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

mysql_user=root
mysql_password=password
mysql_db=wordpressdb
mysql_bakfile=$mysql_db.bak

ssh_user=root
aws_ssh_user=ec2-user

federation=aws

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
mode=offramp
region=${AWS_DEFAULT_REGION#*@}
account=${AWS_ACCOUNT_NAME:-demo}
user=${AWS_USER_NAME:-admin}
aws_region=us-east-1
aws_account=euca
aws_user=demo


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-N]"
    echo "                  [-r region ] [-a account] [-u user]"
    echo "                  [-R aws_region] [-A aws_account] [-U aws_user]"
    echo "  -I              non-interactive"
    echo "  -s              slower: increase pauses by 25%"
    echo "  -f              faster: reduce pauses by 25%"
    echo "  -N              oNramp: migrate from Eucalyptus to AWS (default: $mode)"
    echo "  -r region       Region (default: $region)"
    echo "  -a account      Account (default: $account)"
    echo "  -u user         User (default: $user)"
    echo "  -R aws_region   Partner AWS Region (default: $aws_region)"
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

while getopts IsfNr:a:u:R:A:U:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    N)  mode=onramp
        echo "onramp mode not yet supported!"
        exit 100;;
    r)  region="$OPTARG";;
    a)  account="$OPTARG";;
    u)  user="$OPTARG";;
    R)  aws_region="$OPTARG";;
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
        echo "-r $region invalid: Please specify a Eucalyptus region"
        exit 11;;
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

if [ -z $aws_region ]; then
    echo "-R aws_region missing!"
    echo "Could not automatically determine aws_region, and it was not specified as a parameter"
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

profile=$region-$account-$user
profile_region=$profile@$region

if ! grep -s -q "\[user $profile]" ~/.euca/$region.ini; then
    echo "Could not find $region Demo ($account) Account Demo ($user) User Euca2ools user!"
    echo "Expected to find: [user $profile] in ~/.euca/$region.ini"
    exit 50
fi

aws_profile=$federation-$aws_account-$aws_user
aws_profile_region=$aws_profile@$aws_region

if ! grep -s -q "\[user $aws_profile]" ~/.euca/$federation.ini; then
    echo "Could not find AWS ($aws_account) Account Demo ($aws_user) User Euca2ools user!"
    echo "Expected to find: [user $aws_profile] in ~/.euca/$federation.ini"
    exit 52
fi


#  5. Run Migration

start=$(date +%s)

((++step))
clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Obtain Instance details"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "euca_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$profile_region | cut -f3)"
echo
echo "euca_public_name=\$(euca-describe-instances \$euca_instance_id --region=$profile_region | grep \"^INSTANCE\" | cut -f4)"
echo
echo "euca_public_ip=\$(euca-describe-instances \$euca_instance_id --region=$profile_region | grep \"^INSTANCE\" | cut -f17)"
echo
echo "aws_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_profile_region | cut -f3)"
echo
echo "aws_public_name=\$(euca-describe-instances \$aws_instance_id --region=$aws_profile_region | grep \"^INSTANCE\" | cut -f4)"
echo
echo "aws_public_ip=\$(euca-describe-instances \$aws_instance_id --region=$aws_profile_region | grep \"^INSTANCE\" | cut -f17)"
echo

next

echo
echo "# euca_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$profile_region | cut -f3)"
euca_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$profile_region | cut -f3)
echo "$euca_instance_id"
pause

echo "# euca_public_name=\$(euca-describe-instances \$euca_instance_id --region=$profile_region | grep \"^INSTANCE\" | cut -f4)"
euca_public_name=$(euca-describe-instances $euca_instance_id --region=$profile_region | grep "^INSTANCE" | cut -f4)
echo "$euca_public_name"
pause

echo "# euca_public_ip=\$(euca-describe-instances \$euca_instance_id --region=$profile_region | grep \"^INSTANCE\" | cut -f17)"
euca_public_ip=$(euca-describe-instances $euca_instance_id --region=$profile_region | grep "^INSTANCE" | cut -f17)
echo "$euca_public_ip"
pause

