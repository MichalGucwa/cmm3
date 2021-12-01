"""This module tests functionality in the module ccp4i.py."""

__version__ = "$Revision: 1.10 $"

import sys
import unittest
import os,os.path
import shutil
import time

# Update the python path to acquire the ccp4i module
if os.path.isdir(os.path.join(os.environ["DBCCP4I_TOP"])):
    ccp4i_path = os.path.join(os.environ["DBCCP4I_TOP"],"dbccp4i")
    sys.path.append(ccp4i_path)
import ccp4i

class ArrayTest(unittest.TestCase):

    def testAddIndexedParameter(self):
        """Test the addparameter method of the array class."""

        # Create a new (empty) array object
        arr = ccp4i.array()
        # Add a zero'th (prototype) parameter and check the value
        arr.addparameter("INDEXED",index=0,type="_text",value="paul daniels")
        self.assertEqual(arr["INDEXED,0"],"paul daniels")
        # Add another indexed parameter
        arr.addparameter("INDEXED",index=1,type="_text",value="harry houdini")
        self.assertEqual(arr["INDEXED,1"],"harry houdini")

class DirectoriesTest(unittest.TestCase):

    def testCreate(self):
        """Test creating a new directories file."""
        
        directories = "test_directories.def"
        cleanDirectories(directories)

        # Create new directories file
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.create(),True,"'Create' method failed")
        self.assertEqual(os.path.exists(directories),True,str(directories)+" not found")
        dirs.release()
        cleanDirectories(directories)

    def testLoad(self):
        """Test opening a directories file."""
        
        directories = "test_directories.def"
        makeDirectories(directories)
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(),True,"Failed to load test directories.def")
        dirs.release()
        cleanDirectories(directories)

    def testRead(self):
        """Test reading data from the directories file"""

        directories = "test_directories.def"
        makeDirectories(directories)
        dirs = ccp4i.directories(source=directories)
        dirs.load()
        self.assertEqual(dirs.n_projects(),0,"Failed to get number of projects")
        self.assertEqual(dirs.listprojects(),[],"Failed to list projects")
        self.assertEqual(dirs.n_defdirs(),1,"Failed to get number of def dirs")
        self.assertEqual(dirs.listdefdirs(),["TEMPORARY"],"Failed to list def dirs")
        dirs.release()
        cleanDirectories(directories)

    def testWriteRead(self):
        """Test writing data to the object and reading it back.

        Not implemented."""
        
    def testWriteSaveRead(self):
        """Test writing data to the file and reading it back.

        Not implemented."""

class DirectoriesReadonlyTest(unittest.TestCase):
    
    def testReadonlyLoad(self):
        """Test opening a directories file as readonly."""
        
        directories = "test_directories.def"
        makeDirectories(directories)
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(readonly=True),True,
                         "Failed to load test directories.def")
        dirs.release()
        cleanDirectories(directories)

    def testReadonlyRead(self):
        """Test that readonly load allows reading."""

        directories = "test_directories.def"
        makeDirectories(directories)
        dirs = ccp4i.directories(source=directories)
        dirs.load(readonly=True)
        self.assertEqual(dirs.isreadable(),True,"Directories not readable")
        self.assertEqual(dirs.n_projects(),0,"Failed to get number of projects")
        self.assertEqual(dirs.listprojects(),[],"Failed to list projects")
        self.assertEqual(dirs.n_defdirs(),1,"Failed to get number of def dirs")
        self.assertEqual(dirs.listdefdirs(),["TEMPORARY"],"Failed to list def dirs")
        dirs.release()
        cleanDirectories(directories)

    def testReadonlyBlocksWrite(self):
        """Test that readonly load blocks writing."""

        directories = "test_directories.def"
        makeDirectories(directories)
        dirs = ccp4i.directories(source=directories)
        dirs.load(readonly=True)
        self.assertNotEqual(dirs.iswriteable(),True,
                            "Directories appears to be writeable")
        self.assertNotEqual(dirs.addprojectref("TEST_PROJ1","/a/random/dir"),True,
                            "Add project reference shouldn't be possible")
        self.assertNotEqual(dirs.save(),True,
                            "Save directories data shouldn't be possible")
        dirs.release()
        cleanDirectories(directories)

