#!/usr/bin/tclsh

set MYPDB_NEW           "/med/soroka/MYPDB_NEW";
set pdb_entries_dir     "/home/dust/neighborhood_2006/test";
#set pdb_entries_dir     "/med/soroka/MYPDB_NEW/pdb_entries";
set mod_entries_dir     "/med/soroka/MYPDB_NEW/maxsprout_models";
set current_dir         [pwd];
set temporary_dir       "$current_dir/temp_for_neighboorhood";
set gunzip_prog         "/bin/gunzip";
set psql_prog           "/usr/bin/psql";
set database_name       "-p5532 neighborhood";

set pita_local_dir      "$MYPDB_NEW/pita_local";
set surfrace_dir        "$pita_local_dir/surfrace_summary";
set lib_dir             "$MYPDB_NEW/pdb_derived_data";
set backup_lib_dir      "/home/dust/neighborhood_2006/lib";
set exec_dir            "/home/dust/neighborhood_2006/src";
set exec_prog           "$exec_dir/neighborhood";
set sql_dir             "/home/dust/neighborhood_2006/sql";
set sql_create_table    "$sql_dir/createNeighborhoodTables.sql";
set sql_copy_data       "copyNeighborhoodData.sql";
set abinitio 1;
set start_pdbfileid 42000

#------------------------------------------------------------------------------
# Parameters for using local directory instead of soroka one by overriding certain default values
set MYPDB_NEW           "/db/soroka/MYPDB_NEW";
#set pdb_entries_dir     "/db/soroka/MYPDB_NEW/pdb_entries";
set mod_entries_dir     "/db/soroka/MYPDB_NEW/maxsprout_models";
set pita_local_dir      "$MYPDB_NEW/pita_local";
set surfrace_dir        "$pita_local_dir/surfrace_summary";

#------------------------------------------------------------------------------
proc cdhit_set_clusters { filename field } {
  global ARR_FILELIST
  puts "Setting cluster information for $filename"
  if {[string equal $field "fifty"]} {set first_run 1} else {set first_run 0}
  set error_detected 0
  set fd [open $filename r]
  while {[gets $fd line] != -1} {
    if {[regexp {^(\d+)\s+(\d+)\s+(\w\w\w\w):(\w)$} $line junk clusterid representid pdbid chainid]} {
      # puts "$clusterid $representid $pdbid $chainid"
    } elseif {[regexp {^(\d+)\s+(\d+)\s+(\w\w\w\w):([a-z])([a-z])$} $line junk clusterid representid pdbid chainid1 chainid2]} {
      if {[string equal $chainid1 $chainid2]} {set chainid $chainid1} else {set error_detected 1}
    } else {
      set error_detected 1
    }
    if {$error_detected} {
      puts stderr "ERROR: \"$line\" cannot be recognized"
      exit 0;
    } else {
      set upper_pdbid [string toupper $pdbid]
      if {[info exists ARR_FILELIST($upper_pdbid)] && [llength $ARR_FILELIST($upper_pdbid)]==5} {
        # set flag [lindex $ARR_FILELIST($upper_pdbid) 3]
        set ARR_FILELIST($upper_pdbid) [lreplace $ARR_FILELIST($upper_pdbid) 3 3 2]
        lappend ARR_FILELIST($upper_pdbid,$field) [list $chainid $clusterid $representid]
      }
    }
  }
  close $fd
}

proc cdhit_set_short { filename } {
  global ARR_FILELIST
  set error_detected 0
  set fd [open $filename r]
  while {[gets $fd line] != -1} {
    if {[regexp {^(\w\w\w\w):(\S)$} $line junk pdbid chainid]} {
    } elseif {[regexp {^(\w\w\w\w):$} $line junk pdbid]} {
      set chainid "_"
    } else {
      set error_detected 1
    }
    if {$error_detected} {
      puts stderr "ERROR: \"$line\" cannot be recognized"
      exit 0;
    } else {
      set upper_pdbid [string toupper $pdbid]
      if {[info exists ARR_FILELIST($upper_pdbid)] && [llength $ARR_FILELIST($upper_pdbid)]==5} {
        set flag [lindex $ARR_FILELIST($upper_pdbid) 3]
        if {$flag==0 || $flag==2} {incr flag}
        set ARR_FILELIST($upper_pdbid) [lreplace $ARR_FILELIST($upper_pdbid) 3 3 $flag]
        lappend ARR_FILELIST($upper_pdbid,short) [list $chainid -1 -1]
      }
    }
  }
  close $fd
}

