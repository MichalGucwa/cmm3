#    
#     Copyright (C) 2006-2008 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
#
# CCP4 Interface - ccp4i.py
#
# Python module providing a class library for emulating the CCP4i
# def file based database. It also provides classes for dealing with
# the CCP4i "directories.def" file and general classes for .def files
# and lockfiles.
#
# Peter Briggs
#
########################################################################

__version__ = "$Revision: 1.14 $"

#######################################################################
# Import modules that this module depends on
#######################################################################
import sys
import os
import stat
import re
import time
import copy

#######################################################################
# Class definitions
#######################################################################

# database
#
# A class for handling CCP4i def file based databases
#
class database:
    """CCP4i def file project database class.

    Creates an instance of a CCP4i project database object associated
    with a particular project name and a project directory. If the
    project doesn't exist then the create method must be used to make
    a new project database.def file; use the open method to load
    data from an existing database.

    To ensure that the data in the database object reflects the actual
    state of the persistent storage, checks are made before read and
    write operations to see whether the database object still holds the
    lock on the resource and that it has not been modified by some
    other process since the last save.

    Since these checks involve file operations which may be expensive
    (in terms of timing), the 'interval' parameter can be used to
    specify the length of time in seconds for which the results of a
    check are held to be valid. An interval of zero means that the checks
    are made every time an operation is performed; a longer interval
    reduces the number of checks that are made, which should improve
    efficiency at the expense of leaving a longer window of opportunity
    for the resource to come out of synch with the database object."""

    def __init__(self,project,directory,dbdir="",template="",interval=0):
        """Internal: initialise a new project database object.

        The name of the project and the path to the corresponding
        project directory must be supplied.

        Optionally a database directory can be specified using the
        'dbdir' argument - this specifies where the object will look
        for or write the persistent storage.
        
        By default the data items in the file are taken from the
        'template' def file in $CCP4/ccp4i/etc; this can be over-ridden
        by specifying a template def file via the optional 'template'
        argument.
        No data is loaded until either the open or create methods
        are invoked."""
        self.__project = project
        self.__directory = GetAbsolutePath(directory)
        self.__record_template = []
        self.__joblist = []
        if dbdir == "":
            # Default database directory
            self.__dbdir = GetAbsolutePath(GetDbDir(directory))
        else:
            # User defined database directory
            self.__dbdir = GetAbsolutePath(dbdir)
        self.__dbdir = self.__dbdir.replace('\\','/').replace('\\\\','/')
        if template == "":
            # Default template
            self.__initfile = SearchPath("TOP","etc","database.def")
        else:
            # User defined template
            self.__initfile = template
        self.__database = array(initfile=self.__initfile)
        self.__dbfile = self.getDbFile()
        # Make sure that the core db items are present
        for item in self.__list_core_db_items():
            if self.__database.addparameter(item,index=0,type=""):
                print "Added item "+item+" to the db"
        self.__dblock = dblockfile(project,self.__dbdir)
        self.__loaded = False
        self.__modified = False
        self.__auto_refresh = False
        self.__last_saved = time.time()
        self.__lastmessage = ""
        # Caching mechanism
        self.__stale = False
        self.__last_checked_stale = -1
        self.__locked = False
        self.__last_checked_lock = -1
        self.__interval = interval

    def __repr__(self):
        """Returns the project name."""
        return self.__project

    def __del__(self):
        """del(project)

        Saves data, releases lock and deletes the object."""
        self.save()
        if self.__dblock.haslock():
            self.__dblock.unlock()

    def __len__(self):
        """len(project)

        Returns the number of jobs stored in the project, or
        zero if the project is not loaded."""
        if self.isloaded():
            return len(self.__joblist)
        return 0

    def __nonzero__(self):
        """Returns True if the project is loaded, False otherwise."""
        return self.isloaded()

    def __initjoblist(self):
        """Internal method: initialises an internal list of jobs.

        Called when the project is opened, as part of the
        initialisation. This method goes through all possible job ids
        (from 1 to NJOBS) and checks for the existence of the 'core'
        data items. If some items are missing then it will attempt to
        repair the record by restoring the missing items with null
        values. If all items are missing then it is assumed that
        the job doesn't exist."""
        # Initialise the internal list of jobs
        self.__joblist = []
        n = self.njobs()
        maxjob = 0
        items = self.__list_core_db_items()
        # Range excludes the last item so add one to last job
        for job in range(1,n+1):
            jobexists = True
            nitems = 0
            missing_items = []
            for item in items:
                if not self.__database.has_parameter(item,job):
                    missing_items.append(item)
                else:
                    nitems =+ 1
            if nitems == 0:
                # None of the items were found
                jobexists = False
            else:
                # Some items were found, attempt to repair
                for item in missing_items:
                    self.__repairdata(job,item,"")
                    self.__modified = True
            if jobexists:
                # Add to the list of jobs
                self.__joblist.append(job)
                if job > maxjob:
                    maxjob = job
        if self.njobs() > maxjob:
            # Special case: the last job doesn't exist
            # Then we need to reset njobs
            self.__database["NJOBS"] = maxjob
            self.__modified = True
        return self.__joblist

    def __repairdata(self,job,item,value):
        """Internal method: force a data item to be set for a job.

        This should only be used internally on startup."""
        self.__database.setvalue(item,job,value)

    def __make_db_file(self,dbfile,project,dbdir,defid):
        """Internal: creates a new (empty) database.def file.

        dbfile is the absolute pathname specifying the database.def
        file; project is the name of the project, dbdir is the path
        of the database directory for the project directory, and defid
        is the identifier for the type of data being written (probably
        should be 'database')."""
        # Make a new CCP4i database.def file.
        # The arguments are the absolute filename and the name of the
        # project. A database file will be generated from the template
        # database.def file in the CCP4 distribution
        self.__database.write(dbfile,project=project+" "+dbdir,defname=defid)

    # Make a database record
    def __make_db_record(self,job_id):
        """Internal: create a blank database record for a job."""
        # Make a blank database record for the specified job id
        for item in self.__list_db_items():
            self.__database.setvalue(item,job_id,None)

    def __list_db_items(self):
        """Internal: return a 'template list' of data items.

        The template list is the names of all data items stored
        for each job in the project."""
        # Return a template list of the items in database record
        if len(self.__record_template) == 0:
            # Load the template from the parameter list
            # of the def file
            for parameter in self.__database.parameters():
                if self.__database.parameter_isindexed(parameter):
                    root = self.__database.parameter_root(parameter)
                    self.__record_template.append(root)
        # Return the existing template
        return copy.copy(self.__record_template)

    def __list_core_db_items(self):
        """Internal: return a 'minimal template list' of data items.

        The minimal template list is the names of those data items
        which absolutely must be present for each job in the project."""
        # Return a "minimal" template list of the items that should
        # be in a database record
        return ["TITLE", \
            "TASKNAME", \
            "DATE", \
            "STATUS", \
            "INPUT_FILES", \
            "INPUT_FILES_DIR", \
            "INPUT_FILES_STATUS", \
            "OUTPUT_FILES", \
            "OUTPUT_FILES_DIR", \
            "OUTPUT_FILES_STATUS", \
            "LOGFILE"]
        
    def getProjectname(self):
        """Return the name of the project."""
        return self.__project

    def getDbdir(self):
        """Return the database directory of the project."""
        return self.__dbdir

    def getDbFile(self):
        """Return the database file for the project."""
        return os.path.join(self.__dbdir,"database.def")

    def getDbItems(self):
        """Return a list of the data items stored for all jobs."""
        return self.__list_db_items()
    
    def exists(self):
        """Test if the project exists.

        Returns True if the project directory and database.def file both
        exist, and False otherwise."""
        # Test if the project exists
        project = self.__project
        directory = self.__directory
        dbdir = self.__dbdir
        dbfile = self.__dbfile
        if DirExists(dbdir) and FileExists(dbfile):
            return True
        else:
            return False

    def islocked(self):
        """Test whether the project is locked.

        Returns True if the project database.def file has a lockfile
        from any process, and False otherwise."""
        # Test if the project is currently locked
        return self.__dblock.islocked()

    def haslock(self):
        """Test whether the project is locked by this process.

        Returns True if the project database.def file has a lockfile
        owned by this process, and False otherwise.

        The check is only performed after a specified time interval,
        in between the value is cached. Set the time interval to
        0 to ensure that the value is never cached."""
        now = time.time()
        if now  > self.__last_checked_lock + self.__interval:
            self.__last_checked_lock = now
            self.__locked = self.__dblock.haslock()
        return self.__locked

    def isloaded(self):
        """Test whether the project data has been loaded.

        Returns True if the database object has been populated from
        the file on disk."""
        return self.__loaded

    def isstale(self):
        """Check if the data in the object is older than on disk.

        Return True if the modification time of the resource
        file is more recent than the last save.
        If so then this suggests that the data in this object may
        not accurately mirror the data in the persistent
        storage.
        
        The check is only performed after a specified time interval,
        in between the value is cached. Set the time interval to
        0 to ensure that the value is never cached."""
        now = time.time()
        if now >= self.__last_checked_stale + self.__interval:
            self.__last_checked_stale = now
            if not FileExists(self.__dbfile):
                # There is no file
                self.__stale = True
            if FileMtime(self.__dbfile) > self.__last_saved:
                # Modification time is more recent than
                # the last save - data in object could be
                # out-of-date
                self.__stale = True
            else:
                self.__stale = False
        return self.__stale

    def isreadable(self):
        """Test if it is possible to get data from the object.

        Returns True if the database object has been loaded,
        and has data that is at least as recent as the persistent
        storage on disk."""
        if self.isstale():
            if self.__auto_refresh: return self.refresh()
            return False
        return self.isloaded()

    def iswriteable(self):
        """Test if it is possible to modify and save the data.

        Returns True if the database object has been loaded, owns
        the lock on the persistent storage on disk, and has data
        that is at least as recent as the persistent storage."""
        if self.isstale():
            return False
        if self.isloaded() and self.haslock():
            return True
        else:
            return False

    def create(self):
        """Make a new project.

        Creating a new project includes creating the project directory
        (if it doesn't already exist), and creating the database
        subdirectory and database.def file. The project is then opened
        and the project object is returned.
        The create operation will fail (returning False) if the project
        already exists."""
        # Make a new database object
        if self.isloaded():
            self.__setmessage("Error project is already loaded for")
            return False
        project = self.__project
        directory = self.__directory
        dbdir = self.__dbdir
        if self.exists():
            self.__setmessage("Error: directory "
                              +directory+" is already a project dir")
            return False
        if not DirExists(directory):
            # Make the project directory
            MakeDir(directory)
        # Make the database subdirectory and database.def file
        if not DirExists(dbdir):
            MakeDir(dbdir)
        dbfile = self.getDbFile()
        self.__make_db_file(dbfile,project,dbdir,"CCP4_Project_Database")
        return self.open()

    def set_auto_refresh(self,auto_refresh):
        """Set the auto_refresh flag.

        'auto_refresh' takes a boolean value. Setting it to 'True'
        means that a read attempt on a 'stale' database (i.e. when
        the source database file is newer than the data in the
        object) will automatically invoke the 'refresh' method to
        load the data in read-only mode. Setting it to 'False'
        means that the 'refresh' method must be explicitly invoked."""

        self.__auto_refresh = auto_refresh
        return self.__auto_refresh

    def auto_refresh(self):
        """Return the value of the auto_refresh flag.

        The 'auto_refresh' feature means that read attempts on a
        'stale' database automatically cause the data to be
        refreshed from file in read-only mode. See the
        set_auto_refresh method for more information."""

        return self.__auto_refresh

    def open(self,grablock=False,readonly=False,strict=False):
        """Open a project.

        Read the data from the project database and return the project
        object.

        The open operation will fail (return False) if the project is
        locked, if the project is already loaded, or if the project
        doesn't exist. Set the 'grablock' argument to True to override
        any existing lock and force loading of the database.

        Specifying 'readonly' as True populates the database object
        from the file on disk without attempting to lock the resource.
        However it will clear an existing lock, so the process may
        still own the lock even if it is in 'read-only' mode.

        If the 'strict' flag is true then header information about
        the project name and database directory are checked against
        the internal values, and warnings issued if there is a
        discrepancy."""
        # Open an existing database object
        project = self.__project
        directory = self.__directory
        dbdir = self.__dbdir
        if self.isloaded():
            self.__setmessage("Error project is already loaded for"+project)
            return False
        dbfile = self.getDbFile()
        if not self.exists():
            self.__setmessage("Error: directory "+directory+" is not a project")
            return False
        # Deal with locks, if necessary
        if not readonly:
            if self.islocked():
                if not grablock:
                    self.__setmessage("Error: database file "+dbfile+
                                      " is locked by another process")
                    return False
                else:
                    self.__dblock.unlock(force=True)               
            self.__dblock.lock()
        # Read in the data
        self.__database.read(dbfile)
        if strict:
            # Get the project name from the def file header
            rx = re.compile(r"^PROJECT ([^ ]+) ([^ ]+)")
            check = rx.match(self.__database.getheaderdata("^PROJECT"))
            if check:
                chk_project = check.group(1)
                if project != chk_project:
                    print "Warning: project name in file (\""+str(chk_project)+ \
                          "\") differs from actual name (\""+ \
                          str(dbdir)+"\")"
                chk_dbdir = check.group(2)
                if dbdir != chk_dbdir:
                    print "Warning: db dir in file (\""+str(chk_dbdir)+ \
                          "\") differs from actual db dir (\""+ \
                          str(dbdir)+"\")"
            else:
                print "Warning: failed to get project & dir names from def file"
        self.__last_saved = FileMtime(dbfile)
        self.__loaded = True
        self.__joblist = self.__initjoblist()
        return True

    def refresh(self,grablock=False,readonly=True):
        """Reload the data from the file into a database object.

        Use the 'refresh' method to re-read the data from the
        file on disk into an existing (loaded) database object.
        This is necessary for example if the file is updated
        by an external process.

        Essentially the database object is closed and then
        reopened. By default the data is reloaded in 'readonly'
        mode. Set the 'grablock' argument to True to override
        any existing lock and force loading of the database in
        write mode - see the 'open' method."""
        self.close()
        self.__database = array(initfile=self.__initfile)
        self.__modified = False
        self.__last_saved = time.time()
        self.__last_checked_stale = -1
        self.__last_checked_lock = -1
        return self.open(grablock=grablock,readonly=readonly)

    def close(self):
        """Close an open project.

        This saves any unsaved data to file, releases the lock on the
        database.def file, and clears the data from the project object,
        returning True on success.
        The project must have first been loaded via an open or create
        operation, otherwise False is returned."""
        # Close an open database
        if not self.isloaded():
            self.__setmessage("Warning: database for "
                              +self.__project+" isn't loaded")
            return False
        self.save()
        if self.haslock():
            self.__dblock.unlock()
            
        self.__database = array()
        self.__record_template = []
        self.__joblist = []
        self.__loaded = False
        return True

    def hasjob(self,job):
        """Checks if a job with the specified id exists in the database.

        Given a job id, returns True if the database contains a job
        with that id and False if not."""
        try:
            jobid = int(job)
        except ValueError:
            return False
        try:
            self.__joblist.index(jobid)
            return True
        except ValueError:
            return False

    def selectjobs(self,item,pattern):
        """Retrieve a list of jobs based on some selection criterion.

        Returns a list of jobs for which the value of the given data
        item matches the supplied regular expression pattern."""
        # Return a list of jobs where the values of the
        # given item match the supplied regular expression
        if not self.isreadable():
            return []
        n = self.njobs()
        rx = re.compile(pattern)
        selection = []
        for job in self.__joblist:
            if self.itemexists(job,item):
                if rx.match(str(self.getdata(job,item))):
                    selection.append(job)
        return selection

    def njobs(self):
        """Return the value of the NJOBS data item.

        For historical reasons, the NJOBS data item records the current
        highest job id number used in the project, and is not generally
        the actual number of jobs in the project. To get the actual
        number of jobs in an object project, do len(project).
        Returns -1 if the project has not been correctly loaded."""
        # Return the value of NJOBS
        if not self.isreadable():
            return -1
        return int(self.__database["NJOBS"])

    def listjobs(self):
        """Return the list of all jobs in the project.

        The list is an unsorted list of job id numbers, or an empty list
        if the project is not currently loaded."""
        # Return the list of job ids
        if not self.isreadable():
            return []
        # Don't return the list itself, as it is mutable
        return copy.copy(self.__joblist)

    def newjob(self,taskname="",status="STARTING",title=""):
        """Create a new job record in the project.

        Creates a new entry in the current project with the current date
        and returns the id number for the new job. Optionally the
        taskname (TASKNAME data item), the status (STATUS item) and/or
        title (TITLE item) may also be set when the job is created.

        If no taskname is specified then it is set to 'none', if no status
        is specified then it is set to 'STARTING'. (Note that blank values
        of the taskname can crash CCP4i and cause corruption of the
        database.)
        
        The operation will fail and return -1 if project is not loaded,
        or if the current object has lost the lock on the database.def
        file."""
        # Create a new record in the database
        if not self.iswriteable():
            self.__setmessage("Error: (newjob) project is not writeable")
            return -1
        n = self.njobs() + 1
        self.__make_db_record(n)
        self.__database["NJOBS"] = n
        self.__joblist.append(n)
        # Check for valid values
        if taskname.isspace() or taskname == "":
            # Don't allow blank TASKNAMEs to be written
            taskname = "none"
        # Optionally set the attributes of the job
        self.setdata(n,"TASKNAME",taskname)
        self.setdata(n,"STATUS",status)
        self.setdata(n,"TITLE",title)
        # Set the date
        self.updatetime(n)
        self.__modified = True
        return n

    def deletejob(self,job):
        """Remove an existing job record from the project.

        The job with the specified id number will be removed from the
        project, also removing all associated data, returning True on
        success. The operation will fail if the database is not loaded,
        if the object has lost the lock on the database.def file, or
        if a job with the specified id number is not found."""
        # Remove a record from the database
        if not self.iswriteable():
            self.__setmessage("Error: (deletejob) project is not writeable")
            return False
        n = self.njobs()
        if job > n:
            return False
        # Locate associated items in the database
        ndel = 0
        for item in self.__list_db_items():
            if self.__database.has_parameter(item,job):
                self.__database.delparameter(item,job)
                ndel = ndel + 1
        if ndel == 0:
            # Nothing was deleted
            return False

        # Remove job from list, and reset NJOBS if necessary
        self.__joblist.remove(job)
        if job == n:
            while n > 0 and self.__joblist.count(n) < 1:
                n = n - 1
            self.__database["NJOBS"] = n

        self.__modified = True
        return True

    def itemexists(self,job,item):
        """Check for the existence of a data item for a particular job.

        Returns True if the data item is found for the specified job
        id number. If the item is not found for the specified job id,
        but was defined in the template database.def file, then this
        method also returns True. Otherwise, itemexists returns False,
        indicating that the item is not accessible for the specified
        job.

        itemexists will also return False in the event that the project
        is not loaded."""
        # Confirm whether or not an item exists for a job
        if not self.isreadable():
            self.__setmessage("itemexists: project is not readable")
            return False
        if job > self.njobs():
            self.__setmessage("itemexists: job > "+str(self.njobs()))
            return False
        if self.__database.has_parameter(item,job):
            return True
        # The specific data item wasn't found, so check if it exists
        # as a prototype?
        return self.__database.has_parameter(item,0)

    def setdata(self,job,item,value):
        """Set the value of a data item for the specified job.

        The job is specified by an id number. The operation returns
        True if the value was successlly updated and False if the
        database is not writeable, or if the data item is valid but
        could not be updated.

        An IndexError exception will be raised if the data item is
        invalid, either because the job doesn't exist or because the
        data item doesn't exist for the job, as indicated by a call
        to the itemexists method.
        
        Note that the validity of the new value is not checked, except
        for the TASKNAME data item, which must not be blank."""
        # Set the value of an item for a job
        value = str(value).replace("\\", "/").replace("\\\\", "/")
        if not self.iswriteable():
            self.__setmessage("setdata: project is not writeable")
            return False
        if not self.hasjob(job):
            raise IndexError, \
                  "No job matching id "+str(job)
        if not self.itemexists(job,item):
            raise IndexError, \
                  "Item \""+str(item)+"\" cannot be set for job "+str(job)
        if item == "TASKNAME":
            if value.isspace() or value == "":
                # Don't allow blank TASKNAMEs to be written
                self.__setmessage("setdata: blank taskname is not valid")
                return False
        self.__database.setvalue(item,job,value)
        self.__modified = True
        return True

    def updatetime(self,job):
        """Update the time of the job to be the current time.

        This wraps the setdata method to automatically set the DATE
        attribute of the job specified by the id number, and returns
        the result of the setdata operation."""
        # Update the DATE attribute of a job to be
        # the current date
        if self.iswriteable():
            return self.setdata(job,"DATE",int(time.time()))
        return False

    def addfile(self,job,ftype,dirs,filename,alias):
        """Add a file to the list of files for a job.

        The job is specified by an id number. 'ftype' specifies
        whether the file should be associated as an 'input' or
        'output' file.

        'filename' specifies the name of the file to be added
        to the can be either a full path or a relative path,
        and 'alias' specifies a project alias to be associated
        with the file. The alias is only used to resolve
        relative paths in the filename, and is ignored if a
        full path is supplied for the file being added.

        'dirs' is a ccp4i directories object.

        Returns True if the operation was successful, False
        if there was a problem. Note that if the file name
        already appears in the list of files then this is
        not an error."""

        # Check that the job exists
        if not self.hasjob(job):
            raise IndexError,"No job matching id "+str(job)

        # Check that the directories data is available
        if not dirs:
            return False

        # Set the file type (INPUT or OUTPUT)
        fitem = str(ftype).upper()+"_FILES"
        ditem = str(ftype).upper()+"_FILES_DIR"

        # Generate a full path filename from the input
        if not os.path.isabs(filename):
            # Relative path - attempt to make a full path
            if alias == "":
                # Use current project
                fullfilen = os.path.join(self.__directory,filename)
            else:
                # Look up the supplied alias
                dirn = dirs.projectdir(alias)
                if dirn == "":
                    # Not a project, try a defdir
                    dirn = dirs.defdir(alias)
                if dirn == "":
                    # Neither project nor defdir
                    # Invalid alias supplied - bail out
                    return False
                # Create a full path
                fullfilen = os.path.join(dirn,filename)
            
        else:
            # Absolute path supplied
            # Sort out the project directory name
            fullfilen = filename

        # Deal with Windows-style path separators
        fullfilen = str(fullfilen).replace("\\", "/").replace("\\\\", "/")
        # Check if the file has already been stored
        for filen in self.listfiles(job,ftype,dirs):
            if os.path.normcase(filen) == os.path.normcase(fullfilen):
                # Found a duplicate - return True
                return True
        # Not a duplicate
        # Convert the name
        data = dirs.filenamecomponents(fullfilen)
        filen = data[0]
        project = data[1]

        # Now store the data

        # Deal with special cases
        # File name contains spaces - wrap in curly braces
        if filen.count(" ") > 0:
            filen = "{ "+str(filen)+" }"

        # Get the data already stored and append the
        # new data
        if not self.itemexists(job,fitem) or not self.itemexists(job,ditem):
            # Some problem with the data
            raise IndexError, \
                  str(ftype).capitalize()+ \
                  " file data doesn't exist for job "+str(job)
        filedata = self.getdata(job,fitem)+" "+str(filen)
        dirsdata = self.getdata(job,ditem)+" "+str(project)
        
        # Update the data directly to make it
        # effectively a single operation
        if not self.iswriteable():
            self.__setmessage("addfile: project is not writeable")
            return False
        self.__database.setvalue(fitem,job,filedata)
        self.__database.setvalue(ditem,job,dirsdata)
        self.__modified = True
        return True

    def addinputfile(self,job,dirs,filename,alias):
        """Add a file to the list of input files for a job.

        This function wraps the addfile method: 'job' is a
        job number, 'dirs' is a directories object, 'filename'
        is an absolute or relative path, and 'alias' is an
        optional project name which is used to resolve
        relative paths but is otherwise ignored.

        The method returns True on success and False otherwise."""

        return self.addfile(job,"INPUT",dirs,filename,alias)

    def addoutputfile(self,job,dirs,filename,alias):
        """Add a file to the list of output files for a job.

        This function wraps the addfile method: 'job' is a
        job number, 'dirs' is a directories object, 'filename'
        is an absolute or relative path, and 'alias' is an
        optional project name which is used to resolve
        relative paths but is otherwise ignored.

        The method returns True on success and False otherwise."""
        return self.addfile(job,"OUTPUT",dirs,filename,alias)

    def listfiles(self,job,ftype,dirs):
        """Return a list of files for a job.

        The job is specified by an id number. 'ftype' specifies
        whether the file list should be the associated 'input' or
        'output' files.

        'dirs' is a ccp4i directories object.

        Returns a list with the full filenames for each of the
        files associated with the job, or a blank list if there
        are no files.

        The following exceptions are raised:
        
        IndexError: if the job id is not found in the database

        ValueError: if there are any problems with interpreting
        the stored data (consistency or parsing issues)"""

        # Check that the job exists
        if not self.hasjob(job):
            raise IndexError,"No job matching id "+str(job)

        # Check that the directories data is available
        if not dirs:
            return []

        # Set the file type (INPUT or OUTPUT)
        fitem = str(ftype).upper()+"_FILES"
        ditem = str(ftype).upper()+"_FILES_DIR"

        # Fetch the data for the files
        # The data is stored as Tcl-style lists so convert
        # them to Python lists using tokenise
        try:
            filens = tokenise(self.getdata(job,fitem))
            dirns = tokenise(self.getdata(job,ditem))
        except IndexError:
            # One or more items not found for this job
            raise ValueError, \
                  str(ftype).capitalize()+ \
                  " file data not available or parseable for job "+str(job)

        # Construct the file list
        files = []
        if len(filens) != len(dirns):
            # The data are inconsistent - there are unequal numbers
            # of file names and directory specifications
            raise ValueError, \
                  str(ftype).capitalize()+ \
                  " file data is inconsistent for job "+str(job)
        for i in range(0,len(filens)):
            files.append(dirs.fullfilename(filens[i],dirns[i]))
        return files

    def listinputfiles(self,job,dirs):
        """Return a list of input files for a job.

        The job is specified by an id number,'dirs' is a ccp4i
        directories object.

        Returns a list with the full filenames for each of the
        files associated with the job, or a blank list if there
        are no files.

        Raises an IndexError exception if the job doesn't exist,
        and ValueError exceptions if the data cannot be otherwise
        retrieved."""
        return self.listfiles(job,"INPUT",dirs)

    def listoutputfiles(self,job,dirs):
        """Return a list of output files for a job.

        The job is specified by an id number,'dirs' is a ccp4i
        directories object.

        Returns a list with the full filenames for each of the
        files associated with the job, or a blank list if there
        are no files.

        Raises an IndexError exception if the job doesn't exist,
        and ValueError exceptions if the data cannot be otherwise
        retrieved."""
        return self.listfiles(job,"OUTPUT",dirs)

    def removefile(self,job,ftype,dirs,filename):
        """Remove a file from the list of files for a job.

        The job is specified by an id number. 'ftype' specifies
        whether the file should be associated as an 'input' or
        'output' file.

        'dirs' is a ccp4i directories object.

        Returns True if the operation was successful, False
        if there was a problem."""

        # Check that the directories data is available
        if not dirs:
            return False

        # Set the file type (INPUT or OUTPUT)
        fitem = str(ftype).upper()+"_FILES"
        ditem = str(ftype).upper()+"_FILES_DIR"

        # Sort out the project directory name
        data = dirs.filenamecomponents(filename)
        filen = data[0]
        project = data[1]
        
        # Fetch the data already stored
        # The data is stored as Tcl-style lists so convert
        # them to Python lists using tokenise
        try:
            filens = tokenise(self.getdata(job,fitem))
            dirns = tokenise(self.getdata(job,ditem))
        except IndexError:
            # One or more items not found for this job
            raise IndexError, \
                  str(ftype).capitalize()+ \
                  " file data not found for job "+str(job)

        # Reconstruct the data without the file being removed
        got_file = False
        filedata = ""
        dirndata = ""
        for i in range(0,len(filens)):
            fileni = filens[i]
            dirnsi = dirns[i]
            if filen != fileni or project != dirnsi:
                if fileni.count(" ") > 0:
                    fileni = "{ "+str(fileni)+" }"
                filedata = filedata+" "+str(fileni)
                dirndata = dirndata+" "+str(dirnsi)
            else:
                # Set flag to indicate that the
                # file was located
                got_file = True

        # Sanity check
        if not got_file:
            # Nothing removed - file not found
            return False
        
        # Update the data directly to make it
        # effectively a single operation
        if not self.iswriteable():
            self.__setmessage("removefile: project is not writeable")
            return False
        self.__database.setvalue(fitem,job,filedata)
        self.__database.setvalue(ditem,job,dirndata)
        self.__modified = True
        return True

    def removeinputfile(self,job,dirs,filename):
        """Remove a file from the list of input files for a job.

        The job is specified by an id number. 'dirs' is a ccp4i
        directories object.

        Returns True if the operation was successful, False
        if there was a problem."""
        return self.removefile(job,"INPUT",dirs,filename)

    def removeoutputfile(self,job,dirs,filename):
        """Remove a file from the list of output files for a job.

        The job is specified by an id number. 'dirs' is a ccp4i
        directories object.

        Returns True if the operation was successful, False
        if there was a problem."""
        return self.removefile(job,"OUTPUT",dirs,filename)

    def getdata(self,job,item):
        """Retrieve the value of a data item stored for a job.

        The job is specified by an id number. If the job doesn't
        exist, or if the item is otherwise inaccessible as
        indicated by a call to the itemexists method, then the
        operation raises an IndexError exception.

        Otherwise, the specific value of the data item for the
        specified job id is returned (or the 'generic' value,
        if a specific value was not found).

        If the database is not readable then 'None' is returned."""
        # Retrieve the value of an item
        if not self.isreadable():
            return None
        if not self.hasjob(job):
            raise IndexError, \
                  "No job matching id "+str(job)
        if not self.itemexists(job,item):
            # Requested data item is not in the database
            raise IndexError, \
                  "Item \""+str(item)+"\" doesn't exist for job "+str(job)
        try:
            # Retrieve the value for the specific item
            return self.__database.getvalue(item,job)
        except KeyError:
            # Raised if the specific item isn't found
            try:
                # Try to retrieve the generic value
                return self.__database.getvalue(item,0)
            except KeyError:
                # No generic value - give up
                # It shouldn't be possible to get here
                raise IndexError, \
                      "Serious error: no specific or generic value available for \""+\
                      str(item)+"\" job "+str(job)

    def describe(self,joblist,itemlist,formatlist):
        """Return a list of formatted strings populated with job data.

        For each job id number in the joblist, the describe method
        retrieves the values of each of the data items in the itemlist
        and creates a description string by placing those values into
        fields with character widths supplied in the formatlist.
        It returns a list of these strings, with one list item per job.
        Allowed data items can be any stored in the project database
        plus JOB_ID (the id number of the job), which is an implicit
        data item."""
        # Return a list of descriptions, one item per job
        # from the supplied list of jobs
        description = []
        if not self.isreadable():
            return description
        for job in joblist:
            description.append(self.describejob(job,itemlist,formatlist))
        return description

    def describejob(self,job,itemlist,formatlist):
        """Return a formatted string populated with job data.

        For the specified job id number, the describejob method
        retrieves the values of each of the data items in the itemlist
        and creates a description string by placing those values into
        fields with character widths supplied in the formatlist.
        Allowed data items can be any stored in the project database
        plus JOB_ID (the id number of the job), which is an implicit
        data item."""
        # Write out the description of a single job record
        # itemlist is a list of data items to be written
        # formatlist is a corresponding list of fieldwidths
        if not self.isreadable():
            return []
        line_format = ""
        for field in formatlist:
            line_format = line_format + "%-" + str(field) + "s"
        valuelist = []
        for item in itemlist:
            if item == "JOB_ID":
                # Job id is not explicity stored
                value = str(job)
            elif item == "DATE":
                # Date must be converted to a pretty format
                value = FormatDate(self.getdata(job,"DATE"))
            else:
                value = str(self.getdata(job,item))
            valuelist.append(value)
        valuelist = tuple(valuelist)
        return line_format % valuelist

    def save(self):
        """Save the project database contents to file.

        The save method writes the data in the object to persistent
        storage (i.e. the database.def file for the project).
        On successful completion True is returned.
        The save operation will fail if the project is not loaded,
        or if the object has lost the lock on the database.def file;
        in both cases False is returned."""
        # Check that data was loaded
        if not self.__loaded:
            return False
        # If the data wasn't modified then there's no need to
        # write anything
        if not self.__modified:
            return True
        # Check whether the disk storage is newer
        if self.isstale():
            self.__setmessage("Error: (save) data on disk is newer than in memory")
            return False
        # Check the lock
        if not self.__dblock.haslock():
            self.__setmessage("Error: (save) lock has been lost")
            return False
        # Write the data to disk
        dbfile = self.getDbFile()
        self.__database.write(dbfile,
                              project=self.__project+" "+self.__dbdir,
                              defname="CCP4_Project_Database",
                              include_nonprototyped=True)
        self.__last_saved = FileMtime(dbfile)
        self.__modified = False
        return True

    def __setmessage(self,message):
        """Internal: set the error message from the last failed operation."""
        # Error reporting
        # Other methods in the class can set an error message
        self.__lastmessage = str(message)
        return True

    def getmessage(self):
        """Retrieve last internal error message.

        If an operation fails then the client application can
        access the last error message using this method. Invoking
        getmessage clears the error message."""
        # Error reporting
        # Application can access the last error message
        message = self.__lastmessage
        self.__lastmessage = ""
        return message

