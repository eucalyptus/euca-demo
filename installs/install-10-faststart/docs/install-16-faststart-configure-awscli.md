# FastStart Install: Configure AWSCLI Procedure
### This variant uses the Helion Eucalyptus Development PKI Infrastructure

This document describes the manual procedure to configure AWSCLI, after Eucalyptus has been installed
via the FastStart installer. This script assumes the reverse-proxy script has been run, so that
Eucalyptus can be accessed via HTTPS endpoints via the proxy.

This variant is meant to be run as root

This procedure is based on the hp-gol01-f1 demo/test environment running on host odc-f-32 in the PRC.
It uses **hp-gol01-f1** as the AWS_DEFAULT_REGION, and **mjc.prc.eucalyptus-systems.com** as the
AWS_DEFAULT_DOMAIN. Note that this domain only resolves inside the HP Goleta network.

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
    export AWS_DEFAULT_REGION=hp-gol01-f1
    export AWS_DEFAULT_DOMAIN=mjc.prc.eucalyptus-systems.com

    export EUCA_DNS_INSTANCE_SUBDOMAIN=.cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb

    export EUCA_PUBLIC_IP_RANGE=10.104.45.1-10.104.45.126
    ```

### Configure AWSCLI

1. Use Eucalyptus Administrator credentials

    Eucalyptus Administrator credentials should have been moved from the default location
    where they are downloaded to the hierarchical directory structure used for all demos,
    in the location shown below, as part of the prior faststart manual install procedure.

    ```bash
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Install Python Pip

    This step assumes the EPEL repo has been configured.

    ```bash
    yum install -y python-pip
    ```

3. Install AWSCLI

    ```bash
    pip install awscli
    ```

