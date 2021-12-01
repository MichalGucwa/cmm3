#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface cif_utils.tcl
#
#
# Utilities for dealing with CIF data
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#===========================================================================
proc ExtractCIFData { file } {
#===========================================================================
# Read all the loop names and types from CIF file "file"
# and load into global array CIF_file_data

   global CIF_file_data

   if { [ElementExists CIF_file_data LOADED] && \
          $file == $CIF_file_data(FILE) } {
      if { $CIF_file_data(LOADED)  == 1 } {
#     puts "Using old data "
        return 1
      } elseif { $CIF_file_data(LOADED)  == -1 } {
        return -2
      }
   }

   if { [OpenFile $file f r ] <= 0 } { 
     WarningMessage "ERROR Opening CIF file.  Check read permissions"
     return -1 
   }

   set CIF_file_data(LOADED) 0
   set CIF_file_data(FILE) $file

   set CIF_file_data(NLOOPS) 0
   set nloops 0
   set line [ExtractFromFile $f "loop_*" 1 all ]

   while { $line != {} } {
     set dataname [split [string trim $line ]  "." ]
     incr nloops
     set CIF_file_data(LOOP_CATAGORY,$nloops) [lindex $dataname 0 ]
     set line [ExtractFromFile $f "loop_*" 1 all ]
  }

   set CIF_file_data(NLOOPS) $nloops
     
   CloseFile $f

   set CIF_file_data(LOADED) 1
   set CIF_file_data(FILE) $file
   return 1
}

#---------------------------------------------------------------------
proc GetCifDataNames { channel loop_category ndatanamesVar datanamesVar \
                         first_lineVar } {
#---------------------------------------------------------------------

  upvar $ndatanamesVar ndatanames
  upvar #0 $datanamesVar datanames
  upvar $first_lineVar first_line

  set ndatanames 0
  set datanames {}

  set first_line 0
  set line [ExtractFromFile $channel "loop_*" 1 all]
  incr first_line [GetSystemVar extractfromfile_lines_read]

  while { $line != {} } {
    set splitline [split [string trim $line] "."]
    if  { [lindex $splitline 0 ] == $loop_category } {
      incr ndatanames
      lappend datanames [lindex $splitline 1 ]
      gets $channel line
      incr first_line
    } elseif { $ndatanames > 0 } {
      SetSystemVar CIF_SAVE_LINE $line
      return 1
    } else {
      set line [ExtractFromFile $channel "loop_*" 1 all]
      incr first_line [GetSystemVar extractfromfile_lines_read]
    }
  }
  return 0
}

