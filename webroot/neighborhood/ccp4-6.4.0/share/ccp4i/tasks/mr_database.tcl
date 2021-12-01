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
# mr_database.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc mr_database_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef

  source [SearchPath TOP tasks mr_utils.tcl]

  SaveOnProgramExit mr_database $arrayname

  return 1
}

#---------------------------------------------------------------------
proc mr_database_edit { arrayname counter } {
#---------------------------------------------------------------------
# User has used the edit tools on the toggle frame to delete or copy
# Do we want to save the result? probably not!
  set_model_menu $arrayname $counter

}

#---------------------------------------------------------------------
proc set_model_menu { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
# Make sure there is no spaces in the name (if users put in any other
# form of white space they deserve to be in a mess!)

  set array(MODEL_TITLE,$counter) \
	[RemoveMetaChars $array(MODEL_TITLE,$counter) ]

  set unique [CheckUnique $arrayname MODEL_TITLE $array(N_MODELS) ] 
  if { $unique > 0 }   { return 0 }

# Update the menus in other windows which list the models in the database
    set project [GetCurrentProject]
    mr_model_menu "amore_$project" $array(N_MODELS)
    mr_model_menu "mr_solution_$project" $array(N_MODELS)
    mr_model_menu "mr_map_$project" $array(N_MODELS)
}

#---------------------------------------------------------------------
proc set_model_filenames { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

# When user enters name for trial model derive names for output files

  set name1 $array(MODEL_TITLE,$counter)
  set array(XYZSHFT,$counter)  [subst $name1]_origin_shifted.pdb
  set array(SF_TABLE,$counter) [subst $name1]_MR_trial.tab
  set array(HKLIN,$counter) [subst $name1]_MR_trial.mtz

  CheckFileInput $arrayname XYZSHFT,$counter save
  CheckFileInput $arrayname SF_TABLE,$counter save
  CheckFileInput $arrayname HKLIN,$counter save

}

#---------------------------------------------------------------------
proc set_model_FC { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if [StringSame [GetValue $arrayname MODEL_MODE,$counter] EMAP ] {
    set array(FC,$counter) "E"
  } else {
    set array(FC,$counter) "FC"
  }
}


#---------------------------------------------------------------------
proc mr_update_solution_list { arrayname } {
#---------------------------------------------------------------------
# Go thru the solution file list and check whether the file still exists
  upvar #0 $arrayname array
  if { ![ElementExists $arrayname N_MODELS] || $array(N_MODELS) < 0 } { return }
  for { set nm 1 } { $nm <= $array(N_MODELS) } { incr nm } {
    if { $array(N_SOLFIL,$nm) > 0 } {
      set nlines $array(N_SOLFIL,$nm)
      set ns $nlines

      while { $ns > 0 } {
        if [ElementExists $arrayname [Indxv DIR_SOLFIL $nm $ns] ] {
          set array([Indxv DIR_SOLFIL $nm $ns]) ""
        }
        if { ![file exists $array([Indxv SOLFIL $nm $ns]) ] } {
          if { $ns < $nlines } {
            foreach ele [list SOLFIL DIR_SOLFIL]  {
              for { set i $ns } { $i < $nlines } { incr i } {
                set ii [expr $i + 1]
                set array([Indxv $ele $nm $i]) $array([Indxv $ele $nm $ii])
              }
            }
          }
          incr nlines -1
          puts "deleting $array([Indxv SOLFIL $nm $ns]) nlines $nlines"
        }
        incr ns -1
      } 

      if { $nlines < $array(N_SOLFIL,$nm) } {
        for { set i [expr $nlines +1] } { $i < $array(N_SOLFIL,$nm) } { incr i } {
          foreach ele [list SOLFIL DIR_SOLFIL]  {
            unset array([Indxv $ele $nm $i])
          }
        }
      }
      set array(N_SOLFIL,$nm) $nlines
    }
  }
}

