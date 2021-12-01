#!/usr/bin/python
# routines for macromolecular X-ray structure determination using a multivariate llhood function
# for phasing, density modification and refinement
import os,sys,re,shutil
import subprocess

# check and define environment variables
if not os.environ.has_key("CLIB"):
  sys.exit('Error: Environment variable CCP4_LIB not found.')
else:
  ccp4_lib=os.environ.get("CLIB")

if not os.environ.has_key("CRANK"):
  sys.exit('Error: Environment variable CRANK not found.')
else:
  crank=os.environ.get("CRANK")

# import crank tcl procedures using tkinter - disabled as of now, script wrappers used instead
use_tkinter=0
tcl=None
if use_tkinter:
  try:
    from Tkinter import Tcl
  except ImportError:
    print "WARNING: Python's Tkinter module not found. Some functionality may be unavailable."
  else:
    tcl=Tkinter.Tcl()
    tcl.eval('source {0}'.format(os.path.join(crank,'bin','crankutils.tcl')))


# define heavy atom pdb manipulation utils
get_heavy="get_heavy"
add_heavy="add_heavy"
del_heavy="del_heavy"




# unified routine for external program calling
def ExtRun( run_basename, args, inp_scr_lines, pwd, clean=1 ):
  inp_scr = '\n'.join(inp_scr_lines)+'\n'
  arg_scr = ' '.join(args)
  with open('{0}_input'.format(run_basename),'w') as scrin_f:
    scrin_f.write(arg_scr)
    if inp_scr:
      scrin_f.write(' << END\n')
      scrin_f.write(inp_scr)
      scrin_f.write("END\n")
  # fix for Windows to prevent terminal window being created
  startupinfo=None
  if os.name == 'nt':
    startupinfo = subprocess.STARTUPINFO()
    if sys.version_info <= (2, 6):
      startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    else:
      startupinfo.dwFlags |= subprocess._subprocess.STARTF_USESHOWWINDOW
  with open('{0}.log'.format(run_basename),'w') as out_f:
    popen = subprocess.Popen( args, stdin=subprocess.PIPE, stderr=subprocess.PIPE, stdout=out_f, cwd=pwd, startupinfo=startupinfo )
  values,err = popen.communicate(input=inp_scr)
  if popen.returncode != 0:
    if err:
      sys.exit( "{0} failed with error message: {1}".format(run_basename, err) )
    else:
      sys.exit( "{0} failed".format(run_basename) )
  if clean:
    os.remove('{0}_input'.format(run_basename))



class heavy_atom:
  """heavy atom class"""

  def __init__(self,atomtype,fp,fpp):
    self.atomtype=atomtype
    try:
      self.fp=list(fp)
      self.fpp=list(fpp)
    except TypeError:
      self.fp=[fp,]
      self.fpp=[fpp,]



class mtz_cols:
  """MTZ columns labels"""

  def __init__(self, fsigf_o=None, fsigf_op=None, fsigf_om=None, fph_b=None, fph_wt=None, fph_mod=None,
                     hl=None, fom=None, hl_recomb=None, free=None):
    self.fsigf_o = fsigf_o
    self.fsigf_op = fsigf_op
    self.fsigf_om = fsigf_om
    self.fph_b = fph_b
    self.fph_wt = fph_wt
    self.fph_mod = fph_mod
    self.hl = hl
    self.hl_recomb = hl_recomb
    self.fom = fom
    self.free = free



class stats:
  """base class for acquiring results from logfiles/xml files etc"""
  name=None
  value=None
  grep=None 

  def Grep(self, logbase, prog):
    if os.path.getsize(logbase+".log")>100000000:
      sys.exit("{0}.log file too big!".format(logbase))
    self.value=None
    with open(logbase+".log","r") as f:
      for grep_pair in self.grep:
        if grep_pair[0] in prog:
          self.value=re.findall(grep_pair[1], f.read())
          break
      else:
        print "WARNING: Don't know how to get {0} for program {1}".format(self.name,prog)
    if self.value is not None:
      self.value=float(self.value[-1])
    else:
      print "WARNING: {0} could not be obtained by {1}".format(self.name,prog)
    return self.value



class program_params:
  """base class for program specific parameters storage and use"""
  # key = dictionary of keywords and corresponding values (parameters); 
  # value can be a string, scalar, vector, bool or None:
  #   bool:   if False then keyword is not used, if True it is used without any parameters following it
  #   string: keyword is following by the string 
  #   scalar: keyword is following by the scalar converted to string 
  #   vector: keyword is following by all the vectors from the scalar converted to string 
  #   None:   keyword is not used
  param = {}
  # (ordered) list of all keywords (only needed for keywords that need to be supplied in a particular order;
  #    keywords from 'key' (which are not in it yet) will be automatically added to it in undefined order)
  lst_pars = []
  # modifier will be added to the front of each keyword
  modif=''

  def InitList(self):
    for par in self.param:
      if par not in self.lst_pars:
        self.lst_pars.append(par)

  def AddToArgs(self, args, scr_lines=None):
    """Add all parameters to (inputted) args list (command line arguments formatting)"""
    for key in self.lst_pars:
      val = self.param[key]
      if val is not None and val is not False:
        args.append(self.modif+key)
        if val is not True:
          try:
            assert type(val) != str
            for v in val:
              args.append(str(v))
          except:
            args.append(str(val))
        if scr_lines is not None:
          scr_lines.append(' '.join(args))
          args=[]

  def AddToScriptLines(self, scr_lines):
    """Add all parameters to (inputted) scr_lines list (script input lines formatting)"""
    self.AddToArgs([], scr_lines)



class process:
  """ Base class for processes such as model building, density modification etc"""
  whoami="process"
  # debug=0: no intermediate files are kept
  #       1: intermediate working files are kept
  #       2: all intermediate files are kept, incl. all the temporary scripts
  debug=0

  def Clean(self, *files):
    if not self.debug:
      for f in files:
        if os.path.isfile(f):
          os.remove(f)
        #else:
        #  print "WARNING from {0}: file {1} could not be deleted".format(self.whoami, f)

  def ExternalRun(self, run_basename, args, inp_scr_lines, pwd):
    clean = 0 if self.debug>1  else 1
    ExtRun(run_basename, args, inp_scr_lines, pwd, clean)



