# Demo 90: Configure Management Workstation

This document describes the manual procedure to run the Mnagement Workstation Configuration demo
using a combination of Euca2ools and AWSCLI.

### Prerequisites

This procedure should not be run on hosts running Eucalyptus components - the use of Python pip to
install AWSCLI can update python dependencies also used by Eucalyptus which have not been
tested.

You should have a copy of the "euca-demo" GitHub project checked out to the workstation
where you will be running any scripts or using a Browser which will access the Eucalyptus
Console, so that you can run scripts or upload Templates or other files which may be needed.
This project should be checked out to the ~/src/eucalyptus/euca-demo directory.

In examples below, credentials are specified via the --region USER@REGION option with Euca2ools,
or the --profile PROFILE and --region REGION options with AWS CLI. Normally you could shorten the
command lines by use of the AWS_DEFAULT_REGION and AWS_DEFAULT_PROFILE environment variables set
to appropriate values, but there are two conflicts which prevent that alternative for this demo.
We must switch back and forth between AWS and Eucalyptus, and explicit options make clear which
system is the target of each command. Also, there is a conflict between Euca2ools use of
USER@REGION and AWSCLI, which breaks when this variable has the USER@ prefix.

Before running this demo, please run the demo-90-initialize-configure-management-workstation.sh
script, which will confirm that all dependencies exist and perform any demo-specific initialization
required.

After running this demo, please run the demo-90-reset-configure-management-workstation.sh script,
which will reverse all actions performed by this script so that it can be re-run.

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    Adjust the variables in this section to your environment.

    ```bash
    export EUCA_DOMAIN=hpcloudsvc.com
    export EUCA_REGION=hp-aw2-1
    export EUCA_ACCOUNT=demo
    export EUCA_ACCOUNT_NUMBER=111111111111
    export EUCA_USER=admin
    export EUCA_USER_ACCESS_KEY=EEEEEEEEEEEEEEEE
    export EUCA_USER_SECRET_KEY=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

    export EUCA_USER_REGION=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER@$EUCA_REGION
    export EUCA_PROFILE=$EUCA_REGION-$EUCA_ACCOUNT-$EUCA_USER

    export AWS_REGION=us-west-2
    export AWS_ACCOUNT=mjchpe
    export AWS_ACCOUNT_NUMBER=222222222222
    export AWS_USER=mcrawford
    export AWS_USER_ACCESS_KEY=AAAAAAAAAAAAAAAA
    export AWS_USER_SECRET_KEY=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

    export AWS_USER_REGION=aws-$AWS_ACCOUNT-$AWS_USER@$AWS_REGION
    export AWS_PROFILE=$AWS_ACCOUNT-$AWS_USER
    ```

### Run Configure Management Workstation Demo

1. Install Euca2ools

    CentOS/RHEL 6:

    ```bash
    yum install -y \
        http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.3/centos/6/x86_64/euca2ools-release-3.3-1.el6.noarch.rpm

    yum install -y euca2ools
    ```

    CentOS/RHEL 7:

    ```bash
    yum install -y \
        http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
        http://downloads.eucalyptus.com/software/euca2ools/3.3/centos/7/x86_64/euca2ools-release-3.3-1.el7.noarch.rpm

    yum install -y euca2ools
    ```

    Mac OS X:

    ```bash
    curl -O http://downloads.eucalyptus.com/software/euca2ools/3.3/source/euca2ools-3.3.0.tar.xz

    tar xvfz euca2ools-3.3.0.tar.xz
    cd euca2ools-3.3.0

    sudo python setup.py install
    ```

    Confirm Euca2ools Version.

    ```bash
    euca-version
    ```

2. Display Euca2ools Initial Configuration

    Note how the AWS Endpoint configuration is installed as part of Euca2ools.

    ```bash
    less /etc/euca2ools/euca2ools.ini
    less /etc/euca2ools/conf.d/aws.ini
    ```

3. Configure Euca2ools Default Region

    ```bash
    cat << EOF > ~/.euca/global.ini
    ; Eucalyptus Global

    [global]
    default-region = ${EUCA_REGION}
    EOF
    ```

4. Configure Euca2ools Eucalyptus Region (via direct HTTP endpoints)

    By default, Eucalyptus is accessible via direct HTTP endpoints. This is the simplest method.

    ```bash
    cat << EOF > /etc/euca2ools/conf.d/${EUCA_REGION}.ini
    ; Eucalyptus Region ${EUCA_REGION}

    [region ${EUCA_REGION}]
    autoscaling-url = http://autoscaling.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    bootstrap-url = http://bootstrap.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    cloudformation-url = http://cloudformation.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    ec2-url = http://ec2.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    elasticloadbalancing-url = http://elasticloadbalancing.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    iam-url = http://iam.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    monitoring-url = http://monitoring.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    properties-url = http://properties.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    reporting-url = http://reporting.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    s3-url = http://s3.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    sts-url = http://sts.${EUCA_REGION}.${EUCA_DOMAIN}:8773/
    user = ${EUCA_REGION}-${EUCA_ACCOUNT}-admin
    EOF
    ```

