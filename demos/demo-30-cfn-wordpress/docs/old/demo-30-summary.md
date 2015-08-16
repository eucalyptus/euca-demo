This is an outline of the steps required to run the workload repatriation demo,
modified to insure all steps are clearly listed in logical phases, and in
logical steps within each phase.

AWS Steps

 1. Create Role Specific to this Demo with associated EC2 Trust Policy

    cat << EOF > /var/tmp/EC2RoleTrustPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": { "Service": "ec2.amazonaws.com"},
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF

    aws iam create-role --role-name EucaDemo30CloudFormationWordpress \
                        --assume-role-policy-document file://var/tmp/EC2RoleTrustPolicy.json


 2. Create S3 Bucket Access Policy and attach to the Role

    cat << EOF > /var/tmp/S3FullAccessPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": ["s3:*"],
          "Resource": ["*"]
        }
      ]
    }
    EOF

    aws iam put-role-policy --role-name EucaDemo30CloudFormationWordpress \
                            --policy-name S3FullAccessPolicy \
                            --policy-document file:///var/tmp/S3FullAccessPolicy.json

-OR-

 2. Create this policy and attach to the Role

    cat << EOF /var/tmp/EucaDemo30CloudFormationWordpressPolicy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "cloudformation:DescribeStacks",
                    "cloudformation:DescribeStackEvents",
                    "cloudformation:DescribeStackResource",
                    "cloudformation:DescribeStackResources",
                    "cloudformation:GetTemplate",
                    "cloudformation:List*",
                    "ec2:Describe*",
                    "s3:Get*",
                    "s3:List*"
                ],
                "Effect": "Allow",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "s3:ListAllMyBuckets",
                "Resource": "arn:aws:s3:::*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketLocation"
                ],
                "Resource": "arn:aws:s3:::workload-repatriation"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObjectAcl",
                    "s3:PutObjectVersionAcl"
                ],
                "Resource": "arn:aws:s3:::workload-repatriation/*"
            }
        ]
    }
    EOF

    aws iam put-role-policy --role-name EucaDemo30CloudFormationWordpress \
                            --policy-name EucaDemo30CloudFormationWordpressPolicy \
                            --policy-document file:///var/tmp/EucaDemo30CloudFormationWordpressPolicy.json


 3. Create Instance Profile

    aws iam create-instance-profile --instance-profile-name EucaDemo30CloudFormationWordpress


 4. Attach the Role to the Instance Profile

    aws iam add-role-to-instance-profile --instance-profile-name EucaDemo30CloudFormationWordpress \
                                         --role-name EucaDemo30CloudFormationWordpress



 5. Deploy the Wordpress Single Instance CloudFormation Stack
    - Modify the templates use of "admin-role" to instead be "EucaDemo30CloudFormationWordpress"
    - Obtain the template from S3, named Wordpress_Single_Instance.template
    - Lesters variant is https://s3.amazonaws.com/workload-repatriation/wordpress-demo-discover
    - He modifies the Map to add in the euca regions including the EMIs of the new image which includes
      the aws cli and cfn-init packages

    aws cloudformation create-stack --stack-name=wordpress-demo-discover \
                                    --template-body file:///cygdrive/c/Users/lwade/Downloads/wordpress-demo-discover-2015 \
                                    --parameters ParameterKey=KeyName,ParameterValue=mykeypair-east1 \
                                                 ParameterKey=DBUser,ParameterValue=demo \
                                                 ParameterKey=DBPassword,ParameterValue=password \
                                                 ParameterKey=DBRootPassword,ParameterValue=password \
                                                 ParameterKey=EndPoint,ParameterValue=https://cloudformation.us-east-1.amazonaws.com \
                                    --capabilities CAPABILITY_IAM --region us-east-1

 6. Configure Wordpress on the AWS Stack
    - TBD, get Wordpress up to the point where an initial "Hello World!" Blog post is visible.
    - Display the output URL by which the Wordpress blog can be reached.

