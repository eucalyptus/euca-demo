#/bin/bash
#
# This script configures the AWS CLI to access the local Eucalyptus instance after a Faststart installation
# - This variant uses the HP Cloud Certification Authority Hierarchy
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
echo "$(printf '%2d' $step). Install AWS CLI"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pip install awscli"

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
        echo "# pip install awscli"
        pip install awscli

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
echo "$(printf '%2d' $step). Configure AWS CLI Command Completion"
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
echo "$(printf '%2d' $step). Configure AWS CLI to trust local Certificate Authority"
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
echo "    - We must add this CA cert to the trusted root certificate authorities"
echo "      used by botocore on all clients where AWS CLI is run"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
echo
if [ ! -r cacert.pem.local ]; then
    echo "cp -a cacert.pem cacert.pem.local"
    echo
fi
echo "cat << EOF >> cacert.pem.local"
echo
echo "# Issuer: CN=cloudca.hpcloud.ms"
echo "# Subject: CN=cloudca.hpcloud.ms"
echo "# Label: "cloudca.hpcloud.ms""
echo "# Serial: 6F58C6D22397309F4CDD121BB52ADBE6"
echo "# MD5 Fingerprint: 8F:41:5C:6C:29:D9:EA:DD:FE:A4:4C:8D:90:17:73:C1"
echo "# SHA1 Fingerprint: 67:0E:8C:B9:44:BD:D6:AB:E4:1A:55:EF:81:8F:6F:C6:19:70:6F:EA"
echo "# SHA256 Fingerprint: 7E:D5:FA:A6:67:97:D4:5B:57:6C:1C:CA:FC:26:29:C9:A6:4C:53:CD:4E:83:13:01:C9:58:C2:45:79:0B:53:96"
echo "-----BEGIN CERTIFICATE-----"
echo "MIIDFTCCAf2gAwIBAgIQb1jG0iOXMJ9M3RIbtSrb5jANBgkqhkiG9w0BAQsFADAd"
echo "MRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjE2MTI1NzA4WhcN"
echo "MzIwMjE2MTMwNzA4WjAdMRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwggEi"
echo "MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCZSFy2YTOnujqh0Wemevdrk9kH"
echo "6sQdidVntwkcvMEe+kzLEGiZrbY7pmoqreFFlDWhYiBPgAtrSjKl89NTd/9cGm3/"
echo "42n4WcoUE65dH8rSn7mAzLZ2WKkICCEeKor7njiSXIo00z4vavujBXWkDImhzRwB"
echo "sU6Xx7uhgMpQt8tTKG3h5NEEknrFjA+Xg7WkQJ5eees8LtO4+S1ESNr9Txi5ZnJ0"
echo "b4eyOnPGxdw1t/AlAtN1BpBW6W37stWd0LiHP+CRlwkA2GETSoQH1Iz9L3hy/qr+"
echo "Na5NNgDOd6ev0DH1cL93a4NUe1xTcC06r125KMjBQVdC516QG81cHtr4L/uFAgMB"
echo "AAGjUTBPMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQJ"
echo "BIieQP10WQIwDbaKmhvnUHmetzAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0B"
echo "AQsFAAOCAQEAMyT7bk+MGr+g0E028d14TauuAqdGBbZ6rX9+8wtOgIY1k4ApP4Xi"
echo "cfgcUl+7uZcI1RKweD04u1FZXOUjf8apGzLl9XlC65z1YrAJwTNN/AmcyYXI3iDO"
echo "u0KezyVA5TSh03jJgHhGlPH6HvG44D6xP9KVs4n1X+QQmW/xELsluxb+//u2+oP1"
echo "XSsj13WU1/5eZec3pedt0IJLVrOzwEV219Xvp4DIPF3chRKaT/CM2yLF7FJ7yICf"
echo "vvVIg1ZJ2VcBCP6sxkVb8BfbIyclB8SG8FKbNl5xm2TxVjriKd3V/xFkaqh1y3Mj"
echo "sEtTkVwohlqtn77wSYTvYAZB+UzqypbX9Q=="
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

