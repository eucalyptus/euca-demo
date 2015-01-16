#!/bin/bash
#
# This script initializes Eucalyptus for demos by performing in advance some auxilliary and/or
# time-consuming dependencies, including:
# - Downloading and installing a CentOS 6.5 image
# - Creating the Demo Account, and downloading administrator credentials
# - Creating the DemoUser and DemoDeveloper users, associated login profiles, and downloading credentials
# - Creating the DemoUsers and DemoDevelopers groups, associating the appropriate users
# - Within the Eucalyptus Account Administrator, creating the DemoKey Keypair
# - Within the Demo Account Administrator, creating the DemoKey Keypair
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

centos_image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz

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

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 10
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 20
fi


#  5. Prepare Eucalyptus for Demos

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Initialize Eucalyptus Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    choose "Continue"
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
if euca-describe-keypairs | grep -s -q "DemoKey"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Keypair for Eucalyptus Administrator"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Keypair for Eucalyptus Administrator"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem"
    echo
    echo "chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem"
        euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem
        echo
        echo "# chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem"
        chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem

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
    echo "$(printf '%2d' $step). Create Login Profile with custom password as Eucalyptus Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - This allows the Ops Account Administrator to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "euare-usermodloginprofile –u admin --as-account ops –p password123"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc
        pause

        echo "# euare-usermodloginprofile -u admin -p password123 --as-account ops"
        euare-usermodloginprofile -u admin -p password123 --as-account ops

        choose "Continue"
    fi
fi



((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Engineering Account Administrator Credentials"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/engineering/admin"
    echo
    echo "euca-get-credentials -u admin -a engineering \\"
    echo "                     /root/creds/engineering/admin/eng-admin.zip"
    echo
    echo "unzip /root/creds/engineering/admin/eng-admin.zip \\"
    echo "      -d /root/creds/engineering/admin/"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/engineering/admin"
        mkdir -p /root/creds/engineering/admin
        pause

        echo "# euca-get-credentials -u admin -a engineering \\"
        echo ">                      /root/creds/engineering/admin/eng-admin.zip"
        euca-get-credentials -u admin -a engineering \
                             /root/creds/engineering/admin/eng-admin.zip
        pause

        echo "# unzip /root/creds/engineering/admin/eng-admin.zip \\"
        echo ">       -d /root/creds/engineering/admin/"
        unzip /root/creds/engineering/admin/eng-admin.zip \
              -d /root/creds/engineering/admin/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/engineering/admin/eucarc    # invisibly fix deprecation message

        choose "Continue"
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q "^demouser"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Users"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Users"
    echo "    - Within the demo account, create users:
    echo "      - demouser      - used to demo user-level features
    echo "      - demodeveloper - used to demo developer-level features
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate --as-account demo -u demouser"
    echo "euare-usercreate --as-account demo -u demodeveloper"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate --as-account demo -u demouser"
        euare-usercreate --as-account demo -u demouser
        echo "# euare-usercreate --as-account demo -u demodeveloper"
        euare-usercreate --as-account demo -u demodeveloper

        choose "Continue"
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q "^demouser"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo Users"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Login Profiles"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Within the ops account, create profiles for:
    echo "      - bob, sally
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile --as-account ops -u bob -p mypassword"
    echo "euare-useraddloginprofile --as-account ops -u sally -p mypassword"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile --as-account ops -u bob -p mypassword"
        euare-useraddloginprofile --as-account ops -u bob -p mypassword
        echo "# euare-useraddloginprofile --as-account ops -u sally -p mypassword"
        euare-useraddloginprofile --as-account ops -u sally -p mypassword

        choose "Continue"
    fi
fi




((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Engineering Account Sally User Credentials"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/ops/sally"
    echo
    echo "euca-get-credentials -u sally -a ops \\"
    echo "                     /root/creds/ops/sally/ops-sally.zip"
    echo
    echo "unzip /root/creds/ops/sally/ops-sally.zip \\"
    echo "      -d /root/creds/ops/sally/"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/ops/sally"
        mkdir -p /root/creds/ops/sally
        pause

        echo "# euca-get-credentials -u sally -a ops \\"
        echo ">                      /root/creds/ops/sally/ops-sally.zip"
        euca-get-credentials -u sally -a ops \
                             /root/creds/ops/sally/ops-sally.zip
        pause

        echo "# unzip /root/creds/ops/sally/ops-sally.zip \\"
        echo ">       -d /root/creds/ops/sally/"
        unzip /root/creds/ops/sally/ops-sally.zip \
              -d /root/creds/ops/sally/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/ops/sally/eucarc    # invisibly fix deprecation message

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Groups as Engineering Account Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "source /root/creds/engineering/admin/eucarc"
    echo
    echo "euare-groupcreate -g describe"
    echo "euare-groupcreate -g full"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# source /root/creds/engineering/admin/eucarc"
        source /root/creds/engineering/admin/eucarc
        pause

        echo "# euare-groupcreate -g describe"
        euare-groupcreate -g describe
        echo "# euare-groupcreate -g full"
        euare-groupcreate -g full

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Groups and Users"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-grouplistbypath"
    echo
    echo "euare-userlistbypath"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-grouplistbypath"
        euare-grouplistbypath
        pause

        echo "# euare-userlistbypath"
        euare-userlistbypath

        choose "Continue"
    fi
fi




echo
echo "Eucalyptus configured for demo scripts"
