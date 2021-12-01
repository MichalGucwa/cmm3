#include "AtomInfo.h"

int AtomInfoIsElement(char a, char b) {
  /* return codesd definition:
   * 4: correct element name, no further check
   * 3: a little bit uncertain, but still not need further check
   * 2: Whether it is an element depends on residue name (either residue code, or
   *    valid ligand-depot entry molecule formula contains the element name).
   * 1: Not a element name, unless match exactly the residue name
   * 0: Not a valid chemical element at all */
  switch(b) {
    case 0:   if(index("CONHSPBDFIKQTUVWYconhspbdfikqtuvwy",a))
                                        {return 4;};            break;
    case 'C': if(index("STst",a))       {return 3;}
              else if(index("Aa",a))    {return 1;};            break;
    case 'O': if(index("Mm",a))         {return 4;}
              else if(index("HNhn",a))  {return 3;}
              else if(index("Cc",a))    {return 2;}
              else if(index("Pp",a))    {return 1;};            break;
    case 'N': if(index("MZmz",a))       {return 4;}
              else if(index("SRsr",a))  {return 3;}
              else if(index("Ii",a))    {return 2;};            break;
    case 'H': if(index("Tt",a))         {return 3;}
              else if(index("Rr",a))    {return 2;}
              else if(index("Bb",a))    {return 1;};            break;
    case 'S': if(index("ACHDEachde",a)) {return 3;}
              else if(index("Oo",a))    {return 2;};            break;
    case 'P': if(index("Nn",a))         {return 3;};            break;
    case 'A': if(index("NCGBTRLPncgbtrlp",a)) {return 4;};      break;
    case 'B': if(index("RNSPDTYrnspdty",a)) {return 4;};        break;
    case 'D': if(index("PCNGMpcngm",a)) {return 4;};            break;
    case 'E': if(index("HBNFGSTXPChbnfgstxpc",a)) {return 4;};  break;
    case 'F': if(index("HRChrc",a)) {return 4;};                break;
    case 'G': if(index("MAHSRmahsr",a)) {return 4;};            break;
    case 'I': if(index("LSTNBlstnb",a)) {return 4;};            break;
    case 'K': if(index("Bb",a)) {return 4;};                    break;
    case 'L': if(index("ACTact",a)) {return 4;};                break;
    case 'M': if(index("PSTACFpstacf",a)) {return 4;};          break;
    case 'R': if(index("ACBKSZIFPELacbkszifpel",a)) {return 4;};break;
    case 'T': if(index("PAMpam",a)) {return 4;};                break;
    case 'U': if(index("CRAUELPcrauelp",a)) {return 4;};        break;
    case 'Y': if(index("Dd",a)) {return 4;};                    break;
    default: return 0;
  }
  return 0;
}

#define LIG(x) {if(!strncasecmp(resn,x,3)) {return 1;};}
#define LIG2(x) {if(!strncasecmp(resn,x,2)) {return 1;};}
int AtomInfoMatchResidue(char *resn, char a, char b, int elem_flag) {
  if(elem_flag==2) {
    if(resn[0]==a && resn[1]==b) {return 1;}
    if(resn[1]==a && resn[2]==b) {return 1;}
    if(a=='C'&&b=='O') {      LIG("3CO"); LIG("B12"); LIG("B13"); LIG("B1M");
      LIG("CB5"); LIG("CNC"); LIG2("CO"); LIG("CO5"); LIG("COB"); LIG("COH");
      LIG("CON"); LIG("COY"); LIG("DEU"); LIG("HCB"); LIG("NCO"); LIG("OCL");
      LIG("OCM"); LIG("OCN"); LIG("OCO"); LIG("PC3"); LIG("PL1"); }
    else if(a=='R'&&b=='H') { LIG("R1C"); LIG("RHD"); LIG("RHM"); }
    else if(a=='O'&&b=='S') { LIG("DOS"); LIG("LOS"); LIG2("OS"); LIG("OS4"); }
    return 0;
  } else if(elem_flag==1) {
    if(resn[0]==a && resn[1]==b) {return 1;} else {return 0;}
  } else { return 0; }
}
#undef LIG
#undef LIG2

