# ======================================================================
# demo.tcl --
#
# CCP4Interface 
#
# =======================================================================

proc ample_prereq { } {
  if { ![file exists [FindExecutable ample]] } {
    return 0
  }
  return 1
}

############################################################################
proc ample_setup { typedefVar arrayname } {
############################################################################
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _ample_mode [ list "Ab initio modelling and Molecular Replacement" \
	          		"NMR or Homologue modelling and Molecular Replacement" ] \
	     [ list ABINITIO NMRHOM ] 

  return 1
}

############################################################################
proc mrbumpKeywords { arrayname counter } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "mrbump" 
  
  CreateLine line \
    help match \
    message "MrBUMP keyword and value (e.g. PJOBS 4)" \
    label "MrBUMP keyword and value:" \
    widget MKEYWORD  -width 50

}

############################################################################
proc ampleArguments { arrayname counter } {
############################################################################
  upvar #0 $arrayname array

  SetProgramHelpFile "ample" 
  
  CreateLine line \
    help match \
    message "AMPLE command line argument and value (e.g. -ASU <no_of_mols>)" \
    label "AMPLE command line argument and value:" \
    widget AKEYWORD  -width 50

}

############################################################################
proc ample_browse { arrayname dir_type} {
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
    if { $dir_type == "ROSETTA_DIR" } {
       set array(ROSETTA_DIR) $dirname
    } elseif { $dir_type == "RunDir" } {
       set array(RunDir) $dirname
    } elseif { $dir_type == "MODELS_LOCATION" } {
       set array(MODELS_LOCATION) $dirname
    } elseif { $dir_type == "LGA" } {
       set array(LGA) $dirname
    }
  }
  return
}

