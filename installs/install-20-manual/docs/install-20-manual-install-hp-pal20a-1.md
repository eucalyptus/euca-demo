# Install Procedure for region hp-pal20a-1
## 1-Node POC

This document describes the manual procedure to setup region **hp-pal20a-1**,
with 1 large host for all components.

This variant is meant to be run as root

This POC will use **hp-pal10a-1** as the AWS_DEFAULT_REGION.

The full parent DNS domain will be **hp-pal20a-1.hpccc.com**. Note that this
domain only resolves inside the EBC.

This is using the following node in the EBC machine room:
- dl580gen8a.hpccc.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 172.0.1.8/24 (VLAN 10)
  - Private: 172.0.2.8/24 (VLAN 20)

Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- OSP: Object Storage Provider (Walrus)
- CC:  Cluster Controller Host
- SC:  Storage Controller Host
- NCn: Node Controller(s)

### Hardware Configuration and Operating System Installation

The hardware configuration and operating system installation were done manually for this first
iteration of the demo, as a PXE boot and kickstart environment were not yet available.

The host will eventually have 10 480GB SSD disks, with 5 installed in the top disk chassis, and
5 installed in the lower disk chassis, and configured by the SmartArray P830i Controller
into the following RAID groups:

- Disks 1,6, RAID1, /dev/sda, used for boot (/boot), root (/), and swap.
- Disks 2-5,7-10, RAID10, /dev/sdb, used for eucalyptus (/var/lib/eucalyptus) and EBS volumes

