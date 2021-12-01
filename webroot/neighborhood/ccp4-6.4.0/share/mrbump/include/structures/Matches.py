#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Master object for the mrbump job
# Ronan Keegan 11/11/04

import os, string, sys
import shutil
import PDB_info
import subprocess
import shlex

import urllib
#import sets

import Align_structure
import Write_seq_align
import Align_score 
import Sort_dict
import Get_sequence_DB
import Fasta_search
import SCOP_search, Get_SCOP
import Write_MR_results
import Write_Search_results

import MRBUMP_MAFFT
import MRBUMP_PROBCONS
import MRBUMP_T_COFFEE
import MRBUMP_CLUSTALW
import PDBClip

import split_NMR
import DB_handler
import PDB_download


if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Job_struct:
   """ A class to hold details about a particular job """

   def __init__(self):

      self.job_name=""
      self.model_name=""
      self.MRPROGRAM=""
      self.refine_program=""
      

class Chain_struct:
   """ A defined structure for the matching sequence
   information. """
	
   def __init__(self):
     self.chainName=''
     self.chainID=''
     self.PDBName=''
     self.unprocessed_PDBFile=''
     self.original_PDBFile=''
     self.PDBFile=''
     self.Score=0
     self.seqID=0.0
     self.rms=0.0
     self.align_length=0
     self.sequence=''
     self.chain_sequence=''
     self.seqlength=0
     self.included=False

     self.no_of_domains=0
     self.domain_list=[]
     self.domain_range_list=[]
     self.no_of_ranges=0

     self.source=''
     self.parent_chain=''
     self.expdata=''
     self.resolution_high=0.0
     self.resolution_low=0.0
 
     self.working_DIR=''
 
     self.raw_align_file=''
     self.ma_pir_file='' 
     self.pir_aln_file='' 

     self.unmod_modelPDB='' 
     self.unmod_logfile='' 
     self.unmod_jobname=''
     self.unmod_jobid=''
     self.unmod_score=0.0

     self.plyala_modelPDB='' 
     self.plyala_logfile='' 
     self.plyala_jobname=''
     self.plyala_jobid=''
     self.plyala_score=0.0

     self.molrep_modelPDB='' 
     self.molrep_logfile='' 
     self.molrep_errfile='' 
     self.molrep_jobname=''
     self.molrep_jobid=''
     self.molrep_score=0.0

     self.pdbclip_modelPDB='' 
     self.coord_format_logfile=''
     self.pdbset_logfile=''
     self.pdbcur_logfile=''

     self.chainsaw_modelPDB='' 
     self.chainsaw_logfile='' 
     self.chainsaw_errfile='' 
     self.chainsaw_ALIGNIN='' 
     self.chainsaw_jobname=''
     self.chainsaw_jobid=''
     self.chainsaw_score=0.0

     self.sculptor_modelPDB='' 
     self.sculptor_logfile='' 
     self.sculptor_errfile='' 
     self.sculptor_ALIGNIN='' 
     self.sculptor_jobname=''
     self.sculptor_jobid=''
     self.sculptor_score=0.0

     self.multimer_type=''
     self.number_monomers=''
     self.has_multimer='no'
     self.multimer_list=[]

     self.alignment=Align_structure.align_struct()

     self.HHmatch=False
     self.HHalignment=""
     self.HHtargetSequence=""

   def setchainName(self, chainName):
     self.chainName=chainName 

   def setchainID(self, chainID):
     self.chainID=chainID

   def setPDBName(self, PDBName):
     self.PDBName=PDBName 

   def setUnprocessedPDBFile(self, PDBFile):
     self.unprocessed_PDBFile=PDBFile 

   def setOriginalPDBFile(self, PDBFile):
     self.original_PDBFile=PDBFile 

   def setPDBFile(self, PDBFile):
     self.PDBFile=PDBFile 

   def setScore(self, Score):
     self.Score=Score 

   def setseqID(self, seqID):
     self.seqID=seqID 

   def setRMS(self, RMS):
     self.rms=RMS 

   def setAlignLength(self, align_length):
     self.align_length=align_length 

   def setSequence(self, sequence):
     self.sequence=sequence 

   def setChainSequence(self, chain_sequence):
     self.chain_sequence=chain_sequence 

   def setSeqLength(self, seqlength):
     self.seqlength=seqlength 

   def setNoofDomains(self, number):
     self.no_of_domains=number

   def setNoofRanges(self, number):
     self.no_of_ranges=number

   def setSource(self, sourcetype):
     self.source=sourcetype 

   def setParentChain(self, name):
     self.parent_chain=name 

   def setEXPDATA(self, expdata):
     self.expdata=expdata 

   def setIncluded(self, flag):
     self.included=flag 


   def setWorkingDIR(self, directory):
     self.working_DIR=directory


   def setRawAlignFile(self, raw_align_file):
      self.raw_align_file = raw_align_file

   def setMAPIRFile(self, filename):
     self.ma_pir_file=filename 


   def setUnmodModelPDB(self, Unmod_model_PDB):
     self.unmod_modelPDB=Unmod_model_PDB 

   def setUnmodLogFile(self, Unmod_Logfile):
     self.unmod_logfile=Unmod_Logfile

   def setUnmodJobName(self, Unmod_Job_Name):
     self.unmod_jobname=Unmod_Job_Name 

   def setUnmod_jobid(self, Unmod_Job_ID):
     self.unmod_jobid=Unmod_Job_ID 

   def setUnmodScore(self, UnmodScore):
     self.unmod_score=UnmodScore 


   def setPlyalaModelPDB(self, Plyala_model_PDB):
     self.plyala_modelPDB=Plyala_model_PDB 

   def setPlyalaLogFile(self, Plyala_Logfile):
     self.plyala_logfile=Plyala_Logfile

   def setPlyalaJobName(self, Plyala_Job_Name):
     self.plyala_jobname=Plyala_Job_Name 

   def setPlyala_jobid(self, Plyala_Job_ID):
     self.plyala_jobid=Plyala_Job_ID 

   def setPlyalaScore(self, PlyalaScore):
     self.plyala_score=PlyalaScore 


   def setMolrepModelPDB(self, Molrep_model_PDB):
     self.molrep_modelPDB=Molrep_model_PDB 

   def setMolrepLogFile(self, Molrep_Logfile):
     self.molrep_logfile=Molrep_Logfile

   def setMolrepErrFile(self, Molrep_Errfile):
     self.molrep_errfile=Molrep_Errfile

   def setMolrepJobName(self, Molrep_Job_Name):
     self.molrep_jobname=Molrep_Job_Name 

   def setMolrep_jobid(self, Molrep_Job_ID):
     self.molrep_jobid=Molrep_Job_ID 

   def setMolrepScore(self, MolrepScore):
     self.molrep_score=MolrepScore 


   def setClipModelPDB(self, Clip_model_PDB):
     self.pdbclip_modelPDB=Clip_model_PDB 

   def setCoordFormatLog(self, coord_format_logfile):
     self.coord_format_logfile=coord_format_logfile 

   def setPDBsetLog(self, pdbset_logfile):
     self.pdbset_logfile=pdbset_logfile 

   def setPDBcurLog(self, pdbcur_logfile):
     self.pdbcur_logfile=pdbcur_logfile 


   def setChainsawModelPDB(self, model_PDB):
     self.chainsaw_modelPDB=model_PDB 

   def setChainsawLogFile(self, logfile):
     self.chainsaw_logfile=logfile

   def setChainsawErrFile(self, errfile):
     self.chainsaw_errfile=errfile

   def setChainsawJobName(self, Job_Name):
     self.chainsaw_jobname=Job_Name 

   def setChainsaw_jobid(self, Job_ID):
     self.chainsaw_jobid=Job_ID 

   def setChainsawScore(self, Score):
     self.chainsaw_score=Score 


   def setSculptorModelPDB(self, model_PDB):
     self.sculptor_modelPDB=model_PDB 

   def setSculptorLogFile(self, logfile):
     self.sculptor_logfile=logfile

   def setSculptorErrFile(self, errfile):
     self.sculptor_errfile=errfile

   def setSculptorJobName(self, Job_Name):
     self.sculptor_jobname=Job_Name 

   def setSculptor_jobid(self, Job_ID):
     self.sculptor_jobid=Job_ID 

   def setSculptorScore(self, Score):
     self.sculptor_score=Score 


   def setMultimerType(self, type):
     self.multimer_type=type 

   def setNumberMonomers(self, nmon):
     self.number_monomers=nmon 

   def setMultimer(self, ans):
     self.has_multimer=ans 


