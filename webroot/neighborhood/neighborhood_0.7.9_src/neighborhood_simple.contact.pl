#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;

#------------------------------ CONTACT -----------------------------------------
my $contact60_exec = "/usr/local/xtalprogs/ccp4-6.0.2/bin/contact";
my $contact61_exec = "$mypdbRootPath/ccp4-6.1.2/ccp4-6.1.2/bin/contact";
my $contact_home   = "$mypdbRootPath/contact";
my $contact_temp   = "$contact_home/test";
if (! -e $contact_home) {mkdir $contact_home, 0700 or die "cannot create $contact_home";}
if (! -e $contact_temp) {mkdir $contact_temp, 0700 or die "cannot create $contact_temp";}
#------------------------------ CONTACT -----------------------------------------

my $pdbfile="XXXX.pdb";
if (exists $ARGV[1]) {
  $pdbfile=$ARGV[1];
}
my $NEIGHBORHOOD     ="/home/dust/neighborhood_0.6.0";
$ENV{"NEIGHBORHOOD"} = $NEIGHBORHOOD;
my $exec_dir         ="$NEIGHBORHOOD/src";
my $exec_prog        ="$exec_dir/neighborhood";
my $temporary_dir    ="/var/www/html/csgid/app/webroot/neighborhood_temp/water/".$ARGV[0];

calculate_contact_file("1e2f",$temporary_dir,$pdbfile);
my $exec_line	     ="$exec_prog $temporary_dir $pdbfile XXXX.cluster NULL NULL";
system($exec_line) == 0 or die "Could not calculate neighborhood\n";



#------------------------------------------------------------------------------

sub calculate_contact_file{
  my($pdbid,$deleteflag)=@_;
  my $zipfile="$entry_datapath/pdb$pdbid\.ent.gz";
  my $modfile="$maxsprout_path/mod$pdbid\.ent";
  my $pdbfile="$contact_temp/pdb$pdbid\.ent";
  my $logfile="$contact_temp/pdb$pdbid\.log";

# my $fragmentfile="$contact_temp/pdb$pdbid\.frag.ent";
  my $contactfile="$contact_path/pdb$pdbid\.contact";

# my $assemblyid=0;
# my $htmlfileshort="pita_html/pdb$pdbid\." . $assemblyid . ".htm";
# my $datafileshort="pita_data/pdb$pdbid\." . $assemblyid . ".pdb";
# my $htmlfile="$localPitaPath/$htmlfileshort";
# my $datafile="$localPitaPath/$datafileshort";
  if($deleteflag==1) {
    unlink $contactfile;
  }
  unlink $pdbfile if -f $pdbfile;
  open ZIPFILE,  "zcat -c $zipfile |" or die "could not open the file: $zipfile: $!\n";
  my $count_num_models=0;
  while (<ZIPFILE>) {
    $count_num_models++ if (/^MODEL/); 
  }
  close ZIPFILE;
  if(-f $modfile){
#   system("cp $modfile $pdbfile")==0 or die "Fail to copy file $modfile: $!\n";
    open ZIPFILE, $modfile or die "could not open the file: $modfile: $!\n";
  }else{
    open ZIPFILE, "zcat -c $zipfile |" or die "could not open the file: $zipfile: $!\n";
  }
  open PDBFILE, '>', $pdbfile or die "can not open file $pdbfile: $!\n";
  if ($count_num_models >= 2 ) {
    $count_num_models=0;
    while(<ZIPFILE>){
      $count_num_models++ if (/^MODEL/); 
      last if $count_num_models>=2;
      print PDBFILE $_;
    }
  } else {
    while(<ZIPFILE>){print PDBFILE $_;}
  }
  close PDBFILE;
  close ZIPFILE;

  my $retcode = run_and_convert($pdbid,$pdbfile,$logfile,$contactfile,61);
  if ($retcode) {$retcode = run_and_convert($pdbid,$pdbfile,$logfile,$contactfile,60);}
  if ($retcode) {
    if (not exists $local_id_exception{$pdbid}) {
      push(@local_list_id_exception, $pdbid);
      my $errorcode=$retcode;
      $errorcode="Segmentation fault" if ($retcode==35584);
      $errorcode="Inconsistent data $retcode" if ($retcode<=5);
      $local_id_exception{$pdbid}="Fatal error $errorcode";
    };
    return $retcode;
  }

  unlink $pdbfile, $logfile;
  return 0;
}


sub run_and_convert {
  my($pdbid,$pdbfile,$logfile,$contactfile,$version)=@_;
  my $retcode = run_contact_program($pdbid, $pdbfile, $logfile, 5, $version);
  if ($retcode) {
      print "CONTACT ERROR (5): Attempt to run with 4 angstrom distance cutoff instead of 5...\n";
      $retcode = run_contact_program($pdbid, $pdbfile, $logfile, 4, $version);
      if ($retcode) {return $retcode;}
      $retcode = convert_logfile_to_contactfile($pdbid, $logfile, $contactfile);
  } else {
    $retcode = convert_logfile_to_contactfile($pdbid, $logfile, $contactfile);
    if ($retcode) {
      print "CONVERT ERROR (5): Attempt to run with 4 angstrom distance cutoff instead of 5...\n";
      $retcode = run_contact_program($pdbid, $pdbfile, $logfile, 4, $version);
      if ($retcode) {return $retcode;}
      $retcode = convert_logfile_to_contactfile($pdbid, $logfile, $contactfile);
    }
  }
  return $retcode;
}


