[root@odc-c-21 bin]# euca-course-02-install.sh 

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
eucalyptus-release-4.0-1.el6.noarch.rpm                                                                                                                          | 5.2 kB     00:00     
Examining /var/tmp/yum-root-mhjBJl/eucalyptus-release-4.0-1.el6.noarch.rpm: eucalyptus-release-4.0-1.el6.noarch
Marking /var/tmp/yum-root-mhjBJl/eucalyptus-release-4.0-1.el6.noarch.rpm to be installed
Loading mirror speeds from cached hostfile
 * extras: repos.dfw.quadranet.com
epel-release-6-8.noarch.rpm                                                                                                                                      |  14 kB     00:00     
Examining /var/tmp/yum-root-mhjBJl/epel-release-6-8.noarch.rpm: epel-release-6-8.noarch
/var/tmp/yum-root-mhjBJl/epel-release-6-8.noarch.rpm: does not update installed package.
elrepo-release-6-6.el6.elrepo.noarch.rpm                                                                                                                         | 8.2 kB     00:00     
Examining /var/tmp/yum-root-mhjBJl/elrepo-release-6-6.el6.elrepo.noarch.rpm: elrepo-release-6-6.el6.elrepo.noarch
/var/tmp/yum-root-mhjBJl/elrepo-release-6-6.el6.elrepo.noarch.rpm: does not update installed package.
euca2ools-release-3.1-1.el6.noarch.rpm                                                                                                                           | 5.2 kB     00:00     
Examining /var/tmp/yum-root-mhjBJl/euca2ools-release-3.1-1.el6.noarch.rpm: euca2ools-release-3.1-1.el6.noarch
Marking /var/tmp/yum-root-mhjBJl/euca2ools-release-3.1-1.el6.noarch.rpm to be installed
Resolving Dependencies
--> Running transaction check
---> Package euca2ools-release.noarch 0:3.1-1.el6 will be installed
---> Package eucalyptus-release.noarch 0:4.0-1.el6 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

========================================================================================================================================================================================
 Package                                      Arch                             Version                             Repository                                                      Size
========================================================================================================================================================================================
Installing:
 euca2ools-release                            noarch                           3.1-1.el6                           /euca2ools-release-3.1-1.el6.noarch                            1.9 k
 eucalyptus-release                           noarch                           4.0-1.el6                           /eucalyptus-release-4.0-1.el6.noarch                           1.9 k

Transaction Summary
========================================================================================================================================================================================
Install       2 Package(s)

Total size: 3.8 k
Installed size: 3.8 k
Downloading Packages:
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : eucalyptus-release-4.0-1.el6.noarch                                                                                                                                  1/2 
  Installing : euca2ools-release-3.1-1.el6.noarch                                                                                                                                   2/2 
  Verifying  : euca2ools-release-3.1-1.el6.noarch                                                                                                                                   1/2 
  Verifying  : eucalyptus-release-4.0-1.el6.noarch                                                                                                                                  2/2 

Installed:
  euca2ools-release.noarch 0:3.1-1.el6                                                       eucalyptus-release.noarch 0:4.0-1.el6                                                      

Complete!

Continue (y,n,q)[y]

============================================================

 2. Install packages

============================================================

Commands:

yum install -y eucalyptus-cloud eucaconsole eucalyptus-cc eucalyptus-sc eucalyptus-walrus

Execute (y,n,q)[y]