Eucalyptus Environment Setup Steps
- These are steps to setup the environment independent of this demo

 0. We need to create an image based on CentOS-6.6 with cfn-init and awscli added to it
    - This was done independently by Lester
    - This needs to be uploaded into the Euca cloud
    - This is done via the demo prep scripts

 1. Intall Eucalyptus via Faststart
 2. Configure DNS via install-11-faststart-configure-dns.sh
 3. Configure PKI via install-12-faststart-configure-pki.sh
 4. Configure Reverse-Proxy via install-13-faststart-configure-proxy.sh
 5. Configure Support via install-15-faststart-configure-support.sh
 6. Configure AWSCLI via install-16-faststart-configure-awscli.sh
 7. Update Console via install-19-faststart-update-console.sh	
 8. Initialize Eucalyptus for Demos via demo-00-initialize.sh
 9. Initialize Eucalyptus Demo Account via demo-01-initialize-account.sh
10. Initialize Eucalyptus Demo Account Dependencies via demo-02-initialize-account-dependencies.sh (euca2ools)
    or demo-02-initialize-account-dependencies-awscli.sh

- At this point, you should have a Euca region with all demo dependencies loaded, and with Euca2ools and AWSCLI
  configured for this region.

11. We next need to add credentials for the AWS user used above to both AWS CLI and Euca2ools.


