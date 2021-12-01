#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface modules_utils.tcl
#
#
#
# Utilities for reading and manipulating CCP4i modules files
#
# Peter Briggs Jun01
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities for building CCP4i modules data structure (src/modules_utils.tcl)
#d_intro Some utilities for constructing and interrogating the  task and \
module references used for building the module and tasklist display. \
BuildModulesDataStruct takes the data previously \
read in from a modules.def file and populates an internal data structure by \
calling the "Set" and "New" commands (SetModuleProject, NewModule, \
NewModuleSeparator etc). The commands in browser_utils.tcl which actually \
build the display use the "Get" and "List" commands (ListFolderContents, \
GetTaskDesc etc) to acquire the information needed to make modules, folders \
and task buttons.
#d_intro The internal data structure assigns a unique internal identifier to \
each task and folder at the point of generation. These unique identifiers are \
then used within the commands to access the data about the tasks and folders. \
Note that the identifiers may not be the same between different instances of \
the data structure.
#
#-------------------------------------------------------------------------
proc BuildModulesDataStruct { modulesVar arrayname } {
#-------------------------------------------------------------------------
#d_sum Build a data structure for the modules and tasklists
#d_desc The data in the modules.def file must previously have been loaded \
into the array specified by modulesVar (typically called moduledef).
#d_desc Based on this data, this command constructs an internal data \
structure that can later be easily queried and modified by calling a set of \
interface functions.
#d_arg modulesVar Name of the array containing previously loaded modules file
#d_arg arrayname Name of array to store the data structure in

  upvar #0 $modulesVar modules_data
  upvar #0 $arrayname array

  # Store project and title information
  SetModuleProject $arrayname $modules_data(PROJECT) $modules_data(TITLE)

  # Initialise a list of the internal unique ids for tasks
  # and folders
  set array(UNIQUE_IDS) {}

  # Build an internal data structure
  set nmodules $modules_data(N_MODULES)
  if { [lsearch [array names modules_data N_FOLDERS] N_FOLDERS] < 0 } {
      set nfolders 0
  } else {
      set nfolders $modules_data(N_FOLDERS)
  }
  set ntasks $modules_data(N_TASKS)
  foreach module $modules_data(MODULE_LIST) {
      if { $module == "" } {
	  # Add a separator
	  NewModuleSeparator $arrayname
	  continue
      }
      # Assume that it's a genuine module
      set module_task_list {}
      for { set i 1 } { $i <= $nmodules } { incr i } {
	  if { $modules_data(MODULE_NAME,$i) == $module } {
	      # Make a new module
	      NewModule $arrayname $modules_data(MODULE_NAME,$i) \
		  $modules_data(MODULE_TITLE,$i)
	      set module_task_list $modules_data(MODULE_TASK_LIST,$i)
	      break
	  }
      }
      # Add the folders and tasks
      foreach task $module_task_list {
	  # See if this "task" is actually a folder
	  set folder {}
	  for { set i 1 } { $i <= $nfolders } { incr i } {
	      if { $modules_data(FOLDER_TITLE,$i) == $task &&
		   $modules_data(FOLDER_MODULE,$i) == $module } {
		  # Add the folder
		  NewFolder $arrayname $modules_data(FOLDER_NAME,$i) \
		      $modules_data(FOLDER_TITLE,$i) \
		      $modules_data(FOLDER_DESCRIPT,$i) $module
		  set folder $modules_data(FOLDER_NAME,$i)
		  set folder_task_list $modules_data(FOLDER_TASK_LIST,$i)
		  # Add the tasks in the folder
		  foreach subtask $folder_task_list {
		      for { set j 1 } { $j <= $ntasks } { incr j } {
			  if { $modules_data(TASK_TITLE,$j) == $subtask } {
			      # Add the task
			      NewTask $arrayname $modules_data(TASK_NAME,$j) \
				  $modules_data(TASK_TITLE,$j) \
				  $modules_data(TASK_DESCRIPT,$j) \
				  $module $folder
			      break
			  }
		      }
		  }
		  # Done
		  break
	      }
	  }
	  if { $folder != "" } {
	      # A folder was found so skip looking up the tasks
	      continue
	  }
	  # Task is a top-level task
	  for { set i 1 } { $i <= $ntasks } { incr i } {
	      if { $modules_data(TASK_TITLE,$i) == $task } {
		  # Add the task
		  NewTask $arrayname $modules_data(TASK_NAME,$i) \
		      $modules_data(TASK_TITLE,$i) \
		      $modules_data(TASK_DESCRIPT,$i) \
		      $module
		  break
	      }
	  }
      }
  }
  # Sort the program list into alphabetical order, if it is present
  SortProgramList $arrayname
  # Finished
  return 1
}

#-------------------------------------------------------------------------
proc SortProgramList { arrayname } {
#-------------------------------------------------------------------------
#d_sum Sort the tasks in the program list module into alphabetical order
#d_desc Intended to be called after an internal data structure has been \
built. Uses the compare_task_titles function to perform the comparision \
of two tasks in the sorting.
#d_arg arrayname Name of array containing the data structure
    upvar \#0 $arrayname array
    if { [lsearch [ListModules $arrayname] programlist] < 0 } {
	# Program list not found
	return 1
    }
    set tasklist $array(MODULE_LIST_programlist)
    set newtasklist [lsort -command "compare_task_titles $arrayname" $tasklist]
    set array(MODULE_LIST_programlist) $newtasklist
    return 0
}

#-------------------------------------------------------------------------
proc compare_task_titles { arrayname taskid1 taskid2 } {
#-------------------------------------------------------------------------
#d_sum Internal - compare the titles of two tasks given their ids
#d_desc Used by SortProgramList. Acquires titles of tasks given their \
ids and returns return of "string compare".
#d_arg arrayname Name of array containing the data structure
#d_arg taskid1 Unique id for first task
#d_arg taskid2 Unique id for second task
    upvar \#0 $arrayname array
    set title1 [GetTaskTitle $arrayname $taskid1]
    set title2 [GetTaskTitle $arrayname $taskid2]
    return [string compare -nocase $title1 $title2]
}

#-------------------------------------------------------------------------
proc SetModuleProject { arrayname project title } {
#-------------------------------------------------------------------------
#d_sum Set the project name and title within the data structure
#d_arg arrayname Name of array containing the data structure
#d_arg project Project name (usually 'CCP4')
#d_arg title Title of application (usually 'CCP4 Program Interface')
    upvar \#0 $arrayname array
    set array(PROJECT) $project
    set array(TITLE) $title
}

#-------------------------------------------------------------------------
proc NewModule { arrayname name description } {
#-------------------------------------------------------------------------
#dsum Add a new module to the data structure
#d_arg arrayname Name of array containing the data structure
#d_arg name Internal name of the module (e.g. 'datred')
#d_arg description Description seen by the user (e.g. 'Data Reduction')
    upvar \#0 $arrayname array
    if { ![info exists array(MODULE_LIST)] } {
	# Create a new blank list
	set array(MODULE_LIST) {}
    } elseif { [lsearch $array(MODULE_LIST) $name] > -1 } {
	# Module already exists
	return 0
    }
    lappend array(MODULE_LIST) $name
    set array(MODULE_$name) $description
    set array(MODULE_LIST_$name) {}
    set array(MODULE_LIST_TYPE_$name) {}
    return 1
}

#-------------------------------------------------------------------------
proc NewModuleSeparator { arrayname } {
#-------------------------------------------------------------------------
#d_sum Add a "separator" into the module list
#d_arg arrayname Name of array to contain data structure
    upvar \#0 $arrayname array
    if { ![info exists array(MODULE_LIST)] } {
	# Create a new blank list
	set array(MODULE_LIST) {}
    }
    set name "<separator>"
    lappend array(MODULE_LIST) "$name"
    set array(MODULE_$name) "Separator"
    set array(MODULE_LIST_$name) {}
    set array(MODULE_LIST_TYPE_$name) {}
    return 1
}

