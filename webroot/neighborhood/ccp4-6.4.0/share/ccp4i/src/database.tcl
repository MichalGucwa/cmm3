#
#     Copyright (C) 1999-2007  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - database.tcl
#
#
#
# Database handling utilities
#
# Liz Potterton Jan97
# Peter Briggs  Dec02, Oct07
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Database Utilities (src/database.tcl)
#d_intro_title Database Utilities
#
#d_intro This file contains the various commands for interacting with \
the underlying job database within CCP4i. The actual database commands \
are in the projectdb.tcl file. These functions are concerned with the \
provision of tools and interfaces for viewing and modifying the \
database contents.

SetSystemVar VIEW_JOB_JOBID 0

# Acquire the plugins procedures
source [SearchPath TOP src plugins.tcl]

# Acquire the directories handling code
source [SearchPath TOP src projectdirs.tcl]

# Acquire the core job database handling code
source [SearchPath TOP src projectdb.tcl]

# Acquire the qtrview handling code
source [SearchPath TOP src qtrview.tcl]

#-----------------------------------------------------------------------
proc DbInterrogateLock { project db statusVar userVar timeVar } {
#-----------------------------------------------------------------------
#d_sum Obtain the status of the lock for the given project database
#d_desc Returns the status in statusVar - "unlocked" or "locked"
#d_arg project Alias for project
#d_arg db Directory for corresponding database
#d_arg statusVar Name of variable to return status in
#d_arg userVar Name of variable to return user in
#d_arg timeVar Name of variable to return time in

  upvar $statusVar status
  upvar $userVar user
  upvar $timeVar time

  if { [DbLockStatus $project user time] == 0 } {
      set status "locked"
  } else {
      set status "unlocked"
  }
}

#d_index_title APIs to Access the Database
#d_intro_title APIs to Access the Database
#
#d_intro These are CCP4i-specific commands to interact with the database. \
They are built on top of the core database commands.

#----------------------------------------------------------------------
proc DbRegisterJob { arrayname taskname { status "STARTING" } } {
#----------------------------------------------------------------------
#d_sum Register a new job with the project database.
#d_desc This procedure will automatically extract data from the array \
associated with a task and load it into the database.  The data in the \
task array must have the appropriate parameter names:
#d_desc TITLE  A title for the job
#d_desc INPUT_FILES A list of the *parameter* names in the task array for \
input files (NB not the file names themselves)
#d_desc OUTPUT_FILES A list of the *parameter* names in the task array for \
input files (NB not the file names themselves)
#d_desc The procedure returns the job id.
#d_arg arrayname The name of the task array
#d_arg taskname  The name of the task
#d_arg status    Optional status - default is 'STARTING'

  upvar #0 $arrayname array

  if { [set job_id [DbNewRecord $taskname $status]] == 0 } {
    # We have failed to create a new record
    return 0
  }

  if { [ElementExists $arrayname TITLE] } {
    set title "$array(TITLE)"
  } else {
    set title ""
  }
  set output_files ""
  set input_files ""
  set output_files_dir ""
  set input_files_dir ""
  set input_files_status ""
  set output_files_status ""

  if { [ElementExists $arrayname INPUT_FILES ] } {
    foreach file $array(INPUT_FILES) {
      if { $array($file) != "" } {
        lappend input_files $array($file)
        if { [StringSame $array(DIR_$file) [GetSystemVar PATHNAME_LABEL]] } {
          lappend input_files_dir FULL_PATH
        } else {
          lappend input_files_dir $array(DIR_$file)
        }
        lappend input_files_status 0
      }
    }
  }
  if { [ElementExists $arrayname OUTPUT_FILES ] } {
    foreach file $array(OUTPUT_FILES) {
      if { $array($file) != "" } {
        lappend output_files $array($file)
        if { [StringSame $array(DIR_$file) [GetSystemVar PATHNAME_LABEL] ] } {
          lappend output_files_dir FULL_PATH
        } else {
          lappend output_files_dir $array(DIR_$file)
        }
        lappend output_files_status 0
      }
    }
  }

  DbSetJobData $job_id STATUS $status \
    TASKNAME $taskname TITLE $title INPUT_FILES $input_files \
    INPUT_FILES_DIR $input_files_dir OUTPUT_FILES $output_files \
    OUTPUT_FILES_DIR $output_files_dir

  return $job_id
}

#-----------------------------------------------------------------------
proc DbUnregisterJob { job_id } {
#-----------------------------------------------------------------------
#d_sum Unregister job at some stage in job startup 
#d_desc This should only be used if job_id is the last job in the project. \
This procedure is usually called if the user has opted to abort running a job.
#d_arg job_id  Job id
  if { [DbGetNJOBS] < 1 } { return }
  DbSetJobData $job_id STATUS closed
  DbDeleteJob $job_id
  return
}

#--------------------------------------------------------------------
proc DbGetJobFileRoot { job_id { dir {} } } {
#--------------------------------------------------------------------
#d_sum Return the root name for files such as script and log files
#d_desc There are standard file names for log file of the form jobid_taskname
#d_desc This does not return the file extension and only includes the full \
directory path if the dir parameter is set.  This will generally be used \
when you want to create the file.
#d_arg job_id 	Job id
#d_arg dir 	Optional project/directory alias or the word 'PROJECT' \
which will use the current project directory.

  append filename  $job_id _ [DbGetJobData $job_id TASKNAME]

  if { $dir == "" } {
    return $filename
  } elseif { $dir == "PROJECT"  } {
    return [FileJoin [GetDefaultDirPath] $filename ]
  } else {
    return [FileJoin [GetDefaultDirPath $dir] $filename ]
  }

}

#---------------------------------------------------------------------------
proc GetLogFileName { job_id } {
#---------------------------------------------------------------------------
#d_sum Return the full file name for the log file
#d_desc If the file does not exists then return null. This will generally \
be used when you want to read the file.
#d_arg job_id Job id

  if { ![DbItemExists $job_id LOGFILE] } { return {} }
  set logfile [DbGetJobData $job_id LOGFILE]

  if { [llength [file split $logfile ]] > 1 } {
    return $logfile
  } else {
    if { [file exists [FileJoin [GetDefaultDirPath] $logfile]] } {
      return [FileJoin [GetDefaultDirPath] $logfile]
    } elseif { [file exists [FileJoin [GetDefaultDirPath TEMPORARY] $logfile]] } {
      return [FileJoin [GetDefaultDirPath TEMPORARY] $logfile]
    } else {
      return ""
    }
  }
}

#--------------------------------------------------------------------
proc GetLogFileFormat { job_id logfileVar formatVar } {
#--------------------------------------------------------------------
#d_sum Return the full file name for the log file and its format
#d_desc If the file does not exist or can not be read then the format \
is returned as 'NOFILE'.  The format will otherwise be 'TEXT' or 'HTML'.
#d_desc This procedure reads the first few lines of the file to \
determine its format. 
#d_arg job_id	Job id
#d_arg logfileVar	Returned full path name for log file
#d_arg formatVar	Returned file format
  upvar $formatVar format
  upvar $logfileVar logfile

  set format TEXT
  set logfile [GetLogFileName $job_id ]
  if { ![file exists $logfile] } { set format NOFILE; return }

  if { ![OpenFile $logfile f r] } {  set format NOFILE; return }
  for { set i 1 } { $i < 20 } { incr i } {
    if { [regexp "CCP4 HTML" [set line [gets $f]]] } { lappend format HTML }
  }
  CloseFile $f

  if { ![file exists $logfile.html] } { return }
  if { ![OpenFile $logfile.html f r] } { return }
  lappend format ANNOTATED
  CloseFile $f
}

#--------------------------------------------------------------------
proc DbGetJobFiles { job_id mode filelistVar args } {
#--------------------------------------------------------------------
#d_sum Return a list of either INPUT/OUTPUT files 
#d_desc By default only files are returned in the lists. If the -all \
argument is specified then any directories are also included in the \
list that is returned.
#d_arg job_id Job id
#d_arg mode either 'INPUT' or 'OUTPUT'
#d_arg filelistVar Returned list of files with full path names
#d_opt0 -all
#d_opt1 Include all files and directories

  upvar $filelistVar filelist

  set incl_dirs 0
  foreach arg $args {
    switch -- $arg {
	"-all" {
	    set incl_dirs 1
	}
    }
  }

  set filelist {}
  set flist [DbGetJobData $job_id [subst $mode]_FILES ]
  set dlist [DbGetJobData $job_id [subst $mode]_FILES_DIR]

  if { [llength $flist] <= 0 } { return 0 }

  set i -1; foreach file $flist { incr i
    if { $file != "" || $incl_dirs } {
      if { [llength [file split $file]] > 1 } {
        lappend filelist $file
      } else {
	if { $file == "" } {
            lappend filelist  [lindex $dlist $i]
        } else {
	    lappend filelist  [GetFullFileName $file [lindex $dlist $i]]
        }
      }
    }
  }

  return [llength $filelist]
}

#d_index_title Database GUI
#d_intro_title Database GUI
#d_intro  These are procedures to draw the job list from the database in the ccp4i main window.

#------------------------------------------------------------------------
proc ssdb_setup {} {
#------------------------------------------------------------------------
#d_sum Create the window containing the tools for searching and sorting
#d_desc The sort/search window consist in choice between a search and a sort \
 and between simple or advanced one. Depending on the user's choice the parameters \
 that can be tuned are different and can help the user to refine a search step by step \
 or to do many different search and sorts. The results of the sorting and searching \
 are displayed in this window, not in the main task window.

  global configure
  global searching
  global archive

  set archive(REFINE_EXIST) 0
  set ssdb_w ".search"

  if { [winfo exists $ssdb_w] } { return 0 }

  # defining basic general variable and menus for both search and sort use
  DefineVariable searching IFSS	_logical 	0
  DefineVariable searching SEARCH_TYPE	_logical 	0
  DefineVariable searching SORT_TYPE	_logical 	0
  DefineVariable searching IFSORT	_logical 	"-increasing"
  DefineVariable searching IFADSORT_1	_logical 	"-increasing"
  DefineVariable searching IFADSORT_2	_logical 	"-increasing"
  DefineVariable searching IFTITLE _logical 0
  DefineVariable searching IFSTATUS _logical 0
  DefineVariable searching IFPROG _logical 0
  DefineVariable searching IFDATE _logical 0
  DefineVariable searching IFINPUT _logical 0
  DefineVariable searching IFOUTPUT _logical 0
  DefineVariable searching IFADONE _logical 0
  DefineVariable searching IFADTWO _logical 0

  DefineVariable searching TITLE _text ""
  DefineVariable searching PROG _text ""

  DefineVariable searching AD_DAY _positiveint	""
  DefineVariable searching AD_MONTH _positiveint	""
  DefineVariable searching AD_YEAR _positiveint	""
  DefineVariable searching AD_TI_TYPE _logical 0
  DefineVariable searching IN_FILE _text ""
  DefineVariable searching IN_DIR _default_dirs ""
  DefineVariable searching OUT_FILE _text ""
  DefineVariable searching OUT_DIR _default_dirs ""

  DefineMenu _sort_mode [list "Job number" "Job Title" "Status" "Taskname"] \
                        [ list JOB_ID TITLE STATUS TASKNAME ]
  DefineMenu _advanced_sort_mode [list "Number of files used for input" \
									"Number of output files"] \
                        [ list INPUT_FILES OUTPUT_FILES]
  DefineMenu _job_statuses [list "RUNNING" "START" "BATCH" "FAILED" "FINISHED" "KILLED"] \
                           [list RUNNING START BATCH FAILED FINISHED KILLED]

  DefineVariable searching SORT_MODE _sort_mode JOB_ID
  DefineVariable searching AD_SORT_MODE_1 _sort_mode TASKNAME
  DefineVariable searching AD_SORT_MODE_2 _sort_mode TITLE

  DefineVariable searching STATUS _job_statuses FINISHED

  set searching(CURRENT_SORT) 1
  set searching(CURRENT_SEARCH) {}
  OpenWindow $ssdb_w "Searching and Sorting database" "Search/Sort" \
	         -message searching
  wm protocol $ssdb_w WM_DELETE_WINDOW "CloseWindow searching"

  # create the first lines with the basis for the choices
  CreateFrame $ssdb_w searching -noscroll
  
  OpenFolder protocol
  
  CreateLineTemplate threeitems { 0.1 0.335 0.45 }
  
  OpenSubFrame one 

  CreateLine linesearc \
    message "Select what you want to do" \
    help todo \
    label "Action to perform on the database " \
    message "Sorting the database " \
    radiobutton IFSS 1  "sort" \
    message " .. or searching through the database" \
    radiobutton IFSS 0  "search " \
    format template threeitems

  CloseSubFrame

  OpenSubFrame two

  CreateLine linesearc \
    message "what accuracy do you need?" \
    help search \
    label "accuracy:" \
    message "Simple operations" \
    radiobutton SEARCH_TYPE 0  "simple " \
    message " .. or advanced operations" \
    radiobutton SEARCH_TYPE 1  "advanced" \
    toggle_display IFSS hide 1 \
    format template threeitems
	
  CreateLine linesearc \
    message "what accuracy do you need?" \
    help search \
    label "accuracy:" \
    message "Simple operations" \
    radiobutton SORT_TYPE 0  "simple " \
    message " .. or advanced operations" \
    radiobutton SORT_TYPE 1  "advanced" \
    toggle_display IFSS hide 0

  CloseSubFrame

  # main subframe containing all the frames and lines concerning the search parameters
  
  OpenSubFrame criterias -toggle_display IFSS open 0 hide 

  # Creating the lines for the simple search
  CreateLineTemplate twoitems { 0.1 0.335  }
  CreateLine linesearch1 \
    message "" \
    help criter \
    message "Set on to enables to search on job statuses" \
    widget IFSTATUS -toggleon\
    label "Search for status:" \
    message "Set the status you want" \
    widget STATUS \
    format template twoitems
	
  CreateLine linesearch2 \
    message "" \
    help criter \
    message "Set on to search on job's title content be careful about case" \
    widget IFTITLE -toggleon\
    label "Search for title containing:" \
    message "you can type words that appears in the title" \
    widget TITLE \
    format template twoitems

  CreateLine linesearch3 \
    message "" \
    help criter \
    message "Set on to search on job's progam name" \
    widget IFPROG -toggleon\
    label "Search for task:" \
    message "Type the title of the program be careful about the case" \
    widget PROG \
    format template twoitems
	
  # Subframe containing the criteria for an advanced search
  OpenSubFrame advanced -toggle_display SEARCH_TYPE open 1

  CreateLine linesearch4 \
    message "Set on to Combine with a search on time" \
    widget IFDATE -toggleon\
    label "Search jobs whose date is " \
    radiobutton AD_TI_TYPE -1 " before " \
    radiobutton AD_TI_TYPE 1 " after " \
    radiobutton AD_TI_TYPE 0 " or on " \
    message "day number" \
    widget AD_DAY \
    label "(dd) " \
    message "month number" \
    widget AD_MONTH \
    label "(mm) " \
    message "year number" \
    widget AD_YEAR \
    label "(yyyy)"

  CreateLine linesearch5 \
    message "set on to search for job with a specific input file" \
    widget IFINPUT\
    label "Search for the job using the following input file" 
	
  CreateInputFileLine linesearch5f \
      "Indicate the file" \
      "" \
      IN_FILE \
      IN_DIR \
	  -command "set searching(IFINPUT) 1"

  CreateLine linesearch6 \
    message "set on to search for job with a specific output file" \
    widget IFOUTPUT -toggleon\
    label "Search for the job using the following output file" 
	
  CreateInputFileLine linesearch6f \
      "Indicate the file" \
      "" \
      OUT_FILE \
      OUT_DIR 	\
	  -command "set searching(IFOUTPUT) 1"

  CloseSubFrame

  CloseSubFrame

  # Create the lines concerning the simple and advanced sorting
  CreateLineTemplate sixitems { 0.0 0.2 0.37 0.4 0.55 0.62 }

  OpenSubFrame critsort -toggle_display IFSS open 1 hide

  CreateLine linesort \
    message "How do you want to sort the database?" \
    help sort \
    label "Sort by: " \
    widget SORT_MODE \
    label "in " \
    radiobutton IFSORT "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFSORT "-decreasing"  "Decreasing Order" \
    format template sixitems \
    toggle_display SORT_MODE open JOB_ID
	
  CreateLine linesortbis \
    message "How do you want to sort the database?" \
    help sort \
    label "Sort by: " \
    widget SORT_MODE \
    label "in " \
    radiobutton IFSORT "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFSORT "-decreasing"  "Decreasing Alphabetical Order" \
    format template sixitems \
    toggle_display SORT_MODE hide JOB_ID
	
  OpenSubFrame advancedSort toggle_display SORT_TYPE open 1

  CreateLine linesort2 \
    message "" \
    help criter \
    message "Set on to sort the items that would be equals" \
    widget IFADONE -toggleon\
    label "and then sort by:" \
    widget AD_SORT_MODE_1 \
    label "in " \
    radiobutton IFADSORT_1 "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFADSORT_1 "-decreasing"  "Decreasing Order" \
    format template sixitems \
    toggle_display AD_SORT_MODE_1 open JOB_ID

  CreateLine linesort2bis \
    message "How do you want to sort the database?" \
    help sort \
    widget IFADONE -toggleon\
    label "and then sort by:" \
    widget AD_SORT_MODE_1 \
    label "in " \
    radiobutton IFADSORT_1 "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFADSORT_1 "-decreasing"  "Decreasing Alphabetical Order" \
    format template sixitems \
    toggle_display AD_SORT_MODE_1 hide JOB_ID

  OpenSubFrame advsortbis toggle_display IFADONE open 1

  CreateLine linesort3 \
    message "" \
    help criter \
    message "Set on to sort the items that would be equals" \
    widget IFADTWO -toggleon\
    label "and then sort by:" \
    widget AD_SORT_MODE_2 \
    label "in " \
    radiobutton IFADSORT_2 "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFADSORT_2 "-decreasing"  "Decreasing Order" \
    format template sixitems \
    toggle_display AD_SORT_MODE_2 open JOB_ID
	
  CreateLine linesort2bis \
    message "How do you want to sort the database?" \
    help sort \
    widget IFADTWO -toggleon\
    label "and then sort by:" \
    widget AD_SORT_MODE_2 \
    label "in " \
    radiobutton IFADSORT_2 "-increasing"  "Increasing " \
    label " or " \
    radiobutton IFADSORT_2 "-decreasing"  "Decreasing Alphabetical Order" \
    format template sixitems \
    toggle_display AD_SORT_MODE_2 hide JOB_ID
	
  CloseSubFrame

  CloseSubFrame

  CloseSubFrame

  CreateLine space label "             "

  # create a scrolled listbox to display the results 
  scrollbar $ssdb_w.s -command "$ssdb_w.res yview"
  scrollbar $ssdb_w.sx -command "$ssdb_w.res xview" -orient horizontal
  listbox $ssdb_w.res -background "white" -height 10 -width 90 -yscroll "$ssdb_w.s set" \
          -xscroll "$ssdb_w.sx set" -font $configure(FONT_FIXED) \
          -selectbackground $configure(COLOUR_CONTRAST) \
          -selectmode extended
  bind $ssdb_w.res <ButtonRelease-1> "db_handle_selection select %W -ssdb"
  bind . <KeyRelease-F2> "db_handle_selection clear %W -ssdb"

  $ssdb_w.res insert 0 "No results to display"

  set optionlist [list [list "View Files from Job" \
                             "View Log File" \
                             "View Log Graphs" \
                             "View Command Scripts" ] \
                       {Delete/Archive Files..} \
                       {Kill Job} \
                       {ReRun Job..} \
                       [list "Edit Job Data" \
                             "Read/Edit Notebook"  \
                             "Edit Job Data" \
                             "Enter Data for External Job" ]	]
								
  set commandlist [ list [ list list_log graph_log list_script ] \
                         archive \
                         kill_job \
                         rerun \
                         [ list edit_notebook edit_job report_job ] ]
			
  set messagelist [list \
    "Display the log file from a selected job" \
    "Delete and/or archive the files generated by selected job(s) & optionally remove from database" \
    "Kill the job" \
    "Rerun the selected job" \
    "Edit information or notebook entry associated with selected job(s)" ]

  set helpfile [SearchPath HELP general database.html]

  set helplist [list \
    review_log_file \
    delete/archive_files \
    rerun_job \
    kill_job \
    notebook  ]
	
  set activelist [list 1 1 1 1 1]

  db_draw_utilities $optionlist $commandlist $messagelist \
                    $activelist $helpfile $helplist -ssdb

  pack $ssdb_w.sx -side bottom -fill x
  pack $ssdb_w.s -side right -fill y 
  pack $ssdb_w.res -side bottom -fill both
		   
  # adding the functionnal buttons
  CreateButton $ssdb_w dismiss Close "CloseWindow searching"
  CreateButton $ssdb_w action Execute \
	  "ssdb_handler 0 $ssdb_w searching" -default
  update_main_scroll $ssdb_w
  return
}

