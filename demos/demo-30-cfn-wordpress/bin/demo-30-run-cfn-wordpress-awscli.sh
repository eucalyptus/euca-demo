#/bin/bash
#
# This script runs a Eucalyptus CloudFormation demo which uses the
# WordPress_Single_Instance_Eucalyptus.template to create WordPress-based
# blog. This demo then shows how this application can be migrated between
# AWS and Eucalyptus.
#
# This is a variant of the demo-30-run-cfn-wordpress.sh script which primarily uses the AWSCLI.
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
# This script assumes many conventions created by the installation DNS and demo initialization
# scripts.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

federation=aws

image_name=CentOS-6-x86_64-CFN-AWSCLI

mysql_root=root
mysql_user=demo
mysql_password=password
mysql_db=wordpressdb
mysql_bakfile=$mysql_db.bak

wordpress_admin_user=demo
wordpress_admin_password=JohannesGutenberg-1455
wordpress_admin_email=mcrawford@hp.com

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

euca_stack_created=n
aws_stack_created=n

create_attempts=30
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
euca_ssh_user=root
aws_region=us-east-1
aws_account=euca
aws_user=demo
aws_ssh_user=ec2-user


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v] [-m mode]"
    echo "                   [-r euca_region ] [-a euca_account] [-u euca_user]"
    echo "                   [-R aws_region] [-A aws_account] [-U aws_user]"
    echo "  -I               non-interactive"
    echo "  -s               slower: increase pauses by 25%"
    echo "  -f               faster: reduce pauses by 25%"
    echo "  -v               verbose"
    echo "  -m mode          mode: Run a=AWS, e=Eucalyptus, b=Both or m=Migrate (default: $mode)"
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
      a|e|b|m) ;;
      *)
        echo "-m $mode invalid: Valid modes are a=AWS (only), e=Eucalyptus (only), b=Both, m=Migrate (only)"
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

euca_profile=$euca_region-$euca_account-$euca_user

if ! grep -s -q "\[profile $euca_profile]" ~/.aws/config; then
    echo "Could not find Eucalyptus ($euca_region) Region Demo ($euca_account) Account Demo ($euca_user) User AWSCLI profile!"
    echo "Expected to find: [profile $euca_profile] in ~/.aws/config"
    exit 51
fi

aws_profile=$aws_account-$aws_user

if ! grep -s -q "\[profile $aws_profile]" ~/.aws/config; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User AWSCLI profile!"
    echo "Expected to find: [profile $aws_profile] in ~/.aws/config"
    exit 53
fi

euca_cloudformation_url=$(sed -n -e "s/cloudformation-url = \(.*\)\/services\/CloudFormation\/$/\1/p" /etc/euca2ools/conf.d/$euca_region.ini)
aws_cloudformation_url=https://cloudformation.$aws_region.amazonaws.com

if [ -z $euca_cloudformation_url ]; then
    echo "Could not automatically determine Eucalyptus CloudFormation URL"
    echo "For Eucalyptus Regions, we attempt to lookup the value of "cloudformation-url" in /etc/euca2ools/conf.d/$euca_region.ini"
    echo 60
fi

if ! which lynx > /dev/null; then
    echo "lynx missing: This demo uses the lynx text-mode browser to confirm webpage content"
    case $(uname) in
      Darwin)
        echo "- Lynx for OSX can be found here: http://habilis.net/lynxlet/"
        echo "- Follow instructions to install and create /usr/bin/lynx symlink";;
      *)
        echo "- yum install -y lynx";;
    esac

    exit 98