#-------------------------------------------------------------------------
proc NewFolder { arrayname name title desc module  } {
#-------------------------------------------------------------------------
#d_sum Add a new folder to the data structure
#d_arg arrayname Name of array to contain data structure
#d_arg name Internal name of the folder
#d_arg title Text appearing on the folder title bar
#d_arg desc Extended description used e.g. for tooltip help message
#d_arg module Internal name of the module that holds the folder
    upvar \#0 $arrayname array
    if { ![info exists array(MODULE_LIST_$module)] } {
	# The module doesn't appear to have been created yet
	return 0
    }
    # Check if the folder already exists in this module
    foreach id $array(MODULE_LIST_$module) {
	if { [info exists array(FOLDER_TITLE_$id)] } {
	    if { [StringSame $array(FOLDER_TITLE_$id) $title] } {
		# The folder name is already defined in this
		# module - drop out
		return 0
	    }
	}
    }
    # Check for the existence of the folder name and
    # get a unique internal identifier
    if { [lsearch -exact $array(UNIQUE_IDS) $name] > -1 } {
	# Folder name is already assigned as an id
	# Generate a new unique id
	set i 1
	set folderid [subst $name]$i
	while { [lsearch -exact $array(UNIQUE_IDS) $folderid] > -1 } {
	    incr i
	    set folderid [subst $name]$i
	}
    } else {
	# Folder name can serve as a unique id as is
	set folderid $name
    }
    # Store the data
    lappend array(UNIQUE_IDS) $folderid
    set array(FOLDER_NAME_$folderid) $name
    set array(FOLDER_TITLE_$folderid) $title
    set array(FOLDER_DESC_$folderid) $desc
    set array(MODULE_[subst $module]_FOLDER_LIST_$folderid) {}
    set array(MODULE_[subst $module]_FOLDER_STATUS_$folderid) "CLOSED"
    lappend array(MODULE_LIST_$module) $folderid
    lappend array(MODULE_LIST_TYPE_$module) "FOLDER"
    return 1
}

#-------------------------------------------------------------------------
proc NewTask { arrayname taskname title description module { folder "" } } {
#-------------------------------------------------------------------------
#d_sum Add a new task to the data structure
#d_arg arrayname Name of array to contain data structure
#d_arg taskname Internal name of the task (e.g. root of Tcl task file)
#d_arg title Text to appear as task title on button
#d_arg description Extended description used e.g. for tooltip help message
#d_arg module Internal name of the module that the task is in
#d_arg folder (optional) Internal name of the folder that the task is in
    upvar \#0 $arrayname array
    if { ![info exists array(MODULE_LIST_$module)] } {
	# The module doesn't appear to have been created yet
	return 0
    }
    # Check for the existence of the taskname and
    # get a unique internal identifier
    if { [lsearch -exact $array(UNIQUE_IDS) $taskname] > -1 } {
	# Taskname is already assigned as an id
	# Generate a new unique id
	set i 1
	set taskid [subst $taskname]$i
	while { [lsearch -exact $array(UNIQUE_IDS) $taskid] > -1 } {
	    incr i
	    set taskid [subst $taskname]$i
	}
    } else {
	# Taskname can serve as a unique id as is
	set taskid $taskname
    }
    # Store the data
    lappend array(UNIQUE_IDS) $taskid
    set array(TASK_NAME_$taskid) $taskname
    set array(TASK_TITLE_$taskid) $title
    set array(TASK_DESC_$taskid) $description
    if { $folder == "" } {
	# No folder
	lappend array(MODULE_LIST_$module) $taskid
	lappend array(MODULE_LIST_TYPE_$module) "TASK"
    } else {
	# We need to identify the folder's internal id
	set got_folder 0
	foreach id $array(MODULE_LIST_$module) {
	    if { [info exists array(FOLDER_NAME_$id)] } {
		if { [StringSame $array(FOLDER_NAME_$id) $folder] } {
		    # Located the folder name
		    set got_folder 1
		    break
		}
	    }
	}
	if { $got_folder } {
	    # Add the task to the folder
	    lappend array(MODULE_[subst $module]_FOLDER_LIST_$id) $taskid
	    return 1
	} else {
	    # Failed to locate the requested folder
	    return 0
	}
    }
}

#-------------------------------------------------------------------------
proc SetFolderVisibility { arrayname module folder status } {
#-------------------------------------------------------------------------
#d_sum Set the visibility of the folder contents
#d_arg arrayname Name of array to contain data structure
#d_arg module Internal name of the module that the task is in
#d_arg folder Internal name of the folder
#d_arg status Can be set to either OPEN or CLOSED
    upvar \#0 $arrayname array
    foreach id $array(MODULE_LIST_$module) {
	if { [info exists array(FOLDER_NAME_$id)] } {
	    if { $array(FOLDER_NAME_$id) == $folder } {
		set array(MODULE_[subst $module]_FOLDER_STATUS_$id) $status
		return
	    }
	}
    }
}

#-------------------------------------------------------------------------
proc GetFolderVisibility { arrayname module folder } {
#-------------------------------------------------------------------------
#d_sum Return the visibility of the folder contents
#d_desc Returns either OPEN or CLOSED, or UNKNOWN if the folder isn't found
#d_arg arrayname Name of array to contain data structure
#d_arg module Internal name of the module that the task is in
#d_arg folder Internal name of the folder
    upvar \#0 $arrayname array
    foreach id $array(MODULE_LIST_$module) {
	if { [info exists array(FOLDER_NAME_$id)] } {
	    if { $array(FOLDER_NAME_$id) == $folder } {
		return $array(MODULE_[subst $module]_FOLDER_STATUS_$id)
	    }
	}
    }
    # Unknown
    return "UNKNOWN"
}   

#-------------------------------------------------------------------------
proc ListModules { arrayname } {
#-------------------------------------------------------------------------
#d_sum List the modules in the data structure
#d_arg arrayname Name of array to contain data structure
    upvar \#0 $arrayname array
    return $array(MODULE_LIST)
}

#-------------------------------------------------------------------------
proc GetModuleDesc { arrayname module } {
#-------------------------------------------------------------------------
#d_sum Return the description string for the module name
#d_arg arrayname Name of array to contain data structure
#d_arg module  Internal name of the module
    upvar \#0 $arrayname array
    return $array(MODULE_$module)
}

#-------------------------------------------------------------------------
proc ReverseLookupModuleName { arrayname desc } {
#-------------------------------------------------------------------------
#d_sum Given the module description, find the matching name
#d_desc Attempts to locate the internal module name given the text \
description. Returns the name, or an empty string if no match is found.
#d_arg arrayname Name of array to contain data structure
#d_arg desc  Description text to be matched
    foreach module [ListModules $arrayname] {
	if { [GetModuleDesc $arrayname $module] == $desc } {
	    return $module
	}
    }
    return ""
}

#-------------------------------------------------------------------------
proc ListModuleContents { arrayname module } {
#-------------------------------------------------------------------------
#d_sum Return a list of the module contents
#d_desc Returns a list of the unique internal ids for the tasks and \
folders in the module.
#d_arg arrayname Name of array containing the data structure
#d_arg module Internal module name
    upvar \#0 $arrayname array
    # Return the list of unique ids for tasks and folders
    return $array(MODULE_LIST_$module)
}

#-------------------------------------------------------------------------
proc ListFolderContents { arrayname module folder } {
#-------------------------------------------------------------------------
#d_sum Return a list of the module contents
#d_desc Returns a list of the unique internal ids for the tasks in \
the folder.
#d_arg arrayname Name of array containing the data structure
#d_arg module Internal module name
#d_arg folder Internal folder name (unique id)
    upvar \#0 $arrayname array
    # Return the list of unique ids for the tasks
    return $array(MODULE_[subst $module]_FOLDER_LIST_$folder)
}

#-------------------------------------------------------------------------
proc GetContentType { arrayname module name } {
#-------------------------------------------------------------------------
#d_sum Return the type (FOLDER or TASK) for the module content
#d_arg arrayname Name of array to contain data structure
#d_arg module Internal module name
#d_arg name Task or folder name for which type is requested
    upvar \#0 $arrayname array
    if { [info exists array(TASK_NAME_$name)] } {
	return "TASK"
    } elseif { [info exists array(FOLDER_NAME_$name)] } {
	return "FOLDER"
    } else {
	return "UNKNOWN"
    }
}

#-------------------------------------------------------------------------
proc GetFolderTitle { arrayname folderid } {
#-------------------------------------------------------------------------
#d_sum Return the title string for a folder in a module
#d_arg arrayname Name of array containing the data structure
#d_arg folderid Internal unique folder id
    upvar \#0 $arrayname array
    if { [info exists array(FOLDER_TITLE_$folderid)] } {
	return $array(FOLDER_TITLE_$folderid)
    }
    return ""
}

#-------------------------------------------------------------------------
proc GetFolderDesc { arrayname folderid } {
#-------------------------------------------------------------------------
#d_sum Return the description string for a folder in a module
#d_arg arrayname Name of array containing the data structure
#d_arg folderid Internal unique folder id
    upvar \#0 $arrayname array
    if { [info exists array(FOLDER_DESC_$folderid)] } {
	return $array(FOLDER_DESC_$folderid)
    }
    return ""
}

#-------------------------------------------------------------------------
proc GetTaskName { arrayname taskid } {
#-------------------------------------------------------------------------
#d_sum Return the taskname for a task id
#d_arg arrayname Name of array to contain data structure
#d_arg taskid Internal taskname (unique id)
    upvar \#0 $arrayname array
    if { [info exists array(TASK_NAME_$taskid)] } {
	return $array(TASK_NAME_$taskid)
    }
    return ""
}