class Match_struct:
   """ Master object for job data. """

   def __init__(self):

     self.search_results=Write_Search_results.Write_html()
     self.mr_results=Write_MR_results.Write_MR_Results()

     self.conn=""
     self.Hdlr=DB_handler.Handler()
     self.mrbump_project=""

     self.ctruncate_logfile=""
     self.SEQmatchfile=''
     self.SSMmatchfile=''
     self.SSM_logfile=''
     self.SSM_resultsfile=''
     self.SSM_results=[]
     self.no_of_hits=0
     self.no_of_SEQhits=0
     self.no_of_SSMhits=0
     self.no_of_newSSMhits=0
     self.no_of_PQShits=0
     self.no_of_SCOPhits=0
     self.SEQhits=[]
     self.SSMnewhits=[]
     self.E_value=0.02
     self.est_no_of_mols=0
  
     self.fastaList=[]
     self.fastaHits=0
     self.hhpredList=[]
     self.hhpredHits=0
     self.hhpredALNFile=""

     self.TRYALL_summary=dict([])

     self.InitError=[]

     self.top_match_chainid=''
     self.top_match_pdbid=''
     self.FASTA_top_match_PDBfile=""

     self.search_dir=''
     self.models_dir=''
     self.results_dir=''
     self.scratch_dir=''

     self.FastaDB=''
     self.results_html=''
     self.len_html_footer=0
 
     self.chain_list=dict([])
     self.model_list=dict([])
     self.ignore_list=[]
     self.include_list=[]
     self.Domains_list=[]

     self.sorted_list=[]
     self.sorted_MR_list=[]
     self.num_MR_models=0

     self.sorted_model_list=[]
     self.sorted_phaser_models=[]
     self.sorted_molrep_models=[]
     self.sorted_refmac_models=[]

     self.model_counter=0
     self.mr_counter=0
     self.ref_counter=0
     self.solution_found=False
     self.soln_model=""
     self.soln_MRprogram=""
     self.soln_list=dict([])
     self.sorted_soln_list=[]

     self.job_end=False
     self.job_time=0.0
     self.start_time=0.0
     self.end_time=0.0

     #self.jobid_array=sets.Set([])
     self.jobid_array=set([])
     self.jobid_dict=dict([])
     self.jobname_dict=dict([])

     self.scores_file=''
     self.pickle_file=''
     self.all_raw_file=''
     self.all_align_file=''

     self.MRNUM=0
     self.ENSMODNUM=0
     self.MRPROGRAM=''

     self.SCOP_file=''
     self.SCOP_results_file=''

     self.reindex_logfile=""
    
     self.AS_JOB_ID=""

     self.TP_JOB_ID=""

     self.FS_JOB_ID=""
     self.FS_input_files=[]
     self.FS_output_files=[]

     self.SS_JOB_ID=""
     self.SS_input_files=[]
     self.SS_output_files=[]

     self.ScS_JOB_ID=""
     self.ScS_input_files=[]
     self.ScS_output_files=[]

     # Downloaded_PDBs is a dictionary used to keep track of the PDB files that
     # have been downloaded. It can be consulted before a download is initiated
     # to see if the file has already been retrieved.
     self.downloaded_PDBs=dict([])

     self.resultsTable=[]
     self.reportTable=[]

   def setctruncate_logfile(self, filename):
     self.ctruncate_logfile=filename

   def setSEQmatchfile(self, SEQ_matchfile):
     self.SEQmatchfile=SEQ_matchfile

   def setSSMmatchfile(self, SSM_matchfile):
     self.SSMmatchfile=SSM_matchfile

   def setNoofSEQHits(self, SEQhits):
     self.no_of_SEQhits=SEQhits

   def setNoofSSMHits(self, SSMhits):
     self.no_of_SSMhits=SSMhits

   def setNoofPQSHits(self, no_of_hits):
     self.no_of_PQShits=no_of_hits


   def setTopMatchPDB(self, topmatch_pdb):
     self.top_match_pdbid=topmatch_pdb

   def setTopMatchChain(self, topmatch_chain):
     self.top_match_chainid=topmatch_chain


   def resetJobid_Array(self):
     #self.jobid_array=sets.Set([])
     self.jobid_array=set([])

   def resetJobid_Dict(self):
     self.jobid_dict=dict([])

   def resetJobName_Dict(self):
     self.jobname_dict=dict([])

   def setSolutionFound(self, solution_found):
      self.solution_found = solution_found

   def setSolutionModel(self, soln_model):
      self.soln_model = soln_model

   def setSolutionMRProgram(self, program):
      self.soln_MRprogram = program


   def setJob_End(self, flag):
      self.job_end = flag 

   def setJob_Time(self, time):
      self.job_time = time 

   def setStartTime(self, time):
      self.start_time = time 

   def setEndTime(self, time):
      self.end_time = time 


   def setScoresFile(self, filename):
      self.scores_file = filename

   def setPickleFile(self, pickle_file):
      self.pickle_file = pickle_file

   def setAllRawFile(self, filename):
      self.all_raw_file = filename

   def setAllAlignFile(self, filename):
      self.all_align_file = filename


   def setMRNUM(self, MRNUM):
      self.MRNUM = MRNUM

   def setENSMODNUM(self, ENSMODNUM):
      self.ENSMODNUM = ENSMODNUM

   def setMRPROGRAM(self, MRPROGRAM):
      self.MRPROGRAM = MRPROGRAM


   def setE_value(self, E_value):
      self.E_value = E_value

   def setEstNoofMols(self, number):
      self.est_no_of_mols = number


   def setSearchDir(self, directory_name):
      self.search_dir = directory_name

   def setModelsDir(self, directory_name):
      self.models_dir = directory_name

   def setResultsDir(self, directory_name):
      self.results_dir = directory_name

   def setScratchDir(self, directory_name):
      if os.path.isdir(directory_name) == False:
         os.mkdir(directory_name)
      self.scratch_dir = directory_name


   def setFastaDB(self, filename):
      self.FastaDB = filename

   def setResultsHTML(self, filename):
      self.results_html = filename 


   def setSCOPFile(self, filename):
      self.SCOP_file = filename

   def setSCOPResultsFile(self, filename):
      self.SCOP_results_file = filename


