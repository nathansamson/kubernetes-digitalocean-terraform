## Setup terraform envvars
# Usage:
#	. ./setup_terraform.sh

eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa

export TF_VAR_number_of_workers=3
export TF_VAR_do_token=$(cat ./secrets/DO_TOKEN)
export TF_VAR_do_read_token=$(cat ./secrets/DO_READ_TOKEN)
export TF_VAR_pub_key="~/.ssh/id_rsa.pub"
export TF_VAR_pvt_key="~/.ssh/id_rsa"
export TF_VAR_region="ams3"
export TF_VAR_size_master="2gb"
export TF_VAR_size_worker="8gb"
export TF_VAR_etcd_count="3"
export TF_VAR_prefix="eu1-cloud-"


if [ ! -f ./secrets/ETCD_DISCOVERY_URL ]; then
   curl https://discovery.etcd.io/new?size=3 > ./secrets/ETCD_DISCOVERY_URL
fi
export TF_VAR_etcd_discovery_url=$(cat ./secrets/ETCD_DISCOVERY_URL)

if [ ! -f ./secrets/KEEPALIVED_TOKEN ]; then
  < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c45 > ./secrets/KEEPALIVED_TOKEN
fi

if [[ `uname` == 'Darwin' ]]; then
	export TF_VAR_ssh_fingerprint=$(ssh-keygen -E MD5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}' | sed 's/MD5://g')
else
	export TF_VAR_ssh_fingerprint=$(ssh-keygen -E MD5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}' | sed 's/MD5://g')
fi


export TF_VAR_ssh_fingerprint=ff:5b:e0:6e:f6:b3:f0:21:19:57:4b:5d:eb:43:e0:ac,87:ad:87:10:89:2e:64:d9:43:11:2f:60:3b:93:fe:7f
