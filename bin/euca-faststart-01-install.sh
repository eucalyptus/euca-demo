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

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
percent_min=0
percent_max=500
run_default=10
pause_default=2
next_default=10

interactive=1
account=eucalyptus
run_percent=100
pause_percent=100
next_percent=100


#  2. Define functions

usage () {
    echo "Usage: $(basename $0)"
    echo "           [-I [-r run_percent] [-p pause_percent] [-n next_percent]]"
    echo "  -I                non-interactive"
    echo "  -r run_percent    run prompt timing adjustment % (default: $run_percent)"
    echo "  -p pause_percent  pause delay timing adjustment % (default: $pause_percent)"
    echo "  -n next_percent   next prompt timing adjustment % (default: $next_percent)"
}

run() {
    if [ -z $1 ]; then
        ((seconds=$run_default * $run_percent / 100))
    else
        ((seconds=$1 * $run_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$pause_default * $pause_percent / 100))
    else
        ((seconds=$1 * $pause_percent / 100))
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
    if [ -z $1 ]; then
        ((seconds=$next_default * $next_percent / 100))
    else
        ((seconds=$1 * $next_percent / 100))
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

while getopts Ir:p:n:? arg; do
    case $arg in
    I)  interactive=0;;
    r)  run_percent="$OPTARG";;
    p)  pause_percent="$OPTARG";;
    n)  next_percent="$OPTARG";;
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

if [[ $run_percent =~ ^[0-9]+$ ]]; then
    if ((run_percent < percent_min || run_percent > percent_max)); then
        echo "-r $run_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $run_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $pause_percent =~ ^[0-9]+$ ]]; then
    if ((pause_percent < percent_min || pause_percent > percent_max)); then
        echo "-p $pause_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-p $pause_percent illegal: must be a positive integer"
    exit 4
fi

if [[ $next_percent =~ ^[0-9]+$ ]]; then
    if ((next_percent < percent_min || next_percent > percent_max)); then
        echo "-r $next_percent invalid: value must be between $percent_min and $percent_max"
        exit 5
    fi
else
    echo "-r $next_percent illegal: must be a positive integer"
    exit 4
fi

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo "This script should be run only on a Cloud Controller"
    exit 20
fi


#  5. Execute Demo

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

run

if [ $choice = y ]; then
    echo
    pushd $HOME &> /dev/null
    echo "# bash <(curl -Ls eucalyptus.com/install)"
    bash <(curl -Ls eucalyptus.com/install)
    popd &> /dev/null

    next 5
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
echo "source /root/creds/eucalyptus/admin/eucarc"

run

if [ $choice = y ]; then
    echo
    echo "# mkdir -p /root/creds/eucalyptus/admin"
    mkdir -p /root/creds/eucalyptus/admin
    echo "# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
    unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/eucalyptus/admin/eucarc    # invisibly fix deprecation message
    pause

    echo "# source /root/creds/eucalyptus/admin/eucarc"
    source /root/creds/eucalyptus/admin/eucarc

    next 5
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

run 5

if [ $choice = y ]; then
    echo
    echo "# euca-describe-addresses verbose"
    euca-describe-addresses verbose

    next 5
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

run 5

if [ $choice = y ]; then
    echo
    echo "# euca-describe-services | cut -f1-5"
    euca-describe-services | cut -f1-5

    next
fi


echo
echo "Eucalyptus installed"
