#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - system.tcl
#
#
#
# This script is run first by all CCP4 interface programs 
# It sets up some basic system dependent functions (mostly 
# to do with file handling and operating system functions) 
# and then runs the script whose name is passed to it on the 
# command line
#
# Liz Potterton Mar97
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Initialisation and Utilities (system.tcl and utils.tcl)
#d_intro_title Initialisation and Utilities 
#d_intro The system.tcl and utils.tcl files contains many basic commands \
which are used throughout ccp4i. These two files are  sourced immediately \
by bin/ccp4i.tcl and all other 'main' scripts to provide the basic \
functionality for boot strapping up the ccp4i system.\
#d_intro Some of the procedures interact with the operating \
system and are therefore platform dependent. NOTE Some of these are no \
more than wrappers to Tcl \
commands - as a matter of policy any function which might conceivably be \
problematic on porting has been wrapped. In practice Tcl seems to handle \
porting very well.

#d_index_title Def Files
#d_intro_title Def Files
#d_intro The def file has identifier data at \
the top of the file written by WriteIdentifier. Def files may have two \
items per line, the parameter name and the parameter value or they may have \
three items: parameter name, parameter type and parameter value. The def files \
in $CCP4I_TOP/tasks include the parameter type which is needed to define the \
widget type when drawing a task window. Other def files do not need to contain \this information.  When initialising an array CCP4i normally reads the \
distributed def file which contains the parameter types and the parameters \
consistent with the distributed graphical interface; this ensures that the \
the graphical window can be drawn safely. These parameters may \
be overlaid and customised by reading another def file.  
#d_intro The preferences files are special cases of def files which might \
be considered to go with the tasks: preferences, configure and directories. \
All of these preferences have global arrays which may be accessed from any \
procedure within CCP4i which needs information from them.  The task windows \
to edit the preferences and configure data are tasks/pref.tcl and \
tasks/config.tcl - note that these windows set up another temporary array \
for the data and do not directly access the preferences and configure arrays. \
The directories task window is defined in src/directories.tcl and does \
directly edit the directories array - this is probably not a good thing.
#d_intro The command InitialiseArray will read data from an def file \
to an array and SaveArray will save data from an array to a def file. \
The InitialisePreferences and SavePreferences commands are used for the \
preferences files to access files in the appropriate directory.


#--------------------------------------------------------------------
proc InitialiseArray { filn arrayname taskname args } {
#--------------------------------------------------------------------
#d_sum Initialise an array with data from a def file
#d_arg filn Def file name
#d_arg arrayname Name of array to be loaded with data
#d_arg taskname The name of a task which should correspond to the \
identifier in the def file
#d_opt0 -nocheck
#d_opt1 Do not check that def file has correct task identifier
#d_opt0 -reportlabel
#d_opt1 If def file does not have correct identifier then ask user if they \
still want to read it.

  upvar #0 $arrayname array

# Initialise an array from a def file
# Create a parameter PARAM_LIST which is list of names of all input
# parameters - this list usually used to write out the same file

  set check 1
  set query_check 0
  set nargs [llength $args]; set n 0
  while  { $n < $nargs }  {
   set comd [lindex $args $n]
   if {[regexp -- "-nocheck" $comd]} {
     set check 0
   } elseif {[regexp -- "-reportlabel" $comd]} {
     set query_check 1
   }
   incr n
  }

  if { [catch {open $filn r }  f ] } {
    Report 3 "Could not open initialisation file $filn"
    return 0
  }
  if { ![ElementExists $arrayname PARAM_LIST] } {
    set array(PARAM_LIST) ""
  }

  if { $check } {

    set checked 0
    while { $checked == 0 && [gets $f line] >= 0 } {
      if { [string first CCP4I $line] >= 0 &&
           [string first SCRIPT $line] >= 0 } {
         if { ( [string first DEF $line] >= 0 || [string first DB $line] >= 0) && [string first $taskname $line] >=0 } {
           set checked 1
         } else {
           set checked -1
         }
      }
    }

    if { $checked <= 0 } {
      if { $query_check } {
        set action [ ChooseOptionDialog "Correct File" "Correct File" \
        "The file $filn
has script identifier: $line
which is not correct for initialising $taskname
do you want to continue reading the file?" \
        [list "Abort Reading" "Continue Reading" ] ]
        if { $action == "Abort Reading" } {
          close $f
          return 0
        }
      } else {
	catch {
	    puts "Def file $filn"
	    puts "does not have correct file label $taskname"
	}
      }
    }
  }
# merge lines which have continuation character
  set textin [split [ read $f ] "\n"]
  CloseFile $f
  set full_text ""
  foreach line $textin {
    if { [string range $line end end] == "\\" } {
      append buffer [string range $line 0 [expr {[string length $line] -2}]]
    } else {
      append buffer $line
      lappend full_text $buffer
      set buffer ""
    }
  }

  if { [llength $full_text] <= 0 } { return 0 }

  set nl 0; set nl_full_text [llength $full_text]
  while { $nl < $nl_full_text } { incr nl; set line [lindex $full_text $nl]
    if { [string length $line ] > 0 } {
# Handle insertion of data from another def file
       switch [string range $line 0 0 ] \
       "@" {
         eval "set filename [string range $line 1 end]"
         if { [ReadFile $filename tmp_full_text -split] } {
	   # Insert the file contents at the correct position
	   set full_text [concat [lrange $full_text 0 $nl] \
			      $tmp_full_text [lrange $full_text [expr {$nl + 1}] end]]
           set nl_full_text [llength $full_text]
         }
       } "#" {
       } default {
         set element [lindex $line 0 ]
         switch [llength $line] \
         2 {
           set array($element) [lindex $line 1]
         } 3 {
           set array(_$element) [lindex $line 1]
           set array($element) [lindex $line 2]
#            if {[catch "set value [lrange $line 2 end]"]} {
#              Report 1 "ERROR reading value of parameter $element from file $filn"
#              set value ""
#            }
         }
         if { ![regexp {,[1-9]} $element] && \
		 [lsearch $array(PARAM_LIST) $element ] < 0 } {
           lappend array(PARAM_LIST) $element
         }
	 # Check for reserved prefixes that are normally used for
	 # internal admin variables
	 if { $element != "" && [reserved_prefix $element] } {
	   catch {
	       puts "Def file $filn"
	       puts "Parameter $element uses a reserved prefix"
	   }
	 }
       }
    }
  }
# set INITIAL_DEF to contain the name of the initialisation def file
# if it is not the interface default

  set filn_list [file split $filn]
  set ll [llength $filn_list]
  if {[regexp tasks [lindex $filn_list [expr {$ll -2}]]]} {
    set array(INITIAL_DEF) ""
  } else {
    set array(INITIAL_DEF) $filn
  }
#  puts "INITIAL_DEF $array(INITIAL_DEF)"
#  puts " $arrayname PARAM_LIST $array(PARAM_LIST) "

  return 1
}

#--------------------------------------------------------------------
proc reserved_prefix { { name "" } } {
#--------------------------------------------------------------------
#d_sum Check whether a parameter name has a reserved prefix
#d_desc Given a parameter name this command returns 1 if the name \
has a prefix matching the list of prefixes used to denote internal \
administrative variables in CCP4i.
#d_desc If no name is given then the procedure returns the list of \
reserved prefixes.
#d_arg name (optional) Parameter name to check 
  set reserved [list \
	  WIDGET_* \
	  LABEL_* \
	  XF_* \
	  HELP_* \
	  FRAME_* \
	  DEPVARS_* \
	  N_DEPFRAMES_* \
	  DEPFRAMES_* \
	  CHILD_* \
	  PARENT_* \
	  VARS_* ]

  if { $name == "" } {
    # Return the list of reserved prefixes
    return $reserved
  }

  # Check if the name matches any of the reserved prefixes
  foreach rname $reserved {
    if { [string match $rname $name] } {
      return 1
    }
  }
  return 0
}

#--------------------------------------------------------------------
proc WriteIdentifier { f  script args  } {
#--------------------------------------------------------------------
#d_sum Write header to CCP4i file (mainly used for def files)
#d_desc The standard header parameters are written automatically : \
VERSION, SCRIPT, DATE & USER.  All other parameters should be entered as \
name-value pairs and will be output in the usual format of
#d_desc #CCP4I NAME value
#d_arg f If this is input as an empty string then the header text is \
returned in this argument.  Otherwise f is interpreted as an io channel id \
and the header text is written to that channel.
#d_arg script The script type (e.g. DEF for a def file)
#d_arg { name value }  There can be any number of additional arguments each of \which is a list of two items: the name of a parameter and its value.

  global system
  global job_params

# Setup the standard file header info 
  set date [GetDate]
  set user [GetUserId]
  set text "#CCP4I VERSION $system(VERSION)
#CCP4I SCRIPT $script
#CCP4I DATE $date
#CCP4I USER $user"

# Expect args to be in pairs of keyword and parameter
# if parameter is a null string then test if it is an element of job_params array

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    set keyword [lindex $args $n ]
    incr n;set param [lindex $args $n]
    if { $param == ""  && [ElementExists job_params $keyword] } {
      set param $job_params($keyword)
    }
    append text "\n#CCP4I $keyword $param"
    incr n 
  }
# If f is a channel id then write text to that channel 
# If f is null string then put text in that string to return to 
#   calling procedure
  if { $f == {} } { return "$text\n" } else { puts $f $text }
}


#----------------------------------------------------------------------
proc SaveArray { taskname filn arrayname args } {
#----------------------------------------------------------------------
#d_sum Save the data in an array to a def file
#d_desc The array should contain an element PARAM_LIST which contains \
a list of the elements of the array to be written out.  The parameter \
name in the def file will be the same as the element name  in the array. \
The PARAM_LIST is usually created by InitialiseArray when it reads in \
the def file to define the contents of the array.  Additional elements \
may be added to the array to be used as control parameters when the array \
is represented in a task window.  The def file has identifier data at \
the top of the file written by WriteIdentifier. Def files may have two \
items per line, the parameter name and the parameter value or they may have \
three items: parameter name, parameter type and parameter value.
#d_opt0 -save_types
#d_opt1 Save the parameter types in addition to their values
#d_opt0 -no_ident
#d_opt1 Do not write identifier text in the file header
#d_opt0 -notype
#d_opt1 Indicates there is no parameter typing information in the array
#d_opt0 -query_overwrite
#d_opt1 Prompt user before overwriting an existing file
#d_opt0 -append
#d_opt1 Append output to existing file (default is to overwrite)
#d_opt0 -job job_id
#d_opt1 Write specified job_id number to the identifier text
  upvar #0 $arrayname array
  set save_types 0
  set identifier 1
  set open_mode -overwrite
  set query_overwrite 0
  set job_id {}
  set notype 0

  if { ![ElementExists $arrayname PARAM_LIST] } {
    Report 3 "Can not save data to $filn - no PARAM_LIST"
    return 0
  }

  set n 0; set nargs [expr {[llength $args] - 1} ]
  while { $n <= $nargs } {
    switch -regexp -- [lindex $args $n] \
    save_types {
      set save_types 1
    } no_ident {
      set identifier 0
    } notype {
      set notype 1
    } query_overwrite {
      set query_overwrite 0
    } append {
      set open_mode ""
    } job {
      incr n; set job_id [lindex $args $n]
    }
    incr n
  }
  if { $query_overwrite && [file exists $filn ] } {

    set mode [ ChooseOptionDialog "File Exists" "File Exists" \
        "File $filn already exists - overwrite it or select alternative file" \
         [list "Quit" "Select Alternative File" "Overwrite" ] -default 2 ]
    if {[regexp Quit $mode  ]} {
      return 0
    } elseif {[ regexp Alternative $mode ]} {
      if { ![SelectFile filn -title "Save Parameters for $taskname" \
        -defdir [GetCurrentProject] -filter "*.def" \
        -parent $arrayname -unknown ] } { return 0 }
    } else {
      DeleteFile [lindex $filn 0]
    }
  }

  if { $identifier } { 
    if { $job_id == "" } { 
      set text [WriteIdentifier {} "DEF $taskname" ]
    } else {
      set text [WriteIdentifier {} "DEF $taskname" JOB_ID $job_id]
    }
  }

  if { $notype } {

# We know there is no typing available so dont try to get it - treat all as text
  set dtype _text
  set type text
  foreach item [lsort $array(PARAM_LIST)] {
    GetIndx $item root c1 c2
    if { $c1 == "" } {
      set varlist $root
    } elseif { $c1 == 0 } {
      set varlist [GetIndexedElements0 $arrayname $root ]
    } else {
      set varlist ""
    }
    foreach var $varlist {
      set value $array($var)
      WriteDefLine text $var "$value"
    }
  }

  } else {

  foreach item [lsort $array(PARAM_LIST)] {
    GetIndx $item root c1 c2
    set dtype _text
    if { $c1 == "" } {
      if { [catch {set dtype $array(_$root)}] } { Report 3 "ERROR no type for $root" }
      set type [GetTypeInfo $arrayname $item type]
      set varlist $root
    } elseif { $c1 == 0 } {
      if { [catch {set dtype $array(_$root,0)}] } { Report 3 "ERROR no type for [subst $root],0" }
      set type [GetTypeInfo $arrayname $item type]
      set varlist [GetIndexedElements0 $arrayname $root ]
    } else {
      set varlist ""
    }
    foreach var $varlist {
      switch -regexp -- $type \
      menu {
        set value [GetMenuValue $arrayname $var ]
      } default {
        set value $array($var)
      }
      if { $save_types } {
        WriteDefLine1 text $var $dtype "$value"
      } else {
        WriteDefLine text $var "$value"
      }
    }
  }
  }

  if { ![WriteFile $filn $text $open_mode ] } {
    Report 3 "Could not save parameters to file $filn"
    return 0
  } else {
    return 1
  }
}

