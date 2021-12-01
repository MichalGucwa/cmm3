#!/usr/bin/env python
#Script to run SAD(-DM-ref)/SIRAS(-DM-ref) (or other) function with ARP/wARP without any modification of ARP/wARP package. 

import os,sys,re,shutil
import subprocess

dummy_env = os.path.join( os.getenv('CRANK'), 'bin', 'dummy' )
os.putenv('PATH', "{0}:{1}".format(dummy_env, os.getenv('PATH')) )
os.putenv('CCP4I_TOP', dummy_env)
### the following line is required for arpwarp 7.x
os.putenv('CBIN', dummy_env)

### catch basic variables
all_lines=""
str_set_beg = r'^(\s*|\s*set\s*)'
str_set_end = r'\s*=\s*(\'(.*)\'|(\S*))'
variables = ('WORKDIR', 'PROJECT', 'JOB_ID', 'CCP4I_DEFFILE', 'HEAVYIN')
PROJECT='UNKNOWN_PROJECT'
for line in sys.stdin:
  for var in variables:
    match = re.match(r"{0}{1}{2}".format(str_set_beg, var, str_set_end), line)
    if match:
      if match.group(3):
        globals()[var] = match.group(3)
      else:
        globals()[var] = match.group(4)
      break
  else:
    if not re.match(r'^\s*set\s*\S+\s*=',line):
      if re.match(r'^\s*\S+\s*=',line): 
        line = "set {0}".format(line)
      elif re.match(r'^(\s*$)|(\#)/',line): 
        line = ""
      else: 
        sys.exit("Wrong format of input line to run_arpwarp_refmac5D: {0}".format(line))
  all_lines = "{0}{1}".format(all_lines,line)

### write input.par file
if 'WORKDIR' not in globals():
  sys.exit('WORKDIR not defined. Exiting.')
try:
  PARFILE = open( os.path.join( WORKDIR, 'input.par' ), 'w' )
except:
  sys.exit("Parameter file {0}/input.par could not be created. Check the path and permissions.".format(WORKDIR))
else:
  PARFILE.write(all_lines)
  PARFILE.close()

### some additional small things that need to be done
if 'HEAVYIN' in globals() and os.path.isfile(HEAVYIN):
  shutil.copy(HEAVYIN, HEAVYIN+".ref")
shutil.copy( os.path.join(WORKDIR,'input.par'), os.path.join(WORKDIR,JOB_ID+'_arp_warp.par') )

### find arp/warp version and run arp/warp tracing
try:
  p = subprocess.Popen('arp_warp', stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  arp_out = p.communicate(input='end')
except subprocess.CalledProcessError:
  sys.exit("Error calling arp_warp:{0}".format(arp_out[1]))
else:
  search = re.search(r"ARP Ver. (\d)",arp_out[0])
  if not search:
    sys.exit("ARP/wARP version could not be determined. Check your ARP/wARP installation.")
  else:
    arp_ver = search.group(1)
if arp_ver <= 6:
  if 'CCP4I_DEFFILE' in globals():
    os.mkdir(os.path.join(WORKDIR,'CCP4_DATABASE'))
    with open(CCP4I_DEFFILE,'w') as f:
      f.write("#CCP4I VERSION DUMMY_REFMAC5\n#CCP4I PROJECT $PROJECT")
  with open(os.path.join(WORKDIR,JOB_ID+"_arp_warp_log.html"),'w') as g:
    subprocess.call( [os.path.join(os.getenv('warpbin'),'arp_warp.sh'),'ccp4i',os.path.join(WORKDIR,'input.par')], stdout=g)
else:
  with open(os.path.join(WORKDIR,JOB_ID+"_arp_warp.log"),'w') as g:
    subprocess.call( [os.path.join(os.getenv('warpbin'),'warp_tracing.sh'),os.path.join(WORKDIR,'input.par'),'1'], stdout=g)
#system("rm -f $WORKDIR/input.par");
#system("rm -f $CCP4I_DEFFILE $WORKDIR/CCP4_DATABASE/*");
#system("rmdir $WORKDIR/CCP4_DATABASE");
