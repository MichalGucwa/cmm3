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
# edit_modules.tcl --
#
# Interface for user to edit the modules.def file
#
# CCP4Interface 
# Created Nov01 by Peter Briggs
#
# =======================================================================

#------------------------------------------------------------------------------
proc edit_modules_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global typedef

    # Make sure we have the procedures available for editing the
    # modules.def file
    source [SearchPath TOP src modules_utils.tcl]

    # Menus for actions
    DefineMenu _edit_modules_action [list "add a new task reference" \
                                          "edit an existing task reference" \
					  "delete an existing task reference" \
	                                  "add a new module" \
					  "edit an existing module" \
	                                  "delete an existing module" \
					  "add a new folder to a module" \
					  "edit an existing folder" \
					  "delete an existing folder" ] \
			            [list ADDTASK \
                                          EDITTASK \
					  DELTASK \
					  ADDMODULE \
					  EDITMODULE \
					  DELMODULE \
					  ADDFOLDER \
					  EDITFOLDER \
					  DELFOLDER ]

    DefineMenu _edit_modules_location [list "user's local CCP4i" \
	                                    "main CCP4i" \
					    "specific" ] \
				    [list LOCAL MAIN USER]

    DefineMenu _edit_modules_modposition [list "at the end of the module list" \
                                               "at the start of the module list" \
					       "after an existing module" \
					       "before an existing module" ] \
					 [list LAST FIRST AFTER BEFORE]

    DefineMenu _edit_modules_taskposition [list "at the end of the task list" \
                                                "at the start of the task list" \
					        "after an existing task or folder" \
					        "before an existing task or folder" ] \
					  [list LAST FIRST AFTER BEFORE]

    # Variable menus
    DefineVariable $arrayname MODULES_MENU  _list ""
    DefineVariable $arrayname MODULES_ALIAS _list ""
    DefineVariable $arrayname TASKS_MENU    _list ""
    DefineVariable $arrayname TASKS_ALIAS   _list ""
    DefineVariable $arrayname ITEMS_MENU    _list ""
    DefineVariable $arrayname ITEMS_ALIAS   _list ""
    DefineVariable $arrayname ITEMS2_MENU   _list ""
    DefineVariable $arrayname ITEMS2_ALIAS  _list ""
    DefineVariable $arrayname ALLTASKS_MENU  _list ""
    DefineVariable $arrayname ALLTASKS_ALIAS _list ""
    DefineVariable $arrayname ALLTASKS2_MENU  _list ""
    DefineVariable $arrayname ALLTASKS2_ALIAS _list ""
    DefineVariable $arrayname FOLDERS_MENU  _list ""
    DefineVariable $arrayname FOLDERS_ALIAS _list ""
    DefineVariable $arrayname FOLDERS2_MENU  _list ""
    DefineVariable $arrayname FOLDERS2_ALIAS _list ""
    DefineVariable $arrayname FOLDERS3_MENU  _list ""
    DefineVariable $arrayname FOLDERS3_ALIAS _list ""
    set typedef(_edit_modules_modules) [list varmenu MODULES_MENU MODULES_ALIAS 20]
    set typedef(_edit_modules_tasks) [list varmenu TASKS_MENU TASKS_ALIAS 10]
    set typedef(_edit_modules_items) [list varmenu ITEMS_MENU ITEMS_ALIAS 10]
    set typedef(_edit_modules_items2) [list varmenu ITEMS2_MENU ITEMS2_ALIAS 10]
    set typedef(_edit_modules_alltasks) [list varmenu ALLTASKS_MENU ALLTASKS_ALIAS 20]
    set typedef(_edit_modules_alltasks2) [list varmenu ALLTASKS2_MENU ALLTASKS2_ALIAS 20]
    set typedef(_edit_modules_folders) [list varmenu FOLDERS_MENU FOLDERS_ALIAS 20]
    set typedef(_edit_modules_folders2) [list varmenu FOLDERS2_MENU FOLDERS2_ALIAS 20]
    set typedef(_edit_modules_folders3) [list varmenu FOLDERS3_MENU FOLDERS3_ALIAS 20]
    set typedef(_edit_modules_foldertasks) \
     [list varmenu FOLDERTASKS_MENU FOLDERTASKS_ALIAS 10]
    DefineVariable $arrayname N_MODULES     _positiveint 0
    DefineVariable $arrayname N_TASKS       _positiveint 0
    DefineVariable $arrayname N_ITEMS       _positiveint 0
    DefineVariable $arrayname N_ITEMS2      _positiveint 0
    DefineVariable $arrayname N_ALLTASKS    _positiveint 0
    DefineVariable $arrayname N_ALLTASKS2   _positiveint 0
    DefineVariable $arrayname N_FOLDERS     _positiveint 0
    DefineVariable $arrayname N_FOLDERS2    _positiveint 0
    DefineVariable $arrayname N_FOLDERS3    _positiveint 0
    DefineVariable $arrayname N_FOLDERTASKS _positiveint 0

    # Variables for actions
    DefineVariable $arrayname LOCATION _edit_modules_location MAIN
    DefineVariable $arrayname ACTION   _edit_modules_action   ADDTASK

    # Other variables
    #
    # User-specified module
    DefineVariable $arrayname MODULES_FILE      _text ""
    # Add a new module
    DefineVariable $arrayname NEW_MODULE_NAME   _text ""
    DefineVariable $arrayname NEW_MODULE_TITLE  _text ""
    DefineVariable $arrayname NEW_MODULE_POS    _edit_modules_modposition LAST
    DefineVariable $arrayname NEW_MODULE_NEIGHBOUR _edit_modules_modules ""
    #
    # Remove an existing module
    DefineVariable $arrayname DEL_MODULE_NAME   _edit_modules_modules ""
    #
    # Update/edit an existing module
    DefineVariable $arrayname UPDATE_MODULE     _edit_modules_modules ""
    DefineVariable $arrayname UPDATE_MODULE_TITLE _text ""
    #
    # Add a new task reference
    DefineVariable $arrayname NEW_TASK_NAME     _text ""
    DefineVariable $arrayname NEW_TASK_TITLE    _text ""
    DefineVariable $arrayname NEW_TASK_DESCRIPT _text ""
    DefineVariable $arrayname NEW_TASK_POS      _edit_modules_taskposition LAST
    DefineVariable $arrayname NEW_TASK_NEIGHBOUR _edit_modules_items  ""
    DefineVariable $arrayname NEW_TASK_MODULE   _edit_modules_modules ""
    DefineVariable $arrayname NEW_TASK_IN_FOLDER _logical 0
    DefineVariable $arrayname NEW_TASK_FOLDER   _edit_modules_folders ""
    DefineVariable $arrayname NEW_TASK_FOLDERNEIGHBOUR _edit_modules_foldertasks  ""
    DefineVariable $arrayname SELECT_TASK_FOLDER _logical 0
    #
    # Update/edit an existing task reference
    DefineVariable $arrayname UPDATE_TASK       _edit_modules_alltasks2  ""
    DefineVariable $arrayname UPDATE_TASK_MODULE _edit_modules_modules ""
    DefineVariable $arrayname UPDATE_TASK_TITLE _text ""
    DefineVariable $arrayname UPDATE_TASK_FOLDER _text ""
    DefineVariable $arrayname UPDATE_TASK_DESCRIPT _text ""
    #
    # Remove an existing task reference
    DefineVariable $arrayname DEL_TASK_TITLE    _edit_modules_alltasks ""
    DefineVariable $arrayname DEL_TASK_MODULE   _edit_modules_modules ""
    #
    # Add a new folder to a module
    DefineVariable $arrayname NEW_FOLDER_NAME     _text ""
    DefineVariable $arrayname NEW_FOLDER_TITLE    _text ""
    DefineVariable $arrayname NEW_FOLDER_DESCRIPT _text ""
    DefineVariable $arrayname NEW_FOLDER_POS      _edit_modules_taskposition LAST
    DefineVariable $arrayname NEW_FOLDER_NEIGHBOUR _edit_modules_items2  ""
    DefineVariable $arrayname NEW_FOLDER_MODULE   _edit_modules_modules ""
    #
    # Update/edit an existing folder reference
    DefineVariable $arrayname UPDATE_FOLDER        _edit_modules_folders3  ""
    DefineVariable $arrayname UPDATE_FOLDER_MODULE _edit_modules_modules ""
    DefineVariable $arrayname UPDATE_FOLDER_TITLE  _text ""
    DefineVariable $arrayname UPDATE_FOLDER_DESCRIPT _text ""
    #
    # Delete a folder from a module
    DefineVariable $arrayname DEL_FOLDER_TITLE    _edit_modules_folders2 ""
    DefineVariable $arrayname DEL_FOLDER_MODULE   _edit_modules_modules ""

    # Initialise (update) all the menus
    edit_modules_updateallmenus $arrayname

    # Other initialisations
    edit_modules_getmoduletitle $arrayname UPDATE_MODULE UPDATE_MODULE_TITLE
    edit_modules_gettaskinfo $arrayname UPDATE_TASK_MODULE UPDATE_TASK \
	    UPDATE_TASK_FOLDER UPDATE_TASK_TITLE UPDATE_TASK_DESCRIPT
    edit_modules_getfolderinfo $arrayname UPDATE_FOLDER_MODULE UPDATE_FOLDER \
            UPDATE_FOLDER_TITLE UPDATE_FOLDER_DESCRIPT

    return 1
}

