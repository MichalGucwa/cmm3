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

import os, string, sys
import shutil


class Write_align_file:
  
   def __init__(self):

      self.output_fasta_file = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def setOutputFastaFile(self, file_name):
      self.output_fasta_file = file_name

   def write_one_file(self, target_info, mstat, chain):
      """ A function to write the target and template sequence to a fasta format file."""

      # Set the name of the output fasta file

      mstat.chain_list[chain].setRawAlignFile(mstat.chain_list[chain].working_DIR + '/alignments/target_' + chain + '_aln.fasta') 
      self.setOutputFastaFile(mstat.chain_list[chain].raw_align_file)

      # Open the output file and write the target and template sequences to it

      outfile = open(self.output_fasta_file,'w')

      outfile.write('>Target\n')
      outfile.write(target_info.sequence + '\n')
      outfile.write('>' + mstat.chain_list[chain].chainName + '\n')
      outfile.write(mstat.chain_list[chain].chain_sequence + '\n')
         
      outfile.close()

   def write_all_file(self, list, target_info, mstat):
      """ A function to write the target and all of the template sequences to a fasta format file."""
 
      # Set the Fasta alignment file - holds all of the sequences (target +templates) in fasta format.
      # To be used in multiple alignment.    
      self.setOutputFastaFile(mstat.all_raw_file)
 
      outfile = open(self.output_fasta_file, 'w')

      outfile.write('>Target\n')
      outfile.write(target_info.sequence + '\n')

      new_list=[]

      # Loop over the list of chains and add each sequence to the fasta file
      for chain in list:
      
         if mstat.chain_list[chain].seqlength > 0:
            # Write this alignment into the overall alignment file
            outfile.write('>' + mstat.chain_list[chain].chainName + '\n')
            outfile.write(mstat.chain_list[chain].chain_sequence + '\n')
	    new_list.append(chain)
         else:
            # Remove the directory for this chain and delete from the chain list
            if self.debug:
               sys.stdout.write("Removing chain %s from the list as it has sequence length = 0\n" % chain)
            else:
               shutil.rmtree(mstat.chain_list[chain].working_DIR)

            # Remove the chain from the list and decrease the number of hits by 1
            del mstat.chain_list[chain]
            mstat.no_of_hits = mstat.no_of_hits - 1

      list=new_list
         
      if self.debug:
         sys.stdout.write("\n")

      outfile.close()
        
      return list
