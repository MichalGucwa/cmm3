#include "PDBheader.h"

void PDBheaderAssignRemark(ObjEntityMolecule *I, char *line, int remark_num) {
  char *p,q[FileLineLength];
  int symop_index=0, symop_translation=0;
  if(remark_num==2) {
    p=line;
    p=str2ncpy(q,p,60);
    p=str2strip(q," ");
    if(!strncmp(p,"RESOLUTION",10)) {
      p=str2nskip(p,10);
      if(*p=='.') str2nskip(p,1);
      p=str2cskip(p,' ');
      if(sscanf(p,"%f",&I->resolution)!=1) {
        I->resolution=-1;
      } else {
        p=str2strip(p," -.0123456789");
        if(strncmp(p,"ANGSTROMS",9)) I->resolution=-1;  // reset resolution to undefined if the remainder of the string does not match ANGSTROMS
      }
    }
  } else if(remark_num=290 && I->symop_status>=0) {   // This is for symmetry operation reading in case it is not a standard space group specified in syminfo.lib file
    p=line;
    p=str2ncpy(q,p,8);
    if(sscanf(q,"%d",&symop_index)!=1) symop_index=-1;
    p=str2ncpy(q,p,3);
    if(sscanf(q,"%d",&symop_translation)!=1) symop_translation=-1;
    if(symop_index>0 && symop_translation==555 && symop_index==I->symop_status+1) {
      if(I->symop_status==0) AllocP(I->symop,ccp4_symop,1024);     // Give it 1K potential symop lines total
      p=str2ncpy(q,p,49);
      p=str2strip(q," ");
      I->symop[I->nsymop]=symop_to_rotandtrn(q,q+strlen(q));
      I->nsymop++;
      I->symop_status=symop_index;
    } else if (I->symop_status>0) {     // In any case input is not expected, shut off reading immediately
      I->symop_status=-1;
    }
  }
}

void PDBheaderAssignTitle (ObjEntityMolecule *I, char *line, int continuation, int isEoS) {
  char *p,q[FileLineLength];
  char *pt,word[FileLineLength];
  int  len_t=0,len_c=0,len_firstword=0;
  p=line;
  p=str2ncpy(q,p,70);
  p=str2strip(q," ");
  p=str2replace(p,'|','/');
  if(continuation) {
    len_t=strlen(I->title);
    len_c=strlen(p);
    pt=str2cskip(p,' ');
    len_firstword=pt-p;
    if(len_t+len_firstword<EntityTitleLen) {
      pt=I->title+len_t;
      if(len_t+len_c>=EntityTitleLen) {
        len_c=EntityTitleLen-len_t-1;
        while(len_c && *(p+len_c)!=' ') len_c--;
      }
      if(len_c>0) {
        *(pt++)=' ';
        strncpy(pt,p,len_c);
        I->title[len_t+len_c+1]=0;
      }
      I->title[EntityTitleLen]=0;
    }
  } else {
    strcpy(I->title,p);
  }
}

