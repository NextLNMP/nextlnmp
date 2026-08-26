#@ lnmpa 栈：顶层分发（脚本入口）
Check_DB

case "${arg1}" in
    start)
        lnmpa_start
        ;;
    stop)
        lnmpa_stop
        ;;
    restart)
        lnmpa_stop
        lnmpa_start
        ;;
    reload)
        lnmpa_reload
        ;;
    kill)
        lnmpa_kill
        ;;
    status)
        lnmpa_status
        ;;
    nginx)
        /etc/init.d/nginx ${arg2}
        ;;
    mysql)
        /etc/init.d/mysql ${arg2}
        ;;
    mariadb)
        /etc/init.d/mariadb ${arg2}
        ;;
    pureftpd)
        /etc/init.d/pureftpd ${arg2}
        ;;
    httpd)
        /etc/init.d/httpd ${arg2}
        ;;
    vhost)
        Function_Vhost ${arg2}
        ;;
    database)
        Verify_DB_Password
        Function_Database ${arg2}
        TempMycnf_Clean
        ;;
    ftp)
        Check_Pureftpd
        Function_Ftp ${arg2}
        ;;
    ssl)
        info="n"
        Add_SSL_Menu
        Add_SSL
        ;;
    dnsssl|dns)
        Add_Dns_SSL ${arg2}
        ;;
    onlyssl)
        Add_Dns_SSL_Only ${arg2}
        ;;
    *)
        echo "Usage: nextlnmp {start|stop|reload|restart|kill|status}"
        echo "Usage: nextlnmp {nginx|mysql|mariadb|pureftpd|httpd} {start|stop|reload|restart|kill|status}"
        echo "Usage: nextlnmp vhost {add|list|del}"
        echo "Usage: nextlnmp database {add|list|edit|del}"
        echo "Usage: nextlnmp ftp {add|list|edit|del|show}"
        echo "Usage: nextlnmp ssl add"
        echo "Usage: nextlnmp {dnsssl|dns} {cx|ali|cf|dp|he|gd|aws}"
        echo "Usage: nextlnmp onlyssl {cx|ali|cf|dp|he|gd|aws}"
esac
exit
