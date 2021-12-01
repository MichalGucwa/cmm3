#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for CCP4 program Acorn 
# Ronan Keegan - 15/2/07
#

import os, sys, string
import time
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Acorn:
   """ A class to run a Acorn job. """

   def __init__(self):
      if os.name=="nt":
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn.exe")  
      else:
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn")  

      self.logfile = ""
      self.hklin = ""
      self.hklout = ""
      self.xyzin = ""
      self.key = ""
      self.keywords = []
      self.termination=False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug=False

   def set_logfile(self, filename):
      self.logfile=filename

   def set_hklin(self, filename):
      self.hklin=filename

   def set_hklout(self, filename):
      self.hklout=filename

   def set_xyzin(self, filename):
      self.xyzin=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)

   def run(self, hklin, hklout, xyzin, logfile):
      """ Function to launch a acorn job for a given MTZ file. """

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Running Acorn:\n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Acorn details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLINs and HKLOUT if they have not been set already
      if self.hklin=="":
         self.hklin=hklin

      if self.hklout=="":
         self.hklout=hklout

      # Set xyzin
      if self.xyzin=="":
         self.xyzin=xyzin

      # Set the input keywords
      for keyword in self.keywords:
         self.key=self.key + keyword + "\n"
      
      # Output the keywords if in debug mode
      if self.local_debug:
         sys.stdout.write("#########################\n")
         sys.stdout.write("Keyword input:\n")
         sys.stdout.write("#########################\n")
         sys.stdout.write("\n")
         sys.stdout.write(self.key)
         sys.stdout.write("\n")
         time.sleep(2)

      # Set the command line
      command_line=self.acornEXE + " HKLIN %s HKLOUT %s XYZIN %s" % (self.hklin, self.hklout, self.xyzin)

      # Display the command line
      if self.local_debug:
         sys.stdout.write("Command line for Acorn: \n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch acorn
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (oe, i) = (p.stdout, p.stdin)

      # Write the keywords to the job
      i.write(self.key)
      i.close()

      # Open the log file for writing
      log=open(self.logfile, "w")

      # Watch the output for successful termination
      out=oe.readline()
      log.write(out)

      while out:
         if self.local_debug:
            sys.stdout.write(out)

         if 'NORMAL TERMINATION' in out.upper():
            self.termination=True
         out=oe.readline()
         log.write(out)

      oe.close()
      log.close()

      # Check the output
      if self.termination == False: 
         sys.stdout.write("Acorn Error: acorn failed to complete successfully\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Acorn completed successfully\n")
         sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
         sys.stdout.write("\n")
 

if __name__ == "__main__":
   """ An example run."""

   # Instantiate the class
   acorn=Acorn()

   # Set the debug flag to true
   acorn.local_debug=True

   # Set the keywords 
   acorn.add_keyword("LABIn FP=F SIGFP=SIGF E=E")
   acorn.add_keyword("POSI 1")

   # Acorn the MTZ file
   acorn.run("ecalc_out.mtz", "acorn_out.mtz", "acorn_in.pdb", "acorn.log")
