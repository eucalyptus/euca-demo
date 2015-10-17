# Setup PRC Host

Quick instructions to setup a PRC host to easily run these demos.

### Initialize New Host

Within this project, the script ./installs/install-00-initialize/bin/install-00-initialize-host-root.sh
has been created to setup a new host, but a "chicken-and-egg problem" exists, where
we need to use another method of getting this script onto the host in question
before it can be run.

Here is one way, after logging in as root on a PRC host which has just been
kickstarted with the qa-centos6-x86_64-striped-drives profile:

```bash
mkdir ~/bin
cd ~/bin

wget https://raw.githubusercontent.com/eucalyptus/euca-demo/master/installs/install-00-initialize/bin/install-00-initialize-host-root.sh

chmod -R 0700 ~/bin

./install-00-initialize-host-root.sh

exit
```
    
This downloads the euca-demo repo to a standard location, so you can then reference
scripts and files.

Logout, then login - to pick up profile changes.

You can find the repo at /root/src/eucalyptus/euca-demo

### Changes to this project

If you need to edit and push changes back to GitHub, on CentOS 7, an attempt to push
will prompt for both your GitHub username and password, so no changes are necessary.

However, on CentOS 6, you will get a 403 Forbidden error, unless you run the following
statement (replacing $github_username):

```bash
git remote set-url origin https://$github_username@github.com/eucalyptus/euca-demo.git
```

### Configure Environment Variables

Each host which will run these demo scripts must have an environment configuration
file created for it, named after the host shortname.

Multi-host environments should have a single file containing configuration which
applies to all participating hosts, named after the host which will run the CLC,
with symlinks to this from other hosts in the configuration.

You can find examples of these files in ~/src/eucalyptus/euca-demo/installs/install-10-faststart/conf.

### Install Eucalyptus via Faststart

Note that for DNS to work, additional configuration must be done on the DNS server
used for the parent domain. If you are unable to do this, you can not run any of
the additional scripts which expect DNS delegation to be setup correctly.

You can run these scripts in this order to install Eucalyptus via Faststart, then
augment the faststart install with DNS, PKI (for SSL), reverse-proxy (exposes
API and Console via SSL on standard SSL port), standard ssh key for service images,
and awscli support. Note there are additional scripts in this directory which are
normally not needed.

```bash
cd ~/src/eucalyptus/euca-demo/installs/install-10-faststart/bin

./install-10-faststart-install.sh
./install-11-faststart-configure-dns.sh
./install-12-faststart-configure-pki.sh
./install-14-faststart-configure-proxy.sh
./install-16-faststart-configure-support.sh
./install-17-faststart-configure-awscli.sh
```

### Initialize Eucalyptus Faststart for use in Demo scripts

Once Eucalyptus has been installed by the Augmented Faststart method, or by a manual method
similar to those found in the ~/src/eucalyptus/euca-demo/installs/install-20-manual/docs
directory, you can run the following scripts to prepare the system for the demos which are
contained within the ~/src/eucalyptus/euca-demo/demos directory.

The demo-01-initialize-account.sh and demo-02-initialize-account-dependencies.sh scripts can
be run more than once (in tandem), passing the "-a account" and optionally "-p password"
flags to create additional demo accounts with more secure passwords.

```bash
cd ~/src/eucalyptus/euca-demo/demo/demo-00-initialize/bin

./demo-00-initialize.sh
./demo-01-initialize-account.sh
./demo-00-initialize-account-dependencies.sh
```

### Run Demos

Demos have been created within the ~/src/eucalyptus/euca-demo/demos directory. Where
possible, scripts and manual procedures have been created to run the demo via the Eucalyptus
CLI or AWS CLI tools, or via the Eucalyptus Console.

Demos as of this update can be found here:

```bash
cd ~/src/eucalyptus/euca-demo/demos/demo-10-cli-elb-asg-user-data
cd ~/src/eucalyptus/euca-demo/demos/demo-20-cfn-simple
cd ~/src/eucalyptus/euca-demo/demos/demo-21-cli-elb
cd ~/src/eucalyptus/euca-demo/demos/demo-30-cli-wordpress
```

### Run Cloud Administrator Course

A version of the Cloud Administrator Course as it existed in December 2014 was automated
via similar scripts as used in the demos section. These scripts are out of date and will
not run without some additional work as of this update, but can be found here:

```bash
cd ~/src/eucalyptus/euca-demo/courses/course-10-cloud-administrator/bin

./course-10-install.sh
./course-11-configure-networking.sh
./course-12-configure-dns.sh
./course-13-configure-ebs-storage.sh
./course-14-configure-object-storage.sh
./course-15-configure-iam.sh
./course-16-configure-tools.sh
./course-17-configure-console.sh
./course-18-configure-images.sh
./course-19-test-security.sh
./course-1A-test-permissions.sh
```

More to come later...

