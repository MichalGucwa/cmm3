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
# Module to get the scores for the model preparation
# Ronan Keegan 25.8.05

import os, sys, string

class Model_Prep_Scores: 
   """ A class to collect results from the Modeller output files. """

   def __init__(self):
      self.total=0.0
      self.chainsaw_seq_id=0.0
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def r_violations(self, mstat, target_info):
      """ A function to collect the violation scores from the modeller directories. """

      viol_total=0.0
	
      # Loop over all matches and check for the existance of the violations file 

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
         viol_file = os.path.isfile(init.search_dir + '/data/' + mstat.chain_list[chain].chainName + \
         '/modeller/' + target_info.chainID + '.V99990001')
   
	 # Open the violations file and record the total violation score

         if viol_file is True:
            f=open(init.search_dir + '/data/' + mstat.chain_list[chain].chainName +'/modeller/' + target_info.chainID + '.V99990001','r')
            line=string.strip(f.readline())
      
            while line:
               if '#' not in line[0] and len(line) != 1:
                  residue_viol_total=(float)((string.split(line))[-1])
                  viol_total=viol_total + residue_viol_total
               line=f.readline()
   
            f.close()
            mstat.chain_list[chain].setModeller_ViolScore(viol_total)
            viol_total=0.0

         # Otherwise, report an error to the error log about the non-existence of the model

         else:
            e=open(init.search_dir + '/logs/errors.log','a')
            e.write('Model ' + mstat.chain_list[chain].chainName + \
	    ' failed to produce a model from Modeller. Check its Modeller log.\n')
            e.close()


   def molrep_score(self, init, mstat):
      """ A function to collect the Molrep modelling scores. """

      score_found=False 

      # Loop over all matches and check for the existance of the Molrep log file 

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
         mol_log_file = os.path.isfile(mstat.chain_list[chain].molrep_logfile)

         # If the file exists then record the Molrep score value for this model.
 
         if mol_log_file is True:
            f=open(mstat.chain_list[chain].molrep_logfile,'r')
            line=string.strip(f.readline())
      
            while line:
               if '<SCORE>' in line:
                  mstat.chain_list[chain].setMolrepScore((float)((string.split(line))[-1]))
                  score_found=True
                  break
               line=f.readline()

            # If no score was found for this model report the error             

            if score_found==False:            
               e=open(init.search_dir + '/logs/errors.log','a')
               e.write('Model ' + mstat.chain_list[chain].chainName + \
               ' failed to give a Molrep score. Check its Molrep log.\n')
               e.close()

            f.close()
       
         # Otherwise, print an erro to the error log file
 
         else:
            e=open(init.search_dir + '/logs/errors.log','a')
            e.write('Model ' + mstat.chain_list[chain].chainName + \
            ' failed to produce a model from Molrep. Check its Molrep log.\n')
            e.close()

   def chainsaw_score(self, init, mstat, align_type):
      """ A function to collect the Chainsaw modelling scores. """

      # Loop over all matches and check for the existance of the Chainsaw log file 

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:

         score_found=False 

         chainsaw_DIR = init.search_dir + '/data/' + mstat.chain_list[chain].chainName + '/chainsaw_m'
         chs_log_file = os.path.isfile(mstat.chain_list[chain].chainsaw_logfile)

         # If the file exists then record the Chainsaw score value for this model.
 
         if chs_log_file is True:
            f=open(mstat.chain_list[chain].chainsaw_logfile,'r')
            line=f.readline()
      
            while line:
               if 'Estimated sequence identity' in line:
                  self.chainsaw_seq_id = float(string.split(line)[-1])
                  score_found = True

               line=f.readline()

            if score_found==True:            
               mstat.chain_list[chain].setChainsawScore(self.chainsaw_seq_id)

            # If no score was found for this model report the error             

            if score_found==False:            
               print ""
               print 'Chainsaw Log Message: Model ' + mstat.chain_list[chain].chainName \
               + ' failed to give a Chainsaw score. Check its Chainsaw log. '
               print ""

            f.close()
       
         # Otherwise, print an erro to the error log file
 
         else:
            print 'Chainsaw Log Message: Model ' + mstat.chain_list[chain].chainName + \
            ' failed to produce a model from Chainsaw. Check its Chainsaw log.\n'

