#!/usr/bin/python
# Python script 
#
# This script will be called from the web server 
# to start balbes on the linux cluster

import os, os.path, sys
import glob, re, shutil
import math
import string
import fpformat
import time
import random
import select, fcntl, subprocess
import socket

if not os.environ.has_key("BALBES_ROOT"):
    print "balbes.setup is not sourced. Re-install BALBES and don't "
    print "forget do what setup.py reminds you to do"
    sys.exit() 

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


class CheckSG :
    
     def __init__( self, t_mtz_name, u_dir):
       
         self.symInfo_name = ""
         self.u_dir = u_dir
         if not glob.glob(self.u_dir):
             os.mkdir(self.u_dir)

         self.hkl_infile_name = ""
         self.in_file_format = ""
         if glob.glob(t_mtz_name):
             self.hkl_infile_name = t_mtz_name
             self.in_file_format  = self.hkl_infile_name.strip().split("/")[-1].split(".")[-1].strip()
     
         else :
             print "can not find the input mtz file for reading"
             sys.exit(1)
     
         self.user_sg = ""
         
         self.sg_dict = {}
         self.new_hkl_file_names = []


     def get_userSG(self):

         if self.in_file_format == "cif" or self.in_file_format == "ent":
             self.hkl_infile_name = self.cifToMtz()
             if not self.hkl_infile_name:
                 print "The input cif file can not be transfered into a mtz file "
                 print "Progarm stopped "
      
         self.user_mtz_para_name = self.u_dir + "/input_mtz.para"

         mtzdump_cmdline = "mtzdump HKLin %s << eof  > %s \n" \
                           %(self.hkl_infile_name, self.user_mtz_para_name)

	 mtzdump_cmdline = mtzdump_cmdline + "Run\n"
         mtzdump_cmdline = mtzdump_cmdline + "eof\n"
         os.system(mtzdump_cmdline)
         
         time.sleep(1)

         if glob.glob(self.user_mtz_para_name):
             user_mtz_para = open(self.user_mtz_para_name, "r")
             for line in user_mtz_para.readlines():
                 if line.find("Space group") != -1 :
                     self.user_sg = line.strip().split("=")[-1].strip().split("(")[0].strip() 
                     self.user_sg = self.user_sg[1:-1]
                     # May need to process further, see what the table is like
                     # print "Space group in the user's mtz is ", self.user_sg
                     break
             user_mtz_para.close()

         if not self.user_sg :
             print "Can't find what the space group is in the input mtz file"
             sys.exit(1)


     def alt_sg_dict(self):

         self.alt_sg_list_exe = os.getenv("BALBES_ROOT") + "/bin/alt_sg_list" 

         self.alt_sg_list_log_name = os.path.join(self.u_dir, "alt_sg_list.log")
         # creat the batch file
         self.alt_sg_list_bat_name  = os.path.join(self.u_dir, "alt_sg_list1.bat")

         try:
             alt_sg_list_bat = open(self.alt_sg_list_bat_name,"w")
         except IOError:
             print self.alt_sg_list_bat_name, " could not be opened for write"
             sys.exit(1)
         else:

             print >> alt_sg_list_bat, " %s << stop > %s " % (self.alt_sg_list_exe, self.alt_sg_list_log_name)
             print >> alt_sg_list_bat, "_DOC Y> %s " % (self.u_dir)
             print >> alt_sg_list_bat, "_PATH_SCR %s " % (self.u_dir + "/" )
             print >> alt_sg_list_bat, "_SG %s"   %self.user_sg 
             print >> alt_sg_list_bat, "_END  "
             print >> alt_sg_list_bat, "stop \n\n"

             alt_sg_list_bat.close()

          
             # TEMP, CHEANGE BACK TO THE STANDAND BALBES WAY LATER
             os.chmod(self.alt_sg_list_bat_name, 0755)

             time.sleep(1)
             os.system(self.alt_sg_list_bat_name)
                  
             self.alt_sg_list_sup = {}
             self.alt_sg_list_sup['err_level'] = 0
             self.alt_sg_list_sup['err_message'] = ""
             self.alt_sg_list_sup['num_sg'] =  0

             if glob.glob("alt_sg_list.xml"):
                 self.symInfo_name = self.u_dir + "/alt_sg_list.xml"     
                 cmdl = "mv alt_sg_list.* " + self.u_dir
                 os.system(cmdl)

             time.sleep(1)

             # get possible space group candidates from "symInfo.xml"
             try:
                 self.symInfo = open(self.symInfo_name,"r")
             except IOError:
                 print   " could not find %s for reading " % self.symInfo_name
             else :
                 # parse contents of XML file
                 try:
                     symInfo_reader   = PyExpat.Reader()
                     symInfo_document = symInfo_reader.fromStream(self.symInfo)
                     self.symInfo.close()
                 except ExpatError:
                     print "parse alt_sg_list.xml failed"
                     sys.exit(1)

                 else :
                    
                     rootElement = StripXml(symInfo_document.documentElement)
                     for node in rootElement.childNodes:
                         if node.nodeName == "err_level":
                             self.alt_sg_list_sup['err_level'] = int(node.firstChild.nodeValue)
                         elif node.nodeName == "err_message":
                             self.alt_sg_list_sup['err_message'] = node.firstChild.nodeValue
                             if self.alt_sg_list_sup['err_level'] != 0:
                                 print "Error message from alt_sg_list:"
                                 print self.alt_sg_list_sup['err_message']
                         elif node.nodeName == "n_sg" :
                             self.alt_sg_list_sup['num_sg'] = int(node.firstChild.nodeValue)
                         elif node.nodeName == "SG_name":
                             t_sg = node.firstChild.nodeValue
                             sg_strgrp = t_sg.split()
                             sg_now =""
                             for a_char in sg_strgrp:
                                 sg_now = sg_now + a_char
                             
                             if sg_now and sg_now.find("(a)") == -1:
                                 self.sg_dict[sg_now] = {}
                                 self.sg_dict[sg_now]['spacegroup'] = sg_now
                                 self.sg_dict[sg_now]['new_hkl'] = self.u_dir + "/re" + sg_now + ".mtz"
                                       

     def getANewMTZ(self, t_sg):
         """ Using REINDEX to generate a new mtz file """

         # check the rule for reindexing then run reindex
         # want to see the table first.

         new_hkl_para_name = self.u_dir + "/" + t_sg + "_mtz.para"

         reindex_cmdline = "reindex hklin %s hklout %s << eof  > %s \n" \
                           %(self.hkl_infile_name,self.sg_dict[t_sg]['new_hkl'], new_hkl_para_name)
	 reindex_cmdline += "symm %s \n" %t_sg
         reindex_cmdline += "end\n"
         reindex_cmdline += "eof\n"
         os.system(reindex_cmdline)

     def cifToMtz(self):
         """ Another (maybe better) way to handle with a cif file.
             Transfer it into a mtz file """
         
         
         t_outpath = self.u_dir + "/" 
         new_mtz_name = t_outpath + "mtz_from_cif.mtz"
         sf_cif_name  = t_outpath + "sfcheck.hkl"
         sf_cif_log   = t_outpath + "sfcheck_cif.log"
         

         # generate a new cif by sfcheck

         sfcheck_cmdline = "sfcheck -f %s -po %s -ps %s -out a > %s "\
                           %(self.hkl_infile_name, t_outpath, t_outpath, sf_cif_log )
         os.system(sfcheck_cmdline)
         
         if glob.glob(sf_cif_name): 
             ciftomtz_log_name = self.u_dir + "/" + "inputcif_to_mtz.log"

             ciftomtz_cmdline = "cif2mtz hklin %s hklout %s << eof  > %s \n" \
                               %(sf_cif_name, new_mtz_name, ciftomtz_log_name)
             ciftomtz_cmdline += "end\n"
             ciftomtz_cmdline += "eof\n"
             os.system(ciftomtz_cmdline)
         else: 
             print "sfcheck does not produce a cif file."
             sys.exit()

  
         if glob.glob(new_mtz_name):
             return new_mtz_name
         else :
             return None 

     def mtzGenerator(self):
  
         self.get_userSG()
         if self.user_sg:
             self.alt_sg_dict()
             for a_sg in self.sg_dict.keys():
                 self.getANewMTZ(a_sg)
               
         return self.sg_dict


