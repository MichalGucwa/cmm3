import os
import string
import re
from socket import *

def CCP4I():
  return CCCP4iPy.insts[0]

class CCCP4iPy:
  months = ['Jan','Feb','Mar','Apr','May','Jun','Jul', \
            'Aug','Sep','Oct','Nov','Dec']  
  insts = []
#------------------------------------------------------------------
  def __init__(self,*argsin):
#------------------------------------------------------------------
    self.insts.append(self)
    self.directories = {}

    # Unsafe assumption - determines where to look for
    # the directories.def file

    # Following are equivalent to the system() variables
    # set in bin/UNIX/startup.tcl
    # We should get from there, but hard-wired for now.
    self.domain = 'unix'
    self.ccp4i_version = 'CCP4Interface 1.4.1'
    self.ccp4_version = "CCP4 Program Suite 6.0.0"

    # Assume we are running a script and will receive the
    # name of a def file in the input arguments
    self.run_mode = 'script'
    self.def_file = ''

    # Information about the job which comes from the
    # header of the def file
    self.taskname = ''
    self.project = ''
    self.job_id = ''

    # Log file name - and is it html
    self.log_file = ''
    self.html_log = 0
    self.html_open_tags = []
    
    #extra output files
    self.extra_output_files = []
    self.map_output_defdir = 'TEMPORARY'
    
    # Socket connection to send status to main ccp4i process
    self.remote = 0
    self.server_host = ''
    self.server_port = ''
    self.socket = ''
    
    # parse the input arguments 
    args = argsin[0]
    nargs = len(args)
    n = 1
    while n < nargs:
      if args[n] == '-r':
        n = n + 1
        self.def_file = args[n]
      n = n + 1
      
    status = self.InitialisePreferences('directories')
    status = self.ReadDefFile(self.def_file)
    if self.remote:
      status = self.Send('STATUS','REMOTE')
    else:
      status = self.Send('STATUS','RUNNING')
    #print "OpenSocket status",status

    status = self.ResolveFullFilePath()

    status = self.InitialiseLog()
    

#-------------------------------------------------------------------
  def GetScriptFile ( self):
#-------------------------------------------------------------------
    if self.taskname:
      script = os.path.join(os.environ('CCP4I_TOP'),'scripts', \
                         self.taskname + '.py')
      if os.path.exists(script):
        return script
    return ''
  
#--------------------------------------------------------------------
  def InitialisePreferences (self, taskname ) :
#-------------------------------------------------------------------   
    filename = os.path.join (os.environ['HOME'],'.CCP4', \
                  self.domain ,  taskname + '.def')
    if not os.path.exists(filename) or not os.path.isfile(filename):
      filename =os.path.join (os.environ['CCP4I_TOP'], 'etc', \
                      self.domain , taskname + '.def')
      if not os.path.exists(filename) or not os.path.isfile(filename):
        return 1

    if taskname == 'directories':
      dirtmp = {}
      RV = self.InitialiseArray ( filename , dirtmp , 'directories' )
      if RV: return RV
      self.directories = {}
      if dirtmp.has_key('LOG_DIRECTORY'): \
         self.directories['LOG_DIRECTORY'] = dirtmp['LOG_DIRECTORY']
      for ii in range(1,int(dirtmp['N_PROJECTS'])+1):
        ich = str(ii)
        if dirtmp.has_key('PROJECT_ALIAS,'+ich) and \
                            dirtmp.has_key('PROJECT_PATH,'+ich):
          self.directories[dirtmp['PROJECT_ALIAS,'+ich]] = dirtmp['PROJECT_PATH,'+ich]
      for ii in range(1,int(dirtmp['N_DEF_DIRS'])+1):
        ich = str(ii)
        if dirtmp.has_key('DEF_DIR_ALIAS,'+ich) and \
                            dirtmp.has_key('DEF_DIR_PATH,'+ich):
          self.directories[dirtmp['DEF_DIR_ALIAS,'+ich]] = dirtmp['DEF_DIR_PATH,'+ich]
    return 0

#-------------------------------------------------------------------------
  def InitialiseArray ( self, filename ='', array ='', taskname ='', **keywords):
