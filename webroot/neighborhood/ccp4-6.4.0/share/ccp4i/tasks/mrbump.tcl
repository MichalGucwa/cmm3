#
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# ======================================================================
# mrbump.tcl --
#
# CCP4Interface 
#
# =======================================================================

############################################################################
proc mrbump_setup { typedefVar arrayname } {
############################################################################
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array
  global env

  DefineMenu _mrbump_mode [ list "Model search and Molecular Replacement" \
						  "Model search only" \
                                                  "Molecular Replacement only" ] \
	     [ list FULLMR MODELS MRONLY ] 

  set program_menu {}
  set program_alias {}

  #Make the list
  #set list [list "mafft" "probcons" "t_coffee" "clustalw" "clustalw2" ]
  #foreach item $list {
  #   if { [FindExecutable $item ] != "" } {
  #       puts $item
  #       lappend program_menu $item 
  #       lappend program_alias [string toupper [$item]]
  #   }
  #}

  # Check for each of the MA programs
  if { [file join $env(CCP4) "libexec" "mafft"] != "" } {
      lappend program_menu "Mafft"
      lappend program_alias MAFFT
  } elseif { [FindExecutable "mafft" ] != "" } {
      lappend program_menu "Mafft"
      lappend program_alias MAFFT
  }
  if { [FindExecutable "mafft.bat" ] != "" } {
      lappend program_menu "mafft.bat"
      lappend program_alias MAFFT
  }
  if { [FindExecutable "probcons" ] != "" } {
      lappend program_menu "Probcons"
      lappend program_alias PROBCONS
  }
  if { [FindExecutable "t_coffee" ] != "" } {
      lappend program_menu "T_Coffee"
      lappend program_alias T_COFFEE
  }
  if { [FindExecutable "clustalw" ] != "" } {
      lappend program_menu "Clustalw"
      lappend program_alias CLUSTALW
  }
  if { [file join $env(CCP4) "libexec" "clustalw2"] != "" } {
      lappend program_menu "Clustalw2"
      lappend program_alias CLUSTALW2
  } elseif { [FindExecutable "clustalw2" ] != "" } {
      lappend program_menu "Clustalw2"
      lappend program_alias CLUSTALW2
  }

  # Check that the list is not empty, i.e. no multiple alignment programs are present 
  if { [llength $program_menu] == 0 } {
         WarningMessage "Dependency Error: No multiple alignment programs found on this system. MrBUMP requires one of mafft, clustalw, clustalw2, probcons or t_coffee"
         return 0
  }

  DefineMenu  _ma_program $program_menu $program_alias
  #DefineMenu  _ma_program [ list "Mafft" "Probcons" "T_Coffee" "Clustalw" "Clustalw2" ] \
  #    [ list  MAFFT PROBCONS T_COFFEE CLUSTALW CLUSTALW2 ]

  set typedef(_tryall)  { menu  { "first solution is produced using a search model" \
	                          "all of the search models have been tried in MR" } \
					{ 0 1 } }

  return 1
}

############################################################################
proc set_cluster_flag { arrayname } {
############################################################################
  upvar #0 $arrayname array
  global env

  # Check to see if there is an SGE queue available for cluster submission 
  if { [info exists env(SGE_ROOT)] } {
     set array(CLUSTER_QUEUE) 1
  }

  # Check to see if there is a PBS queue available for cluster submission 
  if { [info exists env(PBS_ENVIRONMENT)] } {
     set array(CLUSTER_QUEUE) 1
  }

  return 1
}

############################################################################
proc set_acorn_flag { arrayname } {
############################################################################
  upvar #0 $arrayname array

  # Check the max resolution of the target data.
  if { $array(RESOLUTION_MAX) <= 1.7 } {
     set array(ACORN_FLAG) 1
  } else {
     set array(ACORN_FLAG) 0
  }

  return 1
}

############################################################################
proc set_shelxe_flag { arrayname } {
############################################################################
  upvar #0 $arrayname array

  # Check the max resolution of the target data.
  if { $array(AUTOTRACE_AVAILABLE) == 1 && $array(RESOLUTION_MAX) <= 2.4 } {
     set array(SHELXE) 1
     WarningMessage "Data resolution is better than 2.4 Angstroms - SHELXE auto-tracing has been turned on"
  } else {
     set array(SHELXE) 0
  }

  return 1
}


