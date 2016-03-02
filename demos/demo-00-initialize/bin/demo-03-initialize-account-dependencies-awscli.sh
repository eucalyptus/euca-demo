#!/bin/bash
#
# This script initializes a Management Workstation and it's associated Eucalyptus Region with
# dependencies used in demos, including:
# - Confirms the Demo Images are available to the Demo Account
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
# This is a variant of the demo-03-initialize-account-dependencies.sh script which primarily uses
# the AWSCLI
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
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-admin}
prefix=${account}123
user_demo_password=${prefix}-${user_demo}
user_developer_password=${prefix}-${user_developer}
user_user_password=${prefix}-${user_user}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-p prefix]"
    echo "Usage:        [-r region] [-a account] [-u user]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -v          verbose"
    echo "  -p prefix   prefix for passwords created for new Users (default: $prefix)"
    echo "  -r region   Eucalyptus Region (default: $region)"
    echo "  -a account  Eucalyptus Account (default: $account)"
    echo "  -u user     Eucalyptus User with permissions to create new Groups and Users (default $user)"
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
        echo "-r $region invalid: This script can not be run against AWS regions"
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

profile=$region-$account-$user

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($region) Region Demo ($account) Account Administrator ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 51
fi

mkdir -p $tmpdir/$account

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Prepare Eucalyptus Demo Account for Demo Dependencies

start=$(date +%s)

((++step))
if [ $verbose = 1 ]; then
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
    echo "aws ec2 describe-images --profile $profile --region $region --output text"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-images --profile $profile --region $region --output text"
        aws ec2 describe-images --profile $profile --region $region --output text

        next
    fi
fi


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
echo "$(printf '%2d' $step). Import Demo ($account) Account Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws ec2 import-key-pair --key-name=demo \\"
echo "                        --public-key-material file://~/.ssh/demo_id_rsa.pub \\"
echo "                        --profile $profile --region $region --output text"

if aws ec2 describe-key-pairs --profile $profile --region $region --output text | cut -f3 | grep -s -q "^demo$"; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 import-key-pair --key-name=demo \\"
        echo ">                         --public-key-material file://~/.ssh/demo_id_rsa.pub \\"
        echo ">                         --profile $profile --region $region --output text"
        aws ec2 import-key-pair --key-name=demo \
                                --public-key-material file://~/.ssh/demo_id_rsa.pub \
                                --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo (demo-$account) Bucket"
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
echo "                    --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json \\"
echo "                    --profile $profile --region $region --output text"
echo
echo "aws iam create-instance-profile --instance-profile-name $instance_profile_demos \\"
echo "                                --profile $profile --region $region --output text"
echo
echo "aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos \\"
echo "                                     --profile $profile --region $region --output text"

if aws iam list-roles --profile $profile --region $region --output text | grep -s -q ":role/$role_demos"; then
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
        echo ">                     --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json \\"
        echo ">                     --profile $profile --region $region --output text"
        aws iam create-role --role-name $role_demos \
                            --assume-role-policy-document file://$tmpdir/$account/${role_demos}RoleTrustPolicy.json \
                            --profile $profile --region $region --output text
        pause

        echo "# aws iam create-instance-profile --instance-profile-name $instance_profile_demos \\"
        echo ">                                 --profile $profile --region $region --output text"
        aws iam create-instance-profile --instance-profile-name $instance_profile_demos \
                                        --profile $profile --region $region --output text
        pause

        echo "# aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos \\"
        echo ">                                      --profile $profile --region $region --output text"
        aws iam add-role-to-instance-profile --instance-profile-name $instance_profile_demos --role-name $role_demos \
                                             --profile $profile --region $region --output text

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
sed -e "s/\${account}/$account/g" $policiesdir/DemosRolePolicy.json
echo "EOF"
echo
echo "aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \\"
echo "                        --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json \\"
echo "                        --profile $profile --region $region --output text"

