#
#     Copyright (C) 2004  Raj Pannu, Steven Ness
#
#CCP4i_cvs_Id $Id: bp3.com,v 1.3 2006/02/02 16:33:12 mdw Exp $

#CCP4I SCRIPT TEMPLATE bp3

{ $CYCLES != "" } cycle $CYCLES

{ $REFINE_ALL } refall 

{ $STATS } stats $STATS

{ $THRESHOLD != 4 } threshold $THRESHOLD

IF { $CENTRIC_NODES != 3 || $ACENTRIC_NODES != 27 || $AMPLITUDE_NODES != 3} 
	1 node $CENTRIC_NODES $ACENTRIC_NODES $AMPLITUDE_NODES
ENDIF

{ $ACENTRIC } acentric 

{ $CENTRIC } centric 

{ $VERBOSE } verbose 

IF { $N_CRYSTALS > 0 }
LOOP I 1 $N_CRYSTALS
	
	1 xtal $CRYSTAL_ID($I)
	
	{ $CHANGE_CELL($I) } cell $CELL_1($I) $CELL_2($I) $CELL_3($I) $CELL_4($I) $CELL_5($I) $CELL_6($I)
	
	IF { $N_ATOMS($I) > 0 }
	LOOP J 1 $N_ATOMS($I)
		{ [IfSet $ATOM_ID($I,$J)] } atom $ATOM_ID($I,$J) 
		- { [IfSet $ATOM_SITE($I,$J)] } site $ATOM_SITE($I,$J)
		{ !$SAME_SITE && { [IfSet $ATOM_X($I,$J)] && [IfSet $ATOM_Y($I,$J)] && [IfSet $ATOM_Z($I,$J)] } } xyz $ATOM_X($I,$J) $ATOM_Y($I,$J) $ATOM_Z($I,$J)
		- { $ATOM_X_NOREF($I,$J) || $ATOM_Y_NOREF($I,$J) || $ATOM_Z_NOREF($I,$J) } noref
		- { $ATOM_X_NOREF($I,$J) } x
		- { $ATOM_Y_NOREF($I,$J) } y
		- { $ATOM_Z_NOREF($I,$J) } z
		{ [IfSet $ATOM_OCCU($I,$J) ] } occu $ATOM_OCCU($I,$J) 
		- { $ATOM_OCCU_NOREF($I,$J) } noref
		{ [IfSet $ATOM_BISO($I,$J) ] } biso $ATOM_BISO($I,$J) 
		- { $ATOM_BISO_NOREF($I,$J) } noref

		{ [IfSet $ATOM_U11($I,$J) ] } uano $ATOM_U11($I,$J)
		- { [IfSet $ATOM_U12($I,$J)] && [IfSet $ATOM_U13($I,$J)] && [IfSet $ATOM_U22($I,$J)] && [IfSet $ATOM_U23($I,$J)] && [IfSet $ATOM_U33($I,$J)] } $ATOM_U12($I,$J) $ATOM_U13($I,$J) $ATOM_U22($I,$J) $ATOM_U23($I,$J) $ATOM_U33($I,$J)
   		- { $ATOM_UANO_NOREF($I,$J) } noref

	ENDLOOP
	ENDIF

	IF { $N_DATA($I) > 0 }
	LOOP J 1 $N_DATA($I)

		1 dname $DATA_ID($I,$J)
	
		{ $HIGH_RES($I,$J) && $LOW_RES($I,$J) } reso $HIGH_RES($I,$J) $LOW_RES($I,$J)


		IF { !$ANOMALOUS($I,$J) } 
			1 column F=$FP($I,$J) SF=$SIGFP($I,$J)
		ELSE
			1 column F+=$FP_PLUS($I,$J) SF+=$SIGFP_PLUS($I,$J) F-=$FP_MINUS($I,$J) SF-=$SIGFP_MINUS($I,$J)
		ENDIF

		{ [IfSet $FORM_ID($I,$J)] } form $FORM_ID($I,$J) 
		- { [IfSet $FORM_FP($I,$J)] } FP=$FORM_FP($I,$J) 
    	- { [IfSet $FORM_FPP($I,$J)] } FPP=$FORM_FPP($I,$J)

	ENDLOOP
	ENDIF

ENDLOOP
ENDIF

IF { $SAME_SITE }
IF { $N_SITES > 0 }
LOOP I 1 $N_SITES
	1 site $I $SITE_X($I) $SITE_Y($I) $SITE_Z($I)
		- { $SITE_X_NOREF($I) || $SITE_Y_NOREF($I) || $SITE_Z_NOREF($I) } noref
		- { $SITE_X_NOREF($I) } x
		- { $SITE_Y_NOREF($I) } y
		- { $SITE_Z_NOREF($I) } z

ENDLOOP
ENDIF
ENDIF

{ $TWO_D_INTEGRATION } threshold 100000.0

{ $ALLINFLAG } allin

{ $PHASE } phase 

