#
#     Copyright (C) 2004-2005  Kevin Cowtan
#     Pirate script template
#

1 mtzin-ref $HKLINref 
1 colin-ref-fo /*/*/\\\[$FPref,$SIGFPref\\\]
1 colin-ref-hl /*/*/\\\[$HLAref,$HLBref,$HLCref,$HLDref\\\]
1 mtzin-wrk $HKLINwrk
1 colin-wrk-fo /*/*/\\\[$FPwrk,$SIGFPwrk\\\]
1 colin-wrk-hl /*/*/\\\[$HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk\\\]
1 colin-wrk-free /*/*/\\\[$FREEwrk\\\]
1 mtzout $HKLOUT
1 colout $COLOUT

$NCSHA pdbin-ha $PDBINha
$NCSVIRUS ncs-volume 8.0

$AUTOCONT auto-content
$AUTOMAPW auto-mapllk
$AUTONCSW auto-ncsllk
1 skew-content $SKEWCONT1,$SKEWCONT2
1 weight-mapllk $WTMAPLLK
1 weight-ncsllk $WTNCSLLK

$UNBIAS   unbias
$STRICTFR strict-free
1 weight-expllk $WTEXPLLK

$EVALUATE evaluate
1 ncycles $NCYCLES
1 stats-radius $RADIUS1,$RADIUS2

