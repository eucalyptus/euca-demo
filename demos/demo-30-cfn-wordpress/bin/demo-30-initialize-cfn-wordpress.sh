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
verbose=0
mode=e
euca_region=${AWS_DEFAULT_REGION#*@}
euca_account=${AWS_ACCOUNT_NAME:-demo}
euca_user=${AWS_USER_NAME:-admin}
aws_region=us-east-1
aws_account=euca
aws_user=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-m mode]"
    echo "                   [-r euca_region ] [-a euca_account] [-u euca_user]"
    echo "                   [-R aws_region] [-A aws_account] [-U aws_user]"
    echo "  -I               non-interactive"
    echo "  -s               slower: increase pauses by 25%"
    echo "  -f               faster: reduce pauses by 25%"
    echo "  -v               verbose"
    echo "  -m mode          mode: Initialize a=AWS, e=Eucalyptus or b=Both (default: $mode)"
    echo "  -r euca_region   Eucalyptus Region (default: $euca_region)"
    echo "  -a euca_account  Eucalyptus Account (default: $euca_account)"
    echo "  -u euca_user     Eucalyptus User (default: $euca_user)"
    echo "  -R aws_region    AWS Region (default: $aws_region)"
    echo "  -A aws_account   AWS Account (default: $aws_account)"
    echo "  -U aws_user      AWS User (default: $aws_user)"
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

while getopts Isfvm:r:a:u:R:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
    m)  mode="$OPTARG";;
    r)  euca_region="$OPTARG";;
    a)  euca_account="$OPTARG";;
    u)  euca_user="$OPTARG";;
    R)  aws_region="$OPTARG";;
    A)  aws_account="$OPTARG";;
    U)  aws_user="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ -z $mode ]; then
    echo "-m mode missing!"
    echo "Could not automatically determine mode, and it was not specified as a parameter"
    exit 8
else
    case $mode in
      a|e|b) ;;
      *)
        echo "-m $mode invalid: Valid modes are a=AWS (only), e=Eucalyptus (only), b=Both"
        exit 9;;
    esac
fi

if [ -z $euca_region ]; then
    echo "-r euca_region missing!"
    echo "Could not automatically determine Eucalyptus region, and it was not specified as a parameter"
    exit 10
else
    case $euca_region in
      us-east-1|us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        echo "-r $euca_region invalid: Please specify a Eucalyptus region"
        exit 11;;
    esac
fi

if [ -z $euca_account ]; then
    echo "-a euca_account missing!"
    echo "Could not automatically determine Eucalyptus account, and it was not specified as a parameter"
    exit 12
fi

if [ -z $euca_user ]; then
    echo "-u euca_user missing!"
    echo "Could not automatically determine Eucalyptus user, and it was not specified as a parameter"
    exit 14
fi

if [ -z $aws_region ]; then
    echo "-R aws_region missing!"
    echo "Could not automatically determine AWS region, and it was not specified as a parameter"
    exit 20
else
    case $aws_region in
      us-east-1)
        aws_s3_domain=s3.amazonaws.com;;
      us-west-1|us-west-2|sa-east-1|eu-west-1|eu-central-1|ap-northeast-1|ap-southeast-1|ap-southeast-2)
        aws_s3_domain=s3-$aws_region.amazonaws.com;;
    *)
        echo "-R $aws_region invalid: Please specify an AWS region"
        exit 21;;
    esac
fi

if [ -z $aws_account ]; then
    echo "-A aws_account missing!"
    echo "Could not automatically determine AWS account, and it was not specified as a parameter"
    exit 22
fi

if [ -z $aws_user ]; then
    echo "-U aws_user missing!"
    echo "Could not automatically determine AWS user, and it was not specified as a parameter"
    exit 24
fi

euca_user_region=$euca_region-$euca_account-$euca_user@$euca_region

if ! grep -s -q "\[user $euca_region-$euca_account-$euca_user]" ~/.euca/$euca_region.ini; then
    echo "Could not find Eucalyptus ($euca_region) Region Demo ($euca_account) Account Demo ($euca_user) User Euca2ools user!"
    echo "Expected to find: [user $euca_region-$euca_account-$euca_user] in ~/.euca/$euca_region.ini"
    exit 50
fi

euca_profile=$euca_region-$euca_account-$euca_user

