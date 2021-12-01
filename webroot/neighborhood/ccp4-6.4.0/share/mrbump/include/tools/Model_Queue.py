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

import os, string, sys, time
#import sets 
import Get_MR_sum
import Solution_struct
import MRBUMP_writebest
import subprocess, shlex
import Cleanup


class Soln_Model:
   """ A class used for holding solution model details """
 
   def __init__(self):
    
      self.model_name=""

class Queue_info:
   """ A class to handle batch queue system interactions. """

   def __init__(self):

      #self.queue_job_array=sets.Set([])
      self.queue_job_array=set([])
      self.job_completion=False
      self.finished_jobs=[]
      self.latest_jobs=[]
      self.RESULT=False
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def qstat_check(self, init, mstat, target_info, JOB_TYPE, MR=None):
      """ A function to test the SGE/PBS clustering for completion of a list of jobs denoted by
      their job ID's. Needs a "set" of job id's as input. """ 

      # Continuously check the queue to see if our jobs have finished
      while self.job_completion == False:

         # Set the command line
         command_line = "qstat"
     
         # Launch
         if os.name == "nt":
            process_args = shlex.split(command_line, posix=False)
            p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE)
         else:
            process_args = shlex.split(command_line)
            p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)

         (q, i) = (p.stdout, p.stdin)
     
         i.close()

         q=os.popen('qstat', 'r')
         header1=q.readline()
         header2=q.readline()
         line=q.readline() 

         log_file = open(os.path.join(init.search_dir, 'bulkMR.log'),'w')

         while line:
            if init.keywords.QTYPE == "SGE":
               self.queue_job_array.add((int)((string.split(string.strip(line)))[0]))
            elif init.keywords.QTYPE == "PBS":
               # So it won't get tripped up by ids of the form "NNNNNN-1" and "NNNNNN-2"
               id=string.split(string.strip(line),".")[0]
               id=string.split(id,'-')[0] 
               self.queue_job_array.add(int(id))
            line=q.readline() 

         q.close()

         # Check the cluster queue to see if there are any jobs still running.
         # If there are jobs still running find out which ones have just completed.
         if mstat.jobid_array.intersection(self.queue_job_array):
             
            if JOB_TYPE == 'MOL_REPLACE' and mstat.solution_found == False:
               for job_name in self.latest_jobs:
                  self.finished_jobs.append(job_name)

               self.latest_jobs=[]
               for jobID in mstat.jobid_array.difference(self.queue_job_array):
                  if mstat.jobid_dict[jobID] not in self.finished_jobs:
                     self.latest_jobs.append(mstat.jobid_dict[jobID])

               num_MR_jobs = 0
               if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                 num_MR_jobs = len(mstat.sorted_model_list)
               if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                 num_MR_jobs += len(mstat.sorted_model_list)
               if init.keywords.USEENSEM:
                 num_MR_jobs -= 1
               if self.debug:
                  sys.stdout.write("DEBUG - Model_Queue.qstat_check : Number of MR jobs: %d\n" % num_MR_jobs)
                  sys.stdout.write("DEBUG - Model_Queue.qstat_check : Number of parallel jobs running: %d\n" % mstat.parallel_jobs_running)
                  if init.keywords.QSIZE == sys.maxint:
                     sys.stdout.write("DEBUG - Model_Queue.qstat_check : Maximum jobs at any one time (QSIZE): Unlimited\n")
                  else:
                     sys.stdout.write("DEBUG - Model_Queue.qstat_check : Maximum jobs at any one time (QSIZE): %d\n" % init.keywords.QSIZE)
                 
               mstat.parallel_jobs_finished = len(self.finished_jobs)               
               self.check_result_parallel(init, mstat, target_info)
                

            mstat.parallel_jobs_running = len(mstat.jobid_array.intersection(self.queue_job_array))
            log_file.write("%d jobs still running/pending at %s" % (mstat.parallel_jobs_running, time.ctime()))
            # If under threshold, then submit more jobs
            if mstat.parallel_jobs_running < init.keywords.QSIZE and MR!=None:
              sys.stdout.write("Submitting more jobs... %d %d\n" % (mstat.parallel_jobs_running, init.keywords.QSIZE))
              MR.MR_start(target_info, init, mstat, init.keywords.QSIZE - mstat.parallel_jobs_running)

            #print "%s jobs still running/pending" % len(mstat.jobid_array.intersection(self.queue_job_array))
            # print "ID's of jobs still running/pending: %s" % mstat.jobid_array.intersection(self.queue_job_array)
            time.sleep(10)
            self.queue_job_array.clear()
        
         # Otherwise, process the jobs that have just completed and finish. 
         else:
            self.job_completion=True
            mstat.parallel_jobs_running = 0

            if (JOB_TYPE == 'MOL_REPLACE' and mstat.solution_found == False) \
               or (JOB_TYPE == 'MOL_REPLACE' and init.keywords.TRYALL == True):
               for job_name in self.latest_jobs:
                  self.finished_jobs.append(job_name)

               self.latest_jobs=[]
               for jobID in mstat.jobid_array.difference(self.queue_job_array):
                  if mstat.jobid_dict[jobID] not in self.finished_jobs:
                     self.latest_jobs.append(mstat.jobid_dict[jobID])
                
               mstat.parallel_jobs_finished = len(self.finished_jobs)
               self.check_result_parallel(init, mstat, target_info)

            if mstat.solution_found == False and JOB_TYPE == 'MOL_REPLACE' and mstat.MRPROGRAM == 'MOLREP':
               sys.stdout.write("No solution found using Molrep, trying Phaser.\n")
               sys.stdout.write("\n")
            elif mstat.solution_found == False and JOB_TYPE == 'MOL_REPLACE' and mstat.MRPROGRAM == 'PHASER':
               sys.stdout.write("No solution found using Phaser.\n")
               sys.stdout.write("All jobs complete\n")
               sys.stdout.write("\n")
            else:
               sys.stdout.write("All jobs complete\n")
               sys.stdout.write("\n")

      # reset the job_completion flag and the finished and latest job arrays.
      self.job_completion=False
      self.finished_jobs=[]
      self.latest_jobs=[]
      log_file.close()


   def check_result_parallel(self, init, mstat, target_info):
      """ A function to check the refinement results for the finished jobs in parallel run."""

      # Loop over the list of models that have justed completed refinement.
      for job in self.latest_jobs:

         # Get the model name
         model      = mstat.jobname_dict[job].model_name

         sys.stdout.write("\n")
         sys.stdout.write("#########################################################################\n")
         sys.stdout.write("Job '%s' has completed for model '%s'\n" % (job, model))
         sys.stdout.write("#########################################################################\n")
         sys.stdout.write("\n")

         #if self.debug:
         #   print "Checking the PDB summary log file for model: " + model + "...."
         #   print "File name: " + mstat.model_list[model].mr_pdb_sum_logfile
         #  print ""

         #f os.path.isfile(mstat.model_list[model].mr_pdb_sum_logfile):
         #  if self.debug:
         #     print "File exists"
         #     print ""

            # Extract the number of chains from the summary log file.
            # We assume the number of chains equals the number of monomers that
            # the MR program has managed to place. There should be no waters, ligands, etc.
            # in the search model.
            # This may have to be adjusted for complexes.
         #  chains_found=self.getPdbChains(model, mstat, mstat.model_list[model].mr_pdb_sum_logfile)
         #  if chains_found:
         #     print "Molecular Replacement found %d out of %d chains." % (chains_found, target_info.no_of_mols)
         #     print ""
         #  else:
         #     print "Warning: Molecular Replacement found no chains."
         #     print ""
         #lse:
         #  print "Bad error: no Pdb summary log file!"
         #  print ""

         # Set the refmac details depending on the MR program used
         if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
            refmac_logfile=mstat.model_list[model].refmac_molrep_logfile
         if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
            refmac_logfile=mstat.model_list[model].refmac_phaser_logfile

         # If the score file exists then we can assume that the refinement completed successfully.
         # Will change this to look at terminal signals later.
         if self.debug:
            print "Checking to see if Refmac produced a log file for model: " + model + "...."
            print "File name: " + refmac_logfile
            print ""

         if os.path.isfile(refmac_logfile):
            if self.debug:
               print "File exists"
               print ""
            log_file=open(refmac_logfile)

            # Set the model parameters associated with refinement
            mstat.model_list[model].setRefinement_Program('Refmac')
            score_found=self.getRefmacScores(model, mstat, mstat.jobname_dict[job].MRPROGRAM, refmac_logfile)
            #score_found=self.getRefmacScores(model, mstat, job, refmac_logfile)
           
            if score_found:
               # Set some temporary variables to hold the refmac scores
               if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
                  init_rfree  = mstat.model_list[model].refmac_molrep_initRfree
                  final_rfree = mstat.model_list[model].refmac_molrep_finlRfree
               if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
                  init_rfree  = mstat.model_list[model].refmac_phaser_initRfree
                  final_rfree = mstat.model_list[model].refmac_phaser_finlRfree
               diff        = final_rfree/init_rfree

               # If the final Rfree is less than 0.35 then we can asssume that a solution has been found.
               if final_rfree <= 0.35:
                  print "Template Model: %s has produced a solution, final Rfree = %.3f" % (model, final_rfree)
                  if init.keywords.TRYALL == False:
                     sys.stdout.write("removing all other jobs....\n")
                     for jobID in mstat.jobid_array:
                        os.system("qdel " + `jobID` + " > /dev/null") 

                  # Set the details for the solution
                  self.setSolutionDetailsParallel(mstat, model, job, "good")
        
               # If the Rfree score falls by more than 20 % and the final value is less than .5 we can 
               # assume a successful refinement  
               elif final_rfree <= 0.5 and diff <= 0.8: 
                  print "Template Model: %s has produced a solution, final Rfree = %.3f and is %.3f of initial Rfree" % (model, final_rfree, diff)
                  if init.keywords.TRYALL == False:
                     sys.stdout.write("removing all other jobs....\n")
                     for jobID in mstat.jobid_array:
                        os.system("qdel " + `jobID` + " > /dev/null") 

                  # Set the details for the solution
                  self.setSolutionDetailsParallel(mstat, model, job, "good")
        
               elif final_rfree <= 0.48:
                  # Write the details to the results HTML 
                  mstat.mr_results.write_marginal_solnParallel(init, mstat, model, job, final_rfree, diff) 
   
                  # Set the details for the solution
                  self.setSolutionDetailsParallel(mstat, model, job, "marginal")
        
                  # Output the file details to stdout
                  self.printFileDetailsParallel(init, mstat, model, job, "marginal", 1)

               elif final_rfree <= 0.55 and diff <=0.95:
                  # Write the details to the results HTML 
                  mstat.mr_results.write_marginal_solnParallel(init, mstat, model, job, final_rfree, diff) 
   
                  # Set the details for the solution
                  self.setSolutionDetailsParallel(mstat, model, job, "marginal")

                  # Output the file details to stdout
                  self.printFileDetailsParallel(init, mstat, model, job, "marginal", 2)

               else:
                  # Set the details for the solution
                  self.setSolutionDetailsParallel(mstat, model, job, "poor")

                  # Output the file details to stdout
                  self.printFileDetailsParallel(init, mstat, model, job, "poor")

               # If a solution has been found determine the Molecular Replacement details.

               # Molrep. Test to see if a PDB file was created using Molrep and set program variable.
               if mstat.model_list[model].good_solution_MOLREP or mstat.model_list[model].marginal_solution_MOLREP: 
                  if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
                     if os.path.isfile(mstat.model_list[model].molrep_PDBfile):
                        if self.debug:
                           sys.stdout.write("Molrep PDB file exists\n")
                           sys.stdout.write("PDB file name: %s\n" % mstat.model_list[model].molrep_PDBfile)
                           sys.stdout.write("\n")
                        #mstat.model_list[model].setMRPROGRAM('Molrep')
      
                        # Read and set the Molrep variables from the solution file.
                        if os.path.isfile(mstat.model_list[model].molrep_solnfile):
                           if self.debug:
                              sys.stdout.write("Molrep solution file exists\n")
                              sys.stdout.write("File name: %s\n" % mstat.model_list[model].molrep_solnfile)
                              sys.stdout.write("\n")
   
                           # Get the solution summary:
                           sum=Get_MR_sum.MR_Summary() 
                           sum.get_molrep_summary(mstat.model_list[model].molrep_solnfile, init.molrepVersion)

                           # Set the molrep smartie log 
                           mstat.model_list[model].molrep_smartie_log=sum.log

                           mstat.model_list[model].setMolrepSummary(sum.molrep_summary)               
                           print ""
                           print "######################################################################" + len(model)*"#"
                           print "#####           Summary of solutions from Molrep for " + model + ":           #####" 
                           print "######################################################################" + len(model)*"#"
                           print ""
                           print mstat.model_list[model].molrep_summary
   
                           log=open(mstat.model_list[model].molrep_solnfile)
                           line=log.readline()
   
                           while line:
                              if 'S_ Nmon RF TF   theta    phi    chi     tx     ty     tz    TFcnt   Rfac' in line:
                                 line=log.readline()
                                 mstat.model_list[model].setMolrepCorr(float(string.split(line)[-1]))
                                 mstat.model_list[model].setMolrepRfac(float(string.split(line)[-2]))
                                 break
   
                              line=log.readline()
   
                           log.close()
   
                        else:
                           if self.debug:
                              sys.stdout.write("Molrep solution file not found for: %s\n" % model)
                              sys.stdout.write("File name: %s\n" % mstat.model_list[model].molrep_solnfile)
                              sys.stdout.write("\n")

                           # Set the solution type to a Molrep failure
                           mstat.model_list[model].solution_type_MOLREP = "MOLREP_FAIL"
   
                     else:
                        if self.debug:
                           sys.stdout.write("Molrep PDB file not found for: %s\n" % model)
                           sys.stdout.write("PDB File name: %s\n" % mstat.model_list[model].molrep_PDBfile)
                           sys.stdout.write("\n")

                        # Set the solution type to a Molrep failure
                        mstat.model_list[model].solution_type_MOLREP = "MOLREP_FAIL"

                     if os.path.isfile(refmac_logfile):
                        # Output the refinement scores from the refmac log file 
   
                        # Set the title of the loggraph table to be specific to this model
                        sum.setRefmacRfacTitle("Rfactor analysis, stats vs cycle for model %s" % model)
   
                        # Grab the Rfactor table from the Refmac output
                        sum.get_refmac_summary(refmac_logfile)
   
                        # Set the refmac smartie log 
                        mstat.model_list[model].refmac_molrep_smartie_log=sum.log
                        mstat.model_list[model].setRefmacMolrepSummary(sum.refmac_summary)               
   
                        print ""
                        print "#########################################################################" + len(model)*"#"
                        print "#####              Refinement results from Refmac for " + model + ":             #####"
                        print "#########################################################################" + len(model)*"#"
                        print ""
                        print sum.refmac_summary
                        print ""
                     else:
                        if self.debug:
                           sys.stdout.write("Refmac logfile not found for: %s\n" % model)
   
                        # Set the solution type to a Refmac failure (if not already set)
                        if mstat.model_list[model].solution_type_MOLREP == "":
                           mstat.model_list[model].solution_type_MOLREP = "REFMAC_FAIL"
   
                     # If we now have a solution we can break out of the model list loop.
                     if mstat.solution_found:
                        if init.keywords.TRYALL == False:
                           mstat.mr_results.copy_solution_files(mstat, os.path.join(mstat.results_dir, 'solution'))
                           mstat.mr_results.display_results(mstat, init, target_info)
                           break
                        else:
                           mstat.mr_results.display_results(mstat, init, target_info)
   
                     if mstat.model_list[model].marginal_solution_MOLREP:
                        sys.stdout.write("Output MTZ file from Refmac for model " + model + " (marginal solution search model):\n")
                        sys.stdout.write(mstat.model_list[model].refmac_molrep_MTZOUTfile + "\n")
                        sys.stdout.write("Output PDB file from Refmac for model " + model + ":\n")
                        sys.stdout.write(mstat.model_list[model].refmac_phaser_PDBfile + "\n")
                        sys.stdout.write("\n")
   
                     if init.keywords.TRYALL:
                        sys.stdout.write("(Running in TRYALL mode) \n")
                        sys.stdout.write("\n")
   
                     sys.stdout.write("*******************************************************************************************\n")
                     sys.stdout.write("\n")
   
               # Likewise for Phaser. Phaser will superseed Molrep if it has been necessary to use it.
               if mstat.model_list[model].good_solution_PHASER or mstat.model_list[model].marginal_solution_PHASER: 
                  if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
                     if os.path.isfile(mstat.model_list[model].phaser_PDBfile):
                        if self.debug:
                           print "Phaser PDB file exists"
                           print "PDB file name: " + mstat.model_list[model].phaser_PDBfile
                           print ""
                        #mstat.model_list[model].setMRPROGRAM('Phaser')
   
                        # Read and set the Molrep variables from the solution file.
                        if os.path.isfile(mstat.model_list[model].phaser_solnfile):
                           if self.debug:
                              print "Phaser solution file exists"
                              print "File name: " + mstat.model_list[model].phaser_solnfile
                              print ""
   
                           # Check the spacegroup of the output MTZ from Phaser

                           # Get the solution summary:
                           sum=Get_MR_sum.MR_Summary() 

                           # Set the title of the loggraph table to be specific to this model
                           sum.setPhaserTransTitle("Final Translation Function Summary for model %s" % model)

                           # Grab the Translation function table from the Phaser output
                           sum.get_phaser_summary(mstat.model_list[model].phaser_logfile)
                           #sum.get_phaser_summary(mstat.model_list[model].phaser_logfile, \
                           #                       mstat.model_list[model].phaser_soln_spacegroup)

                           # Set the phaser smartie log 
                           mstat.model_list[model].phaser_smartie_log=sum.log

                           mstat.model_list[model].setPhaserSummary(sum.phaser_summary)               
      
                           sys.stdout.write("\n")
                           sys.stdout.write("#########################################################################" + len(model)*"#" + "\n")
                           sys.stdout.write("#####     Results from final translation function in Phaser for " + model + ":   #####\n")
                           sys.stdout.write("#########################################################################" + len(model)*"#" + "\n")
                           sys.stdout.write("\n")
                           print mstat.model_list[model].phaser_summary

                           log=open(mstat.model_list[model].phaser_solnfile)
                           line=log.readline()
                        
                           # Try to get the LLG score from the Phaser solution file. Tries to take the last LLG in the scores line.
                           while line:
                              if 'LLG' in line:
                                 splitline=string.split(line)
                                 for i in range(len(splitline)):
                                    val=splitline[len(splitline)-i-1]
                                    if "LLG=" in val:
                                       try:
                                          mstat.model_list[model].setPhaserLLGscore(float(val.replace("LLG=","").replace(")","")))
                                          # Put in Zscore aswell here. 
                                       except:
                                          sys.stdout.write("Warning: could not set Phaser LLG score\n")
                                          sys.stdout.write("\n")
                                       break
                              line=log.readline()
                           log.close()

                        else:
                           if self.debug:
                              sys.stdout.write("Phaser solution file not found for: %s\n" % model)
                              sys.stdout.write("File name: %s\n" % mstat.model_list[model].phaser_solnfile)
                              sys.stdout.write("\n")
   
                           # Set the solution type to a Phaser failure
                           mstat.model_list[model].solution_type_PHASER = "PHASER_FAIL"
   
                     else:
                        if self.debug:
                           sys.stdout.write("Phaser PDB file not found for: %s\n" % model)
                           sys.stdout.write("PDB File name: %s\n" % mstat.model_list[model].phaser_PDBfile)
                           sys.stdout.write("\n")

                        # Set the solution type to a Phaser failure
                        mstat.model_list[model].solution_type_PHASER = "PHASER_FAIL"
   
                     if os.path.isfile(refmac_logfile):
                        # Output the refinement scores from the refmac log file 
   
                        # Set the title of the loggraph table to be specific to this model
                        sum.setRefmacRfacTitle("Rfactor analysis, stats vs cycle for model %s" % model)
   
                        # Grab the Rfactor table from the Refmac output
                        sum.get_refmac_summary(refmac_logfile)
   
                        # Set the refmac smartie log 
                        mstat.model_list[model].refmac_phaser_smartie_log=sum.log
                        mstat.model_list[model].setRefmacPhaserSummary(sum.refmac_summary)               
   
                        print ""
                        print "#########################################################################" + len(model)*"#"
                        print "#####              Refinement results from Refmac for " + model + ":             #####"
                        print "#########################################################################" + len(model)*"#"
                        print ""
                        print sum.refmac_summary
                        print ""
                     else:
                        if self.debug:
                           sys.stdout.write("Refmac logfile not found for: %s\n" % model)
   
                        # Set the solution type to a Refmac failure (if not already set)
                        if mstat.model_list[model].solution_type_PHASER == "":
                           mstat.model_list[model].solution_type_PHASER = "REFMAC_FAIL"
   
                     # If we now have a solution we can break out of the model list loop.
                     if mstat.solution_found:
                        if init.keywords.TRYALL == False:
                           mstat.mr_results.copy_solution_files(mstat, os.path.join(mstat.results_dir, 'solution'))
                           mstat.mr_results.display_results(mstat, init, target_info)
                           break
                        else:
                           mstat.mr_results.display_results(mstat, init, target_info)
   
                     if mstat.model_list[model].marginal_solution_PHASER:
                        sys.stdout.write("Output MTZ file from Refmac for model " + model + " (marginal solution search model):\n")
                        sys.stdout.write(mstat.model_list[model].refmac_molrep_MTZOUTfile + "\n")
                        sys.stdout.write("Output PDB file from Refmac for model " + model + ":\n")
                        sys.stdout.write(mstat.model_list[model].refmac_phaser_PDBfile + "\n")
                        sys.stdout.write("\n")
   
                     if init.keywords.TRYALL:
                        sys.stdout.write("(Running in TRYALL mode) \n")
                        sys.stdout.write("\n")
   
                     sys.stdout.write("*******************************************************************************************\n")
                     sys.stdout.write("\n")
         
            else:
               if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
                  mstat.model_list[model].solution_type_MOLREP = "REFMAC_FAIL"
               if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
                  mstat.model_list[model].solution_type_PHASER = "REFMAC_FAIL"

         # If no score file exists then we can assume that Refinement/MR failed and continue to the next 
         # model.
         else:
            sys.stdout.write("Refmac log file not found for job number: %d, model ID: %s\n" \
                             % (mstat.model_list[model].MR_job_number, model))

            # Output the file details to stdout
            self.printFileDetailsParallel(init, mstat, model, job, "poor")

         # Create a solution structure for this completed job
         sm=Solution_struct.Soln_Model()
         sm.soln_model_name=model + "_" + mstat.jobname_dict[job].MRPROGRAM
         sm.model_source=model
         sm.mrprogram=mstat.jobname_dict[job].MRPROGRAM
         if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
            sm.solution_type=mstat.model_list[model].solution_type_MOLREP
         if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
            sm.solution_type=mstat.model_list[model].solution_type_PHASER

         # Add this model to the list of successfully completed jobs
         mstat.soln_list[sm.soln_model_name]=sm
      
         # If running in LITE mode clean out the MR directories
         if init.keywords.LITE:
            if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
               purge=Cleanup.Clean()
               purge.purgeDirectory(os.path.join(mstat.model_list[model].model_directory, "mr", "phaser"), Except=["sh"])
            if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
               purge=Cleanup.Clean()
               purge.purgeDirectory(os.path.join(mstat.model_list[model].model_directory, "mr", "molrep"), Except=["sh"])

         # Print out the summary of results so far
         best=MRBUMP_writebest.BestLog()
         best.write_results_log(init, mstat)
         mstat.sorted_soln_list=best.sorted_soln_list

         sys.stdout.write(best.report)


   def check_result_serial(self, mstat, init, model, target_info):
      """ A function to check the refinement results for the finished jobs in a serial run."""

      # If the refmac log file exists then we can assume that the refinement completed successfully.
      # Will change this to look at terminal signals later.
      sys.stdout.write("\n")
      sys.stdout.write("#########################################################################\n")
      sys.stdout.write("Job has completed for model '%s'\n" %  model)
      sys.stdout.write("#########################################################################\n")
      sys.stdout.write("\n")

      #if self.debug:
      #   print "Checking the PDB summary log file for model: " + model + "...."
      #   print "File name: " + mstat.model_list[model].mr_pdb_sum_logfile
      #   print ""

      #if os.path.isfile(mstat.model_list[model].mr_pdb_sum_logfile):
      #   if self.debug:
      #      print "File exists"
      #      print ""

         # Extract the number of chains from the summary log file.
         # We assume the number of chains equals the number of monomers that
         # the MR program has managed to place. There should be no waters, ligands, etc.
         # in the search model.
         # This may have to be adjusted for complexes.
      #   chains_found=self.getPdbChains(model, mstat, mstat.model_list[model].mr_pdb_sum_logfile)
      #   if chains_found:
      #      print "Molecular Replacement found %d out of %d chains." % (chains_found, target_info.no_of_mols)
      #      print ""
      #   else:
      #      print "Warning: Molecular Replacement found no chains."
      #      print ""
      #else:
      #   print "Bad error: no Pdb summary log file!"
      #   print ""

      # Set the refmac details depending on the MR program used
      if mstat.model_list[model].MRPROGRAM=="MOLREP":
         refmac_logfile=mstat.model_list[model].refmac_molrep_logfile
      if mstat.model_list[model].MRPROGRAM=="PHASER":
         refmac_logfile=mstat.model_list[model].refmac_phaser_logfile

      # Check that file is present
      if self.debug:
         print "Checking to see if Refmac produced a log file for model: " + model + "...."
         print "File name: " + refmac_logfile
         print ""
  
      if os.path.isfile(refmac_logfile):
         if self.debug:
            print "File exists"
            print ""
         log_file=open(refmac_logfile)

         # Set the model parameters associated with refinement
         mstat.model_list[model].setRefinement_Program('Refmac')
         score_found=self.getRefmacScores(model, mstat, mstat.model_list[model].MRPROGRAM, refmac_logfile)

         if score_found:
            # Set some temporary variables to hold the refmac scores
            if mstat.model_list[model].MRPROGRAM=="MOLREP":
               init_rfree  = mstat.model_list[model].refmac_molrep_initRfree
               final_rfree = mstat.model_list[model].refmac_molrep_finlRfree
            if mstat.model_list[model].MRPROGRAM=="PHASER":
               init_rfree  = mstat.model_list[model].refmac_phaser_initRfree
               final_rfree = mstat.model_list[model].refmac_phaser_finlRfree
            diff        = final_rfree/init_rfree

            # If the final Rfree is less than 0.35 then we can asssume that a solution has been found.
            if final_rfree <= 0.35:
               sys.stdout.write("Template Model: %s has produced a solution, final Rfree = %.3f\n" % (model, final_rfree))
               sys.stdout.write("\n")

               # Set the details for the solution
               self.setSolutionDetailsSerial(mstat, model, "good")

            # If the Rfree score falls by more than 20 % and the final value is less than .5 we can 
            # assume a successful refinement  
            elif final_rfree <= 0.5 and diff <= 0.8: 
               sys.stdout.write("Template Model: %s has produced a solution, final Rfree = %.3f and is %.3f of initial Rfree\n" \
                     % (model, final_rfree, diff))
               sys.stdout.write("\n")

               # Set the details for the solution
               self.setSolutionDetailsSerial(mstat, model, "good")

            elif final_rfree <= 0.48:
               # Set the details for the solution
               self.setSolutionDetailsSerial(mstat, model, "marginal")

               # Output the file details to stdout
               self.printFileDetailsSerial(init, mstat, model, "marginal", 1)

            elif final_rfree <= 0.55 and diff <=0.95:
               # Set the details for the solution
               self.setSolutionDetailsSerial(mstat, model, "marginal")

               # Output the file details to stdout
               self.printFileDetailsSerial(init, mstat, model, "marginal", 2)

            else:
               # Set the details for the solution
               self.setSolutionDetailsSerial(mstat, model, "poor")

               # Output the file details to stdout
               self.printFileDetailsSerial(init, mstat, model, "poor")

            # If a solution has been found determine the Molecular Replacement details.
            if mstat.model_list[model].good_solution_MOLREP or mstat.model_list[model].marginal_solution_MOLREP or\
               mstat.model_list[model].good_solution_PHASER or mstat.model_list[model].marginal_solution_PHASER:
                   
               # Molrep. Test to see if a PDB file was created using Molrep and set program variable.
               if mstat.model_list[model].MRPROGRAM=="MOLREP":
   
                  if os.path.isfile(mstat.model_list[model].molrep_PDBfile):
                     if self.debug:
                        sys.stdout.write("Molrep PDB file exists\n")
                        sys.stdout.write("PDB file name: %s\n" % mstat.model_list[model].molrep_PDBfile)
                        sys.stdout.write("\n")
                     #mstat.model_list[model].setMRPROGRAM('Molrep')
   
                     # Read and set the Molrep variables from the solution file.
                     if os.path.isfile(mstat.model_list[model].molrep_solnfile):
                        if self.debug:
                           sys.stdout.write("Molrep solution file exists\n")
                           sys.stdout.write("File name: %s\n" % mstat.model_list[model].molrep_solnfile)
                           sys.stdout.write("\n")
   
                        # Get the solution summary:
                        sum=Get_MR_sum.MR_Summary() 

                        sum.get_molrep_summary(mstat.model_list[model].molrep_solnfile, init.molrepVersion)

                        # Set the molrep smartie log 
                        mstat.model_list[model].molrep_smartie_log=sum.log

                        mstat.model_list[model].setMolrepSummary(sum.molrep_summary)               

                        sys.stdout.write("\n")
                        sys.stdout.write("######################################################################" + len(model)*"#" + "\n")
                        sys.stdout.write("#####           Summary of solutions from Molrep for " + model + ":           #####\n") 
                        sys.stdout.write("######################################################################" + len(model)*"#" + "\n")
                        sys.stdout.write("\n")
                        sys.stdout.write(mstat.model_list[model].molrep_summary + "\n")
   
                        # Open the log file and extract the scores (move this to a separate class at some stage)
                        log=open(mstat.model_list[model].molrep_solnfile)
                        line=log.readline()
   
                        while line:
                           if 'S_ Nmon RF TF   theta    phi    chi     tx     ty     tz    TFcnt   Rfac' in line:
                              line=log.readline()
                              mstat.model_list[model].setMolrepCorr(float(string.split(line)[-1]))
                              mstat.model_list[model].setMolrepRfac(float(string.split(line)[-2]))
                              break

                           line=log.readline()
   
                        log.close()
   
                     else:
                        if self.debug:
                           sys.stdout.write("Molrep solution file not found for: %s\n" % model)
                           sys.stdout.write("File name: %s\n" % mstat.model_list[model].molrep_solnfile)
                           sys.stdout.write("\n")
           
                           # Set the solution type to a Molrep failure
                           mstat.model_list[model].solution_type_MOLREP = "MOLREP_FAIL"
   
                  else:
                     if self.debug:
                        sys.stdout.write("Molrep PDB file not found for: %s\n" % model)
                        sys.stdout.write("PDB File name: %s\n" % mstat.model_list[model].molrep_PDBfile)
                        sys.stdout.write("\n")

                        # Set the solution type to a Molrep failure
                        mstat.model_list[model].solution_type_MOLREP = "MOLREP_FAIL"
   
               # Likewise for Phaser. Phaser will superseed Molrep if it has been necessary to use it.
               if mstat.model_list[model].MRPROGRAM=="PHASER":
   
                  if os.path.isfile(mstat.model_list[model].phaser_PDBfile):
                     if self.debug:
                        print "Phaser PDB file exists"
                        print "PDB file name: " + mstat.model_list[model].phaser_PDBfile
                        print ""
                     #mstat.model_list[model].setMRPROGRAM('Phaser')
   
                     # Read and set the Molrep variables from the solution file.
   
                     if os.path.isfile(mstat.model_list[model].phaser_solnfile):
                        if self.debug:
                           print "Phaser solution file exists"
                           print "File name: " + mstat.model_list[model].phaser_solnfile
                           print ""
   
                        # Get the solution summary:
                        sum=Get_MR_sum.MR_Summary() 
                        # Set the title of the loggraph table to be specific to this model
                        sum.setPhaserTransTitle("Final Translation Function Summary for model %s" % model)

                        # Grab the Translation function table from the Phaser output
                        sum.get_phaser_summary(mstat.model_list[model].phaser_logfile)
                        #sum.get_phaser_summary(mstat.model_list[model].phaser_logfile, \
                        #                       mstat.model_list[model].phaser_soln_spacegroup)

                        # Set the phaser smartie log 
                        mstat.model_list[model].phaser_smartie_log=sum.log

                        mstat.model_list[model].setPhaserSummary(sum.phaser_summary)               

                        print ""
                        print "#########################################################################" + len(model)*"#"
                        print "#####     Results from final translation function in Phaser for " + model + ":   #####"
                        print "#########################################################################" + len(model)*"#"
                        print ""
                        print mstat.model_list[model].phaser_summary

                        # Open the log file and extract the scores (move this to a separate class at some stage)
                        log=open(mstat.model_list[model].phaser_solnfile)
                        line=log.readline()
   
                        # Try to get the LLG score from the Phaser solution file. Tries to take the last LLG in the scores line.
                        while line:
                           if 'LLG' in line:
                              splitline=string.split(line)
                              for i in range(len(splitline)):
                                 val=splitline[len(splitline)-i-1]
                                 if "LLG=" in val:
                                    try:
                                       mstat.model_list[model].setPhaserLLGscore(float(val.replace("LLG=","").replace(")","")))
                                       # Put in Zscore aswell here. 
                                    except:
                                       sys.stdout.write("Warning: could not set Phaser LLG score\n")
                                       sys.stdout.write("\n")
                                    break
                           line=log.readline()
                        log.close()

                     else:
                        if self.debug:
                           sys.stdout.write("Phaser solution file not found for: %s\n" % model)
                           sys.stdout.write("File name: %s\n" % mstat.model_list[model].phaser_solnfile)
                           sys.stdout.write("\n")
   
                           # Set the solution type to a Phaser failure
                           mstat.model_list[model].solution_type_PHASER = "PHASER_FAIL"
   
                  else:
                     if self.debug:
                        sys.stdout.write("Phaser PDB file not found for: %s\n" % model)
                        sys.stdout.write("PDB File name: %s\n" % mstat.model_list[model].phaser_PDBfile)
                        sys.stdout.write("\n")
   
                        # Set the solution type to a Phaser failure
                        mstat.model_list[model].solution_type_PHASER = "PHASER_FAIL"
   
               # Set the refmac details depending on the MR program used
               if mstat.model_list[model].MRPROGRAM=="MOLREP":
                  refmac_logfile=mstat.model_list[model].refmac_molrep_logfile
                  refmac_MTZOUTfile=mstat.model_list[model].refmac_molrep_MTZOUTfile
                  refmac_PDBfile=mstat.model_list[model].refmac_molrep_PDBfile
               if mstat.model_list[model].MRPROGRAM=="PHASER":
                  refmac_logfile=mstat.model_list[model].refmac_phaser_logfile
                  refmac_MTZOUTfile=mstat.model_list[model].refmac_phaser_MTZOUTfile
                  refmac_PDBfile=mstat.model_list[model].refmac_phaser_PDBfile

               if os.path.isfile(refmac_logfile):
                  # Output the refinement scores from the refmac log file 

                  # Set the title of the loggraph table to be specific to this model
                  sum.setRefmacRfacTitle("Rfactor analysis, stats vs cycle for model %s" % model)

                  # Grab the Rfactor table from the Refmac output
                  sum.get_refmac_summary(refmac_logfile)

                  # Set the refmac smartie log 
                  if mstat.model_list[model].MRPROGRAM=="MOLREP":
                     mstat.model_list[model].refmac_molrep_smartie_log=sum.log
                     mstat.model_list[model].setRefmacMolrepSummary(sum.refmac_summary)               
                  elif mstat.model_list[model].MRPROGRAM=="PHASER":
                     mstat.model_list[model].refmac_phaser_smartie_log=sum.log
                     mstat.model_list[model].setRefmacPhaserSummary(sum.refmac_summary)               
                  else:
                     sys.stdout.write("Job check WARNING: Unrecognised value for mstat.model_list[model].MRPROGRAM\n")
                     sys.stdout.write("\n")

                  print ""
                  print "#########################################################################" + len(model)*"#"
                  print "#####              Refinement results from Refmac for " + model + ":             #####"
                  print "#########################################################################" + len(model)*"#"
                  print ""
                  print sum.refmac_summary
                  print ""

                  if mstat.model_list[model].MRPROGRAM.upper()=="MOLREP" and mstat.model_list[model].marginal_solution_MOLREP:
                     sys.stdout.write("Output MTZ file from Refmac for model " + model + " (marginal solution search model):\n")
                     sys.stdout.write(refmac_MTZOUTfile + "\n")
                     sys.stdout.write("Output PDB file from Refmac for model " + model + ":\n")
                     sys.stdout.write(refmac_PDBfile + "\n")
                     sys.stdout.write("\n")

                  if mstat.model_list[model].MRPROGRAM.upper()=="PHASER" and mstat.model_list[model].marginal_solution_PHASER:
                     sys.stdout.write("Output MTZ file from Refmac for model " + model + " (marginal solution search model):\n")
                     sys.stdout.write(refmac_MTZOUTfile + "\n")
                     sys.stdout.write("Output PDB file from Refmac for model " + model + ":\n")
                     sys.stdout.write(refmac_PDBfile + "\n")
                     sys.stdout.write("\n")

                  if init.keywords.TRYALL:
                     sys.stdout.write("(Running in TRYALL mode) \n")
                     sys.stdout.write("\n")

               # If no score file exists then we can assume that Refinement/MR failed and continue to the next 
               else:
                  if self.debug:
                     sys.stdout.write("Refmac logfile not found for: %s\n" % model)

                  # Set the solution type to a Refmac failure (if not already set)
                  if mstat.model_list[model].MRPROGRAM=="MOLREP":
                     if mstat.model_list[model].solution_type_MOLREP == "":
                        mstat.model_list[model].solution_type_MOLREP = "REFMAC_FAIL"
                  if mstat.model_list[model].MRPROGRAM=="PHASER":
                     if mstat.model_list[model].solution_type_PHASER == "":
                        mstat.model_list[model].solution_type_PHASER = "REFMAC_FAIL"

         else:
            if mstat.model_list[model].MRPROGRAM=="MOLREP":
               mstat.model_list[model].solution_type_MOLREP = "REFMAC_FAIL"
            if mstat.model_list[model].MRPROGRAM=="PHASER":
               mstat.model_list[model].solution_type_PHASER = "REFMAC_FAIL"

      # If no score file exists then we can assume that Refinement/MR failed and continue to the next 
      # model.
      else:
         sys.stdout.write("Refmac log file not found for: %s\n" % model)
         sys.stdout.write("\n")

         # Set the solution type to a Refmac failure (if not already set)
         if mstat.model_list[model].MRPROGRAM=="MOLREP":
            if mstat.model_list[model].solution_type_MOLREP == "":
               mstat.model_list[model].solution_type_MOLREP = "REFMAC_FAIL"
         if mstat.model_list[model].MRPROGRAM=="PHASER":
            if mstat.model_list[model].solution_type_PHASER == "":
               mstat.model_list[model].solution_type_PHASER = "REFMAC_FAIL"

         sys.stdout.write("Checking MR output...\n")

         if mstat.model_list[model].MRPROGRAM=="MOLREP":
            if os.path.isfile(mstat.model_list[model].molrep_PDBfile):
               sys.stdout.write("Molrep produced a PDB, error was in Refmac\n")
               sys.stdout.write("Check the refmac logfile:\n  %s\n" % mstat.model_list[model].refmac_molrep_logfile)
               sys.stdout.write("\n")
            else:
               sys.stdout.write("Molrep failed to produce a PDB\n")
               sys.stdout.write("Check the molrep logfile:\n  %s\n" % mstat.model_list[model].molrep_logfile)
               sys.stdout.write("\n")
               mstat.model_list[model].solution_type_MOLREP = "MOLREP_FAIL"

         if mstat.model_list[model].MRPROGRAM=="PHASER":
            if os.path.isfile(mstat.model_list[model].phaser_PDBfile):
               sys.stdout.write("Phaser produced a PDB, error was in Refmac\n")
               sys.stdout.write("Check the refmac logfile:\n  %s\n" % mstat.model_list[model].refmac_phaser_logfile)
               sys.stdout.write("\n")
            else:
               sys.stdout.write("Phaser failed to produce a PDB\n")
               sys.stdout.write("Check the phaser logfile:\n  %s\n" % mstat.model_list[model].phaser_logfile)
               sys.stdout.write("\n")
               mstat.model_list[model].solution_type_PHASER = "PHASER_FAIL"

      # Create a solution structure for this completed job
      sm=Solution_struct.Soln_Model()
      sm.soln_model_name=model + "_" + mstat.model_list[model].MRPROGRAM
      sm.model_source=model
      sm.mrprogram=mstat.model_list[model].MRPROGRAM
      if mstat.model_list[model].MRPROGRAM=="MOLREP":
         sm.solution_type=mstat.model_list[model].solution_type_MOLREP
      if mstat.model_list[model].MRPROGRAM=="PHASER":
         sm.solution_type=mstat.model_list[model].solution_type_PHASER

      # Add this model to the list of completed jobs
      mstat.soln_list[sm.soln_model_name]=sm
   
      # If running in LITE mode clean out the MR directories
      if init.keywords.LITE:
         if mstat.model_list[model].MRPROGRAM=="PHASER":
            purge=Cleanup.Clean()
            purge.purgeDirectory(os.path.join(mstat.model_list[model].model_directory, "mr", "phaser"), Except=["sh"])
         if mstat.model_list[model].MRPROGRAM=="MOLREP":
            purge=Cleanup.Clean()
            purge.purgeDirectory(os.path.join(mstat.model_list[model].model_directory, "mr", "molrep"), Except=["sh"])

   def getPdbChains(self, model, mstat, pdb_sum_logfile):
      """ Extract the number of chains listed in the log file of Pdb summary utility. """

      chains_found = 0
      log=open(pdb_sum_logfile,'r')

      # Loop over the file and extract the number of chains found
      line=log.readline()
      while line:
         if 'Number' in line and 'molecules' in line:
            chains_found = float(string.split(line)[4])
            
         line=log.readline()
      log.close()
      
      # Check that the number of chains were found
      if chains_found == 0:
         sys.stdout.write("mrbump_get_pdb_details Error: No chains listed for model: " + model + "\n") 
         sys.stdout.write("mrbump_get_pdb_details Error: Logfile: \n") 
         sys.stdout.write("                " + pdb_sum_logfile + "\n") 
         sys.stdout.write("\n") 

      return chains_found
      
   def getRefmacScores(self, model, mstat, MRPROGRAM, refmac_logfile):
      """ Extract the relevant scores from the refmac log file. """

      score_found = False
      log=open(refmac_logfile,'r')

      # Loop over the file and extract the initial and final Rfactor/Rfree values
      line=log.readline()
      while line:
         if 'Ncyc' in line and 'Rfact' in line:

            line=log.readline()
            line=log.readline()

            # Set the initial Rfactor and Rfree scores
            if MRPROGRAM=="MOLREP":
               mstat.model_list[model].refmac_molrep_initRfact=float(string.split(line)[1])
               mstat.model_list[model].refmac_molrep_initRfree=float(string.split(line)[2])
            if MRPROGRAM=="PHASER":
               mstat.model_list[model].refmac_phaser_initRfact=float(string.split(line)[1])
               mstat.model_list[model].refmac_phaser_initRfree=float(string.split(line)[2])

            while '$$' not in line:
               previous_line=line
               line=log.readline()

            # Set the final Rfactor and Rfree scores
            if MRPROGRAM=="MOLREP":
               mstat.model_list[model].refmac_molrep_finlRfact=float(string.split(previous_line)[1])
               mstat.model_list[model].refmac_molrep_finlRfree=float(string.split(previous_line)[2])
            if MRPROGRAM=="PHASER":
               mstat.model_list[model].refmac_phaser_finlRfact=float(string.split(previous_line)[1])
               mstat.model_list[model].refmac_phaser_finlRfree=float(string.split(previous_line)[2])
          
            score_found = True

         line=log.readline()
      log.close()
      
      # Check that the scores were found
      if score_found == False:
         sys.stdout.write("Refmac Scoring Error: Initial and Final Rfree values were not found for model: " + model + "\n") 
         sys.stdout.write("Refmac Scoring Error: Logfile: \n") 
         sys.stdout.write("                " + refmac_logfile + "\n") 
         sys.stdout.write("\n") 

      return score_found

   def printFileDetailsSerial(self, init, mstat, model, SOLN_TYPE, MARG_TYPE=0):
      """ Output the file details to the stdout """

      # If it is a marginal solution output the log and PDB file details
      if SOLN_TYPE == "marginal": 

         # Output according to the type of marginal solution
         if MARG_TYPE==1:
            if mstat.model_list[model].MRPROGRAM=="MOLREP":
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f\n" \
                                % (model, mstat.model_list[model].refmac_molrep_finlRfree))
            if mstat.model_list[model].MRPROGRAM=="PHASER":
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f\n" \
                                % (model, mstat.model_list[model].refmac_phaser_finlRfree))

         if MARG_TYPE==2:
            if mstat.model_list[model].MRPROGRAM=="MOLREP":
               diff = mstat.model_list[model].refmac_molrep_finlRfree/mstat.model_list[model].refmac_molrep_initRfree
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f and is %.3f of initial Rfree\n" \
                                % (model, mstat.model_list[model].refmac_molrep_finlRfree, diff))
            if mstat.model_list[model].MRPROGRAM=="PHASER":
               diff = mstat.model_list[model].refmac_phaser_finlRfree/mstat.model_list[model].refmac_phaser_initRfree
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f and is %.3f of initial Rfree\n" \
                                % (model, mstat.model_list[model].refmac_phaser_finlRfree, diff))
         sys.stdout.write("\n")

         if mstat.model_list[model].MRPROGRAM=="MOLREP":
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Molrep " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].molrep_scriptfile1)
            else:
               sys.stdout.write("Molrep log file:\n  %s\n" % mstat.model_list[model].molrep_logfile)
               sys.stdout.write("Molrep PDB file:\n  %s\n" % mstat.model_list[model].molrep_PDBfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_molrep_logfile)
            sys.stdout.write("Refmac PDB file:\n  %s\n" % mstat.model_list[model].refmac_molrep_PDBfile)
         elif mstat.model_list[model].MRPROGRAM=="PHASER":
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Phaser " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].phaser_scriptfile)
            else:
               sys.stdout.write("Phaser log file:\n  %s\n" % mstat.model_list[model].phaser_logfile)
               sys.stdout.write("Phaser PDB file:\n  %s\n" % mstat.model_list[model].phaser_PDBfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_phaser_logfile)
            sys.stdout.write("Refmac PDB file:\n  %s\n" % mstat.model_list[model].refmac_phaser_PDBfile)

      # If it's a failure then just report the log file details
      elif SOLN_TYPE == "poor": 
         if mstat.model_list[model].MRPROGRAM=="MOLREP":
            sys.stdout.write("Template Model: %s produced a poor solution (Final Rfree = %.3f)\n" \
                          % (model, mstat.model_list[model].refmac_molrep_finlRfree))
            sys.stdout.write("\n")
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Molrep " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].molrep_scriptfile1)
            else:
               sys.stdout.write("Molrep log file:\n  %s\n" % mstat.model_list[model].molrep_logfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_molrep_logfile)
         elif mstat.model_list[model].MRPROGRAM=="PHASER":
            sys.stdout.write("Template Model: %s produced a poor solution (Final Rfree = %.3f)\n" \
                          % (model, mstat.model_list[model].refmac_phaser_finlRfree))
            sys.stdout.write("\n")
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Phaser " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].phaser_scriptfile)
            else:
               sys.stdout.write("Phaser log file:\n  %s\n" % mstat.model_list[model].phaser_logfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_phaser_logfile)

      else:
         sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in printFileDetails()\n" % SOLN_TYPE)
         sys.stdout.write("\n")

      sys.stdout.write("\n")

   def printFileDetailsParallel(self, init, mstat, model, job, SOLN_TYPE, MARG_TYPE=0):
      """ Output the file details to the stdout """

      # If it is a marginal solution output the log and PDB file details
      if SOLN_TYPE == "marginal": 

         # Output according to the type of marginal solution
         if MARG_TYPE==1:
            if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f\n" \
                                % (model, mstat.model_list[model].refmac_molrep_finlRfree))
            if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f\n" \
                                % (model, mstat.model_list[model].refmac_phaser_finlRfree))

         if MARG_TYPE==2:
            if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
               diff = mstat.model_list[model].refmac_molrep_finlRfree/mstat.model_list[model].refmac_molrep_initRfree
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f and is %.3f of initial Rfree\n" \
                                % (model, mstat.model_list[model].refmac_molrep_finlRfree, diff))
            if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
               diff = mstat.model_list[model].refmac_phaser_finlRfree/mstat.model_list[model].refmac_phaser_initRfree
               sys.stdout.write("Template Model: %s has produced a marginal solution, final Rfree = %.3f and is %.3f of initial Rfree\n" \
                                % (model, mstat.model_list[model].refmac_phaser_finlRfree, diff))
         sys.stdout.write("\n")

         if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Molrep " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].molrep_scriptfile1)
            else:
               sys.stdout.write("Molrep log file:\n  %s\n" % mstat.model_list[model].molrep_logfile)
               sys.stdout.write("Molrep PDB file:\n  %s\n" % mstat.model_list[model].molrep_PDBfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_molrep_logfile)
            sys.stdout.write("Refmac PDB file:\n  %s\n" % mstat.model_list[model].refmac_molrep_PDBfile)
         elif mstat.jobname_dict[job].MRPROGRAM=="PHASER":
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Phaser " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].phaser_scriptfile)
            else:
               sys.stdout.write("Phaser log file:\n  %s\n" % mstat.model_list[model].phaser_logfile)
               sys.stdout.write("Phaser PDB file:\n  %s\n" % mstat.model_list[model].phaser_PDBfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_phaser_logfile)
            sys.stdout.write("Refmac PDB file:\n  %s\n" % mstat.model_list[model].refmac_phaser_PDBfile)

      # If it's a failure then just report the log file details
      elif SOLN_TYPE == "poor": 
         if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
            sys.stdout.write("Template Model: %s produced a poor solution (Final Rfree = %.3f)\n" \
                          % (model, mstat.model_list[model].refmac_molrep_finlRfree))
            sys.stdout.write("\n")
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Molrep " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].molrep_scriptfile1)
            else:
               sys.stdout.write("Molrep log file:\n  %s\n" % mstat.model_list[model].molrep_logfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_molrep_logfile)
         elif mstat.jobname_dict[job].MRPROGRAM=="PHASER":
            sys.stdout.write("Template Model: %s produced a poor solution (Final Rfree = %.3f)\n" \
                          % (model, mstat.model_list[model].refmac_phaser_finlRfree))
            sys.stdout.write("\n")
            if init.keywords.LITE:
               sys.stdout.write("Running in 'LITE' mode. Output files from Phaser " + \
                                "have been removed but can be re-generated by running:\n  %s\n" % mstat.model_list[model].phaser_scriptfile)
            else:
               sys.stdout.write("Phaser log file:\n  %s\n" % mstat.model_list[model].phaser_logfile)
            sys.stdout.write("Refmac log file:\n  %s\n" % mstat.model_list[model].refmac_phaser_logfile)

      else:
         sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in printFileDetails()\n" % SOLN_TYPE)
         sys.stdout.write("\n")

      sys.stdout.write("\n")

   def setSolutionDetailsParallel(self, mstat, model, job, SOLN_TYPE):
      """ Set the solution details """

      if mstat.jobname_dict[job].MRPROGRAM.upper() == "MOLREP":
         if SOLN_TYPE=="good":
            # Set the general solution found flag
            mstat.setSolutionFound(True)
   
            # Set the solution model to the current one
            mstat.setSolutionModel(model)
        
            # Set the MR program that was used to give the solution
            mstat.setSolutionMRProgram(mstat.jobname_dict[job].MRPROGRAM)
   
            # Set this model to be a good solution
            mstat.model_list[model].good_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "GOOD"
   
         elif SOLN_TYPE=="marginal":
            # Set the marginal solution flag to true
            mstat.model_list[model].marginal_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "MARGINAL"
   
         elif SOLN_TYPE=="poor":
            # Set the marginal solution flag to true
            mstat.model_list[model].poor_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "POOR"
   
         else:
            sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in setSolutionDetailsParallel()\n" % SOLN_TYPE)
            sys.stdout.write("\n")

      if mstat.jobname_dict[job].MRPROGRAM.upper() == "PHASER":
         if SOLN_TYPE=="good":
            # Set the general solution found flag
            mstat.setSolutionFound(True)
   
            # Set the solution model to the current one
            mstat.setSolutionModel(model)
        
            # Set the MR program that was used to give the solution
            mstat.setSolutionMRProgram(mstat.jobname_dict[job].MRPROGRAM.upper())
   
            # Set this model to be a good solution
            mstat.model_list[model].good_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "GOOD"
   
         elif SOLN_TYPE=="marginal":
            # Set the marginal solution flag to true
            mstat.model_list[model].marginal_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "MARGINAL"
   
         elif SOLN_TYPE=="poor":
            # Set the marginal solution flag to true
            mstat.model_list[model].poor_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "POOR"
   
         else:
            sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in setSolutionDetailsParallel()\n" % SOLN_TYPE)
            sys.stdout.write("\n")

   def setSolutionDetailsSerial(self, mstat, model, SOLN_TYPE):
      """ Set the solution details """

      if mstat.MRPROGRAM.upper() == "MOLREP":
         if SOLN_TYPE=="good":
            # Set the general solution found flag
            mstat.setSolutionFound(True)
   
            # Set the solution model to the current one
            mstat.setSolutionModel(model)
        
            # Set the MR program that was used to give the solution
            mstat.setSolutionMRProgram(mstat.MRPROGRAM.upper())
   
            # Set this model to be a good solution
            mstat.model_list[model].good_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "GOOD"
   
         elif SOLN_TYPE=="marginal":
            # Set the marginal solution flag to true
            mstat.model_list[model].marginal_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "MARGINAL"
   
         elif SOLN_TYPE=="poor":
            # Set the marginal solution flag to true
            mstat.model_list[model].poor_solution_MOLREP = True
            mstat.model_list[model].solution_type_MOLREP = "POOR"
   
         else:
            sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in setSolutionDetailsSerial()\n" % SOLN_TYPE)
            sys.stdout.write("\n")

      if mstat.MRPROGRAM.upper() == "PHASER":
         if SOLN_TYPE=="good":
            # Set the general solution found flag
            mstat.setSolutionFound(True)
   
            # Set the solution model to the current one
            mstat.setSolutionModel(model)
        
            # Set the MR program that was used to give the solution
            mstat.setSolutionMRProgram(mstat.MRPROGRAM.upper())
   
            # Set this model to be a good solution
            mstat.model_list[model].good_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "GOOD"
   
         elif SOLN_TYPE=="marginal":
            # Set the marginal solution flag to true
            mstat.model_list[model].marginal_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "MARGINAL"
   
         elif SOLN_TYPE=="poor":
            # Set the marginal solution flag to true
            mstat.model_list[model].poor_solution_PHASER = True
            mstat.model_list[model].solution_type_PHASER = "POOR"
   
         else:
            sys.stdout.write("Job checking error: unrecognised value for SOLN_TYPE '%s' in setSolutionDetailsSerial()\n" % SOLN_TYPE)
            sys.stdout.write("\n")

