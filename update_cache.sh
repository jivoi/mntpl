#!/bin/sh
. ~/etc/mnt.conf
uniq=${$}
chk_list $1
bs=`basename $list`
cp ${list} ~/tmp/${bs}.${uniq}
timer start
echo -n >${list}
for host in `cat ~/tmp/${bs}.${uniq} | awk -F: '{print $1}'`;do 
	echo -n "Terminating OS for ${host}..."
	os=`ssh -q $host uname -s`
	if [ "${?}" = 0 ]; then
			echo "($os) OK"
		else
			echo "FAILED"
	fi
	#if [ "${os}" = "FreeBSD" ];do
	#	
	#done
	echo "${host}:${os}" >> ${list}
done
for group in ${groups};do
	grep "$group" $list > ${listdir}/$group
done
rm ~/tmp/${bs}.${uniq}
timer stop
