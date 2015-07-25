#!/bin/bash
#
# This script initializes a Management Workstation and it's associated Eucalyptus Region with
# dependencies used in demos, including:
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
# This is a variant of the demo-03-initialize-account-dependencies.sh script which primarily uses
# the AWSCLI.
#
# The demo-00-initialize.sh and demo-01-initialize-account.sh scripts should both be run by the
# Eucalyptus Administrator prior to running this script against Eucalyptus, as those scripts create
# images and the account referenced in this script.
#
# This script should be run by the Demo Account Administrator last, so all operations are done
# within the context of the Demo Account.
#
# All three initialization scripts are pre-requisites of running any demos!
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
    echo "  -p password  password prefix to use for new Users (default: $password)"
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
      us-east-1|us-west-1|us-west-2|
      sa-east-1|
      eu-west-1|eu-central-1|
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

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "-r $region, -a $account and/or -U admin invalid: Could not find $profile profile!"
    echo "   Expected to find: [profile $profile] in ~/.aws/config"
    exit 21
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
    echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator profile"
else
    echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator ($admin) User profile"
fi
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "export AWS_DEFAULT_PROFILE=$profile"
echo
echo "echo \$AWS_DEFAULT_PROFILE"
echo "echo \$AWS_DEFAULT_REGION"

next

echo
echo "# export AWS_DEFAULT_PROFILE=$profile"
export AWS_DEFAULT_PROFILE=$profile
pause

echo "# echo \$AWS_DEFAULT_PROFILE"
echo $AWS_DEFAULT_PROFILE
echo "# echo \$AWS_DEFAULT_REGION"
echo $AWS_DEFAULT_REGION

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
echo "aws ec2 describe-images"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws ec2 describe-images"
    aws ec2 describe-images

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
echo "aws ec2 import-key-pair --key-name=demo \\"
echo "                        --public-key-material file://~/.ssh/demo_id_rsa.pub"

if aws ec2 describe-key-pairs | cut -f3 | grep -s -q "^demo$" && [ -r ~/.ssh/demo_id_rsa ]; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    aws ec2 delete-key-pair --key-name demo &> /dev/null
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

        echo "# aws ec2 import-key-pair --key-name=demo \\"
        echo ">                         --public-key-material file://~/.ssh/demo_id_rsa.pub"
        aws ec2 import-key-pair --key-name=demo \
                                --public-key-material file://~/.ssh/demo_id_rsa.pub

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Role and associated InstanceProfile"
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
echo "aws iam create-role --role-name $role_demos \\"
echo "                    --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json"
echo
echo "aws iam create-instance-profile --instance-profile-name $instance_profile_demos"
echo
echo "aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos"

if aws iam list-roles | grep -s -q ":role/$role_demos"; then
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

        echo "# aws iam create-role --role-name $role_demos \\"
        echo ">                     --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json"
        aws iam create-role --role-name $role_demos \
                            --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json
        pause

        echo "# aws iam create-instance-profile --instance-profile-name $instance_profile_demos"
        aws iam create-instance-profile --instance-profile-name $instance_profile_demos
        pause

        echo "# aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos"
        aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos

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
echo "aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \\"
echo "                        --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json"

if aws iam list-role-policies --role-name $role_demos | grep -s -q "${role_demos}Policy$"; then
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

        echo "# aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \\"
        echo ">                         --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json"
        aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \
                                --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json

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
echo "aws iam create-group --group-name $group_demos"

if aws iam list-groups | grep -s -q ":group/$group_demos"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_demos"
        aws iam create-group --group-name $group_demos

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
echo "aws iam put-group-policy --group-name $group_demos --policy-name ${group_demos}Policy \\"
echo "                         --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json"

if aws iam list-group-policies --group-name $group_demos | grep -s -q "${group_demos}Policy$"; then
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

        echo "# aws iam put-group-policy --group-name $group_demos --policy-name ${group_demos}Policy \\"
        echo ">                          --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json"
        aws iam put-group-policy --group-name $group_demos --policy-name ${group_demos}Policy \
                                 --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json

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
echo "aws iam create-group --group-name $group_developers"

if aws iam list-groups | grep -s -q ":group/$group_developers"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_developers"
        aws iam create-group --group-name $group_developers

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
echo "aws iam put-group-policy --group-name $group_developers --policy-name ${group_developers}Policy \\"
echo "                         --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json"