class projectDB(database):
    """CCP4i project database class.

    This extends the base 'database' class to allow subjobs to
    be defined and manipulated. It accepts the same arguments
    on instantiation as the parent class.

    Subjob databases are opened in a 'lazy' fashion i.e. only
    when they are needed."""

    def __init__(self,project,directory,interval=0):
        """Initialise the project database."""
        
        # Initialise the base database object
        database.__init__(self,project,directory,interval=interval)
        # Subjobs
        # Set up a dictionary to keep track of the
        # subjob objects that are open
        self.__subjobs = {}
        self.__interval = interval

    def opensubjobdb(self,job,create=True):
        """Open a subjob database for the specified job id.

        Returns an open subjobDB object, or 'False' if no
        subjob could be opened.

        If the 'create' argument is True then if the subjob
        database does exist in the file system then a new
        subjob database will be created (this is the default).
        To avoid this set the 'create' argument to False."""

        # Check that the job exists
        job = str(job)
        if not self.itemexists(job,"TASKNAME"):
            # Can't open a subjob DB for a non-existent job
            return False
        # Look up if there is already a subjobDB object
        # opened for this job
        if self.__subjobs.has_key(job):
            # Already open
            return self.__subjobs[job]
        # Make a test object for the subjobDB
        taskname = self.getdata(job,"TASKNAME")
        subjobdb = subjobDB(job,taskname,self.getDbdir(),
                            interval=self.__interval)
        if subjobdb.exists():
            # Attempt to open it
            if not subjobdb.open():
                # Failed to open the subjob db
                return False
        elif create:
            # Attempt to create it
            if not subjobdb.create():
                # Failed to create and/or open
                return False
        else:
            # Don't create a new subjob db
            return False
        # Add to the list of subjob objects
        self.__subjobs[job] = subjobdb
        return subjobdb

    def getsubjobdb(self,job):
        """Return an existing subjobDB object associated with a job.

        This returns a subjobDB object associated with a job
        id, or 'False' if a subjob database doesn't already
        exist for the specified job."""
        
        if self.has_subjobs(job):
            return self.opensubjobdb(job)
        return False
    
    def has_subjobs(self,job):
        """Check if a job currently has subjobs defined."""

        # Fast check - is there a subjob database directory?
        job = str(job)
        subdbdir = os.path.join(self.getDbdir(),job+"_database")
        if not DirExists(subdbdir):
            # Assume there is no database
            return False
        # Make a test object for the subjobDB
        subjobdb = self.opensubjobdb(job,create=False)
        if subjobdb:
            if subjobdb.exists():
                if subjobdb.njobs() > 0:
                    return True
        return False
    
    def listjobs_withsubjobs(self):
        """Return a list of the jobs which also have subjobs.

        This could be quite slow for large projects since it
        attempts to open subjob databases for every job, to
        test for their existence.
        Possibly the projectDB object could keep track of the
        subjob data internally to speed this up in future."""

        joblist = []
        for job in self.listjobs():
            if self.has_subjobs(job): joblist.append(job)
        return joblist

    def addsubjob(self,job,taskname,title,status="STARTING"):
        """Add a subjob to a job in the project database.

        If this is the first subjob to be added to the job,
        then a new subjob database will be created first.
        The id number of the subjob will be returned."""

        subjobdb = self.opensubjobdb(job)
        if not subjobdb:
            # Unable to access the subjob db
            return False
        # Get a subjob number
        subjob = subjobdb.newjob(taskname=taskname, \
                                 title=title, \
                                 status=status)
        
        if subjob == -1:
            return False           
        else:
            # Construct the full subjob number x.y
            return self.buildjobid(job,subjob)

    def deletejob(self,jobid):
        """Delete a subjob from a job in the project database.

        Over-ride the 'deletejob' method of the parent class.
        'jobid' can be a job or subjob identifier."""
        
        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - attempt to delete this subjob
            subjobdb = self.opensubjobdb(job)
            if subjobdb:
                return subjobdb.deletejob(subjob)
            # No subjobdb to delete jobs from
            return False
        else:
            # Job reference - delegate to the base class
            return database.deletejob(self,job)

    def listjobs(self,jobid=None):
        """Return a list of jobs or subjobs.

        Over-ride the 'listjob' method of the parent class.
        If no jobid is supplied then return the list of top-level
        jobs in the project; if a jobid is supplied for a top-level
        job then return the list of associated subjobs."""

        if not jobid:
            # Delegate to the parent class
            return database.listjobs(self)
        # Jobid is supplied so list subjobs
        subjobdb = self.getsubjobdb(str(jobid))
        if subjobdb:
            subjoblist = []
            for subjob in subjobdb.listjobs():
                # listjobs() only returns the subjob number
                # Build the complete id for each by adding
                # the parent job number
                subjoblist.append(self.buildjobid(jobid,subjob))
            return subjoblist
        # No subjobs - return an empty list
        return []

    def getdata(self,jobid,item):
        """Retrieve the value of a data item stored for a job.

        This over-rides the 'getdata' method in the parent class.
        'job' can be either an id for a job in the main database,
        or for a subjob."""

        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - get data for a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.getdata(subjob,item)
            # No subjobs
            raise IndexError, \
                  "No subjob "+str(jobid)+" for job "+str(job)
        else:
            # Job reference - delegate to the base class
            return database.getdata(self,job,item)

    def setdata(self,jobid,item,value):
        """Set the value of a data item for the specified job or subjob.

        This over-rides the 'setdata' method in the parent class.
        'jobid' can be either an id for a job in the main database,
        or for a subjob."""

        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - set data for a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.setdata(subjob,item,value)
            # No subjobs
            raise IndexError, \
                  "No subjob "+str(jobid)+" for job "+str(job)
        else:
            # Job reference - delegate to the base class
            return database.setdata(self,job,item,value)

    def selectsubjobs(self,job,item,pattern):
        """Retrieve a list of subjobs based on some selection criterion."""

        subjobdb = self.getsubjobdb(job)
        
        if subjobdb:
            subjoblist = []
            for subjob in subjobdb.selectjobs(item,pattern):
                # listjobs() only returns the subjob number
                # Build the complete id for each by adding
                # the parent job number
                subjoblist.append(self.buildjobid(job,subjob))
            return subjoblist
    
        else:
            # No subjobs - return empty list
            return []

    def itemexists(self,jobid,item):
        """Check for the existence of a data item for a particular job.
        
        This over-rides the 'itemexists' method in the parent class.
        'jobid' can be either an id for a job in the main database,
        or for a subjob."""

        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - set data for a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.itemexists(subjob,item)
            # No subjobs
            raise IndexError, \
                  "No subjob "+str(jobid)+" for job "+str(job)
        else:
            # Job reference - delegate to the base class
            return database.itemexists(self,job,item)

    def addfile(self,jobid,ftype,dirs,filename,alias):
        """Add a file to the list of files for a job.

        Over-ride the 'addfile' method of the parent class
        in order to also deal with subjobs."""
        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - add file reference for a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.addfile(subjob,ftype,dirs,filename,alias)
            # No subjobs to add files to
            return False
        else:
            # Job reference - delegate to the base class
            return database.addfile(self,job,ftype,dirs,filename,alias)

    def removefile(self,jobid,ftype,dirs,filename):
        """Remove a file from the list of files for a job or subjob.

        Over-ride the 'addfile' method of the parent class
        in order to also deal with subjobs."""
        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - remove file reference for a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.removefile(subjob,ftype,dirs,filename)
            # No subjobs to remove files from
            return False
        else:
            # Job reference - delegate to the base class
            return database.removefile(self,job,ftype,dirs,filename)

    def describejob(self,jobid,itemlist,formatlist):
        """Return a formatted string populated with job data.

        This over-rides the method in the base class in order
        to be able to also deal with subjobs."""
        job,subjob = self.splitjobid(jobid)
        if subjob:
            # Subjob reference - describe a subjob
            subjobdb = self.getsubjobdb(job)
            if subjobdb:
                return subjobdb.describejob(subjob,itemlist,formatlist)
            # No subjobs to describe
            return ""
        else:
            # Job reference - delegate to the base class
            return database.describejob(self,job,itemlist,formatlist)

    def save(self):
        """Save the project database to file.

        This extends the 'save' method of the base class, by
        also performing save operations on all of the opened
        subjob databases."""

        for job in self.__subjobs.keys():
            self.__subjobs[job].save()
        # Invoke the base class save
        return database.save(self)

    def close(self):
        """Close the project database.

        This extends the 'close' method of the base class,
        by also closing all the opened subjob databases."""
        
        for job in self.__subjobs.keys():
            self.__subjobs[job].close()
        # Invoke the base class close
        return database.close(self)

    def hasjob(self,jobid):
        """Checks if a job with the specified id exists in the database.

        Given a job id, returns True if the database contains a job
        with that id and False if not.

        Overrides the version in the parent class."""
        job,subjob = self.splitjobid(jobid)
        if not subjob:
            return database.hasjob(self,job)
        subjobdb = self.getsubjobdb(job)
        if subjobdb:
            return subjobdb.hasjob(subjob)
        # No subjobs
        return False

    def splitjobid(self,jobid):
        """Split a job id into job and subjob components.

        This is a wrapper for the 'SplitJobid' function."""
        return SplitJobid(jobid)

    def buildjobid(self,job,subjob=None):
        """Build a single job id given the job and subjob components.

        This is a wrapper for the 'MakeJobid' function."""
        return MakeJobid(job,subjob)

