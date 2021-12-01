#!/usr/bin/env python
# IntegraterFactory.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A factory for Integrater implementations. At the moment this will
# support only Mosflm, XDS and the null integrater implementation.
#

import os
import sys
import copy

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT not defined'

if not os.environ['XIA2_ROOT'] in sys.path:
    sys.path.append(os.environ['XIA2_ROOT'])

from Wrappers.CCP4 import Mosflm
from Handlers.Streams import Debug
from Handlers.Flags import Flags
from Handlers.PipelineSelection import get_preferences, add_preference

from Modules.Integrater.XDSIntegrater import XDSIntegrater

from DriverExceptions.NotAvailableError import NotAvailableError

# FIXME 06/SEP/06 this should take an implementation of indexer to
#                 help with the decision about which integrater to
#                 use, and also to enable invisible configuration.
#
# FIXME 06/SEP/06 also need interface which will work with xsweep
#                 objects.

def IntegraterForXSweep(xsweep):
    '''Create an Integrater implementation to work with the provided
    XSweep.'''

    # FIXME this needs properly implementing...
    if xsweep == None:
        raise RuntimeError, 'XSweep instance needed'

    if not xsweep.__class__.__name__ == 'XSweep':
        raise RuntimeError, 'XSweep instance needed'

    integrater = Integrater()
    integrater.setup_from_image(os.path.join(xsweep.get_directory(),
                                             xsweep.get_image()))
    integrater.set_integrater_sweep_name(xsweep.get_name())

    # copy across resolution limits
    if xsweep.get_resolution_high():

        dmin = xsweep.get_resolution_high()
        dmax = xsweep.get_resolution_low()

        if dmin and dmax:

            Debug.write('Assinging resolution limits from XINFO input:')
            Debug.write('dmin: %.3f dmax: %.2f' % (dmin, dmax))
            integrater.set_integrater_resolution(dmin, dmax, user = True)

        else:

            Debug.write('Assinging resolution limits from XINFO input:')
            Debug.write('dmin: %.3f' % dmin)
            integrater.set_integrater_high_resolution(dmin, user = True)

    # check the epoch and perhaps pass this in for future reference
    # (in the scaling)
    if xsweep._epoch > 0:
        integrater.set_integrater_epoch(xsweep._epoch)

    if xsweep.get_reversephi() or Flags.get_reversephi():
        Debug.write('Setting reverse-phi')
        integrater.set_reversephi()

    # need to do the same for wavelength now as that could be wrong in
    # the image header...

    if xsweep.get_wavelength_value():
        Debug.write('Integrater factory: Setting wavelength: %.6f' % \
                    xsweep.get_wavelength_value())
        integrater.set_wavelength(xsweep.get_wavelength_value())

    # likewise the distance...
    if xsweep.get_distance():
        Debug.write('Integrater factory: Setting distance: %.2f' % \
                    xsweep.get_distance())
        integrater.set_distance(xsweep.get_distance())

    integrater.set_integrater_sweep(xsweep)

    return integrater

def Integrater():
    '''Return an  Integrater implementation.'''

    # FIXME this should take an indexer as an argument...

    integrater = None
    preselection = get_preferences().get('integrater')

    if not integrater and (not preselection or preselection == 'mosflmr'):
        try:
            integrater = Mosflm.Mosflm()
            Debug.write('Using MosflmR Integrater')
            if not get_preferences().get('scaler'):
                add_preference('scaler', 'ccp4r')
        except NotAvailableError, e:
            if preselection == 'mosflmr':
                raise RuntimeError, \
                      'preselected integrater mosflmr not available'
            pass

    if not integrater and \
           (not preselection or preselection == 'xdsr'):
        try:
            integrater = XDSIntegrater()
            Debug.write('Using XDS Integrater in new resolution mode')
        except NotAvailableError, e:
            if preselection == 'xdsr':
                raise RuntimeError, \
                      'preselected integrater xdsr not available: ' + \
                      'xds not installed?'
            pass

    if not integrater:
        raise RuntimeError, 'no integrater implementations found'

    # check to see if resolution limits were passed in through the
    # command line...

    dmin = Flags.get_resolution_high()
    dmax = Flags.get_resolution_low()

    if dmin:
        Debug.write('Adding user-assigned resolution limits:')

        if dmax:

            Debug.write('dmin: %.3f dmax: %.2f' % (dmin, dmax))
            integrater.set_integrater_resolution(dmin, dmax, user = True)

        else:

            Debug.write('dmin: %.3f' % dmin)
            integrater.set_integrater_high_resolution(dmin, user = True)


    return integrater

if __name__ == '__main__':
    integrater = Integrater()
