# Demo 20: CloudFormation: Simple

This Demo shows how to run a simple CloudFormation template.

The instructions below assume we are using the "hp-aw2-1" Region and the demo Account was created 
with the default name of "demo".

As this Demo is likely to be one of the first tested in a new Eucalyptus Region, complete Region
setup instructions will be provided here. These replicate documentation in other sections of this
project, but are concentrated here to show the overall end-to-end installation and demo initialization
process.

### Pre-Installation Steps

These are steps which must be run before you install Eucalyptus. In some cases, once a step has
been performed once, you can re-install without having to do it again. In other cases, a step
must be done between each re-kickstart of a host and a new install.

1. Create a Configuration File for each new Region

    Many of the scripts require additional input parameters which are not suitable for
    specification via parameters on the command line. These values are stored in per-region
    configuration files, named after the short name of the host which runs the CLC role.

    Look in the euca-demo projects installs sub-directory for sub-directories named conf
    for examples of existing configuration files, and model any new files after what already
    exists.

    If a region consists of multiple hosts, you should create a symlink with the name of
    each additional host that points to the CLC host configuration file.

2. Configure a new host with the appropriate environmental pre-requisites

    While the rest of this document will refer to scripts contained with the GitHub euca-demo
    project, we have a bootstrap problem to first get that project installed on a new host.

    While logged in as root, follow these instructions:
    https://github.com/eucalyptus/euca-demo/blob/master/installs/install-00-initialize/docs/install-01-initialize-host-user.md

    Once those instructions are followed, the euca-demo project will be located here:
    ~/src/eucalyptus/euca-demo, and all future instructions will assume this exists.

### Installation Steps

These are steps to install Eucalyptus, and perform certain post-intallation tweaks which are useful in
any situation, but which the demos assume will be in place.

All steps to be run on the Eucalyptus CLC as root, unless otherwise specified

1. Install Eucalyptus via FastStart

    ```bash
    cd ~/src/eucalyptus/euca-demo/installs/install-10-faststart/bin

    ./install-10-faststart-install.sh
    ```

2. Configure DNS

    ```bash
    ./install-11-faststart-configure-dns.sh
    ```

3. Configure PKI

    ```bash
    ./install-12-faststart-configure-pki.sh
    ```

4. Configure Reverse-Proxy

    ```bash
    ./install-13-faststart-configure-proxy.sh
    ```

5. Configure Support

    ```bash
    ./install-15-faststart-configure-support.sh
    ```

6. Configure AWSCLI

    ```bash
    ./install-16-faststart-configure-awscli.sh
    ```

7. Update Console to later pre-4.2 version

    This step is temporary during the lead-up to the 4.2 release, as the 4.1.x release does not yet
    include the new HP branding and additional services described in these instructions.

    ```bash
    ./install-19-faststart-update-console.sh
    ```

### Demo Global Pre-Initialization Steps

These are steps which are independent of any single Eucalyptus Region, but which create artifacts
required for the Demos to work, which are installed by the Demo initialization scripts.

1. Create modified CentOS 6.6 minimum image with cfn-init and awscli

    - The image is created via separate instructions, and must be accessible here:
      http://images-euca.s3-website-us-east-1.amazonaws.com/CentOS-6-x86_64-CFN-AWSCLI.raw.xz

### Demo Baseline Initialization Steps

These are steps to initialize a new Eucalyptus Region to run the Demos contained in the euca-demo
project. All demos in the euca-demo project assume the baseline of Resources created in these
scripts exist.

1. Initialize Eucalyptus for Demos

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-00-initialize/bin

    ./demo-00-initialize.sh -r hp-aw2-1
    ```

2. Initialize Eucalyptus Demo Account

    ```bash
    ./demo-01-initialize-account.sh -r hp-aw2-1 -a demo -p <password>
    ```

3. Initialize Eucalyptus Demo Account Administrator

    ```bash
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u mcrawford -p <mcrawford_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u lwade -p <lwade_password>
    ./demo-02-initialize-account-administrator.sh -r hp-aw2-1 -a demo -u bthomason -p <bthomason_password>
    ```

4. Initialize Eucalyptus Demo Account Dependencies

    There are two variants of this script which perform identical actions, using
    either Euca2ools or AWSCLI. You can run either script, but should not run both.

    Run the version which uses euca2ools:

    ```bash
    ./demo-03-initialize-account-dependencies.sh -r hp-aw2-1 -a demo -p <password>
    ```

    Or, run the version which uses AWSCLI: 

    ```bash
    ./demo-03-initialize-account-dependencies-awscli.sh -r hp-aw2-1 -a demo -p <password>
    ```

### Initialize CloudFormation Simple Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation Simple Demo

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple/bin

    ./demo-20-initialize-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

### Run CloudFormation Simple Demo

1. Run the CloudFormation Simple Demo

    There are two variants of this script which perform identical actions, using
    either Euca2ools or AWSCLI. You can run either script, but should not run both.

    Run the version which uses euca2ools:

    ```bash
    ./demo-20-run-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

    Or, run the version which uses AWSCLI:

    ```bash
    ./demo-20-run-cfn-simple-awscli.sh -r hp-aw2-1 -a demo
    ```

    It's also possible to run this demo via manual procedures located in this directory.

### Reset CloudFormation Simple Demo

1. Reset the CloudFormation Simple Demo

    ```bash
    ./demo-20-reset-cfn-simple.sh -r hp-aw2-1 -a demo
    ```

