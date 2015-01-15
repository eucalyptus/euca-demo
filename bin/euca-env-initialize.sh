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

if [ "$0" = "$BASH_SOURCE" ]; then
    echo "You must source this script to set the ENV variables for other demo scripts"
    exit 1
fi


#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
interactive=1
step_wait=0
pause_wait=0
environment=$(hostname -s)
valid=y


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I] [-e environment]"
    echo "  -I             non-interactive"
    echo "  -e environment environment configuration (default: $environment)"
}

pause() {
    if [ "$interactive" = 1 ]; then
        echo "#"
        read pause
        echo -en "\033[1A\033[2K"    # undo newline from read
    else
        echo "#"
        sleep $pause_wait
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed (y,n,q)[y]"
        echo
        echo -n "$prompt2"
        read choice
        case "$choice" in
            "" | "y" | "Y" | "yes" | "Yes") choice=y ;;
            "n" | "N" | "no" | "No") choice=n ;;
             *) echo "cancelled"
                valid=n;;
        esac
    else
        echo
        seconds=$step_wait
        echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
        while ((seconds > 0)); do
            if ((seconds < 10 || seconds % 10 == 0)); then
                echo -n -e "Continuing in $(printf '%2d' $seconds) seconds...\r"
            fi
            sleep 1
            ((seconds--))
        done
        echo
        choice=y
    fi
}


#  3. Parse command line options

while getopts Ie: arg; do
    case $arg in
    I)  interactive=0;;
    e)  environment="$OPTARG";;
    ?)  usage
        valid=n;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [[ $step_wait =~ ^[0-9]+$ ]]; then
    if ((step_wait < step_min || step_wait > step_max)); then
        echo "-s $step_wait invalid: value must be between $step_min and $step_max seconds"
        valid=n
    fi
else
    echo "-s $step_wait illegal: must be a positive integer"
    valid=n
fi

if [[ $pause_wait =~ ^[0-9]+$ ]]; then
    if ((pause_wait < pause_min || pause_wait > pause_max)); then
        echo "-p $pause_wait invalid: value must be between $pause_min and $pause_max seconds"
        valid=n
    fi
else
    echo "-p $pause_wait illegal: must be a positive integer"
    valid=n
fi

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

if [ $valid = y ]; then
    source $envfile

    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo " $(printf '%2d' $step). Initialize Environment"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
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
    echo "export EUCA_DNS_BASE_DOMAIN=\"$dns_base_domain\""
    echo "export EUCA_DNS_LOADBALANCER_SUBDOMAIN=\"$dns_loadbalancer_subdomain\""
    echo "export EUCA_DNS_INSTANCE_SUBDOMAIN=\"$dns_instance_subdomain\""
    echo
    echo "env | sort | grep ^EUCA_"

    choose "Execute"

    if [ $choice = y ]; then
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
        echo "# export EUCA_DNS_BASE_DOMAIN=\"$dns_base_domain\""
        export EUCA_DNS_BASE_DOMAIN="$dns_base_domain"
        echo "# export EUCA_DNS_LOADBALANCER_SUBDOMAIN=\"$dns_loadbalancer_subdomain\""
        export EUCA_DNS_LOADBALANCER_SUBDOMAIN="$dns_loadbalancer_subdomain"
        echo "# export EUCA_DNS_INSTANCE_SUBDOMAIN=\"$dns_instance_subdomain\""
        export EUCA_DNS_INSTANCE_SUBDOMAIN="$dns_instance_subdomain"
        pause

        echo "# env | sort | grep ^EUCA_"
        env | sort | grep ^EUCA_

        choose "Continue"
    fi

    echo
    echo "Environment configured"
fi
