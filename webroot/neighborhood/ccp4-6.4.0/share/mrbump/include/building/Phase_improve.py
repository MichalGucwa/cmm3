#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper preparing data for and calling Acorn to improve phases 
# Ronan Keegan - 15/2/07
#

import os
import string
import sys

import MRBUMP_acorn
import MRBUMP_ecalc
import MRBUMP_unique
import MRBUMP_cad
import phaserEXE

class Target_info:
   """ A mock class of the mrbump Target_info class for testing purposes. """

   def __init__(self):
       self.hklin=""
       self.mtz_coldata=dict([])
       self.cell_dimensions=dict([])

       self.unique_MTZOUTfile=""
       self.unique_logfile=""

       self.cad_MTZOUTfile=""
       self.cad_logfile=""

       self.aniso_MTZOUTFILE=""
       self.aniso_logfile=""

       self.ecalc_MTZOUTfile=""
       self.ecalc_logfile=""


class Model:
   """ A mock class of the mrbump Model structure class for testing purposes. """

   def __init__(self):
       self.name=""
       self.model_directory=""

       self.acorn_MTZOUTfile=""
       self.acorn_logfile=""

       self.acorn_XYZINfile=""


class PhaseImprove:
   """ A class to call Acorn if to improve the phases of a model. """

   def __init__(self):
      self.hklout=""
      self.xyzin=""
      self.xyzout=""
      self.resolution_limit=1.0

      self.cc_value=0.0
      self.no_cycles=0

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.ecalc_MTZOUTfile=""
      self.local_debug=False
      self.DB_fail=False

   def setEcalcMTZOUTfile(self, filename):
      self.ecalc_MTZOUTfile=filename

   def set_resolution_limit(self, value):
      self.resolution_limit=value

   def prepare(self, MTZINfile, space_group, init, mstat, target_info):
      """ A function to call unique and cad to extend the 
          resolution of the input data to 1.0 Angstroms. """

      # Setup a unique job
      unique=MRBUMP_unique.Unique()
 
      # Set the keywords
      unique.add_keyword("LABOUT F=%s SIGF=%s" % (unique.F, unique.SIGF))
      unique.add_keyword("SYMMETRY %s" % space_group)
      unique.add_keyword("CELL %.3f %.3f %.3f %.3f %.3f %.3f" % \
                         (target_info.cell_dimensions['a'], target_info.cell_dimensions['b'], target_info.cell_dimensions['c'], \
                          target_info.cell_dimensions['alpha'], target_info.cell_dimensions['beta'], target_info.cell_dimensions['gamma']))
      unique.add_keyword("RESO %.3f" % self.resolution_limit)
      unique.add_keyword("END")

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            job_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Unique",
               init.ProjectName + "_Unique")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Unique")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", init.ProjectName + "_Unique")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, target_info.unique_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, target_info.unique_logfile)
         except:
            self.DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Unique job\n")
            sys.stdout.write("\n")
   
      # Run Unique
      unique.run(target_info.unique_MTZOUTfile, target_info.unique_logfile)

      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail = False

      # Setup a Cad job
      # Instantiate the class
      cad=MRBUMP_cad.Cad()

      # Set the keywords
      cad.add_keyword("LABIN FILE 1 ALL")
      cad.add_keyword("LABIN FILE 2 ALL")
      cad.add_keyword("END")

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            job_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Cad",
               init.ProjectName + "_Cad")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Cad")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", init.ProjectName + "_Cad")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, job_ID, MTZINfile)
            mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.unique_MTZOUTfile)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, target_info.cad_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, target_info.cad_logfile)
         except:
            self.DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Cad job\n")
            sys.stdout.write("\n")
   
      # Cad the MTZ file
      cad.run(MTZINfile, target_info.unique_MTZOUTfile, target_info.cad_MTZOUTfile, target_info.cad_logfile)
 
      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail = False

      # Remove the Unique MTZ file
      if self.debug == False:
         try:
            os.remove(target_info.unique_MTZOUTfile)
         except:
            sys.stdout.write("Warning: Unique MTZ output file not found in Acorn function\n")
            sys.stdout.write("\n")

      # Anisotropic correction
      phaser=phaserEXE.PhaserEXE()

      # Setup the Phaser root section
      root_path=os.path.split(target_info.aniso_MTZOUTfile)[0]
      root_file_name=os.path.splitext(os.path.split(target_info.aniso_MTZOUTfile)[-1])[0]
 
      phaser.add_keyword("MODE ANO")
      phaser.add_keyword("HKLIN %s" % target_info.cad_MTZOUTfile)
      phaser.add_keyword("LABIn F=%s SIGF=%s" % (target_info.mtz_coldata["F"], target_info.mtz_coldata["SIGF"]))
      #phaser.add_keyword("ROOT %s" % os.path.join(root_path, root_file_name))
      phaser.add_keyword("ROOT %s" % root_file_name)

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            job_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Phaser_aniso",
               init.ProjectName + "_Phaser")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Phaser_aniso")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", init.ProjectName + "_Phaser")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.cad_MTZOUTfile)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, target_info.aniso_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, target_info.aniso_logfile)
         except:
            self.DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Phaser job (aniso correction)\n")
            sys.stdout.write("\n")
   
      phaser.run(root_path, target_info.aniso_MTZOUTfile, "null.pdb", target_info.aniso_logfile)

      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, job_ID, "STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail = False

      # Remove the cad MTZ file
      if self.debug == False:
         try:
            os.remove(target_info.cad_MTZOUTfile)
         except:
            sys.stdout.write("Warning: CAD MTZ output file not found in Acorn function\n")
            sys.stdout.write("\n")

      # Setup an ecalc job
      # Instantiate the class
      ecalc=MRBUMP_ecalc.Ecalc()

      # Set the debug flag to true
      ecalc.debug=True

      # Set the keywords
      ecalc.add_keyword("TITLE Run ecalc to generate normalised structure factor amplitudes")
      ecalc.add_keyword("LABIn FP=%s SIGFP=%s" % (target_info.mtz_coldata["F_ISO"], target_info.mtz_coldata["SIGF_ISO"]))
      ecalc.add_keyword("LABOut E=%s SIGE=%s" % (target_info.mtz_coldata["E"], target_info.mtz_coldata["SIGE"]))
      ecalc.add_keyword("END")

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            job_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Ecalc",
               init.ProjectName + "_Ecalc")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Ecalc")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", init.ProjectName + "_Ecalc")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.aniso_MTZOUTfile)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, self.ecalc_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, target_info.ecalc_logfile)
         except:
            self.DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Ecalc job\n")
            sys.stdout.write("\n")
   
      # Ecalc the MTZ file
      ecalc.run(target_info.aniso_MTZOUTfile, self.ecalc_MTZOUTfile, target_info.ecalc_logfile)

      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, job_ID, "STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail = False

      # Remove the aniso MTZ file
      if self.debug == False:
         try:
            os.remove(target_info.aniso_MTZOUTfile)
         except:
            sys.stdout.write("Warning: Aniso MTZ output file not found in Acorn function\n")
            sys.stdout.write("\n")

   def run_acorn(self, init, mstat, target_info, model):
      """ Run Acorn to imporove the phases. """

      # Instantiate the class
      acorn=MRBUMP_acorn.Acorn()

      # Set the keywords
      acorn.add_keyword("LABIn FP=%s SIGFP=%s E=%s" % \
                        (target_info.mtz_coldata["F"], target_info.mtz_coldata["SIGF"], target_info.mtz_coldata["E"]))
      acorn.add_keyword("POSI 1")

      # Set the output MTZ file
      self.hklout=model.acorn_MTZOUTfile    

      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try:
            job_ID=mstat.conn.AddSubJob( \
               init.ProjectName,init.JobId,
               "Acorn",
               model.name + "_ACORN")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Acorn")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", model.name + "_ACORN")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.ecalc_MTZOUTfile)
            mstat.conn.AddInputFile(init.ProjectName, job_ID, model.acorn_XYZINfile)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, model.acorn_MTZOUTfile)
            mstat.conn.SetLogfile(init.ProjectName, job_ID, model.acorn_logfile)
         except:
            self.DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Acorn job\n")
            sys.stdout.write("\n")
   
      # Acorn the MTZ file
      acorn.run(target_info.ecalc_MTZOUTfile, model.acorn_MTZOUTfile, model.acorn_XYZINfile, model.acorn_logfile)
   
      # Set the status to be finished in the DB
      if init.keywords.DBOUT and self.DB_fail == False:
         mstat.conn.SetData(init.ProjectName, job_ID, "STATUS", "FINISHED")
      elif self.DB_fail:
         self.DB_fail = False

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
      sys.stdout.write("   %s\n" % logfile)
      sys.stdout.write("\n")
      sys.stdout.write("Output MTZ file from Acorn: \n")
      sys.stdout.write("   %s\n" % self.hklout)
      sys.stdout.write("\n")
      sys.stdout.write("################################################################\n")
      sys.stdout.write("\n")