void AtomInfoAssignParameters(ObjAtomInfo *I) {
  char *e,*rn,*n;
  float vdw;
  int i,elem_flag,protons=0,elementFound=0,ind=0;
  ElementDict * edp;
  BondValenceDict *bvp;
  char msg[FileLineLength];
  e=I->elem;
  e[2]=0;

  /* I. catch atom element type from atom name only when element not specified */
  if(*e==0 || (e[0]=='B'&&e[1]==0) || !AtomInfoIsElement(e[0],e[1])) {
    rn=I->realname;
    n=I->name;
    e[1]=0;
    if(isalpha(rn[1])) {
      if(isalpha(rn[0])) {      /* Deal with double characters elements, with false positives */
        elem_flag=AtomInfoIsElement(rn[0],rn[1]);
        switch(elem_flag) {
          case 0: if(index("Qq",rn[0])) {e[0]=rn[0];}
                  else if(index("CONHSPconhsp",rn[1])) {e[0]=rn[1];}
                  else {e[0]=rn[0];e[1]=rn[1];}; break;
          case 1:
          case 2: if(AtomInfoMatchResidue(I->ResidueInfo->resn,rn[0],rn[1],elem_flag)) {
                  e[0]=rn[0];e[1]=rn[1];} else {e[0]=rn[1];}; break;
          case 3:
          case 4:
          default: e[0]=rn[0];e[1]=rn[1]; break;
        }

//      if(index("Qq",rn[0])) {e[0]='Q';}       /* NMR structure, isotope Q */
//      else if(index("CONHSPconhsp",rn[1])) {
//        elem_flag=AtomInfoIsElement(rn[0],rn[1]);
//        if(elem_flag==2) {
//          e[0]=rn[0]; e[1]=rn[1]; /* Use both characters, if it is Zn,Mn,Mo */
//        } else if(elem_flag==1) {
//          e[0]=rn[0]; e[1]=rn[1]; /* Use both characters, if it is any other chemical elements */
//        } else e[0]=rn[1];        /* Use second character, if it is CONHSP, and doesn't form element with frst char */
//      } else {
//        e[0]=rn[0]; e[1]=rn[1];   /* Use both characters, if the second character is not CONHSP */
//      }

      } else if(index("CONHSPBDFIKQTUVWYconhspbdfikqtuvwy",rn[1])) {
        e[0]=rn[1];             /* Deal with 90% of the case, CONHSP, and other single character elements */
      } else {
        if(isalpha(rn[2])) {
          elem_flag=AtomInfoIsElement(rn[1],rn[2]);
          switch(elem_flag) {
            case 0: e[0]=index("CONHSPconhsp",rn[2])?rn[2]:rn[1]; break;
            case 1:
            case 2: if(AtomInfoMatchResidue(I->ResidueInfo->resn,rn[1],rn[2],elem_flag)) {
                    e[0]=rn[1];e[1]=rn[2];} else {e[0]=rn[2];}; break;
            case 3:
            case 4:
            default: e[0]=rn[1];e[1]=rn[2]; break;
          }
        } else { e[0]=rn[1]; }  /* no other choices */
      }
    } else {                    /* Deal with abnormal situation -- second character is not alphabetic */
      if(isalpha(rn[0])) {e[0]=rn[0];}
      else if(isalpha(rn[2])) {
        e[0]=rn[2];
        if(isalpha(rn[3])) e[1]=rn[3];
      } else if(isalpha(rn[3])) {e[0]=rn[3];}
    }
  }
  for(i=0;i<4;i++) if(I->realname[i]==' ') I->realname[i]='-';
//   if(*e==0) {
//     n=I->name;
//     while((!isalpha(n[0]))&&n[1]) n++;
//     while(isalpha(n[0])) *(e++)=*(n++);
//     *e=0;
//     e=I->elem;
//     switch(e[0]) {      /* keep the second character only when known as an element */
//       case 'C':
//         if(e[1]=='A'&&strncasecmp(I->ResidueInfo->resn,"Ca",2)) e[1]=0;
//         else if (!index("aluosrALUOSR",e[1]))     e[1]=0; break;
//       case 'H':
//         if(!index("eE",e[1]))                     e[1]=0; break;
//       case 'D':                                   e[1]=0; break;
//       case 'N':
//         if(!index("iabIAB",e[1]))                 e[1]=0; break;
//       case 'O':
//         if(!index("sS",e[1]))                     e[1]=0; break;
//       case 'S':
//         if(!index("ercbERCB",e[1]))               e[1]=0; break;
//       case 'P':
//         if(!index("dtbormaDTBORMA",e[1]))         e[1]=0; break;
//       default:                                            break;
//     }
//   }
  if(e[1]) e[1]=tolower(e[1]);
  else e[1]='_';

  /* II. assign hydrogen */
  I->hydrogen=((e[0]=='H'||e[0]=='D')&&(e[1]=='_'||e[1]==0));
  n=I->name;
  while(isdigit(n[0])&&n[1]) n++;
  /* Setting up priority, TODO */

  /* III. assign vdw, and number of protons (AKA. atom number) */
  e=I->elem;
  vdw=1.8f;
  while(isdigit(e[0])&&e[1]) e++;
  if(e[0]=='H' && I->ResidueInfo->type<=RESIDUE_SUGAR) {
    vdw=1.2f; I->protons=AN_H; I->bv_index=BV_H;
  } else if(e[1] != '_') {
    if     (!strcasecmp(e,"Ca")) {vdw=2.20f; I->protons=AN_Ca; I->bv_index=BV_Ca; }
    else if(!strcasecmp(e,"Cu")) {vdw=1.40f; I->protons=AN_Cu; I->bv_index=BV_Cu; }
    else if(!strcasecmp(e,"Cl")) {vdw=1.75f; I->protons=AN_Cl; I->bv_index=BV_Cl; }
    else if(!strcasecmp(e,"Na")) {vdw=2.27f; I->protons=AN_Na; I->bv_index=BV_Na; }
    else if(!strcasecmp(e,"Br")) {vdw=1.85f; I->protons=AN_Br; I->bv_index=BV_Br; }
    else if(!strcasecmp(e,"Se")) {vdw=1.90f; I->protons=AN_Se; I->bv_index=BV_Se; }
    else if(!strcasecmp(e,"Si")) {vdw=2.10f; I->protons=AN_Si; I->bv_index=BV_Si; }
    else if(!strcasecmp(e,"Fe")) {vdw=1.80f; I->protons=AN_Fe; I->bv_index=BV_Fe; }
    else if(!strcasecmp(e,"Mn")) {vdw=1.73f; I->protons=AN_Mn; I->bv_index=BV_Mn; }
    else if(!strcasecmp(e,"Mg")) {vdw=1.73f; I->protons=AN_Mg; I->bv_index=BV_Mg; }
    else if(!strcasecmp(e,"Hg")) {vdw=1.50f; I->protons=AN_Hg; I->bv_index=BV_Hg; }
    else if(!strcasecmp(e,"Zn")) {vdw=1.39f; I->protons=AN_Zn; I->bv_index=BV_Zn; }
  } else {
    switch(e[0]) {
      case 'C': vdw=1.7f;  I->protons=AN_C; I->bv_index=BV_C;     break;
      case 'H': vdw=1.2f;  I->protons=AN_H; I->bv_index=BV_H;     break;
      case 'D': vdw=1.2f;  I->protons=AN_H; I->bv_index=BV_H;     break;
      case 'N': vdw=1.55f; I->protons=AN_N; I->bv_index=BV_N;     break;
      case 'O': vdw=1.52f; I->protons=AN_O; I->bv_index=BV_undef; break;
      case 'S': vdw=1.83f; I->protons=AN_S; I->bv_index=BV_S;     break;
      case 'I': vdw=1.98f; I->protons=AN_I; I->bv_index=BV_I;     break;
      case 'P': vdw=1.80f; I->protons=AN_P; I->bv_index=BV_P;     break;
      case 'B': vdw=1.85f; I->protons=AN_B; I->bv_index=BV_B;     break;
      case 'F': vdw=1.47f; I->protons=AN_F; I->bv_index=BV_undef; break;
      case 'K': vdw=2.75f; I->protons=AN_K; I->bv_index=BV_K;     break;
      default:                                                    break;
    }
  }
  if(I->protons==0) {
    elementFound=0;
    for(i=0;protons<AN_max;i++) {
      edp=element_dictionary+i;
      protons=edp->protons;
      if(!strcasecmp(e,edp->elem)) {
        elementFound=1;
        I->protons=protons;
        break;
      }
    }
    if(!elementFound && e[0]=='X') {     // For X in ASX and GLX
      elementFound=1;
      I->protons=AN_O; I->bv_index=BV_undef;
    }
    if(!elementFound && e[0]=='H') {     // For H
      elementFound=1;
      I->protons=AN_H; I->bv_index=BV_H;
    }
    if(!elementFound) {
      sprintf(msg,"Element symbol %s is not recognized.",e);
      PFatalError(msg);
    }
    if(I->vdw==0.0f) {
      elementFound=0;
      ind=0;
      for(i=0;ind<BV_max;i++) {
        bvp=bondvalence_dictionary+i;
        ind=bvp->record_index;   
        if(I->protons==bvp->cation_protons) {
          elementFound=1;
          I->bv_index=ind;
          I->vdw=bvp->bv_r0_oxygen;
          break;
        }
      }
      if(!elementFound) {
        I->bv_index=BV_undef;
        I->vdw=vdw;
      }
    }
  }
  if(I->bv_index>=0)
    I->oxidation_state=(bondvalence_dictionary+I->bv_index)->oxidation_state;
  I->period=element_dictionary[I->protons].period;
  I->group =element_dictionary[I->protons].group;
  if(I->protons==AN_C || I->protons==AN_H) {
    I->isMetal=0;
  } else if (I->group==ELEM_GROUP_VIA) {
    if (I->protons==AN_O || I->protons==AN_S || I->protons==AN_Se) { I->isMetal=0; I->oxidation_state=-2;
    } else if (I->protons==AN_Te)                                  { I->isMetal=1; I->oxidation_state=-2;
    } else                                                           I->isMetal=1;
  } else if (I->group==ELEM_GROUP_VA) {
    if (I->protons==AN_N || I->protons==AN_P) { I->isMetal=0; I->oxidation_state=-3;
    } else if (I->protons==AN_As)             { I->isMetal=1; I->oxidation_state=-3;
    } else                                      I->isMetal=1;
  } else if (I->group==ELEM_GROUP_VIIA) {
    I->isMetal=0; I->oxidation_state=-1;
  } else if (I->group==ELEM_GROUP_VIIIA) {
    I->isMetal=0;
  } else {
    I->isMetal=1;
  }
}

