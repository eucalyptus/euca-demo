#!/bin/bash
#
# This script installs Eucalyptus via the Faststart method
#
# This script is eventually designed to support any combination, but was initially
# written to automate the cloud administrator course which uses a 2-node configuration.
# It has not been tested to work in other combinations.
#
# Each student MUST run all prior scripts on all nodes prior to this script.
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

external_faststart_url=eucalyptus.com/install
internal_faststart_url=mirror.mjc.prc.eucalyptus-systems.com/install

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
[ "$EUCA_INSTALL_MODE" = "local" ] && local=1 || local=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-l]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -l  Use local mirror for Faststart script (uses local yum repos)"
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

while getopts Isfl? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    l)  local=1;;
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

if [ $local = 1 ]; then
    faststart_url=$internal_faststart_url
else
    faststart_url=$external_faststart_url
fi


#  5. Execute Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Install"
echo "    - Responses to questions:"
echo "      Laptop power warning: Continue?                          <enter>"
echo "      DHCP warning: Continue Anyway?                           y"
echo "      What's the NTP server which we will update time from?    <enter>"
echo "      What's the physical NIC that will be used for bridging?  <enter>"
echo "      What's the IP address of this host?                      <enter>"
echo "      What's the gateway for this host?                        <enter>"
echo "      What's the netmask for this host?                        <enter>"
echo "      What's the subnet for this host?                         <enter>"
echo "      What's the first address of your available IP range?     ${EUCA_VNET_PUBLICIPS%-*}"
echo "      What's the last address of your available IP range?      ${EUCA_VNET_PUBLICIPS#*-}"
echo "      Install additional services? [Y/n]                       <enter>"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "bash <(curl -Ls eucalyptus.com/install)"

run 50

if [ $choice = y ]; then
    echo
    pushd $HOME &> /dev/null
    echo "# bash <(curl -Ls eucalyptus.com/install)"
    bash <(curl -Ls $faststart_url)
    popd &> /dev/null

    next 50
fi


((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Move Credentials into Demo Directory Structure"
echo "    - We need to create additional accounts and users, so move"
echo "      the Eucalyptus Administrator credentials into a more"
echo "      hierarchical credentials storage directory structure"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo
if grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
    echo "echo \"export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION\" >> ~/.bash_profile"
    echo
fi
if grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
    echo "echo \"export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin\" >> ~/.bash_profile"
    echo
fi
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin"
echo
echo "rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
echo
echo "cp -a ~/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
echo
echo "unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

run 50

if [ $choice = y ]; then
    echo
    if grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
        echo "# echo \"export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION\" >> ~/.bash_profile"
        echo >> ~/.bash_profile
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> ~/.bash_profile
        pause
    fi
    if grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
        echo "# echo \"export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin\" >> ~/.bash_profile"
        echo >> ~/.bash_profile
        echo "export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin" >> ~/.bash_profile
        pause
    fi
    echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin"
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
    pause

    echo "# rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
    pause

    echo "# cp -a root/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip"
    cp -a root/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
    pause

    echo "# unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/"
    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/
    if grep -s -q "echo WARN:  CloudFormation service URL is not configured" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        # invisibly fix bug in initial faststart which registers CloudFormation but returns a warning in eucarc
        sed -i -r -e "/echo WARN:  CloudFormation service URL is not configured/d" \
                  -e "s/(^export )(AWS_AUTO_SCALING_URL)(.*\/services\/)(AutoScaling$)/\1\2\3\4\n\1AWS_CLOUDFORMATION_URL\3CloudFormation/" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi
    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        # invisibly fix missing environment variables needed for image import
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi
    pause

    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    pause

    echo "# source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm Public IP addresses"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-addresses verbose"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-addresses verbose"
    euca-describe-addresses verbose

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo "    - Truncating normal output for readability"
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
echo "Eucalyptus installed (time: $(date -u -d @$((end-start)) +"%T"))"
