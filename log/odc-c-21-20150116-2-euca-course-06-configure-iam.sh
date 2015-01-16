Object Storage configuration complete
[root@odc-c-21 bin]# euca-course-06-configure-iam.sh 

============================================================

 1. Use Administrator credentials
    - This step is only run on the Cloud Controller host

============================================================

Commands:

source /root/creds/eucalyptus/admin/eucarc

Execute (y,n,q)[y]

# source /root/creds/eucalyptus/admin/eucarc

Continue (y,n,q)[y]

============================================================

 2. Configure Eucalyptus Administrator Password
    - This step is only run on the Cloud Controller host
    - The default password was removed in 4.0, so we must
      set it to get into the console

============================================================

Commands:

euare-usermodloginprofile -u admin -p password

Execute (y,n,q)[y]

# euare-usermodloginprofile -u admin -p password

Continue (y,n,q)[y]

============================================================

 3. Create Accounts
    - This step is only run on the Cloud Controller host
    - We will create two accounts, for Ops and Engineering

============================================================

Commands:

euare-accountcreate -a ops

euare-accountcreate -a engineering

Execute (y,n,q)[y]

# euare-accountcreate -a ops
ops     921417924234
#
# euare-accountcreate -a engineering
engineering     232406316316

Continue (y,n,q)[y]

============================================================

 4. Create Users
    - This step is only run on the Cloud Controller host
    - Within the ops account, create users:
    echo  - bob, sally
    - Within the engineering account, create users:
    echo  - fred, robert, sarah

============================================================

Commands:

euare-usercreate --as-account ops -u bob
euare-usercreate --as-account ops -u sally

euare-usercreate --as-account engineering -u fred
euare-usercreate --as-account engineering -u robert
euare-usercreate --as-account engineering -u sarah

Execute (y,n,q)[y]

# euare-usercreate --as-account ops -u bob
# euare-usercreate --as-account ops -u sally
#
# euare-usercreate --as-account engineering -u fred
# euare-usercreate --as-account engineering -u robert
# euare-usercreate --as-account engineering -u sarah

Continue (y,n,q)[y]

============================================================

 5. Create Login Profiles
    - This step is only run on the Cloud Controller host
    - Within the ops account, create profiles for:
    echo  - bob, sally

============================================================

Commands:

euare-useraddloginprofile --as-account ops -u bob -p mypassword
euare-useraddloginprofile --as-account ops -u sally -p mypassword

Execute (y,n,q)[y]

# euare-useraddloginprofile --as-account ops -u bob -p mypassword
# euare-useraddloginprofile --as-account ops -u sally -p mypassword

Continue (y,n,q)[y]

============================================================

 6. Download Engineering Account Administrator Credentials
    - This step is only run on the Cloud Controller host

============================================================

Commands:

mkdir -p /root/creds/engineering/admin

euca-get-credentials -u admin -a engineering \
                     /root/creds/engineering/admin/eng-admin.zip

unzip /root/creds/engineering/admin/eng-admin.zip \
      -d /root/creds/engineering/admin/

Execute (y,n,q)[y]

# mkdir -p /root/creds/engineering/admin
#
# euca-get-credentials -u admin -a engineering \
>                      /root/creds/engineering/admin/eng-admin.zip
#
# unzip /root/creds/engineering/admin/eng-admin.zip \
>       -d /root/creds/engineering/admin/
Archive:  /root/creds/engineering/admin/eng-admin.zip
To setup the environment run: source /path/to/eucarc
  inflating: /root/creds/engineering/admin/eucarc  
  inflating: /root/creds/engineering/admin/iamrc  
  inflating: /root/creds/engineering/admin/cloud-cert.pem  
  inflating: /root/creds/engineering/admin/jssecacerts  
  inflating: /root/creds/engineering/admin/euca2-admin-5408edc1-pk.pem  
  inflating: /root/creds/engineering/admin/euca2-admin-5408edc1-cert.pem  

Continue (y,n,q)[y]

============================================================

 7. Download Engineering Account Sally User Credentials
    - This step is only run on the Cloud Controller host

============================================================

Commands:

mkdir -p /root/creds/ops/sally

euca-get-credentials -u sally -a ops \
                     /root/creds/ops/sally/ops-sally.zip

unzip /root/creds/ops/sally/ops-sally.zip \
      -d /root/creds/ops/sally/

Execute (y,n,q)[y]