class DirectoriesCCP4iCompatibilityTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for CCP4i compatibility.

        This cleans up any previous test directories.def
        file, removes any leftover CCP4i lock, and creates
        a new test directories.def."""

        directories = "test_directories.def"
        cleanDirectories(directories)
        removeCCP4iDirLock(directories)
        makeDirectories(directories)        

    def tearDown(self):
        """Clean up after CCP4i compatibility test.

        This cleans up the test directories.def file and
        removes any leftover CCP4i lock."""

        directories = "test_directories.def"
        removeCCP4iDirLock(directories)
        cleanDirectories(directories)

    def testCCP4iAlreadyRunning(self):
        """Test that only read is possible if CCP4i is already active."""
        
        directories = "test_directories.def"
        # Make a fake directories.def.LOCK file
        ccp4i_lock = makeCCP4iDirLock(directories)
        # Set up the directories object
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(),True,"Failed to load")
        self.assertEqual(dirs.iswriteable(),False,"Directories is writeable")
        self.assertEqual(dirs.islockedbyccp4i(),True,
                         "Directories not locked by CCP4i")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertEqual(dirs.addprojectref("TEST_PROJ1","/a/random/dir"),False,
                         "Shouldn't be possible to add project reference")
        self.assertEqual(dirs.save(),False,
                         "Shouldn't be possible to save directories data")
        removeCCP4iDirLock(directories)
        # Clean up
        dirs.release()

    def testCCP4iBlocksWrite(self):
        """Test that writing is blocked when CCP4i locks the file.

        This test creates and loads a new directories object, writes
        new data to it and saves. It then creates an artificial CCP4i
        lock file and tries to write more data to the object and
        then tries to save.
        It also checks that the iswriteable, islockedbyccp4i and
        isstale methods return the expected values in both
        situations."""
        
        directories = "test_directories.def"
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(),True,"Failed to load")
        self.assertEqual(dirs.iswriteable(),True,"Directories not writeable")
        self.assertEqual(dirs.islockedbyccp4i(),False,
                         "Directories appears to be locked by CCP4i")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertEqual(dirs.addprojectref("TEST_PROJ1","/a/random/dir"),True,
                         "Failed to add project reference")
        self.assertEqual(dirs.save(),True,"Failed to save directories data")
        # Make a fake directories.def.LOCK file
        ccp4i_lock = makeCCP4iDirLock(directories)
        # Try to write another project reference
        self.assertNotEqual(dirs.iswriteable(),True,
                            "Directories should not be writeable")
        self.assertEqual(dirs.islockedbyccp4i(),True,
                         "Directories is not locked by CCP4i")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertNotEqual(dirs.addprojectref("TEST_PROJ2","/another/random/dir"),True,
                            "Adding project reference should have failed")
        self.assertNotEqual(dirs.save(),True,"Save should have failed")
        removeCCP4iDirLock(directories)
        # Clean up
        dirs.release()

    def testStaleBlocksWrite(self):
        """Test that writing is blocked when directories file is updated
        by a second process.

        This test creates and loads a new directories object, writes new
        data to it and saves. It then updates the modification time of
        the directories file to simulate the file being updated by
        another process. It then tries to write more data to the object
        and save again.
        It also checks that the iswriteable, islockedbyccp4i and
        isstale methods return the expected values in both
        situations."""
        
        directories = "test_directories.def"
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(),True,"Failed to load")
        self.assertEqual(dirs.iswriteable(),True,"Directories not writeable")
        self.assertEqual(dirs.islockedbyccp4i(),False,
                         "Directories is locked by CCP4i")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertEqual(dirs.addprojectref("TEST_PROJ1","/a/random/dir"),True,
                         "Failed to add project reference")
        self.assertEqual(dirs.save(),True,"Failed to save directories data")
        # Replace the directories.def file with a copy
        time.sleep(1)
        directories_copy = str(directories)+".copy"
        shutil.copy(directories,directories_copy)
        os.remove(directories)
        shutil.copy(directories_copy,directories)
        os.remove(directories_copy)
        # Attempt to write more data
        self.assertNotEqual(dirs.iswriteable(),True,
                            "Directories should not be writeable")
        self.assertEqual(dirs.islockedbyccp4i(),False,
                         "Directories appears to be locked by CCP4i")
        self.assertEqual(dirs.isstale(),True,
                         "Directories isn't stale")
        self.assertNotEqual(dirs.addprojectref("TEST_PROJ2","/another/random/dir"),True,
                            "Adding project reference should have failed")
        self.assertNotEqual(dirs.save(),True,"Save should have failed")
        # Clean up
        dirs.release()

    def testRefreshEnablesRead(self):
        """Refresh re-enable read access to a stale directories object."""

        directories = "test_directories.def"
        dirs = ccp4i.directories(source=directories)
        self.assertEqual(dirs.load(),True,"Failed to load")
        self.assertEqual(dirs.isreadable(),True,"Directories not readable")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertEqual(dirs.n_projects(),0,
                         "Failed to get (correct) number of projects")
        self.assertEqual(dirs.n_defdirs(),1,
                         "Failed to get (correct) number of defdirs")
        # Replace the directories.def file with a copy
        time.sleep(1)
        directories_copy = str(directories)+".copy"
        shutil.copy(directories,directories_copy)
        os.remove(directories)
        shutil.copy(directories_copy,directories)
        os.remove(directories_copy)
        # Attempt to refresh and read the data
        self.assertEqual(dirs.refresh(),True,"Refresh attempt failed")
        self.assertEqual(dirs.isreadable(),True,"Directories not readable")
        self.assertEqual(dirs.isstale(),False,"Directories isn't stale")
        self.assertEqual(dirs.n_projects(),0,
                         "Failed to get (correct) number of projects")
        self.assertEqual(dirs.n_defdirs(),1,
                         "Failed to get (correct) number of defdirs")
        # Clean up
        dirs.release()

    def testAutoRefreshOnRead(self):
        """Read on a stale directories object re-enables reading in auto_refresh mode."""

        directories = "test_directories.def"
        dirs = ccp4i.directories(source=directories)
        dirs.set_auto_refresh(True)
        self.assertEqual(dirs.load(),True,"Failed to load")
        self.assertEqual(dirs.isreadable(),True,"Directories not readable")
        self.assertEqual(dirs.isstale(),False,
                         "Directories appears to be stale")
        self.assertEqual(dirs.n_projects(),0,
                         "Failed to get (correct) number of projects")
        self.assertEqual(dirs.n_defdirs(),1,
                         "Failed to get (correct) number of defdirs")
        # Replace the directories.def file with a copy
        time.sleep(1)
        directories_copy = str(directories)+".copy"
        shutil.copy(directories,directories_copy)
        os.remove(directories)
        shutil.copy(directories_copy,directories)
        os.remove(directories_copy)
        # Attempt to read the data
        self.assertEqual(dirs.isreadable(),True,"Directories not readable")
        self.assertEqual(dirs.isstale(),False,"Directories isn't stale")
        self.assertEqual(dirs.n_projects(),0,
                         "Failed to get (correct) number of projects")
        self.assertEqual(dirs.n_defdirs(),1,
                         "Failed to get (correct) number of defdirs")
        # Clean up
        dirs.release()

class DatabaseTest(unittest.TestCase):

    def testCreate(self):
        """Test creating a new project.

        This test makes a new project using the database.create()
        method."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        db_dir = os.path.join(dir,"CCP4_DATABASE")
        db_file = os.path.join(db_dir,"database.def")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.create(),True,"Create operation failed")
        self.assertEqual(os.path.isdir(dir),True,
                         "Project directory not created")
        self.assertEqual(os.path.isdir(db_dir),True,
                         "Project database directory not created")
        self.assertEqual(os.path.exists(db_file),True,
                         "Project database file not created")
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.njobs(),0,
                         "Failed to get correct NJOBS")
        self.assertEqual(db.close(),True,"Failed to close database")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")

    def testOpen(self):
        """Testing opening an existing project.

        This test attempts to open an existing project which
        is manufactured for the test using the makeProject
        function."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.open(),True,"Open failed")
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.njobs(),0,
                         "Failed to get correct NJOBS")
        self.assertEqual(db.close(),True,"Failed to close database")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")

    def testLockBlocksOpen(self):
        """Testing that a lock blocks opening a project.

        This test tries to open an existing project which
        already has a lock file on the database."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        # Make a lock file
        makeDatabaseLock(dir)
        # Attempt to open
        self.assertNotEqual(db.open(),True,
                            "Open appears to have succeeded")
        self.assertEqual(db.isloaded(),False)
        self.assertEqual(db.isreadable(),False)
        self.assertEqual(db.iswriteable(),False)
        self.assertNotEqual(db.njobs(),0)
        self.assertNotEqual(db.close(),True,
                            "Close succeeded but database was not loaded")
        removeDatabaseLock(dir)
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")

    def testOpenGrabLock(self):
        """Testing opening a locked project using the 'grablock' option.
        
        This test tries to open an existing project which
        already has a lock file on the database, by grabbing
        the lock."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        # Make a lock file
        makeDatabaseLock(dir)
        # Attempt to open
        self.assertEqual(db.open(grablock=True),True,
                            "Open failed")
        self.assertEqual(db.isloaded(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.close(),True,
                            "Close failed")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")

    def testOpenLockedReadOnly(self):
        """Test opening a locked project using the 'readonly' option.

        This test tries to open an existing project which
        already has a lock file on the database, by specifying
        the readonly option of the 'open' method.
        Reading operations should be possible but not writing."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        # Make a lock file
        makeDatabaseLock(dir)
        # Attempt to open
        self.assertEqual(db.open(readonly=True),True,
                            "Readonly open failed")
        self.assertEqual(db.isloaded(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.close(),True,
                            "Close failed")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")

    def testOpenReadOnly(self):
        """Test opening a project using the 'readonly' option.

        This test tries to open an existing project, by specifying
        the readonly option of the 'open' method.
        Reading operations should be possible but not writing."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        # Attempt to open
        self.assertEqual(db.open(readonly=True),True,
                            "Readonly open failed")
        self.assertEqual(db.isloaded(),True)
        self.assertEqual(db.islocked(),False,"Project appears to be locked")
        self.assertEqual(db.haslock(),False,"Object appears to own the lock")
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.newjob(),-1,"Created a new job, but shouldn't be able to")
        self.assertEqual(db.close(),True,
                            "Close failed")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")
        
    def testNewJob(self):
        """Testing adding a new job.

        This test attempts to add a new job to a project, and checks
        that the job exists."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.open(),True,"Open failed")
        jobid = db.newjob(taskname="dummy",status="REPORTED",title="Dummy title")
        self.assertEqual(db.hasjob(jobid),True,"Failed to find new job")
        self.assertEqual(db.getdata(jobid,"TASKNAME"),"dummy",
                         "Retrieved taskname doesn't match")
        self.assertEqual(db.getdata(jobid,"STATUS"),"REPORTED",
                         "Retrieved status doesn't match")
        self.assertEqual(db.getdata(jobid,"TITLE"),"Dummy title",
                         "Retrieved status doesn't match")

    def testDeleteJob(self):
        """Testing removing a job.

        This test attempts to add a new job to a project, then deletes
        it and checks that it no longer exists."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.open(),True,"Open failed")
        jobid = db.newjob(taskname="dummy",status="REPORTED",title="Dummy title")
        self.assertEqual(db.hasjob(jobid),True,"Failed to find new job")
        db.deletejob(jobid)
        self.assertEqual(db.hasjob(jobid),False,"'Deleted' job still present")

    def testLookupNonexistentJob(self):
        """Testing look up of a job that doesn't exist.

        This test attempts to access data for a job id that
        doesn't exist."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.open(),True,"Open failed")
        njobs = db.njobs()
        testjob = njobs+100
        self.assertRaises(IndexError,db.getdata,testjob,"TITLE")

    def testNoBlankTaskname(self):
        """Testing adding a new job without specifying a taskname.

        This test attempts to add a new job to a project without
        specifying a taskname. It then attempts to set the taskname
        to an empty string. In all cases the taskname should not be
        blank when retrieved."""

        name = "CCP4IPY_TEST"
        dir = name
        cleanProject(dir)
        self.assertEqual(makeProject(name,dir),True,"Setup (create) failed")
        db = ccp4i.database(name,dir)
        self.assertEqual(db.open(),True,"Open failed")
        jobid = db.newjob()
        self.assertNotEqual(jobid,-1,"Failed to create a new job record")
        self.assertNotEqual(db.getdata(jobid,"TASKNAME"),"","Taskname is blank")
        self.assertEqual(db.setdata(jobid,"TASKNAME",""),False,
                         "setdata allowed blank taskname to be set")
        self.assertEqual(db.setdata(jobid,"TASKNAME","   \t"),False,
                         "setdata allowed blank taskname to be set")
        self.assertEqual(db.setdata(jobid,"TASKNAME","scala"),True,
                         "setdata didn't allow valid taskname to be set")
        jobid = db.newjob(taskname="")
        self.assertNotEqual(jobid,-1,"Failed to create a new job record")
        self.assertNotEqual(db.getdata(jobid,"TASKNAME"),"","Taskname is blank")
        self.assertEqual(db.close(),True,"Failed to close database")
        self.assertEqual(cleanProject(dir),True,"Failed to clean up")


class DatabaseAddFilesBasicTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for input/output file handling.

        This cleans up any previous test directories
        and project 'CCP4IPY_TEST', and creates and
        opens new ones for the test."""
        
        self.directories = "test_directories.def"
        self.dirs = ccp4i.directories(source=self.directories)
        self.dirs.create()
        self.project = "CCP4IPY_TEST"
        self.dir = "CCP4IPY_TEST"
        cleanProject(self.dir)
        self.dirs.addprojectref(self.project,self.dir)
        makeProject(self.project,self.dir)
        self.db = ccp4i.database(self.project,self.dir)
        self.db.open()
        self.db.newjob()

    def tearDown(self):
        """Clean up after an input/output file handling test.

        This closes and cleans up any previous test project
        'CCP4IPY_TEST' and directories file."""
        
        self.db.close()
        cleanProject(self.dir)
        self.dirs.release()
        cleanDirectories(self.directories)

    def testAddInputFile(self):
        """Testing that an input file reference is correctly added."""

        db = self.db
        dirs = self.dirs
        filen = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen,""),True,
                         "addfile operation failed")
        self.assertEqual(db.getdata(1,"INPUT_FILES")," test.dat",
                         "INPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"INPUT_FILES_DIR")," CCP4IPY_TEST",
                         "INPUT_FILES_DIR doesn't have the correct data")

    def testListInputFiles(self):
        """Testing that input file references are correctly listed."""

        db = self.db
        dirs = self.dirs
        filen0 = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        filen1 = dirs.fullfilename("test2.dat","CCP4IPY_TEST")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen0,""),True,
                         "First addfile operation failed")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen1,""),True,
                         "Second addfile operation failed")
        files = db.listfiles(1,"INPUT",dirs)
        self.assertEqual(files[0],filen0,"First stored file is incorrect")
        self.assertEqual(files[1],filen1,"Second stored file is incorrect")

    def testRemoveInputFile(self):
        """Testing that an input file reference is correctly removed."""

        db = self.db
        dirs = self.dirs
        filen0 = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        filen1 = dirs.fullfilename("test2.dat","CCP4IPY_TEST")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen0,""),True,
                         "First addfile operation failed")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen1,""),True,
                         "Second addfile operation failed")
        files = db.listfiles(1,"INPUT",dirs)
        self.assertEqual(files[0],filen0,"First stored file is incorrect")
        self.assertEqual(files[1],filen1,"Second stored file is incorrect")
        self.assertEqual(db.removefile(1,"INPUT",dirs,filen0),True,
                         "Removing first file reported failure")
        self.assertEqual(db.getdata(1,"INPUT_FILES")," test2.dat",
                         "INPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"INPUT_FILES_DIR")," CCP4IPY_TEST",
                         "INPUT_FILES_DIR doesn't have the correct data")

    def testAddDuplicateFile(self):
        """Test that attempting to add a duplicate file reference fails."""

        db = self.db
        dirs = self.dirs
        filen0 = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        filen1 = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen0,""),True,
                         "First addfile operation failed")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen1,""),True,
                            "Second addfile operation failed")
        files = db.listfiles(1,"INPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(files[0],filen0,"First stored file is incorrect")
        self.assertEqual(db.getdata(1,"INPUT_FILES")," test.dat",
                         "INPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"INPUT_FILES_DIR")," CCP4IPY_TEST",
                         "INPUT_FILES_DIR doesn't have the correct data")

    def testProtectSpacesInName(self):
        """Test that spaces in file names are preserved on recovery"""

        db = self.db
        dirs = self.dirs
        filen0 = dirs.fullfilename("test 1.dat","CCP4IPY_TEST")
        filen1 = dirs.fullfilename("test 2.dat","CCP4IPY_TEST")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen0,""),True,
                         "First addfile operation failed")
        self.assertEqual(db.addfile(1,"INPUT",dirs,filen1,""),True,
                         "Second addfile operation failed")
        files = db.listfiles(1,"INPUT",dirs)
        self.assertEqual(len(files),2,"Wrong number of files listed")
        self.assertEqual(files[0],filen0,"First stored file is incorrect")
        self.assertEqual(files[1],filen1,"Second stored file is incorrect")
        self.assertEqual(db.getdata(1,"INPUT_FILES")," { test 1.dat } { test 2.dat }",
                         "INPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"INPUT_FILES_DIR")," CCP4IPY_TEST CCP4IPY_TEST",
                         "INPUT_FILES_DIR doesn't have the correct data")

class DatabaseAddFilesAdvancedTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for input/output file handling.

        This cleans up any previous test directories
        and project 'CCP4IPY_TEST', and creates and
        opens new ones for the test."""
        
        self.directories = "test_directories.def"
        self.dirs = ccp4i.directories(source=self.directories)
        self.dirs.create()
        self.project = "CCP4IPY_TEST"
        self.dir = "CCP4IPY_TEST"
        cleanProject(self.dir)
        self.dirs.addprojectref(self.project,self.dir)
        makeProject(self.project,self.dir)
        self.db = ccp4i.database(self.project,self.dir)
        self.db.open()
        self.db.newjob()

    def tearDown(self):
        """Clean up after an input/output file handling test.

        This closes and cleans up any previous test project
        'CCP4IPY_TEST' and directories file."""
        
        self.db.close()
        cleanProject(self.dir)
        self.dirs.release()
        cleanDirectories(self.directories)

    def testAddFileNameNoAlias(self):
        """Test adding an output file with name only and no alias."""

        # Filename is "test.dat", alias is blank
        # addfile should add it as "test.dat" in project "CCP4IPY_TEST"
        db = self.db
        dirs = self.dirs
        filen = "test.dat"
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,""),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        filen = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        self.assertEqual(files[0],filen,"First stored file is incorrect")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES")," test.dat",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," CCP4IPY_TEST",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileNameAlias(self):
        """Test adding an output file with with name only and valid alias."""
        
        # Filename is "test.dat", alias is set to "CCP4IPY_TEST"
        # addfile should add it as "test.dat" in project "CCP4IPY_TEST"
        db = self.db
        dirs = self.dirs
        filen = "test.dat"
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"CCP4IPY_TEST"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        filen = dirs.fullfilename("test.dat","CCP4IPY_TEST")
        self.assertEqual(files[0],filen,"First stored file is incorrect")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES")," test.dat",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," CCP4IPY_TEST",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileNameBadAlias(self):
        """Test adding an output file with name only and an invalid alias."""
        
        # Filename is "test.dat", alias is set to "_BAD_ALIAS_"
        # addfile should fail to add it
        db = self.db
        dirs = self.dirs
        filen = "test.dat"
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"_BAD_ALIAS_"),False,
                         "addfile operation should have failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),0,"Wrong number of files listed")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES"),"",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR"),"",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileRelativePathNoAlias(self):
        """Test adding an output file with relative path and no alias."""

        # Filename is "1_test/test.dat", alias is blank
        # addfile should add it as a full filename ".../1_test/test.dat"
        # with alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join("1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,""),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        filen = dirs.fullfilename(filen,"CCP4IPY_TEST")
        self.assertEqual(os.path.normcase(files[0]),
                         os.path.normcase(filen),
                         "First stored file is incorrect")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileRelativePathAlias(self):
        """Test adding an output file with relative path and alias."""
        
        # Filename is "1_test/test.dat", alias is set to "CCP4IPY_TEST"
        # addfile should add it as a full filename ".../1_test/test.dat"
        # with alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join("1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"CCP4IPY_TEST"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        filen = dirs.fullfilename(filen,"CCP4IPY_TEST")
        self.assertEqual(os.path.normcase(files[0]),
                         os.path.normcase(filen),
                         "First stored file is incorrect")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileRelativePathBadAlias(self):
        """Test adding an output file with relative path and a bad alias."""
        
        # Filename is "1_test/test.dat", alias is set to "_BAD_ALIAS_"
        # addfile should fail to add it
        db = self.db
        dirs = self.dirs
        filen = os.path.join("1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"_BAD_ALIAS_"),False,
                         "addfile operation should have failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),0,"Wrong number of files listed")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES"),"",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR"),"",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileFullPathNoAlias(self):
        """Test adding an output file with full path and no alias."""

        # Filename is ".../CCP4IPY_TEST/test.dat", alias is blank
        # addfile should add it as "test.dat" with alias "CCP4IPY_TEST"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,""),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(files[0],filen,"First stored file is incorrect")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES")," test.dat",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," CCP4IPY_TEST",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileFullPathAlias(self):
        """Test adding an output file with full path and alias."""
        
        # Filename is ".../CCP4IPY_TEST/test.dat", alias is set to
        # "CCP4IPY_TEST"
        # addfile should add it as "test.dat" with alias "CCP4IPY_TEST"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"CCP4IPY_TEST"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(files[0],filen,"First stored file is incorrect")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES")," test.dat",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," CCP4IPY_TEST",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddFileFullPathBadAlias(self):
        """Test adding an output file with full path and a bad alias."""
        
        # Filename is ".../CCP4IPY_TEST/test.dat", alias is set to
        # "_BAD_ALIAS_"
        # addfile should ignore the alias and add it as full filename
        # "test.dat" with alias "CCP4IPY_TEST"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"_BAD_ALIAS_"),True,
                         "addfile failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES")," test.dat",
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," CCP4IPY_TEST",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddArbitraryFileNoAlias(self):
        """Test adding an arbitrary output file with full path and no alias."""

        # Filename is ".../1_test/test.dat", alias is blank
        # addfile should add it as full filename ".../test.dat" with
        # alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,""),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(os.path.normcase(files[0]),
                         os.path.normcase(filen),
                         "First stored file is incorrect")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddArbitraryFileAlias(self):
        """Test adding an arbitrary output file with full path and alias."""
        
        # Filename is ".../CCP4IPY_TEST/1_test/test.dat", alias is set to
        # "CCP4IPY_TEST"
        # addfile should ignore the alias and add it as full filename
        # ".../CCP4IPY_TEST/1_test/test.dat" with alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"CCP4IPY_TEST"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        self.assertEqual(os.path.normcase(files[0]),
                         os.path.normcase(filen),
                         "First stored file is incorrect")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddArbitraryFileBadAlias(self):
        """Test adding an arbitrary output file with full path and bad alias."""
        
        # Filename is ".../CCP4IPY_TEST/1_test/test.dat", alias is set to
        # "_BAD_ALIAS_"
        # addfile should ignore the alias and add it as full filename
        # ".../CCP4IPY_TEST/1_test/test.dat" with alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.path.abspath(self.dir),"1_test","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"_BAD_ALIAS_"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

    def testAddArbitraryFileWrongAlias(self):
        """Test adding an arbitrary output file with full path and wrong alias."""
        
        # Filename is ".../ANOTHER_PROJECT/test.dat", alias is set to
        # "CCP4IPY_TEST"
        # addfile should ignore the alias and add it as full filename
        # ".../CCP4IPY_TEST/1_test/test.dat" with alias "FULL_PATH"
        db = self.db
        dirs = self.dirs
        filen = os.path.join(os.getcwd(),"ANOTHER_PROJECT","test.dat")
        self.assertEqual(db.addfile(1,"OUTPUT",dirs,filen,"CCP4IPY_TEST"),True,
                         "addfile operation failed")
        files = db.listfiles(1,"OUTPUT",dirs)
        self.assertEqual(len(files),1,"Wrong number of files listed")
        # Construct the expected value of OUTPUT_FILES
        # Need to accommodate spaces in the filename if present
        if str(filen).count(" ") > 0:
            # Filename contains spaces
            expect_output_files = " { "+str(filen)+" }"
        else:
            # No spaces
            expect_output_files = " "+str(filen)
        self.assertEqual(os.path.normcase(db.getdata(1,"OUTPUT_FILES")),
                         os.path.normcase(expect_output_files),
                         "OUTPUT_FILES doesn't have the correct data")
        self.assertEqual(db.getdata(1,"OUTPUT_FILES_DIR")," FULL_PATH",
                         "OUTPUT_FILES_DIR doesn't have the correct data")

