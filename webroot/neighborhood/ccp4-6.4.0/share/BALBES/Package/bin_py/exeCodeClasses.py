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
## The date of last modification: 26/09/2007
#  Report any problem to fei@ysbl.york.ac.uk

import os, os.path, sys
import glob, re, shutil
import math
import string
import fpformat
import time
import select, fcntl
import socket

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

from StructHierachy import SymmtryData
from StructHierachy import TwinInfo
from StructHierachy import TwinDomain
from StructHierachy import ReindexOp

# utility modules
from UtilitiesClasses    import CPathDict
from UtilitiesClasses    import CopyFile
from UtilitiesClasses    import MoveFile
from UtilitiesClasses    import WriteFile
from UtilitiesClasses    import WriteSummaryFile

from UtilitiesClasses    import ModelCmp

# manager modules
# from Managers_b    import CManagers

# the abstract base class to be inheritted by any class
# that wraps an executable code

from baseClasses     import CExeCode

##########################################

class CSFCHECK( CExeCode ) :

    def __init__( self, path_obj):
        """Set the pathes where we can find exe codes, input and output data"""

        self.idx_err = 0
        CExeCode.__init__(self, path_obj)
        if not self._path_dict.has_key("infile_mtz"):
            print "Can not find input structure factor file, check your input "
            self._path_dict['process_log_content'] = \
                  "Can not find input structure factor file, check your input \n"
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content']) 
            self.idx_err = 1
            sys.exit(1)

        self.__exeCode  = os.path.join(self._path_dict["bin_path"],"sfcheck")
       
    def  setCmdLineAndFile (self, idx_stage = 1, t_model = None ) :
        """ set the command lines for the code 'sfcheck', each code has an unique one,
        which overrides the corresponding method in the base class """

        self._cmdline  = ''
    
        # Select different sets of the parameters for 'sfcheck' according to
        # the stage it is used
       
        if idx_stage == 1 or idx_stage == 0:                 
            # the initial stage
            self.batch_name = os.path.join(self._path_dict['scr_path'],"sf_1i.par")
            try:
                sfcheck_bat = open(self.batch_name,"w")
            except IOError:
                print self.batch_name, " could not be opened for write"
                self._path_dict['process_log_content'] = \
                  ("%s could not be opened for write \n" %self.batch_name)
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content']) 
                self._path_dict['process_log_content'] = ""
                self.idx_err = 1
            else:
                print >> sfcheck_bat, '_DOC  Y>%s' % (self._path_dict["doc_path"]+"/")
                print >> sfcheck_bat, "_FILE_C "
                print >> sfcheck_bat, "_FILE_F %s"  % self._path_dict['infile_mtz']
                print >> sfcheck_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"]+"/")
                print >> sfcheck_bat, "_TEST Y "
                sfcheck_bat.close()
            self._cmdline =  ' %s  < %s \n   ' %  (self.__exeCode, self.batch_name)
        elif idx_stage == 2 :                 # The final stage analysis by 'sfcheck'
            
            self._cmdline =  ' %s  -f  %s -m %s -po %s -ps %s -lf FWT -lp PHWT'  \
                              % (self.__exeCode, t_model.refi_sol_hkl, t_model.refi_sol_xyz,
                                 (self._path_dict["scr_path"] + "/"), (self._path_dict["scr_path"] + "/"))    
    def file_manu(self,  idx_stage = 1 ):
        """ mv files to the apporpriate subdirs, should be done in core programs """

        t_xml = self._path_dict["doc_path"] +"/sfcheck.xml"
        t_bat = self._path_dict["doc_path"] +"/sfcheck.bat"
        t_log = self._path_dict["scr_path"] +"/sfcheck.log"
        t_mis = self._path_dict["doc_path"] +"/sfcheck_fob.dat"
        t_ps = self._path_dict["scr_path"] +"/sfcheck*.ps"
        if idx_stage != 2:
            t_xml = self._path_dict["doc_path"] +"/sfcheck.xml"
            out_file = MoveFile(t_xml, self.xml_name)
            out_file = MoveFile(t_bat, self._path_dict["scr_path"] )
            out_file = MoveFile(t_log, self.log_name)
            out_file = MoveFile(t_mis, self.fobs_name)
        else:
            t_xml = self._path_dict["scr_path"] +"/sfcheck.xml"
            out_file = MoveFile(t_xml, self.xml_name)
            out_file = MoveFile(t_log, self.log_name)
            out_file = MoveFile(t_ps, self._path_dict["doc_path"])

    def controller(self,  idx_stage = 1, t_model = None ):
        """ execute 'sfcheck' at different stages """

        if not self.idx_err:
            self.setCmdLineAndFile (idx_stage, t_model)
            if idx_stage == 0:
                self.log_name = os.path.join(self._path_dict['doc_path'],'sfcheck_gfobs.log')
                self.xml_name = os.path.join(self._path_dict['xml_path'],'sfcheck_gfobs.xml')
                self.fobs_name = os.path.join(self._path_dict['scr_path'], "sfcheck_fobs_gfobs.dat")

            elif idx_stage == 1 :
                # The initial stage analysis by 'sfcheck'

                print "\n#-----------------------------------------------------------#"
                print "# Structure Factor Data Analysis                            #"
                print "#-----------------------------------------------------------#"
                self._path_dict['process_log_content'] = \
                       "\n#-----------------------------------------------------------#\n"
                self._path_dict['process_log_content'] += \
                       "# Structure Factor Data Analysis                            #\n"
                self._path_dict['process_log_content'] += \
                       "#-----------------------------------------------------------#\n"
                self.log_name = os.path.join(self._path_dict['doc_path'],'sfcheck_firstStage.log')
                self.xml_name = os.path.join(self._path_dict['xml_path'],'sfcheck_firstStage.xml')
                self.fobs_name = os.path.join(self._path_dict['scr_path'], "sfcheck_fobs_firstStage.dat")
            elif idx_stage == 2:

                # The final validating stage by 'sfcheck' starts
                print "\n#-----------------------------------------------------------#"
                print "# The Model Assesment by Structural Factor Data Analysis    #"
                print "#-----------------------------------------------------------#"
                self._path_dict['process_log_content'] = \
                      "\n#-----------------------------------------------------------#\n"
                self._path_dict['process_log_content'] += \
                      "# The Model Assesment by Structural Factor Data Analysis    #\n"
                self._path_dict['process_log_content'] += \
                      "#-----------------------------------------------------------#\n"
                idx_model = t_model.get_index()
                if t_model.asm:
                    self.name_tag = "sfcheck_FinalStage_asm%s_model%s" \
                                 %(str(idx_model[0]), str(idx_model[1])) 
                else:    
                    self.name_tag = "sfcheck_FinalStage_seq%s_struct%s_model%s" \
                                 %(str(idx_model[0]), str(idx_model[1]), str(idx_model[2]))

                self.log_name = os.path.join(self._path_dict['doc_path'], self.name_tag + ".log") 
                self.xml_name = os.path.join(self._path_dict['xml_path'], self.name_tag + ".xml") 

            self.execute()
 
            # reorganize the files 
            self.file_manu(idx_stage)

            # analyse info in XML file
            if idx_stage == 1 or idx_stage == 0:
                self.info_analysis(idx_stage)
            elif idx_stage == 2:
                self.info_analysis(idx_stage,t_model)
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content']) 
            self._path_dict['process_log_content'] = ""

    def info_analysis(self, idx_stage = 1, t_model = None):

        if not self.idx_err:
            # Open XML file
            try:
                sfcheck_xml = open(self.xml_name,"r")
            except IOError:
                print   " could not find %s for reading " % self.xml_name
                self._path_dict['process_log_content'] += \
                        " could not find %s for reading " % self.xml_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1

            # parse contents of XML file
            try:
                ent_xml_reader   = PyExpat.Reader()
                ent_xml_document = ent_xml_reader.fromStream(sfcheck_xml)
                sfcheck_xml.close()
            except ExpatError:
                print "can not create a reader object for XML file"
                self._path_dict['process_log_content'] += \
                        " can not create a reader object for XML file " 
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1

            rootElement = StripXml(ent_xml_document.documentElement)
            #print "here is the root element of the document: %s " % rootElement.nodeName
            #print "The follow are its child elements:"

            if idx_stage == 1 or idx_stage == 0:
                # Create an object that will contain all info extracted structure factor data
                self.info_strucFactor = SF_info()
                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.info_strucFactor.set_err_level(node.firstChild.nodeValue)
                        if self.info_strucFactor.get_err_level():
                            self.idx_err = 1
                    elif node.nodeName == "err_message":
                        self.info_strucFactor.set_job_message(node.firstChild.nodeValue)
                        if self.idx_err :
                            print "ERROR MESSAGE: %s" % self.info_strucFactor.get_job_message()
                            self._path_dict['process_log_content'] += \
                                   ("ERROR MESSAGE: %s" % self.info_strucFactor.get_job_message())
                    elif node.nodeName == "sg":
                        self.info_strucFactor.set_space_group(node.firstChild.nodeValue)
                    elif node.nodeName == "nsym":
                        self.info_strucFactor.set_nsym (node.firstChild.nodeValue)
                    elif node.nodeName == "vol":
                        self.info_strucFactor.set_volume(node.firstChild.nodeValue)
                    elif node.nodeName == "resmax":
                        self.info_strucFactor.set_resmax(node.firstChild.nodeValue)
                    elif node.nodeName == "resmin":
                        self.info_strucFactor.set_resmin(node.firstChild.nodeValue)
                    elif node.nodeName == "opt_res":
                        self.info_strucFactor.set_opt_res(node.firstChild.nodeValue)
                    elif node.nodeName == "cell":
                        self.info_strucFactor.set_cell(node.firstChild.nodeValue)
                        cell_para = self.info_strucFactor.get_cell().strip().split()
                        self.info_strucFactor.cell_len = \
                             self.info_strucFactor.get_cell_para(cell_para[0:3])
                        self.info_strucFactor.cell_ang = \
                             self.info_strucFactor.get_cell_para(cell_para[3:6])
                        # need further processing
                    elif node.nodeName == "data_compl":
                        self.info_strucFactor.set_data_compl ( node.firstChild.nodeValue)
                    elif node.nodeName == "boverall":
                        self.info_strucFactor.set_b_overall ( node.firstChild.nodeValue)
                    elif node.nodeName == "aniso":
                        self.info_strucFactor.set_aniso ( node.firstChild.nodeValue)
                    elif node.nodeName == "pst":
                        self.info_strucFactor.set_pseudo_trans (node.firstChild.nodeValue)
                    elif node.nodeName == "twin":
                        self.info_strucFactor.set_twin(node.firstChild.nodeValue)
                    elif node.nodeName == "fobs":
                        fobs_name = node.getAttribute("fobs_file")
                        if glob.glob(self.fobs_name):
                            self.info_strucFactor.set_fobs_file(self.fobs_name)
                        else :
                            self.info_strucFactor.set_fobs_file(fobs_name)

                if self.info_strucFactor.get_nsym() > 0 and self.info_strucFactor.get_volume() > 0.0:
                    self.info_strucFactor.set_cell_nmon ()

                # print out the results
                flo_pseudo_trans = float(self.info_strucFactor.get_pseudo_trans())
                if flo_pseudo_trans < 0.1 :
                    t_psudo_trans = "not detected"
                else :
                    t_psudo_trans = fpformat.fix(flo_pseudo_trans,2) + "%"
                flo_twin = float(self.info_strucFactor.get_twin())
                if math.fabs(flo_twin) < 0.01 :
                    t_twin = "not detected"
                else :
                    t_twin = fpformat.fix(flo_twin,3) 
                if not self.idx_err and idx_stage == 1:
                    print "Information about the structure to be solved  "
                    print "|--------------------------------------------|"
                    print "|  SPACE GROUP   |","%s"% self.info_strucFactor.get_space_group().center(25),"|" 
                    print "|----------------|---------------------------|"
                    print "|  CELL LENGTH   |","%s" %self.info_strucFactor.cell_len.center(25),"|"
                    print "|----------------|---------------------------|"
                    print "|  CELL ANGLE    |","%s" %self.info_strucFactor.cell_ang.center(25),"|" 
                    print "|----------------|---------------------------|"
                    print "|  RESOLUTIN_MAX |","%s" %self.info_strucFactor.get_resmax().center(25),"|" 
                    print "|----------------|---------------------------|"
                    print "|  RESOLUTIN_MIN |","%s" %self.info_strucFactor.get_resmin().center(25),"|" 
                    print "|----------------|---------------------------|"
                    print "|  DATA_COMPL    |","%s" %(self.info_strucFactor.get_data_compl()+"%").center(25),"|"  
                    print "|----------------|---------------------------|"
                    print "|  PSEUDO_TRANS  |","%s" %t_psudo_trans.center(25),"|"
                    print "|----------------|---------------------------|"
                    print "|  ALPHA_TWIN    |","%s" %t_twin.center(25),"|"
                    print "|----------------|---------------------------|"

                    # To file 
                    self._path_dict['process_log_content'] += \
                          "Information about the structure to be solved\n"
                    self._path_dict['process_log_content'] += \
                          "|------------------------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  SPACE GROUP   |%s|\n"% self.info_strucFactor.get_space_group().center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  CELL LENGTH   |%s|\n" %self.info_strucFactor.cell_len.center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  CELL ANGLE    |%s|\n" %self.info_strucFactor.cell_ang.center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  RESOLUTIN_MAX |%s|\n" %self.info_strucFactor.get_resmax().center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  RESOLUTIN_MIN |%s|\n" %self.info_strucFactor.get_resmin().center(25) 
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  DATA_COMPL    |%s|\n" %(self.info_strucFactor.get_data_compl()+"%").center(25) 
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  PSEUDO_TRANS  |%s|\n" %t_psudo_trans.center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "|  ALPHA_TWIN    |%s|\n" %t_twin.center(25)
                    self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"

            if idx_stage == 2:
                n_chains  = 0
                n_chain_m = 0
                t_model.found_chains = [ ]
                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        t_model.set_err_level(node.firstChild.nodeValue)
                        if t_model.get_err_level():
                            self.idx_err = 1
                    elif node.nodeName == "err_message":
                        t_model.set_err_message(node.firstChild.nodeValue)
                        if t_model.get_err_level():
                            print "ERROR MESSAGE: %s" % t_model.get_err_message()
                            self._path_dict['process_log_content'] += \
                                  "ERROR MESSAGE: %s\n" % t_model.get_err_message()
                    elif node.nodeName == "scoreD":
                        t_model.set_scoresD(node.firstChild.nodeValue)
                    elif node.nodeName == "scoreC":
                        t_model.set_scoresC(node.firstChild.nodeValue)
                    elif node.nodeName == "corr":
                        t_model.set_corr(node.firstChild.nodeValue)
                    elif node.nodeName == "rfac":
                        t_model.set_rfac(node.firstChild.nodeValue)
                    elif node.nodeName == "nchain":
                        t_model.set_nchains(node.firstChild.nodeValue)
                        n_chain_m = t_model.get_nchains()
                        print "Number of chains in the model is %d " % n_chain_m
                        self._path_dict['process_log_content'] += \
                              "Number of chains in the model is %d\n" % n_chain_m
                    elif node.nodeName == "chain":  
                        a_chain = Chain()
                        n_chains = n_chains + 1 
                        for node_child in node.childNodes:
                            if node_child.nodeName == "Chain_ID":
                                a_chain.set_chainID(node_child.firstChild.nodeValue) 
                            if node_child.nodeName == "scoreC":
                                a_chain.set_scoreC(node_child.firstChild.nodeValue) 
                        t_model.found_chains.append(a_chain)

                if n_chains != t_model.get_nchains(): 
                    print "n_chains is ", n_chains 
                    print "Check number of chains in the xml file !!! "
                    self._path_dict['process_log_content'] += \
                          "n_chains is \n", n_chains 
                    self._path_dict['process_log_content'] += \
                          "Check number of chains in the xml file !!! \n"
                    self.idx_err = 1

                if n_chain_m and not self.idx_err:
                    print "|--------------------------|"
                    print "| Chain |  ID  |  ScoreC   |"
                    print "|-------|------|-----------|"
                    self._path_dict['process_log_content'] += \
                          "|--------------------------|\n"
                    self._path_dict['process_log_content'] += \
                          "| Chain |  ID  |  ScoreC   |\n"
                    self._path_dict['process_log_content'] += \
                          "|-------|------|-----------|\n"
                    for i in range(n_chain_m):
                        print "|%s|%s|%s|"% (str(i+1).center(7),\
                               t_model.found_chains[i].get_chainID().center(6),\
                               str(t_model.found_chains[i].get_scoreC()).center(11))
                        self._path_dict['process_log_content'] += \
                              "|%s|%s|%s|\n"% (str(i+1).center(7),\
                               t_model.found_chains[i].get_chainID().center(6),\
                               str(t_model.found_chains[i].get_scoreC()).center(11))
                        print "|-------|------|-----------|"
                        self._path_dict['process_log_content'] += \
                              "|-------|------|-----------|\n"
        else:
            print "#-----------------------------------------------------------#"
            print "# Structure factor data analysis stoped because of errors!  #"
            print "#-----------------------------------------------------------#"
            self._path_dict['process_log_content'] += \
                  "#-----------------------------------------------------------#\n"
            self._path_dict['process_log_content'] += \
                  "# Structure factor data analysis stoped because of errors!  #\n"
            self._path_dict['process_log_content'] += \
                  "#-----------------------------------------------------------#\n"

###########################################################
class SEQ_Analysis :
    """ A class that manages sequence analysis by selectively runing
        different programs such as search_DB (current default) and other codes
        (future) according to their feedback"""
    
    def __init__( self, manager_obj):
         
        # set the default code to be 'search_DB' and other codes to be plugged in if 
        # the former fails
        self.__code_dict= {}
        self.idx_err = 0
        self.setExeCode("search_DB")
        
        # create an object of the search_DB class as default
        self.SearchDB = CSEARCH_DB(manager_obj)

    def setExeCode(self, name = None):
        
        if name:
            self.__code_dict["exeCode"] = name
        else :
            # temporarily
            print "  which code you want to run ? "
            self.idx_err = 0

    def execute( self, t_cell, t_spaceGroup, t_volume, t_nsym, t_resmax, t_remin,
                 t_opt_res, t_b_overall):

        # If searchDB key is not disabled, run it first
        if self.__code_dict["exeCode"]  == "search_DB" and \
               not self.SearchDB.idx_err:
            self.SearchDB.SetSfparas(t_cell, t_spaceGroup, t_volume, t_nsym, t_resmax,
                                      t_remin, t_opt_res, t_b_overall)
            self.SearchDB.controller()

            # If seach_DB doesn't work, disabled its key
            # and enabble the key of alternate codes
            #if self.Search_DB.error_index_seq :
            #   self.setExeCode("virtualCode")

