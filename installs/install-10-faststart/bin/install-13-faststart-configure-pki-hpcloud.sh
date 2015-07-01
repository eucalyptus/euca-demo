#/bin/bash
#
# This script configures Eucalyptus PKI, including a local trusted root CA and SSL certificates
# - This variant uses the HP Cloud Certification Authority Hierarchy
#
# This should be run immediately after the Faststart DNS configuration script
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
password=
cacerts_password=changeit

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-p password]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
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

while getopts Isfp:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    p)  password="$OPTARG";;
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
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
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
echo "cat << EOF > /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt"
cat $certsdir/cloudca.hpcloud.ms.crt
echo "EOF"
echo
echo "openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt \\"
echo "             -sha1 -noout -fingerprint"
echo
echo "update-ca-trust extract"
echo
echo "awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
echo "    < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"<fingerprint>\""
echo
echo "keytool -list \\"
echo "        -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
echo "   grep -A1 cloudca.hpcloud.ms"

if [ -e /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt ]; then
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

        echo "# cat << EOF > /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt"
        cat $certsdir/cloudca.hpcloud.ms.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/cloudca.hpcloud.ms.crt /etc/pki/ca-trust/source/anchors
        chown root:root /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt
        echo "#"
        echo "# openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt \\"
        echo ">              -sha1 -noout -fingerprint"
        fingerprint=$(openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt \
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
        echo ">    grep -A1 cloudca.hpcloud.ms"
        keytool -list \
                -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \
           grep -A1 cloudca.hpcloud.ms

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure SSL to trust local Certificate Authority"
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
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
echo "cat << EOF > /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt"
cat $certsdir/cloudpca.uswest.hpcloud.ms.crt
echo "EOF"
echo
echo "openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt \\"
echo "             -sha1 -noout -fingerprint"
echo
echo "update-ca-trust extract"
echo
echo "awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
echo "    < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"<fingerprint>\""
echo
echo "keytool -list \\"
echo "        -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
echo "   grep -A1 cloudpca"

if [ -e /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt ]; then
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

        echo "# cat << EOF > /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt"
        cat $certsdir/cloudpca.uswest.hpcloud.ms.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/cloudpca.uswest.hpcloud.ms.crt /etc/pki/ca-trust/source/anchors
        chown root:root /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt
        echo "#"
        echo "# openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt \\"
        echo ">              -sha1 -noout -fingerprint"
        fingerprint=$(openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt \
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
        echo ">    grep -A1 cloudpca"
        keytool -list \
                -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \
           grep -A1 cloudpca

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure SSL to trust local Certificate Authority"
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
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
echo "cat << EOF > /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt"
cat $certsdir/aw2cloudica03.uswest.hpcloud.ms.crt
echo "EOF"
echo
echo "openssl x509 -in /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt \\"
echo "             -sha1 -noout -fingerprint"
echo
echo "update-ca-trust extract"
echo
echo "awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \\"
echo "    < /etc/pki/tls/certs/ca-bundle.trust.crt | grep \"<fingerprint>\""
echo
echo "keytool -list \\"
echo "        -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \\"
echo "   grep -A1 aw2cloudica03"

if [ -e /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt ]; then
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

        echo "# cat << EOF > /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt"
        cat $certsdir/aw2cloudica03.uswest.hpcloud.ms.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/aw2cloudica03.uswest.hpcloud.ms.crt /etc/pki/ca-trust/source/anchors
        chown root:root /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt
        echo "#"
        echo "# openssl x509 -in /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt \\"
        echo ">              -sha1 -noout -fingerprint"
        fingerprint=$(openssl x509 -in /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt \
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
        echo ">    grep -A1 aw2cloudica03"
        keytool -list \
                -keystore /etc/pki/java/cacerts -storepass $cacerts_password | \
           grep -A1 aw2cloudica03

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install SSL Key"
if [ -r $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key ]; then
    echo "    - This key is insecure, websites using it should not be exposed to the"
    echo "      Internet"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ -r $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key.secure ]; then
    echo "cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
    openssl rsa -in $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key.secure \
                -out /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key \
                -passin pass:$password
    cat /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
    rm -f /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
else
    echo "cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
    cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
    echo "EOF"
fi
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
        if [ -r $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key.secure ]; then
            echo "# cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
            openssl rsa -in $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key.secure \
                        -out /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key \
                        -passin pass:$password
            cat /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
            cp /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
            rm -f /tmp/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
        else
            echo "# cat << EOF > /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key"
            cat $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key | sed -e 's/^/> /'
            echo "> EOF"
            cp $certsdir/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$EUCA_DNS_REGION.$EUCA_DNS_REGION_DOMAIN.key
        fi
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
echo "    - We use a wildcard SSL certificate signed by the local CA to prevent"
echo "      unknown CA SSL warnings"
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

end=$(date +%s)

echo
echo "Eucalyptus PKI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"