[root@odc-f-33 bin]# euca-faststart-01-install.sh -I; date

============================================================

  1. Install
    - Responses to questions:
      Laptop power warning: Continue?                          <enter>
      DHCP warning: Continue Anyway?                           y
      What's the physical NIC that will be used for bridging?  <enter>
      What's the IP address of this host?                      <enter>
      What's the gateway for this host?                        <enter>
      What's the netmask for this host?                        <enter>
      What's the subnet for this host?                         <enter>
      What's the first address of your available IP range?     10.104.45.129
      What's the last address of your available IP range?      10.104.45.254
      Install additional services? [Y/n]                       <enter>

============================================================

Commands:

bash <(curl -Ls eucalyptus.com/install)

Continuing in  1 seconds...

# bash <(curl -Ls eucalyptus.com/install)
NOTE: if you're running on a laptop, you might want to make sure that
you have turned off sleep/ACPI in your BIOS.  If the laptop goes to sleep,
virtual machines could terminate.

Continue? [Y/n]
y

[Precheck] Checking root
[Precheck] OK, running as root

[Precheck] Checking curl version
[Precheck] OK, curl is up to date

package eucalyptus is not installed
[Precheck] Checking OS
[Precheck] OK, OS is supported

package PackageKit is not installed
package NetworkManager is not installed
[Precheck] Checking hardware virtualization
[Precheck] OK, processor supports virtualization

[Precheck] Checking if Chef Client is installed
/usr/bin/chef-solo
[Precheck] OK, Chef Client is installed

[Precheck] Identifying primary network interface
wlan0: error fetching interface information: Device not found
Active network interface em1 found
[Precheck] OK, network interfaces checked.

BOOTPROTO=dhcp
=====
WARNING: we recommend configuring Eucalypus servers to use
a static IP address. This system is configured to use DHCP,
which will cause problems if you lose the DHCP lease for this
system.

Continue anyway? [y/N]
y
[Precheck] OK, running a full update of the OS. This could take a bit; please wait.
To see the update in progress, run the following command in another terminal:

  tail -f /var/log/euca-install-01.16.2015-00.24.20.log

[Precheck] Package update in progress...
Loaded plugins: fastestmirror, security
Setting up Update Process
Loading mirror speeds from cached hostfile
 * extras: mirrors.sonic.net
No Packages marked for Update
[Precheck] Precheck successful.


[Prep] Removing old Chef templates
[Prep] Downloading necessary cookbooks
~/cookbooks ~
remote: Counting objects: 3139, done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 3139 (delta 1), reused 0 (delta 0)
Receiving objects: 100% (3139/3139), 563.48 KiB | 305 KiB/s, done.
Resolving deltas: 100% (2086/2086), done.
remote: Counting objects: 1509, done.
remote: Total 1509 (delta 0), reused 0 (delta 0)
Receiving objects: 100% (1509/1509), 316.94 KiB | 255 KiB/s, done.
Resolving deltas: 100% (661/661), done.
remote: Counting objects: 197, done.
remote: Total 197 (delta 0), reused 0 (delta 0)
Receiving objects: 100% (197/197), 31.16 KiB, done.
Resolving deltas: 100% (99/99), done.
remote: Counting objects: 967, done.
remote: Total 967 (delta 0), reused 0 (delta 0)
Receiving objects: 100% (967/967), 204.30 KiB | 180 KiB/s, done.
Resolving deltas: 100% (395/395), done.
~
[Prep] Tarring up cookbooks
=====

Welcome to the Faststart installer!

We're about to turn this system into a single-system Eucalyptus cloud.

Note: it's STRONGLY suggested that you accept the default values where
they are provided, unless you know that the values are incorrect.

What's the physical NIC that will be used for bridging? (em1)

NIC=em1

What's the IP address of this host? (10.104.10.75)

IPADDR=10.104.10.75

What's the gateway for this host? (10.104.0.1)

GATEWAY=10.104.0.1

What's the netmask for this host? (255.255.0.0)

NETMASK=255.255.0.0

What's the subnet for this host? (10.104.0.0)

SUBNET=10.104.0.0

You must now specify a range of IP addresses that are free
for Eucalyptus to use.  These IP addresses should not be
taken up by any other machines, and should not be in any
DHCP address pools.  Faststart will split this range into
public and private IP addresses, which will then be used
by Eucalyptus instances.  Please specify a range of at least
10 IP addresses.

