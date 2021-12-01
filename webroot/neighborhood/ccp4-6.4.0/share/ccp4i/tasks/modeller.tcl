#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# modeller.tcl --
#
# Rum Modeller comparative modelling program
#
# CCP4Interface 
#
# =======================================================================


#--------------------------------------------------------------------
proc modeller_prereq { } {
#--------------------------------------------------------------------
# Check for existence of modeller executable 
  global configure
  set modeller_exe \
	  [FileJoin $configure(MODELLER_MODINSTALL) $configure(MODELLER_PROGRAM)]
  if { ![file exists [FindExecutable $modeller_exe]] } {
    return 0
  }
  return 1
}

#--------------------------------------------------------------------
proc modeller_setup { typedefVar arrayname } {
#--------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  set typedef(_modeller_input)  { menu { "alignment file" "sequence file" } 
					{ ALIGN SEQ } }

  set typedef(_modeller_refine) { menu { "no" "fast" "full" } 
					{ NO FAST FULL } }

  set typedef(_modeller_edit) { menu { "do no edit" "set to zero occupancy" "delete" } 
					{ NO ZERO_OCC DELETE } }

  set typedef(_modeller_side_edit) { menu { "do no edit" 
				"set to zero occupancy" 
				"convert to glycine" 
				"convert to alanine" } 
			{ NO ZERO_OCC GLY ALA } }

  return 1

}


# procedure run before script is written

#--------------------------------------------------------------------
proc modeller_run { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(EDIT_MODEL) && $array(EDIT_FRACTION) == "" } {
     WarningMessage "You have set 'Edit Model' on but not defined the fraction of the model to edit - please enter a fraction"
     return 0
  }

  if [regexp ALIGN [GetValue $arrayname INPUT_MODE] ] {
    set array(INPUT_FILES) ALNFILE
  } else {
    set array(INPUT_FILES) SEQFILE
  }
  set found_model 0

  for { set n 1 }  { $n <= $array(NKNOWNS) } { incr n } { 
    if { $array(KNOWNFILE,$n) != "" } {
      append array(INPUT_FILES) " KNOWNFILE,$n"
    } elseif { !$found_model } {
      set found_model 1 
    } else {
      WarningMessage "Known structure file undefined for more than one sequence in the alignment file"
      return 0
    }
  }

  return 1

}

#--------------------------------------------------------------------
proc modeller_read_aln2 { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![ReadFile [GetFullFileName0 $arrayname ALNFILE] alnfile -split] } {
     WarningMessage "Error reading alignment file" 
     return
  }

  set namelist {}
  foreach line $alnfile {
    if { [regsub {>P1;} $line {} name ] } { 
      lappend namelist $name 
   } 
  }
  if { [llength $namelist] > 0  } { 
    set increment [expr [llength $namelist] - $array(NKNOWNS) ]
    update_extendingframe modellerKnowns 0 $arrayname NKNOWNS \
                $array(NKNOWNS) $increment 1
    for { set n 1 } { $n <= $array(NKNOWNS) } { incr n } { 
       set array(KNOWNCODE,$n) [lindex $namelist [expr $n -1] ]
    }
  }
}
    
#--------------------------------------------------------------------
proc modeller_read_aln { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ReadFile [GetFullFileName0 $arrayname ALNFILE] output ]} {
      set output_text "$output"
  } else {
      PleaseWait
      WarningMessage "File not present or cannot be read"
      return
  }

  set namelist {}
  set sequence {}
  set known {}

  foreach line $output_text {
      if { [regsub {>P1;} $line {} name ] } { 
	  lappend namelist $name 
      } 
  }

  for {set x 0} {$x<[llength $namelist]} {incr x} {
      set type [ExtractFromText $output_text ">P1;[lindex $namelist $x]" 1 all]
      if { [string range $type 0 7] == "sequence" } {
	  lappend sequence [lindex $namelist $x]
      } elseif { [string range $type 0 7] == "structur" } {
	  lappend known [lindex $namelist $x]
      } else {
	  WarningMessage "Format of alignment file is incorrect. Please check and correct."
	  return
      }
      if { [regexp {([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)(:([^:]+))?(:([^:]+))?(:([^:]+))?(:(.*))?} $type match protocol pdb first_res first_chain last_res last_chain name source res rfac] == 0 } {
	  WarningMessage "(regexp)Format of alignment file is incorrect. Please check and correct. Monkey"
	  return
      }
      if { $pdb != [lindex $namelist $x] } {
	  WarningMessage "Inconsistency spotted in PDB codes. Please check."
	  return
      }
  }

  if { [llength $known] > 0  } { 
      set increment [expr [llength $known] - $array(NKNOWNS) ]
      update_extendingframe modellerKnowns 0 $arrayname NKNOWNS \
	  $array(NKNOWNS) $increment 1
      for { set n 1 } { $n <= $array(NKNOWNS) } { incr n } { 
	  set array(KNOWNCODE,$n) [lindex $known [expr $n -1] ]
      }
  }
  puts "end"
}

#--------------------------------------------------------------------
proc modellerKnowns { arrayname counter } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    message "Enter code name for known structure" \
    label "Code name" \
    widget KNOWNCODE
    

  CreateInputFileLine line \
        "Enter name of input known structure file (KNOWNFILE)" \
        "Known in" \
        KNOWNFILE DIR_KNOWNFILE \
	-command "modellerSetKnownCode $arrayname $counter"

  CreateLine line \
    label "Base model on range: chain" \
    widget FIRST_RES_CHAIN \
    label residue  \
    widget FIRST_RES_ID \
    label " to: chain" \
    widget LAST_RES_CHAIN \
    label residue  \
    widget LAST_RES_ID
  
}