class subjobDB(database):
    """CCP4i subjob database class.

    This stores the job data for substeps defined for a job in
    the main project directory.

    The subjob data are stored in a subdirectory of the project
    database directory, called '<jobid>_database. The name of
    the project database directory must be given explicitly as
    the 'dbdir' argument.

    Note that the subjob databases differ from the base class
    databases, in that when a subjob db is closed it will
    automatically delete the persistent storage (i.e. the
    subdirectory and database.def file) if there are no subjobs
    stored at this point.

    The subjobDB class accepts an 'interval' argument on
    instantiation which performs the same function as in the
    base class."""

    def __init__(self,job,taskname,dbdir,interval=0):
        """Initialise the subjob database.

        The calling process should include the taskname and job id
        number of the main job to which the subjobs belong."""
        project = str(job)+"_"+str(taskname)
        directory = os.path.join(dbdir,str(job)+"_database")
        database.__init__(self,project,directory,dbdir=directory,
                          interval=interval)

    def getId(self):
        """Return the identifier for the subjob database."""
        return self.getProjectname()

    def close(self):
        """Close the subjob database.

        This extends the 'close' method of the base class.
        If there are no subjobs defined at the point of closure
        then the subjob database is removed."""

        empty = False
        if self.njobs() == 0:
            # No subjobs are defined
            empty = True
            dbfile = self.getDbFile()
            dbdir  = self.getDbdir()
        # Close the database
        status = database.close(self)
        if not empty or not status:
            return status
        # Remove the database file
        os.remove(dbfile)
        # Attempt to remove the database directory
        try:
            os.rmdir(dbdir)
        except OSError:
            # This will fail if the directory isn't empty,
            # which is ok
            pass
        return status

