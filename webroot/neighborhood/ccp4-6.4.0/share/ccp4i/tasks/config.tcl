#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =======================================================================
# config.tcl --
#
# Interface for user to config the interface
#
# CCP4Interface 
# Created Apr87 by Liz Potterton
#
#
# =======================================================================
#---------------------------------------------------------------------
proc config_edit_fonts { arrayname label_list var_list } {
#---------------------------------------------------------------------
  set n 0
  foreach var $var_list {
    CreateLine line \
      message "Enter the full font description" \
      label "[lindex $label_list $n]" \
      widget $var -width 65 \
      format template config_font
    incr n
  }
}

#------------------------------------------------------------------------------
proc config_task_window { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global configure

  set helpfile [SearchPath HELP general configure.html ]
  InitialisePreferences configure $arrayname

  if { [CreateTaskWindow $arrayname  \
        "Configure CCP4Interface" "Configure" \
        [ list "Configure CCP4i" \
        "CCP4i Utilities" "External Programs" \
        "Help" \
        "Hardware Resources" \
	"Networked Resources" \
        "Fonts" \
        "Add-on Parameters" ] \
	-action_buttons quit \
	-help_file $helpfile ] == 0 } return

  set savebutton [menubutton $array(WINDOW).buttons.save\
		-text "Save" \
		-indicatoron 1 -relief raised  \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
          	-menu $array(WINDOW).buttons.save.m1 ]

  menu $savebutton.m1 -tearoff 0

  $savebutton.m1 add command -label "Save to installation file" \
		-font $configure(FONT_REGULAR) \
	-command "save_configure $arrayname
		SaveInstallPreferences configure $arrayname
  	       InitialisePreferences configure configure
		   DbUpdateList -nosave"

  $savebutton.m1 add command -label "Save to user's home directory" \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
       		 -command "save_configure $arrayname
		       SavePreferences configure $arrayname
                       InitialisePreferences configure configure
					   DbUpdateList -nosave"

  bind $savebutton <Button-3> "KeywordHelp $helpfile saving_configuration"

  set testbutton [menubutton $array(WINDOW).buttons.test \
	-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
		-indicatoron 1 -relief raised  \
		-text "Test" \
		-indicatoron 1 -relief raised  \
                -menu $array(WINDOW).buttons.test.m1 ]
  menu $testbutton.m1 -tearoff 0
  $testbutton.m1 add command -label "Hypertext Viewer" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command "configure_test_hypertext"
  $testbutton.m1 add command -label "BLT & Printing" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command "configure_test_loggraph"
#  $testbutton.m1 add command -label "Inter-process Communication" \
#	-background $configure(COLOUR_PALE) \
#	-font $configure(FONT_REGULAR) \
#	-command "configure_test_run local $arrayname"
  $testbutton.m1 add command -label "Running Task" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command "configure_test_run remote $arrayname"

  bind $testbutton <Button-3> "KeywordHelp $helpfile testing"

  pack  $savebutton $testbutton -side left -expand 1
  SetProgramHelpFile [SearchPath HELP general configure.html ]

  OpenFolder 1

  CreateLine line \
    label "Command to set up CCP4 (used by remote jobs)" \
    widget CCP4_SETUP_COMMAND -width 50 \
    format margins

  CreateLine line \
    message "Set variable RUN_CCP4I. The default should be OK." \
    label "Command to run CCP4i (RUN_CCP4I)" \
    widget RUN_CCP4I -width 50 \
    format margins

  CreateLine line \
    label "Address for CCP4i mail" \
    widget MAIL_ADDRESS \
        -width 50 \
    format margins

  CreateLine line \
    label "BLT library directory (containing bltGraph.pro)" \
    widget BLT_LIBRARY \
	-width 50 \
    format margins

  CreateLine line \
    message "Set the number of entries per menu column when selecting MTZ labels" \
    label "Maximum length of drop-down menu columns" \
    widget MENU_LENGTH \
       -width 50 \
    format margins

  CreateLine line \
    message "Set the number of lines displayed per frame from very big logfiles" \
    label "Number of lines to display in a frame" \
    widget VIEW_TEXT_LINE_LIMIT \
       -width 50 \
    format margins

  CreateLine line \
    message "Set the maximum height of canvas in task interfaces" \
    label "Maximum height of canvas in task interfaces" \
    widget CANVAS_MAX_HEIGHT \
       -width 50 \
    format margins

  OpenFolder 2

  CreateLine line \
    label "Command to run Loggraph" \
    widget RUN_LOGGRAPH -width 50 \
    format margins

  CreateLine line \
    label "Command to run MapSlicer" \
    widget RUN_MAPSLICER -width 50 \
    format margins

  CreateLine line \
    label "Command to run DbViewer" \
    widget RUN_DBVIEWER -width 50 \
    format margins

  CreateLine line \
    label "Command to run CCP4mg" \
    widget RUN_CCP4MG -width 50 \
    format margins

  CreateLine line \
    label "Command to run Coot" \
    widget RUN_COOT -width 50 \
    format margins

  CreateLine line \
    label "Command to run JLigand" \
    widget RUN_JLIGAND -width 50 \
    format margins
	
  CreateLine line \
    label "Command to run iMosflm" \
    widget RUN_IMOSFLM -width 50 \
    format margins

  CreateLine line \
    label "Command to run viewhkl" \
    widget RUN_VIEWHKL -width 50 \
    format margins

  CreateLine line \
    label "Command to run idiffdisp" \
    widget RUN_IDIFFDISP -width 50 \
    format margins

  CreateLine line \
    label "Command to run TopDraw" \
    widget RUN_TOPDRAW -width 50 \
    format margins

  CreateLine line \
    label "Command to run Baubles for annotated logfiles" \
    widget RUN_BAUBLES -width 50 \
    format margins

  CreateLine line \
    widget EXPORT_TO_QTRVIEW \
    label "Export Coot and CCP4mg commands to QtRView"

  OpenFolder 3
 
  CreateLine line \
    label "Hypertext Viewer" \
    widget HYPERTEXT_VIEWER \
	-width 50 \
    format margins

  CreateLine line \
    message "Enter full path name to ensure CCP4i scripts can find this program" \
    label "Mapman program (convert maps for O)" \
    help map_format_conversion \
    widget O_MAPMAN \
	-width 50 \
    format margins

    CreateLine line \
    message "CCP4i scripts will reset MAPSIZE for maps bigger than usual mapman limit" \
    label "Default maximum map size for your version of Mapman" \
    widget MAPMAN_MAXSIZE \
    format margins


  CreateLine line \
    message "Enter full path name to ensure CCP4i scripts can find this program" \
    label "Mbkall program (convert maps for Quanta)" \
    help map_format_conversion \
    widget QUANTA_MBKALL \
        -width 50 \
    format margins

  CreateLine line \
    message "Enter full path of directory where Modeller executable has been installed" \
    label "Modeller install directory (MODINSTALL)" \
    help modeller \
    widget MODELLER_MODINSTALL -width 50 \
    format margins

  CreateLine line \
    message "Enter Modeller installation key" \
    label "Modeller install key" \
    help modeller \
    widget MODELLER_KEY -width 50 \
    format margins

  CreateLine line \
    message "Enter full executable name for Modeller (no aliases)" \
    label "Modeller program name" \
    help modeller \
    widget MODELLER_PROGRAM -width 50 \
    format margins

  CreateLine line \
    message "Enter full path name to ensure CCP4i scripts can find this program" \
    label "ShelxS program name" \
    help shelx \
    widget SHELX -width 50 \
    format margins

  CreateLine line \
    widget DISABLE_TASKS \
    label "Disable buttons for tasks where the underlying programs are missing"

  CreateLineTemplate MARGINS2 [list 0.0 0.45 0.8 0.85]
    
  CreateLine line \
    label "Give full path name for CCP4 programs to overcome name conflicts" \
	-italic

  CreateExtendingFrame NFULLPATHS configure_fullpaths \
        "Enter full path name for CCP4 programs" \
        "Add a program" \
      [ list FULLPATH_PROG FULLPATH_PATH ]

  OpenFolder 4

  CreateLine line \
    widget ENABLE_BUBBLE_HELP \
    label "Enable bubble help"

  OpenFolder 5

  CreateLine line \
    label "Default protocol for connecting to remote machines:" \
    widget REMOTE_PROTOCOL

  CreateLine line \
    label "Enter names of remote machines" \
        -italic

  CreateExtendingFrame N_REMOTE_MACHINES configure_remote_machines \
        "Specify remote machines used for large jobs" \
        "Add a machine" \
      [ list REMOTE_MACHINE ]

  CreateLine line \
    label "Enter names and commands for batch queues" \
        -italic

  CreateExtendingFrame N_BATCH_QUEUES configure_batch_queues \
        "Specify name and command to use batch queues" \
        "Add a batch queue" \
      [ list BATCH_QUEUE_NAME \
             BATCH_QUEUE_TYPE \
		BATCH_QUEUE_COM \
                BATCH_QUEUE_COMPOUND ] \
         -edit edit_batch_queues

  CreateLine line \
    label "Enter names and commands for Postscript Viewers" \
        -italic

  CreateExtendingFrame N_PS_PREVIEW configure_ps_viewers \
        "Specify Postscript viewers available on your site" \
        "Add a PS viewer" \
      [ list PS_PREVIEW_NAME \
             PS_PREVIEW_COM ]


#  CreateLine line \
#    label "Enter names and commands for text printers" \
#	-italic
#
#  CreateExtendingFrame N_TEXT_PRINTERS configure_text_printers \
#        "Specify text printers available on your site" \
#        "Add a text printer" \
#      [ list TEXT_PRINTER_NAME \
#	     TEXT_PRINTER_COM ]

  CreateLine line \
    label "Enter names and commands for black/white printers" \
	-italic

  CreateExtendingFrame N_MONO_PRINTERS configure_mono_printers \
        "Specify black&white printers available on your site" \
        "Add a black-white printer" \
      [ list MONO_PRINTER_NAME \
             MONO_PRINTER_COM ]

  CreateLine line \
    label "Enter names and commands for colour printers" \
        -italic

    CreateExtendingFrame N_COLOUR_PRINTERS configure_colour_printers \
        "Specify colour printers available on your site" \
        "Add a colour printer" \
      [ list COLOUR_PRINTER_NAME \
             COLOUR_PRINTER_COM ]

  OpenFolder 6


  CreateLine line \
	  label "Declare Proxy Server" \
	  message "Declare Proxy Server to connect to external databases" \
	  widget PROXY -width 30 \
	  label "Port" \
	  widget PORT \
	  format template MARGINS2


  CreateLine line \
	  message "Declare URL of external protein database" \
	  label "External Protein Sequence Database" \
	  widget DATABASE_URL \
	  -width 50 \
	  format margins

  OpenFolder 7 closed

  CreateLine line \
    message "Do you want large, medium  or small text in the interface?" \
    label "Use the" \
    widget FONT_SET \
    label "font set"

  CreateLineTemplate config_font [list 0.0 0.15]

  CreateLine line \
    label "Fonts used for the LARGE font set" -italic

  config_edit_fonts $arrayname \
	[list "Regular" "Italic" "Large" "Fixed width"] \
	[list L_FONT_REGULAR L_FONT_ITALIC L_FONT_BIG L_FONT_FIXED ]

  CreateLine line \
    label "Fonts used for the MEDIUM font set" -italic

  config_edit_fonts $arrayname \
        [list "Regular" "Italic" "Large" "Fixed width"] \
        [list M_FONT_REGULAR M_FONT_ITALIC M_FONT_BIG M_FONT_FIXED ]

  CreateLine line \
    label "Fonts used for the SMALL font set" -italic

  config_edit_fonts $arrayname \
	[list "Regular" "Italic" "Large" "Fixed width"] \
	[list S_FONT_REGULAR S_FONT_ITALIC S_FONT_BIG S_FONT_FIXED ]

  OpenFolder 8 closed

  CreateLine line \
    label "Parameter name" -italic \
    label "Parameter value" -italic \
    format margins \
    toggle_display N_EXT_PARAMETERS hide 0
   
  CreateExtendingFrame N_EXT_PARAMETERS configure_ext_parameters \
        "Enter additional parameter values for add-on programs" \
        "Add a parameter" \
      [ list EXT_PARAMETER_NAME EXT_PARAMETER_VALUE ]

}


