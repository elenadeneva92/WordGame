#!/usr/bin/perl -w

package  RECORDS;

use DBI qw(:sql_types);
my $dbfile = "C:/Perl64/game/resources/records.db";

# Used to save player result.
sub save {
	my $name = shift;
	die "Error!!! This is a class method" if ref $name;
	my $points = shift;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
	my $check = $dbh->table_info("%","%","records","TABLE");
	#if there is no DB, create it
	if (!$check->fetch) {
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

# Used to find the player with maximum points
sub max {
my ($class) = shift;
	die "error" if ref $class;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
	my $check = $dbh->table_info("%", "%", "records", "TABLE");
	return "No scores" if (!$check->fetch);
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
	$points." points -> ". $name;
}
1;