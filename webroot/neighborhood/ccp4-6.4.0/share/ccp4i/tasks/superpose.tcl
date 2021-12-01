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
# superpose.tcl --
# Interface to lsqkab and top fitting programs
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc superpose_findatom {readfile atomlab} {
#---------------------------------------------------------------------
# Given an atom number, locate its position in the input file.
	set f [open "$readfile" "r"]
        set maxnum -1
	set line 0
	set keyword ""
	while { [eof $f] != 1 && ![regexp "ATOM|HETATM" $keyword]} {
	    # Go through the file until we meet the first
	    # ATOM or HETATM card
	    set x [gets $f]
	    scan $x "%s" keyword
	}
	while {[eof $f] != 1} {
	    # We always use the line from the previous iteration
            # ignore blank lines
	    if {$x != ""} {incr line}
	    scan $x "%s %d" keyword labl
	    if { $labl == $atomlab } {
		close $f
		return $line
	    }
	    # Track the highest number atom in the file
	    if { $labl > $maxnum } {
		set maxnum $labl
	    }
	    # Fetch the next line
	    set x [gets $f]
	}
	close $f
	# We didn't find a match
	if { $atomlab > $maxnum } {
	    # If the input number was out of range then return
	    # the highest one found
	    return $atomlab
	}
	# Return failure
	return -1
}

#---------------------------------------------------------------------
proc superpose_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array


  DefineMenu _superpose_mode [list "Superpose using gesamt" \
                                   "Superpose using Secondary Structure Matching" \
				   "Superpose topology (Topp program)" \
				   "Superpose specified atoms/residues" \
				   "Translate/rotate structure" ] \
				   [ list GES SSM TOP FIT MOVE ]

  DefineMenu _superpose_sel_mode [ list residues atoms ] [list RES ATOM ]

  DefineMenu _superpose_res_mode [list "CA atoms" \
					"main chain atoms" \
					"side chain atoms" \
					" all" ] \
				[list CA MAIN SIDE ALL]
  DefineMenu _superpose_radius_mode [ list "centre of fixed molecule" \
				"coordinates" ] \
				[ list CENTROID COORDS ]

  DefineMenu _superpose_match_mode [list "equivalent" "not equivalent"] \
		[list EQUIV NOTEQ ]

  DefineMenu _superpose_top_match_mode [ list "automatically" \
			"as fraction of 2ndry structure elements" \
 		"as number of 2ndry structure elements" ] \
		[list AUTO RATE ABS ]


  return 1
}
					
#---------------------------------------------------------------------
proc superpose_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

