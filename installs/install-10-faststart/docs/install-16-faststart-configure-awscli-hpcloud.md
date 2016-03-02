# FastStart Install: Configure AWSCLI Procedure
### This variant uses the HP Cloud Multi-level PKI Infrastructure

This document describes the manual procedure to configure AWSCLI, after Eucalyptus has been installed
via the FastStart installer. This script assumes the reverse-proxy script has been run, so that
Eucalyptus can be accessed via HTTPS endpoints via the proxy.

Please note that this procedure is not a supported configuration, as the use of Python pip changes
Python modules installed via RPM on which Eucalyptus depends to unknown later versions outside of
the RPM package management system. Use this procedure on any host running Eucalyptus at your own
risk! This procedure can be used to install AWSCLI on a separate management workstation, avoiding
this support problem.

This variant is meant to be run as root

This procedure is based on the hp-aw2-1 demo environment running on host ops-aw2az3-eucaclc0001
in Las Vegas. It uses **hp-aw2-1** as the **REGION**, and **hpcloudsvc.com** as the **DOMAIN**.

This is using the following host in the HP Las Vegas AW2 Data Center:
- ops-aw2az3-eucaclc0001.uswest.hpcloud.net: CLC+UFS+MC+Walrus+CC+SC+NC
  - Public: 15.185.206.8/24

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
    export DOMAIN=hpcloudsvc.com
    export REGION=hp-aw2-1
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

5. Configure AWSCLI to trust the HP Cloud Multi-level PKI Infrastructure

    We will use the HP Cloud Root Certification Authority, along with 2 more intermediate
    Certification Authorities to sign SSL certificates. This is the first of three
    certificates.

    We must add these CA certs to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.

    This format was constructed by hand to match the existing certificates.

    ```bash
    cp -a /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
          /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local

    # Issuer: CN=cloudca.hpcloud.ms
    # Subject: CN=cloudca.hpcloud.ms
    # Label: "cloudca.hpcloud.ms"
    # Serial: 6F58C6D22397309F4CDD121BB52ADBE6
    # MD5 Fingerprint: 8F:41:5C:6C:29:D9:EA:DD:FE:A4:4C:8D:90:17:73:C1
    # SHA1 Fingerprint: 67:0E:8C:B9:44:BD:D6:AB:E4:1A:55:EF:81:8F:6F:C6:19:70:6F:EA
    # SHA256 Fingerprint: 7E:D5:FA:A6:67:97:D4:5B:57:6C:1C:CA:FC:26:29:C9:A6:4C:53:CD:4E:83:13:01:C9:58:C2:45:79:0B:53:96
    -----BEGIN CERTIFICATE-----
    MIIDFTCCAf2gAwIBAgIQb1jG0iOXMJ9M3RIbtSrb5jANBgkqhkiG9w0BAQsFADAd
    MRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjE2MTI1NzA4WhcN
    MzIwMjE2MTMwNzA4WjAdMRswGQYDVQQDExJjbG91ZGNhLmhwY2xvdWQubXMwggEi
    MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCZSFy2YTOnujqh0Wemevdrk9kH
    6sQdidVntwkcvMEe+kzLEGiZrbY7pmoqreFFlDWhYiBPgAtrSjKl89NTd/9cGm3/
    42n4WcoUE65dH8rSn7mAzLZ2WKkICCEeKor7njiSXIo00z4vavujBXWkDImhzRwB
    sU6Xx7uhgMpQt8tTKG3h5NEEknrFjA+Xg7WkQJ5eees8LtO4+S1ESNr9Txi5ZnJ0
    b4eyOnPGxdw1t/AlAtN1BpBW6W37stWd0LiHP+CRlwkA2GETSoQH1Iz9L3hy/qr+
    Na5NNgDOd6ev0DH1cL93a4NUe1xTcC06r125KMjBQVdC516QG81cHtr4L/uFAgMB
    AAGjUTBPMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQJ
    BIieQP10WQIwDbaKmhvnUHmetzAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0B
    AQsFAAOCAQEAMyT7bk+MGr+g0E028d14TauuAqdGBbZ6rX9+8wtOgIY1k4ApP4Xi
    cfgcUl+7uZcI1RKweD04u1FZXOUjf8apGzLl9XlC65z1YrAJwTNN/AmcyYXI3iDO
    u0KezyVA5TSh03jJgHhGlPH6HvG44D6xP9KVs4n1X+QQmW/xELsluxb+//u2+oP1
    XSsj13WU1/5eZec3pedt0IJLVrOzwEV219Xvp4DIPF3chRKaT/CM2yLF7FJ7yICf
    vvVIg1ZJ2VcBCP6sxkVb8BfbIyclB8SG8FKbNl5xm2TxVjriKd3V/xFkaqh1y3Mj
    sEtTkVwohlqtn77wSYTvYAZB+UzqypbX9Q==
    -----END CERTIFICATE-----
    EOF

    mv /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem \
       /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.orig

    ln -s cacert.pem.local /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem
    ```

