#!/usr/bin/perl
use IO::Socket::INET;
use strict;

my $address = $ARGV[0] or die "Error: server name is missing\n";
my $port = $ARGV[1] or die "Error: port is missing\n";

my $server_socket = IO::Socket::INET->new( PeerAddr => $address,
		                                       PeerPort => $port,
	                                           	Proto => 'tcp') or die "Error: Unable to create socket ($!)\n";
$server_socket->autoflush(1);
STDOUT->autoflush(1);

my $HELP = <<END;
 NEW GAME -> To start a new game,
 POINTS -> to view your points,
 SAVE -> to save your current result enter,
 MY WORDS -> to view the words you already used enter
 FIRST -> to view the best score enter
 HELP -> to view this message again eneter 
 QUIT -> to quit the game enter !\n
END

print "Welcome to WordWorm!\n\n".$HELP."The game starts now!\nEnter your name: ";

exit if (my $name = <STDIN>) eq "\n";

print $server_socket $name;

my $word = <$server_socket>;
print "Your word : ".uc($word)."WordGame>";

while (my $request = <STDIN>) {
  print "\n".$HELP."WordGame>" and next if $request eq  "HELP\n";
  print "WordGame>" and next if $request eq "\n";
  print $server_socket $request;
  last if $request eq "QUIT\n";

  my $response = <$server_socket>;
  next if $response eq ""; #no connection
  chomp $request;

  if ($request eq "NEW GAME") {
    $word = $response;
    print "New word : ".uc($word);
  } elsif($request eq "SAVE") {
    print $response;
  } else {
    print $response;
    print "Word : ".uc($word) if ($response ne "No time left\n");
  }
  print "WordGame>";
}
close $server_socket or die "Error: Unable to close socket ($!)\n";