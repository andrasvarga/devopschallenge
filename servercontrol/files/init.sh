#!/bin/bash
set -e -x
export DEBIAN_FRONTEND=noninteractive
DOMAIN="eu-central-1.compute.internal"
USER_DATA=$(/usr/bin/curl -s http://169.254.169.254/latest/user-data)
HOSTNAME=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-hostname)
IPV4=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
# Set the host name
hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname
# Add fqdn to hosts file
cat<<EOF > /etc/hosts
127.0.0.1 $HOSTNAME localhost localhost.localdomain

172.31.32.5 master.eu-central-1.compute.internal puppet
$IPV4 $HOSTNAME

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF
# Install Puppet
apt-get update && apt-get -y upgrade && wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && dpkg -i puppetlabs-release-trusty.deb && apt-get update && apt-get -y install puppet && puppet help | tail -n 1
# File: Lock Puppet version
cat<<EOF > /etc/apt/preferences.d/00-puppet.pref
# /etc/apt/preferences.d/00-puppet.pref
Package: puppet puppet-common
Pin: version 3.8.7
Pin-Priority: 501
EOF
# File: Enable Puppet Agent
cat<<EOF > /etc/default/puppet
# Defaults for puppet - sourced by /etc/init.d/puppet

# Enable puppet agent service?
# Setting this to "yes" allows the puppet agent service to run.
# Setting this to "no" keeps the puppet agent service from running.
START=yes

# Startup options
DAEMON_OPTS=""
EOF
# File: Deleting unnecessary lines from config - master server name is puppet by default
cat<<EOF > /etc/puppet/puppet.conf
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
EOF
# File: auto-retrieve configuration on reboot
mkdir /usr/local/ec2
cat<<EOF > /usr/local/ec2/ec2-puppet.sh
#!/bin/bash
set -e -x
export DEBIAN_FRONTEND=noninteractive
# Turning on swap for composer
/sbin/swapon /var/swap.1
# Make sure agent is running and check out the configuration
puppet agent --test
EOF
chmod o+x /usr/local/ec2/ec2-puppet.sh
echo $'\n' >> /etc/rc.local
echo "/usr/local/ec2/ec2-puppet.sh" >> /etc/rc.local
# Setting up swap for composer
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024 && /sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1
# reboot
reboot
