# FastStart Install: Configure Support

This document describes the manual procedure to configure some support-related aspects, after
Eucalyptus has been installed via the FastStart installer.

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

### Configure Eucalyptus Support

1. Use Eucalyptus Administrator credentials

    Eucalyptus Administrator credentials should have been moved from the default location
    where they are downloaded to the hierarchical directory structure used for all demos,
    in the location shown below, as part of the prior faststart manual install procedure.

    ```bash
    cat ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc

    source ~/.creds/$AWS_DEFAULT_REGION/eucalyptus/admin/eucarc
    ```

2. Import Eucalyptus Administrator Support Keypair

    ```bash
    cat << EOF > ~/.ssh/support_id_rsa
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: AES-128-CBC,A7E90718BF61C84826297430F36A3092

    ZaLkWHam/D0edJYg+q/cmu7norygv6uhiTMCyYYWQbqAazdcBT6zvpcxmmCbdoeX
    0FQ0AhM3rD+1/d1e+2nOU0F2SJ9bjfU3FU/MY+OJ5qH5fO6ChMO6H3+x4bQ2knwB
    oYItOvy9PnFCG58XycCam+q8wV49BXsGaHZtoykzTa7v77cvCKwl29QQRUCgym8G
    bXrb90n7V3jEWgHEi3rQZ0/8qGvPU8UDNV+8Jiu16j9GNVShP/30W8uqgT0kj1oS
    TpIFAYQFLW0HlhAmKnqNqqzd2Jet/ebvD3+Om6yIjg6+tncgRjV2kBiIU2WwjJMC
    rTHG0KpQzbEMTfFA8OGEKK3yVjwE92Ypu2SiitFnVVZMYMm0aHR2/Tx5chjed7rV
    gVmPApCjNPOhyQFc+f+KpFsIIOjF7LVRRLRVhnYLujyA+an+BWJjHMhMlQ18Ek9u
    l6b77LoImQIGXq626YSAe9w3rCkOb6CWqMGDKaagvl92N8Topn9W0NXawfbV7ZTM
    Unvi2sLTgsurQ/JpuS7BKmq8gmmmzm8IqhzGBEE9a5G4zJ3vTjRo2lZ6hRN6ri50
    pSHDt6m9b0OU6ZV3FerpjIZWigCkI0VWZPQgPJTF0VKdusU7atG7N1fSCc+GBW39
    opB/mpWghZvI4MLC/5GKG753A2nDYp1K8rBGwXyb27UmZ/6B920cV6L2fqGvyoRO
    q8sP7zsqtU6U+nmZOeRGOQW/XLKRYDnqe5NCC/8tkpMXNk9PAQP9We1X7kxfAl6B
    8WAw+IfSVtBRT76TqwMSqmS3BqAehbeGRZQ+JF33cCxd/8DJcLh8ZHKnlO66m6B9
    K/e2lN+Y6mJCU7g2VSpK6/QzPwYPA63N/CqRoACZw/nQ3T2CBOLK5i7vU57iLHqq
    dUHSdwKrylyb3QPSkttnD9MIuByPN2ZXZCNOp5gXWC/s1hbdGeX/voHtJl8a7g1Z
    1keeDuqW95LMJKhKl0CXFznUHF9wQa3vx8nJVl2K/rXUi5tEw7I/0QD+fER3DTmM
    SYRwinfayzHEUqUCNVEMg/wPfTPPvem07SHPOV8mlVPwusl2RVbHfVg9tTjiB59c
    sc5oEDv2DkWkV6DLXmGR8RVdzYVE845tiJdsEuH5rL5wZyhcCeTccG2PV7+EXjsf
    hxaUqOyZ41izsB0CDg+XwTVKfEg/HO9aqldzn1pSLB2ljVLXdA4PzDpFza2Ey7yy
    d6zyYqGavQ7RXEicv/drdumJI80OwK+BfGw/ex1yjcAQk3jC69Mh3P4ZwVhYBoz1
    TuwTh9yAwTe0cgoaBtesY/KjZaOdYEAZ5HwzT+ofN/HO6UgutZfPH08foNo1+6Hj
    uaSvKENpes/4CviPxX6NuUMyy7VAz6vf+naFzvRB0enB9XmmBnjnT1JTXWPHTIdq
    1rMI8KCvQ0U27KI5bhjYWQOmON0Ai4qfrbtuhQx2sZuU7fM+bqErERVW9gekloX3
    eWHtsITbrRT16luUcCgnubIXMcRCO2rAgbwF4z5YpshexZFFnbqgxOAJC58gtPAi
    dKu/FFZMVwFukKFeyf7WvNleTMu9ziOIs71USXBZpHEiWjsJlcpdkE9KYDX9mLu6
    -----END RSA PRIVATE KEY-----
    EOF

    chmod 0600 ~/.ssh/support_id_rsa

    cat << EOF > ~/.ssh/support_id_rsa.pub
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTXOsL3dwPJxQ9GCpS4izXtxwq\
    tzGw5PCTTVqjy54ZkbmgtqJJTEbT9W4vY6QwuNvsoY7clij7u6Gskfcv93YxMW8c\
    tXIi89lnMAA3VzehAulYOF21+W3sRLe9nPf52js8Mekhl364udTbHMtnpueHyZvG\
    pTJmc3CxO2xYdCa0f8wKxOEXOzGY2EcwWurQPu+jLHU6C5LPulcYfLsYHz1fFuDp\
    8tpVXpHONJwpXLKDoe4iAtkxpKtIZEZEeJNIpuIqiVT8L0uRvYH9Za7yj3Tcxh5r\
    8uE5v925bxkgHk+Hk95YdnfMqJfG8qGtC3tfE6bTOkweLjmiadY+Qz4QBv67\
     support@hpcloud.com
    EOF

    euca-import-keypair -f ~/.ssh/support_id_rsa.pub support
    ```

3. Configure Service Image Login

    ```bash
    euca-modify-property -p services.database.worker.keyname=support

    euca-modify-property -p services.imaging.worker.keyname=support

    euca-modify-property -p services.loadbalancing.worker.keyname=support
    ```

