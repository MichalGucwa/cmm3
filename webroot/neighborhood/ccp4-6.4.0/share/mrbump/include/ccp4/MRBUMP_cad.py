#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for CCP4 program Cad 
# At the moment it just merges 2 hklin files
# Ronan Keegan - 15/2/07
#

import os, sys, string
import time
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Cad:
   """ A class to run a Cad job. """

   def __init__(self):
      if os.name=="nt":
         self.cadEXE = os.path.join(os.environ["CCP4_BIN"], "cad.exe")  
      else:
         self.cadEXE = os.path.join(os.environ["CCP4_BIN"], "cad")  

      self.logfile = ""
      self.hklin1 = ""
      self.hklin2= ""
      self.hklout = ""
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

   def set_hklin1(self, filename):
      self.hklin1=filename

   def set_hklin2(self, filename):
      self.hklin2=filename

   def set_hklout(self, filename):
      self.hklout=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def run(self, hklin1, hklin2, hklout, logfile):
      """ Function to launch a cad job for a given MTZ file. """

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Running Cad\n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Cad details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLINs and HKLOUT if they have not been set already
      if self.hklin1=="":
         self.hklin1=hklin1

      if self.hklin2=="":
         self.hklin2=hklin2

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
      command_line=self.cadEXE + " HKLIN1 %s HKLIN2 %s HKLOUT %s" % (self.hklin1, self.hklin2, self.hklout)

      # Display the command line
      if self.local_debug:
         sys.stdout.write("Command line for Cad: \n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch cad
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
         sys.stdout.write("Cad Error: cad failed to complete successfully\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Cad completed successfully\n")
         sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
         sys.stdout.write("\n")
 

if __name__ == "__main__":
   """ An example run."""

   # Instantiate the class
   cad=Cad()

   # Set the debug flag to true
   cad.debug=True

   # Set the keywords 
   cad.add_keyword("LABIN FILE 1 ALL")
   cad.add_keyword("LABIN FILE 2 ALL")
   cad.add_keyword("END")
 
   # Cad the MTZ file
   cad.run("npii.mtz", "out.mtz", "cad_out.mtz", "cad.log")
