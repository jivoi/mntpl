#!/bin/sh
PATH="/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin:"
USER=mnt
HOME=/home/${USER}
SHELL=/bin/csh
GROUP=${USER}
_UID=6668
GID=${_UID}
OS=`uname -s`
FreeBSD_SUDOFILE="/usr/local/etc/sudoers"
Linux_SUDOFILE="/etc/sudoers"



FreeBSD_USERADD="pw useradd ${USER} -u ${_UID} -g ${GID} -c "control" -s ${SHELL} -m -d ${HOME} ${USER}"
Linux_USERADD="useradd -u ${_UID} -g ${GID} -d ${HOME} -s ${SHELL} -c 'control' ${USER}"

case "$OS" in
	'FreeBSD')
		echo "OS is FreeBSD";
		symbol="*"
		user_add=${FreeBSD_USERADD}
		sudofile=${FreeBSD_SUDOFILE}
	;;
	'Linux')
		echo "OS is Linux";
		symbol="x"
		user_add=${Linux_USERADD}
		sudofile=${Linux_SUDOFILE}
		
	;;
	*)
		echo "Unknown OS, current support only FreeBSD/Linux"
		exit
	;;
esac

if [ -z "`grep -F "${USER}:${symbol}:${GID}:" /etc/group`" ];then
		echo "Adding group ${GID}"
		echo "${USER}:${symbol}:${GID}:" >> /etc/group
	else 
		echo "Group ${GID} exists"
fi
if [ -z "`grep -E "^${USER}:" /etc/passwd`" ];then
		echo "Adding user ${USER}"
		${user_add}
	else
		echo "User ${USER} exists"
fi
if [ -z "`grep -E "^${USER} " ${sudofile}`" ];then
		echo "Adding user ${USER} to ${sudofile}"
		echo "### remote control user" >> ${sudofile}
		echo "${USER}  ALL = NOPASSWD: ALL" >> ${sudofile}
		echo "" >> ${sudofile}
	else
		echo "User ${USER} in ${sudofile} exists"
fi
if [ -d "${HOME}/.ssh" ]; then
		echo ${HOME}/.ssh exists
	else 
		echo "Make dir ${HOME}/.ssh"
	 	mkdir ${HOME}/.ssh
fi
echo "from=\"mnt.example.ru\",no-pty,no-port-forwarding,no-agent-forwarding,no-X11-forwarding SSHKEY" > ${HOME}/.ssh/identity.pub
cat ${HOME}/.ssh/identity.pub > ${HOME}/.ssh/authorized_keys
printf "setenv PATH \"/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:\"\nalias ls ls -aG\nset nobeep\nset prompt='[%%n@%%M %%~]$ '\n" > ~/.cshrc
chmod 600 ${HOME}/.ssh/identity.pub ${HOME}/.ssh/authorized_keys
chown -R mnt:${GID} ${HOME}
