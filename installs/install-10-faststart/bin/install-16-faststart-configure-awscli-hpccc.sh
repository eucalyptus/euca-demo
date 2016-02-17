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
if [ ! -r cacert.pem.local ]; then
    echo "cp -a cacert.pem cacert.pem.local"
    echo
fi
echo "cat << EOF >> cacert.pem.local"
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

if grep -q -s "CE:5B:A4:F9:73:73:6D:84:79:EA:4B:01:AF:65:55:EE" /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local; then
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
        aws ec2 describe-key-pairs --profile=defaults
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
