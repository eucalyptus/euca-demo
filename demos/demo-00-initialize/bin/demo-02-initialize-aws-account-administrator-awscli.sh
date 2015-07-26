#!/bin/bash
#
# This script initializes a Management Workstation and it's associated AWS Account with an
# additional User within the Administrators Group, including:
# - Creates the Administrators Group (named "Administrators")
# - Attaches the AdministratorAccess Managed Policy to the Administrators Group
# - Creates an administrator User (specified via parameter)
# - Adds the administrator User to the Administrators Group
# - Creates the administrator User Login Profile
# - Creates the administrator User Access Key
# - Configures Euca2ools for the administrator User
# - Configures AWSCLI for the administrator User
# - Lists Demo Account Resources
# - Displays Euca2ools Configuration
# - Displays AWSCLI Configuration
#
# This is a variant of the demo-02-initialize-aws-account-administrator.sh script which primarily
# uses the AWSCLI.
#
# The demo-00-initialize-aws.sh script should be run by the AWS Account Administrator once prior
# to running this script.
#
# Then the demo-01-initialize-aws-account.sh script should be run by the AWS Account Administrator
# to move AWS Account-level Credentials downloaded during the manual AWS Account creation process
# into a standard Euca2ools and AWSCLI storage onvention. This is optional, but required for the
# next script to be run.
#
# Then this script should be run by the AWS Account Administrator as many times as needed to
# create one or more AWS IAM Users in the Account Administrators Group.
#
# Then the demo-03-initialize-aws-account-dependencies.sh script should be run once by an AWS
# Account Administrator or an AWS User in the Administrators Group to create additional groups,
# users, roles and instance profiles in the AWS Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
policiesdir=${bindir%/*}/policies
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

federation=aws

group=Administrators

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
account=hp
unset user
unset password
admin=admin


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ] [-a account] [-u user] [-p password] [-U admin]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -r region    AWS Region (default: $region)"
    echo "  -a account   AWS Account name to use in demos (default: $account)"
    echo "  -u user      AWS User to create and add to Administrators Group"
    echo "  -p password  password for new User"
    echo "  -U admin     existing AWS User with permissions to create new Groups and Users (default $admin)"
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

while getopts Isfr:a:u:p:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    u)  user="$OPTARG";;
    p)  password="$OPTARG";;
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
    echo "User must be specified as a parameter"
    exit 14
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

profile=$account-$admin

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find AWS ($account) Account Administrator ($admin) User AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 20
fi

mkdir -p $tmpdir/$account


#  5. Prepare AWS Account for Administrators

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
if [ $admin = admin ]; then
    echo "$(printf '%2d' $step). Use AWS ($account) Account Administrator profile"
else
    echo "$(printf '%2d' $step). Use AWS ($account) Account Administrator ($admin) User profile"
fi
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "export AWS_DEFAULT_PROFILE=$profile"
echo "export AWS_DEFAULT_REGION=$region"
echo
echo "echo \$AWS_DEFAULT_PROFILE"
echo "echo \$AWS_DEFAULT_REGION"

next

echo
echo "# export AWS_DEFAULT_PROFILE=$profile"
export AWS_DEFAULT_PROFILE=$profile
echo "# export AWS_DEFAULT_REGION=$region"
export AWS_DEFAULT_REGION=$region
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
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrators ($group) Group"
echo "    - This Group is intended for Users who have complete control of all Resources in the Account"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-group --group-name $group"

if aws iam list-groups | grep -s -q ":group/$group"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $group"
        aws iam create-group --group-name $group

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Attach AdministratorAccess Managed Policy to AWS ($account) Account Administrators ($group) Group"
echo "    - This Policy provides complete control of all Resources in the Account"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam attach-group-policy --group-name Administrators \\"
echo "                            --policy-arn arn:aws:iam::aws:policy/AdministratorAccess"

if aws iam list-attached-group-policies --group-name $group | grep -s -q ":policy/AdministratorAccess$"; then
    echo
    tput rev
    echo "Already Attached!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam attach-group-policy --group-name Administrators \\"
        echo ">                             --policy-arn arn:aws:iam::aws:policy/AdministratorAccess"
        aws iam attach-group-policy --group-name Administrators \
                                    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-user --user-name $user"

if aws iam list-users | grep -s -q ":user/$user"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $user"
        aws iam create-user --user-name $user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add AWS ($account) Account Administrator ($user) User to Administrators ($group) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam add-user-to-group --group-name $group --user-name $user"

if aws iam get-group --group-name $group | grep -s -q ":user/$user"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group --user-name $user"
        aws iam add-user-to-group --group-name $group --user-name $user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($user) User Login Profile"
echo "    - This allows the AWS Account Administrator User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-login-profile --user-name $user --password $password"

if aws iam get-login-profile --user-name $user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $user --password $password"
        aws iam create-login-profile --user-name $user --password $password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($user) User Access Key"
echo "    - This allows the AWS Account Administrator User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$federation/$account/$user"
echo
echo "aws iam create-access-key --user-name $user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
echo
echo "cat << EOF > ~/.creds/$federation/$account/$user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"

if [ -r ~/.creds/$federation/$account/$user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/$user"
        mkdir -p ~/.creds/$federation/$account/$user
        pause

        echo "# aws iam create-access-key --user-name $user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}'"
        result=$(aws iam create-access-key --user-name $user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}') && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$federation/$account/$user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$federation/$account/$user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/$user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($user) User Euca2ools Profile"
echo "    - This allows the AWS Account Administrator User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$federation.ini"
echo "[user $federation-$account-$user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$federation-$account-$user@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-$user]" ~/.euca/$federation.ini; then
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
        echo "> [user $federation-$account-$user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-$user]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"              >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"          >> ~/.euca/$federation.ini
        echo                                     >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region=$federation-$account-$user@$region"
        euca-describe-availability-zones --region=$federation-$account-$user@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($user) User AWSCLI Profile"
echo "    - This allows the AWS Account Administrator User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $account-$user]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$account-$user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=$account-$user"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-$user]" ~/.aws/config; then
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
        echo "> [profile $account-$user]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-$user]" >> ~/.aws/config
        echo "region = $region"         >> ~/.aws/config
        echo "output = text"            >> ~/.aws/config
        echo                            >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$account-$user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-$user]"                    >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=$account-$user"
        aws ec2 describe-availability-zones --profile=$account-$user

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
echo "aws iam list-groups"
echo
echo "aws iam list-users"
echo
echo "aws iam get-group --group-name $group"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws ec2 describe-images"
    aws ec2 describe-images
    pause

    echo "# aws ec2 describe-key-pairs"
    aws ec2 describe-key-pairs
    pause

    echo "# aws iam list-groups"
    aws iam list-groups
    pause

    echo "# aws iam list-users"
    aws iam list-users
    pause

    echo "# aws iam get-group --group-name $group"
    aws iam get-group --group-name $group

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
echo "cat /etc/euca2ools/conf.d/$federation.ini"
echo
echo "cat ~/.euca/global.ini"
echo
echo "cat ~/.euca/$federation.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat /etc/euca2ools/conf.d/$federation.ini"
    cat /etc/euca2ools/conf.d/$federation.ini
    pause

    echo "# cat ~/.euca/global.ini"
    cat ~/.euca/global.ini
    pause

    echo "# cat ~/.euca/$federation.ini"
    cat ~/.euca/$federation.ini

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
echo "AWS Account Administrator configured (time: $(date -u -d @$((end-start)) +"%T"))"
