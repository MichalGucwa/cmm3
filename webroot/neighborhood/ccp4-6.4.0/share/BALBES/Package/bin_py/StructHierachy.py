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
## The date of last modification: 05/10/2007
#  Report any problem to fei@ysbl.york.ac.uk

import os, os.path
import sys
import glob
import re
import math
import string
import fpformat

# for model sorting
def ModelCmp(mod_1, mod_2):
    if mod_1.get_nres() >= mod_2.get_nres() :
        return -1
    else :
        return 1


def CopyFile(file1_ini, file_fin):
    """ make a check before cp a file to a file or directory"""

    if not os.path.isfile(file1_ini):
        return None
    else:
        execmd = "cp " + file1_ini  + "  " + file_fin
        os.system(execmd)
        return file_fin

class Chain :
    """ Class that describes a chain """

    def __init__( self ):
        
        self.__ID = ""
        self.__scoreC = 0.0 
        
        self.b_all  = BOStruc()
        self.b_main = BOStruc()
        self.b_side = BOStruc()

        self.o_all = BOStruc()
        self.o_main = BOStruc()
        self.o_side = BOStruc()

    def set_chainID ( self, id_chain ):
        self.__ID = id_chain.lstrip()
        self.__ID = self.__ID.rstrip()
    def get_chainID ( self):
        return self.__ID 

    def set_scoreC ( self, score_c ):
        self.__scoreC = float(score_c)
    def get_scoreC (self) :
        return self.__scoreC



