import os
import string
import re

#import resources
#import MMDB
#import MMUT

def DataManager():
  return CDataManager.insts[0]

class CDataManager:
  insts = []

#------------------------------------------------------------------
  def __init__(self,def_data):
#------------------------------------------------------------------
    self.insts.append(self)
    self.moldata_files = []
    self.mtzdata_files = []
    self.moldata_obj = []
    #self.resources = resources.CResources()

    if def_data.has_key('XYZIN'):
      self.moldata_files.append(def_data['XYZIN'])
    elif  def_data.has_key('XYZIN0'):
      self.moldata_files.append(def_data['XYZIN0'])
    if def_data.has_key('HKLIN'):
      self.mtzdata_files.append(def_data['HKLIN'])
    #print "datamanager moldata_files",self.moldata_files

#-----------------------------------------------------------------
  def GetModel(self):
#-----------------------------------------------------------------
    if len(self.moldata_files) > len(self.moldata_obj):
      next = len(self.moldata_obj)
      obj = CMolData()
      RC = obj.ReadFile(self.moldata_files[next])
      if RC:
        print "ERROR opening file ",self.moldata_files[next]
        del obj
        self.moldata_files.pop(next)
        return ''
      else:
        self.moldata_obj.append(obj)
        return obj
    else:
      return ''

####################################################################
####################################################################


class CMolData:

#--------------------------------------------------------------
  def __init__(self):
#--------------------------------------------------------------

    self.molHnd = MMUT.CMMANManager(resources.CResources.insts.CMGSBase, \
                               resources.CResources.insts.CMolBondParams)
    #print "molhnd",self.molHnd

#---------------------------------------------------------------
  def ReadFile(self,filename):
#---------------------------------------------------------------
    RC = self.molHnd.ReadCoorFile(filename)
    return RC

    
