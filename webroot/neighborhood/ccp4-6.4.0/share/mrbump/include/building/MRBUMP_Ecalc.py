#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for running Ecalc jobs
# Ronan Keegan - 29/10/06
#

import os, sys, string
import CCP4_Submit

class Ecalc:
   """ A class to submit Eclac jobs to the local machine or a batch system on a cluster. """

   def __init__(self):
      self.logfile=""
      self.jobname=""

      self.hklin=""
      self.hklout=""

      if os.name=="nt":
         self.ecalcEXE = os.path.join(os.environ["CCP4_BIN"], "ecalc.exe")  
      else:
         self.ecalcEXE = os.path.join(os.environ["CCP4_BIN"], "ecalc")  

      self.CLUSTER = False
      self.QTYPE   = "SGE"

      self.jobid_array = []
      self.jobid_dict = dict([])

   def setLogfile(self, filename):
      self.logfile=filename

   def setHKLIN(self, filename):
      self.hklin=filename

   def setHKLOUT(self, filename):
      self.hklout=filename

   def submit_job_standalone(self, F_flag, SIGF_flag, hklin, hklout, spacegroup, dir=os.getcwd()):
      """ Function to launch an ecalc job for a given model as a standalone job. """

      # Create a job and first set up the Ecalc details

      # Make the model build folder
      if os.path.isdir(os.path.join(dir, "building")) == False: 
         os.mkdir(os.path.join(dir, "building"))

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.setLogfile(os.path.join(dir, "building", "ecalc_job.log"))

      # Set the input and output MTZ file names
      self.setHKLIN(hklin)
      self.setHKLOUT(os.path.join(dir, "building", hklout))

      # Setup the job
      MR_job=CCP4_Submit.CCP4_sub()
      MR_job.setProgram(self.ecalcEXE)
      MR_job.setProgramLogfile(self.logfile)
      MR_job.setCommandLine("HKLIN %s HKLOUT %s" % (self.hklin, self.hklout))

      # Setup the keywords for the job
      MR_job.setKEYWORD("TITLE Run ecalc to generate normalised structure factor amplitudes")
      MR_job.setKEYWORD("LABIn FP=" + F_flag + " SIGFP=" + SIGF_flag)
      MR_job.setKEYWORD("LABOut E=E SIGE=SIGE")
      MR_job.setKEYWORD("SPACEGROUP " + spacegroup )

      # Fire off the job
      
      # Run the job locally
      MR_job.submit_job(self.jobname,\
                        self.logfile,\
                        os.path.join(dir, "building"),
                        queue_type="LOCAL")


   def submit_job(self, init, mstat, model, target_info):
      """ Function to launch an ecalc job for a given model. """

      # Create a job and first set up the Ecalc details

      # Create the build directory if it does not already exist
      build_DIR = os.path.join(model.model_directory, "building")

      if os.path.isdir(build_DIR) == False:
         os.mkdir(build_DIR) 

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=os.path.join(build_DIR, "ecalc_job.log") 

      # Set the various Ecalc parameters and filenames
      model.setEcalcLogfile(os.path.join(build_DIR, "ecalc_" + model.name + ".log"))
      model.setEcalcMTZOUTfile(os.path.join(build_DIR, "ecalc_" + model.name +".mtz"))
      model.setEcalcJobname(os.path.join(build_DIR, "ecalc_" + model.name))

      # Setup the job
      MR_job=CCP4_Submit.CCP4_sub()
      MR_job.setProgram(self.ecalcEXE)
      MR_job.setProgramLogfile(model.ecalc_logfile)
      MR_job.setCommandLine("HKLIN %s HKLOUT %s" % (model.refmac_MTZOUTfile, model.ecalc_MTZOUTfile))

      # Setup the keywords for the job
      MR_job.setKEYWORD("TITLE Run ecalc to generate normalised structure factor amplitudes")
      MR_job.setKEYWORD("LABIn FP=" + target_info.mtz_coldata['F'] + " SIGFP=" + target_info.mtz_coldata['SIGF'])
      MR_job.setKEYWORD("LABOut E=E SIGE=SIGE")

      # Update the target details object with the new column labels
      target_info.mtz_coldata["E"] = "E"
      target_info.mtz_coldata["SIGE"] = "SIGE"
        
      # Fire off the job

      if init.keywords.CLUSTER:
         # Submit the job to a batch queue
         MR_job.submit_job(model.ecalc_jobname,\
                           self.logfile,\
                           build_DIR,\
                           queue_type=init.keywords.QTYPE,
                           qsub_command=init.keywords.QSUBCOM)
         # Note the job number and the job name
         model.setMR_JobID(MR_job.job_number)
         mstat.jobid_array.add(model.MR_jobID)
         mstat.jobid_dict[model.MR_jobID]=model.ecalc_jobname
         mstat.jobname_dict[model.ecalc_jobname]=model.name
      else:
         # Run the job locally
         MR_job.submit_job(model.ecalc_jobname,\
                           self.logfile,\
                           build_DIR,
                           queue_type="LOCAL")

if __name__ == "__main__":

   # An example for running the job as a standalone function

   # Check and read the command line
   if len(sys.argv) != 5:
      print "Usage: MRBUMP_Ecalc.py <hklin> <hklou> <F label> <SIGF label> <spacegroup>"
      sys.exit() 
   
   hklin=sys.argv[1]
   hklout=sys.argv[2]
   F=sys.argv[3]
   SIGF=sys.argv[4]
   spacegroup=sys.argv[5]

   # Call the job
   a=Ecalc()
   a.submit_job_standalone(F, SIGF, hklin, hklout, spacegroup)
