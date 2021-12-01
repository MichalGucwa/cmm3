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
# Script to check if an executable is in the system PATH
# Ronan Keegan 12/12/05
#
# Update 11/1/06: Fixed last PATH entry bug.

import os
import sys
import string

class Check_PATH:
   """ A class to check for the existence of an executable in the environemnt PATH. """

   def __init__(self):
      self.list=[]
      self.folder_name=[]
      self.path_list=[]
      self.exe_found=False
      self.exe_directory=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def get_path_list(self):
      """ Function to construct a list of the directories in the system path. """

      # Readin the path environment
      bin_path=os.environ["PATH"]

      # Make a list of the characters in the PATH 
      for i in bin_path:
         self.list.append(i)

      # Seperate out each directory in the path list
      for i in self.list:
         if os.name == "posix" and i != ":":
            self.folder_name.append(i)
         elif os.name == "nt" and i != ";":
            self.folder_name.append(i)
         else:
            f=string.join(self.folder_name,'')
            self.path_list.append(f)
            self.folder_name = []
   
      # Append the final directory in the PATH
      f=string.join(self.folder_name,'')
      self.path_list.append(f)

   def find_exec(self, executable, debug=False):
      """ Function to ascertain as to whether an executable exists in the system path.
          Returns: booleen """

      self.exe_found=False

      # Construct the path list
      self.get_path_list()

      # If running under windows add '.exe' extension to executable (if not there already)
      if os.name == "nt" and executable[-4:] != ".exe":
         executable = executable + ".exe"   

      # Check to see if the executable exists in any of the PATH directories
      for dir in self.path_list:
         if os.path.isfile(os.path.join(dir, executable)):
            self.exe_found = True
            self.exe_directory = dir
            if debug:
               sys.stdout.write("\n")
               sys.stdout.write(executable + " found in " +  dir + "\n")
               sys.stdout.write("\n")

         if debug:
            sys.stdout.write(dir + "\n")
            
      if self.exe_found == False:
         sys.stdout.write(executable + " not found in PATH\n")
     
      return self.exe_found

if __name__ == '__main__':

   chk=Check_PATH()
   chk.debug=False
   chk.find_exec('ls')
   chk.debug=False
   print chk.find_exec('clustalw2')