class DatabaseCCP4iCompatibilityTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for CCP4i compatibility.

        This cleans up any previous test project
        'CCP4IPY_TEST' and creates a new test project."""

        self.project = "CCP4IPY_TEST"
        self.dir = "CCP4IPY_TEST"
        cleanProject(self.dir)
        makeProject(self.project,self.dir)

    def tearDown(self):
        """Clean up after CCP4i compatibility test.

        This cleans up any previous test project
        'CCP4IPY_TEST'."""
        cleanProject(self.dir)

    def testStaleBlocksWrite(self):
        """Testing that write is not permitted when database file is
        newer than the data in the object."""

        db = ccp4i.database(self.project,self.dir)
        self.assertEqual(db.open(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.isstale(),False)
        updateDatabase(self.dir)
        self.assertEqual(db.isstale(),True)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.close(),True,"Close failed")
        
    def testRefreshAllowsRead(self):
        """Testing that refreshing a stale database re-enables reading."""

        db = ccp4i.database(self.project,self.dir)
        self.assertEqual(db.open(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.isstale(),False)
        updateDatabase(self.dir)
        self.assertEqual(db.isstale(),True)
        self.assertEqual(db.isreadable(),False)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.refresh(),True,"Refresh operation failed")
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.isstale(),False)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.close(),True,"Close failed")
        
    def testRefreshGrablockAllowsReadWrite(self):
        """Testing that refreshing a stale database with grablock re-enables reading and writing."""

        db = ccp4i.database(self.project,self.dir)
        self.assertEqual(db.open(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.isstale(),False)
        updateDatabase(self.dir)
        self.assertEqual(db.isstale(),True)
        self.assertEqual(db.isreadable(),False)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.refresh(grablock=True,readonly=False),True, \
                         "Refresh grablock operation failed")
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.isstale(),False)
        self.assertEqual(db.iswriteable(),True,"Project should be writeable again")
        self.assertEqual(db.close(),True,"Close failed")

    def testAutoRefreshOnRead(self):
        """Read on a stale database re-enables reading for auto_refresh mode."""

        db = ccp4i.database(self.project,self.dir)
        db.set_auto_refresh(True)
        self.assertEqual(db.open(),True)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.iswriteable(),True)
        self.assertEqual(db.isstale(),False)
        updateDatabase(self.dir)
        self.assertEqual(db.isstale(),True)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.isreadable(),True)
        self.assertEqual(db.njobs(),0,"Failed to get correct NJOBS")
        self.assertEqual(db.isstale(),False)
        self.assertEqual(db.iswriteable(),False)
        self.assertEqual(db.close(),True,"Close failed")

class ProjectDbTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for subjob support.

        This cleans up any previous test project
        'CCP4IPY_TEST' and creates a new test project."""

        self.project = "CCP4IPY_TEST"
        self.dir = "CCP4IPY_TEST"
        cleanProject(self.dir)
        makeProject(self.project,self.dir)
        self.db = ccp4i.projectDB(self.project,self.dir)
        self.db.open()

    def tearDown(self):
        """Clean up after subjob support test.

        This cleans up any previous test project
        'CCP4IPY_TEST'."""

        # Remove all subjobs
        for job in self.db.listjobs_withsubjobs():
            for subjob in self.db.listjobs(job):
                self.db.deletejob(subjob)
        self.db.close()
        cleanProject(self.dir)

    def testCreateSubjob(self):
        """Test creating a new subjob.

        This test makes a new job and then a subjob for
        that job."""
        db = self.db
        job = db.newjob()
        self.assertEqual(db.has_subjobs(job),False)
        subjob = db.addsubjob(job,"test","testCreateSubjob","REPORTED")
        self.assertEqual(db.has_subjobs(job),True)

