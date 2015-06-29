# Demo Dependencies Manual Installation

This is the set of manual steps to setup additional dependencies within the demo account.

### Initialize Demo Dependencies Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/feature/poc/bin/euca-demo-02-initialize-dependencies.sh

Help is available when running this script, via the -? flag.

```bash
euca-demo-02-initialize-dependencies.sh -?
Usage: euca-demo-02-initialize-dependencies.sh [-I [-s | -f]] [-a account] [-p password] [-c]
  -I          non-interactive
  -s          slower: increase pauses by 25%
  -f          faster: reduce pauses by 25%
  -a account  account to create for use in demos (default: demo)
  -p password password prefix for demo account users (default: demo123)
  -c          Create new key pairs instead of importing existing public keys

```

By default, the demo account used is named "demo", but this can be overridden with the -a account flag.
This allows alternate and/or multiple demo accounts to be used.

Credentials are now stored in a directory structure which allows for multiple regions.

Your ~/.bash_profile should set the environment variable AWS_DEFAULT_REGION to reference the local region.

### Initialize Demo Dependencies Manual Procedure

1. Use Demo (demo) Account Administrator credentials

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1

    source ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc
    ```

2. List Images available to Demo (demo) Account Administrator

    ```bash
    euca-describe-images -a
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
    lN9/vp/T+iQ9jgHvs1WcqF4PRTJLaUd3Dy+yv9Bu37vWZNCngmJwvKifKUcb
    EOF

    euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo
    ```

4. Initialize Euca2ools Configuration

    This may already have been done if this script is being run on the Cloud Controller, when the
    Demo (demo) Account was created, so test before re-initializing.

    Use Demo (demo) Account Administrator eucarc file for values

    The default version is configured for direct access using the Eucalyptus standard port.

    ```bash
    region=$AWS_DEFAULT_REGION
    ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$region/demo/admin/eucarc)
    s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$region/demo/admin/eucarc)
    iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$region/demo/admin/eucarc)
    sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$region/demo/admin/eucarc)
    as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$region/demo/admin/eucarc)
    cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$region/demo/admin/eucarc)
    cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$region/demo/admin/eucarc)
    elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$region/demo/admin/eucarc)
    swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$region/demo/admin/eucarc)
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/demo/admin/eucarc)

    if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools.ini; then
        echo "# Euca2ools Configuration file" > ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        echo "[global]" > ~/.euca/euca2ools.ini
        echo "region = &region" > ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
        echo "[region $region]" >> ~/.euca/euca2ools.ini
        echo "autoscaling-url = $as_url" >> ~/.euca/euca2ools.ini
        echo "cloudformation-url = $cfn_url" >> ~/.euca/euca2ools.ini
        echo "ec2-url = $ec2_url" >> ~/.euca/euca2ools.ini
        echo "elasticloadbalancing-url = $elb_url" >> ~/.euca/euca2ools.ini
        echo "iam-url = $iam_url" >> ~/.euca/euca2ools.ini
        echo "monitoring-url $cw_url" >> ~/.euca/euca2ools.ini
        echo "s3-url = $s3_url" >> ~/.euca/euca2ools.ini
        echo "sts-url = $sts_url" >> ~/.euca/euca2ools.ini
        echo "swf-url = $swf_url" >> ~/.euca/euca2ools.ini
        echo "user = demo-admin" >> ~/.euca/euca2ools.ini
        echo >> ~/.euca/euca2ools.ini
    fi

    echo "[user demo-admin]" >> ~/.euca/euca2ools.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
    echo >> ~/.euca/euca2ools.ini

    chmod -R og-rwx ~/.euca
    ```

    The ssl version is configured for indirect access via an Nginx proxy which terminates SSL on the SSL standard port.

    ```bash
    ec2_ssl_url=${ec2_url/http:/https:} && ec2_ssl_url=${ec2_ssl_url/:8773/}
    s3_ssl_url=${s3_url/http:/https:} && s3_ssl_url=${s3_ssl_url/:8773/}
    iam_ssl_url=${iam_url/http:/https:} && iam_ssl_url=${iam_ssl_url/:8773/}
    sts_ssl_url=${sts_url/http:/https:} && sts_ssl_url=${sts_ssl_url/:8773/}
    as_ssl_url=${as_url/http:/https:} && as_ssl_url=${as_ssl_url/:8773/}
    cfn_ssl_url=${cfn_url/http:/https:} && cfn_ssl_url=${cfn_ssl_url/:8773/}
    cw_ssl_url=${cw_url/http:/https:} && cw_ssl_url=${cw_ssl_url/:8773/}
    elb_ssl_url=${elb_url/http:/https:} && elb_ssl_url=${elb_ssl_url/:8773/}
    swf_ssl_url=${swf_url/http:/https:} && swf_ssl_url=${swf_ssl_url/:8773/}

    if ! grep -s -q "\[region $region\]" ~/.euca/euca2ools-ssl.ini; then
        echo "# Euca2ools Configuration file" > ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini
        echo "[global]" > ~/.euca/euca2ools-ssl.ini
        echo "region = &region" > ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini
        echo "[region $region]" >> ~/.euca/euca2ools-ssl.ini
        echo "autoscaling-url = $as_url" >> ~/.euca/euca2ools-ssl.ini
        echo "cloudformation-url = $cfn_url" >> ~/.euca/euca2ools-ssl.ini
        echo "ec2-url = $ec2_url" >> ~/.euca/euca2ools-ssl.ini
        echo "elasticloadbalancing-url = $elb_url" >> ~/.euca/euca2ools-ssl.ini
        echo "iam-url = $iam_url" >> ~/.euca/euca2ools-ssl.ini
        echo "monitoring-url $cw_url" >> ~/.euca/euca2ools-ssl.ini
        echo "s3-url = $s3_url" >> ~/.euca/euca2ools-ssl.ini
        echo "sts-url = $sts_url" >> ~/.euca/euca2ools-ssl.ini
        echo "swf-url = $swf_url" >> ~/.euca/euca2ools-ssl.ini
        echo "user = demo-admin" >> ~/.euca/euca2ools-ssl.ini
        echo >> ~/.euca/euca2ools-ssl.ini
    fi

    echo "[user demo-admin]" >> ~/.euca/euca2ools-ssl.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
    echo >> ~/.euca/euca2ools-ssl.ini

    chmod -R og-rwx ~/.euca
    ```

5. Initialize AWS CLI Configuration

    This may already have been done if this script is being run on the Cloud Controller, when the
    Demo (demo) Account was created, so test before re-initializing.

    This assumes the AWS CLI was installed and configured with Eucalyptus endpoints via separate instructions.

    ```bash
    region=$AWS_DEFAULT_REGION
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$region/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$region/demo/admin/eucarc)

    if ! grep -s -q "AWS Config file" ~/.aws/config; then
        echo "#" > ~/.aws/config
        echo "# AWS Config file" >> ~/.aws/config
        echo "#" >> ~/.aws/config
        echo >> ~/.aws/config
    fi

    echo "[profile $region-demo-admin]" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "output = text" >> ~/.aws/config
    echo >> ~/.aws/config

    if ! grep -s -q "AWS Credentials file" ~/.aws/credentials; then
        echo "#" > ~/.aws/credentials
        echo "# AWS Credentials file" >> ~/.aws/credentials
        echo "#" >> ~/.aws/credentials
        echo >> ~/.aws/credentials
    fi

    echo "[$region-demo-admin]" >> ~/.aws/credentials
    echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
    echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
    echo >> ~/.aws/credentials

    chmod -R og-rwx ~/.aws
    ```

6. Create Demo (demo) Account Demo (demo) User

    ```bash
    euare-usercreate -u demo
    ```

7. Create Demo (demo) Account Demo (demo) User Login Profile

    This allows the Demo Account Demo User to login to the console

    ```bash
    euare-useraddloginprofile -u demo -p demo123-demo
    ```

8. Create Demo (demo) Account Demo (demo) User Access Key

    This allows the Demo Account Demo User to run API commands

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/demo/demo

    result=$(euare-useraddkey -u demo)
    read access_key secret_key <<< $result

    echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/demo/demo/iamrc
    echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/demo/demo/iamrc

    cat ~/.creds/$AWS_DEFAULT_REGION/demo/demo/iamrc
    ```

