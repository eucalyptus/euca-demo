#!/bin/bash
#
# This script initializes a Demo Account within Eucalyptus with dependencies used in demos, including:
# - Confirms the Demo Image is available to the Demo Account
# - Creates a Demo Keypair for the Demo Account Administrator
# - Creates a Demo User (named "user"), intended for user-level, mostly read-only, operations
# - Creates the Demo User Login Profile, allowing the use of the console
# - Downloads the Demo User Credentials, allowing use of the API
# - Configures Euca2ools for the Demo User, allowing use of the API via euca2ools
# - Creates a Demo Users Group (named "users"), and makes the Demo User a member
# - Creates a Demo Developer (named "developer"), intended for developer-level, mostly read-write, operations
# - Creates the Demo Developer Login Profile, allowing the use of the console
# - Downloads the Demo Developer Credentials, allowing use of the API
# - Configures Euca2ools for the Demo Developer, allowing use of the API via euca2ools
# - Creates a Demo Developers Group (named "developers"), and makes the Demo Developer a member
#
# The euca-demo-01-initialize-account.sh script should be run by the Eucalyptus Administrator
# prior to running this script.
#
# Both scripts are pre-requisites of running any demos!
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

demo_user=user
demo_user_password=${demo_user}123
demo_users=users

demo_developer=developer
demo_developer_password=${demo_developer}123
demo_developers=developers

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
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

while getopts Isfa:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
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


#  5. Prepare Eucalyptus Demo Account for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Demo ($account) Account Administrator credentials"
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
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem"
echo
echo "chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem"

if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    euca-delete-keypair admin-demo &> /dev/null
    rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem
        echo "#"
        echo "# chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem"
        chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/$account/admin/admin-demo.pem

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user)"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $demo_user"

if euare-userlistbypath | grep -s -q ":user/$demo_user$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_user"
        euare-usercreate -u $demo_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user) Login Profile"
echo "    - This allows the Demo Account User to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $demo_user -p $demo_user_password"

if euare-usergetloginprofile -u $demo_user &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_user -p $demo_user_password"
        euare-useraddloginprofile -u $demo_user -p $demo_user_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo ($account) Account User ($demo_user) Credentials"
echo "    - This allows the Demo Account User to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user"
echo
echo "rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip"
echo
echo "sudo euca-get-credentials -u $demo_user -a $account \\"
echo "                          ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip"
echo
echo "unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip \\"
echo "       -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user
        pause

        echo "# rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip"
        rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip
        pause

        echo "# sudo euca-get-credentials -u $demo_user -a $account \\"
        echo ">                           ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip"
        sudo euca-get-credentials -u $demo_user -a $account \
                                  ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip
        pause

        echo "# unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip \\"
        echo ">        -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/"
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user.zip \
               -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc
        fi
        pause

        echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc"
        cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc

        next
    fi
fi



((++step))
# Obtain all values we need from eucarc
ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
demo_user_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)
demo_user_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_user/eucarc)

# This is an AWS convention I've been using in my own URLs, but which may not work for others
# Obtain the AWS region name from the second-to-the-right domain name component of the URL:
# - if not an IP address, and
# - if consistent with AWS region syntax ("*-*-*")
# otherwise use "eucalyptus"
region=$(echo $ec2_url | sed -n -r -e "s/^.*\/\/compute\.([^-.]*-[^-.]*-[^-.]*)\..*$/\1/p")
if [ -z $region ]; then
    region=eucalyptus
fi

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account User ($demo_user) Tools Profile"
echo "    - This allows the Demo Account User to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools.ini; then
    echo "echo \"# Euca2ools Configuration file\" > ~/.euca/euca2ools.ini"
    echo "echo >> ~/.euca/euca2ools.ini"
    echo "echo \"[region $region]\" >> ~/.euca/euca2ools.ini"
    echo "echo \"autoscaling-url = $as_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"cloudformation-url = $cfn_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"ec2-url = $ec2_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"elasticloadbalancing-url = $elb_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"iam-url = $iam_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"monitoring-url $cw_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"s3-url = $s3_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"sts-url = $sts_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"swf-url = $swf_url\" >> ~/.euca/euca2ools.ini"
    echo "echo >> ~/.euca/euca2ools.ini"
    echo
