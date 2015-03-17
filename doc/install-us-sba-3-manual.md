# Install Procedure for region us-sba-3
## 3-Node (2+1) Hybrid (Virtual/Physical) POC

This document describes the manual procedure to install region us-sba-3.mjcconsulting.com,
based partially on the "4-node reference architecture", with 1 Cloud-level host,
1 Cluster-level host, and 1 Node Controller, in MCrawford's home virtualization environment.

However, this variant will use KVM virtualization on one physical host to
create the 2 control-plane nodes as KVM virtual machines using libvirt, but
outside of the control of Eucalyptus. Combined with a second physical host
which has Eucalyptus directly installed to act as a node controller.
This variant is also setup to use a VLAN trunk into the node controller host
to more closely simulate what is likely on a host with 2 10G interfaces
configured in a bond. I may switch to such a bonded configuration for this
in the future, but at this point, I will skip over the bond, but send the
public, private and a SAN network over the trunk.

This variant is meant to be run as root

This POC will use **us-sba-3** as the AWS_DEFAULT_REGION.

The full parent DNS domain will be us-sba-3.mjcconsulting.com.

This is using the following virtual and physical hosts in the MCrawford home virtualization environment:
- mjcsbateucaclc01 (virtual,  eth0: 10.0.14.48/24, eth1: 10.0.30.48/24, eth2: 10.0.46.48): CLC+UFS+MC+OSP
- mjcsbateucacc01  (virtual,  eth0: 10.0.14.51/24, eth1: 10.0.30.51/24, eth2: 10.0.46.51): CC+SC
- mjcsbapvs02      (physical, br14: 10.0.14.17/24, eth1: 10.0.30.17/24, eth2: 10.0.46.17): NC1

Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- OSP: Object Storage Provider (Walrus)
- CC:  Cluster Controller Host
- SC:  Storage Controller Host
- NCn: Node Controller(s)

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. (ALL): Define Environment Variables used in upcoming code blocks

    ```bash
    export AWS_DEFAULT_REGION=us-sba-3

    export EUCA_DNS_PUBLIC_DOMAIN=mjcconsulting.com
    export EUCA_DNS_PRIVATE_DOMAIN=internal
    export EUCA_DNS_INSTANCE_SUBDOMAIN=cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
    export EUCA_DNS_PARENT_HOST=mjcsbapns41.sba.mjcconsulting.com
    export EUCA_DNS_PARENT_IP=10.0.6.8

    export EUCA_SERVICE_API_NAME=api

    export EUCA_PUBLIC_IP_RANGE=10.0.14.64-10.0.14.127

    export EUCA_CLUSTER1=${AWS_DEFAULT_REGION}a
    export EUCA_CLUSTER1_CC_NAME=${EUCA_CLUSTER1}-cc
    export EUCA_CLUSTER1_SC_NAME=${EUCA_CLUSTER1}-sc

    export EUCA_CLUSTER1_PRIVATE_IP_RANGE=10.0.30.64-10.0.30.127
    export EUCA_CLUSTER1_PRIVATE_NAME=10.0.30.0
    export EUCA_CLUSTER1_PRIVATE_SUBNET=10.0.30.0
    export EUCA_CLUSTER1_PRIVATE_NETMASK=255.255.255.0
    export EUCA_CLUSTER1_PRIVATE_GATEWAY=10.0.30.1

    export EUCA_CLC_PUBLIC_INTERFACE=eth0
    export EUCA_CLC_PRIVATE_INTERFACE=eth1
    export EUCA_CLC_STORAGE_INTERFACE=eth2
    export EUCA_CLC_PUBLIC_IP=10.0.14.48
    export EUCA_CLC_PRIVATE_IP=10.0.30.48
    export EUCA_CLC_STORAGE_IP=10.0.46.48

    export EUCA_UFS_PUBLIC_INTERFACE=eth0
    export EUCA_UFS_PRIVATE_INTERFACE=eth1
    export EUCA_UFS_STORAGE_INTERFACE=eth2
    export EUCA_UFS_PUBLIC_IP=10.0.14.48
    export EUCA_UFS_PRIVATE_IP=10.0.30.48
    export EUCA_UFS_STORAGE_IP=10.0.46.48

    export EUCA_MC_PUBLIC_INTERFACE=eth0
    export EUCA_MC_PRIVATE_INTERFACE=eth1
    export EUCA_MC_STORAGE_INTERFACE=eth2
    export EUCA_MC_PUBLIC_IP=10.0.14.48
    export EUCA_MC_PRIVATE_IP=10.0.30.48
    export EUCA_MC_STORAGE_IP=10.0.46.48

    export EUCA_OSP_PUBLIC_INTERFACE=eth0
    export EUCA_OSP_PRIVATE_INTERFACE=eth1
    export EUCA_OSP_STORAGE_INTERFACE=eth2
    export EUCA_OSP_PUBLIC_IP=10.0.14.48
    export EUCA_OSP_PRIVATE_IP=10.0.30.48
    export EUCA_OSP_STORAGE_IP=10.0.46.48

    export EUCA_CC_PUBLIC_INTERFACE=eth0
    export EUCA_CC_PRIVATE_INTERFACE=eth1
    export EUCA_CC_STORAGE_INTERFACE=eth2
    export EUCA_CC_PUBLIC_IP=10.0.14.51
    export EUCA_CC_PRIVATE_IP=10.0.30.51
    export EUCA_CC_STORAGE_IP=10.0.46.51

    export EUCA_SC_PUBLIC_INTERFACE=eth0
    export EUCA_SC_PRIVATE_INTERFACE=eth1
    export EUCA_SC_STORAGE_INTERFACE=eth2
    export EUCA_SC_PUBLIC_IP=10.0.14.51
    export EUCA_SC_PRIVATE_IP=10.0.30.51
    export EUCA_SC_STORAGE_IP=10.0.46.51

    export EUCA_NC_PUBLIC_BRIDGE=br14
    export EUCA_NC_PRIVATE_BRIDGE=br30
    export EUCA_NC_STORAGE_BRIDGE=br46

    export EUCA_NC1_PUBLIC_IP=10.0.14.17
    export EUCA_NC1_PRIVATE_IP=10.0.30.17
    export EUCA_NC1_STORAGE_IP=10.0.46.17
    ```

