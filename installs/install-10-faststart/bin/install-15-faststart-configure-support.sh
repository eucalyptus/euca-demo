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
password=
unique=0
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-p password] [-u]"
    echo "               [-r region] [-d domain]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -p password  support private key password (default: none)"
    echo "  -u           create unique support key pair"
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -d domain    Eucalyptus Domain (default: $domain)"
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

while getopts Isfp:ur:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    p)  password="$OPTARG";;
    u)  unique=1;;
    r)  region="$OPTARG"
        [ -z $domain ] &&
        domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null);;
    d)  domain="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $region ]; then
    echo "-r region missing!"
    echo "Could not automatically determine region, and it was not specified as a parameter"
    exit 10
else
    case $region in
      us-east-1|us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $domain ]; then
    echo "-d domain missing!"
    echo "Could not automatically determine domain, and it was not specified as a parameter"
    exit 12
fi

user_region=$region-admin@$region

if ! grep -s -q "\[user $region-admin]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Eucalyptus Administrator Euca2ools user!"
    echo "Expected to find: [user $region-admin] in ~/.euca/$region.ini"
    exit 50
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
if [ "$unique" = 0 ]; then
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Configure Support Keypair"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "cat << EOF > ~/.ssh/support_id_rsa"
    cat $keysdir/support_id_rsa
    echo "EOF"
    echo
    echo "chmod 0600 ~/.ssh/support_id_rsa"
    echo
    echo "cat << EOF > ~/.ssh/support_id_rsa.pub"
    cat $keysdir/support_id_rsa.pub
    echo "EOF"

    if [ -r ~/.ssh/support_id_rsa -a -r ~/.ssh/support_id_rsa.pub ]; then
        echo
        tput rev
        echo "Already Created!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            echo
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

            next
        fi
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
if [ "$unique" = 1 ]; then
    echo "$(printf '%2d' $step). Create Imaging Service Support Keypair"
else
    echo "$(printf '%2d' $step). Import Imaging Service Support Keypair"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "imaging_arn=\$(euare-rolelistbypath --path-prefix '/imaging' --as-account '(eucalyptus)imaging')"
echo "eval \$(euare-assumerole \$imaging_arn)"
echo
if [ "$unique" = 1 ]; then
    echo "euca-create-keypair support | tee ~/.ssh/$region-imaging-support_id_rsa"
    echo "ssh-keygen -y -f ~/.ssh/$region-imaging-support_id_rsa > ~/.ssh/$region-imaging-support_id_rsa.pub"
    echo
    echo "chmod 0600 ~/.ssh/$region-imaging-support_id_rsa"
    echo
    echo "ln -s $region-imaging-support_id_rsa ~/.ssh/imaging-support_id_rsa"
    echo "ln -s $region-imaging-support_id_rsa.pub ~/.ssh/imaging-support_id_rsa.pub"
else
    echo "euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
fi
echo
echo "eval \$(euare-releaserole)"

imaging_arn=$(euare-rolelistbypath --path-prefix '/imaging' --as-account '(eucalyptus)imaging')
eval $(euare-assumerole $imaging_arn)
imaging_keypairs=$(euca-describe-keypairs | cut -f2 | grep "^support$")
eval $(euare-releaserole)

if [ "$imaging_keypairs" = "support" ]; then
    echo
    tput rev
    if [ "$unique" = 1 ]; then
        echo "Already Created!"
    else
        echo "Already Imported!"
    fi
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# imaging_arn=\$(euare-rolelistbypath --path-prefix '/imaging' --as-account '(eucalyptus)imaging')"
        imaging_arn=$(euare-rolelistbypath --path-prefix '/imaging' --as-account '(eucalyptus)imaging')
        echo "# eval \$(euare-assumerole \$imaging_arn)"
        eval $(euare-assumerole $imaging_arn)
        echo "#"
        if [ "$unique" = 1 ]; then
            echo "# euca-create-keypair support | tee ~/.ssh/$region-imaging-support_id_rsa"
            euca-create-keypair support | tee ~/.ssh/$region-imaging-support_id_rsa
            echo "# ssh-keygen -y -f ~/.ssh/$region-imaging-support_id_rsa > ~/.ssh/$region-imaging-support_id_rsa.pub"
            ssh-keygen -y -f ~/.ssh/$region-imaging-support_id_rsa > ~/.ssh/$region-imaging-support_id_rsa.pub
            echo "#"
            echo "# chmod 0600 ~/.ssh/$region-imaging-support_id_rsa"
            chmod 0600 ~/.ssh/$region-imaging-support_id_rsa
            echo "#"
            echo "# ln -s $region-imaging-support_id_rsa ~/.ssh/imaging-support_id_rsa"
            ln -s $region-imaging-support_id_rsa ~/.ssh/imaging-support_id_rsa
            echo "# ln -s $region-imaging-support_id_rsa.pub ~/.ssh/imaging-support_id_rsa.pub"
            ln -s $region-imaging-support_id_rsa.pub ~/.ssh/imaging-support_id_rsa.pub
        else
            echo "# euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
            euca-import-keypair -f ~/.ssh/support_id_rsa.pub support
        fi
        echo "#"
        echo "# eval \$(euare-releaserole)"
        eval $(euare-releaserole)

        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
