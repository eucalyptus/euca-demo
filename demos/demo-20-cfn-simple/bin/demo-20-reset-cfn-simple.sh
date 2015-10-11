#/bin/bash
#
# This script resets a Eucalyptus CloudFormation demo which uses the
# Simple.template to create a security group and an instance.
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

image_file=CentOS-6-x86_64-GenericCloud.qcow2.xz

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

create_attempts=6
create_default=20
login_attempts=6
login_default=20
delete_attempts=6
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
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Delete the Stack"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-delete-stack --region=$user_region SimpleDemoStack"

if ! euform-describe-stacks --region=$user_region SimpleDemoStack 2> /dev/null | grep -s -q "^STACK"; then
    echo
    tput rev
    echo "Already Deleted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euform-delete-stack --region=$user_region SimpleDemoStack"
        euform-delete-stack --region=$user_region SimpleDemoStack

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Monitor Stack deletion"
echo "    - NOTE: This can take about 60 - 80 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks --region=$user_region"
echo
echo "euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5"

if ! euform-describe-stacks --region=$user_region SimpleDemoStack 2> /dev/null | grep -s -q "^STACK"; then
    echo
    tput rev
    echo "Already Complete!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euform-describe-stacks --region=$user_region"
        euform-describe-stacks --region=$user_region
        pause

        attempt=0
        ((seconds=$delete_default * $speed / 100))
        while ((attempt++ <= delete_attempts)); do
            echo
            echo "# euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5"
            euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5

            if ! euform-describe-stacks --region=$user_region SimpleDemoStack 2> /dev/null | grep -s -q "^STACK"; then
                break
            else
                echo
                echo -n "Not finished ($RC). Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done

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
echo "                                                  --region=$user_region | grep \"^INSTANCE\" | cut -f2)"
echo
echo "for instance_id in \$terminated_instance_ids; do"
echo "    euca-terminate-instances --region=$user_region \$instance_id &> /dev/null"
echo "done"

terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                  --region=$user_region | grep "^INSTANCE" | cut -f2)
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
        echo ">                                                   --region=$user_region | grep \"^INSTANCE\" | cut -f2)"
        terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                          --region=$user_region | grep "^INSTANCE" | cut -f2)
        pause

        echo "# for instance_id in \$terminated_instance_ids; do"
        echo ">     euca-terminate-instances --region=$user_region \$instance_id &> /dev/null"
        echo "> done"
        for instance_id in $terminated_instance_ids; do
            euca-terminate-instances --region=$user_region $instance_id &> /dev/null
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
    echo "euca-describe-groups --region=$user_region"
    echo
    echo "euca-describe-instances --region=$user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups --region=$user_region"
        euca-describe-groups --region=$user_region
        pause

        echo "# euca-describe-instances --region=$user_region"
        euca-describe-instances --region=$user_region

        next
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List remaining CloudFormation Stacks"
    echo "    - Confirm we are back to our initial set"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euform-describe-stacks --region=$user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euform-describe-stacks --region=$user_region"
        euform-describe-stacks --region=$user_region

        next
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CloudFormation Simple demo reset complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CloudFormation Simple demo reset complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
