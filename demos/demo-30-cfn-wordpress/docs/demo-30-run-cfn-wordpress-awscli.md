# Demo 30: CloudFormation: WordPress

This document describes the manual procedure to run the CloudFormation WordPress demo via AWS CLI
(AWS Command Line Interface).

### CloudFormation WordPress Demo Key Points

The following are key points illustrated in this demo:

* This demo demonstrates how CloudFormation Templates with simple modifications can work across
  both AWS and Eucalyptus Regions with identical results, as long as the Template references
  only supported Resources.
* This also shows how a sample workload, in this case WordPress, can be migrated from an AWS
  Account to a Eucalyptus Region via S3 Object transfer.
* This demo also shows the use of Roles and Instance Profiles, used by the Instance when
  saving the WordPress database backup to S3.
* It is possible to view, run and monitor activities and resources created by CloudFormation
  via the Eucalyptus or AWS Command line tools, or now within the Eucalyptus Console.

### Prerequisites

This variant can be run by any User with the appropriate permissions, as long as AWS CLI
has been configured with the appropriate credentials, and the Account was initialized with
demo baseline dependencies. See [this section](../../demo-00-initialize/docs) for details.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation 
where you will be running any scripts or using a Browser which will access the Eucalyptus
Console, so that you can run scripts or upload Templates or other files which may be needed.
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

In examples below, credentials are specified via the --profile PROFILE and --region REGION
options. Normally you could shorten the command lines by use of the AWS_DEFAULT_PROFILE and
AWS_DEFAULT_REGION environment variables set to appropriate values, but there is a conflict
which prevents that alternative for this demo. We must switch back and forth between AWS
and Eucalyptus, and explicit options make clear which system is the target of each command.

Before running this demo, please run the demo-30-initialize-cfn-wordpress.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-30-reset-cfn-wordpress.sh script, which will
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
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin

    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER

    export AWS_REGION=us-east-1
    export AWS_ACCOUNT=euca
    export AWS_USER=demo

    export AWS_PROFILE=$AWS_ACCOUNT-$AWS_USER
    ```

### Run CloudFormation WordPress Demo

1. Confirm existence of AWS Demo depencencies (Optional)

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile $AWS_PROFILE --region $AWS_REGION
    ```

2. Confirm existence of Eucalyptus Demo depencencies (Optional)

    The "CentOS-6-x86_64-CFN-AWSCLI" image should exist.

    The "demo" Key Pair should exist.

    ```bash
    aws ec2 describe-images --filter "Name=manifest-location,Values=images/CentOS-6-x86_64-CFN-AWSCLI.raw.manifest.xml" \
                            --profile $EUCA_PROFILE --region $EUCA_REGION | cut -f1,3,4

    aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                               --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

3. Download WordPress CloudFormation Template from AWS S3 Bucket

    ```bash
    aws s3 cp s3://demo-$AWS_ACCOUNT/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
           /var/tmp/WordPress_Single_Instance_Eucalyptus.template \
           --profile $AWS_PROFILE --region $AWS_REGION
    ```

4. Display WordPress CloudFormation Template (Optional)

    The WordPress Template creates an Instance Profile based on the "Demos" Role, then a
    Security Group and an Instance which references the Instance Profile. A User-Data
    script passed to the Instance installs and configures WordPress.

    Like most CloudFormation Templates, the WordPress Template uses the "AWSRegionArch2AMI" Map
    to lookup the AMI ID of the Image to use when creating new Instances, based on the Region
    in which the Template is run. Similar to AWS, each Eucalyptus Region will also have a unique
    EMI ID for the Image which must be used there.

    This Template has been modified to add a row containing the Eucalyptus Region EMI ID to this
    Map. It is otherwise identical to what is run in AWS.

    ```bash
    more /var/tmp/WordPress_Single_Instance_Eucalyptus.template
    ```

    [Example of WordPress_Single_Instance_Eucalyptus.template](../templates/WordPress_Single_Instance_Eucalyptus.template.example) (EMIs will vary).

5. List existing AWS Resources (Optional)

    So we can compare with what this demo creates

    ```bash
    aws ec2 describe-security-groups --profile $AWS_PROFILE --region $AWS_REGION

    aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION
    ```

4. List existing AWS CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks --profile $AWS_PROFILE --region $AWS_REGION
    ```

6. Create the AWS Stack

    We first must lookup the EMI ID of the image to be used for this stack, so it can be passed in
    as an input parameter.

    ```bash
    aws cloudformation create-stack --stack-name WordPressDemoStack \
                                    --template-body file:///var/tmp/WordPress_Single_Instance_Eucalyptus.template \
                                    --parameters ParameterKey=KeyName,ParameterValue=demo \
                                                 ParameterKey=InstanceType,ParameterValue=m1.medium \
                                                 ParameterKey=DBUser,ParameterValue=demo \
                                                 ParameterKey=DBPassword,ParameterValue=password \
                                                 ParameterKey=DBRootPassword,ParameterValue=password \
                                                 ParameterKey=EndPoint,ParameterValue=https://cloudformation.$AWS_REGION.amazonaws.com \
                                    --capabilities CAPABILITY_IAM \
                                    --profile $AWS_PROFILE --region $AWS_REGION
    ```
YOU ARE HERE

7. Monitor AWS Stack creation

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
    instance_id=$(aws cloudformation describe-stack-resources --stack-name SimpleDemoStack --logical-resource-id DemoInstance | cut -f4)
    public_name=$(aws ec2 describe-instances --instance-ids $instance_id | grep "^INSTANCES" | cut -f11)

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

