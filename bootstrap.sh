#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   exec sudo $0
fi

if [ ! -f .apt ]; then
	apt-get update
	apt-get install -y build-essential wget ca-certificates git
	touch .apt
fi

git config --global user.name "`whoami`"
git config --global user.email "`whoami`@`hostname`"

if [ ! -f /tmp/chefdk.deb ]; then
	wget -O /tmp/chefdk.deb 'https://packages.chef.io/files/stable/chefdk/2.5.3/debian/8/chefdk_2.5.3-1_amd64.deb'
	dpkg -i /tmp/chefdk.deb
fi

chef_dir=/var/chef

# /bin/rm -rf $chef_dir

test -d ~/.chef || mkdir ~/.chef
test -f ~/.chef/knife.rb || touch ~/.chef/knife.rb

test -d /etc/chef || mkdir /etc/chef
test -f /etc/chef/client.rb || touch /etc/chef/client.rb
cat > /etc/chef/solo.rb <<EOH
cookbook_path [ "/var/chef/cookbooks", "/var/chef/site-cookbooks" ]
solo true
verbose_logging true
EOH
cat > /etc/chef/solo.json <<EOH
{
  "run_list": [ "role[unixlab]" ]
}
EOH

test -d $chef_dir || mkdir $chef_dir
for dir in checksums cookbooks site-cookbooks data_bags environmetns backup cache roles; do
	test -d "$chef_dir/$dir" || mkdir "$chef_dir/$dir"
done
test -d $chef_dir/cookbooks/.git || (cd $chef_dir/cookbooks ; git init ; git commit --allow-empty -m "Initial commit" )
test -d $chef_dir/site-cookbooks/.git || (cd $chef_dir/site-cookbooks ; git init ; git commit --allow-empty -m "Initial commit" )

for cookbook in chef_hostname apt apt-upgrade-once build-essential java
do
	test -d "$chef_dir/cookbooks/$cookbook" || knife cookbook site install "$cookbook"
done


for cookbook in up-common up-docker up-java up-vscode
do
	test -d "$chef_dir/site-cookbooks/$cookbook" || ( cd "$chef_dir/site-cookbooks" ; chef generate cookbook -b "$cookbook" )
done


test -f "$chef_dir/roles/unixlab.rb" || cat > "$chef_dir/roles/unixlab.rb" <<EOH
name 'unixlab'
run_list []
EOH


# ######################################################################
# up-common
# ######################################################################

cat > "$chef_dir/site-cookbooks/up-common/INSTRUCTIONS.txt" <<EOH

In this exercise you will learn:
	How to make a large recipe by including smaller ones
	How to use the "package" resource to install OS packages
	How to use the "user" and "group" resources to create users and groups.

Test your changes using the following chef command:

	chef-solo -o "recipe[up-common]"

Part 1: Include the following chef recipies into the up-common recipe:

	apt
	apt-upgrade-once
	build-essential

Part 2: Install the following packages:

	open-vm-tools

Part 3: Create a user "cs376" and group "cs376"

	Use the chef "group" resource to create the "cs376" group.

	Use the chef "user" resource
	The user's password should be set to "cs376".
	You should create the user's home directory.
	The default group for the user should be "cs376" (created above)

EOH



# ######################################################################
# up-java
# ######################################################################

cat > "$chef_dir/site-cookbooks/up-java/INSTRUCTIONS.txt" <<EOH

In this cookbook you will write a recipe to install Oracle Java
by creating a wrapper cookbook.

In this exercise you will learn:
	How to create a wrapper cookbook that overrides attributes
	specified in the wrapped cookbook.

Test your changes using the following chef command:

	chef-solo -o "recipe[up-java]"

Part 1:

	Create an attributes file with the following contents:

	default['java']['jdk_version'] = '8'
	default['java']['install_flavor'] = 'oracle'
	default['java']['oracle']['accept_oracle_download_terms'] = true

Part 2:

	Declare a dependency on the "java" cookbook in metadata.rb

Part 3:

	Use the "include_recipe" resource to execute the "java" recipe.
EOH

# ######################################################################
# up-vscode
# ######################################################################

cat > "$chef_dir/site-cookbooks/up-vscode/INSTRUCTIONS.txt" <<EOH

In this cookbook you will write a recipe to install Visual Studio code.

In this exercise you will learn:
	How to use the "remote_file" resource.
	How to use an OS-specific packaging resource.

Test your changes using the following chef command:

	chef-solo -o "recipe[up-vscode]"

Part 1:

	Use the "remote_file" resource to download the latest Visual Studio Code installer.
	Save the .deb file to "#{Chef::Config[:file_cache_path]}/vscode.deb"

Part 2:

	Use the "dpkg_package" resource to install the downloaded .deb file.

Part 3:

	If installation is unsuccessful, use the "package" resource to install missing dependencies.

EOH


# ######################################################################
# up-docker
# ######################################################################

cat > "$chef_dir/site-cookbooks/up-docker/INSTRUCTIONS.txt" <<EOH

In this cookbook you will write a recipe to install Docker Community Edition
using the package repository method.

In this exercise you will learn:
	How to use the "execute" resource.
	How to use the "apt_repository" resource.
	How to use the "systemd_unit" resource.
	How to use an only_if or not_if idempotency guard.

You will replicate the steps documented at
https://docs.docker.com/install/linux/docker-ce/debian/#install-using-the-repository

Test your changes using the following chef command:

	chef-solo -o "recipe[up-docker]"

Part 1:

	Install the "package"s required in the "Jessie or newer" section.

	Use the "execute" resource to install the repository's GPG key.

	Use the "apt_repository" resource to add the docker repository.

	Install the "docker-ce" package.

	Use the "systemd_unit" service to ensure that "docker.service"
	is enabled and started.

Part 2:

	Install the "python" and "python-pip" pakcages.
	Upgrade pip by executing "pip install --upgrade pip"
	Install docker-compose using the "pip install" command,
	but only if /usr/local/bin/docker-compose does not already exist.

EOH


# ######################################################################
# unixlab role
# ######################################################################

cat > /dev/null <<EOH
In this cookbook you will write a Chef role to contain all of
the cookbooks you previously declared.

Test your changes using the following chef command:

	chef-solo -j /etc/chef/solo.json

Instructions:

	Create /var/chef/roles/unixlab.rb with the following contents:

	name 'unixlab'
	run_list 'recipe[up-common]', 'recipe[up-java]', 'recipe[up-vscode]', 'recipe[up-docker]'
EOH