if grep -q -s "8F:41:5C:6C:29:D9:EA:DD:FE:A4:4C:8D:90:17:73:C1" /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
        pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
        pause

        if [ ! -r cacert.pem.local ]; then
            echo "# cp -a cacert.pem cacert.pem.local"
            cp -a cacert.pem cacert.pem.local
            pause
        fi

        echo "# cat << EOF >> cacert.pem.local"
        echo ">"
        echo "> # Issuer: CN=cloudca.hpcloud.ms"
        echo "> # Subject: CN=cloudca.hpcloud.ms"
        echo "> # Label: "cloudca.hpcloud.ms""
        echo "> # Serial: 6F58C6D22397309F4CDD121BB52ADBE6"
        echo "> # MD5 Fingerprint: 8F:41:5C:6C:29:D9:EA:DD:FE:A4:4C:8D:90:17:73:C1"
        echo "> # SHA1 Fingerprint: 67:0E:8C:B9:44:BD:D6:AB:E4:1A:55:EF:81:8F:6F:C6:19:70:6F:EA"
        echo "> # SHA256 Fingerprint: 7E:D5:FA:A6:67:97:D4:5B:57:6C:1C:CA:FC:26:29:C9:A6:4C:53:CD:4E:83:13:01:C9:58:C2:45:79:0B:53:96"
        echo "> -----BEGIN CERTIFICATE-----"
        echo "> MIIDFTCCAf2gAwIBAgIQb1jG0iOXMJ9M3RIbtSrb5jANBgkqhkiG9w0BAQsFADAd"
        echo "> MRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjE2MTI1NzA4WhcN"
        echo "> MzIwMjE2MTMwNzA4WjAdMRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwggEi"
        echo "> MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCZSFy2YTOnujqh0Wemevdrk9kH"
        echo "> 6sQdidVntwkcvMEe+kzLEGiZrbY7pmoqreFFlDWhYiBPgAtrSjKl89NTd/9cGm3/"
        echo "> 42n4WcoUE65dH8rSn7mAzLZ2WKkICCEeKor7njiSXIo00z4vavujBXWkDImhzRwB"
        echo "> sU6Xx7uhgMpQt8tTKG3h5NEEknrFjA+Xg7WkQJ5eees8LtO4+S1ESNr9Txi5ZnJ0"
        echo "> b4eyOnPGxdw1t/AlAtN1BpBW6W37stWd0LiHP+CRlwkA2GETSoQH1Iz9L3hy/qr+"
        echo "> Na5NNgDOd6ev0DH1cL93a4NUe1xTcC06r125KMjBQVdC516QG81cHtr4L/uFAgMB"
        echo "> AAGjUTBPMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQJ"
        echo "> BIieQP10WQIwDbaKmhvnUHmetzAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0B"
        echo "> AQsFAAOCAQEAMyT7bk+MGr+g0E028d14TauuAqdGBbZ6rX9+8wtOgIY1k4ApP4Xi"
        echo "> cfgcUl+7uZcI1RKweD04u1FZXOUjf8apGzLl9XlC65z1YrAJwTNN/AmcyYXI3iDO"
        echo "> u0KezyVA5TSh03jJgHhGlPH6HvG44D6xP9KVs4n1X+QQmW/xELsluxb+//u2+oP1"
        echo "> XSsj13WU1/5eZec3pedt0IJLVrOzwEV219Xvp4DIPF3chRKaT/CM2yLF7FJ7yICf"
        echo "> vvVIg1ZJ2VcBCP6sxkVb8BfbIyclB8SG8FKbNl5xm2TxVjriKd3V/xFkaqh1y3Mj"
        echo "> sEtTkVwohlqtn77wSYTvYAZB+UzqypbX9Q=="
        echo "> -----END CERTIFICATE-----"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo                                                                    >> cacert.pem
        echo "# Issuer: CN=cloudca.hpcloud.ms"                                  >> cacert.pem
        echo "# Subject: CN=cloudca.hpcloud.ms"                                 >> cacert.pem
        echo "# Label: "cloudca.hpcloud.ms""                                    >> cacert.pem
        echo "# Serial: 6F58C6D22397309F4CDD121BB52ADBE6"                       >> cacert.pem
        echo "# MD5 Fingerprint: 8F:41:5C:6C:29:D9:EA:DD:FE:A4:4C:8D:90:17:73:C1" >> cacert.pem
        echo "# SHA1 Fingerprint: 67:0E:8C:B9:44:BD:D6:AB:E4:1A:55:EF:81:8F:6F:C6:19:70:6F:EA" >> cacert.pem
        echo "# SHA256 Fingerprint: 7E:D5:FA:A6:67:97:D4:5B:57:6C:1C:CA:FC:26:29:C9:A6:4C:53:CD:4E:83:13:01:C9:58:C2:45:79:0B:53:96" >> cacert.pem
        echo "-----BEGIN CERTIFICATE-----"                                      >> cacert.pem
        echo "MIIDFTCCAf2gAwIBAgIQb1jG0iOXMJ9M3RIbtSrb5jANBgkqhkiG9w0BAQsFADAd" >> cacert.pem
        echo "MRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjE2MTI1NzA4WhcN" >> cacert.pem
        echo "MzIwMjE2MTMwNzA4WjAdMRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwggEi" >> cacert.pem
        echo "MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCZSFy2YTOnujqh0Wemevdrk9kH" >> cacert.pem
        echo "6sQdidVntwkcvMEe+kzLEGiZrbY7pmoqreFFlDWhYiBPgAtrSjKl89NTd/9cGm3/" >> cacert.pem
        echo "42n4WcoUE65dH8rSn7mAzLZ2WKkICCEeKor7njiSXIo00z4vavujBXWkDImhzRwB" >> cacert.pem
        echo "sU6Xx7uhgMpQt8tTKG3h5NEEknrFjA+Xg7WkQJ5eees8LtO4+S1ESNr9Txi5ZnJ0" >> cacert.pem
        echo "b4eyOnPGxdw1t/AlAtN1BpBW6W37stWd0LiHP+CRlwkA2GETSoQH1Iz9L3hy/qr+" >> cacert.pem
        echo "Na5NNgDOd6ev0DH1cL93a4NUe1xTcC06r125KMjBQVdC516QG81cHtr4L/uFAgMB" >> cacert.pem
        echo "AAGjUTBPMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQJ" >> cacert.pem
        echo "BIieQP10WQIwDbaKmhvnUHmetzAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0B" >> cacert.pem
        echo "AQsFAAOCAQEAMyT7bk+MGr+g0E028d14TauuAqdGBbZ6rX9+8wtOgIY1k4ApP4Xi" >> cacert.pem
        echo "cfgcUl+7uZcI1RKweD04u1FZXOUjf8apGzLl9XlC65z1YrAJwTNN/AmcyYXI3iDO" >> cacert.pem
        echo "u0KezyVA5TSh03jJgHhGlPH6HvG44D6xP9KVs4n1X+QQmW/xELsluxb+//u2+oP1" >> cacert.pem
        echo "XSsj13WU1/5eZec3pedt0IJLVrOzwEV219Xvp4DIPF3chRKaT/CM2yLF7FJ7yICf" >> cacert.pem
        echo "vvVIg1ZJ2VcBCP6sxkVb8BfbIyclB8SG8FKbNl5xm2TxVjriKd3V/xFkaqh1y3Mj" >> cacert.pem
        echo "sEtTkVwohlqtn77wSYTvYAZB+UzqypbX9Q=="                             >> cacert.pem
        echo "-----END CERTIFICATE-----"                                        >> cacert.pem
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
echo "$(printf '%2d' $step). Configure AWS CLI to trust local Certificate Authority"
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
echo "    - We must add this CA cert to the trusted root certificate authorities"
echo "      used by botocore on all clients where AWS CLI is run"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
echo
if [ ! -r cacert.pem.local ]; then
    echo "cp -a cacert.pem cacert.pem.local"
    echo