#---------------------------------------------------------------------
proc mr_model { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  set_model_menu $arrayname $counter

  CreateLine line \
    label "Trial model name" \
    message "Enter one-word name for trial model used in menus & filenames" \
    widget MODEL_TITLE -width 20 \
	-command "set_model_menu $arrayname $counter
		  set_model_filenames $arrayname $counter
		  SaveProjectDef  mr_database $arrayname" \
    label " use data in form of" \
    widget MODEL_MODE \
	-command "set_model_FC $arrayname $counter"
    

  CreateInputFileLine line \
     "Enter input coordinate file name (XYZINn)" \
     "Trial model coords" \
      XYZIN DIR_XYZIN \
      -command "set_model_title XYZIN $arrayname $counter
		SaveProjectDef  mr_database $arrayname"

  CreateInputFileLine line \
     "Enter input MTZ file for trial model map (HKLINn)" \
      "MTZ file" HKLIN DIR_HKLIN  \
      -command "set_model_title HKLIN $arrayname $counter" \
      -toggle_display MODEL_MODE,$counter open [list SFMAP EMAP ]

  CreateLaboutLine line \
    "Choose amplitude (FC) and phi (PHIC) for trial model map" \
     HKLIN "FC    " FC \
     -sigma "PHIC  " PHIC  \
     -toggle_display MODEL_MODE,$counter open [list SFMAP EMAP ]

  CreateLine line \
    label "Show AMoRe files and parameters" \
	-italic \
    widget AMORE_DETAILS \
    format margins

    $line configure -background $configure(COLOUR_VERY_PALE)
    $line.l1 configure -background $configure(COLOUR_VERY_PALE)
    $line.cb2 configure -background $configure(COLOUR_VERY_PALE)

    bind $line <Button-1> "$line.cb2 invoke"
    bind $line.l1 <Button-1> "$line.cb2 invoke"


  OpenSubFrame frame -toggle_display AMORE_DETAILS,$counter open 1

  CreateLine line \
    label "Files generated by AMoRe.." -italic

   CreateInputFileLine line \
        "Trial model origin shifted coordinate file (XYZOUTn)" \
        "Optimised coords" \
        XYZSHFT DIR_XYZSHFT

  CreateInputFileLine line \
        "Trial model SF table file (TABLEn)" \
        "SF table file" \
        SF_TABLE DIR_SF_TABLE


  CreateLine line \
    label "The following parameters will be automatically read from the AMoRe log file" \
	-italic

  CreateLine line \
    label "Transformation Shift:" \
    message "XYZ shift to optimised coords (will be read from log file)" \
    widget MODEL_COM_1 \
    widget MODEL_COM_2 \
    widget MODEL_COM_3 \
    label "Rotation" \
    message "Euler angle rotation to optimised coords (will be read from log file)" \
    widget MODEL_EULER_1 \
    widget MODEL_EULER_2 \
    widget MODEL_EULER_3


  CreateLine line \
    label "Minimal containing box for model" \
    message "Minimal box enclosing model - extracted from log" \
    widget MINIMAL_BOX_1 \
    widget MINIMAL_BOX_2 \
    widget MINIMAL_BOX_3 \
    label "& Dmax to centre of mass" \
    message "Maximum distance of atom from centre of mass  - extracted from log" \
    widget MAX_DCOM

  CloseSubFrame

}

#---------------------------------------------------------------------
proc set_model_title { mode arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  if { $array(MODEL_TITLE,$counter) == "" } {
    set array(MODEL_TITLE,$counter) \
      [file tail [file root $array([Indxv $mode $counter])] ]
    set_model_menu $arrayname $counter
    set_model_filenames $arrayname $counter
  }
}

#---------------------------------------------------------------------
proc mr_solution_files { arrayname c2 c1 } {
#---------------------------------------------------------------------

    CreateInputFileLine line \
     "Enter molecular replacement solution file name" \
     "Solution file" \
      SOLFIL DIR_SOLFIL

}

#---------------------------------------------------------------------
proc mr_database_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

#  mr_update_solution_list $arrayname

  if { [CreateTaskWindow $arrayname  \
    	"AMoRe Model Database" "AMoRe Models" \
         [list "Memory Allocation" ] \
	-action_buttons [list quit save exit] ] == 0 } return


  # Set up commands bound to "exit" button
  $array(WINDOW).buttons.exit configure \
       -command "[$array(WINDOW).buttons.exit cget -command ] 
                 mr_copy_memory mr_database amore"

  # Set up commands bound to default "dismiss" button
  $array(WINDOW).buttons.dismiss configure \
       -command "[$array(WINDOW).buttons.dismiss cget -command ]"

  SetProgramHelpFile "amore"


  OpenFolder protocol 


  CreateToggleFrame  N_MODELS mr_model  \
                "Specify molecular replacement trial model" \
                "MR trial model"  \
                "Add MR model" \
	[list	MODEL_TITLE \
		MODEL_MODE \
		XYZIN \
		DIR_XYZIN \
                HKLIN \
                DIR_HKLIN \
		FC \
		PHIC \
		AMORE_DETAILS \
		XYZSHFT \
                DIR_XYZSHFT \
                SF_TABLE \
                DIR_SF_TABLE \
                MODEL_COM_1 \
                MODEL_COM_2 \
                MODEL_COM_3 \
                MODEL_EULER_1 \
                MODEL_EULER_2 \
                MODEL_EULER_3 \
                MINIMAL_BOX_1 \
                MINIMAL_BOX_2 \
                MINIMAL_BOX_3 \
                MAX_DCOM ] \
		-edit_proc mr_database_edit

  OpenFolder 1 closed

  DrawMemoryWidgets

}