fi

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Run Demo

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
        echo "aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\" \\"
        echo "                           --profile $aws_profile --region $aws_region"

        next 50

        echo
        echo "# aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\"\\"
        echo ">                            --profile $aws_profile --region $aws_region"
        aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                                   --profile $aws_profile --region $aws_region | grep "demo" || aws_demo_initialized=n

        next

    else
        aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                                   --profile $aws_profile --region $aws_region | grep -s -q "demo" || aws_demo_initialized=n
    fi

    if [ $aws_demo_initialized = n ]; then
        echo
        echo "At least one AWS prerequisite for this script was not met."
        echo "Please re-run the AWS demo initialization scripts referencing this AWS account:"
        echo "- demo-01-initialize-aws-account.sh -r $aws_region -a $aws_account"
        echo "- demo-03-initialize-aws-account-dependencies-awscli.sh -r $aws_region -a $aws_account"
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
        echo "aws ec2 describe-images --filter \"Name=manifest-location,Values=images/$image_name.raw.manifest.xml\" \\"
        echo "                        --profile $euca_profile --region $euca_region | cut -f1,4,5"
        echo
        echo "aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\" \\"
        echo "                           --profile $euca_profile --region $euca_region"

        next 50

        echo
        echo "# aws ec2 describe-images --filter \"Name=manifest-location,Values=images/$image_name.raw.manifest.xml\" \\"
        echo ">                         --profile $euca_profile --region $euca_region | cut -f1,4,5"
        aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                                --profile $euca_profile --region $euca_region | cut -d$'\t' -f1,4,5  | grep "$image_name" || euca_demo_initialized=n
        pause

        echo "# aws ec2 describe-key-pairs --filter \"Name=key-name,Values=demo\" \\"
        echo ">                            --profile $euca_profile --region $euca_region"
        aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                                   --profile $euca_profile --region $euca_region | grep "demo" || euca_demo_initialized=n

        next
    else
        aws ec2 describe-images --filter "Name=manifest-location,Values=images/$image_name.raw.manifest.xml" \
                                --profile $euca_profile --region $euca_region | cut -d$'\t' -f1,4,5  | grep -s -q "$image_name" || euca_demo_initialized=n
        aws ec2 describe-key-pairs --filter "Name=key-name,Values=demo" \
                                   --profile $euca_profile --region $euca_region | grep -s -q "demo" || euca_demo_initialized=n
    fi

    if [ $euca_demo_initialized = n ]; then
        echo
        echo "At least one Eucalyptus prerequisite for this script was not met."
        echo "Please re-run the Eucalyptus demo initialization scripts referencing this demo account:"
        echo "- demo-00-initialize.sh -r $euca_region"
        echo "- demo-01-initialize-account.sh -r $euca_region -a $euca_account"
        echo "- demo-03-initialize-account-dependencies-awscli.sh -r $euca_region -a $euca_account"
        exit 99
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Download WordPress CloudFormation Template from AWS S3 Bucket"
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
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Display WordPress CloudFormation template"
    echo "    - Like most CloudFormation Templates, the WordPress Template uses the \"AWSRegionArch2AMI\" Map"
    echo "      to lookup the AMI ID of the Image to use when creating new Instances, based on the Region"
    echo "      in which the Template is run. Similar to AWS, each Eucalyptus Region will also have a unqiue"
    echo "      EMI ID for the Image which must be used there."
    echo "    - This Template has been modified to add a row containing the Eucalyptus Region EMI ID to this"
    echo "      Map. It is otherwise identical to what is run in AWS."
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
        echo "aws ec2 describe-security-groups --profile $aws_profile --region $aws_region"
        echo
        echo "aws ec2 describe-instances --profile $aws_profile --region $aws_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws ec2 describe-security-groups --profile $aws_profile --region $aws_region"
            aws ec2 describe-security-groups --profile $aws_profile --region $aws_region
            pause

            echo "# aws ec2 describe-instances --profile $aws_profile --region $aws_region"
            aws ec2 describe-instances --profile $aws_profile --region $aws_region

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
        echo "aws cloudformation describe-stacks --profile $aws_profile --region $aws_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation describe-stacks --profile $aws_profile --region $aws_region"
            aws cloudformation describe-stacks --profile $aws_profile --region $aws_region

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create the AWS Stack"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws cloudformation create-stack --stack-name WordPressDemoStack \\"
    echo "                                --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
    echo "                                --parameters ParameterKey=KeyName,ParameterValue=$aws_ssh_key \\"
    echo "                                             ParameterKey=InstanceType,ParameterValue=m1.medium \\"
    echo "                                             ParameterKey=DBUser,ParameterValue=$mysql_user \\"
    echo "                                             ParameterKey=DBPassword,ParameterValue=$mysql_password \\"
    echo "                                             ParameterKey=DBRootPassword,ParameterValue=$mysql_password \\"
    echo "                                             ParameterKey=EndPoint,ParameterValue=$aws_cloudformation_url \\"
    echo "                                --capabilities CAPABILITY_IAM \\"
    echo "                                --profile $aws_profile --region $aws_region"

    if [ "$(aws cloudformation describe-stacks --stack-name WordPressDemoStack --profile $aws_profile --region $aws_region 2> /dev/null | grep "^STACKS" | cut -f7)" = "CREATE_COMPLETE" ]; then
        echo
        tput rev
        echo "Already Created!"
        tput sgr0

        next 50

    else
        run

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation create-stack --stack-name WordPressDemoStack \\"
            echo ">                                 --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
            echo ">                                 --parameters ParameterKey=KeyName,ParameterValue=$aws_ssh_key \\"
            echo ">                                              ParameterKey=InstanceType,ParameterValue=m1.medium \\"
            echo ">                                              ParameterKey=DBUser,ParameterValue=$mysql_user \\"
            echo ">                                              ParameterKey=DBPassword,ParameterValue=$mysql_password \\"
            echo ">                                              ParameterKey=DBRootPassword,ParameterValue=$mysql_password \\"
            echo ">                                              ParameterKey=EndPoint,ParameterValue=$aws_cloudformation_url \\"
            echo ">                                 --capabilities CAPABILITY_IAM \\"
            echo ">                                 --profile $aws_profile --region $aws_region"
            aws cloudformation create-stack --stack-name=WordPressDemoStack \
                                            --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \
                                            --parameters ParameterKey=KeyName,ParameterValue=$aws_ssh_key \
                                                         ParameterKey=InstanceType,ParameterValue=m1.medium \
                                                         ParameterKey=DBUser,ParameterValue=$mysql_user \
                                                         ParameterKey=DBPassword,ParameterValue=$mysql_password \
                                                         ParameterKey=DBRootPassword,ParameterValue=$mysql_password \
                                                         ParameterKey=EndPoint,ParameterValue=$aws_cloudformation_url \
                                            --capabilities CAPABILITY_IAM \
                                            --profile $aws_profile --region $aws_region

            aws_stack_created=y

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Monitor AWS Stack creation"
    echo "    - NOTE: This can take about 360 - 600 seconds"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws cloudformation describe-stacks --profile $aws_profile --region $aws_region"
    echo
    echo "aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \\"
    echo "                                         --profile $aws_profile --region $aws_region"

    if [ "$(aws cloudformation describe-stacks --stack-name WordPressDemoStack --profile $aws_profile --region $aws_region 2> /dev/null | grep "^STACKS" | cut -f7)" = "CREATE_COMPLETE" ]; then
        echo
        tput rev
        echo "Already Complete!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation describe-stacks --profile $aws_profile --region $aws_region"
            aws cloudformation describe-stacks --profile $aws_profile --region $aws_region
            pause

            attempt=0
            ((seconds=$create_default * $speed / 100))
            while ((attempt++ <= create_attempts)); do
                echo
                echo "# aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \\"
                echo ">                                          --profile $aws_profile --region $aws_region"
                aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \
                                                         --profile $aws_profile --region $aws_region

                status=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack --profile $aws_profile --region $aws_region 2> /dev/null | grep "^STACKS" | cut -f7)
                if [ -z "$status" -o "$status" = "CREATE_COMPLETE" -o "$status" = "CREATE_FAILED" -o "$status" = "ROLLBACK_COMPLETE" ]; then
                    break
                else
                    echo
                    echo -n "Not finished ($RC). Waiting $seconds seconds..."
                    sleep $seconds
                    echo " Done"
                fi
            done

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
        echo "$(printf '%2d' $step). List updated AWS Resources"
        echo "    - Note addition of new group and instance"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "aws ec2 describe-security-groups --profile $aws_profile --region $aws_region"
        echo
        echo "aws ec2 describe-instances --profile $aws_profile --region $aws_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws ec2 describe-security-groups --profile $aws_profile --region $aws_region"
            aws ec2 describe-security-groups --profile $aws_profile --region $aws_region
            pause

            echo "# aws ec2 describe-instances --profile $aws_profile --region $aws_region"
            aws ec2 describe-instances --profile $aws_profile --region $aws_region

            next
        fi
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Obtain AWS Instance and Blog details"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws_instance_id=\$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \\"
    echo "                                                               --profile=$aws_profile --region=$aws_region | cut -f4)"
    echo "aws_public_name=\$(aws ec2 describe-instances --instance-ids $aws_instance_id \\"
    echo "                                              --profile=$aws_profile --region=$aws_region | grep \"^INSTANCES\" | cut -f11)"
    echo "aws_public_ip=\$(aws ec2 describe-instances --instance-ids $aws_instance_id \\"
    echo "                                            --profile=$aws_profile --region=$aws_region | grep \"^INSTANCES\" | cut -f12)"
    echo
    echo "aws_wordpress_url=\$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \\"
    echo "                                                        --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \\"
    echo "                                                        --profile=$aws_profile --region=$aws_region 2> /dev/null)"

    next 50

    echo
    echo "# aws_instance_id=\$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \\"
    echo ">                                                                --profile=$aws_profile --region=$aws_region | cut -f4)"
    aws_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \
                                                                  --profile=$aws_profile --region=$aws_region | cut -f4)
    echo "$aws_instance_id"
    echo "#"
    echo "# aws_public_name=\$(aws ec2 describe-instances --instance-ids $aws_instance_id \\"
    echo ">                                               --profile=$aws_profile --region=$aws_region | grep \"^INSTANCES\" | cut -f11)"
    aws_public_name=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                                 --profile=$aws_profile --region=$aws_region | grep "^INSTANCES" | cut -f11)
    echo "$aws_public_name"
    echo "#"
    echo "# aws_public_ip=\$(aws ec2 describe-instances --instance-ids $aws_instance_id \\"
    echo ">                                             --profile=$aws_profile --region=$aws_region | grep \"^INSTANCES\" | cut -f12)"
    aws_public_ip=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                               --profile=$aws_profile --region=$aws_region | grep "^INSTANCES" | cut -f12)
    echo "$aws_public_ip"
    pause

    echo "# aws_wordpress_url=\$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \\"
    echo ">                                                         --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \\"
    echo ">                                                         --profile=$aws_profile --region=$aws_region 2> /dev/null)"
    aws_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                           --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                           --profile=$aws_profile --region=$aws_region 2> /dev/null)
    echo "$aws_wordpress_url"

    next
