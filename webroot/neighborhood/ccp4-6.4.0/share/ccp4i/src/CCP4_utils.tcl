#
#     Copyright (C) 1999-2005  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - CCP4_utils.tcl
#
#
#
# Interface utilities which are specific to CCP4 interface
#
#  Liz Potterton April 1997
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Handling CCP4-Specific File Formats
#
#--------------------------------------------------------------------------
proc InitialiseProject { } {
#--------------------------------------------------------------------------
#d_sum The place for CCP4 specific initialisation
  global deflists
  global crystal_data

  InitialiseXtlData 
  return 1

}

#----------------------------------------------------------------
  proc InitialiseXtlData { } {
#----------------------------------------------------------------
#d_sum Load data from file CCP4/lib/data/symop.lib & CCP4/ccp4i/etc/crystal.lib
#d_desc Loaded into crystal_data array
  global crystal_data
  global deflists

  set symfile [FileJoin [GetEnvPath CCP4] lib data symop.lib]
  if { ![file exists $symfile] } {
    set  env(CLIBD) [GetEnvPath CLIBD]
    set symfile [FileJoin $env(CLIBD) symop.lib]
    if { $env(CLIBD) == "" || ![file exists $symfile] } {
      puts "Can not find CCP4 symmetry file \$CLIBD/symop.lib
Please check your CCP4 setup and rerun CCP4I"
#      exit
    }
  }

  set syminfofile [FileJoin [GetEnvPath CCP4] lib data syminfo.lib]
  if { ![file exists $syminfofile] } {
    set  env(CLIBD) [GetEnvPath CLIBD]
    set syminfofile [FileJoin $env(CLIBD) syminfo.lib]
    if { $env(CLIBD) == "" || ![file exists $syminfofile] } {
      puts "Can not find CCP4 symmetry file \$CLIBD/syminfo.lib
Please check your CCP4 setup and rerun CCP4I"
#      exit
    }
  }

  if { [ReadSymops $symfile ] } {
    set deflists(valid_space_groups) \
      [concat $crystal_data(SYM_NUMBER) $crystal_data(SYM_CODE) \
	$crystal_data(SYM_STD_CODE)]
    if { [ReadSyminfoFile $syminfofile ] } {
      set deflists(valid_space_groups) \
        [concat $deflists(valid_space_groups) $crystal_data(SYM_SYMBOL_XHM) ]
    } 
  } 
  ReadCrystalData [SearchPath TOP etc crystal.lib]

  return 1
}

