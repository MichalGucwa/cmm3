# $Id: spotfindingsettings2.tcl,v 1.12 2012/03/26 16:36:39 ccb Exp $
# package name
package provide spotfindingsettings 2.0

image create photo ::img::spot_threshold16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMGDyMjfeoxsAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABI0lEQVQ4y91SPUvEQBB9k002l4QYdJVDRBG01vpSi6WtNoqxvpQBf4h9RCtbwc46BzbiDxDEq0Rj4aGHn2Phfay5BO0EBwZmZ96+fTOzwF8bVRVUGM0BWOsdj/Msvf41wURjex3AIYCPXsoAsHnf2j/6kUCF0SQzXwHwCqVHIprPs/ROTxolAhJDulLYHoR0v9z2YEhXAkhK+2WAGWA9rq8mXBYX8UZBvhpIk8MO9FjHjMxAhdGWPbWwR6b0+9J0FL+9dJ5vL5t5lh7075jf2MxaLNxxv3Lp0vPJrMUABgRi+PpO7MwsbQjbkyQsVLlwgsAKpjvd9vkZAJAKo12QWHFmlxvWWN0tTrds2a8PN0/d9kUL/H5Ki80THt0KV3xbwj+0T1ZEVdiNwQxrAAAAAElFTkSuQmCC"

image create photo ::img::spot_search_min_radius16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMIDwsVD9J9sAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAqklEQVQ4y83SsQkCURAE0HcWIWYWIEYH2oJ1GBqLRdiDDViBLdyBkdiDmBuvgV/8nBweKujAJsPM/N39y18iWAZ1cElVB8suxmFQBRFsgkWqTeKqYJh7ikZAhQHWODfy+1jhVDC9k728bUxazBK3xiQfp8gCahywezHpDOPi9tijA4yw77DjfdJqBryFPOCIsoOnTNqngC3madtt6CfN9mvf+PEhffeUf4IrLX9O8Na5+nsAAAAASUVORK5CYII="

image create photo ::img::spot_search_max_radius16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMIDwsdAQn1ggAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAA2klEQVQ4y6XTMW4CQQwF0AeizD3oIwVRhkNkDhJRcAcoOcXeAdEukaCnywVyBtNYymZ2VyJgyRrN+PvPjP09CcITNsu1PJjfzEYCS6wwz/0VR7Q1cFrtX7DBJw54Tz/k2SYxvxZE8JF+Dr6DRX1TsMjYuYOPafXsV5QJXzVBnpXELIe+sMJuKLki2SW2RzBHc0/lO8XtFfHf1iW43qmHktgewRHroQ50O4F1YnsELS5oxtqY/790BVXXYI8fnIJt8Ja+xSlj+z+dyWEqD0p5dBbaId0PauPZcb4BDi1GrkaIeioAAAAASUVORK5CYII="

image create photo ::img::spot_search_vertical_exclusion16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMJCiUA1381+QAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAKklEQVQ4y2NkwAL+MzD8Z2BgCEMTXsXIwMCIrpaJgUIwasCoAaMGDBYDACH0AyAN+WAfAAAAAElFTkSuQmCC"

image create photo ::img::spot_search_horizontal_exclusion16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMJCiQxn7oEggAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAJUlEQVQ4y2NgGAUUA8b/DAz/KTUglBIDmCj1wsAbQHEgjgIqAAAELAVaWl6xHwAAAABJRU5ErkJggg=="

image create photo ::img::spot_size_min_x16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHDzUYaMUKJgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABMklEQVQ4y9WSvU4CQRSFv5md3WXNEimMjwBGtqUWraSzxQegsJVWjdpiS8EDaAkdvgPtYqKPYCwwbkD2byyIZEkgQqi83b0558udORf+fYllw/L9Wz0NJw2dxhUAIdVAWk5neFV8+hNweOO3kvHoMpkG6CSaiQwTw3YxdgoPL7decyWgfPdaj77eH+Pgg2TyiY6nM5GyMZxdlLuHmd8/H16X5puoLCANJ430OyAZjzgbPtP0+wC0vBq98ilS5UjtfANYDtBpVNFJiI6nNP0+F8UjANp+n27pGJ2E6DSqZD1y2xQWNhDSHAjDqgpl0/JqtDNPEMpGGBZCmoOVAGk5HZlzq0ZcoOfV6B6cLHyizLlIy+msSkEDYs0Y9a9XZMzzfo1DmutFptmq9IagpfpNAQD8ACVuggxuGy4HAAAAAElFTkSuQmCC"

