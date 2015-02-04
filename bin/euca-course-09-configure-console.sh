#/bin/bash
#
# This script configures Eucalyptus Management Console
#
# This script should only be run on a Management Console host
#
# Each student MUST run all prior scripts on relevant hosts prior to this script.
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
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp
prefix=course

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


#  5. Execute Course Lab

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console Configuration file"
echo "    - Using sed to edit file, then displaying changes made"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "sed -i -e \"/#elb.host=10.20.30.40/d\" \\"
echo "       -e \"/#elb.port=443/d\" \\"
echo "       -e \"/For each, you can specify a different host/a\\"
echo "ec2.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "ec2.port=8773\\n\\"
echo "autoscale.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "autoscale.port=8773\\n\\"
echo "cloudwatch.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "cloudwatch.port=8773\\n\\"
echo "elb.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "elb.port=8773\\n\\"
echo "iam.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "iam.port=8773\\n\\"
echo "sts.host=$EUCA_UFS_PUBLIC_IP\\n\\"
echo "sts.port=8773\" /etc/eucaconsole/console.ini"
echo
echo "more /etc/eucaconsole/console.ini"

run 150

if [ $choice = y ]; then
    echo
    echo "# sed -i -e \"/#elb.host=10.20.30.40/d\" \\"
    echo ">        -e \"/#elb.port=443/d\" \\"
    echo ">        -e \"/For each, you can specify a different host/a\\"
    echo "> ec2.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> ec2.port=8773\\n\\"
    echo "> autoscale.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> autoscale.port=8773\\n\\"
    echo "> cloudwatch.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> cloudwatch.port=8773\\n\\"
    echo "> elb.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> elb.port=8773\\n\\"
    echo "> iam.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> iam.port=8773\\n\\"
    echo "> sts.host=$EUCA_UFS_PUBLIC_IP\\n\\"
    echo "> sts.port=8773\" /etc/eucaconsole/console.ini"
    sed -i -e "/#elb.host=10.20.30.40/d" \
           -e "/#elb.port=443/d" \
           -e "/For each, you can specify a different host/a\
ec2.host=$EUCA_UFS_PUBLIC_IP\n\
ec2.port=8773\n\
autoscale.host=$EUCA_UFS_PUBLIC_IP\n\
autoscale.port=8773\n\
cloudwatch.host=$EUCA_UFS_PUBLIC_IP\n\
cloudwatch.port=8773\n\
elb.host=$EUCA_UFS_PUBLIC_IP\n\
elb.port=8773\n\
iam.host=$EUCA_UFS_PUBLIC_IP\n\
iam.port=8773\n\
sts.host=$EUCA_UFS_PUBLIC_IP\n\
sts.port=8773" /etc/eucaconsole/console.ini
    pause

    echo "more /etc/eucaconsole/console.ini"
    more /etc/eucaconsole/console.ini

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Start Eucalyptus Console service"
echo "    - When this step is complete, use browser to verify:"
echo "      https://$EUCA_UFS_PUBLIC_IP:8888"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "chkconfig eucaconsole on"
echo
echo "service eucaconsole start"

run 50

if [ $choice = y ]; then
    echo
    echo "# chkconfig eucaconsole on"
    chkconfig eucaconsole on
    pause

    echo "# service eucaconsole start"
    service eucaconsole start

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Stop Eucalyptus Console service"
echo "    - Next we will setup an Nginx reverse proxy to implement SSL"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "service eucaconsole stop"

run 50

if [ $choice = y ]; then
    echo
    echo "# service eucaconsole stop"
    service eucaconsole stop

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install Nginx package"
echo "    - This is needed for SSL support"
echo
echo "============================================================"
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
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Nginx"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "\cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf"
echo
echo "sed -i -e 's/# \\(listen 443 ssl;$\\)/\\1/' \\"
echo "       -e 's/# \\(ssl_certificate\\)/\\1/' \\"
echo "       -e 's/\\/path\\/to\\/ssl\\/pem_file/\\/etc\\/eucaconsole\\/console.crt/' \\"
echo "       -e 's/\\/path\\/to\\/ssl\\/certificate_key/\\/etc\\/eucaconsole\\/console.key/' /etc/nginx/nginx.conf"

run

if [ $choice = y ]; then
    echo
    echo "# \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf"
    \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf
    pause

    echo "# sed -i -e 's/# \\(listen 443 ssl;$\\)/\\1/' \\"
    echo ">        -e 's/# \\(ssl_certificate\\)/\\1/' \\"
    echo ">        -e 's/\\/path\\/to\\/ssl\\/pem_file/\\/etc\\/eucaconsole\\/console.crt/' \\"
    echo ">        -e 's/\\/path\\/to\\/ssl\\/certificate_key/\\/etc\\/eucaconsole\\/console.key/' /etc/nginx/nginx.conf"
    sed -i -e 's/# \(listen 443 ssl;$\)/\1/' \
           -e 's/# \(ssl_certificate\)/\1/' \
           -e 's/\/path\/to\/ssl\/pem_file/\/etc\/eucaconsole\/console.crt/' \
           -e 's/\/path\/to\/ssl\/certificate_key/\/etc\/eucaconsole\/console.key/' /etc/nginx/nginx.conf

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Start Nginx service"
echo
echo "============================================================"
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
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console for SSL"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "sed -i -e '/^session.secure =/s/= .*$/= true/' \\"
echo "       -e '/^session.secure/a\\"
echo "sslcert=/etc/eucaconsole/console.crt\\"
echo "sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# sed -i -e '/^session.secure =/s/= .*$/= true/' \\"
    echo ">        -e '/^session.secure/a\\"
    echo "> sslcert=/etc/eucaconsole/console.crt\\"
    echo "> sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini"
    sed -i -e '/^session.secure =/s/= .*$/= true/' \
           -e '/^session.secure/a\
sslcert=/etc/eucaconsole/console.crt\
sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Start Eucalyptus Console service"
echo "    - Confirm Console is now configured for SSL, should be:"
echo "      https://$EUCA_UFS_PUBLIC_IP"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "service eucaconsole start"

run 50

if [ $choice = y ]; then
    echo
    echo "# service eucaconsole start"
    service eucaconsole start

    next 50
fi


end=$(date +%s)

echo
echo "Eucalyptus Management Console configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
