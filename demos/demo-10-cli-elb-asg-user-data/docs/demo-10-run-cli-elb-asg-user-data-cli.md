# Demo 10: CLI: ELB + ASG + User-Data

This document shows how to use the Euca2ools CLI (Command-Line Interface) to create a
SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScalingPolicies,
CloudWatch Alarms and Instances which use User-Data scripts for configuration.

### Prerequisites

This variant can be run by any User with the appropriate permissions, as long as Euca2ools
has been configured with the appropriate credentials, and the Account was initialized
with demo baseline dependencies. See [this section](../../demo-00-initialize/docs) for details.
    
You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus
Console, so that you can run scripts or upload Templates or other files which may be needed.
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

In examples below, credentials are specified via the --region USER@REGION option. You can shorten
the command lines by use of the AWS_DEFAULT_REGION environment variable set to the appropriate
value, buti for this demo want want to make each command explicit. Also, there is a conflict
between Euca2ools use of USER@REGION and AWS CLI, which breaks when this variable has the USER@
prefix. Specifying the value as a parameter avoids this conflict.

Before running this demo, please run the demo-10-initialize-cli-elb-asg-user-data.sh script,
which will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-10-reset-cli-elb-asg-user-data.sh script, which will
reverse all actions performed by this script so that it can be re-run.

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

    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    ```

### Run CLI: ELB + ASG + User-Data Demo

1. Confirm existence of Demo depencencies (Optional)

    The "CentOS-6-x86_64-GenericCloud" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                         --region $EUCA_USER_REGION | cut -f1,2,3

    euca-describe-keypairs --filter "key-name=demo" \
                           --region $EUCA_USER_REGION
    ```

