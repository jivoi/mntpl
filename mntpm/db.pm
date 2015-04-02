package db;
use DBI;

sub connect(%) {
	my %m = @_;
	my $dbh = DBI->connect("dbi:mysql:dbname=$m{d};host=$m{h}", "$m{u}", "$m{p}", {raise_error=>1}) || die "Can't open database";
	return $dbh;
}

sub query($$) {
	my ($d,$q) = @_;
	my $sth = $d->prepare($q);
	my $rv = $sth->execute();
	return $sth;
}
sub rows_count($) {
	my ($s) = @_;
	my $n = 0;
	while($s->fetchrow_array()) {
		$n++;
	}
	return $n;
}
sub disconnect {
	my ($d) = @_;
	$d->disconnect();
}

1;
