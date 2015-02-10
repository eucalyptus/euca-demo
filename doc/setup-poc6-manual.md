Region hp-gol-d1 Manual Installation
====================================

This is going to be the manual steps to setup region hp-gol-d1, based on the "4-node reference architecture".

This will use hp-gol-d1 as the EUCA_REGION.

The full parent DNS domain will be hp-gol-d1.mjc.prc.eucalyptus-systems.com.

This is using the following nodes in the PRC:
- odc-d-13: CLC
- odc-d-14: UFS, MC
- odc-d-15: CC, SC
- odc-d-29: OSP
- odc-d-35: NC1
- odc-d-38: NC2

I'm also slowly trying to author procedures to run within a normal user account, and use sudo when necessary.
This manual procedure is partially into that process.

## Prepare Network

CLC:  1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT" >> /etc/sysconfig/iptables # Credentials (CLC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables # DNS
    echo "-A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables # DNS

UFS:  1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT" >> /etc/sysconfig/iptables # Database (CLC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)

MC:   1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT" >> /etc/sysconfig/iptables
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT" >> /etc/sysconfig/iptables

CC:   1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8774 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)

SC:   1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)

OSG:  1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)

NC*:  1. Reserve Ports Used by Eucalyptus

    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8775 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (NC)
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
    echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 16514 -j ACCEPT" >> /etc/sysconfig/iptables # TLS, needed for node migrations (NC)

ALL:  2. Verify Connectivity

1. Verify connection from an end-user to the CLC on TCP ports 8443 and 8773
2. Verify connection from an end-user to Walrus on TCP port 8773
3. Verify connection from the CLC, SC, and NC (or VB) to SC on TCP port 8773
4. Verify connection from the CLC, SC, and NC (or VB) to Walrus on TCP port 8773
5. Verify connection from Walrus, SC, and VB to CLC on TCP port 8777
6. Verify connection from CLC to CC on TCP port 8774
7. Verify connection from CC to VB on TCP port 8773
8. Verify connection from CC to NC on TCP port 8775
9. Verify connection from NC (or VB) to Walrus on TCP port 8773.
   Or, you can verify the connection from the CC to Walrus on port TCP 8773, and from an NC to the CC on TCP port 8776
10. Verify connection from public IP addresses of Eucalyptus instances (metadata) and CC to CLC on TCP port 8773
11. Verify TCP connectivity between CLC, Walrus, SC and VB on TCP port 8779 (or the first available port in range 8779-8849)
12. Verify connection between CLC, Walrus, SC, and VB on UDP port 7500
13. Verify multicast connectivity for IP address 228.7.7.3 between CLC, Walrus, SC, and VB on UDP port 8773
14. If DNS is enabled, verify connection from an end-user and instance IPs to DNS ports
15. If you use tgt (iSCSI open source target) for EBS storage, verify connection from NC to SC on TCP port 3260
16. If you use VMware with Eucalyptus, verify the connection from the VMware Broker to VMware (ESX, VSphere).
17. Test multicast connectivity between each CLC and Walrus, SC, and VMware broker host.

CLC, CC, SC, OSG:  3. Run tomography tool

    mkdir -p ~/src/eucalyptus
    cd ~/src/eucalyptus
    git clone https://github.com/eucalyptus/deveutils

    cd deveutils/network-tomography
    ./network-tomography 10.104.10.83 10.104.10.84 10.104.10.85 10.104.1.208

CLC:  4. Scan for unknown SSH host keys (sudo tee needed to append output to file owned by root)

    ssh-keyscan 10.104.10.83 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan 10.104.10.84 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan 10.104.10.85 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan 10.104.1.208 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan 10.104.1.190 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan 10.104.1.187 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null


## Prepare External DNS

I will not describe this in detail yet, except to note that this must be in place and working properly 
before registering services with the method outlined below, as I will be using DNS names for the services
so they look more AWS-like.

You should be able to resolve:
hp-gol-d1.mjc.prc.eucalyptus-systems.com: 10.104.10.84

clc.hp-gol-d1.mjc.prc.eucalyptus-systems.com: 10.104.10.83
more...


## Initialize Dependencies

1. (NC*): Install bridge utilities package

    sudo yum -y install bridge-utils

