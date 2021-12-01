#!/usr/bin/env python
# IndexSelectImages.py
#
#   Copyright (C) 2011 Diamond Light Source, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# Code for the selection of images for autoindexing - selecting lone images
# from a list or wedges from a list, for Mosflm / Labelit and XDS respectively.

import math

def index_select_images_lone(phi_width, images):
    '''Select images close to 0, 45 and 90 degrees from the list of available
    frames. N.B. we assume all frames have the same oscillation width.'''

    selected_images = [images[0]]

    offset = images[0] - 1

    if offset + int(90.0 / phi_width) in images:
        selected_images.append(offset + int(45.0 / phi_width))
        selected_images.append(offset + int(90.0 / phi_width))

    else:
        middle = len(images) // 2 - 1
        if len(images) >= 3:
            selected_images.append(images[middle])
        selected_images.append(images[-1])

    return selected_images

def index_select_images_user(phi_width, images, out_stream):
    '''Select images close to 0, 45 and 90 degrees from the list of available
    frames. N.B. we assume all frames have the same oscillation width. From
    this the user can tweak the settings...'''

    images = index_select_images_lone(phi_width, images)

    images_list = '%d' % images[0]
    for image in images[1:]:
        images_list += ', %d' % image

    out_stream.write('Existing images for indexing: %s' % \
                     images_list)

    while True:

        record = raw_input('>')

        if not record.strip():
            return images

        try:
            images = map(int, record.replace(',', ' ').split())
            images_list = '%d' % images[0]
            for image in images[1:]:
                images_list += ', %d' % image

            out_stream.write('New images for indexing: %s' % \
                             images_list)

            return images

        except ValueError, e:
            pass

    # should not reach here but...

    return images

if __name__ == '__main__':

    images = range(1, 91)

    assert(index_select_images_lone(0.5, images) == [1, 45, 90])
    assert(index_select_images_lone(1.0, images) == [1, 45, 90])
    assert(index_select_images_lone(2.0, images) == [1, 22, 45])

    images = range(1, 361)

    assert(index_select_images_lone(0.5, images) == [1, 90, 180])
    assert(index_select_images_lone(1.0, images) == [1, 45, 90])
