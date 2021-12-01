#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for CCP4 program Unique 
# Ronan Keegan - 15/2/07
#

import os, sys, string
import time
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Unique:
   """ A class to run a Unique job. """

   def __init__(self):
      if os.name=="nt":
         self.uniqueEXE = os.path.join(os.environ["CCP4_BIN"], "unique.exe")  
      else:
         self.uniqueEXE = os.path.join(os.environ["CCP4_BIN"], "unique")  

      self.logfile = ""
      self.hklout = ""
      self.key = ""
      self.keywords = []
      self.termination=False

      self.F="Funi"
      self.SIGF="SIGFuni"

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug=False

   def set_logfile(self, filename):
      self.logfile=filename

   def set_hklout(self, filename):
      self.hklout=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def run(self, hklout, logfile):
      """ Function to launch a unique job for a given MTZ file. """

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Running Unique\n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Unique details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLOUT if they have not been set already
      if self.hklout=="":
         self.hklout=hklout

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
      command_line=self.uniqueEXE + " HKLOUT %s" %  self.hklout

      # Display the command line
      if self.local_debug:
         sys.stdout.write("Command line for Unique: \n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch unique
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
         sys.stdout.write("Unique Error: unique failed to complete successfully\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Unique completed successfully\n")
         sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
         sys.stdout.write("\n")
 


if __name__ == "__main__":
   """ An example run."""

   # Instantiate the class
   unique=Unique()

   # Set the debug flag to true
   unique.debug=True

   # Set the keywords 
   unique.add_keyword("LABOUT F=%s SIGF=%s" % (unique.F, unique.SIGF))
   unique.add_keyword("SYMMETRY P21")
   unique.add_keyword("CELL 38.4300   34.7640   60.2760   90.0000  106.0290   90.0000")
   unique.add_keyword("RESO 1.0")
   unique.add_keyword("END")
 
   # Run Unique
   unique.run("out.mtz", "unique.log")