image create photo ::img::spot_size_min_y16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHDzUpORsKHAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABK0lEQVQ4y7WTO04CURiFv3vnxZghUhiXAEampRatpLOVBVDYSqtGbbGlYAFaQod7oB1MdAnGAiMB53HnWhAVEvABeurzfzn/Cz6lWUJiTrH4LUB/Af5xgvcUAqB4+XCYRuOaTpMSgJBmT9puq3+Sv/kWsH0WNNRocKzCIVrFE5NhYTgexlru6u7cry8EFC/uq/HL43UyfEKNn9FJODGZDoa7jultYGU3q/3TwkcSc5qWRuNa+jpEjQYc9G+pB10AGn6FTnEfaWZInWwNmA/QaVzSKkInIfWgy1F+B4Bm0KVd2EWrCJ3GpekayYqaSSCk1ROGXRamQ8Ov0JxqQZgOwrAR0uotBEjbbcmMVzaSHB2/Qntrb2aIMuMhbbf1f2tc9pD+5JSXfiZWfec3lVSCFMNXqr0AAAAASUVORK5CYII="

image create photo ::img::spot_size_max_x16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHDzYGuedkhgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAByElEQVQ4y6WTO08bURCFv7m765dseYsQCToa8iBNCguXLuEnkIrKsuukJVGSNqltuaIKP4GULolc0ISg0JAKpJBiLVv22vuYFHsNCCkEiZFGVzqamTNz5wzcMoUNhY7CiUJo/cRiG9xlNkgVDhVaCk+ttyymCp1/JR/YgNYdBC0bc7DA3AUzsAlsCXxd/3i6nc6nTU3jGoAYd2ByxZ7srnUVfpGRdQTaYuc6BNoC3efvvn9KJsHrZDZGkwgAcTycfBmn5H/+8f7FG9tlB6iLZX8pUF//8HM7Gv3+Eo//kEyHaDzLCrh5nGIVt/wIr/L41fHbJ/uakR4ZoAHsAaTzaTMNxySTgHh0SRScEwXnxKNLkklAGo5J59OmHX8PaBhgFegDaBrVNJmj8YwkHBENL4iGFyThCI1naDJH06hmC/SBVcMDzQBndgzEeANxctnMhQpedRmvuoxTqCBuHnFyiPEGNrcBnBnbyg6AyRV7plDGKfm4lSU8fwXPX8GtLOGUfEyhjMkVe7bADtC/WqNkoNxnjWRiAqjLtchA/yOk4921fYVNuVaiyCL5IZ8oN7Te1ez9ptBWeGa9bTEUujfy5dat3Pucr7r+Czc/6/IXyJsAAAAAAElFTkSuQmCC"

image create photo ::img::spot_size_max_y16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHDzU5JKwaeAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABm0lEQVQ4y62TsW/TQBTGf+/s2DFyoQNi71IQZWGIwugR/gQ6dYrSGdaCgBXmVJk60T+hjBkjZWChVGUpUytRBkeOEsf2+TH4KmCIhBSe9N3wnd539737Dn6XuqWrMFA4U8gdzhzXZUXpDbTBWKGv8MCh7zhVGKxs/gOrTuk7kZMbzgdEYSDN5jOBTzvvvj2vi0VP66oDIMafmCAaysH2ocJ34MT17IvzNZZGUB6+/vLeztMXdjlDbdmQXgsvjPFubX74+ubRS4U+jZUn4jw9FujuvD3fLbMfH6vZT+xiilbLRsAP8aI7+PFdWhv3dk9f3T9WGAOfDZAARwB1sejV+Qw7T6mya8r0kjK9pMqusfOUOp9RF4ues38EJAbYAkYAWpcdtQVaLbF5Rjm9opxeYfMMrZaoLdC67DiBEbBlWLN84MLZQExrIl6QiB/itTcQaUZrwhjxQ8QLENOauN4EuPDdVfYATBANTTtOvGoTRNDo9l9DNO0YE0RDJ7AHjNZ/RpewfwrS6cH2scJTmiQeCuyvHeX/8pnW+s6/AN4v/V1JVILWAAAAAElFTkSuQmCC"

