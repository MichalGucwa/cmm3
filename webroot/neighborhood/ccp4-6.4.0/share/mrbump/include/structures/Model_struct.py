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
# Setup scripts for the MR pipeline 
# Ronan Keegan 21/12/04

import os, sys, string
import shutil
import smartie


class Models_struct:
   """ A class structure to hold model details. """
   
   def __init__(self):
      self.chain_source=''
      self.source=''
      self.PDBName=''
      self.seqID=[]
      self.rms=[]

      self.num_mols_found=0
      self.num_per_ensem=1
      self.number_mols=1
      self.number_domains=1
      self.resolution=None

      self.name=''
      self.type=''
      self.model_info_string=''
      self.model_directory=''
      self.type_extension='pdb'
      self.multi_type='HOMO'
      self.PDBfile=[]

      self.resolution_high=0.0
      self.resolution_low=0.0

      self.MR_jobID=0
      self.MR_job_number=1
      self.MRPROGRAM=''
      self.Refinement_program=''

      self.marginal_solution_MOLREP=False
      self.good_solution_MOLREP=False
      self.poor_solution_MOLREP=False
      self.solution_type_MOLREP="NA"

      self.marginal_solution_PHASER=False
      self.good_solution_PHASER=False
      self.poor_solution_PHASER=False
      self.solution_type_PHASER="NA"

      self.refinement_HKLIN=""
      self.enant_solution=False

      self.phaser_smartie_log=None

      #self.phaser_keywords=dict([])
      self.phaser_submitted=False
      self.phaser_keywords=[]
      self.phaser_PDBfile=''
      self.phaser_MTZfile=''
      self.phaser_jobname=''
      self.phaser_keyfile=''
      self.phaser_scriptfile=''
      self.phaser_jobID=0
      self.phaser_logfile=''
      self.phaser_solnfile=''
      self.phaser_LLG_score=0.0
      self.phaser_Zscore=0.0
      self.phaser_summary=''
      self.phaser_soln_spacegroup=""

      self.molrep_smartie_log=None

      self.molrep_keywords=dict([])
      self.molrep_submitted=False
      self.molrep_PDBfile=''
      self.molrep_MTZfile=''
      self.molrep_jobname=''
      self.molrep_keyfile=''
      self.molrep_scriptfile1=''
      self.molrep_scriptfile2=''
      self.molrep_RFfile=''
      self.molrep_jobID=0
      self.molrep_logfile=''
      self.molrep_solnfile=''
      self.molrep_Corr=0.0
      self.molrep_Rfac=0.0
      self.molrep_summary=''

      ############ Refmac Rigid Body run parameters ############

      self.refmacRB_molrep_smartie_log=None
      self.refmacRB_phaser_smartie_log=None

      self.refmacRB_molrep_keywords=dict([])
      self.refmacRB_phaser_keywords=dict([])

      self.refmacRB_molrep_PDBfile=''
      self.refmacRB_molrep_MTZINfile=''
      self.refmacRB_molrep_MTZOUTfile=''
      self.refmacRB_molrep_jobname=''
      self.refmacRB_molrep_keyfile=''
      self.refmacRB_molrep_jobID=0
      self.refmacRB_molrep_logfile=''
      self.refmacRB_molrep_initRfact=1.0
      self.refmacRB_molrep_finlRfact=1.0
      self.refmacRB_molrep_initRfree=1.0
      self.refmacRB_molrep_finlRfree=1.0
      self.refmacRB_molrep_summary=''

      self.refmacRB_phaser_PDBfile=''
      self.refmacRB_phaser_MTZINfile=''
      self.refmacRB_phaser_MTZOUTfile=''
      self.refmacRB_phaser_jobname=''
      self.refmacRB_phaser_keyfile=''
      self.refmacRB_phaser_jobID=0
      self.refmacRB_phaser_logfile=''
      self.refmacRB_phaser_initRfact=1.0
      self.refmacRB_phaser_finlRfact=1.0
      self.refmacRB_phaser_initRfree=1.0
      self.refmacRB_phaser_finlRfree=1.0
      self.refmacRB_phaser_summary=''

      ############ Refmac Restrained run parameters ############

      self.refmac_molrep_smartie_log=None
      self.refmac_phaser_smartie_log=None

      self.refmac_molrep_keywords=dict([])
      self.refmac_phaser_keywords=dict([])

      self.refmac_molrep_PDBfile=''
      self.refmac_molrep_MTZINfile=''
      self.refmac_molrep_MTZOUTfile=''
      self.refmac_molrep_jobname=''
      self.refmac_molrep_keyfile=''
      self.refmac_molrep_jobID=0
      self.refmac_molrep_logfile=''
      self.refmac_molrep_initRfact=1.0
      self.refmac_molrep_finlRfact=1.0
      self.refmac_molrep_initRfree=1.0
      self.refmac_molrep_finlRfree=1.0
      self.refmac_molrep_summary=''

      self.refmac_phaser_PDBfile=''
      self.refmac_phaser_MTZINfile=''
      self.refmac_phaser_MTZOUTfile=''
      self.refmac_phaser_jobname=''
      self.refmac_phaser_keyfile=''
      self.refmac_phaser_jobID=0
      self.refmac_phaser_logfile=''
      self.refmac_phaser_initRfact=1.0
      self.refmac_phaser_finlRfact=1.0
      self.refmac_phaser_initRfree=1.0
      self.refmac_phaser_finlRfree=1.0
      self.refmac_phaser_summary=''

      self.buccaneer_molrep_directory=''
      self.buccaneer_molrep_PDBOUTfile=''
      self.buccaneer_molrep_PDBrefinedfile=''
      self.buccaneer_molrep_MTZrefinedfile=''
      self.buccaneer_molrep_res_built=0
      self.buccaneer_molrep_completeness=0.0
      self.buccaneer_molrep_initRfact=1.0
      self.buccaneer_molrep_finalRfact=1.0
      self.buccaneer_molrep_initRfree=1.0
      self.buccaneer_molrep_finalRfree=1.0

      self.buccaneer_phaser_directory=''
      self.buccaneer_phaser_PDBOUTfile=''
      self.buccaneer_phaser_PDBrefinedfile=''
      self.buccaneer_phaser_MTZrefinedfile=''
      self.buccaneer_phaser_res_built=0
      self.buccaneer_phaser_completeness=0.0
      self.buccaneer_phaser_initRfact=1.0
      self.buccaneer_phaser_finalRfact=1.0
      self.buccaneer_phaser_initRfree=1.0
      self.buccaneer_phaser_finalRfree=1.0

      self.arpwarp_molrep_directory=''
      self.arpwarp_molrep_PDBOUTfile=''
      self.arpwarp_molrep_MTZOUTfile=''
      self.arpwarp_molrep_res_built=0
      self.arpwarp_molrep_completeness=0.0
      self.arpwarp_molrep_initRfact=1.0
      self.arpwarp_molrep_finalRfact=1.0
      self.arpwarp_molrep_initRfree=1.0
      self.arpwarp_molrep_finalRfree=1.0

      self.arpwarp_phaser_directory=''
      self.arpwarp_phaser_PDBOUTfile=''
      self.arpwarp_phaser_MTZOUTfile=''
      self.arpwarp_phaser_res_built=0
      self.arpwarp_phaser_completeness=0.0
      self.arpwarp_phaser_initRfact=1.0
      self.arpwarp_phaser_finalRfact=1.0
      self.arpwarp_phaser_initRfree=1.0
      self.arpwarp_phaser_finalRfree=1.0

      self.shelxe_molrep_PDBfile=''
      self.shelxe_molrep_CCscore=0.0

      self.shelxe_phaser_PDBfile=''
      self.shelxe_phaser_CCscore=0.0

      self.acorn_logfile=""
      self.acorn_MTZOUTfile=""
      self.acorn_XYZINfile=""
      self.acorn_cc_values=0.0
      self.acorn_cycles=0

      self.cpirate_MTZfile=""
      self.cpirate_logfile=""
      self.cpirate_cmdfile=""

      self.bucc_ref_logfile=""
      self.bucc_ref_cmdfile=""
      self.bucc_MTZINfile=""
      self.bucc_MTZOUTfile=""
      self.bucc_refmac_PDBOUTfile=""

      self.mr_pdb_sum_logfile=''
      self.pdbcur_sum_logfile=''

   def setModelChainSource(self, chain_source):
      self.chain_source=chain_source

   def setModelSource(self, source):
      self.source=source

   def setPDBName(self, PDBName):
      self.PDBName=PDBName

   def setNumPerEnsem(self, num_per_ensem):
     self.num_per_ensem=num_per_ensem

   def setNumberMols(self, number_mols):
      self.number_mols=number_mols

   def setNumberDomains(self, number):
      self.number_domains=number

   def setModelName(self, name):
      self.name=name

   def setModelType(self, type):
      self.type=type

   def setModel_directory(self, model_directory):
      self.model_directory=model_directory

   def setModelTypeExtension(self, type_extension):
      self.type_extension=type_extension

   def setMultiType(self, multi_type):
      self.multi_type=multi_type


   def setMR_JobID(self, MR_jobID):
      self.MR_jobID=MR_jobID

   def setMR_JobNumber(self, MR_job_number):
      self.MR_job_number=MR_job_number

   def setMRPROGRAM(self, MRPROGRAM):
      self.MRPROGRAM=MRPROGRAM

   def setRefinement_Program(self, Refinement_program):
      self.Refinement_program=Refinement_program


   def setPhaserPDBfile(self, phaser_pdbfile):
      self.phaser_PDBfile=phaser_pdbfile

   def setPhaserMTZfile(self, phaser_mtzfile):
      self.phaser_MTZfile=phaser_mtzfile

   def setPhaserJobName(self, phaser_jobname):
      self.phaser_jobname=phaser_jobname

   def setPhaserKeyFile(self, phaser_keyfile):
      self.phaser_keyfile=phaser_keyfile

   def setPhaserJobID(self, phaser_jobID):
      self.phaser_jobID=phaser_jobID

   def setPhaserLogFile(self, phaser_logfile):
      self.phaser_logfile=phaser_logfile

   def setPhaserScriptFile(self, filename):
      self.phaser_scriptfile=filename

   def setPhaserSolnFile(self, phaser_solnfile):
      self.phaser_solnfile=phaser_solnfile

   def setPhaserLLGscore(self, phaser_LLG_score):
      self.phaser_LLG_score=phaser_LLG_score

   def setPhaserZscore(self, phaser_Zscore):
      self.phaser_Zscore=phaser_Zscore

   def setPhaserSummary(self, summary):
      self.phaser_summary=summary

   def setPhaserSolnSG(self, SG):
      self.phaser_soln_spacegroup=SG

   def setPhaserSubmitted(self, bool):
      self.phaser_submitted=bool

   def isPhaserSubmitted(self):
      return self.phaser_submitted



   def setMolrepPDBfile(self, molrep_pdbfile):
      self.molrep_PDBfile=molrep_pdbfile

   def setMolrepMTZfile(self, molrep_mtzfile):
      self.molrep_MTZfile=molrep_mtzfile

   def setMolrepJobName(self, molrep_jobname):
      self.molrep_jobname=molrep_jobname

   def setMolrepKeyFile(self, molrep_keyfile):
      self.molrep_keyfile=molrep_keyfile

   def setMolrepJobID(self, molrep_jobID):
      self.molrep_jobID=molrep_jobID

   def setMolrepLogFile(self, molrep_logfile):
      self.molrep_logfile=molrep_logfile

   def setMolrepScriptFile1(self, filename):
      self.molrep_scriptfile1=filename

   def setMolrepScriptFile2(self, filename):
      self.molrep_scriptfile2=filename

   def setMolrepSolnFile(self, molrep_solnfile):
      self.molrep_solnfile=molrep_solnfile

   def setMolrepCorr(self, molrep_Corr):
      self.molrep_Corr=molrep_Corr

   def setMolrepRfac(self, molrep_Rfac):
      self.molrep_Rfac=molrep_Rfac

   def setMolrepSummary(self, summary):
      self.molrep_summary=summary

   def setMolrepSubmitted(self, bool):
      self.molrep_submitted=bool

   def isMolrepSubmitted(self):
      return self.molrep_submitted
 
   ##############################
   # Refmac Rigid Body:
   ##############################

   # RefmacRB variables for Molrep 
   def setRefmacRBMolrepPDBfile(self, filename):
      self.refmacRB_molrep_PDBfile=filename

   def setRefmacRBMolrepMTZINfile(self, filename):
      self.refmacRB_molrep_MTZINfile=filename

   def setRefmacRBMolrepMTZOUTfile(self, filename):
      self.refmacRB_molrep_MTZOUTfile=filename

   def setRefmacRBMolrepJobName(self, name):
      self.refmacRB_molrep_jobname=name

   def setRefmacRBMolrepKeyFile(self, filename):
      self.refmacRB_molrep_keyfile=filename

   def setRefmacRBMolrepJobID(self, ID):
      self.refmacRB_molrep_jobID=ID

   def setRefmacRBMolrepLogFile(self, filename):
      self.refmacRB_molrep_logfile=filename

   def setRefmacRBMolrepSummary(self, summary):
      self.refmacRB_molrep_summary=summary


   # RefmacRB variables for Phaser 
   def setRefmacRBPhaserPDBfile(self, filename):
      self.refmacRB_phaser_PDBfile=filename

   def setRefmacRBPhaserMTZINfile(self, filename):
      self.refmacRB_phaser_MTZINfile=filename

   def setRefmacRBPhaserMTZOUTfile(self, filename):
      self.refmacRB_phaser_MTZOUTfile=filename

   def setRefmacRBPhaserJobName(self, name):
      self.refmacRB_phaser_jobname=name

   def setRefmacRBPhaserKeyFile(self, filename):
      self.refmacRB_phaser_keyfile=filename

   def setRefmacRBPhaserJobID(self, ID):
      self.refmacRB_phaser_jobID=ID

   def setRefmacRBPhaserLogFile(self, filename):
      self.refmacRB_phaser_logfile=filename

   def setRefmacRBPhaserSummary(self, summary):
      self.refmacRB_phaser_summary=summary

   ##############################
   # Refmac Restrained:
   ##############################

   # Refmac variables for Molrep 
   def setRefmacMolrepPDBfile(self, filename):
      self.refmac_molrep_PDBfile=filename

   def setRefmacMolrepMTZINfile(self, filename):
      self.refmac_molrep_MTZINfile=filename

   def setRefmacMolrepMTZOUTfile(self, filename):
      self.refmac_molrep_MTZOUTfile=filename

   def setRefmacMolrepJobName(self, name):
      self.refmac_molrep_jobname=name

   def setRefmacMolrepKeyFile(self, filename):
      self.refmac_molrep_keyfile=filename

   def setRefmacMolrepJobID(self, ID):
      self.refmac_molrep_jobID=ID

   def setRefmacMolrepLogFile(self, filename):
      self.refmac_molrep_logfile=filename

   def setRefmacMolrepSummary(self, summary):
      self.refmac_molrep_summary=summary


   # Refmac variables for Phaser 
   def setRefmacPhaserPDBfile(self, filename):
      self.refmac_phaser_PDBfile=filename

   def setRefmacPhaserMTZINfile(self, filename):
      self.refmac_phaser_MTZINfile=filename

   def setRefmacPhaserMTZOUTfile(self, filename):
      self.refmac_phaser_MTZOUTfile=filename

   def setRefmacPhaserJobName(self, name):
      self.refmac_phaser_jobname=name

   def setRefmacPhaserKeyFile(self, filename):
      self.refmac_phaser_keyfile=filename

   def setRefmacPhaserJobID(self, ID):
      self.refmac_phaser_jobID=ID

   def setRefmacPhaserLogFile(self, filename):
      self.refmac_phaser_logfile=filename

   def setRefmacPhaserSummary(self, summary):
      self.refmac_phaser_summary=summary


   def setBuccaneerMolrepWorkingDIR(self, dirname):
      self.buccaneer_molrep_directory=dirname

   def setBuccaneerMolrepPDBOUTfile(self, filename):
      self.buccaneer_molrep_PDBOUTfile=filename

   def setBuccaneerMolrepPDBrefinedfile(self, filename):
      self.buccaneer_molrep_PDBrefinedfile=filename

   def setBuccaneerMolrepMTZrefinedfile(self, filename):
      self.buccaneer_molrep_MTZrefinedfile=filename

   def setBuccaneerPhaserWorkingDIR(self, dirname):
      self.buccaneer_phaser_directory=dirname

   def setBuccaneerPhaserPDBOUTfile(self, filename):
      self.buccaneer_phaser_PDBOUTfile=filename

   def setBuccaneerPhaserPDBrefinedfile(self, filename):
      self.buccaneer_phaser_PDBrefinedfile=filename

   def setBuccaneerPhaserMTZrefinedfile(self, filename):
      self.buccaneer_phaser_MTZrefinedfile=filename


   def setArpwarpMolrepWorkingDIR(self, dirname):
      self.arpwarp_molrep_directory=dirname

   def setArpwarpMolrepPDBOUTfile(self, filename):
      self.arpwarp_molrep_PDBOUTfile=filename

   def setArpwarpMolrepMTZOUTfile(self, filename):
      self.arpwarp_molrep_MTZOUTfile=filename

   def setArpwarpPhaserWorkingDIR(self, dirname):
      self.arpwarp_phaser_directory=dirname

   def setArpwarpPhaserPDBOUTfile(self, filename):
      self.arpwarp_phaser_PDBOUTfile=filename

   def setArpwarpPhaserMTZOUTfile(self, filename):
      self.arpwarp_phaser_MTZOUTfile=filename


   def setShelxeMolrepPDBfile(self, filename):
      self.shelxe_molrep_PDBfile=filename

   def setShelxePhaserPDBfile(self, filename):
      self.shelxe_phaser_PDBfile=filename


   def setEcalcLogfile(self, filename):
      self.ecalc_logfile=filename

   def setEcalcMTZOUTfile(self, filename):
      self.ecalc_MTZOUTfile=filename


   def setAcornLogfile(self, filename):
      self.acorn_logfile=filename

   def setAcornMTZOUTfile(self, filename):
      self.acorn_MTZOUTfile=filename


   def setCpirateMTZfile(self, filename):
      self.cpirate_MTZfile=filename

   def setCpirateLogfile(self, filename):
      self.cpirate_logfile=filename

   def setCpirateCmdfile(self, filename):
      self.cpirate_cmdfile=filename


   def setbucc_ref_logfile(self, filename):
      self.bucc_ref_logfile=filename

   def setbucc_ref_cmdfile(self, filename):
      self.bucc_ref_cmdfile=filename

   def setbucc_MTZINfile(self, filename):
      self.bucc_MTZINfile=filename

   def setbucc_MTZOUTfile(self, filename):
      self.bucc_MTZOUTfile=filename

   def setbucc_refmac_PDBOUTfile(self, filename):
      self.bucc_refmac_PDBOUTfile=filename


   def setMRPDBSummaryFile(self, filename):
      self.mr_pdb_sum_logfile=filename

   def setPDBcurSummaryFile(self, filename):
      self.pdbcur_sum_logfile=filename


