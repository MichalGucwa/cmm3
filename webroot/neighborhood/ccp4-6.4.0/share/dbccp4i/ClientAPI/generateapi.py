#
#     Copyright (C) 2004  Wanjuan Yang
#
#     
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#    
#====================================================================
#
# This is a file to generate API from schema. The result api need to be
# modified newProject & newJob function. Then add to dbClientAPI.py.
#
#  Wanjuan Yang Oct 2006
#
#====================================================================
#
#CCP4i_cvs_Id $Id: generateapi.py,v 1.2 2008/08/12 10:47:59 pjx Exp $
#
#######################################################################




fin = open("schema.sql")
fout = open("api.py","w")
fout.write('Automatic generated API\n')
fout.write(' \n')

while 1:
    line = fin.readline()
    if not line: break

    if 'CREATE TABLE' in line:
        i = line.find('(')
        table = line[13:i-1]
        
        fout.write('class '+table+':\n')
        fout.write(' \n')
        fout.write('   def __init__(self,db):\n')
        fout.write('       self.db = db\n')
        fout.write(' \n')
        fout.write('   def new'+table+'(self):\n')
        fout.write('       argu_list = [\''+table+'\']\n')
        fout.write('       id = self.db.conn.get_request_id()\n')
        fout.write('       message = request_wrapper(\'NewRecord\',argu_list,id)\n')
        fout.write('       return self.db.sendmessage(message)\n')
        fout.write('\n')

    else:
        a = line.split()
        if a !=[]:
            fout.write('   def set'+a[0]+'(self,'+table+'Id,'+a[0]+'):\n')
            fout.write('       argu_list = [\''+table+'\','+table+'Id,\''+a[0]+'\','+a[0]+']\n')
            fout.write('       id = self.db.conn.get_request_id()\n')
            fout.write('       message = request_wrapper(\'SetData\',argu_list,id)\n')
            fout.write('       return self.db.sendmessage(message)\n')
            fout.write('\n')      
            fout.write('   def get'+a[0]+'(self,'+table+'Id'+'):\n')
            fout.write('       argu_list = [\''+table+'\','+table+'Id,\''+a[0]+'\''+']\n')
            fout.write('       id = self.db.conn.get_request_id()\n')
            fout.write('       message = request_wrapper(\'GetData\',argu_list,id)\n')
            fout.write('       return self.db.sendmessage(message)\n')
            fout.write('\n')
        

    
fin.close()
fout.close()
