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
    vb.linked_clone = true
  end
  config.vm.provision "shell", run: "always", inline: <<-EOF
    echo "PROVISION NOTICE: Removing NAT-interface default route"
    if ip route | grep default | grep enp0s3 >/dev/null
    then
      ip route delete default dev enp0s3
    fi
  EOF

  config.vm.define "k3svm-a" do |k3svm_a|
    k3svm_a.vm.hostname = "k3svm-a"
    k3svm_a.vm.provider "virtualbox" do |vb|
      vb.name = "k3svm-a"
    end
    k3svm_a.vm.provision "shell", inline: <<-EOF
      echo "PROVISION NOTICE: Installing JQ and Docker"
      apt update && apt install -y jq docker.io

      echo "PROVISION NOTICE: Installing K3S"
      if [ ! -e /etc/rancher/k3s/k3s.yaml ] ; then curl -sfL https://get.k3s.io | sh - ; fi
      until kubectl get nodes 2>/dev/null | grep k3svm-a | grep " Ready " 2>/dev/null >/dev/null ; do echo "Waiting to be ready" ; sleep 1 ; done
      cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml

      echo "PROVISION NOTICE: K3S Installed. Setting up MetalLB"
      kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml

      echo "PROVISION NOTICE: MetalLB installed. Configuring public registry."
      kubectl apply -f /vagrant/Build/registry.yaml
      touch /etc/rancher/k3s/registry.yaml
      touch /etc/docker/daemon.json
    EOF
    k3svm_a.vm.provision "shell", run: "always", inline: <<-EOF
      echo "PROVISION NOTICE: Checking/Updating PubIP data"
      /vagrant/Build/use_pubip.sh
      echo "PROVISION NOTICE: Done"
    EOF
  end
  config.vm.define "k3svm-b" do |k3svm_b|
    k3svm_b.vm.hostname = "k3svm-b"
    # k3svm_b.persistent_storage.enabled = true
    # k3svm_b.persistent_storage.location = "k3svm-b.vdi"
    # k3svm_b.persistent_storage.size = 20000
    # k3svm_b.persistent_storage.partition = false
    # k3svm_b.persistent_storage.variant = 'Fixed'
    k3svm_b.vm.provider "virtualbox" do |vb|
      vb.name = "k3svm-b"
    end
    k3svm_b.vm.provision "shell", inline: <<-EOF
      if [ ! -e /etc/rancher/node/password ] ; then bash /vagrant/install_server.sh ; fi
      # source /vagrant/source.pubip
      # cd /root/
      # git clone https://github.com/rook/rook.git --single-branch --branch release-1.2
      # cd /root/rook/cluster/examples/kubernetes/ceph/
      # kubectl create -f common.yaml
      # kubectl create -f operator.yaml
      # echo "    nodes:" >> cluster-test.yaml
      # echo '    - name: "k3svm-b"' >> cluster-test.yaml
      # echo "      devices:" >> cluster-test.yaml
      # echo '      - name: "sdc"' >> cluster-test.yaml
      # kubectl create -f cluster-test.yaml
      # kubectl create -f filesystem.yaml
      # kubectl create -f toolbox.yaml
      # kubectl create -f dashboard-external-https.yaml
      # until [ -n "$(kubectl -n rook-ceph get secret rook-ceph-dashboard-password)" ] ; do sleep 2 ; done
      # export ceph_dashboard_pw="$(kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode)
      # export ceph_dashboard_port="$(kubectl -n rook-ceph get service rook-ceph-mgr-dashboard-external-https -o json | jq .spec.ports[0].nodePort)"
      # echo "Ceph Dashboard: https://$pubip:$ceph_dashboard_port using creds: admin:$ceph_dashboard_pw"
    EOF
  end
end