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
import threading

try:
    # Python 3.0
    import queue
except ImportError:
    # Pythin 2.x
    import Queue

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

from UtilitiesClasses import getResNum
#The following two classes generate and manage multiple processes running in
#parallel in a single PC (of a multiple-core processor or multiple processors)
#One class works for multiple processes, the other works for multiple threading

class CSGMultProcess :

     def __init__(self):
         
         self.paraDict = {}

         self.allJobs  = {}

         self.bestSol  = {}
         
     def submitAllSGJobs(self, t_gParaDict, t_all_sg_obj):
         """Try two wats to generate multiple processes in parallel
            (1) continuly use subprocess
            (2) use function fork """


         self.paraDict  = t_gParaDict
         self.allSGObj  = t_all_sg_obj
         self.sgList    = t_all_sg_obj.mtzGenerator().keys()
         self.nSG       = len(self.sgList)
         if self.nSG :
             t_file = open(self.paraDict['checksginfo'], "a")
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("#%s#\n" %"You want to check possible space groups".center(91))
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("Space group in the user's mtz is %s\n" %self.allSGObj.user_sg)
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("#%s#\n" %("There are %d possible space groups"%self.nSG).center(91))
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("#%s#\n"%" These space groups and the associated MR processes are".center(91))

             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             self.allJobs   = {}
             i_count = 0
             for a_sg in self.sgList :
                 if a_sg.find("_a") != -1 :
                     continue
                 else :
                     a_sg_info = a_sg + "/results/Process_information.txt"
                     a_sg_info = "look at %s for detailed information"%a_sg_info
                     t_file.write("# %s|%s#\n" %(a_sg.ljust(9), a_sg_info.center(80)))
                     t_file.write("#-------------------------------------------------------------------------------------------#\n")
                     # test version 1 
                     self.generateOneSGJob(a_sg)
             t_file.write("\n\n")
             t_file.close() 
     
     def generateOneSGJob(self, t_sg):

         #version 1: use subprocess (multiple-core para may need to be add here to obtain efficiency
         
         new_dir = self.paraDict["out_root_path"] + "/" + t_sg
         if not glob.glob(new_dir): 
             os.mkdir(new_dir) 
         os.chdir(new_dir)

         new_log = os.path.join(new_dir, "solv_" + t_sg + ".log") 

         self.allJobs[t_sg] = {}
         cmdLine =  "%s/bin_py/balbes_core -o %s -f %s -s %s >& %s "  \
                    %(os.getenv("BALBES_ROOT"),new_dir, self.allSGObj.sg_dict[t_sg]['new_hkl'], self.paraDict["infile_seq"], new_log)  
         try :
             import subprocess
             a_child_ps = subprocess.Popen(cmdLine, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
             a_child_ps.stdin.close()
             a_child_ps.stdout.close()
         except ImportError:
             import popen2
             a_child_ps = popen2.Popen4(self.cmdLine)
             a_child_ps.tochild.close()
             a_child_ps.fromchild.close()
            
         self.allJobs[t_sg]['pid']   = a_child_ps.pid
         print "the pid of one child process generated is ", self.allJobs[t_sg]['pid']

         os.chdir(self.paraDict["out_root_path"])


     def waitAllSGJobs(self):
 
         for i in range(self.nSG):
             try :
                 a_finished_child  = os.wait()
                 a_finished_pid    = a_finished_child[0]
                 a_finished_stat   = a_finished_child[1]
                 print "a child process finished, it pid is : ", a_finished_pid 
                 for a_sg in self.allJobs.keys():
                     if self.allJobs[a_sg]['pid'] == a_finished_pid:
                         if not a_finished_stat:
                             self.getOneSGInfo(a_sg)
                             break
             except OSError:
                 print "No more child balbes processes"

             # that part is OK
             

     def generateOneSGJob2(self, t_sg):

         # version 2: use function fork (multiple-core para may need to be add here to obtain efficiencya)
         new_dir = self.paraDict["out_root_path"] + "/" + t_sg
         
         if not glob.glob(new_dir): 
             os.mkdir(new_dir) 
         os.chdir(new_dir)

         new_log = os.path.join(new_dir, "solv_" + t_sg + ".log") 
         new_pid = os.fork()

         if new_pid > 0:      
             self.allJobs[t_sg] = {}
             self.allJobs[t_sg]['pid'] = new_pid
         else :
           
             cmdLine =  "%s/bin_py/balbes_core -o %s -f %s -s %s >& %s " \
                        %(os.getenv("BALBES_ROOT"), new_dir, self.allSGObj.sg_dict[t_sg]['new_hkl'], self.paraDict["infile_seq"], new_log)
             # simple but no control to process files.
             os.system(cmdline)


     def waitAllSGJobs2(self):
 
         for i in range(self.nSG):
             a_finished_pid = os.wait()
             for a_sg in self.allJobs.keys():
                 if self.allJobs[a_sg]['pid'] == a_finished_pid:
                     self.getOneSGInfo(a_sg) 
                     break


     def getOneSGInfo(self, t_sg):
   
         t_file = open(self.paraDict['checksginfo'], "a")

         t_sg_dir = self.paraDict["out_root_path"] + "/" + t_sg  
         job_file_name = t_sg_dir + "/results/Process_information.txt"
         if os.path.isfile(job_file_name):
             job_file = open(job_file_name, "r")
             l = 0
             s = 0
             err_str = ""
             self.allJobs[t_sg]['best_sol'] = {}
             self.allJobs[t_sg]['best_sol']['n_res'] = 0
             for line in job_file.readlines():
                 if s == 1 and line.find("SOLUTION SUMMARY") == -1:
                     t_file.write(line)
                 if line.find("RESOLUTIN_MAX") != -1 :
                     line_strs = line.strip().split("|")
                     self.allJobs[t_sg]['best_sol']['resol_high'] = float(line_strs[2].strip())
                 if line.find("RESOLUTIN_MIN") != -1 :
                     line_strs = line.strip().split("|")
                     self.allJobs[t_sg]['best_sol']['resol_low'] = float(line_strs[2].strip())
                 if line.find("SPACE GROUP") != -1 :
                     line_strs = line.strip().split("|")
                     self.allJobs[t_sg]['best_sol']['sg'] = line_strs[2].strip()
                 if line.find("SOLUTION SUMMARY") != -1 :
                     s = 1
                 if line.find("ITS PDB FILE") != -1 :
                     line_strs = line.strip().split("|")
                     self.allJobs[t_sg]['best_sol']['pdb'] =  t_sg_dir + "/" + line_strs[2].strip()
                     if os.path.isfile(self.allJobs[t_sg]['best_sol']['pdb']):
                         self.allJobs[t_sg]['best_sol']['n_res'] = getResNum(self.allJobs[t_sg]['best_sol']['pdb'], err_str)
                     else :
                         err_str+= "unable to find the file %s \n"%self.allJobs[t_sg]['best_sol']['pdb']

                 if line.find("ITS MTZ FILE") != -1 :
                     line_strs = line.strip().split("|")
                     self.allJobs[t_sg]['best_sol']['mtz'] =  t_sg_dir + "/" + line_strs[2].strip()
                 if s == 1 and line.find("R_ini") != -1 :
                     line_strs = line.strip().split("|")
                     Rs     = line_strs[2].strip().split("/")
                     Rfrees = line_strs[4].strip().split("/")
                     self.allJobs[t_sg]['best_sol']['R_ini'] = float(Rs[0])
                     self.allJobs[t_sg]['best_sol']['R_fin'] = float(Rs[-1])
                     self.allJobs[t_sg]['best_sol']['Rf_ini'] = float(Rfrees[0])
                     self.allJobs[t_sg]['best_sol']['Rf_fin'] = float(Rfrees[-1])
                 if line.find("SOLUTION SUMMARY") != -1 :
                     s = 1
                     t_file.write("\nALL JOBS ON %s FINISHED, THE BEST SOLUTION IS:\n"%t_sg)
                 if line.find("no MR template structure") != -1 :
                     t_file.write("ALL JOBS ON %s FINISHED\n"%t_sg)
                     t_file.write("#-------------------------------------------------------------------------------------------#\n")
                     t_file.write("#%s#\n" %"No solution is found".center(91))
                     t_file.write("|-------------------------------------------------------------------------------------------|\n")
                     break

             if err_str :
                 self.allJobs[t_sg]['best_sol']['err_info'] = err_str
                 t_file.write(err_str +"\n")
                 s = 0

             job_file.close()
             t_file.close()

             if s==1:
                 self.allJobs[t_sg]['best_sol']['exist'] = True
             else:
                 self.allJobs[t_sg]['best_sol']['exist'] = False
             

     def finalSGSummary(self):

         t_file = open(self.paraDict['checksginfo'], "a") 
         self.bestSol = {}
         Rf_lowest = 1.0
         best_sg   = ""

         for a_sg in self.allJobs.keys():
             if self.allJobs[a_sg].has_key('best_sol') :
                 if self.allJobs[a_sg]['best_sol']['exist']:
                     if self.allJobs[a_sg]['best_sol'].has_key('Rf_fin'):
                         if self.allJobs[a_sg]['best_sol']['Rf_fin'] < Rf_lowest:
                             Rf_lowest = self.allJobs[a_sg]['best_sol']['Rf_fin']
                             self.bestSol  = self.allJobs[a_sg]['best_sol']
                     

         t_file.write("\nFINAL SOLUTION SUMMARY\n")
         if self.bestSol['exist'] :
             
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("#%s#\n" %"The best solution found is".center(91))
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("| ITS SPACE GROUP    |%s|\n" %self.bestSol['sg'].center(70))
             t_file.write("|-------------------------------------------------------------------------------------------|\n")
             t_file.write("| ITS PDB FILE       |%s|\n" %self.bestSol['pdb'].center(70))
             t_file.write("|-------------------------------------------------------------------------------------------|\n")
             t_file.write("| ITS MTZ FILE       |%s|\n" %self.bestSol['mtz'].center(70))
             t_file.write("|-------------------------------------------------------------------------------------------|\n")
             t_file.write("| R_ini/R_fin        |  %8.4f/%-8.4f  |    Rfree_ini/Rfree_fin     | %8.4f/%-8.4f |\n" \
                      %(self.bestSol['R_ini'], self.bestSol['R_fin'], self.bestSol['Rf_ini'], self.bestSol['Rf_fin']))
             t_file.write("|-------------------------------------------------------------------------------------------|\n")
          
         else :
             t_file.write("#-------------------------------------------------------------------------------------------#\n")
             t_file.write("#%s#\n" %"No solution is found".center(91))
             t_file.write("|-------------------------------------------------------------------------------------------|\n")

         t_file.close()


     def controller(self, t_gParaDict, t_all_sg_obj):

         self.submitAllSGJobs(t_gParaDict, t_all_sg_obj)
 
         self.waitAllSGJobs()

         self.finalSGSummary()

#!!! Looks because of Global Interpreter Lock problem, multithread is not as efficient as multiprocess.
#Use the class defined above, which is based on multiple process and subprocess scheme. Stop developing
#multithreading classes at the moment. The parts of multithreading classes done are in file "MultipleProc.py_ALL"

