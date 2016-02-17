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

if [ -d /var/lib/eucalyptus ]; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        pushd $HOME &> /dev/null

        echo "# bash <(curl -Ls hphelion.com/eucalyptus-install)"

        # There's a bug inside FastStart which causes it to break if it's run inside a shell as is the case here
        # A workaround is to set the region, we save and restore the original region around this
        if [ -n "$AWS_DEFAULT_REGION" ]; then
            save_aws_default_region=$AWS_DEFAULT_REGION
        fi  

        export AWS_DEFAULT_REGION=localhost
        bash <(curl -Ls $faststart_url)
        unset AWS_DEFAULT_REGION

        if [ -n "$save_aws_default_region" ]; then
            export AWS_DEFAULT_REGION=$save_aws_default_region
            unset save_aws_default_region
        fi

        popd &> /dev/null

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Convert FastStart Credentials to Demo Conventions"
echo "    - This section splits the \"localhost\" Region configuration file created"
echo "      by FastStart into a convention which allows for multiple named Regions"
echo "    - We preserve the original \"localhost\" Region configuration file installed"
echo "      with Eucalyptus, so that we can restore this later once a specific Region"
echo "      is configured."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save"
echo
echo "sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
echo "       -e \"s/[0-9]*:admin/localhost-admin/\" \\"
echo "       -e \"/^\\[region/,/^\\user =/p\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini"
echo
echo "sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
echo "       -e \"s/[0-9]*:admin/localhost-admin/\" \\"
echo "       -e \"/^\\[user/,/^account-id =/p\" \\"
echo "       -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini"
echo
echo "cat <<EOF > ~/.euca/global.ini"
echo "; Eucalyptus Global"
echo
echo "[global]"
echo "default-region = localhost"
echo
echo "EOF"
echo
echo "mkdir -p ~/.creds/localhost/eucalyptus/admin"
echo
echo "cat <<EOF > ~/.creds/localhost/eucalyptus/admin/iamrc"
echo "AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)"
echo "AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null)"
echo "EOF"
echo
echo "rm -f ~/.euca/faststart.ini"

if [ ! -r ~/.euca/faststart.ini ]; then
    echo
    tput rev
    echo "Already Converted!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save"
        cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save
        pause

        echo "# sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
        echo ">        -e \"s/[0-9]*:admin/localhost-admin/\" \\"
        echo ">        -e \"/^\\[region/,/^\\user =/p\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini"
        sed -n -e "1i; Eucalyptus Region localhost\n" \
               -e "s/[0-9]*:admin/localhost-admin/" \
               -e "/^\[region/,/^\user =/p" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini
        pause

        echo "# sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
        echo ">        -e \"s/[0-9]*:admin/localhost-admin/\" \\"
        echo ">        -e \"/^\\[user/,/^account-id =/p\" \\"
        echo ">        -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini"
        sed -n -e "1i; Eucalyptus Region localhost\n" \
               -e "s/[0-9]*:admin/localhost-admin/" \
               -e "/^\[user/,/^account-id =/p" \
               -e "\$a\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini
        pause

        echo "cat <<EOF > ~/.euca/global.ini"
        echo "; Eucalyptus Global"
        echo
        echo "[global]"
        echo "default-region = localhost"
        echo
        echo "EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Global"         > ~/.euca/global.ini
        echo                              >> ~/.euca/global.ini
        echo "[global]"                   >> ~/.euca/global.ini
        echo "default-region = localhost" >> ~/.euca/global.ini
        echo                              >> ~/.euca/global.ini
        pause

        echo "# mkdir -p ~/.creds/localhost/eucalyptus/admin"
        mkdir -p ~/.creds/localhost/eucalyptus/admin
        pause

        echo "# cat <<EOF > ~/.creds/localhost/eucalyptus/admin/iamrc"
        echo "> AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)"
        echo "> AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null)"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)    > ~/.creds/localhost/eucalyptus/admin/iamrc
        echo AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null) >> ~/.creds/localhost/eucalyptus/admin/iamrc
        pause

        echo "# rm -f ~/.euca/faststart.ini"
        rm -f ~/.euca/faststart.ini

        next
    fi
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
echo "euca-describe-addresses verbose --region localhost"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-addresses verbose --region localhost"
    euca-describe-addresses verbose --region localhost

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
echo "euserv-describe-services --region localhost"

run 50

if [ $choice = y ]; then
    echo
    echo "# euserv-describe-services --region localhost"
    euserv-describe-services --region localhost

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