#------------------------------------------------------------------------------
proc ReadSymops { filename {read_ops 0} } {
#------------------------------------------------------------------------------
  global crystal_data
  set crystal_data(LATTICE_LIST) [list TRICLINIC MONOCLINIC ORTHORHOMBIC TETRAGONAL TRIGONAL HEXAGONAL CUBIC ]

  set sym_number ""
  set sym_code ""
  set sym_nops ""
  set sym_lattice ""
  set sym_std_code ""
  set all_symops {}
  set nsyms 0

  if { [OpenFile $filename f "r"] == 0 } {
    Report 3 "Can not open symops file: $filename"
    return 0
  }

  while {[gets $f line] >= 0} {
    incr nsyms
    lappend sym_number [lindex $line 0]
    lappend sym_code [string toupper [lindex $line 3 ]]
    lappend sym_lattice [lsearch $crystal_data(LATTICE_LIST) [lindex $line 5 ]]
    set std_code [string trim [lrange $line 6 end] ']
    if { [set index [string first "'" $std_code]] >= 0 } {
      set std_code [string range $std_code 0 [expr {$index - 1}]]
    }
    lappend sym_std_code $std_code
    set nops [lindex $line 1 ] 
    lappend sym_nops $nops

    set symops {}
    for { set i 1 } { $i <= $nops } { incr i } {
      lappend symops [gets $f ]
    }
    lappend all_symops $symops
  }
#  Report 2 "Read $nsyms symmetry codes from $filename " -notime
  set crystal_data(SYM_NUMBER) $sym_number
  set crystal_data(SYM_CODE) $sym_code
  set crystal_data(SYM_NOPS) $sym_nops
  set crystal_data(SYM_LATTICE) $sym_lattice
  set crystal_data(SYM_STD_CODE) $sym_std_code
  if {$read_ops} { set crystal_data(SYM_OPS) $all_symops }
    
  CloseFile $f

  return 1

}

#------------------------------------------------------------------------------
proc ReadSyminfoFile { filename } {
#------------------------------------------------------------------------------
  global crystal_data

  set sym_number ""
  set sym_symbol_xHM ""
  set sym_symbol_old ""

  if { [ReadFile $filename symtext] == 0 } {
    Report 3 "Can not open syminfo file: $filename"
    return 0
  }

# Note - this first occurrence is in the commments at the top!
  ExtractFromText $symtext "begin_spacegroup" 0 all 
  while { [set line [ExtractFromText - "begin_spacegroup" 0 all ] ] >= 0 } {
    lappend sym_number [ExtractFromText - "number" 0 1 ]
    set line [ExtractFromText - "symbol xHM" 0 all ]
    lappend sym_symbol_xHM [string trim [lrange $line 2 end] ']
    set line [ExtractFromText - "symbol old" 0 all ]
    set std_code [string trim [lrange $line 2 end] ']
    if { [set index [string first "'" $std_code]] >= 0 } {
      set std_code [string range $std_code 0 [expr {$index - 1}]]
    }
    lappend sym_symbol_old $std_code
  }
  set crystal_data(SYM_SYMBOL_XHM) $sym_symbol_xHM

  return 1

}

#-----------------------------------------------------------------
proc ReadCrystalData { file } {
#-----------------------------------------------------------------
#d_sum Read etc/crystal.lib file and extract crystallographic info
#d_desc Save to array crystal_data
#d_desc There are crystal_data(N_LAUE) laue groups stored as list \
of space groups in crystal_data(LAUE,$spgp)
#d_desc The patterson info for space group spgp is stored in \
crystal_data(PATTERSON,$spgp) and is a list consisting of: \
patterson_spsgp_number, number of harker planes, definition of planes
#d_arg file Full path name of crystal.lib file

  global crystal_data


  set crystal_data(N_LAUE) 0
  set crystal_data(HAND) ""
  set crystal_data(TWIN) ""
  set nharker_to_read 0

  if { ![ReadFile $file text -split] } { 
    WarningMessage "Can not read crystal data file $file"
    return 0
  }

  set mode {}
  foreach line $text { 
    if { [regexp ^#CCP4I $line] && [regexp DATA $line] } { 
      set mode [lindex $line 2]
    } elseif { ![regexp ^# $line] } {
      switch $mode \
      LAUE {
        incr crystal_data(N_LAUE); set n $crystal_data(N_LAUE)
        set crystal_data(LAUE,$n) $line
      } PATTERSON {
        if { $nharker_to_read == 0 } {
          set ii 0
          set nharker_to_read [lindex $line 4]
          set spgp [lindex $line 0]
          set crystal_data(PATTERSON,$spgp) \
		[list [lindex $line 2] $nharker_to_read]
        } else {
          incr nharker_to_read -1; incr ii
          set crystal_data([Indxv HARKER $spgp $ii]) "$line"
        }
      } ASYM {
        set spgp [lindex $line 0]
        set crystal_data([Indxv ASYM $spgp]) [lrange $line 1 6]
      } FFT {
        set crystal_data(FFT) ""
        foreach sp $line {
          lappend crystal_data(FFT) $sp
        }
      } HAND {
        lappend crystal_data(HAND) [lrange $line 0 4]
      } TWIN {
        lappend crystal_data(TWIN) "$line"
      }
    }
  }
  return 1
}

#d_index_title MTZ Column Selection
#d_intro_title MTZ Column Selection
#d_intro CreateLabinLine and CreateLaboutLine are the APIs \
with a lot of support procedures. \
There is also CreateCadLabinLine which is for the customised labin lines used \
in the CAD interface.

#-------------------------------------------------------------------------
proc CreateLabinLine { linein message filein label1 name1 \
	priority_name_list1 args } {
#-------------------------------------------------------------------------
#d_sum Draw task interface line for selecting input MTZ column labels
#d_desc This is a version of CreateLabinLine that can accommodate up to \
four MTZ labels in a single group.
#d_desc The MTZ label line can allow the user to select up to four MTZ \
labels.  The second and subsequent labels are expected to be associated \
with the first (such as a sigma or a Freidel mate) and when the user \
selects the first label then the second and subsequent labels are \
automatically updated to be the appropriate related column in the MTZ \
file. The label types are defined in CCP4I_TOP/etc/types.def
#d_desc This procedure sets up commands so that \
when the user selects an input MTZ file the column names in the file \
are automatically read by the procedure ExtractMTZData and the menu(s) \
for users to select the column labels is updated by SetLabin
#d_arg linein Output Tk frame id for the line
#d_arg message Message line which appears if cursor over this line
#d_arg filein Name of element in the task interface array which contains \
the name of the input MTZ file
#d_arg label1 Text to appear in the task interface line
#d_arg name1 Name of the element in the task interface array which contains \
the name of the input label
#d_arg priority_name_list1  A list of possible column label names - if one of \
these appears in the MTZ file then it is set as the default.
#d_opt0 -sigma labeln namen priority_name_listn
#d_opt1 The label, element name and priority labels for an additional MTZ label
#d_opt0 -dependent labeln namen priority_name_listn
#d_opt1 Equivalent to the -sigma option
#d_opt0 -toggle_display toggle_var toggle_state toggle_hitlist
#d_opt1 Display this line in the task window dependent on the value of \
toggle_var.  If it takes any of the values in the list toggle_hitlist then \
set the display status to toggle_state.  toggle_state can be 'open', the \
line is displayed, or  'hide', the line is not displayed.
#d_opt0 -command command_string
#d_opt1 Associate a command to be invoked when the user clicks on any of \
the labels in the grouping.

   upvar $linein line
   set arrayname [ GetSystemVar frame_array ]
   upvar #0 $arrayname array

   set fileline ""
   foreach w [GetWidget $arrayname $filein] {
       lappend fileline [winfo parent $w]
   }
   set file_status [CheckFileInput $arrayname $filein read ]
   set label2 ""
   set label3 ""
   set label4 ""
   set help_pointer labin
   set command ""

   # Initialise for processing the arguments
   set ndep 0

   # Process the argument list
   set n 0
   set nargs [llength $args]
   while { $n < $nargs } {
       set argument [lindex $args $n]
       switch -regexp -- $argument {
	   "^-sigma|-dependent" {
	       incr ndep
	       if { $ndep > 3 } {
		   # Error in input
		   # Too many sigmas or other dependent labels
		   puts "ERROR CreateLabinLine: too many extra labels"
		   return
	       }
	       set i [expr $ndep + 1]
	       incr n; set label$i [lindex $args $n]
	       incr n; set name$i [lindex $args $n]
	       incr n; set priority_name_list$i [lindex $args $n]
	   }
	   "^-toggle_display" {
	       incr n; set toggle_var [lindex $args $n ]
	       incr n; set toggle_state [lindex $args $n ]
	       incr n; set toggle_hitlist [lindex $args $n ]
	   }
	   "-help" {
	       incr n; set help_pointer [lindex $args $n ]
	   }
	   "-command" {
	       incr n; set command [lindex $args $n]
	   }
	   default {
	       # Drop out on unrecognised input
	       puts "ERROR CreateLabinLine: unrecognised argument $argument"
	       return
	   }
       }
       incr n
   }

   # Draw the line(s) for the column label(s)
   set index [GetSystemVar current_index_counter]

   # First line
   if { $ndep == 0 } {
       # A single label on a single line
       CreateLine line \
          message $message \
	  help $help_pointer \
	  label $label1 \
	  widget $name1 \
	  format "MTZlabel"

   } else {
       # Second label on the first line
       CreateLine line  \
	   message $message \
	   help $help_pointer \
	   label $label1 \
	   widget $name1 \
	   label $label2 \
	   widget $name2 \
	   format "MTZlabel"
  }
  # Toggling for first line
  if { [info exists toggle_var ] } {
      toggle_frame_display $line $toggle_var $toggle_state $toggle_hitlist
  }

  # Second line
  if { $ndep > 1 } {

      if { $ndep == 2 } {
	  # A single label on the second line
	  CreateLine line2 \
	      message $message \
	      help $help_pointer \
	      label $label3 \
	      widget $name3 \
	      format "MTZlabel"
      } else {
	  # Two labels on the second line
	  CreateLine line2  \
	      message $message \
	      help $help_pointer \
	      label $label3 \
	      widget $name3 \
	      label $label4 \
	      widget $name4 \
	      format "MTZlabel"
      }
      # Toggling for the second line
      if { [info exists toggle_var ] } {
	  toggle_frame_display $line2 $toggle_var $toggle_state $toggle_hitlist
      }
  }

  # Add commands to update the labels when a file is selected

  if { $ndep == 0 } {
      # Single label on a single line
       add_file_command $fileline "SetLabin $arrayname $filein \
                [Indxv $name1 $index] { $priority_name_list1 }"

       if { $file_status } {
	   SetLabin $arrayname $filein [Indxv $name1 $index] \
	       { $priority_name_list1 }
       }
  } elseif { $ndep == 1 } {
      # Two labels on a single line
      add_file_command $fileline "SetLabin $arrayname $filein \
                [Indxv $name1 $index] { $priority_name_list1 } \
                [Indxv $name2 $index] { $priority_name_list2 } "

      if { $file_status } {
	  eval SetLabin $arrayname $filein \
	      [Indxv $name1 $index] { $priority_name_list1 } \
	      [Indxv $name2 $index] { $priority_name_list2 }
      }
  } elseif { $ndep == 2 } {
      # Two lines, three labels
      add_file_command $fileline "SetLabin $arrayname $filein \
                [Indxv $name1 $index] { $priority_name_list1 } \
                [Indxv $name2 $index] { $priority_name_list2 } \
                [Indxv $name3 $index] { $priority_name_list3 } "

      if { $file_status } {
	  eval SetLabin $arrayname $filein \
	      [Indxv $name1 $index] { $priority_name_list1 } \
	      [Indxv $name2 $index] { $priority_name_list2 } \
              [Indxv $name3 $index] { $priority_name_list3 }
      }
  } elseif { $ndep == 3 } {
      # Two lines, four labels
      add_file_command $fileline "SetLabin $arrayname $filein \
                [Indxv $name1 $index] { $priority_name_list1 } \
                [Indxv $name2 $index] { $priority_name_list2 } \
                [Indxv $name3 $index] { $priority_name_list3 } \
                [Indxv $name4 $index] { $priority_name_list4 } "

      if { $file_status } {
	  eval SetLabin $arrayname $filein \
	      [Indxv $name1 $index] { $priority_name_list1 } \
	      [Indxv $name2 $index] { $priority_name_list2 } \
              [Indxv $name3 $index] { $priority_name_list3 } \
              [Indxv $name4 $index] { $priority_name_list4 }
      }
  }

  # Add the supplied command to the menus, if any
  if { $command != "" } {
      add_labinline_command $command $arrayname $name1
      if { $ndep > 0 } {
	  add_labinline_command $command $arrayname $name2
      }
      if { $ndep > 1 } {
	  add_labinline_command $command $arrayname $name3
      }
      if { $ndep > 2 } {
	  add_labinline_command $command $arrayname $name4
      }
  }

  # End of CreateLabinLine
  return
}


#-------------------------------------------------------------------------
proc CreateLabinLine4 { linein message filein label1 name1 \
	priority_name_list1 args } {
#-------------------------------------------------------------------------
#d_sum Draw task interface line for selecting input MTZ column labels
#d_desc This command is now just a wrapper to CreateLabinLine, and so \
supports all the same options as that command.

  upvar $linein line
  return [eval [list CreateLabinLine line "$message" $filein "$label1" \
		    $name1 $priority_name_list1] $args]
}

#-------------------------------------------------------------------------
proc add_labinline_command { command arrayname var } {
#-------------------------------------------------------------------------
#d_sum Internal function used in CreateLabinLine
#d_desc This adds a command callback to a label variable.
#d_arg command The command to be invoked
#d_arg arrayname The name of the parameter array
#d_arg var The parameter name associated with the label
    upvar \#0 $arrayname array
    global tcl_version
    if { $tcl_version == "8.3" } {
	# The "trace add" option is not in 8.3
	trace variable array($var) w \
	    "invoke_labinline_command \"$command\""
    } else {
	# Use "trace add" for non-8.3 Tcl versions
	trace add variable array($var) write \
	    "invoke_labinline_command \"$command\""
    }
}

#-------------------------------------------------------------------------
proc invoke_labinline_command { command args } {
#-------------------------------------------------------------------------
#d_sum Internal function used in CreateLabinLine
#d_desc Invoke a user-defined callback when labels are changed
#d_arg command The command to be invoked when the labels are updated
    if { [catch { eval $command } err ] } {
	Report 3 "WARNING: error when executing callback bound to labinline: $err"
    }
}

#---------------------------------------------------------------------
proc SetLabin { arrayname filename args } {
#---------------------------------------------------------------------
#d_sum An updated version of SetLabin ...
#d_sum Handler to update Labin menu after user has selected MTZ file
#d_arg arrayname Name of data array
#d_arg filename Element of array which contains the MTZ file name
#d_arg labin_element1...labin_elementn  Any number of elements \
of the array which are the input column labels which map onto \
the labin menu widgets
#d_opt0 -setallelements
#d_opt1 Flag that the labin elements are part of extending frames \
and have multiple instances with names element,n.  Update the menus \
for all instances of the element
  upvar #0 $arrayname array
  global configure

  set status 1
  set filestatus 1

  set nargs [llength $args]
  if { [lindex $args [expr $nargs - 1 ] ] == "-setallelements" } {
    set setallelements "-setallelements"
    set allelements 1
    incr nargs -1
  } else {
    set setallelements ""
    set allelements 0
  }

# Set the maximum length of a menu column before it is broken
  set column_length $configure(MENU_LENGTH)

# Sort out the MTZ file
  set file [GetFullFileName0 $arrayname $filename]
  set file_status [expr [file exists $file] && [file isfile $file] ]

  set nlabels [expr  $nargs / 2  ]

  # Extract the data for the first label
  set name_list {}
  set type_list {}
  set default_name ""

  extract_label_data $arrayname \
    element [lindex $args 0 ] \
    priority_name_list [lindex $args 1 ] \
    mtz_column_type

  GetIndx $element root c1 c2
  if { $c1 > 0 } {
    if { $allelements } {
      set elements_list [GetIndexedElements $arrayname $root $c1]
      if {[llength $elements_list] == 0 } { return }
    } else {
      set elements_list $element
    }
  } else {
    set elements_list $element
  }

  ########################################################
  # Extract the data for the dependent labels, if any
  ########################################################

  if { $nlabels >= 2 } {
      # Second label
      set name_list2 {}
      set type_list2 {}
      set default_name2 ""

      extract_label_data $arrayname \
	  element2 [lindex $args 2 ] \
	  priority_name_list2 [lindex $args 3 ] \
	  mtz_column_type2 field2_list
  }
  if { $nlabels >= 3 } {
      # Third label
      set name_list3 {}
      set type_list3 {}
      set default_name3 ""

      extract_label_data $arrayname \
	  element3 [lindex $args 4 ] \
	  priority_name_list3 [lindex $args 5 ] \
	  mtz_column_type3 field3_list

      # Copied from the code for the first label
      GetIndx $element3 root c1 c2
      if { $c1 > 0 } {
	  if { $allelements } {
	      set elements_list3 [GetIndexedElements $arrayname $root $c1]
	      if {[llength $elements_list3] == 0 } { return }
	  } else {
	      set elements_list3 $element3
	  }
      } else {
	  set elements_list3 $element3
      }
      # FIXME? This next line ignores the block above and assumes
      # that there is only one element to deal with
      set elements_list3 $element3
  }
  if { $nlabels == 4 } {
      # Fourth label
      set name_list4 {}
      set type_list4 {}
      set default_name4 ""

      # Extract information for the fourth label
      extract_label_data $arrayname \
	element4 [lindex $args 6 ] \
	priority_name_list4 [lindex $args 7 ] \
	mtz_column_type4 field4_list
  }

  ########################################################
  # Fetch the column lists for the labels
  ########################################################

  if { $file_status != 0 } {
      if { $nlabels == 1 } {
	  # Single label
	  if { $file_status == 1 } {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file \
		       name_list type_list default_name \
		       $mtz_column_type $priority_name_list ]
	  } else {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file_parents \
		       name_list type_list default_name \
		       $mtz_column_type ]
	  }
      } elseif { $nlabels == 2 } {
	  # Two labels
	  if { $file_status == 1 } {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file \
		       name_list type_list default_name \
		       $mtz_column_type $priority_name_list \
		       name_list2 type_list2 default_name2 \
		       $mtz_column_type2 $priority_name_list2 ]
	  } else {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file_parents \
		       name_list type_list default_name \
		       $mtz_column_type $priority_name_list \
		       name_list2 type_list2 default_name2 \
		       $mtz_column_type2 $priority_name_list2 ]
	  }
      } elseif { $nlabels == 3 } {
	  # Three labels
	  if { $file_status == 1 } {
	  } else {
	  }
      } elseif { $nlabels == 4 } {
	  # Three labels
	  if { $file_status == 1 } {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file \
		       name_list type_list default_name \
		       $mtz_column_type $priority_name_list \
		       name_list2 type_list2 default_name2 \
		       $mtz_column_type2 $priority_name_list2 \
		       name_list3 type_list3 default_name3 \
		       $mtz_column_type3 $priority_name_list3 \
		       name_list4 type_list4 default_name4 \
		       $mtz_column_type4 $priority_name_list4 ]
	  } else {
	      set GetColumnListCmd \
		  [list GetMtzColumnList $file_parents \
		       name_list type_list default_name \
		       $mtz_column_type $priority_name_list \
		       name_list2 type_list2 default_name2 \
		       $mtz_column_type2 $priority_name_list2 \
		       name_list3 type_list3 default_name3 \
		       $mtz_column_type3 $priority_name_list3 \
		       name_list4 type_list4 default_name4 \
		       $mtz_column_type4 $priority_name_list4 ]
	  }
      } else {
	  # More than three (or less than 1!)
	  puts "ERROR nlabels = $nlabel out of range (0<nlabel<4)"
	  return
      }
      # Execute the command to fetch the labels
      set status [eval $GetColumnListCmd]

      ########################################################
      # For more than one label, deal with the results
      ########################################################

      if {$nlabels >= 2 && [ElementExists $arrayname $element2] } {
	  # Second label

	  lappend name_list2 "Unassigned"
	  lappend type_list2 "X"
	  if { $array($element2) == "" || 
	       [lsearch $name_list2  $array($element2)] < 0 } {
	      set array($element2) $default_name2
	  }
	  SetLabelList $arrayname $element2 $name_list2 $type_list2
      }

      if {$nlabels >= 3 && [ElementExists $arrayname $element3] } {
	  # Third label

	  lappend name_list3 "Unassigned"
	  lappend type_list3 "X"
	  if { $array($element3) == "" || 
	       [lsearch $name_list3  $array($element3)] < 0 } {
	      set array($element3) $default_name3
	  }
	  SetLabelList $arrayname $element3 $name_list3 $type_list3
      }

      if { $nlabels == 4 && [ElementExists $arrayname $element4] } {
	  # Fourth label

	  lappend name_list4 "Unassigned"
	  lappend type_list4 "X"
	  if { $array($element4) == "" || 
	       [lsearch $name_list4  $array($element4)] < 0 } {
	      set array($element4) $default_name4
	  }
	  SetLabelList $arrayname $element4 $name_list4 $type_list4
      }
  }

  ########################################################
  # Set labin menus to unassigned if the file is not
  # selected, or is invalid
  ########################################################

  if { $filestatus == 0 || $status <= 0 } {
     SetLabinUnassigned $arrayname $element $setallelements
     if {$nlabels >= 2 } {
       SetLabinUnassigned $arrayname $element2 $setallelements
     }
     if {$nlabels >= 3 } {
       SetLabinUnassigned $arrayname $element3 $setallelements
     }
     if {$nlabels == 4 } {
       SetLabinUnassigned $arrayname $element4 $setallelements
     }
  }

  ########################################################
  # Set up for every instance of the first label
  ########################################################

  foreach ele $elements_list {

      lappend name_list "Unassigned"
      lappend type_list "X"
      if { [ElementExists $arrayname $ele] } {
	  if { $array($ele) == ""  || 
	       [lsearch $name_list $array($ele)] < 0 } {
	      set array($ele) $default_name
	  }
      }
      SetLabelList $arrayname $ele $name_list $type_list

      set field_list [GetWidget $arrayname $ele ]
      foreach field $field_list {
	  initialise_menu $field
	  set break_count 0
	  foreach item $name_list {
	      if {$nlabels == 2 } {
		  # Set up binding to second label
		  $field.m add command -label "$item"  \
		      -font $configure(FONT_REGULAR) \
		      -columnbreak \
		      [break_menu_column break_count $column_length] \
		      -command "UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element2"
	      } elseif {$nlabels == 3 } {
		  # Set up binding to 2nd, 3rd labels from first label
		  $field.m add command -label "$item"  \
		      -font $configure(FONT_REGULAR) \
		      -columnbreak \
		      [break_menu_column break_count $column_length] \
		      -command "UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element2 ; \
                       UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element3"
	      } elseif {$nlabels == 4 } {
		  # Set up binding to 2nd, 3rd & 4th labels from first label
		  $field.m add command -label "$item"  \
		      -font $configure(FONT_REGULAR) \
		      -columnbreak \
		      [break_menu_column break_count $column_length] \
		      -command "UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element2 ; \
                       UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element3 ; \
                       UpdateDependentLabin \"$item\" $arrayname  \
                                    $ele $element4"
	      } else {
		  # No dependent labels
		  $field.m add command -label "$item"  \
		      -font $configure(FONT_REGULAR) \
		      -columnbreak \
		      [break_menu_column break_count $column_length] \
		      -command "UpdateDependentLabin \"$item\" $arrayname  \
                                      $ele"
	      }
	  }
	  # Add the "List all Labels" and "Enter Label" options
	  add_label_menu_extras $field.m $arrayname \
	      $ele $file break_count
      }

      # Set up the menus for the second label, if present
      if {$nlabels >= 2 && [llength $field2_list] > 0 } {
	  
	  set break_count 0
	  foreach field2 $field2_list {
	      initialise_menu $field2
	      set nunassigned 0
	      foreach item $name_list2 {
		  if { $item == "Unassigned" } {
		      incr nunassigned
		  }
		  if { $item != "Unassigned"  || $nunassigned <= 1 } {
		      $field2.m add command -label "$item"  \
			  -font $configure(FONT_REGULAR) \
			  -columnbreak \
			  [break_menu_column break_count $column_length] \
			  -command "UpdateDependentLabin \"$item\" $arrayname \
                                      $element2"
		  }
	      }
	  }
	  # Add the "List all Labels" and "Enter Label" options
	  add_label_menu_extras $field2.m $arrayname \
	      $element2 $file break_count
      }

      # Set up the menus for the third label, if present
      if {$nlabels >= 3 && [llength $field3_list] > 0 } {

	  # 3rd label - note that the 4th label is also dependent
	  # on the 3rd label
	  set break_count 0
	  foreach field3 $field3_list {
	      initialise_menu $field3
	      set nunassigned 0
	      foreach item $name_list3 {
		  if { $item == "Unassigned" } {
		      incr nunassigned
		  }
		  if { $item != "Unassigned"  || $nunassigned <= 1 } {
		      if { $nlabels == 3 } {
			  # No dependent fourth label
			  $field3.m add command -label "$item"  \
			      -font $configure(FONT_REGULAR) \
			      -columnbreak \
			      [break_menu_column break_count $column_length] \
			      -command "UpdateDependentLabin \"$item\" \
                                      $arrayname $element3"
		      } else {
			  # Fourth label must also be updated
			  $field3.m add command -label "$item"  \
			      -font $configure(FONT_REGULAR) \
			      -columnbreak \
			      [break_menu_column break_count $column_length] \
			      -command "UpdateDependentLabin \"$item\" \
                                      $arrayname \
                                      $element3 $element4"
		      }
		  } 
	      }
	  }
	  # Add the "List all Labels" and "Enter Label" options
	  add_label_menu_extras $field3.m $arrayname \
	      $element3 $file break_count
      }

      # Set up the menus for the fourth label, if present
      if {$nlabels == 4 && [llength $field4_list] > 0 } {

	  set break_count 0
	  foreach field4 $field4_list {
	      initialise_menu $field4
	      set nunassigned 0
	      foreach item $name_list4 {
		  if { $item == "Unassigned" } {
		      incr nunassigned
		  }
		  if { $item != "Unassigned"  || $nunassigned <= 1 } {
		      $field4.m add command -label "$item"  \
			  -font $configure(FONT_REGULAR) \
			  -columnbreak \
			  [break_menu_column break_count $column_length] \
			  -command "UpdateDependentLabin \"$item\" $arrayname \
                                      $element4"
		  }
	      }
	  }
	  # Add the "List all Labels" and "Enter Label" options
	  add_label_menu_extras $field4.m $arrayname \
	      $element4 $file break_count
      }
      
  }

  # End of SetLabin
  return
}