A manual installation of CentOS 6.6 was done via the 
[CentOS-6.6-x86_64-minimal.iso](http://mirrors.kernel.org/centos/6.6/isos/x86_64/CentOS-6.6-x86_64-minimal.iso)
DVD, mounted as a virtual CD-ROM via the iLo management console.

During the manual installation, we chose manual disk formatting. The result is shown in the
Anaconda-generated kickstart file located on the host: /root/anaconda-ks.cfg. From this file,
you can obtain the original kickstart configuration if you need to perform another manual OS
installation. Hopefully we can replace with a kickstart-based method which automates most of 
this before that is needed. Here is the relevant section in case the original kickstart is lost:

```
clearpart --all --drives=sda,sdb
part /boot --fstype=ext4 --ondisk=sda --asprimary --size=1024
part pv01 --ondisk=sda --asprimary --size=1 --grow
part pv02 --ondisk=sdb --size=1 --grow
volgroup local --pesize=4096 pv01
volgroup eucalyptus --pesize=4096 pv02
logvol swap --name=swap --vgname=local --size=65536
logvol / --fstype=ext4 --name=root --vgname=local --size=260196
logvol /var/lib/eucalyptus/archive --fstype=ext4 --name=archive --vgname=local --size=131072
logvol /var/lib/eucalyptus --fstype=ext4 --name=eucalyptus --vgname=eucalyptus --size=1048576
```

How we have allocated disk space can be described as follows:
- Increased size of /boot to 1 GiB, just in case this system lives for a while with extra kernels
- Created local VG on rest of initial RAID 1 disk set, for swap, OS, and archives
- Created eucalyptus VG on RAID 10, for use by Eucalyptus
- Created swap LV on local VG, with larger 64 GiB size in case we want to test memory overcommit
- Created root LV on local VG, with all space except that used for swap and archive
- Created archive LV on local VG, mount point /var/lib/eucalyptus/archive, with 128 GiB, to store
  db backups on a disk separate from the eucalyptus database
- Created eucalyptus LV on eucalyptus VG, mount point /var/lib/eucalyptus, with 1 TiB, for use
  by most eucalyptus functions
- Reserved remaining space on eucalyptus VG, about 760 GiB, for use by Eucalyptus Storage Controller
  for EBS Volumes and Snapshots

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    ```bash
    export AWS_DEFAULT_REGION=hp-pal20a-1

    export EUCA_DNS_PUBLIC_DOMAIN=hpccc.com
    export EUCA_DNS_PRIVATE_DOMAIN=internal
    export EUCA_DNS_INSTANCE_SUBDOMAIN=cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
    export EUCA_DNS_PARENT_HOST=dc1a.hpccc.com
    export EUCA_DNS_PARENT_IP=10.0.1.91

    export EUCA_SERVICE_API_NAME=api

    export EUCA_PUBLIC_IP_RANGE=172.0.1.64-172.0.1.254

    export EUCA_CLUSTER1=${AWS_DEFAULT_REGION}a
    export EUCA_CLUSTER1_CC_NAME=${EUCA_CLUSTER1}-cc
    export EUCA_CLUSTER1_SC_NAME=${EUCA_CLUSTER1}-sc

    export EUCA_CLUSTER1_PRIVATE_IP_RANGE=172.0.2.64-172.0.2.254
    export EUCA_CLUSTER1_PRIVATE_NAME=172.0.2.0
    export EUCA_CLUSTER1_PRIVATE_SUBNET=172.0.2.0
    export EUCA_CLUSTER1_PRIVATE_NETMASK=255.255.255.0
    export EUCA_CLUSTER1_PRIVATE_GATEWAY=172.0.2.1

    export EUCA_CLC_PUBLIC_INTERFACE=br10
    export EUCA_CLC_PRIVATE_INTERFACE=br20
    export EUCA_CLC_PUBLIC_IP=172.0.1.8
    export EUCA_CLC_PRIVATE_IP=172.0.2.8

    export EUCA_UFS_PUBLIC_INTERFACE=br10
    export EUCA_UFS_PRIVATE_INTERFACE=br20
    export EUCA_UFS_PUBLIC_IP=172.0.1.8
    export EUCA_UFS_PRIVATE_IP=172.0.2.8

    export EUCA_MC_PUBLIC_INTERFACE=br10
    export EUCA_MC_PRIVATE_INTERFACE=br20
    export EUCA_MC_PUBLIC_IP=172.0.1.8
    export EUCA_MC_PRIVATE_IP=172.0.2.8

    export EUCA_OSP_PUBLIC_INTERFACE=br10
    export EUCA_OSP_PRIVATE_INTERFACE=br20
    export EUCA_OSP_PUBLIC_IP=172.0.1.8
    export EUCA_OSP_PRIVATE_IP=172.0.2.8

    export EUCA_CC_PUBLIC_INTERFACE=br10
    export EUCA_CC_PRIVATE_INTERFACE=br20
    export EUCA_CC_PUBLIC_IP=172.0.1.8
    export EUCA_CC_PRIVATE_IP=172.0.2.8

    export EUCA_SC_PUBLIC_INTERFACE=br10
    export EUCA_SC_PRIVATE_INTERFACE=br20
    export EUCA_SC_PUBLIC_IP=172.0.1.8
    export EUCA_SC_PRIVATE_IP=172.0.2.8

    export EUCA_NC_PUBLIC_INTERFACE=br10
    export EUCA_NC_PRIVATE_INTERFACE=br20
    export EUCA_NC_PRIVATE_BRIDGE=br20

    export EUCA_NC1_PUBLIC_IP=172.0.1.8
    export EUCA_NC1_PRIVATE_IP=172.0.2.8
    ```

### Initialize Host Conventions

This section will initialize the host with some conventions normally added during the kickstart
process, not currently available for this host.

1. (All) Install additional packages

    Add packages which are used during host preparation, eucalyptus installation or testing.

    ```bash
    yum install -y man wget zip unzip git qemu-img-rhev nc w3m rsync bind-utils tree
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
dig +short ${EUCA_DNS_PUBLIC_DOMAIN}
10.0.1.91

dig +short ns1.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
172.0.1.8

dig +short clc.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
172.0.1.8

dig +short ufs.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
172.0.1.8

dig +short console.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
172.0.1.8
```

**NS Records**

```bash
dig +short -t NS ${EUCA_DNS_PUBLIC_DOMAIN}
dc1a.hpccc.com.

dig +short -t NS ${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
dc1a.hpccc.com.
```

**MX records**

Note: Mail was not completely setup on the initial installation, as there is no mail relay
currently in place in the EBC.

```bash
dig +short -t MX hp-pal20a-1.hpccc.com
smtp.hp-pal20a-1.hpccc.com.
```

### Initialize Dependencies

1. Confirm storage

    This environment uses a single large DL580 populated with 2 146GB disks in a RAID 1 array
    which appears to the OS as /dev/sda, and another 6 300GB disks in a RAID 10 array which
    appears to the OS as /dev/sdb.

    Initially manual disk and LVM configuration was done during a manual OS install. We will
    attempt to convert this manual process to something kickstart based if time allows.

    The kickstart produced by Anaconda during a manual installation can be found here: 
    `/root/anaconda-ks.cfg. To assist with any future kickstart, the disk configuration
    section (edited for order, improvements and clarity) should look like:

    ```bash
    clearpart --all --drives=sda,sdb
    part /boot --fstype=ext4 --ondisk=sda --asprimary --size=1024
    part pv01 --ondisk=sda --asprimary --size=1 --grow
    part pv02 --ondisk=sdb --size=1 --grow
    volgroup local --pesize=4096 pv01
    volgroup eucalyptus --pesize=4096 pv02
    logvol swap --name=swap --vgname=local --size=65536
    logvol / --fstype=ext4 --name=root --vgname=local --size=260196
    logvol /var/lib/eucalyptus/archive --fstype=ext4 --name=archive --vgname=local --size=131072
    logvol /var/lib/eucalyptus --fstype=ext4 --name=eucalyptus --vgname=eucalyptus --size=1048576
    ```

    Note that we are leaving about half of VG `eucalyptus` on disk `sdb` un-reserved and
    available for use by the Eucalyptus Storage Controller, which will use the `das` storage
    mode, where volumes and snapshots are created as LVs within this VG.
 
    Here is the output of some disk commands showing the storage layout created by anaconda
    during the manual install.

    **Mounted Filesystems**

    ```bash
    df -h
    Filesystem            Size  Used Avail Use% Mounted on
    /dev/mapper/local-root
                          250G  981M  237G   1% /
    tmpfs                  63G     0   63G   0% /dev/shm
    /dev/sda1             976M   47M  879M   5% /boot
    /dev/mapper/eucalyptus-eucalyptus
                         1008G   72M  957G   1% /var/lib/eucalyptus
    /dev/mapper/local-archive
                          126G   60M  120G   1% /var/lib/eucalyptus/archive
    ```

    **Logical Volume Management**

    ```bash
    pvscan
      PV /dev/sdb1   VG eucalyptus   lvm2 [1.75 TiB / 764.39 GiB free]
      PV /dev/sda2   VG local        lvm2 [446.10 GiB / 0    free]
      Total: 2 [2.18 TiB] / in use: 2 [2.18 TiB] / in no VG: 0 [0   ]

    lvscan
      ACTIVE            '/dev/eucalyptus/eucalyptus' [1.00 TiB] inherit
      ACTIVE            '/dev/local/root' [254.10 GiB] inherit
      ACTIVE            '/dev/local/archive' [128.00 GiB] inherit
      ACTIVE            '/dev/local/swap' [64.00 GiB] inherit
    ```

    **Disk Partitions**

    ```bash
    fdisk -l

    Disk /dev/sda: 480.1 GB, 480070426624 bytes
    255 heads, 63 sectors/track, 58365 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 262144 bytes
    Disk identifier: 0x000a1ab6

       Device Boot      Start         End      Blocks   Id  System
    /dev/sda1   *           1         131     1048576   83  Linux
    Partition 1 does not end on cylinder boundary.
    /dev/sda2             131       58366   467768320   8e  Linux LVM

    Disk /dev/sdb: 1920.3 GB, 1920279076864 bytes
    255 heads, 63 sectors/track, 233460 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 1048576 bytes
    Disk identifier: 0x000c1938

       Device Boot      Start         End      Blocks   Id  System
    /dev/sdb1               1      233461  1875270656   8e  Linux LVM

    Disk /dev/mapper/local-root: 272.8 GB, 272835280896 bytes
    255 heads, 63 sectors/track, 33170 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 262144 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-swap: 68.7 GB, 68719476736 bytes
    255 heads, 63 sectors/track, 8354 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 262144 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/local-archive: 137.4 GB, 137438953472 bytes
    255 heads, 63 sectors/track, 16709 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 262144 bytes
    Disk identifier: 0x00000000


    Disk /dev/mapper/eucalyptus-eucalyptus: 1099.5 GB, 1099511627776 bytes
    255 heads, 63 sectors/track, 133674 cylinders
    Units = cylinders of 16065 * 512 = 8225280 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 262144 bytes / 1048576 bytes
    Disk identifier: 0x00000000
    ```
    
2. Install bridge utilities package

    ```bash
    yum install -y bridge-utils
    ```

3. Manually configure complex networking.

    Currently this bridging is configured manually, with these statements.

    **TODO:** reference variables set above in scripts below. Currently values are
    hard-coded.

    ```bash
    cat << EOF > /etc/modprobe.d/bonding.conf
    alias bond0 bonding
    options bond0 mode=4 miimon=80
    EOF

    cat << EOF > /etc/sysconfig/network
    NETWORKING=yes
    NETWORKING_IPV6=no
    HOSTNAME=dl580gen8a.hpccc.com
    GATEWAY=172.0.1.1
    NOZEROCONF=yes
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br10
    # Eucalyptus Public Network (172.0.1.0/24)
    NAME=br10
    DEVICE=br10
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR0=172.0.1.8
    PREFIX0=24
    GATEWAY0=172.0.1.1
    DNS1=10.0.1.91
    DNS2=10.0.1.92
    DOMAIN="hpccc.com"
    DEFROUTE=yes
    PEERDNS=yes
    PEERROUTES=yes
    IPV6INIT=no
    STP=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br20
    # Eucalyptus Private Network (172.0.2.0/24)
    NAME=br20
    DEVICE=br20
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR0=172.0.2.8
    PREFIX0=24
    GATEWAY0=172.0.2.1
    DNS1=10.0.1.91
    DNS2=10.0.1.92
    DOMAIN="hpccc.com"
    IPV6INIT=no
    STP=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
    # Bonded interface into Eucalyptus Public Network (172.0.1.0/24)
    NAME=bond0
    DEVICE=bond0
    TYPE=Bond
    ONBOOT=yes
    NETBOOT=yes
    BOOTPROTO=none
    BRIDGE=br10
    IPV6INIT=no
    PERSISTENT_DHCLIENT=yes
    NM_CONTROLLED=no
    BONDING_MASTER=yes
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0.20
    # Bonded interface into Eucalyptus Private Network (172.0.2.0/24)
    NAME=bond0.20
    DEVICE=bond0.20
    TYPE=Vlan
    VLAN=yes
    VLAN_ID=20
    PHYSDEV=bond0
    MASTER=br20
    BRIDGE=br20
    ONBOOT=yes
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
    # em1
    NAME=eth0
    DEVICE=eth0
    TYPE=Ethernet
    HWADDR=F0:92:1C:05:EB:B8
    ONBOOT=yes
    NETBOOT=yes
    BOOTPROTO=none
    MASTER=bond0
    SLAVE=yes
    USERCTL=no
    NM_CONTROLLED=no
    EOF

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
    # em2
    NAME=eth1
    DEVICE=eth1
    TYPE=Ethernet
    HWADDR=F0:92:1C:05:EB:BC
    ONBOOT=yes
    NETBOOT=yes
    BOOTPROTO=none
    MASTER=bond0
    SLAVE=yes
    USERCTL=no
    NM_CONTROLLED=no
    EOF
    ```

4. Restart networking

    ```bash
    service network restart
    ```

5. Confirm networking

    ```bash
    ip addr | grep " inet "
    netstat -nr
    ```

6. (CLC+UFS+MC+OSP+CC+SC+NC): Configure firewall, but disable during installation

    Note: These have not been thoroughly validated. It may not be necessary to open all of these
    when all components run on a single host, as is the case here, and some ports may be missing.

    Ports to open by component

    * tcp   22 - Login, Control (ALL)
    * udp   53 - DNS (CLC)
    * tcp   53 - DNS (CLC)
    * tcp   80 - Console - HTTP (MC)
    * tcp  443 - Console - HTTPS (MC)
    * tcp 5005 - Debug (CLC+UFS+OSP+CC+SC+NC)
    * tcp 7500 - Diagnostics (CLC+UFS+OSP+CC+SC)
    * tcp 8080 - Credentials (CLC)
    * tcp 8772 - Debug (CLC+UFS+OSP+CC+SC+NC)
    * tcp 8773 - Web services (CLC+UFS+OSP+SC+NC)
    * tcp 8774 - Web services (CC)
    * tcp 8775 - Web services (NC)
    * tcp 8777 - Database (CLC)
    * tcp 8778 - Multicast (CLC+UFS+OSP+CC+SC+NC)
    * tcp 8779-8849 - jGroups (CLC+UFS+OSP+SC)
    * tcp 8888 - Console - Direct (MC)
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
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
    -A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 5005 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 7500 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8772 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8773 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8774 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8775 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8777 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8778 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8779:8849 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8888 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 16514 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT
    EOF

    chkconfig iptables on
    service iptables stop
    ```

7. Disable SELinux

    ```bash
    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    setenforce 0
    ```

8. Install and Configure the NTP service

    ```bash
    yum install -y ntp

    chkconfig ntpd on
    service ntpd start

    ntpdate -u  0.centos.pool.ntp.org
    hwclock --systohc
    ```

9. Install and Configure Mail Relay

    Note: This step was run, and this will allow Eucalyptus to send Email to the Postfix instance
    which runs on localhost. But, until the EBC installs a local mail relay and configures local
    DNS with MX records which point to it, mail will be queued but can not leave the host.

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

10. Install Email test client and test email

    Sending to personal email address on Google Apps - Please update to use your own email address!

    Confirm email is sent to relay by tailing /var/log/maillog on this host and on mail relay host.

    ```bash
    yum install -y mutt

    echo "test" | mutt -x -s "Test from $(hostname -s) on $(date)" michael.crawford@mjcconsulting.com
    ````

11. Configure packet routing

    This configuration is needed on a Node Controller, and used here as this environment has a 
    single host for all components. When fully distributed, we must also configure packet routing
    on the Cluster Controller, but in that case only the first statement below is needed.

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf
    sed -i -e '/^net.bridge.bridge-nf-call-iptables = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    cat /proc/sys/net/bridge/bridge-nf-call-iptables
    ```

### Install Eucalyptus

1. Configure yum repositories

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    yum install -y \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm
    ```

2. Install packages

    Since in this environment, a single host will run all components, it is possible to install
    all packages with a single yum command. For clarity, this step splits the package installs
    to show the more typical separation of components into separate hosts.

    ```bash
    yum install -y eucalyptus-cloud eucaconsole eucalyptus-service-image
    yum install -y eucalyptus-cloud eucalyptus-walrus
    yum install -y eucalyptus-cloud eucalyptus-cc eucalyptus-sc
    yum install -y eucalyptus-nc
    ```

3. Remove Devfault libvirt network.

    The default virtual networks created during the installation of the libvirt package dependency
    can create problems with Eucalyptus, so we remove them. They are not used in Eucalyptus
    installations.

    ```bash
    virsh net-destroy default
    virsh net-autostart default --disable
    ```

### Configure Eucalyptus

1. Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CLC_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CLC_PUBLIC_INTERFACE}\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CLC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

2. Create Eucalyptus EDGE Networking configuration file

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

3. Configure Eucalyptus Disk Allocation

    ```bash
    nc_work_size=500000
    nc_cache_size=100000

    sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
           -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf
    ```

4. Configure Eucalyptus to use Private IP for Metadata

    ```bash
    cat << EOF >> /etc/eucalyptus/eucalyptus.conf

    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    EOF
    ```

5. Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value. This step was skipped on the initial install.

    ```bash
    #heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

6. Configure Management Console with Cloud Controller and Walrus addresses

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

1. Initialize the Cloud Controller service

    ```bash
    euca_conf --initialize
    ```

2. Start the Cloud Controller service

    ```bash
    service eucalyptus-cloud start
    ```

3. Start the Cluster Controller service

    ```bash
    service eucalyptus-cc start
    ```

4. Start the Node Controller and Eucanetd services

    Expect failure messages due to missing keys. This will be corrected when the nodes are
    registered.

    ```bash
    service eucalyptus-nc start

    service eucanetd start
    ```

5. Start the Management Console service

    ```bash
    service eucaconsole start
    ```

6. Confirm service startup

    Confirm logs are being written.

    ```bash
    ls -l /var/log/eucalyptus
    ```

### Register Eucalyptus

1. Register User-Facing services

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

2. Register Walrus as the Object Storage Provider (OSP)

    ```bash
    euca_conf --register-walrusbackend -P walrus -C walrus -H ${EUCA_OSP_PRIVATE_IP}
    sleep 15
    ```

3. Register Storage Controller service

    ```bash
    euca_conf --register-sc -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_SC_NAME} -H ${EUCA_SC_PRIVATE_IP}
    sleep 15
    ```

4. Register Cluster Controller service

    ```bash
    euca_conf --register-cluster -P ${EUCA_CLUSTER1} -C ${EUCA_CLUSTER1_CC_NAME} -H ${EUCA_CC_PRIVATE_IP}
    sleep 15
    ```

5. Register Node Controller host(s)

    ```bash
    euca_conf --register-nodes="${EUCA_NC1_PRIVATE_IP}"
    sleep 15
    ```

6. Restart the Node Controller services

    The failure messages due to missing keys should no longer be there on restart.

    ```bash
    service eucalyptus-nc restart
    ```

### Runtime Configuration

1. Use Eucalyptus Administrator credentials

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
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    euca_conf --get-credentials ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    cp -a ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc.orig

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Confirm initial service status

    * All services should be in the ENABLED state except, for objectstorage, loadbalancingbackend,
      imagingbackend, and storage.
    * All nodes should be in the ENABLED state.

    ````bash
    euca-describe-services | cut -f1-5

    euca-describe-regions

    euca-describe-availability-zones verbose

    euca-describe-nodes
    ```

3. Configure EBS Storage

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

4. Configure Object Storage

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

5. Refresh Eucalyptus Administrator credentials

    As noted above, if the eucarc does not contain the environment variables for the key and
    certificate, we must patch it to add the missing variables which reference the previously
    downloaded versions of the key and certificate files.

    ```bash
    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

6. Load Edge Network JSON configuration

    ```bash
    euca-modify-property -f cloud.network.network_configuration=/etc/eucalyptus/edge-$(date +%Y-%m-%d).json
    sleep 15
    ```

7. Install the imaging-worker and load-balancer images

    ```bash
    euca-install-load-balancer --install-default

    euca-install-imaging-worker --install-default
    ```

8. Confirm service status

    All services should now be in the ENABLED state.

    ```bash
    euca-describe-services | cut -f1-5
    ```

9. Confirm apis

    ```bash
    euca-describe-regions

    euca-describe-availability-zones verbose

    euca-describe-nodes

    euca-describe-instance-types --show-capacity
    ```

### Configure DNS

1. Configure Eucalyptus DNS Server

    ```bash
    euca-modify-property -p dns.dns_listener_address_match=${EUCA_CLC_PUBLIC_IP}

    euca-modify-property -p system.dns.nameserver=${EUCA_DNS_PARENT_HOST}

    euca-modify-property -p system.dns.nameserveraddress=${EUCA_DNS_PARENT_IP}
    ```

2. Configure DNS Timeout and TTL

    ```bash
    euca-modify-property -p dns.tcp.timeout_seconds=30

    euca-modify-property -p services.loadbalancing.dns_ttl=15
    ```

3. Configure DNS Domain

    ```bash
    euca-modify-property -p system.dns.dnsdomain=${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
    ```

4. Configure DNS Sub-Domains

    ```bash
    euca-modify-property -p cloud.vmstate.instance_subdomain=.${EUCA_DNS_INSTANCE_SUBDOMAIN}

    euca-modify-property -p services.loadbalancing.dns_subdomain=${EUCA_DNS_LOADBALANCER_SUBDOMAIN}
    ```

5. Enable DNS

    ```bash
    euca-modify-property -p bootstrap.webservices.use_instance_dns=true

    euca-modify-property -p bootstrap.webservices.use_dns_delegation=true
    ```

6. Refresh Eucalyptus Administrator credentials
 
    As noted above, if the eucarc does not contain the environment variables for the key and 
    certificate, we must patch it to add the missing variables which reference the previously 
    downloaded versions of the key and certificate files.

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    euca-get-credentials -u admin ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip -uo ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    if ! grep -s -q "export EC2_PRIVATE_KEY=" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc; then
        pk_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-pk.pem | tail -1)
        cert_pem=$(ls -1 ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/euca2-admin-*-cert.pem | tail -1)
        sed -i -e "/EUSTORE_URL=/aexport EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}/${pk_pem##*/}\nexport EC2_CERT=\${EUCA_KEY_DIR}/${cert_pem##*/}" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    fi

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

