# Demo Manual Initialization

This is the set of manual steps to initialize a new Eucalyptus system for demos.

### Initialize Demos Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/master/demos/demo-00-initialize/bin/demo-00-initialize.sh

Help is available when running this script, via the -? flag.

```bash
demo-00-initialize.sh -?
Usage: demo-00-initialize.sh [-I [-s | -f]] [-d] [-l]
  -I  non-interactive
  -s  slower: increase pauses by 25%
  -f  faster: reduce pauses by 25%
  -d  use direct service endpoints in euca2ools.ini
  -l  Use local mirror for Demo CentOS image
```

Credentials are now stored in a directory structure which allows for multiple regions.

Your ~/.bash_profile should set the environment variable AWS_DEFAULT_REGION to reference the local region.

### Initialize Demos Manual Procedure

1. Use Eucalyptus Administrator credentials

    Adjust AWS_DEFAULT_REGION to your new region.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Initialize Euca2ools Configuration

    Use Eucalyptus Account Administrator eucarc file for values

    Since we have an SSL reverse proxy in place, we will convert the default service endpoints to their proxy equivalents.

    ```bash
    ec2_url=$(sed -n -e "s/export EC2_URL=\(.*\)$/\1services\/compute/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    s3_url=$(sed -n -e "s/export S3_URL=\(.*\)$/\1services\/objectstorage/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    iam_url=$(sed -n -e "s/export AWS_IAM_URL=\(.*\)$/\1services\/Euare/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    sts_url=$(sed -n -e "s/export TOKEN_URL=\(.*\)$/\1services\/Tokens/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    as_url=$(sed -n -e "s/export AWS_AUTO_SCALING_URL=\(.*\)$/\1services\/AutoScaling/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    cfn_url=$(sed -n -e "s/export AWS_CLOUDFORMATION_URL=\(.*\)$/\1services\/CloudFormation/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    cw_url=$(sed -n -e "s/export AWS_CLOUDWATCH_URL=\(.*\)$/\1services\/CloudWatch/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    elb_url=$(sed -n -e "s/export AWS_ELB_URL=\(.*\)$/\1services\/LoadBalancing/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    swf_url=$(sed -n -e "s/export AWS_SIMPLEWORKFLOW_URL=\(.*\)$/\1services\/SimpleWorkflow/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

    ec2_ssl_url=${ec2_url/http:/https:} && ec2_ssl_url=${ec2_ssl_url/:8773/}
    s3_ssl_url=${s3_url/http:/https:} && s3_ssl_url=${s3_ssl_url/:8773/}
    iam_ssl_url=${iam_url/http:/https:} && iam_ssl_url=${iam_ssl_url/:8773/}
    sts_ssl_url=${sts_url/http:/https:} && sts_ssl_url=${sts_ssl_url/:8773/}
    as_ssl_url=${as_url/http:/https:} && as_ssl_url=${as_ssl_url/:8773/}
    cfn_ssl_url=${cfn_url/http:/https:} && cfn_ssl_url=${cfn_ssl_url/:8773/}
    cw_ssl_url=${cw_url/http:/https:} && cw_ssl_url=${cw_ssl_url/:8773/}
    elb_ssl_url=${elb_url/http:/https:} && elb_ssl_url=${elb_ssl_url/:8773/}
    swf_ssl_url=${swf_url/http:/https:} && swf_ssl_url=${swf_ssl_url/:8773/}

    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/euca2ools.ini
    # Euca2ools Configuration file (via SSL proxy)
    
    [global]
    region = $AWS_DEFAULT_REGION
    
    [region $AWS_DEFAULT_REGION]
    autoscaling-url = $as_ssl_url
    cloudformation-url = $cfn_ssl_url
    ec2-url = $ec2_ssl_url
    elasticloadbalancing-url = $elb_ssl_url
    iam-url = $iam_ssl_url
    monitoring-url $cw_ssl_url
    s3-url = $s3_ssl_url
    sts-url = $sts_ssl_url
    swf-url = $swf_ssl_url
    user = admin

    [user admin]
    key-id = $access_key
    secret-key = $secret_key

    EOF

    euca-describe-availability-zones verbose

    euca-describe-availability-zones verbose --region admin@$AWS_DEFAULT_REGION
    ```

3. Initialize AWSCLI Configuration

    This assumes the AWSCLI was installed and configured with Eucalyptus endpoints via separate instructions.

    ```bash
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc)

    mkdir -p ~/.aws
    chmod 0700 ~/.aws

    cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = $AWS_DEFAULT_REGION
    output = text

    [profile $AWS_DEFAULT_REGION-admin]
    region = $AWS_DEFAULT_REGION
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #

    [default]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    [$AWS_DEFAULT_REGION-admin]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile=default

    aws ec2 describe-availability-zones --profile=$AWS_DEFAULT_REGION-admin
    ```

