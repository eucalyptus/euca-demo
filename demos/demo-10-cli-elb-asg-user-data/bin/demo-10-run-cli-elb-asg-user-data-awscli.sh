#/bin/bash
#
# This script runs a Eucalyptus CLI demo which creates a SecurityGroup,
# ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScaleUp and ScaleDown
# ScalingPolicies and associated CloudWatch Alarms, and Instances associated with
# the LaunchConfiguration which use a user-data script for configuration.
#
# This is a variant of the demo-10-run-cli-elb-asg-user-data.sh script which primarily uses the AWSCLI.
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

profile=$region-$account-$user

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($region) Region Demo ($account) Account Demo ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 51
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
    echo "aws ec2 describe-images --filter \"Name=manifest-location,Values=images/$image_name.raw.manifest.xml\" \\"
    echo "                        --profile $profile --region $region --output text | cut -f1,3,4"
    echo
    echo "aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\" \\"
    echo "                           --profile $profile --region $region --output text"

    next

    echo
    echo "# aws ec2 describe-images --filter \"Name=manifest-location,Values=images/$image_name.raw.manifest.xml\" \\"
    echo ">                         --profile $profile --region $region --output text | cut -f1,3,4"
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                            --profile $profile --region $region --output text | cut -f1,3,4  | grep  "$image_name" || demo_initialized=n
    pause

    echo "# aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\" \\"
    echo ">                            --profile $profile --region $region --output text"
    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile $profile --region $region --output text | grep "demo" || demo_initialized=n

    next

else
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                            --profile $profile --region $region --output text | cut -f1,3,4  | grep -s -q  "$image_name" || demo_initialized=n
    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile $profile --region $region --output text | grep -s -q "demo" || demo_initialized=n
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
    echo "aws ec2 describe-security-groups --profile $profile --region $region --output text"
    echo
    echo "aws elb describe-load-balancers --profile $profile --region $region --output text"
    echo
    echo "aws ec2 describe-instances --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-launch-configurations --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-policies --profile $profile --region $region --output text"
    echo
    echo "aws cloudwatch describe-alarms --profile $profile --region $region --output text"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-security-groups --profile $profile --region $region --output text"
        aws ec2 describe-security-groups --profile $profile --region $region --output text
        pause

        echo "# aws elb describe-load-balancers --profile $profile --region $region --output text"
        aws elb describe-load-balancers --profile $profile --region $region --output text
        pause

        echo "# aws ec2 describe-instances --profile $profile --region $region --output text"
        aws ec2 describe-instances --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-launch-configurations --profile $profile --region $region --output text"
        aws autoscaling describe-launch-configurations --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text"
        aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-policies --profile $profile --region $region --output text"
        aws autoscaling describe-policies --profile $profile --region $region --output text
        pause

        echo "# aws cloudwatch describe-alarms --profile $profile --region $region --output text"
        aws cloudwatch describe-alarms --profile $profile --region $region --output text

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
echo "aws ec2 create-security-group --group-name DemoSG --description \"Demo Security Group\" \\"
echo "                              --profile $profile --region $region --output text"
echo
echo "aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol icmp --port -1 --cidr 0.0.0.0/0 \\"
echo "                                         --profile $profile --region $region --output text"
echo
echo "aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 22 --cidr 0.0.0.0/0 \\"
echo "                                         --profile $profile --region $region --output text"
echo
echo "aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 80 --cidr 0.0.0.0/0 \\"
echo "                                         --profile $profile --region $region --output text"
echo
echo "aws ec2 describe-security-groups --filters \"Name=group-name,Values=DemoSG\" \\"
echo "                                 --profile $profile --region $region --output text"