2. List existing Resources (Optional)

    So we can compare with what this demo creates.

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    eulb-describe-lbs --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION

    euscale-describe-launch-configs --region $EUCA_USER_REGION

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION

    euscale-describe-policies --region $EUCA_USER_REGION

    euwatch-describe-alarms --region $EUCA_USER_REGION
    ```

3. Create a Security Group

    We will allow Ping, SSH and HTTP.

    ```bash
    euca-create-group --description "Demo Security Group" \
                      --region $EUCA_USER_REGION \
                      DemoSG

    euca-authorize --protocol icmp --icmp-type-code -1:-1 --cidr 0.0.0.0/0 \
                   --region $EUCA_USER_REGION \
                   DemoSG

    euca-authorize --protocol tcp --port-range 22 --cidr 0.0.0.0/0 \
                   --region $EUCA_USER_REGION \
                   DemoSG

    euca-authorize --protocol tcp --port-range 80 --cidr 0.0.0.0/0 \
                   --region $EUCA_USER_REGION \
                   DemoSG

    euca-describe-groups --region $EUCA_USER_REGION DemoSG
    ```

4. Create an Elastic Load Balancer

    We first must lookup the first Availability Zone, so it can be passed in as an input parameter.

    We will also configure a health check.

    Use the dig command to confirm the returned ELB DNS name resolves in DNS before proceeding.
    This can take 100 - 140 seconds.

    ```bash
    zone=$(euca-describe-availability-zones --region $EUCA_USER_REGION | head -1 | cut -f2)

    eulb-create-lb --availability-zones $zone \
                   --listener "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" \
                   --region $EUCA_USER_REGION \
                   DemoELB

    eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 \
                               --interval 15 --timeout 30 \
                               --target http:80/index.html \
                               --region $EUCA_USER_REGION \
                               DemoELB

    eulb-describe-lbs --region $EUCA_USER_REGION DemoELB

    lb_name=$(eulb-describe-lbs --region $user_region DemoELB | cut -f3)

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
    image_id=$(euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                    --region $EUCA_USER_REGION | cut -f2)
    account_id=$(euare-usergetattributes --region $EUCA_USER_REGION | grep "^arn" | cut -d ':' -f5)
    instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos \
                                                            --region $EUCA_USER_REGION | \
                               grep $account_id | grep "Demos$")

    euscale-create-launch-config --image-id $image_id --key=demo \
                                 --group=DemoSG \
                                 --user-data-file=~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-1.sh \
                                 --instance-type m1.small \
                                 --iam-instance-profile $instance_profile_arn \
                                 --region $EUCA_USER_REGION \
                                 DemoLC

    euscale-describe-launch-configs --region $EUCA_USER_REGION DemoLC"
    ```

7. Create an AutoScalingGroup

    We first must lookup the first Availability Zone, so it can be passed in as an input parameter.

    Note we associate the AutoScalingGroup with the ElasticLoadBalancer created earlier.

    Note there are two methods of checking Instance status.

    ```bash
    zone=$(euca-describe-availability-zones --region $EUCA_USER_REGION | head -1 | cut -f2)

    euscale-create-auto-scaling-group --launch-configuration DemoLC \
                                      --min-size 2 --max-size 4 --desired-capacity 2 \
                                      --default-cooldown 60 \
                                      --availability-zones $zone \
                                      --load-balancers DemoELB \
                                      --health-check-type ELB \
                                      --grace-period 300 \
                                      --region $EUCA_USER_REGION \
                                      DemoASG

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION DemoASG

    eulb-describe-instance-health --region $EUCA_USER_REGION DemoELB
    ```

8. Create Scaling Policies

    Create scale up and scale down policies to adjust the size of the AutoScalingGroup.

    ```bash
    euscale-put-scaling-policy --auto-scaling-group DemoASG \
                               --adjustment=1 --type ChangeInCapacity \
                               --region $EUCA_USER_REGION \
                               DemoScaleUpPolicy

    euscale-put-scaling-policy --auto-scaling-group DemoASG \
                               --adjustment=-1 --type ChangeInCapacity \
                               --region $EUCA_USER_REGION \
                               DemoScaleDownPolicy

    euscale-describe-policies --region $EUCA_USER_REGION \
                              DemoScaleUpPolicy DemoScaleDownPolicy
    ```

9. Create CloudWatch Alarms and Associate with Scaling Policies

    We first must lookup the ARNs of the Scaling Policies created in the prior step, so they can be
    passed in as an input parameters.

    ```bash
    up_policy_arn=$(euscale-describe-policies --region $EUCA_USER_REGION DemoScaleUpPolicy | cut -f6)
    down_policy_arn=$(euscale-describe-policies --region $EUCA_USER_REGION DemoScaleDownPolicy | cut -f6)

    euwatch-put-metric-alarm --alarm-description "Scale Up DemoELB by 1 when CPU >= 50%" \
                             --alarm-actions $up_policy_arn \
                             --metric-name CPUUtilization --namespace "AWS/EC2" \
                             --statistic Average --dimensions "AutoScalingGroupName=DemoASG" \
                             --period 60 --unit Percent --evaluation-periods 2 --threshold 50 \
                             --comparison-operator GreaterThanOrEqualToThreshold \
                             --region $EUCA_USER_REGION \
                             DemoCPUHighAlarm

    euwatch-put-metric-alarm --alarm-description "Scale Down DemoELB by 1 when CPU <= 10%" \
                             --alarm-actions $down_policy_arn \
                             --metric-name CPUUtilization --namespace "AWS/EC2" \
                             --statistic Average --dimensions "AutoScalingGroupName=DemoASG" \
                             --period 60 --unit Percent --evaluation-periods 2 --threshold 10 \
                             --comparison-operator LessThanOrEqualToThreshold \
                             --region $EUCA_USER_REGION \
                             DemoCPULowAlarm

    euwatch-describe-alarms --region $EUCA_USER_REGION DemoCPUHighAlarm DemoCPULowAlarm
    ```

10. List updated Resources (Optional)

    Note addition of new SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScaleGroup,
    Policies, Alarms and Instances.

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    eulb-describe-lbs --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION

    euscale-describe-launch-configs --region $EUCA_USER_REGION

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION

    euscale-describe-policies --region $EUCA_USER_REGION

    euwatch-describe-alarms --region $EUCA_USER_REGION
    ```

