# Setup AWS CLI to access Eucalyptus Regions

### Overview
Some quick and dirty instructions to setup AWS CLI (actually botocore) so that 
Eucalyptus regions are supported.  This supports all the regions created by MCrawford
using the naming convention "hp-gol01-tn", where "t"=type (f=faststart, c=course, d=demo)
and "n" is the instance within the type. All such regions are subdomains of the custom
DNS parent domain created by MCrawford for testing: mjc/prc/eucalyptus-systems.com. It
is useful to stick with predictable conventions like these to simplify the modifications
which must be made to the botocore _endpoints.json file.

### Install AWS CLI (Linux)

```bash
yum install python-pip

pip install awscli
```

### Modify BotoCore to Support Eucalyptus Regions (Linux)

```bash
cd /usr/lib/python2.7/site-packages/botocore/data/aws/

cp -a _endpoints.json _endpoints.json.orig

cat << EOF > _endpoints.json
{
  "_default":[
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
      "uri":"http://compute.{region}.mjc.prc.eucalyptus-systems.com:8773/",
      "constraints": [
        ["region","startsWith","hp-gol01-"]
      ]
    }
  ],
  "elasticloadbalancing": [
   {
    "uri":"http://loadbalancing.{region}.mjc.prc.eucalyptus-systems.com:8773/",
    "constraints": [
      ["region","startsWith","hp-gol01-"]
    ]
   }
  ],
  "autoscaling":[
   {
    "uri":"http://autoscaling.{region}.mjc.prc.eucalyptus-systems.com:8773/",
    "constraints": [
     ["region","startsWith","hp-gol01-"]
    ]
   }
  ],
  "cloudformation":[
   {
    "uri":"http://cloudformation.{region}.mjc.prc.eucalyptus-systems.com:8773/",
    "constraints": [
     ["region","startsWith","hp-gol01-"]
    ]
   }
  ],
  "monitoring":[
    {
      "uri":"http://cloudwatch.{region}.mjc.prc.eucalyptus-systems.com:8773/",
      "constraints": [
       ["region","startsWith","hp-gol01-"]
      ]
    }
  ],
  "swf":[
   {
    "uri":"http://simpleworkflow.{region}.mjc.prc.eucalyptus-systems.com:8773/",
    "constraints": [
     ["region","startsWith","hp-gol01-"]
    ]
   }
  ],
  "iam":[
    {
      "uri":"https://{service}.cn-north-1.amazonaws.com.cn",
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
      "uri":"http://euare.{region}.mjc.prc.eucalyptus-systems.com:8773/",
      "constraints":[
        ["region", "startsWith", "hp-gol01-"]
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
      "uri":"{scheme}://{service}.cn-north-1.amazonaws.com.cn",
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
      "uri":"http://tokens.{region}.mjc.prc.eucalyptus-systems.com:8773/",
      "constraints":[
        ["region", "startsWith", "hp-gol01-"]
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
      "uri":"http://objectstorage.{region}.mjc.prc.eucalyptus-systems.com:8773/",
      "constraints": [
        ["region", "startsWith", "hp-gol01-"]
      ],
      "properties": {
        "signatureVersion": "s3"
      }
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
  "elasticmapreduce":[
    {
      "uri":"https://elasticmapreduce.cn-north-1.amazonaws.com.cn",
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
```

### Configure AWS CLI (Linux)

These instructions show an example of the data from the `hp-gol01-f1` faststart example.
The credentials data can be obtained from the eucarc files of the users contained within.

```bash
mkdir -p ~/.aws
chmod og-rwx ~/.aws

cat << EOF > ~/.aws/config
#
# AWS Config file
#

[default]
region = hp-gol01-f1
output = text

[profile hp-gol01-f1-admin]
region = hp-gol01-f1
output = text

[profile hp-gol01-f1-demo-admin]
region = hp-gol01-f1
output = text

[profile hp-gol01-f1-demo-user]
region = hp-gol01-f1
output = text

[profile hp-gol01-f1-demo-developer]
region = hp-gol01-f1
output = text
EOF

cat << EOF > ~/.aws/credentials
#
# AWS Credentials file
#

[default]
aws_access_key_id = AKIO1BU6J3NCXKVHYY2I
aws_secret_access_key = ZI3ilTW9bfIMV0RuuKJ7JBPtJYFVHJGIlEAdYT0F

[hp-gol01-f1-admin]
aws_access_key_id = AKIO1BU6J3NCXKVHYY2I
aws_secret_access_key = ZI3ilTW9bfIMV0RuuKJ7JBPtJYFVHJGIlEAdYT0F

[hp-gol01-f1-demo-admin]
aws_access_key_id = AKIYR4S8TNSY8NXDMDID
aws_secret_access_key = AIted5zUY1BRlvaMO0Nva9NOAyrsuSl9pGrnH8AM

[hp-gol01-f1-demo-user]
aws_access_key_id = AKIKILTYUWOLTROIVSRA
aws_secret_access_key = r3hCv6x5iNRY9XEhsyPgjovwuEn7neITDyrrhepE

[hp-gol01-f1-demo-developer]
aws_access_key_id = AKIUOAA3YF2CLXF1AQY9
aws_secret_access_key = pEZoqog5wHJmTfAdRt1NOXNalgEophjhC0qBzto2
EOF

```

### Use AWS CLI (Linux)

By default, the AWS CLI will use the `default` profile. Usually this is duplicated from one of the
named profiles which are below in the configuration files. 

You can specify a different profile to use via the AWS_DEFAULT_PROFILE environment variable, such as:

```bash
export AWS_DEFAULT_PROFILE=hp-gol01-f1-demo-admin
```

Confirm the AWS CLI version

```bash
aws --version
```

Describe a user's key pairs

```bash
aws ec2 describe-key-pairs
```

### Install AWS CLI (Windows)

Download the AWS CLI MSI installer for Windows (64-bit)
- https://s3.amazonaws.com/aws-cli/AWSCLI64.msi

Double-click the installer to install

### Modify BotoCore to Support Eucalyptus Regions (Windows)

Use the same content as for Linux. The Windows version of the _endpoints.json file
is here: `C:\Program Files\Amazon\AWSCLI\botocore\data\aws\_endpoints.json`


