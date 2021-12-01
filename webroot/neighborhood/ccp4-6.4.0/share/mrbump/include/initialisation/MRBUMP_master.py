#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#

import os, sys, string, time
import shutil
import urllib

#import MRBUMP_target_info
import Matches 
import Model
import Model_Queue
import Model_struct
import PQS
import PISA
import Ensemble
import MRBUMP_MR
import Cleanup
import MRBUMP_loggraphs
import WriteXML
import WriteLogfile
import Dummy_Run
import DB_write
import DB_handler

import MRBUMP_writebest
import MRBUMP_HHpred

class Master:
   """ Master script for running MRBUMP """
 
   def __init__(self):
      self.name = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def setDEBUG(self, flag):
      self.debug=flag  

   def fast_search_MR(self, init, target_info, mstat):

      queue = None

      # If we want to run a dummy job only (requires example data pickled in folder pickle_data. 
      # Also requires example log files from Phaser/Molrep/Refmac in the same directory
      if init.keywords.DUMMY:
         
         sys.stdout.write("##################################\n")
         sys.stdout.write("###      Running Dummy Job     ###\n")
         sys.stdout.write("##################################\n")
         sys.stdout.write("\n")
   
         dj=Dummy_Run.DummyJob()
         dj.run(init)      
  
         return

      # Set up the directories for the job
      mstat.setSearchDir(init.search_dir)
      mstat.setResultsDir(init.results_dir)
      mstat.setScratchDir(init.scratch_dir)

      # Start the connection to the DB Handler
      if init.keywords.DBOUT:
         mstat.Hdlr.start(init, mstat)

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            mstat.TP_JOB_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Target_Processing",
               "Process the target details")

            #mstat.conn.SetData(init.ProjectName, mstat.TP_JOB_ID,"TASKNAME", "Target_Processing")
            #mstat.conn.SetData(init.ProjectName, mstat.TP_JOB_ID,"TITLE", "Process the target details")
            mstat.conn.SetData(init.ProjectName, mstat.TP_JOB_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, mstat.TP_JOB_ID, init.seqin)
            if init.ONLYMODELS == False:
               mstat.conn.AddInputFile(init.ProjectName, mstat.TP_JOB_ID, init.hklin)
            TP_fail=False 
         except:
            TP_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Refmac job (post Target processing)\n")
            sys.stdout.write("\n")

      # Start the target data processing
      #target_info=MRBUMP_target_info.TargetInfo()

      # Set the log file for matthews coef job
#      target_info.setMattCoefLogfile(os.path.join(init.search_dir, "logs", "matt_coef.log"))

      # Set the target information
#      mstat.InitError = target_info.setTargetInfo(init, init.search_dir)
#      target_info.printTargetInfo(init)

      # Update the no. of mols in the a.s.u. if the user has specified a value
