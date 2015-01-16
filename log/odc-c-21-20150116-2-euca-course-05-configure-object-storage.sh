[root@odc-c-21 bin]# euca-course-05-configure-object-storage.sh 

============================================================

 1. Use Administrator credentials
    - This step is only run on the Cloud Controller host
    - NOTE: Expect the OSG not configured warning

============================================================

Commands:

source /root/creds/eucalyptus/admin/eucarc

Execute (y,n,q)[y]

# source /root/creds/eucalyptus/admin/eucarc
WARN: An OSG is either not registered or not configured. S3_URL is not set. Please register an OSG and/or set a valid s3 endpoint and download credentials again. Or set S3_URL manually to http://OSG-IP:8773/services/objectstorage

Continue (y,n,q)[y]

============================================================

 2. Set the Eucalyptus Object Storage Provider to Walrus
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-modify-property -p objectstorage.providerclient=walrus

Execute (y,n,q)[y]

# euca-modify-property -p objectstorage.providerclient=walrus
PROPERTY        objectstorage.providerclient    walrus was {}

Waiting 15 seconds for property change to become effective

Continue (y,n,q)[y]

============================================================

 3. Confirm service status
    - This step is only run on the Cloud Controller host
    - The following services should now be in an ENABLED state:
      - cluster, objectstorage
    - The following services should be in a NOTREADY state:
      - loadbalancingbackend, imaging

============================================================

Commands:

euca-describe-services | cut -f1-5

Execute (y,n,q)[y]

# euca-describe-services | cut -f1-5
SERVICE cluster                 AZ1             PODCC                   ENABLED 
SERVICE storage                 AZ1             PODSC                   ENABLED 
SERVICE user-api                PODAPI          PODAPI                  ENABLED 
SERVICE autoscaling             PODAPI          PODAPI.autoscaling      ENABLED 
SERVICE cloudwatch              PODAPI          PODAPI.cloudwatch       ENABLED 
SERVICE compute                 PODAPI          PODAPI.compute          ENABLED 
SERVICE euare                   PODAPI          PODAPI.euare            ENABLED 
SERVICE loadbalancing           PODAPI          PODAPI.loadbalancing    ENABLED 
SERVICE objectstorage           PODAPI          PODAPI.objectstorage    ENABLED 
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

============================================================

 4. Confirm Snapshot Creation
    - This step is only run on the Cloud Controller host
    - First we create a volume

============================================================

Commands:

euca-create-volume -z AZ1 -s 1

euca-describe-volumes

euca-create-snapshot vol-xxxxxx

euca-describe-snapshots

Execute (y,n,q)[y]

# euca-create-volume -z AZ1 -s 1
VOLUME  vol-5ae87a9a    1               AZ1     creating        2015-01-16T09:05:10.154Z
Waiting 30 seconds...Done
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     deleted 2015-01-16T09:02:54.016Z        standard
VOLUME  vol-b7e8f90e    20              AZ1     deleted 2015-01-16T09:03:18.333Z        standard
VOLUME  vol-5ae87a9a    1               AZ1     available       2015-01-16T09:05:10.154Z        standard
#
# euca-create-snapshot 
SNAPSHOT        snap-561b9c4f   vol-5ae87a9a    pending 2015-01-16T09:05:45.194Z        998829501002    1
Waiting 30 seconds...Done
#
# euca-describe-snapshots
SNAPSHOT        snap-561b9c4f   vol-5ae87a9a    completed       2015-01-16T09:05:45.194Z        100%    998829501002   1

Continue (y,n,q)[y]

============================================================

 5. Confirm Snapshot Deletion
    - This step is only run on the Cloud Controller host
    - Last we remove the volume

============================================================

Commands:

euca-delete-snapshot snap-561b9c4f

euca-describe-snapshots

euca-delete-volume vol-5ae87a9a

euca-describe-volumes

Execute (y,n,q)[y]

# euca-delete-snapshot snap-561b9c4f
SNAPSHOT        snap-561b9c4f
Waiting 30 seconds...Done
#
# euca-describe-snapshots
#
# euca-delete-volume vol-5ae87a9a
VOLUME  vol-5ae87a9a
Waiting 30 seconds...Done
#
# euca-describe-volumes
VOLUME  vol-5ae87a9a    1               AZ1     deleted 2015-01-16T09:05:10.154Z        standard

