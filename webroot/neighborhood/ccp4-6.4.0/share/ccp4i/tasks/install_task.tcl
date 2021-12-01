#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#=======================================================================
# install_task.tcl --
#
# CCP4Interface 
#
# 
#========================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
# Only the "export" parameters are defined in the associated .def file
# (to allow the export options to be saved and restored); other
# parameters are defined internally in this procedure.
#---------------------------------------------------------------------
proc install_task_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname  array

  # Make sure we have the procedures available for editing the
  # modules.def and ccp4i_packages.def files
  source [SearchPath TOP src modules_utils.tcl]
  source [SearchPath TOP utils CCP4i_packages_utils.tcl]

  # Define menus of options
  #
  # Main installer options
  DefineMenu _install_option [list "install a new task" \
			            "uninstall an existing task" \
				    "import tasks from an old CCP4 version" \
				    "export a task"] \
				[ list INSTALL \
				       UNINSTALL \
				       IMPORT \
				       EXPORT ]

  # Locations of files or packages
  DefineMenu _install_location [list "user's local CCP4i" \
	                             "main CCP4i" ] \
				     [ list LOCAL \
				            MAIN]

  # Type of files
  DefineMenu _install_file_type [list "Task .tcl" \
	                              "Def .def" \
				      "Script .script" \
				      "templates .com" \
				      "help .html" ] \
				      [list TASKS \
				            TASKS \
					    SCRIPTS \
					    TEMPLATES \
					    HELP ]

  # Type of installation
  DefineMenu _install_type [list "automatic" "customised"] \
	                       [list AUTOMATIC CUSTOM]

  # How to specify exported tasks
  DefineMenu _install_export_selection [list "individual files" "base name and directory"] \
	  [list FILES BASE]

  # Define variable menus
  #
  # List of available tasks
  set typedef(_install_tasks)    [list varmenu TASKS_MENU TASKS_ALIAS 20]
  #
  # List of installed packages
  set typedef(_install_packages) [list varmenu PACKAGES_MENU PACKAGES_ALIAS 10]

  # Define remaining variables
  #
  # Installation parameters
  #
  DefineVariable $arrayname TASK_FILE           _gz_file         ""
  DefineVariable $arrayname DIR_TASK_FILE       _default_dirs    ""
  DefineVariable $arrayname INSTALL_DIR         _dir             ""
  DefineVariable $arrayname INSTALL_PACKAGE_NAME  _text          ""
  DefineVariable $arrayname INSTALL_VERSION     _text            ""
  # Prompt user before overwriting files?
  DefineVariable $arrayname CHECK_OVERWRITE     _logical         1
  # Files to install
  DefineVariable $arrayname N_FILES             _positiveint           0
  DefineVariable $arrayname INSTALL_FILE_DIR,0  _text                  ""
  DefineVariable $arrayname INSTALL_FILE,0      _text                  ""
  DefineVariable $arrayname INSTALL_SELECT,0    _logical               1
  # Installation script
  DefineVariable $arrayname INSTALL_SCRIPT      _text                  ""
  DefineVariable $arrayname RUN_INSTALL_SCRIPT  _logical               1
  # Task references to install in modules.def file
  DefineVariable $arrayname N_REFERENCES        _positiveint           0
  DefineVariable $arrayname TASK_NAME,0         _install_tasks         ""
  DefineVariable $arrayname TASK_TITLE,0        _text                  ""
  DefineVariable $arrayname TASK_DESCRIPT,0     _text                  ""
  DefineVariable $arrayname TASK_MODULE_NAME,0  _text                  ""
  DefineVariable $arrayname TASK_MODULE_TITLE,0 _text                  ""
  DefineVariable $arrayname TASK_FOLDER_NAME,0  _text                  ""
  DefineVariable $arrayname TASK_FOLDER_TITLE,0 _text                  ""
  DefineVariable $arrayname TASK_FOLDER_DESCRIPT,0 _text               ""
  # Menu of available tasks
  DefineVariable $arrayname TASKS_MENU          _list                  ""
  DefineVariable $arrayname TASKS_ALIAS         _list                  ""
  # Menu of available modules
  DefineVariable $arrayname N_MODULES           _positiveint           0

  #
  # Uninstall/review parameters
  #
  DefineVariable $arrayname UNINSTALL_PACKAGE _install_packages ""
  DefineVariable $arrayname REVIEW_VERSION    _text             ""
  DefineVariable $arrayname N_REVIEW_FILES    _positiveint      0
  DefineVariable $arrayname REVIEW_FILE_DIR,0 _text             ""
  DefineVariable $arrayname REVIEW_FILE,0     _text             ""
  DefineVariable $arrayname N_REVIEW_REFERENCES _positiveint    0
  DefineVariable $arrayname REVIEW_TASK_NAME,0 _text            ""
  DefineVariable $arrayname REVIEW_TASK_TITLE,0 _text           ""
  DefineVariable $arrayname REVIEW_TASK_DESCRIPT,0 _text        ""
  DefineVariable $arrayname REVIEW_MODULE_NAME,0 _text          ""
  DefineVariable $arrayname REVIEW_MODULE_TITLE,0 _text         ""
  DefineVariable $arrayname REVIEW_FOLDER_NAME,0 _text          ""
  DefineVariable $arrayname REVIEW_FOLDER_TITLE,0 _text    ""

  # List of packages for uninstall
  DefineVariable $arrayname N_PACKAGES          _positiveint           0
  DefineVariable $arrayname PACKAGES_MENU       _list                  ""
  DefineVariable $arrayname PACKAGES_ALIAS      _list                  ""

  # List of packages for import
  DefineVariable $arrayname N_IMPORT_PACKAGES   _positiveint           0
  DefineVariable $arrayname IMPORT_PACKAGE,0    _text                  ""
  DefineVariable $arrayname IMPORT_VERSION,0    _text                  ""
  DefineVariable $arrayname IMPORT_SELECTED,0   _logical               1

  # procedure must return sucess code (1) for drawing task window
  # to continue
  return 1
}

#-----------------------------------------------------------------------
proc install_task_UpdateInstallFileList { arrayname init_count sub_dir file_list } {
#-----------------------------------------------------------------------
# Build the list of install files to display in the extending frame
# sub_dir is the installation subdirectory e.g. tasks, scripts, templates
# file_list is a list of files to be installed there
#
# Returns the new value of counter
  upvar #0 $arrayname array
  global configure

  set counter $init_count
  foreach file $file_list {
      set file_path [file join $sub_dir [file tail $file]]
      incr counter
      set array(INSTALL_FILE_DIR,$counter) $sub_dir
      set array(INSTALL_FILE,$counter) [file tail $file]
  }

  # Update the extending frame with files to be installed
  install_task_UpdateNoaddlineFrame $arrayname N_FILES install_task_installfilelist \
	  [expr $counter - $array(N_FILES)]

  # Configure the varlabels for the widgets
  # i.e. set the width, background colour and relief explicitly
  for {set i 1} {$i<=$array(N_FILES)} {incr i} {
      set widget_name [GetWidget $arrayname INSTALL_FILE,$i]
      $widget_name config -width 30 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      set widget_name [GetWidget $arrayname INSTALL_FILE_DIR,$i]
      $widget_name config -width 10 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
  }
  return $counter
}

#-----------------------------------------------------------------------
proc install_task_UpdateReviewFileList { arrayname init_count file_list dir_list } {
#-----------------------------------------------------------------------
# Build the list of files to be reviewed (uninstalled) for display in an
# extending frame
# file_list is a list of files to be installed there
#
# Returns the new value of counter
  upvar #0 $arrayname array
  global configure

  set counter $init_count
  set nfiles [llength $file_list]
  if { [llength $dir_list] != $nfiles } {
      # Error if file list and dir list are different lengths
      return
  }
  for {set i 0} {$i<$nfiles} {incr i} {
      incr counter
      set array(REVIEW_FILE,$counter) [lindex $file_list $i]
      set array(REVIEW_FILE_DIR,$counter) [lindex $dir_list $i]
  }

  # Update the extending frame with the files that have been installed
  install_task_UpdateNoaddlineFrame $arrayname N_REVIEW_FILES install_task_reviewfilelist \
	  [expr $counter - $array(N_REVIEW_FILES)]

  # Configure the varlabels for the widgets
  # i.e. set the width, background colour and relief explicitly
  for {set i 1} {$i<=$array(N_REVIEW_FILES)} {incr i} {
      set widget_name [GetWidget $arrayname REVIEW_FILE,$i]
      $widget_name config -width 30 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      set widget_name [GetWidget $arrayname REVIEW_FILE_DIR,$i]
      $widget_name config -width 10 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
  }
  return $counter
}

