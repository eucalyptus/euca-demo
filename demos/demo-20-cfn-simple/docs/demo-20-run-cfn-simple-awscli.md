# Demo 20: CloudFormation: Simple

This document describes the manual procedure to run the CloudFormation Simple demo via the AWS CLI

This variant can be run by any user, as long as the AWS_DEFAULT_PROFILE environment variable
has been set to reference the demo Eucalyptus system with the appropriate credentials.

A demo account should have been created and initialized in advance. This account can be
created with any name, allowing for multiple demo accounts. The instructions below assume
the demo account was created with the name "demo".

Prior to running this demo, please run the demo-20-initialize-cfn-simple.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

### Run CloudFormation Simple Demo via the AWS Command Line

1. Use Demo Account Demo User credentials

    ```bash
    export AWS_DEFAULT_REGION=hp-aw2-1
    export AWS_DEFAULT_PROFILE=$AWS_DEFAULT_REGION-demo-demo
    ```

2. Confirm existence of Demo depencencies

    The "CentOS-6-x86_64-GenericCloud" image should exist.

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-images

    aws ec2 describe-key-pairs
    ```

3. List initial Resources

    So we can compare with what this demo creates

    ```bash
    aws ec2 describe-security-groups

    aws ec2 describe-instances
    ```

4. List initial CloudFormation Stacks

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks
    ```

5. Display Simple CloudFormation template

    The Simple.template creates a security group and an instance, which references a keypair and
    an image created externally and passed in as parameters

    ```bash
    more ~/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template
    ```

    Contents of Simple.template

    ```bash
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

6. Create the Stack

    We first must lookup the EMI ID of the image to be used for this stack, so it can be passed in
    as an input parameter.

    ```bash
    image_id=$((aws ec2 describe-images | grep CentOS-6-x86_64-GenericCloud.raw.manifest.xml | cut -f4)

    aws cloudformation create-stack --template-file ~/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template \
                                    -p DemoImageId=$image_id SimpleDemoStack
    ```

7. Monitor Stack creation

    This stack can take 60 to 80 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    aws cloudformation describe-stacks

    aws cloudformation describe-stack-events --stack-name SimpleDemoStack --max-items 5
    ```

8. List updated Resources

    Note addition of new group and instance

    ```bash
    aws ec2 describe-security-groups

    aws ec2 describe-instances
    ```

9. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of the most recently launched instance.

    It can take 20 to 40 seconds after the Stack creation is complete before login is possible.

    ```bash
    public_name=$(aws ec2 describe-instances | grep "^INSTANCE" | cut -f8,11 | sort -k1 | tail -1 | cut -f2)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

### CloudFormation Simple Demo Key Points
    
The following are key points illustrated in this demo:
    
* This demo demonstrates use of CloudFormation via a Simple template, and is intended as an
  introduction to this feature in Eucalyptus.
* It is possible to view, run and monitor activities and resources created by CloudFormation
  via the Command line, or now within the Eucalyptus Console.

