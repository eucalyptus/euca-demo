# Demo 20: CloudFormation: Simple

This document describes the manual procedure to run the CloudFormation Simple demo via AWS CLI
(AWS Command Line Interface).

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

Before running this demo, please run the demo-20-initialize-cfn-simple.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-20-reset-cfn-simple.sh script, which will
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

    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER
    ```

### Run CloudFormation Simple Demo

1. Confirm existence of Demo depencencies (Optional)

    The "CentOS-6-x86_64-GenericCloud" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                            --query 'Images[].[Name, ImageId, ImageLocation, Description]' \
                            --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --query 'KeyPairs[].[KeyName, KeyFingerprint]' \
                               --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

2. Display Simple CloudFormation template (Optional)

    The Simple Template creates a Security Group and an Instance, which references a Key Pair and
    an Image created externally and passed in as parameters

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template
    ```

    [Example of Simple.template](../templates/Simple.template).

3. List existing Resources (Optional)

    So we can compare with what this demo creates

    ```bash
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-instances --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

4. List existing CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

5. Create the Stack

    We first must lookup the EMI ID of the Image to be used for this Stack, so it can be passed in
    as an input parameter.

    ```bash
    image_id=$(aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                       --query 'Images[].ImageId' \
                                       --profile $EUCA_PROFILE --region $EUCA_REGION --output text)

    aws cloudformation create-stack --stack-name SimpleDemoStack \
                                    --template-body file://~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template \
                                    --parameters ParameterKey=DemoImageId,ParameterValue=$image_id \
                                    --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

6. Monitor Stack creation

    This stack can take 60 to 80 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    aws cloudformation describe-stacks --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws cloudformation describe-stack-events --stack-name SimpleDemoStack --max-items 5 \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

7. List updated Resources (Optional)

    Note addition of new Security Group and Instance

    ```bash
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION --output text

    aws ec2 describe-instance --profile $EUCA_PROFILE --region $EUCA_REGION --output text
    ```

8. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of the Instance within the Stack.

    It can take 20 to 40 seconds after the Stack creation is complete before login is possible.

    ```bash
    instance_id=$(aws cloudformation describe-stack-resources --stack-name SimpleDemoStack --logical-resource-id DemoInstance \
                                                              --query 'StackResources[].PhysicalResourceId' \
                                                              --profile $EUCA_PROFILE --region $EUCA_REGION --output text)
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

