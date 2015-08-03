#/bin/bash
#
# This script initializes a Eucalyptus CloudFormation demo which uses the
# WordPress_Single_Instance_Eucalyptus.template to create WordPress-based
# blog. This demo then shows how this application can be migrated between
# AWS and Eucalyptus.
#
# This script was originally designed to run on a combined CLC+UFS+MC host,
# as installed by FastStart or the Cloud Administrator Course. To run this
# on an arbitrary management workstation, you will need to move the appropriate
# credentials to your management host.
#
# Before running this (or any other demo script in the euca-demo project),
# you should run the following scripts to initialize the demo environment
# to a baseline of known resources which are assumed to exist.
# - Run demo-00-initialize.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-01-initialize-account.sh on the CLC as the Eucalyptus Administrator.
# - Run demo-02-initialize-account-administrator.sh on the CLC as the Demo Account Administrator.
# - Run demo-03-initialize-account-dependencies.sh on the CLC as the Demo Account Administrator.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

federation=aws

image_name=CentOS-6-x86_64-CFN-AWSCLI

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

create_attempts=6
create_default=20
login_attempts=6
login_default=20
delete_attempts=6
delete_default=20

interactive=1
speed=100
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-demo}
aws_region=us-east-1
aws_account=euca
aws_user=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-r region ] [-a account] [-u user] [-A aws_account] [-U aws_user]"
    echo "  -I              non-interactive"
    echo "  -s              slower: increase pauses by 25%"
    echo "  -f              faster: reduce pauses by 25%"
    echo "  -r region       Region (default: $region)"
    echo "  -a account      Account (default: $account)"
    echo "  -u user         User (default: $user)"
    echo "  -A aws_account  Partner AWS Account (default: $aws_account)"
    echo "  -U aws_user     Partner AWS User (default: $aws_user)"
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

while getopts Isfr:a:u:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    u)  user="$OPTARG";;
    A)  aws_account="$OPTARG";;
    U)  aws_user="$OPTARG";;
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
        target="aws"
        aws_region=$region;;
      *)
        target="euca";;
    esac
fi

if [ -z $account ]; then
    echo "-a account missing!"
    echo "Could not automatically determine account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $user ]; then
    echo "-u user missing!"
    echo "Could not automatically determine user, and it was not specified as a parameter"
    exit 14
fi

if [ -z $aws_account ]; then
    echo "-A aws_account missing!"
    echo "Could not automatically determine AWS account, and it was not specified as a parameter"
    exit 16
fi

if [ -z $aws_user ]; then
    echo "-U aws_user missing!"
    echo "Could not automatically determine AWS user, and it was not specified as a parameter"
    exit 18
fi

if [ $target = euca ]; then
    profile=$region-$account-$user
    profile_region=$profile@$region

    if ! grep -s -q "\[user $profile]" ~/.euca/$region.ini; then
        echo "Could not find $region Demo ($account) Account Demo ($user) User Euca2ools user!"
        echo "Expected to find: [user $profile] in ~/.euca/$region.ini"
        exit 20
    fi
else
    profile=$federation-$account-$user
    profile_region=$profile@$region

    if ! grep -s -q "\[user $profile]" ~/.euca/$federation.ini; then
        echo "Could not find AWS ($account) Account Demo ($user) User Euca2ools user!"
        echo "Expected to find: [user $profile] in ~/.euca/$federation.ini"
        exit 20
    fi
fi

aws_profile=$aws_account-$aws_user

if ! grep -s -q "\[profile $aws_profile]" ~/.aws/config; then
    echo "Could not find AWS ($aws_account) Partner Account Demo ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $aws_profile] in ~/.aws/config"
    exit 29
fi


#  5. Initialize Demo

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
if [ $target = euca ]; then
    echo "$(printf '%2d' $step). Use Demo ($account) Account Demo ($user) User credentials"
else
    echo "$(printf '%2d' $step). Use AWS ($account) Account Demo ($user) User credentials"