5. Configure Euca2ools Eucalyptus Region (via proxied HTTPS endpoints)

    It's possible to configure Eucalyptus with HTTPS endpoints. This method is more complex, but
    more secure.

    The certificate file must be moved from the Eucalyptus Cloud Controller to each Management
    Workstation via independent means not described here.

    ```bash
    cat << EOF > /etc/euca2ools/conf.d/${EUCA_REGION}.ini
    ; Eucalyptus Region ${EUCA_REGION}

    [region ${EUCA_REGION}]
    autoscaling-url = https://autoscaling.${EUCA_REGION}.${EUCA_DOMAIN}/
    bootstrap-url = https://bootstrap.${EUCA_REGION}.${EUCA_DOMAIN}/
    cloudformation-url = https://cloudformation.${EUCA_REGION}.${EUCA_DOMAIN}/
    ec2-url = https://ec2.${EUCA_REGION}.${EUCA_DOMAIN}/
    elasticloadbalancing-url = https://elasticloadbalancing.${EUCA_REGION}.${EUCA_DOMAIN}/
    iam-url = https://iam.${EUCA_REGION}.${EUCA_DOMAIN}/
    monitoring-url = https://monitoring.${EUCA_REGION}.${EUCA_DOMAIN}/
    properties-url = https://properties.${EUCA_REGION}.${EUCA_DOMAIN}/
    reporting-url = https://reporting.${EUCA_REGION}.${EUCA_DOMAIN}/
    s3-url = https://s3.${EUCA_REGION}.${EUCA_DOMAIN}/
    sts-url = https://sts.${EUCA_REGION}.${EUCA_DOMAIN}/
    user = ${EUCA_REGION}-${EUCA_ACCOUNT}-admin

    certificate = /usr/share/euca2ools/certs/cert-${EUCA_REGION}.pem
    verify-ssl = true
    EOF

    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-${EUCA_REGION}.pem
    chmod 644 /usr/share/euca2ools/certs/cert-${EUCA_REGION}.pem
    ```

6. Configure Euca2ools Eucalyptus Demo Account User

    This standard configuration is needed to run Euca2ools by itself.

    ```bash
    mkdir -p ~/.euca
    chmod 0700 ~/.euca

    cat << EOF > ~/.euca/${EUCA_REGION}.ini
    ; Eucalyptus Region ${EUCA_REGION}

    [user ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}]
    key-id = ${EUCA_USER_ACCESS_KEY}
    secret-key = ${EUCA_USER_SECRET_KEY}
    account-id = ${EUCA_ACCOUNT_NUMBER}

    EOF
    ```

    This additional configuration is currently needed to run Euca2ools and AWSCLI in parallel.

    ```bash 
    mkdir -p ~/.creds/${EUCA_REGION}/${EUCA_ACCOUNT}/${EUCA_USER}

    cat << EOF > ~/.creds/${EUCA_REGION}/${EUCA_ACCOUNT}/${EUCA_USER}/iamrc
    AWSAccessKeyId=${EUCA_USER_ACCESS_KEY}
    AWSSecretKey=${EUCA_USER_SECRET_KEY}
    EOF
    ```

7. Configure Euca2ools AWS Account User

    This standard configuration is needed to run Euca2ools by itself.

    ```bash
    cat << EOF > ~/.euca/aws.ini
    ; AWS

    [user aws-${AWS_ACCOUNT}-${AWS_USER}]
    key-id = ${AWS_USER_ACCESS_KEY}
    secret-key = ${AWS_USER_SECRET_KEY}

    EOF
    ```

    This additional configuration is currently needed to run Euca2ools and AWSCLI in parallel.

    ```bash
    mkdir -p ~/.creds/aws/${AWS_ACCOUNT}/${AWS_USER}

    cat << EOF > ~/.creds/aws/${AWS_ACCOUNT}/${AWS_USER}/iamrc
    AWSAccessKeyId=${AWS_USER_ACCESS_KEY}
    AWSSecretKey=${AWS_USER_SECRET_KEY}
    EOF
    ```

