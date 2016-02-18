# FastStart Install: Configure UFS to use SSL
### This variant uses the Helion Eucalyptus Development PKI Infrastructure

This document describes the manual procedure to configure UFS to use SSL, after Eucalyptus has been
installed via the FastStart installer. This procedure is incompatible with the reverse-proxy script
on the same host, as both attempt to use port 443.

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
    export DOMAIN=mjc.prc.eucalyptus-systems.com
    export REGION=hp-gol01-f1
    ```

### Confirm Prerequisites

1. Confirm port 443 is open

    This procedure is incompatible with the reverse-proxy procedure, in that they both attempt to
    listen on port 443. This test confirms port 443 is open.

    ```bash
    if nc -z $(hostname) 443 &> /dev/null; then
        echo "A server program is running on port 443, which most often means the proxy script may have been run"
        echo "This script is incompatible with the proxy on the same host"
    fi
    ```

### Configure Eucalyptus UFS to use SSL

1. Create PKCS#12 Archive

    This archive format combines the Key and SSL Certificate in a single file.

    This is needed for configuration of SSL for Java Services.

    Specify a password to protect the key. This is used for the Eucalyptus SSL configuration as well.

    ```bash
    password=<password_to_protect_pkcs12>

    openssl pkcs12 -export -name ufs \
                   -inkey /etc/pki/tls/private/star.${REGION}.${DOMAIN}.key \
                   -in /etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt \
                   -out /var/tmp/ufs.p12 \
                   -password pass:$password

    chmod 400 /var/tmp/ufs.p12
    ```

2. Configure User-Facing Services to use SSL and HTTPS port

    Backup current Eucalyptus Keystore before modifications

    Import PKCS#12 Archive into Eucalyptus Keystore

    List contents of Eucalyptus Keystore (confirm ufs certificate exists)

    Configure Eucalyptus to use the new certificate after import

    Configure Eucalyptus to listen on standard HTTPS port

    Restart Eucalyptus-Cloud to pick up the changes

    ```bash
    cp -a /var/lib/eucalyptus/keys/euca.p12 /var/lib/eucalyptus/keys/euca-$(date +%Y%m%d-%H%M).p12

    keytool -importkeystore -alias ufs \
            -srckeystore /var/tmp/ufs.p12 -srcstoretype pkcs12 \
            -srcstorepass $password -srckeypass $password \
            -destkeystore /var/lib/eucalyptus/keys/euca.p12 -deststoretype pkcs12 \
            -deststorepass eucalyptus -destkeypass $password

    keytool -list \
            -keystore /var/lib/eucalyptus/keys/euca.p12 -storetype pkcs12 \
            -storepass eucalyptus

    euctl bootstrap.webservices.ssl.server_alias=ufs
    euctl bootstrap.webservices.ssl.server_password=$password

    euctl bootstrap.webservices.port=443

    service eucalyptus-cloud restart
    ```

3. Configure Euca2ools Region with HTTPS Endpoints

    We can now switch to HTTPS.

    Note we copy the cloud certificate from the default location to the same directory used for
    other cloud certificates, giving it a similar name. This allows us to centralize multiple
    regions onto a single management workstation.

    ```bash
    cat << EOF > /etc/euca2ools/conf.d/${REGION}.ini
    ; Eucalyptus Region ${REGION}

    [region ${REGION}]
    autoscaling-url = https://autoscaling.${REGION}.${DOMAIN}/
    bootstrap-url = https://bootstrap.${REGION}.${DOMAIN}/
    cloudformation-url = https://cloudformation.${REGION}.${DOMAIN}/
    ec2-url = https://ec2.${REGION}.${DOMAIN}/
    elasticloadbalancing-url = https://elasticloadbalancing.${REGION}.${DOMAIN}/
    iam-url = https://iam.${REGION}.${DOMAIN}/
    monitoring-url = https://monitoring.${REGION}.${DOMAIN}/
    properties-url = https://properties.${REGION}.${DOMAIN}/
    reporting-url = https://reporting.${REGION}.${DOMAIN}/
    s3-url = https://s3.${REGION}.${DOMAIN}/
    sts-url = https://sts.${REGION}.${DOMAIN}/
    user = ${REGION}-admin

    certificate = /usr/share/euca2ools/certs/cert-${REGION}.pem
    verify-ssl = true
    EOF

    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-${REGION}.pem
    chmod 0644 /usr/share/euca2ools/certs/cert-${REGION}.pem
    ```

4. Display Euca2ools Configuration

    This is an example of the configuration which should result from the logic in the last step.

    * The ${REGION} Region should still be the default.
    * The ${REGION} Region should be configured with Custom DNS HTTPS URLs. It can be used from
      other hosts.
    * The localhost Region should still be configured with the default direct URLs. It can only
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
    autoscaling-url = https://autoscaling.${REGION}.${DOMAIN}/
    bootstrap-url = https://bootstrap.${REGION}.${DOMAIN}/
    cloudformation-url = https://cloudformation.${REGION}.${DOMAIN}/
    ec2-url = https://ec2.${REGION}.${DOMAIN}/
    elasticloadbalancing-url = https://elasticloadbalancing.${REGION}.${DOMAIN}/
    iam-url = https://iam.${REGION}.${DOMAIN}/
    monitoring-url = https://monitoring.${REGION}.${DOMAIN}/
    properties-url = https://properties.${REGION}.${DOMAIN}/
    reporting-url = https://reporting.${REGION}.${DOMAIN}/
    s3-url = https://s3.${REGION}.${DOMAIN}/
    sts-url = https://sts.${REGION}.${DOMAIN}/
    user = ${REGION}-admin

    certificate = /usr/share/euca2ools/certs/cert-${REGION}.pem
    verify-ssl = true
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

