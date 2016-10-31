#!/bin/sh
# Target: Automatic mount cdrom device and run configuration script
# Application platform: CentOS RedHat FreeBSD Ubuntu Debian
# Update content: Script integrate together with CentOS FreeBSD Ubuntu platform, and some optimization.
# Update date: 2016/9/27
# Author: niaoyun.com
# Tel: 400-688-3065
# Version: 1.38

# system path
home="/opt/vminit"
log=$home/autovm.log
tmp=$home/autovm.tmp
script=vminit.sh
mount_dir=/mnt/cdrom
kerver=`uname -s`

exec 1>$log 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S')  autovm script starting run" !

[ -d $mount_dir ] || mkdir -p $mount_dir

Linux ()
{
# find the file from cdrom
real_cdrom=`ls -l /dev/cdrom* | grep "/dev/cdrom" | awk -F "->" '{printf $2}' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | awk -F " " '{printf $1}'`

if [ -n "$real_cdrom" ]
then
    	mount "/dev/${real_cdrom}" "${mount_dir}" && echo "mounted cdrom success" !

  if [ -f $mount_dir/$script ]
	then
		if [ -f $home/$script ]
		then
			if [ ! $(cksum $home/$script | awk '{ print $1 }') == $(cksum $mount_dir/$script | awk '{ print $1 }') ]
			then
				rm -f $home/$script
				cp "$mount_dir/$script" "$home" && echo "copy vminit.sh file success" && umount $mount_dir
				chmod 744 $home/$script
				$home/$script
			fi
		else
			cp -f "$mount_dir/$script" "$home" && echo "copy vminit.sh file success" && umount $mount_dir
			chmod 744 $home/$script
			$home/$script
		fi

	else
		echo "no vminit.sh file in cdrom device" !
	fi

fi

}

FreeBSD ()
{
if [ -c /dev/cd0 ]
then
	mount -t cd9660 /dev/cd0 $mount_dir && echo "mount cdrom device success"
	if [ -f $mount_dir/$script ]
	then
		if [ -f $home/$script ]
		then
                	echo "PS_MOD_LAST=$(grep '^PS_MOD' $home/$script | awk -F'=' '{ print $2 }')" > $tmp
                	rm -f $home/$script
		fi

		cp -f "$mount_dir/$script" "$home" && echo "copy vminit.sh file success" && umount $mount_dir
		chmod 744 $home/$script
		$home/$script

	else
		echo "no vminit.sh file in cdrom device"
	fi

fi

}

# Starting run

case $kerver in

Linux)
	Linux;;
FreeBSD)
	FreeBSD;;
*)
	echo "This platform is not supported" !!;;
esac

echo "$(date '+%Y-%m-%d %H:%M:%S')  autovm script ended" !

rm -f $tmp

exit 0
