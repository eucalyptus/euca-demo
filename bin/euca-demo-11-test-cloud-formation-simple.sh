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

centos_image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz

step=0
interactive=1
step_min=0
step_wait=15
step_max=120
pause_min=0
pause_wait=2
pause_max=30


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
        echo "Waiting $step_wait seconds..."
        sleep $step_wait
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

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 10
fi


#  5. Convert FastStart credentials to Course directory structure

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
    exit 20
fi


#  6. Execute Demo

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Initialize Administrator credentials"
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
if [ -r /root/centos.raw ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download a CentOS 6.5 image"
    echo "    - Already Downloaded!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download a CentOS 6.5 image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "wget $centos_image_url -O /root/centos.raw.xz"
    echo
    echo "xz -d /root/centos.raw.xz"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# wget $centos_image_url -O /root/centos.raw.xz"
        wget $centos_image_url -O /root/centos.raw.xz
        pause

        echo "xz -d /root/centos.raw.xz"
        xz -d /root/centos.raw.xz

        choose "Continue"
    fi
fi


((++step))
if euca-describe-images | grep -s -q "centos.raw.manifest.xml"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Image"
    echo "    - Already Installed!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-install-image.out

        choose "Continue"
    fi
fi


((++step))
if euca-describe-keypairs | grep -s -q "DemoKey"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create a Keypair"
    echo "    - Already Created!"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create a Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem"
    echo
    echo "chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem"
        euca-create-keypair DemoKey | tee > /root/creds/eucalyptus/admin/DemoKey.pem
        echo
        echo "# chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem"
        chmod 0600 /root/creds/eucalyptus/admin/DemoKey.pem

        choose "Continue"
    fi
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
echo "$(printf '%2d' $step). Display Simple Example CloudFormation template"
echo "    - This simple template creates a simple security group"
echo "      and an instance which references a keypair and an image"
echo "      created externally and passed in as parameters"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat $templatesdir/simple.template"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# cat $templatesdir/simple.template"
    cat $templatesdir/simple.template

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
echo "euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image SimpleDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image SimpleDemoStack"
    euform-create-stack --template-file $templatesdir/simple.template -p DemoImageId=$image SimpleDemoStack
    
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
echo "euform-describe-stack-events SimpleDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    echo "# euform-describe-stack-events SimpleDemoStack"
    euform-describe-stack-events SimpleDemoStack
    
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
echo "euca-describe-instances"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euca-describe-groups"
    euca-describe-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-describe-groups.out
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
echo "ssh -i /root/creds/eucalyptus/admin/DemoKey.pem $user@$public_ip"

choose "Execute"

if [ $choice = y ]; then
    tries=0
    echo
    while [ $((tries++)) -le 12 ]; do
        echo "# ssh -i /root/creds/eucalyptus/admin/DemoKey.pem $user@$public_ip"
        ssh -i /root/creds/eucalyptus/admin/DemoKey.pem $user@$public_ip
        RC=$?
        if [ $RC = 0 -o $RC = 1 ]; then
            break
        else
            echo "Not yet available ($RC). Waiting 10 seconds"
            sleep 15
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
echo "euform-delete-stack SimpleDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-delete-stack SimpleDemoStack"
    euform-delete-stack SimpleDemoStack
   
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
echo "euform-describe-stack-events SimpleDemoStack"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    echo "# euform-describe-stack-events SimpleDemoStack"
    euform-describe-stack-events SimpleDemoStack

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

    echo "# euca-describe-instances"
    euca-describe-instances

    choose "Continue"
fi


echo
echo "Eucalyptus CloudFormation simple template testing complete"
