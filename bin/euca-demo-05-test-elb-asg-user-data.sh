#/bin/bash
#
# This script tests API creation of SecurityGroup, ElasticLoadBalancer, 
# LaunchConfiguration, AutoScalingGroup, ScalingPolicy, Alarms, 
# Instances and User-Data Scripts.
#
# It should only be run on the Cloud Controller host.
#
# It can be run on top of a new FastStart install,
# or on top of a new Cloud Administrator Course manual install.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp
prefix=demo-05

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
echo "    - Let's first note what we're starting with"
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
echo
echo "euscale-describe-launch-configs"
echo
echo "euscale-describe-auto-scaling-groups"
echo
echo "euscale-describe-policies"
echo
echo "euwatch-describe-alarms"

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
    pause

    echo "# euscale-describe-launch-configs"
    euscale-describe-launch-configs | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-launch-configs.out
    pause

    echo "# euscale-describe-auto-scaling-groups"
    euscale-describe-auto-scaling-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-auto-scaling-groups.out
    pause

    echo "# euscale-describe-policies"
    euscale-describe-policies | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-policies.out
    pause

    echo "# euwatch-describe-alarms"
    euwatch-describe-alarms | tee $tmpdir/$prefix-$(printf '%02d' $step)-euwatch-describe-alarms.out

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create a Security Group"
echo "    - We will allow SSH and HTTP"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-group -d \"Demo Security Group\" DemoSG"
echo
echo "euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 DemoSG"
echo
echo "euca-authorize -P tcp -p 22 -s 0.0.0.0/0 DemoSG"
echo
echo "euca-authorize -P tcp -p 80 -s 0.0.0.0/0 DemoSG"
echo
echo "euca-describe-groups DemoSG"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euca-create-group -d \"Demo Security Group\" DemoSG"
    euca-create-group -d "Demo Security Group" DemoSG
    pause

    echo "# euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 DemoSG"
    euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 DemoSG
    pause

    echo "# euca-authorize -P tcp -p 22 -s 0.0.0.0/0 DemoSG"
    euca-authorize -P tcp -p 22 -s 0.0.0.0/0 DemoSG
    pause
 
    echo "# euca-authorize -P tcp -p 80 -s 0.0.0.0/0 DemoSG"
    euca-authorize -P tcp -p 80 -s 0.0.0.0/0 DemoSG
    pause

    echo "# euca-describe-groups DemoSG"
    euca-describe-groups DemoSG

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create an ElasticLoadBalancer"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "eulb-create-lb -z default -l \"lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP\" DemoELB"
echo
echo "eulb-describe-lbs DemoELB"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# eulb-create-lb -z default -l \"lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP\" DemoELB"
    eulb-create-lb -z default -l "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-create-lb.out
    pause

    echo "# eulb-describe-lbs DemoELB"
    eulb-describe-lbs DemoELB

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure an ElasticLoadBalancer HealthCheck"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \\"
echo "                           --target http:80/index.html DemoELB"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \\"
    echo "                             --target http:80/index.html DemoELB"
    eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \
                               --target http:80/index.html DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-configure-healthcheck.out

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display Demo User-Data script"
echo "    - This simple user-data script will install Apache and configure"
echo "      a simple home page"
echo "    - We will use this in our LaunchConfiguration to automatically"
echo "      configure new instances created by our AutoScalingGroup"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat $scriptsdir/$prefix-user-data.sh"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# cat $scriptsdir/$prefix-user-data.sh"
    cat $scriptsdir/$prefix-user-data.sh

    choose "Continue"
fi


image=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)
user=root

