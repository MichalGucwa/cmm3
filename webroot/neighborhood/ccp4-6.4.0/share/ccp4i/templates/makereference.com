#
#     Copyright (C) 2004  Kevin Cowtan
#     makereference script template
#

1 pdbid $PDBID
{ [StringSame $MODEDOWNLOAD NODOWNLOAD] } pdbin $PDBIN
{ [StringSame $MODEDOWNLOAD NODOWNLOAD] } cifin $CIFIN
1 mtzout $HKLOUT
1 pdbout $XYZOUT
$RESOLUTION resolution $RESOLUTION_MAX
