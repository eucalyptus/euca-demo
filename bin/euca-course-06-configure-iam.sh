#/bin/bash
#
# This script configures Eucalyptus IAM
#
# This script should only be run on the Cloud Controller host
#
# Each student MUST run all prior scripts on relevant hosts prior to this script.
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

if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: /root/creds/eucalyptus/admin/eucarc"
    exit 20
fi


#  5. Execute Course Lab

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
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
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Administrator Password"
echo "    - The default password was removed in 4.0, so we must"
echo "      set it to get into the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usermodloginprofile -u admin -p password"

run 50

if [ $choice = y ]; then
    echo
    echo "# euare-usermodloginprofile -u admin -p password"
    euare-usermodloginprofile -u admin -p password

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Accounts"
echo "    - We will create two accounts, for Ops and Engineering"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-accountcreate -a ops"
echo
echo "euare-accountcreate -a engineering"

run 50

if [ $choice = y ]; then
    echo
    echo "# euare-accountcreate -a ops"
    euare-accountcreate -a ops
    pause

    echo "# euare-accountcreate -a engineering"
    euare-accountcreate -a engineering

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Users"
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

run 50

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

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Login Profiles"
echo "    - Within the ops account, create profiles for:
echo "      - bob, sally
echo
echo "============================================================"
echo 
echo "Commands:"
echo 
echo "euare-useraddloginprofile --as-account ops -u bob -p mypassword"
echo "euare-useraddloginprofile --as-account ops -u sally -p mypassword"

run 50

if [ $choice = y ]; then
    echo
    echo "# euare-useraddloginprofile --as-account ops -u bob -p mypassword"
    euare-useraddloginprofile --as-account ops -u bob -p mypassword
    echo "# euare-useraddloginprofile --as-account ops -u sally -p mypassword"
    euare-useraddloginprofile --as-account ops -u sally -p mypassword

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Engineering Account Administrator Credentials"
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

run 50

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

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Engineering Account Sally User Credentials"
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

run 50

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

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm current identity"
echo "    - Useful when switching between users and accounts as we're about to do"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usergetattributes"
echo
echo "euare-accountlist"

run 50

if [ $choice = y ]; then
    echo
    echo "# euare-usergetattributes"
    euare-usergetattributes
    pause

    echo "# euare-accountlist"
    euare-accountlist

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm account separation"
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

run

if [ $choice = y ]; then
    echo
    echo "# euca-create-volume -s 1 -z AZ1"
    euca-create-volume -s 1 -z AZ1 | tee /var/tmp/6-9-euca-create-volume.out

    echo -n "Waiting 30 seconds..."
    sleep 30
    echo " Done"
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
    echo " Done"
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Groups as Engineering Account Administrator"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/engineering/admin/eucarc"
echo
echo "euare-groupcreate -g describe"
echo "euare-groupcreate -g full"

run 50

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/engineering/admin/eucarc"
    source /root/creds/engineering/admin/eucarc
    pause

    echo "# euare-groupcreate -g describe"
    euare-groupcreate -g describe
    echo "# euare-groupcreate -g full"
    euare-groupcreate -g full

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Groups and Users"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-grouplistbypath"
echo
echo "euare-userlistbypath"

run 50

if [ $choice = y ]; then
    echo
    echo "# euare-grouplistbypath"
    euare-grouplistbypath
    pause

    echo "# euare-userlistbypath"
    euare-userlistbypath

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Login Profile with custom password as Eucalyptus Administrator"
echo "    - This allows the Ops Account Administrator to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"
echo
echo "euare-usermodloginprofile –u admin --as-account ops –p password123"

run 50

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc
    pause

    echo "# euare-usermodloginprofile -u admin -p password123 --as-account ops"
    euare-usermodloginprofile -u admin -p password123 --as-account ops

    next 50
fi


end=$(date +%s)

echo
echo "IAM configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
