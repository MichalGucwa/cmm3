#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
set typedef(_chain_constitution) { menu  {      protein
                                                non-protein
                                                water }
                                         {      PROTEIN
                                                WAT
                                                WAT } }

set typedef(_chain_id_menu)     { varmenu CHAIN_ID_MENU {} 4 }

set typedef(_chain_type)        { varmenu CHAIN_TYPE_MENU {} 4 }

set typedef(_residue_id)        { text 4 NOTOBLIG }

set typedef(_residue_type)      { text 4 NOTOBLIG }

set typedef(_atom_id)           { text 4 NOTOBLIG }

set typedef(_terminal_group)    { menu {        "N"
                                                "N-formyl"
                                                "N-acetyl"
                                                "COO" }
                                             { 3 4 5 2 } }

set typedef(_special_group_type) { menu {       "has cis-peptide"
                                                "linked to carbohydrate" }
                                        {    CISP
                                             CARBO } }

set typedef(_protin_dist_code)  { menu  {       "Bond length"
                                                "1-3distance"
                                                "Intraplanar"
                                                "Hbond/metal"
                                                "Special" }
                                                 { 1 2 3 4 5 } }

set typedef(_protin_bfactor_code) { menu {      "Mainchn bond"
                                                "Mainchn angle"
                                                "Sidechn bond"
                                                "Sidechn angle"
                                                "Special" }
                                                { 1 2 3 4 5 } }

set typedef(_protin_list)       { menu {        all
                                                some
                                                few } }

set typedef(_protin_nonx_code)  { menu { "tight" \
                                        "tight main chain & medium side chain" \
                                        "tight main chain & loose side chain" \
                                        "medium" \
                                        "medium main chain & loose side chain" \
                                        "loose" }
                                        { 1 2 3 4 5 6 } }