if aws iam list-group-policies --group-name $group_developers | grep -s -q "${group_developers}Policy$"; then
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

        echo "# aws iam put-group-policy --group-name $group_developers --policy-name ${group_developers}Policy \\"
        echo ">                          --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json"
        aws iam put-group-policy --group-name $group_developers --policy-name ${group_developers}Policy \
                                 --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json

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
echo "aws iam create-group --group-name $group_users"

if aws iam list-groups | grep -s -q ":group/$group_users"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_users"
        aws iam create-group --group-name $group_users

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
echo "aws iam put-group-policy --group-name $group_users --policy-name ${group_users}Policy \\"
echo "                         --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json"

if aws iam list-group-policies --group-name $group_users | grep -s -q "${group_users}Policy$"; then
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

        echo "# aws iam put-group-policy --group-name $group_users --policy-name ${group_users}Policy \\"
        echo ">                          --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json"
        aws iam put-group-policy --group-name $group_demos --policy-name ${group_users}Policy \
                                 --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json

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
echo "aws iam create-user --user-name $user_demo"

if aws iam list-users | grep -s -q ":user/$user_demo"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_demo"
        aws iam create-user --user-name $user_demo

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
echo "aws iam add-user-to-group --group-name $group_demos --user-name $user_demo"

if aws iam get-group --group-name $group_demos | grep -s -q ":user/$user_demo"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_demos --user-name $user_demo"
        aws iam add-user-to-group --group-name $group_demos --user-name $user_demo

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
echo "aws iam create-login-profile --user-name $user_demo --password $user_demo_password"

if aws iam get-login-profile --user-name $user_demo &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_demo --password $user_demo_password"
        aws iam create-login-profile --user-name $user_demo --password $user_demo_password

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
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo"
echo
echo "aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
echo
echo "cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo
        pause

        echo "# aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
        result=$(aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}') && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc

        next
    fi
fi



((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)

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
echo "cat << EOF >> ~/.euca/euca2ools.ini"
echo "[user $account-$user_demo]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$account-$user_demo@$AWS_DEFAULT_REGION"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$secret_key" ~/.euca/euca2ools.ini; then
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
        echo "# cat << EOF >> ~/.euca/euca2ools.ini"
        echo "> [user $account-$user_demo]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $account-$user_demo]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key"       >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key"   >> ~/.euca/euca2ools.ini
        echo                              >> ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones --region=$account-$user_demo@$AWS_DEFAULT_REGION"
        euca-describe-availability-zones --region=$account-$user_demo@$AWS_DEFAULT_REGION

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)

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
echo "[profile $AWS_DEFAULT_REGION-$account-$user_demo]"
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$AWS_DEFAULT_REGION-$account-$user_demo]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_demo"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_demo]" ~/.aws/config; then
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
        echo "> [profile $AWS_DEFAULT_REGION-$account-$user_demo]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_demo]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION"                      >> ~/.aws/config
        echo "output = text"                                     >> ~/.aws/config
        echo                                                     >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$AWS_DEFAULT_REGION-$account-$user_demo]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$AWS_DEFAULT_REGION-$account-$user_demo]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"           >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key"       >> ~/.aws/credentials
        echo                                             >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_demo"
        aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_demo

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
echo "aws iam create-user --user-name $user_developer"

if  aws iam list-users | grep -s -q ":user/$user_developer"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_developer"
        aws iam create-user --user-name $user_developer

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
echo "aws iam add-user-to-group --group-name $group_developers --user-name $user_developer"

if aws iam get-group --group-name $group_developers | grep -s -q ":user/$user_developer"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_developers --user-name $user_developer"
        aws iam add-user-to-group --group-name $group_developers --user-name $user_developer

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
echo "aws iam create-login-profile --user-name $user_developer --password $user_developer_password"

if aws iam get-login-profile --user-name $user_developer &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_developer --password $user_developer_password"
        aws iam create-login-profile --user-name $user_developer --password $user_developer_password

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
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer"
echo
echo "aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
echo
echo "cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer
        pause

        echo "# aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
        result=$(aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}') && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)

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
echo "cat << EOF >> ~/.euca/euca2ools.ini"
echo "[user $account-$user_developer]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$account-$user_developer@$AWS_DEFAULT_REGION"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$secret_key" ~/.euca/euca2ools.ini; then
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
        echo "# cat << EOF >> ~/.euca/euca2ools.ini"
        echo "> [user $account-$user_developer]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $account-$user_developer]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key"            >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key"        >> ~/.euca/euca2ools.ini
        echo                                   >> ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones --region=$account-$user_developer@$AWS_DEFAULT_REGION"
        euca-describe-availability-zones --region=$account-$user_developer@$AWS_DEFAULT_REGION

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)

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
echo "[profile $AWS_DEFAULT_REGION-$account-$user_developer]"
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$AWS_DEFAULT_REGION-$account-$user_developer]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_developer"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_developer]" ~/.aws/config; then
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
        echo "> [profile $AWS_DEFAULT_REGION-$account-$user_developer]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_developer]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION"                           >> ~/.aws/config
        echo "output = text"                                          >> ~/.aws/config
        echo                                                          >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$AWS_DEFAULT_REGION-$account-$user_developer]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$AWS_DEFAULT_REGION-$account-$user_developer]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"                >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key"            >> ~/.aws/credentials
        echo                                                  >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_developer"
        aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_developer

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
echo "aws iam create-user --user-name $user_user"