double AtomInfoBondValence(int protons, int bv_index, double distance) {
  BondValenceDict *bvp;
  double bv_param=-1;
  if(bv_index==BV_undef) return -0.002f;// no reference value available for calculation
  if(bv_index>=BV_max)   return -0.003f;// no reference value available for calculation
  bvp=bondvalence_dictionary+bv_index;
  switch(protons) {
    case AN_O:  bv_param=bvp->bv_r0_oxygen    ; break;
    case AN_N:  bv_param=bvp->bv_r0_nitrogen  ; break;
    case AN_S:  bv_param=bvp->bv_r0_sulfur    ; break;
    case AN_P:  bv_param=bvp->bv_r0_phosphorus; break;
    case AN_H:  bv_param=bvp->bv_r0_hydrogen  ; break;
    case AN_Cl: bv_param=bvp->bv_r0_chlorine  ; break;
    case AN_Se: bv_param=bvp->bv_r0_selenium  ; break;
    case AN_F:  bv_param=bvp->bv_r0_fluorine  ; break;
    case AN_Br: bv_param=bvp->bv_r0_bromine   ; break;
    case AN_I:  bv_param=bvp->bv_r0_iodine    ; break;
    case AN_As: bv_param=bvp->bv_r0_arsenic   ; break;
    case AN_Te: bv_param=bvp->bv_r0_tellurium ; break;
    default:    bv_param=-1;                    break;
  }
  if(bv_param<0) return -0.001f;        // no reference value available for calculation
//if(distance<bv_param) return -4;      // invalid distance, too short for bond valence calculation
  return (exp((bv_param-distance)/0.37f));
}

