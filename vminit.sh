#!/bin/sh
# Target: Automatic configuration hostname,password,network,datastore and install cloudsafe client for VMware virtual machine.
# Application platform: CentOS FreeBSD Ubuntu Debian OpenSUSE
# Update date: 2017/3/1
# Version: 1.90

HN_MOD={HN_MOD}		# hostname
PS_MOD={PS_MOD}		# password
IP_MOD={IP_MOD}		# ipaddress
MS_MOD={MS_MOD}		# netmask
GW_MOD={GW_MOD}		# gateway
DN_MOD={DN_MOD}		# dnsserver
FM_MOD={FM_MOD}		# whether partition

# Examples like this
#HN_MOD=niaoyun10000
#PS_MOD=niaoyun.0
#IP_MOD=192.168.80.203,10.98.80.203
#MS_MOD=255.255.255.0,255.255.255.0
#GW_MOD=192.168.80.1
#DN_MOD=202.96.134.133,114.114.114.114
#FM_MOD=YES


# system parameter

ch_m=0
ci_m=0
home="/opt/vminit"
log=$home/vminit.log
tmp=$home/vminit.tmp
auto_tmp=$home/autovm.tmp


exec 1>$log 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S')  vminit script starting run" !

# For CentOS or Red Hat System

CentOS ()
{
	# parameters: filename
	time_stamp ()
	{
		if [ $1 ]
		then
        	mod_date=`stat $1 | grep "^Modify" | awk -F. '{print $1}' | awk '{print $2$3}'| awk -F- '{print $1$2$3}'`
        	mod_pre=`echo $mod_date | awk -F: '{print $1}'`
        	mod_minute=`echo $mod_date | awk -F: '{print $2}'`
        	now_pre=`date +%Y%m%d%H`
        	now_minute=`date +%M`

        	if [ $mod_pre == $now_pre ]
        	then
                if [ $mod_minute == $now_minute ]
                then
                    mod=1
                elif [ $(expr $mod_minute + 1) == $now_minute ]
                then
                    mod=1
                else
                    mod=0
                fi
        	else
                mod=0
        	fi
		else
        	echo  "Error,No files have been specified" ! && exit 1

		fi
	}

	# parameters: nicname ipaddress netmask gateway
	network_parameter ()
	{
		echo $1 $2 $3 $4
		if [ $# -lt 3 ]
		then
			echo "error: config_network parameter less than 3" !
			return 1
		fi

		local network_file=/etc/sysconfig/network-scripts/ifcfg-$1

		if [ $(grep -c '^DNS' $network_file) -ge 1 ]
		then
			sed -i '/DNS/d' $network_file
		fi

		if [ $(grep '^DEVICE' $network_file | grep -c "${1}") -eq 0 ] && [ ! "${1}" == "" ]
		then
        	sed -i '/DEVICE/d' $network_file
        	echo DEVICE=${1} >> $network_file
		fi

		macaddress=`cat /sys/class/net/$1/address | tr '[a-z]' '[A-Z]'`

		if [ $macaddress ] && [ $(grep '^HWADDR' $network_file | grep -c $macaddress) -eq 0 ]
		then
			sed -i '/HWADDR/d' $network_file
			echo HWADDR=$macaddress >> $network_file
		fi

		if [ $(grep '^TYPE' $network_file | grep -c "Ethernet") -eq 0 ]
		then
			sed -i '/TYPE/d' $network_file
			echo "TYPE=Ethernet" >> $network_file

		fi

		if [ $(grep '^ONBOOT' $network_file | grep -c 'yes') -eq 0 ]
		then
			sed -i '/ONBOOT/d' $network_file
		    echo "ONBOOT=yes" >> $network_file
		fi

    	if [ $(grep '^BOOTPROTO' $network_file | grep -c 'static') -eq 0 ]
		then
			sed -i '/BOOTPROTO/d' $network_file
    		echo "BOOTPROTO=static" >> $network_file
   		fi

		if [ $(grep '^NM_CONTROLLED' $network_file | grep -c 'no') -eq 0 ]
		then
			sed -i '/NM_CONTROLLED/d' $network_file
        	echo 'NM_CONTROLLED=no' >> $network_file
 		fi

    	if [ $(grep '^PEERDNS' $network_file | grep -c 'no') -eq 0 ]
		then
			sed -i '/PEERDNS/d' $network_file
			echo 'PEERDNS=no' >> $network_file
   		fi

		if [ ! "${2}" == "" ]
		then
			local curr_ip=`grep '^IPADDR' $network_file | grep -oP '\d+\.\d+\.\d+\.\d+'`

			if [ ! "${curr_ip}" == "" ]
			then
    			echo "${1}:current ipaddress is ${curr_ip}" !

				if [ ! "${curr_ip}" == "${2}" ]
				then
        			sed -i '/IPADDR/d' $network_file
        			echo IPADDR=${2} >> $network_file
    				echo "configuration ipaddress for network interface $1 success" !
				fi
			else
        		sed -i '/IPADDR/d' $network_file
				echo IPADDR=${2} >> $network_file
    			echo "configuration ipaddress for network interface $1 success" !
			fi
				
    	fi

    	if [ ! "${3}" == "" ]
		then
    		local curr_netmask=`grep '^NETMASK' $network_file | grep -oP '\d+\.\d+\.\d+\.\d+'`

			if [ ! "${curr_netmask}" == "" ]
			then
    			echo "${1}:current netmask is ${curr_netmask}" !

				if [ ! "${curr_netmask}" == "${3}" ]
				then
       				sed -i '/NETMASK/d' $network_file
       				echo NETMASK=${3} >> $network_file
    				echo "configuration netmask for network interface $1 success" !
				fi
			else
       			sed -i '/NETMASK/d' $network_file
    			echo NETMASK=${3} >> $network_file
    			echo "configuration netmask for network interface $1 success" !
			fi
		fi

    	if [ ! "${4}" == "" ]
		then
    		local curr_gateway=`grep '^GATEWAY' $network_file | grep -oP '\d+\.\d+\.\d+\.\d+'`

			if [ ! "${curr_gateway}" == "" ]
			then
    			echo "${1}:current gateway is ${curr_gateway}"

				if [ ! "${curr_gateway}" == "${4}" ]
				then
       				sed -i '/GATEWAY/d' $network_file
       				echo GATEWAY=${4} >> $network_file
    				echo "configuration gateway for network interface $1 success" !
				fi
			else
       			sed -i '/GATEWAY/d' $network_file
				echo GATEWAY=${4} >> $network_file
    			echo "configuration gateway for network interface $1 success" !
			fi
    	fi

		time_stamp $network_file
		[ $mod == 1 ] && ci_m=1
    	return 0
	}
	

	hostname ()
	{
		if [ $(uname -r | awk -F'-' '{ print $1 }') == "3.10.0" ]
		then
			local curr_hostname=`cat /etc/hostname`

			if [ -n "$HN_MOD" ] && [ "$curr_hostname" != "$HN_MOD" ]
			then 
	    		echo $HN_MOD > /etc/hostname && echo "hostname chang" !
	    		echo -e "127.0.0.1   $HN_MOD\n::1         $HN_MOD" >> /etc/hosts  && echo "hosts file changed" !
				ch_m=1
        	fi
		else
			local curr_hostname=`grep "^HOSTNAME" /etc/sysconfig/network | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`

        	if [ -n "$HN_MOD" ] && [ "$curr_hostname" != "$HN_MOD" ]
			then 
            	sed -i "s/$curr_hostname/$HN_MOD/" /etc/sysconfig/network
            	echo -e "127.0.0.1   $HN_MOD\n::1         $HN_MOD" >> /etc/hosts && echo "hosts file changed" !
				ch_m=1
			fi
		fi

	}


	dnsserver ()
	{
		if [ ! $DN_MOD == "" ]
		then
        	dns1=`echo $DN_MOD | awk -F "," '{ print $1 }'`
            dns2=`echo $DN_MOD | awk -F "," '{ print $2 }'`
            dns3=`echo $DN_MOD | awk -F "," '{ print $3 }'`

            if [ ! $dns1 == "" ] && [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 1p | grep -c $dns1) -eq 0 ]
			then
				echo "nameserver $dns1" > /etc/resolv.conf
                echo "configuration dnsserver1 success" !
			else
				echo "dnsserver1 not change" !
            fi

            if [ ! $dns2 == "" ]
			then
				if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 2 ]
				then
					if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 2p | grep -c $dns2) -eq 0 ]
					then
						curr_nameserver2=`grep "^nameserver" /etc/resolv.conf | sed -n 2p | awk '{ print $2 }'`
						sed -i "s/$curr_nameserver2/$dns2/" /etc/resolv.conf
						echo "nameserver2 $curr_nameserver2 existence" !
                		echo "configuration dnsserver2 success" !
					else
						echo "dnsserver2 not change" !
					fi
				else
                	echo "nameserver $dns2" >> /etc/resolv.conf
                	echo "configuration dnsserver2 success" !
					ci_m=1
                fi

			fi

            if [ ! $dns3 == "" ]
			then
				if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 3 ]
				then
					if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 3p | grep -c $dns3) -eq 0 ]
					then
						curr_nameserver3=`grep "^nameserver" /etc/resolv.conf | sed -n 3p | awk '{ print $2 }'`
						sed -i "s/$curr_nameserver3/$dns3/" /etc/resolv.conf
						echo "nameserver3 $curr_nameserver3 existence" !
                		echo "configuration dnsserver3 success" !
					else
						echo "dnsserver3 not change" !
					fi
				else
                	echo "nameserver $dns3" >> /etc/resolv.conf
                	echo "configuration dnsserver3 success" !
				fi
            fi

            chmod 644 /etc/resolv.conf

			if [ -f /etc/NetworkManager/NetworkManager.conf ]
			then
				if [ $(grep '^dns' /etc/NetworkManager/NetworkManager.conf | grep -c 'none') -eq 0 ]
				then
					echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
				fi
			fi
		fi

	}


	password ()
	{
    	if [ "$PS_MOD" ]
		then
			if [ -f $auto_tmp ]
			then
				. $auto_tmp

				if [ "$PS_MOD_LAST" ]
				then
					if [ ! "$PS_MOD" == "$PS_MOD_LAST" ]
					then
    					echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
					else
						echo "password not change" !
					fi
				else
					echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
				fi
			else
				echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
			fi
    	fi
	}



	restart_service ()
	{
		if [ "$ci_m" -eq 1 ]
		then
			/etc/init.d/network restart
		fi
		
		if [ "$ch_m" -eq 1 ]
		then
			reboot && echo "$(date '+%Y-%m-%d %H:%M:%S')  system will reboot now" !
		fi

		echo "restart service success" !
	}


	datastore ()
	{
		kernel_version=`uname -r | awk -F'-' '{ print $1 }'`

		if [ "$kernel_version" == "2.6.18" ]
		then
			filesystem="ext3"
		elif [ "$kernel_version" == "2.6.32" ]
		then
			filesystem="ext4"
		elif [ "$kernel_version" == "3.10.0" ]
		then
			filesystem="ext4"
		fi

		if [ "$FM_MOD" == "YES" ]
		then
			if [ -b /dev/sdb ]
			then
				if [ -b /dev/sdb1 ]
				then
					if [ $(/sbin/blkid /dev/sdb1  | egrep -c 'ext2|ext3|ext4|xfs') -ge 1 ]
					then
						filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`
					else
						[ -b /dev/sdb1 ] && /sbin/parted -s /dev/sdb rm 1
						/sbin/parted -s /dev/sdb mklabel msdos
						/sbin/parted -s /dev/sdb mkpart primary 0% 100%
                        mkfs -t $filesystem /dev/sdb1 || mkfs -t $filesystem -f /dev/sdb1
					fi
				else
					/sbin/parted -s /dev/sdb mklabel msdos
					/sbin/parted -s /dev/sdb mkpart primary 0% 100%
                    mkfs -t $filesystem /dev/sdb1 && sleep 10
				fi

				if [ $(mount | grep -c 'sdb1') -eq 0 ]
				then
					[ -d /data ] || mkdir /data
					mount -t $filesystem /dev/sdb1 /data
					sed -i '/sdb1/d' /etc/fstab
					echo "/dev/sdb1               /data                   $filesystem    defaults        0 0" >> /etc/fstab
					echo "mount /dev/sdb1 disk success" ! 
				fi
			fi
		else

			if [ -b /dev/sdb1 ] && [ $(/sbin/blkid /dev/sdb1  | egrep -c 'ext2|ext3|ext4|xfs') -ge 1 ]
			then
				if [ $(mount | grep -c 'sdb1') -eq 0 ]
				then
				   [ -d /data ] || mkdir /data
				   mount /dev/sdb1 /data && "mount /dev/sdb1 disk success" !

				   if [ $(mount | grep -c 'sdb1') -ge 1 ]
				   then
					    sed -i '/sdb1/d' /etc/fstab
						filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`
						echo "/dev/sdb1               /data                   $filesystem    defaults        0 0" >> /etc/fstab
				   else
					    echo "mount /dev/sdb1 disk failed" !
				   fi
				fi
			else
				echo "can not find correct filesystem on /dev/sdb1" !!
			fi
		fi
	}


	# parameters: ipaddress_lan
	static_route ()
	{
		if [ ! "$1" == "" ]
		then
    		IP_123=`echo $1 | awk -F "." '{printf("%d.%d.%d.",$1,$2,$3)}'`
    		IP_4=`echo $1 | awk -F "." '{printf("%d", $4)}'`

    		if [ $IP_4 -ge 2 ] && [ $IP_4 -le 61 ]
			then
        		IP_4="1"
    		elif [ $IP_4 -ge 66 ] && [ $IP_4 -le 125 ]
			then
        		IP_4="65"
    		elif [ $IP_4 -ge 130 ] && [ $IP_4 -le 189 ]
			then
        		IP_4="129"
    		elif [ $IP_4 -ge 194 ] && [ $IP_4 -le 253 ]
			then
        		IP_4="193"
    		fi

    		local route_lan_num=`grep -c "^any net 10.0.0.0 netmask 255.0.0.0" /etc/sysconfig/static-routes`
			
			if [ ! "$route_lan_num" == "" ]
			then
    			if [ $route_lan_num -eq 0 ]
				then
        			echo "any net 10.0.0.0 netmask 255.0.0.0 gw $IP_123$IP_4" >> /etc/sysconfig/static-routes
        			ci_m=1
				else
					sed -i "/any net 10.0.0.0 netmask 255.0.0.0/d" /etc/sysconfig/static-routes
					echo "any net 10.0.0.0 netmask 255.0.0.0 gw $IP_123$IP_4" >> /etc/sysconfig/static-routes
                                        ci_m=1
   				fi
			else
				echo "any net 10.0.0.0 netmask 255.0.0.0 gw $IP_123$IP_4" > /etc/sysconfig/static-routes
			fi
		fi
	}

	nyinstall ()
	{

		cdrom=`ls -l /dev/cdrom* | grep "/dev/cdrom" | awk -F "->" '{printf $2}' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | awk -F " " '{printf $1}'`
		if [ $(mount  | grep $cdrom | grep -c '/mnt/cdrom') -eq 0 ]
		then
			umount /dev/$cdrom
			mount /dev/$cdrom /mnt/cdrom && echo "mount cdrom success" !
		fi

		if [ -f /mnt/cdrom/sysSetup.so ]
		then
			if [ -f /home/sysSetup.so ]
            then
              	if [ ! $(cksum /home/sysSetup.so | awk '{ print $1 }') == $(cksum /mnt/cdrom/sysSetup.so | awk '{ print $1 }') ]
				then
                   	rm -f /home/sysSetup.so
                   	cp /mnt/cdrom/sysSetup.so /home
                fi
			else
				cp /mnt/cdrom/sysSetup.so /home
            fi
		fi

		if [ -f /mnt/cdrom/cloudsafe* ]
		then
			rm -f $home/cloudsafe*

			if [ $(uname -i) == "x86_64" ]
			then
				cp /mnt/cdrom/cloudsafe*.x86_64.rpm $home/
			elif [ $(uname -i) == "i386" ]
			then
				cp /mnt/cdrom/cloudsafe*.i686.rpm $home/
			fi

			if [ $(rpm -qa | grep -c cloudsafe) -eq 0 ]
            then
            	rpm -vih $home/cloudsafe*.rpm
            else
            	if [ `find $home -name cloudsafe*.rpm | grep -c $(rpm -qa | grep cloudsafe)` -eq 0 ]
            	then
                   	rpm -e cloudsafe
               		rpm -vih $home/cloudsafe*.rpm
            	fi
			fi
       	fi

		if [ $(ps -fel | grep -v grep | grep -c -i cloudsafe) -eq 0 ]
		then
			/etc/init.d/cloudSafed start
			/etc/init.d/cloudGuardd start
		fi

		eject /dev/$cdrom
	}


	network ()
	{
		if [ ! "$IP_MOD" == "" ]
		then 
			ip_wlan=`echo $IP_MOD | awk -F "," '{printf $1}'`
			ip_lan=`echo $IP_MOD | awk -F "," '{printf $2}'`
		fi

		if [ ! "$MS_MOD" == "" ]
		then
			netmask_wlan=`echo $MS_MOD | awk -F "," '{printf $1}'`
			netmask_lan=`echo $MS_MOD | awk -F "," '{printf $2}'`
		fi

		dev_array=`ip -o link | grep '\<link/ether\>' | awk -F ": " '{printf("%s ", $2)}'`
		dev_count=$(i=0;for j in $dev_array;do i=`expr $i + 1`;done;echo $i)

    	dev_wlan=`echo $dev_array | awk '{ print $1 }'`
		echo "network interface $dev_wlan existence" !

		if [ -n "${dev_wlan}" ] && [ -n "${ip_wlan}" ] && [ -n "${netmask_wlan}" ] && [ -n "${GW_MOD}" ]
		then
        	network_parameter $dev_wlan $ip_wlan $netmask_wlan $GW_MOD
		fi

		if [ $dev_count -ge 2 ]
		then
    		dev_lan=`echo $dev_array | awk '{ print $2 }'`
			echo "network interface $dev_lan existence" !

			if [ -n "${dev_lan}" ] && [ -n "${ip_lan}" ] && [ -n "${netmask_lan}" ]
			then
				network_parameter $dev_lan $ip_lan $netmask_lan
				static_route $ip_lan
			fi
		fi
		
	}


	hostname
	network
	password
	datastore
	nyinstall
	restart_service
	dnsserver
}

