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
# Initialisation for a MRBUMP job
# Ronan Keegan - 23.10.05

import os, sys, string
import shutil
import datetime,time
import MRBUMP_keywords
import MRBUMP_environment
import MRBUMP_update_DB
import MRBUMP_check_dependencies
import MRBUMP_pdbmerge
import MRBUMP_reindex
import MRBUMP_ctruncate
import Phase_improve
import WriteLogfile
import Web_test
import shlex
import subprocess

class Initialise:
   """ A class to do the initialisation for a MRBUMP job. This includes:
       1) Read the command line arguments,
       2) Read in the keywords from command prompt or a file,
       3) Read the environment variables,
       4) Setup the search directory structure,
       5) Update any search databases. """
   
   def __init__(self):
      self.keywords=MRBUMP_keywords.Keywords()
      self.environment=MRBUMP_environment.Environment()
      self.check_deps=MRBUMP_check_dependencies.Check_deps()

      self.ProjectName="mrbump"

      self.version="00.7.01"
      self.version_date="05/11/12"
      self.hklin = ""
      self.seqin = ""
      self.pirin = ""
      self.hklout = ""
      self.xyzout = ""
      self.xmlin = ""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.hklin_filename = ""
      self.seqin_filename = ""
      self.pirin_filename = ""
      self.hklout_filename = ""
      self.xyzout_filename = ""
      self.xmlin_filename = ""
 
      self.labin_found = False
      self.jobid_found = False

      self.mrbump = ""
      self.mrbump_incl = ""
      self.mrbump_data = ""
 
      self.current_dir = ""
      self.search_dir = ""
      self.results_dir = ""
      self.scratch_dir = ""

      self.pythonVersion = int(str(sys.version_info[0]) + str(sys.version_info[1]) + str(sys.version_info[2])) 
      self.phaserVersion = 224
      self.molrepVersion = 11.0

      self.model_types=[]

      self.ONLYMODELS = False
      self.MRONLY = False
      self.XML = False
      self.PREPDIR = ""
      self.localPDBmirror = False

      self.results_logfile=""

      # Results html has a variable location to support inclusion in the CCP4i gui.
      self.results_html = ""
      self.results_html_filename = ""

      # Relative link is a variable to hold the path to the results html files.
      # It should be empty for operation when the results html is in its 
      # default location. This is to ensure that the WebService works correctly.
      self.relative_link = ""

      # Check variable for acorn
      self.acorn_found = False

      # Check variable for cpirate
      if os.name=="nt":
         if os.path.join(os.environ["CCP4_BIN"], "cpirate.exe"):
            self.cpirate_found = True
         else:
            self.cpirate_found = False
      else:
         if os.path.join(os.environ["CCP4_BIN"], "cpirate"):
            self.cpirate_found = True
         else:
            self.cpirate_found = False

      # Set the reference MTZ file for cpirate
      self.cpirate_MTZref_file=os.path.join(os.environ["CCP4"],"lib","data","reference_structures","reference-1ajr.mtz")

      # Set up the column labels for the cpirate reference MTZ file
      self.cpirate_mtz_coldata=dict([])
      self.cpirate_mtz_coldata['F']    ="FP.F_sigF.F"
      self.cpirate_mtz_coldata['SIGF'] ="FP.F_sigF.sigF"
      self.cpirate_mtz_coldata['HLA']  ="FC.ABCD.A"
      self.cpirate_mtz_coldata['HLB']  ="FC.ABCD.B"
      self.cpirate_mtz_coldata['HLC']  ="FC.ABCD.C"
      self.cpirate_mtz_coldata['HLD']  ="FC.ABCD.D"

      self.molrep_fixed_PDBfile=""
      self.merge_fixed_logfile=""

      if os.name=="nt":
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn.exe")
      else:
         self.acornEXE = os.path.join(os.environ["CCP4_BIN"], "acorn")

      # Set up the download URLs for the PDB files
      
      self.download_urls=dict([])

      #EBI:
      pdu=PDB_download_site()
      pdu.name="EBI"
      pdu.url="ftp://ftp.ebi.ac.uk/pub/databases/msd/pdb_uncompressed/"
      pdu.rank=1
      pdu.type="ftp"
     
      self.download_urls[pdu.name]=pdu

      #WWPDB:
      pdu=PDB_download_site()
      pdu.name="WWPDB"
      pdu.url="ftp://ftp.wwpdb.org/pub/pdb/data/structures/all/pdb/"
      pdu.rank=2
      pdu.type="ftp"
     
      self.download_urls[pdu.name]=pdu

      #JAPAN:
      pdu=PDB_download_site()
      pdu.name="JAPAN"
      pdu.url="ftp://pdb.protein.osaka-u.ac.jp/pub/pdb/data/structures/all/pdb/"
      pdu.rank=3
      pdu.type="ftp"
     
      self.download_urls[pdu.name]=pdu

      #OCA:
      pdu=PDB_download_site()
      pdu.name="SEQ"
      #pdu.url="http://oca.ebi.ac.uk/oca-bin/save-pdb?id="
      pdu.url="http://www.rcsb.org/pdb/files/"
      pdu.rank=4
      pdu.type="http"
     
      self.download_urls[pdu.name]=pdu

