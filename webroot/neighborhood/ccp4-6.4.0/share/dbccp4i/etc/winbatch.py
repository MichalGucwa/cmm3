#
# winbatch.py
#
# Generate batch files for running the dbccp4i applications
# under Windows
#
#CCP4i_cvs_Id $Id: winbatch.py,v 1.9 2008/08/12 10:48:19 pjx Exp $

"""winbatch.py

Run this as a Python application under Windows to generate batch
files that can launch the various dbCCP4i applications.

Usage: python winbatch.py [-dbccp4i_top <path_to_dbccp4i_dir>]

Specify the full path to the folder containing the top-level
dbccp4i folder."""

import os
import sys
import time

def WriteBatchFile(name,execline,dbccp4i_path):
   """Write a Windows batch file.

   This function writes a simple batch file which sets up the
   environment to execute the command given in the 'execline'
   argument."""
   batchn = str(name)+".bat"
   datestr =  time.strftime("%H:%M:%S %d %b %y",time.localtime())
   outfile = open(batchn,"w")
   outfile.write("@echo off\n")
   outfile.write("rem Batch script for "+str(name)+"\n")
   outfile.write("rem Generated automatically at "+str(datestr)+"\n")
   outfile.write("echo Starting "+str(name)+"\nsetlocal\n")
   outfile.write("set DBCCP4I_TOP="+os.path.join(dbccp4i_path,"dbccp4i")+"\n")
   outfile.write(str(execline)+"\n")
   outfile.write("endlocal\necho Finishing "+str(name)+"\n")
   outfile.close()
   print "Wrote "+str(batchn)
   return

if __name__ == "__main__":

   # Pick up the environment variables
   dbccp4i_top = ""
   i = 1
   while i < len(sys.argv):
      arg = sys.argv[i]
      if arg == "-dbccp4i_top":
         i = i+1
         dbccp4i_top = sys.argv[i]
      else:
         print "Unknown option: "+str(arg)
         print "Usage: python winbatch.py [-dbccp4i_top <path_to_dbccp4i_dir>]"
         sys.exit(1)
      i = i+1

   # Report settings
   if dbccp4i_top == "":
      print "No value for DBCCP4I_TOP!"
      sys.exit(1)
   print "DBCCP4I_TOP: "+str(dbccp4i_top)

   # Do some checks
   # Check that the DBCCPI_TOP variable is an
   # absolute paths and that it exists
   if not os.path.isabs(dbccp4i_top):
      print "Warning: DBCCP4I_TOP is not an absolute path!"
      sys.exit(1)

   # Write dbccp4i.bat
   WriteBatchFile("dbccp4i", \
                  "call python "+os.path.join("%DBCCP4I_TOP%","dbccp4i","dbccp4i.py"),dbccp4i_top)

   # Write dbconsole.bat
   WriteBatchFile("dbconsole", \
                  "call tclsh "+os.path.join("%DBCCP4I_TOP%","application","dbconsole.tcl"),dbccp4i_top)

   # Write dbconsole_py.bat
   WriteBatchFile("dbconsole_py", \
                  "call python "+os.path.join("%DBCCP4I_TOP%","application","dbconsole.py"),dbccp4i_top)

   # Write starKey.bat
   WriteBatchFile("starKey", \
                  "call python "+os.path.join("%DBCCP4I_TOP%","application","starKey.py")+" %*",dbccp4i_top)

   # Write dbviewer.bat
   WriteBatchFile("dbviewer", \
                  "call wish "+os.path.join("%DBCCP4I_TOP%","application","viewer.tcl")+" %1",dbccp4i_top)

   # Write run_tests.bat
   WriteBatchFile("run_tests", \
                  "call tclsh \""+os.path.join("%DBCCP4I_TOP%","test","run_tests.tcl")+"\"",dbccp4i_top)
