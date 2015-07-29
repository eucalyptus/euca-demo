# Demo 30 CloudFormation Wordpress AWS Summary

This is an outline of the steps required to run the wordpress repatriation demo,
on the AWS side, with coordination points to the Eucalyptus side.

We will use the Eucalyptus hp-aw2-2 region demo account demo user and the AWS mjchp account demo
user in code examples.

### AWS Account Creation and Initialization Steps

These are steps which must be run to create a new AWS Account, and take it up to the
point where the Demo Account Dependencies can be created to match what is created
within Eucalyptus Regions.

1. Create AWS Account

    Steps TBD, but we just need to have an account setup, with knowledge of either
    the Account-level credentials, or an administrative-level user credentials, which
    we will need to configure so that the demo initialization scripts can be run.


### AWS Account Demo Baseline Initialization Steps

These are steps to initialize a new Eucalyptus Region Management Workstation to run the Demos
contained in the euca-demo project which have AWS Account interaction. All demos in the euca-demo
project assume the baseline of Resources created in these scripts exist.

There is a bit of a chicken and egg problem when initializing the account. We need to first
setup an Account-level admin user on the Management Workstation, using the credentials obtained
when creating the account. That method is shown below.

If you do not have access to the Account-Level Access Keys, then you must have access to a
user which has been manually granted the "AdministratorAccess" managed policy. You will note
that one of the scripts below initializes an Administrators group which has this policy
attached for just this sort of user. We do not want to create any resources which will
break that script, so until the account-administrator script has been run be careful.

1. Initialize Eucalyptus Management Workstation with AWS Account

    This includes the following tasks:

    - Configures Euca2ools for the AWS Account Administrator
    - Configures AWSCLI for the AWS Account Administrator

    ```bash
    ./demo-01-initialize-aws-account.sh -r us-west-2 -a mjchp -A <account_access_key> -S <account_secret_key>
    ```

2. Initialize AWS Account Administrator

    This script should be run for each separate administrator of the Account. Once Administrator
    Users are created, the Account-level credentials should be changed and kept private to the
    Account owner. You can use the "-U admin" flag as shown to use an existing Administrators credentials
    when running additional scripts.

    While there are both AWSCLI and Euca2ools versions of this script, prefer the AWSCLI version as it
    is aware of managed IAM Policies, while as of this time Euca2ools is not.

    This includes the following tasks:

    - Creates the Administrators Group (named "Administrators")
    - Attaches the AdministratorAccess Managed Policy to the Administrators Group
    - Creates an administrator User (varies - specified as a required parameter)
    - Adds the administrator User to the Administrators Group
    - Creates the administrator User Login Profile
    - Creates the administrator User Access Key
    - Configures Euca2ools for the administrator User
    - Configures AWSCLI for the administrator User

    ```bash
    ./demo-02-initialize-aws-account-administrator-awscli.sh -r us-west-2 -a mjchp -u mcrawford -p <mcrawford_password>
    ./demo-02-initialize-aws-account-administrator-awscli.sh -r us-west-2 -a mjchp -u lwade -p <lwade_password> -U mcrawford
    ./demo-02-initialize-aws-account-administrator-awscli.sh -r us-west-2 -a mjchp -u bthomason -p <bthomason_password> -U mcrawford
    ```

3. Initialize AWS Account Dependencies

    There are two variants of this script which perform identical actions, using
    either Euca2ools or AWSCLI. You can run either script, but should not run both.

    This script should only be run once for each Demo Account.

    This includes the following tasks:

    - Imports the Demo Keypair into the Demo Account
    - Creates the Demos Role (named "Demos"), and associated Instance Profile (named "Demos")
    - Creates the Demos Role Policy
    - Creates the Demos Group (named "Demos")
    - Creates the Demos Group Policy
    - Creates the Developers Group (named "Developers")
    - Creates the Developers Group Policy
    - Creates the Users Group (named "Users")
    - Creates the Users Group Policy
    - Creates a demo User (named "demo")
    - Adds the demo User to the Demos Group
    - Creates the demo User Login Profile
    - Creates the demo User Access Key
    - Configures Euca2ools for the demo User
    - Configures AWSCLI for the demo User
    - Creates a developer User (named "developer")
    - Adds the developer User to the Developers Group
    - Creates the developer User Login Profile
    - Creates the developer User Access Key
    - Configures Euca2ools for the developer User
    - Configures AWSCLI for the developer User
    - Creates a user User (named "user")
    - Adds the user User to the Users Group
    - Creates the user User Login Profile
    - Creates the user User Access Key
    - Configures Euca2ools for the user User
    - Configures AWSCLI for the user User

    Run the version which uses AWSCLI (preferred):

    ```bash
    ./demo-03-initialize-aws-account-dependencies-awscli.sh -r us-west-2 -a mjchp -p <discover_password> -U mcrawford
    ```

    Or, run the version which uses Euca2ools (creates identical results):

    ```bash
    ./demo-03-initialize-aws-account-dependencies.sh -r us-west-2 -a mjchp -p <discover_password> -U mcrawford
    ```

At this point, you should have an AWS Account configured with all Demo dependencies, and a
Eucalyptus Management workstation with Euca2ools and AWSCLI both configured to access the 
Account.

See the Eucalyptus setup instructions for steps which show how to add the equivalent Eucalyptus
Demo Account Credentials to both Euca2ools and AWSCLI Configuration.

### Initialize CloudFormation Wordpress Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation Wordpress Demo

    This includes the following tasks:

    - Confirm existance of Demo dependencies
    - List initial Resources
    - List initial CloudFormation Stacks
    - Download Wordpress CloudFormation Template from AWS S3 Bucket
    - Display Wordpress CloudFormation Template

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-30-cfn-wordpress/bin
    ./demo-30-initialize-aws-cfn-wordpress.sh -r us-west-2 -a mjchp -t mjchp-templates
    ```

### Run CloudFormation Wordpress Demo in "source" model

1. Run the CloudFormation Wordpress Demo, as source of Migration

    This includes the following tasks:

    - List initial Resources
    - List initial CloudFormation Stacks
    - Download Wordpress CloudFormation Template from AWS S3 Bucket
    - Display Wordpress CloudFormation Template
    - Create the Stack
    - Monitor Stack Creation
    - List updated Resources
    - Confirm ability to login to Instance
    - Configure Wordpress
    - Create a Blog Post
    - Display Wordpress with new Blog Post
    - Backup Wordpress Database
    - Upload Wordpress Database Backup to AWS S3 Bucket

    ```bash
    ./demo-30-run-aws-cfn-wordpress.sh -r us-west-2 -a mjchp -B -t mjchp-templates -b mjchp-backups
    ```

### Reset CloudFormation Wordpress Demo

1. Reset the CloudFormation Wordpress Demo

    This includes the following tasks:

    - Delete the Stack
    - Monitor Stack deletion
    - Clear terminated Instances
    - List remaining Resources
    - List remaining CloudFormation Stacks
    - Delete Wordpress Database Backup from AWS S3 Bucket

    ```bash
    ./demo-30-reset-aws-cfn-wordpress.sh -r us-west-2 -a mjchp
    ```

