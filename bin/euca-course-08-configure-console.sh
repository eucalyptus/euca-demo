#/bin/bash
#
# This script configures Eucalyptus Console
#
# Each student MUST run all prior scripts on all nodes prior to this script.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
interactive=1

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I]"
    echo "  -I non-interactive"
}

pause() {
    if [ "$interactive" = 1 ]; then
        read pause
    else
        sleep 5
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed[y]?"
        echo
        echo -n "$prompt2"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
            "n" | "N" | "no" | "No") choice=n ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        sleep 5
        choice=y
    fi
}


#  3. Parse command line options

while getopts I arg; do
    case $arg in
    I)  interactive=0;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo
    echo "Please set environment variables first"
    exit 1
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y
[ "$(hostname -s)" = "$EUCA_UFS_HOST_NAME" ] && is_ufs=y
[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y
[ "$(hostname -s)" = "$EUCA_CC_HOST_NAME" ] && is_cc=y
[ "$(hostname -s)" = "$EUCA_SC_HOST_NAME" ] && is_sc=y
[ "$(hostname -s)" = "$EUCA_OSP_HOST_NAME" ] && is_osp=y
[ "$(hostname -s)" = "$EUCA_NC1_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC2_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC3_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC4_HOST_NAME" ] && is_nc=y


#  5. Execute Course Lab

if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure Eucalyptus Console Configuration file"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

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

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start Eucalyptus Console service"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# chkconfig eucaconsole on"
        chkconfig eucaconsole on
        pause

        echo "# service eucaconsole start"
        service eucaconsole start

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Stop Eucalyptus Console service"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Next we will setup an Nginx reverse proxy to implement SSL"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "service eucaconsole stop"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# service eucaconsole stop"
        service eucaconsole stop

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Nginx package"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - This is needed for SSL support"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "yum install -y nginx"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# yum install -y nginx"
        yum install -y nginx

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure Nginx"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

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

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start Nginx service"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "chkconfig nginx on"
    echo
    echo "service nginx start"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# chkconfig nginx on"
        chkconfig nginx on
        pause

        echo "# service nginx start"
        service nginx start

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure Eucalyptus Console for SSL"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "sed -i -e '/^session.secure =/s/= .*$/= true/' \\"
    echo "       -e '/^session.secure/a\\"
    echo "sslcert=/etc/eucaconsole/console.crt\\"
    echo "sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini"

    choose "Execute"

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

        choose "Continue"
    fi
fi


if [ $is_mc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start Eucalyptus Console service"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Confirm Console is now configured for SSL, should be:"
    echo "      https://$EUCA_UFS_PUBLIC_IP"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "service eucaconsole start"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# service eucaconsole start"
        service eucaconsole start

        choose "Continue"
    fi
fi


echo
echo "Eucalyptus Console configuration complete"
