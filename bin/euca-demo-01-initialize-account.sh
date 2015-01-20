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

demo_admin_password=demo123
demo_user_password=user456
demo_developer_password=developer789

step=0
percent_min=0
percent_max=500
run_default=10
pause_default=2
next_default=10
create_attempts=12
create_default=10
login_attempts=12
login_default=10
delete_attempts=12
delete_default=10

interactive=1
demo_account=demo
#image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz
image_url=http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
#image_url=http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
run_percent=100
pause_percent=100
next_percent=100
create_percent=100
login_percent=100
delete_percent=100


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-a demo_account] [-u image_url]"
    echo "           [-I [-r run_percent] [-p pause_percent] [-n next_percent]]"
    echo "  -a demo_account   account to create for use in demos (default: $demo_account)"
    echo "  -u image_url      URL to Demo CentOS image (default: $image_url)"
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

while getopts a:u:Ir:p:n:? arg; do
    case $arg in
    a)  demo_account="$OPTARG";;
    u)  image_url="$OPTARG";;
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

if ! curl -s --head $image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo
    echo "-u $image_url invalid: attempts to reach this URL failed"
    exit 8
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Account Administrator credentials!"
    echo "   Expected to find: /root/creds/eucalyptus/admin/eucarc"
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

next 5

echo
echo "# source /root/creds/eucalyptus/admin/eucarc"
source /root/creds/eucalyptus/admin/eucarc

next 2


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

    next 2

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

    run

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem
        echo
        echo "# chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem"
        chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem

        next 2
    fi
fi


((++step))
if euare-accountlist | grep -s -q "^$demo_account"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$demo_account\") Account"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$demo_account\") Account"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountcreate -a $demo_account"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate -a $demo_account"
        euare-accountcreate -a $demo_account

        next 2
    fi
fi


((++step))
if euare-usergetloginprofile -u admin --as-account $demo_account &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$demo_account\") Account Administrator Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$demo_account\") Account Administrator Login Profile"
    echo "    - This allows the Demo (\"$demo_account\") Account Administrator to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usermodloginprofile –u admin –p $demo_admin_password -as-account $demo_account"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $demo_account"
        euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $demo_account

        next 2
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

    next 2

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

    run

    if [ $choice = y ]; then
        echo
        echo "# wget $image_url -O /root/centos.raw.xz"
        wget $image_url -O /root/centos.raw.xz
        pause

        echo "xz -v -d /root/centos.raw.xz"
        xz -v -d /root/centos.raw.xz

        next 2
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

    next 2

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

    run

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-install-image.out

        next 2
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
    echo "$(printf '%2d' $step). Authorize Demo (\"$account\") Account use of Demo Image"
    echo "    - Already Authorized!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Authorize Demo (\"$account\") Account use of Demo Image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-image-attribute -l -a $demo_account_id $image_id"

    run

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $demo_account_id $image_id"
        euca-modify-image-attribute -l -a $demo_account_id $image_id

        next 2
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/admin/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account Administrator Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account Administrator Credentials"
    echo "    - This allows the Demo (\"$account\") Account Administrator to run API commands"
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

    run

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

        next 2
    fi
fi


