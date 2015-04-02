#!/bin/sh
. /home/mnt/etc/mnt.conf
add_user() {
	newuser=$1
	list=$2
	echo -n "Input shell> " 
	read shell	
	echo -n "Input realname> "
	read realname
	echo -n "Create root for this user? [y/n]> "
	read is_root
	echo -n "Input password> "
	read pass
	for rec in `cat ${list}`;do
		#FIXME
		host=`echo $rec|awk -F: '{print $1}'`		
		os=`echo $rec|awk -F: '{print $2}'`
		echo -n "Preparing $host ($os) "
		if [ "${is_root}" = "y" ]; then
			GID="-g 0"
			else
			GID=""
		fi
		if [ "${os}" = "FreeBSD" ]; then
			ssh $host "echo '$pass'|sudo pw useradd $newuser -c  \"$realname\" ${GID} -s $shell -m -d /home/${newuser} -h 0"
			if [ "${is_root}" = "y" ]; then
			ssh $host "echo '$pass'|sudo pw useradd r_$newuser -c  \"$realname\" -g0 -s $shell -m -d /home/r_${newuser} -h 0; sudo sed -Ee 's/(^r_${newuser}:[^:]+:)[0-9]+(.*)/\10\2/' -i '' /etc/master.passwd; sudo pwd_mkdb -p /etc/master.passwd"
			
			fi
		fi
		if [ "${os}" = "Linux" ]; then
			echo "sudo /usr/sbin/adduser ${GID} -d /home/${newuser} -s ${shell} -c \"${realname}\" ${newuser}; echo $pass|sudo passwd --stdin ${newuser}" 
			if [ "${is_root}" = "y" ]; then
				echo "sudo /usr/sbin/adduser -o -u0 ${GID} -d /home/r_${newuser} -s ${shell} -c \"${realname}\" r_${newuser}; echo $pass|sudo passwd --stdin r_${newuser}" 
			fi
		fi
		echo "[OK]"
	done
}
if [ "${1}" = "" ]; then
		echo "Input server list: "
		if [ "${lists}" != "" ]; then
			for group in ${lists} ;do
				printf "\t%s\n" ${listdir}/$group
			done
		fi
		echo -n ">"
		read list
	else
		list=${1}
fi
if [ ! -f ${list} ]; then
	echo "Server list ${list} not found"
	exit 1
fi
echo -n "Input user name: "
read username
printf "Action for user: [%s]\n1. Add\n2. Del\n3. Change password\n4. Exit\n>" $username 
read i 
case $i in
	1)
		add_user $username $list
	;;
	2)
	;;
	3)
	;;
	4)
		exit 0;
	;;
	*)
		echo "Error input" 
		exit 1;
	;;
esac