############################################################################
proc ample_browse_file { arrayname file_type} {
############################################################################
# Use the file browser to select a directory models/PDB files

  upvar #0 $arrayname array

  if { [SelectFile filename] } {
    # The browser can return either a filename or a directory
    # name - make sure we get the leading directory in the
    # former case
    # Update the parameters in the window
    if { $file_type == "SCWRL" } {
       set array(SCWRL) $filename
    } elseif { $file_type == "MAX" } {
       set array(MAX) $filename
    } elseif { $file_type == "Theseus" } {
       set array(Theseus) $filename
    } elseif { $file_type == "ROSETTA" } {
       set array(ROSETTA) $filename
    } elseif { $file_type == "RDB" } {
       set array(RDB) $filename
    } elseif { $file_type == "Rosetta_cluster" } {
       set array(Rosetta_cluster) $filename
    } elseif { $file_type == "fragsexe" } {
       set array(fragsexe) $filename
    } elseif { $file_type == "3mers" } {
       set array(3mers) $filename
    } elseif { $file_type == "9mers" } {
       set array(9mers) $filename
    }
  }
  return
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
proc ample_run { arrayname } {
############################################################################
  upvar #0 $arrayname array
 
  # Make sure at lease one MR program has been chosen
  if { $array(USE_MOLREP) == 0 } {
     if { $array(USE_PHASER) == 0 } { 
            WarningMessage "Input Error: You must select at least one Molecular Replacement program! (MOLREP and/or PHASER)"
            return 0
     }
  }

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc ample_task_window { arrayname } {
#---------------------------------------------------------------------
  global configure

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"AMPLE (beta) - Ab inito modelling for Molecular Replacement" "AMPLE" \
        [ list "Input Files"  \
	"Fragment Files" \
	"Rosetta Installation"  \
	"Modelling Options"  \
	"Molecular Replacement Options"  \
	"Model Building Options" \
        "Advanced Options" \
        ] ] == 0 } return

# Set the name of the CCP4 program help file to use
# (set it to refmac because it is most suitable program for this example!)
  SetProgramHelpFile "refmac"

  # Check if autotrace is available in SHELXE
  set array(AUTOTRACE_AVAILABLE) [autotrace_available_setup]
  if { $array(AUTOTRACE_AVAILABLE) == 1 } {
     set array(USE_SHELXE) 1
  }


#=PROTOCOL==============================================================

  OpenFolder protocol 

  #CreateTitleLine line TITLE

  CreateLine line \
    message "Enter job title (use only alphanumeric, spaces, brackets and underscores)" \
    help  title \
    label "Job title" \
    widget TITLE  -width 65 \
      -command "check_title_line $arrayname TITLE"
 
  set link_target "http://ccp4wiki.org/~ccp4wiki/wiki/index.php?title=Ab_initio_modelling_and_automated_molecular_replacement_with_AMPLE"
  set urlbrowser [button $line.urlbrowser \
          -text "Ample User Guide" \
          -command "open_url $link_target -remote"]

  $urlbrowser configure -font $configure(FONT_SMALL)
  pack $urlbrowser -side left  

  CreateLine line \
      message "Select the mode for AMPLE to run" \
      label "Program Mode:" \
      widget AMPLE_MODE  

#===========================================
#in files
#===========================================

### Ab initio mode ##########################################

  OpenFolder 1 open

  OpenSubFrame frame \
      -toggle_display AMPLE_MODE open [list ABINITIO]

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

  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "F    " F  [list F F.F_sigF.F] \
        -sigma "Sigma  " SIGF  [list F F.F_sigF.sigF ]

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "Free-R" FreeR_flag  [list FreeR_flag]

  CreateLine line \
	message "Number of Processors" \
        label "Number of Processors" \
	widget NProc \
	  -width 3 

  CloseSubFrame

### NMR or Homologue re-modelling ###########################

  OpenSubFrame frame \
      -toggle_display AMPLE_MODE open [list NMRHOM]

  # Input Sequence file
  CreateInputFileLine line \
      "Enter name of the target sequence file" \
      "SEQ in" \
      SEQIN DIR_SEQIN

  # Input Sequence file
  CreateInputFileLine line \
      "Enter name of the NMR or homologue PDB file" \
      "PDB in" \
      XYZIN DIR_XYZIN

  # Input MTZ file
  CreateInputFileLine line \
     "Enter name of the target MTZ file" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_mrbump_soln" \

  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "F    " F  [list F F.F_sigF.F] \
        -sigma "Sigma  " SIGF  [list F F.F_sigF.sigF ]

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "Free-R" FreeR_flag  [list FreeR_flag]

  CreateLine line \
	message "Number of Processors" \
        label "Number of Processors" \
	widget NProc \
	  -width 3 

  CloseSubFrame

#############################################################

#===========================================
  #fragments
#===========================================
  OpenFolder 2 open

  CreateLine line \
	message "To generate fragment files for your sequence you need to use the Robetta Fragment library server" \
        label "To generate fragment files for your sequence you need to use the Robetta Fragment library server" 

  CreateLine line \
	message "Robetta Server (registration required)" \
        label "" 

  set link_target "http://robetta.bakerlab.org"
  set urlbrowser [button $line.urlbrowser -highlightbackground white -highlightthickness 7 \
          -text "Click here to go to online Robetta Server (registration required)" \
          -command "open_url $link_target -remote"]

  $urlbrowser configure -font $configure(FONT_SMALL)
  pack $urlbrowser -side left -expand 1  


  CreateLine line \
	message "3mers (aaXXXX_03_05.200_v1_3)" \
        label "3mers (aaXXXX_03_05.200_v1_3)" \
	widget 3mers \
	  -width 30 

  set browse [button $line.browse -text "Browse" \
	  -command "ample_browse_file $arrayname 3mers"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

  CreateLine line \
	message "9mers (aaXXXX_09_05.200_v1_3)" \
        label "9mers (aaXXXX_09_05.200_v1_3)" \
	widget 9mers \
	  -width 30 

  set browse [button $line.browse -text "Browse" \
	  -command "ample_browse_file $arrayname 9mers"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

#===========================================
  #rosetta installation details
#===========================================

  OpenFolder 3

  CreateLine line \
	message "Rosetta Dir" \
        label "Rosetta Installation Directory" \
	widget ROSETTA_DIR \
	  -width 50 

  set browse [button $line.browse -text "Browse" \
	  -command "ample_browse $arrayname ROSETTA_DIR"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

#===========================================
  #Modelling options
#===========================================

  OpenFolder 4 closed

  if { [FindExecutable "Scwrl4" ] != "" } {
     CreateLine line \
         message "Use SCWRL to add side chains to models (alternative to using ROSETTA-added side chains)" \
         help scwrl \
         widget USE_SCWRL -width 4 \
         label "SCWRL - " \
         label "alternative method for adding side chains to decoy models" -italic
  }

  CreateLine line \
	message "Set the number of models to be generated by Rosetta for cluster search (default 500)" \
        label "Number of models to generate:" \
	widget NMODELS \
	  -width 3 

#===========================================
  #Molecular replacement options
#===========================================

  OpenFolder 5 closed

  CreateLine line \
      message "Try search models in MOLREP" \
      help use_molrep \
      label "Molecular replacement programs to try:" \
      widget USE_MOLREP -width 4 \
      label "MOLREP    " \
      message "Try search models in PHASER" \
      help use_phaser \
      widget USE_PHASER -width 4 \
      label "PHASER    " 

  CreateLine line \
      message "Try all models in molecular repalcement otherwise exit on first success" \
      help update \
      widget TRYALL -width 4 \
      label "Test all generated models in MR (otherwise exit on first success)" 


#===========================================
  #Model building options
#===========================================

  OpenFolder 6 closed

  CreateLine line \
      message "Use Buccaneer to do automated model building after molecular replacement" \
      help shelxe \
      widget USE_BUCC -width 4 \
      label "Buccaneer - " \
      label "automted model building cycled with refinement" -italic

  CreateLine line \
      message "Use ARP/wARP to do automated model building after molecular replacement" \
      help arpwarp \
      widget USE_ARP -width 4 \
      label "ARP/wARP - " \
      label "automted model building cycled with refinement" -italic

  if { $array(AUTOTRACE_AVAILABLE) == 1 } {
     CreateLine line \
         message "Use SHELXE to perform phase improvement and a c-alpha trace after molecular replacement" \
         help shelxe \
         widget USE_SHELXE -width 4 \
         label "SHELXE - " \
         label "phase improvement and c-alpha tracing (requires beta-release version of SHELXE)" -italic
  }

#=Advanced =================================================================  
 
  OpenFolder 7 closed  
  
  CreateLine line \
      label "Enter additional command line options for AMPLE" -italic 
 
  CreateExtendingFrame NAMPKEY ampleArguments \
      "Additional command line arguments" \
      "Add argument" \
      AKEYWORD   

#  CloseSubFrame

  CreateLine line \
      label "Enter additional keyword options for MrBUMP" -italic 
 
  CreateExtendingFrame NBUMPKEY mrbumpKeywords \
      "ARSE Additional MrBUMP keywords" \
      "Add keyword" \
      MKEYWORD   

#  CloseSubFrame

}
