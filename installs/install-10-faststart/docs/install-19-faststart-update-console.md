# FastStart Install: Update Console Procedure

This document describes the manual procedure to update the Console to a later unreleased version,
after Eucalyptus has been installed via the FastStart installer. This is a temporary procedure
needed to demo the latest console with most 4.2 changes and new HP branding, as these are needed
in many demos.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the AWS_DEFAULT_REGION, and **mjc.prc.eucalyptus-systems.com** as the
AWS_DEFAULT_DOMAIN. Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16
  - Private: 10.105.10.74/16 (Unused with FastStart)

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    These instructions were based on a Faststart Install performed within the PRC on host
    odc-f-32.prc.eucalyptus-systems.com, configured as region hp-gol01-f1, using MCrawfords
    DNS server. Adjust the variables in this section to your environment.

    This is where you can update the EUCACONSOLE_URL to specify later versions of the updated
    RPM until the need for this script goes away.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com

    export EUCA_DNS_INSTANCE_SUBDOMAIN=.cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb

    export EUCA_PUBLIC_IP_RANGE=10.104.45.1-10.104.45.126

    export EUCACONSOLE_URL="http://packages.release.eucalyptus-systems.com/yum/tags/eucalyptus-devel/rhel/6/x86_64/eucaconsole-4.1.1-0.0.6723.435.20150702git397e9ed.el6.noarch.rpm"
    ```

### Update Eucalyptus Console

1. Use Eucalyptus Administrator credentials

    Eucalyptus Administrator credentials should have been moved from the default location
    where they are downloaded to the hierarchical directory structure used for all demos,
    in the location shown below, as part of the prior faststart manual install procedure.

    ```bash
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Stop Eucalyptus Console service and preserve configuration

    ```bash
    service eucaconsole stop

    mv /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.$(date +%Y%m%d-%H%M).bak
    ```

3. Install Newer Eucalyptus Console

    ```bash
    yum install -y $EUCACONSOLE_URL
    ```

4. Configure Eucalyptus Console Configuration file

    Using sed to automate editing of changes, then displaying changes made.

    ```bash
    sed -i -e "/^ufshost = localhost$/s/localhost/$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/" \
           -e "/^#cloudformation.samples.bucket =/s/^#//" \
           -e "/^session.secure =/s/= .*$/= true/" \
           -e "/^session.secure/a\
    sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\
    sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key" /etc/eucaconsole/console.ini

    more /etc/eucaconsole/console.ini
    ```

5. Start Eucalyptus Console service

    Confirm updated Eucalyptus Console is running via a browser:
    https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/

    ```bash
    chkconfig eucaconsole on

    service eucaconsole start
    ```