void PDBheaderAssignCompnd(ObjEntityMolecule *I, char *line, int continuation, int isEoS) {
  char *p,q[TemporaryFieldLen],q2[TemporaryFieldLen],msg[FileLineLength];
  int  compndFlag,keyLength,q2len,compound_error=0;
  int  isOpenLine,isCloseLine,compndFlagClose,tempFieldLength;
  int  numFunction;
  ObjComponentInfo *comi;
  ObjFunctionInfo  *funi;
  p=line;
  p=str2ncpy(q,p,70);
  p=str2strip(q," ");
  if(isEoS) strcat(p,";");
  while(1) {
    if(continuation) {
      if (continuation!=I->compnd_done+1) {
        sprintf(msg,"Unexpected COMPND continuation mark encountered, expecting %d, got %d (%s).\n", I->compnd_done+1, continuation, I->pdbid);
        compound_error=1; break;
      }
      I->compnd_done=continuation;
    } else {
      if(!strncmp(p,"MOL_ID: 1;",10)) {
        I->compnd_done=1;
      } else {
        sprintf(msg,"COMPND record: Unexpected first line (%s).\n",I->pdbid);
        compound_error=2; break;
      }
    }
    if        (I->compnd_wait) {                 compndFlag=10; keyLength=0;      // string
    } else if (!strncmp(p,"MOL_ID"       , 6)) { compndFlag=1;  keyLength=6;      // integer
    } else if (!strncmp(p,"MOLECULE"     , 8)) { compndFlag=2;  keyLength=8;      // string
    } else if (!strncmp(p,"CHAIN"        , 5)) { compndFlag=3;  keyLength=5;      // CSV
    } else if (!strncmp(p,"FRAGMENT"     , 8)) { compndFlag=4;  keyLength=8;
    } else if (!strncmp(p,"SYNONYM"      , 7)) { compndFlag=5;  keyLength=7;      // CSV
    } else if (!strncmp(p,"EC"           , 2)) { compndFlag=6;  keyLength=2;      // CSV
    } else if (!strncmp(p,"ENGINEERED"   ,10)) { compndFlag=7;  keyLength=10;     // boolean
    } else if (!strncmp(p,"MUTATION"     , 8)) { compndFlag=8;  keyLength=8;      // boolean
    } else if (!strncmp(p,"OTHER_DETAILS",13)) { compndFlag=9;  keyLength=13;
    } else {                                     compndFlag=0;  keyLength=0;
      sprintf(msg,"COMPND record: Unexpected pattern %s (%s).\n",p,I->pdbid);
      compound_error=3; break;
    }
    if(compndFlag) {
      isOpenLine  = (compndFlag>0 && compndFlag<10) ? 1 : 0;
      isCloseLine = (p[strlen(p)-1]==';') ? 1 : 0;
      if(isOpenLine) {
        if(keyLength) p=str2nskip(p,keyLength);
        p=str2strip(p," :");
        I->temp_field[0]=0;
        strcpy(I->temp_field,p);
        if(isCloseLine) {
          compndFlagClose=compndFlag;
          I->compnd_wait=0;
        } else {
          compndFlagClose=0;
          I->compnd_wait=compndFlag;
        }
      } else {
        tempFieldLength=strlen(I->temp_field);
        if(tempFieldLength<TemporaryFieldLen-FileLineLength) {
          strcat(I->temp_field," ");
          strcat(I->temp_field,p);
        } else {
          sprintf(msg,"COMPND record: Field pattern (%s) is too long (%s).\n",I->temp_field,I->pdbid);
          compound_error=4; break;
        }
        if(isCloseLine) {
          compndFlagClose=I->compnd_wait;
          I->compnd_wait=0;
        } else {
          compndFlagClose=0;
          // I->compnd_wait unchanged
        }
      }
   
      if(compndFlagClose) {
        tempFieldLength=strlen(I->temp_field);
        if(I->temp_field[tempFieldLength-1]!=';') {
          sprintf(msg,"COMPND record: Field pattern (%s) does not end with semicolon (%s).\n",I->temp_field,I->pdbid);
          compound_error=5; break;
        }
        I->temp_field[tempFieldLength-1]=0;
        p=I->temp_field;
   
        if(compndFlagClose==1) {
          comi=I->ComponentInfo+I->numComponent;
          comi->index=I->numComponent;
          if(sscanf(p,"%d",&comi->componentnum)!=1) comi->componentnum=-1;
          I->numComponent++;
          ObjComponentInit(I->ComponentInfo+I->numComponent);
        } else {
          comi=I->ComponentInfo+I->numComponent-1;
          if(comi->index==-1) {
            sprintf(msg,"COMPND record: Field pattern (%s) being read without MOL_ID field (%s).\n",p,I->pdbid);
            compound_error=6; break;
          }
          if(compndFlagClose>=3 && compndFlagClose<=6) {  // comma separated multiple fields
            if(p[strlen(p)-1]!=',' && p[strlen(p)-1]!=';') strcat(p,",");                                // To make the format of all CSV fields unanimous (x, x, x, ..., x,)
            str2replace(p,';',',');
            switch(compndFlagClose) {
              case 3: strcpy(comi->temp_field,p);
                      // evaluation of CHAIN need to be delayed till later after all chains objects has been created
                      break;
              case 4: // FRAGMENT is not collected
                      break;
              case 5: while(strchr(p,',')) {
                        p=str2bskip(p,' ');
                        p=str2ccpy(q,p,',');
                        if(*(p-2)=='\\' && *(p-1)==',') {
                          strcat(q2,q);
                          q2len=strlen(q2);
                          q2[q2len-1]=0;
                          q2[q2len-2]='-';
                        } else {
                          if (strlen(q2)) {
                            strcat(q2,q);
                            PDBheaderAddKeyword(I,q2,comi);
                          } else {
                            PDBheaderAddKeyword(I,q,comi);
                          }
                          q2[0]=0;
                          q2len=0;
                        }
                      }; break;
              case 6: numFunction=str2symbolcnt(p,',');
                      AllocP(comi->FunctionInfo,ObjFunctionInfo,(numFunction+1));
                      funi=comi->FunctionInfo;
                      ObjFunctionInit(funi);
                      comi->numFunction=0;
                      while(strchr(p,',')) {
                        p=str2bskip(p,' ');
                        p=str2ccpy(q,p,',');
                        PDBheaderAddFunction(I,q,comi);
                      }; break;
            }
          } else {
            switch(compndFlagClose) {     // field with single value string
              case 2: strncpy(comi->component_name,p,ComponentNameLen); break;
              case 7: if(p[0]=='Y') comi->engineered=1; break;
              case 8: if(p[0]=='Y') comi->mutation=1;   break;
              case 9: // OTHER_DETAILS is not collected
                      break;
            }
          }
        }
      }
    }
    break;
  }
  if(compound_error) PWarning(msg);
}