#-------------------------------------------------------------------------
proc add_label_menu_extras { menu arrayname ele file countVar } {
#-------------------------------------------------------------------------
#d_sum Internal procedure called from SetLabin
#d_desc Append the "ListAllLabels" and "EnterLabel" options to the labin \
menus set up in SetLabin.
    global configure
    upvar $countVar count

    $menu add command -label "List all Labels" \
	-font $configure(FONT_REGULAR) \
	-columnbreak [break_menu_column count $configure(MENU_LENGTH)] \
	-command "ListAllLabels $arrayname $ele \"$file\""
	  
    $menu add command -label "Enter Label" \
	-font $configure(FONT_REGULAR) \
	-columnbreak [break_menu_column count $configure(MENU_LENGTH)] \
	-command "EnterLabel $arrayname $ele"

    return
}

#-------------------------------------------------------------------------
proc extract_label_data { arrayname \
			      elementVar elementValue \
			      prioritynamesVar namesList \
			      typeVar { fieldsVar "" } } {
#-------------------------------------------------------------------------
#d_sum Internal procedure called from SetLabin
#d_desc Set up the variables needed to define the label widgets in \
SetLabin.
    upvar $elementVar element
    set element $elementValue

    upvar $prioritynamesVar priority_name_list
    set priority_name_list $namesList

    upvar $typeVar mtz_column_type
    set mtz_column_type [GetTypeInfo $arrayname $element mtz_column_type ]

    if { $fieldsVar != "" } {
	upvar $fieldsVar field_list
	set field_list [GetWidget $arrayname $element ]
    }

    return
}

#-------------------------------------------------------------------------
proc SetLabinUnassigned { arrayname element args } {
#-------------------------------------------------------------------------
#d_sum Set labin menu to 'Unassigned' if the user has deselected an MTZ file
#d_arg arrayname Name of data array
#d_arg element Name of labin element in array
#d_opt0 -setallelements
#d_opt1 Flag that the labin element is part of extending frames \
and has multiple instances with name element,n.  Update the menus \
for all instances of the element
  upvar #0 $arrayname array
  global configure

  if { [lsearch $args "-setallelements" ] >= 0 } {
    set allelements 1
  } else {
    set allelements 0
  }

  GetIndx $element root c1 c2
  if { $c1 > 0 } {
    if { $allelements } {
      set elements_list [ GetIndexedElements $arrayname $root $c1]
    } else {
      set elements_list $element
    }
  } else {
    set elements_list $element
  }

  foreach ele $elements_list {

    set field_list [GetWidget $arrayname $ele ]
    foreach field $field_list {
      initialise_menu $field
      $field.m add command -label "Unassigned"  \
	-font $configure(FONT_REGULAR) \
        -command " UpdateDependentLabin Unassigned \
  		$arrayname $ele "
    }
    set array($ele) "Unassigned"
  }

}

#----------------------------------------------------------------------
proc UpdateDependentLabin { selection arrayname param0   args } {
#----------------------------------------------------------------------
#d_sum Update the second labin column in a line when user selects the first labin\
#d_desc This procedure is called when the user selects a new item from the labin menu
#d_arg selection The selected value for the first labin 
#d_arg arrayname Name of data array
#d_arg param0 The name of the array element which contains the first \
labin on the CreatelabinLine
#d_arg param1...paramn A list of the dependent labin elements.  There \
is usually just one for the second labin in the CreateLabin line

  upvar #0 $arrayname array
#  puts " param0 selection $param0 $selection"

# Set the array value to the value the user selected from the list

  if { [catch { set array($param0) $selection } status ] } {
     Report 3 "WARNING: error updating parameter $param0 to $selection"
  }

# If there are extra arguments then they are parallel menus which
# need updating to equivalent position in menu list

  if { $args == "" } {return }

  if { [ GetLabelList $arrayname $param0 optlist0 typelist0 ] } {
    set pp [lsearch $optlist0 $selection ]
    foreach  param  $args {
      if { [ GetLabelList $arrayname $param optlist typelist ] } {
        set array($param) [lindex $optlist $pp ]
      }
    }
  }
}

#---------------------------------------------------------------------
proc SetLabelList { arrayname element name_list type_list {mode "" } } {
#---------------------------------------------------------------------
#d_sum Save a list of allowed column labels and types a labin array element
#d_desc This list corresponds to the list of values presented in the menu 
#d_arg arrayname Name of data array
#d_arg element The name of the array element which contains the labin
#d_arg name_list List of valid column names for this labin
#d_arg type_list List of the column types for these column names
#d_arg mode Optional 'append' to append to existing list, otherwise overwrite

  upvar #0 $arrayname array
  if {[regexp append $mode]} {
    set array(COLUMNLABELS_$element) \
	[concat $array(COLUMNLABELS_$element) $name_list ]
    set array(COLUMNTYPES_$element) \
	[concat $array(COLUMNTYPES_$element) $type_list ]
  } else {
    set array(COLUMNLABELS_$element) $name_list
    set array(COLUMNTYPES_$element) $type_list
  }
}

#---------------------------------------------------------------------
proc GetLabelList { arrayname element name_listVar type_listVar} {
#---------------------------------------------------------------------
#d_sum Return the list of allowed column labels and types for a labin array element
#d_desc This list corresponds to the list of values presented in the menu
#d_arg arrayname Name of data array
#d_arg element The name of the array element which contains the labin
#d_arg name_listVar Output. List of valid column names for this labin
#d_arg type_listVar Output. List of the column types for these column names
  upvar #0 $arrayname array
  upvar $name_listVar name_list
  upvar $type_listVar type_list
  if { [ElementExists $arrayname COLUMNLABELS_$element] } {
    set name_list $array(COLUMNLABELS_$element)
    set type_list $array(COLUMNTYPES_$element)
    return 1
  } else {
    return 0
  }
}

#----------------------------------------------------------------------
proc ListAllLabels { arrayname element { file {} } } {
#----------------------------------------------------------------------
#d_sum List all column labels in MTZ file to support the 'List all Labels' option on column label menu
#d_arg arrayname Name of data array
#d_arg element The name of the array element which contains the labin
#d_arg file The full path name for the MTZ file

  upvar #0 $arrayname array
  global configure

  if { $file == "" } { return 0 }

  set name_list ""
  set type_list ""

  set w .mtzlabel
  if { [winfo exists $w] } { return }

  GetMtzColumnByType $file "*" name_list type_list

  OpenWindow $w "Select MTZ Column Label" "MTZ" -resizeable \
		-parent $arrayname

  set frame [ frame $w.f ]
  pack $frame -side top -fill x

  listbox $frame.list \
	-font $configure(FONT_REGULAR) \
        -yscrollcommand [list $frame.scroll set] \
	-selectmode browse \
        -height 8 \
        -width 25
  scrollbar $frame.scroll -command [list $frame.list yview]
  pack $frame.list -side left -fill both -expand true
  pack $frame.scroll -side left -fill y

  set i -1
  foreach name $name_list {
    incr i
    $frame.list insert end "[lindex $type_list $i]   $name"
  }

  bind $frame.list <ButtonRelease-1> "handle_list_labels %W $arrayname $element"

  button $w.b -text "Close" \
    -font $configure(FONT_REGULAR) \
    -command "destroy $w"

  pack $w.b -side top 

}


#-----------------------------------------------------------------------
proc handle_list_labels { w arrayname element } {
#-----------------------------------------------------------------------
#d_sum handler to update column label when it is selected from 'List all Columns'
#d_arg w The Tk id of the listbox which listed all column labels
#d_arg arrayname name of data array
#d_arg element Name of element in array containing the selected column name
  upvar #0 $arrayname array

  set selection [$w get [$w curselection] ]
  set new_name [lindex $selection 1 ]
  set new_type [lindex $selection 0 ]

  set array($element) $new_name

  set name_list [concat $new_name [ GetTypeInfo $arrayname $element deflist ]]
  set type_list [concat $new_type [ GetTypeInfo $arrayname $element deftypelist ]]
  SetLabelList $arrayname $element $name_list  $type_list

#  set field_list [GetWidget $arrayname $element ]
#  foreach field $field_list {
#    $field.m add command -label "$new_name"  \
#      -command "UpdateDependentParams \"$new_name\" $arrayname  \
#                                    $element"
#  }

}

#----------------------------------------------------------------------
proc EnterLabel { arrayname ele } {
#----------------------------------------------------------------------
#d_sum Window for user to type column label to support 'Enter Label' option on columns menu
#d_arg arrayname Name of data array
#d_arg ele The array element for the column label
  upvar #0 $arrayname array
# Prompt user to enter name of label
# Add this label to the name and type list menu (using SetLabelList_
  if {[InputParamDialog "Enter MTZ label" "MTZ Label" $arrayname \
	   [list [list $ele "Enter Label" ]]  ]} {
    set type [ GetTypeInfo $arrayname $ele type ]
    SetLabelList $arrayname $ele $array($ele)  $type -append
  }
}

#--------------------------------------------------------------------------
proc CreateCadLabinLine { linein message filein label1 name1 label2
			  name2 label3 type args } {
#--------------------------------------------------------------------------
#d_sum Display the MTZ label selection line used in the Cad task interface
#d_desc See the Cad task interface for normal usage
#d_arg linein Output Tk frame id for the line
#d_arg message Message line which appears if cursor over this line
#d_arg filein Name of element in the task interface array which contains \
the name of the input MTZ file
#d_arg label1 Text to appear in the task interface line
#d_arg name1 Name of the element in the task interface array which contains \
the name of the input label
#d_arg label2 Text to appear in the task interface line
#d_arg name2 Name of the element in the task interface array which contains \
the name of the output label
#d_arg label3 Text to appear in the task interface line
#d_arg type The MTZ column type for the output column
#d_opt0 -checkbutton <elementname>
#d_opt1 Specify the name of an element in the task interface array \
which contains a logical variable and associate this with a checkbutton on \
the line

  upvar $linein line
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set include ""
  if { [set k [lsearch -exact $args "-checkbutton"]] > -1 } {
      incr k
      set include [lindex $args $k]
  }

  set fileline [GetWidget $arrayname $filein]
  set fileline [string range $fileline 0 [expr {[string length $fileline ] - 4} ] ]

  set file_status [CheckFileInput $arrayname $filein read ]

  set index [GetSystemVar current_index_counter]
  set underscore [string first "_" $index]
  set i2 [string range $index [ expr {$underscore + 1} ] end ]

  if { $include == "" } {
      CreateLine line  \
		message $message \
	        help labin \
                label $label1 \
                widget $name1 \
	        help labout \
                label $label2 \
                widget $name2 \
                label $label3 \
                help ctypin \
	        widget $type
  } else {
      CreateLine line  \
	        message "Check to select this column" \
                widget $include -toggleon\
		message $message \
	        help labin \
                label $label1 \
                widget $name1 \
	        help labout \
                label $label2 \
                widget $name2 \
                label $label3 \
                help ctypin \
	        widget $type
  }
  set array(INCLUDE_COLUMN,$index) 1
  
  set cmd "cad_update_labin $arrayname $index $name1 $name2 $type"
  set field [GetWidget $arrayname [Indxv $name1 $index] ]

  add_file_command $fileline "SetLabin $arrayname $filein \
                [Indxv $name1 $index] {} 
        $cmd
	add_command $field \"$cmd\""

  SetLabin $arrayname $filein [Indxv $name1 $index] {}
  if { ![ElementExists $arrayname [Indxv $name2 $index]] || \
		$array([Indxv $name2 $index]) == "" } { eval "$cmd" }
  add_command $field $cmd

}

#--------------------------------------------------------------------------
proc cad_update_labin { arrayname index name1 name2 type } {
#--------------------------------------------------------------------------
#d_sum Handler for CreateCadLabinLine to create menu of input column names
#d_desc This procedure is invoked when an input MTZ column is selected from \
menu.  The default values of the output column name and type are set to be \
the same as those of the input column. \
This procedure has an input 'index' which indicates which \
of the multiple column selection lines has been changed by the user. \
The procedure is complicated by the \
fact that the Cad task may have more than one input MTZ file and with \
multiple MTZ files then the 'index' parameter is 2-dimensional.  The \
procedure GetLabelList is called to get a list of the column names and \
types associated with this column selection line and the list of names \
is searched to find the index in the list of the column selected by \
user.  This index is then used to extract the correct column type from \
the list of columns.
#d_arg arrayname Name of task interface array
#d_arg index The number of the column selection line that is been updated
#d_arg name1 Name of the element in the task interface array which contains \
the name of the input label
#d_arg name2 Name of the element in the task interface array which contains \
the name of the output label
#d_arg type The MTZ column type for the output column
  upvar #0 $arrayname array
  global typedef

  set array([Indxv $name2 $index]) $array([Indxv $name1 $index])
  GetIndx [Indxv $name1 $index] root c1 c2

  if { $c2 > 0 } {
    set status [GetLabelList $arrayname [Indxv $root $c1 1] name_list type_list]
  } else {
    set status [GetLabelList $arrayname [Indxv $root 1] name_list type_list]
  }
  if {$status} {
    set pp [lsearch $name_list $array([Indxv $name1 $index]) ]
    if { $pp >= 0 } { 
      set ntype [lsearch [lindex $typedef(_MTZ_data_type_names) 2] \
	[lindex $type_list $pp] ]
      set array([Indxv $type $index]) \
       [lindex [lindex $typedef(_MTZ_data_type_names) 1] $ntype]
    }
  }
}