if __name__ == "__main__":

   target_info=Target_info()

   target_info.space_group = "P21"
   target_info.hklin       = "test/target.mtz"

   target_info.cell_dimensions['a']      = 38.4300
   target_info.cell_dimensions['b']      = 34.7640
   target_info.cell_dimensions['c']      = 60.2760
   target_info.cell_dimensions['alpha']  = 90.0000
   target_info.cell_dimensions['beta']   = 106.0290
   target_info.cell_dimensions['gamma']  = 90.0000

   target_info.mtz_coldata["F"]    = "F"
   target_info.mtz_coldata["SIGF"] = "SIGF"
   target_info.mtz_coldata["E"]    = "E"
   target_info.mtz_coldata["SIGE"] = "SIGE"

   model=Model()    

   model.name="phaser"
   model.model_directory="./"

   target_info.unique_MTZOUTfile="building/unique_out.mtz"
   target_info.unique_logfile="building/unique.log"

   target_info.cad_MTZOUTfile="building/cad_out.mtz"
   target_info.cad_logfile="building/cad.log"

   target_info.aniso_MTZOUTfile="building/aniso_out.mtz"
   target_info.aniso_logfile="building/aniso.log"

   target_info.ecalc_MTZOUTfile="building/ecalc_out.mtz"
   target_info.ecalc_logfile="building/ecalc.log"

   model.acorn_MTZOUTfile="building/acorn_out.mtz"
   model.acorn_logfile="building/acorn.log"

   model.acorn_XYZINfile="building/target.pdb"

   pi=PhaseImprove()

   pi.prepare(target_info, model)
   pi.run_acorn(target_info, model)

