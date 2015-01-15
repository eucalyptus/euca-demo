#/bin/bash
#
# This script tests Eucalyptus Security Groups
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
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Initialize Ops Account Administrator credentials"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "source /root/creds/ops/admin/eucarc"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# source /root/creds/ops/admin/eucarc"
        source /root/creds/ops/admin/eucarc

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    public_ip=$(grep INSTANCE /var/tmp/9-15-euca-run-instance.out | cut -f4)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Test Security Group Rules with Ping"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Allow Ping through default security group"
    echo "    - List instances, and confirm you can ping"
    echo "    - Remove rule allowing Ping"
    echo "    - List instances, and confirm you can no longer ping"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 default"
    echo
    echo "euca-describe-instances"
    echo
    echo "ping $public_ip"
    echo
    echo "euca-revoke -P icmp -t -1:-1 -s 0.0.0.0/0 default"
    echo
    echo "ping $public_ip"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 default"
        euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 default
        pause

        echo "# euca-describe-instances"
        euca-describe-instances
        pause

        echo "# ping -c 3 $public_ip"
        ping -c 3 $public_ip
        pause

        echo "# euca-revoke -P icmp -t -1:-1 -s 0.0.0.0/0 default"
        euca-revoke -P icmp -t -1:-1 -s 0.0.0.0/0 default
        pause

        echo "# ping -c 3 $public_ip"
        ping -c 3 $public_ip

        choose "Continue"
    fi
fi


echo "This lab has not yet been fully implemented!"

echo
echo "Security testing complete"