#-------------------------------------------------------------------------
proc GetTaskTitle { arrayname taskid } {
#-------------------------------------------------------------------------
#d_sum Return the title string for a task
#d_arg arrayname Name of array to contain data structure
#d_arg taskid Internal taskname (unique id)
    upvar \#0 $arrayname array
    if { [info exists array(TASK_TITLE_$taskid)] } {
	return $array(TASK_TITLE_$taskid)
    }
    return ""
}

#-------------------------------------------------------------------------
proc GetTaskDesc { arrayname taskid } {
#-------------------------------------------------------------------------
#d_sum Return the description string for a task
#d_arg arrayname Name of array to contain data structure
#d_arg taskid Internal taskname (unique id)
    upvar \#0 $arrayname array
    if { [info exists array(TASK_DESC_$taskid)] } {
	return $array(TASK_DESC_$taskid)
    }
    return ""
}

#d_index_title Utilities for manipulating CCP4i modules.def files (src/modules_utils.tcl)
#d_intro Some utilities for adding and removing task and module references.
#
#-------------------------------------------------------------------------
proc InitialiseModulesArray { modules_file arrayname } {
#-------------------------------------------------------------------------
#d_sum Initialise an array with the data in a modules.def file
#d_desc This is a wrapper for InitialiseArray which first loads parameters \
from the template modules.def file, to ensure that all expected parameters \
are initialised. It then loads the actual data from the file specified by \
the calling subprogram.
#d_arg modules_file Full path for the module file to be loaded
#d_arg arrayname Name of the array to store the data in
    upvar \#0 $arrayname array
    InitialiseArray [SearchPath TOP etc modules.def.dist] \
	$arrayname modules -nocheck
    InitialiseArray $modules_file $arrayname modules -nocheck
}

