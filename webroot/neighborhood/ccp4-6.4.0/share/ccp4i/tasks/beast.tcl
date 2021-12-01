#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =======================================================================
# beast.tcl --
#
# Likelihood-based molecular replacement
#
# CCP4Interface
#
# =======================================================================

#-----------------------------------------------------------------------
proc beast_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array
  
  set typedef(_beast_molecule_id)   { text 4 OBLIG }

  set typedef(_beast_mr_mode)       { menu \
                    { "mr search"          \
                      "mr trial(s)" }      \
                    { "SEARCH"             \
                      "TRIAL" } }

  set typedef(_beast_fix_mode)      { menu         \
                    { "orientation only"           \
                      "orientation and position" } \
                    { "ORIENT"                     \
                      "ORIENTPOSITION" } }

  set typedef(_beast_ident_rms)     { menu   \
                    { "expected rms error"   \
                      "sequence identity" }  \
                    { "RMS"                  \
                      "IDENT" } }

  set typedef(_beast_trial_type)     { menu                \
                    { "rotation solution(s)"               \
                      "rotation/translation solution(s)"   \
                      "details to be taken from file" }    \
                    { "ROT"                                \
                      "ROTTRANS"                           \
                      "MRFILE"   } }

  set typedef(_beast_rotate_options) { menu              \
                    { "none"                             \
                      "full search"                      \
                      "search within a region"           \
                      "search around specific angle(s)"  \
                      "rotate to specific angle(s)" }    \
                    { "NONE"                             \
                      "FULL"                             \
                      "REGION"                           \
                      "AROUND"                           \
                      "RLIST" } }

  set typedef(_beast_translate_options) { menu               \
                    { "none"                                 \
                      "search within a region"               \
                      "search around specific vector(s)"     \
                      "translate to specific vector(s)" }    \
                    { "NONE"                                 \
                      "REGION"                               \
                      "AROUND"                               \
                      "TLIST" } }

  set typedef(_beast_translate_grid) { menu       \
                    { "hcp grid"                  \
                      "fractional coord grid" }   \
                    { "HCP"                       \
                      "FRACTIONAL" } }

  set typedef(_beast_resolution_limits) { menu    \
                    { "dmin only"                 \
                      "dmin and dmax" }           \
                    { "DMINONLY"                  \
                      "DMINDMAX"    } }

  set typedef(_beast_average) { menu                        \
                    { "statistical average"                 \
                      "prior values, from Sigma(A)" }       \
                    { "STATISTICAL"                         \
                      "PRIOR"          } }

  set typedef(_beast_pivot_point) { menu         \
                    { "centre of mass"           \
                      "vector" }                 \
                    { "CENTRE"                   \
                      "VECTOR" } }

  set typedef(_beast_report) { menu              \
                    { "best scores only"         \
                      "all trials" }             \
                    { "BEST"                     \
                      "ALL" } }

  set typedef(_beast_molecule_menu) \
             { varmenu MOLECULE_MENU_LIST MOLECULE_MENU_ALIAS 6 }

  # PJX menu to deal with entry of rotations
  DefineMenu _beast_euler_entry [list "manually" \
                                      "from mr file" \
				     "manually and from mr file"] \
                                [list MANUAL FILE BOTH] 

  return 1
  }
 

#-----------------------------------------------------------------------
proc beast_run { arrayname } {
#-----------------------------------------------------------------------
# The number of input files is not known before the program is run:
#   there will be one HKLIN file, and one or more XYZIN files.
# Now that Beast is being run, this code sets up the input file array. 

  upvar #0 $arrayname array

  if { [lsearch -exact $array(MOLECULE_MENU_LIST) $array(MOLECULE_MR)] < 0 } {
    WarningMessage "The molecule specified for the mr search is not in
the list of molecules.

Please select a valid molecule before running the job."
    return 0
  }

  if { [GetValue $arrayname MR_MODE] == "SEARCH" } {
    if { ([GetValue $arrayname ROTATE_OPTIONS] == "NONE") && \
	     ([GetValue $arrayname TRANSLATE_OPTIONS] == "NONE") } {
        WarningMessage "No rotation or translation options set for search"
        return 0
    }
  }

  set array(INPUT_FILES) "HKLIN"
  for { set i 1 } { $i <= $array(NMOLECULES) } { incr i } {
    for { set j 1 } { $j <= $array(NMODELS,$i) } { incr j } {
      if { $array(XYZIN,[subst $i]_$j) == "" } {
        WarningMessage "Filename for molecule $i model $j not set."
        return 0
      }
      if { $array(ERROR_IDENT,[subst $i]_$j) == "" && \
           $array(ERROR_RMS,[subst $i]_$j) == "" } {
        WarningMessage "Effective RMS error of molecule $i model $j not set."
        return 0
      }
      append array(INPUT_FILES) " XYZIN,[subst $i]_$j"
    }
  }

  return 1
  }