9. Create Demo (demo) Account Demo (demo) User Tools Profile

    This allows the Demo Account Demo User to run API commands via Euca2ools

    ```bash
    echo "[user demo-demo]" >> ~/.euca/euca2ools.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
    echo >> ~/.euca/euca2ools.ini
    ```

    ```bash
    echo "[user demo-demo]" >> ~/.euca/euca2ools-ssl.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
    echo >> ~/.euca/euca2ools-ssl.ini
    ```

10. Create Demo (demo) Account Demo (demo) User AWS CLI Profile

    This allows the Demo Account Demo User to run AWS CLI commands

    ```bash
    region=$AWS_DEFAULT_REGION

    echo "[profile $region-demo-demo]" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "output = text" >> ~/.aws/config
    echo >> ~/.aws/config

    echo "[$region-demo-demo]" >> ~/.aws/credentials
    echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
    echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
    echo >> ~/.aws/credentials
    ```

11. Create Demo (demo) Account Developer (developer) User

    ```bash
    euare-usercreate -u developer
    ```

12. Create Demo (demo) Account Developer (developer) User Login Profile

    This allows the Demo Account Developer User to login to the console

    ```bash
    euare-useraddloginprofile -u developer -p demo123-developer
    ```

13. Create Demo (demo) Account Developer (developer) User Access Key

    This allows the Demo Account Developer User to run API commands

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/demo/developer

    result=$(euare-useraddkey -u developer)
    read access_key secret_key <<< $result

    echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/demo/developer/iamrc
    echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/demo/developer/iamrc

    cat ~/.creds/$AWS_DEFAULT_REGION/demo/developer/iamrc
    ```

14. Create Demo (demo) Account Developer (developer) User Tools Profile

    This allows the Demo Account Developer User to run API commands via Euca2ools

    ```bash
    echo "[user demo-developer]" >> ~/.euca/euca2ools.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
    echo >> ~/.euca/euca2ools.ini
    ```

    ```bash
    echo "[user demo-developer]" >> ~/.euca/euca2ools-ssl.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
    echo >> ~/.euca/euca2ools-ssl.ini
    ```

15. Create Demo (demo) Account Developer (developer) User AWS CLI Profile

    This allows the Demo Account Developer User to run AWS CLI commands

    ```bash
    region=$AWS_DEFAULT_REGION

    echo "[profile $region-demo-developer]" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "output = text" >> ~/.aws/config
    echo >> ~/.aws/config

    echo "[$region-demo-developer]" >> ~/.aws/credentials
    echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
    echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
    echo >> ~/.aws/credentials
    ```

16. Create Demo (demo) Account User (user) User

    ```bash
    euare-usercreate -u demo
    ```

17. Create Demo (demo) Account User (user) User Login Profile

    This allows the Demo Account User User to login to the console

    ```bash
    euare-useraddloginprofile -u user -p demo123-user
    ```

18. Create Demo (demo) Account User (user) User Access Key

    This allows the Demo Account User User to run API commands

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/demo/user

    result=$(euare-useraddkey -u user)
    read access_key secret_key <<< $result

    echo "AWSAccessKeyId=$access_key"  > ~/.creds/$AWS_DEFAULT_REGION/demo/user/iamrc
    echo "AWSSecretKey=$secret_key"   >> ~/.creds/$AWS_DEFAULT_REGION/demo/user/iamrc

    cat ~/.creds/$AWS_DEFAULT_REGION/demo/user/iamrc
    ```