### Install Miscellaneous Packages

1. (ALL) Install packages

    ```bash
    yum install -y wget zip unzip git bind-utils nc tree
    ```

### Initialize External DNS

I will not describe this in detail here, except to note that this must be in place and working
properly before registering services with the method outlined below, as I will be using DNS names
for the services so they look more AWS-like.

You should be able to resolve these names with these results:

```bash
dig +short ${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.0.14.48

dig +short clc.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.0.14.48
```

### Initialize Dependencies

1. (CLC+UFS+MC+OSP): Confirm storage

    The virtual hosts which participate in this hybrid virtual/physical POC were created by
    virt-install using a kickstart inserted into the initial ramdisk, which installs minimal
    CentOS and some custom local RPMs for repositories and certificate authorities, and
    configures additional storage. This applies to all but the NC.

    See /root/anaconda-ks.cfg (a copy of the kickstart used), and /root/anaconda-ks.log
    (a log of the post-install actions) on each virtual host for details.

    Here is the output of some disk commands showing the storage layout created by kickstart.

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/local-root
                          5.3G  1.1G  4.0G  21% /
    tmpfs                 939M     0  939M   0% /dev/shm
    /dev/vda1             488M   55M  408M  12% /boot
    /dev/mapper/eucalyptus-eucalyptus
                          126G   60M  120G   1% /var/lib/eucalyptus

    fdisk -l

    Disk /dev/vda: 8589 MB, 8589934592 bytes
    16 heads, 63 sectors/track, 16644 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x0002768d

       Device Boot      Start         End      Blocks   Id  System
    /dev/vda1   *           3        1043      524288   83  Linux
    Partition 1 does not end on cylinder boundary.
    /dev/vda2            1043       16645     7863296   8e  Linux LVM
    Partition 2 does not end on cylinder boundary.

    Disk /dev/vdb: 137.4 GB, 137438953472 bytes
    16 heads, 63 sectors/track, 266305 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-swap: 2147 MB, 2147483648 bytes
    255 heads, 63 sectors/track, 261 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-root: 5872 MB, 5872025600 bytes
    255 heads, 63 sectors/track, 713 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/eucalyptus-eucalyptus: 137.4 GB, 137434759168 bytes
    255 heads, 63 sectors/track, 16708 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000

    pvscan
      PV /dev/vdb    VG eucalyptus   lvm2 [128.00 GiB / 0    free]
      PV /dev/vda2   VG local        lvm2 [7.47 GiB / 0    free]
      Total: 2 [135.46 GiB] / in use: 2 [135.46 GiB] / in no VG: 0 [0   ]

    lvscan
      ACTIVE            '/dev/eucalyptus/eucalyptus' [128.00 GiB] inherit
      ACTIVE            '/dev/local/swap' [2.00 GiB] inherit
      ACTIVE            '/dev/local/root' [5.47 GiB] inherit
    ```

2. (CC+SC): Confirm storage
 
    Here is the output of some disk commands showing the storage layout created by kickstart.

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/local-root
                          5.3G  1.1G  4.0G  21% /
    tmpfs                 939M     0  939M   0% /dev/shm
    /dev/vda1             488M   55M  408M  12% /boot
    /dev/mapper/eucalyptus-eucalyptus
                           32G   48M   30G   1% /var/lib/eucalyptus

    fdisk -l

    Disk /dev/vda: 8589 MB, 8589934592 bytes
    16 heads, 63 sectors/track, 16644 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x000296b5

       Device Boot      Start         End      Blocks   Id  System
    /dev/vda1   *           3        1043      524288   83  Linux
    Partition 1 does not end on cylinder boundary.
    /dev/vda2            1043       16645     7863296   8e  Linux LVM
    Partition 2 does not end on cylinder boundary.

    Disk /dev/vdb: 137.4 GB, 137438953472 bytes
    16 heads, 63 sectors/track, 266305 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/vdc: 137.4 GB, 137438953472 bytes
    16 heads, 63 sectors/track, 266305 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-swap: 2147 MB, 2147483648 bytes
    255 heads, 63 sectors/track, 261 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-root: 5872 MB, 5872025600 bytes
    255 heads, 63 sectors/track, 713 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/eucalyptus-eucalyptus: 34.4 GB, 34359738368 bytes
    255 heads, 63 sectors/track, 4177 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000

    pvscan
      PV /dev/vdb    VG eucalyptus   lvm2 [128.00 GiB / 96.00 GiB free]
      PV /dev/vdc    VG eucalyptus   lvm2 [128.00 GiB / 128.00 GiB free]
      PV /dev/vda2   VG local        lvm2 [7.47 GiB / 0    free]
      Total: 3 [263.46 GiB] / in use: 3 [263.46 GiB] / in no VG: 0 [0   ]

    lvscan
      ACTIVE            '/dev/eucalyptus/eucalyptus' [32.00 GiB] inherit
      ACTIVE            '/dev/local/swap' [2.00 GiB] inherit
      ACTIVE            '/dev/local/root' [5.47 GiB] inherit
    ```

