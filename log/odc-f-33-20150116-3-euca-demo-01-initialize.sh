[root@odc-f-33 bin]# euca-demo-01-initialize.sh 

============================================================

  1. Use Eucalyptus Administrator credentials

============================================================

Commands:

source /root/creds/eucalyptus/admin/eucarc

Execute (y)[y]

# source /root/creds/eucalyptus/admin/eucarc

Continue (y,n,q)[y]

============================================================

 2. Create Eucalyptus Administrator Demo Keypair

============================================================

Commands:

euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem

chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem

Execute (y,n,q)[y]

# euca-create-keypair admin-demo | tee > /root/creds/eucalyptus/admin/admin-demo.pem

# chmod 0600 /root/creds/eucalyptus/admin/admin-demo.pem

Continue (y,n,q)[y]

============================================================

 3. Create Demo Account

============================================================

Commands:

euare-accountcreate -a demo

Execute (y,n,q)[y]

# euare-accountcreate -a demo
demo    684553355107

Continue (y,n,q)[y]

============================================================

 4. Create Demo Account Administrator Login Profile
    - This allows the Demo Account Administrator to login to the console

============================================================

Commands:

euare-usermodloginprofile –u admin –p demo123 -as-account demo

Execute (y,n,q)[y]

# euare-usermodloginprofile -u admin -p demo123 --as-account demo

Continue (y,n,q)[y]

============================================================

 5. Download Demo Image (CentOS 6.5)

============================================================

Commands:

wget http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O /root/centos.raw.xz

xz -v -d /root/centos.raw.xz

Execute (y,n,q)[y]

# wget http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz -O /root/centos.raw.xz
--2015-01-16 01:22:22--  http://odc-f-38.prc.eucalyptus-systems.com/downloads/eucalyptus/images/centos.raw.xz
Resolving odc-f-38.prc.eucalyptus-systems.com... 10.104.10.80
Connecting to odc-f-38.prc.eucalyptus-systems.com|10.104.10.80|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 154007888 (147M) [application/x-xz]
Saving to: “/root/centos.raw.xz”

100%[==============================================================================>] 154,007,888  112M/s   in 1.3s    

2015-01-16 01:22:23 (112 MB/s) - “/root/centos.raw.xz” saved [154007888/154007888]

#
xz -v -d /root/centos.raw.xz
/root/centos.raw.xz (1/1)
  100.0 %             146.9 MiB / 5,000.0 MiB = 0.029   137 MiB/s         0:36

Continue (y,n,q)[y]

============================================================

 6. Install Demo Image

============================================================

Commands:

euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm

Execute (y,n,q)[y]

# euca-install-image -b images -r x86_64 -i /root/centos.raw -n centos65 --virtualization-type hvm
IMAGE   emi-79a3baf1

Continue (y,n,q)[y]

============================================================

 7. Authorize Demo Account use of Demo Image

============================================================

Commands:

euca-modify-image-attribute -l -a  emi-79a3baf1

Execute (y,n,q)[y]

# euca-modify-image-attribute -l -a  emi-79a3baf1
usage: euca-modify-image-attribute (--description DESC | -p CODE | -l)
                                   [-a ENTITY] [-r ENTITY]
                                   [--show-empty-fields] [-U URL]
                                   [--region USER@REGION] [-I KEY_ID] [-S KEY]
                                   [--security-token TOKEN] [--debug]
                                   [--debugger] [--version] [-h]
                                   IMAGE
euca-modify-image-attribute: error: too few arguments

Continue (y,n,q)[y]

============================================================

 8. Download Demo Account Administrator Credentials
    - This allows the Demo Account Administrator to run API commands

============================================================

Commands:

mkdir -p /root/creds/demo/admin

euca-get-credentials -u admin -a demo \
                     /root/creds/demo/admin/admin.zip

unzip /root/creds/demo/admin/admin.zip \
      -d /root/creds/demo/admin/

Execute (y,n,q)[y]
/root/src/eucalyptus/euca-demo/bin/euca-demo-01-initialize.sh: line 456: syntax error near unexpected token `!'
/root/src/eucalyptus/euca-demo/bin/euca-demo-01-initialize.sh: line 456: `if [ $choice = y | ! -r /root/creds/demo/admin/eucarc ]; then'
