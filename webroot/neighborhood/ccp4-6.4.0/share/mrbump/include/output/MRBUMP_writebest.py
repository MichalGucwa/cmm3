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
# Script to write out the best results so far to a log file
# Ronan Keegan 30/4/08

import os, sys, string
import time
import shutil
import printTable
import MRBUMP_printTable


class BestLog:
   """ A class to output the best results so far to the BEST log file. """

   def __init__(self):
      self.old_results_logfile=""
      self.report=""
      self.sorted_soln_list=[]
      self.number_MR_jobs=0

      self.debug=False

   def sort_soln_list(self, mstat):
      """ Take the current list of completed solutions and sort them according to Rfree. """

      best_model=""
      final_rfree=0.0

      while len(mstat.soln_list.keys()) > len(self.sorted_soln_list):
         lowest_rfree=10000.0
         for s_model in mstat.soln_list.keys():
 
            # See if we are using Molrep or Phaser
            MODEL_SOURCE=mstat.soln_list[s_model].model_source
            if mstat.soln_list[s_model].mrprogram.upper()=="MOLREP":
               final_rfree=mstat.model_list[MODEL_SOURCE].refmac_molrep_finlRfree
            if mstat.soln_list[s_model].mrprogram.upper()=="PHASER":
               final_rfree=mstat.model_list[MODEL_SOURCE].refmac_phaser_finlRfree

            # Test the final rfree to see if it is the lowest
            if (final_rfree < lowest_rfree) and (s_model not in self.sorted_soln_list):
               previousLowRfree=lowest_rfree
               lowest_rfree=final_rfree
               best_model=s_model
             
         # If the final Rfree is 0 the job has failed. We reverse the list and add this result to the end
         if (final_rfree <= 0):
            self.sorted_soln_list.reverse()
            self.sorted_soln_list.append(best_model)
            self.sorted_soln_list.reverse()
            lowest_rfree=previousLowRfree
         else:
            self.sorted_soln_list.append(best_model)

   def write_results_log(self, init, mstat):
      """ Write out the best solution details so far. """

      if "PHASER" in init.keywords.MR_PROGRAM_LIST and "MOLREP" in init.keywords.MR_PROGRAM_LIST:
         if init.keywords.USEENSEM: 
            self.number_MR_jobs = len(mstat.sorted_model_list) + len(mstat.sorted_model_list) - 1
         else:
            self.number_MR_jobs = len(mstat.sorted_model_list) + len(mstat.sorted_model_list) 
      elif init.keywords.MR_PROGRAM_LIST == ["MOLREP"]:
         if init.keywords.USEENSEM: 
            self.number_MR_jobs = len(mstat.sorted_model_list) - 1 
         else:
            self.number_MR_jobs = len(mstat.sorted_model_list) 
      elif init.keywords.MR_PROGRAM_LIST == ["PHASER"]:
         self.number_MR_jobs = len(mstat.sorted_model_list) 

      if os.path.isfile(init.results_logfile):
         self.old_results_logfile=os.path.join(init.results_dir, "old_results_log.txt")
         os.rename(init.results_logfile, self.old_results_logfile)

      f=open(init.results_logfile, "w")

      FINAL=False
      if init.keywords.CLUSTER:
         if mstat.parallel_jobs_finished == self.number_MR_jobs:
            banner_message="Final report            "
            FINAL=True
         else:
            banner_message="Sorted results so far..."
      else:
         if mstat.mr_counter == self.number_MR_jobs:
            banner_message="Final report            "
            FINAL=True
         else:
            banner_message="Sorted results so far..."

      # Tag this up as SUMMARY content
      self.report  = '<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n'

      self.report += "\n"
      self.report += "$$\n"
      self.report += "$TEXT:Summary: $$ Summary $$\n"
      self.report += "\n"
      self.report += "#################################################################\n"
      self.report += "###         MrBUMP Summary: " + banner_message + "          ###\n"
      self.report += "#################################################################\n"
      self.report += "\n"

      # Some general details about this MrBUMP run
      self.report += "Total number of MR jobs:         %d\n" % self.number_MR_jobs
      if init.keywords.CLUSTER == True and hasattr(mstat, 'parallel_jobs_finished'):
          self.report += "Number of MR jobs completed:    %d\n" % mstat.parallel_jobs_finished
      else:
        self.report += "Number of MR jobs run so far:    %d\n" % mstat.mr_counter
               
      self.report += "MR programs being used:          "
      for prog in init.keywords.MR_PROGRAM_LIST:
         self.report += "%s " % prog
      self.report += "\n\n"

      # If we have solutions write out the best scoring details
      if len(mstat.soln_list.keys()) > 0:
         self.sort_soln_list(mstat)
        
         best_model=self.sorted_soln_list[0]
         MODEL_SOURCE=mstat.soln_list[best_model].model_source
         self.report += "Best search model so far:        %s using %s\n" % (MODEL_SOURCE, mstat.soln_list[best_model].mrprogram)
         if mstat.soln_list[best_model].mrprogram.upper()=="MOLREP":
            self.report += "            Initial Rfree:       %.3f\n" % mstat.model_list[MODEL_SOURCE].refmac_molrep_initRfree
            self.report += "            Final Rfree:         %.3f\n" % mstat.model_list[MODEL_SOURCE].refmac_molrep_finlRfree
            if init.keywords.SHELXE:
               self.report += "            SHELXE CC:           %.3f\n" % mstat.model_list[MODEL_SOURCE].shelxe_molrep_CCscore
         if mstat.soln_list[best_model].mrprogram.upper()=="PHASER":
            self.report += "            Initial Rfree:       %.3f\n" % mstat.model_list[MODEL_SOURCE].refmac_phaser_initRfree
            self.report += "            Final Rfree:         %.3f\n" % mstat.model_list[MODEL_SOURCE].refmac_phaser_finlRfree
            if init.keywords.SHELXE:
               self.report += "            SHELXE CC:           %.3f\n" % mstat.model_list[MODEL_SOURCE].shelxe_phaser_CCscore
         self.report += "            Solution Type:       %s\n" % mstat.soln_list[best_model].solution_type
         self.report += "\n"
   
         self.report += "Files for best search model:\n"
         if mstat.soln_list[best_model].mrprogram.upper()=="MOLREP":
            self.report += "Refmac PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_molrep_PDBfile
            self.report += "Refmac MTZOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_molrep_MTZOUTfile
            self.report += "Refmac LOG:   \n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_molrep_logfile
            if init.keywords.BUCCANEER:
               self.report += "Buccaneer PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].buccaneer_molrep_PDBOUTfile
            if init.keywords.ARPWARP:
               self.report += "ARP/wARP PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].arpwarp_molrep_PDBOUTfile
            if init.keywords.SHELXE:
               self.report += "SHELXE PDBOUT:   \n %s\n" % mstat.model_list[MODEL_SOURCE].shelxe_molrep_PDBfile
         if mstat.soln_list[best_model].mrprogram.upper()=="PHASER":
            self.report += "Refmac PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_phaser_PDBfile
            self.report += "Refmac MTZOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_phaser_MTZOUTfile
            self.report += "Refmac LOG:   \n %s\n" % mstat.model_list[MODEL_SOURCE].refmac_phaser_logfile
            if init.keywords.BUCCANEER:
               self.report += "Buccaneer PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].buccaneer_phaser_PDBOUTfile
            if init.keywords.ARPWARP:
               self.report += "ARP/wARP PDBOUT:\n %s\n" % mstat.model_list[MODEL_SOURCE].arpwarp_phaser_PDBOUTfile
            if init.keywords.SHELXE:
               self.report += "SHELXE PDBOUT:   \n %s\n" % mstat.model_list[MODEL_SOURCE].shelxe_phaser_PDBfile
         self.report += "\n"
           
         if len(mstat.soln_list.keys()) > 0:
            self.report += "Complete list of solutions so far:\n" 
            self.report += "\n"

            # Re-initialise the results table
            mstat.resultsTable=[]
            mstat.reportTable=""

            # Set up the results and report table headers
             
            mstat.reportTable +=  " $TABLE: Final Summary:\n"
            mstat.reportTable +=  " $GRAPHS: Final Rfactor/Rfree vs model :N:1,5,6:\n"
            if init.keywords.BUCCANEER:
               mstat.reportTable +=  "        : Buccaneer Final Rfactor/Rfree vs model :N:1,7,8:\n"
            if init.keywords.ARPWARP:
               if init.keywords.BUCCANEER:
                  col1=9
                  col2=10
               else:
                  col1=7
                  col2=8
               mstat.reportTable +=  "        : ARP/wARP Final Rfactor/Rfree vs model :N:1,%d,%d:\n" % (col1, col2)
            if init.keywords.SHELXE:
               if init.keywords.BUCCANEER and init.keywords.ARPWARP:
                  col1=11
               elif bool(init.keywords.BUCCANEER) != bool(init.keywords.ARPWARP):
                  col1=9
               else:
                  col1=7
               mstat.reportTable +=  "        : SHELXE CC vs model :N:1,%d:\n" % col1
            mstat.reportTable +=  " $$\n"
            mstat.reportTable +=  " Model  Model_Name  MR_Program  Solution_Type  final_Rfact  final_Rfree"
            if init.keywords.BUCCANEER:
               mstat.reportTable += " Bucc_final_Rfact"
               mstat.reportTable += " Bucc_final_Rfree"
            if init.keywords.ARPWARP:
               mstat.reportTable += " ARP_final_Rfact"
               mstat.reportTable += " ARP_final_Rfree"
            if init.keywords.SHELXE:
               mstat.reportTable += " SHELXE_CC"
            mstat.reportTable +=  " $$\n"
            mstat.reportTable +=  " $$\n"

            titleTable=["", "Model_Name", "MR_Program", "Solution_Type", "final_Rfact", "final_Rfree"]
            if init.keywords.BUCCANEER:
               titleTable.append("Bucc_final_Rfact")
               titleTable.append("Bucc_final_Rfree")
            if init.keywords.ARPWARP:
               titleTable.append("ARP_final_Rfact")
               titleTable.append("ARP_final_Rfree")
            if init.keywords.SHELXE:
               titleTable.append("SHELXE_CC")
 
            mstat.resultsTable.append(titleTable)

            # Add the results
            count=1
            for s_model in self.sorted_soln_list:
               MODEL_SOURCE=mstat.soln_list[s_model].model_source
               if mstat.soln_list[s_model].mrprogram.upper()=="MOLREP":

                  scoreTable=["", str(MODEL_SOURCE), "MOLREP", str(mstat.model_list[MODEL_SOURCE].solution_type_MOLREP), \
                       '{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].refmac_molrep_finlRfact), \
                       '{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].refmac_molrep_finlRfree)]
                  if init.keywords.BUCCANEER:
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].buccaneer_molrep_finalRfact))
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].buccaneer_molrep_finalRfree))
                  if init.keywords.ARPWARP:
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].arpwarp_molrep_finalRfact))
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].arpwarp_molrep_finalRfree))
                  if init.keywords.SHELXE:
                     scoreTable.append('{0:.2f}'.format(mstat.model_list[MODEL_SOURCE].shelxe_molrep_CCscore))
                   
                  mstat.reportTable +=  "  %d" % count
                  mstat.reportTable +=  "  ".join(scoreTable)
                  mstat.reportTable +=  "\n"
                  mstat.resultsTable.append(scoreTable)

               if mstat.soln_list[s_model].mrprogram.upper()=="PHASER":

                  scoreTable=["", str(MODEL_SOURCE), "PHASER", str(mstat.model_list[MODEL_SOURCE].solution_type_PHASER), \
                       '{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].refmac_phaser_finlRfact), \
                       '{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].refmac_phaser_finlRfree)]
                  if init.keywords.BUCCANEER:
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].buccaneer_phaser_finalRfact))
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].buccaneer_phaser_finalRfree))
                  if init.keywords.ARPWARP:
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].arpwarp_phaser_finalRfact))
                     scoreTable.append('{0:.3f}'.format(mstat.model_list[MODEL_SOURCE].arpwarp_phaser_finalRfree))
                  if init.keywords.SHELXE:
                     scoreTable.append('{0:.2f}'.format(mstat.model_list[MODEL_SOURCE].shelxe_phaser_CCscore))
                   
                  mstat.reportTable +=  "  %d" % count
                  mstat.reportTable +=  "  ".join(scoreTable)
                  mstat.reportTable +=  "\n"
                  mstat.resultsTable.append(scoreTable)

               count=count+1
 
            mstat.reportTable +=  " $$\n\n"
            #Output the table
            T=MRBUMP_printTable.Table()
            Tstring=T.pstring_table(mstat.resultsTable)
            self.report += Tstring + "\n"
            self.report += "$$\n"

            # Write out the results table data file for AMPLE
            if FINAL:
               resultsTableFile=open(os.path.join(init.search_dir, "results", "resultsTable.dat"), "w")
               out = resultsTableFile
               T.pprint_table(out, mstat.resultsTable)
               resultsTableFile.close()

         sys.stdout.write("\n")

         if init.keywords.CLUSTER == True and hasattr(mstat, 'parallel_jobs_finished'):
            if mstat.parallel_jobs_finished == self.number_MR_jobs: 
               sys.stdout.write("Copying best PDB and MTZ to XYZOUT and HKLOUT ...\n\n")
               if mstat.soln_list[best_model].mrprogram.upper()=="MOLREP":
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_MTZOUTfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_MTZOUTfile, init.hklout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Molrep mtz file\n\n")
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_PDBfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_PDBfile, init.xyzout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Molrep pdb file\n\n")
               if mstat.soln_list[best_model].mrprogram.upper()=="PHASER":
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_MTZOUTfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_MTZOUTfile, init.hklout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Phaser mtz file\n\n")
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_PDBfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_PDBfile, init.xyzout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Phaser pdb file\n\n")
         else:
            if mstat.mr_counter == self.number_MR_jobs: 
               sys.stdout.write("Copying best PDB and MTZ to XYZOUT and HKLOUT ...\n\n")
               if mstat.soln_list[best_model].mrprogram.upper()=="MOLREP":
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_MTZOUTfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_MTZOUTfile, init.hklout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Molrep mtz file\n\n")
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_PDBfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_molrep_PDBfile, init.xyzout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Molrep pdb file\n\n")
               if mstat.soln_list[best_model].mrprogram.upper()=="PHASER":
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_MTZOUTfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_MTZOUTfile, init.hklout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Phaser mtz file\n\n")
                  if os.path.isfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_PDBfile):
                     shutil.copyfile(mstat.model_list[MODEL_SOURCE].refmac_phaser_PDBfile, init.xyzout)
                  else:
                     sys.stdout.write("Warning: [MRBUMP_writebest] Could not find 'best solution' Phaser pdb file\n\n")

      else:
         self.report += "To date, no models have been successfully processed\n"
         self.report += "\n"

      if FINAL:
         self.report += mstat.reportTable

      self.report += "#################################################################\n"
      self.report += "#################################################################\n"
      self.report += "\n"

      # Close the SUMMARY tag for the input details
      self.report +='<!--SUMMARY_END--></FONT></B>\n'

      f.write(self.report)

      f.close()

      if os.path.isfile(self.old_results_logfile):
         os.remove(self.old_results_logfile)

