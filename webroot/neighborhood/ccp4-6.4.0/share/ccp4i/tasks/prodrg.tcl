#
#  Written by A. Schuettelkopf, 2008
#
# prodrg.tcl (?)
#

#-----------------------------------------------------------------------
proc prodrg_prereq { } {
#-----------------------------------------------------------------------
  if { ![file exists [FindExecutable "cprodrg"]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc prodrg_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  DefineMenu _prodrg_protchoice [list "all hydrogens" "polar hydrogens only" "no hydrogens"] \
                                [list "ALL"           "POLAR"                "NONE"]

  DefineMenu _prodrg_coordchoice [list "PDB format" "MDL Molfile format" "both PDB and Molfile format"] \
                                 [list "PDB"        "MOL"                "BOTH"]

  DefineMenu _prodrg_emchoice [list "always" "never" "only when molecule is modified" "always, producing 2D coordinates"] \
                              [list "YES"    "NO"    "BUILD"                          "FLAT"]

  return 1
}

#-----------------------------------------------------------------------
proc prodrg_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  set omode [GetValue $arrayname COORDOUT ]

  if { [ regexp PDB $omode ] } {
    set array(OUTPUT_FILES) "LIBOUT XYZOUT"
  } elseif { [ regexp MOL $omode ] } {
    set array(OUTPUT_FILES) "LIBOUT MOLOUT"
  } else {
    set array(OUTPUT_FILES) "LIBOUT XYZOUT MOLOUT"
  }

  return 1
}

#-----------------------------------------------------------------------
proc prodrg_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Generate small molecule topologies / coordinates" "Content" [ list "Options" ] \
       ] == 0 } return

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line label "Run PRODRG to generate a small molecule topology."

  CreateLine line \
    label "Also write out coordinates in " widget COORDOUT

  OpenFolder file

  CreateInputFileLine line \
    "Enter name of input file in PDB/Molfile/SYBYL2/SMILES/PRODRG drawing format" \
    "Input file" \
    XYZIN DIR_XYZIN \
    -fileout LIBOUT DIR_LIBOUT "_prodrg" \
    -fileout XYZOUT DIR_XYZOUT "_prodrg" \
    -fileout MOLOUT DIR_MOLOUT "_prodrg"

  CreateOutputFileLine line \
    "Enter name of topology file to be written" \
    "Library out" \
    LIBOUT DIR_LIBOUT

  CreateOutputFileLine line \
    "Enter name of PDB coordinate file to be written" \
    "PDB out" \
    XYZOUT DIR_XYZOUT \
    -toggle_display COORDOUT open { PDB BOTH }

  CreateOutputFileLine line \
    "Enter name of Molfile coordinate file to be written" \
    "Molfile out" \
    MOLOUT DIR_MOLOUT \
    -toggle_display COORDOUT open { MOL BOTH }

  OpenFolder 1 open

  CreateLine line \
    message "Energy minimize coordinates (MINI)" \
    label "Improve input coordinates by energy minimization" widget EMMODE

  CreateLine line \
    message "Select protonation for output coordinate files" \
    label "Output coordinates will carry" widget PROTONATE

}
