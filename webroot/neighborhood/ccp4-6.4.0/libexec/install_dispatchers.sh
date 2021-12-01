#!/bin/sh

### This script wraps envExtractor and dispatcherGenerator for standard
### creation of the CCP4Dispatcher package as part of the CCP4 install
### procedure on Linux and Mac OSX. It requires a correctly sourced CCP4
### environment, and expects that environment to be defined in
### $CCP4/bin/ccp4.setup-sh.

# Ensure CCP4 is not empty
if test -z "$CCP4"; then
  echo "This does not appear to be a correctly sourced CCP4 environment. \
Dispatchers will not be generated. Exiting." 1>&2
  exit 1
fi

# Find a python
if test -e $CCP4/bin/ccp4-python; then
  CCP4PYTHON=$CCP4/bin/ccp4-python
elif command -v python >/dev/null; then
  CCP4PYTHON=python
else
  echo "An attempt was made to generate dispatchers, but no python was found. Exiting." 1>&2
  exit 1
fi

# Generate dispatchers
PKGDIR=$CCP4/share/python
LINKDIR=$PKGDIR/CCP4Dispatchers/bin
if cd $CCP4/libexec; then
   echo "Generating CCP4 Dispatchers....."
   if ! $CCP4PYTHON ./envExtractor.py $CCP4/bin/ccp4.setup-sh; then exit 1; fi
   if ! $CCP4PYTHON ./dispatcherGenerator.py -p $PKGDIR -l $LINKDIR ./ccp4-env.sh $CCP4/bin; then exit 1; fi
   if test -d $LINKDIR ; then
      mv ccp4-env.sh $LINKDIR/
   fi
   cd $CCP4
   echo
fi
