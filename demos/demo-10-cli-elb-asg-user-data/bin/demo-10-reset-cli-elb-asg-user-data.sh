#/bin/bash
#
# This script resets a Eucalyptus CLI demo which creates a SecurityGroup,
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
user=${AWS_USER_NAME:-demo}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v]"
    echo "              [-r region ] [-a account] [-u user]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -v          verbose"
    echo "  -r region   Region (default: $region)"
    echo "  -a account  Account (default: $account)"
    echo "  -u user     User (default: $user)"
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


#  5. Reset Demo

start=$(date +%s)


((++step))
instance_ids="$(euscale-describe-auto-scaling-groups --region $user_region DemoASG | grep "^INSTANCE" | cut -f2)"

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the AutoScalingGroup"
echo "    - We must first reduce sizes to zero"
echo "    - Pause a bit longer for changes to be acted upon"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-update-auto-scaling-group --min-size 0 --max-size 0 --desired-capacity 0 --region $user_region DemoASG"
echo
echo "euscale-delete-auto-scaling-group --region $user_region DemoASG"

if ! euscale-describe-auto-scaling-groups --region $user_region DemoASG 2> /dev/null | grep -s -q "^AUTO-SCALING-GROUP"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euscale-update-auto-scaling-group --min-size 0 --max-size 0 --desired-capacity 0 --region $user_region DemoASG"
        euscale-update-auto-scaling-group --min-size 0 --max-size 0 --desired-capacity 0 --region $user_region DemoASG

        attempt=0
        ((seconds=$delete_default * $speed / 100))
        while ((attempt++ <= delete_attempts)); do
            echo
            echo "# euca-describe-instances --region $user_region $instance_ids"
            euca-describe-instances --region $user_region $instance_ids | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out

            if [ $(grep -c "terminated" $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out) -ge $instances ]; then
                break
            else
                echo
                echo -n "Instances not yet \"terminated\". Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done

        echo "# euscale-delete-auto-scaling-group --region $user_region DemoASG"
        euscale-delete-auto-scaling-groupi --region $user_region DemoASG
        pause

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the Alarms"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euwatch-delete-alarms --region $user_region DemoAddNodesAlarm"
echo "euwatch-delete-alarms --region $user_region DemoDelNodesAlarm"

# There's a bug here where euwatch is not reading the config file properly, need to lookup and add the AWS_CLOUDWATCH_URL environment variable
aws_cloudwatch_url=$(sed -n -e 's/^monitoring-url //p' /etc/euca2ools/conf.d/${user_region#*@}.ini)
#if ! euwatch-describe-alarms --region $user_region DemoAddNodesAlarm 2> /dev/null | grep -s -q "^ALARM"; then
if ! AWS_CLOUDWATCH_URL=$aws_cloudwatch_url euwatch-describe-alarms --region $user_region DemoAddNodesAlarm 2> /dev/null | grep -s -q "^ALARM"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euwatch-delete-alarms --region $user_region DemoAddNodesAlarm"
        AWS_CLOUDWATCH_URL=$aws_cloudwatch_url euwatch-delete-alarms --region $user_region DemoAddNodesAlarm
        echo "# euwatch-delete-alarms --region $user_region DemoDelNodesAlarm"
        AWS_CLOUDWATCH_URL=$aws_cloudwatch_url euwatch-delete-alarms --region $user_region DemoDelNodesAlarm

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the LaunchConfigurations"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-delete-launch-config --region $user_region DemoLC"
echo "euscale-delete-launch-config --region $user_region DemoLC-2"

if ! euscale-describe-launch-configs --region $user_region DemoLC 2> /dev/null | grep -s -q "^LAUNCH-CONFIG"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euscale-delete-launch-config --region $user_region DemoLC"
        euscale-delete-launch-config --region $user_region DemoLC
        echo "# euscale-delete-launch-config --region $user_region DemoLC-2"
        euscale-delete-launch-config --region $user_region DemoLC-2

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the ElasticLoadBalancer"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "eulb-delete-lb --region $user_region DemoELB"

if ! eulb-describe-lbs --region $user_region DemoELB 2> /dev/null | grep -s -q "^LOAD_BALANCER"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# eulb-delete-lb --region $user_region DemoELB"
        eulb-delete-lb --region $user_region DemoELB

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the Security Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-delete-group --region $user_region DemoSG"

if ! euca-describe-groups --region $user_region DemoSG 2> /dev/null | grep -s -q "^GROUP"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-delete-group --region $user_region DemoSG"
        euca-delete-group --region $user_region DemoSG

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Clear terminated Instances"
echo "    - By default, Instances which have been terminated will remain in describe statement results"
echo "      in a terminated state for an indeterminate period of time."
echo "    - We want to re-terminate such instances, causing them to immediately disappear from results,"
echo "      prior to re-running any demos"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "terminated_instance_ids=\$(euca-describe-instances --filter \"instance-state-name=terminated\" \\"
echo "                                                  --region $user_region | grep \"^INSTANCE\" | cut -f2)"
echo
echo "for instance_id in \$terminated_instance_ids; do"
echo "    euca-terminate-instances --region $user_region \$instance_id &> /dev/null"
echo "done"

terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                  --region $user_region | grep "^INSTANCE" | cut -f2)
if [ -z "$terminated_instance_ids" ]; then
    echo
    tput rev
    echo "Already Cleared!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# terminated_instance_ids=\$(euca-describe-instances --filter \"instance-state-name=terminated\" \\"
        echo ">                                                   --region $user_region | grep \"^INSTANCE\" | cut -f2)"
        terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                          --region $user_region | grep "^INSTANCE" | cut -f2)
        pause

        echo "# for instance_id in \$terminated_instance_ids; do"
        echo ">     euca-terminate-instances --region $user_region \$instance_id &> /dev/null"
        echo "> done"
        for instance_id in $terminated_instance_ids; do
            euca-terminate-instances --region $user_region $instance_id &> /dev/null
        done

        next
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List remaining Resources"
    echo "    - Confirm we are back to our initial set"
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
        euwatch-describe-alarms --region $user_region

        next
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo reset complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo reset complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