#-------------------------------------------------------------------------
proc GetModuleList { modules_file } {
#-------------------------------------------------------------------------
#d_sum Return a list of the modules in the specified modules def file
#d_desc This procedure returns a list of modules found in the modules.def \
file. Each element of the list is itself a list of two elements, the first \
being the internal name of the module, and the second being the module \
title as seen by the user. Note that this procedure can \
read information from either a .def style modules file, or from the old-style \
flat ascii format modules file.
#d_arg module_file Full path for the module file to be examined
  global getmodulelist_array

  if { ![file exists $modules_file] } {
      return ""
  } elseif { ![file isfile $modules_file] } {
      return ""
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file getmodulelist_array

  # Check to see if it is a .def file, or an old-style ascii file
  if { [info exists getmodulelist_array(N_MODULES)] } {
      #
      # .def file
      set nmodules $getmodulelist_array(N_MODULES)
      if {$nmodules == 0} {
	  unset getmodulelist_array
	  return ""
      }
      set master_list $getmodulelist_array(MODULE_LIST)
      foreach module_name $master_list {
	  for {set i 1} {$i <= $nmodules} {incr i} {
	      if { [string match $module_name $getmodulelist_array(MODULE_NAME,$i)] } {
		  lappend module_list [list $getmodulelist_array(MODULE_NAME,$i) \
			  $getmodulelist_array(MODULE_TITLE,$i)]
	      }
	  }
      }
  } else {
      #
      # old-style ascii file
      ReadFile $modules_file filetext -split -noblank
      foreach line $filetext {
	  if { [regexp -- "^MODULE" $line] } {
	      set linelength [llength $line]
	      if { $linelength > 1 } {
		  set module_name [lindex $line 1]
	      } else {
		  set module_name ""
	      }
	      if { $linelength > 2 } {
		  set module_title [lrange $line 2 end]
	      } else {
		  set module_title ""
	      }
	      lappend module_list [list $module_name $module_title]
	  }   
      }
  }
  unset getmodulelist_array
  return $module_list
}

#-------------------------------------------------------------------------
proc GetTaskList { modules_file module_name } {
#-------------------------------------------------------------------------
#d_sum Return a list of the tasks in the specified module of a modules def file
#d_desc This procedure returns a list with each element representing a task \
in the specified module. Each element of the list is itself a list of three \
items, representing the task title (text seen on the task browser buttons), \
task name (corresponding to the task file), and the task description (text \
appearing in the task browser message line). Note that this procedure can \
read information from either a .def style modules file, or from the old-style \
flat ascii format modules file.
#d_desc Note that if the module also contains folders then the names of the \
folders will also be returned in the list of "tasks". Therefore GetTaskList \
is now deprecated in favour of GetModuleContentList, which returns the same \
data with an additional flag indicating whether the entry is a task or a \
folder.
#d_arg module_file Full path for the module file to be examined
#d_arg module_name The name or title of the module to be examined
  global gettasklist_array

  if { ![file exists $modules_file] } {
      return ""
  } elseif { ![file isfile $modules_file] } {
      return ""
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file gettasklist_array

  # Check to see if it is a .def file, or an old-style ascii file
  if { [info exists gettasklist_array(N_MODULES)] } {
      #
      # .def file
      set nmodules $gettasklist_array(N_MODULES)
      if {$nmodules == 0} {
	  unset gettasklist_array
	  return ""
      }
      # Find the requested module
      set thismodule 0
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $gettasklist_array(MODULE_NAME,$i)] || \
		  [string match $module_name $gettasklist_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
      if {$thismodule == 0} {
	  unset gettasklist_array
	  return ""
      }
      set nam_module $gettasklist_array(MODULE_NAME,$thismodule)

      # Compile a list of tasks
      set task_list ""
      set ntasks $gettasklist_array(N_TASKS)
      foreach tasktitle $gettasklist_array(MODULE_TASK_LIST,$thismodule) {
	  for {set i 1} {$i <= $ntasks} {incr i} {
	      if {[string match $tasktitle $gettasklist_array(TASK_TITLE,$i)] && \
		      [lsearch -exact $gettasklist_array(TASK_MODULE,$i) $nam_module] \
		      > -1 } {
		  lappend task_list \
			  [list $gettasklist_array(TASK_TITLE,$i) \
			  $gettasklist_array(TASK_NAME,$i) \
			  $gettasklist_array(TASK_DESCRIPT,$i) ]
	      }
	  }
      }
  } else {
      #
      # old-style ascii file
      ReadFile $modules_file filetext -split -noblank
      set thismodule 0
      set taskline   0
      foreach line $filetext {
	  # Go through the file contents line by line
	  # Ignore comments, PROJECT and TITLE lines
	  if { ![regexp -- "^#" $line] && \
		  ![regexp -- "^TITLE" $line] && \
		  ![regexp -- "^PROJECT" $line] } {
	      if { [regexp -- "^MODULE" $line] } {
		  # Found a line starting with MODULE
		  set linelength [llength $line]
		  if { $linelength > 1 } {
		      set nam_module [lindex $line 1]
		  } else {
		      set nam_module ""
		  }
		  if { $linelength > 2 } {
		      set module_title [lrange $line 2 end]
		  } else {
		      set module_title ""
		  }
		  # Is this the requested module?
		  if { "$nam_module" == "$module_name" || \
			  "$module_title" == "$module_name" } {
		      set thismodule 1
		  } else {
		      set thismodule 0
		  }
	      } else {
		  # This must be a task reference
		  if { $thismodule == 1 } {
		      if { $taskline == 0 } {
			  # First line - two entries
			  set task_name [lindex $line 0]
			  set task_title [lrange $line 1 end]
			  incr taskline
		      } elseif { $taskline == 1 } {
			  # Second line
			  set task_descript [string trim $line]
			  # Add to the list of tasks
			  lappend task_list [list $task_title $task_name $task_descript]
			  set taskline 0
		      }
		  }
	      }
	  }
      }
      # End of reading from old-style modules file
  }
  unset gettasklist_array
  return $task_list
}

#-------------------------------------------------------------------------
proc GetModuleContentList { modules_file module_name } {
#-------------------------------------------------------------------------
#d_sum Return a list of the items (tasks and folders) in the specified module
#d_desc This procedure returns a list with each element representing a task or \
folder in the specified module. Each element of the list is itself a list of four \
items, representing the task/folder title (text seen on the task browser buttons \
or in the folder title bar), task or folder name (corresponding to the task file, \
or to the internal id name of the folder), the task or folder description (text \
appearing in the task browser message line), and the word TASK or FOLDER \
(indicating whether the item is a task or folder). Note that this procedure can \
read information from either a .def style modules file, or from the old-style \
flat ascii format modules file.
#d_desc Note that only modules.def files can contain folders.
#d_arg module_file Full path for the module file to be examined
#d_arg module_name The name or title of the module to be examined
  global getcontentlist_array

  if { ![file exists $modules_file] } {
      return ""
  } elseif { ![file isfile $modules_file] } {
      return ""
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file getcontentlist_array

  # Check to see if it is a .def file, or an old-style ascii file
  if { [info exists getcontentlist_array(N_MODULES)] } {
      #
      # .def file
      set nmodules $getcontentlist_array(N_MODULES)
      if {$nmodules == 0} {
	  unset getcontentlist_array
	  return ""
      }
      # Find the requested module
      set thismodule 0
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $getcontentlist_array(MODULE_NAME,$i)] || \
		  [string match $module_name $getcontentlist_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
      if {$thismodule == 0} {
	  unset getcontentlist_array
	  return ""
      }
      set nam_module $getcontentlist_array(MODULE_NAME,$thismodule)

      # Compile a list of items (tasks and folders)
      set item_list ""
      set ntasks $getcontentlist_array(N_TASKS)
      set nfolders $getcontentlist_array(N_FOLDERS)
      foreach title $getcontentlist_array(MODULE_TASK_LIST,$thismodule) {
	  set matched 0
	  # Check if it's a folder
	  for {set i 1} {$i <= $nfolders} {incr i} {
	      if {[string match $title $getcontentlist_array(FOLDER_TITLE,$i)] && \
		      [lsearch -exact $getcontentlist_array(FOLDER_MODULE,$i) $nam_module] \
		      > -1 } {
		  lappend item_list \
			  [list $getcontentlist_array(FOLDER_TITLE,$i) \
			  $getcontentlist_array(FOLDER_NAME,$i) \
			  $getcontentlist_array(FOLDER_DESCRIPT,$i) \
			  "FOLDER" ]
		  set matched 1
		  break
	      }
	  }
	  if { $matched } {
	      # Don't bother looking in the list of tasks
	      continue
	  }
	  # Check for tasks
	  for {set i 1} {$i <= $ntasks} {incr i} {
	      if {[string match $title $getcontentlist_array(TASK_TITLE,$i)] && \
		      [lsearch -exact $getcontentlist_array(TASK_MODULE,$i) $nam_module] \
		      > -1 } {
		  lappend item_list \
		      [list $getcontentlist_array(TASK_TITLE,$i) \
			   $getcontentlist_array(TASK_NAME,$i) \
			   $getcontentlist_array(TASK_DESCRIPT,$i) \
			  "TASK" ]
		  break
	      }
	  }
      }
  } else {
      #
      # old-style ascii file
      ReadFile $modules_file filetext -split -noblank
      set thismodule 0
      set taskline   0
      foreach line $filetext {
	  # Go through the file contents line by line
	  # Ignore comments, PROJECT and TITLE lines
	  if { ![regexp -- "^#" $line] && \
		  ![regexp -- "^TITLE" $line] && \
		  ![regexp -- "^PROJECT" $line] } {
	      if { [regexp -- "^MODULE" $line] } {
		  # Found a line starting with MODULE
		  set linelength [llength $line]
		  if { $linelength > 1 } {
		      set nam_module [lindex $line 1]
		  } else {
		      set nam_module ""
		  }
		  if { $linelength > 2 } {
		      set module_title [lrange $line 2 end]
		  } else {
		      set module_title ""
		  }
		  # Is this the requested module?
		  if { "$nam_module" == "$module_name" || \
			  "$module_title" == "$module_name" } {
		      set thismodule 1
		  } else {
		      set thismodule 0
		  }
	      } else {
		  # This must be a task reference
		  if { $thismodule == 1 } {
		      if { $taskline == 0 } {
			  # First line - two entries
			  set task_name [lindex $line 0]
			  set task_title [lrange $line 1 end]
			  incr taskline
		      } elseif { $taskline == 1 } {
			  # Second line
			  set task_descript [string trim $line]
			  # Add to the list of tasks
			  lappend item_list \
			      [list $task_title $task_name $task_descript "TASK"]
			  set taskline 0
		      }
		  }
	      }
	  }
      }
      # End of reading from old-style modules file
  }
  unset getcontentlist_array
  return $item_list
}

#-------------------------------------------------------------------------
proc GetFolderContentList { modules_file module_name folder_name } {
#-------------------------------------------------------------------------
#d_sum Return a list of the tasks in the specified folder of a module
#d_desc This procedure returns a list with each element representing a task in \
the specified folder and module. Each element of the list is itself a list of \
three items, representing the task title (text seen on the task browser buttons), \
task name (corresponding to the task file), and the task description (text \
appearing in the task browser message line). Note that this procedure can \
read information from either a .def style modules file, or from the old-style \
flat ascii format modules file.
#d_desc Note that only modules.def files can contain folders.
#d_arg module_file Full path for the module file to be examined
#d_arg module_name The name or title of the module to be examined
#d_arg folder_name The name or title of the folder to be examined
  global getcontentlist_array

  if { ![file exists $modules_file] } {
      return ""
  } elseif { ![file isfile $modules_file] } {
      return ""
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file getcontentlist_array

  # Check to see if it is a .def file, or an old-style ascii file
  if { [info exists getcontentlist_array(N_MODULES)] } {
      #
      # .def file
      set nmodules $getcontentlist_array(N_MODULES)
      if {$nmodules == 0} {
	  unset getcontentlist_array
	  return ""
      }
      # Find the requested module
      set thismodule 0
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $getcontentlist_array(MODULE_NAME,$i)] || \
		  [string match $module_name $getcontentlist_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
      if {$thismodule == 0} {
	  unset getcontentlist_array
	  return ""
      }
      set nam_module $getcontentlist_array(MODULE_NAME,$thismodule)

      # Find the folder
      set nfolders $getcontentlist_array(N_FOLDERS)
      set thisfolder 0
      for {set i 1} {$i <= $nfolders} {incr i} {
	  if {[string match $folder_name $getcontentlist_array(FOLDER_TITLE,$i)] || \
		  [string match $folder_name $getcontentlist_array(FOLDER_NAME,$i)] } {
	      if { [string match $getcontentlist_array(FOLDER_MODULE,$i) \
			$nam_module] || \
		       [string match $getcontentlist_array(FOLDER_MODULE,$i) \
			    $module_name] } {
		  set thisfolder $i
	      }  
	  }
      }
      # If we didn't find the folder then return empty list
      if { $thisfolder == 0 } {
	  unset getcontentlist_array
	  return {}
      }
      
      # Make a list of tasks
      set task_list {}
      set ntasks $getcontentlist_array(N_TASKS)
      foreach title $getcontentlist_array(FOLDER_TASK_LIST,$thisfolder) {
	  for {set i 1} {$i <= $ntasks} {incr i} {
	      if {[string match $title $getcontentlist_array(TASK_TITLE,$i)] && \
		      [lsearch -exact $getcontentlist_array(TASK_MODULE,$i) $nam_module] \
		      > -1 } {
		  lappend task_list \
		      [list $getcontentlist_array(TASK_TITLE,$i) \
			   $getcontentlist_array(TASK_NAME,$i) \
			   $getcontentlist_array(TASK_DESCRIPT,$i) ]
		  break
	      }
	  }
      }
  } else {
      #
      # old-style ascii file
      # This doesn't support folders so return an empty list
      set task_list {}
  }
  unset getcontentlist_array
  return $task_list
}

#-------------------------------------------------------------------------
proc AddModule { modules_file module_name module_title args } {
#-------------------------------------------------------------------------
#d_sum Add a new module reference to the specified modules def file
#d_desc Adds a new module reference to a modules def file, and overwrites \
with the new version. The new module will be empty when created, and by \
default is added to the end of the list of modules. Returns 1 on success, \
0 on an error (e.g. modules file not found, module name or title already exists).
#d_arg module_file Full path for the module file to be edited
#d_arg module_name Name of the new module
#d_arg module_title Title of the module (text which appears in the list of \
modules as seen by the user)
#d_opt0 -before module_title
#d_opt1 Add the new module before the named module, if possible
#d_opt0 -after module_title
#d_opt1 Add the new module after the named module, if possible
#d_opt0 -first
#d_opt1 Add as the first module
#d_opt0 -last
#d_opt1 Add as the last module
  global addmodule_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  # Process any additional arguments
  set first  0
  set last   0
  set before 0
  set after  0
  set nargs [llength $args]
  if { $nargs > 0 } {
      set option [lindex $args 0]
      switch -- $option {
	  -before {
	      if { $nargs > 1 } {
		  set nb_module [lindex $args 1]
		  set before 1
	      }
	  }
	  -after {
	      if { $nargs > 1 } {
		  set nb_module [lindex $args 1]
		  set after 1
	      }
	  }
	  -first {
	      set first 1
	  }
	  -last {
	      set last 1
	  }
      }
  } else {
      set last 1
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file addmodule_array
  
  # Check that the module name or title are not already being used
  set nmodules $addmodule_array(N_MODULES)
  set newmodule 1
  if {$nmodules > 0} {
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $addmodule_array(MODULE_NAME,$i)] || \
		  [string match $module_title $addmodule_array(MODULE_TITLE,$i)] } {
	      set newmodule 0
	  }
      }
  }
  # Check that the name is not already in the list of modules
  if { [lsearch -exact $addmodule_array(MODULE_LIST) $module_name] > -1 } {
      unset addmodule_array
      return 0
  }

  # Add the new module
  if {$newmodule == 1} {
      incr nmodules
      set addmodule_array(MODULE_NAME,$nmodules) $module_name
      set addmodule_array(MODULE_TITLE,$nmodules) $module_title
      set addmodule_array(MODULE_TASK_LIST,$nmodules) ""
      set addmodule_array(N_MODULES) $nmodules
  }

  # Make sure it is in the correct place
  # Before or after a particular module
  if { $before || $after } {
      set i [lsearch -exact $addmodule_array(MODULE_LIST) $nb_module]
      if { $i > -1} {
	  if { $after } { incr i }
	  set addmodule_array(MODULE_LIST) \
		  [linsert $addmodule_array(MODULE_LIST) $i $module_name]
      } else {
	  set last 1
      }
  }
  # Right at the start
  if { $first } {
      set addmodule_array(MODULE_LIST) \
	      [linsert $addmodule_array(MODULE_LIST) 0 $module_name]
  }
  # Right at the end
  if { $last } {
      lappend addmodule_array(MODULE_LIST) $module_name
  }
  
  # Save to file
  SaveArray modules $modules_file addmodule_array -save_types

  unset addmodule_array
  return 1
}

#-------------------------------------------------------------------------
proc GetModule { modules_file module } {
#-------------------------------------------------------------------------
#d_sum Fetch the attributes of a particular module reference
#d_desc Get the details of a module from a modules.def file, \
specifically the name and title.
#d_desc On success this command returns a list of two elements: the \
module name, and the module title. On failure an empty list is returned.
#d_arg modules_file Full path for the module file to be queried
#d_arg module Name or title of the module reference to be queried
  global getmodule_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file getmodule_array

  # Find the specified module reference
  set nmodules $getmodule_array(N_MODULES)
  if {$nmodules > 0} {
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module $getmodule_array(MODULE_NAME,$i)] || \
		   [string match $module $getmodule_array(MODULE_TITLE,$i)] } {
	      # Located a match - return the information
	      set module_name  $getmodule_array(MODULE_NAME,$i)
	      set module_title $getmodule_array(MODULE_TITLE,$i)
	      unset getmodule_array
	      return [list $module_name $module_title]
	  }
      }
  }
  # Finished - unable to find the module
  unset getmodule_array
  return {}
}

