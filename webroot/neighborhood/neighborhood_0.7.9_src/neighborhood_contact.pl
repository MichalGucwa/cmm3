#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;

#------------------------------ CONTACT -----------------------------------------
my $contact62_exec = "/home/dust/ccp4-6.2.0/ccp4-6.2.0/bin/contact";
my $contactfile = "XXXX.contact";
#------------------------------ CONTACT -----------------------------------------

my $pdbfile="XXXX.pdb";
if (exists $ARGV[1]) {
  $pdbfile=$ARGV[1];
}
my $NEIGHBORHOOD     ="/home/dust/neighborhood_0.7.9_src";
$ENV{"NEIGHBORHOOD"} = $NEIGHBORHOOD;
my $exec_dir         ="$NEIGHBORHOOD/src";
my $exec_prog        ="$exec_dir/neighborhood";
my $temporary_dir    ="/var/www/html/csgid/app/webroot/neighborhood_temp/metalna/upload/".$ARGV[0];

my $return_code      = calculate_contact_file($temporary_dir,$pdbfile,$contactfile);
if ($return_code) {
  $contactfile = "NULL" 
}
my $exec_line	     ="$exec_prog $temporary_dir $pdbfile XXXX.cluster NULL $contactfile NULL";
print $exec_line;
system($exec_line) == 0 or die "Could not calculate neighborhood\n";



#------------------------------------------------------------------------------

sub calculate_contact_file{
  my($temporary_dir,$pdbfile_in,$contactfile_in)=@_;
  my $pdbfile0="$temporary_dir/$pdbfile_in";
  my $pdbfile="$temporary_dir/contact\.pdb";
  my $logfile="$temporary_dir/contact\.log";
  my $errfile="$temporary_dir/contact\.err";
  my $contactfile="$temporary_dir/$contactfile_in";

  open ZIPFILE, $pdbfile0 or die "could not open the file: $pdbfile0: $!\n";
  my $count_num_models=0;
  while (<ZIPFILE>) {
    $count_num_models++ if (/^MODEL/); 
  }
  close ZIPFILE;

  if ($count_num_models >= 2 ) {
    $count_num_models=0;
    open ZIPFILE, $pdbfile0 or die "could not open the file: $pdbfile0: $!\n";
    open PDBFILE, '>', $pdbfile or die "can not open file $pdbfile: $!\n";
    while(<ZIPFILE>){
      $count_num_models++ if (/^MODEL/); 
      last if $count_num_models>=2;
      print PDBFILE $_;
    }
    close PDBFILE;
    close ZIPFILE;
  } else {
    $pdbfile=$pdbfile0;
  }

  my $retcode = run_and_convert($pdbfile,$logfile,$contactfile,62);
# if ($retcode) {$retcode = run_and_convert($pdbfile,$logfile,$contactfile,60);}
  if ($retcode) {
    my $errorcode=$retcode;
    $errorcode="Segmentation fault" if ($retcode==35584);
    $errorcode="Inconsistent data $retcode" if ($retcode<=5);
    open ERRFILE, '>', $errfile or die "can not open file $errfile: $!\n";
    print ERRFILE "CCP4 contact program error: $errorcode";
    close ERRFILE;
    return $retcode;
  }

  return 0;
}


sub run_and_convert {
  my($pdbfile,$logfile,$contactfile,$version)=@_;
  my $retcode = run_contact_program($pdbfile, $logfile, 5, $version);
  if ($retcode) {
      print "CONTACT ERROR (5): Attempt to run with 4 angstrom distance cutoff instead of 5...\n";
      $retcode = run_contact_program($pdbfile, $logfile, 4, $version);
      if ($retcode) {return $retcode;}
      $retcode = convert_logfile_to_contactfile($logfile, $contactfile);
  } else {
    $retcode = convert_logfile_to_contactfile($logfile, $contactfile);
    if ($retcode) {
      print "CONVERT ERROR (5): Attempt to run with 4 angstrom distance cutoff instead of 5...\n";
      $retcode = run_contact_program($pdbfile, $logfile, 4, $version);
      if ($retcode) {return $retcode;}
      $retcode = convert_logfile_to_contactfile($logfile, $contactfile);
    }
  }
  return $retcode;
}


