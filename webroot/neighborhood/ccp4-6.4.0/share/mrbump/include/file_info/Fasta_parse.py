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

import string
import os
import sys
import time


class Fasta_parse:
   """ Calculate the molecular weight of a structure given its sequence. """

   def __init__(self):
     self.seqfile = ''
     self.seqfilename = ''
     self.seq_header = ''
     self.sequence = ''

     self.no_of_res = 0
     self.mol_weight = 0.0

     self.AminoAcids = ["A","B","C","D","E","F","G","H","I","K","L","M","N","P","Q","R","S","T","V","W","Y","X","*","Z"]
     self.AminoAcidWeights = [89.09, 132.61, 121.15, 133.10, 147.13, 165.19, 75.07, 155.16, 131.17, 146.19, 131.17, 149.21, 
                              132.12, 115.13, 146.15, 174.20, 105.09, 119.12, 117.15, 204.23, 181.19, 128.16, 0.0, 146.64]
     try:
        self.debug=eval(os.environ['MRBUMP_DEBUG'])
     except:
        self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def setSequenceFile(self, seq_file):
     self.seqfile = seq_file

   def setSequenceHeader(self, seq_header):
     self.seq_header = seq_header

   def setSequence(self, sequence):
     self.sequence = sequence

   def setNumberRes(self, no_of_res):
     self.no_of_res = no_of_res

   def setMolecularWeight(self, mol_weight):
     self.mol_weight = mol_weight


   def parseSeqFile(self, seq_file_path):
     """ Extract the amino-acid sequence form the sequence file and make a note of its length.
         Handles PIR, Fasta and non formatted sequence files. """

     sequence = ''

     self.setSequenceFile(string.split(seq_file_path,'/')[-1])

     sf = open(seq_file_path, 'r')

     line = sf.readline()

     # Catch for blank lines at the start of the file
     while string.strip(line)=="":
        line = sf.readline()

     # Parse for PIR format
     if '>P1' in line or '>p1' in line:
        self.setSequenceHeader(string.strip(line))
        line = sf.readline()
        line = sf.readline()

     # Parse for fasta format
     elif '>' in line:
        self.setSequenceHeader(string.strip(line))
        line = sf.readline()

     while line:
        sequence += ((string.strip(line).replace(" ","")).replace("*","")).upper()
        line = sf.readline()
     sf.close()
     
     self.setSequence(sequence)
     self.setNumberRes(len(self.sequence))

   def calc_MW(self):
      """ Calculate the molecular weight of the protein from the sequence. """

      index = 0
      total = 0
      water_molecular_weight = 18.015

      for AA_id in self.AminoAcids:
        no_of_occurs = string.count(self.sequence, AA_id)
        weight_for_this = no_of_occurs * self.AminoAcidWeights[index]
        total = total + weight_for_this
        index = index + 1
      self.setMolecularWeight(total - ((self.no_of_res-1)*water_molecular_weight))

   def print_summary(self):
      """ Print a summary of the results."""

      print "\n"
      print "Results for sequence file: %s \n" % self.seqfile
      print "Header: %s " % self.seq_header
      print "Sequence: %s " % self.sequence
      print "Number of Residues: %d " % self.no_of_res
      print "Molecular Weight: %.3f " % self.mol_weight
      print "\n"

if __name__ == '__main__':

   fp=Fasta_parse()
   fp.parseSeqFile('/users/rmk65/parallel_mr/python/dev/nmol_calc/data/eg_mar.seq')
   fp.calc_MW()
#   fp.print_summary()

   print fp.no_of_res

