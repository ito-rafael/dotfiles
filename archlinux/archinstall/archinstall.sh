wget https://geo.mirror.pkgbuild.com/iso/2025.10.01/archlinux-x86_64.iso

gpg --keyserver-options auto-key-retrieve --verify archlinux-<VERSION>-x86_64.iso.sig

dd bs=4M if=path/to/archlinux.iso of=/dev/<SDX> status=progress oflag=sync

archinstall --config-url https://github.com/ito-rafael/dotfiles/blob/master/arch/archinstall-ansible.json

findmnt -t btrfs -o TARGET,SOURCE,OPTIONS

cat /etc/fstab

lsattr -d /var/lib/docker /var/lib/libvirt/images /swap/swapfile

btrfs subvolume list / | grep -E "@snapshot-home/|@snapshot-root/"