class find_remove_refine_heavy(process):
  """find heavy atoms from anomalous maps, remove low occupancy atoms and refine"""
  whoami="heavy atoms detection and removal"

  def __init__(self, ph):
    self.ph=ph

  def Run(self, mtz_in, mtzin_col, runcyc):
    # find new atoms
    shutil.copyfile(self.ph.mtz_out, 'refmac.out{0}.mtz'.format(runcyc))
    shutil.copyfile(self.ph.pdb_heavy, 'heavy{0}.pdb'.format(runcyc))
    args = [ 'find_add_remove_refine_heavy.tcl', 'refmac', 'none', str(runcyc), '0', '6.0', '1', '0', '0' ]
    self.ExternalRun( "treat_heavy_{0}".format(runcyc), args, "", os.getcwd() )
    #tcl.eval('find_atoms_from_map_and_refine refmac none {0} 0 5.0 {1} 1 0'.format(mb.cyc,os.path.join(crank,'plugins')))
    # now refine
    self.ph.Run(pdb_in='update_{0}.pdb'.format(runcyc), mtz_in=mtz_in, intcyc=None, mtzin_col=mtzin_col)
    shutil.copy('refmac.out{0}.mtz'.format(runcyc), self.ph.mtz_out)
    for ha in self.ph.heavy_atoms:
      subprocess.check_call([get_heavy, self.ph.pdb_out, self.ph.pdb_heavy, ha.atomtype])
      subprocess.check_call([del_heavy, self.ph.pdb_out, self.ph.pdb_out, ha.atomtype])
    self.Clean('refmac.out{0}.mtz'.format(runcyc), 'heavy{0}.pdb'.format(runcyc), 'temp.mtz', "treat_heavy_{0}.log".format(runcyc))


class model_build(process):
  """Real space treatment - model building"""
  whoami="model building"

  def __init__(self, prog="cbuccaneer", pir=None, maxbigcyc=20, minbigcyc=5, intcyc=3, intcyc_corr=2, binary=None,
               prog_pars=None):
    self.cyc = 0
    self.maxbigcyc = maxbigcyc
    self.minbigcyc = minbigcyc
    # number of internal cycles of the program
    self.intcyc = intcyc
    self.intcyc_corr = intcyc_corr
    self.sequence=pir
    self.buc_pdbwrk=""
    self.buc_correlmode=""
    self.buc_wrk_fc=""
    self.prog = prog
    self.pdb_out = self.prog+".pdb"
    self.binary=binary
    if self.binary is None:
      self.binary=self.prog
    if prog_pars is not None:
      self.prog_pars = prog_pars
    else:
      if "buccaneer" in self.prog:
        self.prog_pars = self.BuccaneerParams()
    self.default_mtzcols = mtz_cols( fom="FOM", fph_b=("FCOMB","PHCOMB"), hl=("HLA","HLB","HLC","HLD"),
                                     fsigf_o=("1_PREP_X1_D1_F","1_PREP_X1_D1_SIGF") )

  def SetDefaultMTZLabels(self, mtzin_col):
    # default input labels
    if mtzin_col is None:
      mtzin_col = mtz_cols()
    if mtzin_col.fph_b is None:
      mtzin_col.fph_b = self.default_mtzcols.fph_b
    if mtzin_col.fom is None:
      mtzin_col.fom = self.default_mtzcols.fom
    if mtzin_col.fsigf_o is None:
      mtzin_col.fsigf_o = self.default_mtzcols.fsigf_o

  class BuccaneerParams(program_params):
    """Buccaneer specific parameters"""
    def __init__(self):
      self.lst_pars=[]
      self.param={}
      self.param['seq_reliab'] = 0.99
      self.InitList()

  def Run(self, mtz_in, mtzin_col=None):
    """Perform a model building job"""
    print "\nStarting {0}. model building cycle\n".format(self.cyc)
    self.SetDefaultMTZLabels(mtzin_col)
    if "buccaneer" in self.prog:
      intcyc_now = self.intcyc_corr  if self.buc_correlmode  else self.intcyc
      args = [self.binary, "-pdbin-ref", os.path.join(ccp4_lib,"data","reference_structures","reference-1ajr.pdb"),
              "-mtzin-ref", os.path.join(ccp4_lib,"data","reference_structures","reference-1ajr.mtz"),
              "-colin-ref-fo", "*/*/[FP.F_sigF.F,FP.F_sigF.sigF]",
              "-colin-ref-hl", "*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]",
              "-colin-wrk-fo", "*/*/[{0}]".format(','.join(mtzin_col.fsigf_o)),
              #"-colin-wrk-free", "*/*/[1_PREP_FREER]",
              "-mtzin-wrk", mtz_in,
              "-pdbout-wrk", self.pdb_out,
              "-find", "-grow", "-join", "-link", "-correct", "-filter", "-ncsbuild", "-prune", "-rebuild",
              "-cycles", str(intcyc_now),
              "-sequence-reliability", str(self.prog_pars.param['seq_reliab']),
              "-new-residue-name", "UNK",
              "-resolution", "2.0"
             ]
      if mtzin_col.hl:
        args.extend(("-colin-wrk-hl", "*/*/[{0}]".format(','.join(mtzin_col.hl))))
      else:
        args.extend(("-colin-wrk-phifom", "*/*/[{0},{1}]".format(mtzin_col.fph_b[1], mtzin_col.fom)))
      if self.sequence:
        args.extend(("-sequence", "-seqin-wrk", self.sequence))
      if self.buc_wrk_fc:
        args.append(self.buc_wrk_fc)
      if self.buc_pdbwrk:
        args.extend(self.buc_pdbwrk)
      if self.buc_correlmode:
        args.append(self.buc_correlmode)
      # run buccaneer
      self.ExternalRun("{0}_{1}".format(self.prog,self.cyc), args, "", os.getcwd() )
    else:
      sys.exit("Don't know how to run program {0} for {1}".format(self.prog,self.whoami))



