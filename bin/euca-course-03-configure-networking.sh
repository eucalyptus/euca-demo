#/bin/bash
#
# This script configures Eucalyptus networking
#
# This script should be run on all hosts.
#
# Each student MUST run all prior scripts on relevant hosts prior to this script.
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n
[ "$(hostname -s)" = "$EUCA_UFS_HOST_NAME" ] && is_ufs=y || is_ufs=n
[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ]  && is_mc=y  || is_mc=n
[ "$(hostname -s)" = "$EUCA_CC_HOST_NAME" ]  && is_cc=y  || is_cc=n
[ "$(hostname -s)" = "$EUCA_SC_HOST_NAME" ]  && is_sc=y  || is_sc=n
[ "$(hostname -s)" = "$EUCA_OSP_HOST_NAME" ] && is_osp=y || is_osp=n
[ "$(hostname -s)" = "$EUCA_NC1_HOST_NAME" ] && is_nc=y  || is_nc=n
[ "$(hostname -s)" = "$EUCA_NC2_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC3_HOST_NAME" ] && is_nc=y
[ "$(hostname -s)" = "$EUCA_NC4_HOST_NAME" ] && is_nc=y
 
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


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
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

while getopts Isf? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment


#  5. Execute Course Lab

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Networking"
echo "    - We'll save the original file first"
echo "    - Then we'll use sed to quickly change parameters"
echo "    - Then we'll diff the modified and original files to show changes"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig"
echo
echo "sed -i -e \"s/^VNET_MODE=.*$/VNET_MODE=\\\"$EUCA_VNET_MODE\\\"/\" \\"
echo "       -e \"s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\\\"$EUCA_VNET_PRIVINTERFACE\\\"/\" \\"
echo "       -e \"s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\\\"$EUCA_VNET_PUBINTERFACE\\\"/\" \\"
echo "       -e \"s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\\\"$EUCA_VNET_BRIDGE\\\"/\" \\"
echo "       -e \"s/^#VNET_PUBLICIPS=.*$/VNET_PUBLICIPS=\\\"$EUCA_VNET_PUBLICIPS\\\"/\" \\"
echo "       -e \"s/^#VNET_SUBNET=.*$/VNET_SUBNET=\\\"$EUCA_VNET_SUBNET\\\"/\" \\"
echo "       -e \"s/^#VNET_NETMASK=.*$/VNET_NETMASK=\\\"$EUCA_VNET_NETMASK\\\"/\" \\"
echo "       -e \"s/^#VNET_ADDRSPERNET=.*$/VNET_ADDRSPERNET=\\\"$EUCA_VNET_ADDRSPERNET\\\"/\" \\"
echo "       -e \"s/^#VNET_DNS.*$/VNET_DNS=\\\"$EUCA_VNET_DNS\\\"/\" /etc/eucalyptus/eucalyptus.conf"
echo
echo "diff /etc/eucalyptus/eucalyptus.conf{,.orig}"

run
             
if [ $choice = y ]; then
    echo
    echo "# cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig"
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig
    pause

    echo "# sed -i -e \"s/^VNET_MODE=.*$/VNET_MODE=\\\"$EUCA_VNET_MODE\\\"/\" \\"
    echo ">        -e \"s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\\\"$EUCA_VNET_PRIVINTERFACE\\\"/\" \\"
    echo ">        -e \"s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\\\"$EUCA_VNET_PUBINTERFACE\\\"/\" \\"
    echo ">        -e \"s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\\\"$EUCA_VNET_BRIDGE\\\"/\" \\"
    echo ">        -e \"s/^#VNET_PUBLICIPS=.*$/VNET_PUBLICIPS=\\\"$EUCA_VNET_PUBLICIPS\\\"/\" \\"
    echo ">        -e \"s/^#VNET_SUBNET=.*$/VNET_SUBNET=\\\"$EUCA_VNET_SUBNET\\\"/\" \\"
    echo ">        -e \"s/^#VNET_NETMASK=.*$/VNET_NETMASK=\\\"$EUCA_VNET_NETMASK\\\"/\" \\"
    echo ">        -e \"s/^#VNET_ADDRSPERNET=.*$/VNET_ADDRSPERNET=\\\"$EUCA_VNET_ADDRSPERNET\\\"/\" \\"
    echo ">        -e \"s/^#VNET_DNS.*$/VNET_DNS=\\\"$EUCA_VNET_DNS\\\"/\" /etc/eucalyptus/eucalyptus.conf"
    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"$EUCA_VNET_MODE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$EUCA_VNET_PRIVINTERFACE\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$EUCA_VNET_PUBINTERFACE\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"$EUCA_VNET_BRIDGE\"/" \
           -e "s/^#VNET_PUBLICIPS=.*$/VNET_PUBLICIPS=\"$EUCA_VNET_PUBLICIPS\"/" \
           -e "s/^#VNET_SUBNET=.*$/VNET_SUBNET=\"$EUCA_VNET_SUBNET\"/" \
           -e "s/^#VNET_NETMASK=.*$/VNET_NETMASK=\"$EUCA_VNET_NETMASK\"/" \
           -e "s/^#VNET_ADDRSPERNET=.*$/VNET_ADDRSPERNET=\"$EUCA_VNET_ADDRSPERNET\"/" \
           -e "s/^#VNET_DNS.*$/VNET_DNS=\"$EUCA_VNET_DNS\"/" /etc/eucalyptus/eucalyptus.conf
    pause

    echo "# diff /etc/eucalyptus/eucalyptus.conf{,.orig}"
    diff /etc/eucalyptus/eucalyptus.conf{,.orig}

    next
fi


((++step))
if [ $is_cc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Restart the Cluster Controller service"
    echo "    - NOTE: After completing this step, you will need to run"
    echo "      the next step on all Node Controller hosts before you"
    echo "      continue here"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "service eucalyptus-cc restart"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# service eucalyptus-cc restart"
        service eucalyptus-cc restart

        echo
        echo "Please re-start all Node Controller services at this time"
        next 400
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Restart the Node Controller service"
    echo "    - STOP! This step should only be run after the step"
    echo "      which restarts the Cluster Controller service on the"
    echo "      Cluster Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "service eucalyptus-nc restart"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# service eucalyptus-nc restart"
        service eucalyptus-nc restart

        next 50
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Use Administrator Credentials"
    echo "    - NOTE: This step should only be run after the step"
    echo "      which restarts the Node Controller service on all Node"
    echo "      Controller hosts"
    echo "    - NOTE: Expect the OSG not configured warning"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --get-credentials /root/admin.zip"
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
        echo "# euca_conf --get-credentials /root/admin.zip"
        euca_conf --get-credentials /root/admin.zip
        pause

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
fi


((++step))
if [ $is_clc = y ]; then
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
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Instance Types"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-instance-types --show-capacity"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-instance-types --show-capacity"
        euca-describe-instance-types --show-capacity

        next 200
    fi
fi


end=$(date +%s)

echo
echo "Network configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