fi
echo "cat << EOF >> cacert.pem.local"
echo
echo "# Issuer: CN=cloudca.hpcloud.ms"
echo "# Subject: DC=ms, DC=hpcloud, CN=cloudpca"
echo "# Label: "cloudpca""
echo "# Serial: 13903ED9000000000007"
echo "# MD5 Fingerprint: DD:45:88:0B:59:38:B9:12:4B:66:CA:F3:76:58:F6:5A"
echo "# SHA1 Fingerprint: 6B:27:E1:D6:38:E6:15:BB:27:E3:27:61:31:69:31:BA:C5:93:44:D3"
echo "# SHA256 Fingerprint: E4:1F:88:0A:FF:CD:31:98:D9:1C:36:5F:56:57:5C:F8:CD:DE:FB:B1:AD:34:3F:94:0D:B2:A5:08:F8:91:F4:32"
echo "-----BEGIN CERTIFICATE-----"
echo "MIIEIzCCAwugAwIBAgIKE5A+2QAAAAAABzANBgkqhkiG9w0BAQsFADAdMRswGQYD"
echo "VQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjI0MTgwMjI3WhcNMjIwMjI0"
echo "MTgxMjI3WjBAMRIwEAYKCZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdo"
echo "cGNsb3VkMREwDwYDVQQDEwhjbG91ZHBjYTCCASIwDQYJKoZIhvcNAQEBBQADggEP"
echo "ADCCAQoCggEBAK3KkTBAfZggkD3/MQd16wZqC/Kp16J1EyWxO/7r0jWQkXEG56BY"
echo "51bfPjfrQuOxc8eayNHAUBDK4fULbW45LxgVWVfXvyRwSTm0lJ3F37wVBt4/U135"
echo "w0xCX4HvtZfrF8lKX0j7VzNTmyX2OmzkqMQ4MjQB1KkJ9Z9DpRHcICnxkbE1bY8Z"
echo "kaIjas0aERhS7FPLL7PKLb6iPmXkRq+R6axyMMDJ64VopaRg6WeUf793p+8r5G/a"
echo "3OlBk98mZHYILIqQpwol5BaZexzCGDatlxHjkayeInS4OYiDCYaTbeGWls0SWOy3"
echo "LtEQ2Tq2XkQG/w/XRzlFjrp9V++req1+iScCAwEAAaOCAUAwggE8MBAGCSsGAQQB"
echo "gjcVAQQDAgEAMB0GA1UdDgQWBBQWYUgFETm07vF4cSJnKOmer7DPRTAZBgkrBgEE"
echo "AYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB"
echo "/zAfBgNVHSMEGDAWgBQJBIieQP10WQIwDbaKmhvnUHmetzBRBgNVHR8ESjBIMEag"
echo "RKBChkBodHRwOi8vc2UtYXcyb3BzLWNybDAxLnVzd2VzdC5ocGNsb3VkLm5ldC9j"
echo "bG91ZGNhLmhwY2xvdWQubXMuY3JsMFwGCCsGAQUFBwEBBFAwTjBMBggrBgEFBQcw"
echo "AoZAaHR0cDovL3NlLWF3Mm9wcy1jcmwwMS51c3dlc3QuaHBjbG91ZC5uZXQvY2xv"
echo "dWRjYS5ocGNsb3VkLm1zLmNydDANBgkqhkiG9w0BAQsFAAOCAQEAaIK2+3OiCEtt"
echo "Jg7bxfyHoqMWW4Uwl1+F4jMfcuq50wsWWJNBuNb9XKrO+ov07XmfAFfb197C0Xcp"
echo "Z+27VMmNiZNURu3kMjzoYn2BiskicS0ntiPVpb46m9By2OCd8GFlPvRhcgwsnQRU"
echo "gn5Tc76Nn8zviPYxj7LY95ccVWZUdwguupS/dh6NqkWqHikt5faAe7QsykB9sLpp"
echo "N7qVuwnWb3Dwg0vtQj9nK8eYo9QWbV/XBMzf51t2XyzAFAmR7VXf5pwPtI46b+Qf"
echo "E7EKakEXn5DdfCDrF3Fw2OKHNHp6GOVBEHxawpcLLLGXCmZHUCcjr0vLynF8uSTF"
echo "HkIF3OYSeA=="
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