else
    aws_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \
                                                                  --profile=$aws_profile --region=$aws_region | cut -f4)
    aws_public_name=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                                 --profile=$aws_profile --region=$aws_region | grep "^INSTANCES" | cut -f11)
    aws_public_ip=$(aws ec2 describe-instances --instance-ids $aws_instance_id \
                                               --profile=$aws_profile --region=$aws_region | grep "^INSTANCES" | cut -f12)

    aws_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                           --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                           --profile=$aws_profile --region=$aws_region 2> /dev/null)
fi

sed -i -e "/$aws_public_name/d" ~/.ssh/known_hosts 2> /dev/null
sed -i -e "/$aws_public_ip/d" ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan $aws_public_name 2> /dev/null >> ~/.ssh/known_hosts
ssh-keyscan $aws_public_ip 2> /dev/null >> ~/.ssh/known_hosts


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Install WordPress Command-Line Tools on AWS Instance"
    echo "    - This is used to automate WordPress initialization and posting"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
    echo "    \"sudo curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp; sudo chmod +x /usr/local/bin/wp\""

    if ssh -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name "wp --info" 2> /dev/null | grep -s -q "WP-CLI version"; then
        echo
        tput rev
        echo "Already Installed!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            attempt=0
            ((seconds=$login_default * $speed / 100))
            while ((attempt++ <= login_attempts)); do
                echo
                echo "# ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
                echo ">     \"sudo curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp; sudo chmod +x /usr/local/bin/wp\""
                ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \
                    "sudo curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp; sudo chmod +x /usr/local/bin/wp"
                RC=$?
                if [ $RC = 0 -o $RC = 1 ]; then
                    break
                else
                    echo
                    echo -n "Not available ($RC). Waiting $seconds seconds..."
                    sleep $seconds
                    echo " Done"
                fi
            done

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Initialize WordPress on AWS Instance"
    echo "    - Initialize WordPress via wp command-line tool"
    echo "    - OR - skip this step, and..."
    echo "    - Initialize WordPress via a browser:"
    echo "      $aws_wordpress_url"
    echo "    - Using these values:"
    echo "      - Site Title: Demo ($aws_account)"
    echo "      - Username: $wordpress_admin_user"
    echo "      - Password: $wordpress_admin_password"
    echo "      - Your E-mail: $wordpress_admin_email"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
    echo "    \"sudo /usr/local/bin/wp core install --path=/var/www/html/wordpress --url=\\\"$aws_wordpress_url\\\" --title=\\\"Demo ($aws_account)\\\" --admin_user=\\\"$wordpress_admin_user\\\" --admin_password=\\\"$wordpress_admin_password\\\" --admin_email=\\\"$wordpress_admin_email\\\"\""

    if ssh -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name "wp core is-installed --path=/var/www/html/wordpress" 2> /dev/null; then
        echo
        tput rev
        echo "Already Initialized!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            attempt=0
            ((seconds=$login_default * $speed / 100))
            while ((attempt++ <= login_attempts)); do
                echo
                echo "# ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
                echo ">     \"sudo /usr/local/bin/wp core install --path=/var/www/html/wordpress --url=\\\"$aws_wordpress_url\\\" --title=\\\"Demo ($aws_account)\\\" --admin_user=\\\"$wordpress_admin_user\\\" --admin_password=\\\"$wordpress_admin_password\\\" --admin_email=\\\"$wordpress_admin_email\\\"\""
                ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \
                    "sudo /usr/local/bin/wp core install --path=/var/www/html/wordpress --url=\"$aws_wordpress_url\" --title=\"Demo ($aws_account)\" --admin_user=\"$wordpress_admin_user\" --admin_password=\"$wordpress_admin_password\" --admin_email=\"$wordpress_admin_email\""
                RC=$?
                if [ $RC = 0 -o $RC = 1 ]; then
                    break
                else
                    echo
                    echo -n "Not available ($RC). Waiting $seconds seconds..."
                    sleep $seconds
                    echo " Done"
                fi
            done

            next
        fi
    fi
