# Demo Initialize: Initialize Demo Account Dependencies

This document describes the manual procedure to initialize additional dependencies within the
demo account.

### Prerequisites

This variant must be run by root on the Eucalyptus CLC host.

It assumes the environment was installed via FastStart and the additional scripts needed to
initialize DNS, PKI, SSL reverse-proxy and the initialization of Euca2ools and AWSCLI, as
described in the [FastStart Install](../../../installs/install-10-faststart) section, have
been run, or equivalent manual configuration has been done.

It also assumes the [demo-00-initialize.md](./demo-00-initialize.md),
[demo-01-initialize-account.md](./demo-01-initialize-account.md) and
[demo-02-initialize-account-administrator.md](./demo-02-initialize-account-administrator.md)
procedures have been run.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export REGION=hp-gol01-d8
    export ACCOUNT=demo
    export USER=admin

    export USER_REGION=$REGION-$ACCOUNT-$USER@$REGION
    export PROFILE=$REGION-$ACCOUNT-$USER
    ```

### Initialize Demo Account Dependencies

The steps below are automated in the [demo-03-initialize-account-dependencies.sh](../bin/demo-03-initialize-account-dependencies.sh) script.

2. List Images available to Demo (demo) Account Administrator

    ```bash
    euca-describe-images --all --region $USER_REGION
    ```

3. Import Demo (demo) Account Administrator Demo Keypair

    ```bash
    cat << EOF > ~/.ssh/demo_id_rsa
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAmxRVKSZsQEsxlrOZiFfyZy2oKexnf0V7Juq7wfVEaEv6J47/
    tfjGELCOmf5rIY2OfeMumBf5lzoPNjHDZY1pYbdixeLoIaQOYuedIoXkq0yzPV/K
    kYrNTkZ6fkZrQ+9PpLjsfyD8anBNU9gs1qDqCM5nAZhtO7L7XFeQGOb3QGOLOsz1
    1G5qulgCFInA7CpPb1qg6x5QMDaEmAuBy4KY50HNP3JbIRNYSJg4yXeqGULCB6S0
    Aaz81TDeck1kTCnvm/7ZBsiecANPtQp2z4TgS/ngBpTff76f0/okPY4B77NVnKhe
    D0UyS2lHdw8vsr/Qbt+71mTQp4JicLyonylHGwIDAQABAoIBAQCUxyr0cZJFFF6c
    r+1J6uX5qsm8frrEVUpTCbvb1owsa0exD/WvBN4wQNJuVrE83Wuoxn17GPUw6liR
    q6hEEyjYwHEYXBpLu/K5XG9aIY5B8TG8XdwfSUSyJdd6seBSqpKD+42YYXMIQnlN
    SQWrW3FrxWj5FN0m+w0/iBoMafknYVo6xn6SVC0VUGuQFuCEJhTpxBC2pCgnaVqM
    baivYG2TG9/e+1TR7HzRnjvKFQ4md5nRkhVuXjbcJqarWF3L/CErgKqgqKMwrn6s
    HIu24tjBAM8JVYjKkmx3hyiBUUm6rF2KcG3wzVON5tMDBxWQjDdcucsRdTph6Eh3
    IQ0bpbPxAoGBAM3pvGzfSE+cIyzgVHP3Vz42a8HjWC7JjMoWL4YibtvDwXF7Kxt6
    /rPceihZRyMwmpA6NFNRu85BGaT1NmGEaiXjYST9TqwIKliH/3IDNoZJA8d76zLD
    UjD2ufubpvsDuEm8rt0lroFH0x3XekgNe1OEh8/9JZqMLZG2qYf++1mPAoGBAMDN
    LFjPrbnySJni40EzkOHxdKOGTPBnnBB12vPUn27JOB2StJCQNeu5cRAWOCHBSx+6
    Uag9h9Xpvl64PQbyvOBJo+RBjc0BomyuTeqafcu3d4IxHffhtv0WMJzy793KUORR
    278bEfRnGIZFHAo/celW1vUHdXI5Ufz0kd5LwTu1AoGBAJrJlrQ80I3PsH1+kN2v
    0+xXWn+gl9xr9CLBtK3fWnhnWhYlYY1B0w9/sHB+VER2t+mtZ0Iu0b/FHjLrhhqe
    QHEE0TTOGgKmDLcKXJLnKWieoHGnjHFXdISMI9io9EgDTthXNxfUyK40QNZQ8YIS
    aF+q47EM+eSIdYTwy9YIbgevAoGAV6rzx05nyG2K5a5td3BjKNoKF3Ex+v6h0DpG
    3SiJdm64vXm/8Rwh6JXh+1afH3otFrg5+S5BXdtzXM6ZsVce2z2g8GF+gQGFQbXg
    aBTnroI2LVT4M4bHFj3IzRUKTOd58Nfn+/XrLB7U3/j8zwwaV+fMxo4lsVKvHT54
    NYRs0SECgYAoBT9LNHEzsKtA+kAz2PDlg7b0u/3Zx1XWn39TkSmWm1YlKhOw+rZV
    ysocsRRkDaWdjv5gmcUbupnSgh/tWyJSaBfNGROYDCsHx4V8LRsc48bTCyhaxLMI
    MXhYdU42xdkDydmJPDBc0Q6VInxqkiqHTZ/c+gBoiLCIdb3FRvJwyQ==
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 0600 ~/.ssh/demo_id_rsa

    cat << EOF > ~/.ssh/demo_id_rsa.pub
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbFFUpJmxASzGWs5mIV/JnLagp\
    7Gd/RXsm6rvB9URoS/onjv+1+MYQsI6Z/mshjY594y6YF/mXOg82McNljWlht2LF\
    4ughpA5i550iheSrTLM9X8qRis1ORnp+RmtD70+kuOx/IPxqcE1T2CzWoOoIzmcB\
    mG07svtcV5AY5vdAY4s6zPXUbmq6WAIUicDsKk9vWqDrHlAwNoSYC4HLgpjnQc0/\
    clshE1hImDjJd6oZQsIHpLQBrPzVMN5yTWRMKe+b/tkGyJ5wA0+1CnbPhOBL+eAG\
    lN9/vp/T+iQ9jgHvs1WcqF4PRTJLaUd3Dy+yv9Bu37vWZNCngmJwvKifKUcb\
     demo@hpcloud.com
    EOF

    euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \
                        --region $USER_REGION \
                        demo
    ```

4. Create Demo (demo) Account Demo (demo-demo) Bucket

    We must use a non-Euca2ools method, as Euca2ools does not currently support S3.

    ```bash
    aws s3 mb s3://demo-demo --profile $PROFILE --region $REGION
    ```

5. Create Demo (demo) Account Demos (Demos) Role and associated InstanceProfile

    This Role is intended for Demos which need Administrator access to Resources.

    ```bash
    cat << EOF > /var/tmp/demo/DemosRoleTrustPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": { "Service": "ec2.amazonaws.com"},
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF

    euare-rolecreate -f /var/tmp/demo/DemosRoleTrustPolicy.json --region $USER_REGION Demos

    euare-instanceprofilecreate --region $USER_REGION Demos

    euare-instanceprofileaddrole --role-name Demos --region $USER_REGION Demos
    ```

6. Create Demo (demo) Account Demos (Demos) Role Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    cat << EOF >> /var/tmp/demo/DemosRolePolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "cloudformation:DescribeStacks",
            "cloudformation:DescribeStackEvents",
            "cloudformation:DescribeStackResource",
            "cloudformation:DescribeStackResources",
            "cloudformation:GetTemplate",
            "cloudformation:List*",
            "ec2:Describe*",
            "s3:Get*",
            "s3:List*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": "s3:ListAllMyBuckets",
          "Resource": "arn:aws:s3:::*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource": "arn:aws:s3:::demo-demo"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObjectAcl",
            "s3:PutObjectVersionAcl"
          ],
          "Resource": "arn:aws:s3:::demo-demo/*"
        }
      ]
    }
    EOF

    euare-roleuploadpolicy --policy-name DemosPolicy \
                           --policy-document /var/tmp/demo/DemosRolePolicy.json \
                           --region $USER_REGION \
                           Demos
    ```