#-------------------------------------------------------------------
proc save_configure { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array

  switch $array(FONT_SET) large {
    set array(FONT_REGULAR) $array(L_FONT_REGULAR)
    set array(FONT_ITALIC) $array(L_FONT_ITALIC)
    set array(FONT_BIG) $array(L_FONT_BIG)
    set array(FONT_FIXED) $array(L_FONT_FIXED)
  } medium {
    set array(FONT_REGULAR) $array(M_FONT_REGULAR)
    set array(FONT_ITALIC) $array(M_FONT_ITALIC)
    set array(FONT_BIG) $array(M_FONT_BIG)
    set array(FONT_FIXED) $array(M_FONT_FIXED)
  } small {
    set array(FONT_REGULAR) $array(S_FONT_REGULAR)
    set array(FONT_ITALIC) $array(S_FONT_ITALIC)
    set array(FONT_BIG) $array(S_FONT_BIG)
    set array(FONT_FIXED) $array(S_FONT_FIXED)
  }
}

#-------------------------------------------------------------------
proc configure_remote_machines { arrayname counter } {
#-------------------------------------------------------------------

  CreateLine line \
    message "Enter name of machine used for large jobs" \
    widget REMOTE_MACHINE \
        -width 30

}

#-------------------------------------------------------------------
proc configure_batch_queues { arrayname counter } {
#-------------------------------------------------------------------

  CreateLineTemplate MARGINS3 [list 0.0 0.25 0.55]

  CreateLine line \
    message "Enter name of batch queue to be seen by user on menu" \
    widget BATCH_QUEUE_NAME \
        -width 20 \
    message "Enter specific type of batch queue or choose Other if not known" \
    widget BATCH_QUEUE_TYPE \
        -width 20 \
        -command "edit_batch_queues $arrayname $counter" \
    message "Enter command required to use this batch queue" \
    widget BATCH_QUEUE_COM \
        -width 40 \
        -command "edit_batch_queues $arrayname $counter" \
    format template MARGINS3

}