#--------------------------------------------------------------------
proc modellerSetKnownCode { arrayname counter } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  if { $array(KNOWNCODE,$counter) == "" } {
    set array(KNOWNCODE,$counter) \
	[file tail [file rootname $array(KNOWNFILE,$counter) ] ]
  }

  if { [PdbGetChains [GetFullFileName0 $arrayname KNOWNFILE,$counter] \
					chains chain_res] } {
    set array(FIRST_RES_ID,$counter) [lindex [lindex $chain_res 0] 0]
    set array(LAST_RES_ID,$counter) [lindex [lindex $chain_res 0] 1]
    set array(FIRST_RES_CHAIN,$counter) [lindex $chains 0]
    set array(LAST_RES_CHAIN,$counter) [lindex $chains 0]
  }

}


#---------------------------------------------------------------------
proc modeller_read_top_file { arrayname } {
#---------------------------------------------------------------------
# pp54: 08/09/04
# This is a very quick and dirty way of reading a top file and running it.
# It is done this way because it is the quickest way to get something working
# before I leave on friday 10/09/04. It should probably be re-written like the 
# mosflm.tcl task, which reads the script and fills in the values in the gui.

  upvar #0 $arrayname array
  set top_contents ""

  #Read the contents of the file into a list of lines. Ignore blanks
  ReadFile $array(TOPFILE) top_contents -split
  
  # Number of DIRECTORIES keywords encountered
  set ndirs 0

  puts $top_contents
  puts [set $array(COM_FILE) [GetTmpFileName -ext _com ] ]

  for {set i 0} {$i<=[llength $top_contents]} {incr i} {
      WriteFile $array(COM_FILE) [lindex $top_contents $i]
  }
	     
}


#--------------------------------------------------------------------
proc modeller_task_window {arrayname} {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
 	"Modeller - Edit Protein Structure" "Modeller" \
        [list "Set Bfactors" "Edit Model" ] ] == 0 } return

  source  [SearchPath TOP utils pdb_utils.tcl]

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    label "NOTE This task uses the Modeller program which is not distributed with CCP4 - click Help for details" -italics

#pp54: I've commented this line in order to drop modeller 4 support. Always assume that modeller version is 6.
#  CreateLine line \
    message "It is now assumed you are using Modeller 6, but de-select this to revert to Modeller 4" \
    widget USING_MODELLER6 \
    label "I am using Modeller 6. De-select to use Modeller 4."

  CreateTitleLine line TITLE

  CreateLine line \
    message "Have you determined the alignment of sequence and homolog?" \
    label "Input sequence for structure to build as" \
    widget INPUT_MODE

  CreateLine line \
    message "Choose level of refinement for new structure" \
    label "Do" \
    widget REFINE_MODE \
    label "refinement of new structure(s)"


  CreateLine line \
        message "Number of models to create (ENDING_MODEL)"  \
        label "Create" \
        widget NMODELS \
        label "model(s)" \
	toggle_display REFINE_MODE open FULL

  CreateLine line \
    message "Process Modeller models to convert for crystallography" \
    widget EDIT_BFACTORS \
    label "Set B factors (recommended because Modeller misuses Bfactor column)"

  CreateLine line \
    message "Process Modeller models to convert for crystallography" \
    widget EDIT_MODEL \
    label "Edit model to remove 'bad' structure or set occupancy to zero"

  CreateLine line \
      message "Select TOP file" \
      widget DEFINE_TOP_FILE \
      label "Define TOP file"

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
	"Enter input alignment file name (ALNFILE)" \
	"Align in" \
	ALNFILE DIR_ALNFILE \
	-command "modeller_read_aln $arrayname" \
	-toggle_display INPUT_MODE open ALIGN 

  CreateInputFileLine line \
        "Enter input sequence file name (SEQFILE)" \
        "Seq in" \
        SEQFILE DIR_SEQFILE \
	-toggle_display INPUT_MODE open SEQ 
#        -command "modeller_check_sequence $arrayname"

  CreateInputFileLine line \
      "Enter top script" \
      "Top in" \
      TOPFILE DIR_TOPFILE \
      -command "modeller_read_top_file $arrayname"

  CreateLine line \
    label "Enter names of PDB file(s) containing homolog structure(s)" -italic  \
	toggle_display INPUT_MODE open SEQ

  CreateLine line \
    label "Enter names of PDB files corresponding to sequences in alignment file" -italic  \
	toggle_display INPUT_MODE open ALIGN

  CreateLine line \
    label "Leave file name field blank for the sequence you are trying to model" -italic \
    toggle_display INPUT_MODE open ALIGN

  CreateExtendingFrame NKNOWNS modellerKnowns \
        "Enter name of PDB files containing known models" \
        "Add known structure file" \
      [list  KNOWNFILE DIR_KNOWNFILE ]

#-------------------------------------------------------------------------Edit Model

  OpenFolder 1 EDIT_BFACTORS open 1 hide

  CreateLine line \
    label "Set Bfactors to main chain to" \
    widget MAIN_BFACTOR \
    label "and for side chain to" \
    widget SIDE_BFACTOR

  OpenFolder 2 EDIT_MODEL open 1 hide

  CreateLine line \
    label "For whole residue" -italic \
    label "For poorest" \
    widget EDIT_FRACTION -oblig \
    label "fraction of residues in model" \
    widget EDIT_MODE

  CreateLine line \
    label "For side chain only" -italic \
    label "Where residue has been mutated" \
    widget SIDE_EDIT_MODE

}