19. Create Demo (demo) Account User (user) User Tools Profile

    This allows the Demo Account User User to run API commands via Euca2ools

    ```bash
    echo "[user demo-user]" >> ~/.euca/euca2ools.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools.ini
    echo >> ~/.euca/euca2ools.ini
    ```

    ```bash
    echo "[user demo-user]" >> ~/.euca/euca2ools-ssl.ini
    echo "key-id = $access_key" >> ~/.euca/euca2ools-ssl.ini
    echo "secret-key = $secret_key" >> ~/.euca/euca2ools-ssl.ini
    echo >> ~/.euca/euca2ools-ssl.ini
    ```

20. Create Demo (demo) Account User (user) User AWS CLI Profile

    This allows the Demo Account Demo User to run AWS CLI commands

    ```bash
    region=$AWS_DEFAULT_REGION

    echo "[profile $region-demo-user]" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "output = text" >> ~/.aws/config
    echo >> ~/.aws/config

    echo "[$region-demo-user]" >> ~/.aws/credentials
    echo "aws_access_key_id = $access_key" >> ~/.aws/credentials
    echo "aws_secret_access_key = $secret_key" >> ~/.aws/credentials
    echo >> ~/.aws/credentials
    ```

21. Create Demo (demo) Account Demos (Demos) Group

    This Group is intended for Demos which have Administrator access to Resources.

    ```bash
    euare-groupcreate -g Demos
    ```

