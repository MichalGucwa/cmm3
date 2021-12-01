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
## The date of last modification: 29/03/2007
#  Report any problem to fei@ysbl.york.ac.uk
import os
import sys
import glob
import re
import math
import string
import shutil
import time
import random

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
from StructHierachy import Model
from StructHierachy import Structure
from StructHierachy import Sequence
from StructHierachy import Assembly
from StructHierachy import SF_info
from StructHierachy import BOStruc

# the abstract base class to be inheritted by any class
# that wraps an executable code
                                                                                                
###################################################
class CPathDict(dict):
    
    """ A class that manages input, output, and executable pathes, etc, inheritted
         from the build-in datatype 'dict'  """
    
    def __init__( self, t_argvs):
      
        self['user']        = os.environ['USER'] 
        self['cur_path']    = os.getcwd()
        self['pid']         = str(os.getpid())
        # use local disk at the node for 
        # (1) scratch dir (molrep, refmac both write frequently to scratch)
        # (2) maybe database searching and MR template model building (that needs local database) ? 
        try:
            self['local']            = os.environ['CCP4_SCR']
        except:
            try:
                self['local']            = os.environ['TMPDIR']
            except:
                self['local']            = '/tmp'
        self['local_pdb_path']   = "/data2/fei/Database_BALBES/All_pdb/All"
       
        self['start_time'] = time.ctime(time.time() )

        # system path should be put into environmment varibles when installing system
        self.setSystem()
 
        # Match all key words entered by the user
        keyWordList = ["OUT_ROOTDIR", "NAME_ROOT", "HKLIN", "SEQIN", "HKLOUT", "XYZOUT", "SOLIN"]
        i_argv = 0
        for a_argv in  t_argvs :
            if a_argv[0] == "-" or a_argv in keyWordList :
                self.matchKW(a_argv, t_argvs, len(t_argvs), i_argv)
            i_argv = i_argv + 1
        
        # Check if all required pathes have been set, if not, set them to default
 
        if not self.has_key("out_root_path"):
            self['out_root_path'] = os.path.join(self['cur_path'], "output_"+ self['user'])
            if not glob.glob(self['out_root_path']):
                os.mkdir(self['out_root_path'])
        tmp = self['out_root_path'].strip().split("/")
        local_name_root = tmp[-2] + "_" + tmp[-1]
        print local_name_root
        self['loc_root_path'] = os.path.join(self['local'], local_name_root)
        if not glob.glob(self['loc_root_path']):
            os.mkdir(self['loc_root_path'])
       
        # The subdirctionary under root_output path 
        # 1 scratch path (in cluster version the scratch path on a local disk)
        self.setSubpath('scr_path', 'out_root_path', 'scratch')

        # 2 results path
        self.setSubpath('result_path', 'out_root_path', 'results')

        # 3 the path that stores doc and log files
        self.setSubpath('doc_path', 'out_root_path', 'process_details')

        # 4 the path that stores template MR models
        self.setSubpath('ser_path', 'out_root_path', 'template_models')

        # 5 the path that stores xml files
        self.setSubpath('xml_path', 'out_root_path', 'xml' )

        # 6 the path that stores template solution 
        self.setSubpath('tem_path', 'doc_path', 'template_solutions')

        # MR search model
        if self.has_key('ccp4i_root'):
            self['mr_search_mod']  = self['ccp4i_root'] + "_MR_SEARCH_MOD.pdb"
       
        # Get rid of all white space and print all key words and the related values
        i_done =0 
        for a_key in self.keys():
            self[a_key] = self[a_key].rstrip()
            self[a_key] = self[a_key].lstrip()
            if a_key in ["infile_seq", "infile_pdb", "infile_mtz"] \
               and i_done == 0:
                self['name_root'] = self[a_key].split("/")[-1].split(".")[0]
                i_done = 1

        # log file and brief summary for the whole process 
        self['process_log_name'] = os.path.join(self['result_path'],"Process_information.txt") 
        self['process_log_content'] = "" 
        self['process_sum_name'] = os.path.join(self['result_path'],"Summary.txt") 

        print "BALBES Version is %s " % self['version']
        print "JOB STARTS  AT ", self['start_time']       
        # print "Output path is %s " % self['out_root_path'] 

     
        self['process_log_content'] += ("BALBES Version is %s \n" % self['version'])
        self['process_log_content'] += ("JOB FOR STARTS  AT %s \n" %self['start_time'])
        # self['process_log_content'] += ("Output directory is %s \n" % self['out_root_path'])

                 #-----------------------------------------------------------#
        print "\n#############################################################"
        print "| %s |" %"Please cite the following paper in any publication".ljust(57) 
        print "| %s |" %"arising from use of BALBES:".ljust(57)
        print "| %s |" %"F.Long, A.Vagin, P.Young and G.N.Murshudov".ljust(57)
        print "| %s |" %"\"BALBES: a Molecular Replacement Pipeline\" ".ljust(57) 
        print "| %s |"%"Acta Cryst. D64 125-132(2008)".ljust(57)       
        print "#############################################################"

        self['process_log_content'] +=("\n#############################################################\n")
        self['process_log_content'] +=("| %s |\n" %"Please cite the following paper in any publication".ljust(57))
        self['process_log_content'] +=("| %s |\n" %"arising from use of BALBES:".ljust(57))
        self['process_log_content'] +=("| %s |\n" %"F.Long, A.Vagin, P.Young and G.N.Murshudov".ljust(57))
        self['process_log_content'] +=("| %s |\n" %"\"BALBES: a Molecular Replacement Pipeline\" ".ljust(57))
        self['process_log_content'] +=("| %s |\n"%"Acta Cryst. D64 125-132(2008)".ljust(57))
        self['process_log_content'] +=("#############################################################\n")

        try:
            file_log = open(self['process_log_name'], "w")
        except IOError :
            print "can not open file  %s for writing" %file_log
            sys.exit(1)
        
        file_log.write(self['process_log_content'])
        file_log.close()
        self['process_log_content'] = ""

        # solution validation 
        self['chain_expected'] = 0
        self['chain_found']   = 0
        # solution checke, internal usage
        self['best_model'] =  Model()


    def setSystem( self ):
        # set up the system path
        if os.environ.has_key("BALBES_ROOT"): 
            self['sys_path'] = os.getenv("BALBES_ROOT")
        else:
            print "WARN: You have not setup the key environment variable, BALBES_ROOT ." 
            print "execute the following command line depending on the shell you use, "
            print "under csh or tcsh, execute 'setenv BALBES_ROOT (Dir)/BALBES_0.0.1', "
            print "under bash, execute 'export BALBES_ROOT=(Dir)/BALBES_0.0.1', "
            print "where (Dir) is the directory you put BALBES_0.0.1 "
            print "We strongly suggest that you write the above command line into "
            print "your .cshrc(or .tcshrc), or .bashrc file. "
            sys.exit()

        self['seqDB_path']    = os.path.join(self['sys_path'], "seq_DB")
        self['pdbDB_path']    = os.path.join(self['sys_path'], "pdb_DB")
        self['list_path']     = os.path.join(self['sys_path'], "list")
        self['data_path']     = os.path.join(self['sys_path'], "data")
        self['loc_sys_path']  = self['local'] 
        

        # version info about BALBES
        v_file_name = os.path.join(self['list_path'], "version.txt")
        if glob.glob(v_file_name):
            v_file = open(v_file_name, "r")
            self['version'] = v_file.readline().strip()
        else :
            self['version'] = "unknown"

        # CCP4 related
        if os.environ.has_key('CCP4'):
            self['ccp4'] = os.getenv("CCP4") 
            self['bin_path'] = os.path.join(self['ccp4'], "bin")
            self['lig_path'] = os.path.join(self['ccp4'], "lib", "data", "monomers")
        else :
            raise RuntimeError, "You need to install 'ccp4' suite first"
        
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

        messege1 = "You enter key word %s, but forget entering the associated file or path " %t_word
        messege2 = "You enter key word %s, but the associated file does not exist!" %t_word
        messege3 = "Wrong key word %s !" %t_word

        # output path
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
               self[t_key] =  t_argvs[t_argv+1]
           elif t_key == "infile_sol" :
               self[t_key] = os.path.join(self['local_pdb_path'], t_argvs[t_argv+1])
               print self[t_key]
           else :
               self[t_key] = os.path.join(self['cur_path'], t_argvs[t_argv+1])

           # check all input file and dir
           if not glob.glob(self[t_key]) and not t_key in ["outfile_xyz", "outfile_hkl", "ccp4i_root"]:
               if t_key == "out_root_path":
                   os.mkdir(self['out_root_path'])
               else:
                   print messege2
                   sys.exit()

    def setSubpath( self, t_key, t_parent, t_tag ):
        
        self[t_key] = os.path.join(self[t_parent], t_tag)
        if not glob.glob(self[t_key]):
            os.mkdir(self[t_key])

