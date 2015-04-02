#!/usr/bin/perl -I/home/mnt/bin -I /home/mnt/bin/mnt 
use mntpm::db;
use mntpm::config;

%cfg = (
	base => "/home/mnt",
	hosts => ".ssh/know_hosts",
	cache_dir => "cache",
	cache_hosts => "hosts",
	cache_expire => 43200, #12h
	ssh_qwe123 => "/home/mnt/bin/ssh_qwe123.expect"
);


sub load_cache() {
	my %r = ();
	my $pwd = $cfg{base} . "/" . $cfg{cache_dir};
	opendir(d, $pwd) || return %r;
	foreach $l (readdir(d)) {
		my $type = "";
		if ($l =~ /^os\.[a-z0-9A-Z.]+/ ) {
			#os cache
			$type = "os";
		} elsif ($l =~ /^group\.[a-z0-9A-Z.]+/ ) {
		#group cache
			$type = "group";
		} elsif ($l =~ /^passwd\.[a-z0-9A-Z.]+/ ) {
		#passwd cache
			$type = "passwd";
		} else {
			#skip 
			next;	
		}
		open(f, $pwd . "/" . $l) || next;
		$l =~ s/^[a-zA-Z]+\.//;
		#remove prefix os. passwd. group.
		my @stats = stat f;
		# time to change cache 
		$r{modify}{$l} = $stats[9];
		while(<f>) {
			#skip comments
			if ($_ =~ /^([ ]+)?#/){
				next;
			}
			$_ =~ s/\n$//;
			if ($type eq "os") {
				$r{$type}{$l} = $_;		
			} else {
				push @{$r{$type}{"$l"}}, $_;
			}
		}	
		close(f);
			
	}
	closedir(d);
	return %r;
}

sub show_help($) {
	($errno) = @_;
	printf(STDERR "Error: %s\n", $errno) unless !$errno;
	printf(STDERR "Usage:\n");
	printf(STDERR "\tActions:\n");
	printf(STDERR "\t\t-a add user\n");
	printf(STDERR "\t\t-d remove user\n");
	printf(STDERR "\t\t-b block user\n");
	printf(STDERR "\t\t-c run command\n");
	printf(STDERR "\t\t-sh run local script on remote server (/bin/sh)\n");
	printf(STDERR "\t\t-sudosh run local script with root privileges on remote server (/bin/sh)\n");
	printf(STDERR "\t\t-P change password\n");
	printf(STDERR "\t\t-U update cache\n");
	printf(STDERR "\t\t-I install cvsbackup\n");
	printf(STDERR "\t\t-D check users for default password (qwe123), need /home/mnt/bin/ssh_qwe123.expect\n");
	printf(STDERR "\t\t-X update stats for web\n"); 
	printf(STDERR "\tArgs:\n");
	printf(STDERR "\t\t-u <username> set username\n");
	printf(STDERR "\t\t-p <password> set password (default: random generated)\n");
	printf(STDERR "\t\t-s <shell> shell (default /bin/csh)\n");
	printf(STDERR "\t\t-C <comment> comments for user,typicaly realname (default \"New user\")\n");
	printf(STDERR "\t\t-r set root privilegies for new user (default NO)\n");
	printf(STDERR "\t\t-e do not expire password (all passwords are expired by default)\n");
	printf(STDERR "\t\t-h this page\n");
	
	printf(STDERR "\tServer lists:\n");
	printf(STDERR "\t\t-l <servre1,server2,...> get from command line\n");
	printf(STDERR "\t\t-f <file> get server list from file\n");
	printf(STDERR "\tExamples (for dummies):\n");
	printf(STDERR "\t\tmnt.pl -l \"server.domain.ru,server2.domain.ru\" -c \"echo hello world\"\n");
	printf(STDERR "\t\tmnt.pl -f /home/mnt/lists/all -a -u NewAdmin -C \"Join Smith\" -s /bin/bash -r\n");
	
	exit;
}

