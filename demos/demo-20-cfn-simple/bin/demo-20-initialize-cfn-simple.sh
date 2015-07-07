#/bin/bash
#
# This script initializes a Eucalyptus CloudFormation demo which uses the
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

image_name=CentOS-6-x86_64-GenericCloud

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

if ! rpm -q --quiet w3m; then
    echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
    exit 98
fi


#  5. Initialize Demo

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
demo_initialized=y
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
echo "euca-describe-images | grep -P \"^IMAGE\\temi-.*\\timages/$image_name.raw.manifest.xml\\t\""
echo
echo "euca-describe-keypairs | grep -P \"^KEYPAIR\\tdemo\\t\""

next

echo
echo "euca-describe-images | grep -P \"^IMAGE\\temi-.*\\timages/$image_name.raw.manifest.xml\\t\""
euca-describe-images | grep -P "^IMAGE\temi-.*\timages/$image_name.raw.manifest.xml\t" || demo_initialized=n
pause

echo "euca-describe-keypairs | grep -P \"^KEYPAIR\\tdemo\\t\""
euca-describe-keypairs | grep -P "^KEYPAIR\tdemo\t" || demo_initialized=n

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run the demo initialization scripts referencing this demo account:"
    echo "- demo-00-initialize.sh"
    echo "- demo-01-initialize-account.sh -a $account"
    echo "- demo-02-initialize-account-dependencies.sh -a $account"
    exit 99
fi

next


clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List initial Resources"
echo "    - So we can compare with what this demo creates"
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
echo "$(printf '%2d' $step). List initial CloudFormation Stacks"
echo "    - So we can compare with what this demo creates"
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
echo "Eucalyptus CloudFormation Simple.template demo initialization complete (time: $(date -u -d @$((end-start)) +"%T"))"
