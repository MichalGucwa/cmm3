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
# Program to calculate the number of molecules in the a.s.u. based on the 
# cell dimensions, resolution, and space group of the target structure. Derived
# from the method outlined by Kantardjieff and Rupp (2000).
#
# Ronan Keegan 21/6/05
# 

import os

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'

import sys
import string
import time 
import subprocess
import shlex
import Fasta_parse
import MTZ_parse

class Nmol_calc(Fasta_parse.Fasta_parse, MTZ_parse.MTZ_parse):
   """ A class to calculate the number of molecules in the a.s.u."""

   def __init__(self):
      MTZ_parse.MTZ_parse.__init__(self)
      Fasta_parse.Fasta_parse.__init__(self)

      if os.name=="nt":
         self.matthewsEXE=os.path.join(os.environ["CCP4"], "bin", "matthews_coef.exe")
      else:
         self.matthewsEXE=os.path.join(os.environ["CCP4"], "bin", "matthews_coef")

      self.nmol=1
      self.score=0.0
      self.Vm_init=0.0
      self.nmol_max=10

      self.nmol_estimate = 0
      self.Vm_estimate = 0.0
      self.solvent_estimate = 0.0
      self.score_tot = 0.0

      self.matt_coef_list=dict([])
      self.solvent_list=dict([])
      self.deviation=dict([])
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
  
   def setDEBUG(self, flag):
      self.debug=flag 

   def set_VM_init(self, resolution):
      """ A function to work out the most likely value for Vm given the resolution. """

      # Set-up a best guess for the value of Vm based on the resolution of the data.  

      if resolution < 0.54:
         print "Resolution too high. Try again."
         sys.exit(1)
      elif resolution >= 0.54 and resolution < 1.21:
         self.Vm_init=2.15
      elif resolution >= 1.21 and resolution < 1.51:
         self.Vm_init=2.3
      elif resolution >= 1.51 and resolution < 1.81:
         self.Vm_init=2.45
      elif resolution >= 1.81 and resolution < 2.01:
         self.Vm_init=2.6
      elif resolution >= 2.01 and resolution < 2.41:
         self.Vm_init=2.7
      elif resolution >= 2.41 and resolution < 2.81:
         self.Vm_init=2.95
      else:
         print "Resolution too low for this method."
         sys.exit(1)

   def calculate_nmol(self, molecular_weight, MTZIN, SEQIN, LOGFILE, multiple=False):
      """ A function to calculate the number of molecules in the a.s.u. Take in 
          resolution, cell parameters, symmetry group and molecular weight as 
          arguements. Calls matthews_coef. """ 

      # Parse sequence file and mtz file.

      self.parseSeqFile(SEQIN)
      self.calc_MW()
      self.run_mtzdmp(MTZIN)

      # Work out the initial estimate for Vm.

      # self.set_VM_init(self.resolution)
       
      # Start a sub-process to run matthes_coef. We do this several times to test for the best possible
      # answer. Change nmol_max to vary the number of tests.

      # Compose the keywords for matthews_coef
      key  = 'CELL %.3f %.3f %.3f %.3f %.3f %.3f\n' % (self.cell_dimensions['a'], self.cell_dimensions['b'], \
         self.cell_dimensions['c'], self.cell_dimensions['alpha'], self.cell_dimensions['beta'], self.cell_dimensions['gamma'],)
      key += 'SYMM %s\n' % self.space_group
      key += 'MOLW %.3f\n' % molecular_weight
      key += 'RESO %.3f\n' % self.resolution
      key += 'AUTO\n'
      key += 'END\n'

      # Write out the keyfile if running in debug mode
      if self.debug:
         logs_path=os.path.split(LOGFILE)   
         if len(logs_path) > 1:
            logs_dir=logs_path[0]
         else:
            logs_dir=os.getcwd()
         keyfile=open(os.path.join(logs_dir, "matt_coef_input.key"), "w")
         keyfile.write(key)
         keyfile.close()

      # Set the command line
      command_line = self.matthewsEXE
         
      # Launch MatthewsCoef
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.write(key)
      child_stdin.close()         

      # Watch the output for successful termination
      out=child_stdout.readline()
      logfile=open(LOGFILE, "w")
      
      top_score = 0.0
      line = child_stdout.readline()
      while line:
         logfile.write(line)
         if "Matthews Coeff  %solvent" in line:
            line = child_stdout.readline()
            logfile.write(line)
            line = child_stdout.readline()
            logfile.write(line)
            while line:

               if "__________________" in line:
                  break

               results = string.split(line)
               # Set the results from Matthews Coef
               if float(results[4]) > top_score:
                  top_score = float(results[4])
                  self.nmol_estimate = int(results[0])
                  self.Vm_estimate = float(results[1])
                  self.solvent_estimate = float(results[2])
                  score_reso = float(results[3])
                  self.score_tot = float(results[4])

               line = child_stdout.readline()
               logfile.write(line)

         line = child_stdout.readline()
        
      child_stdout.close()
      logfile.close()

      time.sleep(2)

      # Check the results are ok
      if self.nmol_estimate == 0 and multiple == False:
         sys.stdout.write("Matthews_Coef error: There was a problem getting the number of molecules in the asu\n")
         sys.stdout.write("                     Check the matthews coefficent log file in the logs directory\n")
         sys.stdout.write("\n")
         sys.stdout.write("                     %s\n" % LOGFILE)
         sys.stdout.write("\n")
         sys.stdout.write("                     Are you sure that you have the correct MTZ and sequence files?\n")
         sys.exit(1)
      elif multiple == False:
         sys.stdout.write("Matthews_Coef message: Estimated number of molecules using target molecular weight: %i\n" % self.nmol_estimate) 
         sys.stdout.write("Matthews_Coef message: Score for this number of molecules: %.3f\n" % self.score_tot)
         sys.stdout.write("Matthews_Coef message: Actual Vm: %.3f and Solvent content: %.3f %%\n" % (self.Vm_estimate, self.solvent_estimate))


if __name__ == '__main__':

      if len(sys.argv) != 3:
         print "Usage: <mtz file> <sequence file (fasta format)> <matt coef logfile name>"
         sys.exit(1)     
      else:
         MTZIN = sys.argv[1]
         SEQIN = sys.argv[2]
         LOGFILE = sys.argv[3]
 
      nmol = Nmol_calc()
      NMOL = nmol.calculate_nmol(MTZIN, SEQIN, LOGFILE)
         
