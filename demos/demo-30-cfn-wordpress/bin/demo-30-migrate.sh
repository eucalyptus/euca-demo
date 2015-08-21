#!/bin/bash
#
# This script migrates the WordPress database created as part of the Eucalyptus
# CloudFormation demo which uses the WordPress_Single_Instance_Eucalyptus.template
# to create WordPress-based blog.
#
# This script is designed to be run, either via the demo-30-run-cfn-wordpress.sh
# script, or via manual action when the GUI is used for the demo.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

federation=aws

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

create_attempts=24
create_default=20
login_attempts=6
login_default=20
delete_attempts=6
delete_default=20

interactive=1
speed=100
verbose=0
euca_region=${AWS_DEFAULT_REGION#*@}
euca_account=${AWS_ACCOUNT_NAME:-demo}
euca_user=${AWS_USER_NAME:-admin}
euca_ssh_user=root
euca_ssh_key=demo
aws_region=us-east-1
aws_account=euca
aws_user=demo
aws_ssh_user=ec2-user
aws_ssh_key=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v]"
    echo "                   [-r euca_region ] [-a euca_account] [-u euca_user]"
    echo "                   [-R aws_region] [-A aws_account] [-U aws_user]"
    echo "  -I               non-interactive"
    echo "  -s               slower: increase pauses by 25%"
    echo "  -f               faster: reduce pauses by 25%"
    echo "  -v               verbose"
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

while getopts Isfvr:a:u:R:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
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

if [ -z $euca_region ]; then
    echo "-r euca_region missing!"
    echo "Could not automatically determine Eucalyptus region, and it was not specified as a parameter"
    exit 10
else
    case $euca_region in
      us-east-1|us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
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
        s3_domain=s3.amazonaws.com;;
      us-west-1|us-west-2) ;&
      sa-east-1) ;&
      eu-west-1|eu-central-1) ;&
      ap-northeast-1|ap-southeast-1|ap-southeast-2)
        s3_domain=s3-$aws_region.amazonaws.com;;
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

if ! rpm -q --quiet w3m; then
    echo "w3m missing: This demo uses the w3m text-mode browser to confirm webpage content"
    exit 98
fi


#  5. Run Migration

start=$(date +%s)

((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Obtain Instance and Blog details"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "aws_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_user_region | cut -f3)"
    echo "aws_public_name=\$(euca-describe-instances --region=$aws_user_region \$aws_instance_id | grep \"^INSTANCE\" | cut -f4)"
    echo "aws_public_ip=\$(euca-describe-instances --region=$aws_user_region \$aws_instance_id | grep \"^INSTANCE\" | cut -f17)"
    echo
    echo "aws_wordpress_url=\$(euform-describe-stacks --region=$aws_user_region WordPressDemoStack | grep \"^OUTPUT.WebsiteURL\" | cut -f3)"
    echo
    echo "euca_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$euca_user_region | cut -f3)"
    echo "euca_public_name=\$(euca-describe-instances --region=$euca_user_region \$euca_instance_id | grep \"^INSTANCE\" | cut -f4)"
    echo "euca_public_ip=\$(euca-describe-instances --region=$euca_user_region \$euca_instance_id | grep \"^INSTANCE\" | cut -f17)"
    echo
    echo "euca_wordpress_url=\$(euform-describe-stacks --region=$euca_user_region WordPressDemoStack | grep \"^OUTPUT.WebsiteURL\" | cut -f3)"
    echo

    next

    echo
    echo "# aws_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_user_region | cut -f3)"
    aws_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_user_region | cut -f3)
    echo "$aws_instance_id"
    echo "#"
    echo "# aws_public_name=\$(euca-describe-instances --region=$aws_user_region \$aws_instance_id | grep \"^INSTANCE\" | cut -f4)"
    aws_public_name=$(euca-describe-instances --region=$aws_user_region $aws_instance_id | grep "^INSTANCE" | cut -f4)
    echo "$aws_public_name"
    echo "#"
    echo "# aws_public_ip=\$(euca-describe-instances --region=$aws_user_region \$aws_instance_id | grep \"^INSTANCE\" | cut -f17)"
    aws_public_ip=$(euca-describe-instances --region=$aws_user_region $aws_instance_id | grep "^INSTANCE" | cut -f17)
    echo "$aws_public_ip"
    pause

    echo "# aws_wordpress_url=/$(euform-describe-stacks --region=$aws_user_region WordPressDemoStack | grep \"^OUTPUT.WebsiteURL\" | cut -f3)"
    aws_wordpress_url=$(euform-describe-stacks --region=$aws_user_region WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
    echo "$aws_wordpress_url"
    pause

    echo "# euca_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$euca_user_region | cut -f3)"
    euca_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$euca_user_region | cut -f3)
    echo "$euca_instance_id"
    echo "#"
    echo "# euca_public_name=\$(euca-describe-instances --region=$euca_user_region \$euca_instance_id | grep \"^INSTANCE\" | cut -f4)"
    euca_public_name=$(euca-describe-instances --region=$euca_user_region $euca_instance_id | grep "^INSTANCE" | cut -f4)
    echo "$euca_public_name"
    echo "#"
    echo "# euca_public_ip=\$(euca-describe-instances --region=$euca_user_region \$euca_instance_id | grep \"^INSTANCE\" | cut -f17)"
    euca_public_ip=$(euca-describe-instances --region=$euca_user_region $euca_instance_id | grep "^INSTANCE" | cut -f17)
    echo "$euca_public_ip"
    pause

    echo "# euca_wordpress_url=/$(euform-describe-stacks --region=$euca_user_region WordPressDemoStack | grep \"^OUTPUT.WebsiteURL\" | cut -f3)"
    euca_wordpress_url=$(euform-describe-stacks --region=$euca_user_region WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
    echo "$euca_wordpress_url"

    next
else
    aws_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_user_region | cut -f3)
    aws_public_name=$(euca-describe-instances --region=$aws_user_region $aws_instance_id | grep "^INSTANCE" | cut -f4)
    aws_public_ip=$(euca-describe-instances --region=$aws_user_region $aws_instance_id | grep "^INSTANCE" | cut -f17)

    aws_wordpress_url=$(euform-describe-stacks --region=$aws_user_region WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)

    euca_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$euca_user_region | cut -f3)
    euca_public_name=$(euca-describe-instances --region=$euca_user_region $euca_instance_id | grep "^INSTANCE" | cut -f4)
    euca_public_ip=$(euca-describe-instances --region=$euca_user_region $euca_instance_id | grep "^INSTANCE" | cut -f17)

    euca_wordpress_url=$(euform-describe-stacks --region=$euca_user_region WordPressDemoStack | grep "^OUTPUT.WebsiteURL" | cut -f3)
