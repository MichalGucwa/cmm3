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
# Multiple Alignment of all sequences with the target and score derivation.
# Ronan Keegan 31/7/05

import os, string, sys

import MRBUMP_MAFFT
import MRBUMP_PROBCONS
import MRBUMP_CLUSTALW
import MRBUMP_T_COFFEE
import separate
import seq_score

class Score:

   def __init__(self):
      self.logfile = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def setLogFile(self, logfile):
      self.logfile = logfile

   def score(self, list, init, mstat, input_file, output_file, MA_method):
      """ A function to score the multiple alignment by MAFFT/Clustalw/Probcons/TCoffee of all of the sequences. """

      # Set the log file.
      self.setLogFile(os.path.join(init.search_dir, 'logs', 'seq_align.log'))

      # Call Multiple alignment program to do the multiple alignment
      if MA_method == 'mafft':
         ma=MRBUMP_MAFFT.Mafft()
         ma.Mafft(input_file, output_file, os.path.join(init.search_dir, "logs", "mafft.log"))
         raw_len=ma.get_raw_target_len()

      if MA_method == 'probcons':
         pc=MRBUMP_PROBCONS.Probcons()
         pc.setLogFile(os.path.join(init.search_dir, 'logs', 'probcons.log'))
         pc.Probcons(input_file, output_file)
         raw_len=pc.get_raw_target_len()

      if MA_method == 'clustalw':
         cl=MRBUMP_CLUSTALW.Clustalw()
         cl.Clustalw(input_file, output_file, os.path.join(init.search_dir, "logs", "clustalw.log"))
         raw_len=cl.get_raw_target_len()

      if MA_method == 't_coffee':
         tl=MRBUMP_T_COFFEE.T_coffee()
         tl.setLogFile(os.path.join(init.search_dir, 'logs', 't_coffee.log'))
         tl.T_coffee(input_file, output_file)
         raw_len=tl.get_raw_target_len()

      # Seperate the resulting alignment file into separate alignments (target + template)
      s=separate.sep_fasta()
      s.sep(mstat, output_file, raw_len)
      s.write_align_files(list, mstat)

      # Calculate the alignment scores for each set of alignments
      for chain in mstat.chain_list.keys():
         a=seq_score.align_score()
         a.template_score(chain, mstat, init)

      # Write the results to a log file
      sorted=[]

      for chain in mstat.chain_list.keys():
          sorted.append(chain)

      sorted.sort()

      log=open(self.logfile, 'w')

      log.write("----------------------------\n")
      log.write("Results using: " + MA_method + "\n")
      log.write("----------------------------\n")

      log.write("NAME \t\t SCORE \t\t SEQID \t\t A_Q \t\t N_ta \t N_t \t N_g0 \t N_gc \t N_c \t Type \n")
      log.write("--------------------------------------------------------------------------------------------------------------\n")

      for chain in sorted:
         log.write("%s \t\t %.3f \t\t %.3f \t\t %.3f \t\t %d \t %d \t %d \t %d \t %d \t %s\n" % (chain, \
           mstat.chain_list[chain].alignment.score, \
           mstat.chain_list[chain].alignment.seqID, \
           mstat.chain_list[chain].alignment.align_len_score, \
           mstat.chain_list[chain].alignment.align_len, \
           mstat.chain_list[chain].alignment.target_len, \
           mstat.chain_list[chain].alignment.no_of_gaps, \
           mstat.chain_list[chain].alignment.no_of_gap_chars, \
           mstat.chain_list[chain].alignment.no_conserved, \
           mstat.chain_list[chain].source))

      log.close()
