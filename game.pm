#!/usr/bin/perl
package  GAME;
use strict;
use Moose;
use threads;
use threads::shared;

has 'word' => (isa =>'Str', is => 'rw');
has 'points' => (isa =>'Int', is => 'rw');
has 'startTime' => (isa =>'Int', is => 'rw');
has 'dict' => (is => 'rw', isa => 'ArrayRef');
has 'words' => (is=> 'rw', isa => 'ArrayRef[Object]', default => sub { [] },);
has 'isSaved' => (isa =>'Int', is => 'rw');

sub start{
	my ($self) = @_;
	$self->points(0);
	$self->isSaved(0);
	$self->startTime(time());
	$self->word($self->generate);
}

#return the left time 
sub get_time {
	my $self = shift;
	my $rest = 60 - time() + $self->startTime;
	$rest >= 0 ? $rest : 0;
}

#save the results
sub save {
	my $self = shift;
	$self->isSaved(1);
}

#serve a request
sub serve{
	my ($self, $command) = @_;
	if ($command eq "POINTS") {
		return $self->points;
	} elsif ($command eq "TIME")  {
		return $self->get_time();
	} elsif ($command eq "NEW GAME")  {
		$self->start;
		@{$self->words} = ();
		return $self->word;
	} elsif($command eq "MY WORDS") {
		return "Used words: @{$self->words}";
	} else { 
		if ($self->get_time() == 0) {
			return "No time left";
		}
		if (my $points = $self->try($command)) {
			return "Points: ".$points;
		} else {
			return "Invalid word!";
		}
	}
}

# check if a word is correct
sub try{
	my ($self, $newWord) = @_;
	if ($self->check($newWord,$self->word) and $self->find($newWord)
		and not $self->double($newWord)
		and ($newWord ne $self->word)){
		push (@{$self->words},  $newWord);
		my $points = $self->calculate($newWord);
		$self->points($self->points + $points);
		$self->isSaved(0);
		return $points;
	}
	0;
}

#calculate the points the player receives for the word
sub calculate {
	my ($self , $word) = @_;
	my $points = length($word);
	$points += $self->count('b',$word);
	$points += $self->count('v',$word);
	$points += $self->count('k',$word);
	$points += $self->count('j',$word)*3;
	$points += $self->count('q',$word)*3;
	$points += $self->count('x',$word)*3;
	$points += $self->count('z',$word)*3;
	$points += $self->count('y',$word)*1;
	if (length($word) > 9){
		$points = $points * 3;
	}
	elsif (length($word) > 5){
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


sub check($$$){
	my ($self, $word,$patt) = @_;
	return 0 if (length($word) > length($patt));
	for(my $i = 0; $i < length($word); $i++) {
		my $char = substr($word,$i,1);
		return 0 if ($self->count($char,$word) > $self->count($char,$patt));
	}
	1;
}
sub count($$$) {
	my ($self, $char,$word) = @_;
	my $count = 0;
	for(my $i = 0; $i < length($word); $i++) {
		if (substr($word, $i, 1) eq $char) {
			$count++;
		}
	}
	$count;
}
1;