image create photo ::img::spot_sep_x16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHDzs7VCFW2gAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAtElEQVQ4y9WSMQ6DIBSGv7I6ehYWJi/hUDcXL6DH0Au4uNmEU3Ry4SxudaYLJAQtpWNfQvJ4//s/HgT4+7iVqn0BBpj3bXnkmErV3oEOkAIogApYS9WOGeYRWJ2nEJHeO3rq5D6siYu+LjHASbsCyARA5gB+iiuASfSbHMCcAMzfAJP/Cxa0L/rcaVMMOIAn0OzbMgSGOuirA8gANM5znGa0oC3YD0tnvayHBPt8c3zvOI/jDT6sROobHpkuAAAAAElFTkSuQmCC"

image create photo ::img::spot_sep_y16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHEAARpFKUeQAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAzklEQVQ4y6WSIRKDMBBFH9TRVqE5BAKTmxSH4QLFM/WlB8Agew0UpgaBqkXjyiBTAzOhAylN/0xEZndfdn/WQpErohewR6++q4rDdLE/gg++a5bzCcg3AGY5O/UytHXjeP4RECvFWVcVN10HdFWRACFQAv14SiAcY0hIMZWEVII0gijF0hgyguSqB7/KNhlh6uJfH1IAaynJFdEJiIFA2b68q4r7BLHgsghwRXQFzppFSlY3cXw500wgHM9/Dm3drJkYb7Ah1v1CsAEwy3kDoIJLKAeVtysAAAAASUVORK5CYII="

image create photo ::img::spot_split_x16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHEAAzcTLVnQAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAA/0lEQVQ4y7WSsWoCQRCGv6yxUpJmySEWclUg2ljcO1jZWNlYWsTyCiGFhNTW9wApRZ/ByuqQJJAUViIoIlhYHBGumTSnxHNjIpqBab7552d2duBcIVAV6AsEUfYjZuTx5raAdLUt5XxJyvmSdLUtAnKAtwEuIze3lXPwsoWtqRWuqSzHxPngOsNbSvM08V2BoQLqPW3viABqixEmDuBlC/S0DVBXgPNs3e6JisESE99EVHPUqctXgF9bjPYKL2mNiX9/IuAnHiG8+1xVApXEv7rZCsKLBM3pK3EOcD97pzH/AHg4+RvPc0iG6PyR/dgs5mv/3WTTfCg7/zrB0Tv4AvrLo2z9HWi+AAAAAElFTkSuQmCC"

image create photo ::img::spot_split_y16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMHEAArYl5NywAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABIUlEQVQ4y62TP2sCMRiHHw+3FroEjuJQbnLQpcPt3erkIj2wg6PDfYgOzs4Ojg4WTv0MTp1uKIVbnKSFG4SDLkKhy9uhCaaxV6rtCyFv/vx+eZOHgBUCXYGlwFa3pUCX34TAUEDmKpB2oyXtRkvmKhABERiW6SrmZGB6dxEyqjW/bIjzjMFzCnBbgXvXwNN9f6GCPTHAqNZkoQKAvjWduAbhxK+XXk+vhZb4xph4HBZGjDGp6kHa26yu/Pc3epsVl9sCgMdTxcSvc/36ApAC0e7NP9/Pxic/UBAHp5ikatfnUng4O+fpRBkK38axFDiWQmKVL0ByKIUImOl8BkSeRaFUpddSxySyrzDuFGviPNsTx3lGp1gDjJ1K/ucz8dfv/AGsdYm1g3+NeQAAAABJRU5ErkJggg=="

# Class
class Spotfindingsettings {
    inherit itk::Widget Settings2

    # variables
    ###########

#     private variable peak_sep_option "0"
#     private variable peak_separation_min_x "0.00"
#     private variable peak_separation_min_y "0.00"
#     private variable peak_separation_max_x "0.30"
#     private variable peak_separation_max_y "0.30"
#     private variable spot_size_min_x "0.50"
#     private variable spot_size_min_y "0.50"
#     private variable spot_size_max_x "2.00"
#     private variable spot_size_max_y "2.00"
#     private variable exclusion_segment_horizontal_check "0"
#     private variable exclusion_segment_vertical_check "0"
#     private variable exclusion_segment_horizontal "0.00"
#     private variable exclusion_segment_vertical "0.00"
#     private variable bbox_orientation "North"
#     private variable bbox_offset "0.00"

