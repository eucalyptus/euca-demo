# FastStart Install: Configure AWSCLI Procedure
### This variant uses the HP EBC PKI Infrastructure

This document describes the manual procedure to configure AWSCLI, after Eucalyptus has been installed
via the FastStart installer. This script assumes the reverse-proxy script has been run, so that
Eucalyptus can be accessed via HTTPS endpoints via the proxy.

Please note that this procedure is not a supported configuration, as the use of Python pip changes
Python modules installed via RPM on which Eucalyptus depends to unknown later versions outside of
the RPM package management system. Use this procedure on any host running Eucalyptus at your own
risk! This procedure can be used to install AWSCLI on a separate management workstation, avoiding
this support problem.

This variant is meant to be run as root

This procedure is based on the hp-pal20a-1 demo environment running on host dl580gen8a
in the Palo Alto EBC. It uses **hp-pal20a-1** as the **REGION**, and **hpccc.com** as the
**DOMAIN**.

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
    export DOMAIN=hpccc.com
    export REGION=hp-pal20a-1
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

5. Configure AWSCLI to trust the HP EBC PKI Infrastructure

    We will use the HP EBC Root Certification Authority to sign SSL certificates.
    Certificates issued by this CA are not trusted by default.

    We must add this CA cert to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
    cp -a /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
          /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

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

