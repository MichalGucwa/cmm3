
#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.    
#
#====================================================================
# manager.py
#
# Module for handling client & project management in handler
#
# Wanjuan Yang March 06
#
#====================================================================

#CCP4i_cvs_Id $Id: manager.py,v 1.11 2008/08/27 16:09:44 pjx Exp $

__version__ = "$Revision: 1.11 $"


#######################################################################
# Import modules that this module depends on
#######################################################################
import ccp4i
import xml.sax.saxutils as su
import os
import exceptions
import shutil

try:
    import dbapi_sqlite
    sqlite_flag = True
except exceptions.Exception,x:
    sqlite_flag = False

#######################################################################
# Class definitions
#######################################################################

class Manager:
    '''  A class for handlering project & client management in handler.'''
    def __init__(self,directorysource=""):
        self._projectlist = []
        self._clientlist = []
        self._userlist = []
        # Set the time interval used to cache checks on locks etc
        self._interval = 5
        #if sqlite_flag:  # flag for sqlite backend
         #   self._sqldblist = []
        # create a directory object but not load the data
        if directorysource == "":
            self.directory = ccp4i.directories(interval=self._interval)
        else:
            self.directory = ccp4i.directories(source=directorysource,
                                               interval=self._interval)
        # flag for directories.def 
        self.dataloaded = False
        
    def NumProject(self):
        return len(self._projectlist)

    def NumClient(self):
        return len(self._clientlist)

    def NumUser(self):
        return len(self._userlist)

    def SaveProject(self):
       
        if self.NumProject() >0:
            for p in self._projectlist:
                # check if stale
                if p.fileobj.isstale():
                    p.fileobj.refresh()
                    # not writeable, broadcasting
                    message = "Project '"+ \
                              p.projectname + \
                              "' has been changed by another process. The database is now readonly."
                    broadcast = broadcast_wrapper(message,
                                                  p.projectname,
                                                  "",
                                                  "DbReadonly",
                                                  "dbccp4i")
                    self.broadcast(broadcast,p.projectname)
                else:
                    if p.fileobj.iswriteable():
                        p.save()
                
    def SaveDirectory(self):
      
        # check if stale
        if self.directory.isstale():
            self.directory.refresh()
            # not writeable, broadcasting
            message = "The 'directories' data has been changed by another process. The data is now readonly."
            broadcast = broadcast_wrapper(message,
                                          "",
                                          "",
                                          "DirectoriesReadonly",
                                          "dbccp4i")
            self.broadcast_to_all(broadcast)
        
        else:
            # check if writeable
            if self.directory.iswriteable():
                self.directory.save()
        
    def OpenProject(self,projectname,client,grablock,readonly):
        """Open a project database for a client.

        Attempt to open a project database specified by projectname
        for the supplied client, and associate the database with
        that client.

        'grablock' and 'readonly' are boolean modifiers which are
        applied to attempts to open a project which has not already
        been opened by the Manager object on behalf of any client.

        If the Manager has already opened this project then the
        modifiers are not applied."""
        
        # Make sure the directories data is up to date
        if self.directory.isstale():
            self.directory.refresh()
            
        if self.dataloaded:
            
            # Check that the project is defined
            if not self.directory.isproject(projectname):
                return "No such project"
          
            # Check whether the project has already been opened
            if not self.IsProjectOpened(projectname):
                # Hasn't been opened - open it now
                dir = self.directory.projectdir(projectname)
                dbdir = self.directory.projectdb(projectname)
                # Create a def db project
                db = ccp4i.projectDB(projectname,dir,interval=self._interval)
                # Now open the def file database
                if db.exists():
                    # The database already exists
                    if db.islocked() == True:
                        # The database is locked
                        dbstatus = db.open(grablock=grablock,readonly=readonly)
                        if not dbstatus:
                            message = 'data is locked'
                    else:
                        # There is no lock on the database
                        dbstatus = db.open(readonly=readonly)
                        if not dbstatus:
                            message = 'failed to open DB'
                else:
                    # The database doesn't exist
                    dbstatus = False
                    message = 'DB doesn''t exist'

                # Create a Project object to manage the database
                # and add to list of projects for manager object
                if dbstatus:
                    project = Project(projectname,db)
                    self._projectlist.append(project)
            else:
                # Project is already open
                dir = self.directory.projectdir(projectname)
                # Find the exising Project object
                for p in self._projectlist:
                    if p.GetProjectname() == projectname:
                        project = p
                        dbstatus = True
                        break
                if not dbstatus:
                    # Project object not found
                    # This is a serious internal error
                    message = 'Handler internal error: unable to fetch project'
        
            # Deal with SQLite database next
            if dbstatus and sqlite_flag:
                # Check if there is already an sqlite db file
                # NB use the UNIX-style path separator, even
                # on Windows
                if os.path.isfile(str(dir)+"/"+str(projectname)):
                    sqldb = dbapi_sqlite.DB()
                    sqlstatus = sqldb.OpenDB(projectname,dir)
                else:
                    sqlstatus = False
            else:
                # No SQLite database
                sqlstatus = False

            # Attach project (and SQLite db, if we have it) to client
            if dbstatus:
                project.AddClient(client)
                if sqlstatus: client.AddSQLdb(sqldb)
                # Finished
                return True
            else:
                # Failed to get an open project
                # Return the error message
                return message

        else:
            # Data wasn't loaded in the first place
            return 'Data not loaded'

    def NewProject(self,projectname,dir,client):
        """Add a new project to the manager object."""

        if  self.IsProjectOpened(projectname) != True:
            # create def db object
            defdb = ccp4i.projectDB(projectname,dir,interval=self._interval)
            if defdb.exists() != True:
                # Create the project now
                result2 = defdb.create()
            else:
                result2 = 'DB already exists'
                
            # check sqlite flag, if yes, create sql db object
            if sqlite_flag:
                sqldb = dbapi_sqlite.DB()
                # get schema file
                DBCCP4I_TOP = os.environ.get("DBCCP4I_TOP")
                schemafile = os.path.join(DBCCP4I_TOP,"dbccp4i","schema.sql")
                result1 = sqldb.NewDB(projectname,dir,schemafile)

            # Deal with the outcomes
            if result2 == True:
                # Successfully opened the defdb
                # Create a Project object
                project = Project(projectname,defdb)
                project.AddClient(client)
                self._projectlist.append(project)
                # If SQLite support is available and the
                # the SQLite db was successfully opened then
                # set the flags for SQLite db
                if sqlite_flag and result1 == True:
                    project.SetSQLdb()
                    # Add the sqldb object to the client
                    client.AddSQLdb(sqldb)
            # Regardless of the outcome of the SQLite
            # opening, if the def database was opened
            # ok then this is a successful outcome
            if result2 == True:
                result = True
            else:
                # Set the result to whatever we got back
                # from the attempt to create the def db
                result = result2
        else:
            # The project is already open
            result = 'DB already exists and opened'

        # if successful, then add ref in directories.def
        if result == True:
            if self.dataloaded:
                # Get the explicit name of the database dir for the
                # project
                dbdir = defdb.getDbdir()
                self.directory.addprojectref(projectname,dir,dbdir)
                
        return result
        
    def GetProject(self,projectname,client):
        """Return the project object corresponding to projectname for this client"""
        if self.IsProjectOpened(projectname):
            for p in self._projectlist:
                if p.projectname == projectname:
                    if client in p.clientlist:
                        return p
                    else:
                        return 'not register to the project yet'
            else:
                return 'DB not open yet'
        else:
            return 'DB not open yet'

    def GetProjectlist(self):
        return self._projectlist

    def IsProjectOpened(self,projectname):
        """Check if the manager has already opened this project"""
        for p in self._projectlist:
            if p.projectname == projectname:
                return True
        else:
            return False

    def AddClient(self,client):
        self._clientlist.append(client)

    def GetClientlist(self):
        return self._clientlist
    
    def broadcast(self,message,projectname):
        for p in self._projectlist:
            if p.projectname == projectname:
                for client in p.clientlist:
                    if client.GetBroadcast() == True:
                        client.sock.send(message)

    def broadcast_to_all(self,message):
        for client in self._clientlist:
            if client.GetBroadcast() == True:
                client.sock.send(message)
            
    def CreateUser(self,username,client):
        user = User(username)
        self._userlist.append(user)
        user.AddClient(client)

    def IsUserRegistered(self,username):
        for user in self._userlist:
            if user.GetUsername() == username:
                return True
        else:
            return False
        
    def AttachClientToUser(self,username, client):
        for user in self._userlist:
            if user.GetUsername() == username:
                user.AddClient(client)
                
    def DelClient(self,client):
        ## del the client in the list
        if client in self._clientlist:     
            no = self._clientlist.index(client)
            del self._clientlist[no]
         
            
        ## del the client from the projects it has associated 
        for p in self._projectlist:
            if client in p.clientlist:
                p.DeleClient(client)
                # if the client deleted is the last one user of the project, close the project
                if len(p.clientlist) == 0:
                    del self._projectlist[self._projectlist.index(p)]
                    p.close()
        

    def CloseProject(self,projectname,client):
        for p in self._projectlist:
            if p.projectname == projectname:
                p.DeleClient(client)
                if len(p.clientlist) == 0:
                    n = self._projectlist.index(p)
                    del self._projectlist[n]
                    p.close()
        # get sqldb and close it, dele from client
        if p.HasSQLdb():
            for sqldb in client.GetSQLdbs():
                if sqldb.GetDBName() == projectname:
                    sqldb.CloseDB()
                    client.DeleSQLdb(sqldb)
                    
    def Clean(self):
        for p in self._projectlist:
            p.close()

        if self.directory.islocked():
            self.directory.release()