class density_mod(process):
  """Real space treatment - density modification"""
  whoami="density modification"

  def __init__(self, solv_cont, prog="solomon", bigcyc=6, bias_est=0, mtzinit=None, mtzinitwork=None,
                     flip=None, binary=None, prog_pars=None):
    self.cyc = 0
    self.bigcyc = bigcyc
    self.prog = prog
    self.solv_cont = solv_cont
    if flip is not None:
      self.flip = flip
    elif self.solv_cont>0.0:
      self.flip = (solv_cont-1.0)/solv_cont
    else:
      sys.exit("Solvent content must be positive")
    self.beta=1.0
    self.ncs_opers=[]
    self.seed=0
    self.contr_inv=0.0
    self.suffix=""
    self.mtzinit=mtzinit
    self.mtzinitwork=mtzinitwork
    self.bias_est=bias_est
    if self.bias_est:
      self.suffix="_beta"
      if self.mtzinitwork is None:
        self.mtzinitwork="beta-inp.mtz"
        if self.mtzinit is None:
          sys.exit("Bias estimation class requires input mtz at initialization")
        else:
          self.CreateWorkingSetMTZ(self.mtzinit, self.mtzinitwork)
    self.mtz_out=self.prog+".mtz"
    self.binary=binary
    if self.binary is None:
      self.binary=self.prog
      if "parrot" in self.prog:
        self.binary="cparrot"
    if prog_pars is not None:
      self.prog_pars = prog_pars
    else:
      if "parrot" in self.prog:
        self.prog_pars = self.ParrotParams()
      elif "solomon" in self.prog:
        self.prog_pars = self.SolomonParams()
    self.default_mtzcols = mtz_cols( fph_mod=("mod.F_phi.F","mod.F_phi.phi"), fph_b=("FCOMB","PHCOMB"),
                                     fph_wt=("FWT","PHWT"), fsigf_o=("1_PREP_X1_D1_F","1_PREP_X1_D1_SIGF") )

  @classmethod
  def from_dmbe(cls, dmbe, bigcyc=6):
    """Create DM class from bias estimation DM class"""
    if not dmbe.bias_est:
      sys.exit("Wrong DM class inputted to from_dmbe method")
    inst = cls( dmbe.solv_cont, dmbe.prog, bigcyc, 0, dmbe.mtzinit, dmbe.mtzinitwork, dmbe.flip, dmbe.binary, dmbe.prog_pars )
    return inst

  class getcontr(stats):
    name = "inverse map contrast";
    grep =  ( ("solomon",    r"ratio:\s+(\S+)"),
            )

  def SetDefaultMTZLabels(self, mtzin_col):
    # default input labels
    if mtzin_col is None:
      mtzin_col = mtz_cols()
    if mtzin_col.hl is None and mtzin_col.fph_b is None:
      mtzin_col.fph_b = self.default_mtzcols.fph_b
    if mtzin_col.fph_wt is None:
      mtzin_col.fph_wt = self.default_mtzcols.fph_wt
    if mtzin_col.fph_mod is None:
      mtzin_col.fph_mod = self.default_mtzcols.fph_mod
    if mtzin_col.fsigf_o is None:
      mtzin_col.fsigf_o = self.default_mtzcols.fsigf_o

  def CreateWorkingSetMTZ(self, mtz_all, mtz_work):
    """Create MTZ containing only working reflections"""
    inp_scr_lines=[]
    inp_scr_lines.append("read {0}".format(mtz_all))
    inp_scr_lines.append("calc seed {0}".format(self.seed))
    inp_scr_lines.append("delete col FREE")
    inp_scr_lines.append("calc I col FREE = rfree(0.05)")
    inp_scr_lines.append("select col FREE = 1")
    inp_scr_lines.append("write {0}\nY".format(mtz_work))
    inp_scr_lines.append("quit\nY")
    self.ExternalRun("sftoolswork"+self.suffix, ("sftools",), inp_scr_lines, os.getcwd() )

  def PrepareMTZforDM(self, mtz_in, mtzin_col):
    prepared_mtz="junk.mtz"
    inp_scr_lines=[]
    inp_scr_lines.append("read {0}".format(mtz_in))
    # make sure we use the original HL's (in the traditional phase combination)
    if mtzin_col.hl_recomb is not None:
      inp_scr_lines.append("delete col {0}".format(' '.join(mtzin_col.hl_recomb)))
      inp_scr_lines.append("read {0} col {1}".format(self.mtzinit, ' '.join(mtzin_col.hl_recomb)))
    # delete mod's if they exist (parrot would output identical columns otherwise)
    if mtzin_col.fph_mod[0] != mtzin_col.fsigf_o[0]:
      inp_scr_lines.append("delete col {0}".format(' '.join(mtzin_col.fph_mod)))
    # exclude free set for bias estimation
    if self.bias_est:
      inp_scr_lines.append("delete col FREE")
      inp_scr_lines.append("read {0} col FREE".format(self.mtzinitwork))
      # parrot and solomon may need different treatment here in order to be able to modify 
      #   the map constructed from working set and return the modified working+free set (?)
      #if "solomon" in self.prog:
      #  inp_scr_lines.append("select col FREE")
      # for parrot we need to set the free F's and phases as absent rather than not including them
      #elif "parrot" in self.prog:
      if self.cyc>1:
        inp_scr_lines.append("absent col {0} if col FREE absent".format(' '.join(mtzin_col.fsigf_o)))
        inp_scr_lines.append("absent col {0} if col FREE absent".format(' '.join(mtzin_col.fph_wt)))
        if mtzin_col.hl is not None:
          inp_scr_lines.append("absent col {0} if col FREE absent".format(' '.join(mtzin_col.hl)))
        if mtzin_col.fph_b is not None:
          inp_scr_lines.append("absent col {0} if col FREE absent".format(' '.join(mtzin_col.fph_b)))
    inp_scr_lines.append("write {0}\nY".format(prepared_mtz))
    inp_scr_lines.append("quit\nY")
    self.ExternalRun("sftoolsprep4dm", ("sftools",), inp_scr_lines, os.getcwd() )
    return prepared_mtz

  class SolomonParams(program_params):
    """Solomon specific parameters"""
    def __init__(self):
      self.lst_pars=[]
      self.param={}
      self.param['slvdens'] = 0
      self.param['radius'] = 3
      self.param['trunc'] = (0.4, 1.0)
      self.InitList()

  class ParrotParams(program_params):
    """Parrot specific parameters"""
    def __init__(self):
      self.lst_pars=[]
      self.modif='-'
      self.param={}
      self.param['solvent-flatten'] = True
      self.param['histogram-match'] = True
      self.param['ncs-average'] = True
      self.InitList()

  def RunFFT(self, mtz_in, map_out, mtzin_col):
    # Fourier transform to real space
    inp_scr_lines=[]
    inp_scr_lines.append("mtzin {0}".format(mtz_in))
    if self.cyc==1:
      if mtzin_col.hl is not None:
        inp_scr_lines.append("colin-hl */*/[{0}]".format(','.join(mtzin_col.hl)))
      else:
        inp_scr_lines.append("colin-fc */*/[{0}]".format(','.join(mtzin_col.fph_b)))
    else:
      inp_scr_lines.append("colin-fc */*/[{0}]".format(','.join(mtzin_col.fph_wt)))
    inp_scr_lines.append("colin-fo /*/*/[{0}]".format(','.join(mtzin_col.fsigf_o)))
    inp_scr_lines.append("mapout {0}".format(map_out))
    self.ExternalRun("cfft", ("cfft","-stdin"), inp_scr_lines, os.getcwd() )

  def RunInvFFT(self, map_in, mtz_out):
    # Fourier transform back to reciprocal space
    inp_scr_lines=[]
    inp_scr_lines.append("mtzin {0}".format(self.mtzinit))
    inp_scr_lines.append("mapin {0}".format(map_in))
    inp_scr_lines.append("mtzout {0}".format(mtz_out))
    inp_scr_lines.append("colout mod")
    self.ExternalRun("cinvfft", ("cinvfft","-stdin"), inp_scr_lines, os.getcwd() )

  def Run(self, mtz_in, mtzin_col=None, pdb_heavy=None, no_ncs=-1):
    """Perform a real space density modification; input from and output to mtz"""
    # setting default mtz labels for columns not specified by user
    self.SetDefaultMTZLabels(mtzin_col)
    # exclude free set for bias estimation, remove mod columns for parrot etc -> writes out prep_mtz
    prep_mtz = self.PrepareMTZforDM(mtz_in, mtzin_col)
    # DM job itself
    if "solomon" in self.prog:
      # Fourier transform to real space
      self.RunFFT(prep_mtz, "junk.map", mtzin_col)
      # Solomon job
      args = (self.binary, "MAPIN", "junk.map", "MAPOUT", "{0}{1}.map".format(self.prog,self.suffix))
      inp_scr_lines=[]
      inp_scr_lines.append("SLVFRC {0}".format(self.solv_cont))
      inp_scr_lines.append("mulsolv auto {0}".format(self.flip))
      inp_scr_lines.append("extrude")
      inp_scr_lines.append("mapout")
      self.prog_pars.AddToScriptLines(inp_scr_lines)
      self.ExternalRun(self.prog+self.suffix, args, inp_scr_lines, os.getcwd() )
      # Fourier transform back to reciprocal space
      self.RunInvFFT("{0}{1}.map".format(self.prog,self.suffix), self.mtz_out)
      if self.debug:
        shutil.copy("junk.map","junk_{0}.map".format(self.cyc))
        shutil.copy("{0}{1}.map".format(self.prog,self.suffix), "{0}{1}_{2}.map".format(self.prog,self.suffix,self.cyc))
        shutil.copy(self.mtz_out, "{0}_{1}".format(self.mtz_out,self.cyc))
        shutil.copy("{0}{1}.log".format(self.prog,self.suffix), "{0}{1}_{2}.log".format(self.prog,self.suffix,self.cyc))
      self.contr_inv = self.getcontr().Grep(logbase=self.prog+self.suffix, prog=self.prog)
    elif "parrot" in self.prog:
      if no_ncs<0:
        determine_ncs = (self.cyc-2)%10==0
        #determine_ncs = ( self.cyc==4 or (self.cyc-2)%10==0 )
      else:
        determine_ncs = not no_ncs
      args = [self.binary, 
              "-colin-wrk-fo", "*/*/[{0}]".format(','.join(mtzin_col.fsigf_o)),
              "-modify-map-and-terminate",
              "-colout", "mod",
              "-solvent-content", str(self.solv_cont),
              "-mtzin-wrk", prep_mtz,
              "-mtzout", "parr_out_junk.mtz",
             ]
      if self.prog_pars.param["ncs-average"] is not False:
        self.prog_pars.param["ncs-average"] = None
        if determine_ncs and pdb_heavy:
          self.prog_pars.param["ncs-average"] = True
          args.extend( ("-pdbin-wrk-ha", pdb_heavy) )
        elif self.ncs_opers:
          self.prog_pars.param["ncs-average"] = True
          for ncs_oper in self.ncs_opers:
            args.append( "-ncs-operator" )
            args.append( ncs_oper )
      self.prog_pars.AddToArgs(args)
      if mtzin_col.hl_recomb is not None:
        args.extend( ("-colin-hl", "*/*/[{0}]".format(','.join(mtzin_col.hl_recomb))) )
      if self.cyc > 1:
        args.extend( ("-colin-wrk-fc", "*/*/[{0}]".format(','.join(mtzin_col.fph_wt))) )
      else:
        if mtzin_col.hl is not None:
          args.extend( ("-colin-wrk-hl", "*/*/[{0}]".format(','.join(mtzin_col.hl))) )
        else:
          args.extend( ("-colin-wrk-fc", "*/*/[{0}]".format(','.join(mtzin_col.fph_b))) )
      self.ExternalRun("{0}{1}".format(self.prog,self.suffix), args, "", os.getcwd() )
      if determine_ncs:
        with open("{0}{1}".format(self.prog,self.suffix)+".log",'r') as f:
          self.ncs_opers = re.findall(r"-ncs-operator\s+(\S+)", f.read())
      if self.bias_est:
        # include input information for all reflections
        inp_scr_lines=[]
        inp_scr_lines.append("read {0}".format(self.mtzinit))
        inp_scr_lines.append("delete col {0}".format(' '.join(mtzin_col.fph_mod)))
        inp_scr_lines.append("read parr_out_junk.mtz col {0}".format(' '.join(mtzin_col.fph_mod)))
        inp_scr_lines.append("write {0}\nY".format(self.mtz_out))
        inp_scr_lines.append("quit\nY")
        self.ExternalRun("sftoolspostparr", ("sftools",), inp_scr_lines, os.getcwd() )
      else:
        shutil.copy("parr_out_junk.mtz",self.mtz_out)
      if self.debug:
        shutil.copy(self.mtz_out, "{0}_{1}".format(self.mtz_out,self.cyc))
        shutil.copy("{0}{1}.log".format(self.prog,self.suffix), "{0}{1}_{2}.log".format(self.prog,self.suffix,self.cyc))
    else:
      sys.exit("Don't know how to run program {0} for {1}".format(self.prog,self.whoami))
    # cleanup
    self.Clean( prep_mtz, "parr_out_junk.mtz", "junk.map", "{0}{1}.map".format(self.prog,self.suffix) )

  def EstBias(self, mtz_in=None, correction=0, mtzin_col=None): 
    """Estimate DM bias from performed bias estimation jobs"""
    # setting default mtz labels for columns not specified by user
    self.SetDefaultMTZLabels(mtzin_col)
    # default parameter for mtz_in
    if mtz_in is None:
      mtz_in=self.mtz_out
    # get the correlations
    inp_scr_lines=[]
    inp_scr_lines.append("read {0} col FREE".format(self.mtzinitwork))
    inp_scr_lines.append("read {0} col {1} {2}".format(mtz_in, mtzin_col.fph_mod[0], mtzin_col.fsigf_o[0]))
    inp_scr_lines.append("select col FREE")
    inp_scr_lines.append("checkhkl")
    inp_scr_lines.append("correl col {0} {1}".format(mtzin_col.fph_mod[0], mtzin_col.fsigf_o[0]))
    inp_scr_lines.append("select invert")
    inp_scr_lines.append("checkhkl")
    inp_scr_lines.append("correl col {0} {1}".format(mtzin_col.fph_mod[0], mtzin_col.fsigf_o[0]))
    inp_scr_lines.append("quit\nY")
    self.ExternalRun("correl"+self.suffix, ("sftools",), inp_scr_lines, os.getcwd() )
    with open("correl{0}.log".format(self.suffix),"r") as f:
      corr=re.findall("OVERALL STATISTICS\s+\S+\s+(\S+)", f.read())
      if len(corr)!=2:
        sys.exit("Unexpected number of matches in correl{0}.log: {1}".format(self.suffix,len(corr)))
      corr=(float(corr[0]), float(corr[1]))
    # now calculate the estimation or correction to the estimation
    if not correction:
      self.beta=corr[1]/corr[0]
    else:
      perc=corr[1]/corr[0]-1.0
      if (perc>0.15 or perc<-0.15) and (corr[0]>0.3 or perc>0.3 or perc<-0.3):
        self.beta=1.0
        print 'Too unrepresentative free set. Will need to generate new free set and start from beginning again.\n'
        return 1
      else:
        self.beta=self.beta*corr[0]/corr[1]
    if self.beta<0.2:
      self.beta=0.2
    elif self.beta>1.0:
      self.beta=1.0
    if correction:
      print "Beta corrected to {0}\n".format(self.beta)
    else:
      print "Beta estimated as {0}\n".format(self.beta)
    return 0

  def RunWithPhaseComb(self, ph, mtzin, pdbin, mtzin_col=None, mb_mod=0, bias_corr_cyc=0, 
                       no_ncs_det=-1, ph_intcyc=-1, verbose=1):
    """Simple DM+phase combination recycling"""
    if mtzin != ph.mtz_out:
      shutil.copyfile(mtzin, ph.mtz_out)
    if pdbin != ph.pdb_out:
      shutil.copyfile(pdbin, ph.pdb_out)
    # we do not want to run ncs determination every cycle
    if no_ncs_det==0:
      no_ncs_det=-1;
    if verbose and self.bigcyc:
      if self.bias_est:
        print "Starting {0} bias estimation cycles\n".format(self.bigcyc)
      else:
        refi="and refinement" if mb_mod else ""
        print "Starting {0} density modification {1} cycles\n".format(self.bigcyc,refi)
    if self.bigcyc and self.bias_est:
      self.beta=1.0
    # the recycling starts here
    for self.cyc in range(1, self.bigcyc+1):
      self.Run(mtz_in=ph.mtz_out, pdb_heavy=ph.pdb_heavy, no_ncs=no_ncs_det, mtzin_col=mtzin_col)
      ph.Run(pdb_in=ph.pdb_out, dm=self, mb_mod=mb_mod, intcyc=ph_intcyc, mtzin_col=mtzin_col)
      if self.cyc==bias_corr_cyc and self.EstBias(correction=1, mtzin_col=mtzin_col):
        return 1
      if verbose:
        print " Cycle {0}".format(self.cyc)
        if mb_mod:
          print "  Overall R-factor is {0}".format(ph.R)
        else:
          print "  Inverse contrast is {0}".format(self.contr_inv)
        print "  Overall MEAN FOM is {0}".format(ph.fom)
        print "  Overall Correlation is {0}\n".format(ph.corr)
    return 0



