#!/usr/bin/perl -w 
use IO::Socket; 
use strict; 
use threads;
use GAME;
use RECORDS;
use threads::shared;

#flush automatically the output buffer
STDOUT->autoflush(1);

#read a file with words
open(INFO, "EnglishDictionary.txt");
my @words = <INFO>;
@words =  map {s/\s//g;$_} @words;

#create a server socket
my $port = shift || die "Usage server.pl <port>\n";
my $server = IO::Socket::INET->new( Proto => 'tcp', 
							 LocalPort => $port, 
								Listen => 10, 
								 Reuse => 1); 
$server || die "Can't setup server";

print "Server  is running on port $port \n"; 

#Set a password so admin can log in
print "Enter admin password : ";
my $password : shared = <STDIN>;
chomp $password;
my @games : shared;
#count of the players (just for the statistic)
my $count : shared = 0;

$server->listen;

#accept a client and start a new thread for every client
#so many player can play in the same time
while (my ($client) = $server->accept()) { 
	my $child = threads->new("serve", $client);
	$child->detach();
}

#serve a client
sub serve($) {
  my ($client) = @_;
  $client->autoflush(1);
  #a player sends his name or admin sends "Admin" and then expecting a password 
  my $name =  <$client>;
  if (defined($name)) {
    chomp $name;
    if ($name eq "Admin"){
      my $try = <$client>;;
      chomp $try;
      if ($password eq $try){ 
         serveAdmin($client);
      }
    } else{
      print $name;
      servePlayer($client, $name);
    }
  }
  close $client;
}

#serve a player request
sub servePlayer {
	my ($client, $name) = @_;
	#start new game
	my $game :shared = GAME->new(dict=>\@words);
	#flag showing if we will use a position 
	#in the array or we will push it back
	my $flag = 0;
	#check if there is an empty space in the array
	foreach (@games) {
		if ($_ eq '') {
			lock(@games);
			$_ = $game;
			$flag = 1;
			last;
		}
	}
	
	{
		#if there is no empty slot in the array push it back in the array
		lock(@games) &&	push @games, $game unless $flag;
	}
	{
		#the player counts increases with 1
		lock($count);
		$count++;
	}
	
	#start the game and send to the client the word he is playing with
	$game->start($name);
	print $game->word."\n";
	print $client $game->word."\n";
	
	#serve the client request
	while (<$client>) { 
		chomp;
		last if not $_ or $_ eq "QUIT"; 
		my $response;
		if ($_ eq "SAVE")  {
			if ($game->isSaved) {
				 $response =  "the game is already saved";
			}  else {
				RECORDS::save($game->name, $game->points);
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
	#the player quit and he is not anymore in progress
	$game->inProcess(0);
}

#serve the admin request
sub serveAdmin {
	my ($admin) = @_;
	print "Admin logged in \n";
	#send confirmation to the admin
	print $admin "true\n";
	
	#serve admin's request
	while (<$admin>) { 
		print;
		chomp;
		my $response;
		if ($_ eq "COUNT OF PLAYERS NOW")  {
			 $response =  countNow();
		} elsif ($_ eq "PLAYERS ATT ALL")  {
			$response  = $count;
		} elsif ($_ eq "CLEAN") {
			removeUnused();
			$response = "cleaned";
		} elsif ($_ eq "DELETE DB") {
			unlink("C:\\Perl64\\game\\records.db");
			$response = "deleted";
		}  elsif ($_ eq "INFO PLAYER") {
			print $admin "Name of a player: \n";
			my $name = <$admin>;
			return unless defined($name);
			last if $name eq "";
			chomp $name;
			$response = info($name);
		} elsif ($_ eq "CHANGE PASSWORD"){
		 	my $request = "New password : ";
			print $admin $request."\n";
			my $try = <$admin>;
			return unless defined($try);
			last if $try eq "";
			chomp $try;
			print $try. " new\n";
			if (length($try) < 5) {
				$response = "Password not changed";
			} else {
				$password = $try;
				$response = "Password changed";
			}
		} elsif ($_ eq "PLAYERS") {
			$response = "";
			$response .= $_->info() foreach (grep  {$_ ne ""} @games);
		} else {
			$response = "unrecognized command";
		}
		print $admin $response."\n";
	}
}

#get info for a player with $name
sub info($) {
    my $name = shift;
	foreach my $game ( grep { $_ ne "" } @games) {
		if ($game->name eq $name){
			return $game->info;
		}
	}	
	"false";
}

#remove all games that are not in progress to free the array for new players
sub removeUnused {
	foreach my $game (grep { $_ ne "" } @games) {
		unless ($game->inProcess) {
			lock(@games);
      print $game->name." deleted";
			$game = '';
		}
	}
}

#return the number of games in process (the count of players  playing now)
sub countNow {
	my $result = 0;
	foreach my $game (grep { $_ ne "" } @games) {
		if ($game->inProcess) {
			$result++;
		}
	}	
	$result;
}