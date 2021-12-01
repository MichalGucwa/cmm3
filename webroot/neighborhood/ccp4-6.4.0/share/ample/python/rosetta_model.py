'''
Created on 21 Feb 2013

@author: jmht
'''

# Python modules
import glob
import logging
import os
import random
import re
import shutil
import subprocess
import sys
import time
import unittest

# Our modules
import add_sidechains_SCWRL
import ample_util
import octopus_predict


class RosettaModel(object):
    """
    Class to run Rosetta modelling
    """

    def __init__(self):
        
        self.nproc = None
        self.nmodels = None
        self.work_dir = None
        self.models_dir = None
        self.rosetta_dir = None
        self.rosetta_path = None
        self.rosetta_cm = None
        self.rosetta_db = None
        self.rosetta_version = None
        
        # Not used yet
        self.make_models = None
        self.make_fragments = None

        self.fasta = None
        self.all_atom = None
        self.use_scwrl = None
        self.scwrl_exe = None
        
        # Fragment variables
        self.pdb_code = None
        self.frags_3mers = None
        self.frags_9mers = None
        self.use_homs = None
        self.fragments_directory = None
        self.fragments_exe = None
        
        # Transmembrane variables
        self.transmembrane = None
        self.octopus2span = None
        self.run_lips = None
        self.align_blast = None
        self.nr = None
        self.blastpgp = None
        self.spanfile = None
        self.lipofile = None
        
        # List of seeds
        self.seeds = None
        
        # Extra options
        self.domain_termini_distance = None
        self.rad_gyr_reweight = None
        self.improve_template = None
        
        self.logger = logging.getLogger()
    
    def generate_seeds(self, nseeds):
        """
        Generate a list of nseed seeds
        """
        
        seed_list = []

        # Generate the list of random seeds
        while len(seed_list) < nseeds:
            seed = random.randint(1000000, 4000000)
            if seed not in seed_list:
                seed_list.append(seed)
                
        # Keep a log of the seeds
        seedlog = open( self.work_dir + os.sep +'seedlist', "w")
        for seed in  seed_list:
            seedlog.write(str(seed) + '\n')
        seedlog.close()
        
        self.seeds = seed_list
        return
    ##End generate_seeds
    
    def split_jobs(self):
        """
        Return a list of number of jobs to run on each processor
        """
        split_jobs = self.nmodels / self.nproc  # split jobs between processors
        remainder = self.nmodels % self.nproc
        jobs = []
 
	for i in range(self.nproc):
            njobs = split_jobs
            # Separate out remainder over jobs
            if remainder > 0:
                njobs += 1
                remainder -= 1
            jobs.append( njobs )
        
        return jobs
    ##End split_jobs
    
    def fragment_cmd(self):
        """
        Return the command to make the fragments as a list
        
        """
        # Set path to script
        if not self.fragments_exe: 
            if self.rosetta_version == 3.3:
                self.fragments_exe = self.rosetta_dir + '/rosetta_fragments/make_fragments.pl'
            elif self.rosetta_version  == 3.4:
                self.fragments_exe = self.rosetta_dir + '/rosetta_tools/fragment_tools/make_fragments.pl'
        
        # It seems that the script can't tolerate "-" in the directory name leading to the fasta file,
        # so we need to copy the fasta file into the fragments directory and just use the name here
        fasta = os.path.split(  self.fasta )[1]
         
        cmd = [ self.fragments_exe,
               '-rundir', self.fragments_directory,
               '-id', self.pdb_code, fasta ] 
        
        if self.transmembrane:
            cmd += [ '-noporter', '-nopsipred','-sam'] 
        else:
            # version dependent flags
            if self.rosetta_version == 3.3:
                # jmht the last 3 don't seem to work with 3.4
                cmd += ['-noporter', '-nojufo', '-nosam','-noprof' ]
            elif self.rosetta_version == 3.4:
                cmd += ['-noporter' ]

        # Whether to exclude homologs
        if not self.use_homs:
            cmd.append('-nohoms')           
        
        return cmd
    ##End fragment_cmd
            

    def generate_fragments(self):
        """
        Run the script to generate the fragments
        
        """
    
        self.logger.info('----- making fragments--------')
        #RUNNING.write('----- making fragments--------\n')
        #RUNNING.flush()
        
        if not os.path.exists( self.fragments_directory ):
            os.mkdir( self.fragments_directory )
            
        # It seems that the script can't tolerate "-" in the directory name leading to the fasta file,
        # so we need to copy the fasta file into the fragments directory
        fasta = os.path.split(  self.fasta )[1]
        shutil.copy2( self.fasta, self.fragments_directory + os.sep + fasta )
        
