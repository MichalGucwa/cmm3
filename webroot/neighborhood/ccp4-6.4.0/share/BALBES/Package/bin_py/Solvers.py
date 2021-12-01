#!/usr/bin/python
# Python script
#
#
#
#     Copyright (C) 2007 --- 2012 Fei Long, A. Vagin, G. Murshudov
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
## The date of last modification: 19/02/2009
#  Report any problem to fei@ysbl.york.ac.uk

import os, os.path, sys
import glob, re, shutil
import math
import string
import fpformat
import time

# modules (XML DOM) related to handle XML style files
xml_path1= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4","xml","dom")
xml_path2= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4","xml","dom","ext")
xml_path3= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4","xml","dom","ext","reader")
sys.path.append(xml_path1)
sys.path.append(xml_path2)
sys.path.append(xml_path3)

from StripXml import StripXml
import PyExpat
from xml.parsers.expat  import ExpatError

# modules defined for structural hierachy
py_path= os.path.join(os.getenv("BALBES_ROOT"),"bin_py")
sys.path.append(py_path)

from StructHierachy import Chain
from StructHierachy import Model
from StructHierachy import Structure
from StructHierachy import Sequence
from StructHierachy import Assembly
from StructHierachy import SF_info
from StructHierachy import RefCycle
from StructHierachy import BOStruc
from StructHierachy import CBOStrucDict

# utility modules
from UtilitiesClasses    import CPathDict
from UtilitiesClasses    import CopyFile
from UtilitiesClasses    import MoveFile
from UtilitiesClasses    import WriteFile
from UtilitiesClasses    import WriteSummaryFile

from UtilitiesClasses    import AssessQ
from UtilitiesClasses    import ModelCmp

# manager modules
from Managers            import CManagers

# file transform classes
from exeCodeClasses      import CF2CIF
from exeCodeClasses      import CCIF2MTZ
from exeCodeClasses      import CGETMTZ
from exeCodeClasses      import CPDBTOSEQ
from exeCodeClasses      import CAlign_DB

# classes for structural factor analysis
from exeCodeClasses      import CSFCHECK

# classes for cell and space group check and structure selection
from ModuleCSG           import CCellSgFinder

# classes for sequence and model data base analysis
from exeCodeClasses      import SEQ_Analysis
from exeCodeClasses      import CSEARCH_DB

#classes for molecule replacement
from exeCodeClasses      import CMOLREP

#classes for refinement
from exeCodeClasses      import CREFMAC

#classes for reindex
from exeCodeClasses      import CPOINTLESS

#classes for solution check
from exeCodeClasses      import CDoman2chains
from exeCodeClasses      import CSolutionCheck

##################################################################

class CMRSolver:

    def __init__( self, path_obj ):

        self._path_dict = path_obj
        self.MR           = CMOLREP(path_obj)
        self.REFI         = CREFMAC(path_obj)
        self.sol_check    = CSolutionCheck(path_obj)
        self.aPointLessOp = CPOINTLESS(path_obj)

        self.idx_err = 0
        self.no_sol  = True

        self.Q_min   = 0.30
        self.Q_max   = 0.70

        self.input_phase = "N"   #  repeatly with mod_2
        self.use_input_r_free = "N"
        self.input_r_free     = 0.0

    def controller(self, t_mod_1, t_mod_2 = None ):

        if not self.idx_err :
            self.mod_out = Model()
            self.Q_out   = 0.0
            self.MR.idx_err = self.idx_err
            self.MR.controller(t_mod_1, t_mod_2 )
            if glob.glob(self.MR.mod_1.mr_sol_xyz) and not self.MR.idx_err:
                self.no_sol = False 
                self.MR.mod_1.refi_in_xyz = self.MR.mod_1.mr_sol_xyz
                self.REFI.controller(self.MR.mod_1)
                if self.MR.mod_1.twinInfo.reindexAction:
                    # Need to reindex by 'pointless' 
                    pKwList = ["spacegroup %s "%self.MR.mod_1.sfInfo.get_space_group(), "reindex %s"%self.MR.mod_1.twinInfo.reindexOperator]
                    self.aPointLessOp.controller(self.MR.mod_1, pKwList)
                    if not self.aPointLessOp.idx_err:
                        # Re-do the refinement using re-indexed mtz file (generated by pointless)
                        self.MR.mod_1.refi_in_hkl = self.aPointLessOp.hkl_out
                        self.REFI.controller(self.MR.mod_1) 
                if self.use_input_r_free.find("Y") != -1 :
                    AssessQ(self.MR.mod_1, self.input_r_free,  self.input_r, self._path_dict['process_log_name'])
                else:
                    AssessQ(self.MR.mod_1, self.MR.mod_1.R_free_ini, self.MR.mod_1.R_ini, self._path_dict['process_log_name'])
                if self.MR.mod_1.Q > self.Q_min :
                    self.Q_out   = self.MR.mod_1.Q
                    self.MR.mod_1.copyModel(self.mod_out)
                        # self.mod_out = self.MR.mod_1
                self.MR.mod_1.copyModel(t_mod_1)
                print "Q_factor for the model %6.5f\n" %t_mod_1.Q
                self._path_dict['process_log_content'] += \
                      "Q_factor for the model %6.5f\n\n"%t_mod_1.Q 
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self._path_dict['process_log_content'] = ""     
                # solution check, used only in the internal tests     
                if self._path_dict.has_key("infile_sol"):
                    if glob.glob(self._path_dict["infile_sol"]):
                        self.sol_check.controller(self.MR.mod_1)
                                    
                 
