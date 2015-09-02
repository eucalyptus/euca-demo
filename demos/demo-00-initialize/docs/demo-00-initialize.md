# Demo Initialize: Initialize Region

This document describes the manual procedure to initialize a new Eucalyptus Region for demos.

### Prerequisites

This variant must be run by root on the Eucalyptus CLC host. 
 
It assumes the environment was installed via FastStart and the additional scripts needed to 
initialize DNS, PKI, SSL reverse-proxy and the initialization of Euca2ools and AWSCLI, as 
described in the [FastStart Install](../../../installs/install-10-faststart) section, have
been run, or equivalent manual configuration has been done. 

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export AWS_DEFAULT_REGION=hp-gol01-f1
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com
    export AWS_DEFAULT_PROFILE=$AWS_DEFAULT_REGION-admin
    export AWS_CREDENTIAL_FILE=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/iamrc
    ```

### Initialize Demos

The steps below are automated in the [demo-00-initialize.sh](../bin/demo-00-initialize.sh) script.

2. Initialize Euca2ools with Eucalyptus Region Endpoints

    We will programatically construct the service endpoint URLs, assuming the SSL reverse proxy is in place.

    ```bash
    autoscaling_url=https://autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/AutoScaling
    cloudformation_url=https://cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/CloudFormation
    ec2_url=https://compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/compute
    elasticloadbalancing_url=https://loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/LoadBalancing
    iam_url=https://euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/Euare
    monitoring_url=https://cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/CloudWatch
    s3_url=https://objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/objectstorage
    sts_url=https://tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/Tokens
    swf_url=https://simpleworkflow.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN/services/SimpleWorkflow

    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/global.ini
    ; Eucalyptus Global

    [global]
    region = $AWS_DEFAULT_REGION

    EOF

    cat << EOF > /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini
    ; Eucalyptus Region $AWS_DEFAULT_REGION

    [region $AWS_DEFAULT_REGION]
    autoscaling-url = $autoscaling_url
    cloudformation-url = $cloudformation_url
    ec2-url = $ec2_url
    elasticloadbalancing-url = $elasticloadbalancing_url
    iam-url = $iam_url
    monitoring-url $monitoring_url
    s3-url = $s3_url
    sts-url = $sts_url
    swf-url = $swf_url
    user = $region-admin

    certificate = /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    verify-ssl = false

    EOF

    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    chmod 0644 /usr/share/euca2ools/certs/cert-$AWS_DEFAULT_REGION.pem
    ```

3. Initialize Eucalyptus Administrator Euca2ools Profile

    Obtain the values we need from the Region's Eucalyptus Administrator eucarc file.

    ```bash
    account_id=$(sed -n -e "s/export EC2_ACCOUNT_NUMBER='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    access_key=$(sed -n -e "s/export AWS_ACCESS_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    secret_key=$(sed -n -e "s/export AWS_SECRET_KEY='\(.*\)'$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    private_key=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/$(sed -n -e "s/export EC2_PRIVATE_KEY=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)
    certificate=$HOME/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/$(sed -n -e "s/export EC2_CERT=\${EUCA_KEY_DIR}\/\(.*\)$/\1/p" ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc)

    cat << EOF > ~/.euca/$AWS_DEFAULT_REGION.ini
    ; Eucalyptus Region $AWS_DEFAULT_REGION

    [user $AWS_DEFAULT_REGION-admin]
    account-id = $account_id
    key-id = $access_key
    secret-key = $secret_key
    private-key = $private_key
    certificate = $certificate

    EOF

    euca-describe-availability-zones verbose --region $AWS_DEFAULT_REGION-admin@$AWS_DEFAULT_REGION
    ```

4. Create Eucalyptus Administrator AWSCLI Profile

    This assumes the AWSCLI was installed and configured with Eucalyptus endpoints via separate instructions.

    Obtain the values we need from the Region's Eucalyptus Administrator eucarc file.

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

    aws ec2 describe-availability-zones --profile default --region $AWS_DEFAULT_REGION

    aws ec2 describe-availability-zones --profile $AWS_DEFAULT_REGION-admin --region $AWS_DEFAULT_REGION
    ```

5. Import Eucalyptus Administrator Demo Keypair

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

6. Create sample-templates Bucket

    This bucket is intended for Sample CloudFormation Templates.

    ```bash
    aws s3api create-bucket --bucket sample-templates --acl public-read --profile $AWS_DEFAULT_REGION-admin --region=$AWS_DEFAULT_REGION
    ```

7. Download Demo Generic Image (CentOS 6.6)

    This is the Generic Cloud Image created by CentOS.

    ```bash
    wget http://cloud.centos.org/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz \
         -O /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    qemu-img convert -f qcow2 -O raw /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2 \
                                     /var/tmp/CentOS-6-x86_64-GenericCloud.raw
    ```

8. Install Demo Generic Image

    ```bash
    euca-install-image -n centos66 -b images -r x86_64 -i /var/tmp/CentOS-6-x86_64-GenericCloud.raw \
                       --virtualization-type hvm
    ```

9. Download Demo CFN + AWSCLI Image (CentOS 6.6)

    This is a Generic Cloud Image modified to add CFN tools and AWSCLI.

    ```bash
    wget http://images-euca.s3-website-us-east-1.amazonaws.com/$cfn_awscli_image.raw.xz \
         -O /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz
    ```

10. Install Demo CFN + AWSCLI Image

    ```bash
    euca-install-image -n centos66-cfn-init -b images -r x86_64 -i /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw \
                       --virtualization-type hvm
    ```

11. Modify an Instance Type

    Change the m1.small instance type to use 1GB memory and 10GB disk, as the default CentOS
    cloud image requires this additional memory and disk to run.

    ```bash
    euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small
    ```

12. List Demo Resources

    ```bash
    euca-describe-keypairs

    euca-describe-images

    euca-describe-instance-types
    ```

13. Display Euca2ools Configuration

    ```bash
    cat /etc/euca2ools/conf.d/$AWS_DEFAULT_REGION.ini

    cat ~/.euca/global.ini

    cat ~/.euca/$AWS_DEFAULT_REGION.ini
    ```

14. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

