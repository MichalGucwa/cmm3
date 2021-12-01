#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for Refmac 
# Ronan Keegan - 26/1/07
#

import os, sys
import time
import subprocess
import shlex
import shutil

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class RefmacEXE:
   """ A class to run a Refmac job. """

   def __init__(self):
      if os.name=="nt":
         self.refmacEXE = os.path.join(os.environ["CBIN"], "refmac5.exe")  
      else:
         self.refmacEXE = os.path.join(os.environ["CBIN"], "refmac5")  

      self.logfile = ""
      self.hklin = ""
      self.hklout = ""
      self.pdbin = ""
      self.pdbout = ""

      self.logfileBase = ""
      self.hklinBase = ""
      self.hkloutBase = ""
      self.pdbinBase = ""
      self.pdboutBase = ""

      self.copyPDB=False
      self.copyMTZ=False

      self.key = ""
      self.keywords = []
      self.termination=False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def set_logfile(self, filename):
      self.logfile=filename

   def set_hklin(self, filename):
      self.hklin=filename

   def set_hklout(self, filename):
      self.hklout=filename

   def set_pdbin(self, filename):
      self.pdbin=filename

   def set_pdbout(self, filename):
      self.pdbout=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def run(self, hklin, hklout, pdbin, pdbout, logfile, refineType, refineDir="", script="", keyfile="", LITE=False):
      """ Function to launch a refmac job. """

      # Give a header output
      sys.stdout.write("############################################################\n")
      sys.stdout.write("Running Refmac: %s...... \n" % refineType)
      sys.stdout.write("############################################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Reindex details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 
      self.logfileBase=os.path.basename(logfile) 

      # Set HKLIN & HKLOUT if it has not been set already
      if self.hklin=="":
         self.hklin=hklin
      self.hklinBase=os.path.basename(self.hklin) 

      if self.hklout=="":
         self.hklout=hklout
      self.hkloutBase=os.path.basename(self.hklout) 

      # Set PDBIN & PDBOUT 
      if self.pdbin=="":
         self.pdbin=pdbin
      self.pdbinBase=os.path.basename(self.pdbin) 

      if self.pdbout=="":
         self.pdbout=pdbout
      self.pdboutBase=os.path.basename(self.pdbout) 

      # Set the keywords for the job 
      if keyfile == "":
      # If no keyword file is given read keywords from the input keywords
         for keyword in self.keywords:
            self.key=self.key + keyword + "\n"

      else:
      # Read keywords from the keyword file 
         kfile=open(keyfile, "r")
         line=kfile.readline()
         while line:
            self.key = self.key + line
            line=kfile.readline()
         kfile.close()
        
      # Output the keywords if in debug mode
      if self.local_debug:
         sys.stdout.write("###################################################\n")
         sys.stdout.write("Refmac keyword input: %s \n" % refineType)
         sys.stdout.write("###################################################\n")
         sys.stdout.write("\n")
         sys.stdout.write("Refmac keyword file name:\n   %s\n" % keyfile)
         sys.stdout.write(self.key)
         sys.stdout.write("\n")
         time.sleep(2)
         
      # Make a note of the current working diretory
      currentDir=os.getcwd()

      # Change to the Refmac directory so we can run refmac without long paths
      os.chdir(refineDir)

      # Copy in the PDB and MTZ file for efficient running of Refmac. If we ran Rigid Body first the file will already exist.
      if os.path.isfile(os.path.join(refineDir, self.pdbinBase)) == False:
         shutil.copyfile(self.pdbin, os.path.join(refineDir, self.pdbinBase))
         self.copyPDB=True
      if os.path.isfile(os.path.join(refineDir, self.hklinBase)) == False:
         shutil.copyfile(self.hklin, os.path.join(refineDir, self.hklinBase))
         self.copyMTZ=True

      # Set the command line
      command_line=self.refmacEXE + " HKLIN %s HKLOUT %s XYZIN %s XYZOUT %s" % (self.hklinBase, self.hkloutBase, self.pdbinBase, self.pdboutBase)

      # if in Debug mode write out the run script for this Refmac job
      if (self.debug or LITE) and os.name != "nt" and script != "":
         try:
            line = "#! /bin/sh\n\n"
            line+= "cp %s %s\n" % (self.pdbin, os.path.join(refineDir, self.pdbinBase)) 
            line+= "cp %s %s\n\n" % (self.hklin, os.path.join(refineDir, self.hklinBase)) 
            line+= "%s << eof\n" % command_line 
            line+= "%s" % self.key
            line+= "eof\n"

            f=open(script, "w")
            f.write(line)
            f.close()
            os.chmod(script,0755)
         except:
            sys.stdout.write("Script write warning: Could not write refmac run script\n")
            sys.stdout.write("\n")

      # Open a pipe to the job
      # Echo the command line in debug mode
      if self.local_debug:
         sys.stdout.write("\n")
         sys.stdout.write("======================\n")
         sys.stdout.write("Refmac command line:\n")
         sys.stdout.write("======================\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch refmac
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      # Write the keyword input
      child_stdin.write(self.key)
      child_stdin.close()         
 
      # Open the log file for writing
      log=open(self.logfile, "w")

      # Watch the output for successful termination
      out=child_stdout.readline()

      while out:
         if self.local_debug:
            sys.stdout.write(out)

         if 'End of Refmac' in out:
            self.termination=True

         log.write(out)
	 log.flush()
         out=child_stdout.readline()

      child_stdout.close()
      log.close()

      # Check the output
      if self.termination == False: 
         sys.stdout.write("Refinement log: refmac failed to complete successfully\n")
         sys.stdout.write("\n")
         sys.stdout.write("Log file can be found here:\n")
         sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Refinement log: Refmac completed successfully\n")
         sys.stdout.write("\n")
         sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
         sys.stdout.write("Output PDB file written to:\n   " + self.pdbout + "\n")
         sys.stdout.write("\n")

      # Revert to the working directory before refmac run
      os.chdir(currentDir)

      # Delete any copied files to save space
      if self.debug == False:
         if self.copyPDB and os.path.isfile(os.path.join(refineDir, self.pdbinBase)):
            os.remove(os.path.join(refineDir, self.pdbinBase))
         if self.copyMTZ and os.path.isfile(os.path.join(refineDir, self.hklinBase)):
            os.remove(os.path.join(refineDir, self.hklinBase))
    
