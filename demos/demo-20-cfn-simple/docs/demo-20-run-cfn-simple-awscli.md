# Demo 20: CloudFormation: Simple

This document describes the manual procedure to run the CloudFormation Simple demo via AWS CLI
(AWS Command Line Interface).

### CloudFormation Simple Demo Key Points
    
The following are key points illustrated in this demo:
    
* This demo demonstrates use of CloudFormation via a Simple template, and is intended as an
  introduction to this feature in Eucalyptus.
* It is possible to view, run and monitor activities and resources created by CloudFormation
  via the Eucalyptus or AWS Command line tools, or now within the Eucalyptus Console.

### Prepare CloudFormation Simple Demo

This variant can be run by any User with the appropriate permissions, as long as AWS CLI
has been configured with the appropriate credentials, and the Account was initialized with
demo baseline dependencies. This example uses the hp-aw2-1 Region, demo Account and demo User.

In examples below, credentials are specified via the --profile=PROFILE option, but
to shorten the command line, you can export the AWS_DEFAULT_PROFILE environment variable with
the same value instead.

You should unset the AWS_DEFAULT_REGION environment variable, or insure it is set to the
correct Region (without any optional USER@ prefix), prior to running the statements below as
AWS CLI will use any value found to override the default region of the profile, and it will 
break if the value contains the USER@ prefix.

Before running this demo, please run the demo-20-initialize-cfn-simple.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-20-reset-cfn-simple.sh script, which will
reverse all actions performed by this script so that it can be re-run.

### Run CloudFormation Simple Demo

1. Confirm existence of Demo depencencies (Optional)

    The "CentOS-6-x86_64-GenericCloud" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                            --profile=hp-aw2-1-demo-demo | cut -f1,3,4

    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile=hp-aw2-1-demo-demo
    ```

2. Display Simple CloudFormation template (Optional)

    The Simple Template creates a Security Group and an Instance, which references a Key Pair and
    an Image created externally and passed in as parameters

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template
    ```

    Contents of Simple.template

    ```json
    {
      "Parameters": {
        "DemoImageId": {
          "Description":"Image id",
          "Type":"String"
        },
        "DemoKeyPair": {
          "Description":"Key Pair",
          "Type":"String",
          "Default":"demo"
        }
      },
      "Resources" : {
        "DemoSecurityGroup": {
          "Type": "AWS::EC2::SecurityGroup",
          "Properties": {
            "GroupDescription" : "Security Group with Ingress Rule for DemoInstance",
            "SecurityGroupIngress" : [
              {
                "IpProtocol" : "tcp",
                "FromPort" : "22",
                "ToPort" : "22",
                "CidrIp" : "0.0.0.0/0"
              }
            ]
          }
        },
        "DemoInstance": {
          "Type": "AWS::EC2::Instance",
          "Properties": {
            "ImageId" : { "Ref":"DemoImageId" },
            "SecurityGroups" : [ 
              { "Ref" : "DemoSecurityGroup" } 
            ],
            "KeyName" : { "Ref" : "DemoKeyPair" }
          }
        }
      }
    }
    ```

3. List existing Resources (Optional)

    So we can compare with what this demo creates

    ```bash
    aws ec2 describe-security-groups --profile=hp-aw2-1-demo-demo

    aws ec2 describe-instances --profile=hp-aw2-1-demo-demo
    ```

4. List existing CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks --profile=hp-aw2-1-demo-demo
    ```

5. Create the Stack

    We first must lookup the EMI ID of the Image to be used for this Stack, so it can be passed in
    as an input parameter.

    ```bash
    image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                       --profile=hp-aw2-1-demo-demo | cut -f3)

    aws cloudformation create-stack --stack-name SimpleDemoStack \
                                    --template-body file://~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template \
                                    --parameters ParameterKey=DemoImageId,ParameterValue=$image_id \
                                    --profile=hp-aw2-1-demo-demo
    ```

6. Monitor Stack creation

    This stack can take 60 to 80 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    aws cloudformation describe-stacks --profile=hp-aw2-1-demo-demo

    aws cloudformation describe-stack-events --stack-name SimpleDemoStack --max-items 5 \
                                             --profile=hp-aw2-1-demo-demo
    ```

7. List updated Resources (Optional)

    Note addition of new Security Group and Instance

    ```bash
    aws ec2 describe-security-groups --profile=hp-aw2-1-demo-demo

    aws ec2 describe-instance --profile=hp-aw2-1-demo-demo
    ```

8. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of the Instance within the Stack.

    It can take 20 to 40 seconds after the Stack creation is complete before login is possible.

    ```bash
    instance_id=$(aws cloudformation describe-stack-resources --stack-name SimpleDemoStack \
                                                              --logical-resource-id DemoInstance \
                                                              --profile=hp-aw2-1-demo-demo | cut -f4)
    public_name=$(aws ec2 describe-instances --instance-ids $instance_id \
                                             --profile=hp-aw2-1-demo-demo | grep "^INSTANCES" | cut -f11)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new Instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

