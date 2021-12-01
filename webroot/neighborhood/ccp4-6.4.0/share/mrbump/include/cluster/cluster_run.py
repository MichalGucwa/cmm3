#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A script to run MR and refinement on a cluster node. Acts as a stadn-alone executable.
# Ronan Keegan - 31/1/07
#


import os, sys, string
import shutil

import molrepEXE
import phaserEXE
import refmacEXE
import pdbtools

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

#if os.environ.has_key('MRBUMP_CLUSTER'):
#if os.environ["MRBUMP_CLUSTER"] == True:
sys.path.append(os.path.join(os.environ["CCP4"], "share", "mrbump", "include", "building"))

import MRBUMP_Shelxe


class ClusterJob:
   """ A class to handle the running of MR and refinement on a cluster. """

   def __init__(self):
     
      self.MRPROGRAM=""
      self.working_DIR=""

      self.hklin_SG=""
      self.hklin_SG_Code=""
      self.enant_SG_Code=""

      self.hklin1=""
      self.hklin2=""
      self.refine_hklin=""
      self.phaser_hklout=""

      self.mr_log=""

      self.pdbin_list=[]
      self.pdbout=""
      self.pdbout1=""
      self.pdbout2=""

      self.refine_hklout=""
      self.refine_pdbout=""
      self.refine_log=""
      self.refineRB_hklout=""
      self.refineRB_pdbout=""
      self.refineRB_log=""
      self.RBODREF = False
      self.ENANT=False

      self.shelxeEXE = "shelxe"
      self.SHELXE = False
      self.FP = "FP"
      self.SIGFP = "SIGFP"
      self.FREE = "FREE"
      self.solvent=0.0
      self.resolution=0.0
      self.shelxe_pdbout="shelxe-pdbout.pdb"


      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False
      

   def parse_input(self, input_file):
      """ A function to parse the input file for the parameters and filenames for MR and refinement. """

      # Check that input file exists
      if os.path.isfile(input_file) == False:
         sys.stdout.write("Cluster Log: Input parameter file not found\n")
         sys.stdout.write("\n")
      # Read the input parameters according to their four letter keys
      else:
         infile=open(input_file, "r")
         line=string.split(infile.readline())

         while line:
            if "DIRE" in line[0].upper():
               self.working_DIR=line[1]
            if "SGIN" in line[0].upper():
               self.hklin_SG=line[1]
            if "HKL1" in line[0].upper():
               self.hklin1=line[1]
            if "HKL2" in line[0].upper():
               self.hklin2=line[1]
            if "HKLR" in line[0].upper():
               self.refine_hklin=line[1]
            if "HKLO" in line[0].upper():
               self.phaser_hklout=line[1]
            if "PDBO" in line[0].upper():
               self.pdbout=line[1]
            if "MRLO" in line[0].upper():
               self.mr_log=line[1]
            if "REFH" in line[0].upper():
               self.refine_hklout=line[1]
            if "REFP" in line[0].upper():
               self.refine_pdbout=line[1]
            if "REFL" in line[0].upper():
               self.refine_log=line[1]
            if "RBRH" in line[0].upper():
               self.refineRB_hklout=line[1]
            if "RBRP" in line[0].upper():
               self.refineRB_pdbout=line[1]
            if "RBRL" in line[0].upper():
               self.refineRB_log=line[1]
            if "FPIN" in line[0].upper():
               self.FP=line[1]
            if "SIGF" in line[0].upper():
               self.SIGFP=line[1]
            if "FREE" in line[0].upper():
               self.FREE=line[1]
            if "SOLV" in line[0].upper():
               self.solvent=float(line[1])
            if "RESO" in line[0].upper():
               self.resolution=float(line[1])
            if "SHLP" in line[0].upper():
               self.shelxe_pdbout=line[1]
            if "SEXE" in line[0].upper():
               self.shelxeEXE=line[1]
            if "SHEL" in line[0].upper():
               if line[1].upper() == "TRUE":
                  self.SHELXE=True
               else:
                  self.SHELXE=False
            if "ENAN" in line[0].upper():
               if line[1].upper() == "TRUE":
                  self.ENANT=True
               else:
                  self.ENANT=False

            # An arbitrary number of PDB model files may be passed in so we need to reconstruct
            # this list of files. For Molrep 1st one in list is model
            if "PDBI" in line[0].upper():
               for filename in line[1:]: 
                  self.pdbin_list.append(filename)
        
            line=string.split(infile.readline())

         infile.close()

   def run(self, MRPROGRAM, refine_program, mr_keyfile, refineRB_keyfile="", refine_keyfile=""):
      """ A function to run MR and refinement on a cluster node. """

      # Check to see if Rigid Body refinement has been called for
      if refineRB_keyfile != "":
         self.RBODREF = True

      # Change directory to the mr directory for this model
      os.chdir(os.path.join(self.working_DIR, "mr", MRPROGRAM.lower()))

      if MRPROGRAM.upper() == "MOLREP":   
         self.MRPROGRAM = "MOLREP"

         # Instantiate the class
         molrep_job1=molrepEXE.MolrepEXE()

         molrep_job1.local_debug=True

         # Determine the spacegroup code for the enantiomorph
         if self.ENANT:
            self.hklin_SG_Code=molrep_job1.SG_Codes[self.hklin_SG]   
            self.pdbout1 = os.path.join(self.working_DIR, "mr", "molrep", "molrep_pdbout_" + self.hklin_SG_Code + ".pdb")
            # Set the log file for this run of molrep
            molrep1_log=os.path.join(self.working_DIR, "mr", "molrep", "molrep1_" + self.hklin_SG_Code + ".log")
         else:
            self.pdbout1 = os.path.join(self.working_DIR, "mr", "molrep", "molrep_pdbout.pdb")
            # Set the log file for this run of molrep
            molrep1_log=os.path.join(self.working_DIR, "mr", "molrep", "molrep1.log")

         # Run Molrep
         molrep_job1.run(os.path.join(self.working_DIR, "mr", "molrep"), \
                         self.hklin1, \
                         self.pdbin_list[0], \
                         self.pdbout1, \
                         molrep1_log, \
                         molrepDir=os.path.join(self.working_DIR, "mr", MRPROGRAM.lower()), \
                         keyfile=mr_keyfile)

         # Extract contrast value for this job
         molrep_job1.check_contrast()

         # Search in the enantiomorphic spacegroup
         if self.ENANT:
            self.enant_SG_Code=molrep_job1.ENANT_SG[self.hklin_SG_Code]
            self.pdbout2 = os.path.join(self.working_DIR, "mr", "molrep", "molrep_pdbout_" + self.enant_SG_Code + ".pdb")
      
            # Instantiate the class
            molrep_job2=molrepEXE.MolrepEXE()
      
            molrep_job2.local_debug=True
      
            # Check that NOSG line is not already in the mr keyword file
            file=open(mr_keyfile, "r")
            line=file.readline()
            found=False
            while line:
               if "NOSG" in string.split(line)[0].upper(): 
                  found=True
               line=file.readline()
            file.close()

            # Update the keyword input file to search in enantiomorphic SG
            if found==False:
               file=open(mr_keyfile, "a")
               file.write("NOSG " + self.enant_SG_Code)
               file.close()
       
            # Set the log file for this run of molrep
            molrep2_log=os.path.join(self.working_DIR, "mr", "molrep", "molrep2_" + self.enant_SG_Code + ".log")

            # Run Molrep in enantiomorphic SG, translation function only 
            molrep_job2.run(os.path.join(self.working_DIR, "mr", "molrep"), \
                            self.hklin1, \
                            self.pdbin_list[0], \
                            self.pdbout2, \
                            molrep2_log, \
                            molrepDir=os.path.join(self.working_DIR, "mr", MRPROGRAM.lower()), \
                            mode="T", \
                            keyfile=mr_keyfile)
      
            # Extract contrast value for this job
            molrep_job2.check_contrast()

            print "Final contrast for HKLIN : %.3f" % molrep_job1.contrast
            print "Final contrast for Enant : %.3f" % molrep_job2.contrast
       
            if molrep_job1.contrast >= molrep_job2.contrast:
               shutil.copy(self.pdbout1, self.pdbout)   
               shutil.copy(self.hklin1, self.refine_hklin)   
               shutil.copy(molrep1_log, self.mr_log)   
            else:
               shutil.copy(self.pdbout2, self.pdbout)   
               shutil.copy(self.hklin2, self.refine_hklin)   
               shutil.copy(molrep2_log, self.mr_log)   
         else:
            print "Final contrast for HKLIN : %.3f" % molrep_job1.contrast
            shutil.copy(self.pdbout1, self.pdbout)   
            if os.path.isfile(self.refine_hklin) == False:
               shutil.copy(self.hklin1, self.refine_hklin)   
            shutil.copy(molrep1_log, self.mr_log)   

      elif MRPROGRAM.upper() == "PHASER":   
         self.MRPROGRAM = "PHASER"

         # Instantiate the class
         phaser_job=phaserEXE.PhaserEXE()

         phaser_job.local_debug=True

         # Set the script file for running phaser on the cluster
         phaser_job_script = os.path.join(self.working_DIR, "mr", "phaser", "phaser_job_script.txt")

         # Run Phaser
         phaser_job.run(os.path.join(self.working_DIR, "mr", "phaser"), self.phaser_hklout, self.pdbout, self.mr_log, script=phaser_job_script, keyfile=mr_keyfile)

         # Check the spacegroup of the Phaser solution
         phaser_job.check_SG(self.phaser_hklout)

         # Report the spacegroup of the solution and setup the input MTZ file for refinement
         sys.stdout.write("MR log: Spacegroup of solution from Phaser is: %s\n" % phaser_job.soln_spacegroup)
         if string.strip(phaser_job.soln_spacegroup).replace(" ","").lower() \
               == string.strip(self.hklin_SG).replace(" ","").lower():
            sys.stdout.write("        - this is the spacegroup of the input target MTZ file\n")

            # Copy the input MTZ file to the MTZ file to be processed in refinement
            if os.path.isfile(self.refine_hklin) == False:
               shutil.copyfile(self.hklin1, self.refine_hklin)
         elif self.ENANT:
            sys.stdout.write("        - this is the enantiomorphic spacegroup of the target data\n")

            # Copy the reindexed input MTZ file to the MTZ file to be processed in refinement  
            if os.path.exists(self.hklin2):
               shutil.copyfile(self.hklin2, self.refine_hklin)
            #model.enant_solution=True (Not used in CLUSTER mode)
         else:
            # Copy the input MTZ file to the MTZ file to be processed in refinement  
            shutil.copyfile(self.hklin1, self.refine_hklin)
            #model.enant_solution=False (Not used in CLUSTER mode)
   
         sys.stdout.write("\n")

      # Get the number of molecules found
      details=pdbtools.Get_PDB_Details()
      details.get_details(self.pdbout)
     
      # Create summary of the PDB file using pdbcur
      #details.pdbcur(pdbcur_logfile, pdbout)
      
      sys.stdout.write("Number of molecules found in %s : %d\n" % (self.pdbout, details.mol_count))
      sys.stdout.write("\n")
      
      # Setup a refmac job

      # Rigid Body first if asked for
      if self.RBODREF:
         refmacRB_job=refmacEXE.RefmacEXE()
         refmacRB_job.local_debug = True
 
         # Run refmac
         refmacRB_job.run(self.refine_hklin, \
                          self.refineRB_hklout, \
                          self.pdbout, \
                          self.refineRB_pdbout, \
                          self.refineRB_log, \
                          "Rigid Body Refinement", \
                          refineDir=os.path.join(self.working_DIR, "mr", MRPROGRAM.lower(), "refine"), \
                          keyfile=refineRB_keyfile)

      # Restrained refinement  
      refmac_job=refmacEXE.RefmacEXE()
      refmac_job.local_debug = True
    
      # Set the correct input model file
      if self.RBODREF: 
         refmacRR_PDBINfile=self.refineRB_pdbout
      else:
         refmacRR_PDBINfile=self.pdbout
 
      # Run refmac
      refmac_job.run(self.refine_hklin, \
                     self.refine_hklout, \
                     refmacRR_PDBINfile, \
                     self.refine_pdbout, \
                     self.refine_log, \
                     "Restrained Refinement", \
                     refineDir=os.path.join(self.working_DIR, "mr", MRPROGRAM.lower(), "refine"), \
                     keyfile=refine_keyfile)

      # C-alpha tracing with Shelxe   
      if self.SHELXE:
         if os.path.isfile(self.refine_pdbout):
            shelxe_job=MRBUMP_Shelxe.Shelxe()
       
            # Set the correct input model and mtz files
            shelxe_PDBINfile=self.refine_pdbout
            shelxe_MTZINfile=self.refine_hklin
       
            shelxe_job.runMtz2Various(shelxe_MTZINfile, fp=self.FP, sigfp=self.SIGFP, free=self.FREE)
            shelxe_job.runShelxe(self.solvent, self.resolution, MRPROGRAM, shelxe_PDBINfile, pdboutFile=self.shelxe_pdbout, traceCycles=15, shelxeEXE=self.shelxeEXE)
         else:
            sys.stdout.write("Error: Could not find output PDB from Refmac, can't run Shelxe\n")
            sys.stdout.write("\n")

