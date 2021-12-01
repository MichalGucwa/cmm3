#!/bin/bash

source /home/dust/ccp4-6.2.0/setup-scripts/sh/ccp4.setup
source /home/dust/ccp4-6.2.0/setup-scripts/sh/ccp4-others.setup
perl $1 $2 $3 &> $4
exit
