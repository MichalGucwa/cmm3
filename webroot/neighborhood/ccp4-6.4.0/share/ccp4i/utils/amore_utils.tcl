#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#===========================================================================
# CCP4 Interface amore_utils.tcl
#
#
# Utilities to use with amore:
#     Extracting params from log file
#     & loading into mr_database.def
#
#===========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title AMoRe Utilities (utils/amore_utils.tcl)
#d_intro Used in the amore run script to handle the .mr files and \
to interact with the mr model database.

#-------------------------------------------------------------------
proc amore_get_tabling_data { file  boxVar rcomVar comVar eulerVar } {
#-------------------------------------------------------------------
#d_sum Extract data from the amore tabling log file
#d_desc The position and extent of the model in the unit cell is \
extracted from the log file.  This procedure called from amore.script\
which then saves information in the amore database
#d_arg file Amore tabling log file
#d_arg boxVar Returned minimal box (a Tcl list of 3 elements)
#d_arg rcomVar Returned minimal Sphere (one value)
#d_arg comVar Returned centre of mass (a Tcl list of 3 elements)
#d_arg eulerVar Returned rotation applied to orient molecule (a Tcl list of 3 elements)

  upvar $boxVar box
  upvar $rcomVar rcom
  upvar $comVar com
  upvar $eulerVar euler

  ReadFile $file text
  set box [ExtractFromText $text "Minimal Box" 0 [list 3 4 5]]
  set rcom [ExtractFromText $text "Minimal Sphere" 0 2]
  set com [ExtractFromText - "Center of Mass" 0 [list 3 4 5]]
  set euler [ExtractFromText - "Rotation" 0 [list 2 3 4]]
#  puts "box $box"
#  puts "com $com"
#  puts "euler $euler"
#  puts "rcom $rcom"

}

#-------------------------------------------------------------------
proc amore_calc_model_cell { xtl_cell box radius cellVar irmaxVar } {
#-------------------------------------------------------------------
#d_sum Use the model extent and radius to calculate reasonable model cell
#d_desc Use formula that irmax should be the minimum of \
( 0.75 * smallest model box dimension) and \
( 0.5 * smallest xtl cell dimension)
#d_arg xtl_cell The cystal cell lengths
#d_arg box The extent of the model
#d_arg radius The minimal sphere enclosing the model
#d_arg cellVar Returned estimated model cell
#d_arg irmaxVar Returned the proposed radius for the integration sphere

  upvar $cellVar cell
  upvar $irmaxVar irmax

#  set min_rad 100000.0
#  foreach dim $box { if { $dim < $min_rad } { set min_rad $dim } }
#  set irmax [expr 0.75 * $min_rad ]
  set irmax [expr 0.8 * $radius]
  foreach cell_length $xtl_cell { 
    set dim [expr $cell_length / 2.0 ]
    if { $dim < $irmax } { set irmax $dim } 
  }
  set cell ""
  foreach bx $box {
    lappend cell [expr $bx + $irmax + 5.0 ]
  }
#  puts "cell $cell"
}