echo "# aws_instance_id=\$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_profile_region | cut -f3)"
aws_instance_id=$(euform-describe-stack-resources -n WordPressDemoStack -l WebServer --region=$aws_profile_region | cut -f3)
echo "$aws_instance_id"
pause

echo "# aws_public_name=\$(euca-describe-instances \$aws_instance_id --region=$aws_profile_region | grep \"^INSTANCE\" | cut -f4)"
aws_public_name=$(euca-describe-instances $aws_instance_id --region=$aws_profile_region | grep "^INSTANCE" | cut -f4)
echo "$aws_public_name"
pause

echo "# aws_public_ip=\$(euca-describe-instances \$aws_instance_id --region=$aws_profile_region | grep \"^INSTANCE\" | cut -f17)"
aws_public_ip=$(euca-describe-instances $aws_instance_id --region=$aws_profile_region | grep "^INSTANCE" | cut -f17)
echo "$aws_public_ip"

next


((++step))
if [ $mode = offramp ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Off-Ramp Migration: Backup WordPress on AWS Instance"
    echo "    - Backup WordPress database"
    echo "    - Copy database backup from Instance to AWS S3 Bucket (demo-$aws_account)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/demo_id_rsa $aws_ssh_user@$aws_public_name << EOF"
    echo "mysqldump -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
    echo "aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read"
    echo "EOF"

    run 50

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
echo "> mysqldump -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
mysqldump --compatible=mysql4 -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile
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
else
    echo "***** This is not complete or supported yet!"
    exit 100

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). On-Ramp Migration: Backup WordPress on Eucalyptus Instance"
    echo "    - Backup WordPress database"
    echo "    - Copy database backup from Instance to AWS S3 Bucket (demo-$aws_account)"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name << EOF"
    echo "mysqldump -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
    echo "aws s3 cp $tmpdir/$mysql_bakfile s3://demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile --acl public-read"
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
            echo "# ssh -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name"
            ssh -T -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name << EOF
echo "> mysqldump -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile"
mysqldump -u$mysql_user -p$mysql_password $mysql_db > $tmpdir/$mysql_bakfile
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
if [ $mode = offramp ]; then
    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). Off-Ramp Migration: Restore WordPress on Eucalyptus Instance"
    echo "    - Copy database backup from AWS S3 Bucket (demo-$aws_account) to Instance"
    echo "    - Restore WordPress database"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name << EOF"
    echo "wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
    echo "mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
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
            echo "# ssh -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name"
            ssh -T -i ~/.ssh/demo_id_rsa $ssh_user@$euca_public_name << EOF
echo "# wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
wget http://$s3_domain/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile
sleep 1
echo
echo "# mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile
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
else
    echo "***** This is not complete or supported yet!"
    exit 100

    clear
    echo
    echo "============================================================"
    echo
    echo "$(printf '%2d' $step). On-Ramp Migration: Restore WordPress on AWS Instance"
    echo "    - Copy database backup from AWS S3 Bucket (demo-$aws_account) to Instance"
    echo "    - Restore WordPress database"
    echo
    echo "============================================================"
    echo
    echo "Commands:"
    echo
    echo "ssh -T -i ~/.ssh/demo_id_rsa $aws_ssh_user@$aws_public_name << EOF"
    echo "wget http://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
    echo "mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
    echo "EOF"

    run 50

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
echo "# wget http://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile"
wget http://s3.amazonaws.com/demo-$aws_account/demo-30-cfn-wordpress/$mysql_bakfile -O $tmpdir/$mysql_bakfile
sleep 1
echo
echo "# mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile"
mysql -u$mysql_user -p$mysql_password -D$mysql_db < $tmpdir/$mysql_bakfile
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


#echo
#echo "Eucalyptus CloudFormation WordPress migration execution complete (time: $(date -u -d @$((end-start)) +"%T"))"
