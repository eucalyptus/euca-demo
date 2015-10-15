#/bin/bash
#
# This script initializes a Eucalyptus CLI demo which creates a SecurityGroup,
# ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScaleUp and ScaleDown 
# ScalingPolicies and associated CloudWatch Alarms, and Instances associated with
# the LaunchConfiguration which use a user-data script for configuration.
#
# This script was originally designed to run on a combined CLC+UFS+MC host,
# as installed by FastStart or the Cloud Administrator Course. To run this
# on an arbitrary management workstation, you will need to move the appropriate
# credentials to your management host.
#
# Before running this (or any other demo script in the euca-demo project),
# you should run the following scripts to initialize the demo environment
# to a baseline of known resources which are assumed to exist.
# - Run demo-00-initialize.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-01-initialize-account.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-02-initialize-account-administrator.sh on the CLC as the Demo Account Administrator.
# - Run demo-03-initialize-account-dependencies.sh on the CLC as the Demo Account Administrator.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

image_name=CentOS-6-x86_64-GenericCloud

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

create_attempts=12
create_default=20
login_attempts=12
login_default=20
replace_attempts=12
replace_default=20
delete_attempts=12
delete_default=20

interactive=1
speed=100
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-admin}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v]"
    echo "                [-r region ] [-a account] [-u user]"
    echo "  -I            non-interactive"
    echo "  -s            slower: increase pauses by 25%"
    echo "  -f            faster: reduce pauses by 25%"
    echo "  -v            verbose"
    echo "  -r region     Region (default: $region)"
    echo "  -a account    Account (default: $account)"
    echo "  -u user       User (default: $user)"
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

while getopts Isfvr:a:u:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
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

user_region=$region-$account-$user@$region

if ! grep -s -q "\[user $region-$account-$user]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Demo ($account) Account Demo ($user) User Euca2ools user!"
    echo "Expected to find: [user $region-$account-$user] in ~/.euca/$region.ini"
    exit 50
fi

if [ ! $(uname) = "Darwin" ]; then
    if ! rpm -q --quiet w3m; then
        echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
        exit 98
    fi
fi

# See bug: TOOLS-595 - until fixed, we need to lookup and add the AWS_CLOUDWATCH_URL environment
# variable to all euwatch-* commands. This statement looks up and sets an internal variable with
# this value, then for all euwatch-* commands below, we comment out the normal statement, and
# instead use a variant which sets the AWS_CLOUDWATCH_URL environment variable before running the
# command. Once this bug is fixed, we will remove this logic.
aws_cloudwatch_url=$(sed -n -e 's/^monitoring-url \(http.*\)\/services\/CloudWatch.*$/\1/p' /etc/euca2ools/conf.d/${user_region#*@}.ini)

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Initialize Demo

start=$(date +%s)

((++step))
demo_initialized=y

if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm existence of Demo depencencies"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
    echo "                     --region $user_region | cut -f1,2,3"
    echo
    echo "euca-describe-keypairs --filter \"key-name=demo\" \\"
    echo "                       --region $user_region"

    next

    echo
    echo "# euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
    echo ">                      --region $user_region | cut -f1,2,3"
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region $user_region | cut -f1,2,3 | grep "$image_name" || euca_demo_initialized=n
    pause

    echo "# euca-describe-keypairs --filter \"key-name=demo\"\\"
    echo ">                      --region $user_region"
    euca-describe-keypairs --filter "key-name=demo" \
                           --region $user_region | grep "demo" || euca_demo_initialized=n

    next

else
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region $user_region | cut -f1,2,3 | grep -s -q "$image_name" || euca_demo_initialized=n
    euca-describe-keypairs --filter "key-name=demo" \
                           --region $user_region | grep -s -q "demo" || euca_demo_initialized=n
fi

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run the demo initialization scripts referencing this demo account:"
    echo "- demo-00-initialize.sh -r $region"
    echo "- demo-01-initialize-account.sh -r $region -a $account"
    echo "- demo-03-initialize-account-dependencies.sh -r $region -a $account"
    exit 99
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List existing Resources"
    echo "    - So we can compare with what this demo creates"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo 
    echo "euca-describe-groups --region $user_region"
    echo
    echo "eulb-describe-lbs --region $user_region"
    echo
    echo "euca-describe-instances --region $user_region"
    echo
    echo "euscale-describe-launch-configs --region $user_region"
    echo
    echo "euscale-describe-auto-scaling-groups --region $user_region"
    echo
    echo "euscale-describe-policies --region $user_region"
    echo
    echo "euwatch-describe-alarms --region $user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups --region $user_region"
        euca-describe-groups --region $user_region
        pause

        echo "# eulb-describe-lbs --region $user_region"
        eulb-describe-lbs --region $user_region
        pause

        echo "# euca-describe-instances --region $user_region"
        euca-describe-instances --region $user_region
        pause

        echo "# euscale-describe-launch-configs --region $user_region"
        euscale-describe-launch-configs --region $user_region
        pause

        echo "# euscale-describe-auto-scaling-groups --region $user_region"
        euscale-describe-auto-scaling-groups --region $user_region
        pause

        echo "# euscale-describe-policies --region $user_region"
        euscale-describe-policies --region $user_region
        pause

        echo "# euwatch-describe-alarms --region $user_region"
        #euwatch-describe-alarms --region $user_region
        AWS_CLOUDWATCH_URL=$aws_cloudwatch_url euwatch-describe-alarms --region $user_region
    
        next
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo initialization complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo initialization complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
