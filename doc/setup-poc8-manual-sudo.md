# Manual Installation Procedure for 8-Node (4+4) POC (region hp-gol-d1)

This document describes the manual procedure to setup region hp-gol-d1,
based on the "4-node reference architecture", with 4 Node Controllers.

This variant is meant to be run as root

This POC will use **hp-gol-d1** as the AWS_DEFAULT_REGION.

The full parent DNS domain will be hp-gol-d1.mjc.prc.eucalyptus-systems.com.

This is using the following nodes in the PRC:
- odc-d-13: CLC
- odc-d-14: UFS, MC
- odc-d-15: OSP (Walrus)
- odc-d-29: CCA, SCA
- odc-d-35: NCA1
- odc-d-38: NCA2
- odc-f-14: NCA3 (temporary)
- odc-f-17: NCA4 (temporary)

Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- OSP: Object Storage Provider (Walrus)
- CCA:  Cluster Controller Host (Cluster A)
- CCB:  Cluster Controller Host (Cluster B)
- SCA:  Storage Controller Host (Cluster A)
- SCB:  Storage Controller Host (Cluster B)
- NCAn: Node Controller(s) (Cluster A)
- NCBn: Node Controller(s) (Cluster B)

### Configure sudo

This variant of the manual procedure is designed to be run from a normal user account which has
been configured to allow sudo. This section describes what steps related to sudo were done for 
this poc. This is an example - others may configure sudo differently.

These steps must be run as root. However, once these steps are done, all remaining sections can
be run as a user who is in the `wheel` and/or `eucalyptus-install` groups as a secondary member.

Configure sudo so that members of the group `wheel` can sudo **with** a password. Note that this
is now standard behavior for EL 7, and was a very common convention in earlier versions. This
adjustment is not specific to Eucalyptus hosts.

```bash
sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers
```

Optional: Configure sudo so that members of the group `eucalyptus-install` can sudo **without** a
password. This adjustment **is** specific to Eucalyptus, and can eliminate sudo asking for the user
password, but at the cost of some increased security risk. It is recommended that users be removed
from this group, and this group and associated sudo policy be removed once Eucalyptus installation
and testing has been completed.

```bash
groupadd -r eucalyptus-install

echo '%eucalyptus-install ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/eucalyptus-install

chmod 0440 /etc/sudoers.d/eucalyptus-install
```

Add the user who will install Eucalyptus to the `wheel` and/or `eucalyptus-install` groups as a secondary member.

```bash
usermod -a -G wheel,eucalyptus-install ${user}
```

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. (ALL): Define Environment Variables used in upcoming code blocks

    ```bash
    export AWS_DEFAULT_REGION=hp-gol-d1

    export EUCA_DNS_PUBLIC_DOMAIN=mjc.prc.eucalyptus-systems.com
    export EUCA_DNS_PRIVATE_DOMAIN=internal
    export EUCA_DNS_INSTANCE_SUBDOMAIN=cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
    export EUCA_DNS_PARENT_HOST=ns1.mjc.prc.eucalyptus-systems.com
    export EUCA_DNS_PARENT_IP=10.104.10.80

    export EUCA_SERVICE_API_NAME=api

    export EUCA_PUBLIC_IP_RANGE=10.104.40.1-10.104.40.254

    export EUCA_CLUSTER1=${AWS_DEFAULT_REGION}a
    export EUCA_CLUSTER1_CC_NAME=${EUCA_CLUSTER1}-cc
    export EUCA_CLUSTER1_SC_NAME=${EUCA_CLUSTER1}-sc

    export EUCA_CLUSTER1_PRIVATE_IP_RANGE=10.105.40.2-10.105.40.254
    export EUCA_CLUSTER1_PRIVATE_NAME=10.105.0.0
    export EUCA_CLUSTER1_PRIVATE_SUBNET=10.105.0.0
    export EUCA_CLUSTER1_PRIVATE_NETMASK=255.255.0.0
    export EUCA_CLUSTER1_PRIVATE_GATEWAY=10.105.0.1

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

    export EUCA_OSP_PUBLIC_INTERFACE=em1
    export EUCA_OSP_PRIVATE_INTERFACE=em2
    export EUCA_OSP_PUBLIC_IP=10.104.10.85
    export EUCA_OSP_PRIVATE_IP=10.105.10.85

    export EUCA_CCA_PUBLIC_INTERFACE=em1
    export EUCA_CCA_PRIVATE_INTERFACE=em2
    export EUCA_CCA_PUBLIC_IP=10.104.1.208
    export EUCA_CCA_PRIVATE_IP=10.105.1.208

    export EUCA_SCA_PUBLIC_INTERFACE=em1
    export EUCA_SCA_PRIVATE_INTERFACE=em2
    export EUCA_SCA_PUBLIC_IP=10.104.1.208
    export EUCA_SCA_PRIVATE_IP=10.105.1.208

    export EUCA_NC_PRIVATE_BRIDGE=br0
    export EUCA_NC_PRIVATE_INTERFACE=em2
    export EUCA_NC_PUBLIC_INTERFACE=em1

    export EUCA_NCA1_PUBLIC_IP=10.104.1.190
    export EUCA_NCA1_PRIVATE_IP=10.105.1.190

    export EUCA_NCA2_PUBLIC_IP=10.104.1.187
    export EUCA_NCA2_PRIVATE_IP=10.105.1.187

    export EUCA_NCA3_PUBLIC_IP=10.104.10.56
    export EUCA_NCA3_PRIVATE_IP=10.105.10.56

    export EUCA_NCA4_PUBLIC_IP=10.104.10.59
    export EUCA_NCA4_PRIVATE_IP=10.105.10.59
    ```

