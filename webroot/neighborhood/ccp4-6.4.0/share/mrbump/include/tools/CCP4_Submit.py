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
# Generic CCP4 cluster job submitter. So far it supports local machine and SGE
# Ronan Keegan 10/2/06

import os
import string
import sys

class CCP4_sub:
   """ A class to submit CCP4 jobs to a cluster queue. """

   def __init__(self):
       self.qsub_COMMAND=""
       self.q_type="" 
       self.job_name=""
       self.job_number=0
       self.job_directory=""
       self.submission_file=""
       self.log_file=""
 
       self.program_no=0
       self.program=[]
       self.program_logfile=[]
       self.command_line=[]
       self.keywords=""
       self.keyword_array=[]

       try:
          self.debug=eval(os.environ['MRBUMP_DEBUG'])
       except:
          self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   # Job specific commands   
   def setJobNumber(self, number):
       self.job_number = number

   # CCP4 program commands
   def setProgram(self, program_name):
       self.program.append(program_name)

   def setProgramLogfile(self, filename):
       self.program_logfile.append(filename)

   def addProgram(self, program_name):
       self.program.append(program_name)
       self.keyword_array.append(self.keywords)
       self.keywords = ""
       self.program_no = self.program_no + 1

   def setCommandLine(self, command_line):
       self.command_line.append(command_line)
    
   def setKEYWORD(self, keyword):
      self.keywords = self.keywords + keyword +  "\n"


   def submit_job(self, job_name, log_file, job_directory, queue_type="LOCAL", qsub_command="qsub"):
      """ Submit any CCP4 job to the queue. 
          Input: A job name,
                 The name of the log file for the stdout,
                 The directory from where the job will run,
                 The type of batch queue to use (optional - default= local machine)."""
   
      # Set the logfile name
      self.log_file=log_file
   
      # CCP4 doesn't like jobs starting with digits
      if job_name[0].isdigit():
         job_name = "_" + job_name
   
      # Set the job name
      self.job_name=job_name
   
      # Set the job directory
      self.job_directory=job_directory
   
      # Set the queue type for the job
      self.q_type = queue_type

      # Add the final set of keywords to the keyword array
      self.keyword_array.append(self.keywords)

      # Run locally if a queue type is not specified
      if self.q_type == "LOCAL":
         if os.name != "nt":
            self.setup_LOCAL_job()

            # Run the job locally 
            o=os.popen(self.submission_file, "r")
         
            log=open(self.log_file, "w")
            line=o.readline()
            while line:
               log.write(line)
               line=o.readline()
            o.close()
            log.close()

         else:
            # Get the current working directory
            current_dir=os.getcwd()
 
            # Set the program, command line and the keywords
            for i in range(self.program_no + 1): 
   
               # Change to the working directory of this model
               os.chdir(self.job_directory)

               # Write the data input file for this job
               if os.name != "nt":
                  key_file=self.job_directory + "/" + string.split(self.program[i],"/")[-1] + "_input_" + `i` + ".dat"
               else:
                  key_file=self.job_directory + "\\" + string.split(self.program[i],"\\")[-1] + "_input_" + `i` + ".dat"
               kf=open(key_file, "w")
               for key in self.keyword_array[i]:
                  kf.write(key)
               kf.close()
   
               std_out=os.popen(self.program[i] + " " +  self.command_line[i] + " < " + key_file, "r") 
               #os.system(self.program[i] + " " +  self.command_line[i] + " < " + key_file) 

               log=open(self.program_logfile[i], "w")
               line=std_out.readline()
               while line:
                  log.write(line)
                  line=std_out.readline()
               std_out.close()
               log.close()

            # Revert to the current directory
            os.chdir(current_dir)

      elif self.q_type == "SGE":

         self.setup_SGE_job(qsub_command)

         # Submit the job to the batch queue
         o=os.popen(self.qsub_COMMAND + " " + self.submission_file, "r")
   
         # Read the output and record the job number identifier
         line=o.readline()
         while line:
             if self.debug:
                print line
             if "submitted" in line:
                self.setJobNumber(int(string.split(line)[2]))
             line=o.readline()
         o.close()

      #   self.setJobNumber(job_count)
     
      elif self.q_type == "PBS":
         self.setup_PBS_job(qsub_command)

         # Submit the job to the batch queue
         o=os.popen(self.qsub_COMMAND + " " + self.submission_file, "r")
   
         # Read the output and record the job number identifier
         line=o.readline()
         while line:
             if line[0].isdigit():
                self.setJobNumber(int(string.split(line,".")[0]))
             line=o.readline()
         o.close()

      #   self.setJobNumber(job_count)
     
   def setup_LOCAL_job(self):
      """ A function to create a script to run the job locally. """

      # Create the submission script for a local job - first set the template
      line  = "#! /bin/sh\n"
      line += "\n"
      line += "# cd to the directory where the jobs are to be run\n"
      line += "\n"
      line += "cd " + self.job_directory + "\n"
      line += "\n"
      line += "# Below are the programs to be run in this script:\n"
      line += "\n"

      # Set the program, command line and the keywords
      for i in range(self.program_no + 1): 
         line += self.program[i] + " " +  self.command_line[i] + " << eof > " + self.program_logfile[i] + "\n"
         line += self.keyword_array[i]
         line += "eof\n"
         line += "\n"

      # Set the name of the submission script and write the script contents to the file
      self.submission_file = os.path.join(self.job_directory, self.job_name + ".sub")

      sf=open(self.submission_file, "w")
      sf.write(line)
      sf.close()

      if self.debug:
         sys.stdout.write("Submit job file: \n")
         sys.stdout.write(line + "\n")
        
      # Change the permissions on the file so that the user can execute the script
      os.chmod(self.submission_file, 0744)
 
   def setup_SGE_job(self, qsub_command):
      """ A function to create a submission script for an SGE job. """

      # Set the submission command
      self.qsub_COMMAND=qsub_command

      # Create the submission script for an SGE job - first set the template
      line  = "#!/bin/sh\n"
      line += "#$ -j y\n"
      line += "#$ -w e\n"
      line += "#$ -V\n"
      line += "#$ -o " + self.log_file + "\n"
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

      # Set the program, command line and the keywords
      for i in range(self.program_no + 1): 
         line += self.program[i] + " " +  self.command_line[i] + " << eof > " + self.program_logfile[i] + "\n" 
         line += self.keyword_array[i]
         line += "eof\n"
         line += "\n"
         
      # Set the name of the submission script and write the script contents to the file
      self.submission_file = self.job_directory + "/" + self.job_name + ".sub"

      sf=open(self.submission_file, "w")
      sf.write(line)
      sf.close()
 
   def setup_PBS_job(self, qsub_command):
      """ A function to create a submission script for an PBS job. """

      # Set the submission command
      self.qsub_COMMAND=qsub_command

      # Create the submission script for an PBS job - first set the template
      line  = "#!/bin/sh\n"
      line += "#PBS -j oe\n"
      line += "#PBS -V\n"
      line += "#PBS -o " + self.log_file + "\n"
      line += "#PBS -N " + self.job_name + "\n"
      line += "\n"
      line += "# cd to the directory where the jobs are to be run\n"
      line += "\n"
      line += "cd " + self.job_directory + "\n"
      line += "\n"
      line += "# Below are the programs to be run in this script:\n"
      line += "\n"

      # Set the program, command line and the keywords
      for i in range(self.program_no + 1): 
         line += self.program[i] + " " +  self.command_line[i] + " << eof > " + self.program_logfile[i] + "\n" 
         line += self.keyword_array[i]
         line += "eof\n"
         line += "\n"
         
      # Set the name of the submission script and write the script contents to the file
      self.submission_file = self.job_directory + "/" + self.job_name + ".sub"

      sf=open(self.submission_file, "w")
      sf.write(line)
      sf.close()