#        if self.transmembrane:
#            self.generate_tm_predict()        
            
        cmd = self.fragment_cmd()
        logfile = os.path.join( self.fragments_directory, "make_fragments.log" )
        retcode = ample_util.run_command( cmd, logfile=logfile, directory=self.fragments_directory )
        if retcode != 0:
            msg = "Error generating fragments!\nPlease check the logfile {0}".format( logfile )
            self.logger.critical( msg )
            raise RuntimeError, msg
        
        if self.rosetta_version >= 3.4:
            # new name format: $options{runid}.$options{n_frags}.$size" . "mers
            self.frags_3mers = self.fragments_directory + os.sep + self.pdb_code + '.200.3mers'
            self.frags_9mers = self.fragments_directory + os.sep + self.pdb_code + '.200.9mers'      
        else:
            # old_name_format: aa$options{runid}$fragsize\_05.$options{n_frags}\_v1_3"
            self.frags_3mers = self.fragments_directory + os.sep + 'aa' + self.pdb_code + '03_05.200_v1_3'
            self.frags_9mers = self.fragments_directory + os.sep + 'aa' + self.pdb_code + '09_05.200_v1_3'
            
        if not os.path.exists( self.frags_3mers ) or not os.path.exists( self.frags_9mers ):
            raise RuntimeError, "Error making fragments - could not find fragment files:\n{0}\n{1}\n".format(self.frags_3mers,self.frags_9mers)
        
        #RUNNING.write('Fragments done\n3mers at: ' + frags_3_mers + '\n9mers at: ' + frags_9_mers + '\n\n')
        self.logger.info('Fragments Done\n3mers at: ' + self.frags_3mers + '\n9mers at: ' + self.frags_9mers + '\n\n')
    
        if os.path.exists( self.fragments_directory + os.sep + self.fragments_directory + '.psipred'):
            ample_util.get_psipred_prediction( self.fragments_directory + os.sep + self.pdb_code + '.psipred')
       
        return
    ##End fragment_cmd
    
    
    def generate_tm_predict(self):
        """
        Generate the various files needed for modelling transmembrane proteins
        
        REM the fasta as it needs to reside in this directory or the script may fail 
        due to problems with parsing directory names with 'funny' characters
        """
        
        # Files have already been created
        if os.path.isfile( str(self.spanfile) ) and os.path.isfile( str(self.lipofile) ):
            self.logger.debug("Using given span file: {0}\n and given lipo file: {1}".format( self.spanfile, self.lipofile ) )
            return
        
        # It seems that the script can't tolerate "-" in the directory name leading to the fasta file,
        # so we need to copy the fasta file into the fragments directory
        fasta = os.path.split(  self.fasta )[1]
        shutil.copy2( self.fasta, self.models_dir + os.sep + fasta )
        
        # Query octopus server for prediction
        octo = octopus_predict.OctopusPredict()
        self.logger.info("Generating predictions for transmembrane regions using octopus server: {0}".format(octo.octopus_url))
        #fastaseq = octo.getFasta(self.fasta)
        # Problem with 3LBW predicition when remove X
        fastaseq = octo.getFasta(self.fasta)
        octo.getPredict(self.pdb_code,fastaseq, directory=self.models_dir )
        topo_file = octo.topo
        self.logger.debug("Got topology prediction file: {0}".format(topo_file))

        # Generate span file from predict
        self.spanfile = os.path.join(self.models_dir, self.pdb_code + ".span")
        self.logger.debug( 'Generating span file {0}'.format( self.spanfile ) )
        cmd = [ self.octopus2span, topo_file ]
        retcode = ample_util.run_command( cmd, logfile=self.spanfile, directory=self.models_dir )
        if retcode != 0:
            msg = "Error generating span file. Please check the log in {0}".format(self.spanfile)
            self.logger.critical(msg)
            raise RuntimeError,msg
        
        # Now generate lips file
        self.logger.debug('Generating lips file from span')
        logfile = self.models_dir + os.sep + "run_lips.log"
        cmd = [ self.run_lips, fasta, self.spanfile, self.blastpgp, self.nr, self.align_blast ]
        retcode = ample_util.run_command( cmd, logfile=logfile, directory=self.models_dir )
        
        # Script only uses first 4 chars to name files
        lipofile = os.path.join(self.models_dir, self.pdb_code[0:4] + ".lips4")
        if retcode != 0 or not os.path.exists(lipofile):
            msg = "Error generating lips file {0}. Please check the log in {1}".format(lipofile,logfile)
            self.logger.critical(msg)
            raise RuntimeError,msg
        
        # Set the variable
        self.lipofile = lipofile
        
        return
    
    def get_version(self):
        """ Return the Rosetta version as a string"""
        
        if not self.rosetta_version:
            # Get version
            version = None
            version_file = self.rosetta_dir + '/README.version'
            if os.path.exists(version_file):
                try:
                    for line in open(version_file,'r'):
                        line.strip()
                        if line.startswith('Rosetta'):
                            tversion = line.split()[1].strip()
                            # version can be 3 digits - e.g. 3.2.4 - we only care about 2
                            version = float( ".".join(tversion.split(".")[0:2]) )
                    #self.logger.info( 'Your Rosetta version is: {0}'.format( version ) )
                except Exception,e:
                    self.logger.critical("Error determining rosetta version: {0}".format(e))
                    sys.exit(1)
                                
            else:
                # Version file is absent in 3.5, so we need to use the directory name
                self.logger.debug('Version file for Rosetta not found - checking to see if its 3.5')
                dirname = os.path.basename( self.rosetta_dir )
                if dirname.endswith( os.sep ):
                    dirname = dirname[:-1]
                if dirname.endswith("3.5"):
                    version = 3.5
                else:
                    self.logger.critical("Error determining rosetta version: {0}".format(e))
                    sys.exit(1)
                
            self.rosetta_version = version
        else:
            self.logger.debug( 'Using user-supplied Rosetta version' )
        
        self.logger.info( 'Your Rosetta version is: {0}'.format( self.rosetta_version ) )  
        return self.rosetta_version
    #End get_version 
    
    def modelling_cmd(self, wdir, nstruct, seed):
        """
        Return the command to run rosetta as a list suitable for subprocess
        wdir: directory to run in
        nstruct: number of structures to process
        seed: seed for this processor
        """
        
        # Set executable
        if self.transmembrane:
            cmd = [ self.transmembrane_exe ]
        else:
             cmd = [ self.rosetta_path ]
        
        cmd += ['-database', self.rosetta_db,
                '-in::file::fasta', self.fasta,
                '-in:file:frag3', self.frags_3mers,
                '-in:file:frag9', self.frags_9mers,
                '-out:path', wdir,
                '-out:pdb',
                '-out:nstruct', str(nstruct),
                '-out:file:silent', wdir + '/OUT',
                '-run:constant_seed',
                '-run:jran', str(seed) 
                ]
            
        if self.all_atom:
            cmd += [ '-return_full_atom true', '-abinitio:relax' ]
        else:
            cmd += [ '-return_full_atom false' ]
            
        if self.transmembrane:
            cmd += [ '-in:file:spanfile', self.spanfile,
                     '-in:file:lipofile', self.lipofile,
                     '-abinitio:membrane',
                     '-membrane:no_interpolate_Mpair',
                     '-membrane:Menv_penalties',
                     '-score:find_neighbors_3dgrid',
                     '-membrane:normal_cycles', '40',
                     '-membrane:normal_mag', '15',
                     '-membrane:center_mag', '2',
                     '-mute core.io.database',
                     '-mute core.scoring.MembranePotential' 
                    ]
            
        # Domain constraints
        if self.domain_termini_distance > 0:
            dcmd = self.setup_domain_constraints()
            cmd += dcmd
            
        # Radius of gyration reweight
        if self.rad_gyr_reweight:
            if "none" in self.rad_gyr_reweight.lower():
                cmd+= ['-rg_reweight', '0']
                
        # Improve Template
        if self.improve_template:
            cmd += ['-in:file:native',
                    self.improve_template,
                    '-abinitio:steal_3mers',
                    'True',
                    '-abinitio:steal9mers',
                    'True',
                    '-abinitio:start_native',
                    'True',
                    '-templates:force_native_topology',
                    'True' ]
        
        return cmd
    ##End make_rosetta_cmd
    
    
    def doModelling(self):
        """
        Run the modelling and return the path to the models directory
        """

        # Should be done by main script
        if not os.path.isdir( self.models_dir ):
            os.mkdir(self.models_dir)
            
        if self.transmembrane:
            self.generate_tm_predict()    

        # Now generate the seeds
        self.generate_seeds( self.nproc )
        jobs = self.split_jobs()

        # List of processes so we can check when they are done
        processes = []
        # dict mapping process to directories
        directories = {}
        for proc in range(1,self.nproc+1):
            
            # Get directory to run job in 
            wdir = self.models_dir + os.sep + 'models_' + str(proc)
            directories[wdir] = proc
            os.mkdir(wdir)
            
            # Generate the command for this processor
            seed = str(self.seeds[proc-1])
            nstruct = str(jobs[proc-1])
            cmd = self.modelling_cmd( wdir, nstruct, seed )
            
            self.logger.debug('Making {0} models in directory: {1}'.format(nstruct,wdir) )
            self.logger.debug('Executing cmd: {0}'.format( " ".join(cmd) ) )
            
            logf = open(wdir+os.sep+"rosetta_{0}.log".format(proc),"w")
            p = subprocess.Popen( cmd, stdout=logf, stderr=subprocess.STDOUT, cwd=wdir )
            processes.append(p)
            
        #End spawning loop
        
        # Check to see if they have finished
        done=False
        completed=0
        retcodes = [None]*len(processes) # To hold return codes
        while not done:
            time.sleep(5)
            for i, p in enumerate(processes):
                if retcodes[i] != None:
                    continue
                ret = p.poll()
                if ret != None:
                    retcodes[i] = ret
                    completed+=1
            
            if completed == len(processes):
                break
    
        # Check the return codes
        for i, ret in enumerate(retcodes):
            if ret != 0:
                #print "CHECK RET {0} : {1}".format(i,ret)
                msg = "Error generating models with Rosetta!\nGot return code {0} for processor: {1}".format(ret,i+1)
                logging.critical( msg )  
                raise RuntimeError, msg
        
        if self.use_scwrl:
            # Add sidechains using SCRWL - loop over each directory and output files into the models directory
            for wdir,proc in directories.iteritems():
                add_sidechains_SCWRL.add_sidechains_SCWRL(self.scwrl_exe, wdir, self.models_dir, str(proc), False)
        else:
        # Just copy all modelling files into models directory
            for wd in directories.keys():
                proc = directories[wd]
                for pfile in glob.glob( os.path.join(wd, '*.pdb') ):
                    pdbname = os.path.split(pfile)[1]
                    shutil.copyfile( wd + os.sep + pdbname, self.models_dir + os.sep + str(proc) + '_' + pdbname)
        
        return self.models_dir
    ##End doModelling
    
    def setup_domain_constraints(self):
        """
        Create the file for restricting the domain termini and return a list suitable
        for adding to the rosetta command
        """
        
        fas = open(self.fasta)
        seq = ''
        for line in fas:
            if not re.search('>', line):
                seq += line.rstrip('\n')
        length = 0
        for x in seq:
            if re.search('\w', x):
                length += 1
    
        self.logger.info('restricting termini distance: {0}'.format( self.domain_termini_distance ))
        constraints_file = os.path.join(self.work_dir, 'constraints')
        conin = open(constraints_file, "w")
        conin.write('AtomPair CA 1 CA ' + str(length) + ' GAUSSIANFUNC ' + str(self.domain_termini_distance) + ' 5.0 TAG')
        cmd = '-constraints:cst_fa_file', constraints_file, '-constraints:cst_file', constraints_file
        
        return cmd

    def set_from_dict(self, optd ):
        """
        Set the values from a dictionary
        """

        if not optd['rosetta_dir'] or not os.path.isdir( optd['rosetta_dir'] ):
            msg = "You need to set the rosetta_dir variable to where rosetta is installed"
            self.logger.critical(msg)
            raise RuntimeError,msg
        
        self.rosetta_dir = optd['rosetta_dir']
        
        # Determine version
        self.rosetta_version = optd['rosetta_version']
        optd['rosetta_version'] = self.get_version()

        # Common variables
        self.fasta = optd['fasta']
        self.work_dir = optd['work_dir']
        self.pdb_code = optd['pdb_code']
        
        # Fragment variables
        self.fragments_exe = optd['rosetta_fragments_exe']
        self.use_homs = optd['use_homs']
        self.fragments_directory = optd['work_dir'] + os.sep + "rosetta_fragments"
        
        if optd['transmembrane']:
            
            self.transmembrane = True
            
            if platform.mac_ver() == ('', ('', '', ''), ''):
                self.transmembrane_exe = self.rosetta_dir + '/rosetta_source/bin/membrane_abinitio2.linuxgccrelease'
            else:
                self.transmembrane_exe = self.rosetta_dir + '/rosetta_source/bin/membrane_abinitio2'
                    
            if not os.path.exists(self.transmembrane_exe):
                self.logger.critical(' cant find Rosetta membrane executable: {0}'.format(self.transmembrane_exe) )
                raise RuntimeError,msg
            
            script_dir = self.rosetta_dir + os.sep + "rosetta_source/src/apps/public/membrane_abinitio"
            self.octopus2span = script_dir + os.sep + "octopus2span.pl"
            self.run_lips = script_dir + os.sep + "run_lips.pl"
            self.align_blast = script_dir + os.sep + "alignblast.pl"
            
            if not os.path.exists(self.octopus2span) or not os.path.exists(self.run_lips) or not os.path.exists(self.align_blast):
                msg = "Cannot find the required executables: octopus2span.pl ,run_lips.pl and align_blast.pl in the directory\n" +\
                "{0}\nPlease check these files are in place".format( script_dir )
                self.logger.critical(msg)
                raise RuntimeError, msg
                            
            if optd['blast_dir']:
                blastpgp = optd['blast_dir'] + os.sep + "bin/blastpgp"
                blastpgp = ample_util.check_for_exe( 'blastpgp', blastpgp )
            else:
                blastpgp = ample_util.check_for_exe( 'blastpgp', None )
                
            # Found so set
            optd['blastpgp'] = blastpgp
            self.blastpgp = blastpgp                  
            
            # nr database
            if not os.path.exists( str(optd['nr']) ) and not os.path.exists( str(optd['nr'])+".pal" ):
                msg = "Cannot find the nr database: {0}\nPlease give the location with the nr argument to the script.".format( optd['nr'] )
                self.logger.critical(msg)
                raise RuntimeError, msg
            
            # Found it
            self.nr = optd['nr']
                
            self.spanfile = optd['transmembrane_spanfile']
            self.lipofile = optd['transmembrane_lipofile']
            
            # Check if we've been given files
            if  self.spanfile:
                if not ( os.path.isfile( self.spanfile ) ):
                     msg = "Cannot find provided transmembrane spanfile: {0}".format(  self.spanfile )
                     self.logger.critical(msg)
                     raise RuntimeError, msg
                 
            if self.lipofile:
                if not ( os.path.isfile( self.lipofile ) ):
                     msg = "Cannot find provided transmembrane lipofile: {0}".format( self.lipofile )
                     self.logger.critical(msg)
                     raise RuntimeError, msg                 
                   
            
            if (  self.spanfile and not self.lipofile ) or ( self.lipofile and not self.spanfile ):
                msg="You need to provide both a spanfile and a lipofile"
                self.logger.critical(msg)
                raise RuntimeError, msg
        # End transmembrane checks          
            

        # Modelling variables
        if optd['make_models']:
            
            if not optd['make_frags']:
                self.frags_3mers = optd['frags_3mers']
                self.frags_9mers = optd['frags_9mers']
                if not os.path.exists(self.frags_3mers) or not os.path.exists(self.frags_9mers):
                    msg = "Cannot find both fragment files:\n{0}\n{1}\n".format(self.frags_3mers,self.frags_9mers)
                    self.logger.critical(msg)
                    raise RuntimeError,msg
                    
            import platform
            if not optd['rosetta_path']: 
                if platform.mac_ver() == ('', ('', '', ''), ''):
                    optd['rosetta_path'] = self.rosetta_dir + '/rosetta_source/bin/AbinitioRelax.linuxgccrelease'
                else:
                    optd['rosetta_path'] = self.rosetta_dir + '/rosetta_source/bin/AbinitioRelax'
            
            # Always save everything back to the amopt object so we can print it out
            self.rosetta_path = optd['rosetta_path']
            
            if not os.path.exists(self.rosetta_path):
                msg = 'Cannot find Rosetta abinitio: {0}'.format(self.rosetta_path)
                self.logger.critical( msg )
                raise RuntimeError,msg
    
            #jmht not used
            # ROSETTA_cluster = rosetta_dir + '/rosetta_source/bin/cluster.linuxgccrelease'
            if not optd['rosetta_db']:
                optd['rosetta_db'] = self.rosetta_dir + '/rosetta_database' 
            self.rosetta_db = optd['rosetta_db']
            
            if not os.path.exists(self.rosetta_db):
                msg = ' cant find Rosetta DB: {0}'.format(self.rosetta_db)
                self.logger.critical( msg )
                raise RuntimeError,msg
            
            #if not optd['rosetta_cm']:
            #    optd['rosetta_cm'] = self.rosetta_dir + '/rosetta_source/bin/idealize_jd2.default.linuxgccrelease'
            #self.rosetta_cm = optd['rosetta_cm']
            #if not os.path.exists(ROSETTA_cluster):
            #    logger.critical(' cant find Rosetta cluster, check path names')
            #    sys.exit()
            
            self.nproc = optd['nproc']
            self.nmodels = optd['nmodels']
            # Set models directory
            if not optd['models_dir']:
                self.models_dir = optd['work_dir'] + os.sep + "models"
            else:
                self.models_dir = optd['models_dir']
            
            # Extra modelling options
            self.all_atom = optd['all_atom']
            self.domain_termini_distance = optd['domain_termini_distance']
            self.rad_gyr_reweight = optd['CC']
            
            if optd['improve_template'] and not os.path.exists( optd['improve_template'] ):
                msg = 'cant find template to improve'
                self.logger.critical( msg)
                raise RuntimeError(msg)
            self.improve_template = optd['improve_template']
                
            self.use_scwrl = optd['use_scwrl']
            self.scwrl_exe = optd['scwrl_exe']        
        return


