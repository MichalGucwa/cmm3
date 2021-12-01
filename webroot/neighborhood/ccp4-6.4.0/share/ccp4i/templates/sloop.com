#
#     Copyright (C) 2010  Kevin Cowtan
#     Sloop script template
#

1 title $TITLE
1 pdbin $XYZIN
1 mtzin $HKLIN
1 colin-fc /*/*/\\\[$FMAP,$PHIMAP\\\]
1 pdbout $XYZOUT
1 pdbout-loops $XYZOUT

1 resolution $RESOLUTION_MAX
1 clash-radius $CLASH_RAD
1 clash-penalty $CLASH_SCR
