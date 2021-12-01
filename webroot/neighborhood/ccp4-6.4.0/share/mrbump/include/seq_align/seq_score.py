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
# Scoring class for sequence alignments between a target and template sequence.
# Ronan Keegan 28/7/05

import string, sys, os

class align_score:

   def __init__(self):
      """ Initialisation. """

      self.name1=''
      self.name2=''
      self.sequence1=''
      self.sequence2=''

      self.target_seq=''
      self.templt_seq=''
      self.templt_align_seq=''

      self.total_target_len=0
      self.target_len=0

      self.no_conserved=0
      self.seqID=0.0

      self.no_of_gaps=0
      self.no_of_gap_chars=0
      self.gap_penalty=0.0

      self.align_len=0
      self.align_len_score=0.0

      self.score=0.0
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def get_seq(self, mstat, fasta_file, seq1="", seq2="", name1="", name2=""):
      """ Extract the sequences for the target and template structures from the input fasta
          file. """

      # If a HHpred sequence alignment exists it will be passed in and used as the default for scoring
      # Otherwise extract the alignment from the provided fasta file
      if seq1!="" and seq2!="":
         self.sequence1=seq1
         self.sequence2=seq2
         self.name1=name1
         self.name2=name2
      else:
         file=open(fasta_file, 'r')
   
         # Get the target sequence
         line=file.readline()
         self.name1=string.strip(line.replace('>',''))
         line=file.readline()
         while line:
            if '>' not in line:
               self.sequence1 = self.sequence1 + string.strip(line)
            else:
               break
            line=file.readline()
   
         # Get the template sequence
         self.name2=string.strip(line.replace('>',''))
         line=file.readline()
         while line:
            if '>' not in line:
               self.sequence2 = self.sequence2 + string.strip(line)
            else:
               break
            line=file.readline()
         file.close()
   
      # set the sequences to ""
      mstat.chain_list[self.name2].alignment.chainsaw_target_seq = ""
      mstat.chain_list[self.name2].alignment.chainsaw_template_seq = ""

      # Record the sequences with double "-" removed for chainsaw step
      for i in range(len(self.sequence1)):
         if self.sequence1[i] != "-" or self.sequence2[i] != "-":
            mstat.chain_list[self.name2].alignment.chainsaw_target_seq += self.sequence1[i]
            mstat.chain_list[self.name2].alignment.chainsaw_template_seq += self.sequence2[i]
       
   def prune_seq(self, out_file):
      """ Prune the target sequence to get rid of spaces. Throw away corresponding parts of
          the template sequence also. Write out the new sequences to a fasta file. """

      # Set the length of the inital target sequence, inclusive of gaps 

      self.total_target_len=len(self.sequence1)

      # Extract all '-' from the target sequence and remove corresponding elements in the template

      for i in range(self.total_target_len):
         if self.sequence1[i] != '-':
            self.target_seq = self.target_seq + self.sequence1[i]
            self.templt_seq = self.templt_seq + self.sequence2[i]

      # Set the length of the condensed target sequence  

      self.target_len=len(self.target_seq)

      # Ouput the new sequences to a file

      out_fasta=open(out_file,'w')

      out_fasta.write('>Target sequence\n') 
      out_fasta.write(self.target_seq + '\n')  
      out_fasta.write('>' + self.name2 + '\n') 
      out_fasta.write(self.templt_seq + '\n')  
      
      out_fasta.close()
         
   def process_gaps(self):
      """ Look for gaps in the template structure and record the total number of '-' occurances
          and the the total number of gaps. """
     
      count = 0
      gap_count = 0
      for i in range(self.align_len):

         # Count the total number of gap characters

         if self.templt_align_seq[i] == '-':
            count = count + 1
          
         # Count the total number of gaps

         if i == 0 and self.templt_align_seq[i] == '-':
            gap_count = gap_count + 1
         elif self.templt_align_seq[i] == '-' and self.templt_align_seq[i-1] != '-':
            gap_count = gap_count + 1 

      self.no_of_gaps = gap_count
      self.no_of_gap_chars = count

   def get_seqID(self):
      """ Calculate the sequence identity. Looks for residues that are identical in both the
          target and the template. """
      
      # Count the number of residues that match in both sequences

      count = 0
      for i in range(self.target_len):
         if self.target_seq[i] == self.templt_seq[i]:
            count = count + 1
     
      self.no_conserved = count

      # Sequence identity is this count divided by target sequence length
 
      if self.no_conserved != 0:
         self.seqID=float(self.no_conserved)/(float(self.align_len) - float(self.no_of_gap_chars))
      else:
         self.seqID = 0.0
      
   def get_align_length(self, method):
      """ Work out the alignment length. Two methods:
          1) 'end_to_end' - length from first aa to last aa in template sequence. 
          2) 'aa_correspond' - total number of aa's that have a corresponding aa
                               in the template sequence.""" 

      # end_to_end: find begining and end of aligned template sequence

      if method == 'end_to_end':
         
         # Count from the start of template seq until an aa is found
       
         count = 0 
         for i in range(self.target_len):
            if self.templt_seq[i] == '-':
               count = count + 1
            else:
               break
 
         # Make a note of the no. of '-'
          
         f_count = count
      
         # Count from the end of the template until an aa is found

         count = 0 
         for i in range(self.target_len):
            if self.templt_seq[-(i+1)] == '-':
               count = count + 1
            else:
               break

         # Make a note of the no. of '-'

         b_count = count
      
         # Subtract these two counts from the length of the target to get the alignment length

         #self.align_len = self.target_len - (f_count + b_count)

         # Below is the t_a=target length setup. For t_a=templt length use the Above.
         self.align_len = self.target_len
         b_count = 0
         f_count = 0
  
         # Make a note of the aligned sequence
    
         for i in range(self.target_len):
            if i >= f_count and i < (self.target_len - b_count):
               self.templt_align_seq = self.templt_align_seq + self.templt_seq[i]  

      # aa_correspond: look for aa's in target that have a corresponding aa in the template 

      elif method == 'aa_correspond':
         self.align_len = self.target_len - self.no_of_gap_chars 

      else:
         print "get_align_length() error: incorrect method name"
         print "Use 'end_to_end' or 'aa_correspond'"
         sys.exit(1)

   def template_score(self, chain, mstat, init):
      """ Generate a score for this template sequence based on the collected information. """

      # Collect sequence information

      CHAIN=mstat.chain_list[chain]

      # Skip if file not defined
      if not os.path.isfile(CHAIN.alignment.in_fasta_file):
        return
  
      if CHAIN.HHmatch and init.keywords.HHSCORE:
         self.get_seq(mstat, CHAIN.alignment.in_fasta_file, seq1=CHAIN.HHtargetSequence, seq2=CHAIN.HHalignment, \
                      name1="Target sequence", name2=CHAIN.chainName)
      else:
         self.get_seq(mstat, CHAIN.alignment.in_fasta_file)
      self.prune_seq(CHAIN.alignment.out_fasta_file)
      self.get_align_length('end_to_end')
      self.process_gaps()
      self.get_seqID()

      # P0 and P1 are the gap opening and continuation penalties respectively
 
      P0=2.0
      P1=0.5   

      no_of_gap_ext = self.no_of_gap_chars - self.no_of_gaps
      self.align_len_score = (self.align_len - (P0*self.no_of_gaps) - (P1*no_of_gap_ext))/float(CHAIN.alignment.raw_target_len)   

      self.score = self.seqID * self.align_len_score

      # set the alignment details. 

      CHAIN.alignment.seqID           = self.seqID
      CHAIN.alignment.no_conserved    = self.no_conserved

      CHAIN.alignment.no_of_gaps      = self.no_of_gaps
      CHAIN.alignment.no_of_gap_chars = self.no_of_gap_chars
      CHAIN.alignment.gap_penalty     = self.gap_penalty

      CHAIN.alignment.target_len      = self.target_len
      CHAIN.alignment.align_len       = self.align_len
      CHAIN.alignment.align_len_score = self.align_len_score
      CHAIN.alignment.align_seq       = self.templt_seq
      CHAIN.alignment.align_tar_seq   = self.target_seq

      CHAIN.alignment.score           = self.score

      mstat.chain_list[chain] = CHAIN

if  __name__ == '__main__':
  
   a=align_score()
   a.template_score('near_perf.fasta')