class MR_setup:
   """ A class to setup various structures and lists for running the MR/Refmac pipeline. """
   
   def __init__(self):
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag  

   def setTypes(self, init, mstat, mrsearchdir):
      """ A function to define the model types if the models are not part of an ensemble 
      or a PQS multimer. PQS-based multimers are constructed later, but PISA-based multimers
      should be included here. """
     
      mstat.num_MR_models = 0

      #for chain in mstat.sorted_MODEL_list:
      for chain in mstat.sorted_MR_list:

         for i in init.model_types:
            m=Models_struct()
            m.setModelChainSource(mstat.chain_list[chain].chainName)
            m.setModelSource(mstat.chain_list[chain].source)
            m.setPDBName(mstat.chain_list[chain].PDBName)
            m.seqID.append(mstat.chain_list[chain].seqID)
            if mstat.chain_list[chain].source == "LOC":
               m.rms.append(mstat.chain_list[chain].rms)
         
            m.setModelType(i)
            m.setModelName(mstat.chain_list[chain].chainName + '_' + i)

            if mstat.chain_list[chain].multimer_type == 'MULTIMER':
               m.setNumberMols(mstat.chain_list[chain].number_monomers)

            m.resolution_high = mstat.chain_list[chain].resolution_high
            m.resolution_low  = mstat.chain_list[chain].resolution_low

            model_exists=True

            if i == 'UNMOD':
               if os.path.isfile(mstat.chain_list[chain].unmod_modelPDB):
                  m.PDBfile.append(mstat.chain_list[chain].unmod_modelPDB)
                  m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'unmod')) 
               else:
                  model_exists=False
            elif i == 'PDBCLP':
               m.PDBfile.append(mstat.chain_list[chain].pdbclip_modelPDB)
               m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'pdbclip')) 
            elif i == 'MOLREP':
               if os.path.isfile(mstat.chain_list[chain].molrep_modelPDB):
                  m.PDBfile.append(mstat.chain_list[chain].molrep_modelPDB)
                  m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'molrep'))
               else:
                  model_exists=False
            elif i == 'CHNSAW':
               if os.path.isfile(mstat.chain_list[chain].chainsaw_modelPDB):
                  m.PDBfile.append(mstat.chain_list[chain].chainsaw_modelPDB)
                  m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'chainsaw')) 
               else:
                  model_exists=False
            elif i == 'SCLPTR':
               if os.path.isfile(mstat.chain_list[chain].sculptor_modelPDB):
                  m.PDBfile.append(mstat.chain_list[chain].sculptor_modelPDB)
                  m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'sculptor')) 
               else:
                  model_exists=False
            elif i == 'PLYALA':
               if os.path.isfile(mstat.chain_list[chain].plyala_modelPDB):
                  m.PDBfile.append(mstat.chain_list[chain].plyala_modelPDB)
                  m.setModel_directory(os.path.join(init.search_dir, 'data', mstat.chain_list[chain].chainName, 'plyala'))
               else:
                  model_exists=False
  
            # Check that the models were created and add the model to the model_list
            if model_exists == True:
               mstat.model_list[mstat.chain_list[chain].chainName + '_' + i] = m
               mstat.num_MR_models = mstat.num_MR_models + 1

            # Otherwise report an error with the model creation
            else:
               if self.debug:
                  sys.stdout.write("Model preparation log: Excluding %s model for chain %s as its preparation failed\n" % (i, chain)) 

            if self.debug and model_exists == False:
               sys.stdout.write("\n") 

      # Tag this up as SUMMARY content
      sys.stdout.write('<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n')

      # Output the list of models if we are running in DEBUG mode
      sys.stdout.write("Model Preparation log: A total of %d models have been created for processing in Molecular Replacement\n" \
                        % mstat.num_MR_models)         
      if init.keywords.USEENSEM:
         sys.stdout.write("Model Preparation log: An ensemble model has also been prepared\n")
      sys.stdout.write("Model Preparation log: The following list of models has been created for MR:\n")
      sys.stdout.write("\n")
      count=1
      for model in mstat.model_list.keys():
 
          # Catch the chain/domain/multimer identifier (e.g 'A'(C) or 'z23'(D) or '120'(M))
          identifier=string.split(mstat.model_list[model].chain_source, "_")[1]

          # Select and mark the full 'chain' models
          if len(identifier) == 1 and identifier.isalpha(): 
             base_type="Chain"
             id=identifier
          # Select and mark the 'domain' models
          elif len(identifier) > 1 and identifier[0].isalpha():
             base_type="Domain"
             id=identifier
          # Select and mark the 'multimer' models
          elif len(identifier) >= 1 and identifier.isdigit():
             base_type="Multimer"
             id=identifier
          # Catch for the Ensemble
          elif identifier == "" and mstat.model_list[model].chain_source == "ensemble_model":
             base_type="Ensemble"
             id="ensm"
          # Send a message if an unknown id is found
          else:
             sys.stdout.write("Model Setup Warning: unidentified model identifier '%s' found\n" % identifier)
             sys.stdout.write("\n")
             base_type="Unknown_type"
             id=identifier

          sys.stdout.write("%d %s -- " % (count, model))
          if mstat.model_list[model].type == 'UNMOD':
             mstat.model_list[model].model_info_string="%s %s of structure %s (unmodified)" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'PDBCLP':
             mstat.model_list[model].model_info_string="%s %s of structure %s prepared using the PDBclip method" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'MOLREP':
             mstat.model_list[model].model_info_string="%s %s of structure %s prepared using the Molrep method" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'CHNSAW':
             mstat.model_list[model].model_info_string="%s %s of structure %s prepared using the Chainsaw method" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'SCLPTR':
             mstat.model_list[model].model_info_string="%s %s of structure %s prepared using the Sculptor method" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'PLYALA':
             mstat.model_list[model].model_info_string="%s %s of structure %s prepared using the Polyalanine method" \
                % (base_type, id, mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          if mstat.model_list[model].type == 'ENSMBL':
             mstat.model_list[model].model_info_string="Structure %s prepared as an Ensemble" \
                % (mstat.model_list[model].PDBName) 
             sys.stdout.write(mstat.model_list[model].model_info_string + "\n")

          count=count+1

      sys.stdout.write("\n")
      
      # Create a models directory and copy all of the models to it

      # Create the models directory
      mstat.setModelsDir(os.path.join(init.search_dir, 'models'))
      os.mkdir(mstat.models_dir)

      sys.stdout.write("These models will be placed in the folder:\n" + mstat.models_dir + "\n")
      sys.stdout.write("\n")

      # Close the SUMMARY tag for the input details
      sys.stdout.write('<!--SUMMARY_END--></FONT></B>\n')

      # Copy all of the generated models to the models directory
      for model in mstat.model_list.keys():
         if mstat.model_list[model].type != 'ENSMBL':
            shutil.copyfile(mstat.model_list[model].PDBfile[0], os.path.join(mstat.models_dir, model + ".pdb"))
