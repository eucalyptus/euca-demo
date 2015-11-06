# Install Procedure for region hp-gol01-d8
## 8-Node (2+(1+2)+(1+2)) POC

This document describes the manual procedure to setup region **hp-gol08-d1**,
in a multiple cluster configuration, with 2 cloud level control nodes for CLC+UFS+MC
and Walrus, combined with 1 cluster level control node for CC+SC and 2 NCs per cluster,
with a total of 2 clusters.

This variant is meant to be run as root

This POC will use **hp-gol01-d8** as the AWS_DEFAULT_REGION.

The full parent DNS domain will be **hp-gol01-d8.mjc.prc.eucalyptus-systems.com**.

This is using the following nodes in the PRC:
- odc-d-13.prc.eucalyptus-systems.com: CLC+UFS+MC
  - Public: 10.104.10.83/16 (em1)
  - Private: 10.105.10.83/16 (em2)
- odc-d-14.prc.eucalyptus-systems.com: OSP (Walrus)
  - Public: 10.104.10.84/16 (em1)
  - Private: 10.105.10.84/16 (em2)
- odc-d-15.prc.eucalyptus-systems.com: CCA+SCA
  - Public: 10.104.10.85/16 (em1)
  - Private: 10.105.10.85/16 (em2)
- odc-d-29.prc.eucalyptus-systems.com: CCB+SCB
  - Public: 10.104.1.208/16 (em1)
  - Private: 10.105.1.208/16 (em2)
- odc-d-35.prc.eucalyptus-systems.com: NC1
  - Public: 10.104.1.190/16 (em1)
  - Private: 10.105.1.190/16 (em2)
- odc-d-38.prc.eucalyptus-systems.com: NC2
  - Public: 10.104.1.187/16 (em1)
  - Private: 10.105.1.187/16 (em2)
- odc-f-14.prc.eucalyptus-systems.com: NC3
  - Public: 10.104.10.56/16 (em1)
  - Private: 10.105.10.56/16 (em2)
- odc-f-17.prc.eucalyptus-systems.com: NC4
  - Public: 10.104.10.59/16 (em1)
  - Private: 10.105.10.59/16 (em2)

Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- OSP: Object Storage Provider (Walrus)
- CCA: Cluster Controller Host (Cluster A)
- SCA: Storage Controller Host (Cluster A)
- CCB: Cluster Controller Host (Cluster B)
- SCB: Storage Controller Host (Cluster B)
- NCn: Node Controller(s)

### Hardware Configuration and Operating System Installation

The hardware configuration and operating system installation were done by the PRC Cobbler system,
using the it-centos6-x86_64-bare profile. This system leaves little room for customization.

Each host has 2 1TB disks configured as follows:

- Disk 1, /dev/sda, used for boot (/boot), root (/), and swap, with most space left unreserved.
- Disk 2, /dev/sdb, is not initially configured.

A manual installation of CentOS 6.6 is done, but additional configuration is also included.
Local repos are also installed.

Additional disk space allocation is manually performed, as described below.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. (ALL): Define Environment Variables used in upcoming code blocks

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-d8
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com

    export EUCA_ADMIN_PASSWORD=password

    export EUCA_DNS_PRIVATE_DOMAIN=internal
    export EUCA_DNS_INSTANCE_SUBDOMAIN=vm
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
    export EUCA_DNS_PARENT_HOST=ns1.mjc.prc.eucalyptus-systems.com
    export EUCA_DNS_PARENT_IP=10.104.10.80

    export EUCA_SERVICE_API_NAME=user-api-1

    export EUCA_PUBLIC_IP_RANGE=10.104.40.1-10.104.40.254

    export EUCA_ZONEA=${AWS_DEFAULT_REGION}a
    export EUCA_ZONEA_CC_NAME=${EUCA_ZONEA}-cc
    export EUCA_ZONEA_SC_NAME=${EUCA_ZONEA}-sc

    export EUCA_ZONEA_PRIVATE_IP_RANGE=10.105.40.2-10.105.40.127
    export EUCA_ZONEA_PRIVATE_NAME=10.105.0.0
    export EUCA_ZONEA_PRIVATE_SUBNET=10.105.0.0
    export EUCA_ZONEA_PRIVATE_NETMASK=255.255.0.0
    export EUCA_ZONEA_PRIVATE_GATEWAY=10.105.0.1

    export EUCA_ZONEB=${AWS_DEFAULT_REGION}b
    export EUCA_ZONEB_CC_NAME=${EUCA_ZONEB}-cc
    export EUCA_ZONEB_SC_NAME=${EUCA_ZONEB}-sc

    export EUCA_ZONEB_PRIVATE_IP_RANGE=10.105.40.128-10.105.40.254
    export EUCA_ZONEB_PRIVATE_NAME=10.105.0.0
    export EUCA_ZONEB_PRIVATE_SUBNET=10.105.0.0
    export EUCA_ZONEB_PRIVATE_NETMASK=255.255.0.0
    export EUCA_ZONEB_PRIVATE_GATEWAY=10.105.0.1

    export EUCA_CLC_MANAGEMENT_INTERFACE=em1
    export EUCA_CLC_MANAGEMENT_IP=10.104.10.83
    export EUCA_CLC_PUBLIC_INTERFACE=em1
    export EUCA_CLC_PUBLIC_IP=10.104.10.83
    export EUCA_CLC_PRIVATE_INTERFACE=em2
    export EUCA_CLC_PRIVATE_IP=10.105.10.83
    export EUCA_CLC_SAN_INTERFACE=em2
    export EUCA_CLC_SAN_IP=10.105.10.83

    export EUCA_UFS_PUBLIC_INTERFACE=em1
    export EUCA_UFS_PUBLIC_IP=10.104.10.83
    export EUCA_UFS_PRIVATE_INTERFACE=em2
    export EUCA_UFS_PRIVATE_IP=10.105.10.83

    export EUCA_MC_PUBLIC_INTERFACE=em1
    export EUCA_MC_PUBLIC_IP=10.104.10.83
    export EUCA_MC_PRIVATE_INTERFACE=em2
    export EUCA_MC_PRIVATE_IP=10.105.10.83

    export EUCA_OSP_PUBLIC_INTERFACE=em1
    export EUCA_OSP_PUBLIC_IP=10.104.10.84
    export EUCA_OSP_PRIVATE_INTERFACE=em2
    export EUCA_OSP_PRIVATE_IP=10.105.10.84

    export EUCA_CCA_PUBLIC_INTERFACE=em1
    export EUCA_CCA_PUBLIC_IP=10.104.10.85
    export EUCA_CCA_PRIVATE_INTERFACE=em2
    export EUCA_CCA_PRIVATE_IP=10.105.10.85

    export EUCA_SCA_PUBLIC_INTERFACE=em1
    export EUCA_SCA_PUBLIC_IP=10.104.10.85
    export EUCA_SCA_PRIVATE_INTERFACE=em2
    export EUCA_SCA_PRIVATE_IP=10.105.10.85

    export EUCA_CCB_PUBLIC_INTERFACE=em1
    export EUCA_CCB_PUBLIC_IP=10.104.1.208
    export EUCA_CCB_PRIVATE_INTERFACE=em2
    export EUCA_CCB_PRIVATE_IP=10.105.1.208

    export EUCA_SCB_PUBLIC_INTERFACE=em1
    export EUCA_SCB_PUBLIC_IP=10.104.1.208
    export EUCA_SCB_PRIVATE_INTERFACE=em2
    export EUCA_SCB_PRIVATE_IP=10.105.1.208

    export EUCA_NC_PUBLIC_INTERFACE=em1
    export EUCA_NC_PRIVATE_BRIDGE=br0
    export EUCA_NC_PRIVATE_INTERFACE=em2

    export EUCA_NC1_PUBLIC_IP=10.104.1.190
    export EUCA_NC1_PRIVATE_IP=10.105.1.190

    export EUCA_NC2_PUBLIC_IP=10.104.1.187
    export EUCA_NC2_PRIVATE_IP=10.105.1.187

    export EUCA_NC3_PUBLIC_IP=10.104.10.56
    export EUCA_NC3_PRIVATE_IP=10.105.10.56

    export EUCA_NC4_PUBLIC_IP=10.104.10.59
    export EUCA_NC4_PRIVATE_IP=10.105.10.59
    ```

### Initialize Host Conventions

This section will initialize the host with some conventions normally added during the kickstart
process, not currently available for this host.

1. (All) Install additional packages

    Add packages which are used during host preparation, eucalyptus installation or testing.

    ```bash
    yum install -y man wget zip unzip git qemu-img-rhev nc w3m rsync bind-utils tree screen
    ```

2. (All) Configure Sudo

    Allow members of group `wheel` to sudo with a password.

    ```bash
    sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers
    ```

3. (All) Configure root user

    Configure the root user with some useful conventions, including a consistent directory
    structure, adjusting the default GECOS information so email sent from root on a host
    is identified by the host shortname, pre-populating ssh known hosts, and creating a git
    configuration file.

    ```bash
    mkdir -p ~/{bin,doc,log,src,.ssh}
    chmod og-rwx ~/{bin,log,src,.ssh}

    sed -i -e "1 s/root:x:0:0:root/root:x:0:0:$(hostname -s)/" /etc/passwd

    if ! grep -s -q "^github.com" /root/.ssh/known_hosts; then
        ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts
    fi
    if ! grep -s -q "^bitbucket.org" /root/.ssh/known_hosts; then
        ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts
    fi

    if [ ! -r /root/.gitconfig ]; then
        echo -e "[user]" > /root/.gitconfig
        echo -e "\tname = Administrator" >> /root/.gitconfig
        echo -e "\temail = admin@eucalyptus.com" >> /root/.gitconfig
    fi
    ```

4. (All) Configure profile

    Adjust global profile with some local useful aliases.

    ```bash
    if [ ! -r /etc/profile.d/local.sh ]; then
        echo "alias lsa='ls -lAF'" > /etc/profile.d/local.sh
        echo "alias ip4='ip addr | grep \" inet \"'" >> /etc/profile.d/local.sh
    fi

    source /etc/profile.d/local.sh
    ```

    Adjust user profile to set default Eucalyptus region and profile.

    ```bash
    if ! grep -s -q "^export AWS_DEFAULT_REGION=" ~/.bash_profile; then
        echo >> ~/.bash_profile
        echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> ~/.bash_profile
    fi
    if ! grep -s -q "^export AWS_DEFAULT_PROFILE=" ~/.bash_profile; then
        echo >> ~/.bash_profile
        echo "export AWS_DEFAULT_PROFILE=\$AWS_DEFAULT_REGION-admin" >> ~/.bash_profile
    fi
    ```

5. (All) Clone euca-demo git project

    This is one location where demo scripts live. We will run the demo initialization
    scripts at the completion of the installation.

    ```bash
    if [ ! -r ~/src/eucalyptus/euca-demo/README.md ]; then
        mkdir -p ~/src/eucalyptus
        cd ~/src/eucalyptus

        git clone https://github.com/eucalyptus/euca-demo.git
    fi
    ```

### Initialize External DNS

I will not describe this in detail here, except to note that this must be in place and working
properly before registering services with the method outlined below, as I will be using DNS names
for the services so they look more AWS-like.

Confirm external DNS is configured properly with the statements below, which should match the
results which follow the dig command. This document shows the actual results based on variables
set above at the time this document was written, for ease of confirming results. If the variables
above are changed, expected results below should also be updated to match.

**A Records**

```bash
dig +short ${AWS_DEFAULT_DOMAIN}
10.104.10.80