#-----------------------------------------------------------------------
proc beast_molecule { arrayname counter_mol } {
#-----------------------------------------------------------------------
# procedure to draw one line of the 'Molecule #' toggle frame

  upvar #0 $arrayname array

# Set a default name for MOLECULE_ID of mol1, mol2, mol3 etc
  if { $array(MOLECULE_ID,$counter_mol) == "" } {
       set array(MOLECULE_ID,$counter_mol) "mol$counter_mol" }

  CreateLine line \
      help mole \
      label "Molecule id" \
      message "Enter a unique identifier for the molecule,\
               up to 4 characters in length" \
      widget MOLECULE_ID \
             -command "update_beast_molecule $arrayname" \
             -oblig \
      label "Molecule fraction" \
      message "Enter molecule's fractional occupancy in the asymmetric unit" \
      widget MOLECULE_FRACTION -oblig

  CreateLine line \
      label "   Model(s) for Molecule #$counter_mol" \
      -italic

# Within the Add Molecule toggle frame, insert an extending frame
#   for adding models for each molecule

  CreateExtendingFrame NMODELS beast_model \
      "Enter PDB file for a model (XYZIN) and the model identifier" \
      "Add model" \
      [list ERROR_MODE \
            ERROR_IDENT \
            ERROR_RMS \
            XYZIN \
            DIR_XYZIN ] \
       -counter $counter_mol

  # Check and update the variable menus
  edit_beast_molecule $arrayname $counter_mol

  }


#-----------------------------------------------------------------------
proc update_beast_molecule { arrayname } {
#-----------------------------------------------------------------------
# This is called whenever the user clicks into the widget for a
# molecule name
# If the name has changed then the variable menu of names needs to be
# updated via the call to update_beast_molecule_menu

  upvar #0 $arrayname array
  update_beast_molecule_menu $arrayname $array(NMOLECULES)
}


#-----------------------------------------------------------------------
proc update_beast_molecule_menu { arrayname nmolecules } {
#-----------------------------------------------------------------------
# Updates the variable menu of molecules
# The calling procedure needs to explicitly supply the number of
# molecules, since the NMOLECULES element in the array may not have
# been updated prior to arriving here.

  upvar #0 $arrayname array

  # Build list for menu
  set menu {}
  for { set n 1 } { $n <= $nmolecules } { incr n } {
      lappend menu $array(MOLECULE_ID,$n)
  }
  # Do the update
  UpdateVariableMenu $arrayname initialise 0 MOLECULE_MENU_LIST $menu

  ## PJX 16/10/02: start of disabled code
  ## Explanation: if a job is being rerun then this code will
  ## corrupt MOLECULE_MR in all cases where it is not the first
  ## molecule in the list
  ## Instead the test has been added to beast_run to check for
  ## badly assigned molecules
  ### PJX Also update the selected molecule, if necessary
  ##if { $array(NMOLECULES) < $nmolecules } {
  ##  if { [lsearch $menu $array(MOLECULE_MR)] < 0 } {
  ##    set array(MOLECULE_MR) $array(MOLECULE_ID,1)
  ##  }
  ##}
  ## PJX 16/10/02: end of disabled code
}


