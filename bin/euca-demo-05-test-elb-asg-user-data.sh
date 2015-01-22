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

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp
prefix=demo-05

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

create_attempts=6
create_default=20
login_attempts=6
login_default=20
replace_attempts=12
replace_default=20
delete_attempts=6
delete_default=20

interactive=1
speed=100
demo_account=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a demo_account]"
    echo "  -I               non-interactive"
    echo "  -s               slower: increase pauses by 25%"
    echo "  -f               faster: reduce pauses by 25%"
    echo "  -a demo_account  account to use in demos (default: $demo_account)"
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
    a)  demo_account="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r /root/creds/$demo_account/admin/eucarc ]; then
    echo "-a $demo_account invalid: Could not find Account Administrator credentials!"
    echo "   Expected to find: /root/creds/$demo_account/admin/eucarc"
    exit 21
fi


#  5. Execute Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Demo ($demo_account) Account Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "source /root/creds/$demo_account/admin/eucarc"

next

echo
echo "# source /root/creds/$demo_account/admin/eucarc"
source /root/creds/$demo_account/admin/eucarc

next 50


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

next

echo
echo "# euca-describe-images | grep \"centos.raw.manifest.xml\""
euca-describe-images | grep "centos.raw.manifest.xml" || demo_initialized=n
pause

echo "# euca-describe-keypairs | grep \"admin-demo\""
euca-describe-keypairs | grep "admin-demo" || demo_initialized=n

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run euca-demo-02-initialize-dependencies.sh script."
    exit 99
fi

next


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List initial resources"
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

    next 200
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

run 50

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

    next
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

run

if [ $choice = y ]; then
    echo
    echo "# eulb-create-lb -z default -l \"lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP\" DemoELB"
    eulb-create-lb -z default -l "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-create-lb.out
    pause

    echo "# eulb-describe-lbs DemoELB"
    eulb-describe-lbs DemoELB

    next
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

run

if [ $choice = y ]; then
    echo
    echo "# eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \\"
    echo "                             --target http:80/index.html DemoELB"
    eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \
                               --target http:80/index.html DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-configure-healthcheck.out

    next
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

run 50

if [ $choice = y ]; then
    echo
    echo "# cat $scriptsdir/$prefix-user-data.sh"
    cat $scriptsdir/$prefix-user-data.sh

    next 150
fi


((++step))
image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)

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
echo "euscale-create-launch-config DemoLC --image-id $image_id --instance-type m1.small --monitoring-enabled \\"
echo "                                    --key=admin-demo --group=DemoSG \\"
echo "                                    --user-data-file=$scriptsdir/$prefix-user-data.sh"
echo
echo "euscale-describe-launch-configs DemoLC"

run 150

if [ $choice = y ]; then
    echo
    echo "# euscale-create-launch-config DemoLC --image-id $image_id --instance-type m1.small --monitoring-enabled \\"
    echo ">                                     --key=admin-demo --group=DemoSG \\"
    echo ">                                     --user-data-file=$scriptsdir/$prefix-user-data.sh"
    euscale-create-launch-config DemoLC --image-id $image_id --instance-type m1.small --monitoring-enabled \
                                        --key=admin-demo --group=DemoSG \
                                        --user-data-file=$scriptsdir/$prefix-user-data.sh
    pause

    echo "# euscale-describe-launch-configs DemoLC"
    euscale-describe-launch-configs DemoLC

    next
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

run 150

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

    next
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
pause 250

echo "euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \\"
echo "                                           --namespace \"AWS/EC2\" --statistic Average \\"
echo "                                           --period 60 --threshold 50 \\"
echo "                                           --comparison-operator GreaterThanOrEqualToThreshold \\"
echo "                                           --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                                           --evaluation-periods 2 --alarm-actions <DemoHighCPUPolicy arn>"
echo
echo "euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \\"
echo "                                           --namespace \"AWS/EC2\" --statistic Average \\"
echo "                                           --period 60 --threshold 10 \\"
echo "                                           --comparison-operator LessThanOrEqualToThreshold \\"
echo "                                           --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                                           --evaluation-periods 2 --alarm-actions <DemoLowCPUPolicy arn>"
echo
echo "euwatch-describe-alarms"

run 150

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
    pause 250

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

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List updated resources"
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

    next 200
fi