#------------------------------------------------------------------------------
proc edit_modules_task_window { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global configure

  set helpfile [SearchPath HELP general modules.html ]

  if { [CreateTaskWindow $arrayname  \
        "Edit Modules File for CCP4Interface" "Edit Modules" \
        [ list "Add New Module" \
	"Delete Module" \
        "Add New Task Reference to Modules file" \
	"Delete Task Reference from Modules file" \
	"Edit Module Title" \
	"Edit Task Reference in Modules file" \
        "Add New Folder to Module" \
	"Delete Folder from Module" \
	"Edit Folder Attributes" ] \
        -action_buttons quit \
        -help_file $helpfile ] == 0 } return

  set savebutton [button $array(WINDOW).buttons.save\
                -text "Apply" \
                -relief raised  \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
		-command "edit_modules_apply $arrayname"]

  set clearbutton [button $array(WINDOW).buttons.clear\
                -text "Clear" \
		-relief raised \
		-background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
		-command "edit_modules_clear $arrayname"]

  pack $savebutton $clearbutton -side left -expand 1

#-------------------------------------------------------PROTOCOL

  OpenFolder protocol

  CreateLine line \
     label "Edit" \
     widget LOCATION \
     -command " edit_modules_checkmodules $arrayname ; edit_modules_updateallmenus $arrayname" \
     label "modules file to" \
     widget ACTION

  CreateLine line \
          label "Modules file:" \
          varlabel MODULES_FILE \
          toggle_display LOCATION open [list USER]

  $line.l2 configure -width 60 -background $configure(COLOUR_BACKGROUND)

  # Make a "browse" button to allow the user to select the modules file
  # This is a custom widget!
  set browse [button $line.browse -text "Browse" \
          -command "edit_modules_select $arrayname"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.l2 -side left

#-------------------------------------------------------Add Module

  OpenFolder 1 ACTION open [list ADDMODULE] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Add the new module" \
     widget NEW_MODULE_POS

  CreateLine line \
     label "Insert before the" \
     widget NEW_MODULE_NEIGHBOUR \
     label "module" \
     toggle_display NEW_MODULE_POS open [list BEFORE]

  CreateLine line \
     label "Insert after the" \
     widget NEW_MODULE_NEIGHBOUR \
     label "module" \
     toggle_display NEW_MODULE_POS open [list AFTER]

  CloseSubFrame

  CreateLine line \
     label "Specify a one-word internal name for the new module" -italic

  CreateLine line \
     label "Name of new module" \
     widget NEW_MODULE_NAME -width 20

  CreateLine line \
     label "Specify the title text for the new module, which will appear in the modules menu in the main CCP4i window" -italic 

  CreateLine line \
     label "Title of new module" \
     widget NEW_MODULE_TITLE -width 60

#-------------------------------------------------------Delete Module

  OpenFolder 2 ACTION open [list DELMODULE] hide

  CreateLine line \
     label "Name of module to remove" \
     widget DEL_MODULE_NAME -width 25 \
     toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "There are no modules to delete" \
     -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Add Task

  OpenFolder 3 ACTION open [list ADDTASK] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Add a new task reference to the" \
     widget NEW_TASK_MODULE -width 25 \
     -command "edit_modules_updateallmenus $arrayname" \
     label "module"
 
  CreateLine line \
     label "Specify the title text, which will appear on the button to launch the task" \
     -italic

  CreateLine line \
     label "Title of new task" \
     widget NEW_TASK_TITLE -width 40
 
  CreateLine line \
     label "Specify the task name i.e. the root name of the task .tcl and .def files" \
     -italic

  CreateLine line \
     label "Name of task file" \
     widget NEW_TASK_NAME -width 20
 
  CreateLine line \
     label "Specify the description text, which appears in the message help line" \
     -italic

  CreateLine line \
     label "Description of new task" \
     widget NEW_TASK_DESCRIPT -width 60

  #
  # Deal with where to place the new task reference in the list
  # It could be a "top-level" task or it could be inside a folder
  # within the module

  CreateLine line \
     widget NEW_TASK_IN_FOLDER \
     -command "edit_modules_updatefoldertasksmenu $arrayname NEW_TASK_MODULE NEW_TASK_FOLDER NEW_TASK_FOLDERNEIGHBOUR ; edit_modules_set_select_task_folder $arrayname" \
     label "Put task reference into a folder within this module" \
     toggle_display N_FOLDERS hide [list 0]

  # Subframe for dealing with the case when the module contains
  # folders and the user has elected to add the task reference to one
  # of them
  OpenSubFrame frame -toggle_display SELECT_TASK_FOLDER open [list 1]

  CreateLine line \
     label "Add the task in the" \
     widget NEW_TASK_FOLDER \
     -command "edit_modules_updatefoldertasksmenu $arrayname NEW_TASK_MODULE NEW_TASK_FOLDER NEW_TASK_FOLDERNEIGHBOUR ; edit_modules_set_select_task_folder $arrayname" \
     label "folder" \
     toggle_display N_FOLDERTASKS open [list 0]     

  # Subframe which should be visible if there is at least one task
  # in the selected subframe
  OpenSubFrame frame -toggle_display N_FOLDERTASKS hide [list 0]

  CreateLine line \
     label "Add the task in the" \
     widget NEW_TASK_FOLDER \
     -command "edit_modules_updatefoldertasksmenu $arrayname NEW_TASK_MODULE NEW_TASK_FOLDER NEW_TASK_FOLDERNEIGHBOUR ; edit_modules_set_select_task_folder $arrayname" \
     label "folder" \
     widget NEW_TASK_POS

     CreateLine line \
        label "Insert before the" \
        widget NEW_TASK_FOLDERNEIGHBOUR -width 30 \
        label "task" \
        toggle_display NEW_TASK_POS open [list BEFORE]

     CreateLine line \
        label "Insert after the" \
        widget NEW_TASK_FOLDERNEIGHBOUR -width 30 \
        label "task" \
        toggle_display NEW_TASK_POS open [list AFTER]

  CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display SELECT_TASK_FOLDER hide [list 1]

  OpenSubFrame frame -toggle_display N_TASKS hide [list 0]

  CreateLine line \
     label "Add the new task reference" \
     widget NEW_TASK_POS

  CreateLine line \
     label "Insert before" \
     widget NEW_TASK_NEIGHBOUR -width 30 \
     toggle_display NEW_TASK_POS open [list BEFORE]

  CreateLine line \
     label "Insert after" \
     widget NEW_TASK_NEIGHBOUR -width 30 \
     toggle_display NEW_TASK_POS open [list AFTER]

  CloseSubFrame

  CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display N_MODULES open [list 0]

  CreateLine line \
     label "There are no modules available to add a task reference to" \
     -italic

  CloseSubFrame

#-------------------------------------------------------Delete Task

  OpenFolder 4 ACTION open [list DELTASK] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Remove a task from the" \
     widget DEL_TASK_MODULE -width 25 \
     -command "edit_modules_updatealltasksmenu $arrayname ALLTASKS DEL_TASK_MODULE DEL_TASK_TITLE"\
     label "module"

  CreateLine line \
     label "Task reference to be deleted:" \
     widget DEL_TASK_TITLE -width 30 \
     toggle_display N_ALLTASKS hide [list 0]

  CreateLine line \
     label "There are no task references to remove from this module" \
     -italic \
     toggle_display N_ALLTASKS open [list 0]

  CloseSubFrame

  CreateLine line \
     label "There are no modules to remove task references from" \
     -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Edit Module

  OpenFolder 5 ACTION open [list EDITMODULE] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Edit title for" \
     widget UPDATE_MODULE -width 25 \
     -command "edit_modules_getmoduletitle $arrayname UPDATE_MODULE UPDATE_MODULE_TITLE"\
     label "module"

  CreateLine line \
     label "Edit the title text which appears in the list of modules in the main CCP4i window" -italic

  CreateLine line \
     label "New title" \
     widget UPDATE_MODULE_TITLE -width 50

  CloseSubFrame

  CreateLine line \
     label "There are no modules to edit" -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Edit Task

  OpenFolder 6 ACTION open [list EDITTASK] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Edit attributes for a task in the" \
     widget UPDATE_TASK_MODULE -width 25 \
     -command "edit_modules_updateallmenus $arrayname" \
     label "module"

  CreateLine line \
     label "Edit attributes of the" \
     widget UPDATE_TASK -width 40 \
     -command "edit_modules_gettaskinfo $arrayname UPDATE_TASK_MODULE UPDATE_TASK UPDATE_TASK_FOLDER UPDATE_TASK_TITLE UPDATE_TASK_DESCRIPT" \
     label "task reference" \
     toggle_display N_TASKS hide [list 0]
 
  CreateLine line \
     label "Specify the title text, which will appear on the button to launch the task" \
     -italic \
     toggle_display N_TASKS hide [list 0]

  CreateLine line \
     label "New title" \
     widget UPDATE_TASK_TITLE -width 40 \
     toggle_display N_TASKS hide [list 0]
 
  CreateLine line \
     label "Specify the description text, which appears in the message help line" \
     -italic \
     toggle_display N_TASKS hide [list 0]

  CreateLine line \
     label "New description" \
     widget UPDATE_TASK_DESCRIPT -width 60 \
     toggle_display N_TASKS hide [list 0]

  CreateLine line \
     label "There are no task references in this module to edit" -italic \
     toggle_display N_TASKS open [list 0]

  CloseSubFrame

  CreateLine line \
     label "There are no modules (and hence no task references) to edit" -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Add Folder

  OpenFolder 7 ACTION open [list ADDFOLDER] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Add a new folder to the" \
     widget NEW_FOLDER_MODULE -width 25 \
     -command "edit_modules_updatecontentmenu $arrayname ITEMS2 NEW_FOLDER_MODULE NEW_FOLDER_NEIGHBOUR" \
     label "module"
 
  CreateLine line \
     label "Specify the title text, which will appear on the folder title bar" \
     -italic

  CreateLine line \
     label "Title of new folder" \
     widget NEW_FOLDER_TITLE -width 40
 
  CreateLine line \
     label "Specify an internal name for the folder" \
     -italic

  CreateLine line \
     label "Internal name for the folder" \
     widget NEW_FOLDER_NAME -width 20
 
  CreateLine line \
     label "Specify the description text, which appears in the message help line" \
     -italic

  CreateLine line \
     label "Description of new folder" \
     widget NEW_FOLDER_DESCRIPT -width 60

  OpenSubFrame frame -toggle_display N_ITEMS2 hide [list 0]

  CreateLine line \
     label "Add the new folder" \
     widget NEW_FOLDER_POS

  CreateLine line \
     label "Insert before" \
     widget NEW_FOLDER_NEIGHBOUR -width 30 \
     toggle_display NEW_FOLDER_POS open [list BEFORE]

  CreateLine line \
     label "Insert after" \
     widget NEW_FOLDER_NEIGHBOUR -width 30 \
     toggle_display NEW_FOLDER_POS open [list AFTER]

  CloseSubFrame

  CloseSubFrame

  CreateLine line \
     label "There are no modules to add folders to" -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Delete Folder

  OpenFolder 8 ACTION open [list DELFOLDER] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Remove a folder from the" \
     widget DEL_FOLDER_MODULE -width 25 \
     -command "edit_modules_updatefoldermenu $arrayname FOLDERS2 DEL_FOLDER_MODULE DEL_FOLDER_TITLE" \
     label "module"

  CreateLine line \
     label "Folder to be deleted:" \
     widget DEL_FOLDER_TITLE -width 30 \
     toggle_display N_FOLDERS2 hide [list 0]

  CreateLine line \
     label "There are no folders to remove from this module" \
     -italic \
     toggle_display N_FOLDERS2 open [list 0]

  CloseSubFrame

  CreateLine line \
     label "There are no modules to remove folders from" -italic \
     toggle_display N_MODULES open [list 0]

#-------------------------------------------------------Edit Folder

  OpenFolder 9 ACTION open [list EDITFOLDER] hide

  OpenSubFrame frame -toggle_display N_MODULES hide [list 0]

  CreateLine line \
     label "Edit a folder in the" \
     widget UPDATE_FOLDER_MODULE -width 25 \
     -command "edit_modules_updateallmenus $arrayname ; edit_modules_updatefoldermenu $arrayname FOLDERS3 UPDATE_FOLDER_MODULE UPDATE_FOLDER_TITLE" \
     label "module"

  OpenSubFrame frame -toggle_display N_FOLDERS3 hide [list 0]

  CreateLine line \
     label "Edit the" \
     widget UPDATE_FOLDER -width 30 \
     -command "edit_modules_getfolderinfo $arrayname UPDATE_FOLDER_MODULE UPDATE_FOLDER UPDATE_FOLDER_TITLE UPDATE_FOLDER_DESCRIPT" \
     label "folder"

  CreateLine line \
     label "Specify the title text for the folder" \
     -italic

  CreateLine line \
     label "New title" \
     widget UPDATE_FOLDER_TITLE -width 40
 
  CreateLine line \
     label "Specify the description text, which appears in the message help line" \
     -italic

  CreateLine line \
     label "New description" \
     widget UPDATE_FOLDER_DESCRIPT -width 60

  CloseSubFrame

  CreateLine line \
     label "There are no folders to edit in this module" \
     toggle_display N_FOLDERS3 open [list 0]

  CloseSubFrame

  CreateLine line \
     label "There are no modules with folders to edit" -italic \
     toggle_display N_MODULES open [list 0]
}

#------------------------------------------------------------------------------
proc edit_modules_apply { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array

  set modules_file [edit_modules_getfilename $arrayname]

  # Still no modules.def file? Then abort
  if { ![file exists $modules_file] } {
      WarningMessage "There is no modules.def file \"$modules_file\"

The requested action cannot be performed."
      return
  }

  # Add task option
  switch -exact [GetValue $arrayname ACTION] {
      ADDMODULE {
	  # Add a new module reference
	  if { $array(NEW_MODULE_NAME) != "" && $array(NEW_MODULE_TITLE) != "" } {
	      set cmd [list AddModule $modules_file $array(NEW_MODULE_NAME) \
		      $array(NEW_MODULE_TITLE)]
	      switch [GetValue $arrayname NEW_MODULE_POS] {
		  LAST { set opts [list -last] }
		  FIRST { set opts [list -first] }
		  BEFORE { set opts [list -before \
			  [GetValue $arrayname NEW_MODULE_NEIGHBOUR]] }
		  AFTER { set opts [list -after \
			  [GetValue $arrayname NEW_MODULE_NEIGHBOUR]] }
	      }
	      if {![eval $cmd $opts] } {
		  WarningMessage "Couldn't add module to $modules_file"
		  return
	      }
	  } else {
	      WarningMessage "The module title and/or name are blank\nNo changes have been made to the modules.def file"
	      return
	  }
      }
      EDITMODULE {
	  # Edit the title of an existing module
	  if { [IfSet $array(UPDATE_MODULE_TITLE)] } {
	      if {![UpdateModule $modules_file $array(UPDATE_MODULE) \
		      $array(UPDATE_MODULE_TITLE)] } {
		  WarningMessage "Couldn't update module title in $modules_file"
		  return
	      }
	      edit_modules_updateallmenus $arrayname
	  } else {
	      WarningMessage "The new module title is blank\nNo changes have been made to the modules.def file"
	      return
	  }
      }
      DELMODULE {
	  # Delete an existing module reference
	  if { $array(DEL_MODULE_NAME) != "" } {
	      if {![DeleteModule $modules_file [GetValue $arrayname DEL_MODULE_NAME]] } {
		  WarningMessage "Couldn't remove module from $modules_file"
		  return
	      }
	  } else {
	      WarningMessage "No module was specified

No changes have been made to the modules.def
file"
	      return
	  }
      }
      ADDTASK {
	  # Add a new task reference
	  if { $array(NEW_TASK_NAME) != "" && $array(NEW_TASK_TITLE) != ""  \
		  && $array(NEW_TASK_DESCRIPT) != "" } {
	      set module_name [GetValue $arrayname NEW_TASK_MODULE]
	      if {![IfSet $module_name] } {
		  return
	      }
	      if {![edit_modules_checktaskfiles $arrayname] && \
		  ![regexp ^run_ $array(NEW_TASK_NAME)] } {
		  WarningMessage "There is no task (.tcl) file for the task

\"$array(NEW_TASK_NAME)\"

No changes have been made to the modules.def file"
		  return
	      }
	      set cmd [list AddTaskReference $modules_file $array(NEW_TASK_TITLE) \
		      $array(NEW_TASK_NAME) $array(NEW_TASK_DESCRIPT) \
		      $module_name]
	      if { $array(NEW_TASK_IN_FOLDER) } {
		  lappend opts -folder [GetValue $arrayname NEW_TASK_FOLDER]
		  switch [GetValue $arrayname NEW_TASK_POS] {
		      LAST { lappend opts -last }
		      FIRST { lappend opts -first }
		      BEFORE { lappend opts -before \
				   [GetValue $arrayname NEW_TASK_FOLDERNEIGHBOUR] }
		      AFTER { lappend opts -after \
				  [GetValue $arrayname NEW_TASK_FOLDERNEIGHBOUR] }
		  }
	      } else {
		  switch [GetValue $arrayname NEW_TASK_POS] {
		      LAST { set opts [list -last] }
		      FIRST { set opts [list -first] }
		      BEFORE { set opts [list -before [GetValue $arrayname \
							   NEW_TASK_NEIGHBOUR]] }
		      AFTER { set opts [list -after [GetValue $arrayname \
							 NEW_TASK_NEIGHBOUR]] }
		  }
	      }
	      if {![eval $cmd $opts] } {
		  WarningMessage "Couldn't add task reference to $modules_file"
		  return
	      }
	  } else {
	      WarningMessage "One or more of the task name, title or
description are blank

No changes have been made to the modules.def file"
	      return
	  }
      }
      EDITTASK {
	  # Edit an existing task reference
	  if { [IfSet $array(UPDATE_TASK_TITLE)] \
		   && [IfSet $array(UPDATE_TASK_DESCRIPT)] } {
	      # Acquire the task and folder information
	      set update_task_info [GetValue $arrayname UPDATE_TASK]
	      set update_task [lindex $update_task_info 1]
	      if { $array(UPDATE_TASK_FOLDER) == "" } {
		  # Editing a top-level task
		  if {![UpdateTaskReference $modules_file $update_task \
			    [GetValue $arrayname UPDATE_TASK_MODULE] \
			    -title $array(UPDATE_TASK_TITLE) \
			    -descript $array(UPDATE_TASK_DESCRIPT) ] } {
		      WarningMessage "Couldn't update task attributes in $modules_file"
		      return
		  }
	      } else {
		  # Editing a task in a folder
		  if {![UpdateTaskReference $modules_file $update_task \
			    [GetValue $arrayname UPDATE_TASK_MODULE] \
			    -title $array(UPDATE_TASK_TITLE) \
			    -descript $array(UPDATE_TASK_DESCRIPT) \
			    -folder $array(UPDATE_TASK_FOLDER) ] } {
		      WarningMessage "Couldn't update task attributes in $modules_file"
		      return
		  }
	      }
	  } else {
	      WarningMessage "The task title and/or description is blank

No changes have been made to the modules.def file"
              return
	  }
      }
      DELTASK {
	  # Delete a task reference
	  if { $array(DEL_TASK_TITLE) != "" && $array(DEL_TASK_MODULE) != "" } {
	      # Acquire the task and folder information
	      set del_task_info [GetValue $arrayname DEL_TASK_TITLE]
	      set del_task_folder [lindex $del_task_info 0]
	      set del_task_title [lindex $del_task_info 1]
	      if { $del_task_folder == "" } {
		  # Delete a top-level task
		  if {![DeleteTaskReference $modules_file $del_task_title \
			    [GetValue $arrayname DEL_TASK_MODULE] ] } {
		      WarningMessage "Couldn't remove task from $modules_file"
		      return
		  }
	      } else {
		  # Delete a task from a folder
		  if {![DeleteTaskReference $modules_file $del_task_title \
			    [GetValue $arrayname DEL_TASK_MODULE] $del_task_folder ] } {
		      WarningMessage "Couldn't remove task from $modules_file"
		      return
		  }
	      }  
	  } else {
	      WarningMessage "A task title and/or module were not
specified

No changes have been made to the modules.def file"
	      return
	  }
      }
      ADDFOLDER {
	  # Add a new folder to a module
	  if { $array(NEW_FOLDER_NAME) != "" && $array(NEW_FOLDER_TITLE) != ""  \
		  && $array(NEW_FOLDER_DESCRIPT) != "" } {
	      set module_name [GetValue $arrayname NEW_FOLDER_MODULE]
	      if {![IfSet $module_name] } {
		  return
	      }
	      set cmd [list AddModuleFolder $modules_file $array(NEW_FOLDER_TITLE) \
		      $array(NEW_FOLDER_NAME) $array(NEW_FOLDER_DESCRIPT) \
		      $module_name]
	      switch [GetValue $arrayname NEW_FOLDER_POS] {
		  LAST { set opts [list -last] }
		  FIRST { set opts [list -first] }
		  BEFORE { set opts \
			       [list -before [GetValue $arrayname NEW_FOLDER_NEIGHBOUR]] }
		  AFTER { set opts \
			      [list -after [GetValue $arrayname NEW_FOLDER_NEIGHBOUR]] }
	      }
	      if {![eval $cmd $opts] } {
		  WarningMessage "Couldn't add folder to $modules_file"
		  return
	      }
	  } else {
	      WarningMessage "One or more of the folder name, title or
description are blank

No changes have been made to the modules.def file"
	      return
	  }
      }
      EDITFOLDER {
	  # Edit an existing folder reference
	  if { [IfSet $array(UPDATE_FOLDER_TITLE)] \
		   && [IfSet $array(UPDATE_FOLDER_DESCRIPT)] } {
	      if {![UpdateFolderReference $modules_file \
			[GetValue $arrayname UPDATE_FOLDER] \
			[GetValue $arrayname UPDATE_FOLDER_MODULE] \
			-title $array(UPDATE_FOLDER_TITLE) \
			-descript $array(UPDATE_FOLDER_DESCRIPT) ] } {
		  WarningMessage "Couldn't update folder attributes in $modules_file"
		  return
	      }
	  } else {
	      WarningMessage "The folder title and/or description is blank

No changes have been made to the modules.def file"
              return
	  }
      }
      DELFOLDER {
	  # Remove a folder from a module
	  if { $array(DEL_FOLDER_TITLE) != "" && $array(DEL_FOLDER_MODULE) != "" } {
	      # Acquire the folder information
	      set folder_title [GetValue $arrayname DEL_FOLDER_TITLE]
	      if {![DeleteModuleFolder $modules_file  \
			[GetValue $arrayname DEL_FOLDER_MODULE] \
			$folder_title] } {
		      WarningMessage "Couldn't remove folder from $modules_file"
		      return
	      }  
	  } else {
	      WarningMessage "A folder title and/or module were not
specified

No changes have been made to the modules.def file"
	      return
	  }
	  
      }
      default {
	  # Bad option - this should never happen
	  WarningMessage "Unknown option!"
	  return
      }
  }

  # Reload the task lists in the main window
  WarningMessage "Successfully updated the modules.def file"
  ReloadTasklists .module.menu.module.mb.m moduledef

  # Update the menus to accomodate the changes
  edit_modules_updateallmenus $arrayname

  return
}

#------------------------------------------------------------------------------
proc edit_modules_getfilename { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global system

  set modules_file ""

  switch [GetValue $arrayname LOCATION] {
      LOCAL {
	  switch $system(OPSYS) {
	      UNIX { set opsys unix }
	      WINDOWS { set opsys windows }
	  }
	  set modules_file [file join [GetSystemVar DOT] $opsys modules.def]
      }
      MAIN {
	  set modules_file \
		  [file join [GetEnvPath CCP4I_TOP] etc modules.def]
      }
      USER {
          set modules_file $array(MODULES_FILE)
      }
  }
  return $modules_file
}

#------------------------------------------------------------------------------
proc edit_modules_select { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { [SelectFile modules_file -filter "*.def"] } {
    set array(MODULES_FILE) [lindex $modules_file 0]
  }
  edit_modules_checkmodules $arrayname
  edit_modules_updateallmenus $arrayname
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatemodulesmenu { arrayname modulevar { cmd {} } } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleList $modules_file]

  set array(N_MODULES) [llength $master_list]

  if { [llength $master_list] > 0 } {
      foreach module $master_list {
	  lappend modules_menu [lindex $module 1]
	  lappend modules_alias [lindex $module 0]
      }
      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 MODULES_MENU $modules_menu \
		  MODULES_ALIAS $modules_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 MODULES_MENU $modules_menu \
		  MODULES_ALIAS $modules_alias $cmd
      }

      if { [llength $modules_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $modules_menu $array($modulevar)] < 0 } {
	      set array($modulevar) [lindex $modules_menu 0]
	  }
      } else {
	  set array($modulevar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatetasksmenu { arrayname modulevar taskvar { cmd {} } } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array

  set tasks_menu  ""
  set tasks_alias ""

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetTaskList $modules_file $array($modulevar) ]

  set array(N_TASKS) [llength $master_list]

  if { [llength $master_list] > 0 } {
      foreach task $master_list {
	  lappend tasks_menu [lindex $task 0]
	  lappend tasks_alias [lindex $task 1]
      }

      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 TASKS_MENU $tasks_menu \
		  TASKS_ALIAS $tasks_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 TASKS_MENU $tasks_menu \
		  TASKS_ALIAS $tasks_alias $cmd
      }

      if { [llength $tasks_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $tasks_menu $array($taskvar)] < 0 } {
	      set array($taskvar) [lindex $tasks_menu 0]
	  }
      } else {
	  set array($taskvar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatecontentmenu { arrayname menuparam modulevar contentvar \
					  { cmd {} } } {
#------------------------------------------------------------------------------
# This is a variant of edit_modules_updatetasksmenu
# The updated menu lists all the items in a module (both tasks and folders)
 upvar #0 $arrayname array

  set content_menu  ""
  set content_alias ""

  set menu_param  [subst $menuparam]_MENU
  set alias_param [subst $menuparam]_ALIAS

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleContentList $modules_file $array($modulevar) ]

  set array(N_$menuparam) [llength $master_list]

  if { [llength $master_list] > 0 } {
      foreach item $master_list {
	  if { [lindex $item 3] == "FOLDER" } {
	      lappend content_menu "'[lindex $item 0]' folder"
	  } else {
	      lappend content_menu "'[lindex $item 0]' task"
	  }
	  lappend content_alias [lindex $item 0]
      }

      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $content_menu \
		  $alias_param $content_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $content_menu \
		  $alias_param $content_alias $cmd
      }

      if { [llength $content_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $content_menu $array($contentvar)] < 0 } {
	      set array($contentvar) [lindex $content_menu 0]
	  }
      } else {
	  set array($contentvar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatefoldermenu { arrayname menuparam modulevar foldervar \
					 { cmd {} } } {
#------------------------------------------------------------------------------
# This is a variant of edit_modules_updatetasksmenu
# The updated menu lists all the folders in a module
 upvar #0 $arrayname array

  set folder_menu  ""
  set folder_alias ""

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleContentList $modules_file $array($modulevar) ]

  set menu_param  [subst $menuparam]_MENU
  set alias_param [subst $menuparam]_ALIAS

  set array(N_$menuparam) 0

  if { [llength $master_list] > 0 } {
      foreach item $master_list {
	  if { [lindex $item 3] == "FOLDER" } {
	      # Only add folders
	      lappend folder_menu "[lindex $item 0]"
	      lappend folder_alias [lindex $item 1]
	      incr array(N_$menuparam)
	  }
      }

      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $folder_menu \
		  $alias_param $folder_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $folder_menu \
		  $alias_param $folder_alias $cmd
      }

      if { [llength $folder_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $folder_menu $array($foldervar)] < 0 } {
	      set array($foldervar) [lindex $folder_menu 0]
	  }
      } else {
	  set array($foldervar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatefoldertasksmenu { arrayname modulevar foldervar taskvar \
					      { cmd {} } } {
#------------------------------------------------------------------------------
# This is a variant of edit_modules_updatetasksmenu
# The updated menu lists all the tasks for a specific folder in a module
 upvar #0 $arrayname array

  set task_menu  ""
  set task_alias ""

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetFolderContentList $modules_file $array($modulevar) \
		      $array($foldervar)]

  set array(N_FOLDERTASKS) [llength $master_list]
  if { [llength $master_list] > 0 } {
      foreach item $master_list {
	  lappend task_menu [lindex $item 0]
	  lappend task_alias [lindex $item 0]
      }

      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 FOLDERTASKS_MENU $task_menu \
		  FOLDERTASKS_ALIAS $task_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 FOLDERTASKS_MENU $task_menu \
		  FOLDERTASKS_ALIAS $task_alias $cmd
      }

      if { [llength $task_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $task_menu $array($taskvar)] < 0 } {
	      set array($taskvar) [lindex $task_menu 0]
	  }
      } else {
	  set array($taskvar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_updatealltasksmenu { arrayname menuparam modulevar alltasksvar \
					   { cmd {} } } {
#------------------------------------------------------------------------------
# This is a variant of edit_modules_updatetasksmenu
# The updated menu lists all the tasks in a module, including those within
# folders
 upvar #0 $arrayname array

  set alltasks_menu  ""
  set alltasks_alias ""

  set menu_param  [subst $menuparam]_MENU
  set alias_param [subst $menuparam]_ALIAS

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleContentList $modules_file $array($modulevar) ]

  set array(N_$menuparam) 0

  if { [llength $master_list] > 0 } {
      foreach item $master_list {
	  if { [lindex $item 3] == "FOLDER" } {
	      # List the tasks in this folder
	      set folder [lindex $item 0]
	      set task_list [GetFolderContentList $modules_file \
				 $array($modulevar) $folder]
	      foreach task $task_list {
		  lappend alltasks_menu "<$folder> [lindex $task 0]"
		  lappend alltasks_alias [list $folder [lindex $task 0]]
		  incr array(N_$menuparam)
	      }
	  } else {
	      lappend alltasks_menu [lindex $item 0]
	      lappend alltasks_alias [list {} [lindex $item 0]]
	      incr array(N_$menuparam)
	  }
      }

      if { "$cmd" == "" } {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $alltasks_menu \
	      $alias_param $alltasks_alias
      } else {
	  UpdateVariableMenu $arrayname initialise 0 $menu_param $alltasks_menu \
	      $alias_param $alltasks_alias $cmd
      }

      if { [llength $alltasks_menu] > 0 } {
	  # Reset the current option if it is no longer in the menu
	  if {[lsearch -exact $alltasks_menu $array($alltasksvar)] < 0 } {
	      set array($alltasksvar) [lindex $alltasks_menu 0]
	  }
      } else {
	  set array($alltasksvar) ""
      }
  }
  return
}

#------------------------------------------------------------------------------
proc edit_modules_checkmodules { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array
  global system

  # Procedure to initialise/update the user's local modules.def file
  # If we are in the main area then this is unnecessary
  if { [string match [GetValue $arrayname LOCATION] MAIN] } {
    return
  }

  # Get the path name for the modules.def file
  set modules_file [edit_modules_getfilename $arrayname]

  if { [string trim $modules_file] == "" } {
    return
  }

  # If there is no modules.def file in the specified area
  # then offer to make a new one from the modules.def.dist file
  if { ![file exists $modules_file] } {
    set action [ ChooseOptionDialog "File Does Not Exist" "File Exists" \
	     "There is no modules.def file - do you want to create a new (empty)
modules.def file \"$modules_file\"?" \
	[list "Dismiss" "OK"] \
	-default 1 ]
    if { "$action" == "OK" } {
      if { [file exists [file join [GetEnvPath CCP4I_TOP] etc modules.def.dist]] } {
	CopyFile [file join [GetEnvPath CCP4I_TOP] etc modules.def.dist] \
		$modules_file
      } else {
	WarningMessage "Failed: couldn't find [file join [GetEnvPath CCP4I_TOP] etc modules.def.dist]"
      }
    }
  }
  # "Mirror" the list of modules in the main modules.def file
  set master_list \
	  [GetModuleList [file join \
	  [GetEnvPath CCP4I_TOP] etc modules.def]]
  foreach module $master_list {
    if {[AddModule $modules_file [lindex $module 0] [lindex $module 1]]} {
      Report 3 "Edit Modules: added module \"[lindex $module 1]\" to local modules.def file"
    }
  }

}

#------------------------------------------------------------------------------
proc edit_modules_updateallmenus { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  PleaseWait "Updating menus from modules.def file..."

  # Set the menus for list of existing modules
  edit_modules_updatemodulesmenu $arrayname NEW_TASK_MODULE
  edit_modules_updatemodulesmenu $arrayname NEW_MODULE_NEIGHBOUR
  edit_modules_updatemodulesmenu $arrayname DEL_TASK_MODULE
  edit_modules_updatemodulesmenu $arrayname DEL_MODULE_NAME
  edit_modules_updatemodulesmenu $arrayname UPDATE_MODULE
  edit_modules_updatemodulesmenu $arrayname UPDATE_TASK_MODULE
  edit_modules_updatemodulesmenu $arrayname NEW_FOLDER_MODULE
  edit_modules_updatemodulesmenu $arrayname DEL_FOLDER_MODULE
  edit_modules_updatemodulesmenu $arrayname UPDATE_FOLDER_MODULE

  edit_modules_updatealltasksmenu $arrayname ALLTASKS DEL_TASK_MODULE DEL_TASK_TITLE
  edit_modules_updatealltasksmenu $arrayname ALLTASKS2 UPDATE_TASK_MODULE \
      UPDATE_TASK
  edit_modules_updatetasksmenu $arrayname UPDATE_TASK_MODULE UPDATE_TASK \
	  "edit_modules_gettaskinfo $arrayname UPDATE_TASK_MODULE UPDATE_TASK UPDATE_TASK_FOLDER UPDATE_TASK_TITLE UPDATE_TASK_DESCRIPT"

  edit_modules_updatecontentmenu $arrayname ITEMS NEW_TASK_MODULE NEW_TASK_NEIGHBOUR
  edit_modules_updatecontentmenu $arrayname ITEMS2 NEW_FOLDER_MODULE NEW_FOLDER_NEIGHBOUR

  edit_modules_updatefoldermenu $arrayname FOLDERS NEW_TASK_MODULE NEW_TASK_FOLDER \
      "edit_modules_updatefoldertasksmenu $arrayname NEW_TASK_MODULE NEW_TASK_FOLDER NEW_TASK_FOLDERNEIGHBOUR"
  edit_modules_updatefoldertasksmenu $arrayname NEW_TASK_MODULE NEW_TASK_FOLDER \
      NEW_TASK_FOLDERNEIGHBOUR

  edit_modules_updatefoldermenu $arrayname FOLDERS3 UPDATE_FOLDER_MODULE UPDATE_FOLDER \
	  "edit_modules_getfolderinfo $arrayname UPDATE_FOLDER_MODULE UPDATE_FOLDER UPDATE_FOLDER_TITLE UPDATE_FOLDER_DESCRIPT"
  edit_modules_updatefoldermenu $arrayname FOLDERS2 DEL_FOLDER_MODULE DEL_FOLDER_TITLE

  edit_modules_gettaskinfo $arrayname UPDATE_TASK_MODULE UPDATE_TASK UPDATE_TASK_FOLDER UPDATE_TASK_TITLE UPDATE_TASK_DESCRIPT
  edit_modules_getfolderinfo $arrayname UPDATE_FOLDER_MODULE UPDATE_FOLDER UPDATE_FOLDER_TITLE UPDATE_FOLDER_DESCRIPT

  PleaseWait

  return
}

#------------------------------------------------------------------------------
proc edit_modules_checktaskfiles { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  # We can always include tasks in the main CCP4i area
  set task_dirs [file join [GetEnvPath CCP4I_TOP] tasks]

  # If installing in local area then include that too
  if {[string match [GetValue $arrayname LOCATION] LOCAL]} {
    lappend task_dirs [file join [GetSystemVar DOT] CCP4I_TOP tasks]
  }

  # For each area look for the task (.tcl) file
  foreach dir $task_dirs {
    set task_file "[file join $dir $array(NEW_TASK_NAME)].tcl"
    lappend file_list $task_file
  }
  foreach filen $file_list {
    if { [file exists $filen] } {
      if { [file isfile $filen] } {
        # The task file was found - return success
        return 1
      }
    }
  }
  # No file found - return failed
  return 0
}

#------------------------------------------------------------------------------
proc edit_modules_getmoduletitle { arrayname modulevar titlevar } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleList $modules_file]
  set curr_module [GetValue $arrayname $modulevar]
  foreach module $master_list {
      if { "$curr_module" == "[lindex $module 0]" } {
	  set array($titlevar) [lindex $module 1]
	  return
      }
  }
  set array($titlevar) ""
  return
}

#------------------------------------------------------------------------------
proc edit_modules_gettaskinfo { arrayname modulevar taskvar foldervar \
				    titlevar descriptvar } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleContentList $modules_file $array($modulevar)]
  set curr_task $array($taskvar)
  foreach task $master_list {
      if { [lindex $task 3] == "TASK" } {
	  # This is a top-level task
	  if { "$curr_task" == "[lindex $task 0]" } {
	      set array($titlevar) [lindex $task 0]
	      set array($descriptvar) [lindex $task 2]
	      set array($foldervar) {}
	      return
	  }
      } elseif { [lindex $task 3] == "FOLDER" } {
	  # This is a folder
	  set folder_name [lindex $task 0]
	  set folder_tasks [GetFolderContentList $modules_file \
				$array($modulevar) $folder_name]
	  foreach folder_task $folder_tasks {  
	      if { "$curr_task" == "<$folder_name> [lindex $folder_task 0]" } {
		  set array($titlevar) [lindex $folder_task 0]
		  set array($descriptvar) [lindex $folder_task 2]
		  set array($foldervar) $folder_name
		  return
	      }
	  }
      }  
  }
  set array($titlevar) ""
  set array($descriptvar) ""
  return
}