#-------------------------------------------------------------------------
proc WriteDefLine { fVar var {value ""} } {
#-------------------------------------------------------------------------
#d_sum Create a text line for the def file to define one parameter
#d_arg fVar Returned. Text string to which the new line is appended
#d_arg var The name of the parameter
#d_arg value The value of the parameter. Optional. Default empty.
  upvar $fVar f
  set lvalue [string length $value]
  set lvar  [expr {[max [string length $var]  25] + 1} ]
  if { $value == "" || [regexp " " $value]} {
    append f "[format %-[subst $lvar]s%-1s%-[subst $lvalue]s%-1s \
	 $var "\"" "$value" "\"" ]" \n
  } else {
    append f "[format %-[subst $lvar]s%-[subst $lvalue]s \
	$var $value ]" \n
  }
}

#-------------------------------------------------------------------------
proc WriteDefLine1 { fVar var type {value ""} } {
#-------------------------------------------------------------------------
#d_sum Create a text line for the def file to define one parameter including it's data type
#d_arg fVar Returned. Text string to which the new line is appended
#d_arg var The name of the parameter
#d_arg type Data type of the parameter
#d_arg value The value of the parameter. Optional. Default empty.
  upvar $fVar f

  set lvalue [string length $value]
  set lvar  [expr {[max [string length $var]  25] + 1} ]
  set ltype [expr {[max [string length $type] 25] + 1} ]
  if { $value == "" || [regexp " " $value] } {
    append f "[format \
      %-[subst $lvar]s%-[subst $ltype]s%-1s%-[subst $lvalue]s%-1s  \
		$var $type "\"" "$value" "\"" ]" \n
  } else {
    append f "[format \
	%-[subst $lvar]s%-[subst $ltype]s%-[subst $lvalue]s \
		$var $type $value ]" \n
  }
}



#d_index_title Preferences Files
#d_intro_title Preferences Files
#d_intro There are utilities in system.tcl to handle the 'preferences' files, \
which are:
#d_intro configure.def with configuration options for the local installation \
(e.g. printers, remote machines)
#d_intro directories.def which defines the user's project and directory aliases
#d_intro preferences.def which defines some user preferences for graphical CCP4i
#d_intro loggraph.def Preferences for the loggraph program
#d_intro Each of these sets of preferences are treated as a task with a task \
interface for the user to edit parameters and parameters are saved as a \
def file.  The utilities in system.tcl are concerned with loading the \
preferences at CCP4i startup to be saved in global arrays: \
configure, preferences and directories.  These arrays can be accessed from \
anywhere in the ccp4i code but the parameters should NOT be changed - the \
arrays should be regarded as 'read only'.
#d_intro There are distribution versions of the def files called \
$CCP4I_TOP/etc/foo.def.dist  When a user runs CCP4i for the first time \
the distribution file is read, possible amended by an autoconfigure \
procedure and then written to either $CCP4I_TOP/etc/$PLATFORM/foo.def or \
$HOME/.CCP4/$PLATFORM/foo.def.  Subsequently when a user runs CCP4i the \
first configure file found in the order: \
$HOME/.CCP4/$PLATFORM/foo.def, $CCP4I_TOP/etc/$PLATFORM/foo.def, \
$CCP4I_TOP/etc/$PLATFORM/foo.def.dist will be used.

#----------------------------------------------------------------------
proc InitialisePreferences { taskname arrayname args } {
#----------------------------------------------------------------------
#d_sum Initialise the parameters from preferences configure and directories def files
#d_desc This task first reads default parameters from the ccp4i \
installation area and then reads any user preferences in .CCP4/domain directory.  This procedure uses InitialiseArray to load the def file into the array.
#d_arg taskname Name of task (preferences, configure or directories)
#d_arg arrayname Name of array to be loaded with data
#d_opt0 -nouser
#d_opt1 Do not read the user's def files.
  global system
  upvar #0 $arrayname array

  # Debugging: it is undesirable that InitialisePreferences
  # be called with the directories argument from anywhere
  # other than InitialiseDirectories
  # This check and messaging is intended to help detect
  # when this is not happening
  if { $taskname == "directories" } {
      set caller "[info level [expr [info level] -1]]"
      if { [llength $caller] > 0 } { set caller [lindex $caller 0] }
      if { $caller != "InitialiseDirectories" } {
	  puts "InitialisePreferences $taskname: called by $caller"
	  puts "*****************************************************************"
	  puts "*** InitialisePreferences should only be called directly from ***"
          puts "*** InitialiseDirectories                                     ***"
	  puts "*** Please inform the CCP4i maintainer!                       ***"
	  puts "*****************************************************************"
	  puts "Full stack trace:"
	  for { set x [info level] } { $x >= 0 } { incr x -1 } {
	      puts "\t$x:[info level $x]"
	  }
      }
  }

  set make_lock 0
  set read_user 1
  set filename {}
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    nous {
      set read_user 0
    } file {
      incr n; set filename [lindex $args $n]
    } lock {
      set make_lock 1
    }
    incr n
  }
  set retval 1

  InitialiseArray [SearchPath TOP etc $taskname.def.dist] $arrayname $taskname

  # typedef_list_dist comes from configure.def.dist and allows us
  # to add things and not get over-written by configure.def
  if { [StringSame $taskname "configure" ] } {
    set typedef_list_dist $array(TYPEDEF_LIST)
  }

  if { $filename != "" } {
    InitialiseArray $filename $arrayname $taskname
  } elseif { $read_user && 
    [file exists [set filename [datapath $taskname.def -username -domain]]] } {
    if { $make_lock && ![MakeLock $filename] } { return 0 }
    InitialiseArray $filename $arrayname $taskname
    set retval 2
  } elseif { $read_user &&
	[file exists [set filename [datapath $taskname.def -domain ]]] } {
    if { $make_lock && ![MakeLock $filename] } { return 0 }
    InitialiseArray $filename $arrayname $taskname
    set retval 2
  } elseif { [file exists [set filename  \
	[SearchPath TOP etc $system(DOMAIN) $taskname.def ]]] } {
      InitialiseArray $filename $arrayname  $taskname
  } elseif { [file exists \
	[set filename  [SearchPath TOP etc $taskname.def ]]] } {
      InitialiseArray $filename $arrayname  $taskname
  } else {
# The only def file for these parameters was the *.def.dist - so probably first
# run of interface - so try running autoconf 
    if { [llength [info proc autoconf_[subst $system(OPSYS)]_$taskname]] > 0 } {
      if { [autoconf_[subst $system(OPSYS)]_$taskname $arrayname  ] } {
# Check that the subdirectory exists
	if { ![file exists [SearchPath TOP etc $system(DOMAIN)] ] } {
           # Directory doesn't exist so try and make it first
           catch {
	       puts "Creating new directory [SearchPath TOP etc $system(DOMAIN)]"
	       file mkdir [SearchPath TOP etc $system(DOMAIN)]
	   }
	}
        if { [file writable [SearchPath TOP etc $system(DOMAIN)] ] }  {
          set filename [SearchPath TOP etc $system(DOMAIN) $taskname.def]
	  catch {
	      puts "Creating new configure parameters file $filename"
	  }
          SaveArray $taskname $filename $arrayname -save_types
        } else {
          WarningMessage \
"You are the first person to run this version of CCP4i and 
it is trying to automatically configure and save information
to the file:
[SearchPath TOP etc $system(DOMAIN) $taskname.def]
but you do not have write permission for this directory.
Please get the person who installed CCP4i to run it and
do the configure.
It is OK to continue running CCP4i."
        }
      }
    }
  }

#  WarningMessage "InitialisePreferences $taskname $filename"

# The INITIALISATION_MODE indicates if using installation-wide
# parameters (=0) or user's customised parameters (=1)
  set array(INITIALISATION_MODE) [expr {$retval - 1}]

  switch -- $taskname {
    directories {
      catch {update_defdir_menu $arrayname}
    } configure {
      # We over-write the user TYPEDEF_LIST with the one from 
      # the distribution. This allows us to update the list.
      # I'm assuming the user will not want his own list. 
      set array(TYPEDEF_LIST) $typedef_list_dist
      set_configured_menus $arrayname TYPEDEF_LIST
    } preferences {
      set_default_mapviewer $arrayname
      set_default_pdbviewer $arrayname
      set_default_mtzviewer $arrayname
    }
  }
  return $retval
}

#---------------------------------------------------------------------------
proc MakeLock { filename } {
#---------------------------------------------------------------------------
#d_sum Test if a LOCK file exists and query user how to proceed
#d_desc Currently required to handle potential conflict between ccp4i and \
MG accessing directories.def
#d_arg filename Name of file to lock (lockfile will be filename.LOCK)
 
  set lockfile "$filename.LOCK"
  # If there is no lock file or the lock PID is same as current process
  # return 1 (OK)
  if { [LockStatus $lockfile user time pid] } {
    CreateLock $lockfile
    return 1
  } elseif { $pid == [GetPid] } { 
    return 1 
  } else {
    set ret [ ChooseOptionDialog "DirectoriesLock" Lock \
"There is a lock on the file\n$filename
You may be editing this file in another program\n
or the lock may be a fault probably due to program crash.\n
Do you want to delete the lock and continue?" \
    [list "Continue Override Lock" "Quit" ] -default 1 ]
    switch $ret \
    Quit {
      return 0
    } default {
      DeleteLock $lockfile -force
      CreateLock $lockfile
      return 1
    }
  }
}
#--------------------------------------------------------------------------
proc LockStatus { lockfile userVar timeVar { pidVar "" } } {
#--------------------------------------------------------------------------
#d_sum Return status of lock file
#d_desc Return 0 is lock file exists and 1 (i.e. OK to open \
database file) if it does not.
#d_arg project Alias of project
#d_arg db Corresponding database directory
#d_arg userVar Return name of user who created lock file
#d_arg timeVar Return time of creation of lock file
#d_arg pidVar  (Optional) Return id of process which owns the lock file
  upvar $userVar user
  upvar $timeVar time
  if { $pidVar != "" } {
    upvar $pidVar pid
  }

  if { [file exists $lockfile] } {
    Report 2 "LockStatus: lockfile exists $lockfile"
    OpenFile  $lockfile f r
    gets $f line; gets $f line; set user [lindex $line 2]
    gets $f line; set time [lrange $line 1 end]
    gets $f line; set pid [lindex $line end] 
    CloseFile $f
    Report 2 "LockStatus: $user $time $pid"
    return 0
  } else {
    Report 2 "LockStatus: lockfile doesn't exist $lockfile"
    set user ""
    set time ""
    set pid  ""
    return 1
  }
}
#----------------------------------------------------------
proc DeleteLock { lockfile args } {
#----------------------------------------------------------
#d_sum Delete lock file if it belongs to the current process
#d_opt0 -force
#d_opt1 Force deletion of the lock even if not owned by the current \
process

  if { ![file exists $lockfile] } { return }
  set force 0
  if { [lsearch $args "-force"] > -1 } { set force 1 }

  # Only delete the lock if this process actually owns it
  if { [LockStatus $lockfile user time pid] != 0 } {
    Report 2 "DeleteLock: no lock file found"
    return
  }
  if { [GetPid] == $pid } {
    DeleteFile $lockfile
  } elseif { $force } {
    Report 2 "DeleteLock: lock is not owned by this process, forcing removal"
    DeleteFile $lockfile
  } else {
    Report 2 "DeleteLock: lock is not owned by this process, not removed"
  }
  return
}



#-------------------------------------------------------------------------
proc CreateLock { lockfile } {
#-------------------------------------------------------------------------
#d_sum Create a lock file
#d_desc Returns 1 if lock was created, 0 otherwise
#d_arg project Alias of project
#d_arg db Corresponding database directory
  global system

  if { [LockStatus $lockfile user time ] == 0 } {
    return 0
  }
  set status [OpenFile $lockfile f w ]
  if { $status } {
    puts $f "Lock file for [GetSystemVar RUN_MODE]"
    puts $f "Created by [GetUserId]"
    puts $f "Date [GetDate]"
    puts $f "Owned by pid [GetPid]"
    CloseFile $f
    return 1
  } else {
    return 0
  }
}

#---------------------------------------------------------------------------
proc SavePreferences { taskname arrayname args } {
#---------------------------------------------------------------------------
#d_sum Save a directories/preferences/configure/status.def file to user's directory
#d_desc Presently these are saved to directory $HOME/.CCP4/$domain where \
domain is unix or windows
#d_arg taskname Name of the task (i.e. directories preferences configure or \
status).
#d_arg arrayname name of array containing data
  global system
  set test_lock 0
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    lock {
      set test_lock 1
    }
    incr n
  }

  set filename [datapath $taskname.def -user -domain -create]
  if { $test_lock && ![LockStatus "$filename.LOCK" user time pid] && \
                $pid != [GetPid] } { 
    set ret [ ChooseOptionDialog "DirectoriesLock" Lock \
"There is a lock on the file\n$filename
You may be editing this file in another program\n
or the lock may be a fault probably due to program crash.\n
Do you want to delete the lock and continue?" \
    [list "Continue Saving File" "Quit" ] -default 1 ]

    switch $ret \
    Quit {
      return 0
    }
  }

  if { ![SaveArray $taskname $filename $arrayname -save_types] } {
   WarningMessage "ERROR saving parameters to file $filename"
  }
  if {$test_lock} { DeleteLock "$filename.LOCK" -force } 

}