if [ "$unique" = 1 ]; then
    echo "$(printf '%2d' $step). Create LoadBalancing Service Support Keypair"
else
    echo "$(printf '%2d' $step). Import LoadBalancing Service Support Keypair"
fi
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "loadbalancing_arn=\$(euare-rolelistbypath --path-prefix '/loadbalancing' --as-account '(eucalyptus)loadbalancing')"
echo "eval \$(euare-assumerole \$loadbalancing_arn)"
echo
if [ "$unique" = 1 ]; then
    echo "euca-create-keypair support | tee ~/.ssh/$region-loadbalancing-support_id_rsa"
    echo "ssh-keygen -y -f ~/.ssh/$region-loadbalancing-support_id_rsa > ~/.ssh/$region-loadbalancing-support_id_rsa.pub"
    echo
    echo "chmod 0600 ~/.ssh/$region-loadbalancing-support_id_rsa"
    echo
    echo "ln -s $region-loadbalancing-support_id_rsa ~/.ssh/loadbalancing-support_id_rsa"
    echo "ln -s $region-loadbalancing-support_id_rsa.pub ~/.ssh/loadbalancing-support_id_rsa.pub"
else
    echo "euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
fi
echo
echo "eval \$(euare-releaserole)"

loadbalancing_arn=$(euare-rolelistbypath --path-prefix '/loadbalancing' --as-account '(eucalyptus)loadbalancing')
eval $(euare-assumerole $loadbalancing_arn)
loadbalancing_keypairs=$(euca-describe-keypairs | cut -f2 | grep "^support$")
eval $(euare-releaserole)

if [ "$loadbalancing_keypairs" = "support" ]; then
    echo
    tput rev
    if [ "$unique" = 1 ]; then
        echo "Already Created!"
    else
        echo "Already Imported!"
    fi
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# loadbalancing_arn=\$(euare-rolelistbypath --path-prefix '/loadbalancing' --as-account '(eucalyptus)loadbalancing')"
        loadbalancing_arn=$(euare-rolelistbypath --path-prefix '/loadbalancing' --as-account '(eucalyptus)loadbalancing')
        echo "# eval \$(euare-assumerole \$loadbalancing_arn)"
        eval $(euare-assumerole $loadbalancing_arn)
        echo "#"
        if [ "$unique" = 1 ]; then
            echo "# euca-create-keypair support | tee ~/.ssh/$region-loadbalancing-support_id_rsa"
            euca-create-keypair support | tee ~/.ssh/$region-loadbalancing-support_id_rsa
            echo "# ssh-keygen -y -f ~/.ssh/$region-loadbalancing-support_id_rsa > ~/.ssh/$region-loadbalancing-support_id_rsa.pub"
            ssh-keygen -y -f ~/.ssh/$region-loadbalancing-support_id_rsa > ~/.ssh/$region-loadbalancing-support_id_rsa.pub
            echo "#"
            echo "# chmod 0600 ~/.ssh/$region-loadbalancing-support_id_rsa"
            chmod 0600 ~/.ssh/$region-loadbalancing-support_id_rsa
            echo "#"
            echo "# ln -s $region-loadbalancing-support_id_rsa ~/.ssh/loadbalancing-support_id_rsa"
            ln -s $region-loadbalancing-support_id_rsa ~/.ssh/loadbalancing-support_id_rsa
            echo "# ln -s $region-loadbalancing-support_id_rsa.pub ~/.ssh/loadbalancing-support_id_rsa.pub"
            ln -s $region-loadbalancing-support_id_rsa.pub ~/.ssh/loadbalancing-support_id_rsa.pub
        else
            echo "# euca-import-keypair -f ~/.ssh/support_id_rsa.pub support"
            euca-import-keypair -f ~/.ssh/support_id_rsa.pub support
        fi
        echo "#"
        echo "# eval \$(euare-releaserole)"
        eval $(euare-releaserole)

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
echo "euctl services.imaging.worker.keyname=support --region localhost"
echo
echo "euctl services.loadbalancing.worker.keyname=support --region localhost"

if [ "$(euctl -n services.imaging.worker.keyname --region localhost)" = "support" -a \
     "$(euctl -n services.loadbalancing.worker.keyname --region localhost)" = "support" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl services.imaging.worker.keyname=support --region localhost"
        euctl services.imaging.worker.keyname=support --region localhost
        echo "#"
        echo "# euctl services.loadbalancing.worker.keyname=support --region localhost"
        euctl services.loadbalancing.worker.keyname=support --region localhost

        next 50
    fi
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Support configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Support configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