Continue (y,n,q)[y]

============================================================

 6. Refresh Administrator Credentials
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

Execute (y,n,q)[y]

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
  inflating: /root/creds/eucalyptus/admin/euca2-admin-22e70a33-pk.pem  
  inflating: /root/creds/eucalyptus/admin/euca2-admin-22e70a33-cert.pem  
#
# source /root/creds/eucalyptus/admin/eucarc

Continue (y,n,q)[y]

============================================================

 7. Confirm Properties
    - This step is only run on the Cloud Controller host
    - Confirm S3_URL is now configured, should be:
      http://10.104.10.21:8773/services/objectstorage

============================================================

Commands:

euca-describe-properties | more

echo $S3_URL

Execute (y,n,q)[y]

# euca-describe-properties | more
PROPERTY        AZ1.cluster.addressespernetwork 32
PROPERTY        AZ1.cluster.maxnetworkindex     30
PROPERTY        AZ1.cluster.maxnetworktag       2047
PROPERTY        AZ1.cluster.minnetworkindex     9
PROPERTY        AZ1.cluster.minnetworktag       2
PROPERTY        AZ1.cluster.networkmode MANAGED-NOVLAN
PROPERTY        AZ1.cluster.sourcehostname      10.104.10.21
PROPERTY        AZ1.cluster.usenetworktags      true
PROPERTY        AZ1.cluster.vnetnetmask 255.255.0.0
PROPERTY        AZ1.cluster.vnetsubnet  172.44.0.0
PROPERTY        AZ1.cluster.vnettype    ipv4
PROPERTY        AZ1.storage.blockstoragemanager overlay
PROPERTY        AZ1.storage.chapuser    <unset>
PROPERTY        AZ1.storage.dasdevice   <unset>
PROPERTY        AZ1.storage.deletedvolexpiration        24
PROPERTY        AZ1.storage.maxconcurrentsnapshotuploads        3
PROPERTY        AZ1.storage.maxsnapshotpartsqueuesize   5
PROPERTY        AZ1.storage.maxsnaptransferretries      50
PROPERTY        AZ1.storage.maxtotalvolumesizeingb      100
PROPERTY        AZ1.storage.maxvolumesizeingb   20
PROPERTY        AZ1.storage.ncpaths     <unset>
PROPERTY        AZ1.storage.resourceprefix      <unset>
PROPERTY        AZ1.storage.resourcesuffix      <unset>
PROPERTY        AZ1.storage.sanhost     <unset>
PROPERTY        AZ1.storage.sanpassword ********
PROPERTY        AZ1.storage.sanuser     <unset>
PROPERTY        AZ1.storage.scpaths     <unset>
PROPERTY        AZ1.storage.shouldtransfersnapshots     true
PROPERTY        AZ1.storage.snapshotpartsizeinmb        100
PROPERTY        AZ1.storage.snapshotuploadtimeoutinhours        48
PROPERTY        AZ1.storage.storeprefix iqn.2009-06.com.eucalyptus.
PROPERTY        AZ1.storage.tasktimeout <unset>
PROPERTY        AZ1.storage.tid 1
PROPERTY        AZ1.storage.timeoutinmillis     10000
PROPERTY        AZ1.storage.volumesdir  //var/lib/eucalyptus/volumes
PROPERTY        AZ1.storage.zerofillvolumes     false
PROPERTY        authentication.credential_download_host_match   {}
PROPERTY        authentication.ldap_integration_configuration   { 'sync': { 'enable':'false' } }
PROPERTY        autoscaling.activityexpiry      42d
PROPERTY        autoscaling.activityinitialbackoff      9s
PROPERTY        autoscaling.activitymaxbackoff  15m
PROPERTY        autoscaling.activitytimeout     5m
PROPERTY        autoscaling.maxlaunchincrement  20
PROPERTY        autoscaling.maxregistrationretries      5
PROPERTY        autoscaling.pendinginstancetimeout      15m
PROPERTY        autoscaling.suspendedprocesses  {}
PROPERTY        autoscaling.suspendedtasks      {}
PROPERTY        autoscaling.suspensionlaunchattemptsthreshold   15
PROPERTY        autoscaling.suspensiontimeout   1d
PROPERTY        autoscaling.untrackedinstancetimeout    5m
PROPERTY        autoscaling.zonefailurethreshold        5m
PROPERTY        bootstrap.async.future_listener_debug_limit_secs        30
PROPERTY        bootstrap.async.future_listener_error_limit_secs        120
PROPERTY        bootstrap.async.future_listener_get_retries     8
PROPERTY        bootstrap.async.future_listener_get_timeout     30
PROPERTY        bootstrap.async.future_listener_info_limit_secs 60
PROPERTY        bootstrap.hosts.state_initialize_timeout        120000
PROPERTY        bootstrap.hosts.state_transfer_timeout  10000
PROPERTY        bootstrap.notifications.batch_delay_seconds     60
PROPERTY        bootstrap.notifications.digest  false
PROPERTY        bootstrap.notifications.digest_frequency_hours  24
PROPERTY        bootstrap.notifications.digest_only_on_errors   true
PROPERTY        bootstrap.notifications.email_from      notification@eucalyptus
PROPERTY        bootstrap.notifications.email_from_name Eucalyptus Notifications
PROPERTY        bootstrap.notifications.email_subject_prefix    [eucalyptus-notifications]
PROPERTY        bootstrap.notifications.email_to        {}
PROPERTY        bootstrap.notifications.include_fault_stack     false
PROPERTY        bootstrap.notifications.email.email_smtp_host   {}
PROPERTY        bootstrap.notifications.email.email_smtp_port   25
PROPERTY        bootstrap.servicebus.context_timeout    60
PROPERTY        bootstrap.servicebus.hup        0
PROPERTY        bootstrap.servicebus.max_outstanding_messages   256
PROPERTY        bootstrap.servicebus.min_scheduler_core_size    64
PROPERTY        bootstrap.servicebus.workers_per_stage  16
PROPERTY        bootstrap.timer.rate    10000
PROPERTY        bootstrap.topology.coordinator_check_backoff_secs       10
PROPERTY        bootstrap.topology.local_check_backoff_secs     10
PROPERTY        bootstrap.tx.concurrent_update_retries  10
PROPERTY        bootstrap.webservices.async_internal_operations false
PROPERTY        bootstrap.webservices.async_operations  false
PROPERTY        bootstrap.webservices.async_pipeline    false
PROPERTY        bootstrap.webservices.channel_connect_timeout   500
PROPERTY        bootstrap.webservices.channel_keep_alive        true
PROPERTY        bootstrap.webservices.channel_nodelay   true
PROPERTY        bootstrap.webservices.channel_reuse_address     true
PROPERTY        bootstrap.webservices.client_http_chunk_buffer_max      1048576000
PROPERTY        bootstrap.webservices.client_idle_timeout_secs  30
PROPERTY        bootstrap.webservices.client_internal_timeout_secs      60
PROPERTY        bootstrap.webservices.client_pool_max_mem_per_conn      0
PROPERTY        bootstrap.webservices.client_pool_max_threads   40
PROPERTY        bootstrap.webservices.client_pool_timeout_millis        500
PROPERTY        bootstrap.webservices.client_pool_total_mem     0
PROPERTY        bootstrap.webservices.clock_skew_sec    20
PROPERTY        bootstrap.webservices.cluster_connect_timeout_millis    2000
PROPERTY        bootstrap.webservices.default_aws_sns_uri_scheme        http
PROPERTY        bootstrap.webservices.default_ec2_uri_scheme    http
PROPERTY        bootstrap.webservices.default_euare_uri_scheme  http
PROPERTY        bootstrap.webservices.default_eustore_url       http://emis.eucalyptus.com/
PROPERTY        bootstrap.webservices.default_https_enabled     false
PROPERTY        bootstrap.webservices.default_s3_uri_scheme     http
PROPERTY        bootstrap.webservices.http_max_chunk_bytes      102400
PROPERTY        bootstrap.webservices.http_max_header_bytes     8192
PROPERTY        bootstrap.webservices.http_max_initial_line_bytes       4096
PROPERTY        bootstrap.webservices.listener_address_match    0.0.0.0
PROPERTY        bootstrap.webservices.log_requests      true
PROPERTY        bootstrap.webservices.oob_internal_operations   true
PROPERTY        bootstrap.webservices.pipeline_idle_timeout_seconds     60
PROPERTY        bootstrap.webservices.port      8773
PROPERTY        bootstrap.webservices.replay_skew_window_sec    3
PROPERTY        bootstrap.webservices.server_boss_pool_max_mem_per_conn 0
PROPERTY        bootstrap.webservices.server_boss_pool_max_threads      128
PROPERTY        bootstrap.webservices.server_boss_pool_timeout_millis   500
PROPERTY        bootstrap.webservices.server_boss_pool_total_mem        0
PROPERTY        bootstrap.webservices.server_channel_nodelay    true
PROPERTY        bootstrap.webservices.server_channel_reuse_address      true
PROPERTY        bootstrap.webservices.server_pool_max_mem_per_conn      0
PROPERTY        bootstrap.webservices.server_pool_max_threads   128
PROPERTY        bootstrap.webservices.server_pool_timeout_millis        500
PROPERTY        bootstrap.webservices.server_pool_total_mem     0
PROPERTY        bootstrap.webservices.statistics        false
PROPERTY        bootstrap.webservices.unknown_parameter_handling        default
PROPERTY        bootstrap.webservices.use_dns_delegation        false
PROPERTY        bootstrap.webservices.use_instance_dns  false
PROPERTY        bootstrap.webservices.ssl.server_alias  eucalyptus
PROPERTY        bootstrap.webservices.ssl.server_password       ********
PROPERTY        bootstrap.webservices.ssl.server_ssl_ciphers    RSA:DSS:ECDSA:+RC4:+3DES:TLS_EMPTY_RENEGOTIATION_INFO_SC
SV:!NULL:!EXPORT:!EXPORT1024:!MD5:!DES
PROPERTY        cloud.db_check_poll_time        60000
PROPERTY        cloud.db_check_threshold        2.0%
PROPERTY        cloud.euca_log_level    INFO
PROPERTY        cloud.identifier_canonicalizer  lower
PROPERTY        cloud.log_file_disk_check_poll_time     5000
PROPERTY        cloud.log_file_disk_check_threshold     2.0%
PROPERTY        cloud.memory_check_poll_time    5000
PROPERTY        cloud.memory_check_ratio        0.98
PROPERTY        cloud.perm_gen_memory_check_poll_time   5000
PROPERTY        cloud.perm_gen_memory_check_ratio       0.98
PROPERTY        cloud.trigger_fault     {}
PROPERTY        cloud.addresses.dodynamicpublicaddresses        true
PROPERTY        cloud.addresses.maxkillorphans  360
PROPERTY        cloud.addresses.orphangrace     360
PROPERTY        cloud.addresses.systemreservedpublicaddresses   0
PROPERTY        cloud.cluster.disabledinterval  15
PROPERTY        cloud.cluster.enabledinterval   15
PROPERTY        cloud.cluster.notreadyinterval  10
PROPERTY        cloud.cluster.pendinginterval   3
PROPERTY        cloud.cluster.requestworkers    8
PROPERTY        cloud.cluster.startupsyncretries        10
PROPERTY        cloud.images.cleanupperiod      10m
PROPERTY        cloud.images.defaultvisibility  false
PROPERTY        cloud.images.maximagesizegb     30
PROPERTY        cloud.monitor.default_poll_interval_mins        5
PROPERTY        cloud.monitor.history_size      5
PROPERTY        cloud.network.global_max_network_index  4096
PROPERTY        cloud.network.global_max_network_tag    4096
PROPERTY        cloud.network.global_min_network_index  2
PROPERTY        cloud.network.global_min_network_tag    1
PROPERTY        cloud.network.min_broadcast_interval    5
PROPERTY        cloud.network.network_configuration     {}
PROPERTY        cloud.network.network_index_pending_timeout     35
PROPERTY        cloud.network.network_tag_pending_timeout       35
PROPERTY        cloud.vmstate.buried_time       60
PROPERTY        cloud.vmstate.ebs_root_device_name      emi
PROPERTY        cloud.vmstate.ebs_volume_creation_timeout       30
PROPERTY        cloud.vmstate.instance_subdomain        .eucalyptus
PROPERTY        cloud.vmstate.instance_timeout  720
PROPERTY        cloud.vmstate.instance_touch_interval   15
PROPERTY        cloud.vmstate.mac_prefix        d0:0d
PROPERTY        cloud.vmstate.max_state_threads 16
PROPERTY        cloud.vmstate.migration_refresh_time    60
PROPERTY        cloud.vmstate.network_metadata_refresh_time     15
PROPERTY        cloud.vmstate.shut_down_time    10
PROPERTY        cloud.vmstate.stopping_time     10
PROPERTY        cloud.vmstate.terminated_time   60
PROPERTY        cloud.vmstate.tx_retries        10
PROPERTY        cloud.vmstate.user_data_max_size_kb     16
PROPERTY        cloud.vmstate.vm_initial_report_timeout 300
PROPERTY        cloud.vmstate.vm_metadata_instance_cache        maximumSize=250, expireAfterWrite=5s
PROPERTY        cloud.vmstate.vm_metadata_request_cache maximumSize=250, expireAfterWrite=1s
PROPERTY        cloud.vmstate.vm_metadata_user_data_cache       maximumSize=50, expireAfterWrite=5s, softValues
PROPERTY        cloud.vmstate.vm_state_settle_time      40
PROPERTY        cloud.vmstate.volatile_state_interval_sec       9223372036854775807
PROPERTY        cloud.vmstate.volatile_state_timeout_sec        60
PROPERTY        cloud.vmtypes.default_type_name m1.small
PROPERTY        cloudformation.region   {}
PROPERTY        cloudwatch.disable_cloudwatch_service   false
PROPERTY        dns.dns_listener_address_match  {}
PROPERTY        dns.enabled     true
PROPERTY        dns.instancedata.enabled        true
PROPERTY        dns.ns.enabled  true
PROPERTY        dns.recursive.enabled   true
PROPERTY        dns.services.enabled    true
PROPERTY        dns.services.hostmapping        {}
PROPERTY        dns.split_horizon.enabled       true
PROPERTY        dns.spoof_regions.enabled       false
PROPERTY        dns.spoof_regions.region_name   {}
PROPERTY        dns.spoof_regions.spoof_aws_default_regions     false
PROPERTY        dns.spoof_regions.spoof_aws_regions     false
PROPERTY        dns.tcp.timeout_seconds 30
PROPERTY        imaging.imaging_worker_availability_zones       {}
PROPERTY        imaging.imaging_worker_emi      NULL
PROPERTY        imaging.imaging_worker_enabled  true
PROPERTY        imaging.imaging_worker_healthcheck      true
PROPERTY        imaging.imaging_worker_instance_type    m1.small
PROPERTY        imaging.imaging_worker_keyname  {}
PROPERTY        imaging.imaging_worker_log_server       {}
PROPERTY        imaging.imaging_worker_log_server_port  514
PROPERTY        imaging.imaging_worker_ntp_server       {}
PROPERTY        imaging.import_task_expiration_hours    168
PROPERTY        imaging.import_task_timeout_minutes     180
PROPERTY        loadbalancing.loadbalancer_app_cookie_duration  24
PROPERTY        loadbalancing.loadbalancer_dns_subdomain        lb
PROPERTY        loadbalancing.loadbalancer_dns_ttl      60
PROPERTY        loadbalancing.loadbalancer_emi  NULL
PROPERTY        loadbalancing.loadbalancer_instance_type        m1.small
PROPERTY        loadbalancing.loadbalancer_num_vm       1
PROPERTY        loadbalancing.loadbalancer_restricted_ports     22
PROPERTY        loadbalancing.loadbalancer_vm_keyname   {}
PROPERTY        loadbalancing.loadbalancer_vm_ntp_server        {}
PROPERTY        objectstorage.bucket_creation_wait_interval_seconds     60
PROPERTY        objectstorage.bucket_naming_restrictions        extended
PROPERTY        objectstorage.cleanup_task_interval_seconds     60
PROPERTY        objectstorage.dogetputoncopyfail        false
PROPERTY        objectstorage.failed_put_timeout_hrs    168
PROPERTY        objectstorage.max_buckets_per_account   100
PROPERTY        objectstorage.max_total_reporting_capacity_gb   2147483647
PROPERTY        objectstorage.providerclient    walrus
PROPERTY        objectstorage.queue_size        100
PROPERTY        objectstorage.s3provider.s3accesskey    ********
PROPERTY        objectstorage.s3provider.s3endpoint     uninitialized-s3-endpoint
PROPERTY        objectstorage.s3provider.s3secretkey    ********
PROPERTY        objectstorage.s3provider.s3usebackenddns        false
PROPERTY        objectstorage.s3provider.s3usehttps     false
PROPERTY        reporting.data_collection_enabled       true
PROPERTY        reporting.default_size_time_size_unit   GB
PROPERTY        reporting.default_size_time_time_unit   DAYS
PROPERTY        reporting.default_size_unit     GB
PROPERTY        reporting.default_time_unit     DAYS
PROPERTY        reporting.default_write_interval_mins   15
PROPERTY        storage.global_total_snapshot_size_limit_gb     50
PROPERTY        system.dns.dnsdomain    localhost
PROPERTY        system.dns.nameserver   nshost.localhost
PROPERTY        system.dns.nameserveraddress    127.0.0.1
PROPERTY        system.dns.registrationid       4a116fb1-da93-4a62-ac1a-4e9df8e0ac5c
PROPERTY        system.exec.io_chunk_size       102400
PROPERTY        system.exec.max_restricted_concurrent_ops       2
PROPERTY        system.exec.restricted_concurrent_ops   dd,gunzip,tar
PROPERTY        tagging.max_tags_per_resource   10
PROPERTY        tokens.disabledactions  {}
PROPERTY        tokens.enabledactions   {}
PROPERTY        walrusbackend.blockdevice       <unset>
PROPERTY        walrusbackend.resource  <unset>
PROPERTY        walrusbackend.storagedir        //var/lib/eucalyptus/bukkits
PROPERTY        walrusbackend.storagemaxtotalcapacity   182
PROPERTY        www.http_port   8080
PROPERTY        www.httpproxyhost       {}
PROPERTY        www.httpproxyport       {}
PROPERTY        www.https_ciphers       RSA:DSS:ECDSA:+RC4:+3DES:TLS_EMPTY_RENEGOTIATION_INFO_SCSV:!NULL:!EXPORT:!EXPORT
1024:!MD5:!DES
PROPERTY        www.https_port  8443
#
echo $S3_URL
http://10.104.10.21:8773/services/objectstorage