# yum install -y eucalyptus-cloud eucaconsole eucalyptus-cc eucalyptus-sc eucalyptus-walrus
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: repos.dfw.quadranet.com
euca2ools                                                                                                                                                        | 1.5 kB     00:00     
euca2ools/primary                                                                                                                                                | 4.3 kB     00:00     
euca2ools                                                                                                                                                                           8/8
eucalyptus                                                                                                                                                       | 1.5 kB     00:00     
eucalyptus/primary                                                                                                                                               |  36 kB     00:00     
eucalyptus                                                                                                                                                                      122/122
Resolving Dependencies
--> Running transaction check
---> Package eucaconsole.noarch 0:4.0.2-0.0.3341.15.el6 will be installed
--> Processing Dependency: python-pyramid < 1.5 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-greenlet >= 0.3.1 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-gevent >= 0.13.8 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-chameleon >= 2.5.3 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-boto >= 2.27.0 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-wtforms for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-simplejson for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-pyramid-tm for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-pyramid-layout for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-pyramid-chameleon for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-pyramid-beaker for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-gunicorn for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-dateutil for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-crypto for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: python-beaker15 for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: mailcap for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
--> Processing Dependency: m2crypto for package: eucaconsole-4.0.2-0.0.3341.15.el6.noarch
---> Package eucalyptus-cc.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: eucalyptus-axis2c-common = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: eucalyptus = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: dhcp >= 4.1.1-33.P1 for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: vtun for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(Time::HiRes) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: httpd for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: /usr/sbin/euca_conf for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: librampart.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libneethi.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libmod_rampart.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libguththila.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxutil.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_parser.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_sender.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_receiver.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_http_common.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_engine.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libaxis2_axiom.so.0()(64bit) for package: eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64
---> Package eucalyptus-cloud.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: eucalyptus-common-java(x86-64) = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: postgresql91-server >= 9.1.9 for package: eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: postgresql91 >= 9.1.9 for package: eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: euca2ools >= 2.0 for package: eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: dejavu-serif-fonts for package: eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64
---> Package eucalyptus-sc.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: eucalyptus-blockdev-utils = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: scsi-target-utils for package: eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: iscsi-initiator-utils for package: eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: device-mapper-multipath for package: eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64
---> Package eucalyptus-walrus.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: drbd83-kmod for package: eucalyptus-walrus-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: drbd83 for package: eucalyptus-walrus-4.0.2-0.0.22283.44.el6.x86_64
--> Running transaction check
---> Package axis2c.x86_64 0:1.6.0-0.7.el6 will be installed
---> Package dejavu-serif-fonts.noarch 0:2.30-2.el6 will be installed
--> Processing Dependency: dejavu-fonts-common = 2.30-2.el6 for package: dejavu-serif-fonts-2.30-2.el6.noarch
---> Package device-mapper-multipath.x86_64 0:0.4.9-80.el6_6.2 will be installed
--> Processing Dependency: device-mapper-multipath-libs = 0.4.9-80.el6_6.2 for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
--> Processing Dependency: libmultipath.so()(64bit) for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
--> Processing Dependency: libmpathpersist.so.0()(64bit) for package: device-mapper-multipath-0.4.9-80.el6_6.2.x86_64
---> Package dhcp.x86_64 12:4.1.1-43.P1.el6.centos will be installed
--> Processing Dependency: portreserve for package: 12:dhcp-4.1.1-43.P1.el6.centos.x86_64
---> Package drbd83-utils.x86_64 0:8.3.16-1.el6.elrepo will be installed
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
--> Processing Dependency: PyGreSQL for package: eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch
---> Package eucalyptus-axis2c-common.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
---> Package eucalyptus-blockdev-utils.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: perl(Crypt::OpenSSL::Random) for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: perl(Crypt::OpenSSL::RSA) for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: libselinux-python for package: eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64
---> Package eucalyptus-common-java.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: eucalyptus-common-java-libs = 4.0.2-0.0.22283.44.el6 for package: eucalyptus-common-java-4.0.2-0.0.22283.44.el6.x86_64
---> Package httpd.x86_64 0:2.2.15-39.el6.centos will be installed
--> Processing Dependency: httpd-tools = 2.2.15-39.el6.centos for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: apr-util-ldap for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: libaprutil-1.so.0()(64bit) for package: httpd-2.2.15-39.el6.centos.x86_64
--> Processing Dependency: libapr-1.so.0()(64bit) for package: httpd-2.2.15-39.el6.centos.x86_64
---> Package iscsi-initiator-utils.x86_64 0:6.2.0.873-13.el6 will be installed
---> Package kmod-drbd83.x86_64 0:8.3.16-3.el6.elrepo will be installed
---> Package m2crypto.x86_64 0:0.20.2-9.el6 will be installed
---> Package mailcap.noarch 0:2.1.31-2.el6 will be installed
---> Package perl-Time-HiRes.x86_64 4:1.9721-136.el6_6.1 will be installed
---> Package postgresql91.x86_64 0:9.1.9-1PGDG.el6 will be installed
--> Processing Dependency: postgresql91-libs = 9.1.9-1PGDG.el6 for package: postgresql91-9.1.9-1PGDG.el6.x86_64
--> Processing Dependency: libpq.so.5()(64bit) for package: postgresql91-9.1.9-1PGDG.el6.x86_64
---> Package postgresql91-server.x86_64 0:9.1.9-1PGDG.el6 will be installed
---> Package python-beaker15.noarch 0:1.5.4-8.2.el6 will be installed
--> Processing Dependency: python-paste for package: python-beaker15-1.5.4-8.2.el6.noarch
---> Package python-boto.noarch 0:2.34.0-4.el6 will be installed
--> Processing Dependency: python-rsa for package: python-boto-2.34.0-4.el6.noarch
---> Package python-chameleon.noarch 0:2.5.3-1.el6.2 will be installed
--> Processing Dependency: python-zope-interface for package: python-chameleon-2.5.3-1.el6.2.noarch
--> Processing Dependency: python-ordereddict for package: python-chameleon-2.5.3-1.el6.2.noarch
---> Package python-crypto.x86_64 0:2.0.1-22.el6 will be installed
---> Package python-dateutil.noarch 0:1.4.1-6.el6 will be installed
---> Package python-gevent.x86_64 0:0.13.8-3.el6 will be installed
--> Processing Dependency: libevent-1.4.so.2()(64bit) for package: python-gevent-0.13.8-3.el6.x86_64
---> Package python-greenlet.x86_64 0:0.4.2-1.el6 will be installed
---> Package python-gunicorn.noarch 0:18.0-1.el6 will be installed
---> Package python-pyramid.noarch 0:1.4-9.el6 will be installed
--> Processing Dependency: python-zope-deprecation >= 3.5.0 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-zope-component >= 3.6.0 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-venusian >= 1.0 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-zope-interface4 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-zope-configuration for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-webob1.2 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-unittest2 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-translationstring for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-repoze-lru for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-paste-deploy1.5 for package: python-pyramid-1.4-9.el6.noarch
--> Processing Dependency: python-mako0.4 for package: python-pyramid-1.4-9.el6.noarch
---> Package python-pyramid-beaker.noarch 0:0.8-0.1.el6 will be installed
---> Package python-pyramid-chameleon.noarch 0:0.1-1.el6 will be installed
---> Package python-pyramid-layout.noarch 0:0.8-0.1.el6 will be installed
---> Package python-pyramid-tm.noarch 0:0.7-2.el6 will be installed
--> Processing Dependency: python-transaction for package: python-pyramid-tm-0.7-2.el6.noarch
---> Package python-simplejson.x86_64 0:2.0.9-3.1.el6 will be installed
---> Package python-wtforms.noarch 0:1.0.2-1.el6 will be installed
---> Package rampartc.x86_64 0:1.3.0-0.5.el6 will be installed
---> Package scsi-target-utils.x86_64 0:1.0.24-16.el6 will be installed
--> Processing Dependency: sg3_utils for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: perl(Config::General) for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: librdmacm.so.1(RDMACM_1.0)(64bit) for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: libibverbs.so.1(IBVERBS_1.1)(64bit) for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: libibverbs.so.1(IBVERBS_1.0)(64bit) for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: librdmacm.so.1()(64bit) for package: scsi-target-utils-1.0.24-16.el6.x86_64
--> Processing Dependency: libibverbs.so.1()(64bit) for package: scsi-target-utils-1.0.24-16.el6.x86_64
---> Package vtun.x86_64 0:3.0.1-7.el6 will be installed
--> Processing Dependency: xinetd for package: vtun-3.0.1-7.el6.x86_64
--> Running transaction check
---> Package PyGreSQL.x86_64 0:3.8.1-2.el6 will be installed
---> Package apr.x86_64 0:1.3.9-5.el6_2 will be installed
---> Package apr-util.x86_64 0:1.3.9-3.el6_0.1 will be installed
---> Package apr-util-ldap.x86_64 0:1.3.9-3.el6_0.1 will be installed
---> Package dejavu-fonts-common.noarch 0:2.30-2.el6 will be installed
--> Processing Dependency: fontpackages-filesystem for package: dejavu-fonts-common-2.30-2.el6.noarch
---> Package device-mapper-multipath-libs.x86_64 0:0.4.9-80.el6_6.2 will be installed
---> Package eucalyptus-common-java-libs.x86_64 0:4.0.2-0.0.22283.44.el6 will be installed
--> Processing Dependency: java-1.7.0-openjdk >= 1:1.7.0 for package: eucalyptus-common-java-libs-4.0.2-0.0.22283.44.el6.x86_64
--> Processing Dependency: jpackage-utils for package: eucalyptus-common-java-libs-4.0.2-0.0.22283.44.el6.x86_64
---> Package gdisk.x86_64 0:0.8.10-1.el6 will be installed
---> Package httpd-tools.x86_64 0:2.2.15-39.el6.centos will be installed
---> Package libevent.x86_64 0:1.4.13-4.el6 will be installed
---> Package libibverbs.x86_64 0:1.1.8-3.el6 will be installed
---> Package librdmacm.x86_64 0:1.0.18.1-1.el6 will be installed
---> Package libselinux-python.x86_64 0:2.0.94-5.8.el6 will be installed
---> Package perl-Config-General.noarch 0:2.52-1.el6 will be installed
---> Package perl-Crypt-OpenSSL-RSA.x86_64 0:0.25-10.1.el6 will be installed
--> Processing Dependency: perl(Crypt::OpenSSL::Bignum) for package: perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64
---> Package perl-Crypt-OpenSSL-Random.x86_64 0:0.04-9.1.el6 will be installed
---> Package portreserve.x86_64 0:0.0.4-9.el6 will be installed
---> Package postgresql91-libs.x86_64 0:9.1.9-1PGDG.el6 will be installed
---> Package python-argparse.noarch 0:1.2.1-2.el6.centos will be installed
---> Package python-lxml.x86_64 0:2.2.3-1.1.el6 will be installed
--> Processing Dependency: libxslt.so.1(LIBXML2_1.1.9)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.1.26)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.1.2)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.0.24)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.0.22)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.0.18)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1(LIBXML2_1.0.11)(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libxslt.so.1()(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
--> Processing Dependency: libexslt.so.0()(64bit) for package: python-lxml-2.2.3-1.1.el6.x86_64
---> Package python-mako0.4.noarch 0:0.4.2-7.el6 will be installed
--> Processing Dependency: python-markupsafe for package: python-mako0.4-0.4.2-7.el6.noarch
--> Processing Dependency: python-beaker for package: python-mako0.4-0.4.2-7.el6.noarch
---> Package python-ordereddict.noarch 0:1.1-2.el6.centos will be installed
---> Package python-paste.noarch 0:1.7.4-2.el6 will be installed
--> Processing Dependency: pyOpenSSL for package: python-paste-1.7.4-2.el6.noarch
---> Package python-paste-deploy1.5.noarch 0:1.5.0-5.el6 will be installed
---> Package python-progressbar.noarch 0:2.3-2.el6 will be installed
---> Package python-repoze-lru.noarch 0:0.4-3.el6 will be installed
---> Package python-requestbuilder.noarch 0:0.2.3-0.1.el6 will be installed
---> Package python-requests.noarch 0:1.1.0-4.el6.centos will be installed
--> Processing Dependency: python-urllib3 for package: python-requests-1.1.0-4.el6.centos.noarch
--> Processing Dependency: python-chardet for package: python-requests-1.1.0-4.el6.centos.noarch
---> Package python-rsa.noarch 0:3.1.1-5.el6 will be installed
---> Package python-setuptools.noarch 0:0.6.10-3.el6 will be installed
---> Package python-six.noarch 0:1.7.3-1.el6.centos will be installed
---> Package python-transaction.noarch 0:1.0.1-1.el6 will be installed
---> Package python-translationstring.noarch 0:0.4-1.el6 will be installed
---> Package python-unittest2.noarch 0:0.5.1-3.el6 will be installed
---> Package python-venusian.noarch 0:1.0-0.4.a3.el6 will be installed
---> Package python-webob1.2.noarch 0:1.2.3-2.el6 will be installed
---> Package python-zope-component.noarch 0:4.0.2-2.el6 will be installed
--> Processing Dependency: python-zope-event for package: python-zope-component-4.0.2-2.el6.noarch
---> Package python-zope-configuration.noarch 0:3.7.2-4.el6 will be installed
--> Processing Dependency: python-zope-schema for package: python-zope-configuration-3.7.2-4.el6.noarch
--> Processing Dependency: python-zope-i18nmessageid for package: python-zope-configuration-3.7.2-4.el6.noarch
---> Package python-zope-deprecation.noarch 0:3.5.1-1.el6 will be installed
---> Package python-zope-interface.x86_64 0:3.5.2-2.1.el6 will be installed
--> Processing Dependency: python-zope-filesystem for package: python-zope-interface-3.5.2-2.1.el6.x86_64
---> Package python-zope-interface4.x86_64 0:4.0.4-1.el6 will be installed
---> Package sg3_utils.x86_64 0:1.28-6.el6 will be installed
---> Package xinetd.x86_64 2:2.3.14-39.el6_4 will be installed
--> Running transaction check
---> Package fontpackages-filesystem.noarch 0:1.41-1.1.el6 will be installed
---> Package java-1.7.0-openjdk.x86_64 1:1.7.0.71-2.5.3.2.el6_6 will be installed
--> Processing Dependency: xorg-x11-fonts-Type1 for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: tzdata-java for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libpulse.so.0(PULSE_0)(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: fontconfig for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libpulse.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libpangoft2-1.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libpangocairo-1.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libpango-1.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libgtk-x11-2.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libgif.so.4()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libgdk-x11-2.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libfreetype.so.6()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libfontconfig.so.1()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libcairo.so.2()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libatk-1.0.so.0()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libXtst.so.6()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libXrender.so.1()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libXi.so.6()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
--> Processing Dependency: libXext.so.6()(64bit) for package: 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64
---> Package jpackage-utils.noarch 0:1.7.5-3.12.el6 will be installed
---> Package libxslt.x86_64 0:1.1.26-2.el6_3.1 will be installed
---> Package perl-Crypt-OpenSSL-Bignum.x86_64 0:0.04-8.1.el6 will be installed
---> Package pyOpenSSL.x86_64 0:0.10-2.el6 will be installed
---> Package python-beaker.noarch 0:1.3.1-7.el6 will be installed
---> Package python-chardet.noarch 0:2.0.1-1.el6.centos will be installed
---> Package python-markupsafe.x86_64 0:0.9.2-4.el6 will be installed
---> Package python-urllib3.noarch 0:1.5-7.el6.centos will be installed
--> Processing Dependency: python-backports-ssl_match_hostname for package: python-urllib3-1.5-7.el6.centos.noarch
---> Package python-zope-event.noarch 0:3.5.1-5.el6 will be installed
---> Package python-zope-filesystem.x86_64 0:1-5.el6 will be installed
---> Package python-zope-i18nmessageid.x86_64 0:3.5.3-6.el6 will be installed
---> Package python-zope-schema.noarch 0:3.8.1-3.el6 will be installed
--> Running transaction check
---> Package atk.x86_64 0:1.30.0-1.el6 will be installed
---> Package cairo.x86_64 0:1.8.8-3.1.el6 will be installed
--> Processing Dependency: libpixman-1.so.0()(64bit) for package: cairo-1.8.8-3.1.el6.x86_64
---> Package fontconfig.x86_64 0:2.8.0-5.el6 will be installed
---> Package freetype.x86_64 0:2.3.11-14.el6_3.1 will be installed
---> Package giflib.x86_64 0:4.1.6-3.1.el6 will be installed
--> Processing Dependency: libSM.so.6()(64bit) for package: giflib-4.1.6-3.1.el6.x86_64
--> Processing Dependency: libICE.so.6()(64bit) for package: giflib-4.1.6-3.1.el6.x86_64
---> Package gtk2.x86_64 0:2.24.23-6.el6 will be installed
--> Processing Dependency: libXrandr >= 1.2.99.4-2 for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: hicolor-icon-theme for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXrandr.so.2()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXinerama.so.1()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXfixes.so.3()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXdamage.so.1()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXcursor.so.1()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
--> Processing Dependency: libXcomposite.so.1()(64bit) for package: gtk2-2.24.23-6.el6.x86_64
---> Package libXext.x86_64 0:1.3.2-2.1.el6 will be installed
---> Package libXi.x86_64 0:1.7.2-2.2.el6 will be installed
---> Package libXrender.x86_64 0:0.9.8-2.1.el6 will be installed
---> Package libXtst.x86_64 0:1.2.2-2.1.el6 will be installed
---> Package pango.x86_64 0:1.28.1-10.el6 will be installed
--> Processing Dependency: libthai >= 0.1.9 for package: pango-1.28.1-10.el6.x86_64
--> Processing Dependency: libthai.so.0(LIBTHAI_0.1)(64bit) for package: pango-1.28.1-10.el6.x86_64
--> Processing Dependency: libthai.so.0()(64bit) for package: pango-1.28.1-10.el6.x86_64
--> Processing Dependency: libXft.so.2()(64bit) for package: pango-1.28.1-10.el6.x86_64
---> Package pulseaudio-libs.x86_64 0:0.9.21-17.el6 will be installed
--> Processing Dependency: libsndfile.so.1(libsndfile.so.1.0)(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libsndfile.so.1()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
--> Processing Dependency: libasyncns.so.0()(64bit) for package: pulseaudio-libs-0.9.21-17.el6.x86_64
---> Package python-backports-ssl_match_hostname.noarch 0:3.4.0.2-4.el6.centos will be installed
--> Processing Dependency: python-backports for package: python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch
---> Package tzdata-java.noarch 0:2014j-1.el6 will be installed
---> Package xorg-x11-fonts-Type1.noarch 0:7.2-9.1.el6 will be installed
--> Processing Dependency: ttmkfdir for package: xorg-x11-fonts-Type1-7.2-9.1.el6.noarch
--> Processing Dependency: ttmkfdir for package: xorg-x11-fonts-Type1-7.2-9.1.el6.noarch
--> Processing Dependency: mkfontdir for package: xorg-x11-fonts-Type1-7.2-9.1.el6.noarch
--> Processing Dependency: mkfontdir for package: xorg-x11-fonts-Type1-7.2-9.1.el6.noarch
--> Running transaction check
---> Package hicolor-icon-theme.noarch 0:0.11-1.1.el6 will be installed
---> Package libICE.x86_64 0:1.0.6-1.el6 will be installed
---> Package libSM.x86_64 0:1.2.1-2.el6 will be installed
---> Package libXcomposite.x86_64 0:0.4.3-4.el6 will be installed
---> Package libXcursor.x86_64 0:1.1.14-2.1.el6 will be installed
---> Package libXdamage.x86_64 0:1.1.3-4.el6 will be installed
---> Package libXfixes.x86_64 0:5.0.1-2.1.el6 will be installed
---> Package libXft.x86_64 0:2.3.1-2.el6 will be installed
---> Package libXinerama.x86_64 0:1.1.3-2.1.el6 will be installed
---> Package libXrandr.x86_64 0:1.4.1-2.1.el6 will be installed
---> Package libasyncns.x86_64 0:0.8-1.1.el6 will be installed
---> Package libsndfile.x86_64 0:1.0.20-5.el6 will be installed
--> Processing Dependency: libvorbisenc.so.2()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
--> Processing Dependency: libvorbis.so.0()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
--> Processing Dependency: libogg.so.0()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
--> Processing Dependency: libFLAC.so.8()(64bit) for package: libsndfile-1.0.20-5.el6.x86_64
---> Package libthai.x86_64 0:0.1.12-3.el6 will be installed
---> Package pixman.x86_64 0:0.32.4-4.el6 will be installed
---> Package python-backports.x86_64 0:1.0-3.el6.centos will be installed
---> Package ttmkfdir.x86_64 0:3.0.9-32.1.el6 will be installed
---> Package xorg-x11-font-utils.x86_64 1:7.2-11.el6 will be installed
--> Processing Dependency: libfontenc.so.1()(64bit) for package: 1:xorg-x11-font-utils-7.2-11.el6.x86_64
--> Processing Dependency: libXfont.so.1()(64bit) for package: 1:xorg-x11-font-utils-7.2-11.el6.x86_64
--> Running transaction check
---> Package flac.x86_64 0:1.2.1-6.1.el6 will be installed
---> Package libXfont.x86_64 0:1.4.5-4.el6_6 will be installed
---> Package libfontenc.x86_64 0:1.0.5-2.el6 will be installed
---> Package libogg.x86_64 2:1.1.4-2.1.el6 will be installed
---> Package libvorbis.x86_64 1:1.2.3-4.el6_2.1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

========================================================================================================================================================================================
 Package                                                  Arch                        Version                                        Repository                                    Size
========================================================================================================================================================================================
Installing:
 eucaconsole                                              noarch                      4.0.2-0.0.3341.15.el6                          eucalyptus                                   1.6 M
 eucalyptus-cc                                            x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                   1.8 M
 eucalyptus-cloud                                         x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    17 k
 eucalyptus-sc                                            x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    11 k
 eucalyptus-walrus                                        x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    12 k
Installing for dependencies:
 PyGreSQL                                                 x86_64                      3.8.1-2.el6                                    centos-6-x86_64-os                            63 k
 apr                                                      x86_64                      1.3.9-5.el6_2                                  centos-6-x86_64-os                           123 k
 apr-util                                                 x86_64                      1.3.9-3.el6_0.1                                centos-6-x86_64-os                            87 k
 apr-util-ldap                                            x86_64                      1.3.9-3.el6_0.1                                centos-6-x86_64-os                            15 k
 atk                                                      x86_64                      1.30.0-1.el6                                   centos-6-x86_64-os                           195 k
 axis2c                                                   x86_64                      1.6.0-0.7.el6                                  eucalyptus                                   524 k
 cairo                                                    x86_64                      1.8.8-3.1.el6                                  centos-6-x86_64-os                           309 k
 dejavu-fonts-common                                      noarch                      2.30-2.el6                                     centos-6-x86_64-os                            59 k
 dejavu-serif-fonts                                       noarch                      2.30-2.el6                                     centos-6-x86_64-os                           827 k
 device-mapper-multipath                                  x86_64                      0.4.9-80.el6_6.2                               centos-6-x86_64-updates                      122 k
 device-mapper-multipath-libs                             x86_64                      0.4.9-80.el6_6.2                               centos-6-x86_64-updates                      189 k
 dhcp                                                     x86_64                      12:4.1.1-43.P1.el6.centos                      centos-6-x86_64-os                           819 k
 drbd83-utils                                             x86_64                      8.3.16-1.el6.elrepo                            elrepo-6-x86_64                              219 k
 euca2ools                                                noarch                      3.1.1-0.0.1562.15.el6                          euca2ools                                    666 k
 eucalyptus                                               x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                   101 k
 eucalyptus-admin-tools                                   noarch                      4.0.2-0.0.22283.44.el6                         eucalyptus                                   164 k
 eucalyptus-axis2c-common                                 x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                   166 k
 eucalyptus-blockdev-utils                                x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    29 k
 eucalyptus-common-java                                   x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    59 k
 eucalyptus-common-java-libs                              x86_64                      4.0.2-0.0.22283.44.el6                         eucalyptus                                    75 M
 flac                                                     x86_64                      1.2.1-6.1.el6                                  centos-6-x86_64-os                           243 k
 fontconfig                                               x86_64                      2.8.0-5.el6                                    centos-6-x86_64-os                           186 k
 fontpackages-filesystem                                  noarch                      1.41-1.1.el6                                   centos-6-x86_64-os                           8.8 k
 freetype                                                 x86_64                      2.3.11-14.el6_3.1                              centos-6-x86_64-os                           359 k
 gdisk                                                    x86_64                      0.8.10-1.el6                                   centos-6-x86_64-os                           167 k
 giflib                                                   x86_64                      4.1.6-3.1.el6                                  centos-6-x86_64-os                            37 k
 gtk2                                                     x86_64                      2.24.23-6.el6                                  centos-6-x86_64-os                           3.2 M
 hicolor-icon-theme                                       noarch                      0.11-1.1.el6                                   centos-6-x86_64-os                            40 k
 httpd                                                    x86_64                      2.2.15-39.el6.centos                           centos-6-x86_64-os                           825 k
 httpd-tools                                              x86_64                      2.2.15-39.el6.centos                           centos-6-x86_64-os                            75 k
 iscsi-initiator-utils                                    x86_64                      6.2.0.873-13.el6                               centos-6-x86_64-os                           719 k
 java-1.7.0-openjdk                                       x86_64                      1:1.7.0.71-2.5.3.2.el6_6                       centos-6-x86_64-updates                       26 M
 jpackage-utils                                           noarch                      1.7.5-3.12.el6                                 centos-6-x86_64-os                            59 k
 kmod-drbd83                                              x86_64                      8.3.16-3.el6.elrepo                            elrepo-6-x86_64                              173 k
 libICE                                                   x86_64                      1.0.6-1.el6                                    centos-6-x86_64-os                            53 k
 libSM                                                    x86_64                      1.2.1-2.el6                                    centos-6-x86_64-os                            37 k
 libXcomposite                                            x86_64                      0.4.3-4.el6                                    centos-6-x86_64-os                            20 k
 libXcursor                                               x86_64                      1.1.14-2.1.el6                                 centos-6-x86_64-os                            28 k
 libXdamage                                               x86_64                      1.1.3-4.el6                                    centos-6-x86_64-os                            18 k
 libXext                                                  x86_64                      1.3.2-2.1.el6                                  centos-6-x86_64-os                            35 k
 libXfixes                                                x86_64                      5.0.1-2.1.el6                                  centos-6-x86_64-os                            17 k
 libXfont                                                 x86_64                      1.4.5-4.el6_6                                  centos-6-x86_64-updates                      137 k
 libXft                                                   x86_64                      2.3.1-2.el6                                    centos-6-x86_64-os                            55 k
 libXi                                                    x86_64                      1.7.2-2.2.el6                                  centos-6-x86_64-os                            37 k
 libXinerama                                              x86_64                      1.1.3-2.1.el6                                  centos-6-x86_64-os                            13 k
 libXrandr                                                x86_64                      1.4.1-2.1.el6                                  centos-6-x86_64-os                            23 k
 libXrender                                               x86_64                      0.9.8-2.1.el6                                  centos-6-x86_64-os                            24 k
 libXtst                                                  x86_64                      1.2.2-2.1.el6                                  centos-6-x86_64-os                            19 k
 libasyncns                                               x86_64                      0.8-1.1.el6                                    centos-6-x86_64-os                            24 k
 libevent                                                 x86_64                      1.4.13-4.el6                                   centos-6-x86_64-os                            66 k
 libfontenc                                               x86_64                      1.0.5-2.el6                                    centos-6-x86_64-os                            24 k
 libibverbs                                               x86_64                      1.1.8-3.el6                                    centos-6-x86_64-os                            52 k
 libogg                                                   x86_64                      2:1.1.4-2.1.el6                                centos-6-x86_64-os                            21 k
 librdmacm                                                x86_64                      1.0.18.1-1.el6                                 centos-6-x86_64-os                            57 k
 libselinux-python                                        x86_64                      2.0.94-5.8.el6                                 centos-6-x86_64-os                           203 k
 libsndfile                                               x86_64                      1.0.20-5.el6                                   centos-6-x86_64-os                           233 k
 libthai                                                  x86_64                      0.1.12-3.el6                                   centos-6-x86_64-os                           183 k
 libvorbis                                                x86_64                      1:1.2.3-4.el6_2.1                              centos-6-x86_64-os                           168 k
 libxslt                                                  x86_64                      1.1.26-2.el6_3.1                               centos-6-x86_64-os                           452 k
 m2crypto                                                 x86_64                      0.20.2-9.el6                                   centos-6-x86_64-os                           471 k
 mailcap                                                  noarch                      2.1.31-2.el6                                   centos-6-x86_64-os                            27 k
 pango                                                    x86_64                      1.28.1-10.el6                                  centos-6-x86_64-os                           351 k
 perl-Config-General                                      noarch                      2.52-1.el6                                     centos-6-x86_64-os                            72 k
 perl-Crypt-OpenSSL-Bignum                                x86_64                      0.04-8.1.el6                                   centos-6-x86_64-os                            34 k
 perl-Crypt-OpenSSL-RSA                                   x86_64                      0.25-10.1.el6                                  centos-6-x86_64-os                            37 k
 perl-Crypt-OpenSSL-Random                                x86_64                      0.04-9.1.el6                                   centos-6-x86_64-os                            22 k
 perl-Time-HiRes                                          x86_64                      4:1.9721-136.el6_6.1                           centos-6-x86_64-updates                       48 k
 pixman                                                   x86_64                      0.32.4-4.el6                                   centos-6-x86_64-os                           243 k
 portreserve                                              x86_64                      0.0.4-9.el6                                    centos-6-x86_64-os                            23 k
 postgresql91                                             x86_64                      9.1.9-1PGDG.el6                                eucalyptus                                   983 k
 postgresql91-libs                                        x86_64                      9.1.9-1PGDG.el6                                eucalyptus                                   190 k
 postgresql91-server                                      x86_64                      9.1.9-1PGDG.el6                                eucalyptus                                   3.6 M
 pulseaudio-libs                                          x86_64                      0.9.21-17.el6                                  centos-6-x86_64-os                           462 k
 pyOpenSSL                                                x86_64                      0.10-2.el6                                     centos-6-x86_64-os                           212 k
 python-argparse                                          noarch                      1.2.1-2.el6.centos                             extras                                        48 k
 python-backports                                         x86_64                      1.0-3.el6.centos                               extras                                       5.3 k
 python-backports-ssl_match_hostname                      noarch                      3.4.0.2-4.el6.centos                           extras                                        13 k
 python-beaker                                            noarch                      1.3.1-7.el6                                    centos-6-x86_64-os                            72 k
 python-beaker15                                          noarch                      1.5.4-8.2.el6                                  eucalyptus                                    81 k
 python-boto                                              noarch                      2.34.0-4.el6                                   epel-6-x86_64                                1.7 M
 python-chameleon                                         noarch                      2.5.3-1.el6.2                                  epel-6-x86_64                                216 k
 python-chardet                                           noarch                      2.0.1-1.el6.centos                             extras                                       225 k
 python-crypto                                            x86_64                      2.0.1-22.el6                                   centos-6-x86_64-os                           159 k
 python-dateutil                                          noarch                      1.4.1-6.el6                                    centos-6-x86_64-os                            84 k
 python-gevent                                            x86_64                      0.13.8-3.el6                                   epel-6-x86_64                                189 k
 python-greenlet                                          x86_64                      0.4.2-1.el6                                    epel-6-x86_64                                 24 k
 python-gunicorn                                          noarch                      18.0-1.el6                                     epel-6-x86_64                                175 k
 python-lxml                                              x86_64                      2.2.3-1.1.el6                                  centos-6-x86_64-os                           2.0 M
 python-mako0.4                                           noarch                      0.4.2-7.el6                                    epel-6-x86_64                                264 k
 python-markupsafe                                        x86_64                      0.9.2-4.el6                                    centos-6-x86_64-os                            22 k
 python-ordereddict                                       noarch                      1.1-2.el6.centos                               extras                                       7.7 k
 python-paste                                             noarch                      1.7.4-2.el6                                    centos-6-x86_64-os                           758 k
 python-paste-deploy1.5                                   noarch                      1.5.0-5.el6                                    epel-6-x86_64                                 47 k
 python-progressbar                                       noarch                      2.3-2.el6                                      epel-6-x86_64                                 20 k
 python-pyramid                                           noarch                      1.4-9.el6                                      epel-6-x86_64                                874 k
 python-pyramid-beaker                                    noarch                      0.8-0.1.el6                                    eucalyptus                                    16 k
 python-pyramid-chameleon                                 noarch                      0.1-1.el6                                      epel-6-x86_64                                 29 k
 python-pyramid-layout                                    noarch                      0.8-0.1.el6                                    eucalyptus                                    35 k
 python-pyramid-tm                                        noarch                      0.7-2.el6                                      epel-6-x86_64                                 28 k
 python-repoze-lru                                        noarch                      0.4-3.el6                                      epel-6-x86_64                                 13 k
 python-requestbuilder                                    noarch                      0.2.3-0.1.el6                                  euca2ools                                     65 k
 python-requests                                          noarch                      1.1.0-4.el6.centos                             extras                                        71 k
 python-rsa                                               noarch                      3.1.1-5.el6                                    epel-6-x86_64                                 60 k
 python-setuptools                                        noarch                      0.6.10-3.el6                                   centos-6-x86_64-os                           336 k
 python-simplejson                                        x86_64                      2.0.9-3.1.el6                                  centos-6-x86_64-os                           126 k
 python-six                                               noarch                      1.7.3-1.el6.centos                             extras                                        27 k
 python-transaction                                       noarch                      1.0.1-1.el6                                    centos-6-x86_64-os                            57 k
 python-translationstring                                 noarch                      0.4-1.el6                                      epel-6-x86_64                                 25 k
 python-unittest2                                         noarch                      0.5.1-3.el6                                    epel-6-x86_64                                138 k
 python-urllib3                                           noarch                      1.5-7.el6.centos                               extras                                        41 k
 python-venusian                                          noarch                      1.0-0.4.a3.el6                                 epel-6-x86_64                                 55 k
 python-webob1.2                                          noarch                      1.2.3-2.el6                                    epel-6-x86_64                                211 k
 python-wtforms                                           noarch                      1.0.2-1.el6                                    epel-6-x86_64                                392 k
 python-zope-component                                    noarch                      4.0.2-2.el6                                    epel-6-x86_64                                114 k
 python-zope-configuration                                noarch                      3.7.2-4.el6                                    epel-6-x86_64                                 57 k
 python-zope-deprecation                                  noarch                      3.5.1-1.el6                                    epel-6-x86_64                                 15 k
 python-zope-event                                        noarch                      3.5.1-5.el6                                    epel-6-x86_64                                 48 k
 python-zope-filesystem                                   x86_64                      1-5.el6                                        centos-6-x86_64-os                           5.4 k
 python-zope-i18nmessageid                                x86_64                      3.5.3-6.el6                                    epel-6-x86_64                                 19 k
 python-zope-interface                                    x86_64                      3.5.2-2.1.el6                                  centos-6-x86_64-os                           116 k
 python-zope-interface4                                   x86_64                      4.0.4-1.el6                                    epel-6-x86_64                                259 k
 python-zope-schema                                       noarch                      3.8.1-3.el6                                    epel-6-x86_64                                100 k
 rampartc                                                 x86_64                      1.3.0-0.5.el6                                  eucalyptus                                   152 k
 scsi-target-utils                                        x86_64                      1.0.24-16.el6                                  centos-6-x86_64-os                           176 k
 sg3_utils                                                x86_64                      1.28-6.el6                                     centos-6-x86_64-os                           475 k
 ttmkfdir                                                 x86_64                      3.0.9-32.1.el6                                 centos-6-x86_64-os                            43 k
 tzdata-java                                              noarch                      2014j-1.el6                                    centos-6-x86_64-updates                      175 k
 vtun                                                     x86_64                      3.0.1-7.el6                                    epel-6-x86_64                                 57 k
 xinetd                                                   x86_64                      2:2.3.14-39.el6_4                              centos-6-x86_64-os                           121 k
 xorg-x11-font-utils                                      x86_64                      1:7.2-11.el6                                   centos-6-x86_64-os                            75 k
 xorg-x11-fonts-Type1                                     noarch                      7.2-9.1.el6                                    centos-6-x86_64-os                           520 k

Transaction Summary
========================================================================================================================================================================================
Install     136 Package(s)

Total download size: 134 M
Installed size: 324 M
Downloading Packages:
(1/136): PyGreSQL-3.8.1-2.el6.x86_64.rpm                                                                                                                         |  63 kB     00:00     
(2/136): apr-1.3.9-5.el6_2.x86_64.rpm                                                                                                                            | 123 kB     00:00     
(3/136): apr-util-1.3.9-3.el6_0.1.x86_64.rpm                                                                                                                     |  87 kB     00:00     
(4/136): apr-util-ldap-1.3.9-3.el6_0.1.x86_64.rpm                                                                                                                |  15 kB     00:00     
(5/136): atk-1.30.0-1.el6.x86_64.rpm                                                                                                                             | 195 kB     00:00     
(6/136): axis2c-1.6.0-0.7.el6.x86_64.rpm                                                                                                                         | 524 kB     00:00     
(7/136): cairo-1.8.8-3.1.el6.x86_64.rpm                                                                                                                          | 309 kB     00:00     
(8/136): dejavu-fonts-common-2.30-2.el6.noarch.rpm                                                                                                               |  59 kB     00:00     
(9/136): dejavu-serif-fonts-2.30-2.el6.noarch.rpm                                                                                                                | 827 kB     00:00     
(10/136): device-mapper-multipath-0.4.9-80.el6_6.2.x86_64.rpm                                                                                                    | 122 kB     00:00     
(11/136): device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64.rpm                                                                                               | 189 kB     00:00     
(12/136): dhcp-4.1.1-43.P1.el6.centos.x86_64.rpm                                                                                                                 | 819 kB     00:00     
(13/136): drbd83-utils-8.3.16-1.el6.elrepo.x86_64.rpm                                                                                                            | 219 kB     00:00     
(14/136): euca2ools-3.1.1-0.0.1562.15.el6.noarch.rpm                                                                                                             | 666 kB     00:00     
(15/136): eucaconsole-4.0.2-0.0.3341.15.el6.noarch.rpm                                                                                                           | 1.6 MB     00:01     
(16/136): eucalyptus-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                           | 101 kB     00:00     
(17/136): eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch.rpm                                                                                               | 164 kB     00:00     
(18/136): eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                             | 166 kB     00:00     
(19/136): eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                            |  29 kB     00:00     
(20/136): eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                        | 1.8 MB     00:01     
(21/136): eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                                     |  17 kB     00:00     
(22/136): eucalyptus-common-java-4.0.2-0.0.22283.44.el6.x86_64.rpm                                                                                               |  59 kB     00:00     
(23/136): eucalyptus-common-java-libs-4.0.2-0.0.22283.44 (27%) 38% [=================-                            ] 1.2 MB/s |                        ] 1.2 MB/s |  29 MB     00:39 ETA (23/136): eucalyptus-common-java-libs-4.0.2-0.0.22283.44 (27%) 39% [==================                            ] 1.2 MB/s | (23/136): eucalyptus-common-java-libs-4.0.2-0.0.22283.44 (28%) 39% [==================                            ] 1.1 MB/s | (23/136): eucalyptus-common-java-libs-4.0.2-0 (28%) 41% [==============-                     ] 1.1 MB/s |  31 MB     00:38 ETA (23/136): eucalyptus-common-java-libs-4.0. (29%) 42% [=============-                   ] 1.1 MB/s |  32 MB     00:37 ETA (23/136): eucalyptus-common-java-libs-4.0. (29%) 42% [==============                   ] 1.1 MB/s |  32 MB     00:37 ET(23/136): eucalyptus-common-java-libs-4.0. (30%) 43% [==============                   ] 1.1 MB/s |  32 MB     00:37 ETA(23/136): eucalyptus-common-java-libs-4.0.2-0.0.22283.44.el6.x86_64.rpm                          |  75 MB     01:03     
(24/136): eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64.rpm                                        |  11 kB     00:00     
(25/136): eucalyptus-walrus-4.0.2-0.0.22283.44.el6.x86_64.rpm                                    |  12 kB     00:00     
(26/136): flac-1.2.1-6.1.el6.x86_64.rpm                                                          | 243 kB     00:00     
(27/136): fontconfig-2.8.0-5.el6.x86_64.rpm                                                      | 186 kB     00:00     
(28/136): fontpackages-filesystem-1.41-1.1.el6.noarch.rpm                                        | 8.8 kB     00:00     
(29/136): freetype-2.3.11-14.el6_3.1.x86_64.rpm                                                  | 359 kB     00:00     
(30/136): gdisk-0.8.10-1.el6.x86_64.rpm                                                          | 167 kB     00:00     
(31/136): giflib-4.1.6-3.1.el6.x86_64.rpm                                                        |  37 kB     00:00     
(32/136): gtk2-2.24.23-6.el6.x86_64.rpm                                                          | 3.2 MB     00:00     
(33/136): hicolor-icon-theme-0.11-1.1.el6.noarch.rpm                                             |  40 kB     00:00     
(34/136): httpd-2.2.15-39.el6.centos.x86_64.rpm                                                  | 825 kB     00:00     
(35/136): httpd-tools-2.2.15-39.el6.centos.x86_64.rpm                                            |  75 kB     00:00     
(36/136): iscsi-initiator-utils-6.2.0.873-13.el6.x86_64.rpm                                      | 719 kB     00:00     
(37/136): java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64.rpm                                   |  26 MB     00:00     
(38/136): jpackage-utils-1.7.5-3.12.el6.noarch.rpm                                               |  59 kB     00:00     
(39/136): kmod-drbd83-8.3.16-3.el6.elrepo.x86_64.rpm                                             | 173 kB     00:00     
(40/136): libICE-1.0.6-1.el6.x86_64.rpm                                                          |  53 kB     00:00     
(41/136): libSM-1.2.1-2.el6.x86_64.rpm                                                           |  37 kB     00:00     
(42/136): libXcomposite-0.4.3-4.el6.x86_64.rpm                                                   |  20 kB     00:00     
(43/136): libXcursor-1.1.14-2.1.el6.x86_64.rpm                                                   |  28 kB     00:00     
(44/136): libXdamage-1.1.3-4.el6.x86_64.rpm                                                      |  18 kB     00:00     
(45/136): libXext-1.3.2-2.1.el6.x86_64.rpm                                                       |  35 kB     00:00     
(46/136): libXfixes-5.0.1-2.1.el6.x86_64.rpm                                                     |  17 kB     00:00     
(47/136): libXfont-1.4.5-4.el6_6.x86_64.rpm                                                      | 137 kB     00:00     
(48/136): libXft-2.3.1-2.el6.x86_64.rpm                                                          |  55 kB     00:00     
(49/136): libXi-1.7.2-2.2.el6.x86_64.rpm                                                         |  37 kB     00:00     
(50/136): libXinerama-1.1.3-2.1.el6.x86_64.rpm                                                   |  13 kB     00:00     
(51/136): libXrandr-1.4.1-2.1.el6.x86_64.rpm                                                     |  23 kB     00:00     
(52/136): libXrender-0.9.8-2.1.el6.x86_64.rpm                                                    |  24 kB     00:00     
(53/136): libXtst-1.2.2-2.1.el6.x86_64.rpm                                                       |  19 kB     00:00     
(54/136): libasyncns-0.8-1.1.el6.x86_64.rpm                                                      |  24 kB     00:00     
(55/136): libevent-1.4.13-4.el6.x86_64.rpm                                                       |  66 kB     00:00     
(56/136): libfontenc-1.0.5-2.el6.x86_64.rpm                                                      |  24 kB     00:00     
(57/136): libibverbs-1.1.8-3.el6.x86_64.rpm                                                      |  52 kB     00:00     
(58/136): libogg-1.1.4-2.1.el6.x86_64.rpm                                                        |  21 kB     00:00     
(59/136): librdmacm-1.0.18.1-1.el6.x86_64.rpm                                                    |  57 kB     00:00     
(60/136): libselinux-python-2.0.94-5.8.el6.x86_64.rpm                                            | 203 kB     00:00     
(61/136): libsndfile-1.0.20-5.el6.x86_64.rpm                                                     | 233 kB     00:00     
(62/136): libthai-0.1.12-3.el6.x86_64.rpm                                                        | 183 kB     00:00     
(63/136): libvorbis-1.2.3-4.el6_2.1.x86_64.rpm                                                   | 168 kB     00:00     
(64/136): libxslt-1.1.26-2.el6_3.1.x86_64.rpm                                                    | 452 kB     00:00     
(65/136): m2crypto-0.20.2-9.el6.x86_64.rpm                                                       | 471 kB     00:00     
(66/136): mailcap-2.1.31-2.el6.noarch.rpm                                                        |  27 kB     00:00     
(67/136): pango-1.28.1-10.el6.x86_64.rpm                                                         | 351 kB     00:00     
(68/136): perl-Config-General-2.52-1.el6.noarch.rpm                                              |  72 kB     00:00     
(69/136): perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64.rpm                                      |  34 kB     00:00     
(70/136): perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64.rpm                                        |  37 kB     00:00     
(71/136): perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64.rpm                                      |  22 kB     00:00     
(72/136): perl-Time-HiRes-1.9721-136.el6_6.1.x86_64.rpm                                          |  48 kB     00:00     
(73/136): pixman-0.32.4-4.el6.x86_64.rpm                                                         | 243 kB     00:00     
(74/136): portreserve-0.0.4-9.el6.x86_64.rpm                                                     |  23 kB     00:00     
(75/136): postgresql91-9.1.9-1PGDG.el6.x86_64.rpm                                                | 983 kB     00:00     
(76/136): postgresql91-libs-9.1.9-1PGDG.el6.x86_64.rpm                                           | 190 kB     00:00     
(77/136): postgresql91-server-9.1.9-1PGDG.el6.x86_64.rpm                                         | 3.6 MB     00:03     
(78/136): pulseaudio-libs-0.9.21-17.el6.x86_64.rpm                                               | 462 kB     00:00     
(79/136): pyOpenSSL-0.10-2.el6.x86_64.rpm                                                        | 212 kB     00:00     
(80/136): python-argparse-1.2.1-2.el6.centos.noarch.rpm                                          |  48 kB     00:00     
(81/136): python-backports-1.0-3.el6.centos.x86_64.rpm                                           | 5.3 kB     00:00     
(82/136): python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch.rpm                    |  13 kB     00:00     
(83/136): python-beaker-1.3.1-7.el6.noarch.rpm                                                   |  72 kB     00:00     
(84/136): python-beaker15-1.5.4-8.2.el6.noarch.rpm                                               |  81 kB     00:00     
(85/136): python-boto-2.34.0-4.el6.noarch.rpm                                                    | 1.7 MB     00:00     
(86/136): python-chameleon-2.5.3-1.el6.2.noarch.rpm                                              | 216 kB     00:00     
(87/136): python-chardet-2.0.1-1.el6.centos.noarch.rpm                                           | 225 kB     00:00     
(88/136): python-crypto-2.0.1-22.el6.x86_64.rpm                                                  | 159 kB     00:00     
(89/136): python-dateutil-1.4.1-6.el6.noarch.rpm                                                 |  84 kB     00:00     
(90/136): python-gevent-0.13.8-3.el6.x86_64.rpm                                                  | 189 kB     00:00     
(91/136): python-greenlet-0.4.2-1.el6.x86_64.rpm                                                 |  24 kB     00:00     
(92/136): python-gunicorn-18.0-1.el6.noarch.rpm                                                  | 175 kB     00:00     
(93/136): python-lxml-2.2.3-1.1.el6.x86_64.rpm                                                   | 2.0 MB     00:00     
(94/136): python-mako0.4-0.4.2-7.el6.noarch.rpm                                                  | 264 kB     00:00     
(95/136): python-markupsafe-0.9.2-4.el6.x86_64.rpm                                               |  22 kB     00:00     
(96/136): python-ordereddict-1.1-2.el6.centos.noarch.rpm                                         | 7.7 kB     00:00     
(97/136): python-paste-1.7.4-2.el6.noarch.rpm                                                    | 758 kB     00:00     
(98/136): python-paste-deploy1.5-1.5.0-5.el6.noarch.rpm                                          |  47 kB     00:00     
(99/136): python-progressbar-2.3-2.el6.noarch.rpm                                                |  20 kB     00:00     
(100/136): python-pyramid-1.4-9.el6.noarch.rpm                                                   | 874 kB     00:00     
(101/136): python-pyramid-beaker-0.8-0.1.el6.noarch.rpm                                          |  16 kB     00:00     
(102/136): python-pyramid-chameleon-0.1-1.el6.noarch.rpm                                         |  29 kB     00:00     
(103/136): python-pyramid-layout-0.8-0.1.el6.noarch.rpm                                          |  35 kB     00:00     
(104/136): python-pyramid-tm-0.7-2.el6.noarch.rpm                                                |  28 kB     00:00     
(105/136): python-repoze-lru-0.4-3.el6.noarch.rpm                                                |  13 kB     00:00     
(106/136): python-requestbuilder-0.2.3-0.1.el6.noarch.rpm                                        |  65 kB     00:00     
(107/136): python-requests-1.1.0-4.el6.centos.noarch.rpm                                         |  71 kB     00:00     
(108/136): python-rsa-3.1.1-5.el6.noarch.rpm                                                     |  60 kB     00:00     
(109/136): python-setuptools-0.6.10-3.el6.noarch.rpm                                             | 336 kB     00:00     
(110/136): python-simplejson-2.0.9-3.1.el6.x86_64.rpm                                            | 126 kB     00:00     
(111/136): python-six-1.7.3-1.el6.centos.noarch.rpm                                              |  27 kB     00:00     
(112/136): python-transaction-1.0.1-1.el6.noarch.rpm                                             |  57 kB     00:00     
(113/136): python-translationstring-0.4-1.el6.noarch.rpm                                         |  25 kB     00:00     
(114/136): python-unittest2-0.5.1-3.el6.noarch.rpm                                               | 138 kB     00:00     
(115/136): python-urllib3-1.5-7.el6.centos.noarch.rpm                                            |  41 kB     00:00     
(116/136): python-venusian-1.0-0.4.a3.el6.noarch.rpm                                             |  55 kB     00:00     
(117/136): python-webob1.2-1.2.3-2.el6.noarch.rpm                                                | 211 kB     00:00     
(118/136): python-wtforms-1.0.2-1.el6.noarch.rpm                                                 | 392 kB     00:00     
(119/136): python-zope-component-4.0.2-2.el6.noarch.rpm                                          | 114 kB     00:00     
(120/136): python-zope-configuration-3.7.2-4.el6.noarch.rpm                                      |  57 kB     00:00     
(121/136): python-zope-deprecation-3.5.1-1.el6.noarch.rpm                                        |  15 kB     00:00     
(122/136): python-zope-event-3.5.1-5.el6.noarch.rpm                                              |  48 kB     00:00     
(123/136): python-zope-filesystem-1-5.el6.x86_64.rpm                                             | 5.4 kB     00:00     
(124/136): python-zope-i18nmessageid-3.5.3-6.el6.x86_64.rpm                                      |  19 kB     00:00     
(125/136): python-zope-interface-3.5.2-2.1.el6.x86_64.rpm                                        | 116 kB     00:00     
(126/136): python-zope-interface4-4.0.4-1.el6.x86_64.rpm                                         | 259 kB     00:00     
(127/136): python-zope-schema-3.8.1-3.el6.noarch.rpm                                             | 100 kB     00:00     
(128/136): rampartc-1.3.0-0.5.el6.x86_64.rpm                                                     | 152 kB     00:00     
(129/136): scsi-target-utils-1.0.24-16.el6.x86_64.rpm                                            | 176 kB     00:00     
(130/136): sg3_utils-1.28-6.el6.x86_64.rpm                                                       | 475 kB     00:00     
(131/136): ttmkfdir-3.0.9-32.1.el6.x86_64.rpm                                                    |  43 kB     00:00     
(132/136): tzdata-java-2014j-1.el6.noarch.rpm                                                    | 175 kB     00:00     
(133/136): vtun-3.0.1-7.el6.x86_64.rpm                                                           |  57 kB     00:00     
(134/136): xinetd-2.3.14-39.el6_4.x86_64.rpm                                                     | 121 kB     00:00     
(135/136): xorg-x11-font-utils-7.2-11.el6.x86_64.rpm                                             |  75 kB     00:00     
(136/136): xorg-x11-fonts-Type1-7.2-9.1.el6.noarch.rpm                                           | 520 kB     00:00     
------------------------------------------------------------------------------------------------------------------------
Total                                                                                   1.8 MB/s | 134 MB     01:15     
warning: rpmts_HdrFromFdno: Header V3 RSA/SHA1 Signature, key ID c1240596: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-eucalyptus-release
Importing GPG key 0xC1240596:
 Userid : Eucalyptus Systems, Inc. (release key) <security@eucalyptus.com>
 Package: eucalyptus-release-4.0-1.el6.noarch (@/eucalyptus-release-4.0-1.el6.noarch)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-eucalyptus-release
warning: rpmts_HdrFromFdno: Header V3 RSA/SHA1 Signature, key ID c105b9de: NOKEY
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
Importing GPG key 0xC105B9DE:
 Userid : CentOS-6 Key (CentOS 6 Official Signing Key) <centos-6-key@centos.org>
 Package: centos-release-6-6.el6.centos.12.2.x86_64 (@anaconda-CentOS-201410241409.x86_64/6.6)
 From   : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : freetype-2.3.11-14.el6_3.1.x86_64                                                                  1/136 
  Installing : eucalyptus-4.0.2-0.0.22283.44.el6.x86_64                                                           2/136 
  Installing : python-setuptools-0.6.10-3.el6.noarch                                                              3/136 
  Installing : libXrender-0.9.8-2.1.el6.x86_64                                                                    4/136 
  Installing : fontconfig-2.8.0-5.el6.x86_64                                                                      5/136 
  Installing : libXext-1.3.2-2.1.el6.x86_64                                                                       6/136 
  Installing : python-ordereddict-1.1-2.el6.centos.noarch                                                         7/136 
  Installing : libXi-1.7.2-2.2.el6.x86_64                                                                         8/136 
  Installing : libICE-1.0.6-1.el6.x86_64                                                                          9/136 
  Installing : apr-1.3.9-5.el6_2.x86_64                                                                          10/136 
  Installing : apr-util-1.3.9-3.el6_0.1.x86_64                                                                   11/136 
  Installing : libXfixes-5.0.1-2.1.el6.x86_64                                                                    12/136 
  Installing : 2:libogg-1.1.4-2.1.el6.x86_64                                                                     13/136 
  Installing : axis2c-1.6.0-0.7.el6.x86_64                                                                       14/136 
  Installing : python-six-1.7.3-1.el6.centos.noarch                                                              15/136 
  Installing : postgresql91-libs-9.1.9-1PGDG.el6.x86_64                                                          16/136 
  Installing : python-zope-event-3.5.1-5.el6.noarch                                                              17/136 
  Installing : python-zope-interface4-4.0.4-1.el6.x86_64                                                         18/136 
  Installing : postgresql91-9.1.9-1PGDG.el6.x86_64                                                               19/136 
  Installing : rampartc-1.3.0-0.5.el6.x86_64                                                                     20/136 
  Installing : libSM-1.2.1-2.el6.x86_64                                                                          21/136 
  Installing : libXtst-1.2.2-2.1.el6.x86_64                                                                      22/136 
  Installing : mailcap-2.1.31-2.el6.noarch                                                                       23/136 
  Installing : python-argparse-1.2.1-2.el6.centos.noarch                                                         24/136 
  Installing : drbd83-utils-8.3.16-1.el6.elrepo.x86_64                                                           25/136 
  Installing : libfontenc-1.0.5-2.el6.x86_64                                                                     26/136 
  Installing : jpackage-utils-1.7.5-3.12.el6.noarch                                                              27/136 
  Installing : atk-1.30.0-1.el6.x86_64                                                                           28/136 
  Installing : m2crypto-0.20.2-9.el6.x86_64                                                                      29/136 
  Installing : python-greenlet-0.4.2-1.el6.x86_64                                                                30/136 
  Installing : python-translationstring-0.4-1.el6.noarch                                                         31/136 
  Installing : python-crypto-2.0.1-22.el6.x86_64                                                                 32/136 
  Installing : python-venusian-1.0-0.4.a3.el6.noarch                                                             33/136 
  Installing : perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64                                                     34/136 
  Installing : libibverbs-1.1.8-3.el6.x86_64                                                                     35/136 
  Installing : librdmacm-1.0.18.1-1.el6.x86_64                                                                   36/136 
  Installing : libXfont-1.4.5-4.el6_6.x86_64                                                                     37/136 
  Installing : 1:xorg-x11-font-utils-7.2-11.el6.x86_64                                                           38/136 
  Installing : kmod-drbd83-8.3.16-3.el6.elrepo.x86_64                                                            39/136 
Working. This may take some time ...
Done.
  Installing : giflib-4.1.6-3.1.el6.x86_64                                                                       40/136 
  Installing : postgresql91-server-9.1.9-1PGDG.el6.x86_64                                                        41/136 
  Installing : PyGreSQL-3.8.1-2.el6.x86_64                                                                       42/136 
  Installing : flac-1.2.1-6.1.el6.x86_64                                                                         43/136 
  Installing : 1:libvorbis-1.2.3-4.el6_2.1.x86_64                                                                44/136 
  Installing : libsndfile-1.0.20-5.el6.x86_64                                                                    45/136 
  Installing : libXdamage-1.1.3-4.el6.x86_64                                                                     46/136 
  Installing : libXcursor-1.1.14-2.1.el6.x86_64                                                                  47/136 
  Installing : apr-util-ldap-1.3.9-3.el6_0.1.x86_64                                                              48/136 
  Installing : httpd-tools-2.2.15-39.el6.centos.x86_64                                                           49/136 
  Installing : httpd-2.2.15-39.el6.centos.x86_64                                                                 50/136 
  Installing : eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64                                            51/136 
  Installing : libXrandr-1.4.1-2.1.el6.x86_64                                                                    52/136 
  Installing : libXinerama-1.1.3-2.1.el6.x86_64                                                                  53/136 
  Installing : libXft-2.3.1-2.el6.x86_64                                                                         54/136 
  Installing : python-gunicorn-18.0-1.el6.noarch                                                                 55/136 
  Installing : ttmkfdir-3.0.9-32.1.el6.x86_64                                                                    56/136 
  Installing : xorg-x11-fonts-Type1-7.2-9.1.el6.noarch                                                           57/136 
  Installing : python-unittest2-0.5.1-3.el6.noarch                                                               58/136 
  Installing : python-zope-i18nmessageid-3.5.3-6.el6.x86_64                                                      59/136 
  Installing : perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64                                                     60/136 
  Installing : perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64                                                       61/136 
  Installing : python-dateutil-1.4.1-6.el6.noarch                                                                62/136 
  Installing : python-backports-1.0-3.el6.centos.x86_64                                                          63/136 
  Installing : python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch                                   64/136 
  Installing : python-urllib3-1.5-7.el6.centos.noarch                                                            65/136 
  Installing : python-beaker-1.3.1-7.el6.noarch                                                                  66/136 
  Installing : python-webob1.2-1.2.3-2.el6.noarch                                                                67/136 
  Installing : libthai-0.1.12-3.el6.x86_64                                                                       68/136 
  Installing : python-simplejson-2.0.9-3.1.el6.x86_64                                                            69/136 
  Installing : python-chardet-2.0.1-1.el6.centos.noarch                                                          70/136 
  Installing : python-requests-1.1.0-4.el6.centos.noarch                                                         71/136 
  Installing : python-requestbuilder-0.2.3-0.1.el6.noarch                                                        72/136 
  Installing : 4:perl-Time-HiRes-1.9721-136.el6_6.1.x86_64                                                       73/136 
  Installing : libasyncns-0.8-1.1.el6.x86_64                                                                     74/136 
  Installing : pulseaudio-libs-0.9.21-17.el6.x86_64                                                              75/136 
  Installing : libselinux-python-2.0.94-5.8.el6.x86_64                                                           76/136 
  Installing : eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64                                           77/136 
Retrigger failed udev events[  OK  ]
  Installing : python-zope-deprecation-3.5.1-1.el6.noarch                                                        78/136 
  Installing : 2:xinetd-2.3.14-39.el6_4.x86_64                                                                   79/136 
  Installing : vtun-3.0.1-7.el6.x86_64                                                                           80/136 
  Installing : libevent-1.4.13-4.el6.x86_64                                                                      81/136 
  Installing : python-gevent-0.13.8-3.el6.x86_64                                                                 82/136 
  Installing : sg3_utils-1.28-6.el6.x86_64                                                                       83/136 
  Installing : device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64                                              84/136 
  Installing : device-mapper-multipath-0.4.9-80.el6_6.2.x86_64                                                   85/136 
  Installing : python-wtforms-1.0.2-1.el6.noarch                                                                 86/136 
  Installing : libxslt-1.1.26-2.el6_3.1.x86_64                                                                   87/136 
  Installing : python-lxml-2.2.3-1.1.el6.x86_64                                                                  88/136 
  Installing : hicolor-icon-theme-0.11-1.1.el6.noarch                                                            89/136 
  Installing : python-rsa-3.1.1-5.el6.noarch                                                                     90/136 
  Installing : python-boto-2.34.0-4.el6.noarch                                                                   91/136 
  Installing : eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch                                              92/136 
  Installing : libXcomposite-0.4.3-4.el6.x86_64                                                                  93/136 
  Installing : portreserve-0.0.4-9.el6.x86_64                                                                    94/136 
  Installing : 12:dhcp-4.1.1-43.P1.el6.centos.x86_64                                                             95/136 
  Installing : python-progressbar-2.3-2.el6.noarch                                                               96/136 
  Installing : perl-Config-General-2.52-1.el6.noarch                                                             97/136 
  Installing : scsi-target-utils-1.0.24-16.el6.x86_64                                                            98/136 
  Installing : fontpackages-filesystem-1.41-1.1.el6.noarch                                                       99/136 
  Installing : dejavu-fonts-common-2.30-2.el6.noarch                                                            100/136 
  Installing : dejavu-serif-fonts-2.30-2.el6.noarch                                                             101/136 
  Installing : tzdata-java-2014j-1.el6.noarch                                                                   102/136 
  Installing : pixman-0.32.4-4.el6.x86_64                                                                       103/136 
  Installing : cairo-1.8.8-3.1.el6.x86_64                                                                       104/136 
  Installing : pango-1.28.1-10.el6.x86_64                                                                       105/136 
  Installing : gtk2-2.24.23-6.el6.x86_64                                                                        106/136 
  Installing : 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64                                               107/136 
  Installing : eucalyptus-common-java-libs-4.0.2-0.0.22283.44.el6.x86_64                                        108/136 
  Installing : eucalyptus-common-java-4.0.2-0.0.22283.44.el6.x86_64                                             109/136 
  Installing : pyOpenSSL-0.10-2.el6.x86_64                                                                      110/136 
  Installing : python-paste-1.7.4-2.el6.noarch                                                                  111/136 
  Installing : python-beaker15-1.5.4-8.2.el6.noarch                                                             112/136 
  Installing : python-paste-deploy1.5-1.5.0-5.el6.noarch                                                        113/136 
  Installing : python-markupsafe-0.9.2-4.el6.x86_64                                                             114/136 
  Installing : python-mako0.4-0.4.2-7.el6.noarch                                                                115/136 
  Installing : iscsi-initiator-utils-6.2.0.873-13.el6.x86_64                                                    116/136 
  Installing : gdisk-0.8.10-1.el6.x86_64                                                                        117/136 
  Installing : euca2ools-3.1.1-0.0.1562.15.el6.noarch                                                           118/136 
  Installing : python-repoze-lru-0.4-3.el6.noarch                                                               119/136 
  Installing : python-zope-filesystem-1-5.el6.x86_64                                                            120/136 
  Installing : python-zope-interface-3.5.2-2.1.el6.x86_64                                                       121/136 
  Installing : python-chameleon-2.5.3-1.el6.2.noarch                                                            122/136 
  Installing : python-zope-component-4.0.2-2.el6.noarch                                                         123/136 
  Installing : python-zope-schema-3.8.1-3.el6.noarch                                                            124/136 
  Installing : python-zope-configuration-3.7.2-4.el6.noarch                                                     125/136 
  Installing : python-pyramid-1.4-9.el6.noarch                                                                  126/136 
  Installing : python-pyramid-chameleon-0.1-1.el6.noarch                                                        127/136 
  Installing : python-pyramid-layout-0.8-0.1.el6.noarch                                                         128/136 
  Installing : python-pyramid-beaker-0.8-0.1.el6.noarch                                                         129/136 
  Installing : python-transaction-1.0.1-1.el6.noarch                                                            130/136 
  Installing : python-pyramid-tm-0.7-2.el6.noarch                                                               131/136 
  Installing : eucaconsole-4.0.2-0.0.3341.15.el6.noarch                                                         132/136 
  Installing : eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64                                                   133/136 
  Installing : eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64                                                      134/136 
Starting SCSI target daemon: [  OK  ]
  Installing : eucalyptus-walrus-4.0.2-0.0.22283.44.el6.x86_64                                                  135/136 
  Installing : eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64                                                      136/136 
  Verifying  : python-chameleon-2.5.3-1.el6.2.noarch                                                              1/136 
  Verifying  : python-zope-filesystem-1-5.el6.x86_64                                                              2/136 
  Verifying  : python-repoze-lru-0.4-3.el6.noarch                                                                 3/136 
  Verifying  : libXdamage-1.1.3-4.el6.x86_64                                                                      4/136 
  Verifying  : apr-util-ldap-1.3.9-3.el6_0.1.x86_64                                                               5/136 
  Verifying  : libXrender-0.9.8-2.1.el6.x86_64                                                                    6/136 
  Verifying  : gdisk-0.8.10-1.el6.x86_64                                                                          7/136 
  Verifying  : python-beaker15-1.5.4-8.2.el6.noarch                                                               8/136 
  Verifying  : iscsi-initiator-utils-6.2.0.873-13.el6.x86_64                                                      9/136 
  Verifying  : python-zope-interface4-4.0.4-1.el6.x86_64                                                         10/136 
  Verifying  : python-markupsafe-0.9.2-4.el6.x86_64                                                              11/136 
  Verifying  : PyGreSQL-3.8.1-2.el6.x86_64                                                                       12/136 
  Verifying  : python-ordereddict-1.1-2.el6.centos.noarch                                                        13/136 
  Verifying  : 12:dhcp-4.1.1-43.P1.el6.centos.x86_64                                                             14/136 
  Verifying  : libibverbs-1.1.8-3.el6.x86_64                                                                     15/136 
  Verifying  : python-pyramid-chameleon-0.1-1.el6.noarch                                                         16/136 
  Verifying  : python-zope-event-3.5.1-5.el6.noarch                                                              17/136 
  Verifying  : libXtst-1.2.2-2.1.el6.x86_64                                                                      18/136 
  Verifying  : python-gunicorn-18.0-1.el6.noarch                                                                 19/136 
  Verifying  : euca2ools-3.1.1-0.0.1562.15.el6.noarch                                                            20/136 
  Verifying  : postgresql91-9.1.9-1PGDG.el6.x86_64                                                               21/136 
  Verifying  : libXrandr-1.4.1-2.1.el6.x86_64                                                                    22/136 
  Verifying  : python-zope-interface-3.5.2-2.1.el6.x86_64                                                        23/136 
  Verifying  : python-zope-configuration-3.7.2-4.el6.noarch                                                      24/136 
  Verifying  : pyOpenSSL-0.10-2.el6.x86_64                                                                       25/136 
  Verifying  : flac-1.2.1-6.1.el6.x86_64                                                                         26/136 
  Verifying  : perl-Crypt-OpenSSL-Random-0.04-9.1.el6.x86_64                                                     27/136 
  Verifying  : pixman-0.32.4-4.el6.x86_64                                                                        28/136 
  Verifying  : python-venusian-1.0-0.4.a3.el6.noarch                                                             29/136 
  Verifying  : python-zope-component-4.0.2-2.el6.noarch                                                          30/136 
  Verifying  : tzdata-java-2014j-1.el6.noarch                                                                    31/136 
  Verifying  : libSM-1.2.1-2.el6.x86_64                                                                          32/136 
  Verifying  : giflib-4.1.6-3.1.el6.x86_64                                                                       33/136 
  Verifying  : python-pyramid-layout-0.8-0.1.el6.noarch                                                          34/136 
  Verifying  : fontpackages-filesystem-1.41-1.1.el6.noarch                                                       35/136 
  Verifying  : httpd-tools-2.2.15-39.el6.centos.x86_64                                                           36/136 
  Verifying  : eucalyptus-sc-4.0.2-0.0.22283.44.el6.x86_64                                                       37/136 
  Verifying  : python-lxml-2.2.3-1.1.el6.x86_64                                                                  38/136 
  Verifying  : python-crypto-2.0.1-22.el6.x86_64                                                                 39/136 
  Verifying  : pango-1.28.1-10.el6.x86_64                                                                        40/136 
  Verifying  : eucalyptus-cloud-4.0.2-0.0.22283.44.el6.x86_64                                                    41/136 
  Verifying  : python-translationstring-0.4-1.el6.noarch                                                         42/136 
  Verifying  : eucaconsole-4.0.2-0.0.3341.15.el6.noarch                                                          43/136 
  Verifying  : pulseaudio-libs-0.9.21-17.el6.x86_64                                                              44/136 
  Verifying  : libXfont-1.4.5-4.el6_6.x86_64                                                                     45/136 
  Verifying  : perl-Config-General-2.52-1.el6.noarch                                                             46/136 
  Verifying  : python-progressbar-2.3-2.el6.noarch                                                               47/136 
  Verifying  : portreserve-0.0.4-9.el6.x86_64                                                                    48/136 
  Verifying  : libXcomposite-0.4.3-4.el6.x86_64                                                                  49/136 
  Verifying  : postgresql91-libs-9.1.9-1PGDG.el6.x86_64                                                          50/136 
  Verifying  : python-rsa-3.1.1-5.el6.noarch                                                                     51/136 
  Verifying  : eucalyptus-common-java-libs-4.0.2-0.0.22283.44.el6.x86_64                                         52/136 
  Verifying  : python-zope-schema-3.8.1-3.el6.noarch                                                             53/136 
  Verifying  : freetype-2.3.11-14.el6_3.1.x86_64                                                                 54/136 
  Verifying  : python-setuptools-0.6.10-3.el6.noarch                                                             55/136 
  Verifying  : eucalyptus-axis2c-common-4.0.2-0.0.22283.44.el6.x86_64                                            56/136 
  Verifying  : libXcursor-1.1.14-2.1.el6.x86_64                                                                  57/136 
  Verifying  : python-greenlet-0.4.2-1.el6.x86_64                                                                58/136 
  Verifying  : python-gevent-0.13.8-3.el6.x86_64                                                                 59/136 
  Verifying  : libXft-2.3.1-2.el6.x86_64                                                                         60/136 
  Verifying  : hicolor-icon-theme-0.11-1.1.el6.noarch                                                            61/136 
  Verifying  : libxslt-1.1.26-2.el6_3.1.x86_64                                                                   62/136 
  Verifying  : eucalyptus-cc-4.0.2-0.0.22283.44.el6.x86_64                                                       63/136 
  Verifying  : python-urllib3-1.5-7.el6.centos.noarch                                                            64/136 
  Verifying  : python-wtforms-1.0.2-1.el6.noarch                                                                 65/136 
  Verifying  : m2crypto-0.20.2-9.el6.x86_64                                                                      66/136 
  Verifying  : python-paste-deploy1.5-1.5.0-5.el6.noarch                                                         67/136 
  Verifying  : device-mapper-multipath-libs-0.4.9-80.el6_6.2.x86_64                                              68/136 
  Verifying  : python-six-1.7.3-1.el6.centos.noarch                                                              69/136 
  Verifying  : sg3_utils-1.28-6.el6.x86_64                                                                       70/136 
  Verifying  : cairo-1.8.8-3.1.el6.x86_64                                                                        71/136 
  Verifying  : libevent-1.4.13-4.el6.x86_64                                                                      72/136 
  Verifying  : axis2c-1.6.0-0.7.el6.x86_64                                                                       73/136 
  Verifying  : 2:xinetd-2.3.14-39.el6_4.x86_64                                                                   74/136 
  Verifying  : python-mako0.4-0.4.2-7.el6.noarch                                                                 75/136 
  Verifying  : 2:libogg-1.1.4-2.1.el6.x86_64                                                                     76/136 
  Verifying  : libsndfile-1.0.20-5.el6.x86_64                                                                    77/136 
  Verifying  : apr-util-1.3.9-3.el6_0.1.x86_64                                                                   78/136 
  Verifying  : python-pyramid-1.4-9.el6.noarch                                                                   79/136 
  Verifying  : python-paste-1.7.4-2.el6.noarch                                                                   80/136 
  Verifying  : python-transaction-1.0.1-1.el6.noarch                                                             81/136 
  Verifying  : gtk2-2.24.23-6.el6.x86_64                                                                         82/136 
  Verifying  : libXfixes-5.0.1-2.1.el6.x86_64                                                                    83/136 
  Verifying  : librdmacm-1.0.18.1-1.el6.x86_64                                                                   84/136 
  Verifying  : python-zope-deprecation-3.5.1-1.el6.noarch                                                        85/136 
  Verifying  : kmod-drbd83-8.3.16-3.el6.elrepo.x86_64                                                            86/136 
  Verifying  : python-requestbuilder-0.2.3-0.1.el6.noarch                                                        87/136 
  Verifying  : dejavu-fonts-common-2.30-2.el6.noarch                                                             88/136 
  Verifying  : 1:libvorbis-1.2.3-4.el6_2.1.x86_64                                                                89/136 
  Verifying  : python-backports-ssl_match_hostname-3.4.0.2-4.el6.centos.noarch                                   90/136 
  Verifying  : eucalyptus-4.0.2-0.0.22283.44.el6.x86_64                                                          91/136 
  Verifying  : 1:java-1.7.0-openjdk-1.7.0.71-2.5.3.2.el6_6.x86_64                                                92/136 
  Verifying  : eucalyptus-common-java-4.0.2-0.0.22283.44.el6.x86_64                                              93/136 
  Verifying  : atk-1.30.0-1.el6.x86_64                                                                           94/136 
  Verifying  : python-pyramid-beaker-0.8-0.1.el6.noarch                                                          95/136 
  Verifying  : perl-Crypt-OpenSSL-RSA-0.25-10.1.el6.x86_64                                                       96/136 
  Verifying  : jpackage-utils-1.7.5-3.12.el6.noarch                                                              97/136 
  Verifying  : libselinux-python-2.0.94-5.8.el6.x86_64                                                           98/136 
  Verifying  : libasyncns-0.8-1.1.el6.x86_64                                                                     99/136 
  Verifying  : httpd-2.2.15-39.el6.centos.x86_64                                                                100/136 
  Verifying  : eucalyptus-blockdev-utils-4.0.2-0.0.22283.44.el6.x86_64                                          101/136 
  Verifying  : scsi-target-utils-1.0.24-16.el6.x86_64                                                           102/136 
  Verifying  : fontconfig-2.8.0-5.el6.x86_64                                                                    103/136 
  Verifying  : 4:perl-Time-HiRes-1.9721-136.el6_6.1.x86_64                                                      104/136 
  Verifying  : eucalyptus-admin-tools-4.0.2-0.0.22283.44.el6.noarch                                             105/136 
  Verifying  : postgresql91-server-9.1.9-1PGDG.el6.x86_64                                                       106/136 
  Verifying  : ttmkfdir-3.0.9-32.1.el6.x86_64                                                                   107/136 
  Verifying  : python-chardet-2.0.1-1.el6.centos.noarch                                                         108/136 
  Verifying  : libXext-1.3.2-2.1.el6.x86_64                                                                     109/136 
  Verifying  : libfontenc-1.0.5-2.el6.x86_64                                                                    110/136 
  Verifying  : python-simplejson-2.0.9-3.1.el6.x86_64                                                           111/136 
  Verifying  : rampartc-1.3.0-0.5.el6.x86_64                                                                    112/136 
  Verifying  : libthai-0.1.12-3.el6.x86_64                                                                      113/136 
  Verifying  : 1:xorg-x11-font-utils-7.2-11.el6.x86_64                                                          114/136 
  Verifying  : python-boto-2.34.0-4.el6.noarch                                                                  115/136 
  Verifying  : python-requests-1.1.0-4.el6.centos.noarch                                                        116/136 
  Verifying  : drbd83-utils-8.3.16-1.el6.elrepo.x86_64                                                          117/136 
  Verifying  : python-webob1.2-1.2.3-2.el6.noarch                                                               118/136 
  Verifying  : python-pyramid-tm-0.7-2.el6.noarch                                                               119/136 
  Verifying  : python-beaker-1.3.1-7.el6.noarch                                                                 120/136 
  Verifying  : python-argparse-1.2.1-2.el6.centos.noarch                                                        121/136 
  Verifying  : xorg-x11-fonts-Type1-7.2-9.1.el6.noarch                                                          122/136 
  Verifying  : apr-1.3.9-5.el6_2.x86_64                                                                         123/136 
  Verifying  : libXinerama-1.1.3-2.1.el6.x86_64                                                                 124/136 
  Verifying  : vtun-3.0.1-7.el6.x86_64                                                                          125/136 
  Verifying  : mailcap-2.1.31-2.el6.noarch                                                                      126/136 
  Verifying  : device-mapper-multipath-0.4.9-80.el6_6.2.x86_64                                                  127/136 
  Verifying  : eucalyptus-walrus-4.0.2-0.0.22283.44.el6.x86_64                                                  128/136 
  Verifying  : libXi-1.7.2-2.2.el6.x86_64                                                                       129/136 
  Verifying  : dejavu-serif-fonts-2.30-2.el6.noarch                                                             130/136 
  Verifying  : python-backports-1.0-3.el6.centos.x86_64                                                         131/136 
  Verifying  : python-dateutil-1.4.1-6.el6.noarch                                                               132/136 
  Verifying  : libICE-1.0.6-1.el6.x86_64                                                                        133/136 
  Verifying  : perl-Crypt-OpenSSL-Bignum-0.04-8.1.el6.x86_64                                                    134/136 
  Verifying  : python-zope-i18nmessageid-3.5.3-6.el6.x86_64                                                     135/136 
  Verifying  : python-unittest2-0.5.1-3.el6.noarch                                                              136/136 

Installed:
  eucaconsole.noarch 0:4.0.2-0.0.3341.15.el6                   eucalyptus-cc.x86_64 0:4.0.2-0.0.22283.44.el6           
  eucalyptus-cloud.x86_64 0:4.0.2-0.0.22283.44.el6             eucalyptus-sc.x86_64 0:4.0.2-0.0.22283.44.el6           
  eucalyptus-walrus.x86_64 0:4.0.2-0.0.22283.44.el6           

Dependency Installed:
  PyGreSQL.x86_64 0:3.8.1-2.el6                                                                                         
  apr.x86_64 0:1.3.9-5.el6_2                                                                                            
  apr-util.x86_64 0:1.3.9-3.el6_0.1                                                                                     
  apr-util-ldap.x86_64 0:1.3.9-3.el6_0.1                                                                                
  atk.x86_64 0:1.30.0-1.el6                                                                                             
  axis2c.x86_64 0:1.6.0-0.7.el6                                                                                         
  cairo.x86_64 0:1.8.8-3.1.el6                                                                                          
  dejavu-fonts-common.noarch 0:2.30-2.el6                                                                               
  dejavu-serif-fonts.noarch 0:2.30-2.el6                                                                                
  device-mapper-multipath.x86_64 0:0.4.9-80.el6_6.2                                                                     
  device-mapper-multipath-libs.x86_64 0:0.4.9-80.el6_6.2                                                                
  dhcp.x86_64 12:4.1.1-43.P1.el6.centos                                                                                 
  drbd83-utils.x86_64 0:8.3.16-1.el6.elrepo                                                                             
  euca2ools.noarch 0:3.1.1-0.0.1562.15.el6                                                                              
  eucalyptus.x86_64 0:4.0.2-0.0.22283.44.el6                                                                            
  eucalyptus-admin-tools.noarch 0:4.0.2-0.0.22283.44.el6                                                                
  eucalyptus-axis2c-common.x86_64 0:4.0.2-0.0.22283.44.el6                                                              
  eucalyptus-blockdev-utils.x86_64 0:4.0.2-0.0.22283.44.el6                                                             
  eucalyptus-common-java.x86_64 0:4.0.2-0.0.22283.44.el6                                                                
  eucalyptus-common-java-libs.x86_64 0:4.0.2-0.0.22283.44.el6                                                           
  flac.x86_64 0:1.2.1-6.1.el6                                                                                           
  fontconfig.x86_64 0:2.8.0-5.el6                                                                                       
  fontpackages-filesystem.noarch 0:1.41-1.1.el6                                                                         
  freetype.x86_64 0:2.3.11-14.el6_3.1                                                                                   
  gdisk.x86_64 0:0.8.10-1.el6                                                                                           
  giflib.x86_64 0:4.1.6-3.1.el6                                                                                         
  gtk2.x86_64 0:2.24.23-6.el6                                                                                           
  hicolor-icon-theme.noarch 0:0.11-1.1.el6                                                                              
  httpd.x86_64 0:2.2.15-39.el6.centos                                                                                   
  httpd-tools.x86_64 0:2.2.15-39.el6.centos                                                                             
  iscsi-initiator-utils.x86_64 0:6.2.0.873-13.el6                                                                       
  java-1.7.0-openjdk.x86_64 1:1.7.0.71-2.5.3.2.el6_6                                                                    
  jpackage-utils.noarch 0:1.7.5-3.12.el6                                                                                
  kmod-drbd83.x86_64 0:8.3.16-3.el6.elrepo                                                                              
  libICE.x86_64 0:1.0.6-1.el6                                                                                           
  libSM.x86_64 0:1.2.1-2.el6                                                                                            
  libXcomposite.x86_64 0:0.4.3-4.el6                                                                                    
  libXcursor.x86_64 0:1.1.14-2.1.el6                                                                                    
  libXdamage.x86_64 0:1.1.3-4.el6                                                                                       
  libXext.x86_64 0:1.3.2-2.1.el6                                                                                        
  libXfixes.x86_64 0:5.0.1-2.1.el6                                                                                      
  libXfont.x86_64 0:1.4.5-4.el6_6                                                                                       
  libXft.x86_64 0:2.3.1-2.el6                                                                                           
  libXi.x86_64 0:1.7.2-2.2.el6                                                                                          
  libXinerama.x86_64 0:1.1.3-2.1.el6                                                                                    
  libXrandr.x86_64 0:1.4.1-2.1.el6                                                                                      
  libXrender.x86_64 0:0.9.8-2.1.el6                                                                                     
  libXtst.x86_64 0:1.2.2-2.1.el6                                                                                        
  libasyncns.x86_64 0:0.8-1.1.el6                                                                                       
  libevent.x86_64 0:1.4.13-4.el6                                                                                        
  libfontenc.x86_64 0:1.0.5-2.el6                                                                                       
  libibverbs.x86_64 0:1.1.8-3.el6                                                                                       
  libogg.x86_64 2:1.1.4-2.1.el6                                                                                         
  librdmacm.x86_64 0:1.0.18.1-1.el6                                                                                     
  libselinux-python.x86_64 0:2.0.94-5.8.el6                                                                             
  libsndfile.x86_64 0:1.0.20-5.el6                                                                                      
  libthai.x86_64 0:0.1.12-3.el6                                                                                         
  libvorbis.x86_64 1:1.2.3-4.el6_2.1                                                                                    
  libxslt.x86_64 0:1.1.26-2.el6_3.1                                                                                     
  m2crypto.x86_64 0:0.20.2-9.el6                                                                                        
  mailcap.noarch 0:2.1.31-2.el6                                                                                         
  pango.x86_64 0:1.28.1-10.el6                                                                                          
  perl-Config-General.noarch 0:2.52-1.el6                                                                               
  perl-Crypt-OpenSSL-Bignum.x86_64 0:0.04-8.1.el6                                                                       
  perl-Crypt-OpenSSL-RSA.x86_64 0:0.25-10.1.el6                                                                         
  perl-Crypt-OpenSSL-Random.x86_64 0:0.04-9.1.el6                                                                       
  perl-Time-HiRes.x86_64 4:1.9721-136.el6_6.1                                                                           
  pixman.x86_64 0:0.32.4-4.el6                                                                                          
  portreserve.x86_64 0:0.0.4-9.el6                                                                                      
  postgresql91.x86_64 0:9.1.9-1PGDG.el6                                                                                 
  postgresql91-libs.x86_64 0:9.1.9-1PGDG.el6                                                                            
  postgresql91-server.x86_64 0:9.1.9-1PGDG.el6                                                                          
  pulseaudio-libs.x86_64 0:0.9.21-17.el6                                                                                
  pyOpenSSL.x86_64 0:0.10-2.el6                                                                                         
  python-argparse.noarch 0:1.2.1-2.el6.centos                                                                           
  python-backports.x86_64 0:1.0-3.el6.centos                                                                            
  python-backports-ssl_match_hostname.noarch 0:3.4.0.2-4.el6.centos                                                     
  python-beaker.noarch 0:1.3.1-7.el6                                                                                    
  python-beaker15.noarch 0:1.5.4-8.2.el6                                                                                
  python-boto.noarch 0:2.34.0-4.el6                                                                                     
  python-chameleon.noarch 0:2.5.3-1.el6.2                                                                               
  python-chardet.noarch 0:2.0.1-1.el6.centos                                                                            
  python-crypto.x86_64 0:2.0.1-22.el6                                                                                   
  python-dateutil.noarch 0:1.4.1-6.el6                                                                                  
  python-gevent.x86_64 0:0.13.8-3.el6                                                                                   
  python-greenlet.x86_64 0:0.4.2-1.el6                                                                                  
  python-gunicorn.noarch 0:18.0-1.el6                                                                                   
  python-lxml.x86_64 0:2.2.3-1.1.el6                                                                                    
  python-mako0.4.noarch 0:0.4.2-7.el6                                                                                   
  python-markupsafe.x86_64 0:0.9.2-4.el6                                                                                
  python-ordereddict.noarch 0:1.1-2.el6.centos                                                                          
  python-paste.noarch 0:1.7.4-2.el6                                                                                     
  python-paste-deploy1.5.noarch 0:1.5.0-5.el6                                                                           
  python-progressbar.noarch 0:2.3-2.el6                                                                                 
  python-pyramid.noarch 0:1.4-9.el6                                                                                     
  python-pyramid-beaker.noarch 0:0.8-0.1.el6                                                                            
  python-pyramid-chameleon.noarch 0:0.1-1.el6                                                                           
  python-pyramid-layout.noarch 0:0.8-0.1.el6                                                                            
  python-pyramid-tm.noarch 0:0.7-2.el6                                                                                  
  python-repoze-lru.noarch 0:0.4-3.el6                                                                                  
  python-requestbuilder.noarch 0:0.2.3-0.1.el6                                                                          
  python-requests.noarch 0:1.1.0-4.el6.centos                                                                           
  python-rsa.noarch 0:3.1.1-5.el6                                                                                       
  python-setuptools.noarch 0:0.6.10-3.el6                                                                               
  python-simplejson.x86_64 0:2.0.9-3.1.el6                                                                              
  python-six.noarch 0:1.7.3-1.el6.centos                                                                                
  python-transaction.noarch 0:1.0.1-1.el6                                                                               
  python-translationstring.noarch 0:0.4-1.el6                                                                           
  python-unittest2.noarch 0:0.5.1-3.el6                                                                                 
  python-urllib3.noarch 0:1.5-7.el6.centos                                                                              
  python-venusian.noarch 0:1.0-0.4.a3.el6                                                                               
  python-webob1.2.noarch 0:1.2.3-2.el6                                                                                  
  python-wtforms.noarch 0:1.0.2-1.el6                                                                                   
  python-zope-component.noarch 0:4.0.2-2.el6                                                                            
  python-zope-configuration.noarch 0:3.7.2-4.el6                                                                        
  python-zope-deprecation.noarch 0:3.5.1-1.el6                                                                          
  python-zope-event.noarch 0:3.5.1-5.el6                                                                                
  python-zope-filesystem.x86_64 0:1-5.el6                                                                               
  python-zope-i18nmessageid.x86_64 0:3.5.3-6.el6                                                                        
  python-zope-interface.x86_64 0:3.5.2-2.1.el6                                                                          
  python-zope-interface4.x86_64 0:4.0.4-1.el6                                                                           
  python-zope-schema.noarch 0:3.8.1-3.el6                                                                               
  rampartc.x86_64 0:1.3.0-0.5.el6                                                                                       
  scsi-target-utils.x86_64 0:1.0.24-16.el6                                                                              
  sg3_utils.x86_64 0:1.28-6.el6                                                                                         
  ttmkfdir.x86_64 0:3.0.9-32.1.el6                                                                                      
  tzdata-java.noarch 0:2014j-1.el6                                                                                      
  vtun.x86_64 0:3.0.1-7.el6                                                                                             
  xinetd.x86_64 2:2.3.14-39.el6_4                                                                                       
  xorg-x11-font-utils.x86_64 1:7.2-11.el6                                                                               
  xorg-x11-fonts-Type1.noarch 0:7.2-9.1.el6                                                                             

Complete!

Continue (y,n,q)[y]

============================================================

 3. Initialize the database
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca_conf --initialize

Execute (y,n,q)[y]

# euca_conf --initialize
Initializing a new cloud.  This may take a few minutes.
Initialize command succeeded

Continue (y,n,q)[y]

============================================================

 4. Start the Cloud Controller service
    - This step is only run on the Cloud Controller host
    - After starting services, wait until they  come up

============================================================

Commands:

chkconfig eucalyptus-cloud on

service eucalyptus-cloud start

Execute (y,n,q)[y]

# chkconfig eucalyptus-cloud on

# service eucalyptus-cloud start
Starting Eucalyptus services: done.

Waiting 60 seconds for user-facing services to come up

Testing services... Not yet running. Waiting another 15 seconds
Testing services... Not yet running. Waiting another 15 seconds
Testing services... Not yet running. Waiting another 15 seconds
Testing services... Not yet running. Waiting another 15 seconds
Testing services... Not yet running. Waiting another 15 seconds
Testing services... Started

Continue (y,n,q)[y]

============================================================

 5. Start the Cluster Controller service
    - This step is only run on the Cluster Controller host

============================================================

Commands:

chkconfig eucalyptus-cc on

service eucalyptus-cc start

Execute (y,n,q)[y]

# chkconfig eucalyptus-cc on

# service eucalyptus-cc start
Starting Eucalyptus cluster controller: done.

Continue (y,n,q)[y]

============================================================

 6. Register Walrus as the Object Storage Provider
    - This step is only run on the Cloud Controller host
    - Scan for the host key to prevent ssh unknown host prompt

============================================================

Commands:

ssh-keyscan 10.104.10.21 2> /dev/null >> /root/.ssh/known_hosts

euca_conf --register-walrusbackend --partition walrus --host 10.104.10.21 --component walrus

Execute (y,n,q)[y]

# ssh-keyscan 10.104.10.21 2> /dev/null >> /root/.ssh/known_hosts
#
# euca_conf --register-walrusbackend --partition walrus --host 10.104.10.21 --component walrus
Created new partition 'walrus'
SERVICE walrusbackend   walrus          walrus          ENABLED         22      http://10.104.10.21:8773/services/WalrusBackend arn:euca:bootstrap:walrus:walrusbackend:walrus/

Continue (y,n,q)[y]

============================================================

 7. Register User-Facing services
    - This step is only run on the Cloud Controller host
    - It is normal to see ERRORs for objectstorage, imaging
      and loadbalancingbackend at this point, as they require
      further configuration

============================================================

Commands:

euca_conf --register-service -T user-api -H 10.104.10.21 -N PODAPI

Execute (y,n,q)[y]

# euca_conf --register-service -T user-api -H 10.104.10.21 -N PODAPI
warning: No credentials found; attempting local authentication
Created new partition 'PODAPI'
SERVICE user-api                PODAPI          PODAPI                  http://10.104.10.21:8773/services/User-API     arn:euca:bootstrap:PODAPI:user-api:PODAPI/
SERVICE compute                 PODAPI          PODAPI.compute          http://10.104.10.21:8773/services/compute      arn:euca:bootstrap:PODAPI:compute:PODAPI.compute/
SERVICE cloudwatch              PODAPI          PODAPI.cloudwatch       http://10.104.10.21:8773/services/CloudWatch   arn:euca:bootstrap:PODAPI:cloudwatch:PODAPI.cloudwatch/
SERVICE autoscaling             PODAPI          PODAPI.autoscaling      http://10.104.10.21:8773/services/AutoScaling  arn:euca:bootstrap:PODAPI:autoscaling:PODAPI.autoscaling/
SERVICE objectstorage           PODAPI          PODAPI.objectstorage    http://10.104.10.21:8773/services/objectstoragearn:euca:bootstrap:PODAPI:objectstorage:PODAPI.objectstorage/
SERVICE euare                   PODAPI          PODAPI.euare            http://10.104.10.21:8773/services/Euare arn:euca:bootstrap:PODAPI:euare:PODAPI.euare/
SERVICE tokens                  PODAPI          PODAPI.tokens           http://10.104.10.21:8773/services/Tokens       arn:euca:bootstrap:PODAPI:tokens:PODAPI.tokens/
SERVICE loadbalancing           PODAPI          PODAPI.loadbalancing    http://10.104.10.21:8773/services/LoadBalancingarn:euca:bootstrap:PODAPI:loadbalancing:PODAPI.loadbalancing/
ERROR   objectstorage           PODAPI          PODAPI.objectstorage    OSG object storage provider client not configured. Found property 'objectstorage.providerclient' empty or unset manager(null).  Legal values are: riakcs,ceph-rgw,walrus,s3
ERROR   loadbalancingbackend    eucalyptus      10.104.10.21            ERR-1014 2015-01-16 00:36:16 Load balancer image not configured.  LoadBalancing service will not be available.
ERROR   loadbalancingbackend    eucalyptus      10.104.10.21            LoadBalancingPropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: loadbalancingbackend
ERROR   imaging                 eucalyptus      10.104.10.21            ImagingServicePropertyBootstrapper.enable( ): returned false, terminating bootstrap for component: imaging
ERROR   imaging                 eucalyptus      10.104.10.21            ERR-1015 2015-01-16 00:36:16 Imaging worker image not configured.  Imaging service will not be available.

Continue (y,n,q)[y]

============================================================

 8. Register Cluster Controller service
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca_conf --register-cluster --partition AZ1 --host  --component PODCC

Execute (y,n,q)[y]

# euca_conf --register-cluster --partition AZ1 --host 10.104.10.21 --component PODCC
Created new partition 'AZ1'
SERVICE cluster         AZ1             PODCC           NOTREADY        24      http://10.104.10.21:8774/axis2/services/EucalyptusCC    arn:euca:eucalyptus:AZ1:cluster:PODCC/

Continue (y,n,q)[y]

============================================================

 9. Register Storage Controller service
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca_conf --register-sc --partition AZ1 --host 10.104.10.21 --component PODSC

Execute (y,n,q)[y]

# euca_conf --register-sc --partition AZ1 --host 10.104.10.21 --component PODSC
SERVICE storage         AZ1             PODSC           BROKEN          26      http://10.104.10.21:8773/services/Storage       arn:euca:eucalyptus:AZ1:storage:PODSC/
Registered the first storage controller in partition 'AZ1'.  You must choose a storage back end with ``euca-modify-property -p AZ1.storage.blockstoragemanager=$BACKEND''

Continue (y,n,q)[y]

============================================================

10. Register Node Controller host(s)
    - This step is only run on the Cloud Controller host
    - NOTE! After completing this step, you will need to run
      the next step on all Node Controller hosts before you
      continue here
    - Scan for the host key to prevent ssh unknown host prompt

============================================================

Commands:

ssh-keyscan 10.105.10.23 2> /dev/null >> /root/.ssh/known_hosts

euca_conf --register-nodes="10.105.10.23"

Execute (y,n,q)[y]

# ssh-keyscan 10.105.10.23 2> /dev/null >> /root/.ssh/known_hosts
#
# euca_conf --register-nodes="10.105.10.23"
INFO: We expect all nodes to have eucalyptus installed in $EUCALYPTUS for key synchronization.
...done

Continue (y,n,q)[y]

============================================================

12. Confirm service status
    - This step is only run on the Cloud Controller host
    - NOTE: This step should only be run after the step
      which starts the Node Controller service on all Node
      Controller hosts
    - The following services should be in a NOTREADY state:
      - cluster, loadbalancingbackend, imaging
    - The following services should be in a BROKEN state:
      - storage, objectstorage
    - This is normal at this point in time, with partial configuration
    - Some output truncated for clarity

============================================================

Commands:

euca-describe-services | cut -f 1-5

Execute (y,n,q)[y]

# euca-describe-services | cut -f 1-5
SERVICE cluster                 AZ1             PODCC                   NOTREADY
SERVICE storage                 AZ1             PODSC                   BROKEN  
SERVICE user-api                PODAPI          PODAPI                  ENABLED 
SERVICE autoscaling             PODAPI          PODAPI.autoscaling      ENABLED 
SERVICE cloudwatch              PODAPI          PODAPI.cloudwatch       ENABLED 
SERVICE compute                 PODAPI          PODAPI.compute          ENABLED 
SERVICE euare                   PODAPI          PODAPI.euare            ENABLED 
SERVICE loadbalancing           PODAPI          PODAPI.loadbalancing    ENABLED 
SERVICE objectstorage           PODAPI          PODAPI.objectstorage    BROKEN  
SERVICE tokens                  PODAPI          PODAPI.tokens           ENABLED 
SERVICE bootstrap               bootstrap       10.104.10.21            ENABLED 
SERVICE reporting               bootstrap       10.104.10.21            ENABLED 
SERVICE notifications           eucalyptus      10.104.10.21            ENABLED 
SERVICE jetty                   eucalyptus      10.104.10.21            ENABLED 
SERVICE dns                     eucalyptus      10.104.10.21            ENABLED 
SERVICE eucalyptus              eucalyptus      10.104.10.21            ENABLED 
SERVICE autoscalingbackend      eucalyptus      10.104.10.21            ENABLED 
SERVICE cloudwatchbackend       eucalyptus      10.104.10.21            ENABLED 
SERVICE loadbalancingbackend    eucalyptus      10.104.10.21            NOTREADY
SERVICE imaging                 eucalyptus      10.104.10.21            NOTREADY
SERVICE walrusbackend           walrus          walrus                  ENABLED 

Continue (y,n,q)[y]

Installation and initial configuration complete
