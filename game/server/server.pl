#!/usr/bin/perl -w

use lib "C:/Perl64/game/lib";
use IO::Socket;
use strict;
use threads;
use GAME;
use RECORDS;
use Switch::Plain;
use threads::shared;
use List::Util qw(first);

$| = 1;

sub load_words();
sub remove_unused();
sub log_info($);
sub count_now();
sub serialize($);
sub serve_admin($);
sub serve_player($$);
sub check_password($);
sub serve($);
sub change_password($);
sub save_game($);
sub adde_player();

my @words = load_words();
my @games : shared;
my $count : shared = 0; # count of the players
my $port = shift or die "Port needed\n";
my $server = IO::Socket::INET->new( Proto => 'tcp',
                                LocalPort => $port,
                                   Listen => 10,
                                    Reuse => 1);
$server or die "Can't setup server";
print "Server  is running on port $port \n";

print "Enter admin password : ";
my $password : shared = <STDIN>;
chomp $password;

$server->listen;
while (my ($client) = $server->accept()) {
	my $child = threads->new("serve", $client);
	$child->detach();
}

sub serve($) {
  my ($client) = @_;
  my $name =  <$client>;
  return unless defined($name);
  chomp $name;
  if ($name eq "Admin"){
    serve_admin($client) if check_password($client)
  } else {
    serve_player($client, $name);
  }
  close $client;
}

sub check_password($) {
  my $client = shift;
  my $pass = <$client>;
  defined($pass) ? chomp $pass : return 0;
  $password eq $pass;
}

# Used to serve a player request
sub serve_player($$) {
	my ($client, $name) = @_;
	log_info("$name started a game at ".localtime(time)."\n");
	my $game :shared = GAME->new(dict=>\@words);
	my $flag = 1; # used to show if there is empty slot in the array
	foreach (@games) {
		if (!defined($_)) {
      lock($_);
			$_ = $game;
			$flag = 0;
			last;
		}
	}
	if ($flag) {
    lock(@games);
    $games[scalar(@games)] = $game
	}
  increment_players_count();
	
  $game->start($name);
	print $client $game->word."\n";
  
	while (<$client>) {
		chomp;
   	my $response;
    last unless defined and $_ ne "QUIT";
    sswitch($_) {
      case "QUIT": { last }
      case "SAVE": { $response = save_game($game) }
      case "FIRST": {$response = RECORDS::max() }
      default: { $response = $game->serve($_) }
    }
		print $client $response."\n";
	}
	$game->in_process(0);
}

sub save_game($) {
  my $game = shift;
  $game->is_saved ? "The game is already saved" : ( RECORDS::save($game->name, $game->points) and  $game->save() and return "The game is saved" ) ;
}

sub serve_admin($) {
	my $admin = shift;
	log_info("Admin logged in at".localtime(time())."\n");
	print $admin "true\n"; # send confirmation to the admin

	while (<$admin>) {
		chomp;
		my $response;
    sswitch($_) {
      case "COUNT OF PLAYERS NOW": { $response = count_now() }
      case "PLAYERS ATT ALL": { $response = $count }
      case "CLEAN": { remove_unused(); $response = "Cleaned" }
      case "DELETE DB": { unlink("C:/Perl64/game/resources/records.db");$response = "deleted" }
      case "INFO PLAYER": { $response = get_players_name($admin)	}
      case "CHANGE PASSWORD": {	$response = change_password($admin) }
      case "PLAYERS": {	$response = "";	$response .= $_->serialize() foreach (grep  {defined($_)} @games) }
      default: {	$response = "unrecognized command" }
    }
    defined($response) ? print $admin $response."\n" : last;
	}
}

sub change_password($) {
  my $admin = shift;
  print $admin "New password:\n";
  my $try = <$admin>;
  return unless defined($try);
  chomp $try;
  length($try) < 5 ? "Password not changed" : (($password = $try) and return "Password changed");
}

sub get_players_name($) {
  my $admin = shift;
  print $admin "Name of a player: \n";
  my $name = <$admin>;
  return unless defined($name);
  last if $name eq "";
  chomp $name;
  serialize($name);
}

# Used to find a player and serialize it
sub serialize($) {
  my $name = shift;
  my $game = first { defined($_)  and $_->name eq $name} @games;
  defined($game) ? $game->serialize() : "false";
}

sub load_words() {
  open(WORDS, "C:/Perl64/game/resources/EnglishDictionary.txt");
  @words = <WORDS>;
  close(WORDS);
  map { s/\s//g; $_ } @words;
}

# Used to remove all games that are not in progress to free the array for new games
sub remove_unused() {
  foreach my $game (grep { defined($_) and !$_->in_process } @games) {
		$game = undef;
  }
}
# Used to return the number of games in process
sub count_now() {
	scalar (grep { defined($_)  and $_->in_process } @games);
}

sub increment_players_count() {
  lock($count);
  $count++;
}

sub log_info($) {
  my $info = shift;
  open(LOG, ">>", "C:/Perl64/game/resources/Log.txt");
  print LOG $info;
  close(LOG);
}