# Demo 21: CloudFormation: ELB

This document describes the manual procedure to run the CloudFormation ELB demo via Euca2ools

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

Before running this demo, please run the demo-21-initialize-cfn-elb.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-21-reset-cfn-elb.sh script, which will
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

### Run CloudFormation ELB Demo

1. Confirm existence of Demo depencencies (Optional)

    The "CentOS-6-x86_64-GenericCloud" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                         --region $EUCA_USER_REGION | cut -f1,2,3

    euca-describe-keypairs --filter "key-name=demo" \
                           --region $EUCA_USER_REGION
    ```

2. Display ELB CloudFormation Template (Optional)

    The ELB Template creates a Security Group, and ELB and a pair of Instances attached to the ELB, which reference
    a Key Pair and an Image created externally and passed in as parameters

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-21-cfn-elb/templates/ELB.template
    ```

    [Example of ELB.template](../templates/ELB.template).

3. List existing Resources (Optional)

    So we can compare with what this demo creates

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    eulb-describe-lbs --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION
    ```

4. List existing CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    euform-describe-stacks --region $EUCA_USER_REGION
    ```

5. Create the Stack

    We first must lookup the EMI ID of the Image to be used for this Stack, so it can be passed in
    as an input parameter.

    ```bash
    image_id=$(euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml" \
                                    --region $EUCA_USER_REGION | cut -f2)

    euform-create-stack --template-file ~/src/eucalyptus/euca-demo/demos/demo-21-cfn-elb/templates/ELB.template \
                        --parameter WebServerImageId=$image_id \
                        --region $EUCA_USER_REGION \
                        ELBDemoStack
    ```

6. Monitor Stack creation

    This stack can take 60 to 80 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    euform-describe-stacks --region $EUCA_USER_REGION

    euform-describe-stack-events --region $EUCA_USER_REGION ELBDemoStack | head -5
    ```

7. List updated Resources (Optional)

    Note addition of new Security Group and Instance

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    eulb-describe-lbs --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION
    ```

8. Confirm ability to login to Instance

    We must first use some logic to find the public DNS name of an Instance within the Stack.

    It can take 20 to 40 seconds after the Stack creation is complete before login is possible.

    ```bash
    instance_id=$(euform-describe-stack-resources --name ELBDemoStack \
                                                  --logical-resource-id WebServerInstance1 \
                                                  --region $EUCA_USER_REGION | cut -f3)
    public_name=$(euca-describe-instances --region $EUCA_USER_REGION $instance_id | grep "^INSTANCE" | cut -f4)

    ssh -i ~/.ssh/demo_id_rsa centos@$public_name
    ```

    Once you have successfully logged into the new Instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