proc format_six_digit { channel figure {newline 0} } {
  set numlen [string length $figure]
  for {set i $numlen} {$i<6} {incr i} {puts -nonewline $channel " "}
  if {$newline} {
    puts $channel $figure
  } else {
    puts -nonewline $channel $figure
  }
}

proc generate_cluster_file { pdbentry filename } {
  global ARR_FILELIST
  set start_pdbfileid [lindex $ARR_FILELIST($pdbentry) 2]
  set flag            [lindex $ARR_FILELIST($pdbentry) 3]
  set fd [open $filename w]
  puts -nonewline $fd "PDBFILE "
  format_six_digit $fd $start_pdbfileid 1
  if {$flag >= 2} {
    foreach chain $ARR_FILELIST($pdbentry,ninety) {
      set chainid     [lindex $chain 0]
      set clusterid   [lindex $chain 1]
      set representid [lindex $chain 2]
      puts -nonewline $fd "CLUST90 "
      puts -nonewline $fd "$chainid "
      format_six_digit $fd $clusterid
      format_six_digit $fd $representid 1
    }
    foreach chain $ARR_FILELIST($pdbentry,fifty) {
      set chainid     [lindex $chain 0]
      set clusterid   [lindex $chain 1]
      set representid [lindex $chain 2]
      puts -nonewline $fd "CLUST50 "
      puts -nonewline $fd "$chainid "
      format_six_digit $fd $clusterid
      format_six_digit $fd $representid 1
    }
  }
  if {$flag==1 || $flag==3} {
    foreach chain $ARR_FILELIST($pdbentry,short) {
      set chainid     [lindex $chain 0]
      puts -nonewline $fd "SHORT   "
      puts $fd "$chainid "
    }
  }
  close $fd
}

#------------------------------------------------------------------------------

if { $abinitio } {
  set sqlcommand "$psql_prog $database_name < $sql_create_table";
  puts $sqlcommand
  if { [catch "exec $sqlcommand" err_code] } {
    puts stderr "SQL command exit abnormally for DB $database_name file $sql_create_table\n$err_code"
  }
}

if { ![file exists $pdb_entries_dir] || ![file isdir $pdb_entries_dir]} {
  puts stderr "Directory $pdb_entries_dir does not exists";
  exit 0;
}

if { ![file exists $mod_entries_dir] || ![file isdir $mod_entries_dir]} {
  puts stderr "Directory $mod_entries_dir does not exists";
  exit 0;
}

if { [file exists $temporary_dir] && ![file isdir $temporary_dir] } {
  puts stderr "Please remove file $temporary_dir before you can proceed";
  exit 0;
} elseif { ![file exists $temporary_dir] } {
  file mkdir $temporary_dir
}

set file_list_fs [exec ls $pdb_entries_dir]
#set ARR_FILELIST array()
set ind_filelist ""
foreach zipfile $file_list_fs {
  if {[regexp {(pdb(....)\.ent)} $zipfile junk pdbfile pdbid] && ![regexp {obsolete} $zipfile]} {
    set upper_pdbid [string toupper $pdbid]
    lappend ind_filelist $upper_pdbid
    set modfile "mod$pdbid.ent"
    if {[file exists "$mod_entries_dir/$modfile"]} {
      set ARR_FILELIST($upper_pdbid) [list $modfile $pdbfile $start_pdbfileid 0 1]
    } else {
      set ARR_FILELIST($upper_pdbid) [list $zipfile $pdbfile $start_pdbfileid 0 0]
    }
    incr start_pdbfileid
  }
}
foreach copyfile [list clusters50.txt clusters90.txt not_in_clusters.txt] {
  file delete $backup_lib_dir/$copyfile
  file copy $lib_dir/$copyfile $backup_lib_dir/$copyfile
}
cdhit_set_clusters "$lib_dir/clusters50.txt" "fifty"
cdhit_set_clusters "$lib_dir/clusters90.txt" "ninety"
cdhit_set_short    "$lib_dir/not_in_clusters.txt"