6. Configure AWSCLI to trust the HP Cloud Multi-level PKI Infrastructure
 
    We will use the HP Cloud Root Certification Authority, along with 2 more intermediate
    Certification Authorities to sign SSL certificates. This is the second of three
    certificates.
 
    We must add these CA certs to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.
 
    This format was constructed by hand to match the existing certificates.
 
    ```bash
    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local
 
    # Issuer: CN=cloudca.hpcloud.ms
    # Subject: DC=ms, DC=hpcloud, CN=cloudpca
    # Label: "cloudpca"
    # Serial: 13903ED9000000000007
    # MD5 Fingerprint: DD:45:88:0B:59:38:B9:12:4B:66:CA:F3:76:58:F6:5A
    # SHA1 Fingerprint: 6B:27:E1:D6:38:E6:15:BB:27:E3:27:61:31:69:31:BA:C5:93:44:D3
    # SHA256 Fingerprint: E4:1F:88:0A:FF:CD:31:98:D9:1C:36:5F:56:57:5C:F8:CD:DE:FB:B1:AD:34:3F:94:0D:B2:A5:08:F8:91:F4:32
    -----BEGIN CERTIFICATE-----
    MIIEIzCCAwugAwIBAgIKE5A+2QAAAAAABzANBgkqhkiG9w0BAQsFADAdMRswGQYD
    VQQDExJjbG91ZGNhLmhwY2xvdWQubXMwHhcNMTIwMjI0MTgwMjI3WhcNMjIwMjI0
    MTgxMjI3WjBAMRIwEAYKCZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdo
    cGNsb3VkMREwDwYDVQQDEwhjbG91ZHBjYTCCASIwDQYJKoZIhvcNAQEBBQADggEP
    ADCCAQoCggEBAK3KkTBAfZggkD3/MQd16wZqC/Kp16J1EyWxO/7r0jWQkXEG56BY
    51bfPjfrQuOxc8eayNHAUBDK4fULbW45LxgVWVfXvyRwSTm0lJ3F37wVBt4/U135
    w0xCX4HvtZfrF8lKX0j7VzNTmyX2OmzkqMQ4MjQB1KkJ9Z9DpRHcICnxkbE1bY8Z
    kaIjas0aERhS7FPLL7PKLb6iPmXkRq+R6axyMMDJ64VopaRg6WeUf793p+8r5G/a
    3OlBk98mZHYILIqQpwol5BaZexzCGDatlxHjkayeInS4OYiDCYaTbeGWls0SWOy3
    LtEQ2Tq2XkQG/w/XRzlFjrp9V++req1+iScCAwEAAaOCAUAwggE8MBAGCSsGAQQB
    gjcVAQQDAgEAMB0GA1UdDgQWBBQWYUgFETm07vF4cSJnKOmer7DPRTAZBgkrBgEE
    AYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB
    /zAfBgNVHSMEGDAWgBQJBIieQP10WQIwDbaKmhvnUHmetzBRBgNVHR8ESjBIMEag
    RKBChkBodHRwOi8vc2UtYXcyb3BzLWNybDAxLnVzd2VzdC5ocGNsb3VkLm5ldC9j
    bG91ZGNhLmhwY2xvdWQubXMuY3JsMFwGCCsGAQUFBwEBBFAwTjBMBggrBgEFBQcw
    AoZAaHR0cDovL3NlLWF3Mm9wcy1jcmwwMS51c3dlc3QuaHBjbG91ZC5uZXQvY2xv
    dWRjYS5ocGNsb3VkLm1zLmNydDANBgkqhkiG9w0BAQsFAAOCAQEAaIK2+3OiCEtt
    Jg7bxfyHoqMWW4Uwl1+F4jMfcuq50wsWWJNBuNb9XKrO+ov07XmfAFfb197C0Xcp
    Z+27VMmNiZNURu3kMjzoYn2BiskicS0ntiPVpb46m9By2OCd8GFlPvRhcgwsnQRU
    gn5Tc76Nn8zviPYxj7LY95ccVWZUdwguupS/dh6NqkWqHikt5faAe7QsykB9sLpp
    N7qVuwnWb3Dwg0vtQj9nK8eYo9QWbV/XBMzf51t2XyzAFAmR7VXf5pwPtI46b+Qf
    E7EKakEXn5DdfCDrF3Fw2OKHNHp6GOVBEHxawpcLLLGXCmZHUCcjr0vLynF8uSTF
    HkIF3OYSeA==
    -----END CERTIFICATE-----
    EOF
    ```

