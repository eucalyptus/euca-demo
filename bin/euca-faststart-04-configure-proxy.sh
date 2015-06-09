#/bin/bash
#
# This script configures Nginx as as an SSL reverse proxy for Eucalyptus after a Faststart installation
#
# This should be run immediately after the Faststart PKI configuration script
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y || is_mc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
certsdir=${bindir%/*}/certs
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
}

run() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=run_default * speed / 100))
    else
        ((seconds=run_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo
        echo -n "Run? [Y/n/q]"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
            "n" | "N" | "no" | "No") choice=n ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        echo
        echo -n -e "Waiting $(printf '%2d' $seconds) seconds..."
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "\rWaiting $(printf '%2d' $seconds) seconds..."
            fi
            sleep 1
            ((seconds--))
        done
        echo " Done"
        choice=y
    fi
}

pause() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=pause_default * speed / 100))
    else
        ((seconds=pause_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo "#"
        read pause
        echo -en "\033[1A\033[2K"    # undo newline from read
    else
        echo "#"
        sleep $seconds
    fi
}

next() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=next_default * speed / 100))
    else
        ((seconds=next_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo
        echo -n "Next? [Y/q]"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        echo
        echo -n -e "Waiting $(printf '%2d' $seconds) seconds..."
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "\rWaiting $(printf '%2d' $seconds) seconds..."
            fi
            sleep 1
            ((seconds--))
        done
        echo " Done"
        choice=y
    fi
}


#  3. Parse command line options

while getopts Isf? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_mc = n ]; then
    echo "This script should only be run on a Management Console host"
    exit 20
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console Configuration file"
echo "     - Using sed to edit file, then displaying changes made"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/eucaconsole/console.ini.faststart ]; then
    echo "\cp /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
    echo
fi
echo "sed -i -e \"/^clchost = localhost\$/s/localhost/$EUCA_UFS_PUBLIC_IP/\" \\"
echo "       -e \"/# since eucalyptus allows for different services to be located on different/d\" \\"
echo "       -e \"/# physical hosts, you may override the above host and port for each service./d\" \\"
echo "       -e \"/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d\" \\"
echo "       -e \"/For each service, you can specify a different host and\/or port, for example;/d\" \\"
echo "       -e \"/#elb.host=10.20.30.40/d\" \\"
echo "       -e \"/#elb.port=443/d\" \\"
echo "       -e \"/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d\" \\"
echo "       -e \"/# that won't work from client's browsers./d\" \\"
echo "       -e \"/#s3.host=<your host IP or name>/d\" /etc/eucaconsole/console.ini"
echo
echo "more /etc/eucaconsole/console.ini"

run 150

if [ $choice = y ]; then
    echo
   if [ ! -f /etc/eucaconsole/console.ini.faststart ]; then
        echo "# \cp /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
        \cp /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart
        echo "#"
    fi
    echo "# sed -i -e \"/^clchost = localhost\$/s/localhost/$EUCA_UFS_PUBLIC_IP/\" \\"
    echo "         -e \"/# since eucalyptus allows for different services to be located on different/d\" \\"
    echo "         -e \"/# physical hosts, you may override the above host and port for each service./d\" \\"
    echo "         -e \"/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d\" \\"
    echo "         -e \"/For each service, you can specify a different host and\/or port, for example;/d\" \\"
    echo "         -e \"/#elb.host=10.20.30.40/d\" \\"
    echo "         -e \"/#elb.port=443/d\" \\"
    echo "         -e \"/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d\" \\"
    echo "         -e \"/# that won't work from client's browsers./d\" \\"
    echo "         -e \"/#s3.host=<your host IP or name>/d\" /etc/eucaconsole/console.ini"
    sed -i -e "/^clchost = localhost$/s/localhost/$EUCA_UFS_PUBLIC_IP/" \
           -e "/# since eucalyptus allows for different services to be located on different/d" \
           -e "/# physical hosts, you may override the above host and port for each service./d" \
           -e "/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d" \
           -e "/For each service, you can specify a different host and\/or port, for example;/d" \
           -e "/#elb.host=10.20.30.40/d" \
           -e "/#elb.port=443/d" \
           -e "/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d" \
           -e "/# that won't work from client's browsers./d" \
           -e "/#s3.host=<your host IP or name>/d" /etc/eucaconsole/console.ini
    pause

    echo "more /etc/eucaconsole/console.ini"
    more /etc/eucaconsole/console.ini

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Eucalyptus Console service"
echo "     - When this step is complete, use browser to verify:"
echo "       http://console.q$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN:8888"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "chkconfig eucaconsole on"
echo
echo "service eucaconsole restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# chkconfig eucaconsole on"
    chkconfig eucaconsole on
    pause

    echo "# service eucaconsole restart"
    service eucaconsole restart

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Nginx yum repository"
echo "     - We need a later version of Nginx than is currently in EPEL"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/yum.repos.d/nginx.repo"
echo "[nginx]"
echo "name=nginx repo"
echo "baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/"
echo "priority=1"
echo "gpgcheck=0"
echo "enabled=1"
echo "EOF"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat << EOF > /etc/yum.repos.d/nginx.repo"
    echo "> [nginx]"
    echo "> name=nginx repo"
    echo "> baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/"
    echo "> priority=1"
    echo "> gpgcheck=0"
    echo "> enabled=1"
    echo "> EOF"
    echo "[nginx]" > /etc/yum.repos.d/nginx.repo
    echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
    echo "baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/" >> /etc/yum.repos.d/nginx.repo
    echo "priority=1" >> /etc/yum.repos.d/nginx.repo
    echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
    echo "enabled=1" >> /etc/yum.repos.d/nginx.repo

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Nginx"
echo "     - This is needed for HTTP and HTTPS support running on standard ports"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "yum install -y nginx"

run 50

if [ $choice = y ]; then
    echo
    echo "# yum install -y nginx"
    yum install -y nginx

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Nginx to support virtual hosts"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/nginx/nginx.conf.orig ]; then
    echo "\cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig"
    echo
fi
echo "mkdir -p /etc/nginx/server.d"
echo
echo "sed -i -e '/include.*conf\\.d/a\\    include /etc/nginx/server.d/*.conf;' \\"
echo "       -e '/tcp_nopush/a\\\\n    server_names_hash_bucket_size 128;' \\"
echo "       /etc/nginx/nginx.conf"

run 50

if [ $choice = y ]; then
    echo
    if [ ! -f /etc/nginx/nginx.conf.orig ]; then
        echo "# \cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig"
        \cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
        echo "#"
    fi
    echo "# mkdir -p /etc/nginx/server.d"
    mkdir -p /etc/nginx/server.d
    echo "#"
    echo "# sed -i -e '/include.*conf\\.d/a\\    include /etc/nginx/server.d/*.conf;' \\"
    echo ">        -e '/tcp_nopush/a\\\\n    server_names_hash_bucket_size 128;' \\"
    echo ">        /etc/nginx/nginx.conf"
    sed -i -e '/include.*conf\.d/a\    include /etc/nginx/server.d/*.conf;' \
           -e '/tcp_nopush/a\\n    server_names_hash_bucket_size 128;' \
           /etc/nginx/nginx.conf

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Allow Nginx through firewall"
echo "     - Assumes iptables was configured per normal minimal install"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /tmp/iptables_www_$$.sed"
echo "/^-A INPUT -j REJECT/i\\"
echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\\"
echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT"
echo "EOF"
echo
echo "grep -q "dport 80" /etc/sysconfig/iptables ||"
echo "sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables"
echo
echo "rm -f /tmp/iptables_www_$$.sed"
echo
echo "cat /etc/sysconfig/iptables"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat << EOF > /tmp/iptables_www_$$.sed"
    echo "> /^-A INPUT -j REJECT/i\\"
    echo "> -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\\"
    echo "> -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT"
    echo "> EOF"
    echo "/^-A INPUT -j REJECT/i\" > /tmp/iptables_www_$$.sed
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\" >> /tmp/iptables_www_$$.sed
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT" >> /tmp/iptables_www_$$.sed
    echo "#"
    echo "# grep -q "dport 80" /etc/sysconfig/iptables ||"
    echo "> sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables"
    grep -q "dport 80" /etc/sysconfig/iptables ||
    sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables
    echo "#"
    echo "# rm -f /tmp/iptables_www_$$.sed"
    rm -f /tmp/iptables_www_$$.sed
    pause

    echo "# cat /etc/sysconfig/iptables"
    cat /etc/sysconfig/iptables

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Start Nginx service"
echo "     - Confirm Nginx is running via a browser:"
echo "       http://$(hostname)"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "chkconfig nginx on"
echo
echo "service nginx start"

run 50

if [ $choice = y ]; then
    echo
    echo "# chkconfig nginx on"
    chkconfig nginx on
    pause

    echo "# service nginx start"
    service nginx start

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Nginx Upstream Servers"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/nginx/conf.d/upstream.conf"
echo "#"
echo "# Upstream servers"
echo "#"
echo
echo "# Eucalytus User-Facing Services"
echo "upstream ufs {"
echo "    server localhost:8773 max_fails=3 fail_timeout=30s;"
echo "}"
echo
echo "# Eucalyptus Console"
echo "upstream console {"
echo "    server localhost:8888 max_fails=3 fail_timeout=30s;"
echo "}"
echo "EOF"

run 50

if [ $choice = y ]; then
    echo
    echo "cat << EOF > /etc/nginx/conf.d/upstream.conf"
    echo "#"
    echo "# Upstream servers"
    echo "#"
    echo
    echo "# Eucalytus User-Facing Services"
    echo "upstream ufs {"
    echo "    server localhost:8773 max_fails=3 fail_timeout=30s;"
    echo "}"
    echo
    echo "# Eucalyptus Console"
    echo "upstream console {"
    echo "    server localhost:8888 max_fails=3 fail_timeout=30s;"
    echo "}"
    echo "EOF"
    echo "#"                                                        > /etc/nginx/conf.d/upstream.conf
    echo "# Upstream servers"                                      >> /etc/nginx/conf.d/upstream.conf
    echo "#"                                                       >> /etc/nginx/conf.d/upstream.conf
    echo                                                           >> /etc/nginx/conf.d/upstream.conf
    echo "# Eucalytus User-Facing Services"                        >> /etc/nginx/conf.d/upstream.conf
    echo "upstream ufs {"                                          >> /etc/nginx/conf.d/upstream.conf
    echo "    server localhost:8773 max_fails=3 fail_timeout=30s;" >> /etc/nginx/conf.d/upstream.conf
    echo "}"                                                       >> /etc/nginx/conf.d/upstream.conf
    echo                                                           >> /etc/nginx/conf.d/upstream.conf
    echo "# Eucalyptus Console"                                    >> /etc/nginx/conf.d/upstream.conf
    echo "upstream console {"                                      >> /etc/nginx/conf.d/upstream.conf
    echo "    server localhost:8888 max_fails=3 fail_timeout=30s;" >> /etc/nginx/conf.d/upstream.conf
    echo "}"                                                       >> /etc/nginx/conf.d/upstream.conf

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Default Server"
echo "     - We also need to update or create the default home and error pages"
echo "     - We will not display the default home and error pages due to length"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
    echo "\cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig"
    echo
fi
echo "cat << EOF > /etc/nginx/conf.d/default.conf"
echo "#"
echo "# Default server: http://\$(hostname)"
echo "#"
echo
echo "server {"
echo "    listen       80;"
echo "    server_name  \$(hostname);"
echo
echo "    root  /usr/share/nginx/html;"
echo
echo "    access_log  /var/log/nginx/access.log;"
echo "    error_log   /var/log/nginx/error.log;"
echo
echo "    charset  utf-8;"
echo
echo "    keepalive_timeout  70;"
echo
echo "    location / {"
echo "        index  index.html;"
echo "    }"
echo
echo "    error_page  404  /404.html;"
echo "    location = /404.html {"
echo "        root   /usr/share/nginx/html;"
echo "    }"
echo
echo "    error_page  500 502 503 504  /50x.html;"
echo "    location = /50x.html {"
echo "        root   /usr/share/nginx/html;"
echo "    }"
echo
echo "    location ~ /\.ht {"
echo "        deny  all;"
echo "    }"
echo "}"
echo "EOF"
echo
echo "cat << EOF > /usr/share/nginx/html/index.html"
echo "    ... too long to display ..."
echo "EOF"
echo
echo "cat << EOF > /usr/share/nginx/html/404.html"
echo "    ... too long to display ..."
echo "EOF"
echo
echo "cat << EOF > /usr/share/nginx/html/50x.html"
echo "    ... too long to display ..."
echo "EOF"


run 50

if [ $choice = y ]; then
    echo
    if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
        echo "# \cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig"
        \cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig
        echo
    fi
    echo "# cat << EOF > /etc/nginx/conf.d/default.conf"
    echo "> #"
    echo "> # Default server: http://\$(hostname)"
    echo "> #"
    echo ">"
    echo "> server {"
    echo ">     listen       80;"
    echo ">     server_name  \$(hostname);"
    echo ">"
    echo ">     root  /usr/share/nginx/html;"
    echo ">"
    echo ">     access_log  /var/log/nginx/access.log;"
    echo ">     error_log   /var/log/nginx/error.log;"
    echo ">"
    echo ">     charset  utf-8;"
    echo ">"
    echo ">     keepalive_timeout  70;"
    echo ">"
    echo ">     location / {"
    echo ">         index  index.html;"
    echo ">     }"
    echo ">"
    echo ">     error_page  404  /404.html;"
    echo ">     location = /404.html {"
    echo ">         root   /usr/share/nginx/html;"
    echo ">     }"
    echo ">"
    echo ">     error_page  500 502 503 504  /50x.html;"
    echo ">     location = /50x.html {"
    echo ">         root   /usr/share/nginx/html;"
    echo ">     }"
    echo ">"
    echo ">     location ~ /\.ht {"
    echo ">         deny  all;"
    echo ">     }"
    echo "> }"
    echo "> EOF"
    echo "#"                                             > /etc/nginx/conf.d/default.conf
    echo "# Default server: http://$(hostname)"         >> /etc/nginx/conf.d/default.conf
    echo "#"                                            >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "server {"                                     >> /etc/nginx/conf.d/default.conf
    echo "    listen       80;"                         >> /etc/nginx/conf.d/default.conf
    echo "    server_name  $(hostname);"                >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    root  /usr/share/nginx/html;"             >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    access_log  /var/log/nginx/access.log;"   >> /etc/nginx/conf.d/default.conf
    echo "    error_log   /var/log/nginx/error.log;"    >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    charset  utf-8;"                          >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    keepalive_timeout  70;"                   >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    location / {"                             >> /etc/nginx/conf.d/default.conf
    echo "        index  index.html;"                   >> /etc/nginx/conf.d/default.conf
    echo "    }"                                        >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    error_page  404  /404.html;"              >> /etc/nginx/conf.d/default.conf
    echo "    location = /404.html {"                   >> /etc/nginx/conf.d/default.conf
    echo "        root   /usr/share/nginx/html;"        >> /etc/nginx/conf.d/default.conf
    echo "    }"                                        >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    error_page  500 502 503 504  /50x.html;"  >> /etc/nginx/conf.d/default.conf
    echo "    location = /50x.html {"                   >> /etc/nginx/conf.d/default.conf
    echo "        root   /usr/share/nginx/html;"        >> /etc/nginx/conf.d/default.conf
    echo "    }"                                        >> /etc/nginx/conf.d/default.conf
    echo ""                                             >> /etc/nginx/conf.d/default.conf
    echo "    location ~ /\.ht {"                       >> /etc/nginx/conf.d/default.conf
    echo "        deny  all;"                           >> /etc/nginx/conf.d/default.conf
    echo "    }"                                        >> /etc/nginx/conf.d/default.conf
    echo "}"                                            >> /etc/nginx/conf.d/default.conf
    pause

    echo "# cat << EOF > /usr/share/nginx/html/index.html"
    echo "      ... too long to display ..."
    echo "> EOF"
    echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"  > /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">"                                         >> /usr/share/nginx/html/index.html
    echo "    <head>"                                                                                            >> /usr/share/nginx/html/index.html
    echo "        <title>Test Page for the Nginx HTTP Server on $(hostname -s)</title>"                          >> /usr/share/nginx/html/index.html
    echo "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"                     >> /usr/share/nginx/html/index.html
    echo "        <style type=\"text/css\">"                                                                     >> /usr/share/nginx/html/index.html
    echo "            /*<![CDATA[*/"                                                                             >> /usr/share/nginx/html/index.html
    echo "            body {"                                                                                    >> /usr/share/nginx/html/index.html
    echo "                background-color: #fff;"                                                               >> /usr/share/nginx/html/index.html
    echo "                color: #000;"                                                                          >> /usr/share/nginx/html/index.html
    echo "                font-size: 0.9em;"                                                                     >> /usr/share/nginx/html/index.html
    echo "                font-family: sans-serif,helvetica;"                                                    >> /usr/share/nginx/html/index.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/index.html
    echo "                padding: 0;"                                                                           >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            :link {"                                                                                   >> /usr/share/nginx/html/index.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            :visited {"                                                                                >> /usr/share/nginx/html/index.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            a:hover {"                                                                                 >> /usr/share/nginx/html/index.html
    echo "                color: #f50;"                                                                          >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            h1 {"                                                                                      >> /usr/share/nginx/html/index.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/index.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/index.html
    echo "                padding: 0.6em 2em 0.4em;"                                                             >> /usr/share/nginx/html/index.html
    echo "                background-color: #294172;"                                                            >> /usr/share/nginx/html/index.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/index.html
    echo "                font-weight: normal;"                                                                  >> /usr/share/nginx/html/index.html
    echo "                font-size: 1.75em;"                                                                    >> /usr/share/nginx/html/index.html
    echo "                border-bottom: 2px solid #000;"                                                        >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            h1 strong {"                                                                               >> /usr/share/nginx/html/index.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/index.html
    echo "                font-size: 1.5em;"                                                                     >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            h2 {"                                                                                      >> /usr/share/nginx/html/index.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/index.html
    echo "                background-color: #3C6EB4;"                                                            >> /usr/share/nginx/html/index.html
    echo "                font-size: 1.1em;"                                                                     >> /usr/share/nginx/html/index.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/index.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/index.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/index.html
    echo "                padding: 0.5em;"                                                                       >> /usr/share/nginx/html/index.html
    echo "                border-bottom: 2px solid #294172;"                                                     >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            hr {"                                                                                      >> /usr/share/nginx/html/index.html
    echo "                display: none;"                                                                        >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            .content {"                                                                                >> /usr/share/nginx/html/index.html
    echo "                padding: 1em 5em;"                                                                     >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            .alert {"                                                                                  >> /usr/share/nginx/html/index.html
    echo "                border: 2px solid #000;"                                                               >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            img {"                                                                                     >> /usr/share/nginx/html/index.html
    echo "                border: 2px solid #fff;"                                                               >> /usr/share/nginx/html/index.html
    echo "                padding: 2px;"                                                                         >> /usr/share/nginx/html/index.html
    echo "                margin: 2px;"                                                                          >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            a:hover img {"                                                                             >> /usr/share/nginx/html/index.html
    echo "                border: 2px solid #294172;"                                                            >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            .logos {"                                                                                  >> /usr/share/nginx/html/index.html
    echo "                margin: 1em;"                                                                          >> /usr/share/nginx/html/index.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/index.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/index.html
    echo "            /*]]>*/"                                                                                   >> /usr/share/nginx/html/index.html
    echo "        </style>"                                                                                      >> /usr/share/nginx/html/index.html
    echo "    </head>"                                                                                           >> /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "    <body>"                                                                                            >> /usr/share/nginx/html/index.html
    echo "        <h1>Welcome to <strong>nginx</strong> on $(hostname -s)!</h1>"                                 >> /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "        <div class=\"content\">"                                                                       >> /usr/share/nginx/html/index.html
    echo "            <p>This page is used to test the proper operation of the"                                  >> /usr/share/nginx/html/index.html
    echo "            <strong>nginx</strong> HTTP server after it has been"                                      >> /usr/share/nginx/html/index.html
    echo "            installed. If you can read this page, it means that the"                                   >> /usr/share/nginx/html/index.html
    echo "            web server installed at this site is working"                                              >> /usr/share/nginx/html/index.html
    echo "            properly.</p>"                                                                             >> /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "            <div class=\"alert\">"                                                                     >> /usr/share/nginx/html/index.html
    echo "                <h2>Website Administrator</h2>"                                                        >> /usr/share/nginx/html/index.html
    echo "                <div class=\"content\">"                                                               >> /usr/share/nginx/html/index.html
    echo "                    <p>This is the default <tt>index.html</tt> page that"                              >> /usr/share/nginx/html/index.html
    echo "                    is distributed with <strong>nginx</strong> on"                                     >> /usr/share/nginx/html/index.html
    echo "                    EPEL.  It is located in"                                                           >> /usr/share/nginx/html/index.html
    echo "                    <tt>/usr/share/nginx/html</tt>.</p>"                                               >> /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "                    <p>You should now put your content in a location of"                               >> /usr/share/nginx/html/index.html
    echo "                    your choice and edit the <tt>root</tt> configuration"                              >> /usr/share/nginx/html/index.html
    echo "                    directive in the <strong>nginx</strong>"                                           >> /usr/share/nginx/html/index.html
    echo "                    configuration file"                                                                >> /usr/share/nginx/html/index.html
    echo "                    <tt>/etc/nginx/nginx.conf</tt>.</p>"                                               >> /usr/share/nginx/html/index.html
    echo                                                                                                         >> /usr/share/nginx/html/index.html
    echo "                </div>"                                                                                >> /usr/share/nginx/html/index.html
    echo "            </div>"                                                                                    >> /usr/share/nginx/html/index.html
    echo "        </div>"                                                                                        >> /usr/share/nginx/html/index.html
    echo "    </body>"                                                                                           >> /usr/share/nginx/html/index.html
    echo "</html>"                                                                                               >> /usr/share/nginx/html/index.html
    pause

    echo "# cat << EOF > /usr/share/nginx/html/404.html"
    echo "      ... too long to display ..."
    echo "> EOF"
    echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"  > /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">"                                         >> /usr/share/nginx/html/404.html
    echo "    <head>"                                                                                            >> /usr/share/nginx/html/404.html
    echo "        <title>The page is not found</title>"                                                          >> /usr/share/nginx/html/404.html
    echo "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"                     >> /usr/share/nginx/html/404.html
    echo "        <style type=\"text/css\">"                                                                     >> /usr/share/nginx/html/404.html
    echo "            /*<![CDATA[*/"                                                                             >> /usr/share/nginx/html/404.html
    echo "            body {"                                                                                    >> /usr/share/nginx/html/404.html
    echo "                background-color: #fff;"                                                               >> /usr/share/nginx/html/404.html
    echo "                color: #000;"                                                                          >> /usr/share/nginx/html/404.html
    echo "                font-size: 0.9em;"                                                                     >> /usr/share/nginx/html/404.html
    echo "                font-family: sans-serif,helvetica;"                                                    >> /usr/share/nginx/html/404.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/404.html
    echo "                padding: 0;"                                                                           >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            :link {"                                                                                   >> /usr/share/nginx/html/404.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            :visited {"                                                                                >> /usr/share/nginx/html/404.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            a:hover {"                                                                                 >> /usr/share/nginx/html/404.html
    echo "                color: #f50;"                                                                          >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            h1 {"                                                                                      >> /usr/share/nginx/html/404.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/404.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/404.html
    echo "                padding: 0.6em 2em 0.4em;"                                                             >> /usr/share/nginx/html/404.html
    echo "                background-color: #294172;"                                                            >> /usr/share/nginx/html/404.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/404.html
    echo "                font-weight: normal;"                                                                  >> /usr/share/nginx/html/404.html
    echo "                font-size: 1.75em;"                                                                    >> /usr/share/nginx/html/404.html
    echo "                border-bottom: 2px solid #000;"                                                        >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            h1 strong {"                                                                               >> /usr/share/nginx/html/404.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/404.html
    echo "                font-size: 1.5em;"                                                                     >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            h2 {"                                                                                      >> /usr/share/nginx/html/404.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/404.html
    echo "                background-color: #3C6EB4;"                                                            >> /usr/share/nginx/html/404.html
    echo "                font-size: 1.1em;"                                                                     >> /usr/share/nginx/html/404.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/404.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/404.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/404.html
    echo "                padding: 0.5em;"                                                                       >> /usr/share/nginx/html/404.html
    echo "                border-bottom: 2px solid #294172;"                                                     >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            h3 {"                                                                                      >> /usr/share/nginx/html/404.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/404.html
    echo "                background-color: #ff0000;"                                                            >> /usr/share/nginx/html/404.html
    echo "                padding: 0.5em;"                                                                       >> /usr/share/nginx/html/404.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            hr {"                                                                                      >> /usr/share/nginx/html/404.html
    echo "                display: none;"                                                                        >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            .content {"                                                                                >> /usr/share/nginx/html/404.html
    echo "                padding: 1em 5em;"                                                                     >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            .alert {"                                                                                  >> /usr/share/nginx/html/404.html
    echo "                border: 2px solid #000;"                                                               >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            img {"                                                                                     >> /usr/share/nginx/html/404.html
    echo "                border: 2px solid #fff;"                                                               >> /usr/share/nginx/html/404.html
    echo "                padding: 2px;"                                                                         >> /usr/share/nginx/html/404.html
    echo "                margin: 2px;"                                                                          >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            a:hover img {"                                                                             >> /usr/share/nginx/html/404.html
    echo "                border: 2px solid #294172;"                                                            >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            .logos {"                                                                                  >> /usr/share/nginx/html/404.html
    echo "                margin: 1em;"                                                                          >> /usr/share/nginx/html/404.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/404.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/404.html
    echo "            /*]]>*/"                                                                                   >> /usr/share/nginx/html/404.html
    echo "        </style>"                                                                                      >> /usr/share/nginx/html/404.html
    echo "    </head>"                                                                                           >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "    <body>"                                                                                            >> /usr/share/nginx/html/404.html
    echo "        <h1><strong>nginx error!</strong></h1>"                                                        >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "        <div class=\"content\">"                                                                       >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "            <h3>The page you are looking for is not found.</h3>"                                       >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "            <div class=\"alert\">"                                                                     >> /usr/share/nginx/html/404.html
    echo "                <h2>Website Administrator</h2>"                                                        >> /usr/share/nginx/html/404.html
    echo "                <div class=\"content\">"                                                               >> /usr/share/nginx/html/404.html
    echo "                    <p>Something has triggered missing webpage on your"                                >> /usr/share/nginx/html/404.html
    echo "                    website. This is the default 404 error page for"                                   >> /usr/share/nginx/html/404.html
    echo "                    <strong>nginx</strong> that is distributed with"                                   >> /usr/share/nginx/html/404.html
    echo "                    EPEL.  It is located"                                                              >> /usr/share/nginx/html/404.html
    echo "                    <tt>/usr/share/nginx/html/404.html</tt></p>"                                       >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "                    <p>You should customize this error page for your own"                              >> /usr/share/nginx/html/404.html
    echo "                    site or edit the <tt>error_page</tt> directive in"                                 >> /usr/share/nginx/html/404.html
    echo "                    the <strong>nginx</strong> configuration file"                                     >> /usr/share/nginx/html/404.html
    echo "                    <tt>/etc/nginx/nginx.conf</tt>.</p>"                                               >> /usr/share/nginx/html/404.html
    echo                                                                                                         >> /usr/share/nginx/html/404.html
    echo "                </div>"                                                                                >> /usr/share/nginx/html/404.html
    echo "            </div>"                                                                                    >> /usr/share/nginx/html/404.html
    echo "        </div>"                                                                                        >> /usr/share/nginx/html/404.html
    echo "    </body>"                                                                                           >> /usr/share/nginx/html/404.html
    echo "</html>"                                                                                               >> /usr/share/nginx/html/404.html
    pause

    echo "# cat << EOF > /usr/share/nginx/html/50x.html"
    echo "      ... too long to display ..."
    echo "> EOF"
    echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"  > /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">"                                         >> /usr/share/nginx/html/50x.html
    echo "    <head>"                                                                                            >> /usr/share/nginx/html/50x.html
    echo "        <title>The page is temporarily unavailable</title>"                                            >> /usr/share/nginx/html/50x.html
    echo "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />"                     >> /usr/share/nginx/html/50x.html
    echo "        <style type=\"text/css\">"                                                                     >> /usr/share/nginx/html/50x.html
    echo "            /*<![CDATA[*/"                                                                             >> /usr/share/nginx/html/50x.html
    echo "            body {"                                                                                    >> /usr/share/nginx/html/50x.html
    echo "                background-color: #fff;"                                                               >> /usr/share/nginx/html/50x.html
    echo "                color: #000;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "                font-size: 0.9em;"                                                                     >> /usr/share/nginx/html/50x.html
    echo "                font-family: sans-serif,helvetica;"                                                    >> /usr/share/nginx/html/50x.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/50x.html
    echo "                padding: 0;"                                                                           >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            :link {"                                                                                   >> /usr/share/nginx/html/50x.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            :visited {"                                                                                >> /usr/share/nginx/html/50x.html
    echo "                color: #c00;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            a:hover {"                                                                                 >> /usr/share/nginx/html/50x.html
    echo "                color: #f50;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            h1 {"                                                                                      >> /usr/share/nginx/html/50x.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/50x.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/50x.html
    echo "                padding: 0.6em 2em 0.4em;"                                                             >> /usr/share/nginx/html/50x.html
    echo "                background-color: #294172;"                                                            >> /usr/share/nginx/html/50x.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "                font-weight: normal;"                                                                  >> /usr/share/nginx/html/50x.html
    echo "                font-size: 1.75em;"                                                                    >> /usr/share/nginx/html/50x.html
    echo "                border-bottom: 2px solid #000;"                                                        >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            h1 strong {"                                                                               >> /usr/share/nginx/html/50x.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/50x.html
    echo "                font-size: 1.5em;"                                                                     >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            h2 {"                                                                                      >> /usr/share/nginx/html/50x.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/50x.html
    echo "                background-color: #3C6EB4;"                                                            >> /usr/share/nginx/html/50x.html
    echo "                font-size: 1.1em;"                                                                     >> /usr/share/nginx/html/50x.html
    echo "                font-weight: bold;"                                                                    >> /usr/share/nginx/html/50x.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "                margin: 0;"                                                                            >> /usr/share/nginx/html/50x.html
    echo "                padding: 0.5em;"                                                                       >> /usr/share/nginx/html/50x.html
    echo "                border-bottom: 2px solid #294172;"                                                     >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            h3 {"                                                                                      >> /usr/share/nginx/html/50x.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/50x.html
    echo "                background-color: #ff0000;"                                                            >> /usr/share/nginx/html/50x.html
    echo "                padding: 0.5em;"                                                                       >> /usr/share/nginx/html/50x.html
    echo "                color: #fff;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            hr {"                                                                                      >> /usr/share/nginx/html/50x.html
    echo "                display: none;"                                                                        >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            .content {"                                                                                >> /usr/share/nginx/html/50x.html
    echo "                padding: 1em 5em;"                                                                     >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            .alert {"                                                                                  >> /usr/share/nginx/html/50x.html
    echo "                border: 2px solid #000;"                                                               >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            img {"                                                                                     >> /usr/share/nginx/html/50x.html
    echo "                border: 2px solid #fff;"                                                               >> /usr/share/nginx/html/50x.html
    echo "                padding: 2px;"                                                                         >> /usr/share/nginx/html/50x.html
    echo "                margin: 2px;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            a:hover img {"                                                                             >> /usr/share/nginx/html/50x.html
    echo "                border: 2px solid #294172;"                                                            >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            .logos {"                                                                                  >> /usr/share/nginx/html/50x.html
    echo "                margin: 1em;"                                                                          >> /usr/share/nginx/html/50x.html
    echo "                text-align: center;"                                                                   >> /usr/share/nginx/html/50x.html
    echo "            }"                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            /*]]>*/"                                                                                   >> /usr/share/nginx/html/50x.html
    echo "        </style>"                                                                                      >> /usr/share/nginx/html/50x.html
    echo "    </head>"                                                                                           >> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "    <body>"                                                                                            >> /usr/share/nginx/html/50x.html
    echo "        <h1><strong>nginx error!</strong></h1>"                                                        >> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "        <div class=\"content\">"                                                                       >> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            <h3>The page you are looking for is temporarily unavailable.  Please try again later.</h3>">> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "            <div class=\"alert\">"                                                                     >> /usr/share/nginx/html/50x.html
    echo "                <h2>Website Administrator</h2>"                                                        >> /usr/share/nginx/html/50x.html
    echo "                <div class=\"content\">"                                                               >> /usr/share/nginx/html/50x.html
    echo "                    <p>Something has triggered an error on your"                                       >> /usr/share/nginx/html/50x.html
    echo "                    website.  This is the default error page for"                                      >> /usr/share/nginx/html/50x.html
    echo "                    <strong>nginx</strong> that is distributed with"                                   >> /usr/share/nginx/html/50x.html
    echo "                    EPEL.  It is located"                                                              >> /usr/share/nginx/html/50x.html
    echo "                    <tt>/usr/share/nginx/html/50x.html</tt></p>"                                       >> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "                    <p>You should customize this error page for your own"                              >> /usr/share/nginx/html/50x.html
    echo "                    site or edit the <tt>error_page</tt> directive in"                                 >> /usr/share/nginx/html/50x.html
    echo "                    the <strong>nginx</strong> configuration file"                                     >> /usr/share/nginx/html/50x.html
    echo "                    <tt>/etc/nginx/nginx.conf</tt>.</p>"                                               >> /usr/share/nginx/html/50x.html
    echo                                                                                                         >> /usr/share/nginx/html/50x.html
    echo "                </div>"                                                                                >> /usr/share/nginx/html/50x.html
    echo "            </div>"                                                                                    >> /usr/share/nginx/html/50x.html
    echo "        </div>"                                                                                        >> /usr/share/nginx/html/50x.html
    echo "    </body>"                                                                                           >> /usr/share/nginx/html/50x.html
    echo "</html>"                                                                                               >> /usr/share/nginx/html/50x.html

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Nginx service"
echo "     - Confirm Nginx is running via a browser:"
echo "       http://$(hostname)"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service nginx restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# service nginx restart"
    service nginx restart

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus User-Facing Services Reverse Proxy Server"
echo "     - This server will proxy all API URLs via standard HTTP and HTTPS ports"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
echo "#"
echo "# Eucalyptus User-Facing Services"
echo "#"
echo
echo "server {"
echo "    listen       80  default_server;"
echo "    listen       443 default_server ssl;"
echo "    server_name  ec2.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN compute.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  s3.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN objectstorage.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  iam.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN euare.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  sts.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN tokens.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  autoscaling.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  cloudformation.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  monitoring.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN cloudwatch.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  elasticloadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN loadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo "    server_name  swf.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN simpleworkflow.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
echo
echo "    access_log  /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"
echo "    error_log   /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"
echo
echo "    charset  utf-8;"
echo
echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
echo "    ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"
echo "    ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;"
echo
echo "    keepalive_timeout  70;"
echo "    client_max_body_size 100M;"
echo "    client_body_buffer_size 128K;"
echo
echo "    location / {"
echo "        proxy_pass            http://ufs;"
echo "        proxy_redirect        default;"
echo "        proxy_next_upstream   error timeout invalid_header http_500;"
echo "        proxy_connect_timeout 30;"
echo "        proxy_send_timeout    90;"
echo "        proxy_read_timeout    90;"
echo
echo "        proxy_http_version    1.1;"
echo
echo "        proxy_buffering       on;"
echo "        proxy_buffer_size     128K;"
echo "        proxy_buffers         4 256K;"
echo "        proxy_busy_buffers_size 256K;"
echo "        proxy_temp_file_write_size 512K;"
echo
echo "        proxy_set_header      Host \$host;"
echo "        proxy_set_header      X-Real-IP  \$remote_addr;"
echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"
echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"
echo "    }"
echo "}"
echo "EOF"
echo 
echo "chmod 644 /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat << EOF > /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
    echo "> #"
    echo "> # Eucalyptus User-Facing Services"
    echo "> #"
    echo ">"
    echo "> server {"
    echo ">     listen       80  default_server;"
    echo ">     listen       443 default_server ssl;"
    echo ">     server_name  ec2.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN compute.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  s3.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN objectstorage.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  iam.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN euare.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  sts.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN tokens.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  autoscaling.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  cloudformation.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  monitoring.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN cloudwatch.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  elasticloadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN loadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">     server_name  swf.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN simpleworkflow.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"
    echo ">"
    echo ">     access_log  /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"
    echo ">     error_log   /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"
    echo ">"
    echo ">     charset  utf-8;"
    echo ">"
    echo ">     ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
    echo ">     ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"
    echo ">     ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;"
    echo ">"
    echo ">     keepalive_timeout  70;"
    echo ">     client_max_body_size 100M;"
    echo ">     client_body_buffer_size 128K;"
    echo ">"
    echo ">     location / {"
    echo ">         proxy_pass            http://ufs;"
    echo ">         proxy_redirect        default;"
    echo ">         proxy_next_upstream   error timeout invalid_header http_500;"
    echo ">         proxy_connect_timeout 30;"
    echo ">         proxy_send_timeout    90;"
    echo ">         proxy_read_timeout    90;"
    echo ">"
    echo ">         proxy_http_version    1.1;"
    echo ">"
    echo ">         proxy_buffering       on;"
    echo ">         proxy_buffer_size     128K;"
    echo ">         proxy_buffers         4 256K;"
    echo ">         proxy_busy_buffers_size 256K;"
    echo ">         proxy_temp_file_write_size 512K;"
    echo ">"
    echo ">         proxy_set_header      Host \$host;"
    echo ">         proxy_set_header      X-Real-IP  \$remote_addr;"
    echo ">         proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo ">         proxy_set_header      X-Forwarded-Proto \$scheme;"
    echo ">     }"
    echo "> }"
    echo "> EOF"
    echo "#"                                                                                                                                       > /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "# Eucalyptus User-Facing Services"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "#"                                                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "server {"                                                                                                                               >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    listen       80  default_server;"                                                                                                   >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    listen       443 default_server ssl;"                                                                                               >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  ec2.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN compute.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                        >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  s3.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN objectstorage.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                   >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  iam.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN euare.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  sts.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN tokens.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                         >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  autoscaling.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                                                                 >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  cloudformation.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                                                              >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  monitoring.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN cloudwatch.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"              >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  elasticloadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN loadbalancing.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;" >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  swf.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN simpleworkflow.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN;"                 >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    access_log  /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"                                                >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    error_log   /var/log/nginx/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"                                                 >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    charset  utf-8;"                                                                                                                    >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"                                                                                        >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"                                         >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;"                                       >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    keepalive_timeout  70;"                                                                                                             >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    client_max_body_size 100M;"                                                                                                         >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    client_body_buffer_size 128K;"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    location / {"                                                                                                                       >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_pass            http://ufs;"                                                                                              >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_redirect        default;"                                                                                                 >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_next_upstream   error timeout invalid_header http_500;"                                                                   >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_connect_timeout 30;"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_send_timeout    90;"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_read_timeout    90;"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_http_version    1.1;"                                                                                                     >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffering       on;"                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffer_size     128K;"                                                                                                    >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffers         4 256K;"                                                                                                  >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_busy_buffers_size 256K;"                                                                                                  >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_temp_file_write_size 512K;"                                                                                               >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                                                          >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      Host \$host;"                                                                                             >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Real-IP  \$remote_addr;"                                                                                >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"                                                             >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"                                                                              >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    }"                                                                                                                                  >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "}"                                                                                                                                      >> /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "#"
    echo "# chmod 644 /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
    chmod 644 /etc/nginx/server.d/ufs.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    
    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Nginx service"
echo "     - Confirm Eucalyptus User-Facing Services are running via a browser:"
echo "       http://compute.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN"
echo "       https://compute.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN"
echo "     - These should respond with a 403 (Forbidden) error, indicating the"
echo "       AWSAccessKeyId is missing, if working correctly"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service nginx restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# service nginx restart"
    service nginx restart

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console Reverse Proxy Server"
echo "     - This server will proxy the console via standard HTTP and HTTPS ports"
echo "     - Requests which use HTTP are immediately rerouted to use HTTPS"
echo "     - Once proxy is configured, configure the console to expect HTTPS"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
echo "#"
echo "# Eucalyptus Console"
echo "#"
echo
echo "server {"
echo "    listen       80;"
echo "    server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"
echo "    return       301 https://\$server_name\$request_uri;"
echo "}"
echo
echo "server {"
echo "    listen       443 ssl;"
echo "    server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"
echo
echo "    access_log  /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"
echo "    error_log   /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"
echo
echo "    charset  utf-8;"
echo
echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
echo "    ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"
echo "    ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;"
echo
echo "    keepalive_timeout  70;"
echo "    client_max_body_size 100M;"
echo "    client_body_buffer_size 128K;"
echo
echo "    location / {"
echo "        proxy_pass            http://console;"
echo "        proxy_redirect        default;"
echo "        proxy_next_upstream   error timeout invalid_header http_500;"
echo
echo "        proxy_connect_timeout 30;"
echo "        proxy_send_timeout    90;"
echo "        proxy_read_timeout    90;"
echo
echo "        proxy_buffering       on;"
echo "        proxy_buffer_size     128K;"
echo "        proxy_buffers         4 256K;"
echo "        proxy_busy_buffers_size 256K;"
echo "        proxy_temp_file_write_size 512K;"
echo
echo "        proxy_set_header      Host \$host;"
echo "        proxy_set_header      X-Real-IP  \$remote_addr;"
echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"
echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"
echo "    }"
echo "}"
echo "EOF"
echo
echo "chmod 644 /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
echo
echo "sed -i -e \"/^session.secure =/s/= .*\$/= true/\" \\"
echo "       -e \"/^session.secure/a\\"
echo "sslcert=/etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt\\"
echo "sslkey=/etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key\" /etc/eucaconsole/console.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat << EOF > /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
    echo "> #"
    echo "> # Eucalyptus Console"
    echo "> #"
    echo ">"
    echo "> server {"
    echo ">     listen       80;"
    echo ">     server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"
    echo ">     return       301 https://\$server_name\$request_uri;"
    echo "> }"
    echo ">"
    echo "> server {"
    echo ">     listen       80;"
    echo ">     listen       443 ssl;"
    echo ">     server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"
    echo ">"
    echo ">     access_log  /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"
    echo ">     error_log   /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"
    echo ">"
    echo ">     charset  utf-8;"
    echo ">"
    echo ">     ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
    echo ">     ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"
    echo ">     ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;"
    echo ">"
    echo ">     keepalive_timeout  70;"
    echo ">     client_max_body_size 100M;"
    echo ">     client_body_buffer_size 128K;"
    echo ">"
    echo ">     location / {"
    echo ">         proxy_pass            http://console;"
    echo ">         proxy_redirect        default;"
    echo ">         proxy_next_upstream   error timeout invalid_header http_500;"
    echo ">"
    echo ">         proxy_connect_timeout 30;"
    echo ">         proxy_send_timeout    90;"
    echo ">         proxy_read_timeout    90;"
    echo ">"
    echo ">         proxy_buffering       on;"
    echo ">         proxy_buffer_size     128K;"
    echo ">         proxy_buffers         4 256K;"
    echo ">         proxy_busy_buffers_size 256K;"
    echo ">         proxy_temp_file_write_size 512K;"
    echo ">"
    echo ">         proxy_set_header      Host \$host;"
    echo ">         proxy_set_header      X-Real-IP  \$remote_addr;"
    echo ">         proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo ">         proxy_set_header      X-Forwarded-Proto \$scheme;"
    echo ">     }"
    echo "> }"
    echo "> EOF"
    echo "#"                                                                                                 > /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "# Eucalyptus Console"                                                                             >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "#"                                                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "server {"                                                                                         >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    listen       80;"                                                                             >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"                           >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    return       301 https://\$server_name\$request_uri;"                                         >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "}"                                                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "server {"                                                                                         >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    listen       443 ssl;"                                                                        >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    server_name  console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.com;"                           >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    access_log  /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-access.log;"      >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    error_log   /var/log/nginx/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN-error.log;"       >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    charset  utf-8;"                                                                              >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"                                                  >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_certificate      /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt;"   >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    ssl_certificate_key  /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key;" >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    keepalive_timeout  70;"                                                                       >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    client_max_body_size 100M;"                                                                   >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    client_body_buffer_size 128K;"                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    location / {"                                                                                 >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_pass            http://console;"                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_redirect        default;"                                                           >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_next_upstream   error timeout invalid_header http_500;"                             >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_connect_timeout 30;"                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_send_timeout    90;"                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_read_timeout    90;"                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffering       on;"                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffer_size     128K;"                                                              >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_buffers         4 256K;"                                                            >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_busy_buffers_size 256K;"                                                            >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_temp_file_write_size 512K;"                                                         >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo                                                                                                    >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      Host \$host;"                                                       >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Real-IP  \$remote_addr;"                                          >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"                       >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"                                        >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "    }"                                                                                            >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "}"                                                                                                >> /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    echo "#"
    echo "# chmod 644 /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf"
    chmod 644 /etc/nginx/server.d/console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.conf
    pause

    echo "sed -i -e \"/^session.secure =/s/= .*\$/= true/\" \\"
    echo "       -e \"/^session.secure/a\\"
    echo "sslcert=/etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt\\"
    echo "sslkey=/etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key\" /etc/eucaconsole/console.ini"
    sed -i -e "/^session.secure =/s/= .*$/= true/" \
           -e "/^session.secure/a\
sslcert=/etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt
sslkey=/etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key" /etc/eucaconsole/console.ini

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Nginx and Eucalyptus Console services"
echo "     - Confirm Eucalyptus Console is running via a browser:"
echo "       http://console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN"
echo "       https://console.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service nginx restart"
echo
echo "service eucaconsole restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# service nginx restart"
    service nginx restart
    pause

    echo "# service eucaconsole restart"
    service eucaconsole restart

    next 50
fi


end=$(date +%s)

echo
echo "Eucalyptus Proxy configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
