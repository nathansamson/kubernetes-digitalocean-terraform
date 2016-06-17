## Setup terraform envvars
# Usage:
#	. ./setup_terraform.sh

export TF_VAR_number_of_workers=3
export TF_VAR_do_token=$(cat ./secrets/DO_TOKEN)
export TF_VAR_pub_key="~/.ssh/id_rsa.pub"
export TF_VAR_pvt_key="~/.ssh/id_rsa"
export TF_VAR_region="ams3"
export TF_VAR_size_worker="8gb"


if [ ! -f ./secrets/ETCD_DISCOVERY_URL ]; then
   curl https://discovery.etcd.io/new?size=3 > ./secrets/ETCD_DISCOVERY_URL
fi
export TF_VAR_etcd_discovery_url=$(cat ./secrets/ETCD_DISCOVERY_URL)

if [[ `uname` == 'Darwin' ]]; then
	export TF_VAR_ssh_fingerprint=$(ssh-keygen -E MD5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}' | sed 's/MD5://g')
else
	export TF_VAR_ssh_fingerprint=$(ssh-keygen -E MD5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}' | sed 's/MD5://g')
fi
