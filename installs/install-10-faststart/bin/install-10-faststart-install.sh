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

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

external_faststart_url=hphelion.com/eucalyptus-install
internal_faststart_url=mirror.mjc.prc.eucalyptus-systems.com/eucalyptus-install

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
config=$(hostname -s)
local=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config] [-l]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -c config  configuration (default: $config)"
    echo "  -l         Use local mirror for Faststart script (uses local yum repos)"
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

while getopts Isfc:l? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  config="$OPTARG";;
    l)  local=1;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [[ $config =~ ^([a-zA-Z0-9_-]*)$ ]]; then
    conffile=$confdir/$config.txt

    if [ ! -r $conffile ]; then
        echo "-c $config invalid: can't find configuration file: $conffile"
        exit 5
    fi
else
    echo "-c $config illegal: must consist of a-z, A-Z, 0-9, '-' or '_' characters"
    exit 2
fi

source $conffile

if [ $local = 1 ]; then
    faststart_url=$internal_faststart_url
else
    faststart_url=$external_faststart_url
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install"
echo "    - Responses to questions:"
echo "      Laptop power warning: Continue?                          <enter>"
echo "      DHCP warning: Continue Anyway?                           y"
echo "      What's the NTP server which we will update time from?    <enter>"
echo "      What's the physical NIC that will be used for bridging?  <enter>"
echo "      What's the IP address of this host?                      <enter>"
echo "      What's the gateway for this host?                        <enter>"
echo "      What's the netmask for this host?                        <enter>"
echo "      What's the subnet for this host?                         <enter>"
echo "      What's the first address of your available IP range?     ${EUCA_PUBLIC_IP_RANGE%-*}"
echo "      What's the last address of your available IP range?      ${EUCA_PUBLIC_IP_RANGE#*-}"
echo "      Install additional services? [Y/n]                       <enter>"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "bash <(curl -Ls hphelion.com/eucalyptus-install)"

run 50

if [ $choice = y ]; then
    echo
    pushd $HOME &> /dev/null
    echo "# bash <(curl -Ls hphelion.com/eucalyptus-install)"
    export AWS_DEFAULT_REGION=localhost
    bash <(curl -Ls $faststart_url)
    popd &> /dev/null

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Region"
echo "    - FastStart creates a \"localhost\" Region by default"
echo "    - We will switch this to a more \"AWS-like\" Region naming convention"
echo "    - This is needed to run CloudFormation templates which reference the"
echo "      Region in Maps"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl region.region_name=$AWS_DEFAULT_REGION"

run 50

