#!/bin/bash
#
# This script initializes Eucalyptus for Demos, including:
# - Initialize Euca2ools for the Eucalyptus Account Administrator, allowing use of the API via euca2ools
# - Initialize AWSCLI for the Eucalyptus Account Administrator, allowing use of the AWSCLI
# - Imports the Demo Keypair into the Eucalyptus Account
# - Downloads a CentOS 6.6 Generic image
# - Installs the CentOS 6.6 Generic image
# - Downloads a CentOS 6.6 with cfn-init and awscli image
# - Installs the CentOS 6.6 with cfn-init and awscli image
#
# This script should be run by the Eucalyptus Administrator once after installation.
# Then the demo-01-initialize-account.sh script should be run by the Eucalyptus Administrator as
# many times as needed to create one or more demo accounts.
# Then, for each demo account, the demo-02-initialize-account-dependencies.sh script should be run
# by the Demo Account Administrator to create additional groups, users roles and instance profiles
# in the account.
#
# All three initialization scripts are pre-requisites of running any demos!
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
direct=0
local=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-d] [-l]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
    echo "  -d  use direct service endpoints in euca2ools.ini"
    echo "  -l  use local mirror for Demo CentOS image"
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

while getopts Isfdl? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    d)  direct=1;;
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
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

ec2_ssl_url=${ec2_url/http:/https:} && ec2_ssl_url=${ec2_ssl_url/:8773/}
s3_ssl_url=${s3_url/http:/https:} && s3_ssl_url=${s3_ssl_url/:8773/}
iam_ssl_url=${iam_url/http:/https:} && iam_ssl_url=${iam_ssl_url/:8773/}
sts_ssl_url=${sts_url/http:/https:} && sts_ssl_url=${sts_ssl_url/:8773/}
as_ssl_url=${as_url/http:/https:} && as_ssl_url=${as_ssl_url/:8773/}
cfn_ssl_url=${cfn_url/http:/https:} && cfn_ssl_url=${cfn_ssl_url/:8773/}
cw_ssl_url=${cw_url/http:/https:} && cw_ssl_url=${cw_ssl_url/:8773/}
elb_ssl_url=${elb_url/http:/https:} && elb_ssl_url=${elb_ssl_url/:8773/}
swf_ssl_url=${swf_url/http:/https:} && swf_ssl_url=${swf_ssl_url/:8773/}

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
echo "cat << EOF > ~/.euca/euca2ools.ini"
echo "# Euca2ools Configuration file"
echo
echo "[global]"
echo "region = $AWS_DEFAULT_REGION"
echo
echo "[region $AWS_DEFAULT_REGION]"
if [ $direct = 1 ]; then
    echo "autoscaling-url = $as_url"
    echo "cloudformation-url = $cfn_url"
    echo "ec2-url = $ec2_url"
    echo "elasticloadbalancing-url = $elb_url"
    echo "iam-url = $iam_url"
    echo "monitoring-url $cw_url"
    echo "s3-url = $s3_url"
    echo "sts-url = $sts_url"
    echo "swf-url = $swf_url"
else
    echo "[region $AWS_DEFAULT_REGION]"
    echo "autoscaling-url = $as_ssl_url"
    echo "cloudformation-url = $cfn_ssl_url"
    echo "ec2-url = $ec2_ssl_url"
    echo "elasticloadbalancing-url = $elb_ssl_url"
    echo "iam-url = $iam_ssl_url"
    echo "monitoring-url $cw_ssl_url"
    echo "s3-url = $s3_ssl_url"
    echo "sts-url = $sts_ssl_url"
    echo "swf-url = $swf_ssl_url"