if aws iam list-role-policies --role-name $role_demos \
                              --profile $profile --region $region --output text | grep -s -q "${role_demos}Policy$"; then
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

        echo "# aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \\"
        echo ">                         --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json \\"
        echo ">                         --profile $profile --region $region --output text"
        aws iam put-role-policy --role-name $role_demos --policy-name ${role_demos}Policy \
                                --policy-document file://$tmpdir/$account/${role_demos}RolePolicy.json \
                                --profile $profile --region $region --output text

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
echo "aws iam create-group --group-name $group_demos \\"
echo "                     --profile $profile --region $region --output text"

if aws iam list-groups --profile $profile --region $region --output text | grep -s -q ":group/$group_demos"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_demos \\"
        echo ">                      --profile $profile --region $region --output text"
        aws iam create-group --group-name $group_demos \
                             --profile $profile --region $region --output text

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
echo "                         --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json \\"
echo "                         --profile $profile --region $region --output text"

if aws iam list-group-policies --group-name $group_demos \
                               --profile $profile --region $region --output text | grep -s -q "${group_demos}Policy$"; then
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
        echo ">                          --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json \\"
        echo ">                          --profile $profile --region $region --output text"
        aws iam put-group-policy --group-name $group_demos --policy-name ${group_demos}Policy \
                                 --policy-document file://$tmpdir/$account/${group_demos}GroupPolicy.json \
                                 --profile $profile --region $region --output text

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
echo "aws iam create-group --group-name $group_developers \\"
echo "                     --profile $profile --region $region --output text"

if aws iam list-groups --profile $profile --region $region --output text | grep -s -q ":group/$group_developers"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_developers \\"
        echo ">                      --profile $profile --region $region --output text"
        aws iam create-group --group-name $group_developers \
                             --profile $profile --region $region --output text

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
echo "                         --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json \\"
echo "                         --profile $profile --region $region --output text"

if aws iam list-group-policies --group-name $group_developers \
                               --profile $profile --region $region --output text | grep -s -q "${group_developers}Policy$"; then
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
        echo ">                          --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json \\"
        echo ">                          --profile $profile --region $region --output text"
        aws iam put-group-policy --group-name $group_developers --policy-name ${group_developers}Policy \
                                 --policy-document file://$tmpdir/$account/${group_developers}GroupPolicy.json \
                                 --profile $profile --region $region --output text

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
echo "aws iam create-group --group-name $group_users \\"
echo "                     --profile $profile --region $region --output text"

if aws iam list-groups --profile $profile --region $region --output text | grep -s -q ":group/$group_users"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group_users \\"
        echo ">                      --profile $profile --region $region --output text"
        aws iam create-group --group-name $group_users \
                             --profile $profile --region $region --output text

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
echo "                         --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json \\"
echo "                         --profile $profile --region $region --output text"

if aws iam list-group-policies --group-name $group_users \
                               --profile $profile --region $region --output text | grep -s -q "${group_users}Policy$"; then
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
        echo ">                          --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json \\"
        echo ">                          --profile $profile --region $region --output text"
        aws iam put-group-policy --group-name $group_users --policy-name ${group_users}Policy \
                                 --policy-document file://$tmpdir/$account/${group_users}GroupPolicy.json \
                                 --profile $profile --region $region --output text

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
echo "aws iam create-user --user-name $user_demo \\"
echo "                    --profile $profile --region $region --output text"

if aws iam list-users --profile $profile --region $region --output text | grep -s -q ":user/$user_demo"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_demo \\"
        echo ">                     --profile $profile --region $region --output text"
        aws iam create-user --user-name $user_demo \
                            --profile $profile --region $region --output text

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
echo "aws iam add-user-to-group --group-name $group_demos --user-name $user_demo \\"
echo "                          --profile $profile --region $region --output text"

if aws iam get-group --group-name $group_demos \
                     --profile $profile --region $region --output text | grep -s -q ":user/$user_demo"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_demos --user-name $user_demo \\"
        echo ">                           --profile $profile --region --output text $region"
        aws iam add-user-to-group --group-name $group_demos --user-name $user_demo \
                                  --profile $profile --region $region --output text

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
echo "aws iam create-login-profile --user-name $user_demo --password $user_demo_password \\"
echo "                             --profile $profile --region $region --output text"

