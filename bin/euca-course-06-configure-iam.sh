#/bin/bash
#
# This script configures Eucalyptus IAM
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
step_min=0
step_wait=10
step_max=60
pause_min=0
pause_wait=2
pause_max=20

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I [-s step_wait] [-p pause_wait]]"
    echo "  -I             non-interactive"
    echo "  -s step_wait   seconds per step (default: $step_wait)"
    echo "  -p pause_wait  seconds per pause (default: $pause_wait)"
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

while getopts Is:p: arg; do
    case $arg in
    I)  interactive=0;;
    s)  step_wait="$OPTARG";;
    p)  pause_wait="$OPTARG";;
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

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 10
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

((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Use Administrator credentials"
    echo "    - This step is only run on the Cloud Controller host"
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
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure Eucalyptus Administrator Password"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The default password was removed in 4.0, so we must"
    echo "      set it to get into the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usermodloginprofile -u admin -p password"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usermodloginprofile -u admin -p password"
        euare-usermodloginprofile -u admin -p password

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Accounts"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - We will create two accounts, for Ops and Engineering"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountcreate -a ops"
    echo
    echo "euare-accountcreate -a engineering"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate -a ops"
        euare-accountcreate -a ops
        pause

        echo "# euare-accountcreate -a engineering"
        euare-accountcreate -a engineering

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Users"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Within the ops account, create users:
    echo "      - bob, sally
    echo "    - Within the engineering account, create users:
    echo "      - fred, robert, sarah
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate --as-account ops -u bob"
    echo "euare-usercreate --as-account ops -u sally"
    echo
    echo "euare-usercreate --as-account engineering -u fred"
    echo "euare-usercreate --as-account engineering -u robert"
    echo "euare-usercreate --as-account engineering -u sarah"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate --as-account ops -u bob"
        euare-usercreate --as-account ops -u bob
        echo "# euare-usercreate --as-account ops -u sally"
        euare-usercreate --as-account ops -u sally
        pause

        echo "# euare-usercreate --as-account engineering -u fred"
        euare-usercreate --as-account engineering -u fred
        echo "# euare-usercreate --as-account engineering -u robert"
        euare-usercreate --as-account engineering -u robert
        echo "# euare-usercreate --as-account engineering -u sarah"
        euare-usercreate --as-account engineering -u sarah

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
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
    echo "$(printf '%2d' $step). Confirm current identity"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Useful when switching between users and accounts as we're about to do"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usergetattributes"
    echo
    echo "euare-accountlist"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euare-usergetattributes"
        euare-usergetattributes
        pause

        echo "# euare-accountlist"
        euare-accountlist

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm account separation"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Create a volume as the Eucalyptus Account Administrator"
    echo "    - Switch to the Engineering Account Administrator"
    echo "    - Validate the volume is no longer visible"
    echo "    - Switch back to the Eucalyptus Account Administrator"
    echo "    - Delete the volume created for this test"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-volume -s 1 -z AZ1"
    echo
    echo "euca-describe-volumes"
    echo
    echo "source /root/creds/engineering/admin/eucarc"
    echo
    echo "euca-describe-volumes"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "euca-delete-volume vol-xxxxxx"
    echo
    echo "euca-describe-volumes"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-volume -s 1 -z AZ1"
        euca-create-volume -s 1 -z AZ1 | tee /var/tmp/6-9-euca-create-volume.out

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# source /root/creds/engineering/admin/eucarc"
        source /root/creds/engineering/admin/eucarc
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc
        pause
 
        volume=$(cut -f2 /var/tmp/6-9-euca-create-volume.out)

        echo "# euca-delete-volume $volume"
        euca-delete-volume $volume

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes

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


((++step))
if [ $is_clc = y ]; then
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


echo
echo "IAM configuration complete"
