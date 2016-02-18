# Demo Initialize: Initialize Demo Account Administrator

This document describes the manual procedure to initialize an administrator within the demo account.

### Prerequisites

This variant must be run by root on the Eucalyptus CLC host.

It assumes the environment was installed via FastStart and the additional scripts needed to
initialize DNS, PKI, SSL reverse-proxy and the initialization of Euca2ools and AWSCLI, as
described in the [FastStart Install](../../../installs/install-10-faststart) section, have
been run, or equivalent manual configuration has been done.

It also assumes the [demo-00-initialize.md](./demo-00-initialize.md) and
[demo-01-initialize-account.md(./demo-01-initialize-account.md) procedures have been run.

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
    export ACCOUNT=demo
    export USER=admin

    export USER_REGION=$REGION-$ACCOUNT-$USER@$REGION
    ```

### Initialize Demo Account Administrator

The steps below are automated in the [demo-02-initialize-account-administrator.sh](../bin/demo-02-initialize-account-administrator.sh) script.

1. Create Demo (demo) Account Administrators (Administrators) Group

    This Group is intended for Users who have complete control of all Resources in the Account.

    ```bash
    euare-groupcreate --region $USER_REGION Administrators
    ```

2.  Create Demo (demo) Account Administrators (Administrators) Group Policy

    This Policy provides full access to all resources.

    ```bash
    mkdir -p /var/tmp/demo

    cat << EOF >> /var/tmp/demo/AdministratorsGroupPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "*",
          "Resource": "*",
          "Effect": "Allow"
        }
      ]
    }
    EOF

    euare-groupuploadpolicy --policy-name AdministratorsPolicy \
                            --policy-document /var/tmp/demo/AdministratorsGroupPolicy.json \
                            --region $USER_REGION \
                            Administrators
    ```

3. Create Demo (demo) Account Administrator (mcrawford) User

    ```bash
    euare-usercreate --region $USER_REGION mcrawford
    ```

4. Add Demo (demo) Account Administrator (mcrawford) User to Administrators (Administrators) Group

    ```bash
    euare-groupadduser --user-name mcrawford --region $USER_REGION Administrators
    ```

5. Create Demo (demo) Account Administrator (mcrawford) User Login Profile

    This allows the Demo Account Administrator User to login to the console.

    ```bash
    euare-usermodloginprofile --password $PASSWORD --region $USER_REGION mcrawford
    ```

6. Create Demo (demo) Account Administrator (mcrawford) User Access Key

    This allows the Demo Account Administrator User to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/mcrawford

    result=$(euare-useraddkey --region $USER_REGION mcrawford)
    read access_key secret_key <<< $result

    cat << EOF > ~/.creds/$REGION/demo/mcrawford/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

7. Create Demo (demo) Account Administrator (mcrawford) User Euca2ools Profile

    This allows the Demo Account Administrator User to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-mcrawford]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones --region $REGION-demo-mcrawford@$REGION
    ```

8. Create Demo (demo) Account Administrator (mcrawford) User AWSCLI Profile

    This allows the Demo Account Administrator User to run AWSCLI commands.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile $REGION-demo-mcrawford]
    region = $REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$REGION-demo-mcrawford]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile $REGION-demo-mcrawford --region $REGION
    ```

9. List Demo Resources

    ```bash
    euca-describe-images --region $USER_REGION

    euca-describe-keypairs --region $USER_REGION

    euare-grouplistbypath --region $USER_REGION

    euare-userlistbypath --region $USER_REGION

    euare-grouplistusers --region $USER_REGION Administrators
    ```

10. Display Euca2ools Configuration

    ```bash
    cat ~/.euca/global.ini

    cat /etc/euca2ools/conf.d/$REGION.ini

    cat ~/.euca/$REGION.ini
    ```

11. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

