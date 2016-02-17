#!/bin/bash
#
# This script configures Eucalyptus DNS after a Faststart installation
#
# This should be run immediately after the Faststart installer completes
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
showdnsconfig=0
extended=0
region=${AWS_DEFAULT_REGION#*@}
domain=${AWS_DEFAULT_DOMAIN:-$(hostname -i).xip.io}
instance_subdomain=${EUCA_INSTANCE_SUBDOMAIN:-.vm}
loadbalancer_subdomain=${EUCA_LOADBALANCER_SUBDOMAIN:-lb}
dns_timeout=30
dns_loadbalancer_ttl=15


#  2. Define functions

usage () {
    echo "Usage: ${BASH_SOURCE##*/} [-I [-s | -f]] [-x] [-e]"
    echo "                             [-r region] [-d domain]"
    echo "                             [-i instance_subdomain] [-b loadbalancer_subdomain]"
    echo "  -I                         non-interactive"
    echo "  -s                         slower: increase pauses by 25%"
    echo "  -f                         faster: reduce pauses by 25%"
    echo "  -p                         display example parent DNS server configuration"
    echo "  -e                         extended confirmation of API calls"
    echo "  -r region                  Eucalyptus Region (default: $region)"
    echo "  -d domain                  Eucalyptus Domain (default: $domain)"
    echo "  -i instance_subdomain      Eucalyptus Instance Sub-Domain (default: $instance_subdomain)"
    echo "  -b loadbalancer_subdomain  Eucalyptus Load Balancer Sub-Domain (default: $loadbalancer_subdomain)"
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

while getopts Isfxer:d:i:b:? arg; do
    case $arg in
    I)  interactive=0;;
    s)  ((speed < speed_max)) && ((speed=speed+25));;
    f)  ((speed > 0)) && ((speed=speed-25));;
    x)  showdnsconfig=1;;
    e)  extended=1;;
    r)  region="$OPTARG";;
    d)  domain="$OPTARG";;
    i)  instance_subdomain="$OPTARG";;
    b)  loadbalancer_subdomain="$OPTARG";;
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

if [ -z $instance_subdomain ]; then
    echo "-i instance_subdomain missing!"
    echo "Could not automatically determine instance_subdomain, and it was not specified as a parameter"
    exit 13
fi

if [ -z $loadbalancer_subdomain ]; then
    echo "-b loadbalancer_subdomain missing!"
    echo "Could not automatically determine loadbalancer_subdomain, and it was not specified as a parameter"
    exit 14
fi

if ! grep -s -q "\[user localhost-admin]" ~/.euca/localhost.ini; then
    echo "Could not find Eucalyptus (localhost) Region Eucalyptus Administrator (admin) Euca2ools user!"
    echo "Expected to find: [user localhost-admin] in ~/.euca/localhost.ini"

    # See if FastStart credentials are still present. If so we will convert them below.
    if ! grep -s -q "\[user [0-9]*:admin]" ~/.euca/faststart.ini; then
        echo "Could not find Eucalyptus (localhost) Region Eucalyptus Administrator (admin) Euca2ools user!"
        echo "Expected to find: [user [0-9]*:admin] in ~/.euca/faststart.ini"
        exit 50
    fi
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
echo "$(printf '%2d' $step). Convert FastStart Credentials to Demo Conventions"
echo "    - This section splits the \"localhost\" Region configuration file created"
echo "      by FastStart into a convention which allows for multiple named Regions"
echo "    - We preserve the original \"localhost\" Region configuration file installed"
echo "      with Eucalyptus, so that we can restore this later once a specific Region"
echo "      is configured."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save"
echo
echo "sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
echo "       -e \"s/[0-9]*:admin/localhost-admin/\" \\"
echo "       -e \"/^\\[region/,/^\\user =/p\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini"
echo
echo "sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
echo "       -e \"s/[0-9]*:admin/localhost-admin/\" \\"
echo "       -e \"/^\\[user/,/^account-id =/p\" \\"
echo "       -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini"
echo
echo "cat <<EOF > ~/.euca/global.ini"
echo "; Eucalyptus Global"
echo
echo "[global]"
echo "default-region = localhost"
echo
echo "EOF"
echo
echo "mkdir -p ~/.creds/localhost/eucalyptus/admin"
echo
echo "cat <<EOF > ~/.creds/localhost/eucalyptus/admin/iamrc"
echo "AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.in 2> /dev/null)"
echo "AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null)"
echo "EOF"
echo
echo "rm -f ~/.euca/faststart.ini"
 
