#!/bin/bash
#
# This script initializes environment variables needed by scripts
# which are run to demonstrate Eucalyptus features
#
# It depends on per-host configuration files which define variables
# associated with each environment, which are then set as environment
# variables below in the repeatable demo format.
#
# You should create one configuration file named after the host which
# will run the CLC component, and then symlinks named after any additional
# hosts in the environment which point to this file, so all hosts in
# an environment use a single consistent configuration, and the relationship
# is clear in the filesystem.
#
# This script must be sourced to set the environment variables in the parent
# shell for the other scripts to see them. Otherwise it will have no effect.
# So, test for this first. Another side effect is this shell can't exit on
# error, so we must use the "valid" variable to test if the logic should be
# run after validation. This changes some of the conventions and functions
# in this script, so it's different than all others in this project.
#

#  1. Initalize Environment

if [ $0 = $BASH_SOURCE ]; then
    echo "You must source this script to set the ENV variables for other demo scripts"
    exit 1
fi

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

valid=y
step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
environment=$(hostname -s)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-e environment]"
    echo "  -I              non-interactive"
    echo "  -s              slower: increase pauses by 25%"
    echo "  -f              faster: reduce pauses by 25%"
    echo "  -e environment  environment configuration (default: $environment)"
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
                valid=n;;
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
                valid=n;;
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

OPTIND=1 # workaround needed when sourcing a script for getopts to work as expected

while getopts Isfe:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    e)  environment="$OPTARG";;
    ?)  usage
        valid=n;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $valid = y ]; then
    if [[ $environment =~ ^([a-zA-Z0-9_-]*)$ ]]; then
        envfile=$confdir/$environment.txt

        if [ ! -r $envfile ]; then
            echo "-e $environment invalid: can't find conf file: $envfile"
            valid=n
        fi
    else
        echo "-e $environment illegal: must consist of a-z, A-Z, 0-9, '-' or '_' characters"
        valid=n
    fi
fi


#  5. Initialize Demo Environment

start=$(date +%s)

