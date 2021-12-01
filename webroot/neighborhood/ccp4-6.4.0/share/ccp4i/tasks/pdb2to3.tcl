#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# rotaprep.tcl --
#
# Import a formatted reflection file (eg from DENZO) and create multirecord
#   MTZ file
#
# CCP4Interface 
# Created Oct97 by Liz Potterton
#
# =======================================================================

proc pdb2to3_task_window { arrayname } {
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Pdb2to3 - Convert PDB-2 to PDB-3 Format" "Pdb2to3" \
	] == 0 } return

  OpenFolder protocol

  CreateTitleLine line TITLE

  OpenFolder file

  CreateInputFileLine line \
      "Enter input coordinate file name (PDB-2 or PDB-3)" \
        "PDB In" \
       XYZIN DIR_XYZIN \
      -fileout XYZOUT DIR_XYZOUT "_pdb2to3_"

  CreateOutputFileLine line \
      "Enter output coordinate file name (PDB-3)" \
       "PDB Out" \
       XYZOUT DIR_XYZOUT
}