#-----------------------------------------------------------------------
proc edit_beast_molecule { arrayname counter_mol } {
#-----------------------------------------------------------------------
# When a molecule is removed or added, need to update the variable menu 
# for molecule selection.
# counter_mol is passed from the calling procedure, it is the
# number of molecules (= number of frames)

  upvar #0 $arrayname array

  set usermenu {}
  set alias {}

# Create the molecule menu list and its alias
  for { set n 1 } { $n <= $counter_mol } { incr n } {
      lappend usermenu "$n:  $array(MOLECULE_ID,$n)"
      }

  for { set n 1 } { $n <= $counter_mol } { incr n } {
      lappend alias $array(MOLECULE_ID,$n)
      }

# Correct MOLECULE_ID if a molecule is deleted and its 
# MOLECULE_ID is still set to the default mol$counter_mol 
#   (which will now be out by one (one too high))

  if { $counter_mol > 0 } {
    for { set p 1 } { $p <= $array(NMOLECULES)} { incr p } {
      if { [regexp "^(mol)(\[0-9\])$" $array(MOLECULE_ID,$p) \
                   j1 j2 num] } {
         # If the trailing number is different from the current 
         # molecule number (p) then reset the id 
         if { $num != $p } {
             set array(MOLECULE_ID,$p) "mol$p"
         }
      }
    }
  }

  # Update the variable menu with the list of molecule names
  update_beast_molecule_menu $arrayname $counter_mol

}


#-----------------------------------------------------------------------
proc beast_model { arrayname counter_mod counter_mol } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateInputFileLine line \
      "Enter model PDB file name (XYZIN)" \
      "PDB model #$counter_mod file" XYZIN DIR_XYZIN

  CreateLine line \
      help mode \
      label "Effective RMS error of model #$counter_mod" \
      message "Specify implicitly via the sequence identity\
              (as a percentage or a fraction), or explicitly" \
      widget ERROR_MODE \
      widget ERROR_IDENT -oblig \
      toggle_display [Indxv ERROR_MODE $counter_mol $counter_mod]  open IDENT

  CreateLine line \
      label "Effective RMS error of model #$counter_mod" \
      message "Specify implicitly via the sequence identity\
              (as a percentage or a fraction), or explicitly" \
      widget ERROR_MODE \
      widget ERROR_RMS -oblig \
      toggle_display [Indxv ERROR_MODE $counter_mol $counter_mod] open RMS

  }


#-----------------------------------------------------------------------
proc beast_rotate_euler {arrayname counter_euler} {
#-----------------------------------------------------------------------
  CreateLine line \
      help rlis \
      label "Euler angles for rotation $counter_euler:  alpha$counter_euler" \
      message "Enter Euler angles for the rotation" \
      widget ALPHA -oblig \
      label "beta$counter_euler" \
      widget BETA -oblig \
      label "gamma$counter_euler" \
      widget GAMMA -oblig
  }


#-----------------------------------------------------------------------
proc beast_translate_vector {arrayname counter_vector} {
#-----------------------------------------------------------------------
  CreateLine line \
      help tlis \
      message "Enter translation vector" \
      label "Translation vector $counter_vector   x$counter_vector" \
      widget X1 -oblig \
      label "y$counter_vector" \
      widget Y1 -oblig \
      label "z$counter_vector" \
      widget Z1 -oblig
  }

#-----------------------------------------------------------------------
proc beast_trial_rot {arrayname counter_rot} {
#-----------------------------------------------------------------------
  CreateLine line \
      help tria \
      message "Enter rotation Euler angles" \
      label "alpha" \
      widget TRIAL_ALPHA -oblig \
      label "beta" \
      widget TRIAL_BETA -oblig \
      label "gamma" \
      widget TRIAL_GAMMA -oblig
  }

#-----------------------------------------------------------------------
proc beast_trial_rot_trans {arrayname counter_rot_trans} {
#-----------------------------------------------------------------------
  CreateLine line \
      help tria \
      message "Enter rotation Euler angles and translation vector" \
      label "alpha" \
      widget TRIAL_ALPHA -oblig \
      label "beta" \
      widget TRIAL_BETA -oblig \
      label "gamma" \
      widget TRIAL_GAMMA -oblig \
      label "x" \
      widget TRIAL_X -oblig \
      label "y" \
      widget TRIAL_Y -oblig \
      label "z" \
      widget TRIAL_Z -oblig
  }
 