if ! grep -s -q "\[profile $euca_profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($euca_region) Region Demo ($euca_account) Account Demo ($user) User AWSCLI profile!"
    echo "Expected to find: [profile $euca_profile] in ~/.aws/config"
    exit 51
fi

aws_user_region=$federation-$aws_account-$aws_user@$aws_region

if ! grep -s -q "\[user $federation-$aws_account-$aws_user]" ~/.euca/$federation.ini; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User Euca2ools user!"
    echo "Expected to find: [user $federation-$aws_account-$aws_user] in ~/.euca/$federation.ini"
    exit 52
fi

aws_profile=$aws_account-$aws_user

if ! grep -s -q "\[profile $aws_profile]" ~/.aws/config; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User AWSCLI profile!"
    echo "Expected to find: [profile $aws_profile] in ~/.aws/config"
    exit 53
fi

if [ ! $(uname) = "Darwin" ]; then
    if ! rpm -q --quiet w3m; then
        echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
        exit 98
    fi
fi


#  5. Initialize Demo

start=$(date +%s)

((++step))
if [ $mode = a -o $mode = b ]; then
    aws_demo_initialized=y

    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). Confirm existence of AWS Demo depencencies"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-keypairs --filter \"key-name=demo\" \\"
        echo "                       --region=$aws_user_region"

        next

        echo
        echo "# euca-describe-keypairs --filter \"key-name=demo\" \\"
        echo ">                        --region=$aws_user_region"
        euca-describe-keypairs --filter "key-name=demo" \
                               --region=$aws_user_region | grep "demo" || aws_demo_initialized=n

        next

    else
        euca-describe-keypairs --filter "key-name=demo" \
                               --region=$aws_user_region | grep -s -q "demo" || aws_demo_initialized=n
    fi

    if [ $aws_demo_initialized = n ]; then
        echo
        echo "At least one AWS prerequisite for this script was not met."
        echo "Please re-run the AWS demo initialization scripts referencing this AWS account:"
        echo "- demo-01-initialize-aws_account.sh -r $aws_region -a $aws_account"
        echo "- demo-03-initialize-aws_account-dependencies.sh -r $aws_region -a $aws_account"
        exit 99
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    euca_demo_initialized=y

    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). Confirm existence of Eucalyptus Demo depencencies"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
        echo "                     --region=$euca_user_region | cut -f1,2,3"
        echo
        echo "euca-describe-keypairs --filter \"key-name=demo\" \\"
        echo "                       --region=$euca_user_region"

        next

        echo
        echo "# euca-describe-images --filter \"manifest-location=images/$image_name.raw.manifest.xml\" \\"
        echo ">                      --region=$euca_user_region | cut -f1,2,3"
        euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                             --region=$euca_user_region | cut -f1,2,3 | grep "$image_name" || euca_demo_initialized=n
        pause

        echo "# euca-describe-keypairs --filter \"key-name=demo\"\\"
        echo ">                      --region=$euca_user_region"
        euca-describe-keypairs --filter "key-name=demo" \
                               --region=$euca_user_region | grep "demo" || euca_demo_initialized=n

        next

    else
        euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" \
                             --region=$euca_user_region | cut -f1,2,3 | grep -s -q "$image_name" || euca_demo_initialized=n
        euca-describe-keypairs --filter "key-name=demo" \
                               --region=$euca_user_region | grep -s -q "demo" || euca_demo_initialized=n
    fi

    if [ $euca_demo_initialized = n ]; then
        echo
        echo "At least one Eucalyptus prerequisite for this script was not met."
        echo "Please re-run the Eucalyptus demo initialization scripts referencing this demo account:"
        echo "- demo-00-initialize.sh -r $euca_region"
        echo "- demo-01-initialize-account.sh -r $euca_region -a $euca_account"
        echo "- demo-03-initialize-account-dependencies.sh -r $euca_region -a $euca_account"
        exit 99
    fi
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
echo "          --acl public-read --profile $aws_profile --region=$aws_region"

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
        echo ">           --acl public-read --profile $aws_profile --region=$aws_region"
        aws s3 cp $templatesdir/WordPress_Single_Instance_Eucalyptus.template \
                  s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
                  --acl public-read --profile $aws_profile --region=$aws_region

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


