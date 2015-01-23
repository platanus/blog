---
title: Use an ODROID-C1 to drive your wall dashboard
layout: post
author: blackjid
categories: 
  - dashboard
  - odroid
  - raspberry-pi
  - dashing
---

I originally wrote this as a guide to get a dashboard working with a raspberry-pi. The problem was that I wanted to run my dashboard with the chromium browser to have al the props a modern browser has. But the raspberry-pi wasn't up the task. The dashboard with the pi was unstable and very slow.

As a second alternative the pi, I tryied a android stick. The advantages were that you can find dual or quad core stick with android that support full hardware acceleration. May be I picked to wrong one, but at the end the kernel was limited to 720p and our dashboard was 1080p and it look really awefull. Also android is not as nearly tweakeably as a bare linux OS.

Finally I went to the brand new ODROID-C1, is small, cheap (US$35, plus all the necessary accesories), it has a quad core processor, 1GB ram, and they provide a special version of Ubuntu 14.04 that runs very smooth on it, all hardware accelerated by the way. And, for now, is working very well.

Here is what I did to have a autostart, no desktop, full screen dashboard.

## You'll need

+ Odroid C1 with ubuntu/linux SD or MMC card
+ Wifi stick (optional)

Connect your odroid to the screen and to the network. You can use a keyboard and mouse but you can also do everything thought an ssh connection.

```shell
ssh odroid@<odroid-ip>
odroid@<odroid-ip>s password: odroid
```

### Use odroid utility for increase your partition size

Once you flashed your memory (sd or mmc), you'll get a 4.6GB partition aprox., regarles the size of your memory. We can increase the partition size, and that way be able to use the full size of your memory.

Run the odroid utility
```shell
sudo odroid-utility.sh
```

Then choose, the **resize partition** option.

### Setting up NTP

This will sync the time time with ubuntu ntp server

```shell
sudo apt-get install ntpdate
sudo ntpdate -u ntp.ubuntu.com

# Change your timezone if necessary
echo "America/Santiago" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata
```

### Update the OS

```shell
sudo apt-get update
sudo apt-get -y upgrade
```

### Change the name of your device

```shell
echo "dashboard" | sudo tee /etc/hostname
echo "127.0.0.1  dashboard" | sudo tee -a /etc/hosts
```

### Disable lightdm desktop manager

We want to boot directly to our dashboard, for that we will disable the default desktop manarger with the following command

```shell
echo "manual" | sudo tee -a /etc/init/lightdm.override
```

### Configure your monitor resolution

Uncomment the resolution you want in the `/media/boot/boot.ini` file

```shell
# setenv m "vga"          # VGA 640x480
# setenv m "480p"         # 480p 720x480
# setenv m "576p"         # 576p 720x576
# setenv m "800x480p60hz" # WVGA 800x480
# setenv m "svga"         # Super VGA 800x600
# setenv m "xga"          # XGA 1024x768
# setenv m "720p"         # 720p 1280x720
# setenv m "800p"         # 800p(WXGA) 1280x800
# setenv m "sxga"         # SXGA 1280x1024
setenv m "1080p"          # 1080P 1920x1080
# setenv m "1920x1200"    # 1920x1200
```

If you have problems with the `overscan`, black lines on the edges of the screen that may produce that your images gets cropped.
The best solution is disable overscan in the tv. *Check the display menu options (it may be called "just scan", "screen fit", "HD size", "full pixel", "unscaled", "dot by dot", "native" or "1:1)*

### Configure Lan

Run this command to get the name of you network interfaces. In my odroid I got `eth1` for the wired ethernet port and `wlan2` for my wifi USB stick.

```shell
ifconfig
```

#### Using ethernet

Add the following to `/etc/network/interfaces.d/eth1`

```shell
auto eth1
iface eth1 inet dhcp
```

#### Using wifi

You'll need a wifi stick for this. Plug the stick and run the following command to check if the stick was detected.


This will list your network interfaces, and you should search for one named like `wlan2`

Now you need to edit the configuration to setup dhcp and wich SSDI and password use to connect to the network

Create a file name `wlan2` into `/etc/network/interfaces.d` and add the following code at the end

```
auto wlan2
allow-hotplug wlan2
iface wlan2 inet dhcp
        wpa-ssid "ssid"
        wpa-psk "password"
```

Finally remove the network manager, this is to be able to configure our network interfaces from the command line, instead of the ubuntu ui.

```shell
sudo apt-get remove network-manager
```

## Start the browser on boot

### Install Chromium

First, you’ll want to install Chromium.

```shell
sudo apt-get install -y chromium-browser
```

Configure chromium so it start maximized to the size of our tv

Edit `~/.config/chromium/Default/Preferences` and edit the following section

```json
...
"browser": {
  ...,
  "window_placement": {
     "bottom": 1080,
     "left": 0,
     "maximized": true,
     "right": 1920,
     "top": 0,
     "work_area_bottom": 1080,
     "work_area_left": 0,
     "work_area_right": 1920,
     "work_area_top": 0
  }
  ...
}
```

### X server

Install x11 server utils to control video parameters and unclutter to remove the mouse from over our dashboard

```shell
sudo apt-get install -y x11-xserver-utils unclutter
```

Create a script in `/home/odroid/dashboard` with the code that will run chromium in kiosk mode

```shell
#!/bin/sh
chromium-browser \
--kiosk \
--disable-restore-session-state \
--start-maximized \
--incognito \
http://dash.platan.us
```

Add execution permition to the script

```shell
chmod +x /home/odroid/dashboard
```

Add this code to your `~/.xinitrc`

```shell
unclutter &

xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device

exec /home/odroid/dashboard
```

To start on boot we will create a init script in `/etc/init.d/dashboard`

```shell
sudo touch /etc/init.d/dashboard
sudo chmod 755 /etc/init.d/dashboard
```

Now add this code to the script

```shell
#! /bin/sh
# /etc/init.d/dashboard
case "$1" in
  start)
    echo "Starting dashboard"
    # run application you want to start
    /bin/su odroid -c xinit
    ;;
  stop)
    echo "Stopping dashboard"
    # kill application you want to stop
    killall xinit
    ;;
  *)
    echo "Usage: /etc/init.d/dashboard {start|stop}"
    exit 1
    ;;
esac

exit 0
```

We need to register the script to start on boot as kiosk

```shell
sudo update-rc.d dashboard defaults
```

Now you need to give any user permision to run an x application, edit the file `/etc/X11/Xwrapper.config` and change the value there to `anybody`

```
allowed_users=anybody
```

## Troubleshooting

### Your ethernet connection is too slow
There is a problem using a 1000 link with some switches. Odroid kernel v1.2 defaults to 100mbps, but you can limit this in 1.1 adding this line to your `/etc/rc.local`

```
ethtool -s eth0 speed 100 duplex full autoneg off
```

## References
- http://www.fusonic.net/en/blog/2013/07/31/diy-info-screen-using-raspberry-pi-dashing/
- http://askubuntu.com/questions/139014/how-to-disable-lightdm
- http://odroid.com/dokuwiki/doku.php?id=en:c1_tips
- http://odroid.com/dokuwiki/doku.php?id=en:c1_building_kernel
- https://github.com/Pulse-Eight/libcec
