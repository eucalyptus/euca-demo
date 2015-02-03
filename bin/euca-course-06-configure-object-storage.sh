#/bin/bash
#
# This script configures Eucalyptus object storage
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
echo "$(printf '%2d' $step). Set the Eucalyptus Object Storage Provider to Walrus"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p objectstorage.providerclient=walrus"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p objectstorage.providerclient=walrus"
    euca-modify-property -p objectstorage.providerclient=walrus

    echo
    echo "Waiting 10 seconds for property change to become effective"
    sleep 10

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo "    - The following services should now be in an ENABLED state:"
echo "      - objectstorage"
echo "    - The following services should be in a NOTREADY state:"
echo "      - imagingbackend, loadbalancingbackend"
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
echo "$(printf '%2d' $step). Confirm Snapshot Creation"
echo "    - First we create a volume"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-volume -z AZ1 -s 1"
echo
echo "euca-describe-volumes"
echo
echo "euca-create-snapshot vol-xxxxxx"
echo
echo "euca-describe-snapshots"

run

if [ $choice = y ]; then
    echo
    echo "# euca-create-volume -z AZ1 -s 1"
    euca-create-volume -z AZ1 -s 1 | tee /var/tmp/5-4-euca-create-volume.out

    echo -n "Waiting 30 seconds..."
    sleep 30
    echo " Done"
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes
    pause

    echo "# euca-create-snapshot $vol"
    volume=$(cut -f2 /var/tmp/5-4-euca-create-volume.out)
    euca-create-snapshot $volume | tee /var/tmp/5-4-euca-create-snapshot.out

    echo -n "Waiting 30 seconds..."
    sleep 30
    echo " Done"
    pause

    echo "# euca-describe-snapshots"
    euca-describe-snapshots

    next
fi


((++step))
snapshot=$(cut -f2 /var/tmp/5-4-euca-create-snapshot.out)
volume=$(cut -f2 /var/tmp/5-4-euca-create-volume.out)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Snapshot Deletion"
echo "    - Last we remove the volume"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-delete-snapshot $snapshot"
echo
echo "euca-describe-snapshots"
echo
echo "euca-delete-volume $volume"
echo
echo "euca-describe-volumes"

run

if [ $choice = y ]; then
    echo
    echo "# euca-delete-snapshot $snapshot"
    euca-delete-snapshot $snapshot

    echo -n "Waiting 30 seconds..."
    sleep 30
    echo " Done"
    pause

    echo "# euca-describe-snapshots"
    euca-describe-snapshots
    pause

    echo "# euca-delete-volume $volume"
    euca-delete-volume $volume

    echo -n "Waiting 30 seconds..."
    sleep 30
    echo " Done"
    pause

    echo "# euca-describe-volumes"
    euca-describe-volumes
    euca-delete-volume $volume &> /dev/null    # hidden to clear deleting state

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Refresh Eucalyptus Administrator credentials"
echo "    - This fixes the OSG not configured warning"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "rm -f /root/admin.zip"
echo
echo "euca-get-credentials -u admin /root/admin.zip"
echo
echo "rm -Rf /root/creds/eucalyptus/admin"
echo "mkdir -p /root/creds/eucalyptus/admin"
echo "unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
echo
echo "cat /root/creds/eucalyptus/admin/eucarc"
echo
echo "source /root/creds/eucalyptus/admin/eucarc"

run

if [ $choice = y ]; then
    echo
    echo "# rm -f /root/admin.zip"
    rm -f /root/admin.zip
    pause

    echo "# euca-get-credentials -u admin /root/admin.zip"
    euca-get-credentials -u admin /root/admin.zip
    pause

    # Save and restore the admin-demo.pem if it exists
    [ -r /root/creds/eucalyptus/admin/admin-demo.pem ] && cp -a /root/creds/eucalyptus/admin/admin-demo.pem /tmp/admin-demo.pem_$$
    echo "# rm -Rf /root/creds/eucalyptus/admin"
    rm -Rf /root/creds/eucalyptus/admin
    echo "#"
    echo "# mkdir -p /root/creds/eucalyptus/admin"
    mkdir -p /root/creds/eucalyptus/admin
    [ -r /tmp/admin-demo.pem_$$ ] && cp -a /tmp/admin-demo.pem_$$ /root/creds/eucalyptus/admin/admin-demo.pem; rm -f /tmp/admin-demo.pem_$$
    echo "#"
    echo "# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
    unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
    sed -i -e '/EUCALYPTUS_CERT=/aexport EC2_CERT=${EUCA_KEY_DIR}/cloud-cert.pem' /root/creds/eucalyptus/admin/eucarc    # invisibly fix missing property still needed for image import
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
echo "$(printf '%2d' $step). Confirm Properties"
echo "    - Confirm S3_URL is now configured, should be:"
echo "      http://$EUCA_OSP_PUBLIC_IP:8773/services/objectstorage"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-properties | more"
echo
echo "echo \$S3_URL"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-properties | more"
    euca-describe-properties | more
    pause

    echo "echo \$S3_URL"
    echo $S3_URL

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install Load Balancer and Imaging Worker image packages"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image"

run 50

if [ $choice = y ]; then
    echo
    echo "# yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image"
    yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install the images into Eucalyptus"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-install-load-balancer --install-default"
echo
echo "euca-install-imaging-worker --install-default"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-install-load-balancer --install-default"
    euca-install-load-balancer --install-default
    pause

    echo "# euca-install-imaging-worker --install-default"
    euca-install-imaging-worker --install-default

    echo
    echo -n "Waiting 10 seconds for service changes to stabilize..."
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
echo "      - loadbalancingbackend, imaging"
echo "    - All services should now be in the ENABLED state!"
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
echo "Object Storage configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
