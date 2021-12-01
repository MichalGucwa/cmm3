#!/bin/bash

source /home/sg/neighborhood/ccp4.setup
source /home/sg/neighborhood/ccp4-others.setup
#echo "perl $1 $2 $3 &> $4"
perl $1 $2 $3 &> $4
exit
