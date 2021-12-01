#
#     Copyright (C) 2004  Kevin Cowtan
#     phasecombine script template
#

1 mtzin $HKLIN
1 mtzout $HKLOUT
1 colin-hl-1 /*/*/\\\[$HLA1,$HLB1,$HLC1,$HLD1\\\]
1 colin-hl-2 /*/*/\\\[$HLA2,$HLB2,$HLC2,$HLD2\\\]
1 colout $COLOUT
1 weight-hl-1 $WEIGHT1
1 weight-hl-2 $WEIGHT2
