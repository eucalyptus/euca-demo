#/bin/bash
#
# This script resets a Eucalyptus CloudFormation demo which uses the
# Simple.template to create a security group and an instance.
#
# This script was originally designed to run on a combined CLC+UFS+MC host,
# as installed by FastStart or the Cloud Administrator Course. To run this
# on an arbitrary management workstation, you will need to move the demo
# account admin user's credentials zip file to
#   ~/.creds/<region>/<demo_account_name>/admin.zip
# then expand it's contents into the
#   ~/.creds/<region>/<demo_account_name>/admin/ directory
#
# Before running this (or any other demo script in the euca-demo project),
# you should run the following scripts to initialize the demo environment
# to a baseline of known resources which are assumed to exist.
# - Run demo-00-initialize.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-01-initialize-account.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-02-initialize-account-dependencies.sh on the CLC as the Demo Account Administrator.
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
account=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to use in demo (default: $account)"
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

while getopts Isfa:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc ]; then
    echo "-a $account invalid: Could not find $AWS_DEFAULT_REGION Demo Account Administrator credentials!"
    echo "   Expected to find: ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
    exit 21
fi


#  5. Reset Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
if [ $account = eucalyptus ]; then
    echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
else
    echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator credentials"
fi
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"

next

echo
echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc
pause

echo "# source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc

next


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
echo "euform-delete-stack SimpleDemoStack"

run 50

if [ $choice = y ]; then
    echo
    echo "# euform-delete-stack SimpleDemoStack"
    euform-delete-stack SimpleDemoStack
   
    next
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
echo "euform-describe-stacks"
echo
echo "euform-describe-stack-events SimpleDemoStack | head -10"

run 50

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    attempt=0
    ((seconds=$delete_default * $speed / 100))
    while ((attempt++ <= delete_attempts)); do
        echo
        echo "# euform-describe-stack-events SimpleDemoStack | head -10"
        euform-describe-stack-events SimpleDemoStack | head -10

        status=$(euform-describe-stacks SimpleDemoStack | grep "^STACK" | cut -f3)
        if [ -z "$status" ]; then
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
echo "terminated_instance_ids=$(euca-describe-instances --filter \"instance-state-name=terminated\" | grep \"^INSTANCE\" | cut -f2)"
terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" | grep "^INSTANCE" | cut -f2)
echo
echo "for instance_id in \$terminated_instance_ids; do"
echo "    euca-terminate-instances \$instance_id &> /dev/null"
echo "done"
for instance_id in $terminated_instance_ids; do
    euca-terminate-instances $instance_id &> /dev/null
done

run 50

if [ $choice = y ]; then
    echo
    echo "# terminated_instance_ids=$(euca-describe-instances --filter \"instance-state-name=terminated\" | grep \"^INSTANCE\" | cut -f2)"
    terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" | grep "^INSTANCE" | cut -f2)
    pause

    echo "# for instance_id in \$terminated_instance_ids; do"
    echo ">     euca-terminate-instances \$instance_id &> /dev/null"
    echo "> done"
    for instance_id in $terminated_instance_ids; do
        euca-terminate-instances $instance_id &> /dev/null
    done

    next
fi


((++step))
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
echo "euca-describe-images"
echo
echo "euca-describe-keypairs"
echo
echo "euca-describe-groups"
echo
echo "euca-describe-instances"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euca-describe-groups"
    euca-describe-groups
    pause

    echo "# euca-describe-instances"
    euca-describe-instances

    next
fi


((++step))
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
echo "euform-describe-stacks"

run 50

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks

    next
fi


end=$(date +%s)

echo
echo "Eucalyptus CloudFormation Simple.template demo reset complete (time: $(date -u -d @$((end-start)) +"%T"))"
