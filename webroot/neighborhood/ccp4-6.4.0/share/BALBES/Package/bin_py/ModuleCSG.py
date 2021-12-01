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
## The date of last modification: 09/10/2007
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

#from xml.dom.ext            import StripXml
#from xml.dom.ext            import PrettyPrint
#from xml.dom.ext.reader     import PyExpat 
#from xml.parsers.expat      import ExpatError

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


# manager modules
from Managers    import CManagers

# the abstract base class to be inheritted by any class
# that wraps an executable code
from baseClasses     import CExeCode

from exeCodeClasses import CF2CIF
from exeCodeClasses import CCIF2MTZ
from exeCodeClasses import CGETMTZ
from exeCodeClasses import CSFCHECK
from exeCodeClasses import CREFMAC
from exeCodeClasses import CSolutionCheck

from exeCodeClasses import CPOINTLESS

# for model sorting
def model_cmp(mod_1, mod_2): 
    if mod_1.get_nres() >= mod_2.get_nres() :
        return -1
    else :
        return 1 


######################################################################################################

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

     def __init__( self, dict_provided, code_name = None):
          CExeCode.__init__(self, dict_provided)
          self.idx_err = 0
          self.__local_path_list = [ ]
          self.__remote_path_list = [ ]
          self.out_file = None
          self.log_name = self._path_dict["scr_path"] + "/curl.log"

          if not self._path_dict.has_key("file_type"):
             self._path_dict['file_type'] = "PDB" 
          if code_name :
             self._path_dict["code_name"] = code_name

          self.controller()

     def Get_File_RSDB(self):
          """ Function to get and process a file from RCSB """

          # test if RCSB could be connected
          HOST = "198.202.75.77"
          PORT = 21
       
          # test connection
          #try:
          #     mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
          #     if sys.version_info[0] >= 2 and  sys.version_info[1] >=  3:
          #         mySocket.settimeout(20.0)
          #     mySocket.connect((HOST, PORT) )
          # except socket.error:
          #     print "Connection to RCSB can not be established"
          #     self._path_dict['process_log_content'] += \
          #           "Connection to RCSB can not be established"
          #     WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
          #     return None 
    
          # mySocket.close()

          sub_dir = self._path_dict["code_name"][1:3]
          if self._path_dict["file_type"] == "PDB" :
               # remote_path  = "ftp://ftp.rcsb.org/pub/pdb/data/structures/all/pdb/"
               remote_path  = "ftp://ftp.wwpdb.org/pub/pdb/data/structures/divided/pdb/" + sub_dir + "/"
               file_name1 = "pdb" + self._path_dict["code_name"] + ".ent.gz"
               file_name2 = self._path_dict["scr_path"] + "/" + file_name1
               file_name3 = self._path_dict["scr_path"] + "/" + \
                            "pdb" + self._path_dict["code_name"] + ".ent"
               file_name4 = self._path_dict["scr_path"] + "/" + \
                            self._path_dict["code_name"] + ".pdb"

          elif self._path_dict["file_type"] == "ENT" :
               remote_path  = "ftp://ftp.wwpdb.org/pub/pdb/data/structures/divided/structure_factors/" + sub_dir + "/"
               file_name1 = "r" +  self._path_dict["code_name"] + "sf.ent.gz"
               file_name2 = self._path_dict["scr_path"] + "/" + file_name1
               file_name3 = self._path_dict["scr_path"] + "/"  + \
                            "r" + self._path_dict["code_name"] + "sf.ent"
               file_name4 = self._path_dict["scr_path"] + "/" + \
                            self._path_dict["code_name"] + ".ent"

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
          if self._path_dict["file_type"] == "PDB":
               if self._path_dict.has_key("sys_path") :
                   self.__local_path_list.append("/data2/fei/Database_BALBES/All_pdb/All")
                   # self.__local_path_list.append(self._path_dict["sys_path"] + "pdb_SOL/")
                   self.__local_path_list.append("/y/database/brookhaven/pdb")

                   for l_pa in self.__local_path_list:
                       if i_find :
                            break
                       else :
                            t_name = self._path_dict["code_name"] + ".pdb"
                            file_name1 = os.path.join(l_pa, t_name)
                            if glob.glob(file_name1):
                                 file_name2 = os.path.join(self._path_dict["doc_path"], 
                                              self._path_dict["code_name"] + ".pdb")
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
          #self.out_file = self.Get_File_local()
          #if not self.out_file:
          #    print "get structures of similar cell and sg from local failed, try remote sites "
          #    self._path_dict['process_log_content'] += \
          #          "get structures of similar cell and sg from local failed, try remote sites "
          #    WriteFile(self._path_dict['process_log_name'],self._path_dict['process_log_content'])
          #    self.idx_err = 1
          self.out_file = self.Get_File_RSDB()
          if not self.out_file :
              print "Get file from the remote site failed "
              self._path_dict['process_log_content']+= \
                     "Get file from the remote site failed "
                 
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
         if self.ident >= 90.00 and t_diff  < 0.02 :
             go_mode = 1
             print "#-----------------------------------------------------------#"
             print "# Alignment identity > 90 % and                             #"
             print "# space group para difference < 2.0%                        #"
             print "# go for direct refinement                                  #"
             print "#-----------------------------------------------------------#"
             self._path_dict['process_log_content'] += \
                  "#-----------------------------------------------------------#\n"
             self._path_dict['process_log_content'] += \
                  "# Alignment identity > 90% and                              #\n"
             self._path_dict['process_log_content'] += \
                  "# space group para difference < 2.0%                        #\n"
             self._path_dict['process_log_content'] += \
                  "# go for direct refinement                                  #\n"
             self._path_dict['process_log_content'] += \
                        "#-----------------------------------------------------------#\n"
         else :
             print "#-----------------------------------------------------------#"
             print "# No direct refinement                                      #"
             print "# go for automatic molecule replacement                     #"
             print "#-----------------------------------------------------------#"

             self._path_dict['process_log_content'] += \
                  "#-----------------------------------------------------------#\n"
             self._path_dict['process_log_content'] += \
                  "# No direct refinement                                      #\n"
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
                             self.idx_err = int(node.firstChild.nodeValue)
                         elif node.nodeName == "err_message":
                             # self.err_message = node.firstChild.nodeValue
                             self.err_message = "The matched structure may be a DNA or RNA\n"
                         elif node.nodeName == "ch_id":
                             self.ch_id = node.firstChild.nodeValue
                         elif node.nodeName == "naa":
                             self.n_aa = int(node.firstChild.nodeValue)
                         elif node.nodeName == "sequence":
                             if not glob.glob(self.name):
                                 self.seq_file = node.getAttribute("file_seq")
                     pdb2s_xml_reader.releaseNode(pdb2s_xml_document)
                     
                     if self.idx_err:
                         print "\nIt failed to generate a seq from %s "%self.in_file_name.strip().split("/")[-1]
                         print "%s"%self.err_message.center(45)
                         self._path_dict['process_log_content'] += \
                               "\nIt failed to generate a seq from %s\n"%self.in_file_name.strip().split("/")[-1]
                         self._path_dict['process_log_content'] += \
                               "%s\n"%self.err_message.center(45)

                     else :
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
                     