7. Display Parent DNS Server Sample Configuration (skipped)

    ```bash
    # TBD
    ```

8. Confirm DNS resolution for Services

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

1. Configure Eucalyptus Administrator Password

    ```bash
    euare-usermodloginprofile -u admin -p password
    ```

### Configure Support-Related Properties

1. (CLC): Create Eucalyptus Administrator Support Keypair

    ```bash
    euca-create-keypair admin-support | tee ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-support.pem
    ```

2. (CLC): Configure Service Instance Login

    ```bash
    euca-modify-property -p services.database.worker.keyname=admin-support

    euca-modify-property -p services.imaging.worker.keyname=admin-support

    euca-modify-property -p services.loadbalancing.worker.keyname=admin-support
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
    cat << EOF > /etc/pki/ca-trust/source/anchors/HPCCC_DC1A_CA.crt
    -----BEGIN CERTIFICATE-----
    MIIDpDCCAoygAwIBAgIQY375YpycpI9MLtbaTAMeUTANBgkqhkiG9w0BAQUFADBE
    MRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAU
    BgNVBAMTDWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE0MjExNzI4WhcNMjAwNDEzMjEy
    NzI3WjBEMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBj
    Y2MxFjAUBgNVBAMTDWhwY2NjLURDMUEtQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQCmoHR7XOde9LHGmEa0rNAkAt6jDMpxypW3C1xcKi+T8ZcMUwdv
    K9oQv9ZnRAhyCEqQc/VobiiR3JO9/lz86Y9XsoysbrU2gZTfyYw03DH32Tm3tYaI
    xsK+ThBRkM0HhKZiGAO5d5UFz2f3xWWgaahHEbXoOYbuBYxJ6TWpmhrV/NbVdJXI
    /44mdCI4TAjIlQemFa91ZyKdEuT76vt13leyzld4eyl0LU1go3vaLLNo1G7tY5jW
    2aUw7hgpd5jWFPrCNkdvuk04KHl617H+qGGvWKlapG8f7e6voHjgbA2Zqsoa4lQr
    6Is13kAZIQRCEUrppeYWOkhzks/iwWIyJMQZAgMBAAGjgZEwgY4wEwYJKwYBBAGC
    NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD
    VR0OBBYEFO8xVEl5RiVrrtGK9Ou+YdNuDNRtMBIGCSsGAQQBgjcVAQQFAgMDAAMw
    IwYJKwYBBAGCNxUCBBYEFMuCtZAjoURHCHCk5JSf7gpClFeyMA0GCSqGSIb3DQEB
    BQUAA4IBAQAlkTqoUmW6NMzpVQC4aaWVhpwFgU61Vg9d/eDbYZ8OKRxObpjjJv3L
    kHIxVlKnt/XjQ/6KOsneo0cgdxts7vPDxEyMW1/Svronzau3LnMjnnwp2RV0Rn/B
    TQi1NgNLzDATqo1naan6WCiZwL+O2kDJlp5xXfFLx3Gapl3Opa9ShbO1XQmbCdPT
    A7FriDiLLBTWAd6TqhmfH+dcz56TGr36itJAh8i2jb2gGErB0DvBN2S4bCvJ1e54
    gYH1DylEpeALZeYK3M30AoRivO5eAivFRpUi/CBLVaFqmD4E2MI8mdbWtLH1t0Qi
    3hyLaqkOlbnIuxMLe4X041c3cZ+PI7wm
    -----END CERTIFICATE-----
    EOF

    update-ca-trust enable

    update-ca-trust extract
    ```

