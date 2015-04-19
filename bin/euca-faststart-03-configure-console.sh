#/bin/bash
#
# This script configures Eucalyptus Management Console after a Faststart installation
#
# This should be run immediately after the Faststart DNS configuration script
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

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
certificate=0

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -c  install wildcard SSL certificate"
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

while getopts Isfc? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  certificate=1;;
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

# This step done by FastStart, for now we will not modify
#((++step))
#clear
#echo
#echo "============================================================"
#echo
#echo "$(printf '%2d' $step). Configure Eucalyptus Console Configuration file"
#echo "    - Using sed to edit file, then displaying changes made"
#echo
#echo "============================================================"
#echo
#echo "Commands:"
#echo
#echo "cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
#echo
#echo "sed -i -e \"/^clchost = localhost\$/s/localhost/$EUCA_UFS_PUBLIC_IP/\" \"
#echo "       -e \"/# since eucalyptus allows for different services to be located on different/d\" \"
#echo "       -e \"/# physical hosts, you may override the above host and port for each service./d\" \"
#echo "       -e \"/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d\" \"
#echo "       -e \"/For each service, you can specify a different host and\/or port, for example;/d\" \"
#echo "       -e \"/#elb.host=10.20.30.40/d\" \"
#echo "       -e \"/#elb.port=443/d\" \"
#echo "       -e \"/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d\" \"
#echo "       -e \"/# that won't work from client's browsers./d\" \"
#echo "       -e \"/#s3.host=<your host IP or name>/d\" /etc/eucaconsole/console.ini
#echo
#echo "more /etc/eucaconsole/console.ini"
#
#run 150
#
#if [ $choice = y ]; then
#    echo
#    echo "# cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.faststart"
#    cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.orig
#    echo "#"
#    echo "# sed -i -e \"/^clchost = localhost\$/s/localhost/$EUCA_UFS_PUBLIC_IP/\" \"
#    echo "         -e \"/# since eucalyptus allows for different services to be located on different/d\" \"
#    echo "         -e \"/# physical hosts, you may override the above host and port for each service./d\" \"
#    echo "         -e \"/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d\" \"
#    echo "         -e \"/For each service, you can specify a different host and\/or port, for example;/d\" \"
#    echo "         -e \"/#elb.host=10.20.30.40/d\" \"
#    echo "         -e \"/#elb.port=443/d\" \"
#    echo "         -e \"/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d\" \"
#    echo "         -e \"/# that won't work from client's browsers./d\" \"
#    echo "         -e \"/#s3.host=<your host IP or name>/d\" /etc/eucaconsole/console.ini
#    sed -i -e "/^clchost = localhost$/s/localhost/$EUCA_UFS_PUBLIC_IP/" \
#          -e "/# since eucalyptus allows for different services to be located on different/d" \
#           -e "/# physical hosts, you may override the above host and port for each service./d" \
#           -e "/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d" \
#           -e "/For each service, you can specify a different host and\/or port, for example;/d" \
#           -e "/#elb.host=10.20.30.40/d" \
#           -e "/#elb.port=443/d" \
#           -e "/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d" \
#           -e "/# that won't work from client's browsers./d" \
#           -e "/#s3.host=<your host IP or name>/d" /etc/eucaconsole/console.ini
#    pause
#
#    echo "more /etc/eucaconsole/console.ini"
#    more /etc/eucaconsole/console.ini
#
#    next
#fi


# This step done by FastStart, for now we will not modify
#((++step))
#clear
#echo
#echo "============================================================"
#echo
#echo "$(printf '%2d' $step). Start Eucalyptus Console service"
#echo "    - When this step is complete, use browser to verify:"
#echo "      https://$EUCA_UFS_PUBLIC_IP:8888"
#echo
#echo "============================================================"
#echo
#echo "Commands:"
#echo
#echo "chkconfig eucaconsole on"
#echo
#echo "service eucaconsole start"
#
#run 50
#
#if [ $choice = y ]; then
#    echo
#    echo "# chkconfig eucaconsole on"
#    chkconfig eucaconsole on
#    pause
#
#    echo "# service eucaconsole start"
#    service eucaconsole start
#
#    next 50
#fi


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
echo " - Initially we will use self-signed SSL certificate"
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