# lockfile
#
# A class for handling file locks
#
class lockfile:
    """CCP4i lock file class.

    This class provides methods for creating and manipulating lock
    files associated with arbitrary files within CCP4i.

    The lockfile object manages a lock file associated with the
    the resource file that is specified on instantiation. The
    lockfile name is the same as that of the resource file, with
    the extension '.LOCK' appended to it. The class provides
    methods to set up, check and remove the associated lock file."""

    def __init__(self,filen,resource_desc=""):
        """Instantiate a lockfile object.

        A lockfile object is associated with the file supplied
        by the 'filen' argument - the resource. By default the
        'resource description' is taken as the filename with
        any leading path stripped off, but this can be overriden
        by supplying a description string via the 'resource_desc'
        argument."""
        self.__filen = filen
        self.__rootname = GetFileRootname(filen)
        self.__lockfile = os.path.join(self.__rootname+".LOCK")
        if resource_desc == "":
            self.__resource_desc = os.path.basename(self.__rootname)
        else:
            self.__resource_desc = resource_desc
        self.__user = GetUserId()
        self.__date = GetDate()
        self.__pid = str(GetPid())
        self.__timestamp = -1

    def resource(self):
        """Return the name of the resource (i.e. file) being locked."""
        return self.__filen

    def filename(self):
        """Return the lockfile name (including the path)."""
        return self.__lockfile

    def islocked(self):
        """Check whether the resource is locked.

        This method returns True if the resource file that the
        lockfile object is associated with is 'locked' (that is,
        a physical lock file exists), and False if it is not
        locked.

        Note that it is possible for the resource to be locked
        but for the lock to be owned by a different lockfile
        instance - in this case, 'islocked' will still indicate
        that the resource is locked. Use the 'haslock' method to
        check if the resource is actually locked by this
        instance of the lockfile class."""
        return FileExists(self.filename())

    def haslock(self):
        """Check whether the resource is locked by this lockfile object.

        This method returns True provided that the resource is
        locked (i.e. a physical lock file exists) and that the
        the lock file was created by this instance of the lockfile
        class. If either condition is not satisfied then the
        method returns False."""
        if not self.islocked():
            return False
        # Check the timestamp
        if FileMtime(self.filename()) == self.__timestamp:
            return True
        # Read the lockfile
        simulateFileAccessDelay()
        try:
            f = open(self.filename(),"r")
        except:
            # Catch all exceptions and pass the error up to the
            # calling application
            raise
        # Read in the contents of the lockfile
        contents = f.read()
        # Create a regular expression for picking out information
        rx = re.compile(r"^Lock file for (.*)\nCreated by (.*)\nDate (.*)\nOwned by pid (.*)\n$")
        check = rx.match(contents)
        if not check:
            # Failed to match
            # Lock file format doesn't match regular expression
            return False
        else:
            # Extract the attributes
            resource_desc = check.group(1)
            if self.__resource_desc != resource_desc:
                # Resource description in the lock file doesn't match
                # the one in this object
                return False
            user = check.group(2)
            if self.__user != user:
                # User name doesn't match
                return False
            date = check.group(3)
            if self.__date != date:
                # Time/date doesn't match
                return False
            pid = check.group(4)
            if self.__pid != pid:
                # Process id (pid) doesn't match"
                return False
            # All the tests are passed
            self.__timestamp = FileMtime(self.filename())
            return True

    def lock(self):
        """Lock the file resource.

        Attempts to create the physical lock file associated with
        the resource. This will fail is the resource is already
        locked (by any lockfile object, not necessarily only this
        one). Returns True if the lock is successfully created,
        False if there is a failure."""
        if self.islocked():
            print "Error: resource '"+ \
                  str(self.resource())+ \
                  "' is already locked"
            return False
        # Create a lockfile
        simulateFileAccessDelay()
        try:
            f = open(self.filename(),"w")
        except:
            # Catch all errors
            print "Unable to open lockfile for writing"
            # Pass the error up to the calling application
            raise
        # Write the contents of the lockfile
        # The lockfile conists of the following lines:
        # Lock file for <project/resource description>
        # Created by <uid>
        # Date <date>
        # Owned by pid <pid>
        f.write("Lock file for "+self.__resource_desc+"\n")
        f.write("Created by "+str(self.__user)+"\n")
        f.write("Date "+str(self.__date)+"\n")
        f.write("Owned by pid "+str(self.__pid)+"\n")
        f.close()
        return True
        
    def unlock(self,force=False):
        """Unlock a file resource.

        This method attempts to unlock a file resource that was
        previously locked, by removing the physical lock file.

        The operation will fail if the resource is not currently
        locked, or if the lock on the resource belongs to a
        different lockfile object - in this second case, the
        setting the 'force' to True forces the removal of the
        lock file regardless of ownership.

        This method returns True on successful removal of the
        lock and False otherwise."""
        if not self.islocked():
            print "Error: resource '"+ \
                  str(self.resource())+ \
                  "' is not currently locked"
            return False
        if not self.haslock() and not force:
            print "Error: lockfile doesn't belong to this process"
            return False
        # Delete the lockfile
        os.remove(self.filename())
        return True

# dblockfile
#
# A class specifically for handling database lockfiles
# This inherits from the general CCP4i lockfile class
#
class dblockfile(lockfile):
    """CCP4i database lock file class.

    This class provides methods for creating and manipulating lock
    files for CCP4i def file based databases.
    
    The calling subprogram should specify the name of the project
    (argument 'project') and the path to the database directory
    i.e. the location of the database.def file (argument 'dbdir')."""

    def __init__(self,project,dbdir):
        """Instantiate a new dblockfile object."""
        filen = os.path.join(GetAbsolutePath(dbdir),"database.def")
        lockfile.__init__(self,filen,resource_desc=project)

