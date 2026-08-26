

Check_DB

case "${arg1}" in
    start)
        lamp_start
        ;;
    stop)
        lamp_stop
        ;;
    restart)
        lamp_stop
        lamp_start
        ;;
    reload)
        lamp_reload
        ;;
    kill)
        lamp_kill
        ;;
    status)
        lamp_status
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
        echo "Usage: lnmp {start|stop|reload|restart|kill|status}"
        echo "Usage: lnmp {httpd|mysql|mariadb|pureftpd} {start|stop|reload|restart|kill|status}"
        echo "Usage: lnmp vhost {add|list|del}"
        echo "Usage: lnmp database {add|list|edit|del}"
        echo "Usage: lnmp ftp {add|list|edit|del|show}"
        echo "Usage: lnmp ssl add"
        echo "Usage: lnmp {dnsssl|dns} {cx|ali|cf|dp|he|gd|aws}"
        echo "Usage: lnmp onlyssl {cx|ali|cf|dp|he|gd|aws}"
        ;;
esac
exit