fi


((++step))
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
    echo "w3m -dump $aws_wordpress_url"

    run 50

    if [ $choice = y ]; then

        echo "# w3m -dump $aws_wordpress_url"
        w3m -dump $aws_wordpress_url | sed -e '1,/^  . WordPress.org$/d' -e 's/^\(Posted on [A-Za-z]* [0-9]*, 20..\).*$/\1/'

        next 50

    fi
fi


((++step))
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
echo "ssh -T -i ~/.ssh/demo_id_rsa $aws_ssh_user@$aws_public_name << EOF"
echo "mysqldump -u$mysql_root -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
echo "aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read"
echo "EOF"

run

if [ $choice = y ]; then
    attempt=0
    ((seconds=$login_default * $speed / 100))
    while ((attempt++ <= login_attempts)); do
        sed -i -e "/$aws_public_name/d" ~/.ssh/known_hosts
        sed -i -e "/$aws_public_ip/d" ~/.ssh/known_hosts
        ssh-keyscan $aws_public_name 2> /dev/null >> ~/.ssh/known_hosts
        ssh-keyscan $aws_public_ip 2> /dev/null >> ~/.ssh/known_hosts

        echo
        echo "# ssh -i ~/.ssh/demo_id_rsa $aws_ssh_user@$aws_public_name"
        ssh -T -i ~/.ssh/demo_id_rsa $aws_ssh_user@$aws_public_name << EOF
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


((++step))
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
echo "ssh -T -i ~/.ssh/demo_id_rsa $euca_ssh_user@$euca_public_name << EOF"
echo "wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
echo "mysql -u$mysql_root -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
echo "EOF"

run 50

if [ $choice = y ]; then
    attempt=0
    ((seconds=$login_default * $speed / 100))
    while ((attempt++ <= login_attempts)); do
        sed -i -e "/$euca_public_name/d" ~/.ssh/known_hosts
        sed -i -e "/$euca_public_ip/d" ~/.ssh/known_hosts
        ssh-keyscan $euca_public_name 2> /dev/null >> ~/.ssh/known_hosts
        ssh-keyscan $euca_public_ip 2> /dev/null >> ~/.ssh/known_hosts

        echo
        echo "# ssh -i ~/.ssh/demo_id_rsa $euca_ssh_user@$euca_public_name"
        ssh -T -i ~/.ssh/demo_id_rsa $euca_ssh_user@$euca_public_name << EOF
echo "# wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile
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


((++step))
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
echo "w3m -dump $euca_wordpress_url"

run 50

if [ $choice = y ]; then

    echo "# w3m -dump $euca_wordpress_url"
    w3m -dump $euca_wordpress_url | sed -e '1,/^  . WordPress.org$/d' -e 's/^\(Posted on [A-Za-z]* [0-9]*, 20..\).*$/\1/'

    next 50

fi


end=$(date +%s)


#echo
#echo "Eucalyptus CloudFormation WordPress migration execution complete (time: $(date -u -d @$((end-start)) +"%T"))"
