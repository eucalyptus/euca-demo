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
    ```

    Adjust user profile to include demo scripts on PATH, and set default Eucalyptus region
    and profile.

    ```bash
    if ! grep -s -q "^PATH=.*eucalyptus/euca-demo/bin" ~/.bash_profile; then
        sed -i -e '/^PATH=/s/$/:\$HOME\/src\/eucalyptus\/euca-demo\/bin/' ~/.bash_profile
    fi

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

6. (All) Refresh Profile

    The easiest way to do this is simply to log out, then log back in.

    ```bash
    exit
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

24. (ALL?): Configure additional network settings

    TBD: Getting these errors, add steps to prevent these messages:

    WARN: net.ipv4.neigh.default.gc_interval is lower than the expected value of 3600
    To ensure that the settings are persisted, set net.ipv4.neigh.default.gc_interval = 3600 in /etc/sysctl.conf.
    Setting /proc/sys/net/ipv4/neigh/default/gc_interval dynamically to 3600

    WARN: net.ipv4.neigh.default.gc_stale_time is lower than the expected value of 3600
    To ensure that the settings are persisted, set net.ipv4.neigh.default.gc_stale_time = 3600 in /etc/sysctl.conf.
    Setting /proc/sys/net/ipv4/neigh/default/gc_stale_time dynamically to 3600

    WARN: net.ipv4.neigh.default.gc_thresh1 is lower than the expected value of 1024
    To ensure that the settings are persisted, set net.ipv4.neigh.default.gc_thresh1 = 1024 in /etc/sysctl.conf.
    Setting /proc/sys/net/ipv4/neigh/default/gc_thresh1 dynamically to 1024

    WARN: net.ipv4.neigh.default.gc_thresh3 is lower than the expected value of 4096
    To ensure that the settings are persisted, set net.ipv4.neigh.default.gc_thresh3 = 4096 in /etc/sysctl.conf.
    Setting /proc/sys/net/ipv4/neigh/default/gc_thresh3 dynamically to 4096

    WARN: net.ipv4.neigh.default.gc_thresh2 is lower than the expected value of 2048
    To ensure that the settings are persisted, set net.ipv4.neigh.default.gc_thresh2 = 2048 in /etc/sysctl.conf.
    Setting /proc/sys/net/ipv4/neigh/default/gc_thresh2 dynamically to 2048
    done.


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

7. (NC): Configure Eucalyptus Disk Allocation

    SKIP? 

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

9. (CLC+UFS/OSP/SC): Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value

    SKIP?

    ```bash
    heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

10. (MC): Configure Management Console with User Facing Services Address

    SKIP? On same host currently, test when they are on different hosts.

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

    TBD: Confirm this logic works with 4.2.

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

    * All services should be in the **enabled** state except for objectstorage, loadbalancingbackend
      and imagingbackend.
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
    sleep 15
    ```

4. (CLC): Register Storage Controller services

    Copy Encryption Keys. This is not needed in this example as each SC is coresident on the same host as the CC.

    ```bash
    #clcadmin-copy-keys -z ${EUCA_ZONEA} ${EUCA_SCA_PRIVATE_IP}
    #clcadmin-copy-keys -z ${EUCA_ZONEB} ${EUCA_SCB_PRIVATE_IP}
    ```

    Register the Storage Controller services.

    ```bash
    euca_conf --register-sc -P ${EUCA_ZONEA} -C ${EUCA_ZONEA_SC_NAME} -H ${EUCA_SCA_PRIVATE_IP}
    euca_conf --register-sc -P ${EUCA_ZONEB} -C ${EUCA_ZONEB_SC_NAME} -H ${EUCA_SCB_PRIVATE_IP}

    euserv-register-service -t storage -h ${EUCA_SCA_PRIVATE_IP} -z ${EUCA_ZONEA} ${EUCA_ZONEA_SC_NAME}
    euserv-register-service -t storage -h ${EUCA_SCB_PRIVATE_IP} -z ${EUCA_ZONEB} ${EUCA_ZONEB_SC_NAME}
    sleep 30
    ```

5. (CCA): Register Node Controller host(s) associated with Cluster 1

    Register the Node Controller services.

    ```bash
    clusteradmin-register-nodes ${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP}
    sleep 15
    ```

    Copy Encryption Keys.

    ```bash
    clusteradmin-copy-keys ${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP}
    ```

6. (CCB): Register Node Controller host(s) associated with Cluster 2

    Register the Node Controller services.

    ```bash
    clusteradmin-register-nodes ${EUCA_NC3_PRIVATE_IP} ${EUCA_NC4_PRIVATE_IP}
    sleep 15
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

    sed -e "s/(all user services on localhost)/Region $AWS_DEFAULT_REGION/g" \
        -e "s/region localhost/region $AWS_DEFAULT_REGION/g" \
        -e "s/127.0.0.1/$EUCA_UFS_PUBLIC_IP/g" \
        -e "/^certificate =/ s/=.*$/= \/usr\/share\/euca2ools\/certs\/cert-$AWS_DEFAULT_REGION.pem/" \
        -e "$ a\verify-ssl = false" \
        /etc/euca2ools/conf.d/localhost.ini > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini
    ```

2. (CLC): Configure Eucalyptus Region

    ```bash
    euctl region.region_name=$AWS_DEFAULT_REGION

    euca-describe-regions

    euca-describe-availablity-zones verbose
    ```

3. (CLC): Configure Eucalyptus Administrator Password

    ```bash
    euare-usermodloginprofile -u admin -p $EUCA_ADMIN_PASSWORD
    ```

4. (CLC): Generate Eucalyptus Administrator Certificates

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    euare-usercreatecert --out ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-cert.pem \
                         --keyout ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-pk.pem
    ```

