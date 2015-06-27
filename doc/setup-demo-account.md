# Demo Account Manual Installation (via Euca2ools)

This is the set of manual steps to setup the demo account.

### Initialize Demo Account Script

A script to automate the steps described in the manual procedure which follows can be found here:
https://github.com/eucalyptus/euca-demo/blob/feature/poc/bin/euca-demo-01-initialize-account.sh

Help is available when running this script, via the -? flag.

```bash
euca-demo-01-initialize-account.sh -?
Usage: euca-demo-01-initialize-account.sh [-I [-s | -f]] [-a account] [-p password] [-c] [-l]
  -I          non-interactive
  -s          slower: increase pauses by 25%
  -f          faster: reduce pauses by 25%
  -a account  account to create for use in demos (default: demo)
  -p password password for demo account administrator (default: demo123)
  -c          Create new key pairs instead of importing existing public keys
  -l          Use local mirror for Demo CentOS image
```

By default, the demo account created is named "demo", but this can be overridden with the -a account flag.
This allows alternate and/or multiple demo accounts to be used.

Credentials are now stored in a directory structure which allows for multiple regions. Your ~/.bash_profile
should set the environment variable AWS_DEFAULT_REGION to reference the local region.

### Initialize Demo Account Manual Procedure

1. Use Eucalyptus Administrator credentials

    ```bash
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Import Eucalyptus Administrator Demo Keypair

    ```bash
    cat << EOF > ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem
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

    chmod 0600 ~/creds/$AWS_DEFAULT_REGION/eucalyptus/admin/admin-demo.pem

    cat << EOF > /tmp/eucalyptus-admin-demo.public.key
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtUgO0Ppuy11UpU2InJyEj/Vvn\
    0puytb04VyjKtLZwhqVcT+PYcJj70FmzQ4iLY2H/2IyhC9FDGP+esezJ57vIMKQz\
    hwrvKoqTIwr1A2z7WBY07c4KtahAt2ywBu7rT+su3XvQofFlAjm+xm+T/drY7qNg\
    RTtDq6S6LCg+wDBLMbudVfJrRvItOLmrImMG6mvRKeZ7uTF5TRF5lYRWPlOkjqOa\
    92kzHFiFilkEaJhiBZZeFXLHQezA/zxK1+TFqFyz4wDhwS2OkJHB6o1vQLZrr+Rs\
    vaYlq+3EkLG/UgME843rOzUqgwSnlCSDS27HnbtAF0iqaU5tmZYpw3ex7yCT
    EOF

    euca-import-keypair -f /tmp/eucalyptus-admin-demo.public.key admin-demo
    ```

3. Create Demo (demo) Account

    ```bash
    euare-accountcreate -a demo
    ```

4. Create Demo (demo) Account Administrator Login Profile

    This allows the Demo Account Administrator to login to the console

    ```bash
    euare-usermodloginprofile –u admin –p demo123 -as-account demo
    ```

5. Download Demo (demo) Account Administrator Credentials

    This allows the Demo Account Administrator to run API commands

    ```bash
    mkdir -p ~/.creds/$AWS_DEFAULT_REGION/demo/admin

    rm -f ~/.creds/$AWS_DEFAULT_REGION/demo/admin.zip

    sudo euca-get-credentials -u admin -a demo ~/.creds/$AWS_DEFAULT_REGION/demo/admin.zip

    unzip -uo ~/creds/demo/admin.zip -d ~/.creds/$AWS_DEFAULT_REGION/demo/admin/

    cat ~/.creds/$AWS_DEFAULT_REGION/demo/admin/eucarc
    ```

6. Download Demo Image (CentOS 6.6)

    ```bash
    wget http://cloud.centos.org/centos/6.6/images/CentOS-6-x86_64-GenericCloud.qcow2.xz \
         -O /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    xz -v -d /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2.xz

    qemu-img convert -f qcow2 -O raw /var/tmp/CentOS-6-x86_64-GenericCloud.qcow2 \
                                     /var/tmp/CentOS-6-x86_64-GenericCloud.raw
    ```

7. Install Demo Image

    ```bash
    euca-install-image -n centos66 -b images -r x86_64 -i /var/tmp/CentOS-6-x86_64-GenericCloud.raw \
                       --virtualization-type hvm
    ```

8. Authorize Demo (demo) Account use of Demo Image

    Lookup the demo account id and centos image id, as these will be different for each environment

    ```bash
    account_id=$(euare-accountlist | grep "^demo" | cut -f2)
    image_id=$(euca-describe-images | grep centos.raw.manifest.xml | cut -f2)

    euca-modify-image-attribute -l -a $account_id $image_id
    ```

9. Modify an Instance Type

    Change the m1.small instance type to use 1GB memory and 10GB disk, as the default CentOS
    cloud image requires this additional memory and disk to run.

    ```bash
    euca-modify-instance-type -c 1 -d 10 -m 1024 m1.small
    ```

10. List Demo Resources

    ```bash
    euca-describe-images

    euca-describe-keypairs

    euare-accountlist

    euca-describe-instance-types
    ```
