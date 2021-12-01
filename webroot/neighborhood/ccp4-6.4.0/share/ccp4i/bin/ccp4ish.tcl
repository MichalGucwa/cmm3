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
# ccp4ish.tcl 
# 

# Beware if running ccp4ish.tcl with the wish interpreter you will get
# a graphics window which you don't want

catch {wm withdraw .}


#----------------------------------------------------------------
proc GetEnvPath { var } {
#----------------------------------------------------------------
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
  if { $status == 1 } {
    set path ""
    WarningMessage "Can not get environment variable for $var"
  }
  return $path
}

#----------------------------------------------------------------

  if { [set tcl_version [info tclversion]] < 7.6 } {
    WarningMessage "CCP4Interface requires Tcl 7.6 or higher, this is only $tcl_version"
    exit 1
  }

# Source startup.tcl appropriate for operating system

  set system(OPSYS) [string toupper $tcl_platform(platform)]
  source [file join $env(CCP4I_TOP) bin $system(OPSYS) startup.tcl]


#---------------------------------------------------------Source basic utilities
#
# Source the files which define the interface configuration and
# provide the basic utility procedures
#
global configure
global system

source [file join $env(CCP4I_TOP) src system.tcl]
source [file join $env(CCP4I_TOP) src utils.tcl]
source [file join $env(CCP4I_TOP) src projectdirs.tcl]

# If there is an autoconfigure procedure for the system parameters and this opsys
# then run it
if { [llength [info proc autoconf_[subst $system(OPSYS)]_system]] > 0 } {
      autoconf_[subst $system(OPSYS)]_system system }

InitialiseDotCCP4
InitialisePreferences configure configure
InitialisePreferences preferences preferences

#------------------------------------------------------Parse the command line

set system(RUN_MODE) script
set project ""

#Parse the input line to determine the mode and the script/task file
set directories_file {}
set code {r h s k a c}
set mode {script help server kill socket}
set silent 0

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
    } dir {
      set directories_file [lindex $argv $n]
    } socket {
      set system(RUN_MODE) socket
      incr n; set socket_deffile [lindex $argv $n]
      incr n; set socket_comline [lindex $argv $n]
    } uninstall {
      set system(RUN_MODE) uninstall
      incr n; set task_package_name [lindex $argv $n]
    } install {
      set system(RUN_MODE) install
      incr n; set task_package_name [lindex $argv $n]
      incr n; set task_archive      [lindex $argv $n]
    } import_packages {
      set system(RUN_MODE) import_packages
      incr n; set old_ccp4 [lindex $argv $n]
    } silent {
      # Only used for -socket at present
      set silent 1
    } default { foreach c $code {
      if [regexp -- -$c $cmd ] {
        set system(RUN_MODE) [lindex $mode [lsearch $code $c] ]
        if { ![regexp -- ^- [lindex $argv [expr $n + 1 ] ]] } {
          incr n
          set system(SCRIPT) [lindex $argv $n]
        }
      }
    } }
    incr n
  }

#-----------------------------------------------------------------
if { $directories_file != {} } {
  set status [InitialiseDirectories -file $directories_file]
} else {
  set status [InitialiseDirectories]
}
if { !$status } { puts "ccp4ish.tcl: ERROR: could not initialise directories data" }

#--------------------------------------------------------Start up appropriate script
#
# Run a script ($CCP4I/scripts/project.script) with parameters from def file
#

  switch  $system(RUN_MODE) \
  script {
    
    source [file join $env(CCP4I_TOP) src execute.tcl]
    source [file join $env(CCP4I_TOP) src job_utils.tcl]
    if { $project != "" } {
      ExecuteScript $system(SCRIPT) -project $project
    } elseif { $system(SCRIPT) != "" } {
      ExecuteScript $system(SCRIPT)
    } else {
      puts "You have not given the name of a def file. Use..
ccp4ish -r def_file_name"
    }

  } help {

	if [ReadFile [file join $env(CCP4I_TOP) etc ccp4i.help] text] {
          puts $text
        }
	exit

  } server {

     source [file join $env(CCP4I_TOP) src server.tcl]
     StartServer

  } kill {

     source [file join $env(CCP4I_TOP) src local.tcl]
     KillScript $system(SCRIPT)

 } socket {
 
    source [file join $env(CCP4I_TOP) src execute.tcl]
    if { $silent } {
      eval ExecuteSocket -deffile $socket_deffile -command {$socket_comline} -silent
    } else {
      eval ExecuteSocket -deffile $socket_deffile -command {$socket_comline}
    }
    exit

 } uninstall {

    source [file join $env(CCP4I_TOP) utils CCP4i_packages_utils.tcl]
    source [file join $env(CCP4I_TOP) src modules_utils.tcl]
    eval UninstallTaskPackage $task_package_name MAIN -mode nongraphical
    exit

 } install {

    source [file join $env(CCP4I_TOP) utils CCP4i_packages_utils.tcl]
    source [file join $env(CCP4I_TOP) src modules_utils.tcl]
    eval InstallTaskPackage $task_package_name MAIN $task_archive -mode nongraphical
    exit

 } import_packages {

    source [file join $env(CCP4I_TOP) utils CCP4i_packages_utils.tcl]
    source [file join $env(CCP4I_TOP) src modules_utils.tcl]
    eval ImportAllTaskPackages $old_ccp4 -mode nongraphical

 }



