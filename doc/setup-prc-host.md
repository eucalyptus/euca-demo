Setup PRC Host
==============

Quick instructions to setup a PRC host to easily run these demos.

Initialize New Host
-------------------
There's a script named ./bin/user-initialize-prc-host.sh which does this, but a
chicken-and-egg problem of getting this onto the host in question so that you
can run it.

Here's one way, after logging in as root on a PRC host which has just been
kickstarted with the qa-centos6-x86_64-striped-drives profile:

    mkdir ~/bin
    cd ~/bin
    wget https://raw.githubusercontent.com/eucalyptus/euca-demo/master/bin/user-initialize-prc-host.sh
    chmod -R 0700 ~/bin
    ./user-initialize-prc-host.sh
    
This downloads the euca-demo repo to a standard location, then adjusts root's PATH
to include the demo scripts. Logout, then login, to pick up profile changes.

You can find the repo at /root/src/eucalyptus/euca-demo

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

    euca-faststart-01-install.sh
    euca-faststart-02-configure-cloudformation.sh
    euca-faststart-03-configure-dns.sh  # not yet working

Initialize Eucalyptus Faststart for use in Demo scripts
-------------------------------------------------------

    euca-demo-01-initialize.sh

Run Demos
---------

    euca-demo-05-test-elb-asg-user-data.sh
    euca-demo-11-test-cloud-formation-simple.sh
    euca-demo-12-test-cloud-formation-elb.sh

More to come later...

Also see scripts to replicate Cloud Administrator Course, mostly complete as of this writing.