# If user is match equivalent named residues/atoms then fit in the match fields
  switch [GetValue $arrayname SUPERPOSE_MODE] \
  GES {
    if { ![file exists [FindExecutable gesamt]] } {
       WarningMessage "The program \"gesamt\" is not on your path.
Check your installation for \"gesamt\" program."
       return 0
    }
    set array(INPUT_FILES) "XYZIN1 XYZIN2"
    set array(OUTPUT_FILES) "XYZOUT"
  } SSM {
    if { ![file exists [FindExecutable superpose]] } {
       WarningMessage "The program \"superpose\" is not on your path. 
Check your installation for \"superpose\" program and \"ssm\" library."
       return 0
    }
    set array(INPUT_FILES) "XYZIN1 XYZIN2"
    set array(OUTPUT_FILES) "XYZOUT"
  } TOP {
    set array(INPUT_FILES) "XYZIN1 XYZIN2"
    set array(OUTPUT_FILES) ""
  } FIT {
    set array(INPUT_FILES) "XYZIN1 XYZIN2"
    set array(OUTPUT_FILES) "XYZOUT"
    set array(IFOUTPUTXYZ) 1
    set errMessage ""
    for { set n 1 } { $n <= $array(N_MATCHS)  } { incr n } {
       if { [regexp ATOM [GetValue $arrayname FIT_SEL_MODE,$n]] } {
          # The purpose is to correct the input that will be given to LSQKAB, 
          # if user uses pdb files in which the atoms labels sequence is gapped
          set array(FIT_ATOML_1,$n) [superpose_findatom [GetFullFileName0 \
				     $arrayname XYZIN2] $array(FIT_ATOM_1,$n)]
	  if {$array(FIT_ATOML_1,$n)==-1} {
	     append errMessage \
	     "The Atom Label $array(FIT_ATOM_1,$n) is not present in the file $array(XYZIN2)\r"
	  }
	  set array(FIT_ATOML_2,$n) [superpose_findatom [GetFullFileName0 \
				     $arrayname XYZIN2] $array(FIT_ATOM_2,$n)]
	  if {$array(FIT_ATOML_2,$n)==-1} {
	     append errMessage \
	     "The Atom Label $array(FIT_ATOM_2,$n) is not present in the file $array(XYZIN2)\r"
	  }
	  if {[regexp NOTEQ [GetValue $arrayname MATCH_MODE,$n] ]} {
	     set array(MATCH_ATOML_1,$n) [superpose_findatom [GetFullFileName0 \
					  $arrayname XYZIN1] $array(MATCH_ATOM_1,$n)]
	     if {$array(MATCH_ATOML_1,$n)==-1} {
		 append errMessage \
		 "The Matching Label $array(MATCH_ATOM_1,$n) is not present in the file $array(XYZIN1)\r"
	     }
	     set array(MATCH_ATOML_2,$n) [superpose_findatom [GetFullFileName0 \
						     $arrayname XYZIN1] $array(MATCH_ATOM_2,$n)]
	     if {$array(MATCH_ATOML_2,$n)==-1} {
		 append errMessage \
		 "The Matching Label $array(MATCH_ATOM_2,$n) is not present in the file $array(XYZIN1)\r"
	     }
	  } 
       }
    }
    if {$errMessage!=""} {
       WarningMessage "$errMessage"
       return 0
    }
  } MOVE {
    set array(INPUT_FILES) "XYZIN2"
    set array(OUTPUT_FILES) "XYZOUT"
    set array(IFOUTPUTXYZ) 1
  }

  if { [ StringSame FIT [GetValue $arrayname SUPERPOSE_MODE]] } {
    for { set n 1 } { $n <= $array(N_MATCHS) } { incr n } {
      if { [StringSame EQUIV [GetValue $arrayname MATCH_MODE,$n ]] } {
	 if { [StringSame ATOM [GetValue $arrayname FIT_SEL_MODE,$n]] } {
	   # Fitting atoms
           set array(MATCH_ATOML_1,$n) $array(FIT_ATOML_1,$n)
           set array(MATCH_ATOML_2,$n) $array(FIT_ATOML_2,$n)
         } else {
	   # Fitting residues
	   set array(MATCH_RES_1,$n) $array(FIT_RES_1,$n)
           set array(MATCH_RES_2,$n) $array(FIT_RES_2,$n)
         }
         set array(MATCH_CHAIN,$n) $array(FIT_CHAIN,$n)
      }
    }
  }

  # make sure RUN_PDBMERGE switched off for inappropriate modes
  if { ![ StringSame [GetValue $arrayname SUPERPOSE_MODE] GES SSM FIT] } {
     set RUN_PDBMERGE 0
  }

  return 1
}