class SEQ_match:
   """ A class to retrieve and process matches for the target based in the target sequence. """

   def __init__(self):
      self.CHAIN_NAME = ''
      self.CHAIN_id = ''
      self.PDB_id = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def get_Fasta_file(self, init, mstat, target_info, SEQ_matchfile, MRBUMP_SETUP_DIR):
     """ Top level function for retrieving sequence based matches from the OCA service. """
 
     # Set the e value for the SEQ search.
     mstat.setE_value(init.keywords.E_value)
     print "Fasta log message: E value used in Fasta search: %.2e" % mstat.E_value
  
     # Set the fasta DB location
     mstat.setFastaDB(os.path.join(MRBUMP_SETUP_DIR, "pdb_ATOMseqs.txt"))

     # Retrieve the SEQ results.
     f=Fasta_search.Fasta()
     if init.keywords.fasta_local:
        print "Fasta log message: Performing Fasta search locally"
        print "Fasta log message: Fasta DB set to: %s" % mstat.FastaDB
        print ""

        # Set the SEQ results file (text in local case)
        mstat.setSEQmatchfile(SEQ_matchfile + '.txt')
        
        # Perform the search locally
        f.setFastaDB(mstat.FastaDB)
        f.setLogfile(os.path.join(init.search_dir, 'logs', 'fasta_search.log'))
        f.fasta_search_local(target_info.seqfile, mstat.SEQmatchfile, mstat.E_value)

     else:
        sys.stdout.write("Fasta log message: Performing Fasta search using OCA service\n")
        sys.stdout.write("\n")

        # Set the SEQ results file (html in web download case)
        mstat.setSEQmatchfile(SEQ_matchfile + '.html')

        sys.stdout.write("Fasta log message: Writing SEQ results to file:\n   %s\n" % mstat.SEQmatchfile)
        sys.stdout.write("\n")
        
        # Perform the search using the SEQ service
        f.fasta_search_web(target_info.seqfile, mstat.SEQmatchfile, E_value=mstat.E_value)

   def get_Fasta_matches(self, init, mstat, target_info, SEARCHTYPE):
      """ A function to retrive the list of PDB and chain IDs from the SEQ matches file."""

      if SEARCHTYPE == "FASTA":
         # Open the SEQ match file for reading 
         match_file=open(mstat.SEQmatchfile,'r')
         line=match_file.readline()
   
         # this is an attempt to skip the header of the matches file, so
         # as not to get any spurious hits
         while "scores" not in line and line!="":
            if "!! No sequences with E()" in line or "# Hits: 0 (" in line:
               sys.stdout.write("\n")
               sys.stdout.write("##################################################################################\n")
               sys.stdout.write("No matching sequences found in FASTA search with E value = %.3f\n" % init.keywords.E_value)
               sys.stdout.write("Try increasing this value using the EVALUE keyword to MrBUMP\n")
               sys.stdout.write("##################################################################################\n")
               sys.stdout.write("\n")
               break
            line=match_file.readline()
   
    
         while line:
            if '>>' in line[0:2]:
               if init.keywords.fasta_local:
                  code=line[2:8].replace(' ','')
               else:
                  code=string.split(line,'>')[3].replace('</a','')
                  
               # Assign the PDB and chain IDs. If no chain ID set it to 'A'
               PDB_ID=code[0:4].lower()
               print code
               if len(code) == 6:
                  CHAIN_ID=code[5].upper()
               else:
                  CHAIN_ID='A'
             
               self.CHAIN_NAME = PDB_ID + '_' + CHAIN_ID
               mstat.fastaList.append(self.CHAIN_NAME)
            line=match_file.readline()
   
         match_file.close()

         self.no_of_hits=len(mstat.fastaList)
         self.hitList=mstat.fastaList
         source="SEQ"

      if SEARCHTYPE == "HHPRED":
         self.no_of_hits=len(mstat.hhpredList)
         self.hitList=mstat.hhpredList
         source="HHP"

      for chain in self.hitList: 
         CHAIN_ID=chain[5]
         PDB_ID=chain[0:4]
         # Create a new chain object
         c=Chain_struct()
         c.setSource(source)
         c.setMultimerType('MONOMER')
         c.setchainName(chain)
         c.setchainID(CHAIN_ID)
         c.setPDBName(PDB_ID)
        
         # Create the directory structure for this template structure
         c.setWorkingDIR(os.path.join(init.search_dir, 'data', c.chainName))

         if (PDB_ID not in mstat.ignore_list) and (chain not in mstat.SEQhits):
            # Add this chain object to the list of chains
            mstat.chain_list[chain] = c

            os.mkdir(c.working_DIR)
            os.mkdir(os.path.join(c.working_DIR, 'alignments'))
            os.mkdir(os.path.join(c.working_DIR, 'pdb_file'))
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip'))
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr'))
            if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep', 'refine'))
            if "PHASER" in init.keywords.MR_PROGRAM_LIST:
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser', 'refine'))
          
            # Add this chain name to the list of SEQ matches
            mstat.SEQhits.append(chain)
            mstat.no_of_SEQhits = mstat.no_of_SEQhits + 1
            mstat.no_of_hits = mstat.no_of_SEQhits
            if self.debug:
               print "Added chain: " + chain + " to the match list"
         elif PDB_ID in mstat.ignore_list:
            print "Fasta log message: Ignoring chain: %s as it has been excluded from the search" % chain
         else:
            print "Fasta log message: Chain %s already included in list" % chain

   def add_included_chains(self, init, mstat):
      """ A function to include any chains specified by the user in the template model list."""

      if len(mstat.include_list) > 0:
         sys.stdout.write("---------------------------------------\n")        
         sys.stdout.write("Adding chains specified by the user...\n")
         sys.stdout.write("---------------------------------------\n")        
         sys.stdout.write("\n")        

      # Add in the included PDB's if they were not already found
      for id in mstat.include_list:
         
         # Convert the id to the correct format before checking it against the list of downloaded chains.
         PDBcode=string.split(id,"_")[0].lower()
         CHAINcode=string.split(id,"_")[1].upper()
         include_ID=PDBcode + "_" + CHAINcode
       
         # Check this id against the list of chains found in the searches and add it if not already there.
         if include_ID not in mstat.chain_list.keys():

            pdb_id = PDBcode
            chain_id = CHAINcode
            chain = pdb_id + "_" + chain_id

            #chain_id = id[5].upper()
            #pdb_id = id[0:4].lower()

            if self.debug:
               print "Adding chain " + chain + " to the list of search matches."
               print "This chain was not in the fasta results but was selected by user for inclusion."

            c=Chain_struct()
            c.setSource('SEQ')
            c.setMultimerType('MONOMER')
            c.setchainName(chain)
            c.setchainID(chain_id)
            c.setPDBName(pdb_id)
            c.setIncluded(True)

            # Create the directory structure for this template structure
            c.setWorkingDIR(os.path.join(init.search_dir, 'data', c.chainName))

            # Make sure the chain id was not in the ignore list
            if pdb_id not in mstat.ignore_list:
               # Add this chain object to the list of chains
               mstat.chain_list[chain] = c

               os.mkdir(c.working_DIR)
               os.mkdir(os.path.join(c.working_DIR, 'alignments'))
               os.mkdir(os.path.join(c.working_DIR, 'pdb_file'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr'))
               if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep'))
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep', 'refine'))
               if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser'))
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser', 'refine'))

               # Add this chain name to the list of SEQ matches
               mstat.SEQhits.append(chain)
               mstat.no_of_SEQhits = mstat.no_of_SEQhits + 1
               mstat.no_of_hits = mstat.no_of_hits + 1
               if self.debug:
                  print "Added chain: " + chain + " to the match list"
            else:
               sys.stdout.write("User specified chain: Ignoring chain: " + chain + " as it has been excluded from the search\n")
         else:
            if self.debug:
               print "Chain " + include_ID + " was marked for inclusion as a template chain."
               print "This chain was also found in the FASTA/SSM search."
            
            mstat.chain_list[include_ID].setIncluded(True)

      sys.stdout.write("\n")

      sys.stdout.write("Number of templates after user specified chains are included: %d\n" % mstat.no_of_hits)
      sys.stdout.write("\n")

   def add_local_chains(self, init, mstat, target_info):
      """ A function to add chains from local files to the list of potential templates. """

      DB_fail=False

      if self.debug:
         sys.stdout.write("Number of local files specified: %d\n" % len(init.keywords.local_list.keys()))
         sys.stdout.write("\n")        
         count=1
         for id in init.keywords.local_list.keys():
            sys.stdout.write("%d: local id: %s (local file: %s)\n" % (count, id, os.path.split(init.keywords.local_list[id].filename)[1]))        
            count=count+1
         sys.stdout.write("\n")        

      if len(init.keywords.local_list.keys()) > 0:
         sys.stdout.write("---------------------------------------\n")        
         sys.stdout.write("Adding chains from local files...\n")
         sys.stdout.write("---------------------------------------\n")        
         sys.stdout.write("\n")        

         sys.stdout.write("Number of local files specified: %d\n" % len(init.keywords.local_list.keys()))
         sys.stdout.write("\n")        

         # Add the job details to the DB for dbviewer
         if init.keywords.DBOUT:
            try: 
               job_ID=mstat.conn.AddSubJob( \
                   init.ProjectName,init.JobId,
                   "Local_files",
                   "Adding in local PDB files specified by the user to the template list")
   
               #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Local_files")
               #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", "Adding in local PDB files specified by the user to the template list")
               mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
               mstat.conn.AddInputFile(init.ProjectName, job_ID, target_info.seqfile)
               #mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.chain_list[chain].plyala_logfile)
            except:
               DB_fail=True 
               sys.stdout.write("DB error: Could not enter a new record for Locally input files\n")
               sys.stdout.write("\n")
   
      for id in init.keywords.local_list.keys():
         pdb_id = (string.split(id, "_")[0]).lower()
         #chain = pdb_id + "_" + init.keywords.local_list[id].chainID
         chain = id 
         
         if self.debug:
            print "Adding chain " + chain + " to the list of search matches."
            print "This chain comes from the local file specified by the user:"
            print "  %s" % init.keywords.local_list[id].filename
            print ""

         c=Chain_struct()
         c.setSource('LOC')
         c.setMultimerType('MONOMER')
         c.setchainName(chain)
         c.setchainID(init.keywords.local_list[id].chainID)
         c.setPDBName(pdb_id + "_" + init.keywords.local_list[id].filestring)
         c.setIncluded(True)
         c.setRMS(init.keywords.local_list[id].rms)

         # Create the directory structure for this template structure
         c.setWorkingDIR(os.path.join(init.search_dir, 'data', c.chainName))

         # Add this chain object to the list of chains
         mstat.chain_list[chain] = c

         os.mkdir(c.working_DIR)
         os.mkdir(os.path.join(c.working_DIR, 'alignments'))
         os.mkdir(os.path.join(c.working_DIR, 'pdb_file'))
         os.mkdir(os.path.join(c.working_DIR, 'pdbclip'))
         os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr'))
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep'))
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep', 'refine'))
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser'))
            os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser', 'refine'))

         # Copy over the PDB file to the unprocessed folder
         c.setUnprocessedPDBFile(os.path.join(init.search_dir, 'PDB_files', c.PDBName + '.pdb'))
         c.setOriginalPDBFile(init.keywords.local_list[id].filename)
         if os.path.isfile(c.unprocessed_PDBFile) == False:
            shutil.copyfile(init.keywords.local_list[id].filename, c.unprocessed_PDBFile)

         # Add this file to the output files in the dbviewer
         if init.keywords.DBOUT and DB_fail == False:
            mstat.conn.AddInputFile(init.ProjectName, job_ID, init.keywords.local_list[id].filename)
            mstat.conn.AddOutputFile(init.ProjectName, job_ID, c.unprocessed_PDBFile)

         # Add this chain name to the list of SEQ matches
         mstat.SEQhits.append(chain)
         mstat.no_of_SEQhits = mstat.no_of_SEQhits + 1
         mstat.no_of_hits = mstat.no_of_SEQhits

         if self.debug:
            print "Added chain: " + chain + " to the match list"

      if len(init.keywords.local_list.keys()) > 0:
         # Set the status to be finished in the DB
         if init.keywords.DBOUT and DB_fail == False:
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "FINISHED")
         elif DB_fail:
            DB_fail=False

      sys.stdout.write("Fasta log message: Number of matches: %d\n" % mstat.no_of_hits)
      sys.stdout.write("\n")


class SSM_match:
   """ A class to retrieve and process matches for the target based in the structure of the top hit
       in the SEQ search """

   def __init__(self):
      self.CHAIN_NAME = ''
      self.CHAIN_id = ''
      self.PDB_id = ''
      self.hitList=[]

      self.perlExecutable='perl'
      self.ssm_script=''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def setSSMScript(self, script):
      self.ssm_script=script  

   def get_SSM_file(self, init, mstat, ehtpx_id, SSM_matchfile):
     """ A function to retrive SSM XML file from the EBI Webservice. """

     # Set the SSM matchfile variable
     mstat.setSSMmatchfile(SSM_matchfile)

     # Call the webservice (replace with python version)
 
     # Set the command to call the SSM server using the top hit from the FASTA search
     command_line = self.perlExecutable + ' ' + self.ssm_script + ' ' + mstat.top_match_pdbid + ' ' + ehtpx_id

     sys.stdout.write("SSM log: Performing SSM search using EBI SSM server...\n")
     if self.debug: 
        sys.stdout.write("SSM log: Command line set to:\n")
        sys.stdout.write("   " + command_line + "\n")
     sys.stdout.write("\n")

     # Launch SSM
     if os.name == "nt":
        process_args = shlex.split(command_line, posix=False)
        p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)
     else:
        process_args = shlex.split(command_line)
        p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)

     (child_stdout, child_stdin) = (p.stdout, p.stdin)

     child_stdin.close()         

     # Watch the output for successful termination
     out=child_stdout.readline()
     
     # Set the SSM logfile 
     mstat.SSM_resultsfile=os.path.join(init.search_dir, "logs", "ssm_results.log")
     log=open(mstat.SSM_resultsfile, "w")

     while out:
        if self.debug:
            sys.stdout.write(out)
        log.write(out)
        out = child_stdout.readline()

     child_stdout.close()         
     log.close()

   def parse_SSM_results(self, mstat, SSM_resultsfile=""):
      """ Parse the SSM log file for the results of the SSM search. """

      # Open the SSM log file
      if SSM_resultsfile == "":
         SSM_resultsfile=mstat.SSM_resultsfile

      file=open(SSM_resultsfile, "r")
      
      line=file.readline()
      while line:
         if "msdGetResultSet() 2 called successfully" in line:
            res_line=file.readline()
            while res_line:
               if "Column 1 Row:" in res_line:
                  line_split=string.split(res_line)
                  try:
                     mstat.no_of_SSMhits=int(line_split[3])
                  except:
                     raise SSMhitsFailure
                  mstat.SSM_results.append(line_split[6])
               res_line=file.readline()
         line=file.readline()
      
      file.close()

      # Output the results to stdout
      sys.stdout.write("SSM Log: SSM Search completed.\n")
      if mstat.no_of_SSMhits == 0:
         sys.stdout.write("         No results were found for the input PDB ID: %s\n" % mstat.top_match_pdbid)
         sys.stdout.write("\n")
      else:
         if self.debug:
            sys.stdout.write("\n")
            sys.stdout.write("    SSM search found %d hits\n" % mstat.no_of_SSMhits)
            sys.stdout.write("    The results are listed below:\n")
            sys.stdout.write("\n")
            count=1
            for id in mstat.SSM_results:
               sys.stdout.write("%d   %s\n" % (count, id))
               count=count+1
            sys.stdout.write("\n")
      

   def get_SSM_matches(self, init, mstat):
      """ Read the SSM xml file and update the chain dictionary with the new (if any) matches. """

      # Parse the log file from the SSM job to get the matching structures.
      self.parse_SSM_results(mstat)

      for PDB_id in mstat.SSM_results:
         # Temporarily setting the chain ID to A until we figure out how to extract the chain
         # from the SSM results.
         CHAIN_id = 'A'

         CHAIN_NAME = PDB_id + '_' + CHAIN_id 

         # Check that this chain is not already in the list of results
         if mstat.chain_list.has_key(CHAIN_NAME) == False:

            c=Chain_struct()
            c.setSource('SSM')
            c.setMultimerType('MONOMER')
            c.setchainName(CHAIN_NAME)
            c.setchainID(CHAIN_id)
            c.setPDBName(PDB_id)

            # Create the directory structure for this template structure
            c.setWorkingDIR(os.path.join(init.search_dir, 'data', c.chainName))

            # DEV: Remove any chains that are to be ignoreed
            if PDB_id not in mstat.ignore_list:
               mstat.no_of_newSSMhits = mstat.no_of_newSSMhits + 1
               mstat.no_of_hits = mstat.no_of_hits + 1

               os.mkdir(c.working_DIR)
               os.mkdir(os.path.join(c.working_DIR, 'alignments'))
               os.mkdir(os.path.join(c.working_DIR, 'pdb_file'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip'))
               os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr'))
               if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep'))
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep', 'refine'))
               if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser'))
                  os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser', 'refine'))

               # Add this chain object to the list of chains
               mstat.chain_list[CHAIN_NAME] = c

               # Add this chain name to the list of new SSM matches
               mstat.SSMnewhits.append(CHAIN_NAME)
            else:
               sys.stdout.write("SSM Log: Ignoring chain: " + CHAIN_NAME + " as it has been excluded from the search\n")

      if mstat.no_of_newSSMhits > 0:
         sys.stdout.write("SSM Log: Number of new hits in SSM search: %s\n" % mstat.no_of_newSSMhits)
         sys.stdout.write("         New hits found in the SSM search:\n")
         sys.stdout.write("\n")
         count=1
         for id in mstat.SSMnewhits:
            sys.stdout.write("%d   %s\n" % (count,id))
            count=count+1
         sys.stdout.write("\n")
      else:
         sys.stdout.write("SSM Log: No new hits found in SSM search\n")
         sys.stdout.write("\n")


class SCOP_match:
   """ A class to perform a search for individual domains using each of the chains collected so far. """

   def __init__(self):
      self.SCOP_temp_URL=''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
          
   def setDEBUG(self, flag):
      self.debug=flag  

   def setSCOPtempURL(self, filename):
      self.SCOP_temp_URL=filename
    
   def get_SCOP_matches(self, init, mstat, MRBUMP_SETUP_DIR):
      """ A function to collect domains from the chains and create new chain list entries. """ 

      # Set the SCOP parsable database file 
      mstat.setSCOPFile(os.path.join(MRBUMP_SETUP_DIR, 'scop_list.txt'))

      # Set the SCOP logfile
      mstat.setSCOPResultsFile(os.path.join(init.search_dir, "logs", "scop_results.log"))

      # Output to stdout the location of the SCOP results logfile
      sys.stdout.write("SCOP results can be found in the logfile:\n   %s\n" % mstat.SCOP_results_file)
      sys.stdout.write("\n")

      # Open the log file
      log=open(mstat.SCOP_results_file, "w")
     
      log.write("###################################################################\n")
      log.write("####                  SCOP results log file                    ####\n")
      log.write("###################################################################\n")
      log.write("\n")
      log.write("SCOP database file:\n   %s\n" % mstat.SCOP_file)
      log.write("\n")

      # Loop over all the chains in the sorted list and process the domain details
      for chain in mstat.sorted_MR_list:
         domains=SCOP_search.Domain_struct()
         domains.findDomains(mstat.SCOP_file, mstat.chain_list[chain].PDBName)
 
         # Update the log file
         log.write("Looking for domains based on chain %s......\n" % chain)

         # Set the number of domains hits for this chain and altogether
         mstat.chain_list[chain].setNoofDomains(domains.no_of_hits)
         mstat.no_of_SCOPhits = mstat.no_of_SCOPhits + domains.no_of_hits

         if domains.no_of_hits == 0:
            log.write("No domains found for this chain\n")
         else:
            log.write("Number of domains found for this chain: %d\n" % domains.no_of_hits)

         for i in range(domains.no_of_hits):

           # Add the domains to the domains list for this chain
           mstat.chain_list[chain].domain_list.append(domains.sid[i])

           # If this domain is not in the list already, add it, and setup its variables
           if mstat.chain_list[chain].chainID == (domains.sid[i][5:6]).upper() and \
           os.path.isdir(os.path.join(init.search_dir, 'data', domains.sid[i])) == False:

              log.write("Attempting to create file structure for domain: %s\n" % domains.sid[i])

              c = Chain_struct()
              c.setWorkingDIR(os.path.join(init.search_dir, 'data', domains.sid[i]))

              # Set up the directory structure for this chain
              os.mkdir(c.working_DIR)
              os.mkdir(os.path.join(c.working_DIR, 'alignments'))
              os.mkdir(os.path.join(c.working_DIR, 'pdb_file'))
              os.mkdir(os.path.join(c.working_DIR, 'pdbclip'))
              os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr'))
              if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                 os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep'))
                 os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'molrep', 'refine'))
              if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                 os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser'))
                 os.mkdir(os.path.join(c.working_DIR, 'pdbclip', 'mr', 'phaser', 'refine'))

              log.write("Creating the PDB file for this domain...\n")

              # Get the domain ranges
              #domains.getDomainRanges(domains.res_range[i])
              err_code=domains.getDomainCoordinates(domains.sid[i], domains.res_range[i],\
                         mstat.chain_list[chain].PDBFile, os.path.join(c.working_DIR, 'pdb_file'))
        
              if err_code == 0:
                 # Reset the starting residue to 0 if it is negative 
                 #if domains.range_list[0][0] < 0:
                 #   domains.range_list[0][0] = 0
   
                 # Extract the domain sequence from the parent chain sequence
                 #domain_sequence = ''
                 #for j in domains.range_list:
                 #   domain_sequence += mstat.chain_list[chain].chain_sequence[j[0]:j[1]]
                 #c.domain_range_list = domains.range_list
   
                 #Set the rest of the domain parameters including the name of the parent chain
                 c.chainID             = (domains.sid[i][5:6]).upper()
                 c.chainName           = domains.sid[i]
                 c.PDBName             = domains.sid[i][0:4]
                 c.unprocessed_PDBFile = mstat.chain_list[chain].unprocessed_PDBFile
                 c.setOriginalPDBFile(c.unprocessed_PDBFile)
                 c.PDBFile             = os.path.join(c.working_DIR, 'pdb_file', domains.sid[i] +'.pdb')
                 c.setClipModelPDB(c.PDBFile)

                 pdbinfo=PDB_info.PDB_info()
                 c.setChainSequence(pdbinfo.getSequence(c.PDBFile))
                 c.setSeqLength(pdbinfo.sequence_length)
                 c.setNoofRanges(domains.no_of_ranges)
   
                 c.source              = 'SCOP'
                 c.setIncluded(mstat.chain_list[chain].included)
                 c.setParentChain(chain)

                 # Get the PDB header details
                 pdbinfo.getEXPDTA(c.PDBFile)                  
                 c.resolution_high = pdbinfo.resolution_high
                 c.resolution_low = pdbinfo.resolution_low

                 # Add this domain to our list of chains
                 mstat.chain_list[c.chainName]=c
   
                 # Add this domain to the list of domains
                 mstat.Domains_list.append(c.chainName)
   
                 log.write("\n")
                 log.write("*******************************************************************\n")
                 log.write("Name: %s\n" % c.chainName)
                 log.write("Seq Length: %d\n" % c.seqlength)
                 log.write("PDB file:\n   %s\n" % c.pdbclip_modelPDB)
                 log.write("Sequence:\n")
   
                 count=0
                 for i in c.chain_sequence:
                    log.write(i)
                    count =  count + 1
                    if count%80==0:
                       log.write("\n")
                 if len(c.chain_sequence)%80 != 0:
                    log.write("\n")
                     
                 log.write("*******************************************************************\n")
                 log.write("\n")

              else:
                 log.write("SCOP error: There was a problem creating the PDB coordinate file for this domain.\n")
                 # Remove the domain from the domains list for this chain
                 mstat.chain_list[chain].domain_list.remove(domains.sid[i])

           log.write("\n")

      log.write("\n")
      if mstat.no_of_SCOPhits==0:
         log.write("No domains found for any of the top search templates\n")
      else:
         log.write("Total Number of domains found in SCOP search: %d\n" % mstat.no_of_SCOPhits)
      log.close()