if aws iam get-login-profile --user-name $user_demo \
                             --profile $profile --region $region --output text &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_demo --password $user_demo_password \\"
        echo ">                              --profile $profile --region $region --output text"
        aws iam create-login-profile --user-name $user_demo --password $user_demo_password \
                                     --profile $profile --region $region --output text

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
echo "aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
echo "                          --profile $profile --region $region --output text"
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

        echo "# aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
        echo ">                           --profile $profile --region $region --output text"
        result=$(aws iam create-access-key --user-name $user_demo --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
                                           --profile $profile --region $region --output text) && echo $result
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
echo "euca-describe-availability-zones --region $region-$account-$user_demo@$region"

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

        echo "# euca-describe-availability-zones --region $region-$account-$user_demo@$region"
        euca-describe-availability-zones --region $region-$account-$user_demo@$region

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
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region --output text"

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

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region --output text"
        aws ec2 describe-availability-zones --profile $region-$account-$user_demo --region $region --output text

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
echo "aws iam create-user --user-name $user_developer \\"
echo "                    --profile $profile --region $region --output text"

if  aws iam list-users --profile $profile --region $region --output text | grep -s -q ":user/$user_developer"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_developer \\"
        echo ">                     --profile $profile --region $region --output text"
        aws iam create-user --user-name $user_developer \
                            --profile $profile --region $region --output text

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
echo "aws iam add-user-to-group --group-name $group_developers --user-name $user_developer \\"
echo "                          --profile $profile --region $region --output text"

if aws iam get-group --group-name $group_developers \
                     --profile $profile --region $region --output text | grep -s -q ":user/$user_developer"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_developers --user-name $user_developer \\"
        echo ">                           --profile $profile --region $region --output text"
        aws iam add-user-to-group --group-name $group_developers --user-name $user_developer \
                                  --profile $profile --region $region --output text

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
echo "aws iam create-login-profile --user-name $user_developer --password $user_developer_password \\"
echo "                             --profile $profile --region $region --output text"

if aws iam get-login-profile --user-name $user_developer \
                             --profile $profile --region $region --output text &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_developer --password $user_developer_password \\"
        echo ">                              --profile $profile --region $region --output text"
        aws iam create-login-profile --user-name $user_developer --password $user_developer_password \
                                     --profile $profile --region $region --output text

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
echo "aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
echo "                          --profile $profile --region $region --output text"
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

        echo "# aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
        echo ">                           --profile $profile --region $region --output text"
        result=$(aws iam create-access-key --user-name $user_developer --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
                                           --profile $profile --region $region --output text) && echo $result
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
echo "euca-describe-availability-zones --region $region-$account-$user_developer@$region"

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

        echo "# euca-describe-availability-zones --region $region-$account-$user_developer@$region"
        euca-describe-availability-zones --region $region-$account-$user_developer@$region

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
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region --output text"

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

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region --output text"
        aws ec2 describe-availability-zones --profile $region-$account-$user_developer --region $region --output text

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
echo "aws iam create-user --user-name $user_user \\"
echo "                    --profile $profile --region $region --output text"

if aws iam list-users --profile $profile --region $region --output text | grep -s -q ":user/$user_user"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user_user \\"
        echo ">                     --profile $profile --region $region --output text"
        aws iam create-user --user-name $user_user \
                            --profile $profile --region $region --output text

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
echo "aws iam add-user-to-group --group-name $group_users --user-name $user_user \\"
echo "                          --profile $profile --region $region --output text"

if aws iam get-group --group-name $group_users \
                     --profile $profile --region $region --output text | grep -s -q ":user/$user_user"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group_users --user-name $user_user \\"
        echo ">                           --profile $profile --region $region --output text"
        aws iam add-user-to-group --group-name $group_users --user-name $user_user \
                                  --profile $profile --region $region --output text

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
echo "aws iam create-login-profile --user-name $user_user --password $user_user_password \\"
echo "                             --profile $profile --region $region --output text"

