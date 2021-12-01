#
#     Copyright (C) 2007 Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# pisa.tcl --
#
# Run the command line PISA to get information on interfaces and multimers
#
# CCP4Interface 
#
# =======================================================================

#==========================================================================
#==_setup==initialisations, defining local menus===========================
#==========================================================================

proc pisa_setup { typedefname arrayname } {

    upvar #0 $typedefname typedef
    
    set typedef(_pisa_input) { menu { "Generate new PISA analysis" "Use previous PISA analysis" } { ANALYSE REVIEW } }
    
    set typedef(_pisa_option) { menu { "list interfaces, monomers and assemblies" \
                                       "view interface, monomer, assembly or dissociate with Rasmol" \
                                       "view interface, monomer, assembly or dissociate with CCP4mg" \
                                       "download interface, monomer, assembly or dissociate" \
                                       "get details of an interface, monomer or assembly" \
                                       "generate XML output" \
                                        } { LIST VIEW MG DOWNLOAD DETAIL XML } }

    set typedef(_pisa_spec) { menu { "interface" \
                                       "monomer" \
                                       "assembly" \
                                       "dissociate" \
                                        } { interface monomer assembly dissociate } }

    set typedef(_pisa_spec_2) { menu { "interface" \
                                       "monomer" \
                                       "assembly" \
                                        } { interface monomer assembly } }

    return 1
    
}

#==========================================================================
#==_run==executed when user hits .....               ======================
#==========================================================================

proc pisa_run { arrayname } {

    upvar #0 $arrayname array
    global env

# Set PISA_WORK_ROOT to the ccp4i project directory
# This is where the output of the analysis step will be stored.
    set env(PISA_WORK_ROOT) [ GetDefaultDirPath ]

    set array(SESSION) "myname" 
    if { [StringSame [GetValue $arrayname INPUT] "ANALYSE"] } {
	set array(SESSION) [expr [DbGetNJOBS] +1]
    } elseif { $array(NAME) != "" } {
      set array(SESSION) $array(NAME)
    } else {
      PleaseWait
      WarningMessage "No session name entered"
      return 0
    }      

    if { [StringSame [GetValue $arrayname INPUT] "ANALYSE"] } {
     set array(INPUT_FILES) "XYZIN"
   }
   if { [StringSame [GetValue $arrayname INPUT] "REVIEW"] && [StringSame [GetValue $arrayname OPTION] "DOWNLOAD"] } {
     set array(OUTPUT_FILES) "XYZOUT"
   }
   if { [StringSame [GetValue $arrayname INPUT] "REVIEW"] && [StringSame [GetValue $arrayname OPTION] "XML"] } {
     set array(OUTPUT_FILES) "XMLOUT"
   }

   if { [StringSame [GetValue $arrayname INPUT] "ANALYSE"] } {
     SetDefaultTitle $arrayname "new PISA session"
   } else {
     SetDefaultTitle $arrayname "review PISA session $array(SESSION)"
   }

   return 1

}

#==========================================================================
#==_task_window==core procedure. all commands to define graphical interface
#==========================================================================

proc pisa_task_window { arrayname } {

    upvar #0 $arrayname array
    
    if { [CreateTaskWindow $arrayname \
	      "Analyse protein interfaces" "Pisa" [list "Generate new PISA analysis" "Use previous PISA analysis" ] ] == 0 } return

  SetProgramHelpFile "pisa"

#==========================================================================
#==PROTOCOL==TITLE AND KEY DECISIONS=======================================
#==========================================================================
    
    OpenFolder protocol
    
    CreateTitleLine line TITLE

    CreateLine line \
        label "For each PDB file, run a new analysis, then use subsequent runs to get more details or to view" -italic 
 
    CreateLine line \
        message "Generate new interface information, or re-visit a previous job" \
        widget INPUT 

#=========================================================================
#==FOLDER 1==Run PISA and generate output directory of results  ==========
#=========================================================================
    
    OpenFolder 1 INPUT open ANALYSE hide

    CreateInputFileLine line \
        "Enter name of input pdb file" \
        "PDB in" \
        XYZIN DIR_XYZIN 

#===========================================================================
#==FOLDER 2==Use results directory from previous run =======================
#===========================================================================

    OpenFolder 2 INPUT open REVIEW hide

    CreateLine line label "Review previously generated results, from job " \
       widget NAME \
       label " of the current project"
    
    CreateLine line \
        message "Choose which mode of PISA to run" \
        widget OPTION

    CreateLine line \
        label "for " \
        widget SPEC \
        label "number " \
        widget SERIAL_NO \
        toggle_display OPTION open [list "VIEW" "MG" "DOWNLOAD"]

    CreateLine line \
        label "for " \
        widget SPEC_2 \
        label "number " \
        widget SERIAL_NO \
        toggle_display OPTION open [list "DETAIL"]

    CreateOutputFileLine line \
        "Output coordinate file from download option" \
        "PDB out" \
        XYZOUT DIR_XYZOUT \
        -toggle_display OPTION open { DOWNLOAD }

    CreateOutputFileLine line \
        "Output XML file" \
        "XML out" \
        XMLOUT DIR_XMLOUT \
        -toggle_display OPTION open { XML }

}
