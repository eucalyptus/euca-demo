# Demo 10: CLI: ELB + ASG + User-Data

This Demo shows how to use the CLI (Command-Line Interface) to create a SecurityGroup,
ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup, ScalingPolicies, CloudWatch
Alarms and Instances which use User-Data scripts for configuration.

Prior to running this demo, the Eucalyptus Region must be prepared for demos via the Demo
Initialization scripts, as this demo depends on objects created by those scripts. The
initialization scripts can be found in [this directory](../demo-00-initialize/bin), and
manual procedures which perform the same actions can be found in
[this directory](../demo-00-initialize/docs).

Additionally, the end-to-end process of installing Eucalyptus via FastStart, augmenting the
installation with features such as DNS, PKI, reverse-proxy with SSL termination, AWSCLI and
Euca2ools configuration, and demo initialization, are described in detail for the
[Demo 20: CloudFormation: Simple](../demo-20-cfn-simple/README.md) demo.

### CLI: ELB + ASG + User-Data Demo Key Points

The following are key points illustrated in this demo:

* This demo demonstrates use of the CLI (Command-Line Interface) to create a variety of 
  Eucalyptus AWS-compatible Resources, including: SecurityGroup, ElasticLoadBalancer,
  LaunchConfiguration, AutoScaleGroup, ScalingPolicy, CloudWatch Alarm and Instance.
* We show how user-data scripts can configure an instance automatically upon creation.
* We show how a LaunchConfiguration can be modified to simulate a rolling update of a
  new application within an AutoScaleGroup.
* It is possible to create, view and manage Resources via the Eucalyptus Console or
  CLI commands.

### Initialize CLI: ELB + ASG + User-Data Demo

These are steps needed to initialize this demo, on top of the baseline initialization.

1. Initialize the CLI: ELB + ASG + User-Data Demo

    This initialization has to be done only once, but can be run as often as desired.

    Procedure: [demo-10-initialize-cli-elb-asg-user-data.md](docs/demo-10-initialize-cli-elb-asg-user-data.md)

    Script: [demo-10-initialize-cli-elb-asg-user-data.sh](bin/demo-10-initialize-cli-elb-asg-user-data.sh)

    ```bash
    cd ~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data/bin

    ./demo-10-initialize-cli-elb-asg-user-data.sh
    ```

### Run CLI: ELB + ASG + User-Data Demo

These are steps needed to run this demo, assuming baseline and demo-specific initialization
has been done.

1. Run the CLI: ELB + ASG + User-Data Demo

    **This is likely to be the only "live" portion of the demo.**

    There are three variants of this procedure which perform identical actions, using
    the GUI, Euca2ools or AWSCLI, with the latter two also implemented as bash scripts. While
    it's possible to use the script methods to run the live demo, it's likely to be a better
    experience for all but a very technical audience to use the GUI.

    **Choose only one of these methods.**

    GUI Procedure: [demo-10-run-cli-elb-asg-user-data-gui.md](docs/demo-10-run-cli-elb-asg-user-data-gui.md)

    Euca2ools Procedure: [demo-10-run-cli-elb-asg-user-data-cli.md](docs/demo-10-run-cli-elb-asg-user-data-cli.md)

    Euca2ools Script: [demo-10-run-cli-elb-asg-user-data.sh](bin/demo-10-run-cli-elb-asg-user-data.sh)

    ```bash
    ./demo-10-run-cfn-wordpress.sh
    ```

    AWSCLI Procedure: [demo-10-run-cli-elb-asg-user-data-awscli.md](docs/demo-10-run-cli-elb-asg-user-data-awscli.md)

    AWSCLI Script: [demo-10-run-cli-elb-asg-user-data-awscli.sh](bin/demo-10-run-cli-elb-asg-user-data-awscli.sh)

    ```bash
    ./demo-10-run-cli-elb-asg-user-data-awscli.sh
    ```

### Reset CLI: ELB + ASG + User-Data Demo

These are steps needed to reset this demo, assuming it has been run successfully or unsuccessfully
one or more times. It's not necessary to re-run this demo's initialization script after a reset.

1. Reset the CLI: ELB + ASG + User-Data Demo

    Procedure: [demo-10-reset-cli-elb-asg-user-data.md](docs/demo-10-reset-cli-elb-asg-user-data.md)

    Script: [demo-10-reset-cli-elb-asg-user-data.sh](bin/demo-10-reset-cli-elb-asg-user-data.sh)

    ```bash
    ./demo-10-reset-cli-elb-asg-user-data.sh
    ```

