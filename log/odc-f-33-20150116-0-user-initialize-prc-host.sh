[root@odc-f-33 ~]# mkdir ~/bin
cd ~/bin
wget https://raw.githubusercontent.com/eucalyptus/euca-demo/master/bin/user-initialize-prc-host.sh
chmod -R 0700 ~/bin
./user-initialize-prc-host.sh[root@odc-f-33 ~]# cd ~/bin
[root@odc-f-33 bin]# wget https://raw.githubusercontent.com/eucalyptus/euca-demo/master/bin/user-initialize-prc-host.sh
--2015-01-16 00:18:25--  https://raw.githubusercontent.com/eucalyptus/euca-demo/master/bin/user-initialize-prc-host.sh
Resolving raw.githubusercontent.com... 23.235.47.133
Connecting to raw.githubusercontent.com|23.235.47.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3286 (3.2K) [text/plain]
Saving to: “user-initialize-prc-host.sh”

100%[==============================================================================================================================================>] 3,286       --.-K/s   in 0s      

2015-01-16 00:18:25 (85.2 MB/s) - “user-initialize-prc-host.sh” saved [3286/3286]

[root@odc-f-33 bin]# chmod -R 0700 ~/bin
[root@odc-f-33 bin]# ./user-initialize-prc-host.sh

 1. Configure Sudo
    - This makes CentOS 6.x behave like CentOS 7.x
      - Members of wheel can sudo with a password

# sed -i -e '/^# %wheel\tALL=(ALL)\tALL/s/^# //' /etc/sudoers


 2. Setup local aliases
    - alias lsa='ls -lAF'

# echo "alias lsa='ls -lAF'" > /etc/profile.d/local.sh
source /etc/profile.d/local.sh


 3. Configure root user
    - Identify mail sent by root as the hostname
    - Create ~/bin, ~/doc, ~/log and ~/.ssh directories
    - Populate ssh host keys for github.com and bitbucket.org
    - Create ~/.gitconfig

# sed -i -e "1 s/root:x:0:0:root/root:x:0:0:odc-f-33/" /etc/passwd

# mkdir -p ~/{bin,doc,log,.ssh}
# chmod og-rwx ~/{bin,log,.ssh}

# ssh-keyscan github.com 2> /dev/null >> /root/.ssh/known_hosts

# ssh-keyscan bitbucket.org 2> /dev/null >> /root/.ssh/known_hosts

# cat << EOF > /root/.gitconfig
> [user]
>         name = Administrator
>         email = admin@eucalyptus.com
> EOF


 4. Download euca-demo git project

yum install -y git
Loaded plugins: fastestmirror, security
Setting up Install Process
Loading mirror speeds from cached hostfile
 * extras: mirrors.sonic.net
Resolving Dependencies
--> Running transaction check
---> Package git.x86_64 0:1.7.1-3.el6_4.1 will be installed
--> Processing Dependency: perl-Git = 1.7.1-3.el6_4.1 for package: git-1.7.1-3.el6_4.1.x86_64
--> Processing Dependency: perl(Git) for package: git-1.7.1-3.el6_4.1.x86_64
--> Processing Dependency: perl(Error) for package: git-1.7.1-3.el6_4.1.x86_64
--> Running transaction check
---> Package perl-Error.noarch 1:0.17015-4.el6 will be installed
---> Package perl-Git.noarch 0:1.7.1-3.el6_4.1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

========================================================================================================================================================================================
 Package                                   Arch                                  Version                                        Repository                                         Size
========================================================================================================================================================================================
Installing:
 git                                       x86_64                                1.7.1-3.el6_4.1                                centos-6-x86_64-os                                4.6 M
Installing for dependencies:
 perl-Error                                noarch                                1:0.17015-4.el6                                centos-6-x86_64-os                                 29 k
 perl-Git                                  noarch                                1.7.1-3.el6_4.1                                centos-6-x86_64-os                                 28 k

Transaction Summary
========================================================================================================================================================================================
Install       3 Package(s)

Total download size: 4.7 M
Installed size: 15 M
Downloading Packages:
(1/3): git-1.7.1-3.el6_4.1.x86_64.rpm                                                                                                                            | 4.6 MB     00:00     
(2/3): perl-Error-0.17015-4.el6.noarch.rpm                                                                                                                       |  29 kB     00:00     
(3/3): perl-Git-1.7.1-3.el6_4.1.noarch.rpm                                                                                                                       |  28 kB     00:00     
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                    28 MB/s | 4.7 MB     00:00     
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing : 1:perl-Error-0.17015-4.el6.noarch                                                                                                                                    1/3 
  Installing : perl-Git-1.7.1-3.el6_4.1.noarch                                                                                                                                      2/3 
  Installing : git-1.7.1-3.el6_4.1.x86_64                                                                                                                                           3/3 
  Verifying  : git-1.7.1-3.el6_4.1.x86_64                                                                                                                                           1/3 
  Verifying  : perl-Git-1.7.1-3.el6_4.1.noarch                                                                                                                                      2/3 
  Verifying  : 1:perl-Error-0.17015-4.el6.noarch                                                                                                                                    3/3 

Installed:
  git.x86_64 0:1.7.1-3.el6_4.1                                                                                                                                                          

Dependency Installed:
  perl-Error.noarch 1:0.17015-4.el6                                                          perl-Git.noarch 0:1.7.1-3.el6_4.1                                                         

Complete!

# mkdir -p ~/src/eucalyptus
# cd ~/src/eucalyptus
# git clone https://github.com/eucalyptus/euca-demo.git
Initialized empty Git repository in /root/src/eucalyptus/euca-demo/.git/
remote: Counting objects: 215, done.
remote: Compressing objects: 100% (169/169), done.
remote: Total 215 (delta 163), reused 89 (delta 39)
Receiving objects: 100% (215/215), 70.23 KiB, done.
Resolving deltas: 100% (163/163), done.

# sed -i -e '/^PATH=/s/$/:\$HOME\/src\/eucalyptus\/euca-demo\/bin/' /root/.bash_profile

# echo >> /root/.bash_profile
# echo "# Source Eucalyptus Administrator credentials if they exist" >> /root/.bash_profile
# echo "[ -r ~/creds/eucalyptus/admin/eucarc ] && source ~/creds/eucalyptus/admin/eucarc" >> /root/.bash_profile

Please logout, then login to pick up profile changes

User PRC modifications complete
[root@odc-f-33 bin]# exit
logout

Last login: Fri Jan 16 00:20:34 2015 from euca-vpn-10-5-1-94.eucalyptus-systems.com
