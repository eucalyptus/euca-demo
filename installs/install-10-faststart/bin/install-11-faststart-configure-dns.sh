#!/bin/bash
#
# This script configures Eucalyptus DNS after a Faststart installation
#
# This should be run immediately after the Faststart installer completes
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
showdnsconfig=0
config=$(hostname -s)
extended=0

dns_timeout=30
dns_loadbalancer_ttl=15


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-d] [-c config] [-e]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -d         display parent DNS server sample configuration"
    echo "  -c config  configuration (default: $config)"
    echo "  -e         extended confirmation of API calls"
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

while getopts Isfdc:e? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    d)  showdnsconfig=1;;
    c)  config="$OPTARG";;
    e)  extended=1;;
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
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"

next

echo
echo "# cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
pause

echo "# source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

next


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus DNS Server"
echo "    - Instances will use the Cloud Controller's DNS Server directly"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p system.dns.nameserver=ns1.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "euca-modify-property -p system.dns.nameserveraddress=$(hostname -i)"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p system.dns.nameserver=ns1.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    euca-modify-property -p system.dns.nameserver=ns1.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    echo "#"
    echo "# euca-modify-property -p system.dns.nameserveraddress=$(hostname -i)"
    euca-modify-property -p system.dns.nameserveraddress=$(hostname -i)

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Timeout and TTL"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p dns.tcp.timeout_seconds=$dns_timeout"
echo
echo "euca-modify-property -p services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p dns.tcp.timeout_seconds=$dns_timeout"
    euca-modify-property -p dns.tcp.timeout_seconds=$dns_timeout
    echo "#"
    echo "# euca-modify-property -p services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl"
    euca-modify-property -p services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Domain"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p system.dns.dnsdomain=$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p system.dns.dnsdomain=$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    euca-modify-property -p system.dns.dnsdomain=$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Sub-Domains"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p cloud.vmstate.instance_subdomain=$EUCA_DNS_INSTANCE_SUBDOMAIN"
echo
echo "euca-modify-property -p services.loadbalancing.dns_subdomain=$EUCA_DNS_LOADBALANCER_SUBDOMAIN"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p cloud.vmstate.instance_subdomain=$EUCA_DNS_INSTANCE_SUBDOMAIN"
    euca-modify-property -p cloud.vmstate.instance_subdomain=$EUCA_DNS_INSTANCE_SUBDOMAIN
    echo "#"
    echo "# euca-modify-property -p services.loadbalancing.dns_subdomain=$EUCA_DNS_LOADBALANCER_SUBDOMAIN"
    euca-modify-property -p services.loadbalancing.dns_subdomain=$EUCA_DNS_LOADBALANCER_SUBDOMAIN

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Enable DNS"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p bootstrap.webservices.use_instance_dns=true"
echo
echo "euca-modify-property -p bootstrap.webservices.use_dns_delegation=true"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p bootstrap.webservices.use_instance_dns=true"
    euca-modify-property -p bootstrap.webservices.use_instance_dns=true
    echo "#"
    echo "# euca-modify-property -p bootstrap.webservices.use_dns_delegation=true"
    euca-modify-property -p bootstrap.webservices.use_dns_delegation=true

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure CloudFormation Region"
echo "    - Technically, this is not purely related to DNS and doesn't belong here"
echo "    - But, we need to make sure this is run, and this is somewhat related to DNS"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p cloudformation.region=$AWS_DEFAULT_REGION"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p cloudformation.region=$AWS_DEFAULT_REGION"
    euca-modify-property -p cloudformation.region=$AWS_DEFAULT_REGION

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Refresh Administrator Credentials"
echo
echo "================================================================================"
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