sub parse_args(@) {
	my(@a) = @_;
	my(%r);	
	my($list_exists) = 1;
	while ($a[0] ne "") {
		# actions
		if ($a[0] eq "-h" || $a[0] eq "--help") {
			show_help(undef);
		}
		if ($a[0] eq "-a") {
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 1; # add user
		}	
		if ($a[0] eq "-d") {
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 2; # del user
		}
		if ($a[0] eq "-b") {
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 3; # block user
		}
		if ($a[0] eq "-c") {
			show_help("-c need args or action already defined") unless !exists $r{action} && $a[1] ne "";
			shift @a;
			$r{cmd} = $a[0];
			$r{action} = 4; # run command
		}
		if ($a[0] eq "-U" ){
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 5; # update cache
		}
		if ($a[0] eq "-P" ){
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 6; # change password
		}
		if ($a[0] eq "-I" ){
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 7; # install cvsbackup
		}
		if ($a[0] eq "-D" ){
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 8; # check default pass
		}
		if ($a[0] eq "-X") { 
			show_help("Action already defined") unless !exists $r{action};
			$r{action} = 9; #update stats;
		}

                if ($a[0] eq "-sh") {
                        show_help("-sh need args or action already defined") unless !exists $r{action} && $a[1] ne "";
                        shift @a;
                        $r{script} = $a[0];
                        $r{action} = 10; # run script
                }

                if ($a[0] eq "-sudosh") {
                        show_help("-sudosh need args or action already defined") unless !exists $r{action} && $a[1] ne "";
                        shift @a;
                        $r{script} = $a[0];
                        $r{action} = 11; # run sudo script
                }

		#stuff 
		# username
		if ($a[0] eq "-u") {
			show_help("Username already defined") unless $a[1] ne "" && !exists $r{user};
			shift @a;
			$r{user} = $a[0];
			next;
		}
		#output password file
		if ($a[0] eq "-o") {
			show_help("Username already defined") unless $a[1] ne "" && !exists $r{p_out};
			shift @a;
			$r{p_out} = $a[0];
			next;
		}
		#shell
		if ($a[0] eq "-s") {
			show_help("-s need argument or shell already defined") unless $a[1] ne "" && !exists $r{shell};
			shift @a;
			$r{shell} = $a[0];
			next;
		}
		#file of list servers 
		if ($a[0] eq "-f") {
			show_help("-f need argument") unless !exists $r{servers} && $a[1] ne "";
			shift @a;	
			$r{list} = $a[0];
			$r{type} = 0;
			next;
		}
		# server list 
		if ($a[0] eq "-l") {
			show_help("-l need argument") unless !exists $r{list} || !exists $r{servers};
			shift @a;	
			$r{servers} = $a[0];
			$r{type} = 1;
			next;
		}	
		
		#password 
		if ($a[0] eq "-p") {
			show_help("-p need argument") unless $a[1] ne "" && !exists $r{pass};
			shift @a;
			$r{pass} = $a[0];
			$r{manualpass} = 1;
			next;
		}
		#comments
		if ($a[0] eq "-C") {
			show_help("-C need argument or already defined") unless $a[1] ne "" && !exists $r{comment};
			shift @a;
			$r{comment} = $a[0];
			next;
		}
		#flags
		if ($a[0] eq "-r") {
			$r{is_root} = 1;
		}
		if ($a[0] eq "-e") {
			$r{noexpire} = 1;
		}
		shift @a;
	}
	#list exists?
	if (exists $r{list} && !-f $r{list}) {
		show_help("list not found");
	}
	if (!defined $r{servers} && !defined $r{list}) {
		$list_exists = 0;
	}
        #script exists?
        if (exists $r{script} && !-f $r{script}) {
                show_help("script not found");
        }
	#output password file
	if (!exists $r{p_out}) {
		$r{p_out} = "/home/mnt/password.lst";
	}
	#check action
	if (!exists $r{action}) {
		show_help("Action not present");
	}
	#check list servers (if not update cache)
	if (!exists $r{servers} && !$list_exists && $r{action} != 5) {
		show_help("servers and server list defined, wtf man?");
	}
	#update cache
	#printf("%d\n", $list_exists);
	if ($r{action} == 5 && !$list_exists) {
		show_help("update cache need option list (-l or -f)");	
	}

	foreach $useraction (1,2,3,6) {
		if ($r{action} == $useraction) { $needusername = 1};
	}
	if ( $needusername && !$r{user} ) {
		show_help("this command requires user name (-u)");
	}

	$r{is_root} = 0 unless exists $r{is_root};
	$r{comment} = "New user" unless exists $r{comment};
	$r{shell} = "/bin/csh" unless exists $r{shell};

	# if we're creating user or changing password we should have 
	# strong password
	if (!(exists $r{pass}) && ($r{action} == 1 || $r{action} == 6) ) {
		$r{pass}=get_rnd_pass();
	} ;
	return %r;
}
sub get_rnd_pass() {
	@_ = `/home/mnt/bin/genpass-new`;
#	printf("Generated password: %s\n", @_);
	return $_[0];
}
sub get_ssh_users($$) {
	my ($srv,$os) = @_;
	my @r;
	foreach $user (@{$c{passwd}{"$srv"}}) {	
		push @r, $user unless $user !~ /sh$/ || $user =~ /^mnt/;
	}
	return @r;
}
sub get_servers($$) {
	my($a,$type) = @_;
	my(@ret);
	my($i) = 0;
	if ($type == 0) {
		open(IN, "<$a") || die "Can't open server list $a";
		while(<IN>) {
			if ($_ !~ /^( |\n)+$/) {
				$_  =~ s/\n$//;
				push @ret, $_;
			}
		}
		close(IN);	
	}
	if ($type == 1) {
		split(",",$a);
		for(my($i) == 0; $i < scalar(@_); $i++) {	
			push @ret, $_[$i];
		}
	}
	return @ret;
}
sub run_command($$) {
	my($server,$command) = @_;
	printf("-----------> %s\n", $server);
	my($run) = sprintf("ssh -o 'StrictHostKeyChecking no' mnt@%s %s 2>&1",$server, $command);
	local $SIG{INT} = sub { return };
	printf("%s\n", $run);
	my(@out) = `$run`;
# commented out - produced double output
#	foreach $o (@out) {
#		printf("%s",$o);
#	}
	return @out;
}