class Process_Score:
   """ A class to download and process PDB files and perform Multiple alignment using their sequences.""" 

   def __init__(self):
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def PDB_process(self, init, mstat):
      """ A function to download and process the template PDB files. """

      PDB=PDB_get()
      
      # Download and process the PDB files for the matches
      PDB.download_PDB(init, mstat)  

      if init.keywords.SCOP:
         print ""
         print "-------------------------"
         print "Preparing SCOP PDB files:"
         print "-------------------------"
         print ""
   
         # PDB files for SCOP matches are derived from the parent chain PDB files
         PDB.download_SCOP_PDB(mstat)  

      print ""
      print "-------------------------------"
      print "Processing PDB files (PDBclip):"
      print "-------------------------------"
      print ""

      # Prepare the pdb files and extract any relevant information from their headers
      PDB.getPDBheader_info(mstat)
      PDB.process_PDB(init, mstat)
      #PDB.getPDBinfo(mstat)

   def getPDB_sequences(self, init, mstat, Source):
      """ Get the sequences for each of the Chains in the list."""
       
      if self.debug: 
         print "Extracting sequences from " + mstat.FastaDB +  " for chains in '" + Source + "' search results" 
         print ""

      tmpPDB_file_list=[]
      start_position=0

      gs=Get_sequence_DB.Chain_sequence()
      gs.setPDBseqDB(mstat.FastaDB)

      count=0
      f_DB=open(mstat.FastaDB, "r")
      line=f_DB.readline()
  
      while line:
         if ">" in line:
            if line[6] == " ":
               chain=line[1:6] + "A"
            else: 
               chain=line[1:7]

            if chain in mstat.chain_list.keys():

               gs.get_seq(chain, start_position)
               start_position=gs.file_position

               sequence=gs.sequence

               mstat.chain_list[chain].setChainSequence(sequence)
               mstat.chain_list[chain].setSeqLength(len(sequence))
      
               # Remove the chain if it is too short
               if mstat.chain_list[chain].seqlength < 5:
                  del mstat.chain_list[chain]

         line=f_DB.readline()

      f_DB.close()

      for chain in mstat.chain_list.keys():

         # If the sequence was not found in the fasta DB we will attempt to extract it from the PDB file itself
         if mstat.chain_list[chain].chain_sequence == "":
            if self.debug:
               sys.stdout.write("Sequence for " + chain + " could not be found in " + mstat.FastaDB + "\n")
               sys.stdout.write("Attempting to extract the sequence from the PDB file....\n")
               sys.stdout.write("\n")

            pg=PDB_get()

            # If we have a local PDB file copy it to the tmp location for sequence retrieval
            if mstat.chain_list[chain].source == "LOC":
               shutil.copyfile(mstat.chain_list[chain].unprocessed_PDBFile, \
                  os.path.join(mstat.scratch_dir, "tmpPDB_" + mstat.chain_list[chain].PDBName + ".pdb"))
         
            # Assign and note the name of the temporary PDB file
            #tmpPDB_file = os.path.join(mstat.scratch_dir, "tmpPDB_" + mstat.chain_list[chain].PDBName + ".pdb")
            tmpPDB_file = os.path.join(mstat.search_dir, "PDB_files", mstat.chain_list[chain].PDBName + ".pdb")
            if tmpPDB_file not in tmpPDB_file_list:
               tmpPDB_file_list.append(tmpPDB_file)

            # Attempt to get the sequence from the PDB atom records
            sequence=pg.download_PDBsequence(init, chain, mstat.chain_list[chain].source, tmpPDB_file)

            mstat.chain_list[chain].setChainSequence(sequence)
            mstat.chain_list[chain].setSeqLength(len(sequence))

         if self.debug:
            sys.stdout.write("Sequence for %s:\n" % chain)
            res_count=0
            for x in mstat.chain_list[chain].chain_sequence:
               sys.stdout.write(x)
               res_count = res_count + 1
               if res_count%80 == 0:
                  sys.stdout.write("\n")
            sys.stdout.write("\n\n")

         count=count+1

      if self.debug: 
         sys.stdout.write("\n")
      #else:
         # Remove any temporary PDB files
      #   for file in tmpPDB_file_list:
      #      os.remove(file)

   def alignment(self, list, target_info, init, mstat):
      """ A function to do alignment of the target sequence with the sequences from the 
          search results. """
         
      # Write all of the sequences to a fasta file 
      write=Write_seq_align.Write_align_file()
      list=write.write_all_file(list, target_info, mstat)

      # Check to see that we still have some valid matches
      if mstat.no_of_hits == 0:
         sys.stdout.write("Search log message: Number of valid PDB matches found in searches = 0\n")
         sys.stdout.write("Search log message: Exiting program. Try increasing the e-value in the Fasta search.\n")
         sys.stdout.write("\n")
         sys.exit(0)
      else:
         sys.stdout.write("Search log message: Number of valid PDB matches found in searches = %d\n" % mstat.no_of_hits)
         sys.stdout.write("\n")

      if init.keywords.MAPROGRAM == 'MAFFT':
         # Do the multiple alignment
         align=Align_score.Score()
         align.score(list, init, mstat, mstat.all_raw_file, mstat.all_align_file, 'mafft')
         #align.score(list, init, mstat, mstat.hhpredALNFile, mstat.all_align_file, 'mafft')

      if init.keywords.MAPROGRAM == 'PROBCONS':
         # Do the multiple alignment
         align=Align_score.Score()
         align.score(list, init, mstat, mstat.all_raw_file, mstat.all_align_file, 'probcons')

      if init.keywords.MAPROGRAM == 'T_COFFEE':
         # Do the multiple alignment
         align=Align_score.Score()
         align.score(list, init, mstat, mstat.all_raw_file, mstat.all_align_file, 't_coffee')

      if init.keywords.MAPROGRAM == 'CLUSTALW' or init.keywords.MAPROGRAM == 'CLUSTALW2':
         # Do the multiple alignment
         align=Align_score.Score()
         align.score(list, init, mstat, mstat.all_raw_file, mstat.all_align_file, 'clustalw')

      # Set the score and seqID for each chain
      for chain in mstat.chain_list.keys():
         CHAIN = mstat.chain_list[chain]
         CHAIN.setScore(CHAIN.alignment.score)
         CHAIN.setseqID(CHAIN.alignment.seqID)
         CHAIN.setAlignLength(CHAIN.alignment.align_len)
         mstat.chain_list[chain] = CHAIN
  
   def get_top_hit(self, list, init, mstat):
      """ A function to scan the sequence alignment scores for the hits and pick out the highest """
    
      raw_list=dict([])     
 
      # Set up a dictionary of the scores and chain IDs
      for chain in list:
          
         CHAIN=mstat.chain_list[chain]
         raw_list[CHAIN.chainName] = CHAIN.alignment.score
     
      # Call the sort class to sort the raw dictionary
      s=Sort_dict.Sort_dict()
      mstat.sorted_list=s.sort(raw_list, 'HIGHEST')

      # Assign some parameters related to the top hit
      # Pick out the top hit for the SSM search to work from. If the top hit is a local file
      # keep picking the next one until a non-local result is found
      top_hit_chainID = mstat.sorted_list[0][0]
      if init.keywords.locfile_count < len(mstat.sorted_list):
         i=0
         while "loc" in top_hit_chainID[0:3]:
            i=i+1
            top_hit_chainID = mstat.sorted_list[i][0]
      else:
         init.keywords.SSM = False
         sys.stdout.write("SSM search will not be used as there are only local files specified\n")
         sys.stdout.write("\n")

      # Set the top hit chain and PDB IDs 
      mstat.setTopMatchChain(mstat.chain_list[top_hit_chainID].chainName)
      mstat.setTopMatchPDB(mstat.chain_list[top_hit_chainID].PDBName)

   def prune_list(self, mstat):
      """ A function to reduce the chain list for model preparation and MR. """

      count = 0

      # Add any included models to the list. This comes first so that these will be processed first
      for chain in mstat.sorted_list:
         if mstat.chain_list[chain[0]].included == True:
            mstat.sorted_MR_list.append(chain[0])
            count = count + 1 

      # Add the top hits from the searches to the list
      for chain in mstat.sorted_list:
         if count < mstat.MRNUM and chain[0] not in mstat.sorted_MR_list:
            mstat.sorted_MR_list.append(chain[0])
            count = count + 1 

      mstat.num_MR_models=len(mstat.sorted_MR_list)

   def print_list(self, mstat):
      """ A function to print out all of the matches from all searches. """ 

      print ""
      print "#####################################################################"
      print "#####              Template Model Search Results                #####" 
      print "#####################################################################"
      print ""
           
      print "CHAIN_ID \t SCORE \t SEQID \t SOURCE"
      print "--------------------------------------------"

      for chain in mstat.sorted_list: 
         if len(chain[0]) == 6:
            # Append a ' ' to the chain ID to get everything to lineup correctly
            chain_id = chain[0] + ' '  
         else:
            chain_id = chain[0]
         print "%s \t %.3f \t %.3f \t %s" % \
            (chain_id, mstat.chain_list[chain[0]].alignment.score, \
                       mstat.chain_list[chain[0]].alignment.seqID, \
                       mstat.chain_list[chain[0]].source)
      print "" 

   def re_sort_MR_list(self, mstat):
      """ A function to create the new sorted list including SCOP results. """

      # Reset the sorted_MR_list to be empty
      mstat.sorted_MR_list = []

      # We want to include all the possible domains of the sorted_MR list in the new list so there 
      # is no pruning of the list.
      for chain in mstat.sorted_list:
         if mstat.chain_list[chain[0]].included == True:
            mstat.sorted_MR_list.append(chain[0])

      for chain in mstat.sorted_list:
         if mstat.chain_list[chain[0]].included == False:
            mstat.sorted_MR_list.append(chain[0])
      mstat.num_MR_models=len(mstat.sorted_MR_list)

   def print_pruned_list(self, mstat):
      """ A function to print out the pruned list of search templates (including domains). """ 

      print ""
      print "#####################################################################"
      print "#####      Sorted list of templates to be prepared for MR       #####" 
      print "#####################################################################"
      print ""
           
      print "CHAIN_ID \t SCORE \t SEQID \t SOURCE"
      print "--------------------------------------------"

      for chain in mstat.sorted_MR_list: 
         if len(chain) == 6:
            # Append a ' ' to the chain ID to get everything to lineup correctly
            chain_id = chain + ' '  
         else:
            chain_id = chain
         print "%s \t %.3f \t %.3f \t %s" % \
            (chain_id, mstat.chain_list[chain].alignment.score, \
                       mstat.chain_list[chain].alignment.seqID, \
                       mstat.chain_list[chain].source)
      print "" 


