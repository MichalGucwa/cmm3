#!/usr/bin/tclsh
set DIR_PDBDATA "/med/soroka/MYPDB_NEW/pdb_entries"
set DIR_OUTDATA "$env(HOME)/neighborhood_data"
set DIR_ENTRY_DATA $DIR_OUTDATA/pdb_entries
set DIR_PROC_DATA $DIR_OUTDATA/$::tcl_platform(user)[clock format [clock seconds] -format %m%d%y]
set gunzip_prog "/bin/gunzip";
set lsqkab_prog "/home/dust/xtalprogs/ccp4-6.0.1/bin/lsqkab"

proc error_out { msg } {
  puts stderr "FATAL ERROR: $msg\n"
  exit
}

proc warning_out { msg } {
  puts stderr "WARNING: $msg\n"
}

proc convert_serial_term { num } {
  switch $num {
    1       { return first }
    2       { return second }
    3       { return third }
    default { return ${num}th }
  }
}

puts "\nUSAGE: neighborhood_lsqkab.tcl QUERY_OUTPUT_TABLE \[POS_ALIGN=1-2-3-4\] \[INPUT_PDBFILE\]\n"
puts "      \
      POS_ALIGN is a dash-delimited list of positions that will be used for LSQKAB. \n      \
      INPUT_PDBFILE is the coordinate file used as reference structure when doing \n      \
      LSQKAB. In case no input coordinate provided, LSQKAB will use the first \n      \
      structure in the query output as reference structure\n"

# STEP I: Assign default value for all parameters
if {$argc<1 || $argc>3} { error_out "Wrong number of arguments, please check command line" }
set QUERY_OUTPUT_TABLE [lindex $argv 0]
set POS_ALIGN "1-2-3-4"
set INPUT_PDBFILE ""
if {$argc>=2} {set POS_ALIGN [lindex $argv 1]}
if {$argc==3} {set INPUT_PDBFILE [lindex $argv 2]}
if {![file exists $QUERY_OUTPUT_TABLE]} { error_out "Cannot locate database query output file" }

# STEP II: Calculate list for QUERY_OUTPUT_TABLE
set fd [open $QUERY_OUTPUT_TABLE r]
set header_found  0
set header_length 5
set number_nodes  2
set records_hitlist ""
while {[gets $fd line] != -1} {
  set neighbors_line [split $line "|"]
  set record_length [llength $neighbors_line]
  if {$record_length < 5} {continue}    ;# skip lines where not enough field are found
  if {$header_found == 0} {
    set header_found 1
    set header_length $record_length
    if {[expr $header_length % 2] != 1} {
      error_out "Please ensure query output fields fit into the following pattern: \n\
      pdbid | chainid | resseq | chainid | resseq ..."
    }
    set number_nodes [expr ($header_length-1)/2]
  } elseif {$record_length != $header_length} {
    error_out "Number of fields in record($record_length) do not match number of fields in header($header_length)"
  } else {
    set neighbors_record ""
    for {set i 0} {$i < $header_length} {incr i} {
      lappend neighbors_record [string trim [lindex $neighbors_line $i]]
    }
    lappend records_hitlist $neighbors_record
    # puts "[llength $neighbors_record]: $neighbors_record"
  }
}
close $fd
set pdbfiles_hitlist ""
set number_pdbfiles 0
set number_records [llength $records_hitlist]
for {set i 0} {$i < $number_records} {incr i} {
  set neighbors_record [lindex $records_hitlist $i]
  set record_pdbid [lindex $neighbors_record 0]
  set pdbfile_found 0
  for {set j [expr $number_pdbfiles-1]} {$j >= 0} {incr j -1} {
    set pdbfile_hit [lindex $pdbfiles_hitlist $j]
    if {[string equal $record_pdbid [lindex $pdbfile_hit 0]]} {
      set pdbfile_found 1
      set number_occurence [expr [lindex $pdbfile_hit 1]+1]
      break
    }
  }
  if {$pdbfile_found} {
    set pdbfiles_hitlist [lreplace $pdbfiles_hitlist $j $j [list $record_pdbid $number_occurence]]
  } else {
    lappend pdbfiles_hitlist [list $record_pdbid 1]
    incr number_pdbfiles
  }
}
foreach pdbfile_hit $pdbfiles_hitlist {
  set record_pdbid [lindex $pdbfile_hit 0]
  set record_count [lindex $pdbfile_hit 1]
  puts "> pdbid: $record_pdbid, number of hits: $record_count"
}