((++step))
# This is a shortcut assuming no other activity on the system - find the most recently launched instance
result=$(euca-describe-instances | grep "^INSTANCE" | cut -f2,4,11 | sort -k3 | tail -1 | cut -f1,2 | tr -s '[:blank:]' ':')
instance_id=${result%:*}
public_ip=${result#*:}
user=root

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
echo "    - Then view user-data with:"
echo "      # curl http://169.254.169.254/latest/user-data"
echo "    - Logout of instance once login ability confirmed"
echo "    - NOTE: This can take about 20 - 80 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip"

run 50

if [ $choice = y ]; then
    attempt=0
    ((seconds=$login_default * $speed / 100))
    while ((attempt++ <= $login_attempts)); do
        sed -i -e "/$public_ip/d" /root/.ssh/known_hosts
        ssh-keyscan $public_ip 2> /dev/null >> /root/.ssh/known_hosts

        echo
        echo "# ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip"
        if [ $interactive = 1 ]; then
            ssh -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip
            RC=$?
        else
            ssh -T -i /root/creds/$demo_account/admin/admin-demo.pem $user@$public_ip << EOF
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

run 50

if [ $choice = y ]; then
    echo
    echo "# cat $scriptsdir/$prefix-user-data-2.sh"
    cat $scriptsdir/$prefix-user-data-2.sh

    next 150
fi


((++step))
image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)
user=root

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
echo "euscale-create-launch-config DemoLC-2 --image-id $image_id --instance-type m1.small --monitoring-enabled \\"
echo "                                      --key=admin-demo --group=DemoSG \\"
echo "                                      --user-data-file=$scriptsdir/$prefix-user-data-2.sh"
echo
echo "euscale-describe-launch-configs DemoLC"
echo "euscale-describe-launch-configs DemoLC-2"

run

if [ $choice = y ]; then
    echo
    echo "# euscale-create-launch-config DemoLC-2 --image-id $image_id --instance-type m1.small --monitoring-enabled \\"
    echo ">                                       --key=admin-demo --group=DemoSG \\"
    echo ">                                       --user-data-file=$scriptsdir/$prefix-user-data-2.sh"
    euscale-create-launch-config DemoLC-2 --image-id $image_id --instance-type m1.small --monitoring-enabled \
                                          --key=admin-demo --group=DemoSG \
                                          --user-data-file=$scriptsdir/$prefix-user-data-2.sh
    pause

    echo "# euscale-describe-launch-configs DemoLC"
    euscale-describe-launch-configs DemoLC
    echo "# euscale-describe-launch-configs DemoLC-2"
    euscale-describe-launch-configs DemoLC-2

    next
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

run

if [ $choice = y ]; then
    echo
    echo "# euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2"
    euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2
    pause

    echo "# euscale-describe-auto-scaling-groups DemoASG"
    euscale-describe-auto-scaling-groups DemoASG

    next
fi


((++step))
instance_ids="$(euscale-describe-auto-scaling-groups DemoASG | grep "^INSTANCE" | cut -f2)"

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
echo "    - NOTE: This can take about 120 - 180 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
for instance_id in $instance_ids; do
    echo
    echo "euscale-terminate-instance-in-auto-scaling-group $instance_id -D --show-long"
    echo
    echo "euscale-describe-auto-scaling-groups DemoASG"
    echo
    echo "eulb-describe-instance-health DemoELB (repeat until both instances are back is \"InService\")"
    break    # breaking here due to an apparent fidelity bug, deleting one instance, deletes the second once the first is back in service
done

run 150

if [ $choice = y ]; then
    for instance_id in $instance_ids; do
        echo
        echo "# euscale-terminate-instance-in-auto-scaling-group $instance_id -D --show-long"
        euscale-terminate-instance-in-auto-scaling-group $instance_id -D --show-long
        pause

        attempt=0
        ((seconds=$replace_default * $speed / 100))
        while ((attempt++ <= replace_attempts)); do
            echo
            echo "# euscale-describe-auto-scaling-groups DemoASG"
            euscale-describe-auto-scaling-groups DemoASG
            echo
            echo "# eulb-describe-instance-health DemoELB"
            eulb-describe-instance-health DemoELB | tee $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-instance-health.out
            
            if [ $(grep -c "InService" $tmpdir/$prefix-$(printf '%02d' $step)-eulb-describe-instance-health.out) -ge 2 ]; then
                break
            else
                echo
                echo -n "At least 2 instances are not \"InService\". Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done
        break    # breaking here due to an apparent fidelity bug, deleting one instance, deletes the second once the first is back in service
    done

    next
fi


# Initially, I think I'm going to want to bail on this demo at this point,
# instead of tearing down all resources created to get back to the initial
# configuration, to save time and move onto the CloudFormation demo.

end=$(date +%s)

echo
echo "Eucalyptus SecurityGroup, ElasticLoadBalancer, LaunchConfiguration,"
echo "           AutoScalingGroup and User-Data Script testing complete (time: $(date -u -d @$((end-start)) +"%T"))"
exit

# Add steps to unwind demo objects here, by deleting everything created above in reverse order
# Then list remaining resources to insure system is as it was before starting demo, so this demo
# is repeatable in the same account

((++step))
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
echo
echo "euscale-describe-launch-configs"
echo
echo "euscale-describe-auto-scaling-groups"
echo
echo "euwatch-describe-alarms"

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

    echo "# eulb-describe-lbs"
    eulb-describe-lbs
    pause

    echo "# euca-describe-instances"
    euca-describe-instances
    pause

    echo "# euscale-describe-launch-configs"
    euscale-describe-launch-configs
    pause

    echo "# euscale-describe-auto-scaling-groups"
    euscale-describe-auto-scaling-groups
    pause

    echo "# euwatch-describe-alarms"
    euwatch-describe-alarms

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus SecurityGroup, ElasticLoadBalancer, LaunchConfiguration,"
echo "           AutoScalingGroup and User-Data Script testing complete (time: $(date -u -d @$((end-start)) +"%T"))"
