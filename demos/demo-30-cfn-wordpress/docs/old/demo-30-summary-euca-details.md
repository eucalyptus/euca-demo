# Demo 30 CloudFormation Wordpress Eucalyptus Summary

This is an outline of the steps required to run the wordpress repatriation demo,
on the Eucalyptus side, with coordination points to the AWS side.

We will use the Eucalyptus hp-aw2-2 region demo account demo user and the AWS mjchp account demo
user in code examples. Adjust these to your own situation.

### Eucalyptus Region Pre-Installation Steps

These are steps which must be run before you install Eucalyptus. In some cases, once a step has
been performed once, you can re-install without having to do it again. In other cases, a step
must be done between each re-kickstart of a host and a new install.

1. Create a Configuration File for each new Region

    Many of the scripts require additional input parameters which are not suitable for
    specification via parameters on the command line. These values are stored in per-region
    configuration files, named after the short name of the host which runs the CLC role.

    Look in the euca-demo projects installs sub-directory for sub-directories named conf
    for examples of existing configuration files, and model any new files after what already
    exists.

    If a region consists of multiple hosts, you should create a symlink with the name of
    each additional host that points to the CLC host configuration file.

2. Configure a new host with the appropriate environmental pre-requisites

    While the rest of this document will refer to scripts contained with the GitHub euca-demo
    project, we have a bootstrap problem to first get that project installed on a new host.

    While logged in as root, follow these instructions:
    https://github.com/eucalyptus/euca-demo/blob/master/installs/install-00-initialize/docs/install-01-initialize-host-user.md

    Once those instructions are followed, the euca-demo project will be located here:
    ~/src/eucalyptus/euca-demo, and all future instructions will assume this exists.

### Eucalyptus Region Installation Steps

These are steps to install Eucalyptus, and perform certain post-intallation tweaks which are useful in
any situation, but which the demos assume will be in place.

All steps to be run on the Eucalyptus CLC as root, unless otherwise specified

1. Install Eucalyptus via FastStart

    ```bash
    cd ~/src/eucalyptus/euca-demo/installs/install-10-faststart/bin
    ./install-10-faststart-install.sh
    ```

2. Configure DNS

    ```bash
    ./install-11-faststart-configure-dns.sh
    ```

3. Configure PKI

    ```bash
    ./install-12-faststart-configure-pki.sh
    ```

4. Configure Reverse-Proxy

    ```bash
    ./install-13-faststart-configure-proxy.sh
    ```

5. Configure Support

    ```bash
    ./install-15-faststart-configure-support.sh
    ```

6. Configure AWSCLI

    ```bash
    ./install-16-faststart-configure-awscli.sh
    ```

7. Update Console to later pre-4.2 version

    ```bash
    ./install-19-faststart-update-console.sh	
    ```

### Eucalyptus Global Demo Pre-Initialization Steps

These are steps which are independent of any single Eucalyptus Region, but which create artifacts
required for the Demos to work, which are installed by the Demo initialization scripts.

1. Create modified CentOS 6.6 minimum image with cfn-init and awscli

    - This was done independently by Lester
    - This needs to be uploaded into the Euca cloud, which is done by the demo prep scripts
    - I will create a separate demo just for this at some point, but for now the required
      image must be visible here, where the demo init scripts expect it:
      https://s3.amazonaws.com/demo-eucalyptus/demo-30-cfn-wordpress/Centos-6-x86_64-CFN-AWSCLI.raw.xz

### Eucalyptus Demo Baseline Initialization Steps

These are steps to initialize a new Eucalyptus Region to run the Demos contained in the euca-demo
project. All demos in the euca-demo project assume the baseline of Resources created in these
scripts exist.