############################################################################
proc check_enant { arrayname } {
############################################################################
  upvar #0 $arrayname array

  if { ![regexp "^P" $array(SPACE_GROUP)] } {
    #puts "non-primitive"
    set array(ENANT_FLAG) 0
    return 1
  }

  set enant [ GetChangeHandData $array(SPACE_GROUP) space_groupVar cxVar ]

  if {$enant == 1} {
    set array(ENANT_FLAG) 1
  } elseif {$enant == -1} {
    set array(ENANT_FLAG) 0
  } else {
    puts "Error: error encountered checking for enantiomorphic spacegroups"
  }
}

############################################################################
proc autotrace_available_setup {} {
############################################################################
  catch { exec [BinPath shelxe] } shelxe_stdoe
  set shelxe_info [split $shelxe_stdoe]
  if { [set k [lsearch -exact $shelxe_info Version]] > -1 } {
    set shelxe_version [split [lindex $shelxe_info [expr $k + 1]] /]
    if { [llength $shelxe_version] == 2 } {
      set shelxe_year [lindex $shelxe_version 0]
      set shelxe_month [lindex $shelxe_version 1]
      if { [string is integer $shelxe_year] &&  [string is integer $shelxe_year] } {
        if { $shelxe_year > 2009 } {
          return 1
        }
      }
    }
  }
  return 0
}