class CCellSgFinder :

    def __init__( self, path_obj, t_cell, t_sg ):

        self._path_dict = path_obj
        self.idx_err = 0
   
        self.chain_expected = 0
        self.chain_found    = 0

        self.Q_best  = 0.0
        self.Q_max   = 0.65
        self.Q_min   = 0.35
        
        self.sol_found = False      

        self.findStruct = CCheck_Cell_SG (path_obj, t_cell, t_sg)
        if self.findStruct.pdb_code:
            # Found a similar structure and take the PDB file
            get_csg_file = CGet_File(path_obj,self.findStruct.pdb_code)
            if get_csg_file.out_file:
                  # creat a sequence file from the PDB file just obtained
                  new_seq = CPDBTOSEQ(path_obj, get_csg_file.out_file)
                  if not new_seq.idx_err and glob.glob(new_seq.name) :
                      # check the alignment identity between input and newly
                      # created sequence files
                      align_2 = CAlign_DB (self._path_dict, self._path_dict['infile_seq'], new_seq.name)
                      go_ref = align_2.check_ident(self.findStruct.diff)
                      if go_ref == 1:
                            # do refinement for the PDB file
                            self.csg_model = Model()
                            self.csg_model.name_tag = "csg_"+ self._path_dict['name_root']
                            self.csg_model.set_index(0,0,0)
                            self.csg_model.refi_in_xyz = get_csg_file.out_file
                            self.delAnisou(self.csg_model.refi_in_xyz)
                            csg_get_mtz = CGETMTZ(self._path_dict)
                            self.csg_model.refi_in_hkl = csg_get_mtz.mtz_name
                            if glob.glob(self.csg_model.refi_in_xyz) and \
                                   glob.glob(self.csg_model.refi_in_hkl):
                                refinement_csg = CREFMAC(self._path_dict)
                                #refinement_csg.controller(self.csg_model,"Rigid") 
                                if glob.glob(self.csg_model.refi_in_xyz): # here is a repeat (coresponding to rigid ref now cancelled)
                                    t_r_free = 0.0
                                    t_r      = 0.0
                                    refinement_csg.controller(self.csg_model, "Direct") 
                                    # See how refmac put the word indecating reindex should be considered
                                    # Temporarily, need to put into a function block
                                    if refinement_csg.output_dict['reindex']:
                                        reindex_obj = CPOINTLESS(self._path_dict)
                                        reindex_obj.controller(self.csg_model)
                                        if glob.glob(reindex_obj.hkl_out):
                                            # refinement using the reindexed mtz
                                            self.csg_model.name_tag = "direct_refine_reindexed_"+ self._path_dict['name_root']
                                            self.csg_model.refi_in_hkl  = reindex_obj.hkl_out
                                            # use the same pdb for refinement input
                                            refinement_csg.controller(self.csg_model, "Direct") 
                                        else :
                                            print " Test: Why pointless has not produced a reindexed data"
                                            sys.exit(1)

                                    AssessQ(self.csg_model, t_r_free, t_r, self._path_dict['process_log_name'])
                                    print "the Q factor for the model is %5.4f"%self.csg_model.Q
                                    self._path_dict["process_log_content"] += \
                                         "the Q factor for the model is %5.4f\n" %self.csg_model.Q
                                   
                                # check the solution
                                if glob.glob(self.csg_model.refi_sol_xyz) :
                                    if self._path_dict.has_key("infile_sol") :
                                        # solution check
                                        csg_solcheck =  CSolutionCheck(self._path_dict)
                                        # csg_solcheck.set_keypair("in_xyz", self._path_dict["out_xyz"])
                                        csg_solcheck.controller(self.csg_model)
                                        if csg_solcheck.idx_err == 0:
                                            self.chain_expected = int(csg_solcheck.chain_expected)
                                            self.chain_found    = int(csg_solcheck.chain_found)
                                    
                                    if self.chain_found or self.csg_model.Q >= self.Q_max  :
                                            CopyFile(self.csg_model.refi_sol_xyz, self._path_dict['result_path'])
                                            CopyFile(self.csg_model.refi_sol_hkl ,self._path_dict['result_path'])
                                            self.chain_expected = 1
                                            self.chain_found    = 1 
                                            self.Q_best = self.csg_model.Q

                                            # for statitics
                                            self.csg_model.set_mr_score('50.0')       # No MR is needed
                                            self.csg_model.set_mr_score_prev('50.0')  # No MR is needed
                                            # if refinement_csg.output_dict.has_key('B_value'):

                                            # i_sfcheck_stage = 2
                                            # csg_check = CSFCHECK(self._path_dict)
                                            # csg_check.controller(i_sfcheck_stage, self.csg_model)
                                            

                                            self.csg_model.BFactors = refinement_csg.output_dict['BFactores']
                                            # self.csg_model.Occupancy = refinement_csg.output_dict['Occupancy']
                                            # for ccp4i only
                                            if self._path_dict.has_key("outfile_hkl"):
                                                CopyFile(self.csg_model.refi_sol_hkl, self._path_dict["outfile_hkl"])
                                            if self._path_dict.has_key("outfile_xyz"):
                                                CopyFile(self.csg_model.refi_sol_xyz, self._path_dict["outfile_xyz"])

                                            print "#----------------------------------------------------------#"
                                            print "#  A solution is found.                                    #"
                                            print "#----------------------------------------------------------#"

                                            sol_file_hkl = \
                                                      os.path.join(self._path_dict['result_path'],
                                                                   os.path.basename(self.csg_model.refi_sol_hkl))
                                            sol_file_xyz = \
                                                      os.path.join(self._path_dict['result_path'],
                                                                   os.path.basename(self.csg_model.refi_sol_xyz))

                                            self._path_dict["process_log_content"] += \
                                                  "\n#----------------------------------------------------------#\n"
                                            self._path_dict["process_log_content"] += \
                                                  "#  A solution is found.                                    #\n"
                                            self._path_dict["process_log_content"] += \
                                                  "#----------------------------------------------------------#\n"
                                            WriteFile(self._path_dict['process_log_name'], self._path_dict['process_log_content'])
                                            self._path_dict['process_log_content'] = " "
                                            WriteSummaryFile(self._path_dict['process_log_name'],self.csg_model)
                                            
                                    else :

                                            print "\n#----------------------------------------------------------#"
                                            print "#  Direct cell and space group match found                 #"
                                            print "#  no solution. Go to automated MR                         #"
                                            print "#----------------------------------------------------------#"

                                            self._path_dict["process_log_content"] += \
                                                  "\n#----------------------------------------------------------#\n"
                                            self._path_dict["process_log_content"] += \
                                                  "#  Direct cell and space group match found                 #\n"
                                            self._path_dict["process_log_content"] += \
                                                  "#  no solution. Go to automated MR                         #\n"
                                            self._path_dict["process_log_content"] += \
                                                  "#----------------------------------------------------------#\n"
                                            WriteFile(self._path_dict['process_log_name'], self._path_dict['process_log_content'])
                                            self._path_dict['process_log_content'] = " "
                  else :
                       print "\n#----------------------------------------------------------#"
                       print   "#  Skip Direct cell and space group match                  #"
                       print   "#  Go to automated MR                                      #"
                       print   "#----------------------------------------------------------#"

                       self._path_dict["process_log_content"] += \
                             "\n#----------------------------------------------------------#\n"
                       self._path_dict["process_log_content"] += \
                               "#  Skip Direct cell and space group match                  #\n"
                       self._path_dict["process_log_content"] += \
                               "#  Go to automated MR                                      #\n"
                       self._path_dict["process_log_content"] += \
                               "#----------------------------------------------------------#\n"
                       WriteFile(self._path_dict['process_log_name'], self._path_dict['process_log_content'])
                       self._path_dict['process_log_content'] = " "


    def delAnisou(self, in_file):
        
        temp_file = self._path_dict["scr_path"] + "/noAnisou.pdb"
        cmdline = "grep -i -v anisou  " + in_file + " > " + temp_file 
        if glob.glob(in_file) :
            os.system(cmdline)
            if glob.glob(temp_file):
                cmdline = "cp  " + temp_file + "  " + in_file
                os.system(cmdline)


       


                    






            
            




    
        





        

