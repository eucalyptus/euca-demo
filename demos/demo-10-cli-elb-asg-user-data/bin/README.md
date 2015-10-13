# Demo 10: CLI: ELB + ASG + User-Data

These scripts will initialize, run or reset a Demo which uses the CLI (Command-Line Interface)
to create a SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup,
ScalingPolicies, CloudWatch Alarms and Instances which use User-Data scripts for configuration.

In some cases below, there are two scripts, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each script for more details on what each does.

These scripts should be run on the CLC, or a management workstation which has had the relevant
credentials synchronized.

* [demo-10-initialize-cli-elb-asg-user-data.sh](./demo-10-initialize-cli-elb-asg-user-data.sh)
* [demo-10-run-cli-elb-asg-user-data.sh](./demo-10-run-cli-elb-asg-user-data.sh)
* [demo-10-run-cli-elb-asg-user-data-awscli.sh](./demo-10-run-cli-elb-asg-user-data-awscli.sh)
* [demo-10-reset-cli-elb-asg-user-data.sh](./demo-10-reset-cli-elb-asg-user-data.sh)

