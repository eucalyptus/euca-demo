# Demo 30: CloudFormation: WordPress Scripts

These scripts will initialize, run or reset a Demo which uses CloudFormation to create a WordPress
installation first in an AWS Account, then a Eucalyptus Demo Account, then migrate content from
AWS to Eucalyptus, as an example of Workload Repatriation.

In some cases below, there are two scripts, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each script for more details on what each does.

These scripts should be run on the CLC with the "-m e" or "-m b" option to affect
the Eucalyptus Account.

These scripts should be run on the CLC with the "-m a" or "-m b" option to affect 
the AWS Account.

* [demo-30-initialize-cfn-wordpress.sh](./demo-30-initialize-cfn-wordpress.sh)
* [demo-30-run-cfn-wordpress.sh](./demo-30-run-cfn-wordpress.sh)
* [demo-30-run-cfn-wordpress-awscli.sh](./demo-30-run-cfn-wordpress-awscli.sh)
* [demo-30-migrate.sh](./demo-30-migrate.sh)
* [demo-30-reset-cfn-wordpress.sh](./demo-30-reset-cfn-wordpress.sh)

