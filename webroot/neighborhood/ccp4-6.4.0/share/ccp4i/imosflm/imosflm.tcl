# first some definitions, just so we can keep track of the various variables
#
# People used to running MS-Windows should be aware that _all_ directory
# separators in these files should be "/", not "\"!
#
# STARTDIR is the current working directory; we should return here after exiting 
# from iMosflm
#
# HOMEDIR is the directory in which the iMosflm distribution sits - this file 
# should be in this directory
#
# MOSDIR is where the user's log files from iMosflm should go. Currently, lots of 
# stuff also goes into a directory called ".mosflm", but this will change because 
# it's bad.
#
# CLIBD, CINCL and CCP4_SCR are locations of CCP4 related files. If CCP4 hasn't been
# installed properly, and these haven't been set up, then they will be duplicated 
# here; the two files "environ.def" and "default.def" are in CINCL, and 
# "syminfo.lib" is in CLIBD.
#
# MOSFLM_EXEC points to the ipmosflm.exe (or mosflm.exe) file
#
# IMOSFLM points to the imosflm.tcl file which actually starts up iMosflm.

 set nargs [llength $argv]; set n 0
  while { $n < $nargs } {
    set cmd [string tolower [lindex $argv $n]]
    switch -regexp -- $cmd \
    project {
# Luke checks lindex $argv $n and if it is empty we do not set MOSDIR here
      incr n
      if {[lindex $argv $n] != ""} {
	 set ::env(MOSDIR) [lindex $argv $n]
      }
    } 
    incr n
  }

set STARTDIR [pwd]
#
# you should only need to edit the value for HOMEDIR. If you want it in your 
# home folder, uncomment the following line and comment out the subsequent one.
#
#set ::env(HOMEDIR) [regsub -all {\\} $env(userprofile) {/}]
set ::env(HOMEDIR) $STARTDIR
if { ![info exists env(MOSDIR)] } {
if { ![regexp -nocase windows $::tcl_platform(os)] } {
   set ::env(MOSDIR) $env(HOME)/mosdir 
} else {
   set ::env(MOSDIR) $env(HOMEPATH)/mosdir 
}
}
set ::env(MOSDIR) [file nativename [file normalize $env(HOMEDIR)/mosdir]]
puts " MOSDIR is $env(MOSDIR)"
if { ! [file exists $env(MOSDIR)] } {
    file mkdir $env(MOSDIR)
} {
    if { ! [file isdirectory $env(MOSDIR)] } {
	puts "stop here; the directory for all your output files cannot"
	puts "be created because the name we want to use is a regular file"
	exit
    }
}

# A quick fix to avoid $CCP4_BROWSER in setup files / Windows registry.
# Using default system browser (like in idiffdisp.tcl) would be much better.
if { ![info exists env(CCP4_BROWSER)] } {
    if { $::tcl_platform(os) == "Darwin" } {
        set ::env(CCP4_BROWSER) safari
    } elseif { [regexp -nocase windows $::tcl_platform(os)] } {
        set ::env(CCP4_BROWSER) {C:\Program Files\Internet Explorer\iexplore.exe}
    } else {
        set ::env(CCP4_BROWSER) firefox
    }
}

# imosflm is using python, not ccp4-python, here is a workaround
if { ![catch { exec ccp4-python -c "import sys ; print sys.exec_prefix" } python_dir] } {
    set env(PATH) "$python_dir:$env(PATH)"
}

#
# check for CCP4 environment variables
#
if { ! [info exists env(CLIBD)] } {
    set ::env(CLIBD) $env(HOMEDIR)
}
if { ! [info exists env(CINCL)] } {
    set ::env(CINCL) $env(HOMEDIR)
}
if { ! [info exists env(CCP4_SCR)] } {
    set ::env(CCP4_SCR) $env(HOMEDIR)/scratch
    if { ! [file isdirectory $env(CCP4_SCR)] } {
	file mkdir $env(CCP4_SCR)
    }
}

#test if MOSFLM_EXEC is defined. Only overwrite if it undefined
if {![info exists env(MOSFLM_EXEC)]} {
 if { [info exists env(CCP4)] } {
   if { ![regexp -nocase windows $::tcl_platform(os)] } {
            set ::env(MOSFLM_EXEC) [file join [file normalize $env(CBIN)] ipmosflm]
      } else {
            set ::env(MOSFLM_EXEC) [file join [file normalize $env(CBIN)] ipmosflm.exe]
      }
  } else {
      if { ![regexp -nocase windows $::tcl_platform(os)] } {
            set ::env(MOSFLM_EXEC) $env(HOMEDIR)/ipmosflm
      } else {
            set ::env(MOSFLM_EXEC) $env(HOMEDIR)/ipmosflm.exe
      }
 }
}

#set ::env(MOSFLM_EXEC) [file nativename [file normalize $env(HOMEDIR)/bin/ipmosflm.exe]]

if { [info exists env(CCP4)] } {
      set ::env(IMOSFLM) [file join [file normalize $env(CCP4I_TOP)] imosflm src imosflm.tcl] 
   } else {

      set ::env(IMOSFLM) $env(HOMEDIR)/src/imosflm.tcl

   }

# don't want this here? I think we do for the Windows Help About
set ::env(IMOSFLM_VERSION) "iMosflm 1.0.7 - May 2012 (using Mosflm 7.0.9)"
# move to directory for running iMosflm, stores all output here
cd $env(MOSDIR)

set timestamp "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]"
# test to see if mosflm.lp exists, if yes, rename it.
if { [file exists mosflm.lp]} {   
    file rename mosflm.lp mosflm_$timestamp.lp
}
if { [file exists SUMMARY]} { 
    puts "SUMMARY exists and is being renamed"
    file rename SUMMARY mosflm_$timestamp.sum
}

# now run imosflm!
set ::env(MOSFLM_LOGGING) 0
source $env(IMOSFLM)

# go back to starting directory

#cd $STARTDIR
