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
# Wrapper for clustalw the sequence multiple alignment program
# Ronan Keegan 13/9/05

import os, sys, string
import Scan_path
import subprocess
import shlex


class Clustalw:
   """ A class to call clustalw to do a multiple alignment of the target and template sequences. """
 
   def __init__(self):

      chk=Scan_path.Check_PATH()
      if os.path.isfile(os.path.join(os.environ['CCP4'], 'libexec', 'clustalw2')):
         self.clustalw_EXE=os.path.join(os.environ['CCP4'], 'libexec', 'clustalw2')
      else:
         if chk.find_exec("clustalw2"):
            self.clustalw_EXE=os.path.join(chk.exe_directory, "clustalw2")
         elif chk.find_exec("clustalw"):
            self.clustalw_EXE=os.path.join(chk.exe_directory, "clustalw")
         else:
            sys.stdout.write("Clustalw Error: clustalw and clustalw2 executables not found on system.\n")
            sys.stdout.write("\n")
            sys.exit()

      self.input_fasta_file = ''
      self.output_pir_file = ''
      self.log_file = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def setInputFastaFile(self, file_name):
      self.input_fasta_file = file_name

   def setOutputPIRFile(self, file_name):
      self.output_pir_file = file_name

   def setLogFile(self, file_name):
      self.log_file = file_name

   def Clustalw(self, input_fasta_file, output_pir_file, logfile):
      """ A function to do a system call to Clustalw."""

      self.setInputFastaFile(input_fasta_file)
      self.setOutputPIRFile(output_pir_file)
      self.setLogFile(logfile)

      # Set the command line
      command_line = self.clustalw_EXE + ' -align -outorder=input -output=pir -infile=' + self.input_fasta_file + \
                ' -outfile=' + self.output_pir_file
         
      if self.debug:
         sys.stdout.write("\n")
         sys.stdout.write("======================\n")
         sys.stdout.write("Clustalw command line:\n")
         sys.stdout.write("======================\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch clustalw
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.close()         

      # Capture any error from the alignment job and print it to screen if debug mode is on
      log=open(self.log_file, "w")
      line=child_stdout.readline()
      while line:
         if self.debug:
            log.write(line)
         line=child_stdout.readline()
      child_stdout.close()
      log.close()
      
   def convert_to_fasta(self):
  
      infile=open(self.output_pir_file,'r')
      
      line=infile.readline()
      while line: 
         print line

         line=infile.readline()
   
   def get_raw_target_len(self):
      ''' A function to get the length of the target sequence before it is processed by the alignment program. '''

      seq = ''
 
      file = open(self.input_fasta_file, 'r')

      line = file.readline()
      name=string.strip(line).replace('>','') 
      line = file.readline()
      while line:
         if '>' in line:
            break
         else:
           seq = seq + string.strip(line)
         line = file.readline()
    
      return len(seq)
         
  
if __name__ == '__main__':

   clustalw=Clustalw_multiple()
   clustalw.Clustalw('input/1vrd_all.fasta', 'out_1vrd.pir', 'clustalw.log')
   clustalw.convert_to_fasta()