class Model :
    """ Class that describes a model """

    def __init__( self ):

        self.sfInfo                = SF_info()

        self.__index               = []
        self.__complex             = 100
        self.__ncsm                = 1.0
        self.__index_chain         = ""
        self.__index_domain        = ""
        self.__domain_pdb_code     = ""
        self.__radius              = 0.0
        self.__molrep_radius       = 0.0
        self.__resmax_used         = 0.0
        self.__volume              = 0.0
        self.__nres                = 0
        self.__nmon                = 0
        self.__similarity          = ""
        self.__sim_ens            = ""
        self.__mol_compl           = ""
        self.__surface             = ""
        self.__pdb_code            = ""
       
        self.u_input               = "NO" 
        self.name_tag              = ""
        self.infile_seq            = ""    
        self.mr_in_xyz             = ""    
        self.mr_in_xyz_ens         = ""
        self.ens_enable            = "NO"
        self.mr_in_hkl             = ""    
        self.mr_sol_xyz            = ""
        self.mr_sol_hkl            = ""
        self.mr_log                = ""
        self.refi_in_xyz           = ""
        self.refi_in_hkl           = ""
        self.refi_sol_xyz          = ""
        self.refi_sol_hkl          = ""
        self.refi_rigid_log        = ""
        self.refi_log              = ""
        self.file_ocp_crd          = ""
        self.file_ocp_hkl          = ""
        self.file_sol_dimer        = "" 
        
        self.__nmon_solution       = 0
        self.__mr_score            = 0.0
        self.__mr_score_prev       = 0.0

        self.__nchains             = 0
        self.__chains              = [ ]  # check the usage of this
        self.__score_C             = 0.0
        self.__score_D             = 0.0
        self.__corr                = 0.0
        self.__rfac                = 1.0  # sfcheck related only, think
        self.__rfacfree            = 1.0  # 
       

        self.found_chains          = [] 

        self.__err_level           = 0
        self.__err_message         = ""

        # if the model is in an assembly
        self.asm                   = 0
        self.num_seqs              = 0
        self.seqs                  = []
        self.seqs_name             = []
  
        # newly added 

        self.R_ini        = 1
        self.R_fin        = 1
        self.d_R          = 0
        self.R_free_ini   = 1
        self.R_free_fin   = 1
        self.d_R_free     = 0
        self.chains       = []
        self.Q            = 0.0


        self.used_as_start = "N"
        self.used          = "N"
        self.use_phase     = "N"
        self.mix           = "N"

        self.chain_expected = 0
        self.chain_found    = 0

        self.Occupancy = CBOStrucDict()
        self.BFactors  = CBOStrucDict()

        self.twinInfo  = TwinInfo()



        # Newly added quality_factor, different from the Qfactor in
        # another version (probably cancel that one)
   
        # self.qualityFactor = 0.0 
        self.segments = {}

    def set_index(self, i_seq, i_struct, i_mod ):
        self.__index = [int(i_seq), int(i_struct), int(i_mod)]        
    def set_index_asm(self, i_asm, i_mod ):
        self.__index = [int(i_asm), int(i_mod)]        
    def get_index(self):
        return self.__index 

    def set_complex ( self, t_complex ):
        self.__complex = int(t_complex)
        
    def get_complex ( self):
        return self.__complex
    
    def set_numCopies ( self, n_dimer = 0 ):
        
        if self.__complex == 230:
            self.__ncsm = 12
        elif self.__ncsm == 432:
            self.__ncsm = 24
        elif self.__complex == 532:
            self.__ncsm = 60
        else :
            # Now the rules are:
            # complex N00 --> ncsm N
            # complex N22 --> ncsm N * 2 and
            # complex N2  --> ncsm N * 2

            re_t = int(math.fmod(self.__complex, 10))

            if re_t == 0:
                self.__ncsm = self.__complex/100
            else :
                self.__ncsm = 2*self.__complex/100

        if n_dimer:
            self.__ncsm = 2
            
    def get_numCopies ( self):
        return self.__ncsm

    def get_multimer( self):
        if self.__ncsm == 1 :
           return "Monomer"
        elif self.__ncsm == 2 :
           return "Dimer"
        elif self.__ncsm == 3 :
           return "Trimer"
        elif self.__ncsm == 4 :
           return "Tetremer"
        else :
           return "Multimer"

    def set_radius ( self, r_value ):
        self.__radius = float(r_value)
        #print "Its radius value " , self.__radius
    def get_radius ( self):
        return self.__radius

    def set_MOLREP_RAD(self, radius100):
        # Change the definition of "rad" used as an input key work in 
        # "MOLREP" 
        if self.__complex == 100 or self.__pdb_code == "MDOM":
            self.__molrep_radius = 2.0*float(self.__radius)
        else :
            self.__molrep_radius = 2.3*float(radius100)

    def set_MOLREP_RAD2(self, radius):
        # assembly only
        self.__molrep_radius = 2.0*float(radius)

    def set_MOLREP_RAD3(self, radius):
        # assembly only
        self.__molrep_radius = float(radius)

    def get_MOLREP_RAD(self):
        return self.__molrep_radius
   
    def set_nchains ( self, n_chains ):
        self.__nchains= int(n_chains)
    def get_nchains ( self):
        return self.__nchains 
        
    def set_chain ( self, i_chain ):
        self.__index_chain = i_chain.lstrip()
        self.__index_chain = self.__index_chain.rstrip()
        # print "Its chain symbol : " , self.index_chain
    def get_index_chain ( self):
        return self.__index_chain 
        
    def set_domain_PDB_code ( self, domain_pdb_code ):
        domain_pdb_code = domain_pdb_code.strip()
        self.__domain_pdb_code = domain_pdb_code
    def get_domain_pdb_code ( self):
        return self.__domain_pdb_code

    def set_domain ( self, i_domain ):
        self.__index_domain = int(i_domain)
        # print "Its domain value : " , self.index_domain
    def get_index_domain ( self):
        return self.__index_domain
    def get_domain ( self):
        if self.__index_domain:
            return "Yes"
        else :
            return "No"
        
    def set_resmax ( self, resmax_value ):
        self.__resmax_used  = float(resmax_value)
        # print "Its resmax_used  value : " , self.resmax_used
    def get_resmax ( self):
        return self.__resmax_used 
        
    def set_volume ( self, vol_value ):
        self.__volume = float(vol_value)
        # print "Its volume value : " , self.volume
    def get_volume ( self):
        return self.__volume
        
    def set_similarity ( self, sim_value ):
        self.__similarity = float(sim_value) 
        # print "Its similarity value : " , self.similarity
    def get_similarity ( self):
        return self.__similarity

    def set_sim_ens ( self, sim_value ):
        self.__sim_ens = float(sim_value) 
        # print "Its similarity value : " , self.similarity
    def get_sim_ens ( self):
        return self.__sim_ens

        
    def set_mol_compl ( self, mol_c_value):
        self.__mol_compl = float(mol_c_value)
        # print "Its model completness value : " , self.mol_compl
    def get_mol_compl ( self):
        return self.__mol_compl
        
    def set_surface ( self, surf_t ):
        surf_tt = surf_t.lstrip()
        surf_tt = surf_tt.rstrip()
        self.__surface = surf_tt      
    def get_surface ( self):
        return self.__surface 
        
    def set_pdb_code ( self, pdb_code):
        self.__pdb_code = pdb_code
    def get_pdb_code ( self):
        return self.__pdb_code
        
    def set_nmon_solution( self, n_solution):
        self.__nmon_solution = int(n_solution)
    def get_nmon_solution( self):
        return self.__nmon_solution 
        
    def set_nres ( self, nres_t ):
        self.__nres = int( nres_t)
    def get_nres ( self):
        return self.__nres

    def set_nmon ( self, nmon_t ):
        self.__nmon = int( nmon_t)
    def get_nmon ( self):
        return self.__nmon

    def set_mr_score( self, score):
        self.__mr_score = float(score)
    def get_mr_score( self):
        return self.__mr_score

    def set_mr_score_prev( self, score_prev):
        self.__mr_score_prev = float(score_prev)
    def get_mr_score_prev( self):
        return self.__mr_score_prev 

    def set_scores( self, score_c, score_d):
        self.__score_C = float(score_c)
        self.__score_D = float(score_d)
        
    def set_scoresC( self, score_c):
        self.__score_C = float(score_c)
    def get_scoreC( self):
        return self.__score_C

    def set_scoresD( self, score_d):
        self.__score_D = float(score_d)
    def get_scoreD( self):
        return self.__score_D

    def set_corr(self, corr) :
        self.__corr = float(corr)
    def get_corr(self):
        return self.__corr

    def set_rfac(self, rfac) :
        self.__rfac = float(rfac)
    def get_rfac(self):
        return self.__rfac

    def set_rfacfree(self, rfacfree) :
        self.__rfacfree = float(rfacfree)
    def get_rfac(self):
        return self.__rfacfree

    def set_err_level( self, err_level ):
        self.__err_level = int(err_level)
    def get_err_level ( self):
        return self.__err_level 

    def set_err_message ( self, err_message ):
        self.__err_message = err_message    
    def get_err_message ( self):
        return self.__err_message  

    def copyModFiles (self, dis_dir ):
        
        if os.path.isdir(dis_dir):
            dis_dir = dis_dir + "/"
            if self.ens_enable == "YES":
                CopyFile(self.mr_in_xyz_ens, dis_dir)
            else:
                CopyFile(self.mr_in_xyz, dis_dir)

            CopyFile(self.mr_sol_xyz, dis_dir)
            CopyFile(self.mr_sol_hkl, dis_dir)
            CopyFile(self.mr_log, dis_dir)
            CopyFile(self.refi_sol_xyz, dis_dir)
            CopyFile(self.refi_sol_hkl, dis_dir)
            CopyFile(self.refi_rigid_log, dis_dir)
            CopyFile(self.refi_log, dis_dir)

    def copyModel(self, a_model):
        """not using the address point (i.e. avoid using mod1 = mod2) in some cases. 
        Instead copying a few properties important to this model (a_model) to avoid
        that the model (self) pointed is changed when it is processed again
        e.g. in the domain calculations """
 
        if self.asm:
            a_model.set_index_asm(self.__index[0], self.__index[1])
        else:
            a_model.set_index(self.__index[0], self.__index[1],self.__index[2])

        a_model.set_chain(self.__index_chain)
        a_model.set_nchains(self.__nchains)
        a_model.set_domain(self.__index_domain)
        a_model.set_domain(self.__index_domain)
        a_model.set_domain_PDB_code(self.__domain_pdb_code)
        a_model.set_pdb_code(self.__pdb_code)
        a_model.set_nres(self.__nres)
        a_model.set_resmax(self.__resmax_used)
        a_model.set_volume(self.__volume)
        a_model.set_similarity(self.__similarity)
        a_model.set_sim_ens(self.__sim_ens)
        a_model.set_complex(self.__complex)
        a_model.set_mol_compl(self.__mol_compl)
        a_model.set_surface(self.__surface)
        a_model.set_radius(self.__radius)
        a_model.set_MOLREP_RAD3(self.__molrep_radius)
        a_model.set_nmon_solution(self.__nmon_solution)
        a_model.set_nmon(self.__nmon)
        a_model.set_numCopies()

        a_model.set_err_level(self.__err_level)
        a_model.set_err_message(self.__err_message)


        a_model.name_tag    =  self.name_tag
        a_model.infile_seq  =  self.infile_seq             
        a_model.mr_in_xyz   =  self.mr_in_xyz            
        a_model.mr_in_xyz_ens =    self.mr_in_xyz_ens        
        a_model.ens_enable    =    self.ens_enable            
        a_model.mr_in_hkl     =    self.mr_in_hkl                 
        a_model.mr_sol_xyz    =    self.mr_sol_xyz            
        a_model.mr_sol_hkl    =    self.mr_sol_hkl            
        a_model.refi_in_xyz   =    self.refi_in_xyz           
        a_model.refi_in_hkl   =    self.refi_in_hkl           
        a_model.refi_sol_xyz  =    self.refi_sol_xyz          
        a_model.refi_sol_hkl  =    self.refi_sol_hkl          

        a_model.mix           =    self.mix                  
        a_model.asm           =    self.asm                  
        a_model.num_seqs      =    self.num_seqs              
        a_model.seqs          =    self.seqs                 
        a_model.seqs_name     =    self.seqs_name           
       
        a_model.R_ini         =    self.R_ini        
        a_model.R_fin         =    self.R_fin        
        a_model.d_R           =    self.d_R          
        a_model.R_free_ini    =    self.R_free_ini   
        a_model.R_free_fin    =     self.R_free_fin   
        a_model.d_R_free      =    self.d_R_free     
        a_model.chains        =    self.chains      
        a_model.Q             =    self.Q         

        a_model.used_as_start = self.used_as_start
        a_model.used          = self.used
        a_model.use_phase     = self.use_phase

        a_model.chain_expected =  self.chain_expected 
        a_model.chain_found    =  self.chain_found    

        a_model.twinInfo       = TwinInfo()
        a_model.twinInfo.newDomains = self.twinInfo.newDomains
        a_model.twinInfo.numDomains = self.twinInfo.numDomains
        a_model.twinInfo.reindexAction = self.twinInfo.reindexAction
        a_model.twinInfo.reindexOperator = self.twinInfo.reindexOperator



