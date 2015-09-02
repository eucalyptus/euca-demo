# Demo Initialization Scripts

These scripts will initialize a Eucalyptus Region or AWS Account so that it can run the demos
contained in this project. Simultaneously, it will initialize the host where they are run as
a Management Workstation.

In some cases below, there are two scripts, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each script for more details on what each does.

### Eucalyptus

These scripts should be run in order on the CLC to initialize the Eucalyptus Region.

This also initializes the root account to act as a Management Workstation.

The configuration can then be moved to other Management Workstations, even combined with
other Eucalyptus Region configuration for centralized management.

* (demo-00-initialize.sh)
* (demo-01-initialize-account.sh)
* (demo-02-initialize-account-administrator.sh)
* (demo-02-initialize-account-administrator-awscli.sh)
* (demo-03-initialize-account-dependencies.sh)
* (demo-03-initialize-account-dependencies-awscli.sh)

### AWS

These scripts should be run in order on the CLC to initialize an AWS Account which can be
used for Demos which show coordination with the Eucalyptus Region. These scripts should be
run after the Eucalyptus Demo initialization scripts.

This also initializes the root account to act as a Management Workstation.

The configuration can then be moved to other Management Workstations, even combined with
other Eucalyptus Region configuration for centralized management.

* (demo-01-initialize-aws-account.sh)
* (demo-02-initialize-aws-account-administrator.sh)
* (demo-02-initialize-aws-account-administrator-awscli.sh)
* (demo-03-initialize-aws-account-dependencies.sh)
* (demo-03-initialize-aws-account-dependencies-awscli.sh)