int AtomInfoHasHydrogenBond(ObjAtomInfo *ai, ObjEntityMolecule *I, int consider_water) {
  int i;
  int numHB=0;
  ObjAtomInfo *ai2, *ai3;
  ObjNeighborInfo *ni;
  for(i=0;i<ai->numAtmNeighbor;i++) {
    ni=I->AtmNeighborInfo+ai->AtmNeighborIndex[i];
    if(ni->bond_type=='h' || ni->bond_type=='3') {
      if(consider_water) numHB++;
      else {
        ai2=I->AtomInfo+ni->atom_index[0];
        ai3=I->AtomInfo+ni->atom_index[1];
        if(ai2->type != ATOM_WT_O && ai3->type != ATOM_WT_O) numHB++;
      }
    }
  }
  return numHB;
}

double AtomInfoAssignOxidationState(ObjAtomInfo *ai_ion, int numAtomFCS, ObjIonLigAtomInfo *tmpIonLigAtom, double valence_3a) {
  char msg[FileLineLength];
  int i,j,temp_oxidation_state=-9999,temp_bv_index=BV_undef;
  double temp_valence_3a, temp_bv, temp_dev;
  BondValenceDict *bvp;
  ObjIonLigAtomInfo *ilai;
  double deviation=1.0f;
  double ret_valence_3a=valence_3a;
  if(ai_ion->protons==AN_O || ai_ion->protons==AN_S || ai_ion->protons==AN_Se || ai_ion->protons==AN_Te) {
    ai_ion->oxidation_state=-2; return ret_valence_3a;
  } else if(ai_ion->protons==AN_F || ai_ion->protons==AN_Cl || ai_ion->protons==AN_Br || ai_ion->protons==AN_I) {
    ai_ion->oxidation_state=-1; return ret_valence_3a;
  } else if(ai_ion->protons==AN_N || ai_ion->protons==AN_P || ai_ion->protons==AN_As) {
    ai_ion->oxidation_state=-3; return ret_valence_3a;
  }
  for(i=0;i<BV_max;i++) {
    bvp=bondvalence_dictionary+i;
    if(ai_ion->protons==bvp->cation_protons) {
      temp_valence_3a=0.0f;
      for(j=0;j<numAtomFCS;j++) {
        ilai=tmpIonLigAtom+j;
        temp_bv=AtomInfoBondValence(ilai->protons, i, ilai->distance);
        if(temp_bv>0) temp_valence_3a+=temp_bv;
      }
      temp_dev = fabs(temp_valence_3a-bvp->oxidation_state)/bvp->oxidation_state;
      if(temp_dev<0) temp_dev=0.0f;
      if(temp_dev<deviation) {
        deviation=temp_dev;
        temp_oxidation_state=bvp->oxidation_state;
        temp_bv_index=i;
        ret_valence_3a=temp_valence_3a;
      }
    }
  }
  if(temp_oxidation_state>=0 && ai_ion->oxidation_state!=temp_oxidation_state) {
    sprintf(msg,"There is an oxidation state change from default (%s) +%d -> +%d.", ai_ion->name, ai_ion->oxidation_state, temp_oxidation_state);
    PWarning(msg);
    ai_ion->oxidation_state=temp_oxidation_state;
    ai_ion->bv_index=temp_bv_index;
  }
//printf("INPUT %f change to %f\n", valence_3a,ret_valence_3a);
  return ret_valence_3a;
}

int AtomInfoExploreCluster(ObjAtomInfo *atinfo, ObjNeighborInfo *nbinfo, int *arr_atomid_cluster) {
  int i,j,k,already_exist,min_atomid,found_new=0;
  ObjAtomInfo *ai,*aj;
  ObjNeighborInfo *ni;
  for(i=0;arr_atomid_cluster[i]!=-1;i++) {
    ai=atinfo+arr_atomid_cluster[i];
    for(j=0;j<ai->numAtmNeighbor;j++) {
      ni=nbinfo+ai->AtmNeighborIndex[j];
      aj = (ni->atom_index[1]==ai->index) ? atinfo+ni->atom_index[0] : atinfo+ni->atom_index[1];
      if(aj->isMetal) {
        already_exist=0;
        for(k=0;arr_atomid_cluster[k]!=-1;k++) {
          if(aj->index==arr_atomid_cluster[k]) already_exist=1;
        }
        if(!already_exist) {
          found_new=1;
          arr_atomid_cluster[k]=aj->index;
          arr_atomid_cluster[k+1]=-1;
        }
      }
    }
  }
  if(found_new) return AtomInfoExploreCluster(atinfo,nbinfo,arr_atomid_cluster);
  else {
    min_atomid=arr_atomid_cluster[0];
    for(i=0;arr_atomid_cluster[i]!=-1;i++) {
      if(arr_atomid_cluster[i]<min_atomid) min_atomid=arr_atomid_cluster[i];
    }
    return min_atomid;
  }
}

void AtomInfoPrint(ObjAtomInfo *I) {
  ObjResidueInfo * resid=I->ResidueInfo;
  printf("%d: res.chain %c; alt %c; res.resn %s; res.resi %s; name %s; elem %s; vdw %f\n",
       I->id, resid->chain, I->alt, resid->resn, resid->resi, I->name, I->elem, I->vdw);
}

