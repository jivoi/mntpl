#!/bin/sh
. ~/etc/mnt.conf
chk_list $1
shift
command=$*
for rec in `cat $list`;do
	host=`echo $rec|awk -F: '{print $1}'`
	os=`echo $rec|awk -F: '{print $2}'`
	echo $host \($os\)...
	ssh $host $command
done