sub run_contact_program {
  my($pdbfile,$logfile,$distance_cutoff,$version)=@_;
  my $contact_exec = $contact62_exec;
# if ($version == 61) {$contact_exec = $contact61_exec;}
# if ($version == 60) {$contact_exec = $contact60_exec;}
  my $exec_line="$contact_exec xyzin $pdbfile > $logfile << eof\nBIGSEARCH\nMODE AUTO\nATYPE ALL\nLIMITS 0 $distance_cutoff\neof\n";
# print "$exec_line";
  my $retcode=1;
  my $retline="";
  eval {
    local $SIG{ALRM} = sub { die "Program not responding for 5 minutes" };
    alarm 300;
    ($retcode=system($exec_line))==0 or ($retline=$!);
    alarm 0;
  };
  if($@){
    $retline=$@;
    system("ps |grep '[[:space:]]contact[[:space:]]*\$' |sed 's/^/kill /' |sed 's/ pts.*\$//' |sh");
    system("ps |grep '00:00:00 sh[[:space:]]*\$'        |sed 's/^/kill /' |sed 's/ pts.*\$//' |sh");
  }
  if ($retcode!=4096 && $retcode!=0) {
    if ($retcode==256) {
#     if (not exists $local_id_exception{$pdbid}) {
#       push(@local_list_id_exception, $pdbid);
#       $local_id_exception{$pdbid}="Non-standard space group";
#     };
    };
    print " <FATAL ERROR $retcode: $retline> ";
    return $retcode;
  }
  return 0;
}


sub convert_logfile_to_contactfile{
  my($logfile,$contactfile)=@_;
  my $flag_list_of_contacts=0;
  my $flag_record_found    =0;
  my $flag_audit_summary   =0;

  my $resname_a; my $resseq_a; my $chain_a; my $atomname_a;
  my $resname_b; my $resseq_b; my $chain_b; my $atomname_b;
  my $distance ; my $hbond   ;
  my $trans_a  ; my $trans_b ; my $trans_c; my $symop_d   ; my $symop_str;
  my @contact_list;
  my @contact_summary_list;
  my %contact_summary_numcontacts;
  my $contact_total_hits=0;
  my @audit_summary_list;
  my %audit_summary_numcontacts;
  my $audit_total_hits=0;

  my @contact_header_symop_list;
  my %contact_header_symop_detail;

  open LOGFILE, $logfile or die "can not open file $logfile: $!\n";
  while (<LOGFILE>){
    if (/^\s*LIST OF CONTACTS/){
      $flag_list_of_contacts =1;
      $flag_audit_summary    =0;
    } elsif(/^\s*Sorted summation/){
      $flag_list_of_contacts =0;
      $flag_audit_summary    =1;
    } elsif(/^\s*Total hits\s+(\d+)\s*$/) {
      $flag_list_of_contacts =0;
      $flag_audit_summary    =0;
      $audit_total_hits      =$1;
    } elsif($flag_list_of_contacts==1) {
      $flag_record_found=0;
# Dc      2A C5' Wat    88B O    ...  3.69    [         ]   3: -X,  Y+1/2,  -Z+1/2	# V5.0
# Lys    231  CD  Glu   210D  CG   ...  5.97    [-1A      ]   2:   X, Y, Z		# v6.1
      if (/^ (\w..) (....\d)(.) (....) (\w..) (....\d)(.) (....)\s+\.\.\.  (\d\.\d\d) (...)\[(...)(...)(...)\]\s+(\d+):\s*(\S.*,.+,.*\S)\s*$/) {
        $resname_a=translate_resname($1); $resseq_a=$2;  $chain_a=$3;  $atomname_a=translate_atomname($4);
        $resname_b=translate_resname($5); $resseq_b=$6;  $chain_b=$7;  $atomname_b=translate_atomname($8);
        $distance =$9;        $hbond=$10; $trans_a =$11; $trans_b=$12; $trans_c=$13; $symop_d=$14; $symop_str=$15;
        $resseq_a=~s/^\s+//;  $resseq_b=~s/^\s+//;
        $flag_record_found=1;
      } elsif (/^ \s+ (\w..) (....\d)(.) (....)\s+\.\.\.  (\d\.\d\d) (...)\[(...)(...)(...)\]\s+(\d+):\s*(\S.*,.+,.*\S)\s*$/) {
        $resname_b=translate_resname($1); $resseq_b=$2;  $chain_b=$3;  $atomname_b=translate_atomname($4);
        $distance =$5;        $hbond=$6 ; $trans_a =$7;  $trans_b=$8;  $trans_c=$9;  $symop_d=$10; $symop_str=$11;
        $resseq_b=~s/^\s+//;
        $flag_record_found=1;
      }
      if ($flag_record_found==1) {
        my @record;
        my ($trans, $symop) = translate_symop($trans_a, $trans_b, $trans_c, $symop_d);
        my $trans_symop="$trans $symop";
        if (($resname_a ne 'WAT') and ($resname_b ne 'WAT')) {
          $contact_total_hits++;
          if (exists $contact_summary_numcontacts{$trans_symop}) {
            $contact_summary_numcontacts{$trans_symop}++;
          } else {
            push(@contact_summary_list, $trans_symop);
            $contact_summary_numcontacts{$trans_symop}=1;
          }
        }
        @record = ($resname_a, $resname_b, $chain_a, $chain_b, $atomname_a, $atomname_b,
                   $trans, $symop, $distance, translate_hbond($hbond), $resseq_a, $resseq_b);
        push(@contact_list, \@record);
        if (not exists $contact_header_symop_detail{$symop}) {
          $contact_header_symop_detail{$symop}=$symop_str;
          push(@contact_header_symop_list,$symop);
        }
      }
    } elsif($flag_audit_summary==1) {
      if (/^\s*(\d+)\s+(\d\d\d) (\d\d\d)\s+(\d+):/) {
        my $trans_symop="$2 $3";
        push(@audit_summary_list, $trans_symop);
        $audit_summary_numcontacts{$trans_symop}=$1;
      }
    }
  }
  close LOGFILE;


# validate audit data agreement with data calculated from contact list
  my $error_code=0;
  my $error_reason="";
  if ($contact_total_hits != $audit_total_hits) {
    $error_code=1;
    $error_reason="Audit total hits ($audit_total_hits) do not agree with number of records ($contact_total_hits)";
  } elsif ($#contact_summary_list != $#audit_summary_list) {
    $error_code=2;
    $error_reason="Audit number of distinct neighboring AU ($#audit_summary_list) do not agree with ($#contact_summary_list)";
  } else {
    foreach my $trans_symop (@audit_summary_list) {
      if (not exists $contact_summary_numcontacts{$trans_symop}) {
        $error_code=3;
        $error_reason="Hash element does not exist for symmetry operation $trans_symop";
      } elsif (not exists $audit_summary_numcontacts{$trans_symop}) {
        $error_code=4;
        $error_reason="Audit hash element does not exist for symmetry operation $trans_symop";
      } elsif ($contact_summary_numcontacts{$trans_symop} != $audit_summary_numcontacts{$trans_symop}) {
        $error_code=5;
        $error_reason="Audit hash element ($audit_summary_numcontacts{$trans_symop}) does not agree with ($contact_summary_numcontacts{$trans_symop}) for symmetry operation $trans_symop";
      }
    }
  }
  if ($error_code != 0) {
    print " <FATAL ERROR INCONSISTENT DATA $error_code: $error_reason> \n";
    foreach my $i (@contact_summary_list) {print "$i: $contact_summary_numcontacts{$i}\n"; }
    foreach my $i (@audit_summary_list)   {print "$i: $audit_summary_numcontacts{$i}\n"; }
    return $error_code;
  }
  if ($contact_total_hits == 0) {
    print " <WARNING: INCOMPLETE Assymetric Unit: 0 contacts found>";
#   if (not exists $local_id_exception{$pdbid}) {
#     push(@local_list_id_exception, $pdbid);
#     $local_id_exception{$pdbid}="Incomplete AU";
#   };
  } else {
    print " $contact_total_hits contacts found";
  }


# Write out the list of contacts
  open CONTACTFILE, '>', $contactfile or open CONTACTFILE, '>', $contactfile or die "Cannot open file for writing $contactfile: $!\n";
  foreach my $symop (@contact_header_symop_list) {
    print CONTACTFILE "# $symop|$contact_header_symop_detail{$symop}\n";
  }
  foreach my $record (@contact_list) {
    my $flag_first_column=1;
    foreach my $record_column (@$record) {
      if ($flag_first_column) {
        $flag_first_column=0;
      } else {
        print CONTACTFILE "|";
      }
      print CONTACTFILE "$record_column";
    }
    print CONTACTFILE "\n";
  }
  close CONTACTFILE;
  return 0;
}