if [ $valid = y ]; then
    source $envfile

    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Initialize Environment"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "export AWS_DEFAULT_REGION=\"$dns_region\""
    echo 
    echo "export EUCA_VNET_MODE=\"$vnet_mode\""
    echo "export EUCA_VNET_PRIVINTERFACE=\"$vnet_privinterface\""
    echo "export EUCA_VNET_PUBINTERFACE=\"$vnet_pubinterface\""
    echo "export EUCA_VNET_BRIDGE=\"$vnet_bridge\""
    echo "export EUCA_VNET_PUBLICIPS=\"$vnet_publicips\""
    echo "export EUCA_VNET_SUBNET=\"$vnet_subnet\""
    echo "export EUCA_VNET_NETMASK=\"$vnet_netmask\""
    echo "export EUCA_VNET_ADDRSPERNET=\"$vnet_addrspernet\""
    echo "export EUCA_VNET_DNS=\"$vnet_dns\""
    echo
    echo "export EUCA_CLC_HOST_NAME=\"$clc_host_name\""
    echo "export EUCA_CLC_DOMAIN_NAME=\"$clc_domain_name\""
    echo "export EUCA_CLC_PUBLIC_IP=$clc_public_ip"
    echo "export EUCA_CLC_PRIVATE_IP=$clc_private_ip"
    echo
    echo "export EUCA_UFS_HOST_NAME=\"$ufs_host_name\""
    echo "export EUCA_UFS_DOMAIN_NAME=\"$ufs_domain_name\""
    echo "export EUCA_UFS_PUBLIC_IP=$ufs_public_ip"
    echo "export EUCA_UFS_PRIVATE_IP=$ufs_private_ip"
    echo
    echo "export EUCA_MC_HOST_NAME=\"$mc_host_name\""
    echo "export EUCA_MC_DOMAIN_NAME=\"$mc_domain_name\""
    echo "export EUCA_MC_PUBLIC_IP=$mc_public_ip"
    echo "export EUCA_MC_PRIVATE_IP=$mc_private_ip"
    echo
    echo "export EUCA_CC_HOST_NAME=\"$cc_host_name\""
    echo "export EUCA_CC_DOMAIN_NAME=\"$cc_domain_name\""
    echo "export EUCA_CC_PUBLIC_IP=$cc_public_ip"
    echo "export EUCA_CC_PRIVATE_IP=$cc_private_ip"
    echo
    echo "export EUCA_SC_HOST_NAME=\"$sc_host_name\""
    echo "export EUCA_SC_DOMAIN_NAME=\"$sc_domain_name\""
    echo "export EUCA_SC_PUBLIC_IP=$sc_public_ip"
    echo "export EUCA_SC_PRIVATE_IP=$sc_private_ip"
    echo
    echo "export EUCA_OSP_HOST_NAME=\"$osp_host_name\""
    echo "export EUCA_OSP_DOMAIN_NAME=\"$osp_domain_name\""
    echo "export EUCA_OSP_PUBLIC_IP=$osp_public_ip"
    echo "export EUCA_OSP_PRIVATE_IP=$osp_private_ip"
    echo
    echo "export EUCA_NC1_HOST_NAME=\"$nc1_host_name\""
    echo "export EUCA_NC1_DOMAIN_NAME=\"$nc1_domain_name\""
    echo "export EUCA_NC1_PUBLIC_IP=$nc1_public_ip"
    echo "export EUCA_NC1_PRIVATE_IP=$nc1_private_ip"

    if [ -n "$nc2_host_name" ]; then
        echo
        echo "export EUCA_NC2_HOST_NAME=\"$nc2_host_name\""
        echo "export EUCA_NC2_DOMAIN_NAME=\"$nc2_domain_name\""
        echo "export EUCA_NC2_PUBLIC_IP=$nc2_public_ip"
        echo "export EUCA_NC2_PRIVATE_IP=$nc2_private_ip"
    fi

    echo
    echo "export EUCA_DNS_HOST_NAME=\"$dns_host_name\""
    echo "export EUCA_DNS_DOMAIN_NAME=\"$dns_domain_name\""
    echo "export EUCA_DNS_PUBLIC_IP=$dns_public_ip"
    echo "export EUCA_DNS_PRIVATE_IP=$dns_private_ip"
    echo "export EUCA_DNS_MODE=\"$dns_mode\""
    echo "export EUCA_DNS_TIMEOUT=\"$dns_timeout\""
    echo "export EUCA_DNS_LOADBALANCER_TTL=\"$dns_loadbalancer_ttl\""
    echo "export EUCA_DNS_REGION=\"$dns_region\""
    echo "export EUCA_DNS_REGION_DOMAIN=\"$dns_region_domain\""
    echo "export EUCA_DNS_LOADBALANCER_SUBDOMAIN=\"$dns_loadbalancer_subdomain\""
    echo "export EUCA_DNS_INSTANCE_SUBDOMAIN=\"$dns_instance_subdomain\""
    echo
    echo "export EUCA_INSTALL_MODE=\"$install_mode\""
    echo
    echo "env | sort | grep ^EUCA_"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# export AWS_DEFAULT_REGION=\"$dns_region\""
        export AWS_DEFAULT_REGION="$dns_region"
        echo
        echo "# export EUCA_VNET_MODE=\"$vnet_mode\""
        export EUCA_VNET_MODE="$vnet_mode"
        echo "# export EUCA_VNET_PRIVINTERFACE=\"$vnet_privinterface\""
        export EUCA_VNET_PRIVINTERFACE="$vnet_privinterface"
        echo "# export EUCA_VNET_PUBINTERFACE=\"$vnet_pubinterface\""
        export EUCA_VNET_PUBINTERFACE="$vnet_pubinterface"
        echo "# export EUCA_VNET_BRIDGE=\"$vnet_bridge\""
        export EUCA_VNET_BRIDGE="$vnet_bridge"
        echo "# export EUCA_VNET_PUBLICIPS=\"$vnet_publicips\""
        export EUCA_VNET_PUBLICIPS="$vnet_publicips"
        echo "# export EUCA_VNET_SUBNET=\"$vnet_subnet\""
        export EUCA_VNET_SUBNET="$vnet_subnet"
        echo "# export EUCA_VNET_NETMASK=\"$vnet_netmask\""
        export EUCA_VNET_NETMASK="$vnet_netmask"
        echo "# export EUCA_VNET_ADDRSPERNET=\"$vnet_addrspernet\""
        export EUCA_VNET_ADDRSPERNET="$vnet_addrspernet"
        echo "# export EUCA_VNET_DNS=\"$vnet_dns\""
        export EUCA_VNET_DNS="$vnet_dns"
        pause

        echo "# export EUCA_CLC_HOST_NAME=\"$clc_host_name\""
        export EUCA_CLC_HOST_NAME="$clc_host_name"
        echo "# export EUCA_CLC_DOMAIN_NAME=\"$clc_domain_name\""
        export EUCA_CLC_DOMAIN_NAME="$clc_domain_name"
        echo "# export EUCA_CLC_PUBLIC_IP=$clc_public_ip"
        export EUCA_CLC_PUBLIC_IP=$clc_public_ip
        echo "# export EUCA_CLC_PRIVATE_IP=$clc_private_ip"
        export EUCA_CLC_PRIVATE_IP=$clc_private_ip
        pause

        echo "# export EUCA_UFS_HOST_NAME=\"$ufs_host_name\""
        export EUCA_UFS_HOST_NAME="$ufs_host_name"
        echo "# export EUCA_UFS_DOMAIN_NAME=\"$ufs_domain_name\""
        export EUCA_UFS_DOMAIN_NAME="$ufs_domain_name"
        echo "# export EUCA_UFS_PUBLIC_IP=$ufs_public_ip"
        export EUCA_UFS_PUBLIC_IP=$ufs_public_ip
        echo "# export EUCA_UFS_PRIVATE_IP=$ufs_private_ip"
        export EUCA_UFS_PRIVATE_IP=$ufs_private_ip
        pause

        echo "# export EUCA_MC_HOST_NAME=\"$mc_host_name\""
        export EUCA_MC_HOST_NAME="$mc_host_name"
        echo "# export EUCA_MC_DOMAIN_NAME=\"$mc_domain_name\""
        export EUCA_MC_DOMAIN_NAME="$mc_domain_name"
        echo "# export EUCA_MC_PUBLIC_IP=$mc_public_ip"
        export EUCA_MC_PUBLIC_IP=$mc_public_ip
        echo "# export EUCA_MC_PRIVATE_IP=$mc_private_ip"
        export EUCA_MC_PRIVATE_IP=$mc_private_ip
        pause

        echo "# export EUCA_CC_HOST_NAME=\"$cc_host_name\""
        export EUCA_CC_HOST_NAME="$cc_host_name"
        echo "# export EUCA_CC_DOMAIN_NAME=\"$cc_domain_name\""
        export EUCA_CC_DOMAIN_NAME="$cc_domain_name"
        echo "# export EUCA_CC_PUBLIC_IP=$cc_public_ip"
        export EUCA_CC_PUBLIC_IP=$cc_public_ip
        echo "# export EUCA_CC_PRIVATE_IP=$cc_private_ip"
        export EUCA_CC_PRIVATE_IP=$cc_private_ip
        pause

        echo "# export EUCA_SC_HOST_NAME=\"$sc_host_name\""
        export EUCA_SC_HOST_NAME="$sc_host_name"
        echo "# export EUCA_SC_DOMAIN_NAME=\"$sc_domain_name\""
        export EUCA_SC_DOMAIN_NAME="$sc_domain_name"
        echo "# export EUCA_SC_PUBLIC_IP=$sc_public_ip"
        export EUCA_SC_PUBLIC_IP=$sc_public_ip
        echo "# export EUCA_SC_PRIVATE_IP=$sc_private_ip"
        export EUCA_SC_PRIVATE_IP=$sc_private_ip
        pause

        echo "# export EUCA_OSP_HOST_NAME=\"$osp_host_name\""
        export EUCA_OSP_HOST_NAME="$osp_host_name"
        echo "# export EUCA_OSP_DOMAIN_NAME=\"$osp_domain_name\""
        export EUCA_OSP_DOMAIN_NAME="$osp_domain_name"
        echo "# export EUCA_OSP_PUBLIC_IP=$osp_public_ip"
        export EUCA_OSP_PUBLIC_IP=$osp_public_ip
        echo "# export EUCA_OSP_PRIVATE_IP=$osp_private_ip"
        export EUCA_OSP_PRIVATE_IP=$osp_private_ip
        pause

        echo "# export EUCA_NC1_HOST_NAME=\"$nc1_host_name\""
        export EUCA_NC1_HOST_NAME="$nc1_host_name"
        echo "# export EUCA_NC1_DOMAIN_NAME=\"$nc1_domain_name\""
        export EUCA_NC1_DOMAIN_NAME="$nc1_domain_name"
        echo "# export EUCA_NC1_PUBLIC_IP=$nc1_public_ip"
        export EUCA_NC1_PUBLIC_IP=$nc1_public_ip
        echo "# export EUCA_NC1_PRIVATE_IP=$nc1_private_ip"
        export EUCA_NC1_PRIVATE_IP=$nc1_private_ip
        pause

        if [ -n "$nc2_host_name" ]; then
            echo "# export EUCA_NC2_HOST_NAME=\"$nc2_host_name\""
            export EUCA_NC2_HOST_NAME="$nc2_host_name"
            echo "# export EUCA_NC2_DOMAIN_NAME=\"$nc2_domain_name\""
            export EUCA_NC2_DOMAIN_NAME="$nc2_domain_name"
            echo "# export EUCA_NC2_PUBLIC_IP=$nc2_public_ip"
            export EUCA_NC2_PUBLIC_IP=$nc2_public_ip
            echo "# export EUCA_NC2_PRIVATE_IP=$nc2_private_ip"
            export EUCA_NC2_PRIVATE_IP=$nc2_private_ip
            pause
        fi

        echo "# export EUCA_DNS_HOST_NAME=\"$dns_host_name\""
        export EUCA_DNS_HOST_NAME="$dns_host_name"
        echo "# export EUCA_DNS_DOMAIN_NAME=\"$dns_domain_name\""
        export EUCA_DNS_DOMAIN_NAME="$dns_domain_name"
        echo "# export EUCA_DNS_PUBLIC_IP=$dns_public_ip"
        export EUCA_DNS_PUBLIC_IP=$dns_public_ip
        echo "# export EUCA_DNS_PRIVATE_IP=$dns_private_ip"
        export EUCA_DNS_PRIVATE_IP=$dns_private_ip
        echo "# export EUCA_DNS_MODE=\"$dns_mode\""
        export EUCA_DNS_MODE="$dns_mode"
        echo "# export EUCA_DNS_TIMEOUT=\"$dns_timeout\""
        export EUCA_DNS_TIMEOUT="$dns_timeout"
        echo "# export EUCA_DNS_LOADBALANCER_TTL=\"$dns_loadbalancer_ttl\""
        export EUCA_DNS_LOADBALANCER_TTL="$dns_loadbalancer_ttl"
        echo "# export EUCA_DNS_REGION=\"$dns_region\""
        export EUCA_DNS_REGION="$dns_region"
        echo "# export EUCA_DNS_REGION_DOMAIN=\"$dns_region_domain\""
        export EUCA_DNS_REGION_DOMAIN="$dns_region_domain"
        echo "# export EUCA_DNS_LOADBALANCER_SUBDOMAIN=\"$dns_loadbalancer_subdomain\""
        export EUCA_DNS_LOADBALANCER_SUBDOMAIN="$dns_loadbalancer_subdomain"
        echo "# export EUCA_DNS_INSTANCE_SUBDOMAIN=\"$dns_instance_subdomain\""
        export EUCA_DNS_INSTANCE_SUBDOMAIN="$dns_instance_subdomain"
        pause

        echo "# export EUCA_INSTALL_MODE=\"$install_mode\""
        export EUCA_INSTALL_MODE="$install_mode"
        pause

        echo "# env | sort | grep ^EUCA_"
        env | sort | grep ^EUCA_

        next 50
    fi


    end=$(date +%s)

    echo
    case $(uname) in
      Darwin)
        echo "Environment configured (time: $(date -u -r $((end-start)) +"%T"))";;
      *)
        echo "Environment configured (time: $(date -u -d @$((end-start)) +"%T"))";;
    esac
fi