4. Configure AWSCLI to trust the Helion Eucalyptus Development PKI Infrastructure

    We will use the Helion Eucalyptus Development Root Certification Authority to sign SSL
    certificates. Certificates issued by this CA are not trusted by default.

    We must add this CA cert to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem

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
    ```

5. Configure AWS CLI to support local Eucalyptus region

    This creates a modified version of the _endpoints.json file which the botocore Python module
    within AWSCLI uses to configure AWS endpoints, adding the new local Eucalyptus region endpoints.

    We rename the original _endpoints.json file with the .orig extension, so we can diff for 
    changes if we need to update in the future against a new _endpoints.json, then create a
    symlink with the original name pointing to our new SSL version.

    ```bash
    cat << EOF > /usr/lib/python2.6/site-packages/botocore/data/_endpoints.json.local.ssl
    {
      \"_default\":[
        {
          \"uri\":\"{scheme}://{service}.{region}.$AWS_DEFAULT_DOMAIN\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]
          ]
        },
        {
          \"uri\":\"{scheme}://{service}.{region}.amazonaws.com.cn\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"cn-\"]
          ],
          \"properties\": {
              \"signatureVersion\": \"v4\"
          }
        },
        {
          \"uri\":\"{scheme}://{service}.{region}.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notEquals\", null]
          ]
        }
      ],
      \"ec2\": [
        {
          \"uri\":\"{scheme}://compute.{region}.$AWS_DEFAULT_DOMAIN\",
          \"constraints\": [
            [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]
          ]
        }
      ],
      \"elasticloadbalancing\": [
       {
        \"uri\":\"{scheme}://loadbalancing.{region}.$AWS_DEFAULT_DOMAIN\",
        \"constraints\": [
          [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]
        ]
       }
      ],
      \"monitoring\":[
        {
          \"uri\":\"{scheme}://cloudwatch.{region}.$AWS_DEFAULT_DOMAIN\",
          \"constraints\": [
           [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]
          ]
        }
      ],
      \"swf\":[
       {
        \"uri\":\"{scheme}://simpleworkflow.{region}.$AWS_DEFAULT_DOMAIN\",
        \"constraints\": [
         [\"region\",\"startsWith\",\"${AWS_DEFAULT_REGION%-*}-\"]
        ]
       }
      ],
      \"iam\":[
        {
          \"uri\":\"https://euare.{region}.$AWS_DEFAULT_DOMAIN\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]
          ]
        },
        {
          \"uri\":\"https://{service}.cn-north-1.amazonaws.com.cn\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"cn-\"]
          ]
        },
        {
          \"uri\":\"https://{service}.us-gov.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"us-gov\"]
          ]
        },
        {
          \"uri\":\"https://iam.amazonaws.com\",
          \"properties\": {
            \"credentialScope\": {
                \"region\": \"us-east-1\"
            }
          }
        }
      ],
      \"sdb\":[
        {
          \"uri\":\"https://sdb.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"equals\", \"us-east-1\"]
          ]
        }
      ],
      \"sts\":[
        {
          \"uri\":\"https://tokens.{region}.$AWS_DEFAULT_DOMAIN\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]
          ]
        },
        {
          \"uri\":\"{scheme}://{service}.cn-north-1.amazonaws.com.cn\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"cn-\"]
          ]
        },
        {
          \"uri\":\"https://{service}.{region}.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"us-gov\"]
          ]
        },
        {
          \"uri\":\"https://sts.amazonaws.com\",
          \"properties\": {
            \"credentialScope\": {
                \"region\": \"us-east-1\"
            }
          }
        }
      ],
      \"s3\":[
        {
          \"uri\":\"{scheme}://s3.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"oneOf\", [\"us-east-1\", null]]
          ],
          \"properties\": {
            \"credentialScope\": {
                \"region\": \"us-east-1\"
            }
          }
        },
        {
          \"uri\":\"{scheme}://objectstorage.{region}.$AWS_DEFAULT_DOMAIN//\",
          \"constraints\": [
            [\"region\", \"startsWith\", \"${AWS_DEFAULT_REGION%-*}-\"]
          ],
          \"properties\": {
            \"signatureVersion\": \"s3\"
          }
        },
        {
          \"uri\":\"{scheme}://{service}.{region}.amazonaws.com.cn\",
          \"constraints\": [
            [\"region\", \"startsWith\", \"cn-\"]
          ],
          \"properties\": {
            \"signatureVersion\": \"s3v4\"
          }
        },
        {
          \"uri\":\"{scheme}://{service}-{region}.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"oneOf\", [\"us-east-1\", \"ap-northeast-1\", \"sa-east-1\",
                                 \"ap-southeast-1\", \"ap-southeast-2\", \"us-west-2\",
                                 \"us-west-1\", \"eu-west-1\", \"us-gov-west-1\",
                                 \"fips-us-gov-west-1\"]]
          ]
        },
        {
          \"uri\":\"{scheme}://{service}.{region}.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notEquals\", null]
          ],
          \"properties\": {
            \"signatureVersion\": \"s3v4\"
          }
        }
      ],
      \"rds\":[
        {
          \"uri\":\"https://rds.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"equals\", \"us-east-1\"]
          ]
        }
      ],
      \"route53\":[
        {
          \"uri\":\"https://route53.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notStartsWith\", \"cn-\"]
          ]
        }
      ],
      \"elasticmapreduce\":[
        {
          \"uri\":\"https://elasticmapreduce.cn-north-1.amazonaws.com.cn\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"cn-\"]
          ]
        },
        {
          \"uri\":\"https://elasticmapreduce.eu-central-1.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"equals\", \"eu-central-1\"]
          ]
        },
        {
          \"uri\":\"https://elasticmapreduce.us-east-1.amazonaws.com\",
          \"constraints\":[
            [\"region\", \"equals\", \"us-east-1\"]
          ]
        },
        {
          \"uri\":\"https://{region}.elasticmapreduce.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notEquals\", null]
          ]
        }
      ],
      \"sqs\":[
        {
          \"uri\":\"https://queue.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"equals\", \"us-east-1\"]
          ]
        },
        {
          \"uri\":\"https://{region}.queue.amazonaws.com.cn\",
          \"constraints\":[
            [\"region\", \"startsWith\", \"cn-\"]
          ]
        },
        {
          \"uri\":\"https://{region}.queue.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notEquals\", null]
          ]
        }
      ],
      \"importexport\": [
        {
          \"uri\":\"https://importexport.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notStartsWith\", \"cn-\"]
          ]
        }
      ],
      \"cloudfront\":[
        {
          \"uri\":\"https://cloudfront.amazonaws.com\",
          \"constraints\": [
            [\"region\", \"notStartsWith\", \"cn-\"]
          ],
          \"properties\": {
            \"credentialScope\": {
                \"region\": \"us-east-1\"
            }
          }
        }
      ],
      \"dynamodb\": [
        {
          \"uri\": \"http://localhost:8000\",
          \"constraints\": [
            [\"region\", \"equals\", \"local\"]
          ],
          \"properties\": {
            \"credentialScope\": {
                \"region\": \"us-east-1\",
                \"service\": \"dynamodb\"
            }
          }
        }
      ]
    }
    EOF

    mv _endpoints.json _endpoints.json.orig

    ln -s _endoints.json.local.ssl _endpoints.json
    ```

6. Configure Default AWS credentials

    This configures the Eucalyptus Administrator as the default and an explicit profile.

    ```bash
    mkdir -p ~/.aws

    # cat << EOF > ~/.aws/config
    #
    # AWS Config file
    #

    [default]
    region = $AWS_DEFAULT_REGION
    output = text

    [profile-$AWS_DEFAULT_REGION-admin]
    region = $AWS_DEFAULT_REGION
    output = text

    EOF

    cat << EOF > ~/.aws/credentials
    #
    # AWS Credentials file
    #
    
    [default]
    aws_access_key_id = $AWS_ACCESS_KEY
    aws_secret_access_key = $AWS_SECRET_KEY

    [$AWS_DEFAULT_REGION-admin]
    aws_access_key_id = $AWS_ACCESS_KEY
    aws_secret_access_key = $AWS_SECRET_KEY

    EOF

    chmod -R og-rwx ~/.aws
    ```

7. Test AWSCLI

    ```bash
    aws ec2 describe-key-pairs

    aws ec2 describe-key-pairs --profile=defaults

    aws ec2 describe-key-pairs --profile=$AWS_DEFAULT_REGION-admin
    ```

