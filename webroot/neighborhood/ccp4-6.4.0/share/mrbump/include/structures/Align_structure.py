#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#

class align_struct:
   """ A class structure to hold the details for each aligned template sequence. """

   def __init__(self):
      """ Initialisation. """

      self.name = ""
      self.aligned_seq = ""
      self.aligned_tar_seq = ""
      self.results_dir = ""
      self.in_fasta_file = ""
      self.out_fasta_file = ""

      self.seqID=0.0
      self.no_conserved=0

      self.no_of_gaps=0
      self.no_of_gap_chars=0
      self.gap_penalty=0.0

      self.raw_target_len=0
      self.target_len=0
      self.align_len=0
      self.align_len_score=0.0

      self.score=0.0

      self.chainsaw_target_seq=""
      self.chainsaw_template_seq=""