# directories
#
# A class for handling CCP4i directories.def data
#
class directories:
    """CCP4i project directories class.

    This class provides methods for reading and writing the project
    directory information in directories.def for CCP4i-based
    applications.

    The principle data stored in the directories object and the
    underlying file are 'aliases' associated with directories on the
    file system. These are divided into two types: 'project directories'
    and 'default directories' (also referred to as 'data directories').
    The two types are kept separate within the directories class, and
    have separate methods to access and manipulate them.

    (In addition there are some other data items that are maintained
    for backwards compatibility with the Tcl CCP4i code.)

    By default when the directories object instantiated it tries to take
    the user name from the current environment, and assumes that the
    'source' data file (the persistent storage) is the 'directories.def'
    file in the user's .CCP4 directory or folder. These are determined
    automatically unless overriden by one or both of the 'user' and
    'source' arguments on instantiation.

    To ensure that the data in the directories object reflects the actual
    state of the persistent storage, checks are made before read and
    write operations to see whether the directories object still holds the
    lock on the resource and that it has not been modified by some
    other process since the last save.

    Since these checks involve file operations which may be expensive
    (in terms of timing), the 'interval' parameter can be used to
    specify the length of time in seconds for which the results of a
    check are held to be valid. An interval of zero means that the checks
    are made every time an operation is performed; a longer interval
    reduces the number of checks that are made, which should improve
    efficiency at the expense of leaving a longer window of opportunity
    for the resource to come out of synch with the directories object.

    The directories class also supports an 'auto-refresh' mechanism,
    which is turned off by default but which can be toggled on or
    off using the 'set_auto_refresh' method. When auto-refresh is
    active then data in the object is automatically reloaded from the
    file if the source data file is modified by an other process."""

    def __init__(self,user="",source="",interval=0):
        """Instantiate a new directories object.

        Optionally, specify a username 'user' (otherwise this defaults
        to the current user), a 'source' file (which defaults to the
        platform-specific directories.def file in the user's .CCP4
        area), and an 'interval' (in seconds) specifying the maximum
        time that filesystem checks are taken to be current."""
        if user == "":
            self.__user = GetUserId()
        else:
            self.__user = user
        if source == "":
            self.__directories = os.path.join(GetDotCCP4(),GetOpsys(),"directories.def")
        else:
            self.__directories = source
        self.__projects = {}
        self.__db_dirs = {}
        self.__def_dirs = {}
        # Initialise from the default distribution file
        self.__data = array(SearchPath("TOP","etc","directories.def.dist"))
        self.__lock = lockfile(self.__directories)
        self.__loaded = False
        self.__modified = False
        self.__auto_refresh = False
        self.__last_saved = time.time()
        self.__lastmessage = ""
        # Caching mechanism
        self.__stale = False
        self.__last_checked_stale = -1
        self.__locked = False
        self.__last_checked_lock = -1
        self.__ccp4ilock = False
        self.__last_checked_ccp4i_lock = -1
        self.__interval = interval

    def __repr__(self):
        """Return a string representation of the object, suitable for
        display to the programmer."""
        if self.__loaded:
            return self.__user
        else:
            return ""

    def __nonzero__(self):
        """Returns True if data is loaded, False if not.

        This is a wrapper for the __loaded method of this class."""
        return self.__loaded

    def __del__(self):
        """Perform cleanup when the object is deleted.

        This implementation ensures that the directories data is
        cleanly released on deletion."""
        if self.__loaded:
            self.release()

    def user(self):
        """Return the username associated with the object."""
        return self.__user

    def source(self):
        """Return the source filename associated with the object.

        This is the full path and name of the .def file holding the
        directories data that the directories object is associated
        with."""
        return self.__directories

    def iswriteable(self):
        """Test if it is possible to modify data and save to file.

        Returns True if the data in the object can be modified (e.g.
        adding or deleting project directory references) and if the
        data can be saved to persistent storage (i.e. to the source
        data file). False is returned if this is not possible.

        Provided that the data has been loaded in the first place,
        and that this object owns the lock on the source file,
        modify-and-save should be possible. However if the source
        file is locked by CCP4i (which doesn't recognise the ccp4i
        module's lock files) or if the source file has been
        modified by some external process more recently than the
        last save from this object, then modify-and-save is not
        allowed."""
        if self.islockedbyccp4i() or self.isstale():
            return False
        if self.isloaded() and self.haslock():
            return True
        else:
            return False

    def isreadable(self):
        """Test if it is possible to get data from the object.

        The directories object is considered to be 'readable'
        provided that it is loaded with up-to-date data from the
        source file.

        If the source file is newer than the last time the data
        was loaded (and the 'auto refresh' mechanism is not
        enabled) then the data is not considered readable."""
        if self.isstale():
            # The image in the object is older than
            # the file on disk
            # Attempt to refresh the data
            if self.__auto_refresh: return self.refresh()
            return False
        return self.isloaded()

    def isloaded(self):
        """Test if the data has been loaded from the file.

        The object is loaded with data from the source file by
        successfully executing the 'load' method."""
        return self.__loaded

    def islocked(self):
        """Test if the directories file is currently locked.

        This returns True if there is a lock file created by
        a lockfile object associated with the source file, and
        False otherwise.

        This method only reports the existence of the lock file;
        it doesn't check the ownership of the lock - for that,
        use the 'haslock' method."""
        return self.__lock.islocked()

    def haslock(self):
        """Check if the directories object owns the lock.

        This returns True if the process owns the lock file
        associated with the source file, and False if not (or
        if no lock exists).
        
        The check is only performed explicitly after a specified
        time interval - in between, the outcome of the check is
        cached and it is this cached value that is returned. The
        time interval is specified when the object is first
        created, and should be set to 0 to ensure that the value
        is never cached."""
        now = time.time()
        if now  > self.__last_checked_lock + self.__interval:
            self.__last_checked_lock = now
            self.__locked = self.__lock.haslock()
        return self.__locked

    def isstale(self):
        """Check if the resource file is newer than the stored data.
        
        This method returns True if the modification time of the
        resource file is more recent than the last save (or load)
        time. In this case, the data stored in the object may
        not be an accurate copy of the data in persistent storage.
        Otherwise it returns False (the data in the object is not
        'stale').
        
        The check is only performed explicitly after a specified
        time interval - in between, the outcome of the check is
        cached and it is this cached value that is returned. The
        time interval is specified when the object is first
        created, and should be set to 0 to ensure that the value
        is never cached."""
        now = time.time()
        if now >= self.__last_checked_stale + self.__interval:
            self.__last_checked_stale = now
            if not FileExists(self.__directories):
                # There is no file
                self.__stale = True
            if FileMtime(self.__directories) > self.__last_saved:
                # Modification time is more recent than
                # the last save - data in object could
                # out-of-date
                self.__stale = True
            else:
                self.__stale = False
        return self.__stale

    def islockedbyccp4i(self):
        """Check if the resource file is locked by a CCP4i process.
        
        This method returns True if the directories resource file
        is also locked by CCP4i, i.e. a CCP4i-style lock file is
        present in the same directory or folder as the resource
        file. If no such file is found then False is returned.

        CCP4i's lock files are called <filen>.LOCK. CCP4i itself
        does not recognise lock files created on behalf of this
        class, and may alter the data in the resource file at will.
        
        It is worth noting that CCP4i's lock on the directories.def
        file seems a little unpredictable in CCP4i version 1.4.4.1.
        The CCP4i lock is only created when CCP4i is performing
        certain operations. So the return value of False from this
        method doesn't necessarily indicate that CCP4i is not still
        running."""
        now = time.time()
        if now  >= self.__last_checked_ccp4i_lock + self.__interval:
            self.__last_checked_ccp4i_lock = now
            ccp4ilock = str(self.__directories)+".LOCK"
            if FileExists(ccp4ilock):
                self.__ccp4ilock = True
            else:
                self.__ccp4ilock = False
        return self.__ccp4ilock
    
    def set_auto_refresh(self,auto_refresh):
        """Set the auto_refresh flag.

        'auto_refresh' takes a boolean value. Setting it to 'True'
        means that a read attempt on a 'stale' database (i.e. when
        the source database file is newer than the data in the
        object) will automatically invoke the 'refresh' method to
        load the data in read-only mode. Setting it to 'False'
        means that the 'refresh' method must be explicitly invoked."""

        self.__auto_refresh = auto_refresh
        return self.__auto_refresh

    def auto_refresh(self):
        """Return the value of the auto_refresh flag.

        The 'auto_refresh' feature means that read attempts on a
        'stale' database automatically cause the data to be
        refreshed from file in read-only mode. See the
        set_auto_refresh method for more information."""

        return self.__auto_refresh

    def create(self):
        """Make a new directories file.

        This creates a new source file if one does not already
        exist. The object is automatically loaded once the
        file has been created."""
        directories = self.__directories
        if not FileExists(directories):
            # The file must not already exist
            array = self.__data
            array.write(directories)
            # Perform load operations
            return self.load()
        # Unable to create new file
        return False

    def load(self,force=False,readonly=False):
        """Load the data from the resource file into the object.

        Invoking the 'load' method causes the data to be read
        from the resource file into the directories object, so
        that it can be accessed and manipulated using the
        methods in this class.

        This method returns True on successful load, and False
        on failure. Situations where the load operation will
        fail include: the resource file doesn't exist; the
        data has already been loaded successfully; the resource
        file is locked by another directories object.
        
        In the event that there is a lock on the resource file,
        setting the 'force' argument to True over-rides the
        existing lock essentially grabbing it for the current
        directories instance. Alternatively, setting the
        'readonly' argument to True loads the data even if
        there is a lock from another process, but does not grab
        the lock - so the data can be read but not modified."""
        if self.isloaded():
            return False
        directories = self.__directories
        if FileExists(directories):
            # Deal with locks
            if not readonly and self.islocked():
                if force:
                    self.__lock.unlock(force=True)
                else:
                    return False
            if not readonly and not self.islocked():
                self.__lock.lock()
            # Read in the data
            array = self.__data
            array.read(self.__directories)
            # Make local copy of project alias/directory lookup
            nprojects = int(array["N_PROJECTS"])
            for alias in array.listindexed("PROJECT_ALIAS"):
                path = array.getequivalent(alias,"PROJECT_PATH")
                db_dir = array.getequivalent(alias,"PROJECT_DB")
                self.__projects[array[alias]] = array[path]
                self.__db_dirs[array[alias]] = array[db_dir]
            # Make local copy of def_dir alias/directory lookup
            ndefdirs = int(array["N_DEF_DIRS"])
            for alias in array.listindexed("DEF_DIR_ALIAS"):
                path = array.getequivalent(alias,"DEF_DIR_PATH")
                self.__def_dirs[array[alias]] = array[path]
            self.__loaded = True
            # Set last saved time to the last modification time
            # of the file now
            self.__last_saved = FileMtime(directories)
            return True
        else:
            # Directories file didn't exist
            return False

    def refresh(self,readonly=True):
        """Reload the data from the source directories.def file.

        Invoking this method forces the current data in the object
        to be overwritten by the contents of the source directories
        file on disk."""
        # reread data from the file
        self.release()
        self.__projects = {}
        self.__db_dirs = {}
        self.__def_dirs = {}
        self.__data = array(SearchPath("TOP","etc","directories.def.dist"))
        return self.load(readonly=readonly)

    def release(self):
        """Close the directories object and release the source file.

        Invoking this method saves any data to the persistent storage
        (the source file) and releases the lock on the source file.
        After doing this the object is no longer loaded and cannot
        operate on the data without the 'load' method being
        re-invoked.
        
        The object must have write access to the source file in
        order for the save to take effect, and must own the lock
        in order for it surrender the lock.

        'release' always works and always returns True, regardless
        of whether the save or unlocking operations were successful."""
        if self.iswriteable():
            self.save()
        if self.haslock():
            self.__lock.unlock()
        self.__last_checked_stale = -1
        self.__last_checked_lock = -1
        self.__loaded = False
        return True

    def array(self):
        """Diagnostic method: return the underlying array object.

        This method returns the underlying CCP4i 'array' object
        that holds the actual data. It should not be necessary
        to access the array object directly under normal
        circumstances and the use of this method is not
        recommended."""
        if self.isreadable():
            return self.__data
        else:
            raise AttributeError, "Data not loaded"

    def logdir(self):
        """Return the value of the LOG_DIRECTORY data item.

        Raises an AttributeError exception if the data has
        not yet been loaded into the directories object."""
        if self.isreadable():
            return self.__data["LOG_DIRECTORY"]
        else:
            raise AttributeError, "Data not loaded"

    def setlogdir(self,log_dir):
        """Set the value of the LOG_DIRECTORY data item.

        The directories object must have write access.
        Warning: this method fails silently."""
        if self.iswriteable():
            self.__data["LOG_DIRECTORY"] = log_dir

    def project_menu(self):
        """Return the value of the PROJECT_MENU data item.

        Raises an AttributeError exception if the data has
        not yet been loaded into the directories object."""
        if self.isreadable():
            return self.__data["PROJECT_MENU"]
        else:
            raise AttributeError, "Data not readable"

    def listprojects(self):
        """Return a list of project names.

        Returns a list of the project names i.e. the aliases
        currently loaded into the directories object, or
        raises an AttributeError exception if the data does
        not have read access."""
        if self.isreadable():
            return self.__projects.keys()
        else:
            raise AttributeError, "Data not readable"
        
    def n_projects(self):
        """Return the number of projects.

        Returns the number of projects, stored in the
        N_PROJECTS data item, or raises an AttributeError
        exception if the data does not have read access."""
        if self.isreadable():
            return int(self.__data["N_PROJECTS"])
        else:
            raise AttributeError, "Data not readable"

    def projectdir(self,project):
        """Return the project directory for a specific project.

        Returns the full path of the directory or folder
        corresponding to the specified project name, or an
        empty string if the project name is not one of those
        currently stored in the object.

        Raises an AttributeError exception if the data does not
        have read access."""
        if self.isreadable():
            if self.__projects.has_key(project):
                return self.__projects[project]
            else:
                return ""
        else:
            raise AttributeError, "Data not readable"

    def projectdb(self,project):
        """Return the database directory for a specific project.

        The database directory is a subdirectory of the
        project directory where the database.def file is stored.
        Typically this directory is called CCP4_DATABASE.

        An empty string is returned if the project name is not
        one of those currently stored in the object, and an
        AttributeError exception is raised if the data does not
        have read access."""
        if self.isreadable():
            if self.__db_dirs.has_key(project):
                return self.__db_dirs[project]
            else:
                return ""
        else:
            raise AttributeError, "Data not readable"

    def isproject(self,project):
        """Determine if a name is a project alias.

        Returns True if the specified name is the name of a
        project stored in the directories object, and False if
        it is not."""
        return self.__projects.has_key(project)

    def isprojectdir(self,dir):
        """Determine if a directory path is a project directory.

        If the the specified directory corresponds to a project
        directory then returns the name of the project; otherwise
        returns an empty string.

        Raises an AttributeError exception if the data does not
        have read access."""
        for project in self.__projects.keys():
            if self.projectdir(project) == dir:
                # Found a match
                return project
            # Didn't find a match
            return ""
                
        else:
            raise AttributeError, "Data not readable"

    def addprojectref(self,alias,path,db_dir=""):
        """Add a new project reference.

        Associate a project name 'alias' with the directory
        specified by 'path'. Optionally also specify the
        path to the database directory via the 'db_dir'
        argument, however it is recommended not to set this
        as it normally assigned automatically.

        Returns True if the project reference is successfully
        added and False on failure, for example if the data
        is not write accessible or if the project alias is
        already being used."""
        if self.iswriteable():
            if not self.__projects.has_key(alias):
                array = self.__data
                abspath = GetAbsolutePath(path)
                self.__projects[alias] = abspath
                if db_dir != "":
                    self.__db_dirs[alias] = db_dir
                else:
                    # Determine from directory name
                    self.__db_dirs[alias] = GetDbDir(abspath)
                # replace '\' with '/'
                abspath = str(abspath).replace('\\','/').replace('\\\\','/')
                db_dir = str(db_dir).replace('\\','/').replace('\\\\','/')
                n = array.incr("N_PROJECTS")
                array.setvalue("PROJECT_ALIAS",n,alias)
                array.setvalue("PROJECT_PATH",n,abspath)
                array.setvalue("PROJECT_DB",n,self.__db_dirs[alias])
                # Update the PROJECT_MENU parameter
                self.__update_project_menu()
                self.__modified = True
                return True
            else:
                # Project reference already exists
                return False
        else:
            return False

    def deleteprojectref(self,alias):
        """Remove a project reference.

        This removes the project name 'alias' plus all
        associated data, returning True on success and False
        on failure.

        The operation can fail if the data is not write
        accessible or if the named project is not found in the
        directories object."""
        if self.iswriteable():
            if self.__projects.has_key(alias):
                array = self.__data
                n = array["N_PROJECTS"]
                for project in array.listindexed("PROJECT_ALIAS"):
                    if array[project] == alias:
                        # Located the project reference
                        i = array.parameter_index(project)
                        if i == n:
                            array.delparameter("PROJECT_ALIAS",n)
                            array.delparameter("PROJECT_PATH",n)
                            array.delparameter("PROJECT_DB",n)
                        else:
                            array.replacevalue("PROJECT_ALIAS",i,n)
                            array.replacevalue("PROJECT_PATH",i,n)
                            array.replacevalue("PROJECT_DB",i,n)
                        array.incr("N_PROJECTS",-1)
                        self.__modified = True
                        # Update local data
                        del self.__projects[alias]
                        del self.__db_dirs[alias]
                        # Update the PROJECT_MENU parameter
                        self.__update_project_menu()
                        return True
            # Didn't find the project
            return False
        else:
            return False

    def listdefdirs(self):
        """Return a list of the default directory names.
        
        Returns a list of the default directory names i.e. the
        aliases currently loaded into the directories object, or
        raises an AttributeError exception if the data does
        not have read access."""
        if self.isreadable():
            return self.__def_dirs.keys()
        else:
            raise AttributeError, "Data not readable"
        
    def n_defdirs(self):
        """Return the number of default directories.

        Returns the number of default directories, stored in the
        N_DEF_DIRS data item, or raises an AttributeError
        exception if the data does not have read access."""
        if self.isreadable():
            return int(self.__data["N_DEF_DIRS"])
        else:
            raise AttributeError, "Data not readable"

    def defdir(self,def_dir):
        """Return the directory corresponding to a def dir name.
        
        Returns the full path of the directory or folder
        corresponding to the specified default directory name, or
        an empty string if the default dir name is not one of those
        currently stored in the object.

        Raises an AttributeError exception if the data does not
        have read access."""
        if self.isreadable():
            if self.__def_dirs.has_key(def_dir):
                return self.__def_dirs[def_dir]
            else:
                return ""
        else:
            raise AttributeError, "Data not readable"

    def isdefdir(self,def_dir):
        """Determine if a name is a default directory name.

        Returns True if the specified name is the name of a
        project stored in the directories object, and False if
        it is not (or if the data is not read accessible)."""
        if self.isreadable():
            return self.__def_dirs.has_key(def_dir)
        else:
            return False

    def isdefdirdir(self,dir):
        """Determine if a directory path is a default directory.

        If the the specified directory corresponds to a default
        directory then returns the name of the default dir;
        otherwise returns an empty string.

        Raises an AttributeError exception if the data does not
        have read access."""
        if self.isreadable():
            for defdir in self.__def_dirs.keys():
                if self.defdir(defdir) == dir:
                    # Found a match
                    return defdir
            # Didn't find a match
            return ""
                
        else:
            raise AttributeError, "Data not readable"

    def adddefdirref(self,def_dir,path):
        """Add a new default directory reference.

        Associate a default dir name 'def_dir' with the directory
        specified by 'path'. Returns True if the reference is
        successfully`added and False on failure, for example if the
        data is not write accessible or if the default dir name is
        already being used."""
        if self.iswriteable():
            if not self.__def_dirs.has_key(def_dir):
                array = self.__data
                abspath = GetAbsolutePath(path)
                self.__def_dirs[def_dir] = abspath
                # replace '\' with '/'
                abspath = str(abspath).replace('\\','/').replace('\\\\','/')
                n = array.incr("N_DEF_DIRS")
                array.setvalue("DEF_DIR_ALIAS",n,def_dir)
                array.setvalue("DEF_DIR_PATH",n,abspath)
                self.__modified = True
                return True
            else:
                # Def dir reference already exists
                return False
        else:
            return False

    def deletedefdirref(self,def_dir):
        """Remove a default directory reference.

        This removes the default directory name 'def_dir', plus
        all associated data, returning True on success and False
        on failure.

        The operation can fail if the data is not write
        accessible or if the named default dir is not found in the
        directories object."""
        if self.iswriteable():
            if self.__def_dirs.has_key(def_dir):
                array = self.__data
                n = array["N_DEF_DIRS"]
                for name in array.listindexed("DEF_DIR_ALIAS"):
                    if array[name] == def_dir:
                        # Located the default dir reference
                        i = array.parameter_index(name)
                        if i == n:
                            array.delparameter("DEF_DIR_ALIAS",n)
                            array.delparameter("DEF_DIR_PATH",n)
                        else:
                            array.replacevalue("DEF_DIR_ALIAS",i,n)
                            array.replacevalue("DEF_DIR_PATH",i,n)
                        array.incr("N_DEF_DIRS",-1)
                        self.__modified = True
                        # Update local data
                        del self.__def_dirs[def_dir]
                        return True
            # Didn't find the default dir name
            return False
        else:
            return False

    def save(self,filen=""):
        """Save the data in the directories object to file.

        Invoking this method causes the data in the object to be
        written out to the associated directories.def file. Returns
        True on success and False if the operation fails.

        Reasons for failure include: the directories data is not
        currently loaded; the data hasn't been updated since the
        last save; the directories object doesn't own the lock on
        the source file.

        Optionally, the data can be written out to a different
        file than the associated source file, by specifying a
        non-blank filename as the 'filen' argument."""
        if not self.__loaded:
            print "Not loaded"
            return False
        # Save to file
        if filen != "" and filen != self.__directories:
            self.__data.write(filen,include_types=True)
            return True
        elif self.__modified and self.__lock.haslock():
            self.__data.write(self.__directories,include_types=True)
            self.__modified = False
            self.__last_saved = FileMtime(self.__directories)
            return True
        else:
            self.__setmessage("Error: unable to save directories data")
            return False

    def fullfilename(self,filen,project):
        """Construct a full path from filename and project or def dir name

        Given a filename 'filen' and an alias 'project' (which can
        be either a project alias, a default dir alias, the string
        'FULL_PATH', or a blank string), this method attempts to
        construct a full filename based on the information stored in
        the directories object.

        The rules are:

        If the alias is FULL_PATH or blank, or if it is neither a
        project or default directory alias, then return the input
        filename as is. Otherwise append the filename to the
        directory path corresponding to the alias with the
        appropriate path separator.

        If the data has not been loaded into the object then an
        empty string is returned regardless of the inputs."""
        # return a single full path
        if not self.__loaded:
            print "Not loaded"
            return ""
        if project == "FULL_PATH" or project == "{}":
            return filen
        elif self.isproject(project):
            return os.path.join(self.projectdir(project),filen)
        elif self.isdefdir(project):
            return os.path.join(self.defdir(project),filen)
        else:
            return filen

    def filenamecomponents(self,filename):
        """Break a file/directory name into a filename and alias.
        
        Given a file or directory name, this method returns the
        the appropriate file and project/defdir names as a tuple
        with two elements i.e.:

        (filen,project)
        
        'project' will be the alias of a project or default
        directory (or 'FULL_PATH' if there is no match). 'filen'
        will be the filename relative to the project or default
        directory, '' if the supplied file is actually a directory,
        or the input filename if the alias is returned as 'FULL_PATH'.

        This result is also returned if the data is not currently
        loaded."""
        if not self.__loaded:
            print "Not loaded"
            return (filename,"FULL_PATH")
        # Get the leading path and filename parts
        fullfilen = GetAbsolutePath(filename)
        if DirExists(fullfilen):
            dirn = fullfilen
            filn = ""
        else:
            dirn = os.path.dirname(fullfilen)
            filn = os.path.basename(fullfilen)
        # Look up the directory name to see if it
        # is a project or defdir
        project = ""
        for p in self.listprojects():
            if cmp(dirn,self.projectdir(p)) == 0:
                project = p
                #print str(dirn)+" is project "+str(project)
                break
        if project == "":
            # No project set - see if it's a def dir
            for p in self.listdefdirs():
                if cmp(dirn,self.defdir(p)) == 0:
                    project = p
                    #print str(dirn)+" is defdir "+str(project)
                    break
        # Deal with the situation where an alias
        # wasn't identified
        if project == "":
            project = "FULL_PATH"
            filn = filename
        # Finished
        return (filn,project)

    def __update_project_menu(self):
        """Private: update the PROJECT_MENU parameter when
        projects are added or deleted."""
        project_menu = ""
        for project in self.listprojects():
            project_menu = project_menu+str(project)+" "
        self.__data["PROJECT_MENU"] = project_menu.strip()

    def __setmessage(self,message):
        """Private: error reporting method.
        
        Provides a way for methods in the class to set an error
        message that can subsequently be accessed using the
        'getmessage' method."""
        self.__lastmessage = str(message)
        return True

    def getmessage(self):
        """Access the last internal error message.

        Provides a way for the calling application to access the
        last error message set internally.

        Once the message has been accessed it is deleted."""
        message = self.__lastmessage
        self.__lastmessage = ""
        return message