if aws ec2 describe-security-groups --filters "Name=group-name,Values=DemoSG" \
                                    --profile $profile --region $region --output text 2> /dev/null | grep -s -q "^SECURITYGROUPS"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 create-security-group --group-name DemoSG --description \"Demo Security Group\" \\"
        echo ">                               --profile $profile --region $region --output text"
        aws ec2 create-security-group --group-name DemoSG --description "Demo Security Group" \
                                      --profile $profile --region $region --output text
        pause

        echo "# aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol icmp --port -1 --cidr 0.0.0.0/0 \\"
        echo ">                                          --profile $profile --region $region --output text"
        aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol icmp --port -1 --cidr 0.0.0.0/0 \
                                                 --profile $profile --region $region --output text
        pause

        echo "# aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 22 --cidr 0.0.0.0/0 \\"
        echo ">                                          --profile $profile --region $region --output text"
        aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 22 --cidr 0.0.0.0/0 \
                                                 --profile $profile --region $region --output text
        pause

        echo "# aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 80 --cidr 0.0.0.0/0 \\"
        echo ">                                          --profile $profile --region $region --output text"
        aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 80 --cidr 0.0.0.0/0 \
                                                 --profile $profile --region $region --output text
        pause

        echo "# aws ec2 describe-security-groups --filters \"Name=group-name,Values=DemoSG\" \\"
        echo ">                                  --profile $profile --region $region --output text"
        aws ec2 describe-security-groups --filters "Name=group-name,Values=DemoSG" \
                                         --profile $profile --region $region --output text

        next
    fi
fi


((++step))
zone=$(aws ec2 describe-availability-zones --profile $profile --region $region --output text | head -1 | cut -f4)

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
echo "aws elb create-load-balancer --load-balancer-name DemoELB \\"
echo "                             --listeners \"Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80\" \\"
echo "                             --availability-zones $zone \\"
echo "                             --profile $profile --region $region --output text"
echo
echo "aws elb configure-health-check --load-balancer-name DemoELB \\"
echo "                               --health-check \"Target=http:80/index.html,Interval=15,Timeout=30,UnhealthyThreshold=2,HealthyThreshold=2\" \\"
echo "                               --profile $profile --region $region --output text"
echo
echo "aws elb describe-load-balancers --load-balancer-names DemoELB \\"
echo "                                --profile $profile --region $region --output text"

if aws elb describe-load-balancers --load-balancer-names DemoELB \
                                   --query 'LoadBalancerDescriptions[].LoadBalancerName' \
                                   --profile $profile --region $region --output text 2> /dev/null | grep -s -q "^DemoELB$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# aws elb create-load-balancer --load-balancer-name DemoELB \\"
        echo ">                              --listeners \"Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80\" \\"
        echo ">                              --availability-zones $zone \\"
        echo ">                              --profile $profile --region $region --output text"
        aws elb create-load-balancer --load-balancer-name DemoELB \
                                     --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
                                     --availability-zones $zone \
                                     --profile $profile --region $region --output text
        pause

        echo "# aws elb configure-health-check --load-balancer-name DemoELB \\"
        echo ">                                --health-check \"Target=http:80/index.html,Interval=15,Timeout=30,UnhealthyThreshold=2,HealthyThreshold=2\" \\"
        echo ">                                --profile $profile --region $region --output text"
        aws elb configure-health-check --load-balancer-name DemoELB \
                                       --health-check "Target=http:80/index.html,Interval=15,Timeout=30,UnhealthyThreshold=2,HealthyThreshold=2" \
                                       --profile $profile --region $region --output text
        pause

        echo "# aws elb describe-load-balancers --load-balancer-names DemoELB \\"
        echo ">                                 --profile $profile --region $region --output text"
        aws elb describe-load-balancers --load-balancer-names DemoELB \
                                        --profile $profile --region $region --output text

        lb_name=$(aws elb describe-load-balancers --load-balancer-names DemoELB \
                                                  --query 'LoadBalancerDescriptions[].DNSName' \
                                                  --profile $profile --region $region --output text)
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
image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                                   --profile $profile --region $region --output text | cut -f3)
# Workaround 4.1.2 bug EUCA-11052, to prevent multiple arns in the result, must filter by account number
account_id=$(aws iam get-user --query 'User.Arn' --profile $profile --region $region | cut -d ':' -f5)
instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
                                                               --profile $profile --region $region --output text | \
                                                               tr "\t" "\n" | grep $account_id | grep "Demos$")
#instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
#                                                               --profile $profile --region $region --output text)
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
echo "aws autoscaling create-launch-configuration --launch-configuration-name DemoLC \\"
echo "                                            --image-id $image_id --key-name=$ssh_key  \\"
echo "                                            --security-groups DemoSG \\"
echo "                                            --user-data file://$scriptsdir/$prefix-user-data-1.sh \\"
echo "                                            --instance-type m1.small \\"
echo "                                            --iam-instance-profile $instance_profile_arn \\"
echo "                                            --profile $profile --region $region --output text"
echo
echo "aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC \\"
echo "                                               --profile $profile --region $region --output text"

if aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC \
                                                  --profile $profile --region $region --output text 2> /dev/null | grep -s -q "^LAUNCHCONFIGURATIONS"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# aws autoscaling create-launch-configuration --launch-configuration-name DemoLC \\"
        echo ">                                             --image-id $image_id --key-name=$ssh_key  \\"
        echo ">                                             --security-groups DemoSG \\"
        echo ">                                             --user-data file://$scriptsdir/$prefix-user-data-1.sh \\"
        echo ">                                             --instance-type m1.small \\"
        echo ">                                             --iam-instance-profile $instance_profile_arn \\"
        echo ">                                             --profile $profile --region $region --output text"
        aws autoscaling create-launch-configuration --launch-configuration-name DemoLC \
                                                    --image-id $image_id --key-name=$ssh_key  \
                                                    --security-groups DemoSG \
                                                    --user-data file://$scriptsdir/$prefix-user-data-1.sh \
                                                    --instance-type m1.small \
                                                    --iam-instance-profile $instance_profile_arn \
                                                    --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC \\"
        echo ">                                                --profile $profile --region $region --output text"
        aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC \
                                                       --profile $profile --region $region --output text

        next
    fi
fi


((++step))
zone=$(aws ec2 describe-availability-zones --profile $profile --region $region --output text | head -1 | cut -f4)

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
echo "aws autoscaling create-auto-scaling-group --auto-scaling-group-name DemoASG \\"
echo "                                          --launch-configuration-name DemoLC \\"
echo "                                          --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \\"
echo "                                          --default-cooldown 60 \\"
echo "                                          --availability-zones $zone \\"
echo "                                          --load-balancer-names DemoELB \\"
echo "                                          --health-check-type ELB \\"
echo "                                          --health-check-grace-period 300 \\"
echo "                                          --profile $profile --region $region --output text"
echo
echo "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
echo "                                             --profile $profile --region $region --output text"
echo
echo "aws elb describe-instance-health --load-balancer-name DemoELB \\"
echo "                                 --profile $profile --region $region --output text"

if aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                --query 'AutoScalingGroups[].AutoScalingGroupName' \
                                                --profile $profile --region $region --output text 2> /dev/null | grep -s -q "^DemoASG"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# aws autoscaling create-auto-scaling-group --auto-scaling-group-name DemoASG \\"
        echo ">                                           --launch-configuration-name DemoLC \\"
        echo ">                                           --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \\"
        echo ">                                           --default-cooldown 60 \\"
        echo ">                                           --availability-zones $zone \\"
        echo ">                                           --load-balancer-names DemoELB \\"
        echo ">                                           --health-check-type ELB \\"
        echo ">                                           --health-check-grace-period 300 \\"
        echo ">                                           --profile $profile --region $region --output text"
        aws autoscaling create-auto-scaling-group --auto-scaling-group-name DemoASG \
                                                  --launch-configuration-name DemoLC \
                                                  --min-size $instances --max-size $((instances*2)) --desired-capacity $instances \
                                                  --default-cooldown 60 \
                                                  --availability-zones $zone \
                                                  --load-balancer-names DemoELB \
                                                  --health-check-type ELB \
                                                  --health-check-grace-period 300 \
                                                  --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
        echo ">                                              --profile $profile --region $region --output text"
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                     --profile $profile --region $region --output text
        pause

        echo "# aws elb describe-instance-health --load-balancer-name DemoELB \\"
        echo ">                                  --profile $profile --region $region --output text"
        aws elb describe-instance-health --load-balancer-name DemoELB \
                                         --profile $profile --region $region --output text

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
echo "aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \\"
echo "                                   --policy-name DemoScaleUpPolicy \\"
echo "                                   --adjustment-type ChangeInCapacity \\"
echo "                                   --scaling-adjustment=1 \\"
echo "                                   --profile $profile --region $region --output text"
echo
echo "aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \\"
echo "                                   --policy-name DemoScaleDownPolicy \\"
echo "                                   --adjustment-type ChangeInCapacity \\"
echo "                                   --scaling-adjustment=-1 \\"
echo "                                   --profile $profile --region $region --output text"
echo
echo "aws autoscaling describe-policies --auto-scaling-group DemoASG \\"
echo "                                  --policy-names DemoScaleUpPolicy DemoScaleDownPolicy \\"
echo "                                  --profile $profile --region $region --output text"