# mkdir -p /root/creds/ops/sally
#
# euca-get-credentials -u sally -a ops \
>                      /root/creds/ops/sally/ops-sally.zip
#
# unzip /root/creds/ops/sally/ops-sally.zip \
>       -d /root/creds/ops/sally/
Archive:  /root/creds/ops/sally/ops-sally.zip
To setup the environment run: source /path/to/eucarc
  inflating: /root/creds/ops/sally/eucarc  
  inflating: /root/creds/ops/sally/iamrc  
  inflating: /root/creds/ops/sally/cloud-cert.pem  
  inflating: /root/creds/ops/sally/jssecacerts  
  inflating: /root/creds/ops/sally/euca2-sally-fb6e159f-pk.pem  
  inflating: /root/creds/ops/sally/euca2-sally-fb6e159f-cert.pem  

Continue (y,n,q)[y]

============================================================

 8. Confirm current identity
    - This step is only run on the Cloud Controller host
    - Useful when switching between users and accounts as we're about to do

============================================================

Commands:

euare-usergetattributes

euare-accountlist

Execute (y,n,q)[y]

# euare-usergetattributes
arn:aws:iam::998829501002:user/admin
AID2KXMDPUHF9TRCZMY5Y
#
# euare-accountlist
ops     921417924234
eucalyptus      998829501002
engineering     232406316316
(eucalyptus)blockstorage        527582570080

Continue (y,n,q)[y]

============================================================

 9. Confirm account separation
    - This step is only run on the Cloud Controller host
    - Create a volume as the Eucalyptus Account Administrator
    - Switch to the Engineering Account Administrator
    - Validate the volume is no longer visible
    - Switch back to the Eucalyptus Account Administrator
    - Delete the volume created for this test

============================================================

Commands:

euca-create-volume -s 1 -z AZ1

euca-describe-volumes

source /root/creds/engineering/admin/eucarc

euca-describe-volumes

source /root/creds/eucalyptus/admin/eucarc

euca-delete-volume vol-xxxxxx

euca-describe-volumes

Execute (y,n,q)[y]

# euca-create-volume -s 1 -z AZ1
VOLUME  vol-56ce30b1    1               AZ1     creating        2015-01-16T09:27:58.904Z
Waiting 30 seconds...Done
#
# euca-describe-volumes
VOLUME  vol-56ce30b1    1               AZ1     available       2015-01-16T09:27:58.904Z        standard
#
# source /root/creds/engineering/admin/eucarc
#
# euca-describe-volumes
#
# source /root/creds/eucalyptus/admin/eucarc
#
# euca-delete-volume vol-56ce30b1
VOLUME  vol-56ce30b1
Waiting 30 seconds...Done
#
# euca-describe-volumes
VOLUME  vol-56ce30b1    1               AZ1     deleting        2015-01-16T09:27:58.904Z        standard

Continue (y,n,q)[y]

============================================================

10. Create Groups as Engineering Account Administrator
    - This step is only run on the Cloud Controller host

============================================================

Commands:

source /root/creds/engineering/admin/eucarc

euare-groupcreate -g describe
euare-groupcreate -g full

Execute (y,n,q)[y]

# source /root/creds/engineering/admin/eucarc
#
# euare-groupcreate -g describe
# euare-groupcreate -g full

Continue (y,n,q)[y]

============================================================

11. List Groups and Users
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euare-grouplistbypath

euare-userlistbypath

Execute (y,n,q)[y]

# euare-grouplistbypath
groups
   arn:aws:iam::232406316316:group/describe
   arn:aws:iam::232406316316:group/full
#
# euare-userlistbypath
arn:aws:iam::232406316316:user/admin
arn:aws:iam::232406316316:user/fred
arn:aws:iam::232406316316:user/robert
arn:aws:iam::232406316316:user/sarah

Continue (y,n,q)[y]

============================================================

12. Create Login Profile with custom password as Eucalyptus Administrator
    - This step is only run on the Cloud Controller host
    - This allows the Ops Account Administrator to login to the console

============================================================

Commands:

source /root/creds/eucalyptus/admin/eucarc

euare-usermodloginprofile –u admin --as-account ops –p password123

Execute (y,n,q)[y]

# source /root/creds/eucalyptus/admin/eucarc
#
# euare-usermodloginprofile -u admin -p password123 --as-account ops

Continue (y,n,q)[y]

IAM configuration complete
