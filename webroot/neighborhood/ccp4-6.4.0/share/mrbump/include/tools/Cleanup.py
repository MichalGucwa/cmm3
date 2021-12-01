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
#Function to clean up a remove surplus data at the end of a job
#Ronan Keegan 11.10.05

import os, sys, string
import shutil

class Clean:

   def __init__(self):
      self.file_list=[]
      self.dir_list=[]

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def rm_dir(self, directory):
      """ A function to clean out all of the downloaded PDB files. """

      shutil.rmtree(directory)

   def clean_data_dir(self, mstat):
      """ A function to clean out the data folder. Leaves good and marginal solutions. """

      # Clean out the PDB_files dir first:
      PDB_files=os.path.join(mstat.search_dir, "PDB_files")
      if os.path.isdir(PDB_files):
         for file in os.listdir(PDB_files):
            os.remove(os.path.join(PDB_files, file))
            
      for model in mstat.model_list.keys():
         if mstat.model_list[model].poor_solution_MOLREP == True and mstat.model_list[model].poor_solution_PHASER == True:
            if os.path.isdir(mstat.model_list[model].model_directory):

               # If we are on Windows we only remove the files (to avoid the rmtree Windows bug)
               if os.name=="nt":

                  # Reset the file and directory lists to be empty
                  self.file_list=[]
                  self.dir_list=[]

                  # List the contents of the model directory   
                  self.list_dir(mstat.model_list[model].model_directory)

                  # Remove the files
                  for file in self.file_list:
                     os.remove(file)
               else:
                  shutil.rmtree(mstat.model_list[model].model_directory)
     
         
   def list_dir(self, startDir):
      """ Recurrsively loop through a directory and list all files and subdirectories """

      directories = [startDir]
      while len(directories)>0:
          directory = directories.pop()
          for name in os.listdir(directory):
              fullpath = os.path.join(directory,name)
      
              # if its a file add it to the file list
              if os.path.isfile(fullpath):
                  self.file_list.append(fullpath)  
      
              # if its a directory add it to the directory lists 
              elif os.path.isdir(fullpath):
                  directories.append(fullpath)  
                  self.dir_list.append(fullpath)

   def purgeDirectory(self, purgeDir, Except=[]):
      """ Clean out the contents of directory and leave a Readme explaining what has been removed. For LITE mode """

      if os.path.isdir(purgeDir):
         dirContents=os.listdir(purgeDir)
         readme=open(os.path.join(purgeDir, "Readme.txt"), "w")
         readme.write("MrBUMP ran with keyword 'LITE' - surplus files have been deleted\n")
         readme.write("Re-run using the '.sh' script in this folder or MrBUMP with LITE=False if you wish to view deleted files\n")
         readme.write("The following files have been removed:\n\n")
         count=0
         for filename in dirContents:
            if (os.path.splitext(filename)[-1].replace(".","")).lower() not in Except:
               if os.path.isfile(os.path.join(purgeDir, filename)) and filename[-4:] != ".log":
                  os.remove(os.path.join(purgeDir, filename))
                  count=count+1
                  readme.write("%d. %s\n" %(count, filename))
         if count==0:
            readme.write("no files were deleted\n")
         readme.close()
 
