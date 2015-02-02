#/bin/bash
#
# This script configures Eucalyptus Images and creates some Instances
#
# This script should only be run on the Cloud Controller and Node Controller hosts
#
# Each student MUST run all prior scripts on relevant hosts prior to this script.
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n
[ "$(hostname -s)" = "$EUCA_NC1_HOST_NAME" ] && is_nc=y  || is nc=n
[ "$(hostname -s)" = "$EUCA_NC2_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC3_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC4_HOST_NAME" ] && is_nc=y

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

login_attempts=12
login_default=10

interactive=1
speed=100
#image_url=http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz
image_url=http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
#image_url=http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-u image_url]"
    echo "  -I            non-interactive"
    echo "  -s            slower: increase pauses by 25%"
    echo "  -f            faster: reduce pauses by 25%"
    echo "  -u image_url  URL to Demo CentOS image (default: $image_url)"
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

while getopts Isfu:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    u)  image_url="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if ! curl -s --head $image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "-u $image_url invalid: attempts to reach this URL failed"
    exit 5
fi

if [ $is_clc = n -a $is_nc = n ]; then
    echo "This script should be run only on the Cloud Controller or a Node Controller host"
    exit 10
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: /root/creds/eucalyptus/admin/eucarc"
    exit 20
fi


#  5. Execute Course Lab

start=$(date +%s)