if grep -q -s "DD:45:88:0B:59:38:B9:12:4B:66:CA:F3:76:58:F6:5A" /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
        pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
        pause

        if [ ! -r cacert.pem.local ]; then
            echo "# cp -a cacert.pem cacert.pem.local"
            cp -a cacert.pem cacert.pem.local
            pause
        fi

        echo "# cat << EOF >> cacert.pem.local"
        echo ">"
        echo "> # Issuer: CN=cloudca.hpcloud.ms"
        echo "> # Subject: DC=ms, DC=hpcloud, CN=cloudpca"
        echo "> # Label: "cloudpca""
        echo "> # Serial: 13903ED9000000000007"
        echo "> # MD5 Fingerprint: DD:45:88:0B:59:38:B9:12:4B:66:CA:F3:76:58:F6:5A"
        echo "> # SHA1 Fingerprint: 6B:27:E1:D6:38:E6:15:BB:27:E3:27:61:31:69:31:BA:C5:93:44:D3"
        echo "> # SHA256 Fingerprint: E4:1F:88:0A:FF:CD:31:98:D9:1C:36:5F:56:57:5C:F8:CD:DE:FB:B1:AD:34:3F:94:0D:B2:A5:08:F8:91:F4:32"
        echo "> -----BEGIN CERTIFICATE-----"
        echo "> MIIEIzCCAwugAwIBAgIKE5A+2QAAAAAABzANBgkqhkiG9w0BAQsFADAdMRswGQYD"
        echo "> VQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjI0MTgwMjI3WhcNMjIwMjI0"
        echo "> MTgxMjI3WjBAMRIwEAYKCZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdo"
        echo "> cGNsb3VkMREwDwYDVQQDEwhjbG91ZHBjYTCCASIwDQYJKoZIhvcNAQEBBQADggEP"
        echo "> ADCCAQoCggEBAK3KkTBAfZggkD3/MQd16wZqC/Kp16J1EyWxO/7r0jWQkXEG56BY"
        echo "> 51bfPjfrQuOxc8eayNHAUBDK4fULbW45LxgVWVfXvyRwSTm0lJ3F37wVBt4/U135"
        echo "> w0xCX4HvtZfrF8lKX0j7VzNTmyX2OmzkqMQ4MjQB1KkJ9Z9DpRHcICnxkbE1bY8Z"
        echo "> kaIjas0aERhS7FPLL7PKLb6iPmXkRq+R6axyMMDJ64VopaRg6WeUf793p+8r5G/a"
        echo "> 3OlBk98mZHYILIqQpwol5BaZexzCGDatlxHjkayeInS4OYiDCYaTbeGWls0SWOy3"
        echo "> LtEQ2Tq2XkQG/w/XRzlFjrp9V++req1+iScCAwEAAaOCAUAwggE8MBAGCSsGAQQB"
        echo "> gjcVAQQDAgEAMB0GA1UdDgQWBBQWYUgFETm07vF4cSJnKOmer7DPRTAZBgkrBgEE"
        echo "> AYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB"
        echo "> /zAfBgNVHSMEGDAWgBQJBIieQP10WQIwDbaKmhvnUHmetzBRBgNVHR8ESjBIMEag"
        echo "> RKBChkBodHRwOi8vc2UtYXcyb3BzLWNybDAxLnVzd2VzdC5ocGNsb3VkLm5ldC9j"
        echo "> bG91ZGNhLmhwY2xvdWQubXMuY3JsMFwGCCsGAQUFBwEBBFAwTjBMBggrBgEFBQcw"
        echo "> AoZAaHR0cDovL3NlLWF3Mm9wcy1jcmwwMS51c3dlc3QuaHBjbG91ZC5uZXQvY2xv"
        echo "> dWRjYS5ocGNsb3VkLm1zLmNydDANBgkqhkiG9w0BAQsFAAOCAQEAaIK2+3OiCEtt"
        echo "> Jg7bxfyHoqMWW4Uwl1+F4jMfcuq50wsWWJNBuNb9XKrO+ov07XmfAFfb197C0Xcp"
        echo "> Z+27VMmNiZNURu3kMjzoYn2BiskicS0ntiPVpb46m9By2OCd8GFlPvRhcgwsnQRU"
        echo "> gn5Tc76Nn8zviPYxj7LY95ccVWZUdwguupS/dh6NqkWqHikt5faAe7QsykB9sLpp"
        echo "> N7qVuwnWb3Dwg0vtQj9nK8eYo9QWbV/XBMzf51t2XyzAFAmR7VXf5pwPtI46b+Qf"
        echo "> E7EKakEXn5DdfCDrF3Fw2OKHNHp6GOVBEHxawpcLLLGXCmZHUCcjr0vLynF8uSTF"
        echo "> HkIF3OYSeA=="
        echo "> -----END CERTIFICATE-----"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo                                                                    >> cacert.pem
        echo "# Issuer: CN=cloudca.hpcloud.ms"                                  >> cacert.pem
        echo "# Subject: DC=ms, DC=hpcloud, CN=cloudpca"                        >> cacert.pem
        echo "# Label: "cloudpca""                                              >> cacert.pem
        echo "# Serial: 13903ED9000000000007"                                   >> cacert.pem
        echo "# MD5 Fingerprint: DD:45:88:0B:59:38:B9:12:4B:66:CA:F3:76:58:F6:5A" >> cacert.pem
        echo "# SHA1 Fingerprint: 6B:27:E1:D6:38:E6:15:BB:27:E3:27:61:31:69:31:BA:C5:93:44:D3" >> cacert.pem
        echo "# SHA256 Fingerprint: E4:1F:88:0A:FF:CD:31:98:D9:1C:36:5F:56:57:5C:F8:CD:DE:FB:B1:AD:34:3F:94:0D:B2:A5:08:F8:91:F4:32" >> cacert.pem
        echo "-----BEGIN CERTIFICATE-----"                                      >> cacert.pem
        echo "MIIEIzCCAwugAwIBAgIKE5A+2QAAAAAABzANBgkqhkiG9w0BAQsFADAdMRswGQYD" >> cacert.pem
        echo "VQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjI0MTgwMjI3WhcNMjIwMjI0" >> cacert.pem
        echo "MTgxMjI3WjBAMRIwEAYKCZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdo" >> cacert.pem
        echo "cGNsb3VkMREwDwYDVQQDEwhjbG91ZHBjYTCCASIwDQYJKoZIhvcNAQEBBQADggEP" >> cacert.pem
        echo "ADCCAQoCggEBAK3KkTBAfZggkD3/MQd16wZqC/Kp16J1EyWxO/7r0jWQkXEG56BY" >> cacert.pem
        echo "51bfPjfrQuOxc8eayNHAUBDK4fULbW45LxgVWVfXvyRwSTm0lJ3F37wVBt4/U135" >> cacert.pem
        echo "w0xCX4HvtZfrF8lKX0j7VzNTmyX2OmzkqMQ4MjQB1KkJ9Z9DpRHcICnxkbE1bY8Z" >> cacert.pem
        echo "kaIjas0aERhS7FPLL7PKLb6iPmXkRq+R6axyMMDJ64VopaRg6WeUf793p+8r5G/a" >> cacert.pem
        echo "3OlBk98mZHYILIqQpwol5BaZexzCGDatlxHjkayeInS4OYiDCYaTbeGWls0SWOy3" >> cacert.pem
        echo "LtEQ2Tq2XkQG/w/XRzlFjrp9V++req1+iScCAwEAAaOCAUAwggE8MBAGCSsGAQQB" >> cacert.pem
        echo "gjcVAQQDAgEAMB0GA1UdDgQWBBQWYUgFETm07vF4cSJnKOmer7DPRTAZBgkrBgEE" >> cacert.pem
        echo "AYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB" >> cacert.pem
        echo "/zAfBgNVHSMEGDAWgBQJBIieQP10WQIwDbaKmhvnUHmetzBRBgNVHR8ESjBIMEag" >> cacert.pem
        echo "RKBChkBodHRwOi8vc2UtYXcyb3BzLWNybDAxLnVzd2VzdC5ocGNsb3VkLm5ldC9j" >> cacert.pem
        echo "bG91ZGNhLmhwY2xvdWQubXMuY3JsMFwGCCsGAQUFBwEBBFAwTjBMBggrBgEFBQcw" >> cacert.pem
        echo "AoZAaHR0cDovL3NlLWF3Mm9wcy1jcmwwMS51c3dlc3QuaHBjbG91ZC5uZXQvY2xv" >> cacert.pem
        echo "dWRjYS5ocGNsb3VkLm1zLmNydDANBgkqhkiG9w0BAQsFAAOCAQEAaIK2+3OiCEtt" >> cacert.pem
        echo "Jg7bxfyHoqMWW4Uwl1+F4jMfcuq50wsWWJNBuNb9XKrO+ov07XmfAFfb197C0Xcp" >> cacert.pem
        echo "Z+27VMmNiZNURu3kMjzoYn2BiskicS0ntiPVpb46m9By2OCd8GFlPvRhcgwsnQRU" >> cacert.pem
        echo "gn5Tc76Nn8zviPYxj7LY95ccVWZUdwguupS/dh6NqkWqHikt5faAe7QsykB9sLpp" >> cacert.pem
        echo "N7qVuwnWb3Dwg0vtQj9nK8eYo9QWbV/XBMzf51t2XyzAFAmR7VXf5pwPtI46b+Qf" >> cacert.pem
        echo "E7EKakEXn5DdfCDrF3Fw2OKHNHp6GOVBEHxawpcLLLGXCmZHUCcjr0vLynF8uSTF" >> cacert.pem
        echo "HkIF3OYSeA=="                                                     >> cacert.pem
        echo "-----END CERTIFICATE-----"                                        >> cacert.pem
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
echo "$(printf '%2d' $step). Configure AWS CLI to trust local Certificate Authority"
echo "    - We will use the HP Cloud Root Certification Authority, along with 2 more"
echo "      intermediate Certification Authorities to sign SSL certificates"
echo "    - We must add this CA cert to the trusted root certificate authorities"
echo "      used by botocore on all clients where AWS CLI is run"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
echo
if [ ! -r cacert.pem.local ]; then
    echo "cp -a cacert.pem cacert.pem.local"
    echo