class HistoryTest(unittest.TestCase):

    def setUp(self):
        """Initialise a test for history class.

        This cleans up any previous test project
        'CCP4IPY_TEST' and creates a new test project."""

        # Set up directories object
        self.directories = "test_directories.def"
        makeDirectories(self.directories)
        self.dirs = ccp4i.directories(source=self.directories)
        self.dirs.load()
        # Set up database object
        self.project = "CCP4IPY_TEST"
        self.dir = "CCP4IPY_TEST"
        cleanProject(self.dir)
        makeProject(self.project,self.dir)
        self.db = ccp4i.database(self.project,self.dir)
        self.db.open()
        self.dirs.addprojectref(self.project,self.dir)
        # Put some fake data into the project
        # to use in the tests
        jobid1 = self.db.newjob(taskname="test",
                               status="FINISHED",
                               title="Test job")
        self.db.addoutputfile(jobid1,self.dirs,"test1.dat","")
        jobid2 = self.db.newjob(taskname="test",
                               status="FINISHED",
                               title="Test job")
        self.db.addoutputfile(jobid2,self.dirs,"test2.dat","")
        jobid3 = self.db.newjob(taskname="test",
                               status="FINISHED",
                               title="Test job")
        self.db.addinputfile(jobid3,self.dirs,"test1.dat","")
        jobid4 = self.db.newjob(taskname="test",
                               status="FINISHED",
                               title="Test job")
        self.db.addinputfile(jobid4,self.dirs,"test1.dat","")
        self.db.addinputfile(jobid4,self.dirs,"test2.dat","")
        # Record the expected relationships here
        self.jobs = []
        self.jobs.append(jobid1)
        self.jobs.append(jobid2)
        self.jobs.append(jobid3)
        self.jobs.append(jobid4)
        self.parentsof = dict()
        self.parentsof[jobid1] = []
        self.parentsof[jobid2] = []
        self.parentsof[jobid3] = []
        self.parentsof[jobid4] = []
        self.parentsof[jobid3].append(jobid1)
        self.parentsof[jobid4].append(jobid1)
        self.parentsof[jobid4].append(jobid2)
        self.childrenof = dict()
        self.childrenof[jobid1] = []
        self.childrenof[jobid2] = []
        self.childrenof[jobid3] = []
        self.childrenof[jobid4] = []
        self.childrenof[jobid1].append(jobid3)
        self.childrenof[jobid1].append(jobid4)
        self.childrenof[jobid2].append(jobid4)

    def tearDown(self):
        """Clean up after history class test.

        This cleans up any previous test project
        'CCP4IPY_TEST'."""
        self.db.close()
        self.dirs.release()
        cleanProject(self.dir)
        cleanDirectories(self.directories)

    def testHistoryConstruct(self):
        """Test constructing a history instance."""
        hist = ccp4i.history(self.db,self.dirs)
        hist.construct()

    def testHistoryParentsOf(self):
        """Test that parentsof method returns the correct data.

        Compare the data returned from the history object
        with the expected data defined in the setUp method."""
        hist = ccp4i.history(self.db,self.dirs)
        hist.construct()
        for jobid in self.jobs:
            # Compare the stored relations with those
            # returned from the history object
            self.assertEqual(hist.parentsof(jobid),
                             self.parentsof[jobid],
                             "List of parents doesn't agree")

    def testHistoryChildrenOf(self):
        """Test that childrenof method returns the correct data.

        Compare the data returned from the history object
        with the expected data defined in the setUp method."""
        hist = ccp4i.history(self.db,self.dirs)
        hist.construct()
        for jobid in self.jobs:
            # Compare the stored relations with those
            # returned from the history object
            self.assertEqual(hist.childrenof(jobid),
                             self.childrenof[jobid],
                             "List of children doesn't agree")

