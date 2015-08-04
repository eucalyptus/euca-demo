#/bin/bash
#
# This script runs a Eucalyptus CloudFormation demo which uses the
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
# This script assumes many conventions created by the installation DNS and demo initialization
# scripts.
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
created=n

create_attempts=24
create_default=20
login_attempts=6
login_default=20
delete_attempts=6
delete_default=20

interactive=1
speed=100
mode=restore
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-demo}
aws_region=us-east-1
aws_account=euca
aws_user=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c] [-r region ] [-a account] [-u user] [-A aws_account] [-U aws_user]"
    echo "  -I              non-interactive"
    echo "  -s              slower: increase pauses by 25%"
    echo "  -f              faster: reduce pauses by 25%"
    echo "  -c              configure mode: Configure WordPress (default: $mode)"
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

while getopts Isfcr:a:u:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  mode=configure;;
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
        aws_region=$region
        cloudformation_url=https://cloudformation.$region.amazonaws.com;;
      *)
        target="euca"
        cloudformation_url=$(sed -n -e "s/cloudformation-url = \(.*\)\/services\/CloudFormation$/\1/p" /etc/euca2ools/conf.d/$region.ini);;
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

if [ -z $cloudformation_url ]; then
    echo "Could not automatically determine CloudFormation URL"
    echo "For Eucalyptus Regions, we attempt to lookup the value of "cloudformation-url" in /etc/euca2ools/conf.d/$region.ini"
    echo 19
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

if ! rpm -q --quiet w3m; then
    echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
    exit 98
fi


#  5. Run Demo

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


((++step))
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
echo "$(printf '%2d' $step). List CloudFormation Stacks"
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

    next 200
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Create the Stack"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-create-stack --template-url https://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
echo "                    --parameter \"KeyName=demo\" \\"
echo "                    --parameter \"DBUser=demo\" \\"
echo "                    --parameter \"DBPassword=password\" \\"
echo "                    --parameter \"DBRootPassword=password\" \\"
echo "                    --parameter \"EndPoint=$cloudformation_url\" \\"
echo "                    --capabilities CAPABILITY_IAM \\"
echo "                    WordPressDemoStack"

if [ "$(euform-describe-stacks WordPressDemoStack 2> /dev/null | grep "^STACK" | cut -f3)" = "CREATE_COMPLETE" ]; then
    echo
    tput rev
    echo "Already Created!"
    tput sgr0

    next 50

else
    run

    if [ $choice = y ]; then
        echo
        echo "# euform-create-stack --template-url https://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \\"
        echo ">                     --parameter \"KeyName=demo\" \\"
        echo ">                     --parameter \"DBUser=demo\" \\"
        echo ">                     --parameter \"DBPassword=password\" \\"
        echo ">                     --parameter \"DBRootPassword=password\" \\"
        echo ">                     --parameter \"EndPoint=$cloudformation_url\" \\"
        echo ">                     --capabilities CAPABILITY_IAM \\"
        echo ">                     WordPressDemoStack"
        euform-create-stack --template-url https://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/WordPress_Single_Instance_Eucalyptus.template \
                            --parameter "KeyName=demo" \
                            --parameter "DBUser=demo" \
                            --parameter "DBPassword=password" \
                            --parameter "DBRootPassword=password" \
                            --parameter "EndPoint=$cloudformation_url" \
                            --capabilities CAPABILITY_IAM \
                            WordPressDemoStack

        created=y

        next
    fi
fi


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Monitor Stack creation"
echo "    - NOTE: This can take about 400 - 500 seconds"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euform-describe-stacks"
echo
echo "euform-describe-stack-events WordPressDemoStack | head -5"

if [ "$(euform-describe-stacks WordPressDemoStack 2> /dev/null | grep "^STACK" | cut -f3)" = "CREATE_COMPLETE" ]; then
    echo
    tput rev
    echo "Already Complete!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euform-describe-stacks"
        euform-describe-stacks
        pause

        attempt=0
        ((seconds=$create_default * $speed / 100))
        while ((attempt++ <= create_attempts)); do
            echo
            echo "# euform-describe-stack-events WordPressDemoStack | head -5"
            euform-describe-stack-events WordPressDemoStack | head -5

            status=$(euform-describe-stacks WordPressDemoStack 2> /dev/null | grep "^STACK" | cut -f3)
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


((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). List updated Resources"
echo "    - Note addition of new group and instance"
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


if [ $mode = configure -a $created = y ]; then
    ((++step))
    wordpress_url=$(euform-describe-stacks WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Configure WordPress"
    echo "    - Configure WordPress via a browser:"
    echo "      $wordpress_url"
    echo "    - Using these values:"
    if [ $target = euca ]; then
        echo "      - Site Title: Eucalyptus Demo ($account) Account WordPress Demo"
    else
        echo "      - Site Title: AWS ($account) Account  WordPress Demo"
    fi
    echo "      - Username: demo"
    echo "      - Password: <discover_password>"
    echo "      - Your E-mail: <use your hp email address>"
    echo
    echo "============================================================"
    echo

    next 200
fi


if [ $mode = configure ]; then
    ((++step))
    wordpress_url=$(euform-describe-stacks WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
 
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Create WordPress Blog Post"
    echo "    - Create a Blog Post in WordPress via a browser:"
    echo "      $wordpress_url"
    echo "    - Using these values:"
    echo "      - Username: demo"
    echo "      - Password: <discover_password>"
    echo "    - This is to show migration of the current database content"
    echo
    echo "============================================================"
    echo
 
    # Look into creating this automatically via wp-cli or similar

    next 200
fi

if [ $mode = restore ]; then
    ((++step))
    instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer | cut -f3)
    public_name=$(euca-describe-instances $instance_id | grep "^INSTANCE" | cut -f4)
    public_ip=$(euca-describe-instances $instance_id | grep "^INSTANCE" | cut -f17)
    if [ $target = euca ]; then
        user=centos
    else
        user=ec2-user
    fi

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Confirm ability to login to Instance"
    echo "    - If unable to login, view instance console output with:"
    echo "      # euca-get-console-output $instance_id"
    echo "    - If able to login, first show the private IP with:"
    echo "      # ifconfig"
    echo "    - Then view meta-data about the public IP with:"
    echo "      # curl http://169.254.169.254/latest/meta-data/public-ipv4"
    echo "    - Logout of instance once login ability confirmed"
    echo "    - NOTE: This can take about 00 - 40 seconds"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -i ~/.ssh/demo_id_rsa $user@$public_name"

    run 50

    if [ $choice = y ]; then
        attempt=0
        ((seconds=$login_default * $speed / 100))
        while ((attempt++ <= login_attempts)); do
            sed -i -e "/$public_name/d" ~/.ssh/known_hosts
            sed -i -e "/$public_ip/d" ~/.ssh/known_hosts
            ssh-keyscan $public_name 2> /dev/null >> ~/.ssh/known_hosts
            ssh-keyscan $public_ip 2> /dev/null >> ~/.ssh/known_hosts

            echo
            echo "# ssh -i ~/.ssh/demo_id_rsa $user@$public_name"
            ssh -T -i ~/.ssh/demo_id_rsa $user@$public_name << EOF
echo "# ifconfig"
ifconfig
sleep 5
echo
echo "# curl http://169.254.169.254/latest/meta-data/public-ipv4"
curl -sS http://169.254.169.254/latest/meta-data/public-ipv4 -o /tmp/public-ip4
cat /tmp/public-ip4
sleep 5
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


end=$(date +%s)

echo
echo "Eucalyptus CloudFormation WordPress demo execution complete (time: $(date -u -d @$((end-start)) +"%T"))"
