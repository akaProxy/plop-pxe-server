# PLOP PXE SERVER

A Short bash script to set up a pxe server on a Raspberry Pi or any other 
hardware that has a Debian based OS.

The script installs syslinux, dnsmasq and then downloads a copy of the 
Plop system files from the main site to a created tftp folder used by 
dnsmasq. This makes editing of these files easier as you would not have 
to worry about remastering the filesystem to accomplish this.  

The Plop boot manager is designed to enable computers without the ability to 
to boot USB/Disc devices.

It also comes with the Plop Linux OS as a boot option. For more information
about plop go the main website http://www.plop.at/


To install run as ROOT ./pps.sh

## VARIABLES 

PIIP - the IP address of your device/rpi

Defaults:

eth0    10.0.0.1  
netmask 255.255.255.0 



nightowlconsulting.com
