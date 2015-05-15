#!/bin/bash
#
# This script initializes Eucalyptus with a Demo Account, including:
# - Configures Euca2ools for the Eucalyptus Account Administrator, allowing use of the API via euca2ools
# - Creates the Eucalyptus Account Administrator Demo Keypair, allowing ssh login to instances
# - Creates a Demo Account (default name is "demo", but this can be overridden)
# - Creates the Demo Account Administrator Login Profile, allowing the use of the console
# - Downloads the Demo Account Administrator Credentials, allowing use of the API
# - Configures Euca2ools for the Demo Account Administrator, allowing use of the API via euca2ools
# - Downloads a CentOS 6.6 image
# - Installs the CentOS 6.6 image
# - Authorizes use of the CentOS 6.6 image by the Demo Account
#
# This script should be run by the Eucalyptus Administrator, then the
# euca-demo-02-initialize_dependencies.sh script should be run by the
# Demo Account Administrator to create additional objects in the account.
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

external_mirror=cloud.centos.org
internal_mirror=mirror.mjc.prc.eucalyptus-systems.com

external_image_url=http://$external_mirror/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz
internal_image_url=http://$internal_mirror/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz


step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo
demo_admin_password=${account}123
[ "$EUCA_INSTALL_MODE" = "local" ] && local=1 || local=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account] [-p password] [-l]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
    echo "  -p password password for demo account administrator (default: $demo_admin_password)"
    echo "  -l          Use local mirror for Demo CentOS image"
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

while getopts Isfa:p:l? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
    p)  demo_admin_password="$OPTARG";;
    l)  local=1;;
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

if [ $local = 1 ]; then
    image_url=$internal_image_url
else
    image_url=$external_image_url
fi
image_file=${image_url##*/}

if ! curl -s --head $image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "$image_url invalid: attempts to reach this URL failed"
    exit 5
fi
 
if ! rpm -q --quiet qemu-img-rhev; then
    echo "qemu-img missing: This script uses the qemu-img utility to convert images from qcow2 to raw format"
    exit 97
fi


#  5. Prepare Eucalyptus for Demos

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Use Eucalyptus Administrator credentials"
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
# Obtain all values we need from eucarc
ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
eucalyptus_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
eucalyptus_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

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
echo "$(printf '%2d' $step). Create Eucalyptus Administrator Tools Profile"
echo "    - This allows the Eucalyptus Administrator to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
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
echo "echo \"[user admin]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $eucalyptus_admin_access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $eucalyptus_admin_secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"
echo
echo "more ~/.euca/euca2ools.ini"
echo
echo "euca-describe-availability-zones verbose --region admin@$region"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$eucalyptus_admin_secret_key" ~/.euca/euca2ools.ini; then
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

        echo "# echo \"[user admin]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $eucalyptus_admin_access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $eucalyptus_admin_secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user admin]" >> ~/.euca/euca2ools.ini
        echo "key-id = $eucalyptus_admin_access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $eucalyptus_admin_secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        pause

        echo "# more ~/.euca/euca2ools.ini"
        more ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones verbose --region admin@$region"
        euca-describe-availability-zones verbose --region admin@$region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Eucalyptus Administrator Demo Keypair"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem"
echo
echo "chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem"

if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    euca-delete-keypair admin-demo &> /dev/null
    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem
        echo "#"
        echo "# chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem"
        chmod 0600 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem

        next
    fi
fi


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
ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
demo_admin_access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)
demo_admin_secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/$account/admin/eucarc)

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
echo "$(printf '%2d' $step). Create Demo ($account) Account Administrator Tools Profile"
echo "    - This allows the Demo Account Administrator to run API commands via Euca2ools"
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
echo "echo \"[user $account-admin]\" >> ~/.euca/euca2ools.ini"
echo "echo \"key-id = $eucalyptus_admin_access_key\" >> ~/.euca/euca2ools.ini"
echo "echo \"secret-key = $eucalyptus_admin_secret_key\" >> ~/.euca/euca2ools.ini"
echo "echo >> ~/.euca/euca2ools.ini"
echo
echo "more ~/.euca/euca2ools.ini"
echo
echo "euca-describe-availability-zones verbose --region $account-admin@$region"

