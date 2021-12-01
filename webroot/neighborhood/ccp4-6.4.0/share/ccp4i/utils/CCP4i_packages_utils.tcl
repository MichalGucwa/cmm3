#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface packages_utils.tcl
#
#
# Packages and task installation utilities 
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities for managing task installation (src/CCP4i_packages_utils.tcl)
#d_intro_title Utilities for managing task installation
#d_intro Utilities for installing, uninstalling and exporting task interface \
packages, and manipulating ccp4i_packages.def files.

#-----------------------------------------------------------------------
proc InstallTaskPackage { package_name location archive_file args } {
#-----------------------------------------------------------------------
#d_sum Driver procedure to perform installation of a new task
#d_desc Install or update a package with identifier package_name from the \
specified archive_file. The package will be installed in either the main \
CCP4i area (accessible to all users) or the user's local CCP4i (accessible \
only to them), depending on the location argument. A record of the installation \
is stored in the relevant ccp4i_packages.def file.
#d_desc By default the installation will proceed automatically based on the \
information and files found in the archive_file. The calling procedure can \
over-ride this by supplying alternative information for each attribute via \
the arguments below.
#d_desc InstallTaskPackage can run in two different modes, specified by the -mode \
option. The default is 'nongraphical' mode, which means that warnings and error \
messages are written to the standard output. In 'graphical' mode these warnings \
are displayed graphically using the WarningMessage procedure.
#d_desc Returns 1 if the installation was successful, 0 if it failed.
#d_arg package_name Identifier for the package
#d_arg location Either MAIN (the main CCP4i area) or LOCAL (user's private CCP4i \
area)
#d_arg archive_file A tar or tar.gz archive file containing the task package to \
be installed. Alternatively, it can be a directory where the archive file has \
already been unpacked.
#d_opt0 -version version
#d_opt1 Version control string of the form "major.minor.patch"
#d_opt0 -task_files list_of_files
#d_opt1 Specify alternative list of task files (.tcl and .def) to be installed
#d_opt0 -script_files list_of_files
#d_opt1 Specify alternative list of script files (.script)
#d_opt0 -com_files list_of_files
#d_opt1 Specify alternative list of template files (.com)
#d_opt0 -help_files list_of_files
#d_opt1 Specify alternative list of help files (.html)
#d_opt0 -task_references list_of_references
#d_opt1 Specify task references to be added to the modules.def file. Each task \
reference must be a list consisting of: task_name task_title task_description \
module_name module_title
#d_opt0 -install_script script_file
#d_opt1 Specify a script to be run before installing the package
#d_opt0 -no_install_script
#d_opt1 Do not run the install script, even if one is found
#d_opt0 -no_archive
#d_opt1 Indicates that the "archive_file" is not a real CCP4i package
#d_opt0 -mode run_mode
#d_opt1 Warning and error messages will be displayed in a window (run_mode = \
graphical) or written to standard output (run_mode = nongraphical)

    global install_packages

    # Initialise
    set isfile 1
    set no_install_script 0
    set run_mode "nongraphical"
    set version ""
    set task_files ""
    set script_files ""
    set com_files ""
    set help_files ""
    set task_references ""
    set install_script ""

    set custom_task_files 0
    set custom_script_files 0
    set custom_com_files 0
    set custom_help_files 0
    set custom_task_references 0
    set no_archive 0

    # Process the arguments
    set nargs [llength $args]

    for {set i 0} {$i<$nargs} {incr i} {
	set option [lindex $args $i]
	switch -exact -- $option {
	    -version {
		# Version string
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set version [lindex $args $i]
	    }
	    -task_files {
		# List of task files
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set task_files [lindex $args $i]
		set custom_task_files 1
	    }
	    -script_files {
		# List of script files
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set script_files [lindex $args $i]
		set custom_script_files 1
	    }
	    -com_files {
		# List of template files
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set com_files [lindex $args $i]
		set custom_com_files 1
	    }
	    -help_files {
		# List of help files
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set help_files [lindex $args $i]
		set custom_help_files 1
	    }
	    -task_references {
		# List of task references
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set task_references [lindex $args $i]
		set custom_task_references 1
	    }
	    -install_script {
		# Install script
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set install_script [lindex $args $i]
            }
            -no_install_script {
                # Do not run any install script
                set no_install_script 1
	    }
	    -no_archive {
		# The "archive" file is not a true package
		# archive
		set no_archive 1
	    }
            -mode {
		# Run mode
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set run_mode [lindex $args $i]
		if { $run_mode != "graphical" && $run_mode != "nongraphical" } {
		    puts "ERROR unrecognised run mode \"$run_mode\""
		    return 0
		}
	    }
	    default {
		# Unknown option
		puts "ERROR unrecognised option \"$option\""
		return 0
	    }
	}
    }

    # Do checking

    # Check that the location is valid
    if { ![string match $location MAIN] && ![string match $location LOCAL] } {
	#puts "Invalid installation location \"$location\": should be MAIN or LOCAL"
	InstallReport \
		"Invalid installation location \"$location\": should be MAIN or LOCAL" \
		$run_mode
	return 0
    } else {
	set target_dir [GetTaskInstallDir $location]
	##puts "Target (installation) area is $target_dir"
    }

    # Check that the user has permission to write to this area
    if { ![file writable $target_dir] } {
        InstallReport "You do not appear to have permission to write
files to the selected installation area

$target_dir

The installation cannot be performed" $run_mode
        return 0
    }

    # Check that this is a valid archive file
    if { ![file exists $archive_file] } {
	##puts "Archive file \"$archive_file\" doesn't exist"
	InstallReport "Archive file \"$archive_file\" doesn't exist" $run_mode
	return 0
    }
    # Archive "file" might be an unpacked directory
    if { [file isdirectory $archive_file] } {
	##puts "Archive file \"$archive_file\" is a directory"
        ##InstallReport "Archive file \"$archive_file\" is a directory" $run_mode
	set isfile 0
    }

    # Check if the package name is valid
    if {![ValidatePackageName $package_name]} {
	##puts "Package name \"$package_name\" is not valid"
	InstallReport "Package name \"$package_name\" is not valid" $run_mode
	return 0
    }

    # Unpack and examine the archive file in a temporary location
    if { $no_archive } {
        # The "archive_file" is not a real CCP4i package
        # Set up a dummy list
        # The calling function will need to have specified the files to
        # install explicitly using the appropriate arguments
        set install_files [list {} {} {} {} {} {} {}]
    } else {
        # Get list of files to install from the package
        set install_files \
           [ExamineTaskArchive $package_name $archive_file install_packages]
    }
    if { [llength $install_files] == 0 && ! $no_archive } {
	##puts "Couldn't get list of files and references from archive file \"$archive_file\""
	InstallReport "Couldn't get list of files and references from archive \"$archive_file\"" $run_mode
        InstallReport "This may not be a valid CCP4i task package?" $run_mode
	return 0
    }

    if { $version == "" } {
        # No version supplied for calling procedure
        # See if there is one in the archive ccp4i_packages.def file
        if {[array exists install_packages]} {
        	set version $install_packages(PACKAGE_VERSION,1)
        }
    }
    ##puts "Version of package is \"$version\""

    # Check if this package exists already
    set packages_file [file join [GetTaskInstallFileDir $location] ccp4i_packages.def]
    if { [lsearch [GetPackageList $packages_file] $package_name] > -1 } {
	##puts "A package called \"$package_name\" already exists"
	set package_exists 1

	# Check version numbers
	# Current version
	set current_version [GetPackageVersion $packages_file $package_name]
	##puts "Current version of \"$package_name\" is \"$current_version\""

	# Compare version
	set version_status [ComparePackageVersions $current_version $version]
	switch -- $version_status {
	    -1 {
		InstallReport "Couldn't make version comparision" $run_mode
		return 0
	    }
	    0 {
		InstallReport "Versions are equivalent" $run_mode
		return 0
	    }
	    1 {
		InstallReport "The currently installed version ($current_version) is newer than the package version ($version)" $run_mode
		return 0
	    }
	}
	##puts "The package is a newer version: proceeding with the installation"
    }

    # Unpack the archive in a temporary directory
    if { $isfile } {
	##puts "Unpacking archive in temporary directory"
	set tmp_dir [ MakeTmpTaskInstallDir $package_name ]
	if { $tmp_dir == "" } {
	    InstallReport "Unable to create a temporary directory for installation" \
		    $run_mode
	    return 0
	}
	set source_dir [ UnpackTaskArchive $archive_file $tmp_dir ]
	if { $source_dir == "" } {
	    file delete -force $tmp_dir 
	    InstallReport "Unable to unpack the task archive file" $run_mode
	    return 0
	}
    } else {
	# The archive is a directory so assume that it's already
	# been unpacked
	set source_dir $archive_file
    }
    ##puts "Source dir is: $source_dir"
    
    # Run install script, if any was specified
    if { $no_install_script == 0 } {
      if { $install_script == "" } {
	 # See if a script was specified in the ccp4i_packages.def file
	 if {[array exists install_packages]} {
	    set install_script $install_packages(PACKAGE_INSTALL_SCRIPT,1)
	 }
      }
      if { $install_script != "" } {
        # Does it exist?
        if { [file executable [file join $source_dir $install_script]] } {
	  # The install script should return 1 if it is okay to
	  # proceed, 0 to abort the installation
	  set status [catch { exec [file join $source_dir $install_script] } message]
        } else {
          set status 1
          set message "Specified install script cannot be executed"
        }
        # Report any errors
	if { $status != 0 } {
          InstallReport "Install script \"$install_script\" failed with the message

\"$message\"

Installation will not be performed" $run_mode
          # Remove the temporary directory and return
	  if { $isfile } { file delete -force $tmp_dir }
	  return 0
	}
	puts "Install script returned 1 - proceeding with install"
      } else {
	##puts "No install script was specified, proceeding"
      }
    }

    # Get the list of files to install
    # If lists have already been supplied via the command line
    # then use these, otherwise use the lists obtained from the
    # earlier call to ExamineTaskArchive
    if { ! $custom_task_files } {
	set task_files [concat [lindex $install_files 1] [lindex $install_files 2]]
    }
    if { ! $custom_script_files } {
	set script_files [lindex $install_files 3]
    }
    if { ! $custom_com_files } {
	set com_files [lindex $install_files 4]
    }
    if { ! $custom_help_files } {
	set help_files [lindex $install_files 5]
    }
    ##puts "Lists of files to install:"
    ##puts "Task files $task_files"
    ##puts "Script files $script_files"
    ##puts "Com files $com_files"
    ##puts "Help files $help_files"

    # Get lists of task references to install
    # Use any list supplied via the command line in preference to
    # that provided by ExamineTaskArchive
    if { ! $custom_task_references } {
	set task_references [lindex $install_files 6]
    }
    ##puts "List of task references: $task_references"

    # Probably ought to validate names and existence before proceeding, but...
    ##puts "WARNING no validation of data has been performed"

    # Directory to install help files into
    # FIXME: Help files have not been thought about at all
    # The current fudge is that for tasks installed in the main area they
    # will be copied to $CCP4I_HELP/extra, and ignored completely for
    # tasks installed in local (PJX 15/04/02)
    if { $location == "MAIN" } {
      set help_dir [GetEnvPath CCP4I_HELP]
    } else {
      set help_dir ""
    }
    if { $help_dir != "" } {
      set help_dir [file join $help_dir extra]
      # Check if this exists and is okay to write to
      if { ![file exists $help_dir] } {
        # Try to create the directory
        if { ![catch { file mkdir $help_dir } ] } {
          InstallReport "Created a directory for help files:\n$help_dir" $run_mode
        }
      }
      if { ![file isdirectory $help_dir] } {
        set help_dir ""
      }
    }
    # Warn user if help directory cannot be found or
    # created
    if { $help_dir == "" &&  $location == "MAIN" } {
      InstallReport "Warning: the installation couldn't find or create the
directory for help files:

[file join [GetEnvPath CCP4I_HELP] extra]

possibly because you don't have write permission for the
CCP4I_HELP directory.

This means that any help files in this package cannot
be installed." $run_mode
    }

    # Everything ready and checked - proceed with install
    # Copy files
    set installed_files ""
    set backup_files    ""

    foreach subdir [list tasks scripts templates help] {
	##puts "Installing files into $subdir"
	# Set up file lists
	switch $subdir {
	    tasks {
		set file_list $task_files
	    }
	    scripts {
		set file_list $script_files
	    }
	    templates {
		set file_list $com_files
	    }
	    help {
		set file_list $help_files
	    }
	}
	foreach filen $file_list {
	    ##puts "File is $filen"
	    set source_file [file join $source_dir $subdir $filen]
            # Treat help files differently - put them into $CCP4I_HELP/extra
            if { $subdir != "help" } {
	      set target_file [file join $target_dir $subdir $filen]
            } else { 
              if { $help_dir != "" } {
                set target_file [file join $help_dir $filen]
              } else {
                set target_file ""
              }
            }
            # Only copy if the target file is nonblank
            if { $target_file != "" } {
              ##puts "Source file is $source_file, target file is $target_file"
	      # Make back-up copies of any overwritten files
	      if {[file exists $target_file]} {
		##puts "Backing up $target_file"
		set backup_file $target_file
		append backup_file .backup
		file copy -force $target_file $backup_file
		lappend backup_files [file join $subdir [file tail $backup_file]]
              }
	      ##puts "Copying $source_file"
	      CopyFile $source_file $target_file -overwrite
	    } else {
              ##puts "No destination for $source_file - not installed"
            }
	}
    }
    ##puts "Finished file copy"

    # Update the modules file
    set modules_file [file join [GetTaskInstallFileDir $location] modules.def]
    ##puts "Updating modules file $modules_file"
    if {![file exists $modules_file]} {
	# No modules.def file - create a new one from the dist
	# version in CCP4I_TOP/etc
	##puts "File $modules_file not found - creating new version from dist template"
        InstallReport "File $modules_file not found
Creating new modules.def file from the distributed template" $run_mode
	CopyFile [file join [GetEnvPath CCP4I_TOP] etc modules.def.dist ] \
		$modules_file
	##puts "Done"
    }
    # Go through the list of references to install
    set install_modules ""
    set install_task_refs ""
    foreach reference $task_references {
	set task_name [lindex $reference 0]
	set task_title [lindex $reference 1]
	set task_descript [lindex $reference 2]
	set module_name [lindex $reference 3]
	set module_title [lindex $reference 4]
        # There may also be folders defined
        if { [llength $reference] == 8 } {
            set folder_name [lindex $reference 5]
            set folder_title [lindex $reference 6]
            set folder_descript [lindex $reference 7]
        } else {
            set folder_name ""
            set folder_title ""
            set folder_descript ""
        }
	# Check that the module already exists
	set modules_list [GetModuleList $modules_file]
	##puts "List of modules is currently $modules_list"
	set module_exists 0
	foreach module $modules_list {
	    if { [lindex $module 0] == $module_name } {
		set module_exists 1
	    }
	}
	# If the module doesn't exist then add it
	if { ! $module_exists } {
	    ##puts "\"$module_title\" is a new module - adding"
	    if {[AddModule $modules_file $module_name $module_title]} {
		lappend install_modules [list $module_name $module_title]
	    } else {
		##puts "ERROR failed to add module \"$module_title\""
		InstallReport "Failed to add new module \"$module_title\"" $run_mode
	    }
	}
        # Check whether the folder (if any) already exists
        if { $folder_name != "" } {
            set folder_exists 0
            foreach item [GetModuleContentList $modules_file $module_name] {
                if { [lindex $item 3] == "FOLDER" } {
                    if { [lindex $item 0] == $folder_title } {
                        set folder_exists 1
                    }
                } 
            }
            # If the folder doesn't exist then add it
            if { ! $folder_exists } {
                if {[AddModuleFolder $modules_file $folder_title \
                        $folder_name $folder_descript $module_name]} {
	        } else {
		    ##puts "ERROR failed to add folder \"$folder_title\""
		    InstallReport "Failed to add new folder \"$folder_title\"" $run_mode
	        }
            }
        }
	# Check whether the task title already exists
        # It may be a top-level task or in a folder
	set taskref_list [GetModuleContentList $modules_file $module_name]
	##puts "List of tasks is currently $taskref_list"
	set task_exists 0
	foreach taskref $taskref_list {
            if {[lindex $taskref 3] == "TASK"} {
	        if {[lindex $taskref 0] == $task_title} {
		    set task_exists 1
                }
	    } elseif { $folder_name != "" } {
                set folder_name0 [lindex $taskref 1]
                foreach subtask [GetFolderContentList $modules_file \
                     $module_name $folder_name0] {
                    
	            if {[lindex $subtask 0] == $task_title} {
		        set task_exists 1
                    }
                }
            }
	}
	# If the task doesn't exist then add it
	# Maybe there should be a way to update references but
	# leave it for now
	if { ! $task_exists } {
	    ##puts "\"$task_title\" is a new task in this module - adding"
            if { $folder_name == "" } {
	        if {[AddTaskReference $modules_file $task_title $task_name \
		        $task_descript $module_name]} {
		    lappend install_task_refs [list $task_title $task_name \
			     $task_descript $module_name $module_title]
	        } else {
		    InstallReport "Failed to add task \"$task_title\" to module \"$module_title\"" $run_mode
	        }
            } else {
	        if {[AddTaskReference $modules_file $task_title $task_name \
		        $task_descript $module_name -folder $folder_name]} {
		    lappend install_task_refs [list $task_title $task_name \
			     $task_descript $module_name $module_title \
                             $folder_name $folder_title $folder_descript]

                }
	   }
        }
    }
    ##puts "Added task references to $modules_file"

    # Recap what's actually been installed, backed up etc
    ##puts "Installed the following files:"
    ##puts "In tasks: $task_files"
    ##puts "In scripts: $script_files"
    ##puts "In templates: $com_files"
    ##puts "In help: $help_files"
    ##puts "The following files were backed-up:"
    ##puts "$backup_files"
    ##puts "The following new modules were added:"
    ##puts "$install_modules"
    ##puts "The following task references were added:"
    ##puts "$install_task_refs"

    # Update the ccp4i_packages.def file
    ##puts "Adding package info to packages file"
    UpdatePackagesEntry $packages_file $package_name -version $version \
	    -task_files $task_files -script_files $script_files \
	    -com_files $com_files -help_files $help_files \
	    -modules $install_modules -task_references $install_task_refs \
	    -backups $backup_files -install_script $install_script
    ##puts "Done"

    # Delete the temporary directory, if we made one
    if { $isfile } {
	file delete -force $tmp_dir 
    }
    return 1
}