2. (CLC+UFS+MC) Install Wildcard Site SSL Key

    ```bash
    cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEAvubSKR8pfmgK0U6NuA8YymNrXT1m51PdRozNQu11cvyOOyM0
    68NoJ2p69IeXL4PuWJizcAGtFA3FbO5zMUrTuwY/vfJlYkkgCA8YdEGD1VdOvfKq
    ceXu8BolttCmhPKUB1mGIAQXmKB3HDJ0ps3rJniOGxqPsyvDoJUWMjeIyEykm5jI
    79hgjtWF9kPHSoX8Nx6UBuAoXv/4HvuOwnsteVD2DG91cTbDXLB1phMOByIwWWer
    JB/RkUggc8xa5V38HBTSYq+4s6xCr6eU1kHjyRJS5VVmH6OwCmp2sT6oYKb44Vw/
    cHargIooiN6tjohBll5q8uaDhQ3aoYBEF0GLCwIDAQABAoIBAQCF2NS1XFH9fPlI
    s6kNyhf5nydh4nFJ9DULCCHKsS9OBeG7eP3b59AZAsFevcq01+2/VKFLAQHXM6ie
    rbk6cFpvoPwEM/X9qYO54sukh2LlrCdbas8yuKKE2fBjc3utb192n8A4pmXc73VT
    4dSEN5COEqygOElUuHSbHKzJXMKcnFnvth5JW8KVGGyNVks7QdJirbokluBX87OA
    EekNWwsddPsLltRw7YEK5nn7KAhRwUVqAO4mSFqMK6uP4TRjsQODY+G5bQk8kp+D
    DcvW8Le0I6KWscpaRMkXPu5+reTcKpkRVRH/qQmBepQncjZhr2qj9NQqPmUOf22s
    9X3cHHyRAoGBAOaMf/XUvs2XGafyqxwk0wJPss2lQD12sMaCY8yGyTLcQm2bMhrA
    cqxC33NLQjIQlQrvX8vV0uzhbXIcgtCTRt5yn8LqAz1xUUguIu9HIZ9CocG8tome
    I7dXkTJJe7+hVDpML0AbwXLFs/dG5jxAFJ6euYJzSXH9tMVzO0OV5V0PAoGBANP5
    2+Wu8zjGcdxEGImIXyRD4Zd1VIWd+igs28+nJGvixnAalbQOGKPZ6qeIrbI/IAJx
    F9xpxmuhopdHRWqDzO7n01H2euHfgrk5OqqXZt/Y9DZPyNRZZDroT322ro3m3wLX
    o+oT9sRGtWbl1Koza8d/AbxvVMePO/SFED+kJSpFAoGAEyIv8HgCic9zeqPCHajU
    tklk/norda5nB2KE49F/2y+6d5w8sUmteqxmHQxu5vbHV8v7+E+7nJss2R6SoLrI
    U+fRaHzBXhUMeOATWCZgHPaLtCd0QsGUF0A2NaUxlvrNobT26uwixuKvh+Mjcnai
    /3MO1Eu7GbHDket5TKehDHMCgYEAqPYJ7wQKXoDfFOE6ZbXLkE6DLISbQH3xfcBz
    3QqvH0d9QLIQDZsGzOPQBIYPXXqvewLGMCwnunb18Hsgu4we93bVnAlJXW0Y96bE
    OmG/4EFAN2JVA93U5JdzdRL+A6G4tL1JrDUJht2Njl03rAqcqEF2Esry2rYy5e6C
    Sxf9f7kCgYEA4m8O9inj16giGig4hUj8RHk9Fa/e0hEY/2EFKfJdcxq0oDpSHnSH
    T36I8Fks0LPBDETJNV8HJlMG6+Ul1lJpjx5N2S//f5Ypolp/3xbVkdAXZTINZG8B
    HKRCzCUN6anVsxLcx+Ja1hy7aNbNOtOki+GLlz53XQ/xFiBYcmqXH5E=
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key
    ```