sub run_script($$$) {
        my($server,$script,$sudo) = @_;
        printf("-----------> %s\n", $server);
        my($run) = sprintf("cat %s | ssh -o 'StrictHostKeyChecking no' mnt@%s %s/bin/sh 2>&1",$script,$server,$sudo);
        local $SIG{INT} = sub { return };
        printf("%s\n", $run);
        my(@out) = `$run`;
        return @out;
}

sub command_result($$) {
        my($server,$command) = @_;
        printf("-----------> %s\n", $server);
        my($run) = sprintf("ssh -o 'StrictHostKeyChecking no' mnt@%s %s",$server, $command);
        local $SIG{INT} = sub { return };
        printf("%s\n", $run);

        my($out) = system($run);
        return $out;
}


sub out_arr(@) {
	my(@out) = @_;
	for($i = 0; $i < scalar(@out); $i++) { printf("%s", $out[$i]) };
}
sub get_server($) {
	my($rec) = @_;
	split(":",$rec);	
	return $_[0];
}
sub get_os($) {
	my($rec) = @_;
	if (exists $c{os}{$rec}) {
		return $c{os}{$rec};
	} else {
		my(@out) = run_command($rec, "uname -s");
		update_cache_os($rec, $out[0]);
		$out[0] =~ s/\n$//;
		return $out[0];
	}
}
sub remote_rename_file($$$) {
	my($srv,$src,$dst) = @_;
	$cmd=sprintf("'sudo /bin/sh -c \"if [ -f %s ]; then mv %s %s;fi\"'",$src,$src,$dst);
	run_command($srv,$cmd);
}
sub remote_create_dir($$) {
	my($srv, $dir) = @_;
	$cmd = sprintf("'sudo /bin/sh -c \"if [ ! -d %s ]; then mkdir %s;fi\"'",$dir,$dir);
	run_command($srv, $cmd);
}
sub block_user {
	my($srv, $user, $os) = @_;
	my($cmd) = "";
	$os = get_os($srv) unless $os ne "";	
	if ($os eq "Linux") {
		$cmd=sprintf("\"sudo usermod -L %s\"", $user);
	} elsif ($os eq "FreeBSD") {
		$cmd=sprintf("\"sudo pw lock %s\"", $user);
	} else {
		printf(STDERR "Can't determine OS host %s\n", $srv);
		return 0;
	}
	if (scalar((@o = run_command($srv, $cmd))) != 0) {
		printf(STDERR "%s", $o[0]);
		return 0;
	}
	remote_rename_file($srv, "~" . $args{user} . "/.ssh/authorized_keys", "~" . $args{user} . "/.ssh/authorized_keys.bckp");
	remote_rename_file($srv, "~" . $args{user} . "/.ssh/authorized_keys2", "~" . $args{user} . "/.ssh/authorized_keys2.bckp");
	return 1;

}
sub set_pass {
	my ($srv,$user,$os) = @_;
	my $command;

	if ($os eq "FreeBSD") {
	        # Do not expire root users and if -e specified
		if (($user eq "root") || ($user =~ "^r_") || $args{noexpire}) {
			$exp = "";
		} else { $exp = "-p 1"};
	} else {
		if ($user ne "root") {
			$chage = ($args{noexpire}) ? "" : "\"sudo /usr/bin/chage -d 0 $user\"";
		} else { $chage = "" };
	}

	my $tries=10;
	my $res=1;
	if ( $args{manualpass} ) { $tries = 1 }; 

	while (($tries > 0) && $res) {
		if ($os eq "FreeBSD") {
			$command=sprintf("\"echo %s|sudo /usr/sbin/pw usermod %s -h0 %s\"",
				$args{pass},$user,$exp);
		} else {
			$command=sprintf("\"echo %s|sudo /usr/bin/passwd --stdin %s\"",
				$args{pass},$user);
		}
		$res = command_result($srv,$command);

		# try other password if it was random generated and current does not fit
		if($res && !$r{manualpass}) { 
			$args{pass}=get_rnd_pass();
		}
		
		$tries--;
	}

	if (!$res) {
		printf("--- Set password: %s\n", $args{pass});
	}

	if (!$res && $chage) {
		run_command($srv,$chage);
	}

	return $res;
}