# history
#
# A class for generating and retrieving data flow information
# from a database
class history:
    """CCP4i database history object.

    This class infers links between jobs in a project database based
    on the names of input and output files, thereby generating a
    'history' for the project based on job linkage.

    Supplied with a loaded database object and a loaded directories
    object, use the construct method to populate the history object.
    Use the parentsof and childrenof methods to return a list of
    parent/child job id numbers for each job. Use the update method
    to find and add new relationships for an existing history.
    Use the arelinked method to find out if two job ids are linked.

    A 'parent' job is a job that has one or more output files that
    are used as input to a 'child' job. Jobs are referenced using
    their job ids. Relationships cannot span projects in this
    implementation. This implementation also doesn't accommodate
    links between jobs that are not due to data flow - however in
    principle it would be possible to add arbitrary links using the
    addlink method.

    Note that the contents of a history object reflects the state
    of the project at the time that the construct method was
    invoked. Subsequent updates to the project data (addition or
    deletion of jobs, addition or removal of file references etc)
    will not be reflected in the history object. To circumvent
    this, either re-invoke the construct or update methods as
    required to rebuild the object contents."""

    def __init__(self,database,directories):
        """Create a new history instance.

        The history class requires an open database object (or
        a subclass) supplied via the 'database' argument, and a
        loaded directories object supplied via the 'directories'
        argument."""
        self.__database = database
        self.__directories = directories
        self.__initialise_lists()

    def __initialise_lists(self):
        """Internal: reset internal data by clearing existing lists."""
        self.__parents = dict()
        self.__children = dict()
        if self.__database:
            for job in self.__database.listjobs():
                self.__parents[job] = []
                self.__children[job] = []

    def updatelinks(self,job_id):
        """Not implemented.
        
        This method was intended to (re)generate the links associated
        with the specified job 'job_id', but has not been implemented."""
        return

    def construct(self):
        """Initialise the relationship data between jobs in the database.
        
        This method constructs descriptions of the relationships
        between jobs in the database. It must be invoked before
        querying the history object.

        The construct method erases any existing data before building
        the relationships from scratch.

        Note that the history object only reflects the state of the
        project at the time that the construct method was last
        invoked. It is therefore necessary to either the reinvoke the
        construct method to rebuild the relationship data from scratch
        or to invoke the update method, if the contents of the project
        database (and possibly the directories object) are updated.

        In the current implementation there is little practical
        difference between the construct and update methods."""
        if self.__database and self.__directories:
            # Initialise lists
            self.__initialise_lists()
            self.__fastpopulate()

    def update(self):
        """Update the relationship data between jobs in the database.

        This method updates descriptions of the relationships
        between jobs in the database. It differs from the construct
        method in that it does not clear any existing data before
        updating. It is possible therefore that 'phantom' links or
        jobs may persist between updates using this method."""
        if self.__database and self.__directories:
            self.__fastpopulate()

    def __fastpopulate(self):
        """Internal: populate the object with data on job linkage.

        This is a re-implementation of the original __populate
        method which is more efficient (and therefore faster).
        It builds a list of the unique files in the project,
        and associates 'parent' and 'child' jobs with each file.
        It then uses this index to build lists of direct
        parent-child job associations."""
        # Keep a list of files in a the project
        file_list = []
        # Make dictionaries with keys being the file
        # names and values being lists of jobs
        #
        # child_jobs[filen] stores the list of jobs for which
        # the file was used as input
        child_jobs = dict()
        # parent_job[filen] stores the job which output the
        # the file
        parent_job = dict()
        # Loop over all jobs in the project
        joblist = self.__database.listjobs()
        for job in joblist:
            # Get list of input files
            try:
                infiles = self.infiles(job)
            except ValueError:
                # Can happen if there is an inconsistency in the
                # input file and directory data that is stored
                # Ignore here
                infiles = []
            for filen in infiles:
                try:
                    file_list.index(filen)
                    child_jobs[filen].append(job)
                except ValueError:
                    # File isn't currently in the list
                    # so add it
                    file_list.append(filen)
                    child_jobs[filen] = [job]
                    parent_job[filen] = 0
            # Get list of output files
            try:
                outfiles = self.outfiles(job)
            except ValueError:
                # Can happen if there is an inconsistency in the
                # input file and directory data that is stored
                # Ignore here
                outfiles = []
            for filen in outfiles:
                try:
                    file_list.index(filen)
                    if job > parent_job[filen]:
                        # Only store the link to the highest
                        # parent job
                        parent_job[filen] = job
                except ValueError:
                    # File isn't currently in the list
                    # so add it
                    file_list.append(filen)
                    child_jobs[filen] = []
                    parent_job[filen] = job
        # Finished making index
        # Now loop over all files and generate the links
        for filen in file_list:
            parent = parent_job[filen]
            if parent != 0:
                for child_job in child_jobs[filen]:
                    self.addlink(parent,child_job)
        return
            
    def __populate(self):
        """Internal:  populate the object with data on job linkage.

        This method is no longer used as the algorithm it implements
        to populate the object is naive and inefficient: it loops over
        the jobs in the project database and for each it then examines
        all other jobs to see if they are linked. This scales as
        !njobs so it rapidly slows as the number of jobs increases.

        The __fastpopulate method implements a vastly more efficient
        algorithm to generate the same data."""
        # Loop over all jobs in the project
        joblist = self.__database.listjobs()
        for i in range(0,len(joblist)):
            job_i = joblist[i]
            infiles_i = self.infiles(job_i)
            outfiles_i = self.outfiles(job_i)
            # Loop over subsequent jobs
            for j in range(i+1,len(joblist)):
                job_j = joblist[j]
                if self.arelinked(job_i,job_j):
                    # These jobs are already linked
                    continue
                # Otherwise explicitly check for links
                # by matching input and output
                infiles_j = self.infiles(job_j)
                outfiles_j = self.outfiles(job_j)
                # Do any input files match output files
                # for this job?
                for filei in infiles_i:
                    for filej in outfiles_j:
                        if str(filei) == str(filej):
                            # Found a link
                            self.addlink(job_j,job_i)
                            break
                    for filei in outfiles_i:
                        for filej in infiles_j:
                            if str(filei) == str(filej):
                                # Found a link
                                self.addlink(job_i,job_j)
                                break
        return

    def addlink(self,parent_job,child_job):
        """Record a link between two jobs.

        This method is used when populating the history object;
        it creates a parent-child link between the supplied job ids
        'parent_job' and 'child_job'."""
        if parent_job == child_job:
            # Apparently a job is linked to itself
            # Ignore
            return
        try:
            x = self.__parents[child_job].index(parent_job)
        except:
            self.__parents[child_job].append(parent_job)
        try:
            x = self.__children[parent_job].index(child_job)
        except:
            self.__children[parent_job].append(child_job)

    def infiles(self,job_id):
        """Return a list of the input files associated with a job.

        Supplied with a job number 'job_id', this method returns
        a list of the full path names for each of the files."""
        return self.__database.listinputfiles(job_id,
                                              self.__directories)
        
    def outfiles(self,job_id):
        """Return a list of the output files associated with a job.

        Supplied with a job number 'job_id', this method returns
        a list of the full path names for each of the files."""
        return self.__database.listoutputfiles(job_id,
                                              self.__directories)

    def arelinked(self,job_id1,job_id2):
        """Check whether two jobs are linked.

        This method returns True if the two jobs 'job_id1' and
        'job_id2' are linked by a parent-child relationship within
        the history object, and False if not.

        The order that the job ids are supplied in is not important."""
        try:
            x = self.__parents[job_id1].index(job_id2)
            return True
        except:
            try:
                x = self.__children[job_id1].index(job_id2)
                return True
            except:
                return False

    def parentsof(self,job_id):
        """Return a list of the parent jobs for a specific job.
        
        Given a job number 'job_id', this method returns a list
        of the parent job ids linked within the history object.

        Raises an IndexError if the job is not found."""
        if self.__parents.has_key(job_id):
            return copy.copy(self.__parents[job_id])
        raise IndexError, "job "+str(job_id)+" not found"

    def childrenof(self,job_id):
        """Return a list of the child jobs for a specific job.
        
        Given a job number 'job_id', this method returns a list
        of the child job ids linked within the history object.

        Raises an IndexError if the job is not found."""
        if self.__children.has_key(job_id):
            return copy.copy(self.__children[job_id])
        raise IndexError, "job "+str(job_id)+" not found"

    def allchildrenof(self,job_id,result_ids=[]):
        """Return list all child jobs descended from a specific job

        Given a job number 'job_id' this method returns a list of
        all 'descendent' jobs, i.e. jobs that are immediate children
        of the specified job, plus jobs that are children of those
        children and so on. Essentially this returns the set of
        jobs descended from the specified job.

        The 'result_ids' argument is used internally when the
        method calls itself recursively - it is used to pass along
        and accumulate the results of earlier calls."""
        children = self.childrenof(job_id)
        if children == []:
            return result_ids
        else:
            for child in children:
                if child not in result_ids:
                    result_ids.append(child)
                self.allchildrenof(child,result_ids)
        return result_ids

    def allparentsof(self,job_id,result_ids=[]):
        """Return list all parent jobs descended from a specific job

        Given a job number 'job_id' this method returns a list of
        all 'antecedent' jobs, i.e. jobs that are immediate parents
        of the specified job, plus jobs that are parents of those
        parents and so on. Essentially this returns the set of
        jobs that anteceded the specified job.

        The 'result_ids' argument is used internally when the
        method calls itself recursively - it is used to pass along
        and accumulate the results of earlier calls."""
        parents = self.parentsof(job_id)
        if parents == []:
            return result_ids
        else:
            for parent in parents:
                if parent not in result_ids:
                    result_ids.append(parent)
                self.allparentsof(parent,result_ids)
        return result_ids

class extendedhistory(history):
    """Extended history class for use with projectDB class.

    The extendedhistory class is intended for use with the
    projectDB class and adds support for querying the history
    for subjobs as well as 'top-level' jobs. The same
    methods are available as for the base 'history' class
    however they can be used for subjobs by specifying
    the subjob id using the x.y notation, e.g.

    history.parentsof(9)

    will return top-level jobs that are 'parents' of job 9,
    while

    history.parentsof(9.5)

    will return subjobs of job 9 that are 'parents' of job
    9.5.

    Note that top-level jobs will not be returned as being
    linked to subjobs (or vice versa); neither will subjobs
    that belong to different top-level jobs."""

    def __init__(self,database,directories):
        """Override initialisation of base class.

        This additionally sets up a dictionary for the histories
        of each of the subjob databases."""
        self.__subhistory = dict()
        for jobid in database.listjobs_withsubjobs():
            self.__subhistory[jobid] = history(database.getsubjobdb(jobid),directories)
        # Also invoke the base class initialisation
        history.__init__(self,database,directories)

    def construct(self):
        """Override the construction of the history.

        This additionally constructs histories for each of the
        subjob databases."""
        for jobid in self.__subhistory.keys():
            self.__subhistory[jobid].construct()
        # Also invoke the base class history construction
        history.construct(self)

    def arelinked(self,job_id1,job_id2):
        """Override the test to see if two jobs are linked."""

        job1,subjob1 = SplitJobid(job_id1)
        job2,subjob2 = SplitJobid(job_id2)
        if subjob1 == None and subjob2 == None:
            # Invoke the base class method to check the
            # link between two top-level jobs
            return history.arelinked(self,job1,job2)
        if subjob1 == None or subjob2 == None:
            # Currently subjobs and top-level jobs cannot
            # be linked
            return False
        if job1 != job2:
            # Subjobs of different parents cannot be linked
            return False
        # Invoke the islinked method of the appropriate
        # subhistory
        return self.__subhistory[job1].arelinked(subjob1,subjob2)

    def parentsof(self,job_id):
        """Override the listing of parent ids for the current job."""

        job,subjob = SplitJobid(job_id)
        if subjob == None:
            return history.parentsof(self,job)
        parent_subjobs = []
        if self.__subhistory.has_key(job):
            for parent in self.__subhistory[job].parentsof(subjob):
                parent_subjobs.append(MakeJobid(job,parent))
            return parent_subjobs
        raise IndexError, "job "+str(job_id)+" not found"

    def childrenof(self,job_id):
        """Override the listing of child ids for the current job."""

        job,subjob = SplitJobid(job_id)
        if subjob == None:
            return history.childrenof(self,job)
        child_subjobs = []
        for child in self.__subhistory[job].childrenof(subjob):
            child_subjobs.append(MakeJobid(job,child))
        return child_subjobs

