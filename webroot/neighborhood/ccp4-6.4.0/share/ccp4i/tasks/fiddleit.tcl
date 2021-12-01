#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#-----------------------------------------------------------------------
proc fiddleit_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![CreateTaskWindow $arrayname  \
	"Fiddleit - A Simmple CCP4i Demo TASK" Fiddleit \
	{} ] }  { return 0 }
 
  OpenFolder protocol

 CreateLine line \
     message "Enter a title for this job (TITLE)" \
     label "Title" \
     widget TITLE -width 80
  CreateLine line \
     message "Enter the fiddle factors (FIDDLEFACTORS)" \
     label "Fiddle factors: first" \
     widget FACTOR_1 \
     label "second" \
     widget FACTOR_2
  CreateLine line \
     message "Use extra fiddle factor for really rough problem \
     (FIDDLEFACTORS FACTOR_3)" \
     widget EXTRA_FIDDLE \
     label "Use third fiddle factor" \
     widget FACTOR_3

}
