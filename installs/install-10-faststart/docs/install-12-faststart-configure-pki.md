# FastStart Install: Configure PKI Procedure
### This variant uses the Helion Eucalyptus Development PKI Infrastructure

This document describes the manual procedure to configure PKI, after Eucalyptus has been installed
via the FastStart installer. This includes configuration of an additional trusted root CA
certificate, along with a key and wildcard SSL certificate used to protect UFS and MC URLs.

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
    export EUCA_DNS_PARENT_HOST=ns1.$AWS_DEFAULT_DOMAIN
    export EUCA_DNS_PARENT_IP=10.104.10.80

    export EUCA_PUBLIC_IP_RANGE=10.104.45.1-10.104.45.126
    ```

### Configure Eucalyptus PKI to use the Helion Eucalyptus Development PKI Infrastructure

1. Configure SSL to trust the Helion Eucalyptus Development PKI Infrastructure

    We will use a local development PKI created within the PRC to sign SSL certificates.

    We must add this CA cert to the trusted root certificate authorities on all servers which
    use certificates it issues, and on all browsers which must trust websites served by them.

    The "update-ca-trust extract" command updates both the OpenSSL and Java trusted ca bundles.

    We will verify certificates were added to the OpenSSL trusted ca bundle and Java trusted ca
    bundle.

    You can copy the body of the certificate below to install on your browser in the location 
    shown below.

    ```bash
    if [ ! -L /etc/pki/tls/certs/ca-bundle.crt ]; then
        update-ca-trust enable
    fi

    cat << EOF > /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt
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

    openssl x509 -in /etc/pki/ca-trust/source/anchors/Helion_Eucalyptus_Development_Root_Certification_Authority.crt \
                 -sha1 -noout -fingerprint
    
    update-ca-trust extract
    
    awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
        < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "75:76:2A:DF:A3:97:E8:C8:2F:0A:60:D7:4A:A1:94:AC:8E:A9:E9:3B"
     
    keytool -list \
            -keystore /etc/pki/java/cacerts -storepass changeit | \
       grep -A1 helioneucalyptusdevelopmentrootcertificationauthority
    ```

2. Install SSL Key

    This key is insecure, and should not be used to protect sites exposed to the Internet.

    ```bash
    cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEA1ZvMKQTPRJJGNSQvoA1VuIbtuPpKr5m13j3GO6sdLI3LnR9N
    Xw0HwgQ9cFm8ooISrC3LtlQsk7MAlxa1JRB+fU9PimBxV8CNewNpcgj0O8aDxku8
    XP5c13YCZECkj3eB+Syvqk/+rXXgW/MHb2BXBQCeLlLEeJTR2EkY4WNuhs7Nwc0y
    sadaBwdKXH4nl8Mojm6OcIdfvwcYV/TDUOp5AMT9ffXqPh45F6O9HZGvQErlBxDx
    Khk/CCz8QDiXvjsyJSTrjJBu8jj+xF4ivrUe+AdodUhcKTKjEUs5Ifzp63WgVoUb
    bF2hAhxmMhcUO9fQV70/ijO9LC2fFvNRHdPWVQIDAQABAoIBAQCXJJodHA4ckvOi
    fmxEb6sL2k0y6ccW4UhSbJtrdPQ7pklAb/mrG+k1WxKuAJD829Sih/TwmjbAe5Qb
    VDHwe+9Ec23wl7UbRl/VfuCJk9Rcx2ZOVSB/HGxM+G9QyHyoFwOccAYMGHY3/oQ2
    C4xjPmPUYk+Kr33dZE/nHjHAqT53m2mvMVI8EgSeCUQBJ7o+TvEnkEwnS4Opq+RN
    UVKLYmINBx2D7hN/W341KdHpIUfzivagAEFPKgxAhqLgHCPBTAhvR/WGTjAjqrla
    T3OU3zvkuzVYQG2FSI3zQ6aPK9IB5Pjq3+CMiylVW9kdPPkrIyYTevbWFkkZhAEt
    E2HVIG8xAoGBAPSmvVywVOZ0wuueV0j48gD//yKX1hEdtuv2ORwbkr+rUUzBGsPn
    FsmvrKEhQpbBWGMakotaHnFwYuPcnzvwdXbSjJdifkS/+b0Kjp2ycg+DR8YKv94a
    e6zXcdByR1leG1KnH4ULQPktWyAfaq3+PGRoWAE3s9xC+k1xz4OG7KwvAoGBAN+E
    bAWKaFTJ0NMDx131LJ9RIHThX26IUYgVNXtfAb/q5f8RodlxBoVrJRyhu1vz5q54
    MUdz1XcVFypv7Slhyok+aN6V8cz/r1dAFq41HuhN6SjmeKZN1iVwXJFTBEgRkKeP
    mAxzdsNXvZgrPU/qM1dRXm3nX0R7KIck/kTrWvC7AoGAGLwq9Q4W513yvyO5K3WP
    8i3vu62iRQS+E8lHKOJYyewmQh5b+GaK1UVfrMLSGq/doddz7YblAQ8d0G/j4YmE
    Nsk+0adxoL3QIB7LIIKEKbFaNlmr4GbJDkaSCUMkl5J+LLMc6rSikw7U4cCLZqAH
    txcdnrHlC2XyLJZPJrsjfp0CgYBlYO2R0cYidusFWphpkFNt62D6QmKDgsbgHyaD
    z4K+pm8tMrUjJ7WafA94Hg8Z1NVTWuaXDv3KJkG8mMmL1HQFrc3o7z+eCHZh74qZ
    9zQOj4/qYiZk37b6gi0qKOovOfBPX7zKIPDEBx7STwJfJc2llB1tYdz+9ZFbQrcl
    UU6NEwKBgAuUS+TLfTw6JJMlfVcByJz6FQCOzGMZ2va8R9Ifn+NROFDaoCqtDEMG
    Igosd4JgFzuPD4mFREvbduzdGrgN4Cbb7hmU8QJ9kyU+VRYwr+aMIQjYWxzGArJo
    xql2Ed7tPn8ctWpsTikYYLhYmEkE8cvrrBuQVOGy32Np4WCMQCPw
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    ```

5. Install Wildcard SSL Certificate

    This wildcard certificate, signed by the Helion Eucalyptus Development Root CA hierarchy, 
    protects all UFS and MC URLs.

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    -----BEGIN CERTIFICATE-----
    MIIFuDCCA6CgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBujELMAkGA1UEBhMCVVMx
    EzARBgNVBAgMCkNhbGlmb3JuaWExDzANBgNVBAcMBkdvbGV0YTEYMBYGA1UECgwP
    SGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVjYWx5cHR1cyBEZXZl
    bG9wbWVudDFDMEEGA1UEAww6SGVsaW9uIEV1Y2FseXB0dXMgRGV2ZWxvcG1lbnQg
    Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNTA0MjEwNDIwMjVaFw0x
    ODA0MjAwNDIwMjVaMIGbMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5p
    YTEYMBYGA1UECgwPSGV3bGV0dC1QYWNrYXJkMSYwJAYDVQQLDB1IZWxpb24gRXVj
    YWx5cHR1cyBEZXZlbG9wbWVudDE1MDMGA1UEAwwsKi5ocC1nb2wwMS1mMS5tamMu
    cHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQDVm8wpBM9EkkY1JC+gDVW4hu24+kqvmbXePcY7qx0sjcudH01f
    DQfCBD1wWbyighKsLcu2VCyTswCXFrUlEH59T0+KYHFXwI17A2lyCPQ7xoPGS7xc
    /lzXdgJkQKSPd4H5LK+qT/6tdeBb8wdvYFcFAJ4uUsR4lNHYSRjhY26Gzs3BzTKx
    p1oHB0pcfieXwyiObo5wh1+/BxhX9MNQ6nkAxP199eo+HjkXo70dka9ASuUHEPEq
    GT8ILPxAOJe+OzIlJOuMkG7yOP7EXiK+tR74B2h1SFwpMqMRSzkh/OnrdaBWhRts
    XaECHGYyFxQ719BXvT+KM70sLZ8W81Ed09ZVAgMBAAGjgeUwgeIwDAYDVR0TAQH/
    BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQD
    AgWgMB8GA1UdIwQYMBaAFDZChTaQujqm5C4FWaBQExPk0ttYMGMGA1UdEQRcMFqC
    LCouaHAtZ29sMDEtZjEubWpjLnByYy5ldWNhbHlwdHVzLXN5c3RlbXMuY29tgipo
    cC1nb2wwMS1mMS5tamMucHJjLmV1Y2FseXB0dXMtc3lzdGVtcy5jb20wHQYDVR0O
    BBYEFFbbqFHEHuiO0MicaqHBE06TUk1nMA0GCSqGSIb3DQEBCwUAA4ICAQC/FrPc
    Y0A9UugUdlbPLV2SUF69ED6v9/5Fz3IxwZrvl2fsdRnRMsx6rKfgItjtfEd6s0Z2
    imZ9Izi9TnV5LLZy5aK/Jd5bdyg+S+rnRNqUsY3Gbbg3+PXDyg+He12aNHIZnnq/
    EjZIQ5dv9Iw6BHw3rHhhfcPIUCbf75SLIC+L8Ubu1IVBzG0bnXvTDeyOP1uxtfFh
    fEWJ3mkvFP+vArJW+WTfQ+yEkNfnoDNsGtdZmxDYlF9fGBIUwqUfAoqUDs+E0HaD
    iF0Pndk6T7r6lwBA1lWJHuAZ0suIudRutOTmZxa2eWZ9TwN2KCLi89PY9qbsk9UY
    ticHXo9hnJu8AmkUmWaGaQfjZZlzAu/kI59tb7r9ScypRAesdq76Lt0T4Cg77oLC
    botipgxLgD2k/rkQK+rdm329Y6Y8PIvbSzzVAT0kgLIfbiSTGfViQ6S8x/dgEf2F
    CHRUvXzZkzSDWIlBNLG8DRrdwDQoXlMydmPN8pAYOPNOMnShxzT77s134QUCw1aC
    uTGv6THdhymNe/kAj7wT1tnTi+71bLZCxUJIMFzx/P9dE+I6SM46TLOqOlp2SC7Z
    aKXzlj19VmNaPHgzehTz6CHxHOtKZ7eCTpA32uFf5SEGaf3V0RdVFh22NJ2evu/b
    zq74AEZHLy3AAkwztNcx9Cst8YnxmmlNQg0INQ==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    ```

