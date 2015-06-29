local mirrors
=============

This is an area I'm experimenting with, to see how much I can speed up PRC installations by
using local yum repository and download locations. This technique should also eventually
work to allow for faster installs at many other locations around the world, both internal
and external to HP.

For this initial experiment, by passing a "-l" (local) flag to some commands, the normal
external URL which might reference downloads.eucalyptus.com or mirror.eucalyptus.com is
replaced with a local mirror I've created on mirror.mjc.prc.eucalyptus-systems.com. 
Or, the mirrorlist refernce in our release RPMs is changed from 
"mirrors.eucalyptus.com/mirrors" to "mirrorlist.mjc.prc.eucalyptus-systems.com/"
which when taking the same query string parameters returns both the external and internal
repositories, which should allow yum's fastest mirror plugin to select the internal 
mirror when doing installs in the PRC.

See the odc-f-38 server which serves the mirror.mjc.prc.eucalyptus-systems.com and 
mirrorlist.mjc.prc.eucalyptus-systems.com websites for more details, but the mirrorlist
logic is very simple SSI in this file: 
odc-f-38:/var/www/mirrorlist.eucalyptus-systems.com/html/mirrorlist.shtml
and it should be trivial to add new yum repo locations over time.
