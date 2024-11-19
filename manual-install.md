# Arch linux installation guide

# Preliminary steps  

First set up your keyboard layout  

```Zsh
# List all the available keyboard maps and filter them through grep 
ls /usr/share/kbd/keymaps/**/*.map.gz | grep en

# Now get the name without the path and the extension ( localectl returns just the name ) and load the layout. 
loadkeys us
```

<br>

Check that we are in UEFI mode  

```Zsh
# If this command prints 64 or 32 then you are in UEFI
cat /sys/firmware/efi/fw_platform_size
```

<br>

Check the internet connection  

```Zsh
ping -c 5 archlinux.org 
```

<br>

Check the system clock

```Zsh
# Check if ntp is active and if the time is right
timedatectl

# In case it's not active you can do
timedatectl set-ntp true

# Or this
systemctl enable systemd-timesyncd.service
```

<br>

# Main installation

## Disk partitioning

I will make 2 partitions:  

| Number | Type | Size |
| --- | --- | --- |
| 1 | EFI | 512 Mb |
| 2 | Linux Filesystem | 99.5Gb \(all of the remaining space \) |  

<br>

```Zsh
# Check the drive name. Mine is /dev/nvme0n1
# If you have an hdd is something like sdax
fdisk -l

# Now you can either go and partition your disk with fdisk and follow the steps below,
# or if you want to do things yourself and make it easier, use cfdisk ( an fdisk TUI wrapper ) which is
# much more user friendly. A reddit user suggested me this and it's indeed very intuitive to use.
# If you choose cfdisk you will have to invoke it the same way as I did with fdisk below, but
# you don't need to follow my commands blindly as with fdisk below, just navigate the UI with the arrows
# and press enter to get inside menus, remember to write changes before quitting.

# Invoke fdisk to partition
fdisk /dev/nvme0n1

# Now press the following commands, when i write ENTER press enter
g
ENTER
n
ENTER
ENTER
ENTER
+512M
ENTER
t
ENTER
ENTER
1
ENTER
n
ENTER
ENTER
ENTER # If you don't want to use all the space then select the size by writing +XG ( eg: to make a 10GB partition +10G )
p
ENTER # Now check if you got the partitions right

# If so write the changes
w
ENTER

# If not you can quit without saving and redo from the beginning
q
ENTER
```

<br>

## Disk formatting  

For the file system I've chosen [**BTRFS**](https://wiki.archlinux.org/title/Btrfs) which has evolved quite a lot in the recent years. It is most known for its **Copy on Write** feature which enables it to make system snapshots in a blink of a an eye and to save a lot of disk space, which can be even saved to a greater extent by enabling built\-in **compression**. Also it lets the user create **subvolumes** which can be individually snapshotted.

```Zsh
# Find the efi partition with fdisk -l or lsblk. For me it's /dev/nvme0n1p1 and format it.
mkfs.fat -F 32 /dev/nvme0n1p1

# Find the root partition. For me it's /dev/nvme0n1p2 and format it. I will use BTRFS.
mkfs.btrfs /dev/nvme0n1p2

# Mount the root fs to make it accessible
mount /dev/nvme0n1p2 /mnt
```

<br>

## Disk mounting

