#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""NextLNMP AI 网关 v2.0 —— 诊断 / 多轮对话 / 自愈供应链。

跑在镜像机 127.0.0.1:8927，nginx /ai/ 反代。纯标准库零依赖。

端点：
  POST /diagnose  单轮诊断（v1.0 契约，保持兼容）
  POST /chat      多轮对话救援（模块 B 客户端对接，见 CONTRACT.md）
  GET  /health    健康 + 当日用量/缓存/自愈计数
  GET  /admin     自愈队列与近期动作（?key=）

自愈三闸（防投毒，命门）：
  ① 上游域名白名单写死在服务端 —— AI 与用户都无权提供 URL，只能给"文件名+上游标识"
  ② 文件名必须匹配既有目录的命名模式
  ③ 入清单必须走 sync-checksums 的公开 commit 轨道（可审计）
"""
import base64
import hashlib
import secrets
import json
import os
import queue
import re
import sqlite3
import subprocess
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DS_KEY = os.environ.get('DS_KEY', '')
DS_MODEL = os.environ.get('DS_MODEL', 'deepseek-v4-flash')
DS_URL = 'https://api.deepseek.com/chat/completions'
GH_TOKEN = os.environ.get('GH_TOKEN', '')
ADMIN_KEY = os.environ.get('ADMIN_KEY', '')
HEAL_ENABLE = os.environ.get('HEAL_ENABLE', '0') == '1'
# 镜像站对外地址，用于"这个文件到底在不在"的实地核实
MIRROR_URL = os.environ.get('MIRROR_URL', 'https://mirror.nextlnmp.cn').rstrip('/')
# 每天最多开几个 issue，防止被刷
ISSUE_DAILY_CAP = int(os.environ.get('ISSUE_DAILY_CAP', '10'))
GH_REPO = os.environ.get('GH_REPO', 'NextLNMP/nextlnmp')
MIRROR_ROOT = os.environ.get('MIRROR_ROOT', '/data/mirror')
DB_PATH = os.environ.get('AI_DB', '/opt/nextlnmp-ai/cache.db')
DAILY_YUAN_CAP = float(os.environ.get('DAILY_YUAN_CAP', '10'))
# deepseek-v4-flash 计价（元/百万 token），仅用于熔断估算
PRICE_IN, PRICE_IN_CACHED, PRICE_OUT = 0.5, 0.1, 2.0

MAX_LOG = 12 * 1024
SESSION_TTL = 24 * 3600
MAX_TURNS = 10

# ---- 闸① 上游域名白名单：AI 只能给 upstream 标识，URL 由服务端按模板拼 ----
UPSTREAM = {
    'php.net':      'https://www.php.net/distributions/{file}',
    # museum.php.net 支持 https；原来写的是明文 http，而 curl 又跟随重定向，
    # 等于这条上游的内容完全不可验证。
    'php.museum':   'https://museum.php.net/php5/{file}',
    'pecl':         'https://pecl.php.net/get/{file}',
    'nginx.org':    'https://nginx.org/download/{file}',
    'mysql.cdn':    'https://cdn.mysql.com/Downloads/MySQL-{mm}/{file}',
    'mysql.archive':'https://cdn.mysql.com/archives/mysql-{mm}/{file}',
    'mariadb':      'https://archive.mariadb.org/{stem}/{sub}/{file}',
    'phpmyadmin':   'https://files.phpmyadmin.net/phpMyAdmin/{ver}/{file}',
    'libzip':       'https://libzip.org/download/{file}',
    'launchpad':    'https://launchpad.net/libmemcached/1.0/1.0.18/+download/{file}',
    'pureftpd':     'https://download.pureftpd.org/pub/pure-ftpd/releases/obsolete/{file}',
    'remi':         'https://rpms.remirepo.net/enterprise/9/remi/{arch}/{file}',
    'lnmp.com':     'https://soft.lnmp.com/{dir}/{file}',
}
# ---- 闸② 文件名命名模式（由镜像既有 168 个文件归纳）----
NAME_OK = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._+-]{2,90}'
                     r'\.(tar\.gz|tar\.bz2|tar\.xz|tgz|zip|rpm|diff\.gz)$')
# 段内允许 . 是为了 php-8.3.7 这种带点的目录名，但必须排掉 '..' ——
# 否则 dir='web/..' 就写到镜像根、'web/../..' 写到 MIRROR_ROOT 上一层。
# (?!\.{1,2}$) 保证每一段都不是 . 或 ..
# 段内允许 . 是为了 php-8.3.7 这种带点的目录名，但每一段都不能是 . 或 ..
# 注意 (?!\.{1,2}$) 只锚最后一段，web/../x 照样能过——必须写成 (?!\.{1,2}(/|$))。
DIR_OK = re.compile(r'^(web|lib|datebase|ftp|security|php|prober)'
                    r'(/(?!\.{1,2}(/|$))[A-Za-z0-9._-]{1,40}){0,2}$')

# ---- 只读诊断命令白名单（服务端强制；客户端同样强制，双重保险）----
DIAG_OK = [
    re.compile(r'^free -h$'), re.compile(r'^df -h$'), re.compile(r'^uname -a$'),
    re.compile(r'^cat /etc/os-release$'), re.compile(r'^nginx -t$'),
    re.compile(r'^ss -tlnp( \| grep [:A-Za-z0-9._-]{1,24})?$'), re.compile(r'^lsblk$'), re.compile(r'^id www$'),
    re.compile(r'^systemctl status (nginx|php-fpm|mysql|mysqld|mariadb|httpd|caddy|pureftpd|redis|memcached)(\.service)?$'),
    re.compile(r'^tail -n \d{1,4} (/root/nextlnmp-install\.log|/var/log/nginx/[a-z_.-]{1,40}|/usr/local/php/var/log/php-fpm\.log|/usr/local/mysql/var/[A-Za-z0-9._-]{1,40}|/usr/local/mariadb/var/[A-Za-z0-9._-]{1,40})$'),
    re.compile(r'^(rpm -qa|dpkg -l) \| grep [A-Za-z0-9._+-]{1,30}$'),
    re.compile(r'^ls -la (/usr/local/(php|nginx|mysql|mariadb|apache)[A-Za-z0-9./_-]{0,40}|/home/wwwroot[A-Za-z0-9./_-]{0,40}|/root/nextlnmp/src)$'),
    re.compile(r'^(/usr/local/php/bin/php|php) -v$'),
    re.compile(r'^cat /etc/my\.cnf$'),
    # 允许模型常用的省略 -m 写法与副镜像探活；仅限 HEAD 请求、仅限自家镜像域名
    re.compile(r'^curl -sI( -m \d{1,3})? https://(mirror\.nextlnmp\.cn|modelscope\.cn)/[A-Za-z0-9./_+-]{1,100}$'),
]

# 灾难命令：即使用户按了 y 也不该执行（客户端 tools/test-ai-assist.sh 有同款硬闸，双重保险）。
# 只拦"整个系统目录"，rm -rf /usr/local/php 这类合法修复必须放行。
# 归一化后再判：去掉引号、把连续空白压成一个。否则 rm -rf "/" 这种
# 只要插一个引号，字符串匹配就整个错过。客户端 AI_Cmd_Catastrophic 同款处理。
_NORM_QUOTES = re.compile('[' + chr(34) + chr(39) + ']')
_NORM_SPACE = re.compile(r'\s+')

DANGER = re.compile(
    r'(^|[;&|]\s*)(reboot|shutdown|halt|poweroff|init\s+[06])\b'
    r'|mkfs(\.\w+)?\b'
    r'|\bdd\s+[^\r\n]*of=/dev/'
    r'|>\s*/dev/(sd|nvme|vd)'
    # rm 带任意标志（含 --no-preserve-root 这种长选项），参数里出现裸 / 或裸系统
    # 目录即拦 —— 不要求它在行尾，否则 `rm -rf /etc /usr` 这种多目标写法会漏掉。
    r'|(^|[\s;&|])rm(\s+-[-a-zA-Z]+)*\s+([^\s]+\s+)*'
    r'(/|/etc|/usr|/var|/home|/boot|/bin|/sbin|/lib|/lib64|/opt|/root|/srv|/dev|/proc|/sys)'
    r'(/\*)?(\s|$|[;&|])'
    r'|chmod\s+(-R\s+)?777\s+/\s*($|[;&|])'
    r'|:\(\)\s*\{.*\};\s*:'
)


def is_dangerous(cmd):
    """判危险命令。先归一化，避免靠引号或多余空格绕过。"""
    if not cmd:
        return False
    raw = str(cmd)
    norm = _NORM_SPACE.sub(' ', _NORM_QUOTES.sub('', raw))
    return bool(DANGER.search(norm)) or bool(DANGER.search(raw))


SYSTEM_PROMPT = """你是 NextLNMP 一键安装包（Linux 下 Nginx/MySQL/MariaDB/PHP 环境安装脚本）的安装故障排查专家，正在与一位可能是新手的中文用户对话。
只输出严格 JSON：{"say":"对用户说的中文，一段话，说人话","diag":["需要用户机器执行的只读诊断命令"],"fix":["建议用户执行的修复命令"],"heal":{"file":"","dir":"","upstream":""},"done":false,"need_human":false}
字段规则：
- say 必填，永远用中文，直接说结论和下一步，不要寒暄不要免责声明。
- diag 只能来自这个白名单形态：free -h / df -h / uname -a / cat /etc/os-release / nginx -t / ss -tlnp / systemctl status <服务> / tail -n <N> <安装日志或服务日志> / rpm -qa|grep X / dpkg -l|grep X / ls -la <安装目录> / php -v / cat /etc/my.cnf / curl -sI 镜像URL。需要更多信息时才给，不需要就给空数组。
- fix 是要用户确认后才会执行的写命令。**必须自包含**：从创建/安装的第一步给起，绝不假设中间产物已存在（例：加 swap 必须从 fallocate 建文件开始，不能直接 mkswap）。多步操作合并成一条 && 链，避免用户只执行一半。脚本本身以 root 运行，**命令里不要带 sudo**（最小化系统可能没装）。禁止 rm -rf 系统目录、mkfs、dd of=/dev/、chmod 777 /、reboot 等破坏性命令。
- heal 仅在判定为"镜像站缺少某个组件文件"时填写：file=文件名，dir=镜像相对目录（如 web/php、datebase/mysql、lib/lua），upstream 从这些标识里选一个：php.net php.museum pecl nginx.org mysql.cdn mysql.archive mariadb phpmyadmin libzip launchpad pureftpd remi lnmp.com。不确定就留空。绝不要输出完整 URL，服务端只认标识。
- 已给出终局修复命令、或问题已解决、或需用户自行处理时，done=true（不要为了追问而不收尾；用户若仍失败会带着新日志回来）。判断超出能力时 need_human=true 并让用户带 /root/nextlnmp-install.log 加 QQ 群 615298。
已知故障模式：下载失败（脚本自带镜像→副镜像→官方源三级兜底，反复失败多为 DNS 污染/出站被墙/系统时间错导致证书失败）；cc1 被 Killed=内存不足需加 swap 或改预编译；apt/yum 源 404=系统 EOL 需切归档源；端口占用；No space left=磁盘满；glibc 不匹配改源码编译；MySQL 启动失败查 datadir 权限与 /etc/my.cnf；缺 libaio.so.1 / libncurses.so.5 等旧 soname=新发行版改了库名（Debian 13 的 t64 迁移），补兼容软链即可；预编译包解压后跑不起来=运行时库版本对不上，改源码编译。