fi


((++step))
if [ $mode = a -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create WordPress Blog Post on AWS Instance"
    echo "    - Create a WordPress Post via wp command-line tool"
    echo "    - OR - skip this step, and..."
    echo "    - Create a WordPress Post via a browser:"
    echo "      $aws_wordpress_url"
    echo "    - Login using these values:"
    echo "      - Username: $wordpress_admin_user"
    echo "      - Password: $wordpress_admin_password"
    echo "    - This is to show migration of current database content"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
    echo "    \"sudo /usr/local/bin/wp post create --path=/var/www/html/wordpress --post_type=\\\"post\\\" --post_status=\\\"publish\\\" --post_title=\\\"Post on $(date '+%Y-%m-%d %H:%M')\\\" --post_content=\\\"Post created with wp on $(hostname)\\\"\""

    run 50

    if [ $choice = y ]; then
        attempt=0
        ((seconds=$login_default * $speed / 100))
        while ((attempt++ <= login_attempts)); do
            echo
            echo "# ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \\"
            echo ">     \"sudo /usr/local/bin/wp post create --path=/var/www/html/wordpress --post_type=\\\"post\\\" --post_status=\\\"publish\\\" --post_title=\\\"Post on $(date '+%Y-%m-%d %H:%M')\\\" --post_content=\\\"Post created with wp on $(hostname)\\\"\""

            ssh -t -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name \
                "sudo /usr/local/bin/wp post create --path=/var/www/html/wordpress --post_type=\"post\" --post_status=\"publish\" --post_title=\"Post on $(date '+%Y-%m-%d %H:%M')\" --post_content=\"Post created with wp on $(hostname)\""
            RC=$?
            if [ $RC = 0 -o $RC = 1 ]; then
                break
            else
                echo
                echo -n "Not available ($RC). Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done

        next
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
        echo "aws ec2 describe-security-groups --profile $euca_profile --region $euca_region"
        echo
        echo "aws ec2 describe-instances --profile $euca_profile --region $euca_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws ec2 describe-security-groups --profile $euca_profile --region $euca_region"
            aws ec2 describe-security-groups --profile $euca_profile --region $euca_region
            pause

            echo "# aws ec2 describe-instances --profile $euca_profile --region $euca_region"
            aws ec2 describe-instances --profile $euca_profile --region $euca_region

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
        echo "aws cloudformation describe-stacks --profile $euca_profile --region $euca_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation describe-stacks --profile $euca_profile --region $euca_region"
            aws cloudformation describe-stacks --profile $euca_profile --region $euca_region

            next
        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create the Eucalyptus Stack"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws cloudformation create-stack --stack-name WordPressDemoStack \\"
    echo "                                --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
    echo "                                --parameters ParameterKey=KeyName,ParameterValue=$euca_ssh_key \\"
    echo "                                             ParameterKey=InstanceType,ParameterValue=m1.medium \\"
    echo "                                             ParameterKey=DBUser,ParameterValue=$mysql_user \\"
    echo "                                             ParameterKey=DBPassword,ParameterValue=$mysql_password \\"
    echo "                                             ParameterKey=DBRootPassword,ParameterValue=$mysql_password \\"
    echo "                                             ParameterKey=EndPoint,ParameterValue=$euca_cloudformation_url \\"
    echo "                                --capabilities CAPABILITY_IAM \\"
    echo "                                --profile $euca_profile --region $euca_region"

    if [ "$(aws cloudformation describe-stacks --stack-name WordPressDemoStack --profile $euca_profile --region $euca_region 2> /dev/null | grep "^STACKS" | cut -f7)" = "CREATE_COMPLETE" ]; then
        echo
        tput rev
        echo "Already Created!"
        tput sgr0

        next 50

    else
        run

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation create-stack --stack-name WordPressDemoStack \\"
            echo ">                                 --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \\"
            echo ">                                 --parameters ParameterKey=KeyName,ParameterValue=$euca_ssh_key \\"
            echo ">                                              ParameterKey=InstanceType,ParameterValue=m1.medium \\"
            echo ">                                              ParameterKey=DBUser,ParameterValue=$mysql_user \\"
            echo ">                                              ParameterKey=DBPassword,ParameterValue=$mysql_password \\"
            echo ">                                              ParameterKey=DBRootPassword,ParameterValue=$mysql_password \\"
            echo ">                                              ParameterKey=EndPoint,ParameterValue=$euca_cloudformation_url \\"
            echo ">                                 --capabilities CAPABILITY_IAM \\"
            echo ">                                 --profile $euca_profile --region $euca_region"
            aws cloudformation create-stack --stack-name=WordPressDemoStack \
                                            --template-body file://$tmpdir/WordPress_Single_Instance_Eucalyptus.template \
                                            --parameters ParameterKey=KeyName,ParameterValue=$euca_ssh_key \
                                                         ParameterKey=InstanceType,ParameterValue=m1.medium \
                                                         ParameterKey=DBUser,ParameterValue=$mysql_user \
                                                         ParameterKey=DBPassword,ParameterValue=$mysql_password \
                                                         ParameterKey=DBRootPassword,ParameterValue=$mysql_password \
                                                         ParameterKey=EndPoint,ParameterValue=$euca_cloudformation_url \
                                            --capabilities CAPABILITY_IAM \
                                            --profile $euca_profile --region $euca_region

            euca_stack_created=y

            next
        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Monitor Eucalyptus Stack creation"
    echo "    - NOTE: This can take about 360 - 600 seconds"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws cloudformation describe-stacks --profile $euca_profile --region $euca_region"
    echo
    echo "aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \\"
    echo "                                         --profile $euca_profile --region $euca_region"

        echo
        tput rev
        echo "Already Complete!"
        tput sgr0

        next 50

    else
        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws cloudformation describe-stacks --profile $euca_profile --region $euca_region"
            aws cloudformation describe-stacks --profile $euca_profile --region $euca_region
            pause

            attempt=0
            ((seconds=$create_default * $speed / 100))
            while ((attempt++ <= create_attempts)); do
                echo
                echo "# aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \\"
                echo ">                                          --profile $euca_profile --region $euca_region"
                aws cloudformation describe-stack-events --stack-name WordPressDemoStack --max-items 5 \
                                                         --profile $euca_profile --region $euca_region

                status=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack --profile $euca_profile --region $euca_region 2> /dev/null | grep "^STACKS" | cut -f7)
                if [ -z "$status" -o "$status" = "CREATE_COMPLETE" -o "$status" = "CREATE_FAILED" -o "$status" = "ROLLBACK_COMPLETE" ]; then
                    break
                else
                    echo
                    echo -n "Not finished ($RC). Waiting $seconds seconds..."
                    sleep $seconds
                    echo " Done"
                fi
            done

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
        echo "$(printf '%2d' $step). List updated Eucalyptus Resources"
        echo "    - Note addition of new group and instance"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "aws ec2 describe-security-groups --profile $euca_profile --region $euca_region"
        echo
        echo "aws ec2 describe-instances --profile $euca_profile --region $euca_region"

        run 50

        if [ $choice = y ]; then
            echo
            echo "# aws ec2 describe-security-groups --profile $euca_profile --region $euca_region"
            aws ec2 describe-security-groups --profile $euca_profile --region $euca_region
            pause

            echo "# aws ec2 describe-instances --profile $euca_profile --region $euca_region"
            aws ec2 describe-instances --profile $euca_profile --region $euca_region

            next
        fi
    fi