I will lay down the subvolumes on a **flat** layout, which is overall superior in my opinion and less constrained than a **nested** one. What's the difference ? If you're interested [this section of the old sysadmin guide](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/SysadminGuide.html#Layout) explains it.

```Zsh
# Create the subvolumes, in my case I choose to make a subvolume for / and one for /home. Subvolumes are identified by prepending @
# NOTICE: the list of subvolumes will be increased in a later release of this guide, upon proper testing and judgement. See the "Things to add" chapter.
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home

# Unmount the root fs
umount /mnt
```

<br>

For this guide I'll compress the btrfs subvolumes with **Zstd**, which has proven to be [a good algorithm among the choices](https://www.phoronix.com/review/btrfs-zstd-compress)  

```Zsh
# Mount the root and home subvolume. If you don't want compression just remove the compress option.
mount -o compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home
```

<br>

Now we have to mount the efi partition. In general there are 2 main mountpoints to use: `/efi` or `/boot` but in this configuration i am **forced** to use `/efi`, because by choosing `/boot` we could experience a **system crash** when trying to restore `@` _\( the root subvolume \)_ to a previous state after kernel updates. This happens because `/boot` files such as the kernel won't reside on `@` but on the efi partition and hence they can't be saved when snapshotting `@`. Also this choice grants separation of concerns and also is good if one wants to encrypt `/boot`, since you can't encrypt efi files. Learn more [here](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points)

```Zsh
mkdir -p /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi
```

<br>

## Packages installation  

```Zsh
# This will install some packages to "bootstrap" methaphorically our system. Feel free to add the ones you want
# "base, linux, linux-firmware" are needed. If you want a more stable kernel, then swap linux with linux-lts
# "base-devel" base development packages
# "git" to install the git vcs
# "btrfs-progs" are user-space utilities for file system management ( needed to harness the potential of btrfs )
# "grub" the bootloader
# "efibootmgr" needed to install grub
# "grub-btrfs" adds btrfs support for the grub bootloader and enables the user to directly boot from snapshots
# "inotify-tools" used by grub btrfsd deamon to automatically spot new snapshots and update grub entries
# "timeshift" a GUI app to easily create,plan and restore snapshots using BTRFS capabilities
# "amd-ucode" microcode updates for the cpu. If you have an intel one use "intel-ucode"
# "vim" my goto editor, if unfamiliar use nano
# "networkmanager" to manage Internet connections both wired and wireless ( it also has an applet package network-manager-applet )
# "pipewire pipewire-alsa pipewire-pulse pipewire-jack" for the new audio framework replacing pulse and jack. 
# "wireplumber" the pipewire session manager.
# "reflector" to manage mirrors for pacman
# "zsh" my favourite shell
# "zsh-completions" for zsh additional completions
# "zsh-autosuggestions" very useful, it helps writing commands [ Needs configuration in .zshrc ]
# "openssh" to use ssh and manage keys
# "man" for manual pages
# "sudo" to run commands as other users
pacstrap -K /mnt base base-devel linux linux-firmware git btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift vim networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber reflector zsh zsh-completions zsh-autosuggestions openssh man sudo
```

<br>

## Fstab  

```Zsh
# Fetch the disk mounting points as they are now ( we mounted everything before ) and generate instructions to let the system know how to mount the various disks automatically
genfstab -U /mnt >> /mnt/etc/fstab

# Check if fstab is fine ( it is if you've faithfully followed the previous steps )
cat /mnt/etc/fstab
```

<br>

## Context switch to our new system  

```Zsh
# To access our new system we chroot into it
arch-chroot /mnt
```

<br>

Git clone and run base-uefi.sh
```Zsh
  git clone https://github.com/ob3rg/arch-basic
  cd arch-basic
  chmod +x base-uefi.sh
  ./base-uefi.sh
```

<br>

## Grub configuration  

Now I'll [deploy grub](https://wiki.archlinux.org/title/GRUB#Installation)  

## Unmount everything and reboot 

```Zsh
# Exit from chroot
exit

# Unmount everything to check if the drive is busy
umount -R /mnt

# Reboot the system and unplug the installation media
reboot

# Now you'll be presented at the terminal. Log in with your user account, for me its "mjkstra".

# Enable and start the time synchronization service
timedatectl set-ntp true
```

<br>

## Automatic snapshot boot entries update  

Each time a system snapshot is taken with timeshift, it will be available for boot in the bootloader, however you need to manually regenerate the grub configuration, this can be avoided thanks to `grub-btrfs`, which can automatically update the grub boot entries.  

Edit the **`grub-btrfsd`** service and because I will rely on timeshift for snapshotting, I am going to replace `ExecStart=...` with `ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto`. If you don't use timeshift or prefer to manually update the entries then lookup [here](https://github.com/Antynea/grub-btrfs)  

```Zsh 
sudo systemctl edit --full grub-btrfsd

# Enable grub-btrfsd service to run on boot
sudo systemctl enable grub-btrfsd
```

<br>

## Aur helper and additional packages installation  

To gain access to the arch user repository we need an aur helper, I will choose yay which also works as a pacman wrapper \( which means you can use yay instead of pacman \). Yay has a CLI, but if you later want to have an aur helper with a GUI you can install [`pamac`](https://gitlab.manjaro.org/applications/pamac) \( a Manjaro software, so use at your own risk \), **however** note that front\-ends like `pamac` and also any store \( KDE discovery, Ubuntu store etc. \) are not officially supported and should be avoided, because of the high risk of performing [partial upgrades](https://wiki.archlinux.org/title/System_maintenance#Partial_upgrades_are_unsupported). This is also why later when installing KDE, I will exclude the KDE discovery store from the list of packages.  

To learn more about yay read [here](https://github.com/Jguer/yay#yay)  

> Note: you can't execute makepkg as root, so you need to log in your main account. For me it's mjkstra

```Zsh
# Install yay
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# Install "timeshift-autosnap", a configurable pacman hook which automatically makes snapshots before pacman upgrades.
yay -S timeshift-autosnap
```

> Learn more about timeshift autosnap [here](https://gitlab.com/gobonja/timeshift-autosnap)

<br>

## Finalization

```Zsh
# To complete the main/basic installation reboot the system
reboot
```

> After these steps you **should** be able to boot on your newly installed Arch Linux, if so congrats !  

> The basic installation is complete and you could stop here, but if you want to to have a graphical session, you can continue reading the guide.

<br>

# Video drivers

In order to have the smoothest experience on a graphical environment, **Gaming included**, we first need to install video drivers. To help you choose which one you want or need, read [this section](https://wiki.archlinux.org/title/Xorg#Driver_installation) of the arch wiki.  

> Note: skip this section if you are on a Virtual Machine

<br>

## Amd  

For this guide I'll install the [**AMDGPU** driver](https://wiki.archlinux.org/title/AMDGPU) which is the open source one and the recommended, but be aware that this works starting from the **GCN 3** architecture, which means that cards **before** RX 400 series are not supported. _\( I have an RX 5700 XT \)_  

```Zsh

# What are we installing ?
# mesa: DRI driver for 3D acceleration.
# xf86-video-amdgpu: DDX driver for 2D acceleration in Xorg. I won't install this, because I prefer the default kernel modesetting driver.
# vulkan-radeon: vulkan support.
# libva-mesa-driver: VA-API h/w video decoding support.
# mesa-vdpau: VDPAU h/w accelerated video decoding support.

sudo pacman -S mesa vulkan-radeon libva-mesa-driver mesa-vdpau
```

<br>

## Nvidia  

In summary if you have an Nvidia card you have 2 options:  

1. [**NVIDIA** proprietary driver](https://wiki.archlinux.org/title/NVIDIA)
2. [**Nouveau** open source driver](https://wiki.archlinux.org/title/Nouveau)

The recommended is the proprietary one, however I won't explain further because I don't have an Nvidia card and the process for such cards is tricky unlike for AMD or Intel cards. Moreover for reason said before, I can't even test it.

<br>

## Intel

Installation looks almost identical to the AMD one, but every time a package contains the `radeon` word substitute it with `intel`. However this does not stand for [h/w accelerated decoding](https://wiki.archlinux.org/title/Hardware_video_acceleration), and to be fair I would recommend reading [the wiki](https://wiki.archlinux.org/title/Intel_graphics#Installation) before doing anything.

<br>

# Setting up a graphical environment

I'll provide 2 options:  

1. **KDE-plasma**  
2. **Hyprland**

On top of that I'll add a **display manager**, which you can omit if you don't like ( if so, you have additional configuration steps to perform ).  

<br>

