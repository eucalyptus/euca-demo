# FastStart Install: Configure DNS Procedure

This document describes the manual procedure to configure DNS, after Eucalyptus has been installed
via the FastStart installer.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the AWS_DEFAULT_REGION, and **mjc.prc.eucalyptus-systems.com** as the
AWS_DEFAULT_DOMAIN. Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16
  - Private: 10.105.10.74/16 (Unused with FastStart)

Additionally, this relies on a parent DNS server, also in a host in the HP Goleta server room:
- odc-f-38.prc.eucalyptus-systems.com: DNS Parent
  - Public: 10.104.10.80/16

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

### Initialize External DNS

I will not describe this in detail here, except to note that this must be in place and working
properly before registering services with the method outlined below, as I will be using DNS names
for the services so they look more AWS-like.

Confirm external DNS is configured properly with the statements below, which should match the
results which follow the dig command. This document shows the actual results based on variables
set above at the time this document was written, for ease of confirming results. If the variables
above are changed, expected results below should also be updated to match.

**A Records**

```bash
dig +short ${AWS_DEFAULT_DOMAIN}
10.104.10.80

dig +short ns1.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.74

dig +short clc.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.74

dig +short ufs.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.74

dig +short console.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.74
```

**NS Records**

```bash
dig +short -t NS ${AWS_DEFAULT_DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.

dig +short -t NS ${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.
```

**MX records**

Note: Mail was not completely setup on the initial installation, as there is no mail relay
currently in place in the EBC.

```bash
dig +short -t MX ${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
smtp.mjc.prc.eucalyptus-systems.com.
```

### Configure Eucalyptus DNS

1. Use Eucalyptus Administrator credentials

    Eucalyptus Administrator credentials should have been moved from the default location
    where they are downloaded to the hierarchical directory structure used for all demos,
    in the location shown below, as part of the prior faststart manual install procedure.

    ```bash
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Configure Eucalyptus DNS Server

    Instances will use the Cloud Controller DNS Server directly

    ```bash
    euca-modify-property -p system.dns.nameserver=ns1.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    euca-modify-property -p system.dns.nameserveraddress=$(hostname -i)
    ```

3. Configure DNS Timeout and TTL

    Optional step, to show how these values can be adjusted if needed.

    ```bash
    euca-modify-property -p dns.tcp.timeout_seconds=30

    euca-modify-property -p services.loadbalancing.dns_ttl=15
    ```

4. Configure DNS Domain

    ```bash
    euca-modify-property -p system.dns.dnsdomain=$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    ```

5. Configure DNS Sub-Domains

    ```bash
    euca-modify-property -p cloud.vmstate.instance_subdomain=$EUCA_DNS_INSTANCE_SUBDOMAIN

    euca-modify-property -p services.loadbalancing.dns_subdomain=$EUCA_DNS_LOADBALANCER_SUBDOMAIN
    ```

6. Enable DNS

    ```bash
    euca-modify-property -p bootstrap.webservices.use_instance_dns=true

    euca-modify-property -p bootstrap.webservices.use_dns_delegation=true
    ```

7. Configure CloudFormation Region

    Technically, this is not purely related to DNS and does not belong here. But, we need to make
    sure this is run, and this is somewhat related to DNS, so this is the best location to run
    this.

    ```bash
    euca-modify-property -p cloudformation.region=$AWS_DEFAULT_REGION
    ```

8. Refresh Administrator Credentials

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
        sed -i -e "/WARN: Certificate credentials not present./d" \
               -e "/WARN: Review authentication.credential_download_generate_certificate and/d" \
               -e "/WARN: authentication.signing_certificates_limit properties for current/d" \
               -e "/WARN: certificate download limits./d" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi

    if [ -r /root/eucarc ]; then
        cp -a ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc /root/eucarc
    fi

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

9. Display Parent DNS Server Configuration

    This is an example of the changes which need to be made on the parent DNS server which will
    delegate DNS to Eucalyptus for Eucalyptus DNS names used for instances, ELBs and services.

    You should make these changes, adjusted for your environment, on the parent DNS server,
    once. You should then be able to re-install configured regions as needed without having
    to repeat these changes.

    To avoid ambiguity, the files below are verbatim for the hp-gol01-f1 region.

    Add these lines to /etc/named.conf on the parent DNS server"

    ```bash
           zone "hp-gol01-f1.mjc.prc.eucalyptus-systemc.com" IN
           {
                   type master;
                   file "/etc/named/db.hp-gol01-f1";
           };
    ```

    Create the zone file on the parent DNS server

    ```bash
    ;
    ; DNS zone for hp-gol01-f1.mjc.prc.eucalyptus-systems.com
    ;
    $TTL 1M
    $ORIGIN hp-gol01-f1.mjc.prc.eucalyptus-systems.com.
    @                       SOA     ns1 root (
                                    2015042101      ; Serial
                                    1H              ; Refresh
                                    10M             ; Retry
                                    1D              ; Expire
                                    1H )            ; Negative Cache TTL

                            NS      ns1

    ns1                     A       10.104.10.74

    clc                     A       10.104.10.74
    ufs                     A       10.104.10.74
    mc                      A       10.104.10.74
    osp                     A       10.104.10.74
    walrus                  A       10.104.10.74
    cc                      A       10.104.10.74
    sc                      A       10.104.10.74
    ns1                     A       10.104.10.74

    console                 A       10.104.10.74
    autoscaling             A       10.104.10.74
    cloudformation          A       10.104.10.74
    cloudwatch              A       10.104.10.74
    compute                 A       10.104.10.74
    euare                   A       10.104.10.74
    loadbalancing           A       10.104.10.74
    objectstorage           A       10.104.10.74
    tokens                  A       10.104.10.74

    cloud                   NS      ns1
    lb                      NS      ns1
    ```

10. Confirm DNS resolution for Services

    Confirm new DNS-based service URLs in refreshed eucarc resolve

    ```bash
    dig +short compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    dig +short loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    ```

11. Confirm API commands work with new URLs

    Confirm service describe commands still work

    ```bash
    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-images

    euca-describe-instance-types

    euca-describe-instances

    euca-describe-instance-status

    euca-describe-groups

    euca-describe-volumes

    euca-describe-snapshots

    eulb-describe-lbs

    euform-describe-stacks

    euscale-describe-auto-scaling-groups

    euscale-describe-launch-configs

    euscale-describe-auto-scaling-instances

    euscale-describe-policies

    euwatch-describe-alarms
    ```

