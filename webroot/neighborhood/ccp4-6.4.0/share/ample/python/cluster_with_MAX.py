#!/usr/bin/python2.6

#edit the sidechains to make polyala, all and reliable

import ample_util
import logging
import re
import os


class MaxClusterer(object):
    """Class to cluster files with maxcluster"""
    
    def __init__(self, maxcluster_exe ):
        
        self.maxcluster_exe = maxcluster_exe
        self.distance_matrix = None
        self.index2pdb = []
        
        return
    
    def generate_distance_matrix(self, pdb_list ):
        """Run maxcluster to generate the distance distance_matrix"""
        
        
        cur_dir = os.getcwd()
        
        no_models = len( pdb_list )
        if not no_models:
            msg = "generate_distance_matrix got empty pdb_list!"
            logging.critical( msg )
            raise RuntimeError, msg
        
        self.index2pdb=[0]*no_models
    
        # Maxcluster arguments
        # -l [file]   File containing a list of PDB model fragments
        # -L [n]      Log level (default is 4 for single MaxSub, 1 for lists)
        # -d [f]      The distance cut-off for search (default auto-calibrate)
        # -bb         Perform RMSD fit using backbone atoms
        #     -C [n]      Cluster method: 0 - No clustering
        # -rmsd ???
        #os.system(MAX + ' -l list  -L 4 -rmsd -d 1000 -bb -C0 >MAX_LOG ')
        #print 'MAX Done'
        
        # Create the list of files for maxcluster
        fname = os.path.join( cur_dir, "files.list" )
        f = open( fname, 'w' )
        f.write( "\n".join( pdb_list )+"\n" )
        f.close()
            
        #log_name = "maxcluster_radius_{0}.log".format(radius)
        log_name = "maxcluster.log"
        cmd = [ self.maxcluster_exe, "-l", fname, "-L", "4", "-rmsd", "-d", "1000", "-bb", "-C0" ]
        retcode = ample_util.run_command( cmd, logfile=log_name )
        
        if retcode != 0:
            msg = "non-zero return code for maxcluster in generate_distance_matrix!"
            logging.critical( msg )
            raise RuntimeError, msg
        
        # Create a square distance_matrix no_models in size filled with zeros
        self.distance_matrix =  [[0 for col in range(no_models)] for row in range(no_models)]
    
        #jmht Save output for parsing - might make more sense to use one of the dedicated maxcluster output formats
        #max_log = open(cur_dir+'/MAX_LOG')
        max_log = open( log_name, 'r')
        pattern = re.compile('INFO  \: Model')
        for line in max_log:
            if re.match(pattern, line):
    
                # Split so that we get a list with
                # 0: model 1 index
                # 1: path to model 1 without .pdb suffix
                # 2: model 2 index
                # 3: path to model 2 without .pdb suffix
                # 4: distance metric
                split = re.split('INFO  \: Model\s*(\d*)\s*(.*)\.pdb\s*vs\. Model\s*(\d*)\s*(.*)\.pdb\s*=\s*(\d*\.\d*)', line)
                #print split
        #         int(split[3])
    
            # print split[1], split[3], split[5]
                self.distance_matrix[  int(split[1]) -1 ][  int(split[3]) -1]  = split[5]
    
                if split[2]+'.pdb' not  in self.index2pdb:
                    self.index2pdb[int(split[1]) -1]  =  split[2]+'.pdb'
    
                if split[4]+'.pdb' not  in self.index2pdb:
                    self.index2pdb[int(split[3]) -1]  =  split[4]+'.pdb'
    
        x = 0
        while x < len(self.distance_matrix):
            y = 0
            while y < len(self.distance_matrix):
                self.distance_matrix[y][x] = self.distance_matrix [x][y]
                y+=1
            x+=1
            
        return

    def cluster_by_radius(self, radius):
        """Return a list of pdbs clustered by the given radius"""
        
        cluster = []
        cluster_indices = self._get_indices_from_distances( radius )
        for index in cluster_indices:
            cluster.append( self.index2pdb[index] )
        
        return cluster
    
    def _get_indices_from_distances( self, radius ):
        """Return the indices of the pdb files when clustering by radius"""
    
        #print len(matrix)
        matrix_line = 0
        best_cluster=[]
        largest = 0
    
        while matrix_line<len(self.distance_matrix):
            cluster=0
            current_cluster_models = []
    
            each_model = 0
    
            while each_model < len(self.distance_matrix[matrix_line]):
                if float(self.distance_matrix[matrix_line][each_model])<radius:
                    current_cluster_models.append(each_model)
                    cluster+=1
                each_model+=1
        # print 'MODEL ', matrix_line+1, cluster
            if len(current_cluster_models) > largest:
                largest = len(current_cluster_models)
                best_cluster = current_cluster_models
    
            matrix_line +=1
    
        # print 'BEST ', best_cluster
        return best_cluster

