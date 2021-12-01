
proc zanuda_setup { typedefVar arrayname } {
   upvar #0  $typedefVar typedef

   set typedef(_SG_dir) { file
      Directory ".dir"  "Directory with transformed models and data" "" ""
   }

   DefineMenu _zanuda_mode \
      [list "REFINE all transformed models and save the best model" "SAVE all transformed models and data without refinement"] \
      [list "REFINE" "SAVE"]

   return 1
}
     

proc zanuda_task_window { arrayname } {
   upvar #0 $arrayname array

#  if { [ CreateTaskWindow $arrayname "Zanuda" "Znd" \
#          [ list "Subgroup selection" "Rigid body refinements" ] ] == 0 } return

   if { [ CreateTaskWindow $arrayname "Zanuda" "Znd" "" ] == 0 } return

   OpenFolder protocol 

   CreateTitleLine line \
       TITLE

   CreateLine line \
       label "Transform input model and data into subgroups of the pseudosymmetry space group (PSSG)" \

   CreateLine line \
       message "REFINE means automatic mode. SAVE and refine manually for a more accurate comparison" \
       message "REFINE... means automatic mode. SAVE... and then refine manually for a more accurate comparison" \
       label "              and" \
       widget MODE \

   CreateLine line \
       message "This is for breaking an incorrect symmetry, but NOT for deliberately low symmetry input (e.g. P1)" \
       widget AVERAGE \
       label "SYMMETRYSE input model (i.e. transform it into PSSG) before further transformations" \

   OpenFolder file 
  
   CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ  in " \
       HKLIN DIR_HKLIN

   CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
      "PDB  in " \
       XYZIN DIR_XYZIN \
      -fileout SGDIR DIR_SGDIR "_zanuda" \
      -fileout HKLOUT DIR_HKLOUT "_zanuda" \
      -fileout XYZOUT DIR_XYZOUT "_zanuda" \

   CreateOutputFileLine line \
      "Output directory" \
      "SG out  " \
       SGDIR DIR_SGDIR \
      -toggle_display MODE open "SAVE"

   CreateOutputFileLine line \
      "Output MTZ File" \
      "MTZ out" \
       HKLOUT DIR_HKLOUT \
      -toggle_display MODE open "REFINE"

   CreateOutputFileLine line \
      "Output coordinate file" \
      "PDB out" \
       XYZOUT DIR_XYZOUT \
      -toggle_display MODE open "REFINE"


#  OpenFolder 1 closed

#  CreateLine line \
#      message "To be used in presence of pseudotranslation but only when crystal point group is clearly defined" \
#      widget ORIGINS \
#      label "Test different origins only (less subgroups to test)" \

#  OpenFolder 2 MODE hide "SAVE" closed

#  CreateLine line \
#      message "Apply additional B to structure amplitudes, but not to their sigmas. This hack improves convergence" \
#      label "Additional B-factor for F" \
#      widget RIGID_BADD \
#      message "Exclusion of high resolution data accelerates rigid body refinement and improves its convergence" \
#      label "Set high resolution limit at <F>/<SIGF> =" \
#      widget RIGID_FSLIM
}


proc zanuda_run { arrayname } {
   upvar #0 $arrayname array

   if { $array(MODE) == "REFINE all transformed models and save the best model" } {
      set array(OUTPUT_FILES) "HKLOUT XYZOUT"
      set array(SGDIR) ""
   } elseif { $array(MODE) == "SAVE all transformed models and data without refinement" } {
      set array(HKLOUT) ""
      set array(XYZOUT) ""
      set array(OUTPUT_FILES) "SGDIR"
   }
   return 1
}

