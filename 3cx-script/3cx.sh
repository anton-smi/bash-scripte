#!/bin/bash


# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

mkdir -p /mnt/3cx || { echo "Failed to make directory /mnt/3cx"; exit 1;}
mount /dev/vda1 /mnt/3cx || { echo "Failed to mount /dev/vda1"; exit 1;}
mkdir -p /mnt/3cx/iso || { echo "Failed to make directory /mnt/3cx/iso"; exit 1;}
mkdir -p /mnt/3cx/install || { echo "Failed to make directory /mnt/3cx/install"; exit 1;}

wget -O /mnt/3cx/iso/3cx.iso \
    https://downloads-global.3cx.com/downloads/debian12iso/debian-amd64-netinst-3cx.iso \
    || { echo "Failed to download 3cx.iso at /mnt/3cx/iso/"; exit 1;}


wget -O /mnt/3cx/install/initrd.gz \
    http://ftp.de.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz \
    || { echo "Failed to download initrd.gz at /mnt/3cx/install/"; exit 1;}

wget -O /mnt/3cx/install/vmlinuz \
    http://ftp.de.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/vmlinuz \
    || { echo "Failed to download vmlinuz at /mnt/3cx/install/"; exit 1;}

mkdir -p /mnt/3cx/boot/grub || { echo "Failed to make directory /mnt/3cx/boot/grub"; exit 1;}



echo "
menuentry "Install 3CX from ISO" {

    set root=(hd0,1)
    set isofile=/iso/3cx.iso

    linux /install/vmlinuz inst.stage2=hd:LABEL=3cx iso-scan/filename=$isofile
ipv6.disable=1 auto=true priority=high url=http://downloads-
global.3cx.com/downloads/debian12iso/preseed_12.1.0_46a7ea2.txt --- quiet
THREECXMARKER=DEBIAN-3CX-ISO

    initrd /install/initrd.gz
} " > /mnt/3cx/boot/grub/grub.cfg


grub-install --root-directory=/mnt/3cx /dev/vda || { echo "Failed to install grub on /dev/vda at /mnt/3cx"; exit 1;}




# Ask if user wants to reboot
read -p "Do you want to reboot the system now? (y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Rebooting the system..."
    reboot
else
    echo "Reboot skipped. Please reboot manually."
fi
