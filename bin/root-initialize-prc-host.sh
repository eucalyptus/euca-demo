#/bin/bash
#
# This script initializes a PRC host to some of the conventions preferred
# by Michael Crawford, so these changes are standardized in one place
#
# Echo then run each command so user can follow progress and understand
# what's being done.
#
# I will run this on new PRC hosts prior to starting the course scripts.
# These should not change any behavior, but in case it does, this will
# record what was done.
#

step=0

# Verify we are logged on as root
if [ $(id -u) != 0 ]; then
    echo "You must be root to execute this script."
    exit 1
fi

((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure Sudo"
echo "    - This makes CentOS 6.x behave like CentOS 7.x"
echo "      - Members of wheel can sudo with a password"
echo
echo "============================================================"
echo
echo "# sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers"
sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Setup local aliases"
echo "    - alias lsa='ls -lAF'"
echo "    - alias ip4='ip addr | grep \" inet \"'"
echo
echo "============================================================"
echo
if [ ! -r /etc/profile.d/local.sh ]; then
    echo "# echo \"alias lsa='ls -lAF'\" > /etc/profile.d/local.sh"
    echo "alias lsa='ls -lAF'" > /etc/profile.d/local.sh
    echo "# echo \"alias ip4='ip addr | grep \" inet \"'\" > /etc/profile.d/local.sh"
    echo "alias ip4='ip addr | grep \" inet \"'" > /etc/profile.d/local.sh
    echo "# source /etc/profile.d/local.sh"
    source /etc/profile.d/local.sh
fi
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Configure root user"
echo "    - Identify mail sent by root as the hostname"
echo "    - Create ~/bin, ~/doc, ~/log and ~/.ssh directories"
echo "    - Populate ssh host keys for github.com and bitbucket.org"
echo "    - Create ~/.gitconfig"
echo
echo "============================================================"
echo
echo "# sed -i -e \"1 s/root:x:0:0:root/root:x:0:0:$(hostname -s)/\" /etc/passwd"
sed -i -e "1 s/root:x:0:0:root/root:x:0:0:$(hostname -s)/" /etc/passwd
sleep 1

echo "#"
echo "# mkdir -p ~/{bin,doc,log,.ssh}"
mkdir -p ~/{bin,doc,log,.ssh}
echo "# chmod og-rwx ~/{bin,log,.ssh}"
chmod og-rwx ~/{bin,log,.ssh}
sleep 1

if ! grep -s -q "^github.com" /root/.ssh/known_hosts; then
    echo "#"
    echo "# ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts"
    ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts
fi
if ! grep -s -q "^bitbucket.org" /root/.ssh/known_hosts; then
    echo "#"
    echo "# ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts"
    ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts
fi
sleep 1


if [ ! -r /root/.gitconfig ]; then
    echo "#"
    echo "# cat << EOF > /root/.gitconfig"
    echo "> [user]"
    echo ">         name = Administrator"
    echo ">         email = admin@eucalyptus.com"
    echo "> EOF"
    tab="$(printf '\t')"
    cat << EOF > /root/.gitconfig
[user]
${tab}name = Administrator
${tab}email = admin@eucalyptus.com
EOF
fi
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Install git"
echo
echo "============================================================"
echo
if ! rpm -q --quiet git; then
    echo "# yum install -y git"
    yum install -y git
fi
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Install w3m"
echo
echo "============================================================"
echo
if ! rpm -q --quiet w3m; then
    echo "# yum install -y w3m"
    yum install -y w3m
fi
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Clone euca-demo git project"
echo
echo "============================================================"
echo
if [ ! -r /root/src/eucalyptus/euca-demo/README.md ]; then
    echo "# mkdir -p /root/src/eucalyptus"
    mkdir -p /root/src/eucalyptus
    echo "# cd /root/src/eucalyptus"
    cd /root/src/eucalyptus
    echo "#"
    echo "# git clone https://github.com/eucalyptus/euca-demo.git"
    git clone https://github.com/eucalyptus/euca-demo.git
fi
sleep 1


((++step))
echo
echo "============================================================"
echo
echo " $(printf '%2d' $step). Add euca-demo scripts to PATH"
echo
echo "============================================================"
echo
if ! grep -s -q "^PATH=.*eucalyptus/euca-demo/bin" /root/.bash_profile; then
    echo "# sed -i -e '/^PATH=/s/$/:\\\$HOME\/src\/eucalyptus\/euca-demo\/bin/' /root/.bash_profile"
    sed -i -e '/^PATH=/s/$/:\$HOME\/src\/eucalyptus\/euca-demo\/bin/' /root/.bash_profile
fi
if ! grep -s -q "Source Eucalyptus Administrator credentials" /root/.bash_profile; then
    echo "#"
    echo "# echo >> /root/.bash_profile"
    echo >> /root/.bash_profile
    echo "# echo \"# Source Eucalyptus Administrator credentials if they exist\" >> /root/.bash_profile"
    echo "# Source Eucalyptus Administrator credentials if they exist" >> /root/.bash_profile
    echo "# echo \"[ -r \$HOME/creds/eucalyptus/admin/eucarc ] && source \$HOME/creds/eucalyptus/admin/eucarc\" >> /root/.bash_profile"
    echo "[ -r \$HOME/creds/eucalyptus/admin/eucarc ] && source \$HOME/creds/eucalyptus/admin/eucarc" >> /root/.bash_profile
fi
echo
echo "Please logout, then login to pick up profile changes"
sleep 1

echo
echo "Root PRC modifications complete"
