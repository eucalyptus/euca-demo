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
    euca-create-group --description "Demo Security Group" --region $EUCA_USER_REGION DemoSG

    euca-authorize --protocol icmp --icmp-type-code -1:-1 --cidr 0.0.0.0/0 --region $EUCA_USER_REGION DemoSG

    euca-authorize --protocol tcp --port-range 22 --cidr 0.0.0.0/0 --region $EUCA_USER_REGION DemoSG

    euca-authorize --protocol tcp --port-range 80 --cidr 0.0.0.0/0 --region $EUCA_USER_REGION DemoSG

    euca-describe-groups --region $EUCA_USER_REGION DemoSG
    ```

4. Create an Elastic Load Balancer

    Use the dig command to confirm the returned ELB DNS name resolves in DNS before proceeding.
    This can take 100 - 140 seconds.

    ```bash
    eulb-create-lb --availability-zones $zone \
                   --listener "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" \
                   --region $EUCA_USER_REGION DemoELB

    eulb-describe-lbs --region $EUCA_USER_REGION DemoELB
    ```

5. Configure an ElasticLoadBalancer HealthCheck

    ```bash
    eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 \
                               --interval 15 --timeout 30 \
                               --target http:80/index.html \
                               --region $EUCA_USER_REGION DemoELB
    ```

6. Display Demo User-Data Script (Optional)

    This simple user-data script will install Apache and configure a simple home page.

    We will use this in our LaunchConfiguration to automatically configure new instances
    as they are created by our AutoScalingGroup.

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-1.sh
    ```

    [Example of demo-10-user-data-s.sh](../scripts/demo-10-user-data-1.sh).


7. Create a LaunchConfiguration

    ```bash
    euscale-create-launch-config --image-id $image_id --instance-type m1.small --monitoring-enabled \
                                 --key=admin-demo --group=DemoSG \
                                 --user-data-file=~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/scripts/demo-10-user-data-1.sh
                                 --region $EUCA_USER_REGION \
                                 DemoLC

    euscale-describe-launch-configs --region $EUCA_USER_REGION DemoLC"
    ```

8. Create an AutoScalingGroup

    Note we associate the AutoScalingGroup with the ElasticLoadBalancer created earlier.

    Note there are two methods of checking Instance status.

    ```bash
    euscale-create-auto-scaling-group --launch-configuration DemoLC \
                                      --availability-zones $zone \
                                      --load-balancers DemoELB \
                                      --min-size 2 --max-size 4 --desired-capacity 2 \
                                      --region $EUCA_USER_REGION \
                                      DemoASG

    euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION DemoASG

    eulb-describe-instance-health --region $EUCA_USER_REGION DemoELB
    ```

9. Create Scaling Policies

    ```bash
    euscale-put-scaling-policy --auto-scaling-group DemoASG \
                               --adjustment=1 --type ChangeInCapacity \
                               --region $EUCA_USER_REGION \
                               DemoHighCPUPolicy

    euscale-put-scaling-policy --auto-scaling-group DemoASG \
                               --adjustment=-1 --type ChangeInCapacity \
                               --region $EUCA_USER_REGION \
                               DemoLowCPUPolicy

    euscale-update-auto-scaling-group --termination-policies "OldestLaunchConfiguration" \
                                      --region $EUCA_USER_REGION \
                                      DemoASG

    euscale-describe-policies --auto-scaling-group DemoASG --region $EUCA_USER_REGION
    ```

10. Create CloudWatch Alarms and Associate with Scaling Policies

    We must first lookup the Scaling Policy ARNs, as they are the target for the Alarms.

    ```bash
    high_policy_arn=$(euscale-describe-policies --region $EUCA_USER_REGION DemoHighCPUPolicy | cut -f6)
    low_policy_arn=$(euscale-describe-policies --region $EUCA_USER_REGION DemoLowCPUPolicy | cut -f6)

    euwatch-put-metric-alarm --metric-name CPUUtilization --unit Percent \
                             --namespace "AWS/EC2" --statistic Average \
                             --period 60 --threshold 50 --evaluation-periods 2 \
                             --comparison-operator GreaterThanOrEqualToThreshold \
                             --dimensions "AutoScalingGroupName=DemoASG" \
                             --alarm-actions $high_policy_arn \
                             --region $EUCA_USER_REGION \
                             DemoAddNodesAlarm

    euwatch-put-metric-alarm --metric-name CPUUtilization --unit Percent \
                             --namespace "AWS/EC2" --statistic Average \
                             --period 60 --threshold 10 --evaluation-periods 2 \
                             --comparison-operator LessThanOrEqualToThreshold \
                             --dimensions "AutoScalingGroupName=DemoASG" \
                             --alarm-actions $low_policy_arn \
                             --region $EUCA_USER_REGION \
                             DemoDelNodesAlarm

    euwatch-describe-alarms --alarm-name-prefix Demo --region $EUCA_USER_REGION
    ```

11. List updated Resources (Optional)

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

12. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of an Instance within the 
    AutoScaleGroup.

    It can take 20 to 40 seconds after the AutoScaleGroup stabilizes before login is possible.

    ```bash
    instance_id=$(euca-describe-instances --region $EUCA_USER_REGION | grep "^INSTANCE" | \
                                          cut -f2,11 | sort -k2 | tail -1 | cut -f1)
    public_name=$(euca-describe-instances --region $EUCA_USER_REGION $instance_id | grep "^INSTANCE" | cut -f4)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new Instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

13. Confirm web pages are visible

    We must first use some logic to find all public DNS names of Instances associated with the
    AutoScaleGroup, and the public DNS name of the ELB also associated. 
    
    We will use the w3m text-mode browser to dump the web page contents, but you can also use
    any graphical browser to confirm the contents with the same DNS names.

    ```bash
    instance_ids="$(euscale-describe-auto-scaling-groups --region $EUCA_USER_REGION DemoASG | grep "^INSTANCE" | cut -f2)"
    unset instance_names
    for instance_id in $instance_ids; do
        instance_names="$instance_names $(euca-describe-instances --region $EUCA_USER_REGION $instance_id | grep "^INSTANCE" | cut -f4)"
    done
    instance_names=${instance_names# *}

    lb_name=$(eulb-describe-lbs --region $EUCA_USER_REGION | cut -f3)
    lb_public_ip=$(dig +short $lb_name)

    for instance_name in $instance_names; do
        w3m -dump $instance_name
    done
    if [ -n "$lb_public_ip" ]; then
        w3m -dump $lb_name
        w3m -dump $lb_name
    fi
    ```

