#/bin/bash
#
# This script configures Eucalyptus EBS storage
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

is_clc=n
is_ufs=n
is_mc=n
is_cc=n
is_sc=n
is_osp=n
is_nc=n


#  2. Define functions

usage () {
    echo "Usage: $(basename $0) [-I]"
    echo "  -I non-interactive"
}

pause() {
    if [ "$interactive" = 1 ]; then
        read pause
    else
        sleep 5
    fi
}

choose() {
    if [ "$interactive" = 1 ]; then
        [ -n "$1" ] && prompt2="$1 (y,n,q)[y]"
        [ -z "$1" ] && prompt2="Proceed[y]?"
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
        sleep 5
        choice=y
    fi
}


#  3. Parse command line options

while getopts I arg; do
    case $arg in
    I)  interactive=0;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $EUCA_VNET_MODE ]; then
    echo
    echo "Please set environment variables first"
    exit 1
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

if [ $is_clc = y ]; then
    ((++step))
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


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Set the Eucalyptus Storage Controller backend"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p AZ1.storage.blockstoragemanager=overlay"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-property -p AZ1.storage.blockstoragemanager=overlay"
        euca-modify-property -p AZ1.storage.blockstoragemanager=overlay

        echo
        echo "Waiting 15 seconds for property change to become effective"
        sleep 15

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm service status"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - The following service should now be in an ENABLED state:"
    echo "      - storage"
    echo "    - The following services should be in a NOTREADY state:"
    echo "      - cluster, loadbalancingbackend, imaging"
    echo "    - The following services should be in a BROKEN state:"
    echo "      - objectstorage"
    echo "    - This is normal at this point in time, with partial configuration"
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


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Volume Creation"
    echo "    - This step is only run on the Cloud Controller host"
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

    choose "Execute"

    if [ $choice = y ]; then

        echo
        echo "# euca-create-volume -z AZ1 -s 1"
        euca-create-volume -z AZ1 -s 1 | tee /var/tmp/4-4-euca-create-volume.out
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# ls -l /var/lib/eucalyptus/volumes"
        ls -lh /var/lib/eucalyptus/volumes

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    volume=$(cut -f2 /var/tmp/4-4-euca-create-volume.out)
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Volume Deletion"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-delete-volume $volume"
    echo
    echo "euca-describe-volumes"
    echo 
    echo "ls -lh /var/lib/eucalyptus/volumes"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-delete-volume $volume"
        euca-delete-volume $volume
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# ls -lh /var/lib/eucalyptus/volumes"
        ls -lh /var/lib/eucalyptus/volumes

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    volume=$(cut -f2 /var/tmp/4-4-euca-create-volume.out)
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Flush Volume Resource Information"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-delete-volume $volume"
    echo 
    echo "euca-describe-volumes"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-delete-volume $volume"
        euca-delete-volume $volume
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Volume Quota"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - This step should fail with quota exceeded error"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-volume -z AZ1 -s 20"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-volume -z AZ1 -s 20"
        euca-create-volume -z AZ1 -s 20

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Increase Volume Quota"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-modify-property -p AZ1.storage.maxvolumesizeingb=20"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-property -p AZ1.storage.maxvolumesizeingb=20"
        euca-modify-property -p AZ1.storage.maxvolumesizeingb=20

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Increased Volume Quota"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-create-volume -z AZ1 -s 20"
    echo
    echo "euca-describe-volumes"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-create-volume -z AZ1 -s 20"
        euca-create-volume -z AZ1 -s 20 | tee /var/tmp/4-7-euca-create-volume.out
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes

        choose "Continue"
    fi
fi


if [ $is_clc = y ]; then
    volume=$(cut -f2 /var/tmp/4-7-euca-create-volume.out)
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm Larger Volume Deletion"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-delete-volume $volume"
    echo
    echo "euca-describe-volumes"
    echo
    echo "ls -lh /var/lib/eucalyptus/volumes"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-delete-volume $volume"
        euca-delete-volume $volume
        pause

        echo "# euca-describe-volumes"
        euca-describe-volumes
        pause

        echo "# ls -lh /var/lib/eucalyptus/volumes"
        ls -lh /var/lib/eucalyptus/volumes

        choose "Continue"
    fi
fi


echo
echo "EBS Storage configuration complete"
