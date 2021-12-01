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
#This script contains code to output all variables from the job to dump files. This
#is purly for testing purposes so the job can be started at any point.
#
#Ronan Keegan 21/12/04

import os, sys, string, pickle


class Dump_all:
   """ A class to dump all variables from the code. """

   def __init__(self):
      self.dump_dir=''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
	
   def setDumpDIR(selt, dump_dir):
      self.dump_dir = dump_dir

   def write_out_models(self, mstat, dump_file):
      """ Testing only. Dump everything in to files so that it can be read in again later. """
      
      mstat.setPickleFile(dump_file)

      # Dump the chain details.
      f=open(mstat.pickle_file, 'w')
      pickle.dump(mstat,f)
      f.close()

   def write_out_target(self, target_info, dump_file):
      """ Testing only. Dump everything in to files so that it can be read in again later. """
      
      target_info.setPickleFile(dump_file)

      # Dump the target details.
      t=open(target_info.pickle_file, 'w')
      pickle.dump(target_info,t)
      t.close()

   def read_in_models(self, mstat, dump_file):
      """ A function to read in the data from the dump files """

      mstat.setPickleFile(dump_file)

      # Open the piclke file for reading
      f=open(mstat.pickle_file, 'r')
      mstat=pickle.load(f)
      f.close()

      # Set the pickle file again for completness
      mstat.setPickleFile(dump_file)

   def read_in_target(self, target_info, dump_file):
      """ A function to read in the data from the dump files """

      target_info.setPickleFile(dump_file)

      # Open the piclke file for reading
      t=open(target_info.pickle_file, 'r')
      target_info=pickle.load(t)
      t.close()

      # Set the pickle file again for completness
      target_info.setPickleFile(dump_file)