#############################################################
# Supporting functions
#############################################################
        
def cleanDirectories(directories_file):
    """Supporting function: do clean up before/after tests.

    Given the name of a directories.def file, remove the file
    and any associated lock, if found."""
    
    # Get rid of pre-existing directories.def and LOCK files
    if ccp4i.FileExists(directories_file):
        os.remove(directories_file)
    lock = str(ccp4i.GetFileRootname(directories_file))+".LOCK"
    if ccp4i.FileExists(lock):
        os.remove(lock)

def makeDirectories(directories_file):
    """Supporting function: create new directories file for tests.

    Given the name of a directories.def, make the file if it
    doesn't already exist."""
    
    dirs = ccp4i.directories(source=directories_file)
    status = dirs.create()
    dirs.release()
    return status

def makeCCP4iDirLock(directories_file):
    """Supporting function: create a fake CCP4i lock file for directories.

    Makes a CCP4i-style lock file for the named directories file,
    and returns the lock file name. Invoke the removeCCP4iDirLock
    function to clean up afterwards."""

    ccp4i_lock = directories_file+".LOCK"
    if not ccp4i.FileExists(ccp4i_lock):
        flock = open(ccp4i_lock,"w")
        flock.write("Lock file for RUN_MODE\n")
        flock.write("Created by USER_ID\n")
        flock.write("Date DATE_STRING\n")
        flock.write("Owned by pid PID\n")
        flock.close()
    return ccp4i_lock