#---------------------------------------------------------------------
proc superpose_match { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if {  $counter > 1  && $array(MATCH_RES_1,$counter) == "" 
       && $array(MATCH_ATOM_1,$counter) == ""} {
    set last [expr {$counter -1}]
    set array(FIT_SEL_MODE,$counter) $array(FIT_SEL_MODE,$last)
    set array(MATCH_MODE,$counter) $array(MATCH_MODE,$last)
    set array(RES_MODE,$counter) $array(RES_MODE,$last)
  }

  OpenSubFrame frame -toggle_display FIT_SEL_MODE,$counter open ATOM

  CreateLine line  \
    message "Enter the atom number for atom in the moving molecule (FIT)" \
    help fit_atom \
    label Fit \
    widget FIT_SEL_MODE \
    label range \
    widget FIT_ATOM_1 \
    label to \
    widget FIT_ATOM_2 \
    label "of chain" \
    widget FIT_CHAIN

  CreateLine line \
    message "Enter the atom number for atom in the fixed molecule (MATCH)" \
    help fit_atom \
    label to \
    widget MATCH_MODE \
    label "atom range" \
    widget MATCH_ATOM_1 \
    label to \
    widget MATCH_ATOM_2 \
    label "of chain" \
    widget MATCH_CHAIN \
    toggle_display MATCH_MODE,$counter hide EQUIV

  CreateLine line \
    message "Enter the atom number for atom in the fixed molecule (MATCH)" \
    help fit_atom \
    label to \
    widget MATCH_MODE \
    label "atom range" \
    toggle_display MATCH_MODE,$counter open EQUIV


  CloseSubFrame

  OpenSubFrame frame -toggle_display FIT_SEL_MODE,$counter open RES

  CreateLine line  \
    message "Enter the residue range for the moving molecule (FIT)" \
    help fit_residue \
    label Fit \
    widget RES_MODE \
    label of \
    widget FIT_SEL_MODE \
    label range \
    widget FIT_RES_1 \
    label to \
    widget FIT_RES_2 \
    label "of chain" \
    widget FIT_CHAIN

  CreateLine line \
    message "Enter the residue range for the fixed molecule (MATCH)" \
    help match \
    label to  \
    widget MATCH_MODE \
    label "residue range" \
    widget MATCH_RES_1 \
    label to \
    widget MATCH_RES_2 \
    label "of chain" \
    widget MATCH_CHAIN \
    toggle_display MATCH_MODE,$counter hide EQUIV

  CreateLine line \
    message "Enter the residue range for the fixed molecule (MATCH)" \
    help match \
    label to  \
    widget MATCH_MODE \
    label "residue range" \
    toggle_display MATCH_MODE,$counter open EQUIV


  CloseSubFrame

  return 1
}

#-----------------------------------------------------------------
proc superpose_update_atom_selection  { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  # chain IDs or wild card
  if {$array(SOURCE_CHN) != ""} {
    set array(SSM_MOVING) "$array(SOURCE_CHN)"
  } else {
    set array(SSM_MOVING) "*"
  }

  # residue numbers or wild card
  if {$array(SOURCE_NUMR1) != "" && $array(SOURCE_NUMR2) != ""} {
    set array(SSM_MOVING) "$array(SSM_MOVING)/$array(SOURCE_NUMR1)-$array(SOURCE_NUMR2)"
  } elseif {$array(SOURCE_NUMR1) != ""} {
    set array(SSM_MOVING) "$array(SSM_MOVING)/$array(SOURCE_NUMR1)"
  } else {
    set array(SSM_MOVING) "$array(SSM_MOVING)/*"
  }

  # atom name and element type
  if {$array(SOURCE_ANAME) != "" || $array(SOURCE_ELEM) != ""} {
    set array(SSM_MOVING) "$array(SSM_MOVING)/"
  }
  if {$array(SOURCE_ANAME) != ""} {
    set array(SSM_MOVING) "$array(SSM_MOVING)$array(SOURCE_ANAME)"
  }
   if {$array(SOURCE_ELEM) != ""} {
    set array(SSM_MOVING) "$array(SSM_MOVING)\[$array(SOURCE_ELEM)\]"
  }
   

  # chain IDs or wild card
  if {$array(TARGET_CHN) != ""} {
    set array(SSM_FIXED) "$array(TARGET_CHN)"
  } else {
    set array(SSM_FIXED) "*"
  }

  # residue numbers or wild card
  if {$array(TARGET_NUMR1) != "" && $array(TARGET_NUMR2) != ""} {
    set array(SSM_FIXED) "$array(SSM_FIXED)/$array(TARGET_NUMR1)-$array(TARGET_NUMR2)"
  } elseif {$array(TARGET_NUMR1) != ""} {
    set array(SSM_FIXED) "$array(SSM_FIXED)/$array(TARGET_NUMR1)"
  } else {
    set array(SSM_FIXED) "$array(SSM_FIXED)/*"
  }

  # atom name and element type
  if {$array(TARGET_ANAME) != "" || $array(TARGET_ELEM) != ""} {
    set array(SSM_FIXED) "$array(SSM_FIXED)/"
  }
  if {$array(TARGET_ANAME) != ""} {
    set array(SSM_FIXED) "$array(SSM_FIXED)$array(TARGET_ANAME)"
  }
   if {$array(TARGET_ELEM) != ""} {
    set array(SSM_FIXED) "$array(SSM_FIXED)\[$array(TARGET_ELEM)\]"
  }

}

