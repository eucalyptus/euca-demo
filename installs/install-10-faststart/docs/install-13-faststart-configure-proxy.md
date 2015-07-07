# FastStart Install: Configure Proxy

This document describes the manual procedure to configure an SSL reverse-proxy, after Eucalyptus
has been installed via the FastStart installer.

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

### Configure Eucalyptus Proxy

1. Configure Eucalyptus Console Configuration file

    This step uses sed to automate the edits, then displays the results.

    ```bash
    sed -i -e "/^clchost = localhost$/s/localhost/$(hostname -i)/" \
           -e "/# since eucalyptus allows for different services to be located on different/d" \
           -e "/# physical hosts, you may override the above host and port for each service./d" \
           -e "/# The service list is \[ec2, autoscale, cloudwatch, elb, iam, sts, s3\]./d" \
           -e "/For each service, you can specify a different host and\/or port, for example;/d" \
           -e "/#elb.host=10.20.30.40/d" \
           -e "/#elb.port=443/d" \
           -e "/# set this value to allow object storage downloads to work. Using 'localhost' will generate URLs/d" \
           -e "/# that won't work from client's browsers./d" \
           -e "/#s3.host=<your host IP or name>/d" /etc/eucaconsole/console.ini

    more /etc/eucaconsole/console.ini
    ```

2. Restart Eucalyptus Console service

    Confirm Eucalyptus Console is running on the normal port via a browser:
    http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN:8888/

    ```bash
    chkconfig eucaconsole on

    service eucaconsole restart
    ```

3. Install Nginx yum repository

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

4. Install Nginx

    This is needed for HTTP and HTTPS support running on standard ports

    ```bash
    yum install -y nginx
    ```

5. Configure Nginx to support virtual hosts

    ```bash
    if [ ! -f /etc/nginx/nginx.conf.orig ]; then
        \cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    fi

    mkdir -p /etc/nginx/server.d

    sed -i -e '/include.*conf\.d/a\    include /etc/nginx/server.d/*.conf;' \
           -e '/tcp_nopush/a\\n    server_names_hash_bucket_size 128;' \
           /etc/nginx/nginx.conf
    ```

6. Start Nginx service

    Confirm Nginx is running via a browser:
    http://$(hostname)/

    ```bash
    chkconfig nginx on

    service nginx start
    ```

7.  Configure Nginx Upstream Servers

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

8. Configure Default Server

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

9. Restart Nginx service

    Confirm Nginx is running via a browser:
    http://$(hostname)/

    ```bash
    service nginx restart
    ```

10. Configure Eucalyptus User-Facing Services Reverse Proxy Server

    This server will proxy all API URLs via standard HTTP and HTTPS ports.

    ```bash
    cat << EOF > /etc/nginx/server.d/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    #
    # Eucalyptus User-Facing Services
    #

    server {
        listen       80  default_server;
        listen       443 default_server ssl;
        server_name  ec2.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  s3.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN objectstorage.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  iam.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN euare.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  sts.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN tokens.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  autoscaling.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  cloudformation.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  monitoring.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN cloudwatch.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  elasticloadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN loadbalancing.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        server_name  swf.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN simpleworkflow.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;

        access_log  /var/log/nginx/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-access.log;
        error_log   /var/log/nginx/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key;

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
        }
    }
    EOF

    chmod 644 /etc/nginx/server.d/ufs.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    ```

11. Restart Nginx service

    Confirm Eucalyptus User-Facing Services are running via a browser:
    http://compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    https://compute.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    These should respond with a 403 (Forbidden) error, indicating the AWSAccessKeyId is missing,
    if working correctly

    ```bash
    service nginx restart
    ```

12. Configure Eucalyptus Console Reverse Proxy Server

    This server will proxy the console via standard HTTP and HTTPS ports

    Requests which use HTTP are immediately rerouted to use HTTPS

    Once proxy is configured, configure the console to expect HTTPS

    ```bash
    cat << EOF > /etc/nginx/server.d/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf
    #
    # Eucalyptus Console
    #

    server {
        listen       80;
        server_name  console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;
        return       301 https://\$server_name\$request_uri;
    }

    server {
        listen       443 ssl;
        server_name  console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN;

        access_log  /var/log/nginx/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-access.log;
        error_log   /var/log/nginx/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN-error.log;

        charset  utf-8;

        ssl_protocols        TLSv1 TLSv1.1 TLSv1.2;
        ssl_certificate      /etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt;
        ssl_certificate_key  /etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key;

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

    chmod 644 /etc/nginx/server.d/console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.conf

    sed -i -e "/^session.secure =/s/= .*$/= true/" \
           -e "/^session.secure/a\
    sslcert=/etc/pki/tls/certs/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.crt\\
    sslkey=/etc/pki/tls/private/star.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN.key" /etc/eucaconsole/console.ini
    ```

13. Restart Nginx and Eucalyptus Console services

    Confirm Eucalyptus Console is running via a browser:
    http://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN
    https://console.$AWS_DEFAULT_REGION.$AWS_DEFAULT_DOMAIN

    ```bash
    service nginx restart

    service eucaconsole restart
    ```