#-----------------------------------------------------------------------
proc ImportTaskPackage { package_name location ccp4_dir args } {
#-----------------------------------------------------------------------
#d_sum Driver procedure to import a task package from another CCP4 installation
#d_desc Given the name of a package, an installation location, and the \
path to another CCP4 installation, extract the data about the package and \
use that to copy the task install in the current CCP4 installation.
#d_desc ImportTaskPackage can run in either 'nongraphical' (the default) or \
'graphical' modes, as specified by the -mode option. In the former warning \
and error messages are written to the standard output, in the latter they are \
displayed graphically using the WarningMessage procedure.
#d_desc Returns 1 if the package was successfully imported, 0 if it failed.
#d_arg package_name Identifier for the package
#d_arg location Either MAIN (the main CCP4i area) or LOCAL (user's private CCP4i \
area)
#d_arg ccp4_dir Path to the top-level directory of a previous CCP4 installation
#d_opt0 -mode run_mode
#d_opt1 Warning and error messages displayed in a window (run_mode = graphical) \
or written to standard output (run_mode = nongraphical)

  global system

  # Initialise
  set run_mode "nongraphical"

  # Process the arguments
  set nargs [llength $args]
  for {set i 0} {$i<$nargs} {incr i} {
      set option [lindex $args $i]
      switch -exact -- $option {
          -mode {
	      # Run mode
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set run_mode [lindex $args $i]
	      if { $run_mode != "graphical" && $run_mode != "nongraphical" } {
		  puts "ERROR unrecognised run mode \"$run_mode\""
		  return 0
	      }
	  }
	  default {
	      # Unknown option
	      puts "ERROR unrecognised option \"$option\""
	      return 0
	  }
      }
  }

  # Get the location to copy from and the package file name
  set old_ccp4i [file join $ccp4_dir ccp4i]
  if { ![file isdirectory $old_ccp4i] } {
      InstallReport "Import: cannot find the source CCP4i directory:

$old_ccp4i

Cannot proceed." $run_mode
      return 0
  }
  set packages_file [file join $old_ccp4i etc \
			 $system(OPSYS) ccp4i_packages.def]
  if { ![file exists $packages_file] } {
      set packages_file [file join $old_ccp4i etc \
                             ccp4i_packages.def]
  }
  if { ![file exists $packages_file] } {
      InstallReport "Import: cannot find the source CCP4i packages file:

$packages_file

Cannot proceed." $run_mode
      return 0
  }

  # Acquire the package version
  set version [GetPackageVersion $packages_file $package_name]

  # Acquire the data about the installed files
  set task_files [GetPackageFiles $packages_file $package_name "tasks"]
  set script_files [GetPackageFiles $packages_file $package_name "scripts"]
  set com_files [GetPackageFiles $packages_file $package_name "templates"]
  set help_files [GetPackageFiles $packages_file $package_name "help"]

  # Acquire the task references
  set task_refs [GetPackageReferences $packages_file $package_name]

  # Fix the task references for feeding into InstallTaskPackage
  #
  # There is an inconsistency between the various functions
  # which means that the lists of references returned by
  # GetPackageReferences has the first two items (task name and
  # task title) the opposite way around to that needed by
  # InstallTaskPackage
  # So this fudge reverses them
  set updated_task_refs {}
  foreach ref $task_refs {
      set new_ref [list \
		       [lindex $ref 1] \
		       [lindex $ref 0] \
		       [lindex $ref 2] \
		       [lindex $ref 3] \
		       [lindex $ref 4]]
      # Deal with the possibility that there are also folders
      # referenced in the package
      if { [llength $ref] > 5 } {
	  lappend new_ref [lindex $ref 5] [lindex $ref 6] [lindex $ref 6]
      }
      lappend updated_task_refs $new_ref
  }
  set task_refs $updated_task_refs

  # Install the package
  return [InstallTaskPackage $package_name $location $old_ccp4i \
	      -version $version \
	      -task_files $task_files \
	      -script_files $script_files \
	      -com_files $com_files \
	      -help_files $help_files \
	      -task_references $task_refs \
	      -no_install_script \
	      -no_archive \
	      -mode $run_mode]
}

