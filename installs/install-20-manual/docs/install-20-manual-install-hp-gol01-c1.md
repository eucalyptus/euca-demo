# Install Procedure for region hp-gol01-c1
## 2-Node (1+1) POC

This document describes the manual procedure to setup region **hp-gol01-c1**,
with 1 cloud/cluster-level control node for CLC+UFS+MC+OSP+CC+SC, and 1 NC.
There is an option to install a second NC.

This variant is meant to be run as root

This POC will use **hp-gol01-c1** as the AWS_DEFAULT_REGION.

The full parent DNS domain will be **hp-gol01-c1.mjc.prc.eucalyptus-systems.com**.

This is using the following nodes in the PRC:
- odc-c-21.prc.eucalyptus-systems.com: CLC+UFS+MC+OSP+CC+SC
  - Public: 10.104.10.21/16 (em1)
  - Private: 10.105.10.21/16 (em2)
- odc-c-23.prc.eucalyptus-systems.com: NC1
  - Public: 10.104.10.23/16 (em1)
  - Private: 10.105.10.23/16 (em2)
- odc-c-37.prc.eucalyptus-systems.com: NC2 (optional)
  - Public: 10.104.10.37/16 (em1)
  - Private: 10.105.10.37/16 (em2)

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
    export AWS_DEFAULT_REGION=hp-gol01-c1

    export EUCA_DNS_PUBLIC_DOMAIN=mjc.prc.eucalyptus-systems.com
    export EUCA_DNS_PRIVATE_DOMAIN=internal
    export EUCA_DNS_INSTANCE_SUBDOMAIN=cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
    export EUCA_DNS_PARENT_HOST=ns1.mjc.prc.eucalyptus-systems.com
    export EUCA_DNS_PARENT_IP=10.104.10.80

    export EUCA_SERVICE_API_NAME=api

    export EUCA_PUBLIC_IP_RANGE=10.104.44.1-10.104.44.254

    export EUCA_CLUSTER1=${AWS_DEFAULT_REGION}a
    export EUCA_CLUSTER1_CC_NAME=${EUCA_CLUSTER1}-cc
    export EUCA_CLUSTER1_SC_NAME=${EUCA_CLUSTER1}-sc

    export EUCA_CLUSTER1_PRIVATE_IP_RANGE=10.105.44.1-10.105.44.254
    export EUCA_CLUSTER1_PRIVATE_NAME=10.105.0.0
    export EUCA_CLUSTER1_PRIVATE_SUBNET=10.105.0.0
    export EUCA_CLUSTER1_PRIVATE_NETMASK=255.255.0.0
    export EUCA_CLUSTER1_PRIVATE_GATEWAY=10.105.0.1

    export EUCA_CLC_PUBLIC_INTERFACE=em1
    export EUCA_CLC_PRIVATE_INTERFACE=em2
    export EUCA_CLC_PUBLIC_IP=10.104.10.21
    export EUCA_CLC_PRIVATE_IP=10.105.10.21

    export EUCA_UFS_PUBLIC_INTERFACE=em1
    export EUCA_UFS_PRIVATE_INTERFACE=em2
    export EUCA_UFS_PUBLIC_IP=10.104.10.21
    export EUCA_UFS_PRIVATE_IP=10.105.10.21

    export EUCA_MC_PUBLIC_INTERFACE=em1
    export EUCA_MC_PRIVATE_INTERFACE=em2
    export EUCA_MC_PUBLIC_IP=10.104.10.21
    export EUCA_MC_PRIVATE_IP=10.105.10.21

    export EUCA_OSP_PUBLIC_INTERFACE=em1
    export EUCA_OSP_PRIVATE_INTERFACE=em2
    export EUCA_OSP_PUBLIC_IP=10.104.10.21
    export EUCA_OSP_PRIVATE_IP=10.105.10.21

    export EUCA_CC_PUBLIC_INTERFACE=em1
    export EUCA_CC_PRIVATE_INTERFACE=em2
    export EUCA_CC_PUBLIC_IP=10.104.10.21
    export EUCA_CC_PRIVATE_IP=10.105.10.21

    export EUCA_SC_PUBLIC_INTERFACE=em1
    export EUCA_SC_PRIVATE_INTERFACE=em2
    export EUCA_SC_PUBLIC_IP=10.104.10.21
    export EUCA_SC_PRIVATE_IP=10.105.10.21

    export EUCA_NC_PRIVATE_BRIDGE=br0
    export EUCA_NC_PRIVATE_INTERFACE=em2
    export EUCA_NC_PUBLIC_INTERFACE=em1

    export EUCA_NC1_PUBLIC_IP=10.104.10.23
    export EUCA_NC1_PRIVATE_IP=10.105.10.23

    export EUCA_NC1_PUBLIC_IP=10.104.10.37
    export EUCA_NC1_PRIVATE_IP=10.105.10.37
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
10.104.10.80

