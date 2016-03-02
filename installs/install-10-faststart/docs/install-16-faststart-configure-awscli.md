# FastStart Install: Configure AWSCLI Procedure
### This variant uses the Helion Eucalyptus Development PKI Infrastructure

This document describes the manual procedure to configure AWSCLI, after Eucalyptus has been installed
via the FastStart installer. This script assumes the reverse-proxy script has been run, so that
Eucalyptus can be accessed via HTTPS endpoints via the proxy.

Please note that this procedure is not a supported configuration, as the use of Python pip changes
Python modules installed via RPM on which Eucalyptus depends to unknown later versions outside of
the RPM package management system. Use this procedure on any host running Eucalyptus at your own
risk! This procedure can be used to install AWSCLI on a separate management workstation, avoiding
this support problem.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the **REGION**, and **mjc.prc.eucalyptus-systems.com** as the **DOMAIN**.
Note that this domain only resolves inside the HP Goleta network.

This is using the following host in the HP Goleta server room:
- odc-f-32.prc.eucalyptus-systems.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 10.104.10.74/16

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    These instructions were based on a Faststart Install performed within the PRC on host
    odc-f-32.prc.eucalyptus-systems.com, configured as region hp-gol01-f1, using MCrawfords
    DNS server. Adjust the variables in this section to your environment.

    ```bash
    export DOMAIN=mjc.prc.eucalyptus-systems.com
    export REGION=hp-gol01-f1
    ```

### Configure AWSCLI

1. Install Python Pip

    This step assumes the EPEL repo has been configured.

    ```bash
    yum install -y python-pip

    pip install --upgrade pip
    ```

2. Install AWSCLI

    ```bash
    pip install awscli
    ```

3. Fix Eucalyptus Console dependencies broken by pip

    pip overwrites a version of a python module required by eucaconsole so we must revert back to
    the required version.

    This problem is likely to be a moving target, until a recent usable version of AWSCLI is
    packaged as an RPM compatible with CentOS/RHEL and/or EPEL, so it can be installed without
    pip. Whenever pip is used on any Eucalyptus host, there is a potential for pip to break
    dependencies. You can explicitly start eucaconsole on the command line to determine if this
    is happening, and identify the module affected.

    ```bash
    pip uninstall -y python-dateutil
    yum reinstall -y python-dateutil
    ```

4. Configure AWSCLI Command Completion

    ```bash
    cat << EOF >> /etc/profile.d/aws.sh
    complete -C '/usr/bin/aws_completer' aws
    EOF

    source /etc/profile.d/aws.sh
    ```

5. Configure AWSCLI to trust the Helion Eucalyptus Development PKI Infrastructure

    We will use the Helion Eucalyptus Development Root Certification Authority to sign SSL
    certificates. Certificates issued by this CA are not trusted by default.

    We must add this CA cert to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
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

    mv /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
       /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.orig

    ln -s cacert.pem.local /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem
    ```

6. Configure AWSCLI to support local Eucalyptus region

    This creates a modified version of the _endpoints.json file which the botocore Python module
    within AWSCLI uses to configure AWS endpoints, adding the new local Eucalyptus region endpoints.

    We rename the original _endpoints.json file with the .orig extension, so we can diff for 
    changes if we need to update in the future against a new _endpoints.json, then create a
    symlink with the original name pointing to our new SSL version.

    ```bash
    cat << EOF > /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local.ssl
    {
      "_default":[
        {
          "uri":"{scheme}://{service}.{region}.${DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${REGION%-*}-"]
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
          "uri":"{scheme}://compute.{region}.${DOMAIN}",
          "constraints": [
            ["region","startsWith","${REGION%-*}-"]
          ]
        }
      ],
      "elasticloadbalancing": [
       {
        "uri":"{scheme}://loadbalancing.{region}.${DOMAIN}",
        "constraints": [
          ["region","startsWith","${REGION%-*}-"]
        ]
       }
      ],
      "monitoring":[
        {
          "uri":"{scheme}://cloudwatch.{region}.${DOMAIN}",
          "constraints": [
           ["region","startsWith","${REGION%-*}-"]
          ]
        }
      ],
      "swf":[
       {
        "uri":"{scheme}://simpleworkflow.{region}.${DOMAIN}",
        "constraints": [
         ["region","startsWith","${REGION%-*}-"]
        ]
       }
      ],
      "iam":[
        {
          "uri":"https://euare.{region}.${DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${REGION%-*}-"]
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
          "uri":"https://tokens.{region}.${DOMAIN}",
          "constraints":[
            ["region", "startsWith", "${REGION%-*}-"]
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
          "uri":"{scheme}://objectstorage.{region}.${DOMAIN}//",
          "constraints": [
            ["region", "startsWith", "${REGION%-*}-"]
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

    mv _endpoints.json _endpoints.json.orig

    ln -s _endoints.json.local.ssl _endpoints.json
    ```

7. Configure Default AWS credentials

    This configures the Eucalyptus Administrator as the default and an explicit profile.

    ```bash
    access_key=$(sed -n -e 's/AWSAccessKeyId=//p' ~/.creds/${REGION}/eucalyptus/admin/iamrc)
    secret_key=$(sed -n -e 's/AWSSecretKey=//p' ~/.creds/${REGION}/eucalyptus/admin/iamrc)

    mkdir -p ~/.aws

    # cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = ${REGION}
    output = text

    [profile-${REGION}-admin]
    region = ${REGION}
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #
    
    [default]
    aws_access_key_id = ${access_key}
    aws_secret_access_key = ${secret_key}

    [${REGION}-admin]
    aws_access_key_id = ${access_key}
    aws_secret_access_key = ${secret_key}

    EOF

    chmod -R og-rwx ~/.aws
    ```

8. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

9. Confirm AWSCLI

    ```bash
    aws ec2 describe-key-pairs

    aws ec2 describe-key-pairs --profile default

    aws ec2 describe-key-pairs --profile ${REGION}-admin
    ```