fi
echo "cat << EOF >> cacert.pem.local"
echo
echo "# Issuer: DC=ms, DC=hpcloud, CN=cloudpca"
echo "# Subject: DC=ms, DC=hpcloud, CN=aw2cloudica03"
echo "# Label: "aw2cloudica03""
echo "# Serial: 1A391A3300000000000B"
echo "# MD5 Fingerprint: 95:A3:20:FD:C8:5C:D9:3A:E6:DD:6A:91:40:E2:3A:78"
echo "# SHA1 Fingerprint: B4:A0:1C:96:5F:75:A8:23:80:96:B2:A2:4F:32:20:22:5B:4A:62:0F"
echo "# SHA256 Fingerprint: 2C:B1:57:96:4D:38:BA:60:0C:F7:E5:7D:42:42:11:90:C7:97:94:BB:D3:9C:DA:FA:9E:88:71:8A:7A:0E:8C:6F"
echo "-----BEGIN CERTIFICATE-----"
echo "MIIEZDCCA0ygAwIBAgIKGjkaMwAAAAAACzANBgkqhkiG9w0BAQsFADBAMRIwEAYK"
echo "CZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdocGNsb3VkMREwDwYDVQQD"
echo "EwhjbG91ZHBjYTAeFw0xMjAyMjkwNDU1MjFaFw0xNzAyMjgwNTA1MjFaMEUxEjAQ"
echo "BgoJkiaJk/IsZAEZFgJtczEXMBUGCgmSJomT8ixkARkWB2hwY2xvdWQxFjAUBgNV"
echo "BAMTDWF3MmNsb3VkaWNhMDMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB"
echo "AQDYridWlpBFg3BJRGP+pbkflnlsvAhzpf+kIQ3NBWN+8PD0GB5LCMqe8VS0TvXk"
echo "1PWkJ0zop7d5gbxOb1QvTqvNtZZatEOg94lbox3YaN26TZnTIUBvx9ZQ/vwNvww1"
echo "P2kiS1mvd5lPBOFZDeUAXSJnhIC7NmCsHTaxAVPdvmh8gMlwRLH9H4S1S5a1f9iL"
echo "g3gGEbcntC1oXg2D5/QL8fdP66oFa+72wsGoz8k46FBviDVUB8SQ7NtMtHZZ6dN1"
echo "3U6Anc4nfRIJA8zqT9oJCUQpuG668sRw7ztZECcHTRsqWE9p7nImzgib39dYdD3i"
echo "Y3PngQzw4tSY/azFDK36IF0bAgMBAAGjggFZMIIBVTAQBgkrBgEEAYI3FQEEAwIB"
echo "ADAdBgNVHQ4EFgQUIsX2rnOI2dW38KM/QO6zvRtm1WgwGQYJKwYBBAGCNxQCBAwe"
echo "CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j"
echo "BBgwFoAUFmFIBRE5tO7xeHEiZyjpnq+wz0UwTgYDVR0fBEcwRTBDoEGgP4Y9aHR0"
echo "cDovL2F3MmNsb3VkY2EwMi51c3dlc3QuaHBjbG91ZC5tcy9DZXJ0RW5yb2xsL2Ns"
echo "b3VkcGNhLmNybDB4BggrBgEFBQcBAQRsMGowaAYIKwYBBQUHMAKGXGh0dHA6Ly9h"
echo "dzJjbG91ZGNhMDIudXN3ZXN0LmhwY2xvdWQubXMvQ2VydEVucm9sbC9BVzJDTE9V"
echo "RENBMDIudXN3ZXN0LmhwY2xvdWQubXNfY2xvdWRwY2EuY3J0MA0GCSqGSIb3DQEB"
echo "CwUAA4IBAQAF/iK35c0jssJBYz/NBvokg+Xd8raomRtObiuoN/myft5BRezqpQej"
echo "X9nipSsJP4rWl7jP7ZYDIYy2lAQVWNeXbeWGealbfRnCwt/h98pRfClXu/H2mIqP"
echo "t4iLn+8a6SyPOLnXZUuzIow7bLC2abL8nWPcbjp5sVBZHZpXPkST6Grdc9BLmPsL"
echo "zu5Afmws4tFt1rn4+uTh1OkuHk4IOBWQ4PRhJUSwWOafnvfZogt0peBkih6r6QeY"
echo "dZVQE96ZvvmDrWLUTluoZb+muqt40pZb4E1m8d9iiofkYhJ1EgchifFeZrLnQY36"
echo "GThJnh8rguyv071bpFUxGDpmwKGviegK"
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

