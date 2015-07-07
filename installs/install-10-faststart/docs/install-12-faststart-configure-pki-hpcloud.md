# FastStart Install: Configure PKI Procedure
### This variant uses the HP Cloud Multi-level PKI Infrastructure

This document describes the manual procedure to configure PKI, after Eucalyptus has been installed
via the FastStart installer. This includes configuration of additional trusted root and issuing CA
certificates, along with a key and wildcard SSL certificate used to protect UFS and MC URLs.

This variant is meant to be run as root

This procedure is based on the hp-aw2-1 demo environment running on host ops-aw2az3-eucaclc0001
in Las Vegas. It uses **hp-aw2-1** as the AWS_DEFAULT_REGION, and **hpcloudsvc.com** as the
AWS_DEFAULT_DOMAIN.

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
    export AWS_DEFAULT_REGION=hp-aw2-1
    export AWS_DEFAULT_DOMAIN=hpcloudsvc.com

    export EUCA_DNS_INSTANCE_SUBDOMAIN=.eucalyptus
    export EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb

    export EUCA_PUBLIC_IP_RANGE=15.185.206.64-15.185.206.95
    ```

### Configure Eucalyptus PKI to use the HP Cloud Multi-level PKI Infrastructure

1. Configure SSL to trust HPCloud Root Certification Authority

    We will use the HP Cloud Root Certification Authority, along with 2 more intermediate
    Certification Authorities to sign SSL certificates.

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

    cat << EOF > /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt
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

    openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudca.hpcloud.ms.crt \
                 -sha1 -noout -fingerprint
    
    update-ca-trust extract
    
    awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
        < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "67:0E:8C:B9:44:BD:D6:AB:E4:1A:55:EF:81:8F:6F:C6:19:70:6F:EA"
     
    keytool -list \
            -keystore /etc/pki/java/cacerts -storepass changeit | \
       grep -A1 cloudca.hpcloud.ms
    ```

2. Configure SSL to trust HPCloud Issuing Certification Authority

    The second of three CA certificates we must trust.

    You can copy the body of the certificate below to install on your browser in the location 
    shown below.

    ```bash
    cat << EOF > /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt
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

    openssl x509 -in /etc/pki/ca-trust/source/anchors/cloudpca.uswest.hpcloud.ms.crt \
                 -sha1 -noout -fingerprint
    
    update-ca-trust extract
    
    awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
        < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "6B:27:E1:D6:38:E6:15:BB:27:E3:27:61:31:69:31:BA:C5:93:44:D3"
     
    keytool -list \
            -keystore /etc/pki/java/cacerts -storepass changeit | \
       grep -A1 cloudpca
    ```

3. Configure SSL to trust HPCloud Issuing Certification Authority

    The third of three CA certificates we must trust.

    You can copy the body of the certificate below to install on your browser in the location
    shown below.

    ```bash
    cat << EOF > /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt
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

    openssl x509 -in /etc/pki/ca-trust/source/anchors/aw2cloudica03.uswest.hpcloud.ms.crt \
                 -sha1 -noout -fingerprint

    update-ca-trust extract

    awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
        < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "B4:A0:1C:96:5F:75:A8:23:80:96:B2:A2:4F:32:20:22:5B:4A:62:0F"

    keytool -list \
            -keystore /etc/pki/java/cacerts -storepass changeit | \
       grep -A1 aw2cloudica03
    ```

