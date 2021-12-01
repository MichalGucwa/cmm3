#
#     Copyright (C) 2006-2008  Kevin Cowtan
#     Buccaneer script template
#

1 title $TITLE
1 pdbin-ref $XYZINref 
1 mtzin-ref $HKLINref 
1 colin-ref-fo /*/*/\\\[$FPref,$SIGFPref\\\]
1 colin-ref-hl /*/*/\\\[$HLAref,$HLBref,$HLCref,$HLDref\\\]
$USEXYZIN  pdbin-wrk $XYZINwrk
$USEXYZSQ  pdbin-wrk-sequence-prior $XYZINseq
$DOSEQNC seqin-wrk $SEQINwrk
1 mtzin-wrk $HKLINwrk
1 colin-wrk-fo /*/*/\\\[$FPwrk,$SIGFPwrk\\\]
{ $USEPHIW != 1 } colin-wrk-hl /*/*/\\\[$HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk\\\]
{ $USEPHIW == 1 } colin-wrk-phifom /*/*/\\\[$PHIwrk,$FOMwrk\\\]
$USEFMAP colin-wrk-fc     /*/*/\\\[$FMAPwrk,$PMAPwrk\\\]
$USEFREE colin-wrk-free   /*/*/\\\[$FREEwrk\\\]

1 pdbout-wrk $XYZOUT

$DOFIND  find
$DOGROW  grow
$DOJOIN  join
$DOLINK  link
$DOSEQNC sequence
$DOCORCT correct
$DOFILTR filter
$DONCSRB ncsbuild
$DOPRUNE prune
$DOBUILD rebuild

$DOFAST  fast
$DOANIS  anisotropy-correction
$DOSEMET  build-semet
$DOFIXPOS fix-position

$USECORR correlation-mode
1 cycles $NCYCLE
1 fragments $NFRAGS
1 fragments-per-100-residues $NFRAGR

1 sequence-reliability $SEQREL
1 new-residue-name $NEWRESNM

1 resolution $RESOLUTION_MAX

1 ramachandran-filter $RAMAFLT
