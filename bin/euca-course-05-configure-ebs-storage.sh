#/bin/bash
#
# This script configures Eucalyptus EBS storage
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

if [ ! -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: /root/creds/eucalyptus/admin/eucarc"
    exit 20
fi


#  5. Execute Course Lab

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo "    - NOTE: Expect the OSG not configured warning"
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
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Set the Eucalyptus Storage Controller backend"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p AZ1.storage.blockstoragemanager=overlay"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p AZ1.storage.blockstoragemanager=overlay"
    euca-modify-property -p AZ1.storage.blockstoragemanager=overlay

    echo
    echo -n "Waiting 10 seconds for property change to become effective..."
    sleep 10
    echo " Done"

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo "    - The following service should now be in an ENABLED state:"
echo "      - storage"
echo "    - The following services should be in a NOTREADY state:"
echo "      - imagingbackend, loadbalancingbackend"
echo "    - The following services should be in a BROKEN state:"
echo "      - objectstorage"
echo "    - This is normal at this point in time, with partial configuration"
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


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Volume Creation"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-volume -z AZ1 -s 1"
echo
echo "euca-describe-volumes"
echo
echo "ls -l /var/lib/eucalyptus/volumes"

run 50

if [ $choice = y ]; then

    echo
    echo "# euca-create-volume -z AZ1 -s 1"
    euca-create-volume -z AZ1 -s 1 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-create-volume.out
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes
    pause

    echo "# ls -l /var/lib/eucalyptus/volumes"
    ls -lh /var/lib/eucalyptus/volumes

    next
fi
volume1_id=$(cut -f2 $tmpdir/$prefix-$(printf '%02d' $step)-euca-create-volume.out)


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Volume Deletion"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-delete-volume $volume1_id"
echo
echo "euca-describe-volumes"
echo 
echo "ls -lh /var/lib/eucalyptus/volumes"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-delete-volume $volume1_id"
    euca-delete-volume $volume1_id
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes
    pause

    echo "# ls -lh /var/lib/eucalyptus/volumes"
    ls -lh /var/lib/eucalyptus/volumes

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Flush Volume Resource Information"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-delete-volume $volume1_id"
echo 
echo "euca-describe-volumes"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-delete-volume $volume1_id"
    euca-delete-volume $volume1_id
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Volume Quota"
echo "    - This step should fail with quota exceeded error"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-volume -z AZ1 -s 20"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-create-volume -z AZ1 -s 20"
    euca-create-volume -z AZ1 -s 20

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Increase Volume Quota"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p AZ1.storage.maxvolumesizeingb=20"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p AZ1.storage.maxvolumesizeingb=20"
    euca-modify-property -p AZ1.storage.maxvolumesizeingb=20

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Increased Volume Quota"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-volume -z AZ1 -s 20"
echo
echo "euca-describe-volumes"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-create-volume -z AZ1 -s 20"
    euca-create-volume -z AZ1 -s 20 | tee $tmpdir/$prefix-$(printf '%02d' $step)-euca-create-volume.out
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes

    next
fi
volume2_id=$(cut -f2 $tmpdir/$prefix-$(printf '%02d' $step)-euca-create-volume.out)


((++step))

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Larger Volume Deletion"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-delete-volume $volume2_id"
echo
echo "euca-describe-volumes"
echo
echo "ls -lh /var/lib/eucalyptus/volumes"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-delete-volume $volume2_id"
    euca-delete-volume $volume2_id
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes
    pause

    echo "# ls -lh /var/lib/eucalyptus/volumes"
    ls -lh /var/lib/eucalyptus/volumes

    next
fi


end=$(date +%s)

echo
echo "EBS Storage configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