2. (NC*): Create Private Bridge
Move the static IP of em2 to the bridge

    private_interface=em2
    private_ip=$(sed -n -e "s/^IPADDR=//p" /etc/sysconfig/network-scripts/ifcfg-$private_interface)
    private_netmask=$(sed -n -e "s/^NETMASK=//p" /etc/sysconfig/network-scripts/ifcfg-$private_interface)
    private_dns1=$(sed -n -e "s/^DNS1=//p" /etc/sysconfig/network-scripts/ifcfg-$private_interface)
    private_dns2=$(sed -n -e "s/^DNS2=//p" /etc/sysconfig/network-scripts/ifcfg-$private_interface)
    private_bridge=br0    

    cat << EOF | sudo tee /etc/sysconfig/network-scripts/ifcfg-$private_bridge > /dev/null
    DEVICE=$private_bridge
    TYPE=Bridge
    BOOTPROTO=static
    IPADDR=$private_ip
    NETMASK=$private_netmask
    DNS1=$private_dns1
    DNS2=$private_dns2
    PERSISTENT_DHCLIENT=yes
    ONBOOT=yes
    DELAY=0
    EOF

3. (NC*): Convert Private Ethernet Interface to Private Bridge Slave

    sudo sed -i -e "\$aBRIDGE=$private_bridge" \
                -e "/^BOOTPROTO=/s/=.*$/=none/" \
                -e "/^IPADDR=/d" \
                -e "/^NETMASK=/d" \
                -e "/^PERSISTENT_DHCLIENT=/d" \
                -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-$private_interface

4. (NC*): Restart networking

    sudo service network restart

5. (ALL): Disable firewall

    sudo service iptables stop

6. (ALL): Disable SELinux

    sudo sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    sudo setenforce 0

7. (ALL): Install and Configure the NTP service

    sudo yum -y install ntp

    sudo chkconfig ntpd on
    sudo service ntpd start

    sudo ntpdate -u  0.centos.pool.ntp.org
    sudo hwclock --systohc

8. (CLC) Install and Configure Mail Relay

    TBD - see existing Postfix null client configurations

9. (NC*): Configure packet routing

    sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        sudo sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf
    fi

    sudo sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        cat /proc/sys/net/bridge/bridge-nf-call-iptables
    fi

10. (ALL): Install subscriber license (optional, for subscriber-only packages)
Note CS has a license for internal use, so this will obtain and use that license from where
I have placed it on my local mirror:

    wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/CS-Team-Unlimited-1.4.0.tgz \
         -O /tmp/CS-Team-Unlimited-1.4.0.tgz

    cd /tmp
    tar xvfz CS-Team-Unlimited-1.4.0.tgz


## Install Eucalyptus

ALL:  1. Configure yum repositories (second set of statements optional for subscriber-licensed packages)

    sudo yum install -y \
             http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
             http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
             http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm

```
Not working right now
    sudo yum install -y /tmp/CS-Team-Unlimited-1.4.0/eucalyptus-enterprise-release-4.0-1.CS_Team.Unlimited.noarch.rpm
    sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.0-1.el6.noarch.rpm
    sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm
```

ALL:  1. Override external yum repos to internal servers

    sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/eucalyptus.repo
    sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/euca2ools.repo


CLC:  2. Install packages

    sudo yum install -y eucalyptus-cloud
    sudo yum install -y eucalyptus-service-image

UFC:  2. Install packages

    sudo yum install -y eucalyptus-cloud

MC:   2. Install packages

    sudo yum install -y eucaconsole

CC:   2. Install packages

    sudo yum install -y eucalyptus-cc

SC:   2. Install packages

    sudo yum install -y eucalyptus-sc

OSP:  2. Install packages

    sudo yum install -y eucalyptus-walrus

NC*:  2. Install packages (note eucalyptus-nc has eucanetd as dependency)

    sudo yum install -y eucalyptus-nc

NC*:  3. Remove Devfault libvirt network.

    sudo virsh net-destroy default
    sudo virsh net-autostart default --disable

NC*:  4. Confirm KVM device node permissions.

    ls -l /dev/kvm  # should be owned by root:kvm


## Configure Eucalyptus

CLC:  1. Configure Eucalyptus Networking

    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    em1_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em1$/\1/p')
    em2_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em2$/\1/p')
    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$em2_ip\"/" /etc/eucalyptus/eucalyptus.conf

UFS,MC:  1. Configure Eucalyptus Networking

    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    em1_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em1$/\1/p')
    em2_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em2$/\1/p')
    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$em2_ip\"/" /etc/eucalyptus/eucalyptus.conf

CC,SC:   1. Configure Eucalyptus Networking

    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    em1_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em1$/\1/p')
    em2_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em2$/\1/p')
    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$em1_ip\"/" /etc/eucalyptus/eucalyptus.conf

OSP:  1. Configure Eucalyptus Networking

    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    em1_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em1$/\1/p')
    em2_ip=$(ip addr | sed -r -n -e 's/^ *inet ([^/]*)\/.* em2$/\1/p')
    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$em1_ip\"/" /etc/eucalyptus/eucalyptus.conf