1. Initialize Eucalyptus for Demos

    This includes the following tasks:

    - Initializes Euca2ools with the Region Endpoints
    - Initializes Euca2ools for the Eucalyptus Account Administrator
    - Initialize AWSCLI for the Eucalyptus Account Administrator
    - Imports the Demo Keypair into the Eucalyptus Account
    - Downloads a CentOS 6.6 Generic image
    - Installs the CentOS 6.6 Generic image
    - Downloads a CentOS 6.6 with cfn-init and awscli image
    - Installs the CentOS 6.6 with cfn-init and awscli image

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-00-initialize/bin
    ./demo-00-initialize.sh -r hp-aw2-2
    ```

2. Initialize Eucalyptus Demo Account

    This includes the following tasks:

    - Creates a Demo Account (named "demo", but this can be overridden)
    - Creates the Demo Account Administrator Login Profile
    - Downloads the Demo Account Administrator Credentials
    - Configures Euca2ools for the Demo Account Administrator
    - Configures AWSCLI for the Demo Account Administrator
    - Authorizes use of the CentOS 6.6 Generic image by the Demo Account
    - Authorizes use of the CentOS 6.6 CFN + AWSCLI image by the Demo Account

    ```bash
    ./demo-01-initialize-account.sh -r hp-aw2-2 -a demo -p <discover_password>
    ```

3. Initialize Eucalyptus Demo Account Administrator

    This is not strictly required for Eucalyptus, but recommended for compatibility reasons.
    AWS recommends against direct use of the Account credentials, and instead recommends 
    the creation of an Administrators group with an IAM policy which allows complete control,
    and separate user accounts for all administrators, who are members of this group. This
    script creates such a group and a user within it.

    This script should be run for each separate administrator of the Account.

    This includes the following tasks:

    - Creates the Administrators Group (named "Administrators")
    - Creates the Administrators Group Policy
    - Creates an administrator User (varies - specified as a required parameter)
    - Adds the administrator User to the Administrators Group
    - Creates the administrator User Login Profile
    - Creates the administrator User Access Key
    - Configures Euca2ools for the administrator User
    - Configures AWSCLI for the administrator User

    ```bash
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-2 -a demo -u mcrawford -p <mcrawford_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-2 -a demo -u lwade -p <lwade_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-2 -a demo -u bthomason -p <bthomason_password>
    ```

4. Initialize Eucalyptus Demo Account Dependencies

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

    Run the version which uses euca2ools:

    ```bash
    ./demo-03-initialize-account-dependencies.sh -r hp-aw2-2 -a demo -p <discover_password>
    ```

    Or, run the version which uses AWSCLI: 

    ```bash
    ./demo-03-initialize-account-dependencies-awscli.sh -r hp-aw2-2 -a demo -p <discover_password>
    ```

At this point, you should have a Eucalyptus Demo Account configured with all Demo dependencies,
and with Euca2ools and AWSCLI both configured to access the Demo Account.

See the AWS setup instructions for steps which show how to add the equivalent AWS Account Credentials
to both Euca2ools and AWSCLI Configuration.

### Initialize CloudFormation Wordpress Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation Wordpress Demo

    This includes the following tasks:

    - Confirm existance of Demo dependencies
    - List initial Resources
    - List initial CloudFormation Stacks
    - Download CloudFormation Template from S3 URL
    - Modify CloudFormation Template to reference local Image
    - Display modified CloudFormation Template
    - Upload modified CloudFormation Template to AWS S3 URL
    - Upload modified CloudFormation Template to Eucalyptus S3 sample-templates bucket

    ```bash
    ./demo-30-initialize-cfn-wordpress.sh -r hp-aw2-2 -a demo
    ```

### Run CloudFormation Wordpress Demo

1. Run the CloudFormation Wordpress Demo, as destination of Migration

    This includes the following tasks:

    - List initial Resources
    - List initial CloudFormation Stacks
    - Display Wordpress CloudFormation Template
    - Create the Stack
    - Monitor Stack Creation
    - List updated Resources
    - Confirm ability to login to Instance
    - Download Wordpress Database Backup from AWS S3 Bucket
    - Restore Wordpress Database from Backup
    - Display Wordpress running the migrated data

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-30-cfn-wordpress/bin
    ./demo-30-run-cfn-wordpress.sh -r hp-aw2-2 -a demo -R
    ```

>>>>>>>>>>>>>> Some key steps as needed in the above script copied here to save