8. Display Example Euca2ools Configuration

    This is an example of what the configuration performed in steps 3 - 7 should look like,
    assuming the values specified above were used, and HTTPS endpoints are in effect.

    ~/.euca/global.ini
    ```bash
    ; Eucalyptus Global

    [global]
    default-region = hp-aw2-1
    ```

    /etc/euca2ools/conf.d/hp-aw2-1.ini
    ```bash
    ; Eucalyptus Region hp-aw2-1

    [region hp-aw2-1]
    autoscaling-url = https://autoscaling.hp-aw2-1.hpcloudsvc.com/
    bootstrap-url = https://bootstrap.hp-aw2-1.hpcloudsvc.com/
    cloudformation-url = https://cloudformation.hp-aw2-1.hpcloudsvc.com/
    ec2-url = https://ec2.hp-aw2-1.hpcloudsvc.com/
    elasticloadbalancing-url = https://elasticloadbalancing.hp-aw2-1.hpcloudsvc.com/
    iam-url = https://iam.hp-aw2-1.hpcloudsvc.com/
    monitoring-url = https://monitoring.hp-aw2-1.hpcloudsvc.com/
    properties-url = https://properties.hp-aw2-1.hpcloudsvc.com/
    reporting-url = https://reporting.hp-aw2-1.hpcloudsvc.com/
    s3-url = https://s3.hp-aw2-1.hpcloudsvc.com/
    sts-url = https://sts.hp-aw2-1.hpcloudsvc.com/
    user = hp-aw2-1-demo-admin

    certificate = /usr/share/euca2ools/certs/cert-hp-aw2-1.pem
    verify-ssl = true
    ```

    ~/.euca/hp-aw2-1.ini
    ```bash
    ; Eucalyptus Region hp-aw2-1

    [user hp-aw2-1-demo-admin]
    key-id = EEEEEEEEEEEEEEEEEEEE
    secret-key = eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    account-id = 111111111111
    ```

    ~/.creds/hp-aw2-1/demo/admin/iamrc
    ```bash
    AWSAccessKeyId=EEEEEEEEEEEEEEEEEEEE
    AWSSecretKey=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    ```

    ~/.euca/aws.ini
    ```bash
    ; AWS

    [user aws-mjchpe-mcrawford]
    key-id = AAAAAAAAAAAAAAAAAAAA
    secret-key = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    ```

    ~/.creds/aws/mjchpe/mcrawford/iamrc
    ```bash
    AWSAccessKeyId=AAAAAAAAAAAAAAAAAAAA
    AWSSecretKey=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    ```

9. Install AWSCLI

    Assumes the EPEL yum repository has been configured as shown in a prior step.

    We must install Python's pip utility first, before we can then use that to install AWSCLI.

    Also configure AWSCLI's command-line completion.

    ```bash
    yum install -y python-pip

    pip install --upgrade pip

    pip install awscli

    cat << EOF >> /etc/profile.d/aws.sh
    complete -C '/usr/bin/aws_completer' aws
    EOF

    source /etc/profile.d/aws.sh
    ```

10. Display AWSCLI Initial Configuration

    CentOS/RHEL 6:

    ```bash
    less /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json
    less /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem
    ```

    CentOS/RHEL 7:

    ```bash
    less /usr/lib/python2.7/site-packages/botocore/data/_endpoints.json
    less /usr/lib/python2.7/site-packages/botocore/vendored/requests/cacert.pem
    ```

    Mac OS X:

    ```bash
    less /Library/Python/2.7/site-packages/botocore/data/_endpoints.json
    less /Library/Python/2.7/site-packages/botocore/vendored/requests/cacert.pem
    ```

11. Configure AWSCLI Eucalyptus Region (via direct HTTP endpoints)

    Preserve the original version, so that we can compare with any newer version installed
    during AWSCLI upgrades. Using diff, you can identify changes and port them to your
    modified version.

    Adjust the path as needed for your system.

    ```bash
    cp -a /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json \
          /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.orig

    cat << EOF > /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local
    {
      "_default":[
        {
          "uri":"http://{service}.{region}.${EUCA_DOMAIN}:8773",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
              "signatureVersion": "v4"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "ec2": [
        {
          "uri":"http://compute.{region}.${EUCA_DOMAIN}:8773",
          "constraints": [
            ["region","startsWith","${EUCA_REGION%-*}-"]
          ]
        }
      ],
      "elasticloadbalancing": [
       {
        "uri":"http://loadbalancing.{region}.${EUCA_DOMAIN}:8773",
        "constraints": [
          ["region","startsWith","${EUCA_REGION%-*}-"]
        ]
       }
      ],
      "monitoring":[
        {
          "uri":"http://cloudwatch.{region}.${EUCA_DOMAIN}:8773",
          "constraints": [
           ["region","startsWith","${EUCA_REGION%-*}-"]
          ]
        }
      ],
      "swf":[
       {
        "uri":"http://simpleworkflow.{region}.${EUCA_DOMAIN}:8773",
        "constraints": [
         ["region","startsWith","${EUCA_REGION%-*}-"]
        ]
       }
      ],
      "iam":[
        {
          "uri":"http://euare.{region}.${EUCA_DOMAIN}:8773",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.us-gov.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://iam.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "sdb":[
        {
          "uri":"https://sdb.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "sts":[
        {
          "uri":"http://tokens.{region}.${EUCA_DOMAIN}:8773",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://sts.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "s3":[
        {
          "uri":"{scheme}://s3.amazonaws.com",
          "constraints":[
            ["region", "oneOf", ["us-east-1", null]]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        },
        {
          "uri":"http://objectstorage.{region}.${EUCA_DOMAIN}:8773//",
          "constraints": [
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ],
          "properties": {
            "signatureVersion": "s3"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints": [
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        },
        {
          "uri":"{scheme}://{service}-{region}.amazonaws.com",
          "constraints": [
            ["region", "oneOf", ["us-east-1", "ap-northeast-1", "sa-east-1",
                                 "ap-southeast-1", "ap-southeast-2", "us-west-2",
                                 "us-west-1", "eu-west-1", "us-gov-west-1",
                                 "fips-us-gov-west-1"]]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        }
      ],
      "rds":[
        {
          "uri":"https://rds.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "route53":[
        {
          "uri":"https://route53.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "waf":[
        {
          "uri":"https://waf.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          },
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "elasticmapreduce":[
        {
          "uri":"https://elasticmapreduce.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.eu-central-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "eu-central-1"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.us-east-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.elasticmapreduce.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "sqs":[
        {
          "uri":"https://queue.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "importexport": [
        {
          "uri":"https://importexport.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "cloudfront":[
        {
          "uri":"https://cloudfront.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "dynamodb": [
        {
          "uri": "http://localhost:8000",
          "constraints": [
            ["region", "equals", "local"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1",
                "service": "dynamodb"
            }
          }
        }
      ]
    }
    EOF

    rm -f /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json

    ln -s _endoints.json.local /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json
    ```

