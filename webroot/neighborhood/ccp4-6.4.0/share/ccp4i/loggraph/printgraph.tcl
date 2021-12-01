#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
###############################################################################
#
# procedure: create_print_win
#
# Description: Create window for printing the mca-graph
#
# Original file from Darren Spruce much hacked by LizP Mar98
#
###############################################################################

#---------------------------------------------------------------------------
proc print_loggraph { arrayname bltwin { mode PRINT } } {
#---------------------------------------------------------------------------
  global loggraph
  upvar #0 $arrayname array

  if { $array(PRINT_TO_FILE) && $array(PSFILE) != "" } {
    set file $array(PSFILE)
    if { $array(PSFILE_DIR) != "" } {
      set file [file join [GetFullDirName $array(PSFILE_DIR) ] $array(PSFILE) ] }
  } else {
    set file [ GetTmpFileName -ext ps ]
  }

# If plotting in monochrome then use symbols and pattern

  set replot 0
  if { [regexp monochrome $array(PCOLOR)]  } {
    set use_symbols $loggraph(USE_SYMBOLS)
    set use_pattern $loggraph(USE_PATTERN)
    if { $array(PLOT_SYMBOLS) && !$loggraph(USE_SYMBOLS) } {
      set loggraph(USE_SYMBOLS) 1
      set replot 1
    }
    if { $array(PLOT_PATTERN) && !$loggraph(USE_PATTERN) } {
      set loggraph(USE_PATTERN) 1
      set replot 1
    }
    if $replot {configure_plot stuff }
  }

  set paper [GetValue $arrayname PAPER_SIZE]
  set width [lindex $paper 0]
  set height [lindex $paper 1]
     
  $bltwin postscript output $file \
	-maxpect 1 \
	-decorations 0 \
	-center 1 \
	-landscape [GetValue $arrayname ORIENT] \
	-colormode [GetValue $arrayname PCOLOR] \
	-paperheight $height \
	-paperwidth $width

  if $replot { 
    set loggraph(USE_SYMBOLS) $use_symbols
    set loggraph(USE_PATTERN) $use_pattern
    configure_plot stuff
  }

  if [regexp PRINT $mode ] { 

    set pname $array(MONO_PRINTER)
    if {$array(PCOLOR) == "colour"} {
      set pname $array(COLOUR_PRINTER)
      set pcmd [GetValue $arrayname COLOUR_PRINTER]
    } else {
      set pname $array(MONO_PRINTER)
      set pcmd [GetValue $arrayname MONO_PRINTER]
    }
    if { $array(PRINT_TO_PRINTER) && $pname != "" } {
      if { [info procs PrintFile ] != "PrintFile" } {
        source [SearchPath TOP src local.tcl]
      }
      PrintFile $pcmd $file
    }
  } else {
     if [regexp ghostview [GetValue $arrayname PRINT_PREVIEW]] { 
       set orient -landscape
     } else {
       set orient ""
     }
# Preview plot with ghostview or xv
    if [catch "exec [GetValue $arrayname PRINT_PREVIEW] $orient $file" ]  {
      Report 1 "Can not run $array(PRINT_PREVIEW) - can not preview plot"
    }
  }
#  if [regexp tmp [file extension $file]] { DeleteFile $file }
}

#---------------------------------------------------------------------------
proc create_print_win { arrayname bltwin } {
#---------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![info exists array(PLOT_SYMBOLS) ] } {
    DefineVariable $arrayname PLOT_SYMBOLS _logical 1
    DefineVariable $arrayname PLOT_PATTERN _logical 1
  }

  set w .printer
  if { ! [ OpenWindow  $w "Print Graph" "Print" -message $arrayname \
	-help [SearchPath HELP general loggraph.html] ] } { return }

  CreateFrame $w $arrayname -noscroll

  CreateButton $w dismiss Quit \
	 "destroy $w"

  SetMessage $arrayname $w.buttons.dismiss \
    "Exit this window"

  CreateButton $w preview "Print Preview" \
      "destroy $w; print_loggraph $arrayname $bltwin PREVIEW"

  SetMessage $arrayname $w.buttons.preview \
    "Display plot using selected plot preview program"

  CreateButton $w print Print \
      "destroy $w; print_loggraph $arrayname $bltwin PRINT"

  SetMessage $arrayname $w.buttons.print \
    "Print the plot to file and/or printer"

  CreateLine line \
    label "Plot" \
    message "Choose to create black&white or colour plot" \
    widget PCOLOR \
    message "Draw plot in landscape or portrait mode" \
    widget ORIENT \
    label "graph    " \
    message "Toggle button on to draw plot directly to printer" \
    widget PRINT_TO_PRINTER \
    label "to printer  "  \
    message "Toggle button on to save plot to file" \
    widget PRINT_TO_FILE \
    label "to file" 

  OpenSubFrame frame \
     -toggle_display PRINT_TO_PRINTER open 1 

  CreateLine line \
    label "Printer" \
    message "Select a monochrome printer to send plot to" \
    widget  MONO_PRINTER \
    message " " \
    label "paper size" \
    widget PAPER_SIZE \
    label " Print preview" \
    message "Select Postscript viewer to use with 'Print Preview' button" \
    widget PRINT_PREVIEW \
    toggle_display PCOLOR open monochrome


  CreateLine line \
    label "Printer" \
    message "Select a colour printer to send plot to" \
    widget  COLOUR_PRINTER \
    label "paper size" \
    message " " \
    widget PAPER_SIZE \
    label "print preview" \
    message "Select Postscript viewer to use with 'Preview Plot' button" \
    widget PRINT_PREVIEW \
    toggle_display PCOLOR open color

  CloseSubFrame

  CreateOutputFileLine line \
    "Name of postscript file" \
    "PS file" PSFILE PSFILE_DIR \
    -toggle_display PRINT_TO_FILE open 1

   CreateLine line \
     message "Use variable symbols and linestyles to clarify monochrome plots?" \
     label "For monochrome plot use" \
     widget PLOT_SYMBOLS \
     label "variable symbols and" \
     widget PLOT_PATTERN \
     label "variable linestyles" \
     toggle_display PCOLOR open monochrome

   CloseFrame

}