#-----------------------------------------------------------------------
proc beast_molecule_fix { arrayname counter } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
      help fix \
      message "Select a molecule to fix" \
      label "Fix" \
      widget FIX_MODE \
      label "of one copy of molecule #" \
      widget MOLECULE_FIX_ORIENT

  # PJX The following lines are toggled on an indexed parameter
  # The trick is to explicitly include the index of the
  # parameter - otherwise it doesn't work

  # Display this line if orientation only is fixed
  CreateLine line \
      help fix \
      message "Enter Euler angles for fixed orientation" \
      label "alpha" \
      widget FIX_ORIENT_ALPHA -oblig \
      label "beta" \
      widget FIX_ORIENT_BETA -oblig \
      label "gamma" \
      widget FIX_ORIENT_GAMMA -oblig \
      toggle_display FIX_MODE,$counter open ORIENT

  # Display this line if both orientation and position
  # are fixed
  CreateLine line \
      help fix \
      message "Enter Euler angles for fixed orientation" \
      label "alpha" \
      widget FIX_ORIENT_ALPHA -oblig \
      label "beta" \
      widget FIX_ORIENT_BETA -oblig \
      label "gamma" \
      widget FIX_ORIENT_GAMMA -oblig \
      message "Enter translation vector for fixed position" \
      label "   x" \
      widget FIX_ORIENT_X -oblig \
      label "y" \
      widget FIX_ORIENT_Y -oblig \
      label "z" \
      widget FIX_ORIENT_Z -oblig \
      toggle_display FIX_MODE,$counter open ORIENTPOSITION

  # Set initial value for molecule name
  if { $array(MOLECULE_FIX_ORIENT,$counter) == "" && \
	   $array(NMOLECULES) > 0 } {
    set array(MOLECULE_FIX_ORIENT,$counter) \
	[lindex $array(MOLECULE_MENU_LIST) 0]
  }

  }

#-----------------------------------------------------------------------
proc beast_mode_trial_type {arrayname} {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ([GetValue $arrayname MR_MODE] == "TRIAL") && 
       ([GetValue $arrayname TRIAL_TYPE] == "ROT") } {
    set array(MODE_TRIAL_TYPE) "ROTTRIAL"

  } elseif {
       ([GetValue $arrayname MR_MODE] == "TRIAL") && 
       ([GetValue $arrayname TRIAL_TYPE] == "ROTTRANS") } {
    set array(MODE_TRIAL_TYPE) "ROTTRANSTRIAL"

    } elseif {
         ([GetValue $arrayname MR_MODE] == "TRIAL") && 
         ([GetValue $arrayname TRIAL_TYPE] == "MRFILE") } {
      set array(MODE_TRIAL_TYPE) "MRFILETRIAL"

           } else {
             set array(MODE_TRIAL_TYPE) "UNDEF"
                  }
  }