class ClusterManager :
    
     def __init__(self):
         
         pass   

     def SetBalJobBatch(self,para_dict) :
     
         if not para_dict :
             return None
         else :
             baf_name = os.path.join(para_dict['new_dir'], para_dict['name_root']+ ".csh")
             try :
                 baf = open(baf_name, "w")
             except IOError :
                 print "can not open %s for write " % baf_name
                 return None 
      
             baf.write("#!/bin/csh\n")
             baf.write("#$ -S /bin/csh\n")
             baf.write("#$ -cwd\n")
             baf.write("#$ -o %s \n" %para_dict['new_dir'])
             baf.write("#$ -e %s \n" %para_dict['new_dir'])
             t_na = "job_" + para_dict['name_root']
             baf.write("#$ -N %s \n" % ("job_" + para_dict['name_root']))
             baf.write("source %s/balbes.setup \n"%os.getenv("BALBES_ROOT"))
             baf.write("source %s/setup-scripts/csh/ccp4.setup\n"%os.getenv("CCP4_MASTER"))
             baf.write("setenv exeBalbes %s/bin_py/balbes_cluster\n"%os.getenv("BALBES_ROOT"))
             baf.write("set in_mtz=%s \n" %para_dict['in_rsf'])
             baf.write("set in_seq=%s \n" %para_dict['in_seq'])
             t_out = para_dict['new_dir'][1:].strip()
             baf.write("set path_ro=%s \n" %t_out )
   
             if para_dict.has_key('in_sol'):
                 baf.write("set in_sol=%s \n" %para_dict['in_sol'])
                 baf.write("/usr/bin/env python $exeBalbes OUT_ROOTDIR /$path_ro HKLIN /$in_mtz SEQIN /$in_seq SOLIN /$in_sol ") 
             else :  
                 baf.write("/usr/bin/env python $exeBalbes OUT_ROOTDIR /$path_ro HKLIN $in_mtz SEQIN $in_seq\n\n")

             baf.close()

             return baf_name

     def submitOneJob(self, para_dict, a_sg = None):
      
         # submit one job to the cluster and retrieve all the process info
         batch_name = self.SetBalJobBatch(para_dict)
         job_name = batch_name.split("/")[-1].split(".")[0]
         if batch_name:
             exeCmd = "qsub " + batch_name
             # os.system(exeCmd) 
             # using a simpler mechanism, not that in balbes 
             job_out = os.popen(exeCmd, "r")
             job_info = job_out.readlines()
      
             job_out.close()

             job_id = 0
             for line in job_info:
                 if line.find("Your") != -1:
                     job_id = int(line.strip().split()[2])
      
             if job_id:
                 if a_sg:
                     # one of multiple SG Jobs
                     para_dict['job_list'][a_sg] = job_id
                 else:
                     para_dict['only_job'] = job_id

     def checkJobCompletion(self, para_dict):

        jobs_active     = []
        jobs_active_pre = []
    
        # keep para_dict['job_list'] unchange because we need it later
        if para_dict.has_key('only_job'):
            jobs_active_pre.append(para_dict['only_job'])
        else:
            for a_sg in para_dict['job_list'].keys():
                jobs_active_pre.append(para_dict['job_list'][a_sg])

        while jobs_active_pre:
       
            time.sleep(60)
            jobs_active = []
            # only for the web server at YSBL
            jobs = os.popen("/opt/sge6/bin/lx24-amd64/qstat", "r")
            # in general
            #jobs = os.popen("qstat", "r")
            i_line = 0
            for line in jobs.readlines():
                i_line = i_line + 1
                if line and i_line > 2:
                    a_job_id = int(line.strip().split()[0])
                    # cjecke if the job_id belong to the current user
                    if a_job_id in jobs_active_pre:
                        jobs_active.append(a_job_id)

            # check which job finished
            for a_job_id in jobs_active_pre:
                if not (a_job_id in jobs_active):
                    if para_dict.has_key('only_job'):
                        self.getOneJobInfo(para_dict)
                        break
                    else:
                        self.writeJobInfo(a_job_id, para_dict)              

            jobs_active_pre = []
            for a_job_id in jobs_active:
                jobs_active_pre.append(a_job_id)
            jobs.close()
  
     def getOneJobInfo(self, para_dict) :
        job_file_name = para_dict['new_dir'] + "/results/Process_information.txt"
        if glob.glob(job_file_name):
             job_file = open(job_file_name, "r")
             l = 0
             s = 0
             err_str = ""
             para_dict['best_sol'] = {}
             para_dict['best_sol']['n_res'] = 0
             for line in job_file.readlines():
                 if line.find("RESOLUTIN_MAX") != -1 :
                     line_strs = line.strip().split("|")
                     para_dict['best_sol']['resol_high'] = float(line_strs[2].strip())
                 if line.find("RESOLUTIN_MIN") != -1 :
                     line_strs = line.strip().split("|")
                     para_dict['best_sol']['resol_low'] = float(line_strs[2].strip())
                 if line.find("SPACE GROUP") != -1 :
                     line_strs = line.strip().split("|")
                     para_dict['best_sol']['sg'] = line_strs[2].strip()
                 if line.find("SOLUTION SUMMARY") != -1 :
                     s = 1
                 if line.find("ITS PDB FILE") != -1 :
                     line_strs = line.strip().split("|") 
                     para_dict['best_sol']['pdb'] =  para_dict['new_dir'] + "/" + line_strs[2].strip()
                     if glob.glob(para_dict['best_sol']['pdb']):
                         para_dict['best_sol']['n_res'] = getResNum(para_dict['best_sol']['pdb'], err_str)
                     else :
                         err_str+= "unable to find the file %s \n"%para_dict['best_sol']['pdb']
                      
                 if line.find("ITS MTZ FILE") != -1 :
                     line_strs = line.strip().split("|") 
                     para_dict['best_sol']['mtz'] =  para_dict['new_dir'] + "/" + line_strs[2].strip()
                 if s == 1 and line.find("R_ini") != -1 :
                     line_strs = line.strip().split("|") 
                     Rs     = line_strs[2].strip().split("/")
                     Rfrees = line_strs[4].strip().split("/") 
                     para_dict['best_sol']['R_ini'] = float(Rs[0])
                     para_dict['best_sol']['R_fin'] = float(Rs[-1])
                     para_dict['best_sol']['Rf_ini'] = float(Rfrees[0])
                     para_dict['best_sol']['Rf_fin'] = float(Rfrees[-1])
             job_file.close()

             if err_str :      
                f1 =open(job_file_name, "a")
                f1.write(err_str)
                f1.close()

             if s==1:
                 return para_dict['best_sol']
             else:
                 return None

     def writeJobInfo(self, a_job_id, para_dict) :
    
        t_file = open(para_dict['SGJobInfo'], "a") 
        err_str = ""
        for a_sg in para_dict['job_list'].keys():
            if a_job_id == para_dict['job_list'][a_sg]:
                job_file_name = para_dict['new_dir'] + "/" + a_sg + "/results/Process_information.txt"
                if glob.glob(job_file_name):
                    job_file = open(job_file_name, "r")
                    l = 0
                    s = 0
                    
                    para_dict['solutions'] [a_sg] = {}
                    for line in job_file.readlines():
                        if l == 1 or s == 1 :
                            t_file.write(line)
                        if line.find("RESOLUTIN_MAX") != -1 :
                            line_strs = line.strip().split("|")
                            para_dict['solutions'] [a_sg]['resol_high'] = float(line_strs[2].strip())
                        if line.find("RESOLUTIN_MIN") != -1 :
                            line_strs = line.strip().split("|")
                            para_dict['solutions'] [a_sg]['resol_low'] = float(line_strs[2].strip())
                        if s == 1:
                            line_strs = line.strip().split("|") 
                            if line.find("ITS PDB FILE") != -1 :
                                para_dict['solutions'] [a_sg]['pdb'] = a_sg + "/" + line_strs[2].strip()
                                if glob.glob(para_dict['solutions'] [a_sg]['pdb']):
                                    para_dict['solutions'] [a_sg]['n_res'] = getResNum(para_dict['solutions'][a_sg]['pdb'], err_str)
                                else :
                                    err_str+= "unable to find the file %s \n"%para_dictpara_dict['solutions'] [a_sg]['pdb']
                            if line.find("ITS MTZ FILE") != -1 :
                                para_dict['solutions'] [a_sg]['mtz'] = a_sg + "/" + line_strs[2].strip()
                            if line.find("R_ini") != -1 :
                                Rs     = line_strs[2].strip().split("/") 
                                Rfrees = line_strs[4].strip().split("/") 
                                para_dict['solutions'] [a_sg]['R_ini'] = float(Rs[0])
                                para_dict['solutions'] [a_sg]['R_fin'] = float(Rs[-1])
                                para_dict['solutions'] [a_sg]['Rf_ini'] = float(Rfrees[0])
                                para_dict['solutions'] [a_sg]['Rf_fin'] = float(Rfrees[-1])
                        if line.find("TRIED") != -1:
                            t_file.write("ALL JOBS ON %s FINISHED==SUMMARY OF THE MR MODELS TRIED\n"%a_sg)
                            l =1
                        if line.find("SOLUTION SUMMARY") != -1 :
                            s =1
                            if l !=1 :
                                t_file.write("ALL JOBS ON %s FINISHED\n"%a_sg) 
                            # pick up the solution uf exists
                        if line.find("no MR template structure") != -1 :
                            t_file.write("ALL JOBS ON %s FINISHED\n"%a_sg) 
                            t_file.write("#-------------------------------------------------------------------------------------------#\n")
                            t_file.write("#%s#\n" %"No solution is found".center(91))
                            t_file.write("|-------------------------------------------------------------------------------------------|\n")
                        if line.find("No solution is found") != -1 :
                            t_file.write("ALL JOBS ON %s FINISHED\n"%a_sg) 
                            t_file.write("#-------------------------------------------------------------------------------------------#\n")
                            t_file.write("#%s#\n" %"No solution is found".center(91))
                            t_file.write("|-------------------------------------------------------------------------------------------|\n")
                            break

                    job_file.close()

                break
        if err_str:
           t_file.write(err_str)
                                  
        t_file.write("\n\n")
        t_file.close()
                          
     def writeSummaryFile(self, para_dict) :
 
        # output the best solution from all sg solutions and make some suggestion
    
        t_file = open(para_dict['SGJobInfo'], "a")

        sol_best = {}

        Rf_lowest = 1.0
        sg_best   = ""

        for a_sg in para_dict['solutions'].keys():
            if para_dict['solutions'][a_sg].has_key('Rf_fin'):
                if para_dict['solutions'][a_sg]['Rf_fin'] < Rf_lowest:
                    Rf_lowest = para_dict['solutions'][a_sg]['Rf_fin']
                    sol_best  = para_dict['solutions'] [a_sg]
                    sol_best['sg'] = a_sg

        t_file.write("\nFINAL SOLUTION SUMMARY\n")
        if sol_best.has_key('sg') :
            t_file.write("#-------------------------------------------------------------------------------------------#\n")
            t_file.write("#%s#\n" %"The best solution found is".center(91))
            t_file.write("#-------------------------------------------------------------------------------------------#\n")
            t_file.write("| ITS SPACE GROUP    |%s|\n" %sol_best['sg'].center(70))
            t_file.write("|-------------------------------------------------------------------------------------------|\n")
            t_file.write("| ITS PDB FILE       |%s|\n" %sol_best['pdb'].center(70))
            t_file.write("|-------------------------------------------------------------------------------------------|\n")
            t_file.write("| ITS MTZ FILE       |%s|\n" %sol_best['mtz'].center(70))
            t_file.write("|-------------------------------------------------------------------------------------------|\n")
            t_file.write("| R_ini/R_fin        |  %8.4f/%-8.4f  |    Rfree_ini/Rfree_fin     | %8.4f/%-8.4f |\n" \
                     %(sol_best['R_ini'], sol_best['R_fin'], sol_best['Rf_ini'], sol_best['Rf_fin']))
            t_file.write("|-------------------------------------------------------------------------------------------|\n")
            t_file.close()
            return sol_best
        else :
            t_file.write("#-------------------------------------------------------------------------------------------#\n")
            t_file.write("#%s#\n" %"No solution is found".center(91))
            t_file.write("|-------------------------------------------------------------------------------------------|\n")
            return None