sub pwuseradd {
	my ($srv,$user,$os) = @_;
	my $command;
	
	if ($os eq "FreeBSD") {
		if ($user =~ /^r_/) {
			# special commands for root users
			$command=sprintf("\"sudo pw useradd %s -c '%s' -g0 -s %s -m -d /home/%s",
				$user, $args{comment}, $args{shell}, $user);
			$command=sprintf("%s && sudo sed -Ee 's/(^%s:[^:]+:)[0-9]+(.*)/\\10\\2/' -i '' /etc/master.passwd",
				$command, $user);
			$command=sprintf("%s && sudo pwd_mkdb -p /etc/master.passwd && sudo chown -R %s:wheel /home/%s\"",
				$command, $user, $user);
		} else {
			# simple user
			$command=sprintf("\"sudo pw useradd %s -c '%s' %s -s %s -m -d /home/%s\"",
				$user, $args{comment},
				($args{is_root}) ? "-g 0" : "",
				$args{shell}, $user);
		}
	} else {
			# just changing -g 10 and -o -u 0 for root and simple users
                        $command=sprintf("\"sudo /usr/sbin/adduser %s %s -d /home/%s -m -s %s -c '%s' %s\"",
				($args{is_root}) ? "-g 10" : "",
				($user =~ /^r_/) ? "-o -u0" : "",
                                $user, $args{shell}, $args{comment}, $user);
	}

	return command_result($srv, $command);
}

sub add_user {
        my ($srv,$user,$os) = @_;
        my $command;

	# set password if user added
	if  ($res = pwuseradd($srv, $user, $os)) {
		printf(STDERR "%s: Cannot add user %s\n", $srv, $args{user});
	} else {
		if (set_pass($srv, $user, $os)) {
			printf(STDERR "%s: Cannot set password for user %s\n", $srv, $args{user});
		}
	}

	return $res;
}

sub update_cache_os($$) {
	my($s,$o) = @_;
	open(h, ">$cfg{base}/$cfg{cache_dir}/os.$s") || die "Can't open os cache file for write";
	printf h "%s", $o;
	close(h);
}
sub update_cache_group {
	my($s) = @_;
	shift;
	my(@g) = @_;
	open(h, ">$cfg{base}/$cfg{cache_dir}/group.$s") || die "Can't open group cache file for write";
	foreach $r (@g) {
		printf h "%s", $r;
	}
	close(h);
}
sub update_cache_passwd {
	my($s) = @_;
	shift;
	my(@g) = @_;
	open(h, ">$cfg{base}/$cfg{cache_dir}/passwd.$s") || die "Can't open passwd cache file for write";
	foreach $r (@g) {
		printf h "%s", $r;
	}
	close(h);
}
sub update_cache_crontab {
        my($s) = @_;
        shift;
        my(@g) = @_;
        open(h, ">$cfg{base}/$cfg{cache_dir}/crontab.$s") || die "Can't open crontab cache file for write";
        foreach $r (@g) {
                printf h "%s", $r;
        }
        close(h);
}

sub update_cache_hosts {
        my($s) = @_;
        shift;
        my(@g) = @_;
        open(h, ">$cfg{base}/$cfg{cache_dir}/hosts.$s") || die "Can't open hosts cache file for write";
        foreach $r (@g) {
                printf h "%s", $r;
        }
        close(h);
}

