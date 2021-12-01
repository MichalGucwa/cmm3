#include "csymlib.h"


CCP4SPG *ccp4spg_load_by_standard_num(const int numspg) 
{ 
  return ccp4spg_load_spacegroup(numspg, 0, NULL, NULL, 0, NULL);
}

CCP4SPG *ccp4spg_load_by_ccp4_num(const int ccp4numspg) 
{ 
  return ccp4spg_load_spacegroup(0, ccp4numspg, NULL, NULL, 0, NULL);
}

CCP4SPG *ccp4spg_load_by_spgname(const char *spgname) 
{ 
  return ccp4spg_load_spacegroup(0, 0, spgname, NULL, 0, NULL);
}

CCP4SPG *ccp4spg_load_by_ccp4_spgname(const char *ccp4spgname) 
{ 
  return ccp4spg_load_spacegroup(0, 0, NULL, ccp4spgname, 0, NULL);
}

CCP4SPG *ccp4_spgrp_reverse_lookup(const int nsym1, const ccp4_symop *op1)
{
  return ccp4spg_load_spacegroup(0, 0, NULL, NULL, nsym1, op1);
}

CCP4SPG *ccp4spg_load_spacegroup(const int numspg, const int ccp4numspg,
         const char *spgname, const char *ccp4spgname, 
         const int nsym1, const ccp4_symop *op1) 
{ CCP4SPG *spacegroup;
  char msg[FileLineLength];
  int i,j,k,l,debug=0,nsym2,symops_provided=0,ierr,ilaue,keyFlag,sgFound,nlaue;
  float sg_chb[4][4],limits[2],rot1[4][4],rot2[4][4],det;
  FILE *filein;
  char *buffer;
  char *p,q[FileLineLength];
  char *envhome=NULL;
  char *symopfile, *ccp4dir, filerec[80];
  ccp4_symop *op2,*op3,opinv;

  static int reported_syminfo = 0;       /* report location of SYMINFO first time only */

  /* spacegroup variables */
  int sg_num, sg_ccp4_num, sg_nsymp, sg_num_cent;
  float cent_ops[4][4];
  char sg_symbol_old[20],sg_symbol_Hall[40],sg_symbol_xHM[20],
       sg_point_group[20],sg_patt_group[40];
  char sg_basisop[80],sg_symop[192][80],sg_cenop[4][80];
  char sg_asu_descr[80], map_asu_x[12], map_asu_y[12], map_asu_z[12];    
  char map_asu_ccp4_x[12], map_asu_ccp4_y[12], map_asu_ccp4_z[12]; 

  sg_symbol_old[0] =0;  sg_symbol_Hall[0]=0;    sg_symbol_xHM[0] =0;
  sg_point_group[0]=0;  sg_patt_group[0] =0;
  sg_basisop[0]    =0;  sg_asu_descr[0]  =0;
  map_asu_x[0]     =0;  map_asu_y[0]     =0;    map_asu_z[0]     =0;    
  map_asu_ccp4_x[0]=0;  map_asu_ccp4_y[0]=0;    map_asu_ccp4_z[0]=0; 

  /* initialisations */
  sg_nsymp=0;
  sg_num_cent=0;

  if (nsym1) symops_provided=1;

  AllocP(spacegroup,CCP4SPG,1);

  if (debug) {
    printf(" Entering ccp4spg_load_spacegroup, with arguments %d %d %d \n",
        numspg,ccp4numspg,nsym1);
    if (spgname) printf(" spgname = %s \n",spgname);
    if (ccp4spgname) printf(" ccp4spgname = %s \n",ccp4spgname);
    for (i = 0; i < nsym1; ++i) {
      printf(" %f %f %f \n",op1[i].rot[0][0],op1[i].rot[0][1],op1[i].rot[0][2]);
      printf(" %f %f %f \n",op1[i].rot[1][0],op1[i].rot[1][1],op1[i].rot[1][2]);
      printf(" %f %f %f \n",op1[i].rot[2][0],op1[i].rot[2][1],op1[i].rot[2][2]);
      printf(" %f %f %f \n\n",op1[i].trn[0],op1[i].trn[1],op1[i].trn[2]);
    }
  }

  /* if we are searching with symops, make sure translations are modulo 1 */
  if (symops_provided) {
    AllocP(op3,ccp4_symop,nsym1+1);
    for (i = 0; i < nsym1; ++i) {
     for (k = 0; k < 3; ++k) {
      for (l = 0; l < 3; ++l) {
        op3[i].rot[k][l]=op1[i].rot[k][l];
      }
      op3[i].trn[k] = op1[i].trn[k];
     }
     ccp4spg_norm_trans(&op3[i]);
    }
  }

  /* Open the symop file: */
  envhome=getenv("NEIGHBORHOOD");
  if (envhome == NULL) {
    PFatalError("Please set your environmental variable NEIGHBORHOOD to corresponding path before you can continue...\n");
  } else {
    AllocP(symopfile,char,strlen(envhome)+22);
    strcpy(symopfile, envhome);
    if(symopfile[strlen(symopfile)-1] != '/') strcat(symopfile, "/");
    strcat(symopfile, "lib/syminfo.lib");

    if (!reported_syminfo) {
      printf("\n Spacegroup information obtained from library file: \n");
      printf(" Logical Name: SYMINFO   Filename: %s\n\n",symopfile);
      reported_syminfo = 1;
    }
  }

  filein = fopen(symopfile,"r");
  if (!filein) { ccp4spg_error(CSYMERR_NoSyminfoFile,"CSYMERR_NoSyminfoFile"); }
  free(symopfile);
  buffer=str2cachetextfile(filein);

  p=buffer;
  while(*p) {
    keyFlag=0;
    sgFound=0;
    if(!strncmp(p,"begin_spacegroup",16))    keyFlag=1;
    else if(!strncmp(p,"number ",7))         keyFlag=2;
    else if(!strncmp(p,"basisop",7))         keyFlag=3;
    else if(!strncmp(p,"symbol ccp4",11))    keyFlag=4;
    else if(!strncmp(p,"symbol Hall",11))    keyFlag=5;
    else if(!strncmp(p,"symbol xHM ",11))    keyFlag=6;
    else if(!strncmp(p,"symbol old ",11))    keyFlag=7;
    else if(!strncmp(p,"symbol laue",11))    keyFlag=8;
    else if(!strncmp(p,"symbol patt",11))    keyFlag=9;
    else if(!strncmp(p,"symbol pgrp",11))    keyFlag=10;
    else if(!strncmp(p,"hklasu ccp4",11))    keyFlag=11;
    else if(!strncmp(p,"mapasu ccp4",11))    keyFlag=12;
    else if(!strncmp(p,"mapasu zero",11))    keyFlag=13;
    else if(!strncmp(p,"mapasu nonz",11))    keyFlag=14;
    else if(!strncmp(p,"cheshire",8))        keyFlag=15;
    else if(!strncmp(p,"symop",5))           keyFlag=16;
    else if(!strncmp(p,"cenop",5))           keyFlag=17;
    else if(!strncmp(p,"end_spacegroup",14)) keyFlag=18;
    if(keyFlag>=2 && keyFlag<=17) {
      if     (keyFlag==2  || keyFlag==3 ) p=str2nskip(p,8);
      else if(keyFlag>=4  && keyFlag<=14) p=str2nskip(p,12);
      else if(keyFlag==9                ) p=str2nskip(p,9);
      else if(keyFlag==16 || keyFlag==17) p=str2nskip(p,6);
      str2ncpy(q,p,80);
    }
    if(keyFlag) {
      switch(keyFlag) {
        case 1:  break;
        case 2:  if(sscanf(q,"%d",&sg_num)!=1)      ccp4spg_error(CSYMERR_SyminfoTokensMissing,"CSYMERR_SyminfoTokensMissing"); break;
        case 3:  if(strlen(q)>=1)                   strcpy(sg_basisop,q);                        break;
        case 4:  if(sscanf(q,"%d",&sg_ccp4_num)!=1) ccp4spg_error(CSYMERR_SyminfoTokensMissing,"CSYMERR_SyminfoTokensMissing"); break;
        case 5:  if(strlen(q)>=1)                   strcpy(sg_symbol_Hall,str2strip(q,"'"));     break;
        case 6:  if(strlen(q)>=1)                   strcpy(sg_symbol_xHM, str2strip(q,"'"));     break;
        case 7:  if(strlen(q)>=1)                   strcpy(sg_symbol_old, str2strip(q,"'"));     break;
        case 8:  
        case 9:  
        case 10: p=str2cskip(p,'\''); p=str2cskip(p,'\''); p=str2cskip(p,'\''); str2ncpy(q,p,80);
                 if(strlen(q)>=1) {
                   if(keyFlag==9)                   strcpy(sg_patt_group, str2strip(q,"'"));
                   else if(keyFlag==10)             strcpy(sg_point_group,str2strip(q,"'"));
              }; break;
        case 11: if(strlen(q)>=1)                   strcpy(sg_asu_descr,  str2strip(q,"'"));     break;
        case 12: p=str2bskip(p,' '); p=str2ccpy(map_asu_ccp4_x,p,';');
                 p=str2bskip(p,' '); p=str2ccpy(map_asu_ccp4_y,p,';');
                 p=str2bskip(p,' '); p=str2ccpy(map_asu_ccp4_z,p,';');
                 break;
        case 13: p=str2bskip(p,' '); p=str2ccpy(map_asu_x,p,';');
                 p=str2bskip(p,' '); p=str2ccpy(map_asu_y,p,';');
                 p=str2bskip(p,' '); p=str2ccpy(map_asu_z,p,';');
                 break;
        case 14: break;
        case 15: break;
        case 16: if(strlen(q)>=1) strcpy(sg_symop[sg_nsymp++],   q); break;
        case 17: if(strlen(q)>=1) strcpy(sg_cenop[sg_num_cent++],q); break;
        case 18: if(numspg) {
                   if (sg_num == numspg) sgFound=1;
                 } else if(ccp4numspg) {
                   if (sg_ccp4_num == ccp4numspg) sgFound=1;
                 } else if(spgname) {
                   if (ccp4spg_name_equal_to_lib(sg_symbol_xHM,spgname)) sgFound=1;
                 } else if(ccp4spgname) {
                   if (ccp4spg_name_equal_to_lib(sg_symbol_old,ccp4spgname)) sgFound=1;
                   else if (ccp4spg_name_equal_to_lib(sg_symbol_xHM,ccp4spgname)) sgFound=1;
                 } else if(symops_provided) {
                   nsym2 = sg_nsymp*sg_num_cent;
                   if (nsym2 == nsym1) {
                     AllocP(op2,ccp4_symop,nsym2);
                     for (i = 0; i < sg_num_cent; ++i) {
                      symop_to_mat4(sg_cenop[i],sg_cenop[i]+strlen(sg_cenop[i]),cent_ops[0]);
                      for (j = 0; j < sg_nsymp; ++j) {
                       symop_to_mat4(sg_symop[j],sg_symop[j]+strlen(sg_symop[j]),rot2[0]);
                       ccp4_4matmul(rot1,(const float (*)[4])cent_ops,(const float (*)[4])rot2);
                       op2[i*sg_nsymp+j] = mat4_to_rotandtrn((const float (*)[4])rot1);
                       /* combination of primitive and centering operators can 
                          produce translations greater than one. */
                       ccp4spg_norm_trans(&op2[i*sg_nsymp+j]);
                      }
                     }
                     /* op3 are requested operators and op2 are from SYMINFO file */
                     if (ccp4_spgrp_equal(nsym1,op3,nsym2,op2)) {
                       if (debug) printf(" ops match for sg %d ! \n",sg_num);
                       sgFound=1;
                     }
                     free(op2);
                   }
                 }
                 break;
      }
    }
    if(keyFlag==18) {
      if(sgFound) {
        break;
      } else {
        sg_nsymp = 0;
        sg_num_cent = 0;
        sg_symbol_xHM[0]=0;
        sg_symbol_old[0]=0;
      }
    }
    p=str2nextline(p);
  }
  if (symops_provided) free(op3);
  if (debug) printf(" syminfo.lib read successfully into memory \n");
  sprintf(msg," Failed to find spacegroup in SYMINFO! (%s)\n", spgname);
  if (!sg_nsymp) {
    PWarning(msg);
    spacegroup->spg_num = -1;
    spacegroup->spg_ccp4_num = -1;
    spacegroup->nsymop=0;
    return spacegroup;
  }

  /* extract various symbols for spacegroup */
  spacegroup->spg_num = sg_num;
  spacegroup->spg_ccp4_num = sg_ccp4_num;
  strcpy(spacegroup->symbol_Hall,sg_symbol_Hall);
  strcpy(spacegroup->symbol_xHM,sg_symbol_xHM);
  strcpy(spacegroup->symbol_old,sg_symbol_old);
  strcpy(spacegroup->point_group,"PG");
  strcpy(spacegroup->point_group+2,sg_point_group);

  if (debug) printf(" Read in details of spacegroup %d %d <%s> PG%s\n",sg_num,sg_ccp4_num,sg_symbol_xHM,sg_point_group);

  /* change of basis */
  if (debug) printf(" Change of basis %s \n",sg_basisop);
  symop_to_mat4(sg_basisop,sg_basisop+strlen(sg_basisop),sg_chb[0]);
  for (i = 0; i < 3; ++i) {
   for (j = 0; j < 3; ++j) {
    spacegroup->chb[i][j] = sg_chb[i][j];
   }
  }
  if (debug)
    for (k = 0; k < 3; ++k) 
      printf("chb: %f %f %f\n",spacegroup->chb[k][0], spacegroup->chb[k][1],spacegroup->chb[k][2]);

  /* symmetry operators */
  spacegroup->nsymop_prim = sg_nsymp;
  spacegroup->nsymop = sg_nsymp*sg_num_cent;
  AllocP(spacegroup->symop,ccp4_symop,spacegroup->nsymop);
  AllocP(spacegroup->invsymop,ccp4_symop,spacegroup->nsymop);
  if (symops_provided) {
   for (i = 0; i < nsym1; ++i) {
    opinv = ccp4_symop_invert(op1[i]);
    for (k = 0; k < 3; ++k) {
      for (l = 0; l < 3; ++l) {
        spacegroup->symop[i].rot[k][l]=op1[i].rot[k][l];
        spacegroup->invsymop[i].rot[k][l]=opinv.rot[k][l];
      }
      spacegroup->symop[i].trn[k] = op1[i].trn[k];
      spacegroup->invsymop[i].trn[k] = opinv.trn[k];
    }
   }
  } else {
   for (i = 0; i < sg_num_cent; ++i) {
    symop_to_mat4(sg_cenop[i],sg_cenop[i]+strlen(sg_cenop[i]),cent_ops[0]);
    for (j = 0; j < sg_nsymp; ++j) {
     strncpy(filerec,sg_symop[j],80);   /* symop_to_mat4 overwrites later sg_symop */
     symop_to_mat4(filerec,filerec+strlen(filerec),rot2[0]);
     ccp4_4matmul(rot1,(const float (*)[4])cent_ops,(const float (*)[4])rot2);
     det=invert4matrix((const float (*)[4])rot1,rot2);
     if (debug) printf("symop determinant: %f\n",det);
     for (k = 0; k < 3; ++k) {
      for (l = 0; l < 3; ++l) {
        spacegroup->symop[i*sg_nsymp+j].rot[k][l]=rot1[k][l];
        spacegroup->invsymop[i*sg_nsymp+j].rot[k][l]=rot2[k][l];
      }
      spacegroup->symop[i*sg_nsymp+j].trn[k] = rot1[k][3];
      spacegroup->invsymop[i*sg_nsymp+j].trn[k] = rot2[k][3];
     }
     /* unless symops have been provided, store normalised operators */
     ccp4spg_norm_trans(&spacegroup->symop[i*sg_nsymp+j]);
     ccp4spg_norm_trans(&spacegroup->invsymop[i*sg_nsymp+j]);
    }
   }
  }
  if (debug) 
   for (i = 0; i < sg_num_cent; ++i) 
    for (j = 0; j < sg_nsymp; ++j) {
     for (k = 0; k < 3; ++k) 
      printf("rot/trn: %f %f %f %f\n",spacegroup->symop[i*sg_nsymp+j].rot[k][0],
           spacegroup->symop[i*sg_nsymp+j].rot[k][1],
           spacegroup->symop[i*sg_nsymp+j].rot[k][2],
           spacegroup->symop[i*sg_nsymp+j].trn[k]);
     for (k = 0; k < 3; ++k) 
      printf("inv rot/trn: %f %f %f %f\n",spacegroup->invsymop[i*sg_nsymp+j].rot[k][0],
           spacegroup->invsymop[i*sg_nsymp+j].rot[k][1],
           spacegroup->invsymop[i*sg_nsymp+j].rot[k][2],
           spacegroup->invsymop[i*sg_nsymp+j].trn[k]);
    }

  /* reciprocal asymmetric unit */
  strcpy(spacegroup->asu_descr,sg_asu_descr);

  /* Select ASU function (referred to default basis) from asu desc */
  /* Also infer Laue and Patterson groups. This uses additional
     information from spacegroup name. In general, we use Hall symbol
     because syminfo.lib is missing a few xHM symbols. However, we
     need to use the latter for R vs. H settings. */
  ierr  = 1;
  ilaue = 1;
  nlaue = 0;
  if     (!strcmp(sg_asu_descr,"l>0 or (l==0 and (h>0 or (h==0 and k>=0)))"))   nlaue=3;  
  else if(!strcmp(sg_asu_descr,"k>=0 and (l>0 or (l=0 and h>=0))"))             nlaue=4;  
  else if(!strcmp(sg_asu_descr,"h>=0 and k>=0 and l>=0"))                       nlaue=6;  
  else if(!strcmp(sg_asu_descr,"l>=0 and ((h>=0 and k>0) or (h=0 and k=0))") &&
          !strcmp(sg_patt_group,"4/m"))                                         nlaue=7;  
  else if(!strcmp(sg_asu_descr,"h>=k and k>=0 and l>=0")                     &&
          !strcmp(sg_patt_group,"4/mmm"))                                       nlaue=8;  
  else if(!strcmp(sg_asu_descr,"(h>=0 and k>0) or (h=0 and k=0 and l>=0)"))     nlaue=9;  
  else if(!strcmp(sg_asu_descr,"h>=k and k>=0 and (k>0 or l>=0)"))              nlaue=10; 
  else if(!strcmp(sg_asu_descr,"h>=k and k>=0 and (h>k or l>=0)"))              nlaue=11; 
  else if(!strcmp(sg_asu_descr,"l>=0 and ((h>=0 and k>0) or (h=0 and k=0))") &&
          !strcmp(sg_patt_group,"6/m"))                                         nlaue=12; 
  else if(!strcmp(sg_asu_descr,"h>=k and k>=0 and l>=0")                     &&
          !strcmp(sg_patt_group,"6/mmm"))                                       nlaue=13; 
  else if(!strcmp(sg_asu_descr,"h>=0 and ((l>=h and k>h) or (l=h and k=h))"))   nlaue=14; 
  else if(!strcmp(sg_asu_descr,"k>=l and l>=h and h>=0"))                       nlaue=15; 
  if(nlaue) {
    ilaue=ccp4spg_load_laue(spacegroup,nlaue);
    ierr =ccp4spg_load_patt(spacegroup,nlaue);
  }

  /* Raise an error if failed to match the ASU description */
  if (ierr) ccp4spg_error(CSYMERR_NoAsuDefined,"CSYMERR_NoAsuDefined");

  /* Raise an error if failed to match the Laue code */
  if (ilaue) ccp4spg_error(CSYMERR_NoLaueCodeDefined,"CSYMERR_NoLaueCodeDefined");

  /* real asymmetric unit */
  /* origin-based choice */
  sprintf(spacegroup->mapasu_zero_descr,"%s %s %s",map_asu_x,map_asu_y,map_asu_z);
  range_to_limits(map_asu_x, limits);
  spacegroup->mapasu_zero[0] = limits[1];
  range_to_limits(map_asu_y, limits);
  spacegroup->mapasu_zero[1] = limits[1];
  range_to_limits(map_asu_z, limits);
  spacegroup->mapasu_zero[2] = limits[1];
  /* CCP4 choice a la SETLIM - defaults to origin-based choice */
  range_to_limits(map_asu_ccp4_x, limits);
  if (limits[1] > 0) {
    sprintf(spacegroup->mapasu_ccp4_descr,"%s %s %s",map_asu_ccp4_x,map_asu_ccp4_y,map_asu_ccp4_z);
    spacegroup->mapasu_ccp4[0] = limits[1];
    range_to_limits(map_asu_ccp4_y, limits);
    spacegroup->mapasu_ccp4[1] = limits[1];
    range_to_limits(map_asu_ccp4_z, limits);
    spacegroup->mapasu_ccp4[2] = limits[1];
  } else {
    strcpy(spacegroup->mapasu_ccp4_descr,spacegroup->mapasu_zero_descr);
    spacegroup->mapasu_ccp4[0] = spacegroup->mapasu_zero[0];
    spacegroup->mapasu_ccp4[1] = spacegroup->mapasu_zero[1];
    spacegroup->mapasu_ccp4[2] = spacegroup->mapasu_zero[2];
  }
  if (debug) {
    printf(" mapasu limits %f %f %f \n",spacegroup->mapasu_zero[0],
	   spacegroup->mapasu_zero[1],spacegroup->mapasu_zero[2]);
    printf(" CCP4 mapasu limits %f %f %f \n",spacegroup->mapasu_ccp4[0],
	   spacegroup->mapasu_ccp4[1],spacegroup->mapasu_ccp4[2]);
  }

  /* set up centric and epsilon zones for this spacegroup */
  ccp4spg_set_centric_zones(spacegroup);
  ccp4spg_set_epsilon_zones(spacegroup);

  if (debug) printf(" Leaving ccp4spg_load_spacegroup \n");

  return spacegroup;
}

