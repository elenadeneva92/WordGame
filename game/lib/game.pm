#!/usr/bin/perl -w

package  GAME;

use strict;
use Moose;
use threads;
use threads::shared;
use Switch::Plain;
use List::Util qw(reduce);

# Used to make the game obejcts shared
around 'new' => sub {
        my $orig = shift;
        my $class = shift;
        my $self = $class->$orig(@_);
        my $shared_self : shared = shared_clone($self);
        return $shared_self;
    };

has 'word' => (isa =>'Str', is => 'rw');
has 'points' => (isa =>'Int', is => 'rw');
has 'start_time' => (isa =>'Int', is => 'rw');
has 'dict' => (is => 'rw', isa => 'ArrayRef');
has 'words' => (is=> 'rw', isa => 'ArrayRef[Object]', default => sub { [] },);
has 'is_saved' => (isa =>'Int', is => 'rw');
has 'name' => (is => 'rw', isa => 'Str');
has 'in_process'=>(is => 'rw', isa => 'Bool');

# Used to start a game with passed name
sub start($){
	my ($self, $name) = @_;
	$self->name($name);
	$self->points(0);
	$self->is_saved(0);
	$self->start_time(time());
	$self->word($self->generate);
	$self->in_process(1);
}

# Used to obtain the left time of the player
sub left_time {
	my $self = shift;
	my $rest = 60 - time() + $self->start_time;
	$rest >= 0 ? $rest : 0;
}

# Used save the results
sub save {
	my $self = shift;
	$self->is_saved(1);
}

# Used to serve a request
sub serve {
  my ($self, $command) = @_;
    sswitch ($command) {
    case "POINTS": { return $self->points }
    case "TIME": { return $self->left_time() }
    case "NEW GAME": { $self->start($self->name); @{$self->words} = (); return $self->word }
    case "MY WORDS": { return "Used words: @{$self->words}" }
    default: { return check_word($self, $command) }
  }
}

sub check_word($$) {
  my ($self, $word) = @_;
  return "No time left" if $self->left_time() == 0;
  my $points = $self->try($word);
  $points ? "Points: ".$points : "Invalid word!";
}

# check if a word is correct
sub try {
	my ($self, $newWord) = @_;
	if ($self->check($newWord,$self->word) and $self->find($newWord)
        and not $self->double($newWord)  and ($newWord ne $self->word)){
		push (@{$self->words},  $newWord);
		my $points = $self->calculate($newWord);
		$self->points($self->points + $points);
		$self->is_saved(0);
		return $points;
	}
	0;
}

#calculate the points the player receives for the word
sub calculate {
	my ($self , $word) = @_;
	my $points = length($word);
  $points += reduce { $a + $b} map { $self->count($_, $word) } ('b', 'v', 'k', 't', 'c');
  $points += reduce { $a + $b} map { 3 * $self->count($_, $word) } ('j', 'q', 'x', 'y', 'z');
   if (length($word) > 9) {
		$points = $points * 3;
	}	elsif (length($word) > 5) {
		$points  = $points * 2;
	}
	$points;
}

#check if the word is not already used
sub double($$) {
	my ($self, $word) = @_;
	foreach(@{$self->words}){
		return 1 if ($_ eq $word);
	}
	0;
}

#search a word in a dictionary
sub find($$) {
	my ($self, $word) = @_;
	my ($l,$u) =(0, @{$self->dict}-1);
	my $i;
	while($l <= $u) {
		$i = int(($l + $u)/2);
		if (@{$self->dict}[$i] lt $word) {
			$l = $i + 1;
		} elsif (@{$self->dict}[$i] gt $word) {
			$u = $i - 1;
		} else {
			return 1;
		}
	}
	0;
}

#generate a word to play with
sub generate() {
	my $self = shift;
	my @words = @{$self->dict};
	my $index = int(rand(scalar(@{$self->dict})));
	my $word = $words[$index];
	while(length($word) < 8){
		$index = int(rand(scalar(@{$self->dict})));
		$word = $words[$index];
	}
	$word;
}

#check if a word has only letters that are in the pattern
#Example: reverse -> preserve
sub check($$$){
	my ($self, $word,$patt) = @_;
	return 0 if (length($word) > length($patt));
	for(my $i = 0; $i < length($word); $i++) {
		my $char = substr($word,$i,1);
		return 0 if ($self->count($char,$word) > $self->count($char,$patt));
	}
	1;
}

#return the count of char in a string
sub count($$$) {
	my ($self, $char, $word) = @_;
	my $count = 0;
	for(my $i = 0; $i < length($word); $i++) {
		if (substr($word, $i, 1) eq $char) {
			$count++;
		}
	}
	$count;
}

# Used to serialize the info for a player
sub serialize {
	my ($self) = @_;
	my $result = "Name : ".$self->name.";";
	$result .= "Points : ".$self->points.";";
	$result .= "In process : ".$self->in_process.";";
	$result .= "Start last game : ".localtime($self->start_time).";";
	$result;
}
1;