3. (NC): Confirm storage
 
    The physical hosts which participate in this hybrid virtual/physical POC were created by 
    PXE boot with a network OS and kickstart, which installs minimal CentOS and some custom
    local RPMs for repositories and certificate authorities. There is a single SSD disk, 
    used for swap and /, but no additional storage.

    Here is the output of some disk commands showing the storage layout created by kickstart.

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/local-root
                          427G  2.4G  403G   1% /
    tmpfs                 7.8G  232K  7.8G   1% /dev/shm
    /dev/sda1             240M   58M  170M  26% /boot

    fdisk -l

    Disk /dev/sda: 500.1 GB, 500107862016 bytes
    255 heads, 63 sectors/track, 60801 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00086aef

       Device Boot      Start         End      Blocks   Id  System
    /dev/sda1   *           1          33      262144   83  Linux
    Partition 1 does not end on cylinder boundary.
    /dev/sda2              33       60802   488123392   8e  Linux LVM

    Disk /dev/mapper/local-swap: 34.4 GB, 34359738368 bytes
    255 heads, 63 sectors/track, 4177 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-root: 465.5 GB, 465467080704 bytes
    255 heads, 63 sectors/track, 56589 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x00000000

    pvscan
      PV /dev/sda2   VG local   lvm2 [465.50 GiB / 0    free]
      Total: 1 [465.50 GiB] / in use: 1 [465.50 GiB] / in no VG: 0 [0   ]

    lvscan
      ACTIVE            '/dev/local/swap' [32.00 GiB] inherit
      ACTIVE            '/dev/local/root' [433.50 GiB] inherit
    ```

4. (ALL): Disable zero-conf network

    Skip: This was done in the kickstart

    ```bash
    # sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    ```

5. (NC): Install bridge utilities package

    Skip: This was done in the kickstart

    ```bash
    # yum install -y bridge-utils
    ```

6. (NC): Create Bridges

    To simplify the configuration and more closely match the bridge configuration of the
    first physical host which runs the 4 virtual control-plane VMs, we have a single
    ethernet interface on the host connected to a L3 switch, which is configured to send
    a trunk consisting of the Virtual (public, native VLAN), Virtual-Private, and
    Virtual-SAN VLANs.

    Currently this bridging is configured manually, with these statements.

    ```bash
    cat << EOF > /etc/sysconfig/network
    NETWORKING=yes
    NETWORKING_IPV6=no
    HOSTNAME=mjcsbapvs02.sba.mjcconsulting.com
    GATEWAY=10.0.14.1
    NOZEROCONF=yes
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br14
    # MJC Consulting Santa Barbara Virtual Zone
    NAME=br14
    DEVICE=br14
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR0=10.0.14.17
    PREFIX0=24
    GATEWAY0=10.0.14.1
    IPADDR1=10.0.14.9
    PREFIX1=24
    GATEWAY1=10.0.14.1
    DNS1=10.0.14.8
    DNS2=10.0.14.9
    DNS3=8.8.8.8
    DOMAIN="sba.mjcconsulting.com mjcconsulting.com"
    DEFROUTE=yes
    PEERDNS=yes
    PEERROUTES=yes
    IPV6INIT=no
    STP=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br30
    # MJC Consulting Santa Barbara Virtual-Private Zone
    NAME=br30
    DEVICE=br30
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR0=10.0.30.17
    PREFIX0=24
    GATEWAY0=10.0.30.1
    DNS1=10.0.14.8
    DNS2=10.0.14.9
    DNS3=8.8.8.8
    DOMAIN="sba.mjcconsulting.com mjcconsulting.com"
    IPV6INIT=no
    STP=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br46
    # MJC Consulting Santa Barbara Virtual-SAN Zone
    NAME=br46
    DEVICE=br46
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR0=10.0.46.17
    PREFIX0=24
    GATEWAY0=10.0.46.1
    DNS1=10.0.14.8
    DNS2=10.0.14.9
    DNS3=8.8.8.8
    IPV6INIT=no
    STP=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
    # MJC Consulting Santa Barbara Virtual Zone
    NAME=eth0
    DEVICE=eth0
    TYPE=Ethernet
    HWADDR=74:D4:35:C6:0D:FF
    ONBOOT=yes
    NETBOOT=yes
    BOOTPROTO=none
    BRIDGE=br14
    IPV6INIT=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0.30
    # MJC Consulting Santa Barbara Virtual-Private Zone
    NAME=eth0.30
    DEVICE=eth0.30
    TYPE=Vlan
    VLAN=yes
    VLAN_ID=30
    PHYSDEV=eth0
    MASTER=br30
    BRIDGE=br30
    ONBOOT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0.46
    # MJC Consulting Santa Barbara Virtual-Storage Zone
    NAME=eth0.46
    DEVICE=eth0.46
    TYPE=Vlan
    VLAN=yes
    VLAN_ID=46
    PHYSDEV=eth0
    MASTER=br46
    BRIDGE=br46
    ONBOOT=yes
    NM_CONTROLLED=no
    EOF
    ```

7. (ALL): Restart networking

    ```bash
    service network restart
    ```

8. (ALL): Confirm networking

    What you should see is 3 interfaces on all virtual hosts, using eth0, eth1, and eth2,
    for the public, private and storage networks, respectively. And 3 bridges on all
    physical hosts, using br14, br30 and br46 for the public, private and storage networks,
    respectively. All hosts should be using 10.0.14.1 as the default gateway.

    ```bash
    ip addr | grep " inet "
    netstat -nr
    ```

