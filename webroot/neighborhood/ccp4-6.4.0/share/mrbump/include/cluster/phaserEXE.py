#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for Phaser 
# Ronan Keegan - 29/1/07
#

import os, sys
import string
import time
import signal
import subprocess
import shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class PhaserEXE:
   """ A class to run a Phaser job. """

   def __init__(self):
      if os.name=="nt":
         self.phaserEXE  = os.path.join(os.environ["CBIN"], "phaser.exe")  
         self.mtzdumpEXE = os.path.join(os.environ["CBIN"], "mtzdump.exe")  
      else:
         self.phaserEXE  = os.path.join(os.environ["CBIN"], "phaser")  
         self.mtzdumpEXE = os.path.join(os.environ["CBIN"], "mtzdump")  

      self.logfile = ""
      self.hklout = ""
      self.pdbout = ""
      self.key = ""
      self.keywords = []
      self.termination=False
      self.soln_spacegroup=""
      self.soln_found=False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def set_logfile(self, filename):
      self.logfile=filename

   def set_hklout(self, filename):
      self.hklout=filename

   def set_pdbout(self, filename):
      self.pdbout=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def check_SG(self, mtzfile):
      """ Check the spacegroup of the Phaser solution from the output MTZ file. 
          hklout   - output mtz file from Phaser,
          hklinSG - the spacegroup of the input MTZ file"""

      # Run mtzdump to dump the file details

      # Check the file exists
      if os.path.isfile(mtzfile):

         # Set the command line
         command_line=self.mtzdumpEXE + " HKLIN " + mtzfile

         # Launch mtzdump
         if os.name == "nt":
            process_args = shlex.split(command_line, posix=False)
            p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                   stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
         else:
            process_args = shlex.split(command_line)
            p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                   stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

         (child_stdout, child_stdin) = (p.stdout, p.stdin)
   
         # Write the keyword input
         child_stdin.write("GO\n")
         child_stdin.close()         
    
         # Watch the output for successful termination
         out=child_stdout.readline()
   
         while out:
            if self.local_debug:
               sys.stdout.write(out)
   
            if 'Space group' in out:
               self.soln_spacegroup=string.split(out,"'")[1] 
   
            out=child_stdout.readline()
   
         child_stdout.close()

      else:
         # Report an error
         sys.stdout.write("Phaser output MTZ error: file not found\n")
         sys.stdout.write("\n")

   def run(self, working_DIR, hklout, pdbout, logfile, script="", keyfile="", LITE=False, KILLPHASER=False, KILLTIME=600.0):
      """ Function to launch a phaser job.
          LITE = boolean to control removal of files for light running of MrBUMP """

      # Change to the Phaser working directory
      curr_DIR=os.getcwd()
      os.chdir(working_DIR)

      # Give a header output
      sys.stdout.write("#######################################\n")
      sys.stdout.write("Running Phaser...... \n")
      sys.stdout.write("#######################################\n")
      sys.stdout.write("\n")

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLOUT if it has not been set already
      if self.hklout=="":
         self.hklout=hklout

      # Set PDBOUT 
      if self.pdbout=="":
         self.pdbout=pdbout

      # Set the keywords for the job 
      if keyfile == "":
      # If no keyword file is given read keywords from the input keywords
         for keyword in self.keywords:
            #self.key=self.key + keyword
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
         sys.stdout.write("#########################\n")
         sys.stdout.write("Phaser keyword input:\n")
         sys.stdout.write("#########################\n")
         sys.stdout.write("\n")
         sys.stdout.write(self.key)
         sys.stdout.write("\n")
         time.sleep(2)
         
      # Set the command line
      command_line=self.phaserEXE

      # if in Debug mode write out the run script for this Phaser job
      if (self.debug or LITE) and os.name != "nt" and script!="":
         try:
            line = "#! /bin/sh\n\n"
            line+= "%s << eof\n" % command_line 
            line+= "%s" % self.key
            line+= "eof\n"

            f=open(script, "w")
            f.write(line)
            f.close()
            os.chmod(script,0755)
         except:
            sys.stdout.write("Script write warning: Could not write phaser run script\n")
            sys.stdout.write("\n")

      start=time.time()
      # Launch Phaser
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT, preexec_fn=os.setsid)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      # Write the keyword input
      child_stdin.write(self.key)
      child_stdin.close()         
 
      log=open(self.logfile, "w")

      # Watch the output for successful termination
      out=child_stdout.readline()
      log.write(out)

      if self.debug:
         sys.stdout.write(out)

      while out:
         if self.local_debug:
            sys.stdout.write(out)

         if 'EXIT STATUS: FAILURE' in out:
            self.termination=False

         out=child_stdout.readline()
         log.write(out)
         # If we want to stop Phaser after a certain length of time:
         if os.name != "nt" and KILLPHASER: 
            elapsed=(time.time()-start)
            if elapsed >= KILLTIME:
               os.killpg(p.pid, signal.SIGTERM)
               os.killpg(p.pid, signal.SIGKILL)
               break

      child_stdout.close()
      log.close()

      # Check the output

      # Check for the output files:
      if os.path.exists(self.pdbout):
         self.termination = True
      else:
         self.termination = False

      # If this is an anisotropic correction run of phaser only an MTZ is produced.
      if "MODE MR_ANO" in self.key:
         if os.path.exists(self.hklout):
            self.termination = True
         else:
            self.termination = False

      # Report the result
      if self.termination == False: 
         self.soln_found=False
         sys.stdout.write("Phaser Error: phaser failed to complete successfully\n")
         if LITE:
            sys.stdout.write("Running in 'LITE' mode. Phaser job can be re-run using:\n  %s\n" % script)
         else:
            sys.stdout.write("Log file can be found here:\n")
            sys.stdout.write("   " + self.logfile + "\n")
         sys.stdout.write("\n")
      else:
         self.soln_found=True
         sys.stdout.write("Phaser completed successfully\n")
         if LITE:
            sys.stdout.write("Running in 'LITE' mode. Output files from Phaser have been removed but can be re-generated by running:\n  %s\n" % script)
         else:  
            sys.stdout.write("Output Log file written to:\n   " + self.logfile + "\n")
            sys.stdout.write("Output MTZ file written to:\n   " + self.hklout + "\n")
            if "MODE MR_ANO" not in self.key:
               sys.stdout.write("Output PDB file written to:\n   " + self.pdbout + "\n")
         sys.stdout.write("\n")

      # Revert to working directory
      os.chdir(curr_DIR)
