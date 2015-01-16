[root@odc-c-21 bin]# euca-course-01-initialize-dependencies.sh 

============================================================

 1. Install bridge utilities package
    - This step is only run on the cluster and node controller hosts

============================================================

Commands:

yum -y install bridge-utils

Execute (y,n,q)[y]

# yum -y install bridge-utils
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: repos.dfw.quadranet.com
Package bridge-utils-1.2-10.el6.x86_64 already installed and latest version
Nothing to do

Continue (y,n,q)[y]

============================================================

 5. Disable firewall
    - To prevent unexpected issues
    - Can be re-enabled after setup with appropriate ports open

============================================================

Commands:

service iptables stop

Execute (y,n,q)[y]

# service iptables stop

Continue (y,n,q)[y]

============================================================

 6. Disable SELinux

============================================================

Commands:

sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

setenforce 0

Execute (y,n,q)[y]

# sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config
#
# setenforce 0
setenforce: SELinux is disabled

Continue (y,n,q)[y]

============================================================

 7. Install and Configure the NTP service
    - It is critical that NTP be running and accurate on all hosts

============================================================

Commands:

yum -y install ntp

chkconfig ntpd on
service ntpd start

ntpdate -u  0.centos.pool.ntp.org
hwclock --systohc

Execute (y,n,q)[y]

# yum -y install ntp
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: repos.dfw.quadranet.com
Package ntp-4.2.6p5-2.el6.centos.x86_64 already installed and latest version
Nothing to do
#
# chkconfig ntpd on
# service ntpd start
Starting ntpd:                                             [  OK  ]
#
# ntpdate -u  0.centos.pool.ntp.org
16 Jan 00:27:07 ntpdate[24770]: adjust time server 208.75.89.4 offset -0.429419 sec
# hwclock --systohc

Continue (y,n,q)[y]

============================================================

 8. Configure packet routing

============================================================

Commands:

sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

sysctl -p

cat /proc/sys/net/ipv4/ip_forward

Execute (y,n,q)[y]

# sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
#
# sysctl -p
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#
# cat /proc/sys/net/ipv4/ip_forward
1

Continue (y,n,q)[y]

Dependencies initialized