#-----------------------------------------------------------------------
proc install_task_UpdateReviewRefList { arrayname init_count task_titles \
					    task_names task_descripts \
					    module_names module_titles \
					    { folder_names {} } { folder_titles {} } } {
#-----------------------------------------------------------------------
# Build the task reference list to display in an extending frame
  upvar #0 $arrayname array
  global configure

  set counter $init_count
  set nrefs [llength $task_names]

  # Check that the supplied lists are consistent with each other
  foreach var [list task_titles task_descripts module_names module_titles] {
    if { [llength [subst $[subst $var]]] != $nrefs } {
	# Error if task_names list has different length to other lists
	return
    }
  }
  # Update the parameters
  for {set i 0} {$i<$nrefs} {incr i} {
      incr counter
      set array(REVIEW_TASK_TITLE,$counter) [lindex $task_titles $i]
      set array(REVIEW_TASK_NAME,$counter)  [lindex $task_names $i]
      set array(REVIEW_TASK_DESCRIPT,$counter) [lindex $task_descripts $i]
      set array(REVIEW_MODULE_NAME,$counter)   [lindex $module_names $i]
      set array(REVIEW_MODULE_TITLE,$counter)  [lindex $module_titles $i]
      if { $folder_names != "" } {
	  set array(REVIEW_FOLDER_NAME,$counter) [lindex $folder_names $i]
	  set array(REVIEW_FOLDER_TITLE,$counter) [lindex $folder_titles $i]
      } else {
	  set array(REVIEW_FOLDER_NAME,$counter) {}
	  set array(REVIEW_FOLDER_TITLE,$counter) {}
      }
  }

  # Update the extending frame with the task references that have been installed
  install_task_UpdateNoaddlineFrame $arrayname N_REVIEW_REFERENCES \
	  install_task_reviewreflist [expr $counter - $array(N_REVIEW_REFERENCES)]

  # Configure the varlabels for the widgets
  # i.e. set the width, background colour and relief explicitly
  for {set i 1} {$i<=$array(N_REVIEW_REFERENCES)} {incr i} {
      set widget_names [GetWidget $arrayname REVIEW_TASK_NAME,$i]
      foreach widget_name $widget_names {
	  $widget_name config -width 10 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      }
      set widget_names [GetWidget $arrayname REVIEW_TASK_TITLE,$i]
      foreach widget_name $widget_names {
	  $widget_name config -width 20 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      }
      set widget_names [GetWidget $arrayname REVIEW_TASK_DESCRIPT,$i]
      foreach widget_name $widget_names {
	  $widget_name config -width 50 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      }
      set widget_names [GetWidget $arrayname REVIEW_MODULE_TITLE,$i]
      foreach widget_name $widget_names {
	  $widget_name config -width 20 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      }
      set widget_names [GetWidget $arrayname REVIEW_FOLDER_TITLE,$i]
      foreach widget_name $widget_names {
	  $widget_name config -width 20 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
      }
  }
  return $counter
}

#-----------------------------------------------------------------------
proc install_task_GetPackageName { task_file } {
#-----------------------------------------------------------------------
# Set the package name to be the root part of the file name
# NB the double invocation of the 'file rootname' command is
# not a typo - it is required to strip off .tar.gz type extensions
  return [file rootname [file rootname [file tail $task_file] ] ]
}

#-----------------------------------------------------------------------
proc install_task_GetModulesInTarget { arrayname menuVar aliasVar } {
#-----------------------------------------------------------------------
# Return lists of module names and titles in the menuVar and aliasVar
# variables, as derived from the modules.def file found in the target
# installation area
# Return the number of modules found

  upvar #0 $arrayname array
  upvar $menuVar modules_menu
  upvar $aliasVar modules_alias

  set modules_menu {}
  set modules_alias {}

  set modules_file \
	  [file join \
	  [GetTaskInstallFileDir [GetValue $arrayname INSTALL_LOCATION]] \
	  modules.def]
  # Build the variable menu listing the modules in the modules
  # file
  set master_list [GetModuleList $modules_file]

  if { [llength $master_list] > 0 } {
      foreach module $master_list {
	  lappend modules_menu [lindex $module 1]
	  lappend modules_alias [lindex $module 0]
      }
  }
  return [llength $master_list]
}

#-----------------------------------------------------------------------
proc install_task_GetFoldersInTarget { arrayname module menuVar aliasVar descrVar } {
#-----------------------------------------------------------------------
# Return lists of folder names and titles in the menuVar and aliasVar
# variables, as derived from the modules.def file found in the target
# installation area. The name of a module must also be supplied.
# Return the number of folders found

  upvar #0 $arrayname array
  upvar $menuVar folders_menu
  upvar $aliasVar folders_alias
  upvar $descrVar folders_descr

  set folders_menu {}
  set folders_alias {}
  set folders_descr {}

  set modules_file \
	  [file join \
	  [GetTaskInstallFileDir [GetValue $arrayname INSTALL_LOCATION]] \
	  modules.def]
  # Build the variable menu listing the modules in the modules
  # file
  set master_list [GetModuleContentList $modules_file $module]

  set n_folders 0
  if { [llength $master_list] > 0 } {
      foreach item $master_list {
	  if { [lindex $item 3] == "FOLDER" } {
	      lappend folders_menu [lindex $item 0]
	      lappend folders_alias [lindex $item 1]
	      lappend folders_descr [lindex $item 2]
	      incr n_folders
	  }
      }
  }
  return $n_folders
}

#-----------------------------------------------------------------------
proc install_task_GetTargetDir { arrayname } {
#-----------------------------------------------------------------------
# Set the explicit path for the target directory for installation
# This also builds the variable menu listing the modules in the
# current modules file, and the currently installed packages
  upvar #0 $arrayname array
  global system

  # For the list of packages
  # Find the correct PACKAGES file
  set packages_file [file join [GetTaskInstallFileDir \
	  [GetValue $arrayname INSTALL_LOCATION] ] ccp4i_packages.def]
  set packages_alias ""
  set packages_menu  ""
  if {[file exists $packages_file]} {
      set packages_menu [GetPackageList $packages_file]
      set packages_alias $packages_menu
  }
  # Update the variable menu
  set array(N_PACKAGES) [llength $packages_menu]
  UpdateVariableMenu $arrayname initialise 0 PACKAGES_MENU $packages_menu \
	  PACKAGES_ALIAS $packages_alias
  set array(UNINSTALL_PACKAGE) [lindex $array(PACKAGES_MENU) 0]
  return
}

#-----------------------------------------------------------------------
proc install_task_ExamineArchive { arrayname } {
#-----------------------------------------------------------------------
# When a tar file or a directory is selected then this procedure
# is automatically invoked to examine the contents
  upvar #0 $arrayname array

  ##puts "install_task_ExamineArchive invoked"

  # No action if the task file archive name is blank
  if { $array(TASK_FILE) == "" } { return }

  set task_archive [string trim [GetFullFileName0 $arrayname TASK_FILE]]

  # If the archive file doesn't exist then reset the displayed
  # parameters
  if { $task_archive != "" && ![file exists $task_archive] } {
    set array(INSTALL_PACKAGE_NAME) ""
    set array(INSTALL_VERSION) ""
    install_task_UpdateInstallFileList $arrayname 0 "" ""
    UpdateVariableMenu $arrayname initialise 0 TASKS_MENU "" TASKS_ALIAS ""
    UpdateExtendingFrame install_task_installreflist 0 $arrayname \
	  [expr 0 - $array(N_REFERENCES)]
    return
  }

  # Set the package name to be the root part of the file name
  set package_name [install_task_GetPackageName $array(TASK_FILE)]
  set array(INSTALL_PACKAGE_NAME) $package_name

  # Better put a waiting message - this might take a while
  PleaseWait "Examining task package archive file - this may take a moment"
  set master_list [ ExamineTaskArchive $package_name $task_archive \
	  examinepackages_array ]
  if { $master_list == "" } {
      WarningMessage "Failed to unpack and/or read contents of $task_archive
This may not be a valid CCP4i package."
      PleaseWait
      return
  }

  # Get information from packages file (if any)
  if { [info exists examinepackages_array(N_PACKAGES)] } {
      if { $examinepackages_array(N_PACKAGES) > 0 } {
	  set array(INSTALL_PACKAGE_NAME) $examinepackages_array(PACKAGE_NAME,1)
          set array(INSTALL_VERSION) $examinepackages_array(PACKAGE_VERSION,1)
          set array(INSTALL_SCRIPT) $examinepackages_array(PACKAGE_INSTALL_SCRIPT,1)
      }
  } else {
    # Reset version and install script, since there can't be any for
    # this package
    set array(INSTALL_VERSION) ""
    set array(INSTALL_SCRIPT) ""
  }

  PleaseWait

  # Retrieve list of modules from the target area
  set array(N_MODULES) [install_task_GetModulesInTarget $arrayname \
	  modules_names modules_titles]

  # Extract the contents of the package from master_list
  #
  # First get lists of the relevant files to be installed
  set task_list        [lindex $master_list 0]
  set tcl_file_list    [lindex $master_list 1]
  set def_file_list    [lindex $master_list 2]
  set script_file_list [lindex $master_list 3]
  set com_file_list    [lindex $master_list 4]
  set help_file_list   [lindex $master_list 5]
  #
  # Update the variable menu with the list of tasks
  UpdateVariableMenu $arrayname initialise 0 TASKS_MENU $task_list \
	  TASKS_ALIAS $task_list
  #
  # Now set up the lists of task references
  set task_ref_list    [lindex $master_list 6]
  set nref 0
  foreach task_ref $task_ref_list {
      incr nref
      set task_name     [lindex $task_ref 0]
      set task_title    [lindex $task_ref 1]
      set task_descript [lindex $task_ref 2]
      set task_module_name  [lindex $task_ref 3]
      set task_module_title [lindex $task_ref 4]
      #
      # There may also be folders in the module list
      if { [llength $task_ref] == 8 } {
	  set task_folder_name     [lindex $task_ref 5]
	  set task_folder_title    [lindex $task_ref 6]
	  set task_folder_descript [lindex $task_ref 7]
      } else {
	  set task_folder_name {}
	  set task_folder_title {}
	  set task_folder_descript {}
      }
      #
      set array(TASK_NAME,$nref)         $task_name
      set array(TASK_TITLE,$nref)        $task_title
      set array(TASK_DESCRIPT,$nref)     $task_descript
      set array(TASK_MODULE_NAME,$nref)  $task_module_name
      set array(TASK_MODULE_TITLE,$nref) $task_module_title
      set array(TASK_FOLDER_NAME,$nref)     $task_folder_name
      set array(TASK_FOLDER_TITLE,$nref)    $task_folder_title
      set array(TASK_FOLDER_DESCRIPT,$nref) $task_folder_descript
      #
      # Also record which modules are defined, in case
      # they are new
      if { [lsearch $modules_titles $task_module_title] < 0 } {
        incr array(N_MODULES)
        lappend modules_names $task_module_name
        lappend modules_titles $task_module_title
      }
  }

  # Reset the task references extending frame
  UpdateExtendingFrame install_task_installreflist 0 $arrayname \
	  [expr $nref - $array(N_REFERENCES)]

  # Rebuild list of install files in their extending frame
  # The install_task_UpdateInstallFileList proc automatically updates the extending
  # frame itself
  set counter 0
  set counter [install_task_UpdateInstallFileList $arrayname $counter tasks \
	  [concat $tcl_file_list $def_file_list]]
  set counter [install_task_UpdateInstallFileList $arrayname $counter scripts \
	  $script_file_list]
  set counter [install_task_UpdateInstallFileList $arrayname $counter templates \
	  $com_file_list]
  set counter [install_task_UpdateInstallFileList $arrayname $counter help \
	  $help_file_list]
  return
}