if [ $(aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                         --policy-names DemoScaleUpPolicy DemoScaleDownPolicy \
                                         --profile $profile --region $region --output text 2> /dev/null | egrep -c "DemoScale(Up|Down)Policy") = 2 ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \\"
        echo ">                                    --policy-name DemoScaleUpPolicy \\"
        echo ">                                    --adjustment-type ChangeInCapacity \\"
        echo ">                                    --scaling-adjustment=1 \\"
        echo ">                                    --profile $profile --region $region --output text"
        aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \
                                           --policy-name DemoScaleUpPolicy \
                                           --adjustment-type ChangeInCapacity \
                                           --scaling-adjustment=1 \
                                           --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \\"
        echo ">                                    --policy-name DemoScaleDownPolicy \\"
        echo ">                                    --adjustment-type ChangeInCapacity \\"
        echo ">                                    --scaling-adjustment=-1 \\"
        echo ">                                    --profile $profile --region $region --output text"
        aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \
                                           --policy-name DemoScaleDownPolicy \
                                           --adjustment-type ChangeInCapacity \
                                           --scaling-adjustment=-1 \
                                           --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-policies --auto-scaling-group DemoASG \\"
        echo ">                                   --policy-names DemoScaleUpPolicy DemoScaleDownPolicy \\"
        echo ">                                   --profile $profile --region $region --output text"
        aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                          --policy-names DemoScaleUpPolicy DemoScaleDownPolicy \
                                          --profile $profile --region $region --output text

        next
    fi
fi


((++step))
up_policy_arn=$(aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                                  --policy-names DemoScaleUpPolicy \
                                                  --query 'ScalingPolicies[].PolicyARN' \
                                                  --profile $profile --region $region --output text)
down_policy_arn=$(aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                                    --policy-names DemoScaleDownPolicy \
                                                    --query 'ScalingPolicies[].PolicyARN' \
                                                    --profile $profile --region $region --output text)

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
echo "aws cloudwatch put-metric-alarm --alarm-name DemoCPUHighAlarm \\"
echo "                                --alarm-description \"Scale Up DemoELB by 1 when CPU >= 50%\" \\"
echo "                                --alarm-actions $up_policy_arn \\"
echo "                                --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
echo "                                --statistic Average --dimensions \"Name=AutoScalingGroupName,Value=DemoASG\" \\"
echo "                                --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \\"
echo "                                --comparison-operator GreaterThanOrEqualToThreshold \\"
echo "                                --profile $profile --region $region --output text"
echo
echo "aws cloudwatch put-metric-alarm --alarm-name DemoCPULowAlarm \\"
echo "                                --alarm-description \"Scale Down DemoELB by 1 when CPU <= 10%\" \\"
echo "                                --alarm-actions $down_policy_arn \\"
echo "                                --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
echo "                                --statistic Average --dimensions \"Name=AutoScalingGroupName,Value=DemoASG\" \\"
echo "                                --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \\"
echo "                                --comparison-operator LessThanOrEqualToThreshold \\"
echo "                                --profile $profile --region $region --output text"
echo
echo "aws cloudwatch describe-alarms --alarm-names DemoCPUHighAlarm DemoCPULowAlarm \\"
echo "                               --profile $profile --region $region --output text"

if [ $(aws cloudwatch describe-alarms --alarm-names DemoCPUHighAlarm DemoCPULowAlarm \
                                      --query 'MetricAlarms[].AlarmName' \
                                      --profile $profile --region $region --output text 2> /dev/null | wc -w) = 2 ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 150

    if [ $choice = y ]; then
        echo
        echo "# aws cloudwatch put-metric-alarm --alarm-name DemoCPUHighAlarm \\"
        echo ">                                 --alarm-description \"Scale Up DemoELB by 1 when CPU >= 50%\" \\"
        echo ">                                 --alarm-actions $up_policy_arn \\"
        echo ">                                 --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
        echo ">                                 --statistic Average --dimensions \"Name=AutoScalingGroupName,Value=DemoASG\" \\"
        echo ">                                 --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \\"
        echo ">                                 --comparison-operator GreaterThanOrEqualToThreshold \\"
        echo ">                                 --profile $profile --region $region --output text"
        aws cloudwatch put-metric-alarm --alarm-name DemoCPUHighAlarm \
                                        --alarm-description "Scale Up DemoELB by 1 when CPU >= 50%" \
                                        --alarm-actions $up_policy_arn \
                                        --metric-name CPUUtilization --namespace "AWS/EC2" \
                                        --statistic Average --dimensions "Name=AutoScalingGroupName,Value=DemoASG" \
                                        --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \
                                        --comparison-operator GreaterThanOrEqualToThreshold \
                                        --profile $profile --region $region --output text
        pause

        echo "# aws cloudwatch put-metric-alarm --alarm-name DemoCPULowAlarm \\"
        echo ">                                 --alarm-description \"Scale Down DemoELB by 1 when CPU <= 10%\" \\"
        echo ">                                 --alarm-actions $down_policy_arn \\"
        echo ">                                 --metric-name CPUUtilization --namespace \"AWS/EC2\" \\"
        echo ">                                 --statistic Average --dimensions \"Name=AutoScalingGroupName,Value=DemoASG\" \\"
        echo ">                                 --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \\"
        echo ">                                 --comparison-operator LessThanOrEqualToThreshold \\"
        echo ">                                 --profile $profile --region $region --output text"
        aws cloudwatch put-metric-alarm --alarm-name DemoCPULowAlarm \
                                        --alarm-description "Scale Down DemoELB by 1 when CPU <= 10%" \
                                        --alarm-actions $down_policy_arn \
                                        --metric-name CPUUtilization --namespace "AWS/EC2" \
                                        --statistic Average --dimensions "Name=AutoScalingGroupName,Value=DemoASG" \
                                        --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \
                                        --comparison-operator LessThanOrEqualToThreshold \
                                        --profile $profile --region $region --output text
        pause

        echo "# aws cloudwatch describe-alarms --alarm-names DemoCPUHighAlarm DemoCPULowAlarm \\"
        echo ">                                --profile $profile --region $region --output text"
        aws cloudwatch describe-alarms --alarm-names DemoCPUHighAlarm DemoCPULowAlarm \
                                       --profile $profile --region $region --output text

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
    echo "    - Note addition of new SecurityGroup, ElasticLoadBalancer, "
    echo "      Instances, LaunchConfiguration, AutoScalingGroup, "
    echo "      Scaling Policies and Alarms"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws ec2 describe-security-groups --profile $profile --region $region --output text"
    echo
    echo "aws elb describe-load-balancers --profile $profile --region $region --output text"
    echo
    echo "aws ec2 describe-instances --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-launch-configurations --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-policies --profile $profile --region $region --output text"
    echo
    echo "aws cloudwatch describe-alarms --profile $profile --region $region --output text"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-security-groups --profile $profile --region $region --output text"
        aws ec2 describe-security-groups --profile $profile --region $region --output text
        pause

        echo "# aws elb describe-load-balancers --profile $profile --region $region --output text"
        aws elb describe-load-balancers --profile $profile --region $region --output text
        pause

        echo "# aws ec2 describe-instances --profile $profile --region $region --output text"
        aws ec2 describe-instances --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-launch-configurations --profile $profile --region $region --output text"
        aws autoscaling describe-launch-configurations --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text"
        aws autoscaling describe-auto-scaling-groups --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-policies --profile $profile --region $region --output text"
        aws autoscaling describe-policies --profile $profile --region $region --output text
        pause

        echo "# aws cloudwatch describe-alarms --profile $profile --region $region --output text"
        aws cloudwatch describe-alarms --profile $profile --region $region --output text

        next
    fi
fi


((++step))
instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                           --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                           --profile $profile --region $region --output text | cut -f1)
public_name=$(aws ec2 describe-instances --instance-ids $instance_id \
                                         --query 'Reservations[].Instances[].PublicDnsName' \
                                         --profile $profile --region $region --output text)
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id \
                                       --query 'Reservations[].Instances[].PublicIpAddress' \
                                       --profile $profile --region $region --output text)
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
instance_ids="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                             --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                             --profile $profile --region $region --output text)"
unset instance_public_names
for instance_id in $instance_ids; do
    instance_public_names="$instance_public_names $(aws ec2 describe-instances --instance-ids $instance_id \
                                                                               --query 'Reservations[].Instances[].PublicDnsName' \
                                                                               --profile $profile --region $region --output text)"
