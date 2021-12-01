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
# A wrapper to Tcoffee, the multiple alignment program
# Ronan Keegan 13/9/05

import os, sys, string


class T_coffee:
   """ A class to run the multiple sequence alignment program T_coffee to 
       generate the alignment for MrBUMP scoring. Takes in the names of the 
       input sequence list file and the output list file (.fasta format)."""  
 
   def __init__(self):
      self.t_coffee_EXE = 't_coffee'

      self.input_fasta_file = ''
      self.output_fasta_file = ''
      self.log_file = 't_coffee.log'
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

   def T_coffee(self, input_fasta_file, output_fasta_file):
      """ Function to run T_coffee to generate the multiple alignment. """

      # Set the names of the input and output sequence files
      self.setInputFastaFile(input_fasta_file)
      self.setOutputFastaFile(output_fasta_file)

      # Report the command line for running t_coffee
      print "##########################################################"
      print "      Using T_coffee to do the sequence alignment"
      print "##########################################################"
      print ""

      if self.debug:
         print "Input fasta file: %s" % self.input_fasta_file
         print "Output fasta file: %s" % self.output_fasta_file
         print "T_coffee log file: %s" % self.log_file
         print ""
         print "======================"
         print "Tcoffee command line:"
         print "======================"
         print self.t_coffee_EXE + ' -outorder=input -output=fasta -infile=' + self.input_fasta_file + \
             ' -outfile=' + self.output_fasta_file
         print ""

      # Open up a pipe to the job capturing the stdout and the stderr
      i,o=os.popen4(self.t_coffee_EXE + ' -outorder=input -output=fasta -infile=' + self.input_fasta_file + \
             ' -outfile=' + self.output_fasta_file, "r")
      i.close()

      # Open the log file for writing
      log=open(self.log_file,"w")

      # Write out the lines
      line=o.readline()
      while line:
         log.write(line)
         if self.local_debug:
            sys.stdout.write(line)

         line=o.readline()

      o.close()
      log.close()
      
   def get_raw_target_len(self):
      """ A function to get the length of the target sequence 
          before it is processed by the alignment program. """

      seq=""
 
      file = open(self.input_fasta_file, 'r')

      # Read the header
      line = file.readline()
      name=string.strip(line).replace('>','') 

      # Read the sequence from the file
      line = file.readline()
      while line:
         if '>' in line:
            break
         else:
           seq = seq + string.strip(line)
         line = file.readline()
    
      return len(seq)
         
  
if __name__ == '__main__':

   t_coffee=T_coffee()
   t_coffee.T_coffee('input/1vrd_all.fasta', 'out_1vrd.fasta')