fi


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Obtain Eucalyptus Instance and Blog details"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "euca_instance_id=\$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \\"
    echo "                                                                --profile=$euca_profile --region=$euca_region | cut -f4)"
    echo "euca_public_name=\$(aws ec2 describe-instances --instance-ids $euca_instance_id \\"
    echo "                                               --profile=$euca_profile --region=$euca_region | grep \"^INSTANCES\" | cut -f11)"
    echo "euca_public_ip=\$(aws ec2 describe-instances --instance-ids $euca_instance_id \\"
    echo "                                             --profile=$euca_profile --region=$euca_region | grep \"^INSTANCES\" | cut -f12)"
    echo
    echo "euca_wordpress_url=\$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \\"
    echo "                                                         --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \\"
    echo "                                                         --profile=$euca_profile --region=$euca_region 2> /dev/null)"

    next 50

    echo
    echo "# euca_instance_id=\$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \\"
    echo ">                                                                 --profile=$euca_profile --region=$euca_region | cut -f4)"
    euca_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \
                                                                   --profile=$euca_profile --region=$euca_region | cut -f4)
    echo "$euca_instance_id"
    echo "#"
    echo "# euca_public_name=\$(aws ec2 describe-instances --instance-ids $euca_instance_id \\"
    echo ">                                                --profile=$euca_profile --region=$euca_region | grep \"^INSTANCES\" | cut -f11)"
    euca_public_name=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                  --profile=$euca_profile --region=$euca_region | grep "^INSTANCES" | cut -f11)
    echo "$euca_public_name"
    echo "#"
    echo "# euca_public_ip=\$(aws ec2 describe-instances --instance-ids $euca_instance_id \\"
    echo ">                                              --profile=$euca_profile --region=$euca_region | grep \"^INSTANCES\" | cut -f12)"
    euca_public_ip=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                --profile=$euca_profile --region=$euca_region | grep "^INSTANCES" | cut -f12)
    echo "$euca_public_ip"
    pause

    echo "# euca_wordpress_url=\$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \\"
    echo ">                                                          --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \\"
    echo ">                                                          --profile=$euca_profile --region=$euca_region 2> /dev/null)"
    euca_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                            --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                            --profile=$euca_profile --region=$euca_region 2> /dev/null)
    echo "$euca_wordpress_url"

    next
