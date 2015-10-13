# Demo 10: CLI: ELB + ASG + User-Data

These procedures will run a Demo which uses the CLI (Command-Line Interface)
to create a SecurityGroup, ElasticLoadBalancer, LaunchConfiguration, AutoScalingGroup,
ScalingPolicies, CloudWatch Alarms and Instances which use User-Data scripts for configuration.

There are multiple procedures below, identically named except for a suffix which indicates
what method is used to perform the procedure. These include the Eucalyptus Console (-gui),
the Euca2ools CLI (-cli) and the AWS CLI (-awscli). These procedures perform identical
steps using these different methods, showing how multiple AWS ecosystem tools can be used
interchangeably.

Manual procedures do not exist for demo initialization and reset. See the bin directory
for scripts which automate these stages of the demo process.

* [demo-10-run-cli-elb-asg-user-data-gui.md](./demo-10-run-cli-elb-asg-user-data-gui.md)
* [demo-10-run-cli-elb-asg-user-data-cli.md](./demo-10-run-cli-elb-asg-user-data-cli.md)
* [demo-10-run-cli-elb-asg-user-data-awscli.md](./demo-10-run-cli-elb-asg-user-data-awscli.md)

