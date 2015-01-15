#/bin/bash
#
# This script configures Eucalyptus Tools (euca2ools)
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
step_wait=20
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
    echo "$(printf '%2d' $step). Create Eucalyptus Tools Configuration file from template"
    echo "    - This step is only run on the Cloud Controller host"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "mkdir -p /root/.euca"
    echo
    echo "cp /etc/euca2ools/euca2ools.ini /root/.euca/"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p /root/.euca"
        mkdir -p /root/.euca
        pause

        echo "# cp /etc/euca2ools/euca2ools.ini /root/.euca/"
        cp /etc/euca2ools/euca2ools.ini /root/.euca/

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    eucalyptus_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" /root/creds/eucalyptus/admin/eucarc)
    eucalyptus_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" /root/creds/eucalyptus/admin/eucarc)

    engineering_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" /root/creds/engineering/admin/eucarc)
    engineering_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" /root/creds/engineering/admin/eucarc)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure Eucalyptus Tools Configuration file"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Add the Eucalyptus and Engineering Administrators"
    echo "    - Add the Service endpoints"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "cat << EOF >> /root/.euca/euca2ools.ini"
    echo "[user cloudadmin]"
    echo "key-id = $eucalyptus_admin_access_key"
    echo "secret-key = $eucalyptus_admin_secret_key"
    echo
    echo "[user engadmin]"
    echo "key-id = $engineering_admin_access_key"
    echo "secret-key = $engineering_admin_secret_key"
    echo "EOF"
    echo
    echo "cat << EOF >> /root/.euca/euca2ools.ini"
    echo "[region eucacloud]"
    echo "ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute"
    echo "s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage"
    echo "iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare"
    echo "sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens"
    echo "elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing"
    echo "autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling"
    echo "monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch"
    echo "EOF"
    echo
    echo "more /root/.euca/euca2ools.ini"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF >> /root/.euca/euca2ools.ini"
        echo "> [user cloudadmin]"
        echo "> key-id = $eucalyptus_admin_access_key"
        echo "> secret-key = $eucalyptus_admin_secret_key"
        echo ">"
        echo "> [user engadmin]"
        echo "> key-id = $engineering_admin_access_key"
        echo "> secret-key = $engineering_admin_secret_key"
        echo "> EOF"
        cat << EOF >> /root/.euca/euca2ools.ini

[user cloudadmin]
key-id = $eucalyptus_admin_access_key
secret-key = $eucalyptus_admin_secret_key

[user engadmin]
key-id = $engineering_admin_access_key
secret-key = $engineering_admin_secret_key
EOF
        pause

        echo "# cat << EOF >> /root/.euca/euca2ools.ini"
        echo "> [region eucacloud]"
        echo "> ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute"
        echo "> s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage"
        echo "> iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare"
        echo "> sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens"
        echo "> elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing"
        echo "> autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling"
        echo "> monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch"
        echo "> EOF"
        cat << EOF >> /root/.euca/euca2ools.ini

[region eucacloud]
ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute
s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage
iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare
sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens
elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing
autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling
monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch
EOF
        pause

        echo "# more /root/.euca/euca2ools.ini"
        more /root/.euca/euca2ools.ini

        choose "Continue"
    fi
fi


((++step))
if [ $is_clc = y ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Describe Availability Zones as the Engineering Administrator"
    echo "    - This step is only run on the Cloud Controller host"
    echo "    - Note syntax which references config file sections created above"
    echo "    - Note verbose output when running same command as Eucalyptus Administrator"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca-describe-availability-zones verbose --region engadmin@eucacloud"
    echo
    echo "euca-describe-availability-zones verbose --region cloudadmin@eucacloud"

    choose "Execute"

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-availability-zones verbose --region engadmin@eucacloud"
        euca-describe-availability-zones verbose --region engadmin@eucacloud
        pause

        echo "# euca-describe-availability-zones verbose --region cloudadmin@eucacloud"
        euca-describe-availability-zones verbose --region cloudadmin@eucacloud

        choose "Continue"
    fi
fi


echo
echo "Eucalyptus Tools configuration complete"