done
instance_public_names=${instance_public_names# *}

lb_public_name=$(aws elb describe-load-balancers --load-balancer-names DemoELB \
                                                 --query 'LoadBalancerDescriptions[].DNSName' \
                                                 --profile $profile --region $region --output text)
lb_public_ip=$(dig +short $lb_public_name)

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
echo "aws elb describe-instance-health --load-balancer-name DemoELB \\"
echo "                                 --profile $profile --region $region --output text"
for instance_public_name in $instance_public_names; do
    echo
    echo "lynx -dump http://$instance_public_name";;
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
        echo "# aws elb describe-instance-health --load-balancer-name DemoELB \\"
        echo ">                                  --profile $profile --region $region --output text"
        instance_health=$(aws elb describe-instance-health --load-balancer-name DemoELB \
                                                           --profile $profile --region $region --output text)
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
        lynx -dump http://$lb_public_name;;
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
                    echo -e -n "\r                                \r"
                fi
            done < $scriptsdir/$prefix-user-data-2.sh
        fi

        next 200
    fi
fi


((++step))
image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                                   --profile $profile --region $region --output text | cut -f3)
# Workaround 4.1.2 bug EUCA-11052, to prevent multiple arns in the result, must filter by account number
account_id=$(aws iam get-user --query 'User.Arn' --profile $profile --region $region | cut -d ':' -f5)
instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
                                                               --profile $profile --region $region --output text | \
                                                               tr "\t" "\n" | grep $account_id | grep "Demos$")
#instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
#                                                               --profile $profile --region $region --output text)
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
echo "aws autoscaling create-launch-configuration --launch-configuration-name DemoLC-2 \\"
echo "                                            --image-id $image_id --key-name=$ssh_key  \\"
echo "                                            --security-groups DemoSG \\"
echo "                                            --user-data file://$scriptsdir/$prefix-user-data-2.sh \\"
echo "                                            --instance-type m1.small \\"
echo "                                            --iam-instance-profile $instance_profile_arn \\"
echo "                                            --profile $profile --region $region --output text"
echo
echo "aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC DemoLC-2 \\"
echo "                                               --profile $profile --region $region --output text"

if aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC-2 \
                                                  --profile $profile --region $region --output text 2> /dev/null | grep -s -q "^LAUNCHCONFIGURATIONS"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# aws autoscaling create-launch-configuration --launch-configuration-name DemoLC-2 \\"
        echo ">                                             --image-id $image_id --key-name=$ssh_key  \\"
        echo ">                                             --security-groups DemoSG \\"
        echo ">                                             --user-data file://$scriptsdir/$prefix-user-data-2.sh \\"
        echo ">                                             --instance-type m1.small \\"
        echo ">                                             --iam-instance-profile $instance_profile_arn \\"
        echo ">                                             --profile $profile --region $region --output text"
        aws autoscaling create-launch-configuration --launch-configuration-name DemoLC-2 \
                                                    --image-id $image_id --key-name=$ssh_key  \
                                                    --security-groups DemoSG \
                                                    --user-data file://$scriptsdir/$prefix-user-data-2.sh \
                                                    --instance-type m1.small \
                                                    --iam-instance-profile $instance_profile_arn \
                                                    --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC DemoLC-2 \\"
        echo ">                                                --profile $profile --region $region --output text"
        aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC DemoLC-2 \
                                                       --profile $profile --region $region --output text

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
echo "aws autoscaling update-auto-scaling-group --auto-scaling-group-name DemoASG \\"
echo "                                          --launch-configuration-name DemoLC-2 \\"
echo "                                          --profile $profile --region $region --output text"
echo
echo "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
echo "                                             --profile $profile --region $region --output text"