###########################################
def get_clusters_from_distances(matrix, radius):

    #print len(matrix)
    matrix_line = 0
    best_cluster=[]
    largest = 0


    while matrix_line<len(matrix):
        cluster=0
        current_cluster_models = []

        each_model = 0

        while each_model < len(matrix[matrix_line]):
            if float(matrix[matrix_line][each_model])<radius:
                current_cluster_models.append(each_model)
                cluster+=1
            each_model+=1
    # print 'MODEL ', matrix_line+1, cluster
        if len(current_cluster_models) > largest:
            largest = len(current_cluster_models)
            best_cluster = current_cluster_models

        matrix_line +=1

    # print 'BEST ', best_cluster
    return best_cluster
########################################## ADD ALL
def cluster_with_MAX_FASTBAK(string, radius, MAX, no_models):
    cur_dir = os.getcwd()
    string = re.sub(' ', '\n', string)
    list_string = open(cur_dir + '/list', "w")
    list_string.write(string)
    list_string.close()

    model_indeces=[]
    #print 'runing MAX'
    os.system(MAX + ' -l list  -L 4 -rmsd -d 1000 -bb -C0 >MAX_LOG ')
    #print 'MAX Done'
    matrix = []
    inc = 1
    while inc < no_models+1:
        matrix_line =[]
        #print 'matrix', inc
        max_log = open(cur_dir+'/MAX_LOG')
        pattern = re.compile('INFO  \: Model')
        for line in max_log:
            if re.match(pattern, line):

                #print line
                split = re.split('INFO  \: Model\s*(\d*)\s*(.*)\.pdb\s*vs\. Model\s*(\d*)\s*(.*)\.pdb\s*=\s*(\d*\.\d*)', line)
                #print split
                if int(split[1]) == inc:
                    matrix_line.insert(int(split[3]),  split[5] )
                    if split[2] not in model_indeces:
                        model_indeces.insert(inc, split[2])

                if int(split[3]) == inc:
                    matrix_line.insert(int(split[1]), split[5] )
                    if split[4] not in model_indeces:
                        model_indeces.insert(inc, split[4])


        matrix_line.insert(inc-1, 0 )
        matrix.append(matrix_line )
        inc +=1

    # for x in matrix:   ### got distance matrix
    #  print x
    # print 'GOT MATRIX'
    cluster_models = get_clusters_from_distances(matrix, radius)
    return cluster_models
#####################################
##################################### START

def matrix_insert(i, j, k,  matrix):
    matrix[1][2]  = 2
    #print matrix

    return matrix

##########
def cluster_with_MAX_FAST( file_list, radius, MAX ):
    """
    Cluster the models in the file_list with the given radius using maxcluster
    INPUTS:
    file_list: a file with a list of PDB files to compare
    radius: radius threshold (currently [1,2,3])
    MAX: path to maxcluster executable

    Returns:
    A list of the clustered files.
    """
    cur_dir = os.getcwd()

    no_models = 0
    for pdb in open( file_list, 'r' ):
        no_models+=1
    #no_models = len( file_list )

    # Create the input file for maxcluster with the list of fragments
    #list_string = open(cur_dir + '/list', "w")
    #list_string.write( "\n".join( file_list ) )
    #list_string.close()

    models=[0]*no_models
    #print 'runing MAX'

    # Maxcluster arguments
    # -l [file]   File containing a list of PDB model fragments
    # -L [n]      Log level (default is 4 for single MaxSub, 1 for lists)
    # -d [f]      The distance cut-off for search (default auto-calibrate)
    # -bb         Perform RMSD fit using backbone atoms
    #     -C [n]      Cluster method: 0 - No clustering
    # -rmsd ???
    #os.system(MAX + ' -l list  -L 4 -rmsd -d 1000 -bb -C0 >MAX_LOG ')
    #print 'MAX Done'

    log_name = "maxcluster_radius_{0}.log".format(radius)
    cmd = [ MAX, "-l", file_list, "-L", "4", "-rmsd", "-d", "1000", "-bb", "-C0" ]
    retcode = ample_util.run_command( cmd, logfile=log_name )
    
    # Create a square matrix no_models in size filled with zeros
    matrix =  [[0 for col in range(no_models)] for row in range(no_models)]

    #jmht Save output for parsing - might make more sense to use one of the dedicated maxcluster output formats
    #max_log = open(cur_dir+'/MAX_LOG')
    max_log = open( log_name, 'r')
    pattern = re.compile('INFO  \: Model')
    for line in max_log:
        if re.match(pattern, line):

                    # Split so that we get a list with
                    # 0: model 1 index
                    # 1: path to model 1 without .pdb suffix
                    # 2: model 2 index
                    # 3: path to model 2 without .pdb suffix
                    # 4: distance metric
            split = re.split('INFO  \: Model\s*(\d*)\s*(.*)\.pdb\s*vs\. Model\s*(\d*)\s*(.*)\.pdb\s*=\s*(\d*\.\d*)', line)
            #print split
    #         int(split[3])

        # print split[1], split[3], split[5]
            matrix[  int(split[1]) -1 ][  int(split[3]) -1]  = split[5]

            if split[2]+'.pdb' not  in models:
                models[int(split[1]) -1]  =  split[2]+'.pdb'

            if split[4]+'.pdb' not  in models:
                models[int(split[3]) -1]  =  split[4]+'.pdb'

    x = 0
    while x < len(matrix):
        y = 0
        while y < len(matrix):
            matrix[y][x] = matrix [x][y]
            y+=1
        x+=1

    # for x in matrix:   ### got distance matrix
    #  print x
    # print 'GOT MATRIX'
    ############# get model indeces

    CLUSTER = []

    cluster_models = get_clusters_from_distances(matrix, radius)
    #print cluster_models
    #for i in cluster_models:
    #  print 'using', i

    for index in cluster_models:
        CLUSTER.append(models[index])
    #print CLUSTER
    return CLUSTER