void PDBheaderAssignSource(ObjEntityMolecule *I, char *line, int continuation, int isEoS) {
  char *p,q[TemporaryFieldLen],msg[FileLineLength];
  int  sourceFlag,keyLength,source_error=0;
  int  i,componentnum,componentFound;
  ObjComponentInfo *comi;
  // NOTE: The work of this part has been shifted to neighborhood_update.pl script,
  //       taxonomy info will be read from xxxx.cluster file
  //
  // Evaluation of Source organism into protein function for each component will be delayed until later
  // After all residues and atoms has been parsed, and before neighbor will be calculated
  p=line;
  p=str2ncpy(q,p,70);
  p=str2strip(q," ");
  if(isEoS) strcat(p,";");
  while(1) {
    if(continuation) {
      if (continuation!=I->source_done+1) {
        sprintf(msg,"SOURCE record: Unexpected SOURCE continuation mark encountered, expecting %d, got %d (%s).\n", I->source_done+1, continuation, I->pdbid);
        source_error=1; break;
      }
      I->source_done=continuation;
    } else {
      if(!strncmp(p,"MOL_ID: 1;",10)) {
        I->source_done=1;
      } else {
        sprintf(msg,"SOURCE record: Unexpected first line (%s).\n",I->pdbid);
        source_error=2; break;
      }
    }
    if        (!strncmp(p,"MOL_ID"                 , 6)) { sourceFlag=1;  keyLength=6;
    } else if (!strncmp(p,"ORGANISM_SCIENTIFIC"    ,19)) { sourceFlag=2;  keyLength=19;
    } else if (!strncmp(p,"ORGANISM_COMMON"        ,15)) { sourceFlag=3;  keyLength=15;
    } else if (!strncmp(p,"ORGANISM_TAXID"         ,14)) { sourceFlag=4;  keyLength=14;
    } else if (!strncmp(p,"SYNTHETIC"              , 9)) { sourceFlag=5;  keyLength=9;
    } else if (!strncmp(p,"EXPRESSION_SYSTEM_TAXID",23)) { sourceFlag=6;  keyLength=23;
    } else if (!strncmp(p,"EXPRESSION_SYSTEM_"     ,18)) { sourceFlag=22; keyLength=18;
    } else if (!strncmp(p,"EXPRESSION_SYSTEM"      ,17)) { sourceFlag=7;  keyLength=17;
    } else if (!strncmp(p,"FRAGMENT"               , 8)) { sourceFlag=8;  keyLength=8;
    } else if (!strncmp(p,"STRAIN"                 , 6)) { sourceFlag=9;  keyLength=6;
    } else if (!strncmp(p,"VARIANT"                , 7)) { sourceFlag=10; keyLength=7;
    } else if (!strncmp(p,"CELL_LINE"              , 9)) { sourceFlag=11; keyLength=9;
    } else if (!strncmp(p,"CELLULAR_LOCATION"      ,17)) { sourceFlag=12; keyLength=17;
    } else if (!strncmp(p,"CELL"                   , 4)) { sourceFlag=12; keyLength=4;
    } else if (!strncmp(p,"ATCC"                   , 4)) { sourceFlag=13; keyLength=4;
    } else if (!strncmp(p,"COLLECTION"             ,10)) { sourceFlag=14; keyLength=10;
    } else if (!strncmp(p,"ORGAN"                  , 5)) { sourceFlag=15; keyLength=5;
    } else if (!strncmp(p,"TISSUE"                 , 6)) { sourceFlag=16; keyLength=6;
    } else if (!strncmp(p,"ORGANELLE"              , 9)) { sourceFlag=17; keyLength=9;
    } else if (!strncmp(p,"SECRETION"              , 9)) { sourceFlag=18; keyLength=9;
    } else if (!strncmp(p,"PLASMID"                , 7)) { sourceFlag=19; keyLength=7;
    } else if (!strncmp(p,"GENE"                   , 4)) { sourceFlag=20; keyLength=4;
    } else if (!strncmp(p,"OTHER_DETAILS"          ,13)) { sourceFlag=21; keyLength=13;
    } else if (I->source_wait) {                           sourceFlag=23; keyLength=0;
    } else {                                               sourceFlag=0;  keyLength=0;
      sprintf(msg,"SOURCE record: Unexpected pattern %s (%s).\n",p,I->pdbid);
      source_error=3; break;
    }
    I->source_wait = (p[strlen(p)-1]==';') ? 0 : 1;
    if(sourceFlag<=7) {
      if(keyLength) p=str2nskip(p,keyLength);
      p=str2strip(p," :");
      if(sourceFlag==1) {
        if(sscanf(p,"%d",&componentnum)!=1) componentnum=-1;
        componentFound=0;
        for(i=0;i<I->numComponent;i++) {
          comi=I->ComponentInfo+i;
          if(comi->componentnum == componentnum) {
            I->temp_index=comi->index;
            componentFound=1;
            break;
          }
        }
        if(!componentFound) {
          sprintf(msg,"SOURCE record: Cannot locate corresponding component number (%d) for SOURCE card.\n",componentnum,I->pdbid);
          source_error=4; break;
        }
      } else {
        if(I->temp_index<0 || I->temp_index>=I->numComponent) {
          sprintf(msg,"SOURCE record: Index to component (%d) is out of range.\n",I->temp_index,I->pdbid);
          source_error=5; break;
        }
        comi=I->ComponentInfo+I->temp_index;
        p[strlen(p)-1]=0;
        if(sourceFlag==4 && comi->organism_id==-1) {      // old version: Do not assign taxonomy ID if it has been initiated as -2 (synthetic)
                                                          // new version: DO assign taxonomy ID even if it is -2 (synthetic), however, synthetic field will be set in that situation
          sscanf(p,"%d",&comi->organism_id);
        } else if (sourceFlag==2) {
          strncpy(comi->organism_name,p,OrganismNameLen);
          if(!strncmp(p,"SYNTHETIC",9)) comi->synthetic=1;
        } else if (sourceFlag==6) {
          sscanf(p,"%d",&comi->expression_id);
        } else if (sourceFlag==7) {
          strncpy(comi->expression_name,p,OrganismNameLen);
        } else if (sourceFlag==5) {
          if(p[0]=='Y') comi->synthetic=1;
        }
      }
    }
    break;
  }
  if(source_error) PWarning(msg);
}