#-----------------------------------------------------------------------
proc ImportAllTaskPackages { ccp4_dir args } {
#-----------------------------------------------------------------------
#d_sum Driver procedure to import all task packages from another CCP4 installation
#d_desc Given the path to another CCP4 installation, extract the data about \
the packages installed in that installation and then copy the task install \
into the current CCP4 installation.
#d_desc ImportAllTaskPackages can run in either 'nongraphical' (the default) or \
'graphical' modes, as specified by the -mode option. In the former warning \
and error messages are written to the standard output, in the latter they are \
displayed graphically using the WarningMessage procedure.
#d_desc Returns 1 if the package was successfully imported, 0 if it failed.
#d_arg ccp4_dir Path to the top-level directory of a previous CCP4 installation
#d_opt0 -mode run_mode
#d_opt1 Warning and error messages displayed in a window (run_mode = graphical) \
or written to standard output (run_mode = nongraphical)

  global system

  # Initialise
  set run_mode "nongraphical"

  # Process the arguments
  set nargs [llength $args]
  for {set i 0} {$i<$nargs} {incr i} {
      set option [lindex $args $i]
      switch -exact -- $option {
          -mode {
	      # Run mode
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set run_mode [lindex $args $i]
	      if { $run_mode != "graphical" && $run_mode != "nongraphical" } {
		  puts "ERROR unrecognised run mode \"$run_mode\""
		  return 0
	      }
	  }
	  default {
	      # Unknown option
	      puts "ERROR unrecognised option \"$option\""
	      return 0
	  }
      }
  }

  # Get the location to copy from and the package file name
  set old_ccp4i [file join $ccp4_dir ccp4i]
  if { ![file isdirectory $old_ccp4i] } {
      InstallReport "Import: cannot find the source CCP4i directory:

$old_ccp4i

Cannot proceed." $run_mode
      return 0
  }
  set packages_file [file join $old_ccp4i etc \
			 $system(OPSYS) ccp4i_packages.def]
  if { ![file exists $packages_file] } {
      set packages_file [file join $old_ccp4i etc \
                             ccp4i_packages.def]
  }
  if { ![file exists $packages_file] } {
      InstallReport "Import: cannot find the source CCP4i packages file:

$packages_file

Cannot proceed." $run_mode
      return 0
  }

  # Acquire a list of packages in the old version
  set old_packages [GetPackageList $packages_file]
  if { [llength $old_packages] == 0 } {
      InstallReport "Import: no packages available to import from

$old_ccp4i

Cannot proceed." $run_mode
      return 0
  }

  # Loop over packages and import
  foreach package_name $old_packages {
      ImportTaskPackage $package_name MAIN $ccp4_dir -mode $run_mode
  }
  return 1
}

