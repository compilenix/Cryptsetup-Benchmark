#!/bin/bash
echo -e "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND.\nRead and understand the code/script BEFORE you run this! (press enter to continue or control+c to return to safety)" 1>&2;
read;

path_started_at=$(pwd);
ramdisk_name="tmpfs_ramdisk_cryptsetup_test";
ramdisk_size="1250M";
testfile_size="1G"; # Has to be LESS than $ramdisk_size !!
cryptsetup_volume_name="cryptsetuptest";
cryptsetup_mount_folder_name="crypt_test";
cryptsetup_args_cipher="aes-xts-plain64:sha256";
cryptsetup_args_keysize="512";
cryptsetup_args_hash_digest="sha256";


trap clean_up SIGHUP SIGINT SIGTERM;
echo "start doing stuff... it's safe to interupt this at any time (control+c)." 1>&2;

# print all commands executed to stdout and start codeblock which redirects stderr to stdout
set -x;
{

function clean_up() {
    cd "${path_started_at}";
    umount -v "/mnt/${ramdisk_name}/${cryptsetup_mount_folder_name}";
    cryptsetup luksClose "${cryptsetup_volume_name}";
    umount -v "/mnt/${ramdisk_name}";
    rmdir -v "/mnt/${ramdisk_name}";
    exit;
}

uname -a;

# get loaded aes-xts kernel modules/drivers
cat /proc/crypto | grep xts | grep aes | grep driver --color=no;

# get supported x86 instruction flags
cat /proc/cpuinfo | grep flags | head -1;

cryptsetup benchmark;

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
    }
clean_up;
} 2>&1;

# vim: tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
