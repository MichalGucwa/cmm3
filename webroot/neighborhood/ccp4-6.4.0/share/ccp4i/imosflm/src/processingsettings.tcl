# $Id: processingsettings.tcl,v 1.11 2012/03/26 16:36:39 ccb Exp $
package provide processingsettings 1.0

image create photo ::img::max_res16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMIDwwII5WHrgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAA10lEQVQ4y6WTsQ2DQAxFH4gye9AjBaUMQ4RBIgp2gDJTsAOivSCRni4LMINTYCkX7pAIWLJO5/v+On/bAYhwwCI98535TbTycAEyINb7CHSAWQLDxf0ElMAdaIGrequxUjG2iYDc1AeQN0jqfkpSfRssvISLbyezHkHvEgS9apUo1ikhA2p/8g9JrViHIAaaLcpb4joi/m02wbhxHnLFOgQdUPg7YHeCQrEOgQFec41rbaRRjFnT4AFMwBOkAjmrV3OMSTHfvugy5TtHeXUXjG/uvZNxdJ0/4ERGrntyQ9sAAAAASUVORK5CYII="

image create photo ::img::min_res16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMIDwwQMPkf+AAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAqElEQVQ4y83SsQnCYBAF4C8OIXYOIFaCruAcltbiEO6QBZzAFRKwEncQe+uzyC/GiBg0oA+uebx73Ls7/hSxIkrikqqsuPeNQ6IggsiJZao8cUWluSNrGBQYYINzw72PNU5ksxvZexzb9EWzxG0qzT1ObYIoccDuTc45xmTTxgRG2LdY1D5pmxE+Q93giEmLnknSPhlssUjbfoV+0mw7O+PXj9T1K/8AV+O0TvCnVhg/AAAAAElFTkSuQmCC"

image create photo ::img::res_cutoff16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHEyo19XwC2QAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABlUlEQVQ4y92STShEURTH//fe9+6tudPUeJgZzfhayUexUYZmIWUhM0WxUp6SbBSlLGzsLGRjSRGrsZgFYuUjaWZDr8zGapIZhfCiRlHmWfiaxudOOXXqfP1/nToH+GsjXzU0v14MIPiSrlxF509+Dchr6O0GsAQg81KiAHquYwvhHwGaX8+3LOsYgMxppQkhpVfR+cvsIv1kgVHKbZwJCcZtzy4kKLdxAKO5wx8AhPEQE1KtvE9jLGlgLGmg8j4NJqRKGA99C9D8ukaFLGs1U4jsh8GoAkYVRPbDaDVToEKWaX5dy9YoOcA2h7A/TB2ucr1Rx0FeKQBgy1uDudgioi0jD+ad2QZg8dMNFMaHpuNr9u2iahieKlAhQYWE4anCdlE1puNrdoXxoWwNew3GS+pnJpNG8FHhZDgwCEsVIEx98x1vLToTMQycxt35roqC3ZvTDQAg607fZtPtWeDC5qSzdR10uaL5HW99PHbX0Rb6jUim8M7M7Dncu6SvfcJKOVxIOH1ZOuuLt30nlZtJeG/P8Q/sCWMhbaFnboFeAAAAAElFTkSuQmCC"

image create photo ::img::mtz_file16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMJCigz3QEqogAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABsElEQVQ4y4WTz2sTURDHP6/GkoKioBcPXkVPCqKgVEg06sVjycn/QvCkBHPyb+nJgwdt0Q2B2Co9WGg8CeJBaylCUKyaH+/jIbubzSr4hdmZ2ffm+2bmzQsAtRUlhY4wjohxhKY6DolxxPXlKo8fnA6UUVvRX07lp3qg/lC/q9/UgXrpVt+Ljbfef/TeYuxCem7+FYjAJNW5xCHP18+z1tnjXqvvHEGMv/ONfwVmpHFIo94jToasvfxEt9sVoAJMa6Q6l0UxG4FnLy7n9s3lp3Q6m+QEMQ7nNheDY4koAnEyzHuQE5Q3+o9gC+VkCAB74CStvyixZBcJ5/AFVB20Wn4Av7Zaqr5L/2fYKvmb2fXtFhYOkiS3d8DtdG0LfA1ugPurqw6SxB64UMxkv9lkqVZjt9mcuxEKJZxLEgS263XGWQ8+g6eUjyEwTms+o+yk/gXlTQhMgCuzqScJYUaQNWtcaNy41NSyH7JJvH1tnUNKRVlUqsqSckQ5qhxTjisnlJPK3bMPedVucwNCJRvlxtUnpRc4mg5YHBGLLzTVcHg2SP3endBut+W/CMBiKlP8AdF5d2zfuDaaAAAAAElFTkSuQmCC"

