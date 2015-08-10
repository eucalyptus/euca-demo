# Demo 30: CloudFormation: WordPress

This Demo shows how to run the WordPress CloudFormation template in both an AWS Account and a
Eucalyptus Region, and migrate WordPress content, as an example of Workload Repatriation.

The instructions below are currently based on these Regions during testing. We will move these to
more permanent accounts shortly:
- Eucalyptus
  - Region: hp-aw2-1
  - Account: demo
  - User: admin
- AWS
  - Region: us-west-2
  - Account: mjchp
  - User: demo

Prior to running this demo, the Eucalyptus Region and AWS Account must be prepared for demos via
the Demo Initialization scripts, as this demo depends on objects created by those scripts. The
initialization scripts can be found in [this directory](../../demo-00-initialization/bin), and
manual procedures which perform the same actions can be found in 
[this directory](../../demo-00-initialization/docs). Additionally, the end-to-end process of
installing Eucalyptus via FastStart, augmenting the installation with features such as DNS, PKI,
reverse-proxy with SSL termination, AWSCLI and Euca2ools configuration, and demo initialization,
are described in detail for [Demo 20: CloudFormation: Simple](../../demo-20-cfn-simple/docs/README.md)
demo.

### CloudFormation WordPress Demo Overview

This demo creates a modified version of the "WordPress_Single_Instance" template in both an
AWS Account and an Account in a Eucalyptus Region. This template has been modified from the 
original to add an Instance Profile which allows the Instance to lookup CloudFormation
information and store a WordPress database backup in S3, so it can be used to show repatriation.
It has also been modified to allow custom endpoints with cloud-init, so CloudFormation signals
can reach Eucalyptus CloudFormation endpoints.

This demo is complicated by the fact it coordinates activities across both an AWS Account and
an Account in a Eucalyptus Region, as well as the time required to complete each CloudFormation
Stack, which usually means we want to create and leave running the Stack in AWS. However, to show
that the migration is live, we want to create fresh content prior to each migration. Another
complication is the need to support what may be multiple separate demo environments which may be
using different Eucalyptus Regions and AWS accounts without conflict.

As a result, it's possible to adjust quite a bit of behavior via command-line options when
running these scripts. Each script can be run with a help (-?) option to show what parameters are
available, but here is a list of the most important options, along with some explanation of how
they're meant to be used:

```bash
  -I               non-interactive
  -v               verbose
  -m mode          mode: Initialize a=AWS, e=Eucalyptus or b=Both (default: e)
  -r euca_region   Eucalyptus Region (default: hp-aw2-1)
  -a euca_account  Eucalyptus Account (default: demo)
  -u euca_user     Eucalyptus User (default: admin)
  -R aws_region    AWS Region (default: us-east-1)
  -A aws_account   AWS Account (default: euca)
  -U aws_user      AWS User (default: demo)
```

The non-interactive (-I) option will cause the script to run automatically from start to end
with delays before and after each action so a user can follow what each step does. Normally,
the scripts require the user to hit enter to proceed with each step.

The verbose (-v) option will list Resources before and after steps which create or delete them.
It will also display the Template prior to running it. You may want to specify this for a more
technical audience.

The mode (-m) option controls which Account is affected by the script, allowing AWS or Eucalyptus
to be initialized, run or reset separately, or together. Note that the default is to only
affect Eucalyptus, as it's expected the AWS Account will generally be setup in advance and
left running due to the time it takes to create the CloudFormation Stack there.

The Eucalyptus region (-r), account (-a) and user (-u) options allow specification of the
Eucalyptus Region, Account and User. These are optional and will default to the demo account
administrator of the host's Region when run on a Cloud Controller. When run from a central
management workstation which is configured to work with multiple Eucalyptus Regions, these
options are initialized to the values of the AWS_DEFAULT_REGION, AWS_ACCOUNT_NAME, and 
AWS_USER_NAME environment variables. Setting these appropriately can shorten what you need
to type on command lines.

The AWS region (-R), account (-A) and user (-U) options allow specification of the AWS Account
Region, Account and User. These default to the primary Eucalyptus Account used for Demos,
which should normally be correct. (NOTE: Currently testing against the mjchp test account, until
we formally convert the main Eucalyptus account to this demo format!)

These scripts also depend on the prior setup of both Euca2ools and AWSCLI on the host where 
they are run. The host account must have been configured with the credentials of the AWS and
Eucalyptus Users which are referenced by the script options or default values.