class Structure :
    """ class that describes a structure """
    
    def __init__( self ):
        
        self.__index      = [-1,-1]
        self.__num_models = 0
        self.__models     = []
        self.multip_domain_index = 0

        self.__c_radius   = 0.0

        self.__pdb_code   = ""

        self.multimers    = []
        self.monomers     = []
        self.domains      = []

        self.size_mon     = 0
  
    def set_index(self, i_seq, i_struct):
        self.__index = [int(i_seq), int(i_struct)]
    def get_index(self):
        return self.__index
    
    def set_similarity(self, sim):
        self.__similarity = float(sim)
    def get_similarity(self):
        return self.__similarity
    
    def add_model ( self, model_i ):
        # This part needs to change to be more general

        self.__models.append(model_i)
        self.__num_models += 1

    def get_num_models ( self):   
        return self.__num_models
    def get_all_models ( self):   
        return self.__models
    def get_a_model ( self, i_mod):   
        return self.__models[i_mod]

    def get_same_complex_models ( self, t_model):
        s_models = [ ]   
        for a_model in self.get_all_models():
            if a_model.get_complex() == t_model.get_complex() \
                  and a_model.get_index_domain() != t_model.get_index_domain() :
                s_models.append(a_model)
        return s_models

    def set_c_radius(self) :
        # serarch radius of complex value 100 
        for a_model in self.get_all_models() :
            if a_model.get_complex() == 100 and a_model.get_index_domain() == 0:
                self.__c_radius = a_model.get_radius()
                break
            

    def get_c_radius(self) :
        return self.__c_radius

    def set_molrep_rad(self) :
        for a_model in self.get_all_models():
            a_model.set_MOLREP_RAD(self.get_c_radius())

    def set_molrep_rad2(self) :
        for a_model in self.get_all_models():
            a_model.set_MOLREP_RAD2()
                 
    def set_PDB_code( self, pdb_code):
        self.__pdb_code= pdb_code
        
    def get_PDB_code( self):
        return self.__pdb_code
       