12. Configure AWSCLI SSL Certificate Issuing Root Certificate Authority (optional)

    This is an optional step, needed only if you are signing the SSL certificate used by the
    Eucalyptus Region with a Certificate Authority that is not one of the standard Root
    Certificate Authorities trusted by Python. This is commonly needed when an internal
    Enterprise or Development PKI Infrastructure is used.

    This example will show the configuration of the Helion Eucalyptus Development Root
    Certification Authority. Certificates issued by this CA are not trusted by default.

    The comment lines added were constructed by hand by extracting the information from
    the CA Certificate via OpenSSL commands, to match the format of existing certificates
    in this file. You can either replicate these comments with your own certificate, or
    simply leave them off as they are purely for identification purposes.

    Preserve the original version, so that we can compare with any newer version installed
    during AWSCLI upgrades. Using diff, you can identify changes and port them to your
    modified version.

    Adjust the path as needed for your system.

    ```bash
    cp -a /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
          /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.orig

    cp -a /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
          /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    # Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Label: "Helion Eucalyptus Development Root Certification Authority"
    # Serial: 0
    # MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12
    # SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B
    # SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd
    -----BEGIN CERTIFICATE-----
    MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y
    NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk
    BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI
    ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g
    QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV
    BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku
    Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh
    lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd
    Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL
    GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT
    47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn
    23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc
    HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9
    WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb
    qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1
    ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU
    NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT
    E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB
    BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
    OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa
    jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub
    sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d
    vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI
    kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap
    oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX
    wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD
    zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8
    qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M
    Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I
    Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI=
    -----END CERTIFICATE-----
    EOF

    rm -f /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem

    ln -s cacert.pem.local /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem
    ```

13. Configure AWSCLI Eucalyptus Region (via proxied HTTPS endpoints)

    Adjust the path as needed for your system.

    ```bash
    cat << EOF > /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local.ssl
    {
      "_default":[
        {
          "uri":"{scheme}://{service}.{region}.${EUCA_DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
              "signatureVersion": "v4"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "ec2": [
        {
          "uri":"{scheme}://compute.{region}.${EUCA_DOMAIN}",
          "constraints": [
            ["region","startsWith","${EUCA_REGION%-*}-"]
          ]
        }
      ],
      "elasticloadbalancing": [
       {
        "uri":"{scheme}://loadbalancing.{region}.${EUCA_DOMAIN}",
        "constraints": [
          ["region","startsWith","${EUCA_REGION%-*}-"]
        ]
       }
      ],
      "monitoring":[
        {
          "uri":"{scheme}://cloudwatch.{region}.${EUCA_DOMAIN}",
          "constraints": [
           ["region","startsWith","${EUCA_REGION%-*}-"]
          ]
        }
      ],
      "swf":[
       {
        "uri":"{scheme}://simpleworkflow.{region}.${EUCA_DOMAIN}",
        "constraints": [
         ["region","startsWith","${EUCA_REGION%-*}-"]
        ]
       }
      ],
      "iam":[
        {
          "uri":"https://euare.{region}.${EUCA_DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.us-gov.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://iam.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "sdb":[
        {
          "uri":"https://sdb.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "sts":[
        {
          "uri":"https://tokens.{region}.${EUCA_DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://sts.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "s3":[
        {
          "uri":"{scheme}://s3.amazonaws.com",
          "constraints":[
            ["region", "oneOf", ["us-east-1", null]]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        },
        {
          "uri":"{scheme}://objectstorage.{region}.${EUCA_DOMAIN}//",
          "constraints": [
            ["region", "startsWith", "${EUCA_REGION%-*}-"]
          ],
          "properties": {
            "signatureVersion": "s3"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints": [
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        },
        {
          "uri":"{scheme}://{service}-{region}.amazonaws.com",
          "constraints": [
            ["region", "oneOf", ["us-east-1", "ap-northeast-1", "sa-east-1",
                                 "ap-southeast-1", "ap-southeast-2", "us-west-2",
                                 "us-west-1", "eu-west-1", "us-gov-west-1",
                                 "fips-us-gov-west-1"]]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        }
      ],
      "rds":[
        {
          "uri":"https://rds.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "route53":[
        {
          "uri":"https://route53.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "waf":[
        {
          "uri":"https://waf.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          },
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "elasticmapreduce":[
        {
          "uri":"https://elasticmapreduce.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.eu-central-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "eu-central-1"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.us-east-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.elasticmapreduce.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "sqs":[
        {
          "uri":"https://queue.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "importexport": [
        {
          "uri":"https://importexport.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "cloudfront":[
        {
          "uri":"https://cloudfront.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "dynamodb": [
        {
          "uri": "http://localhost:8000",
          "constraints": [
            ["region", "equals", "local"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1",
                "service": "dynamodb"
            }
          }
        }
      ]
    }
    EOF

    rm -f /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json

    ln -s _endoints.json.local.ssl /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json
    ```

