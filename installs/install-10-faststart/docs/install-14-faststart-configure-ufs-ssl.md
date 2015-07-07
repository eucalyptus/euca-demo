# FastStart Install: Configure UFS to use SSL
### This variant uses the Helion Eucalyptus Development PKI Infrastructure

This document describes the manual procedure to configure UFS to use SSL, after Eucalyptus has been
installed via the FastStart installer. This procedure is incompatible with the reverse-proxy script
on the same host, as both attempt to use port 443.

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
                   -inkey /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \
                   -in /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt \
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

    euca-modify-property -p bootstrap.webservices.ssl.server_alias=ufs
    euca-modify-property -p bootstrap.webservices.ssl.server_password=$password

    euca-modify-property -p bootstrap.webservices.port=443

    service eucalyptus-cloud restart
    ```

3. Refresh Administrator Credentials

    The first section of code waits for services to become available after restart.

    ```bash
    while true; do
        echo -n "Testing services... "
        if curl -s https://$(hostname -i)/services/User-API | grep -s -q 404; then
            echo " Started"
            break
        else
            echo " Not yet running"
            echo -n "Waiting another 15 seconds..."
            sleep 15
            echo " Done"
        fi
    done

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