class Sequence:
    """ class that describes a sequence """

    count = 0    # class attribute, keep it public
    
    def __init__( self ):

        self.__indx           = -1
        self.__num_structures = 0
        self.__structures     = []
        self.used             = "N"
        
        Sequence.count +=1
        
    def __del__( self ):

        Sequence.count -=1        

    def set_index(self, i_seq):
        self.__index = i_seq
    def get_index(self):
        return self.__index 
        
    def add_structure ( self, structure_i ):
        self.__structures.append(structure_i)
        self.__num_structures += 1
        
    def get_num_structures ( self):
        return self.__num_structures
    
    def get_structures ( self):
        return self.__structures
    
    def get_a_structure ( self, i_str ):
        return self.__structures[i_str]

class Assembly:
    """ class that describes a sequence """

    count = 0    # class attribute, keep it public

    def __init__( self ):

        self.__indx           = -1
        self.__num_models     =  0
        self.__models         = []

        self.seqs             = []
        self.num_seqs_used    = 0
        self.name             = ""

        Assembly.count +=1

    def __del__( self ):
        Assembly.count -=1

    def set_index(self, i_seq):
        self.__index = i_seq
    def get_index(self):
        return self.__index

    def add_model ( self, model_i ):
        self.__models.append(model_i)
        self.__num_models += 1

    def get_num_models ( self):
        return self.__num_models

    def get_models ( self):
        return self.__models

    def get_a_model ( self, i_str ):
        return self.__models[i_str]

    def models_sort ( self):
        if self.__num_models > 1:
          self.__models.sort(ModelCmp)


