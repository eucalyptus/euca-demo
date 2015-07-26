#!/bin/bash
#
# This script initializes a Management Workstation and its associated Eucalyptus Region for Demos,
# including:
# - Initializes Euca2ools with the Region Endpoints
# - Initializes Euca2ools for the Eucalyptus Account Administrator
# - Initialize AWSCLI for the Eucalyptus Account Administrator
# - Imports the Demo Keypair into the Eucalyptus Account
# - Downloads a CentOS 6.6 Generic image
# - Installs the CentOS 6.6 Generic image
# - Downloads a CentOS 6.6 with cfn-init and awscli image
# - Installs the CentOS 6.6 with cfn-init and awscli image
#
# This script should be run by the Eucalyptus Administrator once after installation.
#
# Then the demo-01-initialize-account.sh script should be run by the Eucalyptus Administrator as
# many times as needed to create one or more Demo Accounts.
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

external_mirror=cloud.centos.org
internal_mirror=mirror.mjc.prc.eucalyptus-systems.com

generic_image=CentOS-6-x86_64-GenericCloud
external_generic_image_url=http://$external_mirror/centos/6.6/images/$generic_image.qcow2.xz
internal_generic_image_url=http://$internal_mirror/centos/6.6/images/$generic_image.qcow2.xz

cfn_awscli_image=Centos-6-x86_64-CFN-AWSCLI
external_cfn_awscli_image_url=https://s3.amazonaws.com/demo-eucalyptus/demo-30-cfn-wordpress/$cfn_awscli_image.raw.xz
internal_cfn_awscli_image_url=http://$internal_mirror/centos/6.6/images/$cfn_awscli_image.raw.xz

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
native=0
local=0
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e "s/export EC2_URL=http:\/\/compute\.$region\.\(.*\):8773\/$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-n] [-l] [-r region ] [ -d domain]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -n         use native service endpoints in euca2ools.ini"
    echo "  -l         use local mirror for Demo CentOS image"
    echo "  -r region  Eucalyptus Region (default: $region)"
    echo "  -d domain  Eucalyptus Domain (default: $domain)"
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

