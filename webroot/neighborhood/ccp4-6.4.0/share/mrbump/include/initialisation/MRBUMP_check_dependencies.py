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
# Script to check all the dependencies of MRBUMP before a job is run
# Ronan Keegan 12/12/05

import os, sys, string
import Scan_path

class Check_deps:
   """ A class to check that all the dependencies of MRBUMP are in place before a job starts. """

   def __init__(self):
      self.mafft_exe_found = False
      self.probcons_exe_found = False
      self.tcoffee_exe_found = False
      self.clustalw_exe_found = False
      self.ma_keyword_ok = True
      self.phaser_exe_found = False
      self.molrep_exe_found = False

   def chk_ma_program(self, keywords):
      """ Check that at least one of the multiple alignment programs is installed. """

      # Check for the mafft executable
      self.scan_path = Scan_path.Check_PATH()
      if os.name=="nt":
         if os.path.isfile(os.path.join(os.environ['CCP4'], 'libexec', 'mafft.bat')):
            self.mafft_exe_found = True
            os.environ['MAFFT_BINARIES'] = os.path.join(os.environ['CCP4'], 'libexec')
         else:
            self.mafft_exe_found = self.scan_path.find_exec('mafft.bat')
      else:
         if os.path.isfile(os.path.join(os.environ['CCP4'], 'libexec', 'mafft')):
            self.mafft_exe_found = True
            os.environ['MAFFT_BINARIES'] = os.path.join(os.environ['CCP4'], 'libexec')
         else:
            self.mafft_exe_found = self.scan_path.find_exec('mafft')

      # Check for the probcons executable
      self.scan_path = Scan_path.Check_PATH()
      self.probcons_exe_found = self.scan_path.find_exec('probcons')

      # Check for the tcoffee executable
      self.scan_path = Scan_path.Check_PATH()
      self.tcoffee_exe_found = self.scan_path.find_exec('t_coffee')

      # Check for the clustalw executable
      if os.path.isfile(os.path.join(os.environ['CCP4'], 'libexec', 'clustalw2')):
         self.clustalw_exe_found = True
      else:
         self.scan_path = Scan_path.Check_PATH()
         self.clustalw_exe_found = self.scan_path.find_exec('clustalw2')
         
      # If clustalw not found check for the clustalw executable
      if self.clustalw_exe_found == False:
         self.scan_path = Scan_path.Check_PATH()
         self.clustalw_exe_found = self.scan_path.find_exec('clustalw')
         
      if keywords.MAPROGRAM == "MAFFT" and self.mafft_exe_found == False:
         print ""
         print "Program 'mafft' was not found in the system PATH."
         print ""
         self.ma_keyword_ok = False
      elif keywords.MAPROGRAM == "PROBCONS" and self.probcons_exe_found == False: 
         print ""
         print "Program 'probcons' was not found in the system PATH."
         print ""
         self.ma_keyword_ok = False
      elif keywords.MAPROGRAM == "T_COFFEE" and self.tcoffee_exe_found == False: 
         print ""
         print "Program 't_coffee' was not found in the system PATH."
         print ""
         self.ma_keyword_ok = False
      elif keywords.MAPROGRAM == "CLUSTALW" and self.clustalw_exe_found == False: 
         print ""
         print "Program 'clustalw' was not found in the system PATH."
         print ""
         self.ma_keyword_ok = False

      if self.ma_keyword_ok == False:
         if self.mafft_exe_found:
            print "Will use MAFFT to do multiple alignment of sequences instead."
            keywords.MAPROGRAM = "MAFFT"
            self.ma_keyword_ok = True
         elif self.probcons_exe_found:
            print "Will use PROBCONS to do multiple alignment of sequences instead."
            keywords.MAPROGRAM = "PROBCONS"
            self.ma_keyword_ok = True
         elif self.clustalw_exe_found:
            print "Will use CLUSTALW to do multiple alignment of sequences instead."
            keywords.MAPROGRAM = "CLUSTALW"
            self.ma_keyword_ok = True
         elif self.tcoffee_exe_found:
            print "Will use T_COFFEE to do multiple alignment of sequences instead."
            keywords.MAPROGRAM = "T_COFFEE"
            self.ma_keyword_ok = True
         else:
           print ""
           print "Dependency check error: No suitable multiple alignment program was found in your system PATH."
           print ""
           print "Either 'mafft', 'clustalw', 'probcons' or 't_coffee' are acceptable and are available from:"
           print "http://align.bmr.kyushu-u.ac.jp/mafft/software/  -  Mafft"
           print "ftp://ftp.ebi.ac.uk/pub/software/unix/clustalw/  -  Clustalw"  
           print "http://probcons.stanford.edu/ - Probcons"
           print "http://www.tcoffee.org/ - TCoffee"
           print ""
           sys.exit(1)

   def chk_MRPROGRAM(self, keywords):
      """ Check if phaser program is installed. """

      # Check for the phaser executable
      self.scan_path = Scan_path.Check_PATH()
      self.phaser_exe_found = self.scan_path.find_exec('phaser')

      # Check for the molrep executable
      self.scan_path = Scan_path.Check_PATH()
      self.molrep_exe_found = self.scan_path.find_exec('molrep')

      if "PHASER" in keywords.MR_PROGRAM_LIST and len(keywords.MR_PROGRAM_LIST) == 1 \
        and self.phaser_exe_found == False and self.molrep_exe_found == True:
         print ""
         print "Dependency check error: Program 'phaser' was not found in the system PATH."
         print "                        Try using Molrep instead."
         print ""
         sys.exit(1)

      if "MOLREP" in keywords.MR_PROGRAM_LIST and len(keywords.MR_PROGRAM_LIST) == 1 \
        and self.phaser_exe_found == True and self.molrep_exe_found == False:
         print ""
         print "Dependency check error: Program 'molrep' was not found in the system PATH."
         print "                        Try using Phaser instead."
         print ""
         sys.exit(1)

      if len(keywords.MR_PROGRAM_LIST) == 2:
         if self.phaser_exe_found == False and self.molrep_exe_found == True:
            print ""
            print "Dependency check error: Program 'phaser' was not found in the system PATH."
            print "                        Program will only use Molrep for molecular replacement."
            print ""
            keywords.MR_PROGRAM_LIST=['MOLREP']
         if self.phaser_exe_found == True and self.molrep_exe_found == False:
            print ""
            print "Dependency check error: Program 'molrep' was not found in the system PATH."
            print "                        Program will only use Phaser for molecular replacement."
            print ""
            keywords.MR_PROGRAM_LIST=['PHASER']

      if self.phaser_exe_found == False and self.molrep_exe_found == False:
         print ""
         print "Dependency check error: No suitable molecular replacement program was found in your system PATH."
         print "                        Molrep or Phaser are valid mr programs."
         print ""
         sys.exit(1)

      return keywords.MR_PROGRAM_LIST

         

   
         

   





