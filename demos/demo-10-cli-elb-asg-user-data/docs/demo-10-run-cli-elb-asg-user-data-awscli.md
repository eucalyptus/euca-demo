# Demo 10: CLI: ELB + ASG + User-Data

This document shows how to use the AWS CLI (Command-Line Interface) to create a
SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScalingPolicies,
CloudWatch Alarms and Instances which use User-Data scripts for configuration.

### Prerequisites

This variant can be run by any User with the appropriate permissions, as long as AWS CLI
has been configured with the appropriate credentials, and the Account was initialized with
demo baseline dependencies. See [this section](../../demo-00-initialize/docs) for details.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus
Console, so that you can run scripts or upload Templates or other files which may be needed.
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

In examples below, credentials are specified via the --profile PROFILE and --region REGION
options. You can shorten the command lines by use of the AWS_DEFAULT_PROFILE and
AWS_DEFAULT_REGION environment variables set to appropriate values, but for this demo we
want to make each command explicit.

Before running this demo, please run the demo-10-initialize-cli-elb-asg-user-data.sh script,
which will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-10-reset-cli-elb-asg-user-data.sh script, which
will reverse all actions performed by this script so that it can be re-run.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different Regions, Accounts and Users, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export EUCA_REGION=hp-aw2-1
    export EUCA_DOMAIN=hpcloudsvc.com
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin

    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER
    ```

### Run CLI: ELB + ASG + User-Data Demo

1. Confirm existence of Demo depencencies (Optional)

    The "CentOS-6-x86_64-GenericCloud" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                            --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -f1,3,4

    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

2. List Existing Resources (Optional)

    So we can compare with what this demo creates.

    ```bash
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb describe-load-balancers --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-instances --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-launch-configurations --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-auto-scaling-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-policies --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws cloudwatch describe-alarms --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

3. Create a Security Group

    We will allow Ping, SSH and HTTP.

    ```bash
    aws ec2 create-security-group --group-name DemoSG --description "Demo Security Group" \
                                  --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol icmp --port -1 --cidr 0.0.0.0/0 \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 22 --cidr 0.0.0.0/0 \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 authorize-security-group-ingress --group-name DemoSG --protocol tcp --port 80 --cidr 0.0.0.0/0 \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-security-groups --filters "Name=group-name,Values=DemoSG" \
                                     --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

4. Create an Elastic Load Balancer

    We first must lookup the first Availability Zone, so it can be passed in as an input parameter.

    We will also configure a health check.

    Use the dig command to confirm the returned ELB DNS name resolves in DNS before proceeding.
    This can take 100 - 140 seconds.

    ```bash
    zone=$(aws ec2 describe-availability-zones --profile $EUCA_PROFILE --region $EUCA_REGION --output text | \
              head -1 | cut -f4)

    aws elb create-load-balancer --load-balancer-name DemoELB \
                                 --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
                                 --availability-zones $zone \
                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb configure-health-check --load-balancer-name DemoELB \
                                   --health-check "Target=http:80/index.html,Interval=15,Timeout=30,UnhealthyThreshold=2,HealthyThreshold=2" \
                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb describe-load-balancers --load-balancer-names DemoELB \
                                    --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    lb_name=$(aws elb describe-load-balancers --load-balancer-names DemoELB \
                                              --query 'LoadBalancerDescriptions[].DNSName' \
                                              --profile $EUCA_PROFILE --region $EUCA_REGION --output text)

    dig +short $lb_name    # repeat this until an IP address is returned
    ```

5. Display Demo User-Data Script (Optional)

    This simple user-data script will install Apache and configure a simple home page.

    We will use this in our LaunchConfiguration to automatically configure new instances
    as they are created by our AutoScalingGroup.

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-1.sh
    ```

    [Example of demo-10-user-data-1.sh](../scripts/demo-10-user-data-1.sh).

