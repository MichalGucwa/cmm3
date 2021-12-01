::!/bin/sh
:: Phasing the rnase using Pt sites only.
:: See Sevcik, Dodson and Dodson, Acta Cryst. B47 240 (1991)

mlphare HKLIN %RNASE%\rnase25.mtz HKLOUT %TEMPRES%\rnase_phase_mir.mtz < %SCRIPTWIN%\mlphare-rnase.dat
