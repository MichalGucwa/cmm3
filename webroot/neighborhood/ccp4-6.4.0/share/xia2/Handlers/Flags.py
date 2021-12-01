#/usr/bin/env python
# Flags.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 4th May 2007
#
# A singleton to handle flags, which can be imported more easily
# as it will not suffer the problems with circular references that
# the CommandLine singleton suffers from.

import os
import sys

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT not defined'
if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

if not os.environ['XIA2_ROOT'] in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2_ROOT']))

from Handlers.Environment import get_number_cpus
from Toolkit.BackstopMask import BackstopMask

class _Flags:
    '''A singleton to manage boolean flags.'''

    # by default now switch on smart scaling and chef - after the smart
    # scaling has been reset in the XDS Scaler to be "everything"

    def __init__(self):
        self._quick = False
        self._interactive = False
        self._ice = False
        self._egg = False
        self._uniform_sd = True
        self._chef = False
        self._mask = None
        self._reversephi = False
        self._no_lattice_test = False
        self._migrate_data = False
        self._trust_timestaps = False

        # XDS specific things - to help with handling tricky data sets

        self._xparm = None
        self._xparm_beam_vector = None
        self._xparm_rotation_axis = None
        self._xparm_origin = None

        self._xparm_a = None
        self._xparm_b = None
        self._xparm_c = None

        try:
            self._parallel = get_number_cpus()
        except:
            self._parallel = 0

        self._xparallel = 0

        self._min_images = 10
        self._start_end = None

        self._batch_scale = False

        # File from which to copy the FreeR_flag column
        self._freer_file = None

        # or alternatively the fraction, or total number of free
        # reflections
        self._free_fraction = None
        self._free_total = None

        # reference reflection file
        self._reference_reflection_file = None

        # these are development parameters for the XDS implementation
        self._z_min = 0.0
        self._remove = True
        self._zero_dose = False
        self._relax = True
        self._profile = True

        # and these for the Mosflm / Scala and perhaps XDS implementation

        self._scale_model = False
        self._scale_model_decay = False
        self._scale_model_modulation = False
        self._scale_model_absorption = False
        self._scale_model_partiality = False

        self._rmerge_target = 'low'

        # options to support the -spacegroup flag - the spacegroup is
        # set from this, the lattice and pointgroup derived from such
        self._spacegroup = None
        self._pointgroup = None
        self._lattice = None

        # scala secondary correction
        self._scala_secondary = 6

        # options to support the -cell option
        self._cell = None

        # resolution limit flags
        self._resolution_low = None
        self._resolution_high = None

        # and these are general rejection criteria
        self._rejection_threshold = 1.5
        self._isigma = 1.0
        self._misigma = 2.0
        self._completeness = 0.0
        self._rmerge = 0.0

        self._microcrystal = False
        self._failover = False
        self._blend = False

        # are we working with small molecule data?
        self._small_molecule = False

        # flags relating to fixing specific bugs
        self._fixed_628 = False

        # ISPyB things
        self._ispyb_xml_out = None

        # header cache / json things
        self._hdr_in = None
        self._hdr_out = None

        return

    def set_batch_scale(self, batch_scale):
        self._batch_scale = batch_scale
        return

    def get_batch_scale(self):
        return self._batch_scale

    def set_rmerge_target(self, rmerge_target):
        assert(rmerge_target in ['low', 'high', 'overall'])
        self._rmerge_target = rmerge_target
        return

    def get_rmerge_target(self):
        return self._rmerge_target

    # matters relating to the manual definition of a scaling model

    def set_scale_model(self, scale_model):
        self._scale_model = scale_model

        # now unpack this

        self.set_scale_model_decay('decay' in scale_model)
        self.set_scale_model_modulation('modulation' in scale_model)
        self.set_scale_model_absorption('absorption' in scale_model)
        self.set_scale_model_partiality('partiality' in scale_model)

        return

    def get_scale_model(self):
        return self._scale_model

    def set_scale_model_decay(self, scale_model_decay = True):
        self._scale_model_decay = scale_model_decay
        return

    def get_scale_model_decay(self):
        return self._scale_model_decay

    def set_scale_model_modulation(self, scale_model_modulation = True):
        self._scale_model_modulation = scale_model_modulation
        return

    def get_scale_model_modulation(self):
        return self._scale_model_modulation

    def set_scale_model_absorption(self, scale_model_absorption = True):
        self._scale_model_absorption = scale_model_absorption
        return

    def get_scale_model_absorption(self):
        return self._scale_model_absorption

    def set_scale_model_partiality(self, scale_model_partiality = True):
        self._scale_model_partiality = scale_model_partiality
        return

    def get_scale_model_partiality(self):
        return self._scale_model_partiality

    # the end of such matters

    ### SETTING OF RESOLUTION LIMITS #### bug # 3183

    def set_resolution_high(self, resolution):
        self._resolution_high = resolution
        return

    def set_resolution_low(self, resolution):
        self._resolution_low = resolution
        return

    def get_resolution_high(self):
        return self._resolution_high

    def get_resolution_low(self):
        return self._resolution_low

    def set_spacegroup(self, spacegroup):
        '''A handler for the command-line option -spacegroup - this will
        set the spacegroup and derive from this the pointgroup and lattice
        appropriate for such...'''

        from Handlers.Syminfo import Syminfo

        spacegroup = spacegroup.upper()

        # validate by deriving the pointgroup and lattice...

        pointgroup = Syminfo.get_pointgroup(spacegroup)
        lattice = Syminfo.get_lattice(spacegroup)

        # assign

        self._spacegroup = spacegroup
        self._pointgroup = pointgroup
        self._lattice = lattice

        # debug print

        from Handlers.Streams import Debug

        Debug.write('Derived information from spacegroup flag: %s' % \
                    spacegroup)
        Debug.write('Pointgroup: %s  Lattice: %s' % (pointgroup, lattice))

        # indicate that since this has been assigned, we do not wish to
        # test it!

        self.set_no_lattice_test(True)

        return

    def get_spacegroup(self):
        return self._spacegroup

    def get_pointgroup(self):
        return self._pointgroup

    def get_lattice(self):
        return self._lattice

    def set_cell(self, cell):
        self._cell = cell
        return

    def get_cell(self):
        return self._cell

    def set_quick(self, quick):
        self._quick = quick
        return

    def get_quick(self):
        return self._quick

    def set_interactive(self, interactive):
        self._interactive = interactive
        return

    def get_interactive(self):
        return self._interactive

    def set_ice(self, ice):
        self._ice = ice
        return

    def get_ice(self):
        return self._ice

    def set_egg(self, egg):
        self._egg = egg
        return

    def get_egg(self):
        return self._egg

    def set_uniform_sd(self, uniform_sd):
        self._uniform_sd = uniform_sd
        return

    def get_uniform_sd(self):
        return self._uniform_sd

    def set_chef(self, chef):
        self._chef = chef
        return

    def get_chef(self):
        return self._chef

    def set_reversephi(self, reversephi):
        self._reversephi = reversephi
        return

    def get_reversephi(self):
        return self._reversephi

    def set_no_lattice_test(self, no_lattice_test):
        self._no_lattice_test = no_lattice_test
        return

    def get_no_lattice_test(self):
        return self._no_lattice_test

    def set_relax(self, relax):
        self._relax = relax
        return

    def get_relax(self):
        return self._relax

    def set_profile(self, profile):
        self._profile = profile
        return

    def get_profile(self):
        return self._profile

    def set_migrate_data(self, migrate_data):
        self._migrate_data = migrate_data
        return

    def get_migrate_data(self):
        return self._migrate_data

    def set_trust_timestamps(self, trust_timestamps):
        self._trust_timestamps = trust_timestamps
        return

    def get_trust_timestamps(self):
        return self._trust_timestamps

    def set_small_molecule(self, small_molecule):
        self._small_molecule = small_molecule
        return

    def get_small_molecule(self):
        return self._small_molecule

    def set_parallel(self, parallel):
        self._parallel = parallel
        return

    def get_parallel(self):
        return self._parallel

    def set_xparm(self, xparm):

        self._xparm = xparm

        from Wrappers.XDS.XDS import xds_read_xparm

        xparm_info = xds_read_xparm(xparm)

        self._xparm_origin = xparm_info['ox'], xparm_info['oy']
        self._xparm_beam_vector = tuple(xparm_info['beam'])
        self._xparm_rotation_axis = tuple(xparm_info['axis'])
        self._xparm_distance = xparm_info['distance']

        return

    def get_xparm(self):
        return self._xparm

    def get_xparm_origin(self):
        return self._xparm_origin

    def get_xparm_rotation_axis(self):
        return self._xparm_rotation_axis

    def get_xparm_beam_vector(self):
        return self._xparm_beam_vector

    def get_xparm_distance(self):
        return self._xparm_distance

    def set_xparm_ub(self, xparm):

        self._xparm_ub = xparm

        tokens = map(float, open(xparm, 'r').read().split())

        self._xparm_a = tokens[-9:-6]
        self._xparm_b = tokens[-6:-3]
        self._xparm_c = tokens[-3:]
        
        return

    def get_xparm_a(self):
        return self._xparm_a

    def get_xparm_b(self):
        return self._xparm_b

    def get_xparm_c(self):
        return self._xparm_c

    def set_min_images(self, min_images):
        self._min_images = min_images
        return

    def get_min_images(self):
        return self._min_images

    def set_start_end(self, start, end):
        assert(end > start)
        self._start_end = start, end
        return

    def get_start_end(self):
        return self._start_end

    def set_xparallel(self, xparallel):
        self._xparallel = xparallel
        return

    def get_xparallel(self):
        return self._xparallel

    def set_z_min(self, z_min):
        self._z_min = z_min
        return

    def get_z_min(self):
        return self._z_min

    def set_scala_secondary(self, scala_secondary):
        self._scala_secondary = scala_secondary
        return

    def get_scala_secondary(self):
        return self._scala_secondary

    def set_freer_file(self, freer_file):

        # mtzdump this file to make sure that there is a FreeR_flag
        # column therein...

        freer_file = os.path.abspath(freer_file)

        if not os.path.exists(freer_file):
            raise RuntimeError, '%s does not exist' % freer_file

        from Modules.FindFreeFlag import FindFreeFlag
        from Handlers.Streams import Debug

        column = FindFreeFlag(freer_file)

        Debug.write('FreeR_flag column in %s found: %s' % \
                    (freer_file, column))

        self._freer_file = freer_file
        return

    def get_freer_file(self):
        return self._freer_file

    def set_free_fraction(self, free_fraction):
        self._free_fraction = free_fraction
        return

    def get_free_fraction(self):
        return self._free_fraction

    def set_free_total(self, free_total):
        self._free_total = free_total
        return

    def get_free_total(self):
        return self._free_total

    def set_mask(self, mask):
        self._mask = BackstopMask(mask)
        return

    def get_mask(self):
        return self._mask

    def set_ispyb_xml_out(self, ispyb_xml_out):
        self._ispyb_xml_out = ispyb_xml_out
        return

    def get_ispyb_xml_out(self):
        return self._ispyb_xml_out

    def set_hdr_in(self, hdr_in):
        self._hdr_in = hdr_in

        from Wrappers.XIA.Diffdump import HeaderCache
        from Handlers.Streams import Debug

        Debug.write('Read %d headers from %s' % (HeaderCache.read(hdr_in),
                                                 hdr_in))
        
        return

    def get_hdr_in(self):
        return self._hdr_in

    def set_hdr_out(self, hdr_out):
        self._hdr_out = hdr_out
        return

    def get_hdr_out(self):
        return self._hdr_out

    def set_fixed_628(self):
        self._fixed_628 = True
        return

    def get_fixed_628(self):
        return self._fixed_628

    def set_reference_reflection_file(self, reference_reflection_file):
        '''Set a new reference reflection file.'''

        reference_reflection_file = os.path.abspath(reference_reflection_file)

        if not os.path.exists(reference_reflection_file):
            raise RuntimeError, '%s does not exist' % reference_reflection_file

        self._reference_reflection_file = reference_reflection_file

        return

    def get_reference_reflection_file(self):
        return self._reference_reflection_file

    def set_rejection_threshold(self, rejection_threshold):
        self._rejection_threshold = rejection_threshold
        return

    def get_rejection_threshold(self):
        return self._rejection_threshold

    def set_isigma(self, isigma):
        self._isigma = isigma
        return

    def get_isigma(self):
        return self._isigma

    def set_misigma(self, misigma):
        self._misigma = misigma
        return

    def get_misigma(self):
        return self._misigma

    def set_completeness(self, completeness):
        self._completeness = completeness
        return

    def get_completeness(self):
        return self._completeness

    def set_rmerge(self, rmerge):
        self._rmerge = rmerge
        return

    def get_rmerge(self):
        return self._rmerge

    def set_microcrystal(self, microcrystal = True):
        self._microcrystal = microcrystal
        return

    def get_microcrystal(self):
        return self._microcrystal

    def set_failover(self, failover = True):
        self._failover = failover
        return

    def get_failover(self):
        return self._failover

    def set_blend(self, blend = True):
        self._blend = blend
        return

    def get_blend(self):
        return self._blend

    def set_remove(self, remove):
        self._remove = remove
        return

    def get_remove(self):
        return self._remove

    def set_zero_dose(self, zero_dose):
        self._zero_dose = zero_dose
        return

    def get_zero_dose(self):
        return self._zero_dose

Flags = _Flags()
