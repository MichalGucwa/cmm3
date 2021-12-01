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
# MRBUMP wrapper for CCP4 program PDBSET
# Ronan Keegan 19/8/05

import os, sys, string
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CCP4_SCR'):
    raise RuntimeError, 'CCP4_SCR not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class PDBset:
   """ A class to call pdbset. """
 
   def __init__(self):
      if os.name == "nt":
         self.pdbsetEXE = os.path.join(os.environ['CBIN'], 'pdbset.exe')
      else:
         self.pdbsetEXE = os.path.join(os.environ['CBIN'], 'pdbset')
      self.keyword = '\n'
      self.termination = False 
      self.logfile = ''
      self.error_code = 0
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def setDEBUG(self, flag):
      self.debug=flag 

   def setKEYWORD(self, param):
      self.keyword = self.keyword + param + '\n' 
 
   def setLOGFILE(self, filename):
      self.logfile = filename 
 
   def pdbset(self, xyzin, xyzout):
      """ A function to run pdbset. """

      # Get the location of the CCP4 scratch directory
      CCP4_SCR = os.environ["CCP4_SCR"]

      # Set the logfile for standard out
      pdb_name = os.path.splitext(os.path.split(xyzin)[-1])[0]
      self.setLOGFILE(os.path.join(CCP4_SCR, "pdbcur_" + pdb_name + ".log"))

      # Close the keyword input
      self.setKEYWORD("END")

      # Set the command line
      command_line = self.pdbsetEXE + " xyzin " + xyzin + " xyzout " + xyzout

      # Launch pdbset
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (stdout, stdin) = (p.stdout, p.stdin)

      # Enter the keywords
      stdin.write(self.keyword)
      stdin.close()
 
      log=open(self.logfile, 'w')

      # Check the stdout for successful completion
      line=stdout.readline()
      while line:
         log.write(line)
         if "Normal completion PDBSET" in line:
            self.termination = True 
         line=stdout.readline()
      
      log.close()
      stdout.close()   
    
      # If the job failed report an error
      if self.termination == False:
         print "pdbset failed with input PDB: %s" % xyzin 
         print "log file: %s" % self.logfile
         self.error_code = 1

      return self.error_code
      

if __name__ == '__main__':
   p=PDBset()
   p.setKEYWORD("EXCLUDE HOH")
   p.setKEYWORD("SEQUENCE SINGLE")
   p.pdbset("1s28.pdb", "temp.pdb")

      
      
