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
    export EUCA_DOMAIN=hpcloudsvc.com
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

6. List existing AWS CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks --profile $AWS_PROFILE --region $AWS_REGION
    ```

7. Create the AWS Stack

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

8. Monitor AWS Stack creation

    This stack can take 360 to 600 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    aws cloudformation describe-stacks --profile $AWS_PROFILE --region $AWS_REGION

    aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \
                                             --profile $AWS_PROFILE --region $AWS_REGION
    ```

9. List updated AWS Resources (Optional)

    Note addition of new group and instance

    ```bash
    aws ec2 describe-security-groups --profile $AWS_PROFILE --region $AWS_REGION

    aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION
    ```

10. Obtain AWS Instance and Blog Details

    Note these values for future use.

    ```bash
    aws_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack \
                                                                  --logical-resource-id WebServer \
                                                                  --profile=$AWS_PROFILE --region=$AWS_REGION | cut -f4)
    $aws_instance_id

    aws_public_name=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                                 --profile=$AWS_PROFILE --region=$AWS_REGION | grep "^INSTANCES" | cut -f11)
    $aws_public_name

    aws_public_ip=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                               --profile=$AWS_PROFILE --region=$AWS_REGION | grep "^INSTANCES" | cut -f12)
    $aws_public_ip

    aws_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                           --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                           --profile=$AWS_PROFILE --region=$AWS_REGION 2> /dev/null)
    $aws_wordpress_url
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
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION

    aws ec2 describe-instances --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

15. List existing Eucalyptus CloudFormation Stacks (Optional)

    So we can compare with what this demo creates

    ```bash
    aws cloudformation describe-stacks --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

16. Create the Eucalyptus Stack

    ```bash
    aws cloudformation create-stack --stack-name WordPressDemoStack \
                                    --template-body file:///var/tmp/WordPress_Single_Instance_Eucalyptus.template \
                                    --parameters ParameterKey=KeyName,ParameterValue=demo \
                                                 ParameterKey=InstanceType,ParameterValue=m1.medium \
                                                 ParameterKey=DBUser,ParameterValue=demo \
                                                 ParameterKey=DBPassword,ParameterValue=password \
                                                 ParameterKey=DBRootPassword,ParameterValue=password \
                                                 ParameterKey=EndPoint,ParameterValue=https://cloudformation.$EUCA_REGION.$EUCA_DOMAIN \
                                    --capabilities CAPABILITY_IAM \
                                    --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

17. Monitor Eucalyptus Stack creation

    This stack can take 360 to 600 seconds to complete.

    Run either of these commands as desired to monitor Stack progress.

    ```bash
    aws cloudformation describe-stacks --profile $EUCA_PROFILE --region $EUCA_REGION

    aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \
                                             --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

18. List updated Eucalyptus Resources (Optional)

    Note addition of new group and instance

    ```bash
    aws ec2 describe-security-groups --profile $EUCA_PROFILE --region $EUCA_REGION

    aws ec2 describe-instances --profile $EUCA_PROFILE --region $EUCA_REGION
    ```

19. Obtain Eucalyptus Instance and Blog Details

    Note these values for future use.

    ```bash
    euca_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack \
                                                                   --logical-resource-id WebServer \
                                                                   --profile=$EUCA_PROFILE --region=$EUCA_REGION | cut -f4)
    $euca_instance_id

    euca_public_name=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                  --profile=$EUCA_PROFILE --region=$EUCA_REGION | grep "^INSTANCES" | cut -f11)
    $euca_public_name

    euca_public_ip=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                --profile=$EUCA_PROFILE --region=$EUCA_REGION | grep "^INSTANCES" | cut -f12)
    $euca_public_ip

    euca_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                            --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                            --profile=$EUCA_PROFILE --region=$EUCA_REGION 2> /dev/null)
    $euca_wordpress_url
    ```

20. View WordPress on AWS Instance (Optional)

    We can do this via the WordPress website, or via a text-mode browser using the command below.

    If you prefer to use the website, use your Browser to visit $aws_wordpress_url, and note
    current content.

    ```bash
    w3m -dump $aws_wordpress_url
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
    w3m -dump $euca_wordpress_url
    ```