def removeCCP4iDirLock(directories_file):
    """Supporting function: removes the CCP4i lock on a directories file.

    Supply the name of the directories file being locked
    in order to remove the lock."""
    
    ccp4i_lock = directories_file+".LOCK"
    if ccp4i.FileExists(ccp4i_lock):
        os.remove(ccp4i_lock)

def cleanProject(dir):
    """Supporting function: removes a project directory.

    Supply the name of the project directory. Also cleans up
    any leftover lock file on the database."""

    if not os.path.isdir(dir):
        return False
    db_dir = os.path.join(dir,"CCP4_DATABASE")
    db_file = os.path.join(db_dir,"database.def")
    removeDatabaseLock(dir)
    if os.path.exists(db_file):
        os.remove(db_file)
    if os.path.isdir(db_dir):
        os.rmdir(db_dir)
    os.rmdir(dir)
    return not os.path.isdir(dir)
    
def makeProject(name,dir):
    """Supporting function: creates a new project.

    Supply the name of the project and a directory."""

    db_dir = os.path.join(dir,"CCP4_DATABASE")
    db_file = os.path.join(db_dir,"database.def")
    db = ccp4i.database(name,dir)
    if not db.create():
        return False
    db.close()
    if not os.path.isdir(dir) or \
       not os.path.isdir(db_dir) or \
       not os.path.exists(db_file):
        return False
    return True

