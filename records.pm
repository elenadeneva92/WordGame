#!/usr/bin/perl
package  RECORDS;
use DBI qw(:sql_types);
my $dbfile = "C:\\Perl64\\game\\records.db";
sub save {
	my $name = shift;
	die "Error!!! This is a class method" if ref $name;
	my $points = shift;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
	my $check = $dbh->table_info("%","%","records","TABLE");
	if (!$check->fetch) {
		print "initial import";
			$dbh->do(qq{
		CREATE TABLE records(
			id integer primary key autoincrement,
			name carchar,
			points integer)
		});
	}
	my $sth = $dbh->prepare(qq{
	INSERT INTO records
	(name, points)
	VALUES(?, ?)
	});
	$sth->execute($name, $points);
}

sub max {
my ($class) = shift;
	die "error" if ref $class;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
	my $check = $dbh->table_info("%","%","records","TABLE");
	if (!$check->fetch) {
		return "No scores";
	}
	my $stmax = $dbh->prepare(qq {
		SELECT *
		from (
			SELECT points as points, 
			name
			from records
			order by points desc
			limit 1
		)
		}) or die $!;
	$stmax->execute();
	my ($points, $name) = $stmax->fetchrow_array();
	$points." -> ". $name;
}
1;