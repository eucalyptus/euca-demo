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


### Define Parameters
Define these environment variables before running script snippets below. This allows us to use descriptive names for each
parameter to make the commands more legible than would be the case if we used IP addresses


1. (ALL): Define Environment Variables used in upcoming code blocks

        export EUCA_REGION=hp-gol-d1

        export EUCA_DNS_PUBLIC_DOMAIN=mjc.prc.eucalyptus-systems.com
        export EUCA_DNS_PRIVATE_DOMAIN=internal
        export EUCA_DNS_INSTANCE_SUBDOMAIN=cloud
        export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
        export EUCA_DNS_PARENT_HOST=ns1.mjc.prc.eucalyptus-systems.com
        export EUCA_DNS_PARENT_IP=10.104.10.80
        
        export EUCA_PUBLIC_IP_RANGE=10.104.40.1-10.104.40.254

        export EUCA_PUBLIC_IP_RANGE=10.104.40.1-10.104.40.254

        export EUCA_CLUSTER1=${EUCA_REGION}a
        export EUCA_CLUSTER1_PRIVATE_IP_RANGE=10.105.40.2-10.105.40.254
        export EUCA_CLUSTER1_PRIVATE_CIDR=10.105.40.0/24
        export EUCA_CLUSTER1_PRIVATE_SUBNET=10.105.40.0
        export EUCA_CLUSTER1_PRIVATE_NETMASK=255.255.255.0
        export EUCA_CLUSTER1_PRIVATE_GATEWAY=10.105.40.1
    
        export EUCA_CLC_PUBLIC_INTERFACE=em1
        export EUCA_CLC_PRIVATE_INTERFACE=em2
        export EUCA_CLC_PUBLIC_IP=10.104.10.83
        export EUCA_CLC_PRIVATE_IP=10.105.10.83

        export EUCA_UFS_PUBLIC_INTERFACE=em1
        export EUCA_UFS_PRIVATE_INTERFACE=em2
        export EUCA_UFS_PUBLIC_IP=10.104.10.84
        export EUCA_UFS_PRIVATE_IP=10.105.10.84

        export EUCA_MC_PUBLIC_INTERFACE=em1
        export EUCA_MC_PRIVATE_INTERFACE=em2
        export EUCA_MC_PUBLIC_IP=10.104.10.84
        export EUCA_MC_PRIVATE_IP=10.105.10.84

        export EUCA_CC_PUBLIC_INTERFACE=em1
        export EUCA_CC_PRIVATE_INTERFACE=em2
        export EUCA_CC_PUBLIC_IP=10.104.10.85
        export EUCA_CC_PRIVATE_IP=10.105.10.85

        export EUCA_SC_PUBLIC_INTERFACE=em1
        export EUCA_SC_PRIVATE_INTERFACE=em2
        export EUCA_SC_PUBLIC_IP=10.104.10.85
        export EUCA_SC_PRIVATE_IP=10.105.10.85

        export EUCA_OSP_PUBLIC_INTERFACE=em1
        export EUCA_OSP_PRIVATE_INTERFACE=em2
        export EUCA_OSP_PUBLIC_IP=10.104.1.208
        export EUCA_OSP_PRIVATE_IP=10.105.1.208

        export EUCA_NC_PRIVATE_BRIDGE=br0
        export EUCA_NC_PRIVATE_INTERFACE=em2
        export EUCA_NC_PUBLIC_INTERFACE=em1

        export EUCA_NC1_PUBLIC_IP=10.104.1.190
        export EUCA_NC1_PRIVATE_IP=10.105.1.190

        export EUCA_NC2_PUBLIC_IP=10.104.1.187
        export EUCA_NC2_PRIVATE_IP=10.105.1.187

        export EUCA_NC3_PUBLIC_IP=10.104.10.56
        export EUCA_NC3_PRIVATE_IP=10.105.10.56

        export EUCA_NC4_PUBLIC_IP=10.104.10.59
        export EUCA_NC4_PRIVATE_IP=10.105.10.59