### Initialize CloudFormation WordPress Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation WordPress Demo in both the Eucalyptus and AWS Accounts

    This initialization has to be done only once, but can be run as often as desired. It
    customizes the WordPress CloudFormation Template to reference the Eucalyptus Region's
    Region-specific EMI ID for the Image which will be used in the Template, confirms
    Dependencies are available, and lists what Resources and Stacks currently exist.

    Procedure: [demo-30-initialize-cfn-wordpress.md](demo-30-initialize-cfn-wordpress.md)

    Script: [demo-30-initialize-cfn-wordpress.sh](../bin/demo-30-initialize-cfn-wordpress.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-30-cfn-wordpress/bin

    ./demo-30-initialize-cfn-wordpress.sh -m b -R us-west-2 -A mjchp
    ```

### Run CloudFormation WordPress Demo

These are steps needed to run this demo, assuming baseline and demo-specific initialization
has been done.

1. Run the CloudFormation WordPress Demo in the AWS Account

    While it's possible to run the demo against both AWS and Eucalyptus Accounts in a single
    procedure, the time required to create the Stack in AWS is usually something we want to
    avoid in most demo settings. The time needed is not worth the benefit. So, we recommend
    the run script be run against the AWS Account in advance, so WordPress on the AWS instance
    which will be the source of the migration is left installed, configured and runnning.

    There are three variants of this procedure which perform identical actions, using
    the GUI, Euca2ools or AWSCLI, with the latter two also implemented as bash scripts. While
    it's possible to use the GUI method to setup the AWS Account, it's likely to be quicker
    and less error-prone to run the script for this step.

    Choose only one of these methods.

    GUI Procedure: [demo-30-run-cfn-wordpress-gui.md](demo-30-run-cfn-wordpress-gui.md)

    Euca2ools Procedure: [demo-30-run-cfn-wordpress-cli.md](demo-30-run-cfn-wordpress-cli.md)

    Euca2ools Script: [demo-30-run-cfn-wordpress.sh](../bin/demo-30-run-cfn-wordpress.sh)

    ```bash
    ./demo-30-run-cfn-wordpress.sh -m a -R us-west-2 -A mjchp
    ```

    AWSCLI Procedure: [demo-30-run-cfn-wordpress-awscli.md](demo-30-run-cfn-wordpress-awscli.md)

    AWSCLI Script: [demo-30-run-cfn-wordpress-awscli.sh](../bin/demo-30-run-cfn-wordpress-awscli.sh)

    ```bash
    ./demo-30-run-cfn-wordpress-awscli.sh -m a -R us-west-2 -A mjchp
    ```

2. Run the CloudFormation WordPress Demo in the Eucalyptus Account

    **This is likely to be the only "live" portion of the demo.**

    This procedure will download the modified WordPress CloudFormation Template, create the
    WordPress Stack, Backup WordPress on the AWS Instance and save the backup to S3, Download
    the backup from S3 to the Eucalyptus Instance, Restore WordPress from the backup, then
    Display the Eucalyptus copy of WordPress to confirm the Migration.

    This procedure can be run multiple times against the same instantiation of WordPress in
    AWS, and will move any content added to that instance each time. It can also be run against
    the same instantiation of WordPress in Eucalyptus, and will skip over the creation of the
    Stack if it already exists, and simply restore new content.

    There are three variants of this procedure which perform identical actions, using
    the GUI, Euca2ools or AWSCLI, with the latter two also implemented as bash scripts. While
    it's possible to use the script methods to run the live demo, it's likely to be a better
    experience for all but a very technical audience to use the GUI.

    Choose only one of these methods.

    GUI Procedure: [demo-30-run-cfn-wordpress-gui.md](demo-30-run-cfn-wordpress-gui.md)

    Euca2ools Procedure: [demo-30-run-cfn-wordpress-cli.md](demo-30-run-cfn-wordpress-cli.md)

    Euca2ools Script: [demo-30-run-cfn-wordpress.sh](../bin/demo-30-run-cfn-wordpress.sh)

    ```bash
    ./demo-30-run-cfn-wordpress.sh -m e -R us-west-2 -A mjchp
    ```

    AWSCLI Procedure: [demo-30-run-cfn-wordpress-awscli.md](demo-30-run-cfn-wordpress-awscli.md)

    AWSCLI Script: [demo-30-run-cfn-wordpress-awscli.sh](../bin/demo-30-run-cfn-wordpress-awscli.sh)

    ```bash
    ./demo-30-run-cfn-wordpress-awscli.sh -m e -R us-west-2 -A mjchp
    ```

### Reset CloudFormation WordPress Demo

These are steps needed to reset this demo, assuming it has been run successfully or unsuccessfully
one or more times in either or both Regions. Running this will not delete the Template modifications,
meaning it's not necessary to re-run this demo's initialization script after a reset.

1. Reset the CloudFormation WordPress Demo in the Eucalyptus Account

    While it's possible to reset the demo in both AWS and Eucalyptus Accounts in a single
    procedure, since the time required to create the Stack in AWS is usually something we want to
    avoid in most demo settings, we will typically only reset the Eucalyptus Account and leave
    the AWS Account WordPress Instance running.

    Procedure: [demo-30-reset-cfn-wordpress.md](demo-30-reset-cfn-wordpress.md)

    Script: [demo-30-reset-cfn-wordpress.sh](../bin/demo-30-reset-cfn-wordpress.sh)

    ```bash
    ./demo-30-reset-cfn-wordpress.sh -m e -R us-west-2 -A mjchp
    ```

2. Reset the CloudFormation WordPress Demo in the AWS Account

    **This should usually not be run - normally we will leave the AWS WordPress Instance running.**

    Due to the time required to create the Stack in AWS, we will usually want to leave the Stack
    running when we reset the demo in the Eucalyptus Region. Run this procedure, then re-create
    the AWS WordPress Stack, when you want to have a clean start on the Blog content.

    Procedure: [demo-30-reset-cfn-wordpress.md](demo-30-reset-cfn-wordpress.md)

    Script: [demo-30-reset-cfn-wordpress.sh](../bin/demo-30-reset-cfn-wordpress.sh)

    ```bash
    ./demo-30-reset-cfn-wordpress.sh -m a -R us-west-2 -A mjchp
    ```