【什么时候该劝用户换系统，而不是硬修】
有些问题不是配置能解决的，硬修只会让用户白折腾几个小时。遇到下面这些，直接在 say 里
说清楚"这个系统装不了/很难装"，给出建议的替代系统，然后 done=true，不要再给一堆 fix：
- 系统已 EOL 且官方源全下线（CentOS 6/7、Debian 9/10 之类），需要手工切归档源才能装依赖；
- 编译器太老装不了新版 PHP（比如 CentOS 7 自带 GCC 4.8，装 PHP 8.x）；
- CPU 缺少预编译包要求的指令集，且源码编译在该机器上也不现实；
- 内存/磁盘明显不够（比如 512M 单核还要源码编译 PHP，可能要一两个小时，
  期间还可能被服务商限速导致 SSH 断连）。
推荐的省事组合：Debian 12 / Debian 13 / Ubuntu 22.04 / Ubuntu 24.04 —— 这几个系统有
PHP 预编译包，几分钟就能装完，不用编译。说的时候要具体（"建议重装成 Debian 12"），
不要含糊地说"换个新系统"。"""

_lock = threading.Lock()
_rate = {}
_healq = queue.Queue()


def db():
    c = sqlite3.connect(DB_PATH, timeout=10)
    c.execute('CREATE TABLE IF NOT EXISTS cache (sig TEXT PRIMARY KEY, resp TEXT, created INT, hits INT DEFAULT 0)')
    c.execute('CREATE TABLE IF NOT EXISTS stats (day TEXT PRIMARY KEY, total INT DEFAULT 0, cached INT DEFAULT 0,'
              ' llm INT DEFAULT 0, tok_in INT DEFAULT 0, tok_cached INT DEFAULT 0, tok_out INT DEFAULT 0, heals INT DEFAULT 0)')
    c.execute('CREATE TABLE IF NOT EXISTS sessions (sid TEXT PRIMARY KEY, created INT, turns INT DEFAULT 0, msgs TEXT)')
    c.execute('CREATE TABLE IF NOT EXISTS heals (id INTEGER PRIMARY KEY AUTOINCREMENT, ts INT, file TEXT, dir TEXT,'
              ' upstream TEXT, status TEXT, detail TEXT)')
    # 迁移：v1.0 的 stats 表只有 total/cached/llm，补齐用量与自愈计数列
    have = {r[1] for r in c.execute('PRAGMA table_info(stats)')}
    for col in ('tok_in', 'tok_cached', 'tok_out', 'heals'):
        if col not in have:
            c.execute('ALTER TABLE stats ADD COLUMN %s INT DEFAULT 0' % col)
    c.commit()
    return c


def today():
    return time.strftime('%Y-%m-%d')


def bump(field, n=1):
    c = db()
    c.execute('INSERT INTO stats(day) VALUES(?) ON CONFLICT(day) DO NOTHING', (today(),))
    c.execute('UPDATE stats SET %s=%s+? WHERE day=?' % (field, field), (n, today()))
    c.commit(); c.close()


def spent_yuan():
    c = db()
    r = c.execute('SELECT tok_in, tok_cached, tok_out FROM stats WHERE day=?', (today(),)).fetchone()
    c.close()
    if not r:
        return 0.0
    return (r[0] * PRICE_IN + r[1] * PRICE_IN_CACHED + r[2] * PRICE_OUT) / 1e6


def normalize(text):
    t = text[-6144:]
    t = re.sub(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}[ T]?\d{0,2}:?\d{0,2}:?\d{0,2}', '', t)
    t = re.sub(r'\b\d{1,3}(\.\d{1,3}){3}\b', 'IP', t)
    t = re.sub(r'[0-9a-f]{8,}', 'HEX', t, flags=re.I)
    t = re.sub(r'/home/[^\s/]+', '/home/X', t)
    t = re.sub(r'[0-9]+', '0', t)
    return re.sub(r'\s+', ' ', t).strip()


def _scrub(text):
    """把可能出现在异常/日志里的凭据抹掉。"""
    if not text:
        return text
    out = text
    if GH_TOKEN:
        out = out.replace(GH_TOKEN, '<GH_TOKEN>')
    if ADMIN_KEY:
        out = out.replace(ADMIN_KEY, '<ADMIN_KEY>')
    if DS_KEY:
        out = out.replace(DS_KEY, '<DS_KEY>')
    out = re.sub(r'(Bearer|Authorization:?)\s*\S+', r'\1 <redacted>', out, flags=re.I)
    return out

# 用户日志里的密码：客户端上传前已经抹过一遍，但不能只指望客户端——
# 老版本客户端、或者有人直接打 /chat，都会绕过那一层。
# 服务端在【送模型之前】和【落库之前】各过一遍，作为兜底。
_SECRET_PATTERNS = [
    (re.compile(r'(密码[：:]\s*)\S{4,}'), r'\1***'),
    (re.compile(r'([Pp]assword\s*[:=]\s*)\S{4,}'), r'\1***'),
    (re.compile(r"(IDENTIFIED BY\s*')[^']*(')"), r'\1***\2'),
    (re.compile(r'(-p)[A-Za-z0-9!@#$%^&*_+=-]{6,}'), r'\1***'),
    (re.compile(r'([Tt]oken\s*[:=]\s*)[A-Za-z0-9_-]{12,}'), r'\1***'),
    (re.compile(r'(gh[pousr]_)[A-Za-z0-9]{20,}'), r'\1***'),
    (re.compile(r'(sk-)[A-Za-z0-9]{16,}'), r'\1***'),
]


def scrub_user_text(text):
    if not text:
        return text
    out = str(text)
    for pat, rep in _SECRET_PATTERNS:
        out = pat.sub(rep, out)
    return out

def signature(step, os_info, log_tail):
    fam = re.sub(r'[0-9.]+', '', (os_info or ''))[:40]
    return hashlib.sha1(('%s|%s|%s' % (step, fam, normalize(log_tail))).encode()).hexdigest()


def rate_ok(ip):
    now = time.time()
    with _lock:
        q = [t for t in _rate.get(ip, []) if now - t < 60]
        if len(q) >= 30:
            _rate[ip] = q
            return False
        q.append(now); _rate[ip] = q
        if len(_rate) > 5000:
            _rate.clear()
    return True


# 并发上限：原来只有"先读额度、后记 token"的检查，中间没有任何闸门，
# 并发请求可以在额度被记上之前一起冲进去，把日上限冲穿任意倍数。
# 加一个信号量把同时在飞的模型调用压到个位数——既堵住竞态窗口，
# 也顺带限制了单位时间的最大烧钱速度。
_llm_slots = threading.Semaphore(int(os.environ.get('LLM_CONCURRENCY', '4')))


def ask_llm(messages, max_tokens=2000):
    if spent_yuan() >= DAILY_YUAN_CAP:
        raise RuntimeError('daily cap reached')
    if not _llm_slots.acquire(timeout=20):
        raise RuntimeError('llm busy')
    try:
        return _ask_llm_inner(messages, max_tokens)
    finally:
        _llm_slots.release()


def _ask_llm_inner(messages, max_tokens=2000):
    # 进到这里之前额度已查过一次；这里再查一次，把并发排队期间被别人
    # 花掉的额度算进来（信号量只压并发，不代替额度检查）。
    if spent_yuan() >= DAILY_YUAN_CAP:
        raise RuntimeError('daily cap reached')
    # deepseek-v4-flash 是推理模型：token 预算先被 reasoning_tokens 吃掉，给少了会
    # finish_reason=length 且 content 为空。low 档实测 7s/744tok，够诊断用且省一半。
    body = json.dumps({'model': DS_MODEL, 'messages': messages, 'temperature': 0.2,
                       'reasoning_effort': 'low',
                       'max_tokens': max_tokens, 'response_format': {'type': 'json_object'}}).encode()
    req = urllib.request.Request(DS_URL, data=body, headers={
        'Content-Type': 'application/json', 'Authorization': 'Bearer ' + DS_KEY})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read())
    u = out.get('usage', {}) or {}
    cached = u.get('prompt_cache_hit_tokens', 0) or 0
    bump('tok_in', max(0, (u.get('prompt_tokens', 0) or 0) - cached))
    bump('tok_cached', cached)
    bump('tok_out', u.get('completion_tokens', 0) or 0)
    parsed = json.loads(out['choices'][0]['message']['content'])
    parsed.setdefault('say', '')
    parsed.setdefault('diag', [])
    parsed.setdefault('fix', [])
    parsed.setdefault('heal', {})
    parsed.setdefault('done', False)
    parsed.setdefault('need_human', False)
    # 闸：服务端过滤非白名单诊断命令
    parsed['diag'] = [d for d in parsed['diag'] if isinstance(d, str)
                      and any(p.match(d.strip()) for p in DIAG_OK)][:4]
    parsed['fix'] = [f for f in parsed['fix'] if isinstance(f, str) and not is_dangerous(f)][:4]
    return parsed


# ------------------------- 自愈执行器 -------------------------
def _http_head_ok(url, timeout=25):
    """HEAD 一下看在不在。返回 True/False/None(网络异常，判不了)。"""
    try:
        req = urllib.request.Request(url, method='HEAD')
        req.add_header('User-Agent', 'nextlnmp-ai/2.0')
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return 200 <= r.status < 300
    except urllib.error.HTTPError as e:
        return 200 <= e.code < 300
    except Exception:
        return None


def _gh_api(path, method='GET', payload=None, timeout=25):
    """GitHub API。token 走 header，不进任何 argv。"""
    if not GH_TOKEN:
        return None
    url = 'https://api.github.com/' + path.lstrip('/')
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header('Authorization', 'Bearer ' + GH_TOKEN)
    req.add_header('Accept', 'application/vnd.github+json')
    req.add_header('User-Agent', 'nextlnmp-ai/2.0')
    if data:
        req.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode('utf-8', 'replace') or 'null')
    except Exception as e:
        print('GH API 失败 %s %s: %s' % (method, path, _scrub(repr(e))[:160]), flush=True)
        return None


def _issue_exists(title):
    """同一个缺件不重复开。

    这里【不用】 Search API：搜索索引是最终一致的，两个请求挨得近会双双搜不到
    而重复开 issue；而且细粒度 PAT 对 Search API 的支持也不确定。
    直接列本仓库带 mirror-missing 标签的 open issue，即时且只需要 Issues:Read。
    """
    page = 1
    while page <= 5:                      # 最多翻 5 页，够用且不会打满配额
        r = _gh_api('repos/%s/issues?state=open&labels=mirror-missing&per_page=100&page=%d'
                    % (GH_REPO, page))
        if not r:
            return False
        for it in r:
            if isinstance(it, dict) and (it.get('title') or '').strip() == title:
                return it.get('number')
        if len(r) < 100:
            break
        page += 1
    return False


def _issues_today():
    c = db()
    n = c.execute("SELECT COUNT(*) FROM heals WHERE status='issued' AND ts >= ?",
                  (int(time.time()) - 86400,)).fetchone()[0]
    c.close()
    return n


def _archive_listable(path):
    """真正把归档列一遍。file(1) 只看头几个字节，截断的包照样'像 gzip'。"""
    import tarfile, zipfile
    try:
        if path.endswith(('.zip',)):
            with zipfile.ZipFile(path) as z:
                return bool(z.namelist())
        if path.endswith('.rpm'):
            return os.path.getsize(path) > 1024   # rpm 不在这里深挖
        with tarfile.open(path) as t:
            for _ in t:
                return True
            return False
    except Exception:
        return False


def heal_url(file, dirname, upstream):
    """闸① + ②：只认白名单标识与命名模式，URL 由服务端拼。"""
    if upstream not in UPSTREAM or not NAME_OK.match(file or '') or not DIR_OK.match(dirname or ''):
        return None
    tpl = UPSTREAM[upstream]
    mm = ''
    m = re.search(r'(\d+\.\d+)', file)
    if m:
        mm = m.group(1)
    stem = file.split('-linux')[0].split('.tar')[0].split('.tgz')[0]
    sub = 'bintar-linux-systemd-x86_64' if 'linux-systemd' in file else 'source'
    arch = 'aarch64' if 'aarch64' in file else 'x86_64'
    ver = mm
    try:
        return tpl.format(file=file, mm=mm, stem=stem, sub=sub, arch=arch, ver=ver, dir=dirname)
    except Exception:
        return None


def heal_worker():
    """镜像缺件的处理：核实之后去 GitHub 开 issue，不再自己往镜像里写文件。

    为什么不自己写：
      · 镜像是所有用户的信任根，而这里的输入（file/dir/upstream）归根到底来自
        模型输出，而模型的输入是匿名用户完全可控的安装日志——提示词注入可以
        直通这条管线。
      · 而且镜像少个文件，用户的安装【本来就不会失败】：安装器有主镜像→魔搭
        副镜像→官方源三级兜底。自愈的真实价值只是"下次别人不用绕远路"，
        为这点收益换供应链写权限，不划算。
    改成开 issue 之后：网关不碰任何文件，最坏后果就是一条噪音通知；
    真正的补货动作交给 CI/机器人去做，那边有审计轨道。
    """
    while True:
        item = _healq.get()
        file, dirname, upstream = item['file'], item['dir'], item['upstream']
        detail, status = '', 'rejected'
        try:
            url = heal_url(file, dirname, upstream)
            if not url:
                detail = '未通过白名单/命名校验'
            else:
                mirror_path = '%s/%s/%s' % (MIRROR_URL, dirname.strip('/'), file)

                # ① 实地核实：镜像上到底在不在。在的话就是误报，直接丢。
                #    这一步把"模型幻觉"和"提示词注入"挡掉一大半——
                #    没法让我为一个明明在架的文件开 issue。
                on_mirror = _http_head_ok(mirror_path)
                if on_mirror is True:
                    status, detail = 'false_alarm', '镜像上已有此文件：' + mirror_path
                elif on_mirror is None:
                    status, detail = 'unknown', '镜像不可达，无法核实，暂不处理'
                else:
                    # ② 官方上游有没有这个文件。没有说明文件名是编的。
                    on_upstream = _http_head_ok(url)
                    if on_upstream is not True:
                        status, detail = 'rejected', '官方上游也没有此文件，判定为无效上报：' + url
                    else:
                        title = '[镜像缺件] %s/%s' % (dirname.strip('/'), file)
                        dup = _issue_exists(title)
                        if dup:
                            status, detail = 'duplicate', '已有 issue #%s' % dup
                        elif _issues_today() >= ISSUE_DAILY_CAP:
                            status, detail = 'capped', '今日开 issue 已达上限 %d' % ISSUE_DAILY_CAP
                        elif not HEAL_ENABLE:
                            status, detail = 'dryrun', '演练模式，未开 issue：' + title
                        else:
                            body = _issue_body(file, dirname, upstream, url, mirror_path)
                            r = _gh_api('repos/%s/issues' % GH_REPO, 'POST',
                                        {'title': title, 'body': body,
                                         'labels': ['mirror-missing', 'automated']})
                            if r and r.get('number'):
                                status = 'issued'
                                detail = '已开 issue #%s' % r['number']
                                bump('heals')
                            else:
                                status, detail = 'error', '开 issue 失败（见网关日志）'
        except Exception as e:
            detail = _scrub(repr(e))[:200]

        try:
            c = db()
            c.execute('INSERT INTO heals(ts, file, dir, upstream, status, detail) VALUES(?,?,?,?,?,?)',
                      (int(time.time()), file, dirname, upstream, status, detail))
            c.commit(); c.close()
        except Exception as e:
            print('HEAL 写库失败（不影响线程存活）: %s' % _scrub(repr(e))[:200], flush=True)
        try:
            print('HEAL %s %s/%s <- %s : %s' % (status, dirname, file, upstream, detail), flush=True)
        except Exception:
            pass
        _healq.task_done()


def _issue_body(file, dirname, upstream, upstream_url, mirror_path):
    """正文写成机器可读的结构，让机器人不用猜。

    所有字段都已过白名单和实地核实；正文里不放任何用户原文——
    避免把用户日志里的内容（可能带注入）原样贴进 issue。
    """
    d = dirname.strip('/')
    lines = [
        '镜像站缺少一个组件文件。以下几点均已核实：',
        '',
        '- 已确认【镜像上没有】：`%s` 返回非 2xx' % mirror_path,
        '- 已确认【官方上游有】：`%s` 返回 2xx' % upstream_url,
        '- 文件名与目录已通过命名白名单校验',
        '',
        '```yaml',
        'kind: mirror-missing',
        'file: %s' % file,
        'dir: %s' % d,
        'upstream_id: %s' % upstream,
        'upstream_url: %s' % upstream_url,
        'mirror_path: %s' % mirror_path,
        '```',
        '',
        '补货参考命令（在镜像机上执行）：',
        '',
        '```bash',
        'mkdir -p /data/mirror/%s' % d,
        "curl -fsSL --proto '=https' --proto-redir '=https' --max-redirs 5 \\",
        '  -o /data/mirror/%s/%s \\' % (d, file),
        '  %s' % upstream_url,
        '```',
        '',
        '补完后触发 Actions → sync-checksums，把哈希收进清单。',
        '',
        '> 本 issue 由 NextLNMP AI 安装救援网关自动创建。',
        '> 网关不会自己往镜像写文件——补货动作请在此处审核后执行。',
    ]
    return '\n'.join(lines)


def maybe_heal(parsed):
    h = parsed.get('heal') or {}
    if not isinstance(h, dict):
        return None
    file, dirname, upstream = (h.get('file') or '').strip(), (h.get('dir') or '').strip(), (h.get('upstream') or '').strip()
    if not (file and dirname and upstream):
        return None
    c = db()
    row = c.execute('SELECT ts FROM heals WHERE file=? AND status IN ("stocked","dryrun") ORDER BY id DESC LIMIT 1',
                    (file,)).fetchone()
    c.close()
    if row and time.time() - row[0] < 24 * 3600:   # 同一文件 24h 冷却，防抖
        return None
    _healq.put({'file': file, 'dir': dirname, 'upstream': upstream})
    return file


# ------------------------- 会话 -------------------------
def load_session(sid):
    c = db()
    r = c.execute('SELECT created, turns, msgs FROM sessions WHERE sid=?', (sid,)).fetchone()
    c.close()
    if not r or time.time() - r[0] > SESSION_TTL:
        return None
    return {'turns': r[1], 'msgs': json.loads(r[2])}


def save_session(sid, turns, msgs):
    c = db()
    # 落库前再脱敏一次：会话表存 24 小时，里面是用户机器的安装日志与诊断输出，
    # 不该留下明文密码。
    safe = []
    for msg in msgs[-16:]:
        if isinstance(msg, dict):
            m2 = dict(msg)
            if isinstance(m2.get('content'), str):
                m2['content'] = scrub_user_text(m2['content'])
            safe.append(m2)
        else:
            safe.append(msg)
    c.execute('INSERT INTO sessions(sid, created, turns, msgs) VALUES(?,?,?,?) '
              'ON CONFLICT(sid) DO UPDATE SET turns=excluded.turns, msgs=excluded.msgs',
              (sid, int(time.time()), turns, json.dumps(safe, ensure_ascii=False)))
    c.execute('DELETE FROM sessions WHERE created < ?', (int(time.time()) - SESSION_TTL,))
    c.commit(); c.close()


def _one_line(v, limit=1000):
    """协议是行式的：一个字段绝不能横跨多行。

    原来只 strip() 首尾空白，字段中间的换行会原样写进协议流——模型只要在一条
    fix 里夹带换行，就能凭空造出额外的 DIAG:/FIX:/HEAL:/DONE 行，
    从而绕开服务端自己的逐条 DANGER 过滤和客户端的只读白名单。
    这里把所有控制字符（含换行、回车、ESC）统一压成空格并截断。
    回车尤其要处理：它会让终端上的显示与实际执行不一致。
    """
    t = '' if v is None else str(v)
    t = ''.join(' ' if (ord(ch) < 32 or ord(ch) == 127) else ch for ch in t)
    return t.strip()[:limit]


def render_text(sid, p, healed):
    """bash 客户端直接消费：行首标记，无需 jq"""
    out = ['SESSION: ' + sid]
    for line in (p.get('say') or '').splitlines() or ['']:
        out.append('SAY: ' + _one_line(line))
    for d in p.get('diag') or []:
        out.append('DIAG: ' + _one_line(d))
    for f in p.get('fix') or []:
        out.append('FIX: ' + _one_line(f))
    if healed:
        out.append('HEAL: ' + _one_line(healed))
    if p.get('need_human'):
        out.append('HUMAN: 请带 /root/nextlnmp-install.log 加 QQ 群 615298')
    if p.get('done') or p.get('need_human'):
        out.append('DONE')
    return '\n'.join(out) + '\n'


class H(BaseHTTPRequestHandler):
    server_version = 'nextlnmp-ai/2.0'

    def _client_ip(self):
        # X-Real-IP 是客户端可以自己填的头。只有当请求确实来自本机 nginx
        # （127.0.0.1 / ::1）时才采信它，否则一律用真实对端地址——
        # 不然攻击者每个请求换一个 X-Real-IP，限流形同虚设。
        peer = self.client_address[0]
        if peer in ('127.0.0.1', '::1', '::ffff:127.0.0.1'):
            return self.headers.get('X-Real-IP') or peer
        return peer

    def log_message(self, fmt, *a):
        # 请求行会原样进日志，而 /admin 的密钥走 query string —— 运维每用一次，
        # 明文密钥就在 stdout/journald 里留一份，nginx access log 里还有一份。
        # 这里把 query 里的 key 抹掉，再过一遍通用脱敏。
        line = fmt % a
        line = re.sub(r'([?&]key=)[^&\s]+', r'\1<redacted>', line)
        print('%s %s' % (self.client_address[0], _scrub(line)), flush=True)

    def _send(self, code, obj, text=False):
        data = (obj if text else json.dumps(obj, ensure_ascii=False)).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ('text/plain' if text else 'application/json') + '; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _body(self):
        # Content-Length 为负数时 min(-1, 128K) = -1，rfile.read(-1) 会一直读到
        # EOF —— 128KB 的上限被自己的 min() 绕过。先夹到 [0, 128K]。
        try:
            n = int(self.headers.get('Content-Length', 0))
        except (TypeError, ValueError):
            n = 0
        n = max(0, min(n, 128 * 1024))
        return json.loads(self.rfile.read(n).decode('utf-8', 'replace'))

    def do_GET(self):
        path = self.path.split('?')[0].rstrip('/')
        if path in ('', '/health'):
            c = db()
            r = c.execute('SELECT total, cached, llm, tok_in, tok_cached, tok_out, heals FROM stats WHERE day=?',
                          (today(),)).fetchone()
            c.close()
            k = ['total', 'cached', 'llm', 'tok_in', 'tok_cached', 'tok_out', 'heals']
            self._send(200, {'ok': True, 'model': DS_MODEL, 'heal_enabled': HEAL_ENABLE,
                             'today': dict(zip(k, r)) if r else {},
                             'yuan_today': round(spent_yuan(), 4), 'yuan_cap': DAILY_YUAN_CAP})
        elif path == '/admin':
            # do_POST 一开始就过 rate_ok，而 do_GET 原来一路裸奔——/admin 的密钥
            # 可以被全速枚举，猜错的成本几乎为零（403 在开库之前就返回了）。
            # 这里补上同一套限流，并对失败额外加一点延迟拖慢爆破。
            ip = self._client_ip()
            if not rate_ok(ip):
                return self._send(429, {'error': 'too many requests'})
            q = dict(re.findall(r'(\w+)=([^&]*)', self.path.split('?', 1)[-1]))
            supplied = q.get('key') or ''
            # 用 compare_digest：普通 != 是按字节短路比较，理论上能被计时区分
            if not ADMIN_KEY or not secrets.compare_digest(supplied, ADMIN_KEY):
                time.sleep(0.5)
                return self._send(403, {'error': 'forbidden'})
            c = db()
            rows = c.execute('SELECT ts, file, dir, upstream, status, detail FROM heals ORDER BY id DESC LIMIT 50').fetchall()
            c.close()
            self._send(200, {'heals': [dict(zip(['ts', 'file', 'dir', 'upstream', 'status', 'detail'], x)) for x in rows]})
        else:
            self._send(404, {'error': 'not found'})

    def do_POST(self):
        path = self.path.split('?')[0].rstrip('/')
        want_text = 'fmt=text' in self.path
        ip = self._client_ip()
        if not rate_ok(ip):
            return self._send(429, 'SAY: 请求过于频繁，请稍后再试\nDONE\n' if want_text else {'error': 'rate limited'}, want_text)
        try:
            p = self._body()
        except Exception:
            return self._send(400, {'error': 'bad json'})

        if path == '/diagnose':      # v1.0 契约，保持兼容
            return self._diagnose(p)
        if path == '/chat':
            return self._chat(p, want_text)
        return self._send(404, {'error': 'not found'})

    def _log_of(self, p):
        if p.get('log_b64'):
            try:
                return base64.b64decode(p['log_b64']).decode('utf-8', 'replace')[-MAX_LOG:]
            except Exception:
                return ''
        return scrub_user_text(str(p.get('log_tail', '')))[-MAX_LOG:]

    def _diagnose(self, p):
        try:
            log = self._log_of(p)
            if not log.strip():
                return self._send(400, {'error': 'log required'})
            sig = signature(str(p.get('step', ''))[:200], str(p.get('os', ''))[:200], log)
            c = db()
            row = c.execute('SELECT resp FROM cache WHERE sig=?', (sig,)).fetchone()
            if row:
                c.execute('UPDATE cache SET hits=hits+1 WHERE sig=?', (sig,)); c.commit(); c.close()
                bump('total'); bump('cached')
                out = json.loads(row[0]); out['cached'] = True
                return self._send(200, out)
            c.close()
            user = ('NextLNMP 版本: %s\n失败步骤: %s\n系统: %s %s\n安装日志尾部:\n%s'
                    % (p.get('ver', '?'), p.get('step', '?'), p.get('os', '?'), p.get('arch', ''), log))
            r = ask_llm([{'role': 'system', 'content': SYSTEM_PROMPT}, {'role': 'user', 'content': user}])
            out = {'diagnosis': r.get('say', ''), 'commands': r.get('fix', []),
                   'auto_safe': False, 'need_human': r.get('need_human', False)}
            c = db()
            c.execute('INSERT OR REPLACE INTO cache(sig, resp, created) VALUES(?,?,?)',
                      (sig, json.dumps(out, ensure_ascii=False), int(time.time())))
            c.commit(); c.close()
            bump('total'); bump('llm')
            out['cached'] = False
            return self._send(200, out)
        except Exception as e:
            print('ERROR diagnose:', repr(e), flush=True)
            return self._send(503, {'error': 'unavailable'})

    def _chat(self, p, want_text):
        try:
            sid = str(p.get('session', ''))[:64]
            sess = load_session(sid) if sid else None
            if not sess:
                # 原来是 sha1(ver + step + time.time())：ver 和 step 都是可枚举的
                # 短字符串，时间戳也能猜，于是会话 id 可被算出来。会话里存着别人
                # 机器的安装日志，猜中就等于接管。改用系统 CSPRNG。
                sid = secrets.token_hex(16)
                log = self._log_of(p)
                if not log.strip():
                    return self._send(400, {'error': 'log required'})
                first = ('NextLNMP 版本: %s\n失败步骤: %s\n系统: %s %s\n安装日志尾部:\n%s'
                         % (p.get('ver', '?'), p.get('step', '?'), p.get('os', '?'), p.get('arch', ''), log))
                sess = {'turns': 0, 'msgs': [{'role': 'user', 'content': first}]}
            else:
                parts = []
                for d in (p.get('diag') or [])[:4]:
                    if isinstance(d, dict) and d.get('cmd'):
                        try:
                            o = base64.b64decode(d.get('out_b64', '')).decode('utf-8', 'replace')[:4000]
                        except Exception:
                            o = ''
                        parts.append('$ %s\n%s' % (d['cmd'], o))
                if p.get('reply'):
                    parts.append('用户说：' + str(p['reply'])[:2000])
                sess['msgs'].append({'role': 'user', 'content': '\n\n'.join(parts) or '（用户未补充信息，请继续）'})

            if sess['turns'] >= MAX_TURNS:
                body = 'SESSION: %s\nSAY: 对话轮数已达上限，请带 /root/nextlnmp-install.log 加 QQ 群 615298\nDONE\n' % sid
                return self._send(200, body if want_text else {'session': sid, 'say': '轮数上限', 'done': True}, want_text)

            r = ask_llm([{'role': 'system', 'content': SYSTEM_PROMPT}] + sess['msgs'])
            healed = maybe_heal(r)
            sess['msgs'].append({'role': 'assistant', 'content': json.dumps(r, ensure_ascii=False)})
            save_session(sid, sess['turns'] + 1, sess['msgs'])
            bump('total'); bump('llm')
            if want_text:
                return self._send(200, render_text(sid, r, healed), True)
            r['session'] = sid
            r['healed'] = healed
            return self._send(200, r)
        except Exception as e:
            print('ERROR chat:', repr(e), flush=True)
            body = 'SAY: AI 诊断暂时不可用，安装本身不受影响\nDONE\n'
            return self._send(503, body if want_text else {'error': 'unavailable'}, want_text)


if __name__ == '__main__':
    if not DS_KEY:
        raise SystemExit('DS_KEY not set')
    threading.Thread(target=heal_worker, daemon=True).start()
    print('nextlnmp-ai 2.0 on 127.0.0.1:8927 model=%s heal=%s' % (DS_MODEL, HEAL_ENABLE), flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8927), H).serve_forever()