6. Create a LaunchConfiguration

    We first must lookup the EMI ID of the Image to be used for this Launch Condition, and the ARN of
    the Instance Profile, so these can be passed in as an input parameters.

    ```bash
    image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                       --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -f3)
    account_id=$(aws iam get-user --query 'User.Arn' --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -d ':' -f5)
    instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
                                                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text | \
                                                                   tr "\t" "\n" | grep $account_id | grep "Demos$")

    aws autoscaling create-launch-configuration --launch-configuration-name DemoLC \
                                                --image-id $image_id --key-name=demo \
                                                --security-groups DemoSG \
                                                --user-data file://~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-1.sh \
                                                --instance-type m1.small \
                                                --iam-instance-profile $instance_profile_arn \
                                                --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC \
                                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

7. Create an AutoScalingGroup

    We first must lookup the first Availability Zone, so it can be passed in as an input parameter.

    Note we associate the AutoScalingGroup with the ElasticLoadBalancer created earlier.

    Note there are two methods of checking Instance status.

    ```bash
    zone=$(aws ec2 describe-availability-zones --profile $EUCA_PROFILE --region $EUCA_REGION --output text | head -1 | cut -f4)

    aws autoscaling create-auto-scaling-group --auto-scaling-group-name DemoASG \
                                              --launch-configuration-name DemoLC \
                                              --min-size 2 --max-size 4 --desired-capacity 2 \
                                              --default-cooldown 60 \
                                              --availability-zones $zone \
                                              --load-balancer-names DemoELB \
                                              --health-check-type ELB \
                                              --health-check-grace-period 300 \
                                              --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb describe-instance-health --load-balancer-name DemoELB \
                                     --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

8. Create Scaling Policies

    Create scale up and scale down policies to adjust the size of the AutoScalingGroup.

    ```bash
    aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \
                                       --policy-name DemoScaleUpPolicy \
                                       --adjustment-type ChangeInCapacity \
                                       --scaling-adjustment=1 \
                                       --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling put-scaling-policy --auto-scaling-group-name DemoASG \
                                       --policy-name DemoScaleDownPolicy \
                                       --adjustment-type ChangeInCapacity \
                                       --scaling-adjustment=-1 \
                                       --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                      --policy-names DemoScaleUpPolicy DemoScaleDownPolicy \
                                      --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

9. Create CloudWatch Alarms and Associate with Scaling Policies

    We first must lookup the ARNs of the Scaling Policies created in the prior step, so they can be
    passed in as an input parameters.

    ```bash
    up_policy_arn=$(aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                                      --policy-names DemoScaleUpPolicy \
                                                      --query 'ScalingPolicies[].PolicyARN' \
                                                      --profile $EUCA_PROFILE --region $EUCA_REGION --output text)
    down_policy_arn=$(aws autoscaling describe-policies --auto-scaling-group DemoASG \
                                                        --policy-names DemoScaleDownPolicy \
                                                        --query 'ScalingPolicies[].PolicyARN' \
                                                        --profile $EUCA_PROFILE --region $EUCA_REGION --output text)

    aws cloudwatch put-metric-alarm --alarm-name DemoCPUHighAlarm \
                                    --alarm-description "Scale Up DemoELB by 1 when CPU >= 50%" \
                                    --alarm-actions $up_policy_arn \
                                    --metric-name CPUUtilization --namespace "AWS/EC2" \
                                    --statistic Average --dimensions "Name=AutoScalingGroupName,Value=DemoASG" \
                                    --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \
                                    --comparison-operator GreaterThanOrEqualToThreshold \
                                    --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws cloudwatch put-metric-alarm --alarm-name DemoCPULowAlarm \
                                    --alarm-description "Scale Down DemoELB by 1 when CPU <= 10%" \
                                    --alarm-actions $down_policy_arn \
                                    --metric-name CPUUtilization --namespace "AWS/EC2" \
                                    --statistic Average --dimensions "Name=AutoScalingGroupName,Value=DemoASG" \
                                    --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \
                                    --comparison-operator LessThanOrEqualToThreshold \
                                    --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws cloudwatch describe-alarms --alarm-names DemoCPUHighAlarm DemoCPULowAlarm \
                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

