#/bin/bash
#
# This script configures Eucalyptus Support Tasks after a Faststart installation
#
# This should be run immediately after the Faststart Console configuration script
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
keysdir=${bindir%/*/*/*}/keys
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
config=$(hostname -s)
password=
unique=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config] [-p password] [-u]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -c config    configuration (default: $config)"
    echo "  -p password  support private key password (default: none)"
    echo "  -u           create unique support key pair"
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

while getopts Isfc:p:u? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  config="$OPTARG";;
    p)  password="$OPTARG";;
    u)  unique=1;;
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
if [ "$unique" = 1 ]; then
    echo "$(printf '%2d' $step). Create Eucalyptus Administrator Support Keypair"
else
    echo "$(printf '%2d' $step). Import Eucalyptus Administrator Support Keypair"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
if [ "$unique" = 1 ]; then
    echo "euca-create-keypair support | tee ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa"
    echo "ssh-keygen -y -f ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa > ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa.pub"
    echo
    echo "chmod 0600 ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa"
    echo
    echo "ln -s $AWS_DEFAULT_REGION-support_id_rsa ~/.ssh/support_id_rsa"
    echo "ln -s $AWS_DEFAULT_REGION-support_id_rsa.pub ~/.ssh/support_id_rsa.pub"
else
    echo "cat << EOF > ~/.ssh/support_id_rsa"
    cat $keysdir/support_id_rsa
    echo "EOF"
    echo
    echo "chmod 0600 ~/.ssh/support_id_rsa"
    echo
    echo "cat << EOF > ~/.ssh/support_id_rsa.pub"
    cat $keysdir/support_id_rsa.pub
    echo "EOF"
    echo
    echo "euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
fi

if euca-describe-keypairs | cut -f2 | grep -s -q "^support$" && [ -r ~/.ssh/support_id_rsa ]; then
    echo
    tput rev
    echo "Already Imported or Created!"
    tput sgr0

    next 50

else
    euca-delete-keypair support &> /dev/null
    rm -f ~/.ssh/support_id_rsa
    rm -f ~/.ssh/support_id_rsa.pub

    run 50

    if [ $choice = y ]; then
        echo
        if [ "$unique" = 1 ]; then
            echo "# euca-create-keypair support | tee ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa"
            euca-create-keypair support | tee ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa
            echo "# ssh-keygen -y -f ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa > ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa.pub"
            ssh-keygen -y -f ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa > ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa.pub
            echo "#"
            echo "# chmod 0600 ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa"
            chmod 0600 ~/.ssh/$AWS_DEFAULT_REGION-support_id_rsa
            pause

            echo "# ln -s $AWS_DEFAULT_REGION-support_id_rsa ~/.ssh/support_id_rsa"
            ln -s $AWS_DEFAULT_REGION-support_id_rsa ~/.ssh/support_id_rsa
            echo "# ln -s $AWS_DEFAULT_REGION-support_id_rsa.pub ~/.ssh/support_id_rsa.pub"
            ln -s $AWS_DEFAULT_REGION-support_id_rsa.pub ~/.ssh/support_id_rsa.pub
        else
            echo "# cat << EOF > ~/.ssh/support_id_rsa"
            cat $keysdir/support_id_rsa | sed -e 's/^/> /'
            echo "> EOF"
            cp $keysdir/support_id_rsa ~/.ssh/support_id_rsa
            echo "#"
            echo "# chmod 0600 ~/.ssh/support_id_rsa"
            chmod 0600 ~/.ssh/support_id_rsa
            pause

            echo "# cat << EOF > ~/.ssh/support_id_rsa.pub"
            cat $keysdir/support_id_rsa.pub | sed -e 's/^/> /'
            echo "> EOF"
            cp $keysdir/support_id_rsa.pub ~/.ssh/support_id_rsa.pub
            echo "#"
            echo "# euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
            euca-import-keypair -f ~/.ssh/support_id_rsa.pub support
        fi

        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo " $(printf '%2d' $step). Configure Service Image Login"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-modify-property -p services.database.worker.keyname=support"
echo
echo "euca-modify-property -p services.imaging.worker.keyname=support"
echo
echo "euca-modify-property -p services.loadbalancing.worker.keyname=support"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-modify-property -p services.database.worker.keyname=support"
    euca-modify-property -p services.database.worker.keyname=support
    echo "#"
    echo "# euca-modify-property -p services.imaging.worker.keyname=support"
    euca-modify-property -p services.imaging.worker.keyname=support
    echo "#"
    echo "# euca-modify-property -p services.loadbalancing.worker.keyname=support"
    euca-modify-property -p services.loadbalancing.worker.keyname=support

    next 50
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Support configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Support configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
