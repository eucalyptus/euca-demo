# Demo 20: CloudFormation: Simple

This document describes the manual procedure to run the CloudFormation Simple demo via Euca2ools

This variant can be run by any user with the appropriate permissions, as long as Euca2ools
has been configured with the appropriate credentials, and the account was initialized with
demo baseline dependencies. This example uses the hp-aw2-1 region, demo account and demo user.

In examples below, credentials are specified via the --region=USER@REGION option, but
to shorten the command line, you can export the AWS_DEFAULT_REGION environment variable with
the same value instead.

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
    euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                         --region=hp-aw2-1-demo-demo@hp-aw2-1 | cut -f1,2,3

    euca-describe-keypairs --filter "key-name=demo" \
                           --region=hp-aw2-1-demo-demo@hp-aw2-1
    ```

2. Display Simple CloudFormation Template (Optional)

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
    euca-describe-groups --region=hp-aw2-1-demo-demo@hp-aw2-1

    euca-describe-instances --region=hp-aw2-1-demo-demo@hp-aw2-1
    ```

4. List existing CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    euform-describe-stacks --region=hp-aw2-1-demo-demo@hp-aw2-1
    ```

5. Create the Stack

    We first must lookup the EMI ID of the Image to be used for this Stack, so it can be passed in
    as an input parameter.

    ```bash
    image_id=$(euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                    --region=hp-aw2-1-demo-demo@hp-aw2-1 | cut -f2)

    euform-create-stack --template-file ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template \
                        --parameter DemoImageId=$image_id \
                        --region=hp-aw2-1-demo-demo@hp-aw2-1 \
                        SimpleDemoStack
    ```

6. Monitor Stack creation

    This stack can take 60 to 80 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    euform-describe-stacks --region=hp-aw2-1-demo-demo@hp-aw2-1

    euform-describe-stack-events --region=hp-aw2-1-demo-demo@hp-aw2-1 SimpleDemoStack | head -5
    ```

7. List updated Resources (Optional)

    Note addition of new Security Group and Instance

    ```bash
    euca-describe-groups --region=hp-aw2-1-demo-demo@hp-aw2-1

    euca-describe-instances --region=hp-aw2-1-demo-demo@hp-aw2-1
    ```

8. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of the Instance within the Stack.

    It can take 20 to 40 seconds after the Stack creation is complete before login is possible.

    ```bash
    instance_id=$(euform-describe-stack-resources --name SimpleDemoStack \
                                                  --logical-resource-id DemoInstance \
                                                  --region=hp-aw2-1-demo-demo@hp-aw2-1 | cut -f3)
    public_name=$(euca-describe-instances --region=hp-aw2-1-demo-demo@hp-aw2-1 $instance_id | grep "^INSTANCE" | cut -f4)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new Instance. Confirm the private IP, then
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