#------------------------------------------------------------------------
proc ssdb_handler { mode ssdb_w arrayname } {
#------------------------------------------------------------------------
#d_sum Handle action when user clicks "Execute" or "Refine" buttons
#d_desc This procedure deals with the execution or refinement of a search \
or sort request when the user clicks on the action button in the window.
#d_arg mode 0 (execute a new search) or 1 (refine existing results),2 resetting
#d_arg ssdb_w The path of the toplevel searching window
#d_arg arrayname The name of the array at global level holding the searching \
parameters
    
  upvar #0 $arrayname searching

  # Check that the window exists
  if { ![winfo exists $ssdb_w] } { return }

  # Resetting if mode is 2
  if {$mode==2} {
    $ssdb_w.res delete 0 end
    $ssdb_w.res insert 0 "No results to display"
    set searching(PROG) ""
    set searching(TITLE) ""
    set searching(AD_DAY) ""
    set searching(AD_MONTH) ""
    set searching(AD_YEAR) ""
    set searching(IN_FILE) ""
    set searching(OUT_FILE) ""
    set searching(CURRENT_SEARCH) {}
    set searching(CURRENT_SORT) 0
  } else {
	# Are we searching or sorting?
    set line [$ssdb_w.res get 0 0]
    if {$mode==1 && [lsearch $line "No results to display"]!=-1} {
      WarningMessage "You are trying to refine on an empty set of results"
      return -1
    }
	# Telling the user that we're doing something
    PleaseWait "Searching/sorting"
	if { [GetValue $arrayname IFSS] == 0} {
	  # Searching
	  if {$mode==0} {
        set searching(CURRENT_SEARCH) {}
        set searching(CURRENT_SORT) 0
	  }
      db_search_handler $mode $ssdb_w $arrayname
    } else {
      # Sorting
      set searching(CURRENT_SORT) 1
      db_sort_handler $mode $ssdb_w $arrayname
    } 
  }
  # Finished - remove the PleaseWait window
  PleaseWait
  return
}

#------------------------------------------------------------------------
proc update_ssdb_list { } {
#------------------------------------------------------------------------
#d_sum update the list from jobs inside the search/sort tool
#d_dest The way this procedure works just apply the search or sort like a \
 refine search/sort with the current parameters. This will change nothing \
 to the results and will refill the result listbox with values correct for the \
 database.

  global archive
  upvar #0 "searching" search
  set ssdb_w ".search"
  if {$archive(REFINE_EXIST)==1} {
    set current $search(CURRENT_SEARCH)
    if {[llength $current]>1} {
      db_search_handler 2 $ssdb_w searching
	  if {$search(CURRENT_SORT)==1} {  
        db_sort_handler 1 $ssdb_w searching
	  } 
    } elseif {[llength $current]==1} {
      db_search_handler 0 $ssdb_w searching
      if {$search(CURRENT_SORT)==1} {  
        db_sort_handler 1 $ssdb_w searching
      }
    } else {
      if {$search(CURRENT_SORT)==1} {  
        db_sort_handler 0 $ssdb_w searching
      }
    }
    update idletasks
  }
  return
}
#------------------------------------------------------------------------
proc db_sort_handler {want_refine win_path arrayname} {
#------------------------------------------------------------------------
#d_sum Handle a simple or advanced sorting triggered by the search/sort tool
#d_desc This method deal both with the simple and advanced sorting, and enables \
 to sort on the result of previous searches through its parameters.
#d_arg want_refine is a boolean value used to see if it is a new sorting or if the \
 user want to sort on previous results. Set to 1 for refining, 0 otherwise.
#d_arg win_path is the pathname of the search/sort windows used to feed the result

  upvar #0 $arrayname searching
  global archive

  if {$want_refine} {
    set job_list $archive(SSDB)
  } else {
    set job_list [DbSelectJobs STATUS .*]
  }
  
  # storing the criteria(s) the user want to use for the sorting
  set sort_crit [list [GetValue searching SORT_MODE]]

  if {[GetValue searching IFADONE]} {
    lappend sort_crit [GetValue searching AD_SORT_MODE_1]
    if {[GetValue searching IFADTWO]} {
      lappend sort_crit [GetValue searching AD_SORT_MODE_2]
      }
  }

  set ssdb_results {}
  set val_list {}
  set i 0

  DbGetCurrentProject project
  $win_path.res delete 0 end

  # fetching the values of the (first) criteria selected by the user
  if {![ regexp JOB_ID [lindex $sort_crit 0] ]} {
    foreach item $job_list {
      set job_ids($i) $item 
      set job_vals($i) [DbGetJobData $job_ids($i) [lindex $sort_crit 0]]
      set first_value($i) $job_vals($i)
      set job_vals($i) "$job_vals($i)_$item"
      lappend val_list $job_vals($i) 
      incr i
    }
  } else {
    set index 0
    set inc_dec [GetValue searching IFSORT]
    if {$inc_dec=="-decreasing"} {
      set job_list [lsort -integer [subst $inc_dec] $job_list]
    }
    set archive(SSDB) $job_list
    foreach item $job_list {
      set line [DbJobDescription $project $item [list JOB_ID DATE STATUS \
                TASKNAME TITLE] [list 10 10 10 15 50]]
      $win_path.res insert end "$line"
      incr index
    }
	
    if {!$archive(REFINE_EXIST)} {
      CreateButton $win_path refine "Apply to results" "ssdb_handler 1 $win_path searching"
      CreateButton $win_path reset "Reset" "ssdb_handler 2 $win_path searching"
      set archive(REFINE_EXIST) 1
    }
    return
  }

  # sorting on the list on the chosen criteria
  set inc_dec [GetValue searching IFSORT]
  set val_list [lsort -dictionary [subst $inc_dec] $val_list]
  set i 0

  # reordering the array to make the job numbers be in the new order
  ssdb_reordering_array $val_list "job_vals" "job_ids" "first_value" [array size job_ids] 0

  # dealing with an advanced sort
  if {[GetValue searching SORT_TYPE]} {
    set n [expr {[GetValue searching IFADTWO] +1}]
    # we have to do the process once or twice depending on the user's choice this is
    # the use of this loop
    for {set j 1} {$j<=$n} {incr j} {
      set previous $first_value(0)
      set i 0
      # going through the main array containing the values to identify sublist whose
      # values are identical
      while {$i < [array size job_ids]} {
        set prev_i $i
        set val_list {}
        while {$i<[array size job_ids] && $previous==$first_value($i)} {
          set job_vals($i) [DbGetJobData $job_ids($i) [lindex $sort_crit $j]]
          set previous $first_value($i)
          set first_value($i) $job_vals($i)
          set job_vals($i) "$job_vals($i)_$job_ids($i)"
          lappend val_list $job_vals($i)
          incr i
        }
        #once a sublist is identified, we order this sublist according to the user's will
        if {$i<[array size job_ids]} {
		  set previous $first_value($i)
        }
        set inc_dec [GetValue searching IFADSORT_$j]
        if {[ regexp JOB_ID [lindex $sort_crit $i]]} {
          set val_list [lsort -integer [subst $inc_dec] $val_list]
        } else {
          set val_list [lsort -dictionary [subst $inc_dec] $val_list]
        }
        # and reorder the part of the main array containing the id of jobs of this sublist
        # to match the sorting criteria.
        ssdb_reordering_array $val_list "job_vals" "job_ids" "first_value" $i $prev_i
      }
    }
  }

  #saving the current results for later use
  for {set kk 0} {$kk<[array size job_ids]} {incr kk} {
    lappend ssdb_results $job_ids($kk)
    }
  set archive(SSDB) $ssdb_results
	
  # feeding the results in the listbox
  set index 0
  foreach item $ssdb_results {
    set line [DbJobDescription $project $item [list JOB_ID DATE STATUS \
              TASKNAME TITLE] [list 10 10 10 15 50]]
    $win_path.res insert end "$line"
    incr index
  }

  # create the refine button if it was not already available
  if {!$archive(REFINE_EXIST)} {
    CreateButton $win_path refine "Apply to results" "ssdb_handler 1 $win_path searching"
    CreateButton $win_path reset "Reset" "ssdb_handler 2 $win_path searching"
    set archive(REFINE_EXIST) 1
  }
  return
}
#------------------------------------------------------------------------
proc ssdb_reordering_array { value_list unordered_val unorder_ids backup_val bound start} {
#------------------------------------------------------------------------
#d_sum Reorder the entries of an array.
#d_desc This procedure take the value from a list to compare them to the entries \
 of an array, and reorder all the arrays in the parameters to match the order of the \
 list
#d_arg value_list is a list containing the ordered values.
#d_arg unordered_val is the name of the array containing the currently unordered values
#d_arg unordered_ids is the name of the array containing the currently unordered job ids
#d_arg backup_val is the name of an array containing values for advanced sort
#d_arg bound is the upperbound for the index in the array to match the values of the list
#d_arg start is the index in the array where the search need to start to find matching values

  upvar $unordered_val unordered_values
  upvar $unorder_ids unordered_ids
  upvar $backup_val backup_values

  foreach elem $value_list {
    if { $elem != $unordered_values($start) } {
      set temp_id $unordered_ids($start)
      set temp_val $unordered_values($start)
      set temp_first $backup_values($start)
      set k $start
      while {$unordered_values($k)!= $elem && $k < $bound} {
        incr k
      }
      set unordered_values($start) $unordered_values($k)
      set unordered_ids($start) $unordered_ids($k)
      set backup_values($start) $backup_values($k)
      set unordered_values($k) $temp_val
      set unordered_ids($k) $temp_id
      set backup_values($k) $temp_first
      }
      incr start
  }
  return
}
#------------------------------------------------------------------------
proc db_search_handler { want_refine win_path arrayname} {
#------------------------------------------------------------------------
#d_sum Handles a simple or advanced search triggered by the sort/search tool
#d_desc This procedure deal with both simple and advanced search, fetching the \
 jobs corresponding to the different values and retaining only those which match all \
 criteria. It deals with an unfructuous search by displaying a message
#d_arg want_refine is a boolean value used to see if it is a new search or if the \
 user want to sort on previous results. Set to 1 for refining, 0 otherwise.
#d_arg win_path is the pathname of the search/sort windows used to feed the result

  upvar #0 $arrayname searching
  global archive
  set result {}
  # checking the different options enabled in the interface and retrieve the 
  # corresponding jobs from the database.
  set max_len 0
  set max_ind 0
  set z 0 
  if {$want_refine!=2} {
    if {[GetValue searching IFTITLE]} {
      if {[GetValue searching TITLE]==""} {
        WarningMessage "Please give title words to search on"
        return
      }
      lappend searching(CURRENT_SEARCH) [list  TITLE [GetValue searching TITLE]]
      set result_list($z) [DbSelectJobs TITLE [GetValue searching TITLE]]
      incr z 
    }
	
    if {[GetValue searching IFPROG]} {
      if {[GetValue searching PROG]==""} {
        WarningMessage "Please give a taskname to search on"
        return
      }
      lappend searching(CURRENT_SEARCH) [list  TASKNAME [GetValue searching PROG]]
      set result_list($z) [DbSelectJobs TASKNAME [GetValue searching PROG]]
      incr z
    }
	
    if {[GetValue searching IFSTATUS]} {
      lappend searching(CURRENT_SEARCH) [list  STATUS [GetValue searching STATUS]]
      set result_list($z) [DbSelectJobs STATUS [GetValue searching STATUS]]
      incr z
    }
 	
    if {[GetValue searching SEARCH_TYPE] != 0} {	
      if {[GetValue searching IFDATE]} {
        set day [GetValue searching AD_DAY]
        set monthes [list January February March April May June July August \
                          September October November December]
        set month_31 [list 1 3 5 7 8 10 12]
        set month_30 [list 4 6 9 11]
        if {$day== ""} {
          set day [clock format [clock seconds] -format "%d"]
        } 
        set month [GetValue searching AD_MONTH]
        if {$month== ""} {
          set month [clock format [clock seconds] -format "%m"]
        }
        set year [GetValue searching AD_YEAR]
        if {$year== ""} {
          set year [clock format [clock seconds] -format "%Y"]
        }	
	    #Error handling in the format of date
	    #checking content of entries	
        if {![string is integer $day] || ![string is integer $month] || \
                                         ![string is integer $year]} {
          WarningMessage "Day, month and Year should be numbers!" 
          return
        }
        #checking monthes
        if {$month < 1 || $month >12} {
          WarningMessage "Incorrect Month number!"
          return
        }
        #checking days in relation to monthes and year
        if {$day <= 31 && $day > 0} {
          if {[lsearch $month_30 $month]>=0 && $day==31} {
	    set month_name [lindex $monthes [expr {$month -1}]]
            WarningMessage "There are not $day days in $month_name!"
            return
          } elseif {$month==2} {
            if {$day >=30} {
              WarningMessage "There are not $day days in Feburary"
              return
            } elseif {[expr {$year/4.0}]!= [expr {$year/4}] && $day==29} {
              WarningMessage "Year $year is not a leap year"
              return
            }
          }
        } else {
          WarningMessage "Incorrect Day number!"
          return
        }
        #checking year
        if {$year > [clock format [clock seconds] -format "%Y"]} {
          WarningMessage "We are not in $year yet!"
          return
        }
        if {$year < 1979} {
          WarningMessage "The CCP4 program suite didn't exist in $year!"
          return
        }
        set op [GetValue searching AD_TI_TYPE]
        if {$op==0} {
          set const 86399
        } else {
          set const 0
        }
        set check_time 1
        if {$op!=-1} {
          set timestamp [clock scan "23:59:59 $year-$month-$day"]
        } else {
          set timestamp [clock scan "0:00:00 $year-$month-$day"]
        }
        set result_list($z) [DbSelectJobs DATE .*]
        lappend searching(CURRENT_SEARCH) [list  DATE $const $timestamp]
        set max_ind $z
        incr z
      } else {
        set check_time 0
      }
	
      if {[GetValue searching IFINPUT] || [GetValue searching IN_FILE]!=""} {
        if {[GetValue searching IN_FILE]==""} {
          WarningMessage "Please give a input file name to search on"
          return
        }
        if {![GetValue searching IFINPUT]} {
          set searching(IFINPUT) 1
        }
        set result_list($z) [DbSelectJobs INPUT_FILES [GetValue searching IN_FILE]]
        incr z
        set result_list($z) [DbSelectJobs INPUT_FILES_DIR [GetValue searching IN_DIR]]
        incr z
        lappend searching(CURRENT_SEARCH) [list  INPUT_FILES [GetValue searching IN_FILE] \
                                           INPUT_FILES_DIR [GetValue searching IN_DIR]]
      }
	
      if {[GetValue searching IFOUTPUT] || [GetValue searching OUT_FILE]!=""} {
        if {[GetValue searching OUT_FILE]==""} {
          WarningMessage "Please give a output file name to search on"
          return
        }
        if {![GetValue searching IFOUTPUT]} {
          set searching(IFOUTPUT) 1
        }
        set result_list($z) [DbSelectJobs OUTPUT_FILES [GetValue searching OUT_FILE]]
        incr z
        set result_list($z) [DbSelectJobs OUTPUT_FILES_DIR [GetValue searching OUT_DIR]]
        incr z
        lappend searching(CURRENT_SEARCH) [list  OUTPUT_FILES [GetValue searching IN_FILE] \
                                           OUTPUT_FILES_DIR [GetValue searching IN_DIR]]
      }
    } else {
      set check_time 0
    } 	
  
    if {$z==0} {
      WarningMessage "Please select at least one criteria\r"
      return
    }
  } else {
    set current $searching(CURRENT_SEARCH)
    set check_time 0
    foreach criter $current {
      if {[llength $criter]==2} {
	    set result_list($z) [DbSelectJobs [lindex $criter 0] [lindex $criter 1]]
        incr z
      } else {
        if {[lindex $criter 0] == "DATE"} {
          set const [lindex $criter 1]
          set timestamp [lindex $criter 2]
          set result_list($z) [DbSelectJobs DATE .*]
          set max_ind $z
          incr z
		  set check_time 1
	    } else {
          set result_list($z) [DbSelectJobs [lindex $criter 0] [lindex $criter 1]]
          incr z
          set result_list($z) [DbSelectJobs [lindex $criter 2] [lindex $criter 3]]
          incr z
	    }
	  }
    }
  }
  #Checking list lenght to know which one is the longest
  set zz 0
  while {$zz < [array size result_list] && !$check_time} {
    if {$max_len < [llength $result_list($zz)]} {
      set max_len [llength $result_list($zz)]
      set max_ind $zz
    }
    incr zz
  }

  $win_path.res delete 0 end

  # This put the longest list in front because its lenght makes it more likely to make
  # short loops. Indeed it is less likely to find its item in all other lists.
  if {$max_ind!=0} {
    set temp_list $result_list(0)
    set result_list(0) $result_list($max_ind)
    set result_list($max_ind) $temp_list 
  }

  #Taking all the elements from the first list to check if they are in other list
  #I take advantage of the fact that DbSelectJobs returns ordered list to make
  # loops stop earlier in case of non-match. It then change to the next element 
  # of the first list as soon as it see a non match in a list.
  foreach item $result_list(0) {
    if {$check_time} {
      set jobtime [DbGetJobData $item DATE]
      if {$const} {
	if {$jobtime <= $timestamp && $jobtime >= [expr {$timestamp-$const}]} {
          set matched 1
        } else {
          set matched 0
        }
      } else {
        if {$op==1} {
	  set test [expr {$jobtime > $timestamp}]
        } else {
	  set test [expr {$jobtime < $timestamp}]
        }
        if {$test} {
          set matched 1
        } else {
          set matched 0
        }
      }
    } else {
      set matched 1
    }
    set count 1
    while {$count<[array size result_list] && $count==$matched} {
      if {[lsearch $result_list($count) $item]!=-1} {
        incr matched
      }
      incr count
    }
    if {$matched == $count} {
      lappend result $item
    }
  }

  # If we are refining the search we compare the previous results to ones included
  # in the new search to retrieve only the matching ones
  if {$want_refine==1} {
    set tempor_result $result
    set result {}
    foreach titem $tempor_result {
      if {[lsearch $archive(SSDB) $titem]!=-1} {lappend result $titem}
    }
  }

  # Fill the result listbox with the results if available
  if {[llength $result]>0} {
    DbGetCurrentProject project
    set index 0
    foreach item $result {
      set line [DbJobDescription $project $item [list JOB_ID DATE STATUS \
                TASKNAME TITLE] [list 10 10 10 15 50]]
      $win_path.res insert end "$line"
      incr index
    }
  } else {
    $win_path.res insert end "There are no tasks matching your criteria"
  }
  
  #save the current result for possible refinement
  set archive(SSDB) $result

  #create the button to refine search and sorting if it was not already available
  if {!$archive(REFINE_EXIST)} {
    CreateButton $win_path refine "Apply to results" "ssdb_handler 1 $win_path searching"
    CreateButton $win_path reset "Reset" "ssdb_handler 2 $win_path searching"
    set archive(REFINE_EXIST) 1
  }
  return
}

