#!/bin/bash
#
# This script initializes a Management Workstation for Demos which also use AWS, including:
# - Configures Euca2ools for the AWS Account Administrator
# - Configures AWSCLI for the AWS Account Administrator
#
# The demo-00-initialize-aws.sh script should be run by the AWS Account Administrator once prior
# to running this script.
#
# This script should be run by the AWS Account Administrator next, to move the Credentials obtained
# during manual AWS Account creation into the Euca2ools and AWSCLI configuration file in a
# standard way.
#
# Then the demo-02-initialize-aws-account-administrator.sh script should be run by the AWS Account
# Administrator as many times as needed to create one or more AWS IAM Users in the Account
# Administrators Group.
#
# Then the demo-03-initialize-aws-account-dependencies.sh script should be run once by an AWS
# Account Administrator or an AWS User in the Administrators Group to create additional groups,
# users, roles and instance profiles in the AWS Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

federation=aws

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
account=euca
access_key=${AWS_ACCESS_KEY}
secret_key=${AWS_SECRET_KEY}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ] [-a account] [-A access_key] [-S secret_key]"
    echo "  -I             non-interactive"
    echo "  -s             slower: increase pauses by 25%"
    echo "  -f             faster: reduce pauses by 25%"
    echo "  -r region      AWS Region (default: $region)"
    echo "  -a account     AWS Account name to use in demos (default: $account)"
    echo "  -A access_key  AWS Account-level access-key (default: $access_key)"
    echo "  -S secret_key  AWS Account-level secret-key (default: $secret_key)"
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

while getopts Isfr:a:A:S:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    A)  access_key="$OPTARG";;
    S)  secret_key="$OPTARG";;
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

if [ -z $access_key ]; then
    echo "-A access_key missing!"
    echo "Could not automatically determine access_key, and it was not specified as a parameter"
    exit 14
fi

if [ -z $secret_key ]; then
    echo "-S secret_key missing!"
    echo "Could not automatically determine secret_key, and it was not specified as a parameter"
    exit 16
fi


#  5. Prepare AWS for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator Credentials"
echo "    - This allows the AWS Account Administrator to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$federation/$account/admin"
echo
echo "cat << EOF >> ~/.creds/$federation/$account/admin/iamrc"
echo "AWSAccessKeyId=$access_key"
echo "AWSSecretKey=$secret_key"
echo "EOF"

if [ -r ~/.creds/$federation/$account/admin/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$federation/$account/admin"
        mkdir -p ~/.creds/$federation/$account/admin
        echo "#"
        echo "# cat << EOF >> ~/.creds/$federation/$account/admin/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key" >> ~/.creds/$federation/$account/admin/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$federation/$account/admin/iamrc

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator Euca2ools Profile"
echo "    - This allows the AWS Account Administrator to run API commands via Euca2ools"
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
echo "[user $federation-$account-admin]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones --region $federation-$account-admin@$region"

if [ -r ~/.euca/$federation.ini ] && grep -s -q "\[user $federation-$account-admin]" ~/.euca/$federation.ini; then
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
            echo "; AWS"                > ~/.euca/$federation.ini
            echo                       >> ~/.euca/$federation.ini
            pause
        fi
        echo "# cat << EOF >> ~/.euca/$federation.ini"
        echo "> [user $federation-$account-admin]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $federation-$account-admin]" >> ~/.euca/$federation.ini
        echo "key-id = $access_key"              >> ~/.euca/$federation.ini
        echo "secret-key = $secret_key"          >> ~/.euca/$federation.ini
        echo                                     >> ~/.euca/$federation.ini
        pause

        echo "# euca-describe-availability-zones --region $federation-$account-admin@$region"
        euca-describe-availability-zones --region $federation-$account-admin@$region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create AWS ($account) Account Administrator AWSCLI Profile"
echo "    - This allows the AWS Account Administrator to run AWSCLI commands"
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
echo "[profile $account-admin]"
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
echo "[$account-admin]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $account-admin --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $account-admin]" ~/.aws/config; then
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
        echo "> [profile $account-admin]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $account-admin]" >> ~/.aws/config
        echo "region = $region"         >> ~/.aws/config
        echo "output = text"            >> ~/.aws/config
        echo                            >> ~/.aws/config
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
        echo "> [$account-admin]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$account-admin]"                     >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"      >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key"  >> ~/.aws/credentials
        echo                                        >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $account-admin --region $region"
        aws ec2 describe-availability-zones --profile $account-admin --region $region

        next
    fi
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
echo "AWS Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
unset a; [ $account = hp ] || a=" -a $account"
echo "Please run \"demo-02-initialize-aws-account-administrator.sh$a -u <username>\" to create at least one User-level Administrator, then"
echo "Please run \"demo-03-initialize-aws-account-dependencies.sh$a\" to complete AWS Account initialization"
