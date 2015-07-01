#!/bin/bash
#
# This script initializes a Demo Account within Eucalyptus with dependencies used in demos, including:
# - Confirms the Demo Image is available to the Demo Account
# - Imports the Demo Keypair into the Demo Account
# - Creates a demo User (named "demo"), as an example User within the Demos Group
# - Creates the demo User Login Profile, allowing the use of the console
# - Creates the demo User Access Key, allowing use of the API
# - Configures Euca2ools for the demo User, allowing use of the API via Euca2ools
# - Configures AWSCLI for the demo User, allowing use of the AWSCLI
# - Creates a developer User (named "developer"), an an example User within the Developers Group
# - Creates the developer User Login Profile, allowing the use of the console
# - Creates the developer User Access Key, allowing use of the API
# - Configures Euca2ools for the developer User, allowing use of the API via Euca2ools
# - Configures AWSCLI for the developer User, allowing use of the AWSCLI
# - Creates a user User (named "user"), as an example User within the Users Group
# - Creates the user User Login Profile, allowing the use of the console
# - Creates the user User Access Key, allowing use of the API
# - Configures Euca2ools for the user User, allowing use of the API via Euca2ools
# - Configures AWSCLI for the user User, allowing use of the AWSCLI
# - Creates the Demos Group (named "Demos"), used for Users which create, own and manage Resources
# - Creates the Demos Group Policy, which allows full access to all Resources, except Users and Groups
# - Adds the demo User to the Demos Group
# - Creates the Developers Group (named "Developers"), used for Users which have developer-level control of Resources
# - Creates the Developers Group Policy, which allows full access to all Resources, except Users and Groups
# - Adds the developer User to the Developers Group
# - Creates the Users Group (named "Users"), used for Users which have read-only visibility to Resources
# - Creates the Users Group Policy, which allows read-only access to all Resources
# - Adds the user User to the Users Group
# - Creates the Demos Role (named "Demos"), and associated Instance Profile (named "Demos")
# - Creates the Demos Role Policy, which allows read-only access to Demo Resources, and write access to an S3 bucket used in Demos.
# - Lists Demo Resources
# - Displays Euca2ools Configuration
# - Displays AWSCLI Configuration
#
# The demo-00-initialize.sh and demo-01-initialize-account.sh scripts should both be run by the
# Eucalyptus Administrator prior to running this script, as those scripts create images and
# the account referenced in this script.
# This script should be run by the Demo Account Administrator last, so all operations are done
# within the context of the Demo Account.
#
# All three initialization scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
policiesdir=${bindir%/*}
topdir=${bindir%/*/*/*}
keysdir=$topdir/keys
tmpdir=/var/tmp

user_demo=demo
user_developer=developer
user_user=user

group_demos=Demos
group_developers=Developers
group_users=Users

role_demos=Demos
instance_profile_demos=Demos

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo
password=${account}123
user_demo_password=${password}-${user_demo}
user_developer_password=${password}-${user_developer}
user_user_password=${password}-${user_user}


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account] [-p password]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
    echo "  -p password password prefix for demo account users (default: $password)"
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
    p)  password="$OPTARG"
        user_demo_password=${password}-${user_demo}
        user_developer_password=${password}-${user_developer}
        user_user_password=${password}-${user_user};;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc ]; then
    echo "-a $account invalid: Could not find $AWS_DEFAULT_REGION Demo Account Administrator credentials!"
    echo "   Expected to find: ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
    exit 21
fi

mkdir -p $tmpdir/$account


#  5. Prepare Eucalyptus Demo Account for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Use Demo ($account) Account Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
echo
echo "source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"

next

echo
echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc
pause

echo "# source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
source ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc

next


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List Images available to Demo ($account) Account Administrator"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-describe-images -a"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images -a"
    euca-describe-images -a

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Import Demo ($account) Account Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > ~/.ssh/demo_id_rsa"
cat $keysdir/demo_id_rsa
echo "EOF"
echo
echo "chmod 0600 ~/.ssh/demo_id_rsa"
echo
echo "cat << EOF > ~/.ssh/demo_id_rsa.pub"
cat $keysdir/demo_id_rsa.pub
echo "EOF"
echo
echo "euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo"

if euca-describe-keypairs | cut -f2 | grep -s -q "^demo$" && [ -r ~/.ssh/demo_id_rsa ]; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    euca-delete-keypair demo &> /dev/null
    rm -f ~/.ssh/demo_id_rsa
    rm -f ~/.ssh/demo_id_rsa.pub

    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > ~/.ssh/demo_id_rsa"
        cat $keysdir/demo_id_rsa | sed -e 's/^/> /'
        echo "> EOF"
        cp $keysdir/demo_id_rsa ~/.ssh/demo_id_rsa
        echo "#"
        echo "# chmod 0600 ~/.ssh/demo_id_rsa"
        chmod 0600 ~/.ssh/demo_id_rsa
        pause

        echo "# cat << EOF > ~/.ssh/demo_id_rsa.pub"
        cat $keysdir/demo_id_rsa.pub | sed -e 's/^/> /'
        echo "> EOF"
        cp $keysdir/demo_id_rsa.pub ~/.ssh/demo_id_rsa.pub
        pause

        echo "# euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo"
        euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_demo"

if euare-userlistbypath | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_demo"
        euare-usercreate -u $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Login Profile"
echo "    - This allows the Demo Account Demo User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_demo -p $user_demo_password"

if euare-usergetloginprofile -u $user_demo &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_demo -p $user_demo_password"
        euare-useraddloginprofile -u $user_demo -p $user_demo_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Access Key"
echo "    - This allows the Demo Account Demo User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo"
echo
echo "euare-useraddkey -u $user_demo"
echo
echo "echo \"AWSAccessKeyId=<generated_access_key>\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"
echo "echo \"AWSSecretKey=<generated_secret_key>\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo
        pause

        echo "# euare-useraddkey -u $user_demo"
        result=$(euare-useraddkey -u $user_demo) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "echo \"AWSAccessKeyId=$access_key\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"
        echo "echo \"AWSSecretKey=$secret_key\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc"
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc

        next
    fi
fi



((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User Euca2ools Profile"
echo "    - This allows the Demo Account Demo User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[user $account-$user_demo]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"

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
        echo "# echo \"[user $account-$user_demo]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-$user_demo]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        # Invisibly create the ssl variant
        echo "[user $account-$user_demo]" >> ~/.euca/euca2ools-ssl.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_demo/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demo ($user_demo) User AWSCLI Profile"
echo "    - This allows the Demo Account Demo User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[profile $AWS_DEFAULT_REGION-$account-$user_demo]\" >> ~/.aws/config"
echo "echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
echo "echo \"output = text\" >> ~/.aws/config"
echo "echo >> ~/.aws/config"
echo
echo "echo \"[$AWS_DEFAULT_REGION-$account-$user_demo]\" >> ~/.aws/credentials"
echo "echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
echo "echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
echo "echo >> ~/.aws/credentials"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_demo]" ~/.aws/config; then
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
        echo "# echo \"[profile $AWS_DEFAULT_REGION-$account-$user_demo]\" >> ~/.aws/config"
        echo "# echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
        echo "# echo \"output = text\" >> ~/.aws/config"
        echo "# echo >> ~/.aws/config"
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_demo]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION" >> ~/.aws/config
        echo "output = text" >> ~/.aws/config
        echo >> ~/.aws/config
        pause

        echo "# echo \"[$AWS_DEFAULT_REGION-$account-$user_demo]\" >> ~/.aws/credentials"
        echo "# echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
        echo "# echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
        echo "# echo >> ~/.aws/credentials"
        echo "[$AWS_DEFAULT_REGION-$account-$user_demo]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo >> ~/.aws/credentials
        pause

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_developer"

if euare-userlistbypath | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_developer"
        euare-usercreate -u $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Login Profile"
echo "    - This allows the Demo Account Developer User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_developer -p $user_developer_password"

if euare-usergetloginprofile -u $user_developer &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_developer -p $user_developer_password"
        euare-useraddloginprofile -u $user_developer -p $user_developer_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Access Key"
echo "    - This allows the Demo Account Developer User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer"
echo
echo "euare-useraddkey -u $user_developer"
echo
echo "echo \"AWSAccessKeyId=<generated_access_key>\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"
echo "echo \"AWSSecretKey=<generated_secret_key>\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer
        pause

        echo "# euare-useraddkey -u $user_developer"
        result=$(euare-useraddkey -u $user_developer) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "echo \"AWSAccessKeyId=$access_key\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"
        echo "echo \"AWSSecretKey=$secret_key\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc"
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc

        next
    fi
fi



((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User Euca2ools Profile"
echo "    - This allows the Demo Account Developer User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[user $account-$user_developer]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"

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
        echo "# echo \"[user $account-$user_developer]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-$user_developer]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        # Invisibly create the ssl variant
        echo "[user $account-$user_developer]" >> ~/.euca/euca2ools-ssl.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_developer/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($user_developer) User AWSCLI Profile"
echo "    - This allows the Demo Account Developer User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[profile $AWS_DEFAULT_REGION-$account-$user_developer]\" >> ~/.aws/config"
echo "echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
echo "echo \"output = text\" >> ~/.aws/config"
echo "echo >> ~/.aws/config"
echo
echo "echo \"[$AWS_DEFAULT_REGION-$account-$user_developer]\" >> ~/.aws/credentials"
echo "echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
echo "echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
echo "echo >> ~/.aws/credentials"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_developer]" ~/.aws/config; then
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
        echo "# echo \"[profile $AWS_DEFAULT_REGION-$account-$user_developer]\" >> ~/.aws/config"
        echo "# echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
        echo "# echo \"output = text\" >> ~/.aws/config"
        echo "# echo >> ~/.aws/config"
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_developer]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION" >> ~/.aws/config
        echo "output = text" >> ~/.aws/config
        echo >> ~/.aws/config
        pause

        echo "# echo \"[$AWS_DEFAULT_REGION-$account-$user_developer]\" >> ~/.aws/credentials"
        echo "# echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
        echo "# echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
        echo "# echo >> ~/.aws/credentials"
        echo "[$AWS_DEFAULT_REGION-$account-$user_developer]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo >> ~/.aws/credentials

        next
    fi
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $user_user"

if euare-userlistbypath | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $user_user"
        euare-usercreate -u $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Login Profile"
echo "    - This allows the Demo Account User User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $user_user -p $user_user_password"

if euare-usergetloginprofile -u $user_user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $user_user -p $user_user_password"
        euare-useraddloginprofile -u $user_user -p $user_user_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Access Key"
echo "    - This allows the Demo Account User User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user"
echo
echo "euare-useraddkey -u $user_user"
echo
echo "echo \"AWSAccessKeyId=<generated_access_key>\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"
echo "echo \"AWSSecretKey=<generated_secret_key>\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user
        pause

        echo "# euare-useraddkey -u $user_user"
        result=$(euare-useraddkey -u $user_user) && echo $result
        read access_key secret_key <<< $result
        pause

        echo "echo \"AWSAccessKeyId=$access_key\"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"
        echo "echo \"AWSSecretKey=$secret_key\"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc"
        echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc
        echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc

        next
    fi
fi



((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User Euca2ools Profile"
echo "    - This allows the Demo Account User User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[user $account-$user_user]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"

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
        echo "# echo \"[user $account-$user_user]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-$user_user]" >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        # Invisibly create the ssl variant
        echo "[user $account-$user_user]" >> ~/.euca/euca2ools-ssl.ini
        echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
        echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini

        next
    fi
fi


((++step))
# Obtain all values we need from iamrc
access_key=$(sed -n -e "s/AWSAccessKeyId=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)
secret_key=$(sed -n -e "s/AWSSecretKey=\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$user_user/iamrc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($user_user) User AWSCLI Profile"
echo "    - This allows the Demo Account User User to run AWSCLI commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "echo \"[profile $AWS_DEFAULT_REGION-$account-$user_user]\" >> ~/.aws/config"
echo "echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
echo "echo \"output = text\" >> ~/.aws/config"
echo "echo >> ~/.aws/config"
echo
echo "echo \"[$AWS_DEFAULT_REGION-$account-$user_user]\" >> ~/.aws/credentials"
echo "echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
echo "echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
echo "echo >> ~/.aws/credentials"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-$account-$user_user]" ~/.aws/config; then
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
        echo "# echo \"[profile $AWS_DEFAULT_REGION-$account-$user_user]\" >> ~/.aws/config"
        echo "# echo \"region = $AWS_DEFAULT_REGION\" >> ~/.aws/config"
        echo "# echo \"output = text\" >> ~/.aws/config"
        echo "# echo >> ~/.aws/config"
        echo "[profile $AWS_DEFAULT_REGION-$account-$user_user]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION" >> ~/.aws/config
        echo "output = text" >> ~/.aws/config
        echo >> ~/.aws/config
        pause

        echo "# echo \"[$AWS_DEFAULT_REGION-$account-$user_user]\" >> ~/.aws/credentials"
        echo "# echo \"aws_access_key_id = $access_key\" >> ~/.aws/credentials"
        echo "# echo \"aws_secret_access_key = $secret_key\" >> ~/.aws/credentials"
        echo "# echo >> ~/.aws/credentials"
        echo "[$AWS_DEFAULT_REGION-$account-$user_user]" >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo >> ~/.aws/credentials

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Group"
echo "    - This Group is intended for Demos which have Administrator access to Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_demos"

if euare-grouplistbypath | grep -s -q ":group/$group_demos$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_demos"
        euare-groupcreate -g $group_demos

        next
    fi
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Group Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_demos}GroupPolicy.json"
cat $policiesdir/DemosGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \\"
echo "                        -f $tmpdir/$account/${group_demos}GroupPolicy.json"


if euare-grouplistpolicies -g $group_demos | grep -s -q "${group_demos}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_demos}GroupPolicy.json"
        cat $policiesdir/DemosGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosGroupPolicy.json $tmpdir/$account/${group_demos}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_demos}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_demos -p ${group_demos}Policy \
                                -f $tmpdir/$account/${group_demos}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Demos ($group_demos) Group members"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_demos -u $user_demo"

if euare-grouplistusers -g $group_demos | grep -s -q ":user/$user_demo$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_demos -u $user_demo"
        euare-groupadduser -g $group_demos -u $user_demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($group_developers) Group"
echo "    - This Group is intended for Developers who can modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_developers"

if euare-grouplistbypath | grep -s -q ":group/$group_developers$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_developers"
        euare-groupcreate -g $group_developers

        next
    fi
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($group_developers) Group Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_developers}GroupPolicy.json"
cat $policiesdir/DevelopersGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \\"
echo "                        -f $tmpdir/$account/${group_developers}GroupPolicy.json"


if euare-grouplistpolicies -g $group_developers | grep -s -q "${group_developers}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_developers}GroupPolicy.json"
        cat $policiesdir/DevelopersGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DevelopersGroupPolicy.json $tmpdir/$account/${group_developers}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_developers}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_developers -p ${group_developers}Policy \
                                -f $tmpdir/$account/${group_developers}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Developers ($group_developers) Group members"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_developers -u $user_developer"

if euare-grouplistusers -g $group_developers | grep -s -q ":user/$user_developer$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_developers -u $user_developer"
        euare-groupadduser -g $group_developers -u $user_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($group_users) Group"
echo "    - This Group is intended for Users who can view but not modify Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $group_users"

if euare-grouplistbypath | grep -s -q ":group/$group_users$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $group_users"
        euare-groupcreate -g $group_users

        next
    fi
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($group_users) Group Policy"
echo "    - This Policy provides ReadOnly access to all resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${group_users}GroupPolicy.json"
cat $policiesdir/UsersGroupPolicy.json
echo "EOF"
echo
echo "euare-groupuploadpolicy -g $group_users -p ${group_users}Policy \\"
echo "                        -f $tmpdir/$account/${group_users}GroupPolicy.json"


if euare-grouplistpolicies -g $group_users | grep -s -q "${group_users}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${group_users}GroupPolicy.json"
        cat $policiesdir/UsersGroupPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/UsersGroupPolicy.json $tmpdir/$account/${group_users}GroupPolicy.json
        pause

        echo "# euare-groupuploadpolicy -g $group_users -p ${group_users}Policy \\"
        echo ">                         -f $tmpdir/$account/${group_users}GroupPolicy.json"
        euare-groupuploadpolicy -g $group_demos -p ${group_users}Policy \
                                -f $tmpdir/$account/${group_users}GroupPolicy.json

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Add Demo ($account) Account Users ($group_users) Group members"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupadduser -g $group_users -u $user_user"

if euare-grouplistusers -g $group_users | grep -s -q ":user/$user_user$"; then
    echo
    tput rev
    echo "Already Added!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupadduser -g $group_users -u $user_user"
        euare-groupadduser -g $group_users -u $user_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($group_demos) Role and associated InstanceProfile"
echo "    - This Role is intended for Demos which need Administrator access to Resources"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
cat $policiesdir/DemosRoleTrustPolicy.json
echo "EOF"
echo
echo "euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
echo
echo "euare-instanceprofilecreate -s instance_profile_demos"
echo
echo "euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos"

if euare-rolelistbypath | grep -s -q ":role/$role_demos$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF >> $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
        cat $policiesdir/DemosRoleTrustPolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosRoleTrustPolicy.json $tmpdir/$account/${role_demos}RoleTrustPolicy.json
        pause

        echo "# euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json"
        euare-rolecreate -r $role_demos -f $tmpdir/$account/${role_demos}RoleTrustPolicy.json
        pause

        echo "# euare-instanceprofilecreate -s instance_profile_demos"
        euare-instanceprofilecreate -s instance_profile_demos
        pause

        echo "# euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos"
        euare-instanceprofileaddrole -s $instance_profile_demos -r $role_demos

        next
    fi
fi

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Demos ($role_demos) Role Policy"
echo "    - This Policy provides full access to all resources, except users and groups"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> $tmpdir/$account/${role_demos}RolePolicy.json"
cat $policiesdir/DemosRolePolicy.json
echo "EOF"
echo
echo "euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \\"
echo "                       -f $tmpdir/$account/${role_demos}RolePolicy.json"


if euare-rolelistpolicies -r $role_demos | grep -s -q "${role_demos}Policy$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF > $tmpdir/$account/${role_demos}RolePolicy.json"
        cat $policiesdir/DemosRolePolicy.json | sed -e 's/^/> /'
        echo "> EOF"
        cp $policiesdir/DemosRolePolicy.json $tmpdir/$account/${role_demos}RolePolicy.json
        pause

        echo "# euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \\"
        echo ">                        -f $tmpdir/$account/${role_demos}RolePolicy.json"
        euare-roleuploadpolicy -r $role_demos -p ${role_demos}Policy \
                               -f $tmpdir/$account/${role_demos}RolePolicy.json

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
echo "euca-describe-keypairs"
echo
echo "euare-userlistbypath"
echo
echo "euare-grouplistbypath"
echo "euare-grouplistusers -g $group_demos"
echo "euare-grouplistusers -g $group_developers"
echo "euare-grouplistusers -g $group_users"
echo
echo "euare-rolelistbypath"
echo "euare-instanceprofilelistbypath"
echo "euare-instanceprofilelistforrole -r $role_demos"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euare-userlistbypath"
    euare-userlistbypath
    pause

    echo "# euare-grouplistbypath"
    euare-grouplistbypath
    echo "#"
    echo "# euare-grouplistusers -g $group_demos"
    euare-grouplistusers -g $group_demos
    echo "#"
    echo "# euare-grouplistusers -g $group_developers"
    euare-grouplistusers -g $group_developers
    echo "#"
    echo "# euare-grouplistusers -g $group_users"
    euare-grouplistusers -g $group_users
    pause

    echo "# euare-rolelistbypath"
    euare-rolelistbypath
    echo "#"
    echo "# euare-instanceprofilelistbypath"
    euare-instanceprofilelistbypath
    echo "#"
    echo "# euare-instanceprofilelistforrole -r $role_demos"
    euare-instanceprofilelistforrole -r $role_demos

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display Eucalyptus CLI Configuration"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/demo/iamrc"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/developer/iamrc"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/user/iamrc"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc"
    cat ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc
    pause

    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/demo/iamrc"
    cat ~/.creds/$AWS_DEFAULT_REGION/$account/demo/iamrc
    pause

    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/developer/iamrc"
    cat ~/.creds/$AWS_DEFAULT_REGION/$account/developer/iamrc
    pause

    echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/user/iamrc"
    cat ~/.creds/$AWS_DEFAULT_REGION/$account/user/iamrc

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
echo "cat ~/.euca/euca2ools.ini"
echo
echo "cat ~/.euca/euca2ools-ssl.ini"

run 50

if [ $choice = y ]; then
    echo
    echo "# cat ~/.euca/euca2ools.ini"
    cat ~/.euca/euca2ools.ini
    pause

    echo "# cat ~/.euca/euca2ools-ssl.ini"
    cat ~/.euca/euca2ools-ssl.ini

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
echo "Eucalyptus Demo Account Dependencies configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
