#!/bin/bash

# Update our package manager...
yum update -y -q --exclude=util-linux-ng --exclude=libblkid --exclude=libuuid
# Install dependencies for RVM and Ruby...
rpm --rebuilddb \
  && yum -q -y install \
	gcc-c++ \
	patch \
	readline-devel \
	zlib-devel \
	libxml2-devel \
	libyaml-devel \
	libxslt-devel \
	libffi-devel \
	openssl-devel \
	autoconf \
	automake \
	libtool \
	bison \
	git \
	augeas-devel \
	sqlite-devel
#	 \
#	&& rm -rf /var/cache/yum/* \
#	&& yum clean all \
#	&& /bin/find /usr/share \
#	    -type f \
#	    -regextype posix-extended \
#	    -regex '.*\.(jpg|png)$' \
#	    -delete

# import signing key
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

# Get and install RVM
curl -L https://get.rvm.io | bash -s stable

# Source rvm.sh so we have access to RVM in this shell
source /etc/profile.d/rvm.sh

rvm install ruby-2.3.2
rvm alias create default ruby-2.3.2

source /etc/profile.d/rvm.sh

# Update rubygems, and pull down facter and then puppet...
rvm 2.3.2 do gem update --system --no-ri --no-rdoc 1>/dev/null
rvm 2.3.2 do gem install json_pure -v1.8.3 --silent --no-ri --no-rdoc
rvm 2.3.2 do gem install facter --silent --no-ri --no-rdoc
rvm 2.3.2 do gem install puppet --silent --no-ri --no-rdoc -v3.8.7
rvm 2.3.2 do gem install libshadow --silent --no-ri --no-rdoc
rvm 2.3.2 do gem install puppet-module --silent --no-ri --no-rdoc
rvm 2.3.2 do gem install ruby-augeas --silent --no-ri --no-rdoc
rvm 2.3.2 do gem install syck --no-ri --silent --no-rdoc

# install r10k
rvm 2.3.2 do gem install --no-rdoc --no-ri r10k --silent

# Create necessary Puppet directories...
mkdir -p /etc/puppet /var/lib /var/log /var/run /etc/puppet/manifests /etc/puppet/modules /etc/puppet/hieradata

# create hiera config
cat <<EOF > /etc/puppet/hiera.yaml
---
:backends:
  - yaml
:yaml:
  :datadir: /etc/puppet/hieradata
:hierarchy:
  - "node--%{::fqdn}"

EOF

# create custom facts for facter
mkdir -p /etc/facter/facts.d

cat <<EOF2 > /etc/facter/facts.d/puppet_module_elasticsearch_version.rb
#!/bin/env ruby

version = \`puppet module list |grep elasticsearch-elasticsearch |awk '{print \$(NF)}'\`

if version.empty? || version.nil?
    result = 'unknown' + "\n"
else
    result = version
end

print "puppet_module_elasticsearch_version=" + result
EOF2

chmod 755 /etc/facter/facts.d/puppet_module_elasticsearch_version.rb
