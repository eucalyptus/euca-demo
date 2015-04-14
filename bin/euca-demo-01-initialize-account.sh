#!/bin/bash
#
# This script initializes Eucalyptus with a Demo Account, including:
# - Within the Eucalyptus Account, creates a Demo Keypair
# - Creates a Demo Account (default name is "demo", but this can be overridden)
# - Creates the Demo Account Administrator Login Profile, allowing the use of the console
# - Downloads the Demo Account Administrator Credentials, allowing use of the API
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

external_image_url=http://cloud.centos.org/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz
internal_image_url=http://mirror.mjc.prc.eucalyptus-systems.com/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz

demo_admin_password=demo123

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
account=demo
[ "$EUCA_INSTALL_MODE" = "local" ] && local=1 || local=0


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-a account] [-l]"
    echo "  -I          non-interactive"
    echo "  -s          slower: increase pauses by 25%"
    echo "  -f          faster: reduce pauses by 25%"
    echo "  -a account  account to create for use in demos (default: $account)"
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

while getopts Isfa:l? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    a)  account="$OPTARG";;
    l)  local=1;;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ ! -r ~/creds/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Account Administrator credentials!"
    echo "Expected to find: ~/creds/eucalyptus/admin/eucarc"
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
echo "cat ~/creds/eucalyptus/admin/eucarc"
echo
echo "source ~/creds/eucalyptus/admin/eucarc"

next

echo
echo "# cat ~/creds/eucalyptus/admin/eucarc"
cat ~/creds/eucalyptus/admin/eucarc
pause

echo "# source ~/creds/eucalyptus/admin/eucarc"
source ~/creds/eucalyptus/admin/eucarc

next


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
echo "euca-create-keypair admin-demo | tee ~/creds/eucalyptus/admin/admin-demo.pem"
echo
echo "chmod 0600 ~/creds/eucalyptus/admin/admin-demo.pem"

if euca-describe-keypairs | grep -s -q "admin-demo" && [ -r ~/creds/eucalyptus/admin/admin-demo.pem ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    euca-delete-keypair admin-demo
    rm -f ~/creds/eucalyptus/admin/admin-demo.pem

    run 50

    if [ $choice = y ]; then
        echo
        echo "# euca-create-keypair admin-demo | tee ~/creds/eucalyptus/admin/admin-demo.pem"
        euca-create-keypair admin-demo | tee ~/creds/eucalyptus/admin/admin-demo.pem
        echo "#"
        echo "# chmod 0600 ~/creds/eucalyptus/admin/admin-demo.pem"
        chmod 0600 ~/creds/eucalyptus/admin/admin-demo.pem

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
echo "mkdir -p ~/creds/$account/admin"
echo
echo "rm -f ~/creds/$account/admin.zip"
echo
echo "sudo euca-get-credentials -u admin -a $account \\"
echo "                          ~/creds/$account/admin.zip"
echo
echo "unzip -uo ~/creds/$account/admin.zip \\"
echo "       -d ~/creds/$account/admin/"
echo
echo "cat ~/creds/$account/admin/eucarc"

if [ -r ~/creds/$account/admin/eucarc ]; then
    echo
    tput rev
    echo "Already Downloaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mkdir -p ~/creds/$account/admin"
        mkdir -p ~/creds/$account/admin
        pause

        echo "# rm -f ~/creds/$account/admin.zip"
        rm -f ~/creds/$account/admin.zip
        pause

        echo "# sudo euca-get-credentials -u admin -a $account \\"
        echo ">                           ~/creds/$account/admin.zip"
        sudo euca-get-credentials -u admin -a $account \
                                  ~/creds/$account/admin.zip
        pause

        echo "# unzip -uo ~/creds/$account/admin.zip \\"
        echo ">        -d ~/creds/$account/admin/"
        unzip -uo ~/creds/$account/admin.zip \
               -d ~/creds/$account/admin/
        if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/creds/$account/admin/eucarc; then
            # invisibly fix missing environment variables needed for image import
            pk_pem=$(ls -1 ~/creds/$account/admin/euca2-admin-*-pk.pem | tail -1)
            cert_pem=$(ls -1 ~/creds/$account/admin/euca2-admin-*-cert.pem | tail -1)
            sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/creds/$account/admin/eucarc
        fi
        pause

        echo "# cat ~/creds/$account/admin/eucarc"
        cat ~/creds/$account/admin/eucarc

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download Demo Image (CentOS 6.6)"
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
echo "      - to use 8 GB disk instead of the 5 GB default"
echo "    - We need to increase this to use the CentOS image"
echo
echo "============================================================"
echo 
echo "Commands:"
echo 
echo "euca-modify-instance-type -c 1 -d 8 -m 1024 m1.small"

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
        echo "# euca-modify-instance-type -c 1 -d 8 -m 1024 m1.small"
        euca-modify-instance-type -c 1 -d 8 -m 1024 m1.small

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
