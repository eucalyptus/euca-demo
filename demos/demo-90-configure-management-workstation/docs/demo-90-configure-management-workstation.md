# Demo 90: Configure Management Workstation

This document describes the manual procedure to run the Mnagement Workstation Configuration demo
using a combination of Euca2ools and AWSCLI.

### Prerequisites

This procedure should not be run on hosts running Eucalyptus components - the use of Python pip to
install AWSCLI can update python dependencies also used by Eucalyptus which have not been
tested.

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

Before running this demo, please run the demo-90-initialize-configure-management-workstation.sh
script, which will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-90-reset-configure-management-workstation.sh script,
which will reverse all actions performed by this script so that it can be re-run.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export EUCA_REGION=hp-aw2-1
    export EUCA_DOMAIN=hpcloudsvc.com
    export EUCA_ACCOUNT=demo
    export EUCA_USER=admin
    export EUCA_USER_ACCESS_KEY=XXXXXXXXXXXXXXXX
    export EUCA_USER_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER

    export AWS_REGION=us-west-2
    export AWS_ACCOUNT=mjchp
    export AWS_USER=mcrawford
    export AWS_USER_ACCESS_KEY=XXXXXXXXXXXXXXXX
    export AWS_USER_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    export AWS_USER_REGION=aws-$AWS_ACCOUNT-$AWS_USER@$AWS_REGION
    export AWS_PROFILE=$AWS_ACCOUNT-$AWS_USER
    ```

### Run Configure Management Workstation Demo

1. Install Euca2ools

    Via package for CentOS/RHEL 6.

    ```bash
    yum install -y \
        http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.3/centos/6/x86_64/euca2ools-release-3.3-1.el6.noarch.rpm

    yum install -y euca2ools
    ```

    Via package for CentOS/RHEL 7.

    ```bash
    yum install -y \
        http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.3/centos/7/x86_64/euca2ools-release-3.3-1.el7.noarch.rpm

    yum install -y euca2ools
    ```

    From source tarball for Mac OS X. Additional configuration is required.

    ```bash
    curl ...
    ```

2. Display Euca2ools Initial Configuration

    ```bash
    less /etc/euca2ools/euca2ools.ini
    less /etc/euca2ools/conf.d/aws.ini
    ```

3. Configure Euca2ools Eucalyptus Region (via direct HTTP endpoints)

    By default, Eucalyptus is accessible via direct HTTP endpoints. This is the simplest method.

    ```bash
    cat << EOF > /etc/euca2ools/conf.d/$EUCA_REGION.ini
    ; Eucalyptus Region $EUCA_REGION

    [region $EUCA_REGION]
    autoscaling-url = http://autoscaling.$EUCA_REGION.$EUCA_DOMAIN:8773/services/AutoScaling/
    cloudformation-url = http://cloudformation.$EUCA_REGION.$EUCA_DOMAIN:8773/services/CloudFormation/
    ec2-url = http://compute.$EUCA_REGION.$EUCA_DOMAIN:8773/services/compute/
    elasticloadbalancing-url = http://loadbalancing.$EUCA_REGION.$EUCA_DOMAIN:8773/services/LoadBalancing/
    iam-url = http://euare.$EUCA_REGION.$EUCA_DOMAIN:8773/services/Euare/
    monitoring-url = http://cloudwatch.$EUCA_REGION.$EUCA_DOMAIN:8773/services/CloudWatch/
    s3-url = http://objectstorage.$EUCA_REGION.$EUCA_DOMAIN:8773/services/objectstorage/
    sts-url = http://tokens.$EUCA_REGION.$EUCA_DOMAIN:8773/services/Tokens/
    swf-url = http://simpleworkflow.$EUCA_REGION.$EUCA_DOMAIN:8773/services/SimpleWorkflow/
    user = $EUCA_REGION-$EUCA_ACCOUNT-admin

    certificate = /usr/share/euca2ools/certs/cert-$EUCA_REGION.pem
    verify-ssl = false
    EOF
    ```

4. Configure Euca2ools Eucalyptus Region (via proxied HTTPS endpoints)

    It's possible to configure Eucalyptus with HTTPS endpoints. This method is more complex, but
    more secure.

    The certificate file must be moved from the Eucalyptus Cloud Controller to each Management
    Workstation via independent means not described here.

    This method currently does not work with Euca2ools 3.3 - SKIP this until fixed!

    ```bash
    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$EUCA_REGION.pem
    chmod 644 /usr/share/euca2ools/certs/cert-$EUCA_REGION.pem

    cat << EOF > /etc/euca2ools/conf.d/$EUCA_REGION.ini
    ; Eucalyptus Region $EUCA_REGION

    [region $EUCA_REGION]
    autoscaling-url = https://autoscaling.$EUCA_REGION.$EUCA_DOMAIN/services/AutoScaling/
    cloudformation-url = https://cloudformation.$EUCA_REGION.$EUCA_DOMAIN/services/CloudFormation/
    ec2-url = https://compute.$EUCA_REGION.$EUCA_DOMAIN/services/compute/
    elasticloadbalancing-url = https://loadbalancing.$EUCA_REGION.$EUCA_DOMAIN/services/LoadBalancing/
    iam-url = https://euare.$EUCA_REGION.$EUCA_DOMAIN/services/Euare/
    monitoring-url = https://cloudwatch.$EUCA_REGION.$EUCA_DOMAIN/services/CloudWatch/
    s3-url = https://objectstorage.$EUCA_REGION.$EUCA_DOMAIN/services/objectstorage/
    sts-url = https://tokens.$EUCA_REGION.$EUCA_DOMAIN/services/Tokens/
    swf-url = https://simpleworkflow.$EUCA_REGION.$EUCA_DOMAIN/services/SimpleWorkflow/
    user = $EUCA_REGION-$EUCA_ACCOUNT-admin

    certificate = /usr/share/euca2ools/certs/cert-$EUCA_REGION.pem
    verify-ssl = true
    EOF
    ```

5. Configure Euca2ools Eucalyptus Demo Account User

    ```bash
    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/$EUCA_REGION.ini
    ; Eucalyptus Region $EUCA_REGION

    [user $EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER]
    key-id = $EUCA_USER_ACCESS_KEY
    secret-key = $EUCA_USER_SECRET_KEY
    account-id = $EUCA_USER_ACCOUNT_ID

    EOF
    ```

6. Configure Euca2ools AWS Account User

    ```bash
    cat << EOF > ~/.euca/$EUCA_REGION.ini
    ; Eucalyptus Region $EUCA_REGION

    [user $EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER]
    key-id = $EUCA_USER_ACCESS_KEY
    secret-key = $EUCA_USER_SECRET_KEY
    account-id = $EUCA_USER_ACCOUNT_ID

    EOF
    ```

7. Display Euca2ools New Configuration

    ```bash
    ```

8. Install AWSCLI

    ```bash
    ```

9. Display AWSCLI Initial Configuration

    ```bash
    ```

10. Configure AWSCLI Eucalyptus Region (via direct HTTP endpoints)

    ```bash
    ```

11. Configure AWSCLI Eucalyptus SSL Certificate

    ```bash
    ```

12. Configure AWSCLI Eucalyptus Region (via proxied HTTPS endpoints)

    ```bash
    ```

13. Configure AWSCLI Eucalyptus Demo Account User

    ```bash
    ```

14. Configure AWSCLI AWS Account User

    ```bash
    ```

15. Display AWSCLI New Configuration

    ```bash
    ```

16. List Eucalyptus Demo Account Resources via Euca2ools

    ```bash
    ```

17. List AWS Account Resources via Euca2ools

    ```bash
    ```

18. List Eucalyptus Demo Account Resources via AWSCLI

    ```bash
    ```

19. List AWS Account Resources via AWSCLI

    ```bash
    ```


2. Create Demo (demo) Account Administrator Login Profile

    This allows the Demo Account Administrator to login to the console.

    ```bash
    euare-usermodloginprofile -p demo123 --as-account demo --region $USER_REGION admin
    ```

3. Create Demo (demo) Account Administrator Access Key

    This allows the Demo Account Administrator to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/admin

    result=$(euare-useraddkey --as-account demo --region $USER_REGION admin)
    read access_key secret_key <<< $result

    cat << EOF > ~/.creds/$REGION/demo/admin/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

4. Create Demo (demo) Account Administrator Euca2ools Profile

    This allows the Demo Account Administrator to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-admin]
    key-id = $access_key
    secret-key = $secret_key
    account-id = $account_id

    EOF

    euca-describe-availability-zones verbose --region $REGION-demo-admin@$REGION
    ```

