#!/usr/bin/tclsh
set DIR_PDBDATA "/med/soroka/MYPDB_NEW/pdb_entries"
set DIR_OUTDATA "$env(HOME)/neighborhood_data"
set DIR_ENTRY_DATA $DIR_OUTDATA/pdb_entries
set DIR_PROC_DATA $DIR_OUTDATA/$::tcl_platform(user)[clock format [clock seconds] -format %m%d%y]
set fdout stdout
set temp_table_created 0

proc error_out { msg } {
  puts stderr "FATAL ERROR: $msg\n"
  exit
}

puts "\n--USAGE: neighborhood_query.tcl KEYWORDED_INPUT_FILE \[IS_PRODUCTIVE=0\] \[INPUT_PDBFILE\]"
puts "\n--  \
      IS_PRODUCTIVE flag indicates whether this query is for testing (interested  \n--	\
      first in number of hits), or for result analysis (need further examination).\n--	\
      Testing run can be ten times faster than an analytical run, thus at least   \n--	\
      one test run is strongly recommended before trying any analytical run.    \n\n--	\
      INPUT_PDBFILE is the coordinate file used as reference structure when doing \n--	\
      LSQKAB. In case no input coordinate provided, LSQKAB will use the first     \n--	\
      structure in the query output as reference structure\n"

# STEP I: Assign default value for all parameters
if {$argc<1 || $argc>3} { error_out "Wrong number of arguments, please check command line" }
set KEYWORDED_INPUT_FILE [lindex $argv 0]
set IS_PRODUCTIVE 0
set INPUT_PDBFILE ""
if {$argc>=2} {set IS_PRODUCTIVE [lindex $argv 1]}
if {$argc==3} {set INPUT_PDBFILE [lindex $argv 2]}
if {![file exists $KEYWORDED_INPUT_FILE]} { error_out "Cannot locate file 'KEYWORDED_INPUT_FILE'." }

