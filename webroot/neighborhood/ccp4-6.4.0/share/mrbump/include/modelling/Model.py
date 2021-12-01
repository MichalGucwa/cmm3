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
# Script to do all of the modelling steps in MRBUMP. Calls chainsaw and molrep.
# Ronan Keegan 114/10/04

import os, string, sys
import shutil
import CCP4_Submit
import time
import molrep
import chainsaw
import phaser_sculptor

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 must be defined'
#if not os.environ.has_key('MODINSTALL6v2'):
#    raise RuntimeError, 'MODINSTALL6v2 must be defined'


class Modelling:

   def __init__(self):
      if os.name == "nt":
         self.MolrepEXE=os.path.join(os.environ["CBIN"], "molrep.exe")
         self.PdbsetEXE=os.path.join(os.environ["CBIN"], "pdbset.exe")
         self.ChainsawEXE=os.path.join(os.environ["CBIN"], "chainsaw.exe")
      else:
         self.MolrepEXE=os.path.join(os.environ["CBIN"], "molrep")
         self.PdbsetEXE=os.path.join(os.environ["CBIN"], "pdbset")
         self.ChainsawEXE=os.path.join(os.environ["CBIN"], "chainsaw")

      self.chainsaw_target_seq=""
      self.chainsaw_template_seq=""

      self.job_logfile=""
      self.DB_fail=False
   
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag

   def setJobLogfile(self, filename):
      self.job_logfile=filename

   def convert_to_pir(self, mstat, target_info):
      """ Function to write convert alignment files into PIR format for Chainsaw. """
      
      # Temporary flag to mark whether or not to use the origional alignment
      # or the stripped one where only the target lenght is considered.
      MODIFIED = False

      print "\n---------------------------------------------------------------"
      print "Models Construct log message: Creating PIR alignment files"
      print "----------------------------------------------------------------\n"
      
      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:

         # Set the pir file variable
         mstat.chain_list[chain].setMAPIRFile(mstat.chain_list[chain].working_DIR + \
          '/alignments/ma_' + mstat.chain_list[chain].chainName + '.pir')

         if MODIFIED == True:
            # Assign output files
            outfile=open(mstat.chain_list[chain].ma_pir_file,'w')

            outfile.write('>P1;' + target_info.chainID + '\n')
            outfile.write('\n')
            outfile.write(mstat.chain_list[chain].alignment.align_tar_seq + '\n')
            outfile.write('*\n')
            outfile.write('>P1;' + mstat.chain_list[chain].chainName + '\n')
            outfile.write('\n')
            outfile.write(mstat.chain_list[chain].alignment.align_seq + '\n')
            outfile.write('*\n')
 
            outfile.close()
         else:
            # Change the unmodified alignment file to PIR format  
            algn_tmp_file = mstat.chain_list[chain].working_DIR + '/alignments/' + chain + '_temp_aln.fasta'
 
            infile=open(algn_tmp_file, 'r')
            outfile=open(mstat.chain_list[chain].ma_pir_file,'w')
         
            line=infile.readline()
            # Write the target header
            outfile.write(line.replace('>','>P1;'))
            outfile.write('\n')

            # Get the target sequence and write it to the outfile
            line=infile.readline()
            while line:
               if '>' not in line:
                  outfile.write(line)
               else:
                  break
               line=infile.readline()
            outfile.write('*\n')

            # Write the template header
            outfile.write(line.replace('>','>P1;'))
            outfile.write('\n')

            # Get the template sequence and write it to the outfile
            line=infile.readline()
            while line:
               outfile.write(line)
               line=infile.readline()
            outfile.write('*\n')

            # Close both files
            infile.close()
            outfile.close()

   def unmodModel(self, target_info, init, mstat):
      """ Add an unmodified version of the pdb to the list of models. """

      sys.stdout.write("\n")
      sys.stdout.write("-------------------------------------------------------------\n")
      sys.stdout.write("Models Construct log message: Adding unmodified models\n")
      sys.stdout.write("-------------------------------------------------------------\n")
      sys.stdout.write("\n")

      for chain in mstat.sorted_MR_list:

         unmodModelDir=os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'unmod')

         os.mkdir(unmodModelDir)
         os.mkdir(os.path.join(unmodModelDir, 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(unmodModelDir, 'mr', 'molrep'))
            os.mkdir(os.path.join(unmodModelDir, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(unmodModelDir, 'mr', 'phaser'))
            os.mkdir(os.path.join(unmodModelDir, 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setUnmodModelPDB(os.path.join(mstat.chain_list[chain].working_DIR, 'unmod', \
            'MODEL_UNMOD_' + mstat.chain_list[chain].chainName + '.pdb'))
   
         if self.debug:
            sys.stdout.write("Unmodified prep log: Creating unmodified template " + chain + "\n")
            sys.stdout.write("Unmodified prep log: Output PDB file:\n  " + mstat.chain_list[chain].unmod_modelPDB + "\n") 

         shutil.copyfile(mstat.chain_list[chain].original_PDBFile, mstat.chain_list[chain].unmod_modelPDB) 

         mstat.model_counter=mstat.model_counter+1


   def polyala(self, target_info, init, mstat):
      """ Generate models that are polyalanine. """
 
      print "\n-------------------------------------------------------------"
      print "Models Construct log message: Preparing Polyalanine models."
      print "-------------------------------------------------------------\n"

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
 
         os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala'))
         os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala', 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala', 'mr', 'molrep'))
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala', 'mr', 'molrep', 'refine',))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala', 'mr', 'phaser'))
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala', 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setPlyalaModelPDB(os.path.join(mstat.chain_list[chain].working_DIR, 'plyala', 'MODEL_PLYALA_' \
            + mstat.chain_list[chain].chainName + '.pdb'))

         # Set the job logfile
         self.setJobLogfile(os.path.join(mstat.chain_list[chain].working_DIR, 'plyala', 'job.log'))

         # Set the Polyala log file
         mstat.chain_list[chain].setPlyalaLogFile(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, \
            'plyala', 'MODEL_PLYALA_' + mstat.chain_list[chain].chainName + '.log'))

	 # Set the job name for the Batch queue
         mstat.chain_list[chain].setPlyalaJobName("ply_" + mstat.chain_list[chain].chainName)
    
         if self.debug == True:
            print "Polyala prep log: Modifying template " + chain 
            print "Polyala prep log: Output PDB file:\n  " + mstat.chain_list[chain].plyala_modelPDB 
            print "Polyala prep log: Log file:\n  " + mstat.chain_list[chain].plyala_logfile + "\n" 

         # Setup the job
         plyala_job=CCP4_Submit.CCP4_sub()
         plyala_job.setProgram(self.PdbsetEXE)
         plyala_job.setProgramLogfile(mstat.chain_list[chain].plyala_logfile)
         plyala_job.setCommandLine("XYZIN " + mstat.chain_list[chain].PDBFile + " XYZOUT " + mstat.chain_list[chain].plyala_modelPDB)

         # Setup the keywords for the job
         plyala_job.setKEYWORD("EXCLUDE SIDE")
         plyala_job.setKEYWORD("END")

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try: 
               job_ID=mstat.conn.AddSubJob( \
                   init.ProjectName,init.JobId,
                   "Model_%s" % mstat.chain_list[chain].plyala_jobname,
                   "Template from '%s' Chain '%s' - Polyalanine Model"
                   % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
   
               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Model_%s" \
               #     % mstat.chain_list[chain].plyala_jobname)
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", "Template from '%s' Chain '%s' - Polyalanine Model" \
               #     % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, mstat.chain_list[chain].PDBFile)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, mstat.chain_list[chain].plyala_modelPDB)
               mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.chain_list[chain].plyala_logfile)
               time.sleep(2)
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Polyalanine preparation job\n")
               sys.stdout.write("\n")
   
