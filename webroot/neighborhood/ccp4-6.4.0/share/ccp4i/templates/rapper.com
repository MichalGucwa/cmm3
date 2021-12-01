#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#     Extended for RAPPER by Nichols Furnham 2007
#
########################################################################
# RAPPER - KEYWORD TEMPLATE
########################################################################
1 FILES
1 --pdb-in $XYZIN
1 --map $MAPIN
1 --pdb-out $XYZOUT

1 BUILD PARAMS
1 --start $RES_START
1 --stop $RES_STOP


1 --chain-id $CHAIN_ID
1 --cryst-d-high $RESOLUTION
1 --models $MODEL_NUM

1 POSITIONAL RESTRAINTS
$MC_RES --enforce-mainchain-restraints true --mainchain-restraint-threshold $MC_RAD
$SC_RES --sidechain-mode smart --sidechain-radius-reduction 0.5 --enforce-sidechain-centroid-restraints true --sidechain-centroid-restraint-threshold $SC_RAD --sidchain-library $ROTOMER_LIB

1 OPTIONAL ARGS
$EDM_FILTERS --use-edm-filters true
$RES_OPT --restraints-are-pass-optional true
$MC_SIGMA_OPT --enforce-mainchain-min-sigma-restraints true --edm-mainchain-min-sigma $MC_SIGMA 
$SC_SIGMA_OPT --enforce-sidechain-min-sigma-restraints true --edm-sidechain-min-sigma $SC_SIGMA
$EDM_OPT --optional-edm-mainchain-restraints true
$ANCHOR_OPT --strict-anchors true
$ANCHOR_OPT2 --enforce-strict-anchor-geometry true
$CONTACT_FILTERS --use-contact-filters true

1 BAD FIT ARGS
1 --edm-rebuild-poor-regions true
1 --divide-and-conquer false
1 --divide-and-conquer-ignore-chain-breaks true 
1 --default-mainchain-b-factor 20.0 --default-sidechain-b-factor 30.0 --models-get-native-bfactors false
1 --error-for-no-models false --fix-mislabeled-atoms false --write-user-remarks false
1 --edm-poor-region-threshold $EDM_POOR_TH
1 --edm-poor-region-buffer-size $EDM_BUFF_SIZE
