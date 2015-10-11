#/bin/bash
#
# This script configures Eucalyptus PKI, including a local trusted root CA and SSL certificates
# - This variant uses the HP EBC Root Certification Authority
#
# This should be run immediately after the Faststart DNS configuration script
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
certsdir=${bindir%/*/*/*}/certs
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
password=
cacerts_password=changeit

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config] [-p password]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -c config    configuration (default: $config)"
    echo "  -p password  password for key if encrypted"
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
echo "$(printf '%2d' $step). Configure SSL to trust local Certificate Authority"
echo "    - We will use the HP EBC Root Certification Authority to sign SSL certificates"
echo "    - We must add this CA cert to the trusted root certificate authorities on"
echo "      all servers which use these certificates, and on all browsers which must"
echo "      trust websites served by them"
echo "    - The \"update-ca-trust extract\" command updates both the OpenSSL and"
echo "      Java trusted ca bundles"
echo "    - Verify certificate was added to the OpenSSL trusted ca bundle"
echo "    - Verify certificate was added to the Java trusted ca bundle"
echo "    - You can copy the body of the certificate below to install on your browser"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ ! -L /etc/pki/tls/certs/ca-bundle.crt ]; then
    echo "update-ca-trust enable"
    echo
fi
echo "cat << EOF > /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt"
cat $certsdir/hpccc-DC1A-CA.crt
echo "EOF"
echo
echo "openssl x509 -in /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt \\"
echo "             -sha1 -noout -fingerprint"
echo
echo "update-ca-trust extract"
echo
echo "awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
echo "    < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"<fingerprint>\""
echo
echo "keytool -list \\"
echo "        -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
echo "   grep -A1 hpccc-dc1a-ca"

if [ -e /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt ]; then
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

        echo "# cat << EOF > /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt"
        cat $certsdir/hpccc-DC1A-CA.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/hpccc-DC1A-CA.crt /etc/pki/ca-trust/source/anchors
        chown root:root /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt
        echo "#"
        echo "# openssl x509 -in /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt \\"
        echo ">              -sha1 -noout -fingerprint"
        fingerprint=$(openssl x509 -in /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt \
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
        echo ">    grep -A1 hpccc-dc1a-ca"
        keytool -list \
                -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \
           grep -A1 hpccc-dc1a-ca

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install SSL Key"
if [ -r $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key ]; then
    echo "    - This key is insecure, websites using it should not be exposed to the"
    echo "      Internet"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ -r $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure ]; then
    echo "cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"
    openssl rsa -in $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure \
                -out /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \
                -passin pass:$password
    cat /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    echo "EOF"
    rm -f /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
else
    echo "cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"
    cat $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    echo "EOF"
fi
echo
echo "chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"

if [ -e /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        if [ -r $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure ]; then
            echo "# cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"
            openssl rsa -in $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure \
                        -out /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \
                        -passin pass:$password
            cat /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key | sed -e 's/^/> /'
            echo "> EOF"
            cp /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
            rm -f /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
        else
            echo "# cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"
            cat $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key | sed -e 's/^/> /'
            echo "> EOF"
            cp $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
        fi
        echo "#"
        echo "# chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key"
        chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Wildcard SSL Certificate"
echo "    - We use a wildcard SSL certificate signed by the local CA to prevent"
echo "      unknown CA SSL warnings"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt"
cat $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
echo "EOF"
echo
echo "chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt"

if [ -e /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt"
        cat $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt /etc/pki/tls/certs
        chown root:root /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
        echo "#"
        echo "# chmod 440 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt"
        chmod 440 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt

        next 50
    fi
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus PKI configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus PKI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