if [ -z $image ]; then
    echo "centos image missing; run earlier step to download and install centos image before re-running this step, exiting"
    exit 10
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create a LaunchConfiguration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-create-launch-config DemoLC --image-id $image --instance-type m1.small --monitoring-enabled \\"
echo "                                    --key=DemoKey --group=DemoSG \\"
echo "                                    --user-data-file=$scriptsdir/$prefix-user-data.sh"
echo
echo "euscale-describe-launch-configs DemoLC"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euscale-create-launch-config DemoLC --image-id $image --instance-type m1.small --monitoring-enabled \\"
    echo ">                                     --key=DemoKey --group=DemoSG \\"
    echo ">                                     --user-data-file=$scriptsdir/$prefix-user-data.sh"
    euscale-create-launch-config DemoLC --image-id $image --instance-type m1.small --monitoring-enabled \
                                        --key=DemoKey --group=DemoSG \
                                        --user-data-file=$scriptsdir/$prefix-user-data.sh
    pause

    echo "# euscale-describe-launch-configs DemoLC"
    euscale-describe-launch-configs DemoLC

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create an AutoScalingGroup"
echo "    - Note we associate the AutoScalingGroup with the"
echo "      ElasticLoadBalancer created earlier"
echo "    - Note there are two methods of checking Instance"
echo "      status"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-create-auto-scaling-group DemoASG --launch-configuration DemoLC \\"
echo "                                          --availability-zones default \\"
echo "                                          --load-balancers DemoELB \\"
echo "                                          --min-size 2 --max-size 4 --desired-capacity 2"
echo
echo "euscale-describe-auto-scaling-groups DemoASG"
echo
echo "eulb-describe-instance-health DemoELB"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euscale-create-auto-scaling-group DemoASG --launch-configuration DemoLC \\"
    echo ">                                           --availability-zones default \\"
    echo ">                                           --load-balancers DemoELB \\"
    echo ">                                           --min-size 2 --max-size 4 --desired-capacity 2"
    euscale-create-auto-scaling-group DemoASG --launch-configuration DemoLC \
                                              --availability-zones default \
                                              --load-balancers DemoELB \
                                              --min-size 2 --max-size 4 --desired-capacity 2
    pause

    echo "# euscale-describe-auto-scaling-groups DemoASG"
    euscale-describe-auto-scaling-groups DemoASG
    pause

    echo "# eulb-describe-instance-health DemoELB"
    eulb-describe-instance-health DemoELB

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Policies and Associated Alarms"
echo "    - Create a scale out policy"
echo "    - Create a scale in policy"
echo "    - Update AutoScalingGroup with a termination policy"
echo "    - Create a high-cpu alarm using the scale out policy"
echo "    - Create a low-cpu alarm using the scale in policy"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-put-scaling-policy DemoHighCPUPolicy --auto-scaling-group DemoASG \\"
echo "                                             --adjustment=1 --type ChangeInCapacity"
echo
echo "euscale-put-scaling-policy DemoLowCPUPolicy --auto-scaling-group DemoASG \\"
echo "                                            --adjustment=-1 --type ChangeInCapacity"
echo
echo "euscale-update-auto-scaling-group DemoASG --termination-policies \"OldestLaunchConfiguration\""
echo
echo "euscale-describe-policies"
pause

echo "euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \\"
echo "                                           --namespace \"AWS/EC2\" --statistic Average \\"
echo "                                           --period 60 --threshold 50 \\"
echo "                                           --comparison-operator GreaterThanOrEqualToThreshold \\"
echo "                                           --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                                           --evaluation-periods 2 --alarm-actions <DemoHighCPUPolicy arn>"
pause

