#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Top level wrapper for launcing Molecular Replacement and Refinement jobs
# Ronan Keegan 10/03/06
#

import os, sys, string
import Model_Queue
import MRBUMP_Phaser
import MRBUMP_Molrep
import MRBUMP_cpirate
import MRBUMP_writebest
#import MRBUMP_cbuccaneer_ref
import Phase_improve

class MR_submit:

   def __init__(self):
      self.DB_fail=False
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag

   def MR_start(self, target_info, init, mstat, job_limit):
      """ A function to start a molecular replacement job (Molrep or Phaser)."""

      sys.stdout.write("MR log: Launching molecular replacement jobs\n")
      sys.stdout.write("\n")

      # If an enantiomorph exists and we want to do a search in that spacegroup too, report it
      if init.keywords.ENANT:
         sys.stdout.write("MR log: The spacegroup of the target data (%s) has an enantiomorph (%s)\n" \
                           % (target_info.space_group, target_info.enant_spacegroup))
         sys.stdout.write("        Molecular replacement will be carried out in this spacegroup also.\n")
         sys.stdout.write("\n")

      # If a fixed component is being input to the MR stage, add this to the DBviewer record
      if init.keywords.FIXED:
         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try:
               # PJB: add subjob with dummy taskname and title
               # PJB: they are set explicitly afterwards
               if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                  job_ID=mstat.conn.AddSubJob( \
                     init.ProjectName,init.JobId,
                     "MR","[No title given]")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Fixed_Input_Molrep")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                    "Inclusion of user input fixed components in MR search (files combined for Molrep)")
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, init.molrep_fixed_PDBfile)
                  mstat.conn.AddOutputFile(init.ProjectName, job_ID, init.merge_fixed_logfile)
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                  job_ID=mstat.conn.AddSubJob( \
                     init.ProjectName,init.JobId,
                     "MR","[No title given]")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Fixed_Input_Phaser")
                  mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                    "Inclusion of user input fixed components in MR search")
                  for i in init.keywords.fixed_list.keys():
                     mstat.conn.AddOutputFile(init.ProjectName, job_ID, init.keywords.fixed_list[i].filename)
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for the fixed component in MR\n")
               sys.stdout.write("\n")

         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

      # Sort the model list so that jobs with a higher sequence identity are started first
      self.sort_model_list(mstat)

      jl_file=os.path.join(init.search_dir, "logs", "jobs.txt")
      if os.path.isfile(jl_file):
         job_id_log = open(jl_file, 'a')
      else:
         job_id_log = open(jl_file, 'w')
 
      # Loop over all of the search models and submit them to one of the MR programs
      model_count=0
      for model in mstat.sorted_model_list:

         # If we have submitted enough jobs, then exit
         if model_count>=job_limit:
            break

         # Loop over the list of molecular replacement programs that are being used in this job
         for MRPROGRAM in init.keywords.MR_PROGRAM_LIST: 

            # Set the MR program
            mstat.setMRPROGRAM(MRPROGRAM.upper())
   
            MODEL=mstat.model_list[model]
      
            # Skip jobs that have already been submitted
            if mstat.MRPROGRAM == "MOLREP" and MODEL.isMolrepSubmitted() or \
               mstat.MRPROGRAM == "PHASER" and MODEL.isPhaserSubmitted():
               continue

            # Set the job number
            MODEL.setMR_JobNumber(mstat.mr_counter)
            
            # Print some details about this job
            if MODEL.name[:14] == "ensemble_model" and mstat.MRPROGRAM == "MOLREP":
               if self.debug:
                  sys.stdout.write("Skipping MR results check for ensemble model using Molrep..\n")
            else:
               self.print_job_details(MODEL, mstat, init)
   
            # if we are using Phaser as the MR program then we start the MR job accordingly.
            if mstat.MRPROGRAM=='PHASER':
           
               # Set the model variable for the name of the MR program
               MODEL.setMRPROGRAM("PHASER")
   
               # Setup for Phaser
               MODEL.setPhaserLogFile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'phaser_' + MODEL.name + '.log'))
               MODEL.setPhaserSummary(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'phaser_' + MODEL.name + '.sum'))
               MODEL.setPhaserSolnFile(os.path.join(MODEL.model_directory,'mr', 'phaser', 'phaser_' + MODEL.name + '.sol'))
               MODEL.setPhaserMTZfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'phaser_' + MODEL.name + '.1.mtz'))
               MODEL.setPhaserPDBfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'phaser_' + MODEL.name + '.1.pdb'))
               MODEL.setPhaserJobName("MRB_" + MODEL.name)
   
               # Specify the PDB summary log file name for phaser
               MODEL.setMRPDBSummaryFile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'mr_pdb_summary_phaser_' + MODEL.name + '.log'))
   
               # Specify the PDBcur log file name
               MODEL.setPDBcurSummaryFile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'pdbcur_summary_phaser_' + MODEL.name + '.log'))
    
               # Create specific files for the Refmac Rigid Body MTZ, PDB, solution file and logfile for Phaser.
               if init.keywords.RBODREF:
                  MODEL.setRefmacRBPhaserLogFile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'refine', 'refmacRB_phaser_' + MODEL.name + '.log'))
                  MODEL.setRefmacRBPhaserPDBfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "refine", "refmacRB_phaser_" + MODEL.name + ".pdb"))
                  #MODEL.setRefmacRBPhaserMTZINfile(os.path.join(MODEL.model_directory, "refine", "phaser", "refmac_phaser_HKLIN_" + MODEL.name + ".mtz"))
                  MODEL.setRefmacRBPhaserMTZOUTfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "refine", "refmacRB_phaser_HKLOUT_" + MODEL.name + ".mtz"))
                  #MODEL.setRefmacRBPhaserMTZINfile(target_info.refinement_hklin)
  
               # Create specific files for the Refmac MTZ, PDB, solution file and logfile for Phaser.
               MODEL.setRefmacPhaserLogFile(os.path.join(MODEL.model_directory, 'mr', 'phaser', 'refine', 'refmac_phaser_' + MODEL.name + '.log'))
               MODEL.setRefmacPhaserPDBfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "refine",  "refmac_phaser_" + MODEL.name + ".pdb"))
               #MODEL.setRefmacPhaserMTZINfile(os.path.join(MODEL.model_directory, "refine", "phaser", "refmac_phaser_HKLIN_" + MODEL.name + ".mtz"))
               MODEL.setRefmacPhaserMTZOUTfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "refine", "refmac_phaser_HKLOUT_" + MODEL.name + ".mtz"))
               #MODEL.setRefmacPhaserMTZINfile(target_info.refinement_hklin)

               # Model building settings
               if init.keywords.BUCCANEER:
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "buccaneer"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "buccaneer"))
                  MODEL.setBuccaneerPhaserPDBOUTfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "build", "buccaneer", "buccaneer_phaser_" + MODEL.name + ".pdb"))
                  MODEL.setBuccaneerPhaserWorkingDIR(os.path.join(MODEL.model_directory, 'mr', 'phaser', "build", "buccaneer"))
                  MODEL.setBuccaneerPhaserPDBrefinedfile(os.path.join(MODEL.buccaneer_phaser_directory, "buccaneer_pipeline", "refined.pdb"))
                  MODEL.setBuccaneerPhaserMTZrefinedfile(os.path.join(MODEL.buccaneer_phaser_directory, "buccaneer_pipeline", "refined.mtz"))

               if init.keywords.ARPWARP:
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "arpwarp"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "arpwarp"))
                  MODEL.setArpwarpPhaserPDBOUTfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "build", "arpwarp", "arpwarp_phaser_" + MODEL.name + ".pdb"))
 
               if init.keywords.SHELXE:
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build"))
                  if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "shelxe"))==False:
                     os.mkdir(os.path.join(MODEL.model_directory, "mr", "phaser", "build", "shelxe"))
                  MODEL.setShelxePhaserPDBfile(os.path.join(MODEL.model_directory, 'mr', 'phaser', "build", "shelxe", "shelxe_phaser_" + MODEL.name + ".pdb"))

               # Set this as submitted, and increment counter
               MODEL.setPhaserSubmitted(True)
               model_count += 1
               # Complete the jobs script to be Phaser specific
               phaser_job=MRBUMP_Phaser.Phaser()
               phaser_job.submit_job(init, mstat, MODEL, target_info)
         
            # or if we are using molrep...
            if mstat.MRPROGRAM=='MOLREP':
   
               # Set the model variable for the name of the MR program
               MODEL.setMRPROGRAM("MOLREP")
   
               # Make sure not to try the phaser ensemble model if we are running Molrep
               if "ensemble_model" in MODEL.name: 
                  if self.debug:
                     sys.stdout.write("Ignoring ensemble model in Molrep\n") 
                     sys.stdout.write("\n") 
   
               else:
                  # Setup for Molrep   
                  MODEL.setMolrepLogFile(os.path.join(MODEL.model_directory, 'mr', 'molrep', 'molrep.log'))
                  MODEL.setMolrepSolnFile(os.path.join(MODEL.model_directory, 'mr', 'molrep', 'molrep.log'))
                  MODEL.setMolrepMTZfile(os.path.join(MODEL.model_directory, 'mr', 'molrep', 'molrep_' + MODEL.name + '.1.mtz'))
                  MODEL.setMolrepPDBfile(os.path.join(MODEL.model_directory, 'mr', 'molrep', 'molrep_' + MODEL.name + '.1.pdb'))
                  MODEL.setMolrepJobName("MRB_" + MODEL.name)
   
                  # Specify the PDB summary log file name for molrep
                  MODEL.setMRPDBSummaryFile(os.path.join(MODEL.model_directory, "mr", 'molrep',"mr_pdb_summary_molrep_" + MODEL.name + ".log"))
   
                  # Specify the PDBcur log file name
                  MODEL.setPDBcurSummaryFile(os.path.join(MODEL.model_directory, "mr", 'molrep',"pdbcur_summary_molrep_" + MODEL.name + ".log"))
    
                  # Create specific files for the Refmac Rigid Body solution file and logfile for Molrep.
                  if init.keywords.RBODREF:
                     MODEL.setRefmacRBMolrepLogFile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmacRB_molrep_" + MODEL.name + ".log"))
                     MODEL.setRefmacRBMolrepPDBfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmacRB_molrep_" + MODEL.name + ".pdb"))
                     #MODEL.setRefmacRBMolrepMTZINfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmac_molrep_HKLIN_" + MODEL.name + ".mtz"))
                     MODEL.setRefmacRBMolrepMTZOUTfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmacRB_molrep_HKLOUT_" + MODEL.name + ".mtz"))
                     #MODEL.setRefmacRBMolrepMTZINfile(target_info.refinement_hklin)
   
                  # Create specific files for the Refmac solution file and logfile for Molrep.
                  MODEL.setRefmacMolrepLogFile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmac_molrep_" + MODEL.name + ".log"))
                  MODEL.setRefmacMolrepPDBfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmac_molrep_" + MODEL.name + ".pdb"))
                  #MODEL.setRefmacMolrepMTZINfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmac_molrep_HKLIN_" + MODEL.name + ".mtz"))
                  MODEL.setRefmacMolrepMTZOUTfile(os.path.join(MODEL.model_directory, "mr", "molrep", "refine", "refmac_molrep_HKLOUT_" + MODEL.name + ".mtz"))
                  #MODEL.setRefmacMolrepMTZINfile(target_info.refinement_hklin)

                  # Model building settings
                  if init.keywords.BUCCANEER:
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "buccaneer"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "buccaneer"))
                     MODEL.setBuccaneerMolrepPDBOUTfile(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "buccaneer", "buccaneer_molrep_" + MODEL.name + ".pdb"))
                     MODEL.setBuccaneerMolrepWorkingDIR(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "buccaneer")) 
                     MODEL.setBuccaneerMolrepPDBrefinedfile(os.path.join(MODEL.buccaneer_molrep_directory, "buccaneer_pipeline", "refined.pdb"))
                     MODEL.setBuccaneerMolrepMTZrefinedfile(os.path.join(MODEL.buccaneer_molrep_directory, "buccaneer_pipeline", "refined.mtz"))
   
                  if init.keywords.ARPWARP:
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "arpwarp"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "arpwarp"))
                     MODEL.setArpwarpPhaserPDBOUTfile(os.path.join(MODEL.model_directory, 'mr', 'molrep', "build", "arpwarp", "arpwarp_molrep_" + MODEL.name + ".pdb"))
 
                  if init.keywords.SHELXE:
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build"))
                     if os.path.isdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "shelxe"))==False:
                        os.mkdir(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "shelxe"))
                     MODEL.setShelxeMolrepPDBfile(os.path.join(MODEL.model_directory, "mr", "molrep", "build", "shelxe", "shelxe_molrep_" + MODEL.name + ".pdb"))

                  # Set this as submitted, and increment counter
                  MODEL.setMolrepSubmitted(True)
                  model_count += 1
                  # Complete the jobs script to be Molrep specific
                  molrep_job=MRBUMP_Molrep.Molrep()
                  molrep_job.submit_job(init, mstat, MODEL, target_info)
         
   
            # If we are using the cluster we do not do the following:
            if init.keywords.CLUSTER == False:
   
               # If we are running on a single machine we do the following. Uses the same script
               if MODEL.name[:14] == "ensemble_model" and mstat.MRPROGRAM == "MOLREP":
                  sys.stdout.write("Skipping Ensemble model for in Molrep....\n")
               else:
                  sys.stdout.write("Finished job, checking results....\n")
   
               # Check the results for this job
               queue=Model_Queue.Queue_info()
                
               if MODEL.name[:14] == "ensemble_model" and mstat.MRPROGRAM == "MOLREP":
                  if self.debug:
                     sys.stdout.write("Skipping Refmac results check for ensemble in Molrep..\n")
               else:
                  queue.check_result_serial(mstat, init, model, target_info)
   
               # Run Acorn if the solution looks ok and the resolution is good enough
               SOLUTION=False
               if mstat.MRPROGRAM == "MOLREP":
                  if MODEL.good_solution_MOLREP or MODEL.marginal_solution_MOLREP:
                     SOLUTION=True
               if mstat.MRPROGRAM == "PHASER":
                  if MODEL.good_solution_PHASER or MODEL.marginal_solution_PHASER:
                     SOLUTION=True
   
               if init.acorn_found and SOLUTION and init.keywords.USEACORN:
                  if target_info.resolution <= init.keywords.ACORNRES:
   
                     sys.stdout.write("##############################################################\n")
                     sys.stdout.write("Running Acorn using output MTZ from Refmac to improve the map\n")
                     sys.stdout.write("##############################################################\n")
                     sys.stdout.write("\n")
                     sys.stdout.write("Collected data resolution = %.3f Angstroms\n" % target_info.resolution)
                     sys.stdout.write("\n")
   
                     phase_imp=Phase_improve.PhaseImprove()
                    
                     # Make the building directory
                     if os.path.exists(os.path.join(MODEL.model_directory, "building")) == False:
                        os.mkdir(os.path.join(MODEL.model_directory, "building"))
   
                     # Set the input PDB file for Acorn (experiment with this)
                     #if init.keywords.XYZACORN = "REFINED":
                     #MODEL.acorn_XYZINfile = MODEL.refmac_PDBfile 
                     #   sys.stdout.write("Using PDB 
   
                     # Set the various file names
                     if mstat.MRPROGRAM == "MOLREP":
                        MODEL.acorn_XYZINfile = MODEL.refmac_molrep_PDBfile 
                        MODEL.acorn_MTZOUTfile = os.path.join(MODEL.model_directory, "building", MODEL.name + "_molrep_acorn_out.mtz") 
                        MODEL.acorn_logfile = os.path.join(MODEL.model_directory, "building", MODEL.name + "_molrep_acorn.log") 
                     if mstat.MRPROGRAM == "PHASER":
                        MODEL.acorn_XYZINfile = MODEL.refmac_phaser_PDBfile 
                        MODEL.acorn_MTZOUTfile = os.path.join(MODEL.model_directory, "building", MODEL.name + "_phaser_acorn_out.mtz") 
                        MODEL.acorn_logfile = os.path.join(MODEL.model_directory, "building", MODEL.name + "_phaser_acorn.log") 
                  
                     # Run acorn to calculate new phases
                     if self.debug:
                        sys.stdout.write("Running Acorn to calculate new phases...\n")
                        sys.stdout.write("\n")
           
                     # Set the ecalc output MTZ (original target or enantiomorphic)
                     if init.keywords.ENANT and MODEL.enant_solution:
                        target_info.ecalc_MTZOUTfile = target_info.enant_ecalc_MTZOUTfile
                     else:
                        target_info.ecalc_MTZOUTfile = target_info.target_ecalc_MTZOUTfile
   
                     # Run Acorn
                     phase_imp.run_acorn(init, mstat, target_info, MODEL)
   
                     # Check the results from Acorn
                     phase_imp.read_logfile(MODEL.acorn_logfile)
   
                     # Get the final cc value and the no. of cycles used
                     MODEL.acorn_CC_value = phase_imp.cc_value
                     MODEL.acorn_cycles = phase_imp.no_cycles
   
   ### CPIRATE: #################################################################################################################
   
               # Run Cpirate if the solution looks ok and the resolution is not high enough for Acorn 
               NO_GOOD_SOLUTION=False
               if mstat.MRPROGRAM == "MOLREP":
                  if MODEL.poor_solution_MOLREP or MODEL.marginal_solution_MOLREP:
                     NO_GOOD_SOLUTION=True
               if mstat.MRPROGRAM == "PHASER":
                  if MODEL.poor_solution_PHASER or MODEL.marginal_solution_PHASER:
                     NO_GOOD_SOLUTION=True
   
               if init.cpirate_found and NO_GOOD_SOLUTION \
                  and init.keywords.USECPIRATE and mstat.MRPROGRAM == "PHASER":
   
                  sys.stdout.write("##################################################################\n")
                  sys.stdout.write("Running Cpirate using output MTZ from Phaser to improve the phases\n")
                  sys.stdout.write("##################################################################\n")
                  sys.stdout.write("\n")
                  sys.stdout.write("Collected data resolution = %.3f Angstroms\n" % target_info.resolution)
                  sys.stdout.write("\n")
   
                  # Instantiate a cpirate job
                  cp=MRBUMP_cpirate.Cpirate()
               
                  # Make the directory 
                  if os.path.isdir(os.path.join(MODEL.model_directory, 'mr', 'build')) == False:
                     os.mkdir(os.path.join(MODEL.model_directory, 'mr', 'build'))
                     
                  # Set the Cpirate logfile, command file and output MTZ file 
                  MODEL.setCpirateMTZfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'cpirate_' + MODEL.name + '.mtz'))
                  MODEL.setCpirateLogfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'cpirate_' + MODEL.name + '.log'))
                  MODEL.setCpirateCmdfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'cpirate_' + MODEL.name + '_commandline.txt'))
   
                  # Set the log file and command file
                  cp.setLogfile(MODEL.cpirate_logfile)
                  cp.setCommandfile(MODEL.cpirate_cmdfile)
                  
                  # Set the Column labels for the phaser output HL coeffiecients (assume phaser has these as HLA, HLB,...)
                  target_info.mtz_coldata['HLA'] = 'HLA'
                  target_info.mtz_coldata['HLB'] = 'HLB'
                  target_info.mtz_coldata['HLC'] = 'HLC'
                  target_info.mtz_coldata['HLD'] = 'HLD'
               
                  # Set up the keyword input for Cpirate
                  cp.keywords["mtzin-ref"]=init.cpirate_MTZref_file
                  cp.keywords["mtzin-wrk"]=MODEL.phaser_MTZfile
                  cp.keywords["mtzout"]=MODEL.cpirate_MTZfile
                  cp.keywords["colin-ref-fo"]="/*/*/[%s,%s]" % (init.cpirate_mtz_coldata['F'], init.cpirate_mtz_coldata['SIGF'])
                  cp.keywords["colin-ref-hl"]="/*/*/[%s,%s,%s,%s]" % (init.cpirate_mtz_coldata['HLA'], init.cpirate_mtz_coldata['HLB'], \
                                                                      init.cpirate_mtz_coldata['HLC'], init.cpirate_mtz_coldata['HLD'])
                  cp.keywords["colin-wrk-fo"]="/*/*/[%s,%s]" % (target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'])
                  cp.keywords["colin-wrk-hl"]="/*/*/[%s,%s,%s,%s]" % (target_info.mtz_coldata['HLA'], target_info.mtz_coldata['HLB'], \
                                                                      target_info.mtz_coldata['HLC'], target_info.mtz_coldata['HLD'])
                  cp.keywords["colin-wrk-free"] = "/*/*/[%s]" % target_info.mtz_coldata['FREE']
                  cp.keywords["colout"] = "pirate"
                  cp.keywords["ncycles"] = init.keywords.PIRCYC
                  cp.keywords["unbias"] = True
               
                  # Run cpirate
                  cp.run()
              
                  # Display location of Log and MTZ files from cpirate
                  sys.stdout.write("Output Log file from cpirate written to:\n   %s\n" % MODEL.cpirate_logfile)
                  sys.stdout.write("\n")
   
                  sys.stdout.write("Output MTZ file from cpirate written to:\n   %s\n" % MODEL.cpirate_MTZfile)
                  sys.stdout.write("\n")
   
   ##############################################################################################################################
   
   ### BUCC_REFMAC: #############################################################################################################
   
               # Run CCP4_pipeline_simple to cycle buccaneer and refmac to build the model 
               if init.cpirate_found and NO_GOOD_SOLUTION \
                  and init.keywords.USECPIRATE and mstat.MRPROGRAM == "PHASER":
   
                  cbr=MRBUMP_buccaneer_ref.Buc_Ref()
               
                  cbr.debug = True
               
                  # Make the directory 
                  if os.path.isdir(os.path.join(MODEL.model_directory, 'mr', 'build')) == False:
                     os.mkdir(os.path.join(MODEL.model_directory, 'mr', 'build'))
                     
                  # Set the log file, the command file and any other files
                  MODEL.setbucc_ref_logfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'buccref_' + MODEL.name + '.log'))
                  MODEL.setbucc_ref_cmdfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'buccref_' + MODEL.name + '.com'))
                  MODEL.setbucc_MTZINfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'bucc_' + MODEL.name + '_in.mtz'))
                  MODEL.setbucc_MTZOUTfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'bucc_' + MODEL.name + '_out.mtz'))
                  MODEL.setbucc_refmac_PDBOUTfile(os.path.join(MODEL.model_directory, 'mr', 'build', 'bucc_refmac_' + MODEL.name + '_out.pdb'))
   
                  # Copy the output MTZ file from cpirate to the input MTZ file for the first loop
                  os.copyfile(MODEL.cpirate_MTZfile, MODEL.bucc_MTZINfile)
   
                  cbr.setLogfile(MODEL.bucc_ref_logfile)
                  cbr.setCommandfile(MODEL.bucc_ref_cmdfile)
               
                  cbr.setbucc_title("Mrbump buccaneer run")
                  cbr.setbucc_SEQIN(target_info.seqfile)
                  cbr.setbucc_workMTZIN(MODEL.bucc_MTZINfile)
                  cbr.setbucc_workPDBIN(MODEL.bucc_refmac_PDBOUTfile)
                  cbr.setbucc_workPDBOUT(MODEL.bucc_MTZOUTfile)
               
                  cbr.bucc_workCol["FP"]=target_info.mtz_coldata["F"]
                  cbr.bucc_workCol["SIGFP"]=target_info.mtz_coldata["SIGF"]
                  cbr.bucc_workCol["HLA"]=target_info.mtz_coldata["HLA"]
                  cbr.bucc_workCol["HLB"]=target_info.mtz_coldata["HLB"]
                  cbr.bucc_workCol["HLC"]=target_info.mtz_coldata["HLC"]
                  cbr.bucc_workCol["HLD"]=target_info.mtz_coldata["HLD"]
                  cbr.bucc_workCol["PHCOMB"]="PHCOMB"
                  cbr.bucc_workCol["FOM"]="FOM"
               
                  cbr.bucc_cycles.append(3)
                  for i in range(cbr.ncycles-1):
                     cbr.bucc_cycles.append(1)
               
                  cbr.bucc_seqReliability.append(0.95)
                  for i in range(cbr.ncycles-1):
                     cbr.bucc_seqReliability.append(0.95)
                  cbr.setbucc_Resolution(2.0)
               
                  cbr.setrefmac_title("Bucc Refmac run")
                
                  cbr.setrefmac_MTZIN(MODEL.cpirate_MTZfile)
                  cbr.setrefmac_PDBIN(MODEL.bucc_MTZOUTfile)
                  cbr.setrefmac_MTZOUT(MODEL.bucc_MTZINfile)
                  cbr.setrefmac_PDBOUT(MODEL.bucc_refmac_PDBOUTfile)
               
                  cbr.refmac_Col["FP"]=target_info.mtz_coldata["F"]
                  cbr.refmac_Col["SIGFP"]=target_info.mtz_coldata["SIGF"]
                  cbr.refmac_Col["HLA"]=target_info.mtz_coldata["HLA"]
                  cbr.refmac_Col["HLB"]=target_info.mtz_coldata["HLB"]
                  cbr.refmac_Col["HLC"]=target_info.mtz_coldata["HLC"]
                  cbr.refmac_Col["HLD"]=target_info.mtz_coldata["HLD"]
   
                  cbr.run()
   
   ##############################################################################################################################
   
               # If a solution is found output the results and exit                
               if mstat.solution_found == True:
                  if init.keywords.TRYALL == False:
                     mstat.mr_results.copy_solution_files(mstat, mstat.results_dir + '/solution')
                     mstat.mr_results.display_results(mstat, init, target_info)
                     break
   
            # Increment the counter 
            if MODEL.name[:14] == "ensemble_model" and mstat.MRPROGRAM == "MOLREP":
               if self.debug:
                  sys.stdout.write("Skipping counter increment for Molrep ensemble job\n")
            else:
   	       mstat.mr_counter=mstat.mr_counter+1
   
            mstat.model_list[model]=MODEL
   
            if init.keywords.CLUSTER == False:
              # Print out the summary of results so far, but only for non-parallel
              best=MRBUMP_writebest.BestLog()
              best.write_results_log(init, mstat)
              mstat.sorted_soln_list=best.sorted_soln_list
               
              sys.stdout.write(best.report)
   
            # If we have submitted enough jobs, then exit
            if model_count>=job_limit:
               break
   
      job_id_log.close()

   def print_job_details(self, MODEL, mstat, init):
      """ A function to output the details of the MR job to be submitted for execution. """

      # Print some details about this job
      sys.stdout.write("*********************************************************************************\n")
      sys.stdout.write("*********************************************************************************\n")
      sys.stdout.write("*********************************************************************************\n")
      sys.stdout.write("\n")
      sys.stdout.write("#####################################################\n")
      sys.stdout.write("Template Model %s: %s\n" % (MODEL.MR_job_number, MODEL.name))
      sys.stdout.write("#####################################################\n")
      sys.stdout.write("\n")
      sys.stdout.write("Working directory:\n    %s\n" % MODEL.model_directory)

      # List the models being used as input to the MR job
      if MODEL.num_per_ensem > 1:
         sys.stdout.write("Input search models: \n")
         for i in range(MODEL.num_per_ensem):
            if init.keywords.MDLCHAINSAW:
               sys.stdout.write("   " + MODEL.PDBfile[i] + "\n") 
            else:
               sys.stdout.write("   " + MODEL.PDBfile[i] + "\n") 
            sys.stdout.write("    Sequence ID: %.3f" % MODEL.seqID[i])
            if MODEL.rms[i] != 0.0:
               sys.stdout.write(" RMS value:  %.3f" % MODEL.rms[i])
            sys.stdout.write("\n")
      else:
         sys.stdout.write("Input search model:\n   %s\n" % MODEL.PDBfile[0])
         if MODEL.resolution_low == 0.0 and MODEL.resolution_high == 0.0:
            sys.stdout.write("Resolution Range for this model: Not Known\n") 
         else:
            sys.stdout.write("Resolution Range for this model: %.2lf - %.2lf Angstroms\n" % (MODEL.resolution_low, MODEL.resolution_high)) 

      sys.stdout.write("Search model type:             %s\n" % MODEL.type)
      sys.stdout.write("Molecular Replacement Program: %s\n" % mstat.MRPROGRAM)
      sys.stdout.write("Refinement Program:            Refmac5\n")
      sys.stdout.write("\n")

      # FIXED components
      if init.keywords.FIXED:
         sys.stdout.write("Fixed component(s) being used in search:\n")
         for i in init.keywords.fixed_list.keys():
            sys.stdout.write("File name: %s, Seq ID: %.3f\n" \
             % (init.keywords.fixed_list[i].filename, init.keywords.fixed_list[i].identity))
         if mstat.MRPROGRAM == "MOLREP" and init.keywords.fixedfile_count > 1: 
            sys.stdout.write("For Molrep these have been merged into the PDB file:\n  %s\n" % init.molrep_fixed_PDBfile)
         sys.stdout.write("\n")
 
   def sort_model_list(self, mstat):
      """ Sort the models in the list according to sequence identity with the target structure. """

      for name in mstat.sorted_MR_list:
         for model in mstat.model_list.keys():
            if mstat.model_list[model].chain_source == name and model not in mstat.sorted_model_list:
              mstat.sorted_model_list.append(model)