int ccp4spg_load_laue(CCP4SPG *spacegroup, const int nlaue) {
  int ierr=0;
  int ls0=0,ls1=0,ls2=0;
  switch(nlaue) {
    case 3:  spacegroup->asufn=&ASU_1b;    strcpy(spacegroup->laue_name,"-1");     ls0=2; ls1=2; ls2=2 ; break;
    case 4:  spacegroup->asufn=&ASU_2_m;   strcpy(spacegroup->laue_name,"2/m");    ls0=2; ls1=4; ls2=2 ; break;
    case 5:  spacegroup->asufn=&ASU_2_m;   strcpy(spacegroup->laue_name,"2/m");    ls0=2; ls1=8; ls2=4 ; break;
    case 6:  spacegroup->asufn=&ASU_mmm;   strcpy(spacegroup->laue_name,"mmm");    ls0=4; ls1=4; ls2=4 ; break;
    case 7:  spacegroup->asufn=&ASU_4_m;   strcpy(spacegroup->laue_name,"4/m");    ls0=4; ls1=4; ls2=8 ; break;
    case 8:  spacegroup->asufn=&ASU_4_mmm; strcpy(spacegroup->laue_name,"4/mmm");  ls0=4; ls1=4; ls2=8 ; break;
    case 9:  spacegroup->asufn=&ASU_3b;    strcpy(spacegroup->laue_name,"-3");     ls0=6; ls1=6; ls2=6 ; break;
    case 10: spacegroup->asufn=&ASU_3bm;   strcpy(spacegroup->laue_name,"3bar1m"); ls0=6; ls1=6; ls2=6 ; break;
    case 11: spacegroup->asufn=&ASU_3bmx;  strcpy(spacegroup->laue_name,"3barm");  ls0=6; ls1=6; ls2=6 ; break;
    case 12: spacegroup->asufn=&ASU_6_m;   strcpy(spacegroup->laue_name,"6/m");    ls0=6; ls1=6; ls2=12; break;
    case 13: spacegroup->asufn=&ASU_6_mmm; strcpy(spacegroup->laue_name,"6/mmm");  ls0=6; ls1=6; ls2=12; break;
    case 14: spacegroup->asufn=&ASU_m3b;   strcpy(spacegroup->laue_name,"m3bar");  ls0=4; ls1=4; ls2=4 ; break;
    case 15: spacegroup->asufn=&ASU_m3bm;  strcpy(spacegroup->laue_name,"m3barm"); ls0=8; ls1=8; ls2=8 ; break;
    default: ierr=1;
             break;
  }
  if(!ierr) {
    spacegroup->nlaue=nlaue;
    spacegroup->laue_sampling[0]=ls0;
    spacegroup->laue_sampling[1]=ls1;
    spacegroup->laue_sampling[2]=ls2;
  }
  return ierr;
}

