# Demo 30: CloudFormation: WordPress (Short)

This document describes the manual procedure to run the CloudFormation WordPress demo primarily
via the Eucalyptus Console (GUI). Some steps require Linux shell access to run scripts.

This variant has been shortened to show only the required steps in the Eucalyptus Account, as
well as the migration itself, and assumes all steps have been run in advance in the AWS Account
and left running to save time. Certain steps have also been rearranged or changed slightly to
improve the flow in live settings. There is a [long](demo-30-run-cfn-wordpress-gui.md) version
of this procedure which should be run at least once in each new environment to ensure all
prerequisites have been met before you switch to use of this short variant.

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
required. This script **should** be run with the "-m e" option to limit actions to the
Eucalyptus Account, but there is no harm if this option is omitted.

After running this demo, please run the demo-30-reset-cfn-wordpress.sh script, which will
reverse all actions performed by this script so that it can be re-run. This script **MUST**
be run with the "-m e" option to limit actions to the Eucalyptus Account, otherwise the
AWS Account CloudFormation Stack will be deleted, and the long version of this procedure
will have to be run again before this short version will again work.

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
    export EUCA_DOMAIN=hpcloudsvc.com
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin

    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER

    export AWS_REGION=us-east-1
    export AWS_ACCOUNT=euca
    export AWS_USER=demo

    export AWS_USER_REGION=aws-$AWS_ACCOUNT-$AWS_USER@$AWS_REGION
    export AWS_PROFILE=$AWS_ACCOUNT-$AWS_USER
    ```

### Login to Management Consoles and a Terminal Session

This demo shows coordination between Eucalyptus and AWS Accounts, with most actions performed in parallel
across both Accounts in an interleaved manner. You will need to open two browser windows or tabs, and 
log into the Eucalyptus and AWS Consoles separately, then use each Console as specified in the steps
below.

Additionally, the migration of the WordPress database requires a script which must be run in a terminal
session.

Ideally, this demo should be shown on a wide-screen or multi-monitor/projector display, so that both
consoles can be seen side-by-side. If this is not possible, use two tabs in the same browser window.

1. Login to the AWS Console as the AWS Account Demo User

    Using your browser, open the appropriate [AWS Console](https://140601064733.signin.aws.amazon.com/console),
    and login with the parameters referenced above as $AWS_USER. The password will need to be
    obtained separately from the AWS Account Administrator.

    Arrange this window or tab to the LEFT of your screen.

    ![Login as AWS Account Demo User](../images/demo-30-run-cfn-wordpress-00-aws-login.png?raw=true)

2. Login to the Eucalyptus Console as the Demo Account Demo User

    Using your browser, open the appropriate [Eucalyptus Console](https://console.hp-aw2-1.hpcloudsvc.com),
    and login with the parameters referenced above as $EUCA_ACCOUNT and $EUCA_USER. The password will
    need to be obtained separately from the Demo Account Administrator.

    Arrange this window or tab to the RIGHT of your screen.

    ![Login as Eucalyptus Demo Account Demo User](../images/demo-30-run-cfn-wordpress-00-euca-login.png?raw=true)

3. Login to a Terminal Session

    Using your favorite SSH Terminal appliocation, open a terminal session into the Eucalyptus CLC.

    This can also be any other Enterprise Linux management workstation, as long as the credentials
    for both the AWS Account and Eucalyptus Demo Account have been configured, and the euca-demo
    GitHub project which contains the migration script has been downloaded to the
    ~/src/eucalyptus/euca-demo directory.

    Arrange this window UNDERNEATH the browser windows, as the steps which require this are run last.

    ![Login to Terminal Session](../images/demo-30-run-cfn-wordpress-00-ssh-login.png?raw=true)

### Run CloudFormation WordPress Demo

1. Download WordPress CloudFormation Template from AWS S3 Bucket

   It may be safe to skip this step if a local copy of the WordPress_Single_Instance_Eucalyptus.template
   file exists on the host where you will be running this demo.
 
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
 
2. Create the Eucalyptus Stack

    On the Eucalyptus Console, from the Stacks List Page, click the Create Button to create a
    new CloudFormation Stack.  Enter "WordPressDemoStack" as the Name.

    Next, click on the Upload template Radio Button, then the Choose File Button. Find and
    select ~/Downloads/WordPress_Single_Instance_Eucalyptus.template.

    ![Eucalyptus Create Stack - General](../images/demo-30-run-cfn-wordpress-16-euca-create-general.png?raw=true)

    Press the Next Button to advance to the Parameters Page. Enter 
    "https://cloudformation.$AWS_REGION.$AWS_DOMAIN" (replacing $AWS_REGION and $AWS_DOMAIN
    with the values defined above) as the EndPoint. Select "m1.medium" as the InstanceType.
    Leave SSHLocation set to the default of "0.0.0.0/0". Select "demo" as the KeyName.
    Enter "password" as the DBPassword, "demo" as the DBUser and "password" as the
    DBRootPassword. Leave DBName set to the default of "wordpressdb".

    ![Eucalyptus Create Stack - Parameters](../images/demo-30-run-cfn-wordpress-16-euca-create-parameters.png?raw=true)

    Press the CreateStack Button to initiate Stack creation.

3. Start to Monitor Eucalyptus Stack creation

    Due to the time it will take to complete creation of the Stack, we will monitor just a bit in
    this step, jump to some other steps to fill the time, then return to monitoring until 
    completion in a later step.

    Continuing on the Eucalyptus Console, initiating Stack creation will automatically take you
    to the Stack General Tab, showing a periodically updating view of the state of the Stack
    Resources. Review Stack status.

    ![Eucalyptus Stack - General](../images/demo-30-run-cfn-wordpress-17-euca-stack-01-general.png?raw=true)

    Click on the Events Tab. Review Stack Events.

    ![Eucalyptus Stack - Events](../images/demo-30-run-cfn-wordpress-17-euca-stack-01-events.png?raw=true)

4. Display AWS WordPress Template and Blog

    The WordPress Template creates an Instance Profile based on the "Demos" Role, then a
    Security Group and an Instance which references the Instance Profile. A User-Data
    script passed to the Instance installs and configures WordPress.

    Like most CloudFormation Templates, the WordPress Template uses the "AWSRegionArch2AMI" Map
    to lookup the AMI ID of the Image to use when creating new Instances, based on the Region
    in which the Template is run. Similar to AWS, each Eucalyptus Region will also have a unique
    EMI ID for the Image which must be used there.

    This Template has been modified to add a row containing the Eucalyptus Region EMI ID to this
    Map. It is otherwise identical to what is run in AWS, so we will display the template via
    the AWS Console.

    On the AWS Console, from the Console Home, Select the CloudFormation Service to view the
    CloudFormation Dashboard, then from the CloudFormation Dashboard, Select the
    "WordPressDemoStack", then Select the "Template" Tab.

    ![AWS Stack Template](../images/demo-30-run-cfn-wordpress-10-aws-stack-template.png?raw=true)

    Walk through sections of the Template as needed based on your audience and any questions.
    Highlight the lines in the "AWSRegionArch2AMI" Map which were added for Eucalyptus.

    Select the "Outputs" Tab to view the WordPress Blog URL.

    ![AWS Stack Outputs](../images/demo-30-run-cfn-wordpress-10-aws-stack-outputs.png?raw=true)

    Right-Click on the "WebsiteURL" Link and open it in another window or tab. View the
    WordPress Blog, with existing posts.

    ![AWS WordPress](../images/demo-30-run-cfn-wordpress-13-aws-wordpress-confirm.png?raw=true)

5. Create WordPress Blog Post on AWS Instance

    On the AWS WordPress Blog, login using the username and password provided during the
    initialization step, then click on the "Write your first blog post" link and create
    a new blog post.

    ![AWS Create Blog Post](../images/demo-30-run-cfn-wordpress-13-aws-wordpress-post.png?raw=true)

    Confirm new post is visible.

    ![AWS Create Blog Post](../images/demo-30-run-cfn-wordpress-13-aws-wordpress-confirm.png?raw=true)

6. Finish Monitoring Eucalyptus Stack creation

    Return to the Eucalyptus Console, where you should still be on the CloudFormation Dashboard, and
    click on the General Tab. Continue to monitor Stack Details until you notice the Stack is
    Completed. View the Resources created. Note the Security Group and Instance IDs.

    ![Eucalyptus Stack - General](../images/demo-30-run-cfn-wordpress-17-euca-stack-02-general.png?raw=true)

    Click on the Events Tab. Confirm all Events.

    ![Eucalyptus Stack - Events](../images/demo-30-run-cfn-wordpress-17-euca-stack-02-events.png?raw=true)

7. Obtain Eucalyptus Blog Details

    On the Eucalyptus Console, from the Dashboard, Select the Stacks Tile to view CloudFormation
    Stacks in the Demo Account, then Select "WordPressDemoStack" to view the Stack General Page.
    Select the "WebsiteURL" Link text, then copy this value to the paste buffer.

    ![Eucalyptus Stack Outputs](../images/demo-30-run-cfn-wordpress-19-euca-stack-outputs.png?raw=true)

    Open a new browser window or tab, and paste this value into the address bar.  View the
    WordPress Blog, awaiting initialization!

    ![Eucalyptus WordPress Unconfigured](../images/demo-30-run-cfn-wordpress-19-aws-wordpress.png?raw=true)

8. Backup WordPress on AWS Instance, and Restore to Eucalyptus Instance

    On the Terminal Session, run a script to migrate WordPress from AWS to Eucalyptus. This
    script will step through the commands necessary to perform the migration one-by-one, each
    time you press Enter.

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-30-cfn-wordpress/bin

    # If you are using default Eucalyptus parameters against the default AWS account:
    ./demo-30-migrate.sh

    # Otherwise, if any of the parameters are different, you can specify any or all of them:
    ./demo-30-migrate.sh -r $EUCA_REGION -a $EUCA_ACCOUNT -u $EUCA_USER \
                         -R $AWS_REGION  -A $AWS_ACCOUNT  -U $AWS_USER
    ```

    ![SSH Run Script](../images/demo-30-run-cfn-wordpress-21-ssh-run-script.png?raw=true)

    ![SSH Backup WordPress](../images/demo-30-run-cfn-wordpress-21-ssh-wordpress-backup.png?raw=true)

    ![SSH Restore WordPress](../images/demo-30-run-cfn-wordpress-22-ssh-wordpress-restore.png?raw=true)

9. Confirm WordPress Migration on Eucalyptus Instance

    On the Eucalyptus WordPress Blog, Confirm content matches the AWS WordPress Instance.

    ![Eucalyptus Confirm Blog](../images/demo-30-run-cfn-wordpress-23-euca-wordpress.png?raw=true)