############################################################################
proc mrbump_run { arrayname } {
############################################################################
  upvar #0 $arrayname array
 
# Change OUTPUT_FILES if we are running in models only mode
   if { $array(MRBUMP_MODE) == "Model search only" } {
       set array(INPUT_FILES) "SEQIN"
       set array(OUTPUT_FILES) ""
   } elseif { $array(MRBUMP_MODE) == "Model search and Molecular Replacement" } {
       set array(INPUT_FILES) "HKLIN SEQIN"
       set array(OUTPUT_FILES) "HKLOUT XYZOUT"
       if { $array(USE_MOLREP) == 1 } { 
          if { $array(USE_PHASER) == 0 } { 
             set array(MR_PROGRAM_LIST) "MOLREP"
          } else {
             set array(MR_PROGRAM_LIST) "MOLREP PHASER"
          }
       } else { 
          if { $array(USE_PHASER) == 0 } { 
             set array(MR_PROGRAM_LIST) "MOLREP"
          } else {
             set array(MR_PROGRAM_LIST) "PHASER"
          }
       }
   } elseif { $array(MRBUMP_MODE) == "Molecular Replacement only" } {
       set array(INPUT_FILES) "HKLIN"
       set array(OUTPUT_FILES) "HKLOUT XYZOUT"
       if { $array(USE_MOLREP) == 1 } { 
          if { $array(USE_PHASER) == 0 } { 
             set array(MR_PROGRAM_LIST) "MOLREP"
          } else {
             set array(MR_PROGRAM_LIST) "MOLREP PHASER"
          }
       } else { 
          if { $array(USE_PHASER) == 0 } { 
             set array(MR_PROGRAM_LIST) "MOLREP"
          } else {
             set array(MR_PROGRAM_LIST) "PHASER"
          }
       }
   }

# Sanity Checks:

  # Make sure number of models to be used in MR is <= number that have been prepared
  if { $array(MRBUMP_MODE) == "Model search and Molecular Replacement" } {
     if { $array(USE_PHASER) == 1 } { 
        if { $array(ENSMODNUM) > $array(MRNUM) } {
               WarningMessage "Input Error: Number of models used in Phaser Ensemble should be <= Number of models used in MR."
               return 0
        }
     }
  }

  # Check for multiple alignment program
  if { [FindExecutable [ string tolower $array(MAPROGRAM) ] ] == "" } {
         # Not found
         WarningMessage "Input Error: $array(MAPROGRAM) program not found in system path."
         return 0
     }

  # If using FASTA search this must be done using a local version of FASTA
  if { $array(DOFASTA) == 1 } {
        set array(FASTALOCAL) 1
     } 

  # Check for FASTA program
  if { [FindExecutable [ string tolower "fasta34" ] ] == "" && $array(FASTALOCAL) == 1 } {
         if { [FindExecutable [ string tolower "fasta35" ] ] == "" } {
            if { [FindExecutable [ string tolower "fasta36" ] ] == "" } {
               # Not found
               WarningMessage "Dependency Error: fasta executable not found in system path. Unselect the option to run FASTA search locally and re-try. You can download fasta from http://www.ebi.ac.uk/fasta/. Versions fasta34, fasta35 or fasta36 will work with MrBUMP."
               return 0
            }
         }
     }

  if { $array(MRBUMP_MODE) == "Model search and Molecular Replacement" } {
     # Check for Molrep program
     if { $array(USE_MOLREP) == 1 } { 
        if { [FindExecutable [ string tolower "molrep" ] ] == "" } {
            # Not found
            WarningMessage "Input Error: Molrep program not found in system path."
            return 0
        }
     }
   
     # Check for Phaser program
     if { $array(USE_PHASER) == 1 } { 
        if { [FindExecutable [ string tolower "phaser" ] ] == "" } {
            # Not found
            WarningMessage "Input Error: Phaser program not found in system path."
            return 0
        }
     }
  }

  # Check for perl 
  if { [FindExecutable [ string tolower "perl" ] ] == "" && $array(SSMSEARCH) == 1 } {
         # Not found
         WarningMessage "Input Error: Perl not found in system path. Perl is required for the SSM search. Unselect it and retry."
         return 0
     }

  # Check the values for the FIXED component sequence identities
  for {set N 1} {$N <= $array(NFIXED)} {incr N 1} {
    if { $array(FIDEN,$N) <= 0.0 } {
       WarningMessage "Input Error: A sequence identity must be given for each fixed component entered for the MR search."
       return 0
    }
  }

  # Setup the IGNORE keyword. These are the PDB ids to ignore in the search
  set array(IGNORE) ""
  for {set N 1} {$N <= $array(NPDBIDS)} {incr N 1} {
    lappend array(IGNORE) $array(PDBID,$N)
  }
 
  # Setup the INCLUDE keyword. These are the PDB ids to include in the search
  set array(INCLUDE) ""
  for {set N 1} {$N <= $array(NCHAINIDS)} {incr N 1} {
    lappend array(INCLUDE) $array(CHAINID,$N)
  }
 
  # Check to see that chains are specified if not using FASTA search
  if { $array(DOFASTA) == 0 } { 
     if { $array(INCLUDE) == "" } {
        if { $array(NLOCAL) == 0 } {
            WarningMessage "Input Error: You must specify chains or local PDB files to use as search models if you are not using FASTA search."
            return 0
        }
     }
  }

  # Set the root directory
  set array(ROOTDIR) [GetDefaultDirPath]
  
  # Check to see if Dbviewer is set to True. Set DBVIEW to true if it is.
  if { $array(DBOUT) == 1} {
     # Check for graphviz executable 
     if { [FindExecutable [ string tolower "dot" ] ] == "" && $array(DBOUT) == 1 } {
         # Not found
         WarningMessage "Input Error: Dot (Graphviz) not found in system path. A Graphviz installation is required for the CCP4i dbviewer to work. Unselect CCP4i dbviewer option and retry."
         return 0
     } else {
         set array(DBVIEW) 1
     }
  }

  # Set DBVIEW to 0 if DBOUT is 0
  if { $array(DBOUT) == 0} {
     set array(DBVIEW) 0
  }

  return 1
}

############################################################################
proc phaserKeywords { arrayname counter } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  CreateLine line \
    help match \
    message "Phaser keyword and value (e.g. MACMR PROTOCOL OFF)" \
    label "Phaser keyword and value:" \
    widget PKEYWORD  -width 50

}

############################################################################
proc pdbCodes { arrayname counter } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  CreateLine line \
    help match \
    message "Define PDB codes to ignore" \
    label "PDB id" \
    widget PDBID 

}

############################################################################
proc chainCodes { arrayname counter } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  CreateLine line \
    help match \
    message "Define Chain id codes to include" \
    label "Chain id" \
    widget CHAINID 

}

############################################################################
proc localPDB { arrayname counter_pdb } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  set count [expr [join $counter_pdb -] - 1]

  CreateInputFileLine line \
      "Select a local PDB file to include in molecular replacement" \
      "Local PDB (loc$count)" \
      XYZIN DIR_XYZIN

  CreateLine line \
      message "Enter the chain to be used from the PDB file" \
      help loc_chainid \
      label "Chain identifier" \
      widget LOC_CHAINID -width 3 \
      label "Chain A will be used if left blank" -italic 

  CreateLine line \
      message "Enter the average RMS deviation for these coordinates relative to the target (Phaser only)" \
      help num_mr \
      label "RMS deviation (for Phaser input)" \
      widget LOC_RMS -width 3 \
      label "Leave blank for automatic calculation from sequence ID" -italic 

}