class SF_info:
    """ class that contains the structural information
    obtained from the structure factor analysis """

    def __init__( self ):
        
        self.__space_group         = ""
        self.__nsym                = 1
        self.__cell                = ""
        self.cell_len              = ""
        self.cell_ang              = ""
        self.__volume              = 0.0
        self.__cell_nmon           = 0.0
        self.__resmax              = ""
        self.__resmin              = ""
        self.__resmax_used         = ""
        self.__opt_res             = ""
        self.__data_comp           = ""
        self.__b_overall           = ""
        self.__aniso               = ""
        self.__pseudo_trans        = ""
        self.__twin                = ""
        self.__fobs_file           = ""
        self.__err_level           = -1
        self.__job_message         = ""
        
    def set_space_group ( self, space_group):
        self.__space_group  = space_group
    def get_space_group ( self):
        return self.__space_group 
        
    def set_nsym ( self, nsym):
        self.__nsym  = int(nsym)
    def get_nsym ( self):
        return self.__nsym

    def set_cell ( self, cell):
        self.__cell  =  cell
    def get_cell ( self):
        return self.__cell
    
    def get_cell_para ( self, cell_pa):
        if len(cell_pa) == 3:
            cell_para = cell_pa[0] + " " + cell_pa[1]  \
                              + " " + cell_pa[2]
            return cell_para
        else :
            return None   

    def set_volume ( self, volume):
        if str(volume)[0] != "*":
            self.__volume  =  float(volume)
    def get_volume ( self):
        return self.__volume 

    def set_cell_nmon ( self ):
        if self.__nsym :
            self.__cell_nmon = self.__volume*0.70/self.__nsym
        else :
            print "The number of symmetry is zero "
            print "How to calculate cell_nmon ? (for debugging) "
            sys.exit()
    
    def get_cell_nmon ( self ):
        return self.__cell_nmon
    
    def set_resmax ( self, resmax):
        self.__resmax  =  fpformat.fix(float(resmax),2)
    def get_resmax ( self):
        return self.__resmax
        
    def set_resmin ( self, resmin):
        self.__resmin  = fpformat.fix(float(resmin),2)
    def get_resmin ( self):
        return self.__resmin

    def set_resmax_used ( self, resmax_used):
        self.__resmax_used  =  resmax_used
    def get_resmax_used ( self):
        return self.__resmax_used

    def set_opt_res ( self, opt_res):
        self.__opt_res  =  opt_res
    def get_opt_res ( self):
        return self.__opt_res
    
    def set_data_compl ( self, data_compl):
        self.__data_compl  =  fpformat.fix(float(data_compl),2)
    def get_data_compl ( self):
        return self.__data_compl 

    def set_b_overall ( self, b_overall):
        self.__b_overall  =  b_overall
    def get_b_overall ( self):
        return self.__b_overall
    
    def set_aniso ( self, aniso):
        self.__aniso  =  aniso
    def get_aniso ( self):
        return self.__aniso  
        
    def set_pseudo_trans ( self, pseudo_trans):
        self.__pseudo_trans  =  pseudo_trans
    def get_pseudo_trans ( self):
        return self.__pseudo_trans
        
    def set_twin ( self, twin):
        self.__twin  =  twin
    def get_twin ( self):
        return self.__twin
    
    def set_fobs_file ( self, fobs_file):
        self.__fobs_file  =  fobs_file
    def get_fobs_file ( self):
        return self.__fobs_file 

    def set_err_level ( self, err_level):
        self.__err_level  =  int(err_level)
    def get_err_level ( self):
        return self.__err_level
        
    def set_job_message ( self, job_message):
        self.__job_message  =  job_message
    def get_job_message ( self):
        return self.__job_message             

