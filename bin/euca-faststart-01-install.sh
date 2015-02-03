#!/bin/bash
#
# This script installs Eucalyptus via the Faststart method
#
# This script is eventually designed to support any combination, but was initially
# written to automate the cloud administrator course which uses a 2-node configuration.
# It has not been tested to work in other combinations.
#
# Each student MUST run all prior scripts on all nodes prior to this script.
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

external_faststart_url=eucalyptus.com/install
internal_faststart_url=mirror.mjc.prc.eucalyptus-systems.com/install

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
faststart_url=$external_faststart_url


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-l]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -l  Use local mirror for Faststart script (uses local yum repos)"
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

while getopts Isfl? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    l)  faststart_url=$internal_faststart_url;;
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


#  5. Execute Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Install"
echo "    - Responses to questions:"
echo "      Laptop power warning: Continue?                          <enter>"
echo "      DHCP warning: Continue Anyway?                           y"
echo "      What's the physical NIC that will be used for bridging?  <enter>"
echo "      What's the IP address of this host?                      <enter>"
echo "      What's the gateway for this host?                        <enter>"
echo "      What's the netmask for this host?                        <enter>"
echo "      What's the subnet for this host?                         <enter>"
echo "      What's the first address of your available IP range?     ${EUCA_VNET_PUBLICIPS%-*}"
echo "      What's the last address of your available IP range?      ${EUCA_VNET_PUBLICIPS#*-}"
echo "      Install additional services? [Y/n]                       <enter>"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "bash <(curl -Ls eucalyptus.com/install)"

run 50

if [ $choice = y ]; then
    echo
    pushd $HOME &> /dev/null
    echo "# bash <(curl -Ls eucalyptus.com/install)"
    bash <(curl -Ls $faststart_url)
    popd &> /dev/null

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Move Credentials into Demo Directory Structure"
echo "    - We need to create additional accounts and users, so move"
echo "      the Eucalyptus Administrator credentials into a more"
echo "      hierarchical credentials storage directory structure"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p /root/creds/eucalyptus/admin"
echo "unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
echo
echo "cat /root/creds/eucalyptus/admin/eucarc"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

run 50

if [ $choice = y ]; then
    echo
    echo "# mkdir -p /root/creds/eucalyptus/admin"
    mkdir -p /root/creds/eucalyptus/admin
    echo "# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
    unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
    pause

    echo "# cat /root/creds/eucalyptus/admin/eucarc"
    cat /root/creds/eucalyptus/admin/eucarc
    pause

    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Public IP addresses"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-addresses verbose"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-addresses verbose"
    euca-describe-addresses verbose

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo "    - Truncating normal output for readability"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-services | cut -f1-5"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-services | cut -f1-5"
    euca-describe-services | cut -f1-5

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus installed (time: $(date -u -d @$((end-start)) +"%T"))"