((++step))
if [ $showdnsconfig = 1 ]; then
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Display Parent DNS Server Configuration"
    echo "    - This is an example of what changes need to be made on the"
    echo "      parent DNS server which will delgate DNS to Eucalyptus"
    echo "      for Eucalyptus DNS names used for instances, ELBs and"
    echo "      services"
    echo "    - You should make these changes to the parent DNS server"
    echo "      manually, once, outside of creating and running demos"
    echo "    - Instances will use the Cloud Controller's DNS Server directly"
    echo "    - This configuration is based on the BIND configuration"
    echo "      conventions used on the cs.prc.eucalyptus-systems.com DNS server"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "# Add these lines to /etc/named.conf on the parent DNS server"
    echo "         zone \"$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN\" IN"
    echo "         {"
    echo "                 type master;"
    echo "                 file \"/etc/named/db.$AWS_DEFAULT_REGION\";"
    echo "         };"
    echo "#"
    echo "# Create the zone file on the parent DNS server"
    echo "> ;"
    echo "> ; DNS zone for $AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    echo "> ; - Eucalyptus configured to use CLC as DNS server"
    echo ">"
    echo "# cat << EOF > /etc/named/db.$AWS_DEFAULT_REGION"
    echo "> $TTL 1M"
    echo "> $ORIGIN $AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    echo "> @                       SOA     ns1 root ("
    echo ">                                 $(date +%Y%m%d)01      ; Serial"
    echo ">                                 1H              ; Refresh"
    echo ">                                 10M             ; Retry"
    echo ">                                 1D              ; Expire"
    echo ">                                 1H )            ; Negative Cache TTL"
    echo ">"
    echo ">                         NS      ns1"
    echo ">"
    echo "> ns1                     A       $(hostname -i)"
    echo ">"
    echo "> clc                     A       $(hostname -i)"
    echo "> ufs                     A       $(hostname -i)"
    echo "> mc                      A       $(hostname -i)"
    echo "> osp                     A       $(hostname -i)"
    echo "> walrus                  A       $(hostname -i)"
    echo "> cc                      A       $(hostname -i)"
    echo "> sc                      A       $(hostname -i)"
    echo "> ns1                     A       $(hostname -i)"
    echo ">"
    echo "> console                 A       $(hostname -i)"
    echo "> autoscaling             A       $(hostname -i)"
    echo "> cloudformation          A       $(hostname -i)"
    echo "> cloudwatch              A       $(hostname -i)"
    echo "> compute                 A       $(hostname -i)"
    echo "> euare                   A       $(hostname -i)"
    echo "> loadbalancing           A       $(hostname -i)"
    echo "> objectstorage           A       $(hostname -i)"
    echo "> tokens                  A       $(hostname -i)"
    echo ">"
    echo "> ${EUCA_DNS_INSTANCE_SUBDOMAIN#.}                   NS      ns1"
    echo "> ${EUCA_DNS_LOADBALANCER_SUBDOMAIN#.}                      NS      ns1"
    echo "> EOF"

    next 200
fi

    
((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm DNS resolution for Services"
echo "    - Confirm service URLS in eucarc resolve"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "dig +short compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
echo
echo "dig +short loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"

run 50

if [ $choice = y ]; then
    echo
    echo "# dig +short compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    pause

    echo "# dig +short loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN"
    dig +short loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm API commands work with new URLs"
echo "    - Confirm service describe commands still work"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-describe-regions"
if [ $extended = 1 ]; then
    echo
    echo "euca-describe-availability-zones"
    echo
    echo "euca-describe-keypairs"
    echo
    echo "euca-describe-images"
    echo
    echo "euca-describe-instance-types"
    echo
    echo "euca-describe-instances"
    echo
    echo "euca-describe-instance-status"
    echo
    echo "euca-describe-groups"
    echo
    echo "euca-describe-volumes"
    echo
    echo "euca-describe-snapshots"
fi
echo
echo "eulb-describe-lbs"
echo
echo "euform-describe-stacks"
echo
echo "euscale-describe-auto-scaling-groups"
if [ $extended = 1 ]; then
    echo
    echo "euscale-describe-launch-configs"
    echo
    echo "euscale-describe-auto-scaling-instances"
    echo
    echo "euscale-describe-policies"
fi
echo
echo "euwatch-describe-alarms"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-regions"
    euca-describe-regions
    pause

    if [ $extended = 1 ]; then
        echo "# euca-describe-availability-zones"
        euca-describe-availability-zones
        pause

        echo "# euca-describe-keypairs"
        euca-describe-keypairs
        pause

        echo "# euca-describe-images"
        euca-describe-images
        pause

        echo "# euca-describe-instance-types"
        euca-describe-instance-types
        pause

        echo "# euca-describe-instances"
        euca-describe-instances
        pause

        echo "# euca-describe-instance-status"
        euca-describe-instance-status
        pause

        echo "# euca-describe-groups"
        euca-describe-groups
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# euca-describe-snapshots"
        euca-describe-snapshots
        pause
    fi

    echo
    echo "# eulb-describe-lbs"
    eulb-describe-lbs
    pause

    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks
    pause

    echo
    echo "# euscale-describe-auto-scaling-groups"
    euscale-describe-auto-scaling-groups
    pause

    if [ $extended = 1 ]; then
        echo "# euscale-describe-launch-configs"
        euscale-describe-launch-configs
        pause

        echo "# euscale-describe-auto-scaling-instances"
        euscale-describe-auto-scaling-instances
        pause

        echo "# euscale-describe-policies"
        euscale-describe-policies
        pause
    fi

    echo
    echo "# euwatch-describe-alarms"
    euwatch-describe-alarms

    next
fi


end=$(date +%s)

echo
echo "Eucalyptus DNS configured (time: $(date -u -d @$((end-start)) +"%T"))"
