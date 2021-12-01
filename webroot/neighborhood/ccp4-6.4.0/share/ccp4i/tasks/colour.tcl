#
#     Copyright (C) 1999-2007  Liz Potterton, Peter Briggs, Francois Remacle
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# =======================================================================
# colour.tcl --
#
# Interface for user to configure the colourisation of the joblist/dbviewer
#
# CCP4Interface 
# Created Dec07 by Francois Remacle
#
# =======================================================================
#---------------------------------------------------------------------
proc colour_applyColor { color path arrayEntry arrayname} {
#---------------------------------------------------------------------
  upvar #0 $arrayname myarray
  if {$color == "tk_chooseColor"} {
    set color [tk_chooseColor]
  }
  if {$color != ""} {
    set myarray($arrayEntry) $color
	$path.colorButton configure -text "Colour: $color"
  } else {
    set color "black"
    set myarray($arrayEntry) ""
	$path.colorButton configure -text "Default Value"
  }
  $path.l1 configure -foreground "$color"
  $path.colorButton configure -foreground "$color"
  if {[string first "Status" [$path.l1 cget -text] ]==-1 && \
      [string first "Job" [$path.l1 cget -text] ]==-1} {
    $path.e2 configure -foreground "$color"
  }
  
  if {[string first "BG" $arrayEntry]==-1} {
    set compareWith [string replace $arrayEntry 6 6 "_BG_"]
  } else {
    set compareWith [string replace $arrayEntry 6 8]
  }
  #Display Warning if the user uses same color on same characteristic for both
  #foreground and background
  if {[GetValue $arrayname COLOUR_MODE]==[GetValue $arrayname BG_COLOUR_MODE] \
      && $color==[GetValue $arrayname $compareWith] } {
    WarningMessage "Be careful you are using the same colour for text and
                    \Background on the same	characteristic!"
  }
}
#---------------------------------------------------------------------
proc colour_addColorMenu { path arrayEntry arrayname } {
#---------------------------------------------------------------------
  global configure
  set color [GetValue $arrayname $arrayEntry]
  if {$color!=""} {
    set infotext "Colour: $color"
  } else {
    set infotext "Default Value"
  }
  menubutton $path.colorButton    -text "$infotext"\
  			-relief raised -padx 7 -pady 2 -borderwidth 1 -width 15 \
			-font $configure(FONT_REGULAR) -anchor center \
            -menu $path.colorButton.m
  place $path.colorButton -in $path -relx 0.5

  set colours [list red green blue yellow orange darkred darkgreen \
                    darkblue gray black white]
  set me [menu $path.colorButton.m -tearoff 0]
  foreach colour $colours {
  $me add command \
         -command "colour_applyColor $colour $path $arrayEntry $arrayname" \
         -background "$colour" \
         -activebackground "$colour" 
  }
  $me add command \
        -label "Other Color"  \
        -command "colour_applyColor tk_chooseColor $path $arrayEntry $arrayname"
  if {[string first "Status" [$path.l1 cget -text] ]!=-1 } {
    $me add command \
         -label "Default"  \
	     -command "colour_applyColor \"\" $path $arrayEntry $arrayname"
  }

  if {[GetValue $arrayname $arrayEntry] != ""} {
  	$path.colorButton configure -foreground [GetValue $arrayname $arrayEntry]
	$path.l1 configure -foreground [GetValue $arrayname $arrayEntry]
	if {[string first "Status" [$path.l1 cget -text] ]==-1 && \
	    [string first "Job" [$path.l1 cget -text] ]==-1} {
		$path.e2 configure -foreground [GetValue $arrayname $arrayEntry]
	}
  }

}
#---------------------------------------------------------------------
proc colour_Task { arrayname counter } {
#---------------------------------------------------------------------
     
  CreateLine taskColor  \
    	label "      Taskname    " \
    	widget TASK_NAME
  colour_addColorMenu $taskColor "COLOUR_TASK,$counter" $arrayname
    
  return 1
}
#---------------------------------------------------------------------
proc colour_Title { arrayname counter } {
#---------------------------------------------------------------------
  
  CreateLine titleColor  \
    	label "      Title containing word(s)    " \
    	widget WORD_TITLE
  colour_addColorMenu $titleColor "COLOUR_WORD,$counter" $arrayname
    
  return 1
}
#---------------------------------------------------------------------
proc colour_BackagroundTask { arrayname counter } {
#---------------------------------------------------------------------
   
  CreateLine taskColor  \
    	label "      Taskname    " \
    	widget TASK_NAME_BG
  colour_addColorMenu $taskColor "COLOUR_BG_TASK,$counter" $arrayname
    
  return 1
}
#---------------------------------------------------------------------
proc colour_BackagroundTitle { arrayname counter } {
#---------------------------------------------------------------------
  
  CreateLine titleColor  \
    	label "       Title containing word(s)    " \
    	widget WORD_TITLE_BG
  colour_addColorMenu $titleColor "COLOUR_BG_WORD,$counter" $arrayname
    
  return 1
}