void PDBheaderAssignKeywds(ObjEntityMolecule *I, char *line, int continuation, int isEoS) {
  char *p,q[FileLineLength],msg[FileLineLength];
  int tempFieldLength;
  p=line;
  p=str2ncpy(q,p,70);
  p=str2strip(q," ");
  if(continuation) {
    tempFieldLength=strlen(I->temp_field);
    if(tempFieldLength<TemporaryFieldLen-FileLineLength) {
      strcat(I->temp_field," ");
      strcat(I->temp_field,p);
    } else {
      sprintf(msg,"KEYWDS pattern (%s) is too long (%s).\n",I->temp_field,I->pdbid);
      PFatalError(msg);
    }
  } else {
    strcpy(I->temp_field,p);
  }
  // STEP 1: Assign the keywords from I->temp_field
  if(isEoS) {
    p=I->temp_field;
    while(strchr(p,',')) {
      p=str2bskip(p,' ');
      p=str2ccpy(q,p,',');
      PDBheaderAddKeyword(I,q,NULL);
    };
    p=str2bskip(p,' ');
    PDBheaderAddKeyword(I,p,NULL);
  }
}

void PDBheaderAssignExpdta(ObjEntityMolecule *I, char *line, int continuation) {
  char *p,q[FileLineLength];
  p=line;
  if(continuation) {
  } else {
    p=str2ncpy(q,p,60);
    p=str2strip(q," ");
    if     (!strncmp(p,"X-RAY",5))                      I->exp_method=EXP_METHOD_XRAY      ;
    else if(!strncmp(p,"NMR",3))                        I->exp_method=EXP_METHOD_NMR       ;
    else if(str2contains(p,"ELECTRON MICROSCOPY"))      I->exp_method=EXP_METHOD_ELEMICRO  ;
    else if(str2contains(p,"ELECTRON CRYSTALLOGRAPHY")) I->exp_method=EXP_METHOD_ELEMICRO  ;
    else if(str2contains(p,"FIBER DIFFRACTION"))        I->exp_method=EXP_METHOD_FIBERDIFF ;
    else if(str2contains(p,"SOLUTION SCATTERING"))      I->exp_method=EXP_METHOD_SOLSCAT   ;
    else if(str2contains(p,"NEUTRON DIFFRACTION"))      I->exp_method=EXP_METHOD_NEUDIFF   ;
    else if(str2contains(p,"POWDER DIFFRACTION"))       I->exp_method=EXP_METHOD_POWDERDIFF;
    else if(!strncmp(p,"FTIR",4))                       I->exp_method=EXP_METHOD_FTIR      ;
    else if(!strncmp(p,"INFRARED",8))                   I->exp_method=EXP_METHOD_FTIR      ;
    else if(str2contains(p,"ELECTRON DIFFRACTION"))     I->exp_method=EXP_METHOD_ELEDIFF   ;
    else if(str2contains(p,"X-RAY"))                    I->exp_method=EXP_METHOD_XRAY      ;
    else if(str2contains(p,"XRAY"))                     I->exp_method=EXP_METHOD_XRAY      ;
    else if(str2contains(p,"SYNCHROTRON RADIATION"))    I->exp_method=EXP_METHOD_XRAY      ;
    else if(str2contains(p,"SOLUTION NMR"))             I->exp_method=EXP_METHOD_NMR       ;
    else if(str2contains(p,"SOLID-STATE NMR"))          I->exp_method=EXP_METHOD_NMR       ;
    else if(str2contains(p,"ELECTRON TOMOGRAPHY"))      I->exp_method=EXP_METHOD_ELETOMO   ;
    else if(str2contains(p,"FLUORESCENCE TRANSFER"))    I->exp_method=EXP_METHOD_FLUTR     ;
    else if(str2contains(p,"THEORETICAL MODEL"))        I->exp_method=EXP_METHOD_THEOMODEL ;
  }
}

