#!/usr/bin/env bash
#$# this script is intended to be run from a fresh Terraform Virtual Server Instances

export DEPLOY_ENV="STARTED"
if [ $DEPLOY_ENV -eq "STARTED" ]; then
echo ".......................................PHASE1.................................."
# NOTE: you must set this manually now
echo "export IBM_API_TOKEN=\"JUbX8h2y6qu0QwJOXTfV0QZzNE1M06UCUQMa15-emISC\"" >> ~/.profile

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y jq unzip python2.7 software-properties-common make
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
python2 get-pip.py
sudo apt-get update && sudo apt-get install -y gnupg  curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# get and unpack golang
curl -O https://dl.google.com/go/go1.16.5.linux-amd64.tar.gz
tar -xvf go1.16.5.linux-amd64.tar.gz

# move binary and add to path
mv go /usr/local
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile

# create the goApps directory, set GOPATH, and put it on PATH
mkdir goApps
echo "export GOPATH=/root/goApps" >> ~/.profile
echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.profile
# **turn on the go module, default is auto. The value is off, if tendermint source code
#is downloaded under $GOPATH/src directory
echo "export GO111MODULE=on" >> ~/.profile

source ~/.profile

mkdir -p $GOPATH/src/github.com/tendermint
cd $GOPATH/src/github.com/tendermint
# ** use git clone instead of go get.
# once go module is on, go get will download source code to
# specific version directory under $GOPATH/pkg/mod the make
# script will not work
git clone https://github.com/tendermint/tendermint.git
cd tendermint
 build
make tools
make build
#** need to install the package, otherwise terdermint testnet will not execute
make install

# generate an ssh key
ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
echo "export SSH_KEY_FILE=\"\$HOME/.ssh/id_rsa.pub\"" >> ~/.profile
source ~/.profile

# install ansible
sudo apt-get update -y
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update -y
sudo apt-get install ansible -y

fi

export DEPLOY_ENV="COMPLETED"
source ~/.profile
echo ".......................................PHASE2.................................."

# the next two commands are directory sensitive
cd $GOPATH/src/github.com/tendermint/tendermint/networks/remote/terraform

terraform init
terraform apply -var IBM_API_TOKEN="$IBM_API_TOKEN" -var SSH_KEY_FILE="$SSH_KEY_FILE" -auto-approve

# let the droplets boot
echo "waiting for the droplets to boot"
sleep 1
pwd
ls -lah
terraform output -json public_ips
sleep 60

cd $GOPATH/src/github.com/tendermint/tendermint/networks/remote/terraform
#cd ~/goApps/src/github.com/tendermint/tendermint/networks/remote/terraform
pwd
ip0=`terraform output -json public_ips | jq '.[0][0]'
ip1=`terraform output -json public_ips | jq '.[0][0]'
ip2=`terraform output -json public_ips | jq '.[0][0]'
ip3=`terraform output -json public_ips | jq '.[0][0]'


echo "IP CHECK1"
echo "Node0 IP is $ip0"
echo "Node1 IP is $ip1"
echo "Node2 IP is $ip2"
echo "Node3 IP is $ip3"

# to remove quotes
strip() {
  opt=$1
  temp="${opt%\"}"
  temp="${temp#\"}"
  echo $temp
}

ip0=$(strip $ip0)
ip1=$(strip $ip1)
ip2=$(strip $ip2)
ip3=$(strip $ip3)

echo "IP CHECK2"
echo "Node0 IP is $ip0"
echo "Node1 IP is $ip1"
echo "Node2 IP is $ip2"
echo "Node3 IP is $ip3"

# all the ansible commands are also directory specific
cd $GOPATH/src/github.com/tendermint/tendermint/networks/remote/ansible

# create config dirs
tendermint testnet

ansible-playbook -i inventory/digital_ocean.py -l sentrynet install.yml
ansible-playbook -i inventory/digital_ocean.py -l sentrynet config.yml -e BINARY=$GOPATH/src/github.com/tendermint/tendermint/build/tendermint -e CONFIGDIR=$GOPATH/src/github.com/tendermint/tendermint/networks/remote/ansible/mytestnet

sleep 10

echo "IP CHECK3"
echo "Node0 IP is $ip0"
echo "Node1 IP is $ip1"
echo "Node2 IP is $ip2"
echo "Node3 IP is $ip3"


# get each nodes ID then populate the ansible file
id0=`curl $ip0:26657/status | jq .result.node_info.id`
id1=`curl $ip1:26657/status | jq .result.node_info.id`
id2=`curl $ip2:26657/status | jq .result.node_info.id`
id3=`curl $ip3:26657/status | jq .result.node_info.id`


echo "ID CHECK1"
echo "Node0 ID is $id0"
echo "Node1 ID is $id1"
echo "Node2 ID is $id2"
echo "Node3 ID is $id3"


id0=$(strip $id0)
id1=$(strip $id1)
id2=$(strip $id2)
id3=$(strip $id3)

echo "ID CHECK2"
echo "Node0 ID is $id0"
echo "Node1 ID is $id1"
echo "Node2 ID is $id2"
echo "Node3 ID is $id3"

# remove file we'll re-write to with new info
old_ansible_file=$GOPATH/src/github.com/tendermint/tendermint/networks/remote/ansible/roles/install/templates/systemd.service.j2
rm $old_ansible_file

# need to populate the `--p2p.persistent-peers` flag
echo "[Unit]
Description={{service}}
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
User={{service}}
Group={{service}}
PermissionsStartOnly=true
ExecStart=/usr/bin/tendermint node --mode validator --proxy-app=kvstore --p2p.persistent-peers=$id0@$ip0:26656,$id1@$ip1:26656,$id2@$ip2:26656,$id3@$ip3:26656
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
" >> $old_ansible_file

# now, we can re-run the install command
ansible-playbook -i inventory/digital_ocean.py -l sentrynet install.yml

# and finally restart it all
ansible-playbook -i inventory/digital_ocean.py -l sentrynet restart.yml

echo "congratulations, your testnet is now running :)"