if aws iam list-users | grep -s -q ":user/$user_user"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_user"
        aws iam create-user --user-name $user_user

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
echo "aws iam add-user-to-group --group-name $group_users --user-name $user_user"

if aws iam get-group --group-name $group_users | grep -s -q ":user/$user_user"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_users --user-name $user_user"
        aws iam add-user-to-group --group-name $group_users --user-name $user_user

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
echo "aws iam create-login-profile --user-name $user_user --password $user_user_password"

if aws iam get-login-profile --user-name $user_user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_user --password $user_user_password"
        aws iam create-login-profile --user-name $user_user --password $user_user_password

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
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user"
echo
echo "aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
echo
echo "cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user
        pause

        echo "# aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
        result=$(aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}') && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)

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
echo "cat << EOF >> ~/.euca/euca2ools.ini"
echo "[user $account-$user_user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$account-$user_user@$AWS_DEFAULT_REGION"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$secret_key" ~/.euca/euca2ools.ini; then
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
        echo "# cat << EOF >> ~/.euca/euca2ools.ini"
        echo "> [user $account-$user_user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $account-$user_user]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key"       >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key"   >> ~/.euca/euca2ools.ini
        echo                              >> ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones --region=$account-$user_user@$AWS_DEFAULT_REGION"
        euca-describe-availability-zones --region=$account-$user_user@$AWS_DEFAULT_REGION

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)

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
echo "[profile $AWS_DEFAULT_REGION-$account-$user_user]"
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$AWS_DEFAULT_REGION-$account-$user_user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_user"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_user]" ~/.aws/config; then
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
        echo "> [profile $AWS_DEFAULT_REGION-$account-$user_user]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_user]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION"                      >> ~/.aws/config
        echo "output = text"                                     >> ~/.aws/config
        echo                                                     >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$AWS_DEFAULT_REGION-$account-$user_user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$AWS_DEFAULT_REGION-$account-$user_user]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"           >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key"       >> ~/.aws/credentials
        echo                                             >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_user"
        aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-$account-$user_user

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
echo "aws ec2 describe-images"
echo
echo "aws ec2 describe-key-pairs"
echo
echo "aws iam list-roles"
echo "aws iam list-instance-profiles"
echo "aws iam get-instance-profile --instance-profile-name $role_demos"
echo
echo "aws iam list-groups"
echo
echo "aws iam list-users"
echo
echo "aws iam get-group --group-name $group_demos"
echo "aws iam get-group --group-name $group_developers"
echo "aws iam get-group --group-name $group_users"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws ec2 describe-images"
    aws ec2 describe-images
    pause

    echo "# aws ec2 describe-key-pairs"
    aws ec2 describe-key-pairs
    pause

    echo "# aws iam list-roles"
    aws iam list-roles
    echo "#"
    echo "# aws iam list-instance-profiles"
    aws iam list-instance-profiles
    echo "#"
    echo "# aws iam get-instance-profile --instance-profile-name $role_demos"
    aws iam get-instance-profile --instance-profile-name $role_demos
    pause

    echo "# aws iam list-groups"
    aws iam list-groups
    pause

    echo "# aws iam list-users"
    aws iam list-users
    pause

    echo "# aws iam get-group --group-name $group_demos"
    aws iam get-group --group-name $group_demos
    echo "#"
    echo "# aws iam get-group --group-name $group_developers"
    aws iam get-group --group-name $group_developers
    echo "#"
    echo "# aws iam get-group --group-name $group_users"
    aws iam get-group --group-name $group_users

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
echo "cat ~/.euca/euca2ools.ini"
echo
echo "cat ~/.euca/euca2ools-ssl.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat ~/.euca/euca2ools.ini"
    cat ~/.euca/euca2ools.ini
    pause

    echo "# cat ~/.euca/euca2ools-ssl.ini"
    cat ~/.euca/euca2ools-ssl.ini

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
