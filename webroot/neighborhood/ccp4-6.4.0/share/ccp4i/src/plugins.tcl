#
#     Copyright (C) 1999-2007  Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - plugins.tcl
#
#
#
# External program interaction utilities
#
# Peter Briggs  Aug07
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Plugin Utilities (src/plugins.tcl)
#d_intro_title Plugin Utilities
#
#d_intro The procedures in this file provide support for a simple "plugins" \
mechanism within CCP4i. A "plugin" is another application outside of CCP4i \
which can be usefully invoked on behalf of the user to view files or perform \
a new action after a particular task has been run. For example, after a run \
of Refmac5 it might be useful to launch Coot to further work on the refined \
structure.

#d_intro Data about which plugins are available for which task is stored in \
the ccp4i_plugins global array. Elements of the array are tasknames; the value \
of each element is a list of plugin names. For each plugin there should be a \
procedure called plugin_for_$pluginname, which returns a text string and a command \
for launching the application given the taskname and a list of files output \
from that task.

#d_intro The GetPlugins procedure provides an interface to the available \
plugins: given a taskname and list of files, it returns the available plugin \
commands that could be invoked.

global ccp4i_plugins

# Initialise data on the available plugins
# Each element of the ccp4i_plugins array is a CCP4i taskname
# The corresponding value is a list of one or more plugin names
# For each plugin a corresponding "plugin_for_*" procedure must be
# defined else where in this file 
if { ![info exists ccp4i_plugins(INIT)] } {
    set ccp4i_plugins(INIT) 1
    set ccp4i_plugins(refmac5) [list \
				    "coot" \
				    "ccp4mg" ]
    set ccp4i_plugins(refmac5_review) [list "coot"]
    set ccp4i_plugins(mrbump) [list \
				   "coot"]
    set ccp4i_plugins(dimple) [list \
				   "coot"]
    set ccp4i_plugins(patterson) [list \
				      "mapslicer"]
    set ccp4i_plugins(dm) [list "coot"]
    set ccp4i_plugins(pirate) [list "coot"]
    set ccp4i_plugins(buccaneer) [list "coot"]
    set ccp4i_plugins(phaser_mr) [list "coot"]
}

#----------------------------------------------------------
proc GetPlugins { taskname filelist } {
#----------------------------------------------------------
#d_sum Return available plugins for a specific task
#d_desc Given the name of a task plus a list of associated files, this \
command checks whether any plugins have been specified for that task \
and attempts to generate commands for launching any that are found.
#d_desc The result of the command is a list of plugin specifications. \
Each specification is also a list, the first element being a string of \
text to be displayed in (e.g.) the "View Files from Job" menu, and the \
other the command to be invoked to start the plugin application.
#d_desc If no plugins are found then an empty list is returned.
#d_arg taskname Name of the task
#d_arg filelist List of full filenames output from the task
    global ccp4i_plugins
    
    # Return immediately if no plugins are defined for this task
    set taskname0 [string tolower $taskname]
    if { ![info exists ccp4i_plugins($taskname0)] } { return {} }

    # Reduce the filelist down to files that actually exist
    set filelist0 {}
    foreach filen $filelist {
	if { [file exists $filen] } {
	    lappend filelist0 $filen
	}
    }

    # Build a list of the available plugins
    set pluginlist {}
    foreach plugin $ccp4i_plugins($taskname0) {
	# Invoke the "plugin_for_$plugin" procedure for each plugin
	# This will return button text and an associated launch command,
	# or an empty list if the plugin cannot be launched in this case
	if { [set cmd [eval "plugin_for_$plugin" "$taskname0" \
			   { $filelist0 }]] != {} } {
	    lappend pluginlist $cmd
	}
    }
    # Return the list of plugins
    return $pluginlist
}

#----------------------------------------------------------
proc get_plugin_executable { program execVar } {
#----------------------------------------------------------
#d_sum Helper function: verify and return the executable name
#d_desc This command wraps FindExecutable. It returns 1 if the \
specified executable is found, and the executable path is returned \
in the specified variable. Otherwise it returns 0.
#d_arg program Name of the program executable to be found
#d_arg execVar Name of the variable to return the name in, if found
    # Return
    upvar $execVar exe
    if { [set exe [FindExecutable $program]] == "" } {
	return 0
    }
    return 1
}

#d_index_title Plugin Command Generation Functions
#d_intro_title Plugin Command Generation Functions
#
#d_intro The functions in this section generate the appropriate commands \
for launching the plugin applications for specified task contexts and \
available output files.
#
#d_intro Each plugin should have an associated plugin_for_* procedure \
defined, which should take exactly two arguments: the first is the \
name of a task, and the second is a list of files from a job. The \
procedure should contain code specific to the plugin application, and \
return a list of two elements - the first is a string of text that \
describes the operation of the plugin when launched, and the second \
is the actual command to launch the plugin in background.
#d_intro If no plugin is available then an empty list should be returned.