class Project:
    '''A class which has a database instance and the clients associated with the database instance'''
    
    def __init__(self,projectname,fileobj):
        self.projectname = projectname
        self.backend = None
        self.clientlist = []
        self.fileobj = fileobj
        self.sql_flag = False
        
    def __repr__(self):
        return self.projectname

    def SetSQLdb(self):
        self.sql_flag = True
        
    def SetBackend(self,backend):
        self.backend = backend

    def getbackend(self):
        return self.backend   

    def GetProjectname(self):
        return self.projectname
    
    def AddClient(self,client):
        self.clientlist.append(client)

    def DeleClient(self,client):
        i = self.clientlist.index(client)
        del self.clientlist[i]

    def HasSQLdb(self):
        return self.sql_flag
    
    def save(self):
        self.fileobj.save()
        
    def close(self):
        self.fileobj.close()

class Client:
    ''' A class which represent a client connection and have associated attributes, e.g. what projects the client is opening, what application is the client using, is it require broadcast or not etc.'''
    
    def __init__(self,sock,addr):
        self.sock = sock
        self.addr = addr
        self._auth = None
        self._application = None
        self._projectlist = []
        self.broadcast = True
        self._user = None
        self._sqldblist = []    # store sqldb object
        self._db = None         # store central sql db
        
    def __repr__(self):
        return str(self.addr)
        
    def AddProject(self,projectname):
        self._projectlist.append(projectname)

    def GetProjects(self):
        return self._projectlist

    def DeleProject(self,projectname):
        n = self._projectlist.index(projectname)
        del self._projectlist[n]

    def AddSQLdb(self,sqldb):
        self._sqldblist.append(sqldb)
        
    def GetSQLdbs(self):
        return self._sqldblist

    def DeleSQLdb(self,sqldb):
        n = self._sqldblist.index(sqldb)
        del self._sqldblist[n]
        
    def AddUser(self,username):
        self._user = username

    def GetUser(self):
        return self._user
    
    def IsProjectOpened(self,projectname):
        if projectname in self._projectlist:
            return True
        else:
            return False
    
    def SetAuth(self,auth):
        self._auth = auth

    def GetAuth(self):
        return self._auth

    def SetApplication(self,application):
        self._application = application

    def GetApplication(self):
        return self._application

    def SetDb(self,dbname):
        self._db = dbname

    def GetDb(self):
        return self._db

    def SetBroadcast(self,flag):
        self.broadcast = flag

    def GetBroadcast(self):
        return self.broadcast
  
