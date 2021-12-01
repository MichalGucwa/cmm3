#
#     Copyright (C) 2006 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#    
#====================================================================
# Driver for the database handler - dbccp4i.py
#
# Wanjuan Yang, Peter Briggs 2006-8
#
#====================================================================

#CCP4i_cvs_Id $Id: dbccp4i.py,v 1.15 2008/09/19 07:22:03 pjx Exp $

######################################################################

__version__ = "0.4.11"
__dbccp4i_version__ = "$Revision: 1.15 $"

#######################################################################
# Import modules that this module depends on
#######################################################################

try:
    
    import exceptions
    import sys
    import socket
    import datetime,time
    import thread
    from threading import *
    import threading
    import os
    import errno
    import xml.sax.saxutils as su
    import xml.dom.minidom
    
except exceptions.Exception,x:

    print "Database server dbccp4i failed to load required Python modules."
    print "The following exception was raised: \""+str(x)+"\""
    print "Pleae check your Python installation, or report this problem to\n"+\
          "the developers."
    sys.exit(1)

# Load the modules for dealing with def files
# Check the CCP4_TOP & DBCCP4I_TOP environment variables

CCP4I_TOP = os.environ.get("CCP4I_TOP")
if CCP4I_TOP == None:
    print "Please set CCP4I_TOP environment variable first"
    sys.exit()

DBCCP4I_TOP = os.environ.get("DBCCP4I_TOP")
if DBCCP4I_TOP == None:
    print "The DBCCP4I_TOP environment variable is not set"
    sys.exit()

try:
    import ccp4i
    import DBcommand
    import manager
    from manager import *
    def_flag = True
    
except exceptions.Exception,x:
    def_flag = False
    print str(x)
    sys.exit()
    
# load API for SQLite
try:
    import dbapi_sqlite
    sql_flag = True
    
except ImportError,x:
    # No SQLite DB support
    sql_flag = False

# Initialise the .CCP4 area
ccp4i.InitialiseDotCCP4()

