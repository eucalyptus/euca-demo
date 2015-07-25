#!/bin/bash
#
# This script initializes a Management Workstation for Demos which also use AWS, including:
# - Initializes Euca2ools with the AWS Region Endpoints
#
# This script should be run by the AWS Account Administrator once per AWS region, after Eucalyptus
# has been installed, to prepare for demos which show iteroperability with AWS.
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

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
domain=amazonaws


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -r region  AWS Region (default: $region)"
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

while getopts Isfr:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
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


#  5. Prepare AWS for Demos

start=$(date +%s)

((++step))
# AWS Endpoints are well known
autoscaling_url=https://autoscaling.$region.$domain/
cloudformation_url=https://cloudformation.$region.$domain/
ec2_url=https://ec2.$region.$domain/
elasticloadbalancing_url=https://elasticloadbalancing.$region.$domain/
iam_url=https://iam.$domain/
monitoring_url=https://monitoring.$region.$domain/
s3_url=https://s3.$domain/
sts_url=https://sts.$domain/
swf_url=https://swf.$region.$domain/

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Initialize Euca2ools with AWS Region Endpoints"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ ! -r ~/.euca/euca2ools.ini ]; then
    echo "cat << EOF > ~/.euca/euca2ools.ini"
    echo "# Euca2ools Configuration file"
    echo
    echo "[global]"
    echo "region = $region"
    echo 
    echo "EOF"
    echo
fi
echo "cat << EOF >> ~/.euca/euca2ools.ini"
echo "[region $region]"
echo "autoscaling-url = $autoscaling_url"
echo "cloudformation-url = $cloudformation_url"
echo "ec2-url = $ec2_url"
echo "elasticloadbalancing-url = $elasticloadbalancing_url"
echo "iam-url = $iam_url"
echo "monitoring-url $monitoring_url"
echo "s3-url = $s3_url"
echo "sts-url = $sts_url"
echo "swf-url = $swf_url"
echo
echo "EOF"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "\[region $region]" ~/.euca/euca2ools.ini; then
    echo
    tput rev
    echo "Already Initialized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        if [ ! -r ~/.euca/euca2ools.ini ]; then
            echo "# cat << EOF > ~/.euca/euca2ools.ini"
            echo "> # Euca2ools Configuration file"
            echo ">"
            echo "> [global]"
            echo "> region = $region"
            echo ">"
            echo "> EOF"
            echo
            # Use echo instead of cat << EOF to better show indentation
            echo "# Euca2ools Configuration file"  > ~/.euca/euca2ools.ini
            echo                                  >> ~/.euca/euca2ools.ini
            echo "[global]"                       >> ~/.euca/euca2ools.ini
            echo "region = $region"               >> ~/.euca/euca2ools.ini
            echo                                  >> ~/.euca/euca2ools.ini
        fi
        # Save, then delete any users
        sed -n -e '/^\[user/,$p' ~/.euca/euca2ools.ini > ~/.euca/euca2ools-users.ini
        sed -e '/^\[user/,$d' ~/.euca/euca2ools.ini
        # Append the new region
        echo "cat << EOF >> ~/.euca/euca2ools.ini"
        echo "[region $region]"
        echo "autoscaling-url = $autoscaling_url"
        echo "cloudformation-url = $cloudformation_url"
        echo "ec2-url = $ec2_url"
        echo "elasticloadbalancing-url = $elasticloadbalancing_url"
        echo "iam-url = $iam_url"
        echo "monitoring-url $monitoring_url"
        echo "s3-url = $s3_url"
        echo "sts-url = $sts_url"
        echo "swf-url = $swf_url"
        echo
        echo "EOF"
        # Append the saved users, then delete the temp file
        cat ~/.euca/euca2ools-users.ini >> ~/.euca/euca2ools.ini
        rm -f ~/.euca/euca2ools-users.ini
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
echo "cat ~/.euca/euca2ools.ini"
 
run 50
 
if [ $choice = y ]; then
    echo
    echo "# cat ~/.euca/euca2ools.ini"
    cat ~/.euca/euca2ools.ini
 
    next 200
fi
 
 
end=$(date +%s)

echo
echo "AWS initialized for demos (time: $(date -u -d @$((end-start)) +"%T"))"
echo "Please run \"demo-01-initialize-aws-account.sh\" to continue with demo initialization"
