::!\bin\csh -f 

:: Copy PDB files to current directory.
:: These will be changed by 4akeA-2eckB.w5_shscript

cd %TEMPRES%
copy %DATA%\2eck.pdb .\2eck_work.pdb
copy %DATA%\4ake.pdb .\4ake_work.pdb

:: Running dyndom
:: Control input is contained in separate file adenylate.command

dyndom %DATA%\adenylate.command

:: The program produces five files:
:: 
:: 4akeA-2eckB.w5_arrow      : PDB file for arrow indicating interdomain screw axis
:: 4akeA-2eckB.w5_info       : Text file containing details of results
:: 4akeA-2eckB.w5_rasscript  : RasMol script file for display with RasMol program
:: 4akeA-2eckB.w5_rotvecs    : PDB file for rotation vectors

:: To display rotation vectors, enter command:
::4akeA-2eckB.w5_shscript rotvecs

cd %SCRIPTWIN%