NC*:  1. Configure Eucalyptus Networking

    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"br0\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em1\"/" \
                -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"br0\"/" /etc/eucalyptus/eucalyptus.conf

CLC:  2. Create Eucalyptus EDGE Networking configuration file
* This can not be loaded until the cloud is initialized

    instance_dns_domain=cloud.internal
    instance_dns_servers=10.104.10.80
    instance_public_ips=10.104.40.1-10.104.40.254
    cluster01=hp-gol-d1a
    
    cat << EOF | sudo tee /etc/eucalyptus/edge-$(date +%Y-%m-%d).json > /dev/null
    {
      "InstanceDnsDomain": "eucalyptus.internal",
      "InstanceDnsServers": [
        "10.104.10.80"
      ],
      "PublicIps": [
        "10.104.40.1-10.104.40.254"
      ],
      "Clusters": [
        {
          "Name": "hp-gol-d1a",
          "MacPrefix": "d0:0d",
          "Subnet": {
            "Name": "Private (10.105.40.0/24)",
            "Subnet": "10.105.40.0",
            "Netmask": "255.255.255.0",
            "Gateway": "10.105.40.1"
          },
          "PrivateIps": [
            "10.105.40.2-10.105.40.254"
          ]
        }
      ]
    }
    EOF

NC*:  3. Configure Eucalyptus Disk Allocation

    nc_work_size=2400000
    nc_cache_size=300000
    sudo sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
                -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf

NC*:  4. Configure Eucalyptus to use Private IP for Metadata

    cat << EOF | sudo tee -a /etc/eucalyptus/eucalyptus.conf > /dev/null
    
    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    EOF

CLC,UFS,SC,OSP:  5. Configure Eucalyptus Java Memory Allocation

    # Skip for now, causing startup errors
    # heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    # sudo sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

MC:   6. Configure Management Console with Cloud Controller Address

    clc_host=odc-d-13.prc.eucalyptus-systems.com
    clc_em1_ip=$(dig +short $clc_host)
    clc_em2_ip=${clc_em1_ip/10.104/10.105}
    sudo sed -i -e "/^clchost = /s/localhost/$clc_em2_ip/" /etc/eucaconsole/console.ini

ALL:  7. Disable zero-conf network

    sudo sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    

## Start Eucalyptus

CLC:  1. Initialize the Cloud Controller service

    sudo euca_conf --initialize

CLC,UFS,SC,OSP:  2. Start the Cloud Controller service

    sudo chkconfig eucalyptus-cloud on

    sudo service eucalyptus-cloud start

CC:   3. Start the Cluster Controller service

    sudo chkconfig eucalyptus-cc on

    sudo service eucalyptus-cc start

NC*:  4. Start the Node Controller and Eucanetd services

    sudo chkconfig eucalyptus-nc on

    sudo service eucalyptus-nc start

    sudo chkconfig eucanetd on

    sudo service eucanetd start

MW:   5. Confirm service startup

    nc -z 10.104.10.83 8443 || echo 'Connection failed! CLC not listening on 8443'
    nc -z 10.104.10.83 8773 || echo 'Connection failed! CLC not listening on 8773'

    nc -z 10.104.10.84 8773 || echo 'Connection failed! UFS not listening on 8773'

    nc -z 10.104.10.84 8888 || echo 'Connection failed! MC not listening on 8888'

    nc -z 10.10.104.1.208 8773 || echo 'Connection failed! OSP not listening on 8773'

    nc -z 10.104.10.85 8773 || echo 'Connection failed! SC not listening on 8773'

    nc -z 10.104.10.85 8774 || echo 'Connection failed! CC not listening on 8774'

    nc -z 10.105.1.190 8775 || echo 'Connection failed! NC1 not listening on 8775'
    nc -z 10.105.1.187 8775 || echo 'Connection failed! NC2 not listening on 8775'
    nc -z 10.105.10.56 8775 || echo 'Connection failed! NC3 not listening on 8775'
    nc -z 10.105.10.59 8775 || echo 'Connection failed! NC4 not listening on 8775'

    ls -l /var/log/eucalyptus # confirm log files written on all hosts


## Register Eucalyptus

CLC:  1. Register User-Facing services

    region=hp-gol-d1
    region_domain=mjc.prc.eucalyptus-systems.com
    zone_a=${region}a
    zone_b=${region}b

    ufs_private_ip=10.105.10.84
    api_service_name=${region}-api

    euca_conf --register-service -T user-api -H ${region}.${region_domain} -N ${api_service_name}

