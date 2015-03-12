# Demo Dependencies Manual Installation

This is the set of manual steps to setup additional dependencies within the demo account.

### Initialize Demo Dependencies Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/feature/poc/bin/euca-demo-02-initialize-dependencies.sh

Help is available when running this script, via the -? flag.

    ```bash
    euca-demo-02-initialize-dependencies.sh -?
    ```
    Usage: euca-demo-02-initialize-dependencies.sh [-I [-s | -f]] [-a account]
      -I          non-interactive
      -s          slower: increase pauses by 25%
      -f          faster: reduce pauses by 25%
      -a account  account to create for use in demos (default: demo)

As noted in the help message, by default, the demo account used is named "demo", but this can be
overridden with the -a account flag. This allows alternate and/or multiple demo accounts to be used.

### Initialize Demo Dependencies Manual Procedure

This procedure depends on the existance of the Demo account administrator credentials in
the ~/creds/demo/admin directory. If an account other than "demo" was created, this path would 
instead reference that account name.

Additionally, the procedure or script to initialize the demo account must have been run.

1. Use Demo (demo) Account Administrator credentials

    ```bash
    cat ~/creds/demo/admin/eucarc

    source ~/creds/demo/admin/eucarc
    ```

2. List Images available to Demo (demo) Account Administrator

    ```bash
    euca-describe-images -a
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