#---------------------------------------------------------------------
proc install_task_UpdateReviewFiles { arrayname } {
#---------------------------------------------------------------------
# This procedure is invoked whenever the user selects a package to
# uninstall or review
# It reads the information from the selected package and updates the
# display variables
  upvar #0 $arrayname array

  # Get the package file path
  set packages_file [file join \
	  [GetTaskInstallFileDir \
	  [GetValue $arrayname INSTALL_LOCATION]] ccp4i_packages.def]

  # Get the package name
  set package_name $array(UNINSTALL_PACKAGE)

  # Ignore unspecified packages
  if { $package_name == "" } { return }

  # Get the information from the PACKAGES file
  if { [lsearch [GetPackageList $packages_file] $package_name] < 0 } {
      WarningMessage "Cannot find package \"$package_name\""
      return
  }

  # Retrive the list of installed files
  set review_dirs ""
  set review_files ""
  set review_types [list TASKS SCRIPTS TEMPLATES HELP]
  foreach type $review_types {
      foreach filein [GetPackageFiles $packages_file $package_name $type] {
	  lappend review_files $filein
	  lappend review_dirs [string tolower $type]
      }
  }
  ##puts "Lists of files in package : $review_files"
  ##puts "Corresponding dirs:         $review_dirs"
  set nfiles [llength $review_files]
  if {$nfiles < 1} {
      WarningMessage "Package contains no files"
      return
  }

  # Update the lists of files and the extending frames
  set counter 0
  set counter [install_task_UpdateReviewFileList $arrayname $counter \
	  $review_files $review_dirs]

  # Update the lists of task references
  # The references are returned as list:
  # {task_title} {task_name} {task_descript} {module_name} {module_title}
  set review_task_titles ""
  set review_task_names ""
  set review_task_descripts ""
  set review_module_names ""
  set review_module_titles ""
  set review_folder_names ""
  set review_folder_titles ""
  set  review_folder_descripts ""
  foreach ref [GetPackageReferences $packages_file $package_name] {
    if { [llength $ref] == 5 || [llength $ref] == 8 } {
      lappend review_task_titles    [lindex $ref 0]
      lappend review_task_names     [lindex $ref 1]
      lappend review_task_descripts [lindex $ref 2]
      lappend review_module_names   [lindex $ref 3]
      lappend review_module_titles  [lindex $ref 4]
    }
    if { [llength $ref] == 8 } {
      lappend review_folder_names     [lindex $ref 5]
      lappend review_folder_titles    [lindex $ref 6]
      lappend review_folder_descripts [lindex $ref 7]
    } else {
      lappend review_folder_titles    {}
      lappend review_folder_names     {}
      lappend review_folder_descripts {}
    }
  }
  install_task_UpdateReviewRefList $arrayname 0 $review_task_titles \
	  $review_task_names $review_task_descripts $review_module_names \
	  $review_module_titles $review_folder_names $review_folder_titles

  # Update the version
  set array(REVIEW_VERSION) [GetPackageVersion $packages_file $package_name]
  if { $array(REVIEW_VERSION) == "" } {
    set array(REVIEW_VERSION) "\[None\]"
  }
}

#---------------------------------------------------------------------
proc install_task_InstallPackage { arrayname } {
#---------------------------------------------------------------------
# Procedure which is invoked to install files from an external package
#
# Checks for "bad" (ie nonexistant) source files
# Checks for overwritten files and issues a warning if requested
# Creates backup files for overwritten files
#
  upvar #0 $arrayname array

  # Update the modules menu
  install_task_GetTargetDir $arrayname 

  set task_archive [string trim [GetFullFileName0 $arrayname TASK_FILE]]
  ##puts "Task archive is \"$task_archive\""
  # Raise an error if the file doesn't exist
  if { $task_archive == "" || ![file exists $task_archive] } {
    WarningMessage "The specified task archive file doesn't exist:
\"$task_archive\"

Installation aborted."
    return
  }

  # Set the package name to be the root part of the file name
  set package_name $array(INSTALL_PACKAGE_NAME)
  if { [string trim $package_name] == "" } {
    WarningMessage "No package name specified
Installation aborted."
    return
  }
  ##puts "Package name is $package_name"

  # Check if this package has been installed in the past
  # If the package already exists then give the user the option
  # of aborting the installation
  set main_packages_file [file join \
	  [GetTaskInstallFileDir [GetValue $arrayname INSTALL_LOCATION]] ccp4i_packages.def]
  if { [lsearch [GetPackageList $main_packages_file] $package_name] > -1 } {
      set action [ChooseOptionDialog "Install: Package Name Exists" \
	      "Install Package" \
	      "A package with the name \"$package_name\" already exists" \
	      [list "Cancel" "Proceed"] -default 0 ]
      if { "$action" == "Cancel" } {
	  return
      }
  }

  # Check for overwritten files if requested
  if { $array(CHECK_OVERWRITE) } {
    # Not implemented!
  }

  # Do the installation
  if { [GetValue $arrayname INSTALL_TYPE] == "AUTOMATIC" } {
      # Automatic installation
      set install_status [InstallTaskPackage $package_name \
	      [GetValue $arrayname INSTALL_LOCATION] \
	      $task_archive -mode graphical]
  } else {
      # Custom install
      # Set the initial command
      lappend installcmd \
	      InstallTaskPackage $package_name [GetValue $arrayname INSTALL_LOCATION] \
	      $task_archive -mode graphical

      # Version
      if { $array(INSTALL_VERSION) != "" } {
	# Should check the version and warn at this point
        lappend installcmd "-version" $array(INSTALL_VERSION)
      } else {
	lappend installcmd "-version" ""
      }

      # Files
      set taskfile_list ""
      set comfile_list ""
      set scriptfile_list ""
      set helpfile_list ""
      for { set i 1 } { $i <= $array(N_FILES) } { incr i } {
        if { $array(INSTALL_SELECT,$i) } {
          switch -exact $array(INSTALL_FILE_DIR,$i) {
          "tasks" {
	    # Task files
            lappend taskfile_list $array(INSTALL_FILE,$i)
          }
          "scripts" {
	    # Script files
	    lappend scriptfile_list $array(INSTALL_FILE,$i)
          }
          "templates" {
	    # Com files
            lappend comfile_list $array(INSTALL_FILE,$i)
          }
          "help" {
	    # Help files
	    lappend helpfile_list $array(INSTALL_FILE,$i)
          }
        }
      }
    }
    lappend installcmd "-task_files" $taskfile_list \
	    "-script_files" $scriptfile_list \
	    "-com_files" $comfile_list \
	    "-help_files" $helpfile_list

    # Task references
    set references_list ""
    for { set i 1 } { $i <= $array(N_REFERENCES) } { incr i } {
      #
      set task_name     $array(TASK_NAME,$i)
      set task_title    $array(TASK_TITLE,$i)
      set task_descript $array(TASK_DESCRIPT,$i)
      #
      set module_name   $array(TASK_MODULE_NAME,$i)
      set module_title  $array(TASK_MODULE_TITLE,$i)
      #
      set folder_name   $array(TASK_FOLDER_NAME,$i)
      set folder_title  $array(TASK_FOLDER_TITLE,$i)
      set folder_descript $array(TASK_FOLDER_DESCRIPT,$i)
      #
      ##puts "Task reference information:"
      ##puts "TASK_NAME  \"$array(TASK_NAME,$i)\""
      ##puts "TASK_TITLE \"$array(TASK_TITLE,$i)\""
      ##puts "TASK_DESCRIPT \"$array(TASK_DESCRIPT,$i)\""
      ##puts "MODULE_NAME  \"$array(TASK_MODULE_NAME,$i)\""
      ##puts "MODULE_TITLE \"$array(TASK_MODULE_TITLE,$i)\""
      ##puts "FOLDER_NAME  \"$array(TASK_FOLDER_NAME,$i)\""
      ##puts "FOLDER_TITLE \"$array(TASK_FOLDER_TITLE,$i)\""
      ##puts "FOLDER_DESCRIPT \"$array(TASK_FOLDER_DESCRIPT,$i)\""
      #
      set taskref [list $task_name $task_title $task_descript \
		       $module_name $module_title]
      if { $folder_name != "" } {
	  # Also add the folder reference information
	  lappend taskref $folder_name $folder_title $folder_descript
      }
      lappend references_list $taskref
    }
    lappend installcmd "-task_references" $references_list

    # Install script
    if { $array(RUN_INSTALL_SCRIPT) } {
      if { $array(INSTALL_SCRIPT) != "" } {
        lappend installcmd "-install_script" $array(INSTALL_SCRIPT)
      }
    } else {
      lappend installcmd "-no_install_script"
    }

    # Execute the install command
    set install_status [eval $installcmd]
  }

  # Report the outcome of the installation
  if { $install_status } {
      WarningMessage "Installation of \"$package_name\" completed successfully"
  } else {
      WarningMessage "Installation of \"$package_name\" was not completed"
  }
  
  # Update the menus
  install_task_GetTargetDir $arrayname
  install_task_UpdateReviewFiles $arrayname
}

