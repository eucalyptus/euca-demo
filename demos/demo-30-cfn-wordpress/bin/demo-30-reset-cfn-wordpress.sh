#/bin/bash
#
# This script resets a Eucalyptus CloudFormation demo which uses the
# WordPress_Single_Instance_Eucalyptus.template to create WordPress-based
# blog. This demo then shows how this application can be migrated between
# AWS and Eucalyptus.
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

federation=aws

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
mode=e
euca_region=${AWS_DEFAULT_REGION#*@}
euca_account=${AWS_ACCOUNT_NAME:-demo}
euca_user=${AWS_USER_NAME:-admin}
aws_region=us-east-1
aws_account=euca
aws_user=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-m mode]"
    echo "                   [-r euca_region ] [-a euca_account] [-u euca_user]"
    echo "                   [-R aws_region] [-A aws_account] [-U aws_user]"
    echo "  -I               non-interactive"
    echo "  -s               slower: increase pauses by 25%"
    echo "  -f               faster: reduce pauses by 25%"
    echo "  -v               verbose"
    echo "  -m mode          mode: Reset a=AWS, e=Eucalyptus or b=Both (default: $mode)"
    echo "  -r euca_region   Eucalyptus Region (default: $euca_region)"
    echo "  -a euca_account  Eucalyptus Account (default: $euca_account)"
    echo "  -u euca_user     Eucalyptus User (default: $euca_user)"
    echo "  -R aws_region    AWS Region (default: $aws_region)"
    echo "  -A aws_account   AWS Account (default: $aws_account)"
    echo "  -U aws_user      AWS Account (default: $aws_user)"
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

while getopts Isfvm:r:a:u:R:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    m)  mode="$OPTARG";;
    r)  euca_region="$OPTARG";;
    a)  euca_account="$OPTARG";;
    u)  euca_user="$OPTARG";;
    R)  aws_region="$OPTARG";;
    A)  aws_account="$OPTARG";;
    U)  aws_user="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $mode ]; then
    echo "-m mode missing!"
    echo "Could not automatically determine mode, and it was not specified as a parameter"
    exit 8
else
    case $mode in
      a|e|b) ;;
      *)
        echo "-m $mode invalid: Valid modes are a=AWS (only), e=Eucalyptus (only), b=Both"
        exit 9;;
    esac
fi

if [ -z $euca_region ]; then
    echo "-r euca_region missing!"
    echo "Could not automatically determine Eucalyptus region, and it was not specified as a parameter"
    exit 10
else
    case $euca_region in
      us-east-1|us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $euca_region invalid: Please specify a Eucalyptus region"
        exit 11;;
    esac
fi

if [ -z $euca_account ]; then
    echo "-a euca_account missing!"
    echo "Could not automatically determine Eucalyptus account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $euca_user ]; then
    echo "-u euca_user missing!"
    echo "Could not automatically determine Eucalyptus user, and it was not specified as a parameter"
    exit 14
fi

if [ -z $aws_region ]; then
    echo "-R aws_region missing!"
    echo "Could not automatically determine AWS region, and it was not specified as a parameter"
    exit 20
else
    case $aws_region in
      us-east-1)
        aws_s3_domain=s3.amazonaws.com;;
      us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        aws_s3_domain=s3-$aws_region.amazonaws.com;;
    *)
        echo "-R $aws_region invalid: Please specify an AWS region"
        exit 21;;
    esac
fi

if [ -z $aws_account ]; then
    echo "-A aws_account missing!"
    echo "Could not automatically determine AWS account, and it was not specified as a parameter"
    exit 22
fi

if [ -z $aws_user ]; then
    echo "-U aws_user missing!"
    echo "Could not automatically determine AWS user, and it was not specified as a parameter"
    exit 24
fi

euca_user_region=$euca_region-$euca_account-$euca_user@$euca_region

if ! grep -s -q "\[user $euca_region-$euca_account-$euca_user]" ~/.euca/$euca_region.ini; then
    echo "Could not find Eucalyptus ($euca_region) Region Demo ($euca_account) Account Demo ($euca_user) User Euca2ools user!"
    echo "Expected to find: [user $euca_region-$euca_account-$euca_user] in ~/.euca/$euca_region.ini"
    exit 50
fi

euca_profile=$euca_region-$euca_account-$euca_user

if ! grep -s -q "\[profile $euca_profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($euca_region) Region Demo ($euca_account) Account Demo ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $euca_profile] in ~/.aws/config"
    exit 51
fi

aws_user_region=$federation-$aws_account-$aws_user@$aws_region

if ! grep -s -q "\[user $federation-$aws_account-$aws_user]" ~/.euca/$federation.ini; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User Euca2ools user!"
    echo "Expected to find: [user $federation-$aws_account-$aws_user] in ~/.euca/$federation.ini"
    exit 52
fi

aws_profile=$aws_account-$aws_user

if ! grep -s -q "\[profile $aws_profile]" ~/.aws/config; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User AWSCLI profile!"
    echo "Expected to find: [profile $aws_profile] in ~/.aws/config"
    exit 53
fi


#  5. Reset Demo

start=$(date +%s)

