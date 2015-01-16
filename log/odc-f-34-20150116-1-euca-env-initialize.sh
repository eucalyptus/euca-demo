[root@odc-f-34 ~]# source euca-env-initialize.sh -I

============================================================

  1. Initialize Environment

============================================================

Commands:

export EUCA_VNET_MODE="EDGE"
export EUCA_VNET_PRIVINTERFACE="em1"
export EUCA_VNET_PUBINTERFACE="em2"
export EUCA_VNET_BRIDGE="br0"
export EUCA_VNET_PUBLICIPS="10.104.46.1-10.104.46.126"
export EUCA_VNET_SUBNET="172.46.0.0"
export EUCA_VNET_NETMASK="255.255.128.0"
export EUCA_VNET_ADDRSPERNET="32"
export EUCA_VNET_DNS="8.8.8.8"

export EUCA_CLC_HOST_NAME="odc-f-34"
export EUCA_CLC_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_CLC_PUBLIC_IP=10.104.10.76
export EUCA_CLC_PRIVATE_IP=10.105.10.76

export EUCA_UFS_HOST_NAME="odc-f-34"
export EUCA_UFS_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_UFS_PUBLIC_IP=10.104.10.76
export EUCA_UFS_PRIVATE_IP=10.105.10.76

export EUCA_MC_HOST_NAME="odc-f-34"
export EUCA_MC_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_MC_PUBLIC_IP=10.104.10.76
export EUCA_MC_PRIVATE_IP=10.105.10.76

export EUCA_CC_HOST_NAME="odc-f-34"
export EUCA_CC_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_CC_PUBLIC_IP=10.104.10.76
export EUCA_CC_PRIVATE_IP=10.105.10.76

export EUCA_SC_HOST_NAME="odc-f-34"
export EUCA_SC_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_SC_PUBLIC_IP=10.104.10.76
export EUCA_SC_PRIVATE_IP=10.105.10.76

export EUCA_OSP_HOST_NAME="odc-f-34"
export EUCA_OSP_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_OSP_PUBLIC_IP=10.104.10.76
export EUCA_OSP_PRIVATE_IP=10.105.10.76

export EUCA_NC1_HOST_NAME="odc-f-34"
export EUCA_NC1_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_NC1_PUBLIC_IP=10.104.10.76
export EUCA_NC1_PRIVATE_IP=10.105.10.76

export EUCA_DNS_HOST_NAME="odc-f-21"
export EUCA_DNS_DOMAIN_NAME="prc.eucalyptus-systems.com"
export EUCA_DNS_PUBLIC_IP=10.104.10.63
export EUCA_DNS_PRIVATE_IP=10.105.10.63
export EUCA_DNS_BASE_DOMAIN="mjcfc.cs.prc.eucalyptus-systems.com"
export EUCA_DNS_LOADBALANCER_SUBDOMAIN="lb"
export EUCA_DNS_INSTANCE_SUBDOMAIN=".cloud"

env | sort | grep ^EUCA_

Continuing in  0 seconds...

