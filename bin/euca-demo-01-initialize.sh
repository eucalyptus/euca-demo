#!/bin/bash
#
# This script initializes Eucalyptus for demos by performing in advance some auxilliary and/or
# time-consuming dependencies, including:
# - Downloads and installs a CentOS 6.5 image
# - Creates the demo Account, and downloads it's admin credentials
# - Within the demo Account, creates the user and developer Users and associated Login Profiles, then downloads credentials
# - Within the demo Account, creates the users and developers Groups, then associates the appropriate Users
# - Within the Eucalyptus Account Administrator, creates the admin-demo Keypair
# - Within the demo Account Administrator, creates the admin-demo Keypair
# - Within the demo user User, creates the user-demo Keypair
# - Within the demo developer User, creates the developer-demo Keypair
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

#centos_image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz
centos_image_url=http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
#centos_image_url=http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz

demo_admin_password=demo123
demo_user_password=user456
demo_developer_password=developer789

step=0
interactive=1
step_min=0
step_wait=10
step_max=60
pause_min=0
pause_wait=2
pause_max=20


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I [-s step_wait] [-p pause_wait]] [-u image_url]"
    echo "  -I             non-interactive"
    echo "  -s step_wait   seconds per step (default: $step_wait)"
    echo "  -p pause_wait  seconds per pause (default: $pause_wait)"
    echo "  -u image_url   URL to CentOS image (default: $centos_image_url)"
}

pause() {
    if [ "$interactive" = 1 ]; then
        echo "#"
        read pause
        echo -en "\033[1A\033[2K"    # undo newline from read
    else
        echo "#"
        sleep $pause_wait
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed (y,n,q)[y]"
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
        echo
        seconds=$step_wait
        echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
            fi
            sleep 1
            ((seconds--))
        done
        echo
        choice=y
    fi
}

wait() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt3="$1 (y)[y]"
        [ -z "$1" ] && prompt3="Proceed (y)[y]"
        echo
        echo -n "$prompt3"
        read alwaysyes
    else
        echo
        seconds=$step_wait
        echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
            fi
            sleep 1
            ((seconds--))
        done
        echo
    fi
    choice=y
}


#  3. Parse command line options

while getopts Is:p:u: arg; do
    case $arg in
    I)  interactive=0;;
    s)  step_wait="$OPTARG";;
    p)  pause_wait="$OPTARG";;
    u)  centos_image_url="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

if [[ $step_wait =~ ^[0-9]+$ ]]; then
    if ((step_wait < step_min || step_wait > step_max)); then
        echo "-s $step_wait invalid: value must be between $step_min and $step_max seconds"
        exit 5
    fi
else
    echo "-s $step_wait illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_wait =~ ^[0-9]+$ ]]; then
    if ((pause_wait < pause_min || pause_wait > pause_max)); then
        echo "-p $pause_wait invalid: value must be between $pause_min and $pause_max seconds"
        exit 7
    fi
else
    echo "-p $pause_wait illegal: must be a positive integer"
    exit 6
fi

if ! curl -s --head $centos_image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo
    echo "-u $centos_image_url invalid: attempts to reach this URL failed"
    exit 8
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 10
fi

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 20
fi


#  5. Prepare Eucalyptus for Demos

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

wait "Execute"

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    choose "Continue"
fi


((++step))
if euca-describe-keypairs | grep -s -q "admin-demo"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Eucalyptus Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
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

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem
        echo
        echo "# chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem"
        chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem

        choose "Continue"
    fi
fi


((++step))
if euare-accountlist | grep -s -q "^demo"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountcreate -a demo"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate -a demo"
        euare-accountcreate -a demo

        choose "Continue"
    fi
fi


((++step))
if euare-usergetloginprofile -u admin --as-account demo &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Administrator Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Administrator Login Profile"
    echo "    - This allows the Demo Account Administrator to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usermodloginprofile –u admin –p $demo_admin_password -as-account demo"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usermodloginprofile -u admin -p $demo_admin_password --as-account demo"
        euare-usermodloginprofile -u admin -p $demo_admin_password --as-account demo

        choose "Continue"
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

    choose "Continue"

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
    echo "wget $centos_image_url -O /root/centos.raw.xz"
    echo
    echo "xz -v -d /root/centos.raw.xz"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# wget $centos_image_url -O /root/centos.raw.xz"
        wget $centos_image_url -O /root/centos.raw.xz
        pause

        echo "xz -v -d /root/centos.raw.xz"
        xz -v -d /root/centos.raw.xz

        choose "Continue"
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

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Demo Image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-install-image.out

        choose "Continue"
    fi
fi


((++step))
account=$(euare-accountlist | grep -s -q "^demo" | cut -f2)
image=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo Account use of Demo Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute -l -a $account $image"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euca-modify-image-attribute -l -a $account $image"
    euca-modify-image-attribute -l -a $account $image

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Account Administrator Credentials"
echo "    - This allows the Demo Account Administrator to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p /root/creds/demo/admin"
echo
echo "euca-get-credentials -u admin -a demo \\"
echo "                     /root/creds/demo/admin/admin.zip"
echo
echo "unzip /root/creds/demo/admin/admin.zip \\"
echo "      -d /root/creds/demo/admin/"

choose "Execute"

if [ $choice = y | ! -r /root/creds/demo/admin/eucarc ]; then
    echo
    echo "# mkdir -p /root/creds/demo/admin"
    mkdir -p /root/creds/demo/admin
    pause

    echo "# euca-get-credentials -u admin -a demo \\"
    echo ">                      /root/creds/demo/admin/admin.zip"
    euca-get-credentials -u admin -a demo \
                         /root/creds/demo/admin/admin.zip
    pause

    echo "# unzip /root/creds/demo/admin/admin.zip \\"
    echo ">       -d /root/creds/demo/admin/"
    unzip /root/creds/demo/admin/admin.zip \
          -d /root/creds/demo/admin/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/demo/admin/eucarc    # invisibly fix deprecation message

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Demo Account Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/demo/admin/eucarc"

