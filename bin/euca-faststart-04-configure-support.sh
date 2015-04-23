#/bin/bash
#
# This script configures Eucalyptus Support Tasks after a Faststart installation
#
# This should be run immediately after the Faststart Console configuration script
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_MC_HOST_NAME" ] && is_mc=y || is_mc=n

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

while getopts Isfc? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  certificate=1;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_mc = n ]; then
    echo "This script should only be run on a Management Console host"
    exit 20
fi


#  5. Execute Procedure

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
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Eucalyptus Administrator Support Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-keypair admin-support | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem"
echo
echo "chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem"

if euca-describe-keypairs | grep -s -q "admin-support" && [ -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    euca-delete-keypair admin-support
    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-support | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem"
        euca-create-keypair admin-support | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem
        echo "#"
        echo "# chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem"
        chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure Service Image Login"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p services.database.worker.keyname=admin-support"
echo
echo "euca-modify-property -p services.imaging.worker.keyname=admin-support"
echo
echo "euca-modify-property -p services.loadbalancing.worker.keyname=admin-support"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p services.database.worker.keyname=admin-support"
    euca-modify-property -p services.database.worker.keyname=admin-support
    echo "#"
    echo "# euca-modify-property -p services.imaging.worker.keyname=admin-support"
    euca-modify-property -p services.imaging.worker.keyname=admin-support
    echo "#"
    echo "# euca-modify-property -p services.loadbalancing.worker.keyname=admin-support"
    euca-modify-property -p services.loadbalancing.worker.keyname=admin-support

    next 50
fi

end=$(date +%s)

echo
echo "Eucalyptus Support configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