#----------------------------------------------------------------------------
proc SaveInstallPreferences { taskname arrayname } {
#----------------------------------------------------------------------------
#d_sum Save the preferences to the CCP4i installation area
#d_arg taskname Name of the task (i.e. directories preferences configure or \
status).
#d_arg arrayname name of array containing data
  global system
  set filename [SearchPath TOP etc $system(DOMAIN) $taskname.def]
  if { [file writable [file dirname $filename]] } {
    SaveArray $taskname $filename $arrayname -save_types
  } else {
    WarningMessage "You do not have write permission for $filename
Try saving to your home directory"
  }
}


#--------------------------------------------------------------------
proc update_defdir_menu { arrayname } {
#--------------------------------------------------------------------
#d_sum Update the project/alias menus that appears in file selection
#d_desc When the user changes the projects or aliases in the 'Directories \
and ProjectDir' window this command will update the menus in all \
currently drawn task windows and file selection windows.
#d_desc This command called from InitialisePreferences so needs to be \
in system.tcl to ensure it is defined when called - but it more \
naturally belongs in windows.tcl. 
#d_desc  system(DEFDIR_WIDGET_LIST) contains a list of all widgets \
for parameters of type _default_dir.  This list is updated by CreateLine \
whenever it draws such a widget. The list is not updated when widgets are \
destroyed.
#d_arg arrayname Name of directories array

  global system

  set ll [list "[GetSystemVar PATHNAME_LABEL]" ]
  if { $arrayname == "directories" } {
      # Use the interface to the directories data
      set ll [concat $ll [ListProjects] [ListDefdirs]]
      SetDefdirMenu $ll
  } else {
      # Use the original code
      upvar #0 $arrayname array
      for { set n 1 } { $n <= $array(N_PROJECTS) } { incr n } {
	  lappend ll $array(PROJECT_ALIAS,$n)
      }
      for { set n 1 } { $n <= $array(N_DEF_DIRS) } { incr n } {
	  lappend ll $array(DEF_DIR_ALIAS,$n)
      }
      set array(DEFDIR_MENU) $ll
  }

  set lw ""
  foreach w $system(DEFDIR_WIDGET_LIST) {
    if {[winfo exists [lindex $w 0] ]} {
      update_menu0 [lindex $w 0] [lindex $w 1] [lindex $w 2] $ll
      lappend lw $w
    }
  }
  set system(DEFDIR_WIDGET_LIST) $lw
}

#d_index_title CCP4i Startup Utilities

#-----------------------------------------------------
proc ElementExists { arrayname element } {
#-----------------------------------------------------
#d_sum Test if a given element name exists in an array
#d_desc Return 1 if array element exists, otherwise return 0 \
#d_arg arrayname Name of array
#d_arg element Name of element
#  if { ![array exists $arrayname] } { return 0 }

  upvar #0 $arrayname array

  if { [array names array $element] == $element } {
    return 1
  } else {
    return 0
  }
}

#---------------------------------------------------------------------
proc autoconf_BLT_LIBRARY { arrayname } {
#---------------------------------------------------------------------
  if { [regsub bin$ [GetEnvPath CCP4I_TCLTK ] lib lib_path ] } {
    foreach blt [list blt2.4 blt2.3 blt] {
      if { [file exists [set blt_path [FileJoin $lib_path $blt ] ] ] } {
        upvar #0 $arrayname array
        set array(BLT_LIBRARY) $blt_path
        break
      }
    }
  }
}

#---------------------------------------------------------------------
proc autoconf_UNIX_configure { arrayname args } {
#---------------------------------------------------------------------
#d_sum Attempt to configure the configure parameters for a UNIX system
#d_desc Invoked if there is no configure.def file defined for the UNIX \
system.  Initial parameters are taken from CCP4I_TOP/etc/configure.def.init
#d_arg arrayname Name of configure array

  upvar #0 $arrayname array

  Report 1 "Running auto-configure for configure"

# Set the background colour
  catch {
    frame .fdummy
    set configure(COLOUR_BACKGROUND) [.fdummy cget -background]
    destroy .fdummy
  }

  set array(START_NETSCAPE) [SearchPath TOP utils start_netscape.csh]

# set array(COLOUR_DISABLED) "lightgray"
  set array(COLOUR_DISABLED) "darkgrey"

  autoconf_BLT_LIBRARY $arrayname

  set array(RUN_CCP4I) ccp4ish
  set array(RUN_LOGGRAPH) loggraph
  set array(RUN_MAPSLICER) mapslicer
  set array(RUN_TOPDRAW) topdraw
  set array(RUN_CCP4MG) [file join [GetEnvPath CCP4] .. ccp4mg bin ccp4mg]
  set array(RUN_COOT) [file join [GetEnvPath CCP4] coot.app]
  if { ![file isdir $array(RUN_COOT)] } {
    set array(RUN_COOT) [file join [GetEnvPath CCP4] bin coot]
  }
  return 1
}


#---------------------------------------------------------------------
proc autoconf_WINDOWS_configure { arrayname args } {
#---------------------------------------------------------------------
#d_sum Attempt to configure the configure parameters for a WINDOWS system
#d_arg arrayname Name of the configure array
  upvar #0 $arrayname array

  Report 1 "Running auto-configure for configure"

# Set the background colour
  catch {
    frame .fdummy
    set configure(COLOUR_BACKGROUND) [.fdummy cget -background]
    destroy .fdummy
  }

  autoconf_BLT_LIBRARY $arrayname

  package require registry 1.0
  set tclfile {}
  catch {
    set tc [registry get \
       HKEY_CLASSES_ROOT\\TclScript\\shell\\open\\command {}] 
    regsub -all {\\} $tc \/ tclfile }

#  WarningMessage "tclfile $tclfile"

  # "start" and "default" use default browser (see open_url() in local.tcl)
  set array(HYPERTEXT_VIEWER) "default"

  set array(COLOUR_DISABLED) "#bebcaa"


  if { [llength $tclfile] > 0  &&
    [regsub wish [lindex $tclfile 0] tclsh tclsh] > 0 } {
    set array(RUN_TCLSH) $tclsh
  } else {
    set array(RUN_TCLSH) tclsh84
  }
  set array(RUN_CCP4I) "$array(RUN_TCLSH) \[file join \[GetEnvPath CCP4I_TOP] bin ccp4ish.tcl]"


  set array(RUN_BLTWISH) bltwish
  set array(RUN_LOGGRAPH) "bltwish \[file join \[GetEnvPath CCP4I_TOP] bin loggraph.tcl]"
  set array(RUN_MAPSLICER) "ccp4mapwish \[file join \[GetEnvPath CCP4I_TOP] bin mapslicer.tcl]"
  set array(RUN_TOPDRAW) "bltwish \[file join \[GetEnvPath CCP4I_TOP] topdraw topdraw.tcl]"
  set array(RUN_CCP4MG) [file join [GetEnvPath CCP4] .. ccp4mg win_ccp4mg.exe]

  return 1
}

#--------------------------------------------------------------------------
proc autoconf_WINDOWS_system { arrayname args } {
#--------------------------------------------------------------------------
#d_sum Attempt to configure the system parameters for a WINDOWS system
#d_arg arrayname Name of the system array
  upvar #0 $arrayname array

  set uid [GetUserId]
  set array(LOGIN_NAME) WINDOWS
  if { $uid != "" } { set array(LOGIN_NAME)  $uid }

}


#-----------------------------------------------------------------------
proc set_configured_menus { arrayname paramlistVar } {
#-----------------------------------------------------------------------
#d_sum Create menus which are based on data in the configure def file.
#d_desc This is used to set up menus for options such as remote machines.
#d_desc This procedure defines some data types whose actual allowed \
values are \
dependent on user input to the configure interface.  Each data type \
is a menu with the menu items (i.e. the allowed values for data \
of that type) been taken from the configure.def file via the configure \
array.
#d_desc The relationship between the configure file data and the derived \
menus is defined in configure(TYPEDEF_LIST).   This is a list and \
each element in that list defines one menu. Each menu definition is itself \
a list with the items: name of the menu type, the name of the element \
acting as counter, the root element name for the items, \
and the root element name for alias for each item (this is optional).
#d_arg arrayname name of array containing parameters
#d_arg paramlistVar name of array element containing the menu definitions (usually TYPEDEF_LIST)
  upvar #0 $arrayname array

  if { ![ElementExists $arrayname $paramlistVar] } {
    Report 1 "Parameter list $paramlistVar does not exist in $arrayname"
    return
  }

  foreach p $array($paramlistVar) {
    if { [llength $p] > 3 } {
      set_typedef_menu $arrayname [lindex $p 0] \
       [lindex $p 1] [lindex $p 2] [lindex $p 3]
    } else {
      set_typedef_menu $arrayname [lindex $p 0] \
	[lindex $p 1] [lindex $p 2]
    }
  }
}

#-----------------------------------------------------------------------
proc set_typedef_menu {arrayname defVar nitemsVar menuVar { aliasVar "" }  } {
#-----------------------------------------------------------------------
#d_sum Use a list of values from indexed array element(s) to define a menu data type
#d_arg arrayname Name of data array
#d_arg defVar Name of the menu type 
#d_arg nitemsVar Number of menu items (i.e. maximum index for the input array elements)
#d_arg menuVar Array element containing the text for the menu items
#d_arg aliasVar optional. Array element containing the aliases for the menu items
  upvar #0 $arrayname array
  global typedef

#  puts "set_typedef_menu defVar $defVar nitems $array($nitemsVar)"

  if { $array($nitemsVar) < 1 } {
    if { $aliasVar != "" } {
      set typedef($defVar) { menu {"Not Installed"} {"Not Installed"} }
    } else {
      set typedef($defVar) { menu {"Not Installed"} }
    }
  } else {
    for { set n 1 } { $n <= $array($nitemsVar) } { incr n } {
      lappend lm $array([Indxv $menuVar $n])
      if { $aliasVar != "" &&
           [info exists array([Indxv $aliasVar $n]) ] } { 
        lappend la $array([Indxv $aliasVar $n])
      }
    }
    if { [info exists la ] } {
      set typedef($defVar) [list menu $lm $la ]
    } else {
      set typedef($defVar) [list menu $lm ]
    }
  }
}

#-----------------------------------------------------------------------
proc set_default_mapviewer { arrayname } {
#-----------------------------------------------------------------------
#d_sum (Re)set the default mapviewer
#d_desc Sets the default map viewer command in typedef to that \
specified in preferences.
#d_arg arrayname name of array containing parameters
   upvar #0 $arrayname array

   # Set the name of the viewer we want
   set viewercmd $array(MAPVIEWER_DEFAULT)
   set filetype "_map_file"

   # Implement the change
   set_default_viewer $filetype $viewercmd
}

#-----------------------------------------------------------------------
proc set_default_pdbviewer { arrayname } {
#-----------------------------------------------------------------------
#d_sum (Re)set the default PDB viewer
#d_desc Sets the default map viewer command in typedef to that \
specified in preferences.
#d_arg arrayname name of array containing parameters
   upvar #0 $arrayname array

   # Set the name of the viewer we want
   set viewercmd $array(PDBVIEWER_DEFAULT)
   set filetype "_pdb_file"

   # Implement the change
   set_default_viewer $filetype $viewercmd
}

#-----------------------------------------------------------------------
proc set_default_mtzviewer { arrayname } {
#-----------------------------------------------------------------------
#d_sum (Re)set the default MTZ viewer
#d_desc Sets the default mtz viewer command in typedef to that \
specified in preferences.
#d_arg arrayname name of array containing parameters
   upvar #0 $arrayname array

   # Set the name of the viewer we want
   set viewercmd $array(MTZVIEWER_DEFAULT)
   set filetype "_MTZ_file"

   # Implement the change
   set_default_viewer $filetype $viewercmd
}

#-----------------------------------------------------------------------
proc set_default_viewer { filetype viewercmd } {
#-----------------------------------------------------------------------
#d_sum Set the default viewer for a particular file type
#d_desc Reorders the lists of viewer commands in typedef so that \
the user specified default (set in preferences) is first in the list, \
and hence is used by default to view the specified file type in the gui.
#d_arg filetype Name of the type for the file in types.def
#d_arg viewercmd The new default viewer command (must be one of those \
already defined in types.def for this file type)
   global typedef

   if { ![ElementExists typedef file] } { return 0 } 

   # Extract elements defining the type
   set n 0
   foreach attribute $typedef(file) {
     set file_$attribute [lindex $typedef($filetype) $n]
     incr n
   }

   # Locate the requested viewer in the list of possibilities
   set i [lsearch -exact $file_viewercmd $viewercmd]
   if { $i < 1 } {
     # It is first, or couldn't find it - take no action
     return 0
   } 

   # Reorder the lists of viewers and commands
   set file_viewercmd [concat [list [lindex $file_viewercmd $i]]\
			  [lreplace $file_viewercmd $i $i]]
   set file_viewer [concat [list [lindex $file_viewer $i]] \
                          [lreplace $file_viewer $i $i]]

   # Reset the typedef
   set typedef($filetype) ""
   foreach attribute $typedef(file) {
       lappend typedef($filetype) [subst $[subst file_$attribute]]
   }
   return 1
}

