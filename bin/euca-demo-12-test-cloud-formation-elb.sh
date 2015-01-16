#/bin/bash
#
# This script tests Eucalyptus CloudFormation,
# using a template which creates an elb and two instances.
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
prefix=demo-12

centos_image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz

step=0
interactive=1
step_min=0
step_wait=10
step_max=60
pause_min=0
pause_wait=2
pause_max=20
create_wait=10
create_attempts=12
login_wait=10
login_attempts=12
delete_wait=10
delete_attempts=12


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I [-s step_wait] [-p pause_wait]]"
    echo "  -I             non-interactive"
    echo "  -s step_wait   seconds per step (default: $step_wait)"
    echo "  -p pause_wait  seconds per pause (default: $pause_wait)"
}

pause() {
    if [ "$interactive" = 1 ]; then
        echo "#"
        read pause
        echo -en "\033[1A\033[2K"    # undo newline from read
    else
        echo "#"
        sleep $pause_wait
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed (y,n,q)[y]"
        echo
        echo -n "$prompt2"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
            "n" | "N" | "no" | "No") choice=n ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        echo
        seconds=$step_wait
        echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
            fi
            sleep 1
            ((seconds--))
        done
        echo
        choice=y
    fi
}


#  3. Parse command line options

while getopts Is:p: arg; do
    case $arg in
    I)  interactive=0;;
    s)  step_wait="$OPTARG";;
    p)  pause_wait="$OPTARG";;
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

if [[ $step_wait =~ ^[0-9]+$ ]]; then
    if ((step_wait < step_min || step_wait > step_max)); then
        echo "-s $step_wait invalid: value must be between $step_min and $step_max seconds"
        exit 5
    fi
else
    echo "-s $step_wait illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_wait =~ ^[0-9]+$ ]]; then
    if ((pause_wait < pause_min || pause_wait > pause_max)); then
        echo "-p $pause_wait invalid: value must be between $pause_min and $pause_max seconds"
        exit 7
    fi
else
    echo "-p $pause_wait illegal: must be a positive integer"
    exit 6
fi

if [ -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Found Eucalyptus Administrator credentials"
elif [ -r /root/admin.zip ]; then
    echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
    mkdir -p /root/creds/eucalyptus/admin
    unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/eucalyptus/admin/eucarc    # invisibly fix deprecation message
    sleep 2
else
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 10
fi

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 20
fi

demo_initialized=y
[ -r /root/centos.raw ] || demo_initialized=n
euca-describe-images | grep -s -q "centos.raw.manifest.xml" || demo_initialized=n
euca-describe-keypairs | grep -s -q "admin-demo" || demo_initialized=n

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run euca-demo-01-initialize.sh script."
    exit 30
fi


#  5. Execute Demo

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    choose "Continue"
fi


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
echo "eulb-describe-lbs"
echo
echo "euca-describe-instances"

choose "Execute"

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

    echo "# eulb-describe-lbs"
    eulb-describe-lbs | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-lbs.out
    pause

    echo "# euca-describe-instances"
    euca-describe-instances | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out
    
    choose "Continue"
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

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display ELB Example CloudFormation template"
echo "    - This elb template creates a pair of instances with an"
echo "      ElasticLoadBalancer in front, with the KeyPair and"
echo "      image created externally and passwd in as parameters"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat $templatesdir/elb.template"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# cat $templatesdir/elb.template"
    cat $templatesdir/elb.template

    choose "Continue"
fi


# Prefer the centos image, but fallback to the default image installed by FastStart
image=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)
user=root

if [ -z $image ]; then
    image=$(euca-describe-images | grep default.img.manifest.xml | cut -f2)
    user=cirros
fi

if [ -z $image ]; then
    echo "centos and default images missing; run earlier step to download and install centos image before re-running this step, exiting"
    exit 10
fi

((++step))
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
echo "euform-create-stack --template-file $templatesdir/elb.template -p WebServerImageId=$image ElbDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-create-stack --template-file $templatesdir/elb.template -p WebServerImageId=$image ElbDemoStack"
    euform-create-stack --template-file $templatesdir/elb.template -p WebServerImageId=$image ElbDemoStack
    
    choose "Continue"
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
echo "euform-describe-stack-events ElbDemoStack | tail -10"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    attempt=0
    echo
    while ((attempt++ <= create_attempts)); do
        echo "# euform-describe-stack-events ElbDemoStack | tail -10"
        euform-describe-stack-events ElbDemoStack | tail -10 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out
        tail -1 $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out | grep -s -q CREATE_COMPLETE
        RC=$?
        if [ $RC = 0 ]; then
            break
        else
            echo
            echo "Not finished ($RC). Waiting $create_wait seconds"
            sleep $create_wait
            echo
        fi
    done

    choose "Continue"
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
echo "eulb-describe-lbs"
echo
echo "euca-describe-instances"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euca-describe-groups"
    euca-describe-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-groups.out
    pause

    echo "# eulb-describe-lbs"
    eulb-describe-lbs | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-lbs.out
    pause

    echo "# euca-describe-instances"
    euca-describe-instances | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-instances.out

    choose "Continue"
fi


# This is a shortcut assuming no other activity on the system - find the most recently launched instance
result=$(euca-describe-instances | grep "^INSTANCE" | cut -f2,4,11 | sort -k3 | tail -1 | cut -f1,2 | tr -s '[:blank:]' ':')
instance=${result%:*}
public_ip=${result#*:}

sed -i -e "/$public_ip/d" /root/.ssh/known_hosts
ssh-keyscan $public_ip 2> /dev/null >> /root/.ssh/known_hosts


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm ability to login to Instance"
echo "    - If unable to login, view instance console output with:"
echo "      # euca-get-console-output $instance"
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
echo "ssh -i /root/creds/eucalyptus/admin/admin-demo.pem $user@$public_ip"

choose "Execute"

if [ $choice = y ]; then
    attempt=0
    echo
    while ((attempt++ <= login_attempts)); do
        echo "# ssh -i /root/creds/eucalyptus/admin/admin-demo.pem $user@$public_ip"
        ssh -i /root/creds/eucalyptus/admin/admin-demo.pem $user@$public_ip
        RC=$?
        if [ $RC = 0 -o $RC = 1 ]; then
            break
        else
            echo
            echo "Not available ($RC). Waiting $login_wait seconds"
            sleep $login_wait
            echo
        fi
    done

    choose "Continue"
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
echo "euform-delete-stack ElbDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-delete-stack ElbDemoStack"
    euform-delete-stack ElbDemoStack
   
    choose "Continue"
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
echo "euform-describe-stack-events ElbDemoStack | tail -10"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    attempt=0
    echo
    while ((attempt++ <= delete_attempts)); do
        echo "# euform-describe-stack-events ElbDemoStack | tail -10"
        euform-describe-stack-events ElbDemoStack | tail -10 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out
        tail -1 $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-stack-events.out | grep -s -q DELETE_COMPLETE
        RC=$?
        if [ $RC = 0 ]; then
            break
        else
            echo
            echo "Not finished ($RC). Waiting $delete_wait seconds"
            sleep $delete_wait
            echo
        fi
    done

    choose "Continue"
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
echo "eulb-describe-lbs"
echo
echo "euca-describe-instances"

choose "Execute"

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

    echo "# eulb-describe-lbs"
    eulb-describe-lbs
    pause

    echo "# euca-describe-instances"
    euca-describe-instances

    choose "Continue"
fi


echo
echo "Eucalyptus CloudFormation ELB template testing complete"
