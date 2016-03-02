# Demo 30: CloudFormation: WordPress

This document describes the manual procedure to run the CloudFormation WordPress demo primarily 
via Euca2ools. However, because Euca2ools does not currently support S3 operations, all tasks
related to S3 must use another tool, such as AWS CLI, which is used here.

### Prerequisites

This variant can be run by any User with the appropriate permissions, as long as both Euca2ools
and AWS CLI have been configured with the appropriate credentials, and the Account was initialized
with demo baseline dependencies. See [this section](../../demo-00-initialize/docs) for details.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus 
Console, so that you can run scripts or upload Templates or other files which may be needed. 
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

In examples below, credentials are specified via the --region USER@REGION option with Euca2ools, 
or the --profile PROFILE and --region REGION options with AWS CLI. Normally you could shorten the
command lines by use of the AWS_DEFAULT_REGION and AWS_DEFAULT_PROFILE environment variables set
to appropriate values, but there are two conflicts which prevent that alternative for this demo.
We must switch back and forth between AWS and Eucalyptus, and explicit options make clear which
system is the target of each command. Also, there is a conflict between Euca2ools use of
USER@REGION and AWS CLI, which breaks when this variable has the USER@ prefix.

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

### Run CloudFormation WordPress Demo

1. Confirm existence of AWS Demo depencencies (Optional)

    The "demo" Key Pair should exist.

    ```bash
    euca-describe-keypairs --filter "key-name=demo" \
                           --region $AWS_USER_REGION
    ```

2. Confirm existence of Eucalyptus Demo depencencies (Optional)

    The "CentOS-6-x86_64-CFN-AWSCLI" Image should exist.

    The "demo" Key Pair should exist.

    ```bash
    euca-describe-images --filter "manifest-location=images/CentOS-6-x86_64-CFN-AWSCLI.raw.manifest.xml" \
                         --region $EUCA_USER_REGION | cut -f1,2,3

    euca-describe-keypairs --filter "key-name=demo" \
                           --region $EUCA_USER_REGION
    ```

3. Download WordPress CloudFormation Template from AWS S3 Bucket

    ```bash
    aws s3 cp s3://demo-$AWS_ACCOUNT/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
           /var/tmp/WordPress_Single_Instance_Eucalyptus.template \
           --profile $AWS_PROFILE --region $AWS_REGION --output text
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
    euca-describe-groups --region $AWS_USER_REGION

    euca-describe-instances --region $AWS_USER_REGION
    ```

6. List existing AWS CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    euform-describe-stacks --region $AWS_USER_REGION
    ```

7. Create the AWS Stack

    ```bash
    euform-create-stack --template-file /var/tmp/WordPress_Single_Instance_Eucalyptus.template \
                        --parameter "KeyName=demo" \
                        --parameter "InstanceType=m1.medium" \
                        --parameter "DBUser=demo" \
                        --parameter "DBPassword=password" \
                        --parameter "DBRootPassword=password" \
                        --parameter "EndPoint=https://cloudformation.$AWS_REGION.amazonaws.com" \
                        --capabilities CAPABILITY_IAM \
                        --region $AWS_USER_REGION \
                        WordPressDemoStack
    ```

8. Monitor AWS Stack creation

    This stack can take 360 to 600 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    euform-describe-stacks --region $AWS_USER_REGION

    euform-describe-stack-events --region $AWS_USER_REGION WordPressDemoStack | head -10
    ```

9. List updated AWS Resources (Optional)

    Note addition of new group and instance

    ```bash
    euca-describe-groups --region $AWS_USER_REGION

    euca-describe-instances --region $AWS_USER_REGION
    ```

10. Obtain AWS Instance and Blog Details

    Note these values for future use.

    ```bash
    aws_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region $AWS_USER_REGION | cut -f3)
    echo $aws_instance_id

    aws_public_name=$(euca-describe-instances --region $AWS_USER_REGION $aws_instance_id | grep "^INSTANCE" | cut -f4)
    echo $aws_public_name

    aws_public_ip=$(euca-describe-instances --region $AWS_USER_REGION $aws_instance_id | grep "^INSTANCE" | cut -f17)
    echo $aws_public_ip

    aws_wordpress_url=$(euform-describe-stacks --region $AWS_USER_REGION WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
    echo $aws_wordpress_url
    ```

11. Install WordPress Command-Line Tools on AWS Instance (Optional)

    These can be used to automate WordPress Initialization and Management, but are optional if 
    you will instead perform these actions via the WordPress website.

    ssh -t -i ~/.ssh/demo_id_rsa ec2-user@$aws_public_name \
        "sudo curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp; \
         sudo chmod +x /usr/local/bin/wp"