#-------------------------------------------------------------------------
    if keywords.has_key('file_info'):
      file_info = keywords['file_info']
    else:
      file_info = {}

    #print 'InitialiseArray filename',filename
    try:
      f = open(filename)
    except:
      return 1

    text = f.readlines()
    f.close()
    
    for line in text:
      words = self.ParseLine(line)
      ll = len(words)
      if ll > 0:
        if words[0] == '#CCP4I':
          if ll == 3:
            file_info[words[1]] = words[2]
          elif ll>3:
            file_info[words[1]] = self.String(words[2:])
          #print "file_info",words[1],file_info[words[1]]
        elif ll==2:
          array[words[0]]=words[1]
          #print "array",words[0],array[words[0]]
        elif ll==3:
          array[words[0]]=words[2]
          #print "array",words[0],array[words[0]]
        else:
          print "InitialiseArray BOTHER ll",ll,words
    return 0

#------------------------------------------------------------------------
  def ParseLine(self,line):
#------------------------------------------------------------------------
    # Remove eol character and strip white space
    line = string.strip(re.sub('\n$','',line))
    nn = len(line)
    words = []

    # Look for fist word in the string - it may be a string enclosed in ""
    while nn > 0:
      mm = re.search(r'(^"(.)*")',line)
      if mm:
        pp = mm.end(0)
        words.append(line[1:pp-1])
        line = string.strip(line[pp:])
        nn = len(line)
        del mm
      else:
        ww = string.splitfields(line,' ',1)
        #print "ww",ww
        words.append(ww[0])
        if len(ww)>1:
          line = string.strip(ww[1])
          nn = len(line)
        else:
          nn = 0
    #print "words",words
    return words

#------------------------------------------------------------------------
  def String(self,words):
#------------------------------------------------------------------------
    if len(words) < 1: return ''
    str = words[0]
    for ww in words[1:]:
      str = str + ' ' + ww
    return str
      
#---------------------------------------------------------------------------
  def ReadDefFile( self, filename ):
#---------------------------------------------------------------------------
    self.input_params = {}
    self.file_info = {}
    self.InitialiseArray(filename,self.input_params,file_info=self.file_info )
    log_file = ''
    
    if self.file_info.has_key('SCRIPT'):
      words = string.split(self.file_info['SCRIPT'])
      if words[0] != 'DEF' or \
         ( self.taskname != '' and  words[1] != self.taskname):
        return 2
    if self.file_info.has_key('SERVER_HOST'):
      self.server_host = self.file_info['SERVER_HOST']
    if self.file_info.has_key('SERVER_PORT'):
      self.server_port = int(self.file_info['SERVER_PORT'])
    if self.file_info.has_key('PROJECT'):
      self.project = self.file_info['PROJECT']
    if self.file_info.has_key('LOG_FILE'):
      log_file = self.file_info['LOG_FILE']
    if self.file_info.has_key('HTML_LOG'):
      self.html_log = int(self.file_info['HTML_LOG'])
    if self.file_info.has_key('JOB_ID'):
      self.job_id = self.file_info['JOB_ID']
    if self.file_info.has_key('REMOTE'):
      self.remote = int(self.file_info['REMOTE'])
    if self.file_info.has_key('TASKNAME'):
      self.taskname = self.file_info['TASKNAME']

    if log_file and self.project:
      self.log_file = self.GetFullFileName(log_file,self.project)
    else:
      self.log_file = self.GetFullFileName('tmp.log','')
    return 0

#-----------------------------------------------------------------
  def CleanWord ( self,inp ) :
#-----------------------------------------------------------------
    n = string.find( inp , '\n') 
    if n >=0:
      ij = re.sub('^"','',string.strip(inp[0:n]))
    else:
      ij = re.sub('^"','',string.strip(inp))
    out = re.sub('"$','',ij)
    return out

#-------------------------------------------------------------------
  def OpenSocket (self):
#------------------------------------------------------------------
# open a 'send' socket
    if self.server_host == '' or self.server_port == '': return 1
    self.socket = socket(AF_INET,SOCK_STREAM)
    try:
      self.socket.connect((self.server_host,self.server_port))
    except Exception, strerror:
      print "Error in OpenSocket: %s" % strerror
      self.socket = ''
      return 1

    return 0
  
#--------------------------------------------------------------------
  def Send ( self , var, value ):
#--------------------------------------------------------------------
    if not self.socket and self.OpenSocket(): return 1

    try:
      self.socket.send("DbReceive " + self.job_id + " " \
                     + self.project +" " + var + " " + value + "\n")
    except:
      return 1

    return 0


#-----------------------------------------------------------------------
  def ResolveFullFilePath (self):
