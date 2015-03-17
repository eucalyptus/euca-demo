# Un-Install Procedure

This document describes the manual procedure to un-install Eucalyptus.

Initially this will be rough notes based on the nuke.rb Chef recipe.

Each step uses a code to indicate what node the step should be run on:
- MW:  Management Workstation
- CLC: Cloud Controller Host
- UFS: User-Facing Services Host
- MC:  Management Console Host
- OSP: Object Storage Provider (Walrus)
- CC:  Cluster Controller Host
- SC:  Storage Controller Host
- NCn: Node Controller(s)


### Uninstall Eucalyptus

1. (NC): Stop services

    ```bash
    service eucalyptus-nc stop

    service eucanetd stop
    eucanetd -F
    ```

2. (CC) Stop services

    ```bash
    service eucalyptus-cc stop
    ```

3. (MC) Stop services

    ```bash
    service eucaconsole stop
    ```

4. (CLC/UFS/OSP/SC): Stop services

    ```bash
    service eucalyptus-cloud stop
    ```

5. (NC) Destroy all running Virtual Machines

    ```bash
    virsh list | grep 'running$' | sed -re 's/^\\s*[0-9-]+\\s+(.*?[^ ])\\s+running$/\"\\1\"/' | xargs -r -n 1 -P 1 virsh destroy
    ```

6. (ALL) Remove packages

    ```bash
    yum remove -y euca2ools python-eucadmin.noarch python-requestbuilder

    yum remove -y 'euca*'
    ```

7. (ALL) Remove repository control files which may have been created outside of RPMs

    ```bash
    rm -f /etc/yum.repos.d/eucalyptus.repo*
    rm -f /etc/yum.repos.d/enterprise.repo*
    rm -f /etc/yum.repos.d/euca2ools.repo*

    rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-eucalyptus-release
    rm -f /etc/pki/rpm-gpg/RPM-GPG-KEY-euca2ools-release
    ```

8. (SC) Remove devmapper and losetup entries

    ```bash
    if which tgtadm && tgtadm --lld iscsi -m target -o show; then 
        tgtadm --lld iscsi -m target -o delete -t $export --force;
    fi
    ```

9. (SC) Remove Logical Volumes

    ```bash
    for vol in $(lvdisplay | grep /dev | grep euca-vol- | awk '{print $3}'); do
        lvremove -f $vol;
    done
    ```

10. (ALL) Remove file system artifacts

    ```bash
    rm -Rf /etc/init.d/euca*

    rm -Rf /usr/share/eucalyptus

    rm -Rf /etc/eucalyptus

    rm -Rf /etc/euca2ools

    rm -Rf /var/log/eucalyptus

    rm -Rf /var/run/eucalyptus

    rm -Rf /tmp/*release*

    rm -Rf /var/chef/cache
    ```

11. (ALL) Remove devmapper and losetup entries

    ```bash
    dmsetup table | grep euca | cut -d':' -f 1 | sort | uniq | xargs -L 1 dmsetup remove
    losetup -a | cut -d':' -f 1 | xargs -L 1 losetup -d
    losetup -a | grep euca
    ```

12. (CC) Clean iscsi sessions

    ```bash
    iscsiadm -m session -u
    ```

13. (ALL) Delete tgtdadm Eucalyptus account

    ```bash
    if tgtadm --mode account --op show | grep eucalyptus; then
        tgtadm --mode account --op delete --user eucalyptus
    fi
    ```

14. (ALL) Clean up yum

    ```bash
    rm -Rf /var/cache/yum/x86_64/6/euca*

    yum clean all
    ```

