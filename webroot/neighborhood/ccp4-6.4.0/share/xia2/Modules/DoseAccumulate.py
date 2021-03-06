#!/usr/bin/env python
# DoseAccumulate.py
#   Copyright (C) 2007 STFC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A module to determine the accumulated dose as a function of exposure epoch
# for a given set of images, assuming:
#
# (i)  the set is complete
# (ii) the set come from a single (logical) crystal
#
# This is to work with fortran program "doser" and also to help fix
# Bug # 2798.
#

import os, sys

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT undefined'

if not os.environ['XIA2_ROOT'] is sys.path:
    sys.path.append(os.environ['XIA2_ROOT'])

from Wrappers.XIA.Diffdump import Diffdump
from Handlers.Streams import Debug

def epocher(images):
    '''Get a list of epochs for each image in this list, returning as
    a list of tuples.'''

    result = []
    for i in images:
        dd = Diffdump()
        dd.set_image(i)
        header = dd.readheader()

        e = header['epoch']
        result.append((i, e))

    return result

def accumulate(images):
    '''Accumulate dose as a function of image epoch.'''

    dose = { }
    integrated_dose = { }

    for i in images:
        dd = Diffdump()
        dd.set_image(i)
        header = dd.readheader()

        d = header['exposure_time']
        e = header['epoch']

        dose[e] = d

    keys = dose.keys()

    keys.sort()

    accum = 0.0

    for k in keys:
        integrated_dose[k] = accum + 0.5 * dose[k]
        accum += dose[k]

    # ok, now check that the value for the maximum dose is < 1e6 - elsewise
    # chef may explode. or write out ****** as the values are too large for
    # an f8.1 format statement.

    max_dose = max([integrated_dose[k] for k in keys])

    factor = 1.0

    while max_dose / factor > 1.0e6:
        factor *= 10.0

    Debug.write('Doses scaled by %5.2e' % factor)

    # now divide all of those doses by factor

    for k in keys:
        integrated_dose[k] /= factor

    return integrated_dose, factor

if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise RuntimeError, '%s /path/to/image' % sys.argv[0]

    # FIXME with this I would like to be able to give a first batch
    # for a template, then print out the batch numbers computed from
    # the image number and an offset, to enable offline adding
    # of data with doser to test out development versions of chef.

    # don't worry, be static!

    offsets = {
        '9172_1_E1_###.img':0,
        '9172_1_E2_###.img':1000,
        '9172_2_###.img':2000,
        '9172_102_###.img':3000,
        '12287_1_E1_###.img':0,
        '12287_1_E2_###.img':100,
        '12287_2_###.img':200,
        '13185_2_E1_###.img':0,
        '13185_2_E2_###.img':1000,
        '13185_3_###.img':2000,
        'insulin_1_###.img':0,
        'thau_hires_1_###.mccd':0,
        'thau_lores_1_###.mccd':1000,
        '27032_1_E1_###.mccd':0,
        '27032_1_E2_###.mccd':100,
        '27032_2_###.mccd':200
        }

    batches = { }

    from Experts.FindImages import find_matching_images, \
         template_directory_number2image, image2template_directory
    from Handlers.Flags import Flags

    # just cos we can...
    Flags.set_trust_timestamps(True)

    image_names = []
    for image in sys.argv[1:]:

        template, directory = image2template_directory(image)
        images = find_matching_images(template, directory)

        batch_images = []

        for i in images:
            image = template_directory_number2image(
                template, directory, i)
            image_names.append(image)
            batch_images.append(image)

        epochs = epocher(batch_images)
        for j in range(len(epochs)):
            batch = images[j] + offsets[template]
            batches[epochs[j][1]] = batch

    dose = accumulate(image_names)
    epochs = dose.keys()
    epochs.sort()

    e0 = min(epochs)

    for e in epochs:
        print 'batch %d time %f dose %f' % \
              (batches[e], e - e0, dose[e])