############################################################################
proc fixedPDB { arrayname counter_pdb } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  set count [expr [join $counter_pdb -] - 1]

  CreateInputFileLine line \
      "Select a PDB file to include as a fixed component in the molecular replacement search" \
      "Fixed PDB" \
      FIXED_XYZIN DIR_FIXED_XYZIN

  CreateLine line \
      message "Enter the sequence identity of this component" \
      help fiden \
      label "Sequence identity for this component" \
      widget FIDEN -width 5

}

############################################################################
proc mrbump_browse { arrayname dir_type} {
############################################################################
# Use the file browser to select a directory models/PDB files

  upvar #0 $arrayname array

  if { [SelectFile filename -directory] } {
    # The browser can return either a filename or a directory
    # name - make sure we get the leading directory in the
    # former case
    if { [file isdirectory $filename] } {
      set dirname $filename
    } else {
      set dirname [file dirname $filename]
    }
    # Update the parameters in the window
    if { $dir_type == "PREPDIR" } {
       set array(PREPDIR) $dirname
    } elseif { $dir_type == "PDBDIR" } {
       set array(PDBDIR) $dirname
    } elseif { $dir_type == "PDBLOCAL" } {
       set array(PDBLOCAL) $dirname
    }
  }
  return
}

############################################################################
proc mrbump_task_window { arrayname } {
############################################################################
  global configure

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname \
       "MrBUMP: Automated Model generation and Molecular Replacement" "MrBUMP" \
       [ list "Template Search Options" \
              "User specified search models" \
              "Search Model Preparation Options" \
              "Molecular Replacement and Refinement Options" \
              "Pre-determined Component" \
              "Model Building and Phase Improvement" \
              "Additional Options" \
              "Advanced Options" \
       ] ] == 0 } return

  SetProgramHelpFile "mrbump"

  if { [FindExecutable [ string tolower "fasta34" ] ] == "" } {
         if { [FindExecutable [ string tolower "fasta35" ] ] == "" } {
            if { [FindExecutable [ string tolower "fasta36" ] ] == "" } {
               # Not found
               WriteCredits [list "Fasta program not found (fasta34, 35 or 36) "] \
                 -label "Dependency Warning!" \
                 -link "Download from: http://www.ebi.ac.uk/fasta/" \
                       "http://www.ebi.ac.uk/fasta/"
            }
         }
   }

  # Check if autotrace is available in SHELXE
  set array(AUTOTRACE_AVAILABLE) [autotrace_available_setup]

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE 

  CreateLine line \
      message "Select the mode for MrBUMP to run" \
      label "Program Mode:" \
      widget MRBUMP_MODE  

#=DBviewer=============================================================

#  CreateLine line \
#      message "Use the CCP4 dbviewer GUI to view jobs and associated files." \
#      help dbout \
#      widget DBOUT -width 4 \
#      label "View job progress using CCP4 dbviewer GUI." \
#      label "Note: Graphviz should be installed on your machine" -italic

#=Cluster submission of jobs===========================================

  # Check to see if there is a cluster queue present
  set_cluster_flag $arrayname

  OpenSubFrame frame \
      -toggle_display CLUSTER_QUEUE open 1

  CreateLine line \
      message "Use this option to submit processing jobs to the cluster queue system" \
      help cluster \
      label "Submit processing jobs to cluster queue:" \
      widget CLUSTER -width 4 \
      label "An SGE or a PBS queuing system has been detected" -italic

  CloseSubFrame

#=FILES================================================================ 

  OpenFolder file