# For FreeBSD System

FreeBSD ()
{

	# parameters: nicname ipaddress netmask gateway
	network_parameter ()
	{
		curr_ip=`grep '^ifconfig' /etc/rc.conf | grep $1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sed -n 1p`
    	curr_netmask=`grep '^ifconfig' /etc/rc.conf | grep $1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sed -n 2p`
    	curr_gateway=`grep '^defaultrouter' /etc/rc.conf | grep $4 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`

    	if [ ! "${1}" == "" ] && [ ! "${2}" == "" ] && [ ! "${3}" == "" ]
    	then
			if [ ! "${curr_ip}" == "" ] && [ ! "${curr_netmask}" == "" ]
			then
				if [ ! "${curr_ip}" == "${2}" ] && [ ! "${curr_netmask}" == "${3}" ]
				then
					sed -e "/ifconfig_${1}/d" /etc/rc.conf > $tmp
					echo ifconfig_${1}=\"inet ${2} netmask ${3}\" >> $tmp
					cat $tmp > /etc/rc.conf
					echo "configuration ipaddress and netmask for network interface $1 success" !
					ci_m=1
				fi
					echo "${1}:current ipaddress is ${curr_ip}" !
    				echo "${1}:current netmask is ${curr_netmask}" !
			else
				echo ifconfig_${1}=\"inet ${2} netmask ${3}\" >> /etc/rc.conf
				echo "configuration ipaddress and netmask for network interface $1 success" !
				ci_m=1
			fi		
		fi

		if [ ! "${4}" == "" ]
		then
			if [ ! "${curr_gateway}" == "" ]
			then
				if [ ! "${curr_gateway}" == "${4}" ]
				then
					sed -e "/defaultrouter/d" /etc/rc.conf > $tmp
					echo defaultrouter=\"${4}\" >> $tmp
					cat $tmp > /etc/rc.conf
					echo "configuration gateway for network interface $1 success" !
					ci_m=1
				fi
    				echo "${1}:current gateway is ${curr_gateway}" !
			else
				echo defaultrouter=\"${4}\" >> /etc/rc.conf
				echo "configuration gateway for network interface $1 success" !
				ci_m=1
			fi
		fi

    	return 0

	}


	network ()
	{
		if [ ! $IP_MOD == "" ] && [ ! $MS_MOD == "" ] && [ ! $GW_MOD == "" ]
		then
			ip_wlan=`echo $IP_MOD | awk -F "," '{printf $1}'`
			ip_lan=`echo $IP_MOD | awk -F "," '{printf $2}'`
			netmask_wlan=`echo $MS_MOD | awk -F "," '{printf $1}'`
			netmask_lan=`echo $MS_MOD | awk -F "," '{printf $2}'`

		 	network_parameter em0 $ip_wlan $netmask_wlan $GW_MOD
			echo "configuration network interface em0 success" !

			if [ $(/usr/local/bin/lspci | grep -c -i net) -ge 2 ]
			then
		 		network_parameter em1 $ip_lan $netmask_lan
				echo "configuration network interface em1 success" !
		 		static_route $ip_lan
				echo "configuration static route success" !
			else
				echo "less then two net cards" !
			fi
		fi

	}


	hostname ()
	{

        if [ ! "$HN_MOD" == "" ]
		then
			HN_PRI=`grep "^hostname" /etc/rc.conf | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`

			if [ ! "$HN_PRI" == "" ]
			then
				if [ "$HN_PRI" != "$HN_MOD" ]
				then
            		sed -e "/hostname/d" /etc/rc.conf > $tmp
            		echo hostname=\"$HN_MOD\" >> $tmp
            		cat $tmp > /etc/rc.conf
            		ch_m=1 
            		echo "hostname changed" !
				fi
			else
				echo hostname=\"$HN_MOD\" >> /etc/rc.conf
				ch_m=1
                echo "hostname changed" !
			fi
        else 
            echo "hostname not change" !
        fi

	}


	dnsserver ()
	{
		if [ ! $DN_MOD == "" ]
        then
            dns1=`echo $DN_MOD | awk -F "," '{ print $1 }'`
            dns2=`echo $DN_MOD | awk -F "," '{ print $2 }'`
            dns3=`echo $DN_MOD | awk -F "," '{ print $3 }'`

            if [ ! $dns1 == "" ] && [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 1p | grep -c $dns1) -eq 0 ]
            then
                echo "nameserver $dns1" > /etc/resolv.conf
				echo "configuration dnsserver1 success" !
			else
				echo "dnserver1 not change"
            fi

            if [ ! $dns2 == "" ]
            then
                if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 2 ]
                then
                    if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 2p | grep -c $dns2) -eq 0 ]
                    then
                        curr_nameserver2=`grep "^nameserver" /etc/resolv.conf | sed -n 2p | awk '{ print $2}'`
                        sed -e "/$curr_nameserver2/d" /etc/resolv.conf > $tmp
						echo "nameserver $dns2" >> $tmp
						cat $tmp > /etc/resolv.conf
                        echo "nameserver2 $curr_nameserver2 existence" !
						echo "configuration dnsserver2 success" !
					else
						echo "dnserver2 not change"
                    fi
                else
                    echo "nameserver $dns2" >> /etc/resolv.conf
					echo "configuration dnsserver2 success" !
                fi
            fi

			if [ ! $dns3 == "" ]
            then
                if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 3 ]
                then
                    if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 3p | grep -c $dns3) -eq 0 ]
                    then
                        curr_nameserver3=`grep "^nameserver" /etc/resolv.conf | sed -n 3p | awk '{ print $2}'`
                        sed -e "/$curr_nameserver3/d" /etc/resolv.conf > $tmp
						echo "nameserver $dns3" >> $tmp
						cat $tmp > /etc/resolv.conf
                        echo "nameserver3 $curr_nameserver3 existence" !
						echo "configuration dnsserver3 success" !
					else
						echo "dnserver3 not change"
                    fi
                else
                    echo "nameserver $dns3" >> /etc/resolv.conf
					echo "configuration dnsserver3 success" !
				fi

            fi
                chmod 644 /etc/resolv.conf
		fi

	}


	password ()
	{
		bsdpasswd ()
		{
			/usr/local/bin/expect <<- END
			spawn passwd root
			expect "New Password:"
			sleep 5
			send "$PS_MOD\r"
			expect "Retype New Password:"
			sleep 5
			send "$PS_MOD\r"
			expect eof
			END
		}

		if [ "$PS_MOD" ]
    	then 
			if [ -f $auto_tmp ]
			then
				. $auto_tmp

				if [ "$PS_MOD_LAST" ]
				then
					if [ "$PS_MOD_LAST" != "$PS_MOD" ]
					then
						bsdpasswd
    					echo "password changed" !
					else
						echo "password not change" !
					fi
				else
					bsdpasswd
    				echo "password changed" !
				fi
			else
				bsdpasswd
    			echo "password changed" !
			fi
    	else 
        	echo "password not change" !
    	fi

	}

	nyinstall ()
	{
		if [ -c /dev/cd0 ]
		then
			mount -t cd9660 /dev/cd0 /mnt/cdrom && echo "mount cdrom device success"
		fi

		if [ -f /mnt/cdrom/sysSetup.so ]
		then
			if [ -f /home/sysSetup.so ]
            then
              	if [ ! $(cksum /home/sysSetup.so | awk '{ print $1 }') == $(cksum /mnt/cdrom/sysSetup.so | awk '{ print $1 }') ]
				then
                   	rm -f /home/sysSetup.so
                   	cp /mnt/cdrom/sysSetup.so /home
                fi
			else
				cp /mnt/cdrom/sysSetup.so /home
            fi
		fi

		if [ -f /mnt/cdrom/cloudsafe* ]
		then
			rm -f $home/cloudsafe*
			cp /mnt/cdrom/cloudsafe* $home/

			if [ $(pkg info | grep -c cloudsafe) -eq 0 ]
            then
				/etc/rc.d/netif restart
				route add default $GW_MOD
            	pkg install -y $home/cloudsafe*
            else
            	if [ $(ls $home/cloudsafe* | grep -c `pkg info cloudsafe | grep Version | awk '{ print $3 }'`) -eq 0 ]
            	then
					/etc/rc.d/netif restart
					route add default $GW_MOD
                   	pkg remove -y cloudsafe
               		pkg install -y $home/cloudsafe*
            	fi
			fi
       	fi

		if [ $(ps -A | grep -i cloudsafe | grep -c -v grep) -eq 0 ]
		then
			/etc/rc.d/cloudSafed start
		fi
		
		if [ $(ps -A | grep -i cloudguard | grep -c -v grep) -eq 0 ]
		then
			/etc/rc.d/cloudGuardd start
		fi

		eject /dev/cd0
	}
	
	restart_service ()
	{
    
		if [ "$ch_m" -eq 1 ]
		then 
			reboot && echo "$(date '+%Y-%m-%d %H:%M:%S')  system will reboot now" !
    	elif [ "$ci_m" == 1 ]
		then
			sh /etc/rc
			echo "restart service success" !
		fi
	}

	# parameters: ip_lan
	static_route ()
	{
		if [ ! "$1" == "" ]
		then
    		IP_123=`echo $1 | awk -F "." '{printf("%d.%d.%d.",$1,$2,$3)}'`
    		IP_4=`echo $1 | awk -F "." '{printf("%d", $4)}'`

    		if [ $IP_4 -ge 2 ] && [ $IP_4 -le 61 ]
			then
        		IP_4="1"
    		elif [ $IP_4 -ge 66 ] && [ $IP_4 -le 125 ]
			then
        		IP_4="65"
    		elif [ $IP_4 -ge 130 ] && [ $IP_4 -le 189 ]
			then
        		IP_4="129"
		    elif [ $IP_4 -ge 194 ] && [ $IP_4 -le 253 ]
			then
        		IP_4="193"
			fi

			if [ $(grep -c "-net 10.0.0.0/8" /etc/rc.conf) -eq 0 ]
			then
				cat >> /etc/rc.conf  << EOF

# add static route
static_routes="em1"
route_em1="-net 10.0.0.0/8 $IP_123$IP_4"
EOF
			else
				echo "static route not change" !
			fi
    	fi

	}


	datastore ()
	{
		if [ $(mount | grep -c '/data') -eq 0 ] && [ -c /dev/da1 ] && [ "$FM_MOD" = "YES" ]
		then
			if [ $(grep -c '^zfs_enable'  /etc/rc.conf) -eq 0 ]
			then
				cat  /etc/rc.conf > $tmp
				echo 'zfs_enable="YES"' >> $tmp
				cat $tmp > /etc/rc.conf
			fi

			/etc/rc.d/zfs restart
			zpool create data /dev/da1
			zfs create data/data1
			zfs set copies=2 data/data1
			zfs set compression=gzip data/data1
		fi
	}

	hostname
	datastore
	network
	dnsserver
	password
	nyinstall
	restart_service

}