#------------------------------------------------------------------------
proc ScheduleDbUpdateList { } {
#------------------------------------------------------------------------
#d_sum Schedule an update of the job list.
#d_desc When this command is invoked initially it sets up an invocation \
of DbUpdateList (which updates the list of jobs in the main window) to \
happen a second later. Any additional calls in this time are essentially \
ignored. Once the list display has been updated, new calls will set up \
the next update to happen.
#d_desc This mechanism is intended to prevent a sequence of distracting \
updates to the job display occurring each time a set of update requests \
are recieved in rapid succession.

    if { [GetSystemVar DB_UPDATE_SCHEDULED] == "" } {
	# Initialise now
	SetSystemVar DB_UPDATE_SCHEDULED 0
    }
    if { ! [GetSystemVar DB_UPDATE_SCHEDULED] } {
	# Set up an update to happen 1000ms later
	SetSystemVar DB_UPDATE_SCHEDULED 1
	after 1000 {
	    # Reset the flag
	    SetSystemVar DB_UPDATE_SCHEDULED 0
	    # Do the display update
	    DbUpdateList
	}
    }
}

#------------------------------------------------------------------------
proc DbUpdateList { args } {
#------------------------------------------------------------------------
#d_sum Update the list of jobs displayed and save data to file.
#d_desc This procedure defines the parameters and format to be listed \
and calls db_update_list which actually draws the list.
#d_desc Note that the -nosave option no longer does anything, as the \
save operations are handled internally by the database functions.
#d_opt0 -nosave 
#d_opt1 Does nothing but is retained for backwards compatibility.

  global archive

  DbGetCurrentProject project
  set db_display [list JOB_ID DATE STATUS TASKNAME TITLE ]
  set db_display_format [list 5 10 10 15 80 ]
  set no_jobs_message "Project Database Job List - currently no jobs"

  if {[db_update_list $project $db_display \
           $db_display_format  $no_jobs_message ]} {
    update idletasks
	if {[winfo exists ".search"]} {update_ssdb_list}
  }
}

#------------------------------------------------------------------------
proc db_update_list { project db_display db_display_format \
			  no_jobs_message } {
#------------------------------------------------------------------------
#d_sum Draw any generic list of parameters from database to the job list window.
#d_arg project The alias for the project to access
#d_arg db_display A list of the database parameters to be displayed
#d_arg db_display_format A list of the field widths (as integers) to \
use for displaying the items in the db_display list.  
#d_arg no_jobs_message The message to display if there are currently \
no jobs in the database.

  global archive
  set frame [GetSystemVar DBLISTFRAME]

  if { ![winfo exists $frame] } {
    return 0
  }

  set job_list [lsort -decreasing -integer [DbSelectJobs STATUS .*]]
  
  if { [$frame index end] >= 0 } {
    set position [lindex [$frame yview] 0]
    $frame delete 0 end
  } else {
    set position 0.0
  }
  
  set archive(DISPLAY_LIST) ""

  if { [llength $job_list] <= 0 } {
     $frame insert end "$no_jobs_message"
     return 1
  } else {
     FeedListbox $frame $job_list $db_display $db_display_format
  }
  $frame yview moveto $position
  
  return 1
}

#------------------------------------------------------------------------
proc db_handle_selection { mode w args } {
#------------------------------------------------------------------------
#d_sum Handler for user picking a job from list
#d_desc save current selection in archive(CURRENT_SELECTION)
#d_arg mode	Usually 'select' for if user selected job or 'clear' if user clicked F2
#d_arg w The widget identifier for the listbox which displays the job list
#d_opt0 -ssdb
#d_opt1 Indicates that the selection is coming from the search/sort tool

  global archive

  # Process the arguments
  set ssdb 0
  if { [lsearch -exact $args "-ssdb"] > -1 && $archive(REFINE_EXIST)==1} {
    set ssdb 1
  }
 
  if { $mode == "select" } {
    set selection [$w curselection]
    foreach item $selection {
      if { $ssdb } {set id [lindex $archive(SSDB) $item]
	  } else { set id [lindex $archive(DISPLAY_LIST) $item] }
      if { [lsearch $archive(CURRENT_SELECTION) $id ] < 0 } {
        set archive(LAST_SELECTION) $id
      }
    }
    set archive(CURRENT_SELECTION) ""
    foreach list_id $selection {
       if {$ssdb} { 
	   		lappend archive(CURRENT_SELECTION) [lindex $archive(SSDB) $list_id]
	  	} else { 
		lappend archive(CURRENT_SELECTION) [lindex $archive(DISPLAY_LIST) $list_id]
		}
    }
    if { [lsearch $archive(CURRENT_SELECTION) $archive(LAST_SELECTION)] < 0 } {
      set archive(LAST_SELECTION) [max $archive(CURRENT_SELECTION)]
    }
  } else {
    # F2 click - required effect is to clear all selections except the last
    set w [GetSystemVar DBLISTFRAME]
    $w selection clear 0 end
    set archive(CURRENT_SELECTION) ""
    set archive(LAST_SELECTION) ""
  }

}

#------------------------------------------------------------------------
proc db_update_selection { } {
#------------------------------------------------------------------------
#d_sum Update the internal array elements for the current job selection
#d_desc This procedure updates the CURRENT_SELECTION element in the \
archive global array by checking that each item in the selection actually \
exists.

  global archive

  # Make sure that everything on the current selection list is valid
  set sel_list $archive(CURRENT_SELECTION)
  set archive(CURRENT_SELECTION) ""
  foreach sel  $sel_list {
    if { [DbItemExists $sel STATUS] } {
      lappend archive(CURRENT_SELECTION) $sel
    }
  }
  if { [DbItemExists $archive(LAST_SELECTION) STATUS] } {
    set archive(LAST_SELECTION) ""
  }
}

#------------------------------------------------------------------------
proc db_context_menu { w x y ysel } {
#------------------------------------------------------------------------
#d_sum Handler for user right-clicking on job window
#d_desc This procedure generates a "context menu" presenting appropriate \
actions available to the user to manipulate the currently selected set \
of jobs in the database job list.
#d_desc The available operations depend upon the number of selected jobs.
#d_arg w The name of the window that the menu was invoked from
#d_arg x The screen X position of the mouseclick
#d_arg y The screen Y position of the mouseclick
#d_arg ysel The y position of the mouseclick within the window

    global archive
    global configure
    global preferences

    set m "$w.dbcontext"
    if { [winfo exists $m] } {
	destroy $m
    }
    menu $m -tearoff 0

    # Look for the nearest element in the joblist display
    set sel [$w nearest $ysel]
    # If not selected already then clear the current selection
    if { ![$w selection includes $sel] } {
       $w selection clear 0 end
    }
    # Ensure that the data about the current selection
    # is valid
    db_update_selection

    # Add the latest job to the selection
    $w selection set $sel
    db_handle_selection select $w
    
    # How many jobs are selected? (This affects which options
    # should be offered through the context menu)
    set nselect [llength $archive(CURRENT_SELECTION)]

    if { $nselect == 1 } { 
	set job_id $archive(LAST_SELECTION)
        if { $job_id == 0 || $job_id == "" } { set nselect 0 }
    }

    if { $nselect == 1 } { 
	# Get the id of the selected job plus some additional
	# information
	set taskname [DbGetJobData $job_id TASKNAME]
	set status [DbGetJobData $job_id STATUS]
	$m add command -label "For job $job_id.." \
	    -font $configure(FONT_ITALIC)
    } elseif { $nselect > 0 } {
	$m add command -label "For all selected jobs.." \
	    -font $configure(FONT_ITALIC)
    }
    $m add separator

    # Build the menu

    # Delete/archive
    # Needs one or more jobs to have been selected
    if { $nselect > 0 } {
	$m add command -label "Delete/Archive Files.." \
	    -font $configure(FONT_REGULAR) \
	    -command "db_command_handler delete"
    }
    # View files, rerun, kill, edit... need exactly one selected job
    if { $nselect == 1 } {
	# Populate the menu

	# Kill running job
	if { [regexp {RUNNING|REMOTE} $status] } {
	    $m add command -label "Kill Job" \
		-font $configure(FONT_REGULAR) \
		-command "db_command_handler kill_job"
	}
	# Rerun job
	if { ![regexp REPORTED $status] } {
	    $m add command -label "Rerun $taskname job" \
		-font $configure(FONT_REGULAR) \
		-command "db_command_handler rerun"
	}
	# Plugins
	DbGetJobFiles $job_id OUTPUT filelist
        # special cases when some input files should be presented too
        if { $taskname == "refmac5" } {
           DbGetJobFiles $job_id INPUT filelist1
           foreach filen $filelist1 {
             switch -regexp $filen {
                ".*\.refmac\.cif$" {
                    # Data harvesting file, ignored
                }
                ".*\.cif\$" {
                    # CIF file - assume it's a dictionary
                    lappend filelist $filen
                }
             }
          }
        }
	if { [llength [set plugins [GetPlugins $taskname $filelist]]] > 0 } {
	    #$m add separator
	    foreach plugin $plugins {
		$m add command -label "[lindex $plugin 0]" \
		    -font $configure(FONT_REGULAR) \
		    -command "[lindex $plugin 1]"
	    }
	}
	$m add separator
	# View files
        if { [qtrview::isEnabled] } {
           $m add command -label "View Job Results (new style)" -font $configure(FONT_REGULAR) -command "qtrview::launchReportViewer $job_id"
        }
	GetLogFileFormat $job_id logfile format
	if { [lsearch $format "TEXT"] > -1 } {
	    $m add command -label "View Log Graphs" \
		-font $configure(FONT_REGULAR) \
		-command "db_command_handler graph_log"	    
	}
        # Generate the annotated log file on the fly?
	if { ! $preferences(DYNAMIC_ANNOTATION) } {
	    # No dynamic generation - give the option to view
	    # an existing file
	    if { [lsearch $format "ANNOTATED"] > -1 } {
		$m add command -label "View Annotated Log in Web Browser" \
		    -font $configure(FONT_REGULAR) \
		    -command "db_command_handler browse_annotated"
	    }
	} else {
	    # Dynamic generation, provided that a logfile exists
	    if { [lsearch $format "TEXT"] > -1 } {
		if { [lsearch $format "ANNOTATED"] > -1 } {
		    # Annotated file already exists
		    set logfile [GetLogFileName $job_id]
		    set annotatedlog "$logfile.html"
		    $m add command -label "View Annotated Log in Web Browser" \
			-font $configure(FONT_REGULAR) \
			-command "DeleteFile $annotatedlog ; CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
		} else {
		    # No pre-existing file
		    $m add command -label "View Annotated Log in Web Browser" \
			-font $configure(FONT_REGULAR) \
			-command "CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
		}
	    }
	}
	if { [lsearch $format "TEXT"] > -1 } {
	    $m add command -label "View Log File (old style)" \
		-font $configure(FONT_REGULAR) \
		-command "db_command_handler list_log"
	}

	# Make a cascading menu for input and output files
	set fm $m.files
	if { [winfo exists $fm] } {
	    $fm delete 0 [$fm index end]
	} else {
	    set fm [menu $fm -tearoff 0]
	}
	$m add cascade -label "Input and output files .." \
	    -font $configure(FONT_ITALIC) -menu $fm
	for { set i 0 } { $i < 2 } { incr i } {
	    $fm add command -label "[lindex {Input Output} $i] files .."  \
		-font $configure(FONT_ITALIC)
	    set nfiles [DbGetJobFiles $job_id [lindex {INPUT OUTPUT} $i] filelist]
	    foreach file $filelist {
		if { [file exists $file] } {
		    $fm add command -label "[file tail $file]" \
			-command "FileViewer \"$file\" -noquery"
		}
	    }
	}
	$m add separator
	# Edit Data
	$m add command -label "Edit Job Data" \
	    -font $configure(FONT_REGULAR) \
	    -command "db_command_handler edit_job"
	# Link to notebook
	if { [db_job_has_notebook $job_id] } {
	    set message "View/edit notebook entry"
	} else {
	    set message "Add notebook entry"
	}
	# Access to subjobs
	if { [DbJobHasSubjobs $job_id] } {
	    $m add command -label "View subjobs for this job" \
		-font $configure(FONT_REGULAR) \
		-command "RunDbviewer [GetCurrentProject] $job_id"
	}
	$m add command -label "$message" \
	    -font $configure(FONT_REGULAR) \
	    -command  "db_edit_notebook $job_id"
    }

    # Additional configuration options
    if { $nselect != 0 } {
	$m add separator
    }
    # (Re)generate annotated logfile
    if { $nselect == 1 } {
	if { ! $preferences(DYNAMIC_ANNOTATION) } {
	    set logfile [GetLogFileName $job_id]
	    set annotatedlog "$logfile.html"
	    if { ![file exists $annotatedlog] } {
		# No annotated logfile - offer to make one
		$m add command -label "Generate annotated logfile" \
		    -font $configure(FONT_ITALIC) \
		    -command "CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
	    } else {
		# Offer to regenerate the existing annotated logfile
		$m add command -label "Regenerate annotated logfile" \
		    -font $configure(FONT_REGULAR) \
		    -command "DeleteFile $annotatedlog ; CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
	    }
	}
    }
    # Access the interface for customising colours
    $m add command -label "Set custom colours for job list" \
        -font $configure(FONT_REGULAR) \
        -command "RunTask colour"
    # Allow users to access the help if required
    $m add command -label "About the job list.." \
	-font $configure(FONT_REGULAR) \
	-command "KeywordHelp [SearchPath HELP general database.html] job_list"

    # Popup the context menu
    tk_popup $m $x $y
}

#------------------------------------------------------------------------
proc db_handle_doubleclick { } {
#------------------------------------------------------------------------
#d_sum Handler for user double-clicking on job window
#d_desc This procedure attempts to display the logfile for the job, \
if it has one.
    global archive
    set job_id $archive(LAST_SELECTION)
    if { $job_id != "" } {
         if { [qtrview::isEnabled] } {
	   db_command_handler qtrview_log
         } else {
	   db_command_handler list_log
         }
    }
}

#------------------------------------------------------------------------
proc db_handle_shiftdoubleclick { } {
#------------------------------------------------------------------------
#d_sum Handler for user double-clicking on job window while pressing shift
#d_desc This procedure attempts to rerun the job that has been double \
clicked by the user in the job database list, provided that the job has \
a status other than REPORTED.
    global archive
    set job_id $archive(LAST_SELECTION)
    if { $job_id != "" } {
	if { ![regexp REPORTED [DbGetJobData $job_id STATUS]] } {
	    db_rerun $job_id
	}
    }
}

