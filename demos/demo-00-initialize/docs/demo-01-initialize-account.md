# Demo Initialize: Initialize Demo Account

This document describes the manual procedure to initialize a demo account within a Eucalyptus
Region for demos.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the AWS_DEFAULT_REGION, and **mjc.prc.eucalyptus-systems.com** as the
AWS_DEFAULT_DOMAIN. Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    These instructions were based on a Faststart Install performed within the PRC on host
    odc-f-32.prc.eucalyptus-systems.com, configured as region hp-gol01-f1, using MCrawfords
    DNS server. Adjust the variables in this section to your environment.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1
    ```

### Initialize Demo Account

1. Use Eucalyptus Administrator credentials

    ```bash
    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

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
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)

    cat << EOF >> ~/.euca/euca2ools.ini
    [user demo-admin]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones verbose --region demo-admin@$AWS_DEFAULT_REGION
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

    aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-demo-admin
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
    euare-accountlist
    ```

10. List Euca2ools Configuration

    ```bash
    cat ~/.euca/euca2ools.ini
    ```

11. List AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

