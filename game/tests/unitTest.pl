#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib "C:/Perl64/game/lib";

use_ok('GAME', 'Loaded Game module');
use_ok('RECORDS', 'Loaded Records module');

ok( my $obj = GAME->new(dict=>["play"]), 'Can create instance of GAME');