sub run_contact_program {
  my($pdbid,$pdbfile,$logfile,$distance_cutoff,$version)=@_;
  my $contact_exec = $contact61_exec;
  if ($version == 60) {$contact_exec = $contact60_exec;}
  my $exec_line="$contact_exec xyzin $pdbfile > $logfile << eof\nBIGSEARCH\nMODE AUTO\nATYPE ALL\nLIMITS 0 $distance_cutoff\neof\n";
# print "$exec_line";
  my $retcode=1;
  my $retline="";
  eval {
    local $SIG{ALRM} = sub { die "Program not responding for 20 minutes" };
    alarm 1200;
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
      if (not exists $local_id_exception{$pdbid}) {
        push(@local_list_id_exception, $pdbid);
        $local_id_exception{$pdbid}="Non-standard space group";
      };
    };
    print " <FATAL ERROR $retcode: $retline> ";
    return $retcode;
  }
  return 0;
}


sub convert_logfile_to_contactfile{
  my($pdbid,$logfile,$contactfile)=@_;
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
      if (/^ (\w..)\s+(-?\d+)(\S) +(\w...)(\w..)\s+(-?\d+)(\S) +(\w...)\s+\.\.\.  (\d\.\d\d) (...)\[(...)(...)(...)\]\s+(\d+):\s*(\S.*,.+,.*\S)\s*$/) {
        $resname_a=translate_resname($1); $resseq_a=$2;  $chain_a=$3;  $atomname_a=translate_atomname($4);
        $resname_b=translate_resname($5); $resseq_b=$6;  $chain_b=$7;  $atomname_b=translate_atomname($8);
        $distance =$9;        $hbond=$10; $trans_a =$11; $trans_b=$12; $trans_c=$13; $symop_d=$14; $symop_str=$15;
        $flag_record_found=1;
      } elsif (/^ \s+ (\w..)\s+(-?\d+)(\S) +(\w...)\s+\.\.\.  (\d\.\d\d) (...)\[(...)(...)(...)\]\s+(\d+):\s*(\S.*,.+,.*\S)\s*$/) {
        $resname_b=translate_resname($1); $resseq_b=$2;  $chain_b=$3;  $atomname_b=translate_atomname($4);
        $distance =$5;        $hbond=$6 ; $trans_a =$7;  $trans_b=$8;  $trans_c=$9;  $symop_d=$10; $symop_str=$11;
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
    if (not exists $local_id_exception{$pdbid}) {
      push(@local_list_id_exception, $pdbid);
      $local_id_exception{$pdbid}="Incomplete AU";
    };
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

sub month2num{
  my %month;
  my $mm=shift;
  $month{'Jan'}=1;
  $month{'Feb'}=2; 
  $month{'Mar'}=3;
  $month{'Apr'}=4;
  $month{'May'}=5;
  $month{'Jun'}=6;
  $month{'Jul'}=7;
  $month{'Aug'}=8;
  $month{'Sep'}=9;
  $month{'Oct'}=10;
  $month{'Nov'}=11;
  $month{'Dec'}=12;
  
  return $month{$mm};
}

sub num2month{
  my %month;
  my $mm=shift;
  $month{1}='Jan';
  $month{2}='Feb';
  $month{3}='Mar';
  $month{4}='Apr';
  $month{5}='May';
  $month{6}='Jun';
  $month{7}='Jul';
  $month{8}='Aug';
  $month{9}='Sep';
  $month{10}='Oct';
  $month{11}='Nov';
  $month{12}='Dec';

  return $month{$mm};

}

#subroutine to trim both preceding and trailing white spaces
sub trim {
  my $string;
  $string=$_[0];
  $string =~ s/^\s+|\s+$//g;
  return $string;
}



#subroutine to compare the dates, dates have to be in 
#format like MM-DD-YYYY
#return value -1 means date1 is older than date2
#return value  1 means date1 is newer than date2
#return value  0 means date1 is the same as date2
sub comparedate{
  my $date1=shift;
  my $date2=shift;
  
  my $yy1;
  my $mm1;
  my $dd1;
  
  my $yy2;
  my $mm2;
  my $dd2;
  
  ($mm1,$dd1,$yy1) = split(/-/, $date1);
  ($mm2,$dd2,$yy2) = split(/-/, $date2);

    
  if($yy1 < $yy2){
    return -1;
  }elsif($yy1 > $yy2){
    return 1;
  }
  
  if($mm1 < $mm2){
    return -1;
  }elsif($mm1 > $mm2){
    return 1;
  }
  
  if($dd1 < $dd2){
    return -1;
  }elsif($dd1 > $dd2){
    return 1;
  }
  
  return 0;

}