CLC:  2. Register Walrus as the Object Storage Provider

    walrus_public_ip=10.104.1.208
    walrus_component_name=${region}-walrus

    euca_conf --register-walrusbackend -P walrus -H ${walrus_public_ip} -C ${walrus_component_name}

CLC:  3. Register Storage Controller service

    sc_public_ip=10.104.10.85
    sc_component_name=${zone_a}-sc

    euca_conf --register-sc -P ${zone_a} -H ${sc_public_ip} -C ${sc_component_name}

CLC:  4. Register Cluster Controller service

    cc_public_ip=10.104.10.85
    cc_component_name=${zone_a}-cc

    euca_conf --register-cluster -P ${zone_a} -H ${cc_public_ip} -C ${cc_component_name}

CC:   5. Register Node Controller host(s)

    nc1_private_ip=10.105.1.190
    nc2_private_ip=10.105.1.187
    nc3_private_ip=10.105.10.56
    nc4_private_ip=10.105.10.59

    # Skip broken hosts until first two healthy again
    #euca_conf --register-nodes="${nc1_private_ip} ${nc2_private_ip} ${nc3_private_ip} ${nc4_private_ip}"
    euca_conf --register-nodes="${nc3_private_ip} ${nc4_private_ip}"


## Runtime Configuration

CLC:  1. Use Eucalyptus Administrator credentials

    mkdir -p ~/creds/eucalyptus/admin

    rm -f ~/creds/eucalyptus/admin.zip

    euca_conf --get-credentials ~root/creds/eucalyptus/admin.zip

    unzip ~root/creds/eucalyptus/admin.zip -d ~root/creds/eucalyptus/admin/

    cat ~root/creds/eucalyptus/admin/eucarc

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  5. Confirm Public IP addresses

    euca-describe-addresses verbose

CLC:  7. Confirm service status

    euca-describe-services | cut -f 1-5


## Configure DNS

CLC:  1. Use Eucalyptus Administrator credentials

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  2. Configure Eucalyptus DNS Server

    euca-modify-property -p system.dns.nameserver=ns1.mjc.prc.eucalyptus-systems.com

    euca-modify-property -p system.dns.nameserveraddress=10.104.10.80

CLC:  3. Configure DNS Timeout and TTL

    euca-modify-property -p dns.tcp.timeout_seconds=30

    euca-modify-property -p services.loadbalancing.dns_ttl=15

CLC:  4. Configure DNS Domain

    euca-modify-property -p system.dns.dnsdomain=hp-gol-c1.mjc.prc.eucalyptus-systems.com

CLC:  5. Configure DNS Sub-Domains

    euca-modify-property -p cloud.vmstate.instance_subdomain=.cloud

    euca-modify-property -p services.loadbalancing.dns_subdomain=lb

CLC:  6. Enable DNS

    euca-modify-property -p bootstrap.webservices.use_instance_dns=true

    euca-modify-property -p bootstrap.webservices.use_dns_delegation=true

CLC:  7. Refresh Eucalyptus Administrator credentials

    mkdir -p ~root/creds/eucalyptus/admin

    rm -f ~root/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin ~root/creds/eucalyptus/admin.zip

    unzip -uo ~root/creds/eucalyptus/admin.zip -d ~root/creds/eucalyptus/admin/

    cat ~root/creds/eucalyptus/admin/eucarc

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  8. Display Parent DNS Server Sample Configuration (skipped)

CLC:  9. Confirm DNS resolution for Services

    dig +short compute.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short objectstorage.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short euare.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short tokens.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short autoscaling.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short cloudformation.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short cloudwatch.hp-gol-c1.mjc.prc.eucalyptus-systems.com

    dig +short loadbalancing.hp-gol-c1.mjc.prc.eucalyptus-systems.com

CLC: 10. Confirm API commands work with new URLs

    euca-describe-regions

    euform-describe-stacks

    euscale-describe-auto-scaling-groups

    euwatch-describe-alarms


## Configure EBS Storage

CLC:  1. Use Eucalyptus Administrator credentials

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  2. Set the Eucalyptus Storage Controller backend

    euca-modify-property -p AZ1.storage.blockstoragemanager=overlay

CLC:  3. Confirm service status

    euca-describe-services | cut -f1-5

CLC:  4. Confirm Volume Creation

    euca-create-volume -z AZ1 -s 1

    euca-describe-volumes

CLC:  5. Confirm Volume Deletion

    euca-delete-volume vol-xxxxxxxx

    euca-describe-volumes


## Configure Object Storage