if [ -r ~/.euca/euca2ools.ini ] && grep -s -q "$demo_admin_secret_key" ~/.euca/euca2ools.ini; then
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

        echo "# echo \"[user $account-admin]\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"key-id = $demo_admin_access_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo \"secret-key = $demo_admin_secret_key\" >> ~/.euca/euca2ools.ini"
        echo "# echo >> ~/.euca/euca2ools.ini"
        echo "[user $account-admin]" >> ~/.euca/euca2ools.ini
        echo "key-id = $demo_admin_access_key" >> ~/.euca/euca2ools.ini
        echo "secret-key = $demo_admin_secret_key" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        pause

        echo "# more ~/.euca/euca2ools.ini"
        more ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones verbose --region $account-admin@$region"
        euca-describe-availability-zones verbose --region $account-admin@$region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Image (CentOS 6.6)"
echo "    - Decompress and convert image to raw format"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "wget $image_url -O $tmpdir/$image_file"
echo
echo "xz -v -d $tmpdir/$image_file"
echo
echo "qemu-img convert -f qcow2 -O raw $tmpdir/${image_file%%.*}.qcow2 $tmpdir/${image_file%%.*}.raw"

if [ -r $tmpdir/${image_file%%.*}.raw ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# wget $image_url -O $tmpdir/$image_file"
        wget $image_url -O $tmpdir/$image_file
        pause

        echo "# xz -v -d $tmpdir/$image_file"
        xz -v -d $tmpdir/$image_file
        pause

        echo "# qemu-img convert -f qcow2 -O raw $tmpdir/${image_file%%.*}.qcow2 $tmpdir/${image_file%%.*}.raw"
        qemu-img convert -f qcow2 -O raw $tmpdir/${image_file%%.*}.qcow2 $tmpdir/${image_file%%.*}.raw

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install Demo Image"
echo "    - NOTE: This can take a couple minutes..."
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${image_file%%.*}.raw --virtualization-type hvm"

if euca-describe-images | grep -s -q "${image_file%%.*}.raw.manifest.xml"; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${image_file%%.*}.raw --virtualization-type hvm"
        euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${image_file%%.*}.raw --virtualization-type hvm

        next
    fi
fi


((++step))
account_id=$(euare-accountlist | grep "^$account" | cut -f2)
image_id=$(euca-describe-images | grep ${image_file%%.*}.raw.manifest.xml | cut -f2)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Authorize Demo ($account) Account use of Demo Image"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-modify-image-attribute -l -a $account_id $image_id"

if euca-describe-images -x $account_id | grep -s -q $image_id; then
    echo
    tput rev
    echo "Already Authorized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-image-attribute -l -a $account_id $image_id"
        euca-modify-image-attribute -l -a $account_id $image_id

        next
    fi
fi


((++step))
result=$(euca-describe-instance-types | grep "m1.small" | tr -s '[:blank:]' ':' | cut -d: -f3,4,5)
cpu=${result%%:*}
temp=${result%:*} && memory=${temp#*:}
disk=${result##*:}

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Modify an Instance Type"
echo "    - Change the m1.small instance type:"
echo "      - to use 1 GB memory instead of the 256 MB default"
echo "      - to use 10 GB disk instead of the 5 GB default"
echo "    - We need to increase this to use the CentOS image"
echo
echo "============================================================"
echo 
echo "Commands:"
echo 
echo "euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small"

if [ "$memory" = 1024 -a "$disk" = 10 ]; then
    echo
    tput rev
    echo "Already Modified!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small"
        euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small

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
echo "euca-describe-instance-types"

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

    echo "# euca-describe-instance-types"
    euca-describe-instance-types

    next 200
fi


end=$(date +%s)

echo
echo "Eucalyptus Account configured for demo scripts (time: $(date -u -d @$((end-start)) +"%T"))"
unset a; [ $account = demo ] || a=" -a $account"
echo "Please run \"euca-demo-02-initialize-dependencies.sh$a\" to complete demo initialization"