#--------------------------------------------------------------------
proc SetDefaultMapFormat { arrayname map_format args } {
#--------------------------------------------------------------------
#d_sum Return the default map format set by the user  in preferences
#d_desc This procedure called by tasks which present user with the option \
to output maps. Beware FFT/Patterson will not output Xtalview maps because \
Xtalview just takes the hkl data & generates own map
  upvar #0 $arrayname array
  global preferences

  if { $array($map_format) == "MAP_DEFAULT" } {
    if { [lsearch -regexp $args noxt] &&
                [regexp Xtal $preferences(MAP_OUTPUT_FORMAT) ] }  {
      set array($map_format) CCP4
    } else {
      set array($map_format) $preferences(MAP_OUTPUT_FORMAT)
    }
  }
}


#---------------------------------------------------------------------------
proc SetMapConversionMenu { { menuname "_map_format" } } {
#---------------------------------------------------------------------------
#d_sum Update a menu to only include possible map format conversions
#d_desc For each format already defined in the type, check whether the \
conversion can be performed in the current setup and regenerate the menu \
to only include those formats that are actually available.
#d_arg menuname (optional) The parameter type as defined for example in \
types.def. This defaults to _map_format.
  global configure
  global typedef
 
  if { ![info exists typedef($menuname)] } {
      return
  }
  # Get the full range of formats for this 
  set fmts [lindex $typedef($menuname) 1]

  # Set possible map formats
  #set typedef(_map_format) {menu   {CCP4 O QUANTA XtalView } }
  set fmt_list {}
  foreach fmt $fmts {
      switch -exact -- $fmt {
	  O {
	      if { [FindExecutable $configure(O_MAPMAN)] != "" } {
		  lappend fmt_list O
	      }
	  }
	  QUANTA {
	      if { [FindExecutable $configure(QUANTA_MBKALL)] != "" } {
		  lappend fmt_list QUANTA
	      }
	  }
	  default {
	      # Assume that no special conversion program
	      # is required
	      lappend fmt_list $fmt
	  }
      }
  }
  eval set typedef($menuname) \{ menu \{ $fmt_list \} \}
  return
}


#-----------------------------------------------------------------------
proc TestEnvVariables { } {
#-----------------------------------------------------------------------
#d_sum Test CCP4 environment variables set - used at ccp4i startup.
#d_desc Part of CCP4i startup. \
Report unset variables to user with option to continue or exit.
  global env
  global system

# Run at startup to check CCP4 environment roughly in place

  set  env(CCP4_TOP) [GetEnvPath CCP4]
  set  env(CCP4_BIN) [GetEnvPath CBIN]
  Report 2 "Top level CCP4 directory is $env(CCP4_TOP)" -notime
  Report 2 "Using CCP4 programs from $env(CCP4_BIN)" -notime

  set error_list {}
  set envvar_list [list CCP4I_TOP CCP4I_HELP CCP4_TOP \
		       CBIN CLIBD CCP4_SCR ]
  if { [regexp -- UNIX $system(OPSYS)] } {
    lappend envvar_list HOME
  }
  foreach envvar $envvar_list {
    set path [GetEnvPath $envvar 0]
    if { $path == "" } {
      append error_list "$envvar is undefined\n"
    } elseif { ![file exists $path ] || ![file isdirectory $path ] } {
      append error_list "$envvar is defined as $path
  which does not exist or is not a directory\n"
    }
  }

  foreach envvar [list PATH CCP4_OPEN ] {
    set path [GetEnvPath $envvar 0]
    if { $path == "" } {
      append error_list "$envvar is undefined\n"
    }
  }

  if { $error_list  != "" } {

    if { [regexp WINDOWS $system(OPSYS)] } {
      append error_list  \
        "\n You should exit CCP4i and check the installation"
    } else {
      append error_list \
        "\n You should exit CCP4i and do the usual CCP4 setup
If you still get this message then check your installation"
    }

# Probably hav not source the window utility code
    if { [llength [info procs ChooseOptionDialog]] <= 0  } {
      source [file join $env(CCP4I_TOP) src util_windows.tcl]
      source [file join $env(CCP4I_TOP) src window.tcl]
    }

    if { [ regexp Exit \
       [ChooseOptionDialog "Undefined environment variables" \
	Undefined "Undefined environment variables:\n $error_list" \
	  [list Exit Continue ] ] ] }  { puts "Exiting CCP4i"; return 0  }
  }

  return 1

}

#------------------------------------------------------------------------
proc InitialiseDotCCP4 { } {
#------------------------------------------------------------------------
#d_sum Create/update the $HOME/.CCP4 directory
#d_desc On startup check that .CCP4 directory exists, and that the \
necessary subdirectories (including the shadow area) are also \
present. Create any missing directories.
# Make sure we have a $HOME/.CCP4 directory
  global system

  # List of subdirectories in the main CCP4i area
  set subdirs [list bin src etc tasks scripts templates utils loggraph mapslicer sketch]

  # Set location for dot
  switch $system(OPSYS) \
  UNIX {
    set dot [file join [GetEnvPath HOME] .CCP4]
  } WINDOWS  {
    if { [GetEnvPath USERPROFILE ] == "" } {
      set dot [file join [GetEnvPath SystemRoot] Profiles $system(LOGIN_NAME) CCP4]
     } else { 
      set dot [file join [GetEnvPath USERPROFILE] CCP4]
      set olddot [file join [GetEnvPath SystemRoot] Profiles $system(LOGIN_NAME) CCP4] 

      if { ![file exists "$dot"] && [file exists "$olddot"] } {
        Report 1 "Copying your old CCP4 settings file $olddot to the correct $dot location." 
        CopyDir "$olddot" "$dot"
      }
    }
  }

  # If dot doesn't exist then create it
  if { ![file exists $dot ] } {

    Report 1 "Creating a home directory for CCP4 at $dot"
    CreateDir "$dot"
    CreateDir [file join "$dot" windows]
    CreateDir [file join "$dot" unix]

  }

  # Update or initialise shadow area dot/CCP4I_TOP

  if { [file isdirectory $dot] } {

    if { ![file exists [file join $dot CCP4I_TOP]] } {

      Report 1 "Creating CCP4i shadow area at [file join $dot CCP4I_TOP]"
      CreateDir [file join $dot CCP4I_TOP]

    }

    if { [file isdirectory [file join $dot CCP4I_TOP]] } {

      # Check that subdirectories exist - create those that
      # don't
      foreach dir $subdirs {

        if { ![file exists [file join $dot CCP4I_TOP $dir]] } {

          Report 1 "Creating shadow subdirectory [file join $dot CCP4I_TOP $dir]"
          CreateDir [file join $dot CCP4I_TOP $dir]

        }

      }

    }

    # Check for monomer subdirectory

    if { ![file exists [file join $dot monomer]] } {

      Report 3 "Creating local monomer directory [file join $dot monomer]"
      CreateDir [file join $dot monomer]

    }

    # For backwards compatibility with very old versions of CCP4i
    # which used a $HOME/.CCP4_directories file
    # Copy the directories.def to its new home
    if { [regexp UNIX $system(OPSYS)] } {
      if { ![file exists [file join $dot unix directories.def]] && \
	      [file exists [file join [GetEnvPath HOME] .CCP4_directories] ] } {
        CopyFile [file join [GetEnvPath HOME] .CCP4_directories] \
		[file join $dot unix directories.def ]
      }
    }

  } elseif { ![file isdirectory $dot] } {
    puts "There is $dot but it is apparently not a directory"
    exit 1
  }

  SetSystemVar DOT $dot

}

#----------------------------------------------------------------------
proc SetDomain {} {
#----------------------------------------------------------------------
#d_sum Unused. Part of project to support multiple machine domains
# Is the present host machine in a machine domain?
  global system
  global domains
  if { ![ElementExists domains N_DOMAINS] || $domains(N_DOMAINS) == 0 } {
    return 0
  }
  set host [lindex [split [GetHostname] . ] 0 ]
  for { set n 1 } { $n <= $domains(N_DOMAINS) } { incr n } {
    if { [lsearch -exact $domains(DOMAIN_MACHINES,$n) $host] >= 0 } {
       puts "$host in domain $domains(DOMAIN_NAME,$n)"
      set system(GENERIC_DOMAIN) $system(DOMAIN)
      set system(DOMAIN) $domains(DOMAIN_NAME,$n)
      break
    }
  }
}


#--------------------------------------------------------------------
proc CreateSessionLog { } {
#--------------------------------------------------------------------
#d_sum Open a session log file which is written to by the Report
#d_desc This file can seen by user with 'Review Session Log' utility. \
It logs running jobs, file handling, sockets and should be used for \
any other important actions for which some diagnostic reporting might \
be useful.
#d_desc The file name is $HOME/.CCP4/CCP4_session.log
  global tcl_version
  global tk_version

  set logfile [datapath CCP4_session.log -user]

  DeleteFile $logfile
  WriteFile $logfile \
"Starting CCP4I application [GetDate]"

  # Also write some useful diagnostic information
  WriteFile $logfile \
"Interpreter Versions: Tcl: $tcl_version Tk: $tk_version"

  SetSystemVar SESSION_LOG $logfile

}

#---------------------------------------------------------------
proc Report { level text args } {
#---------------------------------------------------------------
#d_sum Write diagnostics to the session log file
#d_desc The report level cutoff is not currently implemented - there is no \
cutoff value in the preferences.
#d_arg Report level - 0,1,2 in order of decreasing importance.  Currently unused.
#d_arg text Text to appear in session log
#d_opt0 -notime
#d_opt1 Do not output the time to the session log
  global preferences
  if { [ElementExists preferences REPORT_LEVEL] &&
      $level < $preferences(REPORT_LEVEL) } { return }
  if { $text == "" } { return }

  if { [lsearch $args -notime] < 0 } { set text "[GetDate -format time] $text" }

  set logfile [GetSystemVar SESSION_LOG]

  if { $logfile != "" } { 
    WriteFile $logfile  "$text"
  } elseif { ![StringSame [GetSystemVar RUN_MODE] mggui] } {
    catch { puts "$text" }
  }

# Old code to write report to log window
#    $frame configure -state normal
#    $frame insert end "\n$text" texttag
#    $frame yview moveto 1.0
#    $frame configure -state disabled
}
#-------------------------------------------------------------------------
proc WarningMessage { message args } {
#-------------------------------------------------------------------------
#d_sum Minimal WarningMessage proc to output diagnostic from WindowsNT
#d_desc Draw a dialog box with a warning message.
#d_desc  There is another version of this proc in util_windows.tcl \
which will override this version after util_windows.tcl has been sourced. \
NB util_windows.tcl is NOT sourced by ccp4ish so run scripts \
will always default to this version if the programmer wants to output \
graphical messages from run scripts which might be necessary debugging under \
windows.
#d_ref CCP4I programmers/graphic_utils.html#WarningMessage See CCP4i Programmers Documentation
  global warning_message_flag
  global system

# If called from a script then just output to a log file
#  if { [GetSystemVar task_log_file] != "" } {
#    WriteToLog "$message"
#  } elseif { $system(OPSYS) == "UNIX" } {
#    puts "$message"
#    return
#  }

  set w .warning_message

# If there is already a warning message up then just add in the extra message
  if { [catch {winfo exists .warning_message} winfo_exists] } {
    catch { puts "$message" }
    return
  }

  if { !$winfo_exists } {
    set w .warning_message
    toplevel $w
    wm title $w "Warning Message"
    wm iconname $w  Warning
    frame $w.f1; pack $w.f1 
    label $w.f1.text \
	-wraplength "15 c" \
	-justify left \
	-text "$message"
    frame $w.f1.b
    pack $w.f1.text $w.f1.b -side top
    button $w.f1.b.b1 -text Dismiss -command warning_message_exit
    pack $w.f1.b.b1

    catch "grab $w"
  }

  wm deiconify $w
  raise $w
  update idletasks
  catch "grab $w"
  vwait warning_message_flag
}

#---------------------------------------------------------------------
proc warning_message_exit { } {
#---------------------------------------------------------------------
  global warning_message_flag
  catch "grab release .warning_message"
  destroy .warning_message
  set warning_message_flag 1
}

#d_index_title Saving Global Parameters
#d_intro_title Saving Global Parameters
#d_intro Save global parameters in an array called system_save \
this just helps keep things tidy.

#--------------------------------------------------------------------------
proc GetSystemVar { symbol } {
#--------------------------------------------------------------------------
#d_sum Get a global parameter from array system_save
#d_arg symbol Name of parameter
  global system_save
  global system

  if {[info exists system_save($symbol)]} {
    return $system_save($symbol)
  } elseif {[info exists system($symbol)]} {
    return $system($symbol)
  } else {
    return ""
  }
}
#--------------------------------------------------------------------------
proc SetSystemVar {symbol name} {
#--------------------------------------------------------------------------
#d_sum Save a global parameter in array system_save
#d_arg symbol Name of parameter
#d_arg value Value of parameter
  global system_save
  set system_save($symbol) $name
}
#d_index_title Querying the Operating System
#d_intro_title Querying the Operating System

#------------------------------------------------------------
proc GetHostname { } {
#------------------------------------------------------------
#d_sum Return the name of the machine running the process
#d_desc Wrapper for 'info hostname'
  if { [catch { exec hostname } host] } { set host [info hostname] }
  return $host

# This is an alternative version of the procedure, which is very slow,\
# when it is run on an offline Mac for the first time.\
# global system
# return [info hostname]
}