4. Install SSL Key

    This key is protected by a passphrase, which must be obtained separately.

    ```bash
    password="<secure_key_passphrase>"

    cat << EOF > /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: DES-EDE3-CBC,22715E33D80182F9

    jbs9I/rTy/P7FHl6wfi5GbVAIDF+iHFjUsu0cWWK6wmPxzkzcYTSE3KtEF15OMOR
    1UVXMCG8M/VXiRBbkhD1MuOl/beS9NbitR9cWgt//9F96gpg/y7R1R33bzc+XoKx
    KJ9znxi/VOoIasQP2reybeITFn6k7FHSSd4YJEQhSdg+uFEWd9iTEpl47PVtBBSE
    XRP+o3u3eFN20xaUS2jlB2SVHo2fkMdvAj4r2ECQvsgltXCVcC3GYwLro+RnKBND
    zJ8Em5jCjGkkBWPie5UxLGvPth+ErG2YApXh0ea8LgcHjz4VJI1oM9gmTuQUGVuh
    WXr+39oI7yaIM4//pTEX9n6FMRYF+9T2eLTjr5OWeGtPy7jTvRzgwJYk7UytWfUF
    RwC2WAfQdJ07nloj4+ssSNjj9Ma1fsEl35Cv5qx2i0BRj0d4Pu/+jDL6Ee00qSC4
    7C5cd1lz0OFv3+yjYCYOUy8juRPvYgAzZi7vgJUpsY6UZdF4IZ/NJMk6aeCyo9h4
    fFcnJE1em12IXI9/jF7uBsDM3ZliSMiBjciWR8utcr4A04nXt8bY91aLcz82ZrDm
    TuIghZFfTYUDI7hAREIzpoPwE6b5+LaBZ1vgBprQMIk5chw2keTxd3+0xNo1yZ7u
    zvtZYFJFwhv+Ud0Rl4UIZEW/ing7bcE5IeYpl9UKnzLeBBKKxFfEZcfgqg4zwhHm
    Rv5aihjjXkVfRni6KYvfukMUcBAoDi9UWSp8hvkc2SQHMDCZJb/CQkB8rzDy6eFA
    /KLiZ+OiVMi1mg9rgEQBVW0lwXpgDjzosUvam2HQyKIwhnHgYSsQRe4KPZPqMdpQ
    CcFTR941ec0/nkQQtPxz6kM9KougOWGpAyImw1V2I8hMcjoHRdG1PVATQUd1FTkp
    Y5RXid0RkLnZvtPbsO42SCPzs+JZY9Vtbk89sFaWhKbNSqAVvjtYDbBOloclAPTM
    pFwSlPS0dnOJEUgvzpqfZkqQsWp5qKgTFAEFFgxOXjQ1Gy2LFvxDCzDOnYmXRuC3
    T1QVvkbJF99mm9lxQl7ylZku7q0E3GOrPTwJMmglw8iVEGihpKSXH4MvDfii4alg
    KVKRjb98gblv+mwb0EuQUtBDfbTrL83FNxEhvgIPHRNczVd30POQ6HlARufdEADE
    hY6lTTVUL1BCZ7nzD7fLoPlrBTAHrg/6H8/SvSJ1b603ftC7JZkscMVaLfmgj+VA
    WCPpCFWcZipwxc/sY9Io/DP1LWnubnbuK7Z2AjYtrcoku/7e5XTr1513lTO4g4EQ
    1Hqw24Z/yPyUaVRj/qHIjUhMGVwm8ujSZiSjyO6NiW4IjQ7kCVRE3nWcdL2vg1tV
    lFMd1047m+tKecFCd0ymbZ85KNa/m2u/l51bt8Q/A0smxthPrQOGgrPNzWyOZB9m
    jQl03r/w67NmjVjOsE83sJm5nB8NpSCDHvJYEmzrjoL2EOMMa3uLp2CMrf2d9Sc9
    orTEGSSaECeV69I7MOmh0movs8oLjp94Q5I+dB9gGEF/e+PwxSBmoMbz2G1fVmlv
    c5Ji/fFFjEj71t8tc3MSPgdKcDoEchzxNJm0dbDlRs5SIPp1xBOplQ==
    -----END RSA PRIVATE KEY-----
    EOF

    openssl rsa -in $certsdir/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key.secure \
                -out /tmp/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key \
                -passin pass:$password

    chmod 400 /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key
    ```

