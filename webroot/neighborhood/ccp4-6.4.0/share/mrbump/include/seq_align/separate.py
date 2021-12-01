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
# Seperate the multiple alignment output alignment file into target + template alignment files
# Ronan Keegan 10.8.05 

import os, string
import sys


class sep_fasta:
   """ A class to read a multiple alignment output alignment file and split it into target+template files. """
  
   def __init__(self):
      """ Initialisation. """

      self.target_name = ''
      self.target_seq = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def setDEBUG(self, flag):
      self.debug=flag  

   def sep(self, mstat, input_aln_file, raw_target_len):
      """ A function to separate the multiple alignment fasta file and record the details. """

      file=open(input_aln_file, 'r')

      # Get the target sequence
      line=file.readline()
      self.target_name=string.strip(line.replace('>','').replace('P1;',''))
      line=file.readline()
      while line:
         if '>' not in line:
            if '*' not in line:
               self.target_seq = self.target_seq + string.strip(line)
         else:
            break
         line=file.readline()
     
      # Get the template sequences
      name=string.strip(line.replace('>','').replace('P1;',''))
      sequence=''
      while line:
         if '>' in line:

            if mstat.chain_list.has_key(name):
               mstat.chain_list[name].alignment.name = name
               mstat.chain_list[name].alignment.aligned_seq=sequence
               mstat.chain_list[name].alignment.raw_target_len=raw_target_len

               mstat.chain_list[name].alignment.in_fasta_file=mstat.chain_list[name].working_DIR + \
                  '/alignments/' + name + '_temp_aln.fasta'
               mstat.chain_list[name].alignment.out_fasta_file=mstat.chain_list[name].working_DIR + \
                  '/alignments/' + name + '_aln.fasta'

            name=string.strip(line.replace('>','').replace('P1;',''))
            sequence=''

         if '>' not in line:
            if '*' not in line:
               sequence = sequence + string.strip(line)
      
         line=file.readline()
      
      if mstat.chain_list.has_key(name):
         mstat.chain_list[name].alignment.name = name
         mstat.chain_list[name].alignment.aligned_seq=sequence
         mstat.chain_list[name].alignment.raw_target_len=raw_target_len

         mstat.chain_list[name].alignment.in_fasta_file=mstat.chain_list[name].working_DIR + \
            '/alignments/' + name + '_temp_aln.fasta'
         mstat.chain_list[name].alignment.out_fasta_file=mstat.chain_list[name].working_DIR + \
            '/alignments/' + name + '_aln.fasta'

   def write_align_files(self, list, mstat):
      """ A function to write out the individual alignment files. """

      for chain in list:

         # Skip if not defined
         if mstat.chain_list[chain].alignment.in_fasta_file=='':
           sys.stdout.write("A FASTA file was not set for chain: "+chain+"\n")
           continue

         # Write the alignment file in fasta format first
         outfile=open(mstat.chain_list[chain].alignment.in_fasta_file, 'w')

         outfile.write('>Target sequence\n')
         outfile.write(self.target_seq + '\n')
         outfile.write('>' + chain + '\n')
         outfile.write(mstat.chain_list[chain].alignment.aligned_seq + '\n')

         outfile.close()

         # Also write it in PIR format
         mstat.chain_list[chain].pir_aln_file=os.path.join(mstat.chain_list[chain].working_DIR, "alignments", chain + "_aln.pir")
         pir_aln_file=open(mstat.chain_list[chain].pir_aln_file, "w")
         pir_aln_file.write(">P1;Target\n")
         pir_aln_file.write("\n")
         pir_aln_file.write(self.target_seq + "\n")
         pir_aln_file.write("*\n")
         pir_aln_file.write(">P1;" + chain + "\n")
         pir_aln_file.write("\n")
         pir_aln_file.write(mstat.chain_list[chain].alignment.aligned_seq + "\n")
         pir_aln_file.write("*\n")
         pir_aln_file.close()

  
if __name__ ==  '__main__':
   
   s=sep_fasta()
   s.sep('out.fasta') 

   s.write_align_files()