def makeDatabaseLock(dir,overwrite=True):
    """Supporting function: create a database lock file.

    Makes a new database lock file for the named project
    directory, and returns the lock file name. Invoke the
    removeDatabaseLock function to clean up afterwards."""

    db_lock = os.path.join(dir,"CCP4_DATABASE","database.LOCK")
    if ccp4i.FileExists(db_lock) and overwrite:
        os.remove(db_lock)
    flock = open(db_lock,"w")
    flock.write("Lock file for PROJECT\n")
    flock.write("Created by USER_ID\n")
    flock.write("Date DATE_STRING\n")
    flock.write("Owned by pid PID\n")
    flock.write("Server port PORT\n")
    flock.close()
    return db_lock

def removeDatabaseLock(dir):
    """Supporting function: remove the lockfile for a database.

    Supply the project directory name."""
    
    lock_file = os.path.join(dir,"CCP4_DATABASE","database.LOCK")
    if os.path.exists(lock_file):
        return os.remove(lock_file)
    else:
        return False

def updateDatabase(dir):
    """Supporting function: make the database file newer by
    1 second.

    Do this by replacing the database.def file with a copy."""

    db_file = os.path.join(dir,"CCP4_DATABASE","database.def")
    time.sleep(1)
    db_copy = str(db_file)+".copy"
    shutil.copy(db_file,db_copy)
    os.remove(db_file)
    os.rename(db_copy,db_file)

if __name__ == "__main__":
    unittest.main()
