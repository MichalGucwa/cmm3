#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Get_MR_sum.py
#
# Script to extract Summary scores from molrep log
# Ronan Keegan 22/12/05

import sys
import string
import smartie


class MR_Summary:
   """ A class to extract the summary of solutions from an MR log file. """

   def __init__(self):
      self.molrep_summary=''
      self.phaser_summary=''
      self.refmac_summary=''

      self.phaser_trans_title=""
      self.refmac_rfac_title=""

      self.refmac_version=""
      self.refmac_message=""

      self.log=""

   def setPhaserTransTitle(self, title):
      """ Set the title for the Translation function table from Phaser. """
      self.phaser_trans_title = title

   def setRefmacRfacTitle(self, title):
      """ Set the title for the Rfactor table from Refmac. """
      self.refmac_rfac_title = title

   def get_molrep_summary(self, logfile, molrepVersion):
      """ Get the solution summary molrep log file. """

      # Call smartie to parse the log file
      self.log=smartie.parselog(logfile)

      f=open(logfile,'r')
   
      if molrepVersion < 11.0:
         line=f.readline()
         while line: 
            if "--- Summary ---" in line:
               line = f.readline()
               line = f.readline()
               self.molrep_summary = line
               line = f.readline()
               for i in range(100):
                  self.molrep_summary += line
                  line = f.readline()
                  if "S__" not in line:
                     break
            line=f.readline()
      else:
         line=f.readline()
         summary=False
         self.molrep_summary += " "
         while line: 
            if "--- Summary ---" in line:
               line = f.readline()
               summary=True
            if "Contrast" not in line and summary==True:
               self.molrep_summary += line
            elif "Contrast" in line and summary==True:
               self.molrep_summary += line
               break
            line=f.readline()

      f.close()
     
      self.molrep_summary = string.strip(self.molrep_summary)

   def get_phaser_summary(self, logfile):
      """ Get the solution summary from the phaser log file. """

      # Call smartie to parse the log file
      self.log=smartie.parselog(logfile)

      # Pull out the final Translation function results table
      for tab in self.log.tables():
         if "Translation Function Component" in str(tab):
            table=self.log.tables(str(tab))[-1]

            # Reset the title for this table (defaults to original if blank)
      
            if self.phaser_trans_title != "": 
               table.settitle(self.phaser_trans_title)

            # point the summary at the table
            self.phaser_summary=table.loggraph()

#      self.phaser_summary = string.rstrip(self.phaser_summary)

   def get_refmac_summary(self, logfile):
      """ Get the solution summary refmac log file. """

      # Call smartie to parse the log file
      self.log=smartie.parselog(logfile)

      # Pull out the Rfactor results table
      table=self.log.tables("Rfactor analysis, stats vs cycle")[0]

      # Reset the title for this table (defaults to original if blank)
      if self.refmac_rfac_title != "": 
         table.settitle(self.refmac_rfac_title)

      # point the summary at the table
      self.refmac_summary=table.loggraph()

      #sys.stdout.write(self.refmac_summary + "\n")
      #sys.stdout.write("\n")

#if __name__=='__main__':
#
#   s=MR_Summary()
#   s.get_molrep_summary('molrep.log')
#   print s.molrep_summary

#if __name__=='__main__':
#
#   s=MR_Summary()
#   s.get_phaser_summary('phaser.sum')
#   print s.phaser_summary

if __name__=='__main__':

   s=MR_Summary()
   s.setRefmacRfacTitle("****** TEST TITLE FOR TABLE ******")
   s.get_refmac_summary('refmac.log')
   print s.refmac_summary