CLC:  1. Use Eucalyptus Administrator credentials

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  2. Set the Eucalyptus Object Storage Provider to Walrus

    euca-modify-property -p objectstorage.providerclient=walrus

CLC:  3. Confirm service status

    euca-describe-services | cut -f1-5

CLC:  4. Confirm Snapshot Creation

    euca-create-volume -z AZ1 -s 1

    euca-describe-volumes

    euca-create-snapshot vol-xxxxxxxx

    euca-describe-snapshots

CLC:  5. Confirm Snapshot Deletion

    euca-delete-snapshot snap-xxxxxxxx

    euca-describe-snapshots

    euca-delete-volume vol-xxxxxxxx

    euca-describe-volumes

CLC:  6. Refresh Eucalyptus Administrator credentials

    rm -f ~root/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin ~root/creds/eucalyptus/admin.zip

    unzip -uo ~root/creds/eucalyptus/admin.zip -d ~root/creds/eucalyptus/admin/

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  7. Confirm Properties

    echo $S3_URL

CLC:  9. Install the images into Eucalyptus

    euca-install-load-balancer --install-default

    euca-install-imaging-worker --install-default

CLC: 10. Confirm service status

    euca-describe-services | cut -f1-5


## Configure IAM

CLC:  1. Use Eucalyptus Administrator credentials

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  2. Configure Eucalyptus Administrator Password

    euare-usermodloginprofile -u admin -p password


## Configure Management Console

MC:  1. Configure Eucalyptus Console Configuration file

    sed -i -e "/#elb.host=10.20.30.40/d" \
           -e "/#elb.port=443/d" \
           -e "/#s3.host=<your host IP or name>/d" \
           -e "/^clchost = localhost$/s/localhost/10.104.10.21/" \
           -e "/For each service, you can specify a different host and\/or port, for example;/a\
    ec2.host=10.104.10.21\n\
    ec2.port=8773\n\
    autoscale.host=10.104.10.21\n\
    autoscale.port=8773\n\
    cloudwatch.host=10.104.10.21\n\
    cloudwatch.port=8773\n\
    elb.host=10.104.10.21\n\
    elb.port=8773\n\
    iam.host=10.104.10.21\n\
    iam.port=8773\n\
    sts.host=10.104.10.21\n\
    sts.port=8773" \
           -e "/that won't work from client's browsers./a\
    s3.host=10.104.10.21" /etc/eucaconsole/console.ini

MC:  2. Start Eucalyptus Console service

    chkconfig eucaconsole on

    service eucaconsole start

MW:  3. Confirm Eucalyptus Console service

    Browse: http://10.104.10.83:8888

MC:  4. Stop Eucalyptus Console service

    service eucaconsole stop

MC:  5. Install Nginx package

    yum install -y nginx

MC:  6. Configure Nginx

    \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf

    sed -i -e 's/# \(listen 443 ssl;$\)/\1/' \
           -e 's/# \(ssl_certificate\)/\1/' \
           -e 's/\/path\/to\/ssl\/pem_file/\/etc\/eucaconsole\/console.crt/' \
           -e 's/\/path\/to\/ssl\/certificate_key/\/etc\/eucaconsole\/console.key/' /etc/nginx/nginx.conf

MC:  7. Start Nginx service

    chkconfig nginx on

    service nginx start


MC:  8. Configure Eucalyptus Console for SSL

    sed -i -e '/^session.secure =/s/= .*$/= true/' \
           -e '/^session.secure/a\
    sslcert=/etc/eucaconsole/console.crt\
    sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini

MC:  9. Start Eucalyptus Console service

    service eucaconsole start

MC: 10. Confirm Eucalyptus Console service

    Browse: https://10.104.10.21


## Configure Images

CLC:  1. Use Eucalyptus Administrator credentials

    source ~root/creds/eucalyptus/admin/eucarc

CLC:  2. Download a CentOS 6.5 image

    wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O ~root/centos.raw.xz

    xz -v -d ~root/centos.raw.xz

CLC:  3. Install Image

    euca-install-image -b images -r x86_64 -i ~root/centos.raw -n centos65 --virtualization-type hvm


CLC:  4. List Images

    euca-describe-images


CLC:  5. Launch Instance

    euca-run-instances -k admin emi-xxxxxxxx -t m1.small

CLC:  6. List Instances

    euca-describe-instances

CLC:  7. Confirm ability to login to Instance

    ssh -i ~root/creds/ops/admin/ops-admin.pem root@euca-XX-XX-XX-XX.cloud.hp-gol-d1.mjc.prc.eucalyptus-systems.com
    > curl http://169.254.169.254/latest/meta-data/public-ipv4