14. Configure AWSCLI Eucalyptus Demo Account User

    AWSCLI uses two files, config and credentials, to store user configuration.

    Unlike Euca2ools, there is no way to store configuration for different Regions
    in different files, which can result in very long versions of these files when
    many credentials are saved.

    Here, we will create new versions of these two files with the Eucalyptus credentials.

    ```bash
    mkdir -p ~/.aws

    cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = ${EUCA_REGION}
    output = text

    [profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}]
    region = ${EUCA_REGION}
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #
    
    [default]
    aws_access_key_id = ${EUCA_USER_ACCESS_KEY}
    aws_secret_access_key = ${EUCA_USER_SECRET_KEY}

    [${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}]
    aws_access_key_id = ${EUCA_USER_ACCESS_KEY}
    aws_secret_access_key = ${EUCA_USER_SECRET_KEY}

    EOF

    chmod -R og-rwx ~/.aws
    ```

15. Configure AWSCLI AWS Account User

    Here, we will append the AWS credentials to the two files created in the prior step.

    ```bash
    cat << EOF >> ~/.aws/config
    [profile ${AWS_ACCOUNT}-${AWS_USER}]
    region = ${AWS_REGION}
    output = text

    EOF

    cat << EOF >> ~/.aws/credentials

    [${AWS_ACCOUNT}-${AWS_USER}]
    aws_access_key_id = ${AWS_USER_ACCESS_KEY}
    aws_secret_access_key = ${AWS_USER_SECRET_KEY}
    
    EOF
    ```