Continue (y,n,q)[y]

============================================================

 8. Install Load Balancer and Imaging Worker image packages
    - This step is only run on the Cloud Controller host

============================================================

Commands:

yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image

Execute (y,n,q)[y]

# yum install -y eucalyptus-load-balancer-image eucalyptus-imaging-worker-image
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: repos.dfw.quadranet.com
Resolving Dependencies
--> Running transaction check
---> Package eucalyptus-imaging-worker-image.x86_64 0:1.0.2-0.49.165.el6 will be installed
---> Package eucalyptus-load-balancer-image.x86_64 0:1.1.3-0.90.36.el6 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

========================================================================================================================
 Package                                    Arch              Version                       Repository             Size
========================================================================================================================
Installing:
 eucalyptus-imaging-worker-image            x86_64            1.0.2-0.49.165.el6            eucalyptus            296 M
 eucalyptus-load-balancer-image             x86_64            1.1.3-0.90.36.el6             eucalyptus            294 M

Transaction Summary
========================================================================================================================
Install       2 Package(s)

Total download size: 590 M
Installed size: 632 M
Downloading Packages:
(1/2): eucalyptus-imaging-worker-image-1.0.2-0.49.165.el6.x86_64.rpm                             | 296 MB     03:27     
(2/2): eucalyptus-load-balancer-image-1.1.3-0.90.36.el6.x86_64.rpm                               | 294 MB     03:30     
------------------------------------------------------------------------------------------------------------------------
Total                                                                                   1.4 MB/s | 590 MB     06:58     
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : eucalyptus-load-balancer-image-1.1.3-0.90.36.el6.x86_64                                              1/2 
  Installing : eucalyptus-imaging-worker-image-1.0.2-0.49.165.el6.x86_64                                            2/2 
  Verifying  : eucalyptus-imaging-worker-image-1.0.2-0.49.165.el6.x86_64                                            1/2 
  Verifying  : eucalyptus-load-balancer-image-1.1.3-0.90.36.el6.x86_64                                              2/2 