#---------------------------------------------------------------------
proc install_task_UninstallPackage { arrayname } {
#---------------------------------------------------------------------
# Procedure which is invoked to uninstall files from an external package
#
  upvar #0 $arrayname array

  # Find the correct PACKAGES file
  set packages_file [file join [GetTaskInstallFileDir \
	  [GetValue $arrayname INSTALL_LOCATION] ] ccp4i_packages.def]
  if {![file exists $packages_file]} {
      WarningMessage "No packages to uninstall"
      return
  }

  # Get the package name
  set package_name $array(UNINSTALL_PACKAGE)

  # Prompt the user before uninstalling
  set action [ChooseOptionDialog "Proceed with Uninstall?" "Uninstall" \
       "Are you sure you want to uninstall the tasks in \"$package_name\"?

All files and task references will be deleted!" \
		  [list "Proceed" "Cancel"] -default 2]
  if { [regexp Cancel $action] } {
     return
  }

  # Get the information from the PACKAGES file
  if { [lsearch [GetPackageList $packages_file] $package_name] < 0 } {
      WarningMessage "Cannot find package \"$package\" to uninstall"
      return
  }

  # Do the uninstallation by calling UninstallTaskPackage
  if { [UninstallTaskPackage $package_name [GetValue $arrayname INSTALL_LOCATION] \
	   -mode graphical] } {
      WarningMessage "Uninstallation of package \"$package_name\" completed"
  } else {
      WarningMessage "Uninstallation of package \"$package_name\" failed"
  }

  # Update menus
  install_task_GetTargetDir $arrayname
  install_task_UpdateReviewFiles $arrayname
  return
}

#---------------------------------------------------------------------
proc install_task_ExportPackage { arrayname } {
#---------------------------------------------------------------------
# Procedure which is invoked to export files to an external package
# This is a warpper to the ExportTaskPackage procedure so many of the
# checks are duplicated here

  upvar #0 $arrayname array

  # Do checks
  # Package name - should only contain letters, numbers and _
  set package_name $array(EXPORT_PACKAGE_NAME)
  if { [string match [string trim $package_name] ""] } {
      WarningMessage "The package name has not been specified"
      return
  }
  if { ![ValidatePackageName $package_name] } {
      WarningMessage "The package name \"$package_name\" is not valid
Package names can only contain letters, numbers and
the underscore character\n
Please enter a valid name"
      return
  }

  # Archive file
  set archive_file [GetFullFileName $array(EXPORT_TAR_FILE) $array(DIR_EXPORT_TAR_FILE)]
  if { [file exists $archive_file] } {
      if { ![file isdirectory $archive_file] } {
	  set action [ChooseOptionDialog "File exists" "Warning" \
		  "The output archive file \"$archive_file\" already exists\nDelete file and proceed?" \
		  [list "Delete File" "Cancel"] -default 2]
	  if { [regexp Cancel $action] } {
	      return
	  }
	  # Ok to delete the file
	  file delete $archive_file
      } else {
	  WarningMessage "The output archive file \"$archive_file\" is a directory
Please choose another file name"
	  return
      }
  }

  # Version string
  set package_version $array(EXPORT_VERSION)

  # Install script
  if { $array(EXPORT_INSTALL_SCRIPT) != "" } {
    set install_script [GetFullFileName $array(EXPORT_INSTALL_SCRIPT) \
	    $array(DIR_EXPORT_INSTALL_SCRIPT)]
    ##puts "Export install script = \"$install_script\""
    if { ![file exists $install_script] } {
      WarningMessage "The install script file \"$install_script\"
doesn't exist\n
Please specify a validate install script"
    }
  } else {
    set install_script ""
  }

  # Initialise for lists of files to export
  set task_list ""
  set n_tcl_files 0
  set files_exist 1
  #
  set task_files ""
  set script_files ""
  set com_files ""
  set help_files ""

  # Export based on base names
  if { [GetValue $arrayname EXPORT_SELECTION] == "BASE" } {
    # Build up the list of files from the base directory and base name
    set ntasks $array(N_EXPORT_BASE)
    if { $ntasks < 1 } {
      WarningMessage "You have not selected any tasks to include
so the package will be empty\n
Please select one or more tasks first"
      return
    }
    # Check each directory and base name and build lists of files to
    # export
    for {set i 1} {$i <= $ntasks} {incr i} {
       set task_name [string trim $array(EXPORT_BASE,$i)]
       set base_dir [string trim $array(EXPORT_BASE_DIR,$i)]
       foreach subdir { tasks tasks scripts templates } ext { tcl def script com } {
	   set filename "[file join $base_dir $subdir $task_name].$ext"
           if { [file exists $filename] } {
	       # Check the extension and append to the appropriate list
	       switch -exact -- [file extension $filename] {
		   ".tcl" {
		       # Tcl file
		       lappend task_files $filename
		       # Tcl files are special - do some more checks
		       incr n_tcl_files
		       set task_name [file rootname [file tail $filename]]
		       ##puts "This is for task \"$task_name\""
		       lappend task_list $task_name
		   }
		   ".def" {
		       # Def file
		       lappend task_files $filename
		   }
		   ".script" {
		       # Script file
		       lappend script_files $filename
		   }
		   ".com" {
		       # Template file
		       lappend com_files $filename
		   }
		   # End of switch
	       }
	       # End of if file exists
           }
	   # End of foreach
       }
       # End of loop over tasks
    }
    # End of if using base names
  }

  # Export based on files
  if { [GetValue $arrayname EXPORT_SELECTION] == "FILES" } {
    set nfiles $array(N_EXPORT_FILES)
    if { $nfiles < 1 } {
      WarningMessage "You have not selected any files to include
so the package will be empty\n
Please select one or more files first"
      return
    }
    # Check each file and build lists of files to export
    #
    for {set i 1} {$i <= $nfiles} {incr i} {
      set filename [string trim [GetFullFileName $array(EXPORT_FILE,$i) \
	      $array(EXPORT_SOURCE_DIR,$i)]]
      ##puts "Export file $i: $filename"
      # Does the file exist?
      if { ![file exists $filename] } {
	  set files_exist 0
      } else {
	  # Check the extension and append to the appropriate list
	  switch -exact -- [file extension $filename] {
	      ".tcl" {
		  # Tcl file
		  lappend task_files $filename
		  # Tcl files are special - do some more checks
		  incr n_tcl_files
		  set task_name [file rootname [file tail $filename]]
		  ##puts "This is for task \"$task_name\""
		  lappend task_list $task_name
	      }
	      ".def" {
		  # Def file
		  lappend task_files $filename
	      }
	      ".script" {
		  # Script file
		  lappend script_files $filename
	      }
	      ".com" {
		  # Template file
		  lappend com_files $filename
	      }
	      ".help" {
		  # Help file
		  lappend help_files $filename
	      }
	  }
      }
    }
    # Check for missing files
    if { $files_exist == 0 } {
      WarningMessage "One or more files specified for inclusion don't exist"
      return
    }
  }

  # Check that some task files were specified
  if { $n_tcl_files < 1 } {
      WarningMessage "You haven't specified any task (.tcl) files
This means there will be no tasks in the package\n
Please specify at least one task file"
      return
  }

  # Check the task references and build list of references to
  # export
  set reference_list ""
  #
  set task_ref_list ""
  set valid_text 1
  set n_extra 0
  set nrefs $array(N_EXPORT_REFS)
  for {set i 1} {$i <= $nrefs} {incr i} {
      set task_name $array(EXPORT_TASK_NAME,$i)
      # Does this correspond to a task in the package?
      if { [lsearch $task_list $task_name] < 0 } {
	  # Reference for a task which is not defined in this package
	  incr n_extra
      } else {
	  if { [lsearch $task_ref_list $task_name] < 0 } {
	      lappend task_ref_list $task_name
	  }
      }
      # Check the title and description aren't blank
      set task_title    $array(EXPORT_TASK_TITLE,$i)
      set task_descript $array(EXPORT_TASK_DESCRIPT,$i)
      if { [string match $task_title ""] || [string match $task_descript ""] } {
	  ##puts "Task title and/or description is empty"
	  set valid_text 0
      } else {
	  # Add to the list of references
	  # Look up the module name from the title
	  set modules_file \
	      [file join \
		   [GetTaskInstallFileDir [GetValue $arrayname INSTALL_LOCATION]] \
		   modules.def]
	  set module_ref [GetModule $modules_file $array(EXPORT_TASK_MODULE,$i)]
	  set module_name [lindex $module_ref 0]
	  set module_title [lindex $module_ref 1]
	  set task_reference [list $task_name $task_title $task_descript \
				  $module_name $module_title]
	  set folder_title $array(EXPORT_TASK_FOLDER,$i)
	  if { $folder_title != "" } {
	      # Look up the folder name and description
	      set folder_ref [GetFolderReference $modules_file \
				  $folder_title $module_name]
	      set folder_name  [lindex $folder_ref 0]
	      set folder_title [lindex $folder_ref 1]
	      set folder_desc  [lindex $folder_ref 2]
	      lappend task_reference $folder_name $folder_title $folder_desc   
	  }
	  lappend reference_list $task_reference
      }
  }
  # Check that all the tasks are referenced
  set n_missing 0
  foreach task_name $task_list {
      if { [lsearch $task_ref_list $task_name] < 0 } {
	  ##puts "Task $task_name is not referenced"
	  incr n_missing
      }
  }
  # Warn if there are problems
  if { $valid_text == 0 } {
      WarningMessage "One or more task titles and/or descriptions are blank"
      return
  }
  if { [llength $task_ref_list] < 1 } {
      WarningMessage "None of the task references refer to task files
in this package\n
Please supply at least one task reference per task file"
      return
  }
  if { $n_missing > 0 } {
      if { [regexp "^Cancel" [ChooseOptionDialog  \
	  "Check resolution limits" \
	  "Resolution" \
	  "$n_missing task(s) (corresponding to Tcl files)
do not appear to have task references defined\n
If this is correct then you can continue to export,
otherwise cancel and fix the problem first." \
				  [list "Cancel" "Continue"] -default 0]] } {
	  return
      }
  }
  if { $n_extra > 0 } {
      WarningMessage "There are $n_extra task references for tasks not
included in this package\n
Please supply task references only for those tasks that
are being exported"
      return
  }
  ##puts "Checked task references"

  # All checks completed - invoke ExportPackage
  if { ![ExportTaskPackage $package_name $archive_file -version $package_version \
	  -task_files $task_files -script_files $script_files \
	  -com_files $com_files -task_references $reference_list \
          -install_script $install_script -mode graphical] } {
      WarningMessage "Unable to export package"
      return
  } else {
      WarningMessage "Package \"$package_name\" exported successfully
to archive file $archive_file"
  }
}

#---------------------------------------------------------------------
proc install_task_ApplyImportPackages { arrayname } {
#---------------------------------------------------------------------
# Procedure which is invoked to import files previously installed in
# an arbitary CCP4 installation
#
  global system

  upvar #0 $arrayname array

  # Location for the tasks to be imported to
  set install_location [GetValue $arrayname INSTALL_LOCATION]

  # Location for the tasks to be imported from
  set ccp4_dir $array(IMPORT_DIRECTORY)

  set imported_packages {}
  set failed_packages {}

  # Loop over all the packages
  for { set i 1 } { $i <= $array(N_IMPORT_PACKAGES) } { incr i } {
      if { $array(IMPORT_SELECTED,$i) } {

	  # Import the package
	  set package $array(IMPORT_PACKAGE,$i)
	  if { [ImportTaskPackage $package $install_location $ccp4_dir \
		    -mode graphical] } {
	      lappend imported_packages $package
	  } else {
	      lappend failed_packages $package
	  }
      }
  }

  # Report any failures
  if { [llength $failed_packages] > 0 } {
      set report_message "WARNING:

Failed to import the following packages:\n"
      foreach package $failed_packages {
	  append report_message "\n * $package"
      }
  }

  # Report imports to the user
  set report_message "The following packages have been imported
into CCP4i from the CCP4 distribution at
$array(IMPORT_DIRECTORY):\n"
  foreach package $imported_packages {
      append report_message "\n * $package"
  }
  WarningMessage $report_message

  # Update menus
  install_task_GetTargetDir $arrayname
  install_task_UpdateReviewFiles $arrayname
  install_task_ImportPackages $arrayname
  return
}

#---------------------------------------------------------------------
proc install_task_exportfilelist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'export files' extending frame 
 upvar #0 $arrayname array 
 global configure

 CreateLine line \
         help task_archive_contents \
	 message "File to be included (must have .tcl, .def, .script or .com extension)" \
	 label "File $counter" \
	 widget EXPORT_SOURCE_DIR \
	 widget EXPORT_FILE -width 60 \
	 button "Browse.."

 $line.b4 configure -font $configure(FONT_SMALL)

 # bind picking of file browser icon to file browser utility
 add_command $line.b4 "FileDialog open $arrayname EXPORT_FILE,$counter EXPORT_SOURCE_DIR,$counter"
}

#---------------------------------------------------------------------
proc install_task_exportbaselist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'export task base names' extending frame 
 upvar #0 $arrayname array 
 global configure

 CreateLine line \
         help task_archive_contents \
	 message "Base name of task to be included" \
	 label "Task $counter: base name" \
	 widget EXPORT_BASE -width 15\
	 message "Directory with task, script and/or templates subdirectory holding task files" \
         label "base directory" \
	 widget EXPORT_BASE_DIR -width 40 \
	 button "Browse.."

 $line.b5 configure -font $configure(FONT_SMALL)

 # bind picking of file browser icon to file browser utility
 add_command $line.b5 "install_task_browse $arrayname $counter"
}

#--------------------------------------------------------------
proc install_task_browse { arrayname counter } {
#--------------------------------------------------------------
# Use the file browser to select a directory containg the files to
# be exported

  upvar #0 $arrayname array
  if { [SelectFile filename -directory] } {
    # The browser can return either a filename or a directory
    # name - make sure we get the leading directory in the
    # former case
    if { [file isdirectory [lindex $filename 0]] } {
      set dirname $filename
    } else {
      set dirname [file dirname [lindex $filename 0]]
    }
    # Update the parameters in the window
    set array(EXPORT_BASE_DIR,$counter) $dirname
  }
  return
}

#---------------------------------------------------------------------
proc install_task_reviewfilelist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'review files' extending frame 
 upvar #0 $arrayname array 

 CreateLine line \
	 message "Subdirectory of the CCP4i area where file will be installed" \
	 label "Directory:" \
	 varlabel REVIEW_FILE_DIR \
	 message "File to be installed" \
	 label "File:" \
	 varlabel REVIEW_FILE
}

