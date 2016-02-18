# FastStart Install Procedure

This document describes the manual procedure to install Eucalyptus via the FastStart installer.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the **REGION**, and **mjc.prc.eucalyptus-systems.com** as the **DOMAIN**.
Note that this domain only resolves inside the HP Goleta network.

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
    export PUBLIC_IP_FIRST=10.104.45.1
    export PUBLIC_IP_LAST=10.104.45.126
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
    * Whats the first address of your available IP range?     ${PUBLIC_IP_FIRST}
    * Whats the last address of your available IP range?      ${PUBLIC_IP_LAST}
    * Install additional services? [Y/n]                       <enter>

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    bash <(curl -Ls hphelion.com/eucalyptus-install)
    ```

2. Convert FastStart Credentials to Demo Conventions

    This section splits the "localhost" Region configuration file created by FastStart into a convention
    which allows for multiple named Regions.

    We preserve the original "localhost" Region configuration file installed with Eucalyptus, so that we
    can restore this later once a specific Region is configured.

    ```bash
    cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save

    cat <<EOF > ~/.euca/global.ini
    ; Eucalyptus Global

    [global]
    default-region = localhost

    EOF

    sed -n -e "1i; Eucalyptus Region localhost\n" \
           -e "s/[0-9]*:admin/localhost-admin/" \
           -e "/^\[region/,/^\user =/p" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini

    sed -n -e "1i; Eucalyptus Region localhost\n" \
           -e "s/[0-9]*:admin/localhost-admin/" \
           -e "/^\[user/,/^account-id =/p" \
           -e "\$a\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini

    mkdir -p ~/.creds/localhost/eucalyptus/admin

    cat <<EOF > ~/.creds/localhost/eucalyptus/admin/iamrc
    AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)
    AWSSecretKey=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)
    EOF

    rm -f ~/.euca/faststart.ini
    ```

3. Display Euca2ools Configuration

    This is an example of the configuration which results from the split logic in the last step.

    * The localhost Region should be the default.
    * The localhost Region should be configured with FastStart xip.io DNS HTTP URLs.
    * The localhost Region should have the single Eucalyptus Administrator User.

    ~/.euca/global.ini
    ```bash
    ; Eucalyptus Global

    [global]
    default-region = localhost
    ```

    /etc/euca2ools/conf.d/localhost.ini
    ```bash
    ; Eucalyptus Region localhost

    [region localhost]
    autoscaling-url = http://autoscaling.10.104.10.74.xip.io:8773/
    bootstrap-url = http://bootstrap.10.104.10.74.xip.io:8773/
    cloudformation-url = http://cloudformation.10.104.10.74.xip.io:8773/
    ec2-url = http://ec2.10.104.10.74.xip.io:8773/
    elasticloadbalancing-url = http://elasticloadbalancing.10.104.10.74.xip.io:8773/
    iam-url = http://iam.10.104.10.74.xip.io:8773/
    monitoring-url = http://monitoring.10.104.10.74.xip.io:8773/
    properties-url = http://properties.10.104.10.74.xip.io:8773/
    reporting-url = http://reporting.10.104.10.74.xip.io:8773/
    s3-url = http://s3.10.104.10.74.xip.io:8773/
    sts-url = http://sts.10.104.10.74.xip.io:8773/
    user = localhost-admin
    ```

    ~/.euca/localhost.ini
    ```bash
    ; Eucalyptus Region localhost

    [user localhost-admin]
    key-id = AKIAATYHPHEMVRQ46T43
    secret-key = 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
    account-id = 000987072445
    ```
    
4. Confirm Eucalyptus Services

    ```bash
    euserv-describe-services --region localhost
    ```

5. Confirm Eucalyptus Public Addresses

    ```bash
    euca-describe-addresses verbose --region localhost
    ```