# STEP II: Calculate list for QUERY_OUTPUT_TABLE
set list_formal_nodes ""
set list_formal_links ""
set residueid_guard   1
set fd [open $KEYWORDED_INPUT_FILE r]
while {[gets $fd line] != -1} {
  if {![regexp {^\s*(#|$)} $line]} {
    set keyword [string toupper [string range $line 0 6]]
    set parameter_line [split [string range $line 8 end]]
    set parameter_list ""
    foreach parameter $parameter_line {
      lappend parameter_list [string tolower [string trim $parameter]]
    }
    switch $keyword {
      RESIDUE   {
        if {[llength $parameter_list] < 2} { error_out "RESIDUE: minimal # of parameters is 2" }
        set residueid [lindex $parameter_list 0]
        if {![string is integer $residueid]} { error_out "RESIDUE: identifier need to be integer" }
        if { $residueid!=$residueid_guard } { error_out "RESIDUE: id has to sequentially start from 1" }
        lappend list_formal_nodes $parameter_list
        incr residueid_guard
      }
      CONTACT   -
      CONNECT   -
      DISTANT   {
        if {[llength $parameter_list] != 2} { error_out "$keyword: # of parameters has to be 2" }
        set residueid_a [lindex $parameter_list 0]
        set residueid_b [lindex $parameter_list 1]
        if {![string is integer $residueid_a] || ![string is integer $residueid_b]} { error_out "$keyword: identifier need to be integer" }
        if { $residueid_a==$residueid_b } { error_out "$keyword: Invalid id pair, node cannot $keyword to itself" }
        if {[string equal $keyword CONNECT]} { set type_interaction 1
        } elseif {[string equal $keyword DISTANT]} { set type_interaction 2
        } else { set type_interaction 0 }
        lappend list_formal_links [list $type_interaction $residueid_a $residueid_b]
      }
      PDBFILE   {}
      LSQ_POS   {}
      LSQ_FIX   {}
    }
  }
}
close $fd
set number_nodes [expr $residueid_guard-1]

# STEP III: Setting array for nodes. 
# structure for arr_formal_nodes
# {name,        -- list of residue 3-letter code
#  text,        -- name for typical link
#  linknum,     -- link number for typical link (used in conjunction with linkend)
#  linkend,     -- link end for typical link (used in conjunction with linknum)
#  link,        -- list of uni-directinoal links
#  link2}       -- list of all links
set cluster_list_1 "" 
set cluster_list_2 ""
foreach node $list_formal_nodes {
  set residueid [lindex $node 0]
  set residuenames [lrange $node 1 end]
  set arr_formal_nodes($residueid,name) $residuenames
  set arr_formal_nodes($residueid,link) ""
  set arr_formal_nodes($residueid,link2) ""
  if {[llength $cluster_list_2]==0} { lappend cluster_list_2 $residueid
  } else { lappend cluster_list_1 $residueid }
}
foreach link $list_formal_links {
  set residueid_a [lindex $link 1]
  set residueid_b [lindex $link 2]
  if {![info exists arr_formal_nodes($residueid_a,name)]} { error_out "Cannot locate node #$residueid_a in residue list" }
  if {![info exists arr_formal_nodes($residueid_b,name)]} { error_out "Cannot locate node #$residueid_b in residue list" }
  lappend arr_formal_nodes($residueid_a,link2) $residueid_b
  lappend arr_formal_nodes($residueid_b,link2) $residueid_a
  if {$residueid_a > $residueid_b} {
    lappend arr_formal_nodes($residueid_b,link) $residueid_a
  } elseif {$residueid_a < $residueid_b} {
    lappend arr_formal_nodes($residueid_a,link) $residueid_b
  }
}

# STEP IV: procedures to create query fragments
proc get_table_name_info {table_str} {
  set table_str [string tolower $table_str]
  if {[string equal $table_str "asparagine"]} {return "asn"}
  if {[string equal $table_str "glutamine"]}  {return "gln"}
  set table_str_3 [string range $table_str 0 2] 
  switch $table_str_3 {
    gly {return $table_str_3} ala {return $table_str_3} val {return $table_str_3} leu {return $table_str_3}
    ile {return $table_str_3} ser {return $table_str_3} thr {return $table_str_3} cys {return $table_str_3}
    met {return $table_str_3} pro {return $table_str_3} asp {return $table_str_3} asn {return $table_str_3}
    glu {return $table_str_3} gln {return $table_str_3} lys {return $table_str_3} arg {return $table_str_3}
    his {return $table_str_3} phe {return $table_str_3} tyr {return $table_str_3} trp {return $table_str_3}
    dna {return $table_str_3} wat {return $table_str_3} ion {return $table_str_3} lig {return $table_str_3}
  }
  if {[string length $table_str] >= 5} {
    set table_str_5 [string range $table_str 0 4] 
    switch $table_str_3 {
      isole   {return "ile"}
      trypt   {return "trp"}
      default {return "null" }
    }
  } else {
    return "null"
  }
}

proc get_table_type_num {table_str_3} {
  switch $table_str_3 {
    gly {set restype  1} ala {set restype  3} val {set restype  5} leu {set restype  7}
    ile {set restype  9} ser {set restype 11} thr {set restype 13} cys {set restype 15}
    met {set restype 17} pro {set restype 19} asp {set restype 21} asn {set restype 23}
    glu {set restype 25} gln {set restype 27} lys {set restype 29} arg {set restype 31}
    his {set restype 33} phe {set restype 35} tyr {set restype 37} trp {set restype 39}
    dna {set restype 42} wat {set restype 43} ion {set restype 44} lig {set restype 48}
    default {set restype 48}
  }
  return $restype
}

proc get_table_type_txt {table_str_3} {
  switch $table_str_3 {
    gly {set restype "01"} ala {set restype "03"} val {set restype "05"} leu {set restype "07"}
    ile {set restype "09"} ser {set restype "11"} thr {set restype "13"} cys {set restype "15"}
    met {set restype "17"} pro {set restype "19"} asp {set restype "21"} asn {set restype "23"}
    glu {set restype "25"} gln {set restype "27"} lys {set restype "29"} arg {set restype "31"}
    his {set restype "33"} phe {set restype "35"} tyr {set restype "37"} trp {set restype "39"}
    dna {set restype "42"} wat {set restype "43"} ion {set restype "44"} lig {set restype "48"}
    default {set restype "48"}
  }
  return $restype
}

proc get_group_type_info {group_str} {
  set group_str [string toupper $group_str]
  switch $group_str {
    ALKALI   { return 44; } ALKALINE { return 45; } CATION   { return 46; }
    ANION    { return 47; } HEME     { return 48; } SOLVENT  { return 49; }
    SUGAR    { return 50; } COFACTOR { return 51; } HEAVY    { return 52; }
  }
  set group_str_4 [string range $group_str 0 3] 
  switch $group_str_4 {
    ALKA { return 44; } CATI { return 46; } ANIO { return 47; }
    HEME { return 48; } SOLV { return 49; } SUGA { return 50; }
    COFA { return 51; } HEAV { return 52; } default { return -1 }
  }
}

proc get_query_resinfo { resname_str } {
  if {[regexp {(\w+)-(\w+)-(\w+)} $resname_str part1 part2 part3]} {
    set tabname [get_table_name_info $part1]
    if {[string equal $tabname "null"]} { error_out "invalid table name: $part1 ($resname_str)" }
    set grptype [get_group_type_info $part2]
    if {$grptype == -1} { error_out "invalid group name: $part2 ($resname_str)" }
    set resname $part3
    if {[string length $resname] > 3} { error_out "invalid ligand code (length > 3): $part3 ($resname_str)" }
  } elseif {[regexp {(\w+)-(\w+)} $resname_str part1 part2]} {
    set part1_group_type [get_group_type_info $part1]
    set part2_group_type [get_group_type_info $part2]
    if {$part1_group_type > 0} {
      set grptype $part1_group_type
      set tabname "lig"
      if {$grptype>=44 && $grptype<=47} { set tabname "ion" }
      set resname $part2
      if {[string length $resname] > 3} { error_out "invalid ligand code (length > 3): $part2 ($resname_str)" }
    } elseif {$part2_group_type > 0} {
      set tabname [get_table_name_info $part1]
      if {[string equal $tabname "null"]} { error_out "invalid table name: $part1 ($resname_str)" }
      set grptype $part2_group_type
      if {$grptype>=44 && $grptype<=47 && ![string equal $tabname "ion"]} { error_out "table-group mismatch: $tabname-$grptype ($resname_str)" }
      if {$grptype>=48 && $grptype<=53 && ![string equal $tabname "lig"]} { error_out "table-group mismatch: $tabname-$grptype ($resname_str)" }
      set resname "null"
    } else {
      set tabname [get_table_name_info $part1]
      if {[string equal $tabname "null"]} { error_out "invalid table name: $part1 ($resname_str)" }
      set grptype -1
      set resname $part2
      if {[string length $resname] > 3} { error_out "invalid ligand code (length > 3): $part2 ($resname_str)" }
      if {[get_table_type_num $tabname] <= 39} {
        if {[string equal $resname $tabname]} {
          set grptype [get_table_type_num $tabname]
        } else {
          set grptype [expr [get_table_type_num $tabname]+1]
        }
      }
    }
  } else {
    set tabname [get_table_name_info $resname_str]
    set grptype [get_group_type_info $resname_str]
    if {![string equal $tabname "null"]} {
      set grptype -1
      set resname "null"
    } elseif {$grptype > 0} {
      set tabname "lig"
      if {$grptype>=44 && $grptype<=47} { set tabname "ion" }
      set resname "null"
    } else {
      switch $resname_str {
        mse     { set tabname "met"; set grptype 18; set resname "mse" }
        mly     { set tabname "lys"; set grptype 30; set resname "mly" }
        hoh     { set tabname "wat"; set grptype -1; set resname "null" }
        g       { set tabname "dna"; set grptype -1; set resname "null" }
        c       { set tabname "dna"; set grptype -1; set resname "null" }
        a       { set tabname "dna"; set grptype -1; set resname "null" }
        t       { set tabname "dna"; set grptype -1; set resname "null" }
        u       { set tabname "dna"; set grptype -1; set resname "null" }
        default {
          if {[string length $resname_str] > 3} { error_out "invalid ligand code (length > 3): $resname_str" }
          set tabname "lig"; set grptype -1; set resname $resname_str }
      }
    }
  }
  # tabname: strictly 3-letter-coded, only 24 values enumeratable, use procedure "get_table_type_num" to get type
  # grptype: if it is -1, use whole table, otherwise limit search on residue types specified in SQL "where" clause
  # resname: if it is "null", use whole table, otherwise limit search on residues in SQL "where" clause
  return [list $tabname $grptype $resname]
}

proc get_query_tabname { residueid } {
  global arr_formal_nodes
  set resname [lindex $arr_formal_nodes($residueid,name) 0]
  set resinfo [get_query_resinfo $resname]
  return [lindex $resinfo 0]
}

proc get_query_grptype { residueid } {
  global arr_formal_nodes
  set resname [lindex $arr_formal_nodes($residueid,name) 0]
  set resinfo [get_query_resinfo $resname]
  return [lindex $resinfo 1]
}

proc get_query_resname { residueid } {
  global arr_formal_nodes
  set resname [lindex $arr_formal_nodes($residueid,name) 0]
  set resinfo [get_query_resinfo $resname]
  return [lindex $resinfo 2]
}

proc get_query_restype { residueid } {
  global arr_formal_nodes
  set resname [lindex $arr_formal_nodes($residueid,name) 0]
  set resinfo [get_query_resinfo $resname]
  return [get_table_type_num [lindex $resinfo 0]]
}

proc get_query_restype_str { residueid } {
  global arr_formal_nodes
  set resname [lindex $arr_formal_nodes($residueid,name) 0]
  set resinfo [get_query_resinfo $resname]
  return [get_table_type_txt [lindex $resinfo 0]]
}

proc check_direction { residueid_a residueid_b } {
  set restype_a [get_query_restype $residueid_a]
  set restype_b [get_query_restype $residueid_b]
  if {$restype_a > $restype_b} { set direction -1 } else { set direction 1 }
  return $direction
}

proc generate_query_table { link } {
  global arr_formal_nodes fdout temp_table_created
  set residueid_a [lindex $link 0]
  set residueid_b [lindex $link 1]
# puts "$residueid_a $residueid_b"

  set direction [check_direction $residueid_a $residueid_b]
  if {$direction == -1} {
    error_out "Incorrect direction detected, please setting up direction for link before calling procedure 'generate_query_table'"
  }
# set restype_a [get_query_restype_str $residueid_a]
# set restype_b [get_query_restype_str $residueid_b]
# set resname_a [get_query_resname $residueid_a]
# set resname_b [get_query_resname $residueid_b]

  set multi_count_a [llength $arr_formal_nodes($residueid_a,name)]
  set multi_count_b [llength $arr_formal_nodes($residueid_b,name)]
  for {set i 0} {$i<$multi_count_a} {incr i} {
    set raw_resname_a [lindex $arr_formal_nodes($residueid_a,name) $i]
    set resinfo_a [get_query_resinfo $raw_resname_a]
    set resname_a [lindex $resinfo_a 0]
    set restype_a [get_table_type_txt $resname_a]
    for {set j 0} {$j<$multi_count_b} {incr j} {
      set raw_resname_b [lindex $arr_formal_nodes($residueid_b,name) $j]
      set resinfo_b [get_query_resinfo $raw_resname_b]
      set resname_b [lindex $resinfo_b 0]
      set restype_b [get_table_type_txt $resname_b]
      if {$i==0 && $j==0} {
        set tab_frag "(SELECT pdbfileid, residueid_a, residueid_b FROM neighbors${restype_a}${restype_b}_${resname_a}_${resname_b}"
      } else {
        set tab_frag "$tab_frag\n  UNION ALL SELECT pdbfileid,"
        if {$restype_a <= $restype_b} {
          set tab_frag "$tab_frag residueid_a, residueid_b FROM neighbors${restype_a}${restype_b}_${resname_a}_${resname_b}"
        } else {
          set tab_frag "$tab_frag residueid_b AS residueid_a, residueid_a AS residueid_b FROM neighbors${restype_b}${restype_a}_${resname_b}_${resname_a}"
        }
      }
      if {$restype_a == $restype_b} {
        set tab_frag "$tab_frag\n  UNION ALL SELECT pdbfileid, residueid_b AS residueid_a, residueid_a AS residueid_b FROM neighbors${restype_b}${restype_a}_${resname_b}_${resname_a}"
      }
    }
  }
  set tab_frag "$tab_frag)"
  return $tab_frag
}

proc generate_query_fragment { number_nodes number_links } {
  global arr_formal_nodes arr_formal_links temp_table_created
  set query_fragment "SELECT t0.pdbfileid"
  for {set i 1} {$i <= $number_nodes} {incr i} {
    if {$i!=1 && [expr $i % 3]==1} { set query_fragment "$query_fragment\n                   " }
    set query_fragment "$query_fragment, $arr_formal_nodes($i,text) AS res$i"
  }
  for {set i 0} {$i < $number_links} {incr i} {
    set link $arr_formal_links($i)
    if {$i == 0} {
      set query_fragment "$query_fragment\nFROM [generate_query_table $link] t$i"
    } else {
      set query_fragment "$query_fragment\nJOIN [generate_query_table $link] t$i"
      if {[string equal $arr_formal_links($i,condition) ""]} {
        error_out "Unknown condition, unrestricted cartesian cross join won't be honored"
      } else {
        set query_fragment "$query_fragment\nON   t${i}.pdbfileid=t0.pdbfileid AND $arr_formal_links($i,condition)"
      }
      if {![string equal $arr_formal_links($i,different) ""]} {
        set query_fragment "$query_fragment\n                               AND $arr_formal_links($i,different)"
      }
    }
  }
  set temp_table_created 1
  return $query_fragment
}

proc generate_leftjoin_fragment { number_nodes } {
  global arr_formal_nodes
  set query_fragment "SELECT pdbid"
  for {set i 1} {$i <= $number_nodes} {incr i} {
    if {$i!=1 && [expr $i % 3]==1} { set query_fragment "$query_fragment\n            " }
    set query_fragment "$query_fragment, rt$i.chainid, rt$i.resseq"
  }
  set query_fragment "$query_fragment\nFROM  (SELECT * FROM temp) tt"
  set query_fragment "$query_fragment\nLEFT JOIN pdbfile            ON tt.pdbfileid=pdbfile.pdbfileid"
  for {set i 1} {$i <= $number_nodes} {incr i} {
    set tabname [get_query_tabname $i]
    set restype [get_query_restype_str $i]
    set tablename residues${restype}_$tabname
    set query_fragment "$query_fragment\nLEFT JOIN $tablename rt${i} ON tt.pdbfileid=rt${i}.pdbfileid AND tt.res${i}=rt${i}.residueid"
  }
  set query_fragment "$query_fragment;"
  return $query_fragment
}

# STEP V: Setting up array for links, BTW check whether there is only one cluster or not
set number_links 0
while {[llength $cluster_list_1]!=0} {
  set temp_list ""
  foreach elem_node $cluster_list_2 {
    foreach elem_link $arr_formal_nodes($elem_node,link2) {
      if {![info exists arr_link_flags($elem_node,$elem_link)]} {
        set arr_link_flags($elem_node,$elem_link) 1
        set arr_link_flags($elem_link,$elem_node) 1
        set direction [check_direction $elem_node $elem_link]
        if {$direction==1} {
          set arr_formal_links($number_links) [list $elem_node $elem_link] 
        } elseif {$direction==-1} {
          set arr_formal_links($number_links) [list $elem_link $elem_node] 
        }
        incr number_links
      }
      set cluster_list_1_position [lsearch $cluster_list_1 $elem_link]
      if {$cluster_list_1_position!=-1} {
        set cluster_list_1 [lreplace $cluster_list_1 $cluster_list_1_position $cluster_list_1_position]
        lappend temp_list $elem_link
      }
    }
  }
  if {[llength $temp_list]==0} { break }
  foreach elem $temp_list { lappend cluster_list_2 $elem }
}
if {[llength $cluster_list_1]!=0} { error_out "More than one cluster in input graph, please use only one cluster" }

proc process_typical_node { linkid nodeid linkend number_nodes } {
  global arr_formal_nodes arr_formal_links
  set resname [lindex $arr_formal_nodes($nodeid,name) 0]
  set temp_condition $arr_formal_links($linkid,different)
  for {set j 0} {$j < $number_nodes} {incr j} {
    if {[info exists arr_formal_nodes($j,text)]} {
      if {[string equal $resname [lindex $arr_formal_nodes($j,name) 0]]} {
        if {![string equal $temp_condition ""]} {set temp_condition "$temp_condition AND "}
        set typical_residue $arr_formal_nodes($j,text)
        set temp_condition "${temp_condition}t${linkid}.residueid_$linkend!=$typical_residue"
      }
    }
  }
  set arr_formal_links($linkid,different) $temp_condition
  set arr_formal_nodes($nodeid,linknum) $linkid
  set arr_formal_nodes($nodeid,linkend) $linkend
  set arr_formal_nodes($nodeid,text) "t${linkid}.residueid_$linkend"
}

for {set i 0} {$i < $number_links} {incr i} {
  set residueid_a [lindex $arr_formal_links($i) 0]
  set residueid_b [lindex $arr_formal_links($i) 1]
  set arr_formal_links($i,condition) ""
  set arr_formal_links($i,different) ""
  if {[info exists arr_formal_nodes($residueid_a,text)]} {
    set typical_residue $arr_formal_nodes($residueid_a,text)
    set arr_formal_links($i,condition) "t${i}.residueid_a=$typical_residue"
  } else {
    process_typical_node $i $residueid_a "a" $number_nodes
  }
  if {[info exists arr_formal_nodes($residueid_b,text)]} {
    set temp_condition $arr_formal_links($i,condition)
    if {![string equal $temp_condition ""]} {set temp_condition "$temp_condition AND "}
    set typical_residue $arr_formal_nodes($residueid_b,text)
    set arr_formal_links($i,condition) "${temp_condition}t${i}.residueid_b=$typical_residue"
  } else {
    process_typical_node $i $residueid_b "b" $number_nodes
  }
}

puts $fdout "set enable_seqscan=0;\nset enable_sort=0;\n"
puts $fdout "explain"
puts $fdout [generate_query_fragment $number_nodes $number_links]
puts $fdout ";\n"
if {$IS_PRODUCTIVE} { puts $fdout "CREATE TEMPORARY TABLE temp AS (" }
puts $fdout [generate_query_fragment $number_nodes $number_links]
if {$IS_PRODUCTIVE} { puts -nonewline $fdout ")" }
puts $fdout ";\n"
if {$IS_PRODUCTIVE} { puts $fdout [generate_leftjoin_fragment $number_nodes] }
# close $fdout