fi
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
demo_initialized=y
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Confirm existence of Demo depencencies"
echo
echo "============================================================"
echo
echo "Commands:"
echo
if [ $target = euca ]; then
    echo "euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\""
    echo
fi
echo "euca-describe-keypairs --filter \"key-name=demo\""

next

echo
if [ $target = euca ]; then
    echo "# euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\""
    euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" | grep "$image_name" || demo_initialized=n
    pause
fi
echo "# euca-describe-keypairs --filter \"key-name=demo\""
euca-describe-keypairs --filter "key-name=demo" | grep "demo" || demo_initialized=n

if [ $demo_initialized = n ]; then
    echo
    echo "At least one prerequisite for this script was not met."
    echo "Please re-run the demo initialization scripts referencing this demo account:"
    echo "- demo-00-initialize.sh -r $region"
    echo "- demo-01-initialize-account.sh -r $region -a $account"
    echo "- demo-03-initialize-account-dependencies.sh -r $region -a $account"
    exit 99
fi

next


clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List initial Resources"
echo "    - So we can compare with what this demo creates"
echo
echo "============================================================"
echo
echo "Commands:"
echo 
echo "euca-describe-groups"
echo
echo "euca-describe-instances"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-groups"
    euca-describe-groups
    pause

    echo "# euca-describe-instances"
    euca-describe-instances
    
    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List initial CloudFormation Stacks"
echo "    - So we can compare with what this demo creates"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"

run 50

if [ $choice = y ]; then
    echo
    echo "# euform-describe-stacks"
    euform-describe-stacks

    next
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Upload original WordPress CloudFormation Template to AWS S3 Bucket"
echo "    - We will use an AWS ($aws_account) Account S3 Bucket (s3://demo-$aws_account)"
echo "      to hold modified versions of the WordPress CloudFormation Template"
echo "      which have Eucalyptus Region-specific EMIs added"
echo "    - If the original Template does not exist, upload it"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws s3 cp $templatesdir/WordPress_Single_Instance_Eucalyptus.template \\"
echo "          s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
echo "          --profile $aws_profile --region=$aws_region"

if aws s3 ls s3://demo-$aws_account/demo-30-cfn-wordpress/ --profile $aws_profile --region=$aws_region | grep -s -q " WordPress_Single_Instance_Eucalyptus.template$"; then
    echo
    tput rev
    echo "Already Uploaded!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws s3 cp $templatesdir/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           --profile $aws_profile --region=$aws_region"
        aws s3 cp $templatesdir/WordPress_Single_Instance_Eucalyptus.template \
                  s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
                  --profile $aws_profile --region=$aws_region

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download WordPress CloudFormation Template from AWS S3 Bucket"
echo "    - This Template may have been modified by other Eucalyptus Regions which use it."
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "aws s3 cp s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
echo "          $tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
echo "          --profile $aws_profile --region=$aws_region"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws s3 cp s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
    echo ">           $tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
    echo ">           --profile $aws_profile --region=$aws_region"
    aws s3 cp s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
              $tmpdir/WordPress_Single_Instance_Eucalyptus.template \
              --profile $aws_profile --region=$aws_region

    next
fi