11. Confirm ability to login to Instance

    We first must lookup the public DNS name of an Instance in the AutoScaleGroup, so this can be used
    in the ssh command.

    It can take 20 to 40 seconds after the AutoScaleGroup stabilizes before login is possible.

    ```bash
    instance_id="$(euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION \
                                                        DemoASG | grep "^INSTANCE" | tail -1 | cut -f2)"
    public_name=$(euca-describe-instances --region $EUCA_USER_REGION \
                                          $instance_id | grep "^INSTANCE" | cut -f4)

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
    instance_ids="$(euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION \
                                                         DemoASG | grep "^INSTANCE" | cut -f2)"
    unset instance_public_names
    for instance_id in $instance_ids; do
        instance_public_names="$instance_public_names $(euca-describe-instances --region $EUCA_USER_REGION \
                                                                                $instance_id | \
                                                            grep "^INSTANCE" | cut -f4)"
    done
    instance_public_names=${instance_public_names# *}

    lb_public_name=$(eulb-describe-lbs --region $EUCA_USER_REGION | cut -f3)
    lb_public_ip=$(dig +short $lb_name)

    eulb-describe-instance-health --region $user_region DemoELB"

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
    image_id=$(euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                    --region $EUCA_USER_REGION | cut -f2)
    account_id=$(euare-usergetattributes --region $EUCA_USER_REGION | grep "^arn" | cut -d ':' -f5)
    instance_profile_arn=$(euare-instanceprofilelistforrole --role-name Demos \
                                                            --region $EUCA_USER_REGION | \
                               grep $account_id | grep "Demos$")

    euscale-create-launch-config --image-id $image_id --key=demo \
                                 --group=DemoSG \
                                 --user-data-file=~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-2.sh \
                                 --instance-type m1.small \
                                 --iam-instance-profile $instance_profile_arn \
                                 --region $EUCA_USER_REGION \
                                 DemoLC-2

    euscale-describe-launch-configs --region $EUCA_USER_REGION DemoLC DemoLC-2"
    ```

16. Update an AutoScalingGroup

    This replaces the original LaunchConfiguration with the replacement created above.

    ```bash
    euscale-update-auto-scaling-group --launch-configuration DemoLC-2 \
                                      --region $EUCA_USER_REGION \
                                      DemoASG

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION DemoASG
    ```

17. Trigger AutoScalingGroup Instance Replacement

    We first must lookup an Instance ID of an Instance in the AutoScaleGroup, so this can 
    be used in the termination command.

    We will terminate one existing Instance of the AutoScalingGroup, and confirm a replacement
    Instance is created with the new LaunchConfiguration and User-Data Script.

    We will wait until all Instances have returned to the "InService" state before we continue.
    This can take 140 - 200 seconds.

    ```bash
    instance_id=$(euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION \
                                                       DemoASG | grep "^INSTANCE" | tail -1 | cut -f2)

    euscale-terminate-instance-in-auto-scaling-group --no-decrement-desired-capacity \
                                                     --show-long \
                                                     --region $EUCA_USER_REGION \
                                                     $instance_id

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION DemoASG

    eulb-describe-instance-health --region $EUCA_USER_REGION DemoELB    # Repeat until "InService"
    ```

18. Confirm updated web page is visible

    We first must lookup the public DNS names of all Instances in the AutoScaleGroup, as well as the
    DNS name of the ELB, so these can be used in the browser commands.

    We will use the lynx text-mode browser to dump the web page contents, but you can also use
    any graphical browser to confirm the contents with the same DNS names.

    ```bash
    instance_ids="$(euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION \ 
                                                         DemoASG | grep "^INSTANCE" | cut -f2)"
    unset instance_public_names
    for instance_id in $instance_ids; do
        instance_public_names="$instance_public_names $(euca-describe-instances --region $EUCA_USER_REGION \ 
                                                                                $instance_id | \
                                                            grep "^INSTANCE" | cut -f4)"
    done
    instance_public_names=${instance_public_names# *}

    lb_public_name=$(eulb-describe-lbs --region $EUCA_USER_REGION | cut -f3)
    lb_public_ip=$(dig +short $lb_public_name)

    for instance_public_name in $instance_public_names; do
        lynx -dump http://$instance_public_name
    done

    if [ -n "$lb_public_ip" ]; then
        lynx -dump http://$lb_public_name
        lynx -dump http://$lb_public_name
    fi
    ```