#-------------------------------------------------------------
proc GetUserId { } {
#-------------------------------------------------------------
#d_sum Return the user's id.
  global env
  global system
# Return the user id
  if { ![regexp WINDOWS $system(OPSYS)] } {
    return $env(USER)
  } else {
    # This is a new way of finding the USERNAME on Windows. Previous
    # version caused problems with the database handler set up. It
    # means that we no longer support versions of Windows before XP.
    catch {set $env(USERNAME)} message
    if { ![regexp "no such variable" $message] } {
	  set USER_NAME $env(USERNAME)
    } else {
          set USER_NAME 'UNKNOWN'
    }
    return $USER_NAME 

#    set log [GetTmpFileName]
#    if { [Execute [BinPath iam] {} status report -log $log] &&
#    		[ReadFile $log logtext] } {
#      DeleteFile $log
#      return [string trim $logtext]
#    } else {
#      return 'UNKNOWN'
#    }
  }
}

#----------------------------------------------------------
proc GetVersion {} {
#----------------------------------------------------------
#d_sum Return the CCP4i version.
  global system
  return $system(VERSION)         
}

#-----------------------------------------------------------------
proc GetPid {} {
#-----------------------------------------------------------------
#d_sum Return the process id of the current process
#d_desc Wrapper for Tcl pid command

  set process [GetSystemVar process]

  if { $process == "" } {
    set process [pid]
    SetSystemVar process $process
  }
  return $process
}

#--------------------------------------------------------------------
proc GetCurrentDir { } {
#--------------------------------------------------------------------
#d_sum Return the name of directory from which current process was started
#d_desc Is wrapper for Tcl pwd command

  return [pwd]
}

#---------------------------------------------------------------
proc GetDate { args } { 
#---------------------------------------------------------------
#d_sum Return the date/time appropriately formatted
#d_desc Uses Tcl clock command.  Return the current time if the -clock \
argument is not used.  See Tcl clock command for explanation of formats.
#d_opt0 -clock time
#d_opt1 Input a time as a machine clock time in seconds
#d_opt0 -format format
#d_opt1 Output format can be: full (%d %b %Y  %H:%M:%S), time (%H:%M:%S) \
date (%d %b %Y), or brief (%H:%M:%S for today or %d %b %y)

# If there is no input secs then find the current time 
# otherwise use the input time secs  and convert to user 
# friendly format   dependent on format input
# full		full date and time
# time		time only
# date		date only
# brief		time for any time today otherwise date
#

  set format full
  set secs {}

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    format {
      incr n; set format [lindex $args $n]
    } clock {
      incr n; set secs [lindex $args $n]
    }
    incr n
  }

  if { $secs == "" } { set secs [clock seconds] }
  if { [llength $secs ] > 1 } { 
    if { $format == "brief" } { 
      return [ append time [string range $secs 0 6] [string range $secs 9 10] ]
    } else {
      return $secs
    }
  }

  if { $format == "seconds"} { return $secs }
  if { $format == "full" } {
    set date [clock format $secs -format "%d %b %Y  %H:%M:%S" ]
  } elseif { $format == "time" } {
    set date [clock format $secs -format "%H:%M:%S" ]
  } elseif { $format == "date" } {
    set date [clock format $secs -format "%d %b %Y" ]
  } elseif { $format == "brief" } {
    set today [ clock format [clock seconds] -format "%Y %j" ]
    set input [ clock format $secs -format "%Y %j" ]
    if { [lindex $input 0 ] == [lindex $today 0 ] &&
         [lindex $input 1 ] == [lindex $today 1 ] } {
      set date [clock format $secs -format "%H:%M:%S" ]
    } else {
      set date [clock format $secs -format "%d %b %y" ]
    }
  }
  return "$date"
}

#----------------------------------------------------------------------
proc BinPath { program } {
#----------------------------------------------------------------------
#d_sum Return path name for an executable
#d_desc CCP4i usually calls programs without giving the full path name and \
relies on the PATH environment variable being correctly set to find the \
required programs. \
The user can define full path names for some programs in the \
configure interface and their specifications are interpreted in the BinPath \
procedure. All program calls in CCP4i scripts should pass the program name \
through this procedure which will expand the name to the full path name for \
those defined in the configure interface. \
By default BinPath will just return the program name as input.
#d_arg program Name of a program.
  global system
  global configure
  global env

  if { [StringSame WINDOWS $system(OPSYS)] && [StringSame fft $program] } {
      set program fft }

  if { [ElementExists configure NFULLPATHS] &&
        $configure(NFULLPATHS) > 0 } {
    for { set n 1 } { $n <= $configure(NFULLPATHS) } { incr n } {
      if { [StringSame $configure(FULLPATH_PROG,$n) $program] } {
        Report 2 "BinPath: script using $program explicitly from $configure(FULLPATH_PATH,$n)"
        return "$configure(FULLPATH_PATH,$n)"
      }
    }
  }
  # If there was no search path defined we need to check in CBIN 
  if { $system(OPSYS)=="WINDOWS" } {
      # first check for $program.bat (some programs may have two launchers
      # shell script (no ext) and Windows batch file).
      set bat_file [FileJoin $env(CBIN) "$program.bat"]
      if { [file exists $bat_file] } {
          return $bat_file
      }
  }
  if {[file exists [FileJoin $env(CBIN) $program]]} {
  	return [FileJoin $env(CBIN) $program]
  }
  #Otherwise we rely on the path
  return $program

}

#-----------------------------------------------------------------------
proc FindExecutable { program } {
#-----------------------------------------------------------------------
#d_sum Return the full path for the program named
#d_desc This command searches the directories on the user's PATH \
and looks for the specified program name in each directory. It \
returns the full path for the first match it finds, or else an \
empty string if no match is found.
#d_desc This should work on both Unix and Windows platforms.
#d_arg program Name of the program executable to search for
    global env
    global system

    # First check if it is already configured by the user
    set filen [BinPath $program]
    # "file executable" is not reliable on Windows when network drive is used
    if { [file exists $filen] && ( $system(OPSYS) == "WINDOWS" ||
                                   [file executable $filen] ) } {
	return $filen
    }

    # Has the user supplied an absolute name?
    if { [file pathtype $program] == "absolute" } {
      if { [file exists $program] && [file executable $program] } {
	  return $filen
      } else {
	  return {}
      }
    }

    # Set the appropriate path separator for this operating system
    switch $system(OPSYS) {
	UNIX {
          set separator ":"
        }
	WINDOWS {
          set separator ";"
        }
	default {
          puts "FindExecutable: unknown OPSYS \"$system(OPSYS)\""
	  return {}
        }
    }

    # Loop over the directories in the path looking for the specified
    # executable name
    set dirs [ split $env(PATH) $separator ]
    foreach dir $dirs {
	set filen [file join $dir $program]
	if { [file exists $filen] && [file executable $filen] } {
	    return $filen
	}
    }
    # If we are on Windows then the program may have an unspecified
    # .exe extension so try this next
    # "file executable" may not work on network drive, don't use it for .exe
    if { $system(OPSYS) == "WINDOWS" } {
	foreach dir $dirs {
	    set filen [join [list [file join $dir $program] exe ] . ]
	    if { [file exists $filen] } {
		return $filen
	    }
	}
    }
    # Nothing found
    return {}
}

#----------------------------------------------------------------------
proc Execute {  command script statusout reportout args } {
#----------------------------------------------------------------------
#d_sum Execute a program with a command script and some error trapping
#d_desc This is a cut-down version of the Execute in execute.tcl which is \
used to run program in the ccp4i run script.  This version runs programs \
from within the ccp4i graphical interface.
#d_desc Execute returns a true (1) if the program completes successfully, \
or a false (0) otherwise.
#d_arg command The command line to run the program
#d_arg script The script input to the program - should be null string \
if there is no script input.
#d_arg statusout Output the termination status from the program
#d_arg reportout Output the termination standardout output from the program \
#d_opt0 -success success_flag
#d_opt1 The 'successful' termination status from the program. \
Default is 0 as appropriate from most CCP4 programs.
#d_opt0 -log logfile \
Set the name of the file for the log output.  If this is not set then Execute \
will not handle log file output.

  upvar $statusout status
  upvar $reportout report
  set program_success 0
  set logfile {}

  set nargs [llength $args] ; set n 0
  while { $n < $nargs } {
    set comd [lindex $args $n ]
    switch -regexp -- $comd \
    success {
      incr n; set success [lindex $args $n ]
    } log {
      incr n; set logfile [lindex $args $n ]
    }
    incr n
  }

  set cmd "set status \[catch \{exec $command"
  if { $script != "" && $script != " " } { append cmd " < " $script }
  if { $logfile != "" } {
    if { [file exists $logfile ]} {
      append cmd " >> \"$logfile\"" 
    } else {
      append cmd " > \"$logfile\""
    }
  }
  append cmd "\} report \]"

# If in environment with Report function then just put
# out a diagnostic level report
#  if { [info procs "Report" ] == "Report" } {
#       Report 0 "Running: $command "
#  }

  eval "$cmd"

# status is the value returned by catch and 0 means command
# successful
  return [ expr {1 - $status} ]
}


#d_index_title Handling File Names

#----------------------------------------------------------------
proc GetEnvPath { var { report 1 } } {
#----------------------------------------------------------------
#d_sum Get operating system environment variable
#d_desc Return a path name associated with an environment variable - in a \
Windows system the separators are converted to forward slash. \
Return an empty string if no environment variable found.
#d_arg var Environment variable
#d_arg report Optional - default 1.  If true (1) then output warning message if \
environment variable not found.
  global system
  global env

# Get environment variable - cope with whether input var has
# leading '$' or not

  regsub {^\$} $var  {} var1

# On NT change the separators to unix style /

  if { [regexp WINDOWS $system(OPSYS)] } {
    set status [catch { global env; 
      regsub -all {\\} $env($var1) \/ path } nc ]
  } else {
    set status [catch {global env; set p1 $env($var1)} path ]
  }
  if { $status } { 
    set path ""
    if { $report } { 
      WarningMessage "Can not get environment variable for $var" }
  } 
  return $path
}
#-----------------------------------------------------------------------
proc GetFullDirName { dir } {
#-----------------------------------------------------------------------
#d_sum Return full path name for given directory alias
#d_desc Given a directory (either alias or full path) returns the \
full path appropriately formatted for the platform.
#d_arg dir Directory alias or path

  if { [llength [file split $dir]] > 1 } {
    return $dir
  } elseif { $dir == "" || \
	  [StringSame "$dir" "[GetSystemVar PATHNAME_LABEL]" "FULL_PATH" "CURRENT" ] } {
    return ""
  } else {
    return "[FileJoin [GetDefaultDirPath $dir]]"
  }
}
#-----------------------------------------------------------------------
proc GetFullFileName { file { dir {} } args } {
#-----------------------------------------------------------------------
#d_sum Return full path name for given file name and directory alias.
#d_desc Path name will be appropriately formatted for the platform.
#d_desc Will return the file name as input if directory alias is undefined \
or if directory alias is FULL_PATH or CURRENT.
#d_arg file File name (not usually including path)
#d_arg dir  Directory or project alias. Optional - default is blank string \
which is interpreted as undefined project alias.

  if { $file == "" } { return "" }

  if { [llength [file split $file]] > 1 ||
      $dir == {} ||
      [StringSame "$dir" "[GetSystemVar PATHNAME_LABEL]" "FULL_PATH" "CURRENT" ] } {
    return "$file"
  } else {
    return "[FileJoin [GetDefaultDirPath $dir] $file]"
  }
}

#-----------------------------------------------------------------------
proc GetFullFileName1 { file { dir {} } args } {
#-----------------------------------------------------------------------
#d_sum GetFullFileName version used in ExecuteScript 
#d_desc Handles the case when the input file name has a directory separator
#d_desc This procedure could be merged with with GetFullFileName but it \
is a bug fix late in development cycle so separate procedure.

  if { $file == "" } { return "" }

  if { [lindex [file split $file] 0] == "/"  ||
      $dir == {} ||
      [StringSame "$dir" "[GetSystemVar PATHNAME_LABEL]" "FULL_PATH" "CURRENT" ] } {
    return "$file"
  } else {
    return "[FileJoin [GetDefaultDirPath $dir] $file]"
  }
}


#-----------------------------------------------------------------------
proc GetFullFileName0 { arrayname fileVar args } {
#-----------------------------------------------------------------------
#d_sum Return the full path name of a file which is defined in an array.
#d_desc This command is similar to GetFullFileName but the input is \
in the form of the name of an array and the element containing the file name. \
Note that the default directory alias for the directory containing \
the file will be in the element DIR_$fileVar.   \
This command should be used in the context of callback functions.
#d_arg arrayname Name of data array
#d_arg fileVar name of array element containing file name
#d_opt0 -dir dirVar
#d_opt1 Name of array element containing the directory alias. 
  upvar #0 $arrayname array
#d_opt0 -machine machine
#d_opt1 Not implemented.  Would derive path name as seen from an alternative \
machine

  set dirVar {}
  set machine localhost
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    dir {
      incr n; set dirVar [lindex $args $n]
    } machine { 
      incr n; set machine [lindex $args $n]
    } 
    incr n
  }

  if { $array($fileVar) == "" } { return "" }

  if { $dirVar == {} } { set dirVar DIR_$fileVar }

  if { [llength [file split $array($fileVar)]] > 1 ||
       [StringSame "$array($dirVar)" "[GetSystemVar PATHNAME_LABEL]" ] } {
    return "$array($fileVar)"
  } else {
    return "[FileJoin [GetDefaultDirPath $array($dirVar)] $array($fileVar)]"
  }
}

