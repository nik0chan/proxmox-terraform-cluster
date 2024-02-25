terraform {
  required_providers {
    proxmox = {
      source = "thegameprofi/proxmox"
      version = "2.9.15"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://${var.proxmox_master_ip}:8006/api2/json"
  pm_api_token_id = var.token_id
  pm_api_token_secret = var.token
  pm_tls_insecure = true
  pm_parallel = 1
}

resource "proxmox_vm_qemu" "kube-worker-1" {
  count = 1
  name = "kube-worker-01"
  target_node = var.proxmox_worker_1
  vmid = "110111"
  clone = var.template_name
  agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4096
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  storage = var.dest_storage
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = "110"
   } 
  ipconfig0 ="ip=${var.kube_worker1_ip}/24,gw=${var.kube_gateway}"
  lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      network,
    ]
  }  
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
  provisioner "remote-exec" {
    inline = [
     "sudo snap wait system seed.loaded",
     "sudo snap install microk8s --classic",
     "sudo microk8s enable dns",
     "sudo usermod -a -G microk8s ubuntu",
     "sudo mkdir -p /home/ubuntu/.kube",
     "sudo chown -f -R ubuntu /home/ubuntu/.kube",
	 "sudo bash -c 'echo \"Match Address ${var.kube_master_ip}\" >> /etc/ssh/sshd_config'",
	 "sudo bash -c 'echo \"PasswordAuthentication yes\"    >> /etc/ssh/sshd_config'",
	 "sudo systemctl reload sshd",
	 "sudo bash -c 'echo -e \"changeme\\nchangeme\" | passwd ubuntu'"
    ]
   
    connection {
	  type        = "ssh"
      user        = "ubuntu"
	  private_key = "${file(".ssh/id_rsa")}"
      host        = var.kube_worker1_ip
    }  
  }  
}

resource "proxmox_vm_qemu" "kube-worker-2" {
  count = 2
  name = "kube-worker-02"
  target_node = var.proxmox_worker_2
  vmid = "110112"
  clone = var.template_name
  agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4096
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  storage = var.dest_storage
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = "110"
   } 
  ipconfig0 ="ip=${var.kube_worker2_ip}/24,gw=${var.kube_gateway}"
  lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      network,
    ]
  }  
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
  provisioner "remote-exec" {
    inline = [
     "sudo snap wait system seed.loaded",
     "sudo snap install microk8s --classic",
     "sudo microk8s enable dns",
     "sudo usermod -a -G microk8s ubuntu",
     "sudo mkdir -p /home/ubuntu/.kube",
     "sudo chown -f -R ubuntu /home/ubuntu/.kube",
	 "sudo bash -c 'echo \"Match Address ${var.kube_master_ip}\" >> /etc/ssh/sshd_config'",
	 "sudo bash -c 'echo \"PasswordAuthentication yes\"    >> /etc/ssh/sshd_config'",
	 "sudo systemctl reload sshd",
	 "sudo bash -c 'echo -e \"changeme\\nchangeme\" | passwd ubuntu'"
    ]
   
    connection {
	  type        = "ssh"
      user        = "ubuntu"
	  private_key = "${file(".ssh/id_rsa")}"
      host        = var.kube_worker2_ip
    }  
  }  
}

resource "proxmox_vm_qemu" "kube-master" {
  depends_on = [ proxmox_vm_qemu.kube-worker-1, proxmox_vm_qemu.kube-worker-2 ]  
  count = 1
  name = "kube-master"
  target_node = var.proxmox_master
  vmid = "110120"
  clone = var.template_name
  agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4096
  boot = "order=scsi0;ide2"
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  storage = var.dest_storage
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = "110"
  }
  ipconfig0 = "ip=${var.kube_master_ip}/24,gw=${var.kube_gateway}"
  lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      network,disk 
    ]
  }
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF  
  
  provisioner "remote-exec" {
    inline = [
	 "sudo apt update && sudo apt install -y sshpass", 
     "sudo snap wait system seed.loaded",
     "sudo snap install microk8s --classic",
     "sudo microk8s enable dns",
     "sudo usermod -a -G microk8s ubuntu",
     "sudo mkdir -p /home/ubuntu/.kube",
     "sudo chown -f -R ubuntu /home/ubuntu/.kube",
	 "sudo microk8s add-node  | sed -n '5p' | sshpass -p 'changeme' ssh  -o StrictHostKeyChecking=no ubuntu@${var.kube_worker1_ip}",
	 "sudo microk8s add-node  | sed -n '5p' | sshpass -p 'changeme' ssh  -o StrictHostKeyChecking=no ubuntu@${var.kube_worker2_ip}",
	 "sudo microk8s kubectl label node kube-master node-role.kubernetes.io/master=master",
	 "sudo microk8s kubectl get nodes --no-headers=true | grep worker | awk '{print $1}' | xargs -I {} sudo microk8s kubectl label nodes {} node-role.kubernetes.io/worker=woker"
    ]  
    connection {
	  type        = "ssh"
      user        = "ubuntu"
	  private_key = "${file(".ssh/id_rsa")}"
      host        = var.kube_master_ip
    }  
  }
}