7. Create Demo (demo) Account Demos (Demos) Group

    This Group is intended for Demos which have Administrator access to Resources.

    ```bash
    euare-groupcreate --region $USER_REGION Demos
    ```

8. Create Demo (demo) Account Demos (Demos) Group Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    mkdir -p /var/tmp/demo

    cat << EOF >> /var/tmp/demo/DemosGroupPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "NotAction": "iam:*",
          "Resource": "*",
          "Effect": "Allow"
        }
      ]
    }
    EOF

    euare-groupuploadpolicy --policy-name DemosPolicy \
                            --policy-document /var/tmp/demo/DemosGroupPolicy.json \
                            --region $USER_REGION \
                            Demos
    ```

9. Create Demo (demo) Account Developers (Developers) Group

    This Group is intended for Developers who can modify Resources.

    ```bash
    euare-groupcreate --region $USER_REGION Developers
    ```

10. Create Demo (demo) Account Developers (Developers) Group Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    cat << EOF >> /var/tmp/demo/DevelopersGroupPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "NotAction": "iam:*",
          "Resource": "*",
          "Effect": "Allow"
        }
      ]
    }
    EOF

    euare-groupuploadpolicy --policy-name DevelopersPolicy \
                            --policy-document /var/tmp/demo/DevelopersGroupPolicy.json \
                            --region $USER_REGION \
                            Developers
    ```

