#/bin/bash
#
# This script configures the AWS CLI to access the local Eucalyptus instance after a Faststart installation
#
# This should be run after the Faststart Reverse Proxy configuration script
#
# This script assumes the reverse proxy configuration script has been run so Eucalyptus
# is accessible by HTTPS URLs on the standard port.
#

#  1. Initalize Environment

if [ -z $EUCA_VNET_MODE ]; then
    echo "Please set environment variables first"
    exit 3
fi

[ "$(hostname -s)" = "$EUCA_CLC_HOST_NAME" ] && is_clc=y || is_clc=n

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
docdir=${bindir%/*}/doc
logdir=${bindir%/*}/log
certsdir=${bindir%/*}/certs
scriptsdir=${bindir%/*}/scripts
templatesdir=${bindir%/*}/templates
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100

#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]]"
    echo "  -I  non-interactive"
    echo "  -s  slower: increase pauses by 25%"
    echo "  -f  faster: reduce pauses by 25%"
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

while getopts Isf? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [ $is_clc = n ]; then
    echo "This script should only be run on the Cloud Controller host"
    exit 10
fi

if [ ! -r ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ]; then
    echo "Could not find Eucalyptus Administrator credentials!"
    echo "Expected to find: ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc"
    sleep 2

    if [ -r /root/admin.zip ]; then
        echo "Moving Faststart Eucalyptus Administrator credentials to appropriate creds directory"
        mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin
        cp -a /root/admin.zip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip
        unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/
        sleep 2
    else
        echo "Could not convert FastStart Eucalyptus Administrator credentials!"
        echo "Expected to find: /root/admin.zip"
        exit 29
    fi
fi


#  5. Execute Procedure

start=$(date +%s)

((++step))
clear
echo
echo "================================================================================"
echo
echo " $(printf '%2d' $step). Use Eucalyptus Administrator credentials"
echo
echo "================================================================================"
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
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install Python Pip"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "yum install -y python-pip"

run 50

if [ $choice = y ]; then
    echo
    echo "# yum install -y python-pip"
    yum install -y python-pip

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install AWS CLI"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pip install awscli"

run 50

if [ $choice = y ]; then
    echo
    echo "# pip install awscli"
    pip install awscli

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure AWS CLI to support local Eucalyptus region"
echo "     - This creates a modified version of the _endpoints.json file which the"
echo "       botocore Python module within AWS CLI uses to configure AWS endpoints,"
echo "       adding the new local Eucalyptus region endpoints"
echo "     - We then rename the original _endpoints.json file with the .orig extension,"
echo "       then create a symlink with the original name pointing to our version"
echo "     - The files created are too long to display - view it in the location"
echo "       shown below. You can compare with the original to see what changes have"
echo "       been made."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cd /usr/lib/python2.6/site-packages/botocore/data"
echo "cat << EOF > _endpoints.json.local.ssl"
echo "    .... too long to list ...."
echo "EOF"
echo
echo "mv _endpoints.json _endpoints.json.orig"
echo 
echo "ln -s _endoints.json.ssl _endpoints.json"

run 50

if [ $choice = y ]; then
    echo
    echo "cd /usr/lib/python2.6/site-packages/botocore/data
    pushd /usr/lib/python2.6/site-packages/botocore/data &> /dev/null
    echo "#"
    echo "# cat << EOF > _endpoints.json.local.ssl"
    echo ">     ... too long to list ..."
    echo "> EOF"
    echo "{"                                                                                    > _endpoints.json.local.ssl
    echo "  \"_default\":["                                                                    >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.{region}.$EUCA_DNS_REGION_DOMAIN\","            >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${EUCA_DNS_REGION%-*}-\"]"                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.{region}.amazonaws.com.cn\","                   >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "          \"signatureVersion\": \"v4\""                                              >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.{region}.amazonaws.com\","                      >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notEquals\", null]"                                           >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"ec2\": ["                                                                        >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://compute.{region}.$EUCA_DNS_REGION_DOMAIN\","              >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\",\"startsWith\",\"${EUCA_DNS_REGION%-*}-\"]"                      >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"elasticloadbalancing\": ["                                                       >> _endpoints.json.local.ssl
    echo "   {"                                                                                >> _endpoints.json.local.ssl
    echo "    \"uri\":\"{scheme}://loadbalancing.{region}.$EUCA_DNS_REGION_DOMAIN\","          >> _endpoints.json.local.ssl
    echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
    echo "      [\"region\",\"startsWith\",\"${EUCA_DNS_REGION%-*}-\"]"                        >> _endpoints.json.local.ssl
    echo "    ]"                                                                               >> _endpoints.json.local.ssl
    echo "   }"                                                                                >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"monitoring\":["                                                                  >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://cloudwatch.{region}.$EUCA_DNS_REGION_DOMAIN\","           >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "       [\"region\",\"startsWith\",\"${EUCA_DNS_REGION%-*}-\"]"                       >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"swf\":["                                                                         >> _endpoints.json.local.ssl
    echo "   {"                                                                                >> _endpoints.json.local.ssl
    echo "    \"uri\":\"{scheme}://simpleworkflow.{region}.$EUCA_DNS_REGION_DOMAIN\","         >> _endpoints.json.local.ssl
    echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
    echo "     [\"region\",\"startsWith\",\"${EUCA_DNS_REGION%-*}-\"]"                         >> _endpoints.json.local.ssl
    echo "    ]"                                                                               >> _endpoints.json.local.ssl
    echo "   }"                                                                                >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"iam\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://euare.{region}.$EUCA_DNS_REGION_DOMAIN\","                   >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${EUCA_DNS_REGION%-*}-\"]"                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{service}.cn-north-1.amazonaws.com.cn\","                    >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{service}.us-gov.amazonaws.com\","                           >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"us-gov\"]"                                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://iam.amazonaws.com\","                                        >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"credentialScope\": {"                                                      >> _endpoints.json.local.ssl
    echo "            \"region\": \"us-east-1\""                                               >> _endpoints.json.local.ssl
    echo "        }"                                                                           >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"sdb\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://sdb.amazonaws.com\","                                        >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"us-east-1\"]"                                     >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"sts\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://tokens.{region}.$EUCA_DNS_REGION_DOMAIN\","                  >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${EUCA_DNS_REGION%-*}-\"]"                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.cn-north-1.amazonaws.com.cn\","                 >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{service}.{region}.amazonaws.com\","                         >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"us-gov\"]"                                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://sts.amazonaws.com\","                                        >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"credentialScope\": {"                                                      >> _endpoints.json.local.ssl
    echo "            \"region\": \"us-east-1\""                                               >> _endpoints.json.local.ssl
    echo "        }"                                                                           >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"s3\":["                                                                          >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://s3.amazonaws.com\","                                      >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"oneOf\", [\"us-east-1\", null]]"                              >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"credentialScope\": {"                                                      >> _endpoints.json.local.ssl
    echo "            \"region\": \"us-east-1\""                                               >> _endpoints.json.local.ssl
    echo "        }"                                                                           >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://objectstorage.{region}.$EUCA_DNS_REGION_DOMAIN//\","      >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${EUCA_DNS_REGION%-*}-\"]"                    >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"signatureVersion\": \"s3\""                                                >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.{region}.amazonaws.com.cn\","                   >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"signatureVersion\": \"s3v4\""                                              >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}-{region}.amazonaws.com\","                      >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"oneOf\", [\"us-east-1\", \"ap-northeast-1\", \"sa-east-1\","  >> _endpoints.json.local.ssl
    echo "                             \"ap-southeast-1\", \"ap-southeast-2\", \"us-west-2\"," >> _endpoints.json.local.ssl
    echo "                             \"us-west-1\", \"eu-west-1\", \"us-gov-west-1\","       >> _endpoints.json.local.ssl
    echo "                             \"fips-us-gov-west-1\"]]"                               >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://{service}.{region}.amazonaws.com\","                      >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notEquals\", null]"                                           >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"signatureVersion\": \"s3v4\""                                              >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"rds\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://rds.amazonaws.com\","                                        >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"us-east-1\"]"                                     >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"route53\":["                                                                     >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://route53.amazonaws.com\","                                    >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notStartsWith\", \"cn-\"]"                                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"elasticmapreduce\":["                                                            >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://elasticmapreduce.cn-north-1.amazonaws.com.cn\","             >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://elasticmapreduce.eu-central-1.amazonaws.com\","              >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"eu-central-1\"]"                                  >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://elasticmapreduce.us-east-1.amazonaws.com\","                 >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"us-east-1\"]"                                     >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{region}.elasticmapreduce.amazonaws.com\","                  >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notEquals\", null]"                                           >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"sqs\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://queue.amazonaws.com\","                                      >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"us-east-1\"]"                                     >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{region}.queue.amazonaws.com.cn\","                          >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"cn-\"]"                                       >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    },"                                                                              >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://{region}.queue.amazonaws.com\","                             >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notEquals\", null]"                                           >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"importexport\": ["                                                               >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://importexport.amazonaws.com\","                               >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notStartsWith\", \"cn-\"]"                                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"cloudfront\":["                                                                  >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://cloudfront.amazonaws.com\","                                 >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"notStartsWith\", \"cn-\"]"                                    >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"credentialScope\": {"                                                      >> _endpoints.json.local.ssl
    echo "            \"region\": \"us-east-1\""                                               >> _endpoints.json.local.ssl
    echo "        }"                                                                           >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"dynamodb\": ["                                                                   >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\": \"http://localhost:8000\","                                           >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"equals\", \"local\"]"                                         >> _endpoints.json.local.ssl
    echo "      ],"                                                                            >> _endpoints.json.local.ssl
    echo "      \"properties\": {"                                                             >> _endpoints.json.local.ssl
    echo "        \"credentialScope\": {"                                                      >> _endpoints.json.local.ssl
    echo "            \"region\": \"us-east-1\","                                              >> _endpoints.json.local.ssl
    echo "            \"service\": \"dynamodb\""                                               >> _endpoints.json.local.ssl
    echo "        }"                                                                           >> _endpoints.json.local.ssl
    echo "      }"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ]"                                                                                 >> _endpoints.json.local.ssl
    echo "}"                                                                                   >> _endpoints.json.local.ssl
    echo "#"
    echo "# mv _endpoints.json _endpoints.json.orig"
    echo "#" 
    echo "# ln -s _endoints.json.ssl _endpoints.json"

    popd &> /dev/null

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Default AWS credentials"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "mkdir -p ~/.aws"
echo 
echo "cat << EOF > ~/.aws/config"
echo "#"
echo "# AWS Config file"
echo "#"
echo
echo "[default]"
echo "region = $EUCA_DNS_REGION"
echo "output = text"
echo "EOF"
echo
echo "cat << EOF > ~/.aws/credentials"
echo "#"
echo "# AWS Credentials file"
echo "#"
echo
echo "[default]"
echo "aws_access_key_id = $AWS_ACCESS_KEY"
echo "aws_secret_access_key = $AWS_SECRET_KEY"
echo "EOF"
echo
echo "chmod -R og-rwx ~/.aws"

run 50

if [ $choice = y ]; then
    echo
    echo "# mkdir -p ~/.aws"
    mkdir -p ~/.aws
    pause

    echo "# cat << EOF > ~/.aws/config"
    echo "> #"
    echo "> # AWS Config file"
    echo "> #"
    echo ">"
    echo "> [default]"
    echo "> region = $EUCA_DNS_REGION"
    echo "> output = text"
    echo "> EOF"
    echo "#"                          > ~/.aws/config
    echo "# AWS Config file"         >> ~/.aws/config
    echo "#"                         >> ~/.aws/config
    echo                             >> ~/.aws/config
    echo "[default]"                 >> ~/.aws/config
    echo "region = $EUCA_DNS_REGION" >> ~/.aws/config
    echo "output = text"             >> ~/.aws/config
    pause

    echo "# cat << EOF > ~/.aws/credentials"
    echo "> #"
    echo "> # AWS Credentials file"
    echo "> #"
    echo ">"
    echo "> [default]"
    echo "> aws_access_key_id = $AWS_ACCESS_KEY"
    echo "> aws_secret_access_key = $AWS_SECRET_KEY"
    echo "> EOF"
    echo "#"                                        > ~/.aws/credentials
    echo "# AWS Credentials file"                  >> ~/.aws/credentials
    echo "#"                                       >> ~/.aws/credentials
    echo                                           >> ~/.aws/credentials
    echo "[default]"                               >> ~/.aws/credentials
    echo "aws_access_key_id = $AWS_ACCESS_KEY"     >> ~/.aws/credentials
    echo "aws_secret_access_key = $AWS_SECRET_KEY" >> ~/.aws/credentials
    pause

    echo "# chmod -R og-rwx ~/.aws"
    chmod -R og-rwx ~/.aws

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Test AWS CLI"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "aws ec2 describe-key-pairs"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws ec2 describe-key-pairs"
    aws ec2 describe-key-pairs

    next 50
fi

end=$(date +%s)

echo
echo "Eucalyptus AWS CLI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))"
