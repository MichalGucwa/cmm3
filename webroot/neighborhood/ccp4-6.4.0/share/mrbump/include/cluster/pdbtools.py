#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A PDB parsing class to go with the phaser/molrep/refmac exe scripts 
# Ronan Keegan - 29/1/07
#

import os, sys
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'


class Get_PDB_Details:
   """ Extract details from the PDB file."""

   def __init__(self):

      if os.name=="nt":
         self.pdbcurEXE = os.path.join(os.environ["CBIN"], "pdbcur.exe")  
      else:
         self.pdbcurEXE = os.path.join(os.environ["CBIN"], "pdbcur")  

      self.molrep_mol_count = 1
      self.phaser_mol_count = 0
      self.mol_count = 1

      self.pdbin = ""
      self.logfile = ""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug=False

   def get_details(self, pdb_filename):
      """ Parse the PDB file to extract any relevant details. """

      self.pdbin = pdb_filename

      if os.path.isfile(self.pdbin) == False:
         sys.stdout.write("PDB file details log: PDB file %s not found\n" % self.pdbin)
         sys.stdout.write("\n")
         sys.exit()

      f=open(self.pdbin,"r")

      line=f.readline()
      while line:
         if "#MOLECULE" in line:
            self.molrep_mol_count=self.molrep_mol_count + 1
         if "REMARK" in line and "ENSEMBLE" in line:
            self.phaser_mol_count=self.phaser_mol_count + 1
         line=f.readline()

      f.close()

      if self.molrep_mol_count > 1:
         self.mol_count = self.molrep_mol_count
      if self.phaser_mol_count > 0:
         self.mol_count = self.phaser_mol_count

   def write_details(self, filename):
      """ Write out the PDB details. """

      self.logfile = filename

      o=open(self.logfile,"w")
      o.write("Number of molecules found: %d" % self.mol_count)
      o.close()

   def pdbcur(self, logfile, pdbin, pdbout=""):
      """ A function to run pdbcur to summarize the contents of the input PDB file. """
    
      # Reset the termination flag
      self.termination=False

      # Create the command line 
      if pdbout=="":
         command_line = self.pdbcurEXE + " XYZIN " + pdbin 
      else:
         command_line = self.pdbcurEXE + " XYZIN " + pdbin + " XYZOUT " + pdbout 

      # Launch pdbcur
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      # Write the keyword input
      child_stdin.write("SUMM\n")
      child_stdin.write("END\n")
      child_stdin.close()         
 
      # Open the log file for writing
      log=open(logfile, "w")

      # Watch the output for successful termination
      out=child_stdout.readline()
      log.write(out)

      if self.local_debug:
         sys.stdout.write("\n")
         sys.stdout.write("#################################################\n")
         sys.stdout.write("Processing PDBfile with PDBcur\n")
         sys.stdout.write("#################################################\n")
         sys.stdout.write("\n")
         sys.stdout.write(out)

      while out:
         if 'Normal termination' in out:
            self.termination=True
         out=child_stdout.readline()
         if self.local_debug:
            sys.stdout.write(out)
         log.write(out)

      child_stdout.close()
      log.close()