fi
echo "user = admin"
echo
echo "[user admin]"
echo "key-id = $access_key"
echo "secret-key = $secret_key"
echo
echo "EOF"
echo
echo "euca-describe-availability-zones verbose
echo
echo "euca-describe-availability-zones verbose --region admin@$AWS_DEFAULT_REGION"

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
        echo "# cat << EOF > ~/.euca/euca2ools.ini"
        echo "> # Euca2ools Configuration file"
        echo ">"
        echo "> [global]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo ">"
        echo "> [region $AWS_DEFAULT_REGION]"
        if [ $direct = 1 ]; then
            echo "> autoscaling-url = $as_url"
            echo "> cloudformation-url = $cfn_url"
            echo "> ec2-url = $ec2_url"
            echo "> elasticloadbalancing-url = $elb_url"
            echo "> iam-url = $iam_url"
            echo "> monitoring-url $cw_url"
            echo "> s3-url = $s3_url"
            echo "> sts-url = $sts_url"
            echo "> swf-url = $swf_url"
            echo "> user = admin"
        else
            echo "> autoscaling-url = $as_ssl_url"
            echo "> cloudformation-url = $cfn_ssl_url"
            echo "> ec2-url = $ec2_ssl_url"
            echo "> elasticloadbalancing-url = $elb_ssl_url"
            echo "> iam-url = $iam_ssl_url"
            echo "> monitoring-url $cw_ssl_url"
            echo "> s3-url = $s3_ssl_url"
            echo "> sts-url = $sts_ssl_url"
            echo "> swf-url = $swf_ssl_url"
        fi
        echo "> user = admin"
        echo ">"
        echo "> [user admin]"
        echo "> key-id = $access_key"
        echo "> secret-key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "# Euca2ools Configuration file"               > ~/.euca/euca2ools.ini
        echo                                               >> ~/.euca/euca2ools.ini
        echo "[global]"                                    >> ~/.euca/euca2ools.ini
        echo "region = $AWS_DEFAULT_REGION"                >> ~/.euca/euca2ools.ini
        echo                                               >> ~/.euca/euca2ools.ini
        echo "[region $AWS_DEFAULT_REGION]"                >> ~/.euca/euca2ools.ini
        if [ $direct = 1 ]; then
            echo "autoscaling-url = $as_url"               >> ~/.euca/euca2ools.ini
            echo "cloudformation-url = $cfn_url"           >> ~/.euca/euca2ools.ini
            echo "ec2-url = $ec2_url"                      >> ~/.euca/euca2ools.ini
            echo "elasticloadbalancing-url = $elb_url"     >> ~/.euca/euca2ools.ini
            echo "iam-url = $iam_url"                      >> ~/.euca/euca2ools.ini
            echo "monitoring-url $cw_url"                  >> ~/.euca/euca2ools.ini
            echo "s3-url = $s3_url"                        >> ~/.euca/euca2ools.ini
            echo "sts-url = $sts_url"                      >> ~/.euca/euca2ools.ini
            echo "swf-url = $swf_url"                      >> ~/.euca/euca2ools.ini
        else
            echo "autoscaling-url = $as_ssl_url"           >> ~/.euca/euca2ools.ini
            echo "cloudformation-url = $cfn_ssl_url"       >> ~/.euca/euca2ools.ini
            echo "ec2-url = $ec2_ssl_url"                  >> ~/.euca/euca2ools.ini
            echo "elasticloadbalancing-url = $elb_ssl_url" >> ~/.euca/euca2ools.ini
            echo "iam-url = $iam_ssl_url"                  >> ~/.euca/euca2ools.ini
            echo "monitoring-url $cw_ssl_url"              >> ~/.euca/euca2ools.ini
            echo "s3-url = $s3_ssl_url"                    >> ~/.euca/euca2ools.ini
            echo "sts-url = $sts_ssl_url"                  >> ~/.euca/euca2ools.ini
            echo "swf-url = $swf_ssl_url"                  >> ~/.euca/euca2ools.ini
        fi
        echo "user = admin"                                >> ~/.euca/euca2ools.ini
        echo                                               >> ~/.euca/euca2ools.ini
        echo "[user admin]"                                >> ~/.euca/euca2ools.ini
        echo "key-id = $access_key"                        >> ~/.euca/euca2ools.ini
        echo "secret-key = $secret_key"                    >> ~/.euca/euca2ools.ini
        echo                                               >> ~/.euca/euca2ools.ini
        pause

        echo "# euca-describe-availability-zones verbose"
        euca-describe-availability-zones verbose
        echo "#"
        echo "# euca-describe-availability-zones verbose --region admin@$AWS_DEFAULT_REGION"
        euca-describe-availability-zones verbose --region admin@$AWS_DEFAULT_REGION

        next
    fi
fi


((++step))
# Obtain all values we need from eucarc
access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

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
echo "cat << EOF > ~/.aws/config"
echo "#"
echo "# AWS Config file"
echo "#"
echo
echo "[default]"
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "[profile $AWS_DEFAULT_REGION-admin]"
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "EOF"
echo
echo "cat << EOF > ~/.aws/credentials"
echo "#"
echo "# AWS Credentials file"
echo "#"
echo
echo "[default]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "[$AWS_DEFAULT_REGION-admin]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "aws ec2 describe-availability-zones --profile=default"
echo
echo "aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-admin"

if [ -r ~/.aws/config ] && grep -s -q "\[profile $AWS_DEFAULT_REGION-admin]" ~/.aws/config; then
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
        echo "# cat << EOF > ~/.aws/config"
        echo "> #"
        echo "> # AWS Config file"
        echo "> #"
        echo ">"
        echo "> [default]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo "> output = text"
        echo ">"
        echo "> [profile $AWS_DEFAULT_REGION-admin]"
        echo "> region = $AWS_DEFAULT_REGION"
        echo "> output = text"
        echo ">"
        echo "EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                                    > ~/.aws/config
        echo "# AWS Config file"                   >> ~/.aws/config
        echo "#"                                   >> ~/.aws/config
        echo                                       >> ~/.aws/config
        echo "[default]"                           >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION"        >> ~/.aws/config
        echo "output = text"                       >> ~/.aws/config
        echo                                       >> ~/.aws/config
        echo "[profile $AWS_DEFAULT_REGION-admin]" >> ~/.aws/config
        echo "region = $AWS_DEFAULT_REGION"        >> ~/.aws/config
        echo "output = text"                       >> ~/.aws/config
        echo                                       >> ~/.aws/config
        pause

        echo "# cat << EOF > ~/.aws/credentials"
        echo "> #"
        echo "> # AWS Credentials file"
        echo "> #"
        echo ">"
        echo "> [default]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> [$AWS_DEFAULT_REGION-admin]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                                    > ~/.aws/credentials
        echo "# AWS Credentials file"              >> ~/.aws/credentials
        echo "#"                                   >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        echo "[default]"                           >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        echo "[$AWS_DEFAULT_REGION-admin]"         >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# aws ec2 describe-availability-zones --profile=default"
        aws ec2 describe-availability-zones--profile=default
        echo "#"
        echo "# aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-admin"
        aws ec2 describe-availability-zones--profile=$AWS_DEFAULT_REGION-admin

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
echo "cat ~/.euca/euca2ools.ini"
 
run 50
 
if [ $choice = y ]; then
    echo
    echo "# cat ~/.euca/euca2ools.ini"
    cat ~/.euca/euca2ools.ini
 
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
echo "Please run \"demo-01-initialize-account.sh$a\" to continue with demo initialization"
