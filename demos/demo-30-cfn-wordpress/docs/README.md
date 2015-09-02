# Demo 30: CloudFormation: WordPress Procedures

These procedures will run a Demo which uses CloudFormation to create a WordPress installation
first in an AWS Account, then a Eucalyptus Demo Account, then migrate content from AWS to
Eucalyptus, as an example of Workload Repatriation.

There are multiple procedures below, identically named except for a suffix which indicates
what method is used to perform the procedure. These include the Eucalyptus Console (-gui and
-gui-short), the Euca2ools CLI (-cli) and the AWS CLI (-awscli). These steps perform identical
steps using these different methods, showing how multiple AWS ecosystem tools can be used
interchangeably.

The procedure identified with the -short suffix performs a subset of the actions, and is
intended to be used when the AWS account is setup in advance, with no optional steps shown.
It should probably used for most high-level audiences.

Manual procedures do not exist for demo initialization and reset. See the bin directory
for scripts which automate these stages of the demo process.

* [demo-30-run-cfn-wordpress-gui.md](./demo-30-run-cfn-wordpress-gui.md)
* [demo-30-run-cfn-wordpress-gui-short.md](./demo-30-run-cfn-wordpress-gui-short.md)
* [demo-30-run-cfn-wordpress-cli.md](./demo-30-run-cfn-wordpress-cli.md)
* [demo-30-run-cfn-wordpress-awscli.md](./demo-30-run-cfn-wordpress-awscli.md)