#---------------------------------------------------------------------
proc install_task_reviewreflist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'review references' extending frame 
 upvar #0 $arrayname array 

 CreateLine line \
	 label "Task" \
	 varlabel REVIEW_TASK_NAME \
         label "was installed in the" \
         varlabel REVIEW_MODULE_TITLE \
	 label "module" \
         toggle_display REVIEW_FOLDER_TITLE,$counter open { "" }

 CreateLine line \
	 label "Task" \
	 varlabel REVIEW_TASK_NAME \
         label "was installed in the" \
         varlabel REVIEW_MODULE_TITLE \
	 label "module in the" \
         varlabel REVIEW_FOLDER_TITLE \
         label "folder" \
         toggle_display REVIEW_FOLDER_NAME,$counter hide { "" }

 CreateLine line \
	 label "Task title:" \
	 varlabel REVIEW_TASK_TITLE \
	 label "Description:" \
	 varlabel REVIEW_TASK_DESCRIPT
}

#---------------------------------------------------------------------
proc install_task_installfilelist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'install files' extending frame 
 upvar #0 $arrayname array 

 CreateLine line \
	 message "Subdirectory of the CCP4i area where file will be installed" \
	 label "SubDirectory:" \
	 varlabel INSTALL_FILE_DIR \
	 message "File to be installed" \
	 label "File:" \
	 varlabel INSTALL_FILE \
	 label "Install" \
         help automatic_or_custom \
	 widget INSTALL_SELECT
}

#---------------------------------------------------------------------
proc install_task_installreflist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'install task references' extending
#frame 
 upvar #0 $arrayname array

 CreateLine line \
     help task_archive_contents \
     message "Name of task file" \
     label "Task" \
     widget TASK_NAME \
     label "will be added to the" \
     message "Name of module to add the task to (choose using the Change button)" \
     varlabel TASK_MODULE_TITLE \
     label "module" \
     button "Change module" \
     -command "install_task_choosemodule $arrayname TASK_MODULE_TITLE,$counter TASK_FOLDER_TITLE,$counter TASK_MODULE_NAME,$counter TASK_FOLDER_NAME,$counter TASK_FOLDER_DESCRIPT,$counter" \
     toggle_display TASK_FOLDER_TITLE,$counter open { "" }
 # Customise varlabels and button positioning
 pack forget $line.b6
 pack $line.b6 -side right
 $line.l4 configure -relief sunken -width 25

 CreateLine line \
     help task_archive_contents \
     message "Name of task file" \
     label "Task" \
     widget TASK_NAME \
     label "will be added to the" \
     message "Name of module to add the task to (choose using the Change button)" \
     varlabel TASK_MODULE_TITLE \
     label "module in the" \
     message "Name of folder to add the task to (choose using the Change button)" \
     varlabel TASK_FOLDER_TITLE \
     label "folder" \
     button "Change module" \
     -command "install_task_choosemodule $arrayname TASK_MODULE_TITLE,$counter TASK_FOLDER_TITLE,$counter TASK_MODULE_NAME,$counter TASK_FOLDER_NAME,$counter TASK_FOLDER_DESCRIPT,$counter" \
     toggle_display TASK_FOLDER_TITLE,$counter hide { "" }
 # Customise varlabels and button positioning
 pack forget $line.b8
 pack $line.b8 -side right
 $line.l4 configure -relief sunken -width 25
 $line.l6 configure -relief sunken -width 15

 CreateLine line \
         help task_archive_contents \
	 message "The title text will appear on the button to launch the task" \
	 label "Task title:" widget TASK_TITLE -width 25 \
	 message "The description text for the task will appear in the message help line of the main CCP4i window" \
	 label "Description:" widget TASK_DESCRIPT -width 50
}