if [ ! -r ~/.euca/faststart.ini ]; then
    echo
    tput rev
    echo "Already Converted!"
    tput sgr0
 
    next 50
 
else
    run 50
 
    if [ $choice = y ]; then
        echo
        echo "# cp -f /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save"
        cp -a /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.save
        pause

        echo "# sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
        echo ">        -e \"s/[0-9]*:admin/localhost-admin/\" \\"
        echo ">        -e \"/^\\[region/,/^\\user =/p\" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini"
        sed -n -e "1i; Eucalyptus Region localhost\n" \
               -e "s/[0-9]*:admin/localhost-admin/" \
               -e "/^\[region/,/^\user =/p" ~/.euca/faststart.ini > /etc/euca2ools/conf.d/localhost.ini
        pause
 
        echo "# sed -n -e \"1i; Eucalyptus Region localhost\\n\" \\"
        echo ">        -e \"s/[0-9]*:admin/localhost-admin/\" \\"
        echo ">        -e \"/^\\[user/,/^account-id =/p\" \\"
        echo ">        -e \"\\\$a\\\\\\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini"
        sed -n -e "1i; Eucalyptus Region localhost\n" \
               -e "s/[0-9]*:admin/localhost-admin/" \
               -e "/^\[user/,/^account-id =/p" \
               -e "\$a\\\\" ~/.euca/faststart.ini > ~/.euca/localhost.ini
        pause
 
        echo "cat <<EOF > ~/.euca/global.ini"
        echo "; Eucalyptus Global"
        echo
        echo "[global]"
        echo "default-region = localhost"
        echo
        echo "EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Global"         > ~/.euca/global.ini
        echo                              >> ~/.euca/global.ini
        echo "[global]"                   >> ~/.euca/global.ini
        echo "default-region = localhost" >> ~/.euca/global.ini
        echo                              >> ~/.euca/global.ini
        pause
 
        echo "# mkdir -p ~/.creds/localhost/eucalyptus/admin"
        mkdir -p ~/.creds/localhost/eucalyptus/admin
        pause
 
        echo "# cat <<EOF > ~/.creds/localhost/eucalyptus/admin/iamrc"
        echo "> AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)"
        echo "> AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null)"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo AWSAccessKeyId=$(sed -n -e 's/key-id = //p' ~/.euca/faststart.ini 2> /dev/null)    > ~/.creds/localhost/eucalyptus/admin/iamrc
        echo AWSSecretKey=$(sed -n -e 's/secret-key = //p' ~/.euca/faststart.ini 2> /dev/null) >> ~/.creds/localhost/eucalyptus/admin/iamrc
        pause
 
        echo "# rm -f ~/.euca/faststart.ini"
        rm -f ~/.euca/faststart.ini
 
        next
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Region"
echo "    - FastStart creates a \"localhost\" Region by default"
echo "    - We will switch this to a more \"AWS-like\" Region naming convention"
echo "    - This is needed to run CloudFormation templates which reference the"
echo "      Region in Maps"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl region.region_name=$region --region localhost"