What's the first address of your available IP range?
10.104.45.129
What's the last address of your available IP range?
10.104.45.254
OK, IP range is good
  Public range will be:   10.104.45.129 - 10.104.45.191
  Private range will be   10.104.45.192 - 10.104.45.254

Do you wish to install the optional load balancer and image
management services? This add 10-15 minutes to the installation.
Install additional services? [Y/n]

OK, additional services will be installed.


[Installing Eucalyptus]

If you want to watch the progress of this installation, you can check the
log file by running the following command in another terminal:

  tail -f /var/log/euca-install-01.16.2015-00.24.20.log

Your cloud-in-a-box should be installed in 30-45 minutes. Go have a cup of coffee!


   ) )     
    ( (    
  ........ 
  |      |]
  \      / 
   ------  


[Config] Enabling web console
EUARE_URL environment variable is deprecated; use AWS_IAM_URL instead
[Config] Adding ssh and http to default security group
GROUP   default
PERMISSION      default ALLOWS  tcp     22      22      FROM    CIDR    0.0.0.0/0
GROUP   default
PERMISSION      default ALLOWS  tcp     80      80      FROM    CIDR    0.0.0.0/0


[SUCCESS] Eucalyptus installation complete!
Time to install: 0:26:22
To log in to the Management Console, go to:
http://10.104.10.75:8888/

User Credentials:
  * Account: eucalyptus
  * Username: admin
  * Password: password

If you are new to Eucalyptus, we strongly recommend that you run
the Eucalyptus tutorial now:

  cd /root/cookbooks/eucalyptus/faststart/tutorials
  ./master-tutorial.sh

Thanks for installing Eucalyptus!

Continuing in  1 seconds...

============================================================

  2. Move Credentials into Demo Directory Structure
    - We need to create additional accounts and users, so move
      the Eucalyptus Administrator credentials into a more
      hierarchical credentials storage directory structure

============================================================

Commands:

mkdir -p /root/creds/eucalyptus/admin
unzip /root/admin.zip -d /root/creds/eucalyptus/admin/

source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

# mkdir -p /root/creds/eucalyptus/admin
# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
Archive:  /root/admin.zip
To setup the environment run: source /path/to/eucarc
  inflating: /root/creds/eucalyptus/admin/eucarc  
  inflating: /root/creds/eucalyptus/admin/iamrc  
  inflating: /root/creds/eucalyptus/admin/cloud-cert.pem  
  inflating: /root/creds/eucalyptus/admin/jssecacerts  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-9338b759-pk.pem  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-9338b759-cert.pem  
#
# source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

============================================================

 3. Confirm Public IP addresses

============================================================

Commands:

euca-describe-addresses verbose

Continuing in  1 seconds...

# euca-describe-addresses verbose
ADDRESS 10.104.45.150   i-3ee9f38b (arn:aws:euare::000000000000:user/eucalyptus)        standard
ADDRESS 10.104.45.156   nobody  standard
ADDRESS 10.104.45.154   nobody  standard
ADDRESS 10.104.45.178   nobody  standard
ADDRESS 10.104.45.160   nobody  standard
ADDRESS 10.104.45.149   nobody  standard
ADDRESS 10.104.45.175   nobody  standard
ADDRESS 10.104.45.164   nobody  standard
ADDRESS 10.104.45.148   nobody  standard
ADDRESS 10.104.45.134   nobody  standard
ADDRESS 10.104.45.189   nobody  standard
ADDRESS 10.104.45.142   nobody  standard
ADDRESS 10.104.45.168   nobody  standard
ADDRESS 10.104.45.158   nobody  standard
ADDRESS 10.104.45.170   nobody  standard
ADDRESS 10.104.45.138   nobody  standard
ADDRESS 10.104.45.177   nobody  standard
ADDRESS 10.104.45.179   nobody  standard
ADDRESS 10.104.45.155   nobody  standard
ADDRESS 10.104.45.190   nobody  standard
ADDRESS 10.104.45.184   nobody  standard
ADDRESS 10.104.45.169   nobody  standard
ADDRESS 10.104.45.188   nobody  standard
ADDRESS 10.104.45.145   nobody  standard
ADDRESS 10.104.45.185   nobody  standard
ADDRESS 10.104.45.174   nobody  standard
ADDRESS 10.104.45.152   nobody  standard
ADDRESS 10.104.45.183   nobody  standard
ADDRESS 10.104.45.182   nobody  standard
ADDRESS 10.104.45.135   nobody  standard
ADDRESS 10.104.45.137   nobody  standard
ADDRESS 10.104.45.153   nobody  standard
ADDRESS 10.104.45.161   nobody  standard
ADDRESS 10.104.45.144   nobody  standard
ADDRESS 10.104.45.132   nobody  standard
ADDRESS 10.104.45.159   nobody  standard
ADDRESS 10.104.45.173   nobody  standard
ADDRESS 10.104.45.163   nobody  standard
ADDRESS 10.104.45.166   nobody  standard
ADDRESS 10.104.45.130   nobody  standard
ADDRESS 10.104.45.141   nobody  standard
ADDRESS 10.104.45.191   nobody  standard
ADDRESS 10.104.45.162   nobody  standard
ADDRESS 10.104.45.133   nobody  standard
ADDRESS 10.104.45.143   nobody  standard
ADDRESS 10.104.45.146   nobody  standard
ADDRESS 10.104.45.151   nobody  standard
ADDRESS 10.104.45.186   nobody  standard
ADDRESS 10.104.45.176   nobody  standard
ADDRESS 10.104.45.129   nobody  standard
ADDRESS 10.104.45.167   nobody  standard
ADDRESS 10.104.45.131   nobody  standard
ADDRESS 10.104.45.147   nobody  standard
ADDRESS 10.104.45.172   nobody  standard
ADDRESS 10.104.45.171   nobody  standard
ADDRESS 10.104.45.136   nobody  standard
ADDRESS 10.104.45.139   nobody  standard
ADDRESS 10.104.45.180   nobody  standard
ADDRESS 10.104.45.165   nobody  standard
ADDRESS 10.104.45.187   nobody  standard
ADDRESS 10.104.45.181   nobody  standard
ADDRESS 10.104.45.140   nobody  standard
ADDRESS 10.104.45.157   nobody  standard

Continuing in  1 seconds...

============================================================

 4. Confirm service status
    - Truncating normal output for readability

============================================================

Commands:

euca-describe-services | cut -f1-5

Continuing in  1 seconds...

# euca-describe-services | cut -f1-5
SERVICE user-api                API_10.104.10.75        API_10.104.10.75        ENABLED 
SERVICE autoscaling             API_10.104.10.75        API_10.104.10.75.autoscaling    ENABLED 
SERVICE cloudwatch              API_10.104.10.75        API_10.104.10.75.cloudwatch     ENABLED 
SERVICE compute                 API_10.104.10.75        API_10.104.10.75.compute        ENABLED 
SERVICE euare                   API_10.104.10.75        API_10.104.10.75.euare  ENABLED 
SERVICE loadbalancing           API_10.104.10.75        API_10.104.10.75.loadbalancing  ENABLED 
SERVICE objectstorage           API_10.104.10.75        API_10.104.10.75.objectstorage  ENABLED 
SERVICE tokens                  API_10.104.10.75        API_10.104.10.75.tokens ENABLED 
SERVICE bootstrap               bootstrap       10.104.10.75            ENABLED 
SERVICE reporting               bootstrap       10.104.10.75            ENABLED 
SERVICE cluster                 default         default-cc-1            ENABLED 
SERVICE storage                 default         default-sc-1            ENABLED 
SERVICE dns                     eucalyptus      10.104.10.75            ENABLED 
SERVICE loadbalancingbackend    eucalyptus      10.104.10.75            ENABLED 
SERVICE eucalyptus              eucalyptus      10.104.10.75            ENABLED 
SERVICE imaging                 eucalyptus      10.104.10.75            ENABLED 
SERVICE autoscalingbackend      eucalyptus      10.104.10.75            ENABLED 
SERVICE notifications           eucalyptus      10.104.10.75            ENABLED 
SERVICE cloudwatchbackend       eucalyptus      10.104.10.75            ENABLED 
SERVICE jetty                   eucalyptus      10.104.10.75            ENABLED 
SERVICE walrusbackend           walrus          walrus-1                ENABLED 

Continuing in  1 seconds...

Eucalyptus installed
Fri Jan 16 00:51:55 PST 2015
