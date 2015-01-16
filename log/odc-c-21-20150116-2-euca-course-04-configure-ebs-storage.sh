[root@odc-c-21 bin]# euca-course-04-configure-ebs-storage.sh 

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

 2. Set the Eucalyptus Storage Controller backend
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-modify-property -p AZ1.storage.blockstoragemanager=overlay

Execute (y,n,q)[y]

# euca-modify-property -p AZ1.storage.blockstoragemanager=overlay
PROPERTY        AZ1.storage.blockstoragemanager overlay was <unset>

Waiting 15 seconds for property change to become effective

Continue (y,n,q)[y]

============================================================

 3. Confirm service status
    - This step is only run on the Cloud Controller host
    - The following service should now be in an ENABLED state:
      - storage
    - The following services should be in a NOTREADY state:
      - cluster, loadbalancingbackend, imaging
    - The following services should be in a BROKEN state:
      - objectstorage
    - This is normal at this point in time, with partial configuration

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

============================================================

 4. Confirm Volume Creation
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-create-volume -z AZ1 -s 1

euca-describe-volumes

ls -l /var/lib/eucalyptus/volumes

Execute (y,n,q)[y]

# euca-create-volume -z AZ1 -s 1
VOLUME  vol-4e378990    1               AZ1     creating        2015-01-16T09:02:54.016Z
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     creating        2015-01-16T09:02:54.016Z        standard
#
# ls -l /var/lib/eucalyptus/volumes
total 1.1M
-rw-r--r-- 1 root root 1.1G Jan 16 01:02 vol-4e378990

Continue (y,n,q)[y]

============================================================

 5. Confirm Volume Deletion
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-delete-volume vol-4e378990

euca-describe-volumes

ls -lh /var/lib/eucalyptus/volumes

Execute (y,n,q)[y]

# euca-delete-volume vol-4e378990
VOLUME  vol-4e378990
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     deleting        2015-01-16T09:02:54.016Z        standard
#
# ls -lh /var/lib/eucalyptus/volumes
total 1.1M
-rw-r--r-- 1 root root 1.1G Jan 16 01:02 vol-4e378990

Continue (y,n,q)[y]

============================================================

 6. Flush Volume Resource Information
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-delete-volume vol-4e378990

euca-describe-volumes

Execute (y,n,q)[y]

# euca-delete-volume vol-4e378990
VOLUME  vol-4e378990
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     deleting        2015-01-16T09:02:54.016Z        standard

Continue (y,n,q)[y]

============================================================

 7. Confirm Volume Quota
    - This step is only run on the Cloud Controller host
    - This step should fail with quota exceeded error

============================================================

Commands:

euca-create-volume -z AZ1 -s 20

Execute (y,n,q)[y]

# euca-create-volume -z AZ1 -s 20
euca-create-volume: error (VolumeLimitExceeded): Failed to create volume because of: Max Volume Size Limit Exceeded volume: vol-a8316b3a

Continue (y,n,q)[y]

============================================================

 8. Increase Volume Quota
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-modify-property -p AZ1.storage.maxvolumesizeingb=20

Execute (y,n,q)[y]

# euca-modify-property -p AZ1.storage.maxvolumesizeingb=20
PROPERTY        AZ1.storage.maxvolumesizeingb   20 was 15

Continue (y,n,q)[y]

============================================================

 9. Confirm Increased Volume Quota
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-create-volume -z AZ1 -s 20

euca-describe-volumes

Execute (y,n,q)[y]

# euca-create-volume -z AZ1 -s 20
VOLUME  vol-b7e8f90e    20              AZ1     creating        2015-01-16T09:03:18.333Z
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     deleting        2015-01-16T09:02:54.016Z        standard
VOLUME  vol-b7e8f90e    20              AZ1     creating        2015-01-16T09:03:18.333Z        standard

Continue (y,n,q)[y]

============================================================

10. Confirm Larger Volume Deletion
    - This step is only run on the Cloud Controller host

============================================================

Commands:

euca-delete-volume vol-b7e8f90e

euca-describe-volumes

ls -lh /var/lib/eucalyptus/volumes

Execute (y,n,q)[y]

# euca-delete-volume vol-b7e8f90e
VOLUME  vol-b7e8f90e
#
# euca-describe-volumes
VOLUME  vol-4e378990    1               AZ1     deleting        2015-01-16T09:02:54.016Z        standard
VOLUME  vol-b7e8f90e    20              AZ1     deleting        2015-01-16T09:03:18.333Z        standard
#
# ls -lh /var/lib/eucalyptus/volumes
total 2.1M
-rw-r--r-- 1 root root 1.1G Jan 16 01:02 vol-4e378990
-rw-r--r-- 1 root root  21G Jan 16 01:03 vol-b7e8f90e

Continue (y,n,q)[y]

EBS Storage configuration complete
