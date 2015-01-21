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
percent_min=0
percent_max=500
run_default=10
pause_default=2
next_default=10

interactive=1
demo_account=demo
run_percent=100
pause_percent=100
next_percent=100


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-a demo_account]"
    echo "           [-I [-r run_percent] [-p pause_percent] [-n next_percent]]"
    echo "  -a demo_account   account to create for use in demos (default: $demo_account)"
    echo "  -I                non-interactive"
    echo "  -r run_percent    run prompt timing adjustment % (default: $run_percent)"
    echo "  -p pause_percent  pause delay timing adjustment % (default: $pause_percent)"
    echo "  -n next_percent   next prompt timing adjustment % (default: $next_percent)"
}

run() {
    if [ -z $1 ]; then
        ((seconds=$run_default * $run_percent / 100))
    else
        ((seconds=$1 * $run_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$pause_default * $pause_percent / 100))
    else
        ((seconds=$1 * $pause_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$next_default * $next_percent / 100))
    else
        ((seconds=$1 * $next_percent / 100))
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

while getopts a:Ir:p:n:? arg; do
    case $arg in
    a)  demo_account="$OPTARG";;
    I)  interactive=0;;
    r)  run_percent="$OPTARG";;
    p)  pause_percent="$OPTARG";;
    n)  next_percent="$OPTARG";;
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

if [[ $run_percent =~ ^[0-9]+$ ]]; then
    if ((run_percent < percent_min || run_percent > percent_max)); then
        echo "-r $run_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $run_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_percent =~ ^[0-9]+$ ]]; then
    if ((pause_percent < percent_min || pause_percent > percent_max)); then
        echo "-p $pause_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-p $pause_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $next_percent =~ ^[0-9]+$ ]]; then
    if ((next_percent < percent_min || next_percent > percent_max)); then
        echo "-r $next_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $next_percent illegal: must be a positive integer"
    exit 4
fi

if [ ! -r /root/creds/$demo_account/admin/eucarc ]; then
    echo "-a $demo_account invalid: Could not find Account Administrator credentials!"
    echo "   Expected to find: /root/creds/$demo_account/admin/eucarc"
    exit 10
fi

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 20
fi


#  5. Prepare Eucalyptus Demo Account for Demos

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Demo ($demo_account) Account Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/$demo_account/admin/eucarc"

next 5

echo
echo "# source /root/creds/$demo_account/admin/eucarc"
source /root/creds/$demo_account/admin/eucarc

next 2


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Images available to Demo ($demo_account) Account Administrator"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images -a"

run 5

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images -a"
    euca-describe-images -a

    next 5
fi


((++step))
if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r /root/creds/$demo_account/admin/admin-demo.pem ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    euca-delete-keypair admin-demo
    rm -f /root/creds/$demo_account/admin/admin-demo.pem

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Administrator Demo Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair admin-demo | tee > /root/creds/$demo_account/admin/admin-demo.pem"
    echo
    echo "chmod 0600 /root/creds/$demo_account/admin/admin-demo.pem"

    run

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee > /root/creds/$demo_account/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee > /root/creds/$demo_account/admin/admin-demo.pem
        echo
        echo "# chmod 0600 /root/creds/$demo_account/admin/admin-demo.pem"
        chmod 0600 /root/creds/$demo_account/admin/admin-demo.pem

        next 2
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q ":user/$demo_user$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account User ($demo_user)"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account User ($demo_user)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u $demo_user"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_user"
        euare-usercreate -u $demo_user

        next 2
    fi
fi


