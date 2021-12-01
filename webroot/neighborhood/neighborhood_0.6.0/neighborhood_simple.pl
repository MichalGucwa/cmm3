#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;

my $pdbfile="XXXX.pdb";
if (exists $ARGV[1]) {
  $pdbfile=$ARGV[1];
}
my $NEIGHBORHOOD     ="/home/sg/neighborhood/neighborhood_0.6.0";
$ENV{"NEIGHBORHOOD"} = $NEIGHBORHOOD;
my $exec_dir         ="$NEIGHBORHOOD/src";
my $exec_prog        ="$exec_dir/neighborhood";
#my $temporary_dir    ="/var/www/html/csgid/app/webroot/neighborhood_temp/".$ARGV[0];
my $temporary_dir    ="/home/sg/neighborhood/neighborhood_0.6.0/src/tmp/";
my $exec_line	     ="$exec_prog $temporary_dir $pdbfile XXXX.cluster NULL NULL";
system($exec_line) == 0 or die "Could not calculate neighborhood\n";