#---------------------------------------------------------------------
proc amore_get_log_solution { mode model_list log_file \
	solution_file args } {
#---------------------------------------------------------------------
#d_sum Extract solutions from log file
#d_desc Will find rotation/translation and fitting solutions and writes to\
the CCP4i 'mr' file
#d_arg mode Should be rot, tra, fit, shift or self.
#d_arg model_list A list of the models used in this run of Amore - indicates \
the number of sollution lines make up one solution
#d_arg log_file name of input log file
#d_arg solution_file Name of output 'mr' solution file
#d_opt0 -append
#d_opt1 Append new solutions to an existing file
#d_opt0 -symmetry spacegroup
#d_opt1 Specify spacegroup to write into header
#d_opt0 -resolution res_max res_min
#d_opt1 Specify resolution limits to write into header
#d_opt0 -cell a b c alpha beta gamma
#d_opt1 Specify cell parameters to write into header

  global job_params

  # Initialise
  set file_mode w
  set symmetry ""
  set cell {}
  set resolution {}

  # Process args
  for { set i 0 } { $i < [llength $args] } { incr i } {
    set arg [lindex $args $i]
    switch -regexp -- $arg {
	append {
	    set file_mode "a+"  
	}
	symm {
	    # -symmetry spacegroup
	    incr i
	    if { $i < [llength $args] } { set symmetry [lindex $args $i] }
	}
	reso {
	    # -resolution resmax resmin
	    set resolution {}
	    for { set j 0 } { $j < 2 } { incr j } {
		incr i
		if { $i < [llength $args] } {
		    lappend resolution [lindex $args $i]
		}
	    }
	    if { [llength $resolution] != 2 } { set resolution {} }
	}
	cell {
	    # -cell a b c alpha gamma beta
	    set cell {}
	    for { set j 0 } { $j < 6 } { incr j } {
		incr i
		if { $i < [llength $args] } {
		    lappend cell [lindex $args $i]
		}
	    }
	    if { [llength $cell] != 6 } { set cell {} }
	}
    }
  }
    
  if { ![ReadFile $log_file text] } {
    WriteToLog "Can not open temporary log file $log_file to extract solutions"
    return 0
  }
  set tf_sol ""
  set isol 0

# extract solution lines from log_file
# first get to somewhere just before where solutions start
  set nsol 0
  switch -regexp -- $mode  \
  rot {
#    set sol_line [ExtractFromText $text ROTING 0 all]
    set sol_line [ExtractFromText $text "ITAB  ALPHA" 0 all]
  } tra {
    set sol_line [ExtractFromText $text "Translation solutions" 0 all]
#    set sol_line [ExtractFromText $text "posiciones finales" 0 all]
  } fit {
    set nmol [ExtractFromText $text "FINAL POSITIONS" 1 0]
    if { $nmol == "" } { 
      WriteToLog "ERROR: FINAL POSITIONS not found in log file - can not create MR file"
      return 0
    }
    
  } shift {
    set sol_line [ExtractFromText $text "SOLUTION" 0 all]
  } self {
    set sol_line [ExtractFromText $text "SELF:" 0 all]
  }

  set sol_list ""
  set hash_sol_list ""
  
# Look for the non-shifted solutions 
  if { ![regexp shift $mode] } {
    set continue 1
    while { $continue } {
      set sol_line [string trim  [ExtractFromText - SOLUT 0 all]]
      if { [regexp FRAGMENT $sol_line] } { 
        set mode shift
        set continue 0
      } elseif { $sol_line == "" } {
        set continue 0
      } elseif { [regexp {^SOLUT_} $sol_line] } {
# In translation mode the less favoured solutions are automatically
# commented out
        lappend hash_sol_list "#$sol_line"
      } elseif { [regexp {^SOLUTIONTF} $sol_line] } {
         if { [regexp {^SOLUTIONTF1 } $sol_line ] } {
           incr nsol
           if { $tf_sol != "" } { lappend sol_list "$tf_sol" }
            set tf_sol "SOLUTIONTF1_[format %-3s $nsol]"; append tf_sol [string range $sol_line 12 end]
         } else {
            append tf_sol "\n[lindex $sol_line 0]_[format %-3s $nsol]" [string range $sol_line 12 end]
         }
      } elseif { [regexp fit $mode] }  {
        incr isol
        if { $isol == 1 } { incr nsol } else { append tf_sol "\n" }
        append tf_sol "[lindex $sol_line 0 ][subst $isol]_[format %-3s $nsol]" [string range $sol_line 12 end] 
        if { $isol == $nmol } { 
          lappend sol_list $tf_sol
          set tf_sol ""
          set isol 0
        }
      } else {
        incr nsol
        lappend sol_list $sol_line
      }
    }
    if { $tf_sol != "" } { lappend sol_list $tf_sol }
  }
  if [regexp shift $mode] {
    set continue 1
    while { $continue } {
      set sol_line [string trim  [ExtractFromText - SOLUT 0 all]]
      if { $sol_line == "" } {
        set continue 0
      } elseif { [lindex $sol_line 2] == $im } {
        incr nsol
# change the text in the line so start with one keyword
        lappend sol_list "SHIFT_SOLUTION [lrange $sol_line 2 end]"
      }
    }
  }

  set order {}
  if [regexp shift|tran $mode] {
    set score_list ""
    foreach sol $sol_list {
      set line [lindex [split $sol \n] end]
#      puts "line $line"
      lappend score_list [lindex $line 8]
    }
    if { [llength $score_list] <= 0 } { return 0 }
    sortorder $score_list order "-real -decreasing"
  } else {
    set n -1; foreach sol $sol_list { incr n; lappend order $n }
  }


# Open a separate solution file for each model
  if { ![OpenFile $solution_file f $file_mode] } {
    WriteToLog "ERROR attempting to open solution file $solution_file"
    return
  }
  if [regexp w $file_mode] {
    set line1 "MR $mode"
    foreach model $model_list { append line1 " " $model }
    WriteIdentifier $f "$line1" PROJECT  {} JOB_ID {}
    # Add symmetry, cell, resoln info if supplied
    # This mimics the style of header comments written by
    # the WriteIdentifer command
    if { $symmetry != "" } { puts $f "#CCP4I SYMMETRY $symmetry" }
    if { [llength $cell] == 6 } {
	set line "#CCP4I CELL"
	foreach param $cell { append line " $param" }
	puts $f $line
    } 
    if { [llength $resolution] == 2 } {
	set line "#CCP4I RESOLUTION"
	foreach param $resolution { append line " $param" }
	puts $f $line
    }
  }

  foreach ord $order { puts $f [lindex $sol_list $ord] } 
  if {[llength $hash_sol_list] > 0 } {
    foreach sol $hash_sol_list { puts $f "$sol" } 
  }
  CloseFile $f
  WriteToLog "  $nsol solutions found in Amore log file for models $model_list
Saved in $solution_file"

  return 1
}