#---------------------------------------------------------------------
proc GetCifData { channel nlinesVar dataVar data_line_refVar \
  datanamesVar { select_param {}}  {range_min {}} {range_max {} } } {\
#---------------------------------------------------------------------

# Assume GetCIFDataNames has read through file to first line in listing
# of data and that line is saved as SystemVar CIF_SAVE_LINE 
# If the select_param is set then just return packets in the range 
# range_min to range_max - otherwise return all packets

  upvar $nlinesVar nlines
  upvar #0 $dataVar data
  upvar #0 $data_line_refVar data_line_ref
  upvar #0 $datanamesVar datanames

  if { $select_param != {} } {
    set select_field [lsearch $datanames "$select_param"]
  } else {
    set select_field -1 
  }
  set nfields [llength $datanames]
#  puts "GetCifData select_field $select_field nfields $nfields"
#  puts " range_min $range_min range_max $range_max"

  set line [GetSystemVar CIF_SAVE_LINE]
  set firstchar [string range $line 0 0 ]
  set refline 1
  set nlines 0

  while { $line != {} && $firstchar != "_" } {
    if { $firstchar != "#" } {
      set packet_line $refline
      set n_continues 0
      if { $firstchar == ";" } {
        cif_read_continuation $channel refline line firstchar tmpstring
        lappend tmplist "$tmpstring"
      } else {
         set tmplist [cif_parse_line $line ] 
      }
      while { [llength $tmplist] < $nfields  } {
        cif_read_line $channel refline line firstchar
        incr n_continues
        if { $firstchar == ";" } {
          cif_read_continuation $channel refline line firstchar tmpstring
          lappend tmplist "$tmpstring"
        } else {
          set tmplist [concat $tmplist  [cif_parse_line $line ]]
        }
      }
      set index 0
      set load_line 1
      while { $load_line == 1 } {
        if { ( $select_field < 0 || [cif_if_selected \
          [lindex $tmplist $select_field] $range_min $range_max] ) \
           && [lsearch $data_line_ref(PACKET_LIST) $packet_line] < 0 } {
          incr nlines
#          puts "loading nlines $nlines"
          set l 0
          for { set l 1 } { $l <= $nfields } { incr l } {
            set data([subst $packet_line].[subst $index],[subst $l]) \
		[lindex $tmplist [expr {$l -1} ] ]
          }
          lappend data_line_ref(PACKET_LIST) $packet_line.$index
          lappend data_line_ref(LINE_CONTINUES) $n_continues
        }
        if { [llength $tmplist] > $nfields } {
          set tmplist [lrange $tmplist $nfields end ]
          incr index
        } else {
          set load_line 0
        }
      }
    }
    cif_read_line $channel refline line firstchar
  }
  set data_line_ref(NPACKETS) $nlines
}

proc cif_read_line { channel reflineVar lineVar firstcharVar } {
  upvar $reflineVar refline
  upvar $lineVar line
  upvar $firstcharVar firstchar

  incr refline
  gets $channel line
  set firstchar [string range $line 0 0 ]
}

#---------------------------------------------------------------------
proc cif_read_continuation { channel reflineVar lineVar firstcharVar \
                     tmpstringVar } {
#---------------------------------------------------------------------
  upvar $reflineVar refline
  upvar $lineVar line
  upvar $firstcharVar firstchar
  upvar $tmpstringVar tmpstring

  set line [string range $line 1 0]; set firstchar ""
  set tmpstring ""
  while { $firstchar != ";" } {
    append tmpstring $line
    cif_read_line $channel refline line firstchar
#    puts "cif_read_continuation after cif_read_line $firstchar"
  }
}

#----------------------------------------------------------------------
proc remove_blanks { datalist } {
#----------------------------------------------------------------------

  set outlist {}
  foreach item $datalist {
    if {$item != {} } { lappend outlist $item }
  }
  return $outlist
}

#--------------------------------------------------------------------
proc cif_parse_line { line } {
#--------------------------------------------------------------------

  set lf [string first "'" $line ]
  if { $lf == -1 } {
      return [remove_blanks [split $line " "]]
  }

  set return_list {}
  set more_to_parse 1
  set line [string trim $line]
  while { $more_to_parse } {
    set lf [string first "'" $line ]
    if { $lf == -1 } {
      set return_list [concat $return_list [remove_blanks [split $line " "]] ]
    } else {
      if { $lf > 0 } {
        set return_list [concat $return_list [remove_blanks [split  \
			       [string range $line 0 [expr {$lf -1} ] ] ] ] ]
      } 
      set line [string range $line [expr {$lf + 1} ] end ]
      set ll [string first "'" $line ]
	#      puts "quoted string: [string range $line 0 [expr {$ll -1} ] ]"
      lappend return_list "[string range $line 0 [expr {$ll -1} ] ]"
      if { [expr {$ll + 1} ] < [string length $line ] } {
	set line [string range $line [expr {$ll + 1} ] end ]
#        puts "chopped down line $line"
      } else {
        set more_to_parse 0
      }
    }
  }
#  puts "return_list $return_list"
  return $return_list
}



#----------------------------------------------------------------------
proc cif_if_selected { item  range_min range_max } {
#----------------------------------------------------------------------

  if { $item <= $range_max && $item >= $range_min } {
    return 1
  } else {
    return 0
  }
}