    # methods
    #########

    # widget callbacks
    public method updateOrientation

    public method linkPeakSep
    public method linkSplitting
    public method linkLocalBackgroundBoxSize
    public method linkSpotSize

    # image update method
    private method updateImageSettings
    public method updateSearchArea
    public method localBackgroundPrep

    public method debug

    public method setSpotfindingRelayBool
    public method getSpotfindingRelayBool
    private variable spotfinding_relay_bool "1"

    constructor { args } { }

}

# Bodies

body Spotfindingsettings::debug { a_val } {
}

body Spotfindingsettings::constructor { args } {

    itk_component add relay_check {
	checkbutton $itk_interior.relaycheck -text "Automatically find spots on entering Autoindexing" -variable [scope spotfinding_relay_bool]
    }

    itk_component add search_area_l {
        gSection $itk_interior.searcharealabel  -text "Search area "
    }
    
    itk_component add min_radius_l {
        label $itk_interior.searcharealabelmin  -text "Minimum radius (mm):"  -anchor w
    }

    itk_component add max_radius_l {
        label $itk_interior.searcharealabelmax  -text "Maximum radius (mm):"  -anchor w
    }

    itk_component add min_radius_e {
        SettingEntry $itk_interior.searchareaentrymin search_area_min_radius \
	    -image ::img::spot_search_min_radius16x16 \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -justify right
    }

    itk_component add max_radius_e {
        SettingEntry $itk_interior.searchareaentrymax search_area_max_radius \
	    -image ::img::spot_search_max_radius16x16 \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right
    }

    itk_component add exclusion_segment_v_l {
        label $itk_interior.vesl \
	    -text "Vertical exclusion segment (mm):" \
	    -anchor w
    }

    itk_component add exclusion_segment_vertical_2x_l {
        label $itk_interior.esv2xl \
	    -text "2\ud7" \
	    -anchor e
    }

    itk_component add exclusion_segment_vertical_e {
        SettingEntry $itk_interior.esve exclusion_segment_vertical \
	    -image ::img::spot_search_vertical_exclusion16x16 \
	    -type real \
	    -precision "2" \
	    -minimum "0.00" \
	    -width 6 \
	    -justify right
    }

    itk_component add exclusion_segment_h_l {
        label $itk_interior.hesl \
	    -text "Horizontal exclusion segment (mm):" \
	    -anchor w
    }

    itk_component add exclusion_segment_horizontal_2x_l {
        label $itk_interior.esh2xl \
	    -text "2\ud7" \
	    -anchor e
    }

    itk_component add exclusion_segment_horizontal_e {
        SettingEntry $itk_interior.eshe exclusion_segment_horizontal \
	    -image ::img::spot_search_horizontal_exclusion16x16 \
	    -type real \
	    -precision "2" \
	    -minimum "0.00" \
	    -width 6 \
	    -justify right
    }

    itk_component add auto_resolution_check {
        SettingCheckbutton $itk_interior.arc auto_resolution \
	    -text "Automatic Resolution reduction"
    }


    itk_component add spot_discrimination_l {
        gSection $itk_interior.threshold_l \
	    -text "Spot discrimination "
    }
    
    itk_component add min_i_sig_i_l {
        label $itk_interior.min_i_sig_i_l \
	    -text "Threshold I/\u3c3(I):"  -anchor w
    }
    
    itk_component add threshold_e {
        SettingEntry $itk_interior.threshold_e threshold \
	    -image ::img::spot_threshold16x16 \
	    -type real \
	    -precision 2 \
	    -minimum 1.00 \
	    -width 4 \
	    -justify right
    }
    
    itk_component add background_l {
	label $itk_interior.bbl \
	    -text "Background box orientation: " \
	    -anchor w
    }

    itk_component add orientation_combo {
        SettingCombo $itk_interior.bborc bbox_orientation \
	    -width 5 \
	    -items {North South East West} \
	    -editable 0 ;#   -highlightcolor black
    } {
	usual
	ignore -textbackground -foreground
    }

    itk_component add offset_l {
        label $itk_interior.bbofl \
	    -text "Background box offset (mm): " \
	    -anchor w
    }

    itk_component add offset_e {
        SettingEntry $itk_interior.bbofe bbox_offset \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -justify right
    }

    itk_component add minpix_l {
        label $itk_interior.mpixl \
	    -text "Minimum pixels per spot: " \
	    -anchor w
    }

    itk_component add minpix_e {
        SettingEntry $itk_interior.mpixe minpix \
	    -type int \
	    -width 7 \
	    -minimum 1 \
	    -justify right
    }

    itk_component add auto_ring_check {
        SettingCheckbutton $itk_interior.aric auto_ring \
	    -text "Automatic ice and powder ring exclusion"
    }

    itk_component add spot_size_l {
        gSection $itk_interior.ssl \
	    -text "Spot size limits (\u221d median size):"
    }

    itk_component add spot_size_max_l {
        label $itk_interior.ssmaxl \
	    -text "Maximum: " \
	    -anchor w
    }

    itk_component add spot_size_max_x_l {
        label $itk_interior.ssmaxxl \
	    -text "x: " \
	    -anchor w
    }

    itk_component add spot_size_max_x_e {
        SettingEntry $itk_interior.ssmaxxe spot_size_max_x \
	    -image ::img::spot_size_max_x16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 1.00 \
	    -width 7 \
	    -justify right \
	    -linkcommand [code $this linkSpotSize maxx]
    }

    itk_component add spot_size_max_y_l {
        label $itk_interior.ssmaxyl \
	    -text " y: " \
	    -anchor w
    }

    itk_component add spot_size_max_y_e {
        SettingEntry $itk_interior.ssmaxye spot_size_max_y \
	    -image ::img::spot_size_max_y16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 1.00 \
	    -width 7 \
	    -justify right \
	    -linkcommand [code $this linkSpotSize maxy]
    }

    itk_component add spot_size_inv_linker {
        Linker $itk_interior.ssil \
	    -orient "vertical" \
	    -width 10 \
	    -pad 1 \
	    -command {}
    }

    itk_component add spot_size_min_l {
        label $itk_interior.ssminl \
	    -text "Minimum: " \
	    -anchor w
    }
    itk_component add spot_size_min_x_l {
        label $itk_interior.ssminxl  -text "x: " -anchor w
    }

    itk_component add spot_size_min_x_e {
        SettingEntry $itk_interior.ssminxe spot_size_min_x \
	    -image ::img::spot_size_min_x16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 1.00 \
	    -minimum 0.10 \
	    -width 7 \
	    -justify right \
	    -linkcommand [code $this linkSpotSize minx]
    }

    itk_component add spot_size_min_y_l {
        label $itk_interior.ssminyl  -text " y: " -anchor w
    }

    itk_component add spot_size_min_y_e {
        SettingEntry $itk_interior.ssminye spot_size_min_y \
	    -image ::img::spot_size_min_y16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 1.00 \
	    -minimum 0.10 \
	    -width 7 \
	    -justify right \
	    -linkcommand [code $this linkSpotSize miny]
    }

    itk_component add spot_size_prop_linker {
        Linker $itk_interior.sspl \
	    -orient "horizontal" \
	    -height 10 \
	    -pad 1 \
	    -command {}
    }

    itk_component add spot_rms_var_l {
        label $itk_interior.srvl \
	    -text "Spot rms variation " \
	    -anchor w
    }

    itk_component add spot_rms_var_e {
        SettingEntry $itk_interior.srve spot_rms_var \
	    -type real \
	    -precision 1 \
	    -minimum 0.0 \
	    -width 7 \
	    -justify right \
    }

    itk_component add spot_anisotropy_l {
        label $itk_interior.sal \
	    -text "Spot anisotropy " \
	    -anchor w
    }

    itk_component add spot_anisotropy_e {
        SettingEntry $itk_interior.sae spot_anisotropy \
	    -type real \
	    -precision 1 \
	    -minimum 0.1 \
	    -width 7 \
	    -justify right \
    }

    itk_component add peak_sep_l {
        gSection $itk_interior.psl \
	    -text "Minimum spot separation"
    }

    itk_component add peak_sep_x_l {
        label $itk_interior.psxl \
	    -text "x: " \
	    -anchor w
    }

    itk_component add peak_sep_y_l {
        label $itk_interior.psyl \
	    -text " y: "  \
	    -anchor w
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
	    -width 4 \
	    -justify right \
	    -linkcommand [code $this linkPeakSep y x]
    }

    itk_component add peak_sep_prop_linker {
        Linker $itk_interior.pspl \
	    -orient "horizontal" \
	    -height 10 \
		-state "open"\
	    -pad 1
    }

    itk_component add fix_separation_check {
        SettingCheckbutton $itk_interior.fsc fix_separation \
	    -text "Fix separation"
    }

    itk_component add separation_close_check {
        SettingCheckbutton $itk_interior.scc separation_close \
	    -text "Spots \"close\""
    }

    itk_component add splitting_l {
        gSection $itk_interior.sl \
	    -text "Maximum peak separation within spots (mm):"
     }

    itk_component add splitting_x_l {
        label $itk_interior.sxl \
	    -text "x: " \
	    -anchor w
    }

    itk_component add splitting_y_l {
        label $itk_interior.syl \
	    -text " y: " \
	    -anchor w
    }

    itk_component add splitting_x_e {
        SettingEntry $itk_interior.sxe spot_splitting_x \
	    -image ::img::spot_split_x16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 1.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -linkcommand [code $this linkSplitting x y] \
	    -justify right
    }

    itk_component add splitting_y_e {
        SettingEntry $itk_interior.sye spot_splitting_y \
	    -image ::img::spot_split_y16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 1.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -linkcommand [code $this linkSplitting y x] \
	    -justify right
    }

    itk_component add splitting_prop_linker {
        Linker $itk_interior.spl \
	    -orient "horizontal" \
	    -height 10 \
	    -pad 1
    }

    itk_component add background_determination_l {
        gSection $itk_interior.backgrounddeterminationlabel  -text "Background determination"
    }

#	itk_component add local_background_l {
#   	label $itk_interior.pocl  -text "Local background determination "  -anchor w
#    }

    itk_component add local_background_check {
        SettingCheckbutton $itk_interior.lbc local_background \
	    -text "Local background determination" -command [code $this localBackgroundPrep]
    }
    itk_component add local_background_box_l {
        gSection $itk_interior.lbbl \
	    -text "Local background box size (pixels):"
     }

    itk_component add local_background_box_x_l {
        label $itk_interior.lbbxl \
	    -text "x: " \
	    -anchor w
    }

    itk_component add local_background_box_y_l {
        label $itk_interior.lbbyl \
	    -text " y: " \
	    -anchor w
    }

    itk_component add local_background_box_x_e {
        SettingEntry $itk_interior.lbbxe local_background_box_size_x \
	    -type int \
	    -minimum 16 \
	    -maximum 256 \
	    -width 4 \
	    -linkcommand [code $this linkLocalBackgroundBoxSize x y] \
	    -justify right
    }

    itk_component add local_background_box_y_e {
        SettingEntry $itk_interior.lbbye local_background_box_size_y \
	    -type int \
	    -minimum 16 \
	    -maximum 256 \
	    -width 4 \
	    -linkcommand [code $this linkLocalBackgroundBoxSize y x] \
	    -justify right
    }

    itk_component add local_background_box_linker {
        Linker $itk_interior.lbbll \
	    -orient "horizontal" \
	    -height 10 \
	    -pad 1
    }

    itk_component add max_unresolved_peaks_l {
        label $itk_interior.mupl \
	    -text "Max number of unresolved peaks: " \
	    -anchor w
    }

    itk_component add max_unresolved_peaks_e {
        SettingEntry $itk_interior.mupe max_unresolved_peaks \
	    -type int \
	    -minimum 0 \
	    -width 7 \
	    -justify right
    }

	

    # layout ####################################

    set indent 20
    set margin 7

    grid x $itk_component(relay_check)   - - - - - -sticky w 
    grid $itk_component(search_area_l) - - - - - - -sticky we -pady {5 0}
    grid x $itk_component(min_radius_l) - - - $itk_component(min_radius_e) x -sticky we
    grid x $itk_component(max_radius_l) - - - $itk_component(max_radius_e) x -sticky we
    grid x $itk_component(exclusion_segment_v_l) - - $itk_component(exclusion_segment_vertical_2x_l) $itk_component(exclusion_segment_vertical_e) -sticky we
    grid x $itk_component(exclusion_segment_h_l) - - $itk_component(exclusion_segment_horizontal_2x_l) $itk_component(exclusion_segment_horizontal_e) -sticky we
    grid x $itk_component(auto_resolution_check) - - - -  -sticky w -pady 2
    grid x $itk_component(auto_ring_check) - - - -  -sticky w -pady 2

    grid $itk_component(spot_discrimination_l) - - - - - - -sticky we -pady {5 0}
    grid x $itk_component(min_i_sig_i_l) - - -  $itk_component(threshold_e) -sticky we
    grid x $itk_component(background_l) - - - $itk_component(orientation_combo) -sticky we
    grid x $itk_component(offset_l) - - -  $itk_component(offset_e) -sticky we
    grid x $itk_component(minpix_l) - - -  $itk_component(minpix_e) -sticky we

    grid $itk_component(spot_size_l) - - - - - - -sticky we -pady {5 0}
    grid x $itk_component(spot_size_max_l) $itk_component(spot_size_max_x_l) $itk_component(spot_size_max_x_e) $itk_component(spot_size_max_y_l) $itk_component(spot_size_max_y_e)  -sticky we
     grid x $itk_component(spot_size_min_l) $itk_component(spot_size_min_x_l) $itk_component(spot_size_min_x_e) $itk_component(spot_size_min_y_l) $itk_component(spot_size_min_y_e)   -sticky we
#    grid configure $itk_component(spot_size_inv_linker) -sticky ns
    grid x x x $itk_component(spot_size_prop_linker) - - -sticky we
    grid x $itk_component(spot_rms_var_l) - - -  $itk_component(spot_rms_var_e) -sticky we
    grid x $itk_component(spot_anisotropy_l) - - -  $itk_component(spot_anisotropy_e) -sticky we

    grid $itk_component(peak_sep_l) - - - - - - -sticky we -pady {5 0}
    grid x x $itk_component(peak_sep_x_l) $itk_component(peak_sep_x_e) $itk_component(peak_sep_y_l) $itk_component(peak_sep_y_e) -sticky we
    grid x x x $itk_component(peak_sep_prop_linker) - - -sticky we
    grid x $itk_component(fix_separation_check) - - - -  -sticky w -pady 2
    grid x $itk_component(separation_close_check) - - - - -sticky w -pady 2

    grid $itk_component(splitting_l) - - - - - -sticky we -pady {5 0}
    grid x x $itk_component(splitting_x_l) $itk_component(splitting_x_e) $itk_component(splitting_y_l) $itk_component(splitting_y_e) -sticky we
    grid x x x $itk_component(splitting_prop_linker) - - -sticky we

    grid $itk_component(background_determination_l) - - - - - -sticky we -pady {5 0}
    grid x $itk_component(local_background_check) - - - -  -sticky w -pady 2
    grid x $itk_component(max_unresolved_peaks_l) - - -  $itk_component(max_unresolved_peaks_e) -sticky we

    grid $itk_component(local_background_box_l) - - - - - -sticky we -pady {5 0}
    grid x x $itk_component(local_background_box_x_l) $itk_component(local_background_box_x_e) $itk_component(local_background_box_y_l) $itk_component(local_background_box_y_e) -sticky we
    grid x x x $itk_component(local_background_box_linker) - - -sticky we
 
    grid columnconfigure $itk_interior 1 -weight 1
    grid columnconfigure $itk_interior {0 6} -minsize $indent
    grid rowconfigure $itk_interior {99} -minsize 7

    eval itk_initialize $args

}