class Processingsettings {
    inherit itk::Widget Settings2

    # member variables
    
    # member methods

    public method linkPeakSep
    public method togglePointlessLive
    
    constructor { args } { }
}

body Processingsettings::constructor { args } {

    itk_component add max_res_l {
	label $itk_interior.maxrl \
	    -text "High resolution limit: "
    }

    itk_component add max_res_e {
        SettingEntry $itk_interior.maxre high_resolution_limit \
	    -image ::img::max_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right
    }

    itk_component add min_res_l {
	label $itk_interior.minrl \
	    -text "Low resolution limit: "
    }

    itk_component add min_res_e {
        SettingEntry $itk_interior.minre low_resolution_limit \
	    -image ::img::min_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right
    }


    itk_component add res_cutoff_l {
	label $itk_interior.rcl \
	    -text "I/\u3c3(I) cutoff: "
    }

    itk_component add res_cutoff_e {
        SettingEntry $itk_interior.rce resolution_cutoff \
	    -image ::img::res_cutoff16x16 \
	    -type real \
	    -precision 1 \
	    -minimum 0 \
	    -width 5 \
	    -justify right
    }

    itk_component add peak_sep_l {
	label $itk_interior.psl \
	    -text "Min spot separation: "
    }

    itk_component add peak_sep_x_l {
        label $itk_interior.psxl  -text "X (mm):"  -anchor w
    }

    itk_component add peak_sep_y_l {
        label $itk_interior.psyl  -text "Y (mm):"  -anchor w
    }

    itk_component add peak_sep_x_e {
        SettingEntry $itk_interior.psxe spot_separation_x \
	    -image ::img::spot_sep_x16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 5 \
	    -justify right \
	    -linkcommand [code $this linkPeakSep x y]
    }

    itk_component add peak_sep_y_e {
        SettingEntry $itk_interior.psye spot_separation_y \
	    -image ::img::spot_sep_y16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 5 \
	    -justify right \
	    -linkcommand [code $this linkPeakSep y x]
    }

    itk_component add fix_separation_check {
        SettingCheckbutton $itk_interior.fsc fix_separation \
	    -text "Fix separation"
    }

    itk_component add separation_close_check {
        SettingCheckbutton $itk_interior.scc separation_close \
	    -text "Spots \"close\""
    }

    itk_component add exclude_ice_check {
        SettingCheckbutton $itk_interior.exi resolution_exclude_ice \
	    -text "Do not process spots near ice rings"
    }


    itk_component add peak_sep_prop_linker {
        Linker $itk_interior.pspl \
	    -orient "vertical" \
	    -width 10 \
	    -pad 1
    }

    itk_component add block_size_l {
        label $itk_interior.bsl \
	    -text "Number of images in \n each integration block: "
    }

    itk_component add block_size_e {
        SettingEntry $itk_interior.bse block_size \
	    -type int \
	    -maximum 200 \
	    -minimum 1 \
	    -width 5 \
	    -justify right
    }

    itk_component add mtz_file_l {
	label $itk_interior.mfl -text "MTZ file:"
    }
    itk_component add mtz_file_e {
        SettingEntry $itk_interior.me mtz_file \
	    -image ::img::mtz_file16x16 \
	    -width 30
    }

    itk_component add mtz_directory_l {
	label $itk_interior.mdl -text "MTZ directory:" 
    }
    itk_component add mtz_directory_e {
        SettingEntry $itk_interior.mde mtz_directory \
		-width 30
    }

    itk_component add batch_number_l {
	label $itk_interior.bnl \
	    -text "Batch number offset: "
    }

    itk_component add batch_number_e {
        SettingEntry $itk_interior.bne batch_number \
	    -type int \
	    -maximum 99999 \
	    -minimum 0 \
	    -width 5 \
	    -justify right
    }

    itk_component add multiple_mtz_check {
        SettingCheckbutton $itk_interior.mmz multiple_mtz_files \
	    -text "Multiple MTZ files (1 per block)" \
		-command [code $this togglePointlessLive] 
    }

    itk_component add pointless_live_check {
        SettingCheckbutton $itk_interior.ptll pointless_live \
	    -text "Feed each MTZ file to Pointless" 
    }

    set pad 2
    set margin 7

    grid x $itk_component(max_res_l) - $itk_component(max_res_e) x -stick w -pady [list $margin $pad]
    grid x $itk_component(min_res_l) - $itk_component(min_res_e) x -stick w -pady $pad
    grid x $itk_component(res_cutoff_l) - $itk_component(res_cutoff_e) x -stick w -pady $pad

    grid x $itk_component(peak_sep_l) $itk_component(peak_sep_x_l) $itk_component(peak_sep_x_e) $itk_component(peak_sep_prop_linker) x -sticky w -pady [list $margin $pad]
    grid configure $itk_component(peak_sep_prop_linker) -sticky nsw
    grid x x $itk_component(peak_sep_y_l) $itk_component(peak_sep_y_e) ^ x -sticky w -pady $pad
    grid x $itk_component(fix_separation_check) - - - x -sticky w -pady $pad
    grid x $itk_component(separation_close_check) - - - x -sticky w -pady $pad
    grid x $itk_component(exclude_ice_check) - - - x -sticky w -pady $pad

    grid x $itk_component(block_size_l) - $itk_component(block_size_e) x -sticky w -pady [list $margin $pad]
    grid x $itk_component(mtz_file_l) - $itk_component(mtz_file_e) - -sticky w -pady $pad
    grid x $itk_component(mtz_directory_l) - $itk_component(mtz_directory_e) -  -sticky w -pady $pad
    grid x $itk_component(batch_number_l) - $itk_component(batch_number_e) x -sticky w -pady $pad

    grid configure $itk_component(block_size_e) -sticky we
    grid configure $itk_component(batch_number_e) -sticky we

    grid x $itk_component(multiple_mtz_check) - - - x -sticky w -pady $pad
    grid x $itk_component(pointless_live_check) - - - x -sticky w -pady $pad

    grid columnconfigure $itk_interior { 0 5 } -minsize $margin
    grid columnconfigure $itk_interior { 2 4 } -weight 1 
    grid rowconfigure $itk_interior 99 -weight 1

    $itk_component(pointless_live_check) configure -state disabled

    eval itk_initialize $args

}

body Processingsettings::linkPeakSep {dim1 dim2} {
    if {[$itk_component(peak_sep_prop_linker) query]} {
	$itk_component(peak_sep_${dim2}_e) update [$itk_component(peak_sep_${dim1}_e) getValue]
    }
    if {![$::session getParameterValue "fix_separation"]} {
	$::session updateSetting "fix_separation" 1 1 1
    }
}

body Processingsettings::togglePointlessLive {a_value} {
    #puts $a_value
    if {$a_value == 0} {

	if {[$itk_component(pointless_live_check) getValue]} {
	    $itk_component(pointless_live_check) invoke
	}
	#$itk_component(pointless_live_check) invoke
	#$::session updateSetting pointless_live 0
	$itk_component(pointless_live_check) configure -state disabled
    } else {
	$itk_component(pointless_live_check) configure -state normal
    }
}

########################################################################
# Usual config options                                                 #
########################################################################

usual Processingsettings {
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}