5. Create Demo (demo) Account Administrator AWSCLI Profile

    This allows the Demo Account Administrator to run API commands via AWSCLI.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile $REGION-demo-admin]
    region = $REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$REGION-demo-admin]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile $REGION-demo-admin --region $REGION
    ```

6. Authorize Demo (demo) Account use of Demo Generic Image

    Lookup the demo account id and centos generic image id, as these will be different for each environment.

    ```bash
    account_id=$(euare-accountlist --region $USER_REGION | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images --filter manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml \
                                    --region $USER_REGION | cut -f2)

    euca-modify-image-attribute --launch-permission --add $account_id --region $USER_REGION $image_id
    ```

7. Authorize Demo (demo) Account use of Demo CFN + AWSCLI Image

    Lookup the demo account id and centos cfn + awscli image id, as these will be different for each environment.

    ```bash
    account_id=$(euare-accountlist --region $USER_REGION | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images --filter manifest-location=images/CentOS-6-x86_64-CFN-AWSCLI.raw.manifest.xml \
                                     --region $USER_REGION | cut -f2)

    euca-modify-image-attribute --launch-permission --add $account_id --region $USER_REGION $image_id
    ```

8. List Demo Resources

    ```bash
    euca-describe-images --region $USER_REGION

    euare-accountlist --region $USER_REGION
    ```

9. Display Euca2ools Configuration

    ```bash
    cat /etc/euca2ools/conf.d/$REGION.ini

    cat ~/.euca/global.ini

    cat ~/.euca/$REGION.ini
    ```

10. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