int ccp4spg_load_patt(CCP4SPG *spacegroup, const int nlaue) {
  int   ierr  = 0;
  int   npatt = 0;
  char* pHall = spacegroup->symbol_Hall;
  char* pxHM  = spacegroup->symbol_xHM;
  switch(nlaue) {
    case 3:                           npatt = 2;   strcpy(spacegroup->patt_name,"P-1");      break;
    case 4:  if (strchr(pHall,'P')) { npatt = 10;  strcpy(spacegroup->patt_name,"P2/m");  }
        else if (strchr(pHall,'C')) { npatt = 12;  strcpy(spacegroup->patt_name,"C2/m");  }; break;
    case 6:  if (strchr(pHall,'P')) { npatt = 47;  strcpy(spacegroup->patt_name,"Pmmm");  }
        else if (strchr(pHall,'C')) { npatt = 65;  strcpy(spacegroup->patt_name,"Cmmm");  }
        else if (strchr(pHall,'I')) { npatt = 71;  strcpy(spacegroup->patt_name,"Immm");  }
        else if (strchr(pHall,'F')) { npatt = 69;  strcpy(spacegroup->patt_name,"Fmmm");  }; break;
    case 7:  if (strchr(pHall,'P')) { npatt = 83;  strcpy(spacegroup->patt_name,"P4/m");  }
        else if (strchr(pHall,'I')) { npatt = 87;  strcpy(spacegroup->patt_name,"I4/m");  }; break;
    case 8:  if (strchr(pHall,'P')) { npatt = 123; strcpy(spacegroup->patt_name,"P4/mmm");}
        else if (strchr(pHall,'I')) { npatt = 139; strcpy(spacegroup->patt_name,"I4/mmm");}; break;
    case 9:  if (strchr(pHall,'P')) { npatt = 147; strcpy(spacegroup->patt_name,"P-3");   }
        else if (strchr(pxHM, 'H')) { npatt = 148; strcpy(spacegroup->patt_name,"H-3");   }
        else if (strchr(pHall,'R')) { npatt = 1148;strcpy(spacegroup->patt_name,"R-3");   }; break;
    case 10:                          npatt = 162; strcpy(spacegroup->patt_name,"P-31m");    break;
    case 11: if (strchr(pHall,'P')) { npatt = 164; strcpy(spacegroup->patt_name,"P-3m1"); }
        else if (strchr(pxHM, 'H')) { npatt = 166; strcpy(spacegroup->patt_name,"H-3m");  }
        else if (strchr(pHall,'R')) { npatt = 1166;strcpy(spacegroup->patt_name,"R-3m");  }; break;
    case 12:                          npatt = 175; strcpy(spacegroup->patt_name,"P6/m");     break;
    case 13:                          npatt = 191; strcpy(spacegroup->patt_name,"P6/mmm");   break;
    case 14: if (strchr(pHall,'P')) { npatt = 200; strcpy(spacegroup->patt_name,"Pm-3");  }
        else if (strchr(pHall,'I')) { npatt = 204; strcpy(spacegroup->patt_name,"Im-3");  }
        else if (strchr(pHall,'F')) { npatt = 202; strcpy(spacegroup->patt_name,"Fm-3");  }; break;
    case 15: if (strchr(pHall,'P')) { npatt = 221; strcpy(spacegroup->patt_name,"Pm-3m"); }
        else if (strchr(pHall,'I')) { npatt = 229; strcpy(spacegroup->patt_name,"Im-3m"); }
        else if (strchr(pHall,'F')) { npatt = 225; strcpy(spacegroup->patt_name,"Fm-3m"); }; break;
    default: ierr=1;                                                                         break;
  }
  if(!ierr) spacegroup->npatt = npatt;
  return ierr;
}

