#!/bin/bash
#
# This script initializes a Management Workstation and its associated Eucalyptus Region for Demos,
# including:
# - TBD: Confirm Euca2ools Region Configuration
# - TBD: Confirm Euca2ools User Configuration for the Eucalyptus Account Administrator
# - TBD: Confirm AWSCLI Region Configuration
# - TBD: Confirm AWSCLI User Configuration for the Eucalyptus Account Administrator
# - Creates the Demo Keypair
# - Imports the Demo Keypair
# - Creates the sample-templates Bucket
# - Downloads a CentOS 6 Generic image
# - Installs the CentOS 6 Generic image
# - Downloads a CentOS 6 with cfn-init and awscli image
# - Installs the CentOS 6 with cfn-init and awscli image
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
external_generic_image_url=http://$external_mirror/centos/6/images/$generic_image.qcow2.xz
internal_generic_image_url=http://$internal_mirror/centos/6/images/$generic_image.qcow2.xz

cfn_awscli_image=CentOS-6-x86_64-CFN-AWSCLI
external_cfn_awscli_image_url=http://images-euca.s3-website-us-east-1.amazonaws.com/$cfn_awscli_image.raw.xz
internal_cfn_awscli_image_url=http://$internal_mirror/centos/6/images/$cfn_awscli_image.raw.xz

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
verbose=0
native=0
local=0
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-n] [-l]"
    echo "             [-r region] [-d domain]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -v         verbose"
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

while getopts Isfvnlr:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    n)  native=1;;
    l)  local=1;;
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
echo "$(printf '%2d' $step). Configure Demo Keypair"
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

if [ -r ~/.ssh/demo_id_rsa -a -r ~/.ssh/demo_id_rsa.pub ]; then
    echo
    tput rev
    echo "Already Congigured!"
    tput sgr0

    next 50

else
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
echo "euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \\"
echo "                    --region $user_region \\"
echo "                    demo"

if euca-describe-keypairs --region $user_region | cut -f2 | grep -s -q "^demo$"; then
    echo
    tput rev
    echo "Already Imported!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \\"
        echo ">                     --region $user_region \\"
        echo ">                     demo"
        euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \
                            --region $user_region \
                            demo

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create sample-templates Bucket"
echo "    - This Bucket is intended for Sample CloudFormation Templates"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws s3api create-bucket --bucket sample-templates --acl public-read \\"
echo "                        --profile $profile --region$region --output text"

# work around pipe bug
if aws s3 ls --profile $profile --region $region --output text 2> /dev/null | grep -s -q " sample-templates$"; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws s3api create-bucket --bucket sample-templates --acl public-read \\"
        echo ">                         --profile $profile --region $region --output text"
        aws s3api create-bucket --bucket sample-templates --acl public-read \
                                --profile $profile --region $region --output text

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Generic Image (CentOS 6)"
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
echo "euca-install-image --name centos6 \\"
echo "                   --description \"Centos 6 Generic Cloud Image\" \\"
echo "                   --bucket images \\"
echo "                   --arch x86_64 \\"
echo "                   --image $tmpdir/${generic_image_file%%.*}.raw \\"
echo "                   --virtualization-type hvm \\"
echo "                   --region $user_region"

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
        echo "# euca-install-image --name centos6 \\"
        echo ">                    --description \"Centos 6 Generic Cloud Image\" \\"
        echo ">                    --bucket images \\"
        echo ">                    --arch x86_64 \\"
        echo ">                    --image $tmpdir/${generic_image_file%%.*}.raw \\"
        echo ">                    --virtualization-type hvm \\"
        echo ">                    --region $user_region"
        euca-install-image --name centos6 \
                           --description "Centos 6 Generic Cloud Image" \
                           --bucket images \
                           --arch x86_64 \
                           --image $tmpdir/${generic_image_file%%.*}.raw \
                           --virtualization-type hvm \
                           --region $user_region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo CFN + AWSCLI Image (CentOS 6)"
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
echo "euca-install-image --name centos6-cfn-init \\"
echo "                   --description \"Centos 6 Cloud Image with CloudFormation and AWSCLI\" \\"
echo "                   --bucket images \\"
echo "                   --arch x86_64 \\"
echo "                   --image $tmpdir/${cfn_awscli_image_file%%.*}.raw \\"
echo "                   --virtualization-type hvm \\"
echo "                   --region $user_region"

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
        echo "# euca-install-image --name centos6-cfn-init \\"
        echo ">                    --description \"Centos 6 Cloud Image with CloudFormation and AWSCLI\" \\"
        echo ">                    --bucket images \\"
        echo ">                    --arch x86_64 \\"
        echo ">                    --image $tmpdir/${cfn_awscli_image_file%%.*}.raw \\"
        echo ">                    --virtualization-type hvm \\"
        echo ">                    --region $user_region"
        euca-install-image --name centos6-cfn-init \
                           --description "Centos 6 Cloud Image with CloudFormation and AWSCLI" \
                           --bucket images \
                           --arch x86_64 \
                           --image $tmpdir/${cfn_awscli_image_file%%.*}.raw \
                           --virtualization-type hvm \
                           --region $user_region

        next
    fi
fi


((++step))
result=$(euca-describe-instance-types --region $user_region | grep "m1.small" | tr -s '[:blank:]' ':' | cut -d: -f3,4,5)
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
echo "      - to use 8 GB disk instead of the 5 GB default"
echo "    - We need to increase this to use the CentOS image"
echo
echo "============================================================"
echo 
echo "Commands:"
echo 
echo "euca-modify-instance-type --cpus 1 --memory 1024 --disk 8 \\"
echo "                          --region $user_region \\"
echo "                          m1.small"

if [ "$memory" = 1024 -a "$disk" = 8 ]; then
    echo
    tput rev
    echo "Already Modified!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-modify-instance-type --cpus 1 --memory 1024 --disk 8 \\"
        echo ">                           --region $user_region \\"
        echo ">                           m1.small"
        euca-modify-instance-type --cpus 1 --memory 1024 --disk 8 \
                                  --region $user_region \
                                  m1.small

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
    echo "euca-describe-keypairs --region $user_region"
    echo
    echo "euca-describe-images --region $user_region"
    echo
    echo "euca-describe-instance-types --region $user_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-describe-keypairs --region $user_region"
        euca-describe-keypairs --region $user_region
        pause

        echo "# euca-describe-images --region $user_region"
        euca-describe-images --region $user_region
        pause

        echo "# euca-describe-instance-types --region $user_region"
        euca-describe-instance-types --region $user_region

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
    echo "Eucalyptus Account initialized for demos (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus Account initialized for demos (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
echo "Please run \"demo-01-initialize-account.sh\" to continue with demo initialization"
