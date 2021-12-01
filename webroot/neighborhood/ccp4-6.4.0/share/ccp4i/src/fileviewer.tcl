#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================
# CCP4 Interface - fileviewer.tcl
#
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title File Viewer (src/fileviewer.tcl)
#d_intro_title File Viewer
#d_intro The procedures in the file src/fileselect.tcl are concerned with \
display of files.  A procedure to display a specific file type such as LOG \
is called LOGViewer.

#-------------------------------------------------------------------
proc fileviewer { } {
#-------------------------------------------------------------------
#d_sum Setup procedure called if file viewer is run stand-alone
#d_desc The name of file to display is  passed from ccp4i script \
as system(SCRIPT)
#
  global system

  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src local.tcl]
  source [SearchPath TOP src window.tcl]
  source [SearchPath TOP src varmenu.tcl]
  source [SearchPath TOP src fileselect.tcl]
  source [SearchPath TOP src CCP4_utils.tcl]
  source [SearchPath TOP src util_windows.tcl]

  CreateSessionLog 
  OpenServerPort

  if { [info exist system(SCRIPT) ] && $system(SCRIPT) != "" } { 
    set file $system(SCRIPT) 
  } else {
    set file {}
  }
  FileViewer $file

}

#------------------------------------------------------------------------
proc ExitFileViewer { } {
#------------------------------------------------------------------------
#d_sum Called on exiting file viewer - will terminate process in stand-alone mode
  global system
# The user has picked the Cancel/quit button on the window - exit
# ccp4i if we are in fileviewer mode
  if { [ElementExists system RUN_MODE ] &&
	[StringSame $system(RUN_MODE) fileviewer] } { exit }
}


#------------------------------------------------------------------------
proc FileViewer { { file {} } args } {
#------------------------------------------------------------------------
#d_sum Display a file 
#d_ref CCP4I programmers/FileViewer.html See Programmers Documentation

  global system
  global fileviewer

  set format ANY
  set query 1
  set viewer {}
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    format {
      incr n; set format [lindex $args $n]
    } noque {
      set query 0
    } viewer { 
      incr n; set viewer [lindex $args $n]
    }
    incr n
  }

# If file name is input then just display it
  if { $file != "" && [file exists $file] && [file isfile $file] } { 
    return [fileviewer0 $file $format $viewer]
  }

# If mode is noquery then quit here
  if { !$query } { return 0}

# Decide a default directory for the file selection
  if { ![ElementExists fileviewer DEFDIR ] } { 
    if { [GetCurrentProject] != "" } {
      set fileviewer(DEFDIR) [GetCurrentProject]
    } else {
      set fileviewer(DEFDIR) "CURRENT"
    }
  }

# Just make sure everything for file selection is installed
  if { ![regexp SelectFile [info proc "SelectFile"] ] } {
     source [SearchPath TOP src utils.tcl]
     source [SearchPath TOP src local.tcl]
     source [SearchPath TOP src window.tcl]
     source [SearchPath TOP src fileselect.tcl]
  }

# Get user to select file(s)

  SelectFile file_defdir_type -title "Select File to View" \
	-defdir $fileviewer(DEFDIR) \
	-filetype $format file_types \
	-filter "*.*" \
	-viewer

}

#--------------------------------------------------------------------
proc fileviewer0 { { file {} } { format ANY } { viewer {} } } {
#--------------------------------------------------------------------
#d_sum Display a file
#d_desc The type of viewer to use is determined from the input parameters in \
order of preference: the specified viewer, the default viewer for the file \
type, the default viewer for the file type that is inferred from the file \
extension.  If the file type can not be inferred then the file will be \
displayed as a text file.
#d_arg file Name of file to display
#d_arg format (Optional) The file format - should correspond to a file \
format defined in etc/types.def
#d_arg viewer The viewer to use to display the file.

  global system

# Have we got a file name now?
  if { ![file exists $file] || ![file isfile $file] } { return 0 }

# Try to figure out which 'plugin' to use to display file
# Use browser procedure - either the name input, or browser specified 
# in the types.def file or one with name constructed  from file format

  if { $viewer != "" && [regexp $viewer [info procs $viewer] ] } {
# The viewer plugin has been input and a procedure of that name exists
    set status [$viewer $file]
  } else {
    if { $format == "ANY" || $format == "" } { 
      set format [GetFileFormat $file ] 
    }
    GetViewerList $format viewer_list viewercmd_list
    set browslength [llength $viewercmd_list]
    set status 0
   for {set n 0} {$n < $browslength} {incr n} {
	  set browser [lindex $viewercmd_list $n]
	  if { [regexp $browser [info proc $browser] ] } {
      	set status [$browser $file]
	  }
	  if { $status != 0} {
		set n $browslength
	  }
	}
  if { $status == 0} {
 # If the browser procedure does  not exist just try standard file listing!
     set status [DisplayTextFile $file -title $file]
    }
  }
  return $status

}