#----------------------------------------------------------
proc plugin_for_coot { taskname filelist } {
#----------------------------------------------------------
#d_dsum Check and return plugin commands for Coot
#d_arg taskname Name of the task
#d_arg filelist List of files output from a run of the task

    global configure

    # Check that a Coot executable is available
    if { ! [get_plugin_executable $configure(RUN_COOT) coot_exe] } { return {} }

    # To launch Coot with predefined files:
    # coot --pdb refmac-out.pdb --auto refmac-in.mtz --dictionary ligand.cif
    # --no-state-script
    set cmd "RunCoot --no-state-script"
    if { $taskname == "refmac5" || $taskname == "mrbump" || $taskname == "dimple" } { 
	# Find MTZ and PDB file plus any others (optional)
	# and build the Coot command line
	set got_mtz 0
	set got_pdb 0
	foreach filen $filelist {
	    switch -regexp $filen {
		".*\.mtz\$" {
		    # MTZ file
		    append cmd " --auto $filen"
		    incr got_mtz
		}
		".*\.pdb\$" {
		    # PDB file
		    append cmd " --pdb $filen"
		    incr got_pdb
		}
		".*\.refmac\.cif$" {
		    # Data harvesting file, ignored
		}
		".*\.cif\$" {
		    # CIF file - assume it's a dictionary
		    append cmd " --dictionary $filen"
		}
	    }
	}
	if { $got_mtz && $got_pdb } {
	    # There are enough files to launch Coot
	    return [list "View result of refinement in Coot" $cmd]
	}
    }
    if { $taskname == "phaser_mr" } {
        # Find MTZ and PDB file plus any others (optional)
        # and build the Coot command line
        set got_mtz 0
        set got_pdb 0
        foreach filen $filelist {
            switch -regexp $filen {
                ".*\.mtz\$" {
                    # MTZ file
                    append cmd " --auto $filen"
                    incr got_mtz
                }
                ".*\.pdb\$" {
                    # PDB file
                    append cmd " --pdb $filen"
                    incr got_pdb
                }
            }
        }
        if { $got_mtz && $got_pdb } {
            # There are enough files to launch Coot
            return [list "View result of MR in Coot" $cmd]
        }
    }
    if { $taskname == "refmac5_review" || $taskname == "buccaneer" } {
	# Allow launch of PDB file alone
	set got_pdb 0
	foreach filein $filelist {
	    switch -regexp $filein {
		".*\.pdb\$" {
		    # PDB file
		    append cmd " --pdb $filein"
		    set got_pdb 1
		}
	    }
	}
	if { $got_pdb } {
	    # There are enough files to launch Coot
	    return [list "Review coordinates using Coot" $cmd]
	}    
    }
    if { $taskname == "dm" || $taskname == "pirate" } {
	# Allow launch of MTZ file alone
	set got_mtz 0
	foreach filein $filelist {
	    switch -regexp $filein {
		".*\.mtz\$" {
		    # MTZ file
		    append cmd " --data $filein"
		    set got_mtz 1
		}
	    }
	}
	if { $got_mtz } {
	    # There are enough files to launch Coot
	    return [list "Review phases using Coot" $cmd]
	}    
	
    }
    # No match to supplied task and/or file list
    return {}
}

#----------------------------------------------------------
proc plugin_for_ccp4mg { taskname filelist } {
#----------------------------------------------------------
#d_dsum Check and return plugin commands for CCP4mg
#d_arg taskname Name of the task
#d_arg filelist List of files output from a run of the task

    global configure

    # Check that a CCP4mg executable is available
    if { ! [get_plugin_executable $configure(RUN_CCP4MG) ccp4mg_exe] } { return {} }

    # To launch CCP4mg with predefined files:
    # ccp4mg -norestore -pdb $pdb -map $map -mtz $mtz
    set cmd "RunCCP4mg -norestore"
    if { $taskname == "refmac5" } {
	# Find MTZ and PDB file plus any others (optional)
	# and build the CCP4mg command line
	set got_mtz 0
	set got_pdb 0
	foreach filen $filelist {
	    switch -regexp $filen {
		".*\.mtz\$" {
		    # MTZ file
		    append cmd " -mtz $filen"
		    incr got_mtz
		}
		".*\.pdb\$" {
		    # PDB file
		    append cmd " -pdb $filen"
		    incr got_pdb
		}
		".*\.map\$" {
		    # MAP file
		    append cmd " -map $filen"
		}
	    }
	}
	if { $got_mtz && $got_pdb } {
	    # There are enough files to launch CCP4mg
	    return [list "View result of refinement in CCP4mg" $cmd]
	}
    }
    # No match to supplied task and/or file list
    return {}
}

#----------------------------------------------------------
proc plugin_for_mapslicer { taskname files } {
#----------------------------------------------------------
#d_dsum Check and return plugin commands for Mapslicer
#d_arg taskname Name of the task
#d_arg filelist List of files output from a run of the task

    global configure

    if { ! [get_plugin_executable $configure(RUN_MAPSLICER) mapslicer_exe] } {
	return {}
    }

    if { $taskname == "patterson" } {
	set cmd "RunMapslicer"
	# Deal with ouput from patterson task
	set got_map 0
	foreach filen $files {
	    switch -regexp $filen {
		".*\.map\$" {
		    # Assume map file is a Patterson
		    append cmd " \"$filen\""
		    incr got_map
		}
	    }
	}
	if { $got_map } {
	    # There are enough files to launch Mapslicer
	    return [list "View patterson in MapSlicer" $cmd]
	}
    }
    # Nothing available
    return {}
}