dig +short ${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.83

dig +short ns1.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.83

dig +short clc.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.83

dig +short ufs.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.83

dig +short console.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
10.104.10.83
```

**NS Records**

```bash
dig +short -t NS ${AWS_DEFAULT_DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.

dig +short -t NS ${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.
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

    **Mounted Filesystems**

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/vg01-lv_root
                           20G  1.1G   18G   6% /
    tmpfs                 3.9G     0  3.9G   0% /dev/shm
    /dev/sda1             240M   33M  195M  15% /boot
    ```

    **Logical Volume Management**

    ```bash
    pvscan
      PV /dev/sda2   VG vg01   lvm2 [931.25 GiB / 903.44 GiB free]
      Total: 1 [931.25 GiB] / in use: 1 [931.25 GiB] / in no VG: 0 [0   ]

    lvscan
      ACTIVE            '/dev/vg01/lv_swap' [7.81 GiB] inherit
      ACTIVE            '/dev/vg01/lv_root' [20.00 GiB] inherit
    ```

    **Disk Partitions**

    ```bash
    fdisk -l

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

    On all hosts, use the remaining space in the vg01 volume group for
    /var/lib/eucalyptus.

    ```bash
    lvcreate -l 100%FREE -n eucalyptus vg01

    pvscan

    lvscan

    mke2fs -t ext4 /dev/vg01/eucalyptus

    e2label /dev/vg01/eucalyptus eucalyptus

    echo >> /etc/fstab
    echo "LABEL=eucalyptus        /var/lib/eucalyptus             ext4    defaults        1 1" >> /etc/fstab

    mkdir -p /var/lib/eucalyptus
   
    mount /var/lib/eucalyptus
    ```
    
2. (CLC+UFS+MC)  Configure additional disk storage for the Cloud Controller

    As we only have 2 physical disks to work with, for the CLC, use of the second disk is best
    suited to keeping the PostgreSQL transaction logs separate from all other disk activity, due to
    the sequential write nature of transaction logs. On many database systems, the speed at which
    transaction logs can be written determines the maximum transactions per second rate.
    This second disk will also be used for a separate logical volume to hold potential PostgreSQL
    archive logs. Normally these would be kept on yet another disk, due to the potential for disk
    contention between transactions and the log archive process, but we only have 2 disks to work
    with, so we will keep them on separate Logical Volumes, the best possible alternative.

    ```bash
    pvcreate -Z y /dev/sdb

    pvscan

    vgcreate eucalyptus /dev/sdb

    lvcreate -l 50%FREE -n xlog eucalyptus
    lvcreate -l 100%FREE -n archive eucalyptus

    mke2fs -t ext4 /dev/eucalyptus/xlog
    mke2fs -t ext4 /dev/eucalyptus/archive

    e2label /dev/eucalyptus/xlog xlog
    e2label /dev/eucalyptus/archive archive

    echo "LABEL=xlog              /var/lib/eucalyptus/tx          ext4    defaults        1 1" >> /etc/fstab
    echo "LABEL=archive           /var/lib/eucalyptus/archive     ext4    defaults        1 1" >> /etc/fstab

    mkdir -p /var/lib/eucalyptus/tx
    mkdir -p /var/lib/eucalyptus/archive
   
    mount /var/lib/eucalyptus/tx
    mount /var/lib/eucalyptus/archive
    ```

3. (OSP)  Configure additional disk storage for the Object Storage Provider

    As we only have 2 physical disks to work with, for the OSP, use of the second disk is best
    suited to keeping the storage buckets separate from other disk activity.

    ```bash
    pvcreate -Z y /dev/sdb

    pvscan

    vgcreate eucalyptus /dev/sdb

    lvcreate -l 100%FREE -n bukkits eucalyptus

    mke2fs -t ext4 /dev/eucalyptus/bukkits
    
    e2label /dev/eucalyptus/bukkits bukkits
    
    echo "LABEL=bukkits           /var/lib/eucalyptus/bukkits     ext4    defaults        1 1" >> /etc/fstab

    mkdir -p /var/lib/eucalyptus/bukkits
   
    mount /var/lib/eucalyptus/bukkits
    ```

4. (SC)  Configure additional disk storage for the Storage Controller

    As we only have 2 physical disks to work with, for the SC, use of the second disk is best
    suited to an additional volume group used for the logical volumes which are used for EBS
    volumes. Note in this case we do not explicitly create the logical volumes or format
    filesystems on top of them, as these tasks are handled by the Eucalyptus Storage Controller.

    ```bash
    pvcreate -Z y /dev/sdb

    pvscan

    vgcreate eucalyptus /dev/sdb
    ```

5. (NC)  Configure additional disk storage for the Node Controller

    As we only have 2 physical disks to work with, for the NC, use of the second disk is best
    suited to where the instance virtual disks are created.

    ```bash
    pvcreate -Z y /dev/sdb

    pvscan

    vgcreate eucalyptus /dev/sdb

    lvcreate -l 100%FREE -n instances eucalyptus

    mke2fs -t ext4 /dev/eucalyptus/instances
    
    e2label /dev/eucalyptus/instances instances
    
    echo "LABEL=instances         /var/lib/eucalyptus/instances   ext4    defaults        1 1" >> /etc/fstab

    mkdir -p /var/lib/eucalyptus/instances
   
    mount /var/lib/eucalyptus/instances
    ```

7. (ALL): Confirm storage

    ```bash
    df -h

    pvscan

    lvscan
    ```

8. (ALL): Disable zero-conf network

    ```bash
    sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    ```

9. (NC): Install bridge utilities package

    ```bash
    yum install -y bridge-utils
    ```

10. (NC): Create Private Bridge

    Move the static IP of the private interface to the private bridge

    ```bash
    private_ip=$(sed -n -e "s/^IPADDR=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
    private_netmask=$(sed -n -e "s/^NETMASK=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
    private_dns1=$(sed -n -e "s/^DNS1=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})
    private_dns2=$(sed -n -e "s/^DNS2=//p" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE})

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_BRIDGE}
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
    sed -i -e "\$aBRIDGE=${EUCA_NC_PRIVATE_BRIDGE}" \
           -e "/^BOOTPROTO=/s/=.*$/=none/" \
           -e "/^IPADDR=/d" \
           -e "/^NETMASK=/d" \
           -e "/^PERSISTENT_DHCLIENT=/d" \
           -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE}
    ```

12. (ALL): Restart networking

    ```bash
    service network restart
    ```

13. (ALL): Confirm networking

    ```bash
    ip addr | grep " inet "
    netstat -nr
    ```

14. (CLC+UFS+MC): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * udp   53 - DNS (CLC)
    * tcp   53 - DNS (CLC)
    * tcp   80 - Console - HTTP (MC)
    * tcp  443 - Console - HTTPS (MC)
    * tcp 5005 - Debug (CLC+UFS)
    * tcp 7500 - Diagnostics (UFS)
    * tcp 8080 - Credentials (CLC)
    * tcp 8772 - Debug (CLC+UFS)
    * tcp 8773 - Web services (CLC+UFS)
    * tcp 8777 - Database (CLC)
    * tcp 8778 - Multicast (CLC)
    * tcp 8779-8849 - jGroups (UFS)
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
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779:8849 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT
    EOF

    chkconfig iptables on
    service iptables stop
    ```

15. (OSP): Configure firewall, but disable during installation

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * tcp 5005 - Debug (OSP)
    * tcp 7500 - Diagnostics (OSP)
    * tcp 8772 - Debug (OSP)
    * tcp 8773 - Web services (OSP)
    * tcp 8778 - Multicast (OSP)
    * tcp 8779-8849 - jGroups (OSP)

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
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779:8849 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT
    EOF

    chkconfig iptables on
    service iptables stop
    ```

16. (CC+SC): Configure firewall, but disable during installation

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
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779:8849 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT
    EOF

    chkconfig iptables on
    service iptables stop
    ```

17. (NC): Configure firewall, but disable during installation

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

18. (ALL): Disable SELinux

    ```bash
    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    setenforce 0
    ```

19. (ALL): Install and Configure the NTP service

    ```bash
    yum install -y ntp

    chkconfig ntpd on
    service ntpd start

    ntpdate -u  0.centos.pool.ntp.org
    hwclock --systohc
    ```

20. (ALL) Install and Configure Mail Relay

    Normally, a null relay will use DNS to find the MX records associated with the domain of the
    host, but that is not currently set for the PRC environment. So, we are using the same
    sub-domain as is used for other DNS base-domains, where this internal record is configured.

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

21. (ALL) Install Email test client and test email

    Sending to personal email address on Google Apps - Please update to use your own email address!

    Confirm email is sent to relay by tailing /var/log/maillog on this host and on mail relay host.

    ```bash
    yum install -y mutt

    echo "test" | mutt -x -s "Test from $(hostname -s) on $(date)" michael.crawford@mjcconsulting.com
    ````

22. (CC): Configure packet routing

    Note that while this is not required when using EDGE mode, as the CC no longer routes traffic,
    you will get a warning when starting the CC if this routing has not been configured, and the
    package would turn this on at that time. So, this is to prevent that warning.

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    ```

23. (NC): Configure packet routing

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    cat /proc/sys/net/bridge/bridge-nf-call-iptables
    ```

24. (ALL): Configure additional network settings

    ```bash
    cat << EOF >> /etc/sysctl.conf

    # Additional Eucalyptus settings
    net.ipv4.neigh.default.gc_interval = 3600
    net.ipv4.neigh.default.gc_stale_time = 3600
    net.ipv4.neigh.default.gc_thresh1 = 1024
    net.ipv4.neigh.default.gc_thresh2 = 2048
    net.ipv4.neigh.default.gc_thresh3 = 4096
    EOF

    sysctl -p

    cat /proc/sys/net/ipv4/neigh/default/gc_interval
    cat /proc/sys/net/ipv4/neigh/default/gc_stale_time
    cat /proc/sys/net/ipv4/neigh/default/gc_thresh1
    cat /proc/sys/net/ipv4/neigh/default/gc_thresh2
    cat /proc/sys/net/ipv4/neigh/default/gc_thresh3
    ```

### Prepare Network

1. (ALL): Configure external switches, routers and firewalls to allow Eucalyptus Traffic

    The purpose of this section is to confirm external network dependencies are configured properly
    for Eucalyptus network traffic.

    TBD: Validate protocol source:port to dest:port traffic
    TBD: It would be ideal if we could create RPMs for a simulator for each node type, which couldi
    send and receive dummy traffic to confirm there are no external firewall or routing issues,
    prior to their removal and replacement with the actual packages

2. (CLC+UFS/OSP/SCA/SCB): Run tomography tool

    This tool should be run simultaneously on all hosts running Java components.

    NOTE: This was moved to after Eucalyptus package installation in 4.2.

    ```bash
    yum install -y --nogpgcheck http://downloads.eucalyptus.com/software/tools/centos/6/x86_64/network-tomography-1.0.0-3.el6.x86_64.rpm

    /usr/bin/network-tomography ${EUCA_CLC_PRIVATE_IP} ${EUCA_OSP_PRIVATE_IP} ${EUCA_SCA_PRIVATE_IP} ${EUCA_SCB_PRIVATE_IP}
    ```

3. (CLC): Scan for unknown SSH host keys

    ```bash
    ssh-keyscan ${EUCA_CLC_PUBLIC_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CLC_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts

    ssh-keyscan ${EUCA_OSP_PUBLIC_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_OSP_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts

    ssh-keyscan ${EUCA_CCA_PUBLIC_IP}  2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CCA_PRIVATE_IP}  2> /dev/null >> /root/.ssh/known_hosts

    ssh-keyscan ${EUCA_CCB_PUBLIC_IP}  2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CCB_PRIVATE_IP}  2> /dev/null >> /root/.ssh/known_hosts

    ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_NC2_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_NC3_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_NC4_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```

4. (CCA): Scan for unknown SSH host keys

    ```bash
    ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_NC2_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```


5. (CCB): Scan for unknown SSH host keys

    ```bash
    ssh-keyscan ${EUCA_NC3_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_NC4_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```

### Install Eucalyptus

1. (ALL): Configure yum repositories

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    yum install -y \
        http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.2/centos/6/x86_64/eucalyptus-release-4.2-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.3/centos/6/x86_64/euca2ools-release-3.3-1.el6.noarch.rpm
    ```

    Optional: This second set of packages is required to configure access to the Eucalyptus yum
    repositories which contain subscription-only Eucalyptus software, which requires a license.

    ```bash
    yum install -y http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/eucalyptus-enterprise-license-1-1.151702164410-Euca_HP_SalesEng.noarch.rpm
    yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.2-1.el6.noarch.rpm
    ```

2. (ALL): Override external yum repos to internal servers

    Optional: This step modifies the `mirrorlist=` value in the Eucalyptus yum repo configuration
    files, to instead reference an internal mirrorlist service running on the odc-f-38 host on the
    mirrorlist.mjc.prc.eucalyptus-systems.com domain. 

    This internal service augments the external Eucalyptus mirrors with internal release mirrors
    which are equivalent. The yum `fastest mirror` plugin will then favor the internal mirror
    because it is faster. This can speed up intallations within the PRC by 4 to 6 minutes.

    ```bash
    sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/eucalyptus.repo
    sed -i -e "s/mirrors\.eucalyptus\.com\/mirrors/mirrorlist.mjc.prc.eucalyptus-systems.com\//" /etc/yum.repos.d/euca2ools.repo
    ```

3. (CLC+UFS+MC): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucaconsole eucalyptus-service-image
    ```

4. (OSP): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucalyptus-walrus
    ```

5. (CC+SC): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucalyptus-cc eucalyptus-sc
    ```

6. (NC): Install packages

    ```bash
    yum install -y eucalyptus-nc
    ```

7. (NC): Remove Devfault libvirt network.

    ```bash
    virsh net-destroy default
    virsh net-autostart default --disable
    ```

### Configure Eucalyptus

1. (CLC+UFS+MC):  1. Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CLC_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CLC_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CLC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

2. (OSP): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_OSP_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_OSP_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_OSP_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

3. (CCA+SCA): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CCA_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CCA_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CCA_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

4. (CCB+SCB): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CCB_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CCB_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CCB_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

5. (NC): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_NC_PUBLIC_INTERFACE}\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

6. (CLC): Create Eucalyptus EDGE Networking configuration file

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
          "Name": "${EUCA_ZONEA}",
          "MacPrefix": "d0:0d",
          "Subnet": {
            "Name": "${EUCA_ZONEA_PRIVATE_NAME}",
            "Subnet": "${EUCA_ZONEA_PRIVATE_SUBNET}",
            "Netmask": "${EUCA_ZONEA_PRIVATE_NETMASK}",
            "Gateway": "${EUCA_ZONEA_PRIVATE_GATEWAY}"
          },
          "PrivateIps": [
            "${EUCA_ZONEA_PRIVATE_IP_RANGE}"
          ]
        },
        {
          "Name": "${EUCA_ZONEB}",
          "MacPrefix": "d0:0d",
          "Subnet": {
            "Name": "${EUCA_ZONEB_PRIVATE_NAME}",
            "Subnet": "${EUCA_ZONEB_PRIVATE_SUBNET}",
            "Netmask": "${EUCA_ZONEB_PRIVATE_NETMASK}",
            "Gateway": "${EUCA_ZONEB_PRIVATE_GATEWAY}"
          },
          "PrivateIps": [
            "${EUCA_ZONEB_PRIVATE_IP_RANGE}"
          ]
        }
      ]
    }
    EOF
    ```

7. (NC): (Skip) Configure Eucalyptus Disk Allocation

    ```bash
    nc_work_size=750000
    nc_cache_size=250000

    sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
           -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf
    ```

8. (NC): Configure Eucalyptus to use Private IP for Metadata

    ```bash
    cat << EOF >> /etc/eucalyptus/eucalyptus.conf

    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    METADATA_IP="$EUCA_CLC_PRIVATE_IP"
    EOF
    ```

9. (CLC+UFS/OSP/SC): (Skip) Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value

    ```bash
    heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