#-----------------------------------------------------------------------
    # Derive the full pathname for files
    for key in self.input_params.keys():
      if re.match('DIR_',key) and self.input_params.has_key(key[4:]):
        #print "ResolveFullFilePaths key",key
        self.input_params[key[4:]] = self.GetFullFileName \
          (self.input_params[key[4:]],self.input_params[key])
        #print "fullfilename",  self.input_params[key[4:]]

#----------------------------------------------------------------------
  def GetFullFileName ( self, filn , dir ):
#----------------------------------------------------------------------
    if not filn: return ""
    if not dir or os.path.isdir(os.path.dirname(filn)) or \
       dir == "FULL_PATH" or dir == "CURRENT" or dir == "Full path..":
      return filn
    else:
      directory = self.GetDefaultDirPath(dir)
      if directory:
        return os.path.join(directory,filn)
      else:
        return ''


#---------------------------------------------------------------------
  def GetDefaultDirPath ( self, dir='' ):
#---------------------------------------------------------------------

    # If no default directory input then assume it is current project 
    if not dir: dir = self.project

    if dir == "Full path.." or dir == "CURRENT" or dir == "FULL_PATH": 
      return os.path.abspath(os.curdir)

    if self.directories.has_key(dir):
      directory = self.directories[dir]
      #print "GetDefaultDirPath",directory
      if directory and os.path.isdir(directory) and os.path.exists(directory):
        return directory
      else:
        return ""

# If all else fails return $CCP4_SCR for the SCRATCH or TEMPORARY
    if dir == 'SCRATCH' or dir == 'TEMPORARY':
      directory = os.environ['CCP4_SCR']
      return directory
  
    return ''

#-------------------------------------------------------------------------
  def SetOutputFileRoot(self,*args):
#-------------------------------------------------------------------------
# Set root name for output files
    file = self.project + '_' + self.job_id
    dir = ''
    if args.count('-tmp')>0 or \
       (args.count('-map')>0 and self.map_output_defdir == 'TEMPORARY') :
      dir = 'TEMPORARY'
    directory =  self.GetDefaultDirPath(dir)
    if directory:
      return os.path.join(directory, file)
    else:
      return ''

#-----------------------------------------------------------------------
  def TerminateScript(self,status=0,report='',exit_on_err='1',autotest='0'):
#-----------------------------------------------------------------------
#d_sum Cleanly terminate a run script process and notify the main CCP4i proccess
#d_desc Note that status = 0 is success (c.f. Tcl version of script and ccp4 programs)

    status = int(status)
    exit_on_err = int(exit_on_err)
    autotest = int(autotest)

# Write termination status to log file
    self.WriteTerminationToLog ( status, report )

# Send signal to database handler to update database - currently database
# handler is part of main GUI but this may change

    if autotest:
      pass
      # Present implementation of autotest assumes the the run script and
      # database are run as part of same process and this is not so
      # easy to do with mixed languages
#      DbSetJobData $job_params(JOB_ID) STATUS $ret_status
#      DbSetJobData $job_params(JOB_ID) DATE [clock seconds]
    else:
      if status:
        self.Send('STATUS','FAILED')
      else:
        self.Send('STATUS','FINISHED')
       
    if not autotest  and exit_on_err: exit


#----------------------------------------------------------------------
  def AddOutputFile(self,args):
#----------------------------------------------------------------------
#d_sum Notify the main CCP4i process of additional output files
#d_desc And add the names to a list which will be reported in the footer of the log file.
#d_args args The list of arguments should be the directory alias and the file name for 1 or more files

    filelist =  ''
    for dir,file in args:
      if dir == 'MAP_DEFAULT':
        if self.map_output_defdir == 'TEMPORARY':
          dir = 'TEMPORARY'
        elif self.map_output_defdir == 'PROJECT':
          dir = self.project
      extra_output_files.append(dir)
      extra_output_files.append(file)
      filelist = filelist + ' ' + dir + ' ' + file

    # Inform database if possible
    if not self.socket and self.OpenSocket(): return 2

    try:
      self.socket.send("DbAddOutputFile " + self.job_id + " " \
                     + self.project + " " + filelist )
    except:
      return 2

    return 0



#-----------------------------------------------------------------------
  def InitialiseLog(self):
