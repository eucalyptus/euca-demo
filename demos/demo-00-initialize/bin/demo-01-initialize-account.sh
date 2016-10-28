#!/bin/bash
#
# This script initializes a Management Workstation and its associated Eucalyptus Region with a 
# Demo Account, including:
# - Creates a Demo Account (named "demo" by default)
# - Creates the Demo Account Administrator Login Profile
# - Downloads the Demo Account Administrator Credentials
# - Configures Euca2ools for the Demo Account Administrator
# - Configures AWSCLI for the Demo Account Administrator
# - Authorizes use of the CentOS 6 Cloud image by the Demo Account
# - Authorizes use of the CentOS 7 Cloud image by the Demo Account
# - Authorizes use of the Ubuntu Trusty Cloud image by the Demo Account
# - Authorizes use of the Ubuntu Xenial Cloud image by the Demo Account
# - Authorizes use of the CentOS 6 CFN + AWSCLI image by the Demo Account
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

centos6_image=CentOS-6-x86_64-GenericCloud
centos7_image=CentOS-7-x86_64-GenericCloud
ubuntu_trusty_image=trusty-server-cloudimg-amd64-disk1
ubuntu_xenial_image=xenial-server-cloudimg-amd64-disk1
cfn_awscli_image=CentOS-6-x86_64-CFN-AWSCLI

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
verbose=0
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
password=${account}123


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-p password]"
    echo "               [-r region] [-a account]"
    echo "  -I           non-interactive"
    echo "  -s           slower: increase pauses by 25%"
    echo "  -f           faster: reduce pauses by 25%"
    echo "  -v           verbose"
    echo "  -p password  password for Demo Account Administrator (default: $password)"
    echo "  -r region    Eucalyptus Region (default: $region)"
    echo "  -a account   Eucalyptus Account to create for use in demos (default: $account)"
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

while getopts Isfvp:r:a:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    p)  password="$OPTARG";;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
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

if [ -z $account ]; then
    echo "-a account missing!"
    echo "Could not automatically determine account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $password ]; then
    echo "-p password missing!"
    echo "Password must be specified as a parameter"
    exit 18
fi

user_region=$region-admin@$region

if ! grep -s -q "\[user $region-admin]" ~/.euca/$region.ini; then
    echo "Could not find Eucalyptus ($region) Region Eucalyptus Administrator Euca2ools user!"
    echo "Expected to find: [user $region-admin] in ~/.euca/$region.ini"
    exit 50
fi

profile=$region-admin

if ! grep -s -q "\[profile $profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($region) Region Eucalyptus Administrator AWSCLI profile!"
    echo "Expected to find: [profile $profile] in ~/.aws/config"
    exit 51
fi

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Prepare Eucalyptus for Demos

start=$(date +%s)

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
echo "euare-accountcreate --region $user_region $account"

if euare-accountlist --region $user_region | grep -s -q "^$account"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-accountcreate --region $user_region $account"
        euare-accountcreate --region $user_region $account

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
echo "euare-useraddloginprofile --password $password --as-account $account \\"
echo "                          --region $user_region \\"
echo "                          admin"

if euare-usergetloginprofile --as-account $account --region $user_region admin &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile --password $password --as-account $account \\"
        echo ">                           --region $user_region \\"
        echo ">                           admin"
        euare-useraddloginprofile --password $password --as-account $account \
                                  --region $user_region \
                                  admin

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Access Key"
echo "    - This allows the Demo Account Administrator to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$region/$account/admin"
echo
echo "euare-useraddkey --as-account $account --region $user_region admin"
echo
echo "cat << EOF > ~/.creds/$region/$account/admin/iamrc"
echo "AWSAccessKeyId=<generated_access_key>"
echo "AWSSecretKey=<generated_secret_key>"
echo "EOF"
echo
echo "chmod 0600 ~/.creds/$region/$account/admin/iamrc"