void AtomInfoPrintPDB(char* pdb_buffer_str, ObjAtomInfo *I, char chain, Vector3f v) {
  int i;
  char elem,elem2;
  char line[FileLineLength];
  sprintf(line,"ATOM  %5d ",I->index);
  strcat(pdb_buffer_str,line);
  for(i=0;i<4;i++) {
    sprintf(line,"%c",I->realname[i]=='-'?' ':I->realname[i]);
    strcat(pdb_buffer_str,line);
  }
  if(I->elem[0]) {
    if(I->elem[1] && I->elem[1]!='_') {
      elem=I->elem[0];elem2=I->elem[1];
    } else {
      elem=' ';elem2=I->elem[0];
    }
  } else {
    elem=' ';elem2=' ';
  }
  sprintf(line," %s %c%4d    %8.3f%8.3f%8.3f%6.2f%6.2f          %c%c  \n",I->ResidueInfo->resn,chain,I->ResidueInfo->resid,v[0],v[1],v[2],I->occup,I->b,elem,elem2);
  strcat(pdb_buffer_str,line);
}

void AtomInfoPrintElement(ElementDict *elem_dict) {
  ElementDict * edp;
  int protons=0,i=0;
  for(i=0;protons<AN_max;i++) {
    edp=elem_dict+i;
    protons=edp->protons;
    printf("%d, %s, %d, %s\n", i, edp->elem, protons, edp->element);
    if (protons<AN_max && i!=protons) PFatalError("Record index does not match element protons number");
  }
}

void AtomInfoPrintBondValence(BondValenceDict *bv_dict) {
  BondValenceDict *bvp, *prev_bvp;
  int index=0,i=0,multiFlag=0,nodataFlag=0;
  char msg[FileLineLength];
  while (index<BV_max) {
    bvp=bv_dict+i;
    index=bvp->record_index;
    nodataFlag=1;
    if (index<BV_max) {
      if(bvp->bv_r0_sulfur    >0) nodataFlag=0;
      if(bvp->bv_r0_selenium  >0) nodataFlag=0;
      if(bvp->bv_r0_tellurium >0) nodataFlag=0;
      if(bvp->bv_r0_bromine   >0) nodataFlag=0;
      if(bvp->bv_r0_iodine    >0) nodataFlag=0;
      if(bvp->bv_r0_nitrogen  >0) nodataFlag=0;
      if(bvp->bv_r0_phosphorus>0) nodataFlag=0;
      if(bvp->bv_r0_arsenic   >0) nodataFlag=0;
      if(bvp->bv_r0_hydrogen  >0) nodataFlag=0;
    }
    if (index<BV_max && multiFlag) {
      msg[0]=0;
      if(bvp->bv_r0_sulfur    != prev_bvp->bv_r0_sulfur)    sprintf(msg, "Disagreed bond valence value for sulfur");
      if(bvp->bv_r0_selenium  != prev_bvp->bv_r0_selenium)  sprintf(msg, "Disagreed bond valence value for selenium");
      if(bvp->bv_r0_tellurium != prev_bvp->bv_r0_tellurium) sprintf(msg, "Disagreed bond valence value for tellurium");
      if(bvp->bv_r0_bromine   != prev_bvp->bv_r0_bromine)   sprintf(msg, "Disagreed bond valence value for bromine");
      if(bvp->bv_r0_iodine    != prev_bvp->bv_r0_iodine)    sprintf(msg, "Disagreed bond valence value for iodine");
      if(bvp->bv_r0_nitrogen  != prev_bvp->bv_r0_nitrogen)  sprintf(msg, "Disagreed bond valence value for nitrogen");
      if(bvp->bv_r0_phosphorus!= prev_bvp->bv_r0_phosphorus)sprintf(msg, "Disagreed bond valence value for phosphorus");
      if(bvp->bv_r0_arsenic   != prev_bvp->bv_r0_arsenic)   sprintf(msg, "Disagreed bond valence value for arsenic");
      if(bvp->bv_r0_hydrogen  != prev_bvp->bv_r0_hydrogen)  sprintf(msg, "Disagreed bond valence value for hydrogen");
      if(strlen(msg)) PFatalError(msg);
    }
    if (!multiFlag) {
      printf("%d, %d, %s, %d: ", i, index, bvp->cation_elem,  bvp->cation_protons);
      if (!nodataFlag) printf("S(%f) Se(%f) Te(%f) Br(%f) I(%f) N(%f) P(%f) As(%f) H(%f)",  bvp->bv_r0_sulfur,  bvp->bv_r0_selenium, bvp->bv_r0_tellurium,
        bvp->bv_r0_bromine, bvp->bv_r0_iodine, bvp->bv_r0_nitrogen, bvp->bv_r0_phosphorus, bvp->bv_r0_arsenic, bvp->bv_r0_hydrogen);
      printf("\n");
    }
    printf("            +%d: O(%f) F(%f) Cl(%f)\n", bvp->oxidation_state, bvp->bv_r0_oxygen, bvp->bv_r0_fluorine, bvp->bv_r0_chlorine);
    multiFlag=0;
    if (bvp->next_record_index<0) printf("\n"); else multiFlag=1;
    prev_bvp=bvp;
    i++;
  }
}

