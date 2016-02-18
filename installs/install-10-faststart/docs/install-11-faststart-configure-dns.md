# FastStart Install: Configure DNS Procedure

This document describes the manual procedure to configure DNS, after Eucalyptus has been installed
via the FastStart installer.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the **REGION**, and **mjc.prc.eucalyptus-systems.com** as the **DOMAIN**.
Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16

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
    export DOMAIN=mjc.prc.eucalyptus-systems.com
    export REGION=hp-gol01-f1

    export INSTANCE_SUBDOMAIN=.vm
    export LOADBALANCER_SUBDOMAIN=lb
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
dig +short ${DOMAIN}
10.104.10.80

dig +short clc.${REGION}.${DOMAIN}
10.104.10.74

dig +short ufs.${REGION}.${DOMAIN}
10.104.10.74

dig +short console.${REGION}.${DOMAIN}
10.104.10.74
```

**NS Records**

```bash
dig +short -t NS ${DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.

dig +short -t NS ${REGION}.${DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.
```

### Configure Eucalyptus DNS

1. Configure Region

    FastStart creates a "localhost" Region by default. We will switch this to a more "AWS-like" Region
    naming convention. This is needed to run CloudFormation templates which reference the Region in Maps.

    ```bash
    euctl region.region_name=${REGION} --region localhost
    ```

2. Configure Eucalyptus DNS Server

    Instances will use the Cloud Controller DNS Server directly

    ```bash
    euctl system.dns.nameserver=ufs.${REGION}.${DOMAIN} --region localhost

    euctl system.dns.nameserveraddress=$(hostname -i) --region localhost
    ```

3. Configure DNS Timeout and TTL

    Optional step, to show how these values can be adjusted if needed.

    ```bash
    euctl dns.tcp.timeout_seconds=30 --region localhost

    euctl services.loadbalancing.dns_ttl=15 --region localhost
    ```

4. Configure DNS Domain

    ```bash
    euctl system.dns.dnsdomain=${REGION}.${DOMAIN} --region localhost
    ```

5. Configure DNS Sub-Domains

    ```bash
    euctl cloud.vmstate.instance_subdomain=${INSTANCE_SUBDOMAIN} --region localhost

    euctl services.loadbalancing.dns_subdomain=${LOADBALANCER_SUBDOMAIN} --region localhost
    ```

6. Enable DNS

    ```bash
    euctl bootstrap.webservices.use_instance_dns=true --region localhost

    euctl bootstrap.webservices.use_dns_delegation=true --region localhost
    ```

7. Configure Euca2ools Region with HTTP Endpoints

    We must configure a new Region configuration, but can re-use the User configuration with a
    change to the Region name.

    We restore the original "localhost" Region saved in a prior step, as the modified "localhost"
    Region created by FastStart no longer works after changing DNS properties.

    ```bash
    mv /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.faststart
    mv /etc/euca2ools/conf.d/localhost.ini.save /etc/euca2ools/conf.d/localhost.ini
    sed -i -e '/^user =/d;/^sts-url =/auser = localhost-admin' /etc/euca2ools/conf.d/localhost.ini

    sed -i -e "s/localhost/${REGION}/g" ~/.euca/global.ini

    cat << EOF > /etc/euca2ools/conf.d/${REGION}.ini
    ; Eucalyptus Region ${REGION}

    [region ${REGION}]
    autoscaling-url = http://autoscaling.${REGION}.${DOMAIN}:8773/
    bootstrap-url = http://bootstrap.${REGION}.${DOMAIN}:8773/
    cloudformation-url = http://cloudformation.${REGION}.${DOMAIN}:8773/
    ec2-url = http://ec2.${REGION}.${DOMAIN}:8773/
    elasticloadbalancing-url = http://elasticloadbalancing.${REGION}.${DOMAIN}:8773/
    iam-url = http://iam.${REGION}.${DOMAIN}:8773/
    monitoring-url = http://monitoring.${REGION}.${DOMAIN}:8773/
    properties-url = http://properties.${REGION}.${DOMAIN}:8773/
    reporting-url = http://reporting.${REGION}.${DOMAIN}:8773/
    s3-url = http://s3.${REGION}.${DOMAIN}:8773/
    sts-url = http://sts.${REGION}.${DOMAIN}:8773/
    user = ${REGION}-admin
    EOF

    sed -e "s/localhost/${REGION}/g" ~/.euca/localhost.ini > ~/.euca/${REGION}.ini

    mkdir -p ~/.creds/${REGION}/eucalyptus/admin
    cp -a ~/.creds/localhost/eucalyptus/admin/iamrc ~/.creds/${REGION}/eucalyptus/admin
    ```

8. Display Euca2ools Configuration

    This is an example of the configuration which should result from the logic in the last step.

    * The ${REGION} Region should now be the default.
    * The ${REGION} Region should be configured with Custom DNS HTTP URLs. It can be used from
      other hosts.
    * The localhost Region should again be configured with the default direct URLs. It can only
      be used from the FastStart host.
    * The ${REGION} and localhost Regions should each have the same single Eucalyptus Administrator
      User.

    ~/.euca/global.ini
    ```bash
    ; Eucalyptus Global

    [global]
    default-region = ${REGION}
    ```

    /etc/euca2ools/conf.d/${REGION}.ini
    ```bash
    ; Eucalyptus Region ${REGION}

    [region ${REGION}]
    autoscaling-url = http://autoscaling.${REGION}.${DOMAIN}:8773/
    bootstrap-url = http://bootstrap.${REGION}.${DOMAIN}:8773/
    cloudformation-url = http://cloudformation.${REGION}.${DOMAIN}:8773/
    ec2-url = http://ec2.${REGION}.${DOMAIN}:8773/
    elasticloadbalancing-url = http://elasticloadbalancing.${REGION}.${DOMAIN}:8773/
    iam-url = http://iam.${REGION}.${DOMAIN}:8773/
    monitoring-url = http://monitoring.${REGION}.${DOMAIN}:8773/
    properties-url = http://properties.${REGION}.${DOMAIN}:8773/
    reporting-url = http://reporting.${REGION}.${DOMAIN}:8773/
    s3-url = http://s3.${REGION}.${DOMAIN}:8773/
    sts-url = http://sts.${REGION}.${DOMAIN}:8773/
    user = ${REGION}-admin
    ```

    /etc/euca2ools/conf.d/localhost.ini
    ```bash
    ; Eucalyptus (all user services on localhost)

    [region localhost]
    autoscaling-url = http://127.0.0.1:8773/services/AutoScaling/
    cloudformation-url = http://127.0.0.1:8773/services/CloudFormation/
    ec2-url = http://127.0.0.1:8773/services/compute/
    elasticloadbalancing-url = http://127.0.0.1:8773/services/LoadBalancing/
    iam-url = http://127.0.0.1:8773/services/Euare/
    monitoring-url = http://127.0.0.1:8773/services/CloudWatch/
    s3-url = http://127.0.0.1:8773/services/objectstorage/
    sts-url = http://127.0.0.1:8773/services/Tokens/
    user = localhost-admin

    bootstrap-url = http://127.0.0.1:8773/services/Empyrean/
    properties-url = http://127.0.0.1:8773/services/Properties/
    reporting-url = http://127.0.0.1:8773/services/Reporting/

    certificate = /var/lib/eucalyptus/keys/cloud-cert.pem
    ```

    ~/.euca/${REGION}.ini
    ```bash
    ; Eucalyptus Region ${REGION}

    [user ${REGION}-admin]
    key-id = AKIAATYHPHEMVRQ46T43
    secret-key = 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
    account-id = 000987072445
    ```

    ~/.euca/localhost.ini
    ```bash
    ; Eucalyptus Region localhost

    [user localhost-admin]
    key-id = AKIAATYHPHEMVRQ46T43
    secret-key = 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
    account-id = 000987072445
    ```

9. Confirm DNS resolution for Services

    Confirm service URLS in euca2ools Region configuration resolve to the IP address of the
    FastStart Host.

    ```bash
    dig +short autoscaling.${REGION}.${DOMAIN}

    dig +short bootstrap.${REGION}.${DOMAIN}

    dig +short cloudformation.${REGION}.${DOMAIN}

    dig +short ec2.${REGION}.${DOMAIN}

    dig +short elasticloadbalancing.${REGION}.${DOMAIN}

    dig +short iam.${REGION}.${DOMAIN}

    dig +short monitoring.${REGION}.${DOMAIN}

    dig +short properties.${REGION}.${DOMAIN}

    dig +short reporting.${REGION}.${DOMAIN}

    dig +short s3.${REGION}.${DOMAIN}

    dig +short sts.${REGION}.${DOMAIN}
    ```

10. Confirm API commands work with new URLs

    Confirm service describe commands still work

    ```bash
    euca-describe-regions --region localhost

    euca-describe-regions --region ${REGION}-admin@${REGION}

    euca-describe-availability-zones verbose --region ${REGION}-admin@${REGION}

    euca-describe-keypairs --region ${REGION}-admin@${REGION}

    euca-describe-images --region ${REGION}-admin@${REGION}

    euca-describe-instance-types --region ${REGION}-admin@${REGION}

    euca-describe-instances --region ${REGION}-admin@${REGION}

    euca-describe-instance-status --region ${REGION}-admin@${REGION}

    euca-describe-groups --region ${REGION}-admin@${REGION}

    euca-describe-volumes --region ${REGION}-admin@${REGION}

    euca-describe-snapshots --region ${REGION}-admin@${REGION}

    eulb-describe-lbs --region ${REGION}-admin@${REGION}

    euform-describe-stacks --region ${REGION}-admin@${REGION}

    euscale-describe-auto-scaling-groups --region ${REGION}-admin@${REGION}

    euscale-describe-launch-configs --region ${REGION}-admin@${REGION}

    euscale-describe-auto-scaling-instances --region ${REGION}-admin@${REGION}

    euscale-describe-policies --region ${REGION}-admin@${REGION}

    euwatch-describe-alarms --region ${REGION}-admin@${REGION}
    ```

12. Configure Bash to use Eucalyptus Administrator Credentials by default

    While it is possible to use the "--region USER@REGION" parameter as shown above with Euca2ools
    to explicitly specify the User and Region, this adds a lot of typing.

    While Euca2ools accepts a "USER@REGION" value in the AWS_DEFAULT_REGION environment variable
    to avoid having to pass these values on every command, this breaks AWSCLI which cannot handle
    this extension to the variable format.

    By setting the variables defined below, both Euca2ools and AWSCLI can be used interchangably.

    Add these lines to your ~/.bash_profile:
    ```bash 
    export AWS_DEFAULT_REGION=${REGION}
    export AWS_DEFAULT_PROFILE=$AWS_DEFAULT_REGION-admin
    export AWS_CREDENTIAL_FILE=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    ```

13. Display Parent DNS Server Configuration

    This is an example of the changes which need to be made on the parent DNS server which will
    delegate DNS to Eucalyptus for Eucalyptus DNS names used for instances, ELBs and services.

    You should make these changes, adjusted for your environment, on the parent DNS server,
    once. You should then be able to re-install configured regions as needed without having
    to repeat these changes.

    To avoid ambiguity, unlike other examples on this page which reference ${REGION} and ${DOMAIN},
    the exammples below are verbatim for the hp-gol01-f1 region.

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
    $TTL 1H
    $ORIGIN hp-gol01-f1.mjc.prc.eucalyptus-systems.com.
    @                       SOA     ns1 root (
                                    2016011801      ; Serial
                                    1H              ; Refresh
                                    10M             ; Retry
                                    1D              ; Expire
                                    1H )            ; Negative Cache TTL

                            NS      ufs

    clc                     A       10.104.10.74
    ufs                     A       10.104.10.74
    mc                      CNAME   ufs
    osp                     A       10.104.10.74
    walrus                  CNAME   osp
    cca                     A       10.104.10.74
    cc                      CNAME   cca
    sca                     A       10.104.10.74
    sc                      CNAME   sca
    ns1                     A       10.104.10.74

    console                 A       10.104.10.74

    autoscaling             A       10.104.10.74
    bootstrap               A       10.104.10.74
    cloudformation          A       10.104.10.74
    ec2                     A       10.104.10.74
    compute                 CNAME   ec2
    elasticloadbalancing    A       10.104.10.74
    loadbalancing           CNAME   elasticloadbalancing
    iam                     A       10.104.10.74
    euare                   CNAME   iam
    monitoring              A       10.104.10.74
    cloudwatch              CNAME   monitoring
    properties              A       10.104.10.74
    reporting               A       10.104.10.74
    s3                      A       10.104.10.74
    objectstorage           CNAME   s3
    sts                     A       10.104.10.74
    tokens                  CNAME   sts

    cloud                   NS      ufs
    lb                      NS      ufs
    ```