#  1 2 3 4
#1
#2
#3
#4




#################### STOP
def cluster_with_MAX(string, radius, MAX, no_models):
    
    cur_dir = os.getcwd()
    string = re.sub(' ', '\n', string)
    list_string = open(cur_dir + '/list', "w")
    list_string.write(string)
    list_string.close()


    os.system(MAX + ' -l list  -L 4 -rmsd -d 1000 -bb >MAX_LOG ')

    matrix = []
    inc = 1

    largest_size = 0
    largest_models = []

    while inc < no_models+1:  # for each model
        COUNT = 1   # size of cluster
        models = []

        max_log = open(cur_dir+'/MAX_LOG')
        pattern = re.compile('INFO  \: Model')
        for line in max_log:
            if re.match(pattern, line):
            #  print line
                split = re.split('INFO  \: Model\s*(\d*)\s*(.*)\.pdb\s*vs\. Model\s*(\d*)\s*(.*)\.pdb\s*=\s*(\d*\.\d*)', line)
            #  print split

                if int(split[1]) == inc:

                    if float(split[5]) < radius:
                        COUNT +=1
                        models.append(split[4]+'.pdb')
                        if split[2] not  in models:
                            models.append(split[2]+'.pdb')

                if int(split[3]) == inc:
                    if float(split[5]) < radius:
                        COUNT +=1
                        models.append(split[2]+'.pdb')
                        if split[4] not  in models:
                            models.append(split[4]+'.pdb')


        if COUNT > largest_size:
            largest_size = COUNT
            largest_models = models
            # print 'MODEL ',  inc,  ' ', COUNT
    #  for x in models:
            #     print x

        inc +=1

    # print 'LARGEST ',  largest_size
    #for l in largest_models:
    #        print l
    return largest_models

if __name__ == "__main__":
    
    maxcluster_exe = "/Users/jmht/Documents/AMPLE/programs/maxcluster"
    radius = 0.5
    fname = "/Users/jmht/Documents/AMPLE/ample-dev1/examples/toxd-example/ROSETTA_MR_0/fine_cluster_1/trunc_files_0.308182/files.list"
    
    clusterer = MaxClusterer( maxcluster_exe )
    pdb_list = [ f.strip() for f in open( fname ) ]
    clusterer.generate_distance_matrix( pdb_list )
    cluster_files1 = clusterer.cluster_by_radius( 3 )
    cluster_files1 = clusterer.cluster_by_radius( 2 )
    cluster_files1 = clusterer.cluster_by_radius( radius )
    print cluster_files1
    
    cluster_files2 = cluster_with_MAX_FAST( fname, radius, maxcluster_exe )
    print cluster_files2
    
    for f in cluster_files1:
        if f not in cluster_files2:
            print "MISSING ",f
            
    if len(cluster_files1) != len(cluster_files2):
        print "WRONG LENGTH"

###################
#string ='/home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/8_S_00000002.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/8_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/2_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/5_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/1_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/3_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/8_S_00000003.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/4_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/7_S_00000001.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/fine/trunc_files_1/6_S_00000001.pdb'
#1 /home/jaclyn/programs/maxcluster/maxcluster 10

#string = '/home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000009.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000010.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000011.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000012.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000013.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000016.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000017.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000018.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000019.pdb /home/jaclyn/Desktop/backup_scripts/NEW_WORKFLOW/MASTER_parallel/PROGRAM/Version_0.1/test/clusters/cluster_60/sorted_cluster_0/1_S_00000020.pdb '
#NoMODELS = 10
#
#cluster_with_MAX_FAST(string, 2, '/home/jaclyn/programs/maxcluster/maxcluster', NoMODELS)
