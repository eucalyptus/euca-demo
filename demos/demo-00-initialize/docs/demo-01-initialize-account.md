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
    export REGION=hp-gol01-d8
    export USER=admin

    export USER_REGION=$REGION-$USER@$REGION
    ```

### Initialize Demo Account

1. Create Demo (demo) Account

    ```bash
    account_id=$(euare-accountcreate --region $USER_REGION demo | cut -f2)
    ```

2. Create Demo (demo) Account Administrator Login Profile

    This allows the Demo Account Administrator to login to the console.

    ```bash
    euare-usermodloginprofile -p demo123 --as-account demo --region $USER_REGION admin
    ```

3. Create Demo (demo) Account Administrator Access Key

    This allows the Demo Account Administrator to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/demo

    result=$(euare-useraddkey --region $USER_REGION demo)
    read access_key secret_key <<< $result

    cat << EOF > > ~/.creds/$REGION/demo/demo/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

4. Create Demo (demo) Account Administrator Certificate

    This allows the Demo Account Administrator to run certain API commands which still need a
    certificate.

    ```bash
    private_key=~/.creds/$REGION/demo/admin/euca2-admin-pk.pem
    certificate=~/.creds/$REGION/demo/admin/euca2-admin-cert.pem

    euare-usercreatecert --keyout $private_key --out $certificate --region $USER_REGION
    ```

5. Create Demo (demo) Account Administrator Euca2ools Profile

    This allows the Demo Account Administrator to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-admin]
    key-id = $access_key
    secret-key = $secret_key
    account-id = $account_id
    private-key = $private_key
    certificate = $certificate

    EOF

    euca-describe-availability-zones verbose --region $REGION-demo-admin@$REGION
    ```

6. Create Demo (demo) Account Administrator AWSCLI Profile

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

7. Authorize Demo (demo) Account use of Demo Generic Image

    Lookup the demo account id and centos generic image id, as these will be different for each environment.

    ```bash
    account_id=$(euare-accountlist --region $USER_REGION | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images --filter manifest-location=images/CentOS-6-x86_64-GenericCloud.raw.manifest.xml \
                                    --region $USER_REGION | cut -f2)

    euca-modify-image-attribute --launch-permission --add $account_id --region $USER_REGION $image_id
    ```

8. Authorize Demo (demo) Account use of Demo CFN + AWSCLI Image

    Lookup the demo account id and centos cfn + awscli image id, as these will be different for each environment.

    ```bash
    account_id=$(euare-accountlist --region $USER_REGION | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images --filter manifest-location=images/CentOS-6-x86_64-CFN-AWSCLI.raw.manifest.xml \
                                     --region $USER_REGION | cut -f2)

    euca-modify-image-attribute --launch-permission --add $account_id --region $USER_REGION $image_id
    ```

9. List Demo Resources

    ```bash
    euca-describe-images --region $USER_REGION

    euare-accountlist --region $USER_REGION
    ```

10. Display Euca2ools Configuration

    ```bash
    cat /etc/euca2ools/conf.d/$REGION.ini

    cat ~/.euca/global.ini

    cat ~/.euca/$REGION.ini
    ```

11. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

