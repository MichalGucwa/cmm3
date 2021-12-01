# ======================================================================
# makereference.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc makereference_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cmakereference]] } {
    return 0
  }
  return 1
}
#------------------------------------------------------------------------
proc makereference_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_makereference_dl) { menu { "ftp'ed from EBI" "from local directory" } { DOWNLOAD NODOWNLOAD } }
  return 1
}

#---------------------------------------------------------------------
proc makereference_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Reference structure preparation for 'pirate' and 'buccaneer'" "makereference" \
             [ list \
               "Options" \
              ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cmakereference"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line  \
        message "Automatic ftp is possible if your site security allows it." \
        label "Use coordinates and reflection files " \
        widget MODEDOWNLOAD

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      message "PDB accession code" \
      label "PDB id" \
      widget PDBID -oblig \
      -command "makereference_set_filenames $arrayname"

  OpenSubFrame frame \
      -toggle_display MODEDOWNLOAD open NODOWNLOAD

  CreateInputFileLine line \
      "Enter input coordinate file name" \
      "pdb????.ent" \
      PDBIN DIR_PDBIN

  CreateInputFileLine line \
      "Enter input reflection file name" \
      "r????sf.ent" \
      CIFIN DIR_CIFIN

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateOutputFileLine line \
      "Enter output PDB file name" \
      "PDB out" \
      XYZOUT DIR_XYZOUT

#-----------------------------------------------------

  OpenFolder 1

  CreateLine line \
      message "Truncate resolution" \
      help resolution \
      widget RESOLUTION -toggleon \
      label "Truncate resolution to" \
      widget RESOLUTION_MAX \
      label "Angstroms"


#-----------------------------------------------------

}

#-------------------------------------------------------------------
proc makereference_set_filenames { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(HKLOUT) "reference-$array(PDBID).mtz"
  set array(XYZOUT) "reference-$array(PDBID).pdb"
}

