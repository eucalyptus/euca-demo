#/bin/bash
#
# This script configures Eucalyptus Images and creates some Instances
#
# Each student MUST run all prior scripts on all nodes prior to this script.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

centos_image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz

step=0
interactive=1
step_min=0
step_wait=10
step_max=60
pause_min=0
pause_wait=2
pause_max=20
login_wait=10
login_attempts=12

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I [-s step_wait] [-p pause_wait]] [-u image_url]"
    echo "  -I             non-interactive"
    echo "  -s step_wait   seconds per step (default: $step_wait)"
    echo "  -p pause_wait  seconds per pause (default: $pause_wait)"
    echo "  -u image_url   URL to CentOS image (default: $centos_image_url)"
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

while getopts Is:p:u: arg; do
    case $arg in
    I)  interactive=0;;
    s)  step_wait="$OPTARG";;
    p)  pause_wait="$OPTARG";;
    u)  centos_image_url="$OPTARG";;
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

if ! curl -s --head $centos_image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo
    echo "-u $centos_image_url invalid: attempts to reach this URL failed"
    exit 8
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 10
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y
[ "$(hostname -s)" = "$EUCA_UFS_HOST_NAME" ] && is_ufs=y
[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y
[ "$(hostname -s)" = "$EUCA_CC_HOST_NAME" ] && is_cc=y
[ "$(hostname -s)" = "$EUCA_SC_HOST_NAME" ] && is_sc=y
[ "$(hostname -s)" = "$EUCA_OSP_HOST_NAME" ] && is_osp=y
[ "$(hostname -s)" = "$EUCA_NC1_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC2_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC3_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC4_HOST_NAME" ] && is_nc=y


#  5. Execute Course Lab

((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Use Administrator credentials"
    echo "    - This step is only run on the Cloud Controller host"
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
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download a CentOS 6.5 image"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "wget $centos_image_url -O /root/centos.raw.xz"
    echo
    echo "xz -v -d /root/centos.raw.xz"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# wget $centos_image_url -O /root/centos.raw.xz"
        wget $centos_image_url -O /root/centos.raw.xz
        pause

        echo "xz -v -d /root/centos.raw.xz"
        xz -v -d /root/centos.raw.xz

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Image"
    echo "    - This step is only run on the Cloud Controller host"
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
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee /var/tmp/9-3-euca-install-image.out

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Images"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - You will notice the imaging and loadbalancing images as well as the image"
    echo "      just uploaded"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-images"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-images"
        euca-describe-images

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Instance Types"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-describe-instance-types"
    
    choose "Execute"
    
    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types"
        euca-describe-instance-types

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Modify an Instance Type"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Change the 1.small instance type to use 1 GB Ram instead"
    echo "      of the 256 MB default"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small"
    
    choose "Execute"
    
    if [ $choice = y ]; then
        echo
        echo "# euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small"
        euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Instance type modification"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-describe-instance-types"
    
    choose "Execute"
    
    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types"
        euca-describe-instance-types

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Find the Account ID of the Ops Account"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountlist | grep ops"
   
    choose "Execute"
   
    if [ $choice = y ]; then
        echo
        echo "# euare-accountlist | grep ops"
        euare-accountlist | tee /var/tmp/9-8-euare-accountlist.out

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    account=$(grep ops /var/tmp/9-8-euare-accountlist.out | cut -f2)
    image=$(cut -f2 /var/tmp/9-3-euca-install-image.out)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Allow the Ops Account to use the new image"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-image-attribute -l -a $account $image"
   
    choose "Execute"
   
    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $account $image"
        euca-modify-image-attribute -l -a $account $image

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download and Source the Ops Account Administrator Credentials"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/creds/ops/admin"
    echo
    echo "euca-get-credentials -a ops -u admin \\"
    echo "                     /root/creds/ops/admin/ops-admin.zip"
    echo
    echo "unzip /root/creds/ops/admin/ops-admin.zip \\"
    echo "      -d /root/creds/ops/admin/"
    echo
    echo "source /root/creds/ops/admin/eucarc"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/creds/ops/admin"
        mkdir -p /root/creds/ops/admin
        pause

        echo "# euca-get-credentials -a ops -u admin \\"
        echo ">                      /root/creds/ops/admin/ops-admin.zip"
        euca-get-credentials -a ops -u admin \
                             /root/creds/ops/admin/ops-admin.zip
        pause

        echo "# unzip /root/creds/ops/admin/ops-admin.zip \\"
        echo ">       -d /root/creds/ops/admin/"
        unzip /root/creds/ops/admin/ops-admin.zip \
              -d /root/creds/ops/admin/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/ops/admin/eucarc    # invisibly fix deprecation message
        pause

        echo "# source /root/creds/ops/admin/eucarc"
        source /root/creds/ops/admin/eucarc

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Images visible to the Ops Account Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-images -a"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-images -a"
        euca-describe-images -a

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Keypair"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem"
    echo
    echo "chmod 0600 /root/creds/ops/admin/ops-admin.pem"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem"
        euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem
        echo
        echo "# chmod 0600 /root/creds/ops/admin/ops-admin.pem"
        chmod 0600 /root/creds/ops/admin/ops-admin.pem

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Security Groups"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-groups"
    echo

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups"
        euca-describe-groups

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Modify default Security Group to allow SSH"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default"
        euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    image=$(cut -f2 /var/tmp/9-3-euca-install-image.out)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Launch Instance"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Using the new keypair and uploaded image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-run-instances -k ops-admin $image -t m1.small"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-run-instances -k ops-admin $image -t m1.small"
        euca-run-instances -k ops-admin $image -t m1.small | tee /var/tmp/9-15-euca-run-instances.out

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Instances"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - This shows instances running in the Ops Account"
    echo "    - Public IP will be in the $EUCA_VNET_PUBLICIPS range"
    echo "    - Private IP will be in the $EUCA_VNET_SUBNET/$EUCA_VNET_NETMASK subnet"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-instances"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instances"
        euca-describe-instances

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    instance=$(grep INSTANCE /var/tmp/9-15-euca-run-instances.out | cut -f2)
    public_ip=$(euca-describe-instances | grep $instance | cut -f4)

    sed -i -e "/$public_ip/d" /root/.ssh/known_hosts
    ssh-keyscan $public_ip 2> /dev/null >> /root/.ssh/known_hosts

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm ability to login to Instance"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - If unable to login, view instance console output with:"
    echo "      # euca-get-console-output $instance"
    echo "    - If able to login, show private IP with:"
    echo "      # ifconfig"
    echo "    - Then view meta-data about instance type with:"
    echo "      # curl http://169.254.169.254/latest/meta-data/instance-type"
    echo "    - Logout of instance once login ability confirmed"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -i /root/creds/ops/admin/ops-admin.pem root@$public_ip"

    choose "Execute"

    if [ $choice = y ]; then
        attempt=0
        echo
        while ((attempt++ <=  login_attempts)); do
            echo "# ssh -i /root/creds/ops/admin/ops-admin.pem root@$public_ip"
            ssh -i /root/creds/ops/admin/ops-admin.pem root@$public_ip
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
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List All Instances as Eucalyptus Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The Eucalyptus Administrator can see instances in other accounts"
    echo "      with the verbose parameter"
    echo "    - NOTE! After completing this step, you will need to run"
    echo "      the next step on all Node Controller hosts before you"
    echo "      continue here"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "euca-describe-instances verbose"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc
        pause

        echo "# euca-describe-instances verbose"
        euca-describe-instances verbose

        choose "Continue"
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Overcommit CPUs on Node Controller host"
    echo "    - This step is only run on Node Controller hosts"
    echo "    - STOP! This step should be run prior to the step"
    echo "      which confirms CPU overcommit on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "sed -e 's/^#MAX_CORES=\"0\"/MAX_CORES=\"6\"/' /etc/eucalyptus/eucalyptus.conf"
    echo
    echo "service eucalyptus-nc restart"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# sed -i -e 's/^#MAX_CORES=\"0\"/MAX_CORES=\"6\"/' /etc/eucalyptus/eucalyptus.conf"
        sed -i -e 's/^#MAX_CORES=\"0\"/MAX_CORES=\"6\"/' /etc/eucalyptus/eucalyptus.conf
        pause

        echo "# service eucalyptus-nc restart"
        service eucalyptus-nc restart

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear 
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm CPU Overcommit"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - NOTE: This step should only be run after the step"
    echo "      which first adjusts MAX_CORES, then restarts the Node"
    echo "      Controller service on all Node Controller hosts"
    echo "    - Confirm maximum number of m1.small instances increased"
    echo "      to 6 due to overcommit"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-instance-types --show-capacity"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types --show-capacity"
        euca-describe-instance-types --show-capacity

        choose "Continue"
    fi
fi


echo
echo "Image and Instance configuration and testing complete"