class PDB_get: 
   """ A class to handle downloading and initial processing of the PDB files for each of the 
       template structures. """ 
   
   def __init__(self):
      if os.name == "nt":
         self.pdbsetEXE       = os.path.join(os.environ['CBIN'], 'pdbset.exe')
         self.pdbcurEXE       = os.path.join(os.environ['CBIN'], 'pdbcur.exe')
         self.coord_formatEXE = os.path.join(os.environ['CBIN'], 'coord_format.exe')
      else:
         self.pdbsetEXE       = os.path.join(os.environ['CBIN'], 'pdbset')
         self.pdbcurEXE       = os.path.join(os.environ['CBIN'], 'pdbcur')
         self.coord_formatEXE = os.path.join(os.environ['CBIN'], 'coord_format')

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      if os.name == "nt":
         self.unzipEXE = "7z x -y" 
      else:
         self.unzipEXE = "gunzip -f" 

   def setDEBUG(self, flag):
      self.debug=flag  

   def download_PDBsequence(self, init, chain, source, tmpPDB_file):
      """ A function to download a single PDB. Used as backup for extracting 
          sequences in the getPDB_sequences function. 
          Returns: sequence (string)"""
 
      # Make a note of the chain PDB code and CHAIN identifier

      pdb_id=string.split(chain, "_")[0].lower()
      chain_id=string.split(chain, "_")[1].upper()

      # Catch for when we want to use the entire contents of the PDB. Set chain_id to A to get the first sequence.
      # Note that this a quick fix for HAMMER and needs to be fixed for non-HAMMER occurances. All sequences should be pulled out
      # in that case.
      if chain_id == "ALL":
         chain_id="A"

      # Some other local variables
      sequence = ''
      pdb_saved = False
      
      # Download the PDB if it is not already saved
      if os.path.isfile(tmpPDB_file) == False:
     
      # Call the class to download the PDB for this sequence
         dPDB=PDB_download.DownloadPDB()
         if init.localPDBmirror:
            dPDB.getlocal_PDB(init.keywords.PDBLOCAL, pdb_id, tmpPDB_file)
         else:
            dPDB.download_PDB(init, pdb_id, tmpPDB_file)
      # Check to see if it successfully retrieved the file
         if dPDB.success == True:
            pdb_saved = True
      else:
         pdb_saved = True

      # We need to catch the cases where the PDB file is a local specified file
      if source == "LOC":
         pdb_saved = True

      # Extract the chain sequence from the PDB coordinates
      if pdb_saved == True:
         info=PDB_info.PDB_info()
         sequence=info.getSequence(tmpPDB_file, chain_id)
      else:
         sys.stdout.write("Sequence retrival error: Error retrieving PDB for %s - could not be found on servers.\n" % pdb_id)
         sys.stdout.write("\n")
      
      return sequence

   def download_PDB(self, init, mstat):
      """ A function to download the PDB structure files."""
  
      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
           
         if mstat.chain_list[chain].source != "SCOP":

            keep_chain = False
            CHAIN = mstat.chain_list[chain] 
         
            # Assign the location of the PDB file for this chain
            CHAIN.setUnprocessedPDBFile(os.path.join(init.search_dir, 'PDB_files', CHAIN.PDBName + '.pdb'))
            CHAIN.setOriginalPDBFile(os.path.join(init.search_dir, 'PDB_files', CHAIN.PDBName + '.pdb'))
               
            if self.debug: 
               sys.stdout.write("PDB Download log: Chain:" + chain + "\n")

            # Check to see if this file is in the folder specified by the user at the start of the job
            if init.keywords.PDBDIR != "" and os.path.isfile(os.path.join(init.keywords.PDBDIR, CHAIN.PDBName + ".pdb")):
               shutil.copy(os.path.join(init.keywords.PDBDIR, CHAIN.PDBName + ".pdb"), CHAIN.unprocessed_PDBFile)
               if self.debug:
                  sys.stdout.write("PDB Download log: " + CHAIN.PDBName + ".pdb found in user specified PDB direcrory\n")
                  sys.stdout.write("\n")

            # Download (if necessary) the PDB structure file for this chain
            elif os.path.isfile(CHAIN.unprocessed_PDBFile):
               sys.stdout.write("PDB Download log: " + CHAIN.PDBName + ".pdb has already been downloaded and saved at:\n  %s\n" \
                                % CHAIN.unprocessed_PDBFile)
               sys.stdout.write("\n")
               mstat.chain_list[chain] = CHAIN

            # Otherwise download the PDB file from one of the online servers
            else:
               # Call the class to download the PDB for this sequence
               dPDB=PDB_download.DownloadPDB()
               if init.localPDBmirror:
                  dPDB.getlocal_PDB(init.keywords.PDBLOCAL, CHAIN.PDBName, CHAIN.unprocessed_PDBFile)
               else:
                  dPDB.download_PDB(init, CHAIN.PDBName, CHAIN.unprocessed_PDBFile)
               # Check to see if it successfully retrieved the file
               if dPDB.success == True:
                  keep_chain = True
               else:
               # Remove the chain folder and all its subfolders if we are running in non-debug mode
                  if self.debug == False:
                     shutil.rmtree(mstat.chain_list[chain].working_DIR)
                  else:
                     sys.stdout.write("PDB download log: Error retrieving PDB for %s - could not be found at server\n" % CHAIN.PDBName)
                     sys.stdout.write("Removing this entry from the chain list\n")
                     sys.stdout.write("\n")
                  del mstat.chain_list[chain]
                  keep_chain = False
                  if chain in mstat.sorted_MR_list:
                     sys.stdout.write("removing %s from the MR list\n" % chain) 
                     sys.stdout.write("\n")
                     mstat.sorted_MR_list.remove(chain)

                     # Decrease the number of hits by 1 
                     mstat.num_MR_models = mstat.num_MR_models - 1
               # Re-assign the chain to the stored verion
               if keep_chain == True:
                  if self.debug:
                     sys.stdout.write("PDB download log: Downloading: " + CHAIN.PDBName + ".pdb. Saved at:\n " + CHAIN.unprocessed_PDBFile + "\n")
                     sys.stdout.write("\n")
                  mstat.chain_list[chain] = CHAIN

   def download_single_PDB(self, PDB_ID, local_file, PDBDIR=""):
      """ A function to download a single PDB structure file given a PDB ID."""
  
      pdb_saved = False

      # Check to see if this file is in the folder specified by the user at the start of the job
      if PDBDIR != "" and os.path.isfile(os.path.join(PDBDIR, PDB_ID + ".pdb")):
         shutil.copy(os.path.join(PDBDIR, PDB_ID + ".pdb"), local_file)
         if self.debug:
            sys.stdout.write("PDB Download log: " + PDB_ID + ".pdb found in user specified PDB direcrory\n")
            sys.stdout.write("\n")

      # Download the PDB structure file and save it to local_file
      elif os.path.isfile(local_file):
         sys.stdout.write("PDB Download log (s): " + PDB_ID + ".pdb has already been downloaded and saved at:\n  %s\n" \
                          % local_file)
         sys.stdout.write("\n")

      else:
         # Call the class to download the PDB for this sequence
         dPDB=PDB_download.DownloadPDB()
         if init.localPDBmirror:
            dPDB.getlocal_PDB(init.keywords.PDBLOCAL, PDB_ID, local_file)
         else:
            dPDB.download_PDB(init, PDB_ID, local_file)
         # Check to see if it successfully retrieved the file
         if dPDB.success == True:
            pdb_saved = True
         else:
            sys.stdout.write("PDB download log: Error retrieving PDB for %s - could not be found at server\n" % PDB_ID) 
            sys.stdout.write("\n")
            pdb_saved = False

         # Re-assign the chain to the stored verion
         if pdb_saved == True:
            if self.debug:
               sys.stdout.write("PDB download log (s): Downloading: " + PDB_ID + ".pdb. Saved at: \n " + local_file + "\n")
               sys.stdout.write("\n")
            mstat.downloaded_PDBs[PDB_ID]=local_file

   def download_SCOP_PDB(self, mstat):
      """ A function to prepare the PDB structure files for the SCOP results."""
  
      for chain in mstat.sorted_MR_list:
         if mstat.chain_list[chain].source == "SCOP":

            keep_chain = False
            CHAIN = mstat.chain_list[chain]
            # Create a keyword line for pdbcur
            pc_key =  'lvres /1/' + CHAIN.chainID + '/' + `CHAIN.domain_range_list[0][0]` + '-' + `CHAIN.domain_range_list[-1][1]` + '\n'
 
            # Create a keyword line for pdbcur to remove the "gap" residues
            if CHAIN.no_of_ranges > 1:
               for i in range(CHAIN.no_of_ranges - 1):
                  pc_key +=  'delres /1/' + CHAIN.chainID + '/' + `CHAIN.domain_range_list[i][1]+1` \
                             + '-' + `CHAIN.domain_range_list[i+1][0]-1` + '\n'
 
            # Finish the key file for pdbcur
            pc_key += 'end'
 
            if self.debug:
               print "SCOP: Pdbcur keywords for " + CHAIN.chainName + ":"
               print ""
               print pc_key
               print "      Output PDB: " + CHAIN.PDBFile
               print ""
 
            # Run pdbcur to extract domain residues
            ### Place choice of paths here ###
            ### This assumes original PDB file in current directory

            if os.path.isfile(CHAIN.unprocessed_PDBFile) == False:
              
               if self.debug:
                  print "SCOP: Unprocessed PDB file not found for chain: " + CHAIN.chainName 
                  print "      Downloading from: " + init.download_urls["EBI"].url
 
               CHAIN.setUnprocessedPDBFile(os.path.join(init.search_dir, "PDB_files", CHAIN.PDBName + ".pdb"))
               CHAIN.setOriginalPDBFile(os.path.join(init.search_dir, "PDB_files", CHAIN.PDBName + ".pdb"))

               # Call the class to download the PDB for this sequence
               dPDB=PDB_download.DownloadPDB()
               if init.localPDBmirror:
                  dPDB.getlocal_PDB(init.keywords.PDBLOCAL, CHAIN.PDBName, CHAIN.unprocessed_PDBFile)
               else:
                  dPDB.download_PDB(init, CHAIN.PDBName, CHAIN.unprocessed_PDBFile)
               # Check to see if it successfully retrieved the file
               if dPDB.success == True:
                  keep_chain = True
               # Otherwise, remove the chain and its directories
               else:
                  if self.debug == False:
                     shutil.rmtree(mstat.chain_list[chain].working_DIR)
                  else:
                     sys.stdout.write("SCOP: Error retrieving PDB for %s - could not be found at server\n" % CHAIN.PDBName)
                     sys.stdout.write("      Removing this entry from the chain list\n")
                  del mstat.chain_list[chain]
                  keep_chain = False

            termination=False
            if os.path.isfile(CHAIN.unprocessed_PDBFile):

               # Set the command line
               command_line = self.pdbcurEXE + ' xyzin ' + CHAIN.unprocessed_PDBFile + ' xyzout ' + CHAIN.PDBFile
         
               # Launch Pdbcur
               if os.name == "nt":
                  process_args = shlex.split(command_line, posix=False)
                  p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                         stdout = subprocess.PIPE)
               else:
                  process_args = shlex.split(command_line)
                  p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                         stdout = subprocess.PIPE)

               (child_stdout, child_stdin) = (p.stdout, p.stdin)

               child_stdin.write(pc_key)
               child_stdin.close()         

               # Watch the output for successful termination
               out=child_stdout.readline()
               pc_log=out
               while out:
                  if 'Normal termination' in out:
                     termination=True

                     # Replace the unprocessed PDB with the PDBcur one to allow for processing later on
                     shutil.copy(CHAIN.PDBFile, CHAIN.unprocessed_PDBFile)
                     os.remove(CHAIN.PDBFile)

                  out = child_stdout.readline()
                  pc_log += out

               child_stdout.close()         

            else:
               print "SCOP PDB creation: Input PDB:\n  " + CHAIN.unprocessed_PDBFile + "\ncould not be found for chain: " + CHAIN.chainName
               pc_log = "Job not started due to missing XYZIN PDB"
 
            if not termination:
               print "SCOP log message: pdbcur failed for %s" % CHAIN.chainName 
               if self.debug:
                  print "Logfile:"
                  print pc_log
               if CHAIN.chainName in mstat.sorted_MR_list:
                  print "removing %s from the MR list" % CHAIN.chainName 
                  mstat.sorted_MR_list.remove(CHAIN.chainName)

          	  # Decrease the number of hits by 1 
                  mstat.num_MR_models = mstat.num_MR_models - 1

 
            # Re-assign the chain to the stored verion
            if keep_chain == True:
               mstat.chain_list[chain] = CHAIN 

 
   def process_PDB(self, init, mstat):
      """ A function to process the PDB files using pdbset, coord_format and pdbcur. """
  
      print ""
      print "-------------"       
      print "Process PDBs"
      print "-------------"       
      print ""
 
      remove_list=[]
      DB_fail=False
 
      # Add the job details to the DB for dbviewer
      if init.keywords.DBOUT:
         try: 
            job_ID=mstat.conn.AddSubJob( \
                init.ProjectName,init.JobId,
                "Process_PDB_Files",
                "Initial processing of the PDB files before model preparation")

            #mstat.conn.SetData(init.ProjectName, job_ID,"TASKNAME", "Process_PDB_files")
            #mstat.conn.SetData(init.ProjectName, job_ID,"TITLE", "Initial processing of the PDB files before model preparation")
            mstat.conn.SetData(init.ProjectName, job_ID,"STATUS", "RUNNING")
            #mstat.conn.SetLogfile(init.ProjectName, job_ID, mstat.chain_list[chain].plyala_logfile)
         except:
            DB_fail=True 
            sys.stdout.write("DB error: Could not enter a new record for Locally input files\n")
            sys.stdout.write("\n")
   
      #for chain in mstat.chain_list.keys():
      for chain in mstat.sorted_MR_list:
           
         CHAIN = mstat.chain_list[chain] 

         if self.debug:
            sys.stdout.write("Processing file: " + CHAIN.PDBName + ".pdb, chain: " + CHAIN.chainID + "\n")
            sys.stdout.write("-----------------------------------------------\n")
 
         CHAIN.setPDBFile(os.path.join(CHAIN.working_DIR, 'pdb_file', CHAIN.chainName + '.pdb'))
         CHAIN.setClipModelPDB(CHAIN.PDBFile)
   
         p=PDBClip.PDBClip()
         p.run(CHAIN.unprocessed_PDBFile, CHAIN.PDBFile, CHAIN.chainID, os.path.join(CHAIN.working_DIR, 'pdbclip'), LITE=init.keywords.LITE)
  
         # Test the ATOM records Sequence to see if it is the same as the one we extracted from the
         # parent chain sequence.
         if self.debug and CHAIN.source == "SCOP":
            seq=PDB_info.PDB_info()
            seq.getSequence(CHAIN.PDBFile)
            if seq.ATOMsequence != CHAIN.chain_sequence:
               sys.stdout.write(seq.ATOMsequence + "\n")
               sys.stdout.write(CHAIN.chain_sequence + "\n")
               sys.stdout.write("SCOP: Atom sequence differs from extracted sequence for:\n    %s\n" % CHAIN.chainName)

         # Re-assign the chain to the stored verion
         mstat.chain_list[chain] = CHAIN 

