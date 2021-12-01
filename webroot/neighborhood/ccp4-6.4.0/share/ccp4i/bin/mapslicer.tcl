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
# Hide the Tk window
wm withdraw .
#
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

#---------------------------------------------------------------
proc LoadCcp4Map { } {
#---------------------------------------------------------------
  package ifneeded ccp4map 4.0 {
    # on OSX sharedlibextension is .dylib, but loadable module has .so
    set libname libccp4map[string map {dylib so} [info sharedlibextension]]
    load [file join [GetEnvPath CLIB] $libname] ccp4map
  }
# Make sure we actually have it
  if { [catch { package require ccp4map 4.0 } errmsg ] } {
    puts "Couldn't find (or load) the MapSlicer command library (\"ccp4map\" package)"
    puts "Error: $errmsg"
    puts "This should have been built as part of the main CCP4 installation, however"
    puts "it is not available on all platforms."
    puts "Stopping"
    exit
  }
}

#---------------------------------------------------------------

# Source startup.tcl appropriate for operating system

  set system(OPSYS) [string toupper $tcl_platform(platform)]
  source [file join $env(CCP4I_TOP) bin $system(OPSYS) startup.tcl]

# This line from loggraph not needed
# package require BLT

global system
set system(RUN_MODE)		mapslicer
set system(TK_VERSION)		$tk_version

source [file join $env(CCP4I_TOP) src system.tcl]
source [file join $env(CCP4I_TOP) src utils.tcl]

# If there is an autoconfigure procedure for the system parameters and this opsys
# then run it
if { [llength [info proc autoconf_[subst $system(OPSYS)]_system]] > 0 } {
      autoconf_[subst $system(OPSYS)]_system system }

InitialiseDotCCP4
global configure
InitialisePreferences configure configure

if { [llength $argv] > 0 } {
  set n 0; set nargs [llength $argv]
  if { $nargs == 1 && ![regexp ^- [lindex $argv 1]] } { 
    set system(SCRIPT) [lindex $argv 0]
  } else {
    while { $n < $nargs } {
      set comd [lindex $argv $n]
      if { [regexp -- -i $comd] } {
        incr n; set system(SCRIPT) [lindex $argv $n]
      } elseif { [regexp -- -f $comd] } {
        incr n; set system(FORMAT) [lindex $argv $n]
      } elseif { [regexp -- -p $comd] } {
        incr n; set system(PARENT_APPNAME) [lindex $argv $n]
      }
      incr n
    }
  }
}

LoadCcp4Map

source [file join $env(CCP4I_TOP) mapslicer mapslicer_main.tcl]
