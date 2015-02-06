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

CLC:  4. Scan for unknown SSH host keys
    
    ssh-keyscan 10.104.10.83 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan 10.104.10.84 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan 10.104.10.85 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan 10.104.1.208 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan 10.104.1.190 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan 10.104.1.187 2> /dev/null >> /root/.ssh/known_hosts

## Initialize Dependencies

CLC, UFS+MC, CC+SC, OSP, NC*:  1. Install bridge utilities package

    yum -y install bridge-utils

NC*:  2. Create Bridge

    echo << EOF > /etc/sysconfig/network-scripts/ifcfg-br0
    DEVICE=br0
    TYPE=Bridge
    BOOTPROTO=dhcp
    PERSISTENT_DHCLIENT=yes
    ONBOOT=yes
    DELAY=0
    EOF

NC*:  3. Adjust public ethernet interface

    sed -i -e "\$aBRIDGE=br0" \
           -e "/^BOOTPROTO=/s/=.*$/=none/" \
           -e "/^PERSISTENT_DHCLIENT=/d" \
           -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-em1

NC*:  4. Restart networking

    service network restart

ALL:  5. Disable firewall

    service iptables stop

ALL:  6. Disable SELinux

    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    setenforce 0

ALL:  7. Install and Configure the NTP service

    yum -y install ntp

    chkconfig ntpd on
    service ntpd start

    ntpdate -u  0.centos.pool.ntp.org
    hwclock --systohc

CLC:  8. Install and Configure Mail Relay

    TBD - see existing Postfix null client configurations