def CMDHelp():
    print "BALBES USAGE    "
    print "1: To run BALBES for molecular replacement and refinement: "
    print "   balbes -o your_output_directory -f your_sf_file(cif or mtz) -s your_sequence (FASTA format)"
    print "   e.g  balbes -o job_xxxxx -f abcdef.mtz -s my_seq.seq \n"
    print "2: To run BALBES for molecular replacement and refinement using your own model PDB: "
    print "   balbes -o your_output_dir -f your_sf_file(cif or mtz) -m your_own_pdb (optional : -s your_sequence)"
    print "   e.g.  balbes -o my_job_x -f xxxx.mtz -m xx.pdb (optional : -s xx.seq)\n"
    print "3: To run BALBES for molecular replacement and refinement using your own database consisting of " 
    print "a group of pdb files:  "
    print "   balbes -o your_output_dir -f your_sf_file -l your_own_database -s your_sequence"
    print "   e.g.  balbes -o a_job -f a_sf.mtz -l myOwnDb/ -s a_seq.seq   \n"
    print "4: To run BALBES for search models only:  "
    print "   balbes -o your_output_dirctory -s your_sequence_file (FASTA format)"
    print "   e.g.  balbes -o Mod_aaaaaa  -s aaaaaaa.seq \n"
 
def MoveFile(file1_ini, file_fin):
    """ make a check before mv a file to a file or directory"""

    if glob.glob(file1_ini):
        execmd = "mv " + file1_ini  + "  " + file_fin
        os.system(execmd)
        return file_fin

def CopyFile(file1_ini, file_fin):
    """ make a check before cp a file to a file or directory"""

    if not glob.glob(file1_ini):
        return None
    else:
        execmd = "cp " + file1_ini  + "  " + file_fin
        os.system(execmd)
        return file_fin


def WriteFile(file_name, line_grp) :
    """ write output to a file"""

    try:
        file_out = open(file_name, "a")
    except IOError :
        print "can not open file  %s for writing" %file_name
        sys.exit(1)
    else :
        file_out.write(line_grp)
        file_out.close()
        line_grp = ""

