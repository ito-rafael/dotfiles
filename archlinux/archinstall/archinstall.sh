archinstall \
    --config-url https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/archlinux/archinstall/config.json \
    --creds-url https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/archlinux/archinstall/credentials.json

wget https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso

gpg --keyserver-options auto-key-retrieve --verify archlinux-x86_64.iso.sig

dd bs=4M if=path/to/archlinux.iso of=/dev/<SDX> status=progress oflag=sync

archinstall \
    --config-url https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/archlinux/archinstall/config.json \
    --creds-url https://raw.githubusercontent.com/ito-rafael/dotfiles/refs/heads/master/archlinux/archinstall/credentials.json

findmnt -t btrfs -o TARGET,SOURCE,OPTIONS

cat /etc/fstab

lsattr -d /var/lib/docker /var/lib/libvirt/images /swap/swapfile

btrfs subvolume list / | grep -E "@snapshot-home/|@snapshot-root/"

su - ansible --command "ANSIBLE_FORCE_COLOR=true ansible-pull --url https://github.com/ito-rafael/ansible-provision | tee /home/ansible/ansible-setup.log"