#-----------------------------------------------------------------------
proc ExportTaskPackage { package_name archive_file args } {
#-----------------------------------------------------------------------
#d_sum Driver procedure to create a task package archive file
#d_desc Create an installable tar.gz archive file for a package with \
identifier package_name. The contents and attributes of the package are \
specified via the optional arguments.
#d_desc ExportPackage can run in either 'nongraphical' (the default) or \
'graphical' modes, as specified by the -mode option. In the former warning \
and error messages are written to the standard output, in the latter they are \
displayed graphically using the WarningMessage procedure.
#d_desc Returns 1 if the package was successfully exported, 0 if it failed.
#d_arg package_name Identifier for the package
#d_arg archive_file Archive file to be written
#d_opt0 -version version
#d_opt1 Version control string of the form "major.minor.patch"
#d_opt0 -task_files list_of_files
#d_opt1 Specify list of task files (.tcl and .def) for inclusion
#d_opt0 -script_files list_of_files
#d_opt1 Specify list of script files (.script) for inclusion
#d_opt0 -com_files list_of_files
#d_opt1 Specify list of template files (.com) for inclusion
#d_opt0 -help_files list_of_files
#d_opt1 Specify list of help files for inclusion
#d_opt0 -task_references list_of_references
#d_opt1 Specify task references to be added to the modules.def file
#d_opt0 -install_script script_file
#d_opt1 Specify a script to be run before installing the package
#d_opt0 -mode run_mode
#d_opt1 Warning and error messages displayed in a window (run_mode = graphical) \
or written to standard output (run_mode = nongraphical)

  ##puts "ExportPackage: starting"

  # Initialise
  set run_mode "nongraphical"
  set overwrite 0
  set silent    0
  set version ""
  set task_files ""
  set script_file ""
  set com_files ""
  set help_files ""
  set task_references ""
  set install_script ""

  # Process the arguments
  set nargs [llength $args]
  if { $nargs < 1 } {
      InstallReport "The exported package is undefined!
Cannot proceed." $run_mode
      ##puts "ERROR no arguments to define exported package"
      return 0
  }

  for {set i 0} {$i<$nargs} {incr i} {
      set option [lindex $args $i]
      switch -exact -- $option {
	  -version {
	      # Version string
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set version [lindex $args $i]
	  }
	  -task_files {
	      # List of task files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set task_files [lindex $args $i]
	  }
	  -script_files {
	      # List of script files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set script_files [lindex $args $i]
	  }
	  -com_files {
	      # List of template files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set com_files [lindex $args $i]
	  }
	  -help_files {
	      # List of help files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set help_files [lindex $args $i]
	  }
	  -task_references {
	      # List of task references
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set task_references [lindex $args $i]
	  }
	  -install_script {
	      # Install script
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set install_script [lindex $args $i]
	  }
	  -overwrite {
	      # Overwrite any existing archive file automatically
	      set overwrite 1
	  }
	  -silent {
	      # Silent
	      set silent 1
	  }
          -mode {
	      # Run mode
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set run_mode [lindex $args $i]
	      if { $run_mode != "graphical" && $run_mode != "nongraphical" } {
		  puts "ERROR unrecognised run mode \"$run_mode\""
		  return 0
	      }
	  }
	  default {
	      # Unknown option
	      puts "ERROR unrecognised option \"$option\""
	      return 0
	  }
      }
  }

  ##puts "Package name \"$package_name\""
  ##puts "Target archive file \"$archive_file\""
  ##puts "Version: $version"
  ##puts "Install script: $install_script"
  ##puts "Task files  : $task_files"
  ##puts "Script files: $script_files"
  ##puts "Com files   : $com_files"
  ##puts "Help files  : $help_files"
  ##puts "Task references: $task_references"
  ##puts "Overwrite mode: $overwrite"
  ##puts "Run mode: $run_mode"

  # Do checks

  # Check that this is a valid package name
  if { ![ValidatePackageName $package_name] } {
      InstallReport "ERROR Package name \"$package_name\" is not valid" $run_mode
      return 0
  }

  # Check the archive file
  if { [file exists $archive_file] } {
      if { ![file isdirectory $archive_file] && $overwrite } {
	  # Delete the file first
	  ##puts "WARNING deleting existing file $archive_file"
	  InstallReport "WARNING deleting existing archive file \"$archive_file\"" \
		  $run_mode
	  file delete $archive_file
      } else {
	  # Otherwise abort
	  ##puts "ERROR file \"$archive_file\" exists and will not be overwritten"
	  InstallReport "ERROR file \"$archive_file\" exists and will not be overwritten" $run_mode
	  return 0
      }
  }

  # Check the lists of files
  # Task files
  if { [llength $task_files] < 1 } {
      ##puts "ERROR no task files specified"
      InstallReport "ERROR no task files specified" $run_mode
      return 0
  }
  set task_list ""
  foreach file $task_files {
      if { ![file exists $file] } {
	  InstallReport "ERROR specified task file \"$file\" not found" $run_mode
	  return 0
      }
      if { [file extension $file] == ".tcl" } {
	  lappend task_list [ file tail [file rootname $file] ]
      } elseif { [file extension $file] != ".def" } {
	  InstallReport "ERROR task file \"$file\" has non-standard extension" $run_mode
	  return 0
      }
  }
  if { [llength $task_list] < 1 } {
      InstallReport "ERROR no task .tcl files were specified" $run_mode
      return 0
  }
  # Script files
  foreach file $script_files {
      if { ![file exists $file] } {
	  InstallReport "ERROR specified script file \"$file\" not found" $run_mode
	  return 0
      }
      if { [file extension $file] != ".script" } {
	  InstallReport "ERROR script file \"$file\" has non-standard extension" \
		  $run_mode
	  return 0
      }
  }
  # Com files
  foreach file $com_files {
      if { ![file exists $file] } {
	  InstallReport "ERROR specified script file \"$file\" not found" $run_mode
	  return 0
      }
      if { [file extension $file] != ".com" } {
	  InstallReport "ERROR template file \"$file\" has non-standard extension" \
		  $run_mode
	  return 0
      }
  }
  # Help files
  foreach file $help_files {
      if { ![file exists $file] } {
	  InstallReport "ERROR specified help file \"$file\" not found" $run_mode
	  return 0
      }
  }

  # Check the task references
  if { [llength $task_references] < 1 } {
      InstallReport "WARNING no task references were supplied" $run_mode
  } else {
      foreach reference $task_references {
	  # Each reference is a list with either five or eight elements
	  # task_name
	  # task_title
	  # task_descript
	  # module_name
	  # module_title
	  # folder_name (optionally)
	  # folder_title (must be present if folder_name is specified)
	  # folder_desc (must be present if folder_name is specified)
	  if { [llength $reference] != 5 && [llength $reference] != 8 } {
	      InstallReport "ERROR in task reference definitions" $run_mode
	      return 0
	  }
	  # Check task name against list of tasks
	  set task_name [lindex $reference 0]
	  if { [lsearch $task_list $task_name] < 0 } {
	      InstallReport "WARNING task reference for \"$task_name\" but task not in package" $run_mode
	  }
	  # Check that the text is not blank
	  foreach item $reference {
	      if { [string trim $item] == "" } {
		  ##puts "ERROR blank item in task references"
		  InstallReport "ERROR blank item in task references" $run_mode
		  return 0
	      }
	  }
	  # Add to the list of referenced tasks
	  lappend task_ref_list $task_name
      }
  }
  # Second check: that all tasks are referenced
  foreach task_name $task_list {
      if { [lsearch $task_ref_list $task_name] < 0 } {
	  InstallReport "WARNING no task reference supplied for task \"$task_name\"" \
		  $run_mode
      }
  }

  # Check that the install script (if any) exists
  if { $install_script != "" } {
      if { ![file exists $install_script] } {
	  InstallReport "ERROR specified install script \"$install_script\" not found" \
		  $run_mode
	  return 0
      }
  }

  # All checks completed - make a temporary directory to put
  # the files in
  set export_dir [MakeTmpTaskInstallDir $package_name]
  if { "$export_dir" == "" } {
      InstallReport "ERROR Failed to create temporary directory for export" $run_mode
      return 0
  }

  # Make a subdirectory here with the actual package name
  set package_dir [file join $export_dir $package_name]
  file mkdir $package_dir

  # Make subdirectories and copy files
  foreach subdir [list tasks scripts templates help] {
      set target_dir [file join $package_dir $subdir]
      file mkdir $target_dir
      ##puts "Made directory $target_dir"
      # Copy all the relevant files
      switch $subdir {
	  tasks {
	      set file_list $task_files
	  }
	  scripts {
	      set file_list $script_files
	  }
	  templates {
	      set file_list $com_files
	  }
	  help {
	      set file_list $help_files
	  }
      }
      foreach source_file $file_list {
	  set target_file [file join $package_dir $subdir [file tail $source_file] ]
	  ##puts "Source file $i: $source_file, target file is $target_file"
	  CopyFile $source_file $target_file
      }
  }
  # Copy the install script to the export directory
  if { $install_script != "" } {
      set target_file [file join $package_dir [file tail $install_script] ]
      CopyFile $install_script $target_file
  }
  ##puts "Finished copying files"

  # Create a new modules file
  set modules_file [file join $package_dir modules.def]
  CopyFile [file join [GetEnvPath CCP4I_TOP] etc modules.def.dist] $modules_file
  if { ![file exists $modules_file] } {
      InstallReport "ERROR failed to create modules definition file $modules_file" \
	      $run_mode
      return 0
  }
  # Add the task references to the modules file
  ##puts "Adding task references to modules file"
  foreach reference $task_references {
      # Add the module first
      set module_name [lindex $reference 3]
      set module_title [lindex $reference 4]
      ##puts "Task reference has module $module_title ($module_name)"
      AddModule $modules_file $module_name $module_title
      # Optionally also add the folder, if specified
      if { [llength $reference] == 8 } {
	  set has_folder 1
	  set folder_name [lindex $reference 5]
	  set folder_title [lindex $reference 6]
	  set folder_desc [lindex $reference 7]
	  AddModuleFolder $modules_file $folder_title \
	      $folder_name $folder_desc $module_name
      } else {
	  set has_folder 0
      }
      # Add the task
      set task_name [lindex $reference 0]
      set task_title [lindex $reference 1]
      set task_descript [lindex $reference 2]
      if { ! $has_folder } {
	  AddTaskReference $modules_file \
	      $task_title $task_name $task_descript $module_name
      } else {
	  AddTaskReference $modules_file \
	      $task_title $task_name $task_descript $module_name \
	      -folder $folder_name
      }
  }

  # Create a new packages file
  set packages_file [file join $package_dir ccp4i_packages.def]
  CopyFile [file join [GetEnvPath CCP4I_TOP] etc ccp4i_packages.def.dist] $packages_file
  if { ![file exists $packages_file] } {
      ##puts "ERROR failed to create $packages_file"
      InstallReport "ERROR failed to create package definition file $packages_file" \
	      $run_mode
      return 0
  }
  # Add a single entry for this package with version info etc
  ##puts "Adding package info to packages file"
  UpdatePackagesEntry $packages_file $package_name -version $version \
	  -task_files $task_files -script_files $script_files \
	  -com_files $com_files -help_files $help_files \
	  -task_references $task_references \
	  -install_script [file tail $install_script]
  ##puts "Done"

  # Archive and compress the export directory
  append tar_file $package_dir .tar
  ##puts "About to make tar file $tar_file"
  CreateTarFile $tar_file $package_name $export_dir
  ##puts "Done making tar file"
  append gz_file $tar_file .gz
  ##puts "About to compress tar file - new file should be $gz_file"
  CompressFile $tar_file
  ##puts "Done compression"
  if { [file exists $gz_file] } {
      ##puts "$gz_file exists"
      # Move to final location
      file rename $gz_file $archive_file
  }

  # Delete temporary directory
  file delete -force $export_dir

  if { ![file exists $archive_file] } {
      InstallReport "ERROR archive file \"$archive_file\" was not created" $run_mode
      return 0
  }
  ##puts "Finished exporting task"

  # Return 1 on success
  return 1
}

