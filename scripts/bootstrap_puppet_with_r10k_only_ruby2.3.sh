#!/bin/bash
if [ `whoami` == "root" ]; then 
    echo "i am root...";
    sudo="";
else 
    echo "i am non-root.."; 
    sudo="sudo";
fi;

# Update our package manager...
$sudo yum update -y -q
# Install dependencies for RVM and Ruby...
$sudo yum -q -y install \
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
	sqlite-devel \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all \
	&& /bin/find /usr/share \
	    -type f \
	    -regextype posix-extended \
	    -regex '.*\.(jpg|png)$' \
	    -delete
	
# patch, libyaml-devel, glibc-headers, autoconf, gcc-c++, glibc-devel, patch, readline-devel, zlib-devel, libffi-devel, openssl-devel, automake, libtool, bison, sqlite-devel

# import signing key
$sudo gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

# Get and install RVM
$sudo curl -L https://get.rvm.io | bash -s stable

# Source rvm.sh so we have access to RVM in this shell
$sudo source /etc/profile.d/rvm.sh

# Install Ruby 1.8.7
#$sudo rvm install ruby-1.9
#$sudo rvm alias create default 1.9

$sudo rvm install ruby-2.3.2
$sudo rvm alias create default ruby-2.3.2

$sudo source /etc/profile.d/rvm.sh

# Update rubygems, and pull down facter and then puppet...
#$sudo rvm 2.3.2 do gem update --system --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install rubygems-update --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install json_pure -v1.8.3 --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install facter --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install puppet --silent --no-ri --no-rdoc -v3.8.7
$sudo rvm 2.3.2 do gem install libshadow --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install puppet-module --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install ruby-augeas --silent --no-ri --no-rdoc
$sudo rvm 2.3.2 do gem install syck --no-ri --silent --no-rdoc

# install r10k
$sudo rvm 2.3.2 do gem install --no-rdoc --no-ri r10k --silent

# Create necessary Puppet directories...
$sudo mkdir -p /etc/puppet /var/lib /var/log /var/run /etc/puppet/manifests /etc/puppet/modules /etc/puppet/hieradata

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

# path puppet src files
# T.B.D.

# create custom facts for facter
$sudo mkdir -p /etc/facter/facts.d

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

$sudo chmod 755 /etc/facter/facts.d/puppet_module_elasticsearch_version.rb

#$sudo yum -y erase gcc-c++ readline-devel zlib-devel libxml2-devel libyaml-devel libxslt-devel libffi-devel openssl-devel augeas-devel
