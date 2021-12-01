#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;


my $NEIGHBORHOOD     ="/home/dust/neighborhood_0.6.1_src";
$ENV{"NEIGHBORHOOD"} = $NEIGHBORHOOD;
my $exec_dir         ="$NEIGHBORHOOD/src";
my $exec_prog        ="$exec_dir/neighborhood";
my $temporary_dir    ="$exec_dir/temp";
my $exec_line        ="$exec_prog $temporary_dir pdb1vs8.ent XXXX.cluster NULL NULL";
system($exec_line) == 0 or die "Could not calculate neighborhood\n";

