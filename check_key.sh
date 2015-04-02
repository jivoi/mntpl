#!/bin/sh
. ~mnt/etc/mnt.conf
chk_list $1
timer start
for rec in `cat ${list}`; do
	host=`echo $rec|awk -F: '{print $1}'`
	echo -n "${host}... "
	ssh -2q $host "echo -n"
	if [ $? = 0 ]; then 
		echo "OK"
		else 
		echo "FAILED"
	fi
done
timer stop
