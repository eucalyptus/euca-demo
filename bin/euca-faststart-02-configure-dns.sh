#!/bin/bash
#
# This script configures Eucalyptus DNS after a Faststart installation
#
# This should be run immediately after the Faststart installer completes
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
showdnsconfig=0
extended=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-d] [-e]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -d  display parent DNS server sample configuration"
    echo "  -e  extended confirmation of API calls"
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

while getopts Isfde? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    d)  showdnsconfig=1;;
    e)  extended=1;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: /root/creds/eucalyptus/admin/eucarc"
    sleep 2

    if [ -r /root/admin.zip ]; then
        echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
        mkdir -p /root/creds/eucalyptus/admin
        cp -a /root/admin.zip /root/creds/eucalyptus/admin.zip
        unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/
        sleep 2
    else
        echo "Could not convert FastStart Eucalyptus Administrator credentials!"
        echo "Expected to find: /root/admin.zip"
        exit 29
    fi
fi


#  5. Execute Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat /root/creds/eucalyptus/admin/eucarc"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

next

echo
echo "# cat /root/creds/eucalyptus/admin/eucarc"
cat /root/creds/eucalyptus/admin/eucarc
pause

echo "# source /root/creds/eucalyptus/admin/eucarc"
source /root/creds/eucalyptus/admin/eucarc

next


