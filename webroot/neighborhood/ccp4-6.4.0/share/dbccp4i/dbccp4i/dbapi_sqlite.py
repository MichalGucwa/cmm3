#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# SQLite Interface - dbapi_sqlite.py
#
# Class for interacting SQLite database 
#
# Wanjuan Yang March 06
#
#===================================================================
#CCP4i_cvs_Id $Id: dbapi_sqlite.py,v 1.9 2008/08/12 10:48:10 pjx Exp $


__version__ = "$Revision: 1.9 $"


#######################################################################
# Import modules that this module depends on
#######################################################################

import exceptions
import sys
import os
try:
    from pysqlite2 import dbapi2 as sqlite
except exceptions.Exception,x:
    import sqlite3 as sqlite

class DB:
    """ Class for interacting SQLite db """
    def __init__(self):
        self.open = False
        self.conn = None
        self.cur = None
        self._db = ""
        self._dbname = ""
        
    def OpenDB(self,dbname,dir):
        """ Open an existing db """
        self._db =  os.path.join(dir,dbname)
        
        if os.path.isfile(self._db):                
            try:
                self.conn = sqlite.connect(self._db)
                self.cur = self.conn.cursor()
                self.open = True
                # set the dbname
                self._dbname = dbname
                
                result = True
            
            except exceptions.Exception,e:
                print '# DB message: catch exception: ', str(e)
                result = 'DB exception:'+ str(e)
        
        else:
            print '# DB message: DB does not exists'
            result =' DB does not exist'

        return result

    def NewDB(self,dbname,dir,schemafile):
        """ Create a new db """ 
        # Generate the name for the SQLite db file
        # Always use the UNIX-style path separator, even
        # on Windows
        self._db = str(dir)+"/"+str(dbname)
        
        if os.path.isfile(self._db) != True:
            try:
                self.conn = sqlite.connect(self._db)
                self.cur = self.conn.cursor()

                # Fetch the SQL commands from the schemafile
                sqllist = getsql(schemafile)
                linen = 0
                for sql in sqllist:
                    linen = linen+1
                    try:
                        self.cur.execute(sql)
                    except exceptions.Exception,e:
                        # Print to stdout if there is a
                        # problem with reading the SQL commands
                        # Also echo the line number in the file
                        print "Exception executing SQL commands from "+\
                              str(schemafile)
                        print "Line "+str(linen)+":"+str(e)
                        raise
                self.open = True
                # set the dbname
                self._dbname = dbname
                result = True
            
            except exceptions.Exception,e:
                result = 'DB exception: '+ str(e)
        else:
            result = 'DB already exists'

        return result
    
    def CloseDB(self):
        """ Close a db """
        if self.open:
            try:
                self.conn.close()
                result = True
            except exceptions.Exception,e:
                result = 'DB exception: '+ str(e)
        else:
            result = 'DB not open'

        return result

    def IsOpen(self):
        """ Check if the db is open """ 
        return self.open

    def GetDBName(self):
        """ Retrieve the name of db """ 
        return self._dbname
    