class phase_ref(process):
  """Reciprocal space treatment - phasing, phase combination and refinement"""
  whoami="phasing and/or refinement"

  def __init__(self, prog="refmac5", intcyc=1, heavy_atoms=[heavy_atom("SE", -4.0, 4.0),], 
                     pdb_heavy="XYZOUT.pdb", exper=None, binary=None):
    # number of internal cycles of the program
    self.intcyc = intcyc
    self.prog = prog
    self.exper = exper
    self.heavy_atoms=heavy_atoms
    self.read_luzz=1
    self.fom=0.0
    self.corr=0.0
    self.pdb_heavy=pdb_heavy
    self.pdb_out=self.prog+".pdb"
    self.mtz_out=self.prog+".mtz"
    self.binary=binary
    if self.binary is None:
      self.binary=self.prog
      if "refmac" in self.prog:
        self.binary="refmac5"
    self.default_mtzcols = mtz_cols( fsigf_o=("1_PREP_X1_D1_F","1_PREP_X1_D1_SIGF"),
                                     fsigf_op=("1_PREP_X1_D1_F+","1_PREP_X1_D1_SIGF+"),
                                     fsigf_om=("1_PREP_X1_D1_F-","1_PREP_X1_D1_SIGF-"),
                                     fph_b=("FCOMB","PHCOMB"), fph_wt=("FWT","PHWT"), hl=("HLACOMB","HLBCOMB","HLCCOMB","HLDCOMB") )

  class getfom(stats):
    name = "FOM";
    grep =  ( ("refmac",    r"Overall figure of merit\s+=\s+(\S+)"),
              ("multicomb", r"Overall MEAN FOM is\s+(\S+)")
            )
  class getcorr(stats):
    name = "correlation coefficient";
    grep =  ( ("refmac",    r"Overall correlation coefficient\s+=\s+(\S+)"),
              ("multicomb", r"Overall Correlation is\s+(\S+)")
            )
  class getR(stats):
    name = "R factor";
    grep =  ( ("refmac",    r"Overall R factor\s+=\s+(\S+)"),
            )

  def SetDefaultMTZLabels(self, mtzin_col):
    # default input labels
    if mtzin_col is None:
      mtzin_col = mtz_cols()
    if mtzin_col.fph_b is None:
      mtzin_col.fph_b = self.default_mtzcols.fph_b
    if mtzin_col.fsigf_o is None:
      mtzin_col.fsigf_o = self.default_mtzcols.fsigf_o
    if mtzin_col.fsigf_op is None:
      mtzin_col.fsigf_op = self.default_mtzcols.fsigf_op
    if mtzin_col.fsigf_om is None:
      mtzin_col.fsigf_om = self.default_mtzcols.fsigf_om

  def SetRefmacScript(self,inp_scr_lines, pdb_in, dm, mtz_in, beta, mb_mod, mtzin_col):
    rluzz=""
    if self.read_luzz and dm and dm.cyc>2:
      rluzz="RLUZZ"
    if not mb_mod or dm:
      inp_scr_lines.append("REFI SUBST YES {0} WLUZZ".format(rluzz))
    labin = "LABIN FP={0} SIGFP={1}".format(mtzin_col.fsigf_o[0], mtzin_col.fsigf_o[1])
    if self.exper=="SAD":
      labin += " -\n  F_1={0} SIGF_1={1}  F_2={2} SIGF_2={3}".format(
              mtzin_col.fsigf_op[0], mtzin_col.fsigf_op[1], mtzin_col.fsigf_om[0], mtzin_col.fsigf_om[1])
      inp_scr_lines.append("REFI SADH") 
    elif self.exper=="SIRAS":
      labin += " -\n  F_1={0} SIGF_1={1}  F_2={2} SIGF_2={3}  F_3={4} SIGF_3={5}".format(
              mtzin_col.fsigf_o[0], mtzin_col.fsigf_o[1],
              mtzin_col.fsigf_op[0], mtzin_col.fsigf_op[1], mtzin_col.fsigf_om[0], mtzin_col.fsigf_om[1])
      inp_scr_lines.append("REFI SRAS") 
      inp_scr_lines.append("DATA DERI 0\nDATA DERI 1 PLUS\nDATA DERI 1 MINUS") 
    elif mtzin_col.hl_recomb is not None:
      labin += " -\n  HLA={0} HLB={1} HLC={2} HLD={3}".format(
              mtzin_col.hl_recomb[0], mtzin_col.hl_recomb[1], mtzin_col.hl_recomb[2], mtzin_col.hl_recomb[3])
    if mtzin_col.free is not None:
      labin += " -\n  FREE={0}".format(mtzin_col.free)
    if dm:
      labin += " -\n  FPART1={0} PHIP1={1}".format(mtzin_col.fph_mod[0], mtzin_col.fph_mod[1])
    inp_scr_lines.append(labin)
    for ha in self.heavy_atoms:
      inp_scr_lines.append("ANOM FORM {0} {1} {2}".format(ha.atomtype, ha.fp[0], ha.fpp[0]))
    inp_scr_lines.append("PHOUT")
    if self.intcyc is not None:
      inp_scr_lines.append("ncyc {0}".format(self.intcyc))
    if dm:
      if mb_mod:
        inp_scr_lines.append("DM2")
        inp_scr_lines.append("scpa 0 1")
      else:
        # siras seems to work better with DM2
        if self.exper=="SIRAS":
          inp_scr_lines.append("DM2")
        else:
          inp_scr_lines.append("DM")
        inp_scr_lines.append("scpa 1")
      inp_scr_lines.append("DMBL {0}".format(dm.beta))
    if not mb_mod:
      inp_scr_lines.append("solv no")

  def SetMulticombScript(self,inp_scr_lines, pdb_in, dm, mtz_in, beta, mb_mod, mtzin_col):
      if dm:
        if mb_mod:
          sys.exit("{0} cannot be used for partial model refinement, use Refmac").format(self.prog)
      else:
        sys.exit("{0} can only be used for phase combination!").format(self.prog)
      rluzz=""
      if self.read_luzz and dm and dm.cyc>1:
        rluzz="@luzzd"
      inp_scr_lines.append("XTAL TMP\nDNAME TMP")
      # FREE=1_PREP_FREER
      if self.exper=="SAD":
        inp_scr_lines.append("TARG PSAD")
        for ha in self.heavy_atoms:
          inp_scr_lines.append("FORM {0} FP={1} FPP={2}".format(ha.atomtype, ha.fp[0], ha.fpp[0]))
        inp_scr_lines.append("COLU  F+={0} SF+={1}  F-={2} SF-={3} -".format(
              mtzin_col.fsigf_op[0], mtzin_col.fsigf_op[1], mtzin_col.fsigf_om[0], mtzin_col.fsigf_om[1]))
      elif mtzin_col.hl_recomb is not None:
        inp_scr_lines.append("TARG MLHL")
        inp_scr_lines.append("COLU  F={0} SF={1} HLA={2} HLB={3} HLC={4} HLD={5} -".format(
              mtzin_col.fsigf_o[0], mtzin_col.fsigf_o[1],
              mtzin_col.hl_recomb[0], mtzin_col.hl_recomb[1], mtzin_col.hl_recomb[2], mtzin_col.hl_recomb[3]))
      else:
        sys.exit("No phase information found for {0}.".format(self.prog))
      inp_scr_lines.append("  FC1={0} PC1={1}".format(mtzin_col.fph_mod[0], mtzin_col.fph_mod[1]))
      inp_scr_lines.append("MODL {0}".format(pdb_in))
      inp_scr_lines.append("OUTP {0}".format(self.prog))
      inp_scr_lines.append("{0}".format(rluzz))
      inp_scr_lines.append("BETA {0}".format(dm.beta))
      inp_scr_lines.append("NOUP\nVERBOSE 3")

  def AdjustOutputMTZ(self, mtz_in, mtzin_col):
    # replace the output F's by original F's etc; at the moment assumes the mtz to be modified is 'hklout.mtz'
    inp_scr_lines=[]
    inp_scr_lines.append("read hklout.mtz")
    inp_scr_lines.append("delete col {0}".format(' '.join(mtzin_col.fsigf_o)))
    inp_scr_lines.append("read {0} col {1}".format(mtz_in, ' '.join(mtzin_col.fsigf_o)))
    inp_scr_lines.append("delete col {0} {1}".format(' '.join(mtzin_col.fsigf_op), ' '.join(mtzin_col.fsigf_om)))
    inp_scr_lines.append("read {0} col {1}".format(mtz_in,' '.join(mtzin_col.fsigf_op)))
    inp_scr_lines.append("read {0} col {1}".format(mtz_in,' '.join(mtzin_col.fsigf_om)))
    if mtzin_col.fph_b[0] != mtzin_col.fsigf_o[0]:
      inp_scr_lines.append("delete col {0}".format(mtzin_col.fph_b[0]))
    inp_scr_lines.append("calc F col {0} = col {1} col {2} *".format(mtzin_col.fph_b[0], mtzin_col.fom, mtzin_col.fsigf_o[0]))
    inp_scr_lines.append("write {0}\nY".format(self.mtz_out))
    inp_scr_lines.append("quit\nY")
    self.ExternalRun("sftools_outph", ("sftools",), inp_scr_lines, os.getcwd() )

  def Run(self, pdb_in=None, dm=None, mtz_in=None, beta=1, mb_mod=0, intcyc=-1, mtzin_col=None):
    """Perform a phasing/phase combination/refinement job"""
    self.SetDefaultMTZLabels(mtzin_col)
    # if we are said to run different amount of cycles than set at the initialization
    if intcyc is None or intcyc >= 0:
      intcyc_saved = self.intcyc
      self.intcyc = intcyc
    # figure out action (just for output purposes)
    action="phas"
    if dm:
      action="phcomb"
      if mb_mod:
        action="refcomb"
    elif mb_mod:
      action="phref"
    # default parameter for pdb_in
    if pdb_in is None:
      pdb_in=self.pdb_heavy
    # default parameter for mtz_in
    if dm and mtz_in is None:
      mtz_in = dm.mtz_out
    if mtz_in is None:
      sys.exit("No input MTZ file for {0} in".format(self.program))
    # add heavy atoms to the input model
    if mb_mod:
      if os.path.isfile(self.pdb_heavy):
        subprocess.check_call([add_heavy, pdb_in, self.pdb_heavy])
      else:
        print "WARNING: heavy atom file {0} not found - substructure not added to the partial model!".format(self.pdb_heavy)
    # set the script
    inp_scr_lines=[]
    if "refmac" in self.prog:
      args = (self.binary, "HKLIN", mtz_in, "XYZIN", pdb_in, "HKLOUT", "hklout.mtz", "XYZOUT", self.pdb_out)
      self.SetRefmacScript(inp_scr_lines, pdb_in, dm, mtz_in, beta, mb_mod, mtzin_col)
    elif "multicomb" in self.prog:
      args = (self.binary, "HKLIN", mtz_in, "HKLOUT", "hklout.mtz")
      self.SetMulticombScript(inp_scr_lines, pdb_in, dm, mtz_in, beta, mb_mod, mtzin_col)
    else:
      sys.exit("Don't know how to run program {0} for {1}".format(self.prog,self.whoami))
    # perform the phasing/refinement action
    dm_info=""
    if dm:
      dm_info="_cyc{0}{1}".format(dm.cyc,dm.suffix)
    logbase="{0}_{1}{2}".format(self.prog, action, dm_info)
    self.ExternalRun(logbase, args, inp_scr_lines, os.getcwd() )
    # get FOM and correl
    self.fom = self.getfom().Grep(logbase,self.prog)
    self.corr = self.getcorr().Grep(logbase,self.prog)
    if "refmac" in self.prog:
      self.R = self.getR().Grep(logbase,self.prog)
    # write luzz D for next multicomb cycle (refmac has WLUZZ keyword for this)
    if "multicomb" in self.prog:
      with open("luzzd",'w') as g:
        with open(self.prog+".sh",'r') as f:
          g.write( '\n'.join(re.findall(r"PLUZ.+", f.read())) )
    # replace the output F's by original F's etc
    if mb_mod:
      self.AdjustOutputMTZ(mtz_in, mtzin_col)
    if dm:
      if dm.bias_est:
        self.AdjustOutputMTZ(dm.mtzinitwork, mtzin_col)
      else:
        self.AdjustOutputMTZ(dm.mtzinit, mtzin_col)
    # save the substructure and remove it from the PDB (so that it does not obscure mb)
    if mb_mod and os.path.isfile(self.pdb_heavy):
      for ha in self.heavy_atoms:
        subprocess.check_call([get_heavy, self.pdb_out, self.pdb_heavy, ha.atomtype])
        subprocess.check_call([del_heavy, self.pdb_out, self.pdb_out, ha.atomtype])
    # restore original number of cycles if needed
    if intcyc is None or intcyc >= 0:
      self.intcyc = intcyc_saved
    # cleanup
    self.Clean( "hklout.mtz" )