#---------------------------------------------------------------------
proc install_task_exporttasklist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'export task references' extending
#frame 
 upvar #0 $arrayname array

 CreateLine line \
         help task_archive_contents \
	 message "Name of task file" \
	 label "Task" \
	 widget EXPORT_TASK_NAME \
	 label "will be added to the" \
	 message "Name of module to add the task to (choose using the Select button)" \
	 varlabel EXPORT_TASK_MODULE \
	 label "module" \
         button "Select module" \
              -command "install_task_choosemodule $arrayname EXPORT_TASK_MODULE,$counter EXPORT_TASK_FOLDER,$counter" \
     toggle_display EXPORT_TASK_FOLDER,$counter open { "" }
 # Customise varlabels and button positioning
 pack forget $line.b6
 pack $line.b6 -side right
 $line.l4 configure -relief sunken -width 25

 CreateLine line \
         help task_archive_contents \
	 message "Name of task file" \
	 label "Task" \
	 widget EXPORT_TASK_NAME \
	 label "will be added to the" \
	 message "Name of module to add the task to (choose using the Select button)" \
	 varlabel EXPORT_TASK_MODULE \
	 label "module in the" \
         message "Name of folder to add the task to (choose using the Select button)" \
         varlabel EXPORT_TASK_FOLDER \
         label "folder" \
         button "Select module" \
              -command "install_task_choosemodule $arrayname EXPORT_TASK_MODULE,$counter EXPORT_TASK_FOLDER,$counter" \
     toggle_display EXPORT_TASK_FOLDER,$counter hide { "" }
 # Customise varlabels and button positioning
 pack forget $line.b8
 pack $line.b8 -side right
 $line.l4 configure -relief sunken -width 25
 $line.l6 configure -relief sunken -width 15

 CreateLine line \
         help task_archive_contents \
	 message "The title text will appear on the button to launch the task" \
	 label "Task title:" widget EXPORT_TASK_TITLE -width 25 \
	 message "The description text for the task will appear in the message help line of the main CCP4i window" \
	 label "Description:" widget EXPORT_TASK_DESCRIPT -width 50

}

# procedure to draw task window
#---------------------------------------------------------------------
proc install_task_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  set helpfile [SearchPath HELP general install.html ]

  if { [CreateTaskWindow $arrayname  \
        "Install (uninstall) CCP4i tasks" "Install Task" \
        [ list "Install Package Information" \
	       "Install Files" \
	       "Install Task References" \
	       "Choose Task to Uninstall" \
	       "Review Package Information" \
	       "Review Task Files" \
	       "Review Task References" \
	       "Export Task Information" \
	       "Export Files" \
	       "Export Task References" \
               "Packages Available for Import" ] \
	       -action_buttons { save quit } \
	       -help_file $helpfile ] == 0 } return

  set savebutton [button $array(WINDOW).buttons.save\
                -text "Apply" \
                -relief raised  \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
		-command "install_task_apply $arrayname"]

  pack $savebutton -side left -expand 1

  # Do this once at the start to initialise packages and modules
  install_task_GetTargetDir $arrayname

