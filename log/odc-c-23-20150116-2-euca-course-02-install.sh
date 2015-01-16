[root@odc-c-23 bin]# euca-course-02-install.sh 

============================================================

 1. Configure yum repositories
    - Install the required release RPMs for ELREPO, EPEL,
      Eucalyptus and Euca2ools

============================================================

Commands:

yum install -y \
    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/eucalyptus-release-4.0-1.el6.noarch.rpm \
    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
    http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/elrepo-release-6-6.el6.elrepo.noarch.rpm \
    http://downloads.eucalyptus.com/software/euca2ools/3.1/centos/6Server/x86_64/euca2ools-release-3.1-1.el6.noarch.rpm

Execute (y,n,q)[y]

# yum install -y \
>     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/eucalyptus-release-4.0-1.el6.noarch.rpm \
>     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/epel-release-6-8.noarch.rpm \
>     http://downloads.eucalyptus.com/software/eucalyptus/4.0/centos/6Server/x86_64/elrepo-release-6-6.el6.elrepo.noarch.rpm \
>     http://downloads.eucalyptus.com/software/euca2ools/3.1/centos/6Server/x86_64/euca2ools-release-3.1-1.el6.noarch.rpm
Loaded plugins: fastestmirror, security
Setting up Install Process
eucalyptus-release-4.0-1.el6.noarch.rpm                                                                                                                                   | 5.2 kB     00:00     
Examining /var/tmp/yum-root-lFLGxS/eucalyptus-release-4.0-1.el6.noarch.rpm: eucalyptus-release-4.0-1.el6.noarch
Marking /var/tmp/yum-root-lFLGxS/eucalyptus-release-4.0-1.el6.noarch.rpm to be installed
Loading mirror speeds from cached hostfile
 * extras: mirror.spro.net
epel-release-6-8.noarch.rpm                                                                                                                                               |  14 kB     00:00     
Examining /var/tmp/yum-root-lFLGxS/epel-release-6-8.noarch.rpm: epel-release-6-8.noarch
/var/tmp/yum-root-lFLGxS/epel-release-6-8.noarch.rpm: does not update installed package.
elrepo-release-6-6.el6.elrepo.noarch.rpm                                                                                                                                  | 8.2 kB     00:00     
Examining /var/tmp/yum-root-lFLGxS/elrepo-release-6-6.el6.elrepo.noarch.rpm: elrepo-release-6-6.el6.elrepo.noarch
/var/tmp/yum-root-lFLGxS/elrepo-release-6-6.el6.elrepo.noarch.rpm: does not update installed package.
euca2ools-release-3.1-1.el6.noarch.rpm                                                                                                                                    | 5.2 kB     00:00     
Examining /var/tmp/yum-root-lFLGxS/euca2ools-release-3.1-1.el6.noarch.rpm: euca2ools-release-3.1-1.el6.noarch
Marking /var/tmp/yum-root-lFLGxS/euca2ools-release-3.1-1.el6.noarch.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package euca2ools-release.noarch 0:3.1-1.el6 will be installed
---> Package eucalyptus-release.noarch 0:4.0-1.el6 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=================================================================================================================================================================================================
 Package                                        Arch                               Version                                Repository                                                        Size
=================================================================================================================================================================================================
Installing:
 euca2ools-release                              noarch                             3.1-1.el6                              /euca2ools-release-3.1-1.el6.noarch                              1.9 k
 eucalyptus-release                             noarch                             4.0-1.el6                              /eucalyptus-release-4.0-1.el6.noarch                             1.9 k

Transaction Summary
=================================================================================================================================================================================================
Install       2 Package(s)

Total size: 3.8 k
Installed size: 3.8 k
Downloading Packages:
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : eucalyptus-release-4.0-1.el6.noarch                                                                                                                                           1/2 
  Installing : euca2ools-release-3.1-1.el6.noarch                                                                                                                                            2/2 
  Verifying  : euca2ools-release-3.1-1.el6.noarch                                                                                                                                            1/2 
  Verifying  : eucalyptus-release-4.0-1.el6.noarch                                                                                                                                           2/2 

Installed:
  euca2ools-release.noarch 0:3.1-1.el6                                                           eucalyptus-release.noarch 0:4.0-1.el6                                                          

Complete!

Continue (y,n,q)[y]

============================================================

 2. Install packages

============================================================

Commands:

yum install -y eucalyptus-nc

Execute (y,n,q)[y]