void ccp4spg_error(int error_number, char* error_info) {
  char msg[FileLineLength];
  sprintf(msg,"ccp4spg error: %d: %s.\n",error_number,error_info);
  PFatalError(msg); 
}

void ccp4spg_free(CCP4SPG **sp) {
  free ((*sp)->symop);
  free ((*sp)->invsymop);
  free (*sp);
  *sp=NULL;
}

/* standard asu tests for 12 Laue classes */

int ASU_1b   (const int h, const int k, const int l) { return (l>0 || (l==0 && (h>0 || (h==0 && k>=0)))); }
int ASU_2_m  (const int h, const int k, const int l) { return (k>=0 && (l>0 || (l==0 && h>=0))); }
int ASU_mmm  (const int h, const int k, const int l) { return (h>=0 && k>=0 && l>=0); }
int ASU_4_m  (const int h, const int k, const int l) { return (l>=0 && ((h>=0 && k>0) || (h==0 && k==0))); }
int ASU_4_mmm(const int h, const int k, const int l) { return (h>=k && k>=0 && l>=0); }
int ASU_3b   (const int h, const int k, const int l) { return (h>=0 && k>0) || (h==0 && k==0 && l >= 0); }
int ASU_3bm  (const int h, const int k, const int l) { return (h>=k && k>=0 && (k>0 || l>=0)); }
int ASU_3bmx (const int h, const int k, const int l) { return (h>=k && k>=0 && (h>k || l>=0)); }
int ASU_6_m  (const int h, const int k, const int l) { return (l>=0 && ((h>=0 && k>0) || (h==0 && k==0))); }
int ASU_6_mmm(const int h, const int k, const int l) { return (h>=k && k>=0 && l>=0); }
int ASU_m3b  (const int h, const int k, const int l) { return (h>=0 && ((l>=h && k>h) || (l==h && k==h))); }
int ASU_m3bm (const int h, const int k, const int l) { return (h>=0 && k>=l && l>=h); }

