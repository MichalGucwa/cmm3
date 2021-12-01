#
#     Copyright (C) 1999-2005  Liz Potterton, Peter Briggs, Francois Remacle
#
#     This code is distributed under the terms and conditions of the
#     CCP4 licence agreement as `Part 1' (Annex 2) software.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# dyndom.tcl --
#
# task interface for dyndom program 
#
# CCP4Interface 
#
# =======================================================================
#-------------------------------------------------------------------------
proc dyndom_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  return 1
}

#---------------------------------------------------------------
proc dyndom_setup { typedefVar arrayname } {
#---------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array
  
  
  DefineMenu _rasmol_mode [list "display the rotation vectors" \
                                 "display the protein" \
								 "do nothing" ] \
	                       [list ROTVEC PROT NOUSE]
  
  return 1

}
#-------------------------------------------------------------------------
proc dyndom_task_window { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  
  set hasrasmol [file exists [FindExecutable rasmol] ]
  
  SetProgramHelpFile "dyndom"

  if { [CreateTaskWindow $arrayname  \
        "Dyndom - Determine Domains for two conformations" "Dyndom" \
        [ list "Control Parameters" "Iteration Parameters"  ] ] == 0 } return

  CreateLineTemplate dyntempl [list 0.1 0.375]
  
  OpenFolder protocol

  CreateTitleLine line TITLE
  
  if {$hasrasmol} {
    CreateLine line \
      message "Choose what to do with output for rasmol" \
	  label "Use Rasmol to" \
	  widget DOMODE \
  }

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "PDB file for first conformation" \
        "PDB in" \
        XYZIN DIR_XYZIN \
	
  CreateLine line \
    message "Choose Chain ID if any" \
	widget IFCHAIN1 -toggleon \
    label "Chain ID" \
    widget CHAIN1 
	
  CreateInputFileLine line \
        "PDB file for second conformation maybe same file" \
        "PDB in" \
        XYZIN2 DIR_XYZIN2

  CreateLine line \
    message "Choose Chain ID if any" \
	widget IFCHAIN2 -toggleon \
    label "Chain ID" \
    widget CHAIN2 
    
  CreateOutputFileLine xyz2 \
        "PDB file that gives the coordinates of atoms from both chains." \
        "PDB out" \
        XYZOUT DIR_XYZOUT

  CreateOutputFileLine xyz2 \
        "A rotation vector file in PDB format for display using RasMol." \
        "PDB out" \
        XYZOUT2 DIR_XYZOUT2

  CreateOutputFileLine file0 \
        "Dihedral analysis file comparing dihedral angle changes in bending regions." \
        "TXT out" \
        FILE DIR_FILE

  CreateOutputFileLine file1 \
        "A RasMol script file for display in Rasmol" \
        "RAS out" \
        FILE1 DIR_FILE1

  CreateOutputFileLine info \
        "Text file with information on the conformational change in terms of \
         domain motions" \
        "TXT out" \
        INFO DIR_INFO

#=PARAMETERS==========================================================

  OpenFolder 1 open

  CreateLine line \
    message "Define size of sliding window for generating backbone segment" \
    label "Size of window " \
    widget SLIDEWINDOW \
	format template dyntempl
	
  CreateLine line \
    message "Minimum domain size as percentage of total number of residues" \
    label "Domain size" \
    widget DOMAIN \
	format template dyntempl
	
  CreateLine line \
    message "Define minimum ratio of interdomain displacement for domain pair" \
    label "Interdomain displacement ratio" \
    widget RATIO \
	format template dyntempl
	
	
  OpenFolder 2 closed

  CreateLine line \
    message "Define numbers of iterations" \
    label "Number of iterations " \
    widget ITERATIONS \
	format template dyntempl
	
  CreateLine line \
    message "Maximum number of clusters to use in each iteration" \
    label "Number of clusters" \
    widget CLUSTERS \
	format template dyntempl
	
}
#-------------------------------------------------------------------------
proc dyndom_review { arrayname job_id} {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  
  if {[GetValue $arrayname RASARGS] != ""} {
    set args [split [GetValue $arrayname RASARGS] " "]
    exec [BinPath rasmol] [lindex $args 0] [lindex $args 1] [lindex $args 2]
  }
}