if [ "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                     --query 'AutoScalingGroups[].LaunchConfigurationName' \
                                                     --profile $profile --region $region --output text 2> /dev/null)" = "DemoLC-2" ]; then
    echo
    tput rev
    echo "Already Updated!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# aws autoscaling update-auto-scaling-group --auto-scaling-group-name DemoASG \\"
        echo ">                                           --launch-configuration-name DemoLC-2 \\"
        echo ">                                           --profile $profile --region $region --output text"
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name DemoASG \
                                                  --launch-configuration-name DemoLC-2 \
                                                  --profile $profile --region $region --output text
        pause

        echo "# aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
        echo ">                                              --profile $profile --region $region --output text"
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                     --profile $profile --region $region --output text

        next
    fi
fi


((++step))
instance_ids="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                             --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                             --profile $profile --region $region --output text)"

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
    echo "aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $instance_id \\"
    echo "                                                         --no-should-decrement-desired-capacity \\"
    echo "                                                         --profile $profile --region $region --output text"
    echo
    echo "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
    echo "                                             --profile $profile --region $region --output text"
    echo
    echo "aws elb describe-instance-health --load-balancer-name DemoELB \\"
    echo "                                 --profile $profile --region $region --output text"
    break    # delete only one at this time
done

run 150

if [ $choice = y ]; then
    for instance_id in $instance_ids; do
        echo
        echo "# aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $instance_id \\"
        echo ">                                                          --no-should-decrement-desired-capacity \\"
        echo ">                                                          --profile $profile --region $region --output text"
        aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $instance_id \
                                                                 --no-should-decrement-desired-capacity \
                                                                 --profile $profile --region $region --output text
        pause

        attempt=0
        ((seconds=$replace_default * $speed / 100))
        while ((attempt++ <= replace_attempts)); do
            echo
            echo "# aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \\"
            echo ">                                              --profile $profile --region $region --output text"
            aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                         --profile $profile --region $region --output text
            echo
            echo "# aws elb describe-instance-health --load-balancer-name DemoELB \\"
            echo ">                                  --profile $profile --region $region --output text"
            instance_health=$(aws elb describe-instance-health --load-balancer-name DemoELB \
                                                               --profile $profile --region $region --output text)
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
instance_ids="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                             --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                             --profile $profile --region $region --output text)"
unset instance_public_names
for instance_id in $instance_ids; do
    instance_public_names="$instance_public_names $(aws ec2 describe-instances --instance-ids $instance_id \
                                                                               --query 'Reservations[].Instances[].PublicDnsName' \
                                                                               --profile $profile --region $region --output text)"
done
instance_public_names=${instance_public_names# *}

lb_public_name=$(aws elb describe-load-balancers --load-balancer-names DemoELB \
                                                 --query 'LoadBalancerDescriptions[].DNSName' \
                                                 --profile $profile --region $region --output text)
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
    echo "lynx -dump http://$instance_public_name";;
done
if [ -n "$lb_public_ip" ]; then
    echo
    echo "lynx -dump http://$lb_public_name"
    echo "lynx -dump http://$lb_public_name";;
fi

run 50

if [ $choice = y ]; then
    echo
    for instance_public_name in $instance_public_names; do
        echo "# lynx -dump http://$instance_public_name"
        lynx -dump http://$instance_public_name;;
        pause
    done
    if [ -n "$lb_public_ip" ]; then
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name
        echo "# lynx -dump http://$lb_public_name"
        lynx -dump http://$lb_public_name;;
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
