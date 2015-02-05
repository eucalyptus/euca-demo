#!/bin/bash
#
# This script initializes a Demo Account within Eucalyptus with dependencies used in demos, including:
# - Confirms the Demo Image is available to the Demo Account
# - Creates a Demo Keypair for the Demo Account Administrator
# - Creates a Demo User (named "user"), intended for user-level, mostly read-only, operations
# - Creates the Demo User Login Profile, allowing the use of the console
# - Downloads the Demo User Credentials, allowing use of the API
# - Creates a Demo Users Group (named "users"), and makes the Demo User a member
# - Creates a Demo Developer (named "developer"), intended for developer-level, mostly read-write, operations
# - Creates the Demo Developer Login Profile, allowing the use of the console
# - Downloads the Demo Developer Credentials, allowing use of the API
# - Creates a Demo Developers Group (named "developers"), and makes the Demo Developer a member
#
# The euca-demo-01-initialize-account.sh script should be run by the Eucalyptus Administrator
# prior to running this script.
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

demo_user=user
demo_user_password=${demo_user}123
demo_users=users

demo_developer=developer
demo_developer_password=${demo_developer}123
demo_developers=developers

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
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

while getopts Isfa:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
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

if [ ! -r /root/creds/$account/admin/eucarc ]; then
    echo "-a $account invalid: Could not find Account Administrator credentials!"
    echo "   Expected to find: /root/creds/$account/admin/eucarc"
    exit 21
fi


#  5. Prepare Eucalyptus Demo Account for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Demo ($account) Account Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat /root/creds/$account/admin/eucarc"
echo
echo "source /root/creds/$account/admin/eucarc"

next

echo
echo "# cat /root/creds/$account/admin/eucarc"
cat /root/creds/$account/admin/eucarc
pause

echo "# source /root/creds/$account/admin/eucarc"
source /root/creds/$account/admin/eucarc

next


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Images available to Demo ($account) Account Administrator"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images -a"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images -a"
    euca-describe-images -a

    next
fi


((++step))
if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r /root/creds/$account/admin/admin-demo.pem ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    euca-delete-keypair admin-demo
    rm -f /root/creds/$account/admin/admin-demo.pem

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Demo Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair admin-demo | tee /root/creds/$account/admin/admin-demo.pem"
    echo
    echo "chmod 0600 /root/creds/$account/admin/admin-demo.pem"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee /root/creds/$account/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee /root/creds/$account/admin/admin-demo.pem
        echo "#"
        echo "# chmod 0600 /root/creds/$account/admin/admin-demo.pem"
        chmod 0600 /root/creds/$account/admin/admin-demo.pem

        next
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q ":user/$demo_user$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user)"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u $demo_user"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_user"
        euare-usercreate -u $demo_user

        next
    fi
fi


((++step))
if euare-usergetloginprofile -u $demo_user &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user) Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user) Login Profile"
    echo "    - This allows the Demo Account User to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u $demo_user -p $demo_user_password"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_user -p $demo_user_password"
        euare-useraddloginprofile -u $demo_user -p $demo_user_password

        next
    fi
fi