9. (CLC+UFS+MC+OSP): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * udp   53 - DNS (CLC)
    * tcp   53 - DNS (CLC)
    * tcp   80 - Console - HTTP (MC)
    * tcp  443 - Console - HTTPS (MC)
    * tcp 5005 - Debug (CLC+UFS+OSP)
    * tcp 7500 - Diagnostics (CLC+UFS+OSP)
    * tcp 8080 - Credentials (CLC)
    * tcp 8772 - Debug (CLC+UFS+OSP)
    * tcp 8773 - Web services (CLC+UFS+OSP)
    * tcp 8777 - Database (CLC)
    * tcp 8778 - Multicast (CLC+UFS+OSP)
    * tcp 8779-8849 - jGroups (CLC+UFS+OSP)
    * tcp 8888 - Console - Direct (MC)


    ```bash
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
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779-8849 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT
    EOF

    chkconfig iptables on
    service iptables stop
    ```

10. (CC+SC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * tcp 5005 - Debug (CC+SC)
    * tcp 7500 - Diagnostice (SC)
    * tcp 8772 - Debug (CC+SC)
    * tcp 8773 - Web services (SC)
    * tcp 8774 - Web services (CC)
    * tcp 8778 - Multicast (CC+SC)
    * tcp 8779-8849 - jGroups (SC)


    ```bash
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
    ```

11. (NC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp    22 - Login, Control (ALL)
    * tcp  5005 - Debug (NC)
    * tcp  8772 - Debug (NC)
    * tcp  8773 - Web services (NC)
    * tcp  8775 - Web services (NC)
    * tcp  8778 - Multicast (NC)
    * tcp 16514 - TLS, needed for node migrations (NC)


    ```bash
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
    ```

12. (ALL): Disable SELinux

    ```bash
    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    setenforce 0
    ```

13. (ALL): Install and Configure the NTP service

    ```bash
    yum install -y ntp

    chkconfig ntpd on
    service ntpd start

    ntpdate -u  0.centos.pool.ntp.org
    hwclock --systohc
    ```

14. (ALL) Install and Configure Mail Relay

    ```bash
    yum install -y postfix

    pushd /etc/postfix

    cp -a main.cf main.cf.orig

    cat << EOF > main.cf
    #
    # Postfix Null Client Configuration
    #
    # This configuration file defines an internal null mail client
    # - Accepts mail from this host only
    # - Does not accept mail from the network
    # - Does not relay mail
    # - Does not deliver local mail
    #

    # INTERNET HOST AND DOMAIN NAMES
    myhostname = $(hostname)
    mydomain = $(hostname -d)

    # SENDING MAIL
    myorigin = \$mydomain

    sender_canonical_maps = hash:/etc/postfix/sender_canonical

    # RECEIVING MAIL (Only local mail)
    inet_interfaces = localhost

    # RELAYING MAIL (No Relay, local only)
    mynetworks = 127.0.0.0/8

    relayhost = \$mydomain

    # LOCAL DELIVERY (Disabled)
    mydestination =
    local_transport = error:local delivery is disabled
    alias_maps = 
    EOF

    cp -a master.cf master.cf.orig

    cat << EOF > master.cf
    #
    # Postfix Null Client Master Configuration
    #
    # This configuration file defines an internal null mail client
    # - Accepts mail from this host only
    # - Does not accept mail from the network
    # - Does not relay mail
    # - Does not deliver local mail
    #
    # ==========================================================================
    # service type  private unpriv  chroot  wakeup  maxproc command + args
    #               (yes)   (yes)   (yes)   (never) (100)
    # ==========================================================================
    smtp      inet  n       -       n       -       -       smtpd
    pickup    fifo  n       -       n       60      1       pickup
    cleanup   unix  n       -       n       -       0       cleanup
    qmgr      fifo  n       -       n       300     1       qmgr
    tlsmgr    unix  -       -       n       1000?   1       tlsmgr
    rewrite   unix  -       -       n       -       -       trivial-rewrite
    bounce    unix  -       -       n       -       0       bounce
    defer     unix  -       -       n       -       0       bounce
    trace     unix  -       -       n       -       0       bounce
    verify    unix  -       -       n       -       1       verify
    flush     unix  n       -       n       1000?   0       flush
    proxymap  unix  -       -       n       -       -       proxymap
    smtp      unix  -       -       n       -       -       smtp
    relay     unix  -       -       n       -       -       smtp
            -o fallback_relay=
    #       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
    showq     unix  n       -       n       -       -       showq
    error     unix  -       -       n       -       -       error
    discard   unix  -       -       n       -       -       discard
    anvil     unix  -       -       n       -       1       anvil
    scache    unix  -       -       n       -       1       scache
    EOF

    cat << EOF > sender_canonical
    #
    # Postfix Sender Canonical Map
    #

    root	$(hostname -s)
    EOF

    postmap sender_canonical

    chkconfig postfix on
    service postfix restart

    popd
    ```

15. (ALL) Install Email test client and test email

    Sending to personal email address on Google Apps - Please update to use your own email address!

    Confirm email is sent to relay by tailing /var/log/maillog on this host and on mail relay host.

    ```bash
    yum install -y mutt

    echo "test" | mutt -x -s "Test from $(hostname -s) on $(date)" michael.crawford@mjcconsulting.com
    ````

16. (CC): Configure packet routing

    Note that while this is not required when using EDGE mode, as the CC no longer routes traffic,
    you will get a warning when starting the CC if this routing has not been configured, and the
    package would turn this on at that time. So, this is to prevent that warning.

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    ```

17. (NC): Configure packet routing

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    cat /proc/sys/net/bridge/bridge-nf-call-iptables
    ```

### Prepare Network

1. (ALL): Configure external switches, routers and firewalls to allow Eucalyptus Traffic
 
    The purpose of this section is to confirm external network dependencies are configured properly
    for Eucalyptus network traffic.
 
    TBD: Validate protocol source:port to dest:port traffic
    TBD: It would be ideal if we could create RPMs for a simulator for each node type, which couldi
    send and receive dummy traffic to confirm there are no external firewall or routing issues,
    prior to their removal and replacement with the actual packages
 
2. (CLC+UFS+OSP/SC): Run tomography tool
 
    This tool should be run simultaneously on all hosts running Java components.
 
    ```bash
    yum install -y java
 
    mkdir -p ~/src/eucalyptus
    cd ~/src/eucalyptus
    git clone https://github.com/eucalyptus/deveutils
 
    cd deveutils/network-tomography
    ./network-tomography ${EUCA_CLC_PRIVATE_IP} ${EUCA_SC_PRIVATE_IP}
    ```
 
3. (CLC): Scan for unknown SSH host keys
 
    ```bash
    ssh-keyscan ${EUCA_CLC_PUBLIC_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CLC_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
 
    ssh-keyscan ${EUCA_CC_PUBLIC_IP}  2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CC_PRIVATE_IP}  2> /dev/null >> /root/.ssh/known_hosts
 
    ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```
 
4. (CC): Scan for unknown SSH host keys
 
    ```bash
    ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```

### Install Eucalyptus

1. (ALL): Configure yum repositories

    This first set of packages is required to configure access to the Eucalyptus yum repositories
    which contain open source Eucalyptus software, and their dependencies.

    We can either use the external repos which are configured as RPMs...

    ```bash
    yum install -y \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm
    ```

    **OR** we can use some internal repos which I have created to speed things up.

    Here we will create custom repository configuration files, as there are internal mirrors in this environment designed
    for faster installation. The internal mirror configuration also has `mirrorlist` logic which returns both the internal
    and external Eucalyptus repositories, so that the external repositories will be used if the internal replicas are 
    off-line. This environment normally uses RPMs in a manner similar to Eucalyptus to install local repositories, and I will
    be updating these instructions to reference such repos once I have time to build and publish them.

    ```bash
    cat << EOF > /etc/yum.repos.d/eucalyptus.repo
    # eucalyptus.repo
    #
    # This repo contains Eucalyptus packages
    #
    # The MJC Consulting mirror system uses the connecting IP address of the client
    # and the update status of each mirror to pick mirrors that are updated to and
    # geographically close to the client.  You should use this for MJC Consulting
    # updates unless you are manually picking other mirrors.
    #
    # If the mirrorlist= does not work for you, as a fall back you can try the
    # remarked out baseurl= line instead.
    #

    [eucalyptus]
    name=Eucalyptus 4.1
    mirrorlist=http://mirrorlist.mjcconsulting.com/?distro=centos&release=\$releasever&arch=\$basearch&repo=eucalyptus&version=4.1
    #baseurl=http://mirror.mjcconsulting.com/centos/\$releasever/eucalyptus/4.1/\$basearch/
    priority=1
    enabled=1
    gpgcheck=1
    gpgkey=http://mirror.mjcconsulting.com/centos/RPM-GPG-KEY-eucalyptus-release
    EOF

    cat << EOF > /etc/yum.repos.d/euca2ools.repo
    # euca2ools.repo
    #
    # This repo contains Euca2ools packages
    #
    # The MJC Consulting mirror system uses the connecting IP address of the client
    # and the update status of each mirror to pick mirrors that are updated to and
    # geographically close to the client.  You should use this for MJC Consulting
    # updates unless you are manually picking other mirrors.
    #
    # If the mirrorlist= does not work for you, as a fall back you can try the
    # remarked out baseurl= line instead.
    #

    [euca2ools]
    name=Euca2ools 3.2
    mirrorlist=http://mirrorlist.mjcconsulting.com/?distro=centos&release=\$releasever&arch=\$basearch&repo=euca2ools&version=3.2
    #baseurl=http://mirror.mjcconsulting.com/centos/\$releasever/euca2ools/3.2/\$basearch/
    priority=1
    enabled=1
    gpgcheck=1
    gpgkey=http://mirror.mjcconsulting.com/centos/RPM-GPG-KEY-eucalyptus-release
    EOF
    ```

    Optional: This second set of packages is required to configure access to the Eucalyptus yum
    repositories which contain subscription-only Eucalyptus software, which requires a license.

    ```bash
    yum install -y http://mirror.mjcconsulting.com/downloads/eucalyptus/licenses/eucalyptus-enterprise-license-1-1.151702164410-Euca_HP_SalesEng.noarch.rpm
    yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm
    ```

2. (ALL) Confirm yum repositories

    Show configured repositories and any yum priorities.

    ```bash
    yum repolist

    sed -n -e "/^\[/h; /priority *=/{ G; s/\n/ /; s/ity=/ity = /; p }" /etc/yum.repos.d/*.repo | sort -k3n
    ```

3. (CLC+UFS+MC+OSP): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucalyptus-service-image eucaconsole eucalyptus-walrus
    ```

4. (SC+CC): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucalyptus-sc eucalyptus-cc
    ```

5. (NC): Install packages

    ```bash
    yum install -y eucalyptus-nc
    ```

6. (NC): Remove Devfault libvirt network.

    ```bash
    virsh net-destroy default
    virsh net-autostart default --disable
    ```

### Configure Eucalyptus

1. (CLC+UFS+MC+OSP):  1. Configure Eucalyptus Networking

    This is a virtual machine, which has 3 interfaces eth0, eth1, eth2, corresponding to the Eucalyptus public,
    private and storage networks created within KVM, and bridged to the corresponding VLANs which are brought
    into the physical host via a trunk.

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CLC_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CLC_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CLC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

2. (CC+SC): Configure Eucalyptus Networking

    This is a virtual machine, which has 3 interfaces eth0, eth1, eth2, corresponding to the Eucalyptus public,
    private and storage networks created within KVM, and bridged to the corresponding VLANs which are brought
    into the physical host via a trunk.

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CC_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CC_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

3. (NC): Configure Eucalyptus Networking

    This is a physical machine, which has 1 interface configured as a trunk, on which the Eucalyptus public,
    private and storage networks are configured. Bridges corresponding to all three networks have been created,
    with IP addresses, allowing their use by the host as well as by virtual machines when needed.

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_NC_PUBLIC_BRIDGE}\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

4. (CLC): Create Eucalyptus EDGE Networking configuration file

    This can not be loaded until the cloud is initialized.

    ```bash
    cat << EOF > /etc/eucalyptus/edge-$(date +%Y-%m-%d).json
    {
      "InstanceDnsDomain": "${EUCA_DNS_INSTANCE_SUBDOMAIN}.${EUCA_DNS_PRIVATE_DOMAIN}",
      "InstanceDnsServers": [
        "${EUCA_CLC_PUBLIC_IP}"
      ],
      "PublicIps": [
        "${EUCA_PUBLIC_IP_RANGE}"
      ],
      "Clusters": [
        {
          "Name": "${EUCA_CLUSTER1}",
          "MacPrefix": "d0:0d",
          "Subnet": {
            "Name": "${EUCA_CLUSTER1_PRIVATE_NAME}",
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
    ```

5. (NC): Configure Eucalyptus Disk Allocation

    ```bash
    nc_work_size=2400000
    nc_cache_size=300000

    sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
           -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf
    ```

6. (NC): Configure Eucalyptus to use Private IP for Metadata

    ```bash
    cat << EOF >> /etc/eucalyptus/eucalyptus.conf

    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    EOF
    ```

7. (CLC+UFS+OSP/SC): Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value

    ```bash
    heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

8. (MC): Configure Management Console with User Facing Services address

    The clchost parameter within console.ini is misleadingly named, as it should reference the
    public IP of the host running User Facing Services.

    ```bash
    cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.orig

    sed -i -e "/^clchost = localhost$/s/localhost/$EUCA_UFS_PUBLIC_IP/" \
           -e "/# since eucalyptus allows for different services to be located on different/d" \
           -e "/# physical hosts, you may override the above host and port for each service./d" \
           -e "/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d" \
           -e "/For each service, you can specify a different host and\/or port, for example;/d" \
           -e "/#elb.host=10.20.30.40/d" \
           -e "/#elb.port=443/d" \
           -e "/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d" \
           -e "/# that won't work from client's browsers./d" \
           -e "/#s3.host=<your host IP or name>/d" /etc/eucaconsole/console.ini
    ```

### Start Eucalyptus

1. (CLC): Initialize the Cloud Controller service

    ```bash
    euca_conf --initialize
    ```

2. (CLC+UFS+OSP/SC): Start the Cloud Controller service

    ```bash
    service eucalyptus-cloud start
    ```

3. (CC): Start the Cluster Controller service

    ```bash
    service eucalyptus-cc start
    ```

4. (NC): Start the Node Controller and Eucanetd services

    Expect failure messages due to missing keys. This will be corrected when the nodes are
    registered.

    ```bash
    service eucalyptus-nc start

    service eucanetd start
    ```

5. (MC): Start the Management Console service

    ```bash
    service eucaconsole start
    ```

6. (All): Confirm service startup

    Confirm logs are being written.

    ```bash
    ls -l /var/log/eucalyptus
    ```

### Register Eucalyptus

1. (CLC): Register User-Facing services

    Wait for CLC services to respond.

    ```bash
    while true; do
        echo -n "Testing services... "
        if nc -z localhost 8777 &> /dev/null; then 
            echo " Started"
            break
        else
            echo " Not yet running"
            echo -n "Waiting another 15 seconds..."
            sleep 15
            echo " Done"
        fi
    done
    ```

    Register UFS services.


    ```bash
    euca_conf --register-service -T user-api -N ${EUCA_SERVICE_API_NAME} -H ${EUCA_UFS_PRIVATE_IP}
    ```

    Wait for UFS services to respond.

    ```bash
    while true; do
        echo -n "Testing services... "
        if curl -s http://$EUCA_UFS_PRIVATE_IP:8773/services/User-API | grep -s -q 404; then
            echo " Started"
            break
        else
            echo " Not yet running"
            echo -n "Waiting another 15 seconds..."
            sleep 15
            echo " Done"
        fi
    done
    ```

    Optional: Confirm service status.

    * All services should be in the ENABLED state except for objectstorage, loadbalancingbackend
      and imagingbackend.
    * The cluster, storage and walrusbackend services should not yet be listed.

    ```bash
    euca-describe-services | cut -f1-5
    ```

2. (CLC): Register Walrus as the Object Storage Provider (OSP)

    ```bash
    euca_conf --register-walrusbackend -P walrus -C walrus -H ${EUCA_OSP_PRIVATE_IP}
    sleep 15
    ```

3. (CLC): Register Storage Controller service

    ```bash
    euca_conf --register-sc -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_SC_NAME} -H ${EUCA_SC_PRIVATE_IP}
    sleep 15
    ```

4. (CLC): Register Cluster Controller service

    ```bash
    euca_conf --register-cluster -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_CC_NAME} -H ${EUCA_CC_PRIVATE_IP}
    sleep 15
    ```

5. (CC): Register Node Controller host(s)

    ```bash
    euca_conf --register-nodes="${EUCA_NC1_PRIVATE_IP}"
    sleep 15
    ```

6. (NC): Restart the Node Controller services

    The failure messages due to missing keys should no longer be there on restart.

    ```bash
    service eucalyptus-nc restart
    ```

### Runtime Configuration

1. (CLC): Use Eucalyptus Administrator credentials

    Note that there is a limit to the number of times the primary key and certificate
    can be downloaded, without deleting and recreating them. So, insure you do not
    accidentally delete any primary key or certificate files when refreshing credentials
    on steps further down in this procedure.

    Additionally, if `euca_conf --get-credentials` or `euca-get-credentials` is called
    to refresh credentials, and the key or certificate is not included in the download
    zip file because they were previously downloaded, the included eucarc file will be
    missing two lines which set the EC2_PRIVATE_KEY and EC2_CERT environment variables
    to the (now missing) files. This causes all image related API calls to fail.

    To work around this issue, we must save the original eucarc file, and insure we do
    not delete the original key and certificate files, and replace the missing lines
    within eucarc on each refresh of credentials.

    ```bash
    mkdir -p ~/creds/eucalyptus/admin

    rm -f ~/creds/eucalyptus/admin.zip

    euca_conf --get-credentials ~/creds/eucalyptus/admin.zip

    unzip ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

    cp -a ~/creds/eucalyptus/admin/eucarc ~/creds/eucalyptus/admin/eucarc.orig

    cat ~/creds/eucalyptus/admin/eucarc

    source ~/creds/eucalyptus/admin/eucarc
    ```

2. (CLC): Confirm initial service status

    * All services should be in the ENABLED state except, for objectstorage, loadbalancingbackend,
      imagingbackend, and storage.
    * All nodes should be in the ENABLED state.

    ````bash
    euca-describe-services | cut -f1-5

    euca-describe-nodes
    ```

3. (CLC): Configure EBS Storage

    This step assumes additional storage configuration as described above was done,
    and there is an empty volume group named `eucalyptus` on the Storage Controller
    intended for DAS storage mode Logical Volumes.

    ```bash
    euca-modify-property -p ${EUCA_CLUSTER1}.storage.blockstoragemanager=das
    sleep 15

    euca-modify-property -p ${EUCA_CLUSTER1}.storage.dasdevice=eucalyptus
    sleep 15
    ```

    Optional: Confirm service status.

    * The storage service should now be in the ENABLED state.
    * All services should be in the ENABLED state except, for objectstorage, loadbalancingbackend
      and imagingbackend.

    ```bash
    euca-describe-services | cut -f1-5
    ```

4. (CLC): Configure Object Storage

    ```bash
    euca-modify-property -p objectstorage.providerclient=walrus
    sleep 15
    ```

    Optional: Confirm service status.

    * The objectstorage service should now be in the ENABLED state.
    * All services should be in the ENABLED state, except for loadbalancingbackend and
      imagingbackend.

    ```bash
    euca-describe-services | cut -f1-5
    ```

5. (CLC): Refresh Eucalyptus Administrator credentials

    As noted above, if the eucarc does not contain the environment variables for the key and
    certificate, we must patch it to add the missing variables which reference the previously
    downloaded versions of the key and certificate files.

    ```bash
    rm -f ~/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

    unzip -uo ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/creds/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/creds/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/creds/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/creds/eucalyptus/admin/eucarc
    fi

    cat ~/creds/eucalyptus/admin/eucarc

    source ~/creds/eucalyptus/admin/eucarc
    ```

6. (CLC): Load Edge Network JSON configuration

    ```bash
    euca-modify-property -f cloud.network.network_configuration=/etc/eucalyptus/edge-$(date +%Y-%m-%d).json
    sleep 15
    ```

7. (CLC): Install the imaging-worker and load-balancer images

    ```bash
    euca-install-load-balancer --install-default

    euca-install-imaging-worker --install-default
    ```

8. (CLC): Confirm service status

    All services should now be in the ENABLED state.

    ```bash
    euca-describe-services | cut -f1-5
    ```

9. (CLC): Confirm apis

    ```bash
    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-instance-types --show-capacity
    ```

### Configure DNS

1. (CLC): Configure Eucalyptus DNS Server

    ```bash
    euca-modify-property -p dns.dns_listener_address_match=${EUCA_CLC_PUBLIC_IP}

    euca-modify-property -p system.dns.nameserver=${EUCA_DNS_PARENT_HOST}

    euca-modify-property -p system.dns.nameserveraddress=${EUCA_DNS_PARENT_IP}
    ```

2. (CLC): Configure DNS Timeout and TTL

    ```bash
    euca-modify-property -p dns.tcp.timeout_seconds=30

    euca-modify-property -p services.loadbalancing.dns_ttl=15
    ```

3. (CLC): Configure DNS Domain

    ```bash
    euca-modify-property -p system.dns.dnsdomain=${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
    ```

4. (CLC): Configure DNS Sub-Domains

    ```bash
    euca-modify-property -p cloud.vmstate.instance_subdomain=.${EUCA_DNS_INSTANCE_SUBDOMAIN}

    euca-modify-property -p services.loadbalancing.dns_subdomain=${EUCA_DNS_LOADBALANCER_SUBDOMAIN}
    ```

5. (CLC): Enable DNS

    ```bash
    euca-modify-property -p bootstrap.webservices.use_instance_dns=true

    euca-modify-property -p bootstrap.webservices.use_dns_delegation=true
    ```

6. (CLC): Refresh Eucalyptus Administrator credentials
 
    As noted above, if the eucarc does not contain the environment variables for the key and 
    certificate, we must patch it to add the missing variables which reference the previously 
    downloaded versions of the key and certificate files.

    ```bash
    mkdir -p ~/creds/eucalyptus/admin

    rm -f ~/creds/eucalyptus/admin.zip

    euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

    unzip -uo ~/creds/eucalyptus/admin.zip -d ~/creds/eucalyptus/admin/

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/creds/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/creds/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/creds/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/creds/eucalyptus/admin/eucarc
    fi

    cat ~/creds/eucalyptus/admin/eucarc

    source ~/creds/eucalyptus/admin/eucarc
    ```

7. (CLC): Display Parent DNS Server Sample Configuration (skipped)

    ```bash
    # TBD
    ```

8. (CLC): Confirm DNS resolution for Services

    ```bash
    dig +short compute.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short objectstorage.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short euare.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short tokens.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short autoscaling.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short cloudformation.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short cloudwatch.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}

    dig +short loadbalancing.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
    ```

### Configure Minimal IAM

1. (CLC): Configure Eucalyptus Administrator Password

    ```bash
    euare-usermodloginprofile -u admin -p password
    ```

### Configure Management Console for SSL

1. (MW): Confirm Eucalyptus Console service on default port

    ```bash
    Browse: http://${EUCA_MC_PUBLIC_IP}:8888
    ```

2. (MC):  4. Stop Eucalyptus Console service

    ```bash
    service eucaconsole stop
    ```

3. (MC): Install Nginx package

    ```bash
    yum install -y nginx
    ```

4. (MC): Configure Nginx

    ```bash
    \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf

    sed -i -e 's/# \(listen 443 ssl;$\)/\1/' \
           -e 's/# \(ssl_certificate\)/\1/' \
           -e 's/\/path\/to\/ssl\/pem_file/\/etc\/eucaconsole\/console.crt/' \
           -e 's/\/path\/to\/ssl\/certificate_key/\/etc\/eucaconsole\/console.key/' /etc/nginx/nginx.conf
    ```

7. (MC): Start Nginx service

    ```bash
    chkconfig nginx on
    service nginx start
    ```

8. (MC): Configure Eucalyptus Console for SSL

    ```bash
    sed -i -e '/^session.secure =/s/= .*$/= true/' \
           -e '/^session.secure/a\
    sslcert=/etc/eucaconsole/console.crt\
    sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini
    ```

9. (MC): Start Eucalyptus Console service

    ```bash
    service eucaconsole start
    ```

10. (MC): Confirm Eucalyptus Console service

    ```bash
    Browse: https://${EUCA_MC_PUBLIC_IP}
    ```

### Configure Images

Optional: If you plan on using this system to run demos, it is preferrable to run the demo setup
scripts, which incorporate this logic as well as performing additional setup, instead.

1. (CLC): Download Images

    ```bash
    wget http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O ~/centos.raw.xz

    xz -v -d ~/centos.raw.xz
    ```

2. (CLC): Install Image

    ```bash
    euca-install-image -n centos65 -b images -r x86_64 -i ~/centos.raw --virtualization-type hvm
    ```

3. (CLC): List Images

    ```bash
    euca-describe-images
    ```

### Test Inter-Component Connectivity

This section has not yet been confirmed for accuracy. Running this is fine, but there may be
additonal ports we should add to ensure complete interconnectivity testing.

1. (MW): Verify Connectivity

    ```bash
    nc -z ${EUCA_CLC_PUBLIC_IP} 8443 || echo 'Connection from MW to CLC:8443 failed!'
    nc -z ${EUCA_CLC_PUBLIC_IP} 8773 || echo 'Connection from MW to CLC:8773 failed!'

    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from MW to Walrus:8773 failed!'
    ```

2. (CLC): Verify Connectivity

    ```bash
    nc -z ${EUCA_SCA_PUBLIC_IP} 8773 || echo 'Connection from CLC to SCA:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from CLC to OSP:8773 failed!'
    nc -z ${EUCA_CCA_PUBLIC_IP} 8774 || echo 'Connection from CLC to CCA:8774 failed!'
    ```

3. (UFS): Verify Connectivity

    ```bash
    nc -z ${EUCA_CLC_PUBLIC_IP} 8773 || echo 'Connection from UFS to CLC:8773 failed!'
    ```

4. (OSP): Verify Connectivity

    ```bash
    nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from OSP to CLC:8777 failed!'
    ```

5. (CC): Verify Connectivity

    ```bash
    nc -z ${EUCA_NCA1_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA1:8775 failed!'
    nc -z ${EUCA_NCA2_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA2:8775 failed!'
    nc -z ${EUCA_NCA3_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA3:8775 failed!'
    nc -z ${EUCA_NCA4_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA4:8775 failed!'
    ```

6. (SC): Verify Connectivity

    ```bash
    nc -z ${EUCA_SCA_PUBLIC_IP} 8773 || echo 'Connection from SCA to SCA:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from SCA to OSP:8773 failed!'
    nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from SCA to CLC:8777 failed!'
    ```

7. (NC): Verify Connectivity

    ```bash
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from NC to OSP:8773 failed!'
    nc -z ${EUCA_SCA_PUBLIC_IP} 8773 || echo 'Connection from NC to SCA:8773 failed!'
    ```

8. (Other): Verify Connectivity

  Use additional commands to verify the following:

  * Verify connection from public IP addresses of Eucalyptus instances (metadata) and CC to CLC
    on TCP port 8773
  * Verify TCP connectivity between CLC, Walrus, SC and VB on TCP port 8779 (or the first
    available port in range 8779-8849)
  * Verify connection between CLC, Walrus, SC, and VB on UDP port 7500
  * Verify multicast connectivity for IP address 228.7.7.3 between CLC, Walrus, SC, and VB on
    UDP port 8773
  * If DNS is enabled, verify connection from an end-user and instance IPs to DNS ports
  * If you use tgt (iSCSI open source target) for EBS storage, verify connection from NC to SC on
    TCP port 3260
  * Test multicast connectivity between each CLC and Walrus, SC, and VMware broker host.

