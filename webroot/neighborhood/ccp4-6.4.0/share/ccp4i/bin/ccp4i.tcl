#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#
# ccp4i.tcl 
# 
#----------------------------------------------------------------
# Set up system parameters that
global system

# Ensure POSIX time settings
  set env(LC_TIME) POSIX

# Source startup.tcl appropriate for operating system

  set system(OPSYS) [string toupper $tcl_platform(platform)]

  if { ![info exists env(CCP4I_TOP)] } {
      if { $system(OPSYS) == "WINDOWS" } {
          tk_messageBox -type ok -icon error -title "Restart needed?" \
          -message "Environment variable %CCP4I_TOP% is not set.
If you have just installed CCP4, the system needs to be restarted
before running CCP4 programs.
(It may be enough to log off)."
      exit 1
      }
  }

  source [file join $env(CCP4I_TOP) bin $system(OPSYS) startup.tcl]

#   puts "Running Tcl/Tk version [info patch]"
#  puts "system $system(OPSYS)"
#----------------------------------------------------------------

# Set env. variables for use in ccp4i and in called programs

if { ![info exists env(CCP4I_HELP)] } {
  set env(CCP4I_HELP) [file join $env(CCP4I_TOP) help]
}

if { ![info exists env(MOSFLM_WISH)] && [info exists env(CCP4I_TCLTK)] } {
    set ::env(MOSFLM_WISH) [file join $env(CCP4I_TCLTK) wish]
}

#----------------------------------------------------------------

# Make sure we have suitable Tk version 
if { [catch "set system(TK_VERSION) $tk_version"] } {
    puts "CCP4Interface error initialising Tcl/TK 
perhaps because DISPLAY variable is not set appropriately"
  exit 1
}
if {$system(TK_VERSION) < 4.2} {
    puts "CCP4Interface requires Tk 4.2 or higher, this is only $tk_version"
    exit 1
}
#---------------------------------------------------------------------

# Hide the Tk window
wm withdraw .

#---------------------------------------------------------Source basic utilities
# Source files which provide the basic utility procedures

source [file join $env(CCP4I_TOP) src system.tcl]
source [file join $env(CCP4I_TOP) src utils.tcl]
source [file join $env(CCP4I_TOP) src projectdirs.tcl]

#------------------------------------------------------------------------------
# Do the vital directories for running CCP4i exists (check the ones for CCP4 later
# when we can give user option ot quit or continue

  set error_list ""
  set envvar_list [list CCP4_SCR]
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
  if { $error_list != "" } { 
    WarningMessage  "Checking environment variables:
$error_list
Please check your installation before restarting CCP4i"
    exit 1
  }

#------------------------------------------------------------------------------
# Avoid writing to "/" when launching ccp4i by clicking on its icon (Mac OS X)

  if { [pwd] == "\/" } {
    cd $env(CCP4_SCR)
    set env(PWD) [pwd]
  }

#  puts "HOME = $env(HOME)"
#  puts "PWD = $env(PWD)"
#  puts "PWD = [pwd]"
#------------------------------------------------------------------------------

# If there is an autoconfigure procedure for the system parameters 
# and this opsys then run it
if { [llength [info proc autoconf_[subst $system(OPSYS)]_system]] > 0 } {
      autoconf_[subst $system(OPSYS)]_system system }

# Make sure we have the $HOME/.CCP4 directory
InitialiseDotCCP4

# Is the host machine in a defined machine domain with customised
# configuration files
InitialisePreferences domains domains -nouser
SetDomain
# Source the files which define the interface configuration
source [SearchPath TOP etc types.def]
InitialisePreferences configure configure
InitialisePreferences preferences preferences
if { ![InitialiseDirectories] } { 
  puts "ERROR: could not initialise directories data"
}

# Set the menu for available maps
SetMapConversionMenu
SetMapConversionMenu _fft_map_format


#------------------------------------------------------Parse the command line

#Set the default run mode to taskbrowser - this may be changed
#after we have parsed the command line!
set system(RUN_MODE) taskbrowser
set project ""

#Parse the input line to determine the mode and the script/task file
set code {t r g v d h c s}
set mode {task script loggraph fileviewer directories help configure server}

  set nargs [llength $argv]; set n 0
  while { $n < $nargs } {
    set cmd [string tolower [lindex $argv $n]]
    switch -regexp -- $cmd \
    user {
      incr n; set system(USERNAME) [lindex $argv $n]
    } debug {
      set system(DEBUG) 1
    } project { 
      incr n; set project [lindex $argv $n]
    } autotest {
      set system(RUN_MODE) autotest
      incr n; set autotest_args [lrange $argv $n end]
      set n $nargs
    } default { foreach c $code {
      if [regexp -- -$c $cmd ] {
        set system(RUN_MODE) [lindex $mode [lsearch $code $c] ]
        if { ![regexp -- ^- [lindex $argv [expr $n + 1 ] ]] } {
          incr n
          if [regexp task$ $system(RUN_MODE) ] {
            set system(TASK) [lindex $argv $n]
          } else {
            set system(SCRIPT) [lindex $argv $n]
          }
        }
      }
    } }
    incr n
  }

