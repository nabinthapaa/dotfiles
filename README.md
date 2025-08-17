# Introduction
My custom arch linux installation and setup using simple bash script 

## Arch install Steps
- Dual boot with windows 
    - Make free space to install arch 
    - Boot to iso 
    - Connect to wifi or ethernet 
        ```bash
        rfkill ublock wlan
        iwctil --passphrase <passphrase> device list
        iwctil --passphrase <passphrase> station <device_name> connect ssid

        archinstall

        ```
    - In disk configuration 
        - mount `/boot/efi` to windows efi partition 
        - mount `/boot` to free space creating a desired partition size 
        - if swap needed make partition with linux-swap size equal to greater than RAM size
        - mount / to remaining size
    - In Profile
        - profile -> desktop -> hyprland
        - display-manager -> sddm
        - graphics -> nvidia
    - If swap add turn of `swap on zram`

## Large size /boot or custom boot size added
 - After setting up `/boot` to have large size say 2GiB 
 - Run `lsblk` to see partition
 - chroot into arch using 
    ```bash 
    #Replace X with partition number for lsblk
    mount  /dev/nvme0n1pX /mnt #root partition 
    mount /dev/nvme0n1pX /mnt/boot #custom boot file 
    mount /dev/nvme0n1pX /mnt/boot/efi #Efi partition 

    arch-chroot /mnt 

    # Rebuild grub
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB  
    grub-mkconfig -o /boot/grub/grub.cfg 

    #check if grub is shown in menu
    efibootmgr -v 

    ```
    - If Grub is not listed 
        ```bash
        cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/Boot/bootx64.efi

        ```
## Installation 
This will install bunch of linux tools and configuration files to files to begin with
```bash
curl -fsSL https://raw.githubusercontent.com/nabinthapaa/dotfiles/refs/heads/main/installations/install.sh | bash
```