#-----------------------------------------------------------------------
    logtext = ''
    if self.html_log:
      logtext = logtext + "<!-- CCP4 HTML LOGFILE -->\n<pre>"

    logtext = logtext + self.WriteIdentifier( \
        script = 'LOG '+self.taskname, \
	PROJECT = self.project, \
	JOB_ID = self.job_id, \
	SCRATCH = os.environ['CCP4_SCR'], \
	HOSTNAME = self.GetHostname(), \
	PID = self.GetPid() )

    if self.html_log: logtext = logtext + "</pre>\n"

    return self.WriteToLog(logtext)
 
#-------------------------------------------------------------------------
  def WriteTerminationToLog(self,status=0,report=''):
#-------------------------------------------------------------------------
    status = int(status)
    report=re.sub ('\n',' ', report)

    if self.html_log: self.WriteHtmlTag('beg','pre')

    logtext = '#CCP4I TERMINATION STATUS ' + str(status) + ' ' + report + '\n' + \
              '#CCP4I TERMINATION TIME ' + self.GetDate() + '\n'
    if status:
      logtext = logtext + "#CCP4I MESSAGE Task failed\n"
    else:
      logtext = logtext + "#CCP4I MESSAGE Task completed successfully\n"
    if self.html_log: self.WriteHtmlTag('end','pre')
      

    return self.WriteToLog(logtext)
  
#-------------------------------------------------------------------------  
  def WriteFile ( self, filename, text):
#-------------------------------------------------------------------------
    try:
      f = open(filename,'a')
      f.write(text)
      f.close()
    except:
      return 1

    return 0

#-------------------------------------------------------------------------  
  def WriteToLog ( self, text):
#-------------------------------------------------------------------------
    try:
      f = open(self.log_file,'a')
      f.write(text)
      f.close()
    except:
      return 1

    return 0

#-------------------------------------------------------------------------
  def WriteHtmlTag ( self, mode, tag ):
#-------------------------------------------------------------------------
#d_sum Write an html tag to log file
#d_arg mode  beg/end  Create the opening or closing tag
#d_arg name Name of tag

# Maintain a list of currently open tags - this will
# only allow tag to to opened once and must be opened before
# it is closed
# i.e. the right things for pre but probably not for anything else!

    if self.html_open_tags.count(tag) > 0:  
      if mode != 'end': return 1
      self.html_open_tags.remove(tag)
      if tag == 'pre':
        text =    "</pre>"
    else:
      if mode != 'beg': return 1
      self.html_open_tags.append(tag)
      if tag == 'pre':
        text = "<pre>"

    self.WriteFile (self.log_file,text)
    return 0

#-------------------------------------------------------------------------
  def WriteIdentifier( self,f='',script = '',**keywords ):
#-------------------------------------------------------------------------
    # Setup the standard file header info
    #print "WriteIdentifier f",f,"script",script
    text = '#CCP4I VERSION ' + self.ccp4i_version + '\n' + \
             '#CCP4I SCRIPT ' + script + '\n' + \
             '#CCP4I DATE ' + self.GetDate() + '\n' + \
             '#CCP4I USER ' + self.GetUser() + '\n'

# Expect args to be in pairs of keyword and parameter
# if parameter is a null string then test if it is an element of
# file_info array

    for key in keywords.keys():
      param =  keywords[key]
      if param == ""  and self.file_info.count(key)>0:
        param = self.file_info[key]
      text = text + '#CCP4I ' + key + ' ' + str(param) + '\n'
    
# If f is a channel id then write text to that channel 
# If f is null string then put text in that string to return to 
#   calling procedure
    import types
    if isinstance(f,types.FileType) :
      f.write(text)
    else:
      return text

#-------------------------------------------------------------------------
  def GetDate ( self):
#-------------------------------------------------------------------------
#d_sum Return as tring containing date and time in usual ccp4i format
#d_desc which looks like  '29 Jul 2002  09:24:56'
    import time
    tt =  time.localtime(time.time())
    ret = str(tt[2]) + ' ' + self.months[tt[1]-1] + ' ' + str(tt[0]) + '  ' + \
          str(tt[3]+1) + ':' + str(tt[4]+1) + ':' + str(tt[5]+1)
    return ret
  

#-----------------------------------------------------------------------
  def GetUser ( self):
#-----------------------------------------------------------------------
    return os.environ['USER']


#----------------------------------------------------------------------
  def GetHostname(self):
#----------------------------------------------------------------------
    return os.environ['HOST']

#----------------------------------------------------------------------
  def GetPid(self):
#----------------------------------------------------------------------
    return os.getpid()