16. Display Example AWSCLI Configuration

    This is an example of what the configuration performed in steps 12 - 15 should look like,
    assuming the values specified above were used, and HTTPS endpoints are in effect.

    /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local
    ```bash
    . . . <Existing Certificates not shown> . . .
    -----END CERTIFICATE-----

    # Issuer: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Subject: C=US, ST=California, L=Goleta, O=Hewlett-Packard, OU=Helion Eucalyptus Development, CN=Helion Eucalyptus Development Root Certification Authority
    # Label: "Helion Eucalyptus Development Root Certification Authority"
    # Serial: 0
    # MD5 Fingerprint: 95:b3:42:d3:1d:78:05:3a:17:c3:01:47:24:df:ce:12
    # SHA1 Fingerprint: 75:76:2a:df:a3:97:e8:c8:2f:0a:60:d7:4a:a1:94:ac:8e:a9:e9:3B
    # SHA256 Fingerprint: 3a:8f:d3:c6:7d:f2:f2:54:5c:50:50:5f:d5:5a:a6:12:73:67:96:b3:6c:9a:5b:91:23:11:81:27:67:0c:a5:fd
    -----BEGIN CERTIFICATE-----
    MIIGfDCCBGSgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjAyMzI2MzNaFw0y
    NTA0MTcyMzI2MzNaMIG6MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEPMA0GA1UEBwwGR29sZXRhMRgwFgYDVQQKDA9IZXdsZXR0LVBhY2thcmQxJjAk
    BgNVBAsMHUhlbGlvbiBFdWNhbHlwdHVzIERldmVsb3BtZW50MUMwQQYDVQQDDDpI
    ZWxpb24gRXVjYWx5cHR1cyBEZXZlbG9wbWVudCBSb290IENlcnRpZmljYXRpb24g
    QXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzTy4eoFV
    BNQYawVhvzZ2rawfV6+oOOr6bNfg8K+TV3faLBXicN1q2XIMuGh2DGMNe0kPskku
    Tn1kk1SMatC8FtrwNQZRlZCqYQP2PC3jabOawo4yJU+3AMMvR+j33MSDY4Tm2uuh
    lwXKzxDgMadpRTxDSbMmBQXqHTAPubIOTM4Nu8LEUiNmTv4tvUJjRxYqTYfbsSUd
    Ox8cvQKr4k/R/kuxD6iwTwdyZ227oXqSv/cQC+7lcyCuq+7+ergbmz52uzAD0klL
    GLxeFpNLk+WcL6LV/KlTBPuMmIlT/ZsJ9plHsNB6lVWXsacVSG2jHQhylLu32rvT
    47D1AXCvIDQeMxzLvJeLQoUM7XXV/oAMZww6b4aXTsFl07avEE7u7I6vNSqiRWtn
    23DuiD6QExSWiwDUEzj0DxCsU366jiHw7j5fgjg3k7TNIKn3oTYnx8WFJMH7/DPc
    HwZ7zOYj3hzCASy2ROqV4/K8mniicQHWpfrvgX980EWsrgNlgDbPCBXBqKwCp5I9
    WDCjx7IDtY3peDfa8+rKzWCE+cwjH7v+1avm16Y/rq4cuP/uUazbT3HtEPbAZHvb
    qAwace0g57w1Yckk3WtzbaQqI+rkV503HT7DCNDZ+MryuWxSU8+xSHUdKsEmPpr1
    ejMcYAEjdau1x5+jMgpBMN2opZZfmWoNWRsCAwEAAaOBijCBhzAdBgNVHQ4EFgQU
    NkKFNpC6OqbkLgVZoFATE+TS21gwHwYDVR0jBBgwFoAUNkKFNpC6OqbkLgVZoFAT
    E+TS21gwDwYDVR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEB
    BAQDAgEGMAkGA1UdEQQCMAAwCQYDVR0SBAIwADANBgkqhkiG9w0BAQsFAAOCAgEA
    OBZU/IohiseYPFFhhvUfKyCvoAlb2tx9jL0UxQifgd02G3wyWOa5q0sRVGynd/qa
    jjTkw0DN/9gt8dQIUU1XdfJ+KT8sfTd6z4/w/yqU6uJ3EvCTV3+G67W9UOtyJqub
    sdCYP24v2uZdF4WLU6Gacq2C/oL0yAngXcEdEC8uwo62WKJftN+AiV7YByWyrX4d
    vaNjxoa/ZF2sXPeY76ZliprgG4xEe9v0SdE7qU8wVlDVc8DtdUkAyosc38HynizI
    kCxPZKgyn+doBXNwMPeq/yyeWjt7av9MozBSgdUhnpHWbmPTouBc+8p58wiolBap
    oMHur98tQYDpwTYwPXL9gQ6V22GaKjJmMGZ8S9pNGhUeHzLVyaFiLBeKh1am7HiX
    wzoERgKZX8Pcs/Rk6/Z0IK1AG7aOHTrE9jrmFNHWDqme0Y7sIRukkd88JgthRRZD
    zq/GCP6kaAclH4Cm6bgeXw7TvEv2B7ocoBoWhV3cqnNJbujB66H59ItCfG9xG3j8
    qkU3RQU7V9UDb/2+anPE+w/SukYILKHT9GCqsyC3Afc855ugPhXC7EMMyd+Xp88M
    Hx6H/MmbW0Pe72Fs27ipgJrEzRXd5FHIzpj2qug9SHEw3d7H7LrqDYs6eA07oL8I
    Zg+lWqylmGZ/aaG3qEnB1I+q6dUCrKDmxtOk6HAJ6PI=
    -----END CERTIFICATE-----
    ```

    /usr/lib/python2.6/site-packages/botocore/data_endpoints.json.local.ssl
    ```bash
    {
      "_default":[
        {
          "uri":"{scheme}://{service}.{region}.hpcloudsvc.com",
          "constraints":[
            ["region", "startsWith", "hp-aw2-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
              "signatureVersion": "v4"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "ec2": [
        {
          "uri":"{scheme}://compute.{region}.hpcloudsvc.com",
          "constraints": [
            ["region","startsWith","hp-aw2-"]
          ]
        }
      ],
      "elasticloadbalancing": [
       {
        "uri":"{scheme}://loadbalancing.{region}.hpcloudsvc.com",
        "constraints": [
          ["region","startsWith","hp-aw2-"]
        ]
       }
      ],
      "monitoring":[
        {
          "uri":"{scheme}://cloudwatch.{region}.hpcloudsvc.com",
          "constraints": [
           ["region","startsWith","hp-aw2-"]
          ]
        }
      ],
      "swf":[
       {
        "uri":"{scheme}://simpleworkflow.{region}.hpcloudsvc.com",
        "constraints": [
         ["region","startsWith","hp-aw2-"]
        ]
       }
      ],
      "iam":[
        {
          "uri":"https://euare.{region}.hpcloudsvc.com",
          "constraints":[
            ["region", "startsWith", "hp-aw2-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.us-gov.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://iam.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "sdb":[
        {
          "uri":"https://sdb.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "sts":[
        {
          "uri":"https://tokens.{region}.hpcloudsvc.com",
          "constraints":[
            ["region", "startsWith", "hp-aw2-"]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{service}.{region}.amazonaws.com",
          "constraints":[
            ["region", "startsWith", "us-gov"]
          ]
        },
        {
          "uri":"https://sts.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "s3":[
        {
          "uri":"{scheme}://s3.amazonaws.com",
          "constraints":[
            ["region", "oneOf", ["us-east-1", null]]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        },
        {
          "uri":"{scheme}://objectstorage.{region}.hpcloudsvc.com//",
          "constraints": [
            ["region", "startsWith", "hp-aw2-"]
          ],
          "properties": {
            "signatureVersion": "s3"
          }
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com.cn",
          "constraints": [
            ["region", "startsWith", "cn-"]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        },
        {
          "uri":"{scheme}://{service}-{region}.amazonaws.com",
          "constraints": [
            ["region", "oneOf", ["us-east-1", "ap-northeast-1", "sa-east-1",
                                 "ap-southeast-1", "ap-southeast-2", "us-west-2",
                                 "us-west-1", "eu-west-1", "us-gov-west-1",
                                 "fips-us-gov-west-1"]]
          ]
        },
        {
          "uri":"{scheme}://{service}.{region}.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ],
          "properties": {
            "signatureVersion": "s3v4"
          }
        }
      ],
      "rds":[
        {
          "uri":"https://rds.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        }
      ],
      "route53":[
        {
          "uri":"https://route53.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "waf":[
        {
          "uri":"https://waf.amazonaws.com",
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          },
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "elasticmapreduce":[
        {
          "uri":"https://elasticmapreduce.{region}.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.eu-central-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "eu-central-1"]
          ]
        },
        {
          "uri":"https://elasticmapreduce.us-east-1.amazonaws.com",
          "constraints":[
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.elasticmapreduce.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "sqs":[
        {
          "uri":"https://queue.amazonaws.com",
          "constraints": [
            ["region", "equals", "us-east-1"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com.cn",
          "constraints":[
            ["region", "startsWith", "cn-"]
          ]
        },
        {
          "uri":"https://{region}.queue.amazonaws.com",
          "constraints": [
            ["region", "notEquals", null]
          ]
        }
      ],
      "importexport": [
        {
          "uri":"https://importexport.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ]
        }
      ],
      "cloudfront":[
        {
          "uri":"https://cloudfront.amazonaws.com",
          "constraints": [
            ["region", "notStartsWith", "cn-"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1"
            }
          }
        }
      ],
      "dynamodb": [
        {
          "uri": "http://localhost:8000",
          "constraints": [
            ["region", "equals", "local"]
          ],
          "properties": {
            "credentialScope": {
                "region": "us-east-1",
                "service": "dynamodb"
            }
          }
        }
      ]
    }
    ```

    ~/.aws/config
    ```bash
    #
    # AWS Config file
    #

    [default]
    region = hp-aw2-1
    output = text

    [profile hp-aw2-1-demo-admin]
    region = hp-aw2-1
    output = text

    [profile mjchpe-mcrawford]
    region = us-west-2
    output = text

    ```

    ~/.aws/credentials
    ```bash
    #
    # AWS Credentials file
    #

    [default]
    aws_access_key_id = EEEEEEEEEEEEEEEE
    aws_secret_access_key = eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

    [hp-aw2-1-demo-admin]
    aws_access_key_id = EEEEEEEEEEEEEEEE
    aws_secret_access_key = eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

    [mjchpe-mcrawford]
    aws_access_key_id = AAAAAAAAAAAAAAAA
    aws_secret_access_key = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    ```