#      self.download_urls={'EBI' : 'ftp://ftp.ebi.ac.uk/pub/databases/msd/pdb_uncompressed/',
#                          'WWPDB' : 'ftp://ftp.wwpdb.org/pub/pdb/data/structures/all/pdb/',
#                          'OCA' : 'http://oca.ebi.ac.uk/oca-bin/save-pdb?id=',
#                          'JAPAN' : 'ftp://pdb.protein.osaka-u.ac.jp/pub/pdb/data/structures/all/pdb'}

   def setHKLIN(self, filename):
      self.hklin = filename
      self.hklin_filename = os.path.split(filename)[-1]

   def setPREPDIR(self, dirname):
      self.PREPDIR = dirname

   def setSEQIN(self, filename):
      self.seqin = filename
      self.seqin_filename = os.path.split(filename)[-1]

   def setHKLOUT(self, filename):
      if os.path.dirname(filename) == "":
         full_filename=os.path.join(self.current_dir, filename)
      else:
         full_filename=filename
      self.hklout = full_filename
      self.hklout_filename = os.path.basename(full_filename)

   def setXYZOUT(self, filename):
      if os.path.dirname(filename) == "":
         full_filename=os.path.join(self.current_dir, filename)
      else:
         full_filename=filename
      self.xyzout = full_filename
      self.xyzout_filename = os.path.basename(full_filename)

   def setXMLIN(self, filename):
      self.xmlin = filename
      self.xmlin_filename = os.path.split(filename)[-1]

   def setMRBUMP(self, directory):
      self.mrbump = directory
   
   def setMRBUMP_INCL(self, directory):
      self.mrbump_incl = directory
   
   def setMRBUMP_DATA(self, directory):
      self.mrbump_data = directory

   def setSearch_DIR(self, directory):
      self.search_dir = directory

   def setResults_DIR(self, directory):
      self.results_dir = directory

   def setScratch_DIR(self, directory):
      self.scratch_dir = directory

   def setResults_Logfile(self, filename):
      self.results_logfile = filename

   def setResults_HTML(self, filename):
      self.results_html = filename

   def setResults_HTML_Filename(self, filename):
      self.results_html_filename = filename

   def setRelative_Link(self, directory):
      self.relative_link = directory

   def printHeader(self):

      # Get the current date
      runDate="00/00/0000"
      try:
         (year, month, day) = string.split(str(datetime.date.today()),"-")
         runDate="%s/%s/%s" % (day, month, year)
      except:
         sys.stdout.write("Warning: Could not set run date\n\n")
         runDate="00/00/0000"

      # Get the username
      user="unknown"
      try:
         import getpass
         user=getpass.getuser()
      except:
         sys.stdout.write("Warning: Could not determine user name\n\n")
         user="unknown"

      # Tag this up as SUMMARY content
      sys.stdout.write('<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n')

      sys.stdout.write("\n")
      sys.stdout.write(" ###############################################################\n")
      sys.stdout.write(" ###############################################################\n")
      sys.stdout.write(" ###############################################################\n")
      sys.stdout.write(" ### CCP4 6.3: MRBUMP               version %s : %s##\n" % (self.version, self.version_date))
      sys.stdout.write(" ###############################################################\n")
      sys.stdout.write(" User: " + user + "  Run date: " + runDate + " Run time: " + string.split(time.ctime())[3] + " \n")
      sys.stdout.write("\n")

      # Output OS and Python version info for debugging
      sys.stdout.write("\n")
      sys.stdout.write("Operating System: %s\n" % sys.platform)
      sys.stdout.write("Python Version:\n%s\n" % sys.version)
      sys.stdout.write("Python location:\n%s\n" % sys.executable)
      sys.stdout.write("\n")

   def mrbump_initialisation(self, arguments, mstat, target_info):
      """ A function to initialise a MrBUMP job. """ 
     
      # Get the current working directory
      self.current_dir=os.getcwd()

      # Read the command line arguments
      self.read_cmdline(arguments)

      # Read the keywords from the STDIN or from a file
      if self.XML == False:
         self.keywords.read_keywords()
      else:
         self.read_XMLinput()
 
      # Set the master directory
      self.setSearch_DIR(os.path.join(self.keywords.ROOTDIR, 'search_' + self.keywords.JOBID))

      # Check the Phaser version
      if "PHASER" in self.keywords.MR_PROGRAM_LIST:
         self.checkPhaserVersion()
         if self.debug:
            sys.stdout.write("Initialisation: Phaser version is %s\n" % self.phaserVersion)
            sys.stdout.write("\n")

      # Check the Molrep version
      if "MOLREP" in self.keywords.MR_PROGRAM_LIST:
         self.checkMolrepVersion()
         if self.debug:
            sys.stdout.write("Initialisation: Molrep version is %s\n" % self.molrepVersion)
            sys.stdout.write("\n")

      # Process the details of the MODELSONLY run if we are doing and MRONLY run
      if self.MRONLY:
         import pickle
         
         # Reset the master directory name if one of that name already exists
         if os.path.isdir(self.search_dir) \
            and (self.search_dir == self.PREPDIR or os.path.split(self.search_dir)[-1] == self.PREPDIR): 
            sys.stdout.write("The directory %s already exists.\nA new directory called %s_MR will be used for this job\n" \
                              % (self.search_dir, self.search_dir)) 
            sys.stdout.write("\n")
            self.keywords.JOBID=self.keywords.JOBID + "_MR"
            self.setSearch_DIR(os.path.join(self.keywords.ROOTDIR, 'search_' + self.keywords.JOBID))
         elif os.path.isdir(self.search_dir): 
            sys.stdout.write("The directory %s already exists.\nPlease remove it or use a different Job ID\n" % self.search_dir)
            sys.stdout.write("\n")
            sys.exit()

         # Setup the directory structure for the job
         self.make_job_dir()

         # Adjust the paths in the copied pickle files    
         init_f=open(os.path.join(self.search_dir, "results", "pickle_data", "init.dat"), "r")
         temp_init=pickle.load(init_f)

         pickled_jobdir=temp_init.search_dir

         init_f.close()        

         # Open each of the copied files and adjust the paths
         for i in "init", "target", "mstat":
            if os.path.isfile(os.path.join(self.search_dir, "results", "pickle_data", i + ".dat")) == False:
               sys.stdout.write("Input Error: MRONLY - pickle file not found for %s object\n" % i) 
               sys.stdout.write("             (from: %s)\n" % os.path.join(self.PREPDIR, "results", "pickle_data", i + ".dat"))
               sys.stdout.write("\n")
               sys.exit()

            # Create a temporary file with the paths adjusted, then copy it over the original
            f=open(os.path.join(self.search_dir, "results", "pickle_data", i + ".dat"), "r")
            o=open(os.path.join(self.scratch_dir, "temp_" + i + ".dat"), "w")

            line=f.readline()
            while line:
               if pickled_jobdir in line:
                  line=line.replace(pickled_jobdir, self.search_dir)
               o.write(line)
               line=f.readline()

            f.close()
            o.close()
       
            # Now copy this file to the original
            os.remove(os.path.join(self.search_dir, "results", "pickle_data", i + ".dat"))
            shutil.copy(os.path.join(self.scratch_dir, "temp_" + i + ".dat"), \
                        os.path.join(self.search_dir, "results", "pickle_data", i + ".dat"))

         # Read the details from the pickled object files (paths updated)
         for i in "init", "target", "mstat":

            # Read in the details from the pickle files
            f=open(os.path.join(self.search_dir, "results", "pickle_data", i + ".dat"), "r")

            if i == "init":
               # Assign this to a temp variable so that we can pull out the bits we want from the MODEL gen run
               temp_init=pickle.load(f)

               self.seqin = temp_init.seqin
               self.seqin_filename = temp_init.seqin_filename
 
               self.keywords.parent_JOBID = temp_init.keywords.JOBID
               self.keywords.NMASU = temp_init.keywords.NMASU

               self.keywords.MRNUM = temp_init.keywords.MRNUM 
               
               # Backward compatibility
               self.keywords.ENSMODNUM = getattr(temp_init.keywords, 'ENSEMNUM', temp_init.keywords.ENSMODNUM)

               self.keywords.USEENSEM = temp_init.keywords.USEENSEM 
 
               self.keywords.E_value = temp_init.keywords.E_value 
               self.keywords.MAPROGRAM = temp_init.keywords.MAPROGRAM 
      
               self.keywords.SSM = temp_init.keywords.SSM 
               self.keywords.SCOP = temp_init.keywords.SCOP 
               self.keywords.PQS = temp_init.keywords.PQS 
               self.keywords.PISA = temp_init.keywords.PISA 

               self.keywords.MDLUNMOD = temp_init.keywords.MDLUNMOD 
               self.keywords.MDLDPDBCLP = temp_init.keywords.MDLDPDBCLP 
               self.keywords.MDLPLYALA = temp_init.keywords.MDLPLYALA 
               self.keywords.MDLMOLREP = temp_init.keywords.MDLMOLREP 
               self.keywords.MDLCHAINSAW = temp_init.keywords.MDLCHAINSAW 
               self.keywords.MDLSCULPTOR = temp_init.keywords.MDLSCULPTOR 

               self.keywords.fasta_local = temp_init.keywords.fasta_local 
               self.keywords.run_local = temp_init.keywords.run_local   

               self.keywords.UPDATE = temp_init.keywords.UPDATE 
               self.keywords.DOFASTA = temp_init.keywords.DOFASTA 

               self.keywords.ignore_list = temp_init.keywords.ignore_list 
               self.keywords.include_list = temp_init.keywords.include_list 
               self.keywords.local_list = temp_init.keywords.local_list 
               self.keywords.locfile_count = temp_init.keywords.locfile_count 
               self.keywords.error_string = temp_init.keywords.error_string 

               self.keywords.jobid_found = temp_init.keywords.jobid_found 
    
               self.keywords.DUMMY = temp_init.keywords.DUMMY 
               self.keywords.PICKLE = temp_init.keywords.PICKLE 
            
            if i == "mstat":
               mstat=pickle.load(f) 
            if i == "target":
               target_info=pickle.load(f) 

      else:
         # Setup the directory structure for the job
         self.make_job_dir()

      # Check to see if the http proxy has been set by the user and add it to the environment if it has
      if self.keywords.PROXYSERVER != "":
         if os.environ.has_key("http_proxy"):
            sys.stdout.write("Warning: The proxy server seems to be already set in the environment.\n")
            sys.stdout.write("         It is currently set to:\n            %s.\n" % os.environ["http_proxy"])
            sys.stdout.write("         MrBUMP is going to reset this to:\n            %s\n" % self.keywords.PROXYSERVER)
            sys.stdout.write("\n")
            sys.stdout.write("         If MrBUMP has problems connecting to the internet you should check\n")
            sys.stdout.write("         that this setting is correct\n")
            sys.stdout.write("\n")
         else:
            sys.stdout.write("Setting the http_proxy environment variable to:\n    %s\n" % self.keywords.PROXYSERVER)
            sys.stdout.write("\n")
         
         # Set the proxy server
         os.environ["http_proxy"] = self.keywords.PROXYSERVER

      # if the ftp proxy is set unset it (within MrBUMP) to prevent download failure 
      if os.environ.has_key("ftp_proxy"):
         del os.environ["ftp_proxy"]

      # Check the web connection
      if self.keywords.CHECK:
 
         sys.stdout.write("Web connectivity test enabled. Checking PDB servers for file availability....\n")
         sys.stdout.write("(Note: Disable this in the MrBUMP interface if running without a web connection)\n")
         sys.stdout.write("\n")

         test_web=Web_test.Test_connection()
         test_web.test("1smw", self.download_urls)
         if test_web.connect==False:
            sys.exit()

      # Update checking
      db_tools=MRBUMP_update_DB.DB_tools()

      # Check to see if a new version of mrbump exists
      if self.keywords.UPDATE:
         db_tools.check_version(self.version)

      # Output the mode of operation details
      sys.stdout.write("\n")
      sys.stdout.write("##########################################################################\n")
      if self.ONLYMODELS == False and self.MRONLY == False:
         sys.stdout.write("Mode of operation: FULLMR -\n   Search models will be created and used in Molecular Replacement.\n")
      elif self.ONLYMODELS:
         sys.stdout.write("Mode of operation: MODELS -\n   Search models will be created only.\n")
      elif self.MRONLY:
         sys.stdout.write("Mode of operation: MRONLY -\n   Molecular Replacement will be carried out using models\n")
         sys.stdout.write("   generated in a earlier run of MRBUMP.\n")
      sys.stdout.write("##########################################################################\n")
      sys.stdout.write("\n")
 
      # Close the SUMMARY tag for the input details
      sys.stdout.write('<!--SUMMARY_END--></FONT></B>\n')

      # Output the input and output file details
      if self.ONLYMODELS == False:
         sys.stdout.write("Input MTZ file: %s\n" % self.hklin)
         
         # Check to see if LABIN has been specified in the input keywords
         if self.keywords.labin_found == False:
            sys.stdout.write("Keyword error:\n")
            sys.stdout.write("Keyword LABIN must be provided and must specify 3 column labels: F, SIGF and FreeR_flag\n")
            sys.stdout.write("  e.g. LABIn F=FP SIGF=SIGFP FreeR_flag=FREE\n")
            sys.exit(1)

      sys.stdout.write("Input Sequence file: %s\n" % self.seqin)

      if self.ONLYMODELS == False:
         sys.stdout.write("Output MTZ file: %s\n" % self.hklout)
         sys.stdout.write("Output PDB file: %s\n" % self.xyzout)
      sys.stdout.write('\n')

      # Check that at least one Model preperation technique has been specified. If none are set UNMOD 
      # to True.
      if self.keywords.MDLUNMOD == False and self.keywords.MDLDPDBCLP == False and self.keywords.MDLPLYALA == False \
         and self.keywords.MDLMOLREP == False and self.keywords.MDLCHAINSAW == False and self.keywords.MDLSCULPTOR == False:
            sys.stdout.write("No model preparation method has been specified. UNMOD (unmodified) will be used in this case.\n")
            self.keywords.MDLUNMOD = True

      # Add the types of models we want to generate to the list of model types
      if self.keywords.MDLUNMOD:
         self.model_types.append('UNMOD')
      if self.keywords.MDLDPDBCLP:
         self.model_types.append('PDBCLP')
      if self.keywords.MDLPLYALA:
         self.model_types.append('PLYALA')
      if self.keywords.MDLMOLREP:
         self.model_types.append('MOLREP')
      if self.keywords.MDLCHAINSAW:
         self.model_types.append('CHNSAW')
      if self.keywords.MDLSCULPTOR:
         self.model_types.append('SCLPTR')
 
      # Setup the environment for python
      self.environment.read_environment()

      # Check that all dependencies are in place

      # Sequence alignment program:
      self.check_deps.chk_ma_program(self.keywords)
      # Molecular Replacement program:
      self.keywords.MR_PROGRAM_LIST=self.check_deps.chk_MRPROGRAM(self.keywords)
      
      # Setup the directory structure for the job
     # self.make_job_dir()

      # Copy in the input files to the search directory - .seq, .mtz.
      # After copying, reassign the file pointers.

      if self.MRONLY == False:
         shutil.copy(self.seqin, os.path.join(self.search_dir, 'input'))

      # Fix for permissions problem with sequence file. If the permissions on your sequence file are
      # read only then it can't be re-written for molrep. 
      os.chmod(os.path.join(self.search_dir, 'input', self.seqin_filename), 0755) 

      if self.ONLYMODELS == False:
         shutil.copy(self.hklin, os.path.join(self.search_dir, 'input'))
         self.hklin=os.path.join(self.search_dir, 'input', self.hklin_filename)

      self.seqin=os.path.join(self.search_dir, 'input', self.seqin_filename)

      # Copy over header for results page
      shutil.copyfile(os.path.join(self.mrbump_incl, 'web_template', 'ccp4.gif'), os.path.join(self.results_dir, 'images', 'ccp4.gif'))
      shutil.copyfile(os.path.join(self.mrbump_incl, 'web_template', 'cclrc-logo.jpg'), os.path.join(self.results_dir, 'images', 'cclrc-logo.jpg'))
      shutil.copyfile(os.path.join(self.mrbump_incl, 'web_template', 'slide_bar.gif'), os.path.join(self.results_dir, 'images', 'slide_bar.gif'))
      #shutil.copyfile(os.path.join(self.mrbump_incl, 'web_template', 'results.html'), self.results_html)

      # Update the search databases if necessary
      db_tools.setMRBUMPDataDir(self.mrbump_data)

      if self.keywords.run_local == False:
         db_tools.test_first_run(self.environment)
         db_tools.test_databases(self.environment, self.keywords.UPDATE)
      else:
         db_tools.test_first_run(self.environment)
         self.keywords.SSM = False
         self.keywords.PQS = False
         self.keywords.PISA = False

      # Test to see if acorn is installed on the system
      if os.path.isfile(self.acornEXE) == False and self.keywords.USEACORN:
         sys.stdout.write("WARNING: Acorn was not found in the CCP4 bin directory so it will not be used.\n")
         sys.stdout.write("\n")
      else:
         self.acorn_found = True

      # See if the user has specified 0 for number in Ensemble. If this is the case set USEENSEM to False
      if self.keywords.USEENSEM and (self.keywords.ENSMODNUM == 0 or self.keywords.ENSNUM == 0):
         sys.stdout.write("User has specified 0 for the number of models in the Ensemble or number of Ensembles. This step will not be carried out.\n")
         sys.stdout.write("\n")
         self.keywords.USEENSEM = False

      # If an XML file is required for output
      if self.keywords.XMLOUT:
         sys.stdout.write("MrBUMP job results will be written to the XML file:\n   %s\n" % self.keywords.SUMMARYFILE)
         sys.stdout.write("\n")
      
      if self.keywords.FIXED and "MOLREP" in self.keywords.MR_PROGRAM_LIST:

         # Set the name for the merged PDB file for Molrep
         self.molrep_fixed_PDBfile=os.path.join(self.search_dir, "input", "fixed_xyzin.pdb")

         # Set the log file for pdb_merge
         self.merge_fixed_logfile=os.path.join(self.search_dir, "logs", "pdb_merge.log")

         # Give a bit of output
         sys.stdout.write("Running PDB_merge to join the fixed input PDB files for input to Molrep in MR stage.\n")
         sys.stdout.write("The resulting merged PDB file is stored at:\n  %s\n" % self.molrep_fixed_PDBfile)
         sys.stdout.write("\n")

         # Run pdb_merge to join the fixed input PDB files
         pdb_merge=MRBUMP_pdbmerge.PDB_merge()

         # Add each of the fixed PDB files to the pdb_merge xyzin list
         for i in self.keywords.fixed_list.keys():
            pdb_merge.xyzin.append(self.keywords.fixed_list[i].filename)
  
         pdb_merge.run_multiple(self.molrep_fixed_PDBfile, self.merge_fixed_logfile)

      # Tag this up as SUMMARY content
      sys.stdout.write('<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n')

      # Target sequence information
      sys.stdout.write("###################################\n")
      sys.stdout.write("###      Target Information     ###\n")
      sys.stdout.write("###################################\n")
      sys.stdout.write("\n")

      # Start the target data processing
      #target_info=MRBUMP_target_info.TargetInfo()

      # Set the log file for matthews coef job
      target_info.setMattCoefLogfile(os.path.join(self.search_dir, "logs", "matt_coef.log"))

      # Set the target information
      mstat.InitError = target_info.setTargetInfo(self, self.search_dir)
      target_info.printTargetInfo(self)
 
      # Make a PIR format version of the input sequence file
      self.makePIRfile(target_info.pretty_sequence, os.path.join(self.search_dir, 'input', os.path.splitext(self.seqin_filename)[0] + ".pir"))

      # Update the no. of mols in the a.s.u. if the user has specified a value
      if self.keywords.NMASU != None:
         sys.stdout.write("The estimated number of molecules in the asu is: %d\n" % target_info.no_of_mols)
         sys.stdout.write("The user has specified a value of %d\n" % self.keywords.NMASU) 
         sys.stdout.write("The value will be set to the user defined value\n")
         mstat.setEstNoofMols(target_info.no_of_mols)
         target_info.no_of_mols = self.keywords.NMASU

      if self.ONLYMODELS==False:
         # Use Ctruncate to process the input data - check for NCS, twinning etc.
         sys.stdout.write("Analysing MTZ file with Ctruncate...\n")
         ctr=MRBUMP_ctruncate.Ctruncate()
   
         exetest=ctr.checkEXE()
         if exetest == 1:
            sys.stdout.write("Ctruncate warning: Ctruncate was not found on the system or in the system PATH. Skipping MTZ analysis...\n")
            sys.stdout.write("\n")
         else:
            # Set the log file for Ctruncate
            mstat.setctruncate_logfile(os.path.join(self.search_dir, "logs", "ctruncate.log"))
      
            ctr.setlogfile(mstat.ctruncate_logfile)
            ctr.ctruncate(target_info.hklin, target_info.mtz_coldata["F"], target_info.mtz_coldata["SIGF"])
            
            # Check for successful completion of Ctruncate
            if ctr.termination == False:
               sys.stdout.write("Warning: Ctruncate analysis of MTZ failed to complete correctly\n")
               sys.stdout.write("The log file is available here:\n")
               sys.stdout.write("   %s\n" % mstat.ctruncate_logfile)
               sys.stdout.write("\n")
            else:
               sys.stdout.write("Analysis of MTZ with Ctruncate completed successfully...\n   (Log file: %s)\n" % mstat.ctruncate_logfile)
               sys.stdout.write("\n")
               sys.stdout.write("Here's a summary of its findings:\n")
               sys.stdout.write("\n")
               sys.stdout.write(ctr.summary)
               sys.stdout.write("\n")
   
            # Set the NCS and Twinning detection flags for this data
            target_info.NCS=ctr.NCS
            target_info.TWINNED=ctr.TWIN

      # Setup for acorn and enantiomorphs if they are required
      if self.ONLYMODELS==False:
         self.enant_acorn_setup(target_info, mstat)
   
      # Set the flag for local PDB mirror if this has been specified in the keywords
      if self.keywords.PDBLOCAL != None:
         self.localPDBmirror = True

      # Write out the target processing logfile
      wl=WriteLogfile.Logfile()
      wl.writeTargetLog(self, mstat, target_info)
      target_info.logfile=wl.logfile

      # Close the SUMMARY tag for the input details
      sys.stdout.write('<!--SUMMARY_END--></FONT></B>\n')

      return (mstat, target_info)

   def getFileName(self, arguments, flag, flag_list=[]):
      """ Get the File name for a given flag from the command_line. """

      # Loop over the command line and pick out the filename (accounting for spaces)
      name=[]
      for i in range(len(arguments)):
         if arguments[i].upper() == flag:
            j=i+1
            while j<len(arguments):
               if arguments[j].upper() not in flag_list:
                  name.append(arguments[j])
               else:
                  break
               j=j+1
            flagname=string.joinfields(name, " ")

      # Check to see that the file was found
      if name == []:
         sys.stdout.write("Command line Error: File/directory name not found in command line for file/directory type: %s\n" % flag) 
         sys.stdout.write("                    %s must be specified.\n" % flag) 
         sys.stdout.write("\n") 
         sys.exit(1)

      # Check to see that the file/directory exists (only applies to input files/directories):
      if flag in ["HKLIN", "SEQIN", "PREPDIR"]:
         if os.path.isdir(flagname) == False and os.path.isfile(flagname) == False:
            sys.stdout.write("Command line Error: File/directory specified by %s does not appear to exist.\n" % flag) 
            sys.stdout.write("                    (%s)\n" % flagname) 
            sys.stdout.write("                    Please check that the value for %s is correct in the command line.\n" % flag) 
            sys.stdout.write("\n") 
            sys.exit(1)
            
      sys.stdout.write("Command line argument: %s set to %s\n" % (flag, flagname)) 
      return flagname
   
   def read_cmdline(self, arguments):
      """ A function to read in the command line arguments. """
      
      # Create the command_line string so it can be scanned for relavent details
      command_line=string.joinfields(arguments, " ")

      if self.debug:
         sys.stdout.write("Parsing command line arguments....\n") 
         sys.stdout.write("\n") 
  
      # There are three possibilities for the command line. 1) Full run including MR,
      # 2) Model generation only and 3) MR only

      # Case 1): 
      # mrbump HKLIN <mtz file> SEQIN <seq file> HKLOUT <mtz file> XYZOUT <pdb file>
      if "HKLIN" in command_line.upper() and "SEQIN" in command_line.upper():
 
         self.printHeader()

         sys.stdout.write("Running Model search/preparation and Molecular Replacement mode\n")
         sys.stdout.write("\n")

         # Grab the HKLIN file (account for spaces)
         self.setHKLIN(self.getFileName(arguments, "HKLIN", ["SEQIN", "HKLOUT", "XYZOUT"]))
         # Grab the SEQIN file (account for spaces)
         self.setSEQIN(self.getFileName(arguments, "SEQIN", ["HKLIN", "HKLOUT", "XYZOUT"]))
         # Grab the HKLOUT file (account for spaces)
         self.setHKLOUT(self.getFileName(arguments, "HKLOUT", ["HKLIN", "SEQIN", "XYZOUT"]))
         # Grab the XYZOUT file (account for spaces)
         self.setXYZOUT(self.getFileName(arguments, "XYZOUT", ["HKLIN", "SEQIN", "HKLOUT"]))
 
      # Case 2):
      # e.g. mrbump SEQIN <seq file> 
      elif "SEQIN" in command_line.upper():

         self.printHeader()

         sys.stdout.write("Running Model search/preparation only mode\n")
         sys.stdout.write("\n")

         self.ONLYMODELS=True
         # Grab the SEQIN file (account for spaces)
         self.setSEQIN(self.getFileName(arguments, "SEQIN"))

      # Case 3):
      # e.g. mrbump HKLIN <mtz file> PREPDIR <directory name> HKLOUT <mtz file> XYZOUT <pdb file> 
      elif "HKLIN" in command_line.upper() and "PREPDIR" in command_line.upper(): 

         self.printHeader()

         sys.stdout.write("Running Molecular Replacement only mode\n")
         sys.stdout.write("\n")

         self.MRONLY=True
         # Grab the HKLIN file (account for spaces)
         self.setHKLIN(self.getFileName(arguments, "HKLIN", ["PREPDIR", "HKLOUT", "XYZOUT"]))
         # Grab the PREPDIR file (account for spaces)
         self.setPREPDIR(self.getFileName(arguments, "PREPDIR", ["HKLIN", "HKLOUT", "XYZOUT"]))
         # Grab the HKLOUT file (account for spaces)
         self.setHKLOUT(self.getFileName(arguments, "HKLOUT", ["HKLIN", "PREPDIR", "XYZOUT"]))
         # Grab the XYZOUT file (account for spaces)
         self.setXYZOUT(self.getFileName(arguments, "XYZOUT", ["HKLIN", "PREPDIR", "HKLOUT"]))

      # Case 4):
      # e.g. mrbump XMLIN <xml file>
      elif "XMLIN" in command_line.upper(): 

         self.printHeader()

         sys.stdout.write("Taking input from XML input file\n")
         sys.stdout.write("\n")

         self.XML=True
         # Grab the XMLIN file (account for spaces)
         self.setXMLIN(self.getFileName(arguments, "XMLIN"))
 
      # Case 5):
      elif "-v" in command_line.lower() or "--version" in command_line.lower():

         sys.stdout.write(self.version + "\n")
         sys.exit()

      # Otherwise there is an incorrect command line specified. Echo the usage
      else:
         #sys.stdout.write("Command line Error: The command line appears to be incorrect, please check it\n")
         self.usage()
         sys.exit(1)
      sys.stdout.write("\n")
      
   def read_XMLinput(self):
      """ A function to parse the XML input for job files and parameters """
       
      import MRBUMP_XML_parse 

      # A little output
      sys.stdout.write("Reading input from the XML file:\n  %s\n" % self.xmlin )
      sys.stdout.write("\n")

      # Open a link to the XML input
      inXML=MRBUMP_XML_parse.readXMLInput()
   
      # Read the XML input
      doc=inXML.getDocumentFromFile(name=self.xmlin)
   
      # Get the run options
      inXML.getOptions(doc.getElementsByTagName("MrBUMPJobOptionItem"))
   
      # Get the job input files
      inXML.getJobInputData(doc.getElementsByTagName("MrBUMPJobDataInputItem"))
   
      # Get the job output details
      inXML.getJobOutputData(doc.getElementsByTagName("MrBUMPJobDataOutputItem"))
   
      # Get the job control options
      inXML.getJobControl(doc.getElementsByTagName("MrBUMPJobParamItem"))
   
      if inXML.LABIN:
         # Get the LABIN keywords
         inXML.getLABIN(doc)
      else:
         # Set them to defaults
         inXML.ColLabels["F"] = "F"
         inXML.ColLabels["SIGF"] = "SIGF"
         inXML.ColLabels["FREE"] = "FreeR_flag"
      
      # Set the mrbump variables
      self.setHKLIN(inXML.HKLIN)
      self.setSEQIN(inXML.SEQIN)
      self.setHKLOUT(inXML.HKLOUT)
      self.setXYZOUT(inXML.XYZOUT)
      self.MRONLY = inXML.MODELONLY

      self.keywords.JOBID = inXML.JobID
      self.keywords.DEBUG = inXML.DEBUG
      self.keywords.ROOTDIR = inXML.OUTDIR
      self.keywords.col_labels["F"] = inXML.ColLabels["F"]
      self.keywords.col_labels["SIGF"] = inXML.ColLabels["SIGF"]
      self.keywords.col_labels["FREER_FLAG"] = inXML.ColLabels["FREE"]
      self.keywords.labin_found = True
      self.keywords.XMLOUT = True

      self.keywords.LOGFILE=inXML.LOG
      self.keywords.SUMMARYFILE=inXML.SUMMARY

      # Output the details to stdout
      sys.stdout.write("Input files:\n")
      sys.stdout.write("--> HKLIN: %s\n" % self.hklin)
      sys.stdout.write("--> SEQIN: %s\n" % self.seqin)
      sys.stdout.write("--> HKLOUT: %s\n" % self.hklout)
      sys.stdout.write("--> XYZOUT: %s\n" % self.xyzout)
      sys.stdout.write("\n")
      sys.stdout.write("Input parameters:\n")
      if self.MRONLY:
         sys.stdout.write("--> Job Type: Models Only\n")
      else:
         sys.stdout.write("--> Job Type: Full Model generation and Molecular Replacement\n")
      sys.stdout.write("--> Job ID: %s\n" % self.keywords.JOBID)
      sys.stdout.write("--> Debug set to: %s\n" % self.keywords.DEBUG)
      sys.stdout.write("--> ROOT directory: %s\n" % self.keywords.ROOTDIR)
      sys.stdout.write("--> Log file: %s\n" % self.keywords.LOGFILE)
      sys.stdout.write("--> Summary file: %s\n" % self.keywords.SUMMARYFILE)
      sys.stdout.write("--> Column Label 'F'         : %s\n" % self.keywords.col_labels["F"])
      sys.stdout.write("--> Column Label 'SIGF'      : %s\n" % self.keywords.col_labels["SIGF"])
      sys.stdout.write("--> Column Label 'FREER_FLAG': %s\n" % self.keywords.col_labels["FREER_FLAG"])
      sys.stdout.write("\n")


   def make_job_dir(self):
      """ A function to create the directory three for the MRBUMP job. """

      # Set the results directory
      self.setResults_DIR(os.path.join(self.search_dir, 'results'))

      # Set the name of the best logfile 
      self.setResults_Logfile(os.path.join(self.results_dir, "results.txt"))

      # Also set the results.html file location
      if self.keywords.results_html == "":
         self.setResults_HTML(os.path.join(self.results_dir, 'results.html'))
         self.setResults_HTML_Filename('results.html')
         self.setRelative_Link("")
      else:
         self.setResults_HTML(self.keywords.results_html)
         if os.name == 'nt':
            # Set results html filename under windows
            self.setResults_HTML_Filename((os.path.split(self.keywords.results_html))[-1])
            self.setRelative_Link(self.results_dir + "\\")
         else:
            # Set results html filename under non-windows OS
            self.setResults_HTML_Filename((os.path.split(self.keywords.results_html))[-1])
            self.setRelative_Link(self.results_dir + "/")

      # Set the scratch directory
      self.setScratch_DIR(os.path.join(self.search_dir, 'scratch'))

      # Setup the directory structure
      if os.path.isdir(self.search_dir):
         sys.stdout.write("\n")
         sys.stdout.write("A directory for a job with this name already exists:\n " \
            + self.search_dir + "\n")
         sys.stdout.write("Please delete it or choose a different job name\n")
         sys.stdout.write("\n")
         sys.exit(1)
    
      # If we are running an MR ONLY job we can just copy the preparation directory
      if self.MRONLY:
         shutil.copytree(self.PREPDIR, self.search_dir)
      
      # Otherwise, create all of the necessary folders
      else:
         os.mkdir(self.search_dir)
         os.mkdir(os.path.join(self.search_dir, 'input'))
         os.mkdir(os.path.join(self.search_dir, 'logs'))
         os.mkdir(os.path.join(self.search_dir, 'scratch'))
         os.mkdir(os.path.join(self.search_dir, 'data'))
         os.mkdir(os.path.join(self.search_dir, 'sequences'))
         os.mkdir(os.path.join(self.search_dir, 'PDB_files'))

         # Create the results directory and all of its subfolders
         if not os.path.isdir(self.results_dir):
            os.mkdir(self.results_dir)
         os.mkdir(os.path.join(self.results_dir, 'images'))
         os.mkdir(os.path.join(self.results_dir, 'data'))
         os.mkdir(os.path.join(self.results_dir, 'data', 'sequences'))
         os.mkdir(os.path.join(self.results_dir, 'pdb_files'))
         os.mkdir(os.path.join(self.results_dir, 'log_files'))
         os.mkdir(os.path.join(self.results_dir, 'marginal_solns'))

   def enant_acorn_setup(self, target_info, mstat): 

      # Initialise the refinement HKLIN file to the input HKLIN
      target_info.refinement_hklin=os.path.join(self.search_dir, "input", "refinement_HKLIN.mtz")
      shutil.copyfile(target_info.hklin, target_info.refinement_hklin)
      # Make sure we have write permissions on this file
      os.chmod(target_info.refinement_hklin, 00660)

      # Generate the MTZ in enantiomorphic spacegroup if enantiomorph has been detected
      if self.keywords.ENANT:
         reindex=MRBUMP_reindex.Reindex()
     
         # Search information
         sys.stdout.write("\n")
         sys.stdout.write("###################################################\n")
         sys.stdout.write("###   Reindex the target MTZ for enantiomorph   ###\n")
         sys.stdout.write("###################################################\n")
         sys.stdout.write("\n")
   
         # Check to see if an enantiomorph actually exists for the target data spacegroup
         reindex.find_spacegroup_id(target_info.space_group)

         if reindex.enant_found == False:
            self.keywords.ENANT=False
         else:
            self.keywords.ENANT=True

            # Set the reindexed MTZ file name and pointer
            target_info.enant_hklin=os.path.join(self.search_dir, "input", self.keywords.JOBID + "_enant.mtz")

            # Set the enantiomorphic spacegroup ID
            target_info.enant_spacegroup=reindex.spacegroup_ID
            target_info.enant_SG_code=target_info.SG_Codes[target_info.enant_spacegroup]

            # Set the reindex logfile
            mstat.reindex_logfile=os.path.join(self.search_dir, "logs", "reindex.log")

            # Set the keywords for the reindexing
            reindex.add_keyword("SYMMETRY %s" % reindex.spacegroup_ID)
            reindex.add_keyword("REINDEX HKL h,k,l")
            reindex.add_keyword("NOREDUCE")
            reindex.add_keyword("END")

            # Run reindex to generate the reindexed MTZ
            reindex.run(target_info.hklin, target_info.enant_hklin, mstat.reindex_logfile)  

      # Setup the Acorn input MTZ if it is to be used
      if self.acorn_found and self.keywords.USEACORN:

         # Search information
         sys.stdout.write("\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("###  Prepare the input MTZ file for use in Acorn  ###\n")
         sys.stdout.write("#####################################################\n")
         sys.stdout.write("\n")

         phase_imp=Phase_improve.PhaseImprove()
                 
         # Set the Column labels for E and SIGE
         target_info.mtz_coldata["E"]        = "E"
         target_info.mtz_coldata["SIGE"]     = "SIGE"
         target_info.mtz_coldata["F_ISO"]    = target_info.mtz_coldata["F"] + "_ISO"
         target_info.mtz_coldata["SIGF_ISO"] = target_info.mtz_coldata["SIGF"] + "_ISO"

         # Set the various file names
         target_info.unique_MTZOUTfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_unique_out.mtz") 
         target_info.unique_logfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_unique.log") 

         target_info.aniso_MTZOUTfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_aniso_out.mtz") 
         target_info.aniso_logfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_aniso.log") 
            
         target_info.cad_MTZOUTfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_cad_out.mtz") 
         target_info.cad_logfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_cad.log") 

         target_info.ecalc_logfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_ecalc.log") 
         target_info.target_ecalc_MTZOUTfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_target_ecalc_out.mtz") 
         if self.keywords.ENANT:
            target_info.enant_ecalc_MTZOUTfile = os.path.join(self.search_dir, "input", self.keywords.JOBID + "_enant_ecalc_out.mtz") 
            
         # Extend the resolution of the target data set and create normalised structure factor amplitudes
         if self.debug:
            sys.stdout.write("Prep Log: Extend resolution and create normalised structure factor amplitudes\n")
            sys.stdout.write("\n")
      
         # Generate the input MTZ file for acorn (target)
         sys.stdout.write("Prep Log: Preparing the input MTZ file for Acorn using target spacegroup...\n")
         sys.stdout.write("\n")
   
         phase_imp.setEcalcMTZOUTfile(target_info.target_ecalc_MTZOUTfile)    
         phase_imp.prepare(target_info.hklin, target_info.space_group, self, mstat, target_info)

         # Generate the input MTZ file for acorn (enantiomorph)
         if self.keywords.ENANT:
            sys.stdout.write("Prep Log: Preparing the input MTZ file for Acorn using enantiomorphic spacegroup...\n")
            sys.stdout.write("\n")
   
            phase_imp.setEcalcMTZOUTfile(target_info.enant_ecalc_MTZOUTfile)    
            phase_imp.prepare(target_info.enant_hklin, target_info.enant_spacegroup, self, mstat, target_info)

   def checkPhaserVersion(self):
      """ Check which version of Phaser we are using. If it is later than 2.2.4 we need to use the new keyword set up """

      # Set the phaser executable
      if os.name == "nt":
         phaserEXE = os.path.join(os.environ["CCP4"], "bin",
                                     "phaser.exe")
      else:
         phaserEXE = os.path.join(os.environ["CCP4"], "bin",
                                     "phaser")

      # First check to see that phaser exists, if not exit with error message
      if os.path.isfile(phaserEXE) == False:
         sys.stderr.write("Dependency error: Phaser executable not found in CCP4 distribution:\n " + phaserEXE + "\n")
         sys.exit(-1)

      # Set the command line
      command_line = str(phaserEXE)

      # Launch phaser
      if os.name=="nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.write("END\n")
      child_stdin.close()

      o=child_stdout.readline()
      version="2.5.0"
      while o:
         if "CCP4 PROGRAM SUITE" in o.upper() and "Phaser" in o:
            version=string.split(o.replace("#",""))[-1]
         o = child_stdout.readline()

      # Convert to an integer value
      if len(string.split(version, ".")) == 3: 
         self.phaserVersion=int(string.join(string.split(version, ".")).replace(" ",""))
      elif len(string.split(version, ".")) == 2: 
         self.phaserVersion=int(string.join(string.split(version, ".")).replace(" ","") + "0")
      else:
         self.phaserVersion=224

   def checkMolrepVersion(self):
      """ Check which version of Molrep we are using. If it is later than 11.0.0 we need to parse the new log file """

      # Set the molrep executable
      if os.name == "nt":
         molrepEXE = os.path.join(os.environ["CCP4"], "bin",
                                     "molrep.exe")
      else:
         molrepEXE = os.path.join(os.environ["CCP4"], "bin",
                                     "molrep")

      # First check to see that molrep exists, if not exit with error message
      if os.path.isfile(molrepEXE) == False:
         sys.stderr.write("Dependency error: Molrep executable not found in CCP4 distribution:\n " + molrepEXE + "\n")
         sys.exit(-1)

      # Set the command line
      command_line = str(molrepEXE)

      # Change to the CCP4_SCR for molrep test run
      currDir=os.getcwd()
      os.chdir(os.environ["CCP4_SCR"])

      # Launch molrep
      if os.name=="nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.write("END\n")
      child_stdin.close()

      o=child_stdout.readline()
      while o:
         if "/Vers" in o and "|" in o:
            version=o.split("/Vers")[1].split(";")[0].strip()
         o = child_stdout.readline()

      # Convert to a float value
      if len(string.split(version, ".")) == 3: 
         self.molrepVersion = float(string.split(version, ".")[0] + "." + string.split(version,".")[1] + string.split(version, ".")[2])
      elif len(string.split(version, ".")) == 2: 
         self.molrepVersion = float(string.split(version, ".")[0] + "." + string.split(version,".")[1])
      else:
         self.molrepVersion=11.0

      os.chdir(currDir)

   def usage(self):
      """ Echo the usage """

      sys.stdout.write("\n")
      sys.stdout.write("Usage:\n")
      sys.stdout.write("Full Model generation and MR:\n  mrbump HKLIN foo_in.mtz SEQIN foo.seq HKLOUT foo_out.mtz XYZOUT foo.pdb\n")
      sys.stdout.write("Model generation only:\n  mrbump SEQIN foo.seq\n")
      sys.stdout.write("Molecular Replacement only:\n")
      sys.stdout.write("  mrbump HKLIN foo_in.mtz PREPDIR <directory from earlier MrBUMP> HKLOUT foo_out.mtz XYZOUT foo.pdb\n")
      sys.stdout.write("XML input:\n  mrbump XMLIN foo_in.xml\n")
      sys.stdout.write("Version information:\n  -v or --version\n")
      sys.stdout.write("\n")

   def makePIRfile(self, sequence, seqout):
      """ Create a pir formatted version of the input sequence file """

      # Create the sequence pir file
      f=open(seqout,"w")
      f.write(">PIR format\n\n")
      f.write(sequence + "\n")
      f.close

      # Set the initialiser names
      self.pirin=seqout
      self.pirin_filename=os.path.split(seqout)[1]
      
class PDB_download_site:

   def __init__(self):
      self.name=""
      self.url=""
      self.rank=0
      self.type=""
      self.con_time=10000.0
    

if __name__ == '__main__':
 
   init=Initialise()
   init.mrbump_initialisation()
   sys.stdout.write(init.keywords.E_value + "\n")
 