#-----------------------------------------------------------------------
proc beast_task_window {arrayname} {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array 

  if { [CreateTaskWindow  $arrayname \
        "Beast - Likelihood-based molecular replacement" "Beast" \
        [ list "Define molecules and models" \
               "Protocol for mr search" \
               "Details for mr rotation trial(s)" \
               "Details for mr rotation/translation trial(s)" \
               "Trial details from file" \
               "Details for fixed molecules" \
               "Additional parameters"] \
         ] == 0 }  return

  SetProgramHelpFile beast

  beast_mode_trial_type $arrayname
  

#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      label "Select the mode for molecular replacement" -italic

  # PJX Minor change to the wording of the trailing label
  CreateLine line \
      label "Perform" \
      message "Choose mr by search or trial mode, for one molecule" \
      widget MR_MODE -command "beast_mode_trial_type $arrayname" \
      label "for a single molecule"

  CreateLine line \
      help tria \
      label "Type of trial(s):" \
      message "Select whether rotation trial(s),\
               rotation/translation trial(s),\
               or trial details to be loaded from file" \
      widget TRIAL_TYPE -command "beast_mode_trial_type $arrayname" \
      toggle_display MR_MODE open TRIAL

  # PJX Modified wording
  CreateLine line \
      help fix \
      message "Select to fix one or more molecules in known orientations\
               and (optionally) positions" \
      widget FIX \
      label "Fix the orientations of one or more molecules"

#=FILE===================================================================

  OpenFolder file

  CreateLine line \
      label "Input files" -italic

  CreateInputFileLine line \
      "Enter observed data MTZ file name (HKLIN)" \
      "MTZ in" HKLIN DIR_HKLIN

  CreateLabinLine line \
      "Select amplitude (F)" \
      HKLIN "F" F  {NULL} \
      -help labi

#========================================================================
# The "Define molecules and models" folder

  OpenFolder 1

  CreateToggleFrame NMOLECULES beast_molecule \
      "Add molecule to be placed within asymmetric unit" \
      "Molecule #" \
      "Add molecule" \
      [list MOLECULE_ID \
            MOLECULE_FRACTION \
            NMODELS ] \
       -edit_proc edit_beast_molecule \
       -child beast_model

#========================================================================
# The "Protocol for mr search" folder

  OpenFolder 2 MR_MODE open SEARCH hide

  CreateLine line \
      help sear \
      label "Perform mr search on molecule #" \
      message "Select the molecule for mr search" \
      widget MOLECULE_MR

  # PJX Start of rotation options
  CreateLine line \
      help rota \
      label "Rotation options" -italic \
      message "Do not rotate the molecule i.e. Euler angles 0 0 0" \
      widget ROTATE_OPTIONS \
      toggle_display ROTATE_OPTIONS open NONE

  CreateLine line \
      help rota \
      label "Rotation options" -italic \
      message "Perform a full rotation search of all unique orientations\
               (calculated from the crystal symmetry)" \
      widget ROTATE_OPTIONS \
      label "with step size" \
      message "Enter step size for search, in degrees.\
               Default value calculated according to\
               model size and resolution" \
      widget ROTATE_STEP_SIZE \
      toggle_display ROTATE_OPTIONS open FULL 

  CreateLine line \
      help rota \
      label "Rotation options" -italic \
      message "Perform a rotation search over a specified region\
               of Euler space" \
      widget ROTATE_OPTIONS \
      label "with step size" \
      message "Enter step size for search, in degrees.\
               Default value calculated according to\
               model size and resolution" \
      widget ROTATE_STEP_SIZE \
      toggle_display ROTATE_OPTIONS open REGION

  CreateLine line \
      help rota \
      message "Specify the Euler angle ranges for the region to search" \
      label "alpha1" \
      widget ROTATE_REGION_ALPHA1 -oblig \
      label "alpha2" \
      widget ROTATE_REGION_ALPHA2 -oblig \
      label "beta1" \
      widget ROTATE_REGION_BETA1 -oblig \
      label "beta2" \
      widget ROTATE_REGION_BETA2 -oblig \
      label "gamma1" \
      widget ROTATE_REGION_GAMMA1 -oblig \
      label "gamma2" \
      widget ROTATE_REGION_GAMMA2 -oblig \
      toggle_display ROTATE_OPTIONS open REGION

  CreateLine line \
      help rota \
      label "Rotation options" -italic \
      message "Perform a rotation search around set(s) of Euler angles" \
      widget ROTATE_OPTIONS \
      label "with search radius" \
      message "Enter search radius, in degrees\
               (the maximal rotational distance)."\
      widget ROTATE_AROUND_RADIUS -oblig \
      label "and step size" \
      message "Enter step size for search, in degrees\
               (default is 1/3 of the search radius)" \
      widget ROTATE_AROUND_STEPSIZE \
      toggle_display ROTATE_OPTIONS open AROUND

  CreateLine line \
      help rota \
      label "Rotation options" -italic \
      message "Rotate molecule to one or more sets of Euler angles" \
      widget ROTATE_OPTIONS \
      toggle_display ROTATE_OPTIONS open RLIST

  # PJX I have made changes here to deal with the definition of rotations
  # Rotations can be specified as Euler angles only,
  # mr file only, or a combination of both
  # The visibility of the options is controlled by the EULER_ENTRY widget
  OpenSubFrame frame -toggle_display ROTATE_OPTIONS hide [list NONE FULL REGION]

  CreateLine line \
      help rota \
      label "Enter Euler angles" \
      widget EULER_ENTRY

  # PJX Toggle the extending frame on the EULER_ENTRY widget
  OpenSubFrame frame -toggle_display EULER_ENTRY open [list MANUAL BOTH]
  CreateExtendingFrame NEULER beast_rotate_euler \
      "Enter additional set of Euler angles" \
      "Add set of Euler angles" \
      [list ALPHA BETA GAMMA]
  CloseSubFrame

  CreateInputFileLine line \
      "Enter .mr file name" \
      ".mr file" \
      MR_FILE DIR_MR_FILE \
      -toggle_display EULER_ENTRY open [list FILE BOTH]

  CloseSubFrame
  # PJX End of Rotation options

  # PJX Translation options start here
  CreateLine line \
      help tran \
      label "Translation options" -italic \
      message "Do not translate the molecule i.e. translation vector 0 0 0" \
      widget TRANSLATE_OPTIONS \
      toggle_display TRANSLATE_OPTIONS open NONE

  CreateLine line \
      help tran \
      label "Translation options" -italic \
      message "Search translation vectors over volume from x1 to x2,\
               y1 to y2 and z1 to z2" \
      widget TRANSLATE_OPTIONS \
      label "using" \
      message "Select search grid type: either hexagonal-close-packed,\
               or fractional with separate step sizes in x, y and z" \
      widget TRANSLATE_GRID \
      toggle_display TRANSLATE_OPTIONS open REGION

  OpenSubFrame frame -toggle_display TRANSLATE_OPTIONS open REGION

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates,\
               and search step size, in Angstroms" \
      label "x1" \
      widget TRANSLATE_REGION_X1 -oblig \
      label "to x2" \
      widget TRANSLATE_REGION_X2 -oblig \
      label "step size" \
      widget TRANSLATE_REGION_STEP \
      toggle_display TRANSLATE_GRID open HCP

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates" \
      label "y1" \
      widget TRANSLATE_REGION_Y1 -oblig \
      label "to y2" \
      widget TRANSLATE_REGION_Y2 -oblig \
      toggle_display TRANSLATE_GRID open HCP

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates" \
      label "z1" \
      widget TRANSLATE_REGION_Z1 -oblig \
      label "to z2" \
      widget TRANSLATE_REGION_Z2 -oblig \
      toggle_display TRANSLATE_GRID open HCP

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates\
               and step size for each axis, in Angstroms" \
      label "x1" \
      widget TRANSLATE_REGION_X1 -oblig \
      label "to x2" \
      widget TRANSLATE_REGION_X2 -oblig \
      label "x step size" \
      widget TRANSLATE_REGION_XSTEP -oblig \
      toggle_display TRANSLATE_GRID open FRACTIONAL

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates\
               and step size for each axis, in Angstroms" \
      label "y1" \
      widget TRANSLATE_REGION_Y1 -oblig \
      label "to y2" \
      widget TRANSLATE_REGION_Y2 -oblig \
      label "y step size" \
      widget TRANSLATE_REGION_YSTEP -oblig \
      toggle_display TRANSLATE_GRID open FRACTIONAL

  CreateLine line \
      help tran \
      message "Specify volume to search in fractional coordinates\
               and step size for each axis, in Angstroms" \
      label "z1" \
      widget TRANSLATE_REGION_Z1 -oblig \
      label "to z2" \
      widget TRANSLATE_REGION_Z2 -oblig \
      label "z step size" \
      widget TRANSLATE_REGION_ZSTEP -oblig \
      toggle_display TRANSLATE_GRID open FRACTIONAL

  CloseSubFrame

  CreateLine line \
      help tran \
      label "Translation options" -italic \
      message "Perform a translation search around specific vector(s)" \
      widget TRANSLATE_OPTIONS \
      label "with search radius" \
      message "Enter search radius, in Angstroms" \
      widget TRANSLATE_AROUND_RADIUS -oblig \
      label "and step size" \
      message "Enter step size for search, in Angstroms\
               (default is dmin/5)" \
      widget TRANSLATE_AROUND_STEPSIZE \
      toggle_display TRANSLATE_OPTIONS open AROUND

  CreateLine line \
      help tran \
      label "Translation options" -italic \
      message "Translate molecule to one or more translation vectors" \
      widget TRANSLATE_OPTIONS \
      toggle_display TRANSLATE_OPTIONS open TLIST

  OpenSubFrame frame -toggle_display TRANSLATE_OPTIONS open [list AROUND TLIST]

  CreateExtendingFrame NVECTOR beast_translate_vector \
      "Enter additional translation vector, in fractional coordinates" \
      "Add vector" \
      [list X1 Y1 Z1]

  CloseSubFrame
  # PJX End of translation options

#========================================================================
# The "Details for mr rotation trial(s)" folder

  OpenFolder 3 MODE_TRIAL_TYPE open ROTTRIAL hide

  CreateLine line \
      help tria \
      label "Perform mr rotation trial(s) on molecule #" \
      message "Select the molecule for mr rotation trial(s)" \
      widget MOLECULE_MR

  CreateExtendingFrame NTRIAL beast_trial_rot \
      "Add another rotation trial to test" \
      "Add rotation trial" \
      [list TRIAL_ALPHA \
            TRIAL_BETA \
            TRIAL_GAMMA ]

#========================================================================
# The "Details for mr rotation/translation trial(s) folder

  OpenFolder 4 MODE_TRIAL_TYPE open ROTTRANSTRIAL hide

  CreateLine line \
      help tria \
      label "Perform mr rotation/translation trial(s) on molecule #" \
      message "Select the molecule for mr rotation/translation trial(s)" \
      widget MOLECULE_MR

  CreateExtendingFrame NTRIAL beast_trial_rot_trans \
      "Add another rotation/translation trial to test" \
      "Add rotation/translation trial" \
       [list TRIAL_ALPHA \
             TRIAL_BETA \
             TRIAL_GAMMA \
             TRIAL_X \
             TRIAL_Y \
             TRIAL_Z ]

#========================================================================
# The "Trial details from file" folder

  OpenFolder 5 MODE_TRIAL_TYPE open MRFILETRIAL hide

  CreateLine line \
      help tria \
      label "Perform trial(s) from a .mr (or .molrep_rf) file\
             on molecule #" \
      message "Select the molecule for mr trial(s)" \
      widget MOLECULE_MR

  CreateInputFileLine line \
      "Enter input .mr (or .molrep_rf) trial file name" \
      "Trial file" \
      MR_FILE DIR_MR_FILE

#========================================================================
# The "Details for fixed molecules" folder

  OpenFolder 6 FIX open 1 hide

  CreateExtendingFrame NFIX_ORIENT beast_molecule_fix \
      "Add another molecule to be fixed within the asymmetric unit" \
      "Add fixed molecule" \
      [list MOLECULE_FIX_ORIENT \
            FIX_MODE \
            FIX_ORIENT_ALPHA \
            FIX_ORIENT_BETA \
            FIX_ORIENT_GAMMA \
            FIX_ORIENT_X \
            FIX_ORIENT_Y \
            FIX_ORIENT_Z ]  

#========================================================================
# The "Additional parameters" folder

  # PJX some options e.g. for reporting best trials etc should be put
  # into a separate folder I think

  OpenFolder 7 closed

  CreateLine line \
      help reso \
      message "Default dmin: twice the RMS error of\
               best model for SEARCH molecule. Default dmax:\
               from the mtz file" \
      widget TOG_RESOLUTION_LIMITS -toggleon \
      label "Resolution limits: specify" \
      widget RESOLUTION_LIMITS \
      label "dmin" \
      message "Enter dmin, in Angstroms" \
      widget DMIN \
      toggle_display RESOLUTION_LIMITS open DMINONLY

  CreateLine line \
      message "Choose to specify dmin only,\
               or both dmin and dmax\
               (default values taken from the mtz file)" \
      widget TOG_RESOLUTION_LIMITS -toggleon \
      label "Resolution limits: specify" \
      widget RESOLUTION_LIMITS \
      label "dmin" \
      message "Enter dmin, in Angstroms" \
      widget DMIN \
      label "dmax" \
      message "Enter dmax, in Angstroms" \
      widget DMAX \
      toggle_display RESOLUTION_LIMITS open DMINDMAX

  CreateLine line \
      help best \
      message "This must be at least 1, default value is 20" \
      widget TOG_NBEST -toggleon \
      label "Number of best trials to report at end of entire search" \
      widget NBEST

  CreateLine line \
      message "This defaults to value for entire search\
               (see previous line) but may be set to zero" \
      widget TOG_NBESTT -toggleon \
      label "Number of best trials to report at end of translation search" \
      widget NBESTT

  CreateLine line \
      message "Select NOT to write the BEST results to a .mr file\
               (PROJECT_JOBID_best.mr) (default is to do so)" \
      widget TOG_NO_MR_BEST_FILE -toggleon \
      label "Do NOT write the BEST results to a .mr file"

  CreateLine line \
      help clus \
      message "Default value is 20" \
      widget TOG_NCLUST -toggleon \
      label "Number of best clusters to report at end of entire search" \
      widget NCLUST

  CreateLine line \
      message "Select NOT to write the CLUSTER results to a .mr file\
               (PROJECT_JOBID_clust.mr) (default is to do so)" \
      widget TOG_NO_MR_CLUST_FILE -toggleon \
      label "Do NOT write the CLUSTER results to a .mr file"

  CreateLine line \
      help aver \
      message "Select to use a statistical average (the default),\
               or use prior values given by Sigma(A) values" \
      widget TOG_AVERAGE -toggleon \
      label "Method by which ensemble average structure factors\
             are computed" \
      widget AVERAGE

  CreateLine line \
      help pivo \
      message "Pivot around the centre of mass of the moving molecule" \
      widget TOG_PIVOT_POINT -toggleon \
      label "Specify pivot point for rotation of moving molecule" \
      widget PIVOT_POINT \
      toggle_display PIVOT_POINT open CENTRE

  CreateLine line \
      message "Specify pivot point in orthogonal Angstroms,\
               in terms of input PDB file for the moving molecule" \
      widget TOG_PIVOT_POINT -toggleon \
      label "Specify pivot point for rotation of moving molecule" \
      widget PIVOT_POINT \
      label "x" \
      widget PIVOT_X \
      label "y" \
      widget PIVOT_Y \
      label "z" \
      widget PIVOT_Z \
      toggle_display PIVOT_POINT open VECTOR 

  CreateLine line \
      label "     (NB This pivot point option is relevant only for\
             the <Translate Around> search option)"

  CreateLine line \
      help solp \
      message "Default values are fsol=0.95 and Bsol=150" \
      widget TOG_SOL -toggleon \
      label "Solvent parameters for Sigma(A) curves: fsol" \
      widget FSOL \
      label "Bsol" \
      widget BSOL

  CreateLine line \
      help outl \
      message "Specify as a probability (e.g. 100000 for 1 in 100000)\
               or its inverse (0.00001).\
               Default value is 0.000001" \
      widget TOG_OUTLIER -toggleon \
      label "Outlier rejection criterion" \
      widget OUTLIER -width 10

  CreateLine line \
      help shan \
      message "Value must be at least 1.1 (minimum of 1.25 recommended).\
               Default value is 1.5" \
      widget TOG_SHANNON -toggleon \
      label "Shannon density oversampling factor" \
      widget SHANNON

  CreateLine line \
      help boxs \
      message "Value must be at least 1.2 (minimum of 1.5 recommended).\
               Default value is 2.0" \
      widget TOG_BOXSCALE -toggleon \
      label "Molecular transform oversampling factor" \
      widget BOXSCALE

  CreateLine line \
      help report \
      message "Default is to report only the best scores,\
               but for detailed statistical analysis, may require all trials" \
      widget TOG_REPORT -toggleon \
      label "Level of reporting of trial scores" \
      widget REPORT

  CreateLine line \
      help verb \
      message "Select for extra output e.g. for debugging purposes" \
      widget TOG_VERBOSE -toggleon \
      label "Produce verbose output (rarely necessary)"

  }
