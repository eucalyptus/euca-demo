# Demo 30: CloudFormation: WordPress

This document describes the manual procedure to run the CloudFormation WordPress demo primarily
via the Eucalyptus Console (GUI). Some steps require Linux shell access to run scripts.

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

This variant can be run by any User with the appropriate permissions, as long the 
credentials are known, and the Account was initialized with demo baseline dependencies. 
See [this section](../../demo-00-initialize/docs) for details.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus 
Console, so that you can run scripts or upload Templates or other files which may be needed. 
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

Before running this demo, please run the demo-30-initialize-cfn-wordpress.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-30-reset-cfn-wordpress.sh script, which will
reverse all actions performed by this script so that it can be re-run.

### Define Parameters

The procedure steps in this document are meant to be static - run unchanged on the appropriate
consoles of each Region. To support reuse of this procedure on different environments with
different Regions, Accounts and Users, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, 
which will be referenced in GUI instructions and should be be pasted into each ssh session,
and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming console instructions and code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export EUCA_REGION=hp-aw2-1
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin

    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER

    export AWS_REGION=us-west-2
    export AWS_ACCOUNT=mjchp
    export AWS_USER=demo

    export AWS_USER_REGION=aws-$AWS_ACCOUNT-$AWS_USER@$AWS_REGION
    export AWS_PROFILE=$AWS_ACCOUNT-$AWS_USER
    ```

### Login to Management Consoles

This demo shows coordination between Eucalyptus and AWS Accounts, with most actions performed in parallel
across both Accounts in an interleaved manner. You will need to open two browser windows or tabs, and 
log into the Eucalyptus and AWS Consoles separately, then use each Console as specified in the steps
below.

Ideally, this demo should be shown on a wide-screen or multi-monitor/projector display, so that both
consoles can be seen side-by-side. If this is not possible, use two tabs in the same browser window.

1. Login to the AWS Console as the AWS Account Demo User

    Using your browser, open the appropriate [AWS Console](https://console.hp-aw2-1.hpcloudsvc.com),
    and login with the parameters referenced above as $AWS_ACCOUNT and $AWS_USER. The password will
    need to be obtained separately from the AWS Account Administrator.

    Arrange this window or tab to the LEFT of your screen.

    ![Login as AWS Account Demo User](../images/demo-30-run-cfn-wordpress-00-aws-login.png?raw=true)

2. Login to the Eucalyptus Console as the Demo Account Demo User

    Using your browser, open the appropriate [Eucalyptus Console](https://console.hp-aw2-1.hpcloudsvc.com),
    and login with the parameters referenced above as $EUCA_ACCOUNT and $EUCA_USER. The password will
    need to be obtained separately from the Demo Account Administrator.

    Arrange this window or tab to the RIGHT of your screen.

    ![Login as Eucalyptus Demo Account Demo User](../images/demo-30-run-cfn-wordpress-00-euca-login.png?raw=true)

### Run CloudFormation WordPress Demo

1. Confirm existence of AWS Demo depencencies (Optional)

    On the AWS Console, from the Console Home,

    ![AWS Console Home](../images/demo-30-run-cfn-wordpress-01-aws-console-home.png?raw=true)

    Select the EC2 Service to view the EC2 Dashboard.

    ![AWS EC2 Dashboard](../images/demo-30-run-cfn-wordpress-01-aws-ec2-dashboard.png?raw=true)

    From the EC2 Dashboard, Select Key Pairs from Left Navigation to view Key Pairs in the AWS Account.
    Confirm the "demo" Key Pair exists.

    ![AWS Key Pairs](../images/demo-30-run-cfn-wordpress-01-aws-key-pairs.png?raw=true)

2. Confirm existence of Eucalyptus Demo depencencies (Optional)

    On the Eucalyptus Console, from the Dashboard, use the top left Navigation icon to display the left Navigation Panel.

    ![Eucalyptus Dashboard with Navigation](../images/demo-30-run-cfn-wordpress-02-euca-dashboard.png?raw=true)

    Select Images to view Images which the Demo Account can use.
    Confirm the "centos66-cfn-init" image exists.

    ![Eucalyptus Images](../images/demo-30-run-cfn-wordpress-02-euca-images.png?raw=true)

    From the Dashboard, Select the Key pairs Tile to view Key Pairs in the Demo Account.
    Confirm the "demo" Key Pair exists.

    ![Eucalyptus Key Pairs](../images/demo-30-run-cfn-wordpress-02-euca-key-pairs.png?raw=true)

3. Download WordPress CloudFormation Template from AWS S3 Bucket
 
    On the AWS Console, from the Console Home, Select the S3 Service to view the S3 Dashboard.

    ![AWS S3 Dashboard](../images/demo-30-run-cfn-wordpress-03-aws-s3-dashboard.png?raw=true)

    From the S3 Dashboard, Select the "demo-$AWS_ACCOUNT" Bucket.

    ![AWS S3 Demo Bucket](../images/demo-30-run-cfn-wordpress-03-aws-s3-demo-bucket.png?raw=true)

    From the "demo-$AWS_ACCOUNT" Bucket List, Select the "demo-30-cfn-wordpress" Folder.

    ![AWS S3 Demo 30 Folder](../images/demo-30-run-cfn-wordpress-03-aws-s3-demo-30-folder.png?raw=true)

    From the "demo-30-wordpress" Folder List, Check "WordPress_Single_Instance_Eucalyptus.template",
    then Click the Action Menu, and select "download", then click the "Download" link in the Dialog
    which pops up. The file is saved to your ~/Downloads directory.

    ![AWS S3 Template Download](../images/demo-30-run-cfn-wordpress-03-aws-s3-template-download.png?raw=true)
 
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
 
    You can use your File Browser to open ~/Downloads/WordPress_Single_Instance_Eucalyptus.template,
    or view this [example WordPress_Single_Instance_Eucalyptus.template](../templates/WordPress_Single_Instance_Eucalyptus.template.example) (EMIs will vary).
 
5. List existing AWS Resources (Optional)

    So we can compare with what this demo creates

    On the AWS Console, from the Console Home, Select the EC2 Service to view the EC2 Dashboard, 
    then from the EC2 Dashboard, Select Security Groups from Left Navigation to view Security
    Groups in the AWS Account. Note what Security Groups exist for comparison with results after
    the WordPressDemoStack has been created.

    ![AWS Security Groups](../images/demo-30-run-cfn-wordpress-05-aws-security-groups.png?raw=true)

    Next, Select Instances from Left Navigation to view Instances in the AWS Account. Note what
    Instances exist for comparison with results after the WordPressDemoStack has been created.

    ![AWS Instances](../images/demo-30-run-cfn-wordpress-05-aws-instances.png?raw=true)

6. List existing AWS CloudFormation Stacks (Optional)

    On the AWS Console, from the Console Home, Select the CloudFormation Service to view the
    CloudFormation Dashboard.

    ![AWS EC2 Dashboard](../images/demo-30-run-cfn-wordpress-01-aws-ec2-dashboard.png?raw=true)

    From the EC2 Dashboard, Select Key Pairs from Left Navigation to view Key Pairs in the AWS Account.
    Confirm the "demo" Key Pair exists.

    ![AWS Key Pairs](../images/demo-30-run-cfn-wordpress-01-aws-key-pairs.png?raw=true)
YOU ARE HERE

7. Create the AWS Stack

    From the Stacks List Page, click the Create Button to create a new CloudFormation Stack.
    Enter "SimpleDemoStack" as the Name.
    
    Next, click on the Upload template Radio Button, then the Choose File Button. Find and
    select ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template.

    ![Create Stack - General](../images/demo-20-run-cfn-simple-06-create-general.png?raw=true)

    Press the Next Button to advance to the Parameters Page. Select "centos66" as the DemoImageId,
    and "demo" as the DemoKeyPair.

    ![Create Stack - Parameters](../images/demo-20-run-cfn-simple-06-create-parameters.png?raw=true)

    Press the CreateStack Button to initiate Stack creation.

7. Monitor AWS Stack creation

    Initiating Stack creation will automatically take you to the Stack General Tab, showing a 
    periodically updating view of the state of the stack objects. Review Stack status.

    ![Stack - General](../images/demo-20-run-cfn-simple-07-stack-01-details.png?raw=true)

    Click on the Events Tab. Review Stack Events.

    ![Stack - Events](../images/demo-20-run-cfn-simple-07-stack-01-events.png?raw=true)

    Click on the General Tab. Continue to monitor Stack Details until you notice the Stack is
    Completed.

    ![Stack - General](../images/demo-20-run-cfn-simple-07-stack-02-details.png?raw=true)

    Click on the Events Tab. Confirm all Events.

    ![Stack - Events](../images/demo-20-run-cfn-simple-07-stack-02-events.png?raw=true)

8. List updated AWS Resources (Optional)

    From the Dashboard, Select the Security groups Tile to view Security Groups in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Security Groups](../images/demo-20-run-cfn-simple-08-security-groups.png?raw=true)

    From the Dashboard, Select the Running instances Tile to view Instances in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Instances](../images/demo-20-run-cfn-simple-08-instances.png?raw=true)

    From the Instances page, Select the instance just created. Note the Public hostname,
    then select and copy it to the paste buffer for use in the next step.

    ![View Instance Details](../images/demo-20-run-cfn-simple-08-instance-details.png?raw=true)

9. Confirm ability to login to Instance

    Confirm you have the demo private key installed: ~/.ssh/demo_id_rsa. This file can
    be found [here](../../../keys/demo_id_rsa). Adjust the ssh command line as needed if
    you store your keys in a different location.

    From a separate ssh terminal application, use a command such as the following
    to login to the instance, replacing the public name shown with that observed in
    the instance details page.

    ```bash
    ssh -i ~/.ssh/demo_id_rsa centos@euca-15-185-206-78.eucalyptus.hp-aw2-1.hpcloudsvc.com
    ```

    Once you have successfully logged into the new instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

    ![Verify Instance](../images/demo-20-run-cfn-simple-09-validate.png?raw=true)

5. List existing AWS Resources (Optional)

    So we can compare with what this demo creates

    From the Dashboard, Select the Security groups Tile to view Security Groups in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Security Groups](../images/demo-20-run-cfn-simple-04-security-groups.png?raw=true)

    From the Dashboard, Select the Running instances Tile to view Instances in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Instances](../images/demo-20-run-cfn-simple-04-instances.png?raw=true)

5. List existing AWS CloudFormation Stacks (Optional)

    From the Dashboard, Select the Stacks Tile to view CloudFormation Stacks in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Stacks](../images/demo-20-run-cfn-simple-05-stacks.png?raw=true)

6. Create the AWS Stack

    From the Stacks List Page, click the Create Button to create a new CloudFormation Stack.
    Enter "SimpleDemoStack" as the Name.

    Next, click on the Upload template Radio Button, then the Choose File Button. Find and
    select ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/templates/Simple.template.

    ![Create Stack - General](../images/demo-20-run-cfn-simple-06-create-general.png?raw=true)

    Press the Next Button to advance to the Parameters Page. Select "centos66" as the DemoImageId,
    and "demo" as the DemoKeyPair.

    ![Create Stack - Parameters](../images/demo-20-run-cfn-simple-06-create-parameters.png?raw=true)

    Press the CreateStack Button to initiate Stack creation.

7. Monitor AWS Stack creation

    Initiating Stack creation will automatically take you to the Stack General Tab, showing a
    periodically updating view of the state of the stack objects. Review Stack status.

    ![Stack - General](../images/demo-20-run-cfn-simple-07-stack-01-details.png?raw=true)

    Click on the Events Tab. Review Stack Events.

    ![Stack - Events](../images/demo-20-run-cfn-simple-07-stack-01-events.png?raw=true)

    Click on the General Tab. Continue to monitor Stack Details until you notice the Stack is
    Completed.

    ![Stack - General](../images/demo-20-run-cfn-simple-07-stack-02-details.png?raw=true)

    Click on the Events Tab. Confirm all Events.

    ![Stack - Events](../images/demo-20-run-cfn-simple-07-stack-02-events.png?raw=true)

8. List updated AWS Resources (Optional)

    From the Dashboard, Select the Security groups Tile to view Security Groups in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Security Groups](../images/demo-20-run-cfn-simple-08-security-groups.png?raw=true)

    From the Dashboard, Select the Running instances Tile to view Instances in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Instances](../images/demo-20-run-cfn-simple-08-instances.png?raw=true)

    From the Instances page, Select the instance just created. Note the Public hostname,
    then select and copy it to the paste buffer for use in the next step.

    ![View Instance Details](../images/demo-20-run-cfn-simple-08-instance-details.png?raw=true)

9. Confirm ability to login to Instance

    Confirm you have the demo private key installed: ~/.ssh/demo_id_rsa. This file can
    be found [here](../../../keys/demo_id_rsa). Adjust the ssh command line as needed if
    you store your keys in a different location.

    From a separate ssh terminal application, use a command such as the following
    to login to the instance, replacing the public name shown with that observed in
    the instance details page.

    ```bash
    ssh -i ~/.ssh/demo_id_rsa centos@euca-15-185-206-78.eucalyptus.hp-aw2-1.hpcloudsvc.com
    ```

    Once you have successfully logged into the new instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

    ![Verify Instance](../images/demo-20-run-cfn-simple-09-validate.png?raw=true)