#-----------------------------------------------------------------------
proc UninstallTaskPackage { package_name location args } {
#-----------------------------------------------------------------------
#d_sum Driver procedure to uninstall a previously installed task package
#d_desc Uninstall the package with identifier package_name from either the \
main CCP4i area or the user's local CCP4i area (depending on the value of the \
location argument), using the information stored in the relevant ccp4i_packages.def \
file.
#d_desc The uninstall will remove the files associated with the package \
(restoring any backup files that it finds in the process) and remove any \
associated task references which were installed in the modules.def file. The \
package will be removed from the ccp4i_packages.def file.
#d_desc UninstallTaskPackage can run  in two different modes, specified by the -mode \
option. The default is 'nongraphical' mode, which means that warnings and error \
messages are written to the standard output. In 'graphical' mode these warnings \
are displayed graphically using the WarningMessage procedure.
#d_desc Returns 1 if the uninstallation was successful, 0 if it failed.
#d_arg package_name Identifier for the package to be uninstalled
#d_arg location Either MAIN (the main CCP4i area) or LOCAL (user's private CCP4i \
area)
#d_opt0 -mode run_mode
#d_opt1 Warning and error messages will be displayed in a window (run_mode = \
graphical) or written to standard output (run_mode = nongraphical)

    # Initialise
    set run_mode "nongraphical"

    # Process the arguments
    set nargs [llength $args]

    for {set i 0} {$i<$nargs} {incr i} {
	set option [lindex $args $i]
	switch -exact -- $option {
	    -mode {
		# Run mode
		incr i
		if { $i == $nargs } {
		    puts "ERROR insufficient arguments"
		    return 0
		}
		set run_mode [lindex $args $i]
		if { $run_mode != "graphical" && $run_mode != "nongraphical" } {
		    puts "ERROR unrecognised run mode \"$run_mode\""
		    return 0
		}
	    }
	    default {
		# Unknown option
		puts "ERROR unrecognised option \"$option\""
		return 0
	    }
	}
    }

    # Do checking

    # Check that the location is valid
    if { ![string match $location MAIN] && ![string match $location LOCAL] } {
	InstallReport "Invalid installation location \"$location\": should be MAIN or LOCAL" $run_mode
	return 0
    } else {
	set target_dir [GetTaskInstallDir $location]
	##puts "Target (uninstallation) area is $target_dir"
    }

    # Check that this package exists
    set packages_file [file join [GetTaskInstallFileDir $location] ccp4i_packages.def]
    if { [lsearch [GetPackageList $packages_file] $package_name] < 0 } {
	InstallReport "Package \"$package_name\" could not be found in $packages_file" \
		$run_mode
	return 0
    }

    # Retrive the list of installed files
    set uninstall_dirs ""
    set uninstall_files ""
    set uninstall_types [list TASKS SCRIPTS TEMPLATES HELP]
    foreach type $uninstall_types {
	foreach filein [GetPackageFiles $packages_file $package_name $type] {
	    lappend uninstall_files $filein
	    lappend uninstall_dirs [string tolower $type]
	}
    }
    ##puts "Lists of files to uninstall: $uninstall_files"
    ##puts "Corresponding dirs:          $uninstall_dirs"

    set nfiles [llength $uninstall_files]
    if { $nfiles < 1 } {
	InstallReport "Package is empty - no files to uninstall" $run_mode
	return 0
    }

    # Retrieve the installed task references
    set task_references [GetPackageReferences $packages_file $package_name]
    set nrefs [llength $task_references]
    set uninstall_refs ""
    if { $nrefs == 0 } {
	##puts "WARNING no task references to uninstall"
	InstallReport "WARNING no task references to uninstall" $run_mode
    } else {
	# Build a list to use for uninstalling
	foreach ref $task_references {
	    ##puts "Examine task reference: $ref"
	    set task_title [lindex $ref 0]
	    set module_name [lindex $ref 3]
	    if { [llength $ref] > 6 } {
		# Also get information on the subfolder
		set folder_title [lindex $ref 6]
	    } else {
		set folder_title ""
	    }
	    lappend uninstall_refs [list $task_title $module_name $folder_title]
	}
    }
    ##puts "List of references to uninstall: $uninstall_refs"

    # Perform the uninstallation
    ##puts "Starting the uninstallation..."
    set backups_list ""
    for {set i 0} {$i<$nfiles} {incr i} {
	set uninstall_file [lindex $uninstall_files $i]
	set uninstall_dir  [lindex $uninstall_dirs $i]
	##puts "Uninstalling $uninstall_file from subdir $uninstall_dir"   
	# Make full filename
        if { $uninstall_dir == "help" } {
	  # Help files were installed in CCP4I_HELP/extra
          set filename [file join [GetEnvPath CCP4I_HELP] extra $uninstall_file]
        } else {
          # All other types
	  set filename [file join $target_dir $uninstall_dir $uninstall_file]
        }
	##puts "Full path: $filename"
	# Check for a backup file
	set backup_file $filename
	append backup_file .backup
	if {[file exists $backup_file]} {
	    # Move backup file to overwrite existing file
	    ##puts "Found backup file - overwriting"
	    file rename -force $backup_file $filename
	    lappend backups_list $filename
	} else {
	    # Remove the existing file
	    ##puts "Didn't find back up file - removing"
	    file delete $filename
	}
    }
    if {[llength $backups_list] > 0} {
	Report 3 "Uninstall: files restored from backups: $backups_list"
    }

    # Uninstall the task references
    set modules_file [file join [GetTaskInstallFileDir $location] modules.def]
    ##puts "Uninstalling task references from $modules_file"
    if {![file exists $modules_file]} {
	# No modules file so nothing to uninstall
	InstallReport "Modules file \"$modules_file not found\" - no uninstallation of task references" $run_mode
    } else {
	# Remove each of the listed task references
	foreach ref $uninstall_refs {
	    set task_title [lindex $ref 0]
	    set module_name [lindex $ref 1]
	    set folder_title [lindex $ref 2]
	    DeleteTaskReference $modules_file $task_title $module_name $folder_title
	    # Delete any empty folders
	    if { [llength [GetFolderContentList $modules_file $module_name \
			       $folder_title]] < 1 } {
		DeleteModuleFolder $modules_file $module_name $folder_title
	    }
            # Delete any empty modules
            if { [llength [GetModuleContentList $modules_file $module_name]] < 1 } {
		DeleteModule $modules_file $module_name
	    }
	}
    }
    
    # Remove the package from ccp4i_packages.def
    ##puts "Updating ccp4i_packages.def"
    RemovePackagesEntry $packages_file $package_name
    ##puts "Removed packages entry - done"
    return 1
}

#-----------------------------------------------------------------------
proc ExamineTaskArchive { package_name archive_file packagesVar } {
#-----------------------------------------------------------------------
#d_sum Examine the contents of a task archive package file
#d_desc Returns a list of the contents of a package archive file, as \
follows:
#d_desc List element 0: list of tasks
#d_desc List element 1: list of tcl files
#d_desc List element 2: list of def files
#d_desc List element 3: list of script files
#d_desc List element 4: list of template files
#d_desc List element 5: list of help files
#d_desc List element 6: list of task references, read from the modules \
file in the package.
#d_desc Each task reference is itself a list, consisting of: task name, \
task title, task description, module name and module title.
#d_desc If the archive contents cannot be successfully read then an \
empty string is returned. If the archive contains a ccp4i_packages.def file \
then the contents are also read into an array called packagesVar and \
returned to the calling procedure.
#d_arg package_name The name of the package
#d_arg archive_file The full path of the archive (file)
#d_arg packagesVar  Name of the array variable in which information will \
be returned to the calling procedure
  upvar $packagesVar packages
  global packages0

  ##puts "ExamineTaskArchive: starting"
  ##puts "packagesVar = $packagesVar"

  # Check that the archive file exists and is a valid file
  if { ![file exists $archive_file] } {
      puts "ExamineTaskArchive: archive \"$archive_file\" doesn't exist"
      return ""
  }
  # Task archive "file" may be an already unpacked directory
  set isdir 0
  if { [file isdirectory $archive_file] } {
      puts "ExamineTaskArchive: archive \"$archive_file\" is a directory"
      set isdir 1
  }

  # Check that the package name doesn't start with a blank
  if { [regexp -- "^\[ \t\]" $package_name] } {
      puts "ExamineTaskArchive: invalid package name \"$package_name\""
      return ""
  }

  # Set up a temporary directory to check archive contents
  if {! $isdir } {
      set tmp_dir [ MakeTmpTaskInstallDir $package_name ]
      if { $tmp_dir == "" } {
	  puts "ExamineTaskArchive: unable to create a temporary directory"
	  return ""
      }
      
      # Copy the archive file to the temporary area and unpack it
      # Fetch lists of the contents
      set source_dir [ UnpackTaskArchive $archive_file $tmp_dir ]
      if { $source_dir == "" } {
	  puts "ExamineTaskArchive: failed to unpack temporary copy of $archive_file"
	  file delete -force $tmp_dir
	  return ""
      }
  } else {
      # "Archive is a directory - assume it was already unpacked by
      # the user
      set source_dir $archive_file
  }

  # Sort the contents of the package
  foreach subdir [list tasks tasks scripts templates help] \
	  ext [list .tcl .def .script .com .html] {
      ##puts "ExamineTaskArchive: subdir $subdir, extension $ext"
      set file_list [glob -nocomplain [FileJoin $source_dir $subdir \*[subst $ext]]]
      ##puts "File list is $file_list"
      # Need to strip off leading paths
      switch -exact $ext {
	  .tcl { set listname tcl_files }
	  .def { set listname def_files }
	  .script { set listname script_files }
	  .com { set listname com_files }
	  .html { set listname help_files }
      }
      set $listname ""
      foreach filen $file_list {
	  lappend $listname [file tail $filen]
      }
  }

  ##puts "ExamineTaskArchive\nList of task files\nTcl files: $tcl_files\n\nDef files: $def_files\n\nScripts  : $script_files\n\nTemplates: $com_files\n\nHelp: $help_files"

  # Check that there are actually tasks to install
  if { [llength $tcl_files] < 1 } {
      puts "ExamineTaskArchive: no tcl files to install"
      if {! $isdir } { file delete -force $tmp_dir }
      return ""
  }

  # Deal with task references in the modules(.def) file
  #
  # Old-style modules file
  set task_modules_file [file join $source_dir modules]
  if { [file exists $task_modules_file] } {
      ##puts "ExamineTaskArchive: found old-style modules file \"$task_modules_file\""
  } elseif { [file exists [subst $task_modules_file].def] } {
      append task_modules_file .def
      ##puts "ExamineTaskArchive: found new-style modules.def file \"$task_modules_file\""
  } else {
      ##puts "ExamineTaskArchive: no modules file found"
      if {! $isdir } { file delete -force $tmp_dir }
      return ""
  }
  # Get a list of modules defined in the modules file
  set master_list [GetModuleList $task_modules_file]

  # For each module get the task references
  set task_refs {}
  foreach module $master_list {
      set module_name  [lindex $module 0]
      set module_title [lindex $module 1]
      set content_list [GetModuleContentList $task_modules_file $module_name]
      ##puts "ExamineTaskArchive: in module $module_name:\n $content_list"
      # The task_list could contain tasks or folders with tasks
      foreach item $content_list {
	  if { [lindex $item 3] == "TASK" } {
	      # The reference is a task - add to the list
	      set task_title    [lindex $item 0]
	      set task_name     [lindex $item 1]
	      set task_descript [lindex $item 2]
	      lappend task_refs [list $task_name $task_title $task_descript \
				     $module_name $module_title]
	  } else {
	      # The reference is a folder - get the contents
	      set folder_title    [lindex $item 0]
	      set folder_name     [lindex $item 1]
	      set folder_descript [lindex $item 2]
	      set subtask_list [GetFolderContentList $task_modules_file $module_name \
				    $folder_name]
	      foreach subtask $subtask_list {
		  # Add the subtask references
		  set subtask_title    [lindex $subtask 0]
		  set subtask_name     [lindex $subtask 1]
		  set subtask_descript [lindex $subtask 2]
		  lappend task_refs [list $subtask_name \
					 $subtask_title $subtask_descript \
					 $module_name $module_title \
					 $folder_name $folder_title \
					 $folder_descript]  
	      }
	  }
      }
  }
  ##puts "ExamineTaskArchive: finished looking at modules file"

  # Look for a ccp4i_packages.def file to obtain additional information
  # about this package
  set packages_file [file join $source_dir ccp4i_packages.def]
  if { [file exists $packages_file] } {
      ##puts "ExamineTaskArchive: found ccp4i_packages.def"
      InitialiseArray $packages_file packages0 packages -nocheck
      ##puts "Array loaded : parameter list is $packages0(PARAM_LIST)"
      # Get list of elements in packages0 array
      # This is so we can copy it to the name specified by the
      # calling procedure
      # Note that no types are copied when doing this
      set params [array names packages0 *]
      foreach par $params {
         set packages($par) $packages0($par)
      }
  } else {
      ##puts "ExamineTaskArchive: no ccp4i_packages.def found"
  }

  # Finished reading from the archive - remove the temporary directory
  if {! $isdir } { file delete -force $tmp_dir }

  # Sort the information for each task into a list of lists construct
  # to return to the calling procedure
  #
  # This is { {tasks} {tcl_files} {def_files} {script_files} {help_files} {task refs} }
  # Each tcl file is a new task so get a list from tcl_file_list
  set task_list ""
  foreach file $tcl_files {
      lappend task_list [file tail [file root $file]]
  }
  return [list $task_list $tcl_files $def_files $script_files $com_files \
	  $help_files $task_refs]
}
	