##################################################################

class CSolutionManager :

    def __init__( self, manager_obj ):

        self._path_dict     = manager_obj.pathDict
        self.mode           = manager_obj.mode
        self.OneMRJobSolver = CMRSolver(manager_obj.pathDict)
        self.sol_check      = CSolutionCheck(manager_obj.pathDict)
    
        self.storedModels          = {}
        self.storedModels['asm']   = []
        self.storedModels['seq']   = []

        self.allSeqs       = []
        self.seqs_used     = []
        self.all_used      = True
        self.Q_min         = 0.30
        self.Q_max         = 0.70

        self.input_phase      = "N"

        self.all_finished     = False


    def controller(self, t_all_models, t_para = None ):
       
        self.Q_best_model     = Model() 
        if self.mode == 4:
            cur_fix_mod = self._path_dict['fixed_mod']
        else:
            cur_fix_mod = None

        self.allSeqs = t_all_models['seqs']  # note: the used_flag in a seq is set to "N" automatically
        if t_all_models.has_key('asms'):
            print "\n|------------------------------------------------------------------------------------|"
            print "|            Calculations of complex models (Assemblies)                             |"
            print "|------------------------------------------------------------------------------------|"
            self._path_dict['process_log_content'] += \
                  "\n|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                  "|            Calculations of complex models (Assemblies)                             |\n"
            self._path_dict['process_log_content'] += \
                  "|------------------------------------------------------------------------------------|\n"

            self.allAsms = t_all_models['asms']
            t_asm_out_mod =self.assembliesSolver(cur_fix_mod)
  
            if t_asm_out_mod.Q > self.Q_best_model.Q \
               and t_asm_out_mod.Q > self.Q_min:
                self.Q_best_model  = t_asm_out_mod

            for a_seq in self.allSeqs:
                a_seq_idx = a_seq.get_index()
                if a_seq_idx not in self.seqs_used:
                    self.all_used = False
                    
            if self.Q_best_model.Q > self.Q_max and self.all_used :
                self.all_finished = True 
            else :
                if self.Q_best_model.Q > self.Q_max :
                    cur_fix_mod = self.Q_best_model
                else :
                    if self.mode == 4:
                        cur_fix_mod = self._path_dict['fixed_mod']
                    else:
                        cure_fix_mod   = None
                    self.seqs_used = []
                    for a_seq in self.allSeqs:
                        a_seq.used = "N"
 
            print "The best Q after Assembly calculations is %5.4f" %self.Q_best_model.Q
            print "idx_Q_best_model ", self.Q_best_model.get_index()
            self._path_dict['process_log_content'] += \
                  "The best Q after Assembly calculations is %5.4f\n"%self.Q_best_model.Q

            print "|------------------------------------------------------------------------------------|"
            print "|            Calculations of complex models (Assemblies) finished                    |"
            print "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                  "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|            Calculations of complex models (Assemblies) finished                    |\n"
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n\n"
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""

        if not self.all_finished:
            print "|------------------------------------------------------------------------------------|"
            print "|            Calculations of models from individual sequences start                  |"
            print "|------------------------------------------------------------------------------------|"
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|            Calculations of models from individual sequences start                  |\n"
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n"

            t_seq_out_mod = self.sequencesSolver(cur_fix_mod)
            if t_seq_out_mod.Q > self.Q_min  and  t_seq_out_mod.Q > self.Q_best_model.Q :
                self.Q_best_model  = t_seq_out_mod
 
            print "|------------------------------------------------------------------------------------|"
            print "|            Calculations of models from individual sequences finished               |"
            print "|------------------------------------------------------------------------------------|"
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|            Calculations of models from individual sequences finished               |\n"
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n"
 
        print "|------------------------------------------------------------------------------------|"
        print "|            All Calculations have finished                                          |"
        print "|------------------------------------------------------------------------------------|"
        self._path_dict['process_log_content'] += \
             "|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "|            All Calculations have finished                                          |\n"
        self._path_dict['process_log_content'] += \
             "|------------------------------------------------------------------------------------|\n"

        print "The best Q after all model calculations is %5.4f" %self.Q_best_model.Q
        self._path_dict['process_log_content'] += \
             "The best Q after all model calculations is %5.4f\n" %self.Q_best_model.Q
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""

        if self.Q_best_model.Q > 0.0:
            if self.Q_best_model.Q >= self.Q_min: 
                d2ch = CDoman2chains(self._path_dict)
                d2ch.controller(self.Q_best_model)
                # self.Q_best_model.copyModFiles(self._path_dict['result_path'])

            # solution check, used only in the internal tests   
            # Only do solution check9ng for the best-Q model  
            if self._path_dict.has_key("infile_sol"):
                if glob.glob(self._path_dict["infile_sol"]):
                    self.sol_check.controller(self.Q_best_model)
                    self.Q_best_model.chain_found       = self.sol_check.chain_found
                    self.Q_best_model.chain_expected    = self.sol_check.chain_expected
                    # keep track solution check results
                    if self._path_dict.has_key("best_model") :
                        if self.Q_best_model.chain_expected > self._path_dict["best_model"].chain_expected:
                               self._path_dict["best_model"].chain_expected  = self.Q_best_model.chain_expected 
                        if self.Q_best_model.chain_found > self._path_dict["best_model"].chain_found:
                               self._path_dict["best_model"].chain_found     = self.Q_best_model.chain_found

        WriteSummaryFile(self._path_dict['process_log_name'],self.Q_best_model)

    def assembliesSolver(self, t_mod_fix = None):
        
        t_model_best = Model()   #  the best model initiation
                                 #  which implies mtz_best = NULL,Q_best = 0.0
      
        for a_assembly in self.allAsms :
            for a_model in a_assembly.get_models() :
                self.OneMRJobSolver.controller(a_model,t_mod_fix)
                if a_model.Q > t_model_best.Q \
                   and a_model.Q > self.Q_min :
                    t_model_best = a_model

                    for a_seq_idx in a_model.seqs:
                        self.seqs_used.append(a_seq_idx)
                        self.allSeqs[a_seq_idx-1].used  = "Y"

        return  t_model_best
                
    def sequencesSolver(self, t_mod_fix):
        
        t_model_best = Model()   #  default model, Q = 0.0
        
        self.mods_stored = []
   
        for a_seq in self.allSeqs:
            if a_seq.used == "N":
                t_aseq_out_mod = self.oneSequenceSolver(a_seq, t_mod_fix)  
                if t_aseq_out_mod.Q > self.Q_min:
                    # for sure, maybe not necessary
                    t_stored_mod = Model()
                    t_aseq_out_mod.copyModel(t_stored_mod)
                    self.mods_stored.append(t_stored_mod)
                    if t_aseq_out_mod.Q > t_model_best.Q :
                        t_aseq_out_mod.copyModel(t_model_best)

        q_seq = "The Best Q out of all individual sequences : %6.4f"%t_model_best.Q
        q_id_mod = "The model with best Q is %s" %t_model_best.name_tag
        print "\n|------------------------------------------------------------------------------------|"
        print "|%s|"%q_seq.center(84)
        print "|%s|"%q_id_mod.center(84)
        print "|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "\n|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "|%s|\n"%q_seq.center(84)
        self._path_dict['process_log_content'] += \
             "|%s|\n"%q_id_mod.center(84)
        self._path_dict['process_log_content'] += \
             "|------------------------------------------------------------------------------------|\n\n"

        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""

        n_mods_stored = len(self.mods_stored)

        if n_mods_stored > 1 :
            self.mods_stored.sort(ModelCmp)
            n_model_max = self.mods_stored[0].get_nres()

            print "|-------------------------------------------------------------------|"
            print "| Further calculations using the calculated models as fixed models  |" 
            print "|-------------------------------------------------------------------|"
            self._path_dict['process_log_content'] += \
                 "|-------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "| Further calculations using the calculated models as fixed models  |\n"
            self._path_dict['process_log_content'] += \
                 "|-------------------------------------------------------------------|\n"
            for i in range(n_mods_stored):
                cur_mod_fix = Model()
                self.mods_stored[i].copyModel(cur_mod_fix)
                self.OneMRJobSolver.use_input_r_free = "Y"
                self.OneMRJobSolver.input_r_free     = cur_mod_fix.R_free_ini
                self.OneMRJobSolver.input_r          = cur_mod_fix.R_ini
                
                if cur_mod_fix.get_nres() >= 0.5*n_model_max:
                    t_other_models  = []
                    for j in range(n_mods_stored):
                        if j != i :
                            self.mods_stored[j].mix = "Y"
                            t_other_model = Model()
                            self.mods_stored[j].copyModel(t_other_model)
                            t_other_model.mr_in_xyz = t_other_model.refi_sol_xyz
                            t_other_model.mr_in_xyz_nmr = t_other_model.refi_sol_xyz
                            t_other_model.mr_in_hkl = t_other_model.refi_sol_hkl
                            t_other_models.append(t_other_model)
                    t_add_seq_mod = self.SFP_Solver(t_other_models, cur_mod_fix)
                    if t_add_seq_mod.Q > t_model_best.Q:
                        t_add_seq_mod.copyModel(t_model_best)

            q_seq = "Best Q from using the calculated models as fixed models %6.4f"%t_model_best.Q
            q_id_mod = "The model with best Q is %s" %t_model_best.name_tag
            print "\n|------------------------------------------------------------------------------------|"
            print "|%s|"%q_seq.center(84)
            print "|%s|"%q_id_mod.center(84)
            print "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "\n|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|%s|\n"%q_seq.center(84)
            self._path_dict['process_log_content'] += \
                 "|%s|\n"%q_id_mod.center(84)
            self._path_dict['process_log_content'] += \
                 "|------------------------------------------------------------------------------------|\n\n"

            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""

        elif n_mods_stored == 1:
            t_model_best = self.mods_stored[0]

        return t_model_best

    def oneSequenceSolver(self, t_seq, t_mod_fix = None):

        t_model_best = Model()   #  default model, Q = 0.0

        print "\n|------------------------------------------------------------------------------------|"
        print "|            Calculations of models from sequence %d                                  |" %t_seq.get_index()
        print "|------------------------------------------------------------------------------------|"
        self._path_dict['process_log_content'] += \
             "\n|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "|            Calculations of models from sequence %d                                  |\n" %t_seq.get_index()
        self._path_dict['process_log_content'] += \
             "|------------------------------------------------------------------------------------|\n"
        
        for a_struct in t_seq.get_structures():
            if a_struct.get_PDB_code() != "MDOM":
                t_struct_out_model = self.structureSolver(a_struct, t_mod_fix)
      
                if t_struct_out_model.Q > t_model_best.Q and t_struct_out_model.Q > self.Q_min:
                    t_struct_out_model.copyModel(t_model_best)
                    # t_model_best =  t_struct_out_model
                      #if t_model_best.Q > self.Q_max:
                      #    return t_model_best
            else :
                t_struct_out_model = self.domainSolver(a_struct.get_all_models(), t_mod_fix)
                if t_struct_out_model.Q > t_model_best.Q and t_struct_out_model.Q > self.Q_min:
                    t_struct_out_model.copyModel(t_model_best)

            q_str = "the best Q for the current strut is %6.5f"%t_struct_out_model.Q
            q_id_mod = "The model with best Q in the current structure is %s" %t_struct_out_model.name_tag
            print "\n|------------------------------------------------------------------------------------|"
            print "|%s|"%q_str.center(84)
            print "|%s|"%q_id_mod.center(84)
            print "|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                  "\n|------------------------------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                  "|%s|\n"%q_str.center(84)
            self._path_dict['process_log_content'] += \
                  "|%s|\n"%q_id_mod.center(84)
            self._path_dict['process_log_content'] += \
                      "|------------------------------------------------------------------------------------|\n\n"

        q_seq = "the best Q for the current sequence is %6.5f"%t_model_best.Q
        q_id_mod = "The model with best Q in the current sequence is %s" %t_model_best.name_tag
        print "\n|------------------------------------------------------------------------------------|"
        print "|%s|"%q_seq.center(84)
        print "|%s|"%q_id_mod.center(84)
        print "|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "\n|------------------------------------------------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
             "|%s|\n"%q_seq.center(84)
        self._path_dict['process_log_content'] += \
             "|%s|\n"%q_id_mod.center(84)
        self._path_dict['process_log_content'] += \
             "|------------------------------------------------------------------------------------|\n\n"
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
                    
        return t_model_best

    def structureSolver(self, t_modgrp_str, t_mod_fix = None):
      
        t_model_best = Model()   #  default model, Q = 0.0
    
        if len(t_modgrp_str.multimers)> 0:
            t_mul_out_model = self.multimerSolver(t_modgrp_str.multimers, t_mod_fix)
            if t_mul_out_model.Q > t_model_best.Q and t_mul_out_model.Q > self.Q_min:
                t_mul_out_model.copyModel(t_model_best)
                # t_model_best =  t_mul_out_model
                if t_model_best.Q > self.Q_max:
                    return t_model_best

        if len(t_modgrp_str.monomers) > 0 :
            self.OneMRJobSolver.controller(t_modgrp_str.monomers[0], t_mod_fix)
            if self.OneMRJobSolver.Q_out > t_model_best.Q \
               and self.OneMRJobSolver.Q_out > self.Q_min :
                self.OneMRJobSolver.mod_out.copyModel(t_model_best)
                # t_model_best = self.OneMRJobSolver.mod_out
                if t_model_best.Q > self.Q_max:
                    return t_model_best
       
        if len(t_modgrp_str.domains)> 0:
            t_dom_out_model = self.domainSolver(t_modgrp_str.domains, t_mod_fix)
            
            if t_dom_out_model.Q > t_model_best.Q and t_dom_out_model.Q > self.Q_min:
                t_dom_out_model.copyModel(t_model_best)
                # t_model_best =  t_dom_out_model

        return t_model_best

    def multimerSolver(self, t_multimer_models, t_mod_fix = None):
        
        t_model_best = Model()   #  default model, Q = 0.0
        for a_model in t_multimer_models :  # multimer models have been ordered 
                                            # according to their size in another class
            self.OneMRJobSolver.controller(a_model, t_mod_fix)
            if self.OneMRJobSolver.Q_out > t_model_best.Q \
               and self.OneMRJobSolver.Q_out > self.Q_min :
                self.OneMRJobSolver.mod_out.copyModel(t_model_best)
                # t_model_best = self.OneMRJobSolver.mod_out
                if t_model_best.Q > self.Q_max:
                    break
       
        return t_model_best
          
    def domainSolver(self, t_domain_models, t_mod_fix = None):
        
        t_model_best     = Model()   #  best Q model, Q = 0.0
        t_model_best_sin = Model()   #  best Q model for a single domain, Q = 0.0

        #Add the crit for the starting model  
 
        # models in the domain model group have been ordered according to their size
        # in the previous MR model building section. 
        n_domain_max = t_domain_models[0].get_nres()

        # alll used_as_start and used flag are set to N
        # The algorithm tries all possible combinations of starting and fixed 
        # domain models. 
       
        n_domain_models = len(t_domain_models) 
        for i in range(n_domain_models) :
                
            a_d_mod = t_domain_models[i]
            
            if a_d_mod.get_nres() >= 0.5*n_domain_max:
         
                a_d_mod.u_input = "N"
                t_idx     = a_d_mod.get_index()
                t_idx_str = "sq"+str(t_idx[0]) + "st" + str(t_idx[1]) + "m" + str(t_idx[2])
                a_d_mod.name_tag = t_idx_str

                print "|-----------------------------------------------|"
                print "|  Domain calculations                          |"
                print "|  (starting from different domains)            |"
                print "|-----------------------------------------------|"
                self._path_dict['process_log_content'] += \
                     "|-----------------------------------------------|\n"
                self._path_dict['process_log_content'] += \
                     "|  Domain calculations                          |\n"
                self._path_dict['process_log_content'] += \
                     "|-----------------------------------------------|\n"

                print "|  The starting domain: %s |" %t_idx_str.center(23)
                self._path_dict['process_log_content'] += \
                      "|  The starting domain: %s |\n" %t_idx_str.center(23)
                if t_mod_fix:
                    t_idx_mod_fix = t_mod_fix.get_index()
                    if not t_mod_fix.asm: 
                        t_idx_str_mod_fix = "sq"+str(t_idx_mod_fix[0]) + "st" + str(t_idx_mod_fix[1]) + "m" + str(t_idx_mod_fix[2])
                    else:
                        t_idx_str_mod_fix = "as" + str(t_idx_mod_fix[0]) + "_m" + str(t_idx_mod_fix[1])
                    # This fixed model could be a input fixed model and need full seq, struct and mod id
                    # otherwise if mod id will appended
                    a_d_mod.name_tag = t_idx_str_mod_fix + "_" + a_d_mod.name_tag
                    a_d_mod.u_input = "Y"

                else:
                    t_idx_str_mod_fix = "None"
                print "|  The fixed domain : %s |" %t_idx_str_mod_fix.center(25)
                print "|-----------------------------------------------|"
                self._path_dict['process_log_content'] += \
                     "|  The fixed domain : %s |\n" %t_idx_str_mod_fix.center(25)
                self._path_dict['process_log_content'] += \
                     "|-----------------------------------------------|\n"

                if not t_mod_fix:
                    a_d_mod.use_phase     = "N"
                else :
                    a_d_mod.use_phase     = "Y"

                other_mod_group = []
                for j in range(n_domain_models):
                    if j != i:
                        t_other_idx = t_domain_models[j].get_index()
                        if not t_domain_models[j].asm :
                            t_domain_models[j].name_tag = "sq"+str(t_other_idx[0]) + "st" + str(t_other_idx[1]) + "m" + str(t_other_idx[2])
                        else:
                            t_domain_models[j].name_tag = "as"+str(t_other_idx[0]) + "st" + str(t_other_idx[1])
                        other_mod_group.append(t_domain_models[j])
 
                self.OneMRJobSolver.use_input_r_free = "N"
                self.OneMRJobSolver.input_r_free  = 0.0
                self.OneMRJobSolver.input_r       = 0.0
                self.OneMRJobSolver.controller(a_d_mod, t_mod_fix)

                # if self.OneMRJobSolver.Q_out >= t_model_best.Q \
                if self.OneMRJobSolver.Q_out > self.Q_min :
                    if self.OneMRJobSolver.Q_out >= t_model_best_sin.Q: 
                        # t_model_best_sin   = self.OneMRJobSolver.mod_out
                        self.OneMRJobSolver.mod_out.copyModel(t_model_best_sin)
                    self.OneMRJobSolver.mod_out.copyModel(a_d_mod)
                    a_d_mod.used   = "Y"
                    a_d_mod.used_as_start = "Y"

                    n_other_mod_group = len(other_mod_group)
                    if n_other_mod_group != 0:      
                        self.OneMRJobSolver.use_input_r_free = "Y"
                        self.OneMRJobSolver.input_r_free     = a_d_mod.R_free_ini
                        self.OneMRJobSolver.input_r          = a_d_mod.R_ini
                        sfp_mod_out =  self.SFP_Solver(other_mod_group, a_d_mod)
                        if sfp_mod_out.Q > t_model_best.Q:
                            #t_model_best = sfp_mod_out
                            sfp_mod_out.copyModel(t_model_best)
                else:
                    print "|-----------------------------------------------|"
                    print "|  No need to fixe the domain model %s       |" %t_idx_str
                    print "|-----------------------------------------------|"
                    self._path_dict['process_log_content'] += \
                         "|-----------------------------------------------|\n"
                    self._path_dict['process_log_content'] += \
                         "|  No need to fixe the domain model %s       |\n" %t_idx_str
                    self._path_dict['process_log_content'] += \
                         "|-----------------------------------------------|\n"     

        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
        if t_model_best.Q > self.Q_min:
            return t_model_best    
        else:
            return t_model_best_sin
      
    def SFP_Solver(self, t_other_models, t_mod_fix ):
  
        t_model_best =  Model()    
        t_mod_fix.copyModel(t_model_best)
        cur_mod_fix       = Model()
        t_mod_fix.copyModel(cur_mod_fix)
       
        # t_fix_idx will be appended according to models fixed in turn 
        if t_mod_fix.u_input == "YES":
            cur_mod_fix.name_tag = "_Usermod"
  
        n_other_models = len(t_other_models)

        # models have been sorted according the number of residues in the previous step

        for a_model in t_other_models:
            a_model.used_as_start = "N"
            a_model.used          = "N"


        self._path_dict['process_log_content'] += \
             "input rf_ini is %5.4f \n"%self.OneMRJobSolver.input_r_free
        self._path_dict['process_log_content'] += \
             "input r_ini is %5.4f \n"%self.OneMRJobSolver.input_r
        for i in range(n_other_models):
            print "|-----------------------------------------------------------|" 
            print "|  The fixed model : %s |" %cur_mod_fix.name_tag.center(38)
            print "|-----------------------------------------------------------|"
            self._path_dict['process_log_content'] += \
                 "|-----------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|  The fixed model : %s |\n" %cur_mod_fix.name_tag.center(38)
            self._path_dict['process_log_content'] += \
                 "|-----------------------------------------------------------|\n"
            a_mod = t_other_models[i]
            a_mod.used_as_start = "Y"
            a_mod.use_phase     = "Y"
            print "|-----------------------------------------------------------|" 
            print "|  The working model : %s |" %a_mod.name_tag.center(36)
            print "|-----------------------------------------------------------|" 
            self._path_dict['process_log_content'] += \
                 "|-----------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                 "|  The working model : %s |\n" %a_mod.name_tag.center(36)
            self._path_dict['process_log_content'] += \
                 "|-----------------------------------------------------------|\n"
            t_idx        = a_mod.get_index()
            a_mod.name_tag = cur_mod_fix.name_tag + "_" + a_mod.name_tag
            self.OneMRJobSolver.controller(a_mod, cur_mod_fix)
            if self.OneMRJobSolver.Q_out > self.Q_min: 
                if self.OneMRJobSolver.Q_out > t_model_best.Q: 
                    self.OneMRJobSolver.mod_out.copyModel(t_model_best)
                    #t_model_best   = self.OneMRJobSolver.mod_out
                self.OneMRJobSolver.mod_out.copyModel(cur_mod_fix)
            else :
                print "Model Q factor is smaller than min required Q, stop adding new domains"
                print "######################################################################\n"

                self._path_dict['process_log_content'] += \
                      "Model Q factor is smaller than mim required Q, stop adding new domains\n"
                self._path_dict['process_log_content'] += \
                      "######################################################################\n\n"
                break

                #Test: not try all of domain combinatioms. If we have 4 domains,
                #we try:
                #(1) dom1 + dom2 + dom3 + dom4 (in the descent size of domains)
                #(2) dom2 + dom1 + dom3 + dom4 
                #(3) dom3 + dom1 + dom2 + dom4
                #(4) dom4 + dom1 + dom2 + dom3
                #These are all we test now the total combination number is 16 (4X4)
                #we skip other 12 combinations at the moment 
 

                #a_related_models = []
                #for j in range(n_other_models):
                #    if j != i:
                #        a_related_models.append(t_other_models[j])
                
                #n_a_related_models = len(a_related_models) 
               
                #if n_a_related_models > 0:
                #    for b_mod in a_related_models :
                #        # make sure that these models are not labelled "used"
                        # from the previous round
                #        b_mod.used    = "N"

                #    for b_mod in a_related_models :
                #        b_mod.use_phase     = "Y"
                #        t_idx        = b_mod.get_index()
                #        b_mod.name_tag = "seq"+str(t_idx[0]) + "struct" + str(t_idx[1]) + "mod" + str(t_idx[2]) + "fixed" + t_fix_idx
                #        self.OneMRJobSolver.controller(b_mod, cur_mod_fix)
                #        if self.OneMRJobSolver.Q_out > t_model_best.Q :
                #          t_model_best   = self.OneMRJobSolver.mod_out
                #            cur_mod_fix    = t_model_best
                #            t_idx     = cur_mod_fix.get_index()
                #            if not cur_mod_fix.asm:
                #                t_fix_idx += "_mod" + str(t_idx[2])
                #            else:
                #                t_fix_idx += "_mod" + str(t_idx[1])
                #        else:
                #            break

                #if t_model_best > self.Q_max:
                #    return t_model_best

        self.OneMRJobSolver.use_input_r_free = "N"
        self.OneMRJobSolver.input_r_free  = 0.0
        self.OneMRJobSolver.input_r       = 0.0

        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
        return t_model_best    
         