#!/bin/bash
#
# This script initializes a Management Workstation and its associated Eucalyptus Region with a 
# Demo Account, including:
# - Creates a Demo Account (named "demo" by default)
# - Creates the Demo Account Administrator Login Profile
# - Downloads the Demo Account Administrator Credentials
# - Configures Euca2ools for the Demo Account Administrator
# - Configures AWSCLI for the Demo Account Administrator
# - Authorizes use of the CentOS 6.6 Generic image by the Demo Account
# - Authorizes use of the CentOS 6.6 CFN + AWSCLI image by the Demo Account
#
# The demo-00-initialize.sh script should be run by the Eucalyptus Administrator once prior to
# running this script, as this script references images it installs.
#
# This script should be run by the Eucalyptus Administrator next, as many times as needed to
# create one or more Demo Accounts.
#
# Then the demo-02-initialize-account-administrator.sh script should be run by the Eucalyptus
# Administrator as many times as needed to create one or more IAM Users in the Demo Account
# Administrators Group.
#
# Then the demo-03-initialize-account-dependencies.sh script should be run by the Demo Account
# Administrator or an IAM User in the Administrators Group to create additional groups, users,
# roles and instance profiles in the Demo Account.
#
# All four initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
keysdir=${bindir%/*/*/*}/keys
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
region=${AWS_DEFAULT_REGION#*@}
account=demo
password=${account}123


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ] [-a account] [-p password]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -a account   Eucalyptus Account to create for use in demos (default: $account)"
    echo "  -p password  password for Demo Account Administrator (default: $password)"
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

while getopts Isfr:a:p:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    p)  password="$OPTARG";;
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
      us-east-1|us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $account ]; then
    echo "-a account missing!"
    echo "Could not automatically determine account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $password ]; then
    echo "-p password missing!"
    echo "Password must be specified as a parameter"
    exit 16
fi

profile=$region-admin
profile_region=$profile@$region

if ! grep -s -q "\[user $profile]" ~/.euca/$region.ini; then
    echo "Could not find $region Eucalyptus Account Administrator Euca2ools user!"
    echo "Expected to find: [user $profile] in ~/.euca/$region.ini"
    exit 20
fi

if [ ! -r ~/.creds/$region/eucalyptus/admin/eucarc ]; then
    echo "Could not find $region Eucalyptus Account Administrator credentials!"
    echo "Expected to find: ~/.creds/$region/eucalyptus/admin/eucarc"
    exit 22
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
echo "export AWS_DEFAULT_REGION=$profile_region"
echo "unset AWS_CREDENTIAL_FILE"

next

echo
echo "# export AWS_DEFAULT_REGION=$profile_region"
export AWS_DEFAULT_REGION=$profile_region
echo "# unset AWS_CREDENTIAL_FILE"
unset AWS_CREDENTIAL_FILE

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
echo "euare-usermodloginprofile –u admin –p $password --as-account $account"

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
        echo "# euare-usermodloginprofile -u admin -p $password --as-account $account"
        euare-usermodloginprofile -u admin -p $password --as-account $account

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
echo "mkdir -p ~/.creds/$region/$account/admin"
echo
echo "rm -f ~/.creds/$region/$account/admin.zip"
echo
echo "sudo euca-get-credentials -u admin -a $account \\"
echo "                          ~/.creds/$region/$account/admin.zip"
echo
echo "unzip -uo ~/.creds/$region/$account/admin.zip \\"
echo "       -d ~/.creds/$region/$account/admin/"
echo
echo "cat ~/.creds/$region/$account/admin/eucarc"