void PDBheaderAssignHeader(ObjEntityMolecule *I, char *line) {
  int date_valid=0;
  char *p,*ph,q[FileLineLength],mmm[4];
  p=line;
  p=str2ncpy(q,p,40);
  ph=str2strip(q," ");
  strcpy(I->header,ph);
  p=str2ncpy(q,p,9);
  ph=str2strip(q," ");
  if(strlen(ph)==9 && ph[2]=='-' && ph[6]=='-' && isdigit(ph[0]) && isdigit(ph[1]) && isdigit(ph[7]) && isdigit(ph[8])) {
    mmm[0]=ph[3]; mmm[1]=ph[4]; mmm[2]=ph[5];
    if     (!strcasecmp(mmm,"JAN")) date_valid=1;
    else if(!strcasecmp(mmm,"FEB")) date_valid=1;
    else if(!strcasecmp(mmm,"MAR")) date_valid=1;
    else if(!strcasecmp(mmm,"APR")) date_valid=1;
    else if(!strcasecmp(mmm,"MAY")) date_valid=1;
    else if(!strcasecmp(mmm,"JUN")) date_valid=1;
    else if(!strcasecmp(mmm,"JUL")) date_valid=1;
    else if(!strcasecmp(mmm,"AUG")) date_valid=1;
    else if(!strcasecmp(mmm,"SEP")) date_valid=1;
    else if(!strcasecmp(mmm,"OCT")) date_valid=1;
    else if(!strcasecmp(mmm,"NOV")) date_valid=1;
    else if(!strcasecmp(mmm,"DEC")) date_valid=1;
    if(date_valid) {
      if(ph[0]=='0' && ph[1]=='0')  ph[1]=='1';
      else if(ph[0]>='4')           date_valid=0;
      else if(ph[0]=='3') {
        if(ph[1]>='2'||ph[3]=='F')  date_valid=0;
        else if(ph[1]=='1' &&
          (ph[3]=='S'||ph[3]=='N'||
           !strcasecmp(mmm,"APR")||
           !strcasecmp(mmm,"JUN"))) date_valid=0;
      }
    }
  }
  if(date_valid) strcpy(I->deposition_date,ph);
  else strcpy(I->deposition_date,"31-DEC-69");
  // Evaluation of I->header content into protein function for each component will be delayed until later
  // After all residues and atoms has been parsed, and before neighbor will be calculated
}