4. Import Eucalyptus Administrator Demo Keypair

    ```bash
    cat << EOF > ~/.ssh/demo_id_rsa
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEArVIDtD6bstdVKVNiJychI/1b59KbsrW9OFcoyrS2cIalXE/j
    2HCY+9BZs0OIi2Nh/9iMoQvRQxj/nrHsyee7yDCkM4cK7yqKkyMK9QNs+1gWNO3O
    CrWoQLdssAbu60/rLt170KHxZQI5vsZvk/3a2O6jYEU7Q6ukuiwoPsAwSzG7nVXy
    a0byLTi5qyJjBupr0Snme7kxeU0ReZWEVj5TpI6jmvdpMxxYhYpZBGiYYgWWXhVy
    x0HswP88Stfkxahcs+MA4cEtjpCRweqNb0C2a6/kbL2mJavtxJCxv1IDBPON6zs1
    KoMEp5Qkg0tux527QBdIqmlObZmWKcN3se8gkwIDAQABAoIBAAF5Gfj1M0OQ2vNv
    9vyYM4rnw1k0DAi3zLTm4LzgTlCkhFFFiI01X8d8HNcOMuHkZVfUUlWoEQ497yY9
    IuMQaiMobqzVb/1aYjUf7h7o+YslU4L9pmum4ZgzNuREGtG7KyeJ0FyUk8WlADKj
    4xzh4nNHi/HshLVthwfiCjGGVqK89OLuX+vEEtkvWwfe3JafurQuMTjHQluHt32N
    cxCoTkS0ZZf3MSTMJnULWFc0lcOWflArNbvUqIDQONtV74UbEQZUt68dRCxTQ7jy
    Wkg4ojOaNfRlXIktLmAwOKd4xml4LA8am6PRJsEwpIUgXfK6ecUz1NE0lt5d/HhY
    8z/sgIECgYEA2wf90YojjLiIgJibXFxJrFeZRbHcU7Sy5OPs/GLHaABi5+W1/eaH
    S0hI4cjrlsydnIAyVAVl6rO5YJ8MWKsZv2VToXQ2Zx1xnIFSENpc3iTPj1WU2e7z
    b6pvWHEJnxoSO5Feir44TsgIRhleUb5vv31DNHzYqkJQ6BpelfbX1tMCgYEAypLt
    G8JY40TLszkvB9J3sUTCFJ9bp6GjW1ct/gU3/Rn7zBZUrBu6n03kctfJxjcRnaQy
    N46pwfMzoCArq8wnml3YcW4GRtwB+yFO2D0k6hfOnIKPx9R+ycRejHaH3oUJ+9GD
    KRQkwpXTs1Eo0+ow+LEWQL4nW5JNWcyO5BY090ECgYEAq5miONViLrCweReWuJCx
    Q63Jrnm/ZXEvqvYLSFzXX1rWIlqs78P5gXibaRFxyc57OQ6S35LvGyc9eD6DfMBo
    RrRLBjY3HShLR1NmCUAa/AuY9fIV0XxNCtJbs82zvQu+9x5YFJkdIlPDb7AWXjK1
    +C9aRLf/Q7z7CC0Ip7MhvPMCgYBKCdNRjwHP5ugQlDjlQf5vMvNAeFIWfZRoIP/1
    VND219VY7Vx7HxNhgCWb99SOdrgghs+30JOpCIt43ek4PEDJQb2HD7CJm4W51J2t
    mQNx78ubFnkYj0jb08K+0d+s67EPca7fh7Y7zGj4pBQpB/JoIslAVn+qD1noFUSw
    hpFLQQKBgAQ5UbagDDbC4YiOsA9Z3/6EETM9EvWR/3rLnlMUR+IQZR2Mit5YYFwb
    OQIUETTrKBR0UKG7QFuy287Lo/mK20QkVL/egF0/hdeufPJB2cqyYI+9svelw/pG
    EOWpZm9AoLPLD0jGsWlkIw4qZDEewgl+lihiFiOjc6RFxWt6PCMb
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 0600 ~/.ssh/demo_id_rsa

    cat << EOF > ~/.ssh/demo_id_rsa.pub
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtUgO0Ppuy11UpU2InJyEj/Vvn\
    0puytb04VyjKtLZwhqVcT+PYcJj70FmzQ4iLY2H/2IyhC9FDGP+esezJ57vIMKQz\
    hwrvKoqTIwr1A2z7WBY07c4KtahAt2ywBu7rT+su3XvQofFlAjm+xm+T/drY7qNg\
    RTtDq6S6LCg+wDBLMbudVfJrRvItOLmrImMG6mvRKeZ7uTF5TRF5lYRWPlOkjqOa\
    92kzHFiFilkEaJhiBZZeFXLHQezA/zxK1+TFqFyz4wDhwS2OkJHB6o1vQLZrr+Rs\
    vaYlq+3EkLG/UgME843rOzUqgwSnlCSDS27HnbtAF0iqaU5tmZYpw3ex7yCT\
    demo@hpcloud.com
    EOF

    euca-import-keypair -f ~/.ssh/demo_id_rsa.pub demo
    ```

5. Download Demo Generic Image (CentOS 6.6)

    This is the Generic Cloud Image created by CentOS.

    ```bash
    wget http://cloud.centos.org/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz \
         -O /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    qemu-img convert -f qcow2 -O raw /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2 \
                                     /var/tmp/CentOS-6-x86_64-GenericCloud.raw
    ```

6. Install Demo Generic Image

    ```bash
    euca-install-image -n centos66 -b images -r x86_64 -i /var/tmp/CentOS-6-x86_64-GenericCloud.raw \
                       --virtualization-type hvm
    ```

7. Download Demo CFN + AWSCLI Image (CentOS 6.6)

    This is a Generic Cloud Image modified to add CFN tools and AWSCLI.

    ```bash
    wget https://s3.amazonaws.com/demo-eucalyptus/demo-30-cfn-wordpress/Centos-6-x86_64-CFN-AWSCLI.raw.xz \
         -O /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz
    ```

8. Install Demo CFN + AWSCLI Image

    ```bash
    euca-install-image -n centos66-cfn-init -b images -r x86_64 -i /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw \
                       --virtualization-type hvm
    ```

9. Modify an Instance Type

    Change the m1.small instance type to use 1GB memory and 10GB disk, as the default CentOS
    cloud image requires this additional memory and disk to run.

    ```bash
    euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small
    ```

10. List Demo Resources

    ```bash
    euca-describe-keypairs

    euca-describe-images

    euca-describe-instance-types
    ```

11. List Euca2ools Configuration

    ```bash
    cat ~/.euca/euca2ools.ini
    ```

12. List AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

