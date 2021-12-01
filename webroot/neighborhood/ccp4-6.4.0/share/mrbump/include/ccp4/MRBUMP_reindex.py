#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for Reindexing the target MTZ file 
# Ronan Keegan - 18/12/06
#

import os, sys, string
import time
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Reindex:
   """ A class to run a Reindex job on an input MTZ file. """

   def __init__(self):
      if os.name=="nt":
         self.reindexEXE = os.path.join(os.environ["CCP4_BIN"], "reindex.exe")  
      else:
         self.reindexEXE = os.path.join(os.environ["CCP4_BIN"], "reindex")  

      self.logfile = ""
      self.hklin = ""
      self.hklout = ""
      self.key = ""
      self.keywords = []
      self.spacegroup=""
      self.spacegroup_ID=""
      self.termination=False

      self.enant_found=True

      self.ENANT_SGs={"P31" : "P32", "P32" : "P31", "P3112" : "P3212", "P3212" : "P3112",
                      "P3121" : "P3221", "P3221" : "P3121", "P41" : "P43", "P43" : "P41",
                      "I41" : "I41", "P4122" : "P4322", "P4322" : "P4122", "P41212" : "P43212",
                      "P43212" : "P41212", "I4122" : "I4122", "P61" : "P65", "P65" : "P61",
                      "P62" : "P64", "P64" : "P62", "P6122" : "P6522", "P6522" : "P6122",
                      "P6222" : "P6422", "P6422" : "P6222", "F4132" : "F4132", "P4332" : "P4132",
                      "P4132" : "P4332", "I4132" : "I4132"}

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

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def find_spacegroup_id(self, target_spacegroup):
      """ Find out what the spacegroup ID for the enantiomorph is. """

      if target_spacegroup in self.ENANT_SGs.keys():
         self.spacegroup_ID = self.ENANT_SGs[target_spacegroup]
         sys.stdout.write("Reindex: Enantiomorph found for target spacegroup: %s\n" % target_spacegroup) 
         sys.stdout.write("Reindex: Enantiomorphic spacegroup: %s\n" % self.spacegroup_ID) 
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Reindex Warning: spacegroup %s does not have an enantiomorph\n" % target_spacegroup)
         sys.stdout.write("\n")
         self.enant_found=False
  
   def run(self, hklin, hklout, logfile):
      """ Function to launch a reindex job for a given MTZ file. """

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Reindexing MTZ file\n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Reindex details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLIN and HKLOUT if they have not been set already
      if self.hklin=="":
         self.hklin=hklin

      if self.hklout=="":
         self.hklout=hklout


      # Set the input keywords
      for keyword in self.keywords:
         self.key=self.key + keyword + "\n"
      
         # Catch for the spacegroup 
         if "SYMM" in keyword:
            self.spacegroup=string.join(string.split(keyword)[1:], "")

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
      command_line=self.reindexEXE + " HKLIN %s HKLOUT %s" % (self.hklin, self.hklout)

      # Launch reindex
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (o, i) = (p.stdout, p.stdin)

      # Enter the keywords
      i.write(self.key)
      i.close()
 
      # Open the log file for writing
      log=open(self.logfile, "w")

      # Watch the output for successful termination
      out=o.readline()
      log.write(out)

      while out:
         if self.local_debug:
            sys.stdout.write(out)

         if 'Normal termination' in out:
            self.termination=True
         out=o.readline()
         log.write(out)

      o.close()
      log.close()

      # Check the output
      if self.termination == False: 
         sys.stdout.write("Reindex Error: reindex failed to complete successfully\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("MTZ file: " + self.hklin + " reindexed to spacegroup " + self.spacegroup + "\n")
         sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
         sys.stdout.write("\n")
 


if __name__ == "__main__":
   """ An example run. Requires an mtz file called emma.mtz in the current directory."""

   # Instantiate the class
   reindex=Reindex()

   # Set the debug flag to true
   reindex.debug=True

   reindex.find_spacegroup_id("P32")

   # Set the keywords 
   reindex.add_keyword("SYMMETRY P32")
   reindex.add_keyword("REINDEX HKL h,k,l")
   reindex.add_keyword("NOREDUCE")
   reindex.add_keyword("END")
 
   # Reindex the MTZ file
   reindex.run("emma.mtz", "emma_reindex.mtz", "reindex.log")