#------------------------------------------------------------------
proc LOGViewer { filename args } {
#------------------------------------------------------------------
#d_sum  Display a log file
#d_desc The first few lines of file are read for an indication that the file \
is html.  If it is then it is displayed in Netscape.
#d_arg filename Name of log file to display
#d_opt0 -summary
#d_opt1 Display only the summary from the log file.  Note that in the non-html \
display there is an option to toggle between full and summary display.
#
#
  if { ![OpenFile $filename f r] } {
    WarningMessage "Error reading file $filename"
    return 0
  }
  while { [regexp {^#} [set line [gets $f]]]}  { }
  for { set n 0 } { $n < 3 } { incr n } { append line [gets $f] }
  CloseFile $f

# Display HTML
  if {[regexp "CCP4 HTML" $line ]} {
    if { [lsearch -regexp $args summ ] >= 0 && [ReadFile $filename fullText] } {
# If -summary argument the extract the summary from the log file
      ExtractLogSummary $fullText summaryText
      set filename [FileJoin [GetDefaultDirPath TEMPORARY] \
		[file tail [file root $filename]]_summary.log ]
      WriteFile $filename "$summaryText" -overwrite
    }
    open_url $filename
  } else {
# Display regular ascii file 
    DisplayTextFile $filename -summary
  }
}

#------------------------------------------------------------------
proc LogGraph_graph { filename } {
#------------------------------------------------------------------
#d_sum Use loggraph to display data from a 'graph' file
#d_arg filename Name of graph  file to display

  LogGraph "$filename" -format GRAPH
}

#------------------------------------------------------------------
proc LogGraph { filename args } {
#------------------------------------------------------------------
#d_sum Display files using ccp4i loggraph
#d_arg filename Name of file to display
#d_opt0 -format format
#d_opt1 Specify format of input file: should be LOG or GRAPH (default LOG)

  global system
  global configure

  set format LOG
  set n 0; set nargs [llength $args ]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    format {
      incr n; set format [lindex $args $n]
    }
    incr n
  }

  set status [expr {1 - [ catch { eval exec $configure(RUN_LOGGRAPH) \
	-i "\"$filename\"" -f $format & } ]} ]
  if { !$status } { WarningMessage "ERROR could not start Loggraph" }
  return $status

}

#------------------------------------------------------------------------
proc PDBViewer { file } {
#------------------------------------------------------------------------
#d_sum Display PDB file as text
#d_arg file Name of file to display
  if { ![file exist $file] } { return 0 }
  return [DisplayTextFile $file -nomonitor -title $file ]
}

#------------------------------------------------------------------------
proc MAPViewer { file } {
#------------------------------------------------------------------------
#d_sum Use mapdump to read map header and display this
#d_arg filename Name of file to display

  global map_text
  if { ![file exist $file] } { return 0 }

  if {[ReadCCP4Map $file map_text ]} {
    return [DisplayTextFile $file -textinput map_text -nomonitor ]
  } else {
    return 0
  }
}

proc MASKViewer { file } {
  return [MAPViewer $file]
}

#------------------------------------------------------------------------
proc RunViewHKL { file } {
#------------------------------------------------------------------------
global configure

  PleaseWait "Starting viewhkl.."
  set status [expr {1 - [ catch { eval  exec $configure(RUN_VIEWHKL)  "$file" & } ]} ]
  PleaseWait
  if { !$status } { WarningMessage "ERROR could not start $configure(RUN_VIEWHKL)

Check that the setting for running viewhkl is
correct in the \"Configure Interface\" task
(accessed under \"System Administration\")"
  }

  return $status
}

#------------------------------------------------------------------------
proc MTZViewer { file } {
#------------------------------------------------------------------------
#d_sum Use mtzdump to read mtz header and display this
#d_arg filename Name of file to display

  global mtz_text
  if { ![file exist $file] } { return 0 }

  set mtzdmp_args "NREF 10"

  if {[ReadMTZ $file mtz_text $mtzdmp_args]} {
    return [DisplayTextFile $file -textinput mtz_text -nomonitor  \
        -title $file -button "List More Info" mtzviewer_info ]
  } else {
    return 0
  }
}

#--------------------------------------------------------------------
proc mtzviewer_info { arrayname } {
#--------------------------------------------------------------------
#d_sum pass-thru to set up new global array
  global mtz_$arrayname
  mtzviewer_info0 $arrayname mtz_$arrayname
}


#--------------------------------------------------------------------
proc mtzviewer_info0 { arrayname mtz_arrayname } {
#--------------------------------------------------------------------
#d_sum Handle option for Extra Information when displaying MTZ files
#d_desc mtz_info behaves like a usual task interface - this procedure \
creates a 'mtz_info' task window
#d_arg arrayname Name of array for fileviewer interface parameters
#d_arg mtz_arrayname Name of array for mtz_info interface parameters

  global system
  upvar #0 $arrayname array
  upvar #0 $mtz_arrayname mtz_info
  
# Look for one of the array elements to check if the mtz_info has been run 
# before and is already set up

# If not then do a lot of setting up - including setting up to run a task

  if { ![ElementExists $mtz_arrayname SF_ACTION] } {

# If not running in full ccp4i may need to set up interface
    if { [regexp viewer $system(RUN_MODE)] } {
      source [SearchPath TOP src exframe.tcl]
      source [SearchPath TOP src runjob.tcl]
      source [SearchPath TOP src database.tcl]
      DbInitialise
    }

# Parameters for running mtzdmp

    DefineVariable $mtz_arrayname SYMMETRY _logical 0
    DefineVariable $mtz_arrayname BATCH _logical 0
    DefineVariable $mtz_arrayname REFLECTIONS _logical 1
    DefineVariable $mtz_arrayname NREF _positiveint 10
    DefineVariable $mtz_arrayname RES_MIN _positivereal ""
    DefineVariable $mtz_arrayname RES_MAX _positivereal ""


#parameters for running sftools

    DefineMenu _mtz_info_action { "header information(Mtzdmp)" "selected reflections(Sftools)" } \
		{ MTZDMP LIST }
    DefineVariable $mtz_arrayname SF_ACTION _mtz_info_action MTZDMP

    DefineVariable $mtz_arrayname HKLIN _MTZ_file $array(FILENAME)
    DefineVariable $mtz_arrayname DIR_HKLIN default_dirs CURRENT
    DefineVariable $mtz_arrayname FORMAT_IN _text MTZ
    DefineVariable $mtz_arrayname LIST_COL_1 _mtz_label ""
    DefineVariable $mtz_arrayname LIST_COL_2 _mtz_label Unassigned
    DefineVariable $mtz_arrayname LIST_COL_3 _mtz_label Unassigned
    DefineVariable $mtz_arrayname LIST_COL_4 _mtz_label Unassigned
    DefineVariable $mtz_arrayname LIST_COL_5 _mtz_label Unassigned
    DefineVariable $mtz_arrayname LIST_COL_6 _mtz_label Unassigned

# Use the sftools_select tools in the file sftools_utils.tcl
# 
    source [SearchPath TOP tasks sftools_utils.tcl]
    sftools_utils_setup typedef $mtz_arrayname
    InitialiseArray [SearchPath TOP tasks sftools_select.def ] \
                 $mtz_arrayname sftools_select
# change some of the default params
    set mtz_info(APPLY_SELECT) 1
    set mtz_info(SELECT_CRITERIA,1) COL

# Ensure that the textframe and window paths are available
    DefineVariable $mtz_arrayname TEXTFRAME _text $array(TEXTFRAME)
    DefineVariable $mtz_arrayname WINDOW _text ""

# Append the file read and list command parameters to PARAM_LIST
    set mtz_info(PARAM_LIST) [concat $mtz_info(PARAM_LIST)  \
    [list TEXTFRAME WINDOW FORMAT_IN HKLIN SF_ACTION LIST_COL_1 LIST_COL_2 LIST_COL_3 LIST_COL_4 LIST_COL_5 LIST_COL_6] ]

  }

# Draw the window

  set w ".mtz_info"
  set array(MTZ_WINDOW) $w
  OpenWindow $w "MTZ Info" "MTZ Info" 
#     -help somewhere

  # Capture the window name for later
  set mtz_info(WINDOW) $w

  CreateFrame $w $mtz_arrayname

  CreateButton $w dismiss Quit "catch { CloseWindow $mtz_arrayname; ExitFileViewer }" 
  CreateButton $w action Apply&Exit \
   "mtzviewer_info_handler $arrayname $mtz_arrayname" -default

  SetProgramHelpFile mtzdump

  OpenFolder protocol

  CreateLine line \
    label "List" \
    widget SF_ACTION

  OpenSubFrame frame -toggle_display SF_ACTION open MTZDMP

  CreateLine line \
    label "List MTZ file header plus" -italic

  CreateLine line \
    help nref \
    widget REFLECTIONS \
    label "List column statistics & first" \
    widget NREF \
    label "reflections in resolution range" \
    widget RES_MIN \
    label to \
    widget RES_MAX

  CreateLine line \
    widget SYMMETRY \
    label "symmetry information"

  CreateLine line \
    widget BATCH \
    label "batch headers for multi-record MTZ" \


  CloseSubFrame

  OpenSubFrame frame -toggle_display SF_ACTION open LIST

  CreateLine line \
    label "Select reflections to list" -italic

  SetProgramHelpFile sftools

  SftoolsSelection $mtz_arrayname

  CreateLine line \
    label "List hkl, resolution, and the following columns"

  SftoolsList $mtz_arrayname

  CloseSubFrame
   
  run_update_script $mtz_arrayname
  update_main_scroll $w

}

#-------------------------------------------------------------------
proc mtzviewer_info_handler { arrayname mtz_arrayname} {
#-------------------------------------------------------------------
#d_sum Handle the 'Run' command for mtz_info - Run mtzdmp or sftools
#d_arg arrayname Name of array for fileviewer interface parameters
#d_arg mtz_arrayname Name of array for mtz_info interface parameters

  upvar #0 $arrayname array
  upvar #0 $mtz_arrayname mtz_info

  if {[regexp MTZDMP [GetValue $mtz_arrayname SF_ACTION]]} {

    set mtzdmp_args  ""
    if {$mtz_info(SYMMETRY)} { append mtzdmp_args "SYMMETRY\n" }
    if {$mtz_info(BATCH)} { append mtzdmp_args "BATCH\n" }
    if {$mtz_info(REFLECTIONS)} {
      append mtzdmp_args "NREF $mtz_info(NREF)\n"
      if { $mtz_info(RES_MIN) != "" || $mtz_info(RES_MAX) != "" } {
        if { $mtz_info(RES_MAX) == "" } { set mtz_info(RES_MAX) 0.0 }
        append mtzdmp_args "RESOLUTION $mtz_info(RES_MAX) $mtz_info(RES_MIN)\n"
      }
    } else {
      append mtzdmp_args "HEADER\n"
    }


    if {[ReadMTZ $array(FILENAME) mtz_text $mtzdmp_args]} {
      LoadTextWindow $arrayname [list [list $mtz_text {} ] ] }

    CloseWindow $mtz_arrayname

  } else {

    PleaseWait "Selecting reflections.."
    sftools_utils_run $mtz_arrayname
    run_command background mtz_info $mtz_arrayname

  }
}

#---------------------------------------------------------------------
proc mtz_info_review { mtz_arrayname job_id } {
#---------------------------------------------------------------------
#d_sum Review and display the output from the mtz_info task
#d_desc  This procedure is called automatically after the mtz_info job \
has finished when been run by 'run_command'
#d_arg mtz_arrayname Name of array for mtz_info interface parameters
#d_arg job_id Job id for the mtz_info job which has just completed

  regsub mtz_ $mtz_arrayname {} arrayname
  if {[ReadFile [GetLogFileName $job_id] logtext -split]} {
    set fline [expr {[lsearch -regexp $logtext "selected: LIST"] +2}]
    set lline [expr {[lsearch -regexp  \
                 [lrange $logtext $fline end] "give your option"] -2 + $fline}]
    foreach line [lrange $logtext $fline $lline] { append text "$line\n" }
    LoadTextWindow $mtz_arrayname [list [list $text {} ] ]
  }
  CloseWindow $mtz_arrayname
  PleaseWait
  TkBusy . 1
  return 1
}

#--------------------------------------------------------------------
proc PSViewer { file } {
#--------------------------------------------------------------------
#d_sum Display a postscript file
#d_arg file Name of PostScript file

  global system
  global configure
#We put a loop to make sure that if one of the viewer fails we at least
#try all of them before considering we failed.
  for {set n 1} {$n <= $configure(N_PS_PREVIEW)} {incr n} {
   PleaseWait "Displaying plot  with $configure(PS_PREVIEW_NAME,$n)"
   set status [expr {1 - [ catch "exec \"$configure(PS_PREVIEW_COM,$n)\" \"$file\" &" ]} ] 
   PleaseWait
   if {$status !=0} {
   set n [expr $configure(N_PS_PREVIEW) + 1]
   }
  }
  if {$status ==0} {
  WarningMessage "You do not seem to have any Post-script viewer on your system\r \
                  or the settings in \"System Administration\" -> \"Configure Interface\" are not set properly\r\r \
                  If you want you can download ghostview and ghostscript (required by ghostview) from\r\r \
                  http://www.cs.wisc.edu/~ghost/gsview/get48.htm \r \
                  http://www.cs.wisc.edu/~ghost/doc/AFPL/get853.htm"
  set status -1
  }
  ExitFileViewer
  return $status
}

#--------------------------------------------------------------------
proc XMGRViewer { file } {
#--------------------------------------------------------------------
#d_sum Display xmgr file - as output by scala
#d_arg file Input xmgr file
  foreach xmgr [list xmgrace xmgr] {
      set status [expr {1 - [ catch "exec $xmgr \"$file\" &" ]} ]
      if { $status } {
	  # Successfully launched some incarnation of XMGR
	  break
      }
  }
  if { ! $status } {
      # Failed to launch XMGR so try loggraph as a last resort
      set status [LogGraph "$file" -format XMGR]
  }
  ExitFileViewer
  return $status
}

#--------------------------------------------------------------------
proc PLOT84Viewer { file } {
#--------------------------------------------------------------------
#d_sum Use xplot84driver to display a plot84 file
#d_arg file Name of plot84 file

  set status [ expr {1 - [catch {exec xplot84driver "$file" &} report]} ]
  ExitFileViewer
  if { $status } {
    return  2
  } else {
    Report 2 "ERROR running xplot84driver program\n$report"
    return 0
  }
}

#--------------------------------------------------------------------
proc PLOT84PSViewer { file } {
#--------------------------------------------------------------------
#d_sum Convert plot84 format file to PostScript and display with PSViewer
#d_arg file Name of plot84 file

  append psfile [file rootname $file ] ".ps.tmp"
  append log [GetTmpFileName]

# pltdev command line input syntax is dependent on operating system

  set cmd "pltdev -dev ps -pen c -por -abs -i \"$file\" -o \"$psfile\"" 
  set status [Execute  $cmd "" program_status report -log $log]
  if { $status != 1 } { return 0 }
  DeleteFile $log

  return [PSViewer $psfile]
}

#---------------------------------------------------------------------
proc MRViewer { file } {
#---------------------------------------------------------------------
#d_sum Display (and edit) a mr (molecular replacement) file
#d_arg file Name of mr file

  mr_ha_viewer $file mr
}

#---------------------------------------------------------------------
proc HAViewer { file } {
#---------------------------------------------------------------------
#d_sum Display (and edit) a ha (heavy atom) file
#d_arg file Name of ha file

  mr_ha_viewer $file ha
}


#----------------------------------------------------------------------
proc mr_ha_viewer { file mode } {
#----------------------------------------------------------------------
#d_sum Pass-thru to mr_edit task which will display & edit mr and ha files
#d_arg file Name of mr/ha file
#d_arg mode File mode - ha or mr

# Get a name for the array mr_edit_$n - make sure there is not
# already a window open for this array
  set arrayname [CreateNewArray mr_edit]
  InitialiseArray [SearchPath TOP tasks mr_edit.def ] \
                    $arrayname mr_edit
  DefineVariable $arrayname SOLFIL _mr_file $file
  DefineVariable $arrayname FILE_MODE _text $mode

  source [SearchPath TOP tasks mr_edit.tcl ]
  DefineVariable $arrayname WINDOW _text .w_$arrayname
  mr_edit_task_window $arrayname

}

#---------------------------------------------------------------------
proc RunRasMol { filename } {
#---------------------------------------------------------------------
#d_sum Run RasMol to display coordinates
#d_arg filename Input PDB coordinate file

  PleaseWait "Starting RasMol.."
  set status [expr {1 - [ catch { eval exec rasmol "$filename" & } ]} ]
  PleaseWait
  if { !$status } { WarningMessage "ERROR could not start RasMol

This may be because RasMol was not
installed with CCP4 - please check
your installation." }
  return $status

}

#---------------------------------------------------------------------
proc RunPyMol { filename } {
#---------------------------------------------------------------------
#d_sum Run PyMol lto display coordinates
#d_arg filename Input PDB coordinate file
  
  PleaseWait "Starting PyMol.."
  set status [expr {1 - [ catch { eval exec pymol "$filename" & } ]} ]
  PleaseWait
  if { !$status } { WarningMessage "ERROR could not start PyMol
  
This may be because PyMol is not
installed - please check
your installation." }
  return $status
  
}   


#---------------------------------------------------------------------
proc RunMapslicer { filename } {
#---------------------------------------------------------------------
#d_sum Run the mapslicer program
#d_arg filename Input CCP4 format map file
  global system
  global configure

  PleaseWait "Starting MapSlicer.."
  set status [expr {1 - [ catch { eval exec $configure(RUN_MAPSLICER) "$filename" & } ]} ]
  PleaseWait
  if { !$status } { WarningMessage "ERROR could not start MapSlicer

This may be because the MapSlicer command
library (ccp4mapwish) was not installed with
CCP4 - please check your installation." }
  return $status

}

#---------------------------------------------------------------------
proc RunCoot { args } {
#---------------------------------------------------------------------
#d_sum Run the Coot program
#d_arg Command line arguments to be passed directly to Coot
  global system
  global configure

  PleaseWait "Starting Coot.."
  set status [expr {1 - [ catch { eval  exec $configure(RUN_COOT)  $args & } ]} ]
  PleaseWait
  if { !$status } {
      WarningMessage "ERROR could not start Coot

Check that the setting for running Coot is
correct in the \"Configure Interface\" task
(accessed under \"System Administration\")"
  }
  return $status
}

#---------------------------------------------------------------------
proc RunCCP4mg { args } {
#---------------------------------------------------------------------
#d_sum Run the CCP4mg program
#d_arg Command line arguments to be passed directly to CCP4mg
  global system
  global configure

  PleaseWait "Starting CCP4mg.."
  set status [expr {1 - [ catch { eval exec { $configure(RUN_CCP4MG) } $args & } ]} ]
  PleaseWait
  if { !$status } {
      WarningMessage "ERROR could not start CCP4mg

Check that the setting for running CCP4mg is
correct in the \"Configure Interface\" task
(accessed under \"System Administration\")"
  }
  return $status
}

#---------------------------------------------------------------------
proc RunDbviewer { args } {
#---------------------------------------------------------------------
#d_sum Launch the Dbviewer application
#d_arg Command line arguments to be passed directly to DbViewer
    global configure

    PleaseWait "Starting Dbviewer.."
    set status [expr {1 - [ catch { 
	eval exec  $configure(RUN_DBVIEWER) $args & } err ]} ]
    PleaseWait
    
  if { !$status } {
      WarningMessage "ERROR could not start Dbviewer

Check that the setting for running Dbviewer is
correct in the \"Configure Interface\" task
(accessed under \"System Administration\")"
  }
  return $status
}

#-------------------------------------------------------------------
proc DisplayTextFile { filename args } {
#-------------------------------------------------------------------
#d_sum Display a text file
#d_ref CCP4I programmers/DisplayTextFile.html
# Create a window to display a file filename
# Valid arguments -title <title>
#                 -edit
#		-height <height>
#		-width <width>
#		-help <helpfile>
#		-position
#		-monitor
#		-terminater <terminater-text>
#		-textinput <globaltextVar>
#		-buttom <button_text> <button_command>
#		-summary <summary_file>

  global configure
  global system

# Get name for new window and array

  set root [GetNewWindowName fileviewer]

  set w .w_$root
  set arrayname $root
  upvar #0 $arrayname array
  set array(summary) 0
  set array(display_summary) 0

#Set default arguments and parse command input


  set name  [file tail $filename]
  set title "CCP4I fileviewer $name"
  set icon "$name"
  set width 90
  set height 40
  set monitor -2
  set terminater ""
  set edit_mode 0
  set textinput 0
  set watch 1
  set open_file 0
  set user_button ""

  set n 0;set nargs [llength $args]
  while { $n < $nargs } {
    set comd [lindex $args $n]
    switch -- $comd \
      -title {
      incr n; set title [lindex $args $n]
    } -width {
      incr n; set width [lindex $args $n]
    } -height {
      incr n; set height [lindex $args $n]
    } -monitor {
      set monitor -1
    } -nomonitor {
      set watch 0
    } -terminater {
      incr n; set terminater [lindex $args $n]
    } -edit {
      set edit_mode 1
    } -textinput {
      set textinput 1
      incr n; set global_textVar [lindex $args $n]
      upvar #0 $global_textVar ftext
      set array(fullText) $ftext
      unset ftext
    } -button {
      incr n; set user_button [lindex $args $n]
      incr n; set user_button_command [lindex $args $n]
    } -summary {
      set array(summary) 1
    } -display_summary {
      set array(summary) 1
      set array(display_summary) 1
    }
    incr n
  }

# Read the file before drawing the window

  if { !$textinput} {
    if { ![file exists $filename] || ![file isfile $filename] } {
      WarningMessage "File does not exist $filename"
      return 0
    }
    if { [file size $filename] > $configure(VIEW_FILE_SIZE_LIMIT) } {
      if {[regexp Quit [ChooseOptionDialog "Large File" Viewer \
          "This file is too big to display all.  
It will be displayed in frames of $configure(VIEW_TEXT_LINE_LIMIT) lines." \
          [list Quit Continue] -default 1] ]} {
        return 0
      } 
      set watch 0
      
      if { ![OpenFile $filename open_file r] } { 
         WarningMessage "Error opening file $filename"
         return 0
      }
      PleaseWait "Reading file.."
      set array(fullText) ""; set n 0
      while { $n < $configure(VIEW_TEXT_LINE_LIMIT) } { incr n
        if { [gets $open_file tt] >= 0 } {
           append array(fullText) $tt\n
        } else {
          CloseFile $open_file
          set open_file 0
          set n [expr {$configure(VIEW_TEXT_LINE_LIMIT) + 1} ] }
      }
      PleaseWait
    }   else {
      if { ![ReadFile $filename array(fullText)] } { return 0 }
    }
  }

  set array(WINDOW) $w
  set array(EDIT_MODE) $edit_mode
  set array(FINDSTRING) ""
  set array(CURRENTSTRING) ""
  set array(SEE_HIT) ""
  set array(CURRENT_CASE_MODE) "Ignore case"
  set array(CASE_MODE) "Ignore case"
  set array(N_LINKS) 0
  set array(OPEN_FILE) $open_file
  set array(OPEN_FILE_FRAME) 1
  set array(FILENAME) $filename


# Open new window

  OpenGridWindow $arrayname $w $title $icon \
	-help [SearchPath HELP general fileviewer.html ]

# Create the main scrollable text display

  set main $w.main

  frame $main.right

  button $main.right.up -bitmap @[SearchPath TOP icons up_arrow.xbm] \
     -command "$main.text yview scroll -1 pages"
	
  button $main.right.down -bitmap @[SearchPath TOP icons down_arrow.xbm] \
     -command "$main.text yview scroll 1 pages"

  SetMessage $arrayname  $main.right.up "Scroll up by one page"
  SetMessage $arrayname  $main.right.down "Scroll down by one page"
 
  scrollbar $main.right.yscroll         -orient vertical \
                                -command [list $main.text yview ]


  set array(TEXTFRAME) [ text $main.text   -width $width -height $height \
                                -wrap word \
				-font $configure(FONT_FIXED) \
                                -yscrollcommand [list $main.right.yscroll set] ]

  $main.text tag configure summarytag \
                        -foreground red

   $main.text tag configure html_tag \
                        -background $configure(COLOUR_CONTRAST)

   $main.text tag configure searchhits \
                        -background $configure(COLOUR_CONTRAST)

  grid $main.text     -row 0 -column 0 -sticky nsew
  grid $main.right    -row 0 -column 1 -sticky ns
  grid columnconfigure $main 0    -weight 1
  grid columnconfigure $main 1    -weight 0
  grid rowconfigure $main 0       -weight 1

  grid columnconfigure $main.right 0    -weight 1
  grid rowconfigure $main.right 0 -weight 0
  grid rowconfigure $main.right 1 -weight 1
  grid rowconfigure $main.right 2 -weight 0
  grid $main.right.up -row 0 -column 0 
  grid $main.right.down -row 2 -column 0 
  grid $main.right.yscroll -row 1 -column 0 -sticky ns

  bind $w <KeyPress-$configure(KEY_PAGE_UP)>  \
		"$main.text yview scroll -1 pages"
  bind $w <KeyPress-$configure(KEY_PAGE_DOWN)>  \
		"$main.text yview scroll 1 pages"

  bind $w <KeyPress-$configure(KEY_DOWN)>  \
		"$main.text yview scroll 1 units"
  bind $w <KeyPress-$configure(KEY_UP)>  \
		"$main.text yview scroll -1 units"

# find utility - in the w.utils frame

  set wutils [frame $w.utils.f]
  label $wutils.l1 -text "Find string.." \
	-font $configure(FONT_REGULAR)
  entry $wutils.e1 -textvariable [subst $arrayname](FINDSTRING) \
 	-font $configure(FONT_REGULAR) \
	-width 40
  button $wutils.b1 -text "Highlight" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command "display_text_find_string hilight $arrayname"
  button $wutils.b2 -text "Next" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command "display_text_find_string next $arrayname"
  button $wutils.b3 -text "Previous" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command "display_text_find_string previous $arrayname"
  label $wutils.pos -text "No hits" \
	-font $configure(FONT_REGULAR)

  SetMessage $arrayname  $wutils.b1 "Just highlight all instances of search string"
  SetMessage $arrayname  $wutils.b2 "Go to next instance of search string"
  SetMessage $arrayname  $wutils.b3 "Go to previous instance of search string"

  menubutton  $wutils.mb1  -textvariable  [subst $arrayname](CASE_MODE) \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
          -indicatoron 1 -relief raised                                 \
          -menu $wutils.mb1.m
  menu $wutils.mb1.m -tearoff 0
  foreach item [list "Ignore case" "Respect case"] {
    $wutils.mb1.m add command -label "$item"   \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
       -command "display_text_update_case \"$item\" $arrayname $w"
  }

  SetMessage  $arrayname $wutils.mb1 \
    "Find exact match to upper/lower case of search string??"

  pack  $wutils.mb1 -side left -expand 1
  pack  $wutils.l1 -side left -expand 1
  pack  $wutils.e1 -side left -expand 1
  pack  $wutils.b1 -side left -expand 1
  pack  $wutils.b2 -side left -expand 1
  pack  $wutils.b3 -side left -expand 1
  pack  $wutils.pos -side right -expand 1

  bind $wutils.e1 <Return> "display_text_find_string hilight $arrayname"

  SetMessage $arrayname  $wutils.e1 \
    "Enter search string - hit return key to begin search"

#  The buttons frame

# Dismiss button

  button $w.buttons.dismiss -text Quit                  \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command  "display_text_close  $arrayname $w; ExitFileViewer"
  pack $w.buttons.dismiss -side right -expand 1

   SetMessage $arrayname $w.buttons.dismiss "Exit the file viewer"


# Save edit to file

  if {  $array(EDIT_MODE) } {
    button $w.buttons.save -text Save&Exit            \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command  "display_text_save $arrayname $filename
                display_text_close  $arrayname $w"
    pack $w.buttons.save -side left -expand 1
    SetMessage $arrayname $w.buttons.save "Save the edited file and exit"
  }

#Display next frame

  if { $array(OPEN_FILE) != 0 } {

     label $w.buttons.frame -text "Frame 1" \
	-font $configure(FONT_REGULAR)
     button $w.buttons.next -text "Next frame" \
	-background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "display_next_frame $arrayname $w"
     button $w.buttons.prev -text "Prev frame" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "display_next_frame $arrayname $w -1"
     pack $w.buttons.frame $w.buttons.prev $w.buttons.next -side left -expand 1

     SetMessage $arrayname $w.buttons.next \
      "Display the next $configure(VIEW_TEXT_LINE_LIMIT) lines of a long file"
  }


# Summary

  if { $array(summary) } {

    frame $w.buttons.s
    pack $w.buttons.s -side right -expand 1

    button $w.buttons.s.full -text "Show Full Text" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command  "display_text_full $w $arrayname"


     button $w.buttons.s.summary -text "Show Summary" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command  "display_text_summary $w $arrayname"

    pack $w.buttons.s.full $w.buttons.s.summary -expand 1 -side left
    pack forget $w.buttons.s.full

    SetMessage $arrayname $w.buttons.s.full \
	"Restore display of the full file"

  }


# user button 

  if { $user_button != "" } {
    button $w.buttons.user -text "$user_button"  \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command  "$user_button_command $arrayname"
    pack $w.buttons.user -side right -expand 1
  }

# Find text

  button $w.buttons.find -text Find                   \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command  "display_text_find open $w $arrayname"
  pack $w.buttons.find -side right -expand 1

  SetMessage $arrayname $w.buttons.find "Search document for text string"

# Load text into the window

  if { $array(summary) } {
    LoadTextWindow $arrayname [HilightLogSummary $array(fullText)]
  } else {
    LoadTextWindow $arrayname [list [list $array(fullText) {} ] ]
  }
  update idletasks

# for now assume the only position parameter is "end"
  if { [lsearch $args "-position" ] >= 0 } {
    $array(TEXTFRAME) yview moveto 1.0
  }

  if { ! $array(EDIT_MODE) } { $array(TEXTFRAME) configure -state disabled }

  if { $watch } { 
    MonitorFile $w $arrayname $filename $monitor -1 100 $terminater }

  return 1
}

#--------------------------------------------------------------------
proc LoadTextWindow { arrayname text_list args } {
#--------------------------------------------------------------------
#d_sum Load the text into the window set up by DisplayTextFile
#d_arg arrayname Array for file display interface
#d_arg text_list The text to insert - may be in the form of a list.
#d_opt0 -append
#d_opt1 Append new text to any test already in the window

  upvar #0 $arrayname array
  $array(TEXTFRAME) configure -state normal
  if { [lsearch -regexp $args append] < 0 } { 
         catch "$array(TEXTFRAME) delete 1.0 end" }
  foreach tt  $text_list {
    eval [concat $array(TEXTFRAME) insert end $tt ] }
  $array(TEXTFRAME) configure -state disabled
}



#--------------------------------------------------------------------
proc display_next_frame { arrayname w { increment 1 } } {
#--------------------------------------------------------------------
#d_sum handle the display of the next frame of text if displaying a very \
large file
#d_arg arrayname Array for file display interface
#d_arg w Window id for file display interface
#d_opt0 increment
#d_opt1 Number of frames to move on from the current frame (default is 1). \
Increment can be negative, to go to previous frames

  upvar #0 $arrayname array
  global configure

  PleaseWait "Reading file.."

  # Step on one frame
  # This is the quickest way to obtain the next frame
  if { $increment == 1 } {
    set current_frame [display_read_frame $arrayname]
  } elseif { $increment > 1 } {
    # Going forward several frames
    # Skip intervening frames and read the last one for display
    for { set i 0 } { $i < [expr {$increment - 1}] } { incr i } {
      display_skip_frame $arrayname
    }
    set current_frame [display_read_frame $arrayname]
  } else {
    # Increment is negative - we're going backwards
    # Do this by closing the file and then moving forward
    # from the start to the requested frame
    set requested_frame [expr {$array(OPEN_FILE_FRAME) + $increment}]
    if { $requested_frame <= 0 } {
      # Special case - we want to see the last frames in the
      # view but we don't know how many frames there are
      set first_frame $array(OPEN_FILE_FRAME)
      # Find the last frame
      set last_frame -1
      while { $last_frame < $array(OPEN_FILE_FRAME) } {
        set last_frame $array(OPEN_FILE_FRAME)
        display_skip_frame $arrayname
      }
      # Work out which frame we need
      # Nb OPEN_FILE_FRAME will be zero for the last frame
      # so we need to add one to get the correct value
      incr last_frame
      # Now reset the requested frame to the correct one
      set requested_frame [expr {$last_frame + $requested_frame}]
    }
    # Reset the file to the start
    CloseFile $array(OPEN_FILE)
    set array(OPEN_FILE) [open $array(FILENAME) r] 
    set array(OPEN_FILE_FRAME) 0
    for { set i 0 } { $i < [expr {$requested_frame - 1}] } { incr i } {
      # Read the frame but don't store it
      display_skip_frame $arrayname
    }
    # Now read the next frame
    set current_frame [display_read_frame $arrayname]
  }
  PleaseWait

  $w.buttons.frame configure -text "Frame $current_frame"

  LoadTextWindow $arrayname [list [list $array(fullText) {} ] ]

}

#---------------------------------------------------------------------
proc display_read_frame { arrayname } {
#---------------------------------------------------------------------
#d_sum Read a frame from a log file into memory so it can be displayed
#d_desc Internal procedure called by display_next_frame. Returns the \
number of the current frame.
#d_arg arrayname Array for file display interface
  upvar #0 $arrayname array
  global configure
  incr array(OPEN_FILE_FRAME)
  set current_frame $array(OPEN_FILE_FRAME)
  set array(fullText) ""; set n 0
  while { $n < $configure(VIEW_TEXT_LINE_LIMIT) } { incr n
    if {[gets $array(OPEN_FILE) tt]>= 0 }  {
      append array(fullText) $tt\n
    } else {
      CloseFile $array(OPEN_FILE)
      set array(OPEN_FILE) [open $array(FILENAME) r] 
      set array(OPEN_FILE_FRAME) 0
      set n $configure(VIEW_TEXT_LINE_LIMIT)
    }
  }
  return $current_frame
}

#---------------------------------------------------------------------
proc display_skip_frame { arrayname } {
#---------------------------------------------------------------------
#d_sum Read through a frame from a log file and discard it
#d_desc Called by display_next_frame. Returns the \
number of the current frame.
#d_arg arrayname Array for file display interface
  upvar #0 $arrayname array
  global configure
  incr array(OPEN_FILE_FRAME)
  set current_frame $array(OPEN_FILE_FRAME)
  set n 0
  while { $n < $configure(VIEW_TEXT_LINE_LIMIT) } { incr n
    if { [gets $array(OPEN_FILE) tt] < 0 }  {
      CloseFile $array(OPEN_FILE)
      set array(OPEN_FILE) [open $array(FILENAME) r] 
      set array(OPEN_FILE_FRAME) 0
      set n $configure(VIEW_TEXT_LINE_LIMIT)
    }
  }
  return $current_frame
}

#---------------------------------------------------------------------
proc display_text_update_case { field arrayname w } {
#---------------------------------------------------------------------
#d_sum Handle user changing the respect/ignore case option
#d_arg field The user selection ignore or respect
#d_arg arrayname Array for file display interface
#d_arg w Window id for file display interface

  upvar #0 $arrayname array
  set array(CASE_MODE) $field
  display_text_find_string hilight $arrayname
}


#------------------------------------------------------------------
proc display_text_close { arrayname w } {
#------------------------------------------------------------------
#d_sum Handle user clicking Close button.
#d_arg arrayname Array for file display interface
#d_arg w Window id for file display interface

  upvar #0 $arrayname array
  global system
  destroy $w
# Close any open file
  if { $array(OPEN_FILE) != 0 } { CloseFile $array(OPEN_FILE) }
# Delete the array
  unset array
  catch { upvar #0 mtz_$arrayname mtz_info; unset mtz_info }
}

#------------------------------------------------------------------
proc display_text_save { arrayname filename } {
#------------------------------------------------------------------
#d_sum Handle user opting to save contents when using 'edit' mode
#d_arg arrayname Array for file display interface
#d_arg filename Name of file to save text to

  upvar #0 $arrayname array
  set text [$array(TEXTFRAME) get 1.0 end ]
  if { [OpenFile $filename f w] == 1 } {
    puts $f $text
    CloseFile $f
    Report 2 "Notebook saved to $filename"
  } else {
    Report 3 "Can not open file $filename"
    Report 3 "Edit has not been saved"
  }
}

#------------------------------------------------------------------
proc display_text_find { mode w arrayname } {
#------------------------------------------------------------------
#d_sum Handle user hitting Find or 'Close Find' button
#d_arg mode open or close 
#d_arg w The Tk id for the window
#d_arg arrayname Name of data array

  upvar #0 $arrayname array

# Toggle open/closed the Find utility and toggle the Find/Close Find button

  if { $mode == "open" } {
    pack $w.utils.f
    $w.buttons.find configure -text "Close Find"
    $w.buttons.find configure -command  "display_text_find close $w $arrayname"
    SetMessage $arrayname $w.buttons.find "Close the find utility"
  } else {
    pack forget $w.utils.f
    $w.buttons.find configure -text Find
    $w.buttons.find configure -command  "display_text_find open $w $arrayname"
    set array(CURRENTSTRING) ""
    set searchhits [ $array(TEXTFRAME) tag ranges searchhits]
    if { [llength $searchhits] > 0 } {
       eval "$array(TEXTFRAME) tag remove searchhits $searchhits"
    }
    SetMessage $arrayname $w.buttons.find "Search document for text string"

 }
  update idletasks
}

#------------------------------------------------------------------
proc display_text_find_string { mode arrayname args } {
#------------------------------------------------------------------
#d_sum Find and highlight given string in the text
#d_arg mode Mode of action: \
next= Just move to next instance of the search string \
previous= Just move to previous instance of the search string \
hilight= Just highlight the instances of the search string \
update= Search the text for the search string, highlight hits
#d_arg arrayname Array for file display interface
#d_opt0 -position position
#d_opt1 In update mode do search from position (used when file is still \
been read in)

  upvar #0 $arrayname array

  set w $array(WINDOW)

#  puts "display_text_find_string $mode FINDSTRING $array(FINDSTRING)"

  set array(FINDSTRING) [string trim $array(FINDSTRING)]

  if { $array(FINDSTRING) !=  $array(CURRENTSTRING) ||
       $array(CASE_MODE) != $array(CURRENT_CASE_MODE) ||
	$mode == "update" }   { 
    if { $mode != "update" } { 
      if { $array(FINDSTRING) == "" } { return }
      set array(SEE_HIT) {} 
      set searchstring $array(FINDSTRING)
      set array(CURRENT_CASE_MODE) $array(CASE_MODE)
    } else {
      set searchstring $array(CURRENTSTRING)
      set array(CASE_MODE) $array(CURRENT_CASE_MODE)
    }
    set lsearchstring [string length $searchstring] 
    set position "1.0"
    set keep_searching 1
    set hitlist {}

    set nargs [llength $args]; set n 0
    while { $n < $nargs } {
      set comd [lindex $args $n]
      if { $comd == "-position" } {
        incr n; set position [lindex $args $n]
      }
      incr n
    }

# Set up search command to be eval'd repeatedly

    set cmd " set hit \[$array(TEXTFRAME) search "
    if { $array(CASE_MODE) == "Ignore case" } { append cmd "-nocase " }
    append cmd "  -- \"\$searchstring\"  \$position \]"

# loop until found all hits in text

    while { $keep_searching } {
      eval "$cmd"
      if { $hit == "" || $hit == [lindex $hitlist 0] } {
        set keep_searching 0
      } else {
        set position [ $array(TEXTFRAME) index "$hit + $lsearchstring chars" ]
        lappend hitlist $hit $position
      }
    }
# Remove any existing searchhits
    set searchhits [ $array(TEXTFRAME) tag ranges searchhits] 
    if { [llength $searchhits] > 0 } {
       eval "$array(TEXTFRAME) tag remove searchhits $searchhits"
    }
    if { [llength $hitlist ] > 0 } {
      eval "$array(TEXTFRAME) tag add  searchhits $hitlist"
    }
  } else {
    set hitlist  [ $array(TEXTFRAME) tag ranges searchhits]
  }

  if { $mode == "hilight" || \
	[llength $hitlist] == 0 || \
	        $array(SEE_HIT) == "" } { 
    $w.utils.f.pos configure -text \
      "[expr {[llength $hitlist] / 2} ] hits"
  } elseif { $mode == "update" && $array(SEE_HIT) != "" } {
    $w.utils.f.pos configure -text \
     "Hit [expr ($array(SEE_HIT) / 2) + 1 ] of [expr [llength $hitlist] /2 ]"
  }

  if { $mode == "hilight" || $mode == "update" || \
	[llength $hitlist] == 0 } { return }

  if { $array(SEE_HIT) == "" } {
    if { $mode == "previous" } {
      set array(SEE_HIT)  [expr {[llength $hitlist] - 2} ]
    } else {
      set array(SEE_HIT) 0
    }
  } else {
    if { $mode == "previous" } {  
      incr  array(SEE_HIT) -2 
      if { $array(SEE_HIT) < 0 } {  
        if { [regexp Yes [ChooseOptionDialog "Top of File" Top \
          "Reached top of file, continue from the bottom?" \
          [list Yes No] -default 1] ] } {
             set array(SEE_HIT)  [expr {[llength $hitlist] - 2} ]
        } else {
          set array(SEE_HIT) 0
        }
      }
    } elseif { $mode == "next" } { 
      incr array(SEE_HIT) 2
      if { $array(SEE_HIT) >= [llength $hitlist] } { 
        if {[regexp Yes [ChooseOptionDialog "Bottom of File" Bottom \
          "Reached end of file, continue from the top?" \
      	  [list Yes No] -default 1] ]} {
          set array(SEE_HIT) 0 
        } else {
          set array(SEE_HIT)  [expr {[llength $hitlist] - 2} ]
        }
      }
    }
  } 
  $array(TEXTFRAME) see [ lindex $hitlist $array(SEE_HIT) ]

  $w.utils.f.pos configure -text \
     "Hit [expr ($array(SEE_HIT) / 2) + 1 ] of [expr [llength $hitlist] /2 ]"
  set array(CURRENTSTRING) $array(FINDSTRING)
}

#------------------------------------------------------------------
proc display_links { arrayname w } {
#------------------------------------------------------------------
#d_sum  Dispaly links in log file
#d_desc This is not used and may not be fully functional
  upvar #0 $arrayname array
  global configure

# Search the text from log file for the CCP4I command markup 
# hide the command string - colour the link text blue and add
# binding to run the command

  set continue 1
  set position 1.0

#  puts "display_links N_LINKS $array(N_LINKS)"
  $array(TEXTFRAME) configure -state normal

  while { $continue } {
    set hit [$array(TEXTFRAME) search -- "<CCP4I" $position ]
    if { $hit == "" ||  $hit <= $position } {
      set continue 0
    } else {
      set close [ $array(TEXTFRAME) search -- ">" \
                     [ $array(TEXTFRAME) index "$hit + 6 chars" ] ]
      set end [$array(TEXTFRAME) search -- "</CCP4I>" $hit ]
      set line [$array(TEXTFRAME) get $hit $close]
      set cmd [ string range $line [expr {[string first "\"" $line] + 1} ] \
				   [expr {[string last "\"" $line] - 1}  ] ]
      incr array(N_LINKS)
      $array(TEXTFRAME) tag configure link_$array(N_LINKS) \
                        -foreground $configure(COLOUR_LINK)
      $array(TEXTFRAME) tag bind link_$array(N_LINKS) \
		<Button-1> "$cmd"
      $array(TEXTFRAME) tag add  link_$array(N_LINKS) \
		[ $array(TEXTFRAME) index "$close + 1 chars" ]  $end
      $array(TEXTFRAME) delete $end [$array(TEXTFRAME) index "$end + 8 chars"]
      $array(TEXTFRAME) delete $hit [ $array(TEXTFRAME) index "$close + 1 chars" ]
      set position $hit
    }
  }
  if { !$array(EDIT_MODE) } { $array(TEXTFRAME) configure -state disabled }
}


#----------------------------------------------------------------------------
proc MonitorFile { w arrayname file mtime size delay terminator } {
#----------------------------------------------------------------------------
#d_sum Read and display a file that is still being written
#d_desc This procedure works by re-calling itself after a small time delay. \
If the file is not increasing in size then the time delay is increased. \
The procedure searches the file for some specified text string which \
indicates the file is complete and then MonitorFile will stop re-calling \
itself.
#d_arg w Tk id of the text window
#d_arg arrayname Array for file display interface
#d_arg file Name of file to display
#d_arg mtime The time at which file was last modified (a negative value \
signifies the first call to MonitorFile
#d_arg size The size of the file when last modified
#d_arg delay The delay before re-calling MonitorFile
#d_arg terminator A text string whose presence in the file would indicate \
the end of the file

  upvar #0 $arrayname array
#  puts "MonitorFile $mtime $size"

# Watch a file that is still growing
# This procedure recalls itself after a given period of time
 
# If the array or window do not exist assume the window has been
# closed and stop monitoring the file

  if { ![ElementExists $arrayname TEXTFRAME] ||
       ![winfo exists $array(TEXTFRAME)] } { return }

# Make sure the file still exists
  if { ![file exists $file] } { return }

  set position  [$array(TEXTFRAME) index end]
    if { $mtime < 0 }  {
      #
      # Run a process every five seconds
      #
      set size1 [file size $file]
      if { ![ReadFile $file array(fullText)] } { return 0 }
      set top [expr {int([$array(TEXTFRAME) index "@0,0 linestart"]) - 1}]

      if { $array(display_summary) } {
        ExtractLogSummary $array(fullText) array(summaryText)
        LoadTextWindow $arrayname [list [list $array(summaryText) {} ] ]
      } else {
        LoadTextWindow $arrayname [HilightLogSummary $array(fullText)]
      }
         
      $array(TEXTFRAME) yview scroll $top units

      if { [$array(TEXTFRAME) index end] > $position } {
        display_text_find_string update $arrayname -position $position
        display_links $arrayname $w
      }
      if { $mtime == -2 } {  return }
      if { [string last "$terminator" $array(fullText) ] < 0 } {
        set mtime1 [file mtime $file]
        after 20000 [list MonitorFile $w $arrayname $file $mtime1 $size1 5000 $terminator ]
      }
    } else {
      #
      # Check a file for new data
      #
      set mtime1 [file mtime $file]
      set size1 [file size $file]
#      puts "mtime1 $mtime1 size1 $size1"
      if {$mtime != $mtime1 || $size != $size1} {
          set delay 100
          if {$size1 < $size || $size < 0} {
              catch "$array(TEXTFRAME) delete 1.0 end"
              set size 0
          }
          set fd [open $file]
          seek $fd $size start
          set newText [read $fd]
          close $fd
          append array(fullText) $newText
          if { $array(display_summary)  } {
            ExtractLogSummary $array(fullText) array(summaryText)
            LoadTextWindow $arrayname [list [list $array(summaryText) {} ] ]
          } else {
            LoadTextWindow $arrayname [HilightLogSummary $newText ] -append
          }
      } else {
          if {[incr delay 100] > 2000} { set delay 2000 }
          set newText ""
      }
      if { [string last "$terminator" "$newText" ] < 0 } {
        after $delay [list \
          MonitorFile $w $arrayname $file $mtime1 $size1 $delay $terminator]
      }
    }
    display_text_find_string update $arrayname -position $position
    display_links $arrayname $w
}

#---------------------------------------------------------------------
proc display_text_summary { w arrayname } {
#---------------------------------------------------------------------
#d_sum Handle the 'Show Summary' option
#d_arg w Display text interface window id
#d_arg arrayname Name of display text interface array

  upvar #0 $arrayname array

  if { ![ElementExists $arrayname summaryText ] } {
    if { ![ExtractLogSummary $array(fullText) array(summaryText)]  } { 
      WarningMessage "Could not extract summary"
      return 0 }
  }

# If have successfully got summary text then display it
  set array(display_summary) 1
  LoadTextWindow $arrayname [list [list $array(summaryText) {} ] ]

# update the display of hilighting

  display_text_find_string update $arrayname

# Change the command buttons
  pack forget $w.buttons.s.summary
  pack $w.buttons.s.full -side left
}

#---------------------------------------------------------------------
proc display_text_full { w arrayname } {
#---------------------------------------------------------------------
#d_sum Handle the 'Show Full Text' option
#d_arg w Display text interface window id
#d_arg arrayname Name of display text interface array

  upvar #0 $arrayname array

  set array(display_summary) 0
  LoadTextWindow $arrayname [HilightLogSummary $array(fullText) ]

# update the display of hilighting
  display_text_find_string update $arrayname

# Change the command button
  pack forget $w.buttons.s.full
  pack $w.buttons.s.summary -side right
}

#--------------------------------------------------------------------
proc ExtractLogSummary { fullText summaryTextVar } {
#--------------------------------------------------------------------
#d_sum Extract the text tagged as 'summary' from a log file
#d_arg fullText Input the full text
#d_arg summaryTextVar Output the text summary

  upvar $summaryTextVar summaryText

  set summaryText ""
  set ftext [split $fullText \n]
  set incl 0
  set n 0

  foreach line $ftext {
    if { [regexp <!--SUMMARY $line] } { 
      set incl [regexp SUMMARY_BEGIN $line]
      incr n
    } elseif { $incl > 0 } {
      append summaryText $line \n
#      append summaryText $n $line \n
    }
  }
  return 1
}

#--------------------------------------------------------------------
proc HilightLogSummary { fullText } {
#--------------------------------------------------------------------
#d_sum Highlight the sections of log file which are tagged as 'summary'
#d_arg fullText Input the full text

  set textout ""
  set notrailingnl 0
  set ftext [split $fullText \n]
  # Check for trailing newline
  if { ![regexp "(.*)\n\$" $fullText] } {
    set notrailingnl 1
  }
  set n 0
  set tag {}
  set tt {}

  foreach line $ftext {
    if { [regexp <!--SUMMARY $line] } {
      if { $n > 0 } { lappend textout [list $tt $tag ] }
      if { [regexp SUMMARY_BEGIN $line] } { set tag summarytag } else { set tag {} }
      set n 0; set tt {}
    } else {
      incr n
      append tt $line \n
    }
  }
  # Strip off the trailing newline
  if { $notrailingnl } {
    regexp "(.*)\n\$" $tt j0 tt j1
  }

  if { $n > 0 } { lappend textout [list $tt $tag ] }

  return $textout
}



#-----------------------------------------------------------------
proc GetViewerList { format viewerVar viewercmdVar } {
#-----------------------------------------------------------------
#d_sum Extract the list of file formats, viewers and full viewer commands from the typedef array
#d_desc The definitions have been read from the etc/types.def file into the \
typedef array.  This procedure reformats the information as lists which are \
easier to handle.
#d_arg format Output list of supported file formats
#d_arg viewer Output list of viewer names (corresponding to format list) which \
is the name of the viewer as seen by the user
#d_arg viewercmd Output list of the commands required to run viewers \
(corresponding to format and viewer lists)

  upvar $viewerVar viewer
  upvar $viewercmdVar viewercmd
  global typedef

  set viewer "List file"
  set viewercmd TextViewer
  set fn [lsearch $typedef(file) format]
  set fv [lsearch $typedef(file) viewer]
  set fc [lsearch $typedef(file) viewercmd ]
  foreach type $typedef(file_types) {
    if {[regexp $format [lindex $typedef($type) $fn] ]} {
      if { [llength [lindex $typedef($type) $fv] ] > 0 } {
        set viewer ""; set viewercmd ""
        foreach item [lindex $typedef($type) $fv] { lappend viewer $item }
        foreach item [lindex $typedef($type) $fc] { lappend viewercmd $item }
        return 1
      } else {
        return 0
      }
    }
  }
  return 0
}
