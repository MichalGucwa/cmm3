#     Copyright (C) 2005-2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - ccp4ilite.tcl
#
# Duplicates a subset of useful CCP4i "core" functions so that they
# are available if the main CCP4i functions have not been loaded.
# 
# Peter Briggs and Wanjuan Yang
# Based on code originally written by Liz Potterton
#====================================================================

#CCP4i_cvs_Id $Id: ccp4ilite.tcl,v 1.9 2008/08/12 10:47:59 pjx Exp $

##################################################################

#
#d_index_title CCP4i Functions (ClientAPI/ccp4ilite.tcl)
#d_intro_title Duplicates of CCP4i functions that can be used without CCP4i
#d_intro Functions that replicate those found in the main CCP4i source \
code. There are made available here so that the full set of CCP4i source \
files do not need to be loaded, hopefully enabling the creation of lighter \
weight standalone Tcl applications.

if { [info procs GetUserId] == "" } {
#-----------------------------------------------------------------------
proc GetUserId { } {
#-----------------------------------------------------------------------
#d_sum Return the user's id. 
    if { ![regexp WINDOWS [GetOPSYS]] } {
	return [GetEnvPath USER]
    } else {
	return [GetEnvPath USERNAME]
    }
}
# End of definition of GetUserId
}

if { [info procs GetDotCCP4] == "" } {
#-----------------------------------------------------------------------
proc GetDotCCP4 { } {
#-----------------------------------------------------------------------
#d_sum Return the location of the .CCP4 directory
#d_desc The .CCP4 directory is used to store user-specific CCP4 data.
#d_desc This code was originally copied from ccp4i/src/system.tcl
  global system

  switch [GetOPSYS] {
      UNIX {
	  return [file join [GetEnvPath HOME] .CCP4]
      }
      WINDOWS  {
	  if { [GetEnvPath USERPROFILE ] == "" } {
	      if { [info exists system(LOGIN_NAME)] } {
		  set uid $system(LOGIN_NAME)
	      } else {
		  set uid [GetUserId]
	      }
	      return [file join [GetEnvPath SystemRoot] Profiles $uid CCP4]
	  } else { 
	      return [file join [GetEnvPath USERPROFILE] CCP4]
	  }
      }
  }
  return {}
}
# End of definition of GetDotCCP4
}

if { [info procs GetOPSYS] == "" } {
#-----------------------------------------------------------------------
proc GetOPSYS { } {
#-----------------------------------------------------------------------
#d_sum Return the operating system type
#d_desc Returns the upper-cased platform type e.g. UNIX or WINDOWS.
    global system tcl_platform
    if { [array exists system] && [info exists system(OPSYS)] } {
	return $system(OPSYS)
    } else {
	return [string toupper $tcl_platform(platform)]
    }
}
# End of definition of GetOPSYS
}

if { [info procs GetEnvPath] == "" } {
#----------------------------------------------------------------
proc GetEnvPath { var { report 1 } } {
#----------------------------------------------------------------
#d_sum Get operating system environment variable
#d_desc Return a path name associated with an environment variable - in a \
Windows system the separators are converted to forward slash. \
Return an empty string if no environment variable found.
#d_desc This procedure was copied from ccp4i/src/system.tcl but has been \
modified to use the GetOPSYS procedure
#d_arg var Environment variable
#d_arg report Optional - default 1.  If true (1) then output warning message if \
environment variable not found.
  global env

# Get environment variable - cope with whether input var has
# leading '$' or not

  regsub {^\$} $var  {} var1

# On NT change the separators to unix style /

  if { [regexp WINDOWS [GetOPSYS]] } {
    set status [catch { global env; 
      regsub -all {\\} $env($var1) \/ path } nc ]
  } else {
    set status [catch {global env; set p1 $env($var1)} path ]
  }
  if { $status } { 
    set path ""
    if { $report } { 
      WarningMessage "Cannot get value for environment variable \"$var\"" }
  } 
  return $path
}
# End of definition of GetEnvPath
}

if { [info procs WarningMessage] == "" } {
#----------------------------------------------------------------
proc WarningMessage { message } {
#----------------------------------------------------------------
#d_sum Report a warning or display a message
#d_desc This is a non-graphical placeholder for the WarningMessage \
function in the core CCP4i
  catch { puts $message }
}
# End of definition of WarningMessage
}