#-----------------------------------------------------------------------
proc MakeTmpTaskInstallDir { package_name args } {
#-----------------------------------------------------------------------
#d_sum Create a temporary directory in which to unpack an archive file
#d_desc Makes a subdirectory in TEMPORARY called install_(package_name). \
This is used by other procedures to unpack and examine the contents of the \
the archive file.
#d_desc Returns the path of the temporary directory, or an empty string \
if there is an error.
#d_desc NB The procedure will attempt to detect if it is operating in a \
non-graphical mode - if the ChooseOptionDialog procedure is not found then \
non-graphical mode is assumed and the -force option is taken as default.
#d_arg package_name Identifier for package
#d_opt0 -force
#d_opt1 By default the user is queried if the temporary directory already \
exists. This option over-rides the query and forces deletion of the directory \
contents before recreating the directory.

  # Optional arguments
  set query 1
  set nargs [llength args]
  if { $nargs == 1 } {
      if { [lindex $args 0] == "-force" } { set query 0 }
  }

  # Are we running in a non-graphical mode?
  if { [info commands ChooseOptionDialog] == "" } {
    ##puts "Can't find ChooseOptionDialog - assume nongraphical"
    set query 0
  }

  # Make temporaray installation directory
  set tmp_dir [file join [GetDefaultDirPath TEMPORARY] install_$package_name]
  if { [file exists $tmp_dir] } {
      if { [file isdirectory $tmp_dir] } {
	  if { $query } {
	      set action [ ChooseOptionDialog "Directory exists" Warning \
		      "The directory $tmp_dir already exists - the installer needs\nthis directory to store temporary files\n\nThe installer will delete this directory and its contents\nand then recreate it." \
		      [list "OK" "Cancel"] -default 2]
	      if { [regexp Cancel $action] } {
		  return ""
	      }
	  }
	  ##puts "MakeTmpTaskInstallDir: Deleting directory $tmp_dir"
	  file delete -force $tmp_dir
      } else {
	  ##puts "MakeTmpTaskInstallDir: $tmp_dir exists and is not a directory"
	  return ""
      }
  }
  file mkdir $tmp_dir
  ##puts "Made directory $tmp_dir"
  return $tmp_dir
}

#-----------------------------------------------------------------------
proc GetTaskInstallDir { location } {
#-----------------------------------------------------------------------
#d_sum Return the root path for the installation area
#d_desc Returns the path for the installation area depending on the \
value of the location argument. MAIN refers to the main CCP4i area pointed \
to by the CCP4I_TOP system variable, LOCAL refers to the user's private \
CCP4i area in \$HOME/.CCP4/CCP4I_TOP
#d_arg location Installation area, either MAIN or LOCAL
    global system
    switch -exact $location {
	LOCAL { return [file join [GetSystemVar DOT] CCP4I_TOP] }
	MAIN  { return [file join [GetEnvPath CCP4I_TOP]] }
	default { puts "Unknown installation area \"$location\"" } 
    }
    return
}

#-----------------------------------------------------------------------
proc GetTaskInstallFileDir { location } {
#-----------------------------------------------------------------------
#d_sum Return the root path for the installation modules and packages files
#d_desc Returns the path for the directory holding the releveny modules.def \
and ccp4i_packages.def files depending on the value of the location argument. \
MAIN refers to the main CCP4i area (\$CCP4I_TOP/etc), \
LOCAL refers to the user's private CCP4i area (\$HOME/.CCP4/(opsys)).
#d_arg location Installation area, either MAIN or LOCAL
    global system
    switch -exact $location {
	LOCAL { 
	    # This is needed as a fudge because I haven't rationalised
	    # exactly where the user's modules file will live
	    # See browser_utils.tcl "ReadTaskList" - it all needs to be
	    # fixed up at some point but assume the same conventions for now
	    switch $system(OPSYS) {
		UNIX { set opsys unix }
		WINDOWS { set opsys windows }
	    }
	    return [file join [GetSystemVar DOT] $opsys ]
	}
	MAIN  {
	    return [file join [GetEnvPath CCP4I_TOP] etc]
	}
	default { puts "Unknown installation area \"$location\"" } 
    }
    return
}

#-----------------------------------------------------------------------
proc UnpackTaskArchive { archive_file tmpdir } {
#-----------------------------------------------------------------------
#d_sum Unpack a CCP4i task package archive file.
#d_desc Copy the task archive file to the temporary area, and uncompress \
and unpack it so that the contents can be examined. Returns the full \
path name of the unpacked directory, or an empty string if there was an \
error.
#d_arg archive_file Full path name of the task archive file
#d_arg tmpdir Full path name of the temporary directory
  set task_file [file tail $archive_file]
  set source_file [file join $tmpdir $task_file]
  file copy $archive_file $source_file
  if { ![file exists $source_file] } {
      puts "UnpackTaskArchive: couldn't copy archive to \"$source_file\""
      return ""
  }

  # Uncompress
  # Need to change directory so that uncompressed and
  # untarred files are written to the same place
  set cwd [GetCurrentDir]
  ChangeDirectory $tmpdir
  if { [regexp gz [file extension $source_file] ] } {
    UnCompressFile $source_file
    set source_file [file rootname $source_file]
    if { ![file exists $source_file] } {
      puts "UnpackTaskArchive: uncompress failed to create \"$source_file\""
      return ""
    }
  }

  # Get a list of the files etc in the current directory
  # immediately prior to untarring
  set file_list1 [glob -dir $tmpdir -nocomplain *]

  # Attempt to unpack
  if { [regexp tar [file extension $source_file] ] } {
    UnTarFile $source_file
    set source_file [file rootname $source_file]
    if { ![file exists $source_file] } {
      # It is possible that the rootname is not the same as the
      # untarred directory
      # Look for new directories created immediately after the
      # untar operation
      set possible_source_files {}
      set file_list2 [glob -dir $tmpdir -nocomplain *]
      foreach filen $file_list2 {
        if { [lsearch -exact $file_list1 $filen] < 0 } {
          # This is a candidate
	  if { [file isdirectory $filen] } {
	    lappend possible_source_files $filen
          }
        }
      }
      if { [llength $possible_source_files] == 1 } {
        # Only one possibility so this must be it
        set source_file [lindex $possible_source_files 0]
      } else {
        # Assume that we've failed
        puts "UnpackTaskArchive: untarring failed to create \"$source_file\""
        return ""
      }
    }
  }

  # Change directory back to original working directory
  ChangeDirectory $cwd

  if { ![file exists $source_file] || \
	  ![file isdirectory $source_file] } {
      puts "UnpackTaskArchive: error - \"$source_file\" is not a directory"
      return ""
  }

  return $source_file
}

#-----------------------------------------------------------------------
proc GetPackageList { packages_file } {
#-----------------------------------------------------------------------
#d_sum Return a list of CCP4i package names from a ccp4i_packages.def file
#d_arg packages_file Full path name of the ccp4i_packages.def file of interest
  global getpackagelist_array

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      return ""
  }

  # Get the information from the PACKAGES file
  InitialiseArray $packages_file getpackagelist_array packages -nocheck

  set n_packages $getpackagelist_array(N_PACKAGES)
  set package_list ""
  for {set i 1} {$i <= $n_packages} {incr i} {
      lappend package_list $getpackagelist_array(PACKAGE_NAME,$i)
  }
  if { [info exists getpackagelist_array] } { unset getpackagelist_array }
  return $package_list
}