#------------------------------------------------------------------------
proc SetCurrentProject { project_alias } {
#------------------------------------------------------------------------
#d_sum Set the project alias for the currently open user project.
#d_desc Dependent on the RUN_MODE this sets either the CURRENT_PROJECT \
or the MG_CURRENT_PROJECT entry in ccp4i_status to the specified value.
#d_arg project_alias Name of the new current project.
  global ccp4i_status
  if { [StringSame [GetSystemVar RUN_MODE] "mggui"] } {
    # Set current project for CCP4mg context
    set ccp4i_status(MG_CURRENT_PROJECT) $project_alias
  } else {
    # Set current project for other contexts
    set ccp4i_status(CURRENT_PROJECT) $project_alias
    set project_path [GetDefaultDirPath $project_alias]
    if { [string match "* *" $project_path] } {
      set msg_lines [list \
        "WARNING" \
        "" \
        "You are switching to" \
        "Project alias: $project_alias" \
        "Project path: $project_path" \
        "" \
        "The project path contains SPACES" \
        "It is OK if this is an old project and you want to see LOG FILES" \
        "" \
        "However, running a NEW JOB in this project can cause a MESS" \
      ]
      set button_text {
        "I have been warned"
      }
      after idle [list ChooseOptionDialog {} New \
        [join $msg_lines "\n"] \
        $button_text \
        -default 0 \
      ]
    }
  }
  return
}

#------------------------------------------------------------------------
proc GetCurrentProject {} {
#------------------------------------------------------------------------
#d_sum Return the project alias for the currently open user project.
#d_desc Dependent on the RUN_MODE this returns the values of either the \
CURRENT_PROJECT or the MG_CURRENT_PROJECT entry in ccp4i_status.
  global ccp4i_status
  # CCP4mg context
  if { [StringSame [GetSystemVar RUN_MODE] "mggui"] } {
      if { [info exists ccp4i_status(MG_CURRENT_PROJECT)] } {
	  return $ccp4i_status(MG_CURRENT_PROJECT)
      }
  }
  # Other contexts
  if { [info exists ccp4i_status(CURRENT_PROJECT)] } {
      return $ccp4i_status(CURRENT_PROJECT)
  }
  # Couldn't fetch the current project for this context
  # If we're in a running job context then try looking up
  # the project in the job_params array?
  global job_params
  if { [info exists job_params(PROJECT)] } {
      return $job_params(PROJECT)
  }
  # Give up, return nothing
  return ""
}

#------------------------------------------------------------------------
proc GetCurrentProjectDir { { project_alias {} } } {
#------------------------------------------------------------------------
#d_sum Return the directory path for the currently open user project.
#d_desc Returns the directory for the project returned by \
GetCurrentProject, or the directory for a particular project alias \
(if one is specified).
#d_arg project_alias (optional) Return directory for this project.

  set project $project_alias
  if { $project == ""  } {
      set project [GetCurrentProject]
  }
  return [GetProjectPath $project]
}

#------------------------------------------------------------------------
proc GetDefaultDirPath { { dirIn {} } } {
#------------------------------------------------------------------------
#d_sum Return the full path name for an input project/directory alias.
#d_arg dir Input project/directory alias. If this argument is missing then \
the current project directory is assumed.

# Set a default of the current directory
  set dir $dirIn
  set nodefault 0

  if { $dir == "" && "[GetCurrentProject]" != "" } {

    # No input project name given but current project
    # is available - so we will use this
    set dir [GetCurrentProject]
    set nodefault 1
  } 

  if { [StringSame "$dir" "[GetSystemVar PATHNAME_LABEL]" ] } {

    # PATHNAME_LABEL is the label that the user sees for "full path"
    # So this is asking for the current directory
    return [GetCurrentDir]

  } else {

    # Check project directories first
    set directory [GetProjectPath $dir] 
    if { $directory != "" && [file exists $directory] &&  \
       [file isdirectory $directory]  } {
	# Valid project directory - return this
	return $directory
    }

    # Not a project directory, try default directories
    set directory [GetDefdirPath $dir]
    if { $directory != "" && [file exists $directory] &&  \
       [file isdirectory $directory]  } {
	# Valid default directory - return this
	return $directory
    }

    # Check if it's SCRATCH or TEMPORARY
    # Return $CCP4_SCR for this case
    if {[regexp SCRATCH|TEMPORARY $dir ]} {
      set directory [GetEnvPath CCP4_SCR]
      return $directory
    }

    # Didn't match/return anything
    # Fall through to the next level
  }

  if { !$nodefault } {
    # This flag is only unset if we acquired a
    # project at the start
    set directory [GetCurrentDir]
  }
  # Return whatever we have
  return $directory
}

#----------------------------------------------------------------
proc GetDbDirPath { { project {} } } {
#----------------------------------------------------------------
#d_sum Return the project database directory
#d_desc Return the full path name for the database directory of \
an input project alias - typically this is a subdirectory called \
CCP4_DATABASE in the project directory.
#d_desc Given a project alias this command looks up the path of the \
corresponding database directory using a call to GetProjectDBPath. \
If the project alias isn't found then an empty string is returned.
#d_desc If no project alias is supplied then the database directory \
of the current project is returned.
#d_arg project (optional) Project alias

  set alias $project

  # If no project alias was supplied then try to get
  # the current project
  if { $alias == "" && "[GetCurrentProject]" != "" } {
    # No input project name given but current project
    # is available - so we will use this
    set alias [GetCurrentProject]
  } 

  # Acquire the database directory for this project
  # This will return an empty string if there is no database
  # for this project
  set dir [GetProjectDBPath $alias]

  # Check that it exists
  if { $dir != "" && [file exists $dir] && [file isdirectory $dir]  } {
    # Valid directory - return
    return $dir
  }
  # Return a database in the scratch directory
  return [FileJoin [GetDefaultDirPath TEMPORARY] CCP4_DATABASE]
}

#----------------------------------------------------------------
proc SearchPath {topname args  } {
#----------------------------------------------------------------
#d_sum Return full path name for a CCP4i code or data file.
#d_desc The procedure will search in order of priority: \
1) the user's 'dot' directory ($HOME/.CCP4/CCP4I_TOP on unix)  \
2) the ccp4i installation area.
#d_arg topname Should be TOP (to find ccp4i source files) or HELP \
(to find html files).   The default place for help files is defined \
by environment variable $CCP4I_HELP
  global system
# get the full path name for a file
# this procedure will need to search the users local directory
  if { ![regexp CCP4 $topname] } { set topname CCP4I_$topname }
# If user has file in .CCP4/CCP4I_TOP/... then use that
  set ff [eval [concat FileJoin {[GetSystemVar DOT]} $topname $args ]]
  if { [file exists $ff ] } { return $ff } 
  return [eval [concat FileJoin {[GetEnvPath $topname]} $args ]]
}

#---------------------------------------------------------------------
proc datapath { filename args } {
#---------------------------------------------------------------------
#d_sum Return the full path name for a configure file in the user's home directory.
#d_desc The user's configure files are usually in $HOME/.CCP4/platform \
where platform is UNIX or WINDOWS \
(eg used when several students in a class have same login) \
#d_arg filename The name of the configure file
#d_opt0 -user
#d_opt1 Use a file in the directory $HOME/.CCP4/username/platform where \
username is taken from $system(USERNAME).  This parameter is set if the \
user start ccp4i with the argument 'ccp4i -u[ser] username'.  This is intended \to be used when there is more than one person using one login id - e.g. in a \
teaching situation.
#d_opt0 -domain
#d_opt1 This is part of the machine domain functionality - not fully implemented.
#d_opt0 -create
#d_opt1 If the directory structure in .CCP4 does not exist then create the \
directories.
  global system
  global env

  set create 0
  set user 0
  set domain 0
  set dir [GetSystemVar DOT]
  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
  switch -regexp -- [lindex  $args $n] \
  user {
    if { $system(USERNAME) != "" } { 
      set dir [file join $dir $system(USERNAME)]
      set user 1
    }
  } domain {
    if { $system(DOMAIN) != "" } { 
      set dir [file join $dir $system(DOMAIN)]
      set domain 1
    }
  } create {
    set create 1
  }
  incr n }

# If the directory structure is not in place for the file then create it
  if { $create && ![file exists $dir] } {
    if { $user && ![file exists  \
       [file join [GetSystemVar DOT] $system(USERNAME)]] } {
      CreateDir [file join [GetSystemVar DOT] $system(USERNAME)]
    }
    if { $domain } { 
      CreateDir $dir
    }
  }
  if { [file exist $filename ] } {
    return $filename
  } else { 
    set filn [FileJoin $dir $filename]
    return $filn
  }
}


#------------------------------------------------------------------------
proc GetTmpFileName { args } {
#------------------------------------------------------------------------
#d_sum Return a unique name for a temporary file
#d_desc   If called in graphical ccp4i the root of the file name is pid_n \
where pid is the ccp4i process id and n is a counter of the number of \
temporary files.  \
If called in a run script then the root of the file name is \
project_jobid_n where project is the user's project name, jobid \
is the job number and n is a counter of the number of \
temporary files.  The file name has the extension .tmp but it is usual \
to specify the file type using the -ext argument to GetTmpFileName and \
giving the usual file extension of the file type.
#d_desc  The temporary file is given a path to put it in the CCP4i \
TEMPORARY directory (NB this is not necessarily the same a $CCP4_SCR).
#d_desc The use of this procedure to provide a consistent naming \
mechanism for temporary files is essential for the CCP4i file cleanup \
mechanism to be able to identify temporary files created by a particular job. \
It is possible that in future this procedure could keep some more definite \
record of temporary files created if ccp4i needs to track files more closely.
#d_opt0 -ext extension
#d_opt1 Add the extra text extension to the root file name.  This option \
is usually used to enter the file type for the file.
#d_opt0 -defdir directory_alias
#d_opt1 Give file name with directory for directory alias directory_alias
#d_opt0 -dir directory
#d_opt1 Give file name with directory directory
#d_opt0 -map
#d_opt1 Give file name with directory as the default output directory for maps. \
This is usually the TEMPORARY directory or the project directory.
  global job_params
  global preferences

  set ex ""
  set defdir ""
  set dir ""
  set job_id ""
  if {[GetSystemVar number_tmp_files] != ""} {
    set number [expr {[GetSystemVar number_tmp_files] +1} ]
  } else {
    set number 1
  }

  set n_args [llength $args]; set n 0
  while { $n < $n_args } {
    switch -regexp -- [lindex $args $n] \
    ext {
      incr n; set ex [lindex $args $n]
    } defdir {
        incr n; set defdir [lindex $args $n]
    } dir {
        incr n; set dir [lindex $args $n]
    } map {
      if { $preferences(MAP_OUTPUT_DEFDIR) == "TEMPORARY" } {
        set defdir TEMPORARY
      } else {
        set defdir $job_params(PROJECT)
      }
    }
    incr n
  }

  if { [ElementExists job_params JOB_ID] } {
    append job_id $job_params(PROJECT) _ $job_params(JOB_ID)
  } else { 
    set job_id [GetPid]
  }

  if { $ex == "" || [string match "_*" $ex ] } { 
    set ext $ex
  } else { 
    set ext "_$ex" 
  }
  set fname "[subst $job_id]_[subst $number][subst $ext].tmp"

  if { $dir == "" && $defdir != "" }  { set dir [GetDefaultDirPath $defdir] }
  if { $dir == "" } { set dir [GetDefaultDirPath TEMPORARY] }
  if { $dir != "" } { 
    set file [FileJoin $dir $fname]
  } else {
    set file $fname
  }

  SetSystemVar number_tmp_files $number
  return $file
}

#---------------------------------------------------------------------------
proc GetFileFormat { file { default {}} } {
#---------------------------------------------------------------------------
#d_sum Return the file type as inferred from the file extension
#d_desc The file formats are defined in etc/types.def
#d_ref CCP4I programmers/def_files.html#types_def Description of types.def
#d_arg file File name
#d_arg default (Optional) A default file type which is returned if a type can \
not be inferred from the file name.
  global typedef
  set ext [file extension $file]
  if { $ext == "" } { return $default }
  foreach filetype $typedef(file_types) {
    set defext [lindex $typedef($filetype) 2]
    if { [StringSame $ext $defext] } {
      return [lindex $typedef($filetype) 1]
    }
  }
  return $default
}

#------------------------------------------------------------
proc FileJoin { args } {
#------------------------------------------------------------
#d_sum Concatenates file names using the correct path separator for platform.
#d_desc If the first argument begins with a dollar sign it will be \
interpreted as a environment variable. Otherwise this procedure \
is just wrapper to Tcl 'file join' command.
#d_desc Beware file join not available for tcl <7.6
#d_arg name(s) List of file/directory names of any length
  global system

  if { [regexp {^\$} [lindex $args 0]] } {
    lappend pathlist  [GetEnvPath [lindex $args 0 ]]
  } else {
    lappend pathlist [lindex $args 0]
  }

# this strips any leading forward slash from each arg
# TclPro: / is not a special character so shouldn't be escaped
  foreach item [lrange $args 1 end]  {
    regsub {^/} $item {} item1
    lappend pathlist $item1
  }

  set cmd [concat "file join" $pathlist]
  set status [catch $cmd filename]
  if { $status == 0 } {
    return $filename
  } else {
    set filename [lindex $args 0 ]
    foreach item [lrange $args 1 end]  {
      append filename "/" $item
    }
    return $filename
  }
}

