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
# Setup Ensemble for Phaser MR
# Ronan Keegan 12/12/04 
#

import os, sys, string
import shutil
import mol_weight
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 must be defined'

import Model_struct

class Ensemble:
   """ A class to construct an ensemble of the top match PDBs for Phaser. """

   def __init__(self):
      if os.name == "nt":
         self.superposeEXE=os.path.join(os.environ['CBIN'], 'superpose.exe') 
         self.pdbsetEXE=os.path.join(os.environ['CBIN'], 'pdbset.exe') 
      else:
         self.superposeEXE=os.path.join(os.environ['CBIN'], 'superpose') 
         self.pdbsetEXE=os.path.join(os.environ['CBIN'], 'pdbset') 
 
      self.SPxyz_template=''
      self.SPxyzin=''
      self.SPxyzout=''

      self.SP_logfile='' 
      self.SP_logfile_last='' 
      self.DB_fail=False

      self.num_per_ensem=0
      self.base_MW=0
      self.meanMW=0
      self.total_MW_ensem=0
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag

   def setSPXYZ_TEMPLATE(self, xyzin):
      self.SPxyz_template=xyzin

   def setSPXYZIN(self, xyzin):
      self.SPxyzin=xyzin

   def setSPXYZOUT(self, xyzout):
      self.SPxyzout=xyzout

   def setSPLOGFILE(self, filename):
      self.SP_logfile=filename

   def setSPLOGFILELAST(self, filename):
      self.SP_logfile_last=filename

   def setNumPerEnsem(self, num_per_ensem):
      self.num_per_ensem=num_per_ensem

   def setup_ensemble(self, mstat, init):
      """  A function to setup structure data for running Phaser with ensembles. Calls superpose
      to line up each of the template structures with each other. """

      # ensemble count
      ecount=0

      sys.stdout.write("Number of Ensembles: %d\n" % init.keywords.ENSNUM)
      sys.stdout.write("Number of search models in each Ensemble: %d\n" % init.keywords.ENSMODNUM)
      print ""

      while ecount < init.keywords.ENSNUM:

         # model count
         mcount=0

         # Set up the model list entry
         m=Model_struct.Models_struct()
         m.setNumPerEnsem(init.keywords.ENSMODNUM)
         m.setModelChainSource('ensemble_model')
         m.setPDBName('ensm')
         m.setModelName('ensemble_model%d'%ecount)
         m.setModelType('ENSMBL')
         m.setModel_directory(os.path.join(init.search_dir, 'data', 'ensemble_model%d'%ecount))

         # Create the directory structure
         os.mkdir(m.model_directory) 
         os.mkdir(os.path.join(m.model_directory, "mr")) 
         os.mkdir(os.path.join(m.model_directory, "mr", "pdbfiles")) 
         os.mkdir(os.path.join(m.model_directory, "mr", "logs")) 
         os.mkdir(os.path.join(m.model_directory, "mr", "tmp")) 
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(m.model_directory, 'mr', 'molrep'))
            os.mkdir(os.path.join(m.model_directory, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(m.model_directory, 'mr', 'phaser'))
            os.mkdir(os.path.join(m.model_directory, 'mr', 'phaser', 'refine'))

         self.setSPLOGFILE(os.path.join(m.model_directory, 'mr', 'logs', 'superpose.log'))
         self.setSPLOGFILELAST(os.path.join(m.model_directory, 'mr', 'logs', 'superpose_last.log'))
         full_log=open(self.SP_logfile,'w')


         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try:
               job_ID=mstat.conn.AddSubJob( \
                   init.ProjectName,init.JobId,
                   "Superpose",
                   "Superpose the top models to create and ensemble for superpose")

               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Superpose")
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
               #  "Superpose the top models to create and ensemble for superpose")
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")

               #mstat.conn.SetLogfile(init.ProjectName, job_ID, model.superpose_logfile)
               self.DB_fail=False 
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Superpose job\n")
               sys.stdout.write("\n")
   
         if ecount<len(mstat.sorted_MR_list):
            rotated_chain_list = mstat.sorted_MR_list[ecount:]+mstat.sorted_MR_list[:ecount]
         else:
            sys.stdout.write("Warning: cannot make more ensembles\n")
            break
         for chain in rotated_chain_list:

            # We only want to include monomers and domains in the ensemble, ignore multimers
            if mstat.chain_list[chain].source != "PQS" or mstat.chain_list[chain].source != "PISA":
            #if chain[5] not in ['0','1','2','3','4','5','6','7','8','9']:
            # First setup the chain details. If there is no chain for a pdb we just 
            # set the chain details to be a blank space in the superpose command line.

               # Use the chainsaw PDB file if available, otherwise use the original
               if os.path.isfile(mstat.chain_list[chain].chainsaw_modelPDB):
                  input_PDBFile = mstat.chain_list[chain].chainsaw_modelPDB
               elif os.path.isfile(mstat.chain_list[chain].molrep_modelPDB):
                  input_PDBFile = mstat.chain_list[chain].molrep_modelPDB
               elif os.path.isfile(mstat.chain_list[chain].plyala_modelPDB):
                  input_PDBFile = mstat.chain_list[chain].plyala_modelPDB
               else:
                  input_PDBFile = mstat.chain_list[chain].PDBFile 
               print ""

            # Top match entry will be our base alignment.  
               if mcount == 0:
                  print "Ensemble number %d\n"%(ecount+1)
                  print "Base alignment model = %s" % chain
                  print "Source:", mstat.chain_list[chain].source
                  sys.stdout.write("Using Superpose to line models up. Superpose log:\n")
                  sys.stdout.write("   %s\n" % self.SP_logfile)
               
                  # Set the chain identifier. Catch for when it is not specified and it is part of a domain.
                  splitchain=string.split(chain, "_")
                  if len(splitchain) == 1:
                     chainID=""
                  else:
                     chainID=(splitchain[1][0]).upper()

                  mw = mol_weight.MolWeight()
                  current_MW = mw.get_pdbMW(input_PDBFile, chain=chainID)
                  self.meanMW = current_MW
                  #self.base_MW = current_MW
                  self.total_MW_ensem = current_MW
                  sys.stdout.write("Molecular weight of base alignment model = %.1f\n" % current_MW)

                  # Set the template structure for the ensemble superposition
                  self.setSPXYZ_TEMPLATE(input_PDBFile)
                  self.setSPXYZOUT(os.path.join(m.model_directory, 'mr', 'pdbfiles', mstat.chain_list[chain].chainName + '_superpose.pdb'))
                  shutil.copyfile(self.SPxyz_template, self.SPxyzout)

               # All other entries will be aligned to top match 
               else:               

                  print "Alignment model %d is %s" % (mcount, chain)
                  print "Source:", mstat.chain_list[chain].source

                  # Set the chain identifier. Catch for when it is not specified and it is part of a domain.
                  splitchain=string.split(chain, "_")
                  if len(splitchain) == 1:
                     chainID=""
                  else:
                     chainID=(splitchain[1][0]).upper()

                  current_MW = mw.get_pdbMW(input_PDBFile, chain=chainID)
                  print "Molecular weight of alignment model = %.1f" % current_MW
                  percent_diff = (current_MW - self.meanMW) * 100.0 / self.meanMW

                  if abs(percent_diff) > 10.0:
                     print "WARNING: Deviation of base alignment model MW (%.2f %%) from mean too large" % percent_diff
                     print "WARNING: Skipping model"
                     print ""
                     continue
                  else:
                     if self.debug:
                        print "Current average molecular weight = %.1f" % self.meanMW
                        print "Deviation of base alignment model from mean = %.2f %%" % percent_diff
                     self.total_MW_ensem += current_MW
                     self.meanMW=self.total_MW_ensem/(mcount+1)
                  
                  

                  #self.total_MW_ensem += current_MW
                  #mean_MW_ensem = self.total_MW_ensem / (mcount+1)
                  #percent_diff = (self.base_MW - mean_MW_ensem) * 100.0 / mean_MW_ensem
                  #print "Molecular weight of alignment model = %.1f" % current_MW
                  #if self.debug:
                  #   print "Current average molecular weight = %.1f" % mean_MW_ensem
                  #   print "Deviation of base alignment model from mean = %.2f %%" % percent_diff
                  #if abs(percent_diff) > 10.0:
                  #   print "WARNING: Deviation of base alignment model MW (%.2f %%) from mean too large" % percent_diff
                  #   print "WARNING: Stopping here with %d models in the ensemble" % mcount
                  #   print ""
                  #   break

                  self.setSPXYZIN(input_PDBFile)
                  self.setSPXYZOUT(os.path.join(m.model_directory, 'mr', 'pdbfiles', mstat.chain_list[chain].chainName + '_superpose.pdb'))

                  # Set the command line
                  command_line = self.superposeEXE + " "  + self.SPxyzin  + " " + self.SPxyz_template + " -p " + self.SPxyzout 
           
                  # Launch superpose
                  if os.name == "nt":
                     process_args = shlex.split(command_line, posix=False)
                     p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                       stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
                  else:
                     process_args = shlex.split(command_line)
                     p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                       stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

                  (o, i) = (p.stdout, p.stdin)
            
                  i.close()

                  # Capture the output from superpose
                  log=open(self.SP_logfile_last, "w")
                  line=o.readline()
                  while line:
                     log.write(line)
                     line=o.readline()
                  o.close()
                  log.close()

                  last_log=open(self.SP_logfile_last, 'r')
                  line = last_log.readline()
                  while line:
                    # copy to full log file, that is kept
                    full_log.write(line)
                    # extract info from current log file
                    if 'RMSD' in line and "=" in line:
                       rmsd_index = string.split(line).index('RMSD')
                       rmsd = float(string.split(line)[rmsd_index+2].replace(",", ""))
                       align_length = int(string.split(line)[-1])
                       print "which aligns to base model with RMSD = %.3f over %d residues" % (rmsd,align_length)
                    line = last_log.readline()
                  last_log.close()

               # Add the input and Output files to the DB record
               if init.keywords.DBOUT and self.DB_fail == False:
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, input_PDBFile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, self.SPxyzout)

               # Add this pdb code to the ensemble list (along with its seq ID and rms value)

               m.PDBfile.append(self.SPxyzout)
               m.seqID.append(mstat.chain_list[chain].seqID)
               m.rms.append(mstat.chain_list[chain].rms)
         
               # When we reach the number of ensemble structures to be used, break out.
               mcount=mcount+1
               if mcount >= m.num_per_ensem:
                  print ""
                  break 

               # If there are too many models in each ensemble, reduce
               if mcount >= len(rotated_chain_list)-1:
                  print "Warning: number of models in each ensemble reduced to %d to ensure ensemble uniqueness\n"%mcount
                  m.num_per_ensem = mcount
                  break

         full_log.close()

         # Add the superpose log file to the DB record
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetLogfile(init.ProjectName, job_ID, self.SP_logfile)

         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

         if mcount < m.num_per_ensem:
            m.num_per_ensem = mcount

         # Add the ensemble to the model list      
         mstat.model_list[m.name]=m
       
         # Insert the ensemble at the top of the sorted list
         mstat.sorted_model_list.insert(0,m.name)
         ecount += 1 
