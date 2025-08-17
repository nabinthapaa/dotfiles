# Introduction
Custom config for  Hyprland setup with arch linux

## Installation 
```
 curl -fsSL https://raw.githubusercontent.com/nabinthapaa/dotfiles/refs/heads/main/installations/install.sh | bash
```
## Large size /boot 
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