fi
echo "echo \"[user $account-$demo_user]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $demo_user_access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $demo_user_secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"
echo
echo "more ~/.euca/euca2ools.ini"
echo
echo "euca-describe-availability-zones verbose --region $account-$demo_user@$region"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$demo_user_secret_key" ~/.euca/euca2ools.ini; then
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

        if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools.ini; then
            echo "# echo \"# Euca2ools Configuration file\" > ~/.euca/euca2ools.ini"
            echo "# echo >> ~/.euca/euca2ools.ini"
            echo "# echo \"[region $region]\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"autoscaling-url = $as_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"cloudformation-url = $cfn_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"ec2-url = $ec2_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"elasticloadbalancing-url = $elb_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"iam-url = $iam_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"monitoring-url $cw_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"s3-url = $s3_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"sts-url = $sts_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"swf-url = $swf_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo >> ~/.euca/euca2ools.ini"
            echo "# Euca2ools Configuration file" > ~/.euca/euca2ools.ini
            echo >> ~/.euca/euca2ools.ini
            echo "[region $region]" >> ~/.euca/euca2ools.ini
            echo "autoscaling-url = $as_url" >> ~/.euca/euca2ools.ini
            echo "cloudformation-url = $cfn_url" >> ~/.euca/euca2ools.ini
            echo "ec2-url = $ec2_url" >> ~/.euca/euca2ools.ini
            echo "elasticloadbalancing-url = $elb_url" >> ~/.euca/euca2ools.ini
            echo "iam-url = $iam_url" >> ~/.euca/euca2ools.ini
            echo "monitoring-url $cw_url" >> ~/.euca/euca2ools.ini
            echo "s3-url = $s3_url" >> ~/.euca/euca2ools.ini
            echo "sts-url = $sts_url" >> ~/.euca/euca2ools.ini
            echo "swf-url = $swf_url" >> ~/.euca/euca2ools.ini
            echo >> ~/.euca/euca2ools.ini
            pause
        fi

        echo "# echo \"[user $account-$demo_user]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $demo_user_access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $demo_user_secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-$demo_user]" >> ~/.euca/euca2ools.ini
        echo "key-id = $demo_user_access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $demo_user_secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        pause

        echo "# more ~/.euca/euca2ools.ini"
        more ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $account-$demo_user@$region"
        euca-describe-availability-zones verbose --region $account-$demo_user@$region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Users ($demo_users) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $demo_users"
echo
echo "euare-groupadduser -g $demo_users -u $demo_user"

if euare-grouplistbypath | grep -s -q ":group/$demo_users$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_users"
        euare-groupcreate -g $demo_users
        echo "#"
        echo "# euare-groupadduser -g $demo_users -u $demo_user"
        euare-groupadduser -g $demo_users -u $demo_user

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer)"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-usercreate -u $demo_developer"

if euare-userlistbypath | grep -s -q ":user/$demo_developer$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-usercreate -u $demo_developer"
        euare-usercreate -u $demo_developer

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer) Login Profile"
echo "    - This allows the Demo Account Developer to login to the console"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"

if euare-usergetloginprofile -u $demo_developer &> /dev/null; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-useraddloginprofile -u $demo_developer -p $demo_developer_password"
        euare-useraddloginprofile -u $demo_developer -p $demo_developer_password

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo ($account) Account Developer ($demo_developer) Credentials"
echo "    - This allows the Demo Account Developer to run API commands"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer"
echo
echo "rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip"
echo
echo "sudo euca-get-credentials -u $demo_developer -a $account \\"
echo "                          ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip"
echo
echo "unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip \\"
echo "       -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/"
echo
echo "cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc"

if [ -r ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer
        pause

        echo "# rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip"
        rm -f ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip
        pause

        echo "# sudo euca-get-credentials -u $demo_developer -a $account \\"
        echo ">                           ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip"
        sudo euca-get-credentials -u $demo_developer -a $account \
                                  ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip
        pause

        echo "# unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip \\"
        echo ">        -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/"
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer.zip \
               -d ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc
        fi
        pause

        echo "# cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc"
        cat ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
demo_developer_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)
demo_developer_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/$demo_developer/eucarc)

# This is an AWS convention I've been using in my own URLs, but which may not work for others
# Obtain the AWS region name from the second-to-the-right domain name component of the URL:
# - if not an IP address, and
# - if consistent with AWS region syntax ("*-*-*")
# otherwise use "eucalyptus"
region=$(echo $ec2_url | sed -n -r -e "s/^.*\/\/compute\.([^-.]*-[^-.]*-[^-.]*)\..*$/\1/p")
if [ -z $region ]; then
    region=eucalyptus