17. List Eucalyptus Demo Account Resources via Euca2ools

    Via default (global default-region reference):

    ```bash
    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-instances
    ```

    Via environment variable (euca2ools-only method):

    This breaks AWSCLI, which can't be used in parallel, as AWSCLI does not work with the
    "USER@" prefix in the AWS_DEFAULT_REGION environment variable.

    ```bash
    export AWS_DEFAULT_REGION=${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}

    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-instances
    ```

    Via environment variables (parallel method):

    This allows parallel use of Euca2ools and AWSCLI, by not including "USER@" prefix.
    Instead, since Euca2ools does not currently have a separate parameter or environment
    variable to specify the USER, we must fall back to it's somewhat obsolete support for
    a separate credentials file containing the access key id and secret key, via the
    AWS_CREDENTIAL_FILE environment variable, which is no longer used by AWSCLI.

    ```bash
    export AWS_DEFAULT_REGION=${EUCA_REGION}
    export AWS_CREDENTIAL_FILE=~/.creds/${EUCA_REGION}/${EUCA_ACCOUNT}/${EUCA_USER}/iamrc

    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-instances
    ```

    Via explicit --region parameter:

    This parameter can always be used to override the default or any environment variables.
    Explicit specification of USER and REGION or PROFILE is recommended in scripts for clarity,
    or when multiple Eucalyptus and/or AWS Accounts are being referenced in parallel within
    the same script or program.

    ```bash
    euca-describe-regions --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}

    euca-describe-availability-zones --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}

    euca-describe-keypairs --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}

    euca-describe-instances --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    ```

18. List AWS Account Resources via Euca2ools

    Via environment variable (euca2ools-only method):

    ```bash
    export AWS_DEFAULT_REGION=aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}

    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-instances
    ```

    Via environment variables (parallel method):

    ```bash
    export AWS_DEFAULT_REGION=${AWS_REGION}
    export AWS_CREDENTIAL_FILE=~/.creds/aws/${AWS_ACCOUNT}/${AWS_USER}/iamrc

    euca-describe-regions

    euca-describe-availability-zones

    euca-describe-keypairs

    euca-describe-instances
    ```

    Via explicit --region parameter:

    ```bash
    euca-describe-regions --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}

    euca-describe-availability-zones --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}

    euca-describe-keypairs --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}

    euca-describe-instances --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    ```

