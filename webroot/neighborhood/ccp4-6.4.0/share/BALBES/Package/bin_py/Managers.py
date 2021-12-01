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
## The date of last modification: 09/05/2007
#  Report any problem to fei@ysbl.york.ac.uk
import os
import sys
import glob
import re
import math
import string
import shutil
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

py_path= os.path.join(os.getenv("BALBES_ROOT"),"bin_py")
sys.path.append(py_path)

from StructHierachy import Model
from StructHierachy import Structure
from StructHierachy import Sequence
from StructHierachy import Assembly
from StructHierachy import SF_info
from StructHierachy import BOStruc

from UtilitiesClasses    import CPathDict
from UtilitiesClasses    import WriteFile
from UtilitiesClasses    import CMDHelp

from exeCodeClasses import CSFCHECK
from exeCodeClasses import CF2CIF
from exeCodeClasses import CCIF2MTZ
from exeCodeClasses import CGETMTZ


###################################################
class CGlobalManager:
    
    def __init__( self, t_argvs):


        if len(t_argvs) <3 :
            CMDHelp()
            sys.exit()

        else :
 
            self.gParaDict = {}
            self.gParaDict['user']      = os.environ['USER']
            self.gParaDict['cur_path']  = os.getcwd()
            
            # Match all key words entered by the user
            keyWordList = ["OUT_ROOTDIR", "NAME_ROOT", "HKLIN", "SEQIN", "HKLOUT", "XYZOUT", "SOLIN"]
            i_argv = 0
            for a_argv in  t_argvs :
                if a_argv[0] == "-" or a_argv in keyWordList :
                    self.matchKW(a_argv, t_argvs, len(t_argvs), i_argv)
                i_argv = i_argv + 1

            if not self.gParaDict.has_key("out_root_path"):
                self.gParaDict['out_root_path'] = os.path.join(self.gParaDict['cur_path'], "output_"+ self.gParaDict['user'])
                if not glob.glob(self.gParaDict['out_root_path']):
                    os.mkdir(self.gParaDict['out_root_path'])

    def matchKW( self, t_word, t_argvs, t_len_argvs, t_argv ):

        t_key = ""
        if t_word == "-pout" or t_word == "OUT_ROOTDIR" or t_word == "-o" :
            t_key = "out_root_path"
        elif t_word == "NAME_ROOT" :
            t_key = "ccp4i_root"
        elif t_word == "-fseq" or t_word == "SEQIN" or t_word == "-s":
            t_key = "infile_seq"
        elif t_word == "-fpdb" or t_word == "-m":
           t_key = "infile_pdb"
        elif t_word == "-lpdb" or t_word == "-l":
           t_key = "infile_pdb_lib"
        elif t_word == "-frsf" or t_word == "HKLIN" or t_word == "-f":
            t_key = "infile_mtz"
        elif t_word == "-x" or t_word == "XYZFX" :
            t_key = "fixed_mod"
        elif t_word == "HKLOUT" :
            t_key = "outfile_hkl"
        elif t_word == "XYZOUT" :
            t_key = "outfile_xyz"
        elif t_word == "-fsol" or t_word == "SOLIN":
            t_key = "infile_sol"
        elif t_word == "-sg" :
             t_key = "checksg"
             self.gParaDict[t_key] = True
        elif  t_word == "=arp":
             t_key = "arp"
             self.gParaDict[t_key] = True 
   

        messege1 = "You enter key word %s, but forget entering the associated file or path " %t_word
        messege2 = "You enter key word %s, but the associated file does not exist!" %t_word
        messege3 = "Wrong key word %s !" %t_word

        # output path
        if t_key != "arp" and  t_key != "checksg":
            if t_len_argvs <= t_argv + 1 :
                print messege1
                sys.exit()
            elif not t_key :
                print messege3
                sys.exit()
            else :
                if t_argvs[t_argv+1][0] == "-":
                    print messege1
                    sys.exit()

                if t_argvs[t_argv+1][0] == "/" or t_argvs[t_argv+1][0] == ".":
                    # user entered abs output path
                    self.gParaDict[t_key] =  t_argvs[t_argv+1]
                elif t_key == "infile_sol" :
                    self.gParaDict[t_key] = os.path.join(self['sys_path'], 'pdb_SOL', t_argvs[t_argv+1])
                else :
                    self.gParaDict[t_key] = os.path.join(self.gParaDict['cur_path'], t_argvs[t_argv+1])

                # check all input file and dir
                if not glob.glob(self.gParaDict[t_key]) and not t_key in ["outfile_xyz", "outfile_hkl", "ccp4i_root"]:
                    if t_key == "out_root_path":
                        os.mkdir(self.gParaDict['out_root_path'])
                    else:
                        print messege2
                        sys.exit()

