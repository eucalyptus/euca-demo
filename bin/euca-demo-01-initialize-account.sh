#!/bin/bash
#
# This script initializes Eucalyptus with a Demo Account, including:
# - Within the Eucalyptus Account, creates a Demo Keypair
# - Creates a Demo Account (default name is "demo", but this can be overridden)
# - Creates the Demo Account Administrator Login Profile, allowing the use of the console
# - Downloads the Demo Account Administrator Credentials, allowing use of the API
# - Downloads a CentOS 6.5 image
# - Installs the CentOS 6.5 image
# - Authorizes use of the CentOS 6.5 image by the Demo Account
#
# This script should be run by the Eucalyptus Administrator, then the
# euca-demo-02-initialize_dependencies.sh script should be run by the
# Demo Account Administrator to create additional objects in the account.
#
# Both scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

demo_admin_password=demo123

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
demo_account=demo
#image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz
image_url=http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
#image_url=http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a demo_account] [-u image_url]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -a demo_account   account to create for use in demos (default: $demo_account)"
    echo "  -u image_url      URL to Demo CentOS image (default: $image_url)"
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

while getopts Isfa:u:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  demo_account="$OPTARG";;
    u)  image_url="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if ! curl -s --head $image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "-u $image_url invalid: attempts to reach this URL failed"
    exit 5
fi
 
if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Account Administrator credentials!"
    echo "Expected to find: /root/creds/eucalyptus/admin/eucarc"
    exit 20
fi


#  5. Prepare Eucalyptus for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

next

echo
echo "# source /root/creds/eucalyptus/admin/eucarc"
source /root/creds/eucalyptus/admin/eucarc

next 50


((++step))
if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r /root/creds/eucalyptus/admin/admin-demo.pem ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Eucalyptus Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    euca-delete-keypair admin-demo
    rm -f /root/creds/eucalyptus/admin/admin-demo.pem

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Eucalyptus Administrator Demo Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem"
    echo
    echo "chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem
        echo
        echo "# chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem"
        chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem

        next
    fi
fi


((++step))
if euare-accountlist | grep -s -q "^$demo_account"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountcreate -a $demo_account"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate -a $demo_account"
        euare-accountcreate -a $demo_account

        next
    fi
fi


((++step))
if euare-usergetloginprofile -u admin --as-account $demo_account &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Administrator Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Administrator Login Profile"
    echo "    - This allows the Demo Account Administrator to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usermodloginprofile –u admin –p $demo_admin_password -as-account $demo_account"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $demo_account"
        euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $demo_account

        next
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/admin/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account Administrator Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account Administrator Credentials"
    echo "    - This allows the Demo Account Administrator to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$demo_account/admin"
    echo
    echo "euca-get-credentials -u admin -a $demo_account \\"
    echo "                     /root/creds/$demo_account/admin/admin.zip"
    echo
    echo "unzip /root/creds/$demo_account/admin/admin.zip \\"
    echo "      -d /root/creds/$demo_account/admin/"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$demo_account/admin"
        mkdir -p /root/creds/$demo_account/admin
        pause

        echo "# euca-get-credentials -u admin -a $demo_account \\"
        echo ">                      /root/creds/$demo_account/admin/admin.zip"
        euca-get-credentials -u admin -a $demo_account \
                             /root/creds/$demo_account/admin/admin.zip
        pause

        echo "# unzip /root/creds/$demo_account/admin/admin.zip \\"
        echo ">       -d /root/creds/$demo_account/admin/"
        unzip /root/creds/$demo_account/admin/admin.zip \
              -d /root/creds/$demo_account/admin/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/$demo_account/admin/eucarc    # invisibly fix deprecation message

        next
    fi
fi


((++step))
if [ -r /root/centos.raw ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo Image (CentOS 6.5)"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo Image (CentOS 6.5)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "wget $image_url -O /root/centos.raw.xz"
    echo
    echo "xz -v -d /root/centos.raw.xz"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# wget $image_url -O /root/centos.raw.xz"
        wget $image_url -O /root/centos.raw.xz
        pause

        echo "xz -v -d /root/centos.raw.xz"
        xz -v -d /root/centos.raw.xz

        next
    fi
fi


((++step))
if euca-describe-images | grep -s -q "centos.raw.manifest.xml"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Demo Image"
    echo "    - Already Installed!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Demo Image"
    echo "    - NOTE: This can take a couple minutes..."
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-install-image.out

        next
    fi
fi


((++step))
demo_account_id=$(euare-accountlist | grep "^$demo_account" | cut -f2)
image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)

if euca-describe-images -x $demo_account_id | grep -s -q $image_id; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Authorize Demo ($demo_account) Account use of Demo Image"
    echo "    - Already Authorized!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Authorize Demo ($demo_account) Account use of Demo Image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-image-attribute -l -a $demo_account_id $image_id"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $demo_account_id $image_id"
        euca-modify-image-attribute -l -a $demo_account_id $image_id

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Demo Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images"
echo
echo "euca-describe-keypairs"
echo
echo "euare-accountlist"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euare-accountlist"
    euare-accountlist

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
unset a; [ $demo_account = demo ] || a=" -a $demo_account"
echo "Please run \"euca-demo-02-initialize-dependencies$a\" to complete demo initialization"