if __name__=="__main__":
   """ An example job using Phaser, Refmac and mtzdump. """
   
   # Create and instance of the job and set the program name and command line arguments
   job=CCP4_sub()
   job.setProgram("phaser")
   job.setCommandLine("")

   # Setup the keywords for the job
   job.setKEYWORD("MODE MR_AUTO")
   job.setKEYWORD("HKLIn /users/rmk65/projects/jsub/input/eg1.mtz")
   job.setKEYWORD("LABIn F=FP SIGF=SIGFP")
   job.setKEYWORD("COMPosition PROTein MW 6005.52 NUM 1")
   job.setKEYWORD("ENSEmble autoMR PDBFile /users/rmk65/projects/jsub/input/chainsaw_1smw_A.pdb IDENtity 1.000")
   job.setKEYWORD("SEARCH ENSEmble autoMR NUM 1")
   job.setKEYWORD("XYZOUT ON")
   job.setKEYWORD("PACK 3")
   job.setKEYWORD("ROOT /users/rmk65/projects/jsub/output/my_job1_")
   job.setKEYWORD("END")

   # Add another job e.g. Refmac
   job.addProgram("refmac")
   job.setCommandLine("HKLIN temp.mtz XYZIN temp.pdb HKLOUT out.mtz XYZOUT out.pdb")
 
   job.setKEYWORD("MODE MR_AUTO")
   job.setKEYWORD("HKLIn /users/rmk65/projects/jsub/input/eg1.mtz")
   job.setKEYWORD("LABIn F=FP SIGF=SIGFP")
   job.setKEYWORD("END")

   # Add another job e.g. Refmac
   job.addProgram("mtzdump")
   job.setCommandLine("HKLIN temp.mtz")
 
   job.setKEYWORD("END")

   # Run the job locally
   #job.submit_job("my_job1", "my_job1.log", "./")

   # Submit the job to an SGE queue
   job.submit_job("my_job1", "my_job1.log", "./", queue_type="SGE", qsub_command="qsub")