class ServeClient(threading.Thread):
    """ Class that deals with a client's requests and sends responses """
    
    def __init__(self,sock,addr):
        """ initialise with client socket and address """
        threading.Thread.__init__(self)
        self._sock = sock
        self._addr = addr

        ### valid command list
        # Admin & def backend commands
        self._admin_db_command = [ 'ShutDown',
                                   'DbDisconnect',
                                   'DbRegister',
                                   'DbRequestStatus',
                                   'DbInfo',
                                   'DbSupported',
                                   'DbOpen',
                                   'DbClose']
        
        self._def_readdb_command = ['DbGetData',
                                    'DbItemExists',
                                    'DbSelectJobs',
                                    'ListJobs',
                                    'DbReturnJobs',
                                    'GetNJOB',
                                    'GetNextJobList',
                                    'GetAllFileLinks',
                                    'GetFileLinks',
                                    'DbGetListofRecords',
                                    'GetAllChildren',
                                    'GetAllParents',
                                    'GetParents',
                                    'GetChildren',
                                    'GetAllParentsChildren',
                                    'GetNotebook',
                                    'GetFiles',
                                    'ListInputFiles',
                                    'ListOutputFiles',
                                    'ProjectWriteable',
                                    'ProjectReadable',
                                    'ReacquireProject',
                                    'HasSQLdb',
                                    'GetDbItems',
                                    'SelectSubJobs',
                                    'HasSubJobs',
                                    'ListJobswithsubjobs']
        
        self._def_writedb_command = ['DbNewJob',
                                     'DbDeleteJob',
                                     'DbSetData',
                                     'Updatetime',
                                     'AddInputFile',
                                     'AddOutputFile',
                                     'AddSubJob']
        
        self._def_readdir_command = ['ListProjects',
                                     'GetProjectDir',
                                     'ListDataDirs',
                                     'GetDataDir',
                                     'GetNProjects',
                                     'GetProjectDBDir',
                                     'IsProjectDir',
                                     'IsDataDir',
                                     'GetDirectoriesData']
        
        self._def_writedir_command = ['DeleteProject',
                                      'ImportProject',
                                      'AddDataDirRef',
                                      'DeleteDataDirRef',
                                      'NewDb']

        # Commands for parallel sqlite db (i.e. in the same directory
        # as CCP4_DATABASE, store additional data for database.def,
        # also store project specific knowledge base data.
        # One client can open many parallel sqlite db at the same connection.
        # Handler opens the parallel sqlite db automatically if there is one.) 
        self._parallel_sqldb_command = ['SetJobQuality',
                                        'SetSQLdbData',
                                        'GetSQLdbData',
                                        'GetAllSQLdbData',
                                        'NewTableRecord',
                                        'DeleteTableRecord',
                                        'DeleteTableRecords',
                                        'SetTableData',
                                        'GetTableData',
                                        'GetTablePrimaryKey',
                                        'GetAllTableRecords',
                                        'GetTableRecords']

        # Commands for sqlite backend (i.e this is the central db, store
        # general knowledge base data, one client can open only one central
        # sql db at a connection)
        self._sql_newrecord_command = ['NewRecord',
                                       'NewProject',
                                       'NewJob']
        self._sql_setdata_command = [ 'SetJobData',
                                      'SetData']
        self._sql_command = ['NewDB',
                             'OpenDB',
                             'GetJobData',
                             'CloseDB',
                             'GetProjectId',
                             'GetData',
                             'GetProjectList',
                             'GetJobList',
                             'GetRowofTable']

        # valid commands
        self._validCommand = self._admin_db_command + \
                             self._def_readdb_command + \
                             self._def_writedb_command + \
                             self._def_readdir_command + \
                             self._def_writedir_command + \
                             self._sql_newrecord_command+ \
                             self._sql_setdata_command + \
                             self._sql_command + \
                             self._parallel_sqldb_command
        
        ## database and user info
        self._sqldb = None          #used to store sql database object
        
        ## client info
        self.c = Client(sock,addr)

        # store user agent
        self.useragent = ""
        
        ## lock
        threadlock = thread.allocate_lock()

    def run(self):
        """Collect socket input and process commands in a loop.

        This method implements the run method for the thread and
        is the main body of code for dealing with a client. It
        collects socket input from the client and processes it,
        then sends responses (and broadcasts) back out."""
        
        # set initial data
        data = ""
        while not en.isSet():
            try:

                # Collect input from socket and append to buffer
                data = data + self.recv(1024)
                
                if data == '':
                    # empty string, remove the client
                    ProjectManager().DelClient(self.c)
                    messager.output('Handler received empty string: lost client '+str(self._addr)+'?')
                    messager.output("Removing client from handler")
                    break

                # check if this is the whole request
                elif "\n" not in data:
                    continue
                 
                else: # check if more than one request ,then unwrap it
                    
                    messager.output('# Handler message: in connection '+str(self._addr) )
                    messager.output(' receive request: ')
                    messager.output(data)

                    # split the data buffer
                    request_list = data.split("\n")
                
                    # parse the requests in current data buffer,
                    # except for the trailing part which will form the
                    # start of the next request
                    for i in range(len(request_list)-1):
                        try:
                            doc = xml.dom.minidom.parseString(request_list[i])
                            com = doc.getElementsByTagName("command")
                            command = com[0].childNodes[0].data
                            argu = doc.getElementsByTagName("argument")
               
                            rid = doc.getElementsByTagName("request_id")            
                            if rid != []:
                                id = rid[0].childNodes[0].data
                    
                        except exceptions.Exception,e:
                            messager.output('# Handler message: in connection '+str(self._addr))
                            messager.output(' catch exception when parse XML, not well form request:')
                            messager.output(str(e))
                            status = 'ERROR'
                            result = 'not well form request'
                            response = response_wrapper(status,result,'#')
                    
                            self._sock.sendall(response)
                            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
                            continue
                 
                        # test whether is a valid command
                        if command not in self._validCommand:
                            try:
                                status = 'ERROR'
                                result = 'not valid command'
                                response = response_wrapper(status,result,id)        
                                self._sock.sendall(response)
                                messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
                            except exceptions.Exception,x:
                                messager.output('# Handler message: in connection'+ str(self._addr))
                                messager.output('message couldnot sent')
                       
                        # check if shutdown
                        elif command == "ShutDown":
                            # receive shutdown message, tell main, set flag 
                            # and exit itself directly        
                            ProjectManager().DelClient(self.c)

                            # Respond to the client that made the request
                            try:
                                result = 'Handler will shut down in 20 seconds'
                                status = 'OK' 
                                response = response_wrapper(status,result,id)
                                self._sock.sendall(response)
                                messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)

                            except exceptions.Exception,x:
                                messager.output(str(x))
                            
                            # send broadcast message to clients
                            message =  broadcast_wrapper("Handler is shutting down in 20 seconds, save your work.","","","Shutdown",self.useragent)
                            ProjectManager().broadcast_to_all(message)

                            # sleep for 20 second
                            time.sleep(20)
                            en.set()    
                            break
   
                        elif command == "DbDisconnect":
                            # receive close message, close all projects it opened,
                            # del from list, and exit directly
                            try:
                                result = True
                                status = 'OK'                   
                                response = response_wrapper(status,result,id)
                       
                                self._sock.sendall(response)
                                messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)

                            except exceptions.Exception,x:
                                messager.output(str(x))
                                
                            ProjectManager().DelClient(self.c)
                            break
                        
                        else:
                            # process different commands
                            try:
                                self.process_command(command,argu,id)

                            except exceptions.Exception,x:
                                messager.output(str(x))
                                ProjectManager().DelClient(self.c)
                                break

                    # finish process the current data, reset data to the
                    # last non-newline-terminated input
                    data = request_list[-1]
                    
            except socket.timeout:
               # timeout, check event flag
               if en.isSet():
                   ProjectManager().DelClient(self.c)
                   break
               
               else:
                  continue
               
            except exceptions.Exception,x:
                messager.output(str(x))
                ProjectManager().DelClient(self.c)
                break
        
        ## close connection and thread exit
        if self._sqldb != None:
            self._sqldb.CloseDB()
       
        self._sock.close()
        messager.output('#Handler message :'+  str(self._addr) + ' disconnected. ')             
    def recv(self,bufsiz):
        """Read data from the socket.

        This is a wrapper for the socket.recv() method, which
        traps for exceptions raised by the underlying socket
        functions and handles them appropriately.

        It takes a single bufsiz argument which is passed
        directly to the socket.recv() call."""

        while 1:
            try:
                return self._sock.recv(bufsiz)
            except socket.timeout:
                # Timeout: pass back up
                raise
            except socket.error,ex:
                # Process the socket error
                try:
                    # Attempt to get an error number
                    errnum = ex[0]
                    if errnum == errno.EINTR:
                        # Interrupted system call
                        # Continue the loop and try to get more data
                        continue
                    elif errnum == errno.EAGAIN:
                        # Instruction to "try again"
                        # Seen with Python 2.4.2 when client is backgrounded
                        # - exception is "Resource temporarily unavailable"
                        # Continue the loop and try to get more data
                        continue
                    else:
                        # Don't know what this is
                        # Ignore it and return no data
                        messager.output("In recv: untrapped socket exception: "+
                                        str(ex))
                        return ''
                except exceptions.Exception,e:
                    # Failed to get an error number
                    # Ignore this error and return no data
                    return ''
            except exceptions.Exception,e:
                # Exception from the socket read which
                # is neither timeout nor socket.error
                # Pass back up
                raise
       
    def process_command(self,command,argu,id):
        """Process a request received from a client application."""

        if command in self._admin_db_command:
            # The request is an admin request

            response = self.process_admin_db_command(command,argu,id)
            
            self._sock.sendall(response)
            messager.output('# Handler message: in connection ' + \
                            str(self._addr) + \
                            ' sent  response: ' + response)
                
        elif command == 'OpenDB':
            # Open an SQLite database
            if sql_flag == True:
                try:
                    # get parameter
                    if len(argu) < 2:
                        result = 'Arguments should be: projectname dir'
                        status = 'ERROR'
                    else:
                        projectname = argu[0].childNodes[0].data
                        dir = argu[1].childNodes[0].data
                        dbname =  os.path.join(dir,projectname)
                       
                        # call db API
                        self._sqldb = dbapi_sqlite.DB()
                        result = self._sqldb.OpenDB(projectname,dir)
                        if result == True:
                            # add to client info
                            self.c.SetDb(dbname)
                                   
                            status = 'OK'
                        else:
                            status = 'ERROR'
                               
                except exceptions.Exception,e:
                    messager.output('# Handler message: catch exception when Open SQL db:')
                    messager.output(str(e))
                    status = 'ERROR'
                    result = 'no such database: '+str(e)
            else:
                status = 'ERROR'
                result = 'no SQLite support'
            
            response = response_wrapper(status,result,id)
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
             
        elif command == 'NewDB':
            # Create a new SQLite database
            if sql_flag == True:
                try:
                    # get parameter
                    if len(argu) < 2 :
                        result = 'Arguments should be: projectname dir'
                        status = 'ERROR'
                    else:
                        projectname = argu[0].childNodes[0].data
                        dir = argu[1].childNodes[0].data
                        dbname = os.path.join(dir,projectname)
                        # call db API
                        self._sqldb = dbapi_sqlite.DB()
                        schemafile = os.path.join(DBCCP4I_TOP,"dbccp4i","schema.sql")
                        result = self._sqldb.NewDB(projectname,dir,schemafile)
                        if result == True:                           
                            # add to client info
                            self.c.SetDb(dbname)
                            
                            status = 'OK'
                        else:
                            status = 'ERROR'
                except exceptions.Exception,e:
                    messager.output('# Handler message: catch exception when Open SQL db:')
                    messager.output(str(e))
                    status = 'ERROR'
                    result = 'no such database: '+str(e)
            else:
                status = 'ERROR'
                result = 'no SQLite support'
            
            response = response_wrapper(status,result,id)                                  
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
            
        elif command in self._sql_newrecord_command:
            try:
                if self._sqldb != None:
                    return_result = DBcommand.do_sql_newrecord_command(self._sqldb,command,argu,self.useragent)
        
                    result = return_result[0]
                    status = return_result[1]
                    table = return_result[2]
                    recordid = return_result[3]
                    
                else:
                    status = 'ERROR'
                    result = 'DB not open yet'                      

            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception'+str(x)
                messager.output(str(x))
                      
            response = response_wrapper(status,result,id)
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
            if status == 'OK':
                message = broadcast_wrapper("New record in table '" + \
                                            table + "' Record id: '" + \
                                            recordid,"","","", \
                                            self.useragent)
                messager.output('# Handler message : broadcast '+message )
                clientlist = ProjectManager().GetClientlist()
                # check project associated clients, send broadcast message
                for client in clientlist:
                    if client.GetDb() ==  self.c.GetDb():
                        if client.broadcast == True:
                            client.sock.sendall(message)

        elif command in self._sql_setdata_command:
            try:
                if self._sqldb != None:
                    return_result = DBcommand.do_sql_setdata_command(self._sqldb,command,argu,self.useragent)
                    result = return_result[0]
                    status = return_result[1]
                    table = return_result[2]
                    recordid = return_result[3]
                          
                else:
                    status = 'ERROR'
                    result = 'DB not open yet'
                           
            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception'+str(x)
                messager.output(str(x))
                         
            response = response_wrapper(status,result,id)
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
                           
            if status == 'OK':
                message = broadcast_wrapper("Updated table '" + table + \
                                            "'. Set data in record id: '" + \
                                            recordid,"","","",self.useragent)
                messager.output('# Handler message : broadcast '+message )
                clientlist = ProjectManager().GetClientlist()
                # check project associated clients, send broadcast message
                for client in clientlist:
                    if client.GetDb() ==  self.c.GetDb():
                        if client.broadcast == True:
                            client.sock.sendall(message)
        
        elif command in self._sql_command:
            try:
                if self._sqldb != None:
                    response = DBcommand.do_sql_command(self._sqldb,command,argu,id,self.useragent)
                          
                else:
                    status = 'ERROR'
                    result = 'DB not open yet'
                    response = response_wrapper(status,result,id)
                            
            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception'+str(x)
                response = response_wrapper(status,result,id)
                messager.output(str(x))
                       
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)     
        
        elif command in self._def_readdir_command:
            try:
                threadlock.acquire(True)
                # check if directory stale
                if ProjectManager().directory.isstale():
                    ProjectManager().directory.refresh()
                    message = broadcast_wrapper("Directories data has been reloaded in read only mode",
                                                "",
                                                "",
                                                "DirectoriesReadonly",
                                                "dbccp4i")
                    #broadcast
                    ProjectManager().broadcast_to_all(message)
                       
                    # process command
                    response =  DBcommand.do_def_readdir_command(command,argu,id)
                else:
                    #process command
                    response =  DBcommand.do_def_readdir_command(command,argu,id)
                
            except exceptions.Exception,x:
            
                status = 'ERROR'
                result = 'catch exception'+str(x)
                response = response_wrapper(status,result,id)
                messager.output(str(x))

            threadlock.release()
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
            
        elif command in self._def_writedir_command:
            
            try:
                threadlock.acquire(True)
                # check if directory stale
                if ProjectManager().directory.isstale():
                    ProjectManager().directory.refresh()
                    message = broadcast_wrapper("Directories data has been reloaded in read only mode",
                                                "",
                                                "",
                                                "DirectoriesReadonly",
                                                "dbccp4i")
                    #broadcast
                    ProjectManager().broadcast_to_all(message)
                    result = "Directories data is read only: modification not allowed"
                    status = "ERROR"
                    response = response_wrapper(status,result,id)
                else: # up-to-date, check if writeable
                    if ProjectManager().directory.iswriteable():
                        pre_result = self.process_def_writedir_command(command,argu,id)
                        # pre_result is a list containing response and message
                        response = pre_result[0]
                        message = pre_result[1]
                        #broadcast
                        ProjectManager().broadcast_to_all(message)
                                                      
                    else:
                        result = "Directories data is read only: modification not allowed"
                        status = "ERROR"
                        response = response_wrapper(status,result,id)

                        message = broadcast_wrapper("Directories data is read only: modification not allowed","","","",self.useragent)
                        #broadcast
                        ProjectManager().broadcast_to_all(message)
                
            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception'+str(x)
                response = response_wrapper(status,result,id)
                messager.output(str(x))

            threadlock.release()
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)     

        elif command in self._parallel_sqldb_command:
            try:
                if len(argu) < 1:
                    result = 'Please specify projectname'
                    status = 'ERROR'
                    response = response_wrapper(status,result,id)
                else:
                    projectname =  argu[0].childNodes[0].data
                    
                    # define a variable to store update_message
                    update_message = ""
                    # get project object from ProjectManager
                    p = ProjectManager().GetProject(projectname,self.c)
                    if p != 'not register to the project yet' and p != 'DB not open yet':
                        if p.HasSQLdb():
                            # get sqldb object from client, pass the sqldb object to command
                            for sqldb in self.c.GetSQLdbs():
                                if sqldb.GetDBName() == projectname:
                                
                                    pre_result = DBcommand.do_parallel_sqlitedb_command(p,sqldb,command,argu,id,self.useragent)
                                    # pre_result has two parts: result & update_message
                                    response = pre_result[0]
                                    update_message = pre_result[1]
                                    break
                            else:
                                result = 'No SQL db'
                                status = 'ERROR'
                                response = response_wrapper(status,result,id)
                        else:
                            result = 'No SQL db found'
                            status = 'ERROR'
                            response = response_wrapper(status,result,id)
                
                    else: #Get db object fail 
                        result = p
                        status = 'ERROR'
                        response = response_wrapper(status,result,id)

            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception'+str(x)
                response = response_wrapper(status,result,id)
                messager.output(str(x))
                
            # send response
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
            #check whether it is a update
            if update_message != "":
                ProjectManager().broadcast(update_message,projectname)   
                
        else:
            try:
                # command either readdb or writedb
                # get the objects and check if out-of-date
                threadlock.acquire(True)
                if len(argu) < 1:
                    result = 'Please specify projectname'
                    status = 'ERROR'
                    response = response_wrapper(status,result,id)
                       
                else:
                    projectname =  argu[0].childNodes[0].data
                       
                    # define a variable to store update_message
                    update_message = ""
                           
                    p = ProjectManager().GetProject(projectname,self.c)
                    if p != 'not register to the project yet' and p != 'DB not open yet':
                        if p.fileobj.isstale() or ProjectManager().directory.isstale():
                            p.fileobj.refresh()
                            ProjectManager().directory.refresh()
                            # send broadcast message
                            readonly_message = broadcast_wrapper("The database has been changed by another process. Data reloaded in readonly mode.",projectname,"","DbReadonly",self.useragent)
                            messager.output('# Handler message : broadcast '+readonly_message )
                            # check project associated clients, send broadcast message,
                            # when to send?
                            ProjectManager().broadcast(readonly_message,projectname)
                                   
                            if command in self._def_writedb_command:
                                result = "Database is read only: modifications not allowed"
                                status = "ERROR"
                                response = response_wrapper(status,result,id)
                            else:
                                response =  DBcommand.do_def_readdb_command(p,command,argu,id)
                        else: #not stale
                            # if readdata
                            if command in self._def_readdb_command:
                                response =  DBcommand.do_def_readdb_command(p,command,argu,id)    
                                
                            else:   #if writedata, check if writeable
                                if p.fileobj.iswriteable():
                                    pre_result = DBcommand.process_writedb_command(p,command,argu,id,self.useragent,self.c)
                                    response = pre_result[0]
                                    update_message = pre_result[1]
                                else: # not writeable
                                    result = "database is read only, not allow to update"
                                    status = "ERROR"
                                    response = response_wrapper(status,result,id)
                                    update_message = "database is read only\n"
                                                                       
                    else: #Get db object fail 
                        result = p
                        status = 'ERROR'
                        response = response_wrapper(status,result,id)

            except exceptions.Exception,x:
                status = 'ERROR'
                result = 'catch exception:'+str(x)
                response = response_wrapper(status,result,id)
                messager.output(str(x))

            threadlock.release()                
            # send response
            self._sock.sendall(response)
            messager.output('# Handler message : in connection '+ str(self._addr) + ' sent response: '+ response)
            #check whether it is a update
            if update_message != "":
                ProjectManager().broadcast(update_message,projectname)
                    
    def process_admin_db_command(self,command,argu,id):
        if command == "DbRegister":
            # check arguments number
            if len(argu)<2:
                result = 'Arguments should be: username useragent [broadcast]'
                status = 'ERROR'
            else:                       
                try:
                    username = argu[0].childNodes[0].data
                    useragent = argu[1].childNodes[0].data

                    self.useragent = useragent
                               
                    # create a client object
                    self.c = manager.Client(self._sock,self._addr)
                    self.c.SetAuth(True)
                    self.c.AddUser(username)
                    self.c.SetApplication(useragent)
                           
                    # set the broadcast_flag if specified
                    # Accept either "True" or "False", or interpret
                    # number 0 (zero) as False and non-zero as True
                    if len(argu) > 2:
                        set_broadcast = True
                        broadcast_flag = argu[2].childNodes[0].data
                        try:
                            set_broadcast = (int(broadcast_flag) != 0)
                        except ValueError:
                            if broadcast_flag == 'False':
                                set_broadcast = False
                        self.c.SetBroadcast(set_broadcast)
                       
                    #add to the clientlist
                    ProjectManager().AddClient(self.c)
                     
                    # create a user
                    if ProjectManager().IsUserRegistered(username)!= True:
        
                        ProjectManager().CreateUser(username,self.c)
                        if ProjectManager().directory.islocked(): #force to overwrite if locked
                            result = ProjectManager().directory.load(force=True)
                               
                            if result == True:
                                ProjectManager().dataloaded = True
                                result = 'data locked, force to override, data loaded'
                                # set a flag for this type of result, used to find the
                                # result
                                lock = 1
                            else:
                                result = 'Data does not exist'
                        else: #load data 
                            result = ProjectManager().directory.load()
                            if result == False:
                                result = 'Data does not exist'
                            else:
                                ProjectManager().dataloaded = True
                    else:   
                        ProjectManager().AttachClientToUser(username,self.c)
                        result = True

                    if result == True or lock == 1:
                        status = 'OK'
                    else:
                        status = 'ERROR'
                     
                except exceptions.Exception,x:
                    result = str(x)
                    status='ERROR'

            response = response_wrapper(status,result,id)
            return response
            
        elif command == "DbRequestStatus":
            result = 'Active'
            status = 'OK'
            response = response_wrapper(status,result,id)
            return response

        elif command == "DbInfo":
            result = ('Version '+str(__version__),
                      'Python '+str(sys.version).replace('\n',' '))
            status = 'OK'
            response = response_wrapper(status,result,id)
            return response
        
        elif command == 'DbSupported':
            try:
                if len(argu) < 1:
                    result = 'Argument should be: dbtype '
                    status = 'ERROR'
                else:
                    dbtype = argu[0].childNodes[0].data
                    if dbtype == 'def' or dbtype == 'Def' or dbtype == 'DEF':
                        if def_flag == True:
                            result = True
                            status = 'OK'
                        else:
                            result = False
                            status = 'OK'
                    elif dbtype == 'sqlite' or dbtype == 'SQLite' or dbtype == 'SQLITE':
                        if sql_flag == True:
                            result = True
                            status = 'OK'
                        else:
                            result = False
                            status = 'OK'
                    else:
                        result = False
                        status = 'OK'
            except exceptions.Exception,x:
                status = 'ERROR'
                result = str(x)
            response = response_wrapper(status,result,id)
            return response    

        elif command == 'DbOpen':
            if def_flag == True:
                ## check if the client is allowed to do so
                if self.c.GetAuth() == True:                   
                    try:
                        # get parameter, test how many arguments
                        argu_num = len(argu)

                        if argu_num < 1:
                            result = 'Arguments should be: projectname [grablock/readonly]'
                            status = 'ERROR'
                        else:
                            projectname = argu[0].childNodes[0].data
                            if argu_num >1:
                                mode = argu[1].childNodes[0].data
                                       
                                if 'grablock' in mode:
                                    grablock = True
                                else:
                                    grablock = False

                                if 'readonly' in mode:
                                    readonly = True
                                else:
                                    readonly = False
                                    
                            else:
                                grablock = False
                                readonly = False
                                # check whether project opened, if not, add
                                # the project to client
                            if self.c.IsProjectOpened(projectname):
                                result = 'Project already opened'
                                
                            else:
                                
                                result = ProjectManager().OpenProject(projectname,self.c,grablock,readonly)
                             
                                # when open db ok, add to the list
                                if result == True:
                                    self.c.AddProject(projectname)
                                       
                    except exceptions.Exception,e:
                        messager.output('# Handler message: catch exception when open db:')
                        messager.output(str(e))
                        result = 'no such database: '+str(e)
                          
                else:
                    result = 'Not authorised yet'
            else:
                result = 'def not supported'
               
            if result == True:
                status = 'OK'
            else:
                status = 'ERROR'    

            response = response_wrapper(status,result,id)
            return response

        elif command == 'DbClose':
            try:
                if len(argu) < 1:
                    result = 'Arguments should be: projectname'
                    status = 'ERROR'
                else:
                    projectname = argu[0].childNodes[0].data
                    # Close the project & delete project
                    
                    if projectname in self.c.GetProjects():
                        self.c.DeleProject(projectname)
                        ProjectManager().CloseProject(projectname,self.c)
                        result = True
                    else:
                        result = 'Project not opened'
                    
            except exceptions.Exception,e:
                messager.output('# Handler message: catch exception when close DB:')
                messager.output(str(e))
                result = str(e)
                       
            if result == True:
                status = 'OK'

            else:
                status = 'ERROR'

            response = response_wrapper(status,result,id)
            return response

    def process_def_writedir_command(self,command,argu,id):
        if command == 'DeleteProject':
            try:
                if len(argu) < 1:
                    result = 'Arguments should be: projectname'
                    status = 'ERROR'
                else:
                    projectname = argu[0].childNodes[0].data
                    if ProjectManager().IsProjectOpened(projectname):
                        # Don't delete a reference to a project
                        # if it is currently in use
                        result = "Project "+str(projectname)+" is currenty in use"
                        status = 'ERROR'
                    else:
                        result = ProjectManager().directory.deleteprojectref(projectname)
                        if result != False:
                            status = 'OK'
                            result = 'Project '+str(projectname)+' removed'
                        else:
                            status = 'ERROR'
                            result = 'Failed to remove project '+str(projectname)

            except exceptions.Exception,x:
                result = str(x)
                status = 'ERROR'
                       
            response = response_wrapper(status,result,id)
            # no update message
            message = ""

            if status == 'OK':
                message = broadcast_wrapper("Project "+projectname+" has been deleted",
                                            projectname,
                                            "",
                                            "DeleteProject",
                                            self.useragent)
            return [response,message]

        elif command == 'ImportProject':
            try:
                if len(argu) < 2:
                    result = 'Arguments should be: alias path'
                    status = 'ERROR'
                else:
                    alias = argu[0].childNodes[0].data
                    path = argu[1].childNodes[0].data
                    result = False
                    # Check that neither the name nor the directory are
                    # already in use for a known project directory and that
                    # it is a valid project directory
                    if ProjectManager().directory.isproject(alias):
                        err = str(alias)+" is already in use as a name"
                    elif ProjectManager().directory.isprojectdir(path):
                        err = "Directory "+ \
                              str(path)+ \
                              " is already assigned to a different project"
                    elif not ccp4i.projectDB(alias,path).exists():
                        err = str(path)+" is not a valid project directory"
                    else:
                        result = ProjectManager().directory.addprojectref(alias,path)
                    if result != False:
                        status = 'OK'
                    else:
                        status = 'ERROR'
                        result = str(err)

            except exceptions.Exception,x:
                result = str(x)
                status = 'ERROR'
                       
            response = response_wrapper(status,result,id)
            # no update message
            message = ""
            if status == 'OK':
                message = broadcast_wrapper("Existing project "+alias+" has been added",
                                            alias,
                                            "",
                                            "ImportProject",
                                            self.useragent)
            
            return [response,message]       
 
        elif command == 'AddDataDirRef':
            try:
                if len(argu) < 2:
                    result = 'Arguments should be: def_dir path'
                    status = 'ERROR'
                else:
                    def_dir = argu[0].childNodes[0].data
                    path = argu[1].childNodes[0].data
                    result = ProjectManager().directory.adddefdirref(def_dir,path)
                    if result != False:
                        status = 'OK'
                    else:
                        status = 'ERROR'

            except exceptions.Exception,x:
                result = str(x)
                status = 'ERROR'
                       
            response = response_wrapper(status,result,id)
            # no update message
            message = ""

            if status == 'OK':
                message = broadcast_wrapper("New data directory "+def_dir+" has been added",
                                            def_dir,"",
                                            "AddDataDirRef",
                                            self.useragent)
            return [response,message]           
               
        elif command == 'DeleteDataDirRef':
            try:
                if len(argu) < 1:
                    result = 'Arguments should be: def_dir'
                    status = 'ERROR'
                else:
                    def_dir = argu[0].childNodes[0].data
                    result = ProjectManager().directory.deletedefdirref(def_dir)
                    if result != False:
                        status = 'OK'
                    else:
                        status = 'ERROR'

            except exceptions.Exception,x:
                result = str(x)
                status = 'ERROR'
                       
            response = response_wrapper(status,result,id)
            # no update message
            message = ""
            
            if status == 'OK':
                message = broadcast_wrapper("Data directory "+def_dir+" has been deleted",
                                            def_dir,"",
                                            "DeleteDataDirRef",
                                            self.useragent)
            return [response,message]
           
        elif command == 'NewDb':
            try:      
                if def_flag == True:
                    if self.c.GetAuth() == True:
                        if len(argu) < 2:
                            result = 'Arguments should be: projectname dir'
                            status = 'ERROR'
                        else:
                            projectname = argu[0].childNodes[0].data
                            dir = argu[1].childNodes[0].data
                            result = ProjectManager().NewProject(projectname,dir,self.c)
                            if result == True:
                                # Create db ok, add to the client
                                self.c.AddProject(projectname)
                                status = 'OK'
                            else:
                                status = 'ERROR'                           
                   
                    else:
                        result = 'Not authorised yet'
                        status = 'ERROR'
                else:
                    result = 'def not supported'
                    status = 'ERROR'

            except exceptions.Exception,e:
                messager.output('# Handler message: catch exception when create db:')
                messager.output(str(e))
                status = 'ERROR'
                result = 'no such database: '+str(e)      

            response = response_wrapper(status,result,id)
            
            # no update message
            message = ""

            if status == 'OK':
                message = broadcast_wrapper("New project "+projectname+" has been created",
                                            projectname,"",
                                            "NewProject",
                                            self.useragent)
            return [response,message]            
            