char *ccp4spg_symbol_Hall(CCP4SPG* sp) {
  if (!sp) ccp4spg_error(CSYMERR_NullSpacegroup,"CSYMERR_NullSpacegroup"); 
  return sp->symbol_Hall; 
}

ccp4_symop ccp4_symop_invert( const ccp4_symop op1 )
{
  float rot1[4][4],rot2[4][4];

  rotandtrn_to_mat4(rot1,op1);
  invert4matrix((const float (*)[4])rot1,rot2);
  return (mat4_to_rotandtrn((const float (*)[4])rot2));
}

int ccp4spg_name_equal(const char *spgname1, const char *spgname2) {

  char *ch1, *ch2, *spgname1_upper, *spgname2_upper;

  /* create copies of input strings, and convert to upper case */
  spgname1_upper = strdup(spgname1);
  str2toupper(spgname1_upper,spgname1);
  spgname2_upper = strdup(spgname2);
  str2toupper(spgname2_upper,spgname2);

  ch1 = spgname1_upper;
  ch2 = spgname2_upper;
  while (*ch1 == *ch2) {
    if (*ch1 == '\0' && *ch2 == '\0') {
      free(spgname1_upper);
      free(spgname2_upper);
      return 1;
    }
    ++ch1;
    ++ch2;
  }
  free(spgname1_upper);
  free(spgname2_upper);
  return 0;
}

int ccp4spg_name_equal_to_lib(const char *spgname_lib, const char *spgname_match) {

  char *ch1, *ch2, *spgname1_upper, *spgname2_upper, *tmpstr;
  int have_one_1=0, have_one_2=0;

  /* create copies of input strings, convert to upper case, and
     deal with colons */
  spgname1_upper = strdup(spgname_lib);
  str2toupper(spgname1_upper,spgname_lib);
  ccp4spg_name_de_colon(spgname1_upper);
  spgname2_upper = strdup(spgname_match);
  str2toupper(spgname2_upper,spgname_match);
  ccp4spg_name_de_colon(spgname2_upper);

  /* see if strings are equal, except for spaces */
  ch1 = spgname1_upper;
  ch2 = spgname2_upper;
  while (*ch1 == *ch2) {
    if (*ch1 == '\0' && *ch2 == '\0') {
      free(spgname1_upper);
      free(spgname2_upper);
      return 1;
    }
    while (*(++ch1) == ' ') ;
    while (*(++ch2) == ' ') ;
  }

  /* if that didn't work, and spgname_match is a short name, try removing
     " 1 " from spgname_lib, and matching again. This would match P21 to
     'P 1 21 1' for instance. */

  /* try to identify if "short names" are being used. */
  if (strstr(spgname1_upper," 1 ")) have_one_1 = 1;
  if (strstr(spgname2_upper," 1 ")) have_one_2 = 1; 
  /* if spgname_lib has " 1 " and spgname_match doesn't, then strip
     out " 1" to do "short" comparison */
  if (have_one_1 && ! have_one_2) {
     tmpstr = strdup(spgname1_upper);
     ccp4spg_to_shortname(tmpstr,spgname1_upper);
     strcpy(spgname1_upper,tmpstr);
     free(tmpstr);
  }

  /* see if strings are equal, except for spaces */
  ch1 = spgname1_upper;
  ch2 = spgname2_upper;
  while (*ch1 == *ch2) {
    if (*ch1 == '\0' && *ch2 == '\0') {
      free(spgname1_upper);
      free(spgname2_upper);
      return 1;
    }
    while (*(++ch1) == ' ') ;
    while (*(++ch2) == ' ') ;
  }

  free(spgname1_upper);
  free(spgname2_upper);
  return 0;
}

char *ccp4spg_to_shortname(char *shortname, const char *longname) {

  const char *ch1;
  char *ch2;
  int trigonal=0;

  ch1 = longname;
  ch2 = shortname;

  /* "P 1" is an exception */
  if (!strcmp(ch1,"P 1")) {
    strcpy(ch2,"P1");
    return  ch2;
  }

  /* trigonal are another exception, don't want to lose significant " 1" */
  if (!strncmp(ch1,"P 3",3) || !strncmp(ch1,"P -3",4) || !strncmp(ch1,"R 3",3) || !strncmp(ch1,"R -3",4)) trigonal=1;

  while (*ch1 != '\0') {
    if (!trigonal && !strncmp(ch1," 1",2)) {
      ch1 += 2;
    } else {
      /* take out blanks - note check for " 1" takes precedence */
      while (*ch1 == ' ') ++ch1;
      if (*ch1 != '\0') { *ch2 = *ch1; ++ch2; ++ch1; }
    }
  }
  *ch2 = '\0';
  return ch2;
}

void ccp4spg_name_de_colon(char *name) {

  char *ch1;

  /* various spacegroup names have settings specified by colon. We'll
     deal with these on a case-by-case basis. */
  if (ch1 = strstr(name,":R")) {
  /* :R spacegroup should be R already so just replace with blanks */
    *ch1 = ' ';
    *(ch1+1) = ' ';
  } else if (ch1 = strstr(name,":H")) {
  /* :H spacegroup should be R so change to H */
    *ch1 = ' ';
    *(ch1+1) = ' ';
    ch1 = strstr(name,"R");
    if (ch1 != NULL) *ch1 = 'H';
  }
    
  return;
}