echo "euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \\"
echo "                                           --namespace \"AWS/EC2\" --statistic Average \\"
echo "                                           --period 60 --threshold 10 \\"
echo "                                           --comparison-operator LessThanOrEqualToThreshold \\"
echo "                                           --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                                           --evaluation-periods 2 --alarm-actions <DemoLowCPUPolicy arn>"
echo
echo "euwatch-describe-alarms"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euscale-put-scaling-policy DemoHighCPUPolicy --auto-scaling-group DemoASG \\" 
    echo ">                                              --adjustment=1 --type ChangeInCapacity"
    euscale-put-scaling-policy DemoHighCPUPolicy --auto-scaling-group DemoASG \
                                                 --adjustment=1 --type ChangeInCapacity | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-put-scaling-policy-high.out
    pause
 
    echo "# euscale-put-scaling-policy DemoLowCPUPolicy --auto-scaling-group DemoASG \\"
    echo ">                                             --adjustment=-1 --type ChangeInCapacity"
    euscale-put-scaling-policy DemoLowCPUPolicy --auto-scaling-group DemoASG \
                                                --adjustment=-1 --type ChangeInCapacity | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-put-scaling-policy-low.out
    pause

    echo "# euscale-update-auto-scaling-group DemoASG --termination-policies \"OldestLaunchConfiguration\""
    euscale-update-auto-scaling-group DemoASG --termination-policies "OldestLaunchConfiguration"
    pause

    echo "# euscale-describe-policies"
    euscale-describe-policies
    pause

    high_policy=$(cat $tmpdir/$prefix-$(printf '%02d' $step)-euscale-put-scaling-policy-high.out)
    echo "# euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \\"
    echo ">                                            --namespace \"AWS/EC2\" --statistic Average \\" 
    echo ">                                            --period 60 --threshold 50 \\"
    echo ">                                            --comparison-operator GreaterThanOrEqualToThreshold \\"
    echo ">                                            --dimensions \"AutoScalingGroupName=DemoASG\" \\"
    echo ">                                            --evaluation-periods 2 --alarm-actions $high_policy"
    euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \
                                               --namespace "AWS/EC2" --statistic Average \
                                               --period 60 --threshold 50 \
                                               --comparison-operator GreaterThanOrEqualToThreshold \
                                               --dimensions "AutoScalingGroupName=DemoASG" \
                                               --evaluation-periods 2 --alarm-actions $high_policy
    pause

    low_policy=$(cat $tmpdir/$prefix-$(printf '%02d' $step)-euscale-put-scaling-policy-low.out)
    echo "# euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \\"
    echo ">                                            --namespace \"AWS/EC2\" --statistic Average \\"
    echo ">                                            --period 60 --threshold 10 \\"
    echo ">                                            --comparison-operator LessThanOrEqualToThreshold \\"
    echo ">                                            --dimensions \"AutoScalingGroupName=DemoASG\" \\"
    echo ">                                            --evaluation-periods 2 --alarm-actions $low_policy"
    euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \
                                               --namespace "AWS/EC2" --statistic Average \
                                               --period 60 --threshold 10 \
                                               --comparison-operator LessThanOrEqualToThreshold \
                                               --dimensions "AutoScalingGroupName=DemoASG" \
                                               --evaluation-periods 2 --alarm-actions $low_policy
    pause

    echo "# euwatch-describe-alarms"
    euwatch-describe-alarms

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List updated resources"
echo "    - Note additional keypair, instances, 's note what we're starting with to better observe"
echo "      what we're creating"
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
echo
echo "euscale-describe-launch-configs"
echo
echo "euscale-describe-auto-scaling-groups"
echo
echo "euscale-describe-policies"
echo
echo "euwatch-describe-alarms"

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
    pause

    echo "# euscale-describe-launch-configs"
    euscale-describe-launch-configs | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-launch-configs.out
    pause

    echo "# euscale-describe-auto-scaling-groups"
    euscale-describe-auto-scaling-groups | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-auto-scaling-groups.out
    pause

    echo "# euscale-describe-policies"
    euscale-describe-policies | tee $tmpdir/$prefix-$(printf '%02d' $step)-euscale-describe-policies.out
    pause

    echo "# euwatch-describe-alarms"
    euwatch-describe-alarms | tee $tmpdir/$prefix-$(printf '%02d' $step)-euwatch-describe-alarms.out

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
echo "    - Then view user-data with:"
echo "      # curl http://169.254.169.254/latest/user-data"
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
echo "$(printf '%2d' $step). Display Demo Alternate User-Data script"
echo "    - This simple user-data script will install Apache and configure"
echo "      a simple home page"
echo "    - This alternate makes minor changes to the simple home page"
echo "      to demonstrate how updates to a Launch Configuration can handle"
echo "      rolling updates"
echo "    - We will modify our existing LaunchConfiguration to automatically"
echo "      configure new instances created by our AutoScalingGroup"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat $scriptsdir/$prefix-user-data-2.sh"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# cat $scriptsdir/$prefix-user-data-2.sh"
    cat $scriptsdir/$prefix-user-data-2.sh

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create a Replacement LaunchConfiguration"
echo "    - This will replace the original User-Data Script with a"
echo "      modified version which will alter the home page"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-create-launch-config DemoLC-2 --image-id $image --instance-type m1.small --monitoring-enabled \\"
echo "                                      --key=DemoKey --group=DemoSG \\"
echo "                                      --user-data-file=$scriptsdir/$prefix-user-data-2.sh"
echo
echo "euscale-describe-launch-configs DemoLC"
echo "euscale-describe-launch-configs DemoLC-2"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euscale-create-launch-config DemoLC-2 --image-id $image --instance-type m1.small --monitoring-enabled \\"
    echo ">                                       --key=DemoKey --group=DemoSG \\"
    echo ">                                       --user-data-file=$scriptsdir/$prefix-user-data-2.sh"
    euscale-create-launch-config DemoLC-2 --image-id $image --instance-type m1.small --monitoring-enabled \
                                          --key=DemoKey --group=DemoSG \
                                          --user-data-file=$scriptsdir/$prefix-user-data-2.sh
    pause

    echo "# euscale-describe-launch-configs DemoLC"
    euscale-describe-launch-configs DemoLC
    echo "# euscale-describe-launch-configs DemoLC-2"
    euscale-describe-launch-configs DemoLC-2

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Update an AutoScalingGroup"
echo "    - This replaces the original LaunchConfiguration with"
echo "      it's replacement created above"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2"
echo
echo "euscale-describe-auto-scaling-groups DemoASG"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2"
    euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2
    pause

    echo "# euscale-describe-auto-scaling-groups DemoASG"
    euscale-describe-auto-scaling-groups DemoASG

    choose "Continue"
