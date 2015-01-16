[root@odc-f-33 bin]# euca-faststart-02-configure-cloudformation.sh -I
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

 2. Register CloudFormation service

============================================================

Commands:

euca_conf --register-service -T CloudFormation -H 10.104.10.75 -N cfn

Continuing in  1 seconds...

# euca_conf --register-service -T CloudFormation -H 10.104.10.75 -N cfn
Created new partition 'cfn'
SERVICE cloudformation          cfn             cfn                     http://10.104.10.75:8773/services/CloudFormatioarn:euca:bootstrap:cfn:cloudformation:cfn/

Continuing in  1 seconds...

============================================================

 3. Refresh Administrator Credentials
    - This step is only run on the Cloud Controller host
    - This fixes the OSG not configured warning

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
  inflating: /root/creds/eucalyptus/admin/euca2-admin-97a0acda-pk.pem  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-97a0acda-cert.pem  
#
# source /root/creds/eucalyptus/admin/eucarc

Continuing in  1 seconds...

============================================================

 4. Confirm service status
    - You should now see the CloudFormation Service

============================================================

Commands:

euca-describe-services | cut -f1-5

Continuing in  1 seconds...

# euca-describe-services | cut -f1-5
SERVICE user-api                API_10.104.10.75        API_10.104.10.75        ENABLED 
SERVICE autoscaling             API_10.104.10.75        API_10.104.10.75.autoscaling    ENABLED 
SERVICE cloudwatch              API_10.104.10.75        API_10.104.10.75.cloudwatch     ENABLED 
SERVICE compute                 API_10.104.10.75        API_10.104.10.75.compute        ENABLED 
SERVICE euare                   API_10.104.10.75        API_10.104.10.75.euare  ENABLED 
SERVICE loadbalancing           API_10.104.10.75        API_10.104.10.75.loadbalancing  ENABLED 
SERVICE objectstorage           API_10.104.10.75        API_10.104.10.75.objectstorage  ENABLED 
SERVICE tokens                  API_10.104.10.75        API_10.104.10.75.tokens ENABLED 
SERVICE bootstrap               bootstrap       10.104.10.75            ENABLED 
SERVICE reporting               bootstrap       10.104.10.75            ENABLED 
SERVICE cloudformation          cfn             cfn                     ENABLED 
SERVICE cluster                 default         default-cc-1            ENABLED 
SERVICE storage                 default         default-sc-1            ENABLED 
SERVICE dns                     eucalyptus      10.104.10.75            ENABLED 
SERVICE loadbalancingbackend    eucalyptus      10.104.10.75            ENABLED 
SERVICE eucalyptus              eucalyptus      10.104.10.75            ENABLED 
SERVICE imaging                 eucalyptus      10.104.10.75            ENABLED 
SERVICE autoscalingbackend      eucalyptus      10.104.10.75            ENABLED 
SERVICE notifications           eucalyptus      10.104.10.75            ENABLED 
SERVICE cloudwatchbackend       eucalyptus      10.104.10.75            ENABLED 
SERVICE jetty                   eucalyptus      10.104.10.75            ENABLED 
SERVICE walrusbackend           walrus          walrus-1                ENABLED 

Continuing in  1 seconds...

============================================================

 5. Verify CloudFormation service
    - Upon installation, there should be no output (no errors)
    - If run after installation, you may see existing Stacks

============================================================

Commands:

euform-describe-stacks

Continuing in  1 seconds...

# euform-describe-stacks

Continuing in  1 seconds...

Eucalyptus CloudFormation configuration complete