# export EUCA_VNET_MODE="EDGE"
# export EUCA_VNET_PRIVINTERFACE="em1"
# export EUCA_VNET_PUBINTERFACE="em2"
# export EUCA_VNET_BRIDGE="br0"
# export EUCA_VNET_PUBLICIPS="10.104.46.1-10.104.46.126"
# export EUCA_VNET_SUBNET="172.46.0.0"
# export EUCA_VNET_NETMASK="255.255.128.0"
# export EUCA_VNET_ADDRSPERNET="32"
# export EUCA_VNET_DNS="8.8.8.8"
#
# export EUCA_CLC_HOST_NAME="odc-f-34"
# export EUCA_CLC_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_CLC_PUBLIC_IP=10.104.10.76
# export EUCA_CLC_PRIVATE_IP=10.105.10.76
#
# export EUCA_UFS_HOST_NAME="odc-f-34"
# export EUCA_UFS_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_UFS_PUBLIC_IP=10.104.10.76
# export EUCA_UFS_PRIVATE_IP=10.105.10.76
#
# export EUCA_MC_HOST_NAME="odc-f-34"
# export EUCA_MC_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_MC_PUBLIC_IP=10.104.10.76
# export EUCA_MC_PRIVATE_IP=10.105.10.76
#
# export EUCA_CC_HOST_NAME="odc-f-34"
# export EUCA_CC_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_CC_PUBLIC_IP=10.104.10.76
# export EUCA_CC_PRIVATE_IP=10.105.10.76
#
# export EUCA_SC_HOST_NAME="odc-f-34"
# export EUCA_SC_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_SC_PUBLIC_IP=10.104.10.76
# export EUCA_SC_PRIVATE_IP=10.105.10.76
#
# export EUCA_OSP_HOST_NAME="odc-f-34"
# export EUCA_OSP_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_OSP_PUBLIC_IP=10.104.10.76
# export EUCA_OSP_PRIVATE_IP=10.105.10.76
#
# export EUCA_NC1_HOST_NAME="odc-f-34"
# export EUCA_NC1_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_NC1_PUBLIC_IP=10.104.10.76
# export EUCA_NC1_PRIVATE_IP=10.105.10.76
#
# export EUCA_DNS_HOST_NAME="odc-f-21"
# export EUCA_DNS_DOMAIN_NAME="prc.eucalyptus-systems.com"
# export EUCA_DNS_PUBLIC_IP=10.104.10.63
# export EUCA_DNS_PRIVATE_IP=10.105.10.63
# export EUCA_DNS_BASE_DOMAIN="mjcfc.cs.prc.eucalyptus-systems.com"
# export EUCA_DNS_LOADBALANCER_SUBDOMAIN="lb"
# export EUCA_DNS_INSTANCE_SUBDOMAIN=".cloud"
#
# env | sort | grep ^EUCA_
EUCA_CC_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_CC_HOST_NAME=odc-f-34
EUCA_CC_PRIVATE_IP=10.105.10.76
EUCA_CC_PUBLIC_IP=10.104.10.76
EUCA_CLC_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_CLC_HOST_NAME=odc-f-34
EUCA_CLC_PRIVATE_IP=10.105.10.76
EUCA_CLC_PUBLIC_IP=10.104.10.76
EUCA_DNS_BASE_DOMAIN=mjcfc.cs.prc.eucalyptus-systems.com
EUCA_DNS_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_DNS_HOST_NAME=odc-f-21
EUCA_DNS_INSTANCE_SUBDOMAIN=.cloud
EUCA_DNS_LOADBALANCER_SUBDOMAIN=lb
EUCA_DNS_PRIVATE_IP=10.105.10.63
EUCA_DNS_PUBLIC_IP=10.104.10.63
EUCA_MC_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_MC_HOST_NAME=odc-f-34
EUCA_MC_PRIVATE_IP=10.105.10.76
EUCA_MC_PUBLIC_IP=10.104.10.76
EUCA_NC1_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_NC1_HOST_NAME=odc-f-34
EUCA_NC1_PRIVATE_IP=10.105.10.76
EUCA_NC1_PUBLIC_IP=10.104.10.76
EUCA_OSP_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_OSP_HOST_NAME=odc-f-34
EUCA_OSP_PRIVATE_IP=10.105.10.76
EUCA_OSP_PUBLIC_IP=10.104.10.76
EUCA_SC_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_SC_HOST_NAME=odc-f-34
EUCA_SC_PRIVATE_IP=10.105.10.76
EUCA_SC_PUBLIC_IP=10.104.10.76
EUCA_UFS_DOMAIN_NAME=prc.eucalyptus-systems.com
EUCA_UFS_HOST_NAME=odc-f-34
EUCA_UFS_PRIVATE_IP=10.105.10.76
EUCA_UFS_PUBLIC_IP=10.104.10.76
EUCA_VNET_ADDRSPERNET=32
EUCA_VNET_BRIDGE=br0
EUCA_VNET_DNS=8.8.8.8
EUCA_VNET_MODE=EDGE
EUCA_VNET_NETMASK=255.255.128.0
EUCA_VNET_PRIVINTERFACE=em1
EUCA_VNET_PUBINTERFACE=em2
EUCA_VNET_PUBLICIPS=10.104.46.1-10.104.46.126
EUCA_VNET_SUBNET=172.46.0.0

Continuing in  0 seconds...

Environment configured
