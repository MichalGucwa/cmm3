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
# dictionary.tcl --
#
# CCP4Interface
# Accessed from the 2d sketch window
#
# =======================================================================

#----------------------------------------------------------------------
proc adddict_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

# Set up default name for users own monomer libraray
  if { [ElementExists $arrayname LIBOUT] } {
    if { $array(LIBOUT) == "" } { 
      set array(LIBOUT) [file join [GetSystemVar DOT] monomer monomer_lib.cif]
      set array(DIR_LIBOUT) [GetSystemVar PATHNAME_LABEL]
    }
  }

  set typedef(_libcheck_select_mode) [list menu \
                           [list "for all PDBs in directory" \
                                 "from one PDB file" \
                                 "from description file"] \
                           [list dir pdb geom]]

  return 1

}
   
#------------------------------------------------------------------------
proc adddict_task_window { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  global configure
  global sketch_data

  if { [CreateTaskWindow $arrayname  \
        "Create Dictionary" "Dictionary" \
        {} ] == 0 } return

  SetProgramHelpFile libcheck

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
    label "Add description " \
    widget SELECT_MODE 

  CreateLine line \
    message "Take ideal geometry from PDB file" \
    widget FROMCOOR \
    label "Extract geometry from the input PDB file" \
    toggle_display SELECT_MODE hide geom

  CreateLine line \
    message "Attempt to find the monomer in the dictionary database" \
    widget SEARCH \
    label "Search the dictionary for monomer(s)" \
    toggle_display SELECT_MODE hide geom


  OpenFolder file

  CreateInputFileLine line \
      "PDB file containing cooordinates" \
       "PDB in" PDBIN DIR_PDBIN \
        -toggle_display SELECT_MODE open pdb \
 
   CreateLine line               \
    message "Enter full path name of directory" \
    label "Directory" \
    widget DIRECTORY -expand \
    message "Use file browser to define path name of directory" \
    button "Browse.." \
    toggle_display  SELECT_MODE open dir
 
# check that a path name  entered in the entry box is OK
    add_command $line.e2 "CheckDirInput $arrayname DIRECTORY"
    $line.b3 configure -font $configure(FONT_SMALL)
# bind picking of file browser icon to directory browser utility
    add_command $line.b3 "DirBrowser $arrayname DIRECTORY"

  CreateInputFileLine line \
    "File containing geometry description" \
    "Geom file" GEOM_FILE DIR_GEOM_FILE \
     -toggle_display SELECT_MODE open geom

  OpenSubFrame frame -toggle_display SELECT_MODE hide geom

    CreateLine line \
      label "Add description(s) to library file (optional):" -itallic

    CreateOutputFileLine line \
      "Merge descriptions into library file" \
       "Library" LIBOUT DIR_LIBOUT

  CloseSubFrame

  OpenSubFrame frame -toggle_display SELECT_MODE open geom

    CreateLine line \
      label "Output library file:" -itallic

    CreateOutputFileLine line \
      "Merge descriptions into library file" \
       "Library" LIBOUT DIR_LIBOUT

  CloseSubFrame

  

}

#------------------------------------------------------------------------
proc adddict_run { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  switch $array(SELECT_MODE) \
  pdb {
    set array(INPUT_FILES) PDBIN
  } geom {
    set array(INPUT_FILES) GEOM_FILE
  } dir {
    set array(INPUT_FILES) DIRECTORY
  }
  set array(OUTPUT_FILES) ""
  return 1
}


#------------------------------------------------------------------------
proc adddict_review { arrayname job_id } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { [ file exists [GetFullFileName0 $arrayname LIBOUT]] } {
    DbAddOutputFile $job_id [GetCurrentProject] \
                 $array(LIBOUT)  $array(DIR_LIBOUT)
  }
  return 1
}
