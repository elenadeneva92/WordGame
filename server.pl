#!/usr/bin/perl -w 
use IO::Socket; 
use Net::hostent; 
use strict; 
use threads;
use GAME;
use RECORDS;

STDOUT->autoflush(1);
open(INFO, "2of12inf.txt");
my @words = <INFO>;
@words =  map {s/\s//g;$_} @words;

my $port = shift || die "Usage server.pl <port>\n";
my $server = IO::Socket::INET->new( Proto => 'tcp', 
							 LocalPort => $port, 
								Listen => 10, 
								 Reuse => 1); 

die "can't setup server" unless $server; 
print "Server  is running on port $port \n"; 
my %clients;

$SIG{CHLD} = 'IGNORE';
$server->listen;

while (my ($client) = $server->accept()) { 
	my $child = threads->new ("read_data", $client);
	$child->detach();
}
sub read_data($) {
	my ($client) = @_;
	$client->autoflush(1); 
	my $game = GAME->new(dict=>\@words);
	$game->start();
	print $game->word."\n";
	print $client $game->word."\n";
	while (<$client>) { 
		print $_;
		chomp;
		last if not $_ or $_ eq "QUIT"; 
		my $response;
		if ($_ eq "SAVE")  {
			if ($game->isSaved) {
				 $response =  "the game is already saved";
			}  else {
				print $client "NAME\n";
				my $name = <$client>;
				chomp $name;
				RECORDS::save($name, $game->points);
				$game->save();
				$response = "the game is saved";
			 }
		} elsif ($_ eq "FIRST")  {
			print "first";
			$response  = RECORDS::max();
		} else {
			$response = $game->serve($_);
		}
		print $client $response."\n";
	} 
	close $client;
}