# array
#
# A class for dealing with CCP4i arrays, which are loaded from and
# saved to .def files
#
class array:
    """CCP4i array class.

    The array class provides functionality for dealing with CCP4i
    arrays, which are typically loaded from and save to .def files.
    It includes methods for readinng and writing CCP4i .def files,
    and allowing manipulation of data inbetween.

    An array consists of 'parameters', which have associated values
    and may optionally also have associated types. Parameters can
    be either 'scalar' (in which case the parameter name is a string
    consisting of alphanumeric characters and the underscore) or
    'indexed' (in which case the parameter name consists of a string
    followed by a comma an then an index component).

    Conventionally parameter names are uppercased. Examples of
    scalar parameters include: NRUNS HKLIN1 REFINE_MODE.

    Examples of indexed parameters include: RUN,0 DERIV,4 ATNAM,1_5
    The index component consists of either a single integer (single
    index), or a pair of integers separated by an underscore (double
    index).

    In addition to parameters, the array object also keeps track of
    'paramater prototypes' (also just referred to as 'prototypes').
    For scalar parameters, the prototype has the same name as the
    parameter and there is essentially no difference between the two.
    
    For indexed parameters, the prototype is the zero'th indexed
    equivalent. For example: for the parameter DERIV,4 the
    parameter prototype would be DERIV,0 while for ATNAM,1_5 it
    would be ATNAM,0 (NB not ATNAM,0_0). RUN,0 is already a
    parameter prototype.

    Parameter prototypes are significant for indexed parameters for
    two reasons:
    1. The type of an indexed parameter is attached to the prototype
    2. The value attached to the prototype is usually used as a
       default value for new indexed parameters based on that
       prototype.

    Prototypes are significant for all parameters because only
    parameters that have prototypes are written to the output
    .def file.

    A set of built-in methods are implemented that allow Python
    dictionary-like syntax to be used to get, set and delete
    array elements - specifically:

    value = array[key] sets value to the value of the element 'key'
    array[key] = value sets the value of the element 'key'
    array.has_key(key) tests whether the element 'key' exists
    del array(key) removes element 'key' from the array."""

    def __init__(self,initfile=""):
        """Create a new array class instance.

        If a .def format file name is supplied via the optional
        'initfile' argument then the contents of the array object
        will be initialised from that file."""
        # Initialisation
        # initfile is an optional def file to initialise from
        self.__initfile = initfile
        # Dictionaries and lists to hold the contents
        self.__header = []
        self.__contents = {}
        self.__types = {}
        self.__parameters = []
        # Header info for writing out
        # Default application name 
        self.__application = "CCP4IPy "+version()
        # Initialise
        if self.__initfile != "":
            self.read(initfile)

    def __getitem__(self,key):
        """Internal: implements 'array[key]' to return value."""
        if self.__contents.has_key(key):
            return self.__contents[key]
        else:
            raise KeyError, "Key not found"

    def __setitem__(self,key,value):
        """Internal: implements 'array[key] = value' to set value."""
        self.__contents[key] = value

    def __delitem__(self,key):
        """Internal: implements 'del array[key]' to delete an item."""
        del self.__contents[key]

    def __contains__(self,key):
        """Internal: implements 'array.has_key(key)' mechanism."""
        if self.__contents.has_key(key):
            return True
        # Check that this isn't an indexed parameter and the
        # calling subprogram didn't specify the index
        if str(key).find(",") < 0:
            return self.__contents.has_key(str(key)+",0")
        else:
            return False

    def read(self,filename):
        """Reads the contents of a def-format file into the array.

        The file format can be either key-value pairs, or
        key-type-value triplets. If a value in the file is of the
        form '\\$name' then 'name' is assumed to be an environment
        variable which is substituted via a call to the GetEnvVar
        function."""
        # Read the contents of a file into the
        # array object
        try:
            simulateFileAccessDelay()
            f = open(str(filename),"r")
            contents = f.readlines()
            f.close()
        except:
            # Catch all errors and pass back up
            self.__error = "Failed to open file \"%s\"" % str(filename)
            raise

        # Process the file contents line-by-line from memory
        for line in contents:
            # Remove whitespace (including trailing newline)
            line = line.strip()
            if line.startswith("#CCP4I"):
                # Header line - store in the header list
                # FIXME: there is no resetting of header data read
                # from multiple files
                self.__header.append(line)
                continue
            elif line.startswith("#"):
                # Comment line - ignore
                continue
            # Tokenise remaining lines
            # There are two types of line: parameter-value pairs
            # and parameter-type-value triples
            tokens = tokenise(line)
            if len(tokens) == 2 or len(tokens) == 3:
                # Break up into components
                key = tokens[0]
                if len(tokens) == 3:
                    type = tokens[1]
                else:
                    type = ""
                # Store as a parameter
                self.addparameter(key,type=type)
                # Store the value (less any quotes)
                value = str(tokens[-1])
                if str(value).startswith("\\$"):
                    # The value has a leading \$
                    # which indicates that it's an
                    # environment variable
                    value = GetEnvVar(value[2:])
                self[key] = value

    def write(self,filename,
              application="",
              version="",
              defname="",
              user="",
              project="",
              include_types=False,
              include_prototypes=False,
              include_nonprototyped=False):
        """Write the contents of the array object to a def file.

        Optionally a number of values can be provided which will be
        written into the header lines of the def file, specifically:

        'application' and 'version' specify a name and version number
        for the application writing the file, i.e.:
        #CCP4I VERSION <application> <version>
        The application name defaults to 'CCP4iPy' if none is supplied.

        'defname' specifies the name of the file, i.e.:
        #CCP4I SCRIPT DEF <defname>
        If defname is not supplied then it defaults to the basename
        of the file being written out.

        'user' is the user name, i.e.:
        #CCP4I USER <user>
        If this is not supplied then it defaults to the value returned
        by the GetUserId function.

        'project' is the name of a CCP4 project, i.e.:
        #CCP4I PROJECT <project>
        If this is not supplied then this header line will not appear.

        Additionally, writing the actual parameters to the file are
        affected by a number of optional 'include_...' arguments:

        include_types:         if True then the type information will
                               also be written to the file; by default
                               type information is not written.
                               
        include_prototypes:    if True then the parameter prototypes
                               for indexed parameters (i.e. the
                               0th-indexed parameters) will also be
                               written; by default the prototypes for
                               indexed parameters are not written.
                               
        include_nonprototyped: if True then all stored parameters will
                               be written; by default only parameters
                               with prototypes are written out."""
        # Write the array contents out to a .def file
        simulateFileAccessDelay()
        try:
            f = open(str(filename),"w")
        except:
            # Pass errors up to the calling subprogram
            self.__error = "write: error opening file \"%s\"" % str(filename)
            raise
        # Write the header components first
        #
        # Application name and version
        if str(application) != "":
            f.write("#CCP4I VERSION "+str(application))
            if str(version) != "":
                f.write(" "+str(version)+"\n")
        else:
            f.write("#CCP4I VERSION "+str(self.__application)+"\n")
        # Def file identifier
        if str(defname) != "":
            defid = str(defname)
        else:
            # Not supplied; use the base of the filename
            basename = os.path.splitext(os.path.basename(filename))
            if len(basename) > 0:
                defid = basename[0]
        f.write("#CCP4I SCRIPT DEF "+str(defid)+"\n")
        # Date
        f.write("#CCP4I DATE "+GetDefDate()+"\n")
        # Username
        if str(user) != "":
            userid = str(user)
        else:
            userid = str(GetUserId())
        f.write("#CCP4I USER "+str(userid)+"\n")
        # Project name
        if str(project) != "":
            f.write("#CCP4I PROJECT "+str(project)+"\n")

        # Write the actual data
        if include_nonprototyped:
            # Write out all parameters in the array object, regardless
            # of their prototype status
            for param in self.__contents:
                if self.parameter_isindexed(param):
                    # Indexed parameter
                    if param != self.__parameter_prototype(param) or \
                       include_prototypes:
                        # Only write non-prototype parameters, unless
                        # these are explicitly requested also
                        self.writeparameter(param,f,include_types)
                else:
                    # Scalar parameter
                    self.writeparameter(param,f,include_types)
        else:
            # Write out only those parameters which have associated
            # prototypes
            for prototype in self.__parameters:
                if not self.parameter_isindexed(prototype):
                    # Parameter prototype is not indexed
                    self.writeparameter(prototype,f,include_types)
                else:
                    # Deal with indexed parameters related to this
                    # prototype
                    for param in self.listindexed(prototype,
                                                  include_prototype=include_prototypes):
                        self.writeparameter(param,f,include_types)
        # Finished
        f.close()

    def writeparameter(self,parameter,f,include_types=False):
        """Write an array parameter to a def file.

        The calling function must supply the complete parameter name (i.e.
        including index, if appropriate) and an initialised file object f.
        If include_types is True then the parameter type is also written."""
        
        f.write(str(parameter)+"      ")
        if include_types:
            f.write(str(self.typeof(parameter))+"      ")
        value = str(self[parameter])
        if len(value) == 0:
            # Empty string
            f.write("\"\"\n")
        elif value.count(" ") > 0:
            # Contains spaces
            f.write("\""+value+"\"\n")
        else:
            # Single nonblank value
            f.write(value+"\n")
        return

    # Methods for extracting data from the header
    def getheaderdata(self,pattern):
        # Given a pattern, find if there is a header
        # line with this data and return the line
        rx = re.compile(pattern)
        for line in self.__header:
            if rx.match(line):
                return line
        return ""

    # Methods for dealing with parameters
    # An array parameter can be single valued or indexed
    # The "prototype" of an indexed parameter is PARAM,0

    def parameters(self):
        """Return a list of the parameter prototypes in the array."""
        return copy.copy(self.__parameters)

    def has_parameter(self,parameter,*indices):
        """Test for the existence of a parameter in the array.

        'parameter' supplies the name of a scalar parameter, or
        the root name of an indexed parameter (in which case one
        or two indices must be specified as separate arguments),
        or a complete indexed parameter name. For example:

        has_parameter('PARAM') - scalar

        has_parameter('PARAM',1) - indexed, one index
        has_parameter('PARAM,1') - indexed, index in the name
        The previous two are equivalent.

        has_parameter('PARAM',1,2) - indexed, two indices
        has_parameter('PARAM,1_2') - indexed, indices in the name
        The previous two are equivalent.

        Note however that has_parameter('PARAM,1',2) is not valid
        syntax for this method.

        Returns True if the parameter is defined in the array, and
        False if not."""
        if len(indices) > 2:
            raise KeyError, "Too many indices for has_parameter"
        key = str(parameter)
        if len(indices) > 0:
            key = key+","+str(indices[0])
            if len(indices) > 1:
                key = key+"_"+str(indices[1])
        return self.__contents.has_key(key)

    def addparameter(self,parameter,index="",type="",value=""):
        """Add a new parameter to the array object.
        
        This method is used to add parameters to the array
        object. If the parameter doesn't exist then a new entry
        will be created to store the specified 'value'.

        If 'parameter' is a scalar parameter, or if it is a zero
        indexed parameter (either explicitly, or when 'index' is
        set to zero), then it will also be added to the list of
        parameter prototypes (if the prototype doesn't already
        exist). The 'type' will be associated with the new
        prototype definition.

        NB: indexed parameters that are not already parameter
        prototypes will NOT have prototypes added for them - this
        may be significant if the array object is saved to file,
        since by default parameters with no prototype are not
        written out."""
        
        # Construct the dictionary key for the parameter
        if index == "":
            # No index explicitly supplied - use the
            # parameter as is
            key = parameter
        else:
            # Index explicitly supplied - construct the full
            # parameter name
            key = self.__make_parameter_name(parameter,index)
        # Deal with prototyping first
        prototype = self.__parameter_prototype(key)
        if key == prototype:
            if not self.isparameter(key):
                self.__parameters.append(key)
                self.__types[key] = type
        # Store the value of the actual parameter, regardless of
        # prototype situation
        self[key] = value
        return

    def delparameter(self,parameter,*indices):
        """Delete a parameter from the array object.

        'parameter' supplies the name of a scalar parameter, or
        the root name of an indexed parameter (in which case one
        or two indices must be specified as separate arguments),
        or a complete indexed parameter name. For example:

        delparameter('PARAM') - scalar

        delparameter('PARAM',1) - indexed, one index
        delparameter('PARAM,1') - indexed, index in the name
        The previous two are equivalent.

        delparameter('PARAM',1,2) - indexed, two indices
        delparameter('PARAM,1_2') - indexed, indices in the name
        The previous two are equivalent.

        Note however delparameter('PARAM,1',2) is not valid syntax
        for this method.

        If successful, removes the parameter from the array. Note
        however that parameter prototypes are not deleted."""
        if len(indices) > 2:
            raise KeyError, "Too many indices for has_parameter"
        key = str(parameter)
        if len(indices) > 0:
            key = key+","+str(indices[0])
            if len(indices) > 1:
                key = key+"_"+str(indices[1])
        del self.__contents[key]

    def isparameter(self,parameter):
        """Check whether the parameter has a prototyped in the array.
        
        Returns True if the parameter is also represented by an
        appropriate parameter prototype in the array. For scalar
        parameters this is the same as the parameter name, while for
        indexed parameters this is the zero-th indexed equivalent.

        The 'parameter' must include any indices associated with the
        parameter name being checked.

        If not prototype exists then returns False."""
        key = self.__parameter_prototype(parameter)
        if self.__parameters.count(key) > 0:
            return True
        else:
            return False

    def typeof(self,parameter):
        """Return the type for a particular parameter.

        The 'parameter' must include any indices associated with the
        parameter name being checked.
        
        If there is no type associated with the prototype for the
        specified 'parameter' argument then an empty string is
        returned."""
        key = self.__parameter_prototype(parameter)
        try:
            return self.__types[key]
        except:
            self.__error = "No type for parameter "+str(parameter)
            return ""

    def listindexed(self,parameter,include_prototype=False):
        """Return a list of parameters that share the same prototype.
        
        Given the name of parameter, this method returns a list of
        all the parameters which share the same prototype. The
        'parameter' argument must include any indices (for example
        'PARAM,1' or 'PARAM,1_2').

        By default the list that is returned won't include the
        actual parameter prototype - set the 'include_prototype'
        argument to True to include the prototype parameter in the
        list."""
        key = self.__parameter_prototype(parameter)
        parameters = []
        for p in self.__contents.keys():
            if p == self.__parameter_prototype(p) and not include_prototype:
                continue
            if key == self.__parameter_prototype(p):
                parameters.append(p)
        # If no results were returned and the parameter
        # was not indexed then try it again with the zero index
        if len(parameters) == 0 and parameter.find(",") < 0:
            key = parameter+",0"
            parameters = self.listindexed(key,include_prototype)
        return parameters

    def getequivalent(self,parameter1,parameter2):
        """Return an equivalently indexed parameter name.
        
        Given an indexed parameter 'parameter1', this method returns
        the name of a parameter with the same index but based on
        'parameter2'.

        For example: if parameter1 = 'PARAM,3' and parameter2 =
        'EQUIV' then 'EQUIV,2' will be returned (also if parameter2
        is 'EQUIV,0' etc)."""
        index = self.__parameter_index(parameter1)
        if index != "":
            return self.__parameter_root(parameter2)+","+str(index)
        else:
            # No index on the first parameter
            return parameter2

    def getvalue(self,parameter,*indices):
        """Get the value of a parameter stored in the array.

        'parameter' supplies the name of a scalar parameter, or
        the root name of an indexed parameter (in which case one
        or two indices must be specified as separate arguments),
        or a complete indexed parameter name. For example:

        getvalue('PARAM') - scalar

        getvalue('PARAM',1) - indexed, one index
        getvalue('PARAM,1') - indexed, index in the name
        The previous two are equivalent.

        getvalue('PARAM',1,2) - indexed, two indices
        getvalue('PARAM,1_2') - indexed, indices in the name
        The previous two are equivalent.

        Note however getvalue('PARAM,1',2) is not valid syntax
        for this method."""
        if len(indices) > 2:
            raise KeyError, "Too many indices for getvalue"
        key = str(parameter)
        if len(indices) > 0:
            key = key+","+str(indices[0])
            if len(indices) > 1:
                key = key+"_"+str(indices[1])
        return self[key]

    def setvalue(self,parameter,*indices):
        """Assign a value toGet the value of a parameter stored in the array.

        'parameter' supplies the name of a scalar parameter, or
        the root name of an indexed parameter (in which case one
        or two indices must be specified as separate arguments),
        or a complete indexed parameter name.

        The last argument in 'indices' must always be the value to
        be assigned. For an indexed parameter, if this is 'None' then
        the default value assigned to the parameter prototype will be
        assigned.

        For example:

        setvalue('PARAM','My value') - set scalar to 'My value'

        setvalue('PARAM',1,'My value') - set single-indexed to 'My value'
        setvalue('PARAM,1',.My value') - equivalent to above

        setvalue('PARAM',1,2,'My value') - set double-indexed parameter
        setvalue('PARAM,1_2','My value') - equivalent to above

        setvalue('PARAM,1',None) - set parameter to same value as

        Note however setvalue('PARAM,1',2,'My value') is not valid
        syntax for this method.

        If the parameter did not already exist then setting its value
        using this method automatically creates it."""
        if len(indices) > 3:
            raise KeyError, "Too many indices for setvalue"
        if len(indices) == 2:
            key = self.__make_parameter_name(parameter,indices[0])
        elif len(indices) == 3:
            key = self.__make_parameter_name(parameter,indices[0],indices[1])
        else:
            key = str(parameter)
        value = indices[-1]
        if value != None:
            self[key] = value
        else:
            self[key] = self[self.__parameter_prototype(key)]

    def incr(self,parameter,increment=1):
        """Increment or decrement the stored integer value for a parameter.
        
        The value stored in 'parameter' must be an integer value -
        the value will be updated by adding the value of the 'increment'
        (which can be either a positive or negative integer) to its
        initial value. If no value is specified for 'increment' then
        the value is increased by one."""
        try:
            self[parameter] = int(self[parameter]) + increment
            return int(self[parameter])
        except:
            raise TypeError, "incr operation failed"

    def replacevalue(self,parameter,*indices):
        """Copy the value of an indexed parameter to another location.

        This method replaces the value stored at one position in an
        indexed parameter by the value stored at another position
        of the same parameter, then delete the parameter that was
        copied.

        'parameter' is the root name of the parameter in question,
        and the remaining arguments are either 2 or 4 numbers
        indicating the target and source indices.

        For example:

        replacevalue('PARAM',n,m) copies the value of PARAM,m to
        PARAM,n and deletes PARAM,m

        replacevalue('PARAM',x,y,p,q) copies the value of PARAM,p,q
        to PARAM,x,y and deletes PARAM,p,q.

        This is useful when deleting a value from a list and copying
        the last item to a new position to replace the deleted
        value."""
        if len(indices) == 2:
            key1 = self.__make_parameter_name(parameter,indices[0])
            key2 = self.__make_parameter_name(parameter,indices[1])
        elif len(indices) == 4:
            key1 = self.__make_parameter_name(parameter,indices[0],indices[1])
            key2 = self.__make_parameter_name(parameter,indices[2],indices[3])
        else:
            raise KeyError, "Wrong number of indices for replacevalue"
        self[key1] = self[key2]
        del self[key2]

    def parameter_root(self,parameter):
        """Return parameter name stripped of any index.

        If 'parameter' is indexed then return the leading part
        of the parameter name with the index removed; otherwise
        return the parameter name as supplied.
        
        Wraps the internal __parameter_root method."""
        return self.__parameter_root(parameter)

    def parameter_index(self,parameter):
        """Return the index part of a parameter name.

        If 'parameter' is an indexed parameter then return the
        index part, otherwise return an empty string.
        
        Wraps the internal __parameter_index method."""
        return self.__parameter_index(parameter)

    def parameter_isindexed(self,parameter):
        """Determine if a parameter is indexed.

        Returns True if 'parameter' is an indexed parameter,
        False if not.
        
        Wraps the internal __parameter_isindexed method."""
        return self.__parameter_isindexed(parameter)

    # Internal (private) methods

    def __parameter_isindexed(self,parameter):
        """Internal: determine if a parameter is indexed.

        Returns True if 'parameter' is an indexed parameter,
        False if not."""
        comma = str(parameter).find(",")
        if comma > -1:
            return True
        else:
            return False

    def __parameter_root(self,parameter):
        """Internal: return parameter name stripped of any index.

        If 'parameter' is indexed then return the leading part
        of the parameter name with the index removed; otherwise
        return the parameter name as supplied."""
        comma = str(parameter).find(",")
        if comma > -1:
            return str(parameter)[:comma]
        else:
            return str(parameter)

    def __parameter_index(self,parameter):
        """Internal: return the index part of a parameter name.

        If 'parameter' is an indexed parameter then return the
        index part, otherwise return an empty string."""
        comma = str(parameter).find(",")
        if comma > -1:
            return str(parameter)[comma+1:]
        else:
            return ""

    def __parameter_prototype(self,parameter):
        """Internal: return the prototype name for a parameter.

        Given a parameter name 'parameter', return the
        equivalent parameter prototype. In the case of a scalar
        (non-indexed) parameter this is the same as the supplied
        name; in the case of an indexed parameter, this is the
        zero-th indexed copy of the parameter name."""
        root = self.__parameter_root(parameter)
        if parameter == root:
            return root
        else:
            return root+",0"

    def __make_parameter_name(self,parameter,index1="",index2=""):
        """Internal: construct the name for an indexed parameter.

        Given a parameter root name 'parameter' plus optionally
        one or two integer indices 'index1' and 'index2', return
        the appropriate parameter name as a single string.

        For example:
        __make_parameter_name('PARAM') returns 'PARAM'
        __make_parameter_name('PARAM',1) returns 'PARAM,1'
        __make_parameter_name('PARAM',1,2) returns 'PARAM,1_2'"""
        key = parameter
        if index1 != "":
            key = str(key)+","+str(index1)
            if index2 != "":
                key = str(key)+"_"+str(index2)
        return key