Eucalyptus Demo Initialization Steps

 1. Download and modify the CloudFormation Template used for this Demo
    - We ned to download the Wordpress_Single_Instance.template cloudformation template from S3
      https://s3.amazonaws.com/cloudformation-templates-us-east-1/WordPress_Single_Instance.template
      https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/WordPress_Single_Instance.template
      https://s3-eu-west-1.amazonaws.com/cloudformation-templates-eu-west-1/WordPress_Single_Instance.template
    - Search the Eucalyptus region to obtain the EMI ID for the CentOS-6.6 image with awscli and cfn-init
    - Modify the AWSRegionArch2AMI Map within the Wordpress_Single_Instance.templte to add a row for the
      Eucalyptus region containing the EMI just found.
    - Search and replace references to the "adminrole" Role to instead use the "Demos" role.
    - Upload the modified CloudFormation Template to the sample_templates bucket on the Euca region.


 2. Create the migration script

    cat << EOF > /var/tmp/migration.sh
    awskey=~/mykeypair-east1.pem
    eucasshuser=root
    awssshuser=ec2-user
    stackname=wordpress-demo-discover
    stackresource=WebServer
    awsregion=us-east-1
    awsapiuser=aws
    eucaregion=eucalyptus
    eucaapiuser=euca
    mysqldb=wordpressdb
    mysqlpwd=password
    mysqluser=root
    dbbackupfilename=db.bak
    s3bucketname=workload-repatriation
    mycmd="mysql -u$mysqluser -p$mysqlpwd -D$mysqldb \< /tmp/$dbbackupfilename"

    # Get the instanceID and public IP address of that instance in AWS EC2
    awsid=`euform-describe-stack-resources -n $stackname -l $stackresource --region $awsapiuser@$awsregion | awk '{print $3}'`
    awsipaddr=`euca-describe-instances $awsid --region $awsapiuser@$awsregion  | grep ^INSTANCE | awk '{print $4}'`

    # Create a DB Dump of the EC2 wordpress instance and copy it on AWS S3, delete the local copy made
    ssh -i $awskey $awssshuser@$awsipaddr "mysqldump -u$mysqluser -p$mysqlpwd $mysqldb > /tmp/$dbbackupfilename"
    ssh -i $awskey $awssshuser@$awsipaddr aws s3 cp /tmp/$dbbackupfilename s3://$s3bucketname/$dbbackupfilename --acl public-read
    ssh -i $awskey $awssshuser@$awsipaddr "rm -f /tmp/$dbbackupfilename"

    # Get the instanceID and public IP address of that instance in Eucalyptus
    eucaid=`euform-describe-stack-resources -n $stackname --region $eucaapiuser@$eucaregion | grep $stackresource | grep Instance |awk '{print $3}'`
    eucaipaddr=`euca-describe-instances verbose $eucaid --region $eucaapiuser@$eucaregion | grep ^INSTANCE | awk '{print $13'}`

    # Copy the DB dump locally (from S3) on the wordpress instance on Eucalyptus and restore it
    ssh -i $awskey $eucasshuser@$eucaipaddr "wget http://s3.amazonaws.com/$s3bucketname/$dbbackupfilename -O /tmp/$dbbackupfilename"
    ssh -i $awskey $eucasshuser@$eucaipaddr "echo $mycmd > /tmp/mycmd"
    ssh -i $awskey $eucasshuser@$eucaipaddr "chmod 777 /tmp/mycmd"
    ssh -i $awskey $eucasshuser@$eucaipaddr "/tmp/mycmd"
    # ssh -i $eucakey $eucasshuser@$eucaipaddr rm -f /tmp/$dbbackupfilename
    # ssh -i $eucakey $eucasshuser@$eucaipaddr rm -f /tmp/mycmd

    # Delete the DB dump stored on S3
    ssh -i $awskey $awssshuser@$awsipaddr aws s3 rm s3://$s3bucketname/$dbbackupfilename
    EOF


 3. Create the CloudFormation Stack in Eucalyptus
    - Run only one of the following statements

    aws cloudformation create-stack --stack-name=wordpress-demo-discover \
                                    --template-body file:///cygdrive/c/Users/lwade/Downloads/wordpress-demo-discover-2015 \
                                    --parameters ParameterKey=KeyName,ParameterValue=mykeypair-east1 \
                                                 ParameterKey=DBUser,ParameterValue=demo \
                                                 ParameterKey=DBPassword,ParameterValue=password \
                                                 ParameterKey=DBRootPassword,ParameterValue=password \
                                                 ParameterKey=EndPoint,ParameterValue=https://cloudformation.us-east-1.amazonaws.com \
                                    --capabilities CAPABILITY_IAM
                                    --region us-east-1

    euform-create-stack wordpress-demo-discover --template-file wordpress-demo-deployment \
                                                -p "KeyName=mykeypair-east1" \
                                                -p "DBUser=demo" \
                                                -p "DBPassword=password" \
                                                -p "DBRootPassword=password" \
                                                -p "EndPoint=http://cloudformation.emea.eucalyptus.com:8773/"
                                                --capabilities CAPABILITY_IAM

 4. Login to the AWS Management Console
    - Use the Eucalyptus Demo account 140601064733
    - Browse: https://140601064733.signin.aws.amazon.com/console
    - User: discover
    - Password: o7[dO#so&A2T

 5. Display the modified Wordpress_Single_Instance_Eucalyptus template
    - From the Main menu, select CloudFormation
    - From the CloudFormation Service Home Page, Click the "wordpress-demo-discover" Stack in the list, then Click the Template tab
    - Show this template to the audience, explaining key sections based on audience interest and time

 6. Show that our S3 workload-repatriation bucket contains the modified template
    - From the top menu, navitate to S3, then find the workload-repatriation bucket, then show that the template file exists with an URL
    - Copy this URL into the paste buffer

 7. Login to the Eucalyptus Management Console
    - Browse: https://console.hp-aw2-2.hpcloudsvc.com/
    - Account: scalene
    - User: admin
    - Password: MohawkRiver1777

 8. View CloudFormation Stacks
    - From the Eucalyptus Main Menu, Click Stacks

 9. Create the Demo Stack
    - From the CloudFormation Stacks List Page, Click the CreateStack Button to get to the Stack Details Page.
    - Enter "wordpress-demo-discover" for the stack name.
    - Paste the URL from the S3 bucket obtained above into the template URL field.
    - Click next to get to the Stack Parameters Page
    - Enter ... for the Endpoint (list out all values)
    - Press the Create Stack button to create the Stack.

10. Monitor Stack Creation
    - Monitor events on the Stack Details page for a few seconds to show the stack is being created.

11. Switch back to the AWS Console CloudFormation Service Home Page
    - You should see the list of stacks, including the "wordpress-demo-discover" Stack.

12. View the Wordpress Blog
    - From the CloudFormation Service Home Page, select the "wordpress-demo-discover" Stack.
    - From the Stack Details Page, select the Outputs tab.
    - Open the URL for the Blog in a new Browser tab.

13. Create a new Wordpress Blog Post
    - From the Wordpress Blog Home Page, select the Log In link at the bottom left.
    - From the Blog login page, login using username: "demo" and password: "QWEiVye39yZz". 
    - From the Blog admin home page, using the menu, select "New" > "Post"
    - Create a trivail entry to show the data we will migrate is live, then publish it.
    - Return to the blog home page to show the new blog post.

14. Switch back to the Eucalyptus Console CloudFormation Service Home Page
    - You should see the list of stacks, including the "wordpress-demo-discover" Stack.

15. Resume Monitoring of Stack Creation
    - From the Main Menu, select Stacks
    - From the CloudFormation Stacks Service Home Page, select the "wordpress-demo-discover" Stack
    - From the Stack Detail page, determine if the Stack has completed.
    - Switch to the Stack Events page to view Stack events. Explain what is going on until the Stack completes.

16. Migrate the Wordpress Database from AWS to Eucalyptus
    - Run the migrate script above, but here are the explicit steps

    - Define variables
    AWS_SSH_KEY_ID=demo
    AWS_SSH_KEY_FILE=${HOME}/.ssh/${AWS_SSH_KEY_ID}_id_rsa

    EUCA_USER=root
    AWS_USER=ec2-user

    stackname=wordpress-demo-discover
    stackresource=WebServer
    awsregion=us-east-1
    awsapiuser=aws
    eucaregion=eucalyptus
    eucaapiuser=euca
    mysqldb=wordpressdb
    mysqluser=root
    mysqlpwd=password
    dbbackupfilename=db.bak
    s3bucketname=workload-repatriation
    mycmd="mysql -u$mysqluser -p$mysqlpwd -D$mysqldb \< /tmp/$dbbackupfilename"

    # Get the instanceID and public IP address of that instance in AWS EC2
    awsid=$(euform-describe-stack-resources -n $stackname -l $stackresource --region $awsapiuser@$awsregion | awk '{print $3}'`
    awsipaddr=$(euca-describe-instances $awsid --region $awsapiuser@$awsregion  | grep ^INSTANCE | awk '{print $4}'`

    # Create a DB Dump of the EC2 wordpress instance and copy it on AWS S3, delete the local copy made
    ssh -i $AWS_SSH_KEY_FILE $AWS_USER@$awsipaddr "mysqldump -u$mysqluser -p$mysqlpwd $mysqldb > /tmp/$dbbackupfilename"
    ssh -i $AWS_SSH_KEY_FILE $AWS_USER@$awsipaddr aws s3 cp /tmp/$dbbackupfilename s3://$s3bucketname/$dbbackupfilename --acl public-read
    ssh -i $AWS_SSH_KEY_FILE $AWS_USER@$awsipaddr "rm -f /tmp/$dbbackupfilename"

    # Get the instanceID and public IP address of that instance in Eucalyptus
    eucaid=`euform-describe-stack-resources -n $stackname --region $eucaapiuser@$eucaregion | grep $stackresource | grep Instance |awk '{print $3}'`
    eucaipaddr=`euca-describe-instances verbose $eucaid --region $eucaapiuser@$eucaregion | grep ^INSTANCE | awk '{print $13'}`

    # Copy the DB dump locally (from S3) on the wordpress instance on Eucalyptus and restore it
    ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr "wget http://s3.amazonaws.com/$s3bucketname/$dbbackupfilename -O /tmp/$dbbackupfilename"
    ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr "echo $mycmd > /tmp/mycmd"
    ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr "chmod 777 /tmp/mycmd"
    ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr "/tmp/mycmd"
    # ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr rm -f /tmp/$dbbackupfilename
    # ssh -i $AWS_SSH_KEY_FILE $EUCA_USER@$eucaipaddr rm -f /tmp/mycmd

    # Delete the DB dump stored on S3
    ssh -i $AWS_SSH_KEY_FILE $AWS_USER@$awsipaddr aws s3 rm s3://$s3bucketname/$dbbackupfilename

17. View the same Wordpress blog in Eucalyptus
    - Browse: https://console.hp-gol01-f1.mjc.prc
    - From Main Menu, Select Stacks
    - From Stacks Service Home Page, Select wordpress stack
    - From Stack Details Page, select Output tab
    - Click on Output link to view Wordpress
    - Confirm Wordpress looks the same