class dm_br(process):
  """Complete density modification recycling with bias reduction"""
  whoami="density modification recycling with bias reduction"

  def __init__(self,ph,dm_be,dm,debug=0):
    self.ph=ph
    self.dm_be=dm_be
    self.dm=dm
    if debug:
      self.debug=debug
      self.ph.debug=debug
      self.dm.debug=debug
      if dm_be is not None:
        self.dm_be.debug=debug

  def Run(self, no_bias_est=0, partial_model=None, ph_intcyc=-1, skip_ncs_det=0, mtz_in=None, mtzin_col=None):
    # for convenience
    ph=self.ph
    dm=self.dm
    dm_be=self.dm_be
    if dm_be is None:
      no_bias_est = 1
    # preparations
    if mtz_in is None:
      mtz_in = dm.mtzinit
    mtz_in_saved=mtz_in+"_save"
    shutil.copy(mtz_in, mtz_in_saved)
    bcc=0
    if (not no_bias_est):
      bcc=dm_be.bigcyc
    mb_mod=0
    if partial_model is not None:
      mb_mod=1
    else:
      partial_model = ph.pdb_heavy
    if not ph.exper and not mtzin_col.hl_recomb:
      mtzin_col.hl_recomb = mtzin_col.hl
    # go!
    # contin is used so that the process can be repeated if needed (eg bias estimation was not reliable)
    contin=1
    while contin:
      # estimate density modification bias
      if not no_bias_est and dm_be.bigcyc:
        dm_be.RunWithPhaseComb(ph, mtzin=mtz_in_saved, mtzin_col=mtzin_col, pdbin=partial_model, 
                               no_ncs_det=skip_ncs_det, ph_intcyc=ph_intcyc, mb_mod=mb_mod)
        dm_be.EstBias(mtzin_col=mtzin_col)
        dm.beta=dm_be.beta
      # run density modification + check bias estimation, apply correction (if bias is estimated)
      if dm.RunWithPhaseComb(ph, mtzin=mtz_in_saved, mtzin_col=mtzin_col, pdbin=partial_model, 
                             no_ncs_det=skip_ncs_det, mb_mod=mb_mod, ph_intcyc=ph_intcyc, bias_corr_cyc=bcc):
        # if bias estimation problem then let's reseed and repeat bias estimation
        dm_be.seed+=1
        dm_be.CreateWorkingSetMTZ(dm_be.mtzinit, dm_be.mtzinitwork)
        dm_be.beta=1.0
      else:
        contin=0
    # assign output mtz labels (useful if dmbr is used by eg combined algorithm) - this should be done by proper labels passing?
    mtzin_col.hl=self.ph.default_mtzcols.hl
    mtzin_col.fph_b=self.ph.default_mtzcols.fph_b
    mtzin_col.fph_wt=self.ph.default_mtzcols.fph_wt
    self.Clean(mtz_in_saved)
    #if dm_be is not None:
    #  self.Clean(dm_be.mtzinitwork)