void PDBheaderAssignOrigx (ObjEntityMolecule *I, char *line, int matrix_row_num) {
  char *p,q[FileLineLength],msg[FileLineLength];
  int  matrix_error=0;
  float on1, on2, on3, tn;
  if (matrix_row_num>=1 && matrix_row_num<=3) {
    p=line;
    matrix_error=0;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&on1)!=1) matrix_error=1;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&on2)!=1) matrix_error=1;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&on3)!=1) matrix_error=1;
    p=str2nskip(p,5);
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&tn)!=1)  tn=0.0f;
    if(matrix_error) {
      sprintf(msg,"Unexpected ORIGX(x) matrix error encountered (%s).\n", I->pdbid);
      PFatalError(msg);
    }
    matrix_error=0;
    if (matrix_row_num==1) {
      if(I->origx_matrix == NULL) {
        AllocP(I->origx_matrix,ccp4_symop,1);
      } else {
        sprintf(msg,"Duplicated ORIGX(x) number encountered (%s).\n", I->pdbid);
        matrix_error=1;
      }
    }
    if (matrix_row_num!=I->origx_done+1) {
      sprintf(msg,"Unexpected ORIGX(x) number encountered, expecting ORIGX%d, got ORIGX%d (%s).\n", I->origx_done+1, matrix_row_num, I->pdbid);
      matrix_error=1;
    }
    if (matrix_error) PWarning(msg);
    else {
      I->origx_matrix->rot[matrix_row_num-1][0]=on1;
      I->origx_matrix->rot[matrix_row_num-1][1]=on2;
      I->origx_matrix->rot[matrix_row_num-1][2]=on3;
      I->origx_matrix->trn[matrix_row_num-1]   =tn;
      I->origx_done=matrix_row_num;
    }
  } else {
    sprintf(msg,"Unexpected ORIGX(x) number (x=%d) encountered (%s).\n", matrix_row_num, I->pdbid);
    PFatalError(msg);
  }
}

