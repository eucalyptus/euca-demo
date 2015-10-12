# Demo 21: CloudFormation: ELB

This Demo shows how to run a CloudFormation template which creates a Security Group, ELB and pair
of Instances attached to the ELB.

Prior to running this demo, the Eucalyptus Region must be prepared for demos via the Demo
Initialization scripts, as this demo depends on objects created by those scripts. The
initialization scripts can be found in [this directory](../demo-00-initialization/bin), and
manual procedures which perform the same actions can be found in
[this directory](../demo-00-initialization/docs). Additionally, the end-to-end process of
installing Eucalyptus via FastStart, augmenting the installation with features such as DNS, PKI,
reverse-proxy with SSL termination, AWSCLI and Euca2ools configuration, and demo initialization,
are described in detail for the [Demo 20: CloudFormation: Simple](../demo-20-cfn-simple/README.md)
demo.

### CloudFormation ELB Demo Key Points

The following are key points illustrated in this demo:

* This demo demonstrates use of CloudFormation to create an Elastic Load Balancer attached to
  a couple of Instances, and is intended as an introduction to both the CloudFormation and
  ELB features in Eucalyptus.
* It is possible to view, run and monitor activities and resources created by CloudFormation
  via the Eucalyptus or AWS Command line tools, or now within the Eucalyptus Console.

### Initialize CloudFormation ELB Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CloudFormation ELB Demo

    This initialization has to be done only once, but can be run as often as desired.

    Procedure: [demo-21-initialize-cfn-elb.md](docs/demo-21-initialize-cfn-elb.md)

    Script: [demo-21-initialize-cfn-elb.sh](bin/demo-21-initialize-cfn-elb.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-21-cfn-elb/bin

    ./demo-21-initialize-cfn-elb.sh
    ```

### Run CloudFormation ELB Demo

These are steps needed to run this demo, assuming baseline and demo-specific initialization
has been done.

1. Run the CloudFormation ELB Demo

    **This is likely to be the only "live" portion of the demo.**

    There are three variants of this procedure which perform identical actions, using
    the GUI, Euca2ools or AWSCLI, with the latter two also implemented as bash scripts. While
    it's possible to use the script methods to run the live demo, it's likely to be a better
    experience for all but a very technical audience to use the GUI.

    **Choose only one of these methods.**

    GUI Procedure: [demo-21-run-cfn-elb-gui.md](docs/demo-21-run-cfn-elb-gui.md)

    Euca2ools Procedure: [demo-21-run-cfn-elb-cli.md](docs/demo-21-run-cfn-elb-cli.md)

    Euca2ools Script: [demo-21-run-cfn-elb.sh](bin/demo-21-run-cfn-elb.sh)

    ```bash
    ./demo-21-run-cfn-wordpress.sh
    ```

    AWSCLI Procedure: [demo-21-run-cfn-elb-awscli.md](docs/demo-21-run-cfn-elb-awscli.md)

    AWSCLI Script: [demo-21-run-cfn-elb-awscli.sh](bin/demo-21-run-cfn-elb-awscli.sh)

    ```bash
    ./demo-21-run-cfn-elb-awscli.sh
    ```

### Reset CloudFormation ELB Demo

These are steps needed to reset this demo, assuming it has been run successfully or unsuccessfully
one or more times. It's not necessary to re-run this demo's initialization script after a reset.

1. Reset the CloudFormation ELB Demo

    Procedure: [demo-21-reset-cfn-elb.md](docs/demo-21-reset-cfn-elb.md)

    Script: [demo-21-reset-cfn-elb.sh](bin/demo-21-reset-cfn-elb.sh)

    ```bash
    ./demo-21-reset-cfn-elb.sh
    ```

