#!/bin/bash
#
# This script initializes dependencies prior to installing Eucalyptus
#
# This script isn't smart enough to figure out various network modes, and is
# currently hard-coded for the course's use of the MANANGED-NOVLAN mode

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
step_min=0
step_wait=15
step_max=120
pause_min=0
pause_wait=2
pause_max=30

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I [-s step_wait] [-p pause_wait]]"
    echo "  -I             non-interactive"
    echo "  -s step_wait   seconds per step (default: $step_wait)"
    echo "  -p pause_wait  seconds per pause (default: $pause_wait)"
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
                exit 2;;
        esac
    else
        echo "Waiting $step_wait seconds..."
        sleep $step_wait
        choice=y
    fi
}


#  3. Parse command line options

while getopts Is:p: arg; do
    case $arg in
    I)  interactive=0;;
    s)  step_wait="$OPTARG";;
    p)  pause_wait="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

if [[ $step_wait =~ ^[0-9]+$ ]]; then
    if ((step_wait < step_min || step_wait > step_max)); then
        echo "-s $step_wait invalid: value must be between $step_min and $step_max seconds"
        exit 5
    fi
else
    echo "-s $step_wait illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_wait =~ ^[0-9]+$ ]]; then
    if ((pause_wait < pause_min || pause_wait > pause_max)); then
        echo "-p $pause_wait invalid: value must be between $pause_min and $pause_max seconds"
        exit 7
    fi
else
    echo "-p $pause_wait illegal: must be a positive integer"
    exit 6
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y
[ "$(hostname -s)" = "$EUCA_UFS_HOST_NAME" ] && is_ufs=y
[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y
[ "$(hostname -s)" = "$EUCA_CC_HOST_NAME" ] && is_cc=y
[ "$(hostname -s)" = "$EUCA_SC_HOST_NAME" ] && is_sc=y
[ "$(hostname -s)" = "$EUCA_OSP_HOST_NAME" ] && is_osp=y
[ "$(hostname -s)" = "$EUCA_NC1_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC2_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC3_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC4_HOST_NAME" ] && is_nc=y


#  5. Execute Course Lab

((++step))
if [ $is_cc = y -o $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install bridge utilities package"
    echo "    - This step is only run on the cluster and node controller hosts"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "yum -y install bridge-utils"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# yum -y install bridge-utils"
        yum -y install bridge-utils

        choose "Continue"
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create bridge"
    echo "    - This step is only run on the node controller host"
    echo "    - This bridge connects between the public ethernet adapter"
    echo "      and virtual machine instance virtual ethernet adapters"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "echo << EOF > /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE"
    echo "DEVICE=$EUCA_VNET_BRIDGE"
    echo "TYPE=Bridge"
    echo "BOOTPROTO=dhcp"
    echo "PERSISTENT_DHCLIENT=yes"
    echo "ONBOOT=yes"
    echo "DELAY=0"
    echo "EOF"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# echo << EOF > /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE"
        echo "> DEVICE=$EUCA_VNET_BRIDGE"
        echo "> TYPE=Bridge"
        echo "> BOOTPROTO=dhcp"
        echo "> PERSISTENT_DHCLIENT=yes"
        echo "> ONBOOT=yes"
        echo "> DELAY=0"
        echo "> EOF"
        echo "DEVICE=$EUCA_VNET_BRIDGE"  > /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE
        echo "TYPE=Bridge"              >> /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE
        echo "BOOTPROTO=dhcp"           >> /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE
        echo "PERSISTENT_DHCLIENT=yes"  >> /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE
        echo "ONBOOT=yes"               >> /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE
        echo "DELAY=0"                  >> /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_BRIDGE

        choose "Continue"
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Adjust public ethernet interface"
    echo "    - This step is only run on the node controller host"
    echo "    - Associate the interface with the bridge"
    echo "    - Remove the interface's IP address (moves to bridge)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "sed -i -e \"\\\$aBRIDGE=$EUCA_VNET_BRIDGE\" \\"
    echo "       -e \"/^BOOTPROTO=/s/=.*\$/=none/\" \\"
    echo "       -e \"/^PERSISTENT_DHCLIENT=/d\" \\"
    echo "       -e \"/^DNS.=/d\" /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_PRIVINTERFACE"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# sed -i -e \"\\\$aBRIDGE=$EUCA_VNET_BRIDGE\" \\"
        echo ">        -e \"/^BOOTPROTO=/s/=.*\$/=none/\" \\"
        echo ">        -e \"/^PERSISTENT_DHCLIENT=/d\" \\"
        echo ">        -e \"/^DNS.=/d\" /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_PRIVINTERFACE"
        sed -i -e "\$aBRIDGE=$EUCA_VNET_BRIDGE" \
               -e "/^BOOTPROTO=/s/=.*$/=none/" \
               -e "/^PERSISTENT_DHCLIENT=/d" \
               -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-$EUCA_VNET_PRIVINTERFACE

        choose "Continue"
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Restart networking"
    echo "    - This step is only run on the node controller host"
    echo "    - Can lose connectivity here, make sure you have alternate way in"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "service network restart"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# service network restart"
        service network restart

        choose "Continue"
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Disable firewall"
echo "    - To prevent unexpected issues"
echo "    - Can be re-enabled after setup with appropriate ports open"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "service iptables stop"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# service iptables stop"
    service iptables stop

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Disable SELinux"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "sed -i -e \"/^SELINUX=/s/=.*\$/=permissive/\" /etc/selinux/config"
echo
echo "setenforce 0"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# sed -i -e \"/^SELINUX=/s/=.*\$/=permissive/\" /etc/selinux/config"
    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config
    pause

    echo "# setenforce 0"
    setenforce 0

    choose "Continue"
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install and Configure the NTP service"
echo "    - It is critical that NTP be running and accurate on all hosts"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "yum -y install ntp"
echo
echo "chkconfig ntpd on"
echo "service ntpd start"
echo
echo "ntpdate -u  0.centos.pool.ntp.org"
echo "hwclock --systohc"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# yum -y install ntp"
    yum -y install ntp
    pause

    echo "# chkconfig ntpd on"
    chkconfig ntpd on
    echo "# service ntpd start"
    service ntpd start
    pause

    echo "# ntpdate -u  0.centos.pool.ntp.org"
    ntpdate -u  0.centos.pool.ntp.org
    echo "# hwclock --systohc"
    hwclock --systohc

    choose "Continue"
fi


# Skipping mail relay config for now
# Just talked to Kyle yesterday about how we do this, still need to write the code
# to use GMail as relay and then test it. May need to add parameter to specify email
# address of user running this script.


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure packet routing"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf"
if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    echo "sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf"
fi
echo
echo "sysctl -p"
echo
echo "cat /proc/sys/net/ipv4/ip_forward"
if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    echo "cat /proc/sys/net/bridge/bridge-nf-call-iptables"
fi

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf"
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        echo "# sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf"
        sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf
    fi
    pause

    echo "# sysctl -p"
    sysctl -p 2> /dev/null    # prevent display of missing bridge errors
    pause

    echo "# cat /proc/sys/net/ipv4/ip_forward"
    cat /proc/sys/net/ipv4/ip_forward
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        echo "cat /proc/sys/net/bridge/bridge-nf-call-iptables"
        cat /proc/sys/net/bridge/bridge-nf-call-iptables
    fi

    choose "Continue"
fi


echo
echo "Dependencies initialized"