int ccp4spg_pgname_equal(const char *pgname1, const char *pgname2) {

  char *ch1, *ch2, *pgname1_upper, *pgname2_upper;

  pgname1_upper = strdup(pgname1);
  str2toupper(pgname1_upper,pgname1);
  pgname2_upper = strdup(pgname2);
  str2toupper(pgname2_upper,pgname2);

  ch1 = pgname1_upper;
  if (pgname1_upper[0] == 'P' && pgname1_upper[1] == 'G') ch1 += 2;
  ch2 = pgname2_upper;
  if (pgname2_upper[0] == 'P' && pgname2_upper[1] == 'G') ch2 += 2;
  while (*ch1 == *ch2) {
    if (*ch1 == '\0' && *ch2 == '\0') {
      free(pgname1_upper);
      free(pgname2_upper);
      return 1;
    }
    while (*(++ch1) == ' ') ;
    while (*(++ch2) == ' ') ;
  }
  free(pgname1_upper);
  free(pgname2_upper);
  return 0;
}

ccp4_symop *ccp4spg_norm_trans(ccp4_symop *op) {

  int i;

  for ( i = 0; i < 3; i++ ) {
    while (op->trn[i] < 0.0) op->trn[i] += 1.0;
    while (op->trn[i] >= 1.0) op->trn[i] -= 1.0;
  }

  return op;
}

int ccp4_spgrp_equal( int nsym1, const ccp4_symop *op1, int nsym2, const ccp4_symop *op2 )
{
  int i, n;
  int *symcode1, *symcode2;

  /* first check that we have equal number of symops */
  if ( nsym1 != nsym2 ) return 0;

  n = nsym1;

  /* now make the sym code arrays */
  AllocP(symcode1,int,n+1);
  AllocP(symcode2,int,n+1);
  for ( i = 0; i < n; i++ ) {
    symcode1[i] = ccp4_symop_code( op1[i] );
    symcode2[i] = ccp4_symop_code( op2[i] );
  }
  /* sort the symcodes */
  /* Kevin suggests maybe just compare all pairs rather than sort */
  qsort( symcode1, n, sizeof(int), &ccp4_int_compare );
  qsort( symcode2, n, sizeof(int), &ccp4_int_compare );
  /* compare the symcodes */
  for ( i = 0; i < n; i++ ) {
    if ( symcode1[i] != symcode2[i] ) break;
  }
  /* delete the symcodes */
  free(symcode1);
  free(symcode2);

  /* return true if they are equal */
  return ( i == n );
}

int ccp4_spgrp_equal_order( int nsym1, const ccp4_symop *op1, int nsym2, const ccp4_symop *op2 )
{
  int i;

  /* first check that we have equal number of symops */
  if ( nsym1 != nsym2 ) return 0;

  /* compare the symcodes */
  for ( i = 0; i < nsym1; i++ ) {
    if ( ccp4_symop_code( op1[i] ) != ccp4_symop_code( op2[i] ) ) break;
  }

  /* return true if they are equal */
  return ( i == nsym1 );
}

int ccp4_symop_code(ccp4_symop op)
{
  int i, j, code=0;
  for ( i=0; i<3; i++ )
    for ( j=0; j<3; j++ )
      code = ( code << 2 ) | ( (int) rint( op.rot[i][j] ) & 0x03 ) ;
  for ( i=0; i<3; i++ )
    code = ( code << 4 ) | ( (int) rint( op.trn[i]*12.0 ) & 0x0f ) ;
  return code;
}

int ccp4_int_compare( const void *p1, const void *p2 )
{
  return ( *((int*)p1) - *((int*)p2) );
}

void ccp4spg_set_centric_zones(CCP4SPG* sp) {

  int i,j,hnew,knew,lnew;
  int ihkl[12][3];

  if (!sp) ccp4spg_error(CSYMERR_NullSpacegroup,"CSYMERR_NullSpacegroup");

  ihkl[0][0] = 0; ihkl[0][1] = 1; ihkl[0][2] = 2; 
  ihkl[1][0] = 1; ihkl[1][1] = 0; ihkl[1][2] = 2; 
  ihkl[2][0] = 1; ihkl[2][1] = 2; ihkl[2][2] = 0; 
  ihkl[3][0] = 1; ihkl[3][1] = 1; ihkl[3][2] = 10; 
  ihkl[4][0] = 1; ihkl[4][1] = 10; ihkl[4][2] = 1; 
  ihkl[5][0] = 10; ihkl[5][1] = 1; ihkl[5][2] = 1; 
  ihkl[6][0] = 1; ihkl[6][1] = -1; ihkl[6][2] = 10; 
  ihkl[7][0] = 1; ihkl[7][1] = 10; ihkl[7][2] = -1; 
  ihkl[8][0] = 10; ihkl[8][1] = 1; ihkl[8][2] = -1; 
  ihkl[9][0] = -1; ihkl[9][1] = 2; ihkl[9][2] = 10; 
  ihkl[10][0] = 2; ihkl[10][1] = -1; ihkl[10][2] = 10; 
  ihkl[11][0] = 1; ihkl[11][1] = 4; ihkl[11][2] = 8; 

  /* loop over all possible centric zones */
  for (i = 0; i < 12; ++i) {
   sp->centrics[i] = 0;
   for (j = 0; j < sp->nsymop; ++j) {
    hnew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][0] + 
      ihkl[i][1]*sp->symop[j].rot[1][0] + ihkl[i][2]*sp->symop[j].rot[2][0] );
    if (hnew == -ihkl[i][0]) {
     knew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][1] + 
       ihkl[i][1]*sp->symop[j].rot[1][1] + ihkl[i][2]*sp->symop[j].rot[2][1] );
     if (knew == -ihkl[i][1]) {
      lnew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][2] + 
        ihkl[i][1]*sp->symop[j].rot[1][2] + ihkl[i][2]*sp->symop[j].rot[2][2] );
      if (lnew == -ihkl[i][2]) {
        sp->centrics[i] = j+1;
        break;
      }
     }
    }
   }
  }
}

void ccp4spg_set_epsilon_zones(CCP4SPG* sp) {

  int i,j,hnew,knew,lnew,neps;
  int ihkl[13][3];

  if (!sp) ccp4spg_error(CSYMERR_NullSpacegroup,"CSYMERR_NullSpacegroup");

  ihkl[0][0] = 1; ihkl[0][1] = 0; ihkl[0][2] = 0; 
  ihkl[1][0] = 0; ihkl[1][1] = 2; ihkl[1][2] = 0; 
  ihkl[2][0] = 0; ihkl[2][1] = 0; ihkl[2][2] = 2; 
  ihkl[3][0] = 1; ihkl[3][1] = 1; ihkl[3][2] = 0; 
  ihkl[4][0] = 1; ihkl[4][1] = 0; ihkl[4][2] = 1; 
  ihkl[5][0] = 0; ihkl[5][1] = 1; ihkl[5][2] = 1; 
  ihkl[6][0] = 1; ihkl[6][1] = -1; ihkl[6][2] = 0; 
  ihkl[7][0] = 1; ihkl[7][1] = 0; ihkl[7][2] = -1; 
  ihkl[8][0] = 0; ihkl[8][1] = 1; ihkl[8][2] = -1; 
  ihkl[9][0] = -1; ihkl[9][1] = 2; ihkl[9][2] = 0; 
  ihkl[10][0] = 2; ihkl[10][1] = -1; ihkl[10][2] = 0; 
  ihkl[11][0] = 1; ihkl[11][1] = 1; ihkl[11][2] = 1; 
  ihkl[12][0] = 1; ihkl[12][1] = 2; ihkl[12][2] = 3; 

  /* Loop over all possible epsilon zones, except the catch-all 13th. For each 
     zone, "neps" counts the number of symmetry operators that map a representative
     reflection "ihkl" to itself. At least the identity will do this. If any
     more do, then this is a relevant epsilon zone. */
  for (i = 0; i < 12; ++i) {
   sp->epsilon[i] = 0;
   neps = 0;
   for (j = 0; j < sp->nsymop_prim; ++j) {
    hnew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][0] + 
      ihkl[i][1]*sp->symop[j].rot[1][0] + ihkl[i][2]*sp->symop[j].rot[2][0] );
    if (hnew == ihkl[i][0]) {
     knew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][1] + 
       ihkl[i][1]*sp->symop[j].rot[1][1] + ihkl[i][2]*sp->symop[j].rot[2][1] );
     if (knew == ihkl[i][1]) {
      lnew = (int) rint( ihkl[i][0]*sp->symop[j].rot[0][2] + 
        ihkl[i][1]*sp->symop[j].rot[1][2] + ihkl[i][2]*sp->symop[j].rot[2][2] );
      if (lnew == ihkl[i][2]) {
        ++neps;
      }
     }
    }
   }
   if (neps > 1) sp->epsilon[i] = neps * (sp->nsymop/sp->nsymop_prim);
  }
  /* hkl zone covers all with neps of 1 */
  sp->epsilon[12] = sp->nsymop/sp->nsymop_prim;
}