#------------------------------------------------------------------------------
proc colour_task_window { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global configure

  set helpfile [SearchPath HELP general configure.html ]
  InitialisePreferences configure $arrayname

if { [CreateTaskWindow $arrayname  \
        "Configure Job list colours" "Colours" \
        [ list "Customize colours of Job list"] \
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
	-command "SaveInstallPreferences configure $arrayname
  	       InitialisePreferences configure configure
		   DbUpdateList -nosave"

  $savebutton.m1 add command -label "Save to user's home directory" \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
       		 -command "SavePreferences configure $arrayname
                       InitialisePreferences configure configure
					   DbUpdateList -nosave"

  bind $savebutton <Button-3> "KeywordHelp $helpfile saving_configuration"
 
  pack  $savebutton -side left -expand 1
  SetProgramHelpFile [SearchPath HELP general configure.html ]
  
  
  OpenFolder 1
  
  CreateLine ColourOrNotColour \
    widget IFCOLOUR \
    label "Enable job colourisation"
	
  OpenSubFrame iwantcolour toggle_display IFCOLOUR open 1
  
  CreateLine defaulparam label "Default colours :"
  $defaulparam.l1 config -bg [GetValue configure COLOUR_PALE]
  
  CreateLine defaulparam2 \
    label "   These colours will be applied to all jobs in \
              the list that do not match any colouring specified below" -italic
  $defaulparam2.l1 config -height 2

  CreateLineTemplate twoitems {0.02 0.5}

  CreateLine defaultBack \
    label "      Job background "\
	format template twoitems 	
  colour_addColorMenu $defaultBack BG_DEFAULT $arrayname	
  
  CreateLine defaultText \
	label "      Job text " \
	format template twoitems
  colour_addColorMenu $defaultText TEXT_DEFAULT $arrayname	
  
  CreateLine persoparam label "Customised job colours:"
  $persoparam.l1 config -bg [GetValue configure COLOUR_PALE]

  CreateLine colors \
    label "   Set custom job background colour based on: " \
	format template twoitems \
    widget BG_COLOUR_MODE
  
  OpenSubFrame StatusColor toggle_display BG_COLOUR_MODE open "status"
  
  CreateLine colorFinished \
  		label "      Status FINISHED  "
  colour_addColorMenu $colorFinished COLOUR_BG_FINISHED $arrayname

  CreateLine colorFailed \
  		label "      Status FAILED  "
  colour_addColorMenu $colorFailed COLOUR_BG_FAILED $arrayname
		
  CreateLine colorRunning \
  		label "      Status RUNNING  "
  colour_addColorMenu $colorRunning COLOUR_BG_RUNNING $arrayname
  
  CreateLine colorBatch \
  		label "      Status BATCH  "
  colour_addColorMenu $colorBatch COLOUR_BG_BATCH $arrayname
  
  CreateLine colorKilled \
  		label "      Status KILLED  "
  colour_addColorMenu $colorKilled COLOUR_BG_KILLED $arrayname

  CloseSubFrame
  
  OpenSubFrame StatusColor toggle_display BG_COLOUR_MODE open "task"
   
  CreateExtendingFrame N_COLOUR_BG_TASK colour_BackagroundTask \
        "Add one task name for colouring" \
  		"Add colouring" [list TASK_NAME_BG COLOUR_BG_TASK]
		
  CloseSubFrame
  
  OpenSubFrame StatusColor toggle_display BG_COLOUR_MODE open "title"
  
  CreateExtendingFrame N_COLOUR_BG_WORD colour_BackagroundTitle \
        "Add one word for colouring" \
  		"Add Colouring" [list WORD_TITLE_BG COLOUR_BG_WORD]

  CloseSubFrame	

  CreateLine blank label " "

  CreateLine colors \
    label "   Set custom job text colour based on: " \
	format template twoitems \
    widget COLOUR_MODE
  
  OpenSubFrame StatusColor toggle_display COLOUR_MODE open "status"

  CreateLine colorFinished \
		label "      Status FINISHED  "
  colour_addColorMenu $colorFinished COLOUR_FINISHED $arrayname

  CreateLine colorFailed \
  		label "      Status FAILED  "
  colour_addColorMenu $colorFailed COLOUR_FAILED $arrayname
		
  CreateLine colorRunning \
  		label "      Status RUNNING  "
  colour_addColorMenu $colorRunning COLOUR_RUNNING $arrayname
  
  CreateLine colorBatch \
  		label "      Status BATCH  "
  colour_addColorMenu $colorBatch COLOUR_BATCH $arrayname
  
  CreateLine colorKilled \
  		label "      Status KILLED  "
  colour_addColorMenu $colorKilled COLOUR_KILLED $arrayname

  CloseSubFrame
  
  OpenSubFrame taskColor toggle_display COLOUR_MODE open "task"
   
  CreateExtendingFrame N_COLOUR_TASK colour_Task \
                      "Add one task name for colouring" \
  		              "Add colouring" \
                      [list TASK_NAME COLOUR_TASK]
		
  CloseSubFrame
  
  OpenSubFrame titleColor toggle_display COLOUR_MODE open "title"
  
  CreateExtendingFrame N_COLOUR_WORD colour_Title \
                       "Add one word for colouring" \
  		               "Add Colouring" \
                       [list WORD_TITLE COLOUR_WORD]

  CloseSubFrame
  
  CloseSubFrame
  
  }
