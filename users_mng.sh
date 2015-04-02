#!/bin/sh
. ~/etc/mnt.conf
parse_args $*
chk_list $list
echo "user is $username"
echo "pass is $pass"
echo "shell is $shell"
echo "is root: $root"
echo "Comment: $comment"

for rec in `cat $list`;do
	#FIXME
	host=`echo $rec|awk -F: '{print $1}'`
	os=`echo $rec|awk -F: '{print $2}'`
	if [ -z "$os" ]; then
		get_os $host
		if [ -z "$os" ]; then
			echo "Can't terminate OS for $host"
			continue;
		fi
	fi
	GID=""
	UID=""
	if [ "$root" = "yes" ]; then
		if [ "$os" = "FreeBSD" ];then
				GID="-g 0"
 			else
				GID="-g 10"
		fi
	fi
	case $action in
		add)
		if [ "$os" = "FreeBSD" ]; then
			ssh $host "echo '$pass'|sudo pw useradd $username -c \"$comment\" ${GID} -s $shell -m -d /home/$username -h 0"	
			if [ "$root" = "yes" ];then
				ssh $host "echo '$pass'|sudo pw useradd r_$username -c \"$comment\" ${GID} -s $shell -m -d /home/r_$username -h 0; sudo sed -Ee 's/(^r_${username}:[^:]+:)[0-9]+(.*)/\10\2/' -i '' /etc/master.passwd; sudo pwd_mkdb -p /etc/master.passwd"	
			fi
		fi
		if [ "$os" = "Linux" ]; then
			ssh $host "sudo /usr/sbin/adduser ${GID} -d /home/${username} -s $shell -c \"$comment\" ${username}; echo $pass|sudo passwd --stdin ${username}"
			if [ "$root" = "yes" ]; then
				ssh $host "sudo /usr/sbin/adduser -o -u0 ${GID} -d /home/r_${username} -s $shell -c \"$comment\" r_$username; echo $pass|sudo passwd --stdin r_$username"
			fi
		fi
		;;
		del)
		if [ "$os" = "FreeBSD" ]; then	
			ssh $host "sudo pw userdel $username -r"
			if [ "$root" = "yes" ]; then
				ssh $host "sudo pw userdel r_${username} -r; sudo rm -rfd /home/r_${username}"
			fi
		fi
		if [ "$os" = "Linux" ]; then
			ssh $host "sudo /usr/sbin/userdel -r ${username}"
			if [ "$root" = "yes" ]; then
				ssh $host "sudo /usr/sbin/userdel -r r_${username}"
			fi
		fi
		;;
		block)
		if [ "$os" = "FreeBSD" ]; then
			user_regex="$username"
			if [ "$root" = "yes" ]; then
				user_regex="($username|r_$username)"
			fi
			ssh $host "sudo echo '/^($user_regex):/s/:\\$1\\$[0-9a-zA-Z\\$/.]+:/:*:/;/^$user_regex:/s/[a-z\/]+$/\/usr\/sbin\/nologin/' /tmp/out"
			echo ssh $host "sudo sed -Ee '/^($user_regex):/s/:\$1\$[0-9a-zA-Z\$/.]+:/:*:/;/^$user_regex:/s/[a-z\/]+$/\/usr\/sbin\/nologin/' /etc/master.passwd > /tmp/out"
		fi
		;;
	esac
done

