#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
#
# MRBUMP wrapper for CCP4 program Ctruncate 
# Ronan Keegan 18/6/08

import os, sys, string
import subprocess
import shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CCP4_SCR'):
    raise RuntimeError, 'CCP4_SCR not found'

class Ctruncate:
   """ A class to call ctruncate. """
 
   def __init__(self):
      if os.name=="nt":
         self.ctruncateEXE = os.path.join(os.environ["CBIN"], 'ctruncate.exe')
      else:
         self.ctruncateEXE = os.path.join(os.environ["CBIN"], 'ctruncate')

      self.HKLIN = ""
      self.colF = ""
      self.colSIGF = ""
      self.logfile = ""
      self.summary = ""

      self.NCS=False
      self.TWIN=False
      self.ANISO=False
      self.temp_eigratio_line=""

      self.termination = False 

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
	
   def setDEBUG(self, flag):
      self.debug=flag

   def setlogfile(self, filename):
      self.logfile = filename 
 
   def checkEXE(self):
      """ Check to see if ctruncate is present on the system and in the PATH """

      # First check that it is present
      
      if os.path.isfile(self.ctruncateEXE) == False:
         if self.debug:
            sys.stdout.write("Ctruncate Warning: ctruncate was not found in the on the system\n")
            sys.stdout.write("ctruncate executable: %s\n" % self.ctruncateEXE)
            sys.stdout.write("\n")
         return 1
      
      path_list=[]
      # Now check to see that it is in the PATH
      if os.name!="nt":
         list=string.split(os.environ["PATH"],":")
         # Catch for "//" in the paths
         for pth in list:
            path_list.append(pth.replace("/", ""))

         if (os.path.split(self.ctruncateEXE)[0]).replace("/","") not in path_list:
            if self.debug:
               sys.stdout.write("Ctruncate Warning: ctruncate was not found in the PATH\n")
               sys.stdout.write("PATH list:\n%s\n" % path_list)
               sys.stdout.write("\n")
               sys.stdout.write("ctruncate PATH: %s\n" % os.path.split(self.ctruncateEXE)[0])
               sys.stdout.write("\n")
            return 1
      else:
         path_list=string.split(os.environ["PATH"],";")

         if os.path.split(self.ctruncateEXE)[0] not in path_list:
            if self.debug:
               sys.stdout.write("Ctruncate Warning: ctruncate was not found in the PATH\n")
               sys.stdout.write("PATH list:\n%s\n" % path_list)
               sys.stdout.write("\n")
               sys.stdout.write("ctruncate PATH: %s\n" % os.path.split(self.ctruncateEXE)[0])
               sys.stdout.write("\n")
            return 1
   
      return 0

   def ctruncate(self, HKLIN, colF, colSIGF):
      """ A function to run ctruncate. """
 
      self.HKLIN=HKLIN
      self.colF=colF
      self.colSIGF=colSIGF
 
      # Set the logfile for standard out
      if self.logfile=="":
         self.setlogfile(os.path.join(os.environ["CCP4_SCR"], "ctruncate_temp.log"))

      # Set the column label data for the command line
      colin_data = "/*/*/[" + self.colF + "," + self.colSIGF + "]"
 
      # Set the command line
      command_line = self.ctruncateEXE + ' -mtzin ' + self.HKLIN + ' -amplitudes -colin ' + colin_data + ''
         
      if self.debug:
         sys.stdout.write("\n")
         sys.stdout.write("=======================\n")
         sys.stdout.write("Ctruncate command line:\n")
         sys.stdout.write("=======================\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")
 
      # Launch ctruncate
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)
 
      child_stdin.close()         
 
      # Capture any error from the alignment job and print it to screen if debug mode is on
      log=open(self.logfile, "w")

      catch_line=False

      # Check the stdout for successful completion
      line=child_stdout.readline()
      while line:
         log.write(line)
         if "ctruncate" in line.lower() and "normal" in line.lower() and "termination" in line.lower():
            self.termination = True 

         if "No translational NCS detected" in line:
            self.NCS=False

         if "Translational NCS has been detected" in line:
            self.NCS=True

         if "Eigenvalue ratios:" in line:
            self.ANISO=True
            self.temp_eigratio_line=string.strip(line)

         if "suggests data is twinned" in line:
            self.TWIN=True

         line=child_stdout.readline()
      
      log.close()
      child_stdout.close()   

      # Compile the summary
      self.summary  = "#############################\n"
      self.summary += "###   Ctruncate Results   ###\n"
      self.summary += "#############################\n\n"
      self.summary += "TRANSLATIONAL NCS:\n"
      if self.NCS:
         self.summary += "Translational NCS has been detected\n"
      else:
         self.summary += "No translational NCS detected\n"
      self.summary += "\n"
      if self.ANISO:
         self.summary += "ANISOTROPY CORRECTION:\n"
         self.summary += self.temp_eigratio_line + "\n"
      self.summary += "\n"
      self.summary += "TWINNING ANALYSIS:\n"
      if self.TWIN:
         self.summary += "Tests suggest data is twinned.\n"
      else:
         self.summary += "No twinning detected.\n"
      self.summary += "\n"
      self.summary += "For more details see the Ctruncate log file:\n   %s\n" % self.logfile

    
      # If the job failed report an error
      if self.termination == False and self.debug:
         sys.stdout.write("ctruncate failed\n") 
         sys.stdout.write("log file: %s\n" % self.logfile)
         sys.stdout.write("\n")

   
if __name__ == '__main__':
   p=Ctruncate()
   p.debug = True
   test=p.checkEXE()
   if test == 1:
      print "No ctruncate found, exiting..."
      print ""
      sys.exit()
   p.ctruncate("temp.mtz", "FP", "SIGFP")
   sys.stdout.write(p.summary)

