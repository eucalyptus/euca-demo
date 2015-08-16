# Demo 20: CloudFormation: Simple

This Demo shows how to run a simple CloudFormation template in a Eucalyptus Region..

The instructions below are based on:
- Eucalyptus
  - Region: hp-aw2-1
  - Account: demo
  - User: demo

As this Demo is likely to be one of the first tested in a new Eucalyptus Region, complete Region
setup instructions will be provided here. These replicate documentation in other sections of this
project, but are concentrated here to show the overall end-to-end installation and demo initialization
process.

### Pre-Installation Steps

These are steps which must be run before you install Eucalyptus. In some cases, once a step has
been performed once, you can re-install without having to do it again. In other cases, a step
must be done between each re-kickstart of a host and a new install.

1. Create a Configuration File for each new Region

    Many of the installation scripts require additional input parameters which are not suitable
    for specification via parameters on the command line. These values are stored in per-region
    configuration files, named after the short name of the host which runs the CLC role.

    Examples of configuration files used in the Eucalyptus Goleta Problem Resolution Center can
    be found in the [FastStart installation configuration directory](../../../installs/install-10-faststart/conf/).
    Model any new files after those which are already there and place in the same directory.

    If a Region consists of multiple hosts, you should create a symlink with the name of
    each additional host that points to the CLC host configuration file.

2. Configure a new host with the appropriate environmental pre-requisites

    While the rest of this document will refer to scripts contained with the GitHub euca-demo
    project, we have a bootstrap problem to first get that project installed on a new host.

    Once you can login to a new host with CentOS 6.6 x86_64 Minimum installed, you can follow
    [these instructions](../../../installs/install-00-initialize/docs/install-01-initialize-host-user.md)
    to initialize the host with what you need to use the euca-demo framework.

    Once those instructions are followed, the euca-demo project will be located here:
    ~/src/eucalyptus/euca-demo, and all future instructions will assume this exists.

### Installation Steps

These are steps to install Eucalyptus, and perform certain post-intallation tweaks which are useful in
any situation, but which the demos assume will be in place.

Manual procedures exist to document the steps, and these have been automated as bash scripts which
will implement the procedure step-by-step.

All steps to be run on the Eucalyptus CLC as root, unless otherwise specified