10. List updated Resources (Optional)

    Note addition of new SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScaleGroup,
    Policies, Alarms and Instances.

    ```bash
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb describe-load-balancers --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-instances --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-launch-configurations --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-auto-scaling-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-policies --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws cloudwatch describe-alarms --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

11. Confirm ability to login to Instance

    We first must lookup the public DNS name of an Instance in the AutoScaleGroup, so this can be used
    in the ssh command.

    It can take 20 to 40 seconds after the AutoScaleGroup stabilizes before login is possible.

    ```bash
    instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                               --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                               --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -f1)
    public_name=$(aws ec2 describe-instances --instance-ids $instance_id \
                                             --query 'Reservations[].Instances[].PublicDnsName' \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new Instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

13. Confirm web pages are visible

    We first must lookup the public DNS names of all Instances in the AutoScaleGroup, as well as the
    DNS name of the ELB, so these can be used in the browser commands.

    We will use the lynx text-mode browser to dump the web page contents, but you can also use
    any graphical browser to confirm the contents with the same DNS names.

    ```bash
    instance_ids="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                                 --query 'AutoScalingGroups[].Instances[].InstanceId' \
                                                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text)"

    unset instance_public_names
    for instance_id in $instance_ids; do
        instance_public_names="$instance_public_names $(aws ec2 describe-instances --instance-ids $instance_id \
                                                                                   --query 'Reservations[].Instances[].PublicDnsName' \
                                                                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text)"
    done
    instance_public_names=${instance_public_names# *}

    lb_public_name=$(aws elb describe-load-balancers --load-balancer-names DemoELB \
                                                 --query 'LoadBalancerDescriptions[].DNSName' \
                                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text)
    lb_public_ip=$(dig +short $lb_name)

    aws elb describe-instance-health --load-balancer-name DemoELB \
                                     --profile $EUCA_PROFILE --region $EUCA_REGION --output text


    for instance_public_name in $instance_public_names; do
        lynx -dump http://$instance_public_name
    done

    if [ -n "$lb_public_ip" ]; then
        lynx -dump http://$lb_public_name
        lynx -dump http://$lb_public_name
    fi
    ```

14. Display Alternate Demo User-Data Script (Optional)

    This simple user-data script will install Apache and configure a simple home page.

    This alternate makes minor changes to the simple home page to demonstrate how updates
    to a Launch Configuration can handle rolling updates.

    We will use this in a replacement LaunchConfiguration to automatically configure new
    instances as they are created by our AutoScalingGroup, which will be modified to use
    the new LaunchCondition.

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-2.sh
    ```

    [Example of demo-10-user-data-2.sh](../scripts/demo-10-user-data-2.sh).

15. Create a Replacement LaunchConfiguration

    We first must lookup the EMI ID of the Image to be used for this Launch Condition, and the ARN of
    the Instance Profile, so these can be passed in as an input parameters.

    ```bash
    image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                       --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -f3)
    account_id=$(aws iam get-user --query 'User.Arn' --profile $EUCA_PROFILE --region $EUCA_REGION --output text | cut -d ':' -f5)
    instance_profile_arn=$(aws iam list-instance-profiles-for-role --role-name Demos --query 'InstanceProfiles[].Arn' \
                                                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text | \
                               tr "\t" "\n" | grep $account_id | grep "Demos$")

    aws autoscaling create-launch-configuration --launch-configuration-name DemoLC-2 \
                                                --image-id $image_id --key-name=demo \
                                                --security-groups DemoSG \
                                                --user-data file://~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-2.sh \
                                                --instance-type m1.small \
                                                --iam-instance-profile $instance_profile_arn \
                                                --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-launch-configurations --launch-configuration-names DemoLC DemoLC-2 \
                                                   --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

16. Update an AutoScalingGroup

    This replaces the original LaunchConfiguration with the replacement created above.

    ```bash
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name DemoASG \
                                              --launch-configuration-name DemoLC-2 \
                                              --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

17. Trigger AutoScalingGroup Instance Replacement

    We first must lookup an Instance ID of an Instance in the AutoScaleGroup, so this can
    be used in the termination command.

    We will terminate one existing Instance of the AutoScalingGroup, and confirm a replacement
    Instance is created with the new LaunchConfiguration and User-Data Script.

    We will wait until all Instances have returned to the "InService" state before we continue.
    This can take 140 - 200 seconds.

    ```bash
    instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                               --query 'AutoScalingGroups[].Instances[0].InstanceId' \
                                                               --profile $EUCA_PROFILE --region $EUCA_REGION --output text)

    aws autoscaling terminate-instance-in-auto-scaling-group --instance-id $instance_id \
                                                             --no-should-decrement-desired-capacity \
                                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names DemoASG \
                                                 --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws elb describe-instance-health --load-balancer-name DemoELB \
                                     --profile $EUCA_PROFILE --region $EUCA_REGION --output text    # Repeat until "InService"
    ```

18. Confirm updated web page is visible

    We first must lookup the public DNS names of all Instances in the AutoScaleGroup, as well as the
    DNS name of the ELB, so these can be used in the browser commands.

    We will use the lynx text-mode browser to dump the web page contents, but you can also use
    any graphical browser to confirm the contents with the same DNS names.

    ```bash
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

    for instance_public_name in $instance_public_names; do
        lynx -dump http://$instance_public_name
    done

    if [ -n "$lb_public_ip" ]; then
        lynx -dump http://$lb_public_name
        lynx -dump http://$lb_public_name
    fi
    ```