((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "cat /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"

    next

    echo
    echo "# cat /root/creds/eucalyptus/admin/eucarc"
    cat /root/creds/eucalyptus/admin/eucarc
    pause

    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    next
fi


((++step))
if [ $is_clc = y ]; then
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
    echo "wget $image_url -O /root/centos.raw.xz"
    echo
    echo "xz -v -d /root/centos.raw.xz"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# wget $image_url -O /root/centos.raw.xz"
        wget $image_url -O /root/centos.raw.xz
        pause

        echo "xz -v -d /root/centos.raw.xz"
        xz -v -d /root/centos.raw.xz

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
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

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm"
        euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm | tee /var/tmp/9-3-euca-install-image.out

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Images"
    echo "    - NOTE: Notice the imaging and loadbalancing images in addition"
    echo "      to the image just uploaded. Such internal images are only"
    echo "      visible to the Eucalyptus Administrator"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-images"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-images"
        euca-describe-images

        next 200
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Instance Types"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-describe-instance-types"
    
    run 50
    
    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types"
        euca-describe-instance-types

        next 200
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Modify an Instance Type"
    echo "    - Change the 1.small instance type to use 1 GB Ram instead"
    echo "      of the 256 MB default"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small"
    
    run
    
    if [ $choice = y ]; then
        echo
        echo "# euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small"
        euca-modify-instance-type -c 1 -d 5 -m 1024 m1.small

        next
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Instance type modification"
    echo
    echo "============================================================"
    echo 
    echo "Commands:"
    echo 
    echo "euca-describe-instance-types"
    
    run 50
    
    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types"
        euca-describe-instance-types

        next 200
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Find the Account ID of the Ops Account"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euare-accountlist | grep ops"
   
    run 50
   
    if [ $choice = y ]; then
        echo
        echo "# euare-accountlist | grep ops"
        euare-accountlist | tee /var/tmp/9-8-euare-accountlist.out

        next 50
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
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-image-attribute -l -a $account $image"
   
    run 50
   
    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $account $image"
        euca-modify-image-attribute -l -a $account $image

        next
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Download and Source the Ops Account Administrator Credentials"
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
    echo "cat /root/creds/ops/admin/eucarc"
    echo
    echo "source /root/creds/ops/admin/eucarc"

    run 50

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

        echo "# cat /root/creds/ops/admin/eucarc"
        cat /root/creds/ops/admin/eucarc
        pause

        echo "# source /root/creds/ops/admin/eucarc"
        source /root/creds/ops/admin/eucarc

        next
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Images visible to the Ops Account Administrator"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-images -a"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-images -a"
        euca-describe-images -a

        next
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create Keypair"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem"
    echo
    echo "chmod 0600 /root/creds/ops/admin/ops-admin.pem"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem"
        euca-create-keypair ops-admin | tee /root/creds/ops/admin/ops-admin.pem
        echo "#"
        echo "# chmod 0600 /root/creds/ops/admin/ops-admin.pem"
        chmod 0600 /root/creds/ops/admin/ops-admin.pem

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Security Groups"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-groups"
    echo

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups"
        euca-describe-groups

        next
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Modify default Security Group to allow SSH"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default"
        euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default

        next 50
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
    echo "    - Using the new keypair and uploaded image"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-run-instances -k ops-admin $image -t m1.small"

    run

    if [ $choice = y ]; then
        echo
        echo "# euca-run-instances -k ops-admin $image -t m1.small"
        euca-run-instances -k ops-admin $image -t m1.small | tee /var/tmp/9-15-euca-run-instances.out

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List Instances"
    echo "    - This shows instances running in the Ops Account"
    echo "    - Public IP will be in the $EUCA_VNET_PUBLICIPS range"
    echo "    - Private IP will be in the $EUCA_VNET_SUBNET/$EUCA_VNET_NETMASK subnet"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-instances"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instances"
        euca-describe-instances

        next 200
    fi
fi


((++step))
if [ $is_clc = y ]; then
    instance_id=$(grep INSTANCE /var/tmp/9-15-euca-run-instances.out | cut -f2)
    public_ip=$(euca-describe-instances | grep $instance_id | cut -f4)
    user=root

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm ability to login to Instance"
    echo "    - If unable to login, view instance console output with:"
    echo "      # euca-get-console-output $instance_id"
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
    echo "ssh -i /root/creds/ops/admin/ops-admin.pem $user@$public_ip"

    run 50

    if [ $choice = y ]; then
        attempt=0
        ((seconds=$login_default * $login_percent / 100))
        while ((attempt++ <=  login_attempts)); do
            sed -i -e "/$public_ip/d" /root/.ssh/known_hosts
            ssh-keyscan $public_ip 2> /dev/null >> /root/.ssh/known_hosts

            echo
            echo "# ssh -i /root/creds/ops/admin/ops-admin.pem $user@$public_ip"
            if [ $interactive = 1 ]; then
                ssh -i /root/creds/ops/admin/ops-admin.pem $user@$public_ip
                RC=$?
            else
                ssh -T -i /root/creds/ops/admin/ops-admin.pem $user@$public_ip << EOF
echo "# ifconfig"
ifconfig
sleep 5
echo
echo "# curl http://169.254.169.254/latest/meta-data/public-ipv4"
curl -sS http://169.254.169.254/latest/meta-data/public-ipv4 -o /tmp/public-ip4
echo $(cat /tmp/public-ip4)
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

        next 200
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). List All Instances as Eucalyptus Administrator"
    echo "    - The Eucalyptus Administrator can see instances in other accounts"
    echo "      with the verbose parameter"
    echo "    - NOTE: After completing this step, you will need to run"
    echo "      the next step on all Node Controller hosts before you"
    echo "      continue here"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "cat /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"
    echo
    echo "euca-describe-instances verbose"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat /root/creds/eucalyptus/admin/eucarc"
        cat /root/creds/eucalyptus/admin/eucarc
        pause

        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc
        pause

        echo "# euca-describe-instances verbose"
        euca-describe-instances verbose

        echo
        echo "Please run next step on all Node Controller services at this time"

        next 400
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Overcommit CPUs on Node Controller host"
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

    run

    if [ $choice = y ]; then
        echo
        echo "# sed -i -e 's/^#MAX_CORES=\"0\"/MAX_CORES=\"6\"/' /etc/eucalyptus/eucalyptus.conf"
        sed -i -e 's/^#MAX_CORES=\"0\"/MAX_CORES=\"6\"/' /etc/eucalyptus/eucalyptus.conf
        pause

        echo "# service eucalyptus-nc restart"
        service eucalyptus-nc restart

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear 
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm CPU Overcommit"
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

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types --show-capacity"
        euca-describe-instance-types --show-capacity

        next 200
    fi
fi


end=$(date +%s)

echo
echo "Image and Instance configuration and testing complete (time: $(date -u -d @$((end-start)) +"%T"))"