int AtomInfoLocateIndex4surfrace(ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index) {
// Procedure is not working, I/O for variables exact_match, chainid_from and chainid_to need to be rewritten
// Plus, usage of resCount and atomCount in various branches need to be re-examined to ensure correctness of output value
  int i;
  char msg[FileLineLength];
  int resCount,atomCount,resFound,atomFound;
  int exact_match=0;
  char chainid_from=0,chainid_to=0;
  ObjResidueInfo *ri;
  ObjAtomInfo    *ai;
  int prev_residue_index;
  ai=I->AtomInfo+prev_atom_index;
  prev_residue_index=ai->residue_index;
  ri=I->ResidueInfo+prev_residue_index;
  if (resi->chain==ri->chain && resi->resid==ri->resid &&
      resi->resi2==ri->resi2 && strcmp(resi->resn,ri->resn)==0) {
    atomCount++;
  } else if (exact_match==1 && resi->chain==chainid_from) {
    if(resi->resid==ri->resid && resi->resi2==ri->resi2 &&
       strcmp(resi->resn,ri->resn)==0) atomCount++;
    else {
      resFound=-1;
      for(i=0; i<I->numResidue; i++){               // scan from the beginning to the end
        ri=I->ResidueInfo+i;
        if (chainid_to==ri->chain  && resi->resid==ri->resid &&
            resi->resi2==ri->resi2 && strcmp(resi->resn,ri->resn)==0) {
          exact_match=1; resFound=i; break;
        }
      }
      if(resFound==-1){
        ri=I->ResidueInfo; resCount=0; atomCount=0;
      } else { resCount=resFound; atomCount=0; }
    }
  } else {
    resFound=-1;
    for (i=prev_residue_index;i<I->numResidue;i++) {
      ri=I->ResidueInfo+i;
      if (resi->chain==ri->chain && resi->resid==ri->resid &&
          resi->resi2==ri->resi2 && strcmp(resi->resn,ri->resn)==0) {
        exact_match=0; resFound=i; break;
      }
    }
    if(resFound==-1){
      for(i=0; i<prev_residue_index; i++){                    /* scan from the beginning of coord */
        ri=I->ResidueInfo+i;
        if (resi->chain==ri->chain && resi->resid==ri->resid &&
            resi->resi2==ri->resi2 && strcmp(resi->resn,ri->resn)==0) {
          exact_match=0; resFound=i; break;
        }
      }
      if(resFound==-1){
        for(i=0; i<I->numAtom; i++){                /* try to allow chain_id mismatch, looking for next available chain */
          ai=I->AtomInfo+i;
          if (atmi->id==ai->id && resi->resid==ri->resid && strcmp(resi->resn,ri->resn)==0) {
            exact_match=1;          ri=ai->ResidueInfo;
            resFound=ri->index;
            chainid_from=resi->chain; chainid_to=ri->chain; break;
          }
        }
      }
    }
    if(resFound==-1){                               /* just don't report any error, although slower, it will still get automatically corrected during atom looking */
      ri=I->ResidueInfo; resCount=0; atomCount=0;
    } else { resCount=resFound; atomCount=0; }
  }

  atomFound=-1;
  if (resFound==-1) {
    for(i=0; i<I->numAtom; i++){            /* try to allow chain_id mismatch, looking for next available chain */
      ai=I->AtomInfo+i;
      if (atmi->id==ai->id && strncmp(atmi->realname,ai->realname,4)==0 && atmi->alt==ai->alt) {
        exact_match=1;              ri=ai->ResidueInfo;
        resFound=ri->index;         atomFound=ai->index;        
        chainid_from=resi->chain;   chainid_to=ri->chain; break;
      }
    }
    if (resFound==-1) {
      sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom.",resi->chain,resi->resn,resi->resid);
      PFatalError(msg);
    }
  } else {
    for(i=atomCount;i<ri->numAtom;i++){     /* scan to the end of residue */
      ai=ri->AtomInfo+i;
      if(atmi->id==ai->id && strncmp(atmi->realname,ai->realname,4)==0 && atmi->alt==ai->alt){
        atomFound=ai->index; break;
      }
    }
    if(atomFound==-1){
      for(i=0;i<atomCount;i++){             /* scan from the beginning of residue */
        ai=ri->AtomInfo+i;
        if(atmi->id==ai->id && strncmp(atmi->realname,ai->realname,4)==0 && atmi->alt==ai->alt){
          atomFound=ai->index; break;
        }
      }
      if(atomFound==-1){
        for(i=0;i<ri->numAtom;i++){         /* scan again with losser criteria */
          ai=ri->AtomInfo+i;
          if(strncmp(atmi->realname,ai->realname,4)==0 && atmi->alt==ai->alt) {
            atomFound=ai->index; break;
          }
        }
        if(atomFound==-1) {
          sprintf(msg,"Failed to locate corresponding atom %d:%s:%c for SURFRACE file.", atmi->id, atmi->realname, atmi->alt);
          PFatalError(msg);
        }
      }
    }
  }
  return ai->index;
}

