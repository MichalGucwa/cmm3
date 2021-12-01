#!/usr/bin/env tclsh
# wrapper for find_atoms_from_map_and_refine procedure from crankutils.tcl so that it can be used from python

global env
global XMLParse

set prog    [lindex $argv 0 ]
set tag     [lindex $argv 1 ]
set run     [lindex $argv 2 ]
set step    [lindex $argv 3 ]
set thres   [lindex $argv 4 ]
set inccp4  [lindex $argv 5 ]
set refine  [lindex $argv 6 ]
set verbose [lindex $argv 7 ]

source [file join $env(CRANK) bin crankutils.tcl]

set crankplugins [file join $env(CRANK) plugins]

if { [file exists [file join .. xml input.xml]] } {
  XMLParsefile [file join .. xml input.xml]
} else {
  if { [file exists [file join .. .. xml input.xml]] } {
    XMLParsefile [file join .. .. xml input.xml]
  } else {
    puts "find_add_remove_refine_heavy::xml not found!"
    puts stderr "find_add_remove_refine_heavy::xml not found!"
    exit 100
  }
}


find_atoms_from_map_and_refine $prog $tag $run $step $thres $crankplugins $inccp4 $refine $verbose