if __name__ == "__main__":
   """ An example run. Also allows this function to be called as an executable on clusters."""

   RBODREF=False

   # Check and parse command line arguments
   if len(sys.argv) == 6:
      input_file      = sys.argv[1]
      mr_keyfile      = sys.argv[2]
      refine_keyfile  = sys.argv[3]
      MRPROGRAM       = sys.argv[4]
      refine_program  = sys.argv[5]
   elif len(sys.argv) == 7:
      input_file       = sys.argv[1]
      mr_keyfile       = sys.argv[2]
      refineRB_keyfile = sys.argv[3]
      refine_keyfile   = sys.argv[4]
      MRPROGRAM        = sys.argv[5]
      refine_program   = sys.argv[6]
      RBODREF = True
   else:
      sys.stdout.write("Usage: python cluster_run.py <input_file> <mr_keyfile> <refine_keyfile> <MRPROGRAM> <refine_program>\n")
      sys.stdout.write("\n")
      sys.exit()

   # Setup a cluster job
   cljob=ClusterJob()

   # Read the input parameters for MR and refinement
   cljob.parse_input(input_file)

   # Launch the clusterised job
   if RBODREF == True:
      cljob.run(MRPROGRAM, refine_program, mr_keyfile, refineRB_keyfile=refineRB_keyfile, refine_keyfile=refine_keyfile)
   else:
      cljob.run(MRPROGRAM, refine_program, mr_keyfile, refine_keyfile=refine_keyfile)
   
