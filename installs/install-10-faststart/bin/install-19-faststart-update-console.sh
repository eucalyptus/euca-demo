#/bin/bash
#
# This script updates the Eucalyptus Console to a later unreleased version
#
# This should be run last, after the system is confirmed to work with the
# released console package.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

eucaconsole_url=http://packages.release.eucalyptus-systems.com/yum/tags/eucalyptus-devel/rhel/6/x86_64/eucaconsole-4.1.1-0.0.7007.481.20150729git963b65b.el6.noarch.rpm

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
config=$(hostname -s)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -c config    configuration (default: $config)"
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

while getopts Isfc:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  config="$OPTARG";;
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

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    sleep 2

    if [ -r /root/admin.zip ]; then
        echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
        cp -a /root/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/
        sleep 2
    else
        echo "Could not convert FastStart Eucalyptus Administrator credentials!"
        echo "Expected to find: /root/admin.zip"
        exit 29
    fi
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo " $(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"

next

echo
echo "# cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
pause

echo "# source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

next


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Stop Eucalyptus Console service and preserve configuration"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "service eucaconsole stop"
echo
echo "mv /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.$(date +%Y%m%d-%H%M).bak"

run 50

if [ $choice = y ]; then
    echo "# service eucaconsole stop"
    service eucaconsole stop

    echo "# mv /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.$(date +%Y%m%d-%H%M).bak"
    mv /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.$(date +%Y%m%d-%H%M).bak

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Newer Eucalyptus Console"
echo "    - This newer console has HP branding and additional service support we want"
echo "      to show prior to 4.2 is released."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "yum install -y $eucaconsole_url"

run 50

if [ $choice = y ]; then
    echo
    echo "# yum install -y $eucaconsole_url"
    # Temporarily deal with 4.1.2 requirement to use downgrade
    #yum install -y $eucaconsole_url
    yum downgrade -y $eucaconsole_url

    # Deal with conflict with dateutils between upgraded console and awscli
    yum reinstall -y python-dateutil

    next 50
fi



((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus Console Configuration file"
echo "    - Using sed to edit file, then displaying changes made"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "sed -i -e \"/^ufshost = localhost\$/s/localhost/$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/\" \\"
echo "       -e \"/^#cloudformation.samples.bucket =/s/^#//\" \\"
echo "       -e \"/^session.secure =/s/= .*\$/= true/\" \\"
echo "       -e \"/^session.secure/a\\"
echo "sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\\\"
echo "sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key\" /etc/eucaconsole/console.ini"

echo
echo "more /etc/eucaconsole/console.ini"

run 150

if [ $choice = y ]; then
    echo
    echo "# sed -i -e \"/^ufshost = localhost\$/s/localhost/$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/\" \\"
    echo ">        -e \"/^#cloudformation.samples.bucket =/s/^#//\" \\"
    echo ">        -e \"/^session.secure =/s/= .*\$/= true/\" \\"
    echo ">        -e \"/^session.secure/a\\"
    echo "> sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\\\"
    echo "> sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key\" /etc/eucaconsole/console.ini"
    sed -i -e "/^ufshost = localhost$/s/localhost/$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/" \
           -e "/^#cloudformation.samples.bucket =/s/^#//" \
           -e "/^session.secure =/s/= .*$/= true/" \
           -e "/^session.secure/a\
sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\
sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key" /etc/eucaconsole/console.ini
    pause

    echo "more /etc/eucaconsole/console.ini"
    more /etc/eucaconsole/console.ini

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Start Eucalyptus Console service"
echo "    - When this step is complete, use browser to verify:"
echo "      https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "chkconfig eucaconsole on"
echo
echo "service eucaconsole start"

run 50

if [ $choice = y ]; then
    echo
    echo "# chkconfig eucaconsole on"
    chkconfig eucaconsole on
    pause

    echo "# service eucaconsole start"
    service eucaconsole start

    next 50
fi


end=$(date +%s)

echo
echo "Eucalyptus Console update complete (time: $(date -u -d @$((end-start)) +"%T"))"