#=PROTOCOL==============================================================

  SetProgramHelpFile $helpfile

  OpenFolder protocol 

  CreateLine line \
        message "Install, uninstall, export (for developers) or import tasks" \
        help install_options \
	label "Run the Installation Manager to" \
        widget INSTALL_OPTION

  CreateLine line \
        help automatic_or_custom \
	label "Perform" \
	message "Choose automatic (minimal user input required, recommended) or customised installation" \
	widget INSTALL_TYPE \
	label "installation of tasks into" \
	message {Install into main CCP4i area (\$CCP4I_TOP) or user's private area (\$USER/.CCP4/CCP4I_TOP)} \
        help install_area \
        widget INSTALL_LOCATION -command "install_task_GetTargetDir $arrayname" \
	label "area" \
	toggle_display INSTALL_OPTION open [list INSTALL]

  CreateLine line \
        help install_area \
	label "Uninstall task from" \
	message {Install into main CCP4i area (\$CCP4I_TOP) or user's private area (\$USER/.CCP4/CCP4I_TOP)} \
        widget INSTALL_LOCATION -command "install_task_GetTargetDir $arrayname ; install_task_UpdateReviewFiles $arrayname" \
	label "area" \
        toggle_display INSTALL_OPTION open [list UNINSTALL]

  OpenSubFrame frame -toggle_display INSTALL_OPTION open [list IMPORT]

  CreateLine line \
        help install_area \
	label "Import tasks into" \
	message {Install into main CCP4i area (\$CCP4I_TOP) or user's private area (\$USER/.CCP4/CCP4I_TOP)} \
        widget INSTALL_LOCATION -command "install_task_GetTargetDir $arrayname ; install_task_UpdateReviewFiles $arrayname" \
	label "area"

  CreateLine line \
      label "Specify top-level directory or folder of older CCP4 version e.g. /xtal/ccp4-6.0" -italic

  CreateLine line \
      message "Specify top-level directory or folder of old CCP4 version" \
      label "Old CCP4 directory:" \
      widget IMPORT_DIRECTORY -width 60 \
      -command "install_task_ImportPackages $arrayname"

  # Make a "browse" button to allow the user to select directories
  # via the browser
  # This is a custom widget!
  set browse [button $line.browse -text "Browse" \
		  -command "install_task_browse_oldccp4 $arrayname IMPORT_DIRECTORY ; install_task_ImportPackages $arrayname"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left

  CloseSubFrame
	
#=FILES================================================================ 

  ##OpenFolder file

#=Folder 1========================================Install package information

  OpenFolder 1 INSTALL_OPTION open [list INSTALL] hide

  CreateInputFileLine line \
	  "Specify directory or tarred file or tarred, gzipped file" \
	  "Task archive" TASK_FILE DIR_TASK_FILE \
	  -command "install_task_ExamineArchive $arrayname" \
	  -help task_archive

  CreateLine line \
          help ccp4i_packages_file \
	  message "The package name will be used to identify the files in future" \
	  label "Name of package:" \
	  widget INSTALL_PACKAGE_NAME -oblig -width 30 \
	  message "The version string can be used to track different revisions of a task"\
	  label "Version:" \
	  widget INSTALL_VERSION

  ##CreateLine line \
  ##        message "Author name(s)" \
  ##        label "Author(s)" \
	##  widget INSTALL_AUTHOR

  ##CreateLine line \
  ##        message "Further information URL:" \
	##  widget INSTALL_URL

#=Folder 2========================================Files to be installed

  OpenFolder 2 INSTALL_OPTION open [list INSTALL] hide

  OpenSubFrame frame -toggle_display INSTALL_TYPE open [list CUSTOM] hide

  CreateLine line label "Select which files will be installed from this package" \
	  -italic

  CreateExtendingFrame N_FILES install_task_installfilelist \
	  "List of files to be installed" \
	  "Add another?" \
	  [ list INSTALL_FILE_DIR INSTALL_FILE INSTALL_SELECT ] -noaddline

  CloseSubFrame

  CreateLine line \
	  label "All files in the package will be installed automatically" \
	  toggle_display INSTALL_TYPE open [list AUTOMATIC]

  ##CreateLine line \
	##  widget CHECK_OVERWRITE \
	##  label "Prompt user for confirmation before overwriting files"

  # Initialise the extending frame
  install_task_InitialiseNoaddlineFrame $arrayname N_FILES install_task_installfilelist

  CreateLine line \
          label "The following install script will be run before the installation" \
	  -italic \
          toggle_display INSTALL_TYPE hide [list AUTOMATIC]

  CreateLine line \
          help install_scripts \
          message "Run the install script before the installation is performed?" \
          widget RUN_INSTALL_SCRIPT \
          label "Install script:" \
          varlabel INSTALL_SCRIPT \
          toggle_display INSTALL_TYPE hide [list AUTOMATIC]

  set widget_name [GetWidget $arrayname INSTALL_SCRIPT]
  $widget_name config -width 50 -background $configure(COLOUR_BACKGROUND) \
	  -relief sunken

#=Folder 3========================================Install task references

  OpenFolder 3 INSTALL_OPTION open [list INSTALL] hide

  OpenSubFrame frame -toggle_display INSTALL_TYPE open [list CUSTOM] hide

  CreateLine line label \
	  "The following task references will be added to the modules file:" -italic

  CreateExtendingFrame N_REFERENCES install_task_installreflist \
	  "List of task references to be added to the modules file" \
	  "Add another?" \
	  [ list TASK_NAME \
		TASK_MODULE_NAME \
		TASK_MODULE_TITLE \
		TASK_FOLDER_NAME \
		TASK_FOLDER_TITLE \
		TASK_FOLDER_DESCRIPT ]

  CloseSubFrame

  CreateLine line \
	  label "Task references will be added automatically for this task" \
	  toggle_display INSTALL_TYPE open [list AUTOMATIC] hide

#=Folder 4========================================Choose uninstall package

  OpenFolder 4 INSTALL_OPTION open [list UNINSTALL] hide

  CreateLine line label "No packages are currently registered" \
	  toggle_display N_PACKAGES open [list 0]

  CreateLine line \
          help uninstall_tasks \
	  label "Uninstall package" \
	  widget UNINSTALL_PACKAGE -width 30 \
	  -command "install_task_UpdateReviewFiles $arrayname" \
	  toggle_display N_PACKAGES hide [list 0]

#=Folder 5========================================Review uninstall package info

  OpenFolder 5 INSTALL_OPTION open [list UNINSTALL] hide

  CreateLine line label "No packages are currently registered" \
	  toggle_display N_PACKAGES open [list 0]

  OpenSubFrame frame -toggle_display N_PACKAGES hide [list 0] open

  CreateLine line \
	  label "Currently installed version" \
	  varlabel REVIEW_VERSION

  CloseSubFrame

#=Folder 6========================================Review uninstall package files

  OpenFolder 6 INSTALL_OPTION open [list UNINSTALL] hide

  CreateLine line label "No packages are currently registered" \
	  toggle_display N_PACKAGES open [list 0]

  OpenSubFrame frame -toggle_display N_PACKAGES hide [list 0] open

  CreateLine line label \
	  "The following files are registered as part of this package" -italic

  CreateExtendingFrame N_REVIEW_FILES install_task_reviewfilelist \
	  "List of files in this package" \
	  "Add another?" \
	  [ list REVIEW_FILE_DIR REVIEW_FILE ] -noaddline

  CloseSubFrame

  # Initialise the extending frame
  install_task_InitialiseNoaddlineFrame $arrayname N_REVIEW_FILES \
	  install_task_reviewfilelist

#=Folder 7========================================Review uninstall package refs

  OpenFolder 7 INSTALL_OPTION open [list UNINSTALL] hide

  CreateLine line label "No packages are currently registered" \
	  toggle_display N_PACKAGES open [list 0]

  OpenSubFrame frame -toggle_display N_PACKAGES hide [list 0] open

  CreateLine line label \
	  "The following task references are registered as part of this package" -italic

  CreateExtendingFrame N_REVIEW_REFERENCES install_task_reviewreflist \
	  "List of files in this package" \
	  "Add another?" \
	  [ list REVIEW_TASK_NAME \
	  REVIEW_TASK_TITLE \
	  REVIEW_TASK_DESCRIPT \
	  REVIEW_MODULE_NAME \
	  REVIEW_MODULE_TITLE \
	  REVIEW_FOLDER_NAME \
          REVIEW_FOLDER_TITLE ] -noaddline

  CloseSubFrame

  # Initialise the extending frame
  install_task_InitialiseNoaddlineFrame $arrayname N_REVIEW_REFERENCES \
	  install_task_reviewreflist

#=Folder 8========================================Settings for Export

  OpenFolder 8 INSTALL_OPTION open [list EXPORT] hide

  CreateLine line \
          help ccp4i_packages_file \
	  message "The package name will be used to identify the files in future" \
	  label "Name of package:" \
	  widget EXPORT_PACKAGE_NAME -oblig -width 30 \
	  -command "install_task_UpdateExportFilename $arrayname" \
	  message "(Optional) The version string can be used to track different revisions of a task"\
	  label "Version:" \
	  widget EXPORT_VERSION \
	  -command "install_task_UpdateExportFilename $arrayname"

  CreateOutputFileLine line \
     "Specify name of tarred gzip (.tar.gz extension) archive file to be created" \
     "Archive file"  EXPORT_TAR_FILE DIR_EXPORT_TAR_FILE \
     -help task_archive

  CreateInputFileLine line \
    "(Optional) Specify a script to run before installing the task interface" \
    "Install script:" EXPORT_INSTALL_SCRIPT DIR_EXPORT_INSTALL_SCRIPT \
    -help install_scripts

#=Folder 9========================================Files for Export

  OpenFolder 9 INSTALL_OPTION open [list EXPORT] hide

  CreateLine line label "Select files to include in this package" -italic

  CreateLine line \
     label "Select task files as" \
     widget EXPORT_SELECTION

  OpenSubFrame frame -toggle_display EXPORT_SELECTION open { FILES }

  CreateExtendingFrame N_EXPORT_FILES install_task_exportfilelist \
	  "List of files to be included" \
	  "Add another?" \
	  [ list EXPORT_SOURCE_DIR EXPORT_FILE ]

  CloseSubFrame

  OpenSubFrame frame -toggle_display EXPORT_SELECTION open { BASE }

  CreateExtendingFrame N_EXPORT_BASE install_task_exportbaselist \
	  "List of tasks to be included" \
	  "Add another?" \
	  [ list EXPORT_BASE_DIR EXPORT_BASE ]

  CloseSubFrame


#=Folder 10========================================Task references for Export

  OpenFolder 10 INSTALL_OPTION open [list EXPORT] hide

  CreateLine line label "Define entries for the modules files for this package" -italic

  CreateExtendingFrame N_EXPORT_REFS install_task_exporttasklist \
	  "List of files to be installed" \
	  "Add another?" \
	  [ list EXPORT_TASK_NAME EXPORT_TASK_MODULE EXPORT_TASK_TITLE \
	  EXPORT_TASK_DESCRIPT EXPORT_TASK_FOLDER]

#=Folder 11========================================View available import packages

  OpenFolder 11 INSTALL_OPTION open [list IMPORT] hide

  CreateLine line label "No packages available for import" \
	  toggle_display N_IMPORT_PACKAGES open [list 0]

  OpenSubFrame frame -toggle_display N_IMPORT_PACKAGES hide [list 0]

  CreateLine line label \
	  "The following packages are available for import" -italic

  CreateExtendingFrame N_IMPORT_PACKAGES install_task_importpackagelist \
	  "List of packages available for import" \
	  "Add another?" \
	  [ list IMPORT_PACKAGE IMPORT_VERSION IMPORT_SELECTED] -noaddline

  CloseSubFrame

  CreateLine line label \
	  "Note that any packages already installed are not shown" -italic

  # Initialise the extending frame
  install_task_InitialiseNoaddlineFrame $arrayname N_IMPORT_PACKAGES \
	  install_task_importpackagelist

  # Initialise the list of files to review for uninstallation
  install_task_UpdateReviewFiles $arrayname

  # Initialise the list of packages for import
  install_task_ImportPackages $arrayname

}

#-----------------------------------------------------------------------
proc install_task_apply { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

    # Action depends on the options chosen
    switch [GetValue $arrayname INSTALL_OPTION] {
	INSTALL {
	    # Invoke the installation procedure
	    install_task_InstallPackage $arrayname
	}
	UNINSTALL {
	    # Invoke the uninstall procedure
	    install_task_UninstallPackage $arrayname
	}
	EXPORT {
	    # Invoke the uninstall procedure
	    install_task_ExportPackage $arrayname
	}
	IMPORT {
	    # Invoke the import procedure
	    install_task_ApplyImportPackages $arrayname
	}
    }

  # Reload the task lists in the main window
  ReloadTasklists .module.menu.module.mb.m moduledef

  # Need a ChooseOptionDialog to decide whether to perform another
  # action or exit immediately?

  return 1
}

#-----------------------------------------------------------------------
proc install_task_UpdateExportFilename { arrayname } {
#-----------------------------------------------------------------------
# Reset the name of the archive file name for export based on the
# package name
  upvar #0 $arrayname array
  if { $array(EXPORT_PACKAGE_NAME) != "" } {
    set array(EXPORT_TAR_FILE) $array(EXPORT_PACKAGE_NAME)
    if { $array(EXPORT_VERSION) != "" } {
      append array(EXPORT_TAR_FILE) "_" $array(EXPORT_VERSION)
    }
    append array(EXPORT_TAR_FILE) ".tar.gz"
  }
}

#-----------------------------------------------------------------------
proc install_task_InitialiseNoaddlineFrame { arrayname CounterVar DefLineProc } {
#-----------------------------------------------------------------------
# Initialise an extending frame with a -noaddline option, when that frame
# is not a dependent frame.
# CounterVar = the parameter in the array controlling the number of lines
# in the extending frame
# DefLineProc = the procedure which creates one line of the extending frame

  upvar #0 $arrayname array
  if { $array($CounterVar) > 0 } {
    set counter $array($CounterVar)
    set array($CounterVar) 0
    for { set i 0 } { $i < $counter } { incr i } {
      append_extend_frame $arrayname $DefLineProc
      incr array($CounterVar)
    }
  }
}

#-----------------------------------------------------------------------
proc install_task_UpdateNoaddlineFrame { arrayname CounterVar DefLineProc increment } {
#-----------------------------------------------------------------------
# Update an extending frame with a -noaddline option, when that frame
# is not a dependent frame.
# CounterVar = the parameter in the array controlling the number of lines
# in the extending frame
# DefLineProc = the procedure which creates one line of the extending frame

  upvar #0 $arrayname array

  # Redraw the extending frame manually
  if { $increment > 0 } {
    # Add frames
    for { set i 0 } { $i < $increment } { incr i } {
      append_extend_frame $arrayname $DefLineProc 0
      incr array($CounterVar)
    }
  } elseif { $increment < 0 } {
    # Delete frames
    for { set i 0 } { $i > $increment } { incr i -1 } {
      delete_frame $arrayname $DefLineProc 0
      incr array($CounterVar) -1
    }
  }

  # Update the scrollable extent of the window
  # PJX: This code borrowed from update_extendingframe in exframe.tcl
  # I'm not really sure how or why it works
  append def_proc $DefLineProc _0
  set frame $array(FRAME_$def_proc)
  SetSystemVar block_scroll_update 0
  update_main_scroll $frame 

}

#--------------------------------------------------------------
proc install_task_browse_oldccp4 { arrayname item } {
#--------------------------------------------------------------
# Use the file browser to select a directory with an older CCP4
# version

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
    set array($item) $dirname
  }
  return
}

#--------------------------------------------------------------
proc install_task_ImportPackages { arrayname } {
#--------------------------------------------------------------
# Procedure that looks up the packages that are installed in an
# arbitrary CCP4 installation

  global system
  upvar \#0 $arrayname array

  if { $array(IMPORT_DIRECTORY) == "" } {
      # Nothing to look for
      return
  }

  # Look for the PACKAGES file for the old CCP4 version
  # It should be in $CCP4/ccp4i/etc/UNIX/ccp4i_packages.def
  # (or Windows equivalent)
  set old_packages_file [file join $array(IMPORT_DIRECTORY) ccp4i etc \
			 $system(OPSYS) ccp4i_packages.def]
  if { ![file exists $old_packages_file] } {
      set old_packages_file [file join $array(IMPORT_DIRECTORY) ccp4i etc \
                             ccp4i_packages.def]
  }
  if { ![file exists $old_packages_file] } {
      WarningMessage "No installed packages file found!\nThe packages file:\n\n$old_packages_file\n\nwas not found"
      return
  }

  # Acquire the package information
  install_task_UpdateImportPackages $arrayname $old_packages_file
}

#---------------------------------------------------------------------
proc install_task_UpdateImportPackages { arrayname old_packages_file } {
#---------------------------------------------------------------------
# This procedure is invoked whenever the user selects an old CCP4
# installation to retrieve packages to import from
  upvar #0 $arrayname array

  # Retreive the list of available packages
  set package_list [GetPackageList $old_packages_file]
  if { [set n_packages [llength $package_list]] < 1 } {
      WarningMessage "No packages found for import"
      return
  }

  # Update the list of packages in the extending frame
  set counter 0
  set counter [install_task_UpdateImportPackageList $arrayname $counter \
		   $package_list $old_packages_file]
}

#-----------------------------------------------------------------------
proc install_task_UpdateImportPackageList { arrayname init_count \
						package_list packages_file} {
#-----------------------------------------------------------------------
# Build the list of packages available for import in extending frame
# package_list is a list of package names
#
# Returns the new value of counter
  upvar #0 $arrayname array
  global configure

  # Look up packages already installed
  set install_packages_file [file join [GetTaskInstallFileDir \
	  [GetValue $arrayname INSTALL_LOCATION] ] ccp4i_packages.def]
  if { [file exists $install_packages_file] } {
      set installed_packages [GetPackageList $install_packages_file]
  } else {
      set installed_packages {}
  }

  set counter $init_count
  set npackages [llength $package_list]
  for {set i 0} {$i<$npackages} {incr i} {
      set package_name [lindex $package_list $i]
      # Check to see if a version of this package is already installed
      if { [lsearch $installed_packages $package_name] < 0 } {
	  incr counter
	  set array(IMPORT_PACKAGE,$counter) $package_name
	  set array(IMPORT_VERSION,$counter) \
	      [GetPackageVersion $packages_file $package_name]
	  if { $array(IMPORT_VERSION,$counter) == "" } {
	      set array(IMPORT_VERSION,$counter) "<None>"
	  }
      }
  }

  # Update the extending frame with the files that have been installed
  install_task_UpdateNoaddlineFrame $arrayname N_IMPORT_PACKAGES \
      install_task_importpackagelist \
      [expr $counter - $array(N_IMPORT_PACKAGES)]

  # Configure the varlabels for the widgets
  # i.e. set the width, background colour and relief explicitly
  for {set i 1} {$i<=$array(N_IMPORT_PACKAGES)} {incr i} {
      set widget_name [GetWidget $arrayname IMPORT_PACKAGE,$i]
      $widget_name config -width 20 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
  }
  for {set i 1} {$i<=$array(N_IMPORT_PACKAGES)} {incr i} {
      set widget_name [GetWidget $arrayname IMPORT_VERSION,$i]
      $widget_name config -width 10 -background $configure(COLOUR_BACKGROUND) \
	      -relief sunken
  }
  return $counter
}

#---------------------------------------------------------------------
proc install_task_importpackagelist { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'import packages' extending frame
 upvar #0 $arrayname array 

 CreateLine line \
     message  "Check this box to select the package to be imported" \
     widget IMPORT_SELECTED \
     label "Package:" \
     varlabel IMPORT_PACKAGE \
     label " version:" \
     varlabel IMPORT_VERSION \
}


#-----------------------------------------------------------------------
proc install_task_choosemodule { arrayname modulevar foldervar \
				     { modulenamVar "" } { foldernamVar "" } \
				     { folderdesVar "" } } {
#-----------------------------------------------------------------------
# Pop up a window to choose a module and a folder to install a
# task into
# modulevar is the parameter storing the module title in arrayname, foldervar
# is the parameter storing the folder title.
# Optionally other parameters can also be specified:
# modulenamVar stores the module name,
# foldernamVar and folderdesVar store the folder name and description respectively

  upvar #0 $arrayname array
  global moduleselect
  global typedef

  # Initialise to a known state
  set w .install_task_choosemodule
  if { [winfo exists $w] } {
      destroy $w
  }
  if { [info exists moduleselect] } {
      unset moduleselect
  }

  # Define variable menus
  set typedef(_select_modules)  [list varmenu \
				     SELECT_MODULES_MENU SELECT_MODULES_ALIAS 20]
  set typedef(_select_folders)  [list varmenu \
				     SELECT_FOLDERS_MENU SELECT_FOLDERS_ALIAS 20]
  
  # Define other variables
  DefineVariable moduleselect N_MODULES _positiveint 0
  DefineVariable moduleselect SELECT_MODULES_MENU  _list ""
  DefineVariable moduleselect SELECT_MODULES_ALIAS _list ""
  DefineVariable moduleselect N_FOLDERS _positiveint 0
  DefineVariable moduleselect SELECT_FOLDERS_MENU  _list ""
  DefineVariable moduleselect SELECT_FOLDERS_ALIAS _list ""
  DefineVariable moduleselect SELECT_FOLDERS_DESCR _list ""
  DefineVariable moduleselect MODULE_TITLE _select_modules $array($modulevar)
  DefineVariable moduleselect FOLDER_TITLE _select_folders $array($foldervar)

  # Build the basic window
  if { ![OpenWindow $w "Select Module and Folder" "Modules&Folders" \
        -help [SearchPath HELP general modules.html ] ] } {
    return 0
  }
  CreateFrame $w moduleselect -noscroll

  CreateLine line \
      label "Choose a module and/or a subfolder" -italic

  CreateLine line \
      label "Module:" \
      widget MODULE_TITLE -width 30

  CreateLine line \
      label "Folder :" \
      widget FOLDER_TITLE \
      toggle_display N_FOLDERS hide { 0 }

  CreateLine line \
      label "Folder :" \
      label "No folders to display in this module" -italic \
      toggle_display N_FOLDERS open { 0 }

  CreateButton $w dismiss Cancel "CloseWindow moduleselect"
  CreateButton $w apply   OK \
      "install_task_choosemodule_apply $arrayname $modulevar $foldervar $modulenamVar $foldernamVar $folderdesVar"

  # Initialise the menus and variables
  set moduleselect(N_MODULES) [install_task_GetModulesInTarget $arrayname \
				   modules_menu modules_alias]

  # Update the variable menu for modules
  UpdateVariableMenu moduleselect initialise 0 \
      SELECT_MODULES_MENU $modules_menu \
      SELECT_MODULES_ALIAS $modules_alias \
      "install_task_choosemodule_updatefolders $arrayname $foldervar"

  # Set the initial value for the module name
  if { [llength $modules_menu] > 0 } {
      if { [lsearch $modules_menu $array($modulevar)] < 0 } {
	  set moduleselect(MODULE_TITLE) [lindex $modules_menu 0]
      } else {
	  set moduleselect(MODULE_TITLE) $array($modulevar)
      }
      # Initialise the menu of folders
      install_task_choosemodule_updatefolders $arrayname $foldervar
  }
}

#-----------------------------------------------------------------------
proc install_task_choosemodule_updatefolders { arrayname foldervar } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array
    global moduleselect
    set moduleselect(N_FOLDERS) [install_task_GetFoldersInTarget $arrayname \
				     $moduleselect(MODULE_TITLE) \
				     folders_menu folders_alias folders_descr]
    set folders_menu [linsert $folders_menu 0 "<None>"]
    set folders_alias [linsert $folders_alias 0 {}]
    set folders_descr [linsert $folders_descr 0 {}]
    UpdateVariableMenu moduleselect initialise 0 \
	SELECT_FOLDERS_MENU $folders_menu \
	SELECT_FOLDERS_ALIAS $folders_alias
    set moduleselect(SELECT_FOLDERS_DESCR) $folders_descr
    if { [llength $folders_menu] > 0 } {
	if { [lsearch $folders_menu $array($foldervar)] < 0 } {
	    set moduleselect(FOLDER_TITLE) [lindex $folders_menu 0]
	} else {
	    set moduleselect(FOLDER_TITLE) $array($foldervar)
	}
    }
}

#-----------------------------------------------------------------------
proc install_task_choosemodule_apply { arrayname modulevar foldervar \
					   { modulenamVar "" } \
					   { foldernamVar "" } \
					   { folderdesVar "" } } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array
    global moduleselect

    set array($modulevar) $moduleselect(MODULE_TITLE)
    if { $moduleselect(N_FOLDERS) > 0 && $moduleselect(FOLDER_TITLE) != "<None>" } {
	set array($foldervar) $moduleselect(FOLDER_TITLE)
    } else {
	set array($foldervar) {}
    }

    # Also set the module name, if requested
    if { $modulenamVar != "" } {
	if { [set i [lsearch $moduleselect(SELECT_MODULES_MENU) \
			 $moduleselect(MODULE_TITLE)]] > -1 } {
	    set array($modulenamVar) [lindex $moduleselect(SELECT_MODULES_ALIAS) $i]
	}
    }

    # Set the folder name and description, if requested
    if { [set i [lsearch $moduleselect(SELECT_FOLDERS_MENU) \
		     $moduleselect(FOLDER_TITLE)]] > -1 } {
	if { $foldernamVar != "" } {
	    set array($foldernamVar) [lindex $moduleselect(SELECT_FOLDERS_ALIAS) $i]
	}
	if { $folderdesVar != "" } {
	    set array($folderdesVar) [lindex $moduleselect(SELECT_FOLDERS_DESCR) $i]
	}
    }
    CloseWindow moduleselect
}