void PDBheaderAssignScale (ObjEntityMolecule *I, char *line, int matrix_row_num) {
  char *p,q[FileLineLength],msg[FileLineLength];
  int  matrix_error=0;
  float sn1, sn2, sn3, un;
  int i,j;
  if (matrix_row_num>=1 && matrix_row_num<=3) {
    p=line;
    matrix_error=0;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&sn1)!=1) matrix_error=1;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&sn2)!=1) matrix_error=1;
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&sn3)!=1) matrix_error=1;
    p=str2nskip(p,5);
    p=str2ncpy(q,p,10); if(sscanf(q,"%f",&un)!=1)  un=0.0f;
    if(matrix_error) {
      sprintf(msg,"Unexpected SCALE(x) matrix error encountered (%s).\n", I->pdbid);
      PFatalError(msg);
    }
    matrix_error=0;
    if (matrix_row_num==1) {
      if(I->scale_matrix == NULL) {
        AllocP(I->scale_matrix,ccp4_symop,1);
      } else {
        sprintf(msg,"Duplicated SCALE(x) number encountered (%s).\n", I->pdbid);
        matrix_error=1;
      }
    }
    if (matrix_row_num!=I->scale_done+1) {
      sprintf(msg,"Unexpected SCALE(x) number encountered, expecting SCALE%d, got SCALE%d (%s).\n", I->scale_done+1, matrix_row_num, I->pdbid);
      matrix_error=1;
    }
    if (matrix_error) PWarning(msg);
    else {
      I->scale_matrix->rot[matrix_row_num-1][0]=sn1;
      I->scale_matrix->rot[matrix_row_num-1][1]=sn2;
      I->scale_matrix->rot[matrix_row_num-1][2]=sn3;
      I->scale_matrix->trn[matrix_row_num-1]   =un;
      I->scale_done=matrix_row_num;
    }
  } else if(matrix_row_num==-1) {       // Assign default values for I->scale_matrix even when the records are not there
    AllocP(I->scale_matrix,ccp4_symop,1);
    for(i=0;i<3;i++) {
      for(j=0;j<3;j++) {
        I->scale_matrix->rot[i][j] = (i==j) ? 1.0f : 0.0f;
      }
      I->scale_matrix->trn[i]=0.0f;
    }
  } else {
    sprintf(msg,"Unexpected SCALE(x) number (x=%d) encountered (%s).\n", matrix_row_num, I->pdbid);
    PFatalError(msg);
  }
}

void PDBheaderAssignCryst (ObjEntityMolecule *I, char *line, int crystal_num) {
  char *p,*ps,q[FileLineLength],msg[FileLineLength];
  int  tempint;
  p=line;
  if(crystal_num==1) {
    p=str2ncpy(q,p,9); if(sscanf(q,"%f",&I->cell_a)!=1)     I->cell_a    =-1.0f;
    p=str2ncpy(q,p,9); if(sscanf(q,"%f",&I->cell_b)!=1)     I->cell_b    =-1.0f;
    p=str2ncpy(q,p,9); if(sscanf(q,"%f",&I->cell_c)!=1)     I->cell_c    =-1.0f;
    p=str2ncpy(q,p,7); if(sscanf(q,"%f",&I->cell_alpha)!=1) I->cell_alpha=-1.0f;
    p=str2ncpy(q,p,7); if(sscanf(q,"%f",&I->cell_beta )!=1) I->cell_beta =-1.0f;
    p=str2ncpy(q,p,7); if(sscanf(q,"%f",&I->cell_gamma)!=1) I->cell_gamma=-1.0f;
    p=str2nskip(p,1);
    p=str2ncpy(q,p,11);if(sscanf(q,"%s",msg)!=1) {      // In case this field is an empty string
                         I->space_group=NULL;
                         I->space_group_name[0]=0;
                         I->space_group_number=-1;
                       } else { // Attn: Since sscanf scans only the first word of the string,
                                // msg contains only first word, q contains the real space group name
                         ps=str2strip(q," ");
                         tempint=strlen(ps)-1;
                         if(ps[tempint]=='-') { // space group cant end with '-', if it did, it is a confliction with convention
                           ps[tempint]=ps[tempint-1];
                           ps[tempint-1]='-';
                         }
                       //if     (!strcmp(ps,"C 4 21 2")) strcpy(I->space_group_name, "P 4 21 2");
                       //else if(!strcmp(ps,"F 4 2 2"))  strcpy(I->space_group_name, "I 4 2 2");
                       //else
                         strcpy(I->space_group_name,ps);
                         I->space_group=ccp4spg_load_by_spgname(I->space_group_name);
                         I->space_group_number=I->space_group->spg_num;
                         if(I->space_group->spg_num==-1 && I->space_group->nsymop==0) { // try to load reversely
                           I->space_group=ccp4_spgrp_reverse_lookup(I->nsymop,I->symop);
                           I->space_group_number=I->space_group->spg_num;
                           if(I->space_group->spg_num==-1 && I->space_group->nsymop==0) { // in case it still fails
                             I->space_group->symop=I->symop;
                             I->space_group->nsymop=I->nsymop;
                           }
                         }
                       }
    p=str2ncpy(q,p,4); if(sscanf(q,"%d",&I->z_value)!=1)    I->z_value   =-1;
  } else {
    sprintf(msg,"Unexpected CRYSTAL number %d encountered (%s).\n", crystal_num, I->pdbid);
    PWarning(msg);
  }
}

