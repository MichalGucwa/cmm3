#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Mrbump script for submitting MR/refinement robs to cluster queue systems
# Ronan Keegan - 2/02/07
#

import os, sys, string


class Cluster_submit:
   """ A class to submit a job to a cluster batch queue. """

   def __init__(self):
    
      self.q_type=""
      self.qsub_command=""
      self.command_line=""
  
      self.job_script=""
      self.job_name=""
      self.job_directory=""
      self.job_number=0
      self.logfile=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def setCommandLine(self, line):
      self.command_line=line

   def setJobDirectory(self, directory):
      self.job_directory=directory

   def submit(self, qtype, job_name, job_script_name, logfile_name, qsub_command=""): 
      """ General submission setup. """

      # A few sanity checks
      if self.job_directory == "":
         sys.stdout.write("Cluster sub log: Setup error - job directory not set\n")
         return 

      if os.path.isdir(self.job_directory) == False:
         sys.stdout.write("Cluster sub log: Setup error - job directory does not exist\n")
         return 

      if self.command_line == "":
         sys.stdout.write("Cluster sub log: Setup error - command line not set\n")
         return 

      # Set the job script name
      self.job_script = os.path.join(self.job_directory, job_script_name)

      # Set the job name
      self.job_name = job_name

      # Set the job name
      self.logfile = os.path.join(self.job_directory, logfile_name)

      # Are we using an SGE queue
      if qtype == "SGE":
         # Set the queue type to be SGE
         self.q_type="SGE"
         if qsub_command=="":
            self.qsub_command="qsub"
         else:
            self.qsub_command=qsub_command
 
         # Submit to a Sun Grid Engine queue
         self.submit_SGE()

      # Or are we using a PBS queue?
      elif qtype == "PBS":
         # Set the queue type to PBS
         self.q_type="PBS"
         if qsub_command=="":
            self.qsub_command="qsub"
         else:
            self.qsub_command=qsub_command

         # Submit to PBS
         self.submit_PBS()

   def submit_PBS(self): 
      """ Submit a job to a PBS batch queue. """

      # Create the submission script for a PBD job
      line  = "#!/bin/sh\n"
      line += "#PBS -j oe\n"
      line += "#PBS -V\n"
      line += "#PBS -o " + self.logfile + "\n"
      line += "#PBS -N " + self.job_name + "\n"
      line += "\n"
      line += "# cd to the directory where the jobs are to be run\n"
      line += "\n"
      line += "cd " + self.job_directory + "\n"
      line += "\n"
      line += "# Below are the programs to be run in this script:\n"
      line += "\n"
      line += self.command_line + "\n"

      # Write the submission script
      script=open(self.job_script, "w")
      script.write(line)
      script.close()

      # Submit the job to the PBS queue
      o=os.popen(self.qsub_command + " " + self.job_script)
       
      line=o.readline()

      while line:
         if self.debug:
            sys.stdout.write(line + "\n")
         if line[0].isdigit():
            self.job_number=int(string.split(line,".")[0])
         line=o.readline()

      status=o.close()

      if status == None:
         sys.stdout.write("MR log: Job %s submitted to the PBS batch queue successfully\n" % self.job_name) 
         sys.stdout.write("\n")
      else:
         sys.stdout.write("MR log: WARNING - There was a problem submitting job %s to the PBS batch queue\n" % self.job_name) 
         sys.stdout.write("\n")
         

   def submit_SGE(self): 
      """ Submit a job to an SGE batch queue. """

      # Create the submission script for an SGE job - first set the template
      line  = "#!/bin/sh\n"
      line += "#$ -j y\n"
      line += "#$ -w e\n"
      line += "#$ -V\n"
      line += "#$ -o " + self.logfile + "\n"
      line += "#$ -N " + self.job_name + "\n"
      line += "\n"
      line += "#Re-set CCP4_SCR to the SGE TMPDIR\n"
      line += "setenv CCP4_SCR $TMPDIR\n"
      line += "\n"
      line += "# cd to the directory where the jobs are to be run\n"
      line += "\n"
      line += "cd " + self.job_directory + "\n"
      line += "\n"
      line += "# Below are the programs to be run in this script:\n"
      line += "\n"
      line += self.command_line + "\n"

      # Write the submission script
      script=open(self.job_script, "w")
      script.write(line)
      script.close()

      # Submit the job to the SGE queue
      o=os.popen(self.qsub_command + " " + self.job_script)
       
      line=o.readline()

      while line:
         if self.debug:
            print line
         if "submitted" in line:
            self.job_number=int(string.split(line)[2])
         line=o.readline()

      status=o.close()

      if status == None:
         sys.stdout.write("MR log: Job %s submitted to the SGE batch queue successfully\n" % self.job_name) 
         sys.stdout.write("\n")
      else:
         sys.stdout.write("MR log: WARNING - There was a problem submitting job %s to the SGE batch queue\n" % self.job_name) 
         sys.stdout.write("\n")

         