def sockfactory(lockfile,shutdown):
    ''' generate socket & create a lockfile '''
    
    #### check whether the lockfile exists
    if os.path.isfile(lockfile):
        messager.output('# Handler message: find lockfile')
        f = open(lockfile,"r")
        a = f.readline()
        port = a[15:]
        messager.output('# Handler message: port number is: '+ str(port))

        ## try to bind the port number, if failed, exit. or replace lockfile.
        socket.setdefaulttimeout(15)
        s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        try:
            s.bind(('',int(port)))
            if shutdown == True:
                sys.exit(0)
        except exceptions.Exception,e:
            messager.output(str(e))
            messager.output('# Handler message: there is another handler running on port'+str(port)+'.')
            if shutdown == True:
                # if -shutdown, connect the existing handler and send shutdown message
                s.connect(('',int(port)))              
                message = "<db_request><command>ShutDown</command><request_id>2</request_id></db_request>\n"
                s.send(message)
                s.close()

                sys.exit(0)
            else:                
                sys.exit(0)
    else:
        if shutdown == True:
            sys.exit(0)
            
        ## creat a socket
        socket.setdefaulttimeout(15)
        s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)

        port = 4090
        host = ''
        while 1:
            try:
                s.bind(('',port))
                messager.output('# Handler message: port number is '+ str(port))
                break
            except exceptions.Exception,e:
                messager.output(' # Handler message: trying to use different port number')
                messager.output(str(e))
                port = port + 1
                
    ## write to a lockfile
    try:      
        f = open(lockfile, "w")
        f.write("port number is:")
        f.write(str(port))
        f.close()
    except exceptions.Exception,e:
        print str(e)
        
    s.listen(5)
    return s

