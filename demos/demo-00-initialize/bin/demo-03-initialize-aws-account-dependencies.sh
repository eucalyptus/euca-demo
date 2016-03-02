#!/bin/bash
#
# This script initializes a Management Workstation and it's associated AWS Account with
# dependencies used in demos, including:
# - Configures the Demo Keypair
# - Imports the Demo Keypair
# - Creates the Demo Bucket (named "demo-{account}")
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
# The demo-00-initialize-aws.sh script should be run by the AWS Account Administrator once prior
# to running this script.
#
# Then the demo-01-initialize-aws-account.sh script should be run by the AWS Account Administrator
# to move AWS Account-level Credentials downloaded during the manual AWS Account creation process
# into a standard Euca2ools and AWSCLI storage onvention. This is optional, but required for the
# next script to be run.
#
# Then the demo-02-initialize-aws-account-administrator.sh script should be run by the AWS Account
# Administrator as many times as needed to create one or more AWS IAM Users in the Account
# Administrators Group.
#
# Then this script should be run once by an AWS Account Administrator or an AWS User in the
# Administrators Group to create additional groups, users, roles and instance profiles in the
# AWS Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
policiesdir=${bindir%/*}/policies
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

federation=aws

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
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-euca}
user=${AWS_USER_NAME:-admin}
prefix=${account}123
user_demo_password=${prefix}-${user_demo}
user_developer_password=${prefix}-${user_developer}
user_user_password=${prefix}-${user_user}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-p prefix]"
    echo "              [-r region] [-a account] [-u user]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -v          verbose"
    echo "  -p prefix   prefix for passwords created for new Users (default: $prefix)"
    echo "  -r region   AWS Region (default: $region)"
    echo "  -a account  AWS Account (default: $account)"
    echo "  -u user     AWS User with permissions to create new Groups and Users (default $user)"
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

while getopts Isfvp:r:a:u:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    p)  prefix="$OPTARG"
        user_demo_password=${prefix}-${user_demo}
        user_developer_password=${prefix}-${user_developer}
        user_user_password=${prefix}-${user_user};;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    u)  user="$OPTARG";;
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
      us-east-1|us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        ;;
      *)
        echo "-r $region invalid: This script can not be run against Eucalyptus regions"
        exit 11;;
    esac
fi

if [ -z $account ]; then
    echo "-a account missing!"
    echo "Could not automatically determine account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $user ]; then
    echo "-u user missing!"
    echo "Could not automatically determine user, and it was not specified as a parameter"
    exit 14
fi

if [ -z $prefix ]; then
    echo "-p prefix missing!"
    echo "Password prefix must be specified as a parameter"
    exit 18
fi

user_region=$federation-$account-$user@$region

if ! grep -s -q "\[user $federation-$account-$user]" ~/.euca/$federation.ini; then
    echo "Could not find AWS ($account) Account Administrator ($user) User Euca2ools user!"
    echo "Expected to find: [user $federation-$account-$user] in ~/.euca/$federation.ini"
    exit 50
fi

profile=$account-$user

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find AWS Demo ($account) Account Administrator ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 51
fi

mkdir -p $tmpdir/$account

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Prepare AWS Account for Demo Dependencies

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Demo Keypair"
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

if [ -r ~/.ssh/demo_id_rsa -a -r ~/.ssh/demo_id_rsa.pub ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
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

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Import AWS ($account) Account Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \\"
echo "                    --region $user_region \\"
echo "                    demo"

if euca-describe-keypairs --region $user_region | cut -f2 | grep -s -q "^demo$"; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \\"
        echo ">                     --region $user_region \\"
        echo ">                     demo"
        euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \
                            --region $user_region \
                            demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo (demo-$account) Bucket"
echo "    - This Bucket is intended for Demos which need to store Objects in S3"
echo "    - We must use the AWSCLI as euca2ools does not currently have S3 commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws s3 mb s3://demo-$account --profile $profile --region $region --output text"

if aws s3 ls --profile $profile --region $region --output text 2> /dev/null | grep -s -q " demo-$account$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws s3 mb s3://demo-$account --profile $profile --region $region --output text"
        aws s3 mb s3://demo-$account --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demos ($role_demos) Role and associated InstanceProfile"
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
echo "euare-rolecreate -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json \\"
echo "                 --region $user_region $role_demos"
echo
echo "euare-instanceprofilecreate --region $user_region $instance_profile_demos"
echo
echo "euare-instanceprofileaddrole --role-name $role_demos --region $user_region $instance_profile_demos"

if euare-rolelistbypath --region $user_region | grep -s -q ":role/$role_demos$"; then
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

        echo "# euare-rolecreate -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json \\"
        echo ">                  --region $user_region $role_demos"
        euare-rolecreate -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json \
                         --region $user_region $role_demos
        pause

        echo "# euare-instanceprofilecreate --region $user_region $instance_profile_demos"
        euare-instanceprofilecreate --region $user_region $instance_profile_demos
        pause

        echo "# euare-instanceprofileaddrole --role-name $role_demos --region $user_region $instance_profile_demos"
        euare-instanceprofileaddrole --role-name $role_demos --region $user_region $instance_profile_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demos ($role_demos) Role Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${role_demos}RolePolicy.json"
sed -e "s/\${account}/$account/g" $policiesdir/DemosRolePolicy.json
echo "EOF"
echo
echo "euare-roleuploadpolicy --policy-name ${role_demos}Policy \\"
echo "                       --policy-document $tmpdir/$account/${role_demos}RolePolicy.json \\"
echo "                       --region $user_region \\"
echo "                       $role_demos"

if euare-rolelistpolicies --region $user_region $role_demos | grep -s -q "${role_demos}Policy$"; then
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
        sed -e "s/\${account}/$account/g" $policiesdir/DemosRolePolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        sed -e "s/\${account}/$account/g" $policiesdir/DemosRolePolicy.json > $tmpdir/$account/${role_demos}RolePolicy.json
        pause

        echo "# euare-roleuploadpolicy --policy-name ${role_demos}Policy \\"
        echo ">                        --policy-document $tmpdir/$account/${role_demos}RolePolicy.json \\"
        echo ">                        --region $user_region \\"
        echo ">                        $role_demos"
        euare-roleuploadpolicy --policy-name ${role_demos}Policy \
                               --policy-document $tmpdir/$account/${role_demos}RolePolicy.json \
                               --region $user_region \
                               $role_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demos ($group_demos) Group"
echo "    - This Group is intended for Demos which have Administrator access to Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate --region $user_region $group_demos"

if euare-grouplistbypath --region $user_region | grep -s -q ":group/$group_demos$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate --region $user_region $group_demos"
        euare-groupcreate --region $user_region $group_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demos ($group_demos) Group Policy"
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
echo "euare-groupuploadpolicy --policy-name ${group_demos}Policy \\"
echo "                        --policy-document $tmpdir/$account/${group_demos}GroupPolicy.json \\"
echo "                        --region $user_region \\"
echo "                        $group_demos"

if euare-grouplistpolicies --region $user_region $group_demos | grep -s -q "${group_demos}Policy$"; then
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

        echo "# euare-groupuploadpolicy --policy-name ${group_demos}Policy \\"
        echo ">                         --policy-document $tmpdir/$account/${group_demos}GroupPolicy.json \\"
        echo ">                         --region $user_region \\"
        echo ">                         $group_demos"
        euare-groupuploadpolicy --policy-name ${group_demos}Policy \
                                --policy-document $tmpdir/$account/${group_demos}GroupPolicy.json \
                                --region $user_region \
                                $group_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developers ($group_developers) Group"
echo "    - This Group is intended for Developers who can modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate --region $user_region $group_developers"

if euare-grouplistbypath --region $user_region | grep -s -q ":group/$group_developers$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate --region $user_region $group_developers"
        euare-groupcreate --region $user_region $group_developers

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developers ($group_developers) Group Policy"
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
echo "euare-groupuploadpolicy --policy-name ${group_developers}Policy \\"
echo "                        --policy-document $tmpdir/$account/${group_developers}GroupPolicy.json \\"
echo "                        --region $user_region \\"
echo "                        $group_developers"

if euare-grouplistpolicies --region $user_region $group_developers | grep -s -q "${group_developers}Policy$"; then
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

        echo "# euare-groupuploadpolicy --policy-name ${group_developers}Policy \\"
        echo ">                         --policy-document $tmpdir/$account/${group_developers}GroupPolicy.json \\"
        echo ">                         --region $user_region \\"
        echo ">                         $group_developers"
        euare-groupuploadpolicy --policy-name ${group_developers}Policy \
                                --policy-document $tmpdir/$account/${group_developers}GroupPolicy.json \
                                --region $user_region \
                                $group_developers

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Users ($group_users) Group"
echo "    - This Group is intended for Users who can view but not modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate --region $user_region $group_users"

if euare-grouplistbypath --region $user_region | grep -s -q ":group/$group_users$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate --region $user_region $group_users"
        euare-groupcreate --region $user_region $group_users

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Users ($group_users) Group Policy"
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
echo "euare-groupuploadpolicy --policy-name ${group_users}Policy \\"
echo "                        --policy-document $tmpdir/$account/${group_users}GroupPolicy.json \\"
echo "                        --region $user_region \\"
echo "                        $group_users"

if euare-grouplistpolicies --region $user_region $group_users | grep -s -q "${group_users}Policy$"; then
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

        echo "# euare-groupuploadpolicy --policy-name ${group_users}Policy \\"
        echo ">                         --policy-document $tmpdir/$account/${group_users}GroupPolicy.json \\"
        echo ">                         --region $user_region \\"
        echo ">                         $group_users"
        euare-groupuploadpolicy --policy-name ${group_users}Policy \
                                --policy-document $tmpdir/$account/${group_users}GroupPolicy.json \
                                --region $user_region \
                                $group_users

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo ($user_demo) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate --region $user_region $user_demo"

if euare-userlistbypath --region $user_region | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate --region $user_region $user_demo"
        euare-usercreate --region $user_region $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add AWS ($account) Account Demo ($user_demo) User to Demos ($group_demos) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser --user-name $user_demo --region $user_region $group_demos"

if euare-grouplistusers --user-name $user_demo $group_demos | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser --user-name $user_demo --region $user_region $group_demos"
        euare-groupadduser --user-name $user_demo --region $user_region $group_demos

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo ($user_demo) User Login Profile"
echo "    - This allows the Demo Account Demo User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile --password $user_demo_password --region $user_region $user_demo"

if euare-usergetloginprofile --region $user_region $user_demo &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile --password $user_demo_password --region $user_region $user_demo"
        euare-useraddloginprofile --password $user_demo_password --region $user_region $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo ($user_demo) User Access Key"
echo "    - This allows the Demo Account Demo User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$federation/$account/$user_demo"
echo
echo "euare-useraddkey --region $user_region $user_demo"
echo
echo "cat << EOF > ~/.creds/$federation/$account/$user_demo/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$federation/$account/$user_demo/iamrc"

if [ -r ~/.creds/$federation/$account/$user_demo/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/$user_demo"
        mkdir -p ~/.creds/$federation/$account/$user_demo
        pause

        echo "# euare-useraddkey --region $user_region $user_demo"
        result=$(euare-useraddkey --region $user_region $user_demo) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$federation/$account/$user_demo/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$federation/$account/$user_demo/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/$user_demo/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$federation/$account/$user_demo/iamrc"
        chmod 0600 ~/.creds/$federation/$account/$user_demo/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo ($user_demo) User Euca2ools Profile"
echo "    - This allows the Demo Account Demo User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$federation.ini"
echo "[user $federation-$account-$user_demo]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region $federation-$account-$user_demo@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-$user_demo]" ~/.euca/$federation.ini; then
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
        echo "# cat << EOF >> ~/.euca/$federation.ini"
        echo "> [user $federation-$account-$user_demo]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-$user_demo]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"                   >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"               >> ~/.euca/$federation.ini
        echo                                          >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region $federation-$account-$user_demo@$region"
        euca-describe-availability-zones --region $federation-$account-$user_demo@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Demo ($user_demo) User AWSCLI Profile"
echo "    - This allows the Demo Account Demo User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $account-$user_demo]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$account-$user_demo]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $account-$user_demo --region $region --output text"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-$user_demo]" ~/.aws/config; then
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
        echo "> [profile $account-$user_demo]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-$user_demo]" >> ~/.aws/config
        echo "region = $region"              >> ~/.aws/config
        echo "output = text"                 >> ~/.aws/config
        echo                                 >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$account-$user_demo]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-$user_demo]"               >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $account-$user_demo --region $region --output text"
        aws ec2 describe-availability-zones --profile $account-$user_demo --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developer ($user_developer) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate --region $user_region $user_developer"

if euare-userlistbypath --region $user_region | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate --region $user_region $user_developer"
        euare-usercreate --region $user_region $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add AWS ($account) Account Developer ($user_developer) User to Developers ($group_developers) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser --user-name $user_developer --region $user_region $group_developers"

if euare-grouplistusers --region $user_region $group_developers | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser --user-name $user_developer --region $user_region $group_developers"
        euare-groupadduser --user-name $user_developer --region $user_region $group_developers

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developer ($user_developer) User Login Profile"
echo "    - This allows the Demo Account Developer User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile --password $user_developer_password --region $user_region $user_developer"

if euare-usergetloginprofile --region $user_region $user_developer &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile --password $user_developer_password --region $user_region $user_developer"
        euare-useraddloginprofile --password $user_developer_password --region $user_region $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developer ($user_developer) User Access Key"
echo "    - This allows the Demo Account Developer User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$federation/$account/$user_developer"
echo
echo "euare-useraddkey --region $user_region $user_developer"
echo
echo "cat << EOF > ~/.creds/$federation/$account/$user_developer/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$federation/$account/$user_developer/iamrc"

if [ -r ~/.creds/$federation/$account/$user_developer/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/$user_developer"
        mkdir -p ~/.creds/$federation/$account/$user_developer
        pause

        echo "# euare-useraddkey --region $user_region $user_developer"
        result=$(euare-useraddkey --region $user_region $user_developer) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$federation/$account/$user_developer/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$federation/$account/$user_developer/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/$user_developer/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$federation/$account/$user_developer/iamrc"
        chmod 0600 ~/.creds/$federation/$account/$user_developer/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developer ($user_developer) User Euca2ools Profile"
echo "    - This allows the Demo Account Developer User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$federation.ini"
echo "[user $federation-$account-$user_developer]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region $federation-$account-$user_developer@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-$user_developer]" ~/.euca/$federation.ini; then
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
        echo "# cat << EOF >> ~/.euca/$federation.ini"
        echo "> [user $federation-$account-$user_developer]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-$user_developer]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"                        >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"                    >> ~/.euca/$federation.ini
        echo                                               >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region $federation-$account-$user_developer@$region"
        euca-describe-availability-zones --region $federation-$account-$user_developer@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Developer ($user_developer) User AWSCLI Profile"
echo "    - This allows the Demo Account Developer User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $account-$user_developer]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$account-$user_developer]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $account-$user_developer --region $region --output text"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-$user_developer]" ~/.aws/config; then
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
        echo "> [profile $account-$user_developer]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-$user_developer]" >> ~/.aws/config
        echo "region = $region"                   >> ~/.aws/config
        echo "output = text"                      >> ~/.aws/config
        echo                                      >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$account-$user_developer]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-$user_developer]"          >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $account-$user_developer --region $region --output text"
        aws ec2 describe-availability-zones --profile $account-$user_developer --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account User ($user_user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate --region $user_region $user_user"

if euare-userlistbypath --region $user_region | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate --region $user_region $user_user"
        euare-usercreate --region $user_region $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add AWS ($account) Account User ($user_user) User to Users ($group_users) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser --user-name $user_user --region $user_region $group_users"

if euare-grouplistusers --region $user_region $group_users | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser --user-name $user_user --region $user_region $group_users"
        euare-groupadduser --user-name $user_user --region $user_region $group_users

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account User ($user_user) User Login Profile"
echo "    - This allows the Demo Account User User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile --password $user_user_password --region $user_region $user_user"

if euare-usergetloginprofile --region $user_region $user_user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile --password $user_user_password --region $user_region $user_user"
        euare-useraddloginprofile --password $user_user_password --region $user_region $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account User ($user_user) User Access Key"
echo "    - This allows the Demo Account User User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$federation/$account/$user_user"
echo
echo "euare-useraddkey --region $user_region $user_user"
echo
echo "cat << EOF > ~/.creds/$federation/$account/$user_user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$federation/$account/$user_user/iamrc"

if [ -r ~/.creds/$federation/$account/$user_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/$user_user"
        mkdir -p ~/.creds/$federation/$account/$user_user
        pause

        echo "# euare-useraddkey --region $user_region $user_user"
        result=$(euare-useraddkey --region $user_region $user_user) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$federation/$account/$user_user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$federation/$account/$user_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/$user_user/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$federation/$account/$user_user/iamrc"
        chmod 0600 ~/.creds/$federation/$account/$user_user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account User ($user_user) User Euca2ools Profile"
echo "    - This allows the Demo Account User User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$federation.ini"
echo "[user $federation-$account-$user_user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region $federation-$account-$user_user@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-$user_user]" ~/.euca/$federation.ini; then
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
        echo "# cat << EOF >> ~/.euca/$federation.ini"
        echo "> [user $federation-$account-$user_user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-$user_user]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"                   >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"               >> ~/.euca/$federation.ini
        echo                                          >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region $federation-$account-$user_user@$region"
        euca-describe-availability-zones --region $federation-$account-$user_user@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account User ($user_user) User AWSCLI Profile"
echo "    - This allows the Demo Account User User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $account-$user_user]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$account-$user_user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $account-$user_user --region $region --output text"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-$user_user]" ~/.aws/config; then
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
        echo "> [profile $account-$user_user]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-$user_user]" >> ~/.aws/config
        echo "region = $region"              >> ~/.aws/config
        echo "output = text"                 >> ~/.aws/config
        echo                                 >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$account-$user_user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-$user_user]"               >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $account-$user_user --region $region --output text"
        aws ec2 describe-availability-zones --profile $account-$user_user --region $region --output text

        next
    fi
fi


((++step))
if [ $verbose = 1 ]; then
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
    echo "euca-describe-keypairs --region $user_region"
    echo
    echo "euare-rolelistbypath --region $user_region"
    echo "euare-instanceprofilelistbypath --region $user_region"
    echo "euare-instanceprofilelistforrole --region $user_region -r $role_demos"
    echo
    echo "euare-grouplistbypath --region $user_region"
    echo
    echo "euare-userlistbypath --region $user_region"
    echo
    echo "euare-grouplistusers --region $user_region -g $group_demos"
    echo "euare-grouplistusers --region $user_region -g $group_developers"
    echo "euare-grouplistusers --region $user_region -g $group_users"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-keypairs --region $user_region"
        euca-describe-keypairs --region $user_region
        pause

        echo "# euare-rolelistbypath --region $user_region"
        euare-rolelistbypath --region $user_region
        echo "#"
        echo "# euare-instanceprofilelistbypath --region $user_region"
        euare-instanceprofilelistbypath --region $user_region
        echo "#"
        echo "# euare-instanceprofilelistforrole --region $user_region $role_demos"
        euare-instanceprofilelistforrole --region $user_region $role_demos
        pause

        echo "# euare-grouplistbypath --region $user_region"
        euare-grouplistbypath --region $user_region
        pause

        echo "# euare-userlistbypath --region $user_region"
        euare-userlistbypath --region $user_region
        pause

        echo "# euare-grouplistusers --region $user_region $group_demos"
        euare-grouplistusers --region $user_region $group_demos
        echo "#"
        echo "# euare-grouplistusers --region $user_region $group_developers"
        euare-grouplistusers --region $user_region $group_developers
        echo "#"
        echo "# euare-grouplistusers --region $user_region $group_users"
        euare-grouplistusers --region $user_region $group_users

        next 200
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Display Euca2ools Configuration"
    echo "    - The $region Region should be the default."
    echo "    - The $region Region should be configured with Custom"
    echo "      DNS HTTPS URLs. It can be used from other hosts."
    echo "    - The localhost Region should be configured with direct"
    echo "      URLs. It can be used only from this host."
    echo "    - The $federation Federation should be configured with"
    echo "      AWS HTTPS URLs and Federated Identity Users."
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "cat ~/.euca/global.ini"
    echo
    echo "cat /etc/euca2ools/conf.d/$region.ini"
    echo
    echo "cat /etc/euca2ools/conf.d/localhost.ini"
    echo
    echo "cat /etc/euca2ools/conf.d/$federation.ini"
    echo
    echo "cat ~/.euca/$region.ini"
    echo
    echo "cat ~/.euca/localhost.ini"
    echo
    echo "cat ~/.euca/$federation.ini"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat ~/.euca/global.ini"
        cat ~/.euca/global.ini
        pause

        echo "# cat /etc/euca2ools/conf.d/$region.ini"
        cat /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# cat /etc/euca2ools/conf.d/localhost.ini"
        cat /etc/euca2ools/conf.d/localhost.ini
        pause

        echo "# cat /etc/euca2ools/conf.d/$federation.ini"
        cat /etc/euca2ools/conf.d/$federation.ini 
        pause

        echo "# cat ~/.euca/$region.ini"
        cat ~/.euca/$region.ini 
        pause

        echo "# cat ~/.euca/localhost.ini"
        cat ~/.euca/localhost.ini
        pause

        echo "# cat ~/.euca/$federation.ini"
        cat ~/.euca/$federation.ini 2>/dev/null

        next 200
    fi
fi


((++step))
if [ $verbose = 1 ]; then
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
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Demo Account Dependencies configured for demo scripts (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Demo Account Dependencies configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
