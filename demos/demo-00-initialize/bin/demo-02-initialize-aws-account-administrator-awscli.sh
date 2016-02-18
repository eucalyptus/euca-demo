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
# uses the AWSCLI
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
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-euca}
user=${AWS_USER_NAME:-admin}
unset new_user
unset password


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-n new_user] [-p password]"
    echo "               [-r region] [-a account] [-u user]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -v           verbose"
    echo "  -n new_user  new User to create and add to Administrators Group"
    echo "  -p password  password for new User"
    echo "  -r region    AWS Region (default: $region)"
    echo "  -a account   AWS Account (default: $account)"
    echo "  -u user      AWS User with permissions to create new Groups and Users (default $user)"
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

while getopts Isfvn:p:r:a:u:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    n)  new_user="$OPTARG";;
    p)  password="$OPTARG";;
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

if [ -z $new_user ]; then
    echo "-n new_user missing!"
    echo "New User must be specified as a parameter"
    exit 16
fi

if [ -z $password ]; then
    echo "-p password missing!"
    echo "Password must be specified as a parameter"
    exit 18
fi

profile=$account-$user

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find AWS ($account) Account Administrator ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 51
fi

mkdir -p $tmpdir/$account

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Prepare AWS Account for Administrators

start=$(date +%s)

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
echo "aws iam create-group --group-name $group \\"
echo "                     --profile $profile --region $region"

if aws iam list-groups --profile $profile --region $region | grep -s -q ":group/$group"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-group --group-name $groups \\"
        echo ">                      --profile $profile --region $region"
        aws iam create-group --group-name $group \
                             --profile $profile --region $region

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
echo "                            --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \\"
echo "                            --profile $profile --region $region"