#-----------------------------------------------------------------------
proc GetPackageFiles { packages_file package_name subdir } {
#-----------------------------------------------------------------------
#d_sum Return a list of files for a package registered in a CCP4i subdirectory
#d_desc Get a list of files in one of the CCP4i subdirectories (tasks, \
scripts, templates or help) which are associated with a currently installed \
package.
#d_arg packages_file The full path name of the ccp4i_packages.def file
#d_arg package_name Name of the CCP4i task package of interest
#d_arg subdir The subdirectory of interest
  global getpackagefiles_array

  ##puts "GetPackageFiles: starting"

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      ##puts "Packages file \"$packages_file\" not found"
      return ""
  }

  # Check that we have a valid attribute
  set subdir0 [string toupper $subdir]
  if { [lsearch [list TASKS SCRIPTS TEMPLATES HELP] $subdir0] < 0 } {
      ##puts "GetPackageFiles: invalid attribute \"$subdir\""
      return ""
  }

  # Get the information from the PACKAGES file
  ##puts "About to read packages file from $packages_file"
  InitialiseArray $packages_file getpackagefiles_array packages -nocheck
  ##puts "Done - the number of packages is: $getpackagefiles_array(N_PACKAGES)"

  set n_packages $getpackagefiles_array(N_PACKAGES)
  set package_files ""
  for {set i 1} {$i <= $n_packages} {incr i} {
      ##puts "Package $i is $getpackagefiles_array(PACKAGE_NAME,$i)"
      if { [string match $getpackagefiles_array(PACKAGE_NAME,$i) $package_name] } {
	  set package_files $getpackagefiles_array(PACKAGE_[subst $subdir0],$i)
      }
  }
  if { [info exists getpackagefiles_array] } { unset getpackagefiles_array }
  return $package_files
}

#-----------------------------------------------------------------------
proc GetPackageReferences { packages_file package_name } {
#-----------------------------------------------------------------------
#d_sum Return a list of associated task references registered with a package
#d_desc Returns a list of task references from a ccp4i_packages.def file.
#d_desc Each element of the list is also a list, describing the installed \
task references:
#d_desc {task_title} {task_name} {task_descript} {module_name} {module_title}
#d_desc Optionally the list may contain an two additional items
#d_desc {folder_name} {folder_title}
#d_arg packages_file The full path name of the ccp4i_packages.def file
#d_arg package_name The name of the package of interest
  global getpackagerefs_array

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      ##puts "Packages file \"$packages_file\" not found"
      return ""
  }

  # Get the information from the PACKAGES file
  InitialiseArray $packages_file getpackagerefs_array packages -nocheck

  set n_packages $getpackagerefs_array(N_PACKAGES)
  set package_references ""
  for {set i 1} {$i <= $n_packages} {incr i} {
      if { [string match $getpackagerefs_array(PACKAGE_NAME,$i) $package_name] } {
	  set package_references $getpackagerefs_array(PACKAGE_REFERENCES,$i)
      }
  }
  if { [info exists getpackagerefs_array] } { unset getpackagerefs_array }
  return $package_references
}

#-----------------------------------------------------------------------
proc GetPackageVersion { packages_file package_name } {
#-----------------------------------------------------------------------
#d_sum Return the version string of a CCP4i task package in the \
ccp4i_packages.def file
#d_arg packages_file The full path of the ccp4i_packages.def file
#d_arg package_name The name of the package to examine
  global getpackagevers_array

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      return ""
  }

  # Get the information from the PACKAGES file
  InitialiseArray $packages_file getpackagevers_array packages -nocheck

  set n_packages $getpackagevers_array(N_PACKAGES)
  set package_version ""
  for {set i 1} {$i <= $n_packages} {incr i} {
      ##puts "Package $i has version string $getpackagevers_array(PACKAGE_VERSION,$i)"
      if { [string match $getpackagevers_array(PACKAGE_NAME,$i) $package_name] } {
	  set package_version $getpackagevers_array(PACKAGE_VERSION,$i)
      }
  }
  if { [info exists getpackagevers_array] } { unset getpackagevers_array }
  return $package_version
}

#---------------------------------------------------------------------
proc UpdatePackagesEntry { packages_file package_name args } {
#---------------------------------------------------------------------
#d_sum Update an entry in a ccp4i_packages.def file
#d_desc Updates the existing entry for a CCP4i task package in a \
ccp4i_packages.def file, or creates a new entry if it doesn't currently \
exist.
#d_arg packages_file The full path for the ccp4i_packages.def file
#d_arg package_name  The name of the CCP4i task package
#d_opt0 -version version_string
#d_opt1 Specifies the version string for the package
#d_opt0 -task_files
#d_opt1 List of associated files in the tasks directory (.tcl and .def) 
#d_opt0 -script_files
#d_opt1 List of associated script files
#d_opt0 -com_files
#d_opt1 List of associated template (.com) files
#d_opt0 -help_files
#d_opt1 List of associated help files
#d_opt0 -task_references
#d_opt1 List of associated task references
#d_opt0 -install_script
#d_opt1 Name of an installation script
#d_opt0 -backups
#d_opt1 List of associated backup files
#d_opt0 -modules
#d_opt1 List of modules
# Update an entry in the packages file
# If the package_name doesn't exist in the file then create a new
# entry
  global updatepackages_array

  ##puts "UpdatePackagesEntry: starting"

  # Initialise
  set package_version ""
  set new_version 0
  set package_tasks ""
  set new_tasks 0
  set package_scripts ""
  set new_scripts 0
  set package_templates ""
  set new_templates 0
  set package_help ""
  set new_help 0
  set package_modules ""
  set new_modules 0
  set package_backups ""
  set new_backups 0
  set package_references ""
  set new_references 0
  set package_install_script ""
  set new_install_script 0

  # Process the arguments
  set nargs [llength $args]
  if { $nargs < 1 } {
      puts "WARNING no arguments - nothing to update"
      return 1
  }

  for {set i 0} {$i<$nargs} {incr i} {
      set option [lindex $args $i]
      switch -exact -- $option {
	  -version {
	      # Version string
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_version [lindex $args $i]
	      set new_version 1
	  }
	  -task_files {
	      # List of task files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_tasks [lindex $args $i]
	      set new_tasks 1
	  }
	  -script_files {
	      # List of script files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_scripts [lindex $args $i]
	      set new_scripts 1
	  }
	  -com_files {
	      # List of template files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_templates [lindex $args $i]
	      set new_templates 1
	  }
	  -help_files {
	      # List of help files
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_help [lindex $args $i]
	      set new_help 1
	  }
	  -task_references {
	      # List of task references
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_references [lindex $args $i]
	      set new_references 1
	  }
	  -install_script {
	      # Install script
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_install_script [lindex $args $i]
	      set new_install_script 1
	  }
	  -modules {
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_modules [lindex $args $i]
	      set new_modules 1
	  }
	  -backups {
	      incr i
	      if { $i == $nargs } {
		  puts "ERROR insufficient arguments"
		  return 0
	      }
	      set package_backups [lindex $args $i]
	      set new_backups 1
	  }
	  default {
	      puts "ERROR unrecognised option \"$option\""
	  }
      }
  }

  # Set up the packages file for output
  set packages_file_out $packages_file

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      ##puts "Packages file \"$packages_file\" not found"
      set packages_file_in [file join [GetTaskInstallDir MAIN] etc ccp4i_packages.def.dist]
  } else {
      set packages_file_in $packages_file
  }

  # Get the information from the PACKAGES file
  ##puts "About to read packages file from $packages_file_in"
  InitialiseArray $packages_file_in updatepackages_array packages -nocheck
  ##puts "Done - the number of packages is: $updatepackages_array(N_PACKAGES)"

  # Find the entry to update
  set n_packages $updatepackages_array(N_PACKAGES)
  set package_num 0
  for {set i 1} {$i <= $n_packages} {incr i} {
      ##puts "Package $i is $updatepackages_array(PACKAGE_NAME,$i)"
      if { [string match $updatepackages_array(PACKAGE_NAME,$i) $package_name] } {
	  set package_num $i
      }
  }
  if { $package_num == 0 } {
      # New entry - create a blank entry for this package
      ##puts "New package entry"
      incr updatepackages_array(N_PACKAGES)
      set package_num $updatepackages_array(N_PACKAGES)
      set n $package_num
      set updatepackages_array(PACKAGE_NAME,$n) $package_name
      set updatepackages_array(PACKAGE_VERSION,$n) ""
      set updatepackages_array(PACKAGE_TASKS,$n) ""
      set updatepackages_array(PACKAGE_SCRIPTS,$n) ""
      set updatepackages_array(PACKAGE_TEMPLATES,$n) ""
      set updatepackages_array(PACKAGE_HELP,$n) ""
      set updatepackages_array(PACKAGE_BACKUPS,$n) ""
      set updatepackages_array(PACKAGE_MODULES,$n) ""
      set updatepackages_array(PACKAGE_REFERENCES,$n) ""
      set updatepackages_array(PACKAGE_INSTALL_SCRIPT,$n) ""
      set updatepackages_array(PACKAGE_CCP4I_VERSION,$n) [GetVersion]
  } else {
      ##puts "Existing package entry"
      set n $package_num
  }

  # Update the packages information from the arguments
  # Version
  if { $new_version } {
      set updatepackages_array(PACKAGE_VERSION,$n) $package_version
  }
  # Tasks
  if { $new_tasks } {
      set updatepackages_array(PACKAGE_TASKS,$n) $package_tasks
  }
  # Scripts
  if { $new_scripts } {
      set updatepackages_array(PACKAGE_SCRIPTS,$n) $package_scripts
  }
  # Templates
  if { $new_templates } {
      set updatepackages_array(PACKAGE_TEMPLATES,$n) $package_templates
  }
  # Help files
  if { $new_help } {
      set updatepackages_array(PACKAGE_HELP,$n) $package_help
  }
  # Backup files
  if { $new_backups } {
      set updatepackages_array(PACKAGE_BACKUPS,$n) $package_backups
  }
  # New modules
  if { $new_modules } {
      set updatepackageS_array(PACKAGE_MODULES,$n) $package_modules
  }
  # Task references
  if { $new_references } {
      set updatepackages_array(PACKAGE_REFERENCES,$n) $package_references
  }
  # Install script
  if { $new_install_script } {
      set updatepackages_array(PACKAGE_INSTALL_SCRIPT,$n) $package_install_script
  }
  
  # Write out the updated file
  ##puts "About to save the updated arrays to $packages_file_out"
  if { ![SaveArray packages $packages_file_out updatepackages_array -notype] } {
      WarningMessage "ERROR saving parameters to file $packages_file_out"
  }
  ##puts "Updated packages entry - done"

  # Better zap the packages global array now
  if {[info exists updatepackages_array]} {
      unset updatepackages_array
  }
  return
}