10. (MC): (Skip) Configure Management Console with User Facing Services Address

    On same host currently, may have to set when CLC and UFS are on different hosts.

    ```bash
    cp -a /etc/eucaconsole/console.ini /etc/eucaconsole/console.ini.orig

    sed -i -e "/^ufshost = localhost$/s/localhost/$EUCA_UFS_PUBLIC_IP/" /etc/eucaconsole/console.ini
    ```

### Start Eucalyptus

1. (CLC): Initialize the Cloud Controller service

    ```bash
   clcadmin-initialize-cloud
    ```

2. (CLC+UFS/OSP/SC): Start the Cloud Controller service

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

7. (CLC): Wait for services to respond

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

    TBD: Add steps to verify this using nc

    Verify that everything has started without error. Expected outcomes include:

    * The CLC is listening on ports 8443 and 8773
    * Walrus is listening on port 8773
    * The SC is listening on port 8773
    * The CC is listening on port 8774
    * The NCs are listening on port 8775


### Register Eucalyptus

1. (CLC): Obtain temporary credentials

    ```bash
    eval $(clcadmin-assume-system-credentials)
    ```

2. (CLC): Register User-Facing services

    Copy Encryption Keys. This is not needed in this example as UFS is coresident on the same host with the CLC.

    ```bash
    #clcadmin-copy-keys ${EUCA_UFS_PRIVATE_IP}
    ```

    Register User-Facing Services.

    ```bash
    euserv-register-service -t user-api -h ${EUCA_UFS_PRIVATE_IP} ${EUCA_SERVICE_API_NAME}
    ```

    Wait for User-Facing Services to respond.

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

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend
      and objectstorage.
    * The cluster, storage and walrusbackend services should not yet be listed.

    ```bash
    euserv-describe-services
    ```

2. (CLC): Register Walrus as the Object Storage Provider (OSP)

    Copy Encryption Keys.

    ```bash
    clcadmin-copy-keys ${EUCA_OSP_PRIVATE_IP}
    ```

    Register the Walrus Backend Service.

    ```bash
    euserv-register-service -t walrusbackend -h ${EUCA_OSP_PRIVATE_IP} walrus
    ```

    Wait for walrusbackend service to become **enabled**.

    ```bash
    sleep 30
    ```

    Optional: Confirm service status.

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend
      and objectstorage.
    * The walrusbackend service should now be listed.
    * The cluster and storage services should not yet be listed.

    ```bash
    euserv-describe-services
    ```

3. (CLC): Register Cluster Controller services

    Register the Cluster Controller services.

    ```bash
    euserv-register-service -t cluster -h ${EUCA_CCA_PRIVATE_IP} -z ${EUCA_ZONEA} ${EUCA_ZONEA_CC_NAME}
    euserv-register-service -t cluster -h ${EUCA_CCB_PRIVATE_IP} -z ${EUCA_ZONEB} ${EUCA_ZONEB_CC_NAME}
    ```

    Copy Encryption Keys.

    ```bash
    clcadmin-copy-keys -z ${EUCA_ZONEA} ${EUCA_CCA_PRIVATE_IP}
    clcadmin-copy-keys -z ${EUCA_ZONEB} ${EUCA_CCB_PRIVATE_IP}
    ```

    Wait for services to become **enabled**.

    ```bash
    sleep 30
    ```

    Optional: Confirm service status.

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend
      and objectstorage.
    * The cluster service should now be listed.
    * The storage services should not yet be listed.

    ```bash
    euserv-describe-services
    ```

