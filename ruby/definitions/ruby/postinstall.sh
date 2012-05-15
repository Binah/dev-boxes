#!/bin/env bash
# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vagrant_box_build_time

# Install Percona
# http://www.percona.com/doc/percona-server/5.5/installation/apt_repo.html
gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
gpg -a --export CD2EFD2A | sudo apt-key add -

echo deb http://repo.percona.com/apt lenny main >> /etc/apt/sources.list
echo deb-src http://repo.percona.com/apt lenny main >> /etc/apt/sources.list

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline-gplv2-dev
apt-get -y install curl libxml2-dev libxslt-dev sqlite3 libsqlite3.dev
apt-get -y install tmux
apt-get -y install vim
apt-get -y install git-core

# Automatic password
# http://stackoverflow.com/questions/9743828/installing-percona-mysql-unattended-on-ubuntu
echo percona-server-server-5.5 percona-server-server-5.5/root_password password $dbpass | debconf-set-selections
echo percona-server-server-5.5 percona-server-server-5.5/root_password_again password $dbpass | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
apt-get -y install percona-server-server-5.5

apt-get clean

# Setup sudo to allow no-password sudo for "admin"
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Install NFS client
apt-get -y install nfs-common

# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
tar xvzf ruby-1.9.2-p290.tar.gz
cd ruby-1.9.2-p290
./configure --prefix=/opt/ruby
make
make install
cd ..
rm -rf ruby-1.9.2-p290

# Install RubyGems 1.7.2
wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.11.tgz
tar xzf rubygems-1.8.11.tgz
cd rubygems-1.8.11
/opt/ruby/bin/ruby setup.rb
cd ..
rm -rf rubygems-1.8.11

# Installing chef & Puppet
/opt/ruby/bin/gem install chef --no-ri --no-rdoc
/opt/ruby/bin/gem install puppet --no-ri --no-rdoc

# Changes to user
su vagrant
cd $HOME

# Installing rbenv
curl -L https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
echo 'if [ -d $HOME/.rbenv ]; then' >> $HOME/.bash_profile
echo '    export PATH="$HOME/.rbenv/bin:$PATH"' >> $HOME/.bash_profile
echo '    eval "$(rbenv init -)"' >> $HOME/.bash_profile
echo '    chown -R vagrant $HOME/.rbenv'
echo 'fi'

#Installing ruby on rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
$HOME/.rbenv/bin/rbenv install 1.9.2-p290
$HOME/.rbenv/bin/rbenv global 1.9.2-p290
$HOME/.rbenv/bin/rbenv rehash

# Installing bundler
$HOME/.rbenv/shims/gem install bundler

# Installing cucumber & rspec
$HOME/.rbenv/shims/gem install cucumber
$HOME/.rbenv/shims/gem install rspec

# Installing rails
$HOME/.rbenv/shims/gem install rails

# Installin tmux config
cd /home/vagrant/
wget -c https://raw.github.com/Binah/dev-environment/master/tmux/.tmux.conf

# Installing vim config
cd /tmp
git clone https://github.com/Binah/dev-environment.git
cp -r /tmp/dev-environment/vim /home/vagrant/.vim
cd /home/vagrant/
wget -c https://raw.github.com/Binah/dev-environment/master/vim/.vimrc

# Add /opt/ruby/bin to the global path as the last resort so
# Ruby, RubyGems, and Chef/Puppet are visible
echo 'PATH=$PATH:/opt/ruby/bin/'> /etc/profile.d/vagrantruby.sh

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Remove items used for building, since they aren't needed anymore
apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get -y autoremove

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
exit