void PDBheaderAddKeyword  (ObjEntityMolecule *I, char *word, ObjComponentInfo *comi) {
  ObjKeywordInfo *keyi;
  keyi=I->KeywordInfo+I->numKeyword;
  keyi->index=I->numKeyword;
  strncpy(keyi->keyword,word,ComponentNameLen);
  keyi->ComponentInfo=comi;
  if(comi!=NULL) {
    if(comi->numKeyword==0) comi->KeywordInfo=keyi;
    comi->numKeyword++;
  }
  I->numKeyword++;
  keyi=I->KeywordInfo+I->numKeyword;
  ObjKeywordInit(keyi);
}

void PDBheaderAddFunction (ObjEntityMolecule *I, char *word, ObjComponentInfo *comi) {
  char *p,q[FileLineLength],msg[FileLineLength];
  int ec1,ec2,ec3,ec4;
  ObjFunctionInfo *funi;
  funi=comi->FunctionInfo+comi->numFunction;
  funi->index=comi->numFunction;
  p=str2strip(word," ");
//printf("Adding word (%s)\n",word);
  if(sscanf(p,"%d.%d.%d.%d",&ec1,&ec2,&ec3,&ec4)==4) {
    funi->ec_primary=ec1*100+ec2;
    funi->ec_3rd_level=ec3;
    funi->ec_4th_level=ec4;
  } else if(sscanf(p,"%d.%d.%d.-",&ec1,&ec2,&ec3)==3) {
    funi->ec_primary=ec1*100+ec2;
    funi->ec_3rd_level=ec3;
    funi->ec_4th_level=-1;
  } else if(sscanf(p,"%d.%d.-.-",&ec1,&ec2)==2) {
    funi->ec_primary=ec1*100+ec2;
    funi->ec_3rd_level=-1;
    funi->ec_4th_level=-1;
  } else if(sscanf(p,"%d.-.-.-",&ec1)==1) {
    funi->ec_primary=ec1*100;
    funi->ec_3rd_level=-1;
    funi->ec_4th_level=-1;
  } else {
    sprintf(msg,"EC number contains unexpected pattern (%s) in (%s).\n",p,I->pdbid);
    PWarning(msg);
  }
  funi->ComponentInfo=comi;
  comi->numFunction++;
  funi=comi->FunctionInfo+comi->numFunction;
  ObjFunctionInit(funi);
}

void PDBheaderFinishTouch (ObjEntityMolecule *I) {
  char *p,*p2,q[TemporaryFieldLen],msg[FileLineLength];
  int i,j,chainFound;
  ObjComponentInfo *comi;
  ObjChainInfo *ci;

  // STEP 2: Assign the links from chains using data stored in comi->temp_field
  for(i=0;i<I->numComponent;i++) {
    comi=I->ComponentInfo+i;
    p=comi->temp_field;
    while(strchr(p,',')) {
      p=str2bskip(p,' ');
      p=str2ccpy(q,p,',');
      if(strlen(q)!=1) {
        p2=str2strip(q," ");
        strcpy(q,p2);
        if(strlen(q)!=1) {
          sprintf(msg,"Unexpected length, chainid (%s) is not a single character string in (%s).\n",q,I->pdbid);
          PFatalError(msg);
        }
      }
      chainFound=0;
      for(j=0;j<I->numChain;j++) {
        ci=I->ChainInfo+j;
        if(ci->chainid==q[0]) {
          ci->ComponentInfo=comi;
          comi->numChain++;
          chainFound=1;
          break;
        }
      }
      if(!chainFound) {
        sprintf(msg,"Unexpected chain id (%c) not found in (%s).\n",q[0],I->pdbid);
        PWarning(msg);
      }
    }
  }

  // STEP 3: Assign the tax_id from source from CLUSTER file
  // STEP 4: Explain the Header part into function
}
