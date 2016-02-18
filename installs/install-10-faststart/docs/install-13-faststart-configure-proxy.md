# FastStart Install: Configure Proxy

This document describes the manual procedure to configure an SSL reverse-proxy, after Eucalyptus
has been installed via the FastStart installer.

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

### Configure Eucalyptus Proxy

1. Configure Eucalyptus Console to use custom SSL Certificate

    At this point, we will reference the UFS FQDN URL, but must continue to use port 8773 until we
    complete replacement of the SSL proxy with a version that works with both the Console and UFS.

    ```bash
    sed -i -e "/^ufshost = localhost$/s/localhost/ufs.${REGION}.${DOMAIN}/" /etc/eucaconsole/console.ini

    sed -i -e "/^session.secure/a\
    sslcert=/etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt\
    sslkey=/etc/pki/tls/private/star.${REGION}.${DOMAIN}.key" /etc/eucaconsole/console.ini
    ```

2. Configure Embedded Nginx Proxy to use custom SSL Certificate

    ```bash
    sed -i -e "s/\/etc\/eucaconsole\/console.crt;/\/etc\/pki\/tls\/certs\/star.${REGION}.${DOMAIN}.crt;/" \
           -e "s/\/etc\/eucaconsole\/console.key;/\/etc\/pki\/tls\/private\/star.${REGION}.${DOMAIN}.key;/" \
        /etc/eucaconsole/nginx.conf
    ```

3. Restart Eucalyptus Console service

    ```bash
    service eucaconsole restart
    ```

4. Confirm Eucalyptus Console via Embedded Nginx Proxy

    Open the following URL in a Browser:

    * https://console.${REGION}.${DOMAIN}/

    Confirm no SSL configuration errors. The Browser should show the trusted lock icon, assuming you have
    configured your workstation to trust the Root CA which issued the SSL Certificate.

5. Disable Embedded Nginx Proxy

    We will disable the Embedded Nginx Proxy which is started with the Eucalyptus Console by default,
    so we can replace it with a new Separate Nginx Proxy which works with both the Console and
    User-Facing Services.

    ```bash
    sed -i -e "/NGINX_FLAGS=/ s/=/=NO/" /etc/sysconfig/eucaconsole
    ```

6. Restart Eucalyptus Console

    You should see the Embedded Nginx Proxy stop, but not restart

    ```bash
    service eucaconsole restart
    ```

7. Install Nginx yum repository

    We need a later version of Nginx than is currently in EPEL.

    ```bash
    cat << EOF > /etc/yum.repos.d/nginx.repo
    [nginx]
    name=nginx repo
    baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
    priority=1
    gpgcheck=0
    enabled=1
    EOF
    ```

8. Install Nginx

    ```bash
    yum install -y nginx
    ```

9. Configure Nginx to support virtual hosts

    ```bash
    if [ ! -f /etc/nginx/nginx.conf.orig ]; then
        \cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    fi

    mkdir -p /etc/nginx/server.d

    sed -i -e '/include.*conf\.d/a\    include /etc/nginx/server.d/*.conf;' \
           -e '/tcp_nopush/a\\n    server_names_hash_bucket_size 128;' \
           /etc/nginx/nginx.conf
    ```

10. Start Separate Nginx Proxy

    ```bash
    chkconfig nginx on

    service nginx start
    ```

11. Confirm Separate Nginx Proxy

    Open the following URL in a Browser:

    * http://$(hostname)/

    Confirm the basic Nginx test page is working.

12. Configure Nginx Upstream Servers

    ```bash
    cat << EOF > /etc/nginx/conf.d/upstream.conf
    #
    # Upstream servers
    #
    
    # Eucalytus User-Facing Services
    upstream ufs {
        server localhost:8773 max_fails=3 fail_timeout=30s;
    }
   
    # Eucalyptus Console
    upstream console {
        server localhost:8888 max_fails=3 fail_timeout=30s;
    }
    EOF
    ```

