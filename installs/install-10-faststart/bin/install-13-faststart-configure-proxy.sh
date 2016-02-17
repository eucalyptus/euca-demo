#/bin/bash
#
# This script configures Nginx as as an SSL reverse proxy for Eucalyptus after a Faststart installation
#
# This should be run immediately after the Faststart PKI configuration script
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]]"
    echo "             [-r region] [-d domain]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -r region  Eucalyptus Region (default: $region)"
    echo "  -d domain  Eucalyptus Domain (default: $domain)"
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

while getopts Isfr:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG"
        [ -z $domain ] &&
        domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null);;
    d)  domain="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $region ]; then
    echo "-r region missing!"
    echo "Could not automatically determine region, and it was not specified as a parameter"
    exit 10
else
    case $region in
      us-east-1|us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $domain ]; then
    echo "-d domain missing!"
    echo "Could not automatically determine domain, and it was not specified as a parameter"
    exit 12
fi

user_region=$region-admin@$region

if ! grep -s -q "\[user $region-admin]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Eucalyptus Administrator Euca2ools user!"
    echo "Expected to find: [user $region-admin] in ~/.euca/$region.ini"
    exit 50
fi

if ! which lynx > /dev/null; then
    echo "lynx missing: This demo uses the lynx text-mode browser to confirm webpage content"
    case $(uname) in
      Darwin)
        echo "- Lynx for OSX can be found here: http://habilis.net/lynxlet/"
        echo "- Follow instructions to install and create /usr/bin/lynx symlink";;
      *)
        echo "- yum install -y lynx";;
    esac
 
    exit 98
fi

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console to use custom SSL Certificate"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/eucaconsole/console.ini.faststart ]; then
    echo "\cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
    echo
fi
echo "sed -i -e \"/^ufshost = localhost\$/s/localhost/ufs.$region.$domain/\" /etc/eucaconsole/console.ini"
echo
echo "sed -i -e \"/^session.secure/a\\"
echo "sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\\\"
echo "sslkey=/etc/pki/tls/private/star.$region.$domain.key\" /etc/eucaconsole/console.ini"

if grep -s -q "ufs.$region.$domain" /etc/eucaconsole/console.ini; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        if [ ! -f /etc/eucaconsole/console.ini.faststart ]; then
            echo "# \cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
            \cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart
            pause
        fi

        echo "# sed -i -e \"/^ufshost = localhost\$/s/localhost/ufs.$region.$domain/\" /etc/eucaconsole/console.ini"
        sed -i -e "/^ufshost = localhost$/s/localhost/ufs.$region.$domain/" /etc/eucaconsole/console.ini
        pause

        echo "# sed -i -e \"/^session.secure/a\\"
        echo "> sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\\\"
        echo "> sslkey=/etc/pki/tls/private/star.$region.$domain.key\" /etc/eucaconsole/console.ini"
        sed -i -e "/^session.secure/a\
sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\
sslkey=/etc/pki/tls/private/star.$region.$domain.key" /etc/eucaconsole/console.ini

        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Embedded Nginx to use custom SSL Certificate"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/eucaconsole/nginx.conf.faststart ]; then
    echo "\cp -a /etc/eucaconsole/nginx.conf /etc/eucaconsole/nginx.conf.faststart"
    echo
fi
echo "sed -i -e \"s/\\/etc\\/eucaconsole\\/console.crt;/\\/etc\\/pki\\/tls\\/certs\\/star.$region.$domain.crt;/\" \\"
echo "       -e \"s/\\/etc\\/eucaconsole\\/console.key;/\\/etc\\/pki\\/tls\\/private\\/star.$region.$domain.key;/\" \\"
echo "    /etc/eucaconsole/nginx.conf"