#------------------------------------------------------------------------------

sub translate_resname{
  my $resname=shift;
  my $resname_upper=uc($resname);
  if($resname_upper =~ /^(\w)  $/) {
    return "__$1";
  } elsif($resname_upper =~ /^(\w\w) $/) {
    return "_$1";
  } else {
    return $resname_upper;
  }
}

sub translate_atomname{
  my $atomname=shift;
  my $atomname_upper=uc($atomname);
  $atomname_upper =~ s/^\s+//;
  $atomname_upper =~ s/ /=/g;  
  return $atomname_upper;
}

sub translate_trans{
  my $trans=shift;
  if ($trans =~ /^   $/) {
    return 5;
  } elsif ($trans =~ /^(.)(.)(.)$/) {
    if ($1 eq '+') {
      return 5+$2;
    } elsif ($1 eq '-') {
      return 5-$2;
    } else {
      return 5;
    }
  }
}

sub translate_symop{
  my ($trans_a, $trans_b, $trans_c, $symop_d)=@_;
  my $trans;
  my $symop;
  $trans=translate_trans($trans_a).translate_trans($trans_b).translate_trans($trans_c);
  if ($symop_d < 10) {
    $symop="00$symop_d";
  } elsif ($symop_d < 100) {
    $symop="0$symop_d";
  } else {
    $symop=$symop_d;
  }
  return ($trans, $symop);
}

sub translate_hbond{
  my $hbond=shift;
  if ($hbond =~ /^\*\*\*$/) {
    return "11";
  } elsif ($hbond =~ /^\*  $/) {
    return "01";
  } else {
    return "00";
  }
}

#subroutine to trim both preceding and trailing white spaces
sub trim {
  my $string;
  $string=$_[0];
  $string =~ s/^\s+|\s+$//g;
  return $string;
}


