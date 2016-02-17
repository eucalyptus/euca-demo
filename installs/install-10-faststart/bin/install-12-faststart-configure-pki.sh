#/bin/bash
#
# This script configures Eucalyptus PKI, including a local trusted root CA and SSL certificates
# - This variant uses the Helion Eucalyptus Development Root Certification Authority
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
password=
cacerts_password=changeit
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-p password]"
    echo "               [-r region] [-d domain]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -p password  password for key if encrypted"
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -d domain    Eucalyptus Domain (default: $domain)"
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

while getopts Isfp:r:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    p)  password="$OPTARG";;
    r)  region="$OPTARG"
        [ -z $domain ] &&
        domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null);;
    d)  domain="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $region ]; then
    echo "-r region missing!"
    echo "Could not automatically determine region, and it was not specified as a parameter"
    exit 10
else
    case $region in
      us-east-1|us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $domain ]; then
    echo "-d domain missing!"
    echo "Could not automatically determine domain, and it was not specified as a parameter"
    exit 12
fi

user_region=$region-admin@$region

if ! grep -s -q "\[user $region-admin]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Eucalyptus Administrator Euca2ools user!"
    echo "Expected to find: [user $region-admin] in ~/.euca/$region.ini"
    exit 50
fi

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure SSL to trust local Certificate Authority"
echo "    - We will use the Helion Eucalyptus Development Root Certification Authority"
echo "      to sign SSL certificates"
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
if [ -r $certsdir/star.$region.$domain.key ]; then
    echo "    - This key is insecure, websites using it should not be exposed to the"
    echo "      Internet"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ -r $certsdir/star.$region.$domain.key.secure ]; then
    echo "cat << EOF > /etc/pki/tls/private/star.$region.$domain.key"
    openssl rsa -in $certsdir/star.$region.$domain.key.secure \
                -out /tmp/star.$region.$domain.key \
                -passin pass:$password
    cat /tmp/star.$region.$domain.key
    rm -f /tmp/star.$region.$domain.key
else
    echo "cat << EOF > /etc/pki/tls/private/star.$region.$domain.key"
    cat $certsdir/star.$region.$domain.key
    echo "EOF"
fi
echo
echo "chmod 400 /etc/pki/tls/private/star.$region.$domain.key"

if [ -e /etc/pki/tls/private/star.$region.$domain.key ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        if [ -r $certsdir/star.$region.$domain.key.secure ]; then
            echo "# cat << EOF > /etc/pki/tls/private/star.$region.$domain.key"
            openssl rsa -in $certsdir/star.$region.$domain.key.secure \
                        -out /tmp/star.$region.$domain.key \
                        -passin pass:$password
            cat /tmp/star.$region.$domain.key | sed -e 's/^/> /'
            cp /tmp/star.$region.$domain.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$region.$domain.key
            rm -f /tmp/star.$region.$domain.key
        else
            echo "# cat << EOF > /etc/pki/tls/private/star.$region.$domain.key"
            cat $certsdir/star.$region.$domain.key | sed -e 's/^/> /'
            echo "> EOF"
            cp $certsdir/star.$region.$domain.key /etc/pki/tls/private
            chown root:root /etc/pki/tls/private/star.$region.$domain.key
        fi
        echo "#"
        echo "# chmod 400 /etc/pki/tls/private/star.$region.$domain.key"
        chmod 400 /etc/pki/tls/private/star.$region.$domain.key

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
echo "cat << EOF > /etc/pki/tls/certs/star.$region.$domain.crt"
cat $certsdir/star.$region.$domain.crt
echo "EOF"
echo
echo "chmod 444 /etc/pki/tls/certs/star.$region.$domain.crt"

if [ -e /etc/pki/tls/certs/star.$region.$domain.crt ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/pki/tls/certs/star.$region.$domain.crt"
        cat $certsdir/star.$region.$domain.crt | sed -e 's/^/> /'
        echo "> EOF"
        cp $certsdir/star.$region.$domain.crt /etc/pki/tls/certs
        chown root:root /etc/pki/tls/certs/star.$region.$domain.crt
        echo "#"
        echo "# chmod 440 /etc/pki/tls/certs/star.$region.$domain.crt"
        chmod 440 /etc/pki/tls/certs/star.$region.$domain.crt

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
