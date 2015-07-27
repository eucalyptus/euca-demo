#!/bin/bash
#
# This script initializes a Management Workstation and it's associated Eucalyptus Region with
# dependencies used in demos, including:
# - Confirms the Demo Images are available to the Demo Account
# - Imports the Demo Keypair into the Demo Account
# - Creates the Demos Role (named "Demos"), and associated Instance Profile (named "Demos")
# - Creates the Demos Role Policy
# - Creates the Demos Group (named "Demos")
# - Creates the Demos Group Policy
# - Creates the Developers Group (named "Developers")
# - Creates the Developers Group Policy
# - Creates the Users Group (named "Users")
# - Creates the Users Group Policy
# - Creates a demo User (named "demo"), as an example User within the Demos Group
# - Adds the demo User to the Demos Group
# - Creates the demo User Login Profile
# - Creates the demo User Access Key
# - Configures Euca2ools for the demo User
# - Configures AWSCLI for the demo User
# - Creates a developer User (named "developer"), an an example User within the Developers Group
# - Adds the developer User to the Developers Group
# - Creates the developer User Login Profile
# - Creates the developer User Access Key
# - Configures Euca2ools for the developer User
# - Configures AWSCLI for the developer User
# - Creates a user User (named "user"), as an example User within the Users Group
# - Adds the user User to the Users Group
# - Creates the user User Login Profile
# - Creates the user User Access Key
# - Configures Euca2ools for the user User
# - Configures AWSCLI for the user User
# - Lists Demo Account Resources
# - Displays Euca2ools Configuration
# - Displays AWSCLI Configuration
#
# The demo-00-initialize.sh script should be run by the Eucalyptus Administrator once prior to
# running this script, as this script references images it installs.
#
# Then the demo-01-initialize-aws-account.sh script should be run by the AWS Account Administrator
# to move AWS Account-level Credentials downloaded during the manual AWS Account creation process
# into a standard Euca2ools and AWSCLI storage onvention. This is optional, but required for the
# next script to be run.
#
# Then the demo-02-initialize-account-administrator.sh script should be run by the Eucalyptus
# Administrator as many times as needed to create one or more IAM Users in the Demo Account
# Administrators Group.
#
# Then this script should be run by the Demo Account Administrator or an IAM User in the 
# Administrators Group to create additional groups, users, roles and instance profiles in the 
# Demo Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
policiesdir=${bindir%/*}/policies
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

role_demos=Demos
instance_profile_demos=Demos

group_demos=Demos
group_developers=Developers
group_users=Users

user_demo=demo
user_developer=developer
user_user=user

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
account=demo
password=${account}123
user_demo_password=${password}-${user_demo}
user_developer_password=${password}-${user_developer}
user_user_password=${password}-${user_user}
admin=admin


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ] [-a account] [-p password] [-U admin]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -a account   Eucalyptus Account (default: $account)"
    echo "  -p password  password prefix for new Users (default: $password)"
    echo "  -U admin     existing Eucalyptus User with permissions to create new Groups and Users (default $admin)"
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

while getopts Isfr:a:p:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    p)  password="$OPTARG"
        user_demo_password=${password}-${user_demo}
        user_developer_password=${password}-${user_developer}
        user_user_password=${password}-${user_user};;
    U)  admin="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $region ]; then
    echo "-r region missing!"
    echo "Could not automatically determine region, and it was not specified as a parameter"
    exit 10
else
    case $region in
      us-east-1|us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $account ]; then
    echo "-a account missing!"
    echo "Could not automatically determine account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $password ]; then
    echo "-p password missing!"
    echo "Password must be specified as a parameter"
    exit 16
fi

if [ -z $admin ]; then
    echo "-U admin missing!"
    echo "Existing Administrator must be specified as a parameter"
    exit 18
fi

profile=$region-$account-$admin
profile_region=$profile@$region

if ! grep -s -q "\[user $profile]" ~/.euca/$region.ini; then
    echo "Could not find $region Demo ($account) Account Administrator ($admin) User Euca2ools user!"
    echo "Expected to find: [user $profile] in ~/.euca/$region.ini"
    exit 20
fi

mkdir -p $tmpdir/$account


#  5. Prepare Eucalyptus Demo Account for Demo Dependencies

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
if [ $admin = admin ]; then
    echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator credentials"
else
    echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator ($admin) User credentials"
fi
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "export AWS_DEFAULT_REGION=$profile_region"
echo "unset AWS_CREDENTIAL_FILE"

next

echo
echo "# export AWS_DEFAULT_REGION=$profile_region"
export AWS_DEFAULT_REGION=$profile_region
echo "# unset AWS_CREDENTIAL_FILE"
unset AWS_CREDENTIAL_FILE

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
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Import Demo ($account) Account Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > ~/.ssh/demo_id_rsa"
cat $keysdir/demo_id_rsa
echo "EOF"
echo
echo "chmod 0600 ~/.ssh/demo_id_rsa"
echo
echo "cat << EOF > ~/.ssh/demo_id_rsa.pub"
cat $keysdir/demo_id_rsa.pub
echo "EOF"
echo
echo "euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo"

if euca-describe-keypairs | cut -f2 | grep -s -q "^demo$" && [ -r ~/.ssh/demo_id_rsa ]; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    euca-delete-keypair demo &> /dev/null
    rm -f ~/.ssh/demo_id_rsa
    rm -f ~/.ssh/demo_id_rsa.pub

    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > ~/.ssh/demo_id_rsa"
        cat $keysdir/demo_id_rsa | sed -e 's/^/> /'
        echo "> EOF"
        cp $keysdir/demo_id_rsa ~/.ssh/demo_id_rsa
        echo "#"
        echo "# chmod 0600 ~/.ssh/demo_id_rsa"
        chmod 0600 ~/.ssh/demo_id_rsa
        pause

        echo "# cat << EOF > ~/.ssh/demo_id_rsa.pub"
        cat $keysdir/demo_id_rsa.pub | sed -e 's/^/> /'
        echo "> EOF"
        cp $keysdir/demo_id_rsa.pub ~/.ssh/demo_id_rsa.pub
        pause

        echo "# euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo"
        euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($role_demos) Role and associated InstanceProfile"
echo "    - This Role is intended for Demos which need Administrator access to Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
cat $policiesdir/DemosRoleTrustPolicy.json
echo "EOF"
echo
echo "euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
echo
echo "euare-instanceprofilecreate -s $instance_profile_demos"
echo
echo "euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos"

if euare-rolelistbypath | grep -s -q ":role/$role_demos$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF >> $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
        cat $policiesdir/DemosRoleTrustPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosRoleTrustPolicy.json $tmpdir/$account/${role_demos}RoleTrustPolicy.json
        pause

        echo "# euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
        euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json
        pause

        echo "# euare-instanceprofilecreate -s $instance_profile_demos"
        euare-instanceprofilecreate -s $instance_profile_demos
        pause

        echo "# euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos"
        euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($role_demos) Role Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${role_demos}RolePolicy.json"
cat $policiesdir/DemosRolePolicy.json
echo "EOF"
echo
echo "euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \\"
echo "                       -f $tmpdir/$account/${role_demos}RolePolicy.json"

if euare-rolelistpolicies -r $role_demos | grep -s -q "${role_demos}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${role_demos}RolePolicy.json"
        cat $policiesdir/DemosRolePolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosRolePolicy.json $tmpdir/$account/${role_demos}RolePolicy.json
        pause

        echo "# euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \\"
        echo ">                        -f $tmpdir/$account/${role_demos}RolePolicy.json"
        euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \
                               -f $tmpdir/$account/${role_demos}RolePolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Group"
echo "    - This Group is intended for Demos which have Administrator access to Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_demos"

if euare-grouplistbypath | grep -s -q ":group/$group_demos$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_demos"
        euare-groupcreate -g $group_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Group Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_demos}GroupPolicy.json"
cat $policiesdir/DemosGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \\"
echo "                        -f $tmpdir/$account/${group_demos}GroupPolicy.json"

if euare-grouplistpolicies -g $group_demos | grep -s -q "${group_demos}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_demos}GroupPolicy.json"
        cat $policiesdir/DemosGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosGroupPolicy.json $tmpdir/$account/${group_demos}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_demos}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \
                                -f $tmpdir/$account/${group_demos}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($group_developers) Group"
echo "    - This Group is intended for Developers who can modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_developers"

if euare-grouplistbypath | grep -s -q ":group/$group_developers$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_developers"
        euare-groupcreate -g $group_developers

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($group_developers) Group Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_developers}GroupPolicy.json"
cat $policiesdir/DevelopersGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \\"
echo "                        -f $tmpdir/$account/${group_developers}GroupPolicy.json"

if euare-grouplistpolicies -g $group_developers | grep -s -q "${group_developers}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_developers}GroupPolicy.json"
        cat $policiesdir/DevelopersGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DevelopersGroupPolicy.json $tmpdir/$account/${group_developers}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_developers}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \
                                -f $tmpdir/$account/${group_developers}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($group_users) Group"
echo "    - This Group is intended for Users who can view but not modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_users"

if euare-grouplistbypath | grep -s -q ":group/$group_users$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_users"
        euare-groupcreate -g $group_users

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($group_users) Group Policy"
echo "    - This Policy provides ReadOnly access to all resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_users}GroupPolicy.json"
cat $policiesdir/UsersGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_users -p ${group_users}Policy \\"
echo "                        -f $tmpdir/$account/${group_users}GroupPolicy.json"

if euare-grouplistpolicies -g $group_users | grep -s -q "${group_users}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_users}GroupPolicy.json"
        cat $policiesdir/UsersGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/UsersGroupPolicy.json $tmpdir/$account/${group_users}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_users -p ${group_users}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_users}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_demos -p ${group_users}Policy \
                                -f $tmpdir/$account/${group_users}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_demo"

if euare-userlistbypath | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_demo"
        euare-usercreate -u $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Demo ($user_demo) User to Demos ($group_demos) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_demos -u $user_demo"

if euare-grouplistusers -g $group_demos | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_demos -u $user_demo"
        euare-groupadduser -g $group_demos -u $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Login Profile"
echo "    - This allows the Demo Account Demo User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_demo -p $user_demo_password"

if euare-usergetloginprofile -u $user_demo &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_demo -p $user_demo_password"
        euare-useraddloginprofile -u $user_demo -p $user_demo_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Access Key"
echo "    - This allows the Demo Account Demo User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$region/$account/$user_demo"
echo
echo "euare-useraddkey -u $user_demo"
echo
echo "cat << EOF > ~/.creds/$region/$account/$user_demo/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$region/$account/$user_demo/iamrc"

if [ -r ~/.creds/$region/$account/$user_demo/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/$user_demo"
        mkdir -p ~/.creds/$region/$account/$user_demo
        pause

        echo "# euare-useraddkey -u $user_demo"
        result=$(euare-useraddkey -u $user_demo) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$region/$account/$user_demo/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$region/$account/$user_demo/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$region/$account/$user_demo/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$region/$account/$user_demo/iamrc"
        chmod 0600 ~/.creds/$region/$account/$user_demo/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Euca2ools Profile"
echo "    - This allows the Demo Account Demo User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$region.ini"
echo "[user $region-$account-$user_demo]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$region-$account-$user_demo@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "\[user $region-$account-$user_demo]" ~/.euca/$region.ini; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        echo "# cat << EOF >> ~/.euca/$region.ini"
        echo "> [user $region-$account-$user_demo]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-$user_demo]" >> ~/.euca/$region.ini
        echo "key-id = $access_key"               >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"           >> ~/.euca/$region.ini
        echo                                      >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones --region=$region-$account-$user_demo@$region"
        euca-describe-availability-zones --region=$region-$account-$user_demo@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User AWSCLI Profile"
echo "    - This allows the Demo Account Demo User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-$account-$user_demo]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$region-$account-$user_demo]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-$account-$user_demo]" ~/.aws/config; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.aws
        chmod 0700 ~/.aws
        echo
        echo "# cat << EOF >> ~/.aws/config"
        echo "> [profile $region-$account-$user_demo]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-$account-$user_demo]" >> ~/.aws/config
        echo "region = $region"                      >> ~/.aws/config
        echo "output = text"                         >> ~/.aws/config
        echo                                         >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$region-$account-$user_demo]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-$account-$user_demo]"       >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region"
        aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_developer"

if euare-userlistbypath | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_developer"
        euare-usercreate -u $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Developer ($user_developer) User to Developers ($group_developers) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_developers -u $user_developer"

if euare-grouplistusers -g $group_developers | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_developers -u $user_developer"
        euare-groupadduser -g $group_developers -u $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Login Profile"
echo "    - This allows the Demo Account Developer User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_developer -p $user_developer_password"

if euare-usergetloginprofile -u $user_developer &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_developer -p $user_developer_password"
        euare-useraddloginprofile -u $user_developer -p $user_developer_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Access Key"
echo "    - This allows the Demo Account Developer User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$region/$account/$user_developer"
echo
echo "euare-useraddkey -u $user_developer"
echo
echo "cat << EOF > ~/.creds/$region/$account/$user_developer/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$region/$account/$user_developer/iamrc"

if [ -r ~/.creds/$region/$account/$user_developer/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/$user_developer"
        mkdir -p ~/.creds/$region/$account/$user_developer
        pause

        echo "# euare-useraddkey -u $user_developer"
        result=$(euare-useraddkey -u $user_developer) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$region/$account/$user_developer/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$region/$account/$user_developer/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$region/$account/$user_developer/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$region/$account/$user_developer/iamrc"
        chmod 0600 ~/.creds/$region/$account/$user_developer/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Euca2ools Profile"
echo "    - This allows the Demo Account Developer User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$region.ini"
echo "[user $region-$account-$user_developer]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$region-$account-$user_developer@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "\[user $region-$account-$user_developer]" ~/.euca/$region.ini; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        echo "# cat << EOF >> ~/.euca/$region.ini"
        echo "> [user $region-$account-$user_developer]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-$user_developer]" >> ~/.euca/$region.ini
        echo "key-id = $access_key"                    >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"                >> ~/.euca/$region.ini
        echo                                           >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones --region=$region-$account-$user_developer@$region"
        euca-describe-availability-zones --region=$region-$account-$user_developer@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User AWSCLI Profile"
echo "    - This allows the Demo Account Developer User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-$account-$user_developer]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$region-$account-$user_developer]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-$account-$user_developer]" ~/.aws/config; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.aws
        chmod 0700 ~/.aws
        echo
        echo "# cat << EOF >> ~/.aws/config"
        echo "> [profile $region-$account-$user_developer]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-$account-$user_developer]" >> ~/.aws/config
        echo "region = $region"                           >> ~/.aws/config
        echo "output = text"                              >> ~/.aws/config
        echo                                              >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$region-$account-$user_developer]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-$account-$user_developer]"  >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region"
        aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_user"

if euare-userlistbypath | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_user"
        euare-usercreate -u $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account User ($user_user) User to Users ($group_users) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_users -u $user_user"

if euare-grouplistusers -g $group_users | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_users -u $user_user"
        euare-groupadduser -g $group_users -u $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Login Profile"
echo "    - This allows the Demo Account User User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_user -p $user_user_password"

if euare-usergetloginprofile -u $user_user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_user -p $user_user_password"
        euare-useraddloginprofile -u $user_user -p $user_user_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Access Key"
echo "    - This allows the Demo Account User User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$region/$account/$user_user"
echo
echo "euare-useraddkey -u $user_user"
echo
echo "cat << EOF > ~/.creds/$region/$account/$user_user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$region/$account/$user_user/iamrc"

if [ -r ~/.creds/$region/$account/$user_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/$user_user"
        mkdir -p ~/.creds/$region/$account/$user_user
        pause

        echo "# euare-useraddkey -u $user_user"
        result=$(euare-useraddkey -u $user_user) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$region/$account/$user_user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$region/$account/$user_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$region/$account/$user_user/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$region/$account/$user_user/iamrc"
        chmod 0600 ~/.creds/$region/$account/$user_user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Euca2ools Profile"
echo "    - This allows the Demo Account User User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$region.ini"
echo "[user $region-$account-$user_user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$region-$account-$user_user@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "\[user $region-$account-$user_user]" ~/.euca/$region.ini; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        echo "# cat << EOF >> ~/.euca/$region.ini"
        echo "> [user $region-$account-$user_user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-$user_user]" >> ~/.euca/$region.ini
        echo "key-id = $access_key"               >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"           >> ~/.euca/$region.ini
        echo                                      >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones --region=$region-$account-$user_user@$region"
        euca-describe-availability-zones --region=$region-$account-$user_user@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User AWSCLI Profile"
echo "    - This allows the Demo Account User User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-$account-$user_user]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$region-$account-$user_user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-$account-$user_user]" ~/.aws/config; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.aws
        chmod 0700 ~/.aws
        echo
        echo "# cat << EOF >> ~/.aws/config"
        echo "> [profile $region-$account-$user_user]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-$account-$user_user]" >> ~/.aws/config
        echo "region = $region"                      >> ~/.aws/config
        echo "output = text"                         >> ~/.aws/config
        echo                                         >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$region-$account-$user_user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-$account-$user_user]"       >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region"
        aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region

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
echo "euare-rolelistbypath"
echo "euare-instanceprofilelistbypath"
echo "euare-instanceprofilelistforrole -r $role_demos"
echo
echo "euare-grouplistbypath"
echo
echo "euare-userlistbypath"
echo
echo "euare-grouplistusers -g $group_demos"
echo "euare-grouplistusers -g $group_developers"
echo "euare-grouplistusers -g $group_users"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euare-rolelistbypath"
    euare-rolelistbypath
    echo "#"
    echo "# euare-instanceprofilelistbypath"
    euare-instanceprofilelistbypath
    echo "#"
    echo "# euare-instanceprofilelistforrole -r $role_demos"
    euare-instanceprofilelistforrole -r $role_demos
    pause

    echo "# euare-grouplistbypath"
    euare-grouplistbypath
    pause

    echo "# euare-userlistbypath"
    euare-userlistbypath
    pause

    echo "# euare-grouplistusers -g $group_demos"
    euare-grouplistusers -g $group_demos
    echo "#"
    echo "# euare-grouplistusers -g $group_developers"
    euare-grouplistusers -g $group_developers
    echo "#"
    echo "# euare-grouplistusers -g $group_users"
    euare-grouplistusers -g $group_users

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display Euca2ools Configuration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat /etc/euca2ools/conf.d/$region.ini"
echo
echo "cat ~/.euca/global.ini"
echo
echo "cat ~/.euca/$region.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat /etc/euca2ools/conf.d/$region.ini"
    cat /etc/euca2ools/conf.d/$region.ini
    pause

    echo "# cat ~/.euca/global.ini"
    cat ~/.euca/global.ini
    pause

    echo "# cat ~/.euca/$region.ini"
    cat ~/.euca/$region.ini

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display AWSCLI Configuration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat ~/.aws/config"
echo
echo "cat ~/.aws/credentials"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat ~/.aws/config"
    cat ~/.aws/config
    pause

    echo "# cat ~/.aws/credentials"
    cat ~/.aws/credentials

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Demo Account Dependencies configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
