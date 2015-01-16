#!/bin/bash
#
# This script installs Eucalyptus
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
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure yum repositories"
echo "    - Install the required release RPMs for ELREPO, EPEL,"
echo "      Eucalyptus and Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "yum install -y \\"
echo "    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/eucalyptus-release-4.0-1.el6.noarch.rpm \\"
echo "    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \\"
echo "    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/elrepo-release-6-6.el6.elrepo.noarch.rpm \\"
echo "    http://downloads.eucalyptus.com/software/euca2ools/3.1/centos/6Server/x86_64/euca2ools-release-3.1-1.el6.noarch.rpm"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# yum install -y \\"
    echo ">     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/eucalyptus-release-4.0-1.el6.noarch.rpm \\"
    echo ">     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \\"
    echo ">     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/elrepo-release-6-6.el6.elrepo.noarch.rpm \\"
    echo ">     http://downloads.eucalyptus.com/software/euca2ools/3.1/centos/6Server/x86_64/euca2ools-release-3.1-1.el6.noarch.rpm"
    yum install -y \
        http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/eucalyptus-release-4.0-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/elrepo-release-6-6.el6.elrepo.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.1/centos/6Server/x86_64/euca2ools-release-3.1-1.el6.noarch.rpm

    choose "Continue"
fi


packages=""
[ $is_clc = y -o $is_ufs = y ] && packages="$packages eucalyptus-cloud"
[ $is_mc = y ] && packages="$packages eucaconsole"
[ $is_cc = y ] && packages="$packages eucalyptus-cc"
[ $is_sc = y ] && packages="$packages eucalyptus-sc"
[ $is_osp = y ] && packages="$packages eucalyptus-walrus"
[ $is_nc = y ] && packages="$packages eucalyptus-nc"


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install packages"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "yum install -y ${packages# }"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# yum install -y ${packages# }"
    yum install -y $packages

    choose "Continue"
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Initialize the database"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --initialize"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --initialize"
        euca_conf --initialize

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start the Cloud Controller service"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - After starting services, wait until they  come up"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "chkconfig eucalyptus-cloud on"
    echo
    echo "service eucalyptus-cloud start"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# chkconfig eucalyptus-cloud on"
        echo 
        echo "# service eucalyptus-cloud start"
        service eucalyptus-cloud start

        echo
        echo "Waiting 60 seconds for user-facing services to come up"
        sleep 60

        echo
        while true; do
            echo -n "Testing services... "
            if curl -s http://10.104.10.21:8773/services/User-API | grep -s -q 404; then
                echo "Started"
                break
            else
                echo "Not yet running. Waiting another 15 seconds"
                sleep 15
            fi
        done

        choose "Continue"
    fi
fi


((++step))
if [ $is_cc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start the Cluster Controller service"
    echo "    - This step is only run on the Cluster Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "chkconfig eucalyptus-cc on"
    echo
    echo "service eucalyptus-cc start"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# chkconfig eucalyptus-cc on"
        chkconfig eucalyptus-cc on
        echo
        echo "# service eucalyptus-cc start"
        service eucalyptus-cc start

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register Walrus as the Object Storage Provider"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-walrusbackend --partition walrus --host $EUCA_OSP_PUBLIC_IP --component walrus"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-walrusbackend --partition walrus --host $EUCA_OSP_PUBLIC_IP --component walrus"
        euca_conf --register-walrusbackend --partition walrus --host $EUCA_OSP_PUBLIC_IP --component walrus

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register User-Facing services"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - It is normal to see ERRORs for objectstorage, imaging"
    echo "      and loadbalancingbackend at this point, as they require"
    echo "      further configuration"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-service -T user-api -H $EUCA_UFS_PUBLIC_IP -N PODAPI"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-service -T user-api -H $EUCA_UFS_PUBLIC_IP -N PODAPI"
        euca_conf --register-service -T user-api -H $EUCA_UFS_PUBLIC_IP -N PODAPI

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register Cluster Controller service"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-cluster --partition AZ1 --host $EUCA_CC_HOST_PUBLIC_IP --component PODCC"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-cluster --partition AZ1 --host $EUCA_CC_PUBLIC_IP --component PODCC"
        euca_conf --register-cluster --partition AZ1 --host $EUCA_CC_PUBLIC_IP --component PODCC

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register Storage Controller service"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-sc --partition AZ1 --host $EUCA_SC_PUBLIC_IP --component PODSC"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-sc --partition AZ1 --host $EUCA_SC_PUBLIC_IP --component PODSC"
        euca_conf --register-sc --partition AZ1 --host $EUCA_SC_PUBLIC_IP --component PODSC

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register Node Controller host(s)"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - NOTE! After completing this step, you will need to run"
    echo "      the next step on all Node Controller hosts before you"
    echo "      continue here"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-nodes=\"$EUCA_NC1_PRIVATE_IP\""

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-nodes=\"$EUCA_NC1_PRIVATE_IP\""
        euca_conf --register-nodes="$EUCA_NC1_PRIVATE_IP"

        choose "Continue"
    fi
fi


((++step))
if [ $is_nc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Start Node Controller service"
    echo "    - This step is only run on the Node Controller host"
    echo "    - STOP! This step should only be run after the step"
    echo "      which registers all Node Controller hosts on the"
    echo "      Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "chkconfig eucalyptus-nc on"
    echo
    echo "service eucalyptus-nc start"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# chkconfig eucalyptus-nc on"
        chkconfig eucalyptus-nc on
        echo
        echo "# service eucalyptus-nc start"
        service eucalyptus-nc start

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
    echo "    - NOTE: This step should only be run after the step"
    echo "      which starts the Node Controller service on all Node"
    echo "      Controller hosts"
    echo "    - The following services should be in a NOTREADY state:"
    echo "      - cluster, loadbalancingbackend, imaging"
    echo "    - The following services should be in a BROKEN state:"
    echo "      - storage, objectstorage"
    echo "    - This is normal at this point in time, with partial configuration"
    echo "    - Some output truncated for clarity"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-services | cut -f 1-5"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-services | cut -f 1-5"
        euca-describe-services | cut -f 1-5

        choose "Continue"
    fi
fi


echo
echo "Installation and initial configuration complete"
