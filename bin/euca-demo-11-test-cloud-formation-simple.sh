#/bin/bash
#
# This script tests Eucalyptus CloudFormation,
# using a simple template which creates a security group and an instance.
#
# It should only be run on the Cloud Controller host.
#
# It can be run on top of a new FastStart install,
# or on top of a new Cloud Administrator Course manual install.
#
# The script to configure CloudFormation must be run prior to this script.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp
prefix=demo-11

step=0
percent_min=0
percent_max=500
run_default=10
pause_default=2
next_default=10
create_attempts=12
create_default=10
login_attempts=12
login_default=10
delete_attempts=12
delete_default=10

interactive=1
#demo_account=demo    # The goal is to use a non-eucalyptus account, but this is currently broken due to a bug
demo_account=eucalyptus
run_percent=100
pause_percent=100
next_percent=100
create_percent=100
login_percent=100
delete_percent=100


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-a demo_account]"
    echo "           [-I [-r run_percent] [-p pause_percent] [-n next_percent]]"
    echo "  -a demo_account   account to use in demo (default: $demo_account)"
    echo "  -I                non-interactive"
    echo "  -r run_percent    run prompt timing adjustment % (default: $run_percent)"
    echo "  -p pause_percent  pause delay timing adjustment % (default: $pause_percent)"
    echo "  -n next_percent   next prompt timing adjustment % (default: $next_percent)"
}

run() {
    if [ -z $1 ]; then
        ((seconds=$run_default * $run_percent / 100))
    else
        ((seconds=$1 * $run_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$pause_default * $pause_percent / 100))
    else
        ((seconds=$1 * $pause_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$next_default * $next_percent / 100))
    else
        ((seconds=$1 * $next_percent / 100))
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

while getopts a:Ir:p:n:? arg; do
    case $arg in
    a)  demo_account="$OPTARG";;
    I)  interactive=0;;
    r)  run_percent="$OPTARG";;
    p)  pause_percent="$OPTARG";;
    n)  next_percent="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

if [[ $run_percent =~ ^[0-9]+$ ]]; then
    if ((run_percent < percent_min || run_percent > percent_max)); then
        echo "-r $run_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $run_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_percent =~ ^[0-9]+$ ]]; then
    if ((pause_percent < percent_min || pause_percent > percent_max)); then
        echo "-p $pause_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-p $pause_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $next_percent =~ ^[0-9]+$ ]]; then
    if ((next_percent < percent_min || next_percent > percent_max)); then
        echo "-r $next_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $next_percent illegal: must be a positive integer"
    exit 4
fi

if [ ! -r /root/creds/$demo_account/admin/eucarc ]; then
    echo "-a $demo_account invalid: Could not find Account Administrator credentials!"
    echo "   Expected to find: /root/creds/$demo_account/admin/eucarc"
    exit 10
fi

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo "This script should be run only on a Cloud Controller"
    exit 20
fi


#  5. Execute Demo

((++step))
clear
echo
echo "============================================================"
echo
if [ $demo_account = eucalyptus ]; then
    echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
else
    echo "$(printf '%2d' $step). Use Demo ($demo_account) Account Administrator credentials"
fi
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/$demo_account/admin/eucarc"

next 5

echo
echo "# source /root/creds/$demo_account/admin/eucarc"
source /root/creds/$demo_account/admin/eucarc

next 2


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
echo "euca-describe-images | grep \"centos.raw.manifest.xml\""
echo
echo "euca-describe-keypairs | grep \"admin-demo\""

next 5

echo
echo "# euca-describe-images | grep \"centos.raw.manifest.xml\""
euca-describe-images | grep "centos.raw.manifest.xml" || demo_initialized=n
pause

echo "# euca-describe-keypairs | grep \"admin-demo\""
euca-describe-keypairs | grep "admin-demo" || demo_initialized=n

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run euca-demo-01-initialize.sh script."
    exit 30
fi

next 5


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List initial resources"
echo "    - So we can compare with what CloudFormation creates"
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

run 5

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause 

    echo "# euca-describe-groups"
    euca-describe-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-groups.out
    pause

    echo "# euca-describe-instances"
    euca-describe-instances | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out
    
    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List CloudFormation Stacks"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"