7. Configure AWSCLI to trust the HP Cloud Multi-level PKI Infrastructure
 
    We will use the HP Cloud Root Certification Authority, along with 2 more intermediate
    Certification Authorities to sign SSL certificates. This is the third of three
    certificates.
 
    We must add these CA certs to the trusted root certificate authorities used by botocore on all
    clients where AWSCLI is run.
 
    This format was constructed by hand to match the existing certificates.
 
    ```bash
    cat << EOF >> /usr/lib/python2.6/site-packages/botocore/vendored/requests/cacert.pem.local
 
    # Issuer: DC=ms, DC=hpcloud, CN=cloudpca
    # Subject: DC=ms, DC=hpcloud, CN=aw2cloudica03
    # Label: "aw2cloudica03"
    # Serial: 1A391A3300000000000B
    # MD5 Fingerprint: 95:A3:20:FD:C8:5C:D9:3A:E6:DD:6A:91:40:E2:3A:78
    # SHA1 Fingerprint: B4:A0:1C:96:5F:75:A8:23:80:96:B2:A2:4F:32:20:22:5B:4A:62:0F
    # SHA256 Fingerprint: 2C:B1:57:96:4D:38:BA:60:0C:F7:E5:7D:42:42:11:90:C7:97:94:BB:D3:9C:DA:FA:9E:88:71:8A:7A:0E:8C:6F
    -----BEGIN CERTIFICATE-----
    MIIEZDCCA0ygAwIBAgIKGjkaMwAAAAAACzANBgkqhkiG9w0BAQsFADBAMRIwEAYK
    CZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdocGNsb3VkMREwDwYDVQQD
    EwhjbG91ZHBjYTAeFw0xMjAyMjkwNDU1MjFaFw0xNzAyMjgwNTA1MjFaMEUxEjAQ
    BgoJkiaJk/IsZAEZFgJtczEXMBUGCgmSJomT8ixkARkWB2hwY2xvdWQxFjAUBgNV
    BAMTDWF3MmNsb3VkaWNhMDMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
    AQDYridWlpBFg3BJRGP+pbkflnlsvAhzpf+kIQ3NBWN+8PD0GB5LCMqe8VS0TvXk
    1PWkJ0zop7d5gbxOb1QvTqvNtZZatEOg94lbox3YaN26TZnTIUBvx9ZQ/vwNvww1
    P2kiS1mvd5lPBOFZDeUAXSJnhIC7NmCsHTaxAVPdvmh8gMlwRLH9H4S1S5a1f9iL
    g3gGEbcntC1oXg2D5/QL8fdP66oFa+72wsGoz8k46FBviDVUB8SQ7NtMtHZZ6dN1
    3U6Anc4nfRIJA8zqT9oJCUQpuG668sRw7ztZECcHTRsqWE9p7nImzgib39dYdD3i
    Y3PngQzw4tSY/azFDK36IF0bAgMBAAGjggFZMIIBVTAQBgkrBgEEAYI3FQEEAwIB
    ADAdBgNVHQ4EFgQUIsX2rnOI2dW38KM/QO6zvRtm1WgwGQYJKwYBBAGCNxQCBAwe
    CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
    BBgwFoAUFmFIBRE5tO7xeHEiZyjpnq+wz0UwTgYDVR0fBEcwRTBDoEGgP4Y9aHR0
    cDovL2F3MmNsb3VkY2EwMi51c3dlc3QuaHBjbG91ZC5tcy9DZXJ0RW5yb2xsL2Ns
    b3VkcGNhLmNybDB4BggrBgEFBQcBAQRsMGowaAYIKwYBBQUHMAKGXGh0dHA6Ly9h
    dzJjbG91ZGNhMDIudXN3ZXN0LmhwY2xvdWQubXMvQ2VydEVucm9sbC9BVzJDTE9V
    RENBMDIudXN3ZXN0LmhwY2xvdWQubXNfY2xvdWRwY2EuY3J0MA0GCSqGSIb3DQEB
    CwUAA4IBAQAF/iK35c0jssJBYz/NBvokg+Xd8raomRtObiuoN/myft5BRezqpQej
    X9nipSsJP4rWl7jP7ZYDIYy2lAQVWNeXbeWGealbfRnCwt/h98pRfClXu/H2mIqP
    t4iLn+8a6SyPOLnXZUuzIow7bLC2abL8nWPcbjp5sVBZHZpXPkST6Grdc9BLmPsL
    zu5Afmws4tFt1rn4+uTh1OkuHk4IOBWQ4PRhJUSwWOafnvfZogt0peBkih6r6QeY
    dZVQE96ZvvmDrWLUTluoZb+muqt40pZb4E1m8d9iiofkYhJ1EgchifFeZrLnQY36
    GThJnh8rguyv071bpFUxGDpmwKGviegK
    -----END CERTIFICATE-----
    EOF
    ```

8. Configure AWSCLI to support local Eucalyptus region

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

9. Configure Default AWS credentials

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

10. Display AWSCLI Configuration

    ```bash
    cat ~/.aws/config

    cat ~/.aws/credentials
    ```

11. Confirm AWSCLI

    ```bash
    aws ec2 describe-key-pairs

    aws ec2 describe-key-pairs --profile default

    aws ec2 describe-key-pairs --profile ${REGION}-admin
    ```