#--------------------------------------------------------------------------
proc CreateLaboutLine { linein message fileout label1 name1  args } {
#--------------------------------------------------------------------------
#d_sum  Draw a task interface line for user to specify output MTZ column name
#d_arg linein Output Tk frame id for the line
#d_arg message Message line which appears if cursor over this line
#d_arg fileout Name of element in the task interface array which contains \
the name of the output MTZ file
#d_arg label1 Text to appear in the task interface line
#d_arg name1 Name of the element in the task interface array which contains \
the name of the output labelpvar $linein line
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set label2 ""
  set help_pointer labout

   set n 0; set nargs -1
   if { [info exists args] } { set nargs [expr {[llength $args] - 1} ] }
   while { $n < $nargs } {
     set argument [lindex $args $n ]
     if { $argument == "-sigma" } {
        incr n; set label2 [lindex $args $n]
        incr n; set name2 [lindex $args $n]
     } elseif { $argument == "-toggle_display" } {
       incr n; set toggle_var [lindex $args $n ]
       incr n; set toggle_state [lindex $args $n ]
       incr n; set toggle_hitlist [lindex $args $n ]
     } elseif { $argument == "-help" } {
       incr n; set help_pointer [lindex $args $n ]
     }
     incr n
   }

  if { $label2 == "" } {

  CreateLine line  \
		message $message \
		help $help_pointer \
                label $label1 \
                widget $name1 \
                format "MTZlabel"
  } else {
  CreateLine line  \
		message $message \
		help $help_pointer \
                label $label1 \
                widget $name1 \
                label $label2 \
                widget $name2 \
                format "MTZlabel"
  }
  if { [info exists toggle_var ] } {
    toggle_frame_display $line $toggle_var  $toggle_state $toggle_hitlist
  }
}

#---------------------------------------------------------------------
proc CheckLabout { arrayname labout hklin } {
#---------------------------------------------------------------------
#d_sum Procedure to be called before running a task to check uniqueness of \
output MTZ column names
#d_desc Not currently used - code may not be reliable
#d_arg arrayname Name of task interface array
#d_arg labout Name of element in array which contains a list of the array \
elements which are output column labels.\
#d_arg hklin Array element which contains the name of the input MTZ file

  upvar #0 $arrayname array
  set file $array($hklin)
  set non_unique {}

  if { ![file exists $file ] } { return 1 } 
  if { [llength $array($labout)] <= 0 } { return 1 }

  set name_list ""
  GetMtzColumnByType $file "*" name_list type_list
# Can't get input labels?  Something wrong but don't abort
  if { [llength $name_list ] <= 0 } { return 1 }

  foreach label $array($labout) {
    set file_label $array($label)
    if { [lsearch $name_list $file_label] >= 0 } {
      append non_unique " $file_label"
    }
  }
  if { [llength $non_unique] == 0 } { return 1 }

    set action [ ChooseOptionDialog   "Non-Unique Labout" "Labout" \
    "The MTZ output labels $non_unique
already exist in the input file - the program may fail
It is suggested you abort this run and change the output labels before continuing" \
    [list "Abort Run" "Continue" ] ]

  if { $action == "Abort Run" } { return 0 }
  return 1
}

#-------------------------------------------------------------------
proc PackLabinLine { line args } {
#-------------------------------------------------------------------
#d_sum Pack, i.e. set the layout, of the task interface line to select MTZ columns
#d_desc This procedure is needed to complement CreateLabinLine.  When \
CreateLabinLine calls CreateLine with the line format 'MTZlabel' line \
procedure is used to layout the line.
#d_arg  Tk frame id for the line

#  puts "PackLabinLine line $line"

# forget any preexisting packing

  if { [winfo exists $line.mb2] } {
    set field "mb"
  } elseif {[winfo exists $line.e2] } {
    set field "e"
  } else {
    return
  }

  if { [winfo manager $line.[subst $field]2] == "pack" } { 
	pack forget $line.[subst $field]2 
  }
  set iftwo [winfo exist $line.l3 ]
  if { $iftwo } {
    if { [winfo manager $line.l3] == "pack"}  \
           {pack forget $line.l3; pack forget $line.[subst $field]4}
  }

  pack $line.l1 -side left
  place $line.[subst $field]2 -in $line -rely 0 \
		-relheight 0.9 -relwidth 0.40 \
                -relx 0.10

  if { $iftwo } {
    place $line.l3 -in $line -rely 0 -relheight 0.9 -relwidth 0.10 \
                  -relx 0.50
    place $line.[subst $field]4 -in $line -rely 0  \
		-relheight 0.9 -relwidth 0.40 \
                -relx 0.60
  }

  set cmd "pack $line -side top -fill x"
  foreach item $args {append cmd $item }
  eval "$cmd"

}
#d_index_title Extracting Data from Map Files

#------------------------------------------------------------------------
proc InitialiseMAPData { } {
#------------------------------------------------------------------------
#d_sum Initialise the MAP_file_data array with header info from \
the last selected input CCP4 map file.

   global MAP_file_data
   set MAP_file_data(LOADED) 0
   set MAP_file_data(FILE) ""
   set MAP_file_data(CELL) ""
   set MAP_file_data(GRID) ""
   set MAP_file_data(XYZLIM) ""
   set MAP_file_data(SPACE_GROUP_NAME) ""
   set MAP_file_data(SPACE_GROUP_NUMBER) ""

} 

#---------------------------------------------------------------------
proc ReadCCP4Map { file ttVar } {
#---------------------------------------------------------------------
#d_sum Read a CCP4 map file using mapdump and return program output
#d_arg file Input map file name
#d_arg ttVar Returned text output by mapdump program

  upvar $ttVar tt

  set log [FileJoin [GetDefaultDirPath TEMPORARY] \
        [file root [file tail $file]].dump ]
  set com [FileJoin [GetDefaultDirPath TEMPORARY] \
        [file root [file tail $file]].com ]
  DeleteFile $log
  WriteFile $com "/" -overwrite
  if { [Execute "[BinPath mapdump] MAPIN \"$file\"" $com program_status report -log $log] &&
    [ReadFile $log tt] } {
    set status 1
  } else {
    WarningMessage "Error extracting data from $file
This is probably not a valid map file
OR the CCP4 program mapdump is not accessible?"
    set status 0
  }
  DeleteFile $log
  DeleteFile $com
  return $status
}


#-------------------------------------------------------------------------
proc ExtractMAPData { file } {
#-------------------------------------------------------------------------
#d_sum Read header info from a CCP4 map file and save to MAP_file_data array
#d_arg file Input map file name
  global MAP_file_data

   if { ![file exists $file] } { 
    set MAP_file_data(LOADED) -1
    set MAP_file_data(FILE) $file
    return 0 
   }

   set changed [file mtime $file]
   if { [ElementExists MAP_file_data LOADED] && \
          $file == $MAP_file_data(FILE) && \
          $changed == $MAP_file_data(CHANGED) } {
      if { $MAP_file_data(LOADED)  == 1 } {
#     puts "Using old data "
        return 1
      } elseif { $MAP_file_data(LOADED)  == -1 } {
        return -2
      }
   }

   set MAP_file_data(LOADED) 0
   set MAP_file_data(FILE) $file
   set MAP_file_data(CHANGED) $changed

   if { ![ReadCCP4Map $file logtext ] } {
     set MAP_file_data(LOADED) -1
     return  -1
   }

   # Get the start and stop (XYZLIM)
   # The map may not be stored in X Y Z axis order, so first
   # extract data on the actual ordering
   # Code taken from GetMapHeader in utils/map_utils.tcl
   set line [ExtractFromText $logtext "Fast, medium, slow axes" 0 all ]
   set axes {}
   for { set i 5 } { $i < 8 } { incr i } { lappend axes [lindex $line $i ]}
   set xyzlim_line \
       [ExtractFromText $logtext "Start and stop" 0 all ]

   # Now we  have the axes order can work out the xyzlim
   set ll [llength $xyzlim_line]
   set MAP_file_data(XYZLIM) ""
   for { set i 0 } { $i < 3 } { incr i } {
     set j [lsearch $axes [lindex [list X Y Z] $i] ]
     set jj [expr {$ll - 6 + ($j * 2)}]
     lappend MAP_file_data(XYZLIM) [lindex $xyzlim_line $jj]
     lappend MAP_file_data(XYZLIM) [lindex $xyzlim_line [incr jj]]
   }
   
   set line \
       [ExtractFromText - "Grid" 0 all ]
   set ll [llength $line]; set MAP_file_data(GRID) ""
   for { set i [expr {$ll - 3}] } { $i < $ll } { incr i } {
     lappend MAP_file_data(GRID) [lindex $line $i]
   }


   set line \
       [ExtractFromText - "Cell dimensions" 0 all ]
   set ll [llength $line] ; set MAP_file_data(CELL) ""
   for { set i [expr {$ll - 6}] } { $i < $ll } { incr i } {
     lappend MAP_file_data(CELL) [lindex $line $i]
   }

   set MAP_file_data(SPACE_GROUP_NUMBER) [ExtractFromText -  "Space-group" 0 2 ]
   set MAP_file_data(SPACE_GROUP_NAME) \
     [GetSpaceGroupCode $MAP_file_data(SPACE_GROUP_NUMBER) ]


   set MAP_file_data(LOADED) 1
   set MAP_file_data(FILE) $file

#   foreach ele [array names MAP_file_data] {
#     puts "$ele $MAP_file_data($ele)"
#   }

   return 1
}

#d_index_title Extracting Data from PDB Files

#-------------------------------------------------------------------------
proc InitialisePDBData { } {
#-------------------------------------------------------------------------
#d_sum Initialise the PDB_file_data array which holds header parameters from \
the last selected input PDB file.

   global PDB_file_data
   set PDB_file_data(LOADED) 0
   set PDB_file_data(FILE) ""
   set PDB_file_data(CELL) ""
   set PDB_file_data(SPACE_GROUP_NAME) ""

}

#-------------------------------------------------------------------------
proc ExtractPDBData { file } {
#-------------------------------------------------------------------------
#d_sum Read header from PDB file and load params into global array PDB_file_data

  global PDB_file_data

   if { ![file exists $file] } {
    set PDB_file_data(LOADED) -1
    set PDB_file_data(FILE) $file
    return 0
   }

   set changed [file mtime $file]
   if { [ElementExists PDB_file_data LOADED] && \
          $file == $PDB_file_data(FILE) && \
          $changed == $PDB_file_data(CHANGED) } {
      if { $PDB_file_data(LOADED)  == 1 } {
#     puts "Using old data "
        return 1
      } elseif { $PDB_file_data(LOADED)  == -1 } {
        return -2
      }
   }

   if { ![ReadFile $file pdb_text] ||
    ![ExtractTextLine  "$pdb_text" ^CRYST 0 all line] } { return  -1 }

   set PDB_file_data(CELL) ""
   for  {set n 1 } { $n <= 6 } { incr n } {
     lappend PDB_file_data(CELL) [lindex $line $n]
   }
   set spacegp [string trim [string range $line 55 65]]
   set PDB_file_data(SPACE_GROUP_NAME) [GetCCP4SpaceGroup $spacegp]
   unset pdb_text

   return 1
}

#----------------------------------------------------------------------
proc GetCCP4SpaceGroup { spacegp } {
#----------------------------------------------------------------------
#d_sum  Return space group in CCP4 format
  global crystal_data

  if { [set ll [lsearch $crystal_data(SYM_STD_CODE) $spacegp]] >= 0 } {
    return [lindex $crystal_data(SYM_CODE) $ll]
  } else {
    return $spacegp
  }
}

#d_index_title Extracting Data from MTZ Files

#----------------------------------------------------------------------
proc SetMtzParamField { paramtype arrayname filename element } {
#----------------------------------------------------------------------
#d_sum Put data value from MTZ header into an array element
#d_arg paramtype Parameter type  - must one of the names of elements in \
MTZ_file_data array
#d_arg arrayname Name of data array
#d_arg filename Name of array element containing MTZ file name
#d_arg element Name of array element to receive data from MTZ

  upvar #0 $arrayname array

  set file [GetFullFileName0 $arrayname $filename]
  if { ![file exists $file]} { return }

  if { [GetMtzParam  $file  $paramtype  data] } {
    set array($element) $data
    set_field_colour $arrayname $element 1
  }
}


#-------------------------------------------------------------------------
proc GetMtzParam { file param dataVar } {
#-------------------------------------------------------------------------
#d_sum Return a specified data item from specified MTZ file
#d_arg file MTZ file name
#d_arg param Parameter type - must be one of the names of elements in \
MTZ_file_data array
#d_arg dataVar Variable with returned data value
  upvar $dataVar data
  global MTZ_file_data

# Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
       WarningMessage "ERROR extracting data from $file"
    }
    return $status
  }

  if { [ catch { set data $MTZ_file_data($param) } result ] } {
    return 0
  }

  return 1

}

#-------------------------------------------------------------------------
proc GetMtzParamFromDataset { file xtal dataset param dataVar } {
#-------------------------------------------------------------------------
#d_sum Return a specified data item from specified MTZ file
#d_desc A variation on GetMtzParam.
#d_arg file MTZ file name
#d_arg xtal A crystal in the MTZ file
#d_arg dataset A dataset in the MTZ file
#d_arg param Parameter type - must be one of the names of elements in \
MTZ_file_data array
#d_arg dataVar Variable with returned data value
  upvar $dataVar data
  global MTZ_file_data

  # Initialise
  set data {}

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return $status
  }
  # Return failure if there are no datasets
  set ndatasets $MTZ_file_data(NDATASETS)
  if { $ndatasets < 1 } {
    return 0
  }
  # Loop over datasets in the file to find the match
  for { set i 0 } { $i < $ndatasets } { incr i } {
    if { [lindex $MTZ_file_data(XNAMES) $i] == $xtal &&
         [lindex $MTZ_file_data(DNAMES) $i] == $dataset } {
      set data [lindex $MTZ_file_data($param) $i]
      return 1
    }
  }
  # Failed to find anything
  return 0
}