3. (CLC+UFS+MC) Install Wildcard Site SSL Certificate


    ```bash
    cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt
    -----BEGIN CERTIFICATE-----
    MIIFeTCCBGGgAwIBAgIKHMDJeAADAAAAcDANBgkqhkiG9w0BAQUFADBEMRMwEQYK
    CZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAUBgNVBAMT
    DWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE3MjEzOTA3WhcNMTcwNDE2MjEzOTA3WjCB
    ljELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExEjAQBgNVBAcTCVBh
    bG8gQWx0bzEYMBYGA1UEChMPSGV3bGV0dC1QYWNrYXJkMSIwIAYDVQQLExlFeGVj
    dXRpdmUgQnJpZWZpbmcgQ2VudGVyMSAwHgYDVQQDDBcqLmhwLXBhbDIwYS0xLmhw
    Y2NjLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL7m0ikfKX5o
    CtFOjbgPGMpja109ZudT3UaMzULtdXL8jjsjNOvDaCdqevSHly+D7liYs3ABrRQN
    xWzuczFK07sGP73yZWJJIAgPGHRBg9VXTr3yqnHl7vAaJbbQpoTylAdZhiAEF5ig
    dxwydKbN6yZ4jhsaj7Mrw6CVFjI3iMhMpJuYyO/YYI7VhfZDx0qF/DcelAbgKF7/
    +B77jsJ7LXlQ9gxvdXE2w1ywdaYTDgciMFlnqyQf0ZFIIHPMWuVd/BwU0mKvuLOs
    Qq+nlNZB48kSUuVVZh+jsApqdrE+qGCm+OFcP3B2q4CKKIjerY6IQZZeavLmg4UN
    2qGARBdBiwsCAwEAAaOCAhgwggIUMB0GA1UdDgQWBBQv6vCxpW14sawNAvvzN1s4
    ihboBTAfBgNVHSMEGDAWgBTvMVRJeUYla67RivTrvmHTbgzUbTCByQYDVR0fBIHB
    MIG+MIG7oIG4oIG1hoGybGRhcDovLy9DTj1ocGNjYy1EQzFBLUNBKDMpLENOPURD
    MUEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
    LENOPUNvbmZpZ3VyYXRpb24sREM9aHBjY2MsREM9Y29tP2NlcnRpZmljYXRlUmV2
    b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2lu
    dDCBvQYIKwYBBQUHAQEEgbAwga0wgaoGCCsGAQUFBzAChoGdbGRhcDovLy9DTj1o
    cGNjYy1EQzFBLUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxD
    Tj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWhwY2NjLERDPWNvbT9jQUNl
    cnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0
    eTAhBgkrBgEEAYI3FAIEFB4SAFcAZQBiAFMAZQByAHYAZQByMA4GA1UdDwEB/wQE
    AwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATANBgkqhkiG9w0BAQUFAAOCAQEAd1r/
    2koqygZF0CJdEhyI3BhSthF+vaKqesNBlOgct5gY39nO8yXVjqwUONy9lG0qJ0zW
    untXK395/ifwq2C3nHEXQKQt1pQ45qLKJhA+9DpFrnNcunSbDv9uVSa1Or9cDsoF
    tBIy2x+omkr7gE6QQUBlnl0Bolxc6QYrpNfzuNuDbngELOKi4UlpaZmPCAe0RN0f
    T0wNO/GNebzwg4zEf0uegQO0OMLOtEEWfrPKrXEEAMRZBkDIqv2qUY6DbdCC1dLX
    JhwqRwLbQRtYdjV2xQQ8yYdAtsMtKH7v8vMT+IYVVfj/UyrviveXuwOMjW/RfSlp
    Os/7sQZddG9kdBx8KA==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt
    ```

