#!/bin/bash
#
# MAKE PXE SERVER
#
#The network mask is set to a default of /24 or 255.255.255.0 if yo wish to modify this go to -> line ????
PIIP='10.0.0.1' # this will determine the ip address of the rpi's eth0 interface and thus the rest of the network settings it uses.
# use /24 Network Masks least you make have to edit this script.
#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
NMSK='255.255.255.0'
IFS=. read -r if1 if2 if3 if4 <<< "$PIIP"
IFS=. read -r msk1 msk2 msk3 msk4 <<< "$NMSK"
NETIP=$(printf "%d.%d.%d.%d\n" "$((if1 & msk1))" "$((if2 & msk2))" "$((if3 & msk3))" "$((if4 & msk4))")

IFS=. read -r ip1 ip2 ip3 ip4 <<< "$PIIP"
DHCPL=$(printf "%d.%d.%d.%d\n" "$((ip1))" "$((ip2))" "$((ip3))" "$((if4 + 4 ))")

IFS=. read -r ip1 ip2 ip3 ip4 <<< "$PIIP"
DHCPH=$(printf "%d.%d.%d.%d\n" "$((ip1))" "$((ip2))" "$((ip3))" "$((if4 + 99 ))")


# func requires arguments (user name)
check_user() {
   if [ "$(whoami)" != "$1" ]; then
      printf "\nyou need to be root\nexiting....\n\n"
      exit 1
   fi
}

tstamp() {
   date +"%F"_"%H":"%M"
}

# func requires aguments (full path/file name) and tstamp() func ****
make_runlog() {
   touch $1
   printf "\nscript run on\n"$(tstamp)"\n" > $1
}

check_tubes() {
   printf "\nChecking your tubes..."
   if ! ping -c 1 google.com > /dev/null 2>&1  ; then
      if ! ping -c 1 yahoo.com > /dev/null 2>&1  ; then
         if ! ping -c 1 bing.com > /dev/null 2>&1 ; then
             clear
             printf "\n\nDo you have an internet connection???\n\n"
             exit 2
         fi
      fi
   fi
   printf "\n\ntubes working....\n\n"
}

# func requires aguments ****
check_website() {
   if ! curl -sSf $1 > /dev/null 2>&1 ; then
      printf "\nYou seem to have a internet connection but\nCannot communicate "$1"..."
      exit 3
   fi
}

# func requires aguments ****
get_aptpkg() {
   if ! apt-get -y install $1; then
       printf "\n\nAPT failed to install "$1", are your repos working?\nexiting...\n\n"
       exit 4
   fi
}

# func requires aguments 1:(dowload directory) 2:(url) ****
use_wget() {
   printf "\nFetching from "$2"...\n\n"
   if ! wget --tries=4 --read-timeout=20 -P $1 $2 ; then
       printf "\nSomething went wrong downloading from "$2" \nexiting...."
       exit 5
   fi
}

get_permission() {
 while true; do
     read answer
     case $answer in
          [Yy] ) break;;
          [Yy][eE][sS] ) break;;
          [nN] ) printf "\n Exiting Now \n"; exit;;
          [Nn][oO] ) printf "\n Exiting Now \n"; exit;;
            *  ) printf "\n Not Valid, Answer y or n\n";;
     esac
 done
}

printf "\nTo run this script properly it need to run as root and have a working internet connection."
printf "\nThis script will download necessary plop system files from the plop website"
printf "\nit will also install the apt packages dnsmasq and syslinux to create a working pxe server."
printf "\nThe network configuration of your eth0 interface on your rpi will be modified\nacording to the above variables."
printf "\n\nWARNING---WARNING---WARNING\n"
printf "\nIf you are using the eth0 connection for your main internet connection this will most likely"
printf "\ndisable your internet connection\n\n You may have to connect to the internet over WiFi or use a usb to ethernet adapter.\n"
printf "\nThe program wicd-curses may prove usefull for establising a wireless connection in your rpi with ease through ssh."
printf "\nCONTINUE? (y/n)\n\n"

get_permission
check_user root
check_tubes

if [ ! -e /var/log/rpi-pxe ]; then

   apt-get update
   get_aptpkg dnsmasq
   get_aptpkg syslinux-common

 else

   printf "\nYou ran this script before...\nto continue it will erase the /tftpboot folder"
   printf "\nalong with the interface and dnsmasq configuration files."
   printf "\nYou need to perform a backup if any of the files are important to you."
   printf "\nCONTINUE? (y/n)?\n\n"

   get_permission
   rm -r /tftpboot

fi

