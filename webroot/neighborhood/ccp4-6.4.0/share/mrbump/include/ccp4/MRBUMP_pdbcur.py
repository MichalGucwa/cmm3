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
# MRBUMP wrapper for CCP4 program pdbcur 
# Ronan Keegan 19/8/05

import os, sys, string
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CCP4_SCR'):
    raise RuntimeError, 'CCP4_SCR not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class PDBcur:
   """ A class to call pdbcur. """
 
   def __init__(self):
      if os.name == "nt":
         self.pdbcurEXE = os.path.join(os.environ['CBIN'], 'pdbcur.exe')
      else:
         self.pdbcurEXE = os.path.join(os.environ['CBIN'], 'pdbcur')
      self.keyword = '\n'
      self.termination = False 
      self.SGE = False 
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
 
   def pdbcur(self, xyzin, xyzout):
      """ A function to run pdbcur. """
 
      # Test for Sun Grid Engine
      #if os.environ.has_key('SGE_ROOT'):
      #   self.SGE = True
      #   print "SGE detected. Submitting job to queue."
 
      # Get the location of the CCP4 scratch directory and the current working directory
      CCP4_SCR = os.environ["CCP4_SCR"]
      PWD = os.getcwd()

      # Set the logfile for standard out
      pdb_name = os.path.splitext(os.path.split(xyzin)[-1])[0]
      self.setLOGFILE(os.path.join(CCP4_SCR, "pdbcur_" + pdb_name + ".log"))

      # Close the keyword input
      self.setKEYWORD("END")

      # Set the command line
      command_line = self.pdbcurEXE + " xyzin " + xyzin + " xyzout " + xyzout 

      # Launch pdbcur
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
         if "PDBCUR:  Normal termination" in line:
            self.termination = True 
         line=stdout.readline()
      
      log.close()
      stdout.close()   
    
      # If the job failed report an error
      if self.termination == False:
         print "pdbcur failed with input PDB: %s" % xyzin 
         print "log file: %s" % self.logfile
         self.error_code = 1
 
      return self.error_code
      

if __name__ == '__main__':
   p=PDBcur()
   p.setKEYWORD("cutocc")
   p.setKEYWORD("mostprob")
   p.setKEYWORD("delh")
   p.pdbcur("1s28.pdb", "temp.pdb")

      
      