#---------------------------------------------------------------------------
proc amore_update_database { def_file model_title update_list args } {
#---------------------------------------------------------------------------
#d_sum  Update the mr_database.def file
#d_desc Data extracted from log files is saved in the amore database. \
#d_arg def_file name of the amore mr database file
#d_arg model_title Name of the model in the mr database
#d_arg update_list List of paramters in name & value pairs
#d_opt0 -noreport
#d_opt1 Do not report  progress to log file

  global typedef
  global md

  set report 1
  if [regexp -- -noreport $args] { set report 0 }

  if { $report } {WriteToLog  \
"Saving parameters from Amore to the amore model database file 
$def_file" -nofoot }

  source [SearchPath TOP etc types.def]
  InitialiseArray [SearchPath TOP tasks mr_database.def ] md mr_database 

  if { ![InitialiseArray $def_file md mr_database ] } { 
    WriteToLog "ERROR Could not read $def_file
Aborting saving parameters  to amore model database" -nohead
    return 0 }

  if { ![regexp SaveArray [info procs SaveArray]] } { 
    source [SearchPath TOP src utils.tcl]
  }
  
  set n_model 0
  for { set n 1 } { $n <= $md(N_MODELS) } { incr n } {
    if [StringSame $model_title $md(MODEL_TITLE,$n)] { break }
  }

  if { $n > $md(N_MODELS) } { 
    WriteToLog "ERROR could not find model called $model_title in database" \
	-nofoot
    return 0 
  } elseif { $report } {
    WriteToLog "Saving data for model $model_title" -nohead -nofoot
  }

  foreach item $update_list {

# Each item should have name and value pair
    set name [lindex $item 0]
    set value [lindex $item 1]

#    puts "amore_update_database $name $value"

# If there is third component then use it as an index
# - increment the index and assign value 
    if { [llength $item] > 2 } { 

      set counterVar ""; append counterVar [lindex $item 2] , $n
      incr md($counterVar)
      set ele ""; append ele $name , $n _ $md($counterVar)
      set md($ele) $value

    } elseif { [llength $value] > 1 } {
      set i 0; foreach v $value { 
        incr i; set ele "" ; append ele $name _ $i , $n
        if { ![ElementExists md $ele ] || \
		![IfSet $md($ele)] } {set md($ele) $v }
      }

    } else {
      set ele "" ; append ele $name , $n
      if { ![ElementExists md $ele ] || \
	![IfSet $md($ele)] } { set md($ele) $value }
    }
  }
  if { ![ReadFile $def_file text -split] } {  return 0 }


  amore_block_mr_database 1

  set backup $def_file.amore_utils_backup
  DeleteFile $backup
  if [MoveFile $def_file $backup] { 
    if [OpenFile $def_file f w] { 
      foreach line $text {
        if [regexp "\#CCP4I" $line] { puts $f $line }
      }
      CloseFile $f
      SaveArray mr_database $def_file md -no_identifier -append
      DeleteFile $backup
      WriteToLog " " -nohead
      amore_block_mr_database 0
      return 1
    }
  }
  WriteToLog  "ERROR updating the database file" -nohead
}

#--------------------------------------------------------------------
proc amore_get_solution { file fix model_listVar output_model_listVar \
	nsol solutionVar { solution0 {} } } {
#--------------------------------------------------------------------
#d_sum Extract solutions from an 'mr' file and write in input format for Amore
#d_desc All lines beginning with # in the mr field are ignored. FIX keyword \
and mode lnumbers are inserted.  If this is the second solution file read \
then this is entered into this procedure as solution0.  All solutions in \
solution0 needed to be permed with all solutions input in file.
#d_arg file Input mr solution file
#d_arg fix Will be keyword 'FIX' or blank
#d_arg model_listVar Returned list of models (i.e. the names of models in \
the mr datase), for the current 'known' structure.
#d_arg output_model_listVar returned list models, for the structure to be\
output by the next run of Amore.
#d_arg nsol Number of solutions to be read (default is 'all')
#d_arg solutionVar Returned the text input for Amore listing 'known' solutions.
#d_arg solution0 Optional input of list of 'known' solutions read from another\
mr file

  upvar $solutionVar solution
  upvar $model_listVar model_list
  upvar $output_model_listVar output_model_list

#  puts "amore_get_solution file $file"

  if [regexp all $nsol ] { set nsol 1000 }
  if {![ReadFile $file text] || 
      ![ExtractTextLine $text "CCP4I SCRIPT" 0 all line] } { return 0 }

  set n_file_models [llength [set file_models [lrange $line 4 end]]]
#  puts "file_models $file_models n_file_models $n_file_models"

# Work out the model numbers for the models in the file
# NB the solutions may be for the same model and there may already
# be models defined by previous solution file

  foreach model $file_models {
    lappend output_model_list $model
    if { [llength $model_list] > 0 } {
      set im [expr [lsearch $model_list $model] + 1]
    } else { set im 0 }
    if { $im >  0 } {
      lappend imodel_list $im
    } else {
      lappend model_list $model
      lappend imodel_list [llength $model_list]
    }
  }
#  puts "model_list $model_list imodel_list $imodel_list"

# Extract the solutions from file to a list input_list
  set input_list {}
  foreach line [split $text \n] {
    if { [llength $line] > 0  && ![regexp {^#} $line] } {
      lappend input_list $line
    }
  }
#  puts "input $input_list"
  set nout [min $nsol [expr [llength $input_list]/$n_file_models]]
      
  set nl -1
  set solution {}
  for { set n 1 } { $n <= $nout } { incr n } {
    set sol ""
    foreach im $imodel_list {
      incr nl
      set mc [lindex [lindex $input_list $nl] 1]
      append sol "SOLUTION $fix [lindex $imodel_list [ expr $mc-1] ] [lrange [lindex $input_list $nl] 2 end]\n"
    }
    if { $solution0 != "" } { 
      foreach s0 $solution0 {
        lappend solution "[subst $sol][subst $s0]"
      }
    } else {
      lappend solution $sol
    }
  }
  return $n_file_models
}

#------------------------------------------------------------------------
proc amore_block_mr_database { mode } {
#------------------------------------------------------------------------
#d_sum send command to main ccp4i to block update of the mr database

#d_arg mode 1= initialise block, 0= release the block

  global job_params
  global block_mr_database
# send command to main interface to save the current mr_database and to
# block any user update until new data loaded
# call with mode = 1 to initiate the block and mode = 0 to terminate the block
  set send_status [catch { \
  send "$job_params(CCP4I_APPNAME)" [concat mr_block_database $mode ] } ]

# If setting the block on then wait for a response from ccp4i
}

#------------------------------------------------------------------------
proc amore_extract_mr_header { file args } {
#------------------------------------------------------------------------
#d_sum Extract information from the header of an mr file
#d_desc Arguments are parameter names, and a list of the corresponding \
values extracted from the header are returned. If a parameter is not \
found then a blank value is returned in that position.
#d_arg file Input mr solution file

  if {![ReadFile $file text -split]} { return {} }

  # Extract all possible parameters from header
  set params {} ; set values {}
  foreach line $text {
    if { [regexp -- "^#CCP4I" $line] } {
      if { [llength $line] >= 3 } {
        lappend params [lindex $line 1]
        lappend values [lrange $line 2 end]
      }
    }
  }

  # Search the list for the requested parameters
  set requested {}
  foreach arg $args {
    if { [set n [lsearch $params $arg]] > -1 } {
      lappend requested [lindex $values $n]
    } else {
      lappend requested {}
    }
  }
  return $requested
}