Installed:
  eucalyptus-imaging-worker-image.x86_64 0:1.0.2-0.49.165.el6 eucalyptus-load-balancer-image.x86_64 0:1.1.3-0.90.36.el6

Complete!

Continue (y,n,q)[y]

============================================================

 9. Install the images into Eucalyptus
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-install-load-balancer --install-default

euca-install-imaging-worker --install-default

Execute (y,n,q)[y]

# euca-install-load-balancer --install-default
Installing default Load Balancer tarball.
Found tarball /usr/share/eucalyptus-load-balancer-image/eucalyptus-load-balancer-image-1.1.3-90.36.tgz
Decompressing tarball: /usr/share/eucalyptus-load-balancer-image/eucalyptus-load-balancer-image-1.1.3-90.36.tgz
Bundling and uploading image to bucket: loadbalancer-v1
Registering image manifest: loadbalancer-v1/eucalyptus-load-balancer-image.img.manifest.xml
Registered image: emi-a63f7837
PROPERTY        loadbalancing.loadbalancer_emi  emi-a63f7837 was NULL

Load Balancing Support is Enabled
#
# euca-install-imaging-worker --install-default
Installing default Imaging Service tarball.
Found tarball /usr/share/eucalyptus-imaging-worker-image/eucalyptus-imaging-worker-image-1.0.2-49.165.tgz
Decompressing tarball: /usr/share/eucalyptus-imaging-worker-image/eucalyptus-imaging-worker-image-1.0.2-49.165.tgz
Bundling and uploading image to bucket: imaging-worker-v1
Registering image manifest: imaging-worker-v1/eucalyptus-imaging-worker-image.img.manifest.xml
Registered image: emi-fa58d0b6
PROPERTY        imaging.imaging_worker_emi      emi-fa58d0b6 was NULL