12. Initialize WordPress on AWS Instance

    We can do this via the WordPress website, or via the WordPress CLI using the command below.

    If you prefer to use the website, use your Browser to visit $aws_wordpress_url, and
    specify these values:
    - Site Title: Demo ($AWS_ACCOUNT)
    - Username: demo
    - Password: <your password>
    - Your E-mail: <your email>

    Note this site is publically accessible, so choose a password which is non-trivial.

    ```bash
    ssh -t -i ~/.ssh/demo_id_rsa ec2-user@$aws_public_name \
        "sudo /usr/local/bin/wp core install --path=/var/www/html/wordpress \
                                             --url=\"$aws_wordpress_url\" \
                                             --title=\"Demo ($AWS_ACCOUNT)\" \
                                             --admin_user=\"demo\" \
                                             --admin_password=\"<your password>\" \
                                             --admin_email=\"<your email>\""
    ```

13. Create WordPress Blog Post on AWS Instance

    This should be done each time the demo is run, even if we do not re-create the Stack on AWS,
    to show migration of current content.

    We can do this via the WordPress website, or via the WordPress CLI using the command below.

    If you prefer to use the website, use your Browser to visit $aws_wordpress_url, login using
    the username and password provided in the prior step, and create a new blog post.

    ```bash
    ssh -t -i ~/.ssh/demo_id_rsa ec2-user@$aws_public_name \
        "sudo /usr/local/bin/wp post create --path=/var/www/html/wordpress \
                                            --post_type=\"post\" \
                                            --post_status=\"publish\" \
                                            --post_title=\"Post on $(date '+%Y-%m-%d %H:%M')\" \
                                            --post_content=\"Post created with wp on $(hostname)\""
    ```

14. List existing Eucalyptus Resources (Optional)

    So we can compare with what this demo creates

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION
    ```

15. List existing Eucalyptus CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    euform-describe-stacks --region $EUCA_USER_REGION
    ```

16. Create the Eucalyptus Stack

    ```bash
    euform-create-stack --template-file /var/tmp/WordPress_Single_Instance_Eucalyptus.template \
                        --parameter "KeyName=demo" \
                        --parameter "InstanceType=m1.medium" \
                        --parameter "DBUser=demo" \
                        --parameter "DBPassword=password" \
                        --parameter "DBRootPassword=password" \
                        --parameter "EndPoint=https://cloudformation.$EUCA_REGION.$EUCA_DOMAIN" \
                        --capabilities CAPABILITY_IAM \
                        --region $EUCA_USER_REGION \
                        WordPressDemoStack
    ```

17. Monitor Eucalyptus Stack creation

    This stack can take 360 to 600 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    euform-describe-stacks --region $EUCA_USER_REGION

    euform-describe-stack-events --region $EUCA_USER_REGION WordPressDemoStack | head -10
    ```

18. List updated Eucalyptus Resources (Optional)

    Note addition of new group and instance

    ```bash
    euca-describe-groups --region $EUCA_USER_REGION

    euca-describe-instances --region $EUCA_USER_REGION
    ```

19. Obtain Eucalyptus Instance and Blog Details

    Note these values for future use.

    ```bash
    euca_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region $EUCA_USER_REGION | cut -f3)
    echo $euca_instance_id

    euca_public_name=$(euca-describe-instances --region $EUCA_USER_REGION $euca_instance_id | grep "^INSTANCE" | cut -f4)
    echo $euca_public_name

    euca_public_ip=$(euca-describe-instances --region $EUCA_USER_REGION $euca_instance_id | grep "^INSTANCE" | cut -f17)
    echo $euca_public_ip

    euca_wordpress_url=$(euform-describe-stacks --region $EUCA_USER_REGION WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
    echo $euca_wordpress_url
    ```

20. View WordPress on AWS Instance (Optional)

    We can do this via the WordPress website, or via a text-mode browser using the command below.

    If you prefer to use the website, use your Browser to visit $aws_wordpress_url, and note
    current content.

    ```bash
    lynx -dump $aws_wordpress_url
    ```

21. Backup WordPress on AWS Instance

    Backup the WordPress database, then copy the database backup from the Instance to an AWS S3 
    Bucket (demo-$AWS_ACCOUNT).

    ```bash
    ssh -T -i ~/.ssh/demo_id_rsa ec2-user@$aws_public_name << EOF
    mysqldump -uroot -ppassword wordpressdb > /var/tmp/db.bak
    aws s3 cp /var/tmp/db.bak s3://demo-$AWS_ACCOUNT/demo-30-cfn-wordpress/db.bak --acl public-read
    EOF
    ```

22. Restore WordPress on Eucalyptus Instance

    Copy the database backup from the AWS S3 Bucket (demo-$AWS_ACCOUNT) to the Instance, then
    restore the WordPress database.

    ```bash
    ssh -T -i ~/.ssh/demo_id_rsa root@$euca_public_name << EOF
    wget http://s3.amazonaws.com/demo-$AWS_ACCOUNT/demo-30-cfn-wordpress/db.bak -O /var/tmp/db.bak
    mysql -uroot -ppassword -Dwordpressdb < /var/tmp/db.bak
    rm -f /var/tmp/db.bak
    EOF
    ```

23. Confirm WordPress Migration on Eucalyptus Instance

    We can do this via the WordPress website, or via a text-mode browser using the command below.

    If you prefer to use the website, use your Browser to visit $euca_wordpress_url in a separate
    tab, and confirm content is identical to the AWS WordPress website.

    ```bash
    lynx -dump $euca_wordpress_url
    ```

