[root@odc-f-33 bin]# euca-demo-05-test-elb-asg-user-data.sh -I

============================================================

 1. Use Demo (demo) Account Administrator credentials

============================================================

Commands:

cat /root/creds/demo/admin/eucarc

source /root/creds/demo/admin/eucarc

Waiting  1 seconds... Done

# cat /root/creds/demo/admin/eucarc
EUCA_KEY_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd -P)
export EC2_URL=http://compute.fb.mjc.prc.eucalyptus-systems.com:8773/
export S3_URL=http://objectstorage.fb.mjc.prc.eucalyptus-systems.com:8773/
export AWS_IAM_URL=http://euare.fb.mjc.prc.eucalyptus-systems.com:8773/
export TOKEN_URL=http://tokens.fb.mjc.prc.eucalyptus-systems.com:8773/
export AWS_AUTO_SCALING_URL=http://autoscaling.fb.mjc.prc.eucalyptus-systems.com:8773/
export AWS_CLOUDFORMATION_URL=http://cloudformation.fb.mjc.prc.eucalyptus-systems.com:8773/
export AWS_CLOUDWATCH_URL=http://cloudwatch.fb.mjc.prc.eucalyptus-systems.com:8773/
export AWS_ELB_URL=http://loadbalancing.fb.mjc.prc.eucalyptus-systems.com:8773/
export EUSTORE_URL=http://emis.eucalyptus.com/
export EC2_PRIVATE_KEY=${EUCA_KEY_DIR}/euca2-admin-ac9f004a-pk.pem
export EC2_CERT=${EUCA_KEY_DIR}/euca2-admin-ac9f004a-cert.pem
export EC2_JVM_ARGS=-Djavax.net.ssl.trustStore=${EUCA_KEY_DIR}/jssecacerts
export EUCALYPTUS_CERT=${EUCA_KEY_DIR}/cloud-cert.pem
export EC2_ACCOUNT_NUMBER='876690818618'
export EC2_ACCESS_KEY='AKIQOARQSHZZKMW9XWIX'
export EC2_SECRET_KEY='LTQp1G6ubDBF6FMrKjiAEBm8OABT5djP3FADhtQu'
export AWS_ACCESS_KEY='AKIQOARQSHZZKMW9XWIX'
export AWS_SECRET_KEY='LTQp1G6ubDBF6FMrKjiAEBm8OABT5djP3FADhtQu'
export AWS_CREDENTIAL_FILE=${EUCA_KEY_DIR}/iamrc
export EC2_USER_ID='876690818618'
alias ec2-bundle-image="ec2-bundle-image --cert ${EC2_CERT} --privatekey ${EC2_PRIVATE_KEY} --user ${EC2_ACCOUNT_NUMBER} --ec2cert $
{EUCALYPTUS_CERT}"
alias ec2-upload-bundle="ec2-upload-bundle -a ${EC2_ACCESS_KEY} -s ${EC2_SECRET_KEY} --url ${S3_URL}"
#
# source /root/creds/demo/admin/eucarc

Waiting  1 seconds... Done

============================================================

 2. Confirm existence of Demo depencencies

============================================================

Commands:

euca-describe-images | grep "centos.raw.manifest.xml"

euca-describe-keypairs | grep "admin-demo"

Waiting  1 seconds... Done

# euca-describe-images | grep "centos.raw.manifest.xml"
IMAGE   emi-a967783f    images/centos.raw.manifest.xml  107345199026    available       private x86_64  machine                         instance-store  hvm
#
# euca-describe-keypairs | grep "admin-demo"
KEYPAIR admin-demo      4a:17:c2:c3:f6:62:87:b9:68:fe:c4:25:ee:b8:54:8e:0e:66:a4:0f

Waiting  1 seconds... Done

============================================================

 3. List initial resources
    - So we can compare with what this demo creates

============================================================

Commands:

euca-describe-images

euca-describe-keypairs

euca-describe-groups

eulb-describe-lbs

euca-describe-instances

euscale-describe-launch-configs

euscale-describe-auto-scaling-groups

euscale-describe-policies

euwatch-describe-alarms

Waiting  1 seconds... Done

