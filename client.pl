#!/usr/bin/perl
use IO::Socket::INET;
use strict;

my $address = $ARGV[0] or die "Error: server name is missing\n";
my $port = $ARGV[1] or die "Error: port is missing\n";

my $serverSocket = IO::Socket::INET->new( 
		PeerAddr => $address,
		PeerPort => $port,
		Proto => 'tcp') or die "Error: Unable to create socket ($!)\n";

print "Welcome to WordWorm! \nTo start a new game enter a NEW GAME,
to view your points enter POINTS,
to save your current result enter  SAVE,
to view the words you already used enter MY WORDS,
to view the best score enter FIRST,
to quit the game enter QUIT!\n
The game start now!\n";

$serverSocket->autoflush(1);
STDOUT->autoflush(1);

#first receive the word we are playing with
my $word = <$serverSocket>;
print "Your word : ".uc($word)."Enter your choice : ";
while (my $request = <STDIN>) {
	print $serverSocket $request; 
	last if $request eq "QUIT\n";
	my $response = <$serverSocket>;
	last if $response eq "";
	chomp $request;
	if ($request eq "NEW GAME") {
		$word = $response;
		print "New word : ".uc($word);
	} elsif($request eq "SAVE") {
		if ($response eq "NAME\n") {
			print "Enter your name : ";
			my $name;
			while (($name = <STDIN>) !~ m/^\D[a-zA-z0-9]*$/){
				print "Your name must begin with letter and contain only letters and digits\nEnter your name : ";
			}
			print $serverSocket $name;
			$response = <$serverSocket>;
		}
		print $response;
	} else {
		print $response;
		print "Word : ".uc($word) if ($response ne "No time left\n");
	}
	print "Enter your choice :  ";
}
close $serverSocket or die "Error: Unable to close socket ($!)\n";