body Spotfindingsettings::getSpotfindingRelayBool { } {
    return $spotfinding_relay_bool
}

body Spotfindingsettings::setSpotfindingRelayBool {a_value} {
    set spotfinding_relay_bool $a_value
}

########################################################################
# Widget callback methods                                              #
########################################################################

body Spotfindingsettings::linkPeakSep {dim1 dim2} {
    if {[$itk_component(peak_sep_prop_linker) query]} {
        $itk_component(peak_sep_${dim2}_e) update [$itk_component(peak_sep_${dim1}_e) getValue]
    }
    if {![$::session getParameterValue "fix_separation"]} {
	$::session updateSetting "fix_separation" 1 1 1
    }
}

body Spotfindingsettings::linkSplitting {dim1 dim2} {
    if {[$itk_component(splitting_prop_linker) query]} {
	$itk_component(splitting_${dim2}_e) update [$itk_component(splitting_${dim1}_e) getValue]
    }
}

body Spotfindingsettings::linkLocalBackgroundBoxSize {dim1 dim2} {
    if {[$itk_component(local_background_box_linker) query]} {
	 $itk_component(local_background_box_${dim2}_e) update [$itk_component(local_background_box_${dim1}_e) getValue]
    }
}

body Spotfindingsettings::linkSpotSize { var } {
    switch -- $var {
        minx {
	    set new_val [$itk_component(spot_size_min_x_e) getValue]
            $itk_component(spot_size_min_x_e) update $new_val
	    if {[$itk_component(spot_size_prop_linker) query]} {
                $itk_component(spot_size_min_y_e) update $new_val
            }
        }
        miny {
	    set new_val [$itk_component(spot_size_min_y_e) getValue]
            $itk_component(spot_size_min_y_e) update $new_val
            if {[$itk_component(spot_size_prop_linker) query]} {
                $itk_component(spot_size_min_x_e) update $new_val
            }
        }
        maxx {
	    set new_val [$itk_component(spot_size_max_x_e) getValue]
	    $itk_component(spot_size_max_x_e) update $new_val
            if {[$itk_component(spot_size_prop_linker) query]} {
                $itk_component(spot_size_max_y_e) update $new_val
            }
        }
        maxy {
	    set new_val [$itk_component(spot_size_max_y_e) getValue]
	    $itk_component(spot_size_max_y_e) update $new_val
            if {[$itk_component(spot_size_prop_linker) query]} {
                $itk_component(spot_size_max_x_e) update $new_val
            }
        }
    }
}