22. Create Demo (demo) Account Demos (Demos) Group Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    cat << EOF >> /var/tmp/DemosGroupPolicy.json
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

    euare-groupuploadpolicy -g Demos -p DemosPolicy \
                            -f /var/tmp/DemosGroupPolicy.json
    ```

23. Add Demo (demo) Account Demos (Demos) Group members

    ```bash
    euare-groupadduser -g Demos -u demo
    ```

24. Create Demo (demo) Account Developers (Developers) Group

    This Group is intended for Developers who can modify Resources.

    ```bash
    euare-groupcreate -g Developers
    ```

25. Create Demo (demo) Account Developers (Developers) Group Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    cat << EOF >> /var/tmp/DevelopersGroupPolicy.json
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

    euare-groupuploadpolicy -g Developers -p DevelopersPolicy \
                            -f /var/tmp/DevelopersGroupPolicy.json
    ```

26. Add Demo (demo) Account Developers (Developers) Group members

    ```bash
    euare-groupadduser -g Developers -u developer
    ```

27. Create Demo (demo) Account Users (Users) Group

    This Group is intended for Users who can view but not modify Resources.

    ```bash
    euare-groupcreate -g Users
    ```

28. Create Demo (demo) Account Users (Users) Group Policy

    This Policy provides ReadOnly access to all resources

    ```bash
    cat << EOF >> /var/tmp/UsersGroupPolicy.json
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

    euare-groupuploadpolicy -g Users -p UsersPolicy \
                            -f /var/tmp/UsersGroupPolicy.json
    ```

29. Add Demo (demo) Account Users (Users) Group members

    ```bash
    euare-groupadduser -g Users -u user
    ```

30. Create Demo (demo) Account Demos (Demos) Role and associated Instance Profile

    This Role is intended for Demos which need Administrator access to Resources.

    ```bash
    cat << EOF > /var/tmp/DemosRoleTrustPolicy.json
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

    euare-rolecreate -r Demos -f /var/tmp/DemosRoleTrustPolicy.json

    euare-instanceprofilecreate -s Demos

    aws iam add-role-to-instance-profile -s Demos -r Demos
    ```

31. Create Demo (demo) Account Demos (Demos) Role Policy

    This Policy provides full access to all resources, except users and groups.

    ```bash
    cat << EOF >> /var/tmp/DemosRolePolicy.json
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

    euare-roleuploadpolicy -r Demos -p DemosPolicy \
                           -f /var/tmp/DemosRolePolicy.json
    ```

32. List Demo Resources

    ```bash
    euca-describe-images

    euca-describe-keypairs

    euare-userlistbypath

    euare-grouplistbypath
    euare-grouplistusers -g Demos
    euare-grouplistusers -g Developers
    euare-grouplistusers -g Users

    euare-rolelistbypath
    euare-instanceprofilelistbypath
    euare-instanceprofilelistforrole
    ```

33. List Tools Configuration

    ```bash
    cat ~/.euca2ools.ini

    cat ~/.euca2ools-ssl.ini
    ```

34. List Tools Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

