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
# A python script to calculate the MW of a sequence
# Ronan Keegan - 24/7/07

import os
import string
import sys
import PDB_info

class MolWeight:
   """ A class to run the Matthews coefficient program. """

   def __init__(self):
      self.mol_weight=0.0
      self.nmol=0
      self.nres=0

      self.AAweights = {"A" : 89.09, "B" :  132.61, "C" :  121.15, "D" :  133.10, "E" :  147.13, "F" :  165.19,
                        "G" :  75.07, "H" :  155.16, "I" :  131.17, "K" :  146.19, "L" :  131.17, "M" :  149.21, 
                        "N" : 132.12, "P" :  115.13, "Q" :  146.15, "R" :  174.20, "S" :  105.09, "T" :  119.12,
                        "V" :  117.15, "W" :  204.23, "Y" :  181.19, "X" :  128.16, "*" :  0.0, "Z" :  146.64, " " : 0.0}

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def get_seqMW(self, sequence="*"):
      """ Calculate the molecular weight of a give sequence. """
   
      # Get the number of residues in the sequence
      self.nres=len(sequence.replace("*", "").replace(" ", ""))

      # Set the molecular weight of waters (Daltons) 
      water_molecular_weight = 18.015

      # Molecular weight calculation
      mw=0.0
      for i in sequence:
         mw=mw+self.AAweights[i.upper()]
         
      mw = mw - ((self.nres-1)*water_molecular_weight)

      self.mol_weight=mw

      return mw

   def get_pdbMW(self, pdbfile, chain=""):
      """ Get the molecular weight of a chain or all chains from a PDB file. """
      
      # Call the PDB_info function to get the sequence from the PDB file
      pdb_info=PDB_info.PDB_info()
    
      # Extract the sequence for a single chain or all chains
      pdb_info.getSequence(pdbfile, chain=chain)

      if self.debug:
         print "Sequence from PDB file:"
         print pdb_info.ATOMsequence
         print ""
 
      self.get_seqMW(pdb_info.ATOMsequence)
  
      return self.mol_weight

if __name__ == "__main__":
   """ An example run for a homo dimer. One fixed and one the search for. """
 
   fixed_sequence=\
      "nliqfgnmiq cankgsrpsl dyadygcycg wggsgtpvdel drccqvhdnc yeqagkkgcf" + \
      "pkltlyswkc tgnvptcnsk pgcksfvcac daaaakcfaka pykkenynid tkkrck"

   input_sequence=\
      "nliqfgnmiq cankgsrpsl dyadygcycg wggsgtpvdel drccqvhdnc yeqagkkgcf" + \
      "pkltlyswkc tgnvptcnsk pgcksfvcac daaaakcfaka pykkenynid tkkrck"

   # Instantiate the class
   mc=MolWeight()

   mc.get_pdbMW("test.pdb", chain="A")
   print "Molecular Weight of A chain from file:", mc.mol_weight

   mc.get_pdbMW("test.pdb")
   print "Molecular Weight of all chains in file:", mc.mol_weight

   mol_weight=mc.get_seqMW(input_sequence)
   mol_weight=mc.get_seqMW(input_sequence) + mc.get_seqMW(fixed_sequence)
