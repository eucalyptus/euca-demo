# Demo 20 Workload Repatriation Manual Instructions

This is the set of manual steps to perform Demo 20: Workload Repatriation.

### Demo 20: Workload Repatriation Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/feature/poc/bin/euca-demo-20-workload-repatriation.sh

Help is available when running this script, via the -? flag.

```bash
euca-demo-20-workload-repatriation.sh -?
Usage: euca-demo-20-workload-repatriation.sh [-I [-s | -f]] [-a account]
  -I          non-interactive
  -s          slower: increase pauses by 25%
  -f          faster: reduce pauses by 25%
  -a account  account to use for this demo (default: demo)
```

By default, the demo account used is named "demo", but this can be overridden with the -a account flag.
This allows alternate and/or multiple demo accounts to be used.

### Demo 20: Workload Repatriation Manual Procedure

1. Define environment variables
    - These will be used in steps below, allowing those to remain static
    - Adjust these for your environment

    ```bash
    export AWS_DEFAULT_PROFILE=us-east-1-eucalyptus-discover
    ```

2. Create CloudFormation stack using AWS Simple Wordpress Template

    ```bash
    aws cloudformation create-stack --stack-name=wordpress-demo-discover \
                                    --template-body file:///cygdrive/c/Users/lwade/Downloads/wordpress-demo-discover-2015 \
                                    --parameters ParameterKey=KeyName,ParameterValue=mykeypair-east1 \
                                                 ParameterKey=DBUser,ParameterValue=demo \
                                                 ParameterKey=DBPassword,ParameterValue=password \
                                                 ParameterKey=DBRootPassword,ParameterValue=password \
                                                 ParameterKey=EndPoint,ParameterValue=https://cloudformation.us-east-1.amazonaws.com \
                                    --capabilities CAPABILITY_IAM \
                                    --region us-east-1
    ```



6. Download Demo Image with cfn-init installed (CentOS 6.6)

    ```bash
    cd /var/tmp
    wget http://jeevan-blog-3.s3.amazonaws.com/centos66-cfntools.img.tar.bz2

    tar xvfj centos66-cfntools.img.tar.bz2
    ```

7. Install Demo Image

    ```bash
    euca-install-image -b centos-cfn-patch -r x86_64 -i /var/tmp/centos66-cfntools.img -n centos66-cfntools --virtualization-type hvm
    ```

8. Authorize Demo (demo) Account use of Demo Image

    Lookup the demo account id and centos image id, as these will be different for each environment

    ```bash
    account_id=$(euare-accountlist | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images | grep centos66-cfntools.img.manifest.xml | cut -f2)

    euca-modify-image-attribute -l -a $account_id $image_id
    ```








3. Create Demo (demo) Account Administrator Demo Keypair

    ```bash
    euca-create-keypair admin-demo | tee ~/creds/demo/admin/admin-demo.pem

    chmod 0600 ~/creds/demo/admin/admin-demo.pem
    ```

4. Create Demo (demo) Account User (user)

    ```bash
    euare-usercreate -u user
    ```

5. Create Demo (demo) Account User (user) Login Profile

    This allows the Demo Account User to login to the console

    ```bash
    euare-useraddloginprofile -u user -p user123
    ```

6. Download Demo (demo) Account User (user) Credentials

    This allows the Demo Account User to run API commands

    ```bash
    mkdir -p ~/creds/demo/user

    rm -f ~/creds/demo/user.zip

    sudo euca-get-credentials -u user -a demo ~/creds/demo/user.zip

    unzip -uo ~/creds/demo/user.zip -d ~/creds/demo/user/

    cat ~/creds/demo/user/eucarc
    ```

7. Create Demo (demo) Account Users (users) Group

    ```bash
    euare-groupcreate -g users

    euare-groupadduser -g users -u user
    ```

8. Create Demo (demo) Account Developer (developer)

    ```bash
    euare-usercreate -u developer
    ```

9. Create Demo (demo) Account Developer (developer) Login Profile

    This allows the Demo Account Developer to login to the console

    ```bash
    euare-useraddloginprofile -u developer -p developer123
    ```

10. Download Demo (demo) Account Developer (developer) Credentials

    This allows the Demo Account Developer to run API commands

    ```bash
    mkdir -p ~/creds/demo/developer

    rm -f ~/creds/demo/developer.zip

    sudo euca-get-credentials -u developer -a demo ~/creds/demo/developer.zip

    unzip -uo ~/creds/demo/developer.zip -d ~/creds/demo/developer/

    cat ~/creds/demo/developer/eucarc
    ```

11. Create Demo (demo) Account Developers (developers) Group

    ```bash
    euare-groupcreate -g developers

    euare-groupadduser -g developers -u developer
    ```

12. List Demo Resources

    ```bash
    euca-describe-images

    euca-describe-keypairs

    euare-accountlist

    euare-userlistbypath

    euare-grouplistbypath
    euare-grouplistusers -g users
    euare-grouplistusers -g developers
    ```
