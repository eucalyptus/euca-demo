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
password=N0t5ecret
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)
cacerts_password=changeit
export_password=N0t5ecret2

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-p password]"
    echo "               [-r region] [-d domain]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -p password  password for PKCS#12 archive (default: $password)"
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
    c)  config="$OPTARG";;
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

if nc -z $(hostname) 443 &> /dev/null; then
    echo "A server program is running on port 443, which most often means Eucalyptus Console has been installed on this host"
    echo "This script is incompatible with the default installation of Eucalyptus Console, which has the embedded Nginx proxy"
    echo "which works only with the Console - exiting."
    exit 5
fi

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
echo "$(printf '%2d' $step). Create PKCS#12 Archive"
echo "    - This archive format combines the Key and SSL Certificate in a single file"
echo "    - This is needed for configuration of SSL for Java Services"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "openssl pkcs12 -export -name ufs \\"
echo "               -inkey /etc/pki/tls/private/star.$region.$domain.key \\"
echo "               -in /etc/pki/tls/certs/star.$region.$domain.crt \\"
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
        echo ">              -inkey /etc/pki/tls/private/star.$region.$domain.key \\"
        echo ">              -in /etc/pki/tls/certs/star.$region.$domain.crt \\"
        echo ">              -out /var/tmp/ufs.p12 \\"
        echo ">              -password pass:$password"
        openssl pkcs12 -export -name ufs \
                       -inkey /etc/pki/tls/private/star.$region.$domain.key \
                       -in /etc/pki/tls/certs/star.$region.$domain.crt \
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
echo "euctl bootstrap.webservices.ssl.server_alias=ufs"
echo "euctl bootstrap.webservices.ssl.server_password=$password"
echo
echo "euctl bootstrap.webservices.port=443"
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
        euctl bootstrap.webservices.ssl.server_alias=ufs
        echo "# euctl bootstrap.webservices.ssl.server_password=$password"
        euctl bootstrap.webservices.ssl.server_password=$password
        pause

        echo "# euctl bootstrap.webservices.port=443"
        euctl bootstrap.webservices.port=443
        pause

        echo "# service eucalyptus-cloud restart"
        service eucalyptus-cloud restart

        next
    fi
fi


((++step))
# Construct Eucalyptus Endpoints (assumes AWS-style URLs)
autoscaling_url=https://autoscaling.$region.$domain/
bootstrap_url=https://bootstrap.$region.$domain/
cloudformation_url=https://cloudformation.$region.$domain/
ec2_url=https://ec2.$region.$domain/
elasticloadbalancing_url=https://elasticloadbalancing.$region.$domain/
iam_url=https://iam.$region.$domain/
monitoring_url=https://monitoring.$region.$domain/
properties_url=https://properties.$region.$domain/
reporting_url=https://reporting.$region.$domain/
s3_url=https://s3.$region.$domain/
sts_url=https://sts.$region.$domain/

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Euca2ools Region for HTTPS Endpoints"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > /etc/euca2ools/conf.d/$region.ini"
echo "; Eucalyptus Region $region"
echo
echo "[region $region]"
echo "autoscaling-url = $autoscaling_url"
echo "bootstrap-url = $bootstrap_url"
echo "cloudformation-url = $cloudformation_url"
echo "ec2-url = $ec2_url"
echo "elasticloadbalancing-url = $elasticloadbalancing_url"
echo "iam-url = $iam_url"
echo "monitoring-url = $monitoring_url"
echo "properties-url = $properties_url"
echo "reporting-url = $reporting_url"
echo "s3-url = $s3_url"
echo "sts-url = $sts_url"
echo "user = $region-admin"
echo
echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem"
echo "verify-ssl = true"
echo "EOF"
echo
echo "cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
echo "chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"

if  grep -s -q "ec2-url = $ec2_url" /etc/euca2ools/conf.d/$region.ini; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > /etc/euca2ools/conf.d/$region.ini"
        echo "> ; Eucalyptus Region $region"
        echo ">"
        echo "> [region $region]"
        echo "> autoscaling-url = $autoscaling_url"
        echo "> cloudformation-url = $cloudformation_url"
        echo "> bootstrap-url = $bootstrap_url"
        echo "> ec2-url = $ec2_url"
        echo "> elasticloadbalancing-url = $elasticloadbalancing_url"
        echo "> iam-url = $iam_url"
        echo "> monitoring-url = $monitoring_url"
        echo "> properties-url = $properties_url"
        echo "> reporting-url = $reporting_url"
        echo "> s3-url = $s3_url"
        echo "> sts-url = $sts_url"
        echo "> user = $region-admin"
        echo ">"
        echo "> certificate = /usr/share/euca2ools/certs/cert-$region.pem"
        echo "> verify-ssl = true"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Region $region"                                > /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo "[region $region]"                                          >> /etc/euca2ools/conf.d/$region.ini
        echo "autoscaling-url = $autoscaling_url"                        >> /etc/euca2ools/conf.d/$region.ini
        echo "cloudformation-url = $cloudformation_url"                  >> /etc/euca2ools/conf.d/$region.ini
        echo "bootstrap-url = $bootstrap_url"                            >> /etc/euca2ools/conf.d/$region.ini
        echo "ec2-url = $ec2_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "elasticloadbalancing-url = $elasticloadbalancing_url"      >> /etc/euca2ools/conf.d/$region.ini
        echo "iam-url = $iam_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "monitoring-url = $monitoring_url"                          >> /etc/euca2ools/conf.d/$region.ini
        echo "properties-url = $properties_url"                          >> /etc/euca2ools/conf.d/$region.ini
        echo "reporting-url = $reporting_url"                            >> /etc/euca2ools/conf.d/$region.ini
        echo "s3-url = $s3_url"                                          >> /etc/euca2ools/conf.d/$region.ini
        echo "sts-url = $sts_url"                                        >> /etc/euca2ools/conf.d/$region.ini
        echo "user = $region-admin"                                      >> /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo                                                             >> /etc/euca2ools/conf.d/$region.ini
        echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem" >> /etc/euca2ools/conf.d/$region.ini
        echo "verify-ssl = false"                                        >> /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
        cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem
        echo "# chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"
        chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem

        next
    fi
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus UFS SSL configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus UFS SSL configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
