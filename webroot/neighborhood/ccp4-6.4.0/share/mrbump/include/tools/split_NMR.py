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
# Script to extract all or one model(s) from an NMR PDB file.
# Ronan Keegan 29/08/06


import os, sys, string
import shutil

class Split_NMR:

   def __init__(self):
      self.pdb_file = ""
      self.pdb_header = ""
      self.pdb_tail = ""
      self.chain_name = ""

      self.out_PDBname = []

      self.model_count = 0
      self.model_coord_dict = dict([]) 

      self.model_found = False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def setPDBfile(self, filename):
      """ Set the input PDB filename. """

      self.pdb_file = filename
      self.chain_name = os.path.split(filename)[-1][0:4]

      if self.debug:
         sys.stdout.write("NMR processing: Chain name = %s PDB file:\n   %s\n" % (self.chain_name, self.pdb_file)) 
         sys.stdout.write("\n") 

   def read_header(self, model=0):
      """ A function to read the header of the PDB file """

      f=open(self.pdb_file, "r")

      line = f.readline()
  
      # Read and record the file details until the first model is encountered
      while line:
         if "MODEL" not in line[0:5] and "ATOM" not in line [0:5]:
            # If only one model in file, then don't output NUMMDL
            if model==0 or "NUMMDL" not in line[0:6]:
               self.pdb_header += line
         else:
            break
         line = f.readline()
            
      f.close()

   def read_models(self, model=0):
      """ A function to read each of the models of the PDB file """

      f=open(self.pdb_file, "r")

      line = f.readline()
      model_coords = ""
  
      # Read all of the models into the model dictionary
      while line:
         if "MODEL" in line[0:5]:
            self.model_found = True
            self.model_count = self.model_count + 1
            model_num = int(string.split(line)[1])
            # COORD_FORMAT doesn't like "MODEL   1" - exits with "Duplicate model number" error
            # So omit it when there's only a single model
            if model==0:
               model_coords += line
            coord_line = f.readline()
            while coord_line:
               if "ENDMDL" not in coord_line:
                  model_coords += coord_line
               else:
                  self.model_coord_dict[model_num] = model_coords
                  model_coords = ""
                  break
               coord_line = f.readline()
         line = f.readline()

      f.close()
    
   def read_tail(self):
      """ A function to read the tail of the PDB file. """
          
      f=open(self.pdb_file, "r")

      line = f.readline()
      count = 0
           
      # Loop over the file until the end of the last model is encountered and then record the tail of the file
      while line:
         if "ENDMDL" in line[0:6]:
            count = count + 1
         if count == self.model_count:
            if "ENDMDL" not in line[0:6]:
               self.pdb_tail += line
         
         line = f.readline()

      f.close()

   def read_PDB(self, model=0):
      """ A function to read the details from the input PDB file. """

      # Call each of the reading functions
      self.read_header(model)
      self.read_models(model)
      self.read_tail()

   def write_models(self, model=0):
      """ A function to write out each of the models to separate PDB files. 
          model argument=0 for write all models or an integer > 0 for only
          a specific model. """
     
      # if no MODEL records where found we assume that only one model exists in the file and we copy that to the new
      # file naeme.
      if self.model_found == False:
         shutil.copy(self.pdb_file, self.chain_name + "_1.pdb")
         self.out_PDBname.append(self.chain_name + "_1.pdb")

      else:
         # Test the input value for model to make sure it's reasonable    
         if `model`.isdigit() == False:
            sys.stdout.write("Output Error: Invalid value for 'model' argument in write_models: %s\n" % `model`)
            sys.stdout.write("\n")
            sys.exit(1)
   
         if model > self.model_count:
            sys.stdout.write("Output Error: Value for 'model' argument is too high\n")
            sys.stdout.write("              There are %d models in the input PDB\n" % self.model_count)
            sys.stdout.write("\n")
            sys.exit(1)
   
         # Write out the new PDB files containing each of the models (all or one)
         if model == 0:
            for model_num in self.model_coord_dict.keys():
               self.out_PDBname.append(self.chain_name + "_" + `model_num` + ".pdb")
   
               o=open(self.chain_name + "_" + `model_num` + ".pdb", "w") 
               o.write(self.pdb_header)
               o.write(self.model_coord_dict[model_num])
               o.write(self.pdb_tail)
               o.close()
         else: 
            self.out_PDBname.append(self.chain_name + "_" + `model` + ".pdb")
   
            o=open(self.chain_name + "_" + `model` + ".pdb", "w") 
            o.write(self.pdb_header)
            o.write(self.model_coord_dict[model])
            o.write(self.pdb_tail)
            o.close()

if __name__ == "__main__":

   if len(sys.argv) != 3:
      print "Usage: split_NMR.py <PDB file> <Model No.>"
      print "     (Model No.=0 for all models to be written out)"
      sys.exit()

   nmr=Split_NMR()
   nmr.setPDBfile(sys.argv[1])

   nmr.read_PDB(int(sys.argv[2]))
   nmr.write_models(int(sys.argv[2]))