# Running in FULLMR mode: ############################################

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE open [list FULLMR]

  # Input Sequence file
  CreateInputFileLine line \
      "Enter name of the target sequence file" \
      "SEQ in" \
      SEQIN DIR_SEQIN

  # Input MTZ file
  CreateInputFileLine line \
     "Enter name of the target MTZ file" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_mrbump_soln" \
      -fileout XYZOUT DIR_XYZOUT "_mrbump_soln" \
      -setfileparam space_group_name SPACE_GROUP \
      -setfileparam resolution_max RESOLUTION_MAX \
      -command "set_acorn_flag $arrayname" \
      -command "set_shelxe_flag $arrayname" \
      -command "check_enant $arrayname"

  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "F    " F  [list F F.F_sigF.F] \
        -sigma "Sigma  " SIGF  [list F F.F_sigF.sigF ]

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "Free-R" FreeR_flag  [list FreeR_flag]

  # If an enantiomorphic spacgroup is detected present the user with the option to do MR using it
  OpenSubFrame frame \
      -toggle_display ENANT_FLAG open 1

  CreateLine line \
      message "Spacegroup read from the input MTZ file" \
      label "Spacegroup from MTZ file:" \
      varlabel SPACE_GROUP\
      message "Enantiomorphic Spacegroup found for the Spacegroup of the target MTZ data" \
      help useenant \
      label "      Do MR using enantiomorphic spacegroup as well" \
      widget USEENANT -width 4

  CloseSubFrame

  OpenSubFrame frame \
      -toggle_display ENANT_FLAG open 0

  CreateLine line \
      message "Spacegroup read from the input MTZ file" \
      label "Spacegroup from MTZ file:" \
      varlabel SPACE_GROUP\
      label "Note that MrBUMP will assume this spacegroup for the MR stage" -italic

  CloseSubFrame

  CreateOutputFileLine line \
      "Output MTZ File for solution" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateOutputFileLine line \
      "Output PDB File for solution" \
      "PDB out" \
      XYZOUT DIR_XYZOUT

  CreateLine line \
      message "Number of molecules in the asu" \
      help nmasu \
      label "Number of molecules in the asu:" \
      widget NMASU -width 3 \
      label "Leave blank for automatic calculation" -italic

  CloseSubFrame

######################################################################

# Running in MODELS mode: ############################################

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE open [list MODELS]

  # Input Sequence file
  CreateInputFileLine line \
      "Enter name of the target sequence file" \
      "SEQ in" \
      SEQIN DIR_SEQIN

  CreateLine line \
      message "Anticipated number of molecules in the asu" \
      help nmasu \
      label "Anticipated number of molecules in the asu:" \
      widget NMASU -width 3 \
      label "Governs largest multimer considered (default = 1)" -italic

  CloseSubFrame

######################################################################

