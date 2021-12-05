#! /bin/bash
echo ""
echo "Discos encontrados:"
lsblk | grep "disk"
echo "Selecciona tu disco duro:"
read disco
echo ""
timedatectl set-ntp true
echo "Creando particiones y volumenes en /dev/$disco ..."
echo ""
echo "YES" | parted /dev/$disco mklabel msdos
parted -a optimal /dev/$disco mkpart primary 2 100%
pvcreate /dev/$disco[1]
vgcreate archfs /dev/$disco[1]
lvcreate -n boot -L 2G archfs
lvcreate -n root -L 5G archfs
echo ""
echo "Formateando y montando los volumenes..."
mkfs.ext4 /dev/archfs/boot
mkfs.ext4 /dev/archfs/root
mount /dev/archfs/root /mnt
mkdir /mnt/boot
mount /dev/archfs/boot /mnt/boot
echo ""
echo "Instalando el sistema base..."
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

cat > /mnt/etc/mkinitcpio.conf << EOF
#     MODULES=(piix ide_disk reiserfs)
MODULES=()

BINARIES=()

FILES=()
HOOKS=(base udev autodetect modconf block filesystems lvm2 keyboard fsck)  
EOF


cat > /mnt/arch2.txt << EOF
#! /bin/bash
yes | pacman -S vim
yes | pacman -S networkmanager
yes | pacman -S lvm2
systemctl enable NetworkManager
ln -sf /usr/share/zoneinfo/Mexico/General /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "127.0.0.1 localhost" > /etc/hosts
echo "lastdragon.arch" > /etc/hostname
echo ""
echo "Instalando un gestor de arranque..."
mkinitcpio -P
yes | pacman -S grub
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=i386-pc /dev/$disco
echo ""
echo "Finalmente, escribe la clave del usuario root:"
passwd root
EOF

cat > /mnt/etc/issue << EOF
Arch Linux \r (\l) Instalado con el script de Last Dragon
www.lastdragon.net Twitter @LastDragonMX

Ingresa tus credenciales:

EOF

chmod +x /mnt/arch2.txt
arch-chroot /mnt /arch2.txt
rm -f /mnt/arch2.txt archlinuxinstall.txt
shutdown -r now