11. Create Demo (demo) Account Users (Users) Group

    This Group is intended for Users who can view but not modify Resources.

    ```bash
    euare-groupcreate --region $USER_REGION Users
    ```

12. Create Demo (demo) Account Users (Users) Group Policy

    This Policy provides ReadOnly access to all Resources.

    ```bash
    cat << EOF >> /var/tmp/demo/UsersGroupPolicy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "autoscaling:Describe*",
            "cloudformation:DescribeStackEvents",
            "cloudformation:DescribeStackResource",
            "cloudformation:DescribeStackResources",
            "cloudformation:DescribeStacks",
            "cloudformation:GetTemplate",
            "cloudformation:List*",
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*",
            "ec2:Describe*",
            "ec2:GetConsoleOutput",
            "elasticloadbalancing:Describe*",
            "iam:GenerateCredentialReport",
            "iam:Get*",
            "iam:List*",
            "s3:Get*",
            "s3:List*",
            "swf:Count*",
            "swf:Describe*",
            "swf:Get*",
            "swf:List*",
            "tag:Get*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }
    EOF

    euare-groupuploadpolicy --policy-name UsersPolicy \
                            --policy-document /var/tmp/demo/UsersGroupPolicy.json \
                            --region $USER_REGION \
                            Users
    ```

13. Create Demo (demo) Account Demo (demo) User

    ```bash
    euare-usercreate --region $USER_REGION demo
    ```

14. Add Demo (demo) Account Demo (demo) User to Demos (Demos) Group

    ```bash
    euare-groupadduser --user-name demo --region $USER_REGION Demos
    ```

15. Create Demo (demo) Account Demo (demo) User Login Profile

    This allows the Demo Account Demo User to login to the console.

    ```bash
    euare-useraddloginprofile --password demo123-demo --region $USER_REGION demo
    ```

16. Create Demo (demo) Account Demo (demo) User Access Key

    This allows the Demo Account Demo User to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/demo

    result=$(euare-useraddkey --region $USER_REGION demo)
    read access_key secret_key <<< $result

    cat << EOF > ~/.creds/$REGION/demo/demo/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