sub update_cache_resolv {
        my($s) = @_;
        shift;
        my(@g) = @_;
        open(h, ">$cfg{base}/$cfg{cache_dir}/resolv.conf.$s") || die "Can't open resolv.conf cache file for write";
        foreach $r (@g) {
                printf h "%s", $r;
        }
        close(h);
}

sub update_cache_sysctl {
        my($s) = @_;
        shift;
        my(@g) = @_;
        open(h, ">$cfg{base}/$cfg{cache_dir}/sysctl.conf.$s") || die "Can't open sysctl.conf cache file for write";
        foreach $r (@g) {
                printf h "%s", $r;
        }
        close(h);
}

sub update_cache {
	my(@l) = @_;	
	for(my($i) = 0; $i < scalar(@l); $i++) {
		
		#if (defined $c{modify}{$l[$i]}) {
			#if (time() - $c{modify}{$l[$i]} <= $cfg{cache_expire}) {
			#	#skip update for this host
			#	printf("cache for %s not expire\n",$l[$i]);
			#	next;
			#}
		#}
		my($os) = "";	
		
		my(@o) = run_command($l[$i], "uname -s");
		my $os = "";
		foreach $k (@o) {
			if ($k =~ /FreeBSD|Linux/) {
				if ($k =~ /Linux/) {
					$os = "Linux";
				} elsif ($k =~ /FreeBSD/) {
					$os = "FreeBSD";
				}
			}
		}
		if ($os eq "") {
			printf(STDERR "Can't determine os for %s\n", $l[$i]);
			next;
		}
		if ($os eq "Linux") {
			@o = run_command($l[$i], "sudo cat /etc/passwd");
		} elsif ($os eq "FreeBSD") {
			@o = run_command($l[$i], "sudo cat /etc/passwd");
		} 
		update_cache_passwd($l[$i], @o);
		@o = run_command($l[$i], "sudo cat /etc/group");
		update_cache_group($l[$i], @o);
		@o = run_command($l[$i], "sudo cat /etc/crontab");
		update_cache_crontab($l[$i], @o);
		@o = run_command($l[$i], "sudo cat /etc/hosts");
		update_cache_hosts($l[$i], @o);
                @o = run_command($l[$i], "sudo cat /etc/resolv.conf");
                update_cache_resolv($l[$i], @o);
                @o = run_command($l[$i], "sudo cat /etc/sysctl.conf");
                update_cache_sysctl($l[$i], @o);

		update_cache_os($l[$i], $os);
	}
}
sub check_qwe123($$) {
	my($user,$srv) = @_;
	my $run = sprintf("%s %s@%s >/dev/null 2>&1;echo -n \$?",$cfg{ssh_qwe123},$user,$srv);
	my @out = `$run`;
	return int($out[0]);
	
}
sub update_stats($) {
	my ($srv) = @_;
	foreach $o (run_command($srv, "uname -rsnv")) {
		if ($o =~ /Linux|FreeBSD/) {
			my ($os,$host,$reliz,$version) = split(" ", $o,4);
			$version =~ m/.*(#.*)$/;
                        $version = $1;
			my $q = sprintf "INSERT INTO servers VALUES('%s','%s','%s','%s')", $host, $os, $reliz, $version;
			db::query($main::d, $q);
		}	
	}
}
%c = load_cache();
%args = parse_args(@ARGV);
@servers = get_servers((exists $args{list}) ? $args{list} : $args{servers}, $args{type});


if (scalar(@servers) == 0) {
	printf(STDERR "Server list is empty\n");
	exit 2;
}
# just run command
if ($args{action} == 4) {
	for(my($i) = 0; $i < scalar(@servers); $i++) {
		$srv = get_server($servers[$i]);
		my(@out) = run_command($srv, $args{cmd});
		out_arr(@out);
	}
}
# just run script
if ($args{action} == 10) {
        for(my($i) = 0; $i < scalar(@servers); $i++) {
                $srv = get_server($servers[$i]);
                my(@out) = run_script($srv, $args{script},"");
                out_arr(@out);
        }
}

# just run sudo script
if ($args{action} == 11) {
        for(my($i) = 0; $i < scalar(@servers); $i++) {
                $srv = get_server($servers[$i]);
                my(@out) = run_script($srv, $args{script},"sudo -H ");
                out_arr(@out);
        }
}

#add new user;
if ($args{action} == 1) {
	for(my($i) = 0; $i < scalar(@servers); $i++) {
		$os = get_os($servers[$i]);
		$srv = get_server($servers[$i]);

		if ($os =~ /^(FreeBSD|Linux)$/i) {

			# add simple user
			my $res = add_user($srv, $args{user}, $os);

			# add root user of needed nd simple user was OK
			if (!$res && $args{is_root}) {
				add_user($srv, "r_" . $args{user}, $os);
			}
		} else { printf(STDERR "%s is not Linux or FreeBSD\n", $srv);}
	}
}
#userdel
if ($args{action} == 2) {
	for(my($i) = 0; $i < scalar(@servers); $i++) {
		$os = get_os($servers[$i]);
		$srv = get_server($servers[$i]);
		if ($os =~ /FreeBSD/i) {
			$command=sprintf("sudo pw userdel %s -r", $args{user});
			run_command($srv, $command); 
			if ($args{is_root}) {
				$command=sprintf("sudo pw userdel r_%s", $args{user});	
				run_command($srv, $command);
			}
			next;
		}
		if ($os =~ /Linux/i) {
			$command=sprintf("sudo /usr/sbin/userdel -r %s", $args{user});
			run_command($srv, $command);
			if ($args{is_root}) {
				$command=sprintf("sudo /usr/sbin/userdel -r r_%s", $args{user});
				run_command($srv, $command);
			}
			next;
		}
		printf(STDERR "%s is not Linux or FreeBSD\n", $srv);
	}
}
#block user
if ($args{action} == 3) {
	for(my($i) = 0; $i < scalar(@servers); $i++) {
		block_user(get_server($servers[$i]), $args{user}, get_os($servers[$i]));
	}
}
# update cache
if ($args{action} == 5) {
	update_cache(@servers);
}
#change password
if ($args{action} == 6) {
	open(fd, ">>$args{p_out}");
	for(my($i) = 0; $i < scalar(@servers); $i++) {
		$os = get_os($servers[$i]);
		$srv = get_server($servers[$i]);
		$pass = $args{pass};
		printf fd "%s: %s\n", $srv, $pass;

		if ($os =~ /^(FreeBSD|Linux)$/) {
	                if (set_pass($srv, $args{user}, $os)) {
       		                 printf(STDERR "%s: Cannot set password for user %s\n", $srv, $args{user});
                	}
		} else { printf "%s: unknown OS: %s\n", $srv, $os;}

		# get new password if it is not set manually
		if (!$args{manualpass}) {
                        $args{pass}=get_rnd_pass();
		}
	}
	close(fd);
}
#install cvsbackup
if ($args{action} == 7) {
	foreach $rec (@servers) {
		my $srv = get_server($rec);
		my $os = get_os($srv);
		my $cmd = "";
		if ($os =~ /FreeBSD/) {
			$cmd = sprintf("\"setenv HTTP_AUTH \'basic:\*:cvsbackup:P@ssw0rd'; sudo fetch -o /root/bin/ https://mnt.example.ru/pub/cvsbackup/cvsbckp_install.sh && sudo sh /root/bin/cvsbckp_install.sh\"");
		} elsif ($os =~ /Linux/) {
			$cmd = sprintf("\"sudo wget --no-check-certificate -O /root/bin/cvsbckp_install.sh https://cvsbackup:P@ssw0rd\@mnt.example.ru/pub/cvsbackup/cvsbckp_install.sh && sudo sh /root/bin/cvsbckp_install.sh\"");
		} else {
			printf(STDERR "%s is not Linux or FreeBSD\n", $srv);
			next;
		}
		run_command($srv, $cmd);
	}
}
#check ssh users with default password 
if ($args{action} == 8) {
	foreach $rec (@servers) {
		my $srv = get_server($rec);
		my $os = get_os($srv);
		my $cmd = "";
		@user_list = get_ssh_users($srv, $os);
		foreach $user (@user_list) {
			split(":",$user);
			printf("Check %s@%s ",$_[0],$srv);
			my $r=check_qwe123($_[0],$srv);
			printf(" code %d ", $r);
			if ($r == 0 || $r == 256)  {
				printf("OK\n");
			} elsif ($r == 255) {
				printf("FALSE\n");
			} elsif ($r == 254) {
				printf("UNKNOWN\n");
			}
		}
	}	
}
#update stats
if ($args{action} == 9) {
	$d = db::connect(%config::m);
	db::query($d, "DELETE FROM servers");
	foreach $rec (@servers) {
		update_stats(get_server($rec));	
	}
	$d->disconnect();
}