wait "Execute"

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/demo/admin/eucarc"
    source /root/creds/demo/admin/eucarc

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Images available to Demo Account Administrator"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images -a"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images -a"
    euca-describe-images -a

    choose "Continue"
fi


((++step))
if euca-describe-keypairs | grep -s -q "admin-demo"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Administrator Demo Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair admin-demo | tee > /root/creds/demo/admin/admin-demo.pem"
    echo
    echo "chmod 0600 /root/creds/demo/admin/admin-demo.pem"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee > /root/creds/demo/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee > /root/creds/demo/admin/admin-demo.pem
        echo
        echo "# chmod 0600 /root/creds/demo/admin/admin-demo.pem"
        chmod 0600 /root/creds/demo/admin/admin-demo.pem

        choose "Continue"
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q "^user"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account User"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account User"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u user"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u user"
        euare-usercreate -u user

        choose "Continue"
    fi
fi


((++step))
if euare-usergetloginprofile -u user &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account User Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account User Login Profile"
    echo "    - This allows the Demo Account User to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u user -p $demo_user_password"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u user -p $demo_user_password"
        euare-useraddloginprofile -u user -p $demo_user_password

        choose "Continue"
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Account User Credentials"
echo "    - This allows the Demo Account User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p /root/creds/demo/user"
echo
echo "euca-get-credentials -u user -a demo \\"
echo "                     /root/creds/demo/user/user.zip"
echo
echo "unzip /root/creds/demo/user/user.zip \\"
echo "      -d /root/creds/demo/user/"

choose "Execute"

if [ $choice = y | ! -r /root/creds/demo/user/eucarc ]; then
    echo
    echo "# mkdir -p /root/creds/demo/user"
    mkdir -p /root/creds/demo/user
    pause

    echo "# euca-get-credentials -u user -a demo \\"
    echo ">                      /root/creds/demo/user/user.zip"
    euca-get-credentials -u user -a demo \
                         /root/creds/demo/user/user.zip
    pause

    echo "# unzip /root/creds/demo/user/user.zip \\"
    echo ">       -d /root/creds/demo/user/"
    unzip /root/creds/demo/user/user.zip \
          -d /root/creds/demo/user/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/demo/user/eucarc    # invisibly fix deprecation message

    choose "Continue"
fi


((++step))
if euare-grouplistbypath | grep -s -q "^users"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Users Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Users Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g users"
    echo
    echo "euare-groupadduser -g users -u user"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g users"
        euare-groupcreate -g users
        echo "#"
        echo "# euare-groupadduser -g users -u user"
        euare-groupadduser -g users -u user

        choose "Continue"
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q "^developer"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developer"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developer"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u developer"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u developer"
        euare-usercreate -u developer

        choose "Continue"
    fi
fi


((++step))
if euare-usergetloginprofile -u developer &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developer Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developer Login Profile"
    echo "    - This allows the Demo Account Developer to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u developer -p $demo_developer_password"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u user -p $demo_developer_password"
        euare-useraddloginprofile -u user -p $demo_developer_password

        choose "Continue"
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Account Developer Credentials"
echo "    - This allows the Demo Account Developer to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p /root/creds/demo/developer"
echo
echo "euca-get-credentials -u developer -a demo \\"
echo "                     /root/creds/demo/developer/developer.zip"
echo
echo "unzip /root/creds/demo/developer/developer.zip \\"
echo "      -d /root/creds/demo/developer/"

choose "Execute"

if [ $choice = y | ! -r /root/creds/demo/developer/eucarc ]; then
    echo
    echo "# mkdir -p /root/creds/demo/developer"
    mkdir -p /root/creds/demo/developer
    pause

    echo "# euca-get-credentials -u developer -a demo \\"
    echo ">                      /root/creds/demo/developer/developer.zip"
    euca-get-credentials -u developer -a demo \
                         /root/creds/demo/developer/developer.zip
    pause

    echo "# unzip /root/creds/demo/developer/developer.zip \\"
    echo ">       -d /root/creds/demo/developer/"
    unzip /root/creds/demo/developer/developer.zip \
          -d /root/creds/demo/developer/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/demo/developer/eucarc    # invisibly fix deprecation message

    choose "Continue"
fi


((++step))
if euare-grouplistbypath | grep -s -q "^developers"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developers Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Account Developers Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g developers"
    echo
    echo "euare-groupadduser -g developers -u developer"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g developers"
        euare-groupcreate -g developers
        echo "#"
        echo "# euare-groupadduser -g developers -u developer"
        euare-groupadduser -g developers -u developer

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
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
    echo "euare-accountlist"
    echo
    echo "euare-describe-images"
    echo
    echo "euca-describe-keypairs"
    echo
    echo "euare-userlistbypath"
    echo
    echo "euare-grouplistbypath"
    echo "euare-grouplistusers -g users"
    echo "euare-grouplistusers -g developers"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-accountlist"
        euare-accountlist
        pause

        echo "# euca-describe-images"
        euca-describe-images
        pause

        echo "# euca-describe-keypairs"
        euca-describe-keypairs
        pause

        echo "# euare-userlistbypath"
        euare-userlistbypath
        pause

        echo "# euare-grouplistbypath"
        euare-grouplistbypath
        echo "#"
        echo "# euare-grouplistusers -g users
        euare-grouplistusers -g users
        echo "#"
        echo "# euare-grouplistusers -g developers
        euare-grouplistusers -g developers

        choose "Continue"
    fi
fi


echo
echo "Eucalyptus configured for demo scripts"
