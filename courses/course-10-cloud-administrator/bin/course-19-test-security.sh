#/bin/bash
#
# This script tests Eucalyptus Security Groups
#
# This script should only be run on the Cloud Controller host
#
# Each student MUST run all prior scripts on relevant hosts prior to this script.
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
prefix=course

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

if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r /root/creds/ops/admin/eucarc ]; then
    echo "Could not find Ops Account Administrator credentials!"
    echo "Expected to find: /root/creds/ops/admin/eucarc"
    exit 22
fi


#  5. Execute Course Lab

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Ops Account Administrator credentials"
echo "    - This step is only run on the Cloud Controller host"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat /root/creds/ops/admin/eucarc"
echo
echo "source /root/creds/ops/admin/eucarc"

next

echo
echo "# cat /root/creds/ops/admin/eucarc"
cat /root/creds/ops/admin/eucarc
pause

echo "# source /root/creds/ops/admin/eucarc"
source /root/creds/ops/admin/eucarc

next


((++step))
# This is a shortcut assuming no other activity on the system - find the most recently launched instance
result=$(euca-describe-instances | grep "^INSTANCE" | cut -f2,4,11 | sort -k3 | tail -1 | cut -f1,2 | tr -s '[:blank:]' ':')
instance_id=${result%:*}
public_ip=${result#*:}
user=root

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Test Security Group Rules with Ping"
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

run

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

    next 200
fi


echo "This lab has not yet been fully implemented!"

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Security testing complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Security testing complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
