#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2007 Ronan Keegan, Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
#
# Wrapper for Probcons the multiple alignment program 
# Ronan Keegan 10/9/05

import os, sys, string
import subprocess
import shlex


class Probcons:
   """ A class to call Probcons, the sequence multiple alignment program, to do 
       alignmnet of target and template sequences."""
 
   def __init__(self):

      self.probcons_EXE = 'probcons'

      self.input_fasta_file = ''
      self.output_fasta_file = ''
      self.log_file = 'probcons.log'
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
    
      self.local_debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def setInputFastaFile(self, file_name):
      self.input_fasta_file = file_name

   def setOutputFastaFile(self, file_name):
      self.output_fasta_file = file_name

   def setLogFile(self, file_name):
      self.log_file = file_name

   def Probcons(self, input_fasta_file, output_fasta_file):
      """ A function to do a system call to Probcons."""

      self.setInputFastaFile(input_fasta_file)
      self.setOutputFastaFile(output_fasta_file)

      # Set the command line
      command_line = self.probcons_EXE + ' -ir 100 ' + self.input_fasta_file
         
      if self.debug:
         sys.stdout.write("\n")
         sys.stdout.write("======================\n")
         sys.stdout.write("Probcons command line:\n")
         sys.stdout.write("======================\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch probcons
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
      log=open(self.output_fasta_file, "w")
      line=child_stdout.readline()
      while line:
         log.write(line)
         if self.debug:
            sys.stdout.write(line)
         line=child_stdout.readline()
      child_stdout.close()
      log.close()
        
   def get_raw_target_len(self):
      """ A function to get the length of the target sequence before it is processed by the alignment program. """

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
   
   def convert_to_pir(self, align_file):
      """ Convert a fasta formated alignment file to PIR format (for Chainsaw). """
    
      # Setup temporary variables

      target_name = ''
      target_seq = ''
      templt_name = ''
      templt_seq = ''

      # Open the fasta file to read the target & template details

      in_file=open(align_file,'r')
      
      line = in_file.readline()
      target_name = string.strip(line).replace('>','')
      line = in_file.readline()
      while line:
         if '>' not in line:
            target_seq = target_seq + string.strip(line)
         else:
            break
         line = in_file.readline() 
 
      templt_name = string.strip(line).replace('>','')
      line = in_file.readline() 
      while line:
         templt_seq = templt_seq + string.strip(line)
         line = in_file.readline() 
         
      in_file.close()

      # Re-open the file and write the details in PIR format

      out_file=open(align_file, 'w')
       
      out_file.write(">P1;" + target_name + "\n")
      out_file.write("\n")
      out_file.write(target_seq + "\n")
      out_file.write("*\n")
      out_file.write(">P1;" + templt_name + "\n")
      out_file.write("\n")
      out_file.write(templt_seq + "\n")
      out_file.write("*\n")

      out_file.close()

         
           
if __name__ == '__main__':

   probcons=Probcons()
   probcons.Probcons('1vrd_all.fasta', 'out_1vrd.fasta')