while getopts Isfnlr:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    n)  native=1;;
    l)  local=1;;
    r)  region="$OPTARG"
        [ -z $domain ] &&
        domain=$(sed -n -e "s/export EC2_URL=http:\/\/compute\.$region\.\(.*\):8773\/$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc 2>/dev/null);;
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
      us-east-1|us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $region invalid: This script can not be run against AWS regions"
        exit 11;;
    esac
fi

if [ -z $domain ]; then
    echo "-d domain missing!"
    echo "Could not automatically determine domain, and it was not specified as a parameter"
    exit 12
fi

profile=$region-admin
profile_region=$profile@$region

if [ ! -r ~/.creds/$region/eucalyptus/admin/iamrc ]; then
    echo "Could not find $region Eucalyptus Account Administrator IAM credentials!"
    echo "Expected to find: ~/.creds/$region/eucalyptus/admin/iamrc"
    exit 21
fi

if [ ! -r ~/.creds/$region/eucalyptus/admin/eucarc ]; then
    echo "Could not find $region Eucalyptus Account Administrator credentials!"
    echo "Expected to find: ~/.creds/$region/eucalyptus/admin/eucarc"
    exit 22
fi

if [ $local = 1 ]; then
    generic_image_url=$internal_generic_image_url
    cfn_awscli_image_url=$internal_cfn_awscli_image_url
else
    generic_image_url=$external_generic_image_url
    cfn_awscli_image_url=$external_cfn_awscli_image_url
fi
generic_image_file=${generic_image_url##*/}
cfn_awscli_image_file=${cfn_awscli_image_url##*/}

if ! curl -s --head $generic_image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "$generic_image_url invalid: attempts to reach this URL failed"
    exit 5
fi
 
if ! curl -s --head $cfn_awscli_image_url | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "$cfn_awscli_image_url invalid: attempts to reach this URL failed"
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
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "export AWS_DEFAULT_REGION=$profile_region"

next

echo
echo "export AWS_DEFAULT_REGION=$profile_region"
export AWS_DEFAULT_REGION=$profile_region

next


((++step))
# Construct Eucalyptus Endpoints (assumes AWS-style URLs)
if [ $native = 0 ]; then
    autoscaling_url=https://autoscaling.$region.$domain/services/AutoScaling
    cloudformation_url=https://cloudformation.$region.$domain/services/CloudFormation
    ec2_url=https://compute.$region.$domain/services/compute
    elasticloadbalancing_url=https://loadbalancing.$region.$domain/services/LoadBalancing
    iam_url=https://euare.$region.$domain/services/Euare
    monitoring_url=https://cloudwatch.$region.$domain/services/CloudWatch
    s3_url=https://objectstorage.$region.$domain/services/objectstorage
    sts_url=https://tokens.$region.$domain/services/Tokens
    swf_url=https://simpleworkflow.$region.$domain/services/SimpleWorkflow
else
    autoscaling_url=http://autoscaling.$region.$domain:8773/services/AutoScaling
    cloudformation_url=http://cloudformation.$region.$domain:8773/services/CloudFormation
    ec2_url=http://compute.$region.$domain:8773/services/compute
    elasticloadbalancing_url=http://loadbalancing.$region.$domain:8773/services/LoadBalancing
    iam_url=http://euare.$region.$domain:8773/services/Euare
    monitoring_url=http://cloudwatch.$region.$domain:8773/services/CloudWatch
    s3_url=http://objectstorage.$region.$domain:8773/services/objectstorage
    sts_url=http://tokens.$region.$domain:8773/services/Tokens
    swf_url=http://simpleworkflow.$region.$domain:8773/services/SimpleWorkflow
fi
# Or, alternatively, obtain all values we need from eucarc
#autoscaling_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#cloudformation_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#elasticloadbalancing_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#monitoring_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$region/eucalyptus/admin/eucarc)
#if [ $native = 0 ]; then
#    autoscaling_url=${autoscaling_url/http:/https:} && autoscaling_url=${autoscaling_url/:8773/}
#    cloudformation_url=${cloudformation_url/http:/https:} && cloudformation_url=${cloudformation_url/:8773/}
#    ec2_url=${ec2_url/http:/https:} && ec2_url=${ec2_url/:8773/}
#    elasticloadbalancing_url=${elasticloadbalancing_url/http:/https:} && elasticloadbalancing_url=${elasticloadbalancing_url/:8773/}
#    iam_url=${iam_url/http:/https:} && iam_url=${iam_url/:8773/}
#    monitoring_url=${monitoring_url/http:/https:} && monitoring_url=${monitoring_url/:8773/}
#    s3_url=${s3_url/http:/https:} && s3_url=${s3_url/:8773/}
#    sts_url=${sts_url/http:/https:} && sts_url=${sts_url/:8773/}
#    swf_url=${swf_url/http:/https:} && swf_url=${swf_url/:8773/}
#fi

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Initialize Euca2ools with Eucalyptus Region Endpoints"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ ! -r ~/.euca/global.ini ]; then
    echo "cat << EOF > ~/.euca/global.ini"
    echo "; Eucalyptus Global"
    echo
    echo "[global]"
    echo "region = $region"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF > /etc/euca2ools/conf.d/$region.ini"
echo "; Eucalyptus Region $region"
echo
echo "[region $region]"
echo "autoscaling-url = $autoscaling_url"
echo "cloudformation-url = $cloudformation_url"
echo "ec2-url = $ec2_url"
echo "elasticloadbalancing-url = $elasticloadbalancing_url"
echo "iam-url = $iam_url"
echo "monitoring-url $monitoring_url"
echo "s3-url = $s3_url"
echo "sts-url = $sts_url"
echo "swf-url = $swf_url"
echo "user = $region-admin"
echo
echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem"
echo "verify-ssl = false"
echo
echo "EOF"
echo
echo "cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
echo "chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"

if [ -r /etc/euca2ools/conf.d/$region.ini ]; then
    echo
    tput rev
    echo "Already Initialized!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        mkdir -p ~/.euca
        chmod 0700 ~/.euca
        echo
        if [ ! -r ~/.euca/global.ini ]; then
            echo "# cat << EOF > ~/.euca/global.ini"
            echo "> ; Eucalyptus Global"
            echo ">"
            echo "> [global]"
            echo "> region = $region"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "; Eucalyptus Global"  > ~/.euca/global.ini
            echo                       >> ~/.euca/global.ini
            echo "[global]"            >> ~/.euca/global.ini
            echo "region = $region"    >> ~/.euca/global.ini
            echo                       >> ~/.euca/global.ini
            pause
        fi
        echo "# cat << EOF > /etc/euca2ools/conf.d/$region.ini"
        echo "> ; Eucalyptus Region $region"
        echo ">"
        echo "> [region $region]"
        echo "> autoscaling-url = $autoscaling_url"
        echo "> cloudformation-url = $cloudformation_url"
        echo "> ec2-url = $ec2_url"
        echo "> elasticloadbalancing-url = $elasticloadbalancing_url"
        echo "> iam-url = $iam_url"
        echo "> monitoring-url $monitoring_url"
        echo "> s3-url = $s3_url"
        echo "> sts-url = $sts_url"
        echo "> swf-url = $swf_url"
        echo "> user = $region-admin"
        echo ">"
        echo "> certificate = /usr/share/euca2ools/certs/cert-$region.pem"
        echo "> verify-ssl = false"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Region $region"                               > /etc/euca2ools/conf.d/$region.ini
        echo                                                            >> /etc/euca2ools/conf.d/$region.ini
        echo "[region $region]"                                         >> /etc/euca2ools/conf.d/$region.ini
        echo "autoscaling-url = $autoscaling_url"                       >> /etc/euca2ools/conf.d/$region.ini
        echo "cloudformation-url = $cloudformation_url"                 >> /etc/euca2ools/conf.d/$region.ini
        echo "ec2-url = $ec2_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "elasticloadbalancing-url = $elasticloadbalancing_url"     >> /etc/euca2ools/conf.d/$region.ini
        echo "iam-url = $iam_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "monitoring-url $monitoring_url"                           >> /etc/euca2ools/conf.d/$region.ini
        echo "s3-url = $s3_url"                                         >> /etc/euca2ools/conf.d/$region.ini
        echo "sts-url = $sts_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "swf-url = $swf_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "user = admin"                                             >> /etc/euca2ools/conf.d/$region.ini
        echo                                                            >> /etc/euca2ools/conf.d/$region.ini
        echo "certificate = /usr/share/euca2ools/certs/cert-$region.pem">> /etc/euca2ools/conf.d/$region.ini
        echo "verify-ssl = false"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo                                                            >> /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem"
        cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$region.pem
        echo "# chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem"
        chmod 0644 /usr/share/euca2ools/certs/cert-$region.pem

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
account_id=$(sed -n -e "s/export EC2_ACCOUNT_NUMBER='\(.*\)'$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)
private_key=$HOME/.creds/$region/eucalyptus/admin/$(sed -n -e "s/export EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)
certificate=$HOME/.creds/$region/eucalyptus/admin/$(sed -n -e "s/export EC2_CERT=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Initialize Eucalyptus Administrator Euca2ools Profile"
echo "    - This allows the Eucalyptus Administrator to run API commands via Euca2ools"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "cat << EOF > ~/.euca/$region.ini"
echo "; Eucalyptus Region $region"
echo
echo "[user $region-admin]"
echo "account-id = $account_id"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo "private-key = $private_key"
echo "certificate = $certificate"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones verbose"
echo
echo "euca-describe-availability-zones verbose --region $region"
echo
echo "euca-describe-availability-zones verbose --region $region-admin@$region"

if [ -r ~/.euca/$region.ini ] && grep -s -q "$secret_key" ~/.euca/$region.ini; then
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
        echo "# cat << EOF > ~/.euca/$region.ini"
        echo "> ; Eucalyptus Region $region"
        echo ">"
        echo "> [user $region-admin]"
        echo "> account-id = $account_id"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo "> private-key = $private_key"
        echo "> certificate = $certificate"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Region $region"  > ~/.euca/$region.ini
        echo                               >> ~/.euca/$region.ini
        echo "[user $region-admin]"        >> ~/.euca/$region.ini
        echo "account-id = $account_id"    >> ~/.euca/$region.ini
        echo "key-id = $access_key"        >> ~/.euca/$region.ini
        echo "secret-key = $secret_key"    >> ~/.euca/$region.ini
        echo "private-key = $private_key"  >> ~/.euca/$region.ini
        echo "certificate = $certificate"  >> ~/.euca/$region.ini
        echo                               >> ~/.euca/$region.ini
        pause

        echo "# euca-describe-availability-zones verbose"
        euca-describe-availability-zones verbose
        pause

        echo "# euca-describe-availability-zones verbose --region $region"
        euca-describe-availability-zones verbose --region $region
        pause

        echo "# euca-describe-availability-zones verbose --region $region-admin@$region"
        euca-describe-availability-zones verbose --region $region-admin@$region

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/eucalyptus/admin/eucarc)

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create Eucalyptus Administrator AWSCLI Profile"
echo "    - This allows the Eucalyptus Administrator to run AWSCLI commands"
echo "    - This assumes the AWSCLI was previously installed and configured"
echo "      to support this region"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ ! -r ~/.aws/config ]; then
    echo "cat << EOF > ~/.aws/config"
    echo "#"
    echo "# AWS Config file"
    echo "#"
    echo
    echo "EOF"
    echo
fi
if ! grep -s -q "\[default]" ~/.aws/config; then
    echo "cat << EOF >> ~/.aws/config"
    echo "[default]"
    echo "region = $region"
    echo "output = text"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF >> ~/.aws/config"
echo "[profile $region-admin]"
echo "region = $region"
echo "output = text"
echo
echo "EOF"
echo
if [ ! -r ~/.aws/credentials ]; then
    echo "cat << EOF > ~/.aws/credentials"
    echo "#"
    echo "# AWS Credentials file"
    echo "#"
    echo
    echo "EOF"
    echo
fi
if ! grep -s -q "\[default]" ~/.aws/credentials; then
    echo "cat << EOF > ~/.aws/credentials"
    echo "[default]"
    echo "aws_access_key_id = $access_key"
    echo "aws_secret_access_key = $secret_key"
    echo
    echo "EOF"
    echo
fi
echo "cat << EOF > ~/.aws/credentials"
echo "[$region-admin]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=default"
echo
echo "aws ec2 describe-availability-zones --profile=$region-admin"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $region-admin]" ~/.aws/config; then
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
        if [ ! -r ~/.aws/config ]; then
            echo "# cat << EOF > ~/.aws/config"
            echo "> #"
            echo "> # AWS Config file"
            echo "> #"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "#"                  > ~/.aws/config
            echo "# AWS Config file" >> ~/.aws/config
            echo "#"                 >> ~/.aws/config
            echo                     >> ~/.aws/config
            echo "#"
        fi
        if ! grep -s -q "\[default]" ~/.aws/config; then
            echo "# cat << EOF >> ~/.aws/config"
            echo "> [default]"
            echo "> region = $region"
            echo "> output = text"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "[default]"               >> ~/.aws/config
            echo "region = $region"        >> ~/.aws/config
            echo "output = text"           >> ~/.aws/config
            echo                           >> ~/.aws/config
            echo "#"
        fi
        echo "# cat << EOF > ~/.aws/config"
        echo "> [profile $region-admin]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[profile $region-admin]" >> ~/.aws/config
        echo "region = $region"        >> ~/.aws/config
        echo "output = text"           >> ~/.aws/config
        echo                           >> ~/.aws/config
        pause

        if [ ! -r ~/.aws/credentials ]; then
            echo "# cat << EOF > ~/.aws/credentials"
            echo "> #"
            echo "> # AWS Credentials file"
            echo "> #"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "#"                       > ~/.aws/credentials
            echo "# AWS Credentials file" >> ~/.aws/credentials
            echo "#"                      >> ~/.aws/credentials
            echo                          >> ~/.aws/credentials
            echo "#"
        fi
        if ! grep -s -q "\[default]" ~/.aws/credentials; then
            echo "# cat << EOF > ~/.aws/credentials"
            echo "> [default]"
            echo "> aws_access_key_id = $access_key"
            echo "> aws_secret_access_key = $secret_key"
            echo ">"
            echo "> EOF"
            # Use echo instead of cat << EOF to better show indentation
            echo "[default]"                           >> ~/.aws/credentials
            echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
            echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
            echo                                       >> ~/.aws/credentials
            echo "#"
        fi
        echo "# cat << EOF > ~/.aws/credentials"
        echo "> [$region-admin]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "[$region-admin]"                     >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=default"
        aws ec2 describe-availability-zones--profile=default
        echo "#"
        echo "# aws ec2 describe-availability-zones --profile=$region-admin"
        aws ec2 describe-availability-zones--profile=$region-admin

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Import Eucalyptus Administrator Demo Keypair"
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
        echo "#"
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
echo "$(printf '%2d' $step). Download Demo Generic Image (CentOS 6.6)"
echo "    - Decompress and convert image to raw format"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "wget $generic_image_url -O $tmpdir/$generic_image_file"
echo
echo "xz -v -d $tmpdir/$generic_image_file"
echo
echo "qemu-img convert -f qcow2 -O raw $tmpdir/${generic_image_file%%.*}.qcow2 $tmpdir/${generic_image_file%%.*}.raw"

if [ -r $tmpdir/${generic_image_file%%.*}.raw ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# wget $generic_image_url -O $tmpdir/$generic_image_file"
        wget $generic_image_url -O $tmpdir/$generic_image_file
        pause

        echo "# xz -v -d $tmpdir/$generic_image_file"
        xz -v -d $tmpdir/$generic_image_file
        pause

        echo "# qemu-img convert -f qcow2 -O raw $tmpdir/${generic_image_file%%.*}.qcow2 $tmpdir/${generic_image_file%%.*}.raw"
        qemu-img convert -f qcow2 -O raw $tmpdir/${generic_image_file%%.*}.qcow2 $tmpdir/${generic_image_file%%.*}.raw

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install Demo Generic Image"
echo "    - NOTE: This can take a couple minutes..."
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${generic_image_file%%.*}.raw --virtualization-type hvm"

if euca-describe-images | grep -s -q "${generic_image_file%%.*}.raw.manifest.xml"; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${generic_image_file%%.*}.raw --virtualization-type hvm"
        euca-install-image -n centos66 -b images -r x86_64 -i $tmpdir/${generic_image_file%%.*}.raw --virtualization-type hvm

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo CFN + AWSCLI Image (CentOS 6.6)"
echo "    - Decompress to raw format"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "wget $cfn_awscli_image_url -O $tmpdir/$cfn_awscli_image_file"
echo
echo "xz -v -d $tmpdir/$cfn_awscli_image_file"

if [ -r $tmpdir/${cfn_awscli_image_file%%.*}.raw ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# wget $cfn_awscli_image_url -O $tmpdir/$cfn_awscli_image_file"
        wget $cfn_awscli_image_url -O $tmpdir/$cfn_awscli_image_file
        pause

        echo "# xz -v -d $tmpdir/$cfn_awscli_image_file"
        xz -v -d $tmpdir/$cfn_awscli_image_file

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Install Demo CFN + AWSCLI Image"
echo "    - NOTE: This can take a couple minutes..."
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca-install-image -n centos66-cfn-init -b images -r x86_64 -i $tmpdir/${cfn_awscli_image_file%%.*}.raw --virtualization-type hvm"

if euca-describe-images | grep -s -q "${cfn_awscli_image_file%%.*}.raw.manifest.xml"; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-install-image -n centos66-cfn-init -b images -r x86_64 -i $tmpdir/${cfn_awscli_image_file%%.*}.raw --virtualization-type hvm"
        euca-install-image -n centos66-cfn-init -b images -r x86_64 -i $tmpdir/${cfn_awscli_image_file%%.*}.raw --virtualization-type hvm

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
echo "$(printf '%2d' $step). Modify Instance Types"
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
echo "euca-describe-keypairs"
echo
echo "euca-describe-images"
echo
echo "euca-describe-instance-types"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-keypairs"
    euca-describe-keypairs
    pause

    echo "# euca-describe-images"
    euca-describe-images
    pause

    echo "# euca-describe-instance-types"
    euca-describe-instance-types

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
echo "Eucalyptus Account initialized for demos (time: $(date -u -d @$((end-start)) +"%T"))"
echo "Please run \"demo-01-initialize-account.sh\" to continue with demo initialization"