int range_to_limits(const char *range, float limits[2])
{
  int i,in_value=1,neg=0,frac=0,equal=0;
  float value1,value2;
  float delta=0.00001;
  char ch;
  char buf[2];
  buf[1] = 0;

  for (i = 0 ; i < strlen(range) ; ++i) {
    ch = range[i];
    if (ch == '<') {
      if (in_value) {
	/* finishing lower value */
        limits[0] = value1;
        if (frac) limits[0] = value1/value2;
        if (neg) limits[0] = - limits[0];
        limits[0] += delta;
        neg = 0;
        frac = 0;
        in_value = 0;
      } else {
	/* starting upper value */

        in_value = 1;
      }
    } else if (ch == '-') {
      neg = 1;
    } else if (ch == '/') {
      frac = 1;
    } else if (ch == '=') {
      if (in_value) {
        equal = 1;
      } else {
        limits[0] -= 2.0*delta;        
      }
    } else if (ch == ';' || ch == ' ') {
      ;
    } else {
      if (in_value) {
	buf[0] = ch;
        if (frac) {
          value2 = (float) atoi(buf);
        } else {
          value1 = (float) atoi(buf);
        }
      }
    }
  } 
  /* finishing upper value */
  limits[1] = value1;
  if (frac) limits[1] = value1/value2;
  if (neg) limits[1] = - limits[1];
  limits[1] -= delta;
  if (equal) limits[1] += 2.0*delta;        

  return 0;
}

ccp4_symop symop_to_rotandtrn(const char *symchs_begin, const char *symchs_end) {

  float rsm[4][4];

  symop_to_mat4(symchs_begin, symchs_end, rsm[0]);
  return (mat4_to_rotandtrn((const float (*)[4])rsm));

}

/*------------------------------------------------------------------*/

/* symop_to_mat4

   Translates a single symmetry operator string into a 4x4 quine
   matrix representation
   NB Uses a utility function (symop_to_mat4_err) when reporting
   failures.

   Syntax of possible symop strings:

   real space symmetry operations, e.g. X+1/2,Y-X,Z
   reciprocal space operations,    e.g. h,l-h,-k
   reciprocal axis vectors,        e.g. a*+c*,c*,-b*
   real space axis vectors,        e.g. a,c-a,-b

   The strings can contain spaces, and the coordinate and translation
   parts may be in either order.

   The function returns 1 on success, 0 if there was a failure to
   generate a matrix representation.
*/
const char *symop_to_mat4(const char *symchs_begin, const char *symchs_end, float *rot)
{
  int no_real =0, no_recip = 0, no_axis = 0;          /* counters */
  int col = 3, nops = 0;
  int nsym = 0, init_array = 1;
  float sign = 1.0f, value = 0.0f, value2;
  char *cp, ch;
  const char *ptr_symchs = symchs_begin;
  int j,k;                                 /* loop variables */
  int Isep = 0;                             /* parsed seperator? */

  while (ptr_symchs < symchs_end) {
    ch = *ptr_symchs;

    /* Parse symop */
    if (isspace(ch)) {
      /* Have to allow symop strings to contain spaces for
	 compatibility with older MTZ files
	 Ignore and step on to next character */
      ++ptr_symchs;
      continue;
    } else if (ch == ',' || ch == '*') {           
      ++ptr_symchs;
      if (value == 0.0f && col == 3) {
        /* nothing set, this is a problem */
        ccp4spg_error(CPARSERR_SymopToMat,"CPARSERR_SymopToMat");
      } else {
        Isep = 1;     /* drop through to evaluation*/
      }
    } else if (ch == 'X' || ch == 'x') {
      no_real++, col = 0;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'Y' || ch == 'y') {
      no_real++, col = 1;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'Z' || ch == 'z') {
      no_real++, col = 2;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'H' || ch == 'h') {
      no_recip++, col = 0;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'K' || ch == 'k') {
      no_recip++, col = 1;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'L' || ch == 'l') {
      no_recip++, col = 2;
      if (value == 0.0f) value = sign * 1.0f;
      ++ptr_symchs;
      continue;
    } else if (ch == 'A' || ch == 'a') {
      no_axis++, col = 0;
      if (value == 0.0f) value = sign * 1.0f;
      if (*++ptr_symchs == '*' && ( no_axis != 3 || no_recip )) ++ptr_symchs;
      continue;
    } else if (ch == 'B' || ch == 'b') {
      no_axis++, col = 1;
      if (value == 0.0f) value = sign * 1.0f;
      if (*++ptr_symchs == '*' && ( no_axis != 3 || no_recip )) ++ptr_symchs;
      continue;
    } else if (ch == 'C' || ch == 'c') {
      no_axis++, col = 2;
      if (value == 0.0f) value = sign * 1.0f;
      if (*++ptr_symchs == '*' && ( no_axis != 3 || no_recip )) ++ptr_symchs;
      continue;
    } else if (ch == '+' || ch == '-') {
      sign = ((ch == '+')? 1.0f : -1.0f) ;
      ++ptr_symchs;
      if ( value == 0.0f && col == 3) 
	continue;
      /* drop through to evaluation */
    } else if ( ch == '/') {
      ++ptr_symchs;
      if (value == 0.0f) {
	/* error */
	symop_to_mat4_err(symchs_begin);
	return NULL;
      }
      value2 = strtod(ptr_symchs, &cp);
      if (!value2) {
	/* error */
	symop_to_mat4_err(symchs_begin);
	return NULL;
      }
      /* Nb don't apply the sign to value here
	 It will already have been applied in the previous round */
      value = (float) value/value2;
      ptr_symchs = cp;
      continue;
    } else if ( isdigit(ch) || ch == '.') {
      value = sign*strtod(ptr_symchs, &cp);
      ptr_symchs = cp;
      continue;
    } else {
      ++ptr_symchs;
      continue;
    }
   
  /* initialise and clear the relevant array  (init_array == 1)*/
  /* use knowledge that we are using a [4][4] for rot */
  if (init_array) {
    init_array = 0;       
    for (j = 0 ; j !=4 ; ++j)
      for (k = 0; k !=4 ; ++k)
        rot[(((nsym << 2) + k ) << 2) +j] = 0.0f;
     rot[(((nsym << 2 ) + 3 )  << 2) +3] = 1.0f;
  }
 
    /* value to be entered in rot */
    rot[(((nsym << 2) + nops) << 2) + col] = value;

    /* have we passed a operator seperator */
    if (Isep) {
      Isep = 0;
      ++nops;
      sign = 1.0f;
      if (nops == 3 ) { ++nsym; nops=0 ; init_array = 1; }
    }

    /* reset for next cycle */
    col = 3;
    value = 0.0f;
    no_recip = 0, no_axis = 0, no_real = 0;
  }

  /* Tidy up last value */
  if (value) rot[(((nsym << 2) + nops) << 2) + col] = value;

  if (nops<2) {
    /* Processed fewer than 3 operators, raise an error */
    symop_to_mat4_err(symchs_begin);
    return NULL;
  }

  /* Return with success */
  return ptr_symchs;
}