#-------------------------------------------------------------------------
proc UpdateModule { modules_file module_name new_title } {
#-------------------------------------------------------------------------
#d_sum Change the module title text
#d_arg module_files Full path for the module file to be edited
#d_arg module_name  Name of the module to be updated
#d_arg new_title    Text to be used as new module title
  global updatemodule_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file updatemodule_array

  # Find the specified module reference
  set nmodules $updatemodule_array(N_MODULES)
  set thismodule 0
  if {$nmodules > 0} {
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $updatemodule_array(MODULE_NAME,$i)] || \
		  [string match $module_name $updatemodule_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
  }
  if { $thismodule == 0 } {
      unset updatemodule_array
      return 0
  }

  # Overwrite the old text with the new
  set updatemodule_array(MODULE_TITLE,$thismodule) $new_title

  # Save to file
  SaveArray modules $modules_file updatemodule_array -save_types

  unset updatemodule_array
  return 1
}

#-------------------------------------------------------------------------
proc DeleteModule { modules_file module_name } {
#-------------------------------------------------------------------------
#d_sum Remove a module reference from the specified modules def file
#d_desc Delete a module from the module def file. This will only work if \
there are no task references currently in the module.
#d_arg module_files Full path for the module file to be edited
#d_arg module_name Name of the module to be removed
  global delmodule_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file delmodule_array

  # Find the specified module reference
  set nmodules $delmodule_array(N_MODULES)
  set thismodule 0
  if {$nmodules > 0} {
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $delmodule_array(MODULE_NAME,$i)] || \
		  [string match $module_name $delmodule_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
  }
  if { $thismodule == 0 } {
      unset delmodule_array
      return 0
  }

  # Fail if the module is not empty
  if { [llength $delmodule_array(MODULE_TASK_LIST,$thismodule)] > 0 } {
      unset delmodule_array
      return 0
  }

  # Remove the module reference
  set nam_module $delmodule_array(MODULE_NAME,$thismodule)
  if {$thismodule != $nmodules} {
      set delmodule_array(MODULE_NAME,$thismodule) \
	      $delmodule_array(MODULE_NAME,$nmodules)
      set delmodule_array(MODULE_TITLE,$thismodule) \
	      $delmodule_array(MODULE_TITLE,$nmodules)
      set delmodule_array(MODULE_TASK_LIST,$thismodule) \
	      $delmodule_array(MODULE_TASK_LIST,$nmodules)
  }
  unset delmodule_array(MODULE_NAME,$nmodules)
  unset delmodule_array(MODULE_TITLE,$nmodules)
  unset delmodule_array(MODULE_TASK_LIST,$nmodules)
  incr  delmodule_array(N_MODULES) -1

  # Remove from the list of modules
  set thismodule [lsearch -exact $delmodule_array(MODULE_LIST) $nam_module]
  if { $thismodule < 0 } {
      unset delmodule_array
      return 0
  }
  set delmodule_array(MODULE_LIST) [lreplace $delmodule_array(MODULE_LIST) \
	  $thismodule $thismodule ]

  # Save  to file
  SaveArray modules $modules_file delmodule_array -save_types

  unset delmodule_array
  return 1
}

#-------------------------------------------------------------------------
proc AddTaskReference { modules_file task_title task_name task_descript module_name args } {
#-------------------------------------------------------------------------
#d_sum Add a new task reference to the specified modules file
#d_desc Creates a new task reference in a particular module, and optionally \
within a subfolder.
#d_desc Note that if a folder is specified but doesn't exist then the task \
reference will be added as a "top-level" task in the module. In all cases, \
if the module doesn't exist then the task reference will not be added at all.
#d_arg module_file Full path for the modules file to be edited
#d_arg task_title Title of the task (text which appears in the list of \
modules as seen by the user)
#d_arg task_name Name of the task (must correspond to a .tcl file in the \
tasks directory)
#d_arg task_descript Description of the task (text which appears in the \
message line of the main window)
#d_arg module_name Module to which the task should be added
#d_opt0 -folder folder_name
#d_opt1 Add the new task reference within the named folder, if possible
#d_opt0 -before task_title
#d_opt1 Add the new task reference before the named task, if possible
#d_opt0 -after task_title
#d_opt1 Add the new task reference after the named task, if possible
#d_opt0 -first
#d_opt1 Add as the first task reference in the specified module
#d_opt0 -last
#d_opt1 Add as the last task reference in the specified module
  global addtask_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  # Process any additional arguments
  set first  0
  set last   1
  set before 0
  set after  0
  set folder 0
  set nargs [llength $args]
  for { set i 0 } { $i < $nargs } { incr i } {
      set option [lindex $args $i]
      switch -- $option {
          -folder {
	      incr i
	      if { $i < $nargs } {
		  set folder_name [lindex $args $i]
		  set folder 1
	      }
	  }
	  -before {
	      incr i
	      if { $i < $nargs } {
		  set nb_task [lindex $args $i]
		  set before 1
		  set last 0
	      }
	  }
	  -after {
	      incr i
	      if { $i < $nargs } {
		  set nb_task [lindex $args $i]
		  set after 1
		  set last 0
	      }
	  }
	  -first {
	      set first 1
	      set last 0
	  }
	  -last {
	      set last 1
	  }
      }
  }

  # Load the current values
  InitialiseModulesArray $modules_file addtask_array
  
  # Check that the specified module exists
  set nmodules $addtask_array(N_MODULES)
  if {$nmodules == 0} {
      return 0
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      if { [string match $module_name $addtask_array(MODULE_NAME,$i)] } {
	  set thismodule $i
          break
      }
  }
  # Couldn't find the module name
  if {$thismodule == 0} {
      unset addtask_array
      return 0
  }

  # If a folder was specified then check that this also exists
  set thisfolder 0
  if { $folder } {
      set nfolders $addtask_array(N_FOLDERS)
      for { set i 1 } { $i <= $nfolders } { incr i } {
          if { [string match $folder_name $addtask_array(FOLDER_NAME,$i)] && \
	       [string match $module_name $addtask_array(FOLDER_MODULE,$i)]} {
	      set thisfolder $i
	      break
	  }
      }
      # Couldn't find the folder in this module
      if {$thisfolder == 0} {
         set folder 0
      }
  }

  # Check that the task title is not already being used in this module
  if { ! $folder } {
      # Top-level task
      if { [lsearch -exact $addtask_array(MODULE_TASK_LIST,$thismodule) $task_title] \
           > -1 } {
          # Title already registered for this module
          unset addtask_array
          return 0
      }
  } else {
      # Task in a folder
      if { [lsearch -exact $addtask_array(FOLDER_TASK_LIST,$thisfolder) $task_title] \
           > -1 } {
          # Title already registered for this folder
          unset addtask_array
          return 0
      }
  }

  # Add the new task reference to the list of tasks
  set ntasks $addtask_array(N_TASKS)
  incr ntasks
  set addtask_array(TASK_TITLE,$ntasks) $task_title
  set addtask_array(TASK_NAME,$ntasks) $task_name
  set addtask_array(TASK_MODULE,$ntasks) $module_name
  set addtask_array(TASK_DESCRIPT,$ntasks) $task_descript
  set addtask_array(N_TASKS) $ntasks
  
  # Add to the list of tasks for the specified module
  # Make sure it is in the correct place

  if { ! $folder } {
      # Top-level task
      # Before or after a particular task or folder
      if { $before || $after } {
          set i [lsearch -exact $addtask_array(MODULE_TASK_LIST,$thismodule) $nb_task]
          if { $i > -1} {
	      if { $after } { incr i }
	      set addtask_array(MODULE_TASK_LIST,$thismodule) \
		  [linsert $addtask_array(MODULE_TASK_LIST,$thismodule) \
		       $i $task_title]
	  } else {
	      set last 1
	  }
      }
      # Right at the start
      if { $first } {
         set addtask_array(MODULE_TASK_LIST,$thismodule) \
               [linsert $addtask_array(MODULE_TASK_LIST,$thismodule) 0 $task_title]
      }
      # Right at the end
      if { $last } {
         lappend addtask_array(MODULE_TASK_LIST,$thismodule) $task_title
      }
  } else {
      # Task in a subfolder
      # Before or after a particular task
      if { $before || $after } {
          set i [lsearch -exact $addtask_array(FOLDER_TASK_LIST,$thisfolder) $nb_task]
          if { $i > -1} {
	      if { $after } { incr i }
	      set addtask_array(FOLDER_TASK_LIST,$thisfolder) \
		  [linsert $addtask_array(FOLDER_TASK_LIST,$thisfolder) \
		       $i $task_title]
	  } else {
	      set last 1
	  }
      }
      # Right at the start
      if { $first } {
         set addtask_array(FOLDER_TASK_LIST,$thisfolder) \
               [linsert $addtask_array(FOLDER_TASK_LIST,$thisfolder) 0 $task_title]
      }
      # Right at the end
      if { $last } {
         lappend addtask_array(FOLDER_TASK_LIST,$thisfolder) $task_title
      }
  }

  # Save to file
  SaveArray modules $modules_file addtask_array -notype

  unset addtask_array
  return 1
}

