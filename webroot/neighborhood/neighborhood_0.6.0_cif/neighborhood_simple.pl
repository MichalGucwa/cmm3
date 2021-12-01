#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;

my $coord_filename;

if (exists $ARGV[1]) {
    $coord_filename=$ARGV[1];
} elsif (-e "XXXX.cif") {
    $coord_filename="XXXX.cif";
} elsif (-e "XXXX.pdb") {
    $coord_filename="XXXX.pdb";
} else {
    print "Could not find coordinate file in the current directory!\n";
}

my $NEIGHBORHOOD     ="/home/sg/neighborhood/neighborhood_0.6.0_cif";
$ENV{"NEIGHBORHOOD"} = $NEIGHBORHOOD;
my $exec_dir         ="$NEIGHBORHOOD/src";
my $exec_prog        ="$exec_dir/neighborhood";
#my $temporary_dir    ="/var/www/html/csgid/app/webroot/neighborhood_temp/".$ARGV[0];
my $temporary_dir    ="/home/sg/neighborhood/neighborhood_0.6.0_cif/src/tmp/";
copy("$coord_filename","$temporary_dir") or die "Copy coordinate file failed: $!";
copy("XXXX.cluster","$temporary_dir") or die "Copy XXXX.cluster failed: $!";
my $exec_line	     ="$exec_prog $temporary_dir $coord_filename XXXX.cluster NULL NULL";
print $exec_line;
system($exec_line) == 0 or die "Could not calculate neighborhood!\n";