class comb_phdmmb(process):
  """Combined phasing, density modification and model building"""
  whoami="combined phasing, density modification and model building"

  def __init__(self,ph,dm_be,dm,mb,debug=0,bias_reest_cyc=3):
    self.fom_tresh_min=0.40
    self.fom_tresh_max=0.62
    self.R_tresh=0.44
    self.bias_reest_cyc=bias_reest_cyc
    self.ph=ph
    self.dm_be=dm_be
    self.dm=dm
    self.mb=mb
    self.mb_minbigcyc_init = mb.minbigcyc
    mb.minbigcyc = mb.minbigcyc*2
    self.dm_cyc_init=dm.bigcyc
    self.find_rem_heavy=find_remove_refine_heavy(ph)
    self.mb_correlcyc=2
    self.try_dm=0
    self.R_best=1.0
    self.cyc_best=0
    if debug:
      self.debug=debug
      self.ph.debug=debug
      self.dm.debug=debug
      self.dm_be.debug=debug
      self.mb.debug=debug

  def decide(self):
    """simple FOM based decision making"""
    # for convenience
    ph=self.ph
    dm_be=self.dm_be
    dm=self.dm
    mb=self.mb
    # increase weight of refinement as we are getting close
    if ph.fom>self.fom_tresh_max-0.05 and not self.finish_mode:
      dm.bigcyc=self.dm_cyc_init-2  if self.dm_cyc_init>2  else 1
      if ph.R<self.R_tresh+0.05:
        ph.intcyc=3
        self.mb_correlcyc=2
    # switch to finishing stage
    if ph.fom>self.fom_tresh_max and not self.finish_mode:
      if ph.R<self.R_tresh+0.05:
        dm.bigcyc=self.dm_cyc_init-3  if self.dm_cyc_init>3  else 1
      if ph.R<self.R_tresh:
        ph.intcyc=10
        dm.beta=1.0
        dm_be.bigcyc=0
        self.mb_correlcyc=3
        # the number of finishing cycles depends on the number of cycles it took to get to the finishing stage
        mb.minbigcyc = self.mb_minbigcyc_init + mb.cyc - 1
        if mb.minbigcyc > 2*self.mb_minbigcyc_init:
          mb.minbigcyc=2*self.mb_minbigcyc_init
        self.finish_mode = 1
        print "Switching to finishing mode ({0} cycles).".format(mb.minbigcyc)
    if self.fom_tresh_min<0.5:
      self.fom_tresh_min+=0.005
    # decrease number of min cycles if we are doing very well or very badly
    if ph.fom<self.fom_tresh_min or self.finish_mode:
      mb.minbigcyc-=1
    cyc2go = min(mb.minbigcyc,mb.maxbigcyc-mb.cyc)
    # "anneal" time to time
    if mb.cyc%(self.bias_reest_cyc*4)==0 and cyc2go>=self.mb_correlcyc+(cyc2go!=mb.maxbigcyc-mb.cyc):
      self.try_dm=1
      mb.minbigcyc+=1
    print "FOM after {0}. model building cycle is {1}".format(mb.cyc,ph.fom)
    # if we have the best model then save it and take it as result at the end
    # usually the last model is the best but time to time this helps to keep a bit more complete model
    if self.finish_mode and mb.buc_correlmode:
      if ph.R<self.R_best:
        self.R_best=ph.R
        self.cyc_best=mb.cyc
        shutil.copy(ph.mtz_out, ph.mtz_out+"_best")
        shutil.copy(ph.pdb_out, ph.pdb_out+"_best")
      if self.R_best<1.0 and cyc2go<=0 and self.R_best<ph.R-0.01:
        print "Taking the results from cycle {0} as final.".format(self.cyc_best)
        shutil.move(ph.mtz_out+"_best", ph.mtz_out)
        shutil.move(ph.pdb_out+"_best", ph.pdb_out)
    # switch between correlation building and standard building
    if mb.cyc<=1 or (mb.cyc%self.mb_correlcyc==0 and (cyc2go>=self.mb_correlcyc or not self.finish_mode)):
      mb.buc_pdbwrk=""
      mb.buc_correlmode=""
    else:
      mb.buc_pdbwrk=("-pdbin-wrk",self.ph.pdb_out)
      mb.buc_correlmode="-correlation-mode"

  def FOMresult(self):
    """rough FOM based result estimation and its printing"""
    if self.ph.fom<self.fom_tresh_min:
      print "Wrong substructure or very weak phases suspected: the model building seems unsuccessful."
    elif self.finish_mode:
      print "Majority of model should be successfully built."
    else:
      print "Weak phases (or wrong substructure) likely: a partial (or no) model is probably correctly built."

  def try_something(self, find_new, dmbr, mtzin_col):
    # try searching for new atoms and removing low occupancy ones 
    # restricted to only once in the building due to too many related fake atoms that freeze NCS detection by Parrot
    if find_new and not self.finish_mode and self.mb.cyc<=self.bias_reest_cyc:
      self.find_rem_heavy.Run(self.dm.mtzinit, mtzin_col, self.mb.cyc)
    # try including standard DM if DM2 might got stuck
    if self.try_dm:
      self.ph.Run(pdb_in=self.ph.pdb_out, mtz_in=self.ph.mtz_out, mb_mod=1, intcyc=10, mtzin_col=mtzin_col)
      dmbr.Run(mtz_in=self.ph.mtz_out, mtzin_col=mtzin_col, ph_intcyc=0, skip_ncs_det=1)
      self.try_dm=0

  def Run(self, mtzin_col=None, start_dm=0, find_new=1):
    self.finish_mode = 0
    dmbr=dm_br(self.ph,self.dm_be,self.dm)
    # prepare phases for initial model building
    if start_dm:
      self.dm.bigcyc=self.dm.bigcyc*2
      dmbr.Run(mtzin_col=mtzin_col, ph_intcyc=0, skip_ncs_det=1)
      self.dm.bigcyc=self.dm.bigcyc/2
    else:
      shutil.copyfile(self.dm.mtzinit, self.ph.mtz_out)
    # for convenience
    mb=self.mb
    # go!
    for mb.cyc in range(1, mb.maxbigcyc+1):
      skip_bias_est = (mb.cyc-1)%self.bias_reest_cyc
      # ncs parameters will be ignored for solomon
      skip_ncs_det = (mb.cyc-2)%self.bias_reest_cyc  if mb.cyc>1  else 1
      # build model
      mb.Run(mtz_in=self.ph.mtz_out, mtzin_col=mtzin_col)
      # run density modification recycling (with bias reduction at specified mb cycles)
      dmbr.Run(skip_bias_est, mb.pdb_out, skip_ncs_det=skip_ncs_det, mtz_in=self.ph.mtz_out, mtzin_col=mtzin_col)
      # simple (mainly FOM based) decision making
      self.decide()
      if mb.minbigcyc<=0:
        break
      # try some simple extra actions before new bias estimation if we are not successful yet
      if mb.cyc%self.bias_reest_cyc==0:
        self.try_something(find_new,dmbr,mtzin_col)
    self.Clean(self.dm_be.mtzinitwork)
    # rough FOM based result estimation and printing
    self.FOMresult()
