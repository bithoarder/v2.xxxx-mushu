# V2.xxx - Mushu - Raspberry install #

How the raspberry is set up and configured.

## MainSailOS ##

Copy MainSailOS image to sd card.

## Pre boot changes to fs ##

Mount boot fs on desktop.

```sh
touch "/media/$USER/boot/ssh"

cat >"/media/$USER/boot/wpa_supplicant.conf"  <<EOF
country=DK
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
network={
    ssid="FIXME-FIXME-FIXME"
    psk="FIXME-FIXME-FIXME"
    key_mgmt=WPA-PSK
}
EOF

sudo umount /media/$USER/boot
```

Configure static ip and DNS records for the raspberry pi, then boot the pi.

```sh
ssh pi@mushu

sudo bash -c "echo 'pi ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/010_pi-nopasswd && chmod 0440 /etc/sudoers.d/010_pi-nopasswd"

sudo passwd pi
mkdir .ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6/z90MGCKLVrUD9mA6DVIQDACqqBz50eNaV8psA1JnpKP1zwCC8okFtzkH/0w6gPVxOhLD8WHvfXEZiustR6qaXItFi1KUpKeNOVcR8Z19XVSh0DCxLvmQ7Hrw+OC+rZHgjIVwo3pGDkUpJiei+qRgJnXKuf08Lj0sDjslQXuV10xFmxPXj/3AEuHRIarNexe3D7zKY8LzyCfwsNchowdnLtj1c1azSMYK891AKyTC3jDmDtpWPFlQa0el4XWjGFkV0puP340dZ/bS4BviBDNZF7e7/xB6ePjX3ImceAdmtfw/Xr2hNFls7hOgsEOsrdJfrhEr4XzvocBovTvteqqw== mushu" >>.ssh/authorized_keys

sudo bash -c "echo mushu >/etc/hostname"

sudo raspi-config # set timezone, enable camera ...

sudo apt update && sudo apt upgrade -y
```

## Samba ##

Export the klipper_config dir, so that it can be easily edited from a different computer.  

```sh
sudo apt install samba -y

sudo bash -c "cat >>/etc/samba/smb.conf" <<EOF
[gcode]
  path = /home/pi/gcode_files/
  guest ok = no
  read only = no
  browsable = yes
  create mask = 0666
  directory mask = 0777
[config]
  path = /home/pi/klipper_config/
  guest ok = no
  read only = no
  browsable = yes
  create mask = 0666
  directory mask = 0777
EOF

sudo smbpasswd -a pi
sudo systemctl restart smbd.service
```

## ZRam ##

Ram filesystems are used to reduce the wear on the SD card.

https://github.com/ecdye/zram-config

```sh
sudo apt install git -y

git clone --recurse-submodules https://github.com/ecdye/zram-config
cd zram-config
sudo ./install.bash

sudo zram-config "stop"
sudo bash -c "cat >/etc/ztab <<EOF
# swap  alg      mem_limit  disk_size  swap_priority         page-cluster        swappiness
swap    lzo-rle  250M       750M       75                    0                   80
# dir   alg      mem_limit  disk_size  target_dir            bind_dir
dir     lzo-rle  50M        150M       /tmp                  /tmp.bind
#log    alg      mem_limit  disk_size  target_dir            bind_dir            oldlog_dir
log     lzo-rle  50M        150M       /var/log              /log.bind           /opt/zram/old-klipper-logs
log     lzo-rle  50M        150M       /home/pi/klipper_logs /klipper_logs.bind  /opt/zram/oldlog
EOF"
sudo zram-config "start"
```

## Nginx ##

A nginx config with both Fluid and Mainsail.

```sh
sudo rm /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*
```

Push config from desktop:
```sh
(cd config/nginx && tar cvfz - . | ssh mushu "cd /etc/nginx && sudo tar mxvfz - --no-same-owner --no-same-permissions --no-overwrite-dir && sudo systemctl restart nginx && tail -F /var/log/nginx/*.log")
```

## Fluidd ##

```sh
mkdir -p ~/fluidd && cd ~/fluidd && wget -q -O fluidd.zip https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip && unzip fluidd.zip && rm fluidd.zip
```

## Klipper Z-Calibration ##

```sh
cd ~ && git clone https://github.com/protoloft/klipper_z_calibration.git && cd ~/klipper_z_calibration && ./install.sh
```

## Flash control board ##

### SKR Octopus ###

```sh
cd ~/klipper && cp .config-btt-octopus .config && make clean && make -j
sudo bash -c "mount /dev/disk/by-label/MUSHU /mnt/ && cp out/klipper.bin /mnt/FIRMWARE.BIN && umount /mnt && echo done"
```

## Klipper screen ##

https://klipperscreen.readthedocs.io/en/latest/Installation/

```sh
git clone https://github.com/jordanruthe/KlipperScreen.git
cd ~/KlipperScreen
./scripts/KlipperScreen-install.sh
```