4. (CLC): Register Storage Controller services

    Copy Encryption Keys. This is not needed in this example as each SC is coresident on the same host as the CC.

    ```bash
    #clcadmin-copy-keys -z ${EUCA_ZONEA} ${EUCA_SCA_PRIVATE_IP}
    #clcadmin-copy-keys -z ${EUCA_ZONEB} ${EUCA_SCB_PRIVATE_IP}
    ```

    Register the Storage Controller services.

    ```bash
    euserv-register-service -t storage -h ${EUCA_SCA_PRIVATE_IP} -z ${EUCA_ZONEA} ${EUCA_ZONEA_SC_NAME}
    euserv-register-service -t storage -h ${EUCA_SCB_PRIVATE_IP} -z ${EUCA_ZONEB} ${EUCA_ZONEB_SC_NAME}
    ```

    Wait for storage services to become **broken**.

    ```bash
    sleep 30
    ```

    Optional: Confirm service status.

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend,
      objectstorage and storage.
    * The storage services should now be listed.

    ```bash
    euserv-describe-services
    ```

5. (CCA): Register Node Controller host(s) associated with Cluster 1

    Register the Node Controller services.

    ```bash
    clusteradmin-register-nodes ${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP}
    ```

    Copy Encryption Keys.

    ```bash
    clusteradmin-copy-keys ${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP}
    ```

6. (CCB): Register Node Controller host(s) associated with Cluster 2

    Register the Node Controller services.

    ```bash
    clusteradmin-register-nodes ${EUCA_NC3_PRIVATE_IP} ${EUCA_NC4_PRIVATE_IP}
    ```

    Copy Encryption Keys. 

    ```bash
    clusteradmin-copy-keys ${EUCA_NC3_PRIVATE_IP} ${EUCA_NC4_PRIVATE_IP}
    ```

7. (NC): Restart the Node Controller services

    The failure messages due to missing keys should no longer be there on restart.

    ```bash
    service eucalyptus-nc restart
    ```

### Runtime Configuration

1. (CLC): Initialize Euca2ools Region

    Convert the localhost Euca2ools Region configuration file into a specific Euca2ools Region
    configuration file, not yet using DNS or SSL.

    We will replace this file once DNS is configured, then again once PKI and SSL certificates
    are configured.

    ```bash
    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem

    cat << EOF > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini
    ; Eucalyptus Region $AWS_DEFAULT_REGION

    [region $AWS_DEFAULT_REGION]
    autoscaling-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/AutoScaling/
    cloudformation-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudFormation/
    ec2-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/compute/
    elasticloadbalancing-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/LoadBalancing/
    iam-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Euare/
    monitoring-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/CloudWatch/
    s3-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage/
    sts-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Tokens/
    swf-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/SimpleWorkflow/

    bootstrap-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Empyrean/
    properties-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Properties/
    reporting-url = http://$EUCA_UFS_PUBLIC_IP:8773/services/Reporting/

    certificate = /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    verify-ssl = false
    user = $AWS_DEFAULT_REGION-admin
    EOF
    ```

2. (CLC): Configure Eucalyptus Region

    ```bash
    euctl region.region_name=$AWS_DEFAULT_REGION

    euca-describe-regions

    euca-describe-availability-zones verbose
    ```

3. (CLC): Configure Eucalyptus Administrator Password

    ```bash
    euare-usermodloginprofile --password $EUCA_ADMIN_PASSWORD admin
    ```

4. (CLC): Create Eucalyptus Administrator Certificates

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    euare-usercreatecert --out ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-cert.pem \
                         --keyout ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-pk.pem
    ```

5. (CLC): Generate Eucalyptus Administrator Credentials File

    This is only needed for reference by the AWS_CREDENTIALS_FILE environment variable, which
    itself is only needed when you want to use both Euca2ools and AWSCLI in parallel.

    There is currently a conflict between a Euca2ools extension to the semantics of the
    AWS_DEFAULT_REGION environment variable, where Euca2ools requires the "USER@" prefix to the
    REGION value to pass such USER information via the environment, but when this prefix is
    present it breaks AWSCLI, which uses AWS_DEFAULT_REGION and does not expect this prefix.

    As a workaround, we can restrict the AWS_DEFAULT_REGION environment variable to the original
    AWS semantics where only the REGION is present, and pass the USER into Euca2ools via the
    AWS_DEFAULT_CREDENTIALS environment variable, which Euca2ools still recognizes but which
    is no longer recognized by AWS CLI. 

    ```bash
    access_key=$AWS_ACCESS_KEY_ID
    secret_key=$AWS_SECRET_ACCESS_KEY

    cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

6. (CLC): Initialize Eucalyptus Administrator Euca2ools Profile

    Obtain the values we need from the Region's Eucalyptus Administrator eucarc file.

    ```bash
    account_id=$(euare-userlistbypath | grep "user/admin" | cut -d ":" -f5)
    access_key=$AWS_ACCESS_KEY_ID
    secret_key=$AWS_SECRET_ACCESS_KEY
    private_key=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-pk.pem
    certificate=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-cert.pem

    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/$AWS_DEFAULT_REGION.ini
    ; Eucalyptus Region $AWS_DEFAULT_REGION

    [user $AWS_DEFAULT_REGION-admin]
    account-id = $account_id
    key-id = $access_key
    secret-key = $secret_key
    private-key = $private_key
    certificate = $certificate

    EOF

    euca-describe-regions --region $AWS_DEFAULT_REGION-admin@$AWS_DEFAULT_REGION

    euca-describe-availability-zones verbose --region $AWS_DEFAULT_REGION-admin@$AWS_DEFAULT_REGION
    ```

7. (CLC): Import Support Keypair

    ```bash
    cat << EOF > ~/.ssh/support_id_rsa
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: AES-128-CBC,A7E90718BF61C84826297430F36A3092

    ZaLkWHam/D0edJYg+q/cmu7norygv6uhiTMCyYYWQbqAazdcBT6zvpcxmmCbdoeX
    0FQ0AhM3rD+1/d1e+2nOU0F2SJ9bjfU3FU/MY+OJ5qH5fO6ChMO6H3+x4bQ2knwB
    oYItOvy9PnFCG58XycCam+q8wV49BXsGaHZtoykzTa7v77cvCKwl29QQRUCgym8G
    bXrb90n7V3jEWgHEi3rQZ0/8qGvPU8UDNV+8Jiu16j9GNVShP/30W8uqgT0kj1oS
    TpIFAYQFLW0HlhAmKnqNqqzd2Jet/ebvD3+Om6yIjg6+tncgRjV2kBiIU2WwjJMC
    rTHG0KpQzbEMTfFA8OGEKK3yVjwE92Ypu2SiitFnVVZMYMm0aHR2/Tx5chjed7rV
    gVmPApCjNPOhyQFc+f+KpFsIIOjF7LVRRLRVhnYLujyA+an+BWJjHMhMlQ18Ek9u
    l6b77LoImQIGXq626YSAe9w3rCkOb6CWqMGDKaagvl92N8Topn9W0NXawfbV7ZTM
    Unvi2sLTgsurQ/JpuS7BKmq8gmmmzm8IqhzGBEE9a5G4zJ3vTjRo2lZ6hRN6ri50
    pSHDt6m9b0OU6ZV3FerpjIZWigCkI0VWZPQgPJTF0VKdusU7atG7N1fSCc+GBW39
    opB/mpWghZvI4MLC/5GKG753A2nDYp1K8rBGwXyb27UmZ/6B920cV6L2fqGvyoRO
    q8sP7zsqtU6U+nmZOeRGOQW/XLKRYDnqe5NCC/8tkpMXNk9PAQP9We1X7kxfAl6B
    8WAw+IfSVtBRT76TqwMSqmS3BqAehbeGRZQ+JF33cCxd/8DJcLh8ZHKnlO66m6B9
    K/e2lN+Y6mJCU7g2VSpK6/QzPwYPA63N/CqRoACZw/nQ3T2CBOLK5i7vU57iLHqq
    dUHSdwKrylyb3QPSkttnD9MIuByPN2ZXZCNOp5gXWC/s1hbdGeX/voHtJl8a7g1Z
    1keeDuqW95LMJKhKl0CXFznUHF9wQa3vx8nJVl2K/rXUi5tEw7I/0QD+fER3DTmM
    SYRwinfayzHEUqUCNVEMg/wPfTPPvem07SHPOV8mlVPwusl2RVbHfVg9tTjiB59c
    sc5oEDv2DkWkV6DLXmGR8RVdzYVE845tiJdsEuH5rL5wZyhcCeTccG2PV7+EXjsf
    hxaUqOyZ41izsB0CDg+XwTVKfEg/HO9aqldzn1pSLB2ljVLXdA4PzDpFza2Ey7yy
    d6zyYqGavQ7RXEicv/drdumJI80OwK+BfGw/ex1yjcAQk3jC69Mh3P4ZwVhYBoz1
    TuwTh9yAwTe0cgoaBtesY/KjZaOdYEAZ5HwzT+ofN/HO6UgutZfPH08foNo1+6Hj
    uaSvKENpes/4CviPxX6NuUMyy7VAz6vf+naFzvRB0enB9XmmBnjnT1JTXWPHTIdq
    1rMI8KCvQ0U27KI5bhjYWQOmON0Ai4qfrbtuhQx2sZuU7fM+bqErERVW9gekloX3
    eWHtsITbrRT16luUcCgnubIXMcRCO2rAgbwF4z5YpshexZFFnbqgxOAJC58gtPAi
    dKu/FFZMVwFukKFeyf7WvNleTMu9ziOIs71USXBZpHEiWjsJlcpdkE9KYDX9mLu6
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 0600 ~/.ssh/support_id_rsa

    cat << EOF > ~/.ssh/support_id_rsa.pub
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTXOsL3dwPJxQ9GCpS4izXtxwq\
    tzGw5PCTTVqjy54ZkbmgtqJJTEbT9W4vY6QwuNvsoY7clij7u6Gskfcv93YxMW8c\
    tXIi89lnMAA3VzehAulYOF21+W3sRLe9nPf52js8Mekhl364udTbHMtnpueHyZvG\
    pTJmc3CxO2xYdCa0f8wKxOEXOzGY2EcwWurQPu+jLHU6C5LPulcYfLsYHz1fFuDp\
    8tpVXpHONJwpXLKDoe4iAtkxpKtIZEZEeJNIpuIqiVT8L0uRvYH9Za7yj3Tcxh5r\
    8uE5v925bxkgHk+Hk95YdnfMqJfG8qGtC3tfE6bTOkweLjmiadY+Qz4QBv67\
     support@hpcloud.com
    EOF

    euca-import-keypair -f ~/.ssh/support_id_rsa.pub support
    ```