#--------------------------------------------------------
proc FileRootName { filename } {
#--------------------------------------------------------
#d_sum Return file base name - i.e. remove the file extension and path name.
#d_desc This is wrapper for 'file rootname' and 'file tail' commands.
#d_arg filename Input file name

  set root [file rootname [file tail $filename] ]
  return $root
}

#---------------------------------------------------------------------
proc ChangeFileExt { filename ext } {
#---------------------------------------------------------------------
  set t [file extension $filename]
  if { $t != "" } {
    set nt [expr {[string first $t $filename ] - 1} ]
    set file [string range $filename 0 $nt ]
  } else {
    set file $filename
  }
  if { [string first "." $ext] == 0 } {
    append file $ext
  } else {
    append file "." $ext
  }

  return $file
}

#d_index_title Manipulating Files

#----------------------------------------------------------------
proc OpenFile { filename channel {mode a+ } } {
#----------------------------------------------------------------
#d_sum Open a file
#d_desc Wrapper with error trapping for Tcl 'open'
#d_arg filename File name
#d_arg channel Returned channel id
#d_arg mode Optional (default a+) file open mode - see Tcl documentation for 'open'
  upvar $channel f

  if {[file isdirectory $filename]} { return 0 }
#  puts "OpenFile mode $mode"
  return [expr {1 - [catch { open $filename $mode } f ]} ]
}

#--------------------------------------------------------------------
proc CloseFile { f {filename ""} } {
#--------------------------------------------------------------------
#d_sum Close a file
#d_arg f Channel that file is open on
#d_arg filename Optional argument used in error message to user if fails.
  if { [catch "close $f" ] } {
    WarningMessage "Error closing file $filename
Probably due to disk being full or exceeding disk quota"
    return 0
  } else {
    return 1
  }
}

#--------------------------------------------------------------------
proc ReadFile { filename textVar args } {
#--------------------------------------------------------------------
#d_sum Read contents of file into a text variable
#d_arg filename Name of file to read
#d_arg textVar Returned text read from file
#d_opt0 -split
#d_opt1 Return the file as a list with each line from the file as a list element
#d_opt0 -noblank
#d_opt1 Do not return blank lines
#d_opt0 -nocomment comment_char
#d_opt1 Do not return 'comment' lines which begin with the character comment_char
  upvar $textVar text
  set noblank 0
  set nocomment 0
  set split 0
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    split {
      set split 1
    } nobl {
      set noblank 1
    } noco {
      set nocomment 1
      incr n; set comment [lindex $args $n]
    }
  incr n
  }

  if { ![OpenFile $filename f r ] } { return 0 }
  if { [catch "read $f" tt ] } { CloseFile $f; return 0 }
  CloseFile $f

  if { $split || $noblank || $nocomment } {
    set ttsplit [split $tt \n]
# Strip out blank lines and comment lines
    if { $noblank && $nocomment } {
      foreach line $ttsplit {
        if { [string length [string trim $line ] ] > 0 && ![eval regexp {$comment} {$line} ] } { 
              lappend tclean "$line" }
      }
    } elseif { $noblank } {
      foreach line $ttsplit {
        if { [string length [string trim $line ] ] > 0 } { lappend tclean $line }
      }
    } elseif { $nocomment } {
      if { $noblank } { set ttsplit $text; set text {} }
      foreach line $ttsplit {
        if { $line == "" || ![eval regexp {$comment} {$line} ] } { 
		lappend tclean "$line" }
      }
    } else {
      set tclean $ttsplit 
    }
# If doing noblank/nocomment but don't want text splitting
    if { $split } { set text $tclean } else {
     foreach line $tclean { append text $line \n } }
  } else {
    set text $tt
  }
  return 1
}

#--------------------------------------------------------------------
proc ReadEndOfFile { filename nlines textVar args } {
#--------------------------------------------------------------------
#d_sum Return specified number of lines from the end of a file.
#d_arg filename Name of file to read
#d_arg nlines Number of lines to read
#d_arg textVar Returned text read from file
#d_opt0 -split
#d_opt1 Return the text as a list with each line from the file as a list element

  upvar $textVar text
  global system

# NT 
  if { [regexp WINDOWS $system(OPSYS)] } {
    if { [ReadFile $filename tt  -split] } {
      set ttlen [llength $tt]
      set f [expr {$ttlen - $nlines}]
      if { $f < 0 } { set f 0 }
      if { [lsearch $args "-split"] >= 0 } {
        set text [lrange $tt $f end]
      } else { 
        foreach l [lrange $tt $f end] {
          append text $l \n
        }
      }
      return 1
    }  else {
      return 0
    }
  } else {
  
# Use Unix tail command to read last nlines lines of a file
    if {[catch {set input [open "|tail -$nlines $filename" r]
	     set tt [read $input]
             close $input  } ]}  {
      return 0
    }
    if { [lsearch $args "-split"] < 0 } {
      set text $tt
    } else {
      set text [split $tt \n]
    }
    return 1
  }
}
  


#--------------------------------------------------------------------
proc WriteFile { filename text args } {
#--------------------------------------------------------------------
#d_sum Write text to a file
#d_arg filename Name of file to write
#d_arg text The text to write to the file
#d_opt0 -overwrite
#d_opt1 If file of name filename already exists then overwrite it - otherwise if file exists the procedure will fail

  set file_mode "a+"

  for { set i 0 } { $i < [llength $args] } { incr i } {
    set arg [lindex $args $i]
    switch -regexp -- $arg {
      overwrite {
        set file_mode "w"
      }
    }
  }

  if { ![OpenFile $filename fo $file_mode] } { return 0 }
  if {[catch {puts $fo "$text"}]} { return 0 }
  return [CloseFile $fo]
}

#--------------------------------------------------------------------
proc DeleteFile {file } {
#--------------------------------------------------------------------
#d_sum Delete a file or directory
#d_desc Wrapper for 'file delete' with some error trapping.
#d_desc DeleteFile can also be used to delete directories, if the 'file' \
is actually a directory name. Since the deletion command for directories \
is extremely powerful, the following mechanism has been implemented in an \
attempt to avoid accidental deletion of valuable directories:
#d_desc 1. The directory must be a subdirectory of a registered \
project, or a subdirectory in TEMPORARY. If neither of these criteria are \
met then a warning is displayed and the directory will not be deleted.
#d_desc 2. The user is prompted to confirm deletion of the directory \
before the operation is performed.
#d_arg file Name of file or directory to delete

  if { [file isfile $file] } { 
  # Regular file

    catch { file delete $file }
    return 1

  } elseif { [file isdirectory $file] } {
  # Directory

    # Check that it is a subdirectory of a registered project directory
    set delete 0
    foreach project [ListProjects] {
      set pattern "^[file join ([GetProjectPath $project]) (.+)]"
      if { [regexp -- $pattern $file] } {
        set delete 1
        break
      }
    }
    # The directory is not inside a project
    if { $delete != 1 } {
      # Could be in TEMPORARY
      set pattern "^[file join ([GetDefdirPath TEMPORARY]) (.+)]"
      if { [regexp -- $pattern $file] } {
	  set delete 1
      }
    }
    # Not inside temporary or inside a project - don't delete
    if { $delete != 1 } {
      WarningMessage "Delete Directory: Warning

Directory $file
is neither a subdirectory of one of your registered
project directories, nor a subdirectory of TEMPORARY.

This directory will not be deleted."
      return 0
    } 

    # Warn the user before zapping a directory
    global preferences
    if { $preferences(CLEANUP_DIR_WARNING) } {
       if { [ regexp Abort [ChooseOptionDialog "Warning: Delete Directory" Delete \
	    "WARNING!

About to delete the directory

\"$file\"

AND ITS ENTIRE CONTENTS

Are you really sure you want to do this?" [list Abort OK] ] ] } {
      return 0
       }
    }
    catch {file delete -force $file}
    return 1
  } else {
    # "File" is neither file nor directory
    return 0
  }
}

#--------------------------------------------------------------------
proc DeleteFiles { args } {
#--------------------------------------------------------------------
#d_sum Delete multiple files.
#d_args Filenames  - Tcl list of filenames

  foreach file $args {
    DeleteFile $file
  }
}

#-----------------------------------------------------------------
proc FileWritable { file } {
#-----------------------------------------------------------------
#d_sum Return flag to say if file is writable
#d_desc Wrapper for 'file writable'
#d_arg file Name of file to test

  return [file writable $file ]
}


#--------------------------------------------------------------------
proc MoveFile { filein fileout args } {
#--------------------------------------------------------------------
#d_sum Move (i.e. rename) a file.
#d_desc Wrapper for 'file rename' command
#d_arg filein Name of source file
#d_arg fileout Name of target file

  if { ![file exists $filein] } {
    Report 1 "MoveFile: input file $filein does not exist"
    return 0
  }
  if { [file exists $fileout] } {
    if { [lsearch -regexp $args over ] >= 0 } {
      DeleteFile $fileout
    } else {
      Report 1 "MoveFile: output file $fileout already exists"
      return 0
    }
  }

  if { [catch {file rename $filein $fileout } ] } {
    return 0
  } else {
    return 1
  }
}

#--------------------------------------------------------------------
proc CopyFile { filein fileout args } {
#--------------------------------------------------------------------
#d_sum Copy file - i.e. make a new version and keep existing file
#d_desc Wrapper for 'file copy' command
#d_arg filein Name of source file
#d_arg fileout Name of target file
#d_opt0 -overwrite
#d_opt1 Force overwrite of existing file

  if { ![file exists $filein] } {
    Report 1 "CopyFile: input file $filein does not exist"
    return 0
  }
  if { [file exists $fileout] &&  \
               [lsearch -regexp $args  over] < 0 } {
    Report 1 "CopyFile: output file $fileout already exists"
    return 0
  } else {
    file delete $fileout
  }

  if { [catch {file copy $filein $fileout } ] } {
    Report 1 "CopyFile: error copying from $filein to $fileout"
    return 0
  } else {
    return 1
  }
}

#--------------------------------------------------------------------
proc TranscribeFile { filein fileout } {
#--------------------------------------------------------------------
#d_sum Append contents from one file to the end of another file
#d_arg filein Source file name
#d_arg fileout Target file name

  if { [OpenFile $filein fi r ] <= 0 } {
    Report 2 "ERROR opening file $filein"
    return 0 }
  if { [OpenFile $fileout fo a+ ] <= 0 } {
    Report 2 "ERROR opening file $fileout"
    return 0 }

  puts $fo "[read $fi]"
  CloseFile $fi
  CloseFile $fo
  return 1
}


#-----------------------------------------------------------------------
proc CompressFile { filein args } {
#-----------------------------------------------------------------------
#d_sum Compress file using gzip
#d_arg filein Name of uncompressed file
#d_opt0 -uncompress
#d_opt1 Uncompress the '.gz' file to recreate uncompressed file
#d_opt0 -overwrite
#d_opt1 Overwrite any existing file

  global system
  set overwrite 0
  set uncompress 0

  set nargs [llength $args]; set n 0
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    over {
       set overwrite 1
    } unco {
       set uncompress 1
    }
    incr n
  }

# Uncompress
  if { $uncompress } { return [UnCompressFile $filein] }

# NT fix
  if { [regexp WINDOWS $system(OPSYS)] } {
    WarningMessage "Attempting to run CompressFile"
    return 0
  }

  if { ![file exists $filein] } {
    catch { puts "CompressFile: input file $filein does not exist" }
    return 0
  }

  append fileout $filein ".gz"
  if {[file exists $fileout] } {
    if { $overwrite } { 
      Report 1 "Overwriting existing compressed file:  $fileout"
      DeleteFile $fileout
    } else {
      Report 1 "Compressed file already exists: $fileout"
      return 0
    }
  }
  if { [catch {exec gzip "$filein" } ] } {
    return 0
  } else {
    return 1
  }
}

#-----------------------------------------------------------------------
proc UnCompressFile { filein } {
#-----------------------------------------------------------------------
#d_sum Uncompress file using gzip
#d_arg filein Name of file (with or without the .gz extension)

  global system

# Uncompress the file $filein - if this file does not exist try
# adding the usual compress extension ( .gz ) to file name

# This routine will be mostly used with the database for archiving
# It is probably safer to pass in file name without the compress extension
# and let this routine sort it out which compress program is being used

# NT fix

  set file $filein
  if { ![file exists $file] } { 
    append file "." [CompressExtension]
    if { ![file exists $file] } {
      Report 1 "UnCompressFile: input file $filein does not exist"
      return 0
    }
  }
  
  if { [regexp WINDOWS $system(OPSYS) ] } {
  if { [catch {exec 7z x "$file" } errmsg] } {
      Report 1 "UnCompressFile: gunzip $file failed: \"$errmsg\""
      return 0
    } else {
      Report 1 "UnCompressFile: gunzip $file succeeded"
      return 1
    }
  } else {
    if { [catch {exec gunzip "$file" } errmsg] } {
      Report 1 "UnCompressFile: gunzip $file failed: \"$errmsg\""
      return 0
    } else {
      Report 1 "UnCompressFile: gunzip $file succeeded"
      return 1
    }
  }

}

#---------------------------------------------------------------------
proc UnTarFile { file } {
#---------------------------------------------------------------------
#d_sum Apply 'tar -xf' to a file
#d_arg  file Name of tar file
  global system
# NT fix

# Unix: first need to move to the directory containing the tar
# file
  set cwd [GetCurrentDir]
  set tar_dir [file dirname $file]
  ChangeDirectory $tar_dir
  if { [regexp WINDOWS $system(OPSYS) ] } {
    set tar_result [expr {1 - [catch {exec 7z x "$file" } ]}  ]
  } else {
    set tar_result [expr {1 - [catch {exec tar xf "$file" } ]}  ]
  }
  ChangeDirectory $cwd
  return $tar_result
}

#--------------------------------------------------------------------
proc CompressExtension {} {
#--------------------------------------------------------------------
#d_sum Return the expected extension for compressed file
  return "gz"
}

#d_index_title Handling Directories

#---------------------------------------------------------------------
proc CreateDir { dir } {
#---------------------------------------------------------------------
#d_sum Create a directory
#d_desc the parent directory of the new directory must already exist
#d_arg dir Full path name of directory

  if { [ file exists $dir ] } { 
    Report 3 "ERROR cannot create directory: $dir already exists"
    return 0
  }
  return [expr {1 - [catch {file mkdir $dir } ]} ]
}

#--------------------------------------------------------------------
proc CopyDir { filein fileout } {
#--------------------------------------------------------------------
#d_sum Copy a directory
#d_desc Wrapper for 'file copy' command
#d_arg filein Name of source directory
#d_arg fileout Name of target directory

  if { ![file exists $filein] } {
    Report 1 "CopyDir: input $filein does not exist"
    return 0
  }
  if { [file exists $fileout] } {
    Report 1 "CopyDir: output $fileout already exist"
    return 0
  }

# NT fix - remove the 'exec' from the command - why was it there??
#  if { [catch {exec file copy $filein $fileout } ] }
  if { [catch {file copy $filein $fileout } ] } {
    Report 1 "CopyDir: error copying from $filein to $fileout"
    return 0
  } else {
    return 1
  }
}


#--------------------------------------------------------------------
proc ChangeDirectory { dir } {
#--------------------------------------------------------------------
#d_sum Change working directory
#d_desc This is a wrapper for the Tcl cd command
#d_arg dir Full path or appropriate relative path name

  if { [file exists $dir] && [file isdirectory $dir ] } {
    return [expr {1 - [catch "cd $dir"]} ]
  } else {
    return 0
  }
}

#d_index_title Parsing Files
#d_intro_title Parsing Files
#d_intro The following commands do some of the things that you might do \
with grep or awk

#---------------------------------------------------------------------
proc ExtractFromFile { fileid search_string lineinc word_index } {
#---------------------------------------------------------------------
#d_sum 'grep' text from a file
#d_desc Searches for a line matching search_string - the string \
match function is used and the wild cards * and ? may be used. \
Words from the matching text line or from a following line  \
are returned.
#d-desc This procedure is superseded by ExtractFromText
#d_arg filename input file name
#d_arg search_string search string 
#d_arg lineinc extract from the lineinc'th line after the hit line
#d_arg word_index List of indices of the required words. If word_index=0 return whole line.

  global extractfromfile_line

  set data {}
  set line {}

#  puts "ExtractFromFile fileid $fileid search_string $search_string lineinc $lineinc"

  set extractfromfile_line [GetSystemVar extractfromfile_line]
  set n_lines_read 0

  if {$search_string == "" } {

     set line $extractfromfile_line
     if { $lineinc > 0 } {
           for { set i 1 } { $i <= $lineinc } { incr i } {
              incr n_lines_read
              if { [catch "gets $fileid line" status ] } {
                 puts "ExtractFromFile could not increment $lineinc lines"
                 puts "Possible end-of-file after"
                 puts "$linetmp"
                 return ""
              }
           }
        }

  } else {

    while { [gets $fileid linetmp ] >= 0 } {
      incr n_lines_read
      if { [string match $search_string $linetmp ] == 1 } {
        if { $lineinc > 0 } { 
           for { set i 1 } { $i <= $lineinc } { incr i } {
              incr n_lines_read
              if { [catch "gets $fileid line" status ] } {
                 puts "ExtractFromFile could not increment $lineinc lines"
                 puts "Possible end-of-file after" 
                 puts "$linetmp"
                 return ""
              }
           }
        } else {
          set line $linetmp
        }
      break
      }
    }
  }

  SetSystemVar extractfromfile_line $line
  SetSystemVar extractfromfile_lines_read $n_lines_read
  if {[regexp a $word_index 0]} {
    set data $line
  } else {
    set data [GetWords $line $word_index] 
  }

 return $data

}

#--------------------------------------------------------------------
proc GetWords { line word_index } {
#--------------------------------------------------------------------
#d_sum Return selected words in a line as a Tcl list
#d_arg line A text string
#d_arg word_index A list of indices i - return the i'th word in the line - beware first word is index 0.

  set tmp_list [split $line " "]

# Remove any null list element that derives from multiple spacing
# in the input list
  set tmp_list0 ""
  foreach element $tmp_list {
    if { $element  != "" } { lappend tmp_list0 $element }
  }

  foreach element $word_index {
    lappend out [lindex $tmp_list0 $element]
  }
  return $out
}

#----------------------------------------------------------------------
proc ExtractTextLine { tt search_string lineinc word_index dataVar args } {
#----------------------------------------------------------------------
#d_sum Extract words from a line of text
#d_desc Similar to ExtractTextFromFile.  Find the line in text which \
a search string and then return some selected words from that line or \
from a specified number of lines ahead in the text.
#d_arg tt Input text string - if this is '-' then search from the \
last hit line in text input to a previous call to ExtractTextLine
#d_arg search_string String to search for in text - if input is blank \
text string the apply lineinc from the current position in the text \
and return the words as specified
#d_arg line_inc Advance line_inc lines from finding search string before \
returning words
#d_arg word_index Either a list of indices for words to return (first word \
in line has index 0) or 'all' to return entire line or 'last' to return \
last word.
  upvar $dataVar data

  set retval 1
  set data [ExtractFromText "$tt" "$search_string" $lineinc $word_index $args ]
  # Use catch to trap for lines which cannot be parsed
  # by lindex, for example those containing quotes
  if { [catch { set data0 [lindex $data 0] } ] } {
    set data0 {}
  }
  if { $data == {} || $data0 == {} } { set retval 0 }
#  puts "data $data retval $retval"
#  if { !$retval } { puts "$search_string" } 
  return $retval
}