#-----------------------------------------------------------------
proc gesamt_update_atom_selection  { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  # chain IDs or wild card
  if {$array(SOURCE_CHN) != ""} {
    set array(GES_MOVING) "$array(SOURCE_CHN)"
  } else {
    set array(GES_MOVING) "*"
  }

  # residue numbers or wild card
  if {$array(SOURCE_NUMR1) != "" && $array(SOURCE_NUMR2) != ""} {
    set array(GES_MOVING) "$array(GES_MOVING)/$array(SOURCE_NUMR1)-$array(SOURCE_NUMR2)"
  } elseif {$array(SOURCE_NUMR1) != ""} {
    set array(GES_MOVING) "$array(GES_MOVING)/$array(SOURCE_NUMR1)"
  } else {
    set array(GES_MOVING) "$array(GES_MOVING)/*"
  }

  # atom name and element type
  if {$array(SOURCE_ANAME) != "" || $array(SOURCE_ELEM) != ""} {
    set array(GES_MOVING) "$array(GES_MOVING)/"
  }
  if {$array(SOURCE_ANAME) != ""} {
    set array(GES_MOVING) "$array(GES_MOVING)$array(SOURCE_ANAME)"
  }
   if {$array(SOURCE_ELEM) != ""} {
    set array(GES_MOVING) "$array(GES_MOVING)\[$array(SOURCE_ELEM)\]"
  }


  # chain IDs or wild card
  if {$array(TARGET_CHN) != ""} {
    set array(GES_FIXED) "$array(TARGET_CHN)"
  } else {
    set array(GES_FIXED) "*"
  }

  # residue numbers or wild card
  if {$array(TARGET_NUMR1) != "" && $array(TARGET_NUMR2) != ""} {
    set array(GES_FIXED) "$array(GES_FIXED)/$array(TARGET_NUMR1)-$array(TARGET_NUMR2)"
  } elseif {$array(TARGET_NUMR1) != ""} {
    set array(GES_FIXED) "$array(GES_FIXED)/$array(TARGET_NUMR1)"
  } else {
    set array(GES_FIXED) "$array(GES_FIXED)/*"
  }

  # atom name and element type
  if {$array(TARGET_ANAME) != "" || $array(TARGET_ELEM) != ""} {
    set array(GES_FIXED) "$array(GES_FIXED)/"
  }
  if {$array(TARGET_ANAME) != ""} {
    set array(GES_FIXED) "$array(GES_FIXED)$array(TARGET_ANAME)"
  }
   if {$array(TARGET_ELEM) != ""} {
    set array(GES_FIXED) "$array(GES_FIXED)\[$array(TARGET_ELEM)\]"
  }

}

