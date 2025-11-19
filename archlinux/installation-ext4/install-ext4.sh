wget https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso

gpg --keyserver-options auto-key-retrieve --verify archlinux-x86_64.iso.sig

dd bs=4M if=path/to/archlinux.iso of=/dev/sdx status=progress oflag=sync

setfont /usr/share/kbd/consolefonts/latarcyrheb-sun32.psfu.gz

iw dev
rfkill list
rfkill unblock wifi
ip link set wlp1s0 up
iw dev wlp1s0 scan | less
ip link set wlp1s0 down
iw dev wlp1s0 set type ibss
ip link set wlp1s0 up

wpa_passphrase "SSID" "PASSWD" > /etc/wpa_supplicant/SSID.conf
wpa_supplicant -c /etc/wpa_supplicant/SSID.conf -i wlp1s0
wpa_supplicant -B -c /etc/wpa_supplicant/SSID.conf -i wlp1s0
dhclient wlp1s0

timedatectl set-ntp true

fdisk -l
fdisk /dev/sdX

mkfs.fat -F32 /dev/sda2

mkfs.ext4 /dev/sda3

mkswap /dev/sda4
swapon /dev/sda4

mkfs.ext4 /dev/sda5

mount /dev/sda3 /mnt

mkdir /mnt/efi
mount /dev/sda2 /mnt/efi

mkdir /mnt/home
mount /dev/sda5 /mnt/home

vi /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime

hwclock --systohc

vi /etc/locale.gen

en_US.UTF-8 UTF-8
pt_br_US.UTF-8 UTF-8

locale-gen

vi /etc/locale.conf

LANG=en_US.UTF-8

echo Y2P-ArchLinux >> /etc/hostname

vi /etc/hosts

127.0.0.1   localhost
::1	        localhost
127.0.1.1   Y2P-ArchLinux.localdomain  Y2P-ArchLinux

systemctl enable dhcpcd
pacman -S iw wpa_supplicant

passwd
pacman -Syu

pacman -S grub efibootmgr
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
reboot