# STEP III: Retrieve and validate the positions to be aligned for POS_ALIGN
if {$argc<2} {
  if {$number_nodes == 2} { set POS_ALIGN "1-2"
  } elseif {$number_nodes == 3} { set POS_ALIGN "1-2-3"}
}
set positions_line [split $POS_ALIGN "-"]
set number_positions [llength $positions_line]
if {$number_positions < 2} { error_out "Please assign at least 2 positions for LSQKAB" }
if {$number_positions > $number_nodes} { error_out "The maximal allowed positions for LSQKAB is $number_nodes" }
set prev_pos 0
foreach pos $positions_line {
  if {![string is integer $pos]} { error_out "Invalid format for POS_ALIGN($pos), please use integer" }
  if {$pos < 1 || $pos > $number_nodes} { error_out "Invalid range for POS_ALIGN($pos), outside (1..$number_nodes)" }
  if {$pos <= $prev_pos} { error_out "Invalid order for POS_ALIGN, please use only ascending order" }
  set prev_pos $pos
}
puts "> number_nodes: $number_nodes,  number_positions: $number_positions"
puts "> number_records: $number_records, number_pdbfiles: $number_pdbfiles"

# STEP IV: copy and unzip all PDB files from archive, BTW, create processing dir
if {![file exists $DIR_PDBDATA]} { error_out "Directory for retrieving PDB file($DIR_PDBDATA) cannot be found" }
if {![file isdir  $DIR_PDBDATA]} { error_out "DIR_PDBDATA($DIR_PDBDATA) is not a directory" }
if { [file exists $DIR_OUTDATA] && ![file isdir $DIR_OUTDATA]} { file delete $DIR_OUTDATA }
if {![file exists $DIR_OUTDATA]} { file mkdir $DIR_OUTDATA }
if { [file exists $DIR_ENTRY_DATA] && ![file isdir $DIR_ENTRY_DATA]} { file delete $DIR_ENTRY_DATA }
if {![file exists $DIR_ENTRY_DATA]} { file mkdir $DIR_ENTRY_DATA }
for {set i 0} {$i < $number_pdbfiles} {incr i} {
  set pdbfile_hit  [lindex $pdbfiles_hitlist $i]
  set record_pdbid [lindex $pdbfile_hit 0]
  set pdbfile_name "pdb${record_pdbid}.ent.Z"
  set pdbfile_ori  "$DIR_PDBDATA/$pdbfile_name"
  set pdbfile_des  "$DIR_ENTRY_DATA/pdb${record_pdbid}.ent"
  if {[file exists $pdbfile_des]} {continue}
  if {![file exists $pdbfile_ori]} { error_out "Cannot locate pdbfile $pdbfile_ori in local mirror" }
  if { [catch {file copy $pdbfile_ori $DIR_ENTRY_DATA} err_code] } { error_out "Cannot copy file $pdbfile_ori" }
  if { [catch {exec $gunzip_prog "$DIR_ENTRY_DATA/$pdbfile_name"} err_code] } { error_out "Unzip fail for $pdbfile_ori" }
  puts "> Copying file $pdbfile_name ..."
}
set i 1
set proc_dir $DIR_PROC_DATA-$i
while {[file exists $proc_dir]} {
  incr i
  set proc_dir $DIR_PROC_DATA-$i
}
file mkdir [set DIR_PROC_DATA     $proc_dir]
file mkdir [set DIR_PROC_FRAGMENT $DIR_PROC_DATA/fragment]
file mkdir [set DIR_PROC_LSQ_INS  $DIR_PROC_DATA/lsq_instruction]
file mkdir [set DIR_PROC_LSQ_LOG  $DIR_PROC_DATA/lsq_log]
file mkdir [set DIR_PROC_LSQ_RES  $DIR_PROC_DATA/lsq_result]

