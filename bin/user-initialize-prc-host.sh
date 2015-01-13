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

echo
echo " 1. Configure Sudo"
echo "    - This makes CentOS 6.x behave like CentOS 7.x"
echo "      - Members of wheel can sudo with a password"
echo
echo "# sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers"
sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers
sleep 1

echo
echo
echo " 2. Setup local aliases"
echo "    - alias lsa='ls -lAF'"
echo
echo "# echo \"alias lsa='ls -lAF'\" > /etc/profile.d/local.sh"
echo "alias lsa='ls -lAF'" > /etc/profile.d/local.sh
echo "source /etc/profile.d/local.sh"
source /etc/profile.d/local.sh
sleep 1

echo
echo
echo " 3. Configure root user"
echo "    - Identify mail sent by root as the hostname"
echo "    - Create ~/bin, ~/doc, ~/log and ~/.ssh directories"
echo "    - Populate ssh host keys for github.com and bitbucket.org"
echo "    - Create ~/.gitconfig"
echo
echo "# sed -i -e \"1 s/root:x:0:0:root/root:x:0:0:$(hostname -s)/\" /etc/passwd"
sed -i -e "1 s/root:x:0:0:root/root:x:0:0:$(hostname -s)/" /etc/passwd
sleep 1

echo
echo "# mkdir -p ~/{bin,doc,log,.ssh}"
mkdir -p ~/{bin,doc,log,.ssh}
echo "# chmod og-rwx ~/{bin,log,.ssh}"
chmod og-rwx ~/{bin,log,.ssh}
sleep 1

echo
echo "# ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts"
ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts
echo
echo "# ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts"
ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts
sleep 1

echo 
echo "# cat << EOF > /root/.gitconfig"
echo "> [user]"
echo ">         name = Administrator"
echo ">         email = admin@eucalyptus.com"
echo "> EOF"
cat << EOF > /root/.gitconfig
[user]
        name = Administrator
        email = admin@eucalyptus.com
EOF
sleep 1

echo
echo
echo " 4. Download euca-demo git project"
echo
echo "yum install -y git"
yum install -y git
sleep 1

echo
echo "# mkdir -p ~/src/eucalyptus"
mkdir -p ~/src/eucalyptus
echo "# cd ~/src/eucalyptus"
cd ~/src/eucalyptus
echo "# git clone https://github.com/eucalyptus/euca-demo.git"
git clone https://github.com/eucalyptus/euca-demo.git
sleep 1

echo
echo "# sed -i -e '/^PATH=/s/$/:\\\$HOME\/src\/eucalyptus\/euca-demo\/bin/' /root/.bash_profile"
sed -i -e '/^PATH=/s/$/:\$HOME\/src\/eucalyptus\/euca-demo\/bin/' /root/.bash_profile
echo
echo "# echo >> /root/.bash_profile"
echo >> /root/.bash_profile
echo "# echo \"# Source Eucalyptus Administrator credentials if they exist\" >> /root/.bash_profile"
echo "# Source Eucalyptus Administrator credentials if they exist" >> /root/.bash_profile
echo "# echo \"[ -r ~/creds/eucalyptus/admin/eucarc ] && source ~/creds/eucalyptus/admin/eucarc\" >> /root/.bash_profile"
echo "[ -r ~/creds/eucalyptus/admin/eucarc ] && source ~/creds/eucalyptus/admin/eucarc" >> /root/.bash_profile
echo
echo "Please logout, then login to pick up profile changes"
sleep 1

echo
echo "User PRC modifications complete"