1. Install Eucalyptus via FastStart

    Procedure: [install-10-faststart-install.md](../../../installs/install-10-faststart/docs/install-10-faststart-install.md)

    Script: [install-10-faststart-install.sh](../../../installs/install-10-faststart/bin/install-10-faststart-install.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/installs/install-10-faststart/bin

    ./install-10-faststart-install.sh
    ```

2. Configure DNS

    Procedure: [install-11-faststart-configure-dns.md](../../../installs/install-10-faststart/docs/install-11-faststart-configure-dns.md)

    Script: [install-11-faststart-configure-dns.sh](../../../installs/install-10-faststart/bin/install-11-faststart-configure-dns.sh)

    ```bash
    ./install-11-faststart-configure-dns.sh
    ```

3. Configure PKI

    Procedure: [install-12-faststart-configure-pki.md](../../../installs/install-10-faststart/docs/install-12-faststart-configure-pki.md)

    Script: [install-12-faststart-configure-pki.sh](../../../installs/install-10-faststart/bin/install-12-faststart-configure-pki.sh)

    ```bash
    ./install-12-faststart-configure-pki.sh
    ```

4. Configure Reverse-Proxy

    Procedure: [install-13-faststart-configure-proxy.md](../../../installs/install-10-faststart/docs/install-13-faststart-configure-proxy.md)

    Script: [install-13-faststart-configure-proxy.sh](../../../installs/install-10-faststart/bin/install-13-faststart-configure-proxy.sh)

    ```bash
    ./install-13-faststart-configure-proxy.sh
    ```

5. Configure Support

    Procedure: [install-15-faststart-configure-support.md](../../../installs/install-10-faststart/docs/install-15-faststart-configure-support.md)

    Script: [install-15-faststart-configure-support.sh](../../../installs/install-10-faststart/bin/install-15-faststart-configure-support.sh)

    ```bash
    ./install-15-faststart-configure-support.sh
    ```

6. Configure AWSCLI

    Procedure: [install-16-faststart-configure-awscli.md](../../../installs/install-10-faststart/docs/install-16-faststart-configure-awscli.md)

    Script: [install-16-faststart-configure-awscli.sh](../../../installs/install-10-faststart/bin/install-16-faststart-configure-awscli.sh)

    ```bash
    ./install-16-faststart-configure-awscli.sh
    ```

7. Update Console to later pre-4.2 version

    This step is temporary during the lead-up to the 4.2 release, as the 4.1.x release does not yet
    include the new HP branding and additional services described in these instructions.

    Procedure: [install-19-faststart-update-console.md](../../../installs/install-10-faststart/docs/install-19-faststart-update-console.md)

    Script: [install-19-faststart-update-console.sh](../../../installs/install-10-faststart/bin/install-19-faststart-update-console.sh)

    ```bash
    ./install-19-faststart-update-console.sh
    ```

### Demo Global Pre-Initialization Steps

These are steps which are independent of any single Eucalyptus Region, but which create artifacts
required for the Demos to work, which are installed by the Demo initialization scripts.

1. Create modified CentOS 6.6 minimum image with cfn-init and awscli

    The image is created via separate instructions, not yet documented, and must be accessible here:
    http://images-euca.s3-website-us-east-1.amazonaws.com/CentOS-6-x86_64-CFN-AWSCLI.raw.xz

    Procedure: TBD

    Script: TBD

    ```bash
    # TBD
    ```

### Demo Baseline Initialization Steps

These are steps to initialize a new Eucalyptus Region to run the Demos contained in the euca-demo
project. All demos in the euca-demo project assume the baseline of Resources created in these
scripts exist.

1. Initialize Eucalyptus for Demos

    Procedure: [demo-00-initialize.md](../../demo-00-initialize/docs/demo-00-initialize.md)

    Script: [demo-00-initialize.sh](../../demo-00-initialize/bin/demo-00-initialize.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-00-initialize/bin

    ./demo-00-initialize.sh -r hp-aw2-1
    ```

2. Initialize Eucalyptus Demo Account

    Procedure: [demo-00-initialize-account.md](../../demo-00-initialize/docs/demo-01-initialize-account.md)

    Script: [demo-00-initialize-account.sh](../../demo-00-initialize/bin/demo-01-initialize-account.sh)

    ```bash
    ./demo-01-initialize-account.sh -r hp-aw2-1 -a demo -p <password>
    ```

3. Initialize Eucalyptus Demo Account Administrator

    Procedure: [demo-02-initialize-account-administrator.md](../../demo-00-initialize/docs/demo-02-initialize-account-administrator.md)

    Script: [demo-02-initialize-account-administrator.sh](../../demo-00-initialize/bin/demo-02-initialize-account-administrator.sh)

    ```bash
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u mcrawford -p <mcrawford_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u lwade -p <lwade_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u bthomason -p <bthomason_password>
    ```

4. Initialize Eucalyptus Demo Account Dependencies

    There are two variants of this procedure which perform identical actions, using
    Euca2ools or AWSCLI, both implemented as bash scripts.

    Choose only one of these methods.

    Euca2ools Procedure: [demo-03-initialize-account-dependencies.md](../../demo-00-initialize/docs/demo-03-initialize-account-dependencies.md)

    Euca2ools Script: [demo-03-initialize-account-dependencies.sh](../../demo-00-initialize/bin/demo-03-initialize-account-dependencies.sh)

    ```bash
    ./demo-03-initialize-account-dependencies.sh -r hp-aw2-1 -a demo -p <password>
    ```

    AWSCLI Procedure: [demo-03-initialize-account-dependencies-awscli.md](../../demo-00-initialize/docs/demo-03-initialize-account-dependencies-awscli.md)

    AWSCLI Script: [demo-03-initialize-account-dependencies-awscli.sh](../../demo-00-initialize/bin/demo-03-initialize-account-dependencies-awscli.sh)

    ```bash
    ./demo-03-initialize-account-dependencies-awscli.sh -r hp-aw2-1 -a demo -p <password>
    ```

### Initialize CloudFormation Simple Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation Simple Demo

    Script: [demo-20-initialize-cfn-simple.sh](../bin/demo-20-initialize-cfn-simple.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/bin

    ./demo-20-initialize-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

### Run CloudFormation Simple Demo

1. Run the CloudFormation Simple Demo

    There are three variants of this procedure which perform identical actions, using
    the GUI, Euca2ools or AWSCLI, with the latter two also implemented as bash scripts.

    Choose only one of these methods.

    GUI Procedure: [demo-20-run-cfn-simple-gui.md](demo-20-run-cfn-simple-gui.md)

    Euca2ools Procedure: [demo-20-run-cfn-simple-cli.md](demo-20-run-cfn-simple-cli.md)

    Euca2ools Script: [demo-20-run-cfn-simple.sh](../bin/demo-20-run-cfn-simple.sh)

    ```bash
    ./demo-20-run-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

    AWSCLI Procedure: [demo-20-run-cfn-simple-awscli.md](demo-20-run-cfn-simple-awscli.md)

    AWSCLI Script: [demo-20-run-cfn-simple-awscli.sh](../bin/demo-20-run-cfn-simple-awscli.sh)

    ```bash
    ./demo-20-run-cfn-simple-awscli.sh -r hp-aw2-1 -a demo
    ```

### Reset CloudFormation Simple Demo

1. Reset the CloudFormation Simple Demo

    Script: [demo-20-reset-cfn-simple.sh](../bin/demo-20-reset-cfn-simple.sh)

    ```bash
    ./demo-20-reset-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