# Running in MR ONLY mode: ###########################################

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE open [list MRONLY]

  # Input the Directory containing the MODELS for the MR run 
  CreateLine line \
    message "Enter search directory from previous MrBUMP job" \
    label "Search Directory from previous job" \
      widget PREPDIR -width 50

  # Make a "browse" button to allow the user to select directories
  # via the browser
  # This is a custom widget (from PJB's mosflm interface)!
  set browse [button $line.browse -text "Browse" \
	  -command "mrbump_browse $arrayname PREPDIR"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

  # Input MTZ file
  CreateInputFileLine line \
     "Enter name of the target MTZ file" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_mrbump_soln" \
      -fileout XYZOUT DIR_XYZOUT "_mrbump_soln" \
      -setfileparam space_group_name SPACE_GROUP \
      -setfileparam resolution_max RESOLUTION_MAX \
      -command "set_acorn_flag $arrayname" \
      -command "set_shelxe_flag $arrayname" \
      -command "check_enant $arrayname"

  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "F    " F  [list F F.F_sigF.F] \
        -sigma "Sigma  " SIGF  [list F F.F_sigF.sigF ]

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "Free-R" FreeR_flag  [list FreeR_flag]

  # If an enantiomorphic spacgroup is detected present the user with the option to do MR using it
  OpenSubFrame frame \
      -toggle_display ENANT_FLAG open 1

  CreateLine line \
      message "Spacegroup read from the input MTZ file" \
      label "Spacegroup from MTZ file:" \
      varlabel SPACE_GROUP\
      message "Enantiomorphic Spacegroup found for the Spacegroup of the target MTZ data" \
      help useenant \
      label "      Do MR using enantiomorphic spacegroup as well" \
      widget USEENANT -width 4

  CloseSubFrame

  OpenSubFrame frame \
      -toggle_display ENANT_FLAG open 0

  CreateLine line \
      message "Spacegroup read from the input MTZ file" \
      label "Spacegroup from MTZ file:" \
      varlabel SPACE_GROUP\
      label "Note that MrBUMP will assume this spacegroup for the MR stage" -italic

  CloseSubFrame

  CreateOutputFileLine line \
      "Output MTZ File for solution" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateOutputFileLine line \
      "Output PDB File for solution" \
      "PDB out" \
      XYZOUT DIR_XYZOUT

  CreateLine line \
      message "Number of molecules in the asu" \
      help nmasu \
      label "Number of molecules in the asu:" \
      widget NMASU -width 3 \
      label "Leave blank for automatic calculation" -italic

  CloseSubFrame

########################################################################

#=Template Search Options========================================================== 

#  OpenFolder 1 \
      MRBUMP_MODE open [list FULLMR MODELS] hide

  OpenFolder 1 closed

  CreateLine line \
      message "Do a FASTA search. Otherwise enter specific chains to use as models." \
      help do_fasta \
      widget DOFASTA -width 4 \
      label "Do a FASTA search for possible template models" \
      label "Requires fasta34, fasta35 or fasta36 to be installed" -italic

  CreateLine line \
      label "Note that without a FASTA search you must specify chains or local PDB files to be used as template models." -italic

  OpenSubFrame frame \
      -toggle_display DOFASTA open 1

  CreateLine line \
      message "E-value for FASTA search" \
      help evalue \
      label "E-value for FASTA search" \
      widget EVALUE -width 7 

#  CreateLine line \
#      message "Run FASTA sequence-based search locally" \
#      help fasta_local \
#      widget FASTALOCAL -width 4 \
#      label "Run the FASTA search locally." \
#      label "Requires fasta34 to be installed" -italic

  CloseSubFrame

  CreateLine line \
      message "Database Updating" \
      help update \
      widget UPDATE -width 4 \
      label "Update local copies of search databases" 

  CreateLine line \
      message "Multiple alignment program" \
      label "Multiple alignment program:" \
      widget MAPROGRAM 

  CreateLine line \
      message "Use SCOP (domain-based search) to search for templates" \
      help use_scop \
      label "Additional search methods to use:" \
      widget SCOPSEARCH -width 4 \
      label "SCOP    " \
      message "Use PQS (multimeric search) to search for templates" \
      help use_pqs \
      widget PQSSEARCH -width 4 \
      label "PQS    " \
      message "Use SSM (secondary structure-based search) to search for templates" \
      help use_ssm \
      widget SSMSEARCH -width 4 \
      label "SSM    " 

#=User specified search models========================================================== 

  OpenFolder 2 closed
#  OpenFolder 2 \
      MRBUMP_MODE open [list FULLMR MODELS] hide

  CreateLine line \
      label "Enter Chain id codes to be included in the template model search: (e.g. 1nio_A)"

  CreateExtendingFrame NCHAINIDS chainCodes \
      "Add Chain id codes to include in template search" \
      "Add Chain id" \
      CHAINID  

  CreateLine line \
      label "Enter local PDB files to be included in the molecular replacement search:"

  CreateExtendingFrame NLOCAL localPDB \
      "Add PDB files to be included in model preparation for MR" \
      "Add PDB file" \
      [list XYZIN DIR_XYZIN]  


#=Model Preperation Options================================================================ 

  OpenFolder 3 \
      MRBUMP_MODE open [list FULLMR MODELS] hide

  CreateLine line \
      message "Number of search matches from which to generate search models" \
      help num_mr \
      label "Maximum number of search results from which to generate search models for use in MR:" \
      widget MRNUM -width 3 

  CreateLine line \
      label "Search model types to create:"

  CreateLine line \
      message "Unmodified search model (most useful for ab initio generated search models)" \
      help mdlu \
      widget MDLU -width 4 \
      label "Umodified - " \
      label "No changes to search model" -italic

  CreateLine line \
      message "Generate search models using the PDBClip method" \
      help mdld \
      widget MDLD -width 4 \
      label "PDBClip - " \
      label "Remove waters, hydrogens and select most probable conformations for side chains" -italic

  CreateLine line \
      message "Generate search models using the Molrep method" \
      help mdlm \
      widget MDLM -width 4 \
      label "Molrep - " \
      label "Side chain truncation based on Molrep sequence alignment" -italic

  CreateLine line \
      message "Generate search models using the Chainsaw method" \
      help mdlc \
      widget MDLC -width 4 \
      label "Chainsaw - " \
      label "Side chain truncation based on multiple alignment sequence from $array(MAPROGRAM)" -italic

  CreateLine line \
      message "Generate search models using the Sculptor method" \
      help mdls \
      widget MDLS -width 4 \
      label "Sculptor - " \
      label "Side chain truncation and gap opening based on multiple alignment" -italic

  CreateLine line \
      message "Generate search models using the Polyalanine method" \
      help mdlp \
      widget MDLP -width 4 \
      label "Polyalanine - " \
      label "Removal of all side chains" -italic

 CreateLine line \
      message "Number ensembles to prepare (can be used in Phaser)" \
      help num_ensmod \
      label "Number of Ensemble models to prepare:" \
      widget ENSNUM -width 1 

  CreateLine line \
      message "Number of prepared models to use in each ensemble (can be used in Phaser)" \
      help num_ensmod \
      label "Maximum number of prepared models to use in each Ensemble model:" \
      widget ENSMODNUM -width 3 

#  CreateLine line \
      message "Generate search models using the Molrep method" \
      help mdlm \
      widget MDLM -width 4 \
      label "Create Molrep search models" 

#  CreateLine line \
      message "Generate search models using the Chainsaw method" \
      help mdlc \
      widget MDLC -width 4 \
      label "Create Chainsaw search models" 

#  CreateLine line \
      message "Generate search models using the Polyalanine method" \
      help mdlp \
      widget MDLP -width 4 \
      label "Create Polyalanine search models" 

#=Molecular Replacement and Refinement Options======================================================== 

  OpenFolder 4 \
      MRBUMP_MODE open [list FULLMR MRONLY] hide

  CreateLine line \
      message "Try search models in Molrep" \
      help use_molrep \
      label "Molecular replacement programs to try:" \
      widget USE_MOLREP -width 4 \
      label "Molrep    " \
      message "Try search models in Phaser" \
      help use_phaser \
      widget USE_PHASER -width 4 \
      label "Phaser    " 

  OpenSubFrame frame \
      -toggle_display USE_PHASER open 1

  CreateLine line \
      message "Number of processing cores to be used by Phaser (JOBS keyword)" \
      help pack \
      label "Number of cores to be used by Phaser:" \
      widget PJOBS -width 3 \
      label "Note: this value will be set to 1 for cluster submission" -italic

  CreateLine line \
      message "Number of clashes tolerated by Phaser (PACK keyword)" \
      help pack \
      label "Number of clashes to tolerate in Phaser:" \
      widget PACK -width 3 \
      label "Note: this value is per molecule in the a.s.u." -italic

  CloseSubFrame

  CreateLine line \
      message "Number of cycles of restrained refinement in Refmac (NCYC keyword)" \
      help ncyc \
      label "Number of cycles of restrained refinement in Refmac:" \
      widget NCYC -width 3 

  CreateLine line \
      message "Use TWIN option in Refmac - useful if data is twinned" \
      help reftwin \
      label "Use TWIN option in Refmac (requires Refmac 5.5 or later)" \
      widget REFTWIN -width 4 

#  CreateLine line \
      message "If set to true the program will try all of the search models in molecular replacement." \
      help tryall \
      widget TRYALL -width 4 \
      label "Try all search models (don't exit when the first solution is found)." 

  CreateLine line \
      help  tryall \
      message "Choose when you want to exit the MR stage." \
      label "Finish when" \
      widget TRYALL 

# Open the subframe for acorn if the resolution is good enough.

  OpenSubFrame frame \
      -toggle_display ACORN_FLAG open 1

  CreateLine line \
      message "Collected data has resolution higher than 1.7 Abgstroms. Select to use Acorn to improve phases" \
      help useacorn \
      label "Use Acorn to improve phases" \
      widget USEACORN -width 4

  CloseSubFrame

#=Pre-determined Component================================================== 

  OpenFolder 5 \
      NFIXED closed { 0 } open

  CreateLine line \
      label "Enter PDB files containing already determined fixed solution for the MR search:"

  CreateExtendingFrame NFIXED fixedPDB \
      "Add PDB files containing pre-determined fixed solution" \
      "Add PDB file" \
      [list FIXED_XYZIN DIR_FIXED_XYZIN]  

#=Model Building and Phase Improvement====================================== 

  OpenFolder 6 closed 

  CreateLine line \
      message "Perform automated model building using Buccaneer for each MR solution" \
      help buccaneer \
      widget BUCCANEER -width 4 \
      label "Buccaneer - " \
      label "Automated model building with Buccaneer" -italic

 CreateLine line \
      message "Number of automated building and refinement cycles to be run in Buccaneer" \
      help bcyc \
      label "Number of build-refine cycles in Buccaneer:" \
      widget BCYC -width 3 

  if { [FindExecutable [ string tolower "auto_tracing.sh" ] ] != "" } {
     CreateLine line \
         message "Perform automated model building using ARP/wARP for each MR solution" \
         help buccaneer \
         widget ARPWARP -width 4 \
         label "ARP/wARP - " \
         label "Automated model building with ARP/wARP" -italic
   
    CreateLine line \
         message "Number of automated building and refinement cycles to be run in ARP/wARP" \
         help acyc \
         label "Number of auto-build cycles in ARP/wARP:" \
         widget ACYC -width 3 
  }

  if { $array(AUTOTRACE_AVAILABLE) == 1 } {
     CreateLine line \
         message "Perform phase improvement and c-alpha tracing with SHELXE for each MR solution" \
         help shelxe \
         widget SHELXE -width 4 \
         label "SHELXE - " \
         label "Automated phase improvement and c-alpha trace" -italic
   
    CreateLine line \
         message "Number of automated c-alpha tracing cycles to run in SHELXE" \
         help scyc \
         label "Number of tracing cycles in SHELXE:" \
         widget SCYC -width 3 
  }

#=Additional Options======================================================== 

  OpenFolder 7 closed 

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE hide [list MRONLY]

  # Input the Directory where the is a local PDB mirror
  CreateLine line \
    message "Enter the full path to the location of the top level directory for the PDB database" \
    label "Path to local PDB mirror:" \
      widget PDBLOCAL -width 50

  # Make a "browse" button to allow the user to select directories
  # via the browser
  # This is a custom widget (from PJB's mosflm interface)!
  set browse [button $line.browse -text "Browse" \
	  -command "mrbump_browse $arrayname PDBLOCAL"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

  # Input the Directory containing locally stored PDB files to be used in the search
  CreateLine line \
    message "Enter directory where MrBUMP can search for the PDB files it might need" \
    label "Directory holding PDB files:" \
      widget PDBDIR -width 50

  # Make a "browse" button to allow the user to select directories
  # via the browser
  # This is a custom widget (from PJB's mosflm interface)!
  set browse [button $line.browse -text "Browse" \
	  -command "mrbump_browse $arrayname PDBDIR"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

  CreateLine line \
      label "Enter PDB id codes to be ignored in the template model search: (e.g 1nio)"

  CreateExtendingFrame NPDBIDS pdbCodes \
      "Add PDB id codes to ignore in template search" \
      "Add PDB id" \
      PDBID  

  CloseSubFrame

#  CreateLine line \
#      message "Enable HTML output of the results as they are generated." \
#      help htmlout \
#      widget HTMLOUT -width 4 \
#      label "HTML file output of results" 

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE open [list FULLMR MRONLY]

  CreateLine line \
      message "MrBUMP LITE: Delete non-essential files. Reduces excess disk space usage." \
      help lite \
      widget LITE -width 4 \
      label "LITE mode: Delete non-essential files - reduces disk usage" 

  CloseSubFrame

  CreateLine line \
      message "Checks for connection to PDB file servers" \
      help debug \
      widget CHECK -width 4 \
      label "Enable web connectivity test"

  CreateLine line \
      message "Debug mode (gives more verbose output)" \
      help debug \
      widget DEBUG -width 4 \
      label "Use debug mode." \
      label "Gives a more verbose output" -italic

  CreateLine line \
      message "If you are behind a firewall you may need to enter a proxy server address to access online services" \
      help proxy \
      label "Proxy to access internet (if required):" \
      widget PROXYSERVER -width 40 

#=Advanced ================================================================= 

  OpenFolder 8 closed 

  OpenSubFrame frame \
      -toggle_display MRBUMP_MODE open [list FULLMR MRONLY]

  OpenSubFrame frame \
      -toggle_display USE_PHASER open 1

  CreateLine line \
      label "Enter additional keyword options for Phaser" -italic

  CreateExtendingFrame NPKEY phaserKeywords \
      "Additional Phaser keywords" \
      "Add keyword" \
      PKEYWORD  

  CloseSubFrame

}
