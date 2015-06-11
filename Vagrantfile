# -*- mode: ruby -*-
# vi: set ft=ruby :

# Get Mac to forward port 80 to 8080 http://salferrarello.com/mac-pfctl-port-forwarding/

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.box = "hashicorp/precise64"
    #config.vm.box = "ffuenf/debian-6.0.9-amd64"

    config.vm.network :private_network,
        ip: "10.20.30.60"

  	config.vm.network "forwarded_port",
  		guest: 80,
  		host: 8080

    config.vm.synced_folder "../", "/opt/dev",
        :nfs => true,
        :create => true

    config.vm.provider :virtualbox do |vb|
        vb.memory = 2048
    end

    #config.vm.provision :puppet do |puppet|
    #    puppet.manifests_path = "puppet/manifests"
    #    puppet.module_path = "puppet/modules"
    #end

    config.vm.provision :shell,
        :keep_color => true,
        :path => "provision.sh",
        :privileged => false

    config.trigger.after [:up, :reload, :provision], :stdout => true do

		system('echo "
			rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 8080
			rdr pass inet proto tcp from any to any port 443 -> 127.0.0.1 port 8443
			" | sudo pfctl -ef - >/dev/null 2>&1; echo "Add Port Forwarding (80 => 8080)\nAdd Port Forwarding (443 => 8443)"')
		
	end

end
