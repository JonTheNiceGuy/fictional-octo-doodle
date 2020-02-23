Vagrant.configure("2") do |config|
  config.vbguest.auto_update = false
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "public_network", 
    use_dhcp_assigned_default_route: true, 
    bridge: [
      "DisplayLink Network Adapter NCM"
    ]
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  config.vm.provision "shell", run: "always", inline: <<-EOF
    if ip route | grep default | grep enp0s3 >/dev/null
    then
      ip route delete default dev enp0s3
    fi
  EOF

  config.vm.define "k3svm-a" do |k3svm_a|
    k3svm_a.vm.hostname = "k3svm-a"
    k3svm_a.vm.provider "virtualbox" do |vb|
      vb.name = "k3svm-a"
      vb.memory = 4096
    end
    k3svm_a.vm.provision "shell", inline: <<-EOF
      if ip route | grep default | grep enp0s3 >/dev/null
      then
        ip route delete default dev enp0s3
      fi
      export pubip=$(ip route | grep default | grep enp0s8 | cut -d' ' -f9)
      if [ ! -e /etc/rancher/k3s/k3s.yaml ] ; then curl -sfL https://get.k3s.io | sh - ; fi
      until kubectl get nodes 2>/dev/null | grep k3svm-a | grep " Ready " 2>/dev/null >/dev/null ; do echo "Waiting to be ready" ; sleep 1 ; done
      kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
      kubectl taint node k3svm-a node-role.kubernetes.io/master=effect:NoSchedule
      kubectl get nodes
      echo '#!/bin/bash' > /vagrant/install_server.sh
      echo 'export KUBECONFIG=/vagrant/k3s.yaml' >> /vagrant/install_server.sh
      echo "curl -sfL https://get.k3s.io | K3S_URL=https://$pubip:6443 K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token) sh -" >> /vagrant/install_server.sh
      echo 'until kubectl get nodes 2>/dev/null | grep $(hostname) | grep " Ready " 2>/dev/null >/dev/null ; do echo "Waiting to be ready" ; sleep 1 ; done' >> /vagrant/install_server.sh
      echo 'kubectl label node $(hostname) node-role.kubernetes.io/node=' >> /vagrant/install_server.sh
      cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
      sed -i -e "s/127.0.0.1:6443/$pubip:6443/" /vagrant/k3s.yaml
    EOF
  end
  config.vm.define "k3svm-b" do |k3svm_b|
    k3svm_b.vm.hostname = "k3svm-b"
    k3svm_b.vm.provider "virtualbox" do |vb|
      vb.name = "k3svm-b"
    end
    k3svm_b.vm.provision "shell", inline: <<-EOF
      if [ ! -e /etc/rancher/node/password ] ; then bash /vagrant/install_server.sh ; fi
    EOF
  end
end