#---------------------------------------------------------------------
proc RemovePackagesEntry { packages_file package_name } {
#---------------------------------------------------------------------
#d_sum Remove an existing entry from a ccp4i_packages.def file
#d_desc 
#d_arg packages_file The full path for the ccp4i_packages.def file
#d_arg package_name The name of the CCP4i task package whose entry is \
to be removed.
  global removepackages_array

  ##puts "RemovePackagesEntry: starting"

  # Check that the packages file exists
  if {![file exists $packages_file]} {
      ##puts "Packages file \"$packages_file\" not found"
      return 0
  }

  # Get the information from the PACKAGES file
  ##puts "About to read packages file from $packages_file"
  InitialiseArray $packages_file removepackages_array packages -nocheck
  ##puts "Done - the number of packages is: $removepackages_array(N_PACKAGES)"

  # Find the entry to remove
  set n_packages $removepackages_array(N_PACKAGES)
  set package_num 0
  for {set i 1} {$i <= $n_packages} {incr i} {
      ##puts "Package $i is $removepackages_array(PACKAGE_NAME,$i)"
      if { [string match $removepackages_array(PACKAGE_NAME,$i) $package_name] } {
	  set package_num $i
      }
  }
  if { $package_num == 0 } {
      ##puts "Couldn't find a package called \"$package_name\""
      return 0
  }

  # Overwrite this entry with the last in the file, unless it is
  # already the last
  set n $n_packages
  if { $package_num < $n } {
      set i $package_num
      set removepackages_array(PACKAGE_NAME,$i) \
	      $removepackages_array(PACKAGE_NAME,$n)
      set removepackages_array(PACKAGE_VERSION,$i) \
	      $removepackages_array(PACKAGE_VERSION,$n)
      set removepackages_array(PACKAGE_TASKS,$i) \
	      $removepackages_array(PACKAGE_TASKS,$n)
      set removepackages_array(PACKAGE_SCRIPTS,$i) \
	      $removepackages_array(PACKAGE_SCRIPTS,$n)
      set removepackages_array(PACKAGE_TEMPLATES,$i) \
	      $removepackages_array(PACKAGE_TEMPLATES,$n)
      set removepackages_array(PACKAGE_HELP,$i) \
	      $removepackages_array(PACKAGE_HELP,$n)
      set removepackages_array(PACKAGE_MODULES,$i) \
	      $removepackages_array(PACKAGE_MODULES,$n)
      set removepackages_array(PACKAGE_BACKUPS,$i) \
	      $removepackages_array(PACKAGE_BACKUPS,$n)
      set removepackages_array(PACKAGE_REFERENCES,$i) \
	      $removepackages_array(PACKAGE_REFERENCES,$n)
      set removepackages_array(PACKAGE_INSTALL_SCRIPT,$i) \
	      $removepackages_array(PACKAGE_INSTALL_SCRIPT,$n)
      set removepackages_array(PACKAGE_CCP4I_VERSION,$i) \
	      $removepackages_array(PACKAGE_CCP4I_VERSION,$n)
  }
  # Unset the last entry and decrement the number of packages
  incr removepackages_array(N_PACKAGES) -1
  unset removepackages_array(PACKAGE_NAME,$n)
  unset removepackages_array(PACKAGE_VERSION,$n)
  unset removepackages_array(PACKAGE_TASKS,$n)
  unset removepackages_array(PACKAGE_SCRIPTS,$n)
  unset removepackages_array(PACKAGE_TEMPLATES,$n)
  unset removepackages_array(PACKAGE_HELP,$n)
  unset removepackages_array(PACKAGE_BACKUPS,$n)
  unset removepackages_array(PACKAGE_MODULES,$n)
  unset removepackages_array(PACKAGE_REFERENCES,$n)
  unset removepackages_array(PACKAGE_INSTALL_SCRIPT,$n)
  unset removepackages_array(PACKAGE_CCP4I_VERSION,$n)

  # Write out the updated file
  ##puts "About to save the updated arrays to $packages_file"
  if { ![SaveArray packages $packages_file removepackages_array -notype] } {
      WarningMessage "ERROR saving parameters to file $packages_file"
  }
  ##puts "Done"

  # Better zap the packages global array now
  if {[info exists removepackages_array]} {
      unset removepackages_array
  }
  return 1
}

#---------------------------------------------------------------------
proc CreateTarFile { file tar_dir { parent_dir {} } } {
#---------------------------------------------------------------------
#d_sum Apply 'tar cf' to dir to create a tar file
#d_arg file       Full pathname of tar file to create
#d_arg tar_dir    Name of directory to archive relative to parent_dir
#d_arg parent_dir Directory to move to before creating tar file
  global system
  # Windows
  if { [regexp WINDOWS $system(OPSYS) ] } {
    WarningMessage "CreateTarFile not implemented for this system"
    return 0
  }
  # Unix
  set cwd [GetCurrentDir]
  if { $parent_dir != "" } {
      if { [file isdirectory $parent_dir] } {
	  ChangeDirectory $parent_dir
      } else {
	  return 0
      }
  }
  set tar_result [expr 1 - [catch {exec tar cf $file $tar_dir} ]  ]
  ChangeDirectory $cwd
  return $tar_result
}

#---------------------------------------------------------------------
proc ValidatePackageName { package_name } {
#---------------------------------------------------------------------
#d_sum Check that the supplied package name is valid
#d_desc Package names should only contain letters, numbers and \
underscores.
#d_arg package_name Package name to check.
  return [regexp -- "^\[A-Za-z0-9_\]*$" $package_name]
}

#---------------------------------------------------------------------
proc ComparePackageVersions { version1 version2 } {
#---------------------------------------------------------------------
#d_sum Compare version strings for CCP4i task packages
#d_desc Version strings should be of the form a(.b(.c)) i.e. \
major(minor(patch)).
#d_desc Returns 0 if the versions are equivalent, 1 if version1 is \
higher than version2, 2 if version2 is higher than version1, or -1 \
if the comparison is ambiguious (e.g. one or both are not of the \
correct format).
#d_arg version1 First version string
#d_arg version2 Second version string

    ##puts "ComparePackageVersions: comparing \"$version1\" with \"$version2\""

    # Check for ambigious versions
    if { [regexp -- "^\[0-9.\]*\$" $version1] } {
	##puts "ComparePackageVersions: \"$version1\" is ambigious version"
	return -1
    }
    if { [regexp -- "^\[0-9.\]*\$" $version2] } {
	##puts "ComparePackageVersions: \"$version2\" is ambigious version"
	return -1
    }
    # Split on "."
    set version1_list [split $version1 .]
    set version2_list [split $version2 .]
    set nnum1 [llength $version1_list]
    set nnum2 [llength $version2_list]

    # Check for sensible number of elements in each version string
    if { $nnum1 < 1 || $nnum1 > 3 || $nnum2 < 1 || $nnum2 > 3 } {
	##puts "ComparePackageVersions: ambigious comparision"
	return -1
    }
    
    # Compare major, minor and patch versions
    set i 0
    foreach vers [list major minor patch] {
	##puts "ComparePackageVersions: examining $vers version numbers"
	if { $nnum1 > $i } {
	    set ele1 [lindex $version1_list $i]
	} else {
	    set ele1 ""
	}
	if { $nnum2 > $i } {
	    set ele2 [lindex $version2_list $i]
	} else {
	    set ele2 ""
	}
	# Do comparisions
	# Lists have both run out - versions must be the same
	if { $ele1 == "" && $ele2 == "" } {
	    ##puts "ComparePackageVersions: versions are equivalent"
	    return 0
	} elseif { $ele1 == "" } {
	    ##puts "ComparePackageVersions: version \"$version2\" is higher"
	    return 2
	} elseif { $ele2 == "" } {
	    ##puts "ComparePackageVersions: version \"$version1\" is higher"
	    return 1
	} elseif { $ele1 == $ele2 } {
	    ##puts "ComparePackageVersions: versions are equivalent"
	    return 0
	} elseif { $ele1 > $ele2 } {
	    ##puts "ComparePackageVersions: version \"$version1\" is higher"
	    return 1
	} else {
	    ##puts "ComparePackageVersions: version \"$version2\" is higher"
	    return 2
	}
    }
}

#---------------------------------------------------------------------
proc InstallReport { message run_mode } {
#---------------------------------------------------------------------
#d_sum Report a message from the install procedures.
#d_arg message  Text of message to be displayed
#d_arg run_mode Either graphical (message is displayed in a window) or \
nongraphical (message is written to stdout).
    switch -exact -- $run_mode {
	graphical {
	    WarningMessage "$message"
	}
	nongraphical {
	    puts "$message"
	}
    }
    return
}