#------------------------------------------------------------------------
proc db_command_handler { command } {
#------------------------------------------------------------------------
#d_sum  Handle a user pick of the utility menu
#d_desc All of the utility menu items invoke this procedure when picked. \
This procedure checks that the appropriate  number of jobs for the utility \
have been selected. 
#d_arg command	Keyword to identify the utility that the user has selected.

  global archive

  # Make sure that everything on the current selection list is valid
  db_update_selection

  set job_id ""
  set nselect [llength $archive(CURRENT_SELECTION)]
  if { $nselect == 1 } {
    set job_id $archive(CURRENT_SELECTION)
  } elseif { $archive(LAST_SELECTION) != "" } {
    set job_id $archive(LAST_SELECTION)
  } elseif { $nselect == 0 } {
    if { [DbGetNJOBS] > 0 } {
      # Nothing selected so assume user means to use the last job run
      set job_id [lindex $archive(DISPLAY_LIST) 0]
      set nselect 1
    } elseif { [regexp browse|graph_log|list_script|archive|delete|restore|rerun|edit_notebook|kill_job|edit_job $command] } {
      db_select_warning one "to run any option"
      return 0
    }
  }

  switch -regexp $command \
				\
    dirs {
    RunTask directories -system

  } list_log {
    if { $job_id != "" } {
	set logfile [GetLogFileName $job_id]
	if { ![file isfile $logfile] } {
	    return 0
	}
	DisplayTextFile $logfile \
	-summary -monitor -terminater "CCP4I TERM" \
	-button "Show Log Graphs" "LogGraph [GetLogFileName $job_id]"
      }

  } qtrview_log {

    if { $job_id != "" } {
      if { ![file isfile [GetLogFileName $job_id]] } { return 0 }
      qtrview::launchReportViewer $job_id
    }

  } browse_annotated {

    if { $job_id != "" } { open_url [GetLogFileName $job_id].html }

  } browse_log {

    if { $job_id != "" } { LOGViewer [GetLogFileName $job_id ] }

  } browse_summary {

    if { $job_id != "" } { LOGViewer [GetLogFileName $job_id ] -summary }

  } graph_log {
      if { $job_id != "" } {
        if { [file exists [GetLogFileName $job_id ]] } {
          LogGraph [GetLogFileName $job_id ] }
       } else {
        db_select_warning "one"  "displaying log file graphs"
       }

  } list_script {
    DisplayTextFile [DbMergeComFiles $job_id] -nomonitor

  } {archive|delete} {

    if { ![DbVerifyLock] } {
      WarningMessage "Database Access Warning

This instance of CCP4i no longer has control
of the current database. This is probably
because another CCP4i is running and has
taken control of the database over from this
one.

It is unsafe in these circumstances to alter
the job database.

The safest action is to close this instance
of CCP4i and check that there are no other
CCP4is running before restarting."
      return
    }

    if { $nselect > 1 } {
      db_archive_window $archive(CURRENT_SELECTION)
    } else {
      db_archive_window $job_id
    }

  } restore {
      db_restore_window $job_id

  } rerun {
    if { $nselect == 1 } {
     db_rerun  $job_id
    } else { db_select_warning "one"  "rerunning job" }

  } edit_notebook {
     if { $job_id != "" } { db_edit_notebook $job_id }

  } kill_job {
     if { $nselect == 1 } {
       DbKillJob  $job_id
     } else {  db_select_warning "one" "killing job" }

  } stop_job {
     if { $nselect == 1 } {
       DbStopJob $job_id
     } else {  db_select_warning "one" "stopping job" }

  } edit_job {
     if { $nselect == 1 } {
       db_edit_info $job_id
     } else { db_select_warning "one" "edit job info" }

  } report_job {
     db_edit_info 0

  } preferences {

    RunTask pref
  } searchsort {
    ssdb_setup

  } dbviewer {
    RunDbviewer [GetCurrentProject]

  } session_log {
     db_view_session_log

  } configure {
     RunTask config
  } custom_colours {
     RunTask colour
  } domains {
     RunTask domains
  } edit_modules {
     RunTask edit_modules
  } install {
     RunTask install_task
  } dbconfig {
     db_config_window
  } autotest {
     db_autotest
  }
  return
}


#---------------------------------------------------------------------------
proc DbDrawUtilityMenu {} {
#---------------------------------------------------------------------------
#d_sum Draw the utility menu
#d_desc  This procedure defines the menu content and then call \
db_draw_utilities which does the drawing.
  global archive

  if { [info exists suboptions] } { unset suboptions }

  set optionlist [list [list "View Files from Job" \
				"View Log File" \
                                "View Log Graphs" \
                                "View Command Scripts" ] \
			{Search/Sort Database..} \
			{Graphical View of Project} \
			{Delete/Archive Files..} \
			{Kill Job} \
                        {ReRun Job..} \
                        [list "Edit Job Data" \
				"Read/Edit Notebook"  \
                                "Edit Job Data" \
                                "Enter Data for External Job" ] \
			"Preferences" \
                        [list "System Administration"  \
  			"View Session Log" \
                        "Configure Interface" \
                        "Customise Job List Colours" \
			"Edit Task List" \
                        "Install/uninstall Tasks" \
			"Database Configuration" \
                        "Run Tests" ]	]
  set commandlist [ list [ list list_log graph_log list_script ] \
			searchsort \
			dbviewer \
			archive \
			kill_job \
			rerun \
			[ list edit_notebook edit_job report_job ] \
			preferences \
			[list session_log configure custom_colours edit_modules \
			install dbconfig autotest ] ]
  set messagelist [list \
	"Display the log file from a selected job" \
	"Search for entries within the database and/or sort the list of jobs" \
	"Launch DbViewer to see a graphical view of the current project" \
	"Delete and/or archive the files generated by selected job(s) & optionally remove from database" \
	"Kill the job" \
	"Rerun the selected job" \
	"Edit information or notebook entry associated with selected job(s)" \
	"Set preferences for CCP4I creating maps and deleting/archiving files" \
	"Configure or install new task" ]

  set helpfile [SearchPath HELP general database.html]

  set helplist [list \
	review_log_file \
	search_sort_db \
	delete/archive_files \
	rerun_job \
	kill_job \
	notebook \
	preferences \
	system_administration ]
	
  set activelist [list 1 1 1 1 1 1 1 1 1]

  db_draw_utilities $optionlist $commandlist $messagelist \
           $activelist $helpfile $helplist
  return
}