#######################################################################
# General supporting functions
#######################################################################

# Return an absolute path
def GetAbsolutePath(filen):
    """Return the absolute path - assume that relative paths are rooted
    at the current working directory."""

    if os.name == "nt":
       return (os.path.abspath(filen)).replace("\\","/")
    else:
       return os.path.abspath(filen)

# Make a directory
def MakeDir(directory):
    """Create a new directory."""

    simulateFileAccessDelay()    
    return os.mkdir(directory)

# Check if a directory exists
def DirExists(directory):
    """Check for the existence of a directory.

    This will also return a negative result if the target exists
    but is not a directory."""

    simulateFileAccessDelay()
    return os.path.isdir(directory)

# Check if a file exists
def FileExists(filen):
    """Check for the existence of a file."""
    
    simulateFileAccessDelay()
    return os.path.isfile(filen)

def FileMtime(filen):
    """Return the modification time of a file."""

    simulateFileAccessDelay()
    return os.stat(filen)[stat.ST_MTIME]

# Get the rootname of a file i.e. drop the trailing extension
def GetFileRootname(filen):
    """Return the rootname of a filename."""

    components = os.path.splitext(filen)
    return components[0]

# Return the user id
def GetUserId():
    """Return the username of the current user.

    This function returns the value of the environment variable
    USER, which should be set on UNIX type systems. If USER is
    not set then USERNAME is retrieved, which should be set on
    Windows based systems. Otherwise 'None' will be returned."""
    userid = os.environ.get("USER")
    if userid is None:
        # Try fetching USERNAME
        userid = os.environ.get("USERNAME")
    # Return whatever we've got
    return userid

# Return the current date and time
def GetDate():
    """Return the current date.

    The date is in the format e.g. 27 Feb 2006  15:05:34."""
    
    return time.strftime("%d %b %Y  %H:%M:%S")

# Return the current data and time (in def file format)
def GetDefDate():
    """Return the current date for a def file header.

    The date is in the format dd/mm/yy HH:MM:SS."""
    
    return time.strftime("%d/%m/%y %H:%M:%S")

# Return the current process id
def GetPid():
    """Return the current process id."""
    
    return os.getpid()

# Get the full path for an executable
def FindExecutable(program):
    """Return the full path for the named program.

    FindExecutable operates by looking for the named
    'program' in each directory in the user's path.
    Under Windows it appends '.exe' automatically.
    If the program file is found then the full path
    is returned, otherwise the program name is
    returned."""

    Path = GetEnvVar("PATH")
    opsys = GetOpsys()
    for path in str(Path).split(os.pathsep):
       programexe = os.path.join(path,str(program))
       if opsys == "windows":
          programexe = programexe+".exe"
       if os.path.exists(programexe):
          return programexe
    # Nothing found
    return program


#######################################################################
# Handling the platform and the CCP4 environment
#######################################################################

def GetPlatform():
    """Return the platform information."""

    return sys.platform

def GetOPSYS():
    """Return 'WINDOWS' or 'UNIX', depending on the operating system."""

    Platform = GetPlatform();
    unix = re.compile(r'^linux|irix|osf1|sunos|darwin')
    windows = re.compile(r'^win')
    if unix.match(Platform):
        return "UNIX"
    elif windows.match(Platform):
        return "WINDOWS"
    else:
        return "UNIX"

def GetOpsys():
    """Return 'windows' or 'unix', depending on the operating system."""

    Platform = GetOPSYS()
    return Platform.lower()

def SearchPath(topname,*elements):
    """Return the full path name for a CCP4i code- or data-file.

    This function is based on the CCP4i 'SearchPath' command.
    'topname' should be either 'TOP' or 'HELP', with the remaining
    elements being subdirectories (typically ending with a
    filename). SearchPath will then look for the specified file
    first in the user's .CCP4, then in the DBCCP4I_TOP area,
    and finally in the CCP4I_TOP area. It will return the first
    match that it finds.

    For example: SearchPath('TOP','etc','database.def') will
    look in $USER/.CCP4I/CCP4I_TOP/etc/, $DBCCP4I_TOP/etc/
    and $CCP4I_TOP/etc/ for the file 'database.def'."""

    if topname == "TOP":
        # First look in the user's .CCP4 area
        filen = os.path.join(GetDotCCP4(),"CCP4I_TOP")
        for ele in elements:
            filen = os.path.join(filen,str(ele))
        if FileExists(filen):
            return filen
        # Look in the DBCCP4I_TOP area if not found
        # This is different to the version of SearchPath in
        # the main CCP4i code.
        if GetEnvVar("DBCCP4I_TOP") != "":
            filen = GetEnvVar("DBCCP4I_TOP")
            for ele in elements:
                filen = os.path.join(filen,str(ele))
            if FileExists(filen):
                return filen

    # Otherwise return the path in the main CCP4i area
    filen = os.path.join(GetEnvVar("CCP4I_"+str(topname)))
    for ele in elements:
        filen = os.path.join(filen,str(ele))
    return filen

def GetDotCCP4():
    """Return the location of the .CCP4 directory."""

    # This encodes the logic found in system.tcl, proc InitialiseDotCCP4
    if GetOPSYS() == "UNIX":
        return os.path.join(GetEnvVar("HOME"),".CCP4")
    elif GetOPSYS() == "WINDOWS":
        if GetEnvVar("USERPROFILE") == "":
            return os.path.join(GetEnvVar("SystemRoot"),"Profiles",LoginName,"CCP4")
        else:
            return os.path.join(GetEnvVar("USERPROFILE"),"CCP4")
    # We shouldn't reach this point so it should probably raise an exception
    return ""

def InitialiseDotCCP4():
    """Create or update the .CCP4 directory.

    This function replicates a subset of the functionality of
    the InitialiseDotCCP4 procedure in CCP4i's system.tcl."""

    dotdir = GetDotCCP4()
    if not DirExists(dotdir):
        MakeDir(dotdir)
    unixdir = os.path.join(dotdir,"unix")
    if not DirExists(unixdir):
        MakeDir(unixdir)
    windir = os.path.join(dotdir,"windows")
    if not DirExists(windir):
        MakeDir(windir)

    # Check that directories data is available
    dirs = directories()
    if not FileExists(dirs.source()):
        # No directories data - create it now
        dirs.create()
        dirs.release()

def GetEnvVar(var):
    """Return the value of an environment variable."""

    if os.environ.has_key(var):
        return os.environ[var]
    else:
        return ""

#######################################################################
# Supporting database handling functions
#######################################################################

# Return the CCP4 database directory given the project
# directory
def GetDbDir(projectdir):
    """Return the name of the CCP4i database directory for a project.
    
    Given the project directory path, the name of the default CCP4i
    database subdirectory is returned."""
    
    return os.path.join(projectdir,"CCP4_DATABASE")

# Return the CCP4 database.def file name given the
# project directory
def GetDbFile(projectdir):
    """Return the name of the database.def file.
    
    The sole argument is the name of the project directory."""
    
    return os.path.join(GetDbDir(projectdir),"database.def")

# Make a new CCP4i database.def file
# This consists of the number of jobs plus a dummy record zero
def MakeDbFile(dbfile,project):
    """Make a new CCP4i database.def file.

    The arguments are the absolute filename and the name of the
    project. A database file will be generated from the template
    database.def file in the CCP4 distribution."""

    dbarray = array(initfile=SearchPath("TOP","etc","database.def"))
    dbarray.write(dbfile,project=project)

# Return a list of the items in a database record
def ListDbItems():
    """Return a template list of the items in database record."""
    
    return ["TITLE", \
            "TASKNAME", \
            "DATE", \
            "STATUS", \
            "INPUT_FILES", \
            "INPUT_FILES_DIR", \
            "INPUT_FILES_STATUS", \
            "OUTPUT_FILES", \
            "OUTPUT_FILES_DIR", \
            "OUTPUT_FILES_STATUS", \
            "LOGFILE"]

def MakeJobid(jobid,subjobid=None):
    """Return a job id from job and (optionally) subjob components.

    Given a job id number 'jobid' and (optionally) a subjob id
    number 'subjobid', construct a compound job id. If no subjob id
    is supplied then the result is just the job id; if a subjob id
    is also supplied then the compound id is returned that uniquely
    identifies the subjob as a child of the job."""
    
    if subjobid:
        return str(jobid)+"."+str(subjobid)
    else:
        return jobid
    
def SplitJobid(jobid):
    """Split a job id into job and subjob components.

    Job ids can be either single (integer) numbers, in which
    case they are taken as referring to jobs in the main
    project database, or they can be a pair of numbers
    joined with a dot '.', in which case they are taken
    as referring to subjobs. The first number is the
    main job number and the second the subjob number.
    
    This method returns a tuple containing two items.
    The first is the job number, and the second is either
    a subjob number or 'None'."""

    s = str(jobid).split(".")
    if len(s) > 2:
        # Too many items - dud input?
        raise ValueError, \
              "Invalid job id '"+str(jobid)+"' has too many '.'s"
    if len(s) == 1:
        try:
            return (int(s[0]),None)
        except ValueError:
            raise ValueError, \
                  "Invalid job id '"+str(jobid)+"' can't be converted to an integer"
    else:
        try:
            return (int(s[0]),int(s[1]))
        except ValueError:
            raise ValueError, \
                  "Invalid job id '"+str(jobid)+"' can't be converted to an integer pair"

def FormatDate(epoch):
    """Return an epoch formatted as a date.

    Given an epoch value in seconds this returns a more user-friendly
    string representation similar to that used in CCP4i: if the epoch
    is a time with the last 24 hours then it is returned as
    'hours:minutes:seconds'; otherwise it is returned as
    'day month year'."""
    now = time.time()
    iepoch = int(epoch)
    jobtime = time.localtime(iepoch)
    if (now - iepoch) < 86400:
        # Within 24 hours of the current time
        return time.strftime("%H:%M:%S",jobtime)
    else:
        # Older than 24 hours
        return time.strftime("%d %b %y",jobtime)
            
#######################################################################
# CCP4i def file supporting functions
#######################################################################

# Tokenise a line from a def file
def tokenise(line):
    """Tokenise a string and return a list.

    Typically the string will be a line from a CCP4i def file. Tokens
    are delimited by whitespace, by double quotes, and by curly braces
    '{' and '}', with quoted whitespace within a token not counting as
    a delimiter.

    The tokens are returned with the surrounding quoting characters
    and spaces removed."""
    
    sline = str(line)
    tokens = []
    token = False
    quote = False
    brace = False
    start = 0
    for i in range(len(sline)):
        c = sline[i]
        if token and not quote and not brace:
            if c == " " or c == "\t":
                # end of current token
                tokens.append(sline[start:i])
                token = False
                quote = False
                brace = False
        elif token and c == "\"":
            # Detected a quote - flip the quote flag
            if quote:
                quote = False
            else:
                quote = True
        elif token and c == "}":
            # Detected a close brace
            if brace:
                brace = False
        elif not token:
            if c != " " and c != "\t":
                # Start of a new token
                token = True
                start = i
                if c == "\"":
                    # Also it's quoted
                    quote = True
                elif c == "{":
                    # Also it's enclosed in braces
                    brace = True

    # End of the loop
    if token:
        # End of the last token
        tokens.append(sline[start:len(sline)])
    # Remove any quoting and space characters
    for i in range(0,len(tokens)):
        tokens[i] = tokens[i].strip("\"{}").strip()
    return tokens

#######################################################################
# Other supporting functions
#######################################################################

# Return the ccp4i module version number
def version():
    """Return the version number of the module extracted from the RCS string."""

    # Note: need to break up the regular expression pattern otherwise
    # CVS will substitute it on commit
    pattern = re.compile(r'^\$'+'Revision: ([0-9\.]+) \$') 
    if pattern.match(__version__):
        return str(pattern.match(__version__).group(1))
    else:
        return "?"

# Simulate a delay for a slow file access - used for testing
def simulateFileAccessDelay():
    """Simulate a delay in a file access operation.

    This is used for testing purposes only; the value of the delay
    should be zero in normal usage."""

    time.sleep(0.0)