else
    euca_instance_id=$(aws cloudformation describe-stack-resources --stack-name WordPressDemoStack --logical-resource-id WebServer \
                                                                   --profile=$euca_profile --region=$euca_region | cut -f4)
    euca_public_name=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                  --profile=$euca_profile --region=$euca_region | grep "^INSTANCES" | cut -f11)
    euca_public_ip=$(aws ec2 describe-instances --instance-ids $euca_instance_id \
                                                --profile=$euca_profile --region=$euca_region | grep "^INSTANCES" | cut -f12)

    euca_wordpress_url=$(aws cloudformation describe-stacks --stack-name WordPressDemoStack \
                                                            --query 'Stacks[].Outputs[?OutputKey==`WebsiteURL`].{OutputValue:OutputValue}' \
                                                            --profile=$euca_profile --region=$euca_region 2> /dev/null)
fi

sed -i -e "/$euca_public_name/d" ~/.ssh/known_hosts 2> /dev/null
sed -i -e "/$euca_public_ip/d" ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan $euca_public_name 2> /dev/null >> ~/.ssh/known_hosts
ssh-keyscan $euca_public_ip 2> /dev/null >> ~/.ssh/known_hosts


((++step))
if [ $mode = e -o $mode = b -o $mode = m ]; then
    if [ $verbose = 1 ]; then
        clear
        echo
        echo "============================================================"
        echo
        echo "$(printf '%2d' $step). View WordPress on AWS Instance"
        echo "    - Display WordPress via text-mode browser"
        echo "    - Observe current content from AWS"
        echo "    - Alternatively, you can view WordPress via a graphical browser:"
        echo "      $aws_wordpress_url"
        echo
        echo "============================================================"
        echo
        echo "Commands:"
        echo
        echo "lynx -dump $aws_wordpress_url"

        run 50

        if [ $choice = y ]; then

            echo "# lynx -dump $aws_wordpress_url"
            lynx -dump $aws_wordpress_url | sed -e '1,/^  . WordPress.org$/d' -e 's/^\(Posted on [A-Za-z]* [0-9]*, 20..\).*$/\1/'

            next 50

        fi
    fi