class User:
    '''  A class that represent a user. '''
    def __init__(self,username):
        self._user = username
        self.clientlist = []
   
    def __repr__(self):
        return self._user

    def GetUsername(self):
        return self._user
    
    def AddClient(self,client):
        self.clientlist.append(client)

    def GetClients(self):
        return self.clientlist

    def DeleClient(self,client):
        n = self.clientlist.index(client)
        del self.clientlist[n]


class messager:
    ''' A class that outputs the message to a file or on the screen '''

    def __init__(self,flag=False):
        self.flag = flag
        self.file = open(os.path.join(ccp4i.GetDotCCP4(),'dbhandler.log'),'w')
    def output(self,message):
        if self.flag:
            print str(message)
        else:
            self.file.write(str(message))
            self.file.write(' \n')
            
    def close(self):
        self.file.close()


def response_wrapper(status,result,id):
	''' wrap the message '''
	if type(result) == tuple or type(result) == list:
		response = "<db_response><status>"+ status + "</status><result>"+ result_wrapper(result)+"</result><response_id>"+ str(id) + "</response_id></db_response>\n"

	else:
		response = "<db_response><status>"+status+"</status><result>"+ str(result) + "</result><response_id>" + str(id) + "</response_id></db_response>\n"
	return response	

def result_wrapper(result):
	''' wrap the result '''
        tmp = "<list>"
        
	for item in result:
            if type(item) == tuple or type(item) == list:
                tmp = tmp + "<item>"+result_wrapper(item)+"</item>"
            else:
                tmp = tmp + "<item>"+su.escape(str(item))+"</item>"

	tmp = tmp + "</list>"
	return tmp

def broadcast_wrapper(message,project,job,op,agent):
    '''Wrap a broadcast message in the appropriate pseudo-XML.'''
    
    broadcast = "<db_broadcast>"
    broadcast += "<message>"+str(message)+"</message>"
    broadcast += "<project>"+str(project)+"</project>"
    broadcast += "<jobid>"+str(job)+"</jobid>"
    broadcast += "<operation>"+str(op)+"</operation>"
    broadcast += "<agent>"+str(agent)+"</agent>"
    broadcast += "</db_broadcast>\n"
    return broadcast

_ProjectManager = None

def ProjectManager(manager=None):
    """Set and/or return the current global Manager object.

    The handler needs to create and access a single Manager
    object, which is done via calls to this function.
    An initial call to ProjectManager() should specify the
    Manager instance to use - subsequent calls retrieve this
    object for use."""
    
    global _ProjectManager
    if not manager:
        return _ProjectManager
    else:
        _ProjectManager = manager
        return _ProjectManager
 
if __name__ == '__main__':
    manager = Manager()
    
