%%BeginResource: latin1_prolog

% ReEncodeSmall from Adobe Postscript Tutorial and Cookbook
/reencsmalldict 12 dict def
/ReEncodeSmall
 {reencsmalldict begin
  /newcodesandnames exch def
  /newfontname exch def
  /basefontname exch def

  /basefontdict basefontname findfont def
  /newfont basefontdict maxlength dict def

  basefontdict
   {exch dup /FID ne
     {dup /Encoding eq
       {exch dup length array copy
	 newfont 3 1 roll put}
       {exch newfont 3 1 roll put}
       ifelse
     }
     {pop pop}
     ifelse
   }forall

  newfont /FontName newfontname put
  newcodesandnames aload pop

  newcodesandnames length 2 idiv
   {newfont /Encoding get 3 1 roll put}
   repeat

  newfontname newfont definefont pop
  end
}def
%%EndResource
%%BeginResource: latin1_encoding
/encode_vector [
8#040	/space        	8#041	/exclam       	8#042	/quotedbl     	
8#043	/numbersign   	8#044	/dollar       	8#045	/percent      	
8#046	/ampersand    	8#047	/quoteright   	8#050	/parenleft    	
8#051	/parenright   	8#052	/asterisk     	8#053	/plus         	
8#054	/comma        	8#055	/minus        	8#056	/period       	
8#057	/slash        	8#060	/zero         	8#061	/one          	
8#062	/two          	8#063	/three        	8#064	/four         	
8#065	/five         	8#066	/six          	8#067	/seven        	
8#070	/eight        	8#071	/nine         	8#072	/colon        	
8#073	/semicolon    	8#074	/less         	8#075	/equal        	
8#076	/greater      	8#077	/question     	8#100	/at           	
8#101	/A            	8#102	/B            	8#103	/C            	
8#104	/D            	8#105	/E            	8#106	/F            	
8#107	/G            	8#110	/H            	8#111	/I            	
8#112	/J            	8#113	/K            	8#114	/L            	
8#115	/M            	8#116	/N            	8#117	/O            	
8#120	/P            	8#121	/Q            	8#122	/R            	
8#123	/S            	8#124	/T            	8#125	/U            	
8#126	/V            	8#127	/W            	8#130	/X            	
8#131	/Y            	8#132	/Z            	8#133	/bracketleft  	
8#134	/backslash    	8#135	/bracketright 	8#136	/asciicircum  	
8#137	/underscore   	8#140	/quoteleft    	8#141	/a            	
8#142	/b            	8#143	/c            	8#144	/d            	
8#145	/e            	8#146	/f            	8#147	/g            	
8#150	/h            	8#151	/i            	8#152	/j            	
8#153	/k            	8#154	/l            	8#155	/m            	
8#156	/n            	8#157	/o            	8#160	/p            	
8#161	/q            	8#162	/r            	8#163	/s            	
8#164	/t            	8#165	/u            	8#166	/v            	
8#167	/w            	8#170	/x            	8#171	/y            	
8#172	/z            	8#173	/braceleft    	8#174	/bar          	
8#175	/braceright   	8#176	/tilde        	8#240	/space        	
8#241	/exclamdown   	8#242	/cent         	8#243	/sterling     	
8#244	/currency     	8#245	/yen          	8#246	/brokenbar    	
8#247	/section      	8#250	/dieresis     	8#251	/copyright    	
8#252	/ordfeminine  	8#253	/guillemotleft	8#254	/logicalnot   	
8#255	/hyphen       	8#256	/registered   	8#257	/macron       	
8#260	/degree       	8#261	/plusminus    	8#262	/twosuperior  	
8#263	/threesuperior	8#264	/acute        	8#265	/mu           	
8#266	/paragraph    	8#267	/bullet       	8#270	/cedilla      	
8#271	/dotlessi     	8#272	/ordmasculine 	8#273	/guillemotright	
8#274	/onequarter   	8#275	/onehalf      	8#276	/threequarters	
8#277	/questiondown 	8#300	/Agrave       	8#301	/Aacute       	
8#302	/Acircumflex  	8#303	/Atilde       	8#304	/Adieresis    	
8#305	/Aring        	8#306	/AE           	8#307	/Ccedilla     	
8#310	/Egrave       	8#311	/Eacute       	8#312	/Ecircumflex  	
8#313	/Edieresis    	8#314	/Igrave       	8#315	/Iacute       	
8#316	/Icircumflex  	8#317	/Idieresis    	8#320	/Eth          	
8#321	/Ntilde       	8#322	/Ograve       	8#323	/Oacute       	
8#324	/Ocircumflex  	8#325	/Otilde       	8#326	/Odieresis    	
8#327	/multiply     	8#330	/Oslash       	8#331	/Ugrave       	
8#332	/Uacute       	8#333	/Ucircumflex  	8#334	/Udieresis    	
8#335	/Yacute       	8#336	/Thorn        	8#337	/germandbls   	
8#340	/agrave       	8#341	/aacute       	8#342	/acircumflex  	
8#343	/atilde       	8#344	/adieresis    	8#345	/aring        	
8#346	/ae           	8#347	/ccedilla     	8#350	/egrave       	
8#351	/eacute       	8#352	/ecircumflex  	8#353	/edieresis    	
8#354	/igrave       	8#355	/iacute       	8#356	/icircumflex  	
8#357	/idieresis    	8#360	/eth          	8#361	/ntilde       	
8#362	/ograve       	8#363	/oacute       	8#364	/ocircumflex  	
8#365	/otilde       	8#366	/odieresis    	8#367	/divide       	
8#370	/oslash       	8#371	/ugrave       	8#372	/uacute       	
8#373	/ucircumflex  	8#374	/udieresis    	8#375	/yacute       	
8#376	/thorn        	8#377	/ydieresis    	
] def
%%EndResource