int AtomInfoResCmp(ObjResidueInfo *resi, ObjResidueInfo *ri, char rescmp_type) {
  char msg[FileLineLength];
  int resFound=0;
  if(resi->chain==ri->chain && resi->resid==ri->resid) {
    if(rescmp_type=='c') {
      // For CCP4 contact
      if(!strncmp(resi->resn,"WAT",3) && ri->type==RESIDUE_WATER) {
        resFound=1;
      } else if (!strncmp(resi->resn,ri->resn,3)) {
        resFound=1;
      } else {
        sprintf(msg,"Mismatched residue name pair found %c%d (%s ~ %s).",
                     ri->chain, ri->resid, ri->resn, resi->resn);
        PWarning(msg);
      }
    } else {
      // For MolProbity probe
      // if(rescmp_type=='m')   // Comment out coz it doesn't matter at the moment, since if it is not 'c', it is gonna be 'm'
      if (!strncmp(resi->resn,ri->resn,3) && resi->resi2==ri->resi2) {
        resFound=1;
      }
    }
  }
  return resFound;
}

int AtomInfoLocateIndex4contact(int* list_atomindex, ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index) {
  int i, j;
  int resFound, resException;
  int atomnamelen, atomFound;
  char *p,*ati_begin,msg[FileLineLength];
  int list_mismatch_residueid[256];
  int list_mismatch_residueid_length=0;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  int prev_residue_index;

  atomFound=0;
  while (!atomFound) {
    ai=I->AtomInfo+prev_atom_index;
    prev_residue_index=ai->residue_index;
  /* DEBUG Lines
    printf("Calling with %d: %d\n", prev_atom_index, prev_residue_index);
    printf("res: chain %c, id %d, resn %s; atom: name %s\n", resi->chain, resi->resid, resi->resn, atmi->name);
    AtomInfoPrint(ai);
  */
    // Locating corresponding residue in the internal molecule object
    // Locating corresponding atom in the found residue
    // atmi->name is in the format "C2'=", ai->realname is in the format "-C2'"
    resFound=0;
    for(i=prev_residue_index;i<I->numResidue;i++) {
      resException=0;
      for(j=0;j<list_mismatch_residueid_length;j++) if(list_mismatch_residueid[j]==i) {resException=1; break;}
      if(resException) continue;
      ri=I->ResidueInfo+i;
      resFound=AtomInfoResCmp(resi,ri,'c');
      if(resFound) break;
    }
    if(!resFound) {
      for(i=0;i<prev_residue_index;i++) {
        resException=0;
        for(j=0;j<list_mismatch_residueid_length;j++) if(list_mismatch_residueid[j]==i) {resException=1; break;}
        if(resException) continue;
        ri=I->ResidueInfo+i;
        resFound=AtomInfoResCmp(resi,ri,'c');
        if(resFound) break;
      }
    }
    if(!resFound) {
      sprintf(msg,"Cannot locate residue (%c%d: %s) from CCP4 contact output in corresponding PDB file.",
                   resi->chain, resi->resid, resi->resn);
      PWarning(msg);
      return 0;
      PFatalError(msg);
    }

    atomFound=0;
    p=atmi->name;
    while(*p) {
      if(*p=='=') break;
      p++;
    }
    atomnamelen = p-atmi->name;
    for(i=0;i<ri->numAtom;i++) {
      ai=ri->AtomInfo+i;
      ati_begin = ai->realname;
      ati_begin = str2bskip(ati_begin,'-');
      if(!strncmp(atmi->name, ati_begin, atomnamelen) &&
         (ati_begin[atomnamelen]==0 || ati_begin[atomnamelen]=='-')) {
        if(atomFound>8) break;
        list_atomindex[atomFound]=ai->index;
        atomFound++;
      }
    }
    if(!atomFound) {
      sprintf(msg,"Cannot locate atom (%c%d %s: %s) from CCP4 contact output in corresponding PDB file.",
                   resi->chain, resi->resid, resi->resn, atmi->name);
      PWarning(msg);
      list_mismatch_residueid[list_mismatch_residueid_length]=ri->index;
      list_mismatch_residueid_length++;
    } else if (atomFound>8) {
      sprintf(msg,"Too many alternative conformation for atom (%c%d %s: %s) in corresponding PDB file.",
                   resi->chain, resi->resid, resi->resn, atmi->name);
      PFatalError(msg);
    }
  }
//AtomInfoPrint(ai); printf("==EOF==\n");
  return atomFound;
}

