Setup PRC Host
==============

Quick instructions to setup a PRC host to easily run these demos.

Initialize New Host
-------------------
There is a script named ./bin/user-initialize-prc-host.sh which does this, but a
chicken-and-egg problem of getting this onto the host in question so that you
can run it.

Here is one way, after logging in as root on a PRC host which has just been
kickstarted with the qa-centos6-x86_64-striped-drives profile:

    mkdir ~/bin
    cd ~/bin
    wget https://raw.githubusercontent.com/eucalyptus/euca-demo/master/bin/user-initialize-prc-host.sh
    chmod -R 0700 ~/bin
    ./user-initialize-prc-host.sh
    exit
    
This downloads the euca-demo repo to a standard location, then adjusts the root PATH
to include the demo scripts.

Logout, then login - to pick up profile changes.

You can find the repo at /root/src/eucalyptus/euca-demo

Changes to this project
-----------------------
If you need to edit and push changes back to GitHub, on CentOS 7, an attempt to push
will prompt for both your GitHub username and password, so no changes are necessary.

However, on CentOS 6, you will get a 403 Forbidden error, unless you run the following
statement (replacing $github_username):

    git remote set-url origin https://$github_username@github.com/eucalyptus/euca-demo.git

Configure Environment Variables
-------------------------------
Each host which will run these demo scripts must have an environment configuration
file created for it, named after the host shortname.

Multi-host environments should have a single file containing configuration which
applies to all participating hosts, named after the host which will run the CLC,
with symlinks to this from other hosts in the configuration.

You can check if an environment configuration file has been created for your
host by running:

    source euca-env-initialize.sh -I

Install Eucalyptus via Faststart
--------------------------------
Note that for DNS to work, additional configuration must be done on the DNS server
used for the cs.prc.eucalyptus-systems.com domain. If you are unable to do this,
either skip this step, or modify this script for your alternate DNS server, or running
this script will break the remaining script due to partial DNS configuration.

    euca-faststart-01-install.sh
    euca-faststart-02-configure-cloudformation.sh
    euca-faststart-03-configure-dns.sh

Initialize Eucalyptus Faststart for use in Demo scripts
-------------------------------------------------------

    euca-demo-01-initialize-account.sh
    euca-demo-02-initialize-dependencies.sh

Run Demos
---------

    euca-demo-05-test-elb-asg-user-data.sh
    euca-demo-11-test-cloud-formation-simple.sh
    euca-demo-12-test-cloud-formation-elb.sh

Run Cloud Administrator Course
------------------------------
    euca-course-01-initialize-dependencies.sh
    euca-course-02-install.sh
    euca-course-03-configure-networking.sh
    euca-course-04-configure-ebs-storage.sh
    euca-course-05-configure-object-storage.sh
    euca-course-06-configure-iam.sh
    euca-course-07-configure-tools.sh
    euca-course-08-configure-console.sh
    euca-course-09-configure-images.sh
    euca-course-10-test-security.sh
    euca-course-11-test-permissions.sh

More to come later...