5. Install Wildcard SSL Certificate

   This wildcard certificate, signed by the HP Cloud CA hierarchy, protects all UFS and MC URLs.

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    -----BEGIN CERTIFICATE-----
    MIIFBzCCA++gAwIBAgIKfsamWgAAAAAAWDANBgkqhkiG9w0BAQsFADBFMRIwEAYK
    CZImiZPyLGQBGRYCbXMxFzAVBgoJkiaJk/IsZAEZFgdocGNsb3VkMRYwFAYDVQQD
    Ew1hdzJjbG91ZGljYTAzMB4XDTE1MDYxODIyMzE0M1oXDTE3MDIyODA1MDUyMVow
    gbExCzAJBgNVBAYTAlVTMQ8wDQYDVQQIEwZOZXZhZGExEjAQBgNVBAcTCUxhcyBW
    ZWdhczEYMBYGA1UEChMPSGV3bGV0dC1QYWNrYXJkMRcwFQYDVQQLEw5DbG91ZCBT
    ZXJ2aWNlczEiMCAGA1UEAxQZKi5ocC1hdzItMS5ocGNsb3Vkc3ZjLmNvbTEmMCQG
    CSqGSIb3DQEJARYXbmF0aGFuaWVsLmRpbGxvbkBocC5jb20wggEiMA0GCSqGSIb3
    DQEBAQUAA4IBDwAwggEKAoIBAQDEZ69aa6QFzhSn0d8mbw6PzHxgRu1mj5GNTpES
    tOqY3pEovBnWMj0uErQ8ZrcvmzdaT8k727GD4Wj8I5wY5Fe1vzHDi7t6IuBHlU76
    GGCBgW0jwry+6sqwzSnh8K1dwRTW4btMPduXkl7s7or78RGnNyB4pfBJ8dFDpo09
    1iS2USh/btvNGsGohHMeF8v6tPMu840t7LtYFNq/gNTB1Q/G3w0bIC48oFUCE7fR
    d94onS1WA6VuBMt8FeRzp+4tdCXuuSNHJ+uW3lSWoU2V2R/VporZP6SMcdCE0ifL
    BW1R4JOt1Nc1NSqtf9q0T4uwpUYyZRH54y1LQF7UfmBiMr67AgMBAAGjggGKMIIB
    hjAMBgNVHRMBAf8EAjAAMAsGA1UdDwQEAwIF4DATBgNVHSUEDDAKBggrBgEFBQcD
    ATA9BgNVHREENjA0ghdocC1hdzItMS5ocGNsb3Vkc3ZjLmNvbYIZKi5ocC1hdzIt
    MS5ocGNsb3Vkc3ZjLmNvbTAdBgNVHQ4EFgQUF0RqXSXRTIW3ponk9QaLiz0U1zow
    HwYDVR0jBBgwFoAUIsX2rnOI2dW38KM/QO6zvRtm1WgwVAYDVR0fBE0wSzBJoEeg
    RYZDaHR0cDovL2F3MmNsb3VkaWNhMDMudXN3ZXN0LmhwY2xvdWQubXMvQ2VydEVu
    cm9sbC9hdzJjbG91ZGljYTAzLmNybDB/BggrBgEFBQcBAQRzMHEwbwYIKwYBBQUH
    MAGGY2h0dHA6Ly9hdzJjbG91ZGljYTAzLnVzd2VzdC5ocGNsb3VkLm1zL0NlcnRF
    bnJvbGwvQVcyQ0xPVURJQ0EwMy51c3dlc3QuaHBjbG91ZC5tc19hdzJjbG91ZGlj
    YTAzLmNydDANBgkqhkiG9w0BAQsFAAOCAQEApAgjNKKLCdmJdLTuLxw9GgC4TYt0
    m1hOU23OeNWgM4qLnXxep+dCFu3w+vl/LrvyQyk4nPj3LlFJd6hFrB2X6K6TxkOh
    oBg/tagMRU7t8UK01Yeudg1i2+79b06Gc9OLMD22wjFvrE1ghgXTgcOVMYZPGCXY
    IThk2O9Zi2VphQUUCXoRZ4wBu3A8Jo0+36WDcxdK1pY9a38SQ9kXzkItFdOhZh9M
    8RlXHKu0nx7IXGlKonkx9Jl4kTKkEQY4wog8wj8zXgKC/A6A1APzpO0R0IXHfFVQ
    QJdR8OltdYrBEv+u1YYmnGp1sx2802z7kN7VdjOr9zlZpBww6x4XQJ1s5Q==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt
    ```

