[root@odc-f-34 ~]# euca-faststart-03-configure-dns.sh -I
Found Eucalyptus Administrator credentials

============================================================

  1. Use Administrator credentials

============================================================

Commands:

source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

# source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

============================================================

  2. Configure DNS Domain and SubDomain

============================================================

Commands:

euca-modify-property -p system.dns.dnsdomain = mjcfc.cs.prc.eucalyptus-systems.com

euca-modify-property -p loadbalancing.loadbalancer_dns_subdomain = lb

Continuing in  1 seconds...

# euca-modify-property -p system.dns.dnsdomain=mjcfc.cs.prc.eucalyptus-systems.com
PROPERTY        system.dns.dnsdomain    mjcfc.cs.prc.eucalyptus-systems.com was localhost

# euca-modify-property -p loadbalancing.loadbalancer_dns_subdomain=lb
PROPERTY        loadbalancing.loadbalancer_dns_subdomain        lb was lb

Continuing in  1 seconds...

============================================================

  3. Turn on IP Mapping

============================================================

Commands:

euca-modify-property -p bootstrap.webservices.use_instance_dns=true

euca-modify-property -p cloud.vmstate.instance_subdomain=.cloud

Continuing in  1 seconds...

# euca-modify-property -p bootstrap.webservices.use_instance_dns=true
PROPERTY        bootstrap.webservices.use_instance_dns  true was false

# euca-modify-property -p cloud.vmstate.instance_subdomain=.cloud
PROPERTY        cloud.vmstate.instance_subdomain        .cloud was .eucalyptus

Continuing in  1 seconds...

============================================================

  4. Enable DNS Delegation

============================================================

Commands:

euca-modify-property -p bootstrap.webservices.use_dns_delegation=true

Continuing in  1 seconds...

# euca-modify-property -p bootstrap.webservices.use_dns_delegation=true
PROPERTY        bootstrap.webservices.use_dns_delegation        true was false

Continuing in  1 seconds...

============================================================

  5. Refresh Administrator Credentials

============================================================

Commands:

rm -f /root/admin.zip

euca-get-credentials -u admin /root/admin.zip

rm -Rf /root/creds/eucalyptus/admin
mkdir -p /root/creds/eucalyptus/admin
unzip /root/admin.zip -d /root/creds/eucalyptus/admin/

source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

# rm -f /root/admin.zip
#
# euca-get-credentials -u admin /root/admin.zip
#
# rm -Rf /root/creds/eucalyptus/admin
#
# mkdir -p /root/creds/eucalyptus/admin
#
# unzip /root/admin.zip -d /root/creds/eucalyptus/admin/
Archive:  /root/admin.zip
To setup the environment run: source /path/to/eucarc
  inflating: /root/creds/eucalyptus/admin/eucarc  
  inflating: /root/creds/eucalyptus/admin/iamrc  
  inflating: /root/creds/eucalyptus/admin/cloud-cert.pem  
  inflating: /root/creds/eucalyptus/admin/jssecacerts  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-0e8d0a23-pk.pem  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-0e8d0a23-cert.pem  
#
#
# source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

Eucalyptus DNS configured
