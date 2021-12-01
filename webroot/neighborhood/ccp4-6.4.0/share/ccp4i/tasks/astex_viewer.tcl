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
# astex_viewer.tcl --
#
# Run astex_viewer
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------------
proc astex_viewer_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

#----------------------------------------------------------------------
proc astex_viewer_review { arrayname job_id } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Start browser if requested
  if { $array(LAUNCH_DISPLAY) == 1 } {
    open_url [GetLogFileName $job_id]
  }
  return 1
}

#----------------------------------------------------------------------
proc astex_viewer_task_window { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
       "Launch AstexViewer" "AstexViewer" \
       [list "Protein PDB files" \
             "Ligand PDB files" \
             "Map files" \
             "Display Options"] ] == 0 } return

  SetProgramHelpFile "astex_viewer"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
    widget LAUNCH_DISPLAY \
    label "Launch hypertext browser to display html logfile automatically"

#=FILES================================================================

  OpenFolder file

#=REMAINING FOLDERS====================================================

  # Proteins
  OpenFolder 1

  CreateExtendingFrame NPROTEINS AstexViewer_protein \
     "Specify an additional input pdb file for protein structures to display" \
     "Add input pdb file" \
     [list XYZIN DIR_XYZIN]

  # Ligands
  OpenFolder 2

  CreateExtendingFrame NLIGANDS AstexViewer_ligand \
     "Specify an additional input pdb file for ligands to display" \
     "Add input ligand file" \
      [list LIGAND DIR_LIGAND]

  # Maps
  OpenFolder 3

  CreateExtendingFrame NMAPS AstexViewer_map \
     "Specify an additional input map file for maps to display" \
     "Add input map file" \
      [list MAPIN DIR_MAPIN]

#=PARAMETERS==========================================================

  OpenFolder 4 closed

  CreateLine line \
     message "Set the initial contour levels for map display" \
     label "Contour 1:" \
     widget CONTOUR_LEVEL,1 \
     label "Contour 2:" \
     widget CONTOUR_LEVEL,2 \
     label "Contour 3:" \
     widget CONTOUR_LEVEL,3

  CreateLine line \
     message "Set the height and width for the applet in the output file" \
     label "Applet height" \
     widget APPLET_HEIGHT \
     label "width" \
     widget APPLET_WIDTH \
     label "(pixels)"
}

#----------------------------------------------------------------------
proc AstexViewer_protein { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for protein PDB file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input PDB file name for protein structure" \
    "PDB file $counter" \
    XYZIN DIR_XYZIN
}
#----------------------------------------------------------------------
proc AstexViewer_ligand { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for ligand PDB file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input PDB file name for ligand structure" \
    "Ligand PDB file $counter" \
    LIGAND DIR_LIGAND
}
#----------------------------------------------------------------------
proc AstexViewer_map { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for map file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input PDB file name for protein structure" \
    "Map file $counter" \
    MAPIN DIR_MAPIN
}

#----------------------------------------------------------------------
proc astex_viewer_run { arrayname } {
#----------------------------------------------------------------------
# Write a html file which embeds the viewer plus controls to toggle the
# display of the various components, and to alter the contour levels of
# maps
#
# The Javascript, html and applet code is taken from Mike Hartshorn's
# original Perl script for generating these kinds of pages
  upvar #0 $arrayname array

  # Set up list of input files
  set array(INPUT_FILES) "XYZIN,1 "
  for { set n 2 } { $n <= $array(NPROTEINS) } { incr n } {
    append array(INPUT_FILES) "XYZIN,$n "
  }
  for { set n 1 } { $n <= $array(NLIGANDS) } { incr n } {
    append array(INPUT_FILES) "LIGAND,$n "
  }
  for { set n 1 } { $n <= $array(NMAPS) } { incr n } {
    append array(INPUT_FILES) "MAPIN,$n "
  }
    
  # Set up output files
  set array(OUTPUT_FILES) ""

  return 1
}
