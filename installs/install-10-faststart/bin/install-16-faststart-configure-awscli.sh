#/bin/bash
#
# This script configures the AWSCLI to access the local Eucalyptus instance after a Faststart installation
# - This variant uses the Helion Eucalyptus Development Root Certification Authority
#
# This should be run after the Faststart Reverse Proxy configuration script
#
# This script assumes the reverse proxy configuration script has been run so Eucalyptus
# is accessible by HTTPS URLs on the standard port.
#

#  1. Initalize Environment

bindir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confdir=${bindir%/*}/conf
tmpdir=/var/tmp

step=0
speed_max=400
run_default=10
pause_default=2
next_default=5

interactive=1
speed=100
verbose=0
region=${AWS_DEFAULT_REGION#*@}
domain=$(sed -n -e 's/ec2-url = http.*:\/\/ec2\.[^.]*\.\([^:\/]*\).*$/\1/p' /etc/euca2ools/conf.d/$region.ini 2>/dev/null)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-v]"
    echo "             [-r region] [-d domain]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -v         verbose"
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

while getopts Isfvr:d:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    v)  verbose=1;;
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

# Prevent certain environment variables from breaking commands
unset AWS_DEFAULT_PROFILE
unset AWS_CREDENTIAL_FILE
unset EC2_PRIVATE_KEY
unset EC2_CERT


#  5. Execute Procedure

start=$(date +%s)

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
echo
echo "pip install --upgrade pip"

if hash pip 2>/dev/null; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# yum install -y python-pip"
        yum install -y python-pip
        pause

        echo "# pip install --upgrade pip"
        pip install --upgrade pip

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Install AWSCLI"
echo "    - We install a specific version of AWSCLI so the modifications to the"
echo "      endpoints.json configuration file made below are consistent"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pip install awscli==1.11.10"

if hash aws 2>/dev/null; then
    echo
    tput rev
    echo "Already Installed!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# pip install awscli==1.11.10"
        pip install awscli==1.11.10

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Fix console dependencies broken by pip"
echo "    - pip overwrites a version of a python module required by eucaconsole"
echo "      so we must revert back to this required version"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pip uninstall -y python-dateutil"
echo "yum reinstall -y python-dateutil"

run 50

if [ $choice = y ]; then
    echo
    echo "# pip uninstall -y python-dateutil"
    pip uninstall -y python-dateutil
    echo "# yum reinstall -y python-dateutil"
    yum reinstall -y python-dateutil

    next 50
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure AWSCLI Command Completion"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cat << EOF >> /etc/profile.d/aws.sh"
echo "complete -C '/usr/bin/aws_completer' aws"
echo "EOF"
echo
echo "source /etc/profile.d/aws.sh"

if [ -r /etc/profile.d/aws.sh ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# cat << EOF >> /etc/profile.d/aws.sh"
        echo "> complete -C '/usr/bin/aws_completer' aws"
        echo "> EOF"
        echo complete -C '/usr/bin/aws_completer' aws > /etc/profile.d/aws.sh

        echo "# source /etc/profile.d/aws.sh"
        source /etc/profile.d/aws.sh

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure AWSCLI to trust local Certificate Authority"
echo "    - We will use the Helion Eucalyptus Development Root Certification Authority"
echo "      to sign SSL certificates"
echo "    - We must add this CA cert to the trusted root certificate authorities"
echo "      used by botocore on all clients where AWSCLI is run"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pushd /usr/lib/python2.7/site-packages/botocore/vendored/requests"
echo
if [ ! -r cacert.pem.local ]; then
    echo "cp -a cacert.pem cacert.pem.local"
    echo
fi
echo "cat << EOF >> cacert.pem.local"
echo
echo "# Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority"
echo "# Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority"
echo "# Label: "Helion Eucalyptus Development Root Certification Authority""
echo "# Serial: 0"
echo "# MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12"
echo "# SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B"
echo "# SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd"
echo "-----BEGIN CERTIFICATE-----"
echo "MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx"
echo "EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP"
echo "SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl"
echo "bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg"
echo "Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y"
echo "NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p"
echo "YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk"
echo "BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI"
echo "ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g"
echo "QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV"
echo "BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku"
echo "Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh"
echo "lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd"
echo "Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL"
echo "GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT"
echo "47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn"
echo "23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc"
echo "HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9"
echo "WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb"
echo "qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1"
echo "ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU"
echo "NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT"
echo "E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB"
echo "BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA"
echo "OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa"
echo "jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub"
echo "sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d"
echo "vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI"
echo "kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap"
echo "oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX"
echo "wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD"
echo "zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8"
echo "qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M"
echo "Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I"
echo "Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI="
echo "-----END CERTIFICATE-----"
echo "EOF"
echo
if [ ! -r cacert.pem.orig ]; then
    echo "mv cacert.pem cacert.pem.orig"
    echo
fi
if [ -r cacert.pem.local ]; then
    echo "rm -f cacert.pem"
    echo "ln -s cacert.pem.local cacert.pem"
    echo
fi
echo "popd"

if grep -q -s "95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12" /usr/lib/python2.7/site-packages/botocore/vendored/requests/cacert.pem.local; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# pushd /usr/lib/python2.7/site-packages/botocore/vendored/requests"
        pushd /usr/lib/python2.7/site-packages/botocore/vendored/requests &> /dev/null
        pause

        if [ ! -r cacert.pem.local ]; then
            echo "# cp -a cacert.pem cacert.pem.local"
            cp -a cacert.pem cacert.pem.local
            pause
        fi

        echo "# cat << EOF >> cacert.pem.local"
        echo ">"
        echo "> # Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority"
        echo "> # Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority"
        echo "> # Label: \"Helion Eucalyptus Development Root Certification Authority\""
        echo "> # Serial: 0"
        echo "> # MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12"
        echo "> # SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B"
        echo "> # SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd"
        echo "> -----BEGIN CERTIFICATE-----"
        echo "> MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx"
        echo "> EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP"
        echo "> SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl"
        echo "> bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg"
        echo "> Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y"
        echo "> NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p"
        echo "> YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk"
        echo "> BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI"
        echo "> ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g"
        echo "> QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV"
        echo "> BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku"
        echo "> Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh"
        echo "> lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd"
        echo "> Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL"
        echo "> GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT"
        echo "> 47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn"
        echo "> 23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc"
        echo "> HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9"
        echo "> WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb"
        echo "> qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1"
        echo "> ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU"
        echo "> NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT"
        echo "> E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB"
        echo "> BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA"
        echo "> OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa"
        echo "> jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub"
        echo "> sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d"
        echo "> vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI"
        echo "> kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap"
        echo "> oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX"
        echo "> wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD"
        echo "> zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8"
        echo "> qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M"
        echo "> Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I"
        echo "> Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI="
        echo "> -----END CERTIFICATE-----"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo                                                                    >> cacert.pem.local
        echo "# Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority"  >> cacert.pem.local
        echo "# Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority" >> cacert.pem.local
        echo "# Label: \"Helion Eucalyptus Development Root Certification Authority\"" >> cacert.pem.local
        echo "# Serial: 0"                                                      >> cacert.pem.local
        echo "# MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12"                                                    >> cacert.pem.local
        echo "# SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B"                                       >> cacert.pem.local
        echo "# SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd" >> cacert.pem.local
        echo "-----BEGIN CERTIFICATE-----"                                      >> cacert.pem.local
        echo "MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx" >> cacert.pem.local
        echo "EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP" >> cacert.pem.local
        echo "SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl" >> cacert.pem.local
        echo "bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg" >> cacert.pem.local
        echo "Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y" >> cacert.pem.local
        echo "NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p" >> cacert.pem.local
        echo "YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk" >> cacert.pem.local
        echo "BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI" >> cacert.pem.local
        echo "ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g" >> cacert.pem.local
        echo "QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV" >> cacert.pem.local
        echo "BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku" >> cacert.pem.local
        echo "Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh" >> cacert.pem.local
        echo "lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd" >> cacert.pem.local
        echo "Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL" >> cacert.pem.local
        echo "GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT" >> cacert.pem.local
        echo "47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn" >> cacert.pem.local
        echo "23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc" >> cacert.pem.local
        echo "HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9" >> cacert.pem.local
        echo "WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb" >> cacert.pem.local
        echo "qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1" >> cacert.pem.local
        echo "ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU" >> cacert.pem.local
        echo "NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT" >> cacert.pem.local
        echo "E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB" >> cacert.pem.local
        echo "BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA" >> cacert.pem.local
        echo "OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa" >> cacert.pem.local
        echo "jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub" >> cacert.pem.local
        echo "sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d" >> cacert.pem.local
        echo "vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI" >> cacert.pem.local
        echo "kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap" >> cacert.pem.local
        echo "oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX" >> cacert.pem.local
        echo "wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD" >> cacert.pem.local
        echo "zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8" >> cacert.pem.local
        echo "qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M" >> cacert.pem.local
        echo "Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I" >> cacert.pem.local
        echo "Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI="                     >> cacert.pem.local
        echo "-----END CERTIFICATE-----"                                        >> cacert.pem.local
        pause

        if [ ! -r cacert.pem.orig ]; then
            echo "# mv cacert.pem cacert.pem.orig"
            mv cacert.pem cacert.pem.orig
            echo "#"
        fi
        if [ -r cacert.pem.local ]; then
            echo "# rm -f cacert.pem"
            rm -f cacert.pem
            echo "# ln -s cacert.pem.local cacert.pem"
            ln -s cacert.pem.local cacert.pem
            echo "#"
        fi

        echo "# popd"
        popd &> /dev/null

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure AWSCLI to support local Eucalyptus region"
echo "    - This creates a modified version of the endpoints.json file which the"
echo "      botocore Python module within AWSCLI uses to configure AWS endpoints,"
echo "      adding the new local Eucalyptus region endpoints"
echo "    - We then rename the original endpoints.json file with the .orig extension,"
echo "      then create a symlink with the original name pointing to our version"
echo "    - The files created are too long to display - view it in the location"
echo "      shown below. You can compare with the original to see what changes have"
echo "      been made."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cd /usr/lib/python2.7/site-packages/botocore/data"
echo "sed -e :a -e '$d;N;2,3ba' -e 'P;D' endpoints.json > endpoints.json.local.ssl"
echo "cat << EOF >> endpoints.json.local.ssl"
echo "    .... too long to list ...."
echo "EOF"
echo
echo "mv endpoints.json endpoints.json.orig"
echo
echo "ln -s endoints.json.local.ssl endpoints.json"

if grep -q -s "$region" /usr/lib/python2.7/site-packages/botocore/data/endpoints.json.local.ssl; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "pushd /usr/lib/python2.7/site-packages/botocore/data"
        pushd /usr/lib/python2.7/site-packages/botocore/data &> /dev/null
        echo "#"
        echo "# sed -e :a -e '$d;N;2,3ba' -e 'P;D' endpoints.json > endpoints.json.local.ssl"
        sed -e :a -e '$d;N;2,3ba' -e 'P;D' endpoints.json > endpoints.json.local.ssl

        echo "#"
        echo "# cat << EOF >> endpoints.json.local.ssl"
        echo ">     ... too long to list ..."
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "    },"                                                                            >> endpoints.json.local.ssl
        echo "    {"                                                                             >> endpoints.json.local.ssl
        echo "      \"partition\": \"$region\","                                                 >> endpoints.json.local.ssl
        echo "      \"partitionName\": \"$(echo ${region//-/ } | awk '{print toupper($0)}')\","  >> endpoints.json.local.ssl
        echo "      \"dnsSuffix\": \"$domain\","                                                 >> endpoints.json.local.ssl
        echo "      \"regionRegex\": \"^${region//-/\\\\-}$\","                                  >> endpoints.json.local.ssl
        echo "      \"defaults\": {"                                                             >> endpoints.json.local.ssl
        echo "        \"hostname\": \"{service}.{region}.{dnsSuffix}\","                         >> endpoints.json.local.ssl
        echo "        \"protocols\": ["                                                          >> endpoints.json.local.ssl
        echo "          \"https\""                                                               >> endpoints.json.local.ssl
        echo "        ],"                                                                        >> endpoints.json.local.ssl
        echo "        \"signatureVersions\": ["                                                  >> endpoints.json.local.ssl
        echo "          \"v4\""                                                                  >> endpoints.json.local.ssl
        echo "        ]"                                                                         >> endpoints.json.local.ssl
        echo "      },"                                                                          >> endpoints.json.local.ssl
        echo "      \"regions\": {"                                                              >> endpoints.json.local.ssl
        echo "        \"$region\": {"                                                            >> endpoints.json.local.ssl
        echo "          \"description\": \"$(echo ${region//-/ } | awk '{print toupper($0)}')\"" >> endpoints.json.local.ssl
        echo "        }"                                                                         >> endpoints.json.local.ssl
        echo "      },"                                                                          >> endpoints.json.local.ssl
        echo "      \"services\": {"                                                             >> endpoints.json.local.ssl
        echo "        \"autoscaling\": {"                                                        >> endpoints.json.local.ssl
        echo "          \"defaults\": {"                                                         >> endpoints.json.local.ssl
        echo "            \"protocols\": ["                                                      >> endpoints.json.local.ssl
        echo "              \"http\","                                                           >> endpoints.json.local.ssl
        echo "              \"https\""                                                           >> endpoints.json.local.ssl
        echo "            ]"                                                                     >> endpoints.json.local.ssl
        echo "          },"                                                                      >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"cloudformation\": {"                                                     >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"ec2\": {"                                                                >> endpoints.json.local.ssl
        echo "          \"defaults\": {"                                                         >> endpoints.json.local.ssl
        echo "            \"protocols\": ["                                                      >> endpoints.json.local.ssl
        echo "              \"http\","                                                           >> endpoints.json.local.ssl
        echo "              \"https\""                                                           >> endpoints.json.local.ssl
        echo "            ]"                                                                     >> endpoints.json.local.ssl
        echo "          },"                                                                      >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"elasticloadbalancing\": {"                                               >> endpoints.json.local.ssl
        echo "          \"defaults\": {"                                                         >> endpoints.json.local.ssl
        echo "            \"protocols\": ["                                                      >> endpoints.json.local.ssl
        echo "              \"http\","                                                           >> endpoints.json.local.ssl
        echo "              \"https\""                                                           >> endpoints.json.local.ssl
        echo "            ]"                                                                     >> endpoints.json.local.ssl
        echo "          },"                                                                      >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"iam\": {"                                                                >> endpoints.json.local.ssl
        echo "          \"partitionEndpoint\": \"${region%-*}-global\","                         >> endpoints.json.local.ssl
        echo "          \"isRegionalized\": false,"                                              >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"${region%-*}-global\": {"                                            >> endpoints.json.local.ssl
        echo "              \"hostname\": \"iam.$region.$domain\","                              >> endpoints.json.local.ssl
        echo "              \"credentialScope\": {"                                              >> endpoints.json.local.ssl
        echo "                \"region\": \"$region\""                                           >> endpoints.json.local.ssl
        echo "              }"                                                                   >> endpoints.json.local.ssl
        echo "            }"                                                                     >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"monitoring\": {"                                                         >> endpoints.json.local.ssl
        echo "          \"defaults\": {"                                                         >> endpoints.json.local.ssl
        echo "            \"protocols\": ["                                                      >> endpoints.json.local.ssl
        echo "              \"http\","                                                           >> endpoints.json.local.ssl
        echo "              \"https\""                                                           >> endpoints.json.local.ssl
        echo "            ]"                                                                     >> endpoints.json.local.ssl
        echo "          },"                                                                      >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"s3\": {"                                                                 >> endpoints.json.local.ssl
        echo "          \"defaults\": {"                                                         >> endpoints.json.local.ssl
        echo "            \"protocols\": ["                                                      >> endpoints.json.local.ssl
        echo "              \"http\","                                                           >> endpoints.json.local.ssl
        echo "              \"https\""                                                           >> endpoints.json.local.ssl
        echo "            ],"                                                                    >> endpoints.json.local.ssl
        echo "            \"signatureVersions\": ["                                              >> endpoints.json.local.ssl
        echo "              \"s3\""                                                              >> endpoints.json.local.ssl
        echo "            ]"                                                                     >> endpoints.json.local.ssl
        echo "          },"                                                                      >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {"                                                        >> endpoints.json.local.ssl
        echo "              \"hostname\": \"s3.$region.$domain//\""                              >> endpoints.json.local.ssl
        echo "            }"                                                                     >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        },"                                                                        >> endpoints.json.local.ssl
        echo "        \"sts\": {"                                                                >> endpoints.json.local.ssl
        echo "          \"endpoints\": {"                                                        >> endpoints.json.local.ssl
        echo "            \"$region\": {}"                                                       >> endpoints.json.local.ssl
        echo "          }"                                                                       >> endpoints.json.local.ssl
        echo "        }"                                                                         >> endpoints.json.local.ssl
        echo "      }"                                                                           >> endpoints.json.local.ssl
        echo "    }"                                                                             >> endpoints.json.local.ssl
        echo "  ]"                                                                               >> endpoints.json.local.ssl
        echo "}"                                                                                 >> endpoints.json.local.ssl
        pause

        echo "# mv endpoints.json endpoints.json.orig"
        mv endpoints.json endpoints.json.orig
        echo "#"
        echo "# ln -s endpoints.json.local.ssl endpoints.json"
        ln -s endpoints.json.local.ssl endpoints.json
        echo "#"
        echo "# popd"
        popd &> /dev/null

        next
    fi
fi


((++step))
access_key=$(sed -n -e 's/AWSAccessKeyId=//p' ~/.creds/$region/eucalyptus/admin/iamrc)
secret_key=$(sed -n -e 's/AWSSecretKey=//p' ~/.creds/$region/eucalyptus/admin/iamrc)

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
echo "region = $region"
echo "output = text"
echo
echo "[profile $region-admin]"
echo "region = $region"
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
echo "[$region-admin]"
echo "aws_access_key_id = $access_key"
echo "aws_secret_access_key = $secret_key"
echo
echo "EOF"
echo
echo "chmod -R og-rwx ~/.aws"

if grep -q -s "$region-admin" ~/.aws/credentials; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
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
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> [profile-$region-admin]"
        echo "> region = $region"
        echo "> output = text"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                        > ~/.aws/config
        echo "# AWS Config file"       >> ~/.aws/config
        echo "#"                       >> ~/.aws/config
        echo                           >> ~/.aws/config
        echo "[default]"               >> ~/.aws/config
        echo "region = $region"        >> ~/.aws/config
        echo "output = text"           >> ~/.aws/config
        echo                           >> ~/.aws/config
        echo "[profile $region-admin]" >> ~/.aws/config
        echo "region = $region"        >> ~/.aws/config
        echo "output = text"           >> ~/.aws/config
        echo                           >> ~/.aws/config
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
        echo "> [$region-admin]"
        echo "> aws_access_key_id = $access_key"
        echo "> aws_secret_access_key = $secret_key"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "#"                                    > ~/.aws/credentials
        echo "# AWS Credentials file"              >> ~/.aws/credentials
        echo "#"                                   >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        echo "[default]"                           >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        echo "[$region-admin]"                     >> ~/.aws/credentials
        echo "aws_access_key_id = $access_key"     >> ~/.aws/credentials
        echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
        echo                                       >> ~/.aws/credentials
        pause

        echo "# chmod -R og-rwx ~/.aws"
        chmod -R og-rwx ~/.aws

        next 50
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


((++step))
if [ $verbose = 1 ]; then
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Confirm AWSCLI"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "aws ec2 describe-key-pairs"
    echo
    echo "aws ec2 describe-key-pairs --profile default"
    echo
    echo "aws ec2 describe-key-pairs --profile $region-admin"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-key-pairs"
        aws ec2 describe-key-pairs
        echo "#"
        echo "# aws ec2 describe-key-pairs --profile default"
        aws ec2 describe-key-pairs --profile default
        echo "#"
        echo "# aws ec2 describe-key-pairs --profile $region-admin"
        aws ec2 describe-key-pairs --profile $region-admin

        next 50
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus AWSCLI configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus AWSCLI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
