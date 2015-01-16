#/bin/bash
#
# This script configures Eucalyptus object storage
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
step_wait=10
step_max=60
pause_min=0
pause_wait=2
pause_max=20

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
    echo "$(printf '%2d' $step). Initialize Administrator credentials"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Expect the OSG not configured warning"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "source /root/creds/eucalyptus/admin/eucarc"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Set the Eucalyptus Object Storage Provider to Walrus"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p objectstorage.providerclient=walrus"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-property -p objectstorage.providerclient=walrus"
        euca-modify-property -p objectstorage.providerclient=walrus

        echo
        echo "Waiting 15 seconds for property change to become effective"
        sleep 15

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm service status"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The following services should now be in an ENABLED state:"
    echo "      - cluster, objectstorage"
    echo "    - The following services should be in a NOTREADY state:"
    echo "      - loadbalancingbackend, imaging"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-services | cut -f1-5"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-services | cut -f1-5"
        euca-describe-services | cut -f1-5

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Snapshot Creation"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-volume -z AZ1 -s 1"
        euca-create-volume -z AZ1 -s 1 | tee /var/tmp/5-4-euca-create-volume.out

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# euca-create-snapshot $vol"
        volume=$(cut -f2 /var/tmp/5-4-euca-create-volume.out)
        euca-create-snapshot $volume | tee /var/tmp/5-4-euca-create-snapshot.out

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-snapshots"
        euca-describe-snapshots

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    snapshot=$(cut -f2 /var/tmp/5-4-euca-create-snapshot.out)
    volume=$(cut -f2 /var/tmp/5-4-euca-create-volume.out)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Snapshot Deletion"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-delete-snapshot $snapshot"
        euca-delete-snapshot $snapshot

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-snapshots"
        euca-describe-snapshots
        pause

        echo "# euca-delete-volume $volume"
        euca-delete-volume $volume

        echo -n "Waiting 30 seconds..."
        sleep 30
        echo "Done"
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        euca-delete-volume $volume &> /dev/null    # hidden to clear deleting state

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Refresh Administrator Credentials"
    echo "    - This step is only run on the Cloud Controller host"
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
    echo "source /root/creds/eucalyptus/admin/eucarc"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# rm -f /root/admin.zip"
        rm -f /root/admin.zip
        pause

        echo "# euca-get-credentials -u admin /root/admin.zip"
        euca-get-credentials -u admin /root/admin.zip
        pause

        # Save and restore the DemoKey.pem if it exists
        [ -r /root/creds/eucalyptus/admin/DemoKey.pem ] && cp -a /root/creds/eucalyptus/admin/DemoKey.pem /tmp/DemoKey.pem_$$
        echo "# rm -Rf /root/creds/eucalyptus/admin"
        rm -Rf /root/creds/eucalyptus/admin
        echo "#"
        echo "# mkdir -p /root/creds/eucalyptus/admin"
        mkdir -p /root/creds/eucalyptus/admin
        [ -r /tmp/DemoKey.pem_$$ ] && cp -a /tmp/DemoKey.pem_$$ /root/creds/eucalyptus/admin/DemoKey.pem; rm -f /tmp/DemoKey.pem_$$
        echo "#"
        echo "# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
        unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/eucalyptus/admin/eucarc    # invisibly fix deprecation message
        pause

        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Properties"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-properties | more"
        euca-describe-properties | more
        pause

        echo "echo \$S3_URL"
        echo $S3_URL

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install Load Balancer and Imaging Worker image packages"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image"
        yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install the images into Eucalyptus"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-install-load-balancer --install-default"
    echo
    echo "euca-install-imaging-worker --install-default"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-install-load-balancer --install-default"
        euca-install-load-balancer --install-default
        pause

        echo "# euca-install-imaging-worker --install-default"
        euca-install-imaging-worker --install-default

        echo
        echo "Waiting 15 seconds for service changes to stabilize"
        sleep 15

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm service status"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The following service should now be in an ENABLED state:"
    echo "      - loadbalancingbackend, imaging"
    echo "    - All services should now be in the ENABLED state!"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-services | cut -f1-5"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-services | cut -f1-5"
        euca-describe-services | cut -f1-5

        choose "Continue"
    fi
fi


echo
echo "Object Storage configuration complete"
