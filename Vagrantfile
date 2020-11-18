# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8096"
  end

  config.vm.network "forwarded_port", guest: 8000, host: 8000 # cube
  config.vm.network "forwarded_port", guest: 8010, host: 8010 # store
  config.vm.network "forwarded_port", guest: 5005, host: 5005 # pfcon
  config.vm.network "forwarded_port", guest: 5010, host: 5010 # pman
  config.vm.network "forwarded_port", guest: 5055, host: 5055 # pfioh

  config.vm.provision "shell", inline: <<-SHELL
    wget -qO /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)"
    chmod +x /usr/local/bin/docker-compose
    wget -qO /tmp/get-docker.sh https://get.docker.com
    sh /tmp/get-docker.sh > /dev/null 2>&1
    systemctl enable --now docker
  SHELL
  
  config.vm.provision "shell", run: "always", inline: "cd /vagrant && ./minimake.sh"
end
