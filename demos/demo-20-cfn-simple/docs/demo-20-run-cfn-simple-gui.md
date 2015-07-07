# Demo 20: CloudFormation: Simple

This document describes the manual procedure to run the CloudFormation Simple demo via the GUI.

This script will use the Eucalyptus Console for the hp-gol01-f1 region, located here:
https://console.hp-gol01-f1.mjc.prc.eucalyptus-systems.com, in the commands and screen shots
below. Adjust as needed to your own system.

A demo account should have been created and initialized in advance. This account can be
created with any name, allowing for multiple demo accounts. The instructions below assume
the demo account was created with the name "demo".

Prior to running this demo, please run the demo-20-initialize-cfn-simple.sh script, which
will confirm that all dependencies exist and perform any demo-specific initialization
required.

### Run CloudFormation Simple Demo via the Eucalyptus Console

1. Login to the Eucalyptus Console as the Demo Account Administrator

    Using your browser, open: https://console.hp-aw2-1.hpcloudsvc.com.
    [Login as Demo Account Administrator](../images/demo-20-run-cfn-simple-01-login.png?raw=true)

2. Confirm existence of Demo depencencies

    From the Dashboard, use the top left Navigation icon to display the left Navigation Panel,
    then Select Images to View Images which the Demo Account can use.
    [View Images](../images/demo-20-run-cfn-simple-02-images.png?raw=true)

    The "centos66" image should exist.

    Return to the Dashboard, then select the Key Pairs Tile to View Key Pairs in the Demo Account.
    [View Key Pairs](../images/demo-20-run-cfn-simple-02-key-pairs.png?raw=true)

    The "demo" Key Pair should exist.
    ```

3. List initial Resources

4. List initial CloudFormation Stacks

5. Display Simple CloudFormation template

6. Create the Stack

7. Monitor Stack creation

8. List updated Resources

9. Confirm ability to login to Instance

