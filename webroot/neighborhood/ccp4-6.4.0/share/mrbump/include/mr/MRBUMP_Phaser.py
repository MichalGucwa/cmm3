#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# An MrBUMP wrapper for running Phaser jobs
# Ronan Keegan - 8/03/06
#

import os, sys, string
import shutil
import phaserEXE, refmacEXE, pdbtools
import Cluster_Submit
import convert_SG
import Matches
import MRBUMP_Shelxe
import MRBUMP_Buccaneer
import MRBUMP_ARPwARP


class Phaser:
   """ A class to submit Phaser jobs to the local machine or a batch system on a cluster. """

   def __init__(self):
      self.logfile = ""
      if os.name=="nt":
         self.phaserEXE = os.path.join(os.environ["CCP4_BIN"], "phaser.exe") 
         self.pdbcurEXE = os.path.join(os.environ["CCP4_BIN"], "pdbcur.exe")
         self.refmacEXE = os.path.join(os.environ["CCP4_BIN"], "refmac5.exe")

      else:
         self.phaserEXE = os.path.join(os.environ["CCP4_BIN"], "phaser")
         self.pdbcurEXE = os.path.join(os.environ["CCP4_BIN"], "pdbcur")
         self.refmacEXE = os.path.join(os.environ["CCP4_BIN"], "refmac5")

      # The cluster_run.py script is called as an executable if submitting to a cluster
      self.clusterEXE = os.path.join(os.environ["MRBUMP_CLUSTBIN"], "cluster_run.py") 

      self.DB_fail=False

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLogfile(self, filename):
      self.logfile=filename

   def setPhaserKeywords(self, init, model, target_info):
      """ Setup the phaser keywords """
       
      # Set the keywords
      model.phaser_keywords.append("MODE MR_AUTO")

      model.phaser_keywords.append("HKLIN %s" % target_info.hklin)
      model.phaser_keywords.append("LABIN F=" + target_info.mtz_coldata['F'] + " SIGF=" + target_info.mtz_coldata['SIGF'])
      model.phaser_keywords.append("COMPosition PROTein MW %.3f NUM %d" \
           % (target_info.mol_weight, int(target_info.no_of_mols)))

      # Set up the ensemble details
      ensm_line = 'autoMR '
      for i in range(model.num_per_ensem):
         if len(model.rms) > 0 and model.rms[i] != 0.0:
            ensm_line += 'PDBFile ' + model.PDBfile[i] + ' RMS %.3f ' % model.rms[i]
         else:
            ensm_line += 'PDBFile ' + model.PDBfile[i] + ' IDENtity %.3f ' % model.seqID[i]

      model.phaser_keywords.append("ENSEmble %s" % ensm_line)

      # Set the search line. The number to look for should depend on wheter or not fixed components were used
      model.phaser_keywords.append("SEARCH ENSEmble autoMR NUM " + `target_info.no_of_mols/model.number_mols`)

      model.phaser_keywords.append("XYZOUT ON")
      if init.keywords.CLUSTER:
         model.phaser_keywords.append("JOBS 1")
      else:
         model.phaser_keywords.append("JOBS %d" % int(init.keywords.PJOBS))

      # If we have a newer version of Phaser (>= version 2.2.4 we use the new keywords)
      if init.phaserVersion >= 224:
         if init.keywords.NMASU == None:
            model.phaser_keywords.append("PACK CUTOFF %d" % int(init.keywords.PACK))
         else:
            model.phaser_keywords.append("PACK CUTOFF %d" % (int(init.keywords.PACK)*int(init.keywords.NMASU)))
         if init.keywords.FIXSG:
            model.phaser_keywords.append("SGALTERNATIVE SELECT NONE")
      else:
         if init.keywords.NMASU == None:
            model.phaser_keywords.append("PACK %d" % int(init.keywords.PACK))
         else:
            model.phaser_keywords.append("PACK %d" % (int(init.keywords.PACK)*int(init.keywords.NMASU)))

      #model.phaser_keywords.append("ROOT %s" % os.path.join(model.model_directory,'mr','phaser','phaser_' + model.name))
      model.phaser_keywords.append("ROOT phaser_" +  model.name)

      # If fixed components of the solution where provided we need to add these to the input to phaser
      if init.keywords.FIXED:
         for i in init.keywords.fixed_list.keys():
            model.phaser_keywords.append("COMPosition PROTein MW %.3f NUM 1" \
                % init.keywords.fixed_list[i].mol_weight)
            model.phaser_keywords.append("ENSEmble fixedMR_%d PDBFile %s IDENtity %.3f" \
                % (i, init.keywords.fixed_list[i].filename, init.keywords.fixed_list[i].identity)) 
            model.phaser_keywords.append("SOLU Set")
            model.phaser_keywords.append("SOLU 6DIM ENSE fixedMR_%d EULER %.3f %.3f %.3f FRAC %.3f %.3f %.3f" \
                     % (i, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)) 
 
      # If we are looking in enantiomorphic SG set the keyword
      if init.phaserVersion >= 224:
         if init.keywords.SGALL:
            model.phaser_keywords.append("SGALTERNATIVE SELECT ALL")
         elif init.keywords.ENANT:
            model.phaser_keywords.append("SGALTERNATIVE SELECT HAND")
      else:
         if init.keywords.SGALL:
            model.phaser_keywords.append("SGALTERNATIVE ALL")
         elif init.keywords.ENANT:
            model.phaser_keywords.append("SGALTERNATIVE HAND")

      # Add any generic keyword lines specified by the user
      if init.keywords.PKEYWORD != []:
         for keyword in init.keywords.PKEYWORD:
            model.phaser_keywords.append(keyword)

      # Get Phaser to be more verbose if we are debugging
      if self.debug:
         model.phaser_keywords.append("VERBOSE ON")

   def setRefmacRBKeywords(self, init, model, target_info):
      """ Setup the refmac rigid body keywords """

      # Setup the refmac keywords Dictionary
      model.refmacRB_phaser_keywords["LABIN"]="FP=" + target_info.mtz_coldata['F'] \
                                   + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                                   + " FREE=" + target_info.mtz_coldata['FREE']
      model.refmacRB_phaser_keywords["RIGID NCYCLE"]=`init.keywords.RBNC`
      model.refmacRB_phaser_keywords["REFI"]="TYPE RIGID RESI MLKF METH CGMAT BREF OVER"
      model.refmacRB_phaser_keywords["MAKE"]="HYDR N"
      model.refmacRB_phaser_keywords["WEIGHT"]="MATRIX 0.01"
      # Add the TWIN keyword if specified
      if init.keywords.REFTWIN:
         model.refmacRB_phaser_keywords["TWIN"]=""


   def setRefmacKeywords(self, init, model, target_info):
      """ Setup the refmac keywords """
       
      # Setup the refmac keywords Dictionary
      model.refmac_phaser_keywords["LABIN"]="FP=" + target_info.mtz_coldata['F'] \
                                   + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                                   + " FREE=" + target_info.mtz_coldata['FREE']
      model.refmac_phaser_keywords["NCYC"]=`init.keywords.NCYC`
      model.refmac_phaser_keywords["MAKE"]="HYDR N"
      model.refmac_phaser_keywords["WEIGHT"]="MATRIX 0.01"
      # Add Jelly Body refinement if required
      if init.keywords.JBODREF:
         model.refmac_phaser_keywords["RIDG"]="DIST SIGM 0.02"
      # Add the TWIN keyword if specified
      if init.keywords.REFTWIN: 
         model.refmac_phaser_keywords["TWIN"]=""

   def submit_job(self, init, mstat, model, target_info):
      """ Function to launch a phaser/refmac5 job for a given model. """

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=os.path.join(model.model_directory, "phaser_refmac_job.log") 

      #=================================================================================#
      #================== Run MR and refinement on the local machine ===================#
      #=================================================================================#

      if init.keywords.CLUSTER == False:

         ###############################################################################
         ############################# Running Phaser ##################################
         ###############################################################################

         phaser_job=phaserEXE.PhaserEXE()

         # Setup the keywords for the job
         self.setPhaserKeywords(init, model, target_info)

         # Add the keywords
         for keyword in model.phaser_keywords:
            phaser_job.add_keyword(keyword + "\n")
         phaser_job.add_keyword("END\n")

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try:
               # PJB: add the addsub with dummy taskname and title
               # PJB: they are set explicitly immediately after
               job_ID=mstat.conn.AddSubJob( \
                  init.ProjectName,init.JobId,
                  "Phaser_MR","[No title given]")
   
               if "ensm" in model.name.lower():
                  mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Phaser_MR (Ensemble)")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                    "Molecular replacement using Phaser for Ensemble of best models")
               else:
                  mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Phaser_MR")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                    "Molecular replacement using Phaser for model %s" % model.name)
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.hklin)
               for modelfile in model.PDBfile:
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, modelfile)
               # if fixed components are to be included
               if init.keywords.FIXED:
                  for i in init.keywords.fixed_list.keys():
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, init.keywords.fixed_list[i].filename)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.phaser_MTZfile)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.phaser_PDBfile)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.phaser_solnfile)
               mstat.conn.SetLogfile(init.ProjectName, job_ID, model.phaser_logfile)
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Phaser job\n")
               sys.stdout.write("\n")
   
         # Set the Phaser script file 
         model.setPhaserScriptFile(os.path.join(model.model_directory, 'mr', 'phaser', 'phaser_script_job.sh'))

         # Run Phaser
         phaser_job.run(os.path.join(model.model_directory, "mr", "phaser"), \
                        model.phaser_MTZfile, \
                        model.phaser_PDBfile, \
                        model.phaser_logfile, \
                        script=model.phaser_scriptfile, \
                        LITE=init.keywords.LITE, \
                        KILLPHASER=init.keywords.KPHASER, \
                        KILLTIME=init.keywords.KTIME)
      
         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

         # Check the spacegroup of the Phaser solution
         phaser_job.check_SG(model.phaser_MTZfile)

         # Delete the output MTZ from phaser (not needed beyond here)
         #if init.keywords.LITE and init.keywords.USECPIRATE == False:
         #   os.remove(model.phaser_MTZfile)

         # Record the Phaser solution Space Group (important for accessing the Phaser log file)
         convert=convert_SG.Convert()
         model.setPhaserSolnSG(convert.xHMtoOld(phaser_job.soln_spacegroup))

         # Report the spacegroup of the solution and setup the input MTZ file for refinement
         if phaser_job.soln_found:
            sys.stdout.write("MR log: Spacegroup of solution from Phaser is: %s\n" % model.phaser_soln_spacegroup)
            if string.strip(model.phaser_soln_spacegroup).replace(" ","").lower() \
                  == string.strip(target_info.space_group).replace(" ","").lower():
               sys.stdout.write("        - this is the spacegroup of the input target MTZ file\n")
   
               # Copy the input MTZ file to the MTZ file to be processed in refinement  
               model.setRefmacPhaserMTZINfile(target_info.hklin)
               if init.keywords.RBODREF:
                  model.setRefmacRBPhaserMTZINfile(target_info.hklin)
               #shutil.copyfile(target_info.hklin, model.refmac_phaser_MTZINfile)
               model.enant_solution=False
   
            elif init.keywords.ENANT and not init.keywords.SGALL:
               sys.stdout.write("        - this is the enantiomorphic spacegroup of the target data\n")
   
               # Copy the reindexed input MTZ file to the MTZ file to be processed in refinement  
               model.setRefmacPhaserMTZINfile(target_info.enant_hklin)
               if init.keywords.RBODREF:
                  model.setRefmacRBPhaserMTZINfile(target_info.enant_hklin)
               #shutil.copyfile(target_info.enant_hklin, model.refmac_phaser_MTZINfile)
               model.enant_solution=True
            else:
               # Copy the input MTZ file to the MTZ file to be processed in refinement  
               model.setRefmacPhaserMTZINfile(target_info.hklin)
               if init.keywords.RBODREF:
                  model.setRefmacRBPhaserMTZINfile(target_info.hklin)
               #shutil.copyfile(target_info.hklin, model.refmac_phaser_MTZINfile)
               model.enant_solution=False
   
            sys.stdout.write("\n")
    
            ###############################################################################
            ######################### Extracting PDB details ##############################
            ###############################################################################
      
            # Get the number of molecules found
            details=pdbtools.Get_PDB_Details()
            details.get_details(model.phaser_PDBfile)
      
            model.num_models_found=details.mol_count
      
            # second number should be consistent with SEARCH keyword used
            if init.keywords.FIXED:
               sys.stdout.write("MR log: Molecular replacement (using Phaser) found %d molecule(s) out of %d requested and %d fixed.\n" \
                                 % (details.mol_count, target_info.no_of_mols/model.number_mols, init.keywords.fixedfile_count ))
            else:  
               sys.stdout.write("MR log: Molecular replacement (using Phaser) found %d molecule(s) out of %d requested.\n" \
                                 % (details.mol_count, target_info.no_of_mols/model.number_mols ))
            sys.stdout.write("\n")
            
            if init.keywords.RBODREF:

               ###############################################################################
               ########################### Running Refmac RB #################################
               ###############################################################################

               # Now do the refinement by calling Refmac
               refmacRB_job=refmacEXE.RefmacEXE()

               # Set the refmac keywords
               self.setRefmacRBKeywords(init, model, target_info)

               # Add them to the refmac input
               for keyword in model.refmacRB_phaser_keywords.keys():
                  refmacRB_job.add_keyword(keyword + " " + model.refmacRB_phaser_keywords[keyword])
               refmacRB_job.add_keyword('END')

               # Add the job details to the DB for dbviewer
               if init.keywords.DBOUT:
                  try:
                     job_ID=mstat.conn.AddSubJob(init.ProjectName,init.JobId,
                                                 "Refmac5",model.name)

                     #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Refmac5")
                     #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", model.name)
                     mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, model.refmac_phaser_MTZINfile)
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, model.phaser_PDBfile)
                     mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmacRB_phaser_MTZOUTfile)
                     mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmacRB_phaser_PDBfile)
                     mstat.conn.SetLogfile(init.ProjectName, job_ID, model.refmacRB_phaser_logfile)
                     print "Finished adding new record details for Refmac job"
                  except:
                     self.DB_fail=True
                     sys.stdout.write("DB error: Could not enter a new record for Refmac RB job (post Phaser)\n")
                     sys.stdout.write("\n")

               # Run refmac Rigid Body
               refmacRB_job.run(model.refmac_phaser_MTZINfile, \
                                model.refmacRB_phaser_MTZOUTfile, \
                                model.phaser_PDBfile, \
                                model.refmacRB_phaser_PDBfile, \
                                model.refmacRB_phaser_logfile, \
                                "Rigid Body",
                                refineDir=os.path.join(model.model_directory, "mr", "phaser", "refine"), \
                                script=os.path.join(model.model_directory, "mr", "phaser", "refine", "refmacRB_phaser_run_script.sh"), \
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
            for keyword in model.refmac_phaser_keywords.keys():
               refmac_job.add_keyword(keyword + " " + model.refmac_phaser_keywords[keyword])
            refmac_job.add_keyword('END')

            # Set the refmac PDB file depending on whether or not we have used rigid body refinement
            if init.keywords.RBODREF:
               refmac_PDBINfile=model.refmacRB_phaser_PDBfile
            else:
               refmac_PDBINfile=model.phaser_PDBfile

            # Add the job details to the DB for dbviewer
            if init.keywords.DBOUT:
               try:
                  job_ID=mstat.conn.AddSubJob( \
                     init.ProjectName,init.JobId,
                     "Refmac5",model.name)
      
                  #mstat.conn.SetData(init.ProjectName, job_ID, "TASKNAME", "Refmac5")
                  #mstat.conn.SetData(init.ProjectName, job_ID, "TITLE", model.name)
                  mstat.conn.SetData(init.ProjectName, job_ID, "STATUS", "RUNNING")
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, model.refmac_phaser_MTZINfile)
                  mstat.conn.AddInputFile(init.ProjectName, job_ID, refmac_PDBINfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmac_phaser_MTZOUTfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.refmac_phaser_PDBfile)
                  mstat.conn.SetLogfile(init.ProjectName, job_ID, model.refmac_phaser_logfile)
               except:
                  self.DB_fail=True 
                  sys.stdout.write("DB error: Could not enter a new record for Refmac job (post Phaser)\n")
                  sys.stdout.write("\n")
   
            # Set the refinement type string
            if init.keywords.JBODREF:
               refineType="Restrained Refinement with Jelly Body"
            else:
               refineType="Restrained Refinement"

            # Run refmac
            refmac_job.run(model.refmac_phaser_MTZINfile, \
                           model.refmac_phaser_MTZOUTfile, \
                           refmac_PDBINfile, \
                           model.refmac_phaser_PDBfile, \
                           model.refmac_phaser_logfile, \
                           refineType, \
                           refineDir=os.path.join(model.model_directory, "mr", "phaser", "refine"), \
                           script=os.path.join(model.model_directory, "mr", "phaser", "refine", "refmac_phaser_run_script.sh"), \
                           LITE=init.keywords.LITE)

            # Model Building with Buccaneer   
            if init.keywords.BUCCANEER:
               if os.path.isfile(model.refmac_phaser_PDBfile):
                  buccaneer_job=MRBUMP_Buccaneer.Buccaneer()

                  buccaneer_job.setBuccScriptFile(os.path.join(model.model_directory, "mr", "phaser", "build", "buccaneer", "buccaneer_run_script.sh"))
                  buccaneer_job.setBuccLogFile(os.path.join(model.model_directory, "mr", "phaser", "build", "buccaneer", "buccaneer_run.log"))

                  # Set the correct input sequence file and mtz file and output pdb file
                  buccaneer_SEQfile=init.seqin
                  buccaneer_MTZINfile=model.refmac_phaser_MTZOUTfile
                  buccaneer_PDBOUTfile=model.buccaneer_phaser_PDBOUTfile

                  buccaneer_job.runBuccaneer(buccaneer_SEQfile, buccaneer_MTZINfile, buccaneer_PDBOUTfile, model.buccaneer_phaser_directory, \
                                             target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'], target_info.mtz_coldata['FREE'], \
                                             "PHIC", "FOM", "FWT", "PHWT", \
                                             init.keywords.BCYCLES)

                  # Set the Buccaneer results
                  model.buccaneer_phaser_completeness = buccaneer_job.completeness
                  model.buccaneer_phaser_res_built  = buccaneer_job.res_built
                  model.buccaneer_phaser_initRfact  = buccaneer_job.initRfact
                  model.buccaneer_phaser_finalRfact = buccaneer_job.finalRfact
                  model.buccaneer_phaser_initRfree  = buccaneer_job.initRfree
                  model.buccaneer_phaser_finalRfree = buccaneer_job.finalRfree

               else:
                  sys.stdout.write("Error: Could not find output PDB from Refmac, can't run Buccaneer\n")
                  sys.stdout.write("\n")
           
            # Model building with ARP/wARP  
            if init.keywords.ARPWARP:
               if os.path.isfile(model.refmac_phaser_PDBfile):
                  arpwarp_job=MRBUMP_ARPwARP.Arpwarp()
             
                  arpwarp_job.setArpwarpLogFile(os.path.join(model.model_directory, "mr", "phaser", "build", "arpwarp", "arpwarp_run.log"))
                  model.arpwarp_phaser_directory=os.path.join(model.model_directory, "mr", "phaser", "build", "arpwarp")
                  noResiduesASU=(target_info.no_of_res*target_info.no_of_mols)

                  # Set the correct input model and mtz files
                  arpwarp_MTZINfile=model.refmac_phaser_MTZOUTfile
             
                  arpwarp_job.runARPwARP(init.pirin, arpwarp_MTZINfile, model.arpwarp_phaser_directory, \
                                         target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'], target_info.mtz_coldata['FREE'], \
                                         "PHIC", "FOM", noResiduesASU, cycles=init.keywords.ACYCLES)

                  # Set the ARPWARP output values 
                  model.arpwarp_phaser_res_built  = arpwarp_job.res_built
                  model.arpwarp_phaser_initRfact  = arpwarp_job.initRfact
                  model.arpwarp_phaser_finalRfact = arpwarp_job.finalRfact
                  model.arpwarp_phaser_initRfree  = arpwarp_job.initRfree
                  model.arpwarp_phaser_finalRfree = arpwarp_job.finalRfree

                  # Set the output files
                  model.arpwarp_phaser_PDBOUTfile=arpwarp_job.pdboutFile
                  model.arpwarp_phaser_MTZOUTfile=arpwarp_job.mtzoutFile

               else:
                  sys.stderr.write("Error: Could not find output PDB from Refmac, can't run ARP/wARP\n")
                  sys.stderr.write("\n")
           
            # C-alpha tracing with Shelxe   
            if init.keywords.SHELXE:
               if os.path.isfile(model.refmac_phaser_PDBfile):
                  shelxe_job=MRBUMP_Shelxe.Shelxe()
             
                  shelxe_job.setShelxeLogFile(os.path.join(model.model_directory, "mr", "phaser", "build", "shelxe", "shelxe_run.log"))
                  shelxe_job.setShelxWorkingDIR(os.path.join(model.model_directory, "mr", "phaser", "build", "shelxe"))

                  # Set the correct input model and mtz files
                  shelxe_PDBINfile=model.refmac_phaser_PDBfile
                  shelxe_MTZINfile=model.refmac_phaser_MTZINfile
             
                  shelxe_job.runShelxe(target_info.solvent, target_info.resolution, "PHASER", \
                            shelxe_PDBINfile, shelxe_MTZINfile, pdboutFile=model.shelxe_phaser_PDBfile, traceCycles=init.keywords.SCYCLES,
                            fp=target_info.mtz_coldata['F'], sigfp=target_info.mtz_coldata['SIGF'], free=target_info.mtz_coldata['FREE'], shelxeEXE=init.keywords.SHLXEXE)

                  # Set the SHELXE CC value for partial model
                  model.shelxe_phaser_CCscore = shelxe_job.phaserBestCC

               else:
                  sys.stdout.write("Error: Could not find output PDB from Refmac, can't run Shelxe\n")
                  sys.stdout.write("\n")

            # Set the status to be finished in the DB
            if init.keywords.DBOUT and self.DB_fail == False:
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
            elif self.DB_fail:
               self.DB_fail=False

         else:
            sys.stdout.write("MR log: No phaser solution produced for model %s\n" % model.name)
            sys.stdout.write("\n")

      #=================================================================================#
      #============== Run MR and refinement via a batch queue on a cluster =============#
      #=================================================================================#

      else:
         # Run the job on a cluster by submitting the python script as an executable
         sys.stdout.write("MR log: Submitting MR and refinement jobs to cluster queue (type: %s)\n" % init.keywords.QTYPE)
         sys.stdout.write("\n")

         ###############################################################################
         ####################### Cluster Job Keyword Setup #############################
         ###############################################################################
   
         # Write the inputs.txt file with the various parameters needed for running on a cluster node
         model.cluster_inputfile=os.path.join(model.model_directory, "mr", "phaser", "cluster_inputs.txt")
         model.setRefmacPhaserMTZINfile(target_info.hklin)
         
         cl_file=open(model.cluster_inputfile, "w")

         cl_file.write("DIRE " + model.model_directory + "\n")
         cl_file.write("SGIN " + target_info.space_group + "\n")
         cl_file.write("ENAN " + `init.keywords.ENANT` + "\n")
         cl_file.write("SGAL " + repr(init.keywords.SGALL) + "\n")
         cl_file.write("HKL1 " + target_info.hklin + "\n")
         cl_file.write("HKLR " + model.refmac_phaser_MTZINfile + "\n")
         cl_file.write("HKLO " + model.phaser_MTZfile + "\n")
         cl_file.write("PDBO " + model.phaser_PDBfile + "\n")
         cl_file.write("MRLO " + model.phaser_logfile + "\n")
         cl_file.write("REFH " + model.refmac_phaser_MTZOUTfile + "\n")
         cl_file.write("REFP " + model.refmac_phaser_PDBfile + "\n")
         cl_file.write("REFL " + model.refmac_phaser_logfile + "\n")
         if init.keywords.SHELXE:
            cl_file.write("SHELXE True\n")
            cl_file.write("FPIN " + target_info.mtz_coldata['F'] + "\n")
            cl_file.write("SIGF " + target_info.mtz_coldata['SIGF'] + "\n")
            cl_file.write("FREE " + target_info.mtz_coldata['FREE'] + "\n")
            cl_file.write("SOLV " + str(target_info.solvent) + "\n")
            cl_file.write("RESO " + str(target_info.resolution) + "\n")
            cl_file.write("SHLP " + model.shelxe_phaser_PDBfile + "\n")
            cl_file.write("SEXE " + init.keywords.SHLXEXE + "\n")
         if init.keywords.RBODREF:
            cl_file.write("RBRH " + model.refmacRB_phaser_MTZOUTfile + "\n")
            cl_file.write("RBRP " + model.refmacRB_phaser_PDBfile + "\n")
            cl_file.write("RBRL " + model.refmacRB_phaser_logfile + "\n")
         if init.keywords.ENANT and not init.keywords.SGALL:
            cl_file.write("HKL2 " + target_info.enant_hklin + "\n")

         # Finally, the list of PDB input files to be passed into the MR program
         file_list=""
         for filename in model.PDBfile:
            file_list=file_list + filename + " "

         cl_file.write("PDBI " + file_list + "\n")

         cl_file.close()

         ###############################################################################
         ############################## Phaser Setup ###################################
         ###############################################################################
   
         # Write the keywords file for the phaser job
         model.phaser_keyfile=os.path.join(model.model_directory, "mr", "phaser", "phaser_keywords.txt")

         # Setup the keywords for the job
         self.setPhaserKeywords(init, model, target_info)

         kfile=open(model.phaser_keyfile, "w")

         if self.debug:
            sys.stdout.write("DEBUG : Creating keywords file for Phaser\n Keywords:\n\n")  

         # Add the keywords
         for keyword in model.phaser_keywords:
            if self.debug:
               sys.stdout.write(keyword + "\n")
            kfile.write(keyword + "\n")
         kfile.write("END\n")

         kfile.close()

         if self.debug:
            sys.stdout.write("\n")  

         ###############################################################################
         ############################## Refmac Setup ###################################
         ###############################################################################
   
         ##############################
         # Refmac RB keywords:
         ##############################

         if init.keywords.RBODREF:

            # Set the refmac RB keyword file
            model.refmacRB_phaser_keyfile=os.path.join(model.model_directory, "mr", "phaser", "refine", "refmacRB_keywords-phaser.txt")

            # Set the refmac keywords
            self.setRefmacRBKeywords(init, model, target_info)

            rb_kfile=open(model.refmacRB_phaser_keyfile, "w")

            # Write out the Refmac keywords
            for keyword in model.refmacRB_phaser_keywords.keys():
               rb_kfile.write(keyword + " " + model.refmacRB_phaser_keywords[keyword] + "\n")
            rb_kfile.write('END\n')

            rb_kfile.close()

         ###########################################
         # Refmac Restrained Refinement keywords:
         ###########################################

         # Set the refmac keyword file
         model.refmac_phaser_keyfile=os.path.join(model.model_directory, "mr", "phaser", "refine", "refmac_keywords-phaser.txt")

         kfile=open(model.refmac_phaser_keyfile, "w")

         # Set the refmac keywords
         self.setRefmacKeywords(init, model, target_info)

         # Add them to the refmac input
         for keyword in model.refmac_phaser_keywords.keys():
            kfile.write(keyword + " " + model.refmac_phaser_keywords[keyword] + "\n")
         kfile.write('END\n')
 
         kfile.close()

         ###############################################################################
         ############################ Queue Submission #################################
         ###############################################################################
   
         # Now setup the cluster submission script
         clust_sub=Cluster_Submit.Cluster_submit()

         # Set the working directory for the job
         clust_sub.setJobDirectory(os.path.join(model.model_directory, "mr", "phaser"))

         if init.keywords.RBODREF:
            # Set the command line for the job
            clust_sub.setCommandLine("python " + self.clusterEXE + " " + model.cluster_inputfile \
                                     + " " + model.phaser_keyfile + " " + model.refmacRB_phaser_keyfile \
                                     + " " + model.refmac_phaser_keyfile + " phaser refmac")
         else:
            # Set the command line for the job
            clust_sub.setCommandLine("python " + self.clusterEXE + " " + model.cluster_inputfile \
                                     + " " + model.phaser_keyfile + " " + model.refmac_phaser_keyfile \
                                     + " phaser refmac")

         # Set some job parameters
         model.phaser_jobname = "Job-Phaser-" + model.name
         script_name ="job_" + model.name + ".sub"
         logfile     ="job_" + model.name + ".log"

         # Submit the job
         clust_sub.submit(init.keywords.QTYPE, model.phaser_jobname, script_name, logfile, qsub_command=init.keywords.QSUBCOM)
    
         # Note the job number and the job name
         model.setMR_JobID(clust_sub.job_number)
         mstat.jobid_array.add(model.MR_jobID)
         mstat.jobid_dict[model.MR_jobID]=model.phaser_jobname
         #mstat.jobname_dict[model.phaser_jobname]=model.name
         mstat.jobname_dict[model.phaser_jobname]=Matches.Job_struct()
         mstat.jobname_dict[model.phaser_jobname].model_name=model.name
         mstat.jobname_dict[model.phaser_jobname].MRPROGRAM=model.MRPROGRAM
