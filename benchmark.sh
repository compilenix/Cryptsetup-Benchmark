#!/bin/bash
echo
path_started_at=$(pwd);
ramdisk_name="tmpfs_ramdisk_cryptsetup_test";
ramdisk_size="1250M";
testfile_size="1G"; # Has to be LESS than $ramdisk_size !!
cryptsetup_volume_name="cryptsetuptest";
cryptsetup_mount_folder_name="crypt_test";
cryptsetup_args_cipher="aes-xts-plain64:sha256";
cryptsetup_args_keysize="512";
cryptsetup_args_hash_digest="sha256";


uname -a;
cat /proc/crypto | grep xts | grep aes | grep driver --color=no;
#cryptsetup benchmark;
mkdir -pv "/mnt/${ramdisk_name}" \
&& mount -v -t tmpfs -o size="${ramdisk_size}" tmpfs "/mnt/${ramdisk_name}" \
&& cd "/mnt/${ramdisk_name}" \
&& {
    truncate -s "${ramdisk_size}" "${cryptsetup_volume_name}.img" && mkdir -pv "${cryptsetup_mount_folder_name}" && echo -n "password" | cryptsetup -v -q -c "${cryptsetup_args_cipher}" -s "${cryptsetup_args_keysize}" -h "${cryptsetup_args_hash_digest}" luksFormat "${cryptsetup_volume_name}.img" - \
    && {
        cryptsetup luksDump "${cryptsetup_volume_name}.img" | grep --color=no -iE 'Cipher name|Cipher mode|Hash spec|Payload offset|MK bits' \
        && echo -n "password" | cryptsetup luksOpen "${cryptsetup_volume_name}.img" "${cryptsetup_volume_name}" - \
        && mkfs.xfs -L "${cryptsetup_mount_folder_name}" "/dev/mapper/${cryptsetup_volume_name}" >/dev/null \
        && mount -v "/dev/mapper/${cryptsetup_volume_name}" "${cryptsetup_mount_folder_name}" \
        && cd "${cryptsetup_mount_folder_name}" \
        && dd conv=fsync bs="${testfile_size}" if=/dev/zero of=./zero.bin count=1 \
        && sleep 1 \
        && dd conv=fsync bs="${testfile_size}" if=/dev/zero of=./zero.bin count=1 \
        && sleep 1 \
        && dd conv=fsync bs="${testfile_size}" if=/dev/zero of=./zero.bin count=1 \
        && sleep 1;
    }
    cd ..;
    umount -v "${cryptsetup_mount_folder_name}";
    cryptsetup luksClose "${cryptsetup_volume_name}";
}
cd "${path_started_at}";
umount -v "/mnt/${ramdisk_name}";
rmdir -v "/mnt/${ramdisk_name}";
