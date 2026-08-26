# NextLNMP AI 安装救援网关

安装失败时，客户端（`include/ai-assist.sh`）把日志尾部交给这个网关，
网关请模型分析，把诊断命令和修复建议回给用户。

**放在这里是为了能被审计。** 密钥全部走环境变量，源码里没有任何凭据。

---

## 它做什么

```
安装失败
  → 客户端问用户「要不要分析」（[Y/n]）
  → 同意后：日志尾部 12KB，先抹掉密码，再上传
  → 网关请模型分析
  → 返回：给用户看的话 / 只读诊断命令 / 修复命令
  → 诊断命令过白名单后自动执行并回传（多轮）
  → 修复命令一律 y/N 确认，用户不点头就不执行
```

## 边界（不可退让）

- **永不阻塞安装**：网关超时、异常、不可达，一律静默跳过。
- **上传前必须征得同意**，且日志里的密码字段已被抹掉。
- **诊断命令**必须整行匹配只读白名单，客户端和服务端各校验一次。
- **修复命令**永远 y/N，没有自动执行。灾难命令（`rm -rf /` 等）即使用户点了 y 也拦下。
- **命令里出现控制字符一律拒绝**——回车符能让终端显示的和实际执行的不是一回事，
  那样 y/N 确认就形同虚设。
- **网关不往镜像写任何文件**（见下）。

## 镜像缺件怎么处理

早期版本是网关直接从上游下载、写进镜像（"自愈"）。**已废弃。**

原因：这条链的输入归根到底来自模型输出，而模型的输入是匿名用户完全可控的
安装日志——提示词注入可以直通供应链写权限。而且镜像少个文件用户本来就装得成
（安装器有主镜像→魔搭副镜像→官方源三级兜底），为这点收益换写权限不划算。

现在改成**核实之后去 GitHub 开 issue**：

```
① 过白名单（文件名 / 目录 / 上游标识）
② HEAD 主镜像   → 2xx 说明根本没缺，判误报丢弃
③ HEAD 官方上游 → 非 2xx 说明文件名是编的，判无效上报丢弃
④ 列本仓库 open issue 去重（不用 Search API——索引有延迟会重复开）
⑤ 每日开 issue 上限
⑥ 开 issue，正文是机器可读的 yaml 块
```

②③两步让幻觉和注入基本失效：没法为一个官方上游不存在的文件开 issue，
也没法为一个明明在架的文件开 issue。最坏后果是一条噪音通知。

补货动作交给 GitHub 侧的机器人/CI，那边有审计轨道，且只对已核实的 issue 动手。

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `DS_KEY` | — | 模型 API 密钥（必填） |
| `ADMIN_KEY` | — | `/admin` 的访问密钥，不设则 `/admin` 一律 403 |
| `GH_TOKEN` | 空 | 开 issue 用。**只需要 Issues 读写**，见下 |
| `GH_REPO` | `NextLNMP/nextlnmp` | 往哪个仓库开 issue |
| `HEAL_ENABLE` | `0` | `0`=演练（只记录本来会开什么 issue），`1`=真开 |
| `ISSUE_DAILY_CAP` | `10` | 每日开 issue 上限 |
| `MIRROR_URL` | `https://mirror.nextlnmp.cn` | 核实"文件在不在"用 |
| `AI_DB` | `/opt/nextlnmp-ai/cache.db` | SQLite 路径 |
| `DAILY_YUAN_CAP` | `10` | 日费用上限 |
| `LLM_CONCURRENCY` | `4` | 同时在飞的模型调用数（也是烧钱速度的闸） |

### GH_TOKEN 需要什么权限

用 **fine-grained personal access token**（不是经典 PAT）：

- **Repository access**：只勾 `NextLNMP/nextlnmp` 这一个仓库
- **Permissions**：
  - `Metadata` → **Read-only**（细粒度 token 强制项，去不掉）
  - `Issues` → **Read and write**
- 其它一律不给：不需要 Contents、不需要 Actions、不需要 Workflows、
  不需要 Packages、不需要 Administration。

网关只做两件事：列 open issue（去重）、开 issue。所以上面两项就够了。

> 早期版本还会触发 `sync-checksums` 工作流，那需要 Actions 写权限。
> 改成开 issue 之后这条已经去掉了，token 权限可以收得更紧。

## 端点

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/chat` | 客户端唯一入口。`?fmt=text` 返回行式协议（bash 直接消费，不用 jq） |
| GET | `/health` | 当日调用量、token、估算费用 |
| GET | `/admin?key=` | 缺件上报流水（含被各道闸拒绝的记录与理由） |

## 部署

```bash
# 单文件，纯标准库，没有依赖
install -m 755 app.py /opt/nextlnmp-ai/app.py
systemctl restart nextlnmp-ai
curl -s localhost:8927/health
```

改之前先备份：生产上的惯例是 `cp -a app.py app.py.bak-$(date +%Y%m%d-%H%M%S)`。