#-----------------------------------------------------------------------
proc GetMtzColumnResolution { file label maxresoVar minresoVar } {
#-----------------------------------------------------------------------
#d_sum Return the maximum and minimum resolution for an MTZ column.
#d_desc The resolution values are given in Angrstroms. Returns 1 on \
success, 0 on failure.
#d_arg file MTZ file name
#d_arg label MTZ column label
#d_arg maxresoVar Variable returned with maximum resolution
#d_arg minresoVar Variable returned with minimum resolution
  global MTZ_file_data

  # Initialise
  upvar $maxresoVar maxreso
  upvar $minresoVar minreso
  set maxreso ""
  set minreso ""

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return 0
  }

  # Look up the column name
  if { [set k [lsearch $MTZ_file_data(STATISTICS_COLUMNS) $label]] < 0 } {
      # Column not found
      return 0
  }
  set maxreso [lindex $MTZ_file_data(DRESOLUTION_MAX) $k]
  set minreso [lindex $MTZ_file_data(DRESOLUTION_MIN) $k]
  return 1
}

#-----------------------------------------------------------------------
proc GetMtzDatasetFromLabel { file label xtalVar datasetVar} {
#-----------------------------------------------------------------------
#d_sum Return the parent dataset for the specified label
#d_desc The parent "dataset" consists of an MTZ crystal-dataset \
pair. This procedure returns 1 on success (the parent dataset is \
identified) and 0 on failure (no parent is identified).
#d_arg file MTZ file name
#d_arg label MTZ column label
#d_arg xtalVar Variable returned with parent crystal name
#d_arg datasetVar Variable returned with parent dataset name
  upvar $xtalVar    parent_xtal
  upvar $datasetVar parent_dataset

  # Initialise
  set parent_xtal ""
  set parent_dataset ""

  # Get a list of xtals
  set xtals [GetMtzXtals $file]
  if { [llength $xtals] > 0 } {
    # For each xtal, get datasets
    foreach xtal $xtals {
      set datasets [GetMtzDatasetsInXtal $file $xtal]
      if { [llength $datasets] > 0 } {
        # For each dataset, get column labels
        foreach dataset $datasets {
          set columns [GetMtzColsInDataset $file $xtal $dataset]
          # Look for the requested column
	  if { [lsearch $columns $label] > -1 } {
            # Found the label
	    set parent_xtal $xtal
            set parent_dataset $dataset
            # Return success
            return 1
          }
        }
      }
    }
  }
  # Failed to find the parent dataset - return failure
  return 0
}

#-----------------------------------------------------------------------
proc GetMtzXtals { file } {
#-----------------------------------------------------------------------
#d_sum Return list of crystal names in an MTZ file
#d_arg file MTZ file name
  global MTZ_file_data

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return {}
  }
  # Return failure if there are no datasets
  set ndatasets $MTZ_file_data(NDATASETS)
  if { $ndatasets < 1 } {
    return {}
  }
  # Sort the XNAMES list and return only the unique items i.e.
  # no duplicates 
  return [lsort -unique $MTZ_file_data(XNAMES)]
}

#-----------------------------------------------------------------------
proc GetMtzDatasetsInXtal { file xtal } {
#-----------------------------------------------------------------------
#d_sum Return a list of the datasets associated with a crystal in an \
MTZ file
#d_arg file MTZ file name
#d_arg xtal Crystal name
  global MTZ_file_data

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return {}
  }
  # Return failure if there are no datasets
  set ndatasets $MTZ_file_data(NDATASETS)
  if { $ndatasets < 1 } {
    return {}
  }
  # Get a list of dataset names belonging to this crystal
  set i -1; set datasets {}
  foreach xname $MTZ_file_data(XNAMES) {
    incr i
    if { $xtal == $xname } {
      lappend datasets [lindex $MTZ_file_data(DNAMES) $i]
    }
  }
  # Sort and return unique list
  return [lsort -unique $datasets]
}

#-----------------------------------------------------------------------
proc GetMtzColsInDataset { file xtal dataset } {
#-----------------------------------------------------------------------
#d_sum Return a list of the columns in a dataset in an MTZ file
#d_arg file MTZ file name
#d_arg xtal Crystal name
#d_arg dataset Dataset name
  global MTZ_file_data

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return {}
  }

  # In an unmerged MTZ file, datasets are associated with batches rather
  # than columns, so this procedure is not appropriate
  if {$MTZ_file_data(NBATCHES) != "" } { return {} }

  # Try to sort out which columns belong to each dataset
  # (A dataset is uniquely defined by xtal and dataset name)
  # Some things to remember:
  # 1. HKL_ASSOC gives the associated dataset ids for HKL cols
  # 2. ASSOC gives the associated dataset ids for the remaining cols

  # NB Some files don't appear to have any associations (e.g. batch files?)
  if { [llength $MTZ_file_data(HKL_ASSOC)] < 1 } {
      puts "GetMtzColsInDataset: no column to dataset associations found"
      return {}
  }
  # Get the set id for the named xtal/dataset combo
  set i 0; set setid -1
  foreach xname $MTZ_file_data(XNAMES) dname $MTZ_file_data(DNAMES) {
    if { $xname == $xtal && $dname == $dataset } {
      set setid [lindex $MTZ_file_data(SETID) $i]
    }
    incr i
  }
  if { $setid < 0 } {
    puts "GetMtzColsInDataset: dataset \"$xtal / $dataset\" not found"
    return {} 
  }
  # Loop over all columns and collect those with this setid
  set i 4; set cols {}
  foreach assoc $MTZ_file_data(ASSOC) {
    if { $assoc == $setid } {
      lappend cols $MTZ_file_data($i,NAME)
    }
    incr i
  }
  # Return list
  return $cols
}

#-------------------------------------------------------------------------
proc MtzColSameDataset { file col1 col2 } {
#-------------------------------------------------------------------------
#d_sum Determine whether two columns belong to the same dataset
#d_desc Return 1 if the parent dataset and crystal names for each \
label match, and 0 if not.
#d_arg file MTZ file
#d_arg col1 Label of the first column in the comparison
#d_arg col2 Label of the second column
    if {![GetMtzDatasetFromLabel $file $col1 xtal1 dataset1]} {
	set xtal1 ""
	set dataset1 ""
    }
    if {![GetMtzDatasetFromLabel $file $col2 xtal2 dataset2]} {
	set xtal2 ""
	set dataset2 ""
    }
    if { $dataset1 == $dataset2 && $xtal1 == $xtal2 } {
	return 1
    }
    return 0
}

#-----------------------------------------------------------------------
proc GetMtzAllCols { file } {
#-----------------------------------------------------------------------
#d_sum List all column labels in an MTZ file
#d_arg file MTZ file name
  global MTZ_file_data

  # Make sure the loaded MTZ data is for the required MTZ file
  set status [ExtractMTZData $file]
  if { $status <= 0 } {
    if { [file exists $file] } {
      WarningMessage "ERROR extracting data from $file"
    }
    return {}
  }
  set cols {}
  if { $MTZ_file_data(NCOLS) > 0 } {
    for { set i 1 } { $i <= $MTZ_file_data(NCOLS) } { incr i } {
      lappend cols $MTZ_file_data($i,NAME)
    }
  }
  return $cols
}

#-------------------------------------------------------------------------
proc GetMtzColType { file label } {
#-------------------------------------------------------------------------
#d_sum Return MTZ column type corresponding to a specific label
#d_desc Returns the column type taken from the file, or an empty \
string if no match to the supplied label is found in the file.
#d_desc Required by GroupMtzCols.
#d_arg file  MTZ file
#d_arg label MTZ column label
    global MTZ_file_data

    # Ensure we have the correct file
    set status [ExtractMTZData $file]
    if { $status <= 0 } { return $status }
 
    for {set i 1 } { $i <= $MTZ_file_data(NCOLS)} {incr i } {
	if { [StringSame $MTZ_file_data($i,NAME) $label] } {
	    # Matched the name - return the type
	    return $MTZ_file_data($i,TYPE)
	}
    }
    # No match
    return ""
}

#-------------------------------------------------------------------------
proc GroupMtzCols { file col_list { nlabels 4 } } {
#-------------------------------------------------------------------------
#d_sum Group a list of MTZ columns by type
#d_desc This procedure is used to group the supplied list of MTZ columns \
according to their type.
#d_desc It returns a list of lists, each sublist containing a group of \
labels. For mean structure factor amplitudes (type F), mean intensities \
(type J), E-values (type E) and anomalous differences (type D), the \
groupings returned will be pairs based on value-sigma. For phases (type P) \
the groupings will be pairs based on phases-weight.
#d_desc For F(+)/F(-) and I(+)/I(-) the groupings will sets of four columns.
#d_desc For Hendrickson-Lattman coefficients the grouping will also be a \
set of four columns.
#d_desc For situations where there are F/Phi pairings, additional "groups" \
(consisting of the single F and the single Phi) may also appear. 
#d_desc This procedure assumes strict typing. Columns for which no matching \
sigma etc is expected or found, will be returned in the list as a single \
item.
#d_desc The heuristic algorithm is as follows:
#d_desc 1. Go through the column list once, attempting to group columns that \
appear in sequence in the list (for example, "F SIGF" or "I(+) SIGI(+) I(-) \
SIGI(-)"). This results in a list of groups, with "ungrouped" labels assigned \
to "groups" of one.
#d_desc 2. Check the groups for those containing either single F-type or \
single P-type columns, and try to merge them into F-P pairs.
#d_desc 3. Look for mistyped Freidel pairs of amplitudes (e.g. F(+) which \
is typed as "F" instead of "G") and try to assemble these into groups of \
four labels. (The identification is based on the names having either "(+)" or \
"(-)" components.)
#d_desc 4. Look for anomalous differences (type "D") that should be matched \
with labels of type "F".
#d_arg file     MTZ file
#d_arg col_list List of column names (MTZ labels)
#d_arg nlabels  Maximum number of labels in a group (default is 4)

    set group_list {}

    # Make a list of corresponding types
    set col1_list $col_list
    set type_list {}
    foreach col $col1_list {
	lappend type_list [GetMtzColType $file $col]
    }

    # First sweep: try to column groups that appear as groups 
    #in the list of columns

    foreach col $col1_list {

	if { [set j [lsearch -exact $col1_list $col]] > -1 } {

	    # Fetch the type
	    set type [lindex $type_list $j]
	    # Initialise group for this column
	    set partial_list $col

	    # Remove this column from the lists
	    set col1_list [lreplace $col1_list $j $j]
	    set type_list [lreplace $type_list $j $j]

	    switch -regexp $type {

                F {
		    # F - look for sigma Q, D, Q
		    set match_types [list Q D Q]
		}
		J|D|E {
		    # J,D,E - look for sigma Q
		    set match_types [list Q]
		}
		G {
		    # G - look for sigma L, G, L
		    set match_types [list L G L]
		}
		K {
		    # K - look for sigma M, K, M
		    set match_types [list M K M]
		}
		P {
		    # P - look for weight W
		    set match_types [list W]
		}
		A {
		    # A - look for HLs A, A, A
		    set match_types [list A A A]
		}
		default {
		    # Ungrouped type - ignore
		    set match_types {}
		}
	    }

	    # Truncate the list based on the maximum
	    # number requested per group
	    if { [llength $match_types] > [expr $nlabels - 1]} {
		set match_types [lrange $match_types 0 \
				     [expr $nlabels - 2]]
	    }

	    # Look for matching columns in next position only
	    set k $j
	    foreach type1 $match_types {
		if { $type1 == [lindex $type_list $k] } {
		    # Next column matches required type
		    set colk [lindex $col1_list $k]
		    # Check that the datasets match
		    if { [MtzColSameDataset $file $col $colk] } {
			# Same dataset
			lappend partial_list [lindex $col1_list $k]
			set col1_list [lreplace $col1_list $k $k]
			set type_list [lreplace $type_list $k $k]
		    } else {
			# Second label is from a different dataset
			# Break
			break
		    }
		} else {
		    # Failed to find a match - break
		    break
		}
	    }

	    # Add to the list of groups
	    lappend group_list $partial_list
	}
    }

    # Post processing for special cases
    set empty_groups 0

    # Look for single F's and single P's and create an additional
    # merged group if they are in the same dataset
    # Only attempt the pairing if groups of 2 or more labels
    # are requested
    if { $nlabels > 1 } {
      for { set i 0 } { $i < [expr [llength $group_list] - 1] } { incr i } {
        set group [lindex $group_list $i]
        if { [llength $group] == 1 && \
		 [GetMtzColType $file [lindex $group 0]] == "F" } {
	    set coli [lindex $group 0]
	    for { set j [expr $i+1] } { $j < [llength $group_list] } { incr j } {
		set group [lindex $group_list $j]
		if { [llength $group] == 1 && \
			 [GetMtzColType $file [lindex $group 0]] == "P" } {
		    set colj [lindex $group 0]
		    if { [MtzColSameDataset $file $coli $colj] } {
			# Same dataset
			# Matched labels - make a new group by
                        # merging these groups
			lappend group_list \
			    [concat [lindex $group_list $i] \
				 [lindex $group_list $j]]
			# Don't check any more in inner loop
			break
		    }
		}
	    }
	}
      }
    }

    if { $nlabels == 4 } {
	# Look for mis-typed Friedel pairs (type F instead of G)
	# In this case we expect that the names of the groups will
	# differ only in the + and -'s
	set checkgrps {}
	# Mark groups of F's that contain (+) or (-) in their names
	foreach group $group_list {
	    set chk ""
	    if { [llength $group] == 2 } {
		if { [GetMtzColType $file [lindex $group 0]] == "F" && \
			 [GetMtzColType $file [lindex $group 1]] == "Q" } {
		    if { ![regsub -- "\[\+\]|\[\-\]" \
			      [lindex $group 0] "" chk] } { 
			set chk "" 
		    }
		}
	    }
	    lappend checkgrps $chk
	}
	if { [llength $checkgrps] > 0 } {
	    # Examine marked groups to see if they should be merged
	    set ngroups [llength $group_list]
	    for { set i 0 } { $i < [expr $ngroups - 1] } { incr i } {
		set coli [lindex [lindex $group_list $i] 0]
		if { [set chk [lindex $checkgrps $i]] != "" } {
		    for { set j [expr $i+1] } { $j < $ngroups } { incr j } {
			if { [set chk1 [lindex $checkgrps $j]] == $chk } {
			    # Check that the datasets match
			    set colj [lindex [lindex $group_list $j] 0]
			    if { [MtzColSameDataset $file $coli $colj] } {
				# Same dataset
				# Matched labels - merge these groups
				set group_list \
				    [lreplace $group_list $i $i \
					 [concat [lindex $group_list $i] \
					      [lindex $group_list $j]]]
				set group_list [lreplace $group_list $j $j ""]
				set checkgrps [lreplace $checkgrps $j $j ""]
				# Flag that there is an empty group to
				# remove later
				incr empty_groups
				continue
			    }
			}
		    }
		}
	    }
	}

	# If groups of four were requested then we should look for
	# Dano's not matched to their F's
	set checkgrps {}
	# Mark any groups of 2 labels which are F or D
	foreach group $group_list {
	    set chk ""
	    if { [llength $group] == 2 } {
		if { [GetMtzColType $file [lindex $group 0]] == "F" && \
			 [GetMtzColType $file [lindex $group 1]] == "Q" } {
		    set chk "F"
		}
		if { [GetMtzColType $file [lindex $group 0]] == "D" && \
			 [GetMtzColType $file [lindex $group 1]] == "Q" } {
		    set chk "D"
		}
	    }
	    lappend checkgrps $chk
	}
	# Examine marked groups to see if they should be merged
	if { [llength $checkgrps] > 0 } {
	    set ngroups [llength $group_list]
	    for { set i 0 } { $i < [expr $ngroups - 1] } { incr i } {
		if { [set type1 [lindex $checkgrps $i]] != "" } {
		    set coli [lindex [lindex $group_list $i] 0]
		    for { set j [expr $i+1] } { $j < $ngroups } { incr j } {
			if { [set type2 [lindex $checkgrps $j]] != "" } {
			    if { $type2 != $type1 } {
				# Possible pairing - check the datasets
				set colj [lindex [lindex $group_list $j] 0]
				if { [MtzColSameDataset $file $coli $colj] } {
				    # Merge these groups
				    set group_list \
					[lreplace $group_list $i $i \
					     [concat [lindex $group_list $j] \
						  [lindex $group_list $i]]]
				    set group_list [lreplace $group_list $j $j {} ]
				    set checkgrps [lreplace $checkgrps $j $j ""]
				    # Flag that there is an empty group to
				    # remove later
				    incr empty_groups
				    continue
				}
			    }
			}
		    }
		}
	    }
	}
    }

    # Remove any empty groups
    if { $empty_groups > 0 } {
	set new_list {}
	foreach group $group_list {
	    if { [llength $group] > 0 } {
		lappend new_list $group
	    }
	}
	set group_list $new_list
    }

    # End of post processing

    # Finished
    return $group_list
}

