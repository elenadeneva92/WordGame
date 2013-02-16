#!/usr/bin/perl -w

use IO::Socket::INET;
use strict;

sub register_player();
sub wait_for_word();
sub serve($);

my $address = $ARGV[0] or die "Error: server name is missing\n";
my $port = $ARGV[1] or die "Error: port is missing\n";
my $server_socket = IO::Socket::INET->new( PeerAddr => $address,
		                                       PeerPort => $port,
	                                           	Proto => 'tcp') or die "Error: Unable to create socket ($!)\n";
$server_socket->autoflush(1);
STDOUT->autoflush(1);

my $help = <<END;
 NEW GAME -> start a new game,
 POINTS -> current result
 SAVE -> save the current result
 MY WORDS -> used words
 FIRST -> the best score
 TIME -> time left
 HELP -> help
 QUIT -> stop the game !\n
END

print "Welcome to WordWorm!\n\n".$help."The game starts now!\nEnter your name: ";

my $word;
register_player();
wait_for_word();

while (my $request = <STDIN>) {
  chomp $request;
  last unless serve($request)
}
close $server_socket or die "Error: Unable to close socket ($!)\n";

sub register_player() {
  my $player_name;
  ($player_name = <STDIN>) eq "\n" ? exit : print $server_socket $player_name;
}

sub wait_for_word() {
  $word = <$server_socket>;
  print "Your word : ".uc($word)."WordGame>";
}

sub serve($) {
  my $request = shift;
  print "\n".$help."WordGame>" and return 1 if $request eq  "HELP";
  print "WordGame>" and return 1 if $request eq "";

  print $server_socket $request."\n";
  return 0 if $request eq "QUIT";
  my $response = <$server_socket>;
  return 0 unless (defined($response));

  if ($request eq "NEW GAME") {
    $word = $response;
    print "New word : ".uc($word);
  } else {
    print $response;
    print "Word : ".uc($word) if ($response ne "No time left\n")  and ($request ne "SAVE")
  }
  print "WordGame>";
}