5. Display Wordpress CloudFormation template

    The Wordpress_Single_Instance_Eucalyptus.template creates a security group and an instance, then installs and
    configures Wordpress.

    ```bash
    more ~/src/eucalyptus/euca-demo/demos/demo-30-cfn-wordpress/templates/Wordpress_Single_Instance_Eucalyptus.template
    ```

6. Create the Stack

    ```bash
    euform-create-stack --template-file /var/tmp/Wordpress_Single_Instance_Eucalyptus.template \
                        --parameter "KeyName=demo" \
                        --parameter "DBUser=demo" \
                        --parameter "DBPassword=password" \
                        --parameter "DBRootPassword=password" \
                        --parameter "EndPoint=http://cloudformation.hp-aw2-2.hpcloudsvc.com" \
                        --capabilities CAPABILITY_IAM \
                        WordpressDemoStack

IF TRANSFER SOURCE, THEN

9. View Wordpress Blog

    We first obtain the WebsiteURL as an Output parameter of the Stack, then view this in a browser.

    ```bash
    aws cloudformation describe-stacks --stack-name WordpressDemoStack \
                                       --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}'
    ```

    ```bash
    euform-describe-stacks WordpressDemoStack | sed -n -e "s/^OUTPUT\tWebsiteURL\t//p"
    ```

10. Create a Blog Post

    If this system is to be the source of a copy, create a new blog post to prove we are transferring live data.

    There may be a way to do this programatically, see this URL for details: 
    http://www.codediesel.com/wordpress/accessing-wordpress-data-using-the-new-rest-api/

    This might require the addition of a new plugin, which might be possible with changes to the template,
    or it might require a new step. Otherwise, you can create the new post via the GUI.

    Here is an example of the REST method:
    curl --user demo:password --data "title=Post at $(date)&content_raw=Content to show live changes are transferred" http://www.codediesel.com/wp-json/posts

11. Backup Wordpress Database

    ```bash
    instance_id=$(euform-describe-stack-resources -n WordpressDemoStack -l WebServer | cut -f3)
    public_name=$(euca-describe-instances $instance_id | grep "^INSTANCE" | cut -f 4)
    user=ec2-user

    bucket=workload-repatriation

    db_backup_file=db.bak

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "mysqldump -uroot -ppassword wordpressdb > /tmp/$db_backup_file"

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "aws s3 cp /tmp/$db_backup_file s3://$bucket/$db_backup_file --acl public-read"

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "rm -f /tmp/$db_backup_file"
    ```

ELSE # TRANSFER DESTINATION

9. Restore Saved Wordpress Database

    ```bash
    instance_id=$(euform-describe-stack-resources -n WordpressDemoStack -l WebServer | cut -f3)
    public_name=$(euca-describe-instances $instance_id | grep "^INSTANCE" | cut -f 4)
    user=centos

    bucket=workload-repatriation

    db_backup_file=db.bak

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "wget http://s3.amazonaws.com/$bucket/$db_backup_file -O /tmp/$db_backup_file"

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "mysql -uroot -ppassword -Dwordpressdb < /tmp/$db_backup_file"

    ssh -i ~/.ssh/demo_id_rsa $user@$public_name "rm -f /tmp/$db_backup_file"
    ```

12. View Wordpress Blog

    We first obtain the WebsiteURL as an Output parameter of the Stack, then view this in a browser.

    ```bash
    aws cloudformation describe-stacks --stack-name WordpressDemoStack \
                                       --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}'
    ```

    ```bash
    euform-describe-stacks WordpressDemoStack | sed -n -e "s/^OUTPUT\tWebsiteURL\t//p"
    ```

### Reset CloudFormation Wordpress Demo

1. Reset the CloudFormation Wordpress Demo

    This includes the following tasks:

    - Delete the Stack
    - Monitor Stack deletion
    - Clear terminated instances
    - List remaining Resources
    - List remaining CloudFormation Stacks
    - Delete Wordpress Database Backup from AWS S3 Bucket
    - Delete Modified Wordpress CloudFormation Template from AWS S3 Bucket

    ```bash
    ./demo-30-reset-cfn-wordpress.sh -r hp-aw2-2 -a demo
    ```