#--------------------------------------------------------------------
proc edit_batch_queues { arrayname counter } {
#--------------------------------------------------------------------
# Make sure BATCH_QUEUE_COMPOUND is update if any component is
# changed. 
# If BATCH_QUEUE_COM is not yet set, default from choice of BATCH_QUEUE_TYPE

  upvar #0 $arrayname array

  if { $counter > 0 } {
  for { set i 1 } { $i <= $counter } { incr i } {

    if { $array(BATCH_QUEUE_TYPE,$i) != "" && $array(BATCH_QUEUE_COM,$i) == "" } {

      switch [GetValue $arrayname BATCH_QUEUE_TYPE,$i] "SGE" {
        set array(BATCH_QUEUE_COM,$i) "qsub -V -cwd"
      } "DQS" {
        set array(BATCH_QUEUE_COM,$i) "qsub -cwd"
      } "PBS" {
        set array(BATCH_QUEUE_COM,$i) "qsub"
      } "Condor" {
        set array(BATCH_QUEUE_COM,$i) "ccp4i_condorsub"
      } 
    }

    set array(BATCH_QUEUE_COMPOUND,$i) "[GetValue $arrayname BATCH_QUEUE_TYPE,$i] $array(BATCH_QUEUE_COM,$i)"
  } }

}

