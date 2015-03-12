# Demo Account Manual Installation

This is the set of manual steps to setup the demo account.

### Initialize Demo Account Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/feature/poc/bin/euca-demo-01-initialize-account.sh

Help is available when running this script, via the -? flag.

```bash
euca-demo-01-initialize-account.sh -?
```

Usage: euca-demo-01-initialize-account.sh [-I [-s | -f]] [-a account] [-l]
  -I          non-interactive
  -s          slower: increase pauses by 25%
  -f          faster: reduce pauses by 25%
  -a account  account to create for use in demos (default: demo)
  -l          Use local mirror for Demo CentOS image

By default, the demo account created is named "demo", but this can be overridden with the -a account flag.
This allows alternate and/or multiple demo accounts to be used.

### Initialize Demo Account Manual Procedure

1. Use Eucalyptus Administrator credentials

    ```bash
    cat ~/creds/eucalyptus/admin/eucarc

    source ~/creds/eucalyptus/admin/eucarc
    ```

2. Create Eucalyptus Administrator Demo Keypair

    ```bash
    euca-create-keypair admin-demo | tee ~/creds/eucalyptus/admin/admin-demo.pem

    chmod 0600 ~/creds/eucalyptus/admin/admin-demo.pem
    ```

3. Create Demo (demo) Account

    ```bash
    euare-accountcreate -a demo
    ```

4. Create Demo (demo) Account Administrator Login Profile

    This allows the Demo Account Administrator to login to the console

    ```bash
    euare-usermodloginprofile –u admin –p demo123 -as-account demo
    ```

5. Download Demo (demo) Account Administrator Credentials

    This allows the Demo Account Administrator to run API commands

    ```bash
    mkdir -p ~/creds/demo/admin

    rm -f ~/creds/demo/admin.zip

    sudo euca-get-credentials -u admin -a demo ~/creds/demo/admin.zip

    unzip -uo ~/creds/demo/admin.zip -d ~/creds/demo/admin/

    cat ~/creds/demo/admin/eucarc
    ```

6. Download Demo Image (CentOS 6.5)

    ```bash
    wget http://eucalyptus-images.s3.amazonaws.com/public/centos.raw.xz -O ~/centos.raw.xz

    xz -v -d ~/centos.raw.xz
    ```

7. Install Demo Image

    ```bash
    euca-install-image -b images -r x86_64 -i ~/centos.raw -n centos65 --virtualization-type hvm
    ```

8. Authorize Demo (demo) Account use of Demo Image

    Lookup the demo account id and centos image id, as these will be different for each environment

    ```bash
    account_id=$(euare-accountlist | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)

    euca-modify-image-attribute -l -a $account_id $image_id
    ```

9. List Demo Resources

    ```bash
    euca-describe-images

    euca-describe-keypairs

    euare-accountlist
    ```