#         if init.keywords.CLUSTER:
#            # Submit the job to a batch queue 
#            plyala_job.submit_job(mstat.chain_list[chain].plyala_jobname,\
#                                  self.job_logfile, \
#                                  mstat.chain_list[chain].working_DIR + "/plyala",\
#                                  queue_type=init.keywords.QTYPE, 
#                                  qsub_command=init.keywords.QSUBCOM)
#            # Not the job number and the jobname
#            mstat.chain_list[chain].setPlyala_jobid(plyala_job.job_number)
#            mstat.jobid_array.add(mstat.chain_list[chain].plyala_jobid)
#            mstat.jobid_dict[mstat.chain_list[chain].plyala_jobid]=mstat.chain_list[chain].plyala_jobname
#         else:
         # Run the job locally
         plyala_job.submit_job(mstat.chain_list[chain].plyala_jobname,\
                               self.job_logfile, \
                               mstat.chain_list[chain].working_DIR + "/plyala",
                               queue_type="LOCAL") 

         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

         mstat.model_counter=mstat.model_counter+1
                   
   def molrepModel(self, target_info, init, mstat):
      """ A wrapper for calling molrep to MODEL the pdb files. """

      sys.stdout.write("\n")
      sys.stdout.write("-------------------------------------------------------------\n")
      sys.stdout.write("Models Construct log message: Manipulating models with Molrep\n")
      sys.stdout.write("-------------------------------------------------------------\n")
      sys.stdout.write("\n")

      for chain in mstat.sorted_MR_list:

         molrepModelDir=os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep')

         os.mkdir(molrepModelDir)
         os.mkdir(os.path.join(molrepModelDir, 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(molrepModelDir, 'mr', 'molrep'))
            os.mkdir(os.path.join(molrepModelDir, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(molrepModelDir, 'mr', 'phaser'))
            os.mkdir(os.path.join(molrepModelDir, 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setMolrepModelPDB(os.path.join(mstat.chain_list[chain].working_DIR, 'molrep', \
            'MODEL_MOLREP_' + mstat.chain_list[chain].chainName + '.pdb'))
   
         # Set the Molrep log file
         mstat.chain_list[chain].setMolrepLogFile(os.path.join(molrepModelDir, 'MODEL_MOLREP_' + mstat.chain_list[chain].chainName + '.log'))
 
         # Set the Molrep error file
         mstat.chain_list[chain].setMolrepErrFile(os.path.join(molrepModelDir, 'MODEL_MOLREP_' + mstat.chain_list[chain].chainName + '.err'))

         if self.debug:
            sys.stdout.write("Molrep prep log: Modifying template " + chain + "\n")
            sys.stdout.write("Molrep prep log: Output PDB file:\n  " + mstat.chain_list[chain].molrep_modelPDB + "\n") 
            sys.stdout.write("Molrep prep log: Log file:\n  " + mstat.chain_list[chain].molrep_logfile + "\n") 
            sys.stdout.write("Molrep prep log: Error file:\n  " + mstat.chain_list[chain].molrep_errfile + "\n\n") 
  
         key ="DOC Y\n"
         key+="FILE_S " + target_info.seqfile + "\n"
         key+="SURF Y\n"
         key+="END\n"

         currDir=os.getcwd()
         os.chdir(molrepModelDir)

         molrepDispatch=molrep.Dispatcher()
         molrepDispatch.set_cmd_args("MODEL " + mstat.chain_list[chain].PDBFile)
         molrepDispatch.set_keywords(key)
         molrepDispatch.call()

         if os.path.isfile("align.pdb"):
            os.rename("align.pdb", mstat.chain_list[chain].molrep_modelPDB) 
         else:
            sys.stdout.write("Warning: Could not create Molrep model using input: %s\n" % chain)
            sys.stdout.write("\n")

         os.chdir(currDir)

         # Write out the stdout to the log file
         log=open(mstat.chain_list[chain].molrep_logfile, "w")
         for line in molrepDispatch.stdout_data:
            log.write(line + "\n")
         log.close()
 
         # Write out the stderr to the error file
         err=open(mstat.chain_list[chain].molrep_errfile, "w")
         for line in molrepDispatch.stderr_data:
            err.write(line + "\n")
         err.close()

         mstat.model_counter=mstat.model_counter+1


   def molrep(self, target_info, init, mstat):
      """ A wrapper for calling molrep to MODEL the pdb files. """
 
      print "\n-------------------------------------------------------------"
      print "Models Construct log message: Manipulating models with Molrep"
      print "-------------------------------------------------------------\n"

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
       
         os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep'))
         os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep', 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep', 'mr', 'molrep'))
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep', 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep', 'mr', 'phaser'))
            os.mkdir(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep', 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setMolrepModelPDB(mstat.chain_list[chain].working_DIR + '/molrep/MODEL_MOLREP_' \
            + mstat.chain_list[chain].chainName + '.pdb')
   
         # Set the job logfile
         self.setJobLogfile(os.path.join(mstat.chain_list[chain].working_DIR, 'molrep', 'job.log'))

         # Set the Molrep log file
         mstat.chain_list[chain].setMolrepLogFile(init.search_dir + '/data/' + mstat.chain_list[chain].chainName \
            + '/molrep/MODEL_MOLREP_' + mstat.chain_list[chain].chainName + '.log')

	 # Set the job name for the Batch queue
         mstat.chain_list[chain].setMolrepJobName("MOLREP_" + mstat.chain_list[chain].chainName)

         if self.debug == True:
            print "Molrep prep log: Modifying template " + chain 
            print "Molrep prep log: Output PDB file:\n  " + mstat.chain_list[chain].molrep_modelPDB 
            print "Molrep prep log: Log file:\n  " + mstat.chain_list[chain].molrep_logfile + "\n" 

         # Setup the job
         molrep_job=CCP4_Submit.CCP4_sub()
         molrep_job.setProgram(self.MolrepEXE)
         molrep_job.setProgramLogfile(mstat.chain_list[chain].molrep_logfile)
         molrep_job.setCommandLine("MODEL " + mstat.chain_list[chain].PDBFile)

         # Setup the keywords for the job
         molrep_job.setKEYWORD("DOC Y")
         molrep_job.setKEYWORD("FILE_S " +  target_info.seqfile)
         molrep_job.setKEYWORD("SURF Y")
         molrep_job.setKEYWORD("END")

         # Add a job command to move the align.pdb file to a job related name
         if os.name == "nt":
            molrep_job.addProgram("move")
         else:
            molrep_job.addProgram("mv")
            molrep_job.setProgramLogfile("mv.log")
            molrep_job.setCommandLine("align.pdb " + mstat.chain_list[chain].molrep_modelPDB) 

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try: 
               job_ID=mstat.conn.AddSubJob( \
                   init.ProjectName,init.JobId,
                   "Model_%s" % mstat.chain_list[chain].molrep_jobname,
                   "Template from '%s' Chain '%s' - model prepared using Molrep"
                   % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
   
               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Model_%s" \
               #     % mstat.chain_list[chain].molrep_jobname)
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", "Template from '%s' Chain '%s' - model prepared using Molrep" \
               #     % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, mstat.chain_list[chain].PDBFile)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, mstat.chain_list[chain].molrep_modelPDB)
               mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.chain_list[chain].molrep_logfile)
               time.sleep(2)
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Molrep preparation job\n")
               sys.stdout.write("\n")
   
#         if init.keywords.CLUSTER:
            # Submit the job to a batch queue 
#            molrep_job.submit_job(mstat.chain_list[chain].molrep_jobname,\
#                                  self.job_logfile,\
#                                  mstat.chain_list[chain].working_DIR + "/molrep",\
#                                  queue_type=init.keywords.QTYPE,
#                                  qsub_command=init.keywords.QSUBCOM)
            # Not the job number and the jobname
#            mstat.chain_list[chain].setMolrep_jobid(molrep_job.job_number)
#            mstat.jobid_array.add(mstat.chain_list[chain].molrep_jobid)
#            mstat.jobid_dict[mstat.chain_list[chain].molrep_jobid]=mstat.chain_list[chain].molrep_jobname
#         else:
         # Run the job locally
         molrep_job.submit_job(mstat.chain_list[chain].molrep_jobname,\
                               self.job_logfile,\
                               mstat.chain_list[chain].working_DIR + "/molrep",
                               queue_type="LOCAL")

         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail=False

         mstat.model_counter=mstat.model_counter+1

   def chainsawModel(self, target_info, init, mstat):
      """ A wrapper for calling chainsaw to prepare the pdb files. """

      sys.stdout.write("\n")
      sys.stdout.write("---------------------------------------------------------------\n")
      sys.stdout.write("Models Construct log message: Manipulating models with Chainsaw\n")
      sys.stdout.write("---------------------------------------------------------------\n")
      sys.stdout.write("\n")

      for chain in mstat.sorted_MR_list:
       
         chainsawModelDir=os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'chainsaw')

         os.mkdir(chainsawModelDir)
         os.mkdir(os.path.join(chainsawModelDir, 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(chainsawModelDir, 'mr', 'molrep'))
            os.mkdir(os.path.join(chainsawModelDir, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(chainsawModelDir, 'mr', 'phaser'))
            os.mkdir(os.path.join(chainsawModelDir, 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setChainsawModelPDB(os.path.join(chainsawModelDir, \
            "CHAINSAW_" + mstat.chain_list[chain].chainName + '.pdb'))

         # Set the Chainsaw log file
         mstat.chain_list[chain].setChainsawLogFile(os.path.join(chainsawModelDir, 'CHAINSAW_' + mstat.chain_list[chain].chainName + '.log'))

         # Set the Chainsaw error file
         mstat.chain_list[chain].setChainsawErrFile(os.path.join(chainsawModelDir, 'CHAINSAW' + mstat.chain_list[chain].chainName + '.err'))

         # Write out the correct input alignment file for chainsaw. This is with "-" doubles removed.
         mstat.chain_list[chain].chainsaw_ALIGNIN=os.path.join(chainsawModelDir,  "chainsaw_alignment_file_" + mstat.chain_list[chain].chainName + ".pir")

         file=open(mstat.chain_list[chain].chainsaw_ALIGNIN, "w") 
         file.write(">P1;Target\n")
         file.write("\n")
         if mstat.chain_list[chain].HHmatch and init.keywords.HHSCORE:
            file.write(mstat.chain_list[chain].HHtargetSequence + "\n")
         else:
            file.write(mstat.chain_list[chain].alignment.chainsaw_target_seq + "\n")
         file.write("*\n")
         file.write(">P1;" + mstat.chain_list[chain].chainName + "\n")
         file.write("\n")
         if mstat.chain_list[chain].HHmatch and init.keywords.HHSCORE:
            file.write(mstat.chain_list[chain].HHalignment + "\n")
         else:
            file.write(mstat.chain_list[chain].alignment.chainsaw_template_seq + "\n")
         file.write("*\n")
         file.close()
  
         if self.debug:
            sys.stdout.write("Chainsaw prep log: Modifying template " + chain + "\n")
            sys.stdout.write("Chainsaw prep log: Input alignment file:\n " + mstat.chain_list[chain].chainsaw_ALIGNIN + "\n")
            sys.stdout.write("Chainsaw prep log: Input PDB file:\n  " + mstat.chain_list[chain].PDBFile + "\n")
            sys.stdout.write("Chainsaw prep log: Output PDB file:\n  " + mstat.chain_list[chain].chainsaw_modelPDB + "\n")
            sys.stdout.write("Chainsaw prep log: Log file:\n  " + mstat.chain_list[chain].chainsaw_logfile + "\n") 
            sys.stdout.write("Chainsaw prep log: Error file:\n  " + mstat.chain_list[chain].chainsaw_logfile + "\n\n") 

         key ="END\n"

         currDir=os.getcwd()
         os.chdir(chainsawModelDir)

         chainsawDispatch=chainsaw.Dispatcher()
         chainsawDispatch.set_cmd_args("xyzin " + mstat.chain_list[chain].PDBFile + " ALIGNIN " + \
               mstat.chain_list[chain].chainsaw_ALIGNIN + " xyzout "  + mstat.chain_list[chain].chainsaw_modelPDB)
         chainsawDispatch.set_keywords(key)
         chainsawDispatch.call()
 
         os.chdir(currDir)

         # Write out the stdout to the log file
         log=open(mstat.chain_list[chain].chainsaw_logfile, "w")
         for line in chainsawDispatch.stdout_data:
            log.write(line + "\n")
         log.close()
 
         # Write out the stderr to the error file
         err=open(mstat.chain_list[chain].chainsaw_errfile, "w")
         for line in chainsawDispatch.stderr_data:
            err.write(line + "\n")
         err.close()

         mstat.model_counter=mstat.model_counter+1

   def sculptorModel(self, target_info, init, mstat):
      """ A wrapper for calling phaser.sculptor to prepare the pdb files. """

      sys.stdout.write("\n")
      sys.stdout.write("---------------------------------------------------------------\n")
      sys.stdout.write("Models Construct log message: Manipulating models with Sculptor\n")
      sys.stdout.write("---------------------------------------------------------------\n")
      sys.stdout.write("\n")

      for chain in mstat.sorted_MR_list:
       
         sculptorModelDir=os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'sculptor')

         os.mkdir(sculptorModelDir)
         os.mkdir(os.path.join(sculptorModelDir, 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(sculptorModelDir, 'mr', 'molrep'))
            os.mkdir(os.path.join(sculptorModelDir, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(sculptorModelDir, 'mr', 'phaser'))
            os.mkdir(os.path.join(sculptorModelDir, 'mr', 'phaser', 'refine'))

         # Set the output PDB model
         mstat.chain_list[chain].setSculptorModelPDB(os.path.join(sculptorModelDir, \
            "sculpt_" + mstat.chain_list[chain].chainName + '.pdb'))

         # Set the Sculptor log file
         mstat.chain_list[chain].setSculptorLogFile(os.path.join(sculptorModelDir, 'SCULPTOR_' + mstat.chain_list[chain].chainName + '.log'))

         # Set the Sculptor error file
         mstat.chain_list[chain].setSculptorErrFile(os.path.join(sculptorModelDir, 'SCULPTOR_' + mstat.chain_list[chain].chainName + '.err'))

         # Write out the correct input alignment file for sculptor. This is with "-" doubles removed.
         mstat.chain_list[chain].sculptor_ALIGNIN=os.path.join(sculptorModelDir,  "sculptor_alignment_file_" + mstat.chain_list[chain].chainName + ".pir")

         file=open(mstat.chain_list[chain].sculptor_ALIGNIN, "w") 
         file.write(">P1;Target\n")
         file.write("\n")
         if mstat.chain_list[chain].HHmatch and init.keywords.HHSCORE:
            file.write(mstat.chain_list[chain].HHtargetSequence + "\n")
         else:
            file.write(mstat.chain_list[chain].alignment.chainsaw_target_seq + "\n")
         file.write("*\n")
         file.write(">P1;" + mstat.chain_list[chain].chainName + "\n")
         file.write("\n")
         if mstat.chain_list[chain].HHmatch and init.keywords.HHSCORE:
            file.write(mstat.chain_list[chain].HHalignment + "\n")
         else:
            file.write(mstat.chain_list[chain].alignment.chainsaw_template_seq + "\n")
         file.write("*\n")
         file.close()
  
         if self.debug:
            sys.stdout.write("Sculptor prep log: Modifying template " + chain + "\n")
            sys.stdout.write("Sculptor prep log: Input alignment file:\n " + mstat.chain_list[chain].sculptor_ALIGNIN + "\n")
            sys.stdout.write("Sculptor prep log: Input PDB file:\n  " + mstat.chain_list[chain].PDBFile + "\n")
            sys.stdout.write("Sculptor prep log: Output PDB file:\n  " + mstat.chain_list[chain].sculptor_modelPDB + "\n")
            sys.stdout.write("Sculptor prep log: Log file:\n  " + mstat.chain_list[chain].sculptor_logfile + "\n") 
            sys.stdout.write("Sculptor prep log: Error file:\n  " + mstat.chain_list[chain].sculptor_errfile + "\n\n") 

         currDir=os.getcwd()
         os.chdir(sculptorModelDir)

         sculptorDispatch=phaser_sculptor.Dispatcher()
         sculptorDispatch.set_cmd_args(mstat.chain_list[chain].PDBFile + " " + mstat.chain_list[chain].sculptor_ALIGNIN)
         sculptorDispatch.call()
 
         os.chdir(currDir)

         # Write out the stdout to the log file
         log=open(mstat.chain_list[chain].sculptor_logfile, "w")
         for line in sculptorDispatch.stdout_data:
            log.write(line + "\n")
         log.close()

         # Write out the stderr to the error file
         err=open(mstat.chain_list[chain].sculptor_errfile, "w")
         for line in sculptorDispatch.stderr_data:
            err.write(line + "\n")
         err.close()

         mstat.model_counter=mstat.model_counter+1


   def chainsaw(self, target_info, init, mstat):
      """ A wrapper for calling CHAINSAW to manipulate the pdb files. """ 
 
      print "\n--------------------------------------------------------------------"
      print "Models Construct log message: Manipulating templates with Chainsaw"
      print "--------------------------------------------------------------------\n"

      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:

         # Set various parameters for the job including the job name for the SGE queue
         chainsaw_DIR=mstat.chain_list[chain].working_DIR + '/chainsaw'

         # Set the job logfile
         self.setJobLogfile(chainsaw_DIR + '/job.log')

         # Set the output chainsaw Model name
         mstat.chain_list[chain].setChainsawModelPDB(chainsaw_DIR + '/chainsaw_' \
            + mstat.chain_list[chain].chainName + '.pdb')

         # Set the Chainsaw job name
         mstat.chain_list[chain].setChainsawJobName("CHNSAW" + mstat.chain_list[chain].chainName)
                   
         #Set the Chainsaw job logfile
         mstat.chain_list[chain].setChainsawLogFile(chainsaw_DIR + "/CHAINSAW_" + mstat.chain_list[chain].chainName + ".log")
        
         # Make the necessary directories
         os.mkdir(chainsaw_DIR)
         os.mkdir(os.path.join(chainsaw_DIR, 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(chainsaw_DIR, 'mr', 'molrep'))
            os.mkdir(os.path.join(chainsaw_DIR, 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(chainsaw_DIR, 'mr', 'phaser'))
            os.mkdir(os.path.join(chainsaw_DIR, 'mr', 'phaser', 'refine'))

         # Write out the correct input alignment file for chainsaw. This is with "-" doubles removed.
         mstat.chain_list[chain].chainsaw_ALIGNIN=chainsaw_DIR + "/chainsaw_alignment_file_" + mstat.chain_list[chain].chainName + ".pir"
         csaw_aln_file=open(mstat.chain_list[chain].chainsaw_ALIGNIN, "w") 
         csaw_aln_file.write(">P1;Target\n")
         csaw_aln_file.write("\n")
         csaw_aln_file.write(mstat.chain_list[chain].alignment.chainsaw_target_seq + "\n")
         csaw_aln_file.write("*\n")
         csaw_aln_file.write(">P1;" + mstat.chain_list[chain].chainName + "\n")
         csaw_aln_file.write("\n")
         csaw_aln_file.write(mstat.chain_list[chain].alignment.chainsaw_template_seq + "\n")
         csaw_aln_file.write("*\n")
         csaw_aln_file.close()
  
         if self.debug == True:
            print "Chainsaw (multiple) prep log: Modifying template " + chain 
            print "Chainsaw (multiple) prep log: Input alignment file:\n " + mstat.chain_list[chain].chainsaw_ALIGNIN 
            print "Chainsaw (multiple) prep log: Input PDB file:\n " + mstat.chain_list[chain].PDBFile 
            print "Chainsaw (multiple) prep log: Output PDB file:\n  " + mstat.chain_list[chain].chainsaw_modelPDB 
            print "Chainsaw (multiple) prep log: Log file:\n  " + mstat.chain_list[chain].chainsaw_logfile + "\n" 

         # Setup the Chainsaw job
         chainsaw_job=CCP4_Submit.CCP4_sub()
         chainsaw_job.setProgram(self.ChainsawEXE)
         chainsaw_job.setProgramLogfile(mstat.chain_list[chain].chainsaw_logfile)
         chainsaw_job.setCommandLine("xyzin " + mstat.chain_list[chain].PDBFile + " ALIGNIN " \
            + mstat.chain_list[chain].chainsaw_ALIGNIN + " xyzout "  + mstat.chain_list[chain].chainsaw_modelPDB)

         chainsaw_job.setKEYWORD("END")

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try:
               job_ID=mstat.conn.AddSubJob( \
                   init.ProjectName,init.JobId,
                   "Model_%s" % mstat.chain_list[chain].chainsaw_jobname,
                   "Template from '%s' Chain '%s' - model prepared using Chainsaw"
                   % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
   
               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Model_%s" \
               #     % mstat.chain_list[chain].chainsaw_jobname)
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE",   "Template from '%s' Chain '%s' - model prepared using Chainsaw" \
               #     % (mstat.chain_list[chain].PDBName, mstat.chain_list[chain].chainID))
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, mstat.chain_list[chain].PDBFile)
               mstat.conn.AddInputFile(init.ProjectName, job_ID, mstat.chain_list[chain].chainsaw_ALIGNIN)
               mstat.conn.AddOutputFile(init.ProjectName, job_ID, mstat.chain_list[chain].chainsaw_modelPDB)
               mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.chain_list[chain].chainsaw_logfile)
               time.sleep(2)
            except:
               self.DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Chainsaw job\n")
               sys.stdout.write("\n")
   
#         if init.keywords.CLUSTER:
            # Submit the job to a batch queue 
#            chainsaw_job.submit_job(mstat.chain_list[chain].chainsaw_jobname,\
#                                  self.job_logfile,\
#                                  mstat.chain_list[chain].working_DIR + "/chainsaw",\
#                                  queue_type=init.keywords.QTYPE,
#                                  qsub_command=init.keywords.QSUBCOM)
            # Note the job number and the jobname
#            mstat.chain_list[chain].setChainsaw_jobid(chainsaw_job.job_number)
#            mstat.jobid_array.add(mstat.chain_list[chain].chainsaw_jobid)
#            mstat.jobid_dict[mstat.chain_list[chain].chainsaw_jobid]=mstat.chain_list[chain].chainsaw_jobname
#         else:
         # Run the job locally
         chainsaw_job.submit_job(mstat.chain_list[chain].chainsaw_jobname,\
                                 self.job_logfile,\
                                 mstat.chain_list[chain].working_DIR + "/chainsaw",
                                 queue_type="LOCAL")

         # Set the status to be finished in the DB
         if init.keywords.DBOUT and self.DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif self.DB_fail:
            self.DB_fail = False

         mstat.model_counter=mstat.model_counter+1
         