if [ $target = euca ]; then
    ((++step))
    image_id=$(euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" | cut -f2)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Modify WordPress CloudFormation Template to add Region-specific EMI"
    echo "    - Like most CloudFormation Templates, the WordPress Template uses the \"AWSRegionArch2AMI\" Map"
    echo "      to lookup the AMI of the Image to use when creating new Instances, based on the Region"
    echo "      in which the Template is run. Similar to AWS, each Eucalyptus Region will also have a unqiue"
    echo "      EMI for the Image which must be used there. This step obtains the appropriate EMI"
    echo "      and adds a row for the Region to this Map."
    echo "    - Delete any prior row for this Region before adding a new row based on current EMI value"
    echo "    - Apologies for the gnarly sed syntax!"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "sed -i -e \"/\\\"$region\\\" *: { \\\"PV64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVM64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVMG2\\\" : \\\".*\\\" *},/d\" \\"
    echo "       /var/tmp/WordPress_Single_Instance_Eucalyptus.template"
    echo
    echo "sed -i -e \"/^    \\\"AWSRegionArch2AMI\\\" : {\$/a\\"
    echo "\\      \$(printf \"%-16s : { \\\"PV64\\\" : \\\"%s\\\", \\\"HVM64\\\" : \\\"%s\\\", \\\"HVMG2\\\" : \\\"NOT_SUPPORTED\\\" },\\n\" \"\\\"\"$region\"\\\"\" $image_id $image_id)\" \\"
    echo "       /var/tmp/WordPress_Single_Instance_Eucalyptus.template\""

    run 50

    if [ $choice = y ]; then
        echo "# sed -i -e \"/\\\"$region\\\" *: { \\\"PV64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVM64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVMG2\\\" : \\\".*\\\" *},/d\" \\"
        echo ">        /var/tmp/WordPress_Single_Instance_Eucalyptus.template"
        sed -i -e "/\"$region\" *: { \"PV64\" : \"emi-[0-9a-f]*\", \"HVM64\" : \"emi-[0-9a-f]*\", \"HVMG2\" : \".*\" *},/d" \
               /var/tmp/WordPress_Single_Instance_Eucalyptus.template
        pause

        echo "# sed -i -e \"/^    \\\"AWSRegionArch2AMI\\\" : {\$/a\\"
        echo "> \\      \$(printf \"%-16s : { \\\"PV64\\\" : \\\"%s\\\", \\\"HVM64\\\" : \\\"%s\\\", \\\"HVMG2\\\" : \\\"NOT_SUPPORTED\\\" },\\n\" \"\\\"\"$region\"\\\"\" $image_id $image_id)\" \\"
        echo ">        /var/tmp/WordPress_Single_Instance_Eucalyptus.template\""
        sed -i -e "/^    \"AWSRegionArch2AMI\" : {$/a\
        \      $(printf "%-16s : { \"PV64\" : \"%s\", \"HVM64\" : \"%s\", \"HVMG2\" : \"NOT_SUPPORTED\" },\n" "\""$region"\"" $image_id $image_id)" \
               /var/tmp/WordPress_Single_Instance_Eucalyptus.template

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Display modified WordPress CloudFormation template"
echo "    - The WordPress_Single_Instance_Eucalyptus.template creates a standalone WordPress"
echo "      installation on a single Instance"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "more $tmpdir/WordPress_Single_Instance_Eucalyptus.template"

run 50

if [ $choice = y ]; then
    echo
    echo "# more $tmpdir/WordPress_Single_Instance_Eucalyptus.template"
    if [ $interactive = 1 ]; then
        more $tmpdir/WordPress_Single_Instance_Eucalyptus.template
    else
        # This will iterate over the file in a manner similar to more, but non-interactive
        ((rows=$(tput lines)-2))
        lineno=0
        while IFS= read line; do
            echo "$line"
            if [ $((++lineno % rows)) = 0 ]; then
                tput rev; echo -n "--More--"; tput sgr0; echo -n " (Waiting 10 seconds...)"
                sleep 10
                echo -e -n "\r                                \r"
            fi
        done < $tmpdir/WordPress_Single_Instance_Eucalyptus.template
    fi

    next 200
fi


if [ $target = euca ]; then
    ((++step))
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Upload modified WordPress CloudFormation Template to AWS S3 Bucket"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws s3 cp $tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
    echo "          s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
    echo "          --profile $aws_profile --region=$aws_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws s3 cp $tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           --profile $aws_profile --region=$aws_region"
        aws s3 cp $tmpdir/WordPress_Single_Instance_Eucalyptus.template \
                  s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
                  --profile $aws_profile --region=$aws_region

        next
    fi
fi


end=$(date +%s)

echo
echo "Eucalyptus CloudFormation WordPress demo initialization complete (time: $(date -u -d @$((end-start)) +"%T"))"