13. Configure Nginx Default Server

    We also need to update or create the default home and error pages. Because we are not 
    using the EPEL re-packaging, we do not get what they added in this area, and must
    create something similar from scratch.

    ```bash
    if [ ! -f /etc/nginx/conf.d/default.conf.orig ]; then
        \cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig
    fi

    cat << EOF > /etc/nginx/conf.d/default.conf
    #
    # Default server: http://$(hostname)
    #

    server {
        listen       80;
        server_name  $(hostname);

        root  /usr/share/nginx/html;

        access_log  /var/log/nginx/access.log;
        error_log   /var/log/nginx/error.log;

        charset  utf-8;

        keepalive_timeout  70;

        location / {
            index  index.html;
        }

        error_page  404  /404.html;
        location = /404.html {
            root   /usr/share/nginx/html;
        }

        error_page  500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        location ~ /\.ht {
            deny  all;
        }
    }
    EOF

    cat << EOF > /usr/share/nginx/html/index.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>Test Page for the Nginx HTTP Server on $(hostname -s)</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>
        <body>
            <h1>Welcome to <strong>nginx</strong> on $(hostname -s)!</h1>
            <div class=\"content\">
                <p>This page is used to test the proper operation of the
                <strong>nginx</strong> HTTP server after it has been
                installed. If you can read this page, it means that the
                web server installed at this site is working
                properly.</p>
                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>This is the default <tt>index.html</tt> page that
                        is distributed with <strong>nginx</strong> on
                        EPEL.  It is located in
                        <tt>/usr/share/nginx/html</tt>.</p>
                        <p>You should now put your content in a location of
                        your choice and edit the <tt>root</tt> configuration
                        directive in the <strong>nginx</strong>
                        configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>
                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF

    cat << EOF > /usr/share/nginx/html/404.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>The page is not found</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                h3 {
                    text-align: center;
                    background-color: #ff0000;
                    padding: 0.5em;
                    color: #fff;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>

        <body>
            <h1><strong>nginx error!</strong></h1>

            <div class=\"content\">

                <h3>The page you are looking for is not found.</h3>

                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>Something has triggered missing webpage on your
                        website. This is the default 404 error page for
                        <strong>nginx</strong> that is distributed with
                        EPEL.  It is located
                        <tt>/usr/share/nginx/html/404.html</tt></p>

                        <p>You should customize this error page for your own
                        site or edit the <tt>error_page</tt> directive in
                        the <strong>nginx</strong> configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>

                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF

    cat << EOF > /usr/share/nginx/html/50x.html
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">
        <head>
            <title>The page is temporarily unavailable</title>
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
            <style type=\"text/css\">
                /*<![CDATA[*/
                body {
                    background-color: #fff;
                    color: #000;
                    font-size: 0.9em;
                    font-family: sans-serif,helvetica;
                    margin: 0;
                    padding: 0;
                }
                :link {
                    color: #c00;
                }
                :visited {
                    color: #c00;
                }
                a:hover {
                    color: #f50;
                }
                h1 {
                    text-align: center;
                    margin: 0;
                    padding: 0.6em 2em 0.4em;
                    background-color: #294172;
                    color: #fff;
                    font-weight: normal;
                    font-size: 1.75em;
                    border-bottom: 2px solid #000;
                }
                h1 strong {
                    font-weight: bold;
                    font-size: 1.5em;
                }
                h2 {
                    text-align: center;
                    background-color: #3C6EB4;
                    font-size: 1.1em;
                    font-weight: bold;
                    color: #fff;
                    margin: 0;
                    padding: 0.5em;
                    border-bottom: 2px solid #294172;
                }
                h3 {
                    text-align: center;
                    background-color: #ff0000;
                    padding: 0.5em;
                    color: #fff;
                }
                hr {
                    display: none;
                }
                .content {
                    padding: 1em 5em;
                }
                .alert {
                    border: 2px solid #000;
                }
                img {
                    border: 2px solid #fff;
                    padding: 2px;
                    margin: 2px;
                }
                a:hover img {
                    border: 2px solid #294172;
                }
                .logos {
                    margin: 1em;
                    text-align: center;
                }
                /*]]>*/
            </style>
        </head>

        <body>
            <h1><strong>nginx error!</strong></h1>

            <div class=\"content\">

                <h3>The page you are looking for is temporarily unavailable.  Please try again later.</h3>

                <div class=\"alert\">
                    <h2>Website Administrator</h2>
                    <div class=\"content\">
                        <p>Something has triggered an error on your
                        website.  This is the default error page for
                        <strong>nginx</strong> that is distributed with
                        EPEL.  It is located
                        <tt>/usr/share/nginx/html/50x.html</tt></p>

                        <p>You should customize this error page for your own
                        site or edit the <tt>error_page</tt> directive in
                        the <strong>nginx</strong> configuration file
                        <tt>/etc/nginx/nginx.conf</tt>.</p>

                    </div>
                </div>
            </div>
        </body>
    </html>
    EOF
    ```