# For Ubuntu or Debian System

Ubuntu ()
{
	# parameters: nicname ipaddress netmask gateway
        network_parameter ()	
	{
		if [ "${1}" ]
		then
			if [ $(grep -c "^auto ${1}" /etc/network/interfaces) -eq 0 ]
			then
				sed -i "/auto ${1}/d" /etc/network/interfaces
                echo "\nauto ${1}" >> /etc/network/interfaces
        	fi

        	if [ $(grep "^iface ${1} inet" /etc/network/interfaces | grep  -c 'static') -eq 0 ]
			then
                sed -i "/iface ${1} inet/d" /etc/network/interfaces
                echo "iface ${1} inet static" >> /etc/network/interfaces
        	fi
		fi

		currl_ip=`grep "iface ${1} inet static" -A10 /etc/network/interfaces | grep -v ^# | grep '^address' | sed -n 1p | grep -oP '\d+\.\d+\.\d+\.\d+'`
		currl_netmask=`grep "iface ${1} inet static" -A10 /etc/network/interfaces | grep  -v ^# | grep '^netmask' | sed -n 1p | grep -oP '\d+\.\d+\.\d+\.\d+'`
		currl_gateway=`grep "iface ${1} inet static" -A10 /etc/network/interfaces | grep -v ^# | grep '^gateway' | sed -n 1p | grep -oP '\d+\.\d+\.\d+\.\d+'`

		if [ "${2}" ]
		then
			if [ "$currl_ip" ]
			then
				if [ "$currl_ip" != "${2}" ]
				then
                	sed  -i "s/$currl_ip/${2}/" /etc/network/interfaces
					echo "configuration ipaddress for network interface $1 success" !
					ci_m=1
				fi
			else
                sed -i "/iface ${1} inet static/a\address ${2}" /etc/network/interfaces
				echo "configuration ipaddress for network interface $1 success" !
				ci_m=1
			fi
		fi

		if [ "${3}" ]
		then
        	if [ "$currl_netmask" ]
			then
				if [ "$currl_netmask" != "${3}" ]
				then
                	sed  -i "s/$currl_netmask/${3}/" /etc/network/interfaces
					echo "configuration netmask for network interface $1 success" !
					ci_m=1
				fi
        	else
                sed -i "/address ${2}/a\netmask ${3}" /etc/network/interfaces
				echo "configuration netmask for network interface $1 success" !
				ci_m=1
        	fi
		fi

		if [ "${4}" ]
		then
        	if [ "$currl_gateway" ]
			then
				if [ "$currl_gateway" != "${4}" ]
				then
                	sed  -i "s/$currl_gateway/${4}/" /etc/network/interfaces
					echo "configuration gateway for network interface $1 success" !
					ci_m=1
				fi
        	else
                sed -i "/netmask ${3}/a\gateway ${4}" /etc/network/interfaces
				echo "configuration gateway for network interface $1 success" !
				ci_m=1
        	fi
		fi

		return 0
	}

	dnserver ()
	{
		if [ $DN_MOD ]
		then
        	dns1=`echo $DN_MOD | awk -F "," '{ print $1 }'`
            dns2=`echo $DN_MOD | awk -F "," '{ print $2 }'`
            dns3=`echo $DN_MOD | awk -F "," '{ print $3 }'`

			if [ $dns1 ]
			then
				if [ $(sed -n '/^nameserver/p' /etc/resolvconf/resolv.conf.d/base | sed -n 1p | grep -c $dns1) -eq 0 ]
				then
                    echo "nameserver $dns1" > /etc/resolvconf/resolv.conf.d/base
                	echo "configuration dnsserver1 success" !
					ci_m=1
				else
					echo "dnsserver1 not change" !
                fi
			fi

            if [ $dns2 ]
			then
				if [ $(sed -n '/^nameserver/p' /etc/resolvconf/resolv.conf.d/base | sed -n 2p | grep -c $dns2) -eq 0 ]
				then
                    echo "nameserver $dns2" >> /etc/resolvconf/resolv.conf.d/base
                	echo "configuration dnsserver2 success" !
					ci_m=1
				else
					echo "dnsserver2 not change" !
                fi
			fi

            if [ $dns3 ]
			then
				if [ $(sed -n '/^nameserver/p' /etc/resolvconf/resolv.conf.d/base | sed -n 3p | grep -c $dns3) -eq 0 ]
				then
                    echo "nameserver $dns3" >> /etc/resolvconf/resolv.conf.d/base
					echo "configuration dnsserver3 success" !
					ci_m=1
				else
					echo "dnsserver3 not change" !
				fi
            fi
	
		fi

	}


	hostname ()
	{
		local old_hostname=`cat /etc/hostname`
    	if [ "${HN_MOD}" ]
		then
			if [ "$old_hostname" ]
			then 
				if [ "${HN_MOD}" != "${old_hostname}" ]
				then
        			sed -i "s/$old_hostname/$HN_MOD/g" /etc/hostname
					ch_m=1
					echo "configuration hostname success" !
				else
					echo "hostname not change" !
				fi
			else
        		echo "${HN_MOD}" > /etc/hostname
				ch_m=1
				echo "configuration hostname success" !
			fi

		else
        	echo "hostname not change" !
			
		fi
	}


	password ()
	{
		if [ "$PS_MOD" ]
		then
            if [ -f $auto_tmp ]
            then
                . $auto_tmp

                if [ "$PS_MOD_LAST" ]
                then
                    if [ "$PS_MOD" != "$PS_MOD_LAST" ]
                    then
                        echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
					else
						echo "password not change" !
                    fi
                else
                    echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
                fi      
            else
                echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
            fi
        fi
	}


	restart_service ()
	{
		if [ "$ci_m" -eq 1 ]
		then
			service networking restart || ifdown -a;ifup -a
			/sbin/resolvconf -u
		fi
		
		if [ "$ch_m" = 1 ]
		then
			reboot && echo "$(date '+%Y-%m-%d %H:%M:%S')  system will reboot now" !
		fi

		echo "service restarted success" !
	}


	datastore ()
    {
        filesystem="ext4"

        if [ "$FM_MOD" = "YES" ]
        then
            if [ -b /dev/sdb1 ]
            then
                if [ $(/sbin/blkid /dev/sdb1  | egrep -c 'ext2|ext3|ext4|xfs') -ge 1 ]
                then
                    filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`
                else
                    [ -b /dev/sdb1 ] && /sbin/parted -s /dev/sdb rm 1
                    /sbin/parted -s /dev/sdb mklabel msdos
                    /sbin/parted -s /dev/sdb mkpart primary 0% 100%
                    mkfs -t $filesystem /dev/sdb1 && sleep 10
                fi
            else
                /sbin/parted -s /dev/sdb mklabel msdos
                /sbin/parted -s /dev/sdb mkpart primary 0% 100%
                mkfs -t $filesystem /dev/sdb1 && sleep 10
            fi



			if [ $(mount | grep -c 'sdb1') -eq 0 ]
            then
                [ -d /data ] || mkdir /data
                mount -t $filesystem /dev/sdb1 /data

                if [ $(mount | grep -c 'sdb1') -ge 1 ]
                then
                    sed -i '/sdb1/d' /etc/fstab
               		echo "/dev/sdb1                       /data           $filesystem    defaults        0       0" >> /etc/fstab
                else
                    echo "mount /dev/sdb1 disk failed" !
                fi
            fi
                        
                        
        else

            if [ $(mount | grep -c 'sdb1') -eq 0 ]
            then
                [ -d /data ] || mkdir /data
                mount /dev/sdb1 /data && echo "mount /dev/sdb1 disk success" !
                filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`

                if [ $(mount | grep -c 'sdb1') -ge 1 ]
                then
                    sed -i '/sdb1/d' /etc/fstab
           			echo "/dev/sdb1                                 /data           $filesystem    defaults        0       0" >> /etc/fstab
                fi
                      
                                
            fi

        fi
    }


	static_route ()
	{
		if [ "${1}" ]
		then
			IP_123=`echo $1 | awk -F "." '{printf("%d.%d.%d.",$1,$2,$3)}'`
    		IP_4=`echo $1 | awk -F "." '{printf("%d", $4)}'`

    		if [ $IP_4 -ge 2 ] && [ $IP_4 -le 61 ]
			then
        		IP_4="1"
    		elif [ $IP_4 -ge 66 ] && [ $IP_4 -le 125 ]
			then
        		IP_4="65"
    		elif [ $IP_4 -ge 130 ] && [ $IP_4 -le 189 ]
			then
        		IP_4="129"
    		elif [ $IP_4 -ge 194 ] && [ $IP_4 -le 253 ]
			then
        		IP_4="193"
    		fi

			if [ $(grep -c "up route add -net 10.0.0.0 netmask 255.0.0.0 gw $IP_123$IP_4 $2" /etc/network/interfaces) -eq 0 ]
			then
				sed -i '/up route add*/d' /etc/network/interfaces
    			echo "up route add -net 10.0.0.0 netmask 255.0.0.0 gw $IP_123$IP_4 $2" >> /etc/network/interfaces
    			echo "configuration static route success" !
    			ci_m=1
			else
				echo "static route not change" !
			fi
		fi
	}


	nyinstall ()
	{
		cdrom=`ls -l /dev/cdrom* | grep "/dev/cdrom" | awk -F "->" '{printf $2}' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | awk -F " " '{printf $1}'`
        if [ $(mount  | grep $cdrom | grep -c '/mnt/cdrom') -eq 0 ]
        then
            umount /dev/$cdrom
            mount /dev/$cdrom /mnt/cdrom && echo "mount cdrom success" !
		fi

        if [ -f /mnt/cdrom/sysSetup.so ]
        then
            if [ -f /home/sysSetup.so ]
			then
				if [ ! $(cksum /home/sysSetup.so | awk '{ print $1 }') == $(cksum /mnt/cdrom/sysSetup.so | awk '{ print $1 }') ]
				then
					rm -f /home/sysSetup.so
                    cp /mnt/cdrom/sysSetup.so /home
				fi
			else
				cp /mnt/cdrom/sysSetup.so /home
			fi
        fi


        if [ -f /mnt/cdrom/cloudsafe* ]
        then
            rm -f $home/cloudsafe*
			cp /mnt/cdrom/cloudsafe*.amd64.deb $home/
		fi
		
		if [ -f /var/lib/dpkg/lock ]
		then
			rm -f /var/lib/dpkg/lock
		fi
		
		if [ -f /var/lib/apt/lists/lock ]
		then
			rm -f /var/lib/apt/lists/lock
		fi
		
		if [ -f /var/cache/apt/archives/lock ]
		then
			rm -f /var/cache/apt/archives/lock
		fi
		
		if [ $(dpkg -l | grep -c -i cloudsafe) -eq 0 ]
		then
			echo "cloudsafe packages not install"!
			dpkg -i $home/cloudsafe*.deb
		else
			if [ `dpkg -l | grep cloudsafe | grep -c $(dpkg --info $home/cloudsafe*.deb | grep 'Version' | awk '{ print $2 }')` -eq 0 ]
			then
				dpkg -P cloudsafe
				dpkg -i $home/cloudsafe*.deb
			fi
		fi

		if [ $(ps -fel | grep -v grep | grep -c -i cloudsafe) -eq 0 ]
        then
            /etc/init.d/cloudSafed start
            /etc/init.d/cloudGuardd start
        fi

		eject /dev/$cdrom
	}

	network ()
	{
		if [ "$IP_MOD" ]
		then
			ip_wlan=`echo $IP_MOD | awk -F "," '{printf $1}'`
			ip_lan=`echo $IP_MOD | awk -F "," '{printf $2}'`
		fi

		if [ "$MS_MOD" ]
		then
			netmask_wlan=`echo $MS_MOD | awk -F "," '{printf $1}'`
			netmask_lan=`echo $MS_MOD | awk -F "," '{printf $2}'`
		fi

		dev_array=`ip -o link | grep '\<link/ether\>' | awk -F ": " '{printf("%s ", $2)}'`
		dev_count=${#dev_array[*]}
    	dev_wlan=`echo $dev_array | awk '{ print $1 }'`
		echo "network interface $dev_wlan existence" !

    	if [ -n "${dev_wlan}" ] && [ -n "${ip_wlan}" ] && [ -n "${netmask_wlan}" ] && [ -n "${GW_MOD}" ]
		then
			network_parameter $dev_wlan $ip_wlan $netmask_wlan $GW_MOD
    	fi

		if [ $dev_count -ge 2 ]
		then
    		dev_lan=`echo $dev_array | awk '{ print $2 }'`
			echo "network interface $dev_lan existence" !

    		if [ -n "${dev_lan}" ] && [ -n "${ip_lan}" ] && [ -n "${netmask_lan}" ]
			then
       			network_parameter $dev_lan $ip_lan $netmask_lan
				static_route $ip_lan
    		fi
		fi
	}

	hostname
	network
	dnserver
	password
	datastore
	nyinstall
	restart_service

	return 0
}

openSUSE ()
{
	network_parameter ()
	{
		local network_file=/etc/sysconfig/network/ifcfg-$1
		
		if [ $(grep '^BOOTPROTO' $network_file | grep -c 'static') -eq 0 ]
		then
			sed -i '/BOOTPROTO/d' $network_file
    		echo "BOOTPROTO='static'" >> $network_file
		fi
   	
		if [ $(grep '^STARTMODE' $network_file | grep -c 'auto') -eq 0 ]
		then
			sed -i '/STARTMODE/d' $network_file
    		echo "STARTMODE='auto'" >> $network_file
		fi
   	
		if [ ! "${2}" == "" ] && [ ! "${3}" == "" ]
		then
			local curr_ip=`grep '^IPADDR' $network_file | grep -oP '\d+\.\d+\.\d+\.\d+'`
			netmask=`ipcalc "${2}" "${3}" | grep "Netmask" | awk '{ print $4 }'`

			if [ ! "${curr_ip}" == "" ]
			then
				echo "${1}:current ipaddress is ${curr_ip}" !

				if [ ! "${curr_ip}" == "${2}" ]
				then
        			sed -i '/IPADDR/d' $network_file
        			echo "IPADDR='${2}/$netmask'" >> $network_file
    				echo "configuration ipaddress for network interface $1 success" !
				fi
			else
        		sed -i '/IPADDR/d' $network_file
				echo "IPADDR='${2}/$netmask'" >> $network_file
    			echo "configuration ipaddress for network interface $1 success" !
			fi
		fi
		
		if [ ! "${4}" == "" ]
		then
			gatewayfile=/etc/sysconfig/network/routes
			curtgate=`grep default $gatewayfile | grep -oP '\d+\.\d+\.\d+\.\d+'`
				
			if [ "$curtgate" ]
			then
				
				if [ ! "$curtgate" == "${4}" ]
				then
					sed -i '/default/d' $gatewayfile
					echo default ${4} - - >> $gatewayfile
					echo "configuration gateway for network interface $1 success" !
				fi
					
			else
				echo default ${4} - - > $gatewayfile
				echo "configuration gateway for network interface $1 success" !
			fi
				
		fi
		
	}	
	
	hostname()
	{
		local curr_hostname=`cat /etc/HOSTNAME`
		if [ -n "$HN_MOD" ]
		then
			if [ "$curr_hostname" != "$HN_MOD" ]
			then
				echo $HN_MOD > /etc/HOSTNAME && echo "hostname changed" !
				echo -e "127.0.0.1   $HN_MOD\n::1         $HN_MOD" >> /etc/hosts  && echo "hosts file changed" !
				ch_m=1
			fi
		fi
		
	}
	
	
	dnsserver ()
	{
		if [ ! $DN_MOD == "" ]
		then
        	dns1=`echo $DN_MOD | awk -F "," '{ print $1 }'`
            dns2=`echo $DN_MOD | awk -F "," '{ print $2 }'`
            dns3=`echo $DN_MOD | awk -F "," '{ print $3 }'`

           	if [ ! $dns1 == "" ] && [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 1p | grep -c $dns1) -eq 0 ]
			then
                echo "nameserver $dns1" > /etc/resolv.conf
                echo "configuration dnsserver1 success" !
			else
				echo "dnsserver1 not change" !
            fi

           	if [ ! $dns2 == "" ]
			then
				if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 2 ]
				then
					if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 2p | grep -c $dns2) -eq 0 ]
					then
						curr_nameserver2=`grep "^nameserver" /etc/resolv.conf | sed -n 2p | awk '{ print $2 }'`
						sed -i "s/$curr_nameserver2/$dns2/" /etc/resolv.conf
						echo "nameserver2 $curr_nameserver2 existence" !
                		echo "configuration dnsserver2 success" !
					else
						echo "dnsserver2 not change" !
					fi
				else
                	echo "nameserver $dns2" >> /etc/resolv.conf
               		echo "configuration dnsserver2 success" !
					ci_m=1
           		fi

			fi

           	if [ ! $dns3 == "" ]
			then
				if [ $(grep -c "^nameserver" /etc/resolv.conf) -ge 3 ]
				then
					if [ $(sed -n '/^nameserver/p' /etc/resolv.conf | sed -n 3p | grep -c $dns3) -eq 0 ]
					then
						curr_nameserver3=`grep "^nameserver" /etc/resolv.conf | sed -n 3p | awk '{ print $2 }'`
						sed -i "s/$curr_nameserver3/$dns3/" /etc/resolv.conf
						echo "nameserver3 $curr_nameserver3 existence" !
						echo "configuration dnsserver3 success" !
					else
						echo "dnsserver3 not change" !
					fi
				else
                	echo "nameserver $dns3" >> /etc/resolv.conf
           			echo "configuration dnsserver3 success" !
				fi
           	fi

           	chmod 644 /etc/resolv.conf

			if [ -f /etc/NetworkManager/NetworkManager.conf ]
			then
				if [ $(grep '^dns' /etc/NetworkManager/NetworkManager.conf | grep -c 'none') -eq 0 ]
				then
					echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
				fi
			fi
		fi

	}
	
	
	password ()
	{
    	if [ "$PS_MOD" ]
		then
			if [ -f $auto_tmp ]
			then
				. $auto_tmp

				if [ "$PS_MOD_LAST" ]
				then
					if [ ! "$PS_MOD" == "$PS_MOD_LAST" ]
					then
    					echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
					else
						echo "password not change" !
					fi
				else
					echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
				fi
			else
				echo "root:$PS_MOD" | chpasswd && echo "password changed success" !
			fi
   		fi
	}
	
	restart_service ()
	{
		if [ "$ci_m" -eq 1 ]
		then
			/etc/init.d/network restart
		fi

		if [ "$ch_m" -eq 1 ]
		then
			reboot && echo "$(date '+%Y-%m-%d %H:%M:%S')  system will reboot now" !
		fi
		
		echo "restart service success" !
	}
	
	datastore ()
	{
		if [ "$FM_MOD" == "YES" ]
		then
			filesystem="ext4"
			if [ -b /dev/sdb ]
			then
				if [ -b /dev/sdb1 ]
				then
					if [ $(/sbin/blkid /dev/sdb1  | egrep -c 'ext2|ext3|ext4|xfs') -ge 1 ]
					then
						filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`
					else
						[ -b /dev/sdb1 ] && /sbin/parted -s /dev/sdb rm 1
						/usr/sbin/parted -s /dev/sdb mklabel msdos
						/usr/sbin/parted -s /dev/sdb mkpart primary 0% 100%
						mkfs -t $filesystem /dev/sdb1 || mkfs -t $filesystem -f /dev/sdb1
					fi
				else
					/usr/sbin/parted -s /dev/sdb mklabel msdos
					/usr/sbin/parted -s /dev/sdb mkpart primary 0% 100%
					mkfs -t $filesystem /dev/sdb1 && sleep 10
					
				fi

				if [ $(mount | grep -c 'sdb1') -eq 0 ]
				then
					[ -d /data ] || mkdir /data
					mount -t $filesystem /dev/sdb1 /data
					sed -i '/sdb1/d' /etc/fstab
					echo "/dev/sdb1            /data                $filesystem       defaults              0 0" >> /etc/fstab
					echo "mount /dev/sdb1 disk success" ! 
				fi
			fi
			
		else

			if [ $(mount | grep -c 'sdb1') -eq 0 ]
			then			
				if [ -b /dev/sdb1 ] && [ $(/sbin/blkid /dev/sdb1  | egrep -c 'ext2|ext3|ext4|xfs') -ge 1 ]
				then
					[ -d /data ] || mkdir /data
					mount /dev/sdb1 /data && "mount /dev/sdb1 disk success" !

					if [ $(mount | grep -c 'sdb1') -ge 1 ]
					then
						sed -i '/sdb1/d' /etc/fstab
						filesystem=`/sbin/blkid  /dev/sdb1 | awk '{ print $3 }' | awk -F'=' '{ print $2 }' | sed -e 's/"//g'`
						echo "/dev/sdb1            /data                $filesystem       defaults              0 0" >> /etc/fstab
						echo "write into fstab file success"!
					else
						echo "mount /dev/sdb1 disk failed,and not write into fstab file" !!
					fi
				else
					echo "/dev/sdb1 is not exist,or not a valid file system"!!
				fi	
			else
				echo "/dev/sdb1 is already mount,nothing to do" !!
			fi
			
		fi
	}
	
		
	static_route ()
	{
		if [ "${1}" ]
		then
			IP_123=`echo $1 | awk -F "." '{printf("%d.%d.%d.",$1,$2,$3)}'`
			IP_4=`echo $1 | awk -F "." '{printf("%d", $4)}'`

    	if [ $IP_4 -ge 2 ] && [ $IP_4 -le 61 ]
		then
    		IP_4="1"
    	elif [ $IP_4 -ge 66 ] && [ $IP_4 -le 125 ]
		then
			IP_4="65"
    	elif [ $IP_4 -ge 130 ] && [ $IP_4 -le 189 ]
		then
			IP_4="129"
   		elif [ $IP_4 -ge 194 ] && [ $IP_4 -le 253 ]
		then
			IP_4="193"
    	fi
    	
    	stanum=`grep -c "10.0.0.0"  /etc/sysconfig/network/routes`
    	
    	if [ $stanum -ne 0 ]
    	then
			sed -i "/10.0.0.0/d" /etc/sysconfig/network/routes
		fi
			echo "10.0.0.0 $IP_123$IP_4 255.0.0.0" >> /etc/sysconfig/network/routes
		fi
	}
	
	nyinstall ()
	{
	
		cdrom=`ls -l /dev/cdrom* | grep "/dev/cdrom" | awk -F "->" '{printf $2}' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | awk -F " " '{printf $1}'`
		
        if [ $(mount  | grep $cdrom | grep -c '/mnt/cdrom') -eq 0 ]
        then
            umount /dev/$cdrom
            mount /dev/$cdrom /mnt/cdrom && echo "mount cdrom success" !
		fi

		if [ $(rpm -qa | grep -c postgresql92-contrib) -eq 0 ]
		then
			/etc/init.d/network restart
			zypper install -y postgresql92-contrib
			[ $(rpm -qa | grep -c postgresql92-contrib) -eq 0 ] && echo "postgresql92-contrib install failed"!! && exit 1
		fi
		
        if [ -f /mnt/cdrom/sysSetup.so ]
		then
			if [ -f /home/sysSetup.so ]
            then
                if [ ! $(cksum /home/sysSetup.so | awk '{ print $1 }') == $(cksum /mnt/cdrom/sysSetup.so | awk '{ print $1 }') ]
				then
                    rm -f /home/sysSetup.so
                    cp /mnt/cdrom/sysSetup.so /home
                fi
			else
				cp /mnt/cdrom/sysSetup.so /home
            fi
		fi

		if [ -f /mnt/cdrom/cloudsafe* ]
		then
			rm -f $home/cloudsafe*

			if [ $(uname -i) == "x86_64" ]
			then
				cp /mnt/cdrom/cloudsafe*.x86_64.rpm $home/
			elif [ $(uname -i) == "i386" ]
			then
				cp /mnt/cdrom/cloudsafe*.i686.rpm $home/
			fi

			if [ $(rpm -qa | grep -c cloudsafe) -eq 0 ]
            then
                rpm -vih $home/cloudsafe*.rpm
            else
                if [ `find $home -name cloudsafe*.rpm | grep -c $(rpm -qa | grep cloudsafe)` -eq 0 ]
                then
                    rpm -e cloudsafe
                    rpm -vih $home/cloudsafe*.rpm
                fi
			fi
        fi

		if [ $(ps -fel | grep -v grep | grep -c -i cloudsafe) -eq 0 ]
		then
			/etc/init.d/cloudSafed start
			/etc/init.d/cloudGuardd start
		fi

		eject /dev/$cdrom
	
	}
	
	network ()
	{
		if [ ! "$IP_MOD" == "" ]
		then 
			ip_wlan=`echo $IP_MOD | awk -F "," '{printf $1}'`
			ip_lan=`echo $IP_MOD | awk -F "," '{printf $2}'`
		fi

		if [ ! "$MS_MOD" == "" ]
		then
			netmask_wlan=`echo $MS_MOD | awk -F "," '{printf $1}'`
			netmask_lan=`echo $MS_MOD | awk -F "," '{printf $2}'`
		fi

		dev_array=`ip -o link | grep '\<link/ether\>' | awk -F ": " '{printf("%s ", $2)}'`
		dev_count=$(i=0;for j in $dev_array;do i=`expr $i + 1`;done;echo $i)

    	dev_wlan=`echo $dev_array | awk '{ print $1 }'`
		echo "network interface $dev_wlan existence" !

		if [ -n "${dev_wlan}" ] && [ -n "${ip_wlan}" ] && [ -n "${netmask_wlan}" ] && [ -n "${GW_MOD}" ]
		then
        	network_parameter $dev_wlan $ip_wlan $netmask_wlan $GW_MOD
		fi

		if [ $dev_count -ge 2 ]
		then
    		dev_lan=`echo $dev_array | awk '{ print $2 }'`
			echo "network interface $dev_lan existence" !

			if [ -n "${dev_lan}" ] && [ -n "${ip_lan}" ] && [ -n "${netmask_lan}" ]
			then
				network_parameter $dev_lan $ip_lan $netmask_lan
				static_route $ip_lan
			fi
		fi
		
	}
	
	hostname
	network
	dnsserver
	password
	datastore
	nyinstall
	restart_service
}


enrpsrfs()
{
	if [ -f /etc/os-release ] && [ $(grep '^ID' /etc/os-release | grep -c -i 'opensuse') -ge 1 ]
	then
		localfile=/etc/init.d/boot.local
	elif [ -f /etc/redhat-release ]
	then
		localfile=/etc/rc.d/rc.local
	elif [ -f /etc/os-release ] && [ $(grep '^ID' /etc/os-release | egrep -c -i 'ubuntu|debian') -ge 1 ]
	then
		localfile=/etc/rc.local
	fi
	
	cd /sys/class/net
	rpspath=/sys/class/net/$(ls | grep -v lo | sed -n 1p)/queues/rx-0/rps_cpus
	rfspath=/sys/class/net/$(ls | grep -v lo | sed -n 1p)/queues/rx-0/rps_flow_cnt

	if [ -f $rpspath ]
	then
		sed -i "s#$rpspath#rpspath#;/rpspath/d" $localfile
		echo "echo ff > $rpspath" >> $localfile
	fi

	rfspath2=/proc/sys/net/core/rps_sock_flow_entries

	if [ -f $rfspath2 ]
	then
		sed -i "s#$rfspath2#rfspath2#;/rfspath2/d" $localfile	
		echo "echo 32768 > $rfspath2" >> $localfile
	fi

	if [ -f $rfspath ]
	then
		numrfs=`expr 32768 / $(grep -c pro /proc/cpuinfo)`
		sed -i "s#$rfspath#rfspath#;/rfspath/d" $localfile
		echo "echo $numrfs > $rfspath" >> $localfile
	fi
	
}


# Starting run

plaver=`uname -s`

case $plaver in

Linux)
   enrpsrfs
					
	if [ -f /etc/redhat-release ]
	then
		CentOS
	elif [ -f /etc/os-release ] && [ $(grep '^ID' /etc/os-release | egrep -c -i 'ubuntu|debian') -ge 1 ]
	then
		Ubuntu
	elif [ -f /etc/os-release ] && [ $(grep '^ID' /etc/os-release | grep -c -i 'opensuse') -ge 1 ]
	then
		openSUSE
	else
		echo "error,This System is not supported" !!
   fi
					
;;
FreeBSD)
   FreeBSD

;;
*)
   echo "error,This platform is not supported" !!

;;
esac

rm -f $tmp

# End run
echo "$(date '+%Y-%m-%d %H:%M:%S')  vminit script ended" !

exit 0