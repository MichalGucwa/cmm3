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
# Extract a PDB sequence from the pdb_ATOMseqs DB 
# Ronan Keegan - 18/1/06
#

import os, sys
import string

class Chain_sequence:
   """ A class to find the sequence (PDB) of a given chain ID. The pdb_ATOMseqs.txt file
       containg the PDB sequences of all of the chains in PDB is required."""

   def __init__(self):
      self.pdbseqDB=''
      self.sequence=''
      self.file_position=0

   def setPDBseqDB(self, filename):
      self.pdbseqDB=filename

   def get_seq(self, chain_ID, start_position=0):
      """ Retrieve the sequence of the given chain ID from the DB. """

      # 'start_position' is  a variable to store the current position in the file after the 
      # search has been completed. This allows for iterative searching with a sorted 
      # list and avoids the need to re-read the entire file for each chain. The default
      # is the start of the file and the value should only be set if one is using an
      # alphabebically sorted list. 

      # Open the sequence DB file
      f=open(self.pdbseqDB, "r")
      f.seek(start_position)
      self.sequence = ''

      #Loop over the lines until we find the chain ID we are looking for
      line=f.readline()
      while line:
         if ">" in line:
            if (line[1:7].lower() == chain_ID.lower()) \
               or (line[1:6].lower() == chain_ID[0:5].lower() and line[6] == " " and chain_ID[5].lower() == "a"):
               self.file_position=f.tell()
               line=f.readline()
               while ">" not in line:
                  if line == "":
                     break
                  else:
                     self.sequence += string.strip(line)
                  line=f.readline()
               break
         line=f.readline()
      
      f.close()

# Example
if __name__ == "__main__":

   chain_ID = raw_input("Enter chain ID: ")
   print "Searching for sequence of chain %s" % chain_ID
   print ""

   chs=Chain_sequence()
   chs.setPDBseqDB("pdb_ATOMseqs.txt")

   chs.get_seq(chain_ID)
   
   if chs.sequence == "":
      print "Sequence not found"
   else:
      print chs.sequence
      
     