class RefCycle:
    """ a class that stores information in a cycle of REFMAC  """
    def __init__( self ): 
        self.cyc_id    = 0
        self.r_fact    = 1.0
        self.r_free    = 1.0
        self.rmsBOND   = 0.0
        self.rmsANGLE  = 0.0
        self.CHIRAL    = 0.0

class BOStruc:
     """ a class that stores a group of B factors or occupancy factors"""
  
     def __init__( self, a_Node = None ):
         self.number    = 0
         self.average   = 0.0
         self.sigma     = 1.0

         if a_Node :
             self.SetBOStruc(a_Node)
     
     def SetBOStruc(self, Node):

         for subNode in Node.childNodes:
             if subNode.nodeName == "number": 
                self.number = int(subNode.firstChild.nodeValue) 
             elif subNode.nodeName == "average":                                                     
                self.average = float(subNode.firstChild.nodeValue)
             elif subNode.nodeName == "sigma":
                self.sigma  = float(subNode.firstChild.nodeValue)

class CBOStrucDict(dict):

    def __init__( self):

        self['overall']     = {}
        self['overall']['all']  = BOStruc()
        self['overall']['main'] = BOStruc()
        self['overall']['side'] = BOStruc()
        self['chains']  = []

class SymmtryData :
    """ Tempo, will be changed after the edna version"""

    def __init__( self ):

        self.a     = 0.0
        self.b     = 0.0
        self.c     = 0.0
        self.alpha = 0.0
        self.beta  = 0.0
        self.gamma = 0.0

        self.sg    = ""

class TwinInfo:

    def __init__( self ):
        
        self.newDomains = []
        self.numDomains = 0
        self.reindexAction     = False
        self.reindexOperator   = ""

class TwinDomain:

    def __init__( self ):

        self.idx = 0
        self.operator = ""
        self.fraction = 0.0

class ReindexOp :
    """ for pointless """

    def __init__( self ):

        self.idx      = 0
        self.score    = 0.0
        self.ncc      = 0.0
        self.R        = 0
        self.operator = ""
        self.matrix   = ""