####################

      # Remove the chains from the list that have failed during processing
#      print remove_list
#      for chain in remove_list:
#         if self.debug:
#            sys.stdout.write("PDB Processing log: Removing chain: " + chain + " as an error was encountered during the processing step\n")
#            sys.stdout.write("\n")
#      print ">>>>>>>>>>>>>>>", chain
#      print mstat.chain_list[chain]
         
#         del mstat.chain_list[chain]
#         if chain in mstat.sorted_MR_list:
#            print "removing %s from the MR list" % chain 
#            mstat.sorted_MR_list.remove(chain)
#            # Decrease the number of hits by 1 
#            mstat.num_MR_models = mstat.num_MR_models - 1
#      sys.exit()

      # If the number of hits is == 0 then report it and exit
      if mstat.num_MR_models == 0:
         sys.stdout.write("PDB Processing log: Number of valid search models after PDB processing = 0\n") 
         sys.stdout.write("PDB Processing log: Program will exit. Try increasing the number of models to be used in MR\n") 
         sys.stdout.write("\n") 
	 sys.exit(0)
      else:
         sys.stdout.write("PDB Processing log: Number of valid search models after PDB processing = %d\n" % mstat.num_MR_models) 
         sys.stdout.write("\n") 

   def getPDBheader_info(self, mstat):
     """ Extract any relevant header information from the unprocessed PDB files. """
  
     # Loop over all models and find the chain identifier. If not set then set to 'A'
     for chain in mstat.sorted_MR_list:
    
           CHAIN = mstat.chain_list[chain]
    
           # If the PDB exists then extract information for this chain
           if os.path.isfile(CHAIN.unprocessed_PDBFile):
       
              # Call the PDB_info class to get the sequence from the structure file
              info=PDB_info.PDB_info()
   
              # Record the experimental data string
              expdata=info.getEXPDTA(CHAIN.unprocessed_PDBFile)
   
              # Set the CHAIN variables
              CHAIN.setEXPDATA(expdata)
              CHAIN.resolution_high = info.resolution_high
              CHAIN.resolution_low = info.resolution_low
            
              # Check for NMR
              if 'NMR' in CHAIN.expdata:
                 print CHAIN.chainName + " is an NMR model" 
                 print "Separating out the first Model from the PDB file..."
                 print ""
 
                 # Call the NMR split function to split out the first model
                 nmr=split_NMR.Split_NMR()
                 nmr.setPDBfile(CHAIN.unprocessed_PDBFile)

                 # Read and write out the details of the first MODEL to a new PDB file
                 nmr.read_PDB(1)
                 nmr.write_models(1)
 
                 # Replace the unprocessed PDB file with the new one 

                 # Check that the file doesn't exist already
                 if os.path.isfile(CHAIN.unprocessed_PDBFile):
                    os.remove(CHAIN.unprocessed_PDBFile)

                 #os.rename(nmr.out_PDBname[0], CHAIN.unprocessed_PDBFile)
                 shutil.move(nmr.out_PDBname[0], CHAIN.unprocessed_PDBFile)
            
              mstat.chain_list[chain] = CHAIN
   
           # Otherwise, report an error and remove this model from the chain list
           else:
              if self.debug:
                 print ""
                 print "PDB Processing log: Model " + mstat.chain_list[chain].chainName + \
   	         " - Could not find the unprocessed PDB file for this model."
                 print ""
   
              # Remove it from the list and delete the data directory entry
              if self.debug == False:
                 shutil.rmtree(mstat.chain_list[chain].working_DIR, True)
              del mstat.chain_list[chain] 
              if chain in mstat.sorted_MR_list:
                 print "removing %s from the MR list" % chain 
                 mstat.sorted_MR_list.remove(chain)
   
	         # Decrease the number of hits by 1 
                 mstat.num_MR_models = mstat.num_MR_models - 1

      
   def getPDBinfo(self, mstat):
     """ Extract any relevant information from the PDB files. """
  
     # Loop over all models and find the chain identifier. If not set then set to 'A'
     for chain in mstat.sorted_MR_list:
    
           CHAIN = mstat.chain_list[chain]
    
           # If the PDB exists then extract information for this chain
           if os.path.isfile(CHAIN.PDBFile):
       
              # Call the PDB_info class to get the sequence from the structure file
              info=PDB_info.PDB_info()
   
              # Record the SEQRES and individual chain sequences and the experimental data string
              sequence=info.getSEQRES(CHAIN.PDBFile, CHAIN.chainID)
              chain_sequence=info.getSequence(CHAIN.PDBFile, CHAIN.chainID)
   
              # Set the CHAIN variables
              CHAIN.setSequence(sequence)
              CHAIN.setChainSequence(chain_sequence)
              CHAIN.setSeqLength(int(len(chain_sequence)))

              # Get the PDB header details
              info.getEXPDTA(CHAIN.PDBFile)                  
              c.resolution_high = info.resolution_high
              c.resolution_low = info.resolution_low

              # Test for a ligitemet chain length
              if CHAIN.seqlength <= 5:
                 
                 # if the sequence length is too short, remove that particular chain from the list
                 if self.debug == False:
                    shutil.rmtree(CHAIN.working_DIR)
                 else:
                    print "Removing template " + CHAIN.chainName + " from the list as it has less than 6 Residues"
                 del mstat.chain_list[chain] 
                 if chain in mstat.sorted_MR_list:
                    print "removing %s from the MR list" % chain 
                    mstat.sorted_MR_list.remove(chain)
   
	            # Decrease the number of hits by 1 
                    mstat.num_MR_models = mstat.num_MR_models - 1

              else:
                 mstat.chain_list[chain] = CHAIN
   
           # Otherwise, report an error and remove this model from the chain list
           else:
              if self.debug:
                 print ""
                 print "PDB Processing log: Model " + mstat.chain_list[chain].chainName + \
                  " - Could not find the PDB file for this model."
                 print ""
   
              # Remove it from the list and delete the data directory entry
   
              #shutil.rmtree(mstat.chain_list[chain].working_DIR, True)
              #del mstat.chain_list[chain] 
      
