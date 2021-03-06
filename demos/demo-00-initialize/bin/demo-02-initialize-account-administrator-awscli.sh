#!/bin/bash
#
# This script initializes a Management Workstation and it's associated Eucalyptus Region with an
# additional User within the Administrators Group, including:
# - Creates the Administrators Group (named "Administrators")
# - Creates the Administrators Group Policy
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
# This is a variant of the demo-02-initialize-account-administrator.sh script which primarily uses
# the AWSCLI
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
# Then this script should be run by the Eucalyptus Administrator as many times as needed to
# create one or more IAM Users in the Demo Account Administrators Group.
#
# Then the demo-03-initialize-account-dependencies.sh script should be run by the Demo Account
# Administrator or an IAM User in the Administrators Group to create additional groups, users,
# roles and instance profiles in the Demo Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
policiesdir=${bindir%/*}/policies
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

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
account=${AWS_ACCOUNT_NAME:-demo}
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
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -a account   Eucalyptus Account (default: $account)"
    echo "  -u user      Eucalyptus User with permissions to create new Groups and Users (default $user)"
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


#  5. Prepare Eucalyptus Demo Account for Administrators

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrators ($group) Group"
echo "    - This Group is intended for Users who have complete control of all Resources in the Account"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-group --group-name $group \\"
echo "                     --profile $profile --region $region --output text"

if aws iam list-groups --profile $profile --region $region --output text | grep -s -q ":group/$group"; then
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
        echo ">                      --profile $profile --region $region --output text"
        aws iam create-group --group-name $group \
                             --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrators ($group) Group Policy"
echo "    - This Policy provides complete control of all Resources in the Account"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group}GroupPolicy.json"
cat $policiesdir/AdministratorsGroupPolicy.json
echo "EOF"
echo
echo "aws iam put-group-policy --group-name $group --policy-name ${group}Policy \\"
echo "                         --policy-document file://$tmpdir/$account/${group}GroupPolicy.json \\"
echo "                         --profile $profile --region $region --output text"

if aws iam list-group-policies --group-name $group \
                               --profile $profile --region $region --output text | grep -s -q "${group}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group}GroupPolicy.json"
        cat $policiesdir/AdministratorsGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/AdministratorsGroupPolicy.json $tmpdir/$account/${group}GroupPolicy.json
        pause

        echo "# aws iam put-group-policy --group-name $group --policy-name ${group}Policy \\"
        echo ">                          --policy-document file://$tmpdir/$account/${group}GroupPolicy.json \\"
        echo ">                          --profile $profile --region $region --output text"
        aws iam put-group-policy --group-name $group --policy-name ${group}Policy \
                                 --policy-document file://$tmpdir/$account/${group}GroupPolicy.json \
                                 --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator ($new_user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-user --user-name $new_user \\"
echo "                    --profile $profile --region $region --output text"

if aws iam list-users --profile $profile --region $region --output text | grep -s -q ":user/$new_user"; then
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
        echo ">                     --profile $profile --region $region --output text"
        aws iam create-user --user-name $new_user \
                            --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Administrator ($new_user) User to Administrators ($group) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam add-user-to-group --group-name $group --user-name $new_user \\"
echo "                          --profile $profile --region $region --output text"

if aws iam get-group --group-name $group \
                     --profile $profile --region $region --output text | grep -s -q ":user/$new_user"; then
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
        echo ">                           --profile $profile --region $region --output text"
        aws iam add-user-to-group --group-name $group --user-name $new_user \
                                  --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator ($new_user) User Login Profile"
echo "    - This allows the Demo Account Administrator User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws iam create-login-profile --user-name $new_user --password $password \\"
echo "                             --profile $profile --region $region --output text"

if aws iam get-login-profile --user-name $new_user \
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
        echo "# aws iam create-login-profile --user-name $new_user --password $password \\"
        echo ">                              --profile $profile --region $region --output text"
        aws iam create-login-profile --user-name $new_user --password $password \
                                     --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator ($new_user) User Access Key"
echo "    - This allows the Demo Account Administrator User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$region/$account/$new_user"
echo
echo "aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
echo "                          --profile $profile --region $region --output text"
echo
echo "cat << EOF > ~/.creds/$region/$account/$new_user/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$region/$account/$new_user/iamrc"

if [ -r ~/.creds/$region/$account/$new_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/$new_user"
        mkdir -p ~/.creds/$region/$account/$new_user
        pause

        echo "# aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \\"
        echo ">                           --profile $profile --region $region --output text"
        result=$(aws iam create-access-key --user-name $new_user --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
                                           --profile $profile --region $region --output text) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$region/$account/$new_user/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$region/$account/$new_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$region/$account/$new_user/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$region/$account/$new_user/iamrc"
        chmod 0600 ~/.creds/$region/$account/$new_user/iamrc

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$new_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$new_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator ($new_user) User Euca2ools Profile"
echo "    - This allows the Demo Account Administrator User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.euca/$region.ini"
echo "[user $region-$account-$new_user]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region $region-$account-$new_user@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "\[user $region-$account-$new_user]" ~/.euca/$region.ini; then
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
        echo "> [user $region-$account-$new_user]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-$new_user]" >> ~/.euca/$region.ini
        echo "key-id = $access_key"          >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"      >> ~/.euca/$region.ini
        echo                                 >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones --region $region-$account-$new_user@$region"
        euca-describe-availability-zones --region $region-$account-$new_user@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/$new_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/$new_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator ($new_user) User AWSCLI Profile"
echo "    - This allows the Demo Account Administrator User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-$account-$new_user]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$region-$account-$new_user]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $region-$account-$new_user --region $region --output text"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-$account-$new_user]" ~/.aws/config; then
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
        echo "> [profile $region-$account-$new_user]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-$account-$new_user]" >> ~/.aws/config
        echo "region = $region"                     >> ~/.aws/config
        echo "output = text"                        >> ~/.aws/config
        echo                                        >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$region-$account-$new_user]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-$account-$new_user]"        >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $region-$account-$new_user --region $region --output text"
        aws ec2 describe-availability-zones --profile $region-$account-$new_user --region $region --output text

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
    echo "aws iam list-groups --profile $profile --region $region --output text"
    echo
    echo "aws iam list-users --profile $profile --region $region --output text"
    echo
    echo "aws iam get-group --group-name $group \\"
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

        echo "# aws iam list-groups --profile $profile --region $region --output text"
        aws iam list-groups --profile $profile --region $region --output text
        pause

        echo "# aws iam list-users --profile $profile --region $region --output text"
        aws iam list-users --profile $profile --region $region --output text
        pause

        echo "# aws iam get-group --group-name $group \\"
        echo ">                   --profile $profile --region $region --output text"
        aws iam get-group --group-name $group \
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
    echo "Eucalyptus Demo Account Administrator configured (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Demo Account Administrator configured (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