if [ $choice = y ]; then
    echo
    echo "# euctl region.region_name=$AWS_DEFAULT_REGION"
    euctl region.region_name=$AWS_DEFAULT_REGION

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Convert FastStart Credentials to Demo Conventions"
echo "    - Demos require additional accounts and users, and in some cases"
echo "      multiple Eucalyptus and AWS Accounts are used. So we need a more"
echo "      hierarchical credentials storage directory structure"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem"
echo "chmod 0644 /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem"
echo
echo "sed -n -e \"1i; Eucalyptus Region $AWS_DEFAULT_REGION\\n\" \\"
echo "       -e \"s/localhost/$AWS_DEFAULT_REGION/\" \\"
echo "       -e \"s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/\" \\"
echo "       -e \"/^\\[region/,/^\\user =/p\" \\"
echo "       -e \"\\\$a\\\\\\\\\" \\"
echo "       -e \"\\\$acertificate = /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION\" \\"
echo "       -e \"\\\$averify-ssl = false\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini"
echo
echo "sed -n -e \"1i; Eucalyptus Region $AWS_DEFAULT_REGION\\n\" \\"
echo "       -e \"s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/\" \\"
echo "       -e \"/^\\[user/,/^account-id =/p\" \\"
echo "       -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/$AWS_DEFAULT_REGION.ini"
echo
echo "cat <<EOF > ~/.euca/global.ini"
echo "; Eucalyptus Global"
echo
echo "[global]"
echo "region = $AWS_DEFAULT_REGION"
echo
echo "EOF"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin"
echo
echo "cat <<EOF > ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc"
echo "AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini)"
echo "AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini)"
echo "EOF"
echo
echo "rm -f ~/.euca/faststart.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem"
    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    echo "# chmod 0644 /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem"
    chmod 0644 /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    pause

    echo "# sed -n -e \"1i; Eucalyptus Region $AWS_DEFAULT_REGION\\n\" \\"
    echo ">        -e \"s/localhost/$AWS_DEFAULT_REGION/\" \\"
    echo ">        -e \"s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/\" \\"
    echo ">        -e \"/^\\[region/,/^\\user =/p\" \\"
    echo ">        -e \"\\\$a\\\\\\\\\" \\"
    echo ">        -e \"\\\$acertificate = /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION\" \\"
    echo ">        -e \"\\\$averify-ssl = false\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini"
    sed -n -e "1i; Eucalyptus Region $AWS_DEFAULT_REGION\n" \
           -e "s/localhost/$AWS_DEFAULT_REGION/" \
           -e "s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/" \
           -e "/^\[region/,/^\user =/p" \
           -e "\$a\\\\" \
           -e "\$acertificate = /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION" \
           -e "\$averify-ssl = false" faststart.ini > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini
    pause

    echo "# sed -n -e \"1i; Eucalyptus Region $AWS_DEFAULT_REGION\\n\" \\"
    echo ">        -e \"s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/\" \\"
    echo ">        -e \"/^\\[user/,/^account-id =/p\" \\"
    echo ">        -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/$AWS_DEFAULT_REGION.ini"
    sed -n -e "1i; Eucalyptus Region $AWS_DEFAULT_REGION\n" \
           -e "s/[0-9]*:admin/$AWS_DEFAULT_REGION-admin/" \
           -e "/^\[user/,/^account-id =/p" \
           -e "\$a\\\\" faststart.ini > ~/.euca/$AWS_DEFAULT_REGION.ini
    pause

    echo "cat <<EOF > ~/.euca/global.ini"
    echo "; Eucalyptus Global"
    echo
    echo "[global]"
    echo "region = $AWS_DEFAULT_REGION"
    echo
    echo "EOF"
    # Use echo instead of cat << EOF to better show indentation
    echo "; Eucalyptus Global"           > ~/.euca/global.ini
    echo                                >> ~/.euca/global.ini
    echo "[global]"                     >> ~/.euca/global.ini
    echo "region = $AWS_DEFAULT_REGION" >> ~/.euca/global.ini
    echo                                >> ~/.euca/global.ini
    pause

    echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin"
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
    pause

    echo "# cat <<EOF > ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc"
    echo "> AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini)"
    echo "> AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini)"
    echo "> EOF"
    # Use echo instead of cat << EOF to better show indentation
    echo AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini)    > ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    echo AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini) >> ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    pause

    echo "# rm -f ~/.euca/faststart.ini"
    rm -f ~/.euca/faststart.ini

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Bash to use Eucalyptus Administrator Credentials"
echo "    - While it is possible to use the \"user@region\" convention when setting AWS_DEFAULT_REGION"
echo "      to work with Euca2ools, this breaks AWSCLI which doesn't understand that change to this"
echo "      environment variable format."
echo "    - By setting the variables needed for Euca2ools explicitly, both Euca2ools and AWSCLI"
echo "      can be used interchangably."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if ! grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
    echo "echo \"export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION\" >> ~/.bash_profile"
    echo
fi
if ! grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
    echo "echo \"export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin\" >> ~/.bash_profile"
    echo
fi
if ! grep -s -q "^export AWS_CREDENTIAL_FILE=" ~/.bash_profile; then
    echo "echo \"export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc\" >> ~/.bash_profile"
    echo
fi

run 50

if [ $choice = y ]; then
    echo
    if ! grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
        echo "# echo \"export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION\" >> ~/.bash_profile"
        echo >> ~/.bash_profile
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> ~/.bash_profile
        pause
    fi
    if ! grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
        echo "# echo \"export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin\" >> ~/.bash_profile"
        echo "export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin" >> ~/.bash_profile
        pause
    fi
    if ! grep -s -q "^export AWS_CREDENTIAL_FILE=" ~/.bash_profile; then
        echo "# echo \"export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc\" >> ~/.bash_profile"
        echo "export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc" >> ~/.bash_profile
    fi

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm Public IP addresses"
echo
echo "================================================================================"
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
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm service status"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euserv-describe-services"

run 50

if [ $choice = y ]; then
    echo
    echo "# euserv-describe-services"
    euserv-describe-services

    next 200
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus installed (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus installed (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
