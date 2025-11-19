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
fdisk /dev/nvme0n1

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt

btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@snapshot-root
btrfs subvolume create /mnt/@snapshot-home
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pacman
btrfs subvolume create /mnt/@flatpak
btrfs subvolume create /mnt/@podman
btrfs subvolume create /mnt/@docker
btrfs subvolume create /mnt/@libvirt

umount /mnt

mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@root /dev/nvme0n1p2 /mnt

mkdir /mnt/.snapshot
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@snapshot-root /dev/nvme0n1p2 /mnt/.snapshot

mkdir /mnt/home
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@home /dev/nvme0n1p2 /mnt/home

mkdir /mnt/home/.snapshot
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@snapshot-home /dev/nvme0n1p2 /mnt/home/.snapshot

mkdir -p /mnt/home/rafael/.cache
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@cache /dev/nvme0n1p2 /mnt/home/rafael/.cache

mkdir -p /mnt/var/log
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@log /dev/nvme0n1p2 /mnt/var/log

mkdir -p /mnt/var/cache/pacman/pkg
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@pacman /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg

mkdir -p /mnt/var/lib/flatpak
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@flatpak /dev/nvme0n1p2 /mnt/var/lib/flatpak

mkdir -p /mnt/var/lib/containers
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@podman /dev/nvme0n1p2 /mnt/var/lib/containers

mkdir -p /mnt/var/lib/docker
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@docker /dev/nvme0n1p2 /mnt/var/lib/docker
chattr +C /mnt/var/lib/docker

mkdir -p /mnt/var/lib/libvirt/images
mount -o noatime,commit=120,compress=zstd,space_cache=v2,subvol=@libvirt /dev/nvme0n1p2 /mnt/var/lib/libvirt/images
chattr +C /mnt/var/lib/libvirt/images

mkdir /mnt/swap
mount -o noatime,commit=120,subvol=@swap /dev/nvme0n1p2 /mnt/swap

btrfs filesystem mkswapfile --size 16g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

mkdir -p /mnt/{efi,boot}
mount /dev/nvme0n1p1 /mnt/efi
mkdir -p /mnt/efi/EFI/arch
mount --bind /mnt/efi/EFI/arch /mnt/boot

lsblk
findmnt

reflector --country Brazil --age 6 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel linux linux-firmware bash intel-ucode btrfs-progs networkmanager neovim

genfstab -U /mnt >> /mnt/etc/fstab

sed -i -e "s/\/mnt//" /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime

hwclock --systohc

vi /etc/locale.gen

en_US.UTF-8 UTF-8
pt_br_US.UTF-8 UTF-8

locale-gen

echo LANG=en_US.UTF-8 >> /etc/locale.conf

echo IPF-ArchLinux >> /etc/hostname

nvim /etc/hosts

127.0.0.1  localhost
::1        localhost
127.0.1.1  IPF-ArchLinux.localdomain  IPF-ArchLinux

pacman -S iw wpa_supplicant networkmanager

passwd
pacman -Syu

pacman -S grub grub-btrfs efibootmgr

nvim /etc/mkinitcpio.conf

#MODULES=()
MODULES=(btrfs)

mkinitcpio -p linux

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /efi/EFI/arch/grub/grub.cfg

exit
swapoff /mnt/swap/swapfile
umount -R /mnt
reboot