#--------------------------------------------------------------------
proc db_draw_utilities { optionlist commandlist messagelist \
        activelist helpfile helplist args } {
#--------------------------------------------------------------------
#d_sum Draw a utility menu on the right side of main window.
#d_desc All information for drawing the menus is input as lists \
with one list item per menu item.  This approach makes it easy \
to change the menu but ccp4i currently does not do this (it's probably \
a bad thing anyway).  It ought to be possible to write a similar \
procedure which draws the utilities as pull down menus and the user \
can then have the option on how to lay out the main window.
#d_arg optionlist A list of the text to appear in menu.  \
If the menu item has a submenu then the item is a list.
#d_arg commandlist A list of the command keywords to be used \
by db_command_handler to invoke the right utility procedure.
#d_arg messagelist A list of the messages associated with each \
menu item. Note that there are no distinct messages for each submenu item.
#d_arg activelist A list of 0/1 to indicate if a menu item \
is active.  Currently all input has these set to 1.
#d_arg helpfile Name of a help file.
#d_arg helplist List of the targets in the help file for each menu.
#d_opt0 -ssdb
#d_opt1 Indicates that the menu is drawn from search/sort tool

  global configure

  # Process the arguments
  set ssdb 0
  if { [lsearch -exact $args "-ssdb"] > -1 } {
    set ssdb 1
  }

  # Determine which window we are calling from
  if { $ssdb } {
     set frame ".search"
  } else {
     set frame [GetSystemVar DBOPTIONFRAME]
  }
   
  set noptions [llength $optionlist]

  if { ![ winfo exists $frame ] } {  return }

  set enclose $frame.f
  if { ![winfo exists $enclose] } {
     frame $enclose -background $configure(COLOUR_VERY_PALE)
     if { $ssdb } {
	      pack $enclose -side top
     } else {
	      pack $enclose -side top }
  } else {
    foreach item [winfo children $enclose ] {
      destroy  $item
    }
  }

  for { set n 0 } { $n < $noptions } { incr n } {
    if  { [lindex $activelist $n] } {
      set option [lindex $optionlist $n ]
      set command [lindex $commandlist $n]
      if { [llength $command] == 1} {
	# Normal button represents this option
        if {$ssdb} {
          # Deal with Search/Sort context
          if {$option=="Delete/Archive Files.."} {
            set f  [ button $enclose.f_$n -text "$option" \
                   -font $configure(FONT_REGULAR) \
                   -anchor n -width 20 -borderwidth 2  -pady 2 \
                   -command "db_command_handler $command" ]
          } else {
            set f  [ button $enclose.f_$n -text "$option" \
                  -font $configure(FONT_REGULAR) \
                  -anchor n -width 15 -borderwidth 2  -pady 2 \
                  -command "db_command_handler $command" ]
          }
        } else {
          # Other contexts (assumed to be in main taskbrowser window)
          set f  [ button $enclose.f_$n -text "$option" \
                  -font $configure(FONT_REGULAR) \
                  -anchor w -width 25 -borderwidth 2 -pady 2 \
                  -command "db_command_handler $command" ]	   
        }
      } else {
        # Menubutton represents this option
        set buttonwidth 24
	set anchor w
	if { $ssdb } {
	    # Reset the attributes to use narrower buttons with
	    # centered text for Search/Sort context
	    set buttonwidth 20
	    set anchor center
        }
	# Create the button
        set f [ menubutton $enclose.f_$n -text [lindex $option 0] \
              -font $configure(FONT_REGULAR) \
              -indicatoron 1 -relief raised  \
              -width $buttonwidth -justify left \
              -menu $enclose.f_$n.m1 \
	      -anchor $anchor]
        menu $enclose.f_$n.m1  -tearoff 0
        set i -1
        foreach subopt [lrange $option 1 end] {
          incr i
          $enclose.f_$n.m1 add command -label $subopt \
	                       -font $configure(FONT_REGULAR) \
                           -command "db_command_handler  [lindex $command $i]"
        }
        if {[regexp View [lindex $option 0]]} { 
          if {! $ssdb} {
            SetSystemVar VIEW_JOB_MENU  "$enclose.f_$n.m1"
            bind $enclose.f_$n <Button-1> "DbViewJobMenu"
		  } else {
            SetSystemVar VIEW_JOB_MENU_SS  "$enclose.f_$n.m1"
            bind $enclose.f_$n <Button-1> "DbViewJobMenu -ssdb"}
        }
      }
      if {$ssdb } {
        pack $f -side right
      } else { 
        pack $f -side top -anchor w
      }
      SetMessage moduledef $f "[lindex $messagelist $n]"
      if { $helpfile != "" } {
        bind $f <Button-3> "KeywordHelp $helpfile [lindex $helplist $n]"
      }
    }
  }
  update idletasks
  if {! $ssdb} {
    set canvas [winfo parent $frame]
    $canvas configure -scrollregion [$canvas bbox all]
    $canvas configure -width [winfo width $frame]
    $canvas yview moveto 0.0
  }
}
#----------------------------------------------------------
proc DbViewJobMenu  { args } {
#----------------------------------------------------------
#d_sum  Update "View Job File" menu to list the in/output files for selected job
#d_desc This procedure is called when the user  selects a job.  \
The id of the menu is saved as SystemVar VIEW_JOB_JOBID.
#d_desc The procedure tries to give appropriate options dependent \
on format of log file (? is it html) but does not look for tables \
in log file as this can be slow for big log files.
#d_opt0 -ssdb
#d_opt1 Indicates that the view is in the search/sort tool

  global configure
  global archive 
  global preferences

  # Process the arguments
  set ssdb 0
  if { [lsearch -exact $args "-ssdb"] > -1 } {
    set ssdb 1
  }

  set job_id $archive(LAST_SELECTION)
  if { $job_id == 0 || $job_id == "" } { set job_id [DbGetNJOBS] }
  if { $job_id == 0 || $job_id == "" } { return }

  # Find out length of menu currently displayed
  # & delete any previous files from the menu
  if { ! $ssdb } {
    set mm [GetSystemVar VIEW_JOB_MENU]
  } else {
    set mm [GetSystemVar VIEW_JOB_MENU_SS]
  }
  
  $mm delete 0 [$mm index end]
  if { $job_id == 0 } { return }

  # Search output files for addtional log(graphs) and output directories
  set logfiles ""
  set loggraphs ""
  set directories ""
  set nfiles [DbGetJobFiles $job_id OUTPUT filelist -all] 
  if { $nfiles > 0 } {
    foreach file $filelist {
    Report 2 $file
      if { [file isdirectory $file] } {
	lappend directories $file
      } elseif { [file extension $file] == ".log" && [file exists $file] } {
	lappend logfiles $file
      } elseif { [file extension $file] == ".loggraph" && [file exists $file] } {
	lappend loggraphs $file
      }
    }
  }

  # Main logfile

  if { [qtrview::isEnabled] } {
     $mm add command -label "View Job Results (new style)" -font $configure(FONT_REGULAR) -command "qtrview::launchReportViewer $job_id"
  }

  GetLogFileFormat $job_id logfile format
  if { [lsearch $format "HTML"] > -1 } {
  $mm add command -label  "View LogFile in Web Browser" \
  -font $configure(FONT_REGULAR) \
  -command "db_command_handler browse_log"
  $mm add command -label  "View LogSummary in Web Browser" \
  -font $configure(FONT_REGULAR) \
  -command "db_command_handler browse_summary"
  }

 # Graphs in main logfile
if { [lsearch $format "TEXT"] > -1 } {
 $mm add command -label "View Log Graphs" \
  -font $configure(FONT_REGULAR) \
  -command "db_command_handler graph_log"

 }

  if { ! $preferences(DYNAMIC_ANNOTATION) } {
      # No dynamic generation - give the option to view
      # an existing file
      if { [lsearch $format "ANNOTATED"] > -1 } {
	  $mm add command -label  "View Annotated Log in Web Browser" \
	      -font $configure(FONT_REGULAR) \
	      -command "db_command_handler browse_annotated"
      }
  } else {
      # Dynamic generation, provided that a logfile exists
      if { [lsearch $format "TEXT"] > -1 } {
	  if { [lsearch $format "ANNOTATED"] > -1 } {
	      # Annotated file already exists
	      set logfile [GetLogFileName $job_id]
	      set annotatedlog "$logfile.html"
	      $mm add command -label "View Annotated Log in Web Browser" \
		  -font $configure(FONT_REGULAR) \
		  -command "DeleteFile $annotatedlog ; CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
	  } else {
	      # No pre-existing file
	      $mm add command -label "View Annotated Log in Web Browser" \
		  -font $configure(FONT_REGULAR) \
		  -command "CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
	  }
      }
  }

if { [lsearch $format "TEXT"] > -1 } {
 $mm add command -label  "View Log File (old style)" \
  -font $configure(FONT_REGULAR) \
  -command "db_command_handler list_log"
 }

  $mm add separator

  # Lists of input and output files
  for { set i 0 } { $i < 2 } { incr i } {
    $mm add command -label "[lindex {Input Output} $i] files .."  \
        -font $configure(FONT_ITALIC)
    set nfiles [DbGetJobFiles $job_id [lindex {INPUT OUTPUT} $i] filelist]
    foreach file $filelist {
      # Make sure that additional logfiles/graphs aren't displayed
      # twice by excluding them here
      if { [lsearch $logfiles $file] < 0 && [lsearch $loggraphs $file] < 0 } {
        if { [file exists $file] } {
          $mm add command -label "[file tail $file]" \
		  -command "FileViewer \"$file\" -noquery"
        }
      }
    }
  }

  # Additional logfiles
  set nlogfiles [llength $logfiles]
  if { $nlogfiles > 0 } {
    # Reset (or create) a cascading entry for the list of logfiles
    set lfmm $mm.logs
    if { [winfo exists $lfmm] } {
       $lfmm delete 0 [$lfmm index end]
    } else {
       set lfmm [menu $lfmm -tearoff 0]
    }
    $mm add cascade -label "Additional log files .."  \
	-font $configure(FONT_ITALIC) -menu $lfmm
    # Add the files to the submenu
    foreach file $logfiles {
       if { [file exists $file] } {
	   $lfmm add command -label "[file tail $file]" \
		   -command "FileViewer \"$file\" -noquery"
       }
    }
  }

  # Additional loggraphs
  set nloggraphs [llength $loggraphs]
  if { $nloggraphs > 0 } {
    # Reset (or create) a cascading entry for the list of loggraphs
    set lgmm $mm.graphs
    if { [winfo exists $lgmm] } {
       $lgmm delete 0 [$lgmm index end]
    } else {
       set lgmm [menu $lgmm -tearoff 0]
    }
    $mm add cascade -label "Additional log graphs .."  \
	-font $configure(FONT_ITALIC) -menu $lgmm
    # Add the files to the submenu
    foreach file $loggraphs {
       if { [file exists $file] } {
	   $lgmm add command -label "[file tail $file]" \
		   -command "FileViewer \"$file\" -noquery"
       }
    }
  }

  # Acquire taskname and add any available plugins
  set taskname [DbGetJobData $job_id TASKNAME]
  # special cases when some input files should be presented too
  if { $taskname == "refmac5" } {
     DbGetJobFiles $job_id INPUT filelist1
     foreach filen $filelist1 {
       switch -regexp $filen {
          ".*\.refmac\.cif$" {
              # Data harvesting file, ignored
          }
          ".*\.cif\$" {
              # CIF file - assume it's a dictionary
              lappend filelist $filen
          }
       }
    }
  }
  if { [llength [set plugins [GetPlugins $taskname $filelist]]] > 0 } {
      $mm add separator
      foreach plugin $plugins {
	  $mm add command -label "[lindex $plugin 0]" \
	      -command "[lindex $plugin 1]"
      }
  }

  # Deal with directories
  if { [llength $directories] > 0 } {
    $mm add command -label "Output directories .."  \
        -font $configure(FONT_ITALIC)
    # This could be recursive
    dbviewjobmenu_cascade_dirs $mm $directories
  }

  # Access to subjobs
  if { [DbJobHasSubjobs $job_id] } {
      $mm add separator
      $mm add command -label "View subjobs for this job" \
	  -font $configure(FONT_REGULAR) \
	  -command "RunDbviewer [GetCurrentProject] $job_id"
  }

  # Trailing options
  $mm add separator

  # Link to command scripts
  $mm add command -label "View Command Scripts" \
    -font $configure(FONT_REGULAR) \
    -command  "db_command_handler list_script"

  # (Re)generate annotated logfile
  if { ! $preferences(DYNAMIC_ANNOTATION) } {
      set logfile [GetLogFileName $job_id]
      set annotatedlog "$logfile.html"
      if { ![file exists $annotatedlog] } {
	  # No annotated logfile - offer to make one
	  $mm add command -label "Generate annotated logfile" \
	      -font $configure(FONT_ITALIC) \
	      -command "CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
      } else {
	  # Offer to regenerate the existing annotated logfile
	  $mm add command -label "Regenerate annotated logfile" \
	      -font $configure(FONT_REGULAR) \
	      -command "DeleteFile $annotatedlog ; CreateAnnotatedLogfile $logfile ; db_command_handler browse_annotated"
      }
  }

  # Link to notebook
  if { [db_job_has_notebook $job_id] } {
    set message "View/edit notebook entry"
  } else {
    set message "Add notebook entry"
  }
  $mm add command -label "$message" \
      -font $configure(FONT_ITALIC) \
      -command  "db_edit_notebook $job_id"


  return
}

#-----------------------------------------------------------------------
proc dbviewjobmenu_cascade_dirs { mm directories } {
#-----------------------------------------------------------------------
#d_sum Append cascading menus for subdirectory contents
#d_desc This procedure is used from within DbViewJobMenu, to add a \
cascading menu to the end of the "View Files From Job" menu for each \
output subdirectory that is associated with the job.
#d_desc The cascading menu lists the files contained within the \
subdirectory, and further cascading menus for each of the subdirectories \
within the current subdirectory. The procedure is called recursively \
to add further layers of nesting as required.
#d_arg mm The window name for the Tk menu to add the cascades to
#d_arg directories A list of directories to be added
    set ndir 0
    set dirlist {}
    foreach dir $directories {
	set dirfilelist [glob -nocomplain -directory $dir *]
	if { [llength $dirfilelist] > 0 } {
	    # Reset (or create) a cascading entry for the list of directories
	    set dirmm $mm.dirs$ndir
	    if { [winfo exists $dirmm] } {
		$dirmm delete 0 [$dirmm index end]
	    } else {
		set dirmm [menu $dirmm -tearoff 0]
	    }
	    # Make the cascading entry
	    $mm add cascade -label "[lindex [file split $dir] end]"  \
		-menu $dirmm
	    # Add the files to the submenu
	    foreach filen $dirfilelist {
		if { [file isfile $filen] } {
		    $dirmm add command -label "[file tail $filen]" \
			-command "FileViewer \"$filen\" -noquery"
		} elseif { [file isdir $filen] } {
		    # Store the directory for later
		    lappend dirlist $filen
		}
	    }
	    incr ndir
	}
    }
    # Deal with any directories by calling this procedure again
    if { [llength $dirlist] > 0 } {
	dbviewjobmenu_cascade_dirs $dirmm $dirlist
    }
}
    
#d_index_title Initialising, Loading & Saving the Database

#-----------------------------------------------------------------------
proc DbGetCurrentProject { projectVar } {
#-----------------------------------------------------------------------
#d_sum Return the project alias and database directory for the current \
project.
#d_desc Just a wrapper for GetCurrentProject.
#d_arg projectVar Name of variable in which the project alias will be \
returned.

  upvar $projectVar project
  set project [GetCurrentProject]
  return
}

#-------------------------------------------------------------------------
proc DbInitialise { } {
#-------------------------------------------------------------------------
#d_sum Initialise project database. 
#d_desc Called from taskbrowser or whatever is main program

  global archive

  set archive(CURRENT_SELECTION) ""
  set archive(LAST_SELECTION) ""
  set archive(CURRENT_DATABASE) database
  set archive(VIEW_JOB_JOBID) 0

  ## If no directories info available then let the user define
  ## some now?
  if { [InitialiseDirectories] == 1 } {
    Directories init
  }

  DbOpen -init
  Report 2 "DbInitialise: CURRENT_PROJECT = [GetCurrentProject]"
  Report 2 "DbInitialise: PROJECT_DATABASE = [GetProjectDatabase]"

  # Register the callback to DbUpdateList
  # to force redraw of the joblist whenever the database is updated
  DbRegisterCallback ScheduleDbUpdateList
  return
}

#-------------------------------------------------------------------------
proc DbOpen { args } {
#-------------------------------------------------------------------------
#d_sum Open a project database within CCP4i
#d_desc This is essentially a wrapper to DbOpenDatabase which \
also performs some CCP4i-specific admin tasks, and invokes \
graphical components if prompting is required from the user.
#d_opt0 -init
#d_opt1 Should be specified the first time the procedure is \
invoked. It forces drawing of the utility menu if CCP4i is \
running in taskbrowser mode.

  global system

  # Initialise
  set project [GetCurrentProject]
  set option  ""
  set init 0

  # Process arguments
  set nargs [llength $args]
  if { $nargs > 0 } {
    set i 0
    while { $i < $nargs } {
      switch -regexp -- [lindex $args $i] {
	-init {
	   set init 1
	}
      }
      incr i
    }
  }

  # Try to open the database
  set status [DbOpenDatabase $project]
  if { $status < 0 } {
      # The open failed due to the presence of a lock
      # Try to retrieve the data on the lock from the database messaging
      # function - this should tell us who locked the project, and when
      set lock_info [DbGetMessage]
      if { [llength $lock_info] == 3 && [lindex $lock_info 0] == "Lock" } {
	  set user [lindex $lock_info 1]
	  set time [lindex $lock_info 2]
      } else {
	  set user "<unknown>"
	  set time "<unknown>"
      }
      # Ask the user how to proceed
      set action [db_query_lock $project $user $time]
      Report 2 "DbOpen: action is \"$action\""
      # Exit - don't use Exit Interface cos it tries to save the database
      if {[regexp Exit $action]} { exit 0 }
      # Override lock - try to open the database again
      if { [regexp Override $action]} {
	  set status [DbOpenDatabase $project -grablock]
      }
  }

  # Check status and do some CCP4i-specific admin tasks
  if { $status == 1 } {
      # Database loaded ok
      Report 2 "DbOpen: db loaded okay"
  } else {
      # No database loaded
      Report 2 "DbOpen: no db loaded"
  }

  # Update the status of any jobs already listed as RUNNING etc
  DbUpdateStatus

  # Initialise the taskbrowser, if necessary
  if {[regexp taskbrowser $system(RUN_MODE)]} {
    wm title . "$system(CCP4_VERSION) $system(VERSION) running on [GetHostname]   Project: [GetCurrentProject]"
    # If in "init" mode then draw utility menu
    if { $init } {
      DbDrawUtilityMenu
    }
    # Force the job list to be drawn the first time
    # This should happen automatically for subsequent
    # changes to the job database
    DbUpdateList
  }
  return
}

#-------------------------------------------------------------------------
proc DbClose {} {
#-------------------------------------------------------------------------
#d_sum Close the currently open project database within CCP4i
#d_desc This is essentially a wrapper to DbCloseDatabase.

  DbGetCurrentProject project
  Report 2 "DbClose: closing $project"
  DbCloseDatabase $project
  return
}

#-----------------------------------------------------------
proc DbChangeFile { project } {
#-----------------------------------------------------------
#d_sum Change the project database
#d_desc The user has changed the project so update the \
current project directory and database.

  global system

  # Check that we're not already in the selected project
  if { $project == [GetCurrentProject] } {
    return 1
  }

# Work out what should be default database for current project and
# see if it exists - just load data if it exists

  if { ![ProjectIsDefined $project] } { 
    WarningMessage "Project $project not recognised\nPlease reselect your current project directory"
    return 0
  }

  PleaseWait "..closing current database [GetCurrentProject]"
  DbClose 

  SetCurrentProject $project

  # Put the name of project in the window title
  if {[regexp taskbrowser $system(RUN_MODE)]} {
    wm title . "$system(CCP4_VERSION) $system(VERSION) running on [GetHostname]   Project: [GetCurrentProject]"
  }
  # If the Amore db has been used then the utilities have been sourced
  # and clear_mr_db is available - so use it to clear all amore windows 
  # and data
  if { [regexp clear_mr_db [info procs clear_mr_db]] } { clear_mr_db }

  # Load the database
  PleaseWait "..loading $project"
  DbOpen
  PleaseWait {}

  # All done
  return 1
}

#d_index_title Handling Input from Running Jobs
#d_intro_title Handling Input from Running Jobs
#d_intro Jobs which are run external to the main graphical ccp4i process return status updates using socket connections.
#d_intro The information returned, the job status, finish time, and output files, is entered into the database using these procedures.

#---------------------------------------------------------------------
proc DbReceive { job_id project args } {
#---------------------------------------------------------------------
#d_sum Update database parameters after receiving status report from external job
#d_desc If the update information is that STATUS is FINISHED then this \
procedure will update the job time to the finish time and call the \
task review procedures. Any task can optionally define a review \
procedure which is called after the job has finished  \
(only a handful of tasks do have review procedures).  Finally redraw the job list.
#d_arg job_id The job number
#d_arg project The database project of the job - beware if user has \
changed project  then cannot update database
#d_arg parameter_1,data_1,parameter_2,data_2..  List of pairs of parameter \
name and value.

#  puts "DbReceive $job_id $project"

  set ndata [expr {[llength $args] / 2} ]

  if { $project != "NO_DATABASE" && $project != [GetCurrentProject] } {
# this job is not one for the current open database file
     Report 2 "Job report for different project received $project"
     return
  } 

# Allow this process to write to the current database?
  if { ![DbVerifyLock] } {
     # If the current CCP4i process doesn't own the database lock
     # then it shouldn't be allowed to write to the database
     # In this case the dbreceive requests will have to be processed
     # later on by a different CCP4i process
     Report 2 "Job report received by process that no longer owns the database"
     return
  }

# Check that record exists
# Do this by looking for a TASKNAME
  if { ![DbItemExists $job_id TASKNAME] } {
     # No record found so ignore
     Report 2 "Job report for non-existent job $job_id received"
     return
  }

  for { set n 0 } { $n < $ndata } { incr n } {

    set mode [lindex $args [expr {$n * 2}] ]
    set data [lindex $args [expr {($n * 2) + 1} ] ]

    if { ![StringSame $mode STATUS] || \
         ![StringSame [DbGetJobData $job_id STATUS] KILLED] } {
      DbSetJobData $job_id $mode $data
    }
  }
  return
}

#------------------------------------------------------------------------
proc DbAddOutputFile { job_id project args } {
#------------------------------------------------------------------------
#d_sum Update list of job output files after receiving command from external job.
#d_arg job_id Job id
#d_arg project The database project of the job - beware if user has changed \
project  then cannot update database
#d_arg  file_1,dir_1,file_2,dir_2..  A list of pairs of parameters, \
the first is the file name and the second the project/directory alias.  \
The file name should ordinarily be just the file name and not the full \
pathname. The dir is a project or directory alias. If a full path is given \
then only the trailing filename is used unless the directory alias is \
\"Full path..\" or an empty string (in which case the directory is set to \
\"Full path..\". If the filename is an empty string then this is still \
stored along with the directory name.

  if { $project != "NO_DATABASE" && $project != [GetCurrentProject] } {
# this job is not one for the current open database file
     Report 2 "Job report for different database received $project"
     return
  }

  set files [DbGetJobData $job_id OUTPUT_FILES]
  set dirs [DbGetJobData $job_id OUTPUT_FILES_DIR]

  set nf [expr {[llength $args] / 2}] ; set n 1; set i -1
  while { $n <= $nf } {
    # Get the trailing filename
    incr i
    set filen [lindex $args $i]
    incr i
    set dirn [lindex $args $i]
    if { [file pathtype $filen] == "absolute" } {
      # Full filename was supplied
      if { $dirn == "Full path.." || $dirn == "" } {
        lappend files $filen
        lappend dirs "Full path.."
      } else {
        lappend files [file tail $filen]
        lappend dirs $dirn
      }
    } else {
      # Relative filename was supplied
      lappend files [file tail $filen]
      lappend dirs $dirn
    }
    incr n
  }
  DbSetJobData $job_id OUTPUT_FILES $files
  DbSetJobData $job_id OUTPUT_FILES_DIR $dirs

}
    
#------------------------------------------------------------------------
proc DbUpdateOutFiles { job_id { start_time 0 } } {
#------------------------------------------------------------------------
#d_sum Check the existence of the listed output files for a job
#d_desc If the job start time is defined then also check that any file \
with the appropriate name was created between the job start and finish \
time. If the file does not exist or has wrong creation time then remove \
it from the list of output files.
#d_desc Nb The output 'files' can also include directories. In this \
case the filename should be an empty string.
#d_arg job_id Job id
#d_arg start_time Optional job start time in machine time.

  # Check that the job exists
  if { ![DbJobExists $job_id] } {
      return
  }

  # Grab all data at once
  set job_data [DbGetJobData $job_id DATE OUTPUT_FILES OUTPUT_FILES_DIR]
  if { [llength $job_data] != 3 } {
      # Some error has occurred
      puts "DbUpdateOutFiles: error acquiring data for job $job_id:"
      puts "\"$job_data\""
      return
  }
  set finish_time [lindex $job_data 0]
  set output_files [lindex $job_data 1]
  set output_dirs [lindex $job_data 2]
  set modified 0
  set OKlist {}
  set OKdir {}
  set OKstatus {}
  set n -1; foreach file $output_files { incr n
    if { $file != "" } {
      set filename [GetFullFileName $file  [lindex $output_dirs $n]]
    } else {
      set filename [GetFullDirName [lindex $output_dirs $n]]
    }
    if { [file exists $filename]  } {
       lappend OKlist $file
       lappend OKdir [lindex $output_dirs $n]
    } elseif { [DbArchiveExists $filename $job_id ] } {
       lappend OKlist $file
       lappend OKdir [lindex $output_dirs $n]
    } else {
       incr modified
    }
  }
  if { $modified } {
    DbSetJobData $job_id OUTPUT_FILES $OKlist OUTPUT_FILES_DIR $OKdir
  }
}

#-----------------------------------------------------------------------
proc DbCheckOutputFiles { filename args } {
#-----------------------------------------------------------------------
#d_sum Look through all jobs and check uniqueness of output file name
#d_desc Return a list of job ids which have output files with the given name
#d_desc This procedure is most useful in checking that a currently running job \
not create a file of the same name.
#d_opt0 -running 
#d_opt1 Only search through currently running jobs 
  
  if { [set njobs [DbGetNJOBS] ] <= 0 } { return {} }
  set return_list ""

  # Check command line options
  set running 0
  if { [lsearch -regexp $args run ] >= 0 } {
    set running 1
  }

  # Get a list of jobs that we should check against
  if { $running } {
    # Limit search to those that are currently running
    set check_jobs [DbSelectJobs STATUS START|HOLD|RUNNING|REMOTE ]
  } else {
    # Search all jobs
    set check_jobs [DbSelectJobs OUTPUT_FILES .* ]
  }

  # Nothing to do?
  if { [llength $check_jobs] == 0 } {
    return {}
  }

  # Look for all jobs that have this output file
  set job_list [DbSelectJobs OUTPUT_FILES "$filename"]
  foreach job_id $job_list {
    if { [lsearch -exact $check_jobs $job_id] > -1 } {
      lappend return_list $job_id
    }
  }
  return $return_list
}

#------------------------------------------------------------------
proc DbUpdateStatus { } {
#------------------------------------------------------------------
#d_sum For any job with status RUNNING check log file to see it it has finished
#d_desc This procedure is usually called when ccp4i is started
#d_desc Checks jobs with status RUNNING REMOTE ON_HOLD

# Check out any jobs in database that are still "RUNNING" - look
# at end of log file to see if finished

  DbGetCurrentProject project

  set job_list [DbSelectJobs STATUS HOLD|RUNNING|REMOTE ]
  foreach job_id $job_list {
    set logfile [GetLogFileName $job_id]
    Report 1 "Job $job_id: Checking status of running job from logfile $logfile"
    ReportJobFinish $logfile status time output_files
    if { $status == 1 } {
      DbSetJobData $job_id STATUS FINISHED
      if { $time != "" } { DbSetJobData $job_id DATE $time }
    } elseif { $status == 3 } {
      Report 1 "Job $job_id: cannot read log file $logfile"
    } elseif { $status != 2 }  {
      DbSetJobData $job_id STATUS FAILED
      if { $time != "" } { DbSetJobData $job_id DATE $time }
    }
    if { $output_files != {} } {
      eval [concat DbAddOutputFile $job_id NO_DATABASE $output_files ]
    }
  }

  # Check again periodically (every 5 minutes)
  after 300000 { DbUpdateStatus }

  return
}

#-------------------------------------------------------------
proc ReportJobFinish { logfile statusVar timeVar output_filesVar } {
#-------------------------------------------------------------
#d_sum Read end of logfile to find termination status
#d_desc ccp4i scripts put a short section of termination status on \
end of log file which is usually not needed but may be checked for \
jobs which have RUNNING status when ccp4i graphical process is started.
#d_arg logfile Name of log file
#d_arg statusVar Returned status for job
#d_arg timeVar	Returned finish time for job
#d_arg output_filesVar Returned list of output files (this will be list \
of file/dir alias pairs)
  upvar $statusVar status
  upvar $timeVar time
  upvar $output_filesVar output_files

  set status 0
  set time ""
  set output_files ""

  if { $logfile == "" || ![file exists $logfile] } { 
    set status 3
    return
  }

  if { ![ReadEndOfFile $logfile 20 logtext ] } {
#    Report 2  "Can not read log file $logfile "
    set status 3
    return
  }

  if { ![ExtractTextLine $logtext "CCP4I TERMINATION STATUS" \
			0 all statusline ] } {
    set status 2
  } else {
    set status [lindex $statusline 3 ]
    if { $status == "" } { set status 2 }
    if {[ExtractTextLine  - "CCP4I TERMINATION TIME" 0 all line ]} {
      set date [string trimleft [string range $line \
                  [expr {[string first "TIME" $line ] + 4} ] end ] ]
      set time [clock scan $date]
    }
    if {[ExtractTextLine  - "CCP4I TERMINATION OUTPUT_FILES" \
               0 all line ]} {
      set output_files [lrange $line 3 end]
    }
  }

  unset logtext

  if { $status == 2 } {
    Report 2 "Job still running, log file: $logfile"
  } else {
    Report 2 "Job finished, log file: $logfile"
    if { [lindex $statusline 3 ] != "1" } {
      Report 2 "Job status: FAILED"  -notime
    }
  }
}

