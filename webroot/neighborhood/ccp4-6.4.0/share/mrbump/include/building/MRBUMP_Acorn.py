#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for running Acorn jobs
# Ronan Keegan - 29/10/06
#

import os, sys, string
import CCP4_Submit

class Acorn:
   """ A class to submit Eclac jobs to the local machine or a batch system on a cluster. """

   def __init__(self):
      self.logfile=""
      self.acorn_logfile=""
      self.jobname=""

      self.hklin=""
      self.hklout=""
      self.xyzin=""

      self.cc_value=0.0
      self.no_cycles=0

      if os.name=="nt":
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn.exe")  
      else:
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn")  

      self.CLUSTER = False
      self.QTYPE   = "SGE"

      self.jobid_array = []
      self.jobid_dict = dict([])

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLogfile(self, filename):
      self.logfile=filename

   def setHKLIN(self, filename):
      self.hklin=filename

   def setHKLOUT(self, filename):
      self.hklout=filename

   def setXYZIN(self, filename):
      self.xyzin=filename

   def setAcornLogfile(self, filename):
      self.acorn_logfile=filename

   def submit_job_standalone(self, F_flag, SIGF_flag, E_flag, hklin, hklout, xyzin, dir=os.getcwd()):
      """ Function to launch an acorn job for a given model as a standalone job. """

      # Create a job and first set up the Acorn details

      # Make the model build folder
      if os.path.isdir(os.path.join(dir, "building")) == False: 
         os.mkdir(os.path.join(dir, "building"))

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.setLogfile(os.path.join(dir, "building", "acorn_job.log"))

      # Set the input and output MTZ file names
      self.setHKLIN(hklin)
      self.setXYZIN(xyzin)
      self.setHKLOUT(os.path.join(dir, "building", hklout))
      self.setAcornLogfile(self.logfile)

      # Setup the job
      MR_job=CCP4_Submit.CCP4_sub()
      MR_job.setProgram(self.acornEXE)
      MR_job.setProgramLogfile(self.logfile)
      MR_job.setCommandLine("HKLIN %s HKLOUT %s XYZIN %s" % (self.hklin, self.hklout, self.xyzin))

      # Setup the keywords for the job
      MR_job.setKEYWORD("LABIn FP=" + F_flag + " SIGFP=" + SIGF_flag + " E=" + E_flag)
      MR_job.setKEYWORD("POSI 1")

      # Fire off the job
      
      # Run the job locally
      MR_job.submit_job(self.jobname,\
                        self.logfile,\
                        os.path.join(dir, "building"),
                        queue_type="LOCAL")


   def submit_job(self, init, mstat, model, target_info):
      """ Function to launch an acorn job for a given model. """

      # Create a job and first set up the Acorn details

      # Create the build directory if it does not already exist
      build_DIR = os.path.join(model.model_directory, "building")

      if os.path.isdir(build_DIR) == False:
         os.mkdir(build_DIR) 

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=os.path.join(build_DIR, "acorn_job.log") 

      # Set the various Acorn parameters and filenames
      model.setAcornLogfile(os.path.join(build_DIR, "acorn_" + model.name + ".log"))
      model.setAcornMTZOUTfile(os.path.join(build_DIR, "acorn_" + model.name +".mtz"))
      model.setAcornJobname(os.path.join(build_DIR, "acorn_" + model.name))

      # Set up local links to the input/output files
      self.setHKLIN(model.ecalc_MTZOUTfile)
      self.setHKLOUT(model.acorn_MTZOUTfile)
      self.setXYZIN(model.refmac_PDBfile)
      self.setAcornLogfile(model.acorn_logfile)

      # Setup the job
      MR_job=CCP4_Submit.CCP4_sub()
      MR_job.setProgram(self.acornEXE)
      MR_job.setProgramLogfile(model.acorn_logfile)
      MR_job.setCommandLine("HKLIN %s HKLOUT %s XYZIN %s" \
                         % (model.ecalc_MTZOUTfile, model.acorn_MTZOUTfile, model.refmac_PDBfile))

      # Setup the keywords for the job
      MR_job.setKEYWORD("LABIn FP=" + target_info.mtz_coldata['F'] \
                        + " SIGFP=" + target_info.mtz_coldata['SIGF'] \
                        + " E=" + target_info.mtz_coldata['E'])
      MR_job.setKEYWORD("POSI 1")
        
      # Fire off the job

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         new_job=mstat.conn.AddSubJob( \
            init.ProjectName,init.JobId,
            "Acorn",model.acorn_jobname)
         if new_job[0] == "OK":
            job_ID=new_job[1]
   
            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Acorn")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", model.acorn_jobname)
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, job_ID, model.ecalc_MTZOUTfile)
            mstat.conn.AddInputFile(init.ProjectName, job_ID, model.refmac_PDBfile)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.acorn_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, model.acorn_logfile)
         else:
            print "DB job setup failed: job ID: %d" % model.name
   
      if init.keywords.CLUSTER:
         # Submit the job to a batch queue
         MR_job.submit_job(model.acorn_jobname,\
                           self.logfile,\
                           build_DIR,\
                           queue_type=init.keywords.QTYPE,
                           qsub_command=init.keywords.QSUBCOM)
         # Note the job number and the job name
         model.setMR_JobID(MR_job.job_number)
         mstat.jobid_array.add(model.MR_jobID)
         mstat.jobid_dict[model.MR_jobID]=model.acorn_jobname
         mstat.jobname_dict[model.acorn_jobname]=model.name
      else:
         # Run the job locally
         MR_job.submit_job(model.acorn_jobname,\
                           self.logfile,\
                           build_DIR,
                           queue_type="LOCAL")

         # Set the status to be finished in the DB
         if init.keywords.DBOUT:
            if new_job[0] == "OK":
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")

   def read_logfile(self, logfile):
      """ Read any relavent details from the Acorn log file. """

      # Setup a variable to hold the data
      cc_data=""

      # Open the logfile for reading
      f=open(logfile, "r")
      
      line=f.readline()
      while line:
         if "$TABLE:Correlation Coefficient vs number of cycles" in line:
            cc_data = cc_data + line
            cc_line=f.readline()
            while cc_line:
               cc_data = cc_data + cc_line
               cc_line=f.readline()
               if "************************" in cc_line:
                  self.cc_value=float(string.split(cc_data)[-2])
                  self.no_cycles=int(string.split(cc_data)[-4])
                  break 

         line=f.readline()
    
      f.close()

      # Output the results
      sys.stdout.write("################################################################\n")
      sys.stdout.write("#######        Correlation Coefficient from Acorn        #######\n")
      sys.stdout.write("################################################################\n")
      sys.stdout.write("\n")
      sys.stdout.write(string.strip(cc_data) + "\n")
      sys.stdout.write("\n")
      sys.stdout.write("Final CC value after %i cycles: %.5f\n" % (self.no_cycles, self.cc_value))
      sys.stdout.write("\n")
      sys.stdout.write("Acorn Logfile:\n")
      sys.stdout.write("   %s\n" % self.acorn_logfile)
      sys.stdout.write("\n")
      sys.stdout.write("Output MTZ file from Acorn: \n")
      sys.stdout.write("   %s\n" % self.hklout)
      sys.stdout.write("\n")
      sys.stdout.write("################################################################\n")
      sys.stdout.write("\n")

if __name__ == "__main__":

   # An example for running the job as a standalone function

   # Check and read the command line
   if len(sys.argv) != 7:
      print "Usage: python MRBUMP_Acorn.py <hklin> <hklout> <xyzin> <F label> <SIGF label> <E label>"
      sys.exit() 
   
   hklin=sys.argv[1]
   hklout=sys.argv[2]
   xyzin=sys.argv[3]
   F=sys.argv[4]
   SIGF=sys.argv[5]
   E=sys.argv[6]

   # Call the job
   a=Acorn()
   a.submit_job_standalone(F, SIGF, E, hklin, hklout, xyzin)
   a.read_logfile(a.logfile)