### Prepare Network

1. (ALL): Configure external switches, routers and firewalls to allow Eucalyptus Traffic

    The purpose of this section is to confirm external network dependencies are configured properly
    for Eucalyptus network traffic.

    TBD: Validate protocol source:port to dest:port traffic
    TBD: It would be ideal if we could create RPMs for a simulator for each node type, which couldi
    send and receive dummy traffic to confirm there are no external firewall or routing issues,
    prior to their removal and replacement with the actual packages

2. (CLC/UFS/OSP/SC): Run tomography tool

    This tool should be run simultaneously on all hosts running Java components.

    ```bash
    sudo yum install -y java

    mkdir -p ~/src/eucalyptus
    cd ~/src/eucalyptus
    git clone https://github.com/eucalyptus/deveutils

    cd deveutils/network-tomography
    ./network-tomography ${EUCA_CLC_PRIVATE_IP} ${EUCA_UFS_PRIVATE_IP} ${EUCA_OSP_PRIVATE_IP} ${EUCA_SCA_PRIVATE_IP}
    ```

3. (CLC): Scan for unknown SSH host keys

    Note: sudo tee needed to append output to file owned by root

    ```bash
    ssh-keyscan ${EUCA_CLC_PUBLIC_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_CLC_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

    ssh-keyscan ${EUCA_UFS_PUBLIC_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_UFS_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

    ssh-keyscan ${EUCA_OSP_PUBLIC_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_OSP_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

    ssh-keyscan ${EUCA_CCA_PUBLIC_IP}  2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_CCA_PRIVATE_IP}  2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null

    ssh-keyscan ${EUCA_NCA1_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA2_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA3_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA4_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ```

4. (CC): Scan for unknown SSH host keys

    ```bash
    ssh-keyscan ${EUCA_NCA1_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA2_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA3_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ssh-keyscan ${EUCA_NCA4_PRIVATE_IP} 2> /dev/null | sudo tee -a /root/.ssh/known_hosts > /dev/null
    ```

### Prepare External DNS

I will not describe this in detail here, except to note that this must be in place and working
properly before registering services with the method outlined below, as I will be using DNS names
for the services so they look more AWS-like.

You should be able to resolve these names with these results:

```bash
dig +short ${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.84

dig +short clc.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.83
```

### Initialize Dependencies