class CSEARCH_DB (CExeCode) :
    """ A class that performs sequence database search, using
        the program 'search_DB'. The class is inheritted from CExeCode """
    
    def __init__( self, manager_obj ):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, manager_obj.pathDict)
        self.__exeCode = os.path.join(self._path_dict["bin_path"], "search_DB")

        self.mode = manager_obj.mode
        self.idx_err = 0

        print "\n#-----------------------------------------------------------#"
        print "# Model Database Analysis                                   #"
        print "#-----------------------------------------------------------#"

        self._path_dict['process_log_content'] = \
              "\n#-----------------------------------------------------------#\n"
        self._path_dict['process_log_content'] += \
              "# Model Database Analysis                                   #\n"
        self._path_dict['process_log_content'] += \
              "#-----------------------------------------------------------#\n"
      
        if self._path_dict.has_key("infile_seq"):
            self.seq_name  = self._path_dict["infile_seq"] 
            if not glob.glob(self.seq_name):
                print "The file %s does not exist \n " % self.seq_name
                self._path_dict['process_log_content'] += \
                      "The file %s does not exist \n " % self.seq_name
                self.idx_err = 1

        self.seq_log_name  = os.path.join(self._path_dict["doc_path"],  "search_DB_seq.log")
        self.seq_xml_name  = os.path.join(self._path_dict["xml_path"],  "search_DB_seq.xml")

        self.structDB_log_name  = os.path.join(self._path_dict["doc_path"], 
                                  "get_structure_DB_" + self._path_dict["name_root"] + ".log")
        self.structDB_xml_name  = os.path.join(self._path_dict["xml_path"], 
                                  "get_structure_DB_" + self._path_dict["name_root"] + ".xml")

        self.output_dict = {}

        self.best_mod_sim = 0.0

    def SetSfparas(self, t_cell, t_spaceGroup, t_volume, t_nsym, t_resmax, t_resmin,
                   t_opt_res, t_b_overall):
        """Set the parameters values acoording to the previous sf analysis"""
        
        self.info_strucFactor = SF_info()
        self.info_strucFactor.set_cell(t_cell)
        self.info_strucFactor.set_space_group(t_spaceGroup)
        self.info_strucFactor.set_volume(t_volume)
        self.info_strucFactor.set_nsym(t_nsym)
        self.info_strucFactor.set_resmax(t_resmax)
        self.info_strucFactor.set_resmin(t_resmin)
        self.info_strucFactor.set_opt_res(t_opt_res)
        self.info_strucFactor.set_b_overall(t_b_overall)

    # Sequence search

    def  setCmdLineAndFile (self ) :
        """ set the command lines for the code 'search_DB', each code has an unique one,
        which overrides the corresponding method in the base class """

        self.seq_log = open(self.seq_log_name, "w")
        # creat the batch file
        self.batch_name  = os.path.join(self._path_dict["scr_path"],
                           "search_DB_" + self._path_dict["name_root"] + ".bat")
     
        try:
            search_DB_bat = open(self.batch_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                "%s could not be opened for write \n" %self.batch_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else:
   
            os.putenv("MOLREP_DB", self._path_dict["sys_path"])
            os.putenv("MOLREP_DB_rep", self.seq_log_name)
            print >> search_DB_bat,  self.__exeCode, " << stop >>$MOLREP_DB_rep"  
            print >> search_DB_bat, "_DOC Y>%s " % (self._path_dict["doc_path"] + "/")
            print >> search_DB_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"] + "/" )
            print >> search_DB_bat, "_FILE_S  %s " % self.seq_name
            if self.mode == 2 :
                print >> search_DB_bat, "_USER_D  %s " % self._path_dict["infile_pdb_lib"]
                print >> search_DB_bat, "_USER_L  %s " % self._path_dict["infile_pdb_list"]
        
            print >> search_DB_bat, "_SIM_LIM   0.15 "    
            print >> search_DB_bat, "_NSEQ_MAX  20 "   
            print >> search_DB_bat, "_END  "
            print >> search_DB_bat, "stop \n\n"
            
            search_DB_bat.close()
            self._cmdline =  ' %s  < %s \n' %  (self.__exeCode, self.batch_name)
    
    def seqDB_run(self):
        """ write and execute a batch file to run 'search_DB' """

        # creat the batch file        
        self.batch_name  = os.path.join(self._path_dict["scr_path"], 
                           "search_DB_" + self._path_dict["name_root"] + ".bat")
        try:
            search_DB_bat = open(self.batch_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                "%s could not be opened for write \n" %self.batch_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else:
            os.putenv("MOLREP_DB", self._path_dict["sys_path"])
            # os.putenv("MOLREP_DB_rep", self.seq_log_name)
            #print >> search_DB_bat, "# -------------------------------- "
            #print >> search_DB_bat,  self.__exeCode, " << stop >> $MOLREP_DB_rep"
            print >> search_DB_bat, "_DOC Y>%s" % (self._path_dict["doc_path"] + "/" )
            print >> search_DB_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"] + "/")
            print >> search_DB_bat, "_FILE_S  %s" % self.seq_name

            if self.mode == 2 :
                print >> search_DB_bat, "_USER_D  %s " % self._path_dict["infile_pdb_lib"]
                print >> search_DB_bat, "_USER_L  %s " % self._path_dict["infile_pdb_list"]

            print >> search_DB_bat, "_SIM_LIM   0.15 "    # NEED CONSIDER HERE
            print >> search_DB_bat, "_NSEQ_MAX  20 "     # NEED CONSIDER HRER
            print >> search_DB_bat, "_END  "
            # print >> search_DB_bat, "stop \n\n"
            search_DB_bat.close()

            #os.chmod(self.batch_name, 0755)
            
            time.sleep(2)
            #os.system(self.batch_name)
            self.log_name = self.seq_log_name
            self._cmdline =  ' %s  < %s \n' %  (self.__exeCode, self.batch_name)
            self.execute()


        # This part should be done within "search_DB" code
         
        t_xml =  os.path.join(self._path_dict["doc_path"], "search_DB.xml")
        if not glob.glob(t_xml):
            print "no search_DB.xml is generated  "
            self._path_dict['process_log_content'] += \
                 "no search_DB.xml is generated  "
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else :
            shutil.move(t_xml, self.seq_xml_name)
    
    def seqDB_info_analysis(self):
        """Extract information from the XML file created by search_DB """

        if not self.idx_err:
            # print "\nSequence search finished "
            # Open XML file
            try:
                search_DB_xml = open(self.seq_xml_name,"r")
            except IOError:
                print  self.xml_name  , " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                       "%s could not be opened for reading " %self.xml_name
 
                self.idx_err = 1
            # Parse contents of XML file
            try:
                seqDB_xml_reader   = PyExpat.Reader()
                seqDB_xml_document = seqDB_xml_reader.fromStream(search_DB_xml)
                search_DB_xml.close()
            except ExpatError:
                print "Can not create a reader object for XML file ", self.xml_name
                self._path_dict['process_log_content'] += \
                      "%s Can not create a reader object for XML file " %self.xml_name
                self.idx_err = 1

            if not self.idx_err:
                rootElement = StripXml(seqDB_xml_document.documentElement)

                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.output_dict["seqDB_err_level"] = int(node.firstChild.nodeValue)
                        if self.output_dict["seqDB_err_level"]:
                            self.idx_err = 1
                        # print "index of ERROR: %d " % self.output_dict["seqDB_err_level"]
                    elif node.nodeName == "err_message":
                        self.output_dict["seqDB_err_message"] = node.firstChild.nodeValue
                        if  int(self.output_dict["seqDB_err_level"]) == 1:
                            print "Error message : no memory for alignement"
                            self._path_dict['process_log_content'] += \
                                  "Error message : no memory for alignement\n"
                        elif  int(self.output_dict["seqDB_err_level"]) == 2:
                            print "Error message : input sequence file : open/read"
                            self._path_dict['process_log_content'] += \
                                  "Error message : input sequence file : open/read\n"
                        elif  int(self.output_dict["seqDB_err_level"]) == 3:
                            print "Error message :  chain_list_DB: open/read"
                            self._path_dict['process_log_content'] += \
                                  "Error message :  chain_list_DB: open/read\n"
                        elif  int(self.output_dict["seqDB_err_level"]) == 4:
                            print "Error message : wrong setenv MOLREP_DB"
                            self._path_dict['process_log_content'] += \
                                  "Error message : wrong setenv MOLREP_DB\n"
                        elif  int(self.output_dict["seqDB_err_level"]) == 5:
                            print "The closest homologue found is less than 20%. "
                            print "The likelihood of finding a solution is too low."
                            self._path_dict['process_log_content'] += \
                                  "The closest homologue found is less than 20%. \n"
                            self._path_dict['process_log_content'] += \
                                  "The likelihood of finding a solution is too low.\n"
                        elif  int(self.output_dict["seqDB_err_level"]) == 6:
                            print "Error message :  output file-temp_chain_list.txt: open/write"
                            self._path_dict['process_log_content'] += \
                                  "Error message :  output file-temp_chain_list.txt: open/write\n"
                        else :
                            # all the rest cases alexei probably will add
                            if int(self.output_dict["seqDB_err_level"]):
                                print self.output_dict["seqDB_err_message"]
                                self._path_dict['process_log_content'] += \
                                      (self.output_dict["seqDB_err_message"] + "\n")
                                   
                    elif node.nodeName == "job":
                        self.output_dict["exe_code_seqDB"] = node.firstChild.nodeValue
                    elif node.nodeName == "n_structure":
                        self.output_dict["n_structure_seqDB"] = int(node.firstChild.nodeValue)
                        print self.output_dict["n_structure_seqDB"],\
                              " structures found to be above 15% identity with the given sequence," 
                        self._path_dict['process_log_content'] += \
                              "%d structures found to be above 15%s identity with the given sequence, \n"  \
                              %(self.output_dict["n_structure_seqDB"],"%")
       
                    elif node.nodeName == "identity_best":
                        self.output_dict["identity_best"] = float(node.firstChild.nodeValue)
                        #print "of which the best identity is  ", self.output_dict["identity_best"]
                        #self._path_dict['process_log_content'] += \
                        #      "of which the best identity is %3.1f \n" %self.output_dict["identity_best"]
                    elif node.nodeName == "chain_list":       # wait for alexei to make corrections
                        self.output_dict["chain_list"] = node.getAttribute("temp_chain_list")

            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""

    def structDB_run(self):
        """ write and execute a batch file to run 'search_DB' """
                                                                                              
        # creat the batch file        
        self.structDB_bat_name  = os.path.join(self._path_dict["scr_path"], 
                                  "get_structure_DB_" + self._path_dict["name_root"] + ".bat")
        try:
            structDB_bat = open(self.structDB_bat_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                  "%s could not be opened for write" %self.batch_name,
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1

        if not self.idx_err:
            os.putenv("MOLREP_DB", self._path_dict["sys_path"])
            # os.putenv("MOLREP_DB_rep", self.structDB_log_name)

            # print >> structDB_bat, "# -------------------------------- "
            # print >> structDB_bat, self._path_dict["bin_path"] + "/get_structure_DB << stop >> $MOLREP_DB_rep"
            print >> structDB_bat, "_DOC Y>%s " %(self._path_dict["doc_path"] +"/")
            print >> structDB_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"] +"/") 
            if self._path_dict.has_key("infile_seq"):
                print >> structDB_bat, "_FILE_S  %s" % self.seq_name
            if self.mode != 1:
                print >> structDB_bat, "_FILE_L  %s" % self.output_dict["chain_list"]
            if self.mode == 1:
                print >> structDB_bat, "_FILE_PDB %s " % self._path_dict["infile_pdb"]
            if self.mode == 2:
                print >> structDB_bat, "_USER_D  %s " % self._path_dict["infile_pdb_lib"]
                print >> structDB_bat, "_USER_L  %s " % self._path_dict["infile_pdb_list"]
            if self.mode == 4:
                print >> structDB_bat, "file_mx  %s " % self._path_dict["fixed_mod"]
            if self.mode != 3:
                print >> structDB_bat, "_CELL ", self.info_strucFactor.get_cell()
                print >> structDB_bat, "_SPACE_GR ", self.info_strucFactor.get_space_group()
                print >> structDB_bat, "_NSYM ",  self.info_strucFactor.get_nsym()
                # print >> structDB_bat, "_VOLUME %9.2f " % self.info_strucFactor.get_volume()
                # print "volume ", self.info_strucFactor.get_volume()
                print >> structDB_bat, "_RESMAX  ", self.info_strucFactor.get_resmax()
                print >> structDB_bat, "_RESMIN  ", self.info_strucFactor.get_resmin()
                print >> structDB_bat, "_OPT_RESOL", self.info_strucFactor.get_opt_res()
                print >> structDB_bat, "_BOVERALL ", self.info_strucFactor.get_b_overall()
                print >> structDB_bat, "_NSEQ_MAX  5"    # NEED CONSIDER HRER
            if self.mode == 3: 
                print >> structDB_bat, "_NSEQ_MAX " , " 10 "   # NEED CONSIDER HRER
            print >> structDB_bat, "_END \n"
            structDB_bat.close()
            
            # execmd = "csh " + self.structDB_bat_name
            # os.system(execmd)

            #os.chmod(self.structDB_bat_name, 0755)

            time.sleep(2)
            #os.system(self.structDB_bat_name)

            self.log_name = self.structDB_log_name
            self.__exeCode = self._path_dict["bin_path"] + "/get_structure_DB"
            self._cmdline =  '%s  < %s'%  (self.__exeCode, self.structDB_bat_name)
            self.execute()

        # This part should be done within "get_structure_DB" code        
        t_xml = os.path.join(self._path_dict["doc_path"], "get_structure_DB.xml")
        if not glob.glob(t_xml):
            print "no get_structure_DB.xml is generated  "
            self._path_dict['process_log_content'] += \
                  "no get_structure_DB.xml is generated  "
            self.idx_err = 1
        else :
            shutil.move(t_xml, self.structDB_xml_name)

        t_doc = os.path.join(self._path_dict["cur_path"], "get_structure_DB.doc")
        if  glob.glob(t_doc):
            shutil.move(t_doc, self._path_dict['doc_path'])
        t_bat = os.path.join(self._path_dict["cur_path"], "get_structure_DB.bat")
        if glob.glob(t_bat):
            shutil.move(t_bat, self._path_dict['scr_path'])

    def structDB_info_analysis(self):
        """Extract information from the XML file created by search_DB """

        if not self.idx_err:
            # print "\nModel search finished "
            # Open XML file
            try:
                struct_DB_xml = open(self.structDB_xml_name,"r")
            except IOError:
                print  self.structDB_xml_name, " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                    "%s could not be opened for reading" %s
                self.idx_err = 1

            # Parse contents of XML file
            try:
                struct_xml_reader   = PyExpat.Reader()
                struct_xml_document = struct_xml_reader.fromStream(struct_DB_xml)
                struct_DB_xml.close()
            except ExpatError:
                print "can not create a reader object for XML file for ", self.structDB_xml_name
                self._path_dict['process_log_content'] += \
                      "%s can not create a reader object for XML file for "%self.structDB_xml_name
                self.idx_err = 1

            rootElement = StripXml(struct_xml_document.documentElement)
            # print "here is the root element of the get_structure_DB.xml: %s " \
            # % rootElement.nodeName

            if not self.idx_err:
                self.allMODELS = {}
                self.allMODELS['seqs'] = []
                idx_seq = 0
                idx_asm = 0

                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.output_dict["structDB_err_level"] = int(node.firstChild.nodeValue)
                        if self.output_dict["structDB_err_level"]:
                            self.idx_err = 1
                    elif node.nodeName == "err_message":
                        self.output_dict["structDB_err_message"] = node.firstChild.nodeValue
                        if  int(self.output_dict["structDB_err_level"]) == 1:
                            print "Error message : no memory for alignement"
                            self._path_dict['process_log_content'] += \
                                  "Error message : no memory for alignement"
                        elif  int(self.output_dict["structDB_err_level"]) == 2:
                            print "Error message : input sequence file : open/read"
                            self._path_dict['process_log_content'] += \
                                  "Error message : input sequence file : open/read"
                        elif  int(self.output_dict["structDB_err_level"]) == 3:
                            print "Error message :  chain_list_DB: open/read"
                            self._path_dict['process_log_content'] += \
                                  "Error message :  chain_list_DB: open/read"
                        elif  int(self.output_dict["structDB_err_level"]) == 4:
                            print "Error message : wrong setenv MOLREP_DB"
                            self._path_dict['process_log_content'] += \
                                  "Error message : wrong setenv MOLREP_DB"
                        elif  int(self.output_dict["structDB_err_level"]) == 5:
                            print "Error message : no PDB structure was found"
                            self._path_dict['process_log_content'] += \
                                  "Error message : no PDB structure was found"
                        elif  int(self.output_dict["structDB_err_level"]) == 6:
                            print "Error message :  output file-temp_chain_list.txt: open/write"
                            self._path_dict['process_log_content'] += \
                                  "Error message :  output file-temp_chain_list.txt: open/write"
                        elif  int(self.output_dict["structDB_err_level"]) == 7:
                            print "Error message : there is no file of seq_list or pdb"
                            self._path_dict['process_log_content'] += \
                                  "Error message : there is no file of seq_list or pdb"
                        elif  int(self.output_dict["structDB_err_level"]) == 8:
                            print "Error message :  no structure was found "
                            self._path_dict['process_log_content'] += \
                                  "Error message :  no structure was found "
                        else :
                            # all the rest cases alexei probably will add
                            if int(self.output_dict["structDB_err_level"]):
                                print self.output_dict["structDB_err_message"] 
                                self._path_dict['process_log_content'] += \
                                      (self.output_dict["structDB_err_message"]  + "\n")
                    elif node.nodeName == "job":
                        self.output_dict["exe_code_structDB"] = node.firstChild.nodeValue
                    elif node.nodeName == "sequence":
                        # get a sequence
                        seq_tm = Sequence()
                        idx_seq +=1
                        seq_tm.set_index(idx_seq)
                        idx_str = 0
                        for prop_of_seq in node.childNodes:
                            if prop_of_seq.nodeName == "n_structure":
                                num_structures_t = int(prop_of_seq.firstChild.nodeValue)
                            if prop_of_seq.nodeName == "structure":
                                # create a structure
                                struct_t = Structure()
                                 
                                idx_str +=1
                                struct_t.set_index(idx_seq, idx_str)
                                idx_mod = 0
                                for prop_of_struct in prop_of_seq.childNodes:
                                    if prop_of_struct.nodeName == "PDB_code":
                                        pdb_t = prop_of_struct.firstChild.nodeValue.lstrip()
                                        pdb_t = pdb_t.rstrip()
                                        struct_t.set_PDB_code(pdb_t)
                                        
                                    if prop_of_struct.nodeName == "model":
                                        # get a model in that structure
                                        model_t = Model()
                                        if self.mode != 3:
                                            model_t.sfInfo.set_space_group(self.info_strucFactor.get_space_group())
                                        idx_mod +=1
                                        model_t.set_index(idx_seq, idx_str, idx_mod)
                                        model_t.name_tag = "sq" + str(idx_seq) + "st" + str(idx_str) + "m" + str(idx_mod)
                                        model_t.set_pdb_code(pdb_t)
                                        if self._path_dict.has_key("infile_mtz"):
                                            model_t.mr_in_hkl = self._path_dict["infile_mtz"]
                                            model_t.refi_in_hkl = self._path_dict["infile_mtz"]
                                        # set the properties for the newly found model
                                        for prop_of_model in prop_of_struct.childNodes:
                                            if prop_of_model.nodeName == "complex":
                                                model_t.set_complex(prop_of_model.firstChild.nodeValue)
                                                model_t.set_numCopies()
                                            if prop_of_model.nodeName == "chain":
                                                model_t.set_chain(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "domain":
                                                model_t.set_domain(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "domain_code":
                                                model_t.set_domain_PDB_code(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "radius":
                                                model_t.set_radius(prop_of_model.firstChild.nodeValue) 
                                            if prop_of_model.nodeName == "volume":
                                                model_t.set_volume(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "nres":
                                                model_t.set_nres(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "similarity":
                                                model_t.set_similarity(prop_of_model.firstChild.nodeValue)
                                                cur_mod_sim = model_t.get_similarity()
                                                if cur_mod_sim > self.best_mod_sim:
                                                    self.best_mod_sim = cur_mod_sim
                                            if prop_of_model.nodeName == "similarity_ens":
                                                model_t.set_sim_ens(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "mod_compl":
                                                model_t.set_mol_compl(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "resmax_used":
                                                model_t.set_resmax(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "nmon":
                                                model_t.set_nmon(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "surf":
                                                model_t.set_surface(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "coordinates":
                                                if not model_t.mr_in_xyz:
                                                    model_t.mr_in_xyz = prop_of_model.getAttribute("file_crd")
                                                if not model_t.mr_in_xyz_ens:
                                                    model_t.mr_in_xyz_ens = prop_of_model.getAttribute("file_ens").strip()
                                                    if model_t.mr_in_xyz_ens != "null" and  model_t.mr_in_xyz_ens != "":
                                                        model_t.ens_enable ="YES"

                                            if prop_of_model.nodeName == "sequence":
                                                model_t.infile_seq = prop_of_model.getAttribute("file_seq")

                                        # add this model to the current structure
                                        if struct_t.get_PDB_code() != "MDOM":
                                            if model_t.get_multimer() != "Monomer":
                                                struct_t.multimers.append(model_t)
                                            else :
                                                struct_t.monomers.append(model_t)
                                            if model_t.get_domain() == "Yes":
                                                struct_t.domains.append(model_t) 
                                         
                                        struct_t.add_model(model_t)

                                # add this structure to the current sequence
                                if len(struct_t.multimers) > 1:
                                    struct_t.multimers.sort(ModelCmp)
                                if len(struct_t.domains) > 1:
                                    struct_t.domains.sort(ModelCmp)
                                if struct_t.get_PDB_code() == "MDOM":
                                    struct_t.get_all_models().sort(ModelCmp)
                                    

                                seq_tm.add_structure(struct_t)

                        # add this sequence to the sequence list
                        if seq_tm.get_num_structures() != num_structures_t:
                            print "the number of structures in this sequence is not right! "
                            self._path_dict['process_log_content'] += \
                                  "the number of structures in this sequence is not right! "
                            self.idx_err =1

                        if not self.idx_err:
                            self.allMODELS['seqs'].append(seq_tm)

                    elif node.nodeName == "assembly":
                        self.allMODELS['asms'] = []
                        # begin of all assemblies section 
                        # note: different from "sequence" 
                        idx_asm = 0
                        for prop_of_asm in node.childNodes:
                            if prop_of_asm.nodeName == "structure":
                                # create an assembly 
                                asm_tm = Assembly()
                                idx_asm +=1
                                asm_tm.set_index(idx_asm)
                                idx_mod = 0
                                for prop_of_a_asm in prop_of_asm.childNodes:
                                    if prop_of_a_asm.nodeName == "PDB_code":
                                        pdb_t = prop_of_a_asm.firstChild.nodeValue.lstrip()
                                        pdb_t = pdb_t.rstrip()
                                        asm_tm.name = pdb_t
                                    if prop_of_a_asm.nodeName == "model":
                                        # get a model in that assembly
                                        model_t = Model()
                                        if self.mode != 3:
                                            model_t.sfInfo.set_space_group(self.info_strucFactor.get_space_group())
                                        model_t.asm = 1
                                        idx_mod +=1
                                        model_t.set_index_asm(idx_asm, idx_mod)
                                        model_t.name_tag = "as" + str(idx_asm) + "m" + str(idx_mod)
                                        model_t.set_pdb_code(pdb_t)
                                        if self._path_dict.has_key('infile_mtz'):
                                            model_t.mr_in_hkl = self._path_dict["infile_mtz"]
                                            model_t.refi_in_hkl = self._path_dict["infile_mtz"]
                                        # set the properties for the newly found model
                                        
                                        for prop_of_model in prop_of_a_asm.childNodes:
                                            if prop_of_model.nodeName == "complex":
                                                model_t.set_complex(prop_of_model.firstChild.nodeValue)
                                                model_t.set_numCopies()
                                            if prop_of_model.nodeName == "chain":
                                                model_t.set_chain(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "domain":
                                                model_t.set_domain(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "domain_code":
                                                model_t.set_domain_PDB_code(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "Nseq":
                                                model_t.num_seqs  = int(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "Iseq":
                                                model_t.seqs.append(int(prop_of_model.firstChild.nodeValue))
                                            if prop_of_model.nodeName == "str_code":
                                                model_t.seqs_name.append(prop_of_model.firstChild.nodeValue.strip())
                                            if prop_of_model.nodeName == "radius":
                                                model_t.set_MOLREP_RAD2(float(prop_of_model.firstChild.nodeValue))  
                                            if prop_of_model.nodeName == "volume":
                                                model_t.set_volume(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "nres":
                                                model_t.set_nres(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "similarity":
                                                model_t.set_similarity(prop_of_model.firstChild.nodeValue)
                                                cur_mod_sim = model_t.get_similarity()
                                                if cur_mod_sim > self.best_mod_sim:
                                                    self.best_mod_sim = cur_mod_sim
                                            if prop_of_model.nodeName == "similarity_ens":
                                                model_t.set_sim_ens(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "mod_compl":
                                                model_t.set_mol_compl(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "resmax_used":
                                                model_t.set_resmax(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "nmon":
                                                model_t.set_nmon(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "surf":
                                                model_t.set_surface(prop_of_model.firstChild.nodeValue)
                                            if prop_of_model.nodeName == "coordinates":
                                                if not model_t.mr_in_xyz:
                                                    model_t.mr_in_xyz = prop_of_model.getAttribute("file_crd")
                                                if not model_t.mr_in_xyz_ens:
                                                    model_t.mr_in_xyz_ens = prop_of_model.getAttribute("file_ens").strip()
                                                    if model_t.mr_in_xyz_ens != "null" and  model_t.mr_in_xyz_ens != "":
                                                        model_t.ens_enable ="YES"
                                            if prop_of_model.nodeName == "sequence":
                                                model_t.infile_seq = prop_of_model.getAttribute("file_seq")

                                        t_str = ""
                                        for a_name in model_t.seqs_name:
                                            if t_str :
                                                t_str = t_str + "+" + a_name
                                            else :
                                                t_str = t_str + a_name

                                        model_t.set_pdb_code(t_str)
                                        # add this model to the current structure
                                        asm_tm.add_model(model_t)
                                        asm_tm.name = asm_tm.name + "(" +  model_t.get_pdb_code() + ")"

                                # add this assembly to the assemblies
                                asm_tm.models_sort()
                                self.allMODELS['asms'].append(asm_tm) 


                #  Show hierachy and relationships between assemblies,
                #  structures and models
                print "The best identity found is %4.3f " %self.best_mod_sim
                self._path_dict['process_log_content'] += \
                      "The best identity found is %4.3f \n" %self.best_mod_sim

                if not self.idx_err and self.allMODELS.has_key('asms'):
                    n_asms = len(self.allMODELS['asms'])
                    if n_asms:
                        print "\nTotal number of assemblies found is %d \n" \
                              %n_asms
                        self._path_dict['process_log_content'] += \
                              "\nTotal number of assemblies found is %d \n\n" \
                              %n_asms
                               
                    # loop over asm_i all assemblies
                    i_asm = 0
                    for the_asm in self.allMODELS['asms']:
                        n_mods = the_asm.get_num_models()
                        if n_mods:
                            i_asm = i_asm + 1
                            print "BALBES uses %d models associated with assembly %d " \
                                  %( n_mods, i_asm )
                            print "The following are details of them "
                            self._path_dict['process_log_content'] += \
                                  " \nBALBES uses %d models associated with assembly %d \n" \
                                  %( n_mods, i_asm )
                            self._path_dict['process_log_content'] += \
                                  "The following are details of them \n" 
        
                            # loop over all models in the assembly the_asm
                            print "|-------------|-------------------------------------------------|"
                            print "|    Name     |","%s"%the_asm.name.center(47),"|"
                            self._path_dict['process_log_content'] += \
                                  "|-------------|------------------------------------------------|\n"
                            self._path_dict['process_log_content'] += \
                                  "|    Name     |%s|\n" %the_asm.name.center(48)
                            
                                    
                            print "|-------------|-------------------------------------------------|"
                            print "| NO. of MODEL|","%s"%str(the_asm.get_num_models()).center(47),"|"
                            print "|-------------|-------------------------------------------------|"
                            print "| Model | Seq used | Similarity | Residues |  Monomers(expected)|"
                            print "|-------|----------|------------|----------|--------------------|"
                            self._path_dict['process_log_content'] += \
                                  "|-------------|------------------------------------------------|\n"
                            self._path_dict['process_log_content'] += \
                                  "| NO. of MODEL|%s|\n"%str(the_asm.get_num_models()).center(48)
                            self._path_dict['process_log_content'] += \
                                  "|-------------|------------------------------------------------|\n"
                            self._path_dict['process_log_content'] += \
                                  "| Model | Seq used | Similarity | Residues | Monomers(expected)|\n"
                            self._path_dict['process_log_content'] += \
                                  "|-------|----------|------------|----------|-------------------|\n"

                            for a_model in the_asm.get_models():
                                a_model_index = a_model.get_index()
                                if a_model.ens_enable == "YES":
                                    a_model_sim = str(a_model.get_similarity()) + "(ENS)"
                                else :
                                    a_model_sim = str(a_model.get_similarity())

                                t_seqs = ""
                                for t_idx in a_model.seqs:
                                    t_seqs +=(str(t_idx)+",")
                                print "|",str(a_model_index[1]).center(5),\
                                      "|",t_seqs.center(8),\
                                      "|",str(a_model_sim).center(10),\
                                      "|",str(a_model.get_nres()).center(8),\
                                      "|",str(a_model.get_nmon()).center(18),"|"
                                print "|-------|----------|------------|----------|--------------------|"
                                self._path_dict['process_log_content'] += \
                                      "|%s|%s|%s|%s|%s|\n" %(str(a_model_index[1]).center(7),\
                                      t_seqs.center(10),\
                                      str(a_model_sim).center(12),\
                                      str(a_model.get_nres()).center(10),\
                                      str(a_model.get_nmon()).center(19) )
                                self._path_dict['process_log_content'] += \
                                      "|-------|----------|------------|----------|-------------------|\n"
                                CopyFile(a_model.mr_in_xyz,self._path_dict['ser_path'])

                #  confirm hierachy and relationships between sequences,
                #  structures and models

                if not self.idx_err:
                    n_seqs = len(self.allMODELS['seqs'])
                    if n_seqs and self._path_dict.has_key("infile_seq"):
                        print "\nTotal number of sequences input by the user is %d \n" \
                              %n_seqs
                        self._path_dict['process_log_content'] += \
                              "\nTotal number of sequences input by the user is %d \n\n" \
                              %n_seqs
                               
                    # loop over seq_i all sequences
                    i_seq = 0
                    for the_seq in self.allMODELS['seqs']:
                        if the_seq.get_num_structures():
                            i_seq = i_seq + 1
                            print " \nBALBES uses %d structures associated with sequence %d " \
                                  %( the_seq.get_num_structures(), i_seq )
                            print "The following are details of them "
                            self._path_dict['process_log_content'] += \
                                  " \nBALBES uses %d structures associated with sequence %d \n" \
                                  %( the_seq.get_num_structures(), i_seq )
                            self._path_dict['process_log_content'] += \
                                  "The following are details of them \n" 
        
                        # loop over all structures in the sequence the_seq
                        # to show all the infomation is correctlly exetracted and to
                        # organise models in a structure according to their complex
                        # numbers and  domain indexs (if multuiple domains exist) 
                        for struct in the_seq.get_structures():
                            print "\nFor the structure %d in sequence %d" \
                                    % ( struct.get_index()[1], i_seq)
                            self._path_dict['process_log_content'] += \
                                  "\nFor the structure %d in sequence %d \n" \
                                   %(struct.get_index()[1], i_seq)
                            t_pdbcode = struct.get_PDB_code()
                            struct.set_c_radius()
                            if struct.get_c_radius() or t_pdbcode == "MDOM":
                                struct.set_molrep_rad()
                            else :
                                print "No model of complex vaule 100 in this structure ?"
                                self._path_dict['process_log_content'] += \
                                      "No model of complex vaule 100 in this structure ?"
                                sys.exit()
                            if self.mode == 2:
                                t_pdbcode = self.getUserInputPdbCode(struct.get_PDB_code()) 
                            if t_pdbcode != "MDOM":
                                print "|-------------|----------------------------------------------------------------------|"
                                self._path_dict['process_log_content'] += \
                                      "|-------------|----------------------------------------------------------------------|\n"
                                print "| PDB_CODE    |","%s"%t_pdbcode.center(68),"|"
                                self._path_dict['process_log_content'] += \
                                      "| PDB_CODE    |%s|\n" %t_pdbcode.center(70)
                            else :
                                print "|------------------------------------------------------------------------------------|"
                                self._path_dict['process_log_content'] += \
                                      "|------------------------------------------------------------------------------------|\n"
                                print "| %s | " % "Multiple Domain Models From Different PDBs".center(82) 
                                self._path_dict['process_log_content'] += \
                                      "| %s |\n" % "Multiple Domain Models From Different PDBs".center(82)
                            if struct.get_num_models():
                                if t_pdbcode != "MDOM":    
                                    print "|-------------|----------------------------------------------------------------------|"
                                    print "| NO. of MODEL|","%s"%str(struct.get_num_models()).center(68),"|"
                                    print "|-------------|----------------------------------------------------------------------|"
                                    print "| Model | Chain ID | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|"
                                    print "|-------|----------|------------|----------|-----------|---------|-------------------|"
                                    self._path_dict['process_log_content'] += \
                                          "|-------------|----------------------------------------------------------------------|\n"
                                    self._path_dict['process_log_content'] += \
                                          "| NO. of MODEL|%s|\n"%str(struct.get_num_models()).center(70)
                                    self._path_dict['process_log_content'] += \
                                          "|-------------|----------------------------------------------------------------------|\n"
                                    self._path_dict['process_log_content'] += \
                                          "| Model | Chain ID | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|\n"
                                    self._path_dict['process_log_content'] += \
                                          "|-------|----------|------------|----------|-----------|---------|-------------------|\n"
                                else :
                                    print "|------------------------------------------------------------------------------------|"
                                    print "| NO. of MODEL     |","%s"%str(struct.get_num_models()).center(63),"|"
                                    print "|------------------------------------------------------------------------------------|"
                                    print "| Model | PDB_CODE | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|"
                                    print "|-------|----------|------------|----------|-----------|---------|-------------------|"
                                    self._path_dict['process_log_content'] += \
                                          "|------------------------------------------------------------------------------------|\n"
                                    self._path_dict['process_log_content'] += \
                                          "| NO. of MODEL     |%s|\n"%str(struct.get_num_models()).center(65)
                                    self._path_dict['process_log_content'] += \
                                          "|------------------------------------------------------------------------------------|\n"
                                    self._path_dict['process_log_content'] += \
                                          "| Model | PDB_CODE | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|\n"
                                    self._path_dict['process_log_content'] += \
                                          "|-------|----------|------------|----------|-----------|---------|-------------------|\n"

                                for a_model in struct.get_all_models():
                                    a_model_index = a_model.get_index()
                                    if a_model.ens_enable == "YES":
                                        a_model_sim = str(a_model.get_similarity()) + "(ENS)"
                                    else :
                                        a_model_sim = str(a_model.get_similarity())
                                    if t_pdbcode != "MDOM": 
                                        print "|",str(a_model_index[2]).center(5),\
                                              "|",a_model.get_index_chain().center(8),\
                                              "|",str(a_model_sim).center(10),\
                                              "|",str(a_model.get_nres()).center(8),\
                                              "|",a_model.get_multimer().center(9),\
                                              "|",a_model.get_domain().center(7),\
                                              "|",str(a_model.get_nmon()).center(17),"|"
                                        self._path_dict['process_log_content'] += \
                                              "|%s|%s|%s|%s|%s|%s|%s|\n" %(str(a_model_index[2]).center(7),\
                                              a_model.get_index_chain().center(10),\
                                              str(a_model_sim).center(12),\
                                              str(a_model.get_nres()).center(10),\
                                              a_model.get_multimer().center(11),\
                                              a_model.get_domain().center(9),\
                                              str(a_model.get_nmon()).center(19) )
                                    else :
                                        print "|",str(a_model_index[2]).center(5),\
                                              "|",a_model.get_domain_pdb_code().center(8),\
                                              "|",str(a_model_sim).center(10),\
                                              "|",str(a_model.get_nres()).center(8),\
                                              "|",a_model.get_multimer().center(9),\
                                              "|",a_model.get_domain().center(7),\
                                              "|",str(a_model.get_nmon()).center(17),"|"
                                        self._path_dict['process_log_content'] += \
                                              "|%s|%s|%s|%s|%s|%s|%s|\n" %(str(a_model_index[2]).center(7),\
                                              a_model.get_domain_pdb_code().center(10),\
                                              str(a_model_sim).center(12),\
                                              str(a_model.get_nres()).center(10),\
                                              a_model.get_multimer().center(11),\
                                              a_model.get_domain().center(9),\
                                              str(a_model.get_nmon()).center(19) )

                                    print "|-------|----------|------------|----------|-----------|---------|-------------------|"
                                    self._path_dict['process_log_content'] += \
                                          "|-------|----------|------------|----------|-----------|---------|-------------------|\n"

                                    CopyFile(a_model.mr_in_xyz,self._path_dict['ser_path'])
                     

            struct_xml_reader.releaseNode(struct_xml_document)
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""
     
    def getUserInputPdbCode(self, in_code):
        t_code = in_code
        aNumStr = ""
        if in_code :
           for aChar in in_code:
               if aChar.isdigit():
                   aNumStr = aNumStr + aChar
           if aNumStr:
               t_num = int(aNumStr)
           else :
               print "Could not decide the pdb code in user's lib"
               self._path_dict['process_log_content'] += "Could not decide the pdb code in user's lib\n"
               WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
               self._path_dict['process_log_content'] = ""
               sys.exit()
           if self._path_dict.has_key('infile_pdb_list'):
               if glob.glob(self._path_dict['infile_pdb_list']):
                   t_file = open(self._path_dict['infile_pdb_list'], "r")
                   lines =  t_file.readlines()
                   t_file.close()
                   if len(lines) >= t_num and t_num >= 1:
                       t_code = lines[t_num-1].split(".")[0]
                       if t_code:
                           t_code = t_code.upper()
        return t_code          
        
    def controller(self):

        if not self.idx_err and self._path_dict.has_key("infile_seq") :
            try:
                file_seq = open(self.seq_name,"r")
            except IOError:
                print  "can not find %s for reading " %self.seq_name
                self._path_dict['process_log_content'] += \
                       "can not find %s for reading " %self.seq_name
                self.idx_err = 1
            else :
               t_seq = "" 
               for aline in file_seq.readlines():
                   aline = aline.rstrip().lstrip()
                   if aline:
                       if aline[0] != ">":
                          t_seq = t_seq + aline
               print "number of amino acids in the input sequence file is %d " %len(t_seq)
               self._path_dict['process_log_content'] += \
                     "number of amino acids in the input sequence file is %d \n" %len(t_seq)
               if len(t_seq) < 20 :
                   print "It is a small fragment (<20) that current version of BALBES can not deal with"
                   self._path_dict['process_log_content'] += \
                        "It is a small fragment (<20) that current version of BALBES can not deal with"
                   self.idx_err = 1 
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
          
        # run seq_DB
        if self.mode != 1:
            if not self.idx_err:
                self.seqDB_run()
                #self.setCmdLineAndFile()
                # self.execute()
                if not self.idx_err:
                    self.seqDB_info_analysis()
        
        # run get_structure_DB
        if not self.idx_err:
            self.structDB_run()
            if not self.idx_err:
                self.structDB_info_analysis()

##################################################################
        
class CMOLREP (CExeCode):
    
    def __init__( self, path_obj ):

        CExeCode.__init__(self, path_obj)
        self.idx_err = 0
        self.__exeCode = os.path.join(self._path_dict["bin_path"], "molrep")

        self.mod_1 = None
        self.mod_2 = None 
        
        self.input_phase = "N"   #  repeatly with mod_2

   
        self.found  = 0
        
    def  setCmdLineAndFile (self) :

        # Generate a batch file (can be changed to cmdline once we do not want 
        # to have a look at the batch file
       
        self.bat_name =  os.path.join(self._path_dict["scr_path"], self.name_tag + ".bat" )
        try:
            molrep_bat = open(self.bat_name,"w")
        except IOError:
            print self.bat_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                    "%s could not be opened for writing \n" %self.bat_name
            self.idx_err = 1
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""
        else:
            print >> molrep_bat, "_DOC  Y>%s "% (self._path_dict["doc_path"] + "/")       
            if not self.mod_2: 
                print >> molrep_bat, "_FILE_F %s" % self.mod_1.mr_in_hkl
                if self.mod_1.ens_enable =="YES":
                    print >> molrep_bat, "_FILE_M %s" % self.mod_1.mr_in_xyz_ens
                else:
                    print >> molrep_bat, "_FILE_M %s" % self.mod_1.mr_in_xyz
                print >> molrep_bat, "_PATH_SCR %s" % (self._path_dict["scr_path"] +"/")
                if not (self.mod_1.infile_seq == "null"):
                    str_temp = os.path.join(self._path_dict["scr_path"],  
                         self._path_dict["name_root"]+ "_" + self.mod_1.get_index_chain()+".seq")
                    print >> molrep_bat, "_FILE_S ", str_temp
                #print >> molrep_bat, "_compl " , self.mod_1.get_mol_compl()
                if self.mod_1.ens_enable == "YES":
                    print >> molrep_bat, "_sim  ", self.mod_1.get_sim_ens()
                else:
                    print >> molrep_bat, "_sim  ", self.mod_1.get_similarity()
                print >> molrep_bat, "_rad  %5.2f " % self.mod_1.get_MOLREP_RAD()
                print >> molrep_bat, "_DB   Y    "
                print >> molrep_bat, "_NCSM %d   "  % self.mod_1.get_numCopies()
                if self.mod_1.get_nmon() <= 30:
                    print >> molrep_bat, "_nmon %d " % self.mod_1.get_nmon()

            else :
                # calculation with tge input fixed model 
                if glob.glob(self.mod_2.refi_sol_hkl):
                    print >> molrep_bat, "_FILE_F %s" % self.mod_2.refi_sol_hkl  
                else :
                    print >> molrep_bat, "_FILE_F %s" % self.mod_1.mr_in_hkl  
                if self.mod_1.ens_enable =="YES":
                    print >> molrep_bat, "_FILE_M %s" % self.mod_1.mr_in_xyz_ens
                else:
                    print >> molrep_bat, "_FILE_M %s" % self.mod_1.mr_in_xyz
                print >> molrep_bat, "_PATH_SCR %s" % (self._path_dict["scr_path"] + "/")
                if not (self.mod_1.infile_seq == "null"):
                    str_temp = os.path.join(self._path_dict["scr_path"], 
                           self._path_dict["name_root"] + "_" + self.mod_1.get_index_chain()+".seq") 
                    print >> molrep_bat, "_FILE_S ", str_temp
                # print >> molrep_bat, "_compl " , self.mod_1.get_mol_compl()
                if self.mod_1.get_domain().strip() =="Yes":
                    # the model is a domainmodel
                    print >> molrep_bat, "_badd 1"
                else:
                    if self.mod_1.ens_enable == "YES":
                        print >> molrep_bat, "_sim  ", self.mod_1.get_sim_ens()
                    else:
                        print >> molrep_bat, "_sim  ", self.mod_1.get_similarity()

                print >> molrep_bat, "_rad  %5.2f " % self.mod_1.get_MOLREP_RAD()
                print >> molrep_bat, "_DB   Y    "
                print >> molrep_bat, "_MODEL_2 %s" % self.mod_2.refi_sol_xyz
                if self.mod_1.use_phase == "Y":
                    print >> molrep_bat, "_LABIN F=FWT PH=PHWT"
                    print >> molrep_bat, "_diff  M" 
                print >> molrep_bat, "_nmon %d " % self.mod_1.get_nmon()
                print >> molrep_bat, "_np 40 "

            molrep_bat.close()

            # Set command line
            self._cmdline  = ''
            self._cmdline +=  ' %s  <%s ' %  (self.__exeCode, self.bat_name)
            # log file name

    def info_analysis(self):
        """Extract information from the XML file associated with
           the input moldel on which molrep has executed """
        # set the mr_score to the zero
        self.mod_1.set_mr_score(0.0)
                
        # Organise the file path and name
        if not glob.glob(self._path_dict["doc_path"] +"/molrep.xml"):
            print "no molrep.xml is found for the self.mod_1, molrep running time fault!"
            self._path_dict['process_log_content'] += \
                  "no molrep.xml is found for the self.mod_1, molrep running time fault!"
            self.idx_err = 1
        else:
            xml_name_pre = self._path_dict["doc_path"] + "/molrep.xml"
        
        # Open xml file
        if not self.idx_err:
            try:
                molrep_xml = open(xml_name_pre,"r")
            except IOError:
                print  xml_name_pre  , " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                       "%s could not be opened for reading " %xml_name_pre
                self.idx_err = 1

            # Handle with xml file
            try:
                molrep_xml_reader   = PyExpat.Reader()
                molrep_xml_document = molrep_xml_reader.fromStream(molrep_xml)
                molrep_xml.close()
            except ExpatError:
                print "can not create a reader object for xml file, xml format errors"
                self._path_dict['process_log_content'] += \
                      "can not create a reader object for xml file, xml format errors"
                self.idx_err =1

            if not self.idx_err:
                rootElement = StripXml(molrep_xml_document.documentElement)

                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.mod_1.set_err_level(int(node.firstChild.nodeValue))
                        if self.mod_1.get_err_level() > 1:
                            self.idx_err = 1
                    elif node.nodeName == "err_message":
                        self.mod_1.set_err_message(node.firstChild.nodeValue)
                        if self.idx_err == 1:
                            print "ERROR MESSAGE: ", self.mod_1.get_err_message()
                            self._path_dict['process_log_content'] += \
                                  "ERROR MESSAGE: %s\n", self.mod_1.get_err_message()
                    elif node.nodeName == "n_solution":
                        self.mod_1.set_nmon_solution(int(node.firstChild.nodeValue))
                        print "| Monomers expected |","%s"% str(self.mod_1.get_nmon()).center(15),"|"
                        print "|-------------------|-----------------|"
                        print "| Monomers found    |","%s"% str(self.mod_1.get_nmon_solution()).center(15),"|"
                        print "|-------------------|-----------------|"
                        self._path_dict['process_log_content'] += \
                              "| Monomers expected |%s|\n"% str(self.mod_1.get_nmon()).center(17)
                        self._path_dict['process_log_content'] += \
                              "|-------------------|-----------------|\n"
                        self._path_dict['process_log_content'] += \
                              "| Monomers found    |%s|\n"% str(self.mod_1.get_nmon_solution()).center(17)
                        self._path_dict['process_log_content'] += \
                              "|-------------------|-----------------|\n"
                    elif node.nodeName == "mr_score":
                        self.mod_1.set_mr_score(node.firstChild.nodeValue)
                        print "The MR score is %4.2f" % self.mod_1.get_mr_score()
                        self._path_dict['process_log_content'] += \
                              "The MR score is %4.2f \n" % self.mod_1.get_mr_score()
                    elif node.nodeName == "mr_score_previous":
                        self.mod_1.set_mr_score_prev(node.firstChild.nodeValue)
                    elif node.nodeName == "solution":
                        file_sol_pdb = node.getAttribute("sol_file")
                        if not glob.glob(file_sol_pdb):
                            print "MR failed to produce a solution on this model "
                            self._path_dict['process_log_content'] += \
                                  "MR failed to produce a solution on this model \n"
                            self.mod_1.mr_sol_xyz = ""
                        else:
                            self.mod_1.mr_sol_xyz = os.path.join(self._path_dict["tem_path"],
                                                              self.name_tag +".pdb")
                            shutil.move(file_sol_pdb, self.mod_1.mr_sol_xyz)
                    elif node.nodeName == "found":
                        file_sol_dimer = node.getAttribute("dimer_file")
                        if file_sol_dimer == "none" :
                            self.mod_1.file_sol_dimer = None
                        elif glob.glob(file_sol_dimer):
                            self.mod_1.file_sol_dimer = os.path.join(self._path_dict["tem_path"],
                                                   self.name_tag + "_dimer.pdb") 
                            shutil.move(file_sol_dimer, self.mod_1.file_sol_dimer)
                            if glob.glob(self.mod_1.file_sol_dimer):
                                print "A dimer solution has been found \n"
                                self._path_dict['process_log_content'] += \
                                      "A dimer solution has been found\n"
                            else :
                                print "where did I put the solution dimer file of this model"
                                self._path_dict['process_log_content'] += \
                                      "where did I put the solution dimer file of this model \n"
                                self.idx_err = 1
                        else :
                            print "molrep has found dimer, but failed to produce the dimer pdb! "
                            self._path_dict['process_log_content'] += \
                                  "molrep has found dimer, but failed to produce the dimer pdb! \n"
                            self.idx_err = 1

            molrep_xml_reader.releaseNode(molrep_xml_document)
            shutil.move(xml_name_pre, self.xml_name)

        print "Job finished at %s " % time.ctime( time.time() )
        self._path_dict['process_log_content'] += \
              "Job finished at %s \n" % time.ctime( time.time() )
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""

     #  The dimer file process   
    def dimer_exe(self, model):
        """ running 'molrep' on the input model using the found dimer pdb """
        
        print "Found dimer in the model, work on it "
        self._path_dict['process_log_content'] += \
              "Found dimer in the model, work on it "
        model.mr_in_xyz = model.file_sol_dimer
        print "The input pdb file for  is now ",  model.mr_in_xyz
        self._path_dict['process_log_content'] += \
              "The input pdb file for  is now %s \n"  %model.mr_in_xyz
        model.set_numCopies(2)
        print "The number of copies is now  %d " % model.get_numCopies()
        self._path_dict['process_log_content'] += \
              "The number of copies is now  %d \n" % model.get_numCopies()
        model.set_nmon(model.get_nmon()/2)
        print "The number of monomers is now %d " % model.get_nmon()
        self._path_dict['process_log_content'] += \
              "The number of monomers is now %d \n" % model.get_nmon()
        self.setCmdLineAndFile (moldel_t)
        self.execute()
        self.info_analysis(model)
        print "Job on dimer done \n"
        self._path_dict['process_log_content'] += \
              "Job on dimer done \n"
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
        
    def solution_check_one_model(self, t_model):
        """ run solution-check on one selected model """

        if glob.glob(t_model.solution_xyz):
            self.SolCheck.set_keypair("in_xyz", t_model.solution_xyz)
            self.SolCheck.controller()
            if self.SolCheck.err_level == 0:
                self.found = 1
                self.chain_expect = self.SolCheck.chain_exp
                if self.SolCheck.chain_found:
                    self.chain_found    = self.SolCheck.chain_found
                    self.found = 2
                    self.solved_model = t_model

    def controller(self, t_mod_1, t_mod_2 = None ):
     
        if not self.idx_err:
            print "\n#-------------------------------------#"
            print "# Molecular Replacement               #"
            print "#-------------------------------------#"
            self._path_dict['process_log_content'] += \
                  "\n#-------------------------------------#\n"
            self._path_dict['process_log_content'] += \
                  "# Molecular Replacement               #\n"
            self._path_dict['process_log_content'] += \
                  "#-------------------------------------#\n"

            self.mod_1 = t_mod_1
            if t_mod_2:
                self.mod_2 = t_mod_2
                self.mod_1.use_phase = "Y"
            else:
                self.mod_2 = None       # Play safely

            index_mod_n = self.mod_1.get_index()
            index_dom   = self.mod_1.get_index_domain()
            self.name_tag = "molrep_%s" % self.mod_1.name_tag

            if self.mod_2:
                index_mod_2  = self.mod_2.get_index()
                index_dom    = self.mod_2.get_index_domain()
            #    if self.mod_2.asm :
            #        name2_tag = "assem%s_model%s_dom%s" \
            #                    %(str(index_mod_2[0]), str(index_mod_2[1]),str(index_dom))
            #    else:
            #        name2_tag = "seq%s_struct%s_model%s_dom%s" \
            #                  %(str(index_mod_2[0]), str(index_mod_2[1]), str(index_mod_2[2]), str(index_dom))
            #    self.name_tag = self.name_tag + "fixed_" + name2_tag

            # log file name
            self.log_name = os.path.join(self._path_dict["doc_path"], self.name_tag + ".log")
            self.mod_1.mr_log = self.log_name

            # xml file name
            self.xml_name = os.path.join(self._path_dict["xml_path"], self.name_tag + ".xml")

            print "Job started at %s " % time.ctime( time.time() )
            self._path_dict['process_log_content'] += \
                  "Job started at %s \n" % time.ctime( time.time() )
            print "|-------------------------------------|"
            self._path_dict['process_log_content'] += \
                 "|-------------------|-----------------|\n"
            if self.mod_1.mix =="N" :
                if self.mod_1.asm :
                    print "| Assembly          |","%s"% str(index_mod_n[0]).center(15),"|"
                    print "|-------------------|-----------------|"
                    print "| Structure         |","%s"% self.mod_1.get_pdb_code().center(15),"|"
                    print "|-------------------------------------|"
                    print "| Model             |","%s" %str(index_mod_n[1]).center(15),"|"
                    print "|-------------------|-----------------|"
                    self._path_dict['process_log_content'] += \
                        "| Assembly          |%s|\n"% str(index_mod_n[0]).center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------|-----------------|\n"
                    self._path_dict['process_log_content'] += \
                        "| Structure         |%s|\n"% self.mod_1.get_pdb_code().center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------|-----------------|\n"
                    self._path_dict['process_log_content'] += \
                        "| Model             |%s|\n" %str(index_mod_n[1]).center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------|-----------------|\n"
                else:
                    t_code = str(index_mod_n[1]) + "," + self.mod_1.get_pdb_code()
                    print "| Sequence          |","%s"% str(index_mod_n[0]).center(15),"|"
                    print "|-------------------------------------|"
                    print "| Structure         |","%s"% t_code.center(15),"|"
                    print "|-------------------|-----------------|"
                    print "| Model             |","%s" %str(index_mod_n[2]).center(15),"|"
                    print "|-------------------|-----------------|"
                    self._path_dict['process_log_content'] += \
                        "| Sequence          |%s|\n"% str(index_mod_n[0]).center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------------------------|\n"
                    self._path_dict['process_log_content'] += \
                        "| Structure         |%s|\n"% t_code.center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------|-----------------|\n"
                    self._path_dict['process_log_content'] += \
                        "| Model             |%s|\n" %str(index_mod_n[2]).center(17)
                    self._path_dict['process_log_content'] += \
                        "|-------------------|-----------------|\n"
            else: 
                 print "Current model index : %s"%self.mod_1.name_tag.ljust(40)
                 self._path_dict['process_log_content'] += \
                       "Current model index : %s\n"%self.mod_1.name_tag.ljust(40)   
             
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""
        
            if self.mod_1.get_nmon() >= 30:
                t = 30
                self.mod_1.set_nmon(t) 
            self.setCmdLineAndFile()
                #print "The number of monomers expected in this model is larger than 30"
                #print "BALBES will not solve this model"
                #self._path_dict['process_log_content'] += \
                #    "The number of monomers expected in this model is larger than 30 \n"
                #self._path_dict['process_log_content'] += \
                #     "BALBES will not solve this model\n"
                #WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                #self._path_dict['process_log_content'] = ""
                #self.idx_err = 1

            if not self.idx_err:
                self.execute()

                if not self.idx_err:
                    self.info_analysis()

            t_mod_1 = self.mod_1

        
##################################################################
        
class Refinement :
    """ A class that manages molecule replacement by selectively runing
        different programs such as refmac (current default) and other codes
        (future) according to their feedback"""
    
    def __init__( self, path_obj = None ):
        
        # set the default code to be refmac and other codes to be plugged in if
        # the former fails
        self.__code_dict= {}
        self.setExeCode("refmac")
        
        # create a object of the refmac class
        self.Refmac = CREFMAC(path_obj)
        
    def setExeCode(self, name = None):
        if name:
            self.__code_dict["exeCode"] = name
        else :
            # temporarily
            print "  which code you want to run ? "
            sys.exit(1)

    def execute(self) :
        # If refmac key is not disabled, run it first
        if self.__code_dict["exeCode"]== "refmac" :
            self.Refmac.controller()
            # check if the program produce lower R factor

class CREFMAC (CExeCode):
    """ Class that carries out refinement by running 'refmac'.
    The class is a descendent of the base classs 'CExeCode' """
    
    def __init__( self, path_obj):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        self.__exeCode = os.path.join(self._path_dict["bin_path"],"refmac5")

        self.xml_name = "" 
        self.log_name = ""  
        self.scr_name = ""  

        # default keywords, some will be decided on-fly such as LABIn....

        self.NCYCLE = 40   # default  value

        self.keywords = {}
        self.keywords['rb']      = ["mode rigid", "rigid ncyc %d "%self.NCYCLE,
                                    "MAKE NEWLIGAND CONTINUE"]
        self.keywords['ocp']     = ["refi type occup", "MAKE HYDR N", 
                                    "MAKE NEWLIGAND CONTINUE", 
                                    "BFAC SET 20", "NCYCLE %d"%self.NCYCLE]
        self.keywords['default'] = ["MAKE HYDR NO",
                                    "MAKE NEWLIGAND CONTINUE", "WEIGHT AUTO ",
                                    "NCSR LOCAL",
                                    "RIDGE DIST SIGMA 0.05",
                                    "NCYCLE %d"%self.NCYCLE] 

        self.keywords['direct']  = ["MAKE HYDR NO",
                                    "MAKE NEWLIGAND CONTINUE", "WEIGHT AUTO ",
                                    "TWIN RMER 1.0",
                                    "TWIN TRANSFORM DATA",
                                    "NCYCLE %d"%self.NCYCLE]                                  
                                 

        self.FP    = ""
        self.SIGFP = ""
        self.FREE  = ""

        self.output_dict = {}
        self.output_dict['err_level'] = 0
        self.idx_err = 0

        self.found = 0

        self.OneChainPDB = os.path.join(self._path_dict["scr_path"], 
                           self._path_dict["name_root"] + "_OneChain.pdb")

        # temp using internal ligand dic for refmac
        # os.putenv("LIB_BALBES", self._path_dict["lig_path"])

    def Para_mtzdump(self, t_model = None):
        """ Deduce parametes for Refmac from the relavent mtz file """

        self.mtzdump_bat_name  = os.path.join(self._path_dict["scr_path"], 
                                    "mtzdump_" + self._path_dict["name_root"] + ".bat")
        try:
            mtzdump_bat = open(self.mtzdump_bat_name, "w")
        except IOError:
            print self.mtzdump_bat_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                "%s could not be opened for write\n" %self.mtzdump_bat_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else :
            print >> mtzdump_bat, "RUN "
            mtzdump_bat.close()

            self.mtzdump_log_name = os.path.join(self._path_dict["doc_path"], 
                                    "mtzdump_" + self._path_dict["name_root"]  + ".log")

            if t_model:
                mtzdump_cmdline = "mtzdump HKLin " +  t_model.refi_in_hkl  \
                                + " <"  + self.mtzdump_bat_name + " >  " + self.mtzdump_log_name

            else :  
                mtzdump_cmdline = "mtzdump HKLin " +  self._path_dict['infile_mtz']  \
                              + " <"  + self.mtzdump_bat_name + " >  " + self.mtzdump_log_name
            os.system(mtzdump_cmdline)

    def  Para_freerflag(self, t_model):
        """ append free_R flag in the input mtz file """

        self.freerflag_bat_name  = os.path.join(self._path_dict["scr_path"], 
                                  "freerflag_" + self._path_dict["name_root"] + ".bat")
        try:
            freerflag_bat = open(self.freerflag_bat_name, "w")
        except IOError:
            print self.freerflag_bat_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                "%s could not be opened for write\n" %self.freerflag_bat_name
            self.idx_err = 1
        else :
            print >> freerflag_bat, "FREERFRAC 0.05" # use the default one temperarily
            print >> freerflag_bat, "END "
            freerflag_bat.close()

            self.freerflag_log = os.path.join(self._path_dict["doc_path"],   
                                 "freerflag_" + self._path_dict["name_root"]  + ".log")
            self.freerflag_mtz = os.path.join(self._path_dict["doc_path"] ,
                                     "freerflag_" + self._path_dict["name_root"] + ".mtz")
            if t_model:
                freerflag_cmdline = "freerflag hklin  " +  t_model.refi_in_hkl  \
                                  + "  hklout " + self.freerflag_mtz + " <" \
                                  + self.freerflag_bat_name + " >" + self.freerflag_log
            else :
                freerflag_cmdline = "freerflag hklin  " +  self._path_dict['infile_mtz']  \
                                + "  hklout " + self.freerflag_mtz + " <" \
                                + self.freerflag_bat_name + " >" + self.freerflag_log

            os.system(freerflag_cmdline)
            if glob.glob(self.freerflag_mtz):
                t_model.refi_in_hkl = self.freerflag_mtz
            else:
                print "Problem in appending freeR_flag to the mtz file ?"
                self._path_dict['process_log_content'] += \
                      "Problem in appending freeR_flag to the mtz file ?\n"
                self.idx_err = 1

            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""

    def setCmdLineAndFile (self, t_model, t_mode = None) :


        # Deduce parameters from *.mtz file

        self.Para_mtzdump(t_model)

        try:
            mtzdump_log = open(self.mtzdump_log_name, "r")
        except IOError :
            print self.mtzdump_log_name, " could not be opened for reading"
            self._path_dict['process_log_content'] += \
                  "%s could not be opened for reading \n" % self.mtzdump_log_name
            self.idx_err = 1
        else :
            i_end = 0
            FP_done = 0 
            while 1:
                line_mtz1 = mtzdump_log.readline()
                if line_mtz1.find("order") != -1:
                    while 1:
                        line_mtz2 = mtzdump_log.readline()
                        strs_line_mtz2 = line_mtz2.split()
                        if len(strs_line_mtz2) == 12:
                            if strs_line_mtz2[10] == "F" and not FP_done:
                                line_mtz3 = mtzdump_log.readline()
                                strs_line_mtz3 = line_mtz3.split()
                                if strs_line_mtz3[-2] == "Q":
                                        self.SIGFP = strs_line_mtz3[-1]
                                        self.FP = strs_line_mtz2[-1]
                                        FP_done = 1
                            elif strs_line_mtz2[11] == "FreeR_flag":
                                self.FREE = strs_line_mtz2[11]
                        elif len(strs_line_mtz2) == 11:
                            if strs_line_mtz2[9] == "F" and not FP_done:
                                self.FP = strs_line_mtz2[10]
                                line_mtz3 = mtzdump_log.readline()
                                strs_line_mtz3 = line_mtz3.split()
                                if len(strs_line_mtz3) == 12:
                                    if strs_line_mtz3[10] == "Q":
                                        self.SIGFP = strs_line_mtz3[11]
                                elif len(strs_line_mtz3) == 11:
                                    if strs_line_mtz3[9] == "Q":
                                        self.SIGFP = strs_line_mtz3[10]
                            elif strs_line_mtz2[10] == "FreeR_flag":
                                self.FREE = strs_line_mtz2[10]
                        elif line_mtz2.find("No. of reflections used in FILE STATISTICS") != -1:
                            i_end = 1
                            break
                if i_end == 1:
                    break

            # Check if FreeR_flag is activated
            if not self.FREE:
                self.FREE = "FreeR_flag"
                self.Para_freerflag(t_model)
            if not self.FP or not self.SIGFP:
                print "can not find FP or SIGFP parameter after running mtzdump"
                self._path_dict['process_log_content'] += \
                      "can not find FP or SIGFP parameter after running mtzdump\n"
                self.idx_err = 1

        if not self.bat_name :
            print "no batch file 'refmac', why "
            self.idx_err = 1 
        if not self.idx_err:
            tmp_cmdline = ''
            tmp_cmdline += ' HKLIN %s '  % t_model.refi_in_hkl
            tmp_cmdline += ' XYZIN %s '  % t_model.refi_in_xyz
            tmp_cmdline += ' XYZOUT %s ' % t_model.refi_sol_xyz
            tmp_cmdline += ' HKLOUT %s ' % t_model.refi_sol_hkl
            tmp_cmdline += ' XMLOUT %s ' % self.xml_name
            tmp_cmdline += ' scrref %s ' % self.scr_name
             
            try:
                refmac_bat = open(self.bat_name,"w")
            except IOError:
                print "%s could not be opened for write"%self.bat_name
                self._path_dict['process_log_content'] += \
                      "%s could not be opened for write" %self.bat_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                sys.exit(1)

            if self.mode == "Rigid Body Refinement" :
                a_newline = "LABIn FP=" + self.FP + " SIGFP=" + self.SIGFP +" FREE=FreeR_flag"
                print >> refmac_bat, a_newline
                for item in self.keywords['rb'] : 
                    print >> refmac_bat, item
            elif self.mode == "Occupancy Refinement" :
                for item in self.keywords['ocp'] : 
                    print >> refmac_bat, item
            elif self.mode == "Direct Refinement" :
                a_newline = "LABIn FP=" + self.FP + " SIGFP=" + self.SIGFP +" FREE=FreeR_flag"
                print >> refmac_bat, a_newline
                for item in self.keywords['direct'] : 
                    print >> refmac_bat, item
            else :
                # Use default keywords 
                a_newline = "LABIn FP=" + self.FP + " SIGFP=" + self.SIGFP +" FREE=FreeR_flag"
                print >> refmac_bat, a_newline
                for item in self.keywords['default'] : 
                    print >> refmac_bat, item

            refmac_bat.close()    
            
            self._cmdline = ' %s %s <%s' %(self.__exeCode, tmp_cmdline, self.bat_name )

    def info_analysis(self, t_model):

        """Extract information from the XML file generated by 'refmac' """
        # Organise the file path and name
        if not glob.glob(self.xml_name):
            print "BUG, No xml is generated by refinement"
            self._path_dict['process_log_content'] += \
                  "BUG, No xml is generated by refinement"
            self.idx_err = 1
            sys.exit(1)
        else:
            # Open xml file
            try:
                refmac_xml = open(self.xml_name,"r")
            except IOError:
                print  self.xml_name, " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                       "%s could not be opened for reading \n"%self.xml_name
                self.idx_err = 1

            # Handle with xml file
            try:
                refmac_xml_reader   = PyExpat.Reader()
                refmac_xml_document = refmac_xml_reader.fromStream(refmac_xml)
                refmac_xml.close()
            except ExpatError:
                print "can not create a reader object for xml file, xml format fault"
                self._path_dict['process_log_content'] += \
                      "can not create a reader object for xml file, xml format fault \n"
                sys.exit(1)
                self.idx_err = 1
                

            rootElement = StripXml(refmac_xml_document.documentElement)

            for node in rootElement.childNodes:
                if node.nodeName == "err_level":
                    self.output_dict['err_level'] = int(node.firstChild.nodeValue.strip())
                    if self.output_dict['err_level']:
                        print "Refinement errors. check xml file. The calculation stoped "
                        sys.exit(1)
                elif node.nodeName == "err_message":
                    self.output_dict['err_message'] = node.firstChild.nodeValue
                    if self.output_dict['err_message'].find("reindex") != -1:
                        self.output_dict['reindex'] = True
                        print "|         Twin data: need to reindex           |"
                        print "|         Refinement stopped                   |"
                        print "|----------------------------------------------|"
                        self._path_dict['process_log_content'] += \
                               "|         Twin data: need to reindex           |\n"
                        self._path_dict['process_log_content'] += \
                               "|         Refinement stopped                   |\n"
                        self._path_dict['process_log_content'] += \
                               "|----------------------------------------------|\n"
                elif node.nodeName == "job":
                    self.output_dict['job_type'] = node.firstChild.nodeValue
                elif node.nodeName == "Overall_stats" and not self.output_dict['reindex']:
                    self.output_dict['all_cyc'] = {}
                    for overall in node.childNodes:
                        if overall.nodeName == "n_cycle":
                            self.output_dict['all_cyc']['num_cyc'] = int(overall.firstChild.nodeValue) 
                            t_cyc = self.output_dict['all_cyc']['num_cyc'] 
                            print "| Number of cycle used |","%s"\
                                   % str(t_cyc).center(21),"|"
                            print "|----------------------|-----------------------|"
                            self._path_dict['process_log_content'] += \
                                "| Number of cycle used |%s|\n"\
                                % str(t_cyc).center(23)
                            self._path_dict['process_log_content'] += \
                                "|----------------------|-----------------------|\n"
                             
                        elif overall.nodeName == "stats_vs_cycle":
                             self.output_dict['all_cyc']["cycs"] = []
                             for s_vs_c in overall.childNodes:
                                 if s_vs_c.nodeName == "new_cycle":
                                     a_cyc = RefCycle()
                                     for cyc in s_vs_c.childNodes:
                                         if cyc.nodeName == "cycle":
                                             a_cyc.cyc_id = int(cyc.firstChild.nodeValue)  
                                         elif cyc.nodeName == "r_factor":
                                             a_cyc.r_fact = float(cyc.firstChild.nodeValue)
                                         elif cyc.nodeName == "r_free":
                                             a_cyc.r_free = float(cyc.firstChild.nodeValue)
                                         elif cyc.nodeName == "rmsBOND":
                                             a_cyc.rmsBOND = float(cyc.firstChild.nodeValue)
                                         elif cyc.nodeName == "rmsANGLE":
                                             a_cyc.rmsANGLE = float(cyc.firstChild.nodeValue)
                                         elif cyc.nodeName == "rmsCHIRAL":
                                             a_cyc.rmsCHIRAL = float(cyc.firstChild.nodeValue)

                                 self.output_dict['all_cyc']["cycs"].append(a_cyc)
                             # check
                             if self.output_dict['all_cyc']['num_cyc'] != len(self.output_dict['all_cyc']["cycs"]):
                                 print "number of cycles in refmac xml file is not right "
                                 sys.exit()
                             elif len(self.output_dict['all_cyc']["cycs"]) != 0 :
                                 t_model.R_ini = \
                                            self.output_dict['all_cyc']["cycs"][0].r_fact
                                 t_model.R_free_ini = \
                                            self.output_dict['all_cyc']["cycs"][0].r_free
                                 t_cyc = self.output_dict['all_cyc']['num_cyc'] - 1
                                 t_model.R_fin = \
                                            self.output_dict['all_cyc']["cycs"][t_cyc].r_fact
                                 t_model.R_free_fin = \
                                            self.output_dict['all_cyc']["cycs"][t_cyc].r_free
                                 if t_model.R_ini and t_model.R_free_ini : 
                                     print "| R_ini/R_free_ini     |","%10.4f/%-10.4f" \
                                          %(t_model.R_ini, t_model.R_free_ini ),"|"
                                     print "|----------------------|-----------------------|"
                                     self._path_dict['process_log_content'] += \
                                          "| R_ini/R_free_ini     |%10.4f/%-10.4f  |\n" \
                                          %(t_model.R_ini, t_model.R_free_ini )
                                     self._path_dict['process_log_content'] += \
                                          "|----------------------|-----------------------|\n"
                                 if t_model.R_fin and t_model.R_free_fin  :                   
                                     print "| R/R_free             |","%10.4f/%-10.4f" \
                                          %(t_model.R_fin, t_model.R_free_fin),"|"
                                     print "|----------------------|-----------------------|"
                                     self._path_dict['process_log_content'] += \
                                          "| R/R_free             |%10.4f/%-10.4f  |\n" \
                                          %(t_model.R_fin, t_model.R_free_fin)
                                     self._path_dict['process_log_content'] += \
                                          "|----------------------|-----------------------|\n"
                             
                        elif overall.nodeName == "bvalue_stats":
                             self.output_dict['BFactores'] =  CBOStrucDict()
                             for bs in overall.childNodes:
                                 if bs.nodeName == "overall":
                                    for bs_prop in bs.childNodes:
                                        if bs_prop.nodeName == "all":
                                            self.output_dict['BFactores']['overall']['all'].SetBOStruc(bs_prop)
                                        if bs_prop.nodeName == "main_chain":
                                            self.output_dict['BFactores']['overall']['main'].SetBOStruc(bs_prop)
                                        if bs_prop.nodeName == "side_chain":
                                            self.output_dict['BFactores']['overall']['side'].SetBOStruc(bs_prop)
                                 elif bs.nodeName == "chain_by_chain":
                                    for bs_prop in bs.childNodes:
                                        if bs_prop.nodeName == "new_chain":
                                            a_chain = Chain()
                                            for c_prop in bs_prop.childNodes:
                                                if c_prop.nodeName == "chain_name":
                                                    a_chain.set_chainID(c_prop.firstChild.nodeValue)
                                                elif c_prop.nodeName == "all":
                                                    a_chain.b_all.SetBOStruc(c_prop)
                                                elif c_prop.nodeName == "main_chain":
                                                    a_chain.b_main.SetBOStruc(c_prop)
                                                elif c_prop.nodeName == "side_chain":
                                                    a_chain.b_side.SetBOStruc(c_prop)
                                            self.output_dict['BFactores']['chains'].append(a_chain)
                                    # print out
                                    #for t_chain in self.output_dict['BFactores']['chains']:
                                    #    print "Chain name:  ", t_chain.get_chainID()
                                    #    print "Chain overall B factors "
                                    #    print "\tB overall all number", t_chain.b_all.number 
                                    #    print "\tB overall all average",t_chain.b_all.average 
                                    #    print "\tB overall all sigma", t_chain.b_all.sigma 
                                    #    print "Main chain B factors "
                                    #    print "\tB main chain number", t_chain.b_main.number 
                                    #    print "\tB main chain average",t_chain.b_main.average 
                                    #    print "\tB main chain sigma", t_chain.b_main.sigma 
                                    #    print "Side chain B factors "
                                    #    print "\tB side chain number", t_chain.b_side.number 
                                    #    print "\tB side chain average",t_chain.b_side.average 
                                    #    print "\tB side chain sigma", t_chain.b_side.sigma 
                        elif overall.nodeName == "occupancy_stats":
                             self.output_dict['Occupancy'] =  CBOStrucDict()
                             for oc in overall.childNodes:
                                 if oc.nodeName == "overall":
                                    for oc_prop in oc.childNodes:
                                        if oc_prop.nodeName == "all":
                                            self.output_dict['Occupancy']['overall']['all'].SetBOStruc(oc_prop)
                                        elif oc_prop.nodeName == "main_chain":
                                            self.output_dict['Occupancy']['overall']['main'].SetBOStruc(oc_prop)
                                        elif oc_prop.nodeName == "side_chain":
                                            self.output_dict['Occupancy']['overall']['side'].SetBOStruc(oc_prop)
                                    #print "Occup main number= %d "%self.output_dict['Occupancy']['overall']['main'].number
                                    #print "Occup main average= %6.3f "%self.output_dict['Occupancy']['overall']['main'].average
                                    #print "Occup main sigma= %6.3f "%self.output_dict['Occupancy']['overall']['main'].sigma
                                 elif oc.nodeName == "chain_by_chain":
                                    for oc_prop in oc.childNodes:
                                        if oc_prop.nodeName == "new_chain":
                                            a_chain = Chain()
                                            for c_prop in oc_prop.childNodes:
                                                if c_prop.nodeName == "chain_name":
                                                    a_chain.set_chainID(c_prop.firstChild.nodeValue)
                                                elif c_prop.nodeName == "all":
                                                    a_chain.o_all.SetBOStruc(c_prop)
                                                elif c_prop.nodeName == "main_chain":
                                                    a_chain.o_main.SetBOStruc(c_prop)
                                                elif c_prop.nodeName == "side_chain":
                                                    a_chain.o_side.SetBOStruc(c_prop)
                                            self.output_dict['Occupancy']['chains'].append(a_chain)
                                    # print out
                                    #for t_chain in self.output_dict['Occupancy']['chains']:
                                    #    print "Chain name:  ", t_chain.get_chainID()
                                    #    print "Chain overall Occupancy "
                                    #    print "\tO overall all number", t_chain.o_all.number 
                                    #    print "\tO overall all average",t_chain.o_all.average 
                                    #    print "\tO overall all sigma", t_chain.o_all.sigma 
                                    #    print "Chain main chain Occupancy "
                                    #    print "\tO main chain number", t_chain.o_main.number 
                                    #    print "\tO main chain average",t_chain.o_main.average 
                                    #    print "\tO main chain sigma", t_chain.o_main.sigma 
                                    #    print "Chain side chain Occupancy "
                                    #    print "\tO side chain number", t_chain.o_side.number 
                                    #    print "\tO side chain average",t_chain.o_side.average 
                                    #    print "\tO side chain sigma", t_chain.o_side.sigma 
 
                elif node.nodeName == "solution_file":
                    file_sol_xyz = node.firstChild.nodeValue
                    file_sol_xyz = file_sol_xyz.rstrip()
                    file_sol_xyz = file_sol_xyz.lstrip()
                    #if not glob.glob(file_sol_xyz):
                    #    print " No output pdb file is produced by refinement"
                    #    self._path_dict['process_log_content'] += \
                    #          " No output pdb file is produced by refinement\n"
                    #else:
                    #    print "The solution pdb file is in: \n%s " \
                    #          % file_sol_xyz
                    #    self._path_dict['process_log_content'] += \
                    #          "The solution pdb file is in: \n%s\n " % file_sol_xyz
                elif node.nodeName == "mtz_file":
                    file_sol_mtz = node.firstChild.nodeValue
                    file_sol_mtz = file_sol_mtz.rstrip()
                    file_sol_mtz = file_sol_mtz.lstrip()
                    #if not glob.glob(file_sol_mtz):
                    #    print " No output structural factor file is produce by refinement"
                    #    self._path_dict['process_log_content'] += \\
                    #          " No output structural factor file is produce by refinement\n"
                    #else:
                    #    print "The solution mtz file is in: \n%s " % file_sol_mtz
                    #    self._path_dict['process_log_content'] += \
                    #          "The solution mtz file is in: \n%s\n " % file_sol_mtz                     
                elif node.nodeName == "twin_info":  
                    for a_twProp in node.childNodes:
                        if a_twProp.nodeName == "ntwin_domain":
                            t_model.twinInfo.numDomains = int(a_twProp.firstChild.nodeValue)
                        elif a_twProp.nodeName == "new_domain":
                            t_newDomain = TwinDomain()
                            for a_domain in a_twProp.childNodes:
                                if a_domain.nodeName == "domain":
                                    t_newDomain.idx = int(a_domain.firstChild.nodeValue)
                                elif a_domain.nodeName == "operator":
                                    t_newDomain.operator = a_domain.firstChild.nodeValue.strip()
                                elif a_domain.nodeName == "fraction":
                                    t_newDomain.fraction = float(a_domain.firstChild.nodeValue.strip())
                            t_model.twinInfo.newDomains.append(t_newDomain)
                        elif a_twProp.nodeName == "reindex":
                            for a_reindexOP in a_twProp.childNodes:
                                if a_reindexOP.nodeName == "action":
                                    if a_reindexOP.firstChild.nodeValue.strip() != "none":
                                        t_model.twinInfo.reindexAction = True
                                    else :
                                        t_model.twinInfo.reindexAction = False

                                elif a_reindexOP.nodeName == "operator":
                                    t_model.twinInfo.reindexOperator = a_reindexOP.firstChild.nodeValue.strip()
  
            
                    self.output_dict['reindex'] = node.firstChild.nodeValue

            refmac_xml_reader.releaseNode(refmac_xml_document)

        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""

    def controller(self,t_model, t_mode = None):

        self.FP    = ""
        self.SIGFP = ""
        self.FREE  = ""
      
        self.output_dict['err_level'] = 0
        self.output_dict['reindex']   = False
        self.idx_err = 0
        print "\n#----------------------------------------------#"
        print "# Refinement                                   #"
        print "#----------------------------------------------#"
      
        self._path_dict['process_log_content'] += \
              "\n#----------------------------------------------#\n"
        self._path_dict['process_log_content'] += \
              "# Refinement                                   #\n"
        self._path_dict['process_log_content'] += \
              "#----------------------------------------------#\n"
        print "Refinement started at  %s " % time.ctime( time.time() )
        self._path_dict['process_log_content'] += \
              "Refinement started at  %s \n" % time.ctime( time.time() )

        t_s = ""
        if t_mode :
            if t_mode == "Rigid" :
                self.mode = "Rigid Body Refinement"
                t_s = "r"
            elif t_mode == "Ocp" :
                self.mode = "Occupancy Refinement" 
                t_s = "o"
            elif t_mode == "Direct" :
                self.mode = "Direct Refinement" 
                t_s = "n"
            else :
                self.mode = "Normal Refinement"
                t_s = "n"
        else :
            self.mode = "Normal Refinement"
            t_s = "n"

        # Set name tag        
        index_mod_n   = t_model.get_index()
        index_dom     = t_model.get_index_domain()
        mod_tag   =  "refmac_%s" %t_model.name_tag
        if t_mode == "Rigid" :
            mod_tag += "_r"
        else:
            mod_tag += "_n"

        name_tag1     = os.path.join(self._path_dict["tem_path"], mod_tag)
        name_tag2     = os.path.join(self._path_dict["doc_path"], mod_tag) 
        name_tag3     = os.path.join(self._path_dict["scr_path"], mod_tag)
        name_tag4     = os.path.join(self._path_dict["xml_path"], mod_tag)

        self.xml_name = name_tag4 + ".xml"
        self.log_name = name_tag2 + ".log" 
        if t_mode == "Rigid" :
            t_model.refi_rigid_log = self.log_name
        else:
            t_model.refi_log = self.log_name
        self.scr_name = name_tag3 + ".tmp"
        self.bat_name = name_tag3 + ".bat"
        t_model.refi_sol_xyz = name_tag1 + ".pdb"
        t_model.refi_sol_hkl = name_tag1 + ".mtz"


        print "|----------------------------------------------|"
        print "| Mode                 |","%s"% self.mode.center(21),"|"
        print "|----------------------|-----------------------|"

        self._path_dict['process_log_content'] += \
              "|----------------------------------------------|\n"
        self._path_dict['process_log_content'] += \
              "| Mode                 |%s|\n"% self.mode.center(23)
        self._path_dict['process_log_content'] += \
              "|----------------------|-----------------------|\n"

        self.setCmdLineAndFile(t_model)
       
        self.execute()

        if not self.idx_err:
            self.info_analysis(t_model)
        

        print "Refinement finished at %s " % time.ctime( time.time() )
        self._path_dict['process_log_content'] += \
              "Refinement finished at %s \n" % time.ctime( time.time() )
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""


###########################################################################################

class CF2CIF (CExeCode):
    """ This class transfers a file of sfcheck_fob to that of cif format by running 'f2cif'.
    The class is inheritted from the base classs 'CExeCode' """
    
    def __init__( self, path_obj ):
        """Set the pathes where we can find exe codes, input and output data"""
        CExeCode.__init__(self, path_obj)
        self.__exeCode = os.path.join(self._path_dict["bin_path"], "f2cif")
    
        # set the command lines and file for the code 'f2cif'
        
        # input, output, log and bat file names

        if self._path_dict.has_key("infile_fobs"):
            self.fob_name = self._path_dict["infile_fobs"]
        else :
            self.fob_name = None
            print " No input sf file for 'f2cif'" 
            self._path_dict['process_log_content'] += \
               " No input file for 'f2cif' \n" 
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit()

        self.cif_name   = os.path.join(self._path_dict['scr_path'], self._path_dict['name_root'] + ".cif")
        self.log_name   = os.path.join(self._path_dict["doc_path"], "f2cif.log")
        self.batch_name = os.path.join(self._path_dict["scr_path"], "f2cif.bat") 
     
        try:
            f2cif_bat = open(self.batch_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                  "%s could not be opened for write\n" %self.batch_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit(1)

        print >> f2cif_bat, "_DOC  N "      
        print >> f2cif_bat, "_FILE_F %s" % self.fob_name 
        print >> f2cif_bat, "_FILE_O %s" % self.cif_name
        print >> f2cif_bat, "_FREE I "
        print >> f2cif_bat, "_end"
        f2cif_bat.close()

        self._cmdline  = ''
        self._cmdline +=  ' %s  <%s > %s' %(self.__exeCode, self.batch_name, self.log_name)
        os.system(self._cmdline)
        # self.execute()
        if not glob.glob(self.cif_name):
            print " 'f2cif' has not generate %s " % self.cif_name
            self._path_dict['process_log_content'] += \
               " 'f2cif' has not generate %s \n" % self.cif_name 
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit()

###########################################################################################

class CCIF2MTZ (CExeCode):
    """ This class transfers a file of cif format to that of mtz by running 'cif2mtz'.
    The class is inheritted from the base classs 'CExeCode' """
    
    def __init__( self, path_obj ):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        self.__exeCode = os.path.join(self._path_dict["ccp4"],"cif2mtz")
               
        self.cif_name  = os.path.join(self._path_dict['scr_path'], self._path_dict['name_root'] + ".cif")
        self.mtz_name  = os.path.join(self._path_dict['scr_path'], self._path_dict['name_root'] + ".mtz")
        self.log_name =  os.path.join(self._path_dict['doc_path'], "cif2mtz.log")
        
        # set the command lines for the code 'cif2mtz'

        tmp_cmdline = ''
        tmp_cmdline += ' HKLIN %s ' % self.cif_name
        tmp_cmdline += ' HKLOUT %s ' % self.mtz_name

        self.batch_name = os.path.join(self._path_dict['scr_path'], "cif2mtz.bat")
        try:
            cif2mtz_bat = open(self.batch_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                 "%s could not be opened for write \n" %self.batch_name
            sys.exit(1)

        print >> cif2mtz_bat, "_end "    

        #!!!!!!!!!!!!!!!!!!! CHECK HERE
        self._cmdline  = ''
        self._cmdline +=  ' %s  %s < %s \n' %  (self.__exeCode, tmp_cmdline, self.batch_name)
        
        self.execute()

        if not glob.glob(self.mtz_name):
            print " 'cif2mtz' did not generate %s " % self.mtz_name
            self._path_dict['process_log_content'] += \
                 " 'cif2mtz' did not generate %s \n" % self.mtz_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit(1)


###############################################################
class CGETMTZ:

    """ This class generates *.mtz file by runing 'sfcheck', 'f2cif', and 'cif2mtz' """

    def __init__( self, path_obj):
        """Set the pathes where we can find exe codes, input and output data"""

        # set pathes
        if path_obj :
            self._path_dict = path_obj
        else :
            # temporarily
            print "  Error in set path variables ! "
            sys.exit(1)
        
        self.cif_name = os.path.join(self._path_dict["scr_path"], self._path_dict["name_root"]+ ".cif")
        self.mtz_name = os.path.join(self._path_dict["scr_path"], self._path_dict["name_root"]+ ".mtz")

        if not self._path_dict.has_key("infile_fobs"):
            self.fob_generator = CSFCHECK(path_obj)
            self.fob_generator.controller(0)
            self._path_dict["infile_fobs"] = self.fob_generator.fobs_name
            if not glob.glob(self._path_dict["infile_fobs"]):
                print "sfcheck  can not generate sfcheck_fob.dat, why?"
                self._path_dict['process_log_content'] += \
                      "sfcheck  can not generate sfcheck_fob.dat, why?\n"
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                sys.exit(1)
        #else :
        self.cif_generator = CF2CIF(path_obj)
        if not glob.glob(self.cif_name):
            print "f2cif does not produce the *.cif file! "
            self._path_dict['process_log_content'] += \
                  "f2cif does not produce the *.cif file! \n"
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit(1)
        else:
            self.mtz_generator = CCIF2MTZ(path_obj)
            if not glob.glob(self.mtz_name):
                print "cif2mtz does not produce *.mtz file"
                self._path_dict['process_log_content'] += \
                       "cif2mtz does not produce *.mtz file"
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                sys.exit(1)
                

####################################################################

class CSolutionCheck(CExeCode):
    """ This class that perform solution check by running 'solution_check'.
    The class is descendent of the base classs 'CExeCode' """
    
    def __init__( self, path_obj ):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        # check if we have the initial solution path in the path_dict
        if self._path_dict.has_key("infile_sol"):
            self._path_dict['infile_sol']  = "/data2/fei/Database_BALBES/All_pdb/All/" + self._path_dict["name_root"] + ".pdb"

            self.__exeCode = os.path.join(self._path_dict["bin_path"], "solution_check")
               
            self.xml_name  = os.path.join(self._path_dict['xml_path'], 
                                      self._path_dict['name_root'] + "_solution_check.xml")
            self.log_name =  os.path.join(self._path_dict['doc_path'], "solution_check.log")

        self.idx_err = 0

        self.chain_found      = 0
        self.chain_expected   = 0

    def set_keypair(self, key_t, value_t):
        if key_t:
            self._path_dict[key_t] = value_t
            
    def controller (self, t_model = None):
                

        print "|-----------------------------------------|"
        print "| Solution check aganst the deposited PDB |"
        print "|-----------------------------------------|"
 
        # set the command lines for the code 'solution_check'

        self.chain_found      = 0
        self.chain_expected   = 0

        self._cmdline  = ' '
        
        if t_model :
            file_in_xyz = t_model.refi_sol_xyz
        else :
            if self._path_dict.has_key("in_xyz"):
                file_in_xyz = self._path_dict["in_xyz"]
            else :
                file_in_xyz = None 
        if glob.glob(file_in_xyz) and \
           glob.glob(self._path_dict["infile_sol"]):
            self._cmdline +=  ' %s <<stop > %s \n' %  (self.__exeCode, self.log_name)
            self._cmdline +=  '     \n'
            self._cmdline +=  '  %s \n' % file_in_xyz
            self._cmdline +=  '  %s \n' % self._path_dict["infile_sol"]
            self._cmdline +=  '  %s \n' % (self._path_dict["scr_path"] + "/")
            self._cmdline +=  'stop'
            
            os.system(self._cmdline)

            t_xml = os.path.join(self._path_dict["cur_path"], "solution_check.xml")
            if glob.glob(t_xml):
                shutil.move(t_xml, self.xml_name)
                self.info_analysis()
            else :
                print "Program 'solution_check' has failed "
                self._path_dict['process_log_content'] += \
                      "Program 'solution_check' has failed \n"
                self.idx_err = 1

            
        else :
            print "can not find either %s or %s, why?  " % (self._path_dict["in_xyz"],
                                               self._path_dict["infile_sol"])
            print "no solution check will be carried out"
            self.idx_err = 1
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
            
    def info_analysis(self):
        """Extract information from the XML file generated by 'solution_check'. """
                
        # Organise the file path and name
        if not glob.glob(self.xml_name):
            print "no xml is generated for solution check"
            self._path_dict['process_log_content'] += \
                  "no xml is generated for solution check \n"
            self.idx_err = 1
        else:
            # Open xml file
            try:
                sol_check_xml = open(self.xml_name,"r")
            except IOError:
                print  self.xml_name  , " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                       "%s could not be opened for reading \n" %self.xml_name
                self.idx_err = 1

            # Handle with xml file
            try:
                sol_check_xml_reader   = PyExpat.Reader()
                sol_check_xml_document = \
                                       sol_check_xml_reader.fromStream(sol_check_xml)
                sol_check_xml.close()
            except ExpatError:
                print self.xml_name, "format errors"
                self._path_dict['process_log_content'] += \
                      "%s format errors \n" %self.xml_name
                self.idx_err = 1
            else :
                rootElement = StripXml(sol_check_xml_document.documentElement)

                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.err_level = int(node.firstChild.nodeValue)
                    elif node.nodeName == "err_message":
                        self.err_message = node.firstChild.nodeValue
                    elif node.nodeName == "job":
                        self.job_name = node.firstChild.nodeValue
                    elif node.nodeName == "n_ch_str":
                        self.chain_expected = int(node.firstChild.nodeValue)
                        print "The number of chain expected is %d " % self.chain_expected
                        self._path_dict['process_log_content'] += \
                              "The number of chain expected is %d \n" % self.chain_expected
                    elif node.nodeName == "n_ch_found":
                        self.chain_found = int(node.firstChild.nodeValue)
                        print "The number of chain found is %d " % self.chain_found
                        self._path_dict['process_log_content'] += \
                              "The number of chain found is %d \n" % self.chain_found

                sol_check_xml_reader.releaseNode(sol_check_xml_document)
        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""


class CCheck_Cell_SG (CExeCode) :
    """ A class that performs  database search a structure which has very similar
    for cell and space group to a input refection data file , using
        the program 'chech_cell_sg'. The class is inheritted from CExeCode """

    def __init__( self, path_obj, t_cell, t_sg ):
        """Set the pathes where we can find exe codes, input and output data"""

        self.idx_err = 0
        CExeCode.__init__(self, path_obj)
        self.__exeCode  = os.path.join(self._path_dict["bin_path"], "check_cell_sg")
        self.pdb_code   = None
        self.n_structure  = 0
        self.target_cell  = t_cell.strip()
        cell_p = self.target_cell.split()
        self.target_cell_len = cell_p[0] + " " + cell_p[1]+ " " +cell_p[2]
        self.target_cell_ang = cell_p[3] + " " + cell_p[4]+ " " +cell_p[5]
        self.target_sg    = t_sg.strip()
        self.lim          = 0.02
        self.diff         = 1.0
        self.cell         = ""         
        self.cell_len     = ""
        self.cell_ang     = "" 
        
        self.controller (t_cell, t_sg)

    def setCmdLineAndFile (self) :
        
        self.name_tag = "check_cell_sg" 
        # log and xml file name
        self.log_name = os.path.join(self._path_dict["doc_path"], self.name_tag + ".log")
        self.xml_name = os.path.join(self._path_dict["xml_path"], self.name_tag + ".xml")
        # creat the batch file
        self.batch_name  = os.path.join(self._path_dict["scr_path"], self.name_tag + ".bat")
        try:
            check_cell_sg_bat = open(self.batch_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                   "%s could not be opened for write\n"%self.batch_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else:
            os.putenv("MOLREP_DB", self._path_dict["sys_path"])
            os.putenv("CELL_SG_rep", self.log_name )

            print >> check_cell_sg_bat, "# -------------------------------- "
            print >> check_cell_sg_bat, self.__exeCode + "  << stop >> $CELL_SG_rep" 
            print >> check_cell_sg_bat, "# -------------------------------- " 
            print >> check_cell_sg_bat, "_DOC N  " 
            print >> check_cell_sg_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"] + "/")
            print >> check_cell_sg_bat, "_SG  %s" %   self.target_sg
            print >> check_cell_sg_bat, "_CELL %s " % self.target_cell
            print >> check_cell_sg_bat, "_LIM %.3f " % self.lim
            print >> check_cell_sg_bat, "_END " 
            print >> check_cell_sg_bat, "stop\n\n " 
            check_cell_sg_bat.close()

            os.chmod(self.batch_name, 0755)
            time.sleep(2)
            os.system(self.batch_name)
   
            t_xml = os.path.join(self._path_dict["cur_path"], "check_cell_sg.xml")
            t_out = MoveFile(t_xml,self.xml_name)
            if not t_out :
               self.idx_err = 1

    def info_analysis(self):
        """Extract information from a XML file created by 'check_cell_sg '  """

        # Open xml file
        if not self.idx_err:
            try:
                check_cell_sg_xml = open(self.xml_name,"r")
            except IOError:
                print  xml_name_pre  , " could not be opened for reading "
                self._path_dict['process_log_content'] += \
                   "%s could not be opened for reading\n"%xml_name_pre
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1

            # Handle with xml file
            try:
                check_cell_sg_xml_reader   = PyExpat.Reader()
                check_cell_sg_xml_document = check_cell_sg_xml_reader.fromStream(check_cell_sg_xml)
                check_cell_sg_xml.close()
            except ExpatError:
                print "%s format errors " % xml_name_pre 
                self._path_dict['process_log_content'] += \
                      "%s format errors " % xml_name_pre
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err =1
            else :
                rootElement = StripXml(check_cell_sg_xml_document.documentElement)

                for node in rootElement.childNodes:
                    if node.nodeName == "err_level":
                        self.err_level = int(node.firstChild.nodeValue)
                    elif node.nodeName == "err_message":
                        self.err_message = node.firstChild.nodeValue
                    elif node.nodeName == "n_structure":
                        self.n_structure =int(node.firstChild.nodeValue)
                    elif node.nodeName == "PDB_code":
                        self.pdb_code =node.firstChild.nodeValue
                    elif node.nodeName == "diff":
                        self.diff =float(node.firstChild.nodeValue)
                    elif node.nodeName == "cell":
                        self.cell =node.firstChild.nodeValue.strip()
                        cell_pa = self.cell.split()
                        self.cell_len = cell_pa[0] + " " + cell_pa[1]+ " " +cell_pa[2]
                        self.cell_ang = cell_pa[3] + " " + cell_pa[4]+ " " +cell_pa[5]
            
                check_cell_sg_xml_reader.releaseNode(check_cell_sg_xml_document)
             
                # Output the comparison between target and found sttructures
                if self.n_structure :
                
                    print "%d structure is found" % self.n_structure 
                    for i in range(self.n_structure):
                        print "The details of found structure %d " %(i+1)
                        print "|--------------------------------------------|"
                        print "|  PDB_CODE      |","%s"% self.pdb_code.center(25),"|"
                        print "|----------------|---------------------------|"
                        print "|  SPACE GROUP   |","%s"% self.target_sg.center(25),"|"
                        print "|----------------|---------------------------|"
                        print "|  CELL LENGTH   |","%s"% self.cell_len.center(25),"|"
                        print "|----------------|---------------------------|"
                        print "|  CELL ANGLE    |","%s"% self.cell_ang.center(25),"|"
                        print "|----------------|---------------------------|",

                    self._path_dict['process_log_content'] += \
                          "%d structure is found\n" % self.n_structure
                    for i in range(self.n_structure):
                        self._path_dict['process_log_content'] += \
                          "The details of found structure %d\n" %(i+1)
                        self._path_dict['process_log_content'] += \
                          "|------------------------------------------|\n"
                        self._path_dict['process_log_content'] += \
                          "|  PDB_CODE      |%s|\n"% self.pdb_code.center(25)
                        self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                        self._path_dict['process_log_content'] += \
                          "|  SPACE GROUP   |%s|\n"% self.target_sg.center(25)
                        self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                        self._path_dict['process_log_content'] += \
                          "|  CELL LENGTH   |%s|\n"% self.cell_len.center(25)
                        self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                        self._path_dict['process_log_content'] += \
                          "|  CELL ANGLE    |%s|\n"% self.cell_ang.center(25)
                        self._path_dict['process_log_content'] += \
                          "|----------------|-------------------------|\n"
                else :
                    print "No structure of similar cell and space group was found "
                    self._path_dict['process_log_content'] += \
                          "No structure of similar cell and space group was found \n" 
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
		self._path_dict['process_log_content'] = ""

    def controller (self, t_cell, t_sg) :

        print "\n#-----------------------------------------------------------#"
        print "# Search for Structures with Similar Cell and Space Group   #"
        print "#-----------------------------------------------------------#"
  
        self._path_dict['process_log_content'] += \
              "\n#-----------------------------------------------------------#\n"
        self._path_dict['process_log_content'] += \
              "# Search for Structures with Similar Cell and Space Group   #\n"
        self._path_dict['process_log_content'] += \
              "#-----------------------------------------------------------#\n"
        if not self.idx_err :
            self.setCmdLineAndFile ()
            if not self.idx_err:
                self.info_analysis()

class CGet_File (CExeCode):
     """This Class can be implemented to get a file from a remote or local source 
     site provided by users and then process it locally """

     def __init__( self, dict_provided = None  ):
          self.__dict_setting = { }
          CExeCode.__init__(self, dict_provided)
          self.idx_err = 0
          if dict_provided :
              self.__dict_setting =  dict_provided
              self.__local_path_list = [ ]
              self.__remote_path_list = [ ]
              self.out_file = None
              self.log_name = self.__dict_setting["path_dist_rsf"] + "/curl.log"

              self.controller()
          else :
              print " A location for the file is expected from users "
              self._path_dict['process_log_content'] += \
                    " A location for the file is expected from users "
              WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
              self.idx_err = 1

     def Get_File_RSDB(self):
          """ Function to get and process a file from RCSB """

          # test if RCSB could be connected
          HOST = "198.202.75.77"
          PORT = 21
       
          # test connection
          try:
               mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
               if sys.version_info[0] >= 2 and  sys.version_info[1] >=  3:
                   mySocket.settimeout(20.0)
               mySocket.connect((HOST, PORT) )
          except socket.error:
               print "Connection to RCSB can not be established"
               self._path_dict['process_log_content'] += \
                     "Connection to RCSB can not be established"
               WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
               return None 
    
          mySocket.close()
          if self.__dict_setting["file_type"] == "PDB" :
               remote_path  = "ftp://ftp.rcsb.org/pub/pdb/data/structures/all/pdb/"
               file_name1 = "pdb" + self.__dict_setting["code_name"] + ".ent.Z"
               file_name2 = self.__dict_setting["path_dist_pdb"] + "/" + file_name1
               file_name3 = self.__dict_setting["path_dist_pdb"] + "/" + \
                            "pdb" + self.__dict_setting["code_name"] + ".ent"
               file_name4 = self.__dict_setting["path_dist_pdb"] + "/" + \
                            self.__dict_setting["code_name"] + ".pdb"

          elif self.__dict_setting["file_type"] == "ENT" :
               remote_path  = "ftp://ftp.rcsb.org/pub/pdb/data/structures/all/structure_factors/"
               file_name1 = "r" +  self.__dict_setting["code_name"] + "sf.ent.Z"
               file_name2 = "r" +  self.__dict_setting["code_name"] + "sf.ent"
               file_name3 = self.__dict_setting["path_dist_rsf"] + "/" + \
                            + self.__dict_setting["code_name"] + ".ent"

          execmd     = "curl -o "  + file_name2 + "  "  + remote_path + file_name1 + ">& " + self.log_name
          os.system(execmd)

          if glob.glob(file_name2):
              execmd = "gunzip " + file_name2
              os.system(execmd)
              if glob.glob(file_name3):
                  shutil.move(file_name3, file_name4)
                  return file_name4
              else : # for debug only
                  print "get the new pdb file %s, but can not gunzip it, why?" \
                        % file_name1
                  return None
          else :
              print "there is no pdb file %s in RCSB, curl failed" % file_name1
              self._path_dict['process_log_content'] += \
                    "there is no pdb file %s in RCSB, curl failed" % file_name1
              WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])

              return None

     def Get_File_local(self ):
          """Function to get and process a file from a local site. Three sites are used
          temporarily at the moment. They are : 1) SYSTEM_SITE/pdb_DB/
          2) SYSTEM_SITE/pdb_SOL  3) /y/database/brookhaven/pdb/, should be changed
          to user's input"""

          i_find = 0
          if self.__dict_setting["file_type"] == "PDB":
               if self.__dict_setting.has_key("sys_path") :
                   self.__local_path_list.append("/data/shared/fei/Database_BALBES/All_pdb/All")
                   # self.__local_path_list.append(self.__dict_setting["sys_path"] + "pdb_SOL/")
                   self.__local_path_list.append("/y/database/brookhaven/pdb")

                   for l_pa in self.__local_path_list:
                       if i_find :
                            break
                       else :
                            t_name = self.__dict_setting["code_name"] + ".pdb"
                            file_name1 = os.path.join(l_pa, t_name)
                            if glob.glob(file_name1):
                                 file_name2 = os.path.join(self.__dict_setting["path_dist_pdb"], 
                                              self.__dict_setting["code_name"] + ".pdb")
                                 execmd     = "cp  "  + file_name1 + "   "   + file_name2
                                 os.system(execmd)
                                 if glob.glob(file_name2):
                                      i_find = 1

          if not i_find :
               return None
          else :
               return file_name2

     # a controller function
     def controller(self ):
          self.out_file = self.Get_File_local()
          if not self.out_file:
              print "get structures of similar cell and sg from local failed, try remote sites "
              self.idx_err = 1
          #    self.out_file = self.Get_File_RSDB()
          #if not self.out_file :
          #    print "Get file from the remote site failed "
          #    self._path_dict['process_log_content']+= \
          #           "Get file from the remote site failed "
                   
              self.idx_err = 1

class CAlign_DB(CExeCode):
     """This Class can be implemented to find identity between two  sequences (either from
     pdb or sequence files) """

     def __init__( self, path_obj, file_1, file_2  ):

         CExeCode.__init__(self, path_obj)
         # executable 
         self.__exeCode = os.path.join(self._path_dict["bin_path"],"align_DB")
         self.xml_name   = os.path.join(self._path_dict["xml_path"], "align_DB.xml")
         self.log_name   = os.path.join(self._path_dict["doc_path"], "align_DB.log")
         self.bat_name   = os.path.join(self._path_dict["scr_path"], "align_DB.bat")

         self.idx_err = 0
         self.ident   = 0.0

         self.controller (file_1, file_2)

     def setCmdLineAndFile (self, file_1, file_2) :

        try:
            align_DB_bat = open(self.bat_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self.idx_err = 1
        else:
            print >> align_DB_bat, "_DOC N  " 
            print >> align_DB_bat, "_PATH_SCR %s " % (self._path_dict["scr_path"] + "/")
            print >> align_DB_bat, "_FILE_1  %s" % file_1
            print >> align_DB_bat, "_FILE_2  %s" % file_2
            print >> align_DB_bat, "_END "
            
            align_DB_bat.close()

            self._cmdline = ' %s  <%s > %s' %(self.__exeCode, self.bat_name, self.log_name)

     def info_analysis(self):
         """Extract information from a XML file created by 'align_DB '  """
         # Open xml file
         try:
             align_DB_xml = open(self.xml_name,"r")
         except IOError:
             print  self.xml_name  , " could not be opened for reading "
             self._path_dict['process_log_content'] += \
                    "%s could not be opened for reading \n" %self.xml_name
             WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
             self.idx_err = 1

         # Handle with xml file
         try:
             align_DB_xml_reader   = PyExpat.Reader()
             align_DB_xml_document = align_DB_xml_reader.fromStream(align_DB_xml)
             align_DB_xml.close()
         except ExpatError:
             print "%s format errors " % self.xml_name
             self._path_dict['process_log_content'] += \
                   "%s format errors \n" % self.xml_name
             WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
             self.idx_err =1
         else :
             rootElement = StripXml(align_DB_xml_document.documentElement)

             for node in rootElement.childNodes:
                 if node.nodeName == "err_level":
                     self.err_level = int(node.firstChild.nodeValue)
                 elif node.nodeName == "err_message":
                     self.err_message = node.firstChild.nodeValue
                 elif node.nodeName == "ident":
                     self.ident =float(node.firstChild.nodeValue)

             align_DB_xml_reader.releaseNode(align_DB_xml_document)
             print "| CHAIN IDENTITY |","%s"% str(self.ident).center(25),"|"
             print "|--------------------------------------------|"

             self._path_dict['process_log_content'] += \
                   "| CHAIN IDENTITY |%s|\n"% str(self.ident).center(25)
             self._path_dict['process_log_content'] += \
                   "|------------------------------------------|\n\n"
             WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
             self._path_dict['process_log_content'] = ""

     def check_ident(self, t_diff) :
         go_mode = 0
         if self.ident >= 90.00 :
             go_mode = 1
             print "#-----------------------------------------------------------#"
             print "# Alignment identity > 90 percent, go for direct refinement #"
             print "#-----------------------------------------------------------#"
             self._path_dict['process_log_content'] += \
                   "#-----------------------------------------------------------#\n"
             self._path_dict['process_log_content'] += \
                   "# Alignment identity > 90 percent, go for direct refinement #\n"
             self._path_dict['process_log_content'] += \
                   "#-----------------------------------------------------------#\n"
         else :
              if t_diff  < 0.005:
                  go_mode = 1
                  print "#-----------------------------------------------------------#"
                  print "# Alignment identity < 90 percent.                          #"
                  print "# cell and space group para difference < 0.5 percent        #"
                  print "# go for direct refinement                                  #"
                  print "#-----------------------------------------------------------#"
                  self._path_dict['process_log_content'] += \
                        "#-----------------------------------------------------------#\n"
                  self._path_dict['process_log_content'] += \
                        "# Alignment identity < 90 percent.                          #\n"
                  self._path_dict['process_log_content'] += \
                        "# cell and space group para difference < 0.5 percent        #\n"
                  self._path_dict['process_log_content'] += \
                        "# go for direct refinement                                  #\n"
                  self._path_dict['process_log_content'] += \
                        "#-----------------------------------------------------------#\n"
              else :
                  print "#-----------------------------------------------------------#"
                  print "# Alignment identity < 90 percent.                          #"
                  print "# cell and space group para difference > 0.5 percent        #"
                  print "# go for automatic molecule replacement                     #"
                  print "#-----------------------------------------------------------#"

                  self._path_dict['process_log_content'] += \
                        "#-----------------------------------------------------------#\n"
                  self._path_dict['process_log_content'] += \
                        "# Alignment identity < 90 percent.                          #\n"
                  self._path_dict['process_log_content'] += \
                        "# cell and space group para difference > 0.5 percent        #\n"
                  self._path_dict['process_log_content'] += \
                        "# go for automatic molecule replacement                     #\n"
                  self._path_dict['process_log_content'] += \
                        "#-----------------------------------------------------------#\n"
         
         WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
         self._path_dict['process_log_content'] = ""
         return go_mode
   
     def controller (self, file_1, file_2) :
         if not self.idx_err :
             self.setCmdLineAndFile (file_1, file_2)
             if not self.idx_err :
                 os.system(self._cmdline)
                 t_xml = os.path.join(self._path_dict['cur_path'], "align_DB.xml")
                 MoveFile(t_xml, self.xml_name)
                 if not self.idx_err :
                     self.info_analysis()
                    
                     
class CPDBTOSEQ(CExeCode):
     """This Class can be implemented to produce a sequence file from a PDB file
     using code 'pdb2s' """

     def __init__( self, path_obj, file_1 ):

         CExeCode.__init__(self, path_obj)
         # executable 
         self.__exeCode = os.path.join(self._path_dict["bin_path"], "pdb2s")
         # files
         self.xml_name   = os.path.join(self._path_dict['xml_path'], "pdb2s.xml")
         self.log_name   = os.path.join(self._path_dict['doc_path'], "pdb2s.log")
         self.bat_name   = os.path.join(self._path_dict['scr_path'], "pdb2s.bat")
         self.in_file_name = file_1
         file_s      = file_1.split("/")[-1].split(".")[0] + ".seq"
         self.name     = os.path.join(self._path_dict['scr_path'], file_s)
         self.idx_err = 0
         self.controller ( )

     def setCmdLineAndFile (self ) :

        try:
            pdb2s_bat = open(self.bat_name,"w")
        except IOError:
            print self.batch_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                    "%s could not be opened for write \n" %self.batch_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self.idx_err = 1
        else:
            print >> pdb2s_bat, " N  " 
            print >> pdb2s_bat,  self.in_file_name 
            print >> pdb2s_bat,  self.name 
            print >> pdb2s_bat, " ? " 
            print >> pdb2s_bat, " "
            pdb2s_bat.close()
            
            self._cmdline = ' %s  <%s > %s ' %(self.__exeCode, self.bat_name, self.log_name )
            
     def info_analysis(self):
         """Extract information from a XML file created by 'align_DB '  """

         # Organise the file path and name
         if not glob.glob(self.xml_name):
             print "pdb2s.xml is not found  "
             self._path_dict['process_log_content'] += \
                   "pdb2s.xml is not found \n"
             WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
             self.idx_err = 1
         else:
             # Open xml file
             try:
                 pdb2s_xml = open(self.xml_name,"r")
             except IOError:
                 print  xml_name_pre  , " could not be opened for reading "
                 self._path_dict['process_log_content'] += \
                     "%s could not be opened for reading \n" %xml_name_pre
                 WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                 self.idx_err = 1
             else :
                 # Handle with xml file
                 try:
                     pdb2s_xml_reader      = PyExpat.Reader()
                     pdb2s_xml_document    = \
                                           pdb2s_xml_reader.fromStream(pdb2s_xml)
                     pdb2s_xml.close()
                 except ExpatError:
                     print "can not create a reader object for XML file %s" % xml_name_pre
                     self._path_dict['process_log_content'] += \
                           "can not create a reader object for XML file %s" % xml_name_pre
                     WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                     self.idx_err =1
                 else :
                     rootElement = StripXml(pdb2s_xml_document.documentElement)

                     for node in rootElement.childNodes:
                         if node.nodeName == "err_level":
                             self.err_level = int(node.firstChild.nodeValue)
                         elif node.nodeName == "err_message":
                             self.err_message = node.firstChild.nodeValue
                         elif node.nodeName == "ch_id":
                             self.ch_id = node.firstChild.nodeValue
                         elif node.nodeName == "naa":
                             self.n_aa = int(node.firstChild.nodeValue)
                         elif node.nodeName == "sequence":
                             if not glob.glob(self.name):
                                 self.seq_file = node.getAttribute("file_seq")
                     pdb2s_xml_reader.releaseNode(pdb2s_xml_document)

             
                     print "\n|  ALIGNED CHAIN |","%s"% self.ch_id.center(25),"|"
                     print "|----------------|---------------------------|"          
                     print "|  ALIGNED ACIDS |","%s"% str(self.n_aa).center(25),"|"
                     print "|----------------|---------------------------|"          
                     
                     self._path_dict['process_log_content'] += \
                           "|  ALIGNED CHAIN |%s|\n"% self.ch_id.center(25)
                     self._path_dict['process_log_content'] += \
                           "|----------------|-------------------------|\n"  
                     self._path_dict['process_log_content'] += \
                           "|  ALIGNED ACIDS |%s|\n"% str(self.n_aa).center(25)
                     self._path_dict['process_log_content'] += \
                           "|----------------|-------------------------|\n"     
                     WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                     self._path_dict['process_log_content'] = ""
     
     def controller (self) :

         if not self.idx_err :
             self.setCmdLineAndFile ()
             if not self.idx_err :
                 os.system(self._cmdline)
                 t_xml = os.path.join(self._path_dict['cur_path'], "pdb2s.xml")
                 MoveFile(t_xml, self.xml_name)
                 t_xml = os.path.join(self._path_dict['cur_path'], "temp.seq")
                 MoveFile(t_xml, self._path_dict['scr_path'])
                 if not self.idx_err :
                     self.info_analysis()

class CChocc(CExeCode):
    """ Class that accesses the quality of a solution model by running 'chocc'.
    The class is inheritted from the base classs 'CExeCode' """

    def __init__( self, path_obj ):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        self.idx_err = 0
        self.err_message = ""
        self.__exeCode = os.path.join(self._path_dict["bin_path"], "chocc")

    def controller(self, t_model, i_stage):

        print "\n#-----------------------------------------------------------#"
        print "# The Model Assesment by Occupancy Analysis                 #"
        print "#-----------------------------------------------------------#"
        self._path_dict['process_log_content'] = \
              "\n#-----------------------------------------------------------#\n"
        self._path_dict['process_log_content'] += \
              "# The Model Assesment by Occupancy Analysis                 #\n"
        self._path_dict['process_log_content'] += \
              "#-----------------------------------------------------------#\n"

        index_mod_n = t_model.get_index()
        index_dom     = t_model.get_index_domain()
        if t_model.asm:
            self.name_tag1 = "asm%s_struct%s_model%s_dom%s" \
                        %(str(index_mod_n[0]), str(index_mod_n[1]), str(index_mod_n[2]), str(index_dom))
        else :
            self.name_tag1 = "seq%s_struct%s_model%s_dom%s" \
                        %(str(index_mod_n[0]), str(index_mod_n[1]), str(index_mod_n[2]), str(index_dom))

        self.name_tag2   = "refmac_" + self.name_tag1 + "_ocp"
        self.name_tag3   = "chocc_" + self.name_tag1 

        #  run refmac in occupancy refinement mode. 

        self._path_dict["in_xyz"]  = t_model.solution_xyz
        self._path_dict["in_hkl"]  = t_model.solution_hkl
        self._path_dict["out_xyz"] = os.path.join(self._path_dict["tem_path"], self.name_tag2 + ".pdb")
        self._path_dict["out_hkl"] = os.path.join(self._path_dict["tem_path"], self.name_tag2 + ".mtz")

        self.refmac = CREFMAC(self._path_dict)

        self.refmac.log_name   = os.path.join(self._path_dict["doc_path"],self.name_tag2 + ".log")
        self.refmac.batch_name = os.path.join(self._path_dict["scr_path"],self.name_tag2 + ".bat")
        self.refmac.xml_name   = os.path.join(self._path_dict["xml_path"],self.name_tag2 + ".xml")

        self.refmac.controller("ocp")

        if glob.glob(self._path_dict["out_xyz"]):
            t_model.file_ocp_crd = self._path_dict["out_xyz"]
            # chocc run
            self.log_name = os.path.join(self._path_dict["doc_path"], self.name_tag3 + ".log")
            self.xml_name = os.path.join(self._path_dict["xml_path"], self.name_tag3 + ".xml")

            self.setCmdLineAndFile (t_model, i_stage)
            self.execute()
            self.info_analysis(t_model, i_stage)
   
        if glob.glob(self._path_dict["out_hkl"]):
            t_model.file_ocp_hkl = self._path_dict["out_xyz"]
        
    def setCmdLineAndFile(self, t_model, i_stage):

        # allow future change here

        self._cmdline = "chocc -m %s  " %t_model.file_ocp_crd
        self._cmdline += "-xml %s  " %self.xml_name
        self._cmdline += "-h  %s  " % (os.path.join(self._path_dict['data_path'],"hists.txt"))
        if i_stage == 1:
            self._cmdline += "-force all "
        self._cmdline += " <<stop stop\n"

    def info_analysis(self, t_model, i_stage ):  

        if not self.idx_err:
            # Open XML file
            try:
                chocc_xml = open(self.xml_name,"r")
            except IOError:
                print   " could not find %s for reading " % self.xml_name
                self._path_dict['process_log_content'] += \
                        " could not find %s for reading " % self.xml_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1
                sys.exit(1)

            # parse contents of XML file
            try:
                chocc_xml_reader   = PyExpat.Reader()
                chocc_xml_document = chocc_xml_reader.fromStream(chocc_xml)
                chocc_xml.close()
            except ExpatError:
                print "can not create a reader object for XML file: %s" %self.xml_name
                self._path_dict['process_log_content'] += \
                        " can not create a reader object for XML file: %s " % self.xml_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self._path_dict['process_log_content'] = ""
                self.idx_err = 1

            rootElement = StripXml(chocc_xml_document.documentElement) 
            
            for node in rootElement.childNodes:
                # Currently only pick one quantity --- quality_factor for all segments 
                if node.nodeName == "err_level":
                    self.idx_err = int (node.firstChild.nodeValue)
                elif node.nodeName == "err_message":
                    self.err_message = node.firstChild.nodeValue
                elif node.nodeName == "method":
                    for m_prop in node.childNodes:
                        if m_prop.nodeName == "segment":
                            for seg_prop in m_prop.childNodes:
                                if seg_prop.nodeName == "name":
                                    a_seg_name = seg_prop.firstChild.nodeValue.strip()
                                if seg_prop.nodeName == "quality_factor":
                                    try:
                                        t_q = float(seg_prop.firstChild.nodeValue)
                                    except:
                                        print "%s is not a number "%seg_prop.firstChild.nodeValue
                                        self._path_dict['process_log_content'] += \
                                              "%s is not a number " %seg_prop.firstChild.nodeValue
                                        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                                        self._path_dict['process_log_content'] = ""
                                        self.idx_err = 1
                                    else :
                                        t_model.segments[a_seg_name] = t_q
                                        print "qualityFactor for segment %s is %7.4f "\
                                                 %(a_seg_name, t_model.segments[a_seg_name])
                                        self._path_dict['process_log_content'] += \
                                                 "qualityFactor for segment %s is %7.4f "\
                                                 %(a_seg_name, t_model.segments[a_seg_name])

    
        
class CDoman2chains(CExeCode):

    def __init__(self, path_obj ):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        self.idx_err = 0
        self.err_message = ""
        self.__exeCode = os.path.join(self._path_dict["bin_path"], "domain2chain")

    def  setCmdLineAndFile (self, t_model) :

        self.bat_name =  os.path.join(self._path_dict["scr_path"], self.name_tag + ".bat" )
        try:
            do2ch_bat = open(self.bat_name,"w")
        except IOError:
            print self.bat_name, " could not be opened for write"
            self._path_dict['process_log_content'] += \
                    "%s could not be opened for writing \n" %self.bat_name
            self.idx_err = 1
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""
        else:
            self.tmp_pdb_name = os.path.join(self._path_dict["scr_path"],self.name_tag + ".pdb") 
            print >> do2ch_bat, "_DOC  Y>%s "% (self._path_dict["doc_path"] + "/")
            print >> do2ch_bat, "FILE_PDB %s " %t_model.refi_sol_xyz
            print >> do2ch_bat, "FILE_OUT %s " %self.tmp_pdb_name
            print >> do2ch_bat, "PATH_SCR %s " %self._path_dict["scr_path"]
            print >> do2ch_bat, "\n"
            do2ch_bat.close()
   
            self._cmdline  = ' %s  <%s ' %  (self.__exeCode, self.bat_name)

    def controller(self, t_model = None ):

        self.name_tag = "domain2chains_" + t_model.name_tag 

        if t_model:
            self.setCmdLineAndFile(t_model)

            self.log_name = os.path.join(self._path_dict["doc_path"], self.name_tag + ".log")
            self.xml_name = os.path.join(self._path_dict["xml_path"], self.name_tag + ".xml")
     
            self.execute()

            if glob.glob(self.tmp_pdb_name):
                shutil.copyfile(self.tmp_pdb_name, t_model.refi_sol_xyz)
            else :
                print "Warn: could not find the output file from 'domain2chains', the process continues " 
                self._path_dict['process_log_content'] += \
                      "Warn: could not find the output file from 'domain2chains', the process continues \n"
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self._path_dict['process_log_content'] = ""
   
            tmp_xml_name = os.path.join(self._path_dict["doc_path"],"domain2chain.xml")
            if glob.glob(tmp_xml_name):
                shutil.move(tmp_xml_name,self.xml_name)

class CPOINTLESS (CExeCode):
    """ Class that wrap-ups 'pointless'. The class is a descendent of the base classs 'CExeCode' """

    def __init__( self, path_obj):
        """Set the pathes where we can find exe codes, input and output data"""

        CExeCode.__init__(self, path_obj)
        self.__exeCode = os.path.join(os.getenv("CBIN"), "pointless")

        self.xml_name = ""
        self.log_name = ""
        self.bat_name = ""
        self.name_tag = ""

        self.xyz_in   = ""
        self.hkl_in   = ""
        self.hkl_out  = ""

        self.pointless_dict = {}

        # default keywords, some will be decided on-fly such as LABIn....

        self.keywords = {}
        self.keywords['provided']      = []
        self.keywords['default']       = []
        
        self.mode  = 0

        self.idx_err = 0

    def setMode (self, t_user_kws) :

        for a_line in t_user_kws:
            self.keywords['provided'].append(a_line.strip())

        self.mode = 1

    def setCmdLineAndFile (self) :

        tmp_cmdline = ''
        tmp_cmdline += ' HKLIN %s '  % self.hkl_in
        # tmp_cmdline += ' XYZIN %s '  % self.xyz_in  # check the version of pointless. 
        tmp_cmdline += ' HKLOUT %s ' % self.hkl_out
        tmp_cmdline += ' XMLOUT %s ' % self.xml_name

             
        try:
            pointless_bat = open(self.bat_name,"w")
        except IOError:
            print "%s could not be opened for write" %self.bat_name,
            self._path_dict['process_log_content'] += \
                      "%s could not be opened for write" %self.bat_name
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            sys.exit(1)

        if self.keywords['provided'] : # special requirement 
            
            for item in self.keywords['provided'] : 
                print >> pointless_bat, item
                print item
                self._path_dict['process_log_content'] += \
                      "%s \n"%item
            pointless_bat.close()
            self._cmdline = ' %s %s <%s' %(self.__exeCode, tmp_cmdline, self.bat_name )
        else: # default. Do we need any keywords for this situation, no at the moment
            #for item in self.keywords['default'] : 
            #    print >> pointless_bat, item
            self._cmdline = ' %s %s ' %(self.__exeCode, tmp_cmdline )
        print self._cmdline


    def info_analysis (self, t_model) :
         
        """Extract information from the XML file generated by 'pointless' """
        # Organise the file path and name
        if not os.path.isfile(self.xml_name) :
            print "BUG, No xml is generated by pointless "
            self._path_dict['process_log_content'] += \
                  "BUG, No xml is generated by pointless"
            self.idx_err = 1
            sys.exit(1)
        else:
            # Open xml file
            try:
                pointless_xml = open(self.xml_name,"r")
            except IOError:
                print  "%s could not be opened for reading " %self.xml_name 
                self._path_dict['process_log_content'] += \
                       "%s could not be opened for reading \n"%self.xml_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1
                sys.exit(1)

            # Handle with xml file
            try:
                pointless_xml_reader   = PyExpat.Reader()
                pointless_xml_document = pointless_xml_reader.fromStream(pointless_xml)
                pointless_xml.close()
            except ExpatError:
                print "XML format fault in %s"%self.xml_name
                self._path_dict['process_log_content'] += \
                      "XML format fault in %s \n"%self.xml_name
                WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
                self.idx_err = 1
                sys.exit(1)
                
            rootElement = StripXml(pointless_xml_document.documentElement)
            for node in rootElement.childNodes:
                if node.nodeName == "ReflectionFile":
                    a_stream = node.getAttribute("stream")
                    if a_stream == "XYZIN" :
                        self.pointless_dict['xyz_in'] = SymmtryData()   # a temp data model
                        for prop_xyz_in in node.childNodes:
                            if prop_xyz_in.nodeName == "cell":
                                for prop_cell in prop_xyz_in.childNodes:
                                    if prop_cell.nodeName == "a":
                                        self.pointless_dict['xyz_in'].a = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "b":
                                        self.pointless_dict['xyz_in'].b = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "c":
                                        self.pointless_dict['xyz_in'].c = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "alpha":
                                        self.pointless_dict['xyz_in'].alpha = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "beta":
                                        self.pointless_dict['xyz_in'].beta = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "gamma":
                                        self.pointless_dict['xyz_in'].gamma = float(prop_cell.firstChild.nodeValue)
                            if prop_xyz_in.nodeName == "SpacegroupName":
                                    self.pointless_dict['xyz_in'].sg = prop_xyz_in.firstChild.nodeValue
                    elif a_stream == "HKLIN" :
                        self.pointless_dict['hkl_in'] = SymmtryData()   # a temp data model
                        for prop_hkl_in in node.childNodes:
                            if prop_hkl_in.nodeName == "cell":
                                for prop_cell in prop_hkl_in.childNodes:
                                    if prop_cell.nodeName == "a":
                                        self.pointless_dict['hkl_in'].a = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "b":
                                        self.pointless_dict['hkl_in'].b = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "c":
                                        self.pointless_dict['hkl_in'].c = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "alpha":
                                        self.pointless_dict['hkl_in'].alpha = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "beta":
                                        self.pointless_dict['hkl_in'].beta = float(prop_cell.firstChild.nodeValue)
                                    if prop_cell.nodeName == "gamma":
                                        self.pointless_dict['hkl_in'].gamma = float(prop_cell.firstChild.nodeValue)
                            if prop_hkl_in.nodeName == "SpacegroupName":
                                    self.pointless_dict['hkl_in'].sg = prop_hkl_in.firstChild.nodeValue

                if node.nodeName == "IndexScores":
                        self.pointless_dict['info_reindex'] = {} 
                        self.pointless_dict['info_reindex'] ['operations'] =  [] 
                        for prop_reindex in node.childNodes:
                            if prop_reindex.nodeName == "ScoreCount":
                                self.pointless_dict['info_reindex']['num_reindex'] =  int(prop_reindex.firstChild.nodeValue)
                            if prop_reindex.nodeName == "Index":
                                a_index = ReindexOp()
                                for prop_index in prop_reindex.childNodes:
                                    if prop_index.nodeName == "number":
                                        a_index.idx = int(prop_index.firstChild.nodeValue)
                                    if prop_index.nodeName == "CC":                        
                                        a_index.score = float(prop_index.firstChild.nodeValue)
                                    if prop_index.nodeName == "NCC":
                                        a_index.ncc = int(prop_index.firstChild.nodeValue)
                                    if prop_index.nodeName == "R":
                                        a_index.R = float(prop_index.firstChild.nodeValue)
                                    if prop_index.nodeName == "ReindexOperator":
                                        a_index.operator = prop_index.firstChild.nodeValue
                                    if prop_index.nodeName == "ReindexMatrix":
                                        a_index.matrix = prop_index.firstChild.nodeValue
                                self.pointless_dict['info_reindex']['operations'].append(a_index)

            pointless_xml_reader.releaseNode(pointless_xml_document)
        
            # Now output some information to the users
            # manipulate format
            t_data_in_name = self.hkl_in.strip().split("/")[-1].strip()
            t_data_out_name = self.hkl_out.strip().split("/")[-1].strip()
            t_cell_len  = "%5.2f  %5.2f  %5.2f"%(self.pointless_dict['hkl_in'].a, self.pointless_dict['hkl_in'].b, 
                                                 self.pointless_dict['hkl_in'].c)
            t_cell_ang  = "%5.2f  %5.2f  %5.2f"%(self.pointless_dict['hkl_in'].alpha, self.pointless_dict['hkl_in'].beta,
                                                  self.pointless_dict['hkl_in'].gamma)

            print "Re-index Data file: %s "%t_data_in_name
            print "|---------------------------------------------------------------|"
            print "|%s|"%("Information about re-index".center(63))
            print "|---------------------------------------------------------------|"
            print "|%s|%s|"%("Space Group".center(22),self.pointless_dict['hkl_in'].sg.center(40))
            print "|----------------------|----------------------------------------|"
            print "|%s|%s|"%("Cell Lengths".center(22),t_cell_len.center(40))
            print "|----------------------|----------------------------------------|"
            print "|%s|%s|"%("Cell Angles".center(22),t_cell_ang.center(40))
            print "|----------------------|----------------------------------------|"
            print "|%s|%s|"%("Operator".center(22),self.pointless_dict['info_reindex']['operations'][0].operator.center(40))
            print "|---------------------------------------------------------------|"
            print "The mtz file after re-index: %s"%t_data_out_name
            print "This file will be used for further refinement and model building" 
            self._path_dict['process_log_content'] += \
                            "Re-index Data file: %s \n"%t_data_in_name
            self._path_dict['process_log_content'] += \
                            "|---------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "|%s|\n"%("Information about re-index".center(63))
            self._path_dict['process_log_content'] += \
                            "|---------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "|%s|%s|\n"%("Space Group".center(22),self.pointless_dict['hkl_in'].sg.center(40))
            self._path_dict['process_log_content'] += \
                            "|----------------------|----------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "|%s|%s|\n"%("Cell Lengths".center(22),t_cell_len.center(40))
            self._path_dict['process_log_content'] += \
                            "|----------------------|----------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "|%s|%s|\n"%("Cell Angles".center(22),t_cell_ang.center(40))
            self._path_dict['process_log_content'] += \
                            "|----------------------|----------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "|%s|%s|\n"%("Operator".center(22),self.pointless_dict['info_reindex']['operations'][0].operator.center(40))
            self._path_dict['process_log_content'] += \
                            "|---------------------------------------------------------------|\n"
            self._path_dict['process_log_content'] += \
                            "The mtz file after re-index: %s\n"%t_data_out_name
            self._path_dict['process_log_content'] += \
                            "This file will be used for further refinement and model building\n"
            WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
            self._path_dict['process_log_content'] = ""


    def controller(self,t_model, t_kwList = None):


        print "\n#----------------------------------------------#"
        print "# Reindex using 'pointless'                    #"
        print "#----------------------------------------------#"
      
        self._path_dict['process_log_content'] += \
              "\n#----------------------------------------------#\n"
        self._path_dict['process_log_content'] += \
              "# Reindex using 'pointless'                    #\n"
        self._path_dict['process_log_content'] += \
              "#----------------------------------------------#\n"
        print "Reindex started at  %s " % time.ctime( time.time() )
        self._path_dict['process_log_content'] += \
              "Reindex started at  %s \n" % time.ctime( time.time() )

        self.name_tag = "pointless_%s"%t_model.name_tag
        self.xml_name = os.path.join(self._path_dict["xml_path"],self.name_tag +".xml")
        self.log_name = os.path.join(self._path_dict["doc_path"],self.name_tag +".log")
        self.bat_name = os.path.join(self._path_dict["doc_path"],self.name_tag +".bat") # for the test version using doc_path
                                                                                        # once released using scr_path
 
        self.hkl_in   = t_model.refi_in_hkl
        self.xyz_in   = t_model.refi_in_xyz
        self.hkl_out  = os.path.join(self._path_dict["doc_path"],self.name_tag +".mtz")

        self.keywords['provided'] = t_kwList

        self.setCmdLineAndFile() 

        self.execute()

        if not self.idx_err:
            
            # self.info_analysis(t_model), at the moment, it is not needed
            print "Re-index finished at  %s " % time.ctime( time.time() )
            self._path_dict['process_log_content'] += \
                 "Re-index finished at  %s \n" % time.ctime( time.time() )

        WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
        self._path_dict['process_log_content'] = ""