if [ "$(euctl -n region.region_name --region localhost)" = "$region" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl region.region_name=$region --region localhost"
        euctl region.region_name=$region --region localhost

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Eucalyptus DNS Server"
echo "    - Instances will use the Cloud Controller's DNS Server directly"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl system.dns.nameserver=ns1.$region.$domain --region localhost"
echo
echo "euctl system.dns.nameserveraddress=$(hostname -i) --region localhost"

if [ "$(euctl -n system.dns.nameserver --region localhost | head -1)" = "ns1.$region.$domain" -a \
     "$(euctl -n system.dns.nameserveraddress --region localhost)" = "$(hostname -i)" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl system.dns.nameserver=ns1.$region.$domain --region localhost"
        euctl system.dns.nameserver=ns1.$region.$domain --region localhost
        echo "#"
        echo "# euctl system.dns.nameserveraddress=$(hostname -i) --region localhost"
        euctl system.dns.nameserveraddress=$(hostname -i) --region localhost

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Timeout and TTL"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl dns.tcp.timeout_seconds=$dns_timeout --region localhost"
echo
echo "euctl services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl --region localhost"

if [ "$(euctl -n dns.tcp.timeout_seconds --region localhost)" = "$dns_timeout" -a \
     "$(euctl -n services.loadbalancing.dns_ttl --region localhost)" = "$dns_loadbalancer_ttl" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0

    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl dns.tcp.timeout_seconds=$dns_timeout --region localhost"
        euctl dns.tcp.timeout_seconds=$dns_timeout --region localhost
        echo "#"
        echo "# euctl services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl --region localhost"
        euctl services.loadbalancing.dns_ttl=$dns_loadbalancer_ttl --region localhost

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Domain"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl system.dns.dnsdomain=$region.$domain --region localhost"

if [ "$(euctl -n system.dns.dnsdomain --region localhost)" = "$region.$domain" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl system.dns.dnsdomain=$region.$domain --region localhost"
        euctl system.dns.dnsdomain=$region.$domain --region localhost

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure DNS Sub-Domains"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl cloud.vmstate.instance_subdomain=$instance_subdomain --region localhost"
echo
echo "euctl services.loadbalancing.dns_subdomain=$loadbalancer_subdomain --region localhost"

if [ "$(euctl -n cloud.vmstate.instance_subdomain --region localhost)" = "$instance_subdomain" -a \
     "$(euctl -n services.loadbalancing.dns_subdomain --region localhost)" = "$loadbalancer_subdomain" ]; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50

else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl cloud.vmstate.instance_subdomain=$instance_subdomain --region localhost"
        euctl cloud.vmstate.instance_subdomain=$instance_subdomain --region localhost
        echo "#"
        echo "# euctl services.loadbalancing.dns_subdomain=$loadbalancer_subdomain --region localhost"
        euctl services.loadbalancing.dns_subdomain=$loadbalancer_subdomain --region localhost

        next 50
    fi
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Enable DNS"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euctl bootstrap.webservices.use_instance_dns=true --region localhost"
echo
echo "euctl bootstrap.webservices.use_dns_delegation=true --region localhost"

if [ "$(euctl -n bootstrap.webservices.use_instance_dns --region localhost)" = "true" -a \
     "$(euctl -n bootstrap.webservices.use_dns_delegation --region localhost)" = "true" ]; then
    echo
    tput rev
    echo "Already Enabled!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# euctl bootstrap.webservices.use_instance_dns=true --region localhost"
        euctl bootstrap.webservices.use_instance_dns=true --region localhost
        echo "#"
        echo "# euctl bootstrap.webservices.use_dns_delegation=true --region localhost"
        euctl bootstrap.webservices.use_dns_delegation=true --region localhost

        next 50
    fi
fi


((++step))
# Construct Eucalyptus Endpoints (assumes AWS-style URLs)
autoscaling_url=http://autoscaling.$region.$domain:8773/
bootstrap_url=http://bootstrap.$region.$domain:8773/
cloudformation_url=http://cloudformation.$region.$domain:8773/
ec2_url=http://ec2.$region.$domain:8773/
elasticloadbalancing_url=http://elasticloadbalancing.$region.$domain:8773/
iam_url=http://iam.$region.$domain:8773/
monitoring_url=http://monitoring.$region.$domain:8773/
properties_url=http://properties.$region.$domain:8773/
reporting_url=http://reporting.$region.$domain:8773/
s3_url=http://s3.$region.$domain:8773/
sts_url=http://sts.$region.$domain:8773/

clear
echo
echo "============================================================"
echo
echo "$(printf '%2d' $step). Configure Euca2ools Region for HTTP Endpoints"
echo "    - We must configure a new Region configuration, but"
echo "      can re-use the User configuration with a change to"
echo "      the Region name"
echo "    - Restore the original \"localhost\" Region saved in a"
echo "      prior step, as the modified \"localhost\" Region created"
echo "      by FastStart no longer works after changing DNS properties"
echo
echo "============================================================"
echo
echo "Commands:"
echo
echo "mv /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.faststart"
echo "mv /etc/euca2ools/conf.d/localhost.ini.save /etc/euca2ools/conf.d/localhost.ini"
echo "sed -i -e '/^user =/d;/^sts-url =/auser = localhost-admin' /etc/euca2ools/conf.d/localhost.ini"
echo
echo "cat << EOF > /etc/euca2ools/conf.d/$region.ini"
echo "; Eucalyptus Region $region"
echo
echo "[region $region]"
echo "autoscaling-url = $autoscaling_url"
echo "bootstrap-url = $bootstrap_url"
echo "cloudformation-url = $cloudformation_url"
echo "ec2-url = $ec2_url"
echo "elasticloadbalancing-url = $elasticloadbalancing_url"
echo "iam-url = $iam_url"
echo "monitoring-url = $monitoring_url"
echo "properties-url = $properties_url"
echo "reporting-url = $reporting_url"
echo "s3-url = $s3_url"
echo "sts-url = $sts_url"
echo "user = $region-admin"
echo
echo "EOF"
echo 
echo "sed -e \"s/localhost/$region/g\" ~/.euca/localhost.ini > ~/.euca/$region.ini"
echo 
echo "sed -i -e \"s/localhost/$region/g\" ~/.euca/global.ini"
echo
echo "mkdir -p ~/.creds/$region/eucalyptus/admin"
echo "cp -a ~/.creds/localhost/eucalyptus/admin/iamrc ~/.creds/$region/eucalyptus/admin"

if  grep -s -q "ec2-url = $ec2_url" /etc/euca2ools/conf.d/$region.ini; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        echo "# mv /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.faststart"
        mv /etc/euca2ools/conf.d/localhost.ini /etc/euca2ools/conf.d/localhost.ini.faststart
        echo "# mv /etc/euca2ools/conf.d/localhost.ini.save /etc/euca2ools/conf.d/localhost.ini"
        mv /etc/euca2ools/conf.d/localhost.ini.save /etc/euca2ools/conf.d/localhost.ini
        echo "# sed -i -e '/^user =/d;/^sts-url =/auser = localhost-admin' /etc/euca2ools/conf.d/localhost.ini"
        sed -i -e '/^user =/d;/^sts-url =/auser = localhost-admin' /etc/euca2ools/conf.d/localhost.ini
        pause

        echo "# cat << EOF > /etc/euca2ools/conf.d/$region.ini"
        echo "> ; Eucalyptus Region $region"
        echo ">"
        echo "> [region $region]"
        echo "> autoscaling-url = $autoscaling_url"
        echo "> cloudformation-url = $cloudformation_url"
        echo "> bootstrap-url = $bootstrap_url"
        echo "> ec2-url = $ec2_url"
        echo "> elasticloadbalancing-url = $elasticloadbalancing_url"
        echo "> iam-url = $iam_url"
        echo "> monitoring-url = $monitoring_url"
        echo "> properties-url = $properties_url"
        echo "> reporting-url = $reporting_url"
        echo "> s3-url = $s3_url"
        echo "> sts-url = $sts_url"
        echo "> user = $region-admin"
        echo ">"
        echo "> EOF"
        # Use echo instead of cat << EOF to better show indentation
        echo "; Eucalyptus Region $region"                               > /etc/euca2ools/conf.d/$region.ini
        echo                                                            >> /etc/euca2ools/conf.d/$region.ini
        echo "[region $region]"                                         >> /etc/euca2ools/conf.d/$region.ini
        echo "autoscaling-url = $autoscaling_url"                       >> /etc/euca2ools/conf.d/$region.ini
        echo "cloudformation-url = $cloudformation_url"                 >> /etc/euca2ools/conf.d/$region.ini
        echo "bootstrap-url = $bootstrap_url"                           >> /etc/euca2ools/conf.d/$region.ini
        echo "ec2-url = $ec2_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "elasticloadbalancing-url = $elasticloadbalancing_url"     >> /etc/euca2ools/conf.d/$region.ini
        echo "iam-url = $iam_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "monitoring-url = $monitoring_url"                         >> /etc/euca2ools/conf.d/$region.ini
        echo "properties-url = $properties_url"                         >> /etc/euca2ools/conf.d/$region.ini
        echo "reporting-url = $reporting_url"                           >> /etc/euca2ools/conf.d/$region.ini
        echo "s3-url = $s3_url"                                         >> /etc/euca2ools/conf.d/$region.ini
        echo "sts-url = $sts_url"                                       >> /etc/euca2ools/conf.d/$region.ini
        echo "user = $region-admin"                                     >> /etc/euca2ools/conf.d/$region.ini
        echo                                                            >> /etc/euca2ools/conf.d/$region.ini
        pause

        echo "# sed -e \"s/localhost/$region/g\" ~/.euca/localhost.ini > ~/.euca/$region.ini"
        sed -e "s/localhost/$region/g" ~/.euca/localhost.ini > ~/.euca/$region.ini
        pause

        echo "# sed -i -e \"s/localhost/$region/g\" ~/.euca/global.ini"
        sed -i -e "s/localhost/$region/g" ~/.euca/global.ini
        pause

        echo "# mkdir -p ~/.creds/$region/eucalyptus/admin"
        mkdir -p ~/.creds/$region/eucalyptus/admin
        echo "# cp -a ~/.creds/localhost/eucalyptus/admin/iamrc ~/.creds/$region/eucalyptus/admin"
        cp -a ~/.creds/localhost/eucalyptus/admin/iamrc ~/.creds/$region/eucalyptus/admin

        next
    fi
fi


((++step))
if [ $showdnsconfig = 1 ]; then
    clear
    echo
    echo "================================================================================"
    echo
    echo "$(printf '%2d' $step). Display Parent DNS Server Configuration"
    echo "    - This is an example of what changes need to be made on the"
    echo "      parent DNS server which will delgate DNS to Eucalyptus"
    echo "      for Eucalyptus DNS names used for instances, ELBs and"
    echo "      services"
    echo "    - You should make these changes to the parent DNS server"
    echo "      manually, once, outside of creating and running demos"
    echo "    - Instances will use the Cloud Controller's DNS Server directly"
    echo "    - This configuration is based on the BIND configuration"
    echo "      conventions used on the cs.prc.eucalyptus-systems.com DNS server"
    echo
    echo "================================================================================"
    echo
    echo "Commands:"
    echo
    echo "# Add these lines to /etc/named.conf on the parent DNS server"
    echo "         zone \"$region.$domain\" IN"
    echo "         {"
    echo "                 type master;"
    echo "                 file \"/etc/named/db.$aws_default_region\";"
    echo "         };"
    echo "#"
    echo "# Create the zone file on the parent DNS server"
    echo "> ;"
    echo "> ; DNS zone for $aws_default_region.$aws_default_domain"
    echo "> ; - Eucalyptus configured to use CLC as DNS server"
    echo ">"
    echo "# cat << EOF > /etc/named/db.$aws_default_region"
    echo "> $TTL 1M"
    echo "> $ORIGIN $aws_default_region.$aws_default_domain"
    echo "> @                       SOA     ns1 root ("
    echo ">                                 $(date +%Y%m%d)01      ; Serial"
    echo ">                                 1H              ; Refresh"
    echo ">                                 10M             ; Retry"
    echo ">                                 1D              ; Expire"
    echo ">                                 1H )            ; Negative Cache TTL"
    echo ">"
    echo ">                         NS      ns1"
    echo ">"
    echo "> ns1                     A       $(hostname -i)"
    echo ">"
    echo "> clc                     A       $(hostname -i)"
    echo "> ufs                     A       $(hostname -i)"
    echo "> mc                      A       $(hostname -i)"
    echo "> osp                     A       $(hostname -i)"
    echo "> walrus                  A       $(hostname -i)"
    echo "> cc                      A       $(hostname -i)"
    echo "> sc                      A       $(hostname -i)"
    echo "> ns1                     A       $(hostname -i)"
    echo ">"
    echo "> console                 A       $(hostname -i)"
    echo ">"
    echo "> autoscaling             A       $(hostname -i)"
    echo "> bootstrap               A       $(hostname -i)"
    echo "> cloudformation          A       $(hostname -i)"
    echo "> ec2                     A       $(hostname -i)"
    echo "> elasticloadbalancing    A       $(hostname -i)"
    echo "> iam                     A       $(hostname -i)"
    echo "> monitoring              A       $(hostname -i)"
    echo "> properties              A       $(hostname -i)"
    echo "> reporting               A       $(hostname -i)"
    echo "> s3                      A       $(hostname -i)"
    echo "> sts                     A       $(hostname -i)"
    echo ">"
    echo "> ${instance_subdomain#.}                   NS      ns1"
    echo "> ${loadbalancer_subdomain#.}                      NS      ns1"
    echo "> EOF"

    next 200
fi

    
((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm DNS resolution for Services"
echo "    - Confirm service URLS in eucarc resolve"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "dig +short autoscaling.$region.$domain"
echo
echo "dig +short bootstrap.$region.$domain"
echo
echo "dig +short cloudformation.$region.$domain"
echo
echo "dig +short ec2.$region.$domain"
echo
echo "dig +short elasticloadbalancing.$region.$domain"
echo
echo "dig +short iam.$region.$domain"
echo
echo "dig +short monitoring.$region.$domain"
echo
echo "dig +short properties.$region.$domain"
echo
echo "dig +short reporting.$region.$domain"
echo
echo "dig +short s3.$region.$domain"
echo
echo "dig +short sts.$region.$domain"

run 50

if [ $choice = y ]; then
    echo
    echo "# dig +short autoscaling.$region.$domain"
    dig +short autoscaling.$region.$domain
    pause

    echo "# dig +short bootstrap.$region.$domain"
    dig +short bootstrap.$region.$domain
    pause

    echo "# dig +short cloudformation.$region.$domain"
    dig +short cloudformation.$region.$domain
    pause

    echo "# dig +short ec2.$region.$domain"
    dig +short ec2.$region.$domain
    pause

    echo "# dig +short elasticloadbalancing.$region.$domain"
    dig +short elasticloadbalancing.$region.$domain
    pause

    echo "# dig +short iam.$region.$domain"
    dig +short iam.$region.$domain
    pause

    echo "# dig +short monitoring.$region.$domain"
    dig +short monitoring.$region.$domain
    pause

    echo "# dig +short properties.$region.$domain"
    dig +short properties.$region.$domain
    pause

    echo "# dig +short reporting.$region.$domain"
    dig +short reporting.$region.$domain
    pause

    echo "# dig +short s3.$region.$domain"
    dig +short s3.$region.$domain
    pause

    echo "# dig +short sts.$region.$domain"
    dig +short sts.$region.$domain

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Confirm API commands work with new URLs"
echo "    - Confirm service describe commands still work"
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "euca-describe-regions --region localhost"
echo
echo "euca-describe-regions --region $region-admin@$region"
if [ $extended = 1 ]; then
    echo
    echo "euca-describe-availability-zones --region $region-admin@$region"
    echo
    echo "euca-describe-keypairs --region $region-admin@$region"
    echo
    echo "euca-describe-images --region $region-admin@$region"
    echo
    echo "euca-describe-instance-types --region $region-admin@$region"
    echo
    echo "euca-describe-instances --region $region-admin@$region"
    echo
    echo "euca-describe-instance-status --region $region-admin@$region"
    echo
    echo "euca-describe-groups --region $region-admin@$region"
    echo
    echo "euca-describe-volumes --region $region-admin@$region"
    echo
    echo "euca-describe-snapshots --region $region-admin@$region"
fi
echo
echo "eulb-describe-lbs --region $region-admin@$region"
echo
echo "euform-describe-stacks --region $region-admin@$region"
echo
echo "euscale-describe-auto-scaling-groups --region $region-admin@$region"
if [ $extended = 1 ]; then
    echo
    echo "euscale-describe-launch-configs --region $region-admin@$region"
    echo
    echo "euscale-describe-auto-scaling-instances --region $region-admin@$region"
    echo
    echo "euscale-describe-policies --region $region-admin@$region"
fi
echo
echo "euwatch-describe-alarms --region $region-admin@$region"

run 50

if [ $choice = y ]; then
    echo
    echo "# euca-describe-regions --region localhost"
    euca-describe-regions --region localhost
    echo "#"
    echo "# euca-describe-regions --region $region-admin@$region"
    euca-describe-regions --region $region-admin@$region
    pause

    if [ $extended = 1 ]; then
        echo "# euca-describe-availability-zones --region $region-admin@$region"
        euca-describe-availability-zones --region $region-admin@$region
        pause

        echo "# euca-describe-keypairs --region $region-admin@$region"
        euca-describe-keypairs --region $region-admin@$region
        pause

        echo "# euca-describe-images --region $region-admin@$region"
        euca-describe-images --region $region-admin@$region
        pause

        echo "# euca-describe-instance-types --region $region-admin@$region"
        euca-describe-instance-types --region $region-admin@$region
        pause

        echo "# euca-describe-instances --region $region-admin@$region"
        euca-describe-instances --region $region-admin@$region
        pause

        echo "# euca-describe-instance-status --region $region-admin@$region"
        euca-describe-instance-status --region $region-admin@$region
        pause

        echo "# euca-describe-groups --region $region-admin@$region"
        euca-describe-groups --region $region-admin@$region
        pause

        echo "# euca-describe-volumes --region $region-admin@$region"
        euca-describe-volumes --region $region-admin@$region
        pause

        echo "# euca-describe-snapshots --region $region-admin@$region"
        euca-describe-snapshots --region $region-admin@$region
        pause
    fi

    echo
    echo "# eulb-describe-lbs --region $region-admin@$region"
    eulb-describe-lbs --region $region-admin@$region
    pause

    echo
    echo "# euform-describe-stacks --region $region-admin@$region"
    euform-describe-stacks --region $region-admin@$region
    pause

    echo
    echo "# euscale-describe-auto-scaling-groups --region $region-admin@$region"
    euscale-describe-auto-scaling-groups --region $region-admin@$region
    pause

    if [ $extended = 1 ]; then
        echo "# euscale-describe-launch-configs --region $region-admin@$region"
        euscale-describe-launch-configs --region $region-admin@$region
        pause

        echo "# euscale-describe-auto-scaling-instances --region $region-admin@$region"
        euscale-describe-auto-scaling-instances --region $region-admin@$region
        pause

        echo "# euscale-describe-policies --region $region-admin@$region"
        euscale-describe-policies --region $region-admin@$region
        pause
    fi

    echo
    echo "# euwatch-describe-alarms --region $region-admin@$region"
    euwatch-describe-alarms --region $region-admin@$region

    next
fi


((++step))
clear
echo
echo "================================================================================"
echo
echo "$(printf '%2d' $step). Configure Bash to use Eucalyptus Administrator Credentials"
echo "    - While it is possible to use the \"user@region\" convention when setting"
echo "      AWS_DEFAULT_REGION to work with Euca2ools, this breaks AWSCLI which doesn't"
echo "      understand that change to this environment variable format."
echo "    - By setting the variables defined below, both Euca2ools and AWSCLI"
echo "      can be used interchangably."
echo
echo "================================================================================"
echo
echo "Commands:"
echo
echo "echo \"export AWS_DEFAULT_REGION=$region\" >> ~/.bash_profile"
echo "echo \"export AWS_DEFAULT_PROFILE=\$region-admin\" >> ~/.bash_profile"
echo "echo \"export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$region/eucalyptus/admin/iamrc\" >> ~/.bash_profile"

if grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
    echo
    tput rev
    echo "Already Configured!"
    tput sgr0
 
    next 50
 
else
    run 50

    if [ $choice = y ]; then
        echo
        echo >> ~/.bash_profile
        echo "# echo \"export AWS_DEFAULT_REGION=$region\" >> ~/.bash_profile"
        echo "export AWS_DEFAULT_REGION=$region" >> ~/.bash_profile
        echo "#"
        echo "# echo \"export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin\" >> ~/.bash_profile"
        echo "export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin" >> ~/.bash_profile
        echo "#"
        echo "# echo \"export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc\" >> ~/.bash_profile"
        echo "export AWS_CREDENTIAL_FILE=\$HOME/.creds/\$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc" >> ~/.bash_profile

        next
    fi
fi


end=$(date +%s)

echo
case $(uname) in
  Darwin)
    echo "Eucalyptus DNS configured (time: $(date -u -r $((end-start)) +"%T"))";;
  *)
    echo "Eucalyptus DNS configured (time: $(date -u -d @$((end-start)) +"%T"))";;
esac