#------------------------------------------------------------------------
proc DbHandleOverwrite { filename } {
#------------------------------------------------------------------------
#d_sum Remove filename from database for file that user has opted to overwrite
#d_desc When specified output file already exists and user has opted to \
overwrite it then check thru all jobs in database to see if the overwritten \
file is a recognised output file.  If it is then delete it from the \
output_file list of the previous job.
#d_arg filename  File name - NOT the full path name

  if { [set njobs [DbGetNJOBS] ] <= 0 } { return }

  set job_list [DbSelectJobs OUTPUT_FILES .*]
  foreach job_id $job_list {
    set output_files [DbGetJobData $job_id OUTPUT_FILES]
    if { [llength $output_files ] > 0 &&
      [set hit [lsearch $output_files $filename]] >= 0 } {
      DbSetJobData $job_id OUTPUT_FILES \
	      [lreplace $output_files $hit $hit]
      DbSetJobData $job_id OUTPUT_FILES_DIR \
	      [lreplace [DbGetJobData $job_id OUTPUT_FILES_DIR] $hit $hit]
      DbSetJobData $job_id OUTPUT_FILES_STATUS \
	      [lreplace [DbGetJobData $job_id OUTPUT_FILES_STATUS] $hit $hit]
# Assume same file name only occurs once in database 
# We can quit once we've found it
        return
    }
  }
}

#d_index_title Database Utility GUIs

#--------------------------------------------------------------------------
proc db_archive_window  { job_id_list } {
#--------------------------------------------------------------------------
#d_sum  Draw the window with archive/delete options 
#d_desc call db_cleanup_handler and db_archive_handler to do the business
#d_desc NB code from this procedure has been hacked together in the \
db_removeoutput_handler (which is used to delete files when the "Kill&Remove" \
option is selected). The common code should probably be farmed out to separate \
procedures in the future.
#d_arg job_id_list List of job ids

  global archive
  global configure
  global preferences

  DbGetCurrentProject project

  set w ".archive"
  if { [winfo exists $w] } { return 0 }

  DefineVariable archive LOGFILE _log_archive_status Keep
  DefineVariable archive INPUT_FILES,0 _archive_status Keep
  DefineVariable archive OUTPUT_FILES,0 _archive_status Keep

  OpenWindow $w "Archive/Delete Files" "Archive" \
    -help [SearchPath HELP general database.html ] -target "delete/archive_files"

  CreateFrame  $w archive

  CreateButton $w dismiss Dismiss "CloseWindow archive" -default
  CreateButton $w action Apply&Exit \
    "CloseWindow archive; db_lock_and_archive [list $job_id_list]" -default

  CreateLineTemplate ARCH_DEL " 0.0 0.6"

  OpenFolder protocol

  set n_output_files 0

# If there are multiple jobs selected and all have script & log files present 
# then make a menu option to apply to all jobs

  if { [llength $job_id_list] > 1 } {
#    set missing 0
#    foreach job_id $job_id_list {
#      set script_name [DbGetJobFileRoot $job_id TEMPORARY].run
#      set logfile [DbGetJobFileRoot $job_id PROJECT].log
#      if { ![file exists $script_name ] ||  \
#         ![file exists $logfile] } { incr missing }
#    }
    set archive(DELETE_OPTIONS_ALL) $preferences(CLEANUP_DEFAULT)
    set archive(_DELETE_OPTIONS_ALL) _archive_cleanup_options_3

    CreateLine line \
      label "For all selected jobs" \
      widget DELETE_OPTIONS_ALL  \
      -command "db_archive_window_update ALL [list $job_id_list]"
  }

  foreach job_id $job_id_list {

    DbUpdateOutFiles $job_id

    set logfile [DbGetJobFileRoot $job_id PROJECT].log
    if {[file exists $logfile]} {
      set file_status 3
    } else {
      set file_status 1
    }
 
    set desc [DbJobDescription $project $job_id \
        [list JOB_ID DATE TASKNAME ] [ list 5 25 40 ] ]

    CreateLine line \
     label "For job $desc"

     $line configure -background $configure(COLOUR_PALE)
     $line.l1 configure -font $configure(FONT_ITALIC) \
		-bg $configure(COLOUR_PALE)

#    puts "job_id $job_id file_status $file_status"
#    puts "CLEANUP_DEFAULT $preferences(CLEANUP_DEFAULT)"

    if { $file_status >= 2 } {
      switch $preferences(CLEANUP_DEFAULT) \
      nothing {
	set archive(DELETE_OPTIONS_$job_id) "Do nothing"
      } temp {
	set archive(DELETE_OPTIONS_$job_id) "Delete temporary files"
      } all {
	set archive(DELETE_OPTIONS_$job_id) "Delete all output files"
      } database {
	set archive(DELETE_OPTIONS_$job_id) "Delete output files & remove from database"
      }
    } else {
      switch $preferences(CLEANUP_DEFAULT) \
      database {
        set archive(DELETE_OPTIONS_$job_id) "Remove from database"
      } default {
        set archive(DELETE_OPTIONS_$job_id) "Do nothing"
      }

    }
    set archive(_DELETE_OPTIONS_$job_id) _archive_cleanup_options_$file_status
    set archive(FILE_LIST,$job_id) ""

    CreateLine line \
      label "Cleanup after job:" \
      widget DELETE_OPTIONS_$job_id  \
	-command "db_archive_window_update $job_id [list $job_id_list]" \
      format margins

# Find if log file or archived log file exist and set appropriate
# options

# NB There needs to option for when both exist!!!!!!

    set iflog 0
    set logfilename [GetLogFileName $job_id]
    if { [file exists $logfilename] && [file isfile $logfilename] } {
      if { [regexp nothing|temp $preferences(CLEANUP_DEFAULT)] } {
        set archive(LOGFILE_$job_id) "Keep"
      } else {
        set archive(LOGFILE_$job_id) Delete
      }
      set archive(_LOGFILE_$job_id) _log_archive_1_status
      set iflog 1
    } elseif { [DbArchiveExists $logfilename $job_id ] } {
      set archive(LOGFILE_$job_id) "Retain archive"
      set archive(_LOGFILE_$job_id) _log_archive_2_status
      set iflog 1
    }
    if { $iflog } {
      CreateLine line \
        label "Log file " \
	label "$logfilename" \
		-italic \
        widget LOGFILE_$job_id
      pack forget $line.mb3
      pack $line.mb3 -side right
    }

    set n_job_files 0
    DbUpdateOutFiles $job_id
    if { [DbItemExists $job_id OUTPUT_FILES] &&
      [llength [DbGetJobData $job_id OUTPUT_FILES] ] > 0 } {

      set jj -1
      foreach file0 [DbGetJobData $job_id OUTPUT_FILES] {
        incr jj
        set dir [lindex [DbGetJobData $job_id OUTPUT_FILES_DIR] $jj]
	if { $file0 != "" } {
          set filename [GetFullFileName $file0 $dir]
        } else {
          set filename [GetFullDirName $dir]
        }

# Set file_status dependent on whether file and/or archive file exist
        set file_status 0
        if { [file exists $filename] } { incr file_status 1 }
        if { [DbArchiveExists $filename $job_id ] } { incr file_status 2 }

# If something exists then list it to window and give user appropriate
# options
        if { $file_status > 0 } {
          incr n_output_files; incr n_job_files
          set archive(OUTPUT_FILE,$n_output_files) $filename
          set archive(OUTPUT_FILE_JOB,$n_output_files) $job_id
          if { $file_status == 1 } {
            if { [regexp nothing|temp $preferences(CLEANUP_DEFAULT)] } {
              set archive(OUTPUT_FILE_STATUS_$n_output_files) "Keep"
            } else {
              set archive(OUTPUT_FILE_STATUS_$n_output_files) Delete
            }
            set archive(_OUTPUT_FILE_STATUS_$n_output_files) _archive_1_status          
          } elseif { $file_status == 2 } {
            set archive(OUTPUT_FILE_STATUS_$n_output_files) "Retain archive"
            set archive(_OUTPUT_FILE_STATUS_$n_output_files) _archive_2_status
          } elseif { $file_status == 3 } {
            set archive(OUTPUT_FILE_STATUS_$n_output_files) \
                                "Keep & retain archive"
            set archive(_OUTPUT_FILE_STATUS_$n_output_files) _archive_3_status
          }
          lappend archive(FILE_LIST,$job_id) $n_output_files
          CreateLine line \
            label "Output " \
            label "$filename" \
                -italic \
            widget OUTPUT_FILE_STATUS_$n_output_files
          pack forget $line.mb3; pack $line.mb3 -side right
        }
      }
    }
  }

  set archive(N_OUTPUT_FILES) $n_output_files
  update_main_scroll $w
}

#-------------------------------------------------------------------
proc db_archive_window_update { job_id job_id_list} {
#-------------------------------------------------------------------
#d_sum Update archive/delete window if user changes default
#d_arg job_id Job id for job with changed default options or 'ALL' \
if overall default is changed
#d_arg job_id_list List of ids for all jobs currently in archive/delete window

  global archive

  set mode [GetValue archive DELETE_OPTIONS_$job_id ]

  if { $mode == "all" || $mode == "database" } { 
    set action "Delete"
  } else {
    set action "Keep"
  }

  if {[regexp -- ALL $job_id]} {
    set jlist $job_id_list
    foreach j $jlist {
# individual job may be typed differently to ALL which is _archive_cleanup_options_3
      if { $archive(_DELETE_OPTIONS_$j) == "_archive_cleanup_options_1" } {
        if { $mode == "database" } {
          set archive(DELETE_OPTIONS_$j) "Remove from database"
        } else {
          set archive(DELETE_OPTIONS_$j) "Do nothing"
        }
      } else {
        set archive(DELETE_OPTIONS_$j) $archive(DELETE_OPTIONS_ALL)
      }
    }
  } else {
    set jlist $job_id
  }

  foreach j $jlist {
    foreach item $archive(FILE_LIST,$j) {
      set archive(OUTPUT_FILE_STATUS_$item) $action
    }
    set archive(LOGFILE_$j) $action
  }
}

#--------------------------------------------------------------------------
proc db_archive_handler { job_id_list } {
#--------------------------------------------------------------------------
#d_sum Delete/archive output files & log file as specified in archive window
#d_arg job_id_list List of the ids for jobs in archive/delete window

  global archive

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1  "ERROR starting db_archive_handler: process has lost the lock"
    WarningMessage "Database Access Warning

This instance of CCP4i no longer has control
of the current database. This is probably
because another CCP4i is running and has
taken control of the database over from this
one.

It is unsafe in these circumstances to alter
the job database and no changes have been
committed.

The safest action is to close this instance
of CCP4i and check that there are no other
CCP4is running before restarting."
    return
  }

  if { $archive(N_OUTPUT_FILES) >  0 } { 

    set extra_job_id_list {}

    for { set n 1 } {$n <= $archive(N_OUTPUT_FILES)} { incr n } {
      set mode [GetValue archive OUTPUT_FILE_STATUS_[subst $n]]

# Either archive or restore the file as appropriate
      if { $mode == "archive" || $mode == "archdel" } {
         DbArchiveFile $archive(OUTPUT_FILE,$n) \
	    $archive(OUTPUT_FILE_JOB,$n) archive
      } elseif { $mode == "restore" || $mode == "restdelarch" } {
         DbArchiveFile $archive(OUTPUT_FILE,$n) \
	    $archive(OUTPUT_FILE_JOB,$n) restore
      }

# Delete the archived file if required

      if { $mode == "delarch" || $mode == "restdelarch" } {
        DeleteFile [ArchiveFileName $archive(OUTPUT_FILE,$n) \
		$archive(OUTPUT_FILE_JOB,$n) -ext] 
        Report 1  "Deleting file: [ArchiveFileName $archive(OUTPUT_FILE,$n) \
		 $archive(OUTPUT_FILE_JOB,$n) ]"
      }

# Delete the file if required
      if { $mode == "delete" || $mode == "archdel" } {
        set output_list [DbCheckOutputFiles $archive(OUTPUT_FILE,$n)]
        if { [llength $output_list ] > 1 } {
          set doit [ChooseOptionDialog Delete Delete \
          "A file called $archive(OUTPUT_FILE,$n) 
is apparently output by more than one job. 
See jobs: $output_list
Are you sure you want to delete it" [list Delete Keep] ]
        } else {
          set doit Delete
        }
        if { [regexp Delete $doit] } { 
          foreach id $output_list {
            if { [lsearch $job_id_list $id] < 0 } { 
               lappend extra_job_id_list $id }
          }
          # Trap against deleting project or default dirs
          if { ![DirIsProject $archive(OUTPUT_FILE,$n)] } {
            if { [DeleteFile $archive(OUTPUT_FILE,$n)] } {
              Report 1  "Deleting file: $archive(OUTPUT_FILE,$n)"
            } else {
              Report 1  "File not deleted: $archive(OUTPUT_FILE,$n)"
            }
          } else {
            WarningMessage "The output \"file\"

$archive(OUTPUT_FILE,$n)

is actually a project directory
This will not be deleted"
            Report 1  "Not deleting dir: $archive(OUTPUT_FILE,$n)"
          }
        }
      }

# If we've just deleted files then see if there is any version of the
# file left and if not then remove record of it from the database

       foreach job_id $job_id_list { DbUpdateOutFiles $job_id }
       foreach job_id $extra_job_id_list { DbUpdateOutFiles $job_id }
    }
  }

# Loop through all the selected jobs log files and do whatever with them

  foreach job_id $job_id_list {
    set logfilename [GetLogFileName $job_id]
    if { $logfilename != "" && ( [ file exists $logfilename]  ||
           [DbArchiveExists $logfilename $job_id ] ) &&
         [ ElementExists archive LOGFILE_$job_id] } {
      set mode [GetValue archive LOGFILE_[subst $job_id] ]

# Annotated logfile from baubles
      set annotatedlog "$logfilename.html"

# Archive the log file or log file highlights
      if { $mode == "archive" || $mode == "archdel" } {
         DbArchiveFile $logfilename $job_id archive
      } elseif { $mode == "archhi" || $mode == "archhidel" } {
         Report 2  "No archive highlights option yet!"
      }

# Restore the archived file
      if { $mode == "restore" || $mode ==  "restdelarch" } {
         DbArchiveFile $logfilename $job_id restore
         # Regenerate annotated logfile
         CreateAnnotatedLogfile $logfilename
      }

# Delete the log files
      if { $mode == "delete" || $mode == "archdel" || $mode == "archhidel" } {         Report 1 "Deleting file: $logfilename"
         DeleteFile [GetLogFileName $job_id]
         qtrview::cleanup $job_id
         if { [ file exists $annotatedlog ] } {
            # Delete annotated log
            DeleteFile $annotatedlog
         }
      }

# Delete archived file
      if { $mode == "delarch" || $mode == "restdelarch" } {
        DeleteFile [ArchiveFileName $logfilename $job_id -ext]
        Report 1  "Deleting file: \
 [ArchiveFileName $logfilename $job_id -ext]"
      }
    }
  }

  foreach job_id $job_id_list {
    DbUpdateOutFiles $job_id
  }
  PleaseWait {}

}

#--------------------------------------------------------------------------
proc db_removeoutput_handler { job_id } {
#--------------------------------------------------------------------------
#d_sum Delete all output files for the selected job
#d_desc This procedure is called when the user selects to Kill a running \
job and remove all output. It prepares input for and then calls \
db_archive_handler, which does the removal.
#d_desc The procedure uses code hacked from db_archive_window. The common \
code should probably be farmed out to separate procedures in the future.
#d_arg job_id The id of the job being removed

  global archive

  # Log file
  # Code hacked from db_archive_window
  set logfilename [GetLogFileName $job_id]
  if { [file exists $logfilename] } {
    set archive(LOGFILE_$job_id) Delete
    set archive(_LOGFILE_$job_id) _log_archive_1_status
  }

  # Other output files
  # Code hacked from db_archive_window
  set n_output_files 0
  DbUpdateOutFiles $job_id
  # Get the output file data
  set output_file_data [DbGetJobData $job_id OUTPUT_FILES OUTPUT_FILES_DIR]
  set output_files [lindex $output_file_data 0]
  set output_files_dir [lindex $output_file_data 1]
  if { [llength $output_files] > 0 } {

    set jj -1
    foreach file0 $output_files {
      incr jj
      set dir [lindex $output_files_dir $jj]
      if { $file0 != "" } {
        set filename [GetFullFileName $file0 $dir]
      } else {
        set filename [GetFullDirName $dir]
      }
      # Set file status dependent on whether it exists
      # Don't worry about archived files - this is a job that is
      # supposed to be running so it shouldn't have any
      if { [file exists $filename] } {
        set file_status 1
      } else {
        set file_status 0
      }
      if { $file_status > 0 } {
        incr n_output_files
        set archive(OUTPUT_FILE,$n_output_files) $filename
        set archive(OUTPUT_FILE_JOB,$n_output_files) $job_id
        # Always delete
        set archive(OUTPUT_FILE_STATUS_$n_output_files) Delete
        set archive(_OUTPUT_FILE_STATUS_$n_output_files) _archive_1_status 
        lappend archive(FILE_LIST,$job_id) $n_output_files
      }
    }
  }
  set archive(N_OUTPUT_FILES) $n_output_files

  # Delete the files with a call to db_archive_handler
  db_archive_handler $job_id
}