((++step))
if [ -r /root/creds/$account/$demo_user/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($account) Account User ($demo_user) Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($account) Account User ($demo_user) Credentials"
    echo "    - This allows the Demo Account User to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$account/$demo_user"
    echo
    echo "rm -f /root/creds/$account/$demo_user.zip"
    echo
    echo "euca-get-credentials -u $demo_user -a $account \\"
    echo "                     /root/creds/$account/$demo_user.zip"
    echo
    echo "unzip -uo /root/creds/$account/$demo_user.zip \\"
    echo "       -d /root/creds/$account/$demo_user/"
    echo
    echo "cat /root/creds/$account/$demo_user/eucarc"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$account/$demo_user"
        mkdir -p /root/creds/$account/$demo_user
        pause

        echo "# rm -f /root/creds/$account/$demo_user.zip"
        rm -f /root/creds/$account/$demo_user.zip
        pause

        echo "# euca-get-credentials -u $demo_user -a $account \\"
        echo ">                      /root/creds/$account/$demo_user.zip"
        euca-get-credentials -u $demo_user -a $account \
                             /root/creds/$account/$demo_user.zip
        pause

        echo "# unzip -uo /root/creds/$account/$demo_user.zip \\"
        echo ">        -d /root/creds/$account/$demo_user/"
        unzip -uo /root/creds/$account/$demo_user.zip \
               -d /root/creds/$account/$demo_user/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" /root/creds/$account/$demo_user/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 /root/creds/$account/$demo_user/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 /root/creds/$account/$demo_user/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" /root/creds/$account/$demo_user/eucarc
        fi
        pause

        echo "# cat /root/creds/$account/$demo_user/eucarc"
        cat /root/creds/$account/$demo_user/eucarc

        next
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/$demo_users$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($demo_users) Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($demo_users) Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g $demo_users"
    echo
    echo "euare-groupadduser -g $demo_users -u $demo_user"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_users"
        euare-groupcreate -g $demo_users
        echo "#"
        echo "# euare-groupadduser -g $demo_users -u $demo_user"
        euare-groupadduser -g $demo_users -u $demo_user

        next
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q ":user/$demo_developer$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer)"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u $demo_developer"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_developer"
        euare-usercreate -u $demo_developer

        next
    fi
fi


((++step))
if euare-usergetloginprofile -u $demo_developer &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer) Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer) Login Profile"
    echo "    - This allows the Demo Account Developer to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"
        euare-useraddloginprofile -u $demo_developer -p $demo_developer_password

        next
    fi
fi


((++step))
if [ -r /root/creds/$account/$demo_developer/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($account) Account Developer ($demo_developer) Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 50

else
    clear
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($account) Account Developer ($demo_developer) Credentials"
    echo "    - This allows the Demo Account Developer to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$account/$demo_developer"
    echo
    echo "rm -f /root/creds/$account/$demo_developer.zip"
    echo
    echo "euca-get-credentials -u $demo_developer -a $account \\"
    echo "                     /root/creds/$account/$demo_developer.zip"
    echo
    echo "unzip -uo /root/creds/$account/$demo_developer.zip \\"
    echo "       -d /root/creds/$account/$demo_developer/"
    echo
    echo "cat /root/creds/$account/$demo_developer/eucarc"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$account/$demo_developer"
        mkdir -p /root/creds/$account/$demo_developer
        pause

        echo "# rm -f /root/creds/$account/$demo_developer.zip"
        rm -f /root/creds/$account/$demo_developer.zip
        pause

        echo "# euca-get-credentials -u $demo_developer -a $account \\"
        echo ">                      /root/creds/$account/$demo_developer.zip"
        euca-get-credentials -u $demo_developer -a $account \
                             /root/creds/$account/$demo_developer.zip
        pause

        echo "# unzip -uo /root/creds/$account/$demo_developer.zip \\"
        echo ">        -d /root/creds/$account/$demo_developer/"
        unzip -uo /root/creds/$account/$demo_developer.zip \
               -d /root/creds/$account/$demo_developer/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" /root/creds/$account/$demo_developer/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 /root/creds/$account/$demo_developer/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 /root/creds/$account/$demo_developer/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" /root/creds/$account/$demo_developer/eucarc
        fi
        pause

        echo "# cat /root/creds/$account/$demo_developer/eucarc"
        cat /root/creds/$account/$demo_developer/eucarc

        next
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/$demo_developers$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($demo_developers) Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 50

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($demo_developers) Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g $demo_developers"
    echo
    echo "euare-groupadduser -g $demo_developers -u $demo_developer"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_developers"
        euare-groupcreate -g $demo_developers
        echo "#"
        echo "# euare-groupadduser -g $demo_developers -u $demo_developer"
        euare-groupadduser -g $demo_developers -u $demo_developer

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
echo
echo "euare-userlistbypath"
echo
echo "euare-grouplistbypath"
echo "euare-grouplistusers -g $demo_users"
echo "euare-grouplistusers -g $demo_developers"

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
    pause

    echo "# euare-userlistbypath"
    euare-userlistbypath
    pause

    echo "# euare-grouplistbypath"
    euare-grouplistbypath
    echo "#"
    echo "# euare-grouplistusers -g $demo_users"
    euare-grouplistusers -g $demo_users
    echo "#"
    echo "# euare-grouplistusers -g $demo_developers"
    euare-grouplistusers -g $demo_developers

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Demo Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