#---------------------------------------------------------------------
proc superpose_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Superpose Molecules" "Superpose" \
        [ list "Define Matching Atoms/Residues"  \
	"Define Transformation" \
	"Superpose Topology" \
	"Atom selection for SSM" \
        "Atom selection for Gesamt"] ] == 0 } return

  SetProgramHelpFile lsqkab

  CreateLineTemplate SSM_ATOM_SEL { 0.0 0.17 0.31 0.41 0.50 0.54 0.63 0.75 0.82 0.92}

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Chose superpose mode" \
        widget SUPERPOSE_MODE

  CreateLine line \
        help output \
        message "Output rms distances between atom pairs for the superposed residues" \
	widget IFOUTPUTRMS \
        label "Output graph of RMS difference  " \
        message "List of ALL differences between atom pairs is written to a file" \
	widget IFOUTPUTDELTAS \
	label "Output all distances to a file" \
	toggle_display SUPERPOSE_MODE open FIT

  CreateLine line \
        message "Use PDB_MERGE to combine superposed coordinates with fixed coordinates" \
	widget RUN_PDBMERGE \
        label "combine superposed coordinates with fixed coordinates in output PDB file " \
        toggle_display SUPERPOSE_MODE open [list GES SSM FIT]

#=FILES================================================================

  OpenFolder file 
  
 CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN2)" \
      "Moving" \
       XYZIN2 DIR_XYZIN2 \
       -fileout XYZOUT DIR_XYZOUT "_lsq"

 CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN1)" \
      "Fixed" \
       XYZIN1 DIR_XYZIN1 \
	-toggle_display SUPERPOSE_MODE open [list GES SSM TOP FIT ]


  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT \
        -toggle_display SUPERPOSE_MODE hide [list TOP]


  CreateOutputFileLine line \
        "Output coordinate file root name" \
        "PDB out" \
        TOPOUT DIR_TOPOUT \
        -toggle_display SUPERPOSE_MODE open [list TOP]

#------------------------------------------Define matched atoms/residues

  OpenFolder 1 SUPERPOSE_MODE open FIT hide


  CreateExtendingFrame N_MATCHS superpose_match \
        "Define range(s) of atoms/residue ranges to refine" \
        "Add Range" \
       [ list FIT_SEL_MODE \
	FIT_CHAIN \
	FIT_ATOM_1 \
	FIT_ATOM_2 \
	RES_MODE \
	FIT_RES_1 \
	FIT_RES_2 \
	MATCH_CHAIN \
	MATCH_ATOM_1 \
	MATCH_ATOM_2 \
	MATCH_RES_1 \
	MATCH_RES_2 \
	MATCH_MODE ]


  CreateLine line \
    message "Fit atoms inside sphere (RADIUS)" \
    help radius \
    widget IFRADIUS \
    label "Only fit atoms in sphere radius" \
    widget RADIUS_CUTOFF \
    label "centred on" \
    widget SUPERPOSE_RADIUS_MODE 

  CreateLine line \
    message "Centre sphere on coordinates (RADIUS)" \
    help radius \
    label x \
    widget RADIUS_X \
    label y \
    widget RADIUS_Y \
    label z \
    widget RADIUS_Z \
    toggle_display SUPERPOSE_RADIUS_MODE open COORDS


#-------------------------------------------------------------rotate/translate

  OpenFolder 2 SUPERPOSE_MODE open MOVE hide

  CreateLine line \
    message "Enter rotation in Euler angle degrees (ROTATE)" \
    help rotate \
    label "Apply rotation  alpha" \
    widget ROTATE_ALPHA -oblig \
    label "  beta" \
    widget ROTATE_BETA -oblig \
    label "  gamma" \
    widget ROTATE_GAMMA -oblig

  CreateLine line \
    message "Enter translation in Angstrom (TRANSLATE)" \
    help translate \
    label "and translation  x" \
    widget TRANSLATE_X -oblig \
    label "  y" \
    widget TRANSLATE_Y -oblig \
    label "  z" \
    widget TRANSLATE_Z -oblig