class Test(unittest.TestCase):


    def setUp(self):
        """
        Set paths
        """
        logging.basicConfig()
        logging.getLogger().setLevel(logging.DEBUG)
        thisdir = os.getcwd()
        self.ampledir = os.path.abspath( thisdir+os.sep+"..")


    def XtestMakeFragments(self):
        """See we can create fragments"""
        
        print "testing FragmentGenerator"
        
        optd = {}
        optd['rosetta_dir'] = "/opt/rosetta3.4"
        optd['pdb_code'] = "TOXD_"
        optd['work_dir'] =  os.getcwd()
        optd['use_homs'] =  True
        optd['make_frags'] = True
        optd['rosetta_db'] = None
        optd['rosetta_fragments_exe'] =  "/tmp/make_fragments.pl"
        #optd['rosetta_fragments_exe'] =  None
        optd['fasta'] = self.ampledir + "/examples/toxd-example/toxd_.fasta"
        
        optd['make_models'] = False
        optd['frags_3mers'] = None
        optd['frags_9mers'] = None
        optd['improve_template'] = None
        
        m = RosettaModel()
        m.set_from_dict( optd )
        m.generate_fragments()


    def XtestNoRosetta(self):
        """
        Test without Rosetta
        """
        
        ## Create a dummy script
        script = "dummy_rosetta.sh"
        f = open(script,"w")
        content = """#!/usr/bin/env python
for i in range(10):
    f = open( "rosy_{0}.pdb".format(i), "w")
    f.write( "rosy_{0}.pdb".format(i) )
    f.close()"""
        f.write(content)
        f.close()
        os.chmod(script, 0o777)
        
          
        # Set options
        optd={}
        optd['nproc'] = 3
        optd['nmodels'] = 30
        optd['work_dir'] = os.getcwd()
        optd['models_dir'] = os.getcwd() + os.sep + "models"
        optd['rosetta_dir'] = "/opt/rosetta3.4"
        optd['rosetta_path'] = os.getcwd() + os.sep + "dummy_rosetta.sh"
        optd['rosetta_db'] = None
        optd['frags_3mers'] = '3mers'
        optd['frags_9mers'] = '9mers'
        optd['rosetta_fragments_exe'] = None
        optd['use_homs'] = None
        optd['make_models'] = True
        optd['make_frags'] =  True
        optd['fasta'] = "FASTA"
        optd['pdb_code'] = "TOXD_"
        optd['improve_template'] = None
        optd['all_atom'] = True
        optd['use_scwrl'] = False
        optd['scwrl_exe'] = ""
        
        optd['domain_termini_distance'] = None
        optd['CC'] = None
        optd['improve_template'] = None


        rm = RosettaModel()
        rm.set_from_dict( optd )
        mdir = rm.doModelling()
        print "models in: {0}".format(mdir)
        
        
    def testTransmembraneFragments(self):
        """
        Test for generating transmembrane fragments
        """       
        
        optd = {}
        optd['work_dir'] = os.getcwd()
        optd['rosetta_dir'] = "/opt/rosetta3.4"
        optd['rosetta_fragments_exe'] = None
        optd['use_homs'] = None
        optd['make_models'] = False
        optd['make_frags'] =  True
        optd['fasta'] = "/home/Shared/2UUI/2uui.fasta"
        optd['pdb_code'] = "2uui_"
        optd['transmembrane'] = True
        optd['blast_dir'] = "/opt/blast-2.2.26"
        optd['nr'] = "/opt/nr/nr"
        
        fragdir=os.getcwd()+os.sep+"fragments"
        import shutil
        shutil.copy2(optd['fasta'], fragdir)
        
        rm = RosettaModel()
        rm.set_from_dict( optd )
        rm.fragments_directory = os.getcwd()+os.sep+"fragments"
        rm.generate_tm_predict()
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
