#e! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# An MrBUMP wrapper for running Molrep jobs
# Ronan Keegan - 8/03/06
#

import os, sys, string
import shutil, time
import molrepEXE, refmacEXE, pdbtools
import Cluster_Submit
import Matches
import MRBUMP_Shelxe
import MRBUMP_Buccaneer
import MRBUMP_ARPwARP


class Molrep:
   """ A class to submit Molrep jobs to the local machine or a batch system on a cluster. """

   def __init__(self):
      self.logfile = ""
      if os.name=="nt":
         self.molrepEXE = os.path.join(os.environ["CCP4_BIN"], "molrep.exe") 
         self.pdbcurEXE = os.path.join(os.environ["CCP4_BIN"], "pdbcur.exe")
         self.refmacEXE = os.path.join(os.environ["CCP4_BIN"], "refmac5.exe")

      else:
         self.molrepEXE = os.path.join(os.environ["CCP4_BIN"], "molrep")
         self.pdbcurEXE = os.path.join(os.environ["CCP4_BIN"], "pdbcur")
         self.refmacEXE = os.path.join(os.environ["CCP4_BIN"], "refmac5")

      # The cluster_run.py script is called as an executable if submitting to a cluster
      self.clusterEXE = os.path.join(os.environ["MRBUMP_CLUSTBIN"], "cluster_run.py") 

      self.soln_spacegroup=""
      self.soln_found=False
      self.DB_fail=False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def setLogfile(self, filename):
      self.logfile=filename

   def setMolrepKeywords(self, init, target_info, model, RFfile, SEARCH=""):
      """ Setup the molrep keywords """
       
      # Set the keywords
      model.molrep_keywords["DOC"]="Y"
      model.molrep_keywords["LABIN"]='F=' + target_info.mtz_coldata['F'] \
                                    + ' SIGF=' + target_info.mtz_coldata['SIGF']
      model.molrep_keywords["NMON"]=`target_info.no_of_mols/model.number_mols`
      model.molrep_keywords["SIM"]=`model.seqID[0]`
      # Use only basename for RFfile to stop Molrep crashing with long paths
      if os.path.isfile(os.path.join(model.model_directory, "mr", "molrep", os.path.basename(RFfile))):
         shutil.copyfile(RFfile, os.path.join(model.model_directory, "mr", "molrep", os.path.basename(RFfile)))
      model.molrep_keywords["FILE_T"]=os.path.basename(RFfile)

      # Add the spacegroup to search under if we are looking at the enantiomorph
      if SEARCH=="ENANT":
         model.molrep_keywords["NOSG"]=target_info.enant_SG_code
      
      # If a fixed component of the solution was provided we need to add the MODEL_2 keyword
      if init.keywords.FIXED:
         model.molrep_keywords["MODEL_2"]=init.molrep_fixed_PDBfile

   def setRefmacRBKeywords(self, init, model, target_info):
      """ Setup the refmac rigid body keywords """
       
      # Setup the refmac keywords Dictionary
      model.refmacRB_molrep_keywords["LABIN"]="FP=" + target_info.mtz_coldata['F'] \
                                   + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                                   + " FREE=" + target_info.mtz_coldata['FREE']
      model.refmacRB_molrep_keywords["RIGID NCYCLE"]=`init.keywords.RBNC`
      model.refmacRB_molrep_keywords["REFI"]="TYPE RIGID RESI MLKF METH CGMAT BREF OVER"
      model.refmacRB_molrep_keywords["MAKE"]="HYDR N"
      model.refmacRB_molrep_keywords["WEIGHT"]="MATRIX 0.01"
      # Add the TWIN keyword if specified
      if init.keywords.REFTWIN: 
         model.refmacRB_molrep_keywords["TWIN"]=""

   def setRefmacKeywords(self, init, model, target_info):
      """ Setup the refmac keywords """
       
      # Setup the refmac keywords Dictionary
      model.refmac_molrep_keywords["LABIN"]="FP=" + target_info.mtz_coldata['F'] \
                                   + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                                   + " FREE=" + target_info.mtz_coldata['FREE']
      model.refmac_molrep_keywords["NCYC"]=`init.keywords.NCYC`
      model.refmac_molrep_keywords["MAKE"]="HYDR N"
      model.refmac_molrep_keywords["WEIGHT"]="MATRIX 0.01"
      # Add Jelly Body refinement if required
      if init.keywords.JBODREF:
         model.refmac_molrep_keywords["RIDG"]="DIST SIGM 0.02"
      # Add the TWIN keyword if specified
      if init.keywords.REFTWIN: 
         model.refmac_molrep_keywords["TWIN"]=""

   def setSolution(self, init, spacegroup, log_filename, hklin, molrep_pdbout, model, target_info):
      """ Copy the solution files for the best result to the molrep result files. """

      # Set the spacegroup of the solution to the hklin spacegroup of the target
      self.soln_spacegroup = spacegroup

      # Set the molrep logfile to the original one
      model.setMolrepLogFile(os.path.join(model.model_directory, 'mr', 'molrep', log_filename))

      # Copy the input MTZ file to the MTZ file to be processed in refinement  
      #shutil.copyfile(hklin, target_info.MTZINfile)
      model.setRefmacMolrepMTZINfile(target_info.hklin)
      if init.keywords.RBODREF:
         model.setRefmacRBMolrepMTZINfile(target_info.hklin)
      #shutil.copyfile(hklin, model.refmac_molrep_MTZINfile)

      # Copy the output PDB file to the Molrep solution PDB
      if os.path.isfile(molrep_pdbout):
         shutil.copy(molrep_pdbout, model.molrep_PDBfile)

         # Report the spacegroup of the solution
         sys.stdout.write("MR log: Spacegroup of solution from Molrep is: %s\n" % self.soln_spacegroup)
         if string.strip(self.soln_spacegroup).replace(" ","").lower() \
               == string.strip(target_info.space_group).replace(" ","").lower():
            sys.stdout.write("        - this is the spacegroup of the input target MTZ file\n")
            model.enant_solution=False
         else:
            sys.stdout.write("        - this is the enantiomorphic spacegroup of the target data\n")
            model.enant_solution=True
        
         # Set the solution found flag to true
         self.soln_found = True

      else:
         sys.stdout.write("MR log: Error - molrepEXE: file not found: %s\n" % molrep_pdbout)

      sys.stdout.write("\n")
   

   def submit_job(self, init, mstat, model, target_info):
      """ Function to launch a molrep/refmac5 job for a given model. """

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=os.path.join(model.model_directory, "molrep_refmac_job.log") 

      # Set the rotation function solution file name
      model.molrep_RFfile=os.path.join(model.model_directory, "mr", "molrep", "molrep_RFfile.dat")

      #=================================================================================#
      #================== Run MR and refinement on the local machine ===================#
      #=================================================================================#

      if init.keywords.CLUSTER == False:

         ###############################################################################
         ############################# Running Molrep ##################################
         ###############################################################################

         molrep_job1=molrepEXE.MolrepEXE()

         # Set the rotation function output file for molrep
         molrep_job1.set_RFfile(model.molrep_RFfile)

         # Set up the keywords
         self.setMolrepKeywords(init, target_info, model, molrep_job1.RFfile)

         for keyword in model.molrep_keywords.keys():
            molrep_job1.add_keyword(keyword + " " + model.molrep_keywords[keyword])

         # Set the output PDB file
         molrep_pdbout1=os.path.join(model.model_directory, "mr", "molrep", "molrep_hklinSG_out.pdb")

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try:
               job_ID=mstat.conn.AddSubJob( \
                  init.ProjectName,init.JobId,
                  "Molrep_MR_SG_%s" % target_info.space_group,
                  "Molecular replacement using Molrep for model %s in space group %s" % (model.name, target_info.space_group))
   
               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Molrep_MR_SG_%s" % target_info.space_group)
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
               #  "Molecular replacement using Molrep for model %s in space group %s" % (model.name, target_info.space_group))
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.hklin)
               for modelfile in model.PDBfile:
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, modelfile)
               if init.keywords.FIXED:
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, init.molrep_fixed_PDBfile)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.molrep_PDBfile)
               mstat.conn.SetLogfile(init.ProjectName, job_ID, model.molrep_logfile)
               print "Finished adding new record details for Molrep 1 job"
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Molrep job\n")
               sys.stdout.write("\n")
   
         # Set the Molrep script file (1)
         model.setMolrepScriptFile1(os.path.join(model.model_directory, 'mr', 'molrep', 'molrep_script_job1.sh'))

         # Run Molrep
         molrep_job1.run(os.path.join(model.model_directory, "mr", "molrep"), \
                         target_info.hklin, \
                         model.PDBfile[0], \
                         molrep_pdbout1, \
                         model.molrep_logfile, \
                         molrepDir=os.path.join(model.model_directory, "mr", "molrep"), \
                         script=model.molrep_scriptfile1, \
                         LITE=init.keywords.LITE)
      
         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

         # Extract contrast value for this job
         molrep_job1.check_contrast()

         ###############################################################################
         ######################## Handle Enantiomorphic SG #############################
         ###############################################################################
      
         if init.keywords.ENANT:
            # Instantiate the class
            molrep_job2=molrepEXE.MolrepEXE()
      
            # Set up the keywords
            self.setMolrepKeywords(init, target_info, model, molrep_job1.RFfile, "ENANT")

            for keyword in model.molrep_keywords.keys():
               molrep_job2.add_keyword(keyword + " " + model.molrep_keywords[keyword])

            # Temporarily backup and reset the molrep logfile
            shutil.copy(model.molrep_logfile, os.path.join(model.model_directory, "mr", 'molrep', "molrep1.log"))
            model.setMolrepLogFile(os.path.join(model.model_directory, 'mr', 'molrep', 'molrep2.log'))

            # Set the output PDB file
            molrep_pdbout2=os.path.join(model.model_directory, "molrep_enantSG_out.pdb")

            # Add the job details to the DB for dbviewer
            if init.keywords.DBOUT:
               try:
                  self.DB_fail=False 
                  job_ID=mstat.conn.AddSubJob( \
                     init.ProjectName,init.JobId,
                     "Molrep_MR_SG_%s" % target_info.enant_spacegroup,
                     "Molecular replacement using Molrep for model %s in space group %s" % (model.name, target_info.enant_spacegroup))
          
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Molrep_MR_SG_%s" % target_info.enant_spacegroup)
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                  #  "Molecular replacement using Molrep for model %s in space group %s" % (model.name, target_info.enant_spacegroup))
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.hklin)
                  for modelfile in model.PDBfile:
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, modelfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, molrep_pdbout2)
                  mstat.conn.SetLogfile(init.ProjectName, job_ID, model.molrep_logfile)
                  print "Finished adding new record details for Molrep 2 job"
               except:
                  self.DB_fail=True 
                  sys.stdout.write("DB error: Could not enter a new record for Molrep job\n")
                  sys.stdout.write("\n")
   
            # Set the Molrep script file (2)
            model.setMolrepScriptFile2(os.path.join(model.model_directory, 'mr', 'molrep', 'molrep_script_job2.sh'))

            # Run Molrep in enantiomorphic SG, translation function only
            molrep_job2.run(os.path.join(model.model_directory, "mr", "molrep"), \
                            target_info.hklin, \
                            model.PDBfile[0], \
                            molrep_pdbout2, \
                            model.molrep_logfile, \
                            molrepDir=os.path.join(model.model_directory, "mr", "molrep"), \
                            script=model.molrep_scriptfile2, \
                            mode="T", \
                            LITE=init.keywords.LITE)
      
            # Set the status to be finished in the DB
            if init.keywords.DBOUT and self.DB_fail == False:
               mstat.conn.SetData(init.ProjectName, job_ID, "STATUS", "FINISHED")
            elif self.DB_fail:
               self.DB_fail=False

            # Extract contrast value for this job
            molrep_job2.check_contrast()

            # Report the outcome for the HKLIN spacegroup
            if molrep_job1.soln_found:
               sys.stdout.write("Final contrast value for HKLIN spacegroup:          %.3f\n" % molrep_job1.contrast)
            else:
               sys.stdout.write("No solution found for search using HKLIN spacegroup.\n")

            # Report the outcomr for the enantiomorph
            if molrep_job2.soln_found:
               sys.stdout.write("Final contrast value for enantiomorphic spacegroup: %.3f\n" % molrep_job2.contrast)
            else:
               sys.stdout.write("No solution found for search using enantiomorphic spacegroup.\n")
            sys.stdout.write("\n")
      
            # Check which result was better
            if molrep_job1.soln_found and molrep_job2.soln_found:
               # Compare the contrast values and copy the correct file to the output PDB
               if molrep_job1.contrast >= molrep_job2.contrast:
                  # Setup the solution details
                  self.setSolution(init, target_info.space_group, "molrep1.log", target_info.hklin, \
                                   molrep_pdbout1, model, target_info)
       
               else:
                  # Setup the solution details
                  self.setSolution(init, target_info.enant_spacegroup, "molrep2.log", target_info.enant_hklin, \
                                   molrep_pdbout2, model, target_info)
       
            elif molrep_job1.soln_found and molrep_job2.soln_found == False:
               # Setup the solution details
               self.setSolution(init, target_info.space_group, "molrep1.log", target_info.hklin, \
                                molrep_pdbout1, model, target_info)

               # Report that the enantiomorphic spacegroup molrep job failed
               if self.debug:
                  sys.stdout.write("MR log: No solution was found for model %s using Molrep in the enantiomorphic spacegroup\n" % model.name)
                  sys.stdout.write("        Log file:\n %s\n"\
                                   % os.path.join(model.model_directory, "mr", "molrep", "molrep2.log"))

            elif molrep_job2.soln_found and molrep_job1.soln_found == False:
               # Setup the solution details
               self.setSolution(init, target_info.enant_spacegroup, "molrep2.log", target_info.enant_hklin, \
                                molrep_pdbout2, model, target_info)

               # Report that the HKLIN spacegroup molrep job failed
               if self.debug: 
                  sys.stdout.write("MR log: No solution was found for model %s using Molrep in the HKLIN spacegroup\n" % model.name)
                  sys.stdout.write("        Log file:\n %s\n"\
                                   % os.path.join(model.model_directory, "mr", "molrep", "molrep1.log"))

            else:
               sys.stdout.write("MR log: No solution was found for model %s using Molrep\n" % model.name)
               sys.stdout.write("        Log file for HKLIN spacegroup:\n %s\n"\
                                % os.path.join(model.model_directory, "mr", "molrep", "molrep1.log"))
               sys.stdout.write("        Log file for enantiomorphic spacegroup:\n %s\n"\
                                % os.path.join(model.model_directory, "mr", "molrep", "molrep2.log"))
               sys.stdout.write("\n")
       
         else:
            if molrep_job1.soln_found:
               # Setup the solution details
               self.setSolution(init, target_info.space_group, "molrep.log", target_info.hklin, \
                                molrep_pdbout1, model, target_info)

            else:
               sys.stdout.write("MR log: No solution was found for model %s using Molrep\n" % model.name)
               sys.stdout.write("        Log file for HKLIN spacegroup:\n %s"\
                                % os.path.join(model.model_directory, "mr", "molrep", "molrep1.log"))
               sys.stdout.write("\n")
           
         # If a solution was found using Molrep continue with refinement
         if self.soln_found:

            ###############################################################################
            ######################### Extracting PDB details ##############################
            ###############################################################################
      
            # Get the number of molecules found
            details=pdbtools.Get_PDB_Details()
            details.get_details(model.molrep_PDBfile)
      
            model.num_models_found=details.mol_count

            # second number should be consistent with NMON keyword used
            sys.stdout.write("MR log: Molecular replacement (using Molrep) found %d copies out of %d requested\n" \
                        % (details.mol_count, target_info.no_of_mols/model.number_mols ))
            sys.stdout.write("\n")
            
            # Summarise PDB file using pdbcur
            # details.pdbcur(model.mr_pdb_sum_logfile, model.molrep_PDBfile)
             
            if init.keywords.RBODREF:

               ###############################################################################
               ########################### Running Refmac RB #################################
               ###############################################################################
         
               # Now do the refinement by calling Refmac
               refmacRB_job=refmacEXE.RefmacEXE()
         
               # Set the refmac keywords
               self.setRefmacRBKeywords(init, model, target_info)
   
               # Add them to the refmac input
               for keyword in model.refmacRB_molrep_keywords.keys():
                  refmacRB_job.add_keyword(keyword + " " + model.refmacRB_molrep_keywords[keyword])
               refmacRB_job.add_keyword('END')
    
               # Add the job details to the DB for dbviewer
               if init.keywords.DBOUT:
                  try:
                     job_ID=mstat.conn.AddSubJob(init.ProjectName,init.JobId,
                                                 "Refmac5",model.name)
         
                     #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Refmac5")
                     #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", model.name)
                     mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, model.refmac_molrep_MTZINfile)
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, model.molrep_PDBfile)
                     mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmacRB_molrep_MTZOUTfile)
                     mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmacRB_molrep_PDBfile)
                     mstat.conn.SetLogfile(init.ProjectName, job_ID, model.refmacRB_molrep_logfile)
                     print "Finished adding new record details for Refmac job"
                  except:
                     self.DB_fail=True 
                     sys.stdout.write("DB error: Could not enter a new record for Refmac RB job (post Molrep)\n")
                     sys.stdout.write("\n")
         
               # Run refmac Rigid Body
               refmacRB_job.run(model.refmac_molrep_MTZINfile, \
                                model.refmacRB_molrep_MTZOUTfile, \
                                model.molrep_PDBfile, \
                                model.refmacRB_molrep_PDBfile, \
                                model.refmacRB_molrep_logfile, \
                                "Rigid Body", \
                                refineDir=os.path.join(model.model_directory, "mr", "molrep", "refine"), \
                                script=os.path.join(model.model_directory, "mr", "molrep", "refine", "refmacRB_molrep_run_script.sh"), \
                                LITE=init.keywords.LITE)
   
               # Set the status to be finished in the DB
               if init.keywords.DBOUT and self.DB_fail == False:
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
               elif self.DB_fail:
                  self.DB_fail=False

           
            ###############################################################################
            ############################# Running Refmac ##################################
            ###############################################################################
      
            # Now do the refinement by calling Refmac
            refmac_job=refmacEXE.RefmacEXE()
      
            # Set the refmac keywords
            self.setRefmacKeywords(init, model, target_info)

            # Add them to the refmac input
            for keyword in model.refmac_molrep_keywords.keys():
               refmac_job.add_keyword(keyword + " " + model.refmac_molrep_keywords[keyword])
            refmac_job.add_keyword('END')
 
            # Set the refmac PDB file depending on whether or not we have used rigid body refinement
            if init.keywords.RBODREF:
               refmac_PDBINfile=model.refmacRB_molrep_PDBfile
            else:
               refmac_PDBINfile=model.molrep_PDBfile

            # Add the job details to the DB for dbviewer
            if init.keywords.DBOUT:
               try:
                  job_ID=mstat.conn.AddSubJob(init.ProjectName,init.JobId,
                                              "Refmac5",model.name)
      
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Refmac5")
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", model.name)
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, model.refmac_molrep_MTZINfile)
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, refmac_PDBINfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmac_molrep_MTZOUTfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmac_molrep_PDBfile)
                  mstat.conn.SetLogfile(init.ProjectName, job_ID, model.refmac_molrep_logfile)
                  print "Finished adding new record details for Refmac job"
               except:
                  self.DB_fail=True 
                  sys.stdout.write("DB error: Could not enter a new record for Refmac job (post Molrep)\n")
                  sys.stdout.write("\n")
   
            # Set the refinement type string
            if init.keywords.JBODREF:
               refineType="Restrained Refinement with Jelly Body"
            else:
               refineType="Restrained Refinement"

            # Run refmac
            refmac_job.run(model.refmac_molrep_MTZINfile, \
                           model.refmac_molrep_MTZOUTfile, \
                           refmac_PDBINfile, \
                           model.refmac_molrep_PDBfile, \
                           model.refmac_molrep_logfile, \
                           refineType, \
                           refineDir=os.path.join(model.model_directory, "mr", "molrep", "refine"),  \
                           script=os.path.join(model.model_directory, "mr", "molrep", "refine", "refmac_molrep_run_script.sh"), \
                           LITE=init.keywords.LITE)

            # Model Building with Buccaneer   
            if init.keywords.BUCCANEER:
               if os.path.isfile(model.refmac_molrep_PDBfile):
                  buccaneer_job=MRBUMP_Buccaneer.Buccaneer()
             
                  buccaneer_job.setBuccScriptFile(os.path.join(model.model_directory, "mr", "molrep", "build", "buccaneer", "buccaneer_run_script.sh"))
                  buccaneer_job.setBuccLogFile(os.path.join(model.model_directory, "mr", "molrep", "build", "buccaneer", "buccaneer_run.log"))

                  # Set the correct input sequence file and mtz file and output pdb file
                  buccaneer_SEQfile=init.seqin
                  buccaneer_MTZINfile=model.refmac_molrep_MTZOUTfile
                  buccaneer_PDBOUTfile=model.buccaneer_molrep_PDBOUTfile
             
                  buccaneer_job.runBuccaneer(buccaneer_SEQfile, buccaneer_MTZINfile, buccaneer_PDBOUTfile, model.buccaneer_molrep_directory, \
                                             target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'], target_info.mtz_coldata['FREE'], \
                                             "PHIC", "FOM", "FWT", "PHWT", \
                                             init.keywords.BCYCLES)

                  # Set the Buccaneer results
                  model.buccaneer_molrep_completeness = buccaneer_job.completeness
                  model.buccaneer_molrep_res_built  = buccaneer_job.res_built
                  model.buccaneer_molrep_initRfact  = buccaneer_job.initRfact
                  model.buccaneer_molrep_finalRfact = buccaneer_job.finalRfact
                  model.buccaneer_molrep_initRfree  = buccaneer_job.initRfree
                  model.buccaneer_molrep_finalRfree = buccaneer_job.finalRfree

               else:
                  sys.stderr.write("Error: Could not find output PDB from Refmac, can't run Buccaneer\n")
                  sys.stderr.write("\n")
           
            # Model building with ARP/wARP  
            if init.keywords.ARPWARP:
               if os.path.isfile(model.refmac_molrep_PDBfile):
                  arpwarp_job=MRBUMP_ARPwARP.Arpwarp()
             
                  arpwarp_job.setArpwarpLogFile(os.path.join(model.model_directory, "mr", "molrep", "build", "arpwarp", "arpwarp_run.log"))
                  model.arpwarp_molrep_directory=os.path.join(model.model_directory, "mr", "molrep", "build", "arpwarp")
                  noResiduesASU=(target_info.no_of_res*target_info.no_of_mols)

                  # Set the correct input model and mtz files
                  arpwarp_MTZINfile=model.refmac_molrep_MTZOUTfile
             
                  arpwarp_job.runARPwARP(init.pirin, arpwarp_MTZINfile, model.arpwarp_molrep_directory, \
                                         target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'], target_info.mtz_coldata['FREE'], \
                                         "PHIC", "FOM", noResiduesASU, cycles=init.keywords.ACYCLES)

                  # Set the ARPWARP output values 
                  model.arpwarp_molrep_res_built  = arpwarp_job.res_built
                  model.arpwarp_molrep_initRfact  = arpwarp_job.initRfact
                  model.arpwarp_molrep_finalRfact = arpwarp_job.finalRfact
                  model.arpwarp_molrep_initRfree  = arpwarp_job.initRfree
                  model.arpwarp_molrep_finalRfree = arpwarp_job.finalRfree

                  # Set the output files
                  model.arpwarp_molrep_PDBOUTfile=arpwarp_job.pdboutFile
                  model.arpwarp_molrep_MTZOUTfile=arpwarp_job.mtzoutFile

               else:
                  sys.stderr.write("Error: Could not find output PDB from Refmac, can't run ARP/wARP\n")
                  sys.stderr.write("\n")
         
            # C-alpha tracing with Shelxe   
            if init.keywords.SHELXE:
               if os.path.isfile(model.refmac_molrep_PDBfile):
                  shelxe_job=MRBUMP_Shelxe.Shelxe()
             
                  shelxe_job.setShelxeLogFile(os.path.join(model.model_directory, "mr", "molrep", "build", "shelxe", "shelxe_run.log"))
                  shelxe_job.setShelxWorkingDIR(os.path.join(model.model_directory, "mr", "molrep", "build", "shelxe")) 

                  # Set the correct input model and mtz files
                  shelxe_PDBINfile=model.refmac_molrep_PDBfile
                  shelxe_MTZINfile=model.refmac_molrep_MTZINfile
             
                  shelxe_job.runShelxe(target_info.solvent, target_info.resolution, "MOLREP", \
                         shelxe_PDBINfile, shelxe_MTZINfile, pdboutFile=model.shelxe_molrep_PDBfile, traceCycles=init.keywords.SCYCLES,
                         fp=target_info.mtz_coldata['F'], sigfp=target_info.mtz_coldata['SIGF'], free=target_info.mtz_coldata['FREE'], shelxeEXE=init.keywords.SHLXEXE)

                  # Set the SHELXE CC value for partial model
                  model.shelxe_molrep_CCscore = shelxe_job.molrepBestCC

               else:
                  sys.stderr.write("Error: Could not find output PDB from Refmac, can't run Shelxe\n")
                  sys.stderr.write("\n")


            # Set the status to be finished in the DB
            if init.keywords.DBOUT and self.DB_fail == False:
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
            elif self.DB_fail:
               self.DB_fail=False

         else:
            sys.stdout.write("MR log: No solution found for model %s\n" % model.name)
            sys.stdout.write("\n")

      #=================================================================================#
      #============== Run MR and refinement via a batch queue on a cluster =============#
      #=================================================================================#

      else:
         # Run the job on a cluster by submitting the python script as an executable
         sys.stdout.write("MR log: Submitting MR and refinement jobs to cluster queue (type: %s)\n" % init.keywords.QTYPE)
         sys.stdout.write("\n")

         # Write the inputs.txt file with the various parameters needed for running on a cluster node
         model.cluster_inputfile=os.path.join(model.model_directory, "mr", "molrep", "cluster_inputs.txt")
         model.setRefmacMolrepMTZINfile(target_info.hklin)
         
         model.refmacRB_molrep_keywords["LABIN"]="FP=" + target_info.mtz_coldata['F'] \
                                   + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                                   + " FREE=" + target_info.mtz_coldata['FREE']
         cl_file=open(model.cluster_inputfile, "w")

         cl_file.write("DIRE " + model.model_directory + "\n")
         cl_file.write("SGIN " + target_info.space_group + "\n")
         cl_file.write("ENAN " + `init.keywords.ENANT` + "\n")
         cl_file.write("HKL1 " + target_info.hklin + "\n")
         #cl_file.write("HKLR " + target_info.refinement_hklin + "\n")
         cl_file.write("HKLR " + model.refmac_molrep_MTZINfile + "\n")
         cl_file.write("PDBO " + model.molrep_PDBfile + "\n")
         cl_file.write("MRLO " + model.molrep_logfile + "\n")
         cl_file.write("REFH " + model.refmac_molrep_MTZOUTfile + "\n")
         cl_file.write("REFP " + model.refmac_molrep_PDBfile + "\n")
         cl_file.write("REFL " + model.refmac_molrep_logfile + "\n")
         if init.keywords.SHELXE:
            cl_file.write("SHELXE True\n")
            cl_file.write("FPIN " + target_info.mtz_coldata['F'] + "\n")
            cl_file.write("SIGF " + target_info.mtz_coldata['SIGF'] + "\n")
            cl_file.write("FREE " + target_info.mtz_coldata['FREE'] + "\n")
            cl_file.write("SOLV " + str(target_info.solvent) + "\n")
            cl_file.write("RESO " + str(target_info.resolution) + "\n")
            cl_file.write("SHLP " + model.shelxe_molrep_PDBfile + "\n")
            cl_file.write("SEXE " + init.keywords.SHLXEXE + "\n")
         if init.keywords.RBODREF:
            cl_file.write("RBRH " + model.refmacRB_molrep_MTZOUTfile + "\n")
            cl_file.write("RBRP " + model.refmacRB_molrep_PDBfile + "\n")
            cl_file.write("RBRL " + model.refmacRB_molrep_logfile + "\n")
         if init.keywords.ENANT:
            cl_file.write("HKL2 " + target_info.enant_hklin + "\n")

         # Finally, the list of PDB input files to be passed into the MR program
         file_list=""
         for filename in model.PDBfile:
            file_list=file_list + filename + " "

         cl_file.write("PDBI " + file_list + "\n")

         cl_file.close()

         # Write the keywords file for the molrep job
         model.molrep_keyfile=os.path.join(model.model_directory, "mr", "molrep", "molrep_keywords.txt")

         # Set up the keywords
         self.setMolrepKeywords(init, target_info, model, model.molrep_RFfile)

         # Write the keywords file
         kfile=open(model.molrep_keyfile, "w")

         for keyword in model.molrep_keywords.keys():
            kfile.write(keyword + " " + model.molrep_keywords[keyword] + "\n")

         kfile.close()
      
         ##############################
         # Refmac RB keywords:
         ##############################

         if init.keywords.RBODREF:
   
            # Set the refmac RB keyword file
            model.refmacRB_molrep_keyfile=os.path.join(model.model_directory, "mr", "molrep", "refine", "refmacRB_keywords-molrep.txt")
   
            # Set the refmac keywords
            self.setRefmacRBKeywords(init, model, target_info)
   
            rb_kfile=open(model.refmacRB_molrep_keyfile, "w")
   
            # Write out the Refmac keywords
            for keyword in model.refmacRB_molrep_keywords.keys():
               rb_kfile.write(keyword + " " + model.refmacRB_molrep_keywords[keyword] + "\n") 
            rb_kfile.write('END\n')
   
            rb_kfile.close()
      
         ###########################################
         # Refmac Restrained Refinement keywords:
         ###########################################

         # Set the refmac keyword file
         model.refmac_molrep_keyfile=os.path.join(model.model_directory, "mr", "molrep", "refine", "refmac_keywords-molrep.txt")

         # Set the refmac keywords
         self.setRefmacKeywords(init, model, target_info)

         kfile=open(model.refmac_molrep_keyfile, "w")

         # Write out the Refmac keywords
         for keyword in model.refmac_molrep_keywords.keys():
            kfile.write(keyword + " " + model.refmac_molrep_keywords[keyword] + "\n") 
         kfile.write('END\n')

         kfile.close()
      
         ###############################################################################
         ############################ Queue Submission #################################
         ###############################################################################
   
         # Now setup the cluster submission script
         clust_sub=Cluster_Submit.Cluster_submit()

         # Set the working directory for the job
         clust_sub.setJobDirectory(os.path.join(model.model_directory, "mr", "molrep"))

         if init.keywords.RBODREF:
            # Set the command line for the job
            clust_sub.setCommandLine("python " + self.clusterEXE + " " + model.cluster_inputfile \
                                     + " " + model.molrep_keyfile + " " + model.refmacRB_molrep_keyfile \
                                     + " " + model.refmac_molrep_keyfile + " molrep refmac")  
         else:
            # Set the command line for the job
            clust_sub.setCommandLine("python " + self.clusterEXE + " " + model.cluster_inputfile \
                                     + " " + model.molrep_keyfile + " " + model.refmac_molrep_keyfile \
                                     + " molrep refmac")  
         
         # Set some job parameters
         model.molrep_jobname = "Job-Molrep-" + model.name
         script_name ="job_" + model.name + ".sub"
         logfile     ="job_" + model.name + ".log"

         # Submit the job
         clust_sub.submit(init.keywords.QTYPE, model.molrep_jobname, script_name, logfile, qsub_command=init.keywords.QSUBCOM)

         # Note the job number and the job name
         model.setMR_JobID(clust_sub.job_number)
         mstat.jobid_array.add(model.MR_jobID)
         mstat.jobid_dict[model.MR_jobID]=model.molrep_jobname
         #mstat.jobname_dict[model.molrep_jobname]=model.name
         mstat.jobname_dict[model.molrep_jobname]=Matches.Job_struct()
         mstat.jobname_dict[model.molrep_jobname].model_name=model.name
         mstat.jobname_dict[model.molrep_jobname].MRPROGRAM=model.MRPROGRAM
