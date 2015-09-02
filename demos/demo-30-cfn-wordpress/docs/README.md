# Demo 30: CloudFormation: WordPress Procedures

These procedures will initialize, run or reset a Demo which uses CloudFormation to create a
WordPress installation first in an AWS Account, hten a Eucalyptus Demo Account, then migrate
content from AWS to Eucalyptus, as an example of Workload Repatriation.

In some cases below, there are two procedures, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each procedure for more details on what each does.

These procedures only document the run portion of this demo with steps implemented in the
Eucalyptus Console (gui), Euca2ools CLI (cli) or AWS CLI (awscli). Prior to running these
procedures the appropriate Accounts must be initialized via the appropriate initialize
scripts.

* [demo-30-run-cfn-wordpress-gui.md](./demo-30-run-cfn-wordpress-gui.md)
* [demo-30-run-cfn-wordpress-gui-short.md](./demo-30-run-cfn-wordpress-gui-short.md)
* [demo-30-run-cfn-wordpress-cli.md](./demo-30-run-cfn-wordpress-cli.md)
* [demo-30-run-cfn-wordpress-awscli.md](./demo-30-run-cfn-wordpress-awscli.md)