mkdir -p /tftpboot/{pxelinux.cfg,ploplinux-netboot}
cp /usr/lib/syslinux/{memdisk,menu.c32,vesamenu.c32,pxelinux.0} /tftpboot

#Begin writing to pxelinux.cfg/default
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

cat > /tftpboot/pxelinux.cfg/default <<EOL

default vesamenu.c32
prompt 0
timeout 100

menu title Welcome to Plop Linux

menu color border       37;40   #00000000 #00000000 none
menu color title        1;37;40 #00000000 #00000000 none
menu color tabmsg       40;37   #88888888 #00000000 none
menu color sel          1;37;42 #ffffffff #ff808080 none
menu color unsel        1;40;32 #ff00ff00 #00000000 none


menu separator

label hd
    menu label Boot harddisk
    localboot 0x80
    append -

menu separator

label plp
    menu label Plop Boot Manager
    linux ploplinux-netboot/syslinux/plop/plpbt.bin

label plpkexec
    menu label PlopKexec Boot Manager
    kernel ploplinux-netboot/syslinux/plop/plopkexec

label Memtest
    menu label Memtest
    kernel ploplinux-netboot/memtest

menu separator

# boot from TFTP
label linux-tftp
    menu label Plop Linux - TFTP
    kernel ploplinux-netboot/syslinux/kernel/bzImage
    append initrd=ploplinux-netboot/syslinux/kernel/initramfs.gz vga=1 tftpboot=$PIIP|ploplinux-netboot/tftpfilelist dir=/ploplinux-netboot/ploplinux

#------------------------------------------------------------------------------------------------------------------------------------------
# To use the option below you must have a working web server on the pi hosting the necessary files
#
#boot from HTTP
#label linux-http
#    menu label Plop Linux - HTTP
#    kernel ploplinux-netboot/syslinux/kernel/bzImage
#    append initrd=ploplinux-netboot/syslinux/kernel/initramfs.gz vga=1 url=http://$PIIP/ploplinux-netboot|/webfilelist

EOL
#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
#Finished creating pxelinux.cfg/defualt


# Check if archive already downloaded
if [ ! -e /tmp/tgz/ploplinux-4.3.0-x86_64.tar.gz ]; then
  mkdir /tmp/tgz > /dev/null 2>&1
  check_website http://download.plop.at
  use_wget /tmp/tgz http://download.plop.at/ploplinux/4.3.0/live/ploplinux-4.3.0-x86_64.tar.gz
fi

# extract tar gzip archive, delete archive if extraction fails
if ! tar zxvf /tmp/tgz/ploplinux-4.2.2.tgz -C /tmp/tgz/; then
  printf "\n\ntargz archive failed to extract, possible file corruption\nRe-download it"
  printf "\nby running script again.\n\n"
  printf "\ncleaning up temp download folder\n...."
  rm -r /tmp/tgz
  exit 6
fi

# move extracted files from archive to tftp folder
cp -r /tmp/tgz/ploplinux-4.2.2/* /tftpboot/ploplinux-netboot/
rm -r /tmp/tgz/ploplinux-4.2.2/
printf "You will need to use chmod +x /media/ploplinux-netboot/ploplinux/bin/*\nto be able to use the plophelp command\n\n" >> /tftpboot/ploplinux-netboot/ploplinux/bin/welcome.txt

# Create tftpfilelist for use by the pxe boot options
cd /tftpboot
find ploplinux-netboot > ploplinux-netboot/tftpfilelist

printf "\nWriting to /etc/network/interfaces ....\n"
cat > /etc/network/interfaces << EOL
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $PIIP
netmask $NMSK
network $NETIP

EOL

printf "\nCreating/writing to /etc/dnsmasq.conf ....\n"
cat > /etc/dnsmasq.conf << EOL
enable-tftp
tftp-root=/tftpboot
dhcp-boot=pxelinux.0
interface=eth0
dhcp-range=eth0,$DHCPL,$DHCPH,$NMSK,12h
log-queries
log-facility=/var/log/dnsmasq.log
server=208.67.222.222
no-resolv

EOL

# wrapping up....
ifdown eth0 && ifup eth0

if ! service dnsmasq stop; then
     killall dnsmasq
      if ! service dnsmasq start; then
           printf "\n\nSomething is probably using port 53 use"
           printf "\nsudo netstat -tapen | grep ":53""
           printf "\nto find out which program is causing problems"
           exit 7
      fi
 else
    service dnsmasq start
fi

make_runlog /var/log/rpi-pxe
printf "\nScript finished successfully\nexiting...\n\n"

exit 0
