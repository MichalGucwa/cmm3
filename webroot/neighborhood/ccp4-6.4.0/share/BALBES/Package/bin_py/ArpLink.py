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


from UtilitiesClasses import RandomStrigGenerator
from UtilitiesClasses import RandomNumGenerator
from UtilitiesClasses import RandomtimeString
from UtilitiesClasses import getResNum

#The classes defined here is for ARP/wARP link when running standalone BALBES (CCP4 version)
class ArpJobManager:

     def __init__(self):

         self.ranstring = RandomStrigGenerator()
         self.rannumber = RandomtimeString(8)
         self.email =  ""
         self.keepdata = "CONFIDENTIAL"
         self.arpSeq_name = ""

     def SetArpSeq(self,para_dict) :

         amino_acid_letts = ["A", "R", "N", "D", "C", "E", "Q", "G", "H", "I", \
                             "L", "K", "M", "F", "P", "S", "T", "W", "Y","V"]

         self.arpSeq_name = para_dict['infile_seq'].split(".")[0] + "_arp.seq"
         seq_o = open(para_dict['infile_seq'], "r")
         seq_o_lines = seq_o.readlines()
         seq_o.close()

         seq_new = open(self.arpSeq_name, "w")
         n_comm = 0
         for a_line in seq_o_lines:
             if a_line.find(">") != -1:
                 n_comm = n_comm + 1
                 if n_comm == 1:
                     seq_new.write(a_line + "\n")
                 else :
                     seq_new.write("AAAAAAAAAA")
             else:
                 a_new_line = ""
                 seq_strs = a_line.strip()
                 for i in range(len(seq_strs)):
                     if seq_strs[i] in amino_acid_letts:
                         a_new_line = a_new_line + seq_strs[i]
                 if a_new_line:       
                     seq_new.write(a_new_line)
          
         seq_new.close()        

     def SetArpEmail(self,para_dict) :
         if not para_dict :
             return None
         else:
            if glob.glob(para_dict['email']):
                emailf = open(para_dict['email'], "r")
                self.email = emailf.readline().strip()
                t_keepdata = emailf.readline().strip()
                if t_keepdata.find("Confidential") != -1 or t_keepdata.find("World") != -1:
                    self.keepdata = t_keepdata.upper()
                else :
                    self.keepdata = t_keepdata

                emailf.close()
                    

     def SetArpJobBatch(self,para_dict) :
     
         if not para_dict :
             return None
         else :
             self.SetArpEmail(para_dict)
             self.SetArpSeq(para_dict)
             self.baf_name = os.path.join(para_dict['out_root_path'] + "ArpJob.csh")
             try :
                 self.baf = open(self.baf_name, "w")
             except IOError :
                 print "can not open %s for write " % self.baf_name
                 return None 
      
             self.baf.write("#!/bin/csh -f \n")
             self.baf.write("source /data/programs/arp_warp_7.0.1/arpwarp_setup.csh\n")
             self.baf.write("set datafile = '%s' \n" %para_dict['best_sol']['mtz'])
             self.baf.write("set residues = '%s' \n"%para_dict['best_sol']['n_res'])  
             self.baf.write("set fp       = 'FP' \n")
             self.baf.write("set sigfp    = 'SIGFP' \n")
             self.baf.write("set modelin  = '%s' \n" %para_dict['best_sol']['pdb'])
             self.baf.write("set seqin    = '%s' \n" %self.arpSeq_name) 
             if para_dict['best_sol'].has_key('std_sg'):
                 self.baf.write("set sgr      = '%s' \n" %para_dict['best_sol']['std_sg'])
             else:                 
                 self.baf.write("set sgr      = '%s' \n" %para_dict['best_sol']['sg'])
             self.baf.write("set buildingcycles = '10' \n")
             self.baf.write("set resol    = '%4.2f  %4.2f' \n"
                        %(para_dict['best_sol']['resol_low'],para_dict['best_sol']['resol_high']))
             if self.email:
                 self.baf.write("set remoteemail = %s \n"%self.email)
                 self.baf.write("set keepdata = '%s' \n"%self.keepdata)
             else:
                 self.baf.write("set remoteemail = fei@ysbl.york.ac.uk \n")
                 self.baf.write("set keepdata = 'WORLD' \n")
             self.baf.write("#\n")
             self.baf.write("# Do not change the name of the par file\n")
             self.baf.write("set parfile  = '999_arp_warp.par'\n")
             self.baf.write("#\n")
             self.baf.write("set dirname = '%s'\n"%self.rannumber)
             self.baf.write("mkdir $dirname \n")
             self.baf.write("#\n")
             self.baf.write("# making ARP/wARP par file\n")
             self.baf.write("set lastlogfile = 'prepare.log'\n")
             self.baf.write("$warpbin/auto_tracing.sh datafile $datafile residues $residues ")
             self.baf.write("fp $fp sigfp $sigfp modelin $modelin seqin $seqin ")
             self.baf.write('buildingcycles $buildingcycles resol "$resol" parfile $parfile ')
             self.baf.write('remoteemail "$remoteemail" keepdata $keepdata projectName balbes > $lastlogfile \n')
             self.baf.write("set errormessage = `grep 'QUITTING' $lastlogfile | wc -l` \n")
             self.baf.write('if ( "$errormessage" ) goto exitlab \n') 
             self.baf.write("#\n")
             self.baf.write("# Place files needed into the directory \n")
             self.baf.write("set preparedir = `grep 'Creating directory' $lastlogfile | awk '{print $NF}'` \n")
             self.baf.write("set preparedirshort = $preparedir:t \n")
             self.baf.write("cat ${preparedir}/${parfile}> ${dirname}/${parfile}  \n")  
             self.baf.write("#\n")
             self.baf.write("# Do not change the name of the wilson.log \n")
             self.baf.write("cat ${preparedir}'/warp_wilson.log' > ${dirname}'/999_wilson.loggraph' \n")
             self.baf.write("cp $datafile ${dirname} \n")
             self.baf.write("cp $modelin ${dirname} \n")
             self.baf.write("cp $seqin ${dirname} \n")
             self.baf.write("#\n")
             self.baf.write("# Making the tar file\n")
             self.baf.write("tar cvf ${dirname}.tar $dirname >& /dev/null \n")
             self.baf.write("#\n")
             self.baf.write("# making a dummy file\n")
             self.baf.write("echo  %s > ${dirname}.tar.logm \n" %self.ranstring)
             self.baf.write("#\n")
             self.baf.write("curl --url http://webapps.embl-hamburg.de/upload.php --form ")  
             self.baf.write("userfile=@${dirname}.tar --verbose \n")
             self.baf.write("curl --url http://webapps.embl-hamburg.de/upload.php --form ") 
             self.baf.write("userfile=@${dirname}.tar.logm --verbose \n")
             self.baf.write("#\n")
             self.baf.write("exit \n")
             self.baf.write("#\n")
             self.baf.write("exitlab: \n")
             self.baf.write("echo ' Look at the error message in '$lastlogfile \n")
             self.baf.write("#\n")

             self.baf.close()
             os.chmod(self.baf_name,0755)

     def submitJob(self,para_dict) :


         f_link_name =  para_dict['out_root_path'] + "/Arpwarpweblink.txt"

         self.f_link  = open(f_link_name, "w")
         self.SetArpJobBatch(para_dict)
         # Temp 
         os.chdir(para_dict['out_root_path']) 
         if glob.glob(self.baf_name):
              # f_link_log_name = para_dict['new_dir'] + "Arpwarpweblink.log"
              os.system("%s "%self.baf_name)
              time.sleep(250)
              self.f_link.write("http://webapps.embl-hamburg.de/Results/%s/arp_warp.html\n"%self.ranstring)
         self.f_link.close()        
             