if grep -q -s "95:A3:20:FD:C8:5C:D9:3A:E6:DD:6A:91:40:E2:3A:78" /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
        pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
        pause

        if [ ! -r cacert.pem.local ]; then
            echo "# cp -a cacert.pem cacert.pem.local"
            cp -a cacert.pem cacert.pem.local
            pause
        fi

        echo "# cat << EOF >> cacert.pem.local"
        echo ">"
        echo "> # Issuer: DC=ms, DC=hpcloud, CN=cloudpca"
        echo "> # Subject: DC=ms, DC=hpcloud, CN=aw2cloudica03"
        echo "> # Label: "aw2cloudica03""
        echo "> # Serial: 1A391A3300000000000B"
        echo "> # MD5 Fingerprint: 95:A3:20:FD:C8:5C:D9:3A:E6:DD:6A:91:40:E2:3A:78"
        echo "> # SHA1 Fingerprint: B4:A0:1C:96:5F:75:A8:23:80:96:B2:A2:4F:32:20:22:5B:4A:62:0F"
        echo "> # SHA256 Fingerprint: 2C:B1:57:96:4D:38:BA:60:0C:F7:E5:7D:42:42:11:90:C7:97:94:BB:D3:9C:DA:FA:9E:88:71:8A:7A:0E:8C:6F"
        echo "> -----BEGIN CERTIFICATE-----"
        echo "> MIIEZDCCA0ygAwIBAgIKGjkaMwAAAAAACzANBgkqhkiG9w0BAQsFADBAMRIwEAYK"
        echo "> CZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdocGNsb3VkMREwDwYDVQQD"
        echo "> EwhjbG91ZHBjYTAeFw0xMjAyMjkwNDU1MjFaFw0xNzAyMjgwNTA1MjFaMEUxEjAQ"
        echo "> BgoJkiaJk/IsZAEZFgJtczEXMBUGCgmSJomT8ixkARkWB2hwY2xvdWQxFjAUBgNV"
        echo "> BAMTDWF3MmNsb3VkaWNhMDMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB"
        echo "> AQDYridWlpBFg3BJRGP+pbkflnlsvAhzpf+kIQ3NBWN+8PD0GB5LCMqe8VS0TvXk"
        echo "> 1PWkJ0zop7d5gbxOb1QvTqvNtZZatEOg94lbox3YaN26TZnTIUBvx9ZQ/vwNvww1"
        echo "> P2kiS1mvd5lPBOFZDeUAXSJnhIC7NmCsHTaxAVPdvmh8gMlwRLH9H4S1S5a1f9iL"
        echo "> g3gGEbcntC1oXg2D5/QL8fdP66oFa+72wsGoz8k46FBviDVUB8SQ7NtMtHZZ6dN1"
        echo "> 3U6Anc4nfRIJA8zqT9oJCUQpuG668sRw7ztZECcHTRsqWE9p7nImzgib39dYdD3i"
        echo "> Y3PngQzw4tSY/azFDK36IF0bAgMBAAGjggFZMIIBVTAQBgkrBgEEAYI3FQEEAwIB"
        echo "> ADAdBgNVHQ4EFgQUIsX2rnOI2dW38KM/QO6zvRtm1WgwGQYJKwYBBAGCNxQCBAwe"
        echo "> CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j"
        echo "> BBgwFoAUFmFIBRE5tO7xeHEiZyjpnq+wz0UwTgYDVR0fBEcwRTBDoEGgP4Y9aHR0"
        echo "> cDovL2F3MmNsb3VkY2EwMi51c3dlc3QuaHBjbG91ZC5tcy9DZXJ0RW5yb2xsL2Ns"
        echo "> b3VkcGNhLmNybDB4BggrBgEFBQcBAQRsMGowaAYIKwYBBQUHMAKGXGh0dHA6Ly9h"
        echo "> dzJjbG91ZGNhMDIudXN3ZXN0LmhwY2xvdWQubXMvQ2VydEVucm9sbC9BVzJDTE9V"
        echo "> RENBMDIudXN3ZXN0LmhwY2xvdWQubXNfY2xvdWRwY2EuY3J0MA0GCSqGSIb3DQEB"
        echo "> CwUAA4IBAQAF/iK35c0jssJBYz/NBvokg+Xd8raomRtObiuoN/myft5BRezqpQej"
        echo "> X9nipSsJP4rWl7jP7ZYDIYy2lAQVWNeXbeWGealbfRnCwt/h98pRfClXu/H2mIqP"
        echo "> t4iLn+8a6SyPOLnXZUuzIow7bLC2abL8nWPcbjp5sVBZHZpXPkST6Grdc9BLmPsL"
        echo "> zu5Afmws4tFt1rn4+uTh1OkuHk4IOBWQ4PRhJUSwWOafnvfZogt0peBkih6r6QeY"
        echo "> dZVQE96ZvvmDrWLUTluoZb+muqt40pZb4E1m8d9iiofkYhJ1EgchifFeZrLnQY36"
        echo "> GThJnh8rguyv071bpFUxGDpmwKGviegK"
        echo "> -----END CERTIFICATE-----"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo                                                                    >> cacert.pem
        echo "# Issuer: DC=ms, DC=hpcloud, CN=cloudpca"                         >> cacert.pem
        echo "# Subject: DC=ms, DC=hpcloud, CN=aw2cloudica03"                   >> cacert.pem
        echo "# Label: "aw2cloudica03""                                         >> cacert.pem
        echo "# Serial: 1A391A3300000000000B"                                   >> cacert.pem
        echo "# MD5 Fingerprint: 95:A3:20:FD:C8:5C:D9:3A:E6:DD:6A:91:40:E2:3A:78" >> cacert.pem
        echo "# SHA1 Fingerprint: B4:A0:1C:96:5F:75:A8:23:80:96:B2:A2:4F:32:20:22:5B:4A:62:0F" >> cacert.pem
        echo "# SHA256 Fingerprint: 2C:B1:57:96:4D:38:BA:60:0C:F7:E5:7D:42:42:11:90:C7:97:94:BB:D3:9C:DA:FA:9E:88:71:8A:7A:0E:8C:6F" >> cacert.pem
        echo "-----BEGIN CERTIFICATE-----"                                      >> cacert.pem
        echo "MIIEZDCCA0ygAwIBAgIKGjkaMwAAAAAACzANBgkqhkiG9w0BAQsFADBAMRIwEAYK" >> cacert.pem
        echo "CZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdocGNsb3VkMREwDwYDVQQD" >> cacert.pem
        echo "EwhjbG91ZHBjYTAeFw0xMjAyMjkwNDU1MjFaFw0xNzAyMjgwNTA1MjFaMEUxEjAQ" >> cacert.pem
        echo "BgoJkiaJk/IsZAEZFgJtczEXMBUGCgmSJomT8ixkARkWB2hwY2xvdWQxFjAUBgNV" >> cacert.pem
        echo "BAMTDWF3MmNsb3VkaWNhMDMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB" >> cacert.pem
        echo "AQDYridWlpBFg3BJRGP+pbkflnlsvAhzpf+kIQ3NBWN+8PD0GB5LCMqe8VS0TvXk" >> cacert.pem
        echo "1PWkJ0zop7d5gbxOb1QvTqvNtZZatEOg94lbox3YaN26TZnTIUBvx9ZQ/vwNvww1" >> cacert.pem
        echo "P2kiS1mvd5lPBOFZDeUAXSJnhIC7NmCsHTaxAVPdvmh8gMlwRLH9H4S1S5a1f9iL" >> cacert.pem
        echo "g3gGEbcntC1oXg2D5/QL8fdP66oFa+72wsGoz8k46FBviDVUB8SQ7NtMtHZZ6dN1" >> cacert.pem
        echo "3U6Anc4nfRIJA8zqT9oJCUQpuG668sRw7ztZECcHTRsqWE9p7nImzgib39dYdD3i" >> cacert.pem
        echo "Y3PngQzw4tSY/azFDK36IF0bAgMBAAGjggFZMIIBVTAQBgkrBgEEAYI3FQEEAwIB" >> cacert.pem
        echo "ADAdBgNVHQ4EFgQUIsX2rnOI2dW38KM/QO6zvRtm1WgwGQYJKwYBBAGCNxQCBAwe" >> cacert.pem
        echo "CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j" >> cacert.pem
        echo "BBgwFoAUFmFIBRE5tO7xeHEiZyjpnq+wz0UwTgYDVR0fBEcwRTBDoEGgP4Y9aHR0" >> cacert.pem
        echo "cDovL2F3MmNsb3VkY2EwMi51c3dlc3QuaHBjbG91ZC5tcy9DZXJ0RW5yb2xsL2Ns" >> cacert.pem
        echo "b3VkcGNhLmNybDB4BggrBgEFBQcBAQRsMGowaAYIKwYBBQUHMAKGXGh0dHA6Ly9h" >> cacert.pem
        echo "dzJjbG91ZGNhMDIudXN3ZXN0LmhwY2xvdWQubXMvQ2VydEVucm9sbC9BVzJDTE9V" >> cacert.pem
        echo "RENBMDIudXN3ZXN0LmhwY2xvdWQubXNfY2xvdWRwY2EuY3J0MA0GCSqGSIb3DQEB" >> cacert.pem
        echo "CwUAA4IBAQAF/iK35c0jssJBYz/NBvokg+Xd8raomRtObiuoN/myft5BRezqpQej" >> cacert.pem
        echo "X9nipSsJP4rWl7jP7ZYDIYy2lAQVWNeXbeWGealbfRnCwt/h98pRfClXu/H2mIqP" >> cacert.pem
        echo "t4iLn+8a6SyPOLnXZUuzIow7bLC2abL8nWPcbjp5sVBZHZpXPkST6Grdc9BLmPsL" >> cacert.pem
        echo "zu5Afmws4tFt1rn4+uTh1OkuHk4IOBWQ4PRhJUSwWOafnvfZogt0peBkih6r6QeY" >> cacert.pem
        echo "dZVQE96ZvvmDrWLUTluoZb+muqt40pZb4E1m8d9iiofkYhJ1EgchifFeZrLnQY36" >> cacert.pem
        echo "GThJnh8rguyv071bpFUxGDpmwKGviegK"                                 >> cacert.pem
        echo "-----END CERTIFICATE-----"                                        >> cacert.pem
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
echo "$(printf '%2d' $step). Configure AWS CLI to support local Eucalyptus region"
echo "    - This creates a modified version of the _endpoints.json file which the"
echo "      botocore Python module within AWS CLI uses to configure AWS endpoints,"
echo "      adding the new local Eucalyptus region endpoints"
echo "    - We then rename the original _endpoints.json file with the .orig extension,"
echo "      then create a symlink with the original name pointing to our version"
echo "    - The files created are too long to display - view it in the location"
echo "      shown below. You can compare with the original to see what changes have"
echo "      been made."
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
echo "ln -s _endoints.json.local.ssl _endpoints.json"

