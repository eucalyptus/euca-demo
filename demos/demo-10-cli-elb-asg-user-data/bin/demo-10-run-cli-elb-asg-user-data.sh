#/bin/bash
#
# This script runs a Eucalyptus CLI demo which creates a SecurityGroup,
# ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScaleUp and ScaleDown 
# ScalingPolicies and associated CloudWatch Alarms, and Instances associated with
# the LaunchConfiguration which use a user-data script for configuration.
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
scriptsdir=${bindir%/*}/scripts
tmpdir=/var/tmp
prefix=demo-10

image_name=CentOS-6-x86_64-GenericCloud

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

create_attempts=12
create_default=20
login_attempts=12
login_default=20
replace_attempts=12
replace_default=20
delete_attempts=12
delete_default=20

interactive=1
speed=100
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-admin}
instances=2


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-n instances]"
    echo "                [-r region ] [-a account] [-u user]"
    echo "  -I            non-interactive"
    echo "  -s            slower: increase pauses by 25%"
    echo "  -f            faster: reduce pauses by 25%"
    echo "  -v            verbose"
    echo "  -n instances  Number of Instances in AutoScale Group (default: $instances)"
    echo "  -r region     Region (default: $region)"
    echo "  -a account    Account (default: $account)"
    echo "  -u user       User (default: $user)"
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

while getopts Isfvn:r:a:u:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    n)  instances="$OPTARG";;
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

if [ -z $instances ]; then
    echo "-n instances missing!"
    echo "Could not automatically determine instances, and it was not specified as a parameter"
    exit 30
else
    case $instances in
      2|4|6|8|10|20)
        ;;
      *)
        echo "-n $instances invalid: allowed values: 2, 4, 6, 8, 10, 20"
        exit 31;;
    esac
fi

user_region=$region-$account-$user@$region

if ! grep -s -q "\[user $region-$account-$user]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Demo ($account) Account Demo ($user) User Euca2ools user!"
    echo "Expected to find: [user $region-$account-$user] in ~/.euca/$region.ini"
    exit 50
fi

if ! which lynx > /dev/null; then
    echo "lynx missing: This demo uses the lynx text-mode browser to confirm webpage content"
    case $(uname) in
      Darwin)
        echo "- Lynx for OSX can be found here: http://habilis.net/lynxlet/"
        echo "- Follow instructions to install and create /usr/bin/lynx symlink";;
      *)
        echo "- yum install -y lynx";;
    esac

    exit 98
fi

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


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
    echo "                     --region $user_region | cut -f1,2,3"
    echo
    echo "euca-describe-keypairs --filter \"key-name=demo\" \\"
    echo "                       --region $user_region"

    next

    echo
    echo "# euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
    echo ">                      --region $user_region | cut -f1,2,3"
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region $user_region | cut -f1,2,3 | grep "$image_name" || euca_demo_initialized=n
    pause

    echo "# euca-describe-keypairs --filter \"key-name=demo\"\\"
    echo ">                      --region $user_region"
    euca-describe-keypairs --filter "key-name=demo" \
                           --region $user_region | grep "demo" || euca_demo_initialized=n

    next

else
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                         --region $user_region | cut -f1,2,3 | grep -s -q "$image_name" || euca_demo_initialized=n
    euca-describe-keypairs --filter "key-name=demo" \
                           --region $user_region | grep -s -q "demo" || euca_demo_initialized=n
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
    echo "$(printf '%2d' $step). List existing Resources"
    echo "    - So we can compare with what this demo creates"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-groups --region $user_region"
    echo
    echo "eulb-describe-lbs --region $user_region"
    echo
    echo "euca-describe-instances --region $user_region"
    echo
    echo "euscale-describe-launch-configs --region $user_region"
    echo
    echo "euscale-describe-auto-scaling-groups --region $user_region"
    echo
    echo "euscale-describe-policies --region $user_region"
    echo
    echo "euwatch-describe-alarms --region $user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups --region $user_region"
        euca-describe-groups --region $user_region
        pause

        echo "# eulb-describe-lbs --region $user_region"
        eulb-describe-lbs --region $user_region
        pause

        echo "# euca-describe-instances --region $user_region"
        euca-describe-instances --region $user_region
        pause

        echo "# euscale-describe-launch-configs --region $user_region"
        euscale-describe-launch-configs --region $user_region
        pause

        echo "# euscale-describe-auto-scaling-groups --region $user_region"
        euscale-describe-auto-scaling-groups --region $user_region
        pause

        echo "# euscale-describe-policies --region $user_region"
        euscale-describe-policies --region $user_region
        pause

        echo "# euwatch-describe-alarms --region $user_region"
        euwatch-describe-alarms --region $user_region

        next
    fi
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
echo "euca-create-group --description \"Demo Security Group\" \\"
echo "                  --region $user_region \\"
echo "                  DemoSG"
echo
echo "euca-authorize --protocol icmp --icmp-type-code -1:-1 --cidr 0.0.0.0/0 \\"
echo "               --region $user_region \\"
echo "               DemoSG"
echo
echo "euca-authorize --protocol tcp --port-range 22 --cidr 0.0.0.0/0 \\"
echo "               --region $user_region \\"
echo "               DemoSG"
echo
echo "euca-authorize --protocol tcp --port-range 80 --cidr 0.0.0.0/0 \\"
echo "               --region $user_region \\"
echo "               DemoSG"
echo
echo "euca-describe-groups --region $user_region DemoSG"

if euca-describe-groups --region $user_region DemoSG 2> /dev/null | grep -s -q "^GROUP"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-group --description \"Demo Security Group\" \\"
        echo ">                   --region $user_region \\"
        echo ">                   DemoSG"
        euca-create-group --description "Demo Security Group" \
                          --region $user_region \
                          DemoSG
        pause

        echo "# euca-authorize --protocol icmp --icmp-type-code -1:-1 --cidr 0.0.0.0/0 \\"
        echo ">                --region $user_region \\"
        echo ">                DemoSG"
        euca-authorize --protocol icmp --icmp-type-code -1:-1 --cidr 0.0.0.0/0 \
                       --region $user_region \
                       DemoSG
        pause

        echo "# euca-authorize --protocol tcp --port-range 22 --cidr 0.0.0.0/0 \\"
        echo ">                --region $user_region \\"
        echo ">                DemoSG"
        euca-authorize --protocol tcp --port-range 22 --cidr 0.0.0.0/0 \
                       --region $user_region \
                       DemoSG
        pause

        echo "# euca-authorize --protocol tcp --port-range 80 --cidr 0.0.0.0/0 \\"
        echo ">                --region $user_region \\"
        echo ">                DemoSG"
        euca-authorize --protocol tcp --port-range 80 --cidr 0.0.0.0/0 \
                       --region $user_region \
                       DemoSG
        pause

        echo "# euca-describe-groups --region $user_region DemoSG"
        euca-describe-groups --region $user_region DemoSG

        next
    fi
fi


((++step))
zone=$(euca-describe-availability-zones --region $user_region | head -1 | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create an ElasticLoadBalancer"
echo "    - Configure Health Check"
echo "    - Wait for the ELB to become visible in DNS queries"
echo "    - NOTE: This can take about 100 - 140 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "eulb-create-lb --availability-zones $zone \\"
echo "               --listener \"lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP\" \\"
echo "               --region $user_region \\"
echo "               DemoELB"
echo
echo "eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 \\"
echo "                           --interval 15 --timeout 30 \\"
echo "                           --target http:80/index.html \\"
echo "                           --region $user_region \\"
echo "                           DemoELB"
echo
echo "eulb-describe-lbs --region $user_region DemoELB"

if eulb-describe-lbs --region $user_region DemoELB 2> /dev/null | grep -s -q "^LOAD_BALANCER"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# eulb-create-lb --availability-zones $zone \\"
        echo ">                --listener \"lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP\" \\"
        echo ">                --region $user_region \\"
        echo ">                DemoELB"
        eulb-create-lb --availability-zones $zone \
                       --listener "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" \
                       --region $user_region \
                       DemoELB
        pause

        echo "# eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 \\"
        echo ">                            --interval 15 --timeout 30 \\"
        echo ">                            --target http:80/index.html \\"
        echo ">                            --region $user_region \\"
        echo ">                            DemoELB"
        eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 \
                                   --interval 15 --timeout 30 \
                                   --target http:80/index.html \
                                   --region $user_region \
                                   DemoELB
        pause

        echo "# eulb-describe-lbs --region $user_region  DemoELB"
        eulb-describe-lbs --region $user_region DemoELB

        lb_name=$(eulb-describe-lbs --region $user_region DemoELB | cut -f3)
        ((seconds=$create_default * $speed / 100))
        while ((attempt++ <= $create_attempts)); do
            echo
            echo "# dig +short $lb_name"
            lb_public_ip=$(dig +short $lb_name)
            if [ -n "$lb_public_ip" ]; then
                echo $lb_public_ip
                break
            else
                echo
                echo -n "Not available. Waiting $seconds seconds..."
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
    echo "more $scriptsdir/$prefix-user-data-1.sh"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# more $scriptsdir/$prefix-user-data-1.sh"
        if [ $interactive = 1 ]; then
            more $scriptsdir/$prefix-user-data-1.sh
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
            done < $scriptsdir/$prefix-user-data-1.sh
        fi

        next 200
    fi
fi


((++step))
image_id=$(euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                                --region $user_region | cut -f2)
# Workaround 4.1.2 bug EUCA-11052, to prevent multiple arns in the result, must filter by account number
account_id=$(euare-usergetattributes --region $user_region | grep "^arn" | cut -d ':' -f5)
instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos --region $user_region | grep $account_id | grep "Demos$")
#instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos --region $user_region | grep "Demos$")
ssh_key=demo

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create a LaunchConfiguration"
echo "    - Include the Demos Instance Profile, allowing Instance use of S3"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-create-launch-config --image-id $image_id --key=$ssh_key \\"
echo "                             --group=DemoSG \\"
echo "                             --user-data-file=$scriptsdir/$prefix-user-data-1.sh \\"
echo "                             --instance-type m1.small \\"
echo "                             --iam-instance-profile $instance_profile_arn \\"
echo "                             --region $user_region \\"     
echo "                             DemoLC"
echo
echo "euscale-describe-launch-configs --region $user_region DemoLC"

if euscale-describe-launch-configs --region $user_region DemoLC 2> /dev/null | grep -s -q "^LAUNCH-CONFIG"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# euscale-create-launch-config --image-id $image_id --key=$ssh_key \\"
        echo ">                              --group=DemoSG \\"
        echo ">                              --user-data-file=$scriptsdir/$prefix-user-data-1.sh \\"
        echo ">                              --instance-type m1.small \\"
        echo ">                              --iam-instance-profile $instance_profile_arn \\"
        echo ">                              --region $user_region \\"
        echo ">                              DemoLC"
        euscale-create-launch-config --image-id $image_id --key=$ssh_key \
                                     --group=DemoSG \
                                     --user-data-file=$scriptsdir/$prefix-user-data-1.sh \
                                     --instance-type m1.small \
                                     --iam-instance-profile $instance_profile_arn \
                                     --region $user_region \
                                     DemoLC
        pause

        echo "# euscale-describe-launch-configs --region $user_region DemoLC"
        euscale-describe-launch-configs --region $user_region DemoLC

        next
    fi
fi


((++step))
zone=$(euca-describe-availability-zones --region $user_region | head -1 | cut -f2)

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
echo "euscale-create-auto-scaling-group --launch-configuration DemoLC \\"
echo "                                  --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \\"
echo "                                  --default-cooldown 60 \\"
echo "                                  --availability-zones $zone \\"
echo "                                  --load-balancers DemoELB \\"
echo "                                  --health-check-type ELB \\"
echo "                                  --grace-period 300 \\"
echo "                                  --region $user_region \\"
echo "                                  DemoASG"
echo
echo "euscale-describe-auto-scaling-groups --region $user_region DemoASG"
echo
echo "eulb-describe-instance-health --region $user_region DemoELB"

if euscale-describe-auto-scaling-groups --region $user_region DemoASG 2> /dev/null | grep -s -q "^AUTO-SCALING-GROUP"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# euscale-create-auto-scaling-group --launch-configuration DemoLC \\"
        echo ">                                   --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \\"
        echo ">                                   --default-cooldown 60 \\"
        echo ">                                   --availability-zones $zone \\"
        echo ">                                   --load-balancers DemoELB \\"
        echo ">                                   --health-check-type ELB \\"
        echo ">                                   --grace-period 300 \\"
        echo ">                                   --region $user_region \\"
        echo ">                                   DemoASG"
        euscale-create-auto-scaling-group --launch-configuration DemoLC \
                                          --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \
                                          --default-cooldown 60 \
                                          --availability-zones $zone \
                                          --load-balancers DemoELB \
                                          --health-check-type ELB \
                                          --grace-period 300 \
                                          --region $user_region \
                                          DemoASG
        pause

        echo "# euscale-describe-auto-scaling-groups --region $user_region DemoASG"
        euscale-describe-auto-scaling-groups --region $user_region DemoASG
        pause

        echo "# eulb-describe-instance-health --region $user_region DemoELB"
        eulb-describe-instance-health --region $user_region DemoELB

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Scaling Policies"
echo "    - Create a scale up policy"
echo "    - Create a scale down policy"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euscale-put-scaling-policy --auto-scaling-group DemoASG \\"
echo "                           --adjustment=1 --type ChangeInCapacity \\"
echo "                           --region $user_region \\"
echo "                           DemoScaleUpPolicy"
echo
echo "euscale-put-scaling-policy --auto-scaling-group DemoASG \\"
echo "                           --adjustment=-1 --type ChangeInCapacity \\"
echo "                           --region $user_region \\"
echo "                           DemoScaleDownPolicy"
echo
echo "euscale-describe-policies --region $user_region DemoScaleUpPolicy DemoScaleDownPolicy"

if [ $(euscale-describe-policies --region $user_region DemoScaleUpPolicy DemoScaleDownPolicy 2> /dev/null | egrep -c "DemoScale(Up|Down)Policy") = 2 ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# euscale-put-scaling-policy --auto-scaling-group DemoASG \\"
        echo ">                            --adjustment=1 --type ChangeInCapacity \\"
        echo ">                            --region $user_region \\"
        echo ">                            DemoScaleUpPolicy"
        euscale-put-scaling-policy --auto-scaling-group DemoASG \
                                   --adjustment=1 --type ChangeInCapacity \
                                   --region $user_region \
                                   DemoScaleUpPolicy
        pause

        echo "# euscale-put-scaling-policy --auto-scaling-group DemoASG \\"
        echo ">                            --adjustment=-1 --type ChangeInCapacity \\"
        echo ">                            --region $user_region \\"
        echo ">                            DemoScaleDownPolicy"
        euscale-put-scaling-policy --auto-scaling-group DemoASG \
                                   --adjustment=-1 --type ChangeInCapacity \
                                   --region $user_region \
                                   DemoScaleDownPolicy
        pause

        echo "# euscale-describe-policies --region $user_region DemoScaleUpPolicy DemoScaleDownPolicy"
        euscale-describe-policies --region $user_region DemoScaleUpPolicy DemoScaleDownPolicy

        next
    fi
fi


((++step))
up_policy_arn=$(euscale-describe-policies --region $user_region DemoScaleUpPolicy | cut -f6)
down_policy_arn=$(euscale-describe-policies --region $user_region DemoScaleDownPolicy | cut -f6)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create CloudWatch Alarms and Associate with Scaling Policies"
echo "    - Create a high-cpu alarm which triggers the scale up policy"
echo "    - Create a low-cpu alarm which triggers the scale down policy"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euwatch-put-metric-alarm --alarm-description \"Scale Up DemoELB by 1 when CPU >= 50%\" \\"
echo "                         --alarm-actions $up_policy_arn \\"
echo "                         --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
echo "                         --statistic Average --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                         --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \\"
echo "                         --comparison-operator GreaterThanOrEqualToThreshold \\"
echo "                         --region $user_region \\"
echo "                         DemoCPUHighAlarm"
echo
echo "euwatch-put-metric-alarm --alarm-description \"Scale Down DemoELB by 1 when CPU <= 10%\" \\"
echo "                         --alarm-actions $down_policy_arn \\"
echo "                         --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
echo "                         --statistic Average --dimensions \"AutoScalingGroupName=DemoASG\" \\"
echo "                         --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \\"
echo "                         --comparison-operator LessThanOrEqualToThreshold \\"
echo "                         --region $user_region \\"
echo "                         DemoCPULowAlarm"
echo
echo "euwatch-describe-alarms --region $user_region DemoCPUHighAlarm DemoCPULowAlarm"

if [ $(euwatch-describe-alarms --region $user_region DemoCPUHighAlarm DemoCPULowAlarm 2> /dev/null | egrep -c "DemoCPU(High|Low)Alarm") = 2 ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# euwatch-put-metric-alarm --alarm-description \"Scale Up DemoELB by 1 when CPU >= 50%\" \\"
        echo ">                          --alarm-actions $up_policy_arn \\"
        echo ">                          --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
        echo ">                          --statistic Average --dimensions \"AutoScalingGroupName=DemoASG\" \\"
        echo ">                          --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \\"
        echo ">                          --comparison-operator GreaterThanOrEqualToThreshold \\"
        echo ">                          --region $user_region \\"
        echo ">                          DemoCPUHighAlarm"
        euwatch-put-metric-alarm --alarm-description "Scale Up DemoELB by 1 when CPU >= 50%" \
                                 --alarm-actions $up_policy_arn \
                                 --metric-name CPUUtilization --namespace "AWS/EC2" \
                                 --statistic Average --dimensions "AutoScalingGroupName=DemoASG" \
                                 --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \
                                 --comparison-operator GreaterThanOrEqualToThreshold \
                                 --region $user_region \
                                 DemoCPUHighAlarm
        pause

        echo "# euwatch-put-metric-alarm --alarm-description \"Scale Down DemoELB by 1 when CPU <= 10%\" \\"
        echo ">                          --alarm-actions $down_policy_arn \\"
        echo ">                          --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
        echo ">                          --statistic Average --dimensions \"AutoScalingGroupName=DemoASG\" \\"
        echo ">                          --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \\"
        echo ">                          --comparison-operator LessThanOrEqualToThreshold \\"
        echo ">                          --region $user_region \\"
        echo ">                          DemoCPULowAlarm"
        euwatch-put-metric-alarm --alarm-description "Scale Down DemoELB by 1 when CPU <= 10%" \
                                 --alarm-actions $down_policy_arn \
                                 --metric-name CPUUtilization --namespace "AWS/EC2" \
                                 --statistic Average --dimensions "AutoScalingGroupName=DemoASG" \
                                 --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \
                                 --comparison-operator LessThanOrEqualToThreshold \
                                 --region $user_region \
                                 DemoCPULowAlarm
        pause

        echo "# euwatch-describe-alarms --region $user_region DemoCPUHighAlarm DemoCPULowAlarm"
        euwatch-describe-alarms --region $user_region DemoCPUHighAlarm DemoCPULowAlarm

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
    echo "    - Note addition of new SecurityGroup, ElasticLoadBalancer,"
    echo "      Instances, LaunchConfiguration, AutoScaleGroup, Policies,"
    echo "      and Alarms"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-groups --region $user_region"
    echo
    echo "eulb-describe-lbs --region $user_region"
    echo
    echo "euca-describe-instances --region $user_region"
    echo
    echo "euscale-describe-launch-configs --region $user_region"
    echo
    echo "euscale-describe-auto-scaling-groups --region $user_region"
    echo
    echo "euscale-describe-policies --region $user_region"
    echo
    echo "euwatch-describe-alarms --region $user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-groups --region $user_region"
        euca-describe-groups --region $user_region
        pause

        echo "# eulb-describe-lbs --region $user_region"
        eulb-describe-lbs --region $user_region
        pause

        echo "# euca-describe-instances --region $user_region"
        euca-describe-instances --region $user_region
        pause

        echo "# euscale-describe-launch-configs --region $user_region"
        euscale-describe-launch-configs --region $user_region
        pause

        echo "# euscale-describe-auto-scaling-groups --region $user_region"
        euscale-describe-auto-scaling-groups --region $user_region
        pause

        echo "# euscale-describe-policies --region $user_region"
        euscale-describe-policies --region $user_region
        pause

        echo "# euwatch-describe-alarms --region $user_region"
        euwatch-describe-alarms --region $user_region

        next
    fi
fi


((++step))
instance_id="$(euscale-describe-auto-scaling-groups --region $user_region DemoASG | grep "^INSTANCE" | tail -1 | cut -f2)"
public_name=$(euca-describe-instances --region $user_region $instance_id | grep "^INSTANCE" | cut -f4)
public_ip=$(euca-describe-instances --region $user_region $instance_id | grep "^INSTANCE" | cut -f17)
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
echo "    - Then view user-data with:"
echo "      # curl http://169.254.169.254/latest/user-data"
echo "    - Logout of instance once login ability confirmed"
echo "    - NOTE: This can take about 20 - 80 seconds"
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


((++step))
instance_ids="$(euscale-describe-auto-scaling-groups --region $user_region DemoASG | grep "^INSTANCE" | cut -f2)"
unset instance_public_names
for instance_id in $instance_ids; do
    instance_public_names="$instance_public_names $(euca-describe-instances --region $user_region $instance_id | grep "^INSTANCE" | cut -f4)"
done
instance_public_names=${instance_public_names# *}

lb_public_name=$(eulb-describe-lbs --region $user_region | cut -f3)
lb_public_ip=$(dig +short $lb_name)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm webpage is visible"
echo "    - Wait for all instances to be \"InService\""
echo "    - Attempt to display webpage first directly via instances,"
echo "      then through the ELB"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "eulb-describe-instance-health --region $user_region DemoELB"
for instance_public_name in $instance_public_names; do
    echo
    echo "lynx -dump http://$instance_public_name"
done
if [ -n "$lb_public_ip" ]; then
    echo
    echo "lynx -dump http://$lb_public_name"
    echo "lynx -dump http://$lb_public_name"
fi

run 50

if [ $choice = y ]; then
    attempt=0
    ((seconds=$create_default * $speed / 100))
    while ((attempt++ <= create_attempts)); do
        echo
        echo "# eulb-describe-instance-health --region $user_region DemoELB"
        instance_health=$(eulb-describe-instance-health --region $user_region DemoELB)
        echo "$instance_health"

        if [ $(echo -n "$instance_health" | grep -c OutOfService) = "0" ]; then
            break
        else
            echo
            echo -n "Some instances are still \"OutOfService\". Waiting $seconds seconds..."
            sleep $seconds
            echo " Done"
        fi
    done
    pause

    echo
    for instance_public_name in $instance_public_names; do
        echo "# lynx -dump http://$instance_public_name"
        lynx -dump http://$instance_public_name
        pause
    done
    if [ -n "$lb_public_ip" ]; then
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name
    fi

    next
fi


((++step))
if [ $verbose = 1 ]; then
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
    echo "more $scriptsdir/$prefix-user-data-2.sh"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# more $scriptsdir/$prefix-user-data-2.sh"
        if [ $interactive = 1 ]; then
            more $scriptsdir/$prefix-user-data-2.sh
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
            done < $scriptsdir/$prefix-user-data-2.sh
        fi

        next 200
    fi
fi


((++step))
image_id=$(euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                                --region $user_region | cut -f2)
# Workaround 4.1.2 bug EUCA-11052, to prevent multiple arns in the result, must filter by account number
account_id=$(euare-usergetattributes --region $user_region | grep "^arn" | cut -d ':' -f5)
instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos --region $user_region | grep $account_id | grep "Demos$")
#instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos --region $user_region | grep "Demos$")
ssh_key=demo

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
echo "euscale-create-launch-config --image-id $image_id --key=$ssh_key \\"
echo "                             --group=DemoSG \\"
echo "                             --user-data-file=$scriptsdir/$prefix-user-data-2.sh \\"
echo "                             --instance-type m1.small \\"
echo "                             --iam-instance-profile $instance_profile_arn \\"
echo "                             --region $user_region \\"
echo "                             DemoLC-2"
echo
echo "euscale-describe-launch-configs --region $user_region DemoLC DemoLC-2"

if euscale-describe-launch-configs --region $user_region DemoLC-2 2> /dev/null | grep -s -q "^LAUNCH-CONFIG"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# euscale-create-launch-config --image-id $image_id --key=$ssh_key \\"
        echo ">                              --group=DemoSG \\"
        echo ">                              --user-data-file=$scriptsdir/$prefix-user-data-2.sh \\"
        echo ">                              --instance-type m1.small \\"
        echo ">                              --iam-instance-profile $instance_profile_arn \\"
        echo ">                              --region $user_region \\"
        echo ">                              DemoLC-2"
        euscale-create-launch-config --image-id $image_id --key=$ssh_key \
                                     --group=DemoSG \
                                     --user-data-file=$scriptsdir/$prefix-user-data-2.sh \
                                     --instance-type m1.small \
                                     --iam-instance-profile $instance_profile_arn \
                                     --region $user_region \
                                     DemoLC-2
        pause

        echo "# euscale-describe-launch-configs --region $user_region DemoLC DemoLC-2"
        euscale-describe-launch-configs --region $user_region DemoLC DemoLC-2

        next
    fi
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
echo "euscale-update-auto-scaling-group --launch-configuration DemoLC-2 \\"
echo "                                  --region $user_region \\"
echo "                                  DemoASG"
echo
echo "euscale-describe-auto-scaling-groups --region $user_region DemoASG"

if [ "$(euscale-describe-auto-scaling-groups --region $user_region DemoASG 2> /dev/null | grep "^AUTO-SCALING-GROUP" | cut -f3)" = "DemoLC-2" ]; then
    echo
    tput rev
    echo "Already Updated!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# euscale-update-auto-scaling-group --launch-configuration DemoLC-2 \\"
        echo ">                                   --region $user_region i\\"
        echo ">                                   DemoASG"
        euscale-update-auto-scaling-group --launch-configuration DemoLC-2 \
                                          --region $user_region \
                                          DemoASG
        pause

        echo "# euscale-describe-auto-scaling-groups --region $user_region DemoASG"
        euscale-describe-auto-scaling-groups --region $user_region DemoASG

        next
    fi
fi


((++step))
instance_ids="$(euscale-describe-auto-scaling-groups --region $user_region DemoASG | grep "^INSTANCE" | cut -f2)"

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Trigger AutoScalingGroup Instance Replacement"
echo "    - We will terminate an existing Instance of the AutoScalingGroup,"
echo "      and confirm a replacement Instance is created with the new"
echo "      LaunchConfiguration and User-Data Script"
echo "    - Wait for a replacement instance to be \"InService\""
echo "    - When done, one instance will use the new LaunchConfiguration,"
echo "      while the other(s) will still use the old LaunchConfiguration"
echo "      (normally we'd iterate through all instances when updating the application)"
echo "    - NOTE: This can take about 140 - 200 seconds (per instance)"
echo
echo "============================================================"
echo
echo "Commands:"
for instance_id in $instance_ids; do
    echo
    echo "euscale-terminate-instance-in-auto-scaling-group --no-decrement-desired-capacity \\"
    echo "                                                 --show-long \\"
    echo "                                                 --region $user_region \\"
    echo "                                                 $instance_id"
    echo
    echo "euscale-describe-auto-scaling-groups --region $user_region DemoASG"
    echo
    echo "eulb-describe-instance-health --region $user_region DemoELB"
    break    # delete only one at this time
done

run 150

if [ $choice = y ]; then
    for instance_id in $instance_ids; do
        echo
        echo "# euscale-terminate-instance-in-auto-scaling-group --no-decrement-desired-capacity \\"
        echo ">                                                  --show-long \\"
        echo ">                                                  --region $user_region \\"
        echo ">                                                  $instance_id"
        euscale-terminate-instance-in-auto-scaling-group --no-decrement-desired-capacity \
                                                         --show-long \
                                                         --region $user_region \
                                                         $instance_id
        pause

        attempt=0
        ((seconds=$replace_default * $speed / 100))
        while ((attempt++ <= replace_attempts)); do
            echo
            echo "# euscale-describe-auto-scaling-groups --region $user_region DemoASG"
            euscale-describe-auto-scaling-groups --region $user_region DemoASG
            echo
            echo "# eulb-describe-instance-health --region $user_region DemoELB"
            instance_health=$(eulb-describe-instance-health --region $user_region DemoELB)
            echo "$instance_health"

            if [ $(echo -n "$instance_health" | grep -c InService) -ge $instances ]; then
                break
            else
                echo
                echo -n "Still waiting for $instances Instances to be \"InService\". Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done
        break    # delete only one at this time
    done

    next 50
fi


((++step))
instance_ids="$(euscale-describe-auto-scaling-groups --region $user_region DemoASG | grep "^INSTANCE" | cut -f2)"
unset instance_public_names
for instance_id in $instance_ids; do
    instance_public_names="$instance_public_names $(euca-describe-instances --region $user_region $instance_id | grep "^INSTANCE" | cut -f4)"
done
instance_public_names=${instance_public_names# *}

lb_public_name=$(eulb-describe-lbs --region $user_region | cut -f3)
lb_public_ip=$(dig +short $lb_public_name)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm updated webpage is visible"
echo "    - Attempt to display webpage first directly via instances,"
echo "      then through the ELB"
echo
echo "============================================================"
echo
echo "Commands:"
for instance_public_name in $instance_public_names; do
    echo
    echo "lynx -dump http://$instance_public_name"
done
if [ -n "$lb_public_ip" ]; then
    echo
    echo "lynx -dump http://$lb_public_name"
    echo "lynx -dump http://$lb_public_name"
fi

run 50

if [ $choice = y ]; then
    echo
    for instance_public_name in $instance_public_names; do
        echo "# lynx -dump http://$instance_public_name"
        lynx -dump http://$instance_public_name
        pause
    done
    if [ -n "$lb_public_ip" ]; then
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name
    fi

    next
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo execution complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CLI: ELB + ASG + User-Data demo execution complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