8. (CLC): Confirm initial service status

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend, 
      objectstorage and storage.
    * All nodes should be in the **enabled** state.

    ````bash
    euserv-describe-services

    euserv-describe-node-controllers
    ```

9. (CLC): Load Edge Network JSON configuration

    ```bash
    euctl cloud.network.network_configuration=@/etc/eucalyptus/edge-$(date +%Y-%m-%d).json
    ```

10. (CLC): Configure Object Storage to use Walrus Backend

    ```bash
    euctl objectstorage.providerclient=walrus
    ```

    Wait for objectstorage service to become **enabled**.

    ```bash
    sleep 20
    ```

    Optional: Confirm service status.

    * The objectstorage service should now be in the **enabled** state.
    * All services should be in the **enabled** state, except for imagingbackend,
      loadbalancingbackend and storage.

    ```bash
    euserv-describe-services
    ```

11. (CLC): Configure EBS Storage for DAS storage mode

    This step assumes additional storage configuration as described above was done,
    and there is an empty volume group named `eucalyptus` on the Storage Controller
    intended for DAS storage mode Logical Volumes.

    ```bash
    euctl ${EUCA_ZONEA}.storage.blockstoragemanager=das
    euctl ${EUCA_ZONEB}.storage.blockstoragemanager=das

    sleep 10

    euctl ${EUCA_ZONEA}.storage.dasdevice=eucalyptus
    euctl ${EUCA_ZONEB}.storage.dasdevice=eucalyptus
    ```

    Wait for storage services to become **enabled**.

    ```bash
    sleep 20
    ```

    Optional: Confirm service status.

    * The storage services should now be in the **enabled** state.
    * All services should be in the **enabled** state except for imagingbackend and
      loadbalancingbackend.

    ```bash
    euserv-describe-services
    ```

12. (CLC): Install and Initialize the Eucalyptus Service Image

    Install the Eucalyptus Service Image. This Image is used for the Imaging Worker and Load Balancing Worker.

    ```bash
    export S3_URL=http://$EUCA_UFS_PUBLIC_IP:8773/services/objectstorage
    esi-install-image --install-default
    ```

    (Skip - seems keypair must be in "(eucalyptus)imaging" Account. Set the Worker KeyPair, allowing use of the support KeyPair for Intance debugging.

    ```bash
    euctl services.imaging.worker.keyname=support
    euctl services.loadbalancing.worker.keyname=support
    euctl services.database.worker.keyname=support
    ```

    (Optional) Adjust Worker Instance Types.

    ```bash
    euctl services.imaging.worker.instance_type=m1.xlarge
    euctl services.loadbalancing.worker.instance_type=m1.small
    euctl services.database.worker.instance_type=m1.small
    ```

    Start the Imaging Worker Instance.

    ```bash
    esi-manage-stack -a create imaging
    ```

    Wait for imaging and loadbalancing services to become **enabled**. The imagingbackend service may at
    first appear enabled, then switch to **notready** until the imaging worker created by the last statement
    is stable. Continue to wait until all services are enabled.

    ```bash
    sleep 20
    ```

    Optional: Confirm service status.

    * The imaging, imagingbackend, loadbalanging and loadbalancingbackend services should now be in the
      **enabled** state.
    * All services should now be listed and in the **enabled** state.

    ```bash
    euserv-describe-services
    ```

13. (CLC): Configure DNS

    (Skip) Configure Eucalyptus DNS Server

    Not sure if this does anything more than provide documentation.

    ```bash
    euctl dns.dns_listener_address_match=${EUCA_CLC_PUBLIC_IP}

    euctl system.dns.nameserver=${EUCA_DNS_PARENT_HOST}

    euctl system.dns.nameserveraddress=${EUCA_DNS_PARENT_IP}
    ```

    (Optional) Configure DNS Timeout and TTL

    ```bash
    euctl dns.tcp.timeout_seconds=30

    euctl services.loadbalancing.dns_ttl=15
    ```

    Configure DNS Domain

    ```bash
    euctl system.dns.dnsdomain=${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
    ```

    Configure DNS Sub-Domains

    ```bash
    euctl cloud.vmstate.instance_subdomain=.${EUCA_DNS_INSTANCE_SUBDOMAIN}

    euctl services.loadbalancing.dns_subdomain=${EUCA_DNS_LOADBALANCER_SUBDOMAIN}
    ```

    Enable DNS

    ```bash
    euctl bootstrap.webservices.use_instance_dns=true

    euctl bootstrap.webservices.use_dns_delegation=true
    ```

    Display Parent DNS Server Configuration

    ```bash
    cat /var/named/private/masters/hp-gol01-d8.mjc.prc.eucalyptus-systems.com.zone
    $TTL 1M
    $ORIGIN hp-gol01-d8.mjc.prc.eucalyptus-systems.com.
    ;Name           TTL     Type    Value
    @                       SOA     ns1.mjc.prc.eucalyptus-systems.com. root.mjc.prc.eucalyptus-systems.com. (
                                    2015102901      ; serial
                                    1H              ; refresh
                                    10M             ; retry
                                    1D              ; expiry
                                    1H )            ; minimum
    
                            NS      ns1.mjc.prc.eucalyptus-systems.com.
    
                            A       10.104.10.83
    
    ns1                     A       10.104.10.83
    
    clc                     A       10.104.10.83
    ufs                     A       10.104.10.83
    mc                      A       10.104.10.83
    osp                     A       10.104.10.84
    walrus                  A       10.104.10.84
    cca                     A       10.104.10.85
    sca                     A       10.104.10.85
    ccb                     A       10.104.1.208
    scb                     A       10.104.1.208
    nc1                     A       10.104.1.190
    nc2                     A       10.104.1.187
    nc3                     A       10.104.10.56
    nc4                     A       10.104.10.59

    console                 A       10.104.10.83
    autoscaling             A       10.104.10.83
    cloudformation          A       10.104.10.83
    cloudwatch              A       10.104.10.83
    compute                 A       10.104.10.83
    euare                   A       10.104.10.83
    loadbalancing           A       10.104.10.83
    objectstorage           A       10.104.10.83
    tokens                  A       10.104.10.83
    simpleworkflow          A       10.104.10.83
    bootstrap               A       10.104.10.83
    properties              A       10.104.10.83
    reporting               A       10.104.10.83

    vm                      NS      ns1
    lb                      NS      ns1
    ```

    Confirm DNS resolution for Services

    ```bash
    dig +short console.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short autoscaling.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short cloudformation.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short cloudwatch.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short compute.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short euare.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short loadbalancing.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short objectstorage.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short tokens.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short simpleworkflow.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short bootstrap.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short properties.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short reporting.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
    ```

14. (CLC): Confirm service status

    All services should now be listed and in the **enabled** state.

    ```bash
    euserv-describe-services
    ```

15. (CLC): Confirm apis

    ```bash
    euca-describe-regions

    euca-describe-availability-zones verbose

    euserv-describe-node-controllers

    euca-describe-instance-types --show-capacity
    ```

### Configure SSL Certificates

We have an internal certificate authority used to sign development wildcard certificates.
This reduces the number of SSL certificates we need to manage, while still protecting SSL
websites in a manner similar to how things work in production.

All keys and certificates are included in-line below. If these are reissued, this document
must be updated with the new text. Since this repository is public, these should be 
considered insecure, and not used to protect hosts or sites accessible from the Internet.

1. (ALL) Configure SSL to trust local Certificate Authority

    You should save this certificate and import into the trusted certificate store of all
    workstations where you may access the management console, so that you do not get the
    unknown certificate authority warning.

    ```bash
    cat << EOF > /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt
    -----BEGIN CERTIFICATE-----
    MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y
    NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk
    BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI
    ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g
    QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV
    BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku
    Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh
    lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd
    Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL
    GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT
    47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn
    23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc
    HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9
    WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb
    qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1
    ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU
    NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT
    E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB
    BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
    OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa
    jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub
    sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d
    vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI
    kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap
    oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX
    wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD
    zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8
    qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M
    Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I
    Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI=
    -----END CERTIFICATE-----
    EOF

    update-ca-trust enable

    update-ca-trust extract
    ```

2. (ALL) Install Wildcard Host SSL Key

    ```bash
    cat << EOF > /etc/pki/tls/private/star.${AWS_DEFAULT_DOMAIN#*.}.key
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEApyjRCMhXk96DWLBbjsDiXSmHuCTVNIHMowQqXv1Mvi9W98xF
    VtJYDJz0yhgshbO3DGuYqTr2R451CELmYbBYlhQQMi0tWO4IxwseBJRoxJcAAxx1
    8dSp2anxvcyPk8xomMC3c1t3AyEF+Y1YQKpMPcCqOZhdbQgRUKCrY6kcLrgCcCZf
    8GFPNEPBS3iwYz9V8QD9QSLks5MJblTPwRxDHoMMfMxB8SPeCqEmlTUUz+IJ7wev
    z/3HXgNQZ7a9P8vgGMyKj7+BudgwidR8ENYv0/zM1QzDoCtRHNxID51j/Y70Dobc
    jmvzX9Mlgke0gc1wraI8P1w+CTNCKewNs9Ng9wIDAQABAoIBACQVYII31QfbeZj0
    gN8g7fxUUbLDaK6r8kOiS48zuJQ5Xdmh47npMA6Q9xqE+19lOvdYZpzpWG575vGA
    l4Cw8356GEDslaRjxctJsBInAzKkseD6DM/GK2AMGl3xQXETJ+UJfNBPBzLKtyJ2
    i31yBYEzDMvgAxLdMfeopzadM7M1tiFd2+DEbT66PSsTih9xnDtY2mHicZXFEd1w
    M/3b+S0jfKcytG2nUwc1wI5QVlaks6DU1bkrIkW6ZfTsnTOlKmWc6CJg5Tj1/1SP
    OKcgRmug8JF+KU8CUhTZV8qLF/x/UXgFuKmojLRSTiJ1GDEo6gFliKrYFRAXeW+a
    xDVwCVECgYEA1IQt2wR7A4QSscpVnmF1gqlnajoQzx0C6WBUEORxWO+Nxiq6pxCe
    Qy2wNb6xsAVyzJhRYyxW/WE0EyrjEFnxKwh7SxUMnn6WbeUYsGj6DqW/GGdVP26E
    RiSFRs+SyziBeVKtTA0RJgRL5Cduyo7Ej6YENXS389aI5QlzHifmbMkCgYEAyVzM
    N2yggBKRus+Rr5EOk6fr/LF2hm3amH2Ub1kqsBy959Sa0Dwb112NJa0cuZZtPoFa
    9dWGn/1pozN6qQnuNrSVsMV4PyRl5GZm55t3MzAGp3I1oQRwI4p9wRpZoRVD8rhj
    4CyABLuUh3+F7uvLYwYRw/mx9Crybe+zaAYs/78CgYBGuR5RjvIpP2DBTiakKKbk
    rt+9mElTw8HeTLJtVLjr8fzqf/nR81PX43KK0EVt4MJNmDstl+nzNNARuOoL3QLH
    YXE2kXC7pkEFnYJT4vukuEAaLPlPvMXEWg8Ie7fMbaeY6ozFjGuyjSd8bCsQueZs
    L8Gi0I8PVMwF/NkUpg6nEQKBgDuOrvhVsMMwutm+OyDqjp0ttabv9lacd2NTAWxN
    u0qLtb+0KnYc0T9J9E2Ifk6GJ5mtOPItTbxUf8I9n7IPtd2IXB4EyiQi5+A+SYGH
    giIpuk4cgbA2V9SrSbarzIbQe2B3GVNc1iCQOsY4+axJIccQLIECgZfue/X4R+Ak
    s3qRAoGBAJ2ifqj9iTHKPwb4HfFWW18qfffS4Hoes0OTR9AlpMlPDGqHkyRAjCqc
    w6cfovJya2WnJ/6/ukF1arPFGycXnjM94l20S61dmjwfq/VOA98kuiol97hnUl3u
    Q0FKCwro7Wt37jb9eEwYEg9w3qtq7xzD6YbsRosR02okSymHRgqO
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 400 /etc/pki/tls/private/star.${AWS_DEFAULT_DOMAIN#*.}.key
    ```

3. (ALL) Install Wildcard Host SSL Certificate

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.${AWS_DEFAULT_DOMAIN#*.}.crt
    -----BEGIN CERTIFICATE-----
    MIIFiDCCA3CgAwIBAgIBDjANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjEwNTI4NTJaFw0x
    ODA0MjAwNTI4NTJaMIGLMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEYMBYGA1UECgwPSGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVj
    YWx5cHR1cyBEZXZlbG9wbWVudDElMCMGA1UEAwwcKi5wcmMuZXVjYWx5cHR1cy1z
    eXN0ZW1zLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKco0QjI
    V5Peg1iwW47A4l0ph7gk1TSBzKMEKl79TL4vVvfMRVbSWAyc9MoYLIWztwxrmKk6
    9keOdQhC5mGwWJYUEDItLVjuCMcLHgSUaMSXAAMcdfHUqdmp8b3Mj5PMaJjAt3Nb
    dwMhBfmNWECqTD3AqjmYXW0IEVCgq2OpHC64AnAmX/BhTzRDwUt4sGM/VfEA/UEi
    5LOTCW5Uz8EcQx6DDHzMQfEj3gqhJpU1FM/iCe8Hr8/9x14DUGe2vT/L4BjMio+/
    gbnYMInUfBDWL9P8zNUMw6ArURzcSA+dY/2O9A6G3I5r81/TJYJHtIHNcK2iPD9c
    PgkzQinsDbPTYPcCAwEAAaOBxTCBwjAMBgNVHRMBAf8EAjAAMB0GA1UdJQQWMBQG
    CCsGAQUFBwMBBggrBgEFBQcDAjAOBgNVHQ8BAf8EBAMCBaAwHwYDVR0jBBgwFoAU
    NkKFNpC6OqbkLgVZoFATE+TS21gwQwYDVR0RBDwwOoIcKi5wcmMuZXVjYWx5cHR1
    cy1zeXN0ZW1zLmNvbYIacHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wHQYDVR0O
    BBYEFFUkmTKb9nyPcXGltziX45SRHIx3MA0GCSqGSIb3DQEBCwUAA4ICAQC71q6x
    Hyc/wft+ohM+xo6dotoCZVJJF7hzz+9Qm//yHqB0KR55mLljD9Wq+8C/RYDJ+6dn
    Q79uC/Toa51W1QrZssk3qQAcXZNgtC92+8boXRwqJ9GwrZ8bMAk3IthqQxQp++RF
    IVk4QjPJOQXCuT57orIa39bB78aAXBrmjLRfK0+UPS495DCxeEdfZ2gNBGTogDjs
    rmh/w/umcXN/vGaQUxslcSmXHvIivSASsUAdDltVQbDuRrx6k3zJDRcL7aEtckwV
    OdjbBr6NTb1vNw7MHKIC+hCc7Rg/UP2bFCchLQ3Hjy5xzkP74l9AjXpJHKwOxCJ2
    jL96j5rNGpCNZfYYrRbNiflMLvm8FKibFyVwNagWMc8rYHpPwQIVa2FoPYSHdfLw
    42NlawlalIZemzpHOUuk5cthBt1jqACnI5Gn2G2sn+QP8rMT4iLKyIBxQt3dkxnO
    fjRK/MrEiQUJpWtwZi+TSFPklTjW9gJS1xBLkcaB5qDrALNBWM5XNXGE76JiNuWO
    UK7ghFq6IMyabMUB1fLYExXwI4CwHLJZypPjjW4Vv3pi4OUBfTMXAZhMyLVQ5TZV
    5P+BwsXvGEN+BnGtmsOOnq+x5sNv/ok+iXQClYC4VxzqfEXCotNfE0UwEZaH1Bh2
    j+SI2pU9Ic50YPF3Q2fLT8WmNLp9OBmmt7RfeA==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.${AWS_DEFAULT_DOMAIN#*.}.crt
    ```

4. (CLC+UFS+MC) Install Wildcard Site SSL Key

    ```bash
    cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEAxYGf/J0nk3BsIaQIQjoZZv9AVGm4A5T38E5GDsIrhQtbWL3c
    zo36ZZssrFoF+73kn7D7fePqt1pYvfOfyUTiQLwcE05BcOmde4xdA85tDctISK0g
    HTT2dIX0dPGlOZbLqZUL8OhIARBQCWacLwdhyP6d/nCKkXVVl5yfsBDIf95TQBf4
    SCwEx7v5LVAEdqQNdKX69Ig506/6fYzXzWZ6WKz5Gp/U9Zz1jDxzqIuXlqaU1mX/
    Da8dFfBybKIWo51RrxtJCDtHqM6FX2w8OdocazYnPfSY4ok1+pjlJ85kbVB1KH3I
    fBCpkg5wauJA16+i+z7ws3Sjq7dLKIZ9ulWlfwIDAQABAoIBAGYqiITXEnrNQ9If
    FPqVLUC/NxqzWTHZJGxVQR4vSO3YkxcTl53tiaJ3o6NAKiov74y/s0hK1saj4JXZ
    6UTm8hbEd81wxJ9Q6VrYn+DxLi5dgnW9wIf7NqXOCUdZHLvuikmdxQCIV37dXlmO
    j6owKmAbfcT5mGRoCq+ToHMmK2Egyk2UNhGAHnAPkExSt2A+OMqVy94BJ3/A4Sfb
    4m0llYzp64OBuzHkqf0eGV2ndMs04hLWHpLreEZYwYE5kpeBRWVSlQ6rWAvcQ8K9
    HwhlOXPpdtYYi93bT9Sc+YLQ0aUX5KENU2pRJWnL4Y2Aea67hqRTlhN/4FDrjY8o
    yAdLz5ECgYEA8HKks2fLjmwE/v646gBEm1Kb/X7fSu5eMFM9basDhUIOO2aF+pkO
    hj0jvum7bnW4uYJLQ2dR9QmabYDJ5Mak+kngh9KJeW7Qt6oD6ei+RFY0sVl+Ge1T
    sIBT7y0Cp+uH1LwCjcWr90+R201CMA760WTqCTj3WwvoO4kmwICMbzkCgYEA0kfz
    5vocTcpw3/q/8ZB3SQwZB2+/Oonx16GjGsbD7VwJWyOxl9JKlC0ylq10LHYakvNT
    AMCeqdIELaN4p+YEh7RtwvWzckWHEXWyfj1KvUnldjpfTF4zz0Fe/VYY6m19MLVx
    fffKsfNWlMnCWuZA3TeuQcMqF2Ak2z2cacorgncCgYEA5yAMGTeofxpuIv6OmL/x
    MqxRrXYLBWfjuegJoCVGmQ1JyOdf2ebOA1M5zQW3WRJnokoQNpZWPYghnSiy6OnZ
    I41n+qbx5nwSvLj8Uhea7O1AcUlo4VszmvF/vOQzLV5FjsO6YLSl/G/L8FVvTerY
    RfcO0BamDip/7NqFGX13gGECgYEAzbCISgWZLha59r2mh7qSlCd7TCTo33AT2qNH
    kmefO0zt8fKmQyX2wZ68f1tH6j3UnK3bIT9JdD/0yle/LCz5fWzmePAyCbMs/c0t
    PgLiWuovxEgw89ipwS/mpNRVJurWrJCvZVK/OPYYWQ5KSPQ1uq4+jCFFyPvI0ZQg
    rfKOQN0CgYEA25koGTBdCEQwKJhqvdss5euOxh/Vt6mUt5zMQCqvgbeXhcuuWSOI
    xF9Kvkf4Bg9zqXltXlXZGro9RpbFgXaRO+P4oh9z46gXJfZq3nkCUEL+dMkncWdQ
    HtBoIpvjGrg3v9ZbQN21kUb4b5bGiVQYzjwIMrygLw+TGAke8PgiM7U=
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    ```

5. (CLC+UFS+MC) Install Wildcard Site SSL Certificate

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    -----BEGIN CERTIFICATE-----
    MIIFuDCCA6CgAwIBAgIBCTANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjEwNTA2MjVaFw0x
    ODA0MjAwNTA2MjVaMIGbMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEYMBYGA1UECgwPSGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVj
    YWx5cHR1cyBEZXZlbG9wbWVudDE1MDMGA1UEAwwsKi5ocC1nb2wwMS1kOC5tamMu
    cHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQDFgZ/8nSeTcGwhpAhCOhlm/0BUabgDlPfwTkYOwiuFC1tYvdzO
    jfplmyysWgX7veSfsPt94+q3Wli985/JROJAvBwTTkFw6Z17jF0Dzm0Ny0hIrSAd
    NPZ0hfR08aU5lsuplQvw6EgBEFAJZpwvB2HI/p3+cIqRdVWXnJ+wEMh/3lNAF/hI
    LATHu/ktUAR2pA10pfr0iDnTr/p9jNfNZnpYrPkan9T1nPWMPHOoi5eWppTWZf8N
    rx0V8HJsohajnVGvG0kIO0eozoVfbDw52hxrNic99JjiiTX6mOUnzmRtUHUofch8
    EKmSDnBq4kDXr6L7PvCzdKOrt0sohn26VaV/AgMBAAGjgeUwgeIwDAYDVR0TAQH/
    BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQD
    AgWgMB8GA1UdIwQYMBaAFDZChTaQujqm5C4FWaBQExPk0ttYMGMGA1UdEQRcMFqC
    LCouaHAtZ29sMDEtZDgubWpjLnByYy5ldWNhbHlwdHVzLXN5c3RlbXMuY29tgipo
    cC1nb2wwMS1kOC5tamMucHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wHQYDVR0O
    BBYEFMEFuDsdT+/7m9y/QS/pW5XRtLUDMA0GCSqGSIb3DQEBCwUAA4ICAQB3t8PI
    P7QUv3wTB5In7/1TU89JM8bo1nYu2AodVHoa9sJlGhRLLyIQcypAilxyA1zmZQSO
    vgYnlullh6x46lS9JQqwtCS8c1jZoOo7SdJJ7BGlND6MFBwZq8nyAthI7uc7yTbw
    otZqRAOFbNX9dAqEm2Qo36MidlaVmNeTVOb+tLC4qXgBJKTNOx+iFeg14qVhfs4/
    ryMmejA23Ph7b8txnYumYYCA+wsdh9gcyde9ygZT7Z4wfD0DutpcYW/cUMzGimc5
    6cQZpaSyhJmPJwaV8G4V6YWqAnWS0VTMlbdJWIYYTX6IUjf526pciqQa5p8Ef8wV
    HK1CVDiUBgvCsLxh2BqSwbLgkM5LK56fPJ7P/G8/5kb9bOGa1yW7gQ4ZjfRTyb+B
    5GD6T8nejsDu5mCcIsCAb8AXnvsO6u7m+jkt1rVrhkcwhVEaS41/z+Wj7K3JzLH0
    JTAepLAGiYR8MrrEgs/GA14yr1rEa0ijG8qklrVYv0muyOPcwvGi4nbpNQylmzVE
    F5+BIYe775dwu7gnpE+AIvfNDO+dnShKi6KfCIu1vCqZNzdd+KHe+MH466YM8nRH
    X2dFZM1A1IkCOC3TXeFvVzyvE+PWJvwe18N/7EFEo4N94+p2U78FQW6eL/WLknwv
    3MYJxRHCZTkQ/uayLnMtNoa4z0AjNIRwYojbGg==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    ```

### Replace Management Console Nginx Implementation with an Alternative which also supports UFS

In 4.2, the Eucalyptus Management Console pulls in Nginx along with a configuration file which
only works with the Management Console using self-signed SSL Certificates. We will replace this
with an alternate configuration which will support both the Mangement Console and User-Facing
Services with SSL, using SSL Certificates signed by a local Certification Authority. This
requires disabling the automatic use of Nginx by the Management Console first, and use of a
later version of Nginx.

1. (MW): Confirm Default Eucalyptus Console is accessible via default Nginx configuration

    Let's confirm the default configuration works before we replace it.

    ```bash
    Browse: http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    Browse: https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    ```

2. (MC): Disable Default Nginx Implementation

    ```bash
    sed -i -e "/NGINX_FLAGS=/ s/=/=NO/" /etc/sysconfig/eucaconsole
    ```

3. (MC): Restart Eucalyptus Console service

    ```bash
    service eucaconsole restart
    ```

4. (UFS+MC): Install Nginx yum repository

    We need a later version of Nginx than is currently in EPEL.

    ```bash
    cat << EOF > /etc/yum.repos.d/nginx.repo
    [nginx]
    name=nginx repo
    baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
    priority=1
    gpgcheck=0
    enabled=1
    EOF
    ```

5. (UFS+MC): Install Nginx

    This is needed for HTTP and HTTPS support running on standard ports

    ```bash
    yum install -y nginx
    ```

6. (UFS+MC): Configure Nginx to support virtual hosts

    ```bash
    if [ ! -f /etc/nginx/nginx.conf.orig ]; then
        \cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    fi

    mkdir -p /etc/nginx/server.d

    sed -i -e '/include.*conf\.d/a\    include /etc/nginx/server.d/*.conf;' \
           -e '/tcp_nopush/a\\n    server_names_hash_bucket_size 128;' \
           /etc/nginx/nginx.conf
    ```

7. (UFS+MC): Start Nginx service

    Confirm Nginx is running via a browser:
    http://$(hostname)/

    ```bash
    chkconfig nginx on

    service nginx start
    ```

8. (UFS+MC): Configure Nginx Upstream Servers

    Note this file assumes UFS and MC are co-located on the same host, as is the case in this
    example. If they are split, or multiple copies of one or both exist, this file should be
    created by hand to reference the appropriate server entries.

    ```bash
    cat << EOF > /etc/nginx/conf.d/upstream.conf
    #
    # Upstream servers
    #

    # Eucalytus User-Facing Services
    upstream ufs {
        server localhost:8773 max_fails=3 fail_timeout=30s;
    }

    # Eucalyptus Console
    upstream console {
        server localhost:8888 max_fails=3 fail_timeout=30s;
    }
    EOF
    ```

9. (UFS+MC): Configure Default Server

    We also need to update or create the default home and error pages. Because we are not
    using the EPEL re-packaging, we do not get what they added in this area, and must
    create something similar from scratch.

    ```bash
    if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
        \cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig
    fi

    cat << EOF > /etc/nginx/conf.d/default.conf
    #
    # Default server: http://$(hostname)
    #

    server {
        listen       80;
        server_name  $(hostname);

        root  /usr/share/nginx/html;

        access_log  /var/log/nginx/access.log;
        error_log   /var/log/nginx/error.log;

        charset  utf-8;

        keepalive_timeout  70;

        location / {
            index  index.html;
        }

        error_page  404  /404.html;
        location = /404.html {
            root   /usr/share/nginx/html;
        }

        error_page  500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        location ~ /\.ht {
            deny  all;
        }
    }
    EOF

    cat << EOF > /usr/share/nginx/html/index.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>Test Page for the Nginx HTTP Server on $(hostname -s)</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>
        <body>
            <h1>Welcome to <strong>nginx</strong> on $(hostname -s)!</h1>
            <div class=\"content\">
                <p>This page is used to test the proper operation of the
                <strong>nginx</strong> HTTP server after it has been
                installed. If you can read this page, it means that the
                web server installed at this site is working
                properly.</p>
                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>This is the default <tt>index.html</tt> page that
                        is distributed with <strong>nginx</strong> on
                        EPEL.  It is located in
                        <tt>/usr/share/nginx/html</tt>.</p>
                        <p>You should now put your content in a location of
                        your choice and edit the <tt>root</tt> configuration
                        directive in the <strong>nginx</strong>
                        configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>
                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF

    cat << EOF > /usr/share/nginx/html/404.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>The page is not found</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                h3 {
                    text-align: center;
                    background-color: #ff0000;
                    padding: 0.5em;
                    color: #fff;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>

        <body>
            <h1><strong>nginx error!</strong></h1>

            <div class=\"content\">

                <h3>The page you are looking for is not found.</h3>

                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>Something has triggered missing webpage on your
                        website. This is the default 404 error page for
                        <strong>nginx</strong> that is distributed with
                        EPEL.  It is located
                        <tt>/usr/share/nginx/html/404.html</tt></p>

                        <p>You should customize this error page for your own
                        site or edit the <tt>error_page</tt> directive in
                        the <strong>nginx</strong> configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>

                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF

    cat << EOF > /usr/share/nginx/html/50x.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>The page is temporarily unavailable</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                h3 {
                    text-align: center;
                    background-color: #ff0000;
                    padding: 0.5em;
                    color: #fff;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>

        <body>
            <h1><strong>nginx error!</strong></h1>

            <div class=\"content\">

                <h3>The page you are looking for is temporarily unavailable.  Please try again later.</h3>

                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>Something has triggered an error on your
                        website.  This is the default error page for
                        <strong>nginx</strong> that is distributed with
                        EPEL.  It is located
                        <tt>/usr/share/nginx/html/50x.html</tt></p>

                        <p>You should customize this error page for your own
                        site or edit the <tt>error_page</tt> directive in
                        the <strong>nginx</strong> configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>

                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF
    ```

10. (UFS+MC): Restart Nginx service

    Confirm Nginx is running via a browser:
    http://$(hostname)/

    ```bash
    service nginx restart
    ```

11. (UFS): Configure Eucalyptus User-Facing Services Reverse Proxy Server

    This server will proxy all API URLs via standard HTTP and HTTPS ports.

    ```bash
    cat << EOF > /etc/nginx/server.d/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    #
    # Eucalyptus User-Facing Services
    #

    server {
        listen       80  default_server;
        listen       443 default_server ssl;
        server_name  ec2.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  s3.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  iam.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  sts.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  monitoring.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  elasticloadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  swf.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN simpleworkflow.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;

        access_log  /var/log/nginx/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-access.log;
        error_log   /var/log/nginx/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key;

        keepalive_timeout  70;
        client_max_body_size 100M;
        client_body_buffer_size 128K;

        location / {
            proxy_pass            http://ufs;
            proxy_redirect        default;
            proxy_next_upstream   error timeout invalid_header http_500;
            proxy_connect_timeout 30;
            proxy_send_timeout    90;
            proxy_read_timeout    90;

            proxy_http_version    1.1;

            proxy_buffering       on;
            proxy_buffer_size     128K;
            proxy_buffers         4 256K;
            proxy_busy_buffers_size 256K;
            proxy_temp_file_write_size 512K;

            proxy_set_header      Host \$host;
            proxy_set_header      X-Real-IP  \$remote_addr;
            proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header      X-Forwarded-Proto \$scheme;
        }
    }
    EOF

    chmod 644 /etc/nginx/server.d/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    ```

12. (UFS): Restart Nginx service

    Confirm Eucalyptus User-Facing Services are running via a browser:
    http://compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    https://compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    These should respond with a 403 (Forbidden) error, indicating the AWSAccessKeyId is missing,
    if working correctly

    ```bash
    service nginx restart
    ```

13. (MC): Configure Eucalyptus Console Reverse Proxy Server

    This server will proxy the console via standard HTTP and HTTPS ports

    Requests which use HTTP are immediately rerouted to use HTTPS

    Once proxy is configured, configure the console to expect HTTPS

    ```bash
    cat << EOF > /etc/nginx/server.d/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    #
    # Eucalyptus Console
    #

    server {
        listen       80;
        server_name  console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        return       301 https://\$server_name\$request_uri;
    }

    server {
        listen       443 ssl;
        server_name  console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;

        access_log  /var/log/nginx/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-access.log;
        error_log   /var/log/nginx/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key;

        keepalive_timeout  70;
        client_max_body_size 100M;
        client_body_buffer_size 128K;

        location / {
            proxy_pass            http://console;
            proxy_redirect        default;
            proxy_next_upstream   error timeout invalid_header http_500;

            proxy_connect_timeout 30;
            proxy_send_timeout    90;
            proxy_read_timeout    90;

            proxy_buffering       on;
            proxy_buffer_size     128K;
            proxy_buffers         4 256K;
            proxy_busy_buffers_size 256K;
            proxy_temp_file_write_size 512K;

            proxy_set_header      Host \$host;
            proxy_set_header      X-Real-IP  \$remote_addr;
            proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header      X-Forwarded-Proto \$scheme;
        }
    }
    EOF

    chmod 644 /etc/nginx/server.d/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf

    sed -i -e "/^session.secure =/s/= .*$/= true/" \
           -e "/^session.secure/a\
    sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\
    sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key" /etc/eucaconsole/console.ini
    ```

14. (MC): Restart Nginx and Eucalyptus Console services

    Confirm Eucalyptus Console is running via a browser:
    http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    ```bash
    service nginx restart

    service eucaconsole restart
    ```

### Configure AWSCLI

This installs and configures AWS CLI to work with this region directly on the CLC. Apparently this is
currently an unsupported configuration without the use of Python virtual environments as pip updates
some of the python modules used by Eucalyptus, and this has not been tested. I haven't found this to 
cause any problems so far, but use at your own risk.

To be safe, you might want to skip the installation of AWS CLI on the CLC+MC, and install it only on
a separate management workstation, or set this up within a Python virtual environment, either of which
would be supported configurations.

1. (CLC): Install and Update Python Pip

    This step assumes the EPEL repo has been configured.

    ```bash
    yum install -y python-pip

    pip install --upgrade pip
    ```

2. (CLC): Install AWSCLI

    ```bash
    pip install awscli
    ```

3. (CLC): Configure AWSCLI Command Completion

    ```bash
    cat << EOF >> /etc/profile.d/aws.sh
    complete -C '/usr/local/bin/aws_completer' aws
    EOF

    source /etc/profile.d/aws.sh
    ```

4. (CLC+MC): Fix Broken Python Dependencies

    When awscli is installed by pip on the same host as the Management Console, it breaks the Console
    due to updated python dependencies which AWSCLI doesn't appear to need, but which Management Console
    can't use. We will reverse these changes so that Eucalyptus Console works again as before.

    These broken dependencies may vary over time. To discover what may be broken, run eucaconsole
    directly on the command line and note any errors.

    ```bash
    pip uninstall -y python-dateutil
    yum reinstall -y python-dateutil
    ```

    Confirm you can restart eucaconsole without it failing immediately, which is the symptom of a 
    broken dependency. On the second restart, confirm the stop is **OK**.

    ```bash
    service eucaconsole restart
    sleep 5
    service eucaconsole restart
    ```

5. (CLC): Configure AWSCLI to trust the Helion Eucalyptus Development PKI Infrastructure

    We will use the Helion Eucalyptus Development Root Certification Authority to sign SSL
    certificates. Certificates issued by this CA are not trusted by default.

    We must add this CA cert to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
    cp -a /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
          /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    # Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Label: "Helion Eucalyptus Development Root Certification Authority"
    # Serial: 0
    # MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12
    # SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B
    # SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd
    -----BEGIN CERTIFICATE-----
    MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y
    NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk
    BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI
    ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g
    QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV
    BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku
    Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh
    lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd
    Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL
    GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT
    47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn
    23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc
    HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9
    WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb
    qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1
    ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU
    NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT
    E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB
    BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
    OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa
    jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub
    sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d
    vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI
    kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap
    oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX
    wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD
    zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8
    qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M
    Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I
    Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI=
    -----END CERTIFICATE-----
    EOF

    mv /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
       /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.orig

    ln -s cacert.pem.local /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem
    ```

6. (CLC): Configure AWS CLI to support local Eucalyptus region

    This creates a modified version of the _endpoints.json file which the botocore Python module
    within AWSCLI uses to configure AWS endpoints, adding the new local Eucalyptus region endpoints.

    We rename the original _endpoints.json file with the .orig extension, so we can diff for
    changes if we need to update in the future against a new _endpoints.json, then create a
    symlink with the original name pointing to our new SSL version.

    ```bash
    cat << EOF > /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local.ssl
    {
      "_default":[
        {
          "uri":"{scheme}://{service}.{region}.$AWS_DEFAULT_DOMAIN",
          "constraints":[
            ["region", "startsWith", "${AWS_DEFAULT_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
              "signatureVersion": "v4"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "ec2": [
        {
          "uri":"{scheme}://compute.{region}.$AWS_DEFAULT_DOMAIN",
          "constraints": [
            ["region","startsWith","${AWS_DEFAULT_REGION%-*}-"]
          ]
        }
      ],
      "elasticloadbalancing": [
       {
        "uri":"{scheme}://loadbalancing.{region}.$AWS_DEFAULT_DOMAIN",
        "constraints": [
          ["region","startsWith","${AWS_DEFAULT_REGION%-*}-"]
        ]
       }
      ],
      "monitoring":[
        {
          "uri":"{scheme}://cloudwatch.{region}.$AWS_DEFAULT_DOMAIN",
          "constraints": [
           ["region","startsWith","${AWS_DEFAULT_REGION%-*}-"]
          ]
        }
      ],
      "swf":[
       {
        "uri":"{scheme}://simpleworkflow.{region}.$AWS_DEFAULT_DOMAIN",
        "constraints": [
         ["region","startsWith","${AWS_DEFAULT_REGION%-*}-"]
        ]
       }
      ],
      "iam":[
        {
          "uri":"https://euare.{region}.$AWS_DEFAULT_DOMAIN",
          "constraints":[
            ["region", "startsWith", "${AWS_DEFAULT_REGION%-*}-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.us-gov.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://iam.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "sdb":[
        {
          "uri":"https://sdb.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "sts":[
        {
          "uri":"https://tokens.{region}.$AWS_DEFAULT_DOMAIN",
          "constraints":[
            ["region", "startsWith", "${AWS_DEFAULT_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://sts.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "s3":[
        {
          "uri":"{scheme}://s3.amazonaws.com",
          "constraints":[
            ["region", "oneOf", ["us-east-1", null]]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        },
        {
          "uri":"{scheme}://objectstorage.{region}.$AWS_DEFAULT_DOMAIN//",
          "constraints": [
            ["region", "startsWith", "${AWS_DEFAULT_REGION%-*}-"]
          ],
          "properties": {
            "signatureVersion": "s3"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints": [
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        },
        {
          "uri":"{scheme}://{service}-{region}.amazonaws.com",
          "constraints": [
            ["region", "oneOf", ["us-east-1", "ap-northeast-1", "sa-east-1",
                                 "ap-southeast-1", "ap-southeast-2", "us-west-2",
                                 "us-west-1", "eu-west-1", "us-gov-west-1",
                                 "fips-us-gov-west-1"]]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        }
      ],
      "rds":[
        {
          "uri":"https://rds.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "route53":[
        {
          "uri":"https://route53.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "waf":[
        {
          "uri":"https://waf.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          },
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "elasticmapreduce":[
        {
          "uri":"https://elasticmapreduce.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.eu-central-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "eu-central-1"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.us-east-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.elasticmapreduce.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "sqs":[
        {
          "uri":"https://queue.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "importexport": [
        {
          "uri":"https://importexport.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "cloudfront":[
        {
          "uri":"https://cloudfront.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "dynamodb": [
        {
          "uri": "http://localhost:8000",
          "constraints": [
            ["region", "equals", "local"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1",
                "service": "dynamodb"
            }
          }
        }
      ]
    }
    EOF

    mv /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json \
       /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.orig

    ln -s _endpoints.json.local.ssl /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json
    ```

7. (CLC): Configure Default AWS credentials

    This configures the Eucalyptus Administrator as the default and an explicit profile.

    This step assumes the AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables are still
    set to the Eucalyptus Administrator from a prior call to "eval $(clcadmin-assume-system-credentials)".

    ```bash
    mkdir -p ~/.aws

    cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = $AWS_DEFAULT_REGION
    output = text

    [profile $AWS_DEFAULT_REGION-admin]
    region = $AWS_DEFAULT_REGION
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #

    [default]
    aws_access_key_id = $AWS_ACCESS_KEY
    aws_secret_access_key = $AWS_SECRET_KEY

    [$AWS_DEFAULT_REGION-admin]
    aws_access_key_id = $AWS_ACCESS_KEY
    aws_secret_access_key = $AWS_SECRET_KEY

    EOF

    chmod -R og-rwx ~/.aws
    ```

8. (CLC): Test AWSCLI

    ```bash
    aws ec2 describe-key-pairs

    aws ec2 describe-key-pairs --profile=default

    aws ec2 describe-key-pairs --profile=$AWS_DEFAULT_REGION-admin
    ```

### Configure for Demos

Continue with the Demo initialization scripts.

