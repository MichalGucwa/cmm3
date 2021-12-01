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
# Code to handle the keyword input to MRBUMP
# Ronan Keegan 12.10.05

import string
import sys
import os
import mol_weight

class Keywords:
   """ A class to read the keywords for MRBUMP from the stdin or input from a file. """

   def __init__(self):
      self.col_labels=dict([])
      self.JOBID=''
      self.parent_JOBID=''

      self.ROOTDIR = os.getcwd() 
      self.LOGFILE = "" 
      self.SUMMARYFILE = "" 

      self.PDBDIR = ""
      self.NOVODIR = ""
      self.PDBLOCAL = None
   
      self.NMASU=None
      self.PACK=5
      self.PJOBS=2
      self.PRMSD=1.2
      self.KPHASER=False
      self.KTIME=600.0

      self.FIXSG=False
      self.NCYC=30
      self.RBNC=5
      self.REFTWIN=False
      self.PIRCYC=3
      self.RBODREF=False
      self.JBODREF=True

      self.MRNUM = 10
      self.ENSMODNUM = 5
      self.ENSNUM = 1
      self.USEENSEM = True
 
      self.E_value = 0.02

      self.MR_PROGRAM_LIST = ['MOLREP', 'PHASER']
      self.MAPROGRAM = 'MAFFT'
      
      self.SSM = False
      self.SCOP = True 
      self.PQS = True 
      self.PISA = False

      self.MDLUNMOD = False 
      self.MDLDPDBCLP = False 
      self.MDLPLYALA = False 
      self.MDLMOLREP = True 
      self.MDLCHAINSAW = True 
      self.MDLSCULPTOR = True 

      self.DEBUG = False
      self.CLUSTER = False
      self.QTYPE = "SGE"
      self.QSIZE = sys.maxint
      self.PROXYSERVER = ""

      self.QSUBCOM = "qsub"

      self.fasta_local = True
      self.run_local   = False

      self.UPDATE = True
      self.DOFASTA = True
      self.DOHHPRED = False
      self.HHDBPDB = ""
      self.HHSCORE = False
      self.TRYALL = False
      self.CLEAN = False
      self.LITE = False
      self.CHECK = False

      self.HTMLOUT = False
      self.XMLOUT = False
      self.results_html =  ''

      self.ignore_list = []
      self.include_list = []
      self.local_list = dict([])
      self.locfile_count = 0
      self.error_string = ''

      self.labin_found = False
      self.jobid_found = False

      self.USEACORN = False
      self.ACORNRES = 1.7

      self.BUCCANEER = False
      self.BCYCLES = 5

      self.ARPWARP = False
      self.ACYCLES = 5

      self.SHELXE = False
      self.SHLXEXE = "shelxe"
      self.SCYCLES = 15

      self.USECPIRATE = False

      self.ENANT = False
      self.SGALL = False
      self.DUMMY = False
      self.PICKLE = True

      self.DBOUT = False
      self.DBVIEW = False

      self.fixed_list = dict([])
      self.fixedfile_count = 0
      self.FIXED = False

      self.PKEYWORD=[]
      self.MKEYWORD=[]
      self.RKEYWORD=[]

   def setErrorString(self, error_string):
      self.error_string = error_string

   def read_keywords(self):
      """ A function to read in the keyword arguments from the STDIN or from a file. """

      print "ENTER KEYWORD INPUT FROM FILE OR FROM STANDARD INPUT"

      while True:
         data_line = string.strip(raw_input("-->\n"))
         if data_line == '':
           keyword = "NULL"
         else:
           keyword = string.split(data_line)[0]

         if "LABI" in keyword[0:4].upper():
            self.parse_LABIN(data_line)
            self.labin_found = True
    
         elif "JOBI" in keyword[0:4].upper():
            self.parse_JOBID(data_line)
            self.jobid_found = True
            
         elif "ROOT" in keyword[0:4].upper():
            self.parse_ROOTDIR(data_line)

         elif "PDBD" in keyword[0:4].upper():
            self.parse_PDBDIR(data_line)

         elif "HHDB" in keyword[0:4].upper():
            self.parse_HHDBPDB(data_line)

         elif "NOVO" in keyword[0:4].upper():
            self.parse_NOVODIR(data_line)

         elif "PKEY" in keyword[0:4].upper():
            self.parse_PKEYWORD(data_line)

         elif "MKEY" in keyword[0:4].upper():
            self.parse_MKEYWORD(data_line)

         elif "RKEY" in keyword[0:4].upper():
            self.parse_RKEYWORD(data_line)

         elif "PDBL" in keyword[0:4].upper():
            self.parse_PDBLOCAL(data_line)

         elif "IGNO" in keyword[0:4].upper():
            self.parse_IGNORE(data_line)

         elif "INCL" in keyword[0:4].upper():
            self.parse_INCLUDE(data_line)

         elif "LOCA" in keyword[0:4].upper():
            self.parse_LOCALFILE(data_line)

         elif "NMAS" in keyword[0:4].upper():
            self.parse_NMASU(data_line)

         elif "PACK" in keyword[0:4].upper():
            self.parse_PACK(data_line)

         elif "PRMS" in keyword[0:4].upper():
            self.parse_PRMS(data_line)

         elif "PJOB" in keyword[0:4].upper():
            self.parse_PJOBS(data_line)

         elif "NCYC" in keyword[0:4].upper():
            self.parse_NCYC(data_line)

         elif "BCYC" in keyword[0:4].upper():
            self.parse_BCYCLES(data_line)

         elif "ACYC" in keyword[0:4].upper():
            self.parse_ACYCLES(data_line)

         elif "SCYC" in keyword[0:4].upper():
            self.parse_SCYCLES(data_line)

         elif "RBNC" in keyword[0:4].upper():
            self.parse_RBNC(data_line)

         elif "PIRC" in keyword[0:4].upper():
            self.parse_PIRCYC(data_line)

         elif "RBOD" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'RBODREF')

         elif "JBOD" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'JBODREF')

         elif "MRNU" in keyword[0:4].upper():
            self.parse_MRNUM(data_line)

         elif "ENSN" in keyword[0:4].upper():
            self.parse_ENSNUM(data_line)

         elif "ENSM" in keyword[0:4].upper() or "ENSE" in keyword[0:4].upper():
            self.parse_ENSMODNUM(data_line)

         elif "EVAL" in keyword[0:4].upper():
            self.parse_EVALUE(data_line)

         elif "KTIM" in keyword[0:4].upper():
            self.parse_KTIME(data_line)

         elif "MRPR" in keyword[0:4].upper():
            self.parse_MRPROGRAMS(data_line)

         elif "MAPR" in keyword[0:4].upper():
            self.parse_MAPROGRAM(data_line)

         elif "QTYP" in keyword[0:4].upper():
            self.parse_QTYPE(data_line)

         elif "QSIZ" in keyword[0:4].upper():
            self.parse_QSIZE(data_line)

         elif "QSUB" in keyword[0:4].upper():
            self.parse_QSUBCOM(data_line)

         elif "PROX" in keyword[0:4].upper():
            self.parse_PROXYSERVER(data_line)

         elif "LOGF" in keyword[0:4].upper():
            self.parse_LOGFILE(data_line)

         elif "SUMM" in keyword[0:4].upper():
            self.parse_SUMMARYFILE(data_line)

         elif "MDLU" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLUNMOD')

         elif "MDLD" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLDPDBCLP')

         elif "MDLP" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLPLYALA')

         elif "MDLM" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLMOLREP')

         elif "MDLC" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLCHAINSAW')

         elif "MDLS" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'MDLSCULPTOR')

         elif "DEBU" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DEBUG')

         elif "CLUS" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'CLUSTER')

         elif "SSMS" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'SSMSEARCH')

         elif "SCOP" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'SCOPSEARCH')

         elif "PQSS" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'PQSSEARCH')

         elif "PISA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'PISASEARCH')

         elif "PWAL" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'PWALIGN')

         elif "FAST" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'FASTALOCAL')

         elif "RUNL" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'RUNLOCAL')
      
         elif "UPDA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'UPDATE')
      
         elif "DOFA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DOFASTA')
      
         elif "DOHH" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DOHHPRED')
      
         elif "HHSC" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'HHSCORE')
      
         elif "TRYA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'TRYALL')
      
         elif "CLEA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'CLEAN')
      
         elif "LITE" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'LITE')
      
         elif "HTML" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'HTMLOUT')
      
         elif "RESH" in keyword[0:4].upper():
            self.parse_RESHTML(data_line)

         elif "USEA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'USEACORN')
      
         elif "ACOR" in keyword[0:4].upper():
            self.parse_ACORNRES(data_line)

         elif "BUCC" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'BUCCANEER')
      
         elif "ARPW" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'ARPWARP')
      
         elif "SHEL" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'SHELXE')
      
         elif "SHLX" in keyword[0:4].upper():
            self.parse_SHLXEXE(data_line)

         elif "USEC" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'USECPIRATE')
      
         elif "USEE" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'USEENSEM')
      
         elif "CHEC" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'CHECK')
      
         elif "ENAN" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'ENANT')
      
         elif "SGAL" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'SGALL')
      
         elif "DUMM" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DUMMY')
      
         elif "PICK" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'PICKLE')
      
         elif "DBOU" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DBOUT')
      
         elif "DBVI" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'DBVIEW')
      
         elif "REFT" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'REFTWIN')

         elif "FIXE" in keyword[0:4].upper():
            self.parse_FIXED_XYZIN(data_line)

         elif "FIXS" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'FIXSG')

         elif "KPHA" in keyword[0:4].upper():
            self.parse_FLAG(data_line, 'KPHASER')

         elif "NULL" in keyword.upper():
            print "Please enter a keyword or type END to finish keyword entry"
      
         elif "END" in keyword.upper():
            break
       
         else:
            print "Ignoring unrecognised keyword: %s" % keyword 
            
      # Verify the 'NUM_' keywords are correct
      self.verify_NUM()

      # Check that chains have been specified if DOFASTA and DOHHPRED are set to False
      if self.DOFASTA == False and self.DOHHPRED == False and self.include_list == [] and len(self.local_list.keys()) == 0:
         self.keyword_usage('DOFASTA', \
            'If DOFASTA and DOHHPRED are set to false you need to specify chains ' \
          + 'to be used as template models using the INCLUDE or LOCALFILE keywords' , 19)

      # Check to see that HHDBPDB has been set if DOHHPRED is set to True:
      if self.DOHHPRED and self.HHDBPDB == "":
         self.keyword_usage('DOHHPRED', \
            "If DOHHPRED is set to True you must specify the location of the HHpred " \
          + "pdb sequence database in the interface or using the HHDBPDB keyword", 19) 

      # Check to see that HHLIB variable has been set if DOHHPRED is set to True:
      if self.DOHHPRED and os.environ.has_key("HHLIB") == False:
         self.keyword_usage('DOHHPRED', \
            "If DOHHPRED is set to True you must specify the HHLIB variable in your " \
          + "system environment", 19) 

      # Check that the JOBID keyword hs abeen provided. All others are optional.
      if self.jobid_found == False:
         self.keyword_usage('jobid', 'JOBID keyword not provided', 12)

   def parse_JOBID(self, data_line):
      """ A function to parse the JOBID keyword. """
      
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: JOBID requires an argument"
      else:
         self.JOBID=string.split(data_line)[1]
      
         print "Job identifier: %s" % self.JOBID

   def parse_ROOTDIR(self, data_line):
      """ A function to parse the ROOT keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: ROOTDIR requires an argument"
      else:
         self.ROOTDIR=string.join(string.split(data_line)[1:], " ")
   
         # Test directory existence
         if os.path.isdir(self.ROOTDIR) == False:
            self.keyword_usage('root_dir', '%s does not exist' % self.ROOTDIR, 15)
      
         print "Root directory: %s" % self.ROOTDIR

   def parse_PDBDIR(self, data_line):
      """ A function to parse the keyword PDBDIR. PDBDIR is a directory specified by
          the user that holds PDB files for use in MRBUMP. This can help reduce the
          need for downloads from the web. PDB files should take the format:
             <PDB ID>.pdb   (e.g. 1nio.pdb) """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PDBDIR requires an argument"
      else:
         self.PDBDIR=string.join(string.split(data_line)[1:], " ")
        
         # Test directory existence
         if os.path.isdir(self.PDBDIR) == False:
            sys.stdout.write("Keyword Warning: The PDBDIR was not found:\n  %s\n" % self.PDBDIR)
         else:
            sys.stdout.write("Input PDB files directory: %s\n" % self.PDBDIR)
         sys.stdout.write("\n")

   def parse_HHDBPDB(self, data_line):
      """ A function to parse the keyword HHDBPDB. HHDBPDB is the HHpred PDB sequence database
          """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: HHDBPDB requires an argument"
      else:
         self.HHDBPDB=string.join(string.split(data_line)[1:], " ")
        
         # Test directory existence
        # if os.path.isdir(self.HHDBPDB) == False:
        #    sys.stdout.write("Keyword Warning: The HHDBPDB was not found:\n  %s\n" % self.HHDBPDB)
        # else:
         sys.stdout.write("HHpred PDB database: %s\n" % self.HHDBPDB)
         sys.stdout.write("\n")

   def parse_PKEYWORD(self, data_line):
      """ A function to parse the Phaser keyword input """

      if len(string.split(data_line)) == 1: 
         sys.stdout.write("Keyword entry error: PKEYWORD requires an argument\n")
      else: 
         self.PKEYWORD.append(" ".join(string.split(data_line)[1:]))
         sys.stdout.write("Added keyword line '%s' to Phaser keywords\n" % " ".join(string.split(data_line)[1:]))

   def parse_MKEYWORD(self, data_line):
      """ A function to parse the Molrep keyword input """

      if len(string.split(data_line)) == 1: 
         sys.stdout.write("Keyword entry error: MKEYWORD requires an argument\n")
      else: 
         self.MKEYWORD.append(" ".join(string.split(data_line)[1:]))
         sys.stdout.write("Added keyword line '%s' to Molrep keywords\n" % " ".join(string.split(data_line)[1:]))

   def parse_RKEYWORD(self, data_line):
      """ A function to parse the Refmac keyword input """

      if len(string.split(data_line)) == 1: 
         sys.stdout.write("Keyword entry error: RKEYWORD requires an argument\n")
      else: 
         self.RKEYWORD.append(" ".join(string.split(data_line)[1:]))
         sys.stdout.write("Added keyword line '%s' to Refmac keywords\n" % " ".join(string.split(data_line)[1:]))

   def parse_NOVODIR(self, data_line):
      """ A function to parse the keyword NOVODIR. NOVODIR is a directory specified by
          the user that holds PDB files for use in MRBUMP when using ab initio models
          for molecular replacement. 
          PDB files should take the format:
             <filename>.pdb """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: NOVODIR requires an argument"
      else:
         self.NOVODIR=string.join(string.split(data_line)[1:], " ")
        
         # Test directory existence
         if os.path.isdir(self.NOVODIR) == False:
            sys.stdout.write("Keyword Warning: The NOVODIR directory was not found:\n  %s\n" % self.NOVODIR)
         else:
            sys.stdout.write("Input ab initio PDB files directory: %s\n" % self.NOVODIR)
         sys.stdout.write("\n")

         fileList=[]
         pdbFileList=[]
         # Get the list of files from the directory
         fileList=os.listdir(self.NOVODIR)
         if fileList == []: 
            sys.stdout.write("Keyword Error: The directory NOVODIR is empty!\n  %s\n" % self.NOVODIR)
            sys.exit()
         for file in fileList:
            if file.split(".")[-1] == "pdb":
               pdbFileList.append(os.path.join(self.NOVODIR, file))
         if pdbFileList == []:
            sys.stdout.write("Keyword Error: The directory NOVODIR does not appear to contain any PDB files!\n  (%s)\n" % self.NOVODIR)
            sys.exit()
         else:
            abiPDBcount=len(pdbFileList)

         # Set up a LocalPDB class for each of the PDB files in the directory
         for file in pdbFileList:
            lpdb=LocalPDB()
            lpdb.filename=file
            lpdb.filestring=os.path.splitext(os.path.split(lpdb.filename)[1])[0].replace(".", "_")
            lpdb.chainID="A"
            lpdb.rms=0.0
            #lpdb.name=(os.path.split(file)[-1]).replace(".pdb","").replace(".","_")
            lpdb.number=self.locfile_count

            # Add this local file class to the local_list dictionary
            #self.local_list["loc" + `self.locfile_count` + "_" + lpdb.name + "_" + chainID + "_" + lpdb.filestring] = lpdb
            self.local_list["loc" + `self.locfile_count` + "_" + lpdb.chainID + "_" + lpdb.filestring] = lpdb
            self.locfile_count = self.locfile_count + 1
      
            # Echo the details to the stdout
            sys.stdout.write("Chain from local file (de novo) to include as a search model:\n")
            if lpdb.rms==0.0:
               sys.stdout.write("Chain ID: %s -- Filename: %s\n" % (lpdb.chainID, lpdb.filename)) 
            else:
               sys.stdout.write("Chain ID: %s (RMS=%.2f) -- Filename: %s\n" % (lpdb.chainID, lpdb.rms, lpdb.filename)) 


   def parse_PDBLOCAL(self, data_line):
      """ A function to parse the keyword PDBLOCAL. PDBLOCAL specifies a local mirror of the
          PDB. The mirror must have the files stored under directories specified by the 
          middle two characters in the PDB id. The files must also be zipped and of the 
          format pdb1nio.ent.gz """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PDBLOCAL requires an argument (directory path)"
      else:
         self.PDBLOCAL=string.join(string.split(data_line)[1:], " ")
        
         # Test directory existence
         if os.path.isdir(self.PDBLOCAL) == False:
            sys.stdout.write("Keyword Error: PDBLOCAL directory was not found:\n  %s\n" % self.PDBLOCAL)
            sys.stdout.write("               This should be the path to the local PDB Mirror\n")
            sys.stdout.write("               Remove this keyword if you do not have a local PDB Mirror\n")
            sys.stdout.write("\n")
            sys.exit(1)
         # Do a couple of tests to see if it is in the correct format
         elif os.path.isdir(os.path.join(self.PDBLOCAL, "ni")) == False:
            sys.stdout.write("Keyword Error: PDBLOCAL directory does not have the standard PDB Mirror format\n")
            sys.stdout.write("               It should have files stored under subdirectories denoted by the\n")
            sys.stdout.write("               middle two characters of the PDB codes stored therin\n")
            sys.stdout.write("               e.g. file pdb1nio.ent.gz should be stored in directory 'ni' (dir)\n")
            sys.stdout.write("\n")
            sys.exit(1)
         elif os.path.isfile(os.path.join(self.PDBLOCAL, "ni", "pdb1nio.ent.gz")) == False:
            sys.stdout.write("Keyword Error: PDBLOCAL directory does not have the standard PDB Mirror format\n")
            sys.stdout.write("               It should have files stored under subdirectories denoted by the\n")
            sys.stdout.write("               middle two characters of the PDB codes stored therin\n")
            sys.stdout.write("               e.g. file pdb1nio.ent.gz should be stored in directory 'ni' (file)\n")
            sys.stdout.write("\n")
            sys.exit(1)
         else:
            sys.stdout.write("Local PDB Mirror directory: %s\n" % self.PDBLOCAL)
         sys.stdout.write("\n")

   def parse_RESHTML(self, data_line):
      """ A function to parse the RESHTML keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: RESHTML requires an argument"
      else:
         self.results_html=string.split(data_line)[1]
   
         print "If Results in HTML required the file will be written to: %s" % self.results_html

   def parse_NMASU(self, data_line):
      """ A function to parse the NMASU keyword. """

      if len(string.split(data_line)) == 1:
         print "No value given for NMASU. Number of molecules will be calculated automatically"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.NMASU=int(value)
         else:
            self.keyword_usage('NMASU', "'%s' is not a valid value for NMASU, must be integer" % value, 4)

         print "Number of molecules in the asu: %d" % self.NMASU

   def parse_PACK(self, data_line):
      """ A function to parse the PACK keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PACK requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.PACK=int(value)
         else:
            self.keyword_usage('PACK', "'%s' is not a valid value for PACK, must be integer" % value, 4)

         print "Number of clashes tolerated in Phaser: %d" % self.PACK

   def parse_PRMS(self, data_line):
      """ A function to parse the PRMS keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PRMS requires an argument"
      else:
         value=string.split(data_line)[1]  
 
         try:
            self.PRMS=float(value)
         except:
            self.keyword_usage('PRMS', "'%s' is not a valid value for PRMS, must be float" % value, 7)
      
         print "RMSD value for models set to: %.3f" % self.PRMS

   def parse_PJOBS(self, data_line):
      """ A function to parse the PJOBS keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PJOBS requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.PJOBS=int(value)
         else:
            self.keyword_usage('PJOBS', "'%s' is not a valid value for PJOBS, must be integer" % value, 4)

         print "Number of cores to be used by Phaser: %d" % self.PJOBS

   def parse_RBNC(self, data_line):
      """ A function to parse the RBNC keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: RBNC requires an argument"
      else:
         value = string.split(data_line)[1]
   
         if value.isdigit():
            self.RBNC=int(value)
         else:
	    self.keyword_usage('RBNC', "'%s' is not a valid value for RBNC, must be integer" % value, 4)

         print "Number of cycles of restrained refinement to use in Refmac = %d" % self.RBNC


   def parse_NCYC(self, data_line):
      """ A function to parse the NCYC keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: NCYC requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.NCYC=int(value)
         else:
            self.keyword_usage('NCYC', "'%s' is not a valid value for NCYC, must be integer" % value, 4)

         print "Number of cycles of restrained refinement to use in Refmac = %d" % self.NCYC

   def parse_BCYCLES(self, data_line):
      """ A function to parse the BCYCLES keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: BCYCLES requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.BCYCLES=int(value)
         else:
            self.keyword_usage('BCYCLES', "'%s' is not a valid value for BCYCLES, must be integer" % value, 4)

         print "Number of cycles of model building in Buccaneer = %d" % self.BCYCLES

   def parse_ACYCLES(self, data_line):
      """ A function to parse the ACYCLES keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: ACYCLES requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.ACYCLES=int(value)
         else:
            self.keyword_usage('ACYCLES', "'%s' is not a valid value for ACYCLES, must be integer" % value, 4)

         print "Number of cycles of model building in ARP/wARP = %d" % self.ACYCLES

   def parse_SCYCLES(self, data_line):
      """ A function to parse the SCYCLES keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: SCYCLES requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.SCYCLES=int(value)
         else:
            self.keyword_usage('SCYCLES', "'%s' is not a valid value for SCYCLES, must be integer" % value, 4)

         print "Number of cycles of auto-tracing in Shelxe = %d" % self.SCYCLES

   def parse_PIRCYC(self, data_line):
      """ A function to parse the PIRCYC keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PIRCYC requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.PIRCYC=int(value)
         else:
            self.keyword_usage('PIRCYC', "'%s' is not a valid value for PIRCYC, must be integer" % value, 4)

         print "Number of cycles of phase improvement in Cpirate = %d" % self.PIRCYC

   def parse_MRNUM(self, data_line):
      """ A function to parse the MRNUM keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: MRNUM requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.MRNUM=int(value)
         else:
            self.keyword_usage('MRNUM', "'%s' is not a valid value for MRNUM, must be integer" % value, 5)
      
         print "Number of search models to use in MR: %d" % self.MRNUM

   def parse_ENSNUM(self, data_line):
      """ A function to parse the ENSNUM keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: ENSNUM requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.ENSNUM=int(value)
         else:
            self.keyword_usage('ENSNUM', "'%s' is not a valid value for ENSNUM, must be integer" % value, 6)
      
         print "Number of ensembles processed by phaser: %d" % self.ENSNUM

   def parse_ENSMODNUM(self, data_line):
      """ A function to parse the ENSMODNUM keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: ENSMODNUM requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit():
            self.ENSMODNUM=int(value)
         else:
            self.keyword_usage('ENSMODNUM', "'%s' is not a valid value for ENSMODNUM, must be integer" % value, 6)
      
         print "Number of models to use in each phaser ensemble: %d" % self.ENSMODNUM

   def parse_EVALUE(self, data_line):
      """ A function to parse the E_value keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: EVALUE requires an argument"
      else:
         value=string.split(data_line)[1]  
 
         try:
            self.E_value=float(value)
         except:
            self.keyword_usage('E_value', "'%s' is not a valid value for EVALUE, must be float" % value, 7)
      
         print "E value to use in fasta search: %.6f" % self.E_value

   def parse_KTIME(self, data_line):
      """ A function to parse the KTIME keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: KTIME requires an argument"
      else:
         value=string.split(data_line)[1]  
 
         try:
            self.KTIME=float(value)
         except:
            self.keyword_usage('KTIME', "'%s' is not a valid value for KTIME, must be float" % value, 7)
      
         print "Kill time for Phaser: %.6f (Please note that this value is only used if the KPHASER keyword is true)" % self.KTIME

   def parse_MRPROGRAMS(self, data_line):
      """ A function to parse the MRPROGRAMS keyword. """

      self.MR_PROGRAM_LIST = []
 
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: MRPROGRAMS requires one or more arguments"
         print "Setting default Molecular Replacement program to Molrep..."
         self.MR_PROGRAM_LIST = ['MOLREP']
      else:
         num_programs=len(string.split(data_line)) - 1
         for i in range(num_programs):
            program = (string.split(data_line)[i+1]).upper()
            if program != 'MOLREP' and program != 'PHASER':     
               self.keyword_usage('MRPROGRAMS', "'%s' is not a valid MR program" % program, 10)
            else:
               self.MR_PROGRAM_LIST.append(program)
      
         sys.stdout.write("MR programs to be used: ")
         for prog in self.MR_PROGRAM_LIST: 
            sys.stdout.write(prog +  " ")
         sys.stdout.write("\n")

   def parse_MAPROGRAM(self, data_line):
      """ A function to parse the MAPROGRAM keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: MAPROGRAM requires an argument"
      else:
         program = (string.split(data_line)[1]).upper()

         if program != 'MAFFT' and program != 'CLUSTALW' and program != 'CLUSTALW2' and program != 'PROBCONS' and program != 'T_COFFEE':     
            self.keyword_usage('MAPROGRAM', "'%s' is not a valid Sequence Multiple Alignment program" % program, 14)
         else:
            self.MAPROGRAM=program
      
         print "Default sequence alignment program: %s" % self.MAPROGRAM

   def parse_QTYPE(self, data_line):
      """ A function to parse the QTYPE keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: QTYPE requires an argument"
      else:
         qtype = (string.split(data_line)[1]).upper()

         if qtype != 'SGE' and qtype != 'PBS':     
            self.keyword_usage('QTYPE', "'%s' is not a recogniesed queuing system. 'SGE' or 'PBS' are accepted. " % qtype, 14)
         else:
            self.QTYPE=qtype
      
         print "Specified queuing system on cluster: %s" % self.QTYPE

   def parse_QSUBCOM(self, data_line):
      """ A function to parse the qsub and options command keyword. """

      if len(string.split(data_line)) == 1:
        sys.stdout.write("Keyword entry error: QSUBCOM requires an argument\n")
      else:
         qsub_command = " ".join(data_line.split()[1:])

         self.QSUBCOM=qsub_command
      
         sys.stdout.write("Command for submitting jobs to the cluster queueing system:\n  %s\n" % self.QSUBCOM)

   def parse_SHLXEXE(self, data_line):
      """ A function to parse the shelxe command keyword. """

      if len(string.split(data_line)) == 1:
        sys.stdout.write("Keyword entry error: SHLXEXE requires an argument\n")
      else:
         shelxe_exe = " ".join(data_line.split()[1:])

         self.SHLXEXE=shelxe_exe
      
         sys.stdout.write("Command for running SHELXE:\n  %s\n" % self.SHLXEXE)

   def parse_QSIZE(self, data_line):
      """ A function to parse the QSIZE keyword. """
   
      if len(string.split(data_line)) == 1:
         print "Keyword entry error: QSIZE requires an argument"
      else:
         value = string.split(data_line)[1]

         if value.isdigit() and int(value)>0:
            self.QSIZE=int(value)
         else:
            self.keyword_usage('QSIZE', "'%s' is not a valid value for QSIZE, must be positive integer" % value, 5)
      
         print "Maximum number of jobs submitted to cluster queue: %d" % self.QSIZE

   def parse_PROXYSERVER(self, data_line):
      """ A function to parse the PROXYSERVER keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: PROXYSERVER requires an argument"
      else:
         self.PROXYSERVER = (string.split(data_line)[1]).lower()
         
         print "Proxy server has been set to: %s" % self.PROXYSERVER
         print "This will be set in the environment and will be used for making connections"
         print "to the various online services used by MrBUMP (e.g. for PDB downloads)"
         print ""

   def parse_IGNORE(self, data_line):
      """ A function to parse the IGNORE keyword. """
   
      # Make a list from the line and delete the keyword IGNORE from the start
      line=string.split(data_line)
      del line[0]
      
      # Verify each PDB ID and add it to the ignore list 
      for i in line:
         pdb_id=i.lower()
         if len(pdb_id) !=4 or pdb_id.isalnum() == False or pdb_id[0].isdigit() == False:
            self.keyword_usage('ignore', "%s is not a valid PDB ID" % pdb_id, 3)
         else:
            self.ignore_list.append(pdb_id)
      print "List of PDB codes to ignore in the search: ", self.ignore_list
      
   def parse_INCLUDE(self, data_line):
      """ A function to parse the INCLUDE keyword. """
   
      # Make a list from the line and delete the keyword INCLUDE from the start
      line=string.split(data_line)
      del line[0]
      
      # Verify each PDB ID and add it to the include list 
      for i in line:
         chain=i.lower()
         if len(chain) !=6 or chain[0].isdigit() == False or chain[4] != "_" or chain[5].isalpha() == False:
            self.keyword_usage('include', "%s is not a valid Chain ID" % chain, 3)
         else:
            self.include_list.append(chain)
      print "List of PDB codes to include in the search: ", self.include_list
      
   def parse_ACORNRES(self, data_line):
      """ A function to parse the Acorn resolution limit keyword. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: ACORNRES requires an argument"
      else:
         value=string.split(data_line)[1]  
 
         try:
            self.ACORNRES=float(value)
         except:
            self.keyword_usage('ACORNRES', "'%s' is not a valid value for ACORNRES, must be float" % value, 7)
      
         print "Acorn will be invoked if the collected data resolution is better than: %.3f Angstroms" % self.ACORNRES

   def parse_LOGFILE(self, data_line):
      """ A function to parse the LOGFILE name. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: LOGFILE requires an argument (full path to a file name)"
      else:
         filename=string.split(data_line)[1]  

         # Check to see if the full path has been given, if not use the current directory
         dir_file=os.path.split(filename)

         if dir_file[0] == "":
            dir=os.getcwd()
            self.LOGFILE=os.path.join(dir, filename)
         else:
            self.LOGFILE=filename

         sys.stdout.write("LOGFILE: Log details for this job will be written to %s (not yet implemented):\n   %s\n" % self.LOGFILE)

   def parse_SUMMARYFILE(self, data_line):
      """ A function to parse the SUMMARYFILE name. """

      if len(string.split(data_line)) == 1:
         print "Keyword entry error: SUMMARYFILE requires an argument (full path to a file name)"
      else:
         filename=string.split(data_line)[1]  

         # Check to see if the full path has been given, if not use the current directory
         dir_file=os.path.split(filename)

         if dir_file[0] == "":
            dir=os.getcwd()
            self.SUMMARYFILE=os.path.join(dir, filename)
         else:
            self.SUMMARYFILE=filename

         sys.stdout.write("SUMMARYFILE: An XML summary of this job will be written to %s (not yet implemented):\n   %s\n" % self.SUMMARYFILE)
         self.XMLOUT=True

   def parse_LOCALFILE(self, data_line):
      """ A function to parse the LOCALFILE keyword. """

      if "LOCALFILE" in data_line.upper() and "CHAIN" in data_line.upper() and "RMS" in data_line.upper():
         # Pick out the filename (accounting for spaces)
         filename=self.get_FILENAME(data_line, ["CHAIN", "RMS"])

         # Pick out the chain name
         line=string.split(data_line.upper())
         for i in range(len(line)):
            if line[i] == "CHAIN":
               if len(line) > i+1:
                  chainID=line[i+1] 
               else:
                  error_message="No argument given for CHAIN subkeyword for keyword LOCALFILE"
                  self.LOCALFILE_usage(error_message)
                  sys.exit()

         # Pick out the RMS value         
         line=string.split(data_line.upper())
         for i in range(len(line)):
            if line[i] == "RMS":
               if len(line) > i+1:
                  rms=line[i+1] 
               else:
                  error_message="No argument given for RMS subkeyword for keyword LOCALFILE"
                  self.LOCALFILE_usage(error_message)
                  sys.exit()

         if self.is_a_float(rms):
            rms=float(rms)
         else:
            error_message="Incorrect type for RMS in LOCALFILE keyword. Should be a float"
            self.LOCALFILE_usage(error_message)
            sys.exit()
            
      elif "LOCALFILE" in data_line.upper() and "CHAIN" in data_line.upper():
         # Pick out the filename (accoutning for spaces)
         filename=self.get_FILENAME(data_line, ["CHAIN"])
     
         # Pick out the chain name
         line=string.split(data_line.upper())
         for i in range(len(line)):
            if line[i] == "CHAIN":
               if len(line) > i+1:
                  chainID=line[i+1] 
               else:
                  error_message="No argument given for CHAIN subkeyword for keyword LOCALFILE"
                  self.LOCALFILE_usage(error_message)
                  sys.exit()

         # Set the rms value to be 0.0
         # If rms is set to 0.0 the sequence ID will be used for RMS input to phaser
         rms=0.0

      elif "LOCALFILE" in data_line.upper() and "RMS" in data_line.upper():
         # Pick out the filename (accoutning for spaces)
         filename=self.get_FILENAME(data_line, ["RMS"])
      
         # Pick out the RMS value         
         line=string.split(data_line.upper())
         for i in range(len(line)):
            if line[i] == "RMS":
               if len(line) > i+1:
                  rms=line[i+1] 
               else:
                  error_message="No argument given for RMS subkeyword for keyword LOCALFILE"
                  self.LOCALFILE_usage(error_message)
                  sys.exit()

         if self.is_a_float(rms):
            rms=float(rms)
         else:
            error_message="Incorrect type for RMS in LOCALFILE keyword. Should be a float"
            self.LOCALFILE_usage(error_message)
            sys.exit()
            
         # Set the chainID to be "A"
         chainID="ALL"

      elif "LOCALFILE" in data_line.upper():
         # Pick out the filename (accoutning for spaces)
         filename=self.get_FILENAME(data_line)
 
         # Set the chainID to be "A" and rms to be 0.0
         # If rms is set to 0.0 the sequence ID will be used for RMS input to phaser
         chainID="ALL"
         rms=0.0

      # Verify that the file exists
      if os.path.isfile(filename) == False:
         error_message="File specified in LOCALFILE keyword not found:\n  %s\nDid you specify the full path?" % filename
         self.LOCALFILE_usage(error_message)
         sys.exit()
      else:
         # Set up a LocalPDB class for this local file
         lpdb=LocalPDB()
         lpdb.filename=filename
         lpdb.filestring=os.path.splitext(os.path.split(lpdb.filename)[1])[0]
         lpdb.chainID=chainID
         lpdb.rms=rms
         lpdb.number=self.locfile_count

         # Add this local file class to the local_list dictionary
         self.local_list["loc" + `self.locfile_count` + "_" + chainID + "_" + lpdb.filestring] = lpdb
         self.locfile_count = self.locfile_count + 1
      
      # Echo the details to the stdout
      sys.stdout.write("Chain from local file to include in model search:\n")
      if rms==0.0:
         sys.stdout.write("Chain ID: %s -- Filename: %s\n" % (chainID, filename)) 
      else:
         sys.stdout.write("Chain ID: %s (RMS=%.2f) -- Filename: %s\n" % (chainID, rms, filename)) 


   def LOCALFILE_usage(self, error_message):
      """ The usage message for the LOCALFILE keyword. """

      sys.stdout.write("Keyword input error: %s\n" % error_message)      
      sys.stdout.write("Format: LOCALFILE <filename> [CHAIN <chain ID>] [RMS <rms value>]\n")      
      sys.stdout.write("\n")      
     
   def parse_FIXED_XYZIN(self, data_line):
      """ A function to parse the FIXED_XYZIN keyword. """
   
      # The line format should be:
      #    FIXED_XYZIN <pdbfile> IDENTITY <?> 
      # This can occur multiple times

      line=string.split(data_line)
      if "FIXE" not in line[0].upper()  or "IDEN" not in data_line.upper():
         sys.stdout.write("Keyword input error: FIXED_XYZIN\n") 
         sys.stdout.write("  Format: FIXED_XYZIN <filename> IDENTIY <fractional sequence identity>\n") 
         sys.stdout.write("     e.g. FIXED_XYZIN /home/user/foo.pdb IDENTIY 0.6\n") 
         sys.stdout.write("\n") 
         sys.exit()

      # Set the identity value
      # Test to see if it's a valid float
      if self.is_a_float(line[-1]):
         identity=float(line[-1])
      else:
         sys.stdout.write("Keyword input error: non-float value for IDENTITY in line:\n")
         sys.stdout.write("   %s\n" % data_line)
         sys.stdout.write("\n")
         sys.exit()

      # Strip away everything except the file name
      file=line
      del file[-1]  # strips the identity value
      del file[-1]  # strips the "IDENTITY" keyword
      del file[0]   # strips the "FIXED_XYZIN" keyword

      # Catch for any spaces in the filename (e.g. if on windows the file is in Docs & Settings)
      filename=string.join(file)

      # Check to see if the file actually exists
      if os.path.isfile(filename) == False:
         sys.stdout.write("Keyword input error: File not found\n")
         sys.stdout.write("  File: %s was not found\n" % filename)
         sys.stdout.write("\n")
         sys.exit()

      # Work out the Molecular Weight for this component
      mw=mol_weight.MolWeight()
      molecular_weight=mw.get_pdbMW(filename)

      # Setup the fixed pdb file class for this file
      fixed_pdb=FixedPDB()
      fixed_pdb.filename=filename
      fixed_pdb.identity=identity
      fixed_pdb.mol_weight=molecular_weight

      # Add this file class to the fixed_list dictionary
      self.fixed_list[self.fixedfile_count]=fixed_pdb

      # Increment the fixed files count 
      self.fixedfile_count = self.fixedfile_count + 1

      # Set the FIXED flag to True
      self.FIXED=True

      # Detail the file inclusion to the stdout
      sys.stdout.write("Fixed component to be used in MR search added\n")
      sys.stdout.write("   Filename: %s\n" % filename)
      sys.stdout.write("   Sequence identity for this component: %.3f\n" % identity)
      sys.stdout.write("   Molecular weight for this component: %.3f\n" % molecular_weight)

   def parse_FLAG(self, data_line, env_flag):
      """ A function to parse any boolen flag keywords. """
  
      flag=string.split(data_line)[1]
       
      # Verify that the variable is set to True or False
      if flag.upper() != 'FALSE' and flag.upper() != 'TRUE' and flag != '1' and flag != '0':
         self.keyword_usage(env_flag, "'%s' is not a valid option for keyword %s" % (flag, env_flag), 15)

      if flag.upper() == 'TRUE' or flag == '1':
         if env_flag == 'DEBUG': 
            self.DEBUG=True
            os.environ["MRBUMP_DEBUG"]="True"
            print "Debug set to: ", self.DEBUG
         if env_flag == 'CLUSTER': 
            self.CLUSTER=True
            os.environ["MRBUMP_CLUSTER"]="True"
            print "Cluster set to: ", self.CLUSTER
         if env_flag == 'SCOPSEARCH':
            self.SCOP=True
            print "SCOP search set to: ", self.SCOP
         if env_flag == 'SSMSEARCH':
            self.SSM=True
            print "SSM search set to: ", self.SSM
         if env_flag == 'PQSSEARCH':
            self.PQS=True
            self.PISA=False
            #print "PQS search set to: ", self.PQS, "(and PISA search set to: ", self.PISA, " )"
            print "PQS search set to: ", self.PQS
         if env_flag == 'PISASEARCH':
            self.PISA=True
            self.PQS=False
            print "PISA search set to: ", self.PISA, "(and PQS search set to: ", self.PQS, " )"
         if env_flag == 'FASTALOCAL':
            self.fasta_local=True
            print "Run local Fasta search set to: ", self.fasta_local
         if env_flag == 'RUNLOCAL':
            self.run_local=True
            print "Run local set to: ", self.run_local
         if env_flag == 'UPDATE':
            self.UPDATE=True
            print "Update database files set to: ", self.UPDATE
         if env_flag == 'DOFASTA':
            self.DOFASTA=True
            print "Do the FASTA search set to: ", self.DOFASTA
         if env_flag == 'DOHHPRED':
            self.DOHHPRED=True
            print "Do HHPRED search set to: ", self.DOHHPRED
         if env_flag == 'HHSCORE':
            self.HHSCORE=True
            print "Do HHSCORE search set to: ", self.HHSCORE
         if env_flag == 'TRYALL':
            self.TRYALL=True
            print "Run in TRYALL mode set to: ", self.TRYALL
         if env_flag == 'CLEAN':
            self.CLEAN=True
            print "CLEAN flag set to: ", self.CLEAN
         if env_flag == 'LITE':
            self.LITE=True
            print "LITE flag set to: ", self.LITE
         if env_flag == 'HTMLOUT':
            self.HTMLOUT=True
            print "Run in HTMLOUT mode set to: ", self.HTMLOUT
         if env_flag == 'MDLUNMOD':
            self.MDLUNMOD=True
            print "Generate UNMOD models set to: ", self.MDLUNMOD
         if env_flag == 'MDLDPDBCLP':
            self.MDLDPDBCLP=True
            print "Generate PDBClip models set to: ", self.MDLDPDBCLP
         if env_flag == 'MDLPLYALA':
            self.MDLPLYALA=True
            print "Generate Polyalanine models set to: ", self.MDLPLYALA
         if env_flag == 'MDLMOLREP':
            self.MDLMOLREP=True
            print "Generate Molrep models set to: ", self.MDLMOLREP
         if env_flag == 'MDLCHAINSAW':
            self.MDLCHAINSAW=True
            print "Generate Chainsaw models set to: ", self.MDLCHAINSAW
         if env_flag == 'MDLSCULPTOR':
            self.MDLSCULPTOR=True
            print "Generate Sculptor models set to: ", self.MDLSCULPTOR
         if env_flag == 'USEACORN':
            self.USEACORN=True
            print "Use Acorn to improve map set to: ", self.USEACORN
         if env_flag == 'BUCCANEER':
            self.BUCCANEER=True
            print "Use Buccaneer to do model building set to: ", self.BUCCANEER
         if env_flag == 'ARPWARP':
            self.ARPWARP=True
            print "Use ARP/wARP to do model building set to: ", self.ARPWARP
         if env_flag == 'SHELXE':
            self.SHELXE=True
            print "Use Shelxe to do c-alpha trace set to: ", self.SHELXE
         if env_flag == 'USECPIRATE':
            self.USECPIRATE=True
            print "Use Cpirate to improve phases set to: ", self.USECPIRATE
         if env_flag == 'USEENSEM':
            self.USEENSEM=True
            print "Use Ensemble of top models in MR set to: ", self.USEENSEM
         if env_flag == 'CHECK':
            self.CHECK=True
            print "Check web connection set to: ", self.CHECK
         if env_flag == 'ENANT':
            self.ENANT=True
            print "Enantiomporph search set to: ", self.ENANT
         if env_flag == 'SGALL':
            self.SGALL=True
            print "Test all spacegroups (phaser only) set to: ", self.SGALL
         if env_flag == 'DUMMY':
            self.DUMMY=True
            print "DUMMY run set to: ", self.DUMMY
         if env_flag == 'PICKLE':
            self.PICKLE=True
            print "PICKLE run set to: ", self.PICKLE
         if env_flag == 'DBOUT':
            self.DBOUT=True
            print "DBOUT run set to: ", self.DBOUT
         if env_flag == 'DBVIEW':
            self.DBVIEW=True
            print "DBVIEW run set to: ", self.DBVIEW
         if env_flag == 'REFTWIN':
            self.REFTWIN=True
            print "Refmac TWIN option run set to: ", self.REFTWIN
         if env_flag == 'RBODREF':
            self.RBODREF=True
            print "Refmac Rigid Body refinement option set to: ", self.RBODREF
         if env_flag == 'JBODREF':
            self.JBODREF=True
            print "Refmac Jelly Body refinement option set to: ", self.JBODREF
         if env_flag == 'FIXSG':
            self.FIXSG=True
            print "Fixing Spacegroup to MTZ Spacgroup: FIXSG=", self.FIXSG
         if env_flag == 'KPHASER':
            self.KPHASER=True
            print "Kill Phaser after set time: KPHASER=", self.KPHASER

      if flag.upper() == 'FALSE' or flag == '0': 
         if env_flag == 'DEBUG': 
            self.DEBUG=False
            os.environ["MRBUMP_DEBUG"]="False"
            print "Debug set to: ", self.DEBUG
         if env_flag == 'CLUSTER': 
            self.CLUSTER=False
            os.environ["MRBUMP_CLUSTER"]="False"
            print "Cluster set to: ", self.CLUSTER
         if env_flag == 'SCOPSEARCH':
            self.SCOP=False
            print "SCOP search set to: ", self.SCOP
         if env_flag == 'SSMSEARCH':
            self.SSM=False
            print "SSM search set to: ", self.SSM
         if env_flag == 'PQSSEARCH':
            self.PQS=False
            print "PQS search set to: ", self.PQS
         if env_flag == 'PISASEARCH':
            self.PISA=False
            print "PISA search set to: ", self.PISA
         if env_flag == 'FASTALOCAL':
            self.fasta_local=False
            print "Run local Fasta search set to: ", self.fasta_local
         if env_flag == 'RUNLOCAL':
            self.run_local=False
            print "Run local set to: ", self.run_local
         if env_flag == 'UPDATE':
            self.UPDATE=False
            print "Update database files set to: ", self.UPDATE
         if env_flag == 'DOFASTA':
            self.DOFASTA=False
            print "Do FASTA search set to: ", self.DOFASTA
         if env_flag == 'DOHHPRED':
            self.DOHHPRED=False
            print "Do HHPRED search set to: ", self.DOHHPRED
         if env_flag == 'HHSCORE':
            self.HHSCORE=False
            print "Do HHSCORE search set to: ", self.HHSCORE
         if env_flag == 'TRYALL':
            self.TRYALL=False
            print "Run in TRYALL mode set to: ", self.TRYALL
         if env_flag == 'CLEAN':
            self.CLEAN=False
            print "CLEAN flag set to: ", self.CLEAN
         if env_flag == 'LITE':
            self.LITE=False
            print "LITE flag set to: ", self.LITE
         if env_flag == 'HTMLOUT':
            self.HTMLOUT=False
            print "Run in HTMLOUT mode set to: ", self.HTMLOUT
         if env_flag == 'MDLUNMOD':
            self.MDLDPDBCLP=False
            print "Generate UNMOD models set to: ", self.MDLUNMOD
         if env_flag == 'MDLDPDBCLP':
            self.MDLDPDBCLP=False
            print "Generate PDBClip models set to: ", self.MDLDPDBCLP
         if env_flag == 'MDLPLYALA':
            self.MDLPLYALA=False
            print "Generate Polyalanine models set to: ", self.MDLPLYALA
         if env_flag == 'MDLMOLREP':
            self.MDLMOLREP=False
            print "Generate Molrep models set to: ", self.MDLMOLREP
         if env_flag == 'MDLCHAINSAW':
            self.MDLCHAINSAW=False
            print "Generate Chainsaw models set to: ", self.MDLCHAINSAW
         if env_flag == 'MDLSCULPTOR':
            self.MDLSCULPTOR=False
            print "Generate Sculptor models set to: ", self.MDLSCULPTOR
         if env_flag == 'USEACORN':
            self.USEACORN=False
            print "Use Acorn to improve map set to: ", self.USEACORN
         if env_flag == 'BUCCANEER':
            self.BUCCANEER=False
            print "Use Buccaneer to do model building set to: ", self.BUCCANEER
         if env_flag == 'ARPWARP':
            self.ARPWARP=False
            print "Use ARP/wARP to do model building set to: ", self.ARPWARP
         if env_flag == 'SHELXE':
            self.SHELXE=False
            print "Use Shelxe to do c-alpha trace set to: ", self.SHELXE
         if env_flag == 'USECPIRATE':
            self.USECPIRATE=False
            print "Use Cpirate to improve phases set to: ", self.USECPIRATE
         if env_flag == 'USEENSEM':
            self.USEENSEM=False
            print "Use Ensemble in MR set to: ", self.USEENSEM
         if env_flag == 'CHECK':
            self.CHECK=False
            print "Check web connection set to: ", self.CHECK
         if env_flag == 'ENANT':
            self.ENANT=False
            print "Enantiomporph search set to: ", self.ENANT
         if env_flag == 'SGALL':
            self.SGALL=False
            print "Test all spacegroups (phaser only) set to: ", self.SGALL
         if env_flag == 'DUMMY':
            self.DUMMY=False
            print "DUMMY run set to: ", self.DUMMY
         if env_flag == 'PICKLE':
            self.PICKLE=False
            print "PICKLE run set to: ", self.PICKLE
         if env_flag == 'DBOUT':
            self.DBOUT=False
            print "DBOUT run set to: ", self.DBOUT
         if env_flag == 'DBVIEW':
            self.DBVIEW=False
            print "DBVIEW run set to: ", self.DBVIEW
         if env_flag == 'REFTWIN':
            self.REFTWIN=False
            print "Refmac TWIN option run set to: ", self.REFTWIN
         if env_flag == 'RBODREF':
            self.RBODREF=False
            print "Refmac Rigid Body Refinement option set to: ", self.RBODREF
         if env_flag == 'JBODREF':
            self.JBODREF=False
            print "Refmac Jelly Body Refinement option set to: ", self.JBODREF
         if env_flag == 'FIXSG':
            self.FIXSG=False
            print "FIXSG: ", self.FIXSG
         if env_flag == 'KPHASER':
            self.KPHASER=False
            print "KPHASER: ", self.KPHASER

   def parse_LABIN(self, data_line):
      """ A function to parse the LABIN keyword. """

      labels=[]

      # Check that the correct number of arguments are given
      if data_line.count('=') != 3:
         self.keyword_usage('labin', 'Incorrect number of arguments for LABIN', 1)

      # Split the line into its separate parts
      line=string.split(data_line,'=')

      # Remove the 'LABIN' word from the start of the line
      labin_part=string.split(line[0])
      del labin_part[0]

      # Remove the first entry and re-enter it without 'LABIN'
      del line[0]
      line.insert(0,labin_part[0])

      # Now split the line again
      for i in line:
        t=string.split(i)
        for j in t:
           labels.append(j)

      # Assign the column labels from the list (0=1, 2=3 4=5)
      self.col_labels[labels[0].upper()]=labels[1]
      self.col_labels[labels[2].upper()]=labels[3]
      self.col_labels[labels[4].upper()]=labels[5]

      # Check that all of the necessary column labels are given
      print ""
      for i in 'F', 'SIGF' , 'FREER_FLAG':
         if i not in self.col_labels.keys(): 
            self.keyword_usage('labin', "Column label %s not given" % i, 2)
         print "column %s labelled as %s" % (i, self.col_labels[i]) 
      print ""

   def verify_NUM(self):
      """ A function to chekc that the NUM_ variables adhere to the constraints. """

      # if we are not doing Ensemble, set the number in each ensemble to 0 and the number of ensembles to 0
      if self.USEENSEM == False:
         self.ENSNUM = 0
         self.ENSMODNUM = 0

      # Verify that ENSMODNUM is less than MRNUM
      if self.ENSMODNUM > self.MRNUM and "PHASER" in self.MR_PROGRAM_LIST:
         sys.stdout.write("Input Warning: Number of search models to be used in each Phaser ensemble (%d) is more than the\n" % self.ENSMODNUM
                        + "               number of models to be prepared for MR (%d). Resetting the number in each ensemble\n" % self.MRNUM
                        + "               to the number of search models being prepared, and the number of ensembles to 1.\n")
         sys.stdout.write("\n")

         self.ENSNUM = 1
         self.ENSMODNUM = self.MRNUM
         sys.stdout.write("Number of models to use in each Phaser ensemble: %d\n" % self.ENSMODNUM)
         sys.stdout.write("Number of Phaser ensembles: %d\n" % self.ENSNUM)
         sys.stdout.write("\n")

      if self.ENSNUM*self.ENSMODNUM > self.MRNUM and  "PHASER" in self.MR_PROGRAM_LIST:
         sys.stdout.write("Input warning: Number of search models (%d) is less than no. of ensembles*no. of models/ensemble (%d*%d)\n"%(self.MRNUM, self.ENSNUM, self.ENSMODNUM))
         sys.stdout.write("Number of ensembles will be less than %d\n"%self.ENSNUM)

   def keyword_usage(self, keyword, error_string, error_code):
      """ A function to echo the correct usage of the keywords to the stdout. """

      self.setErrorString(error_string)
 
      print "Keyword error:"

      # LABIN errors:
      if keyword == 'labin':
         print "LABIN error: %s" % self.error_string
         print "Keyword LABIN must be provided and must specify 3 column labels: F, SIGF and FreeR_flag"
         print "  e.g. LABIn F=FP SIGF=SIGFP FreeR_flag=FREE"
     
      # JOBID errors
      if keyword == 'jobid':
         print "JOBID error: %s" % self.error_string
         print "Keyword JOBID must be provided"
         print "  e.g. JOBID Test_job1"
     
      # ROOTDIR errors
      if keyword == 'root_dir':
         print "ROOTDIR error: %s" % self.error_string
     
      # RESULTS HTML errors
      if keyword == 'reshtml':
         print "RESHTML error: %s" % self.error_string
     
      # IGNORE PDB id errors
      if keyword == 'ignore':
         print "IGNORE error: %s" % self.error_string
         print "Keyword IGNORE must specify PDB codes"
         print "  e.g. IGNORE 1smw 1smm 1smu 1ahc ......"

      # INCLUDE PDB id errors
      if keyword == 'include':
         print "INCLUDE error: %s" % self.error_string
         print "Keyword INCLUDE must specify chain codes. This is a four character PDB code\n" \
               + "followed by an underscore and a chain identifier letter."
         print "  e.g. INCLUDE 1smw_A 1smm_B 1smu_A 1ahc_C ......"

      # NMASU errors
      if keyword == 'NMASU':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 4" % keyword
    
      # PACK errors
      if keyword == 'PACK':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 4" % keyword

      # PRMS errors
      if keyword == 'PRMS':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 2.0" % keyword

      # PJOBS errors
      if keyword == 'PJOBS':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 4" % keyword
    
      # NCYC errors
      if keyword == 'NCYC':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
     
      # BCYCLES errors
      if keyword == 'BCYCLES':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
    
      # ACYCLES errors
      if keyword == 'ACYCLES':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
    
      # SCYCLES errors
      if keyword == 'SCYCLES':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
    
      # RBNC errors
      if keyword == 'RBNC':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
    
      # PIRCYC errors
      if keyword == 'PIRCYC':
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 10" % keyword
    
      # NUM_values errors
      if keyword == 'NUM_values':
         print "'NUM' variables error: %s" % self.error_string

      if keyword in ['MRNUM','ENSMODNUM','ENSNUM']:
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s 20" % keyword
    
      # EVALUE errors
      if keyword == 'E_value':
         print "EVALUE error: %s" % self.error_string
         print "  e.g. EVALUE 0.02"

      # KTIME errors
      if keyword == 'KTIME':
         print "KTIME error: %s" % self.error_string
         print "  e.g. KTIME 300.0"

      # ACORNRES errors
      if keyword == 'ACORNRES':
         print "ACORNRES error: %s" % self.error_string
         print "  e.g. ACORNRES 1.7"

      # Debug errors
      if keyword == 'DEBUG' or keyword == 'CLUSTER' or keyword == 'SCOPSEARCH' or keyword == 'SSMSEARCH' \
            or keyword == 'PQSSEARCH' or keyword == 'PWALIGN' or keyword == 'FASTALOCAL' \
            or keyword == 'RUNLOCAL' or keyword == 'UPDATE' or keyword == 'FIXSG' or keyword == 'KPHASER' \
            or keyword == 'MDLCHAINSAW' or keyword == 'MDLMOLREP' or keyword == 'MDLSCULPTOR' \
            or keyword == 'MDLPLYALA' or keyword == 'MDLDPDBCLP' or keyword == 'TRYALL' \
            or keyword == 'HTMLOUT' or keyword == 'USEACORN' or keyword == 'USECPIRATE' \
            or keyword == 'ENANT' or keyword == 'USEENSEM' or keyword == 'PISASEARCH' \
            or keyword == 'DUMMY' or keyword == 'PICKLE' or keyword == 'DBOUT' \
            or keyword == 'DBVIEW' or keyword == 'CLEAN' or keyword == 'LITE' \
            or keyword == "CHECK" or keyword == "SGALL" or keyword == 'SHELXE' \
            or keyword == 'BUCCANEER' or keyword == 'ARPWARP' or keyword == 'MDLUNMOD':  
         print "%s error: %s" % (keyword, self.error_string)
         print "  e.g. %s True" % keyword

      # MRPROGRAM errors
      if keyword == 'MRPROGRAMS':
         print "MRPROGRAMS error: %s" % self.error_string
         print "Keyword MRPROGRAMS must be 'MOLREP' or 'PHASER' or both"
         print "  e.g. MRPROGRAMS PHASER MOLREP"

      # MAPROGRAM errors
      if keyword == 'MAPROGRAM':
         print "MAPROGRAM error: %s" % self.error_string
         print "Keyword MAPROGRAM must be 'MAFFT', 'CLUSTALW', 'CLUSTALW2', 'T_COFFEE' or 'PROBCONS'"
         print "  e.g. MAPROGRAM Mafft"

      # QTYPE errors
      if keyword == 'QTYPE':
         print "QTYPE error: %s" % self.error_string
         print "Keyword QTYPE must be 'SGE' or 'PBS'"
         print "  e.g. QTYPE SGE"

      # QSIZE errors
      if keyword == 'QSIZE':
         print "QSIZE error: %s" % self.error_string
         print "Keyword QSIZE must be > 0"
         print "  e.g. QTYPE 5"
         
      # FASTA search error
      if keyword == 'DOFASTA':
         print "DOFASTA error: %s" % self.error_string

      # HHpred search error
      if keyword == 'DOHHPRED':
         sys.stdout.write("DOHHPRED error: %s\n" % self.error_string)

      sys.exit(error_code)

   def get_FILENAME(self, data_line, flags=[]):
      """ get a filename from a keyword line (accounting for spaces). """

      name=[]
      line=string.split(data_line)
      del line[0]
      for i in range(len(line)):
         if line[i].upper() not in flags:
            name.append(line[i])
         else:
            break

      filename=string.joinfields(name, " ")
     
      return filename

   def is_an_integer(self, s):
      """ A quick function to check if a string is an integer. """
   
      try: int(s)
      except ValueError: return False
      else: return True   

   def is_a_float(self, s):
      """ A quick function to check if a string is a float. """
   
      try: float(s)
      except ValueError: return False
      else: return True   


class FixedPDB:
   """ An object to hold details for a Fixed PDB file in the MR search. """

   def __init__(self):
      self.filename=""
      self.identity=0.0
      self.mol_weight=0.0


class LocalPDB:
   """ An object to hold the details of a local file specified by the user for inclusionn
       in the molecular replacement step. """
   
   def __init__(self):
      self.filename=""
      self.filestring=""
      self.chainID=""
      self.rms=0.0
      self.number=0


if __name__ == '__main__':

   k=Keywords()
   k.parse_LABIN("LABIn FP=FP SIGF=SIGFP freer_flag=FREE")
