# Demo 21: CloudFormation: ELB Scripts

These scripts will initialize, run or reset a Demo which uses CloudFormation to create a Security
Group, ELB and pair of Instances attached to the ELB.

In some cases below, there are two scripts, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each script for more details on what each does.

These scripts should be run on the CLC, or a management workstation which has had the relevant
credentials synchronized.

* [demo-21-initialize-cfn-elb.sh](./demo-21-initialize-cfn-elb.sh)
* [demo-21-run-cfn-elb.sh](./demo-21-run-cfn-elb.sh)
* [demo-21-run-cfn-elb-awscli.sh](./demo-21-run-cfn-elb-awscli.sh)
* [demo-21-reset-cfn-elb.sh](./demo-21-reset-cfn-elb.sh)