Imaging Service Support is Enabled

Waiting 15 seconds for service changes to stabilize

Continue (y,n,q)[y]

============================================================

10. Confirm service status
    - This step is only run on the Cloud Controller host
    - The following service should now be in an ENABLED state:
      - loadbalancingbackend, imaging
    - All services should now be in the ENABLED state!

============================================================

Commands:

euca-describe-services | cut -f1-5

Execute (y,n,q)[y]

# euca-describe-services | cut -f1-5
SERVICE cluster                 AZ1             PODCC                   ENABLED 
SERVICE storage                 AZ1             PODSC                   ENABLED 
SERVICE user-api                PODAPI          PODAPI                  ENABLED 
SERVICE autoscaling             PODAPI          PODAPI.autoscaling      ENABLED 
SERVICE cloudwatch              PODAPI          PODAPI.cloudwatch       ENABLED 
SERVICE compute                 PODAPI          PODAPI.compute          ENABLED 
SERVICE euare                   PODAPI          PODAPI.euare            ENABLED 
SERVICE loadbalancing           PODAPI          PODAPI.loadbalancing    ENABLED 
SERVICE objectstorage           PODAPI          PODAPI.objectstorage    ENABLED 
SERVICE tokens                  PODAPI          PODAPI.tokens           ENABLED 
SERVICE bootstrap               bootstrap       10.104.10.21            ENABLED 
SERVICE reporting               bootstrap       10.104.10.21            ENABLED 
SERVICE notifications           eucalyptus      10.104.10.21            ENABLED 
SERVICE jetty                   eucalyptus      10.104.10.21            ENABLED 
SERVICE dns                     eucalyptus      10.104.10.21            ENABLED 
SERVICE eucalyptus              eucalyptus      10.104.10.21            ENABLED 
SERVICE autoscalingbackend      eucalyptus      10.104.10.21            ENABLED 
SERVICE cloudwatchbackend       eucalyptus      10.104.10.21            ENABLED 
SERVICE loadbalancingbackend    eucalyptus      10.104.10.21            ENABLED 
SERVICE imaging                 eucalyptus      10.104.10.21            ENABLED 
SERVICE walrusbackend           walrus          walrus                  ENABLED 

Continue (y,n,q)[y]

Object Storage configuration complete