if aws iam get-login-profile --user-name $user_user \
                             --profile $profile --region $region --output text &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user_user --password $user_user_password \\"
        echo ">                              --profile $profile --region $region --output text"
        aws iam create-login-profile --user-name $user_user --password $user_user_password \
                                     --profile $profile --region $region --output text

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
echo "aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
echo "                          --profile $profile --region $region --output text"
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

        echo "# aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
        echo ">                           --profile $profile --region $region --output text"
        result=$(aws iam create-access-key --user-name $user_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
                                           --profile $profile --region $region --output text) && echo $result
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
echo "euca-describe-availability-zones --region $region-$account-$user_user@$region"

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
        echo "[user $region-$account-$user_user]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key"               >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key"           >> ~/.euca/euca2ools.ini
        echo                                      >> ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones --region $region-$account-$user_user@$region"
        euca-describe-availability-zones --region $region-$account-$user_user@$region

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
echo "aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region --output text"

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

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region --output text"
        aws ec2 describe-availability-zones --profile $region-$account-$user_user --region $region --output text

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
    echo "aws ec2 describe-images --profile $profile --region $region --output text"
    echo
    echo "aws ec2 describe-key-pairs --profile $profile --region $region --output text"
    echo
    echo "aws iam list-roles --profile $profile --region $region --output text"
    echo "aws iam list-instance-profiles --profile $profile --region $region --output text"
    echo "aws iam get-instance-profile --instance-profile-name $role_demos \\"
    echo "                             --profile $profile --region $region --output text"
    echo
    echo "aws iam list-groups --profile $profile --region $region --output text"
    echo
    echo "aws iam list-users --profile $profile --region $region --output text"
    echo
    echo "aws iam get-group --group-name $group_demos \\"
    echo "                  --profile $profile --region $region --output text"
    echo "aws iam get-group --group-name $group_developers \\"
    echo "                  --profile $profile --region $region --output text"
    echo "aws iam get-group --group-name $group_users \\"
    echo "                  --profile $profile --region $region --output text"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-images --profile $profile --region $region --output text"
        aws ec2 describe-images --profile $profile --region $region --output text
        pause

        echo "# aws ec2 describe-key-pairs --profile $profile --region $region --output text"
        aws ec2 describe-key-pairs --profile $profile --region $region --output text
        pause

        echo "# aws iam list-roles --profile $profile --region $region --output text"
        aws iam list-roles --profile $profile --region $region --output text
        echo "#"
        echo "# aws iam list-instance-profiles --profile $profile --region $region --output text"
        aws iam list-instance-profiles --profile $profile --region $region --output text
        echo "#"
        echo "# aws iam get-instance-profile --instance-profile-name $role_demos \\
        echo ">                              --profile $profile --region $region --output text"
        aws iam get-instance-profile --instance-profile-name $role_demos \
                                     --profile $profile --region $region --output text
        pause

        echo "# aws iam list-groups --profile $profile --region $region --output text"
        aws iam list-groups --profile $profile --region $region --output text
        pause

        echo "# aws iam list-users --profile $profile --region $region --output text"
        aws iam list-users --profile $profile --region $region --output text
        pause

        echo "# aws iam get-group --group-name $group_demos \\"
        echo ">                   --profile $profile --region $region --output text"
        aws iam get-group --group-name $group_demos \
                          --profile $profile --region $region --output text
        echo "#"
        echo "# aws iam get-group --group-name $group_developers \\"
        echo ">                   --profile $profile --region $region --output text"
        aws iam get-group --group-name $group_developers \
                          --profile $profile --region $region --output text
        echo "#"
        echo "# aws iam get-group --group-name $group_users \\"
        echo ">                   --profile $profile --region $region --output text"
        aws iam get-group --group-name $group_users \
                          --profile $profile --region $region --output text

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
    echo "cat ~/.euca/$region.ini"
    echo
    echo "cat ~/.euca/localhost.ini"

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

        echo "# cat ~/.euca/$region.ini"
        cat ~/.euca/$region.ini 
        pause

        echo "# cat ~/.euca/localhost.ini"
        cat ~/.euca/localhost.ini

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
