::!\bin\sh
::  overlapmap reads two or three maps, on the same grid, and 
::  works out certain useful functions.
::   Key words are:
:: MAP AVERAGE - add two maps and output new map
:: MAP EXCLUDE - exclude points from output map if they   exist in map1
:: MAP INCLUDE - include points from output map if they   exist in map1
:: CORRELATE  SECTION - correlation - section by section
:: CORRELATE  RESIDUE - correlation - residue by residue
:: CORRELATE  ATOM - correlation - atom by atom
:: REAL SPACE R - tabulated residue by residue
:: CHAIN  chain_ID  1st_residue_number  last_residue_number
::         Repeat residue numbering by chain, as in SFALL
::
::  Correlation residue by residue of final coordinates with mir map
::  See mapcorrelation_procedures.
::
::  Warning. All grids MUST BE THE SAME!!
::

IF NOT EXIST %TEMPRES%\fomir.map echo "! run mapcorrelation_procedures first" 1>&2 && exit

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Correlation residue by residue of final coordinates with mir map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap mapin1 %TEMPRES%\fomir.map mapin2 %TEMPRES%\fclast.map mapin3 %TEMPRES%\last.map < %SCRIPTWIN%\overlapmap.dat