foreach pdbentry $ind_filelist {
  set zipfile         [lindex $ARR_FILELIST($pdbentry) 0]
  set pdbfile         [lindex $ARR_FILELIST($pdbentry) 1]
  set modelflag       [lindex $ARR_FILELIST($pdbentry) 4]
  set cluster_file    $pdbentry.cluster
  set surface_file    $pdbentry.surface
  foreach delfile [list $pdbfile $cluster_file $surface_file $sql_copy_data PDBFILE.data ASSEMBLY.data CAVITY.data \
                        CDHIT_CHAIN.data SYMOP_CHAIN.data RESIDUE.data ATOM.data NEIGHBOR.data ATOMNEIGHBOR.data] {
    file delete $temporary_dir/$delfile
  }
  generate_cluster_file $pdbentry $temporary_dir/$cluster_file
# break
# set flag            [lindex $ARR_FILELIST($pdbentry) 3]
# puts -nonewline "$pdbentry==$ARR_FILELIST($pdbentry)"
# if {$flag >= 2} {puts -nonewline "++$ARR_FILELIST($pdbentry,fifty)"}
# if {$flag==1 || $flag==3} {puts -nonewline "--$ARR_FILELIST($pdbentry,short)"}
# puts ""

  if {$modelflag} {
    if { [catch {file copy $mod_entries_dir/$zipfile $temporary_dir/$pdbfile} err_code] } {
      puts stderr "Could not copy file $zipfile\n$err_code"
      continue
    }
  } else {
    if { [catch {file copy $pdb_entries_dir/$zipfile $temporary_dir} err_code] } {
      puts stderr "Could not copy file $zipfile\n$err_code"
      continue
    }
    if { [catch {exec $gunzip_prog $temporary_dir/$zipfile} err_code] } {
      puts stderr "Could not unzip file $zipfile\n$err_code"
      continue
    }
  }
  set surface_file_from "$surfrace_dir/pdb[string tolower $pdbentry].surf"
  if { [catch {file copy $surface_file_from $temporary_dir/$surface_file} err_code] } {
    puts stderr "Could not copy file $surface_file_from\n$err_code"
    continue
  }
# Here are explanation for all parameters
# argv[1]: $temporary_dir       -- directory for all (working directory for all three input files)
# argv[2]: $pdbfile             -- text file that contains PDB coordinate info (in PDB format)
# argv[3]: $cluster_file        -- text file that specify the cluster info     (in keyworded format)
# argv[4]: $surface_file        -- text file that specify the surface info     (in keyworded format)
# argv[5]: $pita_local_dir      -- directory where all surface information are stored
  if { [catch {exec $exec_prog $temporary_dir $pdbfile $cluster_file $surface_file $pita_local_dir} err_code] } {
    puts stderr "Could not calculate neighborhood for file $pdbfile\n$err_code"
    continue
  }

  set sqlcommand "$psql_prog $database_name < $temporary_dir/$sql_copy_data";
  puts $sqlcommand
  if { [catch "exec $sqlcommand" err_code] } {
    puts stderr "SQL command exit abnormally for DB $database_name file $pdbfile\n$err_code"
    continue
  }
  foreach delfile [list $pdbfile $cluster_file $surface_file $sql_copy_data PDBFILE.data ASSEMBLY.data CAVITY.data \
                        CDHIT_CHAIN.data SYMOP_CHAIN.data RESIDUE.data ATOM.data NEIGHBOR.data ATOMNEIGHBOR.data] {
    file delete $temporary_dir/$delfile
  }
}
