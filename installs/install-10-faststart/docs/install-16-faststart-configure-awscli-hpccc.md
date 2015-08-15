# FastStart Install: Configure AWSCLI Procedure
### This variant uses the HP EBC PKI Infrastructure

This document describes the manual procedure to configure AWSCLI, after Eucalyptus has been installed
via the FastStart installer. This script assumes the reverse-proxy script has been run, so that
Eucalyptus can be accessed via HTTPS endpoints via the proxy.

This variant is meant to be run as root

This procedure is based on the hp-pal20a-1 demo environment running on host dl580gen8a
in the Palo Alto EBC. It uses **hp-pal20a-1** as the AWS_DEFAULT_REGION, and **hpccc.com** as the
AWS_DEFAULT_DOMAIN.

This is using the following host in the HP Palo Alto EBC:
- dl580gen8a.hpccc.com: CLC+UFS+MC+Walrus+CC+SC+NC
  - Internal Public:  172.0.1.8/24
  - Internal Private: 172.0.2.8/24

### Define Parameters

The procedure steps in this document are meant to be static - pasted unchanged into the appropriate
ssh session of each host. To support reuse of this procedure on different environments with
different identifiers, hosts and IP addresses, as well as to clearly indicate the purpose of each
parameter used in various statements, we will define a set of environment variables here, which
will be pasted into each ssh session, and which can then adjust the behavior of statements.

1. Define Environment Variables used in upcoming code blocks

    These instructions were based on a manual installation of CentOS 6.6 minimum.
    Adjust the variables in this section to your environment.

    ```bash
    export AWS_DEFAULT_REGION=hp-pal20a-1
    export AWS_DEFAULT_DOMAIN=hpccc.com

    export EUCA_DNS_INSTANCE_SUBDOMAIN=.cloud
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb

    export EUCA_PUBLIC_IP_RANGE=172.0.1.64-172.0.1.254
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

4. Configure AWSCLI to trust the HP EBC PKI Infrastructure

    We will use the HP EBC Root Certification Authority to sign SSL certificates.
    Certificates issued by this CA are not trusted by default.

    We must add this CA cert to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem

    # Issuer: DC=com, DC=hpccc, CN=hpccc-DC1A-CA
    # Subject: DC=com, DC=hpccc, CN=hpccc-DC1A-CA
    # Label: "hpccc-DC1A-CA"
    # Serial: 637EF9629C9CA48F4C2ED6DA4C031E51
    # MD5 Fingerprint: CE:5B:A4:F9:73:73:6D:84:79:EA:4B:01:AF:65:55:EE
    # SHA1 Fingerprint: 2B:52:D7:06:1E:59:90:A5:BE:9A:CC:89:BA:C0:C0:90:2B:3E:48:46
    # SHA256 Fingerprint: 2F:2A:44:29:A5:28:08:37:F4:BB:1C:D6:22:8A:BF:FF:CE:D2:2C:BC:BD:94:E9:13:D6:27:0B:97:5A:1A:EA:14
    -----BEGIN CERTIFICATE-----
    MIIDpDCCAoygAwIBAgIQY375YpycpI9MLtbaTAMeUTANBgkqhkiG9w0BAQUFADBE
    MRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAU
    BgNVBAMTDWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE0MjExNzI4WhcNMjAwNDEzMjEy
    NzI3WjBEMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBj
    Y2MxFjAUBgNVBAMTDWhwY2NjLURDMUEtQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQCmoHR7XOde9LHGmEa0rNAkAt6jDMpxypW3C1xcKi+T8ZcMUwdv
    K9oQv9ZnRAhyCEqQc/VobiiR3JO9/lz86Y9XsoysbrU2gZTfyYw03DH32Tm3tYaI
    xsK+ThBRkM0HhKZiGAO5d5UFz2f3xWWgaahHEbXoOYbuBYxJ6TWpmhrV/NbVdJXI
    /44mdCI4TAjIlQemFa91ZyKdEuT76vt13leyzld4eyl0LU1go3vaLLNo1G7tY5jW
    2aUw7hgpd5jWFPrCNkdvuk04KHl617H+qGGvWKlapG8f7e6voHjgbA2Zqsoa4lQr
    6Is13kAZIQRCEUrppeYWOkhzks/iwWIyJMQZAgMBAAGjgZEwgY4wEwYJKwYBBAGC
    NxQCBAYeBABDAEEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYD
    VR0OBBYEFO8xVEl5RiVrrtGK9Ou+YdNuDNRtMBIGCSsGAQQBgjcVAQQFAgMDAAMw
    IwYJKwYBBAGCNxUCBBYEFMuCtZAjoURHCHCk5JSf7gpClFeyMA0GCSqGSIb3DQEB
    BQUAA4IBAQAlkTqoUmW6NMzpVQC4aaWVhpwFgU61Vg9d/eDbYZ8OKRxObpjjJv3L
    kHIxVlKnt/XjQ/6KOsneo0cgdxts7vPDxEyMW1/Svronzau3LnMjnnwp2RV0Rn/B
    TQi1NgNLzDATqo1naan6WCiZwL+O2kDJlp5xXfFLx3Gapl3Opa9ShbO1XQmbCdPT
    A7FriDiLLBTWAd6TqhmfH+dcz56TGr36itJAh8i2jb2gGErB0DvBN2S4bCvJ1e54
    gYH1DylEpeALZeYK3M30AoRivO5eAivFRpUi/CBLVaFqmD4E2MI8mdbWtLH1t0Qi
    3hyLaqkOlbnIuxMLe4X041c3cZ+PI7wm
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

