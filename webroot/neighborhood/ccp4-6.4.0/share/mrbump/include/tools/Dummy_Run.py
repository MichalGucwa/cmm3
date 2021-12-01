#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Script for runnning a dummy run of mrbump and outputting XML 
# Ronan Keegan 14/3/07

import os, sys, string
import shutil
import pickle
import shutil
import smartie
import WriteXML
import Sort_dict


class DummyJob:
   """ A class to run a dummy run of MrBUMP with data read from pickle files. """

   def __init__(self):

      self.p_dir=""
      self.file_list=[]
      self.STOP_JOB=False

      self.log_list=[]

   def run(self, init):

      self.p_dir=os.path.join(os.getcwd(), "pickle_data")

      # Check the pickle data folder exists
      if os.path.isdir(self.p_dir) == False:
        sys.stdout.write("Error: Running in Dummy Run mode. This requires pickled data and sample log files\n" \
                         "to be stored in folder:\n   %s" % self.p_dir)
        sys.stdout.write("\n") 
        self.STOP_JOB=True

      if init.ONLYMODELS:
         self.file_list=["mstat.dat", "target.dat"]
      else:
         self.file_list=["mstat.dat", "target.dat", "refmac.log"]
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            self.file_list.append("molrep.log")
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            self.file_list.append("phaser.log")

      # Check for each of the required files
      for file in self.file_list:
         if os.path.exists(os.path.join(self.p_dir, file)) == False:
            sys.stdout.write("Error: Running in Dummy Run mode. Input file not found\n")
            sys.stdout.write("       File name: %s\n" % file)
            sys.stdout.write("\n")
            self.STOP_JOB=True
      
      if self.STOP_JOB:
         sys.stdout.write("Job will exit now. Set keyword DUMMY to False if you want to run a real job.\n")
         sys.stdout.write("\n")

         sys.exit()
            
      # Read the Match structure data from its pickle file
      mstat_file=open(os.path.join(self.p_dir, "mstat.dat"), "r")
      mstat=pickle.load(mstat_file)
      mstat_file.close()

      # Use smartie to parse the various log files
      if init.ONLYMODELS == False:
         for model in mstat.sorted_model_list:
            if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
               mstat.model_list[model].molrep_smartie_log=smartie.parselog(os.path.join(self.p_dir, "molrep.log"))
            if "PHASER" in init.keywords.MR_PROGRAM_LIST:
               mstat.model_list[model].phaser_smartie_log=smartie.parselog(os.path.join(self.p_dir, "phaser.log"))
            mstat.model_list[model].refmac_molrep_smartie_log=smartie.parselog(os.path.join(self.p_dir, "refmac.log"))
            mstat.model_list[model].refmac_phaser_smartie_log=smartie.parselog(os.path.join(self.p_dir, "refmac.log"))
   
            # Reset the table names
            if "PHASER" in init.keywords.MR_PROGRAM_LIST:
               table1=mstat.model_list[model].phaser_smartie_log.findtable("Translation Function Summary",-1)
               table1.settitle("Final Translation Function Summary for model %s" % model)
   
               table2=mstat.model_list[model].refmac_phaser_smartie_log.findtable("Rfactor analysis, stats vs cycle")
               table2.settitle("Rfactor analysis, stats vs cycle for model %s" % model)
   
            if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
               table3=mstat.model_list[model].refmac_molrep_smartie_log.findtable("Rfactor analysis, stats vs cycle")
               table3.settitle("Rfactor analysis, stats vs cycle for model %s" % model)

      target_file=open(os.path.join(self.p_dir, "target.dat"), "r")
      target_info=pickle.load(target_file)
      target_file.close()

      # Put the results into a dictionary holding model name/final rfree pairs
      sorted_results=dict([])
      for model in mstat.sorted_model_list:
         sorted_results[model]=mstat.model_list[model].refmac_finlRfree

      # Sort the dictionary of results
      s=Sort_dict.Sort_dict()
      sorted_list=s.sort(sorted_results)

      #for i in sorted_list:
      #   sys.stdout.write("Model Name: %s\t -- Solution type: '%s'\t -- Final Rfree: %.3f\n" % (i[0], mstat.model_list[i[0]].solution_type, i[1]))
         #sys.stdout.write("         -- %s\n" % mstat.model_list[i[0]].model_info_string)
      #sys.stdout.write("\n")

      # Ouput the job details to an XML file
      if init.keywords.XMLOUT:
         xml=WriteXML.writeXML()
         xml.write_details(init, mstat, target_info, init.keywords.SUMMARYFILE)

   def pickle(self, init, mstat, target_info):
      """ Pickle the three main objects at the end of a Job. This should be the very last function to be called """

      self.p_dir=os.path.join(mstat.results_dir, "pickle_data") 

      if os.path.exists(self.p_dir) == False:
         os.mkdir(self.p_dir) 

      # Temporaily set the each of the smartie logs to be "None" to avoid pickle problem with smartie 
      for model in mstat.sorted_model_list:
         log=[]

         log.append(mstat.model_list[model].molrep_smartie_log)
         log.append(mstat.model_list[model].phaser_smartie_log)
         log.append(mstat.model_list[model].refmac_molrep_smartie_log)
         log.append(mstat.model_list[model].refmac_phaser_smartie_log)
          
         self.log_list.append(log)
        
         mstat.model_list[model].molrep_smartie_log=None
         mstat.model_list[model].phaser_smartie_log=None
         mstat.model_list[model].refmac_molrep_smartie_log=None
         mstat.model_list[model].refmac_phaser_smartie_log=None

      # Dump the Match structure data to its pickle file
      mstat_file=open(os.path.join(self.p_dir, "mstat.dat"), "w")
      pickle.dump(mstat, mstat_file)
      mstat_file.close()

      # Dump the Target info structure to from its pickle file
      target_file=open(os.path.join(self.p_dir, "target.dat"), "w")
      pickle.dump(target_info, target_file)
      target_file.close()

      # Dump the Init structure to from its pickle file
      init_file=open(os.path.join(self.p_dir, "init.dat"), "w")
      pickle.dump(init, init_file)
      init_file.close()

      # Restore the smartie logs
      for model in mstat.sorted_model_list:
         for log in self.log_list:

            mstat.model_list[model].molrep_smartie_log=log[0]
            mstat.model_list[model].phaser_smartie_log=log[1]
            mstat.model_list[model].refmac_molrep_smartie_log=log[2]
            mstat.model_list[model].refmac_phaser_smartie_log=log[3]
       
      # Free the log list
      self.log_list=[]

#      if init.ONLYMODELS == False:
#         # Copy samples of refmac/molrep/phaser log files to the pickle_dir
#         if mstat.model_list[mstat.sorted_model_list[0]].name[:14] != "ensemble_model" or len(mstat.sorted_model_list) == 1:
#            shutil.copyfile(mstat.model_list[mstat.sorted_model_list[0]].refmac_logfile, os.path.join(self.p_dir, "refmac.log"))
#         else:
#            shutil.copyfile(mstat.model_list[mstat.sorted_model_list[1]].refmac_logfile, os.path.join(self.p_dir, "refmac.log"))
#         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
#            if mstat.model_list[mstat.sorted_model_list[0]].name[:14] != "ensemble_model" or len(mstat.sorted_model_list) == 1:
#               shutil.copyfile(mstat.model_list[mstat.sorted_model_list[0]].molrep_logfile, os.path.join(self.p_dir, "molrep.log"))
#            else:
#               shutil.copyfile(mstat.model_list[mstat.sorted_model_list[1]].molrep_logfile, os.path.join(self.p_dir, "molrep.log"))
#         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
#            shutil.copyfile(mstat.model_list[mstat.sorted_model_list[0]].phaser_logfile, os.path.join(self.p_dir, "phaser.log"))
