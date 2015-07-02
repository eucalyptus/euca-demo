# Demo Account Manual Initialization

This is the set of manual steps to setup a demo account in a new Eucalyptus system for demos.

### Initialize Demo Account Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/master/demos/demo-00-initialize/bin/demo-01-initialize-account.sh

Help is available when running this script, via the -? flag.

```bash
demo-01-initialize-account.sh -?
Usage: demo-01-initialize-account.sh [-I [-s | -f]] [-a account] [-p password]
  -I          non-interactive
  -s          slower: increase pauses by 25%
  -f          faster: reduce pauses by 25%
  -a account  account to create for use in demos (default: demo)
  -p password password for demo account administrator (default: demo123)
```

By default, the demo account created is named "demo", but this can be overridden with the -a account flag.
This allows alternate and/or multiple demo accounts to be used.

Credentials are now stored in a directory structure which allows for multiple regions.

Your ~/.bash_profile should set the environment variable AWS_DEFAULT_REGION to reference the local region.

### Initialize Demo Account Manual Procedure

1. Use Eucalyptus Administrator credentials

    Adjust AWS_DEFAULT_REGION to your new region.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1

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

