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

import os
import sys
import string
import subprocess
import shlex

class MTZ_parse:
   """ A class to parse and store the output from mtzdmp. """

   def __init__(self):
      self.mtzdmp_EXE = os.environ["CBIN"] + "/mtzdmp"
      self.mtzdump_EXE = os.environ["CBIN"] + "/mtzdump"
      self.MTZ_file = ''
      self.no_of_columns = 0
      self.no_of_reflections = 0

      self.cell_dimensions=dict([])
      self.resolution = 0.0
      self.space_group = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
    
   def setDEBUG(self, flag):
      self.debug=flag 

   def setMTZfile(self, MTZ_file):
      self.MTZ_file =  MTZ_file

   def setNoofCols(self, no_of_columns):
      self.no_of_columns = no_of_columns
   
   def setNoofReflections(self, no_of_reflections):
      self.no_of_reflections = no_of_reflections
   
   def setCellDimensions(self, cell_dimensions_array):
      self.cell_dimensions['a'] = float(cell_dimensions_array[0])
      self.cell_dimensions['b'] = float(cell_dimensions_array[1])
      self.cell_dimensions['c'] = float(cell_dimensions_array[2])
      self.cell_dimensions['alpha'] = float(cell_dimensions_array[3])
      self.cell_dimensions['beta'] = float(cell_dimensions_array[4])
      self.cell_dimensions['gamma'] = float(cell_dimensions_array[5])
          
   def setResolution(self, resolution_array):
      self.resolution = float(resolution_array[-3])

   def setSpaceGroup(self, space_group_array):
      self.space_group = space_group_array[1].replace(' ','')


   def run_mtzdmp(self, MTZ_file_path):
     """ Run MTZDump on the input MTZ file to capture various information """
     
     if self.debug:
        sys.stdout.write("\n")
        sys.stdout.write("Preparation: Running MTZDump on the input MTZ file")
        sys.stdout.write("\n")

     self.setMTZfile(os.path.split(MTZ_file_path)[-1])
 
     # Set the command line
     command_line = self.mtzdump_EXE + " HKLIN " + MTZ_file_path
        
     if self.debug:
        sys.stdout.write("\n")
        sys.stdout.write("======================\n")
        sys.stdout.write("MTZDUMP command line:\n")
        sys.stdout.write("======================\n")
        sys.stdout.write(command_line + "\n")
        sys.stdout.write("\n")

     # Launch Mafft
     if os.name == "nt":
        process_args = shlex.split(command_line, posix=False)
        p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)
     else:
        process_args = shlex.split(command_line)
        p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)

     (child_stdout, child_stdin) = (p.stdout, p.stdin)

     child_stdin.write("END\n")
     child_stdin.close()         

     # Capture various pieces of useful information
     line = child_stdout.readline()
     while line:
        if "* Number of Columns" in line:
           self.setNoofCols(int(string.split(line)[-1]))
        if "* Number of Reflections" in line:
           self.setNoofReflections(int(string.split(line)[-1]))
        if "* Cell Dimensions :" in line:
           line = child_stdout.readline()
           line = child_stdout.readline()
           self.setCellDimensions(string.split(line))
        if "Resolution Range :" in line:
           line = child_stdout.readline()
           line = child_stdout.readline()
           self.setResolution(string.split(line))
        if "* Space group =" in line:
           self.setSpaceGroup(string.split(line,"'"))
        if self.debug:
           sys.stdout.write(line)
           
        line = child_stdout.readline()

     child_stdout.close()


if __name__ == '__main__':
 
   mtz = MTZ_parse()
   mtz.run_mtzdmp('/users/rmk65/parallel_mr/python/dev/nmol_calc/data/eg2.mtz')
   print mtz.cell_dimensions
   print mtz.resolution
   print mtz.space_group
