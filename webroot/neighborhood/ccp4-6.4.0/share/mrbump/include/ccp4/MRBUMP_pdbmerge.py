#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for CCP4 program Pdb_merge 
# Ronan Keegan - 6/8/07
#

import os, sys, string
import time
import random
import shutil
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class PDB_merge:
   """ A class to run a Acorn job. """

   def __init__(self):
      if os.name=="nt":
         self.pdb_mergeEXE = os.path.join(os.environ["CCP4_BIN"], "pdb_merge.exe")  
      else:
         self.pdb_mergeEXE = os.path.join(os.environ["CCP4_BIN"], "pdb_merge")  

      self.logfile = ""
      self.xyzin1 = ""
      self.xyzin2 = ""
      self.xyzout = ""
      self.xyzin = []
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

   def set_xyzin1(self, filename):
      self.xyzin1=filename

   def set_xyzin2(self, filename):
      self.xyzin2=filename

   def set_xyzin(self, filename):
      self.xyzin.append(filename)

   def add_keyword(self, keyword):
      self.keywords.append(keyword)

   def run(self, xyzin1, xyzin2, xyzout, logfile):
      """ Function to launch a pdb_merge job. """

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Running PDB_merge:\n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the PDB_merge details

      # Check to see if the logfile has been specified, otherwise give it a default name
      self.logfile=logfile 

      # Set XYZINs and XYZOUT if they have not been set already
      self.xyzin1=xyzin1
      self.xyzin2=xyzin2
      self.xyzout=xyzout

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
      command_line=self.pdb_mergeEXE + " XYZIN1 %s XYZIN2 %s XYZOUT %s" % (self.xyzin1, self.xyzin2, self.xyzout)

      # Display the command line
      if self.local_debug:
         sys.stdout.write("Command line for PDB_merge: \n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch pdbmerge
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
         sys.stdout.write("PDB_merge Error: pdb_merge failed to complete successfully\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("PDB_merge completed successfully\n")
         sys.stdout.write("Output PDB file written to:\n   " + self.xyzout + "\n")
         sys.stdout.write("\n")
 
   def run_multiple(self, XYZOUT, LOGFILE, TEMPDIR=""):
      """ If inputting more than 2 files use this to run pdb_merge recursively. """

      #temp_dirname="pdb_merge_" + time.ctime().replace(" ","_").replace(":","_")
      temp_dirname="pdb_merge_" + str(random.randint(1000000,2000000))
      if TEMPDIR=="":
         temp_DIR=os.path.join(os.environ["CCP4_SCR"], temp_dirname) 
      else:
         temp_DIR=os.path.join(TEMPDIR, temp_dirname) 
      if os.path.isdir(temp_DIR) == False:
         os.mkdir(temp_DIR)

      for i in range(len(self.xyzin)):
     
         if i==0:
            xyzin1=self.xyzin[0]
         else:
            xyzin1=temp_xyzout

         if i < len(self.xyzin) - 1:
            xyzin2=self.xyzin[i+1]
            temp_xyzout= os.path.join(temp_DIR, "xyzout_%d.pdb" % i)

            self.logfile=os.path.join(temp_DIR, "pdb_merge_%d.log" % i)

            self.keywords=[]
            self.key=""
            self.add_keyword("NOMERGE")
            self.add_keyword("OUTPUT PDB")
            self.add_keyword("END")

            self.run(xyzin1, xyzin2, temp_xyzout, self.logfile) 
         else:
            self.xyzout=xyzin1

      shutil.copyfile(self.xyzout, XYZOUT)

      # Reassign self.xyzout to the output from the function
      self.xyzout=XYZOUT

      if self.local_debug == False:
         if os.path.isdir(temp_DIR):
            shutil.rmtree(temp_DIR)


if __name__ == "__main__":
   """ An example run."""

   # Instantiate the class
   pdb_merge=PDB_merge()

   # Set the debug flag to true
   pdb_merge.local_debug=False

   # Set the keywords 
   pdb_merge.add_keyword("NOMERGE")
   pdb_merge.add_keyword("OUTPUT PDB")
   pdb_merge.add_keyword("END")

   # Acorn the MTZ file
   #pdb_merge.run("xyzin1.pdb", "xyzin2.pdb", "xyzout.pdb", "pdb_merge.log")
 
   pdb_merge.xyzin.append("xyzin1.pdb")   
   pdb_merge.xyzin.append("xyzin2.pdb")   
   pdb_merge.xyzin.append("xyzin3.pdb")   
   pdb_merge.xyzin.append("xyzin4.pdb")   
 
   pdb_merge.run_multiple("output.pdb", "pdb_merge.log")

   print "XYZOUT written to:", pdb_merge.xyzout
