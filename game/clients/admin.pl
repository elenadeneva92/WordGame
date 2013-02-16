#!/usr/bin/perl -w

use IO::Socket::INET;
use strict;

sub log_in();
sub serve($);
sub change_password();
sub deserialize($);
sub get_player_info();

$| = 1; # forces a flush after every write or print

my $address = $ARGV[0] or die "Error: server name is missing\n";
my $port = $ARGV[1] or die "Error: port is missing\n";
my $server_socket = IO::Socket::INET->new( PeerAddr => $address,
                                           PeerPort => $port,
                                              Proto => 'tcp');
$server_socket or die "Error: Unable to create socket ($!)\n";

print "Wrong password! " and exit if log_in(); # (in case of incorrect password)

my %commands = (1 => "COUNT OF PLAYERS NOW",
                2 => "PLAYERS ATT ALL",
				        3 => "CLEAN",
                4 => "DELETE DB",
                5 => "INFO PLAYER",
                6 => "CHANGE PASSWORD",
                7 => "PLAYERS",
                8 => "HELP",
                9 => "QUIT");

my $help = <<END;
  Commands:
  1 -> count of the players who are connected now
  2 -> players played the game until now
  3 -> clean the game array with disconnected players
  4 -> delete the database with the results
  5 -> get info for a player
  6 -> change the password
  7 -> return the info for all recent players
  8 -> help
  9 -> quit\n
END

print "\nYou are logged in!\n".$help."admin>";

while (my $number = <STDIN>) {
	chomp $number;
  last unless serve($number);
}

close $server_socket or die "Error: Unable to close socket ($!)\n";

sub log_in() {
  print $server_socket "Admin\n"; # tell the server you want to log as admin
  print "Enter a password : ";
  my $password = <STDIN>;
  print $server_socket $password;
  <$server_socket> ne "true\n"; # wait for confirmation of the password
}

sub serve($) {
  my $number = shift;
  print "unrecognized command\nadmin>" and return 1 if ($number !~ m/^[0-9]$/);
  print "\n".$help."admin>" and return 1 if $number eq "8";
	my $request = $commands{$number};
	print $server_socket $request."\n";
	return 0 if $request eq "QUIT";

	my $response = <$server_socket>;
	$response = deserialize($response) if ($number eq "7");	# information for all players
	print $response;
  get_player_info() if ($number eq "5");
  change_password() if ($number eq "6");
	print "admin>";
}

sub get_player_info() {
    my $name = <STDIN>;
		print $server_socket $name if defined($name);
		my $response = <$server_socket>;
		$response ne "false\n" ? print deserialize($response) : print "No such player\n";
}

sub change_password() {
  my $request = <STDIN>;
  print $server_socket $request if defined($request);
  my $response = <$server_socket>;
  print $response;
}

sub deserialize($) {
	my ($str) = shift;
	$str =~ s/\;/\n/g;
  chomp $str;
	$str;
}