((++step))
if euare-usergetloginprofile -u $demo_user &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account User ($demo_user) Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account User ($demo_user) Login Profile"
    echo "    - This allows the Demo Account User to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u $demo_user -p $demo_user_password"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_user -p $demo_user_password"
        euare-useraddloginprofile -u $demo_user -p $demo_user_password

        next 2
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/$demo_user/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account User ($demo_user) Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account User ($demo_user) Credentials"
    echo "    - This allows the Demo Account User to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$demo_account/$demo_user"
    echo
    echo "euca-get-credentials -u $demo_user -a $demo_account \\"
    echo "                     /root/creds/$demo_account/$demo_user/$demo_user.zip"
    echo
    echo "unzip /root/creds/$demo_account/$demo_user/$demo_user.zip \\"
    echo "      -d /root/creds/$demo_account/$demo_user/"

    run

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$demo_account/$demo_user"
        mkdir -p /root/creds/$demo_account/$demo_user
        pause

        echo "# euca-get-credentials -u $demo_user -a $demo_account \\"
        echo ">                      /root/creds/$demo_account/$demo_user/$demo_user.zip"
        euca-get-credentials -u $demo_user -a $demo_account \
                             /root/creds/$demo_account/$demo_user/$demo_user.zip
        pause

        echo "# unzip /root/creds/$demo_account/$demo_user/$demo_user.zip \\"
        echo ">       -d /root/creds/$demo_account/$demo_user/"
        unzip /root/creds/$demo_account/$demo_user/$demo_user.zip \
              -d /root/creds/$demo_account/$demo_user/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/$demo_account/$demo_user/eucarc    # invisibly fix deprecation message

        next 2
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/$demo_users$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Users ($demo_users) Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Users ($demo_users) Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g $demo_users"
    echo
    echo "euare-groupadduser -g $demo_users -u $demo_user"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_users"
        euare-groupcreate -g $demo_users
        echo "#"
        echo "# euare-groupadduser -g $demo_users -u $demo_user"
        euare-groupadduser -g $demo_users -u $demo_user

        next 2
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q ":user/$demo_developer$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developer ($demo_developer)"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developer ($demo_developer)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u $demo_developer"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_developer"
        euare-usercreate -u $demo_developer

        next 2
    fi
fi


((++step))
if euare-usergetloginprofile -u $demo_developer &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developer ($demo_developer) Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developer ($demo_developer) Login Profile"
    echo "    - This allows the Demo Account Developer to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"
        euare-useraddloginprofile -u $demo_developer -p $demo_developer_password

        next 2
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/$demo_developer/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account Developer ($demo_developer) Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 2

else
    clear
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo ($demo_account) Account Developer ($demo_developer) Credentials"
    echo "    - This allows the Demo Account Developer to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$demo_account/$demo_developer"
    echo
    echo "euca-get-credentials -u $demo_developer -a $demo_account \\"
    echo "                     /root/creds/$demo_account/$demo_developer/$demo_developer.zip"
    echo
    echo "unzip /root/creds/$demo_account/$demo_developer/$demo_developer.zip \\"
    echo "      -d /root/creds/$demo_account/$demo_developer/"

    run

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$demo_account/$demo_developer"
        mkdir -p /root/creds/$demo_account/$demo_developer
        pause

        echo "# euca-get-credentials -u $demo_developer -a $demo_account \\"
        echo ">                      /root/creds/$demo_account/$demo_developer/$demo_developer.zip"
        euca-get-credentials -u $demo_developer -a $demo_account \
                             /root/creds/$demo_account/$demo_developer/$demo_developer.zip
        pause

        echo "# unzip /root/creds/$demo_account/$demo_developer/$demo_developer.zip \\"
        echo ">       -d /root/creds/$demo_account/$demo_developer/"
        unzip /root/creds/$demo_account/$demo_developer/$demo_developer.zip \
              -d /root/creds/$demo_account/$demo_developer/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/$demo_account/$demo_developer/eucarc    # invisibly fix deprecation message

        next 2
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/$demo_developers$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developers ($demo_developers) Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo ($demo_account) Account Developers ($demo_developers) Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g $demo_developers"
    echo
    echo "euare-groupadduser -g $demo_developers -u $demo_developer"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_developers"
        euare-groupcreate -g $demo_developers
        echo "#"
        echo "# euare-groupadduser -g $demo_developers -u $demo_developer"
        euare-groupadduser -g $demo_developers -u $demo_developer

        next 2
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

run

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

    next 20
fi


echo
echo "Eucalyptus Demo Account configured for demo scripts"
