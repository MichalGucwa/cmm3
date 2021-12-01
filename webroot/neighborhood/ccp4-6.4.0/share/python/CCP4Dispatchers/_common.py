#
#     Copyright (C) 2013 David Waterman
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
"""Initialisation for the CCP4Dispatchers package"""

import os, string

envlist = [('CCP4I_TCLTK', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/bin'), ('CCP4_HELPDIR', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/help/'), ('CHTML', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/html'), ('XIA2CORE_ROOT', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/xia2/core'), ('GFORTRAN_UNBUFFERED_PRECONNECTED', '1'), ('XIA2_ROOT', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/xia2'), ('CCP4', '/home/dust/ccp4-6.4.0/ccp4-6.4.0'), ('CLIB', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/lib'), ('CEXAM', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/examples'), ('BALBES_ROOT', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/BALBES/Package'), ('CCP4I_TOP', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/ccp4i'), ('PATH', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/dbccp4i/bin:/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/ccp4i/bin:/home/dust/ccp4-6.4.0/ccp4-6.4.0/bin:/home/dust/ccp4-6.4.0/ccp4-6.4.0/etc:/home/dust/bin:/home/dust/.rvm/wrappers/ruby-1.9.3-p125/:/home/dust/ccp4-6.2.0/ccp4-6.2.0/bin:/home/dust/ccp4-6.2.0/ccp4-6.2.0/share/dbccp4i/bin:/home/dust/ccp4-6.2.0/ccp4-6.2.0/ccp4i/bin:/home/dust/ccp4-6.2.0/ccp4-6.2.0/bin:/home/dust/ccp4-6.2.0/ccp4-6.2.0/etc:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/dell/srvadmin/bin:/home/dust/ccp4-6.2.0/ccp4-6.2.0/share/xia2/xia2core//Test:/home/dust/ccp4-6.2.0/ccp4-6.2.0/share/xia2/xia2//Applications:/home/dust/.rvm/bin:/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/xia2/Applications:/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/xia2/Applications'), ('MOSFLM_EXEC', 'ipmosflm'), ('DBCCP4I_TOP', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/dbccp4i'), ('CCP4_OPEN', 'UNKNOWN'), ('CETC', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/etc'), ('CLIBD_MON', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/lib/data/monomers/'), ('CCP4_SCR', '/tmp/dust'), ('SHLVL', '1'), ('CRANK', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/share/ccp4i/crank'), ('CLIBD', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/lib/data'), ('CBIN', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/bin'), ('CINCL', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/include'), ('CCP4_MASTER', '/home/dust/ccp4-6.4.0'), ('MMCIFDIC', '/home/dust/ccp4-6.4.0/ccp4-6.4.0/lib/ccp4/cif_mmdic.lib')]

prog_to_dispatcher = {'mapdiff': 'mapdiff', 'mat2symop': 'mat2symop', 'convert2mtz': 'convert2mtz', 'prosmart': 'prosmart', 'angles': 'angles', 'ccp4um': 'ccp4um', 'distang': 'distang', 'fft': 'fft', 'phistats': 'phistats', 'pdbcur': 'pdbcur', 'ecalc': 'ecalc', 'cfft': 'cfft', 'idiffdisp': 'idiffdisp', 'findwaters': 'findwaters', 'mapmask': 'mapmask', 'phaser.ensembler': 'phaser_ensembler', 'mini-rsr': 'mini-rsr', 'bltwish24': 'bltwish24', 'afro': 'afro', 'crunch2': 'crunch2', 'mtztona4': 'mtztona4', 'ccp4i_condorsub': 'ccp4i_condorsub', 'rebatch': 'rebatch', 'watncs': 'watncs', 'build-guile-gtk-2.0': 'build-guile-gtk-2_0', 'fsearch': 'fsearch', 'ample': 'ample', 'get_heavy': 'get_heavy', 'bp3': 'bp3', 'cad': 'cad', 'extends': 'extends', 'ccp4um-bin': 'ccp4um-bin', 'hklplot': 'hklplot', 'findligand-real': 'findligand-real', 'density-score-by-residue': 'density-score-by-residue', 'getax': 'getax', 'dmmulti': 'dmmulti', 'nautilus_pipeline': 'nautilus_pipeline', 'shelx2map': 'shelx2map', 'refmac5': 'refmac5', 'dm': 'dm', 'secstr': 'secstr', 'rstats': 'rstats', 'cpatterson': 'cpatterson', 'pdbset': 'pdbset', 'vectors': 'vectors', 'sigmaa': 'sigmaa', 'scaleit': 'scaleit', 'fix-nomenclature-errors': 'fix-nomenclature-errors', 'worms': 'worms', 'prosmart_align': 'prosmart_align', 'siras_0atoms_hack': 'siras_0atoms_hack', 'chainsaw': 'chainsaw', 'avs2ps': 'avs2ps', 'sapi': 'sapi', 'reforigin': 'reforigin', 'get-residue-stats.pl': 'get-residue-stats_pl', 'seqwt': 'seqwt', 'unique': 'unique', 'align_DB': 'align_DB', 'create_docs': 'create_docs', 'ffjoin': 'ffjoin', 'stereo3d': 'stereo3d', 'cif2mtz': 'cif2mtz', 'get_trans': 'get_trans', 'f2mtz': 'f2mtz', 'geomcalc': 'geomcalc', 'almn': 'almn', 'buccaneer_pipeline': 'buccaneer_pipeline', 'rapper': 'rapper', 'gensym': 'gensym', 'bltsh24': 'bltsh24', 'mtz2sca': 'mtz2sca', 'znd_subs': 'znd_subs', 'JLogGraph.jar': 'JLogGraph_jar', 'mapro': 'mapro', 'wish': 'wish', 'rmsdev': 'rmsdev', 'rings3d': 'rings3d', 'matthews_coef': 'matthews_coef', 'cprodrg': 'cprodrg', 'multicomb': 'multicomb', 'add_heavy': 'add_heavy', 'r500ccp4': 'r500ccp4', 'maprot': 'maprot', 'professs': 'professs', 'mtzdiff': 'mtzdiff', 'hbond': 'hbond', 'gfac2pdb': 'gfac2pdb', 'rotamer': 'rotamer', 'sortwater': 'sortwater', 'tclsh': 'tclsh', 'chef': 'chef', 'pmf': 'pmf', 'pdb_extract_sf': 'pdb_extract_sf', 'doser': 'doser', 'zanuda': 'zanuda', 'cphasematch': 'cphasematch', 'check_cell_sg': 'check_cell_sg', 'ribbon': 'ribbon', 'vecref': 'vecref', 'binsort': 'binsort', 'rwcontents': 'rwcontents', 'alt_sg_list': 'alt_sg_list', 'cifdic_to_symtab': 'cifdic_to_symtab', 'cif2xml': 'cif2xml', 'truncate': 'truncate', 'compar': 'compar', 'scala': 'scala', 'icoefl': 'icoefl', 'pointless': 'pointless', 'pisa': 'pisa', 'pdb2s': 'pdb2s', 'check_file_DB': 'check_file_DB', 'ccp4sm': 'ccp4sm', 'cmaplocal': 'cmaplocal', 'abs': 'abs', 'dtrek2scala': 'dtrek2scala', 'csigmaa': 'csigmaa', 'automask': 'automask', 'sortmtz': 'sortmtz', 'ncont': 'ncont', 'phaser.sculptor': 'phaser_sculptor', 'cecalc': 'cecalc', 'find-blobs': 'find-blobs', 'sfcheck': 'sfcheck', 'cnautilus': 'cnautilus', 'cmapcut': 'cmapcut', 'prep_bulk': 'prep_bulk', 'ctruncate': 'ctruncate', 'refindex': 'refindex', 'tlsextract': 'tlsextract', 'makedict': 'makedict', 'gesamt': 'gesamt', 'mapsig': 'mapsig', 'check_zero_res.py': 'check_zero_res_py', 'symop2mat': 'symop2mat', 'acorn': 'acorn', 'amore': 'amore', 'qtpisa': 'qtpisa', 'pdbhtf': 'pdbhtf', 'molrep': 'molrep', 'del_heavy': 'del_heavy', 'save_seg_id': 'save_seg_id', 'cncsfrommodel': 'cncsfrommodel', 'rastep': 'rastep', 'symconv': 'symconv', 'pdb_pack': 'pdb_pack', 'mapexchange': 'mapexchange', 'percent-rank.pl': 'percent-rank_pl', 'proclean': 'proclean', 'csloop': 'csloop', 'omit': 'omit', 'superpose': 'superpose', 'mtz2various': 'mtz2various', 'tracer': 'tracer', 'na4tomtz': 'na4tomtz', 'topdraw': 'topdraw', 'scalepack2mtz': 'scalepack2mtz', 'maptona4': 'maptona4', 'act': 'act', 'r500': 'r500', 'fhscal': 'fhscal', 'revise': 'revise', 'othercell': 'othercell', 'bltwish': 'bltwish', 'reindex': 'reindex', 'sftools': 'sftools', 'toplist': 'toplist', 'render': 'render', 'sfall': 'sfall', 'rotgen': 'rotgen', 'bltsh': 'bltsh', 'viewhkl': 'viewhkl', 'ccp4iwish': 'ccp4iwish', 'comit': 'comit', 'balbes': 'balbes', 'asc2p84': 'asc2p84', 'overlapmap': 'overlapmap', 'dyndom': 'dyndom', 'cavenv': 'cavenv', 'areaimol': 'areaimol', 'cctbx.python': 'cctbx_python', 'map2fs': 'map2fs', 'lidia': 'lidia', 'ccp4-python': 'ccp4-python', 'coot-real': 'coot-real', 'hklview': 'hklview', 'jligand': 'jligand', 'pltdev': 'pltdev', 'mplot': 'mplot', 'lsqkab': 'lsqkab', 'tplot': 'tplot', 'cmodeltoseq': 'cmodeltoseq', 'postref': 'postref', 'mrbump': 'mrbump', 'vecsum': 'vecsum', 'caniso': 'caniso', 'diffdump': 'diffdump', 'cbuccaneer': 'cbuccaneer', 'pplot': 'pplot', 'zeroed': 'zeroed', 'cinvfft': 'cinvfft', 'watertidy': 'watertidy', 'tclsh8.4': 'tclsh8_4', 'mtzmnf': 'mtzmnf', 'baverage': 'baverage', 'havecs': 'havecs', 'anglen': 'anglen', 'symfit': 'symfit', 'peakmax': 'peakmax', 'difres': 'difres', 'csfcalc': 'csfcalc', 'mtzinfo': 'mtzinfo', 'crank': 'crank', 'chltofom': 'chltofom', 'pydbviewer': 'pydbviewer', 'csequins': 'csequins', 'mtz2cif': 'mtz2cif', 'iotbx.lattice_symmetry': 'iotbx_lattice_symmetry', 'bfactan': 'bfactan', 'qtrview': 'qtrview', 'coordconv': 'coordconv', 'density-score-by-residue-real': 'density-score-by-residue-real', 'balls': 'balls', 'ccp4_pipeline_simple': 'ccp4_pipeline_simple', 'sc': 'sc', 'diff2jpeg': 'diff2jpeg', 'mkdssp': 'mkdssp', 'crossec': 'crossec', 'p842asc': 'p842asc', 'imosflm': 'imosflm', 'f2cif': 'f2cif', 'logview': 'logview', 'detwin': 'detwin', 'polarrfn': 'polarrfn', 'solomon': 'solomon', 'freerflag': 'freerflag', 'get_structure_DB': 'get_structure_DB', 'ncsmask': 'ncsmask', 'csymmatch': 'csymmatch', 'anisoanl': 'anisoanl', 'normal3d': 'normal3d', 'stgrid': 'stgrid', 'bones2pdb': 'bones2pdb', 'mtz2hkl': 'mtz2hkl', 'pdbdiff': 'pdbdiff', 'tlsanl': 'tlsanl', 'mapreplace': 'mapreplace', 'cpirate': 'cpirate', 'hgen': 'hgen', 'surface': 'surface', 'mapslicer': 'mapslicer', 'loggraph': 'loggraph', 'printpeaks': 'printpeaks', 'prosmart_restrain': 'prosmart_restrain', 'bulking': 'bulking', 'fffear': 'fffear', 'mtzfix': 'mtzfix', 'ccp4i': 'ccp4i', 'rods': 'rods', 'OpenAstexViewer.jar': 'OpenAstexViewer_jar', 'search_DB': 'search_DB', 'mtzutils': 'mtzutils', 'rotmat': 'rotmat', 'wilson': 'wilson', 'mtzMADmod': 'mtzMADmod', 'solution_check': 'solution_check', 'ipmosflm': 'ipmosflm', 'dimple': 'dimple', 'nb': 'nb', 'stnet': 'stnet', 'cross_validate': 'cross_validate', 'domain2chain': 'domain2chain', 'rantan': 'rantan', 'oasis': 'oasis', 'cparrot': 'cparrot', 'dtrek2mtz': 'dtrek2mtz', 'build-guile-gtk': 'build-guile-gtk', 'gcx': 'gcx', 'findligand': 'findligand', 'pdb2to3': 'pdb2to3', 'tffc': 'tffc', 'npo': 'npo', 'libcheck': 'libcheck', 'rfcorr': 'rfcorr', 'combat': 'combat', 'mapdump': 'mapdump', 'topp': 'topp', 'findncs': 'findncs', 'check_zero_res': 'check_zero_res', 'phaser': 'phaser', 'pdb_merge': 'pdb_merge', 'cmakereference': 'cmakereference', 'get_chain': 'get_chain', 'helixang': 'helixang', 'wish8.4': 'wish8_4', 'coot': 'coot', 'mama2ccp4': 'mama2ccp4', 'watpeak': 'watpeak', 'pdb_extract': 'pdb_extract', 'volume': 'volume', 'stereo': 'stereo', 'aimless': 'aimless', 'mlphare': 'mlphare', 'mtzdump': 'mtzdump', 'cphasecombine': 'cphasecombine', 'axissearch': 'axissearch', 'extract': 'extract', 'ccp4ish': 'ccp4ish', 'contact': 'contact', 'probplot': 'probplot', 'edstats': 'edstats', 'edstats.pl': 'edstats_pl', 'findwaters-real': 'findwaters-real', 'rsps': 'rsps', 'coord_format': 'coord_format'}

def dispatcher_builder(program, cmd_args = None, keywords = None,
                       capture_streams = True, stdout = None, stderr = None):
    """Convenience factory function to set up and return a dispatcher in one
    line, using the original program name"""

    try:
        modulename = prog_to_dispatcher[program]
    except KeyError:
        msg = program + " is not found in the mapping to dispatchers"
        raise KeyError, msg

    _temp = __import__(modulename, globals(), locals(), ["Dispatcher"], -1)
    Dispatch = _temp.Dispatcher(capture_streams, stdout, stderr)

    if cmd_args: Dispatch.set_cmd_args(cmd_args)
    if keywords: Dispatch.set_keywords(keywords)

    return Dispatch

def call_here(program, key, cmdline, workingDIR, function=""):
    """Convenience function to set up and call a dispatcher in one line,
    writing output to files, principally for MrBump"""

    logfile = os.path.join(workingDIR, "%s%s.log" % (program, function))
    errfile = os.path.join(workingDIR, "%s%s.err" % (program, function))

    # Generate a shell script for this job
    if os.name != "nt":
        scriptfile = os.path.join(workingDIR, "%s%s.script" % (program, function))
        s = open(scriptfile,"w")
        s.write("#!/bin/sh\n")
        s.write(program + " " + cmdline + " <<eof\n")
        s.write(key)
        s.write("eof\n")
        s.close()

    # Import Dispatcher from the program name (must remove '.exe' on Windows)
    Dispatch = dispatcher_builder(program, cmdline, key)
    Dispatch.call()

    # Write out the stdout to the log file
    log = open(logfile, "w")
    for line in Dispatch.stdout_data:
        log.write(line + "\n")
    log.close()

    # Write out the stderr to the error file
    err=open(errfile, "w")
    for line in Dispatch.stderr_data:
       err.write(line + "\n")
    err.close()

    return Dispatch

def set_environment():
    """Function to set the environment variables"""

    # Read current environment in order to do any dynamic substitutions required
    env_var_dict = os.environ.copy()

    # Set specified environment variables
    for (var, val) in envlist:

        val_template = string.Template(val)
        val_sub = val_template.safe_substitute(env_var_dict)

        # Remove any remaining $IDENTIFIERS, to behave like bash does.
        val = val_template.pattern.sub("",val_sub)
        os.environ[var]= val

    # Find the path to the CCP4Dispatcher package
    pkg_path = os.path.dirname(os.path.realpath(__file__))

    # Prepend dispatcher package to the PATH, if not included already
    try:
        curr_path = os.environ["PATH"]
    except KeyError:
        curr_path = ""
    if not pkg_path in curr_path:
        os.environ["PATH"] = (pkg_path + os.pathsep + curr_path)

    # Prepend dispatcher package to PYTHONPATH, if not included already
    try:
        curr_pythonpath = os.environ["PYTHONPATH"]
    except KeyError:
        curr_pythonpath = ""
    pkg_parent = os.path.dirname(pkg_path)
    if not pkg_parent in curr_pythonpath:
        os.environ["PYTHONPATH"] = (pkg_parent + os.pathsep + curr_pythonpath)

