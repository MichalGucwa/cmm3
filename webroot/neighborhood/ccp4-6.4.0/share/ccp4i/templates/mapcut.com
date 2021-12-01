#
#     Copyright (C) 2011  Kevin Cowtan
#     mapcut script template
#

{ [StringSame $MAPSRC MTZ] } mtzin $HKLIN
{ [StringSame $MAPSRC MAP] } mapin $MAPIN
{ [StringSame $MSKSRC PDB] } pdbin $XYZIN
{ [StringSame $MSKSRC MSK] } mskin $MSKIN
{ [StringSame $MAPDST MTZ] } mtzout $HKLOUT
{ [StringSame $MAPDST MAP] } mapout $MAPOUT
{ [StringSame $MAPSRC MTZ] } colin-fc $FMAP,$PHIMAP
1 mask-radius $MSKRAD
1 cell-multiplier $GRDMUL
$DOPAD pad-resolution