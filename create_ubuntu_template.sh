#!/bin/sh
echo Preparing customize environment
echo -------------------------------
apt update -y && sudo apt install libguestfs-tools -y
echo Downloading Ubuntu 22.04 LTS clouding image
echo --------------------------------------------
cd /tmp
wget https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img
echo Customizing image
echo -------------------------------
echo Step 1/2: Adding qemu-guest-agent
virt-customize -a ubuntu-22.04-server-cloudimg-amd64.img --install qemu-guest-agent
echo Step 2/2: Assing default root password
virt-customize -a ubuntu-22.04-server-cloudimg-amd64.img --root-password password:changeme
virt-customize -a ubuntu-22.04-server-cloudimg-amd64.img --password ubuntu:password:changeme
echo Creating VM template from prepared cloud-init image
echo Specs:
echo CPU: 2
echo RAM: 2048 Mb
echo ATENTION: Hard disk on: proxmox-nfs, set you propper storage local,local-lvm,etc...
echo Bridge: vmbr0
echo Maquine ID: 9000
echo -----------------------------------------
qm create 9000 --name "ubuntu-cloudinit-template" --cores 2 --memory 2048 --scsihw virtio-scsi-pci
qm set 9000 --scsi0 proxmox-nfs:0,import-from=/tmp/ubuntu-22.04-server-cloudimg-amd64.img --agent enabled=1
qm set 9000 --ide2 proxmox-nfs:cloudinit
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket --vga serial0
qm resize 9000 scsi0 +6G
qm template 9000
rm -f /tmp/ubuntu-22.04-server-cloudimg-amd64.img
rm -fr /tmp/id_rsa*
