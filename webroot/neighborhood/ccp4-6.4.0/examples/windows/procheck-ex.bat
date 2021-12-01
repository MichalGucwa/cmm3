#!/bin/sh

cd $CCP4_SCR

procheck $CEXAM/toxd/toxd.pdb 2.3

gs toxd_??.ps

#
