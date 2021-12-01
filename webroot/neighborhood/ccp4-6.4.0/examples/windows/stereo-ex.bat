:: generate a PDB file from input stereo coordinates
echo "TITLE stereo test" | ^
stereo xyzin %SCRIPTWIN%\stereo.dat xyzout %TEMPRES%\stereo
