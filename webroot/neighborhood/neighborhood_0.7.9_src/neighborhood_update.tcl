#!/usr/bin/tclsh
package require Pgtcl

set MYPDB_NEW           "/med2/soroka/MYPDB_NEW";
#set pdb_entries_dir     "/home/dust/neighborhood_2009/test";
set pdb_entries_dir     "$MYPDB_NEW/pdb_entries_new";
set mod_entries_dir     "$MYPDB_NEW/maxsprout_models";
set current_dir         [pwd];
set temporary_dir       "$current_dir/temp_for_neighboorhood";
set gunzip_prog         "/bin/gunzip";
set psql_prog           "/usr/bin/psql";
set database_host       "zenobi.med.virginia.edu";
set database_name       "neighborhood10";
set database_port       "5432";

set pita_local_dir      "$MYPDB_NEW/pita_local";
set surfrace_dir        "$pita_local_dir/surfrace_summary";
set lib_dir             "$MYPDB_NEW/pdb_derived_data";
set backup_lib_dir      "/home/dust/neighborhood_2009/lib";
set exec_dir            "/home/dust/neighborhood_2009/src";
set exec_prog           "$exec_dir/neighborhood";
set sql_dir             "/home/dust/neighborhood_2009/sql";
set sql_create_table    "$sql_dir/createNeighborhoodTables.sql";
set sql_update_begin    "$sql_dir/updateBegin.sql";
set sql_copy_data       "copyNeighborhoodData.sql";
set sql_update_end      "$sql_dir/updateEnd.sql";
set abinitio 0
set start_pdbfileid 0