((++step))
if [ $EUCA_DNS_MODE = "PARENT" ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo " $(printf '%2d' $step). Configure Eucalyptus DNS Server"
    echo "    - Instances will use the parent DNS Server, which will delegate"
    echo "      Eucalyptus zones to the Cloud Controller DNS Server"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p system.dns.nameserver=$EUCA_DNS_HOST_NAME.$EUCA_DNS_DOMAIN_NAME"
    echo
    echo "euca-modify-property -p system.dns.nameserveraddress=$EUCA_DNS_PUBLIC_IP"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-property -p system.dns.nameserver=$EUCA_DNS_HOST_NAME.$EUCA_DNS_DOMAIN_NAME"
        euca-modify-property -p system.dns.nameserver=$EUCA_DNS_HOST_NAME.$EUCA_DNS_DOMAIN_NAME
        echo "#"
        echo "# euca-modify-property -p system.dns.nameserveraddress=$EUCA_DNS_PUBLIC_IP"
        euca-modify-property -p system.dns.nameserveraddress=$EUCA_DNS_PUBLIC_IP

        next 50
    fi
else
    clear
    echo
    echo "============================================================"
    echo
    echo " $(printf '%2d' $step). Configure Eucalyptus DNS Server"
    echo "    - Instances will use the Cloud Controller's DNS Server directly"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p system.dns.nameserver=ns1.$EUCA_DNS_BASE_DOMAIN"
    echo
    echo "euca-modify-property -p system.dns.nameserveraddress=$EUCA_CLC_PUBLIC_IP"
    
    run 50
    
    if [ $choice = y ]; then
        echo
        echo "# euca-modify-property -p system.dns.nameserver=ns1.$EUCA_DNS_BASE_DOMAIN"
        euca-modify-property -p system.dns.nameserver=ns1.$EUCA_DNS_BASE_DOMAIN
        echo "#"
        echo "# euca-modify-property -p system.dns.nameserveraddress=$EUCA_CLC_PUBLIC_IP"
        euca-modify-property -p system.dns.nameserveraddress=$EUCA_CLC_PUBLIC_IP
    
        next 50
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure DNS Timeout and TTL"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p dns.tcp.timeout_seconds=$EUCA_DNS_TIMEOUT"
echo
echo "euca-modify-property -p services.loadbalancing.dns_ttl=$EUCA_DNS_LOADBALANCER_TTL"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p dns.tcp.timeout_seconds=$EUCA_DNS_TIMEOUT"
    euca-modify-property -p dns.tcp.timeout_seconds=$EUCA_DNS_TIMEOUT
    echo "#"
    echo "# euca-modify-property -p services.loadbalancing.dns_ttl=$EUCA_DNS_LOADBALANCER_TTL"
    euca-modify-property -p services.loadbalancing.dns_ttl=$EUCA_DNS_LOADBALANCER_TTL

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure DNS Domain"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p system.dns.dnsdomain=$EUCA_DNS_BASE_DOMAIN"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p system.dns.dnsdomain=$EUCA_DNS_BASE_DOMAIN"
    euca-modify-property -p system.dns.dnsdomain=$EUCA_DNS_BASE_DOMAIN

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure DNS Sub-Domains"
echo
echo "============================================================"
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
echo "============================================================"
echo
echo " $(printf '%2d' $step). Enable DNS"
echo
echo "============================================================"
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
echo "============================================================"
echo
echo " $(printf '%2d' $step). Refresh Administrator Credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "rm -f /root/creds/eucalyptus/admin.zip"
echo
echo "euca-get-credentials -u admin /root/creds/eucalyptus/admin.zip"
echo
echo "unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/"
echo
echo "cat /root/creds/eucalyptus/admin/eucarc"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

run 50

if [ $choice = y ]; then
    echo
    echo "# mkdir -p /root/creds/eucalyptus/admin"
    mkdir -p /root/creds/eucalyptus/admin
    pause

    echo "# rm -f /root/creds/eucalyptus/admin.zip"
    rm -f /root/creds/eucalyptus/admin.zip
    pause

    echo "# euca-get-credentials -u admin /root/creds/eucalyptus/admin.zip"
    euca-get-credentials -u admin /root/creds/eucalyptus/admin.zip
    pause

    echo "# unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/"
    unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/
    if ! grep -s -q "export EC2_PRIVATE_KEY=" /root/creds/eucalyptus/admin/eucarc; then
        # invisibly fix missing environment variables needed for image import
        pk_pem=$(ls -1 /root/creds/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 /root/creds/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" /root/creds/eucalyptus/admin/eucarc
    fi
    if [ -r /root/eucarc ]; then
        # invisibly update Faststart credentials location
        cp -a /root/creds/eucalyptus/admin/eucarc /root/eucarc
    fi
    pause

    echo "# cat /root/creds/eucalyptus/admin/eucarc"
    cat /root/creds/eucalyptus/admin/eucarc
    pause

    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc
    pause

    next
fi


((++step))
if [ $showdnsconfig = 1 ]; then
    if [ $EUCA_DNS_MODE = "PARENT" ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo " $(printf '%2d' $step). Display Parent DNS Server Configuration"
        echo "    - This is an example of what changes need to be made on the"
        echo "      parent DNS server which will delgate DNS to Eucalyptus"
        echo "      for Eucalyptus DNS names used for instances, ELBs and"
        echo "      services"
        echo "    - You should make these changes to the parent DNS server"
        echo "      manually, once, outside of creating and running demos"
        echo "    - Instances will use the parent DNS Server, which will delegate"
        echo "      Eucalyptus zones to the Cloud Controller DNS Server"
        echo "    - This configuration is based on the BIND configuration"
        echo "      conventions used on the cs.prc.eucalyptus-systems.com DNS server"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "# Add these lines to /etc/named.conf on the parent DNS server"
        echo "         zone \"$EUCA_DNS_BASE_DOMAIN\" IN"
        echo "         {"
        echo "                 type master;"
        echo "                 file \"/etc/named/db.${EUCA_DNS_BASE_DOMAIN%%.*}\";"
        echo "         };"
        echo "#"
        echo "# Create the zone file on the parent DNS server"
        echo "# cat << EOF > /etc/named/db.${EUCA_DNS_BASE_DOMAIN%%.*}"
        echo "> ;"
        echo "> ; DNS zone for $EUCA_DNS_BASE_DOMAIN"
        echo "> ; - Eucalyptus configured to use Parent DNS server"
        echo "> ;"
        echo "> $TTL 1M"
        echo "> $ORIGIN $EUCA_DNS_BASE_DOMAIN"
        echo "> @                       SOA     ns1.${EUCA_DNS_BASE_DOMAIN#*.}. root.${EUCA_DNS_BASE_DOMAIN#*.}. ("
        echo ">                                 $(date +%Y%m%d)01      ; Serial"
        echo ">                                 1H              ; Refresh"
        echo ">                                 10M             ; Retry"
        echo ">                                 1D              ; Expire"
        echo ">                                 1H )            ; Negative Cache TTL"
        echo ">"
        echo ">                         NS      ns1.${EUCA_DNS_BASE_DOMAIN#*.}."
        echo ">"
        echo "> ns1                     A       $EUCA_CLC_PUBLIC_IP"
        echo ">"
        echo "> clc                     A       $EUCA_CLC_PUBLIC_IP"
        echo "> ufs                     A       $EUCA_UFS_PUBLIC_IP"
        echo ">"
        echo "> autoscaling             A       $EUCA_UFS_PUBLIC_IP"
        echo "> cloudformation          A       $EUCA_UFS_PUBLIC_IP"
        echo "> cloudwatch              A       $EUCA_UFS_PUBLIC_IP"
        echo "> compute                 A       $EUCA_UFS_PUBLIC_IP"
        echo "> euare                   A       $EUCA_UFS_PUBLIC_IP"
        echo "> loadbalancing           A       $EUCA_UFS_PUBLIC_IP"
        echo "> objectstorage           A       $EUCA_UFS_PUBLIC_IP"
        echo "> tokens                  A       $EUCA_UFS_PUBLIC_IP"
        echo ">"
        echo "> ${EUCA_DNS_INSTANCE_SUBDOMAIN#.}                   NS      ns1"
        echo "> ${EUCA_DNS_LOADBALANCER_SUBDOMAIN#.}                      NS      ns1"
        echo "> EOF"

        next 200
else
        clear
        echo
        echo "============================================================"
        echo
        echo " $(printf '%2d' $step). Display Parent DNS Server Configuration"
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
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "# Add these lines to /etc/named.conf on the parent DNS server"
        echo "         zone \"$EUCA_DNS_BASE_DOMAIN\" IN"
        echo "         {"
        echo "                 type master;"
        echo "                 file \"/etc/named/db.${EUCA_DNS_BASE_DOMAIN%%.*}\";"
        echo "         };"
        echo "#"
        echo "# Create the zone file on the parent DNS server"
        echo "> ;"
        echo "> ; DNS zone for $EUCA_DNS_BASE_DOMAIN"
        echo "> ; - Eucalyptus configured to use CLC as DNS server"
        echo ">"
        echo "# cat << EOF > /etc/named/db.${EUCA_DNS_BASE_DOMAIN%%.*}"
        echo "> $TTL 1M"
        echo "> $ORIGIN $EUCA_DNS_BASE_DOMAIN"
        echo "> @                       SOA     ns1 root ("
        echo ">                                 $(date +%Y%m%d)01      ; Serial"
        echo ">                                 1H              ; Refresh"
        echo ">                                 10M             ; Retry"
        echo ">                                 1D              ; Expire"
        echo ">                                 1H )            ; Negative Cache TTL"
        echo ">"
        echo ">                         NS      ns1"
        echo ">"
        echo "> ns1                     A       $EUCA_CLC_PUBLIC_IP"
        echo ">"
        echo "> ${EUCA_DNS_INSTANCE_SUBDOMAIN#.}                   NS      ns1"
        echo "> ${EUCA_DNS_LOADBALANCER_SUBDOMAIN#.}                      NS      ns1"
        echo "> EOF"
    
        next 200
    fi
fi

    
((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Confirm DNS resolution for Services"
echo "    - Confirm service URLS in eucarc resolve"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "dig +short compute.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short objectstorage.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short euare.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short tokens.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short autoscaling.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short cloudformation.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short cloudwatch.$EUCA_DNS_BASE_DOMAIN"
echo
echo "dig +short loadbalancing.$EUCA_DNS_BASE_DOMAIN"

run 50

if [ $choice = y ]; then
    echo
    echo "# dig +short compute.$EUCA_DNS_BASE_DOMAIN"
    dig +short compute.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short objectstorage.$EUCA_DNS_BASE_DOMAIN"
    dig +short objectstorage.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short euare.$EUCA_DNS_BASE_DOMAIN"
    dig +short euare.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short tokens.$EUCA_DNS_BASE_DOMAIN"
    dig +short tokens.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short autoscaling.$EUCA_DNS_BASE_DOMAIN"
    dig +short autoscaling.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short cloudformation.$EUCA_DNS_BASE_DOMAIN"
    dig +short cloudformation.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short cloudwatch.$EUCA_DNS_BASE_DOMAIN"
    dig +short cloudwatch.$EUCA_DNS_BASE_DOMAIN
    pause

    echo "# dig +short loadbalancing.$EUCA_DNS_BASE_DOMAIN"
    dig +short loadbalancing.$EUCA_DNS_BASE_DOMAIN

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Confirm API commands work with new URLs"
echo "    - Confirm service describe commands still work"
echo
echo "============================================================"
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