17. Create Demo (demo) Account Demo (demo) User Euca2ools Profile

    This allows the Demo Account Demo User to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-demo]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones --region $REGION-demo-demo@$REGION
    ```

18. Create Demo (demo) Account Demo (demo) User AWSCLI Profile

    This allows the Demo Account Demo User to run AWSCLI commands.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile $REGION-demo-demo]
    region = $REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$REGION-demo-demo]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile $REGION-demo-demo --region $REGION
    ```

19. Create Demo (demo) Account Developer (developer) User

    ```bash
    euare-usercreate --region $USER_REGION developer
    ```

20. Add Demo (demo) Account Developer (developer) to Developers (Developers) Group

    ```bash
    euare-groupadduser --user-name developer --region $USER_REGION Developers
    ```


21. Create Demo (demo) Account Developer (developer) User Login Profile

    This allows the Demo Account Developer User to login to the console.

    ```bash
    euare-useraddloginprofile --password demo123-developer --region $USER_REGION developer
    ```

22. Create Demo (demo) Account Developer (developer) User Access Key

    This allows the Demo Account Developer User to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/developer

    result=$(euare-useraddkey --region $USER_REGION developer)
    read access_key secret_key <<< $result

    cat << EOF > ~/.creds/$REGION/demo/developer/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

23. Create Demo (demo) Account Developer (developer) User Euca2ools Profile

    This allows the Demo Account Developer User to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-developer]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones --region $REGION-demo-developer@$REGION
    ```

24. Create Demo (demo) Account Developer (developer) User AWSCLI Profile

    This allows the Demo Account Developer User to run AWSCLI commands.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile $REGION-demo-developer]
    region = $REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$REGION-demo-developer]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile $REGION-demo-developer --region $REGION
    ```

25. Create Demo (demo) Account User (user) User

    ```bash
    euare-usercreate --region $USER_REGION user
    ```

26. Add Demo (demo) Account User (user) to Users (Users) Group

    ```bash
    euare-groupadduser --user-name user --region $USER_REGION Users
    ```

27. Create Demo (demo) Account User (user) User Login Profile

    This allows the Demo Account User User to login to the console.

    ```bash
    euare-useraddloginprofile --password demo123-user --region $USER_REGION user
    ```

28. Create Demo (demo) Account User (user) User Access Key

    This allows the Demo Account User User to run API commands.

    ```bash
    mkdir -p ~/.creds/$REGION/demo/user

    result=$(euare-useraddkey --region $USER_REGION user)
    read access_key secret_key <<< $result

    cat << EOF > ~/.creds/$REGION/demo/user/iamrc
    AWSAccessKeyId=$access_key
    AWSSecretKey=$secret_key
    EOF
    ```

29. Create Demo (demo) Account User (user) User Euca2ools Profile

    This allows the Demo Account User User to run API commands via Euca2ools.

    ```bash
    cat << EOF >> ~/.euca/$REGION.ini
    [user $REGION-demo-user]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones --region $REGION-demo-user@$REGION
    ```

30. Create Demo (demo) Account User (user) User AWSCLI Profile

    This allows the Demo Account Demo User to run AWSCLI commands.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile $REGION-demo-user]
    region = $REGION
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials
    [$REGION-demo-user]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key
    
    EOF
    
    aws ec2 describe-availability-zones --profile $REGION-demo-user --region $REGION
    ```

31. List Demo Resources

    ```bash
    euca-describe-images --region $USER_REGION

    euca-describe-keypairs --region $USER_REGION

    euare-rolelistbypath --region $USER_REGION
    euare-instanceprofilelistbypath --region $USER_REGION
    euare-instanceprofilelistforrole --region $USER_REGION Demos

    euare-grouplistbypath --region $USER_REGION

    euare-userlistbypath --region $USER_REGION

    euare-grouplistusers --region $USER_REGION Demos
    euare-grouplistusers --region $USER_REGION Developers
    euare-grouplistusers --region $USER_REGION Users
    ```

32. Display Euca2ools Configuration

    ```bash
    cat /etc/euca2ools/conf.d/$REGION.ini

    cat ~/.euca/global.ini

    cat ~/.euca/$REGION.ini
    ```

33. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