CLC:  9. Configure packet routing

    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf
    fi

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    if [ -e /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
        cat /proc/sys/net/bridge/bridge-nf-call-iptables
    fi


## Install Eucalyptus

ALL:  1. Configure yum repositories

    yum install -y \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm

CLC:  2. Install packages

    yum install -y eucalyptus-cloud 

    yum install -y eucalyptus-service-image

MC:   2. Install packages

    yum install -y eucaconsole

CC:   2. Install packages

    yum install -y eucalyptus-cc

SC:   2. Install packages

    yum install -y eucalyptus-sc

OSP:  2. Install packages

    yum install -y eucalyptus-walrus

NC*:  2. Install packages

    yum install -y eucalyptus-nc
    yum install -y eucanetd

NC*:  3. Remove Devfault libvirt network.

    virsh net-destroy default
    virsh net-autostart default --disable

NC*:  4. Confirm KVM device node permissions.

    ls -l /dev/kvm  # should be owned by root:kvm


## Configure Eucalyptus

CC:   1. Configure Eucalyptus Networking
           
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig
           
    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" /etc/eucalyptus/eucalyptus.conf

NC*:  1. Configure Eucalyptus Networking (confirm DHCPDAEMON not needed)
           
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig
           
    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"br0\"/" /etc/eucalyptus/eucalyptus.conf

CLC:  1. Configure Eucalyptus Networking
           
    <do EDGE JSON>

CC:   2. Configure Scheduling Policy (skip, use default)

SC:   3. Configure Loop Devices

    sed -i -e "s/^# CREATE_SC_LOOP_DEVICES=256$/CREATE_SC_LOOP_DEVICES=512/" /etc/eucalyptus/eucalyptus.conf

ALL:  4. Configure Firewall

    TBD: See specific rules. This seems out of order here.


## Start Eucalyptus

CLC:  1. Initialize the Cloud Controller service

    euca_conf --initialize

CLC:  2. Start the Cloud Controller service

    chkconfig eucalyptus-cloud on

    service eucalyptus-cloud start

OSG:  3. Start Walrus

    chkconfig eucalyptus-walrus on    # or is this eucalyptus-cloud?

    service eucalyptus-walrus start

CC:   4. Start the Cluster Controller service

    chkconfig eucalyptus-cc on

    service eucalyptus-cc start

SC:   5. Start the Storage Controller service

    chkconfig eucalyptus-sc on    # or is this eucalyptus-cloud?

    service eucalyptus-sc start

NC*:  6. Start the Node Controller and Eucanetd services

    chkconfig eucalyptus-nc on

    service eucalyptus-nc start

    chkconfig eucanetd on

    service eucanetd start

MW:   7. Confirm service startup

* The CLC is listening on ports 8443 and 8773
* Walrus is listening on port 8773
* The SC is listening on port 8773
* The CC is listening on port 8774
* The NCs are listening on port 8775
* Log files are being written to /var/log/eucalyptus/


## Register Eucalyptus 

CLC:  6. Register Walrus as the Object Storage Provider

    euca_conf --register-walrusbackend --partition walrus --host 10.104.10.21 --component walrus

CLC:  7. Register User-Facing services

    euca_conf --register-service -T user-api -H 10.104.10.21 -N PODAPI

CLC:  8. Register Cluster Controller service

    euca_conf --register-cluster --partition AZ1 --host  --component PODCC

CLC:  9. Register Storage Controller service

    euca_conf --register-sc --partition AZ1 --host 10.104.10.21 --component PODSC

CLC: 10. Register Node Controller host(s)

    euca_conf --register-nodes="10.105.10.23 10.105.10.37"

NC*: 11. Start Node Controller service

    chkconfig eucalyptus-nc on

    service eucalyptus-nc start

CLC: 12. Confirm service status

    euca-describe-services | cut -f 1-5


## Configure Networking

ALL: 1. Configure Eucalyptus Networking

    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"MANAGED-NOVLAN\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"em1\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"em2\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"br0\"/" \
           -e "s/^#VNET_PUBLICIPS=.*$/VNET_PUBLICIPS=\"10.104.44.1-10.104.44.254\"/" \
           -e "s/^#VNET_SUBNET=.*$/VNET_SUBNET=\"172.44.0.0\"/" \
           -e "s/^#VNET_NETMASK=.*$/VNET_NETMASK=\"255.255.0.0\"/" \
           -e "s/^#VNET_ADDRSPERNET=.*$/VNET_ADDRSPERNET=\"32\"/" \
           -e "s/^#VNET_DNS.*$/VNET_DNS=\"10.104.10.80\"/" /etc/eucalyptus/eucalyptus.conf

CC:   2. Restart the Cluster Controller service

    service eucalyptus-cc restart

NC*:  3. Restart the Node Controller service

    service eucalyptus-nc restart

CLC:  4. Use Eucalyptus Administrator credentials

    mkdir -p /root/creds/eucalyptus/admin

    rm -f /root/creds/eucalyptus/admin.zip

    euca_conf --get-credentials /root/creds/eucalyptus/admin.zip

    unzip /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/

    cat /root/creds/eucalyptus/admin/eucarc

    source /root/creds/eucalyptus/admin/eucarc

CLC:  5. Confirm Public IP addresses

    euca-describe-addresses verbose


CLC:  7. Confirm service status

    euca-describe-services | cut -f 1-5


## Configure DNS

CLC:  1. Use Eucalyptus Administrator credentials

    source /root/creds/eucalyptus/admin/eucarc

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

    mkdir -p /root/creds/eucalyptus/admin

    rm -f /root/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin /root/creds/eucalyptus/admin.zip

    unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/

    cat /root/creds/eucalyptus/admin/eucarc

    source /root/creds/eucalyptus/admin/eucarc

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

    source /root/creds/eucalyptus/admin/eucarc

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

    source /root/creds/eucalyptus/admin/eucarc

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

    rm -f /root/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin /root/creds/eucalyptus/admin.zip
    
    unzip -uo /root/creds/eucalyptus/admin.zip -d /root/creds/eucalyptus/admin/

    source /root/creds/eucalyptus/admin/eucarc

CLC:  7. Confirm Properties

    echo $S3_URL

CLC:  9. Install the images into Eucalyptus

    euca-install-load-balancer --install-default

    euca-install-imaging-worker --install-default

CLC: 10. Confirm service status

    euca-describe-services | cut -f1-5


## Configure IAM

CLC:  1. Use Eucalyptus Administrator credentials

    source /root/creds/eucalyptus/admin/eucarc

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

    source /root/creds/eucalyptus/admin/eucarc

CLC:  2. Download a CentOS 6.5 image

    wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O /root/centos.raw.xz

    xz -v -d /root/centos.raw.xz

CLC:  3. Install Image

    euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm


CLC:  4. List Images

    euca-describe-images


CLC:  5. Launch Instance

    euca-run-instances -k admin emi-xxxxxxxx -t m1.small

CLC:  6. List Instances

    euca-describe-instances

CLC:  7. Confirm ability to login to Instance

    ssh -i /root/creds/ops/admin/ops-admin.pem root@euca-XX-XX-XX-XX.cloud.hp-gol-d1.mjc.prc.eucalyptus-systems.com
    > curl http://169.254.169.254/latest/meta-data/public-ipv4