14. Restart Separate Nginx Proxy

    ```bash
    service nginx restart
    ```

15. Confirm Separate Nginx Proxy

    Open the following URL in a Browser:

    * http://$(hostname)/

    Confirm an updated Nginx test page showing the hostname is working.

16. Configure Eucalyptus User-Facing Services Reverse Proxy Server

    This server will proxy all API URLs via standard HTTP and HTTPS ports.

    ```bash
    cat << EOF > /etc/nginx/server.d/ufs.${REGION}.${DOMAIN}.conf
    #
    # Eucalyptus User-Facing Services
    #

    server {
        listen       80  default_server;
        listen       443 default_server ssl;
        server_name  ec2.${REGION}.${DOMAIN} compute.${REGION}.${DOMAIN};
        server_name  s3.${REGION}.${DOMAIN} objectstorage.${REGION}.${DOMAIN};
        server_name  iam.${REGION}.${DOMAIN} euare.${REGION}.${DOMAIN};
        server_name  sts.${REGION}.${DOMAIN} tokens.${REGION}.${DOMAIN};
        server_name  autoscaling.${REGION}.${DOMAIN};
        server_name  cloudformation.${REGION}.${DOMAIN};
        server_name  monitoring.${REGION}.${DOMAIN} cloudwatch.${REGION}.${DOMAIN};
        server_name  elasticloadbalancing.${REGION}.${DOMAIN} loadbalancing.${REGION}.${DOMAIN};
        server_name  swf.${REGION}.${DOMAIN} simpleworkflow.${REGION}.${DOMAIN};

        access_log  /var/log/nginx/ufs.${REGION}.${DOMAIN}-access.log;
        error_log   /var/log/nginx/ufs.${REGION}.${DOMAIN}-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.${REGION}.${DOMAIN}.key;

        keepalive_timeout  70;
        client_max_body_size 100M;
        client_body_buffer_size 128K;

        location / {
            proxy_pass            http://ufs;
            proxy_redirect        default;
            proxy_next_upstream   error timeout invalid_header http_500;
            proxy_connect_timeout 30;
            proxy_send_timeout    90;
            proxy_read_timeout    90;

            proxy_http_version    1.1;

            proxy_buffering       on;
            proxy_buffer_size     128K;
            proxy_buffers         4 256K;
            proxy_busy_buffers_size 256K;
            proxy_temp_file_write_size 512K;

            proxy_set_header      Host \$host;
            proxy_set_header      X-Real-IP  \$remote_addr;
            proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header      X-Forwarded-Proto \$scheme;
            proxy_set_header      Connection "keep-alive";
        }
    }
    EOF

    chmod 644 /etc/nginx/server.d/ufs.${REGION}.${DOMAIN}.conf
    ```