# ----------------------------------------------------------------------
# Test CCP4 environment variables setup - not necessary for some run modes
  if { [regexp taskbrowser|task|script|server $system(RUN_MODE)] } {
    if { ![TestEnvVariables] } { exit }
  }
# ----------------------------------------------------------------------

# set CENTRAL_DEPOSIT as saved value of external HARVESTHOME/HOME
# HARVESTHOME will be changed by ccp4i
if { [ GetCentralDeposit ] == {} } {

       if { [ info exists env(HARVESTHOME) ] && $env(HARVESTHOME) != "" } {
          SetCentralDeposit $env(HARVESTHOME)
       } else {
          SetCentralDeposit $env(HOME)
       }

}

#-----------------------------------------------------------------------
# Start up appropriate script
#
  switch  $system(RUN_MODE) \
  script {
# Run a script ($CCP4I/scripts/project.script) with parameters from def file

    source [file join $env(CCP4I_TOP) src execute.tcl]
    ExecuteScript $system(SCRIPT) -project $project

#
# loggraph - need to use the loggraph script to start up using bltwish
#
  } loggraph {

    exec loggraph $system(SCRIPT)
    exit

# task (ie run individual task) or taskbrowser mode
# taskbrowser - look ot see it there is an ET 'executable - 
# otherwise source the TCL file

  } task {

# For task mode check the task file exists
    if [regexp task$  $system(RUN_MODE) ] {
      set file [SearchPath TOP tasks $system(TASK).tcl ]
      if { ![file exists $file] && \
		![file exists [file join $env(CCP4I_TOP) $system(TASK).tcl]] } {
        puts "ERROR Invalid task name \"$system(TASK)\""
        puts "File does not exist $file"
        exit
      }
    }

    if { [file exists [file join $env(CCP4I_TOP) bin $system(RUN_MODE)]] } {
      set command "[file join $env(CCP4I_TOP) bin $system(RUN_MODE) ] $system(TASK)"
      set status [catch { exec  $command } report ]
      exit
    } else {
      source [file join $env(CCP4I_TOP) src $system(RUN_MODE).tcl]
      task
    }

  } help {

	if [ReadFile [file join $env(CCP4I_TOP) etc ccp4i.help] text] {
          puts $text
        }
	exit

  } configure {

     set system(TASK) config
     set system(RUN_MODE) task
     source [file join $env(CCP4I_TOP) src task.tcl ]
     task

  } autotest {

      source [file join $env(CCP4I_TOP) src taskbrowser.tcl]
      taskbrowser
      eval "DbAutotest $autotest_args"

  } server {

     source [file join $env(CCP4I_TOP) src server.tcl]
     StartServer

  } default {

    if { [file exists [file join $env(CCP4I_TOP) bin $system(RUN_MODE)]] } {
      exec [file join $env(CCP4I_TOP) bin $system(RUN_MODE) ] $system(SCRIPT)
      exit
    } else {
#      puts "Running $system(RUN_MODE) $system(SCRIPT)"
      source [file join $env(CCP4I_TOP) src $system(RUN_MODE).tcl]
      $system(RUN_MODE)
    }
  }

#----------------------------------------------------------------
# Updating $USER/.CCP4/unix/configure.def and preferences.def
# if necessary

  set conf_user [datapath configure.def -user -domain -create]
  set conf_isold 0
  if { [file isfile $conf_user] } {
     set conf_dist [SearchPath TOP etc $system(DOMAIN) configure.def]
     if { ![file isfile $conf_dist] } {
        set conf_dist [SearchPath TOP etc configure.def.dist]
     }
#    puts $conf_dist
     set conf_isold [expr [file mtime $conf_user] < [file mtime $conf_dist]]
  }

  set pref_user [datapath preferences.def -user -domain -create]
  set pref_isold 0
  if { [file isfile $pref_user] } {
     set pref_dist [SearchPath TOP etc $system(DOMAIN) preferences.def]
     if { ![file isfile $pref_dist] } {
        set pref_dist [SearchPath TOP etc preferences.def.dist]
     }
#    puts $pref_dist
     set pref_isold [expr [file mtime $pref_user] < [file mtime $pref_dist]]
  }

  if { $conf_isold || $pref_isold } {
    set t0 "Default settings changed"
    set t1 "This may be due to ccp4 update or upgrade."
    set t2 "It is highly recommended that you reset to new defaults."
    set message [join [list "" $t0 "" $t1 $t2 ""] "\n"]

    set keep "Keep Old"
    set later "Decide Later"
    set reset "Reset"
    set options [list $keep $later $reset]

    set action [ChooseOptionDialog {} New $message $options -default 2]

    set stime [clock seconds]
    set ftime [clock format $stime -format "%Y%m%d%H%M%S"]
    if { "$action" == "$keep" } {
#      puts "$keep"
       file mtime $pref_user $stime
       file mtime $conf_user $stime
    } elseif { "$action" == "$later" } {
#      puts "$later"
    } elseif { "$action" == "$reset" } {
#      puts "$reset"
       if { $pref_isold } {
          file rename -force $pref_user $pref_user.$ftime
          InitialisePreferences preferences preferences
       }
       if { $conf_isold } {
          file rename -force $conf_user $conf_user.$ftime
          InitialisePreferences configure configure
       }
    }
  }

#----------------------------------------------------------------