if [ -r ~/.creds/$region/$account/admin/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$region/$account/admin"
        mkdir -p ~/.creds/$region/$account/admin
        pause

        echo "# euare-useraddkey --as-account $account --region $user_region admin"
        result=$(euare-useraddkey --as-account $account --region $user_region admin) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "# cat << EOF > ~/.creds/$region/$account/admin/iamrc"
        echo "> AWSAccessKeyId=$access_key"
        echo "> AWSSecretKey=$secret_key"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$region/$account/admin/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$region/$account/admin/iamrc
        echo "#"
        echo "# chmod 0600 ~/.creds/$region/$account/admin/iamrc"
        chmod 0600 ~/.creds/$region/$account/admin/iamrc

        next
    fi
fi


((++step))
# Obtain some values from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/admin/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/admin/iamrc)
# Obtain other value direct
account_id=$(euare-accountlist --region $user_region | grep ^$account | cut -f2)

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
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo "account-id = $account_id"
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
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo "> account-id = $account_id"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[user $region-$account-admin]" >> ~/.euca/$region.ini
        echo "key-id = $access_key"          >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"      >> ~/.euca/$region.ini
        echo "account-id = $account_id"      >> ~/.euca/$region.ini
        echo                                 >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $region-$account-admin@$region"
        euca-describe-availability-zones verbose --region $region-$account-admin@$region

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$region/$account/admin/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$region/$account/admin/iamrc)

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
echo "aws ec2 describe-availability-zones --profile $region-$account-admin --region $region --output text"

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

        echo "# aws ec2 describe-availability-zones --profile $region-$account-admin --region $region --output text"
        aws ec2 describe-availability-zones --profile $region-$account-admin --region $region --output text

        next
    fi
fi


