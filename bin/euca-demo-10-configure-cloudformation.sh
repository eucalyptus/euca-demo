#/bin/bash
#
# This script configures Eucalyptus CloudFormation
#
# It should only be run once on the Cloud Controller host.
#
# It can be run on top of a new FastStart install or once the Cloud Administrator
# manual install has completed installing the console
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
step_wait=20
step_max=120
pause_min=0
pause_wait=2
pause_max=30

is_installed=n


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

if [ $(hostname -s) != $EUCA_CLC_HOST_NAME ]; then
    echo
    echo "This script should be run only on a Cloud Controller"
    exit 10
fi


#  5. Convert FastStart credentials to Course directory structure

if [ -r /root/creds/eucalyptus/admin/eucarc ]; then
    echo "Found Eucalyptus Administrator credentials"
elif [ -r /root/admin.zip ]; then
    echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
    mkdir -p /root/creds/eucalyptus/admin
    unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
    sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/eucalyptus/admin/eucarc    # invisibly fix deprecation message
    sleep 2
else
    echo
    echo "Could not find Eucalyptus Administrator credentials!"
    exit 20
fi


#  6. Execute Demo

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Initialize Administrator credentials"
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


((++step))
if euca-describe-services | grep -s -q "^SERVICE.cloudformation"; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register CloudFormation service"
    echo "    - Already Installed!"
    echo "    - Will skip ahead to validation"
    echo
    echo "============================================================"

    choose "Continue"

else
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Register CloudFormation service"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_conf --register-service -T CloudFormation -H $EUCA_UFS_PUBLIC_IP -N cfn"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca_conf --register-service -T CloudFormation -H $EUCA_UFS_PUBLIC_IP -N cfn"
        euca_conf --register-service -T CloudFormation -H $EUCA_UFS_PUBLIC_IP -N cfn

        choose "Continue"
    fi


    ((++step))
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

        echo "# rm -Rf /root/creds/eucalyptus/admin"
        rm -Rf /root/creds/eucalyptus/admin
        echo
        echo "# mkdir -p /root/creds/eucalyptus/admin"
        mkdir -p /root/creds/eucalyptus/admin
        echo
        echo "# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/"
        unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
        sed -i -e 's/EUARE_URL=/AWS_IAM_URL=/' /root/creds/eucalyptus/admin/eucarc    # invisibly fix deprecation message
        if [ -r /root/eucarc ]; then
            cp /root/creds/eucalyptus/admin/eucarc /root/eucarc    # invisibly update Faststart credentials location
        fi
        pause

        echo "# source /root/creds/eucalyptus/admin/eucarc"
        source /root/creds/eucalyptus/admin/eucarc

        choose "Continue"
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo "    - You should now see the CloudFormation Service"
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


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Verify CloudFormation service"
echo "    - Upon installation, there should be no output (no errors)"
echo "    - If run after installation, you may see existing Stacks"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"

choose "Execute"

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks

    choose "Continue"
fi


echo
echo "Eucalyptus CloudFormation configuration complete"