((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Delete the AWS Stack"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euform-delete-stack --region $aws_user_region WordPressDemoStack"

    if ! euform-describe-stacks --region $aws_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
        echo
        tput rev
        echo "Already Deleted!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-delete-stack WordPressDemoStack --region $aws_user_region"
            euform-delete-stack WordPressDemoStack --region $aws_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Monitor AWS Stack deletion"
    echo "    - NOTE: This can take about 300 - 400 seconds"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euform-describe-stacks --region $aws_user_region"
    echo
    echo "euform-describe-stack-events --region $aws_user_region WordPressDemoStack | head -5"

    if ! euform-describe-stacks --region $aws_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
        echo
        tput rev
        echo "Already Complete!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-describe-stacks --region $aws_user_region"
            euform-describe-stacks --region $aws_user_region
            pause

            attempt=0
            ((seconds=$delete_default * $speed / 100))
            while ((attempt++ <= delete_attempts)); do
                echo
                echo "# euform-describe-stack-events --region $aws_user_region WordPressDemoStack | head -5"
                euform-describe-stack-events --region $aws_user_region WordPressDemoStack | head -5

                if ! euform-describe-stacks --region $aws_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
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
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List remaining AWS Resources"
        echo "    - Confirm we are back to our initial set"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-groups --region $aws_user_region"
        echo
        echo "euca-describe-instances --region $aws_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euca-describe-groups --region $aws_user_region"
            euca-describe-groups --region $aws_user_region
            pause

            echo "# euca-describe-instances --region $aws_user_region"
            euca-describe-instances --region $aws_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List remaining AWS CloudFormation Stacks"
        echo "    - Confirm we are back to our initial set"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euform-describe-stacks --region $aws_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-describe-stacks --region $aws_user_region"
            euform-describe-stacks --region $aws_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Delete the Eucalyptus Stack"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euform-delete-stack --region $euca_user_region WordPressDemoStack"
 
    if ! euform-describe-stacks --region $euca_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
        echo
        tput rev
        echo "Already Deleted!"
        tput sgr0
 
        next 50
 
    else
        run 50
 
        if [ $choice = y ]; then
            euform-delete-stack WordPressDemoStack --region $euca_user_region
 
            next
        fi
    fi
fi
 
 
((++step))
if [ $mode = e -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Monitor Eucalyptus Stack deletion"
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euform-describe-stacks --region $euca_user_region"
    echo
    echo "euform-describe-stack-events --region $euca_user_region WordPressDemoStack | head -5"
 
    if ! euform-describe-stacks --region $euca_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
        echo
        tput rev
        echo "Already Complete!"
        tput sgr0
 
        next 50
 
    else
        run 50
            euform-describe-stacks --region $euca_user_region
            pause
 
            attempt=0
            ((seconds=$delete_default * $speed / 100))
            while ((attempt++ <= delete_attempts)); do
                echo
                echo "# euform-describe-stack-events --region $euca_user_region WordPressDemoStack | head -5"
                euform-describe-stack-events --region $euca_user_region WordPressDemoStack | head -5
 
                if ! euform-describe-stacks --region $euca_user_region WordPressDemoStack 2> /dev/null | grep -s -q "^STACK"; then
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
fi
 
 
((++step))
if [ $mode = e ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Clear terminated Eucalyptus Instances"
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
    echo "                                                  --region=$euca_user_region | grep \"^INSTANCE\" | cut -f2)"
    echo
    echo "for instance_id in \$terminated_instance_ids; do"
    echo "    euca-terminate-instances --region $euca_user_region \$instance_id &> /dev/null"
    echo "done"
 
    terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                      --region=$euca_user_region | grep "^INSTANCE" | cut -f2)
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
            echo ">                                                   --region=$euca_user_region | grep \"^INSTANCE\" | cut -f2)"
            terminated_instance_ids=$(euca-describe-instances --filter "instance-state-name=terminated" \
                                                              --region=$euca_user_region | grep "^INSTANCE" | cut -f2)
            pause
 
            echo "# for instance_id in \$terminated_instance_ids; do"
            echo ">     euca-terminate-instances --region $euca_user_region \$instance_id &> /dev/null"
            echo "> done"
            for instance_id in $terminated_instance_ids; do
                euca-terminate-instances --region $euca_user_region $instance_id &> /dev/null
            done
 
            next
        fi
    fi
fi
 
 
((++step))
if [ $mode = e -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List remaining Eucalyptus Resources"
        echo "    - Confirm we are back to our initial set"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-groups --region $euca_user_region"
        echo
        echo "euca-describe-instances --region $euca_user_region"
 
        run 50
 
        if [ $choice = y ]; then
            echo
            echo "# euca-describe-groups --region $euca_user_region"
            euca-describe-groups --region $euca_user_region
            pause
 
            echo "# euca-describe-instances --region $euca_user_region"
            euca-describe-instances --region $euca_user_region
 
            next
        fi
    fi
fi
 
 
((++step))
if [ $mode = e -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List remaining Eucalyptus CloudFormation Stacks"
        echo "    - Confirm we are back to our initial set"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euform-describe-stacks --region $euca_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-describe-stacks --region $euca_user_region"
            euform-describe-stacks --region $euca_user_region

            next
        fi
    fi
fi


end=$(date +%s)

echo
echo "Eucalyptus CloudFormation WordPress demo reset complete (time: $(date -u -d @$((end-start)) +"%T"))"
