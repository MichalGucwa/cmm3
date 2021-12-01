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
# Write various log files for the different stages in the MR job.
# Ronan Keegan 25/06/07

import os, sys, string
import time, shutil

class Logfile:
   """ A class to write out log files for each of the stages in a MrBUMP job. """
 
   def __init__(self):
      self.logfile=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLogFile(self, filename):
      self.logfile=filename

   def writeTargetLog(self, init, mstat, target_info):
      """ Write out the details from the target processing step to a logfile. """

      self.setLogFile(os.path.join(init.search_dir, "logs", "target_processing.log"))
      
      file=open(self.logfile, "w")
  
      log  = "\n"
      log += "#######################################################" + len(init.keywords.JOBID)*"#" + "\n" 
      log += "######          Target details for job: %s         ######\n" % init.keywords.JOBID
      log += "#######################################################" + len(init.keywords.JOBID)*"#" + "\n" 

      log += "\n"

      log += "Input sequence file:\n   %s\n" % target_info.seqfile
      if init.ONLYMODELS == False:
         log += "Input MTZ file:\n   %s\n" % target_info.hklin
      log += "\n"

      log += "Target Sequence:\n"
      log += "\n"
      log += "%s\n" % target_info.pretty_sequence
      log += "\n"

      log += "Number of residues: %d\n" % target_info.no_of_res
      log += "\n"
      log += "Molecular weight: %d\n" % target_info.mol_weight
      log += "\n"

      if init.ONLYMODELS == False:
         log += "Estimated number of molecules in the asu: %d\n" % target_info.no_of_mols
         if init.keywords.NMASU == None:
            log += "   (calculated using Matthews_coef - see matt_coef.log file for more details)\n"
         else:
            log += "   (specified by the user)\n"
         log += "\n"
         log += "Resolution of target data: %.3f\n" % target_info.resolution
         log += "\n"
         log += "Cell dimensions:\n"
         log += "   a: %.3f  b: %.3f  c: %.3f  alpha: %.3f  beta: %.3f  gamma %.3f\n" % \
		 (target_info.cell_dimensions["a"],\
                 target_info.cell_dimensions["b"],\
                 target_info.cell_dimensions["c"],\
                 target_info.cell_dimensions["alpha"],\
                 target_info.cell_dimensions["beta"],\
                 target_info.cell_dimensions["gamma"])
         log += "\n"

         log += "Spacegroup of target data: %s (%s)\n" % (target_info.space_group, target_info.hklin_SG_code)
         log += "\n"

         if init.keywords.ENANT:
            log += "Enantiomorphic spacegroup of target data: %s (%s)\n" % (target_info.enant_spacegroup, target_info.enant_SG_code)
            log += "\n"
     
      file.write(log)
      file.close()
       
   def writeSSMLog(self, init, mstat):
      """ Write the details of the SSM search to a log file. """

      self.setLogFile(os.path.join(init.search_dir, "logs", "ssm_search.log"))
      
      file=open(self.logfile, "w")

      log  = "\n"
      log += "###########################################################" + len(init.keywords.JOBID)*"#" + "\n" 
      log += "######          SSM search details for job: %s         ######\n" % init.keywords.JOBID
      log += "###########################################################" + len(init.keywords.JOBID)*"#" + "\n" 

      log += "\n"

      log += "Base structure used for SSM search: %s\n" % mstat.top_match_pdbid
      log += "   (this was the top match from the FASTA search)\n"
      log += "\n"

      log += "SSM results file returned by SSM search server at the EBI:\n   %s\n" % mstat.SSM_resultsfile
      log += "\n"

      log += "Number of hits found in the search: %d\n" % mstat.no_of_SSMhits
      log += "Number of new hits found in the search: %d\n" % mstat.no_of_newSSMhits
      log += "   (hits not found in FASTA search)\n"
      log += "\n"
      
      if mstat.no_of_newSSMhits > 0:
         log += "List of PDB IDs and Chain IDs for new hits from SSM search:\n"
         count=1
         for id in mstat.SSMnewhits:
            log += "%d. PDB ID: %s Chain ID: %s\n" % (count, id[0:4], id[5])
            count=count+1
         log += "\n"

      file.write(log)
      file.close()
       
