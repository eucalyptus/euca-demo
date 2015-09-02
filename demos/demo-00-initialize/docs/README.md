# Demo Initialization Procedures

These procedures will initialize a Eucalyptus Region or AWS Account so that it can run the demos
contained in this project. Simultaneously, they will initialize the host where they are run as
a Management Workstation.

In some cases below, there are two procedures, identically named except for one with a "-awscli"
suffix. These perform identical steps, using either Eucatools or AWSCLI. One or the other
should be run, but not both.

See each procedure for more details on what each does.

### Eucalyptus

These procedures should be performed in order on the CLC to initialize the Eucalyptus Region.

This also initializes the root account to act as a Management Workstation.

The configuration can then be moved to other Management Workstations, even combined with
other Eucalyptus Region configuration for centralized management.

* [demo-00-initialize.md](./demo-00-initialize.md)
* [demo-01-initialize-account.md](./demo-01-initialize-account.md)
* [demo-02-initialize-account-administrator.md](./demo-02-initialize-account-administrator.md)
* [demo-02-initialize-account-administrator-awscli.md](./demo-02-initialize-account-administrator-awscli.md)
* [demo-03-initialize-account-dependencies.md](./demo-03-initialize-account-dependencies.md)
* [demo-03-initialize-account-dependencies-awscli.md](./demo-03-initialize-account-dependencies-awscli.md)

### AWS

These procedures should be performed in order on the CLC to initialize an AWS Account which can be
used for Demos which show coordination with the Eucalyptus Region. These procedures should be
performed after the Eucalyptus Demo initialization procedures.

This also initializes the root account to act as a Management Workstation.

The configuration can then be moved to other Management Workstations, even combined with
other Eucalyptus Region configuration for centralized management.

* [demo-01-initialize-aws-account.md](./demo-01-initialize-aws-account.md)
* [demo-02-initialize-aws-account-administrator.md](./demo-02-initialize-aws-account-administrator.md)
* [demo-02-initialize-aws-account-administrator-awscli.md](./demo-02-initialize-aws-account-administrator-awscli.md)
* [demo-03-initialize-aws-account-dependencies.md](./demo-03-initialize-aws-account-dependencies.md)
* [demo-03-initialize-aws-account-dependencies-awscli.md](./demo-03-initialize-aws-account-dependencies-awscli.md)

