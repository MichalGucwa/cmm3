#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2007 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
#
# Script to output details of jobs to the DB for viewing
# Ronan Keegan 21/05/07

import os
import sys
import time

class DB_output:

   def __init__(self):
      self.DB_fail=False
      self.JOB_ID=""
   
   def search_job(self, init, mstat, SEARCH_TYPE, input_files, output_files, logfile=""):
      """ Output the details of the FASTA search too the CCP4i DB. """

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            self.JOB_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "%s_Search" % SEARCH_TYPE,
               "%s search" % SEARCH_TYPE)

            #mstat.conn.SetData(init.ProjectName, self.JOB_ID,"TASKNAME", "%s_Search" % SEARCH_TYPE)
            #mstat.conn.SetData(init.ProjectName, self.JOB_ID,"TITLE", \
            #  "%s search" % SEARCH_TYPE)
            mstat.conn.SetData(init.ProjectName, self.JOB_ID,"STATUS", "RUNNING")
            for file in input_files:
               mstat.conn.AddInputFile(init.ProjectName, self.JOB_ID, file)
            for file in output_files:
               mstat.conn.AddOutputFile(init.ProjectName, self.JOB_ID, file)
            if logfile != "":
               mstat.conn.SetLogfile(init.ProjectName, self.JOB_ID, logfile)
            self.DB_fail=False
         except:
            sys.stdout.write("DB error: Could not enter a new record for %s job\n" % SEARCH_TYPE)
            sys.stdout.write("\n")
            self.DB_fail=True 

   def align_sort(self, init, mstat, input_align_file, logfile):
      """ Output the alignment details to the CCP4i DB. """

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            self.JOB_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Align_and_Sort",
               "Do multiple alignment of the search results and sort according to score")

            #mstat.conn.SetData(init.ProjectName, self.JOB_ID,"TASKNAME", "Align_and_Sort")
            #mstat.conn.SetData(init.ProjectName, self.JOB_ID,"TITLE", \
            #  "Do multiple alignment of the search results and sort according to score")
            mstat.conn.SetData(init.ProjectName, self.JOB_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, self.JOB_ID, input_align_file)
            mstat.conn.AddInputFile(init.ProjectName, self.JOB_ID, mstat.OCAmatchfile)
            if init.keywords.SSM:
               mstat.conn.AddInputFile(init.ProjectName, self.JOB_ID, mstat.SSMmatchfile)
            if init.keywords.SCOP:
               mstat.conn.AddInputFile(init.ProjectName, self.JOB_ID, mstat.SCOP_results_file)
            for chain in mstat.sorted_MR_list:
               mstat.conn.AddOutputFile(init.ProjectName, self.JOB_ID, mstat.chain_list[chain].PDBFile)
            mstat.conn.SetLogfile(init.ProjectName, self.JOB_ID, logfile)
            self.DB_fail=False
         except:
            sys.stdout.write("DB error: Could not enter a new record for align and sort job\n")
            sys.stdout.write("\n")
            self.DB_fail=True 

   def finish_job(self, init, mstat, JOB_ID):
      """ Finish the job """

      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, JOB_ID,"STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail=False