#-------------------------------------------------------------------------
proc AddModuleFolder { modules_file folder_title folder_name folder_descript module_name args } {
#-------------------------------------------------------------------------
#d_sum Add a new folder to the specified modules file
#d_desc Creates a new folder reference in a particular module.
#d_arg module_file Full path for the modules file to be edited
#d_arg folder_title Title of the folder (text which appears in the list of \
modules as seen by the user)
#d_arg folder_name Name of the folder (must be unique)
#d_arg task_descript Description of the folder (text which appears in the \
message line of the main window)
#d_arg module_name Module to which the folder should be added
#d_opt0 -before task_or_folder
#d_opt1 Add the new folder before the named task or folder, if possible
#d_opt0 -after task_or_folder
#d_opt1 Add the new folder after the named task or folder, if possible
#d_opt0 -first
#d_opt1 Add as the first entry in the specified module
#d_opt0 -last
#d_opt1 Add as the last entry in the specified module
  global addfolder_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  # Process any additional arguments
  set first  0
  set last   0
  set before 0
  set after  0
  set nargs [llength $args]
  if { $nargs > 0 } {
      set option [lindex $args 0]
      switch -- $option {
	  -before {
	      if { $nargs > 1 } {
		  set nb_entry [lindex $args 1]
		  set before 1
	      }
	  }
	  -after {
	      if { $nargs > 1 } {
		  set nb_entry [lindex $args 1]
		  set after 1
	      }
	  }
	  -first {
	      set first 1
	  }
	  -last {
	      set last 1
	  }
      }
  } else {
      set last 1
  }

  # Load the current values
  InitialiseModulesArray $modules_file addfolder_array
  
  # Check that the specified module exists
  set nmodules $addfolder_array(N_MODULES)
  if {$nmodules == 0} {
      return 0
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      if { [string match $module_name $addfolder_array(MODULE_NAME,$i)] } {
	  set thismodule $i
      }
  }
  # Couldn't find the module name
  if {$thismodule == 0} {
      unset addfolder_array
      return 0
  }
  # Check that the folder name is unique
  set nfolders $addfolder_array(N_FOLDERS)
  for { set i 1 } { $i <= $nfolders } { incr i } {
      if { $folder_name == $addfolder_array(FOLDER_NAME,$i) } {
	  # Name is already in use
	  ##puts "Folder name \"$folder_name\" already defined"
	  unset addfolder_array
	  return 0
      }
      if { $folder_title == $addfolder_array(FOLDER_TITLE,$i) && \
	   $module_name == $addfolder_array(FOLDER_MODULE,$i) } {
	  # Folder title already is in use in this module
	  ##puts "Folder title \"$folder_title\" already exists in module \"$module_name\""
	  unset addfolder_array
	  return 0
      }
  }

  # Add the new folder to the list of folders
  set nfolders $addfolder_array(N_FOLDERS)
  incr nfolders
  set addfolder_array(FOLDER_TITLE,$nfolders) $folder_title
  set addfolder_array(FOLDER_NAME,$nfolders) $folder_name
  set addfolder_array(FOLDER_MODULE,$nfolders) $module_name
  set addfolder_array(FOLDER_DESCRIPT,$nfolders) $folder_descript
  set addfolder_array(FOLDER_TASK_LIST,$nfolders) {}
  set addfolder_array(N_FOLDERS) $nfolders
  
  # Add to the list of tasks & folders for the specified module
  # Make sure it is in the correct place

  # Before or after a particular task/folder
  if { $before || $after } {
      set i [lsearch -exact $addfolder_array(MODULE_TASK_LIST,$thismodule) $nb_entry]
      if { $i > -1} {
	  if { $after } { incr i }
	  set addfolder_array(MODULE_TASK_LIST,$thismodule) \
		  [linsert $addfolder_array(MODULE_TASK_LIST,$thismodule) \
		  $i $folder_title]
      } else {
	  set last 1
      }
  }
  # Right at the start
  if { $first } {
      set addfolder_array(MODULE_TASK_LIST,$thismodule) \
	      [linsert $addfolder_array(MODULE_TASK_LIST,$thismodule) 0 $folder_title]
  }
  # Right at the end
  if { $last } {
      lappend addfolder_array(MODULE_TASK_LIST,$thismodule) $folder_title
  }

  # Save to file
  SaveArray modules $modules_file addfolder_array -notype

  unset addfolder_array
  return 1
}