body Spotfindingsettings::updateOrientation { a_orientation } {
    $itk_component(image_combo) configure -state normal -editable 1
    $itk_component(image_combo) delete 0 end
    $itk_component(image_combo) insert 0 [$an_image getShortName]
    $itk_component(image_combo) configure -editable 0
}

body Spotfindingsettings::updateImageSettings { } {
    .image updateSpotfindingSettings \
	[list \
	     $search_area_min_radius \
	     $search_area_max_radius \
	     $exclusion_segment_horizontal \
	     $exclusion_segment_vertical \
	     $bbox_orientation \
	     $bbox_offset]
}

body Spotfindingsettings::updateSearchArea { } {
    $itk_component(min_radius_e) downloadFromSession
    $itk_component(max_radius_e) downloadFromSession
}

body Spotfindingsettings::localBackgroundPrep {a_value } {
    if {$a_value == 0} {
	$::session updateSetting spot_size_max_x "2.00" 1 1 "User" 0 
	$::session updateSetting spot_size_max_y "2.00" 1 1 "User" 0 
	$::session updateSetting spot_splitting_x "0.30" 1 1 "User" 0 
	$::session updateSetting spot_splitting_y "0.30" 1 1 "User" 0 
	$itk_component(local_background_box_x_e) configure -state disabled
	$itk_component(local_background_box_y_e) configure -state disabled
	$itk_component(max_unresolved_peaks_e) configure -state disabled
    } else {
	$::session updateSetting spot_size_max_x "10.00" 1 1 "User" 0 
	$::session updateSetting spot_size_max_y "10.00" 1 1 "User" 0 
	$::session updateSetting spot_splitting_x "0.00" 1 1 "User" 0 
	$::session updateSetting spot_splitting_y "0.00" 1 1 "User" 0 
	$itk_component(local_background_box_x_e) configure -state normal
	$itk_component(local_background_box_y_e) configure -state normal
	$itk_component(max_unresolved_peaks_e) configure -state normal
    }	
}

########################################################################
# Usual config options                                                 #
########################################################################

usual Spotfindingsettings { 
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}

