#!/bin/bash -eux
#
# Script to configure demo-05 instances - version 2
#
# This is a script meant to be run via cloud-init to do simple initial configuration
# of the Demo 05 Instances created by the associated LaunchConfiguration and 
# AutoScaleGroup.
#

# fix hostname to be more AWS like
local_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/local-ipv4)
public_ipv4=$(curl -qs http://169.254.169.254/latest/meta-data/public-ipv4)
hostname=ip-${local_ipv4//./-}.prc.eucalyptus-systems.com
sed -i -e "s/HOSTNAME=.*/HOSTNAME=$hostname/" /etc/sysconfig/network
hostname $hostname

# setup hosts
cat << EOF >> /etc/hosts
$local_ipv4      $hostname ${hostname%%.*}
EOF

# Install Apache
yum install -y httpd mod_ssl

# Configure Apache to display a test page showing the host internal IP address
cat << EOF >> /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Demo 05, Version 2!</title>
<style>
    body {
        width: 50em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Demo 05, Version 2!</h1>

<p>You're viewing a website running on the host with internal address: $(hostname)</p>
</body>
</html>
EOF

# Configure Apache to start on boot
chkconfig httpd on
service httpd start

# Allow web traffic through the firewall
cat << EOF > /tmp/iptables_www_$$.sed
/^-A INPUT -j REJECT/i\\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT\\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
EOF

grep -q "dport 80" /etc/sysconfig/iptables ||
sed -i -f /tmp/iptables_www_$$.sed /etc/sysconfig/iptables

rm -f /tmp/iptables_www_$$.sed

service iptables restart