#-------------------------------------------------------------------------
proc GetFolderReference { modules_file folder module_name } {
#-------------------------------------------------------------------------
#d_sum Fetch the attributes of a particular folder reference
#d_desc Get the details of a folder reference from a modules.def file, \
specifically the name, title and description.
#d_desc On success this command returns a list of three elements: the \
folder name, the folder title and the folder description text. On failure \
an empty list is returned.
#d_arg modules_file Full path for the module file to be queried
#d_arg folder Name or title of the folder reference to be queried
#d_arg module_name Name of the module in which the folder reference resides
  global getfolder_array

  if { ![file exists $modules_file] } {
      return {}
  } elseif { ![file isfile $modules_file] } {
      return {}
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file getfolder_array
  
  # Check that the specified module exists
  set nmodules $getfolder_array(N_MODULES)
  if {$nmodules == 0} {
      # No modules
      unset getfolder_array
      return {}
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      # Locate the parent module
      if { [string match $module_name $getfolder_array(MODULE_NAME,$i)] } {
	  set thismodule $i
      }
  }
  # Couldn't find the module name - return
  if {$thismodule == 0} {
      unset getfolder_array
      return {}
  }

  # Locate the folder in the list of folders
  set nfolders $getfolder_array(N_FOLDERS)
  if {$nfolders == 0} {
      unset getfolder_array
      return {}
  }
  for {set i 1} {$i <= $nfolders} {incr i} {
      if { [string match $folder $getfolder_array(FOLDER_TITLE,$i) ] || \
	       [string match $folder $getfolder_array(FOLDER_NAME,$i) ] } {
	  if { [string match $getfolder_array(FOLDER_MODULE,$i) \
		    $getfolder_array(MODULE_NAME,$thismodule)] } {
	      # Found a match
	      # Return the information
	      set folder_name $getfolder_array(FOLDER_NAME,$i)
	      set folder_title $getfolder_array(FOLDER_TITLE,$i)
	      set folder_desc $getfolder_array(FOLDER_DESCRIPT,$i)
	      # Finished
	      unset getfolder_array
	      return [list $folder_name $folder_title $folder_desc]
	  }
      }
  }
  # Couldn't find the folder
  unset getfolder_array
  return {}
}

#-------------------------------------------------------------------------
proc UpdateFolderReference { modules_file folder_title module_name args } {
#-------------------------------------------------------------------------
#d_sum Update the attributes of a particular task reference
#d_arg modules_file Full path for the module file to be edited
#d_arg folder_title Name of the folder reference to be updated
#d_arg module_name Name of the module in which the folder reference resides
#d_opt0 -title title_text
#d_opt1 New title text to replace the existing title
#d_opt0 -descript descript_text
#d_opt1 New description text to replace the existing description
  global updatefolder_array

  #puts "Started UpdateFolderReference: args = $args"

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  #puts "$modules_file exists and is a file"

  # Check for arguments
  set title_text ""
  set descript_text ""
  set nargs [llength $args]
  if {$nargs == 0} { return 0 }
  for {set i 0} {$i< $nargs} {incr i} {
      set option [lindex $args $i]
      if {[string match $option "-title"]} {
	  incr i
	  if {$i < $nargs} {
	      set title_text [lindex $args $i]
	  } else {
	      return 0
	  }
      } elseif {[string match $option "-descript"]} {
	  incr i
	  if {$i < $nargs} {
	      set descript_text [lindex $args $i]
	  } else {
	      return 0
	  }
      } else {
	  return 0
      }
  }

  #puts "Title = $title_text"
  #puts "Description = $descript_text"
    
  # Load the current values
  InitialiseModulesArray $modules_file updatefolder_array
  
  # Check that the specified module exists
  set nmodules $updatefolder_array(N_MODULES)
  if {$nmodules == 0} {
      #puts "No modules"
      unset updatefolder_array
      return 0
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      #puts "Checking module $updatefolder_array(MODULE_NAME,$i)"
      if { [string match $module_name $updatefolder_array(MODULE_NAME,$i)] } {
	  set thismodule $i
      }
  }
  # Couldn't find the module name
  if {$thismodule == 0} {
      #puts "Couldn't find module $module_name"
      unset updatefolder_array
      return 0
  }

  # Locate the folder in the list of folders
  set nfolders $updatefolder_array(N_FOLDERS)
  if {$nfolders == 0} {
      unset updatefolder_array
      return 0
  }
  set thisfolder 0
  for {set i 1} {$i <= $nfolders} {incr i} {
      if { [string match $folder_title $updatefolder_array(FOLDER_TITLE,$i) ] || \
	       [string match $folder_title $updatefolder_array(FOLDER_NAME,$i) ] } {
	  if { [string match $updatefolder_array(FOLDER_MODULE,$i) \
		    $updatefolder_array(MODULE_NAME,$thismodule)] } {
	      set thisfolder $i
	  }
      }
  }
  # Couldn't find the folder
  if {$thisfolder == 0} {
      #puts "Couldn't find folder $folder_title"
      unset updatefolder_array
      return 0
  }
  # Locate in the tasklist for this module
  set folder_mod \
      [lsearch $updatefolder_array(MODULE_TASK_LIST,$thismodule) \
	   $updatefolder_array(FOLDER_TITLE,$thisfolder)]
  if { $folder_mod < 0 } {
      #puts "Couldn't find folder $updatefolder_array(FOLDER_TITLE,$thisfolder) (#2)"
      unset updatefolder_array
      return 0
  }
  # Update the values
  if { [IfSet $title_text] } {
      set updatefolder_array(FOLDER_TITLE,$thisfolder) $title_text
      # Update the title in the list of tasks for this module
      set updatefolder_array(MODULE_TASK_LIST,$thismodule) \
	  [lreplace $updatefolder_array(MODULE_TASK_LIST,$thismodule) \
	       $folder_mod $folder_mod $title_text]
  }
  if { [IfSet $descript_text] } {
      set updatefolder_array(FOLDER_DESCRIPT,$thisfolder) $descript_text
  }

  # Save to file
  SaveArray modules $modules_file updatefolder_array -save_types

  unset updatefolder_array
  return 1
}

#-------------------------------------------------------------------------
proc DeleteModuleFolder { modules_file module_name folder_name } {
#-------------------------------------------------------------------------
#d_sum Remove a folder from the specified modules def file
#d_desc Delete a folder from the specified module in a module def file. \
This will only work if there are no task references currently in the folder.
#d_arg module_files Full path for the module file to be edited
#d_arg module_name Name of the module to be removed
#d_arg folder_name Name of the folder to be removed
  global delfolder_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }
    
  # Load the current values
  InitialiseModulesArray $modules_file delfolder_array

  # Find the specified module
  set nmodules $delfolder_array(N_MODULES)
  set thismodule 0
  if {$nmodules > 0} {
      for {set i 1} {$i <= $nmodules} {incr i} {
	  if { [string match $module_name $delfolder_array(MODULE_NAME,$i)] || \
		  [string match $module_name $delfolder_array(MODULE_TITLE,$i)] } {
	      set thismodule $i
	  }
      }
  }
  if { $thismodule == 0 } {
      puts "Couldn't locate module $module_name"
      unset delfolder_array
      return 0
  }

  # Find the specified folder
  set thisfolder 0
  set n_folders $delfolder_array(N_FOLDERS)
  for { set i 1 } { $i <= $n_folders } { incr i } {
      if { $folder_name == $delfolder_array(FOLDER_TITLE,$i) || \
	       $folder_name == $delfolder_array(FOLDER_NAME,$i) } {
	  if { $delfolder_array(FOLDER_MODULE,$i) == \
		   $delfolder_array(MODULE_NAME,$thismodule) } {
	      # Located the folder
	      set thisfolder $i
	      break
	  }
      }
  }
  # Couldn't find the folder in the module
  if {$thisfolder == 0} {
      unset delfolder_array
      return 0
  }

  # Fail if the folder is not empty
  if { [llength $delfolder_array(FOLDER_TASK_LIST,$thisfolder)] > 0 } {
      unset delfolder_array
      return 0
  }

  # Remove the folder from the task list for the module
  if { [set i [lsearch $delfolder_array(MODULE_TASK_LIST,$thismodule) \
		   $delfolder_array(FOLDER_TITLE,$thisfolder)]] > -1 } {
      set delfolder_array(MODULE_TASK_LIST,$thismodule) \
	  [lreplace $delfolder_array(MODULE_TASK_LIST,$thismodule) $i $i ]
  }

  # Remove the folder reference
  if {$thisfolder != $n_folders} {
      set delfolder_array(FOLDER_NAME,$thisfolder) \
	      $delfolder_array(FOLDER_NAME,$n_folders)
      set delfolder_array(FOLDER_TITLE,$thisfolder) \
	      $delfolder_array(FOLDER_TITLE,$n_folders)
      set delfolder_array(FOLDER_TASK_LIST,$thisfolder) \
	      $delfolder_array(FOLDER_TASK_LIST,$n_folders)
      set delfolder_array(FOLDER_DESCRIPT,$thisfolder) \
	      $delfolder_array(FOLDER_DESCRIPT,$n_folders)
      set delfolder_array(FOLDER_MODULE,$thisfolder) \
	      $delfolder_array(FOLDER_MODULE,$n_folders)
  }
  unset delfolder_array(FOLDER_NAME,$n_folders)
  unset delfolder_array(FOLDER_TITLE,$n_folders)
  unset delfolder_array(FOLDER_TASK_LIST,$n_folders)
  unset delfolder_array(FOLDER_DESCRIPT,$n_folders)
  unset delfolder_array(FOLDER_MODULE,$n_folders)
  incr  delfolder_array(N_FOLDERS) -1

  # Save  to file
  SaveArray modules $modules_file delfolder_array -save_types

  unset delfolder_array
  return 1
}