# STEP V to VIII: For each hit, perform scan and parse pdb file
set prev_pdbid ""
set list_fixed_found 0
for {set i 0} {$i < $number_records} {incr i} {
  set neighbors_record [lindex $records_hitlist $i]
  set record_pdbid [lindex $neighbors_record 0]
  set pdbfile_name pdb${record_pdbid}.ent
# STEP V: For each hit, perform scan and parse pdb file whenever encountering new pdbid
  if {![string equal $prev_pdbid $record_pdbid]} {
    if {![file exists $DIR_ENTRY_DATA/$pdbfile_name]} { error_out "Cannot locate pdbfile $pdbfile_name" }
    set fdin  [open $DIR_ENTRY_DATA/$pdbfile_name r]
    if {[info exists pdbfile_atomlines]} { unset pdbfile_atomlines }
    set pdbfile_headerlines ""
    while {[gets $fdin line] != -1} {
      set keyword [string range $line 0 4]
      if {[string equal $keyword "ATOM "] || [string equal $keyword "HETAT"]} {
        # set resname [string range $line 17 19]
        set chain  [string index $line 21]
        if {[string equal $chain " "]} { set chain "EMPTY" }
        set resseq [string trimleft [string range $line 22 25]]
        lappend pdbfile_atomlines($resseq,$chain) $line
      } elseif {[regexp {^(CRYST|ORIGX|SCALE)} $keyword]} {
        lappend pdbfile_headerlines $line
      }
    }
    close $fdin
    set part_number 1
  }

# STEP VI: For each hit, create small fragments of PDB file
  while {[file exists $DIR_PROC_FRAGMENT/${pdbfile_name}.$part_number]} { incr part_number }
  set fdout [open $DIR_PROC_FRAGMENT/${pdbfile_name}.$part_number w]
  puts -nonewline "> Scanning file $pdbfile_name for the [convert_serial_term $part_number] time ..."
  foreach headerline $pdbfile_headerlines { puts $fdout $headerline }
  for {set j 1} {$j <= $number_nodes} {incr j} {
    set record_chain  [lindex $neighbors_record [expr $j*2-1]]
    set record_resseq [lindex $neighbors_record [expr $j*2]]
    if {[string equal $record_chain ""]} { set record_chain "EMPTY" }
    if {[info exists pdbfile_atomlines($record_resseq,$record_chain)]} {
      foreach line $pdbfile_atomlines($record_resseq,$record_chain) { puts $fdout $line }
    } else {
      error_out "The residue $record_chain$record_resseq cannot be located in pdbfile $record_pdbid"
    }
  }
  close $fdout

# STEP VII: For each hit * #combination, export LSQKAB instruction based on all positions in $positions_line
  if {$list_fixed_found == 0} {
    set list_fixed ""
    set file_fixed ""
    if {[string equal $INPUT_PDBFILE ""]} {
      set file_fixed $DIR_PROC_FRAGMENT/${pdbfile_name}.$part_number
      foreach pos $positions_line {
        set record_resseq [lindex $neighbors_record [expr $pos*2]]
        lappend list_fixed $record_resseq
      }
    } else {
      # assign fixed positions from keyworded input
    }
    set list_fixed_found 1
  }
  set list_moved ""
  foreach pos $positions_line {
    set record_resseq [lindex $neighbors_record [expr $pos*2]]
    lappend list_moved $record_resseq
  }
  set combination_id 0
  set file_ins $DIR_PROC_LSQ_INS/${pdbfile_name}.${part_number}.${combination_id}.sh
  set file_log $DIR_PROC_LSQ_LOG/${pdbfile_name}.${part_number}.$combination_id
  set fdins [open $file_ins w]
  puts $fdins "#!/bin/sh\n"
  puts $fdins "$lsqkab_prog xyzinm $DIR_PROC_FRAGMENT/${pdbfile_name}.$part_number \
                            xyzinf $file_fixed \
                            xyzout $DIR_PROC_LSQ_RES/${pdbfile_name}.${part_number}.$combination_id \
                            &> $file_log << END-lsqkab"
  puts $fdins "title \[No title given\]"
  for {set j 0} {$j < $number_positions} {incr j} {
    set res_fixed [lindex $list_fixed $j]
    set res_moved [lindex $list_moved $j]
    puts $fdins "fit res ALL $res_moved to $res_moved"
    puts $fdins "match $res_fixed to $res_fixed"
  }
  puts $fdins "output -\n    xyz\nend"
  puts $fdins "END-lsqkab"
  close $fdins

# STEP VIII: For each hit * #combination, perform 1 LSQKAB
  if { [catch {exec chmod 755 $file_ins} err_code] } { error_out "Fail changing mode for script $file_ins" }
  if { [catch {exec $file_ins} err_code] } { error_out "Fail executing script $file_ins" }
  set fdlog [open $file_log r]
  while {[gets $fdlog line] != -1} {
    if { [string equal "RMS" [string range [string trimleft $line] 0 2]] } {
      if {[regexp {RMS     XYZ DISPLACEMENT =\s+([0-9.]+)} $line junk rmsd_value]} {
        puts "\t$pdbfile_name.$part_number LSQKAB RMSD value is $rmsd_value"
        break
      }
    }
  }
  close $fdlog

  set prev_pdbid $record_pdbid
}

puts "> All entries superimposition finished sccessfully."