1. (ALL): Configure common additional disk storage

    The hosts which participate in this POC were created by Cobbler via kickstart with the
    it-centos6-x86_64-bare cobbler profile.

    In this profile, we have 2 physical disks presented to the OS as /dev/sda and /dev/sdb.
    In other Cobbler profiles, we typically use software raid on the physical disks, so only
    /dev/sda is presented to the OS. But for this POC, we want to simulate hosts with hardware
    RAID controllers, presenting multiple RAID sets as physical disks.

    Disk sda is partitioned, with partition sda1 formatted as ext4 and mounted as /boot, and
    partition sda2 formatted as an LVM physical disk, and assigned to volume group vg01. 
    Logical volumes of 8GB and 20GB were created for swap and the root filesystem, also formatted
    with ext4. 
 
    Here is the output of some disk commands showing the initial storage layout, before we perform
    additional configuration.

    **Physical Disks and Logical Volumes**

    ```bash
    sudo disk -l

    Disk /dev/sda: 1000.2 GB, 1000204886016 bytes
    255 heads, 63 sectors/track, 121601 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
    Disk identifier: 0x0000f592

       Device Boot      Start         End      Blocks   Id  System
    /dev/sda1   *           1          33      262144   83  Linux
    Partition 1 does not end on cylinder boundary.
    /dev/sda2              33      121602   976498688   8e  Linux LVM

    Disk /dev/sdb: 1000.2 GB, 1000204886016 bytes
    255 heads, 63 sectors/track, 121601 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x0000e434

       Device Boot      Start         End      Blocks   Id  System

    Disk /dev/mapper/vg01-lv_swap: 8388 MB, 8388608000 bytes
    255 heads, 63 sectors/track, 1019 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/vg01-lv_root: 21.5 GB, 21474836480 bytes
    255 heads, 63 sectors/track, 2610 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 4096 bytes
    I/O size (minimum/optimal): 4096 bytes / 4096 bytes
    Disk identifier: 0x00000000
    ```

    **LVM Physical Disks, Volume Groups and Logical Volumes**

    ```bash
    sudo pvscan
      PV /dev/sda2   VG vg01   lvm2 [931.25 GiB / 903.44 GiB free]
      Total: 1 [931.25 GiB] / in use: 1 [931.25 GiB] / in no VG: 0 [0   ]

    sudo vgscan
      Reading all physical volumes.  This may take a while...
      Found volume group "vg01" using metadata type lvm2

    sudo lvscan
      ACTIVE            '/dev/vg01/lv_swap' [7.81 GiB] inherit
      ACTIVE            '/dev/vg01/lv_root' [20.00 GiB] inherit
    ```

    **Mounted Filesystems**

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/vg01-lv_root
                           20G  1.1G   18G   6% /
    tmpfs                 3.9G     0  3.9G   0% /dev/shm
    /dev/sda1             240M   33M  195M  15% /boot
    ```
    
    On all hosts, use the remaining space in the vg01 volume group for
    /var/lib/eucalyptus.

    ```bash
    sudo lvcreate -l 100%FREE -n eucalyptus vg01

    sudo pvscan

    sudo vgscan

    sudo lvscan

    sudo mke2fs -t ext4 /dev/vg01/eucalyptus

    sudo e2label /dev/vg01/eucalyptus eucalyptus

    echo | sudo tee -a /etc/fstab > /dev/null
    echo "LABEL=eucalyptus        /var/lib/eucalyptus             ext4    defaults        1 1" | sudo tee -a /etc/fstab > /dev/null

    sudo mkdir -p /var/lib/eucalyptus
   
    sudo mount /var/lib/eucalyptus
    ```
    
2. (CLC)  Configure additional disk storage for the Cloud Controller

    As we only have 2 physical disks to work with, for the CLC, use of the second disk is best
    suited to keeping the PostgreSQL transaction logs separate from all other disk activity, due to
    the sequential write nature of transaction logs. On many database systems, the speed at which
    transaction logs can be written determines the maximum transactions per second rate.
    This second disk will also be used for a separate logical volume to hold potential PostgreSQL
    archive logs. Normally these would be kept on yet another disk, due to the potential for disk
    contention between transactions and the log archive process, but we only have 2 disks to work
    with, so we will keep them on separate Logical Volumes, the best possible alternative.

    ```bash
    sudo pvcreate -Z y /dev/sdb

    sudo pvscan

    sudo vgcreate eucalyptus /dev/sdb

    sudo lvcreate -l 50%FREE -n xlog eucalyptus
    sudo lvcreate -l 100%FREE -n archive eucalyptus

    sudo mke2fs -t ext4 /dev/eucalyptus/xlog
    sudo mke2fs -t ext4 /dev/eucalyptus/archive

    sudo e2label /dev/eucalyptus/xlog xlog
    sudo e2label /dev/eucalyptus/archive archive

    echo "LABEL=xlog              /var/lib/eucalyptus/tx          ext4    defaults        1 1" | sudo tee -a /etc/fstab > /dev/null
    echo "LABEL=archive           /var/lib/eucalyptus/archive     ext4    defaults        1 1" | sudo tee -a /etc/fstab > /dev/null

    sudo mkdir -p /var/lib/eucalyptus/tx
    sudo mkdir -p /var/lib/eucalyptus/archive
   
    sudo mount /var/lib/eucalyptus/tx
    sudo mount /var/lib/eucalyptus/archive
    ```

3. (OSP)  Configure additional disk storage for the Object Storage Provider

    As we only have 2 physical disks to work with, for the OSP, use of the second disk is best
    suited to keeping the storage buckets separate from other disk activity.

    ```bash
    sudo pvcreate -Z y /dev/sdb

    sudo pvscan

    sudo vgcreate eucalyptus /dev/sdb

    sudo lvcreate -l 100%FREE -n bukkits eucalyptus

    sudo mke2fs -t ext4 /dev/eucalyptus/bukkits
    
    sudo e2label /dev/eucalyptus/bukkits bukkits
    
    echo "LABEL=bukkits           /var/lib/eucalyptus/bukkits     ext4    defaults        1 1" | sudo tee -a /etc/fstab > /dev/null

    sudo mkdir -p /var/lib/eucalyptus/bukkits
   
    sudo mount /var/lib/eucalyptus/bukkits
    ```

4. (SC)  Configure additional disk storage for the Storage Controller

    As we only have 2 physical disks to work with, for the SC, use of the second disk is best
    suited to an additional volume group used for the logical volumes which are used for EBS
    volumes. Note in this case we do not explicitly create the logical volumes or format
    filesystems on top of them, as these tasks are handled by the Eucalyptus Storage Controller.

    ```bash
    sudo pvcreate -Z y /dev/sdb

    sudo pvscan

    sudo vgcreate eucalyptus /dev/sdb
    ```

5. (NC)  Configure additional disk storage for the Node Controller

    As we only have 2 physical disks to work with, for the NC, use of the second disk is best
    suited to where the instance virtual disks are created.

    ```bash
    sudo pvcreate -Z y /dev/sdb

    sudo pvscan

    sudo vgcreate eucalyptus /dev/sdb

    sudo lvcreate -l 100%FREE -n instances eucalyptus

    sudo mke2fs -t ext4 /dev/eucalyptus/instances
    
    sudo e2label /dev/eucalyptus/instances instances
    
    echo "LABEL=instances         /var/lib/eucalyptus/instances   ext4    defaults        1 1" | sudo tee -a /etc/fstab > /dev/null

    sudo mkdir -p /var/lib/eucalyptus/instances
   
    sudo mount /var/lib/eucalyptus/instances
    ```

7. (ALL): Confirm storage

    ```bash
    df -h

    sudo pvscan

    sudo vgscan

    sudo lvscan
    ```

8. (ALL): Disable zero-conf network

    ```bash
    sudo sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    ```

9. (NC): Install bridge utilities package

    ```bash
    sudo yum install -y bridge-utils
    ```

10. (NC): Create Private Bridge

    Move the static IP of the private interface to the private bridge

    ```bash
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
    ```

11. (NC): Convert Private Ethernet Interface to Private Bridge Slave

    ```bash
    sudo sed -i -e "\$aBRIDGE=${EUCA_NC_PRIVATE_BRIDGE}" \
                -e "/^BOOTPROTO=/s/=.*$/=none/" \
                -e "/^IPADDR=/d" \
                -e "/^NETMASK=/d" \
                -e "/^PERSISTENT_DHCLIENT=/d" \
                -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE}
    ```

12. (ALL): Restart networking

    ```bash
    sudo service network restart
    ```

13. (ALL): Confirm networking

    ```bash
    ip addr | grep " inet "
    netstat -nr
    ```

14. (CLC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * udp   53 - DNS (CLC)
    * tcp   53 - DNS (CLC)
    * tcp 5005 - Debug (CLC)
    * tcp 8080 - Credentials (CLC)
    * tcp 8772 - Debug (CLC)
    * tcp 8773 - Web services (CLC)
    * tcp 8777 - Database (CLC)
    * tcp 8778 - Multicast (CLC)


    ```bash
    cat << EOF | sudo tee /etc/sysconfig/iptables > /dev/null
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

    sudo chkconfig iptables on
    sudo service iptables stop
    ```

15. (UFS+MC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * tcp   80 - Console - HTTP (MC)
    * tcp  443 - Console - HTTPS (MC)
    * tcp 5005 - Debug (UFS)
    * tcp 7500 - Diagnostics (UFS)
    * tcp 8772 - Debug (UFS)
    * tcp 8773 - Web services (UFS)
    * tcp 8778 - Multicast (UFS)
    * tcp 8779-8849 - jGroups (UFS)
    * tcp 8888 - Console - Direct (MC)


    ```bash
    cat << EOF | sudo tee /etc/sysconfig/iptables > /dev/null
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

    sudo chkconfig iptables on
    sudo service iptables stop
    ```

16. (OSP): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * tcp 5005 - Debug (OSP)
    * tcp 7500 - Diagnostics (OSP)
    * tcp 8772 - Debug (OSP)
    * tcp 8773 - Web services (OSP)
    * tcp 8778 - Multicast (OSP)
    * tcp 8779-8849 - jGroups (OSP)


    ```bash
    cat << EOF | sudo tee /etc/sysconfig/iptables > /dev/null
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

    sudo chkconfig iptables on
    sudo service iptables stop
    ```

17. (SC+CC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * tcp 5005 - Debug (SC, CC)
    * tcp 7500 - Diagnostice (SC)
    * tcp 8772 - Debug (SC, CC)
    * tcp 8773 - Web services (SC)
    * tcp 8774 - Web services (CC)
    * tcp 8778 - Multicast (SC, CC)
    * tcp 8779-8849 - jGroups (SC)


    ```bash
    cat << EOF | sudo tee /etc/sysconfig/iptables > /dev/null
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

    sudo chkconfig iptables on
    sudo service iptables stop
    ```

18. (NC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp    22 - Login, Control (ALL)
    * tcp  5005 - Debug (NC)
    * tcp  8772 - Debug (NC)
    * tcp  8773 - Web services (NC)
    * tcp  8775 - Web services (NC)
    * tcp  8778 - Multicast (NC)
    * tcp 16514 - TLS, needed for node migrations (NC)


    ```bash
    cat << EOF | sudo tee /etc/sysconfig/iptables > /dev/null
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

    sudo chkconfig iptables on
    sudo service iptables stop
    ```

19. (ALL): Disable SELinux

    ```bash
    sudo sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    sudo setenforce 0
    ```

20. (ALL): Install and Configure the NTP service

    ```bash
    sudo yum install -y ntp

    sudo chkconfig ntpd on
    sudo service ntpd start

    sudo ntpdate -u  0.centos.pool.ntp.org
    sudo hwclock --systohc
    ```

21. (ALL) Install and Configure Mail Relay

    Normally, a null relay will use DNS to find the MX records associated with the domain of the
    host, but that is not currently set for the PRC environment. So, we are using the same
    sub-domain as is used for other DNS base-domains, where this internal record is configured.

    ```bash
    sudo yum install -y postfix

    pushd /etc/postfix

    sudo cp -a main.cf main.cf.orig

    cat << EOF | sudo tee main.cf > /dev/null
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
    #mydomain = $(hostname -d)
    mydomain = mjc.$(hostname -d)

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

    sudo cp -a master.cf master.cf.orig

    cat << EOF | sudo tee master.cf > /dev/null
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

    cat << EOF | sudo tee sender_canonical > /dev/null
    #
    # Postfix Sender Canonical Map
    #

    root	$(hostname -s)
    EOF

    sudo postmap sender_canonical

    sudo chkconfig postfix on
    sudo service postfix restart

    popd
    ```

22. (ALL) Install Email test client and test email

    Sending to personal email address on Google Apps - Please update to use your own email address!

    Confirm email is sent to relay by tailing /var/log/maillog on this host and on mail relay host.

    ```bash
    sudo yum install -y mutt

    echo "test" | mutt -x -s "Test from $(hostname -s) on $(date)" michael.crawford@mjcconsulting.com
    ````

