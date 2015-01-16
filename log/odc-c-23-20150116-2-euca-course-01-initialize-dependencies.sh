[root@odc-c-23 bin]# euca-course-01-initialize-dependencies.sh

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
 * extras: mirror.spro.net
Package bridge-utils-1.2-10.el6.x86_64 already installed and latest version
Nothing to do

Continue (y,n,q)[y]

============================================================

 2. Create bridge
    - This step is only run on the node controller host
    - This bridge connects between the public ethernet adapter
      and virtual machine instance virtual ethernet adapters

============================================================

Commands:

echo << EOF > /etc/sysconfig/network-scripts/ifcfg-br0
DEVICE=br0
TYPE=Bridge
BOOTPROTO=dhcp
PERSISTENT_DHCLIENT=yes
ONBOOT=yes
DELAY=0
EOF

Execute (y,n,q)[y]

# echo << EOF > /etc/sysconfig/network-scripts/ifcfg-br0
> DEVICE=br0
> TYPE=Bridge
> BOOTPROTO=dhcp
> PERSISTENT_DHCLIENT=yes
> ONBOOT=yes
> DELAY=0
> EOF

Continue (y,n,q)[y]

============================================================

 3. Adjust public ethernet interface
    - This step is only run on the node controller host
    - Associate the interface with the bridge
    - Remove the interface's IP address (moves to bridge)

============================================================

Commands:

sed -i -e "\$aBRIDGE=br0" \
       -e "/^BOOTPROTO=/s/=.*$/=none/" \
       -e "/^PERSISTENT_DHCLIENT=/d" \
       -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-em1

Execute (y,n,q)[y]

# sed -i -e "\$aBRIDGE=br0" \
>        -e "/^BOOTPROTO=/s/=.*$/=none/" \
>        -e "/^PERSISTENT_DHCLIENT=/d" \
>        -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-em1

Continue (y,n,q)[y]

============================================================

 4. Restart networking
    - This step is only run on the node controller host
    - Can lose connectivity here, make sure you have alternate way in

============================================================

Commands:

service network restart

Execute (y,n,q)[y]

# service network restart
Shutting down interface em1:  bridge br0 does not exist!
                                                           [  OK  ]
Shutting down interface em2:                               [  OK  ]
Shutting down loopback interface:                          [  OK  ]
Bringing up loopback interface:                            [  OK  ]
Bringing up interface em1:                                 [  OK  ]
Bringing up interface em2:  Determining if ip address 10.105.10.23 is already in use for device em2...
                                                           [  OK  ]
Bringing up interface br0:  
Determining IP information for br0... done.
                                                           [  OK  ]

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
 * extras: mirror.spro.net
Package ntp-4.2.6p5-2.el6.centos.x86_64 already installed and latest version
Nothing to do
#
# chkconfig ntpd on
# service ntpd start
Starting ntpd:                                             [  OK  ]
#
# ntpdate -u  0.centos.pool.ntp.org
16 Jan 00:27:10 ntpdate[25331]: adjust time server 208.75.89.4 offset -0.332502 sec
# hwclock --systohc

Continue (y,n,q)[y]

============================================================

 8. Configure packet routing

============================================================

Commands:

sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

sysctl -p

cat /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/bridge/bridge-nf-call-iptables

Execute (y,n,q)[y]

# sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
# sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf
#
# sysctl -p
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 0
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#
# cat /proc/sys/net/ipv4/ip_forward
1
cat /proc/sys/net/bridge/bridge-nf-call-iptables
1

Continue (y,n,q)[y]

Dependencies initialized
