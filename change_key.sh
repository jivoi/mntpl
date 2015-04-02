#!/bin/sh
. ~mnt/etc/mnt.conf
chk_list $1
timer start
for rec in `cat ${list}`; do
	host=`echo $rec|awk -F: '{print $1}'`
	os=`echo $rec|awk -F: '{print $2}'`
	echo -n "$host... "
	case $os in
		Linux)
			fetch="wget --quiet"
		;;
		FreeBSD)
			fetch="fetch -q"
		;;
	esac
	ssh -q $host "cd ~/.ssh; $fetch $keyurl; mv id_dsa.pub authorized_keys; cp authorized_keys identity.pub; chmod 600 authorized_keys identity.pub" 
	if [ "$?" -eq "0" ];then
			echo "OK"
		else 
			echo "FAILED"
	fi
done
timer stop