23. (CC): Configure packet routing

    Note that while this is not required when using EDGE mode, as the CC no longer routes traffic,
    you will get a warning when starting the CC if this routing has not been configured, and the
    package would turn this on at that time. So, this is to prevent that warning.

    ```bash
    sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sudo sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    ```

24. (NC): Configure packet routing

    ```bash
    sudo sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    sudo sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sudo sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    cat /proc/sys/net/bridge/bridge-nf-call-iptables
    ```

### Install Eucalyptus

1. (ALL): Configure yum repositories

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    sudo yum install -y \
             http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
             http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
             http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm
    ```

    Optional: This second set of packages is required to configure access to the Eucalyptus yum
    repositories which contain subscription-only Eucalyptus software, which requires a license.

    ```bash
    sudo yum install -y http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/eucalyptus-enterprise-license-1-1.151702164410-Euca_HP_SalesEng.noarch.rpm
    sudo yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm
    ```

2. (ALL): Override external yum repos to internal servers

    Optional: This step modifies the `mirrorlist=` value in the Eucalyptus yum repo configuration
    files, to instead reference an internal mirrorlist service running on the odc-f-38 host on the
    mirrorlist.mjc.prc.eucalyptus-systems.com domain. 

    This internal service augments the external Eucalyptus mirrors with internal release mirrors
    which are equivalent. The yum `fastest mirror` plugin will then favor the internal mirror
    because it is faster. This can speed up intallations within the PRC by 4 to 6 minutes.

    ```bash
    sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/eucalyptus.repo
    sudo sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/euca2ools.repo
    ```

3. (CLC): Install packages

    ```bash
    sudo yum install -y eucalyptus-cloud eucalyptus-service-image
    ```

4. (UFC+MC): Install packages

    ```bash
    sudo yum install -y eucalyptus-cloud eucaconsole
    ```

5. (OSP): Install packages

    ```bash
    sudo yum install -y eucalyptus-cloud eucalyptus-walrus
    ```

6. (SC+CC): Install packages

    ```bash
    sudo yum install -y eucalyptus-cloud eucalyptus-sc eucalyptus-cc
    ```

7. (NC): Install packages

    ```bash
    sudo yum install -y eucalyptus-nc
    ```

8. (NC): Remove Devfault libvirt network.

    ```bash
    sudo virsh net-destroy default
    sudo virsh net-autostart default --disable
    ```

### Configure Eucalyptus

1. (CLC):  1. Configure Eucalyptus Networking

    ```bash
    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CLC_PRIVATE_INTERFACE}\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CLC_PUBLIC_INTERFACE}\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CLC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