#---------------------------------------------------------------------
# This section is for general functions for sqlite
#---------------------------------------------------------------------
    def new_record(self,table,attributelist=[],valuelist=[]):
        """ insert a record in a table """
        try:
            sql = 'insert into '+table
            if attributelist != [] and valuelist != []:
                sql = sql + ' ('
                for attribute in attributelist:
                    sql = sql + attribute+','

                sql = sql[0:-1] + ')'
                sql = sql + ' values ('

                for value in valuelist:
                    sql = sql + '\''+value+'\','

                sql = sql[0:-1]+')'
            else:
                sql = sql + '('+table+'_Id) values (Null)'
                
            
            self.cur.execute(sql)
            self.conn.commit()
            sql2 = 'select '+table+'_Id from '+table
            self.cur.execute(sql2)
            self.conn.commit()
            pre_result = self.cur.fetchall()
            result = str(pre_result[-1][0])
                  
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result = False

        return result

    def set_table_attribute(self,table,id,attribute,value):
        """ set value for an attribute in a table """
        try:
            if self.open:
                sql = 'update '+table+' set '+attribute + '='+ '\''+str(value)+'\' where '+table+'_Id='+ str(id)
                
                self.cur.execute(sql)
                self.conn.commit()
                result = True
            else:
                result = False
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  False
        return result
        
        
    def get_table_attribute(self,table,id,attribute):
        """ retrieve the value of an attribute in a table """
        try:
            if self.open:
                sql = 'select '+attribute + ' from '+table+' where '+table+'_Id= '+str(id)
            
                self.cur.execute(sql)
                self.conn.commit()
                resultset = self.cur.fetchall()
                result = str(resultset[-1][0])
                
            else:
                result = False
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result = False
            
        return result

    def get_table_primary_key(self,table,condition):
        """ retrieve the primary key of a table based on certain condition """
        try:
            if self.open:
                sql = 'select '+table+'_Id'+' from '+table+' '+condition 
                self.cur.execute(sql)
                self.conn.commit()
                resultset = self.cur.fetchall()
                if resultset != []:
                    result = str(resultset[-1][0])
                else:
                    result = resultset
                
            else:
                result = 'DB not open yet'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result

    def delete_record(self,table,recordid):
        """ remove a record in a table """
        try:
            if self.open:
                sql = 'delete from '+ table + ' where '+table+'_Id= '+str(recordid)
            
                self.cur.execute(sql)
                self.conn.commit()
                result = True
            else:
                result = False
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result = False
            
        return result

    def delete_records(self,table,condition):
        """ remove records in a table based on certain condition """
        try:
            if self.open:
            
                sql = 'delete from '+ table + ' '+ condition
            
                self.cur.execute(sql)
                self.conn.commit()
                result = True
            else:
                result = False
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result = False
            
        return result
        
    def GetAllRecords(self,table,attribute_list):
        """ get all the records from a given table """
        try:
            if self.open:
                sql = 'select '
                # get the attributes list
                for attribute in attribute_list:
                    # construct sql statement
                    sql = sql + attribute +','
                # get rid of the last ','
                sql = sql[0:-1]
                sql = sql + ' '+ 'from '+table
                                
                self.cur.execute(sql)
                self.conn.commit()
                result = self.cur.fetchall()
                
            else:
                result = 'DB not open yet'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result

    def GetRecords(self,table,attribute_list,condition):
        """ get the records where conditions are met """
        try:
            if self.open:
                sql = 'select '
                # get the attributes list
                for attribute in attribute_list:
                    # construct sql statement
                    sql = sql + attribute +','
                # get rid of the last ','
                sql = sql[0:-1]
                sql = sql + ' '+ 'from '+table+ ' '+ condition
                                
                self.cur.execute(sql)
                self.conn.commit()
                result = self.cur.fetchall()
                
            else:
                result = 'DB not open yet'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result
#----------------------------------------------------------------
# This section is the functions specific for Tracking database which is currently not in use.
#----------------------------------------------------------------

    def GetProjectId(self,projectname):
        """ Get the project id for a given project name """
        try:
            if self.open:
                sql = 'select project_Id from Project where ProjectName = \''+projectname+'\''
                
                self.cur.execute(sql)
                self.conn.commit()
                resultset = self.cur.fetchall()
                if resultset != []:
                    result = str(resultset[-1][0])
                else:
                    result = resultset
                
            else:
                result = 'DB not open yet'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result
            

    def GetProjectname(self,jobid):
        """ Retrieve the project name for a given job """
        try:
            if self.open:
                sql1 = 'select Project_Id from Job where Job_Id = '+str(jobid)
                self.cur.execute(sql1)
                resultset = self.cur.fetchall()
                projectid = resultset[0][0]
                sql2 = 'select ProjectName from Project where Project_Id = '+ str(projectid)
                self.cur.execute(sql2)
                resultset = self.cur.fetchall()
                projectname = resultset[0][0]
                result = projectname
            else:
                result = 'DB not open'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception when get projectname: ', str(e)
            result =  'error:'+str(e)
            
        return result

    def GetProjectList(self):
        """ Retrieve a list of existing projects """
        try:
            if self.open:
                sql = 'select ProjectName from Project'
                self.cur.execute(sql)
                resultset = self.cur.fetchall()
                result = []
                for item in resultset:
                    result.append(str(item)[3:-3])              
            else:
                result = 'DB not open'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result   

    def GetJobList(self,projectid):
        """ Retrieve a list of jobs for a project """
        try:
            if self.open:
                sql = 'select * from job where Project_Id = '+projectid
                self.cur.execute(sql)
                resultset = self.cur.fetchall()
                result = []
                for item in resultset:
                    if 'u\'' in item:
                        result.append(str(item)[3:-3])
                    else:
                        result.append(item)
            else:
                result = 'DB not open'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return result   

    def GetRowofTable(self,table,id):
        """ Retrieve record from a table """
        try:
            if self.open:
                sql = 'select * from '+table+' where '+table+'_Id ='+id
                self.cur.execute(sql)
                resultset = self.cur.fetchall()
                result = []
    
                for item in resultset:               
                    if 'u\'' in item:
                        result.append(str(item)[3:-3])
                    else:
                        result.append(item)
            else:
                result = 'DB not open'
                
        except exceptions.Exception,e:
            print '# DB message: catch exception: ', str(e)
            result =  'error:'+str(e)
            
        return resultset   

def getsql(filename):
    fin = open(filename)
    sql = ''
    while 1:
        line = fin.readline()
        if not line: break

        sql = sql+line

    list = sql.split(';')
    return list

if __name__ == '__main__':
    db = DB()
    db.OpenDB('db4','/home/wy45/tmp/db4')
    print db.GetAllRecords('Jobs',['JobNumber','JobQuality'])
    