#------------------------------------------------------------------------------
# subroutines
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
      if {[info exists ARR_FILELIST($upper_pdbid)] && [llength $ARR_FILELIST($upper_pdbid)]==6} {
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
      if {[info exists ARR_FILELIST($upper_pdbid)] && [llength $ARR_FILELIST($upper_pdbid)]==6} {
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

proc process_sql_file { filename } {
  global psql_prog database_host database_port database_name
  set sqlcommand "$psql_prog -h$database_host -p$database_port $database_name < $filename";
  puts $sqlcommand
  if { [catch "exec $sqlcommand" err_code] } {
    puts stderr "SQL command exit abnormally for DB $database_name file $filename\n$err_code"
  }
}

proc print_cluster_info { filelist } {
  global ARR_FILELIST
  set num_undef_pdbfile     0
  set num_defined_pdbfile   0
  set num_clustered_pdbfile 0
  set num_short_pdbfile     0
  set num_clustered_chains  0
  set num_short_chains      0
  foreach pdbentry $filelist {
    set pdbfile_undef 1
    if { [info exists ARR_FILELIST($pdbentry,ninety)] } {
      foreach chain $ARR_FILELIST($pdbentry,ninety) {
        incr num_clustered_chains
      }
      set pdbfile_undef 0
      incr num_clustered_pdbfile
    } elseif { [info exists ARR_FILELIST($pdbentry,short)] } {
      foreach chain $ARR_FILELIST($pdbentry,short) {
        incr num_short_chains
      }
      set pdbfile_undef 0
      incr num_short_pdbfile
    }
    if {$pdbfile_undef} {incr num_undef_pdbfile} else {incr num_defined_pdbfile}
  }
  puts "  PDB file lack clustering info:   $num_undef_pdbfile"
  puts "  PDB file with clustering info:   $num_defined_pdbfile"
  puts "  PDB file contains cluster chain: $num_clustered_pdbfile ($num_clustered_chains chains)"
  puts "  PDB file contains short chain:   $num_short_pdbfile ($num_short_chains chains)"
}


#------------------------------------------------------------------------------
# getting list of existing database records
#------------------------------------------------------------------------------
if { $abinitio } {
  set start_pdbfileid 0
  process_sql_file $sql_create_table
} else {
  set conn [pg_connect -conninfo "port=$database_port host=$database_host dbname=$database_name"]
  puts "Connection successfully established";
# foreach conn_param [pg_conndefaults] {
#   puts -nonewline [lindex $conn_param 1]
#   puts -nonewline ": "
#   puts [lindex $conn_param 4]
# }
  
  set res [pg_exec $conn "SELECT max(pdbfileid) FROM pdbfile "]
  set database_last_pdbfileid [lindex [pg_result $res -getTuple 0] 0]
  if { $database_last_pdbfileid > $start_pdbfileid } {
    set start_pdbfileid $database_last_pdbfileid
    incr start_pdbfileid
  }
  
  set res [pg_exec $conn "SELECT pdbfileid, pdbid FROM pdbfile "]
  set ntups [pg_result $res -numTuples]
  for {set i 0} {$i < $ntups} {incr i} {
    set pdbfileid [lindex [pg_result $res -getTuple $i] 0]
    set pdbid     [lindex [pg_result $res -getTuple $i] 1]
    set upper_pdbid [string toupper $pdbid]
    set ARR_DBRECORD($upper_pdbid) $pdbfileid
  }
  #parray ARR_DBRECORD
  pg_disconnect $conn  
}


#------------------------------------------------------------------------------
# getting list of PDB files on file system
#------------------------------------------------------------------------------
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
set filelist_new ""
set filelist_update ""
foreach zipfile $file_list_fs {
  if {[regexp {(pdb(....)\.ent)} $zipfile junk pdbfile pdbid] && ![regexp {obsolete} $zipfile]} {
    set upper_pdbid [string toupper $pdbid]
    if { [info exists ARR_DBRECORD($upper_pdbid)] } {
      lappend filelist_update $upper_pdbid
      set db_pdbfileid $ARR_DBRECORD($upper_pdbid)
      set updateflag 1
    } else {
      lappend filelist_new $upper_pdbid
      set db_pdbfileid $start_pdbfileid
      set updateflag 0
      incr start_pdbfileid
    }
    set modfile "mod$pdbid.ent"
    if {[file exists "$mod_entries_dir/$modfile"]} {
      set ARR_FILELIST($upper_pdbid) [list $modfile $pdbfile $db_pdbfileid 0 1 $updateflag]
    } else {
      set ARR_FILELIST($upper_pdbid) [list $zipfile $pdbfile $db_pdbfileid 0 0 $updateflag]
    }
  }
}
foreach record $filelist_update {
# puts -nonewline $record 
# puts $ARR_FILELIST($record)
# puts ARR_FILELIST($record,short)
}
# ARR_FILELIST fields definition
# 1. name of un-processed coordinate file in PDB format zipped or in another location
# 2. name of coordinate file in PDB format in the directory to be processed
# 3. existing pdbfileid in database, or new pdbfileid assigned
# 4. (Placeholder) Flag to indicate the CD-HIT clustering status for a record
# 5. Flag to indicate if a record is a model from maxsprout or not
# 6. Flag to indicate if a record is new or existing record


#------------------------------------------------------------------------------
# Calculating clusters and update clusters info for existing records
#------------------------------------------------------------------------------
set num_all_records [llength $file_list_fs]
set num_existing_records [llength $filelist_update]
set num_new_records [llength $filelist_new]
puts "All records found on file system:  $num_all_records"
puts "Existing DB records to be updated: $num_existing_records"
puts "New records to be copied into DB:  $num_new_records"
if { [llength $filelist_new] == 0 } {
  puts "The database $database_name on server $database_host:$database_port is up-to-date, no further update is needed"
  exit 0;
}

foreach copyfile [list clusters50.txt clusters90.txt not_in_clusters.txt] {
  file delete $backup_lib_dir/$copyfile
  file copy $lib_dir/$copyfile $backup_lib_dir/$copyfile
}
cdhit_set_clusters "$lib_dir/clusters50.txt" "fifty"
cdhit_set_clusters "$lib_dir/clusters90.txt" "ninety"
cdhit_set_short    "$lib_dir/not_in_clusters.txt"
puts "CD-HIT clustering information for existing records"
print_cluster_info $filelist_update
puts "CD-HIT clustering information for new records"
print_cluster_info $filelist_new

puts "update-progress ===== Updating CD-HIT clustering information in database ====="
set conn [pg_connect -conninfo "port=$database_port host=$database_host dbname=$database_name"]
foreach pdbentry $filelist_update {
  set pdbfileid  [lindex $ARR_FILELIST($pdbentry) 2]
  set updateflag [lindex $ARR_FILELIST($pdbentry) 5]
  foreach item { [list fifty ninety short] } {
    if { [info exists ARR_FILELIST($pdbentry,$item)] } {
      foreach chain $ARR_FILELIST($pdbentry,$item) {
        set chainid     [lindex $chain 0]
        set clusterid   [lindex $chain 1]
        set representid [lindex $chain 2]
        if { [string equal $item fifty] } {
          set update_query "UPDATE cdhit_chains set cluster50_id=$clusterid, represent50_id=$representid "
        } elseif { [string equal $item ninety] } {
          set update_query "UPDATE cdhit_chains set cluster90_id=$clusterid, represent90_id=$representid "
        } else {
          set update_query "UPDATE cdhit_chains set cluster50_id=-1, represent50_id=-1, cluster90_id=-1, represent90_id=-1 "
        }
        set update_query "$update_query where pdbfileid=$pdbfileid and chainid='$chainid' "
        puts $update_query
#       set res [pg_exec $conn $update_query]
      }
    }
  }
}
pg_disconnect $conn  
exit 1;


#------------------------------------------------------------------------------
# Drop indices and derived tables; calculate new files and copy into DB; re-create indices
#------------------------------------------------------------------------------
puts "update-progress ===== Drop indices and derived tables ====="
process_sql_file $sql_update_begin
puts "update-progress ===== Process new entries and put into database ====="
foreach pdbentry $filelist_new {
# if {[string equal $pdbentry "1ABW"]} {
# } elseif {[string equal $pdbentry "1AG0"]} {
# } elseif {[string equal $pdbentry "1D1B"]} { set flagflag 1; continue
# } elseif {$flagflag == 0} { continue }
  puts $pdbentry
  set zipfile         [lindex $ARR_FILELIST($pdbentry) 0]
  set pdbfile         [lindex $ARR_FILELIST($pdbentry) 1]
  set modelflag       [lindex $ARR_FILELIST($pdbentry) 4]
  set updateflag      [lindex $ARR_FILELIST($pdbentry) 5]
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
#   exit 1
    continue
  }
  exit 1

  process_sql_file $temporary_dir/$sql_copy_data
  foreach delfile [list $pdbfile $cluster_file $surface_file $sql_copy_data PDBFILE.data ASSEMBLY.data CAVITY.data \
                        CDHIT_CHAIN.data SYMOP_CHAIN.data RESIDUE.data ATOM.data NEIGHBOR.data ATOMNEIGHBOR.data] {
    file delete $temporary_dir/$delfile
  }
}
puts "update-progress ===== Re-creating indices and derived tables ====="
process_sql_file $sql_update_end