if grep -s -q "star.$region.$domain.crt" /etc/eucaconsole/nginx.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run
 
    if [ $choice = y ]; then
        echo
        if [ ! -f /etc/eucaconsole/nginx.conf.faststart ]; then
            echo "# \cp -a /etc/eucaconsole/nginx.conf /etc/eucaconsole/nginx.conf.faststart"
            \cp -a /etc/eucaconsole/nginx.conf /etc/eucaconsole/nginx.conf.faststart
            pause
        fi

        echo "# sed -i -e \"s/\\/etc\\/eucaconsole\\/console.crt;/\\/etc\\/pki\\/tls\\/certs\\/star.$region.$domain.crt;/\" \\"
        echo ">        -e \"s/\\/etc\\/eucaconsole\\/console.key;/\\/etc\\/pki\\/tls\\/private\\/star.$region.$domain.key;/\" \\"
        echo ">     /etc/eucaconsole/nginx.conf"
        sed -i -e "s/\/etc\/eucaconsole\/console.crt;/\/etc\/pki\/tls\/certs\/star.$region.$domain.crt;/" \
               -e "s/\/etc\/eucaconsole\/console.key;/\/etc\/pki\/tls\/private\/star.$region.$domain.key;/" \
            /etc/eucaconsole/nginx.conf

        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Eucalyptus Console service"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service eucaconsole restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# service eucaconsole restart"
    service eucaconsole restart

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm Eucalyptus Console is accessible with custom SSL Certificate"
echo "    - Browse: https://console.$region.$domain/ in a separate browser for a"
echo "      comprehensive check."
echo "    - This script uses a text-mode brower to dump the headers."
echo "    - Confirm no SSL configuration errors."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "lynx --dump --head https://console.$region.$domain/"

run 50

if [ $choice = y ]; then
    echo
    echo "# lynx --dump --head https://console.$region.$domain/"
    lynx --dump --head https://console.$region.$domain/

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Disable Embedded Nginx service"
echo "    - We will disable the embedded Nginx server which is started with the Console"
echo "      by default, so we can replace it with a new configuration which proxies"
echo "      SSL for both the Console and User-Facing Services."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "sed -i -e \"/NGINX_FLAGS=/ s/=/=NO/\" /etc/sysconfig/eucaconsole"

if grep -s -q "NGINX_FLAGS=NO" /etc/sysconfig/eucaconsole; then
    echo
    tput rev
    echo "Already Disabled!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# sed -i -e \"/NGINX_FLAGS=/ s/=/=NO/\" /etc/sysconfig/eucaconsole"
        sed -i -e "/NGINX_FLAGS=/ s/=/=NO/" /etc/sysconfig/eucaconsole

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Eucalyptus Console service"
echo "    - You should see the Embedded Nginx service stop, but not restart"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service eucaconsole restart"

run 50

if [ $choice = y ]; then
    echo
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
echo "    - We need a later version of Nginx than is currently in EPEL"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/yum.repos.d/nginx.repo"
echo "[nginx]"
echo "name=nginx repo"
echo "baseurl=http://nginx.org/packages/centos/\\\$releasever/\\\$basearch/"
echo "priority=1"
echo "gpgcheck=0"
echo "enabled=1"
echo "EOF"

