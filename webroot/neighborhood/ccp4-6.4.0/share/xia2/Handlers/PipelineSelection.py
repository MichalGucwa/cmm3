#!/usr/bin/env python
# PipelineSelection.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A handler to manage the selection of pipelines through which to run xia2,
# for instance what indexer to use, what integrater and what scaler.
# This will look for a file preferences.xia in ~/.xia2 or equivalent,
# and the current working directory.

import os
import sys

def check(key, value):
    '''Check that this thing is allowed to have this value.'''

    # this should be current!

    allowed_indexers = [
        'mosflm', 'labelit', 'labelitii', 'xds', 'xdsii', 'xdssum']
    allowed_integraters = ['mosflmr', 'xdsr', 'mosflm', 'xds']
    allowed_scalers = ['ccp4r', 'ccp4a', 'xdsr', 'xdsa', 'ccp4', 'xds']

    if key == 'indexer':
        if not value in allowed_indexers:
            raise RuntimeError, 'indexer %s unknown' % value
        return value

    if key == 'integrater':
        if not value in allowed_integraters:
            raise RuntimeError, 'integrater %s unknown' % value
        if value == 'mosflm':
            return 'mosflmr'
        if value == 'xds':
            return 'xdsr'
        return value

    if key == 'scaler':
        if not value in allowed_scalers:
            raise RuntimeError, 'scaler %s unknown' % value
        if value == 'ccp4':
            return 'ccp4r'
        if value == 'xds':
            return 'xdsr'
        return value

    return

preferences = { }

def get_preferences():
    global preferences

    if preferences == { }:
        search_for_preferences()

    return preferences

def add_preference(key, value):
    '''Add in run-time a preference.'''

    global preferences

    value = check(key, value)

    if preferences.has_key(key):
        if preferences[key] != value:
            raise RuntimeError, 'setting %s to %s: already %s' % \
                  (key, value, preferences[key])

    preferences[key] = value

    return

def search_for_preferences():
    '''Search for a preferences file, first in HOME then here.'''

    global preferences

    if os.name == 'nt':
        homedir = os.path.join(os.environ['HOMEDRIVE'],
                               os.environ['HOMEPATH'])
        xia2dir = os.path.join(homedir, 'xia2')
    else:
        homedir = os.environ['HOME']
        xia2dir = os.path.join(homedir, '.xia2')

    if os.path.exists(os.path.join(xia2dir, 'preferences.xia')):
        preferences = parse_preferences(
            os.path.join(xia2dir, 'preferences.xia'), preferences)

    # look also in current working directory

    if os.path.exists(os.path.join(os.getcwd(), 'preferences.xia')):
        preferences = parse_preferences(
            os.path.join(os.getcwd(), 'preferences.xia'), preferences)

    return preferences

def parse_preferences(file, preferences):
    '''Parse preferences to the dictionary.'''

    for line in open(file, 'r').readlines():

        # all lower case
        line = line.lower()

        # ignore comment lines
        if line[0] == '!' or line[0] == '#' or not line.split():
            continue

        key = line.split(':')[0].strip()
        value = line.split(':')[1].strip()

        value = check(key, value)

        add_preference(key, value)

    return preferences

if __name__== '__main__':

    print search_for_preferences()