fi


instances="$(euscale-describe-auto-scaling-groups DemoASG | grep "^INSTANCE" | cut -f2)"

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Trigger AutoScalingGroup Instance Replacement"
echo "    - We will terminate existing Instances of the AutoScalingGroup,"
echo "      and confirm replacement Instances are created with the new"
echo "      LaunchConfiguration and User-Data Script"
echo "    - Wait for a replacement instance to be \"InService\" before"
echo "      terminating the next Instance"
echo
echo "============================================================"
echo
echo "Commands:"
for instance in $instances; do
    echo
    echo "euscale-terminate-instance-in-auto-scaling-group $instance -D --show-long"
    echo
    echo "euscale-describe-auto-scaling-groups DemoASG"
    echo
    echo "eulb-describe-instance-health DemoELB (repeat until both instances are back is \"InService\")"
done

choose "Execute"

if [ $choice = y ]; then
    for instance in $instances; do
        echo
        echo "# euscale-terminate-instance-in-auto-scaling-group $instance -D --show-long"
        euscale-terminate-instance-in-auto-scaling-group $instance -D --show-long
        pause

        tries=0
        while [ $((tries++)) -le 20 ]; do
            echo "# euscale-describe-auto-scaling-groups DemoASG"
            euscale-describe-auto-scaling-groups DemoASG
            echo
            echo "# eulb-describe-instance-health DemoELB"
            eulb-describe-instance-health DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-instance-health.out
            
            if [ $(grep -c "InService" $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-instance-health.out) -lt 2 ]; then
                echo "- Pausing until at least 2 instances are \"InService\""
                pause    # At least one instance not "InService"
            else
                break    # Continue only once at least 2 instances back in service
            fi
        done
    done

    choose "Continue"
fi


# Initially, I think I'm going to want to bail on this demo at this point,
# instead of tearing down all resources created to get back to the initial
# configuration, to save time and move onto the CloudFormation demo.
# So, parking some of the deletion logic here commented out until I can
# finish adding it all, as I don't want to show partial rollback.


#((++step))
#echo "============================================================"
#echo
#echo "$(printf '%2d' $step). List remaining resources"
#echo "    - Confirm we are back to our initial set"
#echo
#echo "============================================================"
#echo
#echo "Commands:"
#echo
#echo "euca-describe-images"
#echo
#echo "euca-describe-keypairs"
#echo
#echo "euca-describe-groups"
#echo
#echo "eulb-describe-lbs"
#echo
#echo "euca-describe-instances"
#echo
#echo "euscale-describe-launch-configs"
#echo
#echo "euscale-describe-auto-scaling-groups"
#echo
#echo "euwatch-describe-alarms"
#
#choose "Execute"
#
#if [ $choice = y ]; then
#    echo
#    echo "# euca-describe-images"
#    euca-describe-images
#    pause
#
#    echo "# euca-describe-keypairs"
#    euca-describe-keypairs
#    pause
#
#    echo "# euca-describe-groups"
#    euca-describe-groups
#    pause
#
#    echo "# eulb-describe-lbs"
#    eulb-describe-lbs
#    pause
#
#    echo "# euca-describe-instances"
#    euca-describe-instances
#    pause
#
#    echo "# euscale-describe-launch-configs"
#    euscale-describe-launch-configs
#    pause
#
#    echo "# euscale-describe-auto-scaling-groups"
#    euscale-describe-auto-scaling-groups
#    pause
#
#    echo "# euwatch-describe-alarms"
#    euwatch-describe-alarms
#
#    choose "Continue"
#fi

echo
echo "Eucalyptus SecurityGroup, ElasticLoadBalancer, LaunchConfiguration,"
echo "           AutoScalingGroup and User-Data Script testing complete"