#---------------------------------------------------------topology

  OpenFolder 3 SUPERPOSE_MODE open TOP hide

  SetProgramHelpFile topp

  CreateLine line \
    help match \
    label "Cutoff for matches determined" \
    widget TOP_MATCH_MODE \
    toggle_display TOP_MATCH_MODE open AUTO

  CreateLine line \
    label "Cutoff for matches determined" \
    help match \
    widget TOP_MATCH_MODE \
    label "for fixed" \
    widget TOP_MATCH_RATE1 \
    label "and moving" \
    widget TOP_MATCH_RATE2 \
    toggle_display TOP_MATCH_MODE open RATE

    CreateLine line \
    help match \
    label "Cutoff for good matches determined" \
    widget TOP_MATCH_MODE \
    widget TOP_MATCH_NSECSTR \
    toggle_display TOP_MATCH_MODE open ABS

#-----------------------------------------------------SSM atom selection

  OpenFolder 4 SUPERPOSE_MODE open SSM hide

  SetProgramHelpFile superpose

  CreateLine line \
    label "Write atom selection directly (for detailed control): " -italic

  CreateLine line \
    label "Superpose atom selection " \
    message "Use atom selection syntax, see documentation" \
    widget SSM_MOVING \
    label " onto atom selection " \
    widget SSM_FIXED

  CreateLine line \
    label "or use boxes (and optionally edit above): " -italic

  CreateLine line \
    label "Moving: chain(s) " \
    message "Enter single chain identifier or comma-separated list" \
    widget SOURCE_CHN \
    -command "superpose_update_atom_selection $arrayname" \
    label " residues " \
    message "Enter first residue in range" \
    widget SOURCE_NUMR1 -width 7 \
    -command "superpose_update_atom_selection $arrayname" \
    label " to " \
    message "Enter last residue in range" \
    widget SOURCE_NUMR2 -width 7 \
    -command "superpose_update_atom_selection $arrayname" \
    label " atom name " \
    message "Enter atom name e.g. CG1 or leave blank" \
    widget SOURCE_ANAME -width 6 \
    -command "superpose_update_atom_selection $arrayname" \
    label " element " \
    message "Enter element name e.g. C or leave blank" \
    widget SOURCE_ELEM -width 4 \
    -command "superpose_update_atom_selection $arrayname" \
    format  template SSM_ATOM_SEL

  CreateLine line \
    message "Atom selection string will be auto-generated from your choices" \
    label "Fixed: chain(s) " \
    message "Enter single chain identifier or comma-separated list" \
    widget TARGET_CHN \
    -command "superpose_update_atom_selection $arrayname" \
    label " residues " \
    message "Enter first residue in range" \
    widget TARGET_NUMR1 -width 7 \
    -command "superpose_update_atom_selection $arrayname" \
    label " to " \
    message "Enter last residue in range" \
    widget TARGET_NUMR2 -width 7 \
    -command "superpose_update_atom_selection $arrayname" \
    label " atom name " \
    message "Enter atom name e.g. CG1 or leave blank" \
    widget TARGET_ANAME -width 6 \
    -command "superpose_update_atom_selection $arrayname" \
    label " element " \
    message "Enter element name e.g. C or leave blank" \
    widget TARGET_ELEM -width 4 \
    -command "superpose_update_atom_selection $arrayname" \
    format  template SSM_ATOM_SEL

#-----------------------------------------------------GESAMT atom selection

  OpenFolder 5 SUPERPOSE_MODE open GES hide

  SetProgramHelpFile gesamt

  CreateLine line \
    label "Write atom selection directly (for detailed control): " -italic

  CreateLine line \
    label "Superpose atom selection " \
    message "Use atom selection syntax <chain>/<res>-<res>, see documentation" \
    widget GES_MOVING \
    label " onto atom selection " \
    widget GES_FIXED
}