def ShowNameConv(file_name):
    try:
        file_out = open(file_name, "a")
    except IOError :
        print "can not open file  %s for writing" %file_name
        sys.exit(1)
    else:
        print "\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        print "|------------------------------------------------------------------------------------|"
        print "|            Name convention for models during BALBES session                        |"
        print "|                                                                                    |"
        print "|------------------------------------------------------------------------------------|"
        print "In the follow sessions, BALBES will find template models for MR and then try to solve them."
        print "Here is the name convention used for these template and solution models:"
        print "(1) if the results from model searching show "
        print "|-------------|----------------------------------------------------------------------|"
        print "|    Name     |                     ASSEM__2(2a74A+2a74B+2a74C)                      |"
        print "|-------------|----------------------------------------------------------------------|"
        print "| NO. of MODEL|                                  1                                   |"
        print "|-------------|----------------------------------------------------------------------|"
        print "| Model | Seq used | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   1   |  1,2,3,  |    0.54    |   1109   |   Trimer  |    No   |         1         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "The name-tag for this model and the solution associated with it will contain: as2m1"
        print "and (a) this is a complex of models                                                "
        print "    (b) it contains input sequences 1, 2, 3                                        "
        print "    (c) it orignates from PDB 2a74                                                 "
        print "    (d) it is a trimer                                                             " 
        print "(2) if the results from model searching show "
        print "For the structure 2 in sequence 1 "
        print "|-------------|----------------------------------------------------------------------|"
        print "| PDB_CODE    |                                2qkiD                                 |"
        print "|-------------|----------------------------------------------------------------------|"
        print "| NO. of MODEL|                                  6                                   |"
        print "|-------------|----------------------------------------------------------------------|"
        print "| Model | Chain ID | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   1   |    D     | 0.513(ENS) |   600    |  Monomer  |    No   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   2   |    D     | 0.513(ENS) |    92    |  Monomer  |   Yes   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   3   |    D     |   0.513    |    86    |  Monomer  |   Yes   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   4   |    D     | 0.513(ENS) |   115    |  Monomer  |   Yes   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   5   |    D     | 0.513(ENS) |    95    |  Monomer  |   Yes   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "|   6   |    D     | 0.513(ENS) |   122    |  Monomer  |   Yes   |         2         |"
        print "|-------|----------|------------|----------|-----------|---------|-------------------|"
        print "The name-tag for these 6 models and their solutions will contain (in turn):"
        print "sq1st2m1, sq1st2m2, sq1st2m3, sq1st2m4, sq1st2m5, sq1st2m6"
        print "where (a) sq1st2m2, sq1st2m3, sq1st2m4, sq1st2m5, sq1st2m6 are domains,"
        print "      (b) (ENS) means the model coordinate file contains an ensemble of models"
        print "(3) if during the sessions, you see the name-tag of a model contains "
        print "      sq1st2m2_sq3st1m4_sq2st3m1                                   "
        print "it means this model is built during the MR sessions from solving and then fixing, in turn,"
        print "      (a) sequence 1 structure(PDB) 2 model 2 "
        print "      (b) sequence 3 structure(PDB) 1 model 4 "
        print "      (c) sequence 2 structure(PDB) 3 model 1 "  
        print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
        file_out.write("\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
        file_out.write("|------------------------------------------------------------------------------------|\n")
        file_out.write("|            Name convention for models during BALBES session                        |\n")
        file_out.write("|                                                                                    |\n")
        file_out.write("|------------------------------------------------------------------------------------|\n")
        file_out.write("In the follow sessions, BALBES will find template models for MR and then try to solve them.\n")
        file_out.write("Here is the name convention used for these template and solution models:\n")
        file_out.write("(1) if the results from model searching show \n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("|    Name     |                     ASSEM__2(2a74A+2a74B+2a74C)                      |\n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("| NO. of MODEL|                                  1                                   |\n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("| Model | Seq used | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   1   |  1,2,3,  |    0.54    |   1109   |   Trimer  |    No   |         1         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("The name-tag for this model and the solution associated with it will contain: as2m1\n")
        file_out.write("and (a) this is a complex of models                                                \n")
        file_out.write("    (b) it contains input sequences 1, 2, 3                                        \n")
        file_out.write("    (c) it orignates from PDB 2a74                                                 \n")
        file_out.write("    (d) it is a trimer                                                             \n") 
        file_out.write("(2) if the results from model searching show \n")
        file_out.write("For the structure 2 in sequence 1 \n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("| PDB_CODE    |                                2qkiD                                 |\n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("| NO. of MODEL|                                  6                                   |\n")
        file_out.write("|-------------|----------------------------------------------------------------------|\n")
        file_out.write("| Model | Chain ID | Similarity | Residues | Multimer? | Domain? | Monomers(expected)|\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   1   |    D     | 0.513(ENS) |   600    |  Monomer  |    No   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   2   |    D     | 0.513(ENS) |    92    |  Monomer  |   Yes   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   3   |    D     |   0.513    |    86    |  Monomer  |   Yes   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   4   |    D     | 0.513(ENS) |   115    |  Monomer  |   Yes   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   5   |    D     | 0.513(ENS) |    95    |  Monomer  |   Yes   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("|   6   |    D     | 0.513(ENS) |   122    |  Monomer  |   Yes   |         2         |\n")
        file_out.write("|-------|----------|------------|----------|-----------|---------|-------------------|\n")
        file_out.write("The name-tag for these 6 models and their solutions will contain (in turn):\n")
        file_out.write("sq1st2m1, sq1st2m2, sq1st2m3, sq1st2m4, sq1st2m5, sq1st2m6\n")
        file_out.write("where (a) sq1st2m2, sq1st2m3, sq1st2m4, sq1st2m5, sq1st2m6 are domains,\n")
        file_out.write("      (b) (ENS) means the model coordinate file contains an ensemble of models\n")
        file_out.write("(3) if during the sessions, you see the name-tag of a model contains \n")
        file_out.write("      sq1st2m2_sq3st1m4_sq2st3m1                                   \n")
        file_out.write("it means this model is built during the MR sessions from solving and then fixing, in turn,\n")
        file_out.write("      (a) sequence 1 structure(PDB) 2 model 2 \n")
        file_out.write("      (b) sequence 3 structure(PDB) 1 model 4 \n")
        file_out.write("      (c) sequence 2 structure(PDB) 3 model 1 \n")
        file_out.write("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n")
   
def WriteSummaryFile(file_name, t_model, models_processed = None) :
    try:
        file_out = open(file_name, "a")
    except IOError :
        print "can not open file  %s for writing" %file_name
        sys.exit(1)
    else :
        if models_processed:
            # Put a summary of models processed here
            print "\nALL JOBS FINISHED==SUMMARY OF THE MR MODELS TRIED "
            print "|-------------------------------------------------------------------------------------------|"
            print "|    MR Model      | Search    | Simil | Multimer? | Domain? |    Monomers    |  R/R_free   |"
            print "|                  | Model PDB |       |           |         | expected/found |             |"
            print "|------------------|-----------|-------|-----------|---------|----------------|-------------|"
            file_out.write("\nALL JOBS FINISHED==SUMMARY OF THE MR MODELS TRIED\n")
            file_out.write("|-------------------------------------------------------------------------------------------|\n")
            file_out.write("|    MR Model      | Search    | Simil | Multimer? | Domain? |    Monomers    |  R/R_free   |\n")
            file_out.write("|                  | Model PDB |       |           |         | expected/found |             |\n")
            file_out.write("|------------------|-----------|-------|-----------|---------|--------------- |-------------|\n")

            if models_processed.has_key("ASSEM"):
                for a_model in models_processed['ASSEM'] :
                    CopyFile(a_model.refi_sol_xyz, a_model.mod_dir)
                    CopyFile(a_model.refi_sol_hkl, a_model.mod_dir)
                    if a_model.nmr_enable:
                        CopyFile(a_model.mr_in_xyz_nmr, a_model.mod_dir)
                    else:
                        CopyFile(a_model.mr_in_xyz, a_model.mod_dir)
                    CopyFile(a_model.mr_log, a_model.mod_dir)
                    CopyFile(a_model.ref_log, a_model.mod_dir)

                    t_i   = a_model.get_index()
                    t_idx = "ASSEM" + str(t_i[0])+"_STR" + str(t_i[1]) \
                           + "_MOD" + str(t_i[2])
                    t_nmon = str(a_model.get_nmon()) + "/"+  str(a_model.get_nmon_solution())
                    s_pdb  = a_model.s_model_pdb + a_model.get_index_chain()
                      
                    if a_model.R_fin == 1 :
                         t_rall = "N/a"
                        
                    else : 
                         t_r = str(a_model.R_fin)[0:5]
                         t_rf = str(a_model.R_free_fin)[0:5]
                         t_rall =t_r + "/" + t_rf 
                    print "|%s|%s|%s|%s|%s|%s|%s|" \
                          %(t_idx.center(18),s_pdb.center(11), \
                            str(a_model.get_similarity()).center(7), \
                            a_model.get_multimer().center(11),a_model.get_domain().center(9),\
                            t_nmon.center(16), t_rall.center(13))
                    print "|-------------------------------------------------------------------------------------------|"
                    file_out.write("|%s|%s|%s|%s|%s|%s|%s|\n" \
                          %(t_idx.center(18), s_pdb.center(11),\
                            str(a_model.get_similarity()).center(7), \
                            a_model.get_multimer().center(11),a_model.get_domain().center(9),\
                            t_nmon.center(16), t_rall.center(13)))
                    file_out.write("|-------------------------------------------------------------------------------------------|\n")
                    file_out.write("|-------------------------------------------------------------------------------|\n")

            if models_processed.has_key("SEQS"):
                for a_model in models_processed['SEQS'] :
                    CopyFile(a_model.refi_sol_xyz, a_model.mod_dir)
                    CopyFile(a_model.refi_sol_hkl, a_model.mod_dir)
                    if a_model.nmr_enable:
                        CopyFile(a_model.mr_in_xyz_nmr, a_model.mod_dir)
                    else:
                        CopyFile(a_model.mr_in_xyz, a_model.mod_dir)
                    CopyFile(a_model.mr_log, a_model.mod_dir)
                    CopyFile(a_model.ref_log, a_model.mod_dir)

                    t_i   = a_model.get_index()
                    t_idx = "SEQ" + str(t_i[0])+"_STR" + str(t_i[1]) \
                           + "_MOD" + str(t_i[2])
                    t_nmon = str(a_model.get_nmon()) + "/"+  str(a_model.get_nmon_solution())
                    s_pdb  = a_model.s_model_pdb + a_model.get_index_chain()
                    
                    if a_model.R_fin == 1 :
                         t_rall = "N/a"
                        
                    else : 
                         t_r = str(a_model.R_fin)[0:5]
                         t_rf = str(a_model.R_free_fin)[0:5]
                         t_rall =t_r + "/" + t_rf 
                    print "|%s|%s|%s|%s|%s|%s|%s|" \
                          %(t_idx.center(18), s_pdb.center(11), \
                            str(a_model.get_similarity()).center(7), \
                            a_model.get_multimer().center(11),a_model.get_domain().center(9),\
                            t_nmon.center(16), t_rall.center(13))
                    print "|-------------------------------------------------------------------------------------------|"
                    file_out.write("|%s|%s|%s|%s|%s|%s|%s|\n" \
                          %(t_idx.center(18), s_pdb.center(11), \
                            str(a_model.get_similarity()).center(7), \
                            a_model.get_multimer().center(11),a_model.get_domain().center(9),\
                            t_nmon.center(16), t_rall.center(13)))
                    file_out.write("|-------------------------------------------------------------------------------------------|\n")
        # Temporarily  
        print "\nSOLUTION SUMMARY "
        file_out.write("\nSOLUTION SUMMARY \n")
        Q_min = 0.30
        if t_model.Q > Q_min:
            qfac = "%4.3f"%t_model.Q 
            prob = ""
            if t_model.Q > 0.62:
                prob = "99.0%" 
            else:
                x  = (0.65-t_model.Q)*4
                xx = -x*x
                p  = math.exp(xx)*100
                prob = "%3.2f"%p + "%"
           
            a_line = "Its probability to be a solution is %s"%prob
            print "#-------------------------------------------------------------------------------------------#"
            print "#%s#" %"A structure is suggested by BALBES".center(91)
            print "#%s#" %a_line.center(91)
            print "#-------------------------------------------------------------------------------------------#"
            file_out.write("#-------------------------------------------------------------------------------------------#\n")
            file_out.write("#%s#\n" %"A structure is suggested by BALBES".center(91))
            file_out.write("#%s#\n" %a_line.center(91))
            file_out.write("#-------------------------------------------------------------------------------------------#\n")
            print "The solution model index is %s"%t_model.name_tag
            file_out.write("The solution model index is %s\n"%t_model.name_tag)
  
            t_str_grp = t_model.refi_sol_xyz.split("/")
            t_n_root = ""
            for a_dir in t_str_grp[:-3]:
                t_n_root += a_dir + "/"
            t_n_root += "results/"

            f_root = "refmac_final_result"
            f_pdb  = t_n_root + f_root + ".pdb"
            f_mtz  = t_n_root + f_root + ".mtz"
            MoveFile(t_model.refi_sol_xyz,f_pdb)
            MoveFile(t_model.refi_sol_hkl,f_mtz)
            MoveFile(t_model.mr_sol_xyz, t_n_root)
            MoveFile(t_model.mr_log, t_n_root)
            MoveFile(t_model.refi_log, t_n_root)

            #CopyFile(t_model.refi_sol_xyz,f_pdb)
            #CopyFile(t_model.refi_sol_hkl,f_mtz)
        
            pdb_name = "results/"+ f_root + ".pdb"
            mtz_name = "results/"+ f_root + ".mtz"

            #pdb_name = "results/"+ t_model.refi_sol_xyz.split("/")[-1]
            #mtz_name = "results/"+ t_model.refi_sol_hkl.split("/")[-1] 
            print "|-------------------------------------------------------------------------------------------|"
            print "| ITS PDB FILE       |%s|" %pdb_name.center(70)  
            print "|-------------------------------------------------------------------------------------------|"
            print "| ITS MTZ FILE       |%s|" %mtz_name.center(70)
            print "|-------------------------------------------------------------------------------------------|"
            print "| R_ini/R_fin        |  %8.4f/%-8.4f  |    Rfree_ini/Rfree_fin     | %8.4f/%-8.4f |" \
                  %(t_model.R_ini, t_model.R_fin, t_model.R_free_ini, t_model.R_free_fin)
            print "|-------------------------------------------------------------------------------------------|"
            print "| ITS Q FACTOR       |%s|" %qfac.center(70)
            print "|-------------------------------------------------------------------------------------------|"

            file_out.write("|-------------------------------------------------------------------------------------------|\n")
            file_out.write("| ITS PDB FILE       |%s|\n" %pdb_name.center(70))
            file_out.write("|-------------------------------------------------------------------------------------------|\n")
            file_out.write("| ITS MTZ FILE       |%s|\n" %mtz_name.center(70))
            file_out.write("|-------------------------------------------------------------------------------------------|\n")
            file_out.write("| R_ini/R_fin        |  %8.4f/%-8.4f  |    Rfree_ini/Rfree_fin     | %8.4f/%-8.4f |\n" \
                          %(t_model.R_ini, t_model.R_fin, t_model.R_free_ini, t_model.R_free_fin))
            file_out.write("|-------------------------------------------------------------------------------------------|\n")
            file_out.write("| ITS Q FACTOR       |%s|\n" %qfac.center(70))
            file_out.write("|-------------------------------------------------------------------------------------------|\n")

            #f t_model.mr_in_xyz.strip():
            #    ser_name = "results/" + t_model.mr_in_xyz.strip().split("/")[-1]
            #    if t_model.get_nres():
            #        ser_name = ser_name + "(Residues%s)"%str(t_model.get_nres())
            #    print "| Search Model       |%s|" %ser_name.center(70)
            #    print "|-------------------------------------------------------------------------------------------|"
            #    file_out.write("| Search Model       |%s|\n" %ser_name.center(70))
            #    file_out.write("|-------------------------------------------------------------------------------------------|\n")

        else :
            print "#-------------------------------------------------------------------------------------------#"
            print "#%s#" %"No solution is found".center(91)
            print "#-------------------------------------------------------------------------------------------#"
            file_out.write("#-------------------------------------------------------------------------------------------#\n")
            file_out.write("#%s#\n" %"No solution is found".center(91))
            file_out.write("#-------------------------------------------------------------------------------------------#\n")

        file_out.close()

        
def WriteSummaryFileHTHL(file_name, t_model) :
    pass

def OutStaticsFile(file_name, resol, in_mod) :
    """ case file for statistics """
   
    try:
        file_out = open(file_name, "w")
    except IOError :
        print "can not open file  %s for writing" %file_name
        sys.exit(1)
    else :
        lin_grp = "Resolution: %s \n" %resol
        if in_mod :
           lin_grp += "R:        %s \n" %in_mod.r 
           lin_grp += "R_free:   %s \n" %in_mod.r_free
           lin_grp += "MR_Score: %6.3f \n" %in_mod.get_mr_score()
           if in_mod.get_mr_score_prev():
               lin_grp += "MR_Score_pre: %s \n" %in_mod.get_mr_score_prev()
               lin_grp += "\n Overall Properties \n"
           if in_mod.BFactors:
               lin_grp += "Number of chains:                %d\n" %in_mod.BFactors['overall']['all'].number
               lin_grp += "B factor averaged over all:      %7.3f \n" %in_mod.BFactors['overall']['all'].average
               lin_grp += "Sigma B_overall:                 %7.3f\n" %in_mod.BFactors['overall']['all'].sigma
               lin_grp += "number of main chains:                   %d\n" %in_mod.BFactors['overall']['main'].number
               lin_grp += "B factor averaged over all main chains:  %7.3f \n" %in_mod.BFactors['overall']['main'].average
               lin_grp += "Sigma B_overallmainchains:               %7.3f\n" %in_mod.BFactors['overall']['main'].sigma
               lin_grp += "Number of side chains:                   %d\n" %in_mod.BFactors['overall']['side'].number
               lin_grp += "B factor averaged over all side chains:  %7.3f \n" %in_mod.BFactors['overall']['side'].average
               lin_grp += "Sigma B_overallsidechains:                %7.3f\n\n" %in_mod.BFactors['overall']['side'].sigma
           if in_mod.Occupancy:
               lin_grp += "Occupancy averaged over all:      %7.3f \n" %in_mod.Occupancy['overall']['all'].average
               lin_grp += "Sigma O_overall:                 %7.3f\n" %in_mod.Occupancy['overall']['all'].sigma
               lin_grp += "number of main chains:                   %d\n" %in_mod.Occupancy['overall']['main'].number
               lin_grp += "Occupancy averaged over all main chains:  %7.3f \n" %in_mod.Occupancy['overall']['main'].average
               lin_grp += "Sigma O_overallmainchains:               %7.3f\n" %in_mod.Occupancy['overall']['main'].sigma
               lin_grp += "Number of side chains:                   %d\n" %in_mod.Occupancy['overall']['side'].number
               lin_grp += "Occupancy averaged over all side chains:  %7.3f \n" %in_mod.Occupancy['overall']['side'].average
               lin_grp += "Sigma O_overallsidechains:                %7.3f\n\n" %in_mod.Occupancy['overall']['side'].sigma

           # Now information about chains
           n_chains = len(in_mod.BFactors['chains']) # in_mod.get_nchains()
           if n_chains > 1:
               lin_grp += "Properties for each chain \n"
               lin_grp += "Chain     NRES     ScoreC     Occupancy     O_sigma     B_factor      B_sigma\n"
               for a_chain in in_mod.BFactors['chains']:
                   i_f = 0
                   t_id = a_chain.get_chainID()
                   for i in range(in_mod.get_nchains()) :
                       chain_found_id = in_mod.found_chains[i].get_chainID() 
                       if t_id[0] == chain_found_id :
                           i_f = 1
                           break
                   for o_chain in in_mod.Occupancy['chains'] :
                       if t_id == o_chain.get_chainID(): 
                           break
                   if i_f == 1 :
                        lin_grp += "%s       %d        %6.3f      %6.3f      %6.3f      %6.3f      %6.3f\n" \
                                      %(chain_found_id, a_chain.b_all.number, \
                                        in_mod.found_chains[i].get_scoreC(),  o_chain.o_all.average,\
                                        o_chain.o_all.sigma, a_chain.b_all.average, a_chain.b_all.sigma)
                   else: 
                        lin_grp += "%s       %d                   %6.3f      %6.3f      %6.3f      %6.3f\n"\
                                      %(t_id,  a_chain.b_all.number,\
                                        o_chain.o_all.average, o_chain.o_all.sigma,\
                                        a_chain.b_all.average, a_chain.b_all.sigma)

               lin_grp += "\nProperties for each main chain \n"
               lin_grp += "mainChain     NRES    Occupancy     O_sigma     B_factor      B_sigma\n"
               for a_chain in in_mod.BFactors['chains']:
                   t_id = a_chain.get_chainID()
                   for o_chain in in_mod.Occupancy['chains'] :
                       if t_id == o_chain.get_chainID(): 
                           break
                   lin_grp += "%s        %d       %6.3f        %6.3f       %6.3f      %6.3f\n"\
                              %(t_id,  a_chain.b_main.number,\
                                o_chain.o_main.average, o_chain.o_main.sigma,\
                                a_chain.b_main.average, a_chain.b_main.sigma)
                        
               lin_grp += "\nOver all properties for each side chain \n"
               lin_grp += "mainChain     NRES    Occupancy     O_sigma     B_factor      B_sigma\n"
               for a_chain in in_mod.BFactors['chains']:
                   t_id = a_chain.get_chainID()
                   for o_chain in in_mod.Occupancy['chains'] :
                       if t_id == o_chain.get_chainID(): 
                           i_g = 1
                           break
                   lin_grp += "%s           %d       %6.3f      %6.3f        %6.3f      %6.3f\n"\
                              %(t_id,  a_chain.b_side.number,\
                                o_chain.o_side.average, o_chain.o_side.sigma,\
                                a_chain.b_side.average, a_chain.b_side.sigma)
        else :
             lin_grp += "No solution Model"

        file_out.write(lin_grp)
        file_out.close()  

def AssessQ(t_model, t_r_free_ini = None, t_r_ini = None, t_file_o_name = None ):

    print "\n#----------------------------------------------#"
    print "# The Model Assesment                          #"
    print "#----------------------------------------------#"
    

    if t_file_o_name :
        t_file_o = open (t_file_o_name, "a")
        t_file_o.write("\n#----------------------------------------------#\n")
        t_file_o.write("# The Model Assesment                          #\n")
        t_file_o.write("#----------------------------------------------#\n")

    weight = 0.75
    if t_r_free_ini and t_r_ini :
         # use R_ini/R_free_ini calculated in previously rounds of refinement
         r_comb_ini = (1-weight)*t_r_ini + weight*t_r_free_ini
    else :
         # use R_ini/R_free_ini in current round of refinement
         r_comb_ini = (1-weight)*t_model.R_ini + weight*t_model.R_free_ini

    r_comb_fin = (1-weight)*t_model.R_fin + weight*t_model.R_free_fin
    dr_comb = r_comb_ini - r_comb_fin
    # t_model.d_R_free = r_free_ini - t_model.R_free_fin
    if t_file_o_name :
        t_file_o.write("d_R_free = %5.4f\n"%dr_comb)

    t_model.Q = 1 - (2*r_comb_fin*r_comb_fin)/(1+dr_comb) 
    # t_model.Q = 1 - (2*t_model.R_free_fin*t_model.R_free_fin)/(1+t_model.d_R_free) 
 
    t_file_o.close()

# Function that set the details of test case "code_name"
def SetCaseDetail(code_name, case_detail_dict, pdb_sol_file_name):
    if code_name:
        case_detail_dict[code_name] = { }
        case_detail_dict[code_name] ['identity_best'] = 100.0 
        case_detail_dict[code_name]['chain_expected'] = 0.0
        case_detail_dict[code_name]['chain_found']    = 0.0
        print "The detail of  test case %s are:" % code_name
        if glob.glob(pdb_sol_file_name):
            pdb_sol_file = open(pdb_sol_file_name, "r")
            pdb_sol_content = pdb_sol_file.readlines()
            for pdb_line in pdb_sol_content:
                pdb_strings = pdb_line.split()
                n_l = len(pdb_strings)
                if  n_l != 0:
                    if pdb_strings[0] == "HEADER":
                        case_detail_dict[code_name] ['publish_date'] = pdb_strings[n_l-2]
                        print "published in %s " % case_detail_dict[code_name] ['publish_date']
                    if pdb_line.find("METHOD USED TO DETERMINE THE STRUCTURE:") !=-1:
                        if pdb_line.find("MOLECULAR REPLACEMENT") != -1:
                            case_detail_dict[code_name] ['idx_method'] = 1
                        elif pdb_line.find("SAD") != -1 :
                            case_detail_dict[code_name] ['idx_method'] = 2
                        elif pdb_line.find("MAD") != -1 :
                            case_detail_dict[code_name] ['idx_method'] = 3
                        elif pdb_line.find("SIR") != -1 or pdb_line.find("SIRAS") != -1:
                            case_detail_dict[code_name] ['idx_method'] = 4
                        elif pdb_line.find("MIR") != -1 or pdb_line.find("MIRAS") != -1:
                            case_detail_dict[code_name] ['idx_method'] = 5
                        else :
                            case_detail_dict[code_name] ['idx_method'] = 0
                        case_detail_dict[code_name] ['method'] = ' '
                        for n_str in range(8, len(pdb_strings)):
                             case_detail_dict[code_name] ['method'] = case_detail_dict[code_name] ['method']\
                                                         + pdb_strings[n_str] + " "
                        print "METHOD USED TO DETERMINE THE STRUCTURE: %s " \
                              % case_detail_dict[code_name] ['method']
                        print "INDEX OF METHOD USED TO DETERMINE THE STRUCTURE: %d " \
                              % case_detail_dict[code_name] ['idx_method']
                    if pdb_line.find("SOFTWARE USED:") !=-1:
                        case_detail_dict[code_name] ['software'] = " "
                        for n_str in range(4, len(pdb_strings)):
                             case_detail_dict[code_name] ['software'] = case_detail_dict[code_name] ['software'] \
                                                           + pdb_strings[n_str] + " "                             
                        print "SOFTWARE USED: %s " % case_detail_dict[code_name] ['software']
                    
                        
# Function that calculate the successful rate for a method"
def SetMethodRate(method_name, n_total, n_f_1, n_f_all):
    if n_total:
        p_found_one = float(n_f_1)/float(n_total)
        print "Total number of test cases solved initially by %s upto now is %d " \
                  % (method_name, n_total)
        print " in which %d test cases found at least one monomer" % n_f_1
        print " The ratio is %.3f " %  p_found_one

        p_found_all = float(n_f_all)/float(n_total)
        print " and %d test cases found all exepected monomers" % n_f_all
        print " The ratio is %.3f " %  p_found_all

# for model sorting
def ModelCmp(mod_1, mod_2):
    if mod_1.get_nres() >= mod_2.get_nres() :
        return -1
    else :
        return 1

def RandomStrigGenerator():

    table = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t", \
             "u","v","w","x","y","z","a","B", "C", "D","E","F","G","H","I","J","K","L","M","N", \
             "O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8", "9"]

    a_ranstr = ""
    for i in range(10):
        pos = random.randint(1,62)
        a_ranstr = a_ranstr + table[pos-1] 

    return a_ranstr

    
def RandomNumGenerator(nd):

    table = ["0","1","2","3","4","5","6","7","8", "9"]

    a_rnum = ""
    for i in range(nd):
        pos = random.randint(0,9)
        a_rnum = a_rnum + table[pos] 

    return a_rnum

def RandomtimeString(nd):
    
    day, month, date, cur_t, year= time.ctime().split()
    a_time= time.strptime("%s %s %s"%(date, month, year), "%d %b %Y")
    c_year  = str(a_time[0])
    c_month = str(a_time[1])
    if len(c_month) < 2:
        c_month = "0"+ c_month
    c_day   = str(a_time[2]) 

    c_hour, c_minute, c_second = cur_t.split(":")

    a_ramString = RandomNumGenerator(nd)
    
    a_ranTimeString = c_year + "_" + c_month + "_" + c_day + "_" + c_hour + "_" + c_minute + "_" + a_ramString

    return a_ranTimeString

class TmpSGCheckandStand:

    def __init__( self, path_obj):

        self.path_obj = path_obj

        self.exe_reindex = os.path.join(os.getenv("CBIN"), "reindex")
        self.exe_regroup = os.path.join(os.getenv("BALBES_ROOT"),"bin/regroup")
        self.lib_regroup = os.path.join(os.getenv("BALBES_ROOT"), "data/regroup.lib")
        self.dir_regroup = os.path.join(self.path_obj['new_dir'], "Regroup")
        if not glob.glob(self.dir_regroup):
            os.mkdir(self.dir_regroup)


    def controller( self,  t_model):

        t_strgrp = t_model['mtz'].strip().split("/")
        t_name   = t_strgrp[-1].split(".")[0]
        t_standardlized_name = os.path.join(self.dir_regroup, t_name + "_standardlized")
        self.standardlized_pdb = os.path.join(self.dir_regroup, t_name + "_standardlized.pdb")
        self.standardlized_mtz = os.path.join(self.dir_regroup, t_name + "_standardlized.mtz")

        self.re_process_log = open(os.path.join(self.dir_regroup, "process.log"),"w")

        self.regroup_log    = os.path.join(self.dir_regroup, "regroup.log")
        self.reindex_log    = os.path.join(self.dir_regroup, "reindex.log")
        print self.standardlized_pdb
        print self.standardlized_mtz

        if os.path.isfile(t_model['pdb']):
            cmdline = "cat %s | %s %s %s > %s "%(t_model['pdb'], self.exe_regroup, self.lib_regroup, self.standardlized_pdb,self.regroup_log)
            print cmdline
            os.system(cmdline)
            if os.path.isfile(t_model['mtz']) and os.path.isfile(self.regroup_log):
                tmp_mtz = os.path.join(self.dir_regroup,"tmp.mtz")
                cmdline = 'grep "^A" %s | cut -c3- | %s hklin %s hklout %s > %s ' \
                          %(self.regroup_log, self.exe_reindex, t_model['mtz'], tmp_mtz, self.reindex_log)
                os.system(cmdline)
                if os.path.isfile(tmp_mtz):
                    cmdline = 'grep "^B" %s | cut -c3- | %s hklin %s hklout %s >> %s ' \
                              %(self.regroup_log, self.exe_reindex, tmp_mtz, self.standardlized_mtz, self.reindex_log)
                    os.system(cmdline)
                else:
                    self.re_process_log.write("reindex of sym opt failed")
                    self.re_process_log.close()
                    sys.exit(1)

            else :
                self.re_process_log.write("can not find input mtz file to regroup or regroup failed")
                self.re_process_log.close()
                sys.exit(1)

        else :
            self.re_process_log.write("can not find input pdb file to regroup")
            sys.exit()

        if os.path.isfile(self.standardlized_mtz):
            t1 = open(self.regroup_log, "r")
            for line in t1.readlines():
                if line.find("symm") != -1:
                    new_sg = line.strip().split('"')[1]
                    break
            self.re_process_log.write("Before Standardlization, the solution space group is %s \n"%t_model['sg'])
            self.re_process_log.write("After Standardlization, the solution space group is %s  \n"%new_sg)
            self.re_process_log.close()
            t_model['mtz']    = self.standardlized_mtz
            t_model['pdb']    = self.standardlized_pdb
            t_model['std_sg'] = new_sg

def TemSGCheck(t_model):
    # a temp function to check if the space group is a non-standard one (sg number >= 1000 (230)
    # the current version of ARP/wARP (v7.0) can not handle with it
    sg_type = False
    all_sg_type = {}

    try:
        fsym_name = os.path.join(os.getenv("CLIB"), "data/symop.lib")
        fsym = open(fsym_name, "r")
    except IOError:
        print "can not open CCP4 symop.lib, not space group check for ARP/wARP"
        return sg_type

    else :
        for a_line in fsym.readlines():
            if a_line:
                if a_line[0] != " ":

                    strgrps = a_line.strip().split("'")[1].split()
                    ####### add a line here

                    sg_simpl = ""
                    for a_ch in strgrps:
                        sg_simpl +=a_ch
                    sg_simpl = sg_simpl.upper()
                    all_sg_type[sg_simpl] = a_line.split()[0]

        user_strgps =t_model['sg'].split()
        user_sg = ""
        for a_ch in user_strgps:
            user_sg +=a_ch
        user_sg = user_sg.upper()

        if user_sg in all_sg_type.keys():
            if int(all_sg_type[user_sg]) < 1000:
                sg_type = True

        return sg_type

def getResNum(file_xyz, f1 = None):

    a_list = ['ALA', 'LEU', 'ARG', 'LYS', 'ASN', 'MET', 'ASP', 'PHE', 'CYS', 'PRO', 
              'GLY', 'SER', 'GLN', 'THR', 'GLU', 'TRP', 'HIS', 'TYR', 'ILE', 'VAL']
    n_res = 0
    if glob.glob(file_xyz):
        file_in = open(file_xyz, "r")
        res_pre = ""
        res_aft = ""
        n_res = 0 
        n_col = 0
        # need to consider col merge in the file

        for a_line in file_in.readlines():
            strgrp = a_line.strip().split()
            if strgrp and strgrp[0].find("ATOM") != -1 :
                if not res_pre :
                    res_pre = strgrp[3] 
                    if res_pre.upper() in a_list:
                        n_res +=1
                           
                    else:
                        res_pre = ""
                else:               
                    res_aft     = strgrp[3]
                    if res_aft.upper() in a_list:
                        if res_aft != res_pre:
                            n_res += 1
                            res_pre = res_aft
        file_in.close()
            
    else :
        print "could not find %s for reading "%file_xyz
        if f1 :
            f1 = "could not find %s for reading\n"%file_xyz
  
    return n_res

      
  