#----------------------------------------------------------------------
proc ExtractFromText { tt search_string lineinc word_index args } {
#----------------------------------------------------------------------
#d_sum 'Grep' for a line in text and return specified fields from line.
#d_arg tt The input text to be searched.  If is '-' then search from current place in previously input text
#d_arg search_string Search for this text string. If input is empty string then return from the current line.
#d_arg lineinc From 'hit' line step on $lineinc lines 
#d_arg word_index Tcl list of fields in the line to be returned.  If ='all' return the whole line, if ='last' then return the last word.

  global extractText
  global extractTextLen
  global extractLine

  if { $tt != "-" } {
    set extractText [split $tt \n]
    append extractText {}
    set extractTextLen [llength $extractText]
    set extractLine 0
  } elseif { $search_string != "" } {
    incr extractLine
    if { $extractLine > $extractTextLen } { return "" }
  }

#  if {$search_string == "" && [regexp all $word_index] } {
# Find the next non-blank line
#    incr extractLine $lineinc
#    if { $extractLine > $extractTextLen } { return "" }
#    while { $extractLine < $extractTextLen &&  \
#      [string trim [lindex $extractText $extractLine]] == "" } {
#      incr extractLine
#    }
#    return [lindex $extractText $extractLine]
#  }


  if {$search_string != "" } {
    while { $extractLine < $extractTextLen &&  \
      ![regexp $search_string [lindex $extractText $extractLine]] } {
      incr extractLine
    }
  }
  incr extractLine $lineinc
  if { $extractLine <= $extractTextLen } {
    set line [lindex $extractText $extractLine]
  } else {
    return "" 
  }
#  puts "extractLine search_string $search_string $extractLine $line"

  switch $word_index \
  all {
    return $line
  } last {
    return [lindex $line end]
  } default {
    return [GetWords $line $word_index] 
  }
}

#-------------------------------------------------------------------
proc StringSame { args } {
#-------------------------------------------------------------------
#d_sum String comparison - is the first argument the same as any of the other arguments.
#d_desc Return true (1) if the first argument is the same as any subsequent argument.
#d_arg test Test string
#d_arg compare Any number of text strings for comparison.

  set case 1
  set nargs [expr {[llength $args ] -1} ]; set n 0
  if { [lindex $args 0 ] == "-case" } { set case 0 ; incr n }
  set string1 [lindex $args $n]; incr n
  if { $case } { set string1 [string toupper $string1] }

  foreach string2 [lrange $args $n $nargs ] {
    if { $case } { set string2 [string toupper $string2] }
    if { [string compare $string1 $string2 ] == 0 }  { return 1 }
  }
  return 0
}
#d_index_title Socket Handling
#d_intro_title Socket Handling
#d_intro The following procedures are used by ccp4i processes which are acting \
clients to the main graphical ccp4i.  For example loggraph acting as client \
to the sfanal task.  This setup assumes that the process is a client of only \
one server.  Most of the procedures are simple wrappers to Tcl fconfigure \
and puts/gets commands - see the Tcl documentation.  Each CCP4i process stores \
information on sockets in the system array and OpenClientSocket saves this \
information which other procedures might use.
#d_intro The server side sockets in the main ccp4i process is handled by \
procedures in src/local.tcl
#d_ref PROGDOCS local.html#Server_Side_Socket_Handling Server Side Socket handling

#------------------------------------------------------------------------
proc OpenClientSocket { server_host server_port args } {
#------------------------------------------------------------------------
#d_sum Open a client side socket
#d_arg server_host Connect to a server side socket on the machine server_host \
This should be 'local' if the server is one the local machine.
#d_arg server_port The server port number
#d_opt0 -listen listen_handler
#d_opt1  Listen for input from the server socket and when received call \
a procedure listen_handler and input to it the input from server.

  global system

  set listen 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    listen {
      set listen 1
      incr n; set listen_command [lindex $args $n]
    }
    incr n
  }

  if { ![catch "socket $server_host $server_port" sockid] } {
    set system(SERVER_HOST) $server_host
    set system(SERVER_PORT) $server_port
    set system(CLIENT_PORT) $sockid
    fconfigure $system(CLIENT_PORT) -buffering line \
		-blocking [expr {1 - $listen}]
    if { $listen } { ListenClientSocket $sockid 500 $listen_command }
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
proc ListenClientSocket { sockid delay command } {
#------------------------------------------------------------------------
#d_sum Listen for input from a server socket.
#d_desc This procedure is called by OpenClientSocket if the -listen option \
is used.  ListenClientSocket does a gets to get any input from the socket \
and calls the specified command if there is input.  ListenClientSocket then \
calls itself after a short time delay.
#d_args sockid Client side socket id
#d_args delay Delay, in milliseconds, between repeat calls to procedure
#d_args command The command to be issued if there is input from the server. \
The server input is appended to the command.

  if { ![catch {gets $sockid} input] && $input != "" } {
#    puts "ListenClientSocket input $input"
    eval [concat $command $input]
  }
  after $delay [list ListenClientSocket $sockid $delay  $command ]
}

#------------------------------------------------------------------------
proc TestSocket { args } {
#------------------------------------------------------------------------
#d_sum Test if a socket is open - return true (1) is socket responds
#d_opt0 -server
#d_opt1 Test the server side socket
#d_opt0 -client
#d_opt1 Test the client side socket
#d_opt0 -socket socket_id
#d_opt1 Test the socket with id socket_id

  global system
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch  -regexp -- [lindex $args $n] \
    server {
      set socket  $system(SERVER_SOCKET)
    } client {
      set socket $system(CLIENT_SOCKET)
    } socket {
      incr n; set socket [lindex $args $n]
    }
    incr n
  }

  set status [expr {1 - [catch {fconfigure $socket} response ]} ]
#  puts "TestSocket socket $socket $response $status"
  return $status
}

#------------------------------------------------------------------------
proc PutsSocket { message args } {
#------------------------------------------------------------------------
#d_sum Write to a socket
#d_arg message The text string to be written to the socket.
#d_opt0 -server
#d_opt1 Write to the server side socket
#d_opt0 -client
#d_opt1 Write to the client side socket
#d_opt0 -socket socket_id
#d_opt1 Write to the socket with id socket_id

  global system

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch  -regexp -- [lindex $args $n] \
    client {
      set socket $system(CLIENT_PORT)
    } server {
      set socket  $system(SERVER_SOCKET)
    } socket {
      incr n; set socket [lindex $args $n]
    }
    incr n
  }
#  puts "PutsSocket message $message socket $socket"

  return [expr {1 - \
    [catch { puts $socket $message } ]} ]
}

#======================================================================
# SETUP - this is at top level and makes sure ccp4i bombs out
# if CCP4I_TOP is not set
#======================================================================

global system_save

  source [SearchPath TOP src projectdirs.tcl]

  set system_save(PATHNAME_LABEL) "Full path.."
  if { ![ElementExists system TK_VERSION] || $system(TK_VERSION) < 8.0 } {
    set system_save(BLT_TABLE) table
  } else {
    set system_save(BLT_TABLE) blt::table
  }
