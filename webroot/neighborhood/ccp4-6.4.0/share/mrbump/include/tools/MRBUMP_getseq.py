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
# Extract a sequence from the pdb_seq records
# Requires that you have the pdb_ATOMseqs file containing all PDB sequences. Available at:
# http://msdlocal.ebi.ac.uk/docs/rcsb/pdb/derived_data/pdb_ATOMseqs.txt
# Ronan Keegan 20.10.05

import string, os, sys

class PDB_sequence:
   """ A class to handle the retrieval of PDB sequences for each of the matching PDB's."""

   def __init__(self):
      self.temp_list=[]
      self.no_read=False
      self.seq_dict=dict([])
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def get_sequences(self, pdbid_list, pdb_seq_file):
      """ A function to get the sequences of the PDB's from the pdb_ATOMseqs.txt file. 
          Input: 1) List of PDB ids (including chain ids),
                 2) path to pdb_ATOMseqs.txt file"""

      # Open the pdb_ATOMseqs.txt file
      o=open(pdb_seq_file, 'r')
      
      # Loop over the file
      line=o.readline()
      while line:

         # Loop over all of the PDB ids in the input list and extract the sequence if found
         for i in pdbid_list:
            pdbid = i + " "

            if pdbid in line[0:8]:
               self.temp_list.append(i)
               line=o.readline()

               # Read the sequence from the pdb_ATOMseqs file
               sequence=""
               while ">" not in line:
                  sequence =  sequence + string.strip(line)
                  line=o.readline()
                  if line == "":
                     break
                  if ">" in line:
                     self.no_read = True

               # Add this chain and its sequence to the seq_dict
               # Assign the chain value to 'A' if no chain is specified
               if i[-1] == "_":
                  fixed_pdb_id = i + "A"
               else:
                  fixed_pdb_id = i
               self.seq_dict[fixed_pdb_id]=sequence

         # Don't read a new line if we have just come out of a sequence extraction
         if self.no_read == True:
            self.no_read = False
         else:
            line=o.readline()
      
      o.close()
      
      for i in pdbid_list:
         if i not in self.temp_list:
            print "Get sequence log: could not find sequence for %s in pdb_ATOMseqs.txt" % i



if __name__ == '__main__':

   pdb_list=["1nio_A", "1ahc_", "1ahb_", "1aha_", "1mom_", "1mrh_", "1f8q_A", "1mri_", "1mrg_", "1bry_Y", "1bry_Z", "1mrj_", "1mrk_", "1qd2_A", "1tcs_", "1j4g_C", "1j4g_B", "1j4g_A", "1j4g_D", "1gis_A", "1giu_A", "1nli_A", "1cf5_B", "1cf5_A", "1d8v_A", "1hwn_A", "1hwm_A", "1hwp_A", "1hwo_A", "1uq4_A", "1ifs_", "1ifu_", "1ift_", "2aai_A", "1il4_A", "1apg_A", "1br5_A", "1il9_A", "1fmp_", "1smw_A"]

   pdb_seq_file="pdb_ATOMseqs.txt"

   s=PDB_sequence()
   s.get_sequences(pdb_list, pdb_seq_file)

   for i in s.seq_dict.keys():
      print i 
      print s.seq_dict[i]