### Configure Management Console for SSL

1. Confirm Eucalyptus Console service on default port

    ```bash
    Browse: http://console.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN:8888
    ```

2. Stop Eucalyptus Console service

    ```bash
    service eucaconsole stop
    ```

3. Install Nginx package

    ```bash
    yum install -y nginx
    ```

4. Configure Nginx

    ```bash
    \cp /usr/share/doc/eucaconsole-4.*/nginx.conf /etc/nginx/nginx.conf

    sed -i -e "s/# \(listen 443 ssl;$\)/\1/" \
           -e "s/# \(ssl_certificate\)/\1/" \
           -e "s/\/path\/to\/ssl\/pem_file/\/etc\/pki\/tls\/certs\/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt/" \
           -e "s/\/path\/to\/ssl\/certificate_key/\/etc\/pki\/tls\/private\/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key/" /etc/nginx/nginx.conf
    ```

7. Start Nginx service

    ```bash
    chkconfig nginx on
    service nginx start
    ```

8. Configure Eucalyptus Console for SSL

    ```bash
    sed -i -e '/^session.secure =/s/= .*$/= true/' \
           -e '/^session.secure/a\
    sslcert=/etc/eucaconsole/console.crt\
    sslkey=/etc/eucaconsole/console.key' /etc/eucaconsole/console.ini
    ```

9. Start Eucalyptus Console service

    ```bash
    service eucaconsole start
    ```

10. Confirm Eucalyptus Console service

    ```bash
    Browse: https://console.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN
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

### Transfer Eucalyptus and Demo Account credentials and private keys to management workstation

The Eucalyptus Administrator and Demo Account Administrator `admin.zip` file and contents of the
associated `admin` directory must be moved to at least one alternate location for backup. Ideally,
this will be an alternate host used as a management workstation.

Eucalyptus Euca2ools currently runs on UNIX-based hosts, but in the EBC, we initially do not have
a separate UNIX workstation built for this purpose, so we will preserve the credentials on the
Windows Jump Host in the admin account. This was done manually via Putty's SFTP client.

The credentials are stored under C:\Users\admin\Credentials\<account>\<user>.zip and
C:\Users\admin\Credentials\<account>\<user>\

In the future, these instructions will be updated to show how the AWS CLI client can be modified
to reference this additional "region", allowing their use from Windows for most Eucalyptus cloud
management operations.

