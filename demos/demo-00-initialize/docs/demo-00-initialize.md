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
    export DOMAIN=mjc.prc.eucalyptus-systems.com
    export REGION=hp-gol01-d6
    export USER=admin

    export USER_REGION=$REGION-$USER@$REGION
    export PROFILE=$REGION-$USER
    ```

### Initialize Demos

The steps below are automated in the [demo-00-initialize.sh](../bin/demo-00-initialize.sh) script.

2. Initialize Euca2ools with Eucalyptus Region Endpoints

    We will programatically construct the service endpoint URLs, assuming the SSL reverse proxy is in place.

    ```bash
    autoscaling_url=https://autoscaling.$REGION.$DOMAIN/
    bootstrap_url=https://bootstrap.$REGION.$DOMAIN/
    cloudformation_url=https://cloudformation.$REGION.$DOMAIN/
    ec2_url=https://ec2.$REGION.$DOMAIN/services/compute/
    elasticloadbalancing_url=https://elasticloadbalancing.$REGION.$DOMAIN/
    iam_url=https://iam.$REGION.$DOMAIN/
    monitoring_url=https://monitoring.$REGION.$DOMAIN/
    properties_url=https://properties.$REGION.$DOMAIN/
    reporting_url=https://reporting.$REGION.$DOMAIN/
    s3_url=https://s3.$REGION.$DOMAIN/
    sts_url=https://sts.$REGION.$DOMAIN/

    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/global.ini
    ; Eucalyptus Global

    [global]
    default-region = $REGION

    EOF

    cat << EOF > /etc/euca2ools/conf.d/$REGION.ini
    ; Eucalyptus Region $REGION

    [region $REGION]
    autoscaling-url = $autoscaling_url
    bootstrap-url = $bootstrap_url
    cloudformation-url = $cloudformation_url
    ec2-url = $ec2_url
    elasticloadbalancing-url = $elasticloadbalancing_url
    iam-url = $iam_url
    monitoring-url = $monitoring_url
    properties-url = $properties_url
    reporting-url = $reporting_url
    s3-url = $s3_url
    sts-url = $sts_url
    user = $REGION-admin

    certificate = /usr/share/euca2ools/certs/cert-$REGION.pem
    verify-ssl = true

    EOF

    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-$REGION.pem
    chmod 0644 /usr/share/euca2ools/certs/cert-$REGION.pem
    ```

3. Initialize Eucalyptus Administrator Euca2ools Profile

    This allows the Eucalyptus Administrator to run API commands via Euca2ools.

    ```bash
    access_key=$(clcadmin-assume-system-credentials | sed -n -e 's/export AWS_ACCESS_KEY="\(.*\)";$/\1/p')
    secret_key=$(clcadmin-assume-system-credentials | sed -n -e 's/export AWS_SECRET_KEY="\(.*\)";$/\1/p')
    account_id=$(euare-accountlist --access-key-id $access_key --secret-key $secret_key \
                                   --region $REGION | grep "^eucalyptus" | cut -f2)

    cat << EOF > ~/.euca/$REGION.ini
    ; Eucalyptus Region $REGION

    [user $REGION-admin]
    key-id = $access_key
    secret-key = $secret_key
    account-id = $account_id

    EOF

    euca-describe-availability-zones verbose --region $USER_REGION
    ```

4. Create Eucalyptus Administrator AWSCLI Profile

    This allows the Eucalyptus Administrator to run API commands via AWSCLI.

    ```bash
    mkdir -p ~/.aws
    chmod 0700 ~/.aws

    cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = $REGION
    output = text

    [profile $REGION-admin]
    region = $REGION
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #

    [default]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    [$REGION-admin]
    aws_access_key_id = $access_key
    aws_secret_access_key = $secret_key

    EOF

    aws ec2 describe-availability-zones --profile default --region $REGION

    aws ec2 describe-availability-zones --profile $PROFILE --region $REGION
    ```

5. Configure Demo Keypair

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
    ```

6. Import Eucalyptus Administrator Demo Keypair

    ```bash
    euca-import-keypair --public-key-file ~/.ssh/demo_id_rsa.pub \
                        --region $USER_REGION \
                        demo
    ```

7. Create sample-templates Bucket

    This bucket is intended for Sample CloudFormation Templates.

    ```bash
    aws s3api create-bucket --bucket sample-templates --acl public-read
                            --profile $PROFILE --region=$REGION
    ```

8. Download Demo Generic Image (CentOS 6)

    This is the Generic Cloud Image created by CentOS.

    ```bash
    wget http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz \
         -O /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    qemu-img convert -f qcow2 -O raw /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2 \
                                     /var/tmp/CentOS-6-x86_64-GenericCloud.raw
    ```

9. Install Demo Generic Image

    ```bash
    euca-install-image --name centos6 \
                       --description "Centos 6 Generic Cloud Image" \
                       --bucket images \
                       --arch x86_64 \
                       --image /var/tmp/CentOS-6-x86_64-GenericCloud.raw \
                       --virtualization-type hvm \
                       --region $USER_REGION
    ```

10. Download Demo CFN + AWSCLI Image (CentOS 6.6)

    This is a Generic Cloud Image modified to add CFN tools and AWSCLI.

    ```bash
    wget http://images-euca.s3-website-us-east-1.amazonaws.com/CentOS-6-x86_64-CFN-AWSCLI.raw.xz \
         -O /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw.xz
    ```

11. Install Demo CFN + AWSCLI Image

    ```bash
    euca-install-image --name centos6-cfn-init \
                       --description "Centos 6 Cloud Image with CloudFormation and AWSCLI" \
                       --bucket images \
                       --arch x86_64 \
                       --image /var/tmp/CentOS-6-x86_64-CFN-AWSCLI.raw \
                       --virtualization-type hvm \
                       --region $USER_REGION
    ```

12. Modify Instance Types

    Change the m1.small instance type to use 1GB memory and 8GB disk, as the default CentOS
    cloud image requires this additional memory and disk to run.

    ```bash
    euca-modify-instance-type --cpus 1 --memory 1024 --disk 8 \
                              --region $USER_REGION \
                              m1.small
    ```

13. List Demo Resources

    ```bash
    euca-describe-keypairs --region $USER_REGION

    euca-describe-images --region $USER_REGION

    euca-describe-instance-types --region $USER_REGION
    ```

14. Display Euca2ools Configuration

    ```bash
    cat ~/.euca/global.ini

    cat /etc/euca2ools/conf.d/$REGION.ini

    cat ~/.euca/$REGION.ini
    ```

15. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