# Note: MUST run this step to make sure objects created below owned by demo account
((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Demo (\"$account\") Account Administrator credentials"
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
echo "$(printf '%2d' $step). List Images available to Demo (\"$account\") Account Administrator"
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
if euca-describe-keypairs | grep -s -q "admin-demo"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Administrator Demo Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Administrator Demo Keypair"
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
if euare-userlistbypath | grep -s -q ":user/user$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account User"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account User"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u user"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u user"
        euare-usercreate -u user

        next 2
    fi
fi


((++step))
if euare-usergetloginprofile -u user &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account User Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account User Login Profile"
    echo "    - This allows the Demo (\"$account\") Account User to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u user -p $demo_user_password"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u user -p $demo_user_password"
        euare-useraddloginprofile -u user -p $demo_user_password

        next 2
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/user/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account User Credentials"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account User Credentials"
    echo "    - This allows the Demo (\"$account\") Account User to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$demo_account/user"
    echo
    echo "euca-get-credentials -u user -a $demo_account \\"
    echo "                     /root/creds/$demo_account/user/user.zip"
    echo
    echo "unzip /root/creds/$demo_account/user/user.zip \\"
    echo "      -d /root/creds/$demo_account/user/"

    run

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$demo_account/user"
        mkdir -p /root/creds/$demo_account/user
        pause

        echo "# euca-get-credentials -u user -a $demo_account \\"
        echo ">                      /root/creds/$demo_account/user/user.zip"
        euca-get-credentials -u user -a $demo_account \
                             /root/creds/$demo_account/user/user.zip
        pause

        echo "# unzip /root/creds/$demo_account/user/user.zip \\"
        echo ">       -d /root/creds/$demo_account/user/"
        unzip /root/creds/$demo_account/user/user.zip \
              -d /root/creds/$demo_account/user/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/$demo_account/user/eucarc    # invisibly fix deprecation message

        next 2
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/users$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Users Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Users Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g users"
    echo
    echo "euare-groupadduser -g users -u user"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g users"
        euare-groupcreate -g users
        echo "#"
        echo "# euare-groupadduser -g users -u user"
        euare-groupadduser -g users -u user

        next 2
    fi
fi


((++step))
if euare-userlistbypath | grep -s -q ":user/developer$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developer"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developer"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-usercreate -u developer"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u developer"
        euare-usercreate -u developer

        next 2
    fi
fi


((++step))
if euare-usergetloginprofile -u developer &> /dev/null; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developer Login Profile"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developer Login Profile"
    echo "    - This allows the Demo (\"$account\") Account Developer to login to the console"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-useraddloginprofile -u developer -p $demo_developer_password"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u developer -p $demo_developer_password"
        euare-useraddloginprofile -u developer -p $demo_developer_password

        next 2
    fi
fi


((++step))
if [ -r /root/creds/$demo_account/developer/eucarc ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account Developer Credentials"
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
    echo "$(printf '%2d' $step). Download Demo (\"$account\") Account Developer Credentials"
    echo "    - This allows the Demo (\"$account\") Account Developer to run API commands"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/$demo_account/developer"
    echo
    echo "euca-get-credentials -u developer -a $demo_account \\"
    echo "                     /root/creds/$demo_account/developer/developer.zip"
    echo
    echo "unzip /root/creds/$demo_account/developer/developer.zip \\"
    echo "      -d /root/creds/$demo_account/developer/"

    run

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/$demo_account/developer"
        mkdir -p /root/creds/$demo_account/developer
        pause

        echo "# euca-get-credentials -u developer -a $demo_account \\"
        echo ">                      /root/creds/$demo_account/developer/developer.zip"
        euca-get-credentials -u developer -a $demo_account \
                             /root/creds/$demo_account/developer/developer.zip
        pause

        echo "# unzip /root/creds/$demo_account/developer/developer.zip \\"
        echo ">       -d /root/creds/$demo_account/developer/"
        unzip /root/creds/$demo_account/developer/developer.zip \
              -d /root/creds/$demo_account/developer/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/$demo_account/developer/eucarc    # invisibly fix deprecation message

        next 2
    fi
fi


((++step))
if euare-grouplistbypath | grep -s -q ":group/developers$"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developers Group"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    next 2

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Demo (\"$account\") Account Developers Group"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-groupcreate -g developers"
    echo
    echo "euare-groupadduser -g developers -u developer"

    run

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g developers"
        euare-groupcreate -g developers
        echo "#"
        echo "# euare-groupadduser -g developers -u developer"
        euare-groupadduser -g developers -u developer

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
echo "euare-grouplistusers -g users"
echo "euare-grouplistusers -g developers"

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
    echo "# euare-grouplistusers -g users
    euare-grouplistusers -g users
    echo "#"
    echo "# euare-grouplistusers -g developers
    euare-grouplistusers -g developers

    next 20
fi


echo
echo "Eucalyptus configured for demo scripts"