#-------------------------------------------------------------------------
proc UpdateTaskReference { modules_file task_title module_name args } {
#-------------------------------------------------------------------------
#d_sum Update the attributes of a particular task reference
#d_arg modules_file Full path for the module file to be edited
#d_arg task_title Name of the task reference to be updated
#d_arg module_name Name of the module in which the task reference resides
#d_opt0 -title title_text
#d_opt1 New title text to replace the existing title
#d_opt0 -descript descript_text
#d_opt1 New description text to replace the existing description
#d_opt0 -folder folder_name
#d_opt1 Specify the folder that the task reference is currently in
  global updatetask_array

  #puts "Started UpdateTaskReference: args = $args"

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  #puts "$modules_file exists and is a file"

  # Check for arguments
  set title_text ""
  set descript_text ""
  set folder_name ""
  set nargs [llength $args]
  if {$nargs == 0} { return 0 }
  for {set i 0} {$i< $nargs} {incr i} {
      set option [lindex $args $i]
      if {[string match $option "-title"]} {
	  incr i
	  if {$i < $nargs} {
	      set title_text [lindex $args $i]
	  } else {
	      return 0
	  }
      } elseif {[string match $option "-descript"]} {
	  incr i
	  if {$i < $nargs} {
	      set descript_text [lindex $args $i]
	  } else {
	      return 0
	  }
      } elseif {[string match $option "-folder"]} {
	  incr i
	  if {$i < $nargs} {
	      set folder_name [lindex $args $i]
	  } else {
	      return 0
	  }
      } else {
	  return 0
      }
  }

  #puts "Title = $title_text"
  #puts "Description = $descript_text"
  #puts "Folder = $folder_name"
    
  # Load the current values
  InitialiseModulesArray $modules_file updatetask_array
  
  # Check that the specified module exists
  set nmodules $updatetask_array(N_MODULES)
  if {$nmodules == 0} {
      #puts "No modules"
      unset updatetask_array
      return 0
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      #puts "Checking module $updatetask_array(MODULE_NAME,$i)"
      if { [string match $module_name $updatetask_array(MODULE_NAME,$i)] } {
	  set thismodule $i
      }
  }
  # Couldn't find the module name
  if {$thismodule == 0} {
      #puts "Couldn't find module $module_name"
      unset updatetask_array
      return 0
  }

  # Check the folder, if supplied
  if { $folder_name != "" } {
      set nfolders $updatetask_array(N_FOLDERS)
      if {$nfolders == 0} {
	  unset updatetask_array
	  return 0
      }
      set thisfolder 0
      for {set i 1} {$i <= $nfolders} {incr i} {
	  if { [string match $folder_name $updatetask_array(FOLDER_NAME,$i) ] || \
		   [string match $folder_name $updatetask_array(FOLDER_TITLE,$i)] } {
		       if { [string match $updatetask_array(FOLDER_MODULE,$i) \
				 $updatetask_array(MODULE_NAME,$thismodule)] } {
			   set thisfolder $i
		       }
	  }
      }
      # Couldn't find the folder
      if {$thisfolder == 0} {
	  #puts "Couldn't find folder $folder_name"
	  unset updatetask_array
	  return 0
      }
  }

  # Check the task is registered for this module (and folder)
  if { $folder_name == "" } {
      set task_mod \
	  [lsearch -exact $updatetask_array(MODULE_TASK_LIST,$thismodule) $task_title]
      if { $task_mod < 0 } {
	  #puts "Couldn't find $task_title registered in module $module_name ($thismodule)"
	  unset updatetask_array
	  return 0
      }
  } else {
      set task_mod \
	  [lsearch -exact $updatetask_array(FOLDER_TASK_LIST,$thisfolder) $task_title]
      if { $task_mod < 0 } {
	  #puts "Couldn't find $task_title registered in folder $folder_name ($thisfolder)"
	  unset updatetask_array
	  return 0
      }
  }

  # Find the specified task reference in the list of tasks
  set ntasks $updatetask_array(N_TASKS)
  set thistask 0
  if {$ntasks > 0} {
      for {set i 1} {$i <= $ntasks} {incr i} {
	  if { [string match $task_title $updatetask_array(TASK_TITLE,$i)] && \
		  [lsearch -exact $updatetask_array(TASK_MODULE,$i) \
		  $module_name] > -1 } {
	      set thistask $i
	  }
      }
  }
  # Can't find it? This is an error but ignore for now
  if { $thistask == 0 } {
      #puts "Couldn't find data for $task_title"
      unset updatetask_array
      return 0
  }

  # Update the values
  if { [IfSet $title_text] } {
      set updatetask_array(TASK_TITLE,$thistask) $title_text
  }
  if { [IfSet $descript_text] } {
      set updatetask_array(TASK_DESCRIPT,$thistask) $descript_text
  }

  # Update the title in the list of tasks for this module or folder
  if { $folder_name == "" } {
      set updatetask_array(MODULE_TASK_LIST,$thismodule) \
	  [lreplace $updatetask_array(MODULE_TASK_LIST,$thismodule) \
	       $task_mod $task_mod $title_text]
  } else {
      set updatetask_array(FOLDER_TASK_LIST,$thisfolder) \
	  [lreplace $updatetask_array(FOLDER_TASK_LIST,$thisfolder) \
	       $task_mod $task_mod $title_text]
  }

  # Save to file
  SaveArray modules $modules_file updatetask_array -save_types

  unset updatetask_array
  return 1
}

#-------------------------------------------------------------------------
proc DeleteTaskReference { modules_file task_title module_name { folder_title {} } } {
#-------------------------------------------------------------------------
#d_sum Remove a task reference from the specified modules def file
#d_arg modules_file Full path for the module file to be edited
#d_arg task_title Name of the task reference to be deleted
#d_arg module_name Name of the module from which the task is to be removed
#d_arg folder_title (Optional) Title of the folder within the module from which \
the task is to be removed
  global deltask_array

  if { ![file exists $modules_file] } {
      return 0
  } elseif { ![file isfile $modules_file] } {
      return 0
  }

  # Load the current values
  InitialiseModulesArray $modules_file deltask_array
  
  # Check that the specified module exists
  set nmodules $deltask_array(N_MODULES)
  if {$nmodules == 0} {
      unset deltask_array
      return 0
  }
  set thismodule 0 
  for {set i 1} {$i <= $nmodules} {incr i} {
      if { [string match $module_name $deltask_array(MODULE_NAME,$i)] } {
	  set thismodule $i
      }
  }
  # Couldn't find the module name
  if {$thismodule == 0} {
      unset deltask_array
      return 0
  }
  # Check it is registered for this module
  if { $folder_title == "" } {
      # Task is not in a folder
      if { [lsearch -exact $deltask_array(MODULE_TASK_LIST,$thismodule) $task_title] \
	       < 0 } {
	  unset deltask_array
	  return 0
      }
  } else {
      # Task should be in a folder
      # Check that the folder exists in the module
      set thisfolder 0
      set n_folders $deltask_array(N_FOLDERS)
      for { set i 1 } { $i <= $n_folders } { incr i } {
	  if { $folder_title == $deltask_array(FOLDER_TITLE,$i) && \
		   $deltask_array(FOLDER_MODULE,$i) == \
		   $deltask_array(MODULE_NAME,$thismodule) } {
	      # Located the folder
	      set thisfolder $i
	      break
	  }
      }
      # Couldn't find the folder in the module
      if {$thisfolder == 0} {
	  unset deltask_array
	  return 0
      }
      # Check that the task is in this folder
      if { [lsearch $deltask_array(FOLDER_TASK_LIST,$thisfolder) $task_title] < 0 } {
	  unset deltask_array
	  return 0
      }
  }

  # Find the specified task reference in the list of tasks
  set ntasks $deltask_array(N_TASKS)
  set thistask 0
  if {$ntasks > 0} {
      for {set i 1} {$i <= $ntasks} {incr i} {
	  if { [string match $task_title $deltask_array(TASK_TITLE,$i)] && \
		  [lsearch -exact $deltask_array(TASK_MODULE,$i) \
		  $module_name] > -1 } {
	      set thistask $i
	  }
      }
  }
  # Can't find it? This is an error but ignore for now
  if { $thistask == 0 } {
      unset deltask_array
      return 0
  }

  # Remove the task reference
  if {$thistask != $ntasks} {
      set deltask_array(TASK_TITLE,$thistask) $deltask_array(TASK_TITLE,$ntasks)
      set deltask_array(TASK_NAME,$thistask) $deltask_array(TASK_NAME,$ntasks)
      set deltask_array(TASK_MODULE,$thistask) $deltask_array(TASK_MODULE,$ntasks)
      set deltask_array(TASK_DESCRIPT,$thistask) $deltask_array(TASK_DESCRIPT,$ntasks)
  }
  unset deltask_array(TASK_TITLE,$ntasks)
  unset deltask_array(TASK_NAME,$ntasks)
  unset deltask_array(TASK_MODULE,$ntasks)
  unset deltask_array(TASK_DESCRIPT,$ntasks)
  incr  deltask_array(N_TASKS) -1

  # Remove from the list of tasks in the folder or module, as appropriate
  if { $folder_title != "" } {
      # Remove from the list of tasks in the folder
      set thistask [lsearch -exact $deltask_array(FOLDER_TASK_LIST,$thisfolder) \
			$task_title]
      if { $thistask < 0 } {
	  unset deltask_array
	  return 0
      }
      set deltask_array(FOLDER_TASK_LIST,$thisfolder) \
	  [lreplace $deltask_array(FOLDER_TASK_LIST,$thisfolder) $thistask $thistask ]
  } else {
      # Remove from the list of tasks in the module
      set thistask [lsearch -exact $deltask_array(MODULE_TASK_LIST,$thismodule) \
			$task_title]
      if { $thistask < 0 } {
	  unset deltask_array
	  return 0
      }
      set deltask_array(MODULE_TASK_LIST,$thismodule) \
	  [lreplace $deltask_array(MODULE_TASK_LIST,$thismodule) $thistask $thistask ]
  }

  # Save to file
  SaveArray modules $modules_file deltask_array -notype

  unset deltask_array
  return 1

}
