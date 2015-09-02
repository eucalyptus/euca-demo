# Demo Initialize: Initialize Demo Account

This document describes the manual procedure to initialize a Demo Account within a Eucalyptus
Region for demos.

### Prerequisites

This variant must be run by root on the Eucalyptus CLC host.

It assumes the environment was installed via FastStart and the additional scripts needed to
initialize DNS, PKI, SSL reverse-proxy and the initialization of Euca2ools and AWSCLI, as
described in the [FastStart Install](../../../installs/install-10-faststart) section, have
been run, or equivalent manual configuration has been done.

It also assumes the [demo-00-initialize.md](./demo-00-initialize.md) procedure has been run.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com
    export AWS_DEFAULT_PROFILE=$AWS_DEFAULT_REGION-admin
    export AWS_CREDENTIAL_FILE=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    ```

### Initialize Demo Account

2. Create Demo (demo) Account

    ```bash
    euare-accountcreate -a demo
    ```

3. Create Demo (demo) Account Administrator Login Profile

    This allows the Demo Account Administrator to login to the console

    ```bash
    euare-usermodloginprofile –u admin –p demo123 -as-account demo
    ```

4. Download Demo (demo) Account Administrator Credentials

    This allows the Demo Account Administrator to run API commands

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/demo/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/demo/admin.zip

    sudo euca-get-credentials -u admin -a demo ~/.creds/$AWS_DEFAULT_REGION/demo/admin.zip

    unzip -uo ~/creds/demo/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/demo/admin/

    cat ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc
    ```

5. Create Demo (demo) Account Administrator Euca2ools Profile

    Use Demo (demo) Account Administrator eucarc file for values

    ```bash
    account_id=$(sed -n -e "s/export EC2_ACCOUNT_NUMBER='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    private_key=$HOME/.creds/$AWS_DEFAULT_REGION/demo/admin/$(sed -n -e "s/export EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    certificate=$HOME/.creds/$AWS_DEFAULT_REGION/demo/admin/$(sed -n -e "s/export EC2_CERT=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)

    cat << EOF >> ~/.euca/$AWS_DEFAULT_REGION.ini
    [user $AWS_DEFAULT_REGION-demo-admin]
    account-id = $account_id
    key-id = $access_key
    secret-key = $secret_key
    private-key = $private_key
    certificate = $certificate

    EOF

    euca-describe-availability-zones verbose --region AWS_DEFAULT_REGION-demo-admin@$AWS_DEFAULT_REGION
    ```

6. Create Demo (demo) Account Administrator AWSCLI Profile

    This assumes the AWSCLI was installed and configured with Eucalyptus endpoints via separate instructions.

    Use Demo (demo) Account Administrator eucarc file for values

    ```bash
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)

    cat << EOF >> ~/.aws/config
    [profile $AWS_DEFAULT_REGION-demo-admin]
    region = $AWS_DEFAULT_REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$AWS_DEFAULT_REGION-demo-admin]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-demo-admin --region $AWS_DEFAULT_REGION
    ```

7. Authorize Demo (demo) Account use of Demo Generic Image

    Lookup the demo account id and centos generic image id, as these will be different for each environment

    ```bash
    account_id=$(euare-accountlist | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images | grep CentOS-6-x86_64-GenericCloud.raw.manifest.xml | cut -f2)

    euca-modify-image-attribute -l -a $account_id $image_id
    ```

8. Authorize Demo (demo) Account use of Demo CFN + AWSCLI Image

    Lookup the demo account id and centos cfn + awscli image id, as these will be different for each environment

    ```bash
    account_id=$(euare-accountlist | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images | grep CentOS-6-x86_64-CFN-AWSCLI.raw.manifest.xml | cut -f2)

    euca-modify-image-attribute -l -a $account_id $image_id
    ```

9. List Demo Resources

    ```bash
    euca-describe-images

    euare-accountlist
    ```

10. Display Euca2ools Configuration

    ```bash
    cat /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini

    cat ~/.euca/global.ini

    cat ~/.euca/$AWS_DEFAULT_REGION.ini
    ```

11. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