fi

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developer ($demo_developer) Tools Profile"
echo "    - This allows the Demo Account Developer to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools.ini; then
    echo "echo \"# Euca2ools Configuration file\" > ~/.euca/euca2ools.ini"
    echo "echo >> ~/.euca/euca2ools.ini"
    echo "echo \"[region $region]\" >> ~/.euca/euca2ools.ini"
    echo "echo \"autoscaling-url = $as_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"cloudformation-url = $cfn_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"ec2-url = $ec2_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"elasticloadbalancing-url = $elb_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"iam-url = $iam_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"monitoring-url $cw_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"s3-url = $s3_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"sts-url = $sts_url\" >> ~/.euca/euca2ools.ini"
    echo "echo \"swf-url = $swf_url\" >> ~/.euca/euca2ools.ini"
    echo "echo >> ~/.euca/euca2ools.ini"
    echo
fi
echo "echo \"[user $account-$demo_developer]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $demo_developer_access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $demo_developer_secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"
echo
echo "more ~/.euca/euca2ools.ini"
echo
echo "euca-describe-availability-zones verbose --region $account-$demo_developer@$region"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$demo_developer_secret_key" ~/.euca/euca2ools.ini; then
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

        if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools.ini; then
            echo "# echo \"# Euca2ools Configuration file\" > ~/.euca/euca2ools.ini"
            echo "# echo >> ~/.euca/euca2ools.ini"
            echo "# echo \"[region $region]\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"autoscaling-url = $as_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"cloudformation-url = $cfn_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"ec2-url = $ec2_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"elasticloadbalancing-url = $elb_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"iam-url = $iam_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"monitoring-url $cw_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"s3-url = $s3_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"sts-url = $sts_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo \"swf-url = $swf_url\" >> ~/.euca/euca2ools.ini"
            echo "# echo >> ~/.euca/euca2ools.ini"
            echo "# Euca2ools Configuration file" > ~/.euca/euca2ools.ini
            echo >> ~/.euca/euca2ools.ini
            echo "[region $region]" >> ~/.euca/euca2ools.ini
            echo "autoscaling-url = $as_url" >> ~/.euca/euca2ools.ini
            echo "cloudformation-url = $cfn_url" >> ~/.euca/euca2ools.ini
            echo "ec2-url = $ec2_url" >> ~/.euca/euca2ools.ini
            echo "elasticloadbalancing-url = $elb_url" >> ~/.euca/euca2ools.ini
            echo "iam-url = $iam_url" >> ~/.euca/euca2ools.ini
            echo "monitoring-url $cw_url" >> ~/.euca/euca2ools.ini
            echo "s3-url = $s3_url" >> ~/.euca/euca2ools.ini
            echo "sts-url = $sts_url" >> ~/.euca/euca2ools.ini
            echo "swf-url = $swf_url" >> ~/.euca/euca2ools.ini
            echo >> ~/.euca/euca2ools.ini
            pause
        fi

        echo "# echo \"[user $account-$demo_developer]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $demo_developer_access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $demo_developer_secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-$demo_developer]" >> ~/.euca/euca2ools.ini
        echo "key-id = $demo_developer_access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $demo_developer_secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        pause

        echo "# more ~/.euca/euca2ools.ini"
        more ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $account-$demo_developer@$region"
        euca-describe-availability-zones verbose --region $account-$demo_developer@$region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Demo ($account) Account Developers ($demo_developers) Group"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euare-groupcreate -g $demo_developers"
echo
echo "euare-groupadduser -g $demo_developers -u $demo_developer"

if euare-grouplistbypath | grep -s -q ":group/$demo_developers$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euare-groupcreate -g $demo_developers"
        euare-groupcreate -g $demo_developers
        echo "#"
        echo "# euare-groupadduser -g $demo_developers -u $demo_developer"
        euare-groupadduser -g $demo_developers -u $demo_developer

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
echo "euare-accountlist"
echo
echo "euare-userlistbypath"
echo
echo "euare-grouplistbypath"
echo "euare-grouplistusers -g $demo_users"
echo "euare-grouplistusers -g $demo_developers"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euare-accountlist"
    euare-accountlist
    pause

    echo "# euare-userlistbypath"
    euare-userlistbypath
    pause

    echo "# euare-grouplistbypath"
    euare-grouplistbypath
    echo "#"
    echo "# euare-grouplistusers -g $demo_users"
    euare-grouplistusers -g $demo_users
    echo "#"
    echo "# euare-grouplistusers -g $demo_developers"
    euare-grouplistusers -g $demo_developers

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Demo Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
