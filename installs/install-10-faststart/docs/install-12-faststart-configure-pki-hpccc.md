# FastStart Install: Configure PKI Procedure
### This variant uses the HP EBC PKI Infrastructure

This document describes the manual procedure to configure PKI, after Eucalyptus has been installed
via the FastStart installer. This includes configuration of an additional trusted root CA
certificate, along with a key and wildcard SSL certificate used to protect UFS and MC URLs.

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

### Configure Eucalyptus PKI to use the HP EBC PKI Infrastructure

1. Configure SSL to trust the HP EBC Root Certification Authority

    We will use the HP EBC Root Certification Authority created within the EBC to sign SSL
    certificates.

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

    cat << EOF > /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt
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

    openssl x509 -in /etc/pki/ca-trust/source/anchors/hpccc-DC1A-CA.crt \
                 -sha1 -noout -fingerprint
    
    update-ca-trust extract
    
    awk -v cmd='openssl x509 -noout -sha1 -fingerprint' ' /BEGIN/{close(cmd)};{print | cmd}' \
        < /etc/pki/tls/certs/ca-bundle.trust.crt | grep "2B:52:D7:06:1E:59:90:A5:BE:9A:CC:89:BA:C0:C0:90:2B:3E:48:46"
     
    keytool -list \
            -keystore /etc/pki/java/cacerts -storepass changeit | \
       grep -A1 hpccc-dc1a-ca
    ```

2. Install SSL Key

    This key is protected by a passphrase, which must be obtained separately.

    ```bash
    password="<secure_key_passphrase>"

    cat << EOF > /etc/pki/tls/private/star.${REGION}.${DOMAIN}.key.secure
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: DES-EDE3-CBC,045B86B30263BA0B

    i7rWAhJNhwNuhTO7WLegU+ybnsTwvffetBYFea1lVgrhw7K7TdLhmrXc7WoLJ6mL
    P2KV9WHIyJqkqHRtepa8l/y6PcaakyiR7hkRFh0sbMowN6NW5WpzApWiu3t2f+qU
    dwz5HuEi0E80pWxUlI8VE7Ksys2UfBFqpmNp9u0sWxFzgZchOwo/Qfj+NVZhZSpo
    qdUDzKuLq0vU/4zu16kwGDEKLPbNYBynYq6HCrToXEBOgna62Qhnv7VAZTe66xRY
    QaBfAUcQzrDPMAUVL9N3V85eNPqa56vwjbChxPQI9aLOyoBdKiY1tW2l6k4yxK9q
    hX30euBcCs7MG0HD1UTBllWqOoaitTyNoK8dBll5l1CowD7Ua5omFwUC6FJywE9q
    5TCqyVEj1v9GW9A7sgeflXA033Nkb1x2lVOXTgkqQnUh+g3yHg/rFxQjVcyUL7om
    qer2D5q+g2Us04XYMKug2FPLAeQuKucBWmMHHRcN8WRtkGusfCAgPKU4z5DddWvH
    SGw17mYFP134JS4hoYU2YevWYoLKvJxyGoTEeINTibavi5w/uAvuTSZ2fIlW5NTa
    T9m4mmcCzB66GgfylMZ2CwgYPXkAtKUnOhpn3r4MMaenU4tTjtJVY91WR9rZ2WVF
    ou+v6Hp57MYDNM+Y+day2qXhGLads0/wmjLq16AHR0hOrjIX4lK40nO/m2P7aIss
    Ob/DASe4p3Qa1tWq6063nUv3Gi+Do9L2HKnAy2eHMgMt1UBCgHXOqKS4iAF58tve
    KVB6zO+9AHb303x3zUfqT/M3MZ4dx35GPZocCmeftfcb/CZaqrhQeFOZn6S2lExi
    JMJyuvUfwQXcRUud8ZZgP9UpoYEtC1mmpQBI+7CcfxNCAgsFewrLtbjIth5SpcyV
    QOJY2VVNHg4+d3zfEYhHRBBs0d3wJSLF66v5ZpqwReyKm9MPznqlPJOF/+fBzR7E
    yey6H3mWThwATtx2RsVtvx3muGB8boONSDuyGVYEXvmOJGUmQHwvOa4rirD99ON0
    K1ac68mpqDz4Aazni+eUFA3oB3oKy7iGuUU6W31amYhEa7tq9KV9kQBPW2G2MbWj
    Pn12LuXG7UnhAAwaSCT76BdB8ZOMvLffy+P+oVFFuCOjLyDQ3YubTgxNvKJxM/lw
    T6lmfHGwNhFT+qbab8T75elgKmpg6k5Sf5vUwzN7VBCm2pGBqIsHcuNLmzIvWV03
    goR6hSZjy8jWewAV774QdiBQ40eplvIi+NUD2Un3akWdYwIfkQSI5TdG1gxgd32l
    LGByzLn/VfWOy+VMQvFs8s5Yb1gpkHWBUsMY76oCkojRd5K+kGomdtGvJ1V/CzUQ
    w9kZERi1wpBpQeQLtU/gh2hHfSoX0zf8t04J+XxyvgpFVgCCPJbpTxPAjza2OVyi
    tOjEYZQAADLMJ629bBZrvh/V2UnN+I3C1+ST9CgEZGuf80ApTux9+TWSt9l3EZNT
    fhCOAtbhFb8BENjw3MHqgXKTVxsobfDS4QViC7j5oA6hW/zhSzpbRKqJLGmls8mU
    YSF+dk8z/DCaZEO8z5ZqMtcWn/5zJFrmDzJ5ORlIVmsoi6LGRnS5geZMAcWhPNZ0
    -----END RSA PRIVATE KEY-----
    EOF

    openssl rsa -in $certsdir/star.${REGION}.${DOMAIN}.key.secure \
                -out /tmp/star.${REGION}.${DOMAIN}.key \
                -passin pass:$password

    chmod 400 /etc/pki/tls/private/star.${REGION}.${DOMAIN}.key
    ```

3. Install Wildcard SSL Certificate

   This wildcard certificate, signed by the HP EBC Root CA, protects all UFS and MC URLs.

    ```bash
    cat << EOF > /etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt
    -----BEGIN CERTIFICATE-----
    MIIFeTCCBGGgAwIBAgIKHMDJeAADAAAAcDANBgkqhkiG9w0BAQUFADBEMRMwEQYK
    CZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFaHBjY2MxFjAUBgNVBAMT
    DWhwY2NjLURDMUEtQ0EwHhcNMTUwNDE3MjEzOTA3WhcNMTcwNDE2MjEzOTA3WjCB
    ljELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExEjAQBgNVBAcTCVBh
    bG8gQWx0bzEYMBYGA1UEChMPSGV3bGV0dC1QYWNrYXJkMSIwIAYDVQQLExlFeGVj
    dXRpdmUgQnJpZWZpbmcgQ2VudGVyMSAwHgYDVQQDDBcqLmhwLXBhbDIwYS0xLmhw
    Y2NjLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL7m0ikfKX5o
    CtFOjbgPGMpja109ZudT3UaMzULtdXL8jjsjNOvDaCdqevSHly+D7liYs3ABrRQN
    xWzuczFK07sGP73yZWJJIAgPGHRBg9VXTr3yqnHl7vAaJbbQpoTylAdZhiAEF5ig
    dxwydKbN6yZ4jhsaj7Mrw6CVFjI3iMhMpJuYyO/YYI7VhfZDx0qF/DcelAbgKF7/
    +B77jsJ7LXlQ9gxvdXE2w1ywdaYTDgciMFlnqyQf0ZFIIHPMWuVd/BwU0mKvuLOs
    Qq+nlNZB48kSUuVVZh+jsApqdrE+qGCm+OFcP3B2q4CKKIjerY6IQZZeavLmg4UN
    2qGARBdBiwsCAwEAAaOCAhgwggIUMB0GA1UdDgQWBBQv6vCxpW14sawNAvvzN1s4
    ihboBTAfBgNVHSMEGDAWgBTvMVRJeUYla67RivTrvmHTbgzUbTCByQYDVR0fBIHB
    MIG+MIG7oIG4oIG1hoGybGRhcDovLy9DTj1ocGNjYy1EQzFBLUNBKDMpLENOPURD
    MUEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
    LENOPUNvbmZpZ3VyYXRpb24sREM9aHBjY2MsREM9Y29tP2NlcnRpZmljYXRlUmV2
    b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2lu
    dDCBvQYIKwYBBQUHAQEEgbAwga0wgaoGCCsGAQUFBzAChoGdbGRhcDovLy9DTj1o
    cGNjYy1EQzFBLUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxD
    Tj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWhwY2NjLERDPWNvbT9jQUNl
    cnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0
    eTAhBgkrBgEEAYI3FAIEFB4SAFcAZQBiAFMAZQByAHYAZQByMA4GA1UdDwEB/wQE
    AwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATANBgkqhkiG9w0BAQUFAAOCAQEAd1r/
    2koqygZF0CJdEhyI3BhSthF+vaKqesNBlOgct5gY39nO8yXVjqwUONy9lG0qJ0zW
    untXK395/ifwq2C3nHEXQKQt1pQ45qLKJhA+9DpFrnNcunSbDv9uVSa1Or9cDsoF
    tBIy2x+omkr7gE6QQUBlnl0Bolxc6QYrpNfzuNuDbngELOKi4UlpaZmPCAe0RN0f
    T0wNO/GNebzwg4zEf0uegQO0OMLOtEEWfrPKrXEEAMRZBkDIqv2qUY6DbdCC1dLX
    JhwqRwLbQRtYdjV2xQQ8yYdAtsMtKH7v8vMT+IYVVfj/UyrviveXuwOMjW/RfSlp
    Os/7sQZddG9kdBx8KA==
    -----END CERTIFICATE-----
    EOF

    chmod 444 /etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt
    ```