if [ -r /etc/yum.repos.d/nginx.repo ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/yum.repos.d/nginx.repo"
        echo "> [nginx]"
        echo "> name=nginx repo"
        echo "> baseurl=http://nginx.org/packages/centos/\\\$releasever/\\\$basearch/"
        echo "> priority=1"
        echo "> gpgcheck=0"
        echo "> enabled=1"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[nginx]"                                                            > /etc/yum.repos.d/nginx.repo
        echo "name=nginx repo"                                                   >> /etc/yum.repos.d/nginx.repo
        echo "baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/" >> /etc/yum.repos.d/nginx.repo
        echo "priority=1"                                                        >> /etc/yum.repos.d/nginx.repo
        echo "gpgcheck=0"                                                        >> /etc/yum.repos.d/nginx.repo
        echo "enabled=1"                                                         >> /etc/yum.repos.d/nginx.repo

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Nginx"
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
    echo "\cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig"
    echo
fi
echo "mkdir -p /etc/nginx/server.d"
echo
echo "sed -i -e '/include.*conf\\.d/a\\    include /etc/nginx/server.d/*.conf;' \\"
echo "       -e '/tcp_nopush/a\\\\n    server_names_hash_bucket_size 128;' \\"
echo "       /etc/nginx/nginx.conf"

if grep -s -q "/etc/nginx/server.d/*.conf" /etc/nginx.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        if [ ! -f /etc/nginx/nginx.conf.orig ]; then
            echo "# \cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig"
            \cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
            pause
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
fi


# Comment this out for now, as at least in PRC, iptables is not setup per CentOS minimum conventions
#((++step))
#clear
#echo
#echo "================================================================================"
#echo
#echo "$(printf '%2d' $step). Allow Nginx through firewall"
#echo "    - Assumes iptables was configured per normal minimal install"
#echo
#echo "================================================================================"
#echo
#echo "Commands:"
#echo
#echo "cat << EOF > /tmp/iptables_www_$$.sed"
#echo "/^-A INPUT -j REJECT/i\\"
#echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\\"
#echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT"
#echo "EOF"
#echo
#echo "grep -q "dport 80" /etc/sysconfig/iptables ||"
#echo "sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables"
#echo
#echo "rm -f /tmp/iptables_www_$$.sed"
#echo
#echo "cat /etc/sysconfig/iptables"
#
#run 50
#
#if [ $choice = y ]; then
#    echo
#    echo "# cat << EOF > /tmp/iptables_www_$$.sed"
#    echo "> /^-A INPUT -j REJECT/i\\"
#    echo "> -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\\"
#    echo "> -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT"
#    echo "> EOF"
#    echo "/^-A INPUT -j REJECT/i\" > /tmp/iptables_www_$$.sed
#    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\" >> /tmp/iptables_www_$$.sed
#    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT" >> /tmp/iptables_www_$$.sed
#    echo "#"
#    echo "# grep -q "dport 80" /etc/sysconfig/iptables ||"
#    echo "> sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables"
#    grep -q "dport 80" /etc/sysconfig/iptables ||
#    sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables
#    echo "#"
#    echo "# rm -f /tmp/iptables_www_$$.sed"
#    rm -f /tmp/iptables_www_$$.sed
#    pause
#
#    echo "# cat /etc/sysconfig/iptables"
#    cat /etc/sysconfig/iptables
#
#    next 50
#fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Start Separate Nginx service"
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
echo "$(printf '%2d' $step). Confirm Separate Nginx service"
echo "    - Browse: http://$(hostname)/ in a separate browser for a comprehensive"
echo "      check."
echo "    - This script uses a text-mode brower."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "lynx --dump http://$(hostname)/"
 
run 50
 
if [ $choice = y ]; then
    echo
    echo "# lynx --dump http://$(hostname)/"
    lynx --dump http://$(hostname)/
 
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

if grep -s -q "upstream ufs" /etc/nginx/conf.d/upstream.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/nginx/conf.d/upstream.conf"
        echo "> #"
        echo "> # Upstream servers"
        echo "> #"
        echo ">"
        echo "> # Eucalytus User-Facing Services"
        echo "> upstream ufs {"
        echo ">     server localhost:8773 max_fails=3 fail_timeout=30s;"
        echo "> }"
        echo ">"
        echo "> # Eucalyptus Console"
        echo "> upstream console {"
        echo ">     server localhost:8888 max_fails=3 fail_timeout=30s;"
        echo "> }"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
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
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Default Server"
echo "    - We also need to update or create the default home and error pages"
echo "    - We will not display the default home and error pages due to length"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
    echo "\cp -a /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig"
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

if grep -s -q "$(hostname)" /etc/nginx/conf.d/default.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
            echo "# \cp -a /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig"
            \cp -a /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig
            pause
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
        # Use echo instead of cat << EOF to better show indentation
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
        # Use echo instead of cat << EOF to better show indentation
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
        # Use echo instead of cat << EOF to better show indentation
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
        # Use echo instead of cat << EOF to better show indentation
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
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Separate Nginx service"
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
echo "$(printf '%2d' $step). Confirm Separate Nginx service"
echo "    - Browse: http://$(hostname)/ in a separate browser for a comprehensive"
echo "      check."
echo "    - This script uses a text-mode brower."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "lynx --dump http://$(hostname)/"
 
run 50
 
if [ $choice = y ]; then
    echo
    echo "# lynx --dump http://$(hostname)/"
    lynx --dump http://$(hostname)/
 
    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus User-Facing Services Reverse Proxy Server"
echo "    - This server will proxy all API URLs via standard HTTP and HTTPS ports"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/nginx/server.d/ufs.$region.$domain.conf"
echo "#"
echo "# Eucalyptus User-Facing Services"
echo "#"
echo
echo "server {"
echo "    listen       80  default_server;"
echo "    listen       443 default_server ssl;"
echo "    server_name  ec2.$region.$domain compute.$region.$domain;"
echo "    server_name  s3.$region.$domain objectstorage.$region.$domain;"
echo "    server_name  iam.$region.$domain euare.$region.$domain;"
echo "    server_name  sts.$region.$domain tokens.$region.$domain;"
echo "    server_name  autoscaling.$region.$domain;"
echo "    server_name  cloudformation.$region.$domain;"
echo "    server_name  monitoring.$region.$domain cloudwatch.$region.$domain;"
echo "    server_name  elasticloadbalancing.$region.$domain loadbalancing.$region.$domain;"
echo "    server_name  swf.$region.$domain simpleworkflow.$region.$domain;"
echo
echo "    access_log  /var/log/nginx/ufs.$region.$domain-access.log;"
echo "    error_log   /var/log/nginx/ufs.$region.$domain-error.log;"
echo
echo "    charset  utf-8;"
echo
echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
echo "    ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"
echo "    ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"
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
echo "        proxy_set_header      Host \\\$host;"
echo "        proxy_set_header      X-Real-IP  \\\$remote_addr;"
echo "        proxy_set_header      X-Forwarded-For \\\$proxy_add_x_forwarded_for;"
echo "        proxy_set_header      X-Forwarded-Proto \\\$scheme;"
echo "        proxy_set_header      Connection \"keep-alive\";"
echo "    }"
echo "}"
echo "EOF"
echo 
echo "chmod 644 /etc/nginx/server.d/ufs.$region.$domain.conf"

if grep -s -q "ec2.$region.$domain" /etc/nginx/server.d/ufs.$region.$domain.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/nginx/server.d/ufs.$region.$domain.conf"
        echo "> #"
        echo "> # Eucalyptus User-Facing Services"
        echo "> #"
        echo ">"
        echo "> server {"
        echo ">     listen       80  default_server;"
        echo ">     listen       443 default_server ssl;"
        echo ">     server_name  ec2.$region.$domain compute.$region.$domain;"
        echo ">     server_name  s3.$region.$domain objectstorage.$region.$domain;"
        echo ">     server_name  iam.$region.$domain euare.$region.$domain;"
        echo ">     server_name  sts.$region.$domain tokens.$region.$domain;"
        echo ">     server_name  autoscaling.$region.$domain;"
        echo ">     server_name  cloudformation.$region.$domain;"
        echo ">     server_name  monitoring.$region.$domain cloudwatch.$region.$domain;"
        echo ">     server_name  elasticloadbalancing.$region.$domain loadbalancing.$region.$domain;"
        echo ">     server_name  swf.$region.$domain simpleworkflow.$region.$domain;"
        echo ">"
        echo ">     access_log  /var/log/nginx/ufs.$region.$domain-access.log;"
        echo ">     error_log   /var/log/nginx/ufs.$region.$domain-error.log;"
        echo ">"
        echo ">     charset  utf-8;"
        echo ">"
        echo ">     ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
        echo ">     ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"
        echo ">     ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"
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
        echo ">         proxy_set_header      Host \\\$host;"
        echo ">         proxy_set_header      X-Real-IP  \\\$remote_addr;"
        echo ">         proxy_set_header      X-Forwarded-For \\\$proxy_add_x_forwarded_for;"
        echo ">         proxy_set_header      X-Forwarded-Proto \\\$scheme;"
        echo ">         proxy_set_header      Connection \"keep-alive\";"
        echo ">     }"
        echo "> }"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                                                                                       > /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "# Eucalyptus User-Facing Services"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "#"                                                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "server {"                                                                               >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    listen       80  default_server;"                                                   >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    listen       443 default_server ssl;"                                               >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  ec2.$region.$domain compute.$region.$domain;"                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  s3.$region.$domain objectstorage.$region.$domain;"                     >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  iam.$region.$domain euare.$region.$domain;"                            >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  sts.$region.$domain tokens.$region.$domain;"                           >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  autoscaling.$region.$domain;"                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  cloudformation.$region.$domain;"                                       >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  monitoring.$region.$domain cloudwatch.$region.$domain;"                >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  elasticloadbalancing.$region.$domain loadbalancing.$region.$domain;"   >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    server_name  swf.$region.$domain simpleworkflow.$region.$domain;"                   >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    access_log  /var/log/nginx/ufs.$region.$domain-access.log;"                         >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    error_log   /var/log/nginx/ufs.$region.$domain-error.log;"                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    charset  utf-8;"                                                                    >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"                                        >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"                  >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"                >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    keepalive_timeout  70;"                                                             >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    client_max_body_size 100M;"                                                         >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    client_body_buffer_size 128K;"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    location / {"                                                                       >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_pass            http://ufs;"                                              >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_redirect        default;"                                                 >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_next_upstream   error timeout invalid_header http_500;"                   >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_connect_timeout 30;"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_send_timeout    90;"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_read_timeout    90;"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_http_version    1.1;"                                                     >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_buffering       on;"                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_buffer_size     128K;"                                                    >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_buffers         4 256K;"                                                  >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_busy_buffers_size 256K;"                                                  >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_temp_file_write_size 512K;"                                               >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo                                                                                          >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_set_header      Host \$host;"                                             >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_set_header      X-Real-IP  \$remote_addr;"                                >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;"             >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"                              >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "        proxy_set_header      Connection \"keep-alive\";"                               >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "    }"                                                                                  >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "}"                                                                                      >> /etc/nginx/server.d/ufs.$region.$domain.conf
        echo "#"
        echo "# chmod 644 /etc/nginx/server.d/ufs.$region.$domain.conf"
        chmod 644 /etc/nginx/server.d/ufs.$region.$domain.conf
    
        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console Reverse Proxy Server"
echo "    - This server will proxy the console via standard HTTP and HTTPS ports"
echo "    - Requests which use HTTP are immediately rerouted to use HTTPS"
echo "    - Once proxy is configured, configure the console to expect HTTPS"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/nginx/server.d/console.$region.$domain.conf"
echo "#"
echo "# Eucalyptus Console"
echo "#"
echo
echo "server {"
echo "    listen       80;"
echo "    server_name  console.$region.$domain;"
echo "    return       301 https://\$server_name\$request_uri;"
echo "}"
echo
echo "server {"
echo "    listen       443 ssl;"
echo "    server_name  console.$region.$domain;"
echo
echo "    access_log  /var/log/nginx/console.$region.$domain-access.log;"
echo "    error_log   /var/log/nginx/console.$region.$domain-error.log;"
echo
echo "    charset  utf-8;"
echo
echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
echo "    ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"
echo "    ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"
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
echo "        proxy_set_header      Host \\\$host;"
echo "        proxy_set_header      X-Real-IP  \\\$remote_addr;"
echo "        proxy_set_header      X-Forwarded-For \\\$proxy_add_x_forwarded_for;"
echo "        proxy_set_header      X-Forwarded-Proto \\\$scheme;"
echo "    }"
echo "}"
echo "EOF"
echo
echo "chmod 644 /etc/nginx/server.d/console.$region.$domain.conf"
echo
echo "sed -i -e \"/^session.secure =/s/= .*\$/= true/\" \\"
echo "       -e \"/^session.secure/a\\"
echo "sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\\\"
echo "sslkey=/etc/pki/tls/private/star.$region.$domain.key\" /etc/eucaconsole/console.ini"

if grep -s -q "console.$region.$domain" /etc/nginx/server.d/console.$region.$domain.conf; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/nginx/server.d/console.$region.$domain.conf"
        echo "> #"
        echo "> # Eucalyptus Console"
        echo "> #"
        echo ">"
        echo "> server {"
        echo ">     listen       80;"
        echo ">     server_name  console.$region.$domain;"
        echo ">     return       301 https://\$server_name\$request_uri;"
        echo "> }"
        echo ">"
        echo "> server {"
        echo ">     listen       80;"
        echo ">     listen       443 ssl;"
        echo ">     server_name  console.$region.$domain;"
        echo ">"
        echo ">     access_log  /var/log/nginx/console.$region.$domain-access.log;"
        echo ">     error_log   /var/log/nginx/console.$region.$domain-error.log;"
        echo ">"
        echo ">     charset  utf-8;"
        echo ">"
        echo ">     ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"
        echo ">     ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"
        echo ">     ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"
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
        echo ">         proxy_set_header      Host \\\$host;"
        echo ">         proxy_set_header      X-Real-IP  \\\$remote_addr;"
        echo ">         proxy_set_header      X-Forwarded-For \\\$proxy_add_x_forwarded_for;"
        echo ">         proxy_set_header      X-Forwarded-Proto \\\$scheme;"
        echo ">     }"
        echo "> }"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                                                                           > /etc/nginx/server.d/console.$region.$domain.conf
        echo "# Eucalyptus Console"                                                       >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "#"                                                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "server {"                                                                   >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    listen       80;"                                                       >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    server_name  console.$region.$domain;"                                  >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    return       301 https://\$server_name\$request_uri;"                   >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "}"                                                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "server {"                                                                   >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    listen       443 ssl;"                                                  >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    server_name  console.$region.$domain;"                                  >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    access_log  /var/log/nginx/console.$region.$domain-access.log;"         >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    error_log   /var/log/nginx/console.$region.$domain-error.log;"          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    charset  utf-8;"                                                        >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;"                            >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    ssl_certificate      /etc/pki/tls/certs/star.$region.$domain.crt;"      >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    ssl_certificate_key  /etc/pki/tls/private/star.$region.$domain.key;"    >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    keepalive_timeout  70;"                                                 >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    client_max_body_size 100M;"                                             >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    client_body_buffer_size 128K;"                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    location / {"                                                           >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_pass            http://console;"                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_redirect        default;"                                     >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_next_upstream   error timeout invalid_header http_500;"       >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_connect_timeout 30;"                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_send_timeout    90;"                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_read_timeout    90;"                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_buffering       on;"                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_buffer_size     128K;"                                        >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_buffers         4 256K;"                                      >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_busy_buffers_size 256K;"                                      >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_temp_file_write_size 512K;"                                   >> /etc/nginx/server.d/console.$region.$domain.conf
        echo                                                                              >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_set_header      Host \$host;"                                 >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_set_header      X-Real-IP  \$remote_addr;"                    >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "        proxy_set_header      X-Forwarded-Proto \$scheme;"                  >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "    }"                                                                      >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "}"                                                                          >> /etc/nginx/server.d/console.$region.$domain.conf
        echo "#"
        echo "# chmod 644 /etc/nginx/server.d/console.$region.$domain.conf"
        chmod 644 /etc/nginx/server.d/console.$region.$domain.conf
        pause

        echo "sed -i -e \"/^session.secure =/s/= .*\$/= true/\" \\"
        echo "       -e \"/^session.secure/a\\"
        echo "sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\\\"
        echo "sslkey=/etc/pki/tls/private/star.$region.$domain.key\" /etc/eucaconsole/console.ini"
        sed -i -e "/^session.secure =/s/= .*$/= true/" \
               -e "/^session.secure/a\
sslcert=/etc/pki/tls/certs/star.$region.$domain.crt\\
sslkey=/etc/pki/tls/private/star.$region.$domain.key" /etc/eucaconsole/console.ini

        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Separate Nginx service"
echo "    - Confirm Eucalyptus Console is running via a browser:"
echo "      http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo "      https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
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


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm Separate Nginx service"
echo "    - Browse: https://compute.$region.$domain/ in a separate browser for a"
echo "      comprehensive"
echo "    - Browse: https://console.$region.$domain/ in a separate browser for a"
echo "      comprehensive"
echo "    - This script uses a text-mode brower."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "lynx --dump https://compute.$region.$domain/"
echo
echo "lynx --dump --head https://console.$region.$domain/"
 
run 50
 
if [ $choice = y ]; then
    echo
    echo "# lynx --dump https://compute.$region.$domain/"
    lynx --dump https://compute.$region.$domain/
    pause
 
    echo "# lynx --dump --head https://console.$region.$domain/"
    lynx --dump --head https://console.$region.$domain/

    next 50
fi


((++step))
# Construct Eucalyptus Endpoints (assumes AWS-style URLs)
autoscaling_url=https://autoscaling.$region.$domain/
bootstrap_url=https://bootstrap.$region.$domain/
cloudformation_url=https://cloudformation.$region.$domain/
ec2_url=https://ec2.$region.$domain/
elasticloadbalancing_url=https://elasticloadbalancing.$region.$domain/
iam_url=https://iam.$region.$domain/
monitoring_url=https://monitoring.$region.$domain/
properties_url=https://properties.$region.$domain/
reporting_url=https://reporting.$region.$domain/
s3_url=https://s3.$region.$domain/
sts_url=https://sts.$region.$domain/

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Euca2ools Region for HTTPS Endpoints"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/euca2ools/conf.d/$region.ini"
echo "; Eucalyptus Region $region"
echo
echo "[region $region]"
echo "autoscaling-url = $autoscaling_url"
echo "bootstrap-url = $bootstrap_url"
echo "cloudformation-url = $cloudformation_url"
echo "ec2-url = $ec2_url"
echo "elasticloadbalancing-url = $elasticloadbalancing_url"
echo "iam-url = $iam_url"
echo "monitoring-url = $monitoring_url"
echo "properties-url = $properties_url"
echo "reporting-url = $reporting_url"
echo "s3-url = $s3_url"
echo "sts-url = $sts_url"
echo "user = $region-admin"
echo
echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem"
echo "verify-ssl = true"
echo "EOF"
echo
echo "cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
echo "chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"

if  grep -s -q "ec2-url = $ec2_url" /etc/euca2ools/conf.d/$region.ini; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/euca2ools/conf.d/$region.ini"
        echo "> ; Eucalyptus Region $region"
        echo ">"
        echo "> [region $region]"
        echo "> autoscaling-url = $autoscaling_url"
        echo "> bootstrap-url = $bootstrap_url"
        echo "> cloudformation-url = $cloudformation_url"
        echo "> ec2-url = $ec2_url"
        echo "> elasticloadbalancing-url = $elasticloadbalancing_url"
        echo "> iam-url = $iam_url"
        echo "> monitoring-url = $monitoring_url"
        echo "> properties-url = $properties_url"
        echo "> reporting-url = $reporting_url"
        echo "> s3-url = $s3_url"
        echo "> sts-url = $sts_url"
        echo "> user = $region-admin"
        echo ">"
        echo "> certificate = /usr/share/euca2ools/certs/cert-$region.pem"
        echo "> verify-ssl = true"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Region $region"                                > /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo "[region $region]"                                          >> /etc/euca2ools/conf.d/$region.ini
        echo "autoscaling-url = $autoscaling_url"                        >> /etc/euca2ools/conf.d/$region.ini
        echo "bootstrap-url = $bootstrap_url"                            >> /etc/euca2ools/conf.d/$region.ini
        echo "cloudformation-url = $cloudformation_url"                  >> /etc/euca2ools/conf.d/$region.ini
        echo "ec2-url = $ec2_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "elasticloadbalancing-url = $elasticloadbalancing_url"      >> /etc/euca2ools/conf.d/$region.ini
        echo "iam-url = $iam_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "monitoring-url = $monitoring_url"                          >> /etc/euca2ools/conf.d/$region.ini
        echo "properties-url = $properties_url"                          >> /etc/euca2ools/conf.d/$region.ini
        echo "reporting-url = $reporting_url"                            >> /etc/euca2ools/conf.d/$region.ini
        echo "s3-url = $s3_url"                                          >> /etc/euca2ools/conf.d/$region.ini
        echo "sts-url = $sts_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "user = $region-admin"                                      >> /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem" >> /etc/euca2ools/conf.d/$region.ini
        echo "verify-ssl = false"                                        >> /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
        cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem
        echo "# chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"
        chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem

        next
    fi
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Proxy configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Proxy configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