/* Internal function: report error from symop_to_mat4_err */
int symop_to_mat4_err(const char *symop)
{
  printf("\n **SYMMETRY OPERATOR ERROR**\n\n Error in interpreting symop \"%s\"\n\n",
	 symop);
  ccp4spg_error(CPARSERR_SymopToMat,"CPARSERR_SymopToMat");
  return 1;
}

ccp4_symop mat4_to_rotandtrn(const float rsm[4][4]) {

  int i,j;
  ccp4_symop symop;

  for (i = 0; i < 3; ++i) {
    for (j = 0; j < 3; ++j) 
      symop.rot[i][j]=rsm[i][j];
    symop.trn[i]=rsm[i][3];
  }

  return (symop);
}

char *rotandtrn_to_symop(char *symchs_begin, char *symchs_end, const ccp4_symop symop)
{
  float rsm[4][4];

  rotandtrn_to_mat4(rsm,symop);
  return(mat4_to_symop(symchs_begin,symchs_end,(const float (*)[4])rsm));
}

void rotandtrn_to_mat4(float rsm[4][4], const ccp4_symop symop) {

  int i,j;

  for (i = 0; i < 3; ++i) {
    for (j = 0; j < 3; ++j) 
      rsm[i][j]=symop.rot[i][j];
    rsm[i][3]=symop.trn[i];
    rsm[3][i]=0.0;
  }
  rsm[3][3]=1.0;
}

char *mat4_to_symop(char *symchs_begin, char *symchs_end, const float rsm[4][4])
{
  static char axiscr[] = {'X','Y','Z'};
  static char numb[] = {'0','1','2','3','4','5','6','7','8','9'};
  static int npntr1[12] = { 0,1,1,1,0,1,0,2,3,5,0,0 };
  static int npntr2[12] = { 0,6,4,3,0,2,0,3,4,6,0,0 };

  int jdo10, jdo20, irsm, itr, ist;
  register char *ich;
  int debug=0;

  if (debug)
    for (jdo20 = 0; jdo20 != 4; ++jdo20) 
      printf("Input matrix: %f %f %f %f \n",rsm[jdo20][0],rsm[jdo20][1],
          rsm[jdo20][2],rsm[jdo20][3]);

  /* blank output string */
  for (ich = symchs_begin; ich < symchs_end; ++ich) 
    *ich = ' ';
  ich = symchs_begin;

  for (jdo20 = 0; jdo20 != 3; ++jdo20) {
    *ich = '0';
    ist = 0;    /* ---- Ist is flag for first character of operator */
    for (jdo10 = 0; jdo10 != 4; ++jdo10) {
      
      if (rsm[jdo20][jdo10] != 0.f) {
	irsm = (int) rint(fabs(rsm[jdo20][jdo10]));
	
	if ( rsm[jdo20][jdo10] > 0. && ist) {
	  if (ich >= symchs_end) ccp4spg_error(CPARSERR_MatToSymop, "CPARSERR_MatToSymop");
	  *ich++ = '+';
	} else if ( rsm[jdo20][jdo10] < 0.f ) {
	  if (ich >= symchs_end) ccp4spg_error(CPARSERR_MatToSymop, "CPARSERR_MatToSymop");
	  if (jdo10 != 3) {
	    *ich++ = '-';
	  } else {
	    /* translation part is forced to be positive, see below */
	    *ich++ = '+';
	  }
          ist = 1;
	}
      
	if (jdo10 != 3) {
	  /* rotation part */
	  if (ich+1 >= symchs_end) ccp4spg_error(CPARSERR_MatToSymop, "CPARSERR_MatToSymop");
	  if (irsm != 1) {
	    *ich++ = numb[irsm];
	    *ich++ = axiscr[jdo10];
	  } else {
	    *ich++ = axiscr[jdo10];
	  }
	  ist = 1;
        } else {
	  /* translation part */
	  itr = (int) rint(rsm[jdo20][3]*12.0);
          while (itr < 0) itr += 12;
          itr = (itr - 1) % 12;
          if (npntr1[itr] > 0) {
	   if (ich+2 >= symchs_end) ccp4spg_error(CPARSERR_MatToSymop, "CPARSERR_MatToSymop");
	   *ich++ = numb[npntr1[itr]];
	   *ich++ = '/';
           *ich++ = numb[npntr2[itr]];
	  } else {
           *--ich = ' ';
	  }
	}
      }
    }
    if (jdo20 != 2) {
      if (*ich == '0')
        ++ich;
      if (ich+2 >= symchs_end) ccp4spg_error(CPARSERR_MatToSymop, "CPARSERR_MatToSymop");
      *ich++ = ',';
      *ich++ = ' ';
      *ich++ = ' ';
    }
  }
  return symchs_begin;
}

char *mat4_to_recip_symop(char *symchs_begin, char *symchs_end, const float rsm[4][4])
{
  char *symop;
  size_t lsymop;
  register char *ich, *ich_out;

  lsymop = symchs_end-symchs_begin;
  AllocP(symop,char,lsymop);

  mat4_to_symop(symop, symop+lsymop, rsm);
  ich_out = symchs_begin;
  for (ich = symop; ich < symop+lsymop; ++ich) {
    if (*ich == 'X') {
      if (ich_out == symchs_begin || (ich_out > symchs_begin && 
          *(ich_out-1) != '-' && *(ich_out-1) != '+')) *ich_out++ = '+';
      *ich_out++ = 'h';
    } else if (*ich == 'Y') {
      if (ich_out == symchs_begin || (ich_out > symchs_begin && 
          *(ich_out-1) != '-' && *(ich_out-1) != '+')) *ich_out++ = '+';
      *ich_out++ = 'k';
    } else if (*ich == 'Z') {
      if (ich_out == symchs_begin || (ich_out > symchs_begin && 
          *(ich_out-1) != '-' && *(ich_out-1) != '+')) *ich_out++ = '+';
      *ich_out++ = 'l';
    } else if (*ich == ' ') {
      /* skip */
    } else {
      *ich_out++ = *ich;
    }
  }
  while (ich_out < symchs_end) *ich_out++ = ' ';

  free (symop);
  return symchs_begin;
}