if aws iam list-attached-group-policies --group-name $group \
                                        --profile $profile --region $region | grep -s -q ":policy/AdministratorAccess"; then
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
        echo ">                             --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \\"
        echo ">                             --profile $profile --region $region"
        aws iam attach-group-policy --group-name Administrators \
                                    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
                                    --profile $profile --region $region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($new_user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-user --user-name $new_user \\"
echo "                    --profile $profile --region $region"

if aws iam list-users --profile $profile --region $region | grep -s -q ":user/$new_user"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-user --user-name $new_user \\"
        echo ">                     --profile $profile --region $region"
        aws iam create-user --user-name $new_user \
                            --profile $profile --region $region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add AWS ($account) Account Administrator ($new_user) User to Administrators ($group) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam add-user-to-group --group-name $group --user-name $new_user \\"
echo "                          --profile $profile --region $region"

if aws iam get-group --group-name $group \
                     --profile $profile --region $region | grep -s -q ":user/$new_user"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam add-user-to-group --group-name $group --user-name $new_user \\"
        echo ">                           --profile $profile --region $region"
        aws iam add-user-to-group --group-name $group --user-name $new_user \
                                  --profile $profile --region $region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($new_user) User Login Profile"
echo "    - This allows the AWS Account Administrator User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-login-profile --user-name $new_user --password $password \\"
echo "                             --profile $profile --region $region"

if aws iam get-login-profile --user-name $new_user \
                             --profile $profile --region $region &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws iam create-login-profile --user-name $new_user --password $password \\"
        echo ">                              --profile $profile --region $region"
        aws iam create-login-profile --user-name $new_user --password $password \
                                     --profile $profile --region $region

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
echo "mkdir -p ~/.creds/$federation/$account/$new_user"
echo
echo "aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
echo "                          --profile $profile --region $region"
echo
echo "cat << EOF > ~/.creds/$federation/$account/$new_user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$federation/$account/$new_user/iamrc"

if [ -r ~/.creds/$federation/$account/$new_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/$new_user"
        mkdir -p ~/.creds/$federation/$account/$new_user
        pause

        echo "# aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
        echo ">                           --profile $profile --region $region"
        result=$(aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
                                           --profile $profile --region $region) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$federation/$account/$new_user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$federation/$account/$new_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/$new_user/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$federation/$account/$new_user/iamrc"
        chmod 0600 ~/.creds/$federation/$account/$new_user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$new_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$new_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($new_user) User Euca2ools Profile"
echo "    - This allows the AWS Account Administrator User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ ! -r ~/.euca/$federation.ini ]; then
    echo "cat << EOF > ~/.euca/$federation.ini"
    echo "; AWS"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF >> ~/.euca/$federation.ini"
echo "[user $federation-$account-$new_user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region=$federation-$account-$new_user@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-$new_user]" ~/.euca/$federation.ini; then
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
        if [ ! -r ~/.euca/$federation.ini ]; then
            echo "# cat << EOF > ~/.euca/$federation.ini"
            echo "> ; AWS"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "; AWS"  > ~/.euca/$federation.ini
            echo         >> ~/.euca/$federation.ini
            pause
        fi
        echo "# cat << EOF >> ~/.euca/$federation.ini"
        echo "> [user $federation-$account-$new_user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-$new_user]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"                  >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"              >> ~/.euca/$federation.ini
        echo                                         >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region=$federation-$account-$new_user@$region"
        euca-describe-availability-zones --region=$federation-$account-$new_user@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$federation/$account/$new_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$federation/$account/$new_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator ($new_user) User AWSCLI Profile"
echo "    - This allows the AWS Account Administrator User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ ! -r ~/.aws/config ]; then
    echo "cat << EOF > ~/.aws/config"
    echo "#"
    echo "# AWS Config file"
    echo "#"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF >> ~/.aws/config"
echo "[profile $account-$new_user]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
if [ ! -r ~/.aws/credentials ]; then
    echo "cat << EOF > ~/.aws/credentials"
    echo "#"
    echo "# AWS Credentials file"
    echo "#"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF >> ~/.aws/credentials"
echo "[$account-$new_user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $account-$new_user --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-$new_user]" ~/.aws/config; then
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
        if [ ! -r ~/.aws/config ]; then
            echo "# cat << EOF > ~/.aws/config"
            echo "> #"
            echo "> # AWS Config file"
            echo "> #"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "#"                  > ~/.aws/config
            echo "# AWS Config file" >> ~/.aws/config
            echo "#"                 >> ~/.aws/config
            echo                     >> ~/.aws/config
            echo "#"
        fi
        echo "# cat << EOF >> ~/.aws/config"
        echo "> [profile $account-$new_user]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-$new_user]" >> ~/.aws/config
        echo "region = $region"             >> ~/.aws/config
        echo "output = text"                >> ~/.aws/config
        echo                                >> ~/.aws/config
        pause

        if [ ! -r ~/.aws/credentials ]; then
            echo "# cat << EOF > ~/.aws/credentials"
            echo "> #"
            echo "> # AWS Credentials file"
            echo "> #"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "#"                       > ~/.aws/credentials
            echo "# AWS Credentials file" >> ~/.aws/credentials
            echo "#"                      >> ~/.aws/credentials
            echo                          >> ~/.aws/credentials
            echo "#"
        fi
        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$account-$new_user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-$new_user]"                >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $account-$new_user --region $region"
        aws ec2 describe-availability-zones --profile $account-$new_user --region $region

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
    echo "aws ec2 describe-key-pairs --profile $profile --region $region"
    echo
    echo "aws iam list-groups --profile $profile --region $region"
    echo
    echo "aws iam list-users --profile $profile --region $region"
    echo
    echo "aws iam get-group --group-name $group \\"
    echo "                  --profile $profile --region $region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-key-pairs --profile $profile --region $region"
        aws ec2 describe-key-pairs --profile $profile --region $region
        pause

        echo "# aws iam list-groups --profile $profile --region $region"
        aws iam list-groups --profile $profile --region $region
        pause

        echo "# aws iam list-users --profile $profile --region $region"
        aws iam list-users --profile $profile --region $region
        pause

        echo "# aws iam get-group --group-name $group \\"
        echo ">                   --profile $profile --region $region"
        aws iam get-group --group-name $group \
                          --profile $profile --region $region

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
    echo "AWS Account Administrator configured (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "AWS Account Administrator configured (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