((++step))
account_id=$(euare-accountlist --region $user_region | grep "^$account" | cut -f2)
centos6_image_id=$(euca-describe-images --filter manifest-location=images/$centos6_image.raw.manifest.xml \
                                        --region $user_region | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo CentOS 6 Cloud Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute --launch-permission --add $account_id \\"
echo "                            --region $user_region \\"
echo "                            $centos6_image_id"

if euca-describe-images --executable-by $account_id --region $user_region | grep -s -q $centos6_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute --launch-permission --add $account_id \\"
        echo ">                             --region $user_region \\"
        echo ">                             $centos6_image_id"
        euca-modify-image-attribute --launch-permission --add $account_id \
                                    --region $user_region \
                                    $centos6_image_id

        next
    fi
fi


((++step))
account_id=$(euare-accountlist --region $user_region | grep "^$account" | cut -f2)
centos7_image_id=$(euca-describe-images --filter manifest-location=images/$centos7_image.raw.manifest.xml \
                                        --region $user_region | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo CentOS 7 Cloud Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute --launch-permission --add $account_id \\"
echo "                            --region $user_region \\"
echo "                            $centos7_image_id"

if euca-describe-images --executable-by $account_id --region $user_region | grep -s -q $centos7_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute --launch-permission --add $account_id \\"
        echo ">                             --region $user_region \\"
        echo ">                             $centos7_image_id"
        euca-modify-image-attribute --launch-permission --add $account_id \
                                    --region $user_region \
                                    $centos7_image_id

        next
    fi
fi


((++step))
account_id=$(euare-accountlist --region $user_region | grep "^$account" | cut -f2)
ubuntu_trusty_image_id=$(euca-describe-images --filter manifest-location=images/$ubuntu_trusty_image.raw.manifest.xml \
                                              --region $user_region | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo Ubuntu Trusty Cloud Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute --launch-permission --add $account_id \\"
echo "                            --region $user_region \\"
echo "                            $ubuntu_trusty_image_id"

if euca-describe-images --executable-by $account_id --region $user_region | grep -s -q $ubuntu_trusty_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute --launch-permission --add $account_id \\"
        echo ">                             --region $user_region \\"
        echo ">                             $ubuntu_trusty_image_id"
        euca-modify-image-attribute --launch-permission --add $account_id \
                                    --region $user_region \
                                    $ubuntu_trusty_image_id

        next
    fi
fi


((++step))
account_id=$(euare-accountlist --region $user_region | grep "^$account" | cut -f2)
ubuntu_xenial_image_id=$(euca-describe-images --filter manifest-location=images/$ubuntu_xenial_image.raw.manifest.xml \
                                              --region $user_region | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo Ubuntu Xenial Cloud Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute --launch-permission --add $account_id \\"
echo "                            --region $user_region \\"
echo "                            $ubuntu_xenial_image_id"

if euca-describe-images --executable-by $account_id --region $user_region | grep -s -q $ubuntu_xenial_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute --launch-permission --add $account_id \\"
        echo ">                             --region $user_region \\"
        echo ">                             $ubuntu_xenial_image_id"
        euca-modify-image-attribute --launch-permission --add $account_id \
                                    --region $user_region \
                                    $ubuntu_xenial_image_id

        next
    fi
fi


((++step))
account_id=$(euare-accountlist --region $user_region | grep "^$account" | cut -f2)
cfn_awscli_image_id=$(euca-describe-images --filter "manifest-location=images/$cfn_awscli_image.raw.manifest.xml" \
                                           --region $user_region | cut -f2)

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
echo "euca-modify-image-attribute --launch-permission --add $account_id \\"
echo "                            --region $user_region \\"
echo "                            $cfn_awscli_image_id"

if euca-describe-images --executable-by $account_id --region $user_region | grep -s -q $cfn_awscli_image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute --launch-permission --add $account_id \\"
        echo ">                             --region $user_region \\"
        echo ">                             $cfn_awscli_image_id"
        euca-modify-image-attribute --launch-permission --add $account_id \
                                    --region $user_region \
                                    $cfn_awscli_image_id

        next
    fi
fi


((++step))
if [ $verbose = 1 ]; then
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
    echo "euca-describe-images --region $user_region"
    echo
    echo "euare-accountlist --region $user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-images --region $user_region"
        euca-describe-images --region $user_region
        pause

        echo "# euare-accountlist --region $user_region"
        euare-accountlist --region $user_region

        next 200
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Display Euca2ools Configuration"
    echo "    - The $region Region should be the default."
    echo "    - The $region Region should be configured with Custom"
    echo "      DNS HTTPS URLs. It can be used from other hosts."
    echo "    - The localhost Region should be configured with direct"
    echo "      URLs. It can be used only from this host."
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "cat ~/.euca/global.ini"
    echo
    echo "cat /etc/euca2ools/conf.d/$region.ini"
    echo
    echo "cat /etc/euca2ools/conf.d/localhost.ini"
    echo
    echo "cat ~/.euca/$region.ini"
    echo
    echo "cat ~/.euca/localhost.ini"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat ~/.euca/global.ini"
        cat ~/.euca/global.ini
        pause

        echo "# cat /etc/euca2ools/conf.d/$region.ini"
        cat /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# cat /etc/euca2ools/conf.d/localhost.ini"
        cat /etc/euca2ools/conf.d/localhost.ini
        pause

        echo "# cat ~/.euca/$region.ini"
        cat ~/.euca/$region.ini
        pause

        echo "# cat ~/.euca/localhost.ini"
        cat ~/.euca/localhost.ini

        next 200
    fi
fi


((++step))
if [ $verbose = 1 ]; then
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
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus Account configured for demo scripts (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
unset a; [ $account = demo ] || a=" -a $account"
unset p; [ $password = ${account}123 ] || p=" -p $password"
echo "Please run \"demo-02-initialize-account-administrator.sh$a$p\" to create at least one User-level Administrator, then"
echo "Please run \"demo-03-initialize-account-dependencies.sh$a$p\" to complete Demo Account initialization"
