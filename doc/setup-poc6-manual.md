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
- odc-f-14: NC1 (temporary)
- odc-f-17: NC2 (temporary)


Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- CC:  Cluster Controller Host
- SC:  Storage Controller Host
- OSP: Object Storage Provider(Gateway), Walrus
- NCn: Node Controller(s)


I am also slowly trying to author procedures to run within a normal user account, and use sudo when necessary.
This manual procedure is partially into that process.


## Prepare Network

1. (CLC): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT" >> /etc/sysconfig/iptables # Credentials (CLC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables # DNS
        echo "-A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables # DNS


1. (UFS): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT" >> /etc/sysconfig/iptables # Database (CLC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)


1. (MC): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT" >> /etc/sysconfig/iptables
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT" >> /etc/sysconfig/iptables


1. (CC): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8774 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)


1. (SC): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)


1. (OSP): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (CLC, UFS, OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT" >> /etc/sysconfig/iptables # jGroups (CLC,UFS,OSG, SC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT" >> /etc/sysconfig/iptables # Diagnostice (CLC, UFS, OSG, SC)


1. (NC): Reserve Ports Used by Eucalyptus

        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT" >> /etc/sysconfig/iptables # Debug only
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT" >> /etc/sysconfig/iptables # HA Membership
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8775 -j ACCEPT" >> /etc/sysconfig/iptables # Web services (NC)
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT" >> /etc/sysconfig/iptables # Multicast bind port ?
        echo "-A INPUT -m state --state NEW -m tcp -p tcp --dport 16514 -j ACCEPT" >> /etc/sysconfig/iptables # TLS, needed for node migrations (NC)


2. (MW): Verify Connectivity

        nc -z 10.104.10.83 8443 || echo 'Connection from MW to CLC:8443 failed!'
        nc -z 10.104.10.83 8773 || echo 'Connection from MW to CLC:8773 failed!'

        nc -z 10.104.1.208 8773 || echo 'Connection from MW to Walrus:8773 failed!'


2. (CLC): Verify Connectivity
        nc -z 10.104.10.85 8773 || echo 'Connection from CLC to SC:8773 failed!'
        nc -z 10.104.1.208 8773 || echo 'Connection from CLC to OSP:8773 failed!'
        nc -z 10.104.10.85 8774 || echo 'Connection from CLC to CC:8774 failed!'


2. (UFS): Verify Connectivity
        nc -z 10.104.10.83 8773 || echo 'Connection from UFS to CLC:8773 failed!'


2. (CC): Verify Connectivity
        nc -z 10.105.1.190 8775 || echo 'Connection from CC to NC1:8775 failed!'
        nc -z 10.105.1.187 8775 || echo 'Connection from CC to NC2:8775 failed!'
        nc -z 10.105.10.56 8775 || echo 'Connection from CC to NC3:8775 failed!'
        nc -z 10.105.10.59 8775 || echo 'Connection from CC to NC4:8775 failed!'


2. (SC): Verify Connectivity
        nc -z 10.104.10.85 8773 || echo 'Connection from SC to SC:8773 failed!'
        nc -z 10.104.1.208 8773 || echo 'Connection from SC to OSP:8773 failed!'
        nc -z 10.104.10.83 8777 || echo 'Connection from SC to CLC:8777 failed!'


2. (OSP): Verify Connectivity
        nc -z 10.104.10.83 8777 || echo 'Connection from OSP to CLC:8777 failed!'


2. (NC): Verify Connectivity
        nc -z 10.104.10.85 8773 || echo 'Connection from NC to SC:8773 failed!'
        nc -z 10.104.1.208 8773 || echo 'Connection from NC to OSP:8773 failed!'


2. (other): Verify Connectivity
  Use additional commands to verify the following:
  - Verify connection from public IP addresses of Eucalyptus instances (metadata) and CC to CLC on TCP port 8773
  - Verify TCP connectivity between CLC, Walrus, SC and VB on TCP port 8779 (or the first available port in range 8779-8849)
  - Verify connection between CLC, Walrus, SC, and VB on UDP port 7500
  - Verify multicast connectivity for IP address 228.7.7.3 between CLC, Walrus, SC, and VB on UDP port 8773
  - If DNS is enabled, verify connection from an end-user and instance IPs to DNS ports
  - If you use tgt (iSCSI open source target) for EBS storage, verify connection from NC to SC on TCP port 3260
  - Test multicast connectivity between each CLC and Walrus, SC, and VMware broker host.


3. (CLC / CC / SC / OSG): Run tomography tool

        mkdir -p ~/src/eucalyptus
        cd ~/src/eucalyptus
        git clone https://github.com/eucalyptus/deveutils

        cd deveutils/network-tomography
        ./network-tomography 10.104.10.83 10.104.10.84 10.104.10.85 10.104.1.208


4. (CLC): Scan for unknown SSH host keys
Note: sudo tee needed to append output to file owned by root

        ssh-keyscan 10.104.10.83 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.104.10.84 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.104.10.85 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.104.1.208 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

        ssh-keyscan 10.105.1.190 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.105.1.187 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.105.10.56 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan 10.105.10.59 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null


## Prepare External DNS

I will not describe this in detail yet, except to note that this must be in place and working properly 
before registering services with the method outlined below, as I will be using DNS names for the services
so they look more AWS-like.

You should be able to resolve:

        dig +short hp-gol-d1.mjc.prc.eucalyptus-systems.com
        10.104.10.84

        dig +short clc.hp-gol-d1.mjc.prc.eucalyptus-systems.com
        10.104.10.83


## Initialize Dependencies

1. (NC): Install bridge utilities package

        sudo yum -y install bridge-utils


2. (NC): Create Private Bridge
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


3. (NC): Convert Private Ethernet Interface to Private Bridge Slave

        sudo sed -i -e "\$aBRIDGE=$private_bridge" \
                    -e "/^BOOTPROTO=/s/=.*$/=none/" \
                    -e "/^IPADDR=/d" \
                    -e "/^NETMASK=/d" \
                    -e "/^PERSISTENT_DHCLIENT=/d" \
                    -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-$private_interface


4. (NC): Restart networking

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


9. (CC): Configure packet routing

        sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

        sudo sysctl -p

        cat /proc/sys/net/ipv4/ip_forward


9. (NC): Configure packet routing

        sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
        sudo sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

        sudo sysctl -p

        cat /proc/sys/net/ipv4/ip_forward
        cat /proc/sys/net/bridge/bridge-nf-call-iptables


10. (ALL): Install subscriber license (optional, for subscriber-only packages)
Note CS has a license for internal use, so this will obtain and use that license from where
I have placed it on my local mirror:

        wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/CS-Team-Unlimited-1.4.0.tgz \
             -O /tmp/CS-Team-Unlimited-1.4.0.tgz

        cd /tmp
        tar xvfz CS-Team-Unlimited-1.4.0.tgz


## Install Eucalyptus

1. (ALL): Configure yum repositories (second set of statements optional for subscriber-licensed packages)

        sudo yum install -y \
                 http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
                 http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
                 http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm

        # Not working right now - confirm with Harold how I can test a license
        # sudo yum install -y /tmp/CS-Team-Unlimited-1.4.0/eucalyptus-enterprise-release-4.0-1.CS_Team.Unlimited.noarch.rpm
        # sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.0-1.el6.noarch.rpm
        # sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm


1. (ALL): Override external yum repos to internal servers
   There appears to be more repos described on the quality confluence page - confirm with Harold how these are actually used.
   It may be better to manually create repo configs than download and install the eucalyptus-release RPM and modifying it.

        sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/eucalyptus.repo
        sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/euca2ools.repo


2. (CLC): Install packages

        sudo yum install -y eucalyptus-cloud eucalyptus-service-image


2. (UFC): Install packages

        sudo yum install -y eucalyptus-cloud


2. (MC): Install packages

        sudo yum install -y eucaconsole


2. (CC): Install packages

        sudo yum install -y eucalyptus-cc


2. (SC): Install packages

        sudo yum install -y eucalyptus-sc


2. (OSP): Install packages

        sudo yum install -y eucalyptus-walrus


2. (NC): Install packages

        sudo yum install -y eucalyptus-nc


3. (NC): Remove Devfault libvirt network.

        sudo virsh net-destroy default
        sudo virsh net-autostart default --disable


4. (NC): Confirm KVM device node permissions.

        ls -l /dev/kvm  # should be owned by root:kvm


## Configure Eucalyptus

1. (CLC):  1. Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        public_interface=em1
        private_interface=em2
        public_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $public_interface$/\1/p")
        private_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $private_interface$/\1/p")

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$private_interface\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$public_interface\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$private_ip\"/" /etc/eucalyptus/eucalyptus.conf


1. (UFS / MC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        public_interface=em1
        private_interface=em2
        public_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $public_interface$/\1/p")
        private_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $private_interface$/\1/p")

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$private_interface\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$public_interface\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$private_ip\"/" /etc/eucalyptus/eucalyptus.conf


1. (CC / SC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        public_interface=em1
        private_interface=em2
        public_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $public_interface$/\1/p")
        private_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $private_interface$/\1/p")

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$private_interface\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$public_interface\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$public_ip\"/" /etc/eucalyptus/eucalyptus.conf


1. (OSP): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        public_interface=em1
        private_interface=em2
        public_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $public_interface$/\1/p")
        private_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $private_interface$/\1/p")

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$private_interface\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$public_interface\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=$public_ip\"/" /etc/eucalyptus/eucalyptus.conf


1. (NC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        public_interface=em1
        private_bridge=br0
        public_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $public_interface$/\1/p")
        private_ip=$(ip addr | sed -r -n -e "s/^ *inet ([^/]*)\/.* $private_interface$/\1/p")

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"$private_bridge\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"$public_interface\"/" \
                    -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"$private_bridge\"/" /etc/eucalyptus/eucalyptus.conf


2. (CLC): Create Eucalyptus EDGE Networking configuration file
This can not be loaded until the cloud is initialized

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


3. (NC): Configure Eucalyptus Disk Allocation

        nc_work_size=2400000
        nc_cache_size=300000

        sudo sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
                    -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf


4. (NC): Configure Eucalyptus to use Private IP for Metadata

        cat << EOF | sudo tee -a /etc/eucalyptus/eucalyptus.conf > /dev/null
    
        # Set this to Y to use the private IP of the CLC for the metadata service.
        # The default is to use the public IP.
        METADATA_USE_VM_PRIVATE="Y"
        EOF


5. (CLC / UFS / SC / OSP): Configure Eucalyptus Java Memory Allocation

        # Skip for now, causing startup errors
        # heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
        # sudo sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf


6. (MC): Configure Management Console with Cloud Controller Address

        clc_host=odc-d-13.prc.eucalyptus-systems.com
        clc_em1_ip=$(dig +short $clc_host)
        clc_em2_ip=${clc_em1_ip/10.104/10.105}
        sudo sed -i -e "/^clchost = /s/localhost/$clc_em2_ip/" /etc/eucaconsole/console.ini


7. (ALL): Disable zero-conf network

        sudo sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    

## Start Eucalyptus

1. (CLC): Initialize the Cloud Controller service

        sudo euca_conf --initialize


2. (CLC / UFS / SC / OSP): Start the Cloud Controller service

        sudo chkconfig eucalyptus-cloud on

        sudo service eucalyptus-cloud start


3. (CC): Start the Cluster Controller service

        sudo chkconfig eucalyptus-cc on

        sudo service eucalyptus-cc start


4. (NC): Start the Node Controller and Eucanetd services

        sudo chkconfig eucalyptus-nc on

        sudo service eucalyptus-nc start

        sudo chkconfig eucanetd on

        sudo service eucanetd start


5. (MW): Confirm service startup - Are ports listening?

        nc -z 10.104.10.83 8443 || echo 'Connection from MW to CLC:8443 failed!'
        nc -z 10.104.10.83 8773 || echo 'Connection from MW to CLC:8773 failed!'

        nc -z 10.104.10.84 8773 || echo 'Connection from MW to UFS:8773 failed!'

        nc -z 10.104.10.84 8888 || echo 'Connection from MW to MC:8888 failed!'

        nc -z 10.10.104.1.208 8773 || echo 'Connection from MW to OSP:8773 failed!'

        nc -z 10.104.10.85 8773 || echo 'Connection from MW to SC:8773 failed!'

        nc -z 10.104.10.85 8774 || echo 'Connection from MW to CC:8774 failed!'

        nc -z 10.105.1.190 8775 || echo 'Connection from MW to NC1:8775 failed!'
        nc -z 10.105.1.187 8775 || echo 'Connection from MW to NC2:8775 failed!'
        nc -z 10.105.10.56 8775 || echo 'Connection from MW to NC3:8775 failed!'
        nc -z 10.105.10.59 8775 || echo 'Connection from MW to NC4:8775 failed!'


5. (All): Confirm service startup - Are logs being written?

        ls -l /var/log/eucalyptus


## Register Eucalyptus
Experimental configuration attempting to get AWS-like service URLs

1. (CLC): Register User-Facing services

        region=hp-gol-d1
        region_domain=mjc.prc.eucalyptus-systems.com
        zone_a=${region}a
        zone_b=${region}b

        ufs_private_ip=10.105.10.84
        api_service_name=${region}-api

        sudo euca_conf --register-service -T user-api -H ${region}.${region_domain} -N ${api_service_name}


2. (CLC): Register Walrus as the Object Storage Provider (OSP)

        walrus_public_ip=10.104.1.208
        walrus_component_name=${region}-walrus

        sudo euca_conf --register-walrusbackend -P walrus -H ${walrus_public_ip} -C ${walrus_component_name}


3. (CLC): Register Storage Controller service

        sc_public_ip=10.104.10.85
        sc_component_name=${zone_a}-sc

        sudo euca_conf --register-sc -P ${zone_a} -H ${sc_public_ip} -C ${sc_component_name}


4. (CLC): Register Cluster Controller service

        cc_public_ip=10.104.10.85
        cc_component_name=${zone_a}-cc

        sudo euca_conf --register-cluster -P ${zone_a} -H ${cc_public_ip} -C ${cc_component_name}


5. (CC): Register Node Controller host(s)

        nc1_private_ip=10.105.1.190
        nc2_private_ip=10.105.1.187
        nc3_private_ip=10.105.10.56
        nc4_private_ip=10.105.10.59

        sudo euca_conf --register-nodes="${nc1_private_ip} ${nc2_private_ip} ${nc3_private_ip} ${nc4_private_ip}"


## Initial Runtime Configuration

1. (CLC): Use Eucalyptus Administrator credentials

        mkdir -p ~/creds/eucalyptus/admin

        rm -f ~/creds/eucalyptus/admin.zip

        sudo euca_conf --get-credentials ~/creds/eucalyptus/admin.zip

        unzip ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

        cat ~/creds/eucalyptus/admin/eucarc

        source ~/creds/eucalyptus/admin/eucarc


2. (CLC): Switch API to port 80
Confirm how this works with Vic

        euca-modify-property -p bootstrap.webservices.port=80


## Configure DNS

1. (CLC): Use Eucalyptus Administrator credentials

        source ~/creds/eucalyptus/admin/eucarc


2. (CLC): Configure Eucalyptus DNS Server

        euca-modify-property -p system.dns.nameserver=ns1.mjc.prc.eucalyptus-systems.com

        euca-modify-property -p system.dns.nameserveraddress=10.104.10.80


3. (CLC): Configure DNS Timeout and TTL

        euca-modify-property -p dns.tcp.timeout_seconds=30

        euca-modify-property -p services.loadbalancing.dns_ttl=15


4. (CLC): Configure DNS Domain

        euca-modify-property -p system.dns.dnsdomain=hp-gol-d1.mjc.prc.eucalyptus-systems.com


5. (CLC): Configure DNS Sub-Domains

        euca-modify-property -p cloud.vmstate.instance_subdomain=.cloud

        euca-modify-property -p services.loadbalancing.dns_subdomain=lb


6. (CLC): Enable DNS

        euca-modify-property -p bootstrap.webservices.use_instance_dns=true

        euca-modify-property -p bootstrap.webservices.use_dns_delegation=true


7. (CLC): Refresh Eucalyptus Administrator credentials

        mkdir -p ~/creds/eucalyptus/admin

        rm -f ~/creds/eucalyptus/admin.zip

        sudo euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

        unzip -uo ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

        cat ~/creds/eucalyptus/admin/eucarc

        source ~/creds/eucalyptus/admin/eucarc


8. (CLC): Display Parent DNS Server Sample Configuration (skipped)


9. (CLC): Confirm DNS resolution for Services

        region=hp-gol-d1
        region_domain=mjc.prc.eucalyptus-systems.com

        dig +short compute.${region}.${region_domain}

        dig +short objectstorage.${region}.${region_domain}

        dig +short euare.${region}.${region_domain}

        dig +short tokens.${region}.${region_domain}

        dig +short autoscaling.${region}.${region_domain}

        dig +short cloudformation.${region}.${region_domain}

        dig +short cloudwatch.${region}.${region_domain}

        dig +short loadbalancing.${region}.${region_domain}


## Additional Runtime Configuration

1. (CLC): Configure EBS Storage

        euca-modify-property -p ${zone_a}.storage.blockstoragemanager=overlay

    or

        euca-modify-property -p ${zone_a}.storage.blockstoragemanager=das

        euca-modify-property -p ${zone_a}.storage.dasdevice=/dev/sdb # Specfify RAID volume or raw disk


2. (CLC): Configure Object Storage

        euca-modify-property -p objectstorage.providerclient=walrus

        euca-modify-property -p walrusbackend.storagedir=/var/lib/eucalyptus/bukkits # optional


3. (CLC): Refresh Eucalyptus Administrator credentials

        rm -f ~/creds/eucalyptus/admin.zip

        sudo euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

        unzip -uo ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

        cat ~/creds/eucalyptus/admin/eucarc

        source ~/creds/eucalyptus/admin/eucarc


4. (CLC): Load Edge Network JSON configuration

        euca-modify-property -f cloud.network.network_configuration=/etc/eucalyptus/edge-$(date +%Y-%m-%d).json


5. (CLC): Install the imaging-worker and load-balancer images

        euca-install-load-balancer --install-default

        euca-install-imaging-worker --install-default


6. (CLC): Confirm service status

        euca-describe-services | cut -f1-6


7. (CLC): Confirm apis 

       euca-describe-regions



## Configure Minimal IAM

1. (CLC): Configure Eucalyptus Administrator Password

        euare-usermodloginprofile -u admin -p password


## YOU ARE HERE

## Configure Management Console

1. (MC): Configure Eucalyptus Console Configuration file

        sed -i -e "/#elb.host=10.20.30.40/d" \
               -e "/#elb.port=443/d" \
               -e "/#s3.host=<your host IP or name>/d" \
               -e "/^clchost = localhost$/s/localhost/10.105.10.83/" \
               -e "/that won't work from client's browsers./a\
        s3.host=10.104.1.208" /etc/eucaconsole/console.ini


2. (MC): Start Eucalyptus Console service

        chkconfig eucaconsole on

        service eucaconsole start


3. (MW): Confirm Eucalyptus Console service

        Browse: http://10.104.10.84:8888


4. (MC):  4. Stop Eucalyptus Console service

    service eucaconsole stop


5. (MC): Install Nginx package

        yum install -y nginx


6. (MC): Configure Nginx

        \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf

        sed -i -e 's/# \(listen 443 ssl;$\)/\1/' \
               -e 's/# \(ssl_certificate\)/\1/' \
               -e 's/\/path\/to\/ssl\/pem_file/\/etc\/eucaconsole\/console.crt/' \
               -e 's/\/path\/to\/ssl\/certificate_key/\/etc\/eucaconsole\/console.key/' /etc/nginx/nginx.conf

7. (MC): Start Nginx service

        chkconfig nginx on

        service nginx start


8. (MC): Configure Eucalyptus Console for SSL

        sed -i -e '/^session.secure =/s/= .*$/= true/' \
               -e '/^session.secure/a\
        sslcert=/etc/eucaconsole/console.crt\
        sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini


9. (MC): Start Eucalyptus Console service

        service eucaconsole start


10. (MC): Confirm Eucalyptus Console service

        Browse: https://10.104.10.21


## Configure Images

1. (CLC): Download Images

        wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O ~/centos.raw.xz

        xz -v -d ~/centos.raw.xz

        or

        python <(curl http://internal-emis.objectstorage.cloud.qa1.eucalyptus-systems.com/install-emis.py)


2. (CLC): Install Image

        euca-install-image -b images -r x86_64 -i ~root/centos.raw -n centos65 --virtualization-type hvm


3. (CLC): List Images

        euca-describe-images

