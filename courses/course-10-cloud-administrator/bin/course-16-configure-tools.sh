#/bin/bash
#
# This script configures Eucalyptus Tools (euca2ools)
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
echo "$(printf '%2d' $step). Create Eucalyptus Tools Configuration file from template"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p /root/.euca"
echo
echo "cp /etc/euca2ools/euca2ools.ini /root/.euca/"

run 50

if [ $choice = y ]; then
    echo
    echo "# mkdir -p /root/.euca"
    mkdir -p /root/.euca
    pause

    echo "# cp /etc/euca2ools/euca2ools.ini /root/.euca/"
    cp /etc/euca2ools/euca2ools.ini /root/.euca/

    next 50
fi


((++step))
eucalyptus_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" /root/creds/eucalyptus/admin/eucarc)
eucalyptus_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" /root/creds/eucalyptus/admin/eucarc)

engineering_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" /root/creds/engineering/admin/eucarc)
engineering_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" /root/creds/engineering/admin/eucarc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Tools Configuration file"
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
echo "autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling"
echo "cloudformation-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudFormation"
echo "ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute"
echo "elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing"
echo "iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare"
echo "monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch"
echo "s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage"
echo "sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens"
echo "swf-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/SimpleWorkflow"
echo "EOF"
echo
echo "more /root/.euca/euca2ools.ini"

run 150

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
    echo "> autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling"
    echo "> cloudformation-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudFormation"
    echo "> ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute"
    echo "> elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing"
    echo "> iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare"
    echo "> monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch"
    echo "> s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage"
    echo "> sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens"
    echo "> swf-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/SimpleWorkflow"
    echo "> EOF"
    cat << EOF >> /root/.euca/euca2ools.ini

[region eucacloud]
autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling
cloudformation-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudFormation
ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute
elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing
iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare
monitoring-url http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch
s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage
sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens
swf-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/SimpleWorkflow
EOF
    pause

    echo "# more /root/.euca/euca2ools.ini"
    more /root/.euca/euca2ools.ini

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Describe Availability Zones as the Engineering Administrator"
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

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-availability-zones verbose --region engadmin@eucacloud"
    euca-describe-availability-zones verbose --region engadmin@eucacloud
    pause

    echo "# euca-describe-availability-zones verbose --region cloudadmin@eucacloud"
    euca-describe-availability-zones verbose --region cloudadmin@eucacloud

    next 200
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Tools configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Tools configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