((++step))
if [ $mode = e -o $mode = b ]; then
    image_id=$(euca-describe-images --filter "manifest-location=images/$image_name.raw.manifest.xml" --region=$euca_user_region | cut -f2)

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
    echo "sed -i -e \"/\\\"$euca_region\\\" *: { \\\"PV64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVM64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVMG2\\\" : \\\".*\\\" *},/d\" \\"
    echo "       /var/tmp/WordPress_Single_Instance_Eucalyptus.template"
    echo
    echo "sed -i -e \"/^    \\\"AWSRegionArch2AMI\\\" : {\$/a\\"
    echo "\\      \$(printf \"%-16s : { \\\"PV64\\\" : \\\"%s\\\", \\\"HVM64\\\" : \\\"%s\\\", \\\"HVMG2\\\" : \\\"NOT_SUPPORTED\\\" },\\n\" \"\\\"\"$euca_region\"\\\"\" $image_id $image_id)\" \\"
    echo "       /var/tmp/WordPress_Single_Instance_Eucalyptus.template\""

    run 50

    if [ $choice = y ]; then
        echo "# sed -i -e \"/\\\"$euca_region\\\" *: { \\\"PV64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVM64\\\" : \\\"emi-[0-9a-f]*\\\", \\\"HVMG2\\\" : \\\".*\\\" *},/d\" \\"
        echo ">        /var/tmp/WordPress_Single_Instance_Eucalyptus.template"
        sed -i -e "/\"$euca_region\" *: { \"PV64\" : \"emi-[0-9a-f]*\", \"HVM64\" : \"emi-[0-9a-f]*\", \"HVMG2\" : \".*\" *},/d" \
               /var/tmp/WordPress_Single_Instance_Eucalyptus.template
        pause

        echo "# sed -i -e \"/^    \\\"AWSRegionArch2AMI\\\" : {\$/a\\"
        echo "> \\      \$(printf \"%-16s : { \\\"PV64\\\" : \\\"%s\\\", \\\"HVM64\\\" : \\\"%s\\\", \\\"HVMG2\\\" : \\\"NOT_SUPPORTED\\\" },\\n\" \"\\\"\"$euca_region\"\\\"\" $image_id $image_id)\" \\"
        echo ">        /var/tmp/WordPress_Single_Instance_Eucalyptus.template\""
        sed -i -e "/^    \"AWSRegionArch2AMI\" : {$/a\
        \      $(printf "%-16s : { \"PV64\" : \"%s\", \"HVM64\" : \"%s\", \"HVMG2\" : \"NOT_SUPPORTED\" },\n" "\""$euca_region"\"" $image_id $image_id)" \
               /var/tmp/WordPress_Single_Instance_Eucalyptus.template

        next
    fi
fi


((++step))
if [ $verbose = 1 ]; then
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
fi


if [ $mode = e -o $mode = b ]; then
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
    echo "          --acl public-read --profile $aws_profile --region=$aws_region"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws s3 cp $tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">           --acl public-read --profile $aws_profile --region=$aws_region"
        aws s3 cp $tmpdir/WordPress_Single_Instance_Eucalyptus.template \
                  s3://demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
                  --acl public-read --profile $aws_profile --region=$aws_region

        next
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List existing AWS Resources"
        echo "    - So we can compare with what this demo creates"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-groups --region=$aws_user_region"
        echo
        echo "euca-describe-instances --region=$aws_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euca-describe-groups --region=$aws_user_region"
            euca-describe-groups --region=$aws_user_region
            pause

            echo "# euca-describe-instances --region=$aws_user_region"
            euca-describe-instances --region=$aws_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List existing AWS CloudFormation Stacks"
        echo "    - So we can compare with what this demo creates"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euform-describe-stacks --region=$aws_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-describe-stacks --region=$aws_user_region"
            euform-describe-stacks --region=$aws_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List existing Eucalyptus Resources"
        echo "    - So we can compare with what this demo creates"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euca-describe-groups --region=$euca_user_region"
        echo
        echo "euca-describe-instances --region=$euca_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euca-describe-groups --region=$euca_user_region"
            euca-describe-groups --region=$euca_user_region
            pause

            echo "# euca-describe-instances --region=$euca_user_region"
            euca-describe-instances --region=$euca_user_region

            next
        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). List existing Eucalyptus CloudFormation Stacks"
        echo "    - So we can compare with what this demo creates"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "euform-describe-stacks --region=$euca_user_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# euform-describe-stacks --region=$euca_user_region"
            euform-describe-stacks --region=$euca_user_region

            next
        fi
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CloudFormation WordPress demo initialization complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CloudFormation WordPress demo initialization complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