### Prepare Network

1. (ALL): Configure firewall to allow Eucalyptus Traffic

    TBD: Validate protocol source:port to dest:port traffic
    TBD: It would be ideal if we could create RPMs for a simulator for each node type, which could send and receive
         dummy traffic to confirm there are no firewall or routing issues, prior to their removal and replacement
         with the actual packages

2. (CLC/CC/SC/OSG): Run tomography tool

        mkdir -p ~/src/eucalyptus
        cd ~/src/eucalyptus
        git clone https://github.com/eucalyptus/deveutils

        cd deveutils/network-tomography
        ./network-tomography ${EUCA_CLC_PUBLIC_IP} ${EUCA_UFS_PUBLIC_IP} ${EUCA_SC_PUBLIC_IP} ${EUCA_OSP_PUBLIC_IP}


3. (CLC): Scan for unknown SSH host keys

    Note: sudo tee needed to append output to file owned by root

        ssh-keyscan ${EUCA_CLC_PUBLIC_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_UFS_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_CC_PRIVATE_IP}  2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_OSP_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

4. (CC): Scan for unknown SSH host keys

    Note: sudo tee needed to append output to file owned by root

        ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_NC2_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_NC3_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
        ssh-keyscan ${EUCA_NC4_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null


### Prepare External DNS

I will not describe this in detail yet, except to note that this must be in place and working properly 
before registering services with the method outlined below, as I will be using DNS names for the services
so they look more AWS-like.

You should be able to resolve:

    dig +short ${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
    10.104.10.84

    dig +short clc.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
    10.104.10.83


### Initialize Dependencies

1. (ALL): Disable zero-conf network
 
        sudo sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    

2. (NC): Install bridge utilities package

        sudo yum -y install bridge-utils


3. (NC): Create Private Bridge

    Move the static IP of the private interface to the private bridge

        private_ip=$(sed -n -e "s/^IPADDR=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
        private_netmask=$(sed -n -e "s/^NETMASK=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
        private_dns1=$(sed -n -e "s/^DNS1=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
        private_dns2=$(sed -n -e "s/^DNS2=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})

        cat << EOF | sudo tee /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_BRIDGE} > /dev/null
        DEVICE=${EUCA_NC_PRIVATE_BRIDGE}
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


4. (NC): Convert Private Ethernet Interface to Private Bridge Slave

        sudo sed -i -e "\$aBRIDGE=${EUCA_NC_PRIVATE_BRIDGE}" \
                    -e "/^BOOTPROTO=/s/=.*$/=none/" \
                    -e "/^IPADDR=/d" \
                    -e "/^NETMASK=/d" \
                    -e "/^PERSISTENT_DHCLIENT=/d" \
                    -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE}


5. (ALL): Restart networking

        sudo service network restart


6. (CLC): Configure firewall, but disable during installation

    * udp   53 - DNS
    * tcp   53 - DNS
    * tcp 5005 - Debug
    * tcp 8080 - Credentials
    * tcp 8772 - Debug
    * tcp 8773 - Web services
    * tcp 8777 - Database 
    * tcp 8778 - Multicast 

        cat << EOF > /etc/sysconfig/iptables
        *filter
        :INPUT ACCEPT [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [0:0]
        -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        -A INPUT -p icmp -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
        -A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
        -A INPUT -j REJECT --reject-with icmp-host-prohibited
        -A FORWARD -j REJECT --reject-with icmp-host-prohibited
        COMMIT
        EOF

        chkconfig iptables on
        service iptables stop


7. (UFS+MC): 

    * tcp   22 - Login, Control
    * tcp   80 - Console - HTTP (MC)
    * tcp  443 - Console - HTTPS (MC)
    * tcp 5005 - Debug (UFS)
    * tcp 7500 - Diagnostics (UFS)
    * tcp 8772 - Debug (UFS)
    * tcp 8773 - Web services (UFS)
    * tcp 8778 - Multicast (UFS)
    * tcp 8779-8849 - jGroups (UFS)
    * tcp 8888 - Console - Direct (MC)

        cat << EOF > /etc/sysconfig/iptables
        *filter
        :INPUT ACCEPT [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [0:0]
        -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        -A INPUT -p icmp -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT
        -A INPUT -j REJECT --reject-with icmp-host-prohibited
        -A FORWARD -j REJECT --reject-with icmp-host-prohibited
        COMMIT
        EOF

        chkconfig iptables on
        service iptables stop


8. (SC+CC): 

    * tcp   22 - Login, Control
    * tcp 5005 - Debug (SC, CC)
    * tcp 7500 - Diagnostice (SC)
    * tcp 8772 - Debug (SC, CC)
    * tcp 8773 - Web services (SC)
    * tcp 8774 - Web services (CC)
    * tcp 8778 - Multicast (SC, CC)
    * tcp 8779-8849 - jGroups (SC)

        cat << EOF > /etc/sysconfig/iptables
        *filter
        :INPUT ACCEPT [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [0:0]
        -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        -A INPUT -p icmp -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8774 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT
        -A INPUT -j REJECT --reject-with icmp-host-prohibited
        -A FORWARD -j REJECT --reject-with icmp-host-prohibited
        COMMIT
        EOF

        chkconfig iptables on
        service iptables stop


9. (OSP): 

    * tcp   22 - Login, Control
    * tcp 5005 - Debug
    * tcp 7500 - Diagnostics
    * tcp 8772 - Debug
    * tcp 8773 - Web services
    * tcp 8778 - Multicast
    * tcp 8779-8849 - jGroups

        cat << EOF > /etc/sysconfig/iptables
        *filter
        :INPUT ACCEPT [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [0:0]
        -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        -A INPUT -p icmp -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT
        -A INPUT -j REJECT --reject-with icmp-host-prohibited
        -A FORWARD -j REJECT --reject-with icmp-host-prohibited
        COMMIT
        EOF

        chkconfig iptables on
        service iptables stop


10. (NC): Configure firewall, but disable during installation

    * tcp    22 - Login, Control
    * tcp  5005 - Debug
    * tcp  8772 - Debug
    * tcp  8773 - Web services
    * tcp  8775 - Web services
    * tcp  8778 - Multicast
    * tcp 16514 - TLS, needed for node migrations

        cat << EOF > /etc/sysconfig/iptables
        *filter
        :INPUT ACCEPT [0:0]
        :FORWARD ACCEPT [0:0]
        :OUTPUT ACCEPT [0:0]
        -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        -A INPUT -p icmp -j ACCEPT
        -A INPUT -i lo -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8775 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
        -A INPUT -m state --state NEW -m tcp -p tcp --dport 16514 -j ACCEPT
        -A INPUT -j REJECT --reject-with icmp-host-prohibited
        -A FORWARD -j REJECT --reject-with icmp-host-prohibited
        COMMIT
        EOF

        chkconfig iptables on
        service iptables stop


11. (ALL): Disable SELinux

        sudo sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

        sudo setenforce 0


12. (ALL): Install and Configure the NTP service

        sudo yum -y install ntp
    
        sudo chkconfig ntpd on
        sudo service ntpd start

        sudo ntpdate -u  0.centos.pool.ntp.org
        sudo hwclock --systohc


13. (CLC) Install and Configure Mail Relay

        TBD - see existing Postfix null client configurations


14. (CC): Configure packet routing

        sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

        sudo sysctl -p

        cat /proc/sys/net/ipv4/ip_forward


15. (NC): Configure packet routing

        sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
        sudo sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

        sudo sysctl -p

        cat /proc/sys/net/ipv4/ip_forward
        cat /proc/sys/net/bridge/bridge-nf-call-iptables


### Install Eucalyptus

1. (ALL): Configure yum repositories (second set of statements optional for subscriber-licensed packages)

        sudo yum install -y \
                 http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
                 http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
                 http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm

        sudo yum install -y http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/eucalyptus-enterprise-license-1-1.151702164410-Euca_HP_SalesEng.noarch.rpm
        sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm


2. (ALL): Override external yum repos to internal servers

    There appears to be more repos described on the quality confluence page - confirm with Harold how these are actually used.
    It may be better to manually create repo configs than download and install the eucalyptus-release RPM and modifying it.

        sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/eucalyptus.repo
        sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/euca2ools.repo


3. (CLC): Install packages

        sudo yum install -y eucalyptus-cloud eucalyptus-service-image


4. (UFC+MC): Install packages

        sudo yum install -y eucalyptus-cloud eucaconsole


5. (SC+CC): Install packages

        sudo yum install -y eucalyptus-sc eucalyptus-cc


6. (OSP): Install packages

        sudo yum install -y eucalyptus-walrus


7. (NC): Install packages

        sudo yum install -y eucalyptus-nc


8. (NC): Remove Devfault libvirt network.

        sudo virsh net-destroy default
        sudo virsh net-autostart default --disable


### Configure Eucalyptus

1. (CLC):  1. Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CLC_PRIVATE_INTERFACE}\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CLC_PUBLIC_INTERFACE}\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CLC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf


2. (UFS+MC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_UFS_PRIVATE_INTERFACE}\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_UFS_PUBLIC_INTERFACE}\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_UFS_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf


3. (SC+CC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CC_PRIVATE_INTERFACE}\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CC_PUBLIC_INTERFACE}\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf


4. (OSP): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_OSP_PRIVATE_INTERFACE}\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_OSP_PUBLIC_INTERFACE}\"/" \
                    -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_OSP_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf


5. (NC): Configure Eucalyptus Networking

        sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

        sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                    -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
                    -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_NC_PUBLIC_INTERFACE}\"/" \
                    -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" /etc/eucalyptus/eucalyptus.conf


6. (CLC): Create Eucalyptus EDGE Networking configuration file

    This can not be loaded until the cloud is initialized

        cat << EOF | sudo tee /etc/eucalyptus/edge-$(date +%Y-%m-%d).json > /dev/null
        {
          "InstanceDnsDomain": "${EUCA_DNS_INSTANCE_SUBDOMAIN}.${EUCA_DNS_PRIVATE_DOMAIN}",
          "InstanceDnsServers": [
            "${EUCA_DNS_PARENT_IP}"
          ],
          "PublicIps": [
            "${EUCA_PUBLIC_IP_RANGE}"
          ],
          "Clusters": [
            {
              "Name": "${EUCA_CLUSTER1}",
              "MacPrefix": "d0:0d",
              "Subnet": {
                "Name": "Private (${EUCA_CLUSTER1_PRIVATE_CIDR})",
                "Subnet": "${EUCA_CLUSTER1_PRIVATE_SUBNET}",
                "Netmask": "${EUCA_CLUSTER1_PRIVATE_NETMASK}",
                "Gateway": "${EUCA_CLUSTER1_PRIVATE_GATEWAY}"
              },
              "PrivateIps": [
                "${EUCA_CLUSTER1_PRIVATE_IP_RANGE}"
              ]
            }
          ]
        }
        EOF


7. (NC): Configure Eucalyptus Disk Allocation

        nc_work_size=2400000
        nc_cache_size=300000

        sudo sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
                    -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf


8. (NC): Configure Eucalyptus to use Private IP for Metadata

        cat << EOF | sudo tee -a /etc/eucalyptus/eucalyptus.conf > /dev/null
    
        # Set this to Y to use the private IP of the CLC for the metadata service.
        # The default is to use the public IP.
        METADATA_USE_VM_PRIVATE="Y"
        EOF


9. (CLC/UFS/SC/OSP): Configure Eucalyptus Java Memory Allocation

        # Skip for now, causing startup errors
        # heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
        # sudo sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf


10. (MC): Configure Management Console with Cloud Controller Address

        sudo sed -i -e "/^clchost = /s/localhost/${EUCA_CLC_PRIVATE_IP}/" /etc/eucaconsole/console.ini


11. (ALL): Disable zero-conf network

        sudo sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    

### Start Eucalyptus

1. (CLC): Initialize the Cloud Controller service

        sudo euca_conf --initialize


2. (CLC/UFS/SC/OSP): Start the Cloud Controller service

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


5. (MW): Verify Connectivity

        nc -z ${EUCA_CLC_PUBLIC_IP} 8443 || echo 'Connection from MW to CLC:8443 failed!'
        nc -z ${EUCA_CLC_PUBLIC_IP} 8773 || echo 'Connection from MW to CLC:8773 failed!'

        nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from MW to Walrus:8773 failed!'


6. (CLC): Verify Connectivity

        nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from CLC to SC:8773 failed!'
        nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from CLC to OSP:8773 failed!'
        nc -z ${EUCA_CC_PUBLIC_IP} 8774 || echo 'Connection from CLC to CC:8774 failed!'


7. (UFS): Verify Connectivity

        nc -z ${EUCA_CLC_PUBLIC_IP} 8773 || echo 'Connection from UFS to CLC:8773 failed!'


8. (CC): Verify Connectivity

        nc -z ${EUCA_NC1_PRIVATE_IP} 8775 || echo 'Connection from CC to NC1:8775 failed!'
        nc -z ${EUCA_NC2_PRIVATE_IP} 8775 || echo 'Connection from CC to NC2:8775 failed!'
        nc -z ${EUCA_NC3_PRIVATE_IP} 8775 || echo 'Connection from CC to NC3:8775 failed!'
        nc -z ${EUCA_NC4_PRIVATE_IP} 8775 || echo 'Connection from CC to NC4:8775 failed!'


9. (SC): Verify Connectivity

        nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from SC to SC:8773 failed!'
        nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from SC to OSP:8773 failed!'
        nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from SC to CLC:8777 failed!'


10. (OSP): Verify Connectivity

        nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from OSP to CLC:8777 failed!'


11. (NC): Verify Connectivity

        nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from NC to SC:8773 failed!'
        nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from NC to OSP:8773 failed!'


12. (Other): Verify Connectivity

  Use additional commands to verify the following:

  - Verify connection from public IP addresses of Eucalyptus instances (metadata) and CC to CLC on TCP port 8773
  - Verify TCP connectivity between CLC, Walrus, SC and VB on TCP port 8779 (or the first available port in range 8779-8849)
  - Verify connection between CLC, Walrus, SC, and VB on UDP port 7500
  - Verify multicast connectivity for IP address 228.7.7.3 between CLC, Walrus, SC, and VB on UDP port 8773
  - If DNS is enabled, verify connection from an end-user and instance IPs to DNS ports
  - If you use tgt (iSCSI open source target) for EBS storage, verify connection from NC to SC on TCP port 3260
  - Test multicast connectivity between each CLC and Walrus, SC, and VMware broker host.


13. (All): Confirm service startup - Are logs being written?

        ls -l /var/log/eucalyptus


### Register Eucalyptus

1. (CLC): Register User-Facing services

        sudo euca_conf --register-service -T user-api -H ${EUCA_UFS_PRIVATE_IP} -N ${EUCA_REGION}-api

    or, if ${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN} resolves to ${EUCA_UFS_PRIVATE_IP}, try

        sudo euca_conf --register-service -T user-api -H ${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN} -N ${EUCA_REGION}-api

    Second method experimental...


2. (CLC): Register Walrus as the Object Storage Provider (OSP)

        sudo euca_conf --register-walrusbackend -P walrus -H ${EUCA_OSP_PRIVATE_IP} -C ${EUCA_REGION}-walrus


3. (CLC): Register Storage Controller service

        sudo euca_conf --register-sc -P ${EUCA_CLUSTER1} -H ${EUCA_SC_PRIVATE_IP} -C ${EUCA_CLUSTER1}-sc


4. (CLC): Register Cluster Controller service

        sudo euca_conf --register-cluster -P ${EUCA_CLUSTER1} -H ${EUCA_CC_PRIVATE_IP} -C ${EUCA_CLUSTER1}-cc


5. (CC): Register Node Controller host(s)

        sudo euca_conf --register-nodes="${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP} ${EUCA_NC3_PRIVATE_IP} ${EUCA_NC4_PRIVATE_IP}"


### Initial Runtime Configuration

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


### Configure DNS

1. (CLC): Use Eucalyptus Administrator credentials

        source ~/creds/eucalyptus/admin/eucarc


2. (CLC): Configure Eucalyptus DNS Server

        euca-modify-property -p system.dns.nameserver=${EUCA_DNS_PARENT_HOST}

        euca-modify-property -p system.dns.nameserveraddress=${EUCA_DNS_PARENT_IP}


3. (CLC): Configure DNS Timeout and TTL

        euca-modify-property -p dns.tcp.timeout_seconds=30

        euca-modify-property -p services.loadbalancing.dns_ttl=15


4. (CLC): Configure DNS Domain

        euca-modify-property -p system.dns.dnsdomain=${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}


5. (CLC): Configure DNS Sub-Domains

        euca-modify-property -p cloud.vmstate.instance_subdomain=.${EUCA_DNS_INSTANCE_SUBDOMAIN}

        euca-modify-property -p services.loadbalancing.dns_subdomain=${EUCA_DNS_LOADBALANCER_SUBDOMAIN}


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

        dig +short compute.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short objectstorage.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short euare.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short tokens.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short autoscaling.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short cloudformation.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short cloudwatch.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

        dig +short loadbalancing.${EUCA_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}


### Additional Runtime Configuration

1. (CLC): Configure EBS Storage

        euca-modify-property -p ${EUCA_CLUSTER1}.storage.blockstoragemanager=overlay

    or

        euca-modify-property -p ${EUCA_CLUSTER1}.storage.blockstoragemanager=das

        euca-modify-property -p ${EUCA_CLUSTER1}.storage.dasdevice=/dev/sdb # Specfify RAID volume or raw disk


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



### Configure Minimal IAM

1. (CLC): Configure Eucalyptus Administrator Password

        euare-usermodloginprofile -u admin -p password


### YOU ARE HERE

### Configure Management Console

1. (MC): Configure Eucalyptus Console Configuration file

        sed -i -e "/#elb.host=10.20.30.40/d" \
               -e "/#elb.port=443/d" \
               -e "/#s3.host=<your host IP or name>/d" \
               -e "/^clchost = localhost$/s/localhost/${EUCA_CLC_PRIVATE_IP}/" \
               -e "/that won't work from client's browsers./a\
        s3.host=${EUCA_OSP_PUBLIC_IP}" /etc/eucaconsole/console.ini


2. (MC): Start Eucalyptus Console service

        chkconfig eucaconsole on

        service eucaconsole start


3. (MW): Confirm Eucalyptus Console service

        Browse: http://${EUCA_MC_PUBLIC_IP}:8888


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

        Browse: https://${EUCA_MC_PUBLIC_IP}


### Configure Images

1. (CLC): Download Images

        wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O ~/centos.raw.xz

        xz -v -d ~/centos.raw.xz

        or

        python <(curl http://internal-emis.objectstorage.cloud.qa1.eucalyptus-systems.com/install-emis.py)


2. (CLC): Install Image

        euca-install-image -b images -r x86_64 -i ~root/centos.raw -n centos65 --virtualization-type hvm


3. (CLC): List Images

        euca-describe-images

