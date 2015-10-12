# Demo 21: CloudFormation: ELB

This document describes the manual procedure to run the CloudFormation ELB demo via the 
Eucalyptus Console (GUI).

### Prerequisites 

This variant can be run by any User with the appropriate permissions, as long the
credentials are known, and the Account was initialized with demo baseline dependencies.
See [this section](../../demo-00-initialize/docs) for details.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus
Console, so that you can run scripts or upload Templates or other files which may be needed.
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

Before running this demo, please run the demo-21-initialize-cfn-elb.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-21-reset-cfn-elb.sh script, which will
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
    export EUCA_DOMAIN=hpcloudsvc.com
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin
    
    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    ```                                     

### Login to Management Console and a Terminal Session
    
Ideally, this demo should be shown on a wide-screen or multi-monitor/projector display, so that the
console and terminal session can be seen side-by-side.

1. Login to the Eucalyptus Console as the Demo Account Demo User

    Using your browser, open the appropriate [Eucalyptus Console](https://console.hp-aw2-1.hpcloudsvc.com),
    and login with the parameters referenced above as $EUCA_ACCOUNT and $EUCA_USER. The password will
    need to be obtained separately from the Demo Account Administrator.

    Arrange this window to the LEFT of your screen.

    ![Login as Eucalyptus Demo Account Demo User](../images/demo-21-run-cfn-elb-00-euca-login.png?raw=true)

2. Login to a Terminal Session

    Using your favorite SSH Terminal appliocation, open a terminal session into the Eucalyptus CLC.

    This can also be any other Enterprise Linux management workstation, as long as the credentials
    for the Eucalyptus Demo Account have been configured, and the euca-demo GitHub project has been
    downloaded to the ~/src/eucalyptus/euca-demo directory.

    Arrange this window to the RIGHT or UNDERNEATH the console browser window, as the steps which require this are run last.

    ![Login to Terminal Session](../images/demo-21-run-cfn-elb-00-ssh-login.png?raw=true)

### Run CloudFormation ELB Demo

1. Confirm existence of Demo depencencies (Optional)

    From the Dashboard, use the top left Navigation icon to display the left Navigation Panel.

    ![Dashboard with Navigation](../images/demo-21-run-cfn-elb-02-dashboard.png?raw=true)

    Then, Select Images to View Images which the Demo Account can use.
    Confirm the "centos66" image exists.

    ![View Images](../images/demo-21-run-cfn-elb-02-images.png?raw=true)

    From the Dashboard, Select the Key pairs Tile to View Key Pairs in the Demo Account.
    Confirm the "demo" Key Pair exists.

    ![View Key Pairs](../images/demo-21-run-cfn-elb-02-key-pairs.png?raw=true)

2. Display ELB CloudFormation Template (Optional)

    In another browser tab, open the [ELB.template](../templates/ELB.template) to view the ELB
    CloudFormation template we will use in this demo.

    ![View ELB.template](../images/demo-21-run-cfn-elb-03-elb-template.png?raw=true)

3. List existing Resources (Optional)

    From the Dashboard, Select the Security groups Tile to View Security Groups in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Security Groups](../images/demo-21-run-cfn-elb-04-security-groups.png?raw=true)

    From the Dashboard, Select the Load balancers Tile to View Load Balancers in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Load Balancers](../images/demo-21-run-cfn-elb-04-load-balancers.png?raw=true)

    From the Dashboard, Select the Running instances Tile to View Instances in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Instances](../images/demo-21-run-cfn-elb-04-instances.png?raw=true)

4. List existing CloudFormation Stacks (Optional)

    From the Dashboard, Select the Stacks Tile to View CloudFormation Stacks in the
    Demo Account. Note contents of list for comparison after creating Stack.

    ![View Stacks](../images/demo-21-run-cfn-elb-05-stacks.png?raw=true)

5. Create the Stack

    From the Stacks List Page, click the Create Button to create a new CloudFormation Stack.
    Enter "ELBDemoStack" as the Name.
    
    Next, click on the Upload template Radio Button, then the Choose File Button. Find and
    select ~/src/eucalyptus/euca-demo/demos/demo-21-cfn-elb/templates/ELB.template.

    ![Create Stack - General](../images/demo-21-run-cfn-elb-06-create-general.png?raw=true)

    Press the Next Button to advance to the Parameters Page. Select "centos66" as the WebServerImageId,
    and "demo" as the DemoKeyPair.

    ![Create Stack - Parameters](../images/demo-21-run-cfn-elb-06-create-parameters.png?raw=true)

    Press the CreateStack Button to initiate Stack creation.

6. Monitor Stack creation

    Initiating Stack creation will automatically take you to the Stack General Tab, showing a 
    periodically updating view of the state of the stack objects. Review Stack status.

    ![Stack - General](../images/demo-21-run-cfn-elb-07-stack-01-details.png?raw=true)

    Click on the Events Tab. Review Stack Events.

    ![Stack - Events](../images/demo-21-run-cfn-elb-07-stack-01-events.png?raw=true)

    Click on the General Tab. Continue to monitor Stack Details until you notice the Stack is
    Completed.

    ![Stack - General](../images/demo-21-run-cfn-elb-07-stack-02-details.png?raw=true)

    Click on the Events Tab. Confirm all Events.

    ![Stack - Events](../images/demo-21-run-cfn-elb-07-stack-02-events.png?raw=true)

7. List updated Resources (Optional)

    From the Dashboard, Select the Security groups Tile to View Security Groups in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Security Groups](../images/demo-21-run-cfn-elb-08-security-groups.png?raw=true)

    From the Dashboard, Select the Load balancers Tile to View Load Balancers in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Load Balancers](../images/demo-21-run-cfn-elb-08-load-balancers.png?raw=true)

    From the Dashboard, Select the Running instances Tile to View Instances in the
    Demo Account. Note updated contents of list, and compare with the initial set.

    ![View Instances](../images/demo-21-run-cfn-elb-08-instances.png?raw=true)

    From the Instances page, Select the instance with Logical Name WebServerInstance1. Note the
    Public hostname, then select and copy it to the paste buffer for use in the next step.

    ![View Instance Details](../images/demo-21-run-cfn-simple-08-instance-details.png?raw=true)

8. Confirm ability to login to Instance

    Confirm you have the demo private key installed: ~/.ssh/demo_id_rsa. This file can
    be found [here](../../../keys/demo_id_rsa). Adjust the ssh command line as needed if
    you store your keys in a different location.

    On the Terminal Session, use a command such as the following to login to the instance,
    replacing the public name shown with that observed in the instance details page.

    ```bash
    ssh -i ~/.ssh/demo_id_rsa centos@euca-15-185-206-78.eucalyptus.hp-aw2-1.hpcloudsvc.com
    ```

    Once you have successfully logged into the new instance. Confirm the private IP, then
    the public IP via the meta-data service, with the following commands:

    ```bash
    ifconfig

    curl http://169.254.169.254/latest/meta-data/public-ipv4; echo
    ```

    ![Verify Instance](../images/demo-21-run-cfn-elb-09-validate.png?raw=true)

