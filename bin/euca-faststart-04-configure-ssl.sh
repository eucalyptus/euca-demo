#/bin/bash
#
# This script configures Eucalyptus SSL certificates and sets up UFS to use HTTPS after a Faststart installation
#
# This should be run immediately after the Faststart Console configuration script
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y || is_mc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
certsdir=${bindir%/*}/certs
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

date=$(date +%Y%m%d-%H%M)

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
password=N0t5ecret
cacerts_password=changeit
export_password=N0t5ecret2
ufs_ssl=1
mc_ssl=1

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-p password] [-U] [-C]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -p  password password for PKCS#12 archive (default: $password)"
    echo "  -U  skip SSL configuration of User Facing Services"
    echo "  -C  skip SSL configuration of Management Console"
}

run() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=run_default * speed / 100))
    else
        ((seconds=run_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo
        echo -n "Run? [Y/n/q]"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
            "n" | "N" | "no" | "No") choice=n ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        echo
        echo -n -e "Waiting $(printf '%2d' $seconds) seconds..."
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "\rWaiting $(printf '%2d' $seconds) seconds..."
            fi
            sleep 1
            ((seconds--))
        done
        echo " Done"
        choice=y
    fi
}

pause() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=pause_default * speed / 100))
    else
        ((seconds=pause_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo "#"
        read pause
        echo -en "\033[1A\033[2K"    # undo newline from read
    else
        echo "#"
        sleep $seconds
    fi
}

next() {
    if [ -z $1 ] || (($1 % 25 != 0)); then
        ((seconds=next_default * speed / 100))
    else
        ((seconds=next_default * $1 * speed / 10000))
    fi
    if [ $interactive = 1 ]; then
        echo
        echo -n "Next? [Y/q]"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
             *) echo "cancelled"
                exit 2;;
        esac
    else
        echo
        echo -n -e "Waiting $(printf '%2d' $seconds) seconds..."
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "\rWaiting $(printf '%2d' $seconds) seconds..."
            fi
            sleep 1
            ((seconds--))
        done
        echo " Done"
        choice=y
    fi
}


#  3. Parse command line options

while getopts Isfp:UC? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    p)  password="$OPTARG";;
    U)  ufs_ssl=0;;
    C)  mc_ssl=0;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_mc = n ]; then
    echo "This script should only be run on a Management Console host"
    exit 20
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure SSL to trust local Certificate Authority"
echo "     - We will use the Helion Eucalyptus Development Root Certificate Authority"
echo "       to sign SSL certificates"
echo "     - We must add this CA cert to the trusted root certificate authorities on"
echo "       all servers which use these certificates, and on all browsers which must"
echo "       trust websites served by them"
echo "     - The \"update-ca-trust extract\" command updates both the OpenSSL and"
echo "       Java trusted ca bundles"
echo "     - Verify certificate was added to the OpenSSL trusted ca bundle"
echo "     - Verify certificate was added to the Java trusted ca bundle"
echo "     - You can copy the body of the certificate below to install on your browser"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -L /etc/pki/tls/certs/ca-bundle.crt ]; then
    echo "update-ca-trust enable"
    echo
fi
echo "cat << EOF > /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt"
cat $certsdir/Helion_Eucalyptus_Development_Root_Certification_Authority.crt
echo "EOF"
echo
echo "openssl x509 -in /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt \\"
echo "             -sha1 -noout -fingerprint"
echo
echo "update-ca-trust extract"
echo
echo "awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
echo "    < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"<fingerprint>\""
echo
echo "keytool -list \\"
echo "        -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
echo "   grep -A1 helioneucalyptusdevelopmentrootcertificationauthority"

if [ -e /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt ]; then
    echo
    tput rev
    echo "Already Trusted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        if [ ! -L /etc/pki/tls/certs/ca-bundle.crt ]; then
            echo "# update-ca-trust enable"
            update-ca-trust enable
            pause
        fi

        echo "# cat << EOF > /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt"
        cat $certsdir/Helion_Eucalyptus_Development_Root_Certification_Authority.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/Helion_Eucalyptus_Development_Root_Certification_Authority.crt /etc/pki/ca-trust/source/anchors
        chown root:root /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt
        echo "#"
        echo "# openssl x509 -in /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt \\"
        echo ">              -sha1 -noout -fingerprint"
        fingerprint=$(openssl x509 -in /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt \
                                   -sha1 -noout -fingerprint)
        echo $fingerprint
        fingerprint=${fingerprint#*=}
        pause

        echo "# update-ca-trust extract"
        update-ca-trust extract
        pause

        echo "# awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
        echo ">     < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"$fingerprint\""
        awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
            < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "$fingerprint"
        echo "#"
        echo "# keytool -list \\"
        echo ">         -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
        echo ">    grep -A1 helioneucalyptusdevelopmentrootcertificationauthority"
        keytool -list \
                -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \
           grep -A1 helioneucalyptusdevelopmentrootcertificationauthority

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install SSL Key"
echo "     - This key is insecure, websites using it should not be exposed to the"
echo "       Internet"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
echo "EOF"
echo
echo "chmod 400 /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"

if [ -e /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
        cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key /etc/pki/tls/private
        chown root:root /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
        echo "#"
        echo "# chmod 400 /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
        chmod 400 /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Wildcard SSL Certificate"
echo "     - We use a wildcard SSL certificate signed by the local CA to prevent"
echo "       unknown CA SSL warnings"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt"
cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt
echo "EOF"
echo
echo "chmod 444 /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt"

if [ -e /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt"
        cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt /etc/pki/tls/certs
        chown root:root /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt
        echo "#"
        echo "# chmod 440 /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt"
        chmod 440 /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Create PKCS#12 Archive"
echo "     - This archive format combines the Key and SSL Certificate in a single file"
echo "     - This is needed for configuration of SSL for Java Services"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "openssl pkcs12 -export -name ufs \\"
echo "               -inkey /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key \\"
echo "               -in /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt \\"
echo "               -out /var/tmp/ufs.p12 \\"
echo "               -password pass:$password"
echo
echo "chmod 400 /var/tmp/ufs.p12"

if [ -e /var/tmp/ufs.p12 ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# openssl pkcs12 -export -name ufs \\"
        echo ">              -inkey /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key \\"
        echo ">              -in /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt \\"
        echo ">              -out /var/tmp/ufs.p12 \\"
        echo ">              -password pass:$password"
        openssl pkcs12 -export -name ufs \
                       -inkey /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key \
                       -in /etc/pki/tls/certs/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt \
                       -out /var/tmp/ufs.p12 \
                       -password pass:$password
        echo "#"
        echo "# chmod 400 /var/tmp/ufs.p12"
        chmod 400 /var/tmp/ufs.p12

        next 50
    fi
fi


if [ "$ufs_ssl" = "1" ]; then
    ((++step))
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Configure User-Facing Services to use SSL and HTTPS port"
    echo "     - Backup current Eucalyptus Keystore before modifications"
    echo "     - Import PKCS#12 Archive into Eucalyptus Keystore"
    echo "     - List contents of Eucalyptus Keystore (confirm ufs certificate exists)"
    echo "     - Configure Eucalyptus to use the new certificate after import"
    echo "     - Configure Eucalyptus to listen on standard HTTPS port"
    echo "     - Restart Eucalyptus-Cloud to pick up the changes"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "cp -a /var/lib/eucalyptus/keys/euca.p12 /var/lib/eucalyptus/keys/euca-$date.p12"
    echo
    echo "keytool -importkeystore -alias ufs \\"
    echo "        -srckeystore /var/tmp/ufs.p12 -srcstoretype pkcs12 \\"
    echo "        -srcstorepass $password -srckeypass $password \\"
    echo "        -destkeystore /var/lib/eucalyptus/keys/euca.p12 -deststoretype pkcs12 \\"
    echo "        -deststorepass eucalyptus -destkeypass $password"
    echo
    echo "keytool -list \\"
    echo "        -keystore /var/lib/eucalyptus/keys/euca.p12 -storetype pkcs12 \\"
    echo "        -storepass eucalyptus"
    echo
    echo "euca-modify-property -p bootstrap.webservices.ssl.server_alias=ufs"
    echo "euca-modify-property -p bootstrap.webservices.ssl.server_password=$password"
    echo
    echo "euca-modify-property -p bootstrap.webservices.default_https_enabled=true"
    echo "euca-modify-property -p bootstrap.webservices.port=443"
    echo
    echo "service eucalyptus-cloud restart"

    if keytool -list -alias ufs -keystore /var/lib/eucalyptus/keys/euca.p12 --storetype pkcs12 --storepass eucalyptus &> /dev/null; then
        echo
        tput rev
        echo "Already Configured!"
        tput sgr0

        next 50

    else
        run

        if [ $choice = y ]; then
            echo
            echo "# cp -a /var/lib/eucalyptus/keys/euca.p12 /var/lib/eucalyptus/keys/euca-$date.p12"
            cp -a /var/lib/eucalyptus/keys/euca.p12 /var/lib/eucalyptus/keys/euca-$date.p12
            pause

            echo "# keytool -importkeystore -alias ufs \\"
            echo ">         -srckeystore /var/tmp/ufs.p12 -srcstoretype pkcs12 \\"
            echo ">         -srcstorepass $password -srckeypass $password \\"
            echo ">         -destkeystore /var/lib/eucalyptus/keys/euca.p12 -deststoretype pkcs12 \\"
            echo ">         -deststorepass eucalyptus -destkeypass $password"
            keytool -importkeystore -alias ufs \
                    -srckeystore /var/tmp/ufs.p12 -srcstoretype pkcs12 \
                    -srcstorepass $password -srckeypass $password \
                    -destkeystore /var/lib/eucalyptus/keys/euca.p12 -deststoretype pkcs12 \
                    -deststorepass eucalyptus -destkeypass $password
            pause

            echo "# keytool -list \\"
            echo ">         -keystore /var/lib/eucalyptus/keys/euca.p12 -storetype pkcs12 \\"
            echo ">         -storepass eucalyptus"
            keytool -list \
                    -keystore /var/lib/eucalyptus/keys/euca.p12 -storetype pkcs12 \
                    -storepass eucalyptus
            pause

            echo "# euca-modify-property -p bootstrap.webservices.ssl.server_alias=ufs"
            euca-modify-property -p bootstrap.webservices.ssl.server_alias=ufs
            echo "# euca-modify-property -p bootstrap.webservices.ssl.server_password=$password"
            euca-modify-property -p bootstrap.webservices.ssl.server_password=$password
            pause

            echo "# euca-modify-property -p bootstrap.webservices.default_https_enabled=true"
            euca-modify-property -p bootstrap.webservices.default_https_enabled=true
            echo "# euca-modify-property -p bootstrap.webservices.port=443"
            euca-modify-property -p bootstrap.webservices.port=443
            pause

            echo "# service eucalyptus-cloud restart"
            service eucalyptus-cloud restart

            next
        fi
    fi
else
    ((++step))
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Configure User-Facing Services to use HTTP port"
    echo "     - Configure Eucalyptus to listen on standard HTTP port"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p bootstrap.webservices.port=80"

if euca-describe-properties bootstrap.webservices.port | grep -s -q "80"; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

        if [ $choice = y ]; then
            echo
            echo "# euca-modify-property -p bootstrap.webservices.port=80"
            euca-modify-property -p bootstrap.webservices.port=80

            next 50
        fi
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Refresh Administrator Credentials"
echo "     - Wait for services to become available after restart"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
echo
echo "euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
echo
echo "unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"

run 50

if [ $choice = y ]; then
    echo
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

    echo
    echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin"
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
    pause

    echo "# rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
    pause

    echo "# euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
    euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
    pause

    echo "# unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/"
    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/
    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        # invisibly fix missing environment variables needed for image import
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
        sed -i -e "/WARN: Certificate credentials not present./d" \
               -e "/WARN: Review authentication.credential_download_generate_certificate and/d" \
               -e "/WARN: authentication.signing_certificates_limit properties for current/d" \
               -e "/WARN: certificate download limits./d" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi
    if [ -r /root/eucarc ]; then
        # invisibly update Faststart credentials location
        cp -a ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc /root/eucarc
    fi
    pause

    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    pause

    echo "# source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    pause

    next
fi


if [ "$mc_ssl" = "1" ]; then
    ((++step))
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Configure Nginx to use wildcard SSL certificate"
    echo " - This certificate is signed by the Helion Eucalyptus Development Root Certificate Authority"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "sed -i -e \"s/\\/etc\\/eucaconsole\\/console.crt/\\/etc\\/pki\\/tls\\/certs\\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt/\" \\"
    echo "       -e \"s/\\/etc\\/eucaconsole\\/console.key/\\/etc\\/pki\\/tls\\/private\\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key/\" /etc/nginx/nginx.conf"

    run

    if [ $choice = y ]; then
        echo
        echo "# sed -i -e \"s/\\/etc\\/eucaconsole\\/console.crt/\\/etc\\/pki\\/tls\\/certs\\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt/\" \\"
        echo ">        -e \"s/\\/etc\\/eucaconsole\\/console.key/\\/etc\\/pki\\/tls\\/private\\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key/\" /etc/nginx/nginx.conf"
        sed -i -e "s/\/etc\/eucaconsole\/console.crt/\/etc\/pki\/tls\/certs\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.crt/" \
               -e "s/\/etc\/eucaconsole\/console.key/\/etc\/pki\/tls\/private\/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key/" /etc/nginx/nginx.conf

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Restart Nginx service"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service nginx restart"

run 50

if [ $choice = y ]; then
    echo
    echo "# service nginx restart"
    service nginx restart

    next 50
fi


end=$(date +%s)

echo
echo "Eucalyptus SSL configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