#-------------------------------------------------------------------
proc configure_ps_viewers { arrayname counter } {
#-------------------------------------------------------------------

  CreateLine line \
    message "Enter name of Postscript viewers" \
    help printers \
    widget PS_PREVIEW_NAME \
        -width 30 \
    message "Enter command required to start this viewer" \
    widget PS_PREVIEW_COM \
        -width 40 \
    format margins

}




#-------------------------------------------------------------------
proc configure_text_printers { arrayname counter } {
#-------------------------------------------------------------------

  CreateLine line \
    message "Enter name of printer to be seen by user on printer menu" \
    help printers \
    widget TEXT_PRINTER_NAME \
	-width 30 \
    message "Enter command required to send job to this print queue" \
    widget TEXT_PRINTER_COM \
	-width 40 \
    format margins

}

#-------------------------------------------------------------------
proc configure_mono_printers { arrayname counter } {
#-------------------------------------------------------------------
  CreateLine line \
    message "Enter name of black/white printer to be seen by user on menu" \
    help printers \
    widget MONO_PRINTER_NAME \
        -width 30 \
    message "Enter command required to send job to this print queue" \
    widget MONO_PRINTER_COM \
        -width 40 \
    format margins
}

#-------------------------------------------------------------------
proc configure_colour_printers { arrayname counter } {
#-------------------------------------------------------------------
  CreateLine line \
    message "Enter name of colour printer to be seen by user on menu" \
    help printers \
    widget COLOUR_PRINTER_NAME \
        -width 30 \
    message "Enter command required to send job to this print queue" \
    widget COLOUR_PRINTER_COM \
        -width 40 \
    format margins
}

