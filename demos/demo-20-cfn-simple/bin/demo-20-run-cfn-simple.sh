#/bin/bash
#
# This script runs a Eucalyptus CloudFormation demo which uses the
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

if ! rpm -q --quiet w3m; then
    echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
    exit 98
fi


#  5. Run Demo

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
    echo "                     --region=$user_region | cut -f1,2,3"
    echo
    echo "euca-describe-keypairs --filter \"key-name=demo\" \\"
    echo "                       --region=$user_region"

    next

    echo
    echo "# euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
    echo ">                      --region=$user_region | cut -f1,2,3"
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region=$user_region | cut -f1,2,3 | grep "$image_name" || euca_demo_initialized=n
    pause

    echo "# euca-describe-keypairs --filter \"key-name=demo\"\\"
    echo ">                      --region=$user_region"
    euca-describe-keypairs --filter "key-name=demo" \
                           --region=$user_region | grep "demo" || euca_demo_initialized=n

    next

else
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region=$user_region | cut -f1,2,3 | grep -s -q "$image_name" || euca_demo_initialized=n
    euca-describe-keypairs --filter "key-name=demo" \
                           --region=$user_region | grep -s -q "demo" || euca_demo_initialized=n
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
    echo "$(printf '%2d' $step). Display Simple CloudFormation template"
    echo "    - The Simple.template creates a security group and an instance,"
    echo "      which references a keypair and an image created externally"
    echo "      and passed in as parameters"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "more $templatesdir/Simple.template"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# more $templatesdir/Simple.template"
        if [ $interactive = 1 ]; then
            more $templatesdir/Simple.template
        else
            # This will iterate over the file in a manner similar to more, but non-interactive
            ((rows=$(tput lines)-2))
            lineno=0
            while IFS= read line; do
                echo "$line"
                if [ $((++lineno % rows)) = 0 ]; then
                    tput rev; echo -n "--More--"; tput sgr0; echo -n " (Waiting 10 seconds...)"
                    sleep 10
                    echo -e -n "\r                                \r"
                fi
            done < $templatesdir/Simple.template
        fi

        next 200
    fi
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
    echo "$(printf '%2d' $step). List existing CloudFormation Stacks"
    echo "    - So we can compare with what this demo creates"
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


((++step))
image_id=$(euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                                --region=$user_region | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create the Stack"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-create-stack --template-file $templatesdir/Simple.template \\"
echo "                    --parameter DemoImageId=$image_id \\"
echo "                    --region=$user_region \\"
echo "                    SimpleDemoStack"

if [ "$(euform-describe-stacks --region=$user_region SimpleDemoStack | grep "^STACK" | cut -f3)" = "CREATE_COMPLETE" ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euform-create-stack --template-file $templatesdir/Simple.template \\"
        echo ">                     --parameter DemoImageId=$image_id \\"
        echo ">                     --region=$user_region \\"
        echo ">                     SimpleDemoStack"
        euform-create-stack --template-file $templatesdir/Simple.template \
                            --parameter DemoImageId=$image_id \
                            --region=$user_region \
                            SimpleDemoStack

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Monitor Stack creation"
echo "    - NOTE: This can take about 60 - 80 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks --region=$user_region"
echo
echo "euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5"

if [ "$(euform-describe-stacks --region=$user_region SimpleDemoStack | grep "^STACK" | cut -f3)" = "CREATE_COMPLETE" ]; then
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
        ((seconds=$create_default * $speed / 100))
        while ((attempt++ <= create_attempts)); do
            echo
            echo "# euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5"
            euform-describe-stack-events --region=$user_region SimpleDemoStack | head -5

            status=$(euform-describe-stacks --region=$user_region SimpleDemoStack | grep "^STACK" | cut -f3)
            if [ -z "$status" -o "$status" = "CREATE_COMPLETE" -o "$status" = "CREATE_FAILED" -o "$status" = "ROLLBACK_COMPLETE" ]; then
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
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List updated Resources"
    echo "    - Note addition of new group and instance"
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
instance_id=$(euform-describe-stack-resources --n SimpleDemoStack -l DemoInstance --region=$user_region | cut -f3)
public_name=$(euca-describe-instances --region=$user_region $instance_id | grep "^INSTANCE" | cut -f4)
public_ip=$(euca-describe-instances --region=$user_region $instance_id | grep "^INSTANCE" | cut -f17)
ssh_user=centos
ssh_key=demo

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm ability to login to Instance"
echo "    - If unable to login, view instance console output with:"
echo "      # euca-get-console-output $instance_id"
echo "    - If able to login, first show the private IP with:"
echo "      # ifconfig"
echo "    - Then view meta-data about the public IP with:"
echo "      # curl http://169.254.169.254/latest/meta-data/public-ipv4"
echo "    - Logout of instance once login ability confirmed"
echo "    - NOTE: This can take about 00 - 40 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "ssh -i ~/.ssh/${ssh_key}_id_rsa $ssh_user@$public_name"

run 50

if [ $choice = y ]; then
    attempt=0
    ((seconds=$login_default * $speed / 100))
    while ((attempt++ <= login_attempts)); do
        sed -i -e "/$public_name/d" ~/.ssh/known_hosts
        sed -i -e "/$public_ip/d" ~/.ssh/known_hosts
        ssh-keyscan $public_name 2> /dev/null >> ~/.ssh/known_hosts
        ssh-keyscan $public_ip 2> /dev/null >> ~/.ssh/known_hosts

        echo
        echo "# ssh -i ~/.ssh/${ssh_key}_id_rsa $ssh_user@$public_name"
        if [ $interactive = 1 ]; then
            ssh -i ~/.ssh/${ssh_key}_id_rsa $ssh_user@$public_name
            RC=$?
        else
            ssh -T -i ~/.ssh/${ssh_key}_id_rsa $ssh_user@$public_name << EOF
echo "# ifconfig"
ifconfig
sleep 5
echo
echo "# curl http://169.254.169.254/latest/meta-data/public-ipv4"
curl -sS http://169.254.169.254/latest/meta-data/public-ipv4 -o /tmp/public-ip4
cat /tmp/public-ip4
sleep 5
EOF
            RC=$?
        fi
        if [ $RC = 0 -o $RC = 1 ]; then
            break
        else
            echo
            echo -n "Not available ($RC). Waiting $seconds seconds..."
            sleep $seconds
            echo " Done"
        fi
    done

    next
fi


end=$(date +%s)

echo
echo "Eucalyptus CloudFormation Simple demo execution complete (time: $(date -u -d @$((end-start)) +"%T"))"