#--------------------------------------------------------------------------
proc InitialiseMTZData { } {
#--------------------------------------------------------------------------
#d_sum Initialise the MTZ_file_data array with header info from \
the last selected input MTZ file

   global MTZ_file_data
   set MTZ_file_data(LOADED) 0
   set MTZ_file_data(CHANGED) ""
   set MTZ_file_data(FILE) ""
   set MTZ_file_data(NBATCHES) ""
   set MTZ_file_data(NCOL) 0
   set MTZ_file_data(CELL) ""
   set MTZ_file_data(CELL_1) ""
   set MTZ_file_data(CELL_2) ""
   set MTZ_file_data(CELL_3) ""
   set MTZ_file_data(CELL_4) ""
   set MTZ_file_data(CELL_5) ""
   set MTZ_file_data(CELL_6) ""
   set MTZ_file_data(RESOLUTION_RANGE) ""
   set MTZ_file_data(RESOLUTION_MIN) ""
   set MTZ_file_data(RESOLUTION_MAX) ""
   set MTZ_file_data(SPACE_GROUP_NAME) ""
   set MTZ_file_data(SPACE_GROUP_NUMBER) ""
   set MTZ_file_data(SCALES_COLUMN) 0
   set MTZ_file_data(NDATASETS) ""
   set MTZ_file_data(SETID) ""
   set MTZ_file_data(PNAME) ""
   set MTZ_file_data(XNAME) ""
   set MTZ_file_data(DNAME) ""
   set MTZ_file_data(PNAMES) ""
   set MTZ_file_data(XNAMES) ""
   set MTZ_file_data(DNAMES) ""
   set MTZ_file_data(DCELL_1) ""
   set MTZ_file_data(DCELL_2) ""
   set MTZ_file_data(DCELL_3) ""
   set MTZ_file_data(DCELL_4) ""
   set MTZ_file_data(DCELL_5) ""
   set MTZ_file_data(DCELL_6) ""
   set MTZ_file_data(DWAVES) ""
   set MTZ_file_data(ASSOC) ""
   set MTZ_file_data(HKL_ASSOC) ""
   set MTZ_file_data(LATTICE) ""
   set MTZ_file_data(STATISTICS_COLUMNS) ""
   set MTZ_file_data(DRESOLUTION_MIN) ""
   set MTZ_file_data(DRESOLUTION_MAX) ""
} 