#      if init.keywords.NMASU != None:
#         print "The estimated number of molecules in the asu is: %d" % target_info.no_of_mols 
#         print "The user has specified a value of %d" % init.keywords.NMASU 
#         print "The value will be set to the user defined value"
#         mstat.setEstNoofMols(target_info.no_of_mols)
#         target_info.no_of_mols = init.keywords.NMASU

      # Set the DB's for local-based searches
      mstat.setFastaDB(os.path.join(init.mrbump,'data','pdb_ATOMseqs.txt'))

      # Set the output results html page
      if init.keywords.HTMLOUT == True:
         mstat.setResultsHTML(init.results_html)

      # Make a note of the start time for the job
      mstat.setStartTime(time.time())

      # Set the model preparation and MR parameters
      mstat.setMRNUM(init.keywords.MRNUM)
      mstat.setENSMODNUM(init.keywords.ENSMODNUM)

      # initialize the results page
      #w=Write_Search_results.Write_html()
      if init.keywords.HTMLOUT == True:
         mstat.search_results.write_header(init, mstat.results_html)
         mstat.search_results.write_footer(init, mstat, mstat.results_html)

      # write the target details
      if init.keywords.HTMLOUT == True:
         mstat.search_results.write_target_details(init, mstat, target_info, mstat.results_html)
      
      # If there was an error in the initialisation exit the program
      if mstat.job_end == True:

         # Tell the DB handler to stop
         if init.keywords.DBOUT:
            mstat.Hdlr.stop(mstat)

         sys.exit()
      
      # Assign the ignore list, i.e. the PDB codes that are to be ignored
      mstat.ignore_list=init.keywords.ignore_list
   
      # Assign the include list, i.e. the CHAIN codes that are to be included
      mstat.include_list=init.keywords.include_list
   
      # The following sections are only carried out if we are running in MR mode 
      #if init.ONLYMODELS == False:

      # Set the status to be finished in the DB
      if init.keywords.DBOUT:
         if TP_fail == False:
            # Add the various output files
            mstat.conn.AddOutputFile(init.ProjectName, mstat.TP_JOB_ID, target_info.seqfile)
            if init.ONLYMODELS == False:
               mstat.conn.AddOutputFile(init.ProjectName, mstat.TP_JOB_ID, target_info.matt_coef_logfile)
               if init.keywords.ENANT:
                  mstat.conn.AddOutputFile(init.ProjectName, mstat.TP_JOB_ID, target_info.enant_hklin)

            # Set the logfile
            mstat.conn.SetLogfile(init.ProjectName, mstat.TP_JOB_ID, target_info.logfile)
   
            mstat.conn.SetData(init.ProjectName, mstat.TP_JOB_ID,"STATUS", "FINISHED")
         elif TP_fail:
            TP_fail=False

      # Set up the FASTA search
      seq_search=Matches.SEQ_match()

      # If DOFASTA is true do the fasta search otherwise just add the specified chain IDs
      if init.keywords.DOFASTA == True:

         # Search information
         sys.stdout.write("\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("###         Fasta search        ###\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("\n")
   
         # Get the FASTA file using the target sequence
         seq_search.get_Fasta_file(init, mstat, target_info, os.path.join(mstat.results_dir,'data','matches'), \
            init.environment.SETUP_DIR)
   
         # Add the resulting chains to the chain list
         seq_search.get_Fasta_matches(init, mstat, target_info, "FASTA")

      # If DOHHPRED is true do the hhblits search otherwise just add the specified chain IDs
      if init.keywords.DOHHPRED == True:

         # Search information
         sys.stdout.write("\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("###        HHpred search        ###\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("\n")
   
         # Set the name of the output alignment file 
         mstat.hhpredALNFile=os.path.join(init.search_dir, "sequences", "hhpred_alignment.a3m")

         # Instantiate
         HHBLITS=MRBUMP_HHpred.HHblits()

         # Run it
         HHBLITS.setHhblitsLogFile(os.path.join(init.search_dir, "logs", "hhblits.log"))
         HHBLITS.setHhReformatLogFile(os.path.join(init.search_dir, "logs", "hhreformat.log"))
         HHBLITS.runHHblits(target_info.seqfile, init.keywords.HHDBPDB, mstat.hhpredALNFile, 2)
         mstat.hhpredList=HHBLITS.hitList

         # Add the resulting chains to the chain list
         seq_search.get_Fasta_matches(init, mstat, target_info , "HHPRED")

         # Set the alignment for each chain that was found in the HHpred search
         for chain in HHBLITS.chainDict.keys():
             mstat.chain_list[chain].HHalignment=HHBLITS.chainDict[chain].alignment
             mstat.chain_list[chain].HHtargetSequence=HHBLITS.chainDict[chain].targetSequence
             mstat.chain_list[chain].HHmatch=True

      # Add the specified chains to the list
      seq_search.add_included_chains(init, mstat)

      # Add the specified chains from local files 
      seq_search.add_local_chains(init, mstat, target_info)

      # Process the results from the FASTA search
      if mstat.no_of_SEQhits > 0:
         ps=Matches.Process_Score()
      
         sys.stdout.write("\n")
         sys.stdout.write("---------------------------------------------------------\n")
         sys.stdout.write("Fasta: Getting Template Sequences and Multiple Alignment:\n")
         sys.stdout.write("---------------------------------------------------------\n")
         sys.stdout.write("\n")
   
         #ps.PDB_process(mstat, 'SEQ')
   
         # Extract the sequences for the chains from the pdb datafile
         ps.getPDB_sequences(init, mstat, "SEQ")
   
         # Set the names of the input and output files to be used in the multiple alignment 
         mstat.setAllRawFile(os.path.join(init.search_dir,"sequences","All_raw_seqs_SEQ.fasta"))
         mstat.setAllAlignFile(os.path.join(init.search_dir,"sequences","All_align_seqs_SEQ.fasta"))
   
         # Do the multiple alignment
         ps.alignment(mstat.chain_list.keys(), target_info, init, mstat)
   
         # Get the top hit and sort the list of aligned sequences
         ps.get_top_hit(mstat.chain_list.keys(), init, mstat)
   
         sys.stdout.write("Top match from FASTA search: %s\n" % mstat.top_match_chainid)
   
         # First check if it is one of the local PDB files
         #if mstat.top_match_chainid[0:3]=="loc":
         #   mstat.FASTA_top_match_PDBfile=init.keywords.local_list[mstat.top_match_chainid].filename
         #else:
         #   mstat.FASTA_top_match_PDBfile=os.path.join(init.search_dir, "scratch", mstat.top_match_pdbid + ".pdb")
         #   pdb_get=Matches.PDB_get()
         #   pdb_get.download_single_PDB(mstat.top_match_pdbid, mstat.FASTA_top_match_PDBfile, init.keywords.PDBDIR)

         ##################################################################
         ####                 Output to the Database                   ####              
         ##################################################################
   
         # Update the DB with the details of the alignment and sorting 
         if init.keywords.DBOUT and init.keywords.DOFASTA:
            db=DB_write.DB_output()
           
            # Add all the files to be included as input files
            mstat.FS_input_files.append(target_info.seqfile)
            mstat.FS_input_files.append(mstat.all_raw_file)
            for key in init.keywords.local_list.keys():
               mstat.FS_input_files.append(init.keywords.local_list[key].filename)
             
            # Add output files
            mstat.FS_output_files.append(mstat.all_align_file)
            #mstat.FS_output_files.append(mstat.FASTA_top_match_PDBfile)
   
            if init.keywords.DOFASTA:
               db.search_job(init, mstat, "FASTA", mstat.FS_input_files, mstat.FS_output_files, mstat.SEQmatchfile)
            else:
               db.search_job(init, mstat, "FASTA", mstat.FS_input_files, mstat.FS_output_files)
               
            # Capture the Job ID and whether or not the record creation was successful
            mstat.FS_JOB_ID=db.JOB_ID
            FS_Fail=db.DB_fail
         
         ##################################################################

      # Exit if no hits were found
      if mstat.no_of_SEQhits == 0:
         if init.keywords.HTMLOUT == True:
            mstat.search_results.write_SEQ_search_details(mstat, mstat.results_html)

         ##################################################################
         ####                 Output to the Database                   ####              
         ##################################################################
   
         # Update the DB with the details of the alignment and sorting 
         if init.keywords.DBOUT and init.keywords.DOFASTA:
            db=DB_write.DB_output()
           
            # Add all the files to be included as input files
            mstat.FS_input_files.append(target_info.seqfile)
             
            if init.keywords.DOFASTA:
               db.search_job(init, mstat, "FASTA", mstat.FS_input_files, mstat.FS_output_files, mstat.SEQmatchfile)
            else:
               db.search_job(init, mstat, "FASTA", mstat.FS_input_files, mstat.FS_output_files)
               
            # Capture the Job ID and whether or not the record creation was successful
            mstat.FS_JOB_ID=db.JOB_ID
            FS_Fail=db.DB_fail
         
            # Mark the FASTA job as having finished
            db.finish_job(init, mstat, mstat.FS_JOB_ID)

            # Tell the DB handler to stop
            mstat.Hdlr.stop(mstat)

         ##################################################################

         sys.exit()
   
      # write the SEQ search details to the html page
      if init.keywords.HTMLOUT == True:
         mstat.search_results.write_SEQ_search_details(init, mstat, mstat.results_html)

      #shutil.copy('/tmp/ssm_result.xml', mrsearchdir + '/results/ssm_result.xml')

      if init.keywords.SSM == True:

         sys.stdout.write("\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("###          SSM search         ###\n")
         sys.stdout.write("###################################\n")
         sys.stdout.write("\n")

         ssm_search=Matches.SSM_match()

         ssm_search.setSSMScript(os.path.join(init.mrbump_incl,'perl','ssm.pl'))
         ssm_search.get_SSM_file(init, mstat, init.keywords.JOBID, os.path.join(mstat.results_dir,'data','ssm_result.xml'))

         # Check to see if the SSM search failed
         if init.keywords.SSM:
            ssm_search.get_SSM_matches(init, mstat)

            sys.stdout.write("\n")
            sys.stdout.write("-------------------------------------------------------\n")
            sys.stdout.write("SSM: Getting Template Sequences and Multiple Alignment:\n")
            sys.stdout.write("-------------------------------------------------------\n")
            sys.stdout.write("\n")

            #ps.PDB_process(mstat, 'SSM')

            # Extract the sequences for the chains from the pdb datafile
            ps.getPDB_sequences(init, mstat, "SSM")
   
            # Set the names of the input and output files to be used in the multiple alignment 
            mstat.setAllRawFile(os.path.join(init.search_dir,"sequences","All_raw_seqs_SSM.fasta"))
            mstat.setAllAlignFile(os.path.join(init.search_dir,"sequences","All_align_seqs_SSM.fasta"))
   
            # Do the multiple alignment
            ps.alignment(mstat.chain_list.keys(), target_info, init, mstat)

            # Get the top hit and sort the list of aligned sequences
            ps.get_top_hit(mstat.chain_list.keys(), init, mstat)

            # write the SSM search details to the html page
            if init.keywords.HTMLOUT == True:
               mstat.search_results.write_SSM_search_details(init, mstat, mstat.results_html)
 
            # Write out the target processing logfile
            ssmlog=WriteLogfile.Logfile()
            ssmlog.writeSSMLog(init, mstat)
            mstat.SSM_logfile=ssmlog.logfile

            ##################################################################
            ####                 Output to the Database                   ####              
            ##################################################################
   
            # Update the DB with the details of the alignment and sorting 
            if init.keywords.DBOUT:
               db=DB_write.DB_output()
           
               # Add all the files to be included as input files
               #mstat.SS_input_files.append(mstat.FASTA_top_match_PDBfile)
               mstat.SS_input_files.append(target_info.seqfile)
               mstat.SS_input_files.append(mstat.all_raw_file)
             
               # Add output files
               mstat.SS_output_files.append(mstat.all_align_file)
               mstat.SS_output_files.append(mstat.SSM_resultsfile)
   
               db.search_job(init, mstat, "SSM", mstat.SS_input_files, mstat.SS_output_files, mstat.SSM_logfile)
               
               # Capture the Job ID and whether or not the record creation was successful
               mstat.SS_JOB_ID=db.JOB_ID
               SS_Fail=db.DB_fail
            
            ##################################################################

      # Prune the list
      ps.prune_list(mstat)
      ps.print_list(mstat)
 
      #Ouput the loggraph data for the alignment results
      lg_plot=MRBUMP_loggraphs.Mrbump_logs()
      lg_plot.plot_alignment_graphs(init, mstat)
  
      ps.PDB_process(init, mstat)
 
      ##################################################################
      ####                 Output to the Database                   ####              
      ##################################################################
   
      # Mark the FASTA search job as being finished in the CCP4i DB
      if init.keywords.DBOUT:
         if init.keywords.DOFASTA:
            if FS_Fail == False:
     
               # Add the PDB files to the output from the SEQ job
               for chain in mstat.sorted_MR_list:
                  if mstat.chain_list[chain].source=="SEQ":
                     mstat.conn.AddOutputFile(init.ProjectName, mstat.FS_JOB_ID, mstat.chain_list[chain].unprocessed_PDBFile)
          
               # Mark the FASTA job as being finished
               #mstat.conn.SetJobQuality(init.ProjectName, mstat.FS_JOB_ID,-1)
               db.finish_job(init, mstat, mstat.FS_JOB_ID)

         if init.keywords.SSM:
            if SS_Fail == False:

               # Add the PDB files to the output from the SSM job
               for chain in mstat.sorted_MR_list:
                  if mstat.chain_list[chain].source=="SSM":
                     mstat.conn.AddOutputFile(init.ProjectName, mstat.SS_JOB_ID, mstat.chain_list[chain].unprocessed_PDBFile)

               # Mark the SSM job as being finished
               db.finish_job(init, mstat, mstat.SS_JOB_ID)
            
      ##################################################################

      # Search the SCOP database to see if any domains exist in the template structures
      if init.keywords.SCOP == True:

         sys.stdout.write("\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("###          Searching for Domains (SCOP)         ###\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("\n")

         scop_search=Matches.SCOP_match()
         scop_search.get_SCOP_matches(init, mstat, init.environment.SETUP_DIR)
   
         if mstat.no_of_SCOPhits > 0:
            sys.stdout.write("\n")
            sys.stdout.write("---------------------------\n")
            sys.stdout.write("SCOP: Processing PDB files:\n")
            sys.stdout.write("---------------------------\n")
            sys.stdout.write("\n")

         # ps.PDB_process(mstat, 'SCOP')

         # Extract the sequences for the chains from the pdb datafile
         #ps.getPDB_sequences(init, mstat, "SSM")
   
         # Set the names of the input and output files to be used in the multiple alignment 
         mstat.setAllRawFile(os.path.join(init.search_dir, "sequences", "All_raw_seqs_SCOP.fasta"))
         mstat.setAllAlignFile(os.path.join(init.search_dir, "sequences", "All_align_seqs_SCOP.fasta"))

         # Add the SCOP results into the MR list before re-alignment and sorting   
         mstat.sorted_MR_list = mstat.sorted_MR_list + mstat.Domains_list

         # Do the multiple alignment
         ps.alignment(mstat.sorted_MR_list, target_info, init, mstat)

         # Get the top hit and sort the list of aligned sequences
         ps.get_top_hit(mstat.sorted_MR_list, init, mstat)

         # write the SSM search details to the html page
         if init.keywords.HTMLOUT == True:
            mstat.search_results.write_domains_search_details(init, mstat, mstat.results_html)
 
         # Re-sort the list to take into account the SCOP results scores
         ps.re_sort_MR_list(mstat)
         ps.print_pruned_list(mstat)

         ##################################################################
         ####                 Output to the Database                   ####              
         ##################################################################
   
         # Update the DB with the details of the SCOP search 
         if init.keywords.DBOUT:
            db=DB_write.DB_output()
           
            # Add all the files to be included as input files
            mstat.ScS_input_files.append(target_info.seqfile)
            mstat.ScS_input_files.append(mstat.all_raw_file)
             
            # Add output files
            mstat.ScS_output_files.append(mstat.all_align_file)
   
            db.search_job(init, mstat, "SCOP", mstat.ScS_input_files, mstat.ScS_output_files, mstat.SCOP_results_file)
               
            # Capture the Job ID and whether or not the record creation was successful
            mstat.ScS_JOB_ID=db.JOB_ID
            ScS_Fail=db.DB_fail
         
         # Mark the FASTA search job as being finished in the CCP4i DB
         if init.keywords.DBOUT and ScS_Fail==False:

            # Add the PDB files to the output from the SSM job
            scop_added_list=[]
            scop_input_files=[]
            for chain in mstat.sorted_MR_list:
               if mstat.chain_list[chain].source=="SCOP":
                  # Only add the files not already added
                  if chain[0:4] not in scop_added_list:
                     mstat.conn.AddOutputFile(init.ProjectName, mstat.ScS_JOB_ID, mstat.chain_list[chain].unprocessed_PDBFile)
                     scop_input_files.append(mstat.chain_list[chain].unprocessed_PDBFile)
                  scop_added_list.append(chain[0:4])

            db.finish_job(init, mstat, mstat.ScS_JOB_ID)
   
            # Add another DB record to record the SCOP file preparation if there were any SCOP hits
            if mstat.no_of_SCOPhits > 0:
               DB_fail=False
               try: 
                  job_ID=mstat.conn.AddSubJob( \
                     init.ProjectName,init.JobId,
                     "Process_SCOP_results",
                     "Extract the domains found in the SCOP search from the parent PDB files")
   
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Process_SCOP_results")
                  #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", \
                  #      "Extract the domains found in the SCOP search from the parent PDB files")
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
                  
                  # Add the input PDB files to the DB records
                  for PDBFile in scop_input_files:
                     mstat.conn.AddInputFile(init.ProjectName, job_ID, PDBFile)
   
                  # Add the processed PDB files containing the individual domains to the DB records
                  for chain in mstat.sorted_MR_list:
                     if mstat.chain_list[chain].source=="SCOP":
                        print mstat.chain_list[chain].PDBFile
                        mstat.conn.AddOutputFile(init.ProjectName, job_ID, mstat.chain_list[chain].PDBFile)
                  mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.SCOP_results_file)
               except:
                  DB_fail=True 
                  sys.stdout.write("DB error: Could not enter a new record for SCOP preparation\n")
                  sys.stdout.write("\n")
      
               # Set the status to be finished in the DB
               if init.keywords.DBOUT and DB_fail == False:
                  mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
               elif DB_fail:
                  DB_fail=False

      # write the overall search details to the html page
      if init.keywords.HTMLOUT == True:
         mstat.search_results.write_ALL_search_details(init, mstat, target_info, mstat.results_html)
      
      ##################################################################
      ####                 Output to the Database                   ####              
      ##################################################################
   
      # Update the DB with the details of the alignment and sorting 
      #if init.keywords.DBOUT:
      #   db=DB_write.DB_output()
      #   db.align_sort(init, mstat, mstat.all_raw_file, mstat.all_align_file)
# 
#         # Capture the Job ID and whether or not the record creation was successful
#         mstat.AS_JOB_ID=db.JOB_ID
#         AS_Fail=db.DB_fail
#      
#      # Mark the Align and Sort job as being finished in the CCP4i DB
#      if init.keywords.DBOUT and AS_Fail==False:
#         db.finish_job(init, mstat, mstat.AS_JOB_ID)

      ##################################################################

      # Do the modelling of the PDB model structures
      sys.stdout.write("\n")
      sys.stdout.write("###########################################\n")
      sys.stdout.write("###       Search Model Preparation      ###\n")
      sys.stdout.write("###########################################\n")
      sys.stdout.write("\n")
      
      # Output the details of what will be modelled
      sys.stdout.write("The following types of model will be generated:\n")
      sys.stdout.write("\n")
      for i in init.model_types:
         sys.stdout.write("%s -- " % i)
         if i == 'UNMOD':
            sys.stdout.write("Unmodified models.\n") 
         if i == 'PDBCLP':
            sys.stdout.write("PDBclip model, waters, hydrogens removed + most probable side-chain conformations.\n") 
         if i == 'PLYALA':
            sys.stdout.write("Polyalanine model, all side chains removed.\n") 
         if i == 'MOLREP':
            sys.stdout.write("Molrep generated model, side chains pruned according to sequence alignment.\n") 
         if i == 'CHNSAW':
            sys.stdout.write("Chainsaw generated model, side chains pruned according to sequence alignment.\n") 
         if i == 'SCLPTR':
            sys.stdout.write("Sculptor generated model, side chains pruned according to sequence alignment.\n") 
      sys.stdout.write("\n")

      model=Model.Modelling()
      model.convert_to_pir(mstat, target_info)

      # Prepare polyalanine models using 
      if init.keywords.MDLUNMOD:
         model.unmodModel(target_info, init, mstat)

      # Prepare polyalanine models using 
      if init.keywords.MDLPLYALA:
         model.polyala(target_info, init, mstat)

      # Prepare models using Molrep
      if init.keywords.MDLMOLREP:
         model.molrepModel(target_info, init, mstat)
      
      # Multiple alignment input to Chainsaw
      if init.keywords.MDLCHAINSAW:
         model.chainsawModel(target_info, init, mstat)
      
      # Multiple alignment input to Sculptor
      if init.keywords.MDLSCULPTOR:
         model.sculptorModel(target_info, init, mstat)

      # Monitor the queue for the completion of all the jobs
      
      if init.keywords.CLUSTER == True:
         queue=Model_Queue.Queue_info()
         queue.qstat_check(init, mstat, target_info, 'MODEL_PREP')

         # Print out the summary of results so far
         #best=MRBUMP_writebest.BestLog()
         #best.write_results_log(init, mstat)
         #mstat.sorted_soln_list=best.sorted_soln_list
         #sys.stdout.write(best.report)

         mstat.resetJobid_Array()
         mstat.resetJobid_Dict()
         mstat.resetJobName_Dict()
   
      # write the overall search details to the html page
      mstat.search_results.write_model_prep_details(init, mstat, target_info, mstat.results_html)
      
      # Ouput the loggraph data for the model preparation results
      if init.keywords.MDLMOLREP or init.keywords.MDLCHAINSAW:
         lg_plot=MRBUMP_loggraphs.Mrbump_logs()
         lg_plot.plot_model_prep_graphs(init, mstat)

         ##################################################################

      # Note on PISA positioning
      # Needs to be after PDB coord download, and before ONLYMODELS exit. 
      # Have it after model editing so that we form multimers of models rather than templates.
      # Having it after SCOP means we could have multimers of domains.

      # If the number of molecules in our target is greater than 1 consult PISA for multimers
      if target_info.no_of_mols >= 2 and init.keywords.PISA == True:

         sys.stdout.write("\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("###          Searching for Multimers (PISA)       ###\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("\n")
      
         pisa=PISA.PISA()
         pisa.get_pisa_files(target_info, init, mstat)
   
      # Ensemble preparation moved here from MR_start
      # If we are using an Ensemble model then set it up. We now do this
      # whatever MR program chosen - Molrep should ignore an ensemble_model model.
      if init.keywords.USEENSEM:

         sys.stdout.write("############################################################################\n")
         sys.stdout.write("### Model Preparation log: Setting up ensemble (used if Phaser selected) ###\n")
         sys.stdout.write("############################################################################\n")
         sys.stdout.write("\n")

         # Make sure we are not asking for more models than are in the MR list
         if mstat.num_MR_models < init.keywords.ENSMODNUM:
            init.keywords.ENSMODNUM=mstat.num_MR_models
            sys.stdout.write("Resetting the number in the ensemble to " + `init.keywords.ENSMODNUM`
                             + " as there are not enough models for the specified value\n")
            sys.stdout.write("\n")

         ens=Ensemble.Ensemble()
         ens.setup_ensemble(mstat, init)

         # write the ensemble details to the html page
         if init.keywords.HTMLOUT == True:
            mstat.search_results.write_ensemble_details(init, mstat, target_info, mstat.results_html)
   
      else:
         sys.stdout.write("Model Preparation log: Use Ensemble set to 'False' - no ensemble will be created.\n")
         sys.stdout.write("\n")
 
      #If user only wants to generate the models then we will exit at this point.
      if init.ONLYMODELS == True:

         # Output the list of models that has been created
         mr_setup=Model_struct.MR_setup()
         mr_setup.setTypes(init, mstat, init.search_dir)

         # Print the references and exit
         if init.keywords.HTMLOUT == True:
            mstat.mr_results.print_references(init, mstat)
         mstat.mr_results.print_references_stdout(init)

         # Close the connection to the DB handler
         if init.keywords.DBOUT:
            mstat.Hdlr.stop(mstat)
           
         # Pickle the objects for running as input for a dummy run later
         if init.keywords.PICKLE:
         
            # We can't pickle the datahandler object so we reset to something simple
            mstat.conn = ""

            sys.stdout.write("#############################################################\n")
            sys.stdout.write("###      Pickling the objects for running a dummy job     ###\n")
            sys.stdout.write("#############################################################\n")
            sys.stdout.write("\n")
   
            dj=Dummy_Run.DummyJob()
            dj.pickle(init, mstat, target_info)      
    
         finish_time = time.ctime()
         finish_file = open(os.path.join(mstat.results_dir,'finished.txt'), 'w')
         finish_file.write('Job finished: ' + finish_time)
         finish_file.write('')
         finish_file.write('Information only, please do not reply to this email.')
         finish_file.close()
      
         sys.exit(0)      

      # Setup the models for MR
      mr_setup=Model_struct.MR_setup()
      mr_setup.setTypes(init, mstat, init.search_dir)
      
      # Write the header for the MR secion
      if init.keywords.HTMLOUT==True:
         mstat.mr_results.write_MR_header(init, mstat)

      return queue
      
   def runMR(self, init, target_info, mstat, queue=None):
      """ Function for running molecular replacement. """   

      # Start the connection to the DB Handler (if it's required and not already running)
      if init.keywords.DBOUT and init.MRONLY:
         mstat.Hdlr=DB_handler.Handler()
         mstat.Hdlr.start(init, mstat)

      #  Announce the Molecular Replacement stage
      sys.stdout.write("##############################################################\n")
      sys.stdout.write("###           Molecular Replacement and Refinement         ###\n")
      sys.stdout.write("##############################################################\n")
      sys.stdout.write("\n")
      
      # If the number of molecules in our target is greater than 1 consult PQS for multimers
      if target_info.no_of_mols >= 2 and init.keywords.PQS == True:
      
         print ""
         print "------------------------------"
         print "Searching for Multimers (PQS):"
         print "------------------------------"
         print ""
      
         pqs=PQS.PQS()
      
         pqs.set_pqs_list(init.environment.SETUP_DIR)
         pqs.get_pqs_files(init, target_info, mstat, init.keywords.MAPROGRAM)
      
         # write the PQS search details to the html page
         if init.keywords.HTMLOUT == True:
            mstat.search_results.write_PQS_search_details(init, mstat, target_info, mstat.results_html)
      
      # Do the molecular replacement using the model list
      MR=MRBUMP_MR.MR_submit()
      
      # Loop over the list of MR programs set at the start
      #for MRPROGRAM in init.keywords.MR_PROGRAM_LIST: 

      sys.stdout.write("*********************************************************************************\n")
      sys.stdout.write("*********************************************************************************\n")
      sys.stdout.write("*********************************************************************************\n")

      # Echo the name of the MR program being used to the stdout
      #sys.stdout.write("MR log: Using " + MRPROGRAM + " for molecular replacement:\n")
      #sys.stdout.write("\n")
           
      #mstat.setMRPROGRAM(MRPROGRAM.upper())
      MR.MR_start(target_info, init, mstat, init.keywords.QSIZE)
      
#>>>>>>>>>>>

      # Poll the queue to see if the jobs have finished
      if init.keywords.CLUSTER == True:
   
         print ""
         print "---------------------------"
         print "Results (post-refinement):"
         print "---------------------------"
         print ""
        
         if queue==None:
            queue=Model_Queue.Queue_info()
         queue.qstat_check(init, mstat, target_info, 'MOL_REPLACE', MR)
         mstat.resetJobid_Array()
         mstat.resetJobid_Dict()
         #mstat.resetJobName_Dict()
   
         # Print out the summary of results so far
         best=MRBUMP_writebest.BestLog()
         best.write_results_log(init, mstat)
         mstat.sorted_soln_list=best.sorted_soln_list
         sys.stdout.write(best.report)

      # If running in TRYALL mode capture a summary of the results
      if init.keywords.TRYALL:
         mstat.mr_results.setTRYALL_summary(init, mstat)
        
#>>>>>>>>>>>

      if mstat.solution_found == False: 
         sys.stdout.write("\n")
         sys.stdout.write("No solution was found using the following MR programs:\n")
         count=1
         for MRPROGRAM in init.keywords.MR_PROGRAM_LIST:
            sys.stdout.write(`count` + ". " + MRPROGRAM + "\n")
            count=count + 1
         sys.stdout.write("\n")

      # If running in TRYALL mode output a summary of the results for each MR program
      #for MRPROGRAM in init.keywords.MR_PROGRAM_LIST: 
      #   if init.keywords.TRYALL:
      #      sys.stdout.write(mstat.TRYALL_summary[MRPROGRAM])

      # write the final solution details to the html page
      mstat.setJob_End(True)
      if init.keywords.HTMLOUT==True:
         mstat.mr_results.write_final_soln(init, mstat, target_info)

      # Display the references in the results html file and the output logfile.
      if init.keywords.HTMLOUT==True:
         mstat.mr_results.print_references(init, mstat)
      mstat.mr_results.print_references_stdout(init)

      if mstat.solution_found == True and init.keywords.TRYALL == False:
         if mstat.soln_MRprogram == "MOLREP":
            shutil.copy(mstat.model_list[mstat.soln_model].refmac_molrep_MTZOUTfile , init.hklout)
            shutil.copy(mstat.model_list[mstat.soln_model].refmac_molrep_PDBfile , init.xyzout)
         if mstat.soln_MRprogram == "PHASER":
            shutil.copy(mstat.model_list[mstat.soln_model].refmac_phaser_MTZOUTfile , init.hklout)
            shutil.copy(mstat.model_list[mstat.soln_model].refmac_phaser_PDBfile , init.xyzout)
           
      # Ouput the job details to an XML file
      if init.keywords.XMLOUT:
         xml=WriteXML.writeXML()
         xml.write_details(init, mstat, target_info, init.keywords.SUMMARYFILE) 

      # Tell the DB handler to stop
      if init.keywords.DBOUT:
         mstat.Hdlr.stop(mstat)

      # Pickle the objects for running as input for a dummy run later
      if init.keywords.PICKLE:
        
         # We can't pickle the datahandler object so we reset to something simple
         mstat.conn = ""

         sys.stdout.write("#############################################################\n")
         sys.stdout.write("###      Pickling the objects for running a dummy job     ###\n")
         sys.stdout.write("#############################################################\n")
         sys.stdout.write("\n")
   
         dj=Dummy_Run.DummyJob()
         dj.pickle(init, mstat, target_info)      

      finish_time = time.ctime()
      finish_file = open(os.path.join(mstat.results_dir,'finished.txt'), 'w')
      finish_file.write('Job finished: ' + finish_time)
      finish_file.write('')
      finish_file.write('Information only, please do not reply to this email.')
      finish_file.close()
      
      # If running in LITE mode remove the input and PDB_files directories contents
      if init.keywords.LITE:
         purge=Cleanup.Clean()
         purge.purgeDirectory(os.path.join(init.search_dir, "logs"))
         purge.purgeDirectory(os.path.join(init.search_dir, "PDB_files"))
         purge.purgeDirectory(os.path.join(init.search_dir, "scratch"))
         purge.purgeDirectory(os.path.join(init.search_dir, "results", "data"))
         

      # Remove the data directory to save memory space
      # if init.keywords.DEBUG == False and init.keywords.TRYALL == False:
      if init.keywords.CLEAN:
         print "Cleanup: Removing surplus search data and scratch directory"
         cleanup=Cleanup.Clean()
         cleanup.clean_data_dir(mstat)
         cleanup.rm_dir(os.path.join(init.search_dir,'scratch'))
      
      sys.exit(0)