5. (CLC): Initialize Eucalyptus Administrator Euca2ools Profile

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

6. (CLC): Import Support Keypair

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

7. (CLC): Confirm initial service status

    * All services should be in the **enabled** state except for imagingbackend, loadbalancingbackend, 
      objectstorage and storage.
    * All nodes should be in the **enabled** state.

    ````bash
    euserv-describe-services

    euserv-describe-node-controllers
    ```

8. (CLC): Load Edge Network JSON configuration

    ```bash
    euctl cloud.network.network_configuration=@/etc/eucalyptus/edge-$(date +%Y-%m-%d).json
    ```

9. (CLC): Configure Object Storage to use Walrus Backend

    ```bash
    euctl --region @localhost objectstorage.providerclient=walrus
    ```

    Optional: Confirm service status.

    * The objectstorage service should now be in the **enabled** state.
    * All services should be in the **enabled** state, except for imagingbackend,
      loadbalancingbackend and storage.

    ```bash
    euserv-describe-services
    ```

10. (CLC): Configure EBS Storage for DAS storage mode

    This step assumes additional storage configuration as described above was done,
    and there is an empty volume group named `eucalyptus` on the Storage Controller
    intended for DAS storage mode Logical Volumes.

    ```bash
    euctl ${EUCA_ZONEA}.storage.blockstoragemanager=das
    euctl ${EUCA_ZONEB}.storage.blockstoragemanager=das

    euctl ${EUCA_ZONEA}.storage.dasdevice=eucalyptus
    euctl ${EUCA_ZONEB}.storage.dasdevice=eucalyptus
    ```

    Optional: Confirm service status.

    * The storage service should now be in the **enabled** state.
    * All services should be in the **enabled** state except for imagingbackend and
      loadbalancingbackend.

    ```bash
    euserv-describe-services
    ```

11. (CLC): Install the Eucalyptus Service Image

    Install the Eucalyptus Service Image. This Image is used for the Imaging Worker and Load Balancing Worker.

    ```bash
    esi-install-image --install-default
    ```

    Set the Worker KeyPair, allowing use of the support KeyPair for Intance debugging.

    ```bash
    euctl services.imaging.worker.keyname=support
    euctl services.loadbalancing.worker.keyname=support
    euctl services.database.worker.keyname=support
    ```

    (Optional) Adjust Worker Instance Types.

    ```bash
    euctl services.imaging.worker.instance_type=m1.xlarge
    euctl services.loadbalancing.worker.instance_type=m1.xlarge
    euctl services.database.worker.instance_type=m1.xlarge
    ```

12. (CLC): Configure DNS

    (Skip) Configure Eucalyptus DNS Server

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

    cloud                   NS      ns1
    lb                      NS      ns1
    ```

    Confirm DNS resolution for Services

    ```bash
    dig +short compute.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short objectstorage.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short euare.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short tokens.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short autoscaling.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short cloudformation.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short cloudwatch.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}

    dig +short loadbalancing.${AWS_DEFAULT_REGION}.${AWS_DEFAULT_DOMAIN}
    ```

13. (CLC): Confirm service status

    All services should now be in the **enabled** state.

    ```bash
    euserv-describe-services
    ```

9. (CLC): Confirm apis

    ```bash
    euca-describe-regions

    euca-describe-availability-zones verbose

    euca-describe-nodes

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

### Configure Management Console for SSL

1. (MW): Confirm Eucalyptus Console service on default port

    ```bash
    Browse: http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN:8888
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

    sed -i -e "s/# \(listen 443 ssl;$\)/\1/" \
           -e "s/# \(ssl_certificate\)/\1/" \
           -e "s/\/path\/to\/ssl\/pem_file/\/etc\/pki\/tls\/certs\/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt/" \
           -e "s/\/path\/to\/ssl\/certificate_key/\/etc\/pki\/tls\/private\/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key/" /etc/nginx/nginx.conf
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
    Browse: https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    ```

### Configure for Demos

There are scripts within this git project which can be used to configure a new Eucalyptus region for use in
demos. These are useful for any system, as they indicate the type of setup usually needed to prepare any
system for use by users.

1. (CLC): Initialize Demo Account 

    The `euca-demo-01-initialize-account.sh` script can be run with an optional `-a <account>` 
    parameter to create additional accounts. Without this parameter, the default demo account
    is named "demo", and that will be used here.

    ```bash
    ~/src/eucalyptus/euca-demo/bin/euca-demo-01-initialize-account.sh
    ```

2. (CLC): Initiali Demo Account Dependencies.sh

    The `euca-demo-02-initialize-dependencies.sh` script can be run with an optional `-a <account>` 
    parameter to create dependencies in additional accounts created for demo purposes with the
    `euca-demo-01-initialize-account.sh` script. Without this parameter, the default demo account
    is named "demo", and that will be used here.

    ```bash
    ~/src/eucalyptus/euca-demo/bin/euca-demo-02-initialize-dependencies.sh
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
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from CLC to SCA:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from CLC to OSP:8773 failed!'
    nc -z ${EUCA_CC_PUBLIC_IP} 8774 || echo 'Connection from CLC to CCA:8774 failed!'
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
    nc -z ${EUCA_NC1_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA1:8775 failed!'
    nc -z ${EUCA_NC2_PRIVATE_IP} 8775 || echo 'Connection from CCA to NCA2:8775 failed!'
    ```

6. (SC): Verify Connectivity

    ```bash
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from SCA to SCA:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from SCA to OSP:8773 failed!'
    nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from SCA to CLC:8777 failed!'
    ```

7. (NC): Verify Connectivity

    ```bash
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from NC to OSP:8773 failed!'
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from NC to SCA:8773 failed!'
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

