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

step=0
interactive=1

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I]"
    echo "  -I non-interactive"
}

pause() {
    if [ "$interactive" = 1 ]; then
        read pause
    else
        sleep 5
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed[y]?"
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
        sleep 5
        choice=y
    fi
}


#  3. Parse command line options

while getopts I arg; do
    case $arg in
    I)  interactive=0;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo
    echo "Please set environment variables first"
    exit 1
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

if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Initialize Administrator credentials"
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


if [ $is_clc = y ]; then
    ((++step))
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
    echo "wget http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz -O /root/centos.raw.xz"
    echo
    echo "xz -d /root/centos.raw.xz"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# wget http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz -O /root/centos.raw.xz"
        wget http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz -O /root/centos.raw.xz
        pause

        echo "xz -d /root/centos.raw.xz"
        xz -d /root/centos.raw.xz

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    account=$(grep ops /var/tmp/9-8-euare-accountlist.out | cut -f2)
    image=$(cut -f2 /var/tmp/9-3-euca-install-image.out)

    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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
    echo "euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.priv"
    echo
    echo "chmod 0600 /root/creds/ops/admin/ops-admin.priv"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.priv"
        euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.priv
        echo
        echo "# chmod 0600 /root/creds/ops/admin/ops-admin.priv"
        chmod 0600 /root/creds/ops/admin/ops-admin.priv

        choose "Continue"
    fi
fi

if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    image=$(cut -f2 /var/tmp/9-3-euca-install-image.out)

    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    instance=$(grep INSTANCE /var/tmp/9-15-euca-run-instances.out | cut -f2)
    public_ip=$(euca-describe-instances | grep $instance | cut -f4)

    ((++step))
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
    echo "ssh -i /root/creds/ops/admin/ops-admin.priv root@$public_ip"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# ssh -i /root/creds/ops/admin/ops-admin.priv root@$public_ip"
        ssh -i /root/creds/ops/admin/ops-admin.priv root@$public_ip

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List All Instances as Eucalyptus Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The Eucalyptus Administrator can see instances in other accounts"
    echo "      with the verbose parameter"
    echo "    - Note you need to run the next step on all Node Controllers, before continuing"
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


if [ $is_nc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Overcommit CPUs on Node Controller"
    echo "    - This step is only run on Node Controller hosts"
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


if [ $is_clc = y ]; then
    ((++step))
    clear 
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm CPU Overcommit"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - You should have restarted all Node Controllers prior to this step"
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