# euca-describe-images
IMAGE   emi-a967783f    images/centos.raw.manifest.xml  107345199026    available       private x86_64  machine                    instance-store   hvm
#
# euca-describe-keypairs
KEYPAIR admin-demo      4a:17:c2:c3:f6:62:87:b9:68:fe:c4:25:ee:b8:54:8e:0e:66:a4:0f
#
# euca-describe-groups
GROUP   sg-d755e354     876690818618    default default group
#
# eulb-describe-lbs
#
# euca-describe-instances
#
# euscale-describe-launch-configs
#
# euscale-describe-auto-scaling-groups
#
# euscale-describe-policies
#
# euwatch-describe-alarms

Waiting  1 seconds... Done

============================================================

 4. Create a Security Group
    - We will allow SSH and HTTP

============================================================

Commands:

euca-create-group -d "Demo Security Group" DemoSG

euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 DemoSG

euca-authorize -P tcp -p 22 -s 0.0.0.0/0 DemoSG

euca-authorize -P tcp -p 80 -s 0.0.0.0/0 DemoSG

euca-describe-groups DemoSG

Waiting  1 seconds... Done

# euca-create-group -d "Demo Security Group" DemoSG
GROUP   sg-8dbd1b50     DemoSG  Demo Security Group
#
# euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 DemoSG
GROUP   DemoSG
PERMISSION      DemoSG  ALLOWS  icmp    -1      -1      FROM    CIDR    0.0.0.0/0
#
# euca-authorize -P tcp -p 22 -s 0.0.0.0/0 DemoSG
GROUP   DemoSG
PERMISSION      DemoSG  ALLOWS  tcp     22      22      FROM    CIDR    0.0.0.0/0
#
# euca-authorize -P tcp -p 80 -s 0.0.0.0/0 DemoSG
GROUP   DemoSG
PERMISSION      DemoSG  ALLOWS  tcp     80      80      FROM    CIDR    0.0.0.0/0
#
# euca-describe-groups DemoSG
GROUP   sg-8dbd1b50     876690818618    DemoSG  Demo Security Group
PERMISSION      876690818618    DemoSG  ALLOWS  icmp    -1      -1      FROM    CIDR    0.0.0.0/0       ingress
PERMISSION      876690818618    DemoSG  ALLOWS  tcp     80      80      FROM    CIDR    0.0.0.0/0       ingress
PERMISSION      876690818618    DemoSG  ALLOWS  tcp     22      22      FROM    CIDR    0.0.0.0/0       ingress

Waiting  1 seconds... Done

============================================================

 5. Create an ElasticLoadBalancer
    - Wait for ELB to become available
    - NOTE: This can take about 100 - 140 seconds

============================================================

Commands:

eulb-create-lb -z default -l "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" DemoELB

eulb-describe-lbs DemoELB

Waiting  1 seconds... Done

# eulb-create-lb -z default -l "lb-port=80, protocol=HTTP, instance-port=80, instance-protocol=HTTP" DemoELB
DNS_NAME        DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
#
# eulb-describe-lbs DemoELB
LOAD_BALANCER   DemoELB DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com       2015-01-30T01:11:46.151Z

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Not available. Waiting 20 seconds... Done

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Not available. Waiting 20 seconds... Done

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Not available. Waiting 20 seconds... Done

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Not available. Waiting 20 seconds... Done

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Not available. Waiting 20 seconds... Done

# dig +short DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
<Missing IP was corrected, and should now be listed here>

Waiting  1 seconds... Done

============================================================

 6. Configure an ElasticLoadBalancer HealthCheck

============================================================

Commands:

eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \
                           --target http:80/index.html DemoELB

Waiting  1 seconds... Done

# eulb-configure-healthcheck --healthy-threshold 2 --unhealthy-threshold 2 --interval 15 --timeout 30 \
                             --target http:80/index.html DemoELB
HEALTH_CHECK    HTTP:80/index.html      15      30      2       2

Waiting  1 seconds... Done

============================================================

 7. Display Demo User-Data script
    - This simple user-data script will install Apache and configure
      a simple home page
    - We will use this in our LaunchConfiguration to automatically
      configure new instances created by our AutoScalingGroup

============================================================

Commands:

cat /root/src/eucalyptus/euca-demo/scripts/demo-05-user-data.sh

