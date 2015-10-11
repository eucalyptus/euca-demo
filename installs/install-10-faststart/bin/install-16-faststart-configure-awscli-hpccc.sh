#/bin/bash
#
# This script configures the AWS CLI to access the local Eucalyptus instance after a Faststart installation
# - This variant uses the HP EBC Root Certification Authority
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
echo "    - We will use the HP EBC Root Certification Authority to sign SSL certificates"
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
echo "# Issuer: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"
echo "# Subject: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"
echo "# Label: \"hpccc-DC1A-CA\""
echo "# Serial: 637EF9629C9CA48F4C2ED6DA4C031E51"
echo "# MD5 Fingerprint: CE:5B:A4:F9:73:73:6D:84:79:EA:4B:01:AF:65:55:EE"
echo "# SHA1 Fingerprint: 2B:52:D7:06:1E:59:90:A5:BE:9A:CC:89:BA:C0:C0:90:2B:3E:48:46"
echo "# SHA256 Fingerprint: 2F:2A:44:29:A5:28:08:37:F4:BB:1C:D6:22:8A:BF:FF:CE:D2:2C:BC:BD:94:E9:13:D6:27:0B:97:5A:1A:EA:14"
echo "-----BEGIN CERTIFICATE-----"
echo "MIIDpDCCAoygAwIBAgIQY375YpycpI9MLtbaTAMeUTANBgkqhkiG9w0BAQUFADBE"
echo "MRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAU"
echo "BgNVBAMTDWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE0MjExNzI4WhcNMjAwNDEzMjEy"
echo "NzI3WjBEMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBj"
echo "Y2MxFjAUBgNVBAMTDWhwY2NjLURDMUEtQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB"
echo "DwAwggEKAoIBAQCmoHR7XOde9LHGmEa0rNAkAt6jDMpxypW3C1xcKi+T8ZcMUwdv"
echo "K9oQv9ZnRAhyCEqQc/VobiiR3JO9/lz86Y9XsoysbrU2gZTfyYw03DH32Tm3tYaI"
echo "xsK+ThBRkM0HhKZiGAO5d5UFz2f3xWWgaahHEbXoOYbuBYxJ6TWpmhrV/NbVdJXI"
echo "/44mdCI4TAjIlQemFa91ZyKdEuT76vt13leyzld4eyl0LU1go3vaLLNo1G7tY5jW"
echo "2aUw7hgpd5jWFPrCNkdvuk04KHl617H+qGGvWKlapG8f7e6voHjgbA2Zqsoa4lQr"
echo "6Is13kAZIQRCEUrppeYWOkhzks/iwWIyJMQZAgMBAAGjgZEwgY4wEwYJKwYBBAGC"
echo "NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD"
echo "VR0OBBYEFO8xVEl5RiVrrtGK9Ou+YdNuDNRtMBIGCSsGAQQBgjcVAQQFAgMDAAMw"
echo "IwYJKwYBBAGCNxUCBBYEFMuCtZAjoURHCHCk5JSf7gpClFeyMA0GCSqGSIb3DQEB"
echo "BQUAA4IBAQAlkTqoUmW6NMzpVQC4aaWVhpwFgU61Vg9d/eDbYZ8OKRxObpjjJv3L"
echo "kHIxVlKnt/XjQ/6KOsneo0cgdxts7vPDxEyMW1/Svronzau3LnMjnnwp2RV0Rn/B"
echo "TQi1NgNLzDATqo1naan6WCiZwL+O2kDJlp5xXfFLx3Gapl3Opa9ShbO1XQmbCdPT"
echo "A7FriDiLLBTWAd6TqhmfH+dcz56TGr36itJAh8i2jb2gGErB0DvBN2S4bCvJ1e54"
echo "gYH1DylEpeALZeYK3M30AoRivO5eAivFRpUi/CBLVaFqmD4E2MI8mdbWtLH1t0Qi"
echo "3hyLaqkOlbnIuxMLe4X041c3cZ+PI7wm"
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
    echo "> # Issuer: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"
    echo "> # Subject: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"
    echo "> # Label: \"hpccc-DC1A-CA\""
    echo "> # Serial: 637EF9629C9CA48F4C2ED6DA4C031E51"
    echo "> # MD5 Fingerprint: CE:5B:A4:F9:73:73:6D:84:79:EA:4B:01:AF:65:55:EE"
    echo "> # SHA1 Fingerprint: 2B:52:D7:06:1E:59:90:A5:BE:9A:CC:89:BA:C0:C0:90:2B:3E:48:46"
    echo "> # SHA256 Fingerprint: 2F:2A:44:29:A5:28:08:37:F4:BB:1C:D6:22:8A:BF:FF:CE:D2:2C:BC:BD:94:E9:13:D6:27:0B:97:5A:1A:EA:14"
    echo "> -----BEGIN CERTIFICATE-----"
    echo "> MIIDpDCCAoygAwIBAgIQY375YpycpI9MLtbaTAMeUTANBgkqhkiG9w0BAQUFADBE"
    echo "> MRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAU"
    echo "> BgNVBAMTDWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE0MjExNzI4WhcNMjAwNDEzMjEy"
    echo "> NzI3WjBEMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBj"
    echo "> Y2MxFjAUBgNVBAMTDWhwY2NjLURDMUEtQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB"
    echo "> DwAwggEKAoIBAQCmoHR7XOde9LHGmEa0rNAkAt6jDMpxypW3C1xcKi+T8ZcMUwdv"
    echo "> K9oQv9ZnRAhyCEqQc/VobiiR3JO9/lz86Y9XsoysbrU2gZTfyYw03DH32Tm3tYaI"
    echo "> xsK+ThBRkM0HhKZiGAO5d5UFz2f3xWWgaahHEbXoOYbuBYxJ6TWpmhrV/NbVdJXI"
    echo "> /44mdCI4TAjIlQemFa91ZyKdEuT76vt13leyzld4eyl0LU1go3vaLLNo1G7tY5jW"
    echo "> 2aUw7hgpd5jWFPrCNkdvuk04KHl617H+qGGvWKlapG8f7e6voHjgbA2Zqsoa4lQr"
    echo "> 6Is13kAZIQRCEUrppeYWOkhzks/iwWIyJMQZAgMBAAGjgZEwgY4wEwYJKwYBBAGC"
    echo "> NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD"
    echo "> VR0OBBYEFO8xVEl5RiVrrtGK9Ou+YdNuDNRtMBIGCSsGAQQBgjcVAQQFAgMDAAMw"
    echo "> IwYJKwYBBAGCNxUCBBYEFMuCtZAjoURHCHCk5JSf7gpClFeyMA0GCSqGSIb3DQEB"
    echo "> BQUAA4IBAQAlkTqoUmW6NMzpVQC4aaWVhpwFgU61Vg9d/eDbYZ8OKRxObpjjJv3L"
    echo "> kHIxVlKnt/XjQ/6KOsneo0cgdxts7vPDxEyMW1/Svronzau3LnMjnnwp2RV0Rn/B"
    echo "> TQi1NgNLzDATqo1naan6WCiZwL+O2kDJlp5xXfFLx3Gapl3Opa9ShbO1XQmbCdPT"
    echo "> A7FriDiLLBTWAd6TqhmfH+dcz56TGr36itJAh8i2jb2gGErB0DvBN2S4bCvJ1e54"
    echo "> gYH1DylEpeALZeYK3M30AoRivO5eAivFRpUi/CBLVaFqmD4E2MI8mdbWtLH1t0Qi"
    echo "> 3hyLaqkOlbnIuxMLe4X041c3cZ+PI7wm"
    echo "> -----END CERTIFICATE-----"
    echo "> EOF"
    # Use echo instead of cat << EOF to better show indentation
    echo                                                                    >> cacert.pem
    echo "# Issuer: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"                     >> cacert.pem
    echo "# Subject: DC=com, DC=hpccc, CN=hpccc-DC1A-CA"                    >> cacert.pem
    echo "# Label: \"hpccc-DC1A-CA\""                                       >> cacert.pem
    echo "# Serial: 637EF9629C9CA48F4C2ED6DA4C031E51"                       >> cacert.pem
    echo "# MD5 Fingerprint: CE:5B:A4:F9:73:73:6D:84:79:EA:4B:01:AF:65:55:EE" >> cacert.pem
    echo "# SHA1 Fingerprint: 2B:52:D7:06:1E:59:90:A5:BE:9A:CC:89:BA:C0:C0:90:2B:3E:48:46" >> cacert.pem
    echo "# SHA256 Fingerprint: 2F:2A:44:29:A5:28:08:37:F4:BB:1C:D6:22:8A:BF:FF:CE:D2:2C:BC:BD:94:E9:13:D6:27:0B:97:5A:1A:EA:14" >> cacert.pem
    echo "-----BEGIN CERTIFICATE-----"                                      >> cacert.pem
    echo "MIIDpDCCAoygAwIBAgIQY375YpycpI9MLtbaTAMeUTANBgkqhkiG9w0BAQUFADBE" >> cacert.pem
    echo "MRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAU" >> cacert.pem
    echo "BgNVBAMTDWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE0MjExNzI4WhcNMjAwNDEzMjEy" >> cacert.pem
    echo "NzI3WjBEMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBj" >> cacert.pem
    echo "Y2MxFjAUBgNVBAMTDWhwY2NjLURDMUEtQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB" >> cacert.pem
    echo "DwAwggEKAoIBAQCmoHR7XOde9LHGmEa0rNAkAt6jDMpxypW3C1xcKi+T8ZcMUwdv" >> cacert.pem
    echo "K9oQv9ZnRAhyCEqQc/VobiiR3JO9/lz86Y9XsoysbrU2gZTfyYw03DH32Tm3tYaI" >> cacert.pem
    echo "xsK+ThBRkM0HhKZiGAO5d5UFz2f3xWWgaahHEbXoOYbuBYxJ6TWpmhrV/NbVdJXI" >> cacert.pem
    echo "/44mdCI4TAjIlQemFa91ZyKdEuT76vt13leyzld4eyl0LU1go3vaLLNo1G7tY5jW" >> cacert.pem
    echo "2aUw7hgpd5jWFPrCNkdvuk04KHl617H+qGGvWKlapG8f7e6voHjgbA2Zqsoa4lQr" >> cacert.pem
    echo "6Is13kAZIQRCEUrppeYWOkhzks/iwWIyJMQZAgMBAAGjgZEwgY4wEwYJKwYBBAGC" >> cacert.pem
    echo "NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD" >> cacert.pem
    echo "VR0OBBYEFO8xVEl5RiVrrtGK9Ou+YdNuDNRtMBIGCSsGAQQBgjcVAQQFAgMDAAMw" >> cacert.pem
    echo "IwYJKwYBBAGCNxUCBBYEFMuCtZAjoURHCHCk5JSf7gpClFeyMA0GCSqGSIb3DQEB" >> cacert.pem
    echo "BQUAA4IBAQAlkTqoUmW6NMzpVQC4aaWVhpwFgU61Vg9d/eDbYZ8OKRxObpjjJv3L" >> cacert.pem
    echo "kHIxVlKnt/XjQ/6KOsneo0cgdxts7vPDxEyMW1/Svronzau3LnMjnnwp2RV0Rn/B" >> cacert.pem
    echo "TQi1NgNLzDATqo1naan6WCiZwL+O2kDJlp5xXfFLx3Gapl3Opa9ShbO1XQmbCdPT" >> cacert.pem
    echo "A7FriDiLLBTWAd6TqhmfH+dcz56TGr36itJAh8i2jb2gGErB0DvBN2S4bCvJ1e54" >> cacert.pem
    echo "gYH1DylEpeALZeYK3M30AoRivO5eAivFRpUi/CBLVaFqmD4E2MI8mdbWtLH1t0Qi" >> cacert.pem
    echo "3hyLaqkOlbnIuxMLe4X041c3cZ+PI7wm"                                 >> cacert.pem
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