ObjAtomInfo *AtomInfoLocateIndex4molprobity(ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index) {
  int i, j, resFound, atomFound, altFound;
  char msg[FileLineLength];
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  int prev_residue_index;
  atomFound=0;
  while (!atomFound) {
    ai=I->AtomInfo+prev_atom_index;
    prev_residue_index=ai->residue_index;
    resFound=0;
    for(i=prev_residue_index;i<I->numResidue;i++) {
      ri=I->ResidueInfo+i;
      resFound=AtomInfoResCmp(resi,ri,'m');
      if(resFound) break;
    }
    if(!resFound) {
      for(i=0;i<prev_residue_index;i++) {
        ri=I->ResidueInfo+i;
        resFound=AtomInfoResCmp(resi,ri,'m');
        if(resFound) break;
      }
      if(!resFound) {
        // toggle case to try again
        if      (resi->chain>='A' && resi->chain<='Z') resi->chain+=32;
        else if (resi->chain>='a' && resi->chain<='z') resi->chain-=32;
        for(i=prev_residue_index;i<I->numResidue;i++) {
          ri=I->ResidueInfo+i;
          resFound=AtomInfoResCmp(resi,ri,'m');
          if(resFound) break;
        }
        if(!resFound) {
          for(i=0;i<prev_residue_index;i++) {
            ri=I->ResidueInfo+i;
            resFound=AtomInfoResCmp(resi,ri,'m');
            if(resFound) break;
          }
        }
      }
    }
    if(!resFound) {
      sprintf(msg,"Cannot locate residue (%c%d[%s]%c) from Molprobity probe output in corresponding PDB file.",
                   resi->chain, resi->resid, resi->resn, resi->resi2);
      PFatalError(msg);
    }

    atomFound=0; altFound=0;
    for(i=0;i<ri->numAtom;i++) {
      ai=ri->AtomInfo+i;
      if(!strncmp(atmi->realname, ai->realname, 4) && atmi->alt==ai->alt) {
        atomFound=1; break;
      } else if(atmi->alt!=' ' || ai->alt!=' ') {
        altFound++;
      }
    }
    if(!atomFound) {
      if(!altFound) {
        /* exception goes here, for pdbid 4a3i residue N9[_DT] atom -C5M, molprobity interpret it as -H7n and reversed to -C7- */
        for(i=0;i<ri->numAtom;i++) {
          ai=ri->AtomInfo+i;
          if(atmi->realname[1]==ai->realname[1] && ai->realname[3]=='M' && atmi->alt==ai->alt) {
            atomFound=1; break;
          }
        }
      }
      sprintf(msg,"Cannot locate atom (%c%d[%s]%c:[%s]%c) from Molprobity probe output in corresponding PDB file.",
                   resi->chain, resi->resid, resi->resn, resi->resi2, atmi->realname, atmi->alt);
      if(altFound) { PWarning(msg); return NULL; }
      else if(atomFound) {
        sprintf(msg,"Cannot locate atom (%c%d[%s]%c:[%s]%c) from Molprobity probe output. Use a different atom ([%s]) in the residue instead",
                   resi->chain, resi->resid, resi->resn, resi->resi2, atmi->realname, atmi->alt, ai->realname);
        PWarning(msg); return ai;
      } else {
        PWarning(msg); return NULL;
        PFatalError(msg);
      }
    }
  }
  return ai;
}

ObjNeighborStack* stackNew() {
  ObjNeighborStack* s;
  AllocP(s,ObjNeighborStack,1);
  s->size=0;
  s->top=NULL;
  return s;
}

void stackPush(ObjNeighborStack *s, ObjResidueInfo *resi1, ObjAtomInfo *atmi1, ObjResidueInfo *resi2, ObjAtomInfo *atmi2, int regid1, int regid2, int regint, float regfloat) {
  RecNeighborStack *prev_rec, *rec;
  prev_rec=s->top;
  AllocP(s->top,RecNeighborStack,1);
  rec=s->top;
  strcpy(rec->resn1,resi1->resn);
  rec->chain1=resi1->chain;
  rec->resid1=resi1->resid;
  strcpy(rec->atomname1,atmi1->name);
  strcpy(rec->resn2,resi2->resn);
  rec->chain2=resi2->chain;
  rec->resid2=resi2->resid;
  strcpy(rec->atomname2,atmi2->name);
  rec->regid1=regid1;
  rec->regid2=regid2;
  rec->register_int=regint;
  rec->register_float=regfloat;
  rec->prev=prev_rec;
  s->size++;
}

int  stackContains(ObjNeighborStack *s, ObjResidueInfo *resi1, ObjAtomInfo *atmi1, ObjResidueInfo *resi2, ObjAtomInfo *atmi2, int icell, int isym) {
  RecNeighborStack *rec;
  int equals,contains=0;
  rec=s->top;
  while(rec) {
    equals=1;
    if      (rec->resid1!=resi1->resid || rec->resid2!=resi2->resid) equals=0;
    else if (rec->chain1!=resi1->chain || rec->chain2!=resi2->chain) equals=0;
    else if (strncmp(rec->atomname1,atmi1->name,4) || strncmp(rec->atomname2,atmi2->name,4)) equals=0;
    else if (strncmp(rec->resn1,resi1->resn,3) || strncmp(rec->resn2,resi2->resn,3)) equals=0;
    else if (rec->regid1!=icell || rec->regid2!=isym) equals=0;
    if(equals) {
      contains=1;
      break;
    }
    rec=rec->prev;
  }
  return contains;
}

int stackDelete(ObjNeighborStack *s, int record_id) {
  RecNeighborStack *rec, *rec_next;
  int record_deleted=0;
  rec=s->top;
  if(!rec) return 0;
  else if(rec->register_int==record_id) {
    s->top=rec->prev;
    FreeP(rec);
    record_deleted=1;
  } else {
    rec_next=rec;
    rec=rec->prev;
    while(rec) {
      if(rec->register_int==record_id) {
        rec_next->prev=rec->prev;
        FreeP(rec);
        record_deleted=1;
        break;
      } else {
        rec_next=rec;
        rec=rec->prev;
      }
    }
  }
  if(record_deleted) s->size--;
  return record_deleted;
}

void stackRecPrint(RecNeighborStack *rec, char *msg) {
  char info[FileLineLength]; 
  sprintf(info,"%s: (%f) %c%d-%s-%s:%c%d-%s-%s.", msg, rec->register_float,
          rec->chain1, rec->resid1, rec->resn1, rec->atomname1,
          rec->chain2, rec->resid2, rec->resn2, rec->atomname2);
  strcpy(msg,info);
}

void stackFree(ObjNeighborStack *s) {
  RecNeighborStack *rec, *rec_prev;
  rec=s->top;
  while(rec) {
    rec_prev=rec->prev;
    FreeP(rec);
    rec=rec_prev;
  }
  FreeP(s);
}