#---------------------------------------------------------------
proc ReadMTZ { file ttVar {mtzdmp_args HEADER } } {
#---------------------------------------------------------------
#d_sum Read an MTZ file using mtzdump and return program output
#d_arg file Input MTZ file name
#d_arg ttVar Returned text output by mtzdump program
#d_arg mtzdmp_args (Optional, default=HEADER) Arguments to the mtzdump program.
  upvar $ttVar tt
  set log [FileJoin [GetDefaultDirPath TEMPORARY] \
	[file root [file tail $file]].dump ]
  set com [FileJoin [GetDefaultDirPath TEMPORARY] \
        [file root [file tail $file]].com ]
  DeleteFile $log
  WriteFile $com "[subst $mtzdmp_args]\nEND" -overwrite
#  puts "ReadMTZ log $log"
  if { [Execute "[BinPath mtzdump] HKLIN \"$file\"" $com program_status report -log $log] &&
    [ReadFile $log tt] } {
    set status 1
  } else {
    # Failed to execute mtzdump and get sensible result
    # Check mtzdump can be found
    if { [FindExecutable mtzdump] == "" } {
      WarningMessage "Error extracting data from $file

The CCP4 program mtzdump is not accessible.
Please check your CCP4 setup."
    } else {
      # Problem with the file?
      # Give the user the option to look at the logfile to
      # help diagnose the error
      set action [ ChooseOptionDialog "Error reading MTZ file" "MTZ Error" \
    "CCP4i encountered an error when trying to extract
the data from $file

You can view the output from the mtzdump program
which may give an indication of the problem. Otherwise
you should dismiss this window." \
         [list "Continue" "View mtzdump output" ] \
         -default 1 ]
       if { "$action" != "Continue" } {
	   # Display the logfile
	   DisplayTextFile $log
       }
    }

    # Set status to indicate problem
    set status 0
  }
  DeleteFile $log
  DeleteFile $com
  return $status
}


#-------------------------------------------------------------------------
proc ExtractMTZData { file } {
#-------------------------------------------------------------------------
#d_sum Read header info from an MTZ file and save to MTZ_file_data array
#d_desc First, checks to see if file exists. Then checks to see if
#d_desc data has already been loaded. If the data has not been loaded,
#d_desc or the file has been changed on disk since loading, then the
#d_desc global array MTZ_file_data is initialised, and filled again
#d_desc from the file.
#d_arg file Name of MTZ file

   global MTZ_file_data

   if { ![file exists $file] } { 
    set MTZ_file_data(LOADED) -1
    set MTZ_file_data(FILE) $file
    return 0 
   }

   set changed [file mtime $file]


   if { [ElementExists MTZ_file_data LOADED] && \
          $file == $MTZ_file_data(FILE) && \
          $changed == $MTZ_file_data(CHANGED) } {
      if { $MTZ_file_data(LOADED)  == 1 } {
#     puts "Using old data "
        return 1
      } elseif { $MTZ_file_data(LOADED)  == -1 } {
        return -2
      }
   }

#  Initialise global array and fill again
   InitialiseMTZData
   set MTZ_file_data(LOADED) 0
   set MTZ_file_data(FILE) $file
   set MTZ_file_data(CHANGED) $changed
#   SetSystemVar MTZ_file_data_file ""

   set MTZ_file_data(NCOLS) 0

   if { ![ReadMTZ $file text {} ] } { 
     set MTZ_file_data(LOADED) -1
     return  -1
   }

#  Establish whether this is a merged or unmerged file
   set MTZ_file_data(NBATCHES) [ExtractFromText $text \
     "Number of Batches" 0 last ]

   set MTZ_file_data(NDATASETS) [ExtractFromText $text \
     "Number of Datasets" 0 last ]

   # Is NDATASETS a sensible value?
   if { ![regexp "\[0-9\]+" $MTZ_file_data(NDATASETS)] } {
     puts "ExtractMTZData: couldn't get sensible NDATASETS, setting to zero"
     set MTZ_file_data(NDATASETS) 0
   }
   
   if { $MTZ_file_data(NDATASETS) > 0 } {

     set MTZ_file_data(SETID) [ExtractFromText - "Dataset ID" \
        2 { 0 }]

     set MTZ_file_data(PNAMES) [ExtractFromText - "" \
        0 { 1 }]

     set MTZ_file_data(XNAMES) [ExtractFromText - "" \
	1 { 0 }]

     set MTZ_file_data(DNAMES) [ExtractFromText - "" \
	1 { 0 }]

     set MTZ_file_data(DCELL_1) [ExtractFromText - "" \
	1 { 0 }]
     set MTZ_file_data(DCELL_2) [ExtractFromText - "" \
	0 { 1 }]
     set MTZ_file_data(DCELL_3) [ExtractFromText - "" \
	0 { 2 }]
     set MTZ_file_data(DCELL_4) [ExtractFromText - "" \
	0 { 3 }]
     set MTZ_file_data(DCELL_5) [ExtractFromText - "" \
	0 { 4 }]
     set MTZ_file_data(DCELL_6) [ExtractFromText - "" \
	0 { 5 }]

     set MTZ_file_data(DWAVES) [ExtractFromText - "" \
	1 { 0 }]

     set n 1; while { $n < $MTZ_file_data(NDATASETS) } { incr n 
       lappend MTZ_file_data(SETID)  [ExtractFromText - "" 1 { 0 } ]
       lappend MTZ_file_data(PNAMES) [ExtractFromText - "" 0 { 1 } ]
       lappend MTZ_file_data(XNAMES) [ExtractFromText - "" 1 { 0 } ]
       lappend MTZ_file_data(DNAMES) [ExtractFromText - "" 1 { 0 } ]
       lappend MTZ_file_data(DCELL_1) [ExtractFromText - "" 1 { 0 } ]
       lappend MTZ_file_data(DCELL_2) [ExtractFromText - "" 0 { 1 } ]
       lappend MTZ_file_data(DCELL_3) [ExtractFromText - "" 0 { 2 } ]
       lappend MTZ_file_data(DCELL_4) [ExtractFromText - "" 0 { 3 } ]
       lappend MTZ_file_data(DCELL_5) [ExtractFromText - "" 0 { 4 } ]
       lappend MTZ_file_data(DCELL_6) [ExtractFromText - "" 0 { 5 } ]
       lappend MTZ_file_data(DWAVES) [ExtractFromText - "" 1 { 0 } ]
     }

     set MTZ_file_data(DNAME) [lindex $MTZ_file_data(DNAMES) 0]
     set MTZ_file_data(XNAME) [lindex $MTZ_file_data(XNAMES) 0]
     set MTZ_file_data(PNAME) [lindex $MTZ_file_data(PNAMES) 0]

     set MTZ_file_data(NCOLS) [ExtractFromText -  \
		"Number of Columns" 0 { 5 }]
   } else {

     set MTZ_file_data(NDATASETS) 0

     set MTZ_file_data(NCOLS) [ExtractFromText $text \
		 "Number of Columns" 0 { 5 }]
    
   }

   # Is NCOLS a sensible value?
   if { ![regexp "\[0-9\]+" $MTZ_file_data(NCOLS)] } {
     puts "ExtractMTZData: couldn't get sensible NCOLS, setting to zero"
     set MTZ_file_data(NCOLS) 0
   }

#  puts "NDATASETS $MTZ_file_data(NDATASETS)"
#  puts  "PNAMES $MTZ_file_data(PNAMES) DNAMES $MTZ_file_data(DNAMES)"

#   puts "NCOLS $MTZ_file_data(NCOLS)"

   set columns [ExtractFromText - "Column Labels" 2 all ]
   set len 1 
   while { $len > 0 } {
     set cc [ExtractFromText - "" 1 all ]
     if { [set len [llength $cc] ] > 0 } { set columns [concat $columns $cc] }
   }
   set types [ExtractFromText - "Column Types" 2 all ]
   set len 1; while { $len > 0 } {
     set cc [ExtractFromText - "" 1 all ]
     if { [set len [llength $cc] ] > 0 } { set types [concat $types $cc] }
   }

# Get the dataset association for each column (this is not given for unmerged file)

   if { $MTZ_file_data(NDATASETS) > 0 && $MTZ_file_data(NBATCHES) == "" } {
     set assoc [ExtractFromText - "Associated datasets" 2 all]
     set len 1; while { $len > 0 } {
       set cc [ExtractFromText - "" 1 all ]
       if { [set len [llength $cc] ] > 0 } { set assoc [concat $assoc $cc] }
     }
     set MTZ_file_data(HKL_ASSOC) [lindex $assoc 0]
     set MTZ_file_data(ASSOC) [lrange $assoc 3 end]
   }

   for {set i 1} {$i <= $MTZ_file_data(NCOLS)} {incr i} {
      set ii [expr {$i - 1} ]
      set MTZ_file_data($i,NAME) [lindex $columns $ii]
      set MTZ_file_data($i,TYPE) [lindex $types $ii]
   }

# For the benefit of scala check whether ther is a SCALES column
   if { [lsearch $columns SCALES] >= 0 } {
     set MTZ_file_data(SCALES_COLUMN) 1
   } else {
     set MTZ_file_data(SCALES_COLUMN) 0
   }


   set MTZ_file_data(CELL) \
       [ExtractFromText - "Cell Dimensions" 2 { 0 1 2 3 4 5}]
   set MTZ_file_data(CELL_1) [lindex $MTZ_file_data(CELL) 0]
   set MTZ_file_data(CELL_2) [lindex $MTZ_file_data(CELL) 1]
   set MTZ_file_data(CELL_3) [lindex $MTZ_file_data(CELL) 2]
   set MTZ_file_data(CELL_4) [lindex $MTZ_file_data(CELL) 3]
   set MTZ_file_data(CELL_5) [lindex $MTZ_file_data(CELL) 4]
   set MTZ_file_data(CELL_6) [lindex $MTZ_file_data(CELL) 5]

   set MTZ_file_data(RESOLUTION_RANGE) \
       [ExtractFromText -  "Resolution Range" 2 [list 0 1 3 5 ]]


   set MTZ_file_data(RESOLUTION_MIN) [lindex $MTZ_file_data(RESOLUTION_RANGE) 2]
   set MTZ_file_data(RESOLUTION_MAX) [lindex $MTZ_file_data(RESOLUTION_RANGE) 3]

   if { $MTZ_file_data(NBATCHES) != "" } {
     set MTZ_file_data(UNMERGED_SORTED) 0
   }
   set sort_line [ExtractFromText - ".ort .rder" 0 all]
   if { [regexp "no sort" $sort_line] } { 
     set sort_order [list 1 2 3 ]
   } else {
     set sort_order [ExtractFromText - "" 2 { 0 1 2 } ]
# test whether unmerged file is sorted
     if { $MTZ_file_data(NBATCHES) != "" } {
       set unmerged_sort_order [ExtractFromText - "" 0 { 0 1 2 3 4 } ]
       if { $unmerged_sort_order == [list 1 2 3 4 5 ] } {
         set MTZ_file_data(UNMERGED_SORTED) 1
       }
     }
   }
   if { $sort_order == [list 1 2 3 ] } {
     set MTZ_file_data(SORT_ORDER) "HKL"
   } elseif { $sort_order == [list 1 3 2 ] } {
     set MTZ_file_data(SORT_ORDER) "HLK"
   } elseif { $sort_order == [list  2 1 3] } {
     set MTZ_file_data(SORT_ORDER) "KHL"
   } elseif { $sort_order == [list 2 3 1] } {
     set MTZ_file_data(SORT_ORDER) "KLH"
   } elseif { $sort_order == [list 3 1 2 ] } {
     set MTZ_file_data(SORT_ORDER) "LHK"
   } elseif { $sort_order == [list 3 2 1] } {
     set MTZ_file_data(SORT_ORDER) "LKH"
   }

   set t0 [ExtractFromText -  "Space group =" 0 all ]
   if { $t0 != "" } {
     set MTZ_file_data(SPACE_GROUP_NAME) [string trim [lrange $t0 4 end-2] ']
     set t1 [lindex $t0 end]
     regsub -- {\)} $t1 "" MTZ_file_data(SPACE_GROUP_NUMBER)
   }

   set MTZ_file_data(LATTICE) [ExtractFromText - "Lattice Type" 0 4 ]

   # Get statistics for each column
   set line [ExtractFromText $text "OVERALL FILE STATISTICS" \
		 7 { 8 9 11 } ]
   set MTZ_file_data(STATISTICS_COLUMNS) [lindex $line 2]
   set MTZ_file_data(DRESOLUTION_MIN) [lindex $line 0]
   set MTZ_file_data(DRESOLUTION_MAX) [lindex $line 1]
   set n 1; while { $n < $MTZ_file_data(NCOLS) } {
       incr n 
       set line [ExtractFromText - "" 1 { 8 9 11 } ]
       lappend MTZ_file_data(STATISTICS_COLUMNS) [lindex $line 2]
       lappend MTZ_file_data(DRESOLUTION_MIN) [lindex $line 0]
       lappend MTZ_file_data(DRESOLUTION_MAX) [lindex $line 1]
   }

   set MTZ_file_data(LOADED) 1
   set MTZ_file_data(FILE) $file
#   SetSystemVar MTZ_file_data_file $file
   return 1
}

#-------------------------------------------------------------------
proc InitialiseParamFromFile { format } {
#-------------------------------------------------------------------
#d_sum Initialise the *_file_data arrays containing data from map/pdb/mtz file headers
#d_desc This is called when user loads a new def file into task and (possibly) \
changes the selected files from which header data has been loaded
#d_arg format pdb, mtz or map or 'all' for all three

  if { $format == "all" } {
    set arraylist [info globals "*_file_data" ]
#    puts "InitialiseParamFromFile arraylist $arraylist"
    if { [llength $arraylist] > 0 } {
      foreach arrayname $arraylist {
	set format [string range $arrayname 0 [ expr {[string first "_" $arrayname] - 1} ] ]
        set cmd ""
        append cmd Initialise $format Data
        catch { eval "$cmd" }
      }
    }
  } else {
    set cmd ""
    append cmd Initialise $format Data
    catch { eval "$cmd" }
  }
}

#-------------------------------------------------------------------------
proc GetMtzColumnList { file name_listin type_listin default_name_in 
                           select_type {priority_name_list ""} 
                           {name_list2in ""} {type_list2in "" }
                           {default_name2_in "" } { select_type2 "" }
                           {priority_name_list2 ""}
                           {name_list3in ""} {type_list3in "" }
                           {default_name3_in "" } { select_type3 "" }
                           {priority_name_list3 ""}
                           {name_list4in ""} {type_list4in "" }
                           {default_name4_in "" } { select_type4 "" }
                           {priority_name_list4 ""} } {
#-------------------------------------------------------------------------
#d_sum Return the labelled columns of a specified type and one default
#d_desc This procedure calls GetMtzGroupByType to recover groups of columns \
from the file, then searches the list for matching column groupings by type \
before looking for any column name which matches any of the priority name \
list input to CreateLabinLine. This procedure, itself, is just setting the \
default selected column that the user sees immediately after selecting an \
MTZ file.
#d_desc Although priority names can be specified for up to four columns, \
in practice due to the grouping mechanism it is likely that only the first \
will have any practical effect.
#d_desc This function returns the number of columns in name_listin on \
output, or zero if there was a problem.
#d_desc See also the docs for GetMtzColumnByType and GetMtzGroupByType.
#d_arg file Name of MTZ file for which info required
#d_arg name_listin Output. List of selected column names
#d_arg type_listin Output. List of the types of the selected columns
#d_arg default_name_in Output. The name of one default column
#d_arg select_type A list of one or more required column types
#d_arg priority_name_list A list of the preferred column names for the default
#d_arg name_listin2 Output. List of selected column names
#d_arg type_listin2 Output. List of the required column types
#d_arg default_name2_in Output. The name of one default column
#d_arg select_type2 Optional. A list of one or more required column types
#d_arg priority_name_list2 A list of the preferred column names for the default
#d_arg name_listin3 Output. List of selected column names
#d_arg type_listin3 Output. List of the required column types
#d_arg default_name3_in Output. The name of one default column
#d_arg select_type3 Optional. A list of one or more required column types
#d_arg priority_name_list3 A list of the preferred column names for the default
#d_arg name_listin4 Output. List of selected column names
#d_arg type_listin4 Output. List of the required column types
#d_arg default_name4_in Output. The name of one default column
#d_arg select_type4 Optional. A list of one or more required column types
#d_arg priority_name_list4 A list of the preferred column names for the default

  upvar $name_listin name_list1
  upvar $type_listin type_list1
  upvar $default_name_in default_name1
  set mode 1

  if { $name_list2in != "" } {
    upvar $name_list2in name_list2
    upvar $type_list2in type_list2
    upvar $default_name2_in default_name2
    set mode 2
  } else {
    set name_list2 ""
    set type_list2 ""
  }
  if { $name_list3in != "" } {
    upvar $name_list3in name_list3
    upvar $type_list3in type_list3
    upvar $default_name3_in default_name3
    set mode 3
  } else {
    set name_list3 ""
    set type_list3 ""
  }
  if { $name_list4in != "" } {
    upvar $name_list4in name_list4
    upvar $type_list4in type_list4
    upvar $default_name4_in default_name4
    set mode 4
  } else {
    set name_list4 ""
    set type_list4 ""
  }

  set result \
      [GetMtzGroupByType $file \
	   $select_type $select_type2 $select_type3 $select_type4 ]

  # The result should come back as a list with 2 elements
  if { [llength $result] != 2 } {
      return 0
  }

  # Extract the sublists and check we have the correct number
  # (should be equal to the value of mode)
  set master_name_list [lindex $result 0]
  if { [llength $master_name_list] != $mode } {
      return 0
  }
  set master_type_list [lindex $result 1]
  if { [llength $master_type_list] != $mode } {
      return 0
  }

  # Each of the master lists consists of sublists
  # Assign these to the upvar'ed variables
  for { set i 1 } { $i <= $mode } { incr i } {
      set name_list$i [lindex $master_name_list [expr $i - 1]]
      set type_list$i [lindex $master_type_list [expr $i - 1]]
  }

  # Now feed these into the assignment procedure
  if {[lindex $name_list1 0 ] != "" } {
    set default_name1 [lindex $name_list1 0 ]
    if { $mode >= 2 } { set default_name2 [lindex $name_list2 0 ] }
    if { $mode >= 3 } { set default_name3 [lindex $name_list3 0 ] }
    if { $mode == 4 } { set default_name4 [lindex $name_list4 0 ] }
    if { [llength $priority_name_list] != 0 } {
       foreach priority_name $priority_name_list {
         set pp -1; foreach name $name_list1 { incr pp
           if [string match "$priority_name" $name]  {
             set default_name1 $name
	     if { $mode >= 2 } { set default_name2 [lindex $name_list2 $pp ] }
	     if { $mode >= 3 } { set default_name3 [lindex $name_list3 $pp ] }
	     if { $mode == 4 } { set default_name4 [lindex $name_list4 $pp ] }
	     # Return the number of columns in name_list1
	     return [llength $name_list1]
           }
         }
       }
# If don't find label in $priority_name_list, try "$priority_name*"
# Thus HLC will find HLC and then HLC_mlphare1
       foreach priority_name $priority_name_list {
         set pp -1; foreach name $name_list1 { incr pp
           if [string match "$priority_name*" $name]  {
             set default_name1 $name
	     if { $mode >= 2 } { set default_name2 [lindex $name_list2 $pp ] }
	     if { $mode >= 3 } { set default_name3 [lindex $name_list3 $pp ] }
	     if { $mode == 4 } { set default_name4 [lindex $name_list4 $pp ] }
             # Return the number of columns in name_list1
             return [llength $name_list1]
           }
         }
       }
    }
  } else {
    set default_name1 "Unassigned"
    if { $mode >= 2 } { set default_name2 "Unassigned" }
    if { $mode >= 3 } { set default_name3 "Unassigned" }
    if { $mode == 4 } { set default_name4 "Unassigned" }
  }

  # Return the number of columns in name_list1
  return [llength $name_list1]
}

#-------------------------------------------------------------------------
proc GetMtzColumnByType { file select_type name_listin type_listin
                             {select_type2 "" } {name_listin2 ""} 
				{type_listin2 "" } } {
#-------------------------------------------------------------------------
#d_sum Return the labelled columns of a specified type found in an MTZ file
#d_desc This procedure calls ExtractMTZData which loads the MTZ header info \
into the MTZ_file_data array if that array does not already hold data for the \
specified file.  This procedure can output either one or two sets of selected \
columns.  The second set of columns is expected to be something like a sigma \
or a weight and a column in this set is expected to appear in the MTZ file \
immediately after a column from the first set.  If a column from the first \
selected set is followed in the MTZ file by a column of type unsuitable for \
the second set then the value 'Unassigned' is appended to the second set.
#d_arg file Name of MTZ file for which info required
#d_arg select_type A list of one or more column types which the selected \
columns may have.
#d_arg name_listin Output. List of selected column names
#d_arg type_listin Output. List of the types of the selected columns
#d_arg select_type2 Optional. A list of one or more column types which \
the selected columns may have.
#d_arg name_listin2 Output. List of selected column names
#d_arg type_listin2 Output. List of the types of the selected columns

  upvar $name_listin name_list
  upvar $type_listin type_list
  upvar $name_listin2 name_list2
  upvar $type_listin2 type_list2
  global MTZ_file_data

  set status [ExtractMTZData $file]
  if { $status <= 0 } { return $status } 


  set name_list {}
  set name_list2 {}
  if { $MTZ_file_data(NCOLS) <= 0 } { return 0 }

  set nlist2 [llength $select_type2]

# Think about probable required order of columns here - give
# priority to columns with type that is first on select_type and
# then give columns in order that they occur in the file

  set nret 0

  if { $select_type == "*" } {
    for {set i 1 } { $i <= $MTZ_file_data(NCOLS)} {incr i } {
      if { $MTZ_file_data($i,TYPE) != "H" } {
        lappend name_list $MTZ_file_data($i,NAME)
        lappend type_list $MTZ_file_data($i,TYPE)
        incr nret
      }
    }
    if { $nlist2 > 0 } {
      for {set j 1 } { $j <= $MTZ_file_data(NCOLS)} {incr j } {
        if { $MTZ_file_data($j,TYPE) != "H" } {
          lappend name_list2 $MTZ_file_data($j,NAME)
          lappend type_list2 $MTZ_file_data($j,TYPE)
        }
      }
    }
    return $nret
  }

  foreach type $select_type {
    for {set i 1 } {$i <= $MTZ_file_data(NCOLS) } {incr i  } {
      if { $MTZ_file_data($i,TYPE) == $type } {
        lappend name_list $MTZ_file_data($i,NAME)
        lappend type_list $MTZ_file_data($i,TYPE)
        incr nret
	set j [expr {$i + 1} ]
        if { $nlist2 > 0 &&  [ info exists MTZ_file_data($j,TYPE)]  } {
          set pp [lsearch $select_type2 $MTZ_file_data([subst $j],TYPE) ]
          if { $pp >= 0 } {
            lappend name_list2 $MTZ_file_data($j,NAME)
            lappend type_list2 $MTZ_file_data($j,TYPE)
          } else {
            lappend name_list2 "Unassigned"
            lappend type_list2 "X"
          }
        } else {
          lappend name_list2 "Unassigned"
          lappend type_list2 "X"
        }
      }
    }
  }
  return $nret
}

#-------------------------------------------------------------------------
proc GetMtzGroupByType { file select_type \
			     {select_type2 "" } \
			     {select_type3 "" } \
			     {select_type4 "" } } {
#-------------------------------------------------------------------------
#d_sum Return groups of MTZ columns based on the requested types
#d_desc Given a set of input column types this procedure tries to \
match them to the groups of columns that are returned from GroupMtzCols.
#d_desc The procedure returns a list of lists: two lists, the first of \
which is a list of groups and the second of which is a list of the \
corresponding types.
#d_desc This procedure is called from GetMtzColumnList.
#d_arg file         Name of the MTZ file
#d_arg select_type  MTZ column type for first column
#d_arg select_type2 MTZ column type for second column
#d_arg select_type3 MTZ column type for third column
#d_arg select_type4 MTZ column type for fourth column

    # Check how many labels the calling subprogram wants
    set select_types(0) $select_type
    set select_types(1) $select_type2
    set select_types(2) $select_type3
    set select_types(3) $select_type4
    set nlabels 0
    for { set i 0 } { $i < 4 } { incr i } {
	if { $select_types($i) != "" } { incr nlabels }
    }

    # Get a list of all columns in the MTZ file
    set col_list [GetMtzAllCols $file]

    # Group these
    set group_list [GroupMtzCols $file $col_list $nlabels]

    # Go through the groups one at a time
    set matching_groups {}
    foreach group $group_list {
	# See if the group matches the criteria
	set match 1
        set n [llength $group]
	for { set i 0 } { $i < $n } { incr i } {
	    set label [lindex $group $i]
	    set type [GetMtzColType $file $label]
	    if { $i >= $nlabels } {
		# There are no more labels in this group to match
		set match 0
		break
	    } elseif { $select_types($i) != "*" && \
		    [lsearch $select_types($i) $type] < 0 } {
		set match 0
	    }
	}
	if { $match } {
	    lappend matching_groups $group
	}
    }

    # Have we found any matching groups?
    set nmatch [llength $matching_groups]
    if { $nmatch > 0 } {
	for { set i 0 } { $i < $nlabels } { incr i } {
	    set name_list($i) {}
	    set type_list($i) {}
	}
	for { set i 0 } { $i < $nlabels } { incr i } {
	    foreach group $matching_groups {
		set n [llength $group]
		if { $i < $n } {
		    # The group has a value at this position
		    set col [lindex $group $i]
		    lappend name_list($i) $col
		    lappend type_list($i) [GetMtzColType $file $col]
		} else {
		    # The group doesn't have a value at this
		    # position
		    lappend name_list($i) "Unassigned"
		    lappend type_list($i) "X"
		}
	    }
	}
    } else {
	for { set i 0 } { $i < $nlabels } { incr i } {
	    set name_list($i) "Unassigned"
	    set type_list($i) "X"
	}
    }
    # Print again
    set master_name_list {}
    set master_type_list {}
    for { set i 0 } { $i < $nlabels } { incr i } {
	lappend master_name_list $name_list($i)
	lappend master_type_list $type_list($i)
    }
    return [list $master_name_list $master_type_list]
}

#d_index_title Accessing Standard Crystallographic Data

#------------------------------------------------------------------------------
proc GetSpaceGroupNumber { code } {
#------------------------------------------------------------------------------
#d_sum Return space group number from input space group code
#d_arg code space group code (or number will be handled OK)
  global crystal_data

  if { [lsearch $crystal_data(SYM_NUMBER) $code] >= 0 } { return $code }

  set code [string toupper $code] 

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $code]] >= 0 } {
    return  [lindex $crystal_data(SYM_NUMBER) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $code '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_NUMBER) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $code]] >= 0 } {
    return  [lindex $crystal_data(SYM_NUMBER) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $code '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_NUMBER) $i ]
  } else {
    return 0
  }
}

#------------------------------------------------------------------------------
proc GetSpaceGroupCode { number } {
#------------------------------------------------------------------------------
#d_sum Return CCP4 space group code from input space group number
#d_arg number space group number (or code will be handled OK)
# convert a symmetry number to a symmetry code
  global crystal_data

# search on number first
  if { [set i [lsearch $crystal_data(SYM_NUMBER) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_CODE) $i ]
  }

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_CODE) $i ]
  } 

  return 0
}

