#!/bin/bash
pubip=$(ip -j -4 addr show dev enp0s8 | grep local | cut -d\" -f4 2>/dev/null)
if [ ! -e /etc/rancher/k3s/k3s.yaml ]
then
  echo "USE_PUBIP ERROR: Must be run on the master node"
  exit 1
fi
if [ -e /vagrant/k3s.yaml ] && [ -n "$(grep -v $pubip /vagrant/k3s.yaml)" ]
then
  echo "USE_PUBIP NOTICE: Updating k3s.yaml"
  sed -E -i -e "s%server: https://[-.0-9a-zA-Z]+:6443%server: https://$pubip:6443%" /vagrant/k3s.yaml
  echo "export pubip=$pubip" > /vagrant/source.pubip
  echo "KUBECONFIG=/vagrant/k3s.yaml" >> /vagrant/source.pubip
fi
if [ -e /var/lib/rancher/k3s/server/node-token ]
then
  echo "USE_PUBIP NOTICE: Building Install_Server script for subsequent nodes"
  export K3S_URL=https://$pubip:6443
  export K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
  echo '#!/bin/bash' > /vagrant/install_server.sh
  echo 'export KUBECONFIG=/vagrant/k3s.yaml' >> /vagrant/install_server.sh
  echo "curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -" >> /vagrant/install_server.sh
  echo 'export counter=0 ; export totalcounter=0' >> /vagrant/install_server.sh
  echo 'until kubectl get nodes 2>/dev/null | grep $(hostname) | grep " Ready " 2>/dev/null >/dev/null' >> /vagrant/install_server.sh
  echo 'do' >> /vagrant/install_server.sh
  echo '  ((++counter))' >> /vagrant/install_server.sh
  echo '  ((++totalcounter))' >> /vagrant/install_server.sh
  echo '  echo "INSTALL_SERVER NOTICE: Waiting to be ready ($totalcounter)"' >> /vagrant/install_server.sh
  echo '  if [ $counter -gt 5 ]' >> /vagrant/install_server.sh
  echo '  then' >> /vagrant/install_server.sh
  echo '    counter=0' >> /vagrant/install_server.sh
  echo '    echo "INSTALL_SERVER NOTICE: Checking K3S is running"' >> /vagrant/install_server.sh
  echo '    if systemctl status k3s-agent | grep "Active: active" > /dev/null 2>/dev/null' >> /vagrant/install_server.sh
  echo '    then' >> /vagrant/install_server.sh
  echo '      echo "INSTALL_SERVER NOTICE: K3S is running' >> /vagrant/install_server.sh
  echo '    else' >> /vagrant/install_server.sh
  echo '      echo "INSTALL_SERVER WARNING: K3S is NOT running. Trying a re-install.' >> /vagrant/install_server.sh
  echo '      /usr/local/bin/k3s-agent-uninstall.sh' >> /vagrant/install_server.sh
  echo "      curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -" >> /vagrant/install_server.sh
  echo '    fi' >> /vagrant/install_server.sh
  echo '  fi' >> /vagrant/install_server.sh
  echo '  if [ $totalcounter -gt 50 ]' >> /vagrant/install_server.sh
  echo '  then' >> /vagrant/install_server.sh
  echo '    echo "INSTALL_SERVER CRITICAL: K3S has not started. Exiting"' >> /vagrant/install_server.sh
  echo '    exit 200' >> /vagrant/install_server.sh
  echo '  fi' >> /vagrant/install_server.sh
  echo '  sleep 2' >> /vagrant/install_server.sh
  echo 'done' >> /vagrant/install_server.sh
fi
if [ -e /etc/rancher/k3s/registry.yaml ]
then
  if [ -z "$(cat /etc/rancher/k3s/registry.yaml)" ]
  then
    echo "USE_PUBIP NOTICE: Empty K3S File"
    echo "mirrors:" > /etc/rancher/k3s/registry.yaml
    echo "  \"$pubip:5000\":" >> /etc/rancher/k3s/registry.yaml
    echo "    endpoint:" >> /etc/rancher/k3s/registry.yaml
    echo "      - \"http://$pubip:5000\"" >> /etc/rancher/k3s/registry.yaml
    systemctl restart k3s
  elif [ -z "$(grep $pubip /etc/rancher/k3s/registry.yaml 2>/dev/null)" ]
  then
    echo "USE_PUBIP NOTICE: Corrected K3S File"
    echo "mirrors:" > /etc/rancher/k3s/registry.yaml
    echo "  \"$pubip:5000\":" >> /etc/rancher/k3s/registry.yaml
    echo "    endpoint:" >> /etc/rancher/k3s/registry.yaml
    echo "      - \"http://$pubip:5000\"" >> /etc/rancher/k3s/registry.yaml
    systemctl restart k3s
  fi  
fi
if [ -e /etc/docker/daemon.json ]
then
  if [ -z "$(cat /etc/docker/daemon.json)" ] 
  then
    echo "USE_PUBIP NOTICE: Empty Docker File"
    echo "{\"insecure-registries\" : [\"$pubip:5000\"]}" > /etc/docker/daemon.json
    systemctl restart docker
  elif [ -z "$(grep $pubip /etc/docker/daemon.json 2>/dev/null)" ]
  then
    echo "USE_PUBIP NOTICE: Corrected Docker File"
    echo "{\"insecure-registries\" : [\"$pubip:5000\"]}" > /etc/docker/daemon.json
    systemctl restart docker
  fi
fi
