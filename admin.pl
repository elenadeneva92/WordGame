#!/usr/bin/perl
use IO::Socket::INET;
use strict;

#If set $| to nonzero, forces a flush after every write or print
$|=1;

my $address = $ARGV[0] or die "Error: server name is missing\n";
my $port = $ARGV[1] or die "Error: port is missing\n";

my $serverSocket = IO::Socket::INET->new( 
		PeerAddr => $address,
		PeerPort => $port,
		Proto => 'tcp') or die "Error: Unable to create socket ($!)\n";
$serverSocket->autoflush(1);
STDOUT->autoflush(1);

#The magic word "Admin" to tell the server not to start a game and to expect a password
print $serverSocket "Admin\n";

print "Enter a password : ";
my $password = <STDIN>;
print $serverSocket $password;

#expect confirmation of the password from the server 
my $response = <$serverSocket>;

print "Wrong password! " and exit "1" if $response ne  "true\n"; # incorrect password

my %commands = (1 => "COUNT OF PLAYERS NOW",
                2 => "PLAYERS ATT ALL",
				        3 => "CLEAN", 
                4 => "DELETE DB",
                5 => "INFO PLAYER", 
                6 => "CHANGE PASSWORD",
                7 => "PLAYERS",
                8 => "HELP", 
                9 => "QUIT");

my	$help = <<END;
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
	 
  print "\n".$help."\nadmin>" and next if $number eq "8";
	my $request = $commands{$number};
	print $serverSocket $request."\n";
	last if $request eq "QUIT";
	
	my $response = <$serverSocket>;
	last if $response eq "";
	
	#information for all players
	if ($number eq "7") {
		$response = deserialize($response);
	}
	print $response;
	
	#change the password
	if ($number eq "6") {
		$request = <STDIN>;
		chomp $request;
		print $serverSocket $request."\n";
		my $response = <$serverSocket>;
		last if $response eq "";
		print $response;
	}
	
	#information for a player
	if ($number eq "5") {
		my $name = <STDIN>;
		chomp $name;
		print $serverSocket $name."\n";
		my $response = <$serverSocket>;
		last if $response eq "";
		if ($response ne "false\n") {
			print deserialize($response);
		} else {
			print "No such player\n";
		}	
	}
	print "admin>";
}

close $serverSocket or die "Error: Unable to close socket ($!)\n";

#deserialize the received information 
sub deserialize($) {
	my ($str) = shift;
	$str =~ s/\;/\n/g;
  chomp $str;  
	$str;
}