class CManagers:
    
    def __init__( self, t_argvs):


        if len(t_argvs) <3 :
            CMDHelp()
            sys.exit()

        else :

            self.pathDict = CPathDict(t_argvs)
            self.mode         = 0        # default with key words -f and -s 
            
            self.pathDict["ccp4"] = os.path.join(os.getenv("CCP4"),"bin")
            if self.pathDict.has_key('infile_mtz'):
                self.checkInput()
            self.modeDecider()


    def checkInput(self ):
        """ Put here much more things   """

        #if self.pathDict.has_key('infile_mtz') :
        #   t_ext = self.pathDict['infile_mtz'].split(".")[-1]
        #    if t_ext.find('mtz') == -1 :
        if self.pathDict.has_key('infile_mtz'):
            self.pathDict['infile_mtz'] = CGETMTZ(self.pathDict).mtz_name
            if not glob.glob(self.pathDict['infile_mtz']):
                print "No mtz file is generated for BALBES, check CGETMTZ"
                sys.exit(1)

    def modeDecider(self ):
        
        # Modes:
        # 0:  The default mode, typical MR job with input sf and seq files
        # 1:  MR job using the user provided pdb models, no model search will be done within BALBES
        # 2:  MR job using the user provided model lib (a set of models in a directory). No model search 
        #     will be carried out within the lib 
        # 3:  No MR job, just search MR template models using the seq file provided by the user (this is 
        #     the only file provided by the user
        # 4:  The user provides a model. The info on this model will be used in model search procedures 
        #     (different from mode 2). The MR templated models found from BALBES database will contain this input model 
        #     automatically (This mode is mostly for solving a complex model
 
        if not self.pathDict.has_key('infile_mtz') :
            # no sf file is provided
            print "No structural factor file is provided!"
            self.pathDict['process_log_content'] += ("No structural factor file is provided!\n")
            if self.pathDict.has_key('infile_seq'):
                print "Your job is to find the model structures only"
                self.pathDict['process_log_content'] += ("Your job is to find the model structures only\n")
                self.mode = 3
            else :
                print "You provide neither structural factor file nor sequence file. BALBES stoped"
                self.pathDict['process_log_content'] += \
                      ("You provide neither structural factor file nor sequence file. BALBES stoped")
                WriteFile(self.pathDict['process_log_name'], self.pathDict['process_log_content'])
                sys.exit()

        elif self.pathDict.has_key('infile_pdb') :
            # -m, with and without -s, no matter if -l or not
            self.mode = 1
            # check user's pdb file
            if not glob.glob(self.pathDict["infile_pdb"]):
                print "Found no usr's input PDB file, check! BALBES stoped "
                self.pathDict['process_log_content'] += ("Found no usr's input PDB file, check! BALBES stoped")
                WriteFile(self.pathDict['process_log_name'], self.pathDict['process_log_content'])
                sys.exit()
        elif self.pathDict.has_key('infile_pdb_lib') and self.pathDict.has_key('infile_seq') :
            # -l with -s, without -m 
            self.mode = 2
            # check user's lib
            self.pathDict["infile_pdb_lib"] = self.pathDict["infile_pdb_lib"].strip()
            if self.pathDict["infile_pdb_lib"][-1] != "/":
                self.pathDict["infile_pdb_lib"] = self.pathDict["infile_pdb_lib"] + "/"
            if not glob.glob(self.pathDict["infile_pdb_lib"]):
                print "Found no usr's input PDB lib, check! BALBES stoped "
                self.pathDict['process_log_content'] += ("Found no usr's input PDB lib, check! BALBES stoped")
                WriteFile(self.pathDict['process_log_name'], self.pathDict['process_log_content'])
                sys.exit()
            else :
                self.pathDict["infile_pdb_list"] = self.pathDict["scr_path"] + "/" + "user_pdb.list"
                cmdLine = "ls " + self.pathDict["infile_pdb_lib"] + " > " + self.pathDict["infile_pdb_list"] 
                os.system(cmdLine)
        elif self.pathDict.has_key('fixed_mod'):
            if self.pathDct['fixed_mod'].isfile() :
                self.mode = 4
                if self.pathDict.has_key('infile_mtz') and  self.pathDict.has_key('infile_seq'):
                    if self.pathDict['infile_mtz'].isfile() and  self.pathDict['infile_seq'].isfile():
                        print "You have provide a model pdb. BALBES will use it as a fixed part"
                        print "of template models for MR"
                        self.pathDict['process_log_content'] +=  \
                              "You have provide a model pdb. BALBES will use it as a fixed part\n"
                        self.pathDict['process_log_content'] +=  \
                              "of template models for MR\n"
                    else:
                       print "BALBES could not find either input structural factor file or sequence file"
                       print "Check your input files locations"
                       self.pathDict['process_log_content'] +=  \
                           "BALBES could not find either input structural factor file or sequence file\n"
                       self.pathDict['process_log_content'] +=  \
                           "Check your input files locations\n"
                       sys.exit(1)
                else:
                    print "In this case, you need to use keywords for input mtz file and sequence file"
                    self.pathDict['process_log_content'] +=  \
                          "In this case, you need to use keywords for input mtz file and sequence file\n"  
                    sys.exit()
            else:
                print "You enter keyword for using fixed model, but BALBES could not find input pdb file"
                self.pathDict['process_log_content'] +=  \
                      "You enter keyword for using fixed model, but BALBES could not find input pdb file\n"
                sys.exit(1)

        # check if sequence is needed and then exists
        if self.mode == 0 or self.mode == 2 or self.mode == 3 or self.mode ==4:
            if not self.pathDict.has_key("infile_seq") or not glob.glob(self.pathDict["infile_seq"]):
                print "Found no sequence file, check! BALBES stoped "
                self.pathDict['process_log_content'] += ("Found no sequence file, check! BALBES stoped")
                WriteFile(self.pathDict['process_log_name'], self.pathDict['process_log_content'])
                sys.exit()
            else :
                self.seqCheckFile()

    def seqCheckFile(self):
        
        seq_strgrp = self.pathDict["infile_seq"].strip().split(".")
        na_ext = seq_strgrp[-1]
        seq_strgrp = os.path.splitext(self.pathDict["infile_seq"])
        na_main = seq_strgrp[0]
        na_ext = seq_strgrp[1]

        if na_ext != ".seq":
            t_seq_name = na_main + ".seq"
            cmdLine = "cp " + self.pathDict["infile_seq"] + "  " + t_seq_name
            os.system(cmdLine)
            time.sleep(1)
            if not glob.glob(t_seq_name):
                print "Can not change the name extension from '%s' to 'seq'. BALBES stopped " \
                      %na_ext
                self.pathDict['process_log_content'] += \
                      ("Can not change the name extension from '%s' to 'seq'. BALBES stopped \n" \
                        %na_ext)
                WriteFile(self.pathDict['process_log_name'], self.pathDict['process_log_content'])
                sys.exit()
            else :
                self.pathDict["infile_seq"] = t_seq_name
                print "sequence file name has been changed to %s " %self.pathDict["infile_seq"]
                self.pathDict['process_log_content'] += \
                    ("sequence file name has been changed to %s \n" %self.pathDict["infile_seq"])

        try : 
            file_seq = open(self.pathDict["infile_seq"], "r")
        except IOError:
            print " %s could not be opened for reading" %self.pathDict["infile_seq"]
            self.pathDict['process_log_content'] = \
                  ("%s could not be opened for reading \n" %self.pathDict["infile_seq"])
            WriteFile(self.pathDict['process_log_name'],self.pathDict['process_log_content'])
            self.pathDict['process_log_content'] = ""
            sys.exit(1)

        else :
            new_seq_file_name = na_main + "_checked.seq"
            try:
                new_seq_file = open(new_seq_file_name, "w")
            except IOError:
                print " %s could not be opened for writing" % new_seq_file_name
                self.pathDict['process_log_content'] = \
                      ("%s could not be opened for writing \n" %new_seq_file_name)
                WriteFile(self.pathDict['process_log_name'],self.pathDict['process_log_content'])
                self.pathDict['process_log_content'] = ""
                sys.exit(1)

            else :
                seqs = []
                t_seq = ""
                n_seq = 0
                comment_lines = []
                line_seqs = []
                t_seq_line    = ""
                small_frag    = []
                n_line = 0
                for aline in file_seq.readlines():
                    n_line = n_line + 1
                    aline = aline.strip()
                    if aline:
                        if n_line == 1 and aline[0] != ">":
                            print "The input sequence file is not of the exact FASTA format, please check your sequence file"
                            self.pathDict['process_log_content'] = \
                                  ("The input sequence file is not of the exact FASTA format, please check your sequence file\n")
                            WriteFile(self.pathDict['process_log_name'],self.pathDict['process_log_content'])
                            new_seq_file.close() 
                            file_seq.close()
                            sys.exit(1)
                        elif aline[0] == ">":
                            comment_lines.append(aline)
                            if len(t_seq) > 15:
                                seqs.append(t_seq)
                                line_seqs.append(t_seq_line)
                                n_seq = n_seq + 1   
                            elif t_seq.strip() :
                                small_frag.append(t_seq)
                            t_seq       = ""
                            t_seq_line  = ""
                        else:
                            seq_strgrp = aline.split()
                            a_new_line = ""
                            for a_seg in seq_strgrp:
                                a_new_line = a_new_line + a_seg
                            t_seq = t_seq + a_new_line
                            t_seq_line = t_seq_line + a_new_line + "\n"
                  
                # The last sequence if multiple seqences are supplied
                # or the first sequence if only one sequence 
                if len(t_seq) > 15:
                    seqs.append(t_seq)
                    line_seqs.append(t_seq_line)
                    n_seq = n_seq + 1
                
                n_small_frag = len(small_frag)
                print "You have provide %d sequences in the input sequence file" %(n_seq + n_small_frag)
                self.pathDict['process_log_content'] += \
                      "You have provide %d sequences in the input sequence file\n"%(n_seq + n_small_frag)
                if n_small_frag :
                    print "BALBES delete %d samll fragment(s) in your input sequence file"%n_small_frag
                    self.pathDict['process_log_content'] += \
                          "BALBES delete %d samll fragment(s) in your input sequence file\n"%n_small_frag
                t_seq = ""

                for i_seq in range(n_seq):
                    t_seq = len(seqs[i_seq])
                    print "number of amino acids in the sequence %d is %d " %(i_seq+1,t_seq)
                    self.pathDict['process_log_content'] += \
                      "number of amino acids in the sequence %d is %d \n" %(i_seq+1,t_seq)
                    new_seq_file.write(comment_lines[i_seq] + "\n")
                    new_seq_file.write(line_seqs[i_seq])
                    if n_seq == 1 and t_seq < 20 :
                        print "It is a small fragment (<20) that current version of BALBES can not deal with"
                        self.pathDict['process_log_content'] += \
                           "It is a small fragment (<20) that current version of BALBES can not deal with"
                        WriteFile(self.pathDict['process_log_name'],self.pathDict['process_log_content'])
                        self.pathDict['process_log_content'] = ""
                        self.idx_err = 1
                        sys.exit(1)
                WriteFile(self.pathDict['process_log_name'],self.pathDict['process_log_content'])
                self.pathDict['process_log_content'] = ""
              
                file_seq.close()
                new_seq_file.close()
                self.pathDict["infile_seq"]  = new_seq_file_name
