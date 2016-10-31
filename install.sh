#!/bin/bash
# Target: Auto install autovm.sh script
# Update date: 2016/6/30
# Author: niaoyun.com
# Tel: 400-688-3065
# Version: 1.33

# system path
home="/opt/vminit"
tmp=$home/install.tmp
curr_path=$(cd $(dirname $0); pwd)

if [ -f /etc/os-release ] && [ $(grep '^ID' /etc/os-release | grep -c -i 'opensuse') -ge 1 ]
then
	rc_path=/etc/init.d/boot.local
else
	rc_path=/etc/rc.local
fi
	
if [ -d $home ]
then
	rm -fr $home/*
else
	mkdir -p $home
fi

cp -f "${curr_path}/autovm.sh" "$home"
chmod 744 $home/autovm.sh

if [ -f $rc_path ]
then
	if [ $(grep -c "${home}/autovm.sh" ${rc_path}) -ge 1 ]
	then
		sed -e "/autovm.sh/d" $rc_path > $tmp
		cat $tmp > $rc_path
	fi
else
	touch $rc_path && chmod 755 $rc_path
fi

if [ -f $home/autovm.sh ]
then
	if [ $(grep -c '^exit' $rc_path) -ge 1 ]
	then
		sed -i '/^exit/i\'$home'\/autovm.sh' $rc_path 
	else
		echo "$home/autovm.sh" >> $rc_path
	fi
fi

echo "[OK]: install success" !

rm -f ${curr_path}/install.sh ${curr_path}/autovm.sh $tmp

exit 0