19. List Eucalyptus Demo Account Resources via AWSCLI

    Via default (default profile):

    ```bash
    aws ec2 describe-regions

    aws ec2 describe-availability-zones

    aws ec2 describe-key-pairs

    aws ec2 describe-instances
    ```

    Via environment variables:

    AWSCLI profiles can reference a default region, which is used if the AWS_DEFAULT_REGION
    environment variable is not set and the --region parameter is not specified.

    ```bash
    export AWS_DEFAULT_PROFILE=${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}
    export AWS_DEFAULT_REGION=${EUCA_REGION}

    aws ec2 describe-regions

    aws ec2 describe-availability-zones

    aws ec2 describe-key-pairs

    aws ec2 describe-instances
    ```

    Via explicit --profile and --region parameters:

    These parameters can always be used to override the default or any environment variables.
    Explicit specification of both PROFILE and REGION is recommended in scripts for clarity,
    or when multiple Eucalyptus and/or AWS Accounts are being referenced in parallel within
    the same script or program.

    ```bash
    aws ec2 describe-regions --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    aws ec2 describe-availability-zones --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    aws ec2 describe-key-pairs --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    aws ec2 describe-instances --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}
    ```

20. List AWS Account Resources via AWSCLI

    Via environment variables:

    ```bash
    export AWS_DEFAULT_PROFILE=${AWS_ACCOUNT}-${AWS_USER}
    export AWS_DEFAULT_REGION=${AWS_REGION}

    aws ec2 describe-regions

    aws ec2 describe-availability-zones

    aws ec2 describe-key-pairs

    aws ec2 describe-instances
    ```

    Via explicit --profile and --region parameters:

    ```bash
    aws ec2 describe-regions --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    aws ec2 describe-availability-zones --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    aws ec2 describe-key-pairs --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    aws ec2 describe-instances --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}
    ```

21. List Eucalytptus Account Resources via both Euca2ools and AWSCLI

    Via environment variables (parallel method):

    ```bash
    export AWS_DEFAULT_PROFILE=${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}
    export AWS_DEFAULT_REGION=${EUCA_REGION}
    export AWS_CREDENTIAL_FILE=~/.creds/${EUCA_REGION}/${EUCA_ACCOUNT}/${EUCA_USER}/iamrc

    euca-describe-regions
    aws ec2 describe-regions

    euca-describe-availability-zones
    aws ec2 describe-availability-zones

    euca-describe-keypairs
    aws ec2 describe-key-pairs

    euca-describe-instances
    aws ec2 describe-instances
    ```

    Via explicit --profile and/or --region parameters:

    ```bash
    euca-describe-regions --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    aws ec2 describe-regions --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    euca-describe-availability-zones --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    aws ec2 describe-availability-zones --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    euca-describe-keypairs --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    aws ec2 describe-key-pairs --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    euca-describe-instances --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    aws ec2 describe-instances --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}
    ```

22. List AWS Account Resources via both Euca2ools and AWSCLI

    Via environment variables (parallel method):

    ```bash
    export AWS_DEFAULT_PROFILE=${AWS_ACCOUNT}-${AWS_USER}
    export AWS_DEFAULT_REGION=${AWS_REGION}
    export AWS_CREDENTIAL_FILE=~/.creds/aws/${AWS_ACCOUNT}/${AWS_USER}/iamrc

    euca-describe-regions
    aws ec2 describe-regions

    euca-describe-availability-zones
    aws ec2 describe-availability-zones

    euca-describe-keypairs
    aws ec2 describe-key-pairs

    euca-describe-instances
    aws ec2 describe-instances
    ```
    
    Via explicit --profile and/or --region parameters:

    ```bash
    euca-describe-regions --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    aws ec2 describe-regions --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    euca-describe-availability-zones --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    aws ec2 describe-availability-zones --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    euca-describe-keypairs --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    aws ec2 describe-key-pairs --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}

    euca-describe-instances --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    aws ec2 describe-instances --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}
    ```

23. List both Eucalytptus and AWS Account Resources via both Euca2ools and AWSCLI

    Whenever multiple Eucalyptus and/or AWS Accounts are accessed in parallel, only explicit parameters
    should be used.

    ```bash
    unset AWS_DEFAULT_PROFILE
    unset AWS_DEFAULT_REGION
    unset AWS_CREDENTIAL_FILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_KEY

    euca-describe-instances --region ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER}@${EUCA_REGION}
    aws ec2 describe-instances --profile ${EUCA_REGION}-${EUCA_ACCOUNT}-${EUCA_USER} --region ${EUCA_REGION}

    euca-describe-instances --region aws-${AWS_ACCOUNT}-${AWS_USER}@${AWS_REGION}
    aws ec2 describe-instances --profile ${AWS_ACCOUNT}-${AWS_USER} --region ${AWS_REGION}
    ```