2. (UFS+MC): Configure Eucalyptus Networking

    ```bash
    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_UFS_PRIVATE_INTERFACE}\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_UFS_PUBLIC_INTERFACE}\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_UFS_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

3. (OSP): Configure Eucalyptus Networking

    ```bash
    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_OSP_PRIVATE_INTERFACE}\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_OSP_PUBLIC_INTERFACE}\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_OSP_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

4. (SC+CC): Configure Eucalyptus Networking

    ```bash
    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CCA_PRIVATE_INTERFACE}\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CCA_PUBLIC_INTERFACE}\"/" \
                -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CCA_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

5. (NC): Configure Eucalyptus Networking

    ```bash
    sudo cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sudo sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
                -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
                -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_NC_PUBLIC_INTERFACE}\"/" \
                -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

6. (CLC): Create Eucalyptus EDGE Networking configuration file

    This can not be loaded until the cloud is initialized.

    ```bash
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

7. (NC): Configure Eucalyptus Disk Allocation

    ```bash
    nc_work_size=2400000
    nc_cache_size=300000

    sudo sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
                -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf
    ```

8. (NC): Configure Eucalyptus to use Private IP for Metadata

    ```bash
    cat << EOF | sudo tee -a /etc/eucalyptus/eucalyptus.conf > /dev/null

    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    EOF
    ```

9. (CLC/UFS/OSP/SC): Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value

    ```bash
    heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sudo sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sudo sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

