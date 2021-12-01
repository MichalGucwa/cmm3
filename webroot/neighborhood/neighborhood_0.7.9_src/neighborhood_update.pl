#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Pg;
use File::Copy;
use Switch;


my $NEIGHBORHOOD       ="/home/dust/neighborhood_0.7.9_src";
my $MYPDB_NEW          ="/med/zenobi_data/MYPDB_NEW";
my $PSQL_DIR           ="/usr/bin";
my $NEIGHBORHOODTEMP   =".";
my $NEIGHBORHOOD_DEBUG =1;
my $have_priviledge    =0;

die "Environmental variable NEIGHBORHOOD need to be set to the neighborhood path\n" if (not defined $ENV{"NEIGHBORHOOD"} or $ENV{"NEIGHBORHOOD"} eq "");

$NEIGHBORHOOD    =$ENV{"NEIGHBORHOOD"}          if defined $ENV{"NEIGHBORHOOD"};
$MYPDB_NEW       =$ENV{"MYPDB_NEW"}             if defined $ENV{"MYPDB_NEW"};
$PSQL_DIR        =$ENV{"PSQL_DIR"}              if defined $ENV{"PSQL_DIR"};
$NEIGHBORHOODTEMP=$ENV{"HOME"}."/.NEIGHBORHOOD" if defined $ENV{"HOME"};
$NEIGHBORHOODTEMP=$ENV{"NEIGHBORHOODTEMP"}      if defined $ENV{"NEIGHBORHOODTEMP"};
$NEIGHBORHOOD_DEBUG=$ENV{"NEIGHBORHOOD_DEBUG"}  if defined $ENV{"NEIGHBORHOOD_DEBUG"};
if (-e $NEIGHBORHOODTEMP and not (-d $NEIGHBORHOODTEMP)) {
  die "Please remove file $NEIGHBORHOODTEMP before you can proceed";
} elsif (not -e $NEIGHBORHOODTEMP) {
  mkdir $NEIGHBORHOODTEMP;
}

#User specific
my $database_root      ="neighborhood14";
my $database_user      ="dust";
my $database_password  ="dust2008";
my $database_name      =$database_root;

#Don't edit below.
$database_user=$ENV{"USER"} if defined $ENV{"USER"};

$database_user      ="sg_display";
$database_password  ="";
#$database_password=""       if $database_user ne "dust";
#my $pdb_entries_dir   = "$NEIGHBORHOOD/test";
my $pdb_entries_dir    ="$MYPDB_NEW/AU0_pdb_entries";            # file name pattern: pdb100d.ent.gz
my $mod_entries_dir    ="$MYPDB_NEW/AU1_maxsprout";              # file name pattern: mod1a1d.ent
my $AU_molprobity_dir  ="$MYPDB_NEW/AU4_probe";                  # file name pattern: aup100d.ent
my $AU_contact_dir     ="$MYPDB_NEW/AU2_contact";                # file name pattern: contact100d.ent
my $BU_header_dir      ="$MYPDB_NEW/BU4_chain_projection/header";# file name pattern: pdb1b5j.header
my $temporary_dir      ="$NEIGHBORHOODTEMP/temp_for_neighboorhood";
my $zcat_prog          ="/bin/zcat";
my $psql_prog          ="$PSQL_DIR/psql";
my $createdb_prog      ="$PSQL_DIR/createdb";
my $dropdb_prog        ="$PSQL_DIR/dropdb";
my $createlang_prog    ="$PSQL_DIR/createlang";
#my $database_host      ="zenobi.med.virginia.edu";
my $database_host      ="127.0.0.1";
my $database_port      ="5432";

my $lib_dir            ="$MYPDB_NEW/derived";
my $backup_lib_dir     ="$NEIGHBORHOOD/lib";
my $exec_dir           ="$NEIGHBORHOOD/src";
my $exec_prog          ="$exec_dir/neighborhood";
my $sql_dir            ="$NEIGHBORHOOD/sql";
my $sql_create_util    ="$sql_dir/util.sql";
my $sql_create_table   ="$sql_dir/createNeighborhoodTables.sql";
my $sql_update_begin   ="$sql_dir/updateBegin.sql";
my $sql_copy_data      ="copyNeighborhoodData.sql";
my $sql_update_end     ="$sql_dir/updateEnd.sql";
my $abinitio           =0;
my $abinitio           =1;
my $start_pdbfileid    =0;
my $dbh;
my $sth;
my @row;
my %arr_filelist;
my %arr_filelist_fifty;
my %arr_filelist_ninety;
my %arr_filelist_short;
my %arr_filelist_cdf;
my %arr_filelist_clf;
my %arr_filelist_gaf;
my %ARR_DBRECORD;

#process_sql_file("test.sql");

#------------------------------------------------------------------------------
# A subset of pdb file can be selectively chosen by using the command "./neighborhood_update.pl -f [SUBSET_FILE_NAME]"
#------------------------------------------------------------------------------
my $use_subset=0;
my $subset_size=0;
my $single_mode=0;
my %pdbid_dict;
my @filelist_subset=();
if (exists $ARGV[0]) {
  if (($ARGV[0] eq "-l") or ($ARGV[0] eq "-f")) {
    my $file_restrict_pdbid_set_path;
    my $file_restrict_pdbid_set_name;
    die "file name expected with -f or -l option" if (not exists $ARGV[1]);
    $file_restrict_pdbid_set_path=$ARGV[1];
    die "file do not exist\n" if not -f $file_restrict_pdbid_set_path;
    if ($ARGV[0] eq "-f") {
      $single_mode=1;
      $use_subset=1;
      $subset_size++;
    } else {
      #$ARGV[0] must be -l
      #Populate a hash of filenames %pdbid_dict with pdbcodes.
      open SUBSET, "$file_restrict_pdbid_set_path" or die "Cannot open file $file_restrict_pdbid_set_path";
      while (<SUBSET>) {
        if(/^\s*(\w{4})\s*$/) {
          my $upper_pdbid = "\U$1";
          my $lower_pdbid = "\L$1";
          $pdbid_dict{$lower_pdbid}=1;
          push(@filelist_subset,"$upper_pdbid");
          $use_subset=1;
          $subset_size++;
        }
      } # end while (<SUBSET>)
      close SUBSET;
      die "$file_restrict_pdbid_set_path is empty and contains no pdbid record" unless $use_subset;
    } # end if/else ($ARGV[0] eq "-f")

    if((exists $ARGV[2]) and ($ARGV[2] ne "1")) {
      $database_name=$ARGV[2];
      $temporary_dir="$NEIGHBORHOODTEMP/temp_for_$database_name";
      $abinitio= &check_for_dbase;
    } else {
      $abinitio=1;
      if($file_restrict_pdbid_set_path =~ /\/([^\/]+)$/) {
        $file_restrict_pdbid_set_name=$1;
      } else {
        $file_restrict_pdbid_set_name=$file_restrict_pdbid_set_path;
      }
      my $file_root = $file_restrict_pdbid_set_name;
      $file_root =~ s/\..*//;
      $database_name="$database_root-$file_root";
      $temporary_dir="$NEIGHBORHOODTEMP/temp_for_$database_name";
    }
  } elsif ($ARGV[0] eq "1") {
    $abinitio=1;
  } elsif ($ARGV[0] eq "0") {
    $abinitio=0;
  }
} # end if (exists $ARGV[0])

