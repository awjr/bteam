#! /bin/bash

#this is a custom script to do an initial Debian server OS hardening
#By: @syd_thedon


# 1 Banner setting
chown root:root /etc/motd
chmod 644 /etc/motd 
echo "Authorized users only. All activity is monitored and reported." > /etc/motd 
chown root:root /etc/issue 
chmod 644 /etc/issue 
echo "Authorized users only. All activity is monitored and reported." > /etc/issue 
chown root:root /etc/issue.net
chmod 644 /etc/issue.net
echo "Authorized users only. All activity is monitored and reported." > /etc/issue.net

# 2 Disable X11 forwarding. By running an X11 program (known as a server) on your computer, 
# you can access graphical Linux programs remotely through an SSH client
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 
sed -i "s/^X11Forwarding.*yes/X11Forwarding no/" /etc/ssh/sshd_config

# 3 Set default user shell timeout to 800 seconds
cp /etc/bash.bashrc /etc/bash.bashrc.bak
cp /etc/profile /etc/profile.bak 

tmoutbsh=$(grep -cP '^TMOUT=800' /etc/bash.bashrc)
if [ $tmoutbsh -eq 0 ];
then 
    printf '\n%s\n' 'TMOUT=800' >> /etc/bash.bashrc
fi

tmoutprofile=$(grep -cP '^TMOUT=800' /etc/profile)
if [ $tmoutprofile -eq 0 ];
then 
    printf '\n%s\n' 'TMOUT=800' >> /etc/profile
fi

# 4 Secure SHELL, Disable root login, allow specific users, change port
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
sed -i "s/#Port 22/Port 55000/g" /etc/ssh/sshd_config
#set max authentication tries to 3
sed -i "s/#MaxAuthTries 6/MaxAuthTries 3/g" /etc/ssh/sshd_config
#disable root login
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "/PermitEmptyPasswords.*no/s/^#//g" /etc/ssh/sshd_config
service sshd restart

# 5 Enable iptables
apt -y install iptables 
apt -y install iptables-persistent
systemctl enable netfilter-persistent
#flush firewall rules
iptables -F #deletes all
iptables -X #deletes all non default chains
iptables -Z
iptables -A INPUT -i lo -j ACCEPT 
#Accpet ssh access
iptables -A INPUT -p tcp -m tcp --dport 55000 -j ACCEPT 
#Allow outgoing connections
iptables -P OUTPUT ACCEPT 
# Default deny firewall policy
iptables -P FORWARD DROP 
#Save
iptables-save > /etc/iptables/rules.v1
iptables-apply -t 40 /etc/iptables/rules.v1


# 6 Turn on selinux
# SELinux is a security enhancement to Linux which allows users and administrators more control over access control.
#Access can be constrained on such variables as which users and applications can access which resources.
apt install selinux
setenforce enforcing
init 6