10. (MC): Configure Management Console with Cloud Controller and Walrus addresses

    The clchost parameter within console.ini is misleadingly named, as it should reference the
    public IP of the host running User Facing Services.

    ```bash
    sudo cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.orig

    sudo sed -i -e "/^clchost = localhost$/s/localhost/$EUCA_UFS_PUBLIC_IP/" \
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
    sudo euca_conf --initialize
    ```

2. (CLC/UFS/OSP/SC): Start the Cloud Controller service

    ```bash
    sudo service eucalyptus-cloud start
    ```

3. (CC): Start the Cluster Controller service

    ```bash
    sudo service eucalyptus-cc start
    ```

4. (NC): Start the Node Controller and Eucanetd services

    Expect messages about missing keys. This will be corrected when the nodes are registered.

    ```bash
    sudo service eucalyptus-nc start

    sudo service eucanetd start
    ```

5. (MC): Start the Management Console service

    ```bash
    sudo service eucaconsole start
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
    sudo euca_conf --register-service -T user-api -N ${EUCA_SERVICE_API_NAME} -H ${EUCA_UFS_PRIVATE_IP}
    sleep 60
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
    * sudo needed until credentials have been downloaded and sourced.

    ```bash
    sudo euca-describe-services | cut -f1-5
    ```

2. (CLC): Register Walrus as the Object Storage Provider (OSP)

    ```bash
    sudo euca_conf --register-walrusbackend -P walrus -C walrus -H ${EUCA_OSP_PRIVATE_IP}
    sleep 15
    ```

3. (CLC): Register Storage Controller service

    ```bash
    sudo euca_conf --register-sc -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_SC_NAME} -H ${EUCA_SCA_PRIVATE_IP}
    sleep 15
    ```

4. (CLC): Register Cluster Controller service

    ```bash
    sudo euca_conf --register-cluster -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_CC_NAME} -H ${EUCA_CCA_PRIVATE_IP}
    sleep 15
    ```

5. (CC): Register Node Controller host(s)

    ```bash
    sudo euca_conf --register-nodes="${EUCA_NCA1_PRIVATE_IP} ${EUCA_NCA2_PRIVATE_IP} ${EUCA_NCA3_PRIVATE_IP} ${EUCA_NCA4_PRIVATE_IP}"
    sleep 15
    ```

6. (NC): Restart the Node Controller services

    The failure messages due to missing keys should no longer be there on restart.

    ```bash
    sudo service eucalyptus-nc restart
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

    sudo euca_conf --get-credentials ~/creds/eucalyptus/admin.zip

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

    sudo euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

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

    sudo euca-get-credentials -u admin ~/creds/eucalyptus/admin.zip

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
    sudo service eucaconsole stop
    ```

3. (MC): Install Nginx package

    ```bash
    sudo yum install -y nginx
    ```

4. (MC): Configure Nginx

    ```bash
    sudo \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf

    sudo sed -i -e 's/# \(listen 443 ssl;$\)/\1/' \
                -e 's/# \(ssl_certificate\)/\1/' \
                -e 's/\/path\/to\/ssl\/pem_file/\/etc\/eucaconsole\/console.crt/' \
                -e 's/\/path\/to\/ssl\/certificate_key/\/etc\/eucaconsole\/console.key/' /etc/nginx/nginx.conf
    ```

7. (MC): Start Nginx service

    ```bash
    sudo chkconfig nginx on
    sudo service nginx start
    ```

8. (MC): Configure Eucalyptus Console for SSL

    ```bash
    sudo sed -i -e '/^session.secure =/s/= .*$/= true/' \
                -e '/^session.secure/a\
    sslcert=/etc/eucaconsole/console.crt\
    sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini
    ```

9. (MC): Start Eucalyptus Console service

    ```bash
    sudo service eucaconsole start
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