# yum install -y eucalyptus-nc
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: mirror.spro.net
euca2ools                                                                                                                                                                 | 1.5 kB     00:00     
euca2ools/primary                                                                                                                                                         | 4.3 kB     00:00     
euca2ools                                                                                                                                                                                    8/8
eucalyptus                                                                                                                                                                | 1.5 kB     00:00     
eucalyptus/primary                                                                                                                                                        |  36 kB     00:00     
eucalyptus                                                                                                                                                                               122/122
Resolving Dependencies
--> Running transaction check
---> Package eucalyptus-nc.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: eucalyptus-imaging-toolkit = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: eucalyptus-blockdev-utils = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: eucalyptus-axis2c-common = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: eucalyptus = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: euca2ools >= 3.0.2 for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(XML::Simple) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(Time::HiRes) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(Sys::Virt) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.1.2)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.0.11)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.7.3)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.3.2)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.2.1)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.1.9)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.1.0)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0(LIBVIRT_0.0.3)(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: kvm for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: iscsi-initiator-utils for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: httpd for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: device-mapper-multipath for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: /usr/sbin/euca_conf for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libxslt.so.1()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libvirt.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: librampart.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libneethi.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libmod_rampart.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libguththila.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxutil.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_parser.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_sender.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_receiver.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_common.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_engine.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_axiom.so.0()(64bit) for package: eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64
--> Running transaction check
---> Package axis2c.x86_64 0:1.6.0-0.7.el6 will be installed
---> Package device-mapper-multipath.x86_64 0:0.4.9-80.el6_6.2 will be installed
--> Processing Dependency: device-mapper-multipath-libs = 0.4.9-80.el6_6.2 for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
--> Processing Dependency: libmultipath.so()(64bit) for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
--> Processing Dependency: libmpathpersist.so.0()(64bit) for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
---> Package euca2ools.noarch 0:3.1.1-0.0.1562.15.el6 will be installed
--> Processing Dependency: python-six >= 1.4 for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-requestbuilder >= 0.2.0-0.4.pre3 for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-progressbar >= 2.3 for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-setuptools for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-requests for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-lxml for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: python-argparse for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
--> Processing Dependency: gdisk for package: euca2ools-3.1.1-0.0.1562.15.el6.noarch
---> Package eucalyptus.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
---> Package eucalyptus-admin-tools.noarch 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: python-boto >= 2.1 for package: eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch
--> Processing Dependency: m2crypto for package: eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch
--> Processing Dependency: PyGreSQL for package: eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch
---> Package eucalyptus-axis2c-common.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
---> Package eucalyptus-blockdev-utils.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: perl(Crypt::OpenSSL::Random) for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(Crypt::OpenSSL::RSA) for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libselinux-python for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
---> Package eucalyptus-imaging-toolkit.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
---> Package httpd.x86_64 0:2.2.15-39.el6.centos will be installed
--> Processing Dependency: httpd-tools = 2.2.15-39.el6.centos for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: apr-util-ldap for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: /etc/mime.types for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: libaprutil-1.so.0()(64bit) for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: libapr-1.so.0()(64bit) for package: httpd-2.2.15-39.el6.centos.x86_64
---> Package iscsi-initiator-utils.x86_64 0:6.2.0.873-13.el6 will be installed
---> Package libvirt.x86_64 0:0.10.2-46.el6_6.2 will be installed
--> Processing Dependency: dnsmasq >= 2.41 for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: radvd for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: numad for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: nfs-utils for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: lzop for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libnetcf.so.1(NETCF_1.4.0)(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libnetcf.so.1(NETCF_1.3.0)(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libnetcf.so.1(NETCF_1.2.0)(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libnetcf.so.1(NETCF_1.0.0)(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libcgroup for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: ebtables for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: /usr/bin/qemu-img for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libyajl.so.1()(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: libnetcf.so.1()(64bit) for package: libvirt-0.10.2-46.el6_6.2.x86_64
---> Package libvirt-client.x86_64 0:0.10.2-46.el6_6.2 will be installed
--> Processing Dependency: nc for package: libvirt-client-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: gnutls-utils for package: libvirt-client-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: gettext for package: libvirt-client-0.10.2-46.el6_6.2.x86_64
--> Processing Dependency: cyrus-sasl-md5 for package: libvirt-client-0.10.2-46.el6_6.2.x86_64
---> Package libxslt.x86_64 0:1.1.26-2.el6_3.1 will be installed
---> Package perl-Sys-Virt.x86_64 0:0.10.2-5.el6 will be installed
---> Package perl-Time-HiRes.x86_64 4:1.9721-136.el6_6.1 will be installed
---> Package perl-XML-Simple.noarch 0:2.18-6.el6 will be installed
--> Processing Dependency: perl(XML::Parser) for package: perl-XML-Simple-2.18-6.el6.noarch
---> Package qemu-kvm.x86_64 2:0.12.1.2-2.448.el6_6 will be installed
Midokura-local/filelists_db                                                                                                                                               |  39 kB     00:00     
centos-6-x86_64-os/filelists_db                                                                                                                                           | 6.1 MB     00:00     
centos-6-x86_64-updates/filelists_db                                                                                                                                      | 1.1 MB     00:00     
core-0/filelists                                                                                                                                                          | 3.8 MB     00:00     
elrepo-6-x86_64/filelists_db                                                                                                                                              | 105 kB     00:00     
epel-6-x86_64/filelists_db                                                                                                                                                | 9.1 MB     00:00     
euca2ools/filelists                                                                                                                                                       |  15 kB     00:00     
eucalyptus/filelists                                                                                                                                                      |  72 kB     00:00     
extras/filelists_db                                                                                                                                                       |  31 kB     00:00     
--> Processing Dependency: seabios >= 0.6.1.2-20.el6 for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: vgabios-vmware for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: vgabios-stdvga for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: vgabios-qxl for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: vgabios for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.8.3)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.8.2)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.8.1)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.6.0)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.12.4)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.11.2)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.10.4)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1(SPICE_SERVER_0.10.0)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libpulse.so.0(PULSE_0)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libpulse-simple.so.0(PULSE_0)(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: glusterfs-api for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/sgabios/sgabios.bin for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/gpxe/virtio-net.rom for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/gpxe/rtl8139.rom for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/gpxe/rtl8029.rom for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/gpxe/pcnet32.rom for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: /usr/share/gpxe/e1000-0x100e.rom for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libusbredirparser.so.1()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libspice-server.so.1()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libpulse.so.0()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libpulse-simple.so.0()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libgfxdr.so.0()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libgfrpc.so.0()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
--> Processing Dependency: libgfapi.so.0()(64bit) for package: 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64
---> Package rampartc.x86_64 0:1.3.0-0.5.el6 will be installed
--> Running transaction check
---> Package PyGreSQL.x86_64 0:3.8.1-2.el6 will be installed
--> Processing Dependency: libpq.so.5()(64bit) for package: PyGreSQL-3.8.1-2.el6.x86_64
---> Package apr.x86_64 0:1.3.9-5.el6_2 will be installed
---> Package apr-util.x86_64 0:1.3.9-3.el6_0.1 will be installed
---> Package apr-util-ldap.x86_64 0:1.3.9-3.el6_0.1 will be installed
---> Package cyrus-sasl-md5.x86_64 0:2.1.23-15.el6_6.1 will be installed
---> Package device-mapper-multipath-libs.x86_64 0:0.4.9-80.el6_6.2 will be installed
---> Package dnsmasq.x86_64 0:2.48-14.el6 will be installed
---> Package ebtables.x86_64 0:2.0.9-6.el6 will be installed
---> Package gdisk.x86_64 0:0.8.10-1.el6 will be installed
---> Package gettext.x86_64 0:0.17-18.el6 will be installed
--> Processing Dependency: libgomp.so.1(GOMP_1.0)(64bit) for package: gettext-0.17-18.el6.x86_64
--> Processing Dependency: cvs for package: gettext-0.17-18.el6.x86_64
--> Processing Dependency: libgomp.so.1()(64bit) for package: gettext-0.17-18.el6.x86_64
---> Package glusterfs-api.x86_64 0:3.6.0.29-2.el6 will be installed
--> Processing Dependency: glusterfs = 3.6.0.29-2.el6 for package: glusterfs-api-3.6.0.29-2.el6.x86_64
---> Package glusterfs-libs.x86_64 0:3.6.0.29-2.el6 will be installed
---> Package gnutls-utils.x86_64 0:2.8.5-14.el6_5 will be installed
---> Package gpxe-roms-qemu.noarch 0:0.9.7-6.12.el6 will be installed
---> Package httpd-tools.x86_64 0:2.2.15-39.el6.centos will be installed
---> Package libcgroup.x86_64 0:0.40.rc1-15.el6_6 will be installed
---> Package libselinux-python.x86_64 0:2.0.94-5.8.el6 will be installed
---> Package lzop.x86_64 0:1.02-0.9.rc1.el6 will be installed
---> Package m2crypto.x86_64 0:0.20.2-9.el6 will be installed
---> Package mailcap.noarch 0:2.1.31-2.el6 will be installed
---> Package nc.x86_64 0:1.84-22.el6 will be installed
---> Package netcf-libs.x86_64 0:0.2.4-1.el6 will be installed
--> Processing Dependency: libaugeas.so.0(AUGEAS_0.8.0)(64bit) for package: netcf-libs-0.2.4-1.el6.x86_64
--> Processing Dependency: libaugeas.so.0(AUGEAS_0.1.0)(64bit) for package: netcf-libs-0.2.4-1.el6.x86_64
--> Processing Dependency: libaugeas.so.0()(64bit) for package: netcf-libs-0.2.4-1.el6.x86_64
---> Package nfs-utils.x86_64 1:1.2.3-54.el6 will be installed
--> Processing Dependency: nfs-utils-lib >= 1.1.0-3 for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: keyutils >= 1.4-4 for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: rpcbind for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libtirpc for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libgssglue.so.1(libgssapi_CITI_2)(64bit) for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libgssglue for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libevent for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libtirpc.so.1()(64bit) for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libnfsidmap.so.0()(64bit) for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libgssglue.so.1()(64bit) for package: 1:nfs-utils-1.2.3-54.el6.x86_64
--> Processing Dependency: libevent-1.4.so.2()(64bit) for package: 1:nfs-utils-1.2.3-54.el6.x86_64
---> Package numad.x86_64 0:0.5-11.20140620git.el6 will be installed
---> Package perl-Crypt-OpenSSL-RSA.x86_64 0:0.25-10.1.el6 will be installed
--> Processing Dependency: perl(Crypt::OpenSSL::Bignum) for package: perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64
---> Package perl-Crypt-OpenSSL-Random.x86_64 0:0.04-9.1.el6 will be installed
---> Package perl-XML-Parser.x86_64 0:2.36-7.el6 will be installed
--> Processing Dependency: perl(URI::file) for package: perl-XML-Parser-2.36-7.el6.x86_64
--> Processing Dependency: perl(URI) for package: perl-XML-Parser-2.36-7.el6.x86_64
--> Processing Dependency: perl(LWP) for package: perl-XML-Parser-2.36-7.el6.x86_64
---> Package pulseaudio-libs.x86_64 0:0.9.21-17.el6 will be installed
--> Processing Dependency: libsndfile.so.1(libsndfile.so.1.0)(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libsndfile.so.1()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libasyncns.so.0()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libXtst.so.6()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libSM.so.6()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libICE.so.6()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
---> Package python-argparse.noarch 0:1.2.1-2.el6.centos will be installed
---> Package python-boto.noarch 0:2.34.0-4.el6 will be installed
--> Processing Dependency: python-rsa for package: python-boto-2.34.0-4.el6.noarch
---> Package python-lxml.x86_64 0:2.2.3-1.1.el6 will be installed
---> Package python-progressbar.noarch 0:2.3-2.el6 will be installed
---> Package python-requestbuilder.noarch 0:0.2.3-0.1.el6 will be installed
---> Package python-requests.noarch 0:1.1.0-4.el6.centos will be installed
--> Processing Dependency: python-urllib3 for package: python-requests-1.1.0-4.el6.centos.noarch
--> Processing Dependency: python-ordereddict for package: python-requests-1.1.0-4.el6.centos.noarch
--> Processing Dependency: python-chardet for package: python-requests-1.1.0-4.el6.centos.noarch
---> Package python-setuptools.noarch 0:0.6.10-3.el6 will be installed
---> Package python-six.noarch 0:1.7.3-1.el6.centos will be installed
---> Package qemu-img.x86_64 2:0.12.1.2-2.448.el6_6 will be installed
---> Package radvd.x86_64 0:1.6-1.el6 will be installed
---> Package seabios.x86_64 0:0.6.1.2-28.el6 will be installed
---> Package sgabios-bin.noarch 0:0-0.3.20110621svn.el6 will be installed
---> Package spice-server.x86_64 0:0.12.4-11.el6 will be installed
--> Processing Dependency: pixman >= 0.18 for package: spice-server-0.12.4-11.el6.x86_64
--> Processing Dependency: libpixman-1.so.0()(64bit) for package: spice-server-0.12.4-11.el6.x86_64
--> Processing Dependency: libcelt051.so.0()(64bit) for package: spice-server-0.12.4-11.el6.x86_64
---> Package usbredir.x86_64 0:0.5.1-1.el6 will be installed
---> Package vgabios.noarch 0:0.6b-3.7.el6 will be installed
---> Package yajl.x86_64 0:1.0.7-3.el6 will be installed
--> Running transaction check
---> Package augeas-libs.x86_64 0:1.0.0-7.el6 will be installed
---> Package celt051.x86_64 0:0.5.1.3-0.el6 will be installed
--> Processing Dependency: libogg.so.0()(64bit) for package: celt051-0.5.1.3-0.el6.x86_64
---> Package cvs.x86_64 0:1.11.23-16.el6 will be installed
---> Package glusterfs.x86_64 0:3.6.0.29-2.el6 will be installed
---> Package keyutils.x86_64 0:1.4-5.el6 will be installed
---> Package libICE.x86_64 0:1.0.6-1.el6 will be installed
---> Package libSM.x86_64 0:1.2.1-2.el6 will be installed
---> Package libXtst.x86_64 0:1.2.2-2.1.el6 will be installed
--> Processing Dependency: libXi.so.6()(64bit) for package: libXtst-1.2.2-2.1.el6.x86_64
--> Processing Dependency: libXext.so.6()(64bit) for package: libXtst-1.2.2-2.1.el6.x86_64
---> Package libasyncns.x86_64 0:0.8-1.1.el6 will be installed
---> Package libevent.x86_64 0:1.4.13-4.el6 will be installed
---> Package libgomp.x86_64 0:4.4.7-11.el6 will be installed
---> Package libgssglue.x86_64 0:0.1-11.el6 will be installed
---> Package libsndfile.x86_64 0:1.0.20-5.el6 will be installed
--> Processing Dependency: libvorbisenc.so.2()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
--> Processing Dependency: libvorbis.so.0()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
--> Processing Dependency: libFLAC.so.8()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
---> Package libtirpc.x86_64 0:0.2.1-10.el6 will be installed
---> Package nfs-utils-lib.x86_64 0:1.1.5-9.el6 will be installed
---> Package perl-Crypt-OpenSSL-Bignum.x86_64 0:0.04-8.1.el6 will be installed
---> Package perl-URI.noarch 0:1.40-2.el6 will be installed
---> Package perl-libwww-perl.noarch 0:5.833-2.el6 will be installed
--> Processing Dependency: perl-HTML-Parser >= 3.33 for package: perl-libwww-perl-5.833-2.el6.noarch
--> Processing Dependency: perl(HTML::Entities) for package: perl-libwww-perl-5.833-2.el6.noarch
--> Processing Dependency: perl(Compress::Zlib) for package: perl-libwww-perl-5.833-2.el6.noarch
---> Package pixman.x86_64 0:0.32.4-4.el6 will be installed
---> Package postgresql-libs.x86_64 0:8.4.20-1.el6_5 will be installed
---> Package python-chardet.noarch 0:2.0.1-1.el6.centos will be installed
---> Package python-ordereddict.noarch 0:1.1-2.el6.centos will be installed
---> Package python-rsa.noarch 0:3.1.1-5.el6 will be installed
---> Package python-urllib3.noarch 0:1.5-7.el6.centos will be installed
--> Processing Dependency: python-backports-ssl_match_hostname for package: python-urllib3-1.5-7.el6.centos.noarch
---> Package rpcbind.x86_64 0:0.2.0-11.el6 will be installed
--> Running transaction check
---> Package flac.x86_64 0:1.2.1-6.1.el6 will be installed
---> Package libXext.x86_64 0:1.3.2-2.1.el6 will be installed
---> Package libXi.x86_64 0:1.7.2-2.2.el6 will be installed
---> Package libogg.x86_64 2:1.1.4-2.1.el6 will be installed
---> Package libvorbis.x86_64 1:1.2.3-4.el6_2.1 will be installed
---> Package perl-Compress-Zlib.x86_64 0:2.021-136.el6_6.1 will be installed
--> Processing Dependency: perl(IO::Uncompress::Gunzip) >= 2.021 for package: perl-Compress-Zlib-2.021-136.el6_6.1.x86_64
--> Processing Dependency: perl(IO::Compress::Gzip::Constants) >= 2.021 for package: perl-Compress-Zlib-2.021-136.el6_6.1.x86_64
--> Processing Dependency: perl(IO::Compress::Gzip) >= 2.021 for package: perl-Compress-Zlib-2.021-136.el6_6.1.x86_64
--> Processing Dependency: perl(IO::Compress::Base::Common) >= 2.021 for package: perl-Compress-Zlib-2.021-136.el6_6.1.x86_64
--> Processing Dependency: perl(Compress::Raw::Zlib) >= 2.021 for package: perl-Compress-Zlib-2.021-136.el6_6.1.x86_64
---> Package perl-HTML-Parser.x86_64 0:3.64-2.el6 will be installed
--> Processing Dependency: perl(HTML::Tagset) >= 3.03 for package: perl-HTML-Parser-3.64-2.el6.x86_64
--> Processing Dependency: perl(HTML::Tagset) for package: perl-HTML-Parser-3.64-2.el6.x86_64
---> Package python-backports-ssl_match_hostname.noarch 0:3.4.0.2-4.el6.centos will be installed
--> Processing Dependency: python-backports for package: python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch
--> Running transaction check
---> Package perl-Compress-Raw-Zlib.x86_64 1:2.021-136.el6_6.1 will be installed
---> Package perl-HTML-Tagset.noarch 0:3.20-4.el6 will be installed
---> Package perl-IO-Compress-Base.x86_64 0:2.021-136.el6_6.1 will be installed
---> Package perl-IO-Compress-Zlib.x86_64 0:2.021-136.el6_6.1 will be installed
---> Package python-backports.x86_64 0:1.0-3.el6.centos will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=================================================================================================================================================================================================
 Package                                                     Arch                           Version                                        Repository                                       Size
=================================================================================================================================================================================================
Installing:
 eucalyptus-nc                                               x86_64                         4.0.2-0.0.22283.44.el6                         eucalyptus                                      744 k
Installing for dependencies:
 PyGreSQL                                                    x86_64                         3.8.1-2.el6                                    centos-6-x86_64-os                               63 k
 apr                                                         x86_64                         1.3.9-5.el6_2                                  centos-6-x86_64-os                              123 k
 apr-util                                                    x86_64                         1.3.9-3.el6_0.1                                centos-6-x86_64-os                               87 k
 apr-util-ldap                                               x86_64                         1.3.9-3.el6_0.1                                centos-6-x86_64-os                               15 k
 augeas-libs                                                 x86_64                         1.0.0-7.el6                                    centos-6-x86_64-os                              313 k
 axis2c                                                      x86_64                         1.6.0-0.7.el6                                  eucalyptus                                      524 k
 celt051                                                     x86_64                         0.5.1.3-0.el6                                  centos-6-x86_64-os                               50 k
 cvs                                                         x86_64                         1.11.23-16.el6                                 centos-6-x86_64-os                              712 k
 cyrus-sasl-md5                                              x86_64                         2.1.23-15.el6_6.1                              centos-6-x86_64-updates                          47 k
 device-mapper-multipath                                     x86_64                         0.4.9-80.el6_6.2                               centos-6-x86_64-updates                         122 k
 device-mapper-multipath-libs                                x86_64                         0.4.9-80.el6_6.2                               centos-6-x86_64-updates                         189 k
 dnsmasq                                                     x86_64                         2.48-14.el6                                    centos-6-x86_64-os                              149 k
 ebtables                                                    x86_64                         2.0.9-6.el6                                    centos-6-x86_64-os                               95 k
 euca2ools                                                   noarch                         3.1.1-0.0.1562.15.el6                          euca2ools                                       666 k
 eucalyptus                                                  x86_64                         4.0.2-0.0.22283.44.el6                         eucalyptus                                      101 k
 eucalyptus-admin-tools                                      noarch                         4.0.2-0.0.22283.44.el6                         eucalyptus                                      164 k
 eucalyptus-axis2c-common                                    x86_64                         4.0.2-0.0.22283.44.el6                         eucalyptus                                      166 k
 eucalyptus-blockdev-utils                                   x86_64                         4.0.2-0.0.22283.44.el6                         eucalyptus                                       29 k
 eucalyptus-imaging-toolkit                                  x86_64                         4.0.2-0.0.22283.44.el6                         eucalyptus                                      164 k
 flac                                                        x86_64                         1.2.1-6.1.el6                                  centos-6-x86_64-os                              243 k
 gdisk                                                       x86_64                         0.8.10-1.el6                                   centos-6-x86_64-os                              167 k
 gettext                                                     x86_64                         0.17-18.el6                                    centos-6-x86_64-os                              1.8 M
 glusterfs                                                   x86_64                         3.6.0.29-2.el6                                 centos-6-x86_64-updates                         1.3 M
 glusterfs-api                                               x86_64                         3.6.0.29-2.el6                                 centos-6-x86_64-updates                          56 k
 glusterfs-libs                                              x86_64                         3.6.0.29-2.el6                                 centos-6-x86_64-updates                         263 k
 gnutls-utils                                                x86_64                         2.8.5-14.el6_5                                 centos-6-x86_64-os                              100 k
 gpxe-roms-qemu                                              noarch                         0.9.7-6.12.el6                                 centos-6-x86_64-os                              220 k
 httpd                                                       x86_64                         2.2.15-39.el6.centos                           centos-6-x86_64-os                              825 k
 httpd-tools                                                 x86_64                         2.2.15-39.el6.centos                           centos-6-x86_64-os                               75 k
 iscsi-initiator-utils                                       x86_64                         6.2.0.873-13.el6                               centos-6-x86_64-os                              719 k
 keyutils                                                    x86_64                         1.4-5.el6                                      centos-6-x86_64-os                               39 k
 libICE                                                      x86_64                         1.0.6-1.el6                                    centos-6-x86_64-os                               53 k
 libSM                                                       x86_64                         1.2.1-2.el6                                    centos-6-x86_64-os                               37 k
 libXext                                                     x86_64                         1.3.2-2.1.el6                                  centos-6-x86_64-os                               35 k
 libXi                                                       x86_64                         1.7.2-2.2.el6                                  centos-6-x86_64-os                               37 k
 libXtst                                                     x86_64                         1.2.2-2.1.el6                                  centos-6-x86_64-os                               19 k
 libasyncns                                                  x86_64                         0.8-1.1.el6                                    centos-6-x86_64-os                               24 k
 libcgroup                                                   x86_64                         0.40.rc1-15.el6_6                              centos-6-x86_64-updates                         129 k
 libevent                                                    x86_64                         1.4.13-4.el6                                   centos-6-x86_64-os                               66 k
 libgomp                                                     x86_64                         4.4.7-11.el6                                   centos-6-x86_64-os                              133 k
 libgssglue                                                  x86_64                         0.1-11.el6                                     centos-6-x86_64-os                               23 k
 libogg                                                      x86_64                         2:1.1.4-2.1.el6                                centos-6-x86_64-os                               21 k
 libselinux-python                                           x86_64                         2.0.94-5.8.el6                                 centos-6-x86_64-os                              203 k
 libsndfile                                                  x86_64                         1.0.20-5.el6                                   centos-6-x86_64-os                              233 k
 libtirpc                                                    x86_64                         0.2.1-10.el6                                   centos-6-x86_64-os                               79 k
 libvirt                                                     x86_64                         0.10.2-46.el6_6.2                              centos-6-x86_64-updates                         2.4 M
 libvirt-client                                              x86_64                         0.10.2-46.el6_6.2                              centos-6-x86_64-updates                         4.0 M
 libvorbis                                                   x86_64                         1:1.2.3-4.el6_2.1                              centos-6-x86_64-os                              168 k
 libxslt                                                     x86_64                         1.1.26-2.el6_3.1                               centos-6-x86_64-os                              452 k
 lzop                                                        x86_64                         1.02-0.9.rc1.el6                               centos-6-x86_64-os                               50 k
 m2crypto                                                    x86_64                         0.20.2-9.el6                                   centos-6-x86_64-os                              471 k
 mailcap                                                     noarch                         2.1.31-2.el6                                   centos-6-x86_64-os                               27 k
 nc                                                          x86_64                         1.84-22.el6                                    centos-6-x86_64-os                               57 k
 netcf-libs                                                  x86_64                         0.2.4-1.el6                                    centos-6-x86_64-os                               64 k
 nfs-utils                                                   x86_64                         1:1.2.3-54.el6                                 centos-6-x86_64-os                              326 k
 nfs-utils-lib                                               x86_64                         1.1.5-9.el6                                    centos-6-x86_64-os                               68 k
 numad                                                       x86_64                         0.5-11.20140620git.el6                         centos-6-x86_64-os                               31 k
 perl-Compress-Raw-Zlib                                      x86_64                         1:2.021-136.el6_6.1                            centos-6-x86_64-updates                          69 k
 perl-Compress-Zlib                                          x86_64                         2.021-136.el6_6.1                              centos-6-x86_64-updates                          45 k
 perl-Crypt-OpenSSL-Bignum                                   x86_64                         0.04-8.1.el6                                   centos-6-x86_64-os                               34 k
 perl-Crypt-OpenSSL-RSA                                      x86_64                         0.25-10.1.el6                                  centos-6-x86_64-os                               37 k
 perl-Crypt-OpenSSL-Random                                   x86_64                         0.04-9.1.el6                                   centos-6-x86_64-os                               22 k
 perl-HTML-Parser                                            x86_64                         3.64-2.el6                                     centos-6-x86_64-os                              109 k
 perl-HTML-Tagset                                            noarch                         3.20-4.el6                                     centos-6-x86_64-os                               17 k
 perl-IO-Compress-Base                                       x86_64                         2.021-136.el6_6.1                              centos-6-x86_64-updates                          69 k
 perl-IO-Compress-Zlib                                       x86_64                         2.021-136.el6_6.1                              centos-6-x86_64-updates                         135 k
 perl-Sys-Virt                                               x86_64                         0.10.2-5.el6                                   centos-6-x86_64-os                              255 k
 perl-Time-HiRes                                             x86_64                         4:1.9721-136.el6_6.1                           centos-6-x86_64-updates                          48 k
 perl-URI                                                    noarch                         1.40-2.el6                                     centos-6-x86_64-os                              117 k
 perl-XML-Parser                                             x86_64                         2.36-7.el6                                     centos-6-x86_64-os                              224 k
 perl-XML-Simple                                             noarch                         2.18-6.el6                                     centos-6-x86_64-os                               72 k
 perl-libwww-perl                                            noarch                         5.833-2.el6                                    centos-6-x86_64-os                              387 k
 pixman                                                      x86_64                         0.32.4-4.el6                                   centos-6-x86_64-os                              243 k
 postgresql-libs                                             x86_64                         8.4.20-1.el6_5                                 centos-6-x86_64-os                              201 k
 pulseaudio-libs                                             x86_64                         0.9.21-17.el6                                  centos-6-x86_64-os                              462 k
 python-argparse                                             noarch                         1.2.1-2.el6.centos                             extras                                           48 k
 python-backports                                            x86_64                         1.0-3.el6.centos                               extras                                          5.3 k
 python-backports-ssl_match_hostname                         noarch                         3.4.0.2-4.el6.centos                           extras                                           13 k
 python-boto                                                 noarch                         2.34.0-4.el6                                   epel-6-x86_64                                   1.7 M
 python-chardet                                              noarch                         2.0.1-1.el6.centos                             extras                                          225 k
 python-lxml                                                 x86_64                         2.2.3-1.1.el6                                  centos-6-x86_64-os                              2.0 M
 python-ordereddict                                          noarch                         1.1-2.el6.centos                               extras                                          7.7 k
 python-progressbar                                          noarch                         2.3-2.el6                                      epel-6-x86_64                                    20 k
 python-requestbuilder                                       noarch                         0.2.3-0.1.el6                                  euca2ools                                        65 k
 python-requests                                             noarch                         1.1.0-4.el6.centos                             extras                                           71 k
 python-rsa                                                  noarch                         3.1.1-5.el6                                    epel-6-x86_64                                    60 k
 python-setuptools                                           noarch                         0.6.10-3.el6                                   centos-6-x86_64-os                              336 k
 python-six                                                  noarch                         1.7.3-1.el6.centos                             extras                                           27 k
 python-urllib3                                              noarch                         1.5-7.el6.centos                               extras                                           41 k
 qemu-img                                                    x86_64                         2:0.12.1.2-2.448.el6_6                         centos-6-x86_64-updates                         795 k
 qemu-kvm                                                    x86_64                         2:0.12.1.2-2.448.el6_6                         centos-6-x86_64-updates                         1.6 M
 radvd                                                       x86_64                         1.6-1.el6                                      centos-6-x86_64-os                               75 k
 rampartc                                                    x86_64                         1.3.0-0.5.el6                                  eucalyptus                                      152 k
 rpcbind                                                     x86_64                         0.2.0-11.el6                                   centos-6-x86_64-os                               51 k
 seabios                                                     x86_64                         0.6.1.2-28.el6                                 centos-6-x86_64-os                               92 k
 sgabios-bin                                                 noarch                         0-0.3.20110621svn.el6                          centos-6-x86_64-os                              6.6 k
 spice-server                                                x86_64                         0.12.4-11.el6                                  centos-6-x86_64-os                              345 k
 usbredir                                                    x86_64                         0.5.1-1.el6                                    centos-6-x86_64-os                               40 k
 vgabios                                                     noarch                         0.6b-3.7.el6                                   centos-6-x86_64-os                               42 k
 yajl                                                        x86_64                         1.0.7-3.el6                                    centos-6-x86_64-os                               27 k

Transaction Summary
=================================================================================================================================================================================================
Install     101 Package(s)

Total download size: 30 M
Installed size: 115 M
Downloading Packages:
(1/101): PyGreSQL-3.8.1-2.el6.x86_64.rpm                                                                                                                                  |  63 kB     00:00     
(2/101): apr-1.3.9-5.el6_2.x86_64.rpm                                                                                                                                     | 123 kB     00:00     
(3/101): apr-util-1.3.9-3.el6_0.1.x86_64.rpm                                                                                                                              |  87 kB     00:00     
(4/101): apr-util-ldap-1.3.9-3.el6_0.1.x86_64.rpm                                                                                                                         |  15 kB     00:00     
(5/101): augeas-libs-1.0.0-7.el6.x86_64.rpm                                                                                                                               | 313 kB     00:00     
(6/101): axis2c-1.6.0-0.7.el6.x86_64.rpm                                                                                                                                  | 524 kB     00:00     
(7/101): celt051-0.5.1.3-0.el6.x86_64.rpm                                                                                                                                 |  50 kB     00:00     
(8/101): cvs-1.11.23-16.el6.x86_64.rpm                                                                                                                                    | 712 kB     00:00     
(9/101): cyrus-sasl-md5-2.1.23-15.el6_6.1.x86_64.rpm                                                                                                                      |  47 kB     00:00     
(10/101): device-mapper-multipath-0.4.9-80.el6_6.2.x86_64.rpm                                                                                                             | 122 kB     00:00     
(11/101): device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64.rpm                                                                                                        | 189 kB     00:00     
(12/101): dnsmasq-2.48-14.el6.x86_64.rpm                                                                                                                                  | 149 kB     00:00     
(13/101): ebtables-2.0.9-6.el6.x86_64.rpm                                                                                                                                 |  95 kB     00:00     
(14/101): euca2ools-3.1.1-0.0.1562.15.el6.noarch.rpm                                                                                                                      | 666 kB     00:00     
(15/101): eucalyptus-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                                    | 101 kB     00:00     
(16/101): eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch.rpm                                                                                                        | 164 kB     00:00     
(17/101): eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                      | 166 kB     00:00     
(18/101): eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                     |  29 kB     00:00     
(19/101): eucalyptus-imaging-toolkit-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                    | 164 kB     00:00     
(20/101): eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                                 | 744 kB     00:00     
(21/101): flac-1.2.1-6.1.el6.x86_64.rpm                                                                                                                                   | 243 kB     00:00     
(22/101): gdisk-0.8.10-1.el6.x86_64.rpm                                                                                                                                   | 167 kB     00:00     
(23/101): gettext-0.17-18.el6.x86_64.rpm                                                                                                                                  | 1.8 MB     00:00     
(24/101): glusterfs-3.6.0.29-2.el6.x86_64.rpm                                                                                                                             | 1.3 MB     00:00     
(25/101): glusterfs-api-3.6.0.29-2.el6.x86_64.rpm                                                                                                                         |  56 kB     00:00     
(26/101): glusterfs-libs-3.6.0.29-2.el6.x86_64.rpm                                                                                                                        | 263 kB     00:00     
(27/101): gnutls-utils-2.8.5-14.el6_5.x86_64.rpm                                                                                                                          | 100 kB     00:00     
(28/101): gpxe-roms-qemu-0.9.7-6.12.el6.noarch.rpm                                                                                                                        | 220 kB     00:00     
(29/101): httpd-2.2.15-39.el6.centos.x86_64.rpm                                                                                                                           | 825 kB     00:00     
(30/101): httpd-tools-2.2.15-39.el6.centos.x86_64.rpm                                                                                                                     |  75 kB     00:00     
(31/101): iscsi-initiator-utils-6.2.0.873-13.el6.x86_64.rpm                                                                                                               | 719 kB     00:00     
(32/101): keyutils-1.4-5.el6.x86_64.rpm                                                                                                                                   |  39 kB     00:00     
(33/101): libICE-1.0.6-1.el6.x86_64.rpm                                                                                                                                   |  53 kB     00:00     
(34/101): libSM-1.2.1-2.el6.x86_64.rpm                                                                                                                                    |  37 kB     00:00     
(35/101): libXext-1.3.2-2.1.el6.x86_64.rpm                                                                                                                                |  35 kB     00:00     
(36/101): libXi-1.7.2-2.2.el6.x86_64.rpm                                                                                                                                  |  37 kB     00:00     
(37/101): libXtst-1.2.2-2.1.el6.x86_64.rpm                                                                                                                                |  19 kB     00:00     
(38/101): libasyncns-0.8-1.1.el6.x86_64.rpm                                                                                                                               |  24 kB     00:00     
(39/101): libcgroup-0.40.rc1-15.el6_6.x86_64.rpm                                                                                                                          | 129 kB     00:00     
(40/101): libevent-1.4.13-4.el6.x86_64.rpm                                                                                                                                |  66 kB     00:00     
(41/101): libgomp-4.4.7-11.el6.x86_64.rpm                                                                                                                                 | 133 kB     00:00     
(42/101): libgssglue-0.1-11.el6.x86_64.rpm                                                                                                                                |  23 kB     00:00     
(43/101): libogg-1.1.4-2.1.el6.x86_64.rpm                                                                                                                                 |  21 kB     00:00     
(44/101): libselinux-python-2.0.94-5.8.el6.x86_64.rpm                                                                                                                     | 203 kB     00:00     
(45/101): libsndfile-1.0.20-5.el6.x86_64.rpm                                                                                                                              | 233 kB     00:00     
(46/101): libtirpc-0.2.1-10.el6.x86_64.rpm                                                                                                                                |  79 kB     00:00     
(47/101): libvirt-0.10.2-46.el6_6.2.x86_64.rpm                                                                                                                            | 2.4 MB     00:00     
(48/101): libvirt-client-0.10.2-46.el6_6.2.x86_64.rpm                                                                                                                     | 4.0 MB     00:00     
(49/101): libvorbis-1.2.3-4.el6_2.1.x86_64.rpm                                                                                                                            | 168 kB     00:00     
(50/101): libxslt-1.1.26-2.el6_3.1.x86_64.rpm                                                                                                                             | 452 kB     00:00     
(51/101): lzop-1.02-0.9.rc1.el6.x86_64.rpm                                                                                                                                |  50 kB     00:00     
(52/101): m2crypto-0.20.2-9.el6.x86_64.rpm                                                                                                                                | 471 kB     00:00     
(53/101): mailcap-2.1.31-2.el6.noarch.rpm                                                                                                                                 |  27 kB     00:00     
(54/101): nc-1.84-22.el6.x86_64.rpm                                                                                                                                       |  57 kB     00:00     
(55/101): netcf-libs-0.2.4-1.el6.x86_64.rpm                                                                                                                               |  64 kB     00:00     
(56/101): nfs-utils-1.2.3-54.el6.x86_64.rpm                                                                                                                               | 326 kB     00:00     
(57/101): nfs-utils-lib-1.1.5-9.el6.x86_64.rpm                                                                                                                            |  68 kB     00:00     
(58/101): numad-0.5-11.20140620git.el6.x86_64.rpm                                                                                                                         |  31 kB     00:00     
(59/101): perl-Compress-Raw-Zlib-2.021-136.el6_6.1.x86_64.rpm                                                                                                             |  69 kB     00:00     
(60/101): perl-Compress-Zlib-2.021-136.el6_6.1.x86_64.rpm                                                                                                                 |  45 kB     00:00     
(61/101): perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64.rpm                                                                                                               |  34 kB     00:00     
(62/101): perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64.rpm                                                                                                                 |  37 kB     00:00     
(63/101): perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64.rpm                                                                                                               |  22 kB     00:00     
(64/101): perl-HTML-Parser-3.64-2.el6.x86_64.rpm                                                                                                                          | 109 kB     00:00     
(65/101): perl-HTML-Tagset-3.20-4.el6.noarch.rpm                                                                                                                          |  17 kB     00:00     
(66/101): perl-IO-Compress-Base-2.021-136.el6_6.1.x86_64.rpm                                                                                                              |  69 kB     00:00     
(67/101): perl-IO-Compress-Zlib-2.021-136.el6_6.1.x86_64.rpm                                                                                                              | 135 kB     00:00     
(68/101): perl-Sys-Virt-0.10.2-5.el6.x86_64.rpm                                                                                                                           | 255 kB     00:00     
(69/101): perl-Time-HiRes-1.9721-136.el6_6.1.x86_64.rpm                                                                                                                   |  48 kB     00:00     
(70/101): perl-URI-1.40-2.el6.noarch.rpm                                                                                                                                  | 117 kB     00:00     
(71/101): perl-XML-Parser-2.36-7.el6.x86_64.rpm                                                                                                                           | 224 kB     00:00     
(72/101): perl-XML-Simple-2.18-6.el6.noarch.rpm                                                                                                                           |  72 kB     00:00     
(73/101): perl-libwww-perl-5.833-2.el6.noarch.rpm                                                                                                                         | 387 kB     00:00     
(74/101): pixman-0.32.4-4.el6.x86_64.rpm                                                                                                                                  | 243 kB     00:00     
(75/101): postgresql-libs-8.4.20-1.el6_5.x86_64.rpm                                                                                                                       | 201 kB     00:00     
(76/101): pulseaudio-libs-0.9.21-17.el6.x86_64.rpm                                                                                                                        | 462 kB     00:00     
(77/101): python-argparse-1.2.1-2.el6.centos.noarch.rpm                                                                                                                   |  48 kB     00:00     
(78/101): python-backports-1.0-3.el6.centos.x86_64.rpm                                                                                                                    | 5.3 kB     00:00     
(79/101): python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch.rpm                                                                                             |  13 kB     00:00     
(80/101): python-boto-2.34.0-4.el6.noarch.rpm                                                                                                                             | 1.7 MB     00:00     
(81/101): python-chardet-2.0.1-1.el6.centos.noarch.rpm                                                                                                                    | 225 kB     00:00     
(82/101): python-lxml-2.2.3-1.1.el6.x86_64.rpm                                                                                                                            | 2.0 MB     00:00     
(83/101): python-ordereddict-1.1-2.el6.centos.noarch.rpm                                                                                                                  | 7.7 kB     00:00     
(84/101): python-progressbar-2.3-2.el6.noarch.rpm                                                                                                                         |  20 kB     00:00     
(85/101): python-requestbuilder-0.2.3-0.1.el6.noarch.rpm                                                                                                                  |  65 kB     00:00     
(86/101): python-requests-1.1.0-4.el6.centos.noarch.rpm                                                                                                                   |  71 kB     00:00     
(87/101): python-rsa-3.1.1-5.el6.noarch.rpm                                                                                                                               |  60 kB     00:00     
(88/101): python-setuptools-0.6.10-3.el6.noarch.rpm                                                                                                                       | 336 kB     00:00     
(89/101): python-six-1.7.3-1.el6.centos.noarch.rpm                                                                                                                        |  27 kB     00:00     
(90/101): python-urllib3-1.5-7.el6.centos.noarch.rpm                                                                                                                      |  41 kB     00:00     
(91/101): qemu-img-0.12.1.2-2.448.el6_6.x86_64.rpm                                                                                                                        | 795 kB     00:00     
(92/101): qemu-kvm-0.12.1.2-2.448.el6_6.x86_64.rpm                                                                                                                        | 1.6 MB     00:00     
(93/101): radvd-1.6-1.el6.x86_64.rpm                                                                                                                                      |  75 kB     00:00     
(94/101): rampartc-1.3.0-0.5.el6.x86_64.rpm                                                                                                                               | 152 kB     00:00     
(95/101): rpcbind-0.2.0-11.el6.x86_64.rpm                                                                                                                                 |  51 kB     00:00     
(96/101): seabios-0.6.1.2-28.el6.x86_64.rpm                                                                                                                               |  92 kB     00:00     
(97/101): sgabios-bin-0-0.3.20110621svn.el6.noarch.rpm                                                                                                                    | 6.6 kB     00:00     
(98/101): spice-server-0.12.4-11.el6.x86_64.rpm                                                                                                                           | 345 kB     00:00     
(99/101): usbredir-0.5.1-1.el6.x86_64.rpm                                                                                                                                 |  40 kB     00:00     
(100/101): vgabios-0.6b-3.7.el6.noarch.rpm                                                                                                                                |  42 kB     00:00     
(101/101): yajl-1.0.7-3.el6.x86_64.rpm                                                                                                                                    |  27 kB     00:00     
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                            3.8 MB/s |  30 MB     00:07     
warning: rpmts_HdrFromFdno: Header V3 RSA/SHA1 Signature, key ID c105b9de: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
Importing GPG key 0xC105B9DE:
 Userid : CentOS-6 Key (CentOS 6 Official Signing Key) <centos-6-key@centos.org>
 Package: centos-release-6-6.el6.centos.12.2.x86_64 (@anaconda-CentOS-201410241409.x86_64/6.6)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
warning: rpmts_HdrFromFdno: Header V4 RSA/SHA1 Signature, key ID c1240596: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-eucalyptus-release
Importing GPG key 0xC1240596:
 Userid : Eucalyptus Systems, Inc. (release key) <security@eucalyptus.com>
 Package: eucalyptus-release-4.0-1.el6.noarch (@/eucalyptus-release-4.0-1.el6.noarch)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-eucalyptus-release
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : eucalyptus-4.0.2-0.0.22283.44.el6.x86_64                                                                                                                                    1/101 
  Installing : libgssglue-0.1-11.el6.x86_64                                                                                                                                                2/101 
  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [                                                                                                                                         ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [#####################################################################################################                                    ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [######################################################################################################                                   ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [#############################################################################################################                            ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [####################################################################################################################                     ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64 [#######################################################################################################################################  ]   3  Installing : 2:libogg-1.1.4-2.1.el6.x86_64                                                                                                                                               3/101 
  Installing : glusterfs-libs-3.6.0.29-2.el6.x86_64                                                                                              4/101 
  Installing : apr-1.3.9-5.el6_2.x86_64 [                                                                                                    ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [#####################                                                                               ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [###########################################                                                         ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [###########################################################                                         ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [#################################################################################                   ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [#############################################################################################       ]   5  Installing : apr-1.3.9-5.el6_2.x86_64 [################################################################################################### ]   5  Installing : apr-1.3.9-5.el6_2.x86_64                                                                                                          5/101 
  Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [                                                                                             ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [#############################                                                                ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [###########################################################                                  ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [##################################################################                           ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [##################################################################################           ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64 [############################################################################################ ]    Installing : apr-util-1.3.9-3.el6_0.1.x86_64                                                                                                   6/101 
  Installing : python-argparse-1.2.1-2.el6.centos.noarch                                                                         7/101 
  Installing : axis2c-1.6.0-0.7.el6.x86_64 [                                                                                 ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##                                                                               ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [####                                                                             ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#######                                                                          ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [########                                                                         ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###########                                                                      ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#############                                                                    ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#################                                                                ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##################                                                               ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###################                                                              ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [####################                                                             ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [######################                                                           ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#######################                                                          ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#########################                                                        ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [############################                                                     ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##############################                                                   ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#################################                                                ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###################################                                              ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [######################################                                           ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [########################################                                         ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##########################################                                       ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##############################################                                   ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [################################################                                 ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###################################################                              ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [####################################################                             ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#######################################################                          ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [########################################################                         ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##########################################################                       ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###########################################################                      ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [############################################################                     ]   8/  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##############################################################                   ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#################################################################                ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [####################################################################             ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [######################################################################           ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [########################################################################         ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [###########################################################################      ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [############################################################################     ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [#############################################################################    ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [##############################################################################   ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64 [################################################################################ ]   8  Installing : axis2c-1.6.0-0.7.el6.x86_64                                                                                       8/101 
  Installing : python-six-1.7.3-1.el6.centos.noarch                                                                       9/101 
  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [                                                                      ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##                                                                    ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [####                                                                  ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#######                                                               ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#########                                                             ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##########                                                            ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###########                                                           ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [############                                                          ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##############                                                        ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###############                                                       ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [################                                                      ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#################                                                     ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##################                                                    ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [####################                                                  ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#####################                                                 ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [######################                                                ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#######################                                               ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [########################                                              ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#########################                                             ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###########################                                           ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [############################                                          ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##############################                                        ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [################################                                      ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#################################                                     ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##################################                                    ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###################################                                   ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [####################################                                  ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#####################################                                 ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [######################################                                ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#######################################                               ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [########################################                              ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#########################################                             ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##########################################                            ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###########################################                           ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [############################################                          ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#############################################                         ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##############################################                        ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###############################################                       ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [################################################                      ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#################################################                     ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###################################################                   ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [####################################################                  ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [######################################################                ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [########################################################              ]  10/10  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##########################################################            ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###########################################################           ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [############################################################          ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#############################################################         ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##############################################################        ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###############################################################       ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [################################################################      ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [#################################################################     ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [###################################################################   ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64 [##################################################################### ]  10/1  Installing : libxslt-1.1.26-2.el6_3.1.x86_64                                                                           10/101 
  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#############                                                    ]  11/101  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##############                                                   ]  11/10  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###############                                                  ]  11/10  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [################                                                 ]  11/10  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#################                                                ]  11/10  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##################                                               ]  11/10  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###################                                              ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [####################                                             ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#####################                                            ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [######################                                           ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#######################                                          ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [########################                                         ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#########################                                        ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##########################                                       ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###########################                                      ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [############################                                     ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#############################                                    ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##############################                                   ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###############################                                  ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [################################                                 ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#################################                                ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##################################                               ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###################################                              ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [####################################                             ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#####################################                            ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [######################################                           ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#######################################                          ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [########################################                         ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#########################################                        ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##########################################                       ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###########################################                      ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [############################################                     ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#############################################                    ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##############################################                   ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###############################################                  ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [################################################                 ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#################################################                ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [##################################################               ]  11/1  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [###################################################              ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [####################################################             ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#####################################################            ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [######################################################           ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [#######################################################          ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64 [########################################################         ]  11/  Installing : python-lxml-2.2.3-1.1.el6.x86_64                                                                  11/101 
  Installing : rampartc-1.3.0-0.5.el6.x86_64                                                                     12/101 
  Installing : libtirpc-0.2.1-10.el6.x86_64                                                                      13/101 
  Installing : libICE-1.0.6-1.el6.x86_64                                                                         14/101 
  Installing : mailcap-2.1.31-2.el6.noarch                                                                       15/101 
  Installing : perl-URI-1.40-2.el6.noarch                                                                        16/101 
  Installing : libXext-1.3.2-2.1.el6.x86_64                                                                      17/101 
  Installing : yajl-1.0.7-3.el6.x86_64                                                                           18/101 
  Installing : 1:perl-Compress-Raw-Zlib-2.021-136.el6_6.1.x86_64                                                 19/101 
  Installing : libcgroup-0.40.rc1-15.el6_6.x86_64                                                                20/101 
  Installing : usbredir-0.5.1-1.el6.x86_64                                                                       21/101 
  Installing : perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64                                                     22/101 
  Installing : python-ordereddict-1.1-2.el6.centos.noarch                                                        23/101 
  Installing : iscsi-initiator-utils-6.2.0.873-13.el6.x86_64                                                     24/101 
  Installing : perl-IO-Compress-Base-2.021-136.el6_6.1.x86_64                                                    25/101 
  Installing : perl-IO-Compress-Zlib-2.021-136.el6_6.1.x86_64                                                    26/101 
  Installing : perl-Compress-Zlib-2.021-136.el6_6.1.x86_64                                                       27/101 
  Installing : numad-0.5-11.20140620git.el6.x86_64                                                               28/101 
  Installing : libXi-1.7.2-2.2.el6.x86_64                                                                        29/101 
  Installing : libXtst-1.2.2-2.1.el6.x86_64                                                                      30/101 
  Installing : libSM-1.2.1-2.el6.x86_64                                                                          31/101 
  Installing : rpcbind-0.2.0-11.el6.x86_64                                                                       32/101 
  Installing : apr-util-ldap-1.3.9-3.el6_0.1.x86_64                                                              33/101 
  Installing : httpd-tools-2.2.15-39.el6.centos.x86_64                                                           34/101 
  Installing : httpd-2.2.15-39.el6.centos.x86_64                                                                 35/101 
  Installing : eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64                                            36/101 
  Installing : glusterfs-3.6.0.29-2.el6.x86_64                                                                   37/101 
  Installing : glusterfs-api-3.6.0.29-2.el6.x86_64                                                               38/101 
  Installing : 2:qemu-img-0.12.1.2-2.448.el6_6.x86_64                                                            39/101 
  Installing : celt051-0.5.1.3-0.el6.x86_64                                                                      40/101 
  Installing : flac-1.2.1-6.1.el6.x86_64                                                                         41/101 
  Installing : 1:libvorbis-1.2.3-4.el6_2.1.x86_64                                                                42/101 
  Installing : libsndfile-1.0.20-5.el6.x86_64                                                                    43/101 
  Installing : python-backports-1.0-3.el6.centos.x86_64                                                          44/101 
  Installing : python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch                                   45/101 
  Installing : python-urllib3-1.5-7.el6.centos.noarch                                                            46/101 
  Installing : gpxe-roms-qemu-0.9.7-6.12.el6.noarch                                                              47/101 
  Installing : keyutils-1.4-5.el6.x86_64                                                                         48/101 
  Installing : gnutls-utils-2.8.5-14.el6_5.x86_64                                                                49/101 
  Installing : cyrus-sasl-md5-2.1.23-15.el6_6.1.x86_64                                                           50/101 
  Installing : lzop-1.02-0.9.rc1.el6.x86_64                                                                      51/101 
  Installing : python-chardet-2.0.1-1.el6.centos.noarch                                                          52/101 
  Installing : python-requests-1.1.0-4.el6.centos.noarch                                                         53/101 
  Installing : python-requestbuilder-0.2.3-0.1.el6.noarch                                                        54/101 
  Installing : 4:perl-Time-HiRes-1.9721-136.el6_6.1.x86_64                                                       55/101 
  Installing : libasyncns-0.8-1.1.el6.x86_64                                                                     56/101 
  Installing : pulseaudio-libs-0.9.21-17.el6.x86_64                                                              57/101 
  Installing : libselinux-python-2.0.94-5.8.el6.x86_64                                                           58/101 
  Installing : perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64                                                     59/101 
  Installing : perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64                                                       60/101 
  Installing : eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64                                           61/101 
Retrigger failed udev events[  OK  ]
  Installing : seabios-0.6.1.2-28.el6.x86_64                                                                     62/101 
  Installing : libgomp-4.4.7-11.el6.x86_64                                                                       63/101 
  Installing : libevent-1.4.13-4.el6.x86_64                                                                      64/101 
  Installing : nfs-utils-lib-1.1.5-9.el6.x86_64                                                                  65/101 
  Installing : 1:nfs-utils-1.2.3-54.el6.x86_64                                                                   66/101 
  Installing : perl-HTML-Tagset-3.20-4.el6.noarch                                                                67/101 
  Installing : perl-HTML-Parser-3.64-2.el6.x86_64                                                                68/101 
  Installing : perl-libwww-perl-5.833-2.el6.noarch                                                               69/101 
  Installing : perl-XML-Parser-2.36-7.el6.x86_64                                                                 70/101 
  Installing : perl-XML-Simple-2.18-6.el6.noarch                                                                 71/101 
  Installing : device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64                                              72/101 
  Installing : device-mapper-multipath-0.4.9-80.el6_6.2.x86_64                                                   73/101 
  Installing : m2crypto-0.20.2-9.el6.x86_64                                                                      74/101 
  Installing : ebtables-2.0.9-6.el6.x86_64                                                                       75/101 
  Installing : python-setuptools-0.6.10-3.el6.noarch                                                             76/101 
  Installing : python-rsa-3.1.1-5.el6.noarch                                                                     77/101 
  Installing : python-boto-2.34.0-4.el6.noarch                                                                   78/101 
  Installing : python-progressbar-2.3-2.el6.noarch                                                               79/101 
  Installing : cvs-1.11.23-16.el6.x86_64                                                                         80/101 
  Installing : gettext-0.17-18.el6.x86_64                                                                        81/101 
  Installing : radvd-1.6-1.el6.x86_64                                                                            82/101 
  Installing : augeas-libs-1.0.0-7.el6.x86_64                                                                    83/101 
  Installing : netcf-libs-0.2.4-1.el6.x86_64                                                                     84/101 
  Installing : pixman-0.32.4-4.el6.x86_64                                                                        85/101 
  Installing : spice-server-0.12.4-11.el6.x86_64                                                                 86/101 
  Installing : nc-1.84-22.el6.x86_64                                                                             87/101 
  Installing : libvirt-client-0.10.2-46.el6_6.2.x86_64                                                           88/101 
  Installing : perl-Sys-Virt-0.10.2-5.el6.x86_64                                                                 89/101 
  Installing : vgabios-0.6b-3.7.el6.noarch                                                                       90/101 
  Installing : postgresql-libs-8.4.20-1.el6_5.x86_64                                                             91/101 
  Installing : PyGreSQL-3.8.1-2.el6.x86_64                                                                       92/101 
  Installing : eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch                                              93/101 
  Installing : dnsmasq-2.48-14.el6.x86_64                                                                        94/101 
  Installing : libvirt-0.10.2-46.el6_6.2.x86_64                                                                  95/101 
  Installing : sgabios-bin-0-0.3.20110621svn.el6.noarch                                                          96/101 
  Installing : 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64                                                            97/101 
  Installing : gdisk-0.8.10-1.el6.x86_64                                                                         98/101 
  Installing : euca2ools-3.1.1-0.0.1562.15.el6.noarch                                                            99/101 
  Installing : eucalyptus-imaging-toolkit-4.0.2-0.0.22283.44.el6.x86_64                                         100/101 
  Installing : eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64                                                      101/101 
Stopping libvirtd daemon: [FAILED]
Starting libvirtd daemon: [  OK  ]
  Verifying  : perl-IO-Compress-Base-2.021-136.el6_6.1.x86_64                                                     1/101 
  Verifying  : apr-util-ldap-1.3.9-3.el6_0.1.x86_64                                                               2/101 
  Verifying  : gdisk-0.8.10-1.el6.x86_64                                                                          3/101 
  Verifying  : sgabios-bin-0-0.3.20110621svn.el6.noarch                                                           4/101 
  Verifying  : iscsi-initiator-utils-6.2.0.873-13.el6.x86_64                                                      5/101 
  Verifying  : celt051-0.5.1.3-0.el6.x86_64                                                                       6/101 
  Verifying  : PyGreSQL-3.8.1-2.el6.x86_64                                                                        7/101 
  Verifying  : python-ordereddict-1.1-2.el6.centos.noarch                                                         8/101 
  Verifying  : dnsmasq-2.48-14.el6.x86_64                                                                         9/101 
  Verifying  : postgresql-libs-8.4.20-1.el6_5.x86_64                                                             10/101 
  Verifying  : libvirt-0.10.2-46.el6_6.2.x86_64                                                                  11/101 
  Verifying  : vgabios-0.6b-3.7.el6.noarch                                                                       12/101 
  Verifying  : perl-XML-Parser-2.36-7.el6.x86_64                                                                 13/101 
  Verifying  : 2:qemu-img-0.12.1.2-2.448.el6_6.x86_64                                                            14/101 
  Verifying  : libXtst-1.2.2-2.1.el6.x86_64                                                                      15/101 
  Verifying  : perl-Compress-Zlib-2.021-136.el6_6.1.x86_64                                                       16/101 
  Verifying  : nc-1.84-22.el6.x86_64                                                                             17/101 
  Verifying  : perl-Sys-Virt-0.10.2-5.el6.x86_64                                                                 18/101 
  Verifying  : flac-1.2.1-6.1.el6.x86_64                                                                         19/101 
  Verifying  : perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64                                                     20/101 
  Verifying  : pixman-0.32.4-4.el6.x86_64                                                                        21/101 
  Verifying  : spice-server-0.12.4-11.el6.x86_64                                                                 22/101 
  Verifying  : libtirpc-0.2.1-10.el6.x86_64                                                                      23/101 
  Verifying  : libSM-1.2.1-2.el6.x86_64                                                                          24/101 
  Verifying  : glusterfs-libs-3.6.0.29-2.el6.x86_64                                                              25/101 
  Verifying  : augeas-libs-1.0.0-7.el6.x86_64                                                                    26/101 
  Verifying  : python-lxml-2.2.3-1.1.el6.x86_64                                                                  27/101 
  Verifying  : perl-XML-Simple-2.18-6.el6.noarch                                                                 28/101 
  Verifying  : radvd-1.6-1.el6.x86_64                                                                            29/101 
  Verifying  : usbredir-0.5.1-1.el6.x86_64                                                                       30/101 
  Verifying  : perl-libwww-perl-5.833-2.el6.noarch                                                               31/101 
  Verifying  : nfs-utils-lib-1.1.5-9.el6.x86_64                                                                  32/101 
  Verifying  : cvs-1.11.23-16.el6.x86_64                                                                         33/101 
  Verifying  : libvirt-client-0.10.2-46.el6_6.2.x86_64                                                           34/101 
  Verifying  : pulseaudio-libs-0.9.21-17.el6.x86_64                                                              35/101 
  Verifying  : python-progressbar-2.3-2.el6.noarch                                                               36/101 
  Verifying  : rpcbind-0.2.0-11.el6.x86_64                                                                       37/101 
  Verifying  : python-rsa-3.1.1-5.el6.noarch                                                                     38/101 
  Verifying  : python-setuptools-0.6.10-3.el6.noarch                                                             39/101 
  Verifying  : eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64                                            40/101 
  Verifying  : ebtables-2.0.9-6.el6.x86_64                                                                       41/101 
  Verifying  : libxslt-1.1.26-2.el6_3.1.x86_64                                                                   42/101 
  Verifying  : 2:qemu-kvm-0.12.1.2-2.448.el6_6.x86_64                                                            43/101 
  Verifying  : libcgroup-0.40.rc1-15.el6_6.x86_64                                                                44/101 
  Verifying  : python-urllib3-1.5-7.el6.centos.noarch                                                            45/101 
  Verifying  : 1:nfs-utils-1.2.3-54.el6.x86_64                                                                   46/101 
  Verifying  : m2crypto-0.20.2-9.el6.x86_64                                                                      47/101 
  Verifying  : device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64                                              48/101 
  Verifying  : python-six-1.7.3-1.el6.centos.noarch                                                              49/101 
  Verifying  : perl-HTML-Tagset-3.20-4.el6.noarch                                                                50/101 
  Verifying  : libevent-1.4.13-4.el6.x86_64                                                                      51/101 
  Verifying  : axis2c-1.6.0-0.7.el6.x86_64                                                                       52/101 
  Verifying  : libgomp-4.4.7-11.el6.x86_64                                                                       53/101 
  Verifying  : seabios-0.6.1.2-28.el6.x86_64                                                                     54/101 
  Verifying  : 2:libogg-1.1.4-2.1.el6.x86_64                                                                     55/101 
  Verifying  : libsndfile-1.0.20-5.el6.x86_64                                                                    56/101 
  Verifying  : apr-util-1.3.9-3.el6_0.1.x86_64                                                                   57/101 
  Verifying  : perl-HTML-Parser-3.64-2.el6.x86_64                                                                58/101 
  Verifying  : perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64                                                     59/101 
  Verifying  : netcf-libs-0.2.4-1.el6.x86_64                                                                     60/101 
  Verifying  : python-requestbuilder-0.2.3-0.1.el6.noarch                                                        61/101 
  Verifying  : 1:perl-Compress-Raw-Zlib-2.021-136.el6_6.1.x86_64                                                 62/101 
  Verifying  : gettext-0.17-18.el6.x86_64                                                                        63/101 
  Verifying  : python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch                                   64/101 
  Verifying  : eucalyptus-4.0.2-0.0.22283.44.el6.x86_64                                                          65/101 
  Verifying  : httpd-tools-2.2.15-39.el6.centos.x86_64                                                           66/101 
  Verifying  : yajl-1.0.7-3.el6.x86_64                                                                           67/101 
  Verifying  : perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64                                                       68/101 
  Verifying  : libselinux-python-2.0.94-5.8.el6.x86_64                                                           69/101 
  Verifying  : libasyncns-0.8-1.1.el6.x86_64                                                                     70/101 
  Verifying  : httpd-2.2.15-39.el6.centos.x86_64                                                                 71/101 
  Verifying  : eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64                                           72/101 
  Verifying  : glusterfs-3.6.0.29-2.el6.x86_64                                                                   73/101 
  Verifying  : 1:libvorbis-1.2.3-4.el6_2.1.x86_64                                                                74/101 
  Verifying  : 4:perl-Time-HiRes-1.9721-136.el6_6.1.x86_64                                                       75/101 
  Verifying  : eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch                                              76/101 
  Verifying  : python-chardet-2.0.1-1.el6.centos.noarch                                                          77/101 
  Verifying  : libXext-1.3.2-2.1.el6.x86_64                                                                      78/101 
  Verifying  : eucalyptus-imaging-toolkit-4.0.2-0.0.22283.44.el6.x86_64                                          79/101 
  Verifying  : numad-0.5-11.20140620git.el6.x86_64                                                               80/101 
  Verifying  : rampartc-1.3.0-0.5.el6.x86_64                                                                     81/101 
  Verifying  : glusterfs-api-3.6.0.29-2.el6.x86_64                                                               82/101 
  Verifying  : python-boto-2.34.0-4.el6.noarch                                                                   83/101 
  Verifying  : python-requests-1.1.0-4.el6.centos.noarch                                                         84/101 
  Verifying  : lzop-1.02-0.9.rc1.el6.x86_64                                                                      85/101 
  Verifying  : euca2ools-3.1.1-0.0.1562.15.el6.noarch                                                            86/101 
  Verifying  : cyrus-sasl-md5-2.1.23-15.el6_6.1.x86_64                                                           87/101 
  Verifying  : gnutls-utils-2.8.5-14.el6_5.x86_64                                                                88/101 
  Verifying  : keyutils-1.4-5.el6.x86_64                                                                         89/101 
  Verifying  : python-argparse-1.2.1-2.el6.centos.noarch                                                         90/101 
  Verifying  : apr-1.3.9-5.el6_2.x86_64                                                                          91/101 
  Verifying  : perl-URI-1.40-2.el6.noarch                                                                        92/101 
  Verifying  : eucalyptus-nc-4.0.2-0.0.22283.44.el6.x86_64                                                       93/101 
  Verifying  : mailcap-2.1.31-2.el6.noarch                                                                       94/101 
  Verifying  : device-mapper-multipath-0.4.9-80.el6_6.2.x86_64                                                   95/101 
  Verifying  : gpxe-roms-qemu-0.9.7-6.12.el6.noarch                                                              96/101 
  Verifying  : libXi-1.7.2-2.2.el6.x86_64                                                                        97/101 
  Verifying  : python-backports-1.0-3.el6.centos.x86_64                                                          98/101 
  Verifying  : libICE-1.0.6-1.el6.x86_64                                                                         99/101 
  Verifying  : perl-IO-Compress-Zlib-2.021-136.el6_6.1.x86_64                                                   100/101 
  Verifying  : libgssglue-0.1-11.el6.x86_64                                                                     101/101 

Installed:
  eucalyptus-nc.x86_64 0:4.0.2-0.0.22283.44.el6                                                                         

Dependency Installed:
  PyGreSQL.x86_64 0:3.8.1-2.el6                                                                                         
  apr.x86_64 0:1.3.9-5.el6_2                                                                                            
  apr-util.x86_64 0:1.3.9-3.el6_0.1                                                                                     
  apr-util-ldap.x86_64 0:1.3.9-3.el6_0.1                                                                                
  augeas-libs.x86_64 0:1.0.0-7.el6                                                                                      
  axis2c.x86_64 0:1.6.0-0.7.el6                                                                                         
  celt051.x86_64 0:0.5.1.3-0.el6                                                                                        
  cvs.x86_64 0:1.11.23-16.el6                                                                                           
  cyrus-sasl-md5.x86_64 0:2.1.23-15.el6_6.1                                                                             
  device-mapper-multipath.x86_64 0:0.4.9-80.el6_6.2                                                                     
  device-mapper-multipath-libs.x86_64 0:0.4.9-80.el6_6.2                                                                
  dnsmasq.x86_64 0:2.48-14.el6                                                                                          
  ebtables.x86_64 0:2.0.9-6.el6                                                                                         
  euca2ools.noarch 0:3.1.1-0.0.1562.15.el6                                                                              
  eucalyptus.x86_64 0:4.0.2-0.0.22283.44.el6                                                                            
  eucalyptus-admin-tools.noarch 0:4.0.2-0.0.22283.44.el6                                                                
  eucalyptus-axis2c-common.x86_64 0:4.0.2-0.0.22283.44.el6                                                              
  eucalyptus-blockdev-utils.x86_64 0:4.0.2-0.0.22283.44.el6                                                             
  eucalyptus-imaging-toolkit.x86_64 0:4.0.2-0.0.22283.44.el6                                                            
  flac.x86_64 0:1.2.1-6.1.el6                                                                                           
  gdisk.x86_64 0:0.8.10-1.el6                                                                                           
  gettext.x86_64 0:0.17-18.el6                                                                                          
  glusterfs.x86_64 0:3.6.0.29-2.el6                                                                                     
  glusterfs-api.x86_64 0:3.6.0.29-2.el6                                                                                 
  glusterfs-libs.x86_64 0:3.6.0.29-2.el6                                                                                
  gnutls-utils.x86_64 0:2.8.5-14.el6_5                                                                                  
  gpxe-roms-qemu.noarch 0:0.9.7-6.12.el6                                                                                
  httpd.x86_64 0:2.2.15-39.el6.centos                                                                                   
  httpd-tools.x86_64 0:2.2.15-39.el6.centos                                                                             
  iscsi-initiator-utils.x86_64 0:6.2.0.873-13.el6                                                                       
  keyutils.x86_64 0:1.4-5.el6                                                                                           
  libICE.x86_64 0:1.0.6-1.el6                                                                                           
  libSM.x86_64 0:1.2.1-2.el6                                                                                            
  libXext.x86_64 0:1.3.2-2.1.el6                                                                                        
  libXi.x86_64 0:1.7.2-2.2.el6                                                                                          
  libXtst.x86_64 0:1.2.2-2.1.el6                                                                                        
  libasyncns.x86_64 0:0.8-1.1.el6                                                                                       
  libcgroup.x86_64 0:0.40.rc1-15.el6_6                                                                                  
  libevent.x86_64 0:1.4.13-4.el6                                                                                        
  libgomp.x86_64 0:4.4.7-11.el6                                                                                         
  libgssglue.x86_64 0:0.1-11.el6                                                                                        
  libogg.x86_64 2:1.1.4-2.1.el6                                                                                         
  libselinux-python.x86_64 0:2.0.94-5.8.el6                                                                             
  libsndfile.x86_64 0:1.0.20-5.el6                                                                                      
  libtirpc.x86_64 0:0.2.1-10.el6                                                                                        
  libvirt.x86_64 0:0.10.2-46.el6_6.2                                                                                    
  libvirt-client.x86_64 0:0.10.2-46.el6_6.2                                                                             
  libvorbis.x86_64 1:1.2.3-4.el6_2.1                                                                                    
  libxslt.x86_64 0:1.1.26-2.el6_3.1                                                                                     
  lzop.x86_64 0:1.02-0.9.rc1.el6                                                                                        
  m2crypto.x86_64 0:0.20.2-9.el6                                                                                        
  mailcap.noarch 0:2.1.31-2.el6                                                                                         
  nc.x86_64 0:1.84-22.el6                                                                                               
  netcf-libs.x86_64 0:0.2.4-1.el6                                                                                       
  nfs-utils.x86_64 1:1.2.3-54.el6                                                                                       
  nfs-utils-lib.x86_64 0:1.1.5-9.el6                                                                                    
  numad.x86_64 0:0.5-11.20140620git.el6                                                                                 
  perl-Compress-Raw-Zlib.x86_64 1:2.021-136.el6_6.1                                                                     
  perl-Compress-Zlib.x86_64 0:2.021-136.el6_6.1                                                                         
  perl-Crypt-OpenSSL-Bignum.x86_64 0:0.04-8.1.el6                                                                       
  perl-Crypt-OpenSSL-RSA.x86_64 0:0.25-10.1.el6                                                                         
  perl-Crypt-OpenSSL-Random.x86_64 0:0.04-9.1.el6                                                                       
  perl-HTML-Parser.x86_64 0:3.64-2.el6                                                                                  
  perl-HTML-Tagset.noarch 0:3.20-4.el6                                                                                  
  perl-IO-Compress-Base.x86_64 0:2.021-136.el6_6.1                                                                      
  perl-IO-Compress-Zlib.x86_64 0:2.021-136.el6_6.1                                                                      
  perl-Sys-Virt.x86_64 0:0.10.2-5.el6                                                                                   
  perl-Time-HiRes.x86_64 4:1.9721-136.el6_6.1                                                                           
  perl-URI.noarch 0:1.40-2.el6                                                                                          
  perl-XML-Parser.x86_64 0:2.36-7.el6                                                                                   
  perl-XML-Simple.noarch 0:2.18-6.el6                                                                                   
  perl-libwww-perl.noarch 0:5.833-2.el6                                                                                 
  pixman.x86_64 0:0.32.4-4.el6                                                                                          
  postgresql-libs.x86_64 0:8.4.20-1.el6_5                                                                               
  pulseaudio-libs.x86_64 0:0.9.21-17.el6                                                                                
  python-argparse.noarch 0:1.2.1-2.el6.centos                                                                           
  python-backports.x86_64 0:1.0-3.el6.centos                                                                            
  python-backports-ssl_match_hostname.noarch 0:3.4.0.2-4.el6.centos                                                     
  python-boto.noarch 0:2.34.0-4.el6                                                                                     
  python-chardet.noarch 0:2.0.1-1.el6.centos                                                                            
  python-lxml.x86_64 0:2.2.3-1.1.el6                                                                                    
  python-ordereddict.noarch 0:1.1-2.el6.centos                                                                          
  python-progressbar.noarch 0:2.3-2.el6                                                                                 
  python-requestbuilder.noarch 0:0.2.3-0.1.el6                                                                          
  python-requests.noarch 0:1.1.0-4.el6.centos                                                                           
  python-rsa.noarch 0:3.1.1-5.el6                                                                                       
  python-setuptools.noarch 0:0.6.10-3.el6                                                                               
  python-six.noarch 0:1.7.3-1.el6.centos                                                                                
  python-urllib3.noarch 0:1.5-7.el6.centos                                                                              
  qemu-img.x86_64 2:0.12.1.2-2.448.el6_6                                                                                
  qemu-kvm.x86_64 2:0.12.1.2-2.448.el6_6                                                                                
  radvd.x86_64 0:1.6-1.el6                                                                                              
  rampartc.x86_64 0:1.3.0-0.5.el6                                                                                       
  rpcbind.x86_64 0:0.2.0-11.el6                                                                                         
  seabios.x86_64 0:0.6.1.2-28.el6                                                                                       
  sgabios-bin.noarch 0:0-0.3.20110621svn.el6                                                                            
  spice-server.x86_64 0:0.12.4-11.el6                                                                                   
  usbredir.x86_64 0:0.5.1-1.el6                                                                                         
  vgabios.noarch 0:0.6b-3.7.el6                                                                                         
  yajl.x86_64 0:1.0.7-3.el6                                                                                             

Complete!

Continue (y,n,q)[y]

============================================================

11. Start Node Controller service
    - This step is only run on the Node Controller host
    - STOP! This step should only be run after the step
      which registers all Node Controller hosts on the
      Cloud Controller host

============================================================

Commands:

chkconfig eucalyptus-nc on

service eucalyptus-nc start

Execute (y,n,q)[y]

# chkconfig eucalyptus-nc on

# service eucalyptus-nc start
Starting Eucalyptus services: done.

Continue (y,n,q)[y]

Installation and initial configuration complete
