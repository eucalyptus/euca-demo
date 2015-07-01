#!/bin/bash
#
# This script initializes Eucalyptus with a Demo Account, including:
# - Creates a Demo Account (default name is "demo", but this can be overridden)
# - Creates the Demo Account Administrator Login Profile, allowing the use of the console
# - Downloads the Demo Account Administrator Credentials, allowing use of the API
# - Configures Euca2ools for the Demo Account Administrator, allowing use of the API via euca2ools
# - Configures AWSCLI for the Demo Account Administrator, allowing use of the AWSCLI
# - Authorizes use of the CentOS 6.6 Generic image by the Demo Account
# - Authorizes use of the CentOS 6.6 CFN + AWSCLI image by the Demo Account
#
# The demo-00-initialize.sh script should be run by the Eucalyptus Administrator
# prior to running this script, as this script references images it installs.
# This script should be run by the Eucalyptus Administrator next, then the
# demo-02-initialize-account-dependencies.sh script should be run by the
# Demo Account Administrator to create additional objects in the account.
#
# All three initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
topdir=${bindir%/*/*/*}
keysdir=$topdir/keys
tmpdir=/var/tmp

generic_image=CentOS-6-x86_64-GenericCloud
cfn_awscli_image=Centos-6-x86_64-CFN-AWSCLI


step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo
demo_admin_password=${account}123


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account] [-p password]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
    echo "  -p password password for demo account administrator (default: $demo_admin_password)"
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

while getopts Isfa:p:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
    p)  demo_admin_password="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ]; then
    echo "Could not find $AWS_DEFAULT_REGION Eucalyptus Account Administrator credentials!"
    echo "Expected to find: ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    exit 20
fi


#  5. Prepare Eucalyptus for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "============================================================"
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
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-accountcreate -a $account"

if euare-accountlist | grep -s -q "^$account"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate -a $account"
        euare-accountcreate -a $account

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Login Profile"
echo "    - This allows the Demo Account Administrator to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usermodloginprofile –u admin –p $demo_admin_password -as-account $account"

if euare-usergetloginprofile -u admin --as-account $account &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $account"
        euare-usermodloginprofile -u admin -p $demo_admin_password --as-account $account

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo ($account) Account Administrator Credentials"
echo "    - This allows the Demo Account Administrator to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/admin"
echo
echo "rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip"
echo
echo "sudo euca-get-credentials -u admin -a $account \\"
echo "                          ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip"
echo
echo "unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip \\"
echo "       -d ~/.creds/$AWS_DEFAULT_REGION/$account/admin/"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/admin"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/admin
        pause

        echo "# rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip"
        rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip
        pause

        echo "# sudo euca-get-credentials -u admin -a $account \\"
        echo ">                           ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip"
        sudo euca-get-credentials -u admin -a $account \
                                  ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip
        pause

        echo "# unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip \\"
        echo ">        -d ~/.creds/$AWS_DEFAULT_REGION/$account/admin/"
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/admin.zip \
               -d ~/.creds/$AWS_DEFAULT_REGION/$account/admin/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/admin/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/admin/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc
        fi
        pause

        echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
        cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Euca2ools Profile"
echo "    - This allows the Demo Account Administrator to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[user $account-admin]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"
echo
echo "euca-describe-availability-zones verbose --region $account-admin@$AWS_DEFAULT_REGION"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$secret_key" ~/.euca/euca2ools.ini; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        echo "# echo \"[user $account-admin]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-admin]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        # Invisibly create the ssl variant
        echo "[user $account-admin]" >> ~/.euca/euca2ools-ssl.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $account-admin@$AWS_DEFAULT_REGION"
        euca-describe-availability-zones verbose --region $account-admin@$AWS_DEFAULT_REGION

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator AWSCLI Profile"
echo "    - This allows the Demo Account Administrator to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[profile $AWS_DEFAULT_REGION-$account-admin]\" >> ~/.aws/config"
echo "echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
echo "echo \"output = text\" >> ~/.aws/config"
echo "echo >> ~/.aws/config"
echo
echo "echo \"[$AWS_DEFAULT_REGION-$account-admin]\" >> ~/.aws/credentials"
echo "echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
echo "echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
echo "echo >> ~/.aws/credentials"
echo
echo "aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-$account-admin"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-admin]" ~/.aws/config; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.aws
        chmod 0700 ~/.aws
        echo
        echo "# echo \"[profile $AWS_DEFAULT_REGION-$account-admin]\" >> ~/.aws/config"
        echo "# echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
        echo "# echo \"output = text\" >> ~/.aws/config"
        echo "# echo >> ~/.aws/config"
        echo "[profile $AWS_DEFAULT_REGION-$account-admin]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION" >> ~/.aws/config
        echo "output = text" >> ~/.aws/config
        echo >> ~/.aws/config
        pause

        echo "# echo \"[$AWS_DEFAULT_REGION-$account-admin]\" >> ~/.aws/credentials"
        echo "# echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
        echo "# echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
        echo "# echo >> ~/.aws/credentials"
        echo "[$AWS_DEFAULT_REGION-$account-admin]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-$account-admin"
        aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-$account-admin

        next
    fi
fi


((++step))
account_id=$(euare-accountlist | grep "^$account" | cut -f2)
generic_image_id=$(euca-describe-images | grep $generic_image.raw.manifest.xml | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo Generic Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute -l -a $account_id $generic_image_id"

if euca-describe-images -x $account_id | grep -s -q $generic_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $account_id $generic_image_id"
        euca-modify-image-attribute -l -a $account_id $generic_image_id

        next
    fi
fi


((++step))
account_id=$(euare-accountlist | grep "^$account" | cut -f2)
cfn_awscli_image_id=$(euca-describe-images | grep $cfn_awscli_image.raw.manifest.xml | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo CFN + AWSCLI Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute -l -a $account_id $cfn_awscli_image_id"

if euca-describe-images -x $account_id | grep -s -q $cfn_awscli_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $account_id $cfn_awscli_image_id"
        euca-modify-image-attribute -l -a $account_id $cfn_awscli_image_id

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Demo Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images"
echo
echo "euare-accountlist"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euare-accountlist"
    euare-accountlist

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
unset a; [ $account = demo ] || a=" -a $account"
echo "Please run \"demo-02-initialize-account-dependencies.sh$a\" to complete demo initialization"