17. Configure Eucalyptus Console Reverse Proxy Server

    This server will proxy the console via standard HTTP and HTTPS ports

    Requests which use HTTP are immediately rerouted to use HTTPS

    ```bash
    cat << EOF > /etc/nginx/server.d/console.${REGION}.${DOMAIN}.conf
    #
    # Eucalyptus Console
    #

    server {
        listen       80;
        server_name  console.${REGION}.${DOMAIN};
        return       301 https://$server_name$request_uri;
    }

    server {
        listen       443 ssl;
        server_name  console.${REGION}.${DOMAIN};

        access_log  /var/log/nginx/console.${REGION}.${DOMAIN}-access.log;
        error_log   /var/log/nginx/console.${REGION}.${DOMAIN}-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.${REGION}.${DOMAIN}.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.${REGION}.${DOMAIN}.key;

        keepalive_timeout  70;
        client_max_body_size 100M;
        client_body_buffer_size 128K;

        location / {
            proxy_pass            http://console;
            proxy_redirect        default;
            proxy_next_upstream   error timeout invalid_header http_500;

            proxy_connect_timeout 30;
            proxy_send_timeout    90;
            proxy_read_timeout    90;

            proxy_buffering       on;
            proxy_buffer_size     128K;
            proxy_buffers         4 256K;
            proxy_busy_buffers_size 256K;
            proxy_temp_file_write_size 512K;

            proxy_set_header      Host \$host;
            proxy_set_header      X-Real-IP  \$remote_addr;
            proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header      X-Forwarded-Proto \$scheme;
        }
    }
    EOF

    chmod 644 /etc/nginx/server.d/console.${REGION}.${DOMAIN}.conf
    ```

18. Configure Eucalyptus Console to access UFS via Separate Nginx Proxy

    We can now reference UFS via HTTPS using standard SSL port 443.

    ```bash
    sed -i -e "/^ufsport = 8773$/s/8773/443/" /etc/eucaconsole/console.ini
    ```

19. Restart Eucalyptus Console and Separate Nginx Proxy

    ```bash
    service eucaconsole restart

    service nginx restart
    ```

20. Confirm Eucalyptus UFS and Console via Separate Nginx Proxy

    Open the following URLs in a Browser:

    * https://compute.${REGION}.${DOMAIN}/
    * https://console.${REGION}.${DOMAIN}/

    Confirm no SSL configuration errors. The Browser should show the trusted lock icon, assuming
    you have configured your workstation to trust the Root CA which issued the SSL Certificate.

    The compute URL should return a 403:Forbidden error, as we are not passing credentials.

21. Configure Euca2ools Region with HTTPS Endpoints

    We can now switch to HTTPS via the Separate Nginx Proxy. Note we copy the cloud certificate
    from the default location to the same directory used for other cloud certificates, giving
    it a similar name. This allows us to centralize multiple regions onto a single management
    workstation.

    ```bash
    cat << EOF > /etc/euca2ools/conf.d/${REGION}.ini
    ; Eucalyptus Region ${REGION}

    [region ${REGION}]
    autoscaling-url = https://autoscaling.${REGION}.${DOMAIN}:8773/
    bootstrap-url = https://bootstrap.${REGION}.${DOMAIN}:8773/
    cloudformation-url = https://cloudformation.${REGION}.${DOMAIN}:8773/
    ec2-url = https://ec2.${REGION}.${DOMAIN}:8773/
    elasticloadbalancing-url = https://elasticloadbalancing.${REGION}.${DOMAIN}:8773/
    iam-url = https://iam.${REGION}.${DOMAIN}:8773/
    monitoring-url = https://monitoring.${REGION}.${DOMAIN}:8773/
    properties-url = https://properties.${REGION}.${DOMAIN}:8773/
    reporting-url = https://reporting.${REGION}.${DOMAIN}:8773/
    s3-url = https://s3.${REGION}.${DOMAIN}:8773/
    sts-url = https://sts.${REGION}.${DOMAIN}:8773/
    user = ${REGION}-admin

    certificate = /usr/share/euca2ools/certs/cert-${REGION}.pem
    verify-ssl = true
    EOF

    cp /var/lib/eucalyptus/keys/cloud-cert.pem /usr/share/euca2ools/certs/cert-${REGION}.pem
    chmod 0644 /usr/share/euca2ools/certs/cert-${REGION}.pem
    ```

