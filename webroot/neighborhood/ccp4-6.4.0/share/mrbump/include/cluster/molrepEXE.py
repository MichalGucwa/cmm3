#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# A MrBUMP wrapper for Molrep 
# Ronan Keegan - 18/1/07
#



import os, sys, string
import time
import shutil
import refmacEXE
import pdbtools
import subprocess
import shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

#if os.environ.has_key('MRBUMP_CLUSTER'):
#   if os.environ["MRBUMP_CLUSTER"] == True:
#      sys.path.append(os.path.join(os.environ["CCP4"], "share", "mrbump", "include", "building"))
#
#import MRBUMP_Shelxe

def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

class MolrepEXE:
   """ A class to run a Molrep job. """

   def __init__(self):
      if os.name=="nt":
         self.molrepEXE = os.path.join(os.environ["CBIN"], "molrep.exe")  
      else:
         self.molrepEXE = os.path.join(os.environ["CBIN"], "molrep")  

      self.logfile = ""
      self.hklin = ""
      self.pdbin = ""
      self.pdbout = ""
      self.RFfile = ""
      self.hklinBase = ""
      self.pdbinBase = ""
      self.pdboutBase = ""
      self.RFfileBase = ""
      self.key = ""
      self.keywords = []
      self.contrast=0.0
      self.soln_found=False
      
      self.copyPDB=False
      self.copyMTZ=False

      self.SG_Codes={"P31" : "144", "P32" : "145", "P3112" : "151", "P3212" : "153", 
                     "P3121" : "152", "P3221" : "154", "P41" : "76", "P43" : "78", 
                     "P4122" : "91", "P4322" : "95", "P41212" : "92", "P43212" : "96", 
                     "P61" : "169", "P65" : "170", "P62" : "171", "P64" : "172", 
                     "P6122" : "178", "P6522" : "179", "P6222" : "180", "P6422" : 
                     "181", "P4332" : "212", "P4132" : "213"}

      self.ENANT_SG={"144" : "145", "145" : "144", "151" : "153", "153" : "151", 
                     "152" : "154", "154" : "152", "76" : "78", "78" : "76", 
                     "91" : "95", "95" : "91", "92" : "96", "96" : "92", "169" : "170", 
                     "170" : "169", "171" : "172", "172" : "171", "178" : "179", 
                     "179" : "178", "180" : "181", "181" : "180", "212" : "213", "213" : "212"}

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def set_logfile(self, filename):
      self.logfile=filename

   def set_hklin(self, filename):
      self.hklin=filename

   def set_pdbin(self, filename):
      self.pdbin=filename

   def set_RFfile(self, filename):
      self.RFfile=filename

   def add_keyword(self, keyword):
      self.keywords.append(keyword)
      

   def check_contrast(self):
      """ Check tthe logfile of the job for the Contrast value. """
 
      f=open(self.logfile, "r")
      
      line=f.readline()
      while line:
         if "Contrast =" in line:
            try:
               self.contrast=float(string.split(line)[-1])
            except:
               sys.stdout.write("MR Log: error extracting Contrast value from Molrep log file\n")
               sys.stdout.write("\n")

         line=f.readline()

      f.close()

   def run(self, working_DIR, hklin, pdbin, pdbout, logfile, molrepDir="", script="", mode="A", keyfile="", LITE=False):
      """ Function to launch a molrep job. """

      # Change to the running directory for molrep
      os.chdir(working_DIR)

      # Give a header output
      sys.stdout.write("#################################################\n")
      if mode != "T":
         sys.stdout.write("Running Molrep...... \n")
      else: 
         sys.stdout.write("Running Molrep in enantiomorphic SG...... \n")
      sys.stdout.write("#################################################\n")
      sys.stdout.write("\n")

      # Create a job and first set up the Reindex details

      # Check to see if the logfile has been specified, otherwise give it a default name
      if self.logfile=="":
         self.logfile=logfile 

      # Set HKLIN if it has not been set already
      if self.hklin=="":
         self.hklin=hklin
      self.hklinBase=os.path.basename(self.hklin)

      # Set PDBIN & PDBOUT 
      if self.pdbin=="":
         self.pdbin=pdbin
      self.pdbinBase=os.path.basename(self.pdbin)

      if self.pdbout=="":
         self.pdbout=pdbout
      self.pdboutBase=os.path.basename(self.pdbout)

      # Set the keywords for the job 
      if keyfile == "":
      # If no keyword file is given read keywords from the input keywords
         for keyword in self.keywords:
            self.key=self.key + keyword + "\n"

      else:
      # Read keywords from the keyword file 
         kfile=open(keyfile, "r")
         line=kfile.readline()
         while line:
            self.key = self.key + line
            line=kfile.readline()
         kfile.close()
        
      # Add the function mode keyword
      self.key = self.key + "FUN " + mode + "\n"

      # Output the keywords if in debug mode
      if self.local_debug:
         sys.stdout.write("#########################\n")
         sys.stdout.write("Molrep keyword input:\n")
         sys.stdout.write("#########################\n")
         sys.stdout.write("\n")
         sys.stdout.write(self.key)
         sys.stdout.write("\n")
         time.sleep(2)

      # Make a note of the current working diretory
      currentDir=os.getcwd()

      # Change to the Molrep directory so we can run refmac without long paths
      os.chdir(molrepDir)

      # Copy in the PDB and MTZ file for efficient running of Molrep
      if os.path.isfile(os.path.join(molrepDir, self.pdbinBase)) == False:
         shutil.copyfile(self.pdbin, os.path.join(molrepDir, self.pdbinBase))
         self.copyPDB=True
      if os.path.isfile(os.path.join(molrepDir, self.hklinBase)) == False:
         shutil.copyfile(self.hklin, os.path.join(molrepDir, self.hklinBase))
         self.copyMTZ=True

      # Set the command line
      command_line=self.molrepEXE + " HKLIN %s MODEL %s" % (self.hklinBase, self.pdbinBase)

      # if in Debug mode write out the run script for this Molrep job
      if (self.debug or LITE) and os.name != "nt" and script!="":
         try:
            line = "#! /bin/sh\n\n"
            line+= "cp %s %s\n" % (self.pdbin, os.path.join(molrepDir, self.pdbinBase)) 
            line+= "cp %s %s\n\n" % (self.hklin, os.path.join(molrepDir, self.hklinBase)) 
            line+= "%s << eof\n" % command_line 
            line+= "%s" % self.key
            line+= "eof\n"

            f=open(script, "w")
            f.write(line)
            f.close()
            os.chmod(script,0755)
         except:
            sys.stdout.write("Script write warning: Could not write molrep run script\n")
            sys.stdout.write("\n")

      # Open a pipe to the job
      # Echo the command line in debug mode
      if self.local_debug:
         sys.stdout.write("\n")
         sys.stdout.write("======================\n")
         sys.stdout.write("MOLREP command line:\n")
         sys.stdout.write("======================\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch molrep
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

      (child_stdout_and_stderr, child_stdin) = (p.stdout, p.stdin)

      # Write the keyword input
      child_stdin.write(self.key)
      child_stdin.close()         
 
      # Open the log file for writing
      log=open(self.logfile, "w")

      # Watch the stdout and stderr for successful termination
      out=child_stdout_and_stderr.readline()
      log.write(out)

      while out:
         if self.local_debug:
            sys.stdout.write(out)
         out=child_stdout_and_stderr.readline()
         log.write(out)

      child_stdout_and_stderr.close()
      log.close()

      # Check that the output PDB file was created
      if os.path.isfile(os.path.join(working_DIR, "molrep.pdb")):
         shutil.move(os.path.join(working_DIR, "molrep.pdb"), self.pdbout)
         self.soln_found = True
         # Report that a solution has been found
         sys.stdout.write("MR log: Molrep has produced a solution\n")
         if LITE:
            sys.stdout.write("Running in 'LITE' mode. Output files from Molrep " + \
                             "have been removed but can be re-generated by running:\n  %s\n" % script)
         else:
            sys.stdout.write("        Output PDB file:\n %s\n" % self.pdbout)
         sys.stdout.write("\n") 
      else:
         if self.debug:
            sys.stdout.write("MR debug log: Molrep failed to produce a PDB file\n") 
            sys.stdout.write("              Log file can be found at:\n %s\n" % self.logfile) 
            sys.stdout.write("\n") 
         self.soln_found = False

      # Revert to the working directory before molrep run
      os.chdir(currentDir)

      # Delete any copied files to save space
      if self.debug == False:
         if self.copyPDB and os.path.isfile(os.path.join(molrepDir, self.pdbinBase)):
            os.remove(os.path.join(molrepDir, self.pdbinBase))
         if self.copyMTZ and os.path.isfile(os.path.join(molrepDir, self.hklinBase)):
            os.remove(os.path.join(molrepDir, self.hklinBase))
    

if __name__ == "__main__":
   """ An example run. Also allows this function to be called as an executable on Clusters."""

   if len(sys.argv) == 8:
      hklin       = sys.argv[1]
      pdbin       = sys.argv[2]
      pdbout      = sys.argv[3]
      hklin_SG   = sys.argv[4]
      job_name    = sys.argv[5]
      working_DIR = sys.argv[6]
      SHELXE      = sys.argv[7]
   else:
      sys.stdout.write("Usage: molrepEXE.py <hklin> <pdbin> <pdbout> <target spacegroup> <job name> <working directory> <run shelxe True/False>\n")
      sys.stdout.write("\n")
      sys.exit()

   if os.path.isdir(working_DIR) == False:
      os.mkdir(working_DIR)

   # Instantiate the class
   molrep1=MolrepEXE()

   # Determine the spacegroup code for the enantiomorph
   hklin_SG_Code=molrep1.SG_Codes[hklin_SG]   
   pdbout1 = os.path.join(working_DIR, job_name + "_out_" + hklin_SG_Code + ".pdb")

   if molrep1.SG_Codes.has_key(hklin_SG): 
      enant_SG_Code=molrep1.ENANT_SG[hklin_SG_Code]
      pdbout2 = os.path.join(working_DIR, job_name + "_out_" + enant_SG_Code + ".pdb")
      ENANT=True
   else:
      ENANT=False

   # Set the debug flag to true
   molrep1.debug=True
   molrep1.local_debug=True

   molrep1.set_RFfile(os.path.join(working_DIR, "molrep_rf.tab"))

   # Set the keywords 
   molrep1.add_keyword("DOC Y")
   molrep1.add_keyword("LABIN F=FP SIGF=SIGFP")
   molrep1.add_keyword("NMON 2")
   molrep1.add_keyword("File_T " + molrep1.RFfile)
 
   # Run Molrep
   molrep1.run(hklin, pdbin, pdbout1, os.path.join(working_DIR, "molrep1.log"))

   # Extract contrast value for this job
   molrep1.check_contrast()

   if ENANT:
      # Instantiate the class
      molrep2=MolrepEXE()

      # Set the debug flag to true
      molrep2.debug=True
      molrep2.local_debug=True

      # Set the keywords 
      molrep2.add_keyword("DOC Y")
      molrep2.add_keyword("LABIN F=FP SIGF=SIGFP")
      molrep2.add_keyword("NMON 2")
      molrep2.add_keyword("File_T " + molrep1.RFfile)
      molrep2.add_keyword("NOSG " + enant_SG_Code)
 
      # Run Molrep in enantiomorphic SG, translation function only 
      molrep2.run(hklin, pdbin, pdbout2, os.path.join(working_DIR, "molrep2.log"), mode="T")

      # Extract contrast value for this job
      molrep2.check_contrast()

      print "Final contrast for HKLIN: %.3f" % molrep1.contrast
      print "Final contrast for Enant : %.3f" % molrep2.contrast
 
      if molrep1.contrast >= molrep2.contrast:
         shutil.copy(pdbout1, pdbout)   
      else:
         shutil.copy(pdbout2, pdbout)   
   else:
      print "Final contrast for HKLIN: %.3f" % molrep1.contrast
      shutil.copy(pdbout1, pdbout)   

   # Get the number of molecules found
   details=pdbtools.Get_PDB_Details()
   details.get_details(pdbout)
  
   # Create summary of the PDB file using pdbcur
   #details.pdbcur(pdbcur_logfile, pdbout)

   sys.stdout.write("Number of molecules found in %s : %d\n" % (pdbout, details.mol_count))
   sys.stdout.write("\n")

   # Run refmac
   refmac_job=refmacEXE.RefmacEXE()
 
   # Set the keywords
   refmac_job.add_keyword('LABIn FP=FP' \
                          + ' SIGFP=SIGFP' \
                          + ' FREE=FreeR_flag')
   refmac_job.add_keyword('NCYC 30')
   refmac_job.add_keyword('MAKE HYDR N')
   refmac_job.add_keyword('WEIGHT MATRIX 0.01')
   refmac_job.add_keyword('END')

   # Run refmac
   refmac_job.run(hklin, "refmac_out.mtz", pdbout, "refmac_out.pdb", "refmac_logfile.log")

   # If Shelxe is present and option was selected by the user, run Shelxe to trace C-alpha
#   if SHELXE and which("shelxe"):
#      shelxe_job=MRBUMP_Shelxe.Shelxe()
#
#      SHELX.runMtz2Various(hklin, fp="FP", sigfp="SIGFP", free="FreeR_flag")
#      SHELX.runShelxe(solvent, resolution, mrProgram, "refmac_out.pdb", traceCycles=15)
      #SHELX.results(mrProgram)