#--------------------------------------------------------------------------
proc db_cleanup_handler { job_id_list { action "" }  } {
#--------------------------------------------------------------------------
#d_sum Apply the defined cleanup after a job
#d_desc This procedure will delete temporary files and directories, \
def files, com files (the input scripts for the programs) and remove the \
job from the database. If action is not set then apply the cleanup \
defined by archive(DELETE_OPTIONS) parameter
#d_arg job_id_list List of the ids for jobs in archive/delete window
#d_arg action	Action to apply to the jobs in list (optional)

  global archive

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1 "ERROR starting db_cleanup_handler: process has lost the lock"
    # A warning message will already have been generated by db_archive_handler
    # so just drop out at this point
    return
  }

  set mode_list [list nothing temp all database ]
  DbGetCurrentProject project

  foreach job_id $job_id_list {

    PleaseWait "Cleaning up for job $job_id"

    if { $action != "" } {
       set mode [lsearch $mode_list $action ]
    } else { 
      set mode [lsearch $mode_list \
          [GetValue archive DELETE_OPTIONS_[subst $job_id]]]
    }

    if { $mode <= 0 } { break }

# Delete temporary files 

    set cmd "glob [FileJoin [GetDefaultDirPath TEMPORARY] [subst $project]_[subst $job_id]_*.tmp]"
    if { [catch $cmd  tmp_file_list ] == 0 } {
      foreach tmp_file $tmp_file_list {
        Report 1 "Deleting file $tmp_file"
        DeleteFile $tmp_file
      }
    }

# Delete a temprary directory 
    set cmd "glob [FileJoin [GetDefaultDirPath TEMPORARY] [subst $project]_[subst $job_id]_*_]"
    if { [catch $cmd  tmp_file_list ] == 0 } {
      foreach tmp_file $tmp_file_list {
        Report 1 "Deleting temporary directory $tmp_file"
        DeleteFile $tmp_file 
      }
    }

# Delete a com file
    DeleteFile [subst $project]_[subst $job_id]_*.com

    if { $mode <= 1 } { break }

    if { $mode <= 2 } { break }

# *****Delete all reference to job

# delete archived def files

    set file [ DefFileName $job_id ]
    Report 1  "Deleting file $file"
    DeleteFile $file

# delete everything from database array

    Report 1 "Removing job number $job_id from database"

    DbDeleteJob $job_id

    set ll [lsearch $archive(CURRENT_SELECTION) "$job_id" ]
    if { $ll >= 0 } { set archive(CURRENT_SELECTION) \
        [lreplace $archive(CURRENT_SELECTION) $ll $ll] }
  }

  PleaseWait
}

#--------------------------------------------------------------------
proc db_lock_and_archive { job_id_list } {
#--------------------------------------------------------------------
#d_sum Perform archive/delete operations while the interface is locked
#d_desc This command should be invoked when the used clicks Apply&Exit \
in the Delete/Archive Files window - the interface is locked while the \
operations are in progress, to prevent the user exiting partway through.
#d_arg job_id_list List of job ids
    LockInterface
    db_archive_handler $job_id_list
    db_cleanup_handler $job_id_list
    UnlockInterface
}

#--------------------------------------------------------------------
proc db_restore_window { job_id_list } {
#--------------------------------------------------------------------
#d_sum  Draw the window with file restore options 
#d_desc  Calls db_restore_handler to do the business
#d_arg job_id_list List of the ids for jobs in archive/delete window

  global archive
  global configure

  DbGetCurrentProject project

  set w ".restore"
  if { [winfo exists $w] } { return 0 }

  OpenWindow $w "Restore Archived Files" "Restore" \
             -help [SearchPath HELP general  archive.html ]

  CreateFrame  $w archive

  button $w.buttons.action -text "Apply&Exit"  \
   -font $configure(FONT_REGULAR) \
   -command "db_restore_handler [list $job_id_list]
             CloseWindow archive"
  pack $w.buttons.action  -side right -expand 1

  button $w.buttons.dismiss -text Quit \
   -font $configure(FONT_REGULAR) \
   -command "CloseWindow archive"
  pack $w.buttons.dismiss  -side left -expand 1

  CreateLineTemplate ARCH_DEL " 0.0 0.6"

  OpenFolder protocol

  set n_output_files 0

  foreach job_id $job_id_list {

    GenerateJobFileNames $project $job_id \
       [DbGetJobData $job_id TASKNAME] script_name logfile
    if { [file exists $script_name ] } {
      set file_status 3
    } elseif { [file exists $logfile] } {
      set file_status 2
    } else {
      set file_status 1
    }

  }
  return
}

#--------------------------------------------------------------------
proc db_select_warning { nselect text } {
#--------------------------------------------------------------------
#d_sum Write warning message if user picks utility menu without selecting job(s)
#d_arg nselect Text defining number of jobs that must be selected
#d_arg text Text describing utility that user picked
  WarningMessage "Database $text
You must select $nselect job(s) from the list before picking the action"
}


#--------------------------------------------------------------------
proc db_rerun  { job_id } { 
#--------------------------------------------------------------------
#d_sum Draw interface for rerunning a selected job
#d_arg job_id	Job id
  global archive
  global configure

  set taskname [DbGetJobData $job_id TASKNAME]

  if { [regexp REPORTED [DbGetJobData $job_id STATUS] ] } {
    WarningMessage "Can not rerun non-CCP4i task.
This task was originally reported."
    return  0
  } elseif { [StringSame $taskname load_monomer dictionary] } { 
    WarningMessage "Sorry - Can not rerun this task\ntry running from the Monomer Library Sketcher"
    return 0
  }

# Load the def file for the job
  set deffile [ DefFileName $job_id ]
  set arrayname [CreateNewArray dbtmp]
  InitialiseArray [SearchPath TOP tasks $taskname.def ] \
                    $arrayname $taskname
  InitialiseArray $deffile $arrayname $taskname
  upvar #0 $arrayname array

  set array(RERUN_JOBID) $job_id
  DefineVariable $arrayname OVERWRITE_JOB _logical 0

# Create the task interface

  RunTask $taskname -array $arrayname 

}

#------------------------------------------------------------------------
proc db_edit_info { job_id } {
#------------------------------------------------------------------------
#d_sum Edit the information stored for a job 
#d_desc Use a conventional task interface called taskinfo
#d_arg job_id Id for job to edit.  If it is 0 then enter info for a 'REPORTED' job

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1  "ERROR starting db_edit_info: process has lost the lock"
    WarningMessage "Database Access Warning

This instance of CCP4i no longer has control
of the current database. This is probably
because another CCP4i is running and has
taken control of the database over from this
one.

It is unsafe in these circumstances to alter
the job database.

The safest action is to close this instance
of CCP4i and check that there are no other
CCP4is running before restarting."
    return
  }

  set arrayname taskinfo_$job_id
  InitialiseArray [SearchPath TOP tasks taskinfo.def ] \
                    $arrayname taskinfo
  
  db_load_taskinfo $arrayname $job_id

  RunTask taskinfo -arrayname $arrayname

}

#------------------------------------------------------------------------
proc db_load_taskinfo { arrayname job_id } {
#------------------------------------------------------------------------
#d_sum Load database data for job into a task array
#d_desc This procedure used by db_edit_info
#d_arg arrayname Array name for task array
#d_arg job_id Job id

  upvar #0 $arrayname array

  set array(JOB_ID) $job_id

  if { $job_id == 0 } { 
    set array(DATE) [GetDate -format seconds]
    set array(JOB_STATUS) REPORTED
    return 
  }

  set array(JOB_STATUS) [DbGetJobData $job_id STATUS]
  set array(DATE) [DbGetJobData $job_id DATE]
  set array(PROGRAM_NAME)  [DbGetJobData $job_id TASKNAME]
  set array(TITLE) ""
  foreach word [DbGetJobData $job_id TITLE] { append array(TITLE) $word " " }
  set array(LOG_FILE) [DbGetJobData $job_id LOGFILE]

  set n 0; set files  [DbGetJobData $job_id INPUT_FILES]
  set dirs [DbGetJobData $job_id INPUT_FILES_DIR]
  foreach file $files {
    incr n; set array(INPUT_FILE,$n) $file
    set array(DIR_INPUT_FILE,$n)  [lindex $dirs [expr {$n -1}] ]
#    set array(INPUT_FILE_FORMAT,$n) ANY
  }
  set array(N_INPUT_FILES) $n

  set n 0; set files  [DbGetJobData $job_id OUTPUT_FILES]
  set dirs [DbGetJobData $job_id OUTPUT_FILES_DIR]
  foreach file $files {
    incr n; set array(OUTPUT_FILE,$n) $file
    set array(DIR_OUTPUT_FILE,$n)  [lindex $dirs [expr {$n -1}] ]
#    set array(OUTPUT_FILE_FORMAT,$n) ANY
  }
  set array(N_OUTPUT_FILES) $n

}

#---------------------------------------------------------------------------
proc DefFileName { job_id } {
#---------------------------------------------------------------------------
#d_sum Return the full path name of a def file in project database directory
#d_arg job_id Job id
  if { [regexp NO_DATABASE [GetProjectDatabase]] } { return "" }
  set taskname [DbGetJobData $job_id TASKNAME]
  set deffile [FileJoin [GetProjectDatabase] \
       [append name $job_id _ $taskname .def ] ]
  return $deffile
}

#-------------------------------------------------------------------------
proc DbArchiveExists { filename job_id } {
#-------------------------------------------------------------------------
#d_sum Look if there is archive file for filename
#d_desc An archive file is one that has been gzipped and move to the \
project database directory.  Return 0 (no archive file) or 1 (archive file exists)
#d_arg filename File name (NOT full path name)
#d_arg job_id Job id.

  set archive_file [FileJoin [GetProjectDatabase] \
                [append file $job_id _ [file tail $filename] ] ]

  if { [file exists $archive_file] } { return 1 }
  append archive_file ".gz" 
  if { [file exists $archive_file] } { return 1 }
  return 0
}

#-----------------------------------------------------------------------
proc DbArchiveFile { filename job_id { action {} } } {
#-----------------------------------------------------------------------
#d_sum Archive or restore a file
#d_desc Either archive or restore filename dependent on action
#d_desc return a status for the file:
#d_desc   "null"  can't find copy of file
#d_desc   "project"  file in project directory (i.e. file with name filename exists)
#d_desc   "archive"  archived version of file exists
#d_desc   "both"  both project and archive version of file exist
#d_arg filename Full path file name for file
#d_arg job_id Job id
#d_arg action Action required : 'archive' 'restore' or '' (do nothing)

  if { [GetProjectDatabase] == "" } {
    if { [file exists $filename ] } { 
      return "project" 
    } else {
      return "null"
    }
  }

  if { $action == "archive" && [file exists $filename] } {
    PleaseWait "..archiving $filename"
    set archive_file [ArchiveFileName $filename $job_id ]
    CopyFile $filename $archive_file
    CompressFile $archive_file
  }

  if { $action == "restore" } {
    PleaseWait "..restoring $filename"
    set archive_file [ArchiveFileName $filename  $job_id -ext]
    set t "";append t $filename "." [CompressExtension]
    CopyFile $archive_file $t
    UnCompressFile $t
  }
  
}

#--------------------------------------------------------------------
proc ArchiveFileName { filename job_id args } {
#--------------------------------------------------------------------
#d_sum Return the appropriate name for an archive file
#d_arg filename File name (can be full path name)
#d_arg job_id Job id
#d_opt0 -ext
#d_opt1 Append appropriate extension for compressed file

  set fileout [FileJoin [GetProjectDatabase] \
                [append file $job_id _ [file tail $filename] ] ]

  if { [lsearch $args ext] >= 0 } {
      append fileout "." [CompressExtension] 
  }
  return $fileout
}


#--------------------------------------------------------------------
proc db_job_has_notebook { job_id } {
#--------------------------------------------------------------------
#d_sum Check for existance of notebook entry for a job
#d_desc Return 1 if a notebook entry exists and 0 otherwise
#d_arg job_id Job id
  set file [DbGetNotebookFile $job_id ]
  if { [file exists $file] } {
    return 1
  } else {
    return 0
  }
}

#---------------------------------------------------------------------
proc db_edit_notebook { job_id } {
#---------------------------------------------------------------------
#d_sum Display & allow edit of the notebook for one job
#d_arg job_id Job id

  DbGetCurrentProject project
  set file [DbGetNotebookFile $job_id ]

  set db_display [list TASKNAME LOGFILE ]
  set db_display_format [list 40 80 ]

  if { ![file exists $file] } {
    if { [ OpenFile $file f ] == 1 } {
    puts $f "Notebook for $project job number $job_id"
    puts $f "Run on [GetDate -format full -clock [DbGetJobData $job_id DATE] ]"
    puts $f "[ DbJobDescription $project $job_id $db_display $db_display_format ]"
    puts $f "[ DbJobDescription $project $job_id TITLE 80]"
    }
    CloseFile $f
  }
  DisplayTextFile $file -edit
}

#--------------------------------------------------------------------------
proc DbMergeComFiles { job_id } {
#--------------------------------------------------------------------------
#d_sum Merge com files for a job so they can be displayed
#d_desc The  com files are the scripts which are input to the programs
#d_arg job_id Job id
  set nf 0
  set cmd "glob [FileJoin  [GetDefaultDirPath TEMPORARY] \
	  [GetCurrentProject]_[subst $job_id]_*_com.tmp ]"

  if { [catch $cmd tmp_file_list ] == 0 } {
    foreach tmp_file [lsort -command db_sort_tmpfiles $tmp_file_list ] {
      if { [regexp _com $tmp_file ] } {
        incr nf
        ReadFile $tmp_file f
        append ff "\n \n*******************************************************************
$tmp_file
*******************************************************************\n $f\n"
      }
    }
  }

  if { $nf > 0 } {
    set file [FileJoin [GetDefaultDirPath TEMPORARY] scripts_$job_id.tmp ]
    WriteFile $file $ff -overwrite
    return $file
  } else {
    Report 1 "No command script files found for job $job_id"
    return ""
  }
}

#----------------------------------------------------------------
proc db_sort_tmpfiles { f1 f2 } {
#----------------------------------------------------------------
#d_sum Comparison command for lsort in DbMergeComFiles
#d_desc See the Tcl documentation on lsort.
#d_arg f1,f2 The com file names
  set f1split [split $f1 _]
  set f2split [split $f2 _]
  set ind [expr {[llength $f1split] - 2}]

  if { [lindex $f1split $ind ] > [lindex $f2split $ind] } {
    return 1
  } else {
    return -1
  }
}

