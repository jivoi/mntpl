import sys,string
from fabric.api import *
from fabric.network import disconnect_all
from random import Random

env.shell = '/bin/sh -c'
env.always_use_pty = False
sudo.pty = False
sudo.shell = '/bin/sh -c'
env.sudo_prefix = "sudo -H"
env.warn_only = True

good_password = ''

with open('/home/mnt/lists/all', 'r') as f:
    env.hosts = f.readlines()
#env.hosts = ['host1', 'host2']
def host_type():
     with hide('running', 'status', 'stderr', 'warnings', 'stdout'):
        return run('uname -s')

def run_fw():
    with hide('running', 'status', 'stderr', 'warnings'):
        sudo('[ -f /etc/rc.conf ] && cat /etc/rc.conf | egrep -q -i ^firewall_enable.*YES && sh /etc/ipfw.rules; [ -f /root/bin/fw.sh ] && sh /root/bin/fw.sh; [ -f /etc/pf.my.conf ] && pfctl -f /etc/pf.my.conf')

def safe_run_fw():
    env.warn_only = False
    run_fw()
    disconnect_all()
    host_type()
    disconnect_all()

def block_user(user):
    with hide('running', 'status', 'stderr', 'warnings'):
        sudo("egrep -q ^%s /etc/passwd && mv /home/%s/.ssh /home/%s/.ssh_bckp && if [ -f /usr/sbin/pw ]; then /usr/sbin/pw lock %s; else /usr/sbin/usermod -L %s; fi" % (user, user, user, user, user) )
    sudo("egrep -q ^r_%s /etc/passwd && mv /home/r_%s/.ssh /home/r_%s/.ssh_bckp && if [ -f /usr/sbin/pw ]; then /usr/sbin/pw lock r_%s; else /usr/sbin/usermod -L r_%s; fi" % (user, user, user, user, user) )

def change_password(user,new_password=''):
    with hide('running', 'status', 'stderr', 'warnings', 'stdout'):
        rng = Random()
        allchars = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890'
        password = ''
        global good_password
        for i in range(8):
            password += rng.choice(allchars)
        if ( new_password != ''):
            password = new_password
        if ( good_password != '' ):
            password = good_password
        if not run("egrep -q ^%s /etc/passwd" % (user) ).failed:
            if ( host_type() == "FreeBSD" ):
                run("egrep -q ^%s /etc/passwd && echo %s | sudo /usr/sbin/pw usermod %s -h0 -p 1" % (user, password, user) )
            else:
                if run("egrep -q ^%s /etc/passwd && echo %s | sudo /usr/bin/passwd --stdin %s" % (user, password, user) ).failed :
                    change_password(user)
                else:
                    good_password = password
                    print "\033[1;32mSetting password for user %s: %s\033[1;m" % (user, password)

def add_user(user,comment,root=False,shell="/bin/csh"):
    if ( root ):
        if ( host_type() == "FreeBSD" ):
            if not sudo( "pw useradd %s -c '%s' -g 0 -s %s -m -d /home/%s" % (user, comment, shell, user) ).failed:
                if not sudo( "pw useradd r_%s -c '%s' -g 0 -s %s -m -d /home/r_%s" % (user, comment, shell, user) ).failed:
                    sudo("sed -Ee 's/(^r_%s:[^:]+:)[0-9]+(.*)/\\10\\2/' -i '' /etc/master.passwd" % (user) )
                    sudo("pwd_mkdb -p /etc/master.passwd")
                    sudo("chown -R r_%s:wheel /home/r_%s" % (user, user) )
                    change_password(user,good_password)
                    change_password('r_'+user,good_password)
        else:
            if not sudo( "/usr/sbin/adduser -g 10 -d /home/%s -m -s %s -c '%s' %s" % (user, shell, comment, user) ).failed:
                if not sudo( "/usr/sbin/adduser -g 10 -o -u0 -d /home/r_%s -m -s %s -c '%s' r_%s" % (user, shell, comment, user) ).failed:
                    change_password(user,good_password)
                    change_password('r_'+user,good_password)
    else:
        if ( host_type() == "FreeBSD" ):
            if not sudo( "pw useradd %s -c '%s' -s %s -m -d /home/%s" % (user, comment, shell, user) ).failed:
                change_password(user,good_password)
        else:
            if not sudo( "/usr/sbin/adduser -d /home/%s -m -s %s -c '%s' %s" % (user, shell, comment, user) ).failed:
                change_password(user,good_password)

def del_user(user):
    with hide('running', 'status', 'stderr', 'warnings'):
        if ( host_type() == "FreeBSD" ):
            sudo('pw userdel %s -r' % ( user ) )
        else:
            sudo('/usr/sbin/userdel -r %s' % ( user ) )

def collect_etccache(file):
    with hide('running', 'status', 'stderr', 'warnings', 'stdout'):
        host = run( 'hostname' )
        get( '/etc/%s' % (file), '~/cache/%s.%s' % (file, host) )
    pass
