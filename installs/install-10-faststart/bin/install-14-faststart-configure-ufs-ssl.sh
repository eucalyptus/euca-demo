#/bin/bash
#
# This script configures Eucalyptus UFS to use SSL after a Faststart installation
#
# This should be run immediately after the Faststart PKI configuration script
#
# This script is incompatible with running a proxy on the same host. It will check
# for this condition and refuse to run if that is found.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

date=$(date +%Y%m%d-%H%M)

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
config=$(hostname -s)
password=N0t5ecret
cacerts_password=changeit
export_password=N0t5ecret2

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config] [-p password]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -c config    configuration (default: $config)"
    echo "  -p password  password for PKCS#12 archive (default: $password)"
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

while getopts Isfc:p:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  config="$OPTARG";;
    p)  password="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if nc -z $(hostname) 443 &> /dev/null; then
    echo "A server program is running on port 443, which most often means the proxy script may have been run"
    echo "This script is incompatible with the proxy on the same host - exiting"
    exit 5
fi

if [[ $config =~ ^([a-zA-Z0-9_-]*)$ ]]; then
    conffile=$confdir/$config.txt

    if [ ! -r $conffile ]; then
        echo "-c $config invalid: can't find configuration file: $conffile"
        exit 5
    fi
else
    echo "-c $config illegal: must consist of a-z, A-Z, 0-9, '-' or '_' characters"
    exit 2
fi

source $conffile

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    sleep 2

    if [ -r /root/admin.zip ]; then
        echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
        cp -a /root/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/
        sleep 2
    else
        echo "Could not convert FastStart Eucalyptus Administrator credentials!"
        echo "Expected to find: /root/admin.zip"
        exit 29
    fi
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Create PKCS#12 Archive"
echo "    - This archive format combines the Key and SSL Certificate in a single file"
echo "    - This is needed for configuration of SSL for Java Services"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "openssl pkcs12 -export -name ufs \\"
echo "               -inkey /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \\"
echo "               -in /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt \\"
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
        echo ">              -inkey /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \\"
        echo ">              -in /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt \\"
        echo ">              -out /var/tmp/ufs.p12 \\"
        echo ">              -password pass:$password"
        openssl pkcs12 -export -name ufs \
                       -inkey /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \
                       -in /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt \
                       -out /var/tmp/ufs.p12 \
                       -password pass:$password
        echo "#"
        echo "# chmod 400 /var/tmp/ufs.p12"
        chmod 400 /var/tmp/ufs.p12

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure User-Facing Services to use SSL and HTTPS port"
echo "    - Backup current Eucalyptus Keystore before modifications"
echo "    - Import PKCS#12 Archive into Eucalyptus Keystore"
echo "    - List contents of Eucalyptus Keystore (confirm ufs certificate exists)"
echo "    - Configure Eucalyptus to use the new certificate after import"
echo "    - Configure Eucalyptus to listen on standard HTTPS port"
echo "    - Restart Eucalyptus-Cloud to pick up the changes"
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

        echo "# euca-modify-property -p bootstrap.webservices.port=443"
        euca-modify-property -p bootstrap.webservices.port=443
        pause

        echo "# service eucalyptus-cloud restart"
        service eucalyptus-cloud restart

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Refresh Administrator Credentials"
echo "    - Wait for services to become available after restart"
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

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus UFS SSL configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus UFS SSL configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
