# proxmox-terraform-cluster
Autodeployment of a microk8s Kubernetes cluster of 3 nodes on a proxmox cluster

# Presequisites: 

- A proxmox cluster/server 
- Terraform installed (https://developer.hashicorp.com/terraform/install)
- Pre-generated template, you can find an script to generate one based on Ubuntu cloud init on this repo (create_ubuntu_template.sh) users root/ubuntu password changeme  
- Proxmox authentication token configured 
- Private on .ssh directory 
- Public key corresponding to private key con ssh_public_key variable (terraform.tfvars) 
  + On Proxmox server: Datacenter > API Tokens > Add 
  
- Some variables defined on terraform.tfvars 
proxmox_master = "< proxmox-master >"
proxmox_master_ip = "< proxmox-master-IP >
proxmox_worker_1 = "< proxmox-worker-2 >"
proxmox_worker_2 = "< proxmox-worker-2 >"
template_name = "< pre-generated-image >"
dest_storage = "< shared-storage-between-nodes >" 
token_id = "< token-id >"
token = "< generated-token >"
kube_worker1_ip = "cluster kubernetes worker 1 IP"
kube_worker2_ip = "cluster kubernetes worker 2 IP"
kube_master_ip = "cluster kubernetes master IP"
kube_gateway = "cluster network gateway"
ssh_public_key = "< your-public-key-id-here >"

- A prayer

Once you have this.... 

1) terraform init 
2) terraform plan 
3) terrafrom apply 
4) cross your fingers  