Waiting  1 seconds... Done

# cat /root/src/eucalyptus/euca-demo/scripts/demo-05-user-data.sh
#!/bin/bash -eux
#
# Script to configure demo-05 instances
#
# This is a script meant to be run via cloud-init to do simple initial configuration
# of the Demo 05 Instances created by the associated LaunchConfiguration and 
# AutoScaleGroup.
#

# fix hostname to be more AWS like
local_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/local-ipv4)
public_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/public-ipv4)
hostname=ip-${local_ipv4//./-}.prc.eucalyptus-systems.com
sed -i -e "s/HOSTNAME=.*/HOSTNAME=$hostname/" /etc/sysconfig/network
hostname $hostname

# setup hosts
cat << EOF >> /etc/hosts
$local_ipv4      $hostname ${hostname%%.*}
EOF

# Install Apache
yum install -y httpd mod_ssl

# Configure Apache to display a test page showing the host internal IP address
cat << EOF >> /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Demo 05!</title>
<style>
    body {
        width: 50em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Demo 05!</h1>

<p>You're viewing a website running on the host with internal address: $(hostname)</p>
</body>
</html>
EOF

# Configure Apache to start on boot
chkconfig httpd on
service httpd start


Waiting  1 seconds... Done

============================================================

 8. Create a LaunchConfiguration

============================================================

Commands:

euscale-create-launch-config DemoLC --image-id emi-a967783f --instance-type m1.small --monitoring-enabled \
                                    --key=admin-demo --group=DemoSG \
                                    --user-data-file=/root/src/eucalyptus/euca-demo/scripts/demo-05-user-data.sh

euscale-describe-launch-configs DemoLC

Waiting  1 seconds... Done

# euscale-create-launch-config DemoLC --image-id emi-a967783f --instance-type m1.small --monitoring-enabled \
>                                     --key=admin-demo --group=DemoSG \
>                                     --user-data-file=/root/src/eucalyptus/euca-demo/scripts/demo-05-user-data.sh
#
# euscale-describe-launch-configs DemoLC
LAUNCH-CONFIG   DemoLC  emi-a967783f    m1.small

Waiting  1 seconds... Done

============================================================

 9. Create an AutoScalingGroup
    - Note we associate the AutoScalingGroup with the
      ElasticLoadBalancer created earlier
    - Note there are two methods of checking Instance
      status

============================================================

Commands:

euscale-create-auto-scaling-group DemoASG --launch-configuration DemoLC \
                                          --availability-zones default \
                                          --load-balancers DemoELB \
                                          --min-size 2 --max-size 4 --desired-capacity 2

euscale-describe-auto-scaling-groups DemoASG

eulb-describe-instance-health DemoELB

Waiting  1 seconds... Done

# euscale-create-auto-scaling-group DemoASG --launch-configuration DemoLC \
>                                           --availability-zones default \
>                                           --load-balancers DemoELB \
>                                           --min-size 2 --max-size 4 --desired-capacity 2
#
# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC  default DemoELB 2       4       2       Default
INSTANCE        i-c68ed8be      default Pending Healthy DemoLC
INSTANCE        i-ba4062be      default Pending Healthy DemoLC
#
# eulb-describe-instance-health DemoELB

Waiting  1 seconds... Done

============================================================

10. Create Policies and Associated Alarms
    - Create a scale out policy
    - Create a scale in policy
    - Update AutoScalingGroup with a termination policy
    - Create a high-cpu alarm using the scale out policy
    - Create a low-cpu alarm using the scale in policy

============================================================

Commands:

euscale-put-scaling-policy DemoHighCPUPolicy --auto-scaling-group DemoASG \
                                             --adjustment=1 --type ChangeInCapacity

euscale-put-scaling-policy DemoLowCPUPolicy --auto-scaling-group DemoASG \
                                            --adjustment=-1 --type ChangeInCapacity

euscale-update-auto-scaling-group DemoASG --termination-policies "OldestLaunchConfiguration"

euscale-describe-policies
#
euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \
                                           --namespace "AWS/EC2" --statistic Average \
                                           --period 60 --threshold 50 \
                                           --comparison-operator GreaterThanOrEqualToThreshold \
                                           --dimensions "AutoScalingGroupName=DemoASG" \
                                           --evaluation-periods 2 --alarm-actions <DemoHighCPUPolicy arn>

euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \
                                           --namespace "AWS/EC2" --statistic Average \
                                           --period 60 --threshold 10 \
                                           --comparison-operator LessThanOrEqualToThreshold \
                                           --dimensions "AutoScalingGroupName=DemoASG" \
                                           --evaluation-periods 2 --alarm-actions <DemoLowCPUPolicy arn>

euwatch-describe-alarms

Waiting  1 seconds... Done

# euscale-put-scaling-policy DemoHighCPUPolicy --auto-scaling-group DemoASG \
>                                              --adjustment=1 --type ChangeInCapacity
arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy
#
# euscale-put-scaling-policy DemoLowCPUPolicy --auto-scaling-group DemoASG \
>                                             --adjustment=-1 --type ChangeInCapacity
arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy
#
# euscale-update-auto-scaling-group DemoASG --termination-policies "OldestLaunchConfiguration"
#
# euscale-describe-policies
SCALING-POLICY  DemoASG DemoHighCPUPolicy       1       ChangeInCapacity        arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy
SCALING-POLICY  DemoASG DemoLowCPUPolicy        -1      ChangeInCapacity        arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy
#
# euwatch-put-metric-alarm DemoAddNodesAlarm --metric-name CPUUtilization --unit Percent \
>                                            --namespace "AWS/EC2" --statistic Average \
>                                            --period 60 --threshold 50 \
>                                            --comparison-operator GreaterThanOrEqualToThreshold \
>                                            --dimensions "AutoScalingGroupName=DemoASG" \
>                                            --evaluation-periods 2 --alarm-actions arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy
#
# euwatch-put-metric-alarm DemoDelNodesAlarm --metric-name CPUUtilization --unit Percent \
>                                            --namespace "AWS/EC2" --statistic Average \
>                                            --period 60 --threshold 10 \
>                                            --comparison-operator LessThanOrEqualToThreshold \
>                                            --dimensions "AutoScalingGroupName=DemoASG" \
>                                            --evaluation-periods 2 --alarm-actions arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy
#
# euwatch-describe-alarms
DemoAddNodesAlarm       INSUFFICIENT_DATA       arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy      AWS/EC2 CPUUtilization  60      Average 2       GreaterThanOrEqualToThreshold       50.0
DemoDelNodesAlarm       INSUFFICIENT_DATA       arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy       AWS/EC2 CPUUtilization  60      Average 2       LessThanOrEqualToThreshold  10.0

Waiting  1 seconds... Done

============================================================

11. List updated resources

============================================================

Commands:

euca-describe-images

euca-describe-keypairs

euca-describe-groups

eulb-describe-lbs

euca-describe-instances

euscale-describe-launch-configs

euscale-describe-auto-scaling-groups

euscale-describe-policies

euwatch-describe-alarms

Waiting  1 seconds... Done

# euca-describe-images
IMAGE   emi-a967783f    images/centos.raw.manifest.xml  107345199026    available       private x86_64  machine                    instance-store   hvm
#
# euca-describe-keypairs
KEYPAIR admin-demo      4a:17:c2:c3:f6:62:87:b9:68:fe:c4:25:ee:b8:54:8e:0e:66:a4:0f
#
# euca-describe-groups
GROUP   sg-d755e354     876690818618    default default group
GROUP   sg-8dbd1b50     876690818618    DemoSG  Demo Security Group
PERMISSION      876690818618    DemoSG  ALLOWS  icmp    -1      -1      FROM    CIDR    0.0.0.0/0       ingress
PERMISSION      876690818618    DemoSG  ALLOWS  tcp     80      80      FROM    CIDR    0.0.0.0/0       ingress
PERMISSION      876690818618    DemoSG  ALLOWS  tcp     22      22      FROM    CIDR    0.0.0.0/0       ingress
#
# eulb-describe-lbs
LOAD_BALANCER   DemoELB DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com       2015-01-30T01:11:46.151Z
#
# euca-describe-instances
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   running admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default                    monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-992de909      876690818618    DemoSG
INSTANCE        i-c68ed8be      emi-a967783f    euca-10-104-45-179.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-193.cloud.internal   running admin-demo      0               m1.small        2015-01-30T01:14:43.389Z        default                    monitoring-enabled       10.104.45.179   10.104.45.193                   instance-store                                  hvm        f2431e79-8062-48b8-b95b-b6a5b2ac1f5b_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-c68ed8be      aws:autoscaling:groupName       DemoASG
#
# euscale-describe-launch-configs
LAUNCH-CONFIG   DemoLC  emi-a967783f    m1.small
#
# euscale-describe-auto-scaling-groups
AUTO-SCALING-GROUP      DemoASG DemoLC  default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-c68ed8be      default InService       Healthy DemoLC
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
#
# euscale-describe-policies
SCALING-POLICY  DemoASG DemoHighCPUPolicy       1       ChangeInCapacity        arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy
SCALING-POLICY  DemoASG DemoLowCPUPolicy        -1      ChangeInCapacity        arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy
#
# euwatch-describe-alarms
DemoAddNodesAlarm       INSUFFICIENT_DATA       arn:aws:autoscaling::876690818618:scalingPolicy:188e5e8b-202e-41d2-b039-954a9d8f80a3:autoScalingGroupName/DemoASG:policyName/DemoHighCPUPolicy      AWS/EC2 CPUUtilization  60      Average 2       GreaterThanOrEqualToThreshold       50.0
DemoDelNodesAlarm       INSUFFICIENT_DATA       arn:aws:autoscaling::876690818618:scalingPolicy:c0898d7d-e9f5-493b-93f9-4eeac72d2bc4:autoScalingGroupName/DemoASG:policyName/DemoLowCPUPolicy       AWS/EC2 CPUUtilization  60      Average 2       LessThanOrEqualToThreshold  10.0

Waiting  1 seconds... Done

============================================================

12. Confirm ability to login to Instance
    - If unable to login, view instance console output with:
      # euca-get-console-output i-ba4062be
    - If able to login, first show the private IP with:
      # ifconfig
    - Then view meta-data about the public IP with:
      # curl http://169.254.169.254/latest/meta-data/public-ipv4
    - Then view user-data with:
      # curl http://169.254.169.254/latest/user-data
    - Logout of instance once login ability confirmed
    - NOTE: This can take about 20 - 80 seconds

============================================================

Commands:

ssh -i /root/creds/demo/admin/admin-demo.pem root@euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com

Waiting  1 seconds... Done

# ssh -i /root/creds/demo/admin/admin-demo.pem root@euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com
Warning: Permanently added the RSA host key for IP address '10.104.45.188' to the list of known hosts.
# ifconfig
eth0      Link encap:Ethernet  HWaddr D0:0D:BA:40:62:BE  
          inet addr:10.104.45.212  Bcast:10.104.255.255  Mask:255.255.0.0
          inet6 addr: fe80::d20d:baff:fe40:62be/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12741 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7041 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:17397635 (16.5 MiB)  TX bytes:515312 (503.2 KiB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 b)  TX bytes:0 (0.0 b)


# curl http://169.254.169.254/latest/meta-data/public-ipv4
10.104.45.188

Waiting  1 seconds... Done

============================================================

13. Confirm webpage is visible
    - Wait for both instances to be "InService"
    - Attempt to display webpage first directly via instances,
      then through the ELB

============================================================

Commands:

w3m -dump euca-10-104-45-179.cloud.fb.mjc.prc.eucalyptus-systems.com

w3m -dump euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com

w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Waiting  1 seconds... Done

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService
INSTANCE        i-c68ed8be      InService

# w3m -dump euca-10-104-45-179.cloud.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-193.prc.eucalyptus-systems.com

#
# w3m -dump euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-212.prc.eucalyptus-systems.com

#
# w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-212.prc.eucalyptus-systems.com

# w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-193.prc.eucalyptus-systems.com


Waiting  1 seconds... Done

============================================================

14. Display Demo Alternate User-Data script
    - This simple user-data script will install Apache and configure
      a simple home page
    - This alternate makes minor changes to the simple home page
      to demonstrate how updates to a Launch Configuration can handle
      rolling updates
    - We will modify our existing LaunchConfiguration to automatically
      configure new instances created by our AutoScalingGroup

============================================================

Commands:

cat /root/src/eucalyptus/euca-demo/scripts/demo-05-user-data-2.sh

Waiting  1 seconds... Done

# cat /root/src/eucalyptus/euca-demo/scripts/demo-05-user-data-2.sh
#!/bin/bash -eux
#
# Script to configure demo-05 instances - version 2
#
# This is a script meant to be run via cloud-init to do simple initial configuration
# of the Demo 05 Instances created by the associated LaunchConfiguration and 
# AutoScaleGroup.
#

# fix hostname to be more AWS like
local_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/local-ipv4)
public_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/public-ipv4)
hostname=ip-${local_ipv4//./-}.prc.eucalyptus-systems.com
sed -i -e "s/HOSTNAME=.*/HOSTNAME=$hostname/" /etc/sysconfig/network
hostname $hostname

# setup hosts
cat << EOF >> /etc/hosts
$local_ipv4      $hostname ${hostname%%.*}
EOF

# Install Apache
yum install -y httpd mod_ssl

# Configure Apache to display a test page showing the host internal IP address
cat << EOF >> /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Demo 05, Version 2!</title>
<style>
    body {
        width: 50em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Demo 05, Version 2!</h1>

<p>You're viewing a website running on the host with internal address: $(hostname)</p>
</body>
</html>
EOF

# Configure Apache to start on boot
chkconfig httpd on
service httpd start


Waiting  1 seconds... Done

============================================================

15. Create a Replacement LaunchConfiguration
    - This will replace the original User-Data Script with a
      modified version which will alter the home page

============================================================

Commands:

euscale-create-launch-config DemoLC-2 --image-id emi-a967783f --instance-type m1.small --monitoring-enabled \
                                      --key=admin-demo --group=DemoSG \
                                      --user-data-file=/root/src/eucalyptus/euca-demo/scripts/demo-05-user-data-2.sh

euscale-describe-launch-configs DemoLC
euscale-describe-launch-configs DemoLC-2

Waiting  1 seconds... Done

# euscale-create-launch-config DemoLC-2 --image-id emi-a967783f --instance-type m1.small --monitoring-enabled \
>                                       --key=admin-demo --group=DemoSG \
>                                       --user-data-file=/root/src/eucalyptus/euca-demo/scripts/demo-05-user-data-2.sh
#
# euscale-describe-launch-configs DemoLC
LAUNCH-CONFIG   DemoLC  emi-a967783f    m1.small
# euscale-describe-launch-configs DemoLC-2
LAUNCH-CONFIG   DemoLC-2        emi-a967783f    m1.small

Waiting  1 seconds... Done

============================================================

16. Update an AutoScalingGroup
    - This replaces the original LaunchConfiguration with
      it's replacement created above

============================================================

Commands:

euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2

euscale-describe-auto-scaling-groups DemoASG

Waiting  1 seconds... Done

# euscale-update-auto-scaling-group DemoASG --launch-configuration DemoLC-2
#
# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-c68ed8be      default InService       Healthy DemoLC
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

Waiting  1 seconds... Done

============================================================

17. Trigger AutoScalingGroup Instance Replacement
    - We will terminate an existing Instance of the AutoScalingGroup,
      and confirm a replacement Instance is created with the new
      LaunchConfiguration and User-Data Script
    - Wait for a replacement instance to be "InService"
    - When done, one instance will use the new LaunchConfiguration,
      while the other will still use the old LaunchConfiguration
      (normally we'd iterate through all instances when updating the application)
    - NOTE: This can take about 140 - 200 seconds (per instance)

============================================================

Commands:

euscale-terminate-instance-in-auto-scaling-group i-c68ed8be -D --show-long

euscale-describe-auto-scaling-groups DemoASG

eulb-describe-instance-health DemoELB (repeat until both instances are back is "InService")

Waiting  1 seconds... Done

# euscale-terminate-instance-in-auto-scaling-group i-c68ed8be -D --show-long
INSTANCE        6fc5faa5-f43e-4846-8802-e846988979e9            InProgress      At 2015-01-30T01:17:47Z instance was taken out of service in response to a user request..           50      Terminating EC2 instance: i-c68ed8be    2015-01-30T01:17:47.293Z
#

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
INSTANCE        i-ae53fb01      default Pending Healthy DemoLC-2

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
INSTANCE        i-ae53fb01      default Pending Healthy DemoLC-2

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
INSTANCE        i-ae53fb01      default InService       Healthy DemoLC-2

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
INSTANCE        i-ae53fb01      default InService       Healthy DemoLC-2

# eulb-describe-instance-health DemoELB
INSTANCE        i-ba4062be      InService
INSTANCE        i-ae53fb01      OutOfService

At least 2 instances are not "InService". Waiting 20 seconds... Done

# euscale-describe-auto-scaling-groups DemoASG
AUTO-SCALING-GROUP      DemoASG DemoLC-2        default DemoELB 2       4       2       OldestLaunchConfiguration
INSTANCE        i-ba4062be      default InService       Healthy DemoLC
INSTANCE        i-ae53fb01      default InService       Healthy DemoLC-2

# eulb-describe-instance-health DemoELB
INSTANCE        i-ae53fb01      InService
INSTANCE        i-ba4062be      InService

============================================================

18. Confirm updated webpage is visible
    - Attempt to display webpage first directly via instances,
      then through the ELB

============================================================

Commands:

w3m -dump euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com

w3m -dump euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com

w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com

Waiting  1 seconds... Done

# w3m -dump euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-212.prc.eucalyptus-systems.com

#
# w3m -dump euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05, Version 2!

You're viewing a website running on the host with internal address:
ip-10-104-45-249.prc.eucalyptus-systems.com

#
# w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05!

You're viewing a website running on the host with internal address:
ip-10-104-45-212.prc.eucalyptus-systems.com

# w3m -dump DemoELB-876690818618.lb.fb.mjc.prc.eucalyptus-systems.com
Welcome to Demo 05, Version 2!

You're viewing a website running on the host with internal address:
ip-10-104-45-249.prc.eucalyptus-systems.com


Waiting  1 seconds... Done

============================================================

19. Delete the AutoScalingGroup
    - We must first reduce sizes to zero
    - Pause a bit longer for changes to be acted upon

============================================================

Commands:

euscale-update-auto-scaling-group DemoASG --min-size 0 --max-size 0 --desired-capacity 0

euscale-delete-auto-scaling-group DemoASG

Waiting  1 seconds... Done

# euscale-update-auto-scaling-group DemoASG --min-size 0 --max-size 0 --desired-capacity 0

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   running admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default                    monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f    euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-249.cloud.internal   running admin-demo      0               m1.small        2015-01-30T01:19:23.246Z        default                    monitoring-enabled       10.104.45.148   10.104.45.249                   instance-store                                  hvm        b522c302-36f0-487f-991c-27d42b08dcd1_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG

Instances not yet "terminated". Waiting 20 seconds... Done

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default            monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f    euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-249.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:19:23.246Z        default            monitoring-enabled       10.104.45.148   10.104.45.249                   instance-store                                  hvm        b522c302-36f0-487f-991c-27d42b08dcd1_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG

Instances not yet "terminated". Waiting 20 seconds... Done

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default            monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f    euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-249.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:19:23.246Z        default            monitoring-enabled       10.104.45.148   10.104.45.249                   instance-store                                  hvm        b522c302-36f0-487f-991c-27d42b08dcd1_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG

Instances not yet "terminated". Waiting 20 seconds... Done

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default            monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f    euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-249.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:19:23.246Z        default            monitoring-enabled       10.104.45.148   10.104.45.249                   instance-store                                  hvm        b522c302-36f0-487f-991c-27d42b08dcd1_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG

Instances not yet "terminated". Waiting 20 seconds... Done

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f    euca-10-104-45-188.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-212.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:14:43.418Z        default            monitoring-enabled       10.104.45.188   10.104.45.212                   instance-store                                  hvm        751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f    euca-10-104-45-148.cloud.fb.mjc.prc.eucalyptus-systems.com      euca-10-104-45-249.cloud.internal   shutting-down   admin-demo      0               m1.small        2015-01-30T01:19:23.246Z        default            monitoring-enabled       10.104.45.148   10.104.45.249                   instance-store                                  hvm        b522c302-36f0-487f-991c-27d42b08dcd1_default_1   sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG

Instances not yet "terminated". Waiting 20 seconds... Done

# euca-describe-instances i-ba4062be
i-ae53fb01
RESERVATION     r-e6fc37a8      876690818618    DemoSG
INSTANCE        i-ba4062be      emi-a967783f                    terminated      admin-demo      0               m1.small        2015-01-30T01:14:43.418Z    default                         monitoring-enabled                                      instance-store     hvm              751dc4b7-5f6f-444d-ad6d-c616889f90ca_default_1  sg-8dbd1b50                             x86_64
TAG     instance        i-ba4062be      aws:autoscaling:groupName       DemoASG
RESERVATION     r-80a2be3d      876690818618    DemoSG
INSTANCE        i-ae53fb01      emi-a967783f                    terminated      admin-demo      0               m1.small        2015-01-30T01:19:23.246Z    default                         monitoring-enabled                                      instance-store     hvm              b522c302-36f0-487f-991c-27d42b08dcd1_default_1  sg-8dbd1b50                             x86_64
TAG     instance        i-ae53fb01      aws:autoscaling:groupName       DemoASG
# euscale-delete-auto-scaling-group DemoASG
#

Waiting  1 seconds... Done

============================================================

20. Delete the Alarms

============================================================

Commands:

euwatch-delete-alarms DemoAddNodesAlarm
euwatch-delete-alarms DemoDelNodesAlarm

Waiting  1 seconds... Done

# euwatch-delete-alarms DemoAddNodesAlarm
# euwatch-delete-alarms DemoDelNodesAlarm

Waiting  1 seconds... Done

============================================================

21. Delete the LaunchConfigurations

============================================================

Commands:

euscale-delete-launch-config DemoLC
euscale-delete-launch-config DemoLC-2

Waiting  1 seconds... Done

# euscale-delete-launch-config DemoLC
# euscale-delete-launch-config DemoLC-2

Waiting  1 seconds... Done

============================================================

22. Delete the ElasticLoadBalancer

============================================================

Commands:

eulb-delete-lb DemoELB

Waiting  1 seconds... Done

# eulb-delete-lb DemoELB

Waiting  1 seconds... Done

============================================================

23. Delete the Security Group

============================================================

Commands:

euca-delete-group DemoSG

Waiting  1 seconds... Done

# euca-delete-group DemoSG
RETURN  true

Waiting  1 seconds... Done
============================================================

24. List remaining resources
    - Confirm we are back to our initial set

============================================================

Commands:

euca-describe-images

euca-describe-keypairs

euca-describe-groups

eulb-describe-lbs

euca-describe-instances

euscale-describe-launch-configs

euscale-describe-auto-scaling-groups

euscale-describe-policies

euwatch-describe-alarms

Waiting  1 seconds... Done

# euca-describe-images
IMAGE   emi-a967783f    images/centos.raw.manifest.xml  107345199026    available       private x86_64  machine                    instance-store   hvm
#
# euca-describe-keypairs
KEYPAIR admin-demo      4a:17:c2:c3:f6:62:87:b9:68:fe:c4:25:ee:b8:54:8e:0e:66:a4:0f
#
# euca-describe-groups
GROUP   sg-d755e354     876690818618    default default group
#
# eulb-describe-lbs
#
# euca-describe-instances
RESERVATION     r-992de909      876690818618    DemoSG
INSTANCE        i-c68ed8be      emi-a967783f                    terminated      admin-demo      0               m1.small        2015-01-30T01:14:43.389Z    default                         monitoring-enabled                                      instance-store     hvm              f2431e79-8062-48b8-b95b-b6a5b2ac1f5b_default_1  sg-8dbd1b50                             x86_64
TAG     instance        i-c68ed8be      aws:autoscaling:groupName       DemoASG
#
# euscale-describe-launch-configs
#
# euscale-describe-auto-scaling-groups
#
# euscale-describe-policies
#
# euwatch-describe-alarms

Waiting  1 seconds... Done

Eucalyptus SecurityGroup, ElasticLoadBalancer, LaunchConfiguration,
           AutoScalingGroup and User-Data Script testing complete (time: 00:14:04)