22. Display Euca2ools Configuration

    This is an example of the configuration which should result from the logic in the last step.

    * The ${REGION} Region should still be the default.
    * The ${REGION} Region should be configured with Custom DNS HTTPS URLs. It can be used from
      other hosts.
    * The localhost Region should still be configured with the default direct URLs. It can only
      be used from the FastStart host.
    * The ${REGION} and localhost Regions should each have the same single Eucalyptus Administrator
      User.

    ~/.euca/global.ini
    ```bash
    ; Eucalyptus Global

    [global]
    default-region = ${REGION}
    ```

    /etc/euca2ools/conf.d/${REGION}.ini
    ```bash
    ; Eucalyptus Region ${REGION}

    [region ${REGION}]
    autoscaling-url = https://autoscaling.${REGION}.${DOMAIN}/
    bootstrap-url = https://bootstrap.${REGION}.${DOMAIN}/
    cloudformation-url = https://cloudformation.${REGION}.${DOMAIN}/
    ec2-url = https://ec2.${REGION}.${DOMAIN}/
    elasticloadbalancing-url = https://elasticloadbalancing.${REGION}.${DOMAIN}/
    iam-url = https://iam.${REGION}.${DOMAIN}/
    monitoring-url = https://monitoring.${REGION}.${DOMAIN}/
    properties-url = https://properties.${REGION}.${DOMAIN}/
    reporting-url = https://reporting.${REGION}.${DOMAIN}/
    s3-url = https://s3.${REGION}.${DOMAIN}/
    sts-url = https://sts.${REGION}.${DOMAIN}/
    user = ${REGION}-admin

    certificate = /usr/share/euca2ools/certs/cert-${REGION}.pem
    verify-ssl = true
    ```

    /etc/euca2ools/conf.d/localhost.ini
    ```bash
    ; Eucalyptus (all user services on localhost)

    [region localhost]
    autoscaling-url = http://127.0.0.1:8773/services/AutoScaling/
    cloudformation-url = http://127.0.0.1:8773/services/CloudFormation/
    ec2-url = http://127.0.0.1:8773/services/compute/
    elasticloadbalancing-url = http://127.0.0.1:8773/services/LoadBalancing/
    iam-url = http://127.0.0.1:8773/services/Euare/
    monitoring-url = http://127.0.0.1:8773/services/CloudWatch/
    s3-url = http://127.0.0.1:8773/services/objectstorage/
    sts-url = http://127.0.0.1:8773/services/Tokens/
    user = localhost-admin

    bootstrap-url = http://127.0.0.1:8773/services/Empyrean/
    properties-url = http://127.0.0.1:8773/services/Properties/
    reporting-url = http://127.0.0.1:8773/services/Reporting/

    certificate = /var/lib/eucalyptus/keys/cloud-cert.pem
    ```

    ~/.euca/${REGION}.ini
    ```bash
    ; Eucalyptus Region ${REGION}

    [user ${REGION}-admin]
    key-id = AKIAATYHPHEMVRQ46T43
    secret-key = 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
    account-id = 000987072445
    ```

    ~/.euca/localhost.ini
    ```bash
    ; Eucalyptus Region localhost

    [user localhost-admin]
    key-id = AKIAATYHPHEMVRQ46T43
    secret-key = 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
    account-id = 000987072445
    ```