#------------------------------------------------------------------------------
proc GetSpaceGroupStdCode { number } {
#------------------------------------------------------------------------------
#d_sum Return PDB standard space group code from input space group number
#d_arg number space group number (or CCP4 code will be handled OK)
  global crystal_data

# search on number first
  if { [set i [lsearch $crystal_data(SYM_NUMBER) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_STD_CODE) $i ]
  }

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_STD_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_STD_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_STD_CODE) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_STD_CODE) $i ]
  } 

  return 0
}

#------------------------------------------------------------------------------
proc GetSpaceGroupNops { number } {
#------------------------------------------------------------------------------
#d_sum Return the number of symmetry ops for a space group
#d_arg number space group number (or CCP4/PDB code will be handled OK)
  global crystal_data

# search on number first
  if { [set i [lsearch $crystal_data(SYM_NUMBER) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_NOPS) $i ]
  }

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_NOPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_NOPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_NOPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_NOPS) $i ]
  } 

  return 0
}

#------------------------------------------------------------------------------
proc GetSpaceGroupLattice { number } {
#------------------------------------------------------------------------------
#d_sum Return the crystal lattice for a space group
#d_arg number space group number (or CCP4/PDB code will be handled OK)
  global crystal_data

# search on number first
  if { [set i [lsearch $crystal_data(SYM_NUMBER) $number]] >= 0 } {
      return  [lindex $crystal_data(LATTICE_LIST) \
		[lindex $crystal_data(SYM_LATTICE) $i ] ]
  }

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $number]] >= 0 } {
      return  [lindex $crystal_data(LATTICE_LIST) \
		[lindex $crystal_data(SYM_LATTICE) $i ] ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $number '] ]] >= 0 } {
      return  [lindex $crystal_data(LATTICE_LIST) \
		[lindex $crystal_data(SYM_LATTICE) $i ] ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $number]] >= 0 } {
      return  [lindex $crystal_data(LATTICE_LIST) \
		[lindex $crystal_data(SYM_LATTICE) $i ] ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $number '] ]] >= 0 } {
      return  [lindex $crystal_data(LATTICE_LIST) \
		[lindex $crystal_data(SYM_LATTICE) $i ] ]
  } 

  return 0
}


#------------------------------------------------------------------------------
proc GetSpaceGroupSymops { number } {
#------------------------------------------------------------------------------
#d_sum Return the symmetry ops for a space group as a list
#d_arg number space group number (or CCP4/PDB code will be handled OK)
  global crystal_data

  if { ![ElementExists crystal_data SYM_OPS] } { 
    ReadSymops [FileJoin [GetEnvPath CLIBD] symop.lib] 1
    if { ![ElementExists crystal_data SYM_OPS] } { return 0 }
  }

# search on number first
  if { [set i [lsearch $crystal_data(SYM_NUMBER) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_OPS) $i ]
  }

# We check in turn P212121, 'P212121' P 21 21 21 and 'P 21 21 21'
  if { [set i [lsearch $crystal_data(SYM_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_OPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_OPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) $number]] >= 0 } {
    return  [lindex $crystal_data(SYM_OPS) $i ]
  } elseif { [set i [lsearch $crystal_data(SYM_STD_CODE) [string trim $number '] ]] >= 0 } {
    return  [lindex $crystal_data(SYM_OPS) $i ]
  } 

  return 0
}

#-----------------------------------------------------------------
proc GetAsymUnit { spgp_code } {
#-----------------------------------------------------------------
#d_sum Return the CCP4 standard asymmetric unit
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number

  global crystal_data

  set spgp_no [GetSpaceGroupNumber $spgp_code]
  if { $spgp_no <= 0 } { return 0 }

  if { ![ElementExists crystal_data [Indxv ASYM $spgp_no] ] } {
    return ""
  } else {
    return $crystal_data([Indxv ASYM $spgp_no])
  }
}


#-----------------------------------------------------------------
proc GetLaueGroupNumber { spgp_code } {
#-----------------------------------------------------------------
#d_sum Return  an identifier for the laue group
#d_desc Will return 0 if not in the LAUE list from etc/crystal.lib file
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
  global crystal_data
#  puts "GetLaueGroupNumber spgp_code $spgp_code"

  set spgp_no [GetSpaceGroupNumber $spgp_code]
  if { $spgp_no <= 0 } { return 0 }

  for { set n 1 } { $n <= $crystal_data(N_LAUE) } { incr n } {
    if { [lsearch $crystal_data(LAUE,$n) $spgp_no] >= 0 } {
      return $n
    }
  }
  return 0
}

#-----------------------------------------------------------------
proc GetLaueGroup { laue_no } {
#-----------------------------------------------------------------
#d_sum Return a list of space groups in given Laue group
#d_arg laue_no Laue group number
  global crystal_data

  set tt {}
  foreach item $crystal_data(LAUE,$laue_no) {
    if { [GetSpaceGroupCode $item] != 0 } { lappend tt $item }
  }
  return $tt
}

#-----------------------------------------------------------------
proc GetPattersonSpaceGroup { spgp_code } {
#-----------------------------------------------------------------
#d_sum Return the Patterson space group for given space group
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
  global crystal_data
  set spgp [GetSpaceGroupNumber $spgp_code]
#  puts "GetPattersonSpaceGroup code $spgp_code spgp $spgp"
  if { ![ElementExists crystal_data [Indxv PATTERSON $spgp] ] } {
    return 0
  } else {
    return [lindex $crystal_data([Indxv PATTERSON $spgp]) 1]
  }
}


#-----------------------------------------------------------------
proc GetHarkerSections { spgp_code { modein 2 } } {
#-----------------------------------------------------------------
#d_sum Return the Harker sections for given space group (as Tcl list)
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
#d_arg modein Maximum number of sections returned (or all). Optional, default 2
  global crystal_data
  set spgp [GetSpaceGroupNumber $spgp_code]
  set retval ""
  set mode $modein
  if { [regexp all $mode] } { set mode end }
  if { ![ElementExists crystal_data [Indxv PATTERSON $spgp] ] } {
    return 0
  } else {
    set nharker [lindex $crystal_data([Indxv PATTERSON $spgp]) 1]
    for { set n 1 } { $n <= $nharker } { incr n } {
      lappend retval [lrange $crystal_data([Indxv HARKER $spgp $n]) 0 $mode]
    }
  }
  return $retval
}

#-----------------------------------------------------------------------
proc GetFFTSpaceGroups { spgpVar } {
#-----------------------------------------------------------------------
#d_sum Get a list of space groups supported by FFT program
#d_arg spgpVar Returned list of space groups
  upvar $spgpVar spgp
  global crystal_data

  if { [ElementExists crystal_data FFT] } {
    set spgp $crystal_data(FFT)
    return 1
  } else {
    set spgp ""
    return 0
  }
}

#-----------------------------------------------------------------------
proc GetChangeHandData { spgp_code space_groupVar cxVar } {
#-----------------------------------------------------------------------
#d_sum Get resultant space group and transformations fro changing hand of data
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
#d_arg space_groupVar Returned. Space group for data on changed hand
#d_arg cxVar Returned. Tcl list of cx,xy,cz where change of hand transforms x,y,z to cx-x,cy-y,cz-z
  global crystal_data
  upvar $space_groupVar space_group
  upvar $cxVar cx

  set spgp [GetSpaceGroupNumber $spgp_code]

  if { ![ElementExists crystal_data HAND] } { return 0 }

  foreach gp $crystal_data(HAND) {
    if { $spgp == [lindex $gp 0] } {
      set space_group [lindex $gp 1]
      set cx [lrange $gp 2 4]
      return 1
    }
  }
  return -1
}

#-----------------------------------------------------------------------
proc GetTwinData { spgp_code cxVar } {
#-----------------------------------------------------------------------
#d_sum Get the transformation(s) for twinned data
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
#d_arg cxVar Returned. A Tcl list of transformations of form -h,-k,l
  global crystal_data
  upvar $cxVar cx

  set cx {}

  if { ![ElementExists crystal_data TWIN] } { return 0 }
  set spgp [GetSpaceGroupNumber $spgp_code]

  foreach gp $crystal_data(TWIN) {
    if { $spgp == [lindex $gp 0] } {
      set cx [lrange $gp 1 end]
      return 1
    }
  }
  return 0
}

#-----------------------------------------------------------------------
proc GetLatticeFromSpaceGp { spacegp args } {
#-----------------------------------------------------------------------
#d_sum Return the lattice type from space group name ('cos shelx can not!)
#d_desc shelx number code: P = -1  I = -2  F = -4 A = -5  B = -6  C = -7
#d_arg spgp_code Space group code (CCP4 or PDB) or space group number
#d_opt0 -shelx
#d_opt1 Return the Shelx numbering code 

  set lat [string range $spacegp 0 0]
  if { $lat == "R" } { set lat P }

  if { [lsearch -regexp $args shel ] >= 0 } {
# return the shelx number code
# P = -1  I = -2  F = -4 A = -5  B = -6  C = -7
    set ilat [lsearch [list P I F A B C ] $lat] 
    if { $ilat >= 2 } { 
      return -[expr {$ilat + 2} ]
    } elseif { $ilat >= 0 } { 
      return -[expr {$ilat + 1} ]
    } else {
      return ""
    }
# just retun the single character code
  } else {
    return $lat
  }
}
