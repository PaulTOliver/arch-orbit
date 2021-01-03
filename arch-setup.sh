#!/bin/sh

#
# Archlinux auto system configurator script. Run this from within Archlinux's live CD environment.
#

echo ":: Welcome to Archlinux system configurator"
echo ":: Installing dependencies"
pacman -Sy --needed --noconfirm fzf

echo
echo ":: Please provide the following information"
read -p "-- Hostname for your new system: " hostname
read -p "-- Username for daily use: " username
stty -echo
read -p "-- System password: " password && echo
read -p "-- Confirm password: " password_confirm && echo
stty echo

[ "$password" != "$password_confirm" ] && { echo "!! Passwords do not match. Aborting."; exit 1; }

drive=$(lsblk -lp | grep disk | awk '{print $1}' | fzf -1 --reverse --prompt="-- Select installation drive: ")
timezone=$(timedatectl list-timezones | fzf --reverse --prompt="-- Select timezone: ")

echo
echo ":: The following setup has been selected"
echo ":: Hostname: $hostname"
echo ":: Username: $username"
echo ":: Drive: $drive"
echo ":: Timezone: $timezone"
echo "!! Warning: all data on selected drive $drive will be wiped permanently!"
read -p "-- To proceed, type yes in capital letters: " proceed

[ "$proceed" != "YES" ] && { echo "!! Aborting."; exit 1; }

echo
echo ":: Formatting disk drive $drive"
{
	echo o      # Generate new partition table
	echo Y      # Confirm

	echo n      # New partition (boot)
	echo        # Primary
	echo        # Start at lowest possible address
	echo +512M  # Set size of boot partition
	echo EF00   # Set type of boot partition

	echo n      # New partition (root)
	echo        # Primary
	echo        # Start at lowest possible address
	echo        # End at highest possible address
	echo        # Use default partition type

	echo w      # Save changes
	echo Y      # Confirm
} | gdisk $drive > /dev/null 2>&1

echo ":: The following layout has been generated"
lsblk -pT $drive
read -p "-- Press enter to continue"

boot=$(lsblk -lp | grep part | awk '{print $1}' | sed -n '1p')
root=$(lsblk -lp | grep part | awk '{print $1}' | sed -n '2p')

echo
echo ":: Encrypting root partition"
mkdir /run/cryptsetup
echo -n "$password" | cryptsetup luksFormat $root --label=root -d -
echo -n "$password" | cryptsetup open $root luks -d -

echo
echo ":: Formatting and mounting partitions"
mkfs.vfat -F 32 -n EFI $boot
mkfs.ext4 -L ROOT /dev/mapper/luks
mount /dev/mapper/luks /mnt
mkdir /mnt/boot
mount $boot /mnt/boot

echo
echo ":: Installing base system"
pacstrap /mnt base e2fsprogs intel-ucode linux networkmanager sudo
genfstab -U /mnt >> /mnt/etc/fstab
cat <<-EOT | arch-chroot /mnt /bin/sh
	echo
	echo ":: Setting up system time"
	ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
	hwclock --systohc
	systemctl enable systemd-timesyncd.service

	echo
	echo ":: Setting up system locale"
	sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "KEYMAP=us" > /etc/vconsole.conf

	echo
	echo ":: Setting up the hosts file"
	echo $hostname > /etc/hostname
	cat <<-EOF > /etc/hosts
		127.0.0.1 localhost
		::1       localhost
		127.0.1.1 $hostname.localdomain $hostname
	EOF

	echo
	echo ":: Setting up network manager"
	systemctl enable NetworkManager.service

	echo
	echo ":: Configuring user $username"
	useradd -m $username
	echo "root:$password" | chpasswd
	echo "$username:$password" | chpasswd
	sed -i "/^root/a $username ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers

	echo
	echo ":: Setting up auto-login for user $username"
	mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/skip-prompt.conf
		[Service]
		ExecStart=
		ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $username --noclear %I linux
	EOF

	echo
	echo ":: Recreating initramfs"
	sed -i 's/^HOOKS=\(.*\)/HOOKS=\(base keyboard udev autodetect modconf block keymap encrypt filesystems\)/' /etc/mkinitcpio.conf
	mkinitcpio -p linux

	echo
	echo ":: Installing boot manager"
	bootctl --path=/boot install
	echo "default arch.conf" > /boot/loader/loader.conf
	cat <<-EOF > /boot/loader/entries/arch.conf
		title Arch Linux
		linux /vmlinuz-linux
		initrd /intel-ucode.img
		initrd /initramfs-linux.img
		options cryptdevice=UUID=$(blkid -s UUID -o value $root):luks:allow-discards root=/dev/mapper/luks rd.luks.options=discard rw quiet systemd.show_status=false
	EOF

	echo
	echo ":: Installing pacman hook for systemd-boot"
	mkdir -p /etc/pacman.d/hooks
	cat <<-EOF > /etc/pacman.d/hooks/100-systemd-boot.hook
		[Trigger]
		Type = Package
		Operation = Upgrade
		Target = systemd

		[Action]
		Description = Updating systemd-boot
		When = PostTransaction
		Exec = /usr/bin/bootctl update
	EOF
EOT

echo
echo ":: Finishing up"
read -p "-- Press enter to reboot"
umount -R /mnt
reboot