run 5

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks

    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display Simple Example CloudFormation template"
echo "    - This simple template creates a simple security group"
echo "      and an instance which references a keypair and an image"
echo "      created externally and passed in as parameters"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "more $templatesdir/simple.template"

run 5

if [ $choice = y ]; then
    echo
    echo "# more $templatesdir/simple.template"
    if [ $interactive = 1 ]; then
        more $templatesdir/simple.template
    else
        # This will iterate over the file in a manner similar to more, but non-interactive
        ((rows=$(tput lines)-2))
        lineno=0
        while IFS= read line; do
            echo "$line"
            if [ $((++lineno % rows)) = 0 ]; then
                tput rev; echo -n "--More--"; tput sgr0; echo -n " (Wait 10 seconds...)"
                sleep 10
                echo -e -n "\r                             \r"
            fi
        done < $templatesdir/simple.template
    fi

    next 30
fi


((++step))
image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)
user=root

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
echo "euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image_id SimpleDemoStack"

run 5

if [ $choice = y ]; then
    echo
    echo "# euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image_id SimpleDemoStack"
    euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image_id SimpleDemoStack
    
    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Monitor Stack creation"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"
echo
echo "euform-describe-stack-events SimpleDemoStack | tail -10"

run 5

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    attempt=0
    ((seconds=$create_default * $create_percent / 100))
    while ((attempt++ <= create_attempts)); do
        echo
        echo "# euform-describe-stack-events SimpleDemoStack | tail -10"
        euform-describe-stack-events SimpleDemoStack | tail -10 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out
        tail -1 $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out | grep -s -q "CREATE_COMPLETE"
        RC=$?
        if [ $RC = 0 ]; then
            break
        else
            echo
            echo -n "Not finished ($RC). Wait $seconds seconds..."
            sleep $seconds
            echo " Done"
        fi
    done

    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List updated resources"
echo "    - Note addition of new instance and group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-groups"
echo
echo "euca-describe-instances"

run 5

if [ $choice = y ]; then
    echo
    echo "# euca-describe-groups"
    euca-describe-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-groups.out
    pause

    echo "# euca-describe-instances"
    euca-describe-instances | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out

    next 5
fi


((++step))
# This is a shortcut assuming no other activity on the system - find the most recently launched instance
result=$(euca-describe-instances | grep "^INSTANCE" | cut -f2,4,11 | sort -k3 | tail -1 | cut -f1,2 | tr -s '[:blank:]' ':')
instance_id=${result%:*}
public_ip=${result#*:}

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
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip"

run 5

if [ $choice = y ]; then
    attempt=0
    ((seconds=$login_default * $login_percent / 100))
    while ((attempt++ <=  login_attempts)); do
        echo
        sed -i -e "/$public_ip/d" /root/.ssh/known_hosts
        ssh-keyscan $public_ip 2> /dev/null >> /root/.ssh/known_hosts

        echo "# ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip"
        ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip
        RC=$?
        if [ $RC = 0 -o $RC = 1 ]; then
            break
        else
            echo
            echo -n "Not available ($RC). Wait $seconds seconds..."
            sleep $seconds
            echo " Done"
        fi
    done

    next 5
fi


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

run 5

if [ $choice = y ]; then
    echo
    echo "# euform-delete-stack SimpleDemoStack"
    euform-delete-stack SimpleDemoStack
   
    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Monitor Stack deletion"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"
echo
echo "euform-describe-stack-events SimpleDemoStack | tail -10"

run 5

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    attempt=0
    ((seconds=$delete_default * $delete_percent / 100))
    while ((attempt++ <= delete_attempts)); do
        echo
        echo "# euform-describe-stack-events SimpleDemoStack | tail -10"
        euform-describe-stack-events SimpleDemoStack | tail -10 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out
        tail -1 $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out | grep -s -q "DELETE_COMPLETE"
        RC=$?
        if [ $RC = 0 ]; then
            break
        else
            echo
            echo -n "Not finished ($RC). Wait $seconds seconds..."
            sleep $seconds
            echo " Done"
        fi
    done

    next 5
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List remaining resources"
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

run 5

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


echo
echo "Eucalyptus CloudFormation simple template testing complete"
