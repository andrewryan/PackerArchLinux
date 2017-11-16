#!/usr/bin/env bash

HOSTNAME="temporaryUser"

printf "#####> Formatting disk" 
printf "n\n\n\n\n\nw\ny\n" | gdisk /dev/sda
mkfs.ext4 /dev/sda1

printf "#####> %s\n" "Mounting disk" 
mount /dev/sda1 /mnt

printf "#####> %s\n" "Modifying mirrorlist" 
awk 'US_entry {print; US_entry=0}
/United States/ {print; US_entry=1}' /etc/pacman.d/mirrorlist >/tmp/mlist.txt
cat /etc/pacman.d/mirrorlist >>/tmp/mlist.txt
cp /tmp/mlist.txt /etc/pacman.d/mirrorlist

printf "#####> %s\n" "Installing base packages" 
pacstrap /mnt base

printf "#####> %s\n" "adding fstab entry" 
genfstab -U /mnt >> /mnt/etc/fstab
#creates empty executable file
/usr/bin/install --mode=0755 /dev/null "/mnt/usr/local/bin/configsystem.bash"

printf "#####> %s\n" "chroot and install"
cat >/mnt/usr/local/bin/configsystem.bash <<ENDOFSCRIPT
#!/usr/bin/env bash
printf "#####> %s\n" "configuring time"
ln -s /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc --utc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "$HOSTNAME" >/etc/hostname

printf "#####> %s\n" "configuring networking"
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
cat >/etc/systemd/network/MyDhcp.network <<ENDOFTEXT
[Match]
Name=en*

[Network]
DHCP=ipv4
ENDOFTEXT
printf "#####> %s\n" "setting root password"
echo "root:vagrant" | chpasswd
printf "#####> %s\n" "creating boot partition"
pacman -S --noconfirm gdisk
printf "n\n\n\n\nef02\nw\ny\n" | gdisk /dev/sda
pacman -S --noconfirm grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

#install other stuff
printf "#####> %s\n" "configuring vagrant user" 
useradd -m -c "Vagrant User" vagrant
echo "vagrant:vagrant" | chpasswd
pacman -S --noconfirm sudo
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
mkdir /home/vagrant/.ssh
curl -o /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chown -R vagrant:vagrant ~vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
printf "#####> %s\n" "configuring ssh daemon" 
pacman -S --noconfirm openssh
systemctl enable sshd.socket
ENDOFSCRIPT

arch-chroot /mnt /usr/local/bin/configsystem.bash
rm /mnt/usr/local/bin/configsystem.bash

printf "#####> %s\n" "adding symlink for networking" 
rm /mnt/etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf
reboot
