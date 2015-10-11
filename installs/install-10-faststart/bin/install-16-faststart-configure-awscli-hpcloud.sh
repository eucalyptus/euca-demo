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
config=$(hostname -s)


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-c config]"
    echo "  -I         non-interactive"
    echo "  -s         slower: increase pauses by 25%"
    echo "  -f         faster: reduce pauses by 25%"
    echo "  -c config  configuration (default: $config)"
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

while getopts Isfc:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    c)  config="$OPTARG";;
    ?)  usage
        exit 1;;
    esac
done

shift $(($OPTIND - 1))


#  4. Validate environment

if [[ $config =~ ^([a-zA-Z0-9_-]*)$ ]]; then
    conffile=$confdir/$config.txt

    if [ ! -r $conffile ]; then
        echo "-c $config invalid: can't find configuration file: $conffile"
        exit 5
    fi
else
    echo "-c $config illegal: must consist of a-z, A-Z, 0-9, '-' or '_' characters"
    exit 2
fi

source $conffile

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
echo "$(printf '%2d' $step). Use Eucalyptus Administrator credentials"
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
echo "cat << EOF >> cacert.pem"
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
echo "popd"

run 50

if [ $choice = y ]; then
    echo
    echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
    pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
    echo "#"
    echo "# cat << EOF >> cacert.pem"
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
    echo "#"
    echo "# popd"
    popd &> /dev/null

    next 50
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
echo "cat << EOF >> cacert.pem"
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
if [ $choice = y ]; then
    echo
    echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
    pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
    echo "#"
    echo "# cat << EOF >> cacert.pem"
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
    echo "#"
    echo "# popd"
    popd &> /dev/null

    next 50
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
echo "cat << EOF >> cacert.pem"
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
if [ $choice = y ]; then
    echo
    echo "# pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests"
    pushd /usr/lib/python2.6/site-packages/botocore/vendored/requests &> /dev/null
    echo "#"
    echo "# cat << EOF >> cacert.pem"
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
    echo "#"
    echo "# popd"
    popd &> /dev/null

    next 50
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
    echo "      \"uri\":\"{scheme}://{service}.{region}.$AWS_DEFAULT_DOMAIN\","                >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]"                 >> _endpoints.json.local.ssl
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
    echo "      \"uri\":\"{scheme}://compute.{region}.$AWS_DEFAULT_DOMAIN\","                  >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]"                   >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"elasticloadbalancing\": ["                                                       >> _endpoints.json.local.ssl
    echo "   {"                                                                                >> _endpoints.json.local.ssl
    echo "    \"uri\":\"{scheme}://loadbalancing.{region}.$AWS_DEFAULT_DOMAIN\","              >> _endpoints.json.local.ssl
    echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
    echo "      [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]"                     >> _endpoints.json.local.ssl
    echo "    ]"                                                                               >> _endpoints.json.local.ssl
    echo "   }"                                                                                >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"monitoring\":["                                                                  >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"{scheme}://cloudwatch.{region}.$AWS_DEFAULT_DOMAIN\","               >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "       [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]"                    >> _endpoints.json.local.ssl
    echo "      ]"                                                                             >> _endpoints.json.local.ssl
    echo "    }"                                                                               >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"swf\":["                                                                         >> _endpoints.json.local.ssl
    echo "   {"                                                                                >> _endpoints.json.local.ssl
    echo "    \"uri\":\"{scheme}://simpleworkflow.{region}.$AWS_DEFAULT_DOMAIN\","             >> _endpoints.json.local.ssl
    echo "    \"constraints\": ["                                                              >> _endpoints.json.local.ssl
    echo "     [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]"                      >> _endpoints.json.local.ssl
    echo "    ]"                                                                               >> _endpoints.json.local.ssl
    echo "   }"                                                                                >> _endpoints.json.local.ssl
    echo "  ],"                                                                                >> _endpoints.json.local.ssl
    echo "  \"iam\":["                                                                         >> _endpoints.json.local.ssl
    echo "    {"                                                                               >> _endpoints.json.local.ssl
    echo "      \"uri\":\"https://euare.{region}.$AWS_DEFAULT_DOMAIN\","                       >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]"                 >> _endpoints.json.local.ssl
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
    echo "      \"uri\":\"https://tokens.{region}.$AWS_DEFAULT_DOMAIN\","                      >> _endpoints.json.local.ssl
    echo "      \"constraints\":["                                                             >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]"                 >> _endpoints.json.local.ssl
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
    echo "      \"uri\":\"{scheme}://objectstorage.{region}.$AWS_DEFAULT_DOMAIN//\","          >> _endpoints.json.local.ssl
    echo "      \"constraints\": ["                                                            >> _endpoints.json.local.ssl
    echo "        [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]"                 >> _endpoints.json.local.ssl
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
echo "region = $AWS_DEFAULT_REGION"
echo "output = text"
echo
echo "[profile $AWS_DEFAULT_REGION-admin]"
echo "region = $AWS_DEFAULT_REGION"
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
echo "aws_access_key_id = $AWS_ACCESS_KEY"
echo "aws_secret_access_key = $AWS_SECRET_KEY"
echo
echo "[$AWS_DEFAULT_REGION-admin]"
echo "aws_access_key_id = $AWS_ACCESS_KEY"
echo "aws_secret_access_key = $AWS_SECRET_KEY"
echo
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
    echo "> region = $AWS_DEFAULT_REGION"
    echo "> output = text"
    echo ">"
    echo "> [profile-$AWS_DEFAULT_REGION-admin]"
    echo "> region = $AWS_DEFAULT_REGION"
    echo "> output = text"
    echo ">"
    echo "> EOF"
    # Use echo instead of cat << EOF to better show indentation
    echo "#"                                    > ~/.aws/config
    echo "# AWS Config file"                   >> ~/.aws/config
    echo "#"                                   >> ~/.aws/config
    echo                                       >> ~/.aws/config
    echo "[default]"                           >> ~/.aws/config
    echo "region = $AWS_DEFAULT_REGION"        >> ~/.aws/config
    echo "output = text"                       >> ~/.aws/config
    echo                                       >> ~/.aws/config
    echo "[profile $AWS_DEFAULT_REGION-admin]" >> ~/.aws/config
    echo "region = $AWS_DEFAULT_REGION"        >> ~/.aws/config
    echo "output = text"                       >> ~/.aws/config
    echo                                       >> ~/.aws/config
    pause

    echo "# cat << EOF > ~/.aws/credentials"
    echo "> #"
    echo "> # AWS Credentials file"
    echo "> #"
    echo ">"
    echo "> [default]"
    echo "> aws_access_key_id = $AWS_ACCESS_KEY"
    echo "> aws_secret_access_key = $AWS_SECRET_KEY"
    echo ">"
    echo "> [$AWS_DEFAULT_REGION-admin]"
    echo "> aws_access_key_id = $AWS_ACCESS_KEY"
    echo "> aws_secret_access_key = $AWS_SECRET_KEY"
    echo ">"
    echo "> EOF"
    # Use echo instead of cat << EOF to better show indentation
    echo "#"                                        > ~/.aws/credentials
    echo "# AWS Credentials file"                  >> ~/.aws/credentials
    echo "#"                                       >> ~/.aws/credentials
    echo                                           >> ~/.aws/credentials
    echo "[default]"                               >> ~/.aws/credentials
    echo "aws_access_key_id = $AWS_ACCESS_KEY"     >> ~/.aws/credentials
    echo "aws_secret_access_key = $AWS_SECRET_KEY" >> ~/.aws/credentials
    echo                                           >> ~/.aws/credentials
    echo "[$AWS_DEFAULT_REGION-admin]"             >> ~/.aws/credentials
    echo "aws_access_key_id = $AWS_ACCESS_KEY"     >> ~/.aws/credentials
    echo "aws_secret_access_key = $AWS_SECRET_KEY" >> ~/.aws/credentials
    echo                                           >> ~/.aws/credentials
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
echo
echo "aws ec2 describe-key-pairs --profile=default"
echo
echo "aws ec2 describe-key-pairs --profile=$AWS_DEFAULT_REGION-admin"

run 50

if [ $choice = y ]; then
    echo
    echo "# aws ec2 describe-key-pairs"
    aws ec2 describe-key-pairs
    echo "#"
    echo "# aws ec2 describe-key-pairs --profile=default"
    aws ec2 describe-key-pairs --profile=default
    echo "#"
    echo "# aws ec2 describe-key-pairs --profile=$AWS_DEFAULT_REGION-admin"
    aws ec2 describe-key-pairs --profile=$AWS_DEFAULT_REGION-admin

    next 50
fi

end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus AWS CLI configuration complete (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus AWS CLI configuration complete (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