fi


((++step))
if [ $mode = e -o $mode = b -o $mode = m ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Backup WordPress on AWS Instance"
    echo "    - Backup WordPress database"
    echo "    - Copy database backup from Instance to AWS S3 Bucket (demo-$aws_account)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name << EOF"
    echo "mysqldump -u$mysql_root -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
    echo "aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read"
    echo "EOF"

    run 50

    if [ $choice = y ]; then
        attempt=0
        ((seconds=$login_default * $speed / 100))
        while ((attempt++ <= login_attempts)); do
            echo
            echo "# ssh -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name"
            ssh -T -i ~/.ssh/${aws_ssh_key}_id_rsa $aws_ssh_user@$aws_public_name << EOF
echo "> mysqldump -u$mysql_root -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
mysqldump --compatible=mysql4 -u$mysql_root -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile
sleep 1
echo
echo "> aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read"
aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read
rm -f $tmpdir/$mysql_bakfile
EOF
            RC=$?
            if [ $RC = 0 -o $RC = 1 ]; then
                break
            else
                echo
                echo -n "Not available ($RC). Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done

        next
    fi
fi


((++step))
if [ $mode = e -o $mode = b -o $mode = m ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Restore WordPress on Eucalyptus Instance"
    echo "    - Copy database backup from AWS S3 Bucket (demo-$aws_account) to Instance"
    echo "    - Restore WordPress database"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/${euca_ssh_key}_id_rsa $euca_ssh_user@$euca_public_name << EOF"
    echo "wget http://$aws_s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
    echo "mysql -u$mysql_root -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
    echo "EOF"

    run 50

    if [ $choice = y ]; then
        attempt=0
        ((seconds=$login_default * $speed / 100))
        while ((attempt++ <= login_attempts)); do
            echo
            echo "# ssh -i ~/.ssh/${euca_ssh_key}_id_rsa $euca_ssh_user@$euca_public_name"
            ssh -T -i ~/.ssh/${euca_ssh_key}_id_rsa $euca_ssh_user@$euca_public_name << EOF
echo "# wget http://$aws_s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
wget http://$aws_s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile
sleep 1
echo
echo "# mysql -u$mysql_root -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
mysql -u$mysql_root -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile
EOF
            RC=$?
            if [ $RC = 0 -o $RC = 1 ]; then
                break
            else
                echo
                echo -n "Not available ($RC). Waiting $seconds seconds..."
                sleep $seconds
                echo " Done"
            fi
        done

        next
    fi
fi


((++step))
if [ $mode = e -o $mode = b -o $mode = m ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm WordPress Migration on Eucalyptus Instance"
    echo "    - Display WordPress via text-mode browser"
    echo "    - Confirm latest content from AWS is now running in Eucalyptus"
    echo "    - Alternatively, you can view WordPress via a graphical browser:"
    echo "      $euca_wordpress_url"
    echo
    echo "============================================================"
    echo

    echo "Commands:"
    echo
    echo "lynx -dump $euca_wordpress_url"

    run 50

    if [ $choice = y ]; then

        echo "# lynx -dump $euca_wordpress_url"
        lynx -dump $euca_wordpress_url | sed -e '1,/^  . WordPress.org$/d' -e 's/^\(Posted on [A-Za-z]* [0-9]*, 20..\).*$/\1/'

        next 50

    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus CloudFormation WordPress demo execution complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus CloudFormation WordPress demo execution complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