#--------------------------------------------------------------------------
proc DbKillJob { job_id } {
#--------------------------------------------------------------------------
#d_sum Kill a job whose current status is REMOTE or RUNNING
#d_desc Use the KillScript or KillRemoteScript prcedures in the local.tcl
#d_arg job_id Job id

  if { ![regexp {RUNNING|REMOTE} [DbGetJobData $job_id STATUS]] } { return }

# Get user to confirm
  if {[regexp Cancel [set action [ ChooseOptionDialog "Kill job" "Kill job"  \
   "Kill the job $job_id \
 [DbGetJobData $job_id TASKNAME] started at [GetDate -format brief -clock [DbGetJobData $job_id DATE]]
Also, optionally, delete any output files and remove from database?" \
    [list Cancel Kill Kill&Remove ] -default 1 -stop ] ] ]} { return }

# Handle local/remote
  switch [DbGetJobData $job_id STATUS] \
      RUNNING {
	  # If user has restarted ccp4i then it will have no record of job pid so
	  # will need to look at log file header
	  set pid {}
	  if { ![ReadLogPid $job_id pid] } {
	      WarningMessage "Sorry - cannot kill job\nCouldn't read process id from log file:\n\n[DbGetJobData $job_id LOGFILE]"
              return
          }
          if { [KillScript $pid] } { DbSetJobData $job_id STATUS KILLED }
      } REMOTE {
	  if { [KillRemoteScript $job_id] } { DbSetJobData $job_id STATUS KILLED }
      }
  if {[regexp Remove $action]} {
    # Check whether the archive window is currently in use
    if { [winfo exists ".archive"] } {
      # The archive window and the automatic removal share
      # the global "archive" array so they shouldn't be run
      # simultaneously
      WarningMessage "A \"Delete/Archive Files\" window is currently
active so it is not safe to remove the
output files and database record for this job.

You will need to use the \"Delete/Archive Files\" tool to
do this manually."
    } else {
      # First remove the output files
      db_removeoutput_handler $job_id
      # Now remove job record from the database
      db_cleanup_handler $job_id database
    }
  }
}

#--------------------------------------------------------------------------
proc DbStopJob { job_id } {
#--------------------------------------------------------------------------
#d_sum Not implemented - stop job cleanly after next program finish
  return ""
}

#----------------------------------------------------------------------------
proc db_view_session_log {} {
#----------------------------------------------------------------------------
#d_sum Display the session log file

  set logfile [GetSystemVar SESSION_LOG]

  if { $logfile == "" || ![file exists $logfile] } { 
    WarningMessage "No session log file found"
    return 0 
  }
  DisplayTextFile $logfile
}

#----------------------------------------------------------------------------
proc db_config_window { } {
#----------------------------------------------------------------------------
#d_sum Present a window for the user to configure the connection to the db
#d_desc This generates a window which gives the user information about the \
current configuation of CCP4i with respect to accessing the project database.
#d_desc In the case that CCP4i is connected to the database handler, it also \
monitors the status of the connection.

  global configure

  set w ".dbconfig"
  if { [winfo exists $w] } {
      raise $w
      return 0
  }

  DefineVariable dbconfig USING_DBCCP4I _logical [using_dbccp4i]
  DefineVariable dbconfig DBCCP4I_STATUS _logical 0
  DefineVariable dbconfig DBCCP4I_INFO _text "No information"
  DefineVariable dbconfig USE_DBCCP4I_ON_STARTUP _logical \
    $configure(USE_DBCCP4I_ON_STARTUP)

  OpenWindow $w "Configure Database Connection" "DB Config" \
      -help [SearchPath HELP general database.html ] -target "configuredb"

  CreateFrame $w dbconfig

  OpenFolder protocol

  # Subframe displaying information if the database server is in use
  OpenSubFrame frame -toggle_display USING_DBCCP4I open 1

  CreateLine line \
      label "Database access mode:" \
      label "Database server"

  $line.l1 config -width 22 -anchor e
  $line.l2 config -background $configure(COLOUR_BACKGROUND) \
      -relief raised -width 25

  CreateLine line \
      label "Connection status:" \
      label "Connected" \
      toggle_display DBCCP4I_STATUS open 1

  $line.l1 config -width 22 -anchor e
  $line.l2 config -background $configure(COLOUR_BACKGROUND) \
      -foreground "darkgreen" \
      -relief raised -width 25

  CreateLine line \
      label "Connection status:" \
      label "Not connected" \
      toggle_display DBCCP4I_STATUS open 0

  $line.l1 config -width 22 -anchor e
  $line.l2 config -background $configure(COLOUR_BACKGROUND) \
      -foreground "red" \
      -relief raised -width 25

  CreateLine line \
      label "Server info:" \
      varlabel DBCCP4I_INFO

  $line.l1 config -width 22 -anchor e
  $line.l2 config -background $configure(COLOUR_BACKGROUND) \
      -relief raised -width 25

  CloseSubFrame

  # Information if CCP4i is accessing the database directly
  CreateLine line \
      label "Database access mode:" \
      label "Direct access" \
      toggle_display USING_DBCCP4I open 0

  $line.l1 config -width 22 -anchor e
  $line.l2 config -background $configure(COLOUR_BACKGROUND) \
      -relief raised -width 25

  # Option to set the connection mode on startup
  CreateLine line \
    message "Turn off to use the direct access mode next time CCP4i starts" \
    widget USE_DBCCP4I_ON_STARTUP \
    -command "db_update_startup dbconfig USE_DBCCP4I_ON_STARTUP" \
    label "Connect to the database server when CCP4i starts up"

  CreateButton $w dismiss Dismiss "CloseWindow dbconfig -unset" -default

  if { [using_dbccp4i] } {
      db_monitor_connection dbconfig DBCCP4I_STATUS DBCCP4I_INFO
  }

  update_main_scroll $w
  return
}

#----------------------------------------------------------------------------
proc db_update_startup { arrayname startupVar } {
#----------------------------------------------------------------------------
#d_sum Update the user preference for database access mode on startup
#d_desc This sets the USE_DBCCP4I_ON_STARTUP parameter in configure to \
a new value specified by element startupVar in the array supplied by the \
calling procedure.
#d_desc The configure parameters are then saved to file and reloaded into \
the interface. The mode of database access isn't changed until the next \
time CCP4i is started.
#d_arg arrayname Name of the array used in the database configuration window
#d_arg startupVar Name of the parameter storing the user's startup preference
    global configure
    upvar \#0 $arrayname array

    set configure(USE_DBCCP4I_ON_STARTUP) $array($startupVar)
    SavePreferences configure configure
    WarningMessage "The change in database access mode
will take effect next time CCP4i starts."
    return
}

#----------------------------------------------------------------------------
proc db_monitor_connection { arrayname statusVar infoVar } {
#----------------------------------------------------------------------------
#d_sum Check and update the status of the connection in the db config window
#d_desc This is initially called from the database configuration window. \
Subsequently it calls itself periodically to update the status and \
information parameters, essentially monitoring the connection to the \
database server in real time.
#d_arg arrayname Name of the array used in the database configuration window
#d_arg statusVar Name of the parameter displaying the connection status
#d_arg infoVar Name of the parameter displaying the server information
  upvar \#0 $arrayname array
  if { [info exists array($statusVar)] } {
      if { [set array($statusVar) [dbccp4i_verify_connection]] } {
	  set array($infoVar) "[join [::dbClientAPI::DbInfo]]"
      } else {
	  set array($infoVar) "No information"
      }
      after 5000 "db_monitor_connection $arrayname $statusVar $infoVar"
  }
}

#d_index_title Autotest Utilities

#--------------------------------------------------------------------------------
proc DbAutotest { args } {
#--------------------------------------------------------------------------------
#d_sum Handle command line running of autotest

  global autotest

  InitialiseArray  [SearchPath TOP etc autotest.def] autotest autotest

  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
  switch -regexp -- [lindex $args $n] \
  project { 
    incr n; set autotest(TEST_PROJECT) [lindex $args $n]
  } target {
    incr n; set autotest(TARGET_DIR) [lindex $args $n]
  } first { 
    incr n; set autotest(FIRST_JOB) [lindex $args $n]
  } last {
    incr n; set autotest(LAST_JOB) [lindex $args $n]
  } machine {
    set autotest(IFREMOTE) 1
    incr n; set autotest(REMOTE_MACHINE) [lindex $args $n]
  }  exit {
    set autotest(EXIT) 1
  }
  incr n }

# Generate a default name from the date
  if { $autotest(TARGET_DIR) == {} } {
    regsub -all " " [GetDate -format date] _ autotest(TARGET_DIR) }

  if { $autotest(TEST_PROJECT) != "" } {
    if { ![DbChangeFile $autotest(TEST_PROJECT)] } { 
      puts "Error changing to project directory $autotest(TEST_PROJECT)"
      return 0 
    } else {
      puts "Changed to project [GetCurrentProject]"
    }
  }

  if { $autotest(LAST_JOB) == "" } { 
    set autotest(LAST_JOB) [DbGetNJOBS]
  }

  db_autotest_handler -nogr

}

#--------------------------------------------------------------------------------
proc db_autotest { } {
#--------------------------------------------------------------------------------
#d_sum Interface to automatic regression testing - rerun jobs in project
#d_desc the real work is done by db_autotest_handler

  global configure
  global autotest


  InitialiseArray  [SearchPath TOP etc autotest.def] \
               autotest autotest

  set autotest(LAST_JOB) [DbGetNJOBS]

  set w .autotest

  OpenWindow $w "Auto test CCP4I" "Autotest" \
             -help [SearchPath HELP general install.html ]

  CreateFrame  $w autotest

  CreateButton $w dismiss Dismiss "CloseWindow autotest"
  CreateButton $w action Run "db_autotest_handler; CloseWindow autotest"

  OpenFolder protocol

  CreateLine line               \
    message "New files will be output ot subdirectory of project directory" \
    label "Subdirectory name for output data" \
    widget TARGET_DIR 

  CreateLine line               \
    message "Rerun job range" \
    label "Rerun all jobs in range from job number" \
    widget FIRST_JOB \
    label to \
    widget LAST_JOB

  if { $configure(N_REMOTE_MACHINES) > 0 } {
    CreateLine line \
      message "Choose machine to run tests" \
      widget IFREMOTE  -toggleon \
      label "Run on machine" \
      widget REMOTE_MACHINE
  }

  update_main_scroll $w

}

#------------------------------------------------------------------------------
proc db_autotest_handler { args } {
#------------------------------------------------------------------------------
#d_sum  Automatic regression testing - rerun jobs in project
#d_desc Create a new project directory which is a sub-directory of the current \
project directory.  Create a new database directory and database.def.  \
Run all tasks in the project putting output files into the new project subdirectory.
#d_opt0 -nographics
#d_opt1 Running in command line (nographics) mode

  global autotest
  global configure

  set graphics 1
  if { [lsearch -regexp $args nogr] >= 0 } { set graphics 0 }
   
# OK Make sure we are not overwriting an existing target directory -
# Create new target directory and database etc.

  if { $autotest(TARGET_DIR) == "" } {
     WarningMessage "No proper directory name entered for target directory"
     return 0
  }

  if { $autotest(FIRST_JOB) < 1 || $autotest(LAST_JOB) >  [DbGetNJOBS] } {
    WarningMessage "ABORTING: Invalid range of job numbers to rerun"
    return 0
  }

  set work_dir [FileJoin [GetDefaultDirPath] $autotest(TARGET_DIR)]
  set project [GetCurrentProject]_$autotest(TARGET_DIR)

  set mode {}
  if { [file exists $work_dir] } {
    if {$graphics} {
       set mode [ChooseOptionDialog "Run Auto Test"  "Autotest" \
     		"The target directory $work_dir 
already exists.  Do you want to overwrite existing directory or abort" \
  	        [list Abort Continue Overwrite ]   ]
      } else { 
       set mode Overwrite
      }
    switch  $mode \
    Abort { 
      return 0 
    }  Overwrite {
# Hum - dangerous this 
     DeleteFile $work_dir 
    }
  }
  if { ![regexp Continue $mode ]  && ![CreateDir $work_dir] } {
    WarningMessage "ABORTING: Failed to create directory $work_dir"
    return 0
  }

  set olddb [GetDbDirPath]
  set newdb [GetDbDirPath $work_dir]

  if { ![CreateDir $newdb ] } {
    if { ![regexp Continue $mode ] } {
      WarningMessage "ABORTING: Failed to create directory \ $newdb"
      return 0
    }
  }

# Copy database.def file

  DbSaveFile $project $newdb -hold \
	-range $autotest(FIRST_JOB) $autotest(LAST_JOB)

# Change to the new project

  AddProject $project $work_dir
  set old_project [GetCurrentProject]
  DbChangeFile [GetCurrentProject]_$autotest(TARGET_DIR)
  DbUpdateList
  SaveDirectories


# Run through all jobs in the working project - update the def file to
# pick up and put files in the working project
# And execute each script

  set cmd "AutotestRunjob init $autotest(FIRST_JOB) $autotest(LAST_JOB) \
        $old_project $project"
  if {$autotest(IFREMOTE)} { append cmd " -remote $autotest(REMOTE_MACHINE)" }
  if {$autotest(EXIT)} { append cmd " -exit" }
  eval "$cmd"


}

#-------------------------------------------------------------------------
proc AutotestRunjob { mode job_id last_job old_project project args } {
#-------------------------------------------------------------------------
#d_sum Check status of automatic test jobs and start new job
#d_desc While the auto tests are running this procedure calls itself every \
couple of seconds and test if the current job is finished and if so then \
starts the next job
#d_arg mode	Mode is either 'init' for first time procedure is called \
or 'watch' thereafter
#d_arg job_id	The job id of the currently running job
#d_arg last_job	The id of the final job that the procedure is required to run.
#d_arg old_project	The project alias of the master project that is being rerun
#d_arg project	The project alias for the working project
#d_opt0 -exit
#d_opt1 Exit from ccp4i after completely the tests in this project
#d_opt0 -remote machine
#d_opt1 Run jobs on remote machine

  set ifexit 0
  set run_mode background
  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
    switch -regexp -- [lindex $args $n]  \
    exit {
      set ifexit 1
    } remote {
      incr n; set run_mode "remote [lindex $args $n]"
    } 
  incr n }

  if { ![regexp init $mode]  } {
#    puts "status [DbGetJobData $job_id STATUS]"
    if { ![regexp {FINISHED|FAILED|KILLED|ABORTED} [DbGetJobData $job_id STATUS] ] } {
      after 2000 [list AutotestRunjob watch $job_id $last_job $old_project $project $args]
      return 
    } else {
      while {  ![regexp ON_HOLD|RUNNING|REMOTE [DbGetJobData $job_id STATUS]] } {
        incr job_id
        if { $job_id > $last_job } { 
          if {$ifexit} { ExitInterface } else { return 1 } }
      }
    }
  }

#  OK were either in init mode or the last job has just finished
# So try running the next job

  if { [UpdateAutoTestDef $old_project $project $job_id $run_mode] } {
    set deffile [subst $job_id]_[DbGetJobData $job_id TASKNAME].def
    set scriptfile [SearchPath TOP scripts [DbGetJobData $job_id TASKNAME].script]
    set format tcl
    RunScript $run_mode $format $deffile $script_file $job_id
    DbSetJobData $job_id STATUS RUNNING
  } else {
    DbSetJobData $job_id STATUS ABORTED
  }
  after 2000 [list AutotestRunjob watch $job_id $last_job $old_project $project $args]

}


#--------------------------------------------------------------------------------------
proc UpdateAutoTestDef { old_project project job_id run_mode } {
#--------------------------------------------------------------------------------------
#d_sum Update the def file when running regression tests
#d_desc Change the directory aliases to that of the working project
#d_arg old_project	The project alias of the master project that is being rerun
#d_arg project	The project alias for the working project
#d_arg job_id The job id
#d_arg run_mode Set to 'remote' or 'background' - required to set the def file header
  global system
#
  global temp

#  puts "UpdateAutoTestDef old_project $old_project project $project"

  set taskname [DbGetJobData $job_id TASKNAME]
  set deffile [subst $job_id]_$taskname.def

  set olddef [FileJoin [GetDbDirPath $old_project] $deffile]
  set newdef [FileJoin [GetDbDirPath $project] $deffile]


  if { ![ReadFile $olddef deftext -split] } {
    WarningMessage "Cannot read old def file $olddef"
    return 0
  }

#  WarningMessage "olddef $olddef newdef $newdef status $status"

  set n 0; while { [regexp {^#CCP4I} [lindex $deftext $n]] }  {
    set line [lindex $deftext $n]
    set temp_params([lindex $line 1]) [lrange $line 2 end]
    incr n
  }

  InitialiseArray $olddef temp $taskname

  set in_files {}
  set in_dirs {}
  foreach filevar $temp(INPUT_FILES) {
    if { [StringSame $temp(DIR_$filevar) $old_project] &&
     [file exists [FileJoin [GetDefaultDirPath $project] $temp($filevar)]] } {
      set temp(DIR_$filevar) $project
    }
    append in_files $temp($filevar) " "
    append in_dirs $temp(DIR_$filevar) " "
  }
  set out_files {}
  set out_dirs {}
  foreach filevar $temp(OUTPUT_FILES) {
    if { [StringSame $temp(DIR_$filevar) $old_project TEMPORARY] } {
      set temp(DIR_$filevar) $project
    }
    append out_files $temp($filevar) " "
    append out_dirs $temp(DIR_$filevar) " "
  }
  DbSetJobData $job_id INPUT_FILES [string trimright $in_files]
  DbSetJobData $job_id INPUT_FILES_DIR [string trimright $in_dirs]
  DbSetJobData $job_id OUTPUT_FILES [string trimright $out_files]
  DbSetJobData $job_id OUTPUT_FILES_DIR [string trimright $out_dirs]

# Write the header to the script file
  switch -regexp -- $run_mode \
  remote {
    set ifremote 1
    set gui_host [GetHostname]
  } default {
    set ifremote 0
    set gui_host localhost
  }

  set header [WriteIdentifier {} "DEF $taskname" \
                JOB_ID $job_id \
                PROJECT $project \
                AUTOTEST $old_project \
                TASKNAME $taskname \
                LOG_FILE [subst $job_id]_$taskname.log \
                EDIT_SCRIPT 0 \
                HTML_LOG $temp_params(HTML_LOG) \
                REMOTE $ifremote \
                SERVER_HOST $gui_host \
                SERVER_PORT $system(SERVER_PORT) ]
#
  WriteFile $newdef $header

  SaveArray $taskname $newdef temp -silent -no_ident -append -notype

  unset temp
  unset temp_params
  return 1
}

#-----------------------------------------------------------
proc db_query_lock { project user time } {
#-----------------------------------------------------------
#d_sum Create a dialogue window for overriding database lock
#d_arg project Alias of project
#d_arg user Name of user who currently owns the lock
#d_arg time Time when the lock was created

    return [ ChooseOptionDialog "DatabaseLock" Lock \
"Each project database file can only be opened by one CCP4I at a time.

The database for project:
$project
was apparently already opened by $user at $time.

The lock may be left over from a previous run of the interface which did not terminate cleanly.

You can override the lock. Or you can continue without saving anything to the database." \
    [list "Exit CCP4I" "Continue" "Override Lock" ] -default 2 ]
}

#-----------------------------------------------------------------------
proc DbFlushCommandBuffer { project } {
#-----------------------------------------------------------------------
#d_sum Flush the command buffer and execute the commands
#d_desc Socket commands e.g. from running scripts which could not be \
executed immediately due to the main process being inaccessible, may \
be stored in a buffer file. DbFlushCommandBuffer flushes the buffer \
file and executes the commands using the "ccp4ish -socket" mechanism.
#d_arg project Project alias
    Report 1 "DbFlushCommandBuffer: flushing the command buffer for project $project"
    # First determine buffer file
    set bufferfile [DbGetBufferFile $project]
    Report 1 "DbFlushCommandBuffer: buffer file is $bufferfile"
    # Does it exist? If not then nothing to do
    if { ![file exists $bufferfile] } {
	Report 1 "DbFlushCommandBuffer: no command buffer found, nothing to do"
	return
    }
    # Read the file contents and destroy the file
    set buffer [open $bufferfile "r"]
    set commandbuffer [read -nonewline $buffer]
    close $buffer
    DeleteFile $bufferfile
    # Split the buffer content into a list of lines
    set commandlist [split $commandbuffer "\n"]
    # Execute each command in turn
    set full_line ""
    foreach line $commandlist {
	# A single command may be spread over a number of lines
	# so we need to make sure that the line is complete before
	# attempting to execute it
	append full_line $line
	if { [catch { llength $full_line } ] } {
	    append full_line " \n"
	} else {
	    Report 1 "DbFlushCommandBuffer: command is \"$full_line\""
	    if { [llength $full_line] != 3 } {
		Report 1 "DbFlushCommandBuffer: badly formatted buffer command, ignored"
	    } else {
		# Collect deffile and command
		set deffile [lindex $full_line 1]
		set command [lindex $full_line 2]
		# This is unsafe! but probably okay for a first attempt
		# Try executing the command through a ccp4ish invocation
		exec -- ccp4ish -socket "$deffile" "$command"
	    }
	    # Reset the line to blank to collect next command
	    set full_line ""
	}
    }
    return
}

#d_index_title Handling Delayed Execution of Buffered Commands

#-----------------------------------------------------------------------
proc DbGetBufferFile { project } {
#-----------------------------------------------------------------------
#d_sum Return the name of the database command buffer file
#d_desc Clone of GetBufferFile in execute.tcl
#d_arg project Alias for project
    return [FileJoin [GetDbDirPath $project] database.BUFFER]

}