#-----------------------------------------------------------------------
proc configure_fullpaths { arrayname counter } {
#-----------------------------------------------------------------------
  CreateLine line \
    message "Enter name of program" \
    help fullpath \
    widget FULLPATH_PROG -width 20 \
    message "Enter full path name for program" \
    widget FULLPATH_PATH -width 50  \
    format margins
   
}

#-----------------------------------------------------------------------
proc configure_ext_parameters { arrayname counter } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  if {[info exists array(EXT_PARAMETER_MESSAGE,$counter)] && \
      $array(EXT_PARAMETER_MESSAGE,$counter) != ""} {
    set message $array(EXT_PARAMETER_MESSAGE,$counter)
  } else {
    set message "Enter a name for this parameter"
  }
  CreateLine line \
    message $message \
    widget EXT_PARAMETER_NAME -width 30 \
    message "Enter the parameter value" \
    widget EXT_PARAMETER_VALUE -width 55  \
    format margins
} 


#-------------------------------------------------------------------
proc configure_test_loggraph { } {
#-------------------------------------------------------------------

  WarningMessage "The steps to test the loggraph program are described in the HTML file which will now be displayed automatically using the hypertext viewer you have installed. 
If the viewer does not work automatically you should look at
\$CCP4I_TOP/help/general/configure.html#test_loggraph
for instructions." -title "Test BLT & Printing" -stop

  KeywordHelp [SearchPath HELP general configure.html ] test_loggraph

  PleaseWait "Running the loggraph program.."

  if [catch "exec loggraph [SearchPath TOP test_data scaleit.log ] &" ] {
    WarningMessage "Failed to start loggraph program" -stop
  }
  PleaseWait
}

#-------------------------------------------------------------------
proc configure_test_hypertext { } {
#-------------------------------------------------------------------

  KeywordHelp [SearchPath HELP general configure.html ] test_hypertext

}



#-------------------------------------------------------------------
proc configure_test_print { } {
#-------------------------------------------------------------------
  set arrayname test_print
  global $arrayname
  set w .configure_test_print
 
  if { ![OpenWindow $w "Test Printers" "Test" \
	-help [SearchPath HELP general  configure.html ] ] } {
    return 0
  }
  CreateFrame $w $arrayname -noscroll

  DefineVariable $arrayname PRINT_COMMAND _text_printer FROM_MENU

  CreateLine line \
    help test_print \
    label "Test" \
    widget PRINT_COMMAND \
    label "printer"

  CreateButton $w dismiss Quit "destroy $w"
  CreateButton $w apply Apply   \
    "PrintFile [GetValue $arrayname PRINT_COMMAND] [SearchPath TOP test_data print.test]"

}

#-------------------------------------------------------------------
proc configure_test_run { mode arrayname } {
#-------------------------------------------------------------------
  global database
  global remote_started

  WarningMessage "To test running a remote job you will be given the interface to 'Convert to MTZ and Standardise' task with input parameters already set. 

Select 'Run Remote/Batch/Later' from the 'Run' menu on the bottom left of the window.
In the 'Run Remote' window select a machine and click the 'Run' button.

See the instructions in the help pages
  \$CCP4I_TOP/help/general/configure.html"

  RunTask import -def  [SearchPath CCP4I_TOP test_data test_import.def]


}

#----------------------------------------------------------------------
proc configure_test_run_abort { job_id } {
#----------------------------------------------------------------------
  global database
  set database(STATUS,$job_id) ABORTED
}