my $NEIGHBORHOODLOCK="$temporary_dir/.neighborhood_lock";
if (-e $temporary_dir and not (-d $temporary_dir)) {
  die "Please remove file $temporary_dir before you can proceed";
} elsif (not -e $temporary_dir) {
  mkdir $temporary_dir;
}

if(-e $NEIGHBORHOODLOCK) {
  print "Another process is trying to update the database. If the previous update process didn't finish successfully, please remove the lock $NEIGHBORHOODLOCK before you can proceed.\n";
  exit;
} else {
  open  LOCK, '>', "$NEIGHBORHOODLOCK" or die "Cannot open file $NEIGHBORHOODLOCK";
  print LOCK "$NEIGHBORHOODLOCK";
  close LOCK;
}

#------------------------------------------------------------------------------
# subroutines
#------------------------------------------------------------------------------
sub check_for_dbase {
  my $db_check = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_user","$database_password", {PrintError => 0});
  if ($db_check) { 
    $db_check->disconnect() or warn $DBI::errstr;
    return 0;
  } else {return 1};
} # End sub check_for_dbase 
    
sub cath_set_CDF {      # Setting up CATH Domall File (CDF) Format 2.0
  my $filename = shift;
  my $error_detected=0;
  my $pdbid;
  my $chainid;
  my $domallcount;
  my $remainder;
  print "Setting CATH CDF information for $filename\n";
  open CATHCDF, "$filename" or die "Cannot open file $filename";
  while (<CATHCDF>) {
    my $line=$_;
    my $comments=0;
    if (/^(\w\w\w\w)(\S) (D\d\d) (F\d\d)( .*)$/) {
      $pdbid         =$1;
      $chainid       =$2;
      $domallcount   =$3.$4;
      $remainder     =$5;
      $chainid="_" if ($chainid eq "0");
    } elsif (/^#/) {
      $comments=1;
    } else {
      $error_detected=1;
    }
    if ($error_detected) {
      die("ERROR: \"$line\" cannot be recognized\n");
    } elsif(not $comments) {
      my $upper_pdbid="\U$pdbid";
      if ((exists $arr_filelist{$upper_pdbid}) and ($#{$arr_filelist{$upper_pdbid}}==8)) {
        $arr_filelist{$upper_pdbid}->[6]++;
        my @file_record_field = ($chainid, $domallcount, $remainder);
        @{$arr_filelist_cdf{$upper_pdbid}}=() if not exists $arr_filelist_cdf{$upper_pdbid};
        push (@{$arr_filelist_cdf{$upper_pdbid}}, \@file_record_field);
      }
    }
  }
  close CATHCDF;
}

sub cath_set_CLF {      # Setting up CATH List File (CLF) Format 2.0
  my $filename = shift;
  my $error_detected=0;
  my $pdbid;
  my $chainid;
  my $domainnum;
  my $remainder;
  print "Setting CATH CLF information for $filename\n";
  open CATHCLF, "$filename" or die "Cannot open file $filename";
  while (<CATHCLF>) {
    my $line=$_;
    my $comments=0;
    if (/^(\w\w\w\w)(\S)(\d\d)( .*)$/) {
      $pdbid         =$1;
      $chainid       =$2;
      $domainnum     =$3;
      $remainder     =$4;
      $chainid="_" if ($chainid eq "0");
    } elsif (/^#/) {
      $comments=1;
    } else {
      $error_detected=1;
    }
    if ($error_detected) {
      die("ERROR: \"$line\" cannot be recognized\n");
    } elsif(not $comments) {
      my $upper_pdbid="\U$pdbid";
      if ((exists $arr_filelist{$upper_pdbid}) and ($#{$arr_filelist{$upper_pdbid}}==8)) {
        $arr_filelist{$upper_pdbid}->[7]++;
        my @file_record_field = ($chainid, $domainnum, $remainder);
        @{$arr_filelist_clf{$upper_pdbid}}=() if not exists $arr_filelist_clf{$upper_pdbid};
        push (@{$arr_filelist_clf{$upper_pdbid}}, \@file_record_field);
      }
    }
  }
  close CATHCLF;
}

=comment geneontology
CREATE TABLE geneontology(
    id                  serial,
    pdbfileid           integer NOT NULL REFERENCES pdbfile (pdbfileid) ON UPDATE NO ACTION ON DELETE NO ACTION,
    pdbid               char(4),
    chainid             char(1),
    namespace           char(1) NOT NULL,       -- 'P','F','C'
    qualifier           boolean,
    qualifier_detail    char(20),               -- contributes_to, colocalizes_with
    go_id               integer,
    evidence            char(3) NOT NULL,       -- EXP, IMP, IC, IGI, IPI, ISS, IDA, IEP, IEA, TAS, NAS, NR, ND, RCA, ISA, or ISO.
    ref_db_name         char(20),
    ref_db_id           integer,
    xref_db_name        char(20),
    xref_db_id          text,
    organism_id         integer,
    created_by          char(20),
    creation_date       date,
);
=cut

sub go_set_GAF_error {
  my ($err_type, $err_value) = @_;
  my $err_message="";
  if($err_type==-1) {
    $err_message="unexpected number of fields";
  } else {
    $err_message="Unexpected value from field # $err_type";
  }
  die "GAF file record reading error: $err_message - ($err_value).\n";
}

sub go_set_GAF {
  my $filename=shift;
  print "Setting gene ontology information for $filename...\n";
  open GOGAF, "zcat -c $filename |" or die "Cannot open file $filename";
  while (<GOGAF>) {
    my $line=$_;
    if (/^\s*!.*$/) {
      # Do nothing if it is comments
    } else {
      my @fields=split(/\t/,$line);
      if($#fields == 16) {
        my $upper_pdbid="";
        my $chainid="";
        my $qualifier=0;
        my $go_id=0;
        my $ref_db_name="";
        my $ref_db_id="";
        my $evidence="";
        my $xref_db_name="";
        my $xref_db_id="";
        my $namespace="U";
        my $organism_id=-1;
        my $created_by="";
        my $creation_date="12-31-69";;
        go_set_GAF_error(0,$fields[0]) if $fields[0] ne "PDB";
        if ($fields[1] =~ /^(\w\w\w\w)_(\w)$/) {
          $upper_pdbid="\U$1";
          $chainid=$2;
        } else {
          go_set_GAF_error(1,$fields[1]);
        }
        go_set_GAF_error(2,$fields[2]) if $fields[2] ne $fields[1];
        if      ($fields[3] eq ""                    ) { $qualifier=1;
        } elsif ($fields[3] eq "NOT"                 ) { $qualifier=-1;
        } elsif ($fields[3] eq "contributes_to"      ) { $qualifier=2;
        } elsif ($fields[3] eq "colocalizes_with"    ) { $qualifier=3;
        } elsif ($fields[3] eq "NOT|contributes_to"  ) { $qualifier=-2;
        } elsif ($fields[3] eq "NOT|colocalizes_with") { $qualifier=-3;
        } else { go_set_GAF_error(3,$fields[3]);
        }
        if ($fields[4] =~ /^GO:(\d{7})$/) {
          $go_id=$1;
        } else {
          go_set_GAF_error(4,$fields[4]);
        }
        if ($fields[5] =~ /^(GO_REF|PMID):(\d+)\s*$/) {
          $ref_db_name=$1;
          $ref_db_id=$2;
        } elsif ($fields[5] =~ /^(Reactome):REACT_(\d+)\s*$/) {
          $ref_db_name=$1;
          $ref_db_id=$2;
        } elsif ($fields[5] =~ /^(DOI):(\S+)\s*$/) {
          $ref_db_name=$1;
          $ref_db_id=$2;
        } else {
          go_set_GAF_error(5,$fields[5]);
        }
        if($fields[6] eq "EXP" or $fields[6] eq "IMP" or $fields[6] eq "IC"  or $fields[6] eq "IGI" or $fields[6] eq "IPI" or
           $fields[6] eq "ISS" or $fields[6] eq "IDA" or $fields[6] eq "IEP" or $fields[6] eq "IEA" or $fields[6] eq "TAS" or
           $fields[6] eq "NAS" or $fields[6] eq "NR"  or $fields[6] eq "ND"  or $fields[6] eq "RCA" or $fields[6] eq "IBA" or
           $fields[6] eq "IRD" or $fields[6] eq "ISA" or $fields[6] eq "ISO" or $fields[6] eq "ISM" or $fields[6] eq "PDB" or
           $fields[6] eq "IGC") {
          $evidence=$fields[6];
        } else {
          go_set_GAF_error(6,$fields[6]);
        }
        if ($fields[7] =~ /^(\S+):(\S+)\s*$/) {
          $xref_db_name="\U$1";
          $xref_db_id=$2;
        } elsif ($fields[7] eq "") {
          $xref_db_name="";
          $xref_db_id="";
        } else {
          go_set_GAF_error(7,$fields[7]);
        }
        if($fields[8] eq "P" or $fields[8] eq "F" or $fields[8] eq "C") {
          $namespace=$fields[8];
        } else {
          go_set_GAF_error(8,$fields[8]);
        }
        go_set_GAF_error( 9,$fields[9] ) if $fields[9]  ne "";
        go_set_GAF_error(10,$fields[10]) if $fields[10] ne "";
        go_set_GAF_error(11,$fields[11]) if $fields[11] ne "protein_structure";
        if($fields[12] =~ /^taxon:(\d+)\s*$/) {
          $organism_id=$1;
        } elsif($fields[12] =~ /^taxon:$/) {
          $organism_id=-1;
        } else {
          go_set_GAF_error(12,$fields[12]);
        }
        if($fields[13] =~ /^(19|20)(\d\d)(\d\d)(\d\d)$/) {
          $creation_date="$3-$4-$2";
        } else {
          go_set_GAF_error(13,$fields[13]);
        }
        if($fields[14] =~ /^(\S+)\s*$/) {
          $created_by="\U$1";
        } else {
          go_set_GAF_error(14,$fields[14]);
        }
        go_set_GAF_error(15,$fields[15]) if $fields[15] ne "";
        go_set_GAF_error(16,$fields[16]) if ($fields[16] ne "" and $fields[16] ne "\n");
        if ((exists $arr_filelist{$upper_pdbid}) and ($#{$arr_filelist{$upper_pdbid}}==8)) {
          $arr_filelist{$upper_pdbid}->[8]++;
          my @file_record_field = ($chainid, $namespace, $qualifier, $go_id, $ref_db_name, $ref_db_id, $evidence, $xref_db_name, $xref_db_id, $organism_id, $created_by, $creation_date);
          @{$arr_filelist_gaf{$upper_pdbid}}=() if not exists $arr_filelist_gaf{$upper_pdbid};
          push (@{$arr_filelist_gaf{$upper_pdbid}}, \@file_record_field);
        }
      } else {
        go_set_GAF_error(-1,$#fields);
      }
    }
  }
  close GOGAF;
}

sub cdhit_set_clusters {
  my ($filename, $field) = @_;
  my $first_run=0;
  my $error_detected=0;
  my $clusterid;
  my $representid;
  my $pdbid;
  my $chainid;
  print "Setting cluster information for $filename\n";
  if ($field eq "fifty") {$first_run=1;} else {$first_run=0;}
  open CLUSTERIN, "$filename" or die "Cannot open file $filename";
  while (<CLUSTERIN>) {
    my $line=$_;
    if (/^(\d+)\s+(\d+)\s+(\w\w\w\w):(\w)$/) {
      $clusterid   = $1;
      $representid = $2;
      $pdbid       = $3;
      $chainid     = $4;
    } elsif (/^(\d+)\s+(\d+)\s+(\w\w\w\w):([a-z])([a-z])$/) {
      if ($4 eq $5) {
        $clusterid   = $1;
        $representid = $2;
        $pdbid       = $3;
        $chainid     = $4;
      } else { $error_detected=1; }
    } else {
      $error_detected=1;
    }
    if ($error_detected) {
      die("ERROR: \"$line\" cannot be recognized\n");
    } else {
      my $upper_pdbid="\U$pdbid";
      if ((exists $arr_filelist{$upper_pdbid}) and ($#{$arr_filelist{$upper_pdbid}}==8)) {
        $arr_filelist{$upper_pdbid}->[3]=2;
        my @file_record_field = ($chainid, $clusterid, $representid);
        if ($field eq "fifty") {
          @{$arr_filelist_fifty{$upper_pdbid}}=() if not exists $arr_filelist_fifty{$upper_pdbid};
          push (@{$arr_filelist_fifty{$upper_pdbid}}, \@file_record_field);
        } elsif ($field eq "ninety") {
          @{$arr_filelist_ninety{$upper_pdbid}}=() if not exists $arr_filelist_ninety{$upper_pdbid};
          push (@{$arr_filelist_ninety{$upper_pdbid}}, \@file_record_field);
        } else {
          die "Unexpected field parameter for subroutine cdhit_set_clusters: $field";
        }
      }
    }
  }
  close CLUSTERIN;
}

sub cdhit_set_short {
  my $filename=shift;
  my $error_detected=0;
  open SHORTIN, "$filename" or die "Cannot open file $filename";
  while (<SHORTIN>) {
    my $line=$_;
    my $pdbid;
    my $chainid;
    if (/^(\w\w\w\w):(\S)$/) {
      $pdbid=$1;
      $chainid=$2;
    } elsif (/^(\w\w\w\w):$/) {
      $pdbid=$1;
      $chainid="_";
    } else {
      $error_detected=1;
    }
    if ($error_detected) {
      die("ERROR: \"$line\" cannot be recognized\n");
    } else {
      my $upper_pdbid="\U$pdbid";
      if ((exists $arr_filelist{$upper_pdbid}) and ($#{$arr_filelist{$upper_pdbid}}==8)) {
        my $file_record = $arr_filelist{$upper_pdbid};
        my $flag = $file_record->[3];
        $flag++ if ($flag==0 || $flag==2);
        $file_record->[3] = $flag;
        my @file_record_field = ($chainid, -1, -1);
        @{$arr_filelist_short{$upper_pdbid}}=() if not exists $arr_filelist_short{$upper_pdbid};
        push (@{$arr_filelist_short{$upper_pdbid}}, \@file_record_field);
      }
    }
  }
  close SHORTIN;
}

sub format_six_digit {
  my ($figure, $newline) = @_;
  my $numlen=length($figure);
  for (my $i=$numlen;$i<6;$i++) {print CLUSTEROUT " ";}
  print CLUSTEROUT $figure;
  if ($newline) {
    print CLUSTEROUT "\n";
  }
}

sub format_n_digit {
  my ($figure, $ndigit) = @_;
  my $numlen=length($figure);
  if($numlen<=$ndigit) {
    for (my $i=$numlen;$i<$ndigit;$i++) {print CLUSTEROUT " ";}
    print CLUSTEROUT $figure;
  } else {
    my $figure_cut = substr $figure, 0, $ndigit;
    print CLUSTEROUT $figure_cut;
  }
}

sub generate_cluster_file {
  my ($upper_pdbid, $filename) = @_;
  my $start_pdbfileid=$arr_filelist{$upper_pdbid}->[2];
  my $flag           =$arr_filelist{$upper_pdbid}->[3];
  my $cath_cdf_flag  =$arr_filelist{$upper_pdbid}->[6];
  my $cath_clf_flag  =$arr_filelist{$upper_pdbid}->[7];
  my $go_gaf_flag    =$arr_filelist{$upper_pdbid}->[8];
  open CLUSTEROUT, '>', $filename;
  print CLUSTEROUT "PDBFILE   ";
  format_n_digit($start_pdbfileid, 10);
  print "\n";
  if ($flag >= 2) {
    foreach my $chain (@{$arr_filelist_ninety{$upper_pdbid}}) {
      my $chainid     = $chain->[0];
      my $clusterid   = $chain->[1];
      my $representid = $chain->[2];
      print CLUSTEROUT "CLUST90 ";
      print CLUSTEROUT "$chainid ";
      format_six_digit($clusterid, 0); 
      format_six_digit($representid, 1);
    }
    foreach my $chain (@{$arr_filelist_fifty{$upper_pdbid}}) {
      my $chainid     = $chain->[0];
      my $clusterid   = $chain->[1];
      my $representid = $chain->[2];
      print CLUSTEROUT "CLUST50 ";
      print CLUSTEROUT "$chainid ";
      format_six_digit($clusterid, 0); 
      format_six_digit($representid, 1);
    }
  }
  if ($flag==1 or $flag==3) {
    foreach my $chain (@{$arr_filelist_short{$upper_pdbid}}) {
      my $chainid = $chain->[0];
      print CLUSTEROUT "SHORT   ";
      print CLUSTEROUT "$chainid \n";
    }
  }
  if ($cath_cdf_flag) {
    foreach my $chain (@{$arr_filelist_cdf{$upper_pdbid}}) {
      my $chainid     = $chain->[0];
      my $domallcount = $chain->[1];
      my $cdf_info    = $chain->[2];
      print CLUSTEROUT "DOMALL  ";
      print CLUSTEROUT "$chainid ";
      format_six_digit($domallcount, 0);
      print CLUSTEROUT "$cdf_info\n";
    }
  }
  if ($cath_clf_flag) {
    foreach my $chain (@{$arr_filelist_clf{$upper_pdbid}}) {
      my $chainid     = $chain->[0];
      my $domainnum   = $chain->[1];
      my $clf_info    = $chain->[2];
      print CLUSTEROUT "DOMAIN  ";
      print CLUSTEROUT "$chainid ";
      format_six_digit($domainnum, 0);
      print CLUSTEROUT "$clf_info\n";
    }
  }
  if ($go_gaf_flag) {
    foreach my $chain (@{$arr_filelist_gaf{$upper_pdbid}}) {
      my $namespace    = $chain->[1];
      my $chainid      = $chain->[0];
      my $go_id        = $chain->[3];
      my $qualifier    = $chain->[2];
      my $evidence     = $chain->[6];
      my $xref_db_name = $chain->[7];
      my $xref_db_id   = $chain->[8];
      my $organism_id  = $chain->[9];
      my $creation_date= $chain->[11];
      my $created_by   = $chain->[10];
      my $ref_db_name  = $chain->[4];
      my $ref_db_id    = $chain->[5];
      print CLUSTEROUT "GOPROC  " if($namespace eq "P");
      print CLUSTEROUT "GOFUNC  " if($namespace eq "F");
      print CLUSTEROUT "GOCOMP  " if($namespace eq "C");
      print CLUSTEROUT "$chainid$go_id";
      format_six_digit($qualifier,   0);        # width=1
      format_six_digit($evidence,    0);        # width=1
      format_n_digit($xref_db_name, 12);        # width=2
      format_n_digit($xref_db_id,   18);        # width=3
      format_n_digit($organism_id,   9);        # width=1.5
      format_n_digit($creation_date, 9);        # width=1.5
      format_n_digit($created_by,   18);        # width=3
      print CLUSTEROUT " $ref_db_name:$ref_db_id\n";
    }
  }
  close CLUSTEROUT;
}

sub generate_other_input_file {
  my ($dir_src, $file_src, $dir_des, $file_type) = @_;
  my $filename     = "$dir_src/$file_src";
  my $outfilename  = "$dir_des/$file_src";
  my $ret_file_src = "NULL";
  if (-e $filename and -f $filename) {
    system("cp $filename $outfilename") == 0 or die "Could not copy file $filename\n";
    $ret_file_src = $file_src;
  }
  print "$file_type... ";
  return $ret_file_src;
}

sub process_sql_file {
  my $filename=shift;
  my $sqlcommand="$psql_prog -U$database_user -p$database_port $database_name < $filename\n";
  print $sqlcommand;
  system($sqlcommand) == 0 or die "SQL command exit abnormally for DB $database_name file $filename\n";
}

sub process_sql_command {
  my $command=shift;
  my $sqlcommand="$psql_prog -U$database_user -p$database_port $database_name << HEPING\n$command\nHEPING\n";
  print $sqlcommand;
  system($sqlcommand) == 0 or die "SQL command exit abnormally for DB $database_name command $command\n";
}

sub print_cluster_info {
  my $filelist=shift;
  my $num_undef_pdbfile    =0;
  my $num_defined_pdbfile  =0;
  my $num_clustered_pdbfile=0;
  my $num_short_pdbfile    =0;
  my $num_clustered_chains =0;
  my $num_short_chains     =0;
  my $num_undef_cdf        =0;
  my $num_defined_cdf      =0;
  my $num_chain_cdf        =0;
  my $num_domain_cdf       =0;
  my $num_fragment_cdf     =0;
  my $num_undef_clf        =0;
  my $num_defined_clf      =0;
  my $num_chain_clf        =0;
  my $num_domain_clf       =0;
  my $num_undef_gaf        =0;
  my $num_defined_gaf      =0;
  my $num_chain_gaf        =0;
  my %clf_chain_flag;
  my $chain;
  foreach my $upper_pdbid (@{$filelist}) {
    my $pdbfile_undef=1;
    my $pdbfile_undef_cdf=1;
    my $pdbfile_undef_clf=1;
    my $pdbfile_undef_gaf=1;
    if (exists $arr_filelist_ninety{$upper_pdbid}) {
      foreach $chain (@{$arr_filelist_ninety{$upper_pdbid}}) {
        $num_clustered_chains++;
      }
      $pdbfile_undef=0;
      $num_clustered_pdbfile++;
    } elsif (exists $arr_filelist_short{$upper_pdbid}) {
      foreach $chain (@{$arr_filelist_short{$upper_pdbid}}) {
        $num_short_chains++;
      }
      $pdbfile_undef=0;
      $num_short_pdbfile++;
    }
    if (exists $arr_filelist_cdf{$upper_pdbid}) {
      foreach $chain (@{$arr_filelist_cdf{$upper_pdbid}}) {
        $num_chain_cdf++;
        if($chain->[1] =~ /^D(\d\d)F(\d\d)$/){
          $num_domain_cdf+=$1;
          $num_fragment_cdf+=$2;
        }
      }
      $pdbfile_undef_cdf=0;
    }
    if (exists $arr_filelist_clf{$upper_pdbid}) {
      foreach $chain (@{$arr_filelist_clf{$upper_pdbid}}) {
        my $clf_chain_id=$upper_pdbid.$chain->[0];
        if (not exists $clf_chain_flag{$clf_chain_id}) {
          $clf_chain_flag{$clf_chain_id}=1;
          $num_chain_clf++;
        }
        $num_domain_clf++;
      }
      $pdbfile_undef_clf=0;
    }
    if (exists $arr_filelist_gaf{$upper_pdbid}) {
      foreach $chain (@{$arr_filelist_gaf{$upper_pdbid}}) {
        $num_chain_gaf++;
      }
      $pdbfile_undef_gaf=0;
    }
    if ($pdbfile_undef) {$num_undef_pdbfile++;} else {$num_defined_pdbfile++;}
    if ($pdbfile_undef_cdf) {$num_undef_cdf++;} else {$num_defined_cdf++;}
    if ($pdbfile_undef_clf) {$num_undef_clf++;} else {$num_defined_clf++;}
    if ($pdbfile_undef_gaf) {$num_undef_gaf++;} else {$num_defined_gaf++;}
  }
  print "  PDB file lack clustering info:   $num_undef_pdbfile\n";
  print "  PDB file with clustering info:   $num_defined_pdbfile\n";
  print "  PDB file contains cluster chain: $num_clustered_pdbfile ($num_clustered_chains chains)\n";
  print "  PDB file contains short chain:   $num_short_pdbfile ($num_short_chains chains)\n";
  print "  PDB file lack CATH CDF info:     $num_undef_cdf\n";
  print "  PDB file with CATH CDF info:     $num_defined_cdf ($num_chain_cdf chains, $num_domain_cdf domains, $num_fragment_cdf fragments)\n";
  print "  PDB file lack CATH CLF info:     $num_undef_clf\n";
  print "  PDB file with CATH CLF info:     $num_defined_clf ($num_chain_clf chains, $num_domain_clf domains)\n";
  print "  PDB file lack GO GAF info:       $num_undef_gaf\n";
  print "  PDB file with GO GAF info:       $num_defined_gaf ($num_chain_gaf chains)\n";
}

sub extract_pdbid {
  my $filename=shift;
  print "filename is $filename\n";
  if($filename =~ /(^|\/)(\d\w\w\w)\.pdb$/) {
    return $2;
  } else {
    return "XXXX";
  }
}


#------------------------------------------------------------------------------
# getting list of existing database records
#------------------------------------------------------------------------------

if ($abinitio) {
  my $dropdb="$dropdb_prog -p$database_port $database_name";
  my $createdb="$createdb_prog -p$database_port $database_name";
  my $createlang="$createlang_prog plpgsql -p$database_port $database_name";
  if($have_priviledge) {
    system($dropdb);
    system($createdb) == 0 or die "Database creation exit abnormally for DB $database_name\n";
    system($createlang);
  }
  process_sql_file($sql_create_util);
  $start_pdbfileid=0;
  process_sql_file($sql_create_table);

  my $eth0_line=0;
  my $ifconfig_line="";
  my $ip_address="";
  my $mac_address="";
  open IFCONFIG, '/sbin/ifconfig |' or die 'Cannot execute ifconfig\n';
  while (<IFCONFIG>) {
    if(/^eth0/) { $eth0_line=1; $ifconfig_line=$_;
    } elsif ($eth0_line and /^\s/) { $eth0_line=1; $ifconfig_line=$_;
    } else { $eth0_line=0; $ifconfig_line=""; }
    if ($eth0_line) {
      if($ifconfig_line =~ /inet addr:\s*([12]?\d?\d).([12]?\d?\d).([12]?\d?\d).([12]?\d?\d)/) {
        $ip_address="$1.$2.$3.$4";
      } elsif($ifconfig_line =~ /HWaddr\s*([0-9a-fA-F][0-9a-fA-F]):([0-9a-fA-F][0-9a-fA-F]):([0-9a-fA-F][0-9a-fA-F]):([0-9a-fA-F][0-9a-fA-F]):([0-9a-fA-F][0-9a-fA-F]):([0-9a-fA-F][0-9a-fA-F])/) {
        $mac_address="$1:$2:$3:$4:$5:$6";
      }
    }
  }
  close IFCONFIG;
  process_sql_command("INSERT INTO neighborhood (purpose,version,host,ip,port,mac_address,database_name) values ('general','0.7.9','$database_host','$ip_address',$database_port,'$mac_address','$database_name');");

} else {
# $dbh = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_user","$database_password") or die $DBI::errstr;
  $dbh = DBI->connect("dbi:Pg:dbname=$database_name","$database_user") or die $DBI::errstr;
# $dbh = DBI->connect("dbi:Pg:dbname=$database_name") or die $DBI::errstr;
  print "Connection successfully established\n";

  $sth = $dbh->prepare("SELECT max(pdbfileid) FROM pdbfiles;") or die $DBI::errstr;
  $sth->execute() or die $DBI::errstr;
  while (@row = $sth->fetchrow_array()){
    my $database_last_pdbfileid=$row[0];
    if (defined $database_last_pdbfileid and $database_last_pdbfileid >= $start_pdbfileid) {
      $start_pdbfileid=$database_last_pdbfileid+1;
    }
  }
  $sth->finish() or warn $DBI::errstr;
  print "Update will begin with pdbfileid $start_pdbfileid\n";

  $sth = $dbh->prepare("SELECT pdbfileid, pdbid FROM pdbfiles;") or die $DBI::errstr;
  $sth->execute() or die $DBI::errstr;
  while (@row = $sth->fetchrow_array()){
    my $pdbfileid   = $row[0];
    my $pdbid       = $row[1];
    my $upper_pdbid = "\U$pdbid";
    $ARR_DBRECORD{$upper_pdbid}=$pdbfileid;
  }
  $sth->finish() or warn $DBI::errstr;

  $dbh->disconnect() or warn $DBI::errstr;
}

# By now, $start_pdbfileid is set properly, and %ARR_DBRECORD is a hash list contains indexed pdbfileid
#------------------------------------------------------------------------------
# getting list of PDB files on file system
#------------------------------------------------------------------------------
if (not $single_mode) {
  die "Directory $pdb_entries_dir does not exists" unless (-e $pdb_entries_dir and -d $pdb_entries_dir);
  die "Directory $mod_entries_dir does not exists" unless (-e $mod_entries_dir and -d $mod_entries_dir);
}

my @filelist_new=();
my @filelist_update=();
my %filelist_obsolete;
my $num_all_records=0;
my $num_existing_records=0;
my $num_new_records=0;

if ($single_mode) {
  push (@filelist_new, extract_pdbid($ARGV[1]));
  $num_new_records++;
  $num_all_records++;
} else {
  opendir DIR, $pdb_entries_dir || die "Cannot read directory $pdb_entries_dir\n";
  while (my $zipfile = readdir DIR) {
    if ($zipfile =~ /obsolete/) {
      # Do nothing if it is obsolete
      if ($zipfile =~ /pdb(....)\.ent.*obsolete/) {
        my $upper_pdbid = "\U$1";
        $filelist_obsolete{$upper_pdbid}=1;
      }
    } elsif ($zipfile =~ /(pdb(....)\.ent)/) {
      my $pdbfile = $1;
      my $pdbid   = $2;
      my $upper_pdbid = "\U$2";
      my $db_pdbfileid;
      my $updateflag;
      if (exists $ARR_DBRECORD{$upper_pdbid}) {
        push (@filelist_update, $upper_pdbid);
        $num_existing_records++;
        $db_pdbfileid=$ARR_DBRECORD{$upper_pdbid};
        $updateflag=1;
      } else {
        push (@filelist_new, $upper_pdbid);
        $num_new_records++;
        $db_pdbfileid=$start_pdbfileid;
        $updateflag=0;
        $start_pdbfileid++;
      }
      my $modfile="mod$pdbid.ent";
      my @file_record=();
      if (-e "$mod_entries_dir/$modfile") {
        @file_record=($modfile, $pdbfile, $db_pdbfileid, 0, 1, $updateflag, 0, 0, 0);
      } else {
        @file_record=($zipfile, $pdbfile, $db_pdbfileid, 0, 0, $updateflag, 0, 0, 0);
      }
      $arr_filelist{$upper_pdbid} = \@file_record;
      $num_all_records++;
    }
  }
  closedir DIR;


=comment reporting subroutine
  foreach my $upper_pdbid (@filelist_new) {
    print "$upper_pdbid:";
    foreach my $element (@{$arr_filelist{$upper_pdbid}}) {
      print "$element, ";
    }
    print "\n";
# print $arr_filelist("$upper_pdbid,short");
  }
=cut


=comment arr_filelist fields definition
    1. name of un-processed coordinate file in PDB format zipped or in another location
    2. name of coordinate file in PDB format in the directory to be processed
    3. existing pdbfileid in database, or new pdbfileid assigned
    4. (Placeholder) Flag to indicate the CD-HIT clustering status for a record
    5. Flag to indicate if a record is a model from maxsprout or not
    6. Flag to indicate if a record is new or existing record
    7. (Placeholder) Flag to indicate the CATH Domall status for a record
    8. (Placeholder) Flag to indicate the CATH DomainList status for a record
    9. (Placeholder) Flag to indicate the GeneOntology status for a record
=cut


#------------------------------------------------------------------------------
# Calculating clusters and update clusters info for existing records
#------------------------------------------------------------------------------
  print "All records found on file system:  $num_all_records\n";
  print "Existing DB records to be updated: $num_existing_records\n";
  print "New records to be copied into DB:  $num_new_records\n";
  die "The database $database_name on server $database_host:$database_port is up-to-date, no further update is needed" unless $num_new_records != 0;

  if(not $use_subset) {
    foreach my $copyfile (qw(clusters50.txt clusters90.txt not_in_clusters.txt)) {
      unlink "$backup_lib_dir/$copyfile";
      copy("$lib_dir/$copyfile", "$backup_lib_dir/$copyfile") or die "Copy failed: $!";
    }
  }
  cdhit_set_clusters("$lib_dir/clusters50.txt","fifty");

=comment DEBUG output procedure
  foreach my $upper_pdbid (@filelist_new) {
    print "$upper_pdbid:";
    foreach my $element (@{$arr_filelist{$upper_pdbid}}) {
      print "$element, ";
    }
    print "\n";
# print $arr_filelist("$upper_pdbid,short");
  }
=cut

  cdhit_set_clusters("$lib_dir/clusters90.txt","ninety");
  cdhit_set_short   ("$lib_dir/not_in_clusters.txt");
  if($use_subset and $subset_size>1000) {
    cath_set_CDF("$lib_dir/CathDomall");
    cath_set_CLF("$lib_dir/CathDomainList");
#   go_set_GAF("$lib_dir/gene_association.goa_pdb.gz");
  }
  print "CD-HIT clustering information for existing records\n";
  print_cluster_info(\@filelist_update);
  print "CD-HIT clustering information for new records\n";
  print_cluster_info(\@filelist_new);

  print "update-progress ===== Updating CD-HIT clustering information in database =====\n";
# $dbh = DBI->connect("dbi:Pg:dbname=$database_name;host=$database_host","$database_user","$database_password") or die $DBI::errstr;
  $dbh = DBI->connect("dbi:Pg:dbname=$database_name","$database_user") or die $DBI::errstr;
# $dbh = DBI->connect("dbi:Pg:dbname=$database_name") or die $DBI::errstr;
  foreach my $upper_pdbid (@filelist_update) {
    my $pdbfileid  = $arr_filelist{$upper_pdbid}->[2];
    my $updateflag = $arr_filelist{$upper_pdbid}->[5];
    my $pdbfile_cluster50_id="";
    my $pdbfile_cluster90_id="";
    my $update_query="";
    foreach my $item (qw(fifty ninety short)) {
      my %arr_filelist_current;
      $update_query="";
      if ($item eq "fifty") {
        %arr_filelist_current=%arr_filelist_fifty;
      } elsif ($item eq "ninety") {
        %arr_filelist_current=%arr_filelist_ninety;
      } elsif ($item eq "short") {
        %arr_filelist_current=%arr_filelist_short;
      } else {
        die "Unexpected value ($item) for update of cluster infomation\n";
      }
      if (exists $arr_filelist_current{$upper_pdbid}) {
        foreach my $chain (@{$arr_filelist_current{$upper_pdbid}}) {
          my $chainid     = $chain->[0];
          my $clusterid   = $chain->[1];
          my $representid = $chain->[2];
          if ($item eq "fifty") {
            $update_query="UPDATE cdhit_chains set cluster50_id=$clusterid, represent50_id=$representid ";
          } elsif ($item eq "ninety") {
            $update_query="UPDATE cdhit_chains set cluster90_id=$clusterid, represent90_id=$representid ";
          } elsif ($item eq "short") {
            $update_query="UPDATE cdhit_chains set cluster50_id=-1, represent50_id=-1, cluster90_id=-1, represent90_id=-1 ";
          }
          $update_query="$update_query where pdbfileid=$pdbfileid and chainid='$chainid';";
          print $update_query."\n";

          $sth = $dbh->prepare($update_query) or die $DBI::errstr;
          $sth->execute() or die $DBI::errstr;
          $sth->finish() or warn $DBI::errstr;

          # Take the first chain's clusterid as the clusterid for the whole pdbfile,
          # assuming CD-Hit program always work with descending order of chain length
          if ($pdbfile_cluster50_id eq "" and $item eq "fifty") {
            $pdbfile_cluster50_id=$clusterid;
          } elsif ($pdbfile_cluster90_id eq "" and $item eq "ninety") {
            $pdbfile_cluster90_id=$clusterid;
          }
        }
      }
    }
    $pdbfile_cluster50_id=-1 if $pdbfile_cluster50_id eq "";
    $pdbfile_cluster90_id=-1 if $pdbfile_cluster90_id eq "";
    $update_query="UPDATE ccdinfo set cluster50_id=$pdbfile_cluster50_id, cluster90_id=$pdbfile_cluster90_id where pdbfileid=$pdbfileid;\n";
    print $update_query."\n";
    $sth = $dbh->prepare($update_query) or die $DBI::errstr;
    $sth->execute() or die $DBI::errstr;
    $sth->finish() or warn $DBI::errstr;
  }
  $dbh->disconnect() or warn $DBI::errstr;
}


#------------------------------------------------------------------------------
# Drop indices and derived tables; calculate new files and copy into DB; re-create indices
#------------------------------------------------------------------------------
print "update-progress ===== Drop indices and derived tables =====\n";
process_sql_file($sql_update_begin) if ($abinitio == 0 and $use_subset == 0);
print "update-progress ===== Process new entries and put into database =====\n";
@filelist_new=@filelist_subset if($use_subset and not $single_mode);
LOOPPDBFILE: foreach my $upper_pdbid (@filelist_new) {
# if {[string equal $upper_pdbid "1ABW"]} {
# } elseif {[string equal $upper_pdbid "1AG0"]} {
# } elseif {[string equal $upper_pdbid "1D1B"]} { set flagflag 1; continue
# } elseif {$flagflag == 0} { continue }
  my $lower_pdbid  = "\L$upper_pdbid";
  my $zipfile           ="NULL";
  my $pdbfile           ="NULL";
  my $modelflag         =0;
  my $updateflag        =0;
  my $cluster_file      ="pdb$lower_pdbid.cluster"; # To be generated, and will contain
  my $AU_molprobity_file="NULL";
  my $AU_contact_file   ="NULL";
  my $BU_header_file    ="NULL";
  my @list_delfile = ($sql_copy_data, "PDBFILE.data", "ASSEMBLY.data", "CAVITY.data", "CDHIT_CHAIN.data", "SYMOP_CHAIN.data", "MOLECULE.data", "RESIDUE.data", "ATOM.data", "NEIGHBOR.data", "ATOMNEIGHBOR.data", "LIGAND_BONDANGLE.data","ION_BONDVALENCE.data","WATER_BONDVALENCE.data");
  if($NEIGHBORHOOD_DEBUG) {@list_delfile = ();}
  if($single_mode) {
    my $source_pdbfile = $ARGV[1];
    if ($source_pdbfile =~ /^.*\/([^\/]+)$/) {
      $pdbfile = $1;
    } else {
      $pdbfile = $source_pdbfile;
    }
    copy($source_pdbfile, "$temporary_dir/$pdbfile") or die "Copy failed: $!";
    open CLUSTEROUT, '>', "$temporary_dir/$cluster_file";
    print CLUSTEROUT "PDBFILE   ";
    format_n_digit($start_pdbfileid, 10);
    print "\n";
    close CLUSTEROUT;
  } else {
    if($use_subset) {
      next unless exists $pdbid_dict{$lower_pdbid};	# Do not process a record that is not specified in the subset file
    }
    next if exists $filelist_obsolete{$upper_pdbid};	# Do not process obsolete record
    next unless exists $arr_filelist{$upper_pdbid};	# Do not process record without an entry in the filesystem
    $zipfile      = $arr_filelist{$upper_pdbid}->[0];
    $pdbfile      = $arr_filelist{$upper_pdbid}->[1];
    # $arr_filelist{$upper_pdbid}->[2] and $arr_filelist{$upper_pdbid}->[3] is going to be used in the procedure generate_cluster_file
    $modelflag    = $arr_filelist{$upper_pdbid}->[4];
    $updateflag   = $arr_filelist{$upper_pdbid}->[5];
    $AU_molprobity_file = "aup$lower_pdbid.ent";
    $AU_contact_file    = "contact$lower_pdbid.ent";
    $BU_header_file     = "pdb$lower_pdbid.header";
    # $arr_filelist{$upper_pdbid}->[6] and $arr_filelist{$upper_pdbid}->[7] is going to be used in the procedure generate_cluster_file
    print "$upper_pdbid: ";
=comment list of tables in neighborhood database
  DROP TABLE atomneighbors;
  DROP TABLE neighbors;
  DROP TABLE atoms;
  DROP TABLE residues;
  DROP TABLE molecules;
  DROP TABLE symop_chains;
  DROP TABLE cdhit_chains;
  DROP TABLE cavities;
  DROP TABLE assemblies;
  DROP TABLE pdbfile;
=cut
    foreach my $delfile (@list_delfile) {
      unlink "$temporary_dir/$delfile";
    }
# break
# set flag            [lindex $arr_filelist($upper_pdbid) 3]
# puts -nonewline "$upper_pdbid==$arr_filelist($upper_pdbid)"
# if {$flag >= 2} {puts -nonewline "++$arr_filelist($upper_pdbid,fifty)"}
# if {$flag==1 || $flag==3} {puts -nonewline "--$arr_filelist($upper_pdbid,short)"}
# puts ""

# Four Files to be generated, to be fed into neighborhood program as input
# 1. $pdbfile            -- copy from either $pdb_entries_dir/pdb1abc.ent.gz, or from $mod_entries_dir/mod1abc.ent
# 2. $cluster_file       -- from sub procedure generate_cluster_file, contains pdbfileid
# 3. $AU_molprobity_file -- copy from $AU_molprobity_dir/aup1abc.ent
# 4. $AU_contact_file    -- copy from $AU_contact_dir/contact1abc.ent
# 5. $BU_header_file     -- copy from $BU_header_dir/pdb1abc.header

# STEP 1: generating $pdbfile
    my $filename    = "NULL";
    my $outfilename = "$temporary_dir/$pdbfile";
    if ($modelflag) {
      $filename = "$mod_entries_dir/$zipfile";
    } else {
      $filename = "$zcat_prog -c $pdb_entries_dir/$zipfile |";
    }
    open ZIPFILE, "$filename" or die "could not open the file: $filename for reading\n";
    open OUTFILE, '>', "$outfilename" or die "could not open $outfilename file for writing\n";
    while (<ZIPFILE>) { print OUTFILE $_; };
    close OUTFILE;
    close ZIPFILE;
    print "COORD... ";

# STEP 2: generating $cluster_file
    generate_cluster_file($upper_pdbid, "$temporary_dir/$cluster_file");
    print "CLUSTERED... ";

# STEP 3,4,5: generating $AU_molprobity_file, $AU_contact_file, and $BU_header_file
    $AU_molprobity_file = generate_other_input_file($AU_molprobity_dir, $AU_molprobity_file, $temporary_dir, "Molprobity");
    $AU_contact_file    = generate_other_input_file($AU_contact_dir, $AU_contact_file, $temporary_dir, "CONTACT");
    $BU_header_file     = generate_other_input_file($BU_header_dir, $BU_header_file, $temporary_dir, "ASSEMBLY");
    print "\n";
  }
  push (@list_delfile, $pdbfile);
  push (@list_delfile, $cluster_file);
  push (@list_delfile, $AU_molprobity_file);
  push (@list_delfile, $AU_contact_file);
  push (@list_delfile, $BU_header_file);
# exit;

# Here are explanation for all parameters
# argv[1]: $temporary_dir       -- directory for all (working directory for all three input files)
# argv[2]: $pdbfile             -- text file that contains PDB coordinate info (in PDB format)
# argv[3]: $cluster_file        -- text file that specify the cluster info     (in keyworded format)
# argv[4]: $AU_molprobity_file  -- text file that specify the molprobity probe info (in ':' delimited format) (calculated by Molprobity probe program)
# argv[5]: $AU_contact_file     -- text file that specify the contact info     (in '|' delimited format) (calculated by CCP4 contact program)
# argv[6]: $BU_header_file      -- header that defines all biological unit related info (with cavity calculated by surflex-dock, and surface area calculated by surface-racer)
  my $exec_line = "$exec_prog $temporary_dir $pdbfile $cluster_file $AU_molprobity_file $AU_contact_file $BU_header_file $MYPDB_NEW";
  print "$exec_line\n";
  if ($NEIGHBORHOOD_DEBUG) {
    system($exec_line) == 0 or die "Could not calculate neighborhood for file $pdbfile\n";
  } else {
    if (system($exec_line)) {
      print STDERR "$upper_pdbid: Could not calculate neighborhood for file $pdbfile\n";
      next;
    }
  }
  process_sql_file("$temporary_dir/$sql_copy_data");
  print "\n";
  foreach my $delfile (@list_delfile) {
    unlink "$temporary_dir/$delfile";
  }
}

unlink $NEIGHBORHOODLOCK if(-e $NEIGHBORHOODLOCK);
exit if($use_subset or $single_mode);
print "update-progress ===== Re-creating indices and derived tables =====\n";
process_sql_file($sql_update_end);