if __name__ == '__main__':

    shutdown = False    # Process the command line options
    debug    = False    # Generate debugging output
    dirsfile = ""       # Non-default directories file
    i = 1
    nargs = len(sys.argv)
    while i < nargs:
        arg = str(sys.argv[i])
        if arg == "-shutdown":
            shutdown = True
        elif arg == "-debug":
            debug = True
        elif arg == "-directories":
            i=i+1
            dirsfile = str(sys.argv[i])
            # Strip double quotes that may have been supplied
            # by the client API
            if dirsfile[0] == '"' and dirsfile[-1] == '"':
                dirsfile = dirsfile.strip('"')
        # Next argument
        i=i+1

    # Initialise messaging
    messager = messager(debug)

    # Create and store the Manager object for this session
    if dirsfile == "":
        ProjectManager(Manager())
        lockname = "dbccp4i.LOCK"
    else:
        messager.output("dbccp4i: attempting to use "+str(dirsfile))
        if not os.path.exists(dirsfile):
            messager.output("dbccp4i: "+str(dirsfile)+" doesn't exist")
            # Try and create a new directories file
            newdirsfile = ccp4i.directories(source=dirsfile)
            if not newdirsfile.create():
                messager.output("dbccp4i: cannot find or create file '"+ \
                                str(dirsfile)+"'")
                sys.exit(1)
            newdirsfile.release()
        ProjectManager(Manager(dirsfile))
        lockname = str(os.path.splitext(os.path.basename(dirsfile))[0])+\
                   "_dbccp4i.LOCK"

    # create the lock file
    lockfile = os.path.join(ccp4i.GetDotCCP4(),lockname)
    # create a socket
    s = sockfactory(lockfile,shutdown)
    # create an event object to communicate between threads
    en = threading.Event()
    # add a lock
    threadlock = thread.allocate_lock()
    
    try:
      messager.output('====================================================================')
      messager.output('# Handler message: DB Handler started at '+str(datetime.datetime.now() ))
      messager.output('Version: '+ __version__)
      messager.output('====================================================================')
      while 1:      
          try:
              try:
                  clientsock,clientaddr = s.accept()
              except KeyboardInterrupt:
                  # Python 2.4: ignore KeyboardInterrupt caught here
                  raise
              messager.output('# Handler message: New connect from '+ str(clientaddr))
              # start a thread for the client
              t = ServeClient(clientsock,clientaddr)
              t.setDaemon(0)
              t.start()
           
          except socket.timeout:
              if ProjectManager().NumClient() == 0:
                  break

              # still have clients, check any message from child threads,
              # if yes,exit; otherwise write to the database and continue
              else:
                  if en.isSet():
                      messager.output('# Handler message: handler is shutting down')
                      break
                  else:
                     try:
                         threadlock.acquire(True)
                         ## save to disk                         
                         ProjectManager().SaveProject()
                         ProjectManager().SaveDirectory()
                         threadlock.release()
                     except exceptions.Exception,e:
                         threadlock.release()
                         messager.output(str(e))
                     continue
                 
          except socket.error, e:
              # Python 2.5: ignore any socket errors caught here
              messager.output('Ignoring socket error in main loop: '+str(e))
              pass
          
          except KeyboardInterrupt:
              # Ignore keyboard interrupts
              messager.output('Ignoring keyboard interrupt in main loop')
              pass

          except exceptions.Exception,e:
              # Unrecognised exception
              messager.output('Ignoring unknown exception in main loop: '+str(e))
              print 'dbccp4i: ignoring exception in main loop:'
              print str(e)
              print 'Please report this message to CCP4'
              pass
          
    finally:
        # do cleaning: close all projects, close socket
        ProjectManager().Clean()
        s.close()
        if os.path.exists(lockfile):
           os.remove(lockfile)
        else:
           messager.output('Warning: lockfile '+ \
              str(lockfile)+' not found, not removed')
   
    messager.output('=================================================================')
    messager.output('# Handler message: Handler stopped at '+ str(datetime.datetime.now()))
    messager.output('=================================================================\n')

