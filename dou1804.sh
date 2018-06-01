#!/bin/bash
#
# Digitalocean Ubuntu 18.04 server setup
#
#Update OS
apt-get update && apt-get upgrade -y
#
#Set timezone
echo "America/Chicago" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
#
#Memory Management
echo "vm.swappiness=1" > /etc/sysctl.d/99-swappiness.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.overcommit_memory = 1" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.dirty_background_ratio = 5" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.dirty_ratio = 10" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.dirty_expire_centisecs = 1000" >> /etc/sysctl.d/99-swappiness.conf
echo "dev.rtc.max-user-freq = 1024" >> /etc/sysctl.d/99-swappiness.conf
echo "vm.laptop_mode = 0" >> /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf
#
#Enable unattended security upgrades
echo 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
sed -i '/^\/\/.*-updates.*/s/^\/\//  /g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i '/^\/\/.*-backports.*/s/^\/\//  /g' /etc/apt/apt.conf.d/50unattended-upgrades
#
#Set update schedule
rm /etc/apt/apt.conf.d/10periodic
cat <<EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
chmod 644 /etc/apt/apt.conf.d/10periodic
#
#Pull configuration files
mkdir /root/git
cd /root/git
git clone git@github.com:djinnsour/install.git
#
#Setup user
sudo adduser bw --gecos "B W,108,108,108" --disabled-password
mkdir /home/bw/.ssh
touch /home/bw/.ssh/authorized_keys
cat /root/git/bw.pub >> authorized_keys
chown bw:bw -R /home/bw/
chmod 700 /home/bw/.ssh
#
#Apply various Server config files
cp /root/git/sshd_config /etc/ssh/sshd_config
cp /root/git/jail.local /etc/fail2ban/jail.local
cp /root/git/bw /etc/sudoers.d/bw
cp /root/git/ssh_banner.sh /etc/ssh_banner.sh
chmod +x /etc/ssh_banner.sh
echo "/etc/ssh_banner.sh" >> /etc/profile
sed -i 's/HISTSIZE=1000/HISTSIZE=200000/' /home/bw/.bashrc
sed -i 's/HISTSIZE=1000/HISTSIZE=200000/' /root/.bashrc
#The following is specific to the digitalocean ubuntu virtual machines
sed -i 's/ext4\tdefaults/ext4\tdefaults,noatime/g' /etc/fstab
#
#Finish up and reboot
echo y | apt-get install -f -y 
echo y | apt-get autoremove 
echo y | apt-get clean 
update-grub
reboot