#------------------------------------------------------------------------------
proc edit_modules_getfolderinfo { arrayname modulevar foldervar \
				      titlevar descriptvar } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  set modules_file [edit_modules_getfilename $arrayname]
  set master_list [GetModuleContentList $modules_file $array($modulevar)]
  set current_folder $array($foldervar)
  foreach item $master_list {
      if { [lindex $item 3] == "FOLDER" } {
	  # This is a folder  
	  if { $current_folder == [lindex $item 0] } {
	      set array($titlevar) [lindex $item 0]
	      set array($descriptvar) [lindex $item 2]
	      return
	  }
      }
  }
  set array($titlevar) ""
  set array($descriptvar) ""
  return
}

#------------------------------------------------------------------------------
proc edit_modules_set_select_task_folder { arrayname } {
#------------------------------------------------------------------------------
# Set the value of the SELECT_TASK_FOLDER parameter based on the settings
# for adding a new task reference chosen by the user
# SELECT_TASK_FOLDER is an internal parameter that controls the visibility
# of the options for selecting where the new task reference will be located
# within a folder of a module.
  upvar #0 $arrayname array

  if { $array(N_FOLDERS) == 0 } {
      # No folders to put tasks into
      set array(SELECT_TASK_FOLDER) 0
      return
  }
  # Assume that there is at least one folder
  set array(SELECT_TASK_FOLDER) $array(NEW_TASK_IN_FOLDER)
}

#------------------------------------------------------------------------------
proc edit_modules_clear { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

    set array(NEW_MODULE_NAME) ""
    set array(NEW_MODULE_TITLE) ""
    set array(NEW_TASK_NAME) ""
    set array(NEW_TASK_TITLE) ""
    set array(NEW_TASK_DESCRIPT) ""
    set array(NEW_FOLDER_NAME) ""
    set array(NEW_FOLDER_TITLE) ""
    set array(NEW_FOLDER_DESCRIPT) ""
    return
}