if grep -q -s "$region" /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local.ssl; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "pushd /usr/lib/python2.6/site-packages/botocore/data"
        pushd /usr/lib/python2.6/site-packages/botocore/data &> /dev/null
        echo "#"
        echo "# cat << EOF > _endpoints.json.local.ssl"
        echo ">     ... too long to list ..."
        # Use echo instead of cat << EOF to better show indentation
        echo "> EOF"
        echo "{"                                                                                    > _endpoints.json.local.ssl
        echo "  \"_default\":["                                                                    >> _endpoints.json.local.ssl
        echo "    {"                                                                               >> _endpoints.json.local.ssl
        echo "      \"uri\":\"{scheme}://{service}.{region}.$domain\","                            >> _endpoints.json.local.ssl
        echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
        echo "        [\"region\", \"startsWith\", \"${region%-*}-\"]"                             >> _endpoints.json.local.ssl
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
        echo "      \"uri\":\"{scheme}://compute.{region}.$domain\","                              >> _endpoints.json.local.ssl
        echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
        echo "        [\"region\",\"startsWith\",\"${region%-*}-\"]"                               >> _endpoints.json.local.ssl
        echo "      ]"                                                                             >> _endpoints.json.local.ssl
        echo "    }"                                                                               >> _endpoints.json.local.ssl
        echo "  ],"                                                                                >> _endpoints.json.local.ssl
        echo "  \"elasticloadbalancing\": ["                                                       >> _endpoints.json.local.ssl
        echo "   {"                                                                                >> _endpoints.json.local.ssl
        echo "    \"uri\":\"{scheme}://loadbalancing.{region}.$domain\","                          >> _endpoints.json.local.ssl
        echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
        echo "      [\"region\",\"startsWith\",\"${region%-*}-\"]"                                 >> _endpoints.json.local.ssl
        echo "    ]"                                                                               >> _endpoints.json.local.ssl
        echo "   }"                                                                                >> _endpoints.json.local.ssl
        echo "  ],"                                                                                >> _endpoints.json.local.ssl
        echo "  \"monitoring\":["                                                                  >> _endpoints.json.local.ssl
        echo "    {"                                                                               >> _endpoints.json.local.ssl
        echo "      \"uri\":\"{scheme}://cloudwatch.{region}.$domain\","                           >> _endpoints.json.local.ssl
        echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
        echo "       [\"region\",\"startsWith\",\"${region%-*}-\"]"                                >> _endpoints.json.local.ssl
        echo "      ]"                                                                             >> _endpoints.json.local.ssl
        echo "    }"                                                                               >> _endpoints.json.local.ssl
        echo "  ],"                                                                                >> _endpoints.json.local.ssl
        echo "  \"swf\":["                                                                         >> _endpoints.json.local.ssl
        echo "   {"                                                                                >> _endpoints.json.local.ssl
        echo "    \"uri\":\"{scheme}://simpleworkflow.{region}.$domain\","                         >> _endpoints.json.local.ssl
        echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
        echo "     [\"region\",\"startsWith\",\"${region%-*}-\"]"                                  >> _endpoints.json.local.ssl
        echo "    ]"                                                                               >> _endpoints.json.local.ssl
        echo "   }"                                                                                >> _endpoints.json.local.ssl
        echo "  ],"                                                                                >> _endpoints.json.local.ssl
        echo "  \"iam\":["                                                                         >> _endpoints.json.local.ssl
        echo "    {"                                                                               >> _endpoints.json.local.ssl
        echo "      \"uri\":\"https://euare.{region}.$domain\","                                   >> _endpoints.json.local.ssl
        echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
        echo "        [\"region\", \"startsWith\", \"${region%-*}-\"]"                             >> _endpoints.json.local.ssl
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
        echo "      \"uri\":\"https://tokens.{region}.$domain\","                                  >> _endpoints.json.local.ssl
        echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
        echo "        [\"region\", \"startsWith\", \"${region%-*}-\"]"                             >> _endpoints.json.local.ssl
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
        echo "      \"uri\":\"{scheme}://objectstorage.{region}.$domain//\","                      >> _endpoints.json.local.ssl
        echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
        echo "        [\"region\", \"startsWith\", \"${region%-*}-\"]"                             >> _endpoints.json.local.ssl
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
        pause

        echo "# mv _endpoints.json _endpoints.json.orig"
        mv _endpoints.json _endpoints.json.orig
        echo "#"
        echo "# ln -s _endpoints.json.local.ssl _endpoints.json"
        ln -s _endpoints.json.local.ssl _endpoints.json
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
    echo "$(printf '%2d' $step). Display AWS CLI Configuration"
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
    echo "$(printf '%2d' $step). Confirm AWS CLI"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "aws ec2 describe-key-pairs"
    echo
    echo "aws ec2 describe-key-pairs --profile=default"
    echo
    echo "aws ec2 describe-key-pairs --profile=$region-admin"

    run 50

    if [ $choice = y ]; then
        echo
        echo "# aws ec2 describe-key-pairs"
        aws ec2 describe-key-pairs
        echo "#"
        echo "# aws ec2 describe-key-pairs --profile=default"
        aws ec2 describe-key-pairs --profile=default
        echo "#"
        echo "# aws ec2 describe-key-pairs --profile=$region-admin"
        aws ec2 describe-key-pairs --profile=$region-admin

        next 50
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus AWS CLI configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus AWS CLI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