if [ -r ~/.creds/$region/$account/admin/eucarc ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/admin"
        mkdir -p ~/.creds/$region/$account/admin
        pause

        echo "# rm -f ~/.creds/$region/$account/admin.zip"
        rm -f ~/.creds/$region/$account/admin.zip
        pause

        echo "# sudo euca-get-credentials -u admin -a $account \\"
        echo ">                           ~/.creds/$region/$account/admin.zip"
        sudo euca-get-credentials -u admin -a $account \
                                  ~/.creds/$region/$account/admin.zip
        pause

        echo "# unzip -uo ~/.creds/$region/$account/admin.zip \\"
        echo ">        -d ~/.creds/$region/$account/admin/"
        unzip -uo ~/.creds/$region/$account/admin.zip \
               -d ~/.creds/$region/$account/admin/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$region/$account/admin/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 ~/.creds/$region/$account/admin/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 ~/.creds/$region/$account/admin/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$region/$account/admin/eucarc
        fi
        pause

        echo "# cat ~/.creds/$region/$account/admin/eucarc"
        cat ~/.creds/$region/$account/admin/eucarc

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
account_id=$(sed -n -e "s/export EC2_ACCOUNT_NUMBER='\(.*\)'$/\1/p" ~/.creds/$region/$account/admin/eucarc)
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/$account/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/$account/admin/eucarc)
private_key=$HOME/.creds/$region/$account/admin/$(sed -n -e "s/export EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$region/$account/admin/eucarc)
certificate=$HOME/.creds/$region/$account/admin/$(sed -n -e "s/export EC2_CERT=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$region/$account/admin/eucarc)

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
echo "cat << EOF >> ~/.euca/$region.ini"
echo "[user $region-$account-admin]"
echo "account-id = $account_id"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo "private-key = $private_key"
echo "certificate = $certificate"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones verbose --region $region-$account-admin@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "\[user $region-$account-admin]" ~/.euca/$region.ini; then
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
        echo "# cat << EOF >> ~/.euca/$region.ini"
        echo "> [user $region-$account-admin]"
        echo "> account-id = $account_id"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo "> private-key = $private_key"
        echo "> certificate = $certificate"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-admin]" >> ~/.euca/$region.ini
        echo "account-id = $account_id"      >> ~/.euca/$region.ini
        echo "key-id = $access_key"          >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"      >> ~/.euca/$region.ini
        echo "private-key = $private_key"    >> ~/.euca/$region.ini
        echo "certificate = $certificate"    >> ~/.euca/$region.ini
        echo                                 >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $region-$account-admin@$region"
        euca-describe-availability-zones verbose --region $region-$account-admin@$region

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/$account/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/$account/admin/eucarc)

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
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-$account-admin]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF >> ~/.aws/credentials"
echo "[$region-$account-admin]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile $region-$account-admin --region $region"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-$account-admin]" ~/.aws/config; then
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
        echo "# cat << EOF >> ~/.aws/config"
        echo "> [profile $region-$account-admin]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-$account-admin]" >> ~/.aws/config
        echo "region = $region"                 >> ~/.aws/config
        echo "output = text"                    >> ~/.aws/config
        echo                                    >> ~/.aws/config
        pause

        echo "# cat << EOF >> ~/.aws/credentials"
        echo "> [$region-$account-admin]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-$account-admin]"             >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"      >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key"  >> ~/.aws/credentials
        echo                                        >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile $region-$account-admin --region $region"
        aws ec2 describe-availability-zones --profile $region-$account-admin --region $region

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


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display Euca2ools Configuration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat /etc/euca2ools/conf.d/$region.ini"
echo
echo "cat ~/.euca/global.ini"
echo
echo "cat ~/.euca/$region.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat /etc/euca2ools/conf.d/$region.ini"
    cat /etc/euca2ools/conf.d/$region.ini
    pause

    echo "# cat ~/.euca/global.ini"
    cat ~/.euca/global.ini
    pause

    echo "# cat ~/.euca/$region.ini"
    cat ~/.euca/$region.ini

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display AWSCLI Configuration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat ~/.aws/config"
echo
echo "cat ~/.aws/credentials"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat ~/.aws/config"
    cat ~/.aws/config
    pause

    echo "# cat ~/.aws/credentials"
    cat ~/.aws/credentials

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
unset a; [ $account = demo ] || a=" -a $account"
unset p; [ $password = ${account}123 ] || p=" -p $password"
echo "Please run \"demo-02-initialize-account-administrator.sh$a$p\" to create at least one User-level Administrator, then"
echo "Please run \"demo-03-initialize-account-dependencies.sh$a$p\" to complete Demo Account initialization"
