# FastStart Install Procedure

This document describes the manual procedure to install Eucalyptus via the FastStart installer.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the AWS_DEFAULT_REGION, and **mjc.prc.eucalyptus-systems.com** as the
AWS_DEFAULT_DOMAIN. Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16

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

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com

    export EUCA_DNS_INSTANCE_SUBDOMAIN=.cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb

    export EUCA_PUBLIC_IP_RANGE=10.104.45.1-10.104.45.126
    ```

### Install Eucalyptus via Faststart

1. Run Faststart

    When prompted, use these answers:

    * Laptop power warning: Continue?                          <enter>
    * DHCP warning: Continue Anyway?                           y
    * Whats the NTP server which we will update time from?    <enter>
    * Whats the physical NIC that will be used for bridging?  <enter>
    * Whats the IP address of this host?                      <enter>
    * Whats the gateway for this host?                        <enter>
    * Whats the netmask for this host?                        <enter>
    * Whats the subnet for this host?                         <enter>
    * Whats the first address of your available IP range?     ${EUCA_PUBLIC_IP_RANGE%-*} (first IP address)
    * Whats the last address of your available IP range?      ${EUCA_PUBLIC_IP_RANGE#*-} (last IP address)
    * Install additional services? [Y/n]                       <enter>

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    bash <(curl -Ls eucalyptus.com/install)
    ```

2. Move Credentials into Demo Directory Structure

    We need to create additional accounts and users on this host, and also need to consolidate
    credentials from multiple regions onto a single management host in some environments, so
    move the Eucalyptus Administrator credentials into a more hierarchical credentials storage
    directory structure which supports these needs.

    Logic below also tests for a common problem and fixes it if found.

    Logic below also handles the case where additional credentials downloads do not include the
    pk/cert from the original download, and have a warning in the eucarc to this effect. We 
    preserve the original files and re-add them the the eucarc.

    ```bash
    if ! grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> ~/.bash_profile
    fi
    if ! grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
        echo "export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin" >> ~/.bash_profile
    fi

    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
 
    cp -a ~/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip \
           -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    if grep -s -q "echo WARN:  CloudFormation service URL is not configured" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        sed -i -r -e "/echo WARN:  CloudFormation service URL is not configured/d" \
                  -e "s/(^export )(AWS_AUTO_SCALING_URL)(.*\/services\/)(AutoScaling$)/\1\2\3\4\n\1AWS_CLOUDFORMATION_URL\3CloudFormation/" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

3. Confirm Public IP addresses

    Simple test to confirm Eucalyptus is working.

    ```bash
    euca-describe-addresses verbose
    ```

4. Confirm service status

    Truncate normal long output for readability

    ```bash
    euca-describe-services | cut -f1-5
    ```