dig +short ${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.21

dig +short ns1.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.21

dig +short clc.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.21

dig +short ufs.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.21

dig +short console.${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
10.104.10.21
```

**NS Records**

```bash
dig +short -t NS ${EUCA_DNS_PUBLIC_DOMAIN}
ns1.mjc.prc.eucalyptus-systems.com.

dig +short -t NS ${AWS_DEFAULT_REGION}.${EUCA_DNS_PUBLIC_DOMAIN}
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
    
2. (CLC+UFS+OSP+SC)  Configure additional disk storage for the Storage Controller

    With a combined FE host, using the second disk as the LVM for EBS storage.

    ```bash
    pvcreate -Z y /dev/sdb

    pvscan

    vgcreate eucalyptus /dev/sdb
    ```

3. (NC)  Configure additional disk storage for the Node Controller

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

4. (ALL): Confirm storage

    ```bash
    df -h

    pvscan

    lvscan
    ```

5. (ALL): Disable zero-conf network

    ```bash
    sed -i -e '/NOZEROCONF=/d' -e '$a\NOZEROCONF=yes' /etc/sysconfig/network
    ```

6. (NC): Install bridge utilities package

    ```bash
    yum install -y bridge-utils
    ```

7. (NC): Create Private Bridge

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

8. (NC): Convert Private Ethernet Interface to Private Bridge Slave

    ```bash
    sed -i -e "\$aBRIDGE=${EUCA_NC_PRIVATE_BRIDGE}" \
           -e "/^BOOTPROTO=/s/=.*$/=none/" \
           -e "/^IPADDR=/d" \
           -e "/^NETMASK=/d" \
           -e "/^PERSISTENT_DHCLIENT=/d" \
           -e "/^DNS.=/d" /etc/sysconfig/network-scripts/ifcfg-${EUCA_NC_PRIVATE_INTERFACE}
    ```

9. (ALL): Restart networking

    ```bash
    service network restart
    ```

10. (ALL): Confirm networking

    ```bash
    ip addr | grep " inet "
    netstat -nr
    ```

11. (CLC+UFS+MC+): Disable firewall

    ```bash
    I will come back to this later, to nail down what ports are needed for a combined FE.
    Until then, just disabling IPtables

    chkconfig iptables off
    service iptables stop
    ```

12. (NC): Configure firewall, but disable during installation

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

    chkconfig iptables off
    service iptables stop
    ```

13. (ALL): Disable SELinux

    ```bash
    sed -i -e "/^SELINUX=/s/=.*$/=permissive/" /etc/selinux/config

    setenforce 0
    ```

14. (ALL): Install and Configure the NTP service

    ```bash
    yum install -y ntp

    chkconfig ntpd on
    service ntpd start

    ntpdate -u  0.centos.pool.ntp.org
    hwclock --systohc
    ```

15. (ALL) Install and Configure Mail Relay

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

16. (ALL) Install Email test client and test email

    Sending to personal email address on Google Apps - Please update to use your own email address!

    Confirm email is sent to relay by tailing /var/log/maillog on this host and on mail relay host.

    ```bash
    yum install -y mutt

    echo "test" | mutt -x -s "Test from $(hostname -s) on $(date)" michael.crawford@mjcconsulting.com
    ````

17. (CC): Configure packet routing

    Note that while this is not required when using EDGE mode, as the CC no longer routes traffic,
    you will get a warning when starting the CC if this routing has not been configured, and the
    package would turn this on at that time. So, this is to prevent that warning.

    ```bash
    sed -i -e '/^net.ipv4.ip_forward = 0/s/=.*$/= 1/' /etc/sysctl.conf

    sysctl -p

    cat /proc/sys/net/ipv4/ip_forward
    ```

18. (NC): Configure packet routing

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

2. (CLC+UFS/OSP/SC): Run tomography tool

    This tool should be run simultaneously on all hosts running Java components.

    ```bash
    yum install -y java

    mkdir -p ~/src/eucalyptus
    cd ~/src/eucalyptus
    git clone https://github.com/eucalyptus/deveutils

    cd deveutils/network-tomography
    ./network-tomography ${EUCA_CLC_PRIVATE_IP}
    ```

3. (CLC): Scan for unknown SSH host keys

    ```bash
    ssh-keyscan ${EUCA_CLC_PUBLIC_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ssh-keyscan ${EUCA_CLC_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts

    ssh-keyscan ${EUCA_NC1_PRIVATE_IP} 2> /dev/null >> /root/.ssh/known_hosts
    ```

### Install Eucalyptus

1. (ALL): Configure yum repositories

   This first set of packages is required to configure access to the Eucalyptus yum repositories
   which contain open source Eucalyptus software, and their dependencies.

    ```bash
    yum install -y \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
        http://downloads.eucalyptus.com/software/eucalyptus/4.1/centos/6Server/x86_64/eucalyptus-release-4.1-1.el6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.2/centos/6Server/x86_64/euca2ools-release-3.2-1.el6.noarch.rpm
    ```

    Optional: This second set of packages is required to configure access to the Eucalyptus yum
    repositories which contain subscription-only Eucalyptus software, which requires a license.

    ```bash
    yum install -y http://mirror.mjc.prc.eucalyptus-systems.com/downloads/eucalyptus/licenses/eucalyptus-enterprise-license-1-1.151702164410-Euca_HP_SalesEng.noarch.rpm
    yum install -y http://subscription.eucalyptus.com/eucalyptus-enterprise-release-4.1-1.el6.noarch.rpm
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

5. (SC+CC): Install packages

    ```bash
    yum install -y eucalyptus-cloud eucalyptus-sc eucalyptus-cc
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

3. (SC+CC): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_CC_PRIVATE_INTERFACE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_CC_PUBLIC_INTERFACE}\"/" \
           -e "s/^CLOUD_OPTS=.*$/CLOUD_OPTS=\"--bind-addr=${EUCA_CC_PRIVATE_IP}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

4. (NC): Configure Eucalyptus Networking

    ```bash
    cp -a /etc/eucalyptus/eucalyptus.conf /etc/eucalyptus/eucalyptus.conf.orig

    sed -i -e "s/^VNET_MODE=.*$/VNET_MODE=\"EDGE\"/" \
           -e "s/^VNET_PRIVINTERFACE=.*$/VNET_PRIVINTERFACE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" \
           -e "s/^VNET_PUBINTERFACE=.*$/VNET_PUBINTERFACE=\"${EUCA_NC_PUBLIC_INTERFACE}\"/" \
           -e "s/^VNET_BRIDGE=.*$/VNET_BRIDGE=\"${EUCA_NC_PRIVATE_BRIDGE}\"/" /etc/eucalyptus/eucalyptus.conf
    ```

5. (CLC): Create Eucalyptus EDGE Networking configuration file

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

6. (NC): Configure Eucalyptus Disk Allocation

    ```bash
    nc_work_size=2400000
    nc_cache_size=300000

    sed -i -e "s/^#NC_WORK_SIZE=.*$/NC_WORK_SIZE=\"$nc_work_size\"/" \
           -e "s/^#NC_CACHE_SIZE=.*$/NC_CACHE_SIZE=\"$nc_cache_size\"/" /etc/eucalyptus/eucalyptus.conf
    ```

7. (NC): Configure Eucalyptus to use Private IP for Metadata

    ```bash
    cat << EOF >> /etc/eucalyptus/eucalyptus.conf

    # Set this to Y to use the private IP of the CLC for the metadata service.
    # The default is to use the public IP.
    METADATA_USE_VM_PRIVATE="Y"
    EOF
    ```

8. (CLC/OSP/SC): Configure Eucalyptus Java Memory Allocation

    This has proven risky to run, frequently causing failure to start due to incorrect heap size,
    regardless of value

    ```bash
    heap_mem_mb=$(($(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 4))
    sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xms=${heap_mem_mb}M -Xmx=${heap_mem_mb}M\"/" /etc/eucalyptus/eucalyptus.conf

    # Alternate method
    # sed -i -e "/^CLOUD_OPTS=/s/\"$/ -Xmx=2G\"/" /etc/eucalyptus/eucalyptus.conf
    ```

10. (MC): Configure Management Console with Cloud Controller and Walrus addresses

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

2. (CLC/OSP/SC): Start the Cloud Controller service

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
    euca_conf --register-nodes="${EUCA_NC1_PRIVATE_IP} ${EUCA_NC2_PRIVATE_IP}"
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
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    euca_conf --get-credentials ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip

    unzip ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/

    cp -a ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc.orig

    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. (CLC): Confirm initial service status

    * All services should be in the ENABLED state except, for objectstorage, loadbalancingbackend,
      imagingbackend, and storage.
    * All nodes should be in the ENABLED state.

    ````bash
    euca-describe-services | cut -f1-5

    euca-describe-regions

    euca-describe-availability-zones verbose

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

    euca-describe-availability-zones verbose

    euca-describe-nodes

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
    cat << EOF > /etc/pki/tls/private/star.${EUCA_DNS_PUBLIC_DOMAIN#*.}.key
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

    chmod 400 /etc/pki/tls/private/star.${EUCA_DNS_PUBLIC_DOMAIN#*.}.key
    ```

3. (ALL) Install Wildcard Host SSL Certificate

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.${EUCA_DNS_PUBLIC_DOMAIN#*.}.crt
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

    chmod 444 /etc/pki/tls/certs/star.${EUCA_DNS_PUBLIC_DOMAIN#*.}.crt
    ```

4. (CLC+UFS+MC) Install Wildcard Site SSL Key

    ```bash
    cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEAlT988/QgoUxGTr+6FN3t6eMdI1BoDMBSbTTlAgGkHFODkFJu
    f/yQOXWzMPHlCW28OxgSJP7tqwgmZeJ6GxlV9VxXlJiutRBOGcW/g3RIV6DpaLD2
    a7XqVV4NG93/3qyt/Lvn4my3teKHjgmoZVFEVa7BC1fDMNzfFh3JTaYZ44/wzqsM
    +jG8hkkSBO4jDul2l1+9wdo/xsaEkftHlKw1Qp/ExuKdinzU08GRV6NZbEAmX4Rh
    2PPWCX/KpZebOO3dUxHnlV0DEUd493Oa979oRCKs3gvXQKwUhbz5mWSfrmZGSdM/
    uxmPa34BRF7MEK8gJ+NAarRHBJjTj4iWjSspEwIDAQABAoIBAGOpcJQrGjr7hxuA
    9g6HIB8FtOhnAgQ5zRD1uFL9q4vqzLjsArPegKSODymI7iu8pmxDp6IixaxnFdUF
    RgqggYEFt8oXptpr1+tn3Ho4hTJW1mY9fV/xq1h0JIbOWNVmNAzHoZHWjVqcuW5E
    zrlRajNZLbmYUlRnuWS4YTtDxpfo+ongXxxPc7HLK0J7hM/c4ti8Chk8iO5wcvs0
    vqD1iSWTVlru4K/Vl+u6s8EF7kCHORS+R95dKiVWB4se0O74zPHyDJsZgf/vRU0U
    CBAGeJ51xbId9aB0TEboXdzKi134GyZbNlaK/ESiLRrxBQZikydPrR0OyYYdmGp+
    DjCCEukCgYEAxt/uluhyhzr6RN1DgOV4dxClMEM9Fw91hR1LiPDKLEdWpD+wXdyg
    7fBOOC8WPODBCmynvv5Op1Uuxewz6PzvSDmrLY8LcCagqVS2/7j7AzzAhVO5y20q
    OJkFLul2JvmvDOakvmPwTylHBLwjpgMuQ3Dwd7GY3I2J9n7f9fG7cpUCgYEAwB5M
    79sbhalgowQMj7cv4BAh/Of7DSuHrCcCk8f9+/ohY/k0lELxS7A+nchg2GSxV76R
    wawd2kvXCRrO3jsqVS5fWNNKh8C4LWv20lxSkU44i3ElO7QYSRKmP/d9CIv7R12Q
    V9Ue4W/5bQPhjhNPAInvne2kzF217XYT75qcKwcCgYEArIUN4HN9Brqu6JZZPLPT
    sNYLtrZdhGewtu0W3ZCkkYzBKHLneEUwhbh04mBWljESxQxE6HaLnLVUgfXJglAI
    80qzqC3y6jNYJAyNQ4Egn0pQaFidUE8+1SJJUMzN5jmrFTHvsAnaKZHRPdZHxnfz
    5iVPNUYnKQzPpbmiZyRwS5ECgYBefgjFaHVO9pILW/B5t1Ya1JSC+e6m+aQPblh8
    Kz+m8c3+iBHuYkagPZ1uqaHIjS4UxCyYn3lHZ0nqtn7NGzilENvgqnvb7VQpMxMB
    QFt0EI8LNqljhh7zwfJ3P9kFnSQIY+Kc8LvxkcuSbPhBkwmmcDGk8b++rNDQbOU9
    UkRBfQKBgEwRBRJ4xPWT54S/49pWAyS0QPOV4+hnByTrxNJghLozcS5OjKEOx8af
    TLGKFHYGWmj88zH4N7PK2pfYCYUD9UMoxvnxXAuIaJodHYrPnZIlkVwPZgWi4mPM
    cdV0FcwVZz34AhT+Jfglud6x8fYipNUi7KIsV9JOeaYces90xVbp
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key
    ```

5. (CLC+UFS+MC) Install Wildcard Site SSL Certificate


    ```bash
    cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt
    -----BEGIN CERTIFICATE-----
    MIIFuDCCA6CgAwIBAgIBBDANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjEwNDQwMTBaFw0x
    ODA0MjAwNDQwMTBaMIGbMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEYMBYGA1UECgwPSGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVj
    YWx5cHR1cyBEZXZlbG9wbWVudDE1MDMGA1UEAwwsKi5ocC1nb2wwMS1jMS5tamMu
    cHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQCVP3zz9CChTEZOv7oU3e3p4x0jUGgMwFJtNOUCAaQcU4OQUm5/
    /JA5dbMw8eUJbbw7GBIk/u2rCCZl4nobGVX1XFeUmK61EE4Zxb+DdEhXoOlosPZr
    tepVXg0b3f/erK38u+fibLe14oeOCahlUURVrsELV8Mw3N8WHclNphnjj/DOqwz6
    MbyGSRIE7iMO6XaXX73B2j/GxoSR+0eUrDVCn8TG4p2KfNTTwZFXo1lsQCZfhGHY
    89YJf8qll5s47d1TEeeVXQMRR3j3c5r3v2hEIqzeC9dArBSFvPmZZJ+uZkZJ0z+7
    GY9rfgFEXswQryAn40BqtEcEmNOPiJaNKykTAgMBAAGjgeUwgeIwDAYDVR0TAQH/
    BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQD
    AgWgMB8GA1UdIwQYMBaAFDZChTaQujqm5C4FWaBQExPk0ttYMGMGA1UdEQRcMFqC
    LCouaHAtZ29sMDEtYzEubWpjLnByYy5ldWNhbHlwdHVzLXN5c3RlbXMuY29tgipo
    cC1nb2wwMS1jMS5tamMucHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wHQYDVR0O
    BBYEFPEJGqrsRlFe+S2dZEXwx5znoLkUMA0GCSqGSIb3DQEBCwUAA4ICAQAphetg
    LRyJzryEYBCMBH54sSjOxeJFdTq56L5xajZydYv/IfIcYwPDmXA68diq57Brb3pj
    mE7MFTGMfQI0KH5Fszj5DV/b0wdcwjYoI2SiwutvVRo5CGLM5P+I62xqx+b2nMfv
    tYxuXcLGozuAQoNX7b7OflUWEhtwyQ0E2MdKovNQL08mgUMfD7AUoIuYTshPQ0ea
    GKymPqRvYcSz2e0AlDzpi70xwCr5gtMYglMaZ6IM/KI5E4DKMazKRXk/mgB6BhqF
    DxCt7HE99/vuFotrKJnfo9e7X6WJH9AyaFeWbHUSd2kSD2pQ+b6Chz6wl0IRnB/P
    icLOFqJq8Dam6H93dz0ROSW6hYlyxWBCbyIOiX7Z8y8oxduOXZ4Axnkxji8EgVK4
    xWD/KI8eXCCtANRf7gLPVNRKSIR/mSCDwvRsP4BK803UVXzi4S4w8vaaY9WU3hoB
    a03ExcLqC0Ij/JuQM6LBq73e56ctHSoCjeR3Jt6ApheZsq+V/6gxerm2CeyRgaDo
    vgRDZ6Q4rVY3rgHKKahSAJXD2QFqRsFydHt7WWBPQHijw0qNvdRNOtOBn97AI8bA
    XXE4khUKilpN4p3gTLh32Jl6rPCD7Nu3QeeyJrYz3bw0F0/H5PoIDbBtNQIcQgoY
    jlEd8vTU+laznroM1lgYzCzmOU5RwBbJqXuatg==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt
    ```

### Configure Management Console for SSL

1. (MW): Confirm Eucalyptus Console service on default port

    ```bash
    Browse: http://console.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN:8888
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
           -e "s/\/path\/to\/ssl\/pem_file/\/etc\/pki\/tls\/certs\/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.crt/" \
           -e "s/\/path\/to\/ssl\/certificate_key/\/etc\/pki\/tls\/private\/star.$AWS_DEFAULT_REGION.$EUCA_DNS_PUBLIC_DOMAIN.key/" /etc/nginx/nginx.conf
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
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from CLC to SC:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from CLC to OSP:8773 failed!'
    nc -z ${EUCA_CC_PUBLIC_IP} 8774 || echo 'Connection from CLC to CC:8774 failed!'
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
    nc -z ${EUCA_NC1_PRIVATE_IP} 8775 || echo 'Connection from CC to NCA1:8775 failed!'
    nc -z ${EUCA_NC2_PRIVATE_IP} 8775 || echo 'Connection from CC to NCA2:8775 failed!'
    ```

6. (SC): Verify Connectivity

    ```bash
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from SC to SC:8773 failed!'
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from SC to OSP:8773 failed!'
    nc -z ${EUCA_CLC_PUBLIC_IP} 8777 || echo 'Connection from SC to CLC:8777 failed!'
    ```

7. (NC): Verify Connectivity

    ```bash
    nc -z ${EUCA_OSP_PUBLIC_IP} 8773 || echo 'Connection from NC to OSP:8773 failed!'
    nc -z ${EUCA_SC_PUBLIC_IP} 8773 || echo 'Connection from NC to SC:8773 failed!'
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

