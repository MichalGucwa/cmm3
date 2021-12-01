#include "main.h"
#include "AtomInfo.h"
#include "Hash.h"
#include "csymlib.h"
#include "PDBheader.h"

char* contact_pdb_buffer_str;

/*---------------------------------------------------------------------------*/
int ReadAminoAcidDictionary(ResidueDict *aminoacid_dictionary, char *file_aadict) {
  FILE *f;
  char* buffer=NULL;
  char *p;
  ResidueName nsa,aa;
  int rt,last_record=0;

  f=fopen(file_aadict,"rb");
  if (!f) { PFatalError("invalid Amino Acid Dictionary file name\n"); };
  buffer=str2cachetextfile(f);
  p=buffer;
  while(*p) {
    p=str2ncpy(aminoacid_dictionary[last_record].nsa,p,3);
    aminoacid_dictionary[last_record].nsa[3]=0;
    p=str2nskip(p,1);
    if(!strncmp(p,"GLY",3))      rt=RESIDUE_GLY;
    else if(!strncmp(p,"ALA",3)) rt=RESIDUE_ALA;
    else if(!strncmp(p,"VAL",3)) rt=RESIDUE_VAL;
    else if(!strncmp(p,"LEU",3)) rt=RESIDUE_LEU;
    else if(!strncmp(p,"ILE",3)) rt=RESIDUE_ILE;
    else if(!strncmp(p,"SER",3)) rt=RESIDUE_SER;
    else if(!strncmp(p,"THR",3)) rt=RESIDUE_THR;
    else if(!strncmp(p,"CYS",3)) rt=RESIDUE_CYS;
    else if(!strncmp(p,"MET",3)) rt=RESIDUE_MET;
    else if(!strncmp(p,"PRO",3)) rt=RESIDUE_PRO;
    else if(!strncmp(p,"ASP",3)) rt=RESIDUE_ASP;
    else if(!strncmp(p,"ASN",3)) rt=RESIDUE_ASN;
    else if(!strncmp(p,"GLU",3)) rt=RESIDUE_GLU;
    else if(!strncmp(p,"GLN",3)) rt=RESIDUE_GLN;
    else if(!strncmp(p,"LYS",3)) rt=RESIDUE_LYS;
    else if(!strncmp(p,"ARG",3)) rt=RESIDUE_ARG;
    else if(!strncmp(p,"HIS",3)) rt=RESIDUE_HIS;
    else if(!strncmp(p,"PHE",3)) rt=RESIDUE_PHE;
    else if(!strncmp(p,"TYR",3)) rt=RESIDUE_TYR;
    else if(!strncmp(p,"TRP",3)) rt=RESIDUE_TRP;
    else rt=RESIDUE_UNDEF;
    p=str2ncpy(aminoacid_dictionary[last_record].aa,p,3);
    aminoacid_dictionary[last_record].aa[3]=0;
    aminoacid_dictionary[last_record].type=rt;
    last_record++;
    p=str2nextline(p);
  }
  aminoacid_dictionary[last_record].nsa[0]=0;
  aminoacid_dictionary[last_record].aa[0]=0;
  aminoacid_dictionary[last_record].type=-1;
  return last_record;   // return the number of records read into the aminoacid_dictionary array
}

/*---------------------------------------------------------------------------*/
ObjEntityMolecule *EntityMoleculeNew() {
  int i;
  OOAlloc(ObjEntityMolecule);
  /* The field filename/pdbid need to be explicitly defined immediately after initiation */
  I->pdbfileid          = 0;
  I->intra_residue_flag = 0;    I->shortest_only_flag = 1;
  I->numAssembly        = 0;    I->numComponent       = 0;
  I->numKeyword         = 0;    I->numChain           = 0;
  I->numMolecule        = 0;    I->numDomain          = 0;
  I->numResidue         = 0;    I->numAtom            = 0;
  I->numResNeighbor     = 0;    I->numAtmNeighbor     = 0;
  I->numAngle           = 0;    I->numIonBindingSite  = 0;
  /* It is important for this two memory allocation to be autozero */
  I->AssemblyInfo       = NULL; I->ComponentInfo      = NULL;
  I->KeywordInfo        = NULL; I->ChainInfo          = NULL;
  I->MoleculeInfo       = NULL; I->DomainInfo         = NULL;
  I->ResidueInfo        = NULL; I->AtomInfo           = NULL;
  I->ResNeighborInfo    = NULL; I->AtmNeighborInfo    = NULL;
  I->AngleInfo          = NULL; I->IonBindingSiteInfo = NULL;
  I->Coord              = NULL;
  VectorClear3f(I->Max);
  VectorClear3f(I->Min);
  VectorClear3f(I->Center);
  /* initialize cell and symmetry info, together with resolution and deposition date */
  I->space_group        = NULL;  I->space_group_name[0]= 0;     I->space_group_number = -1;
  I->cell_a             = -1.0f; I->cell_b             = -1.0f; I->cell_c             = -1.0f;
  I->cell_alpha         = -1.0f; I->cell_beta          = -1.0f; I->cell_gamma         = -1.0f;
  I->z_value            = -1;    I->resolution         = -1;    strcpy(I->deposition_date,"31-DEC-69");
  I->symop_status       = 0;     I->symop              = NULL;  I->nsymop             = 0;
  I->origx_matrix       = NULL;  I->scale_matrix       = NULL;
  I->origx_done         = 0;     I->scale_done         = 0;     I->compnd_done        = 0;
  I->source_done        = 0;     I->compnd_wait        = 0;     I->source_wait        = 0;
  /* initialize functional info and fold info */
  I->exp_method  = EXP_METHOD_UNDEF;  I->header[0]     = 0;     I->title[0]           = 0;
  I->organism_id = -1;
  I->go_process  = -1;                I->go_function   = -1;    I->go_component       = -1;
  I->ec_primary  = EC_000_UNKNOWN;    I->ec_3rd_level  = -1;    I->ec_4th_level       = -1;
  I->ec_complex  = EC_000_UNKNOWN;    I->cluster50_id  = -1;    I->cluster90_id       = -1;
  I->cath_primary= CATH_0000_UNKNOWN; I->cath_topology = -1;    I->cath_superfamily   = -1;
  I->temp_index  = -1;                I->temp_field[0]=0;
  for(i=0;i<TABLE_MAX;i++) {
    I->tables[i]=1;
  }
  return(I);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeFree(ObjEntityMolecule *I) {
  FreeP(I->AssemblyInfo);
  FreeP(I->ChainInfo);
  FreeP(I->MoleculeInfo);
  FreeP(I->ResidueInfo);
  FreeP(I->AtomInfo);
  FreeP(I->ResNeighborInfo);
  FreeP(I->ResNeighborInfo);
  FreeP(I->Coord);
  FreeP(I)
}

/*---------------------------------------------------------------------------*/
void ObjGeneOntologyInit(ObjGeneOntologyInfo *goi, char go_type, int index) {
  goi->index=index;       goi->chain=0;
  goi->go_type=go_type;   goi->go_id=-1;
  goi->qualifier=0;       goi->evidence[0]=0;
  goi->xref_db_name[0]=0; goi->xref_db_id[0]=0;
  goi->organism_id=-1;    goi->created_by[0]=0;
  strcpy(goi->creation_date,"12-31-69");
  goi->ref_db_name='U';   goi->ref_db_id=-1;
}

/*---------------------------------------------------------------------------*/
int ObjGeneOntologyMinimalID(ObjGeneOntologyInfo *goinfo, int numGO) {
  ObjGeneOntologyInfo *goi;
  int i, GOminID=-1;
  for(i=0;i<numGO;i++) {
    goi=goinfo+i;
    if(goi->go_id>=0) {
      if (GOminID<0) GOminID=goi->go_id;
      else if (GOminID>goi->go_id) GOminID=goi->go_id;
    }
  }
  return GOminID;
}

/*---------------------------------------------------------------------------*/
void ObjComponentInit(ObjComponentInfo *comi) {
  comi->index=-1;       comi->componentnum=-1;
  comi->numChain=0;     comi->component_name[0]=0;
  comi->numKeyword=0;   comi->KeywordInfo=NULL;
  comi->numFunction=0;  comi->FunctionInfo=NULL;
  comi->engineered=0;   comi->mutation=0;
  comi->organism_id=-1; comi->organism_name[0]=0;
}

void ObjFunctionInit(ObjFunctionInfo *funi) {
  funi->index=-1;
  funi->ec_primary=-1;
  funi->ec_3rd_level=-1;
  funi->ec_4th_level=-1;
  funi->ComponentInfo=NULL;
}

void ObjKeywordInit(ObjKeywordInfo *keyi) {
  keyi->index=-1;
  keyi->keyword[0]=0;
  keyi->ComponentInfo=NULL;
}

void ObjChainInit(ObjChainInfo *ci) {
  ci->index=-1;           ci->chainid=0;
  ci->assembly_index=-1;  ci->AssemblyInfo=NULL;
  ci->ComponentInfo=NULL;
  ci->numWaterRes=0;      ci->numLigandRes=0;
  ci->numDnarnaRes=0;     ci->numProteinRes=0;
  ci->type2               =CHAIN_TYPE2_UNDEF;
  ci->clusterstatus       =CHAIN_CLUSTER_UNDEF;
  ci->cluster50_id=-1;    ci->represent50_id=-1;
  ci->cluster90_id=-1;    ci->represent90_id=-1;
  ci->numGeneOntology=0;
  ci->numBiolProcess=0;   ci->BiolProcessInfo=NULL;
  ci->numMoleFunction=0;  ci->MoleFunctionInfo=NULL;
  ci->numCellComponent=0; ci->CellComponentInfo=NULL;
  ci->numMolecule=0;      ci->MoleculeInfo=NULL;
  ci->numDomain=0;        ci->numFragment=0;
  ci->DomainInfo=NULL;    ci->numResidue=0;
  ci->numAtom=0;          ci->claimed=0;
  VectorClear3f(ci->Center);
}

void ObjMoleculeInit(ObjMoleculeInfo *mi) {
  mi->index=-1;         mi->type=COMPONENT_OTHER;
  mi->assembly_index=-1;mi->AssemblyInfo=NULL;
  mi->chain=0;          mi->ChainInfo=NULL;
  mi->numResidue=0;
}

void ObjDomainInit(ObjDomainInfo *di) {
  di->index=-1;            di->chain=0;          di->residueid_begin=-9999;
  di->residueid_end=-9999; di->is_fragment=-1;   di->domainnum=-1;
  di->cath_primary=-1;     di->cath_topology=-1; di->cath_superfamily=-1;
  di->cath_s35=-1;         di->cath_s60=-1;      di->cath_s95=-1;
  di->cath_s100=-1;        di->cath_uniqueid=-1; di->numResidue=0;
}

void ObjResidueInit(ObjResidueInfo *ri) {
  ri->index=-1;                 ri->type=RESIDUE_UNDEF;
  ri->prev_index=-1;            ri->next_index=-1;
  ri->assembly_index=-1;        ri->AssemblyInfo=NULL;
  ri->cavity_index=-1;          ri->CavityInfo=NULL;
  ri->chain=0;                  ri->ChainInfo=NULL;
  ri->molecule_index=0;         ri->MoleculeInfo=NULL;
  ri->resn[0]=0;                ri->resi[0]=0;
  ri->resid=-9999;              ri->resi2=0;
  ri->numAtom=0;                ri->isSingle=-1;
  ri->containsMetal=-1;         ri->location=RESIDUE_LOCATE_UNDEF;
  ri->asa=-1;                   ri->msa=-1;
  ri->curvature=0;              ri->AtomInfo=NULL;
  ri->center_displacement=0.0f; VectorClear3f(ri->Center);
}

void ObjResidueAssignAltLoc(ObjResidueInfo *ri) {
  int i, j;
  ObjAtomInfo *ai1, *ai2;
  char msg[FileLineLength];
  for(i=0;i<ri->numAtom;i++) {
    ai1=ri->AtomInfo+i;
//  ai1->numAltLoc=1;    // Skip Init here since it was initialized in the main procedure
    for(j=i+1;j<ri->numAtom;j++) {
      ai2=ri->AtomInfo+j;
      if(!strncmp(ai1->realname,ai2->realname,4)) {
        if(ai1->alt==ai2->alt) {
          if(ai1->protons!=AN_H && ai2->protons!=AN_H) {
            // hydrogen are allowed to have the same atomname in the same residue
            // otherwise, an error will be reported is not alternative location is reported
            sprintf(msg,"Alternative atoms (%d(%s)%c-%d(%s)%c) should be assigned different altLoc code\n",
                ai1->id, ai1->realname, ai1->alt, ai2->id, ai2->realname, ai2->alt);
            PFatalError(msg);
          }
        } else {
          ai1->AltLocStr[ai1->numAltLoc]=ai2->alt;
          ai1->numAltLoc++;
          ai2->AltLocStr[ai2->numAltLoc]=ai1->alt;
          ai2->numAltLoc++;
          if (ai1->numAltLoc>=16 || ai2->numAltLoc>=16) PFatalError("Too many alternative location for the same atom (n >= 16)\n");
        }
      }
    }
    ai1->AltLocStr[ai1->numAltLoc]=0;
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadPDBStr(ObjEntityMolecule *I, char *buffer, ResidueDict *aminoacid_dictionary) {
  int              i,atomFlag,rescodeFlag,chainFound,numAtom=0;
  int              componentCount,keywordCount,chainCount,molCount,resCount,atomCount,coordCount;
  char             *p,*p2,q[FileLineLength];
  float            *coord=NULL;
  ObjComponentInfo *cpinfo=NULL,*comi;
  ObjKeywordInfo   *kwinfo=NULL,*keyi;
  ObjChainInfo     *chinfo=NULL,*ci,chain;
  ObjResidueInfo   *rsinfo=NULL,*ri,res;
  ObjAtomInfo      *atinfo=NULL,*ai;
  int              headerFlag,continuation,isEoS;
  int              compndCount,sourceCount;

  p=buffer;
  while(*p) {
    if     (!strncmp(p,"ATOM"  ,4)) numAtom++;
    else if(!strncmp(p,"HETATM",6)) numAtom++;
    else if(!strncmp(p,"COMPND",6)) headerFlag=3;       //  8 - 10 continuation,   11 - 80 compound
    else if(!strncmp(p,"SOURCE",6)) headerFlag=4;       //  8 - 10 continuation,   11 - 79 srcName
    else if(!strncmp(p,"ENDMDL",6)) break;
    else if(!strncmp(p,"END"   ,3)) break;
    p=str2nextline(p);
  }
  AllocP(coord, float,        3*(numAtom+1));
  AllocP(cpinfo,ObjComponentInfo,257);   /* Ribosome 50s subunit from E.coli (PDBID: 3OFD) contains only 31 different components */
  AllocP(kwinfo,ObjKeywordInfo,  257);   /* assuming max 257 keywords */
  AllocP(chinfo,ObjChainInfo,    257);   /* Look, chainid is only one char, 257 is for sure enough */
  AllocP(rsinfo,ObjResidueInfo,  (numAtom+1));
  AllocP(atinfo,ObjAtomInfo,     (numAtom+1));
  I->numComponent  = 0;         I->ComponentInfo = cpinfo;
  I->numKeyword    = 0;         I->KeywordInfo   = kwinfo;
  I->numChain      = 0;         I->ChainInfo     = chinfo;
  I->numResidue    = 0;         I->ResidueInfo   = rsinfo;
  I->numAtom       = numAtom;   I->AtomInfo      = atinfo; 
  I->Coord         = coord;

  p=buffer;
  componentCount=0;keywordCount=0;chainCount=0;resCount=0;atomCount=0;coordCount=0;
  comi=cpinfo+componentCount;   ObjComponentInit(comi);
  keyi=kwinfo+keywordCount;     ObjKeywordInit(keyi);
  ci=chinfo+chainCount;         ObjChainInit(ci);
  chain.index=-1;               chain.numResidue=0;     chain.numAtom=0;
//mi=moinfo+molCount;           ObjMoleculeInit(mi);
//mol.index=-1;                 mol.numResidue=0;
  ri=rsinfo+resCount;           ObjResidueInit(ri);
  res.index=-1;                 res.numAtom=0;
  while(*p) {
    if     (!strncmp(p,"ATOM"  ,4)) atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else {
      atomFlag=0;
      headerFlag=0;
      if     (!strncmp(p,"REMARK",6)) headerFlag=1;       //  8 - 10 remark type,    11 - 80 remark content
      else if(!strncmp(p,"TITLE ",6)) headerFlag=2;       //  9 - 10 continuation,   11 - 80 title
      else if(!strncmp(p,"COMPND",6)) headerFlag=3;       //  8 - 10 continuation,   11 - 80 compound
      else if(!strncmp(p,"SOURCE",6)) headerFlag=4;       //  8 - 10 continuation,   11 - 79 srcName
      else if(!strncmp(p,"KEYWDS",6)) headerFlag=5;       //  8 - 10 continuation,   11 - 79 srcName
      else if(!strncmp(p,"EXPDTA",6)) headerFlag=6;       //  9 - 10 continuation,   11 - 79 technique
      else if(!strncmp(p,"HEADER",6)) headerFlag=7;       // 11 - 50 classification, 51 - 59 depDate, 63 - 66 idCode
      else if(!strncmp(p,"ORIGX" ,5)) headerFlag=8;       // 11 - 20 On1, 21 - 30 On2, 31 - 40 On3, 46 - 55 Tn
      else if(!strncmp(p,"SCALE" ,5)) headerFlag=9;       // 11 - 20 Sn1, 21 - 30 Sn2, 31 - 40 Sn3, 46 - 55 Un
      else if(!strncmp(p,"CRYST" ,5)) headerFlag=10;      // 7-15a, 16-24b, 25-33c, 34-40alpha, 41-47beta, 48-54gamma, 56-66sGroup 
      else if(!strncmp(p,"ENDMDL",6)) break;
      else if(!strncmp(p,"END"   ,3)) break;
    }
    if(atomFlag) {
      ai=atinfo+atomCount;
      ai->index = atomCount;
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      ai->hetatm=(atomFlag==2) ? 1 : 0;
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&ai->id)!=1) ai->id=0;
      /* atom serial number in the pdbfile */
 
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(ai->realname,p,4);     /* read 13-16   name     */
      if(sscanf(ai->realname,"%s",ai->name)!=1) ai->name[0]=0;
      /* atom name, first 2 chars are element name, followed by atom id */
 
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      ai->alt=q[0];
      ai->numAltLoc=1;
      ai->AltLocStr[0]=ai->alt;
      ai->AltLocStr[1]=0;
      /* alternate location indicator, used with alternate chain id */
 
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      rescodeFlag = (q[2]==' ') ? 0 : 1;
      if(q[1]!=' ') rescodeFlag+=2;
      if(q[0]!=' ') rescodeFlag+=4;
      switch(rescodeFlag){              /* a fast way to assign residue 3-letter-code */
        case 0: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]='_';  break;
        case 1: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[2]; break;
        case 2: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[1]; break;
        case 3: res.resn[0]='_';  res.resn[1]=q[1]; res.resn[2]=q[2]; break;
        case 4: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[0]; break;
        case 5: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[2]; break;
        case 6: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[1]; break;
        case 7: res.resn[0]=q[0]; res.resn[1]=q[1]; res.resn[2]=q[2]; break;
      }
      res.resn[3]=0;
      /* residue name, three letter code */
 
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      chain.chainid=q[0];
      /* chain identifier, preserve original pdb chain ID here  */
 
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */

      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
      if (chain.chainid!=ci->chainid) {
        ci->numResidue += chain.numResidue;
        chain.numResidue= 0;
        chainFound      =-1;
        if (ci->index!=-1) {
          for(i=0;i<=chainCount;i++){
            ci=chinfo+i;
            if(chain.chainid==ci->chainid) chainFound=i;
          }
          if(chainFound==-1) chainCount++;
        }
        if(chainFound==-1) {
          ci=chinfo+chainCount;
          ObjChainInit(ci);
          ci->index     = chainCount;
          ci->chainid   = chain.chainid;
        } else ci=chinfo+chainFound;
      }
      ci->numAtom++;
      /* handling chain object creation and initiation */

      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        res.numAtom++;
      } else {
        ri->numAtom     = res.numAtom;
        VectorAverage3f(res.Center, res.numAtom);
        VectorCopy3f(ri->Center, res.Center);
        ObjResidueAssignAltLoc(ri);
        res.numAtom     = 1;
        VectorClear3f(res.Center);
        if (ri->index!=-1) resCount++;
        ri=rsinfo+resCount;
        ObjResidueInit(ri);
        ri->index       = resCount;
        ri->chain       = res.chain;
        ri->ChainInfo   = ci;
        str2ncpy(ri->resn,res.resn,ResidueNameLen);
        str2ncpy(ri->resi,res.resi,ResidueIdLen);
        ri->resid       = res.resid;
        ri->resi2       = res.resi2;
        ri->AtomInfo    = ai;
        chain.numResidue++;
      }
      /* handling residue object creation and initiation */
      ai->residue_index = resCount;
      ai->ResidueInfo   = ri;
      /* establish link between residue information and atom information */

      p=str2nskip(p,3);                 /* skip 28-30 */
      p=str2ncpy(q,p,8);                /* read 31-38   x        */
      sscanf(q,"%f",coord+coordCount);
      p=str2ncpy(q,p,8);                /* read 39-46   y        */
      sscanf(q,"%f",coord+(coordCount+1));
      p=str2ncpy(q,p,8);                /* read 47-54   z        */
      sscanf(q,"%f",coord+(coordCount+2));
      VectorAdd3f(res.Center, (coord+coordCount));
      /* orthogonal coordinates for X,Y,Z in angstroms */
 
      p=str2ncpy(q,p,6);                /* read 55-60   occupancy */
      if(sscanf(q,"%f",&ai->occup)!=1) ai->occup=1.0;
      /* occupancy, default to 1.0 if not recognized */
 
      p=str2ncpy(q,p,6);                /* read 61-66   tempFactor*/
      if(sscanf(q,"%f",&ai->b)!=1) ai->b=0.0;
      /* read the temperature factor B, default to 0.0 if not recognized */
 
      p=str2nskip(p,10);                /* skip 67-72 */
                                        /* skip 73-76   segID    */
      p=str2ncpy(q,p,2);                /* read 77-78   element  */
      if(!isalpha(q[0]) || !isalpha(q[1])) {
        ai->elem[0]=0;
        ai->elem[1]=0;
        if(isalpha(q[0]) && q[1]==' ' && index("CONHSP",q[0])) {
          ai->elem[0]=q[0]; str2ncpy(q,p,2);
          if(isdigit(q[1]) && (isdigit(q[0]) || q[0]==' ')) ai->elem[0]=0;
        }/* prevent PDB misuse */
        if(isalpha(q[1]) && q[0]==' ') ai->elem[0]=q[1];
      } else if(sscanf(q,"%s",ai->elem)!=1) ai->elem[0]=0;
      /* element symbol, right-justified */
 
      p=str2ncpy(q,p,2);                /* read 79-80   charge   */
      q[5]=0;
      if(isdigit(q[0])) {
        if (q[1]=='+' || q[1]=='-') { q[4]=q[1];q[1]=q[0];q[0]=q[4];q[2]=0;q[5]=1;
        } else if (q[1]==' ') { q[1]=0;q[5]=1; }
      } else if(isdigit(q[1])) {
        if(isdigit(q[0]) || q[0]=='+' || q[0]=='-') { q[5]=1;
        } else if (q[0]==' ') { q[0]=q[1];q[1]=0;q[5]=1; }
      }
      if (q[5]==1) { if(sscanf(q,"%f",&ai->q)!=1) ai->q=0.0f;
      } else ai->q=0.0f;
      /* charge on the atom, in PDB specification but not widely used in practice */

      ai->cavity_index  =-1;            ai->CavityInfo=NULL;
      ai->type          =ATOM_UNDEF;    ai->location  =ATOM_LOCATE_UNDEF;
      ai->asa           =-1;            ai->msa       =-1;
      ai->curvature     =0;             ai->vdw       =0.0f;
      ai->hydrogen      =0;             ai->protons   =0;
      ai->period        =0;             ai->group     =ELEM_GROUP_undef;
      ai->oxidation_state=0;            ai->bv_index  =-1;
      ai->numCovalentBond=0;            ai->isMetal   =-1;
      ai->numAtmNeighbor=0;             ai->AtmNeighborIndex=NULL;
      ai->center_displacement=0.0f;     AtomInfoAssignParameters(ai);
      /* Don't forget to do initiation of all other parameters that not yet been initiated yet */
      coordCount+=3;
      atomCount++;
    } else if(headerFlag) {
      p2=str2nextline(p);
      isEoS = strncmp(p2,p,6) ? 1 : 0;
      if (headerFlag <= 6) {
        p=str2nskip(p,7);
        p=str2ncpy(q,p,3);
        if(sscanf(q,"%d",&continuation)!=1) continuation=0;
      } else if (headerFlag >= 8) {
        p=str2nskip(p,5);
        p=str2ncpy(q,p,1);
        if(sscanf(q,"%d",&continuation)!=1) continuation=0;
        if(headerFlag!=10) p=str2nskip(p,4);
      } else {
        p=str2nskip(p,10);
      }
      switch(headerFlag) {
        case 1:  PDBheaderAssignRemark(I,p,continuation);       break;
        case 2:  PDBheaderAssignTitle (I,p,continuation,isEoS); break;
        case 3:  PDBheaderAssignCompnd(I,p,continuation,isEoS); break;
        case 4:  PDBheaderAssignSource(I,p,continuation,isEoS); break;
        case 5:  PDBheaderAssignKeywds(I,p,continuation,isEoS); break;
        case 6:  PDBheaderAssignExpdta(I,p,continuation);       break;
        case 7:  PDBheaderAssignHeader(I,p);                    break;
        case 8:  PDBheaderAssignOrigx (I,p,continuation);       break;
        case 9:  PDBheaderAssignScale (I,p,continuation);       break;
        case 10: PDBheaderAssignCryst (I,p,continuation);       break;
      }
    }
    p=str2nextline(p);
  }
  ai=atinfo+atomCount; ai->index=-1;
  if (ri->index!=-1) {
    ri->numAtom = res.numAtom;
    VectorAverage3f(res.Center, res.numAtom);
    VectorCopy3f(ri->Center, res.Center);
    ObjResidueAssignAltLoc(ri);
    resCount++;
    ri=rsinfo+resCount; ri->index=-1;
    I->numResidue= resCount;
  }
  if (ci->index!=-1) {
    ci->numResidue += chain.numResidue;
    chainCount++;
    ci=chinfo+chainCount; ci->index=-1;
    I->numChain= chainCount;
  }
  EntityMoleculeAssignType(I, aminoacid_dictionary);
  EntityMoleculeAssignCenterDisplacement(I);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadClusterStr(ObjEntityMolecule *I, char *buffer) {
  int           i,j,chainFlag,chainFound,ecFound,localCount,nonAlnumCount50=0,nonAlnumCount90=0;
  int           numGOProc=0,numGOFunc=0,numGOComp=0;
  int           nd,nf,numDomain=0,numFragment=0,domainCount,domainFound;
  char          *p,q[FileLineLength];
  ObjChainInfo  *ci,*cip,*cid;
  ObjDomainInfo *di;
  ObjComponentInfo    *comi;
  ObjFunctionInfo     *funi;
  ObjGeneOntologyInfo *goi;
  ObjCounter          *cnti;
  p=buffer;
  while(*p) {
    if     (!strncmp(p,"GOPROC ",7)) numGOProc++;
    else if(!strncmp(p,"GOFUNC ",7)) numGOFunc++;
    else if(!strncmp(p,"GOCOMP ",7)) numGOComp++;
    else if(!strncmp(p,"DOMALL ",7)) {
      p=str2nskip(p,10);
      if(sscanf(p,"D%dF%d",&nd,&nf)==2) {
        numDomain+=nd;
        numFragment+=nf;
      } else {
        PFatalError("invalid CLUSTER file format in DOMALL card.\n");
      }
    }
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    // Simple allocate more than enough space for each individual chain
    AllocP(ci->BiolProcessInfo,ObjGeneOntologyInfo,(numGOProc+1));
    AllocP(ci->MoleFunctionInfo,ObjGeneOntologyInfo,(numGOFunc+1));
    AllocP(ci->CellComponentInfo,ObjGeneOntologyInfo,(numGOComp+1));
  }
  AllocP(I->DomainInfo,ObjDomainInfo,(numDomain+numFragment+1));
  domainCount=0;
  I->numDomain = domainCount;
  di=I->DomainInfo+domainCount;
  ObjDomainInit(di);

  p=buffer;
  while(*p) {
    chainFlag=0;
    if     (!strncmp(p,"GOCOMP ",7)) chainFlag=8;
    else if(!strncmp(p,"GOFUNC ",7)) chainFlag=7;
    else if(!strncmp(p,"GOPROC ",7)) chainFlag=6;
    else if(!strncmp(p,"DOMAIN ",7)) chainFlag=5;
    else if(!strncmp(p,"DOMALL ",7)) chainFlag=4;
    else if(!strncmp(p,"CLUST90",7)) chainFlag=3;
    else if(!strncmp(p,"CLUST50",7)) chainFlag=2;
    else if(!strncmp(p,"SHORT  ",7)) chainFlag=1;
    else if(!strncmp(p,"PDBFILE",7)) {
      p=str2nskip(p,10);
      p=str2ncpy(q,p,6);
      if(sscanf(q,"%d",&I->pdbfileid)!=1) I->pdbfileid=0;
    } else if(!strncmp(p,"NOTABLE",7)) {
      p=str2nskip(p,10);
      p=str2ncpy(q,p,40);       // assume table name is less than 40 chars
      if     (!strncasecmp(q,"NEIGHBORHOOD",             12)) I->tables[TABLE_NEIGHBORHOOD]=0;
      else if(!strncasecmp(q,"USAGES",                    6)) I->tables[TABLE_USAGES]=0;
      else if(!strncasecmp(q,"COMMENTS",                  8)) I->tables[TABLE_COMMENTS]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_DICTIONARY",  23)) I->tables[TABLE_GENEONTOLOGY_DICTIONARY]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_RELATIONSHIP",25)) I->tables[TABLE_GENEONTOLOGY_RELATIONSHIP]=0;
      else if(!strncasecmp(q,"GENEONTOLOGY_REFERENCE",   22)) I->tables[TABLE_GENEONTOLOGY_REFERENCE]=0;
      else if(!strncasecmp(q,"EC_DICTIONARY",            13)) I->tables[TABLE_EC_DICTIONARY]=0;
      else if(!strncasecmp(q,"CATH_DICTIONARY",          15)) I->tables[TABLE_CATH_DICTIONARY]=0;
      else if(!strncasecmp(q,"AMINOACID_DICTIONARY",     20)) I->tables[TABLE_AMINOACID_DICTIONARY]=0;
      else if(!strncasecmp(q,"HETDICTIONARY",            13)) I->tables[TABLE_HETDICTIONARY]=0;
      else if(!strncasecmp(q,"PDBFILES",                  8)) PFatalError("PDBFILES table cannot be turned off");
      else if(!strncasecmp(q,"CCDINFO",                   7)) I->tables[TABLE_CCDINFO]=0;
      else if(!strncasecmp(q,"GENEONTOLOGIES",           14)) I->tables[TABLE_GENEONTOLOGIES]=0;
      else if(!strncasecmp(q,"ASSEMBLIES",               10)) I->tables[TABLE_ASSEMBLIES]=0;
      else if(!strncasecmp(q,"CAVITIES",                  8)) I->tables[TABLE_CAVITIES]=0;
      else if(!strncasecmp(q,"COMPONENTS",               10)) I->tables[TABLE_COMPONENTS]=0;
      else if(!strncasecmp(q,"FUNCTIONS",                 9)) I->tables[TABLE_FUNCTIONS]=0;
      else if(!strncasecmp(q,"KEYWORDS",                  8)) I->tables[TABLE_KEYWORDS]=0;
      else if(!strncasecmp(q,"CDHIT_CHAINS",             12)) I->tables[TABLE_CDHIT_CHAINS]=0;
      else if(!strncasecmp(q,"SYMOP_CHAINS",             12)) I->tables[TABLE_SYMOP_CHAINS]=0;
      else if(!strncasecmp(q,"MOLECULES",                 9)) I->tables[TABLE_MOLECULES]=0;
      else if(!strncasecmp(q,"DOMAINS",                   7)) I->tables[TABLE_DOMAINS]=0;
      else if(!strncasecmp(q,"RESIDUES",                  8)) I->tables[TABLE_RESIDUES]=0;
      else if(!strncasecmp(q,"ATOMS",                     5)) I->tables[TABLE_ATOMS]=0;
      else if(!strncasecmp(q,"NEIGHBORS",                 9)) I->tables[TABLE_NEIGHBORS]=0;
      else if(!strncasecmp(q,"ATOMNEIGHBORS",            13)) I->tables[TABLE_ATOMNEIGHBORS]=0;
      else if(!strncasecmp(q,"LIGAND_BONDANGLES",        17)) I->tables[TABLE_LIGAND_BONDANGLES]=0;
      else if(!strncasecmp(q,"ION_BONDVALENCES",         16)) I->tables[TABLE_ION_BONDVALENCES]=0;
      else if(!strncasecmp(q,"WATER_BONDVALENCES",       18)) I->tables[TABLE_WATER_BONDVALENCES]=0;
      else if(!strncasecmp(q,"ION_BINDINGSITES",         16)) I->tables[TABLE_ION_BINDINGSITES]=0;
    }
    if(chainFlag) {
      p=str2nskip(p,8);
      p=str2ncpy(q,p,1);
      if(q[0]=='_') q[0]=' ';
      chainFound=-1;
      for(i=0;i<I->numChain;i++){
        ci=I->ChainInfo+i;
        if(ci->chainid==q[0]) chainFound=i;
      } /* loop around to find the same chain_id */
      if(chainFound==-1) {
        localCount=0;
        for(i=0;i<I->numChain;i++){
          ci=I->ChainInfo+i;
          if(!isalnum(ci->chainid)) {
            if(chainFlag==3){
              if(localCount==nonAlnumCount90) { if(chainFound==-1) { chainFound=i; nonAlnumCount90++; } } else localCount++;
            }else if(chainFlag==2){
              if(localCount==nonAlnumCount50) { if(chainFound==-1) { chainFound=i; nonAlnumCount50++; } } else localCount++;
            }
          }
        }
      } /* loop around to find the next unclaimed chain_id */
      if(chainFound!=-1) {
        ci=I->ChainInfo+chainFound;
        switch(chainFlag) {
          case 1: ci->clusterstatus=CHAIN_CLUSTER_SHORT;
                  break;
          case 2:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->cluster50_id)!=1) ci->cluster50_id=-1;
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->represent50_id)!=1) ci->represent50_id=-1;
            if(ci->clusterstatus<CHAIN_CLUSTER_CLUSTERED){
              ci->clusterstatus = (ci->represent50_id==1) ? CHAIN_CLUST50_REPRESENT : CHAIN_CLUSTER_CLUSTERED;
            };    break;
          case 3:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->cluster90_id)!=1) ci->cluster90_id=-1;
            p=str2ncpy(q,p,6);
            if(sscanf(q,"%d",&ci->represent90_id)!=1) ci->represent90_id=-1;
            if(ci->clusterstatus<CHAIN_CLUSTER_CLUSTERED){
              ci->clusterstatus = (ci->represent90_id==1) ? CHAIN_CLUST90_REPRESENT : CHAIN_CLUSTER_CLUSTERED;
            };    break;
          case 4:
            p=str2nskip(p,1);
            p=str2ncpy(q,p,6);
            if(sscanf(q,"D%dF%d",&nd,&nf)==2) {
              ci->numDomain=nd;
              ci->numFragment=nf;
              ci->DomainInfo=di;
              for(i=0;i<nd;i++) {
                di->index=domainCount;
                di->chain=ci->chainid;
                di->is_fragment=0;
                domainCount++;
                di=I->DomainInfo+domainCount;
                ObjDomainInit(di);
              }
              for(i=0;i<nf;i++) {
                di->index=domainCount;
                di->chain=ci->chainid;
                di->is_fragment=1;
                domainCount++;
                di=I->DomainInfo+domainCount;
                ObjDomainInit(di);
              }
            }
                  break;
          case 5:
            di=ci->DomainInfo;
            domainFound=0;
            for(i=0;i<ci->numDomain;i++) {
              di=ci->DomainInfo+i;
              if(di->domainnum==-1) {
                domainFound=1;
                break;
              }
            }
            if(domainFound) {
              p=str2nskip(p,1);
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->domainnum)!=1)        di->domainnum=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&nd)!=1)                   nd=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_primary)!=1)     di->cath_primary=0;
              di->cath_primary+=(nd*1000);
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_topology)!=1)    di->cath_topology=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_superfamily)!=1) di->cath_superfamily=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s35)!=1)         di->cath_s60=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s60)!=1)         di->cath_s60=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s95)!=1)         di->cath_s95=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_s100)!=1)        di->cath_s100=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->cath_uniqueid)!=1)    di->cath_uniqueid=0;
              p=str2ncpy(q,p,6); if (sscanf(q,"%d",&di->numResidue)!=1)       di->numResidue=0;
            } else {
              PFatalError("Cannot locate corresponding DOMALL from DOMAIN card in CLUSTER file.\n");
            }
                  break;
          case 6:
          case 7:
          case 8:
            if     (chainFlag==6) { goi=ci->BiolProcessInfo  +ci->numBiolProcess;   ObjGeneOntologyInit(goi,'P',ci->numBiolProcess);   ci->numBiolProcess++;   }
            else if(chainFlag==7) { goi=ci->MoleFunctionInfo +ci->numMoleFunction;  ObjGeneOntologyInit(goi,'F',ci->numMoleFunction);  ci->numMoleFunction++;  }
            else if(chainFlag==8) { goi=ci->CellComponentInfo+ci->numCellComponent; ObjGeneOntologyInit(goi,'C',ci->numCellComponent); ci->numCellComponent++; }
            goi->chain=ci->chainid;
            p=str2ncpy(q,p,7);   if(sscanf(q,"%d",&goi->go_id)!=1)        goi->go_id=-1;
            p=str2ncpy(q,p,6);   if(sscanf(q,"%d",&goi->qualifier)!=1)    goi->qualifier=0;
            p=str2ncpy(q,p,6);   if(sscanf(q,"%s",goi->evidence)!=1)      goi->evidence[0]=0;
            p=str2ncpy(q,p,12);  if(sscanf(q,"%s",goi->xref_db_name)!=1)  goi->xref_db_name[0]=0;
            p=str2ncpy(q,p,18);  if(sscanf(q,"%s",goi->xref_db_id)!=1)    goi->xref_db_id[0]=0;
            p=str2ncpy(q,p,9);   if(sscanf(q,"%d",&goi->organism_id)!=1)  goi->organism_id=-1;
            p=str2ncpy(q,p,9);   if(sscanf(q,"%s",goi->creation_date)!=1) goi->creation_date[0]=0;
            p=str2ncpy(q,p,18);  if(sscanf(q,"%s",goi->created_by)!=1)    goi->created_by[0]=0;
            p=str2ccpy(q,p,':'); if     (!strncasecmp(q,"GO_REF",6))      goi->ref_db_name='G';
                                 else if(!strncasecmp(q,"PMID",  4))      goi->ref_db_name='P';
                                 else if(!strncasecmp(q,"DOI",   3))      goi->ref_db_name='D';
                                 if(goi->ref_db_name=='G' || goi->ref_db_name=='P') {
            p=str2ncpy(q,p,30);  if(sscanf(q,"%d",&goi->ref_db_id)!=1)    goi->ref_db_id=-1;
                                 } else if(goi->ref_db_name=='D')         goi->ref_db_id=-1;
                  break;
        }
      }
    }
    p=str2nextline(p);
  }
  I->numDomain = domainCount;
  /* The follow sections are deserved for calculation of fields in ccdinfo table */
  /* Take the EC number from most populated function in all components tables
   * Take corresponding ec_3rd_level, ec_4th_level, if any */
  cnti=counterNew(256);
  for(i=0;i<I->numComponent;i++) {
    comi=I->ComponentInfo+i;
    for(j=0;j<comi->numFunction;j++) {
      funi=comi->FunctionInfo+j;
      counterAddRecord(cnti,funi->ec_primary);
    }
  }
  I->ec_primary=counterMostPopular(cnti);
  if(I->ec_primary>=100 && I->ec_primary<700) {
    ecFound=0;
    for(i=0;i<I->numComponent;i++) {
      comi=I->ComponentInfo+i;
      for(j=0;j<comi->numFunction;j++) {
        funi=comi->FunctionInfo+j;
        if(funi->ec_primary==I->ec_primary) {
          ecFound=1;
          break;
        }
      }
      if(ecFound) break;
    }
    if(ecFound) {
      I->ec_3rd_level=funi->ec_3rd_level;
      I->ec_4th_level=funi->ec_4th_level;
    } else {
      PFatalError("EC primary found, but cannot be matched due to inconsistency.\n");
    }
  }
  counterFree(cnti);
  /* Find the longest protein or DNA chain, if of equal length, protein chain is used */
  cip=I->ChainInfo;
  cid=I->ChainInfo;
  for(i=1;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    ci->numGeneOntology=ci->numBiolProcess+ci->numMoleFunction+ci->numCellComponent;
    if(ci->numProteinRes > cip->numProteinRes) cip=ci;
    if(ci->numDnarnaRes  > cid->numDnarnaRes)  cid=ci;
  }
  /* Take the longest chain for clusterid of the whole entry */
  ci = (cip->numProteinRes >= cid->numDnarnaRes) ? cip : cid;   // Take the longest chain
  I->cluster50_id=ci->cluster50_id;
  I->cluster90_id=ci->cluster90_id;
  /* From the longest chain,
   * Take the GO taxon as the organism_id,
   * If no data captured, Take the TAXID from most populated Component */
  cnti=counterNew(256);
  for(i=0;i<ci->numBiolProcess;i++)   { goi=ci->BiolProcessInfo+i;   counterAddRecord(cnti,goi->organism_id); }
  for(i=0;i<ci->numMoleFunction;i++)  { goi=ci->MoleFunctionInfo+i;  counterAddRecord(cnti,goi->organism_id); }
  for(i=0;i<ci->numCellComponent;i++) { goi=ci->CellComponentInfo+i; counterAddRecord(cnti,goi->organism_id); }
  I->organism_id=counterMostPopular(cnti);
  counterFree(cnti);
  if(I->organism_id==-1) {
    cnti=counterNew(256);
    for(i=0;i<I->numComponent;i++) {
      comi=I->ComponentInfo+i;
      counterAddRecord(cnti,comi->organism_id);
    }
    I->organism_id=counterMostPopular(cnti);
    counterFree(cnti);
  }
  /* From the longest chain,
   * Take the GO term with min go_id,
   * supposedly to be a more general term */
  I->go_process  =ObjGeneOntologyMinimalID(ci->BiolProcessInfo,  ci->numBiolProcess);
  I->go_function =ObjGeneOntologyMinimalID(ci->MoleFunctionInfo, ci->numMoleFunction);
  I->go_component=ObjGeneOntologyMinimalID(ci->CellComponentInfo,ci->numCellComponent);
  /* From the longest chain,
   * Take the CATH class with max CATH_primary,
   * supposedly to be a more complicated domain archetecture */
  for(i=0;i<ci->numDomain;i++){
    di = ci->DomainInfo+i;
    if(di->cath_primary>I->cath_primary) {
      I->cath_primary    =di->cath_primary;
      I->cath_topology   =di->cath_topology;
      I->cath_superfamily=di->cath_superfamily;
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadAssemblyStrOld(ObjEntityMolecule *I, char *buffer_surface, char* data_dir) {
  EntityFileName file_path;
  FILE           *f;
  char*          buffer=NULL;
  int            i,keyFlag;
  char           chainid;
  int            tempint,current_assembly_id=-1;
  int            numAssembly=0,numMacroChain=0,numSymChain=0,numChain;
  int            assCount,symCount,cavityCount=0;
  char           *p,q[FileLineLength];
  ObjAssemblyInfo*assinfo=NULL,*assi;
  ObjSymChainInfo*syminfo=NULL,*symi;
  ObjChainInfo   *ci;
  ObjResidueInfo *ri;
  p=buffer_surface;
  while(*p) {
    if(!strncmp(p,"ASSEMBLY",8)) numAssembly++;
    else if(!strncmp(p,"SYMCHAIN",8)) numSymChain++;
    else if(!strncmp(p,"CHAIN   ",8)) {
      p=str2nskip(p,9);
      chainid=p[0];
      for(i=0;i<I->numChain;i++){
        ci=I->ChainInfo+i;
        if(ci->chainid==chainid) ci->claimed++;
      }
    }
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    if(ci->type2>=CHAIN_TYPE2_DNARNA) numMacroChain++;
  }
  AllocP(assinfo,ObjAssemblyInfo,(numAssembly+1));
  I->numAssembly        = numAssembly;
  I->AssemblyInfo       = assinfo;
  AllocP(syminfo,ObjSymChainInfo,(numSymChain+1));

  p=buffer_surface;
  assCount=0;
  assi=assinfo+assCount;
  assi->index=-1;
  symCount=0;
  symi=syminfo+symCount;
  symi->index=-1;
  while(*p) {
    keyFlag=0;
    chainid=0;
//  str2printline(p);
    if(!strncmp(p,"ASSEMBLY",8))      keyFlag=1; 
    else if(!strncmp(p,"SURFRESL",8)) keyFlag=2; 
    else if(!strncmp(p,"SURFDATA",8)) keyFlag=3; 
    else if(!strncmp(p,"TOTALASA",8)) keyFlag=4; 
    else if(!strncmp(p,"POLARASA",8)) keyFlag=5; 
    else if(!strncmp(p,"POSITASA",8)) keyFlag=6; 
    else if(!strncmp(p,"NEGATASA",8)) keyFlag=7; 
    else if(!strncmp(p,"TBACKASA",8)) keyFlag=8; 
    else if(!strncmp(p,"PBACKASA",8)) keyFlag=9; 
    else if(!strncmp(p,"TOTALMSA",8)) keyFlag=10;
    else if(!strncmp(p,"POLARMSA",8)) keyFlag=11;
    else if(!strncmp(p,"POSITMSA",8)) keyFlag=12;
    else if(!strncmp(p,"NEGATMSA",8)) keyFlag=13;
    else if(!strncmp(p,"TBACKMSA",8)) keyFlag=14;
    else if(!strncmp(p,"PBACKMSA",8)) keyFlag=15;
    else if(!strncmp(p,"NUMATOMS",8)) keyFlag=16;
    else if(!strncmp(p,"NUMCHAIN",8)) keyFlag=17;
    else if(!strncmp(p,"CHAIN   ",8)) keyFlag=18;
    else if(!strncmp(p,"SYMCHAIN",8)) keyFlag=19;
    else if(!strncmp(p,"ENDASSEM",8)) keyFlag=20;

    if(keyFlag) {
      p=str2nskip(p,9);
      if(keyFlag==18 || keyFlag==19) {
        chainid=p[0];
        p=str2nskip(p,1);
        if(keyFlag==18) p=str2wcpy(q,p);
      } else {
        p=str2wcpy(q,p);
      }

      switch(keyFlag) {
        case 1:  if(sscanf(q,"%d",&current_assembly_id)!=1) current_assembly_id=-1;
                 if (assi->index!=-1) assCount++;
                 assi=assinfo+assCount; numChain=0; // numMacroChain in assembly
                 assi->index=assCount;  assi->type=ASSEMBLY_UNDEF;
                 assi->total_asa=0;     assi->polar_asa=0;
                 assi->positive_asa=0;  assi->negative_asa=0;
                 assi->total_bb_asa=0;  assi->polar_bb_asa=0;
                 assi->total_msa=0;     assi->polar_msa=0;
                 assi->positive_msa=0;  assi->negative_msa=0;
                 assi->total_bb_msa=0;  assi->polar_bb_msa=0;
                 assi->numChain=0;      assi->numSymChain=0;
                 assi->numCavity=0;     assi->numSurfraceAtom=0; 
                 assi->CavityInfo=NULL; assi->SymChainInfo=NULL;
                 break;
        case 2:  break;
        case 3:  if (!strncmp(q,"NONE",4)) {
                   strcpy(file_path,q);
                 } else if (strlen(data_dir) > 0) {
                   strcpy(file_path,data_dir);
                   strcat(file_path,q);
                   /* NOTE: atomwise surface data processing is delayed till the end of assembly entity */
              }; break;
        case 4:  if(sscanf(q,"%f",&assi->total_asa   )!=1)   assi->total_asa   =0;   break;
        case 5:  if(sscanf(q,"%f",&assi->polar_asa   )!=1)   assi->polar_asa   =0;   break;
        case 6:  if(sscanf(q,"%f",&assi->positive_asa)!=1)   assi->positive_asa=0;   break;
        case 7:  if(sscanf(q,"%f",&assi->negative_asa)!=1)   assi->negative_asa=0;   break;
        case 8:  if(sscanf(q,"%f",&assi->total_bb_asa)!=1)   assi->total_bb_asa=0;   break;
        case 9:  if(sscanf(q,"%f",&assi->polar_bb_asa)!=1)   assi->polar_bb_asa=0;   break;
        case 10: if(sscanf(q,"%f",&assi->total_msa   )!=1)   assi->total_msa   =0;   break;
        case 11: if(sscanf(q,"%f",&assi->polar_msa   )!=1)   assi->polar_msa   =0;   break;
        case 12: if(sscanf(q,"%f",&assi->positive_msa)!=1)   assi->positive_msa=0;   break;
        case 13: if(sscanf(q,"%f",&assi->negative_msa)!=1)   assi->negative_msa=0;   break;
        case 14: if(sscanf(q,"%f",&assi->total_bb_msa)!=1)   assi->total_bb_msa=0;   break;
        case 15: if(sscanf(q,"%f",&assi->polar_bb_msa)!=1)   assi->polar_bb_msa=0;   break;
        case 16: if(sscanf(q,"%d",&assi->numSurfraceAtom)!=1)assi->numSurfraceAtom=0;break;
        case 17: if(sscanf(q,"%d",&assi->numChain    )!=1)   assi->numChain=0;       break;
        case 18: /* if(sscanf(q,"%d",&tempint)!=1) tempint=-1; if(tempint>=4) numChain++; */
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->chainid==chainid){
                     ci->assembly_index=assCount;
                     ci->AssemblyInfo=assi;
                     if(ci->type2>=CHAIN_TYPE2_DNARNA) numChain++;
                   }
              }; break;
        case 19: assi->numSymChain++;
                 if (assi->SymChainInfo==NULL) assi->SymChainInfo=symi;
                 if (symi->index!=-1) symCount++;
                 symi=syminfo+symCount;
                 symi->index=symCount;
                 symi->cdhit_chainid=chainid;
                 symi->assembly_index=assCount;
                 symi->AssemblyInfo=assi;
                 break;
        case 20: if(assi->numSymChain==0) assi->SymChainInfo=NULL;
                 if(assi->numSymChain) {
                   assi->type = (numChain==numMacroChain) ? ASSEMBLY_BIGGER : ASSEMBLY_OVERLAP;
                 } else {
                   assi->type = (numChain==numMacroChain) ? ASSEMBLY_EQUAL : ASSEMBLY_SMALLER;
                 }
                 if (!strncmp(file_path,"NONE",4)) break;
                 if (strlen(data_dir) > 0) {
                   f=fopen(file_path,"rb");
                   if (!f) { PFatalError("invalid SURFFILE name\n"); };
                   buffer=str2cachetextfile(f);
                   cavityCount=EntityAssemblyReadSurfaceStrOld(assi, buffer, assCount, cavityCount, I);
                   FreeP(buffer);
              }; break;
      }
    }
    p=str2nextline(p);
  }
  assCount++;   assi=assinfo+assCount;  assi->index=-1;
  symCount++;   symi=syminfo+symCount;  symi->index=-1;

  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ri->assembly_index=ri->ChainInfo->assembly_index;
    ri->AssemblyInfo  =ri->ChainInfo->AssemblyInfo;
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReadAssemblyStr(ObjEntityMolecule *I, char *buffer_buheader, char* data_dir) {
  EntityFileName file_path;
  FILE           *f;
  char*          buffer=NULL;
  int            i,keyFlag,resFound;
  char           chainid;
  int            tempint,current_assembly_id=-1;
  int            numAssembly=0,numMacroChain=0,numSymChain=0,numCavityResidue=0,numAssemblyChain,numAssUniqueChain;
  int            assCount,symCount,cavityCount=0;
  char           *p,q[FileLineLength],msg[FileLineLength];
  ObjAssemblyInfo*assinfo=NULL,*assi;
  ObjCavityInfo  *cavinfo=NULL,*cavi;
  ObjSymChainInfo*syminfo=NULL,*symi,symchain;
  int            *residue_indices=NULL;
  ObjChainInfo   *ci;
  ObjResidueInfo *ri,res;
  p=buffer_buheader;
  while(*p) {
    if(!strncmp(p,"ASSEMBLY",8)) numAssembly++;
    else if(!strncmp(p,"CHAIN",5)) numSymChain++;
    else if(!strncmp(p,"CAVERESI",8)) numCavityResidue++;
    p=str2nextline(p);
  }
  for(i=0;i<I->numChain;i++){
    ci=I->ChainInfo+i;
    if(ci->type2>=CHAIN_TYPE2_DNARNA) numMacroChain++;
  }
  AllocP(assinfo,ObjAssemblyInfo,(numAssembly+1));
  I->numAssembly        = numAssembly;
  I->AssemblyInfo       = assinfo;
  AllocP(cavinfo,ObjCavityInfo,(numAssembly+1));
  AllocP(syminfo,ObjSymChainInfo,(numSymChain+1));

  p=buffer_buheader;
  assCount=0;
  assi=assinfo+assCount;
  assi->index=-1;
  cavityCount=0;
  cavi=cavinfo+cavityCount;
  cavi->index=-1;
  symCount=0;
  symi=syminfo+symCount;
  symi->index=-1;
  file_path[0]=0;
  while(*p) {
    keyFlag=0;
    chainid=0;
//  str2printline(p);
    if(!strncmp(p,"ASSEMBLY",8))      keyFlag=1; 
    else if(!strncmp(p,"CAVERESI",8)) keyFlag=2; 
    else if(!strncmp(p,"CAVESIZE",8)) keyFlag=3; 
    else if(!strncmp(p,"TOTALASA",8)) keyFlag=4; 
    else if(!strncmp(p,"POLARASA",8)) keyFlag=5; 
    else if(!strncmp(p,"POSITASA",8)) keyFlag=6; 
    else if(!strncmp(p,"NEGATASA",8)) keyFlag=7; 
    else if(!strncmp(p,"TBACKASA",8)) keyFlag=8; 
    else if(!strncmp(p,"PBACKASA",8)) keyFlag=9; 
    else if(!strncmp(p,"TOTALMSA",8)) keyFlag=10;
    else if(!strncmp(p,"POLARMSA",8)) keyFlag=11;
    else if(!strncmp(p,"POSITMSA",8)) keyFlag=12;
    else if(!strncmp(p,"NEGATMSA",8)) keyFlag=13;
    else if(!strncmp(p,"TBACKMSA",8)) keyFlag=14;
    else if(!strncmp(p,"PBACKMSA",8)) keyFlag=15;
    else if(!strncmp(p,"NUMATOMS",8)) keyFlag=16;
    else if(!strncmp(p,"NUMCHAIN",8)) keyFlag=17;
    else if(!strncmp(p,"CHAIN",5))    keyFlag=18;
    else if(!strncmp(p,"APDBFILE",8)) keyFlag=19; 
    else if(!strncmp(p,"PMOLFILE",8)) keyFlag=20; 
    else if(!strncmp(p,"SITEFILE",8)) keyFlag=21; 
    else if(!strncmp(p,"SURFDATA",8)) keyFlag=22; 
    else if(!strncmp(p,"ENDASSEM",8)) keyFlag=23;

    if(keyFlag) {
      if(keyFlag==2) {    // 1. In the case of CAVERESI, multiple parameters need to be read into res object
        p=str2nskip(p,9);
        p=str2ncpy(q,p,1);      // residue's chainid
        res.chain=q[0];

        p=str2nskip(p,1);
        p=str2ncpy(q,p,4);      // resseq
        if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
        if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;

        p=str2nskip(p,1);
        p=str2ncpy(q,p,3);      // resname
        if ((q[0]==' ') || (q[1]==' ') || (q[2]==' ')) { PFatalError("Only 3-letter-aa-code is expected in header file CAVERESI record.\n"); };
        res.resn[0]=q[0]; res.resn[1]=q[1]; res.resn[2]=q[2]; res.resn[3]=0;

      } if(keyFlag==18) { // 2. In the case of CHAIN, multiple parameters need to be read into symchain object
        p=str2nskip(p,5);
        p=str2ncpy(q,p,3);      // model_number
        if(sscanf(q,"%d",&symchain.model_number)!=1) symchain.model_number=-9999;

        p=str2nskip(p,1);
        p=str2ncpy(q,p,1);      // cdhit_chainid
        symchain.cdhit_chainid=q[0];

        p=str2nskip(p,1);
        p=str2ncpy(q,p,1);      // symop_chainid
        symchain.symop_chainid=q[0];

      } else {            // 3. For all other cases, one-word parameter is read into q for further processing
        p=str2nskip(p,9);
        p=str2wcpy(q,p);
      }

      switch(keyFlag) {
        case 1:  if(sscanf(q,"%d",&current_assembly_id)!=1) current_assembly_id=-1;
                 if (assi->index!=-1) assCount++;
                 assi=assinfo+assCount;
                 numAssemblyChain=0;            numAssUniqueChain=0; // numMacroChain in assembly
                 assi->index=assCount;          assi->assembly_number=current_assembly_id;
                 assi->type=ASSEMBLY_UNDEF;
                 assi->total_asa=0;             assi->polar_asa=0;
                 assi->positive_asa=0;          assi->negative_asa=0;
                 assi->total_bb_asa=0;          assi->polar_bb_asa=0;
                 assi->total_msa=0;             assi->polar_msa=0;
                 assi->positive_msa=0;          assi->negative_msa=0;
                 assi->total_bb_msa=0;          assi->polar_bb_msa=0;
                 assi->numChain=0;              assi->numSymChain=0;
                 assi->numCavity=0;             assi->numSurfraceAtom=0; 
                 assi->CavityInfo=NULL;         assi->SymChainInfo=NULL;
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   ci->claimed=0;
                 }
                 strcpy(file_path,"NONE");
                 break;
        case 2:  resFound=-1;
                 for(i=0;i<I->numResidue;i++) {
                   ri=I->ResidueInfo+i;
                   if (res.chain==ri->chain && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                     resFound=i; break;
                   }
                 }
                 if (resFound != -1) {
                   if (ri->location < RESIDUE_LOCATE_SDCAVITY) { ri->location += RESIDUE_LOCATE_SDCAVITY; }
                   if (assi->CavityInfo == NULL) {
                     if (cavi->index!=-1) cavityCount++;
                     cavi=cavinfo+cavityCount;      
                     cavi->index=cavityCount;   cavi->assembly_index=assCount;
                     cavi->AssemblyInfo=assi;   cavi->numResidue=0;
                     AllocP(residue_indices,int,(numCavityResidue+1));
                     cavi->residue_indices=residue_indices;
                     cavi->residue_indices[0]=-1;
                     cavi->numAtom=0;           cavi->volume=0;
                     assi->CavityInfo=cavi;     assi->numCavity=1;
                   }
                   cavi->residue_indices[cavi->numResidue]=resFound;
                   cavi->numResidue++;
                   cavi->residue_indices[cavi->numResidue]=-1;
                 } else {
                   sprintf(msg,"Failed to locate residue %c:%s %d from CAVERESI record.\n",res.chain,res.resn,res.resid);
                   PWarning(msg);
                 }
                 break;
        case 3:  if(sscanf(q,"%d",&cavi->volume      )!=1)   cavi->volume=0;         break;
        case 4:  if(sscanf(q,"%f",&assi->total_asa   )!=1)   assi->total_asa   =0;   break;
        case 5:  if(sscanf(q,"%f",&assi->polar_asa   )!=1)   assi->polar_asa   =0;   break;
        case 6:  if(sscanf(q,"%f",&assi->positive_asa)!=1)   assi->positive_asa=0;   break;
        case 7:  if(sscanf(q,"%f",&assi->negative_asa)!=1)   assi->negative_asa=0;   break;
        case 8:  if(sscanf(q,"%f",&assi->total_bb_asa)!=1)   assi->total_bb_asa=0;   break;
        case 9:  if(sscanf(q,"%f",&assi->polar_bb_asa)!=1)   assi->polar_bb_asa=0;   break;
        case 10: if(sscanf(q,"%f",&assi->total_msa   )!=1)   assi->total_msa   =0;   break;
        case 11: if(sscanf(q,"%f",&assi->polar_msa   )!=1)   assi->polar_msa   =0;   break;
        case 12: if(sscanf(q,"%f",&assi->positive_msa)!=1)   assi->positive_msa=0;   break;
        case 13: if(sscanf(q,"%f",&assi->negative_msa)!=1)   assi->negative_msa=0;   break;
        case 14: if(sscanf(q,"%f",&assi->total_bb_msa)!=1)   assi->total_bb_msa=0;   break;
        case 15: if(sscanf(q,"%f",&assi->polar_bb_msa)!=1)   assi->polar_bb_msa=0;   break;
        case 16: if(sscanf(q,"%d",&assi->numSurfraceAtom)!=1)assi->numSurfraceAtom=0;break;
        case 17: if(sscanf(q,"%d",&assi->numChain    )!=1)   assi->numChain=0;       break;
        case 18: // create symop chain records
                 if (symi->index!=-1) symCount++;
                 symi=syminfo+symCount;
                 symi->index=symCount;
                 symi->model_number=symchain.model_number;
                 symi->cdhit_chainid=symchain.cdhit_chainid;
                 symi->symop_chainid=symchain.symop_chainid;
                 symi->assembly_index=assCount;
                 symi->AssemblyInfo=assi;
                 // assign pointer for assembly
                 if (assi->SymChainInfo==NULL) assi->SymChainInfo=symi;
                 assi->numSymChain++;
                 // assign assembly_index and pointer for real chains
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->chainid==symchain.cdhit_chainid){
                     if (ci->AssemblyInfo==NULL) {
                       ci->assembly_index=assCount;
                       ci->AssemblyInfo=assi;
                     }
                     ci->claimed++;
                   }
                 }
                 break;
        case 19:        // APDBFILE record is not being processed
                 break;
        case 20:        // PMOLFILE record is not being processed
                 break;
        case 21:        // SITEFILE record is not being processed
                 break;
        case 22: if (q[0]=='/') {
                   strcpy(file_path,q);
                 } else if (!strncmp(q,"NONE",4)) {
                   strcpy(file_path,q);
                 } else if (strlen(data_dir) > 0) {
                   strcpy(file_path,data_dir);
                   strcat(file_path,q);
                   /* NOTE: atomwise surface data processing is delayed till the end of assembly entity */
              }; break;
        case 23: if(assi->numSymChain==0) assi->SymChainInfo=NULL;
                 for(i=0;i<I->numChain;i++){
                   ci=I->ChainInfo+i;
                   if(ci->type2>=CHAIN_TYPE2_DNARNA && ci->claimed) {
                     numAssemblyChain+=ci->claimed;
                     numAssUniqueChain++;
                   }
                 }
                 if(numAssemblyChain > numAssUniqueChain) {
                   assi->type = (numAssUniqueChain==numMacroChain) ? ASSEMBLY_BIGGER : ASSEMBLY_OVERLAP;
                 } else {
                   assi->type = (numAssUniqueChain==numMacroChain) ? ASSEMBLY_EQUAL : ASSEMBLY_SMALLER;
                 }
                 if (!strncmp(file_path,"NONE",4)) break;
                 if (strlen(file_path) > 0) {
                   f=fopen(file_path,"rb");
                   if (!f) {
                     sprintf(msg, "invalid SURFFILE name (%s)\n", I->pdbid);
                     PWarning(msg);
                     return;
                   };
                   buffer=str2cachetextfile(f);
                   EntityAssemblyReadSurfaceStr(assi, buffer, assCount, I);
                   FreeP(buffer);
              }; break;
      }
    }
    p=str2nextline(p);
  }
  if (assi->index!=-1) assCount++;    assi=assinfo+assCount;    assi->index=-1;
  if (symi->index!=-1) symCount++;    symi=syminfo+symCount;    symi->index=-1;
  if (cavi->index!=-1) cavityCount++; cavi=cavinfo+cavityCount; cavi->index=-1;

  if(assCount>0) {      // Only if at least one assembly record is detected
    for(i=0;i<I->numResidue;i++) {
      ri=I->ResidueInfo+i;
      ri->assembly_index=ri->ChainInfo->assembly_index;
      ri->AssemblyInfo  =ri->ChainInfo->AssemblyInfo;
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityAssemblyReadSurfaceStr(ObjAssemblyInfo *assi, char *buffer, int assCount, ObjEntityMolecule *I) {
  int           i,j,atomFlag,rescodeFlag;
  int           resCount,atomCount,resFound,atomFound;
  char          *p,q[FileLineLength],msg[FileLineLength],line[FileLineLength];
  ObjChainInfo  *ci;
  ObjSymChainInfo*symi;
  ObjResidueInfo*ri,res;
  ObjAtomInfo   *ai,*ai_cavity,atom;
  int           exact_match=0,cavity_record=0;
  char          chainid_from=0,chainid_to=0;

  p=buffer;
  resCount=0;
  ri=I->ResidueInfo+resCount;
  atomCount=-1;
  while(*p) {
//  str2ncpy(line,p,FileLineLength);
    atomFlag=-1;
    if(!strncmp(p,"ATOM",4))        atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else if(!strncmp(p,"CAVITY",6)) atomFlag=0;
//  str2printline(p);
    if(atomFlag>=1) {
/* STEP ONE: parse character 1-17 and store information in 'atom' object */
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&atom.id)!=1) atom.id=0;
      /* atom serial number in the pdbfile */
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(atom.realname,p,4);     /* read 13-16   name     */
      if(sscanf(atom.realname,"%s",atom.name)!=1) atom.name[0]=0;
      for(i=0;i<4;i++) if(atom.realname[i]==' ') atom.realname[i]='-';
      /* atom name, first 2 chars are element name, followed by atom id */
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      atom.alt=q[0];
      /* alternate location indicator, used with alternate chain id */

/* STEP TWO: parse character 18-28 and store information in 'res' object */
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      rescodeFlag = (q[2]==' ') ? 0 : 1;
      if(q[1]!=' ') rescodeFlag+=2;
      if(q[0]!=' ') rescodeFlag+=4;
      switch(rescodeFlag){              /* a fast way to assign residue 3-letter-code */
        case 0: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]='_';  break;
        case 1: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[2]; break;
        case 2: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[1]; break;
        case 3: res.resn[0]='_';  res.resn[1]=q[1]; res.resn[2]=q[2]; break;
        case 4: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[0]; break;
        case 5: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[2]; break;
        case 6: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[1]; break;
        case 7: res.resn[0]=q[0]; res.resn[1]=q[1]; res.resn[2]=q[2]; break;
      }
      res.resn[3]=0;
      /* residue name, three letter code */
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      if (assi->SymChainInfo) {
        for (i=0;i<assi->numSymChain;i++) {
          symi=assi->SymChainInfo+i;
          if(res.chain == symi->symop_chainid) {
            res.chain=symi->cdhit_chainid;
            break;
          }
        }
      }
      /* chain identifier, preserve original pdb chain ID here  */
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */
      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
/* alternative solution for step 3 & 4, still in development */
//    ai=I->AtomInfo+AtomInfoLocateIndex4surfrace(&res, &atom, I, ai->index);
//    ri=ai->ResidueInfo;
/* End alternative solution for step 3 & 4, still in development */

/* STEP THREE: locate correct residue by res.(chain,resid,resi2,resn), store in ri-> */
//    printf("%s",line);
//    printf("=%c-%d-%d-%s=%c-%d-%d-%s=\n",res.chain,res.resid,res.resi2,res.resn,ri->chain,ri->resid,ri->resi2,ri->resn);
      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        atomCount++;
      }else if (exact_match==1 && res.chain==chainid_from) {
        if(res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) atomCount++;
        else {
          resFound=-1;
          for(i=0; i<I->numResidue; i++){               // scan from the beginning to the end
            ri=I->ResidueInfo+i;
            if (chainid_to==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=1; resFound=i; break;
            }
          }
          if(resFound==-1){
            ri=I->ResidueInfo; resCount=0; atomCount=0;
//          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom even with chain_id correction.\n",res.chain,res.resn,res.resid);
//          PFatalError(msg);
          } else { resCount=resFound; atomCount=0; }
        }
      }else{
        resFound=-1;
        for(i=resCount+1; i<I->numResidue; i++){        // scan to the end of coord
          ri=I->ResidueInfo+i;
          if (res.chain==ri->chain && res.resid==ri->resid &&
              res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
            exact_match=0; resFound=i; break;
          }
        }
        if(resFound==-1){
          for(i=0; i<resCount; i++){                    // scan from the beginning of coord
            ri=I->ResidueInfo+i;
            if (res.chain==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=0; resFound=i; break;
            }
          }
          if(resFound==-1){
            for(i=0; i<I->numAtom; i++){                // try to allow chain_id mismatch, looking for next available chain
              ai=I->AtomInfo+i;
              if (atom.id==ai->id && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                exact_match=1;          ri=ai->ResidueInfo;
                resFound=ri->index;
                chainid_from=res.chain; chainid_to=ri->chain; break;
              }
            }
          }
        }
        if(resFound==-1){                               // just don't report any error, although slower, it will still get automatically corrected during atom looking
          ri=I->ResidueInfo; resCount=0; atomCount=0;
        } else { resCount=resFound; atomCount=0; }
      }

// STEP FOUR: locate correct atom by atom.(name,alt,id), store in ai->
      atomFound=-1;
      if (resFound==-1) {
        for(i=0; i<I->numAtom; i++){            // try to allow chain_id mismatch, looking for next available chain
          ai=I->AtomInfo+i;
          if ((atom.id==ai->id || atom.id==ai->id+1) && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
            exact_match=1;              ri=ai->ResidueInfo;
            resFound=ri->index;         atomFound=ai->index;        
            chainid_from=res.chain;     chainid_to=ri->chain; break;
          }
        }
        if (resFound==-1) {
          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom.\n",res.chain,res.resn,res.resid);
          PWarning(msg);
        }
      } else {
        for(i=atomCount;i<ri->numAtom;i++){     // scan to the end of residue
          ai=ri->AtomInfo+i;
          if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
            atomFound=ai->index; break;
          }
        }
        if(atomFound==-1){
          for(i=0;i<atomCount;i++){             // scan from the beginning of residue
            ai=ri->AtomInfo+i;
            if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
              atomFound=ai->index; break;
            }
          }
          if(atomFound==-1){
            for(i=0;i<ri->numAtom;i++){         // scan again with looser criteria
              ai=ri->AtomInfo+i;
              if(strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
                atomFound=ai->index; break;
              }
            }
            if((!strncmp(res.resn,"GLY",3)) && (!strncmp(atom.realname,"-CB-",4))) {    // Glycine do not have C beta atom, skip this case
              p=str2nextline(p);
              continue;
            }
            if(atomFound==-1) {
              sprintf(msg,"Failed to locate corresponding atom %d:%s:%c for SURFRACE file. Skipping...\n", atom.id, atom.realname, atom.alt);
              PWarning(msg);
              p=str2nextline(p);
              continue;
            }
          }
        }
      }

/* STEP FIVE: skip character 28-54, parse character 55-81 and store in ai-> object */
      /* NOTE: location, asa, msa and curvature for atom is update here, */
      /*       but those values for residue are left empty here, and assigned later */
      p=str2nskip(p,36);                /* skip 28-63 */
      p=str2ncpy(q,p,5);                /* read 64-68   assessible surface */
      if(sscanf(q,"%f",&ai->asa)!=1) ai->asa=0.0;
      p=str2nskip(p,2);                 /* skip 69-70 */
      p=str2ncpy(q,p,5);                /* read 71-75   molecule surface */
      if(sscanf(q,"%f",&ai->msa)!=1) ai->msa=0.0;
      p=str2nskip(p,1);                 /* skip 76 */
      p=str2ncpy(q,p,5);                /* read 77-81   surface curvature */
      if(sscanf(q,"%f",&ai->curvature)!=1) ai->curvature=0.0;

/* STEP SIX: process cavity-specific information */
      if(cavity_record==0){ /* for a residue in general, that is, no cavity info has been identified */
        if(ai->asa<=0 && ai->msa<=0) ai->location=ATOM_LOCATE_BURIED;
        else ai->location=ATOM_LOCATE_SURFACE;
      }else{              /* for a residue inside some cavity */
        ai->location=ATOM_LOCATE_CAVITY;
      }
    }else if(atomFlag==0){/* cavity record encounters */
      cavity_record = 1;
    }
    p=str2nextline(p);
  }

/* STEP SEVEN: derived residue information (location, asa, msa and curvature) from its atoms */
  int buried_detected,surface_detected,cavity_detected,is_sdcavity;
  float asa_sum,msa_sum,curvature_sum;
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    buried_detected=0;
    surface_detected=0;
    cavity_detected=0;
    asa_sum=0;
    msa_sum=0;
    curvature_sum=0;
    for(j=0;j<ri->numAtom;j++){
      ai=ri->AtomInfo+j;
      switch(ai->location){
        case ATOM_LOCATE_BURIED:  buried_detected=1;  break;
        case ATOM_LOCATE_SURFACE: surface_detected=1; break;
        case ATOM_LOCATE_CAVITY:  cavity_detected=1; 
                               /* ai_cavity=ai; */    break;
      }
      if(ai->asa > 0) asa_sum+=ai->asa;
      if(ai->msa > 0) { msa_sum+=ai->msa; curvature_sum+=ai->msa*ai->curvature; }
    }
    is_sdcavity = ri->location>=RESIDUE_LOCATE_SDCAVITY ? 1 : 0;
    if(cavity_detected) {
      ri->location      =RESIDUE_LOCATE_CAVITY;
//    ri->cavity_index  =ai_cavity->cavity_index;
//    ri->CavityInfo    =ai_cavity->CavityInfo;
//    ri->CavityInfo->numResidue++;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(surface_detected) {
      ri->location=RESIDUE_LOCATE_SURFACE;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(buried_detected) {
      ri->location=RESIDUE_LOCATE_BURIED;
      ri->asa=0; ri->msa=0; ri->curvature=0;
    } else ri->location=RESIDUE_LOCATE_UNDEF;
    if(is_sdcavity) { ri->location += RESIDUE_LOCATE_SDCAVITY; }
  }
}

/*---------------------------------------------------------------------------*/
int EntityAssemblyReadSurfaceStrOld(ObjAssemblyInfo *assi, char *buffer, int assCount, int cavityCountPrev, ObjEntityMolecule *I) {
  int           i,j,atomFlag,rescodeFlag;
  int           resCount,atomCount,resFound,atomFound;
  int           cavityCount,numCavity=0;
  char          *p,q[FileLineLength],msg[FileLineLength];
  ObjChainInfo  *ci;
  ObjResidueInfo*ri,res;
  ObjAtomInfo   *ai,*ai_cavity,atom;
  ObjCavityInfo *cvinfo=NULL,*cvi;
  int           exact_match=0;
  char          chainid_from=0,chainid_to=0;

  p=buffer;
  while(*p) {
    if(!strncmp(p,"CAVITY",6)) numCavity++;
    p=str2nextline(p);
  }
  AllocP(cvinfo,ObjCavityInfo,(numCavity+2));
  assi->numCavity=numCavity;
  assi->CavityInfo=cvinfo;

  p=buffer;
  cavityCount=0;
  cvi=cvinfo+cavityCount;
  cvi->index=-1;
  resCount=0;
  ri=I->ResidueInfo+resCount;
  atomCount=-1;
  while(*p) {
    atomFlag=-1;
    if(!strncmp(p,"ATOM",4))        atomFlag=1;
    else if(!strncmp(p,"HETATM",6)) atomFlag=2;
    else if(!strncmp(p,"CAVITY",6)) atomFlag=0;
//  str2printline(p);
    if(atomFlag>=1) {
/* STEP ONE: parse character 1-17 and store information in 'atom' object */
      p=str2nskip(p,6);                 /* skip 1-6     "ATOM  " */
      p=str2ncpy(q,p,5);                /* read 7-11    serial   */
      if(sscanf(q,"%d",&atom.id)!=1) atom.id=0;
      /* atom serial number in the pdbfile */
      p=str2nskip(p,1);                 /* skip 12 */
      p=str2ncpy(atom.realname,p,4);     /* read 13-16   name     */
      if(sscanf(atom.realname,"%s",atom.name)!=1) atom.name[0]=0;
      for(i=0;i<4;i++) if(atom.realname[i]==' ') atom.realname[i]='-';
      /* atom name, first 2 chars are element name, followed by atom id */
      p=str2ncpy(q,p,1);                /* read 17      altLoc   */
      atom.alt=q[0];
      /* alternate location indicator, used with alternate chain id */

/* STEP TWO: parse character 18-28 and store information in 'res' object */
      p=str2ncpy(q,p,3);                /* read 18-20   resName  */
      rescodeFlag = (q[2]==' ') ? 0 : 1;
      if(q[1]!=' ') rescodeFlag+=2;
      if(q[0]!=' ') rescodeFlag+=4;
      switch(rescodeFlag){              /* a fast way to assign residue 3-letter-code */
        case 0: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]='_';  break;
        case 1: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[2]; break;
        case 2: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[1]; break;
        case 3: res.resn[0]='_';  res.resn[1]=q[1]; res.resn[2]=q[2]; break;
        case 4: res.resn[0]='_';  res.resn[1]='_';  res.resn[2]=q[0]; break;
        case 5: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[2]; break;
        case 6: res.resn[0]='_';  res.resn[1]=q[0]; res.resn[2]=q[1]; break;
        case 7: res.resn[0]=q[0]; res.resn[1]=q[1]; res.resn[2]=q[2]; break;
      }
      res.resn[3]=0;
      /* residue name, three letter code */
      p=str2nskip(p,1);                 /* skip 21 */
      p=str2ncpy(q,p,1);                /* read 22      chainId  */
      res.chain=q[0];
      /* chain identifier, preserve original pdb chain ID here  */
      p=str2ncpy(q,p,4);                /* read 23-26   resSeq   */
      if(sscanf(q,"%s",res.resi)!=1) res.resi[0]=0;
      if(sscanf(q,"%d",&res.resid)!=1) res.resid=-9999;
      /* residue sequence number , together with residue insertion code */
      p=str2ncpy(q,p,1);                /* read 27      patched residue   */
      res.resi2=q[0];
      /* alternate residue id indicator, used with the main resseq - residue id */
 
/* STEP THREE: locate correct residue by res.(chain,resid,resi2,resn), store in ri-> */
      if (res.chain==ri->chain && res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
        atomCount++;
      }else if (exact_match==1 && res.chain==chainid_from) {
        if(res.resid==ri->resid && res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) atomCount++;
        else {
          resFound=-1;
          for(i=0; i<I->numResidue; i++){               /* scan from the beginning to the end */
            ri=I->ResidueInfo+i;
            if (chainid_to==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=1; resFound=i; break;
            }
          }
          if(resFound==-1){
            ri=I->ResidueInfo; resCount=0; atomCount=0;
//          sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom even with chain_id correction.\n",res.chain,res.resn,res.resid);
//          PFatalError(msg);
          } else { resCount=resFound; atomCount=0; }
        }
      }else{
        resFound=-1;
        for(i=resCount+1; i<I->numResidue; i++){        /* scan to the end of coord */
          ri=I->ResidueInfo+i;
          if (res.chain==ri->chain && res.resid==ri->resid &&
              res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
            exact_match=0; resFound=i; break;
          }
        }
        if(resFound==-1){
          for(i=0; i<resCount; i++){                    /* scan from the beginning of coord */
            ri=I->ResidueInfo+i;
            if (res.chain==ri->chain && res.resid==ri->resid &&
                res.resi2==ri->resi2 && strcmp(res.resn,ri->resn)==0) {
              exact_match=0; resFound=i; break;
            }
          }
          if(resFound==-1){
            for(i=0; i<I->numAtom; i++){                /* try to allow chain_id mismatch, looking for next available chain */
              ai=I->AtomInfo+i;
              if (atom.id==ai->id && res.resid==ri->resid && strcmp(res.resn,ri->resn)==0) {
                exact_match=1; ri=ai->ResidueInfo; resFound=ai->residue_index;
                chainid_from=res.chain; chainid_to=ri->chain; break;
              }
            }
          }
        }
        if(resFound==-1){                               /* just don't report any error, although slower, it will still get automatically corrected during atom looking */
          ri=I->ResidueInfo; resCount=0; atomCount=0;
//        sprintf(msg,"Failed to locate residue %c:%s %d for SURFRACE file atom.\n",res.chain,res.resn,res.resid);
//        PFatalError(msg);
        } else { resCount=resFound; atomCount=0; }
      }

/* STEP FOUR: locate correct atom by atom.(name,alt,id), store in ai-> */
      atomFound=-1;
      for(i=atomCount;i<ri->numAtom;i++){               /* scan to the end of residue */
        ai=ri->AtomInfo+i;
        if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
          atomFound=i; break;
        }
      }
      if(atomFound==-1){
        for(i=0;i<atomCount;i++){                       /* scan from the beginning of residue */
          ai=ri->AtomInfo+i;
          if(atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt){
            atomFound=i; break;
          }
        }
        if(atomFound==-1){
          for(i=0; i<I->numAtom; i++){                  /* try to allow chain_id mismatch, looking for next available chain */
            ai=I->AtomInfo+i;
            if (atom.id==ai->id && strncmp(atom.realname,ai->realname,4)==0 && atom.alt==ai->alt) {
              exact_match=1; ri=ai->ResidueInfo; atomFound=ai->index;
              chainid_from=res.chain; chainid_to=ri->chain; break;
            }
          }
          if(atomFound==-1){
            for(i=0;i<ri->numAtom;i++){                 /* scan again with losser criteria */
              ai=ri->AtomInfo+i;
              if(strncmp(atom.realname,ai->realname,4)==0) {
                atomFound=i; break;
              }
            }
            if(atomFound==-1) sprintf(msg,"Failed to locate corresponding atom %d:%s:%cfor SURFRACE file.\n", atom.id, atom.realname, atom.alt);
            else sprintf(msg,"Failed to locate exact match atom %d:%s:%cfor SURFRACE file.\n", atom.id, atom.realname, atom.alt);
            PFatalError(msg);
          }
        }
      }

/* STEP FIVE: skip character 28-54, parse character 55-81 and store in ai-> object */
      /* NOTE: location, asa, msa and curvature for atom is update here, */
      /*       but those values for residue are left empty here, and assigned later */
      p=str2nskip(p,36);                /* skip 28-63 */
      p=str2ncpy(q,p,5);                /* read 64-68   assessible surface */
      if(sscanf(q,"%f",&ai->asa)!=1) ai->asa=0.0;
      p=str2nskip(p,2);                 /* skip 69-70 */
      p=str2ncpy(q,p,5);                /* read 71-75   molecule surface */
      if(sscanf(q,"%f",&ai->msa)!=1) ai->msa=0.0;
      p=str2nskip(p,1);                 /* skip 76 */
      p=str2ncpy(q,p,5);                /* read 77-81   surface curvature */
      if(sscanf(q,"%f",&ai->curvature)!=1) ai->curvature=0.0;

/* STEP SIX: process cavity-specific information */
      if(cvi->index==-1){ /* for a residue in general, that is, no cavity info has been identified */
        if(ai->asa<=0 && ai->msa<=0) ai->location=ATOM_LOCATE_BURIED;
        else ai->location=ATOM_LOCATE_SURFACE;
      }else{              /* for a residue inside some cavity */
        ai->location=ATOM_LOCATE_CAVITY;
        ai->cavity_index=cvi->index;
        ai->CavityInfo=cvi;
        cvi->numAtom++;
      }
    }else if(atomFlag==0){/* cavity record encounters */
      if(cvi->index!=-1) cavityCount++;
      cvi=cvinfo+cavityCount;
      cvi->index        = cavityCountPrev+cavityCount;
      cvi->assembly_index=assCount;
      cvi->AssemblyInfo = assi;
      cvi->numResidue   = 0;
      cvi->numAtom      = 0;
    }
    p=str2nextline(p);
  }
  cavityCount++;
  cvi=cvinfo+cavityCount;
  cvi->index=-1;

/* STEP SEVEN: derived residue information (location, asa, msa and curvature) from its atoms */
  int buried_detected,surface_detected,cavity_detected;
  float asa_sum,msa_sum,curvature_sum;
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    buried_detected=0;
    surface_detected=0;
    cavity_detected=0;
    asa_sum=0;
    msa_sum=0;
    curvature_sum=0;
    for(j=0;j<ri->numAtom;j++){
      ai=ri->AtomInfo+j;
      switch(ai->location){
        case ATOM_LOCATE_BURIED:  buried_detected=1;  break;
        case ATOM_LOCATE_SURFACE: surface_detected=1; break;
        case ATOM_LOCATE_CAVITY:
          if(cavity_detected==0){
            cavity_detected=1; ai_cavity=ai;
          }else if(ai_cavity->CavityInfo->numAtom < ai->CavityInfo->numAtom) {
            ai_cavity=ai;       /* choose the biggest cavity in case a residue belongs to multiple cavities */
          }; break;
      }
      if(ai->asa > 0) asa_sum+=ai->asa;
      if(ai->msa > 0) { msa_sum+=ai->msa; curvature_sum+=ai->msa*ai->curvature; }
    }
    if(cavity_detected) {
      ri->location      =RESIDUE_LOCATE_CAVITY;
      ri->cavity_index  =ai_cavity->cavity_index;
      ri->CavityInfo    =ai_cavity->CavityInfo;
      ri->CavityInfo->numResidue++;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(surface_detected) {
      ri->location=RESIDUE_LOCATE_SURFACE;
      ri->asa           =asa_sum;
      ri->msa           =msa_sum;
      if(msa_sum>0) ri->curvature=curvature_sum/msa_sum;
      else          ri->curvature=0;
    } else if(buried_detected) {
      ri->location=RESIDUE_LOCATE_BURIED;
      ri->asa=0; ri->msa=0; ri->curvature=0;
    } else ri->location=RESIDUE_LOCATE_UNDEF;
  }
  return (cavityCountPrev+numCavity);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeAssignType(ObjEntityMolecule *I, ResidueDict *aminoacid_dictionary) {
  int i, im, irt, j, numAtom;
  ObjChainInfo *ci;
  ObjMoleculeInfo*moinfo=NULL,*mi;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  char *name, *elem;

  /* Assign residue type */
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    name=ri->resn;
    if(!strncmp(name,"HOH",3) ||
       !strncmp(name,"DOD",3) ||
       !strncmp(name,"MTO",3) ||
       !strncmp(name,"DIS",3) ||
       !strncmp(name,"WAT",3)) ri->type = RESIDUE_WATER;
    else if(!strncmp(name,"LEU",3)) ri->type = RESIDUE_LEU;
    else if(!strncmp(name,"ALA",3)) ri->type = RESIDUE_ALA;
    else if(!strncmp(name,"GLY",3)) ri->type = RESIDUE_GLY;
    else if(!strncmp(name,"VAL",3)) ri->type = RESIDUE_VAL;
    else if(!strncmp(name,"GLU",3)) ri->type = RESIDUE_GLU;
    else if(!strncmp(name,"SER",3)) ri->type = RESIDUE_SER;
    else if(!strncmp(name,"LYS",3)) ri->type = RESIDUE_LYS;
    else if(!strncmp(name,"ASP",3)) ri->type = RESIDUE_ASP;
    else if(!strncmp(name,"THR",3)) ri->type = RESIDUE_THR;
    else if(!strncmp(name,"ILE",3)) ri->type = RESIDUE_ILE;
    else if(!strncmp(name,"ARG",3)) ri->type = RESIDUE_ARG;
    else if(!strncmp(name,"PRO",3)) ri->type = RESIDUE_PRO;
    else if(!strncmp(name,"ASN",3)) ri->type = RESIDUE_ASN;
    else if(!strncmp(name,"PHE",3)) ri->type = RESIDUE_PHE;
    else if(!strncmp(name,"GLN",3)) ri->type = RESIDUE_GLN;
    else if(!strncmp(name,"TYR",3)) ri->type = RESIDUE_TYR;
    else if(!strncmp(name,"HIS",3)) ri->type = RESIDUE_HIS;
    else if(!strncmp(name,"MET",3)) ri->type = RESIDUE_MET;
    else if(!strncmp(name,"TRP",3)) ri->type = RESIDUE_TRP;
    else if(!strncmp(name,"CYS",3)) ri->type = RESIDUE_CYS;
    else if(!strncmp(name,"UNK",3) /* && ri->AtomInfo->hetatm==0 */) ri->type = RESIDUE_AMINOACID;
    else if( name[0]=='_' && /* ri->AtomInfo->hetatm==0 && */
            (name[1]=='_' || name[1]=='+' || name[1]=='D')&&
            (name[2]=='A' || name[2]=='T' || name[2]=='G' ||
             name[2]=='C' || name[2]=='U' || name[2]=='N')) ri->type = RESIDUE_DNARNA;
    /* MSE, MLY, frequently observed cation, and anions (3000+) */
    else if(!strncmp(name,"MSE",3)) ri->type = RESIDUE_NSAA_BASE + RESIDUE_MET;
    else if(!strncmp(name,"MLY",3)) ri->type = RESIDUE_NSAA_BASE + RESIDUE_LYS;
    else if(!strcmp(name,"_LI")|| !strcmp(name,"_NA")|| !strcmp(name,"__K") || !strcmp(name,"NH4") ||
            !strcmp(name,"_RB")|| !strcmp(name,"_CS")) ri->type = RESIDUE_ALKALI;
    else if(!strcmp(name,"_MG")|| !strcmp(name,"_CA")||
            !strcmp(name,"_SR")|| !strcmp(name,"_BA")) ri->type = RESIDUE_ALKALINE;
    else if(!strcmp(name,"SO4")|| !strcmp(name,"SO3")|| !strcmp(name,"SUL")||
            !strcmp(name,"PO4")|| !strcmp(name,"PO3")|| !strcmp(name,"ACT")||
            !strcmp(name,"CO3")|| !strcmp(name,"NO3")|| !strcmp(name,"NO2")||
            !strcmp(name,"__F")|| !strcmp(name,"_CL")|| !strcmp(name,"_BR")||
            !strcmp(name,"IOD")) ri->type = RESIDUE_ANION;
    /* sugar, solvent, heme, cofactor, non-standard proline that exist more than 300 times in PDB */
    else if(!strncmp(name,"NAG",3)|| !strncmp(name,"MAN",3)|| !strncmp(name,"GLC",3)|| !strncmp(name,"BMA",3)||
            !strncmp(name,"GAL",3)|| !strncmp(name,"NDG",3)|| !strncmp(name,"FUC",3)|| !strncmp(name,"BGC",3)||
            !strncmp(name,"XYP",3))                                                   ri->type = RESIDUE_SUGAR;
    else if(!strncmp(name,"GOL",3)|| !strncmp(name,"EDO",3)|| !strncmp(name,"DMS",3)|| !strncmp(name,"MPD",3)||
            !strncmp(name,"BME",3)|| !strncmp(name,"TRS",3)|| !strncmp(name,"MES",3)|| !strncmp(name,"PEG",3)||
            !strncmp(name,"IPA",3)|| !strncmp(name,"EOH",3)|| !strncmp(name,"MOH",3)) ri->type = RESIDUE_SOLVENT;
    else if(!strncmp(name,"HEM",3)|| !strncmp(name,"CL1",3)|| !strncmp(name,"CLA",3)|| !strncmp(name,"HEC",3)||
            !strncmp(name,"BCL",3))                                                   ri->type = RESIDUE_PORPHYRIN;
    else if(!strncmp(name,"NAD",3)|| !strncmp(name,"ADP",3)|| !strncmp(name,"FAD",3)|| !strncmp(name,"NAP",3)||
            !strncmp(name,"ATP",3)|| !strncmp(name,"FMN",3)|| !strncmp(name,"GDP",3)|| !strncmp(name,"AMP",3)||
            !strncmp(name,"NDP",3))                                                   ri->type = RESIDUE_COFACTOR;
    else if(!strncmp(name,"HYP",3)|| !strncmp(name,"DPR",3)|| !strncmp(name,"DP9",3)|| !strncmp(name,"4FB",3))
                                                                                      ri->type = RESIDUE_NSAA_BASE + RESIDUE_PRO;
    /* a comprehensive list of metal ions in PDB */
    else if(!strcmp(name,"UNX")|| !strcmp(name,"_AL")|| !strcmp(name,"_GA")|| !strcmp(name,"GA1")||
            !strcmp(name,"_IN")|| !strcmp(name,"_TL")|| !strcmp(name,"_PB")||
            !strcmp(name,"__V")|| !strcmp(name,"_CR")|| !strcmp(name,"_MN")|| !strcmp(name,"MN3")||
            !strcmp(name,"_FE")|| !strcmp(name,"FE2")|| !strcmp(name,"_CO")|| !strcmp(name,"3CO")||
            !strcmp(name,"_NI")|| !strcmp(name,"3NI")|| !strcmp(name,"_CU")|| !strcmp(name,"CU1")||
            !strcmp(name,"_ZN")|| !strcmp(name,"ZN2")|| !strcmp(name,"_Y1")|| !strcmp(name,"YT3")||
            !strcmp(name,"_MO")|| !strcmp(name,"4MO")|| !strcmp(name,"6MO")||
            !strcmp(name,"_RU")|| !strcmp(name,"_PD")|| !strcmp(name,"_AG")|| !strcmp(name,"_CD")||
            !strcmp(name,"_LA")|| !strcmp(name,"_CE")|| !strcmp(name,"_PR")|| !strcmp(name,"_SM")||
            !strcmp(name,"_EU")|| !strcmp(name,"EU3")|| !strcmp(name,"_GD")|| !strcmp(name,"GD3")||
            !strcmp(name,"_TB")|| !strcmp(name,"_HO")|| !strcmp(name,"HO3")|| !strcmp(name,"ER3")||
            !strcmp(name,"_YB")|| !strcmp(name,"_LU")|| !strcmp(name,"__W")|| !strcmp(name,"_RE")||
            !strcmp(name,"_OS")|| !strcmp(name,"OS4")|| !strcmp(name,"_IR")|| !strcmp(name,"IR3")||
            !strcmp(name,"_PT")|| !strcmp(name,"PT4")|| !strcmp(name,"_AU")|| !strcmp(name,"AU3")||
            !strcmp(name,"_HG")) ri->type = RESIDUE_CATION;
    /* a comprehensive list of sugar, heme, cofactor in PDB */
    else if(!strcmp(name,"CYC")|| !strcmp(name,"BPH")|| !strcmp(name,"CHL")|| !strcmp(name,"HEA")||
            !strcmp(name,"BCB")|| !strcmp(name,"BLA")|| !strcmp(name,"DHE")|| !strcmp(name,"PEB")||
            !strcmp(name,"BPB")|| !strcmp(name,"SFP")|| !strcmp(name,"HDD")|| !strcmp(name,"FEC")||
            !strcmp(name,"PHO")|| !strcmp(name,"HNI")|| !strcmp(name,"SRM")|| !strcmp(name,"PP9")||
            !strcmp(name,"COH"))                                             ri->type = RESIDUE_PORPHYRIN;
    else if(!strcmp(name,"1CP")|| !strcmp(name,"CLN")|| !strcmp(name,"CP3")|| !strcmp(name,"DDH")||
            !strcmp(name,"DEU")|| !strcmp(name,"FDD")|| !strcmp(name,"FDE")|| !strcmp(name,"FMI")||
            !strcmp(name,"H01")|| !strcmp(name,"H02")|| !strcmp(name,"HCO")|| !strcmp(name,"HE5")||
            !strcmp(name,"HEG")|| !strcmp(name,"HEV")|| !strcmp(name,"HFM")|| !strcmp(name,"HIF")||
            !strcmp(name,"HME")|| !strcmp(name,"MHM")|| !strcmp(name,"MMP")|| !strcmp(name,"MNH")||
            !strcmp(name,"MNR")|| !strcmp(name,"MP1")|| !strcmp(name,"PC3")|| !strcmp(name,"PCU")||
            !strcmp(name,"PNI")|| !strcmp(name,"POH")|| !strcmp(name,"POR")|| !strcmp(name,"VEA")||
            !strcmp(name,"VER")|| !strcmp(name,"ZEM")|| !strcmp(name,"ZNH")) ri->type = RESIDUE_PORPHYRIN;
    else if(!strcmp(name,"SIA")|| !strcmp(name,"GLA")|| !strcmp(name,"SUC")|| !strcmp(name,"XYS")||
            !strcmp(name,"MMA")|| !strcmp(name,"MAL")|| !strcmp(name,"FUL")|| !strcmp(name,"NGA")||
            !strcmp(name,"ADA")|| !strcmp(name,"SGN")|| !strcmp(name,"F6P")|| !strcmp(name,"A2G")||
            !strcmp(name,"IDS")|| !strcmp(name,"FBP")|| !strcmp(name,"LAT")|| !strcmp(name,"DAN")||
            !strcmp(name,"TRE")|| !strcmp(name,"AHR")|| !strcmp(name,"HBI")|| !strcmp(name,"DDA")||
            !strcmp(name,"AMG")|| !strcmp(name,"SGC")|| !strcmp(name,"GCU")|| !strcmp(name,"FRU")||
            !strcmp(name,"G1P")|| !strcmp(name,"G6P")|| !strcmp(name,"XYL")|| !strcmp(name,"AAL")||
            !strcmp(name,"BDP")|| !strcmp(name,"M8C")|| !strcmp(name,"RAM")|| !strcmp(name,"MFU")||
            !strcmp(name,"GMH")|| !strcmp(name,"G2F")|| !strcmp(name,"NBG")|| !strcmp(name,"SOR")||
            !strcmp(name,"IDU")|| !strcmp(name,"2FG")|| !strcmp(name,"GLD")|| !strcmp(name,"RIP")||
            !strcmp(name,"MAG")|| !strcmp(name,"UGA")|| !strcmp(name,"BG6")|| !strcmp(name,"CBS")||
            !strcmp(name,"RIB")|| !strcmp(name,"SLB")|| !strcmp(name,"CBI")|| !strcmp(name,"MNA")||
            !strcmp(name,"2FL")|| !strcmp(name,"UDA")|| !strcmp(name,"XMM")|| !strcmp(name,"16G")||
            !strcmp(name,"MLR")|| !strcmp(name,"GAA")|| !strcmp(name,"G6D")|| !strcmp(name,"FCA")||
            !strcmp(name,"R1P")|| !strcmp(name,"RP5")|| !strcmp(name,"ROB")|| !strcmp(name,"MGL")||
            !strcmp(name,"GLP")|| !strcmp(name,"LBT")|| !strcmp(name,"2FP")|| !strcmp(name,"M6P")||
            !strcmp(name,"ADQ")|| !strcmp(name,"DAF")|| !strcmp(name,"AGL")|| !strcmp(name,"FDP")||
            !strcmp(name,"MGC")|| !strcmp(name,"GYP")|| !strcmp(name,"DDL")|| !strcmp(name,"CDR")||
            !strcmp(name,"RNS")|| !strcmp(name,"DXP")|| !strcmp(name,"GDD")|| !strcmp(name,"DX5")||
            !strcmp(name,"F6R")|| !strcmp(name,"AAB")|| !strcmp(name,"1GL")|| !strcmp(name,"CSF")||
            !strcmp(name,"MAV")|| !strcmp(name,"145")|| !strcmp(name,"G4S")|| !strcmp(name,"GCV")||
            !strcmp(name,"CTO")|| !strcmp(name,"MTT")|| !strcmp(name,"G6Q")|| !strcmp(name,"P5P")||
            !strcmp(name,"MBG")|| !strcmp(name,"GCN")|| !strcmp(name,"LGU")|| !strcmp(name,"ORP")||
            !strcmp(name,"SGA")|| !strcmp(name,"GLO")|| !strcmp(name,"MDM")) ri->type = RESIDUE_SUGAR;
    else if(!strcmp(name,"GTP")|| !strcmp(name,"5CM")|| !strcmp(name,"UDP")|| !strcmp(name,"PSU")||
            !strcmp(name,"UMP")|| !strcmp(name,"BRU")|| !strcmp(name,"_DU")|| !strcmp(name,"H2U")||
            !strcmp(name,"U5P")|| !strcmp(name,"TTP")|| !strcmp(name,"OMG")|| !strcmp(name,"5MC")||
            !strcmp(name,"ADN")|| !strcmp(name,"CBR")|| !strcmp(name,"5GP")|| !strcmp(name,"5BU")||
            !strcmp(name,"CMP")|| !strcmp(name,"5MU")|| !strcmp(name,"THM")|| !strcmp(name,"OMC")||
            !strcmp(name,"5IU")|| !strcmp(name,"TMP")|| !strcmp(name,"CTP")|| !strcmp(name,"1MA")||
            !strcmp(name,"APR")|| !strcmp(name,"C5P")|| !strcmp(name,"DTP")|| !strcmp(name,"TYD")||
            !strcmp(name,"OMU")|| !strcmp(name,"8OG")|| !strcmp(name,"DOC")|| !strcmp(name,"ADX")||
            !strcmp(name,"7MG")|| !strcmp(name,"DCP")|| !strcmp(name,"2MG")|| !strcmp(name,"MTA")||
            !strcmp(name,"DUT")|| !strcmp(name,"UTP")|| !strcmp(name,"M2G")|| !strcmp(name,"GSP")||
            !strcmp(name,"CDP")|| !strcmp(name,"DGT")|| !strcmp(name,"DUR")|| !strcmp(name,"C43")||
            !strcmp(name,"G48")|| !strcmp(name,"BGM")|| !strcmp(name,"DCT")|| !strcmp(name,"A2M")||
            !strcmp(name,"6MA")|| !strcmp(name,"C42")|| !strcmp(name,"BMP")|| !strcmp(name,"DCZ")||
            !strcmp(name,"6OG")|| !strcmp(name,"UFP")|| !strcmp(name,"ABG")|| !strcmp(name,"DDG")||
            !strcmp(name,"DUP")|| !strcmp(name,"A23")|| !strcmp(name,"GMP")|| !strcmp(name,"DGP")||
            !strcmp(name,"UP6")|| !strcmp(name,"G38")|| !strcmp(name,"DUD")|| !strcmp(name,"UMS")||
            !strcmp(name,"SAP")|| !strcmp(name,"2DT")|| !strcmp(name,"TDR")|| !strcmp(name,"M7G")||
            !strcmp(name,"_LG")|| !strcmp(name,"3AT")|| !strcmp(name,"A44")|| !strcmp(name,"U36")||
            !strcmp(name,"PDU")|| !strcmp(name,"BT5")|| !strcmp(name,"DCM")|| !strcmp(name,"1MG")||
            !strcmp(name,"D5M")|| !strcmp(name,"4SU")|| !strcmp(name,"CBV")|| !strcmp(name,"MGT")||
            !strcmp(name,"NYM")|| !strcmp(name,"DAD")|| !strcmp(name,"_LC")|| !strcmp(name,"CCC")||
            !strcmp(name,"CDF")|| !strcmp(name,"A43")|| !strcmp(name,"ATM")|| !strcmp(name,"_IU")||
            !strcmp(name,"A5M")|| !strcmp(name,"PCG")|| !strcmp(name,"5PC")|| !strcmp(name,"MA7")||
            !strcmp(name,"5AD")|| !strcmp(name,"THU")|| !strcmp(name,"126")|| !strcmp(name,"ATR"))
                                                                             ri->type = RESIDUE_COFACTOR;
    /* a comprehensive list of non-standard amino acid residues in PDB */
/*  else if(!strcmp(name,"AIB")|| !strcmp(name,"ALM")|| !strcmp(name,"AYA")|| !strcmp(name,"CHG")||
            !strcmp(name,"CSD")|| !strcmp(name,"DAL")|| !strcmp(name,"DNP")|| !strcmp(name,"DHA")||
            !strcmp(name,"FLA")|| !strcmp(name,"HAC")|| !strcmp(name,"MAA")|| !strcmp(name,"PRR")||
            !strcmp(name,"TIH")|| !strcmp(name,"TPQ")|| !strcmp(name,"BAL")|| !strcmp(name,"DBZ")||
            !strcmp(name,"NAL")|| !strcmp(name,"PFF")|| !strcmp(name,"R1A")|| !strcmp(name,"NCB"))
                                                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_ALA;
    else if(!strcmp(name,"C5C")|| !strcmp(name,"C6C")|| !strcmp(name,"CCS")|| !strcmp(name,"CEA")|| 
            !strcmp(name,"CME")|| !strcmp(name,"CSO")|| !strcmp(name,"CSP")|| !strcmp(name,"CSS")|| 
            !strcmp(name,"CSW")|| !strcmp(name,"CSX")|| !strcmp(name,"CY1")|| !strcmp(name,"CY3")|| 
            !strcmp(name,"CYG")|| !strcmp(name,"CYM")|| !strcmp(name,"CYQ")|| !strcmp(name,"BCS")|| 
            !strcmp(name,"BUC")|| !strcmp(name,"DCY")|| !strcmp(name,"EFC")|| !strcmp(name,"OCS")|| 
            !strcmp(name,"PR3")|| !strcmp(name,"PEC")|| !strcmp(name,"SCS")|| !strcmp(name,"SCH")|| 
            !strcmp(name,"SCY")|| !strcmp(name,"SHC")|| !strcmp(name,"SOC")|| !strcmp(name,"SMC")||
            !strcmp(name,"CAS")|| !strcmp(name,"CMH")|| !strcmp(name,"SC2")|| !strcmp(name,"CSU")||
            !strcmp(name,"CAF")|| !strcmp(name,"GSW")|| !strcmp(name,"NCY")|| !strcmp(name,"CSE")||
            !strcmp(name,"S2C")|| !strcmp(name,"SNC")|| !strcmp(name,"RCY")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_CYS;
    else if(!strcmp(name,"2AS")|| !strcmp(name,"BHD")|| !strcmp(name,"DAS")|| !strcmp(name,"DSP")|| 
            !strcmp(name,"ASA")|| !strcmp(name,"ASB")|| !strcmp(name,"ASK")|| !strcmp(name,"ASL")|| 
            !strcmp(name,"ASI")|| !strcmp(name,"ACB")|| !strcmp(name,"PAL")|| !strcmp(name,"NCD")||
            !strcmp(name,"ASQ")|| !strcmp(name,"ASX")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ASP;
    else if(!strcmp(name,"5HP")|| !strcmp(name,"CGU")|| !strcmp(name,"DGL")|| !strcmp(name,"GGL")|| 
            !strcmp(name,"GLX")|| !strcmp(name,"GMA")|| !strcmp(name,"PCA")|| !strcmp(name,"NLG")||
            !strcmp(name,"GLH")|| !strcmp(name,"PGU")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLU;
    else if(!strcmp(name,"BNN")|| !strcmp(name,"DAH")|| !strcmp(name,"DPN")|| !strcmp(name,"HPQ")|| 
            !strcmp(name,"NFA")|| !strcmp(name,"PHI")|| !strcmp(name,"PHL")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_PHE;
    else if(!strcmp(name,"GSC")|| !strcmp(name,"GL3")|| !strcmp(name,"GLZ")|| !strcmp(name,"MPQ")||
            !strcmp(name,"MSA")|| !strcmp(name,"NMC")|| !strcmp(name,"SAR")|| !strcmp(name,"BET"))
                                                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLY;
    else if(!strcmp(name,"3AH")|| !strcmp(name,"DHI")|| !strcmp(name,"HIP")|| !strcmp(name,"HIC")||
            !strcmp(name,"MHS")|| !strcmp(name,"NEP")|| !strcmp(name,"NEM")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_HIS;
    else if(!strcmp(name,"DIL")|| !strcmp(name,"IIL")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ILE;
    else if(!strcmp(name,"ALY")|| !strcmp(name,"DLY")|| !strcmp(name,"LLY")|| !strcmp(name,"LLP")||
            !strcmp(name,"LYM")|| !strcmp(name,"LYZ")|| !strcmp(name,"KCX")|| !strcmp(name,"SHR")|| 
            !strcmp(name,"TRG")|| !strcmp(name,"M3L")|| !strcmp(name,"MLZ")|| !strcmp(name,"LCX"))
                                                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_LYS;
    else if(!strcmp(name,"BUG")|| !strcmp(name,"CLE")|| !strcmp(name,"DLE")|| !strcmp(name,"MLE")|| 
            !strcmp(name,"NLE")|| !strcmp(name,"NLN")|| !strcmp(name,"NLP")|| !strcmp(name,"DNE")||
            !strcmp(name,"ONL"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_LEU;
    else if(!strcmp(name,"SAM")|| !strcmp(name,"MME")|| !strcmp(name,"OMT")|| !strcmp(name,"CXM")||
            !strcmp(name,"FME"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_MET;
    else if(!strcmp(name,"MEN")|| !strcmp(name,"DMH")|| !strcmp(name,"DSG")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ASN;
    else if(!strcmp(name,"DGN")|| !strcmp(name,"MGN")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_GLN;
    else if(!strcmp(name,"ACL")|| !strcmp(name,"AGM")|| !strcmp(name,"ARM")|| !strcmp(name,"DAR")|| 
            !strcmp(name,"HAR")|| !strcmp(name,"HMR")|| !strcmp(name,"MAI")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_ARG;
    else if(!strcmp(name,"DSN")|| !strcmp(name,"MIS")|| !strcmp(name,"OAS")|| !strcmp(name,"SAC")|| 
            !strcmp(name,"SEL")|| !strcmp(name,"SEP")|| !strcmp(name,"SET")|| !strcmp(name,"SVA")||
            !strcmp(name,"SEB"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_SER;
    else if(!strcmp(name,"ALO")|| !strcmp(name,"BMT")|| !strcmp(name,"DTH")|| !strcmp(name,"TPO"))
                                                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_THR;
    else if(!strcmp(name,"DIV")|| !strcmp(name,"DVA")|| !strcmp(name,"MVA")|| !strcmp(name,"NVA")||
            !strcmp(name,"SN0"))                       ri->type = RESIDUE_NSAA_BASE + RESIDUE_VAL;
    else if(!strcmp(name,"DTR")|| !strcmp(name,"HTR")|| !strcmp(name,"LTR")|| !strcmp(name,"TPL")|| 
            !strcmp(name,"TRO")|| !strcmp(name,"TRN")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_TRP;
    else if(!strcmp(name,"DTY")|| !strcmp(name,"IYR")|| !strcmp(name,"PAQ")|| !strcmp(name,"PTR")|| 
            !strcmp(name,"STY")|| !strcmp(name,"TYB")|| !strcmp(name,"TYS")|| !strcmp(name,"TYY")|| 
            !strcmp(name,"TYQ")|| !strcmp(name,"TYI")) ri->type = RESIDUE_NSAA_BASE + RESIDUE_TYR;
    */
    else {
    /* everything else is just assigned as a general ligand */
      ri->type = RESIDUE_LIGAND;
    /* with the exception of rare non-standard amino acids */
      irt=RESIDUE_UNDEF;
      for(j=0;irt>=RESIDUE_UNDEF;j++) {
        irt=aminoacid_dictionary[j].type;
        if(!strcmp(name,aminoacid_dictionary[j].nsa)) {
          ri->type = RESIDUE_NSAA_BASE + irt;
          break;
        }
      }
    }
    ci=ri->ChainInfo;
    if(ri->type<=RESIDUE_AMINOACID)   ci->numProteinRes++;
    else if(ri->type==RESIDUE_WATER)  ci->numWaterRes++;
    else if(ri->type==RESIDUE_DNARNA) ci->numDnarnaRes++;
    else                              ci->numLigandRes++;
  }

  /* Assign chain type2 */
  I->numMolecule=0;
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    if(ci->numWaterRes)   { ci->type2+=CHAIN_TYPE2_WATER;   ci->numMolecule++; }
    if(ci->numLigandRes)  { ci->type2+=CHAIN_TYPE2_LIGAND;  ci->numMolecule+=ci->numLigandRes; }
    if(ci->numDnarnaRes)  { ci->type2+=CHAIN_TYPE2_DNARNA;  ci->numMolecule++; }
    if(ci->numProteinRes) { ci->type2+=CHAIN_TYPE2_PROTEIN; ci->numMolecule++; }
    I->numMolecule += ci->numMolecule;
  }

  /* Create molecule object and assign molecule type */
  AllocP(moinfo,ObjMoleculeInfo,(I->numMolecule+1));
  I->MoleculeInfo = moinfo;
  for(im=0;im<I->numMolecule;im++) {
    mi=I->MoleculeInfo+im;
    ObjMoleculeInit(mi);
    mi->index=im;
  }
  im=0;
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    ci->MoleculeInfo = I->MoleculeInfo+im;
    if(ci->numProteinRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_AMINOACID;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numProteinRes; im++;
    }
    if(ci->numDnarnaRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_NUCLEOTIDE;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numDnarnaRes;  im++;
    }
    if(ci->numWaterRes) {
      mi=I->MoleculeInfo+im;            mi->type=COMPONENT_WATER;
      mi->chain=ci->chainid;            mi->ChainInfo=ci;
      mi->numResidue=ci->numWaterRes;   im++;
    }
    if(ci->numLigandRes) {
      for(j=0;j<ci->numLigandRes;j++) {
        mi=I->MoleculeInfo+im;      mi->type=COMPONENT_OTHER;
        mi->chain=ci->chainid;      mi->ChainInfo=ci;
        mi->numResidue=-1;          im++;
     // mi->numResidue is served as a flag to check if a ligand residue is linked to molecule or not
     // when mi->numResidue == -1, the corresponding ligand residue hasn't been linked to this molecule yet
     // only after a ligand residue is linked to the molecule, mi->numResidue will be set to 1
      }
    }
  }
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ci=ri->ChainInfo;
    mi=ci->MoleculeInfo;
    if(ri->type<=RESIDUE_AMINOACID) {
      if(mi->type == COMPONENT_AMINOACID) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, amino acid residues should always be in first molecule of each chain.\n");
    } else if(ri->type==RESIDUE_DNARNA) {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, nucleotide residues should always be in first or second molecule of each chain.\n");
    } else if(ri->type==RESIDUE_WATER) {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_WATER) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
      } else PFatalError("Invalid molecule type, water residues should always be after amino acid and nucleotide residues of each chain.\n");
    } else {
      if(mi->type == COMPONENT_AMINOACID)  { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_NUCLEOTIDE) { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_WATER)      { im=mi->index+1; mi=I->MoleculeInfo+im; }
      while(mi->numResidue == 1)           { im=mi->index+1; mi=I->MoleculeInfo+im; }
      if(mi->type == COMPONENT_OTHER && mi->numResidue == -1) {
        ri->molecule_index=mi->index;
        ri->MoleculeInfo=mi;
        mi->numResidue=1;
      } else PFatalError("Invalid molecule type, either molecule is not expecting a small molecule ligand, or molecule has been occupied by another ligand residue.\n");
    }
  }

  /* Assign atom type */
  for(i=0;i<I->numAtom;i++) {
    ai=I->AtomInfo+i;
    elem=ai->elem;
    ai->type = ATOM_OTHER;      // default if won't be recognized
    ri=ai->ResidueInfo;
    if (ri->type <= RESIDUE_AMINOACID) {
      irt = ri->type;           // if it will be an even number, indicating non-standard residue,
      if (irt % 2 == 0) irt--;  // project to its corresponding standard residue name for atom type assignment whenever possible
      name=ai->realname;
      if(elem[1]=='_') {
        if(elem[0]=='C') {
           if(name[2]=='-') ai->type = ATOM_MC_C;
           else if(name[2]=='A' && name[3]=='-') ai->type = ATOM_MC_CA;
           else if(name[2]=='B' && name[3]=='-') ai->type = ATOM_SC_CB;
           else if(irt==RESIDUE_PHE || irt==RESIDUE_TYR ||
                   irt==RESIDUE_HIS || irt==RESIDUE_TRP) ai->type = ATOM_SC_C_RING;
           else ai->type = ATOM_SC_C;
        } else if(elem[0]=='O') {
           if(name[2]=='-') ai->type=ATOM_MC_O;
           else if(irt==RESIDUE_ASP || irt==RESIDUE_GLU) ai->type=ATOM_SC_O_CARBOXYL;
           else if(irt==RESIDUE_ASN || irt==RESIDUE_GLN) ai->type=ATOM_SC_O_AMIDE;
           else if(irt==RESIDUE_SER || irt==RESIDUE_THR) ai->type=ATOM_SC_O_HYDROXYL;
           else if(irt==RESIDUE_TYR)                     ai->type=ATOM_SC_O_PHENOL;
           else ai->type=ATOM_SC_O_HETERO;
        } else if(elem[0]=='N') {
           if(name[2]=='-') ai->type=ATOM_MC_N;
           else if(irt==RESIDUE_LYS) ai->type=ATOM_SC_N_LYS;
           else if(irt==RESIDUE_ARG) ai->type=ATOM_SC_N_ARG;
           else if(irt==RESIDUE_ASN || irt==RESIDUE_GLN) ai->type=ATOM_SC_N_AMIDE;
           else if(irt==RESIDUE_HIS) ai->type=ATOM_SC_N_HIS;
           else if(irt==RESIDUE_TRP) ai->type=ATOM_SC_N_TRP;
           else ai->type=ATOM_SC_N_HETERO;
        } else if(elem[0]=='S') {
           if(irt==RESIDUE_CYS) ai->type=ATOM_SC_S_CYS;
           else if(irt==RESIDUE_MET) ai->type=ATOM_SC_S_MET;
           else ai->type=ATOM_SC_S_HETERO;
        } else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
          else ai->type = ATOM_SC_X_HETERO;
      } else if (!strncmp(elem,"Se",2)) ai->type = ATOM_SC_SE;
        else ai->type = ATOM_SC_X_HETERO;
    } else if (ri->type == RESIDUE_WATER) {
      if(elem[1]=='_') {
        if     (elem[0]=='O') ai->type = ATOM_WT_O;
        else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
      }
    } else if (ri->type == RESIDUE_DNARNA) {
      if(elem[1]=='_') {
        if     (elem[0]=='C') ai->type = ATOM_DR_C;
        else if(elem[0]=='O') ai->type = ATOM_DR_O;
        else if(elem[0]=='N') ai->type = ATOM_DR_N;
        else if(elem[0]=='P') ai->type = ATOM_DR_P;
        else if(index("HDQ",elem[0])) ai->type = ATOM_HYDROGEN;
      }
    } else {                    // assume RESIDUE_LIGAND as default
      if(elem[1]=='_') {
        switch(elem[0]) {
          case 'C': ai->type = ATOM_LG_C; break;
          case 'O': ai->type = ATOM_LG_O; break;
          case 'N': ai->type = ATOM_LG_N; break;
          case 'P': ai->type = ATOM_LG_P; break;
          case 'S': ai->type = ATOM_LG_S; break;
          case 'H':
          case 'D':
          case 'Q': ai->type = ATOM_LG_H; break;
          case 'K': ai->type = ATOM_ALKALI;     break;
          case 'F':
          case 'I': ai->type = ATOM_HALOGEN;    break;
          case 'B': ai->type = ATOM_LIGHT;      break;
          default:  ai->type = ATOM_HEAVY;      break;
        }
      } else {
        if      (!strncmp(elem,"Li",2) || !strncmp(elem,"Na",2) || !strncmp(elem,"Rb",2) ||
                 !strncmp(elem,"Cs",2) || !strncmp(elem,"Fr",2)) ai->type = ATOM_ALKALI;
        else if (!strncmp(elem,"Be",2) || !strncmp(elem,"Mg",2) ||
                 !strncmp(elem,"Ca",2) || !strncmp(elem,"Sr",2) ||
                 !strncmp(elem,"Ba",2) || !strncmp(elem,"Ra",2)) ai->type = ATOM_ALKALINE;
        else if (!strncmp(elem,"Cl",2) || !strncmp(elem,"Br",2)) ai->type = ATOM_HALOGEN;
        else if (!strncmp(elem,"He",2) || !strncmp(elem,"Ne",2) || !strncmp(elem,"Al",2) ||
                 !strncmp(elem,"Si",2) || !strncmp(elem,"Ar",2)) ai->type = ATOM_LIGHT;
        else ai->type = ATOM_HEAVY;
      }
      if (ai->type==ATOM_HEAVY&&ri->type==RESIDUE_LIGAND) ri->type=RESIDUE_HEAVY;
//    if (ai->type==ATOM_HEAVY||ri->type==RESIDUE_LIGAND) ri->type=RESIDUE_HEAVY;       /* This wrong condition was misused in neighborhood v1.0 */
    }
  }

  /* Assign for each residue, whether residue contains more than one non-hydrogen atom, 2 indicates water */
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ri->isSingle=0;
    if(ri->type == RESIDUE_WATER) {
      ri->containsMetal=0;
      ri->isSingle=2;
    } else {
      numAtom=0;
      ri->containsMetal=0;
      for(j=0;j<ri->numAtom;j++) {
        ai=ri->AtomInfo+j;
        if(!ai->hydrogen) numAtom++;
        if(ai->isMetal) ri->containsMetal=1;
      }
      if(numAtom==1) ri->isSingle=1;
      /* Handle special case exception when a residue with single N atom on peptide chain N-terminal */
      if(ri->isSingle==1 && ri->type<=RESIDUE_AMINOACID) {
        ai=ri->AtomInfo;
        if(ai->type==ATOM_MC_N) ri->isSingle=0;
      }
    }
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeAssignCenterDisplacement(ObjEntityMolecule *I) {
  // Value to be assigned in this subroutine includes:
  // For each chain:   ObjChainInfo->Center
  // For each residue: ObjResidueInfo->center_displacement (regarding center of chain it belongs)
  // For each atom:    ObjAtomInfo->center_displacement    (regarding center of chain it belongs)
  //
  // ObjResidueInfo->Center, However, has already been assigned in subroutine EntityMoleculeReadPDBStr
  // And need not be assigned again here
  ObjChainInfo *ci;
  ObjResidueInfo *ri;
  ObjAtomInfo *ai;
  int i;
  float *v;
  // calculating ObjChainInfo->Center
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    VectorClear3f(ci->Center);
  }
  for(i=0;i<I->numAtom;i++) {
    v=I->Coord+(3*i);
    ai=I->AtomInfo+i;
    ri=ai->ResidueInfo;
    ci=ri->ChainInfo;
    VectorAdd3f(ci->Center, v);
  }
  for(i=0;i<I->numChain;i++) {
    ci=I->ChainInfo+i;
    VectorAverage3f(ci->Center, ci->numAtom);
  }

  // calculating ObjResidueInfo->center_displacement
  for(i=0;i<I->numResidue;i++) {
    ri=I->ResidueInfo+i;
    ci=ri->ChainInfo;
    ri->center_displacement=VectorDistance2v(ri->Center, ci->Center);
  }

  // calculating ObjAtomInfo->center_displacement
  for(i=0;i<I->numAtom;i++) {
    v=I->Coord+(3*i);
    ai=I->AtomInfo+i;
    ri=ai->ResidueInfo;
    ci=ri->ChainInfo;
    ai->center_displacement=VectorDistance2v(v, ci->Center);
  }
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeGenerateCenter(ObjEntityMolecule *I) {
  int i;
  float *v;
  if(I->numAtom) {
    v=I->Coord;
    VectorCopy3f(I->Min,v);
    VectorCopy3f(I->Max,v);
    for(i=0;i<I->numAtom;i++) {
      VectorMin3f(I->Min,v);
      VectorMax3f(I->Max,v);
      v+=3;
    }
  }
  VectorMiddle3f(I->Min,I->Max,I->Center);
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeNeighbor(ObjEntityMolecule *I, float cutoff, char *buffer_contact) {
  int i,j,a,b,c,d,e,f,contact_flag;
  int anbCount,maxNeighbor,anbCount0;                   /* For STEP 1 */
  int symopCount,contact_fwd,contact_alt,compare_atom;  /* For STEP 2 */
  int rnbCount,maxNeighbor2,rnbCount0;                  /* For STEP 3 */
  int rnbFound, distCalculated;
  int hasMetalContact;
  float dist, dist_temp;
  float *v1,*v2,v3[3];
  char *p,q[FileLineLength],msg[FileLineLength];
  ObjAtomInfo *atinfo, *ai1, *ai2, atm1, atm2;
  ObjResidueInfo       *ri1, *ri2, res1, res2;
  ObjNeighborInfo *anbinfo, *rnbinfo, *ani, *rni;
  ObjHash *hash;
  ObjNeighborStack *alt_stack;
  float cutoff2=cutoff+1.0f;
  int nalt1, alt_ai1[9], nalt2, alt_ai2[9], alt_processed;
  int cell_id, symop_id, symop_found;
  SymopDict *symmetryoperator_dictionary, *symopi;
  float v_shift[3],m_scale[4][4],m_inv_scale[4][4],m_symop[4][4];
  const ccp4_symop sm=*(I->scale_matrix);
  rotandtrn_to_mat4(m_scale,sm);
  invert4matrix((const float (*)[4])m_scale,m_inv_scale);
//printf("%f\t%f\t%f\n%f\t%f\t%f\n%f\t%f\t%f\n",sm.rot[0][0],sm.rot[0][1],sm.rot[0][2],
//       sm.rot[1][0],sm.rot[1][1],sm.rot[1][2],sm.rot[2][0],sm.rot[2][1],sm.rot[2][2]);
  /* allocate a maximal number of neighbor interactions for filled sphere using
   * cutoff as radius ((2*cutoff)^3), since the neighbor interaction will be
   * directional, only half of it will be used, thus 4*(cutoff^3). */
  atinfo=I->AtomInfo;

  if(I->numAtom) {
  /* STEP 0: pre-calculate number of atom neighbors from contact program output */
    maxNeighbor=0;
    p=buffer_contact;
    while(*p) {
      maxNeighbor++;
      p=str2nextline(p);
    }
    maxNeighbor *= 2;   // To accomodate potential alternative conformation
    AllocP(contact_pdb_buffer_str,char,((I->numAtom+maxNeighbor)*81));	// To store the symmetry-related PDB file
  /* STEP 1: calculate all atom neighbors, store with distance */
    maxNeighbor += 4*cutoff*cutoff*cutoff*I->numAtom;
    anbCount = 0;
    AllocP(anbinfo,ObjNeighborInfo,(maxNeighbor+1));
    EntityMoleculeGenerateCenter(I);
    hash=HashNew5(cutoff,I->Coord,I->numAtom,I->Min,I->Max);
    if(hash)
      for(i=0;i<I->numAtom;i++) {
        v1=I->Coord+(3*i);
        ai1=atinfo+i;
        AtomInfoPrintPDB(contact_pdb_buffer_str,ai1,ai1->ResidueInfo->chain,v1);
        if(ai1->hydrogen) continue;     /* skip hydrogen interactions */
        HashLocate(hash,v1,&a,&b,&c);   /* find the unit cube this vertex resides */
        for(d=a-1;d<=a+1;d++)
        for(e=b-1;e<=b+1;e++)
        for(f=c-1;f<=c+1;f++) {         /* for 27 adjacent cubes, seek for bond */
          j=*(HashFirst(hash,d,e,f));   /* get first vertex index */
          while(j>0) {                  /* stop when see -1, which is the end of list */
            if(i>=j)            { j=HashNext(hash,j); continue; }
                                        /* allow only one direction to avoid repetition */
            v2=I->Coord+(3*j);
            ai2=atinfo+j;
/* Slower version */
/* Can be further optimized, only calculate distance when the interaction involve
 * at least one atom which does not belong to standard amino acid or water */
            distCalculated=0;
            if((ai1->type>ATOM_SC_SE && ai1->type!=ATOM_WT_O) || (ai2->type>ATOM_SC_SE && ai2->type!=ATOM_WT_O)) {
              dist=(float)VectorDistance2v(v1,v2);
              distCalculated=1;
              if(dist<1.5) {
                ai1->numCovalentBond++;
                ai2->numCovalentBond++;
              }
            }
/* End Slower version */
            if(ai1->residue_index==ai2->residue_index) {
              if(!I->intra_residue_flag && ai1->type<=ATOM_WT_O && ai2->type<=ATOM_WT_O) {
                j=HashNext(hash,j); continue;
              } else {
                contact_flag = CONTACT_INTRA_RESIDUE;
              }
            } else {
              contact_flag = CONTACT_INTER_RESIDUE;
              if(ai1->ResidueInfo->molecule_index!=ai2->ResidueInfo->molecule_index) {
                contact_flag += CONTACT_INTER_MOLEC;
              }
            }
                                        /* skip intra-residue interactions */
            if(ai2->hydrogen)   { j=HashNext(hash,j); continue; }
                                        /* skip hydrogen interactions */
/* Faster version */
            if(!distCalculated) dist=(float)VectorDistance2v(v1,v2);
/* End Faster version */
            if(dist<=cutoff) {
              if(ai1->numAltLoc>1 && ai2->numAltLoc>1 && ai1->alt != ai2->alt) {
                if(str2symbolcnt(ai1->AltLocStr,ai2->alt) &&
                   str2symbolcnt(ai2->AltLocStr,ai1->alt)) {
                  // if there is potential for this pair of altLoc to agree with each other
                  j=HashNext(hash,j); continue; // skip when altLoc still do not agree
                }
              }
              if(anbCount >= maxNeighbor)
                PFatalError("IMPOSSIBLE: insufficient initial memory allocated for neighbor");
              ani=anbinfo+anbCount; ani->index=anbCount;
              contact_fwd=0;
              contact_alt=1;
              if (ai1->ResidueInfo->chain<ai2->ResidueInfo->chain) { contact_fwd=1;
              } else if (ai1->ResidueInfo->chain==ai2->ResidueInfo->chain) {
                if (ai1->ResidueInfo->resid<ai2->ResidueInfo->resid) { contact_fwd=1;
                } else if (ai1->ResidueInfo->resid==ai2->ResidueInfo->resid) {
                  compare_atom=strncmp(ai1->realname,ai2->realname,4);
                  if (compare_atom<0) { contact_fwd=1;
                  } else if (compare_atom==0) {
                    if (ai1->ResidueInfo->resi2<ai2->ResidueInfo->resi2) { contact_fwd=1;
                    } else if (ai1->ResidueInfo->resi2==ai2->ResidueInfo->resi2) {
                      if(strcmp(ai1->ResidueInfo->resn,ai2->ResidueInfo->resn)) {
                        contact_alt=0;
                      } else {
                        sprintf(msg, "Neighborhood calculation within AU shouldn't contain interaction with both ends (%d-%d) point to the same atom\n",
                            ai1->id, ai2->id);
                        PFatalError(msg);
                      }
                    }
                  }
                }
              }
              /* since j>i (atom index), we are assuming the same for
               * ai2->residue_index>ai1->residue_index (residue index) */
              if(contact_alt) {
                if(contact_fwd) {
                  ani->atom_index[0]=i;
                  ani->atom_index[1]=j;
                  ani->residue_index[0]=ai1->residue_index;
                  ani->residue_index[1]=ai2->residue_index;
                  VectorCopy3f(ani->direction,v2);
                  VectorSubstract3f(ani->direction,v1);
                } else {
                  ani->atom_index[0]=j;
                  ani->atom_index[1]=i;
                  ani->residue_index[0]=ai2->residue_index;
                  ani->residue_index[1]=ai1->residue_index;
                  VectorCopy3f(ani->direction,v1);
                  VectorSubstract3f(ani->direction,v2);
                }
              //ani->res1=ai1->ResidueInfo;
              //ani->atm1=ai1;
              //ani->res2=ai2->ResidueInfo;
              //ani->atm2=ai2;
                ani->contact_flag=contact_flag;
                ani->icell=555;   ani->isym=0;
                ani->distance=dist;
                ani->bfactor_correlation=(float)BfactorCorrelation(ai1->b,ai2->b);
                ai1->numAtmNeighbor++;
                ai2->numAtmNeighbor++;
                anbCount++;
              }
            }
            j=HashNext(hash,j);
          }
        }
      }
    HashFree(hash);
//  I->numAtmNeighbor  = anbCount;      // will be assigned after next while loop
    I->AtmNeighborInfo = anbinfo;
    anbCount0          = anbCount;      // save this value for residue neighbor processing

  /* STEP 2: Parse all neighbor from CCP4 contact program, and append to
   *         atom neighbor list with different contact_flag */
    p=buffer_contact;
    symopCount=0;
    alt_stack=stackNew();
    while(*p) {
      if(p[0]=='#') symopCount++;
      else break;
      p=str2nextline(p);
    }
    AllocP(symmetryoperator_dictionary,SymopDict,(symopCount+1));
    /* Read contact file header part */
    p=buffer_contact;
    symopCount=0;
    while(*p) {
      symopi=symmetryoperator_dictionary+symopCount;
      if(p[0]=='#') {
        p=str2cskip(p,' ');
        p=str2ccpy(symopi->symop_num,p,'|');
        p=str2ncpy(symopi->symop_str,p,SymopStrLen);
        if(sscanf(symopi->symop_num,"%d",&symopi->symop_id)!=1) symopi->symop_id=0;
        symopCount++;
      } else break;
      p=str2nextline(p);
    }
    /* Read contact file body part */
    hasMetalContact=0;
    while(*p) {
      p=str2ccpy(res1.resn,p,'|');      // Column 1-2:   resname, stored in res1, res2
      p=str2ccpy(res2.resn,p,'|');
      res1.chain=(*p); p=str2nskip(p,2);// Column 3-4:   chainid, stored in res1, res2
      res2.chain=(*p); p=str2nskip(p,2);
      p=str2ccpy(atm1.name,p,'|');      // Column 5-6:   atomname,stored in atm1, atm2
      p=str2ccpy(atm2.name,p,'|');
      p=str2ccpy(q,p,'|');              // Column 7-8:   translation (e.g.555), symop (e.g.005)
      if(sscanf(q,"%d",&cell_id)!=1) cell_id=555;
      for(i=0;i<3;i++) {
        v_shift[i]=(float)(q[i]-'5');
        if(v_shift[i]<-4 || v_shift[i]>4) PFatalError("Invalid v_shift for contact file record\n");
      }
      p=str2ccpy(q,p,'|');
      if(sscanf(q,"%d",&symop_id)!=1) symop_id=0;
      p=str2ccpy(q,p,'|');              // Column 9:     distance,stored in variable dist
      if(sscanf(q,"%f",&dist)!=1) dist=-1;
      if(dist<0.02) {                   // skip interaction if it's the same atom on border of assymetric unit 
        p=str2nextline(p);              // so that it is overlapped by symmetry operation
        continue;
      }
      p=str2cskip(p,'|');               // Column 10:    skipping
      p=str2ccpy(res1.resi,p,'|');      // Column 11-12: resseq,  stored in res1, res2
      p=str2ccpy(res2.resi,p,'|');
      if(sscanf(res1.resi,"%d",&res1.resid)!=1) res1.resid=-1;
      if(sscanf(res2.resi,"%d",&res2.resid)!=1) res2.resid=-1;
      
      contact_fwd=0;
      nalt1=AtomInfoLocateIndex4contact(alt_ai1, &res1, &atm1, I, ai1->index);
      nalt2=AtomInfoLocateIndex4contact(alt_ai2, &res2, &atm2, I, ai2->index);
      ai1=atinfo+alt_ai1[0];
      ai2=atinfo+alt_ai2[0];

      if (ai1->isMetal) { contact_fwd=1;
      } else if (ai2->isMetal) { contact_fwd=0;
      } else if (res1.chain<res2.chain) { contact_fwd=1;
      } else if (res1.chain==res2.chain) {
        if (res1.resid<res2.resid) { contact_fwd=1;
        } else if (res1.resid==res2.resid) {
          compare_atom=strncmp(atm1.name,atm2.name,4);
          if (compare_atom<0) { contact_fwd=1;
          } else if (compare_atom==0) { contact_fwd=2;  // Need special handling in case of an atom interact with its own mirror image by symmetry operation
          }
        }
      }
      if (contact_fwd) {
        if(anbCount >= maxNeighbor)
          PFatalError("IMPOSSIBLE: insufficient initial memory allocated for neighbor");
        alt_processed=0;
        if(nalt1>1 || nalt2>1 || contact_fwd==2) {      // Remove potential repetition in case of alternative conformation,
                                                        // or an atom interact with its own mirror image
          if(stackContains(alt_stack, &res1, &atm1, &res2, &atm2)) {
            alt_processed=1;
          } else {
            stackPush(alt_stack, &res1, &atm1, &res2, &atm2);
          }
        }
        if(!alt_processed) {
         for(a=0;a<nalt1;a++) {
          for(b=0;b<nalt2;b++) {
           symop_found=0;
           for(i=0;i<symopCount;i++) {
             symopi=symmetryoperator_dictionary+i;
             if(symopi->symop_id==symop_id) { symop_found=1; break; }
           }
           if(!symop_found) PFatalError("Invalid symop_id for contact file record\n");
           symop_to_mat4(symopi->symop_str,symopi->symop_str+strlen(symopi->symop_str),m_symop[0]);
           v1=I->Coord+(3*alt_ai1[a]);
           v2=I->Coord+(3*alt_ai2[b]);
           VectorCopy3f(v3, v2);                     // fprintf(stderr,"original   : "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, m_scale[0]);     // fprintf(stderr,"original-f : "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, m_symop[0]);     // fprintf(stderr,"transform-f: "); VectorPrint3f(v3);
           VectorAdd3f(v3, v_shift);                 // fprintf(stderr,"translate-f: "); VectorPrint3f(v3);
           VectorTransform3f44f(v3, m_inv_scale[0]); // fprintf(stderr,"transformed: "); VectorPrint3f(v3);
           dist_temp=(float)VectorDistance2v(v1,v3);
//         fprintf(stderr,"DEBUG: %s,\tdist:%f\tdist2:%f\n",symopi->symop_str,dist,dist_temp);
//         float diff = dist>dist_temp ? dist-dist_temp : dist_temp-dist;
//         printf("%f|%f|%f\n",dist,dist_temp,diff);
//         MatrixPrint44f(m_scale[0]);
//         MatrixPrint44f(m_symop[0]);
//         MatrixPrint44f(m_inv_scale[0]);

           if(dist_temp<=cutoff2) {
             contact_alt=1;
             ai1=atinfo+alt_ai1[a];
             ai2=atinfo+alt_ai2[b];
             if(ai1->numAltLoc>1 && ai2->numAltLoc>1 && ai1->alt != ai2->alt) {
               if(str2symbolcnt(ai1->AltLocStr,ai2->alt) &&
                  str2symbolcnt(ai2->AltLocStr,ai1->alt)) {
                 contact_alt=0;
               }
             }
             if(contact_alt) {
               ani=anbinfo+anbCount; ani->index=anbCount;
               ani->atom_index[0]=alt_ai1[a];
               ani->atom_index[1]=alt_ai2[b];
               ani->residue_index[0]=ai1->residue_index;
               ani->residue_index[1]=ai2->residue_index;
//             ani->contact_flag = (ai1->ResidueInfo->molecule_index==ai2->ResidueInfo->molecule_index) ? CONTACT_FLAG_UNDEF : CONTACT_INTER_MOLEC;
//             ani->contact_flag = CONTACT_INTER_AU + CONTACT_CUTOFF_6A + CONTACT_INTER_MOLEC;
               ani->contact_flag = CONTACT_INTER_RESIDUE + CONTACT_INTER_MOLEC + CONTACT_INTER_AU;
               ani->icell=cell_id;ani->isym=symop_id;
               ani->distance=dist_temp;
               VectorCopy3f(ani->direction,v3);
               VectorSubstract3f(ani->direction,v1);
               ani->bfactor_correlation=(float)BfactorCorrelation(ai1->b,ai2->b);
               ai1->numAtmNeighbor++;
               ai2->numAtmNeighbor++;
               anbCount++;
               if(ai1->isMetal && dist_temp<3 && ai2->protons != AN_C && ai2->protons != AN_H) { AtomInfoPrintPDB(contact_pdb_buffer_str,ai2,'#',v3); hasMetalContact=1; }
             }
           }
          }
         }
        }
      }
      p=str2nextline(p);
    }
    I->numAtmNeighbor = anbCount;
    stackFree(alt_stack);
    if(!hasMetalContact) { contact_pdb_buffer_str[0]=0; }

  /* STEP 3: build a list of atomneighbor index inside atom object to speed up future operation */
    for(i=0;i<I->numAtom;i++) {
      ai1=atinfo+i;
      AllocP(ai1->AtmNeighborIndex,int,(ai1->numAtmNeighbor+1));
      ai1->indAtmNeighbor=0;
    }
    for(i=0;i<anbCount;i++) {
      ani=anbinfo+i;
      ai1=atinfo+ani->atom_index[0];
      ai2=atinfo+ani->atom_index[1];
      ai1->AtmNeighborIndex[ai1->indAtmNeighbor]=i;
      ai2->AtmNeighborIndex[ai2->indAtmNeighbor]=i;
      ai1->indAtmNeighbor++;
      ai2->indAtmNeighbor++;
    }

  /* STEP 4: Search all atom neighbors, calculate residue neighbor with shortest
   *         atom neighbor distance */
    maxNeighbor2 = anbCount;
    rnbCount = 0;
    AllocP(rnbinfo,ObjNeighborInfo,(maxNeighbor2+1));
//  for(i=0;i<anbCount0;i++) {}                 // process first part, intra-AU neighbors
    for(i=0;i<I->numAtmNeighbor;i++) {          // process both parts together now, intra-AU and inter-AU neighbors
      ani=anbinfo+i;
      if(ani->contact_flag != CONTACT_INTRA_RESIDUE) {  // intra-residue neighbor will never be considered as residue neighbor
        rnbFound=-1;                      // 1) rnbFound is first used as the index of the residue neighbor
        for(j=rnbCount-1;j>=0;j--) {
          rni=rnbinfo+j;
          if(ani->residue_index[0]==rni->residue_index[0] &&
             ani->residue_index[1]==rni->residue_index[1] &&
             ani->icell==rni->icell && ani->isym==rni->isym) {
          // contact between the same pair of residues but from different symmetry operators are considered as different residues
            rnbFound=j;
            break;
          }
        }
        if (rnbFound==-1) {
          rni=rnbinfo+rnbCount;
          rni->index=rnbCount;
          rni->residue_index[0]=ani->residue_index[0];
          rni->residue_index[1]=ani->residue_index[1];
          rnbCount++;
          rnbFound=1;                     // 2) rnbFound is used as an indicator of whether or not data need to be copied
        } else if (ani->distance < rni->distance) rnbFound=1; else rnbFound=0;
        if(rnbFound) {
          rni->atom_index[0]=ani->atom_index[0];
          rni->atom_index[1]=ani->atom_index[1];
          rni->contact_flag=ani->contact_flag;
          rni->icell=ani->icell;  rni->isym=ani->isym;
          VectorCopy3f(rni->direction,ani->direction);
          rni->distance=ani->distance;
          rni->bfactor_correlation=ani->bfactor_correlation;
        }
      }
    }
/* The following content is obsolete,
 * it was used to make residue neighbors independently for intra-AU and inter-AU contacts
 * But in this new version, Everything is handled by a single loop,
 * such distinction are made by the ani->icell and ani->isym variables
 * regardless of whether or not it is from intra-AU or inter-AU contact */
//  rnbCount0          = rnbCount;      // save this value for residue neighbor processing
//
// All code for this second loop is the carbon copy as last loop except for those 2 lines that begin with /**/
//*/for(i=anbCount0;i<I->numAtmNeighbor;i++) {  // process second part, inter-AU contacts
//    ani=anbinfo+i;
//    rnbFound=-1;
//*/  for(j=rnbCount-1;j>=rnbCount0;j--) {
//      rni=rnbinfo+j;
//      if(ani->residue_index[0]==rni->residue_index[0] &&
//         ani->residue_index[1]==rni->residue_index[1] &&
//         ani->icell==rni->icell && ani->isym==rni->isym) {
//        rnbFound=j;
//        break;
//      }
//    }
//    if (rnbFound==-1) {
//      rni=rnbinfo+rnbCount;
//      rni->index=rnbCount;
//      rni->atom_index[0]=ani->atom_index[0];
//      rni->atom_index[1]=ani->atom_index[1];
//      rni->residue_index[0]=ani->residue_index[0];
//      rni->residue_index[1]=ani->residue_index[1];
//      rni->contact_flag=ani->contact_flag;
//        rni->icell=ani->icell;  rni->isym=ani->isym;
//        VectorCopy3f(rni->direction,ani->direction);
//      rni->distance=ani->distance;
//      rni->bfactor_correlation=ani->bfactor_correlation;
//      rnbCount++;
//    } else if (ani->distance < rni->distance) {
//      rni->atom_index[0]=ani->atom_index[0];
//      rni->atom_index[1]=ani->atom_index[1];
//      rni->contact_flag=ani->contact_flag;
//        rni->icell=ani->icell;  rni->isym=ani->isym;
//        VectorCopy3f(rni->direction,ani->direction);
//      rni->distance=ani->distance;
//      rni->bfactor_correlation=ani->bfactor_correlation;
//    }
//  }
    I->numResNeighbor  = rnbCount;
    I->ResNeighborInfo = rnbinfo;

  /* STEP 5: Calculate all peptide bond info, and assign previous/next residues
   *         in poly-peptide chain */
    for(i=0;i<I->numResNeighbor;i++) {
      rni=rnbinfo+i;
      ri1=I->ResidueInfo+rni->residue_index[0];
      ri2=I->ResidueInfo+rni->residue_index[1];
      ai1=I->AtomInfo+rni->atom_index[0];
      ai2=I->AtomInfo+rni->atom_index[1];
      if (ri1->type<=RESIDUE_AMINOACID && ri2->type<=RESIDUE_AMINOACID && rni->distance<1.5) {
        if (ai1->type==ATOM_MC_C && ai2->type==ATOM_MC_N) {
          ri1->next_index=ri2->index;
          ri2->prev_index=ri1->index;
          if (ri2->index!=ri1->index+1) {
            sprintf(msg,"Non-consecutive peptide bond found %s%d:%s%d (%s).\n",
                        ri1->resn, ri1->resid, ri2->resn, ri2->resid, I->pdbid);
            PWarning(msg);
          }
        } else if (ai1->type==ATOM_MC_N && ai2->type==ATOM_MC_C) {
          ri2->next_index=ri1->index;
          ri1->prev_index=ri2->index;
          if (ri1->index!=ri2->index+1) {
            sprintf(msg,"Non-consecutive peptide bond found %s%d:%s%d (%s).\n",
                        ri1->resn, ri1->resid, ri2->resn, ri2->resid, I->pdbid);
            PWarning(msg);
          }
        }
      }
    }

  /* STEP 6: Calculate all covalent bond for each atom for LCN calculation later on */
    for(i=0;i<I->numAtom;i++) {
      ai1=I->AtomInfo+i;
      ri1=ai1->ResidueInfo;
      if (ai1->hydrogen) ai1->numCovalentBond=1; 
      else if (ri1->isSingle==2) ai1->numCovalentBond=2;
      else if (ri1->isSingle==1) ai1->numCovalentBond=0;
      else {
        switch (ai1->type) {
          case ATOM_MC_N         : ai1->numCovalentBond=3; break;
          case ATOM_MC_CA        : ai1->numCovalentBond=4; break;
          case ATOM_MC_C         : ai1->numCovalentBond=3; break;
          case ATOM_MC_O         : ai1->numCovalentBond=1; break;
          case ATOM_SC_CB        : ai1->numCovalentBond=4; break;
          case ATOM_SC_C         : ai1->numCovalentBond=4; break;
          case ATOM_SC_N_ARG     : ai1->numCovalentBond=3; break;
          case ATOM_SC_O_AMIDE   : ai1->numCovalentBond=1; break;
          case ATOM_SC_N_AMIDE   : ai1->numCovalentBond=3; break;
          case ATOM_SC_O_CARBOXYL: ai1->numCovalentBond=1; break;
          case ATOM_SC_S_CYS     : ai1->numCovalentBond=2; break;
          case ATOM_SC_C_RING    : ai1->numCovalentBond=3; break;
          case ATOM_SC_N_HIS     : ai1->numCovalentBond=2; break;
          case ATOM_SC_N_LYS     : ai1->numCovalentBond=4; break;
          case ATOM_SC_N_TRP     : ai1->numCovalentBond=3; break;
          case ATOM_SC_S_MET     : ai1->numCovalentBond=2; break;
          case ATOM_SC_O_HYDROXYL: ai1->numCovalentBond=2; break;
          case ATOM_SC_O_PHENOL  : ai1->numCovalentBond=2; break;
          case ATOM_SC_SE        : ai1->numCovalentBond=2; break;
        }
      }
    }
  }
}


/*---------------------------------------------------------------------------*/
void EntityMoleculeLigandAngle(ObjEntityMolecule *I, float cutoff) {
  int i,j,k,l,m,n;
  int maxLigAtom,maxNeighbor,maxAngle,agCount;
  int numNeighbor;
  int *tmpNBindex, *tmpNBatomindex, tmpDistanceindex;
  float *v1, *v2, dist0, dist1, dist2, diff, dist_adjusted;
  ObjAtomInfo     *ai0, *ai1, *ai2, *atinfo;
  ObjResidueInfo  *ri0, *ri1, *ri2;
  ObjNeighborInfo *nbinfo, *nb1, *nb2, *nb3;
  ObjAngleInfo    *aginfo, *agi, *agi2;
  int indDistance=0;
  Vector3f vec0;

  atinfo      = I->AtomInfo;
  nbinfo      = I->AtmNeighborInfo;
  agCount     = 0;
  maxNeighbor = 8*cutoff*cutoff*cutoff;
  maxLigAtom  = 0;
  maxAngle    = 0;
  for(i=0;i<I->numResidue;i++) {
    ri0=I->ResidueInfo+i;
    if(ri0->type>=RESIDUE_ALKALI) {
      maxLigAtom+=ri0->numAtom;
      for(j=0;j<ri0->numAtom;j++) {
        ai0=ri0->AtomInfo+j;
        maxAngle+=(ai0->numAtmNeighbor)*(ai0->numAtmNeighbor+1);
      }
    }
  }
  AllocP(tmpNBindex,int,(maxNeighbor+1));
  AllocP(tmpNBatomindex,int,(maxNeighbor+1));
  AllocP(aginfo,ObjAngleInfo,(maxAngle+1));
  /* STEP 6: Calculate bond angle for all ligands environments */
  for(i=0;i<I->numResidue;i++) {
    ri0=I->ResidueInfo+i;
    if(ri0->type>=RESIDUE_ALKALI) {
      printf("Processing chain %c, resi %d, resn %s\n", ri0->chain, ri0->resid, ri0->resn);
      for(j=0;j<ri0->numAtom;j++) {
        ai0=ri0->AtomInfo+j;
        if(ai0->protons != AN_C) {      // Only make angles for non-carbon atoms in ligand
          /* make a list of neighbors */
          numNeighbor=0;
          for(k=0;k<ai0->numAtmNeighbor;k++) {
            nb1=nbinfo+ai0->AtmNeighborIndex[k];
            if (nb1->distance<=cutoff) {
              if (nb1->atom_index[1]==ai0->index) {
                ai1=atinfo+nb1->atom_index[0];
                if (ai1->protons != AN_C) { // Only make angles for non-carbon atoms in protein
                  tmpNBatomindex[numNeighbor]=nb1->atom_index[0];
                  tmpNBindex[numNeighbor]=nb1->index;
                  numNeighbor++;
                }
              } else if (nb1->atom_index[0]==ai0->index) {
                ai1=atinfo+nb1->atom_index[1];
                if (ai1->protons != AN_C) { // Only make angles for non-carbon atoms in protein
                  tmpNBatomindex[numNeighbor]=nb1->atom_index[1];
                  tmpNBindex[numNeighbor]=nb1->index;
                  numNeighbor++;
                }
              }
            }
          }
          /* make all combination with the list of neighbors */
          for(k=0;k<numNeighbor;k++) {
            ai1=atinfo+tmpNBatomindex[k];
            nb1=nbinfo+tmpNBindex[k];
            dist1=nb1->distance;
            for(l=k+1;l<numNeighbor;l++) {
              ai2=atinfo+tmpNBatomindex[l];
              nb2=nbinfo+tmpNBindex[l];
              dist2=nb2->distance;
              if (nb1->contact_flag<CONTACT_INTER_AU && nb2->contact_flag<CONTACT_INTER_AU) {
                v1=I->Coord+(3*ai1->index);
                v2=I->Coord+(3*ai2->index);
                dist0=(float)VectorDistance2v(v1,v2);
              } else {
                VectorCopy3f(vec0,nb1->direction);
                if((ai1->index==nb1->atom_index[0] && ai2->index==nb2->atom_index[1]) ||
                   (ai1->index==nb1->atom_index[1] && ai2->index==nb2->atom_index[0])) VectorAdd3f(vec0,nb2->direction);
                else VectorSubstract3f(vec0,nb2->direction);
                dist0=(float)VectorLength3f(vec0);
                /*obsolete*/ // dist0=-1;  // invalid dist0 value in case when inter-AU contact is encountered
              }
          /* make new angle object for each combination */
              agi=aginfo+agCount;
              agi->index=agCount;
              agi->atom_index[0]=ai0->index;
              agi->atom_index[1]=ai1->index;
              agi->atom_index[2]=ai2->index;
              agi->residue_index[0]=i;
              agi->residue_index[1]=ai1->residue_index;
              agi->residue_index[2]=ai2->residue_index;
              agi->atomneighbor_index[0]=nb1->index;
              agi->atomneighbor_index[1]=nb2->index;
              agi->distance[0]=dist0;
              agi->distance[1]=dist1;
              agi->distance[2]=dist2;
              agi->numDistance=0;
              agi->indDistance=-3;
              agi->DistanceList=NULL;
              if(dist0==-1) {   // OBSOLETE LOOP: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
                diff = (dist1>dist2) ? (dist1-dist2) : (dist2-dist1);
                AllocP(agi->DistanceList,float,(ai1->numAtmNeighbor+1));
                for(m=0;m<ai1->numAtmNeighbor;m++) {
                  nb3=nbinfo+ai1->AtmNeighborIndex[m];
                  if((nb3->atom_index[0]==ai1->index && nb3->atom_index[1]==ai2->index) ||
                     (nb3->atom_index[0]==ai2->index && nb3->atom_index[1]==ai1->index) ) {
                    if(nb3->distance<=1.3*(dist1+dist2) && nb3->distance>=0.9*diff) {
                      dist_adjusted=nb3->distance;
                      if (nb3->distance>=(dist1+dist2)) dist_adjusted=dist1+dist2-0.00001;
                      if (nb3->distance<=diff)          dist_adjusted=diff+0.00001;
                      tmpDistanceindex=0;
                      if(agi->numDistance) {
                        for(n=0;n<agi->numDistance;n++) if(dist_adjusted < agi->DistanceList[n]) break;
                        tmpDistanceindex=n;
                        for(n=agi->numDistance;n>tmpDistanceindex;n--) agi->DistanceList[n]=agi->DistanceList[n-1];
                      }
                      agi->DistanceList[tmpDistanceindex]=dist_adjusted;
                      agi->numDistance++;
                    }
                  }
                }
                agi->indDistance = (agi->numDistance) ? -1 : -2;
                if (agi->indDistance == -2) {
                  v1=I->Coord+(3*ai1->index);
                  v2=I->Coord+(3*ai2->index);
                  dist0=(float)VectorDistance2v(v1,v2);
                  if(dist0<=1.3*(dist1+dist2) && dist0>=0.9*diff) {
                    dist_adjusted=dist0;
                    if (dist0>=(dist1+dist2)) dist_adjusted=dist1+dist2-0.00001;
                    if (dist0<=diff)          dist_adjusted=diff+0.00001;
                    agi->distance[0]=dist_adjusted;
                  }
                }
              }
            //agi->angle = (dist0<0) ? -1 : VectorAngle3f(agi->distance);       // assign the angle later at the end of the procedure
              agCount++;
            }
          }
        }
      }
    }
  }
  agi=aginfo+agCount;
  agi->index=-1;
  I->numAngle=agCount;
  I->AngleInfo=aginfo;

  for(i=0;i<agCount;i++) {      // Mark redundant angle caused by symmetry operation
    agi=aginfo+i;
    if(agi->indDistance==-1) {  // OBSOLETE CONDITION: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
      indDistance=0;
      agi->indDistance=indDistance;
      for(j=i+1;j<agCount;j++) {
        agi2=aginfo+j;
        if(agi2->indDistance==-1) {
          if(  agi->atom_index[0]==agi2->atom_index[0] &&
             ((agi->atom_index[1]==agi2->atom_index[1] && agi->atom_index[2]==agi2->atom_index[2]) ||
              (agi->atom_index[1]==agi2->atom_index[2] && agi->atom_index[2]==agi2->atom_index[1]))) {
            indDistance++;
            agi2->indDistance=indDistance;
          }
        }
      }
    }
  }
  for(i=0;i<agCount;i++) {      // assign the corresponding distance by index
    agi=aginfo+i;
    if(agi->indDistance>=0) {   // OBSOLETE CONDITION: This is not gonna happen after v0.5.8 using the nb1->direction & nb2->direction
      agi->indDistance %= agi->numDistance;
      if(agi->distance[0]<0) agi->distance[0]=agi->DistanceList[agi->indDistance];
    }
    agi->angle = (agi->distance[0]<0) ? -1 : VectorAngle3f(agi->distance);
  }
}


/*---------------------------------------------------------------------------*/
int EntityMoleculeNeighborPrint(FILE *fout, ObjEntityMolecule *I, int isAtomNeighbor) {
  ObjResidueInfo *ri1, *ri2;
  ObjAtomInfo    *ai1, *ai2;
  ObjNeighborInfo *ni, *NeighborInfo;
  int numNeighbor, i, nameCompare, reverse=0;
  int isPeptideBond=0,numNeighborReturn=0;

  numNeighbor  = isAtomNeighbor ? I->numAtmNeighbor : I->numResNeighbor;
  NeighborInfo = isAtomNeighbor ? I->AtmNeighborInfo: I->ResNeighborInfo;
  numNeighborReturn=numNeighbor;
  for (i=0; i<numNeighbor; i++) {
    ni=NeighborInfo+i;
    ri1=I->ResidueInfo+ni->residue_index[0];
    ri2=I->ResidueInfo+ni->residue_index[1];
    ai1=I->AtomInfo+ni->atom_index[0];
    ai2=I->AtomInfo+ni->atom_index[1];
    isPeptideBond=0;
    if (isAtomNeighbor) {
      if (ai1->type < ai2->type)      reverse=0;
      else if (ai1->type > ai2->type) reverse=1;
      else {
        nameCompare=strcmp(ai1->realname,ai2->realname);
        if(nameCompare>0) reverse=1;
        else if(!nameCompare && ai1->index>ai2->index) reverse=1;
        else reverse=0;
      }
      /* Only C1-N2 interaction will be recorded for 6 peptide bond interaction
       * CA1-N2, CA1-CA2, C1-N2, C1-CA2, O1-N2, O1-CA2 */
      if (ri1->next_index==ri2->index && ri2->prev_index==ri1->index) {
        if ((ai1->type==ATOM_MC_CA || ai1->type==ATOM_MC_O) && (ai2->type==ATOM_MC_N || ai2->type==ATOM_MC_CA))
          isPeptideBond=1;
        else if (ai1->type==ATOM_MC_C && ai2->type==ATOM_MC_CA)
          isPeptideBond=1;
      } else if (ri1->prev_index==ri2->index && ri2->next_index==ri1->index) {
        if ((ai2->type==ATOM_MC_CA || ai2->type==ATOM_MC_O) && (ai1->type==ATOM_MC_N || ai1->type==ATOM_MC_CA))
          isPeptideBond=1;
        else if (ai2->type==ATOM_MC_C && ai1->type==ATOM_MC_CA)
          isPeptideBond=1;
      }
    } else {
      if (ri1->type < ri2->type)      reverse=0;
      else if (ri1->type > ri2->type) reverse=1;
      else {
        nameCompare=strcmp(ri1->resn,ri2->resn);
        if(nameCompare>0) reverse=1;
        else if(!nameCompare && ri1->index>ri2->index) reverse=1;
        else reverse=0;
      }
    }
    if (isPeptideBond) {numNeighborReturn--; continue;} /* Eliminate excessive peptide bond interaction in output */
    if (reverse) {
      fprintf(fout, "%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|%04d|%d|%d|%f|%f|%f|%f|%f\n",
          I->pdbfileid,         ni->index,
          ni->residue_index[1], ni->residue_index[0],
          ri2->resn,            ri1->resn,            ri2->type*100+ri1->type,
          ni->atom_index[1],    ni->atom_index[0],
          ai2->realname,        ai1->realname,        ai2->type*100+ai1->type,
          ni->contact_flag,     ni->icell,            ni->isym,         ni->distance,
         -ni->direction[0],    -ni->direction[1],    -ni->direction[2], ni->bfactor_correlation);
    } else {
      fprintf(fout, "%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|%04d|%d|%d|%f|%f|%f|%f|%f\n",
          I->pdbfileid,         ni->index,
          ni->residue_index[0], ni->residue_index[1],
          ri1->resn,            ri2->resn,            ri1->type*100+ri2->type,
          ni->atom_index[0],    ni->atom_index[1],
          ai1->realname,        ai2->realname,        ai1->type*100+ai2->type,
          ni->contact_flag,     ni->icell,            ni->isym,         ni->distance,
          ni->direction[0],     ni->direction[1],     ni->direction[2], ni->bfactor_correlation);
    }
  }
  return numNeighborReturn;
}

/*---------------------------------------------------------------------------*/
int EntityMoleculeAnglePrint(FILE *fout, ObjEntityMolecule *I) {
  int numAngle, i, nameCompare, reverse=0;
  ObjResidueInfo *rsinfo, *ri0, *ri1, *ri2;
  ObjAtomInfo    *atinfo, *ai0, *ai1, *ai2;
  ObjAngleInfo   *aginfo, *agi;
  rsinfo=I->ResidueInfo;
  atinfo=I->AtomInfo;
  aginfo=I->AngleInfo;
  for (i=0; i<I->numAngle; i++) {
    agi=aginfo+i;
    ai0=atinfo+agi->atom_index[0];
    ai1=atinfo+agi->atom_index[1];
    ai2=atinfo+agi->atom_index[2];
    ri0=rsinfo+agi->residue_index[0];
    ri1=rsinfo+agi->residue_index[1];
    ri2=rsinfo+agi->residue_index[2];
    if (ai1->type < ai2->type)      reverse=0;
    else if (ai1->type > ai2->type) reverse=1;
    else {
      nameCompare=strcmp(ai1->realname,ai2->realname);
      if(nameCompare>0) reverse=1;
      else if(!nameCompare && ai1->index>ai2->index) reverse=1;
      else reverse=0;
    }
    if (reverse) {
      fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%f|%f|%f|%f\n",
          I->pdbfileid,     agi->index,
          ri2->index,       ri0->index,       ri1->index,
          ri2->resn,        ri0->resn,        ri1->resn,
          ri2->type*10000  +ri0->type*100    +ri1->type,
          ai2->index,       ai0->index,       ai1->index,
          ai2->realname,    ai0->realname,    ai1->realname,
          ai2->type*10000  +ai0->type*100    +ai1->type,
          agi->atomneighbor_index[1],         agi->atomneighbor_index[0],
          agi->distance[2], agi->distance[1], agi->distance[0], agi->angle);
    } else {
      fprintf(fout, "%d|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%d|%d|%d|%f|%f|%f|%f\n",
          I->pdbfileid,     agi->index,
          ri1->index,       ri0->index,       ri2->index,
          ri1->resn,        ri0->resn,        ri2->resn,
          ri1->type*10000  +ri0->type*100    +ri2->type,
          ai1->index,       ai0->index,       ai2->index,
          ai1->realname,    ai0->realname,    ai2->realname,
          ai1->type*10000  +ai0->type*100    +ai2->type,
          agi->atomneighbor_index[0],         agi->atomneighbor_index[1],
          agi->distance[1], agi->distance[2], agi->distance[0], agi->angle);
    }
  }
  return I->numAngle;
}


/*---------------------------------------------------------------------------*/
int EntityMoleculeBondValencePrint(FILE *fout, ObjEntityMolecule *I, int isWater) {
  ObjResidueInfo *ri1, *ri2;
  ObjAtomInfo    *ai1, *ai2;
  ObjNeighborInfo *ni, *NeighborInfo;
  double bondvalence, sodium_bondvalence, calcium_bondvalence;
  Vector3f bv_direction;
  int numNeighbor, i, forward, reverse, lcn;
  int maxBondValence_id=0;
  int isSingleFlag=isWater+1;   // ri->isSingle flag should be 2 in case of water,
                                // 1 in case of ion, and 0 in case of SM/AA/DNA/RNA

  numNeighbor  = I->numAtmNeighbor;
  NeighborInfo = I->AtmNeighborInfo;
  if(!isWater) { AllocP(I->IonBondValenceInfo, ObjIonBondValenceInfo, numNeighbor); }
  for (i=0; i<numNeighbor; i++) {
    ni=NeighborInfo+i;
    ri1=I->ResidueInfo+ni->residue_index[0];
    ri2=I->ResidueInfo+ni->residue_index[1];
    ai1=I->AtomInfo+ni->atom_index[0];
    ai2=I->AtomInfo+ni->atom_index[1];
    if(ri1->isSingle==isSingleFlag || ri2->isSingle==isSingleFlag || (!isWater && (ai1->isMetal || ai2->isMetal))) {
//    printf("Record examined: %s(%c%d) ~ %s(%c%d)\n", ri1->resn, ri1->chain, ri1->resid, ri2->resn, ri2->chain, ri2->resid);
      if (ri1->isSingle==isSingleFlag) reverse=1; else reverse=0;
      if (ri2->isSingle==isSingleFlag) forward=1; else forward=0;
      if(!isWater) {
        if (ai1->isMetal) reverse=1;
        if (ai2->isMetal) forward=1;
      }
      if (reverse) {
        if(ai2->protons==AN_C) continue;
        lcn = ai2->numCovalentBond+1;
        calcium_bondvalence=AtomInfoBondValence(ai2, BV_Ca, ni->distance);
/* Obsolete handling of bond valence direction */
//      VectorClear3f(bv_direction); bv_direction_len=-1.0f;
//      if(ni->contact_flag<CONTACT_INTER_AU) {
//        VectorCopy3f(bv_direction, I->Coord+(3*ai1->index));
//        VectorSubstract3f(bv_direction, I->Coord+(3*ai2->index));
//        VectorScaleDown3f(bv_direction, ni->distance); bv_direction_len=ni->distance;
//      }
/* New handling of bond valence direction, with direction as an internal member of neighbor object */
        VectorReverse3f(bv_direction, ni->direction);
        VectorScaleDown3f(bv_direction, ni->distance);
        if (isWater) {
          sodium_bondvalence=AtomInfoBondValence(ai2, BV_Na, ni->distance);
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%d|%d|%d|%s|%d|%d|%d|%04d|%f|%f|%f|%f|%f|%f|%f\n",
              I->pdbfileid,         maxBondValence_id,    -1,               ni->index,
              ni->residue_index[1], ni->residue_index[0], ri2->resn,        ri2->type*100+ri1->type,
              ni->atom_index[1],    ni->atom_index[0],    ai2->realname,    ai2->type*100+ai1->type,
              ai2->protons,         lcn,                  ni->contact_flag, ni->distance,
              bv_direction[0],      bv_direction[1],      bv_direction[2],  ni->bfactor_correlation,
              sodium_bondvalence,   calcium_bondvalence);
        } else {
          bondvalence=AtomInfoBondValence(ai2, ai1->bv_index, ni->distance);
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|%d|%d|%d|%04d|%f|%f|%f|%f|%f|%f|%f\n",
              I->pdbfileid,         maxBondValence_id,    -1,              ni->index,
              ni->residue_index[1], ni->residue_index[0], ri2->resn,       ri1->resn,        ri2->type*100+ri1->type,
              ni->atom_index[1],    ni->atom_index[0],    ai2->realname,   ai1->realname,    ai2->type*100+ai1->type,
              ai2->protons,         ai1->protons,         lcn,             ni->contact_flag, ni->distance,
              bv_direction[0],      bv_direction[1],      bv_direction[2], ni->bfactor_correlation,
              bondvalence,          calcium_bondvalence);
          EntityMoleculeIonBondValenceAdd(I, maxBondValence_id, ni, 1, ai2, ai1, bondvalence, calcium_bondvalence, bv_direction);
        }
        maxBondValence_id++;
      }
      if (forward) {
        if(ai1->protons==AN_C) continue;
        lcn = ai1->numCovalentBond+1;
        calcium_bondvalence=AtomInfoBondValence(ai1, BV_Ca, ni->distance);
/* Obsolete handling of bond valence direction */
//      VectorClear3f(bv_direction); bv_direction_len=-1.0f;
//      if(ni->contact_flag<CONTACT_INTER_AU) {
//        VectorCopy3f(bv_direction, I->Coord+(3*ai2->index));
//        VectorSubstract3f(bv_direction, I->Coord+(3*ai1->index));
//        VectorScaleDown3f(bv_direction, ni->distance); bv_direction_len=ni->distance;
//      }
/* New handling of bond valence direction, with direction as an internal member of neighbor object */
        VectorCopy3f(bv_direction, ni->direction);
        VectorScaleDown3f(bv_direction, ni->distance);
        if (isWater) {
          sodium_bondvalence=AtomInfoBondValence(ai1, BV_Na, ni->distance);
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%d|%d|%d|%s|%d|%d|%d|%04d|%f|%f|%f|%f|%f|%f|%f\n",
              I->pdbfileid,         maxBondValence_id,    -1,               ni->index,
              ni->residue_index[0], ni->residue_index[1], ri1->resn,        ri1->type*100+ri2->type,
              ni->atom_index[0],    ni->atom_index[1],    ai1->realname,    ai1->type*100+ai2->type,
              ai1->protons,         lcn,                  ni->contact_flag, ni->distance,
              bv_direction[0],      bv_direction[1],      bv_direction[2],  ni->bfactor_correlation,
              sodium_bondvalence,   calcium_bondvalence);
        } else {
          bondvalence=AtomInfoBondValence(ai1, ai2->bv_index, ni->distance);
          fprintf(fout, "%d|%d|%d|%d|%d|%d|%s|%s|%d|%d|%d|%s|%s|%d|%d|%d|%d|%04d|%f|%f|%f|%f|%f|%f|%f\n",
              I->pdbfileid,         maxBondValence_id,    -1,              ni->index,
              ni->residue_index[0], ni->residue_index[1], ri1->resn,       ri2->resn,        ri1->type*100+ri2->type,
              ni->atom_index[0],    ni->atom_index[1],    ai1->realname,   ai2->realname,    ai1->type*100+ai2->type,
              ai1->protons,         ai2->protons,         lcn,             ni->contact_flag, ni->distance,
              bv_direction[0],      bv_direction[1],      bv_direction[2], ni->bfactor_correlation,
              bondvalence,          calcium_bondvalence);
          EntityMoleculeIonBondValenceAdd(I, maxBondValence_id, ni, 0, ai1, ai2, bondvalence, calcium_bondvalence, bv_direction);
        }
        maxBondValence_id++;
      }
    }
  }
  if(!isWater) { I->numIonBondValence=maxBondValence_id; }
  return maxBondValence_id;
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeIonBondValenceAdd(ObjEntityMolecule *I, int bondvalenceid, ObjNeighborInfo *ni, int reverse, ObjAtomInfo *ai1, ObjAtomInfo *ai2, double bondvalence, double calcium_bondvalence, float* bv_direction) {
  ObjIonBondValenceInfo *ibvi=I->IonBondValenceInfo+bondvalenceid;
  ibvi->index=bondvalenceid;
  ibvi->ni=ni;
  ibvi->reverse=reverse;
  ibvi->ri_lig=ai1->ResidueInfo;
  ibvi->ri_ion=ai2->ResidueInfo;
  ibvi->ai_lig=ai1;
  ibvi->ai_ion=ai2;
  ibvi->valid=1;
  ibvi->valid_lig_occup=ai1->occup;
  ibvi->bondvalence=bondvalence;
  ibvi->calcium_bondvalence=calcium_bondvalence;
  if(reverse) VectorReverse3f(ibvi->direction, ni->direction);
  else VectorCopy3f(ibvi->direction, ni->direction);
  VectorCopy3f(ibvi->bv_direction, bv_direction);
  ibvi->bv_direction_len=ni->distance;
  ibvi->bidentate=0;
}

/*---------------------------------------------------------------------------*/
int ObjIonBondValenceCopy(ObjIonBondValenceInfo *ibvi, ObjIonBondValenceInfo *ibvj) {
  ibvi->index  =ibvj->index;    ibvi->ni    =ibvj->ni;
  ibvi->reverse=ibvj->reverse;  ibvi->ri_lig=ibvj->ri_lig;
  ibvi->ri_ion =ibvj->ri_ion;   ibvi->ai_lig=ibvj->ai_lig;
  ibvi->ai_ion =ibvj->ai_ion;   ibvi->valid =ibvj->valid;
  ibvi->valid_lig_occup       = ibvj->valid_lig_occup;
  ibvi->bondvalence           = ibvj->bondvalence;
  ibvi->calcium_bondvalence   = ibvj->calcium_bondvalence;
  VectorCopy3f(ibvi->direction,ibvj->direction);
  VectorCopy3f(ibvi->bv_direction,ibvj->bv_direction);
  ibvi->bv_direction_len      = ibvj->bv_direction_len;
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceIonAICmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi1->ai_ion->index-ibvi2->ai_ion->index);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceValidCmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  return (ibvi2->valid-ibvi1->valid);
}

/*---------------------------------------------------------------------------*/
static int ObjIonBondValenceLigRICmp(const void *p1, const void *p2) {
  ObjIonBondValenceInfo *ibvi1=(ObjIonBondValenceInfo *)p1;
  ObjIonBondValenceInfo *ibvi2=(ObjIonBondValenceInfo *)p2;
  int op1, op2;
  int retval=ibvi1->ri_lig->index-ibvi2->ri_lig->index;
  if(!retval) {
    op1=ibvi1->ni->icell*1000+ibvi1->ni->isym;
    op2=ibvi2->ni->icell*1000+ibvi2->ni->isym;
    retval=op1-op2;
  }
  return retval;
}

/*---------------------------------------------------------------------------*/
static int doublecmp (const void *p1, const void *p2) {
  double *num1=(double *)p1;
  double *num2=(double *)p2;
  int retval=0;
  if(*num1>*num2) retval=1;
  else if(*num1<*num2) retval=-1;
  return retval;
}

/*---------------------------------------------------------------------------*/
int  ObjIonBindingSiteBidentate(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, ObjBidentateInfo *arr_bidentate, int cnt_bidentate) {
  // Search backwards for n=2 ligands, until got both of them distance<3.0
  Vector3f vec0;
  int bidentate=0;
  int bidentate_count=cnt_bidentate;
  ObjIonBondValenceInfo *ibvi1, *ibvi2;
  /* This procedures will be called only if bv_count>=2 */
  ibsi->num_bidentate_all++;
  if(bv_count==2) {
    ibvi1=bv_info;
    while((ibvi1->ai_lig->protons!=AN_O && ibvi1->ai_lig->protons!=AN_N && ibvi1->ai_lig->protons!=AN_S) ||
           ibvi1->ni->distance>=3.0f) ibvi1++;
    ibvi2=ibvi1+1;
    while((ibvi2->ai_lig->protons!=AN_O && ibvi2->ai_lig->protons!=AN_N && ibvi2->ai_lig->protons!=AN_S) ||
           ibvi2->ni->distance>=3.0f) ibvi2++;
    /* Mark special bidentate only when all of the following are true:
     * 1. From the same residue
     * 2. Form only two interactions
     * 3. Ligand Residue is an amino acid
     * 4. Both ligand atoms are from amino acid side chain */
    if(ibvi1->ai_lig->type>=ATOM_SC_N_ARG     && ibvi1->ai_lig->type<=ATOM_SC_N_HETERO &&
       ibvi2->ai_lig->type>=ATOM_SC_N_ARG     && ibvi2->ai_lig->type<=ATOM_SC_N_HETERO &&
       ibvi1->ri_lig->type<=RESIDUE_AMINOACID && ibvi2->ri_lig->type<=RESIDUE_AMINOACID) {
      if(ibvi1->ai_lig->protons==AN_O) {
        if(ibvi2->ai_lig->protons==AN_O)      {ibsi->num_bidentate_oo++;bidentate=1;}
        else if(ibvi2->ai_lig->protons==AN_N) {ibsi->num_bidentate_on++;bidentate=1;}
      } else if(ibvi1->ai_lig->protons==AN_N) {
        if(ibvi2->ai_lig->protons==AN_O)      {ibsi->num_bidentate_on++;bidentate=1;}
        else if(ibvi2->ai_lig->protons==AN_N) {ibsi->num_bidentate_nn++;bidentate=1;}
      }
    } else if(ibvi1->ri_lig->index==ibvi2->ri_lig->index && ibvi1->ri_lig->type>RESIDUE_AMINOACID && ibvi2->ri_lig->type>RESIDUE_AMINOACID) {
// ibvi1->ri_lig->index==ibvi2->ri_lig->index is not needed since this procedure is called only when 2 atoms are from the same residue
      VectorCopy3f(vec0,ibvi1->direction);
      VectorSubstract3f(vec0,ibvi2->direction);
      if(VectorLength3f(vec0)<2.0f && VectorLength3f(vec0)>1.0f) {
        bidentate=1;
      }
    }
    if(bidentate) bidentate_count=ObjBidentateAdd(arr_bidentate, cnt_bidentate, cnt_bidentate, ibvi1, ibvi2, -1.0f);
//  printf("bidentating: %s, %s, %s, %s\n",ibvi1->ri_lig->resn,ibvi1->ai_lig->realname,ibvi2->ri_lig->resn,ibvi2->ai_lig->realname);
  }
  return bidentate_count;
}

int  ObjBidentateAdd(ObjBidentateInfo *arr_bidentate, int cnt_bidentate, int ind_bidentate, ObjIonBondValenceInfo *ibvi1, ObjIonBondValenceInfo *ibvi2, double distance) {
  int    bidentate_type=2;
  int    bidentate_count=cnt_bidentate;
  double bidentate_distance=distance;
  Vector3f vec0;
  if(distance<=0.0f) {
    bidentate_type=1;
    VectorCopy3f(vec0,ibvi1->direction);
    VectorSubstract3f(vec0,ibvi2->direction);
    bidentate_distance=VectorLength3f(vec0);
  }
  ibvi1->bidentate=bidentate_type;
  ibvi2->bidentate=bidentate_type;
  arr_bidentate[ind_bidentate].bv1=ibvi1;
  arr_bidentate[ind_bidentate].bv2=ibvi2;
  arr_bidentate[ind_bidentate].distance=bidentate_distance;
  arr_bidentate[ind_bidentate].bondvalence=ibvi1->bondvalence+ibvi2->bondvalence;
  arr_bidentate[ind_bidentate].calcium_bondvalence=ibvi1->calcium_bondvalence+ibvi2->calcium_bondvalence;
  VectorCopy3f(arr_bidentate[ind_bidentate].bv_direction,ibvi1->bv_direction);
  VectorScaleUp3f(arr_bidentate[ind_bidentate].bv_direction,ibvi1->bondvalence);
  VectorCopy3f(vec0,ibvi2->bv_direction);
  VectorScaleUp3f(vec0,ibvi2->bondvalence);
  VectorAdd3f(arr_bidentate[ind_bidentate].bv_direction,vec0);
  VectorScaleDown3f(arr_bidentate[ind_bidentate].bv_direction,VectorLength3f(arr_bidentate[ind_bidentate].bv_direction));
  if(ind_bidentate==cnt_bidentate) bidentate_count++;
  return bidentate_count;
}

/*---------------------------------------------------------------------------*/
int ObjIonBindingSiteGeometry(ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count, int geometry_bidentate) {
  int i, j, k, dict_base, numDataSamples, numModelCases;
  double rmsd_geom_angle=180.0f, geo_diff, geo_scores[6], geo_angles[56];       // geo_angles, array of 28 is sufficient, 29-56 should never be used
  int geometry_type=GEOM_FREE, geometry_pseudo=-1, geometry_distort=1, rmsd_geom_weight=1;
  int updateFlag=0;
  ObjIonBondValenceInfo *gbvi, *gbvj;
  Vector3f *vi, *vj;
  GeometryDict *geodict=geometry_dictionary;
  double bondvalence_limit;
  int coordnum, oxidation_state;
  if(!bv_count) PFatalError("ObjIonBindingSiteGeometry is called without any vertex data.\n");
  oxidation_state = bv_info->ai_ion->bv_index == BV_undef ? 2 : bv_info->ai_ion->oxidation_state;
  if(oxidation_state<1 || oxidation_state>7) PFatalError("Unknown element and oxidation state.\n");
  // Calculate coordination number using default setting
  coordnum=0;
  for(i=0;i<bv_count;i++) {
    gbvi=bv_info+i;
    if(gbvi->bondvalence>=0.08f) coordnum++;
  }
  bondvalence_limit=oxidation_state*0.15f/coordnum;
  // Calculate coordination number according to preliminary coordination number
  if(bondvalence_limit>=0.08f) { bondvalence_limit=0.08f;
  } else {
    coordnum=0;
    for(i=0;i<bv_count;i++) {
      gbvi=bv_info+i;
      if(gbvi->bondvalence>=bondvalence_limit) coordnum++;
    }
  }
  switch(coordnum) {
    case 0:  geometry_type=GEOM_FREE; geometry_pseudo=-1; rmsd_geom_angle=180.0f; break;
    case 1:  geometry_type=GEOM_UNDERFLOW; geometry_pseudo=1; rmsd_geom_angle=180.0f; break;
    case 2:  dict_base=1;  numModelCases=4; break;
    case 3:  dict_base=5;  numModelCases=5; break;
    case 4:  dict_base=10; numModelCases=5; break;
    case 5:  dict_base=15; numModelCases=2; break;
    case 6:  dict_base=17; numModelCases=3; break;
    case 7:  dict_base=20; numModelCases=2; break;
    case 8:  dict_base=22; numModelCases=3; break;
    default: geometry_type=GEOM_OVERFLOW;  geometry_pseudo=0; rmsd_geom_angle=180.0f; break;
  }
  if(coordnum>=2 && coordnum<=8) {
    // Calculate set of observed angles
    k=0;
    for(i=0;i<bv_count;i++) {
      gbvi=bv_info+i;
      if(gbvi->bondvalence>=bondvalence_limit) {
        vi=&gbvi->bv_direction;
        for(j=i+1;j<bv_count;j++) {
        gbvj=bv_info+j;
          if(gbvj->bondvalence>=bondvalence_limit) {
            vj=&gbvj->bv_direction;
            geo_angles[k]=VectorAngle2v(*vi,*vj);
          //printf("%c%d-%s, %c%d-%s, %c%d-%s -- %f\n",
          //  gbvi->ri_lig->chain,gbvi->ri_lig->resid,gbvi->ai_lig->realname,
          //  gbvi->ri_ion->chain,gbvi->ri_ion->resid,gbvi->ai_ion->realname,
          //  gbvj->ri_lig->chain,gbvj->ri_lig->resid,gbvj->ai_lig->realname,geo_angles[k]);
            k++;
          }
        }
      }
    }
    // Compute geometry
    numDataSamples=k;
    qsort(geo_angles,k,sizeof(double),doublecmp);
    for(i=0;i<numModelCases;i++) {
      j=dict_base+i;
      if(geodict[j].index!=j || geodict[j].coord_number!=coordnum) PFatalError("Inconsistent data detected for geometry dictionary.\n");
      if(geodict[j].angle_number != numDataSamples) PFatalError("Inconsistent number of angles detected for geometry dictionary.\n");
      geo_scores[i]=0.0f;
      for(k=0;k<numDataSamples;k++) {
        if(geodict[j].angle[k] < 0 || geo_angles[k] < 0) PFatalError("Negative angle detected for geometry dictionary.\n");
        geo_diff=geodict[j].angle[k]-geo_angles[k];
        geo_scores[i]+=geo_diff*geo_diff;
      }
      geo_scores[i]=sqrt(geo_scores[i]/numDataSamples);
    //printf("atomname: %s, i: %d, geo_score: %f, type: %d, missing %d\n",bv_info->ai_ion->realname,i,geo_scores[i],geodict[j].geometry_type,geodict[j].geometry_pseudo);
      if(geo_scores[i]/geodict[j].rmsd_geom_weight<rmsd_geom_angle/rmsd_geom_weight) {
        geometry_type=geodict[j].geometry_type;
        geometry_pseudo=geodict[j].geometry_pseudo;
        rmsd_geom_angle=geo_scores[i];
        rmsd_geom_weight=geodict[j].rmsd_geom_weight;
      }
    }
  }
  geometry_distort = rmsd_geom_angle<rmsd_geom_weight/10.0f ? 0 : 1;
  updateFlag=0;
  if(ibsi->rmsd_geom_angle<0) updateFlag=1;
  else if(ibsi->geometry_type && geometry_type) {
    if (rmsd_geom_angle/rmsd_geom_weight<ibsi->rmsd_geom_angle/ibsi->rmsd_geom_weight) updateFlag=1;
  }
  if(updateFlag) {
    ibsi->geometry_type     =geometry_type;
    ibsi->geometry_bidentate=geometry_bidentate;
    ibsi->geometry_pseudo   =geometry_pseudo;
    ibsi->geometry_distort  =geometry_distort;
    ibsi->rmsd_geom_angle   =rmsd_geom_angle;
    ibsi->rmsd_geom_weight  =rmsd_geom_weight;
    ibsi->coord_number_geom =coordnum;
//  for(i=0;i<bv_count;i++) {
//    gbvi=bv_info+i;
//    printf("%f-",gbvi->bv_direction_len);
//  }
//  printf("\n");
  }
  return coordnum;
}
/*---------------------------------------------------------------------------*
# Total 1
# ( 0        linear)       180
# (-1 pseudo triangle)     120
# (-2 pseudo tetrahedral)  109.5
# (-2 pseudo square planar) 90
# Total 3
# ( 0        triangle)           120,   120,   120
# (-1 pseudo tetrahedral)        109.5, 109.5, 109.5
# (-1 pseudo square planar)       90,    90,   180
# (-2 pseudo trigonal bipyramid)  90,    90,   120
# (-3 pseudo octahedral)          90,    90,    90
# Total 6
# ( 0             tetrahedral)        109.5, 109.5, 109.5, 109.5, 109.5, 109.5
# ( 0             square planar)       90,    90,    90,    90,   180,   180
# (-1 tip  pseudo trigonal bipyramid)  90,    90,    90,   120,   120,   120
# (-1 base pseudo trigonal bipyramid)  90,    90,    90,    90,   120,   180
# (-2      pseudo octahedral)          90,    90,    90,    90,    90,   180
# Total 10
# ( 0        trigonal bipyramid) 90, 90, 90, 90, 90, 90, 120, 120, 120, 180
# (-1 pseudo octahedral)         90, 90, 90, 90, 90, 90, 90,  90,  180, 180
# Total 15
# (octahedral)         90, 90, 90, 90, 90, 90,  90,  90,  90,  90,  90,  90, 180, 180, 180
# (trigonal biprism)   6 x 66.421822, 3 x 101.536957, 6 x 143.130096 (using side=1, height=sqrt(2))
# (trigonal antiprism) 70, 70, 70, 70, 70, 70, 110, 110, 110, 110, 110, 110, 180, 180, 180 (approx.)
# Total 21
# ( 0 capped trigonal biprism)  4 x 71.565048, 2 x 129.23152, plus 15 parameters from trigonal biprism (approx.)
# ( 0 pentagonal bipyramid)     5 x 72, 10 x 90, 5 x 144, 1 x 180
# Total 28
# ( 0 cubic)                    4 x (70.53 70.53 70.53 109.47 109.47 109.47 180)
# ( 0 square antiprism)         4 x (4 x 74.858490, 118.528267, 2 x 141.592468)
# ( 0 dodecahedral)             4 x (5 x 73.69345,  138.91964,      147.3869)
 *---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
void ObjIonBindingSitePrint(FILE *fout, ObjIonBindingSiteInfo *ibsi, ObjIonBondValenceInfo *bv_info, int bv_count_redundant, int pdbfileid) {
  int i, j, k, tmpAtomCount, lastResidueID, lastSymop;
  ObjIonBondValenceInfo *ibvi, *ibvi2, *prev_residue_ibvi;
  ObjAtomInfo           *ai, *ai_ion=bv_info->ai_ion;
  ObjResidueInfo        *ri, *ri_ion=bv_info->ri_ion;
  Vector3f              bv_vec, calcium_bv_vec, vecsum_3a, calcium_vecsum_3a, vecsum_4a, calcium_vecsum_4a;
  /* Site0: store non-bidentate info
   * Site2: store bidentate info in double form
   * Site1: store bidentate info in its pseudo-atom form, normalized vector calculated */
  ObjIonBondValenceInfo *tmpGeoSite0, *tmpGeoSite2, *tmpGeoSite1, *gbvi, *gbvi1;
  int tmpBVID0, tmpBVID2, tmpBVID1;
  double rmsd_geom_angle=-1.0f;
  int l, b[7];

  Vector3f vec0;
  double vec0len;
  ObjBidentateInfo arr_bidentate[64];
  int cnt_bidentate=0;
  int ind_bidentate=0;
  int bv_count=bv_count_redundant;

  // Assign invalid ligands
  for(i=0;i<bv_count_redundant;i++) {
    ibvi=bv_info+i;
    if(ibvi->bv_direction_len<1.0f) {
      ibvi->valid=0;
      bv_count--;
    } else {
      for(j=i+1;j<bv_count_redundant;j++) {
        ibvi2=bv_info+j;
        VectorCopy3f(vec0,ibvi->direction);
        VectorSubstract3f(vec0,ibvi2->direction);
        if(ibvi->valid && ibvi2->valid && (VectorLength3f(vec0)<0.8f || (!ibvi->ai_lig->hydrogen && !ibvi2->ai_lig->hydrogen && VectorLength3f(vec0)<1.1f))) {
          k=0;
          if(ibvi->ai_lig->occup>ibvi2->ai_lig->occup) k=1;
          else if(ibvi->ai_lig->occup==ibvi2->ai_lig->occup) {
            if(ibvi->ai_lig->protons<ibvi2->ai_lig->protons) k=1;
            else if(ibvi->ai_lig->protons==ibvi2->ai_lig->protons) {
              if(ibvi->ai_lig->index<ibvi2->ai_lig->index) k=1;
            }
          }
          if(k) {
            ibvi2->valid=0;
            ibvi->valid_lig_occup+=ibvi2->valid_lig_occup;
          } else {
            ibvi->valid=0;
            ibvi2->valid_lig_occup+=ibvi->valid_lig_occup;
          }
          bv_count--;
        }
      }
    }
  }
  /* first sort by valid entries descendently */
  qsort(bv_info, bv_count_redundant, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceValidCmp);
  /* out of valid entries, now sort by residue id ascendingly */
  qsort(bv_info, bv_count, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceLigRICmp);

  
//for(i=0;i<bv_count;i++) {
//  ibvi=bv_info+i;
//  printf("%c%d-%s-%s: %d, %f, %d, %d\n",ibvi->ri_lig->chain,ibvi->ri_lig->resid,ibvi->ri_lig->resn,ibvi->ai_lig->realname,ibvi->ri_lig->index,ibvi->ni->distance,ibvi->ni->contact_flag,ibvi->ai_ion->protons);
//}
//printf("\n");

  ibsi->residueid_ion   =ri_ion->index;
  ibsi->atomid_ion      =ai_ion->index;
  ibsi->bfactor_env_avg =0.0f;  ibsi->occupancy_env_avg =0.0f;
  ibsi->coord_number_3a =0;     ibsi->coord_number_geom =0;
  ibsi->coord_number_4a =0;     ibsi->rmsd_geom_angle   =-1.0f;
  ibsi->rmsd_geom_weight=1;     ibsi->geometry_type     =GEOM_FREE;
  ibsi->geometry_bidentate=-1;  ibsi->geometry_pseudo   =-1;
  ibsi->geometry_distort=1;

  ibsi->num_oxygen      =0;     ibsi->num_nitrogen      =0;
  ibsi->num_sulfur      =0;     ibsi->num_phosphorus    =0;
  ibsi->num_carbon      =0;     ibsi->num_others        =0;
  ibsi->num04_oxygen_mc =0;     ibsi->num08_oxygen_amide=0;
  ibsi->num10_oxygen_carboxyl=0;ibsi->num17_oxygen_hydroxyl=0;
  ibsi->num18_oxygen_phenol=0;  ibsi->num26_oxygen_dnarna=0;
  ibsi->num28_oxygen_water=0;   ibsi->num31_oxygen_others=0;
  ibsi->num01_nitrogen_mc=0;    ibsi->num07_nitrogen_arginine=0;
  ibsi->num09_nitrogen_amide=0; ibsi->num13_nitrogen_histidine=0;
  ibsi->num14_nitrogen_lysine=0;ibsi->num15_nitrogen_tryptophan=0;
  ibsi->num25_nitrogen_dnarna=0;ibsi->num30_nitrogen_others=0;
  ibsi->num11_sulfur_cysteine=0;ibsi->num16_sulfur_methionine=0;
  ibsi->num33_sulfur_others=0;  ibsi->num19_selenium    =0;
  ibsi->num41_others    =0;     tmpAtomCount            =-1;
  lastResidueID         =-1;    lastSymop               =-1;
  ibsi->num_bidentate_all=0;    ibsi->num_bidentate_oo  =0;
  ibsi->num_bidentate_on=0;     ibsi->num_bidentate_nn  =0;
  ibsi->distance_avg    =0;     ibsi->distance_min      =10.0f;
  ibsi->distance_max    =-1.0f; ibsi->num_metal_4a      =0;
  VectorClear3f(vecsum_3a);     VectorClear3f(calcium_vecsum_3a);
  VectorClear3f(vecsum_4a);     VectorClear3f(calcium_vecsum_4a);
  ibsi->valence_3a       =0.0f; ibsi->vecsum_3a         =-1.0f;
  ibsi->calcium_valence_3a=0.0f;ibsi->calcium_vecsum_3a =-1.0f;
  ibsi->valence_4a       =0.0f; ibsi->vecsum_4a         =-1.0f;
  ibsi->calcium_valence_4a=0.0f;ibsi->calcium_vecsum_4a =-1.0f;

  for(i=0;i<bv_count;i++) {
    ibvi=bv_info+i;
    ai=ibvi->ai_lig;
    ri=ibvi->ri_lig;
    if(ai->protons==AN_H) continue;
    if (ibvi->ni->distance<4.0f) {
      ibsi->coord_number_4a++;
      if(ai->isMetal) ibsi->num_metal_4a++;
      if(ibvi->bondvalence>0) {
        ibsi->bfactor_env_avg+=ai->b*ibvi->bondvalence;
        ibsi->occupancy_env_avg+=ibvi->valid_lig_occup*ibvi->bondvalence;
        ibsi->valence_4a+=ibvi->bondvalence;
        VectorCopy3f(bv_vec,ibvi->bv_direction);
        VectorScaleUp3f(bv_vec,ibvi->bondvalence);
        VectorAdd3f(vecsum_4a,bv_vec);
      }
      if(ibvi->calcium_bondvalence>0) {
        ibsi->calcium_valence_4a+=ibvi->calcium_bondvalence;
        VectorCopy3f(calcium_bv_vec,ibvi->bv_direction);
        VectorScaleUp3f(calcium_bv_vec,ibvi->calcium_bondvalence);
        VectorAdd3f(calcium_vecsum_4a,calcium_bv_vec);
      }
      /* Additional steps if distance is less than 3 angstrom */
      if(ibvi->ni->distance<3.5f && ibvi->bondvalence>=0.08) {
        ibsi->coord_number_3a++;
        switch(ai->protons) {
          case AN_O: ibsi->num_oxygen++;     break;
          case AN_N: ibsi->num_nitrogen++;   break;
          case AN_S: ibsi->num_sulfur++;     break;
          case AN_P: ibsi->num_phosphorus++; break;
          case AN_C: ibsi->num_carbon++;     break;
          default:   ibsi->num_others++;     break;
        }
        switch(ai->type) {
          case ATOM_MC_N         : ibsi->num01_nitrogen_mc++;         break;
          case ATOM_MC_O         : ibsi->num04_oxygen_mc++;           break;
          case ATOM_SC_N_ARG     : ibsi->num07_nitrogen_arginine++;   break;
          case ATOM_SC_O_AMIDE   : ibsi->num08_oxygen_amide++;        break;
          case ATOM_SC_N_AMIDE   : ibsi->num09_nitrogen_amide++;      break;
          case ATOM_SC_O_CARBOXYL: ibsi->num10_oxygen_carboxyl++;     break;
          case ATOM_SC_S_CYS     : ibsi->num11_sulfur_cysteine++;     break;
          case ATOM_SC_N_HIS     : ibsi->num13_nitrogen_histidine++;  break;
          case ATOM_SC_N_LYS     : ibsi->num14_nitrogen_lysine++;     break;
          case ATOM_SC_N_TRP     : ibsi->num15_nitrogen_tryptophan++; break;
          case ATOM_SC_S_MET     : ibsi->num16_sulfur_methionine++;   break;
          case ATOM_SC_O_HYDROXYL: ibsi->num17_oxygen_hydroxyl++;     break;
          case ATOM_SC_O_PHENOL  : ibsi->num18_oxygen_phenol++;       break;
          case ATOM_SC_SE        : ibsi->num19_selenium++;            break;
          case ATOM_SC_O_HETERO  : ibsi->num31_oxygen_others++;       break;
          case ATOM_SC_N_HETERO  : ibsi->num30_nitrogen_others++;     break;
          case ATOM_SC_S_HETERO  : ibsi->num33_sulfur_others++;       break;
          case ATOM_DR_N         : ibsi->num25_nitrogen_dnarna++;     break;
          case ATOM_DR_O         : ibsi->num26_oxygen_dnarna++;       break;
          case ATOM_WT_O         : ibsi->num28_oxygen_water++;        break;
          case ATOM_LG_N         : ibsi->num30_nitrogen_others++;     break;
          case ATOM_LG_O         : ibsi->num31_oxygen_others++;       break;
          case ATOM_LG_S         : ibsi->num33_sulfur_others++;       break;
          default:                 ibsi->num41_others++;              break;      // Everything except O,N,S
        }
        ibsi->distance_avg+=ibvi->ni->distance;
        if(ibvi->ni->distance>ibsi->distance_max) ibsi->distance_max=ibvi->ni->distance;
        if(ibvi->ni->distance<ibsi->distance_min) ibsi->distance_min=ibvi->ni->distance;
        if(ibvi->bondvalence>0) {
          ibsi->valence_3a+=ibvi->bondvalence;
          VectorAdd3f(vecsum_3a,bv_vec);
        }
        if(ibvi->calcium_bondvalence>0) {
          ibsi->calcium_valence_3a+=ibvi->calcium_bondvalence;
          VectorAdd3f(calcium_vecsum_3a,calcium_bv_vec);
        }
        if(ai->protons==AN_O || ai->protons==AN_N || ai->protons==AN_S) {
          if(ibvi->ri_lig->index==lastResidueID && ibvi->ni->icell*1000+ibvi->ni->isym==lastSymop) {
            tmpAtomCount++;
          } else {
            lastResidueID=ibvi->ri_lig->index;
            lastSymop=ibvi->ni->icell*1000+ibvi->ni->isym;
            if(tmpAtomCount>=2) cnt_bidentate=ObjIonBindingSiteBidentate(ibsi,prev_residue_ibvi,tmpAtomCount,arr_bidentate,cnt_bidentate);
            tmpAtomCount=1;
            prev_residue_ibvi=ibvi;
          }
        }
      }
    }
  }
  // Finishing up amino acid side chain bidentate and summary info
  if(tmpAtomCount>=2) cnt_bidentate=ObjIonBindingSiteBidentate(ibsi,prev_residue_ibvi,tmpAtomCount,arr_bidentate,cnt_bidentate);
  ibsi->bfactor_env_avg   /= ibsi->valence_4a;
  ibsi->occupancy_env_avg /= ibsi->valence_4a;
  ibsi->distance_avg      /= ibsi->coord_number_3a;
  if(ibsi->distance_min>3.0f) ibsi->distance_min=-1.0f;
  ibsi->vecsum_3a=VectorLength3f(vecsum_3a);
  ibsi->calcium_vecsum_3a=VectorLength3f(calcium_vecsum_3a);
  ibsi->vecsum_4a=VectorLength3f(vecsum_4a);
  ibsi->calcium_vecsum_4a=VectorLength3f(calcium_vecsum_4a);
  // Now process water bidentate
  for(i=0;i<bv_count;i++) {
    ibvi=bv_info+i;
    if(ibvi->ai_lig->type==ATOM_WT_O && ibvi->ni->distance<3.0f) {
      for(j=i+1;j<bv_count;j++) {
        ibvi2=bv_info+j;
        if(ibvi2->ai_lig->type==ATOM_WT_O && ibvi->ni->distance<3.0f) {
          VectorCopy3f(vec0,ibvi->direction);
          VectorSubstract3f(vec0,ibvi2->direction);
          vec0len=VectorLength3f(vec0);
          if(vec0len<2.0f) {
            ind_bidentate=cnt_bidentate;
            for(k=0;k<cnt_bidentate;k++) {
              if(arr_bidentate[k].bv1==ibvi || arr_bidentate[k].bv1==ibvi2 ||
                 arr_bidentate[k].bv2==ibvi || arr_bidentate[k].bv2==ibvi2) {
                if(arr_bidentate[k].distance > vec0len) ind_bidentate=k;
              } 
            }
            cnt_bidentate=ObjBidentateAdd(arr_bidentate, cnt_bidentate, ind_bidentate, ibvi, ibvi2, vec0len);
          }
        }
      }
    }
  }


  AllocP(tmpGeoSite0, ObjIonBondValenceInfo, bv_count); tmpBVID0=0;  // To store non-bidentate BV records temporarily
  AllocP(tmpGeoSite2, ObjIonBondValenceInfo, bv_count); tmpBVID2=0;  // To store bidentate BV records temporarily
  AllocP(tmpGeoSite1, ObjIonBondValenceInfo, bv_count); tmpBVID1=0;  // To store bidentate BV records temporarily
  for(i=0;i<bv_count;i++) {
    ibvi=bv_info+i;
    ai=ibvi->ai_lig;
    if(ibvi->ni->distance<3.0f && ibvi->bv_direction_len>0.0f && !ibvi->bidentate && (ai->protons==AN_O || ai->protons==AN_N || ai->protons==AN_S)) {
      gbvi=tmpGeoSite0+tmpBVID0;
      tmpBVID0++;
      ObjIonBondValenceCopy(gbvi,ibvi);
    }
  }
  for(i=0;i<cnt_bidentate;i++) {
    ibvi=arr_bidentate[i].bv1;
    ibvi2=arr_bidentate[i].bv2;
    if((ibvi->ni->distance<3.0f && ibvi->bv_direction_len>0.0f) || (ibvi2->ni->distance<3.0f && ibvi2->bv_direction_len>0.0f)) {
      gbvi=tmpGeoSite2+tmpBVID2;
      ObjIonBondValenceCopy(gbvi,ibvi);
      gbvi=tmpGeoSite2+tmpBVID2+1;
      ObjIonBondValenceCopy(gbvi,ibvi2);
      tmpBVID2+=2;
      gbvi1=tmpGeoSite1+tmpBVID1;
      gbvi1->index=-1;    gbvi1->ni=NULL;
      gbvi1->reverse=-1;  gbvi1->valid=1;
      gbvi1->ri_lig=NULL; gbvi1->ri_ion=ibvi->ri_ion;
      gbvi1->ai_lig=NULL; gbvi1->ai_ion=ibvi->ai_ion;
      gbvi1->bondvalence=arr_bidentate[i].bondvalence;
      gbvi1->calcium_bondvalence=arr_bidentate[i].calcium_bondvalence;
      VectorCopy3f(gbvi1->bv_direction,arr_bidentate[i].bv_direction);
      gbvi1->bv_direction_len=-1.0f;
      tmpBVID1++;
    }
  }

//printf("tmpBVID: %d %d %d\n",tmpBVID0,tmpBVID1,tmpBVID2);
//for(i=0;i<tmpBVID0;i++) { gbvi=tmpGeoSite0+i; VectorPrint3f(gbvi->bv_direction); }
//for(i=0;i<tmpBVID1;i++) { gbvi=tmpGeoSite1+i; VectorPrint3f(gbvi->bv_direction); }
//for(i=0;i<tmpBVID2;i++) { gbvi=tmpGeoSite2+i; VectorPrint3f(gbvi->bv_direction); }
  for(i=0;i<tmpBVID0;i++) {
    gbvi=tmpGeoSite0+i;
  }
  if(tmpBVID2!=2*tmpBVID1) PFatalError("Inconsistent data tmpBVID2!=2*tmpBVID1.\n");
  if(tmpBVID1==0 || (tmpBVID0+tmpBVID1<=2)) {   // Reference table top left corner
    for(i=0;i<tmpBVID2;i++) {
      gbvi=tmpGeoSite0+tmpBVID0+i;
      gbvi1=tmpGeoSite2+i;
      ObjIonBondValenceCopy(gbvi,gbvi1);
    }
    if(tmpBVID0+tmpBVID2)
      ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+tmpBVID2,0);
  } else if(tmpBVID0+tmpBVID1>=8) {             // Refernece table bottom right corner OVERFLOW
    for(i=0;i<tmpBVID1;i++) {
      gbvi=tmpGeoSite0+tmpBVID0+i;
      gbvi1=tmpGeoSite1+i;
      ObjIonBondValenceCopy(gbvi,gbvi1);
    }
    ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+tmpBVID1,tmpBVID1);
  } else {
    l=1<<tmpBVID1;
    for(i=0;i<l;i++) {
      k=0;
      for(j=0;j<tmpBVID1;j++) {
        b[j]=(i>>j)%2;
        k+=b[j];
        k++;
      }
      if(tmpBVID0+k>8) continue;
//    for(j=0;j<tmpBVID1;j++) printf("%d,",b[j]);
//    printf("\n");
      k=0;
      for(j=0;j<tmpBVID1;j++) {
        gbvi=tmpGeoSite0+tmpBVID0+k;
        if(b[j]) {
          gbvi1=tmpGeoSite2+(j*2);
          ObjIonBondValenceCopy(gbvi,gbvi1);
          k++;
          gbvi=tmpGeoSite0+tmpBVID0+k;
          gbvi1=tmpGeoSite2+(j*2+1);
        } else {
          gbvi1=tmpGeoSite1+j;
        }
        ObjIonBondValenceCopy(gbvi,gbvi1);
        k++;
      }
      ObjIonBindingSiteGeometry(ibsi,tmpGeoSite0,tmpBVID0+k,tmpBVID2-k);
    }
  }
  FreeP(tmpGeoSite1);
  FreeP(tmpGeoSite2);
  FreeP(tmpGeoSite0);
               /* 1  2  3  4  5  6  7  8  9 10 11  1  2  3  4  5  6  7  8  9 10 11 12 13  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16  1  2  3  4  5  6  7  8  9 10 11 12  1  2  3  4  5  6  7  8  9 10*/
  fprintf(fout, "%d|%d|%d|%s|%d|%s|%d|%f|%f|%f|%f|%d|%d|%d|%d|%d|%d|%f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%f|%f|%f|%f|%f|%f|%f|%d|%d|%f|%f|%f|%f\n",
      pdbfileid,               ibsi->index,            ri_ion->index,           ri_ion->resn,          ai_ion->index,
      ai_ion->realname,        ai_ion->protons,        ai_ion->b,               ibsi->bfactor_env_avg, ai_ion->occup,
      ibsi->occupancy_env_avg, ibsi->coord_number_3a,  ibsi->coord_number_geom, ibsi->geometry_type,   ibsi->geometry_bidentate,
      ibsi->geometry_pseudo,   ibsi->geometry_distort, ibsi->rmsd_geom_angle,   ibsi->num_oxygen,      ibsi->num_nitrogen,
      ibsi->num_sulfur,        ibsi->num_phosphorus,   ibsi->num_carbon,        ibsi->num_others,
      ibsi->num04_oxygen_mc,       ibsi->num08_oxygen_amide,        ibsi->num10_oxygen_carboxyl, ibsi->num17_oxygen_hydroxyl,
      ibsi->num18_oxygen_phenol,   ibsi->num26_oxygen_dnarna,       ibsi->num28_oxygen_water,    ibsi->num31_oxygen_others,
      ibsi->num01_nitrogen_mc,     ibsi->num07_nitrogen_arginine,   ibsi->num09_nitrogen_amide,  ibsi->num13_nitrogen_histidine,
      ibsi->num14_nitrogen_lysine, ibsi->num15_nitrogen_tryptophan, ibsi->num25_nitrogen_dnarna, ibsi->num30_nitrogen_others,
      ibsi->num11_sulfur_cysteine, ibsi->num16_sulfur_methionine,   ibsi->num33_sulfur_others,   ibsi->num19_selenium, ibsi->num41_others,
      ibsi->num_bidentate_all,     ibsi->num_bidentate_oo,  ibsi->num_bidentate_on, ibsi->num_bidentate_nn,   ibsi->distance_avg,
      ibsi->distance_min,    ibsi->distance_max, ibsi->valence_3a, ibsi->vecsum_3a, ibsi->calcium_valence_3a, ibsi->calcium_vecsum_3a,
      ibsi->coord_number_4a, ibsi->num_metal_4a, ibsi->valence_4a, ibsi->vecsum_4a, ibsi->calcium_valence_4a, ibsi->calcium_vecsum_4a);
}
/*---------------------------------------------------------------------------* 
 * Table for bidentate evaluation
 * Header: Site0: number of non-bidentate ligands
 *         Site2: number of bidentate ligand atoms
 *         Site1: number of bidentate ligand residues
 * Legend: Site0: Only use Site0 ligands for geometry calculation
 *         Site2: Only use Site2 ligands for geometry calculation
 *         Site1: Only use Site1 pseudo atoms for geometry calculation
 *         1-extra: 1 Site  out of N sites can be treated as either bidentate or non-bidentate
 *         4-extra: 4 Sites out of N sites can be treated as either bidentate or non-bidentate
        Site2   2       4       6       8       10      12      14      16
        Site1   1       2       3       4       5       6       7       8
 *Site0 under   Site2   Site2   3-extra 4-extra 3-extra 2-extra 1-extra Site1
 *    1 Site0   Site2   2-extra 3-extra 3-extra 2-extra 1-extra Site1
 *    2 Site0   1-extra 2-extra 3-extra 2-extra 1-extra Site1
 *    3 Site0   1-extra 2-extra 2-extra 1-extra Site1
 *    4 Site0   1-extra 2-extra 1-extra Site1
 *    5 Site0   1-extra 1-extra Site1                    O V E R
 *    6 Site0   1-extra Site1                            F L O W
 *    7 Site0   Site1
 *    8 Site0   
 *---------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------*/
int  EntityMoleculeIonBindingSitePrint(FILE *fout, ObjEntityMolecule *I) {
  int i, j, maxSites, maxAtoms, tmpAtomCnt, lastAtomID;
  ObjIonBondValenceInfo *ibvi;
  ObjIonBindingSiteInfo *ibsi;
  qsort(I->IonBondValenceInfo, I->numIonBondValence, sizeof(ObjIonBondValenceInfo), ObjIonBondValenceIonAICmp);
  /* count number of sites for memory allocation */
  maxSites=0;
  maxAtoms=0;
  tmpAtomCnt=-1;
  lastAtomID=-1;
  for (i=0;i<I->numIonBondValence;i++) {
    ibvi=I->IonBondValenceInfo+i;
    if(ibvi->ai_ion->index==lastAtomID) {
      tmpAtomCnt++;
    } else {
      lastAtomID=ibvi->ai_ion->index;
      if(tmpAtomCnt>maxAtoms) maxAtoms=tmpAtomCnt;
      tmpAtomCnt=1;
      maxSites++;
    }
  }
  if(tmpAtomCnt>maxAtoms) maxAtoms=tmpAtomCnt;
  AllocP(I->IonBindingSiteInfo, ObjIonBindingSiteInfo, maxSites);
  /* site info assignment */
  tmpAtomCnt=-1;
  lastAtomID=-1;
  maxSites=0;
  for (i=0;i<I->numIonBondValence;i++) {
    ibvi=I->IonBondValenceInfo+i;
    if(ibvi->ai_ion->index==lastAtomID) {
      tmpAtomCnt++;
    } else {
      lastAtomID=ibvi->ai_ion->index;
      if(tmpAtomCnt>0) ObjIonBindingSitePrint(fout, ibsi, ibvi-tmpAtomCnt, tmpAtomCnt, I->pdbfileid);
      tmpAtomCnt=1;
      ibsi=I->IonBindingSiteInfo+maxSites;
      ibsi->index=maxSites;
      maxSites++;
    }
  }
  if(tmpAtomCnt>0) ObjIonBindingSitePrint(fout, ibsi, ibvi+1-tmpAtomCnt, tmpAtomCnt, I->pdbfileid);
  I->numIonBindingSite=maxSites;
  return maxSites;
}

/*---------------------------------------------------------------------------*/
void EntityMoleculeReport(ObjEntityMolecule *I, float cutoff, char *temp_dir) {
  ObjGeneOntologyInfo*goi;
  ObjAssemblyInfo    *assi;
  ObjCavityInfo      *cavi;
  ObjComponentInfo   *comi;     
  ObjFunctionInfo    *funi;     
  ObjKeywordInfo     *keyi;     
  ObjSymChainInfo    *symi;
  ObjMoleculeInfo    *mi;
  ObjDomainInfo      *di;
  ObjChainInfo       *ci;
  ObjResidueInfo     *ri;
  ObjAtomInfo        *ai;
  float              *coord;
  int i,j,numGO=0,numCavity=0,numFunction=0,numSymChain=0,output_redirected=0,numBondValence=0,numNeighbor=0,numIonBindingSite=0;
  EntityFileName temp_pdbfile_path, temp_ccdinfo_path,   temp_geneontology_path, temp_assembly_path;
  EntityFileName temp_cavity_path,  temp_component_path, temp_function_path,     temp_keyword_path;
  EntityFileName temp_cdchain_path, temp_symchain_path,  temp_molecule_path,     temp_domain_path;
  EntityFileName temp_residue_path, temp_atom_path,      temp_neighbor_path,     temp_atomneighbor_path;
  EntityFileName temp_ligbondangle_path,    temp_ion_bondvalence_path,  temp_water_bondvalence_path;
  EntityFileName temp_ion_bindingsite_path, sql_copydata_path, crystal_contact_pdbfile;
  FILE *fout = stdout;
  if (strlen(temp_dir) > 0) {
    strcpy(temp_pdbfile_path,           temp_dir);  strcat(temp_pdbfile_path,           "PDBFILE.data");
    strcpy(temp_ccdinfo_path,           temp_dir);  strcat(temp_ccdinfo_path,           "CCDINFO.data");
    strcpy(temp_geneontology_path,      temp_dir);  strcat(temp_geneontology_path,      "GENEONTOLOGY.data");
    strcpy(temp_assembly_path,          temp_dir);  strcat(temp_assembly_path,          "ASSEMBLY.data");
    strcpy(temp_cavity_path,            temp_dir);  strcat(temp_cavity_path,            "CAVITY.data");
    strcpy(temp_component_path,         temp_dir);  strcat(temp_component_path,         "COMPONENT.data");
    strcpy(temp_function_path,          temp_dir);  strcat(temp_function_path,          "FUNCTION.data");
    strcpy(temp_keyword_path,           temp_dir);  strcat(temp_keyword_path,           "KEYWORD.data");
    strcpy(temp_cdchain_path,           temp_dir);  strcat(temp_cdchain_path,           "CDHIT_CHAIN.data");
    strcpy(temp_symchain_path,          temp_dir);  strcat(temp_symchain_path,          "SYMOP_CHAIN.data");
    strcpy(temp_molecule_path,          temp_dir);  strcat(temp_molecule_path,          "MOLECULE.data");
    strcpy(temp_domain_path,            temp_dir);  strcat(temp_domain_path,            "DOMAIN.data");
    strcpy(temp_residue_path,           temp_dir);  strcat(temp_residue_path,           "RESIDUE.data");
    strcpy(temp_atom_path,              temp_dir);  strcat(temp_atom_path,              "ATOM.data");
    strcpy(temp_neighbor_path,          temp_dir);  strcat(temp_neighbor_path,          "NEIGHBOR.data");
    strcpy(temp_atomneighbor_path,      temp_dir);  strcat(temp_atomneighbor_path,      "ATOMNEIGHBOR.data");
    strcpy(temp_ligbondangle_path,      temp_dir);  strcat(temp_ligbondangle_path,      "LIGAND_BONDANGLE.data");
    strcpy(temp_ion_bondvalence_path,   temp_dir);  strcat(temp_ion_bondvalence_path,   "ION_BONDVALENCE.data");
    strcpy(temp_water_bondvalence_path, temp_dir);  strcat(temp_water_bondvalence_path, "WATER_BONDVALENCE.data");
    strcpy(temp_ion_bindingsite_path,   temp_dir);  strcat(temp_ion_bindingsite_path,   "ION_BINDINGSITE.data");
    strcpy(sql_copydata_path,           temp_dir);  strcat(sql_copydata_path,           "copyNeighborhoodData.sql");
    strcpy(crystal_contact_pdbfile,     temp_dir);  strcat(crystal_contact_pdbfile,     "contact.pdb");
    output_redirected=1;
  }

  if(strlen(contact_pdb_buffer_str)>0) {
    fout=fopen(crystal_contact_pdbfile,"w");
    fprintf(fout, "%s", contact_pdb_buffer_str);
    fclose(fout);
  }

  /* For TABLE ccdinfo, 14 fields */
  if(I->tables[TABLE_CCDINFO]) {
   printf("#CCDINFO(%d):%s\n", I->pdbfileid, I->filename);
   if (output_redirected) fout=fopen(temp_ccdinfo_path,"w");
   fprintf(fout, "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",    I->pdbfileid,
       I->organism_id,  I->ec_primary,    I->ec_3rd_level, I->ec_4th_level, I->ec_complex,
       I->cluster50_id, I->cluster90_id,  I->go_process,   I->go_function,  I->go_component, 
       I->cath_primary, I->cath_topology, I->cath_superfamily);
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE geneontologies, 14 fields */
  if(I->tables[TABLE_GENEONTOLOGIES]) {
   if (output_redirected) fout=fopen(temp_geneontology_path,"w");
   for (i=0; i<I->numChain; i++) {
     ci=I->ChainInfo+i;
     for (j=0; j<ci->numBiolProcess; j++) {
       goi=ci->BiolProcessInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
     for (j=0; j<ci->numMoleFunction; j++) {
       goi=ci->MoleFunctionInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
     for (j=0; j<ci->numCellComponent; j++) {
       goi=ci->CellComponentInfo+j; numGO++;
       fprintf(fout, "%d|%s|%c|%c|%d|%d|%s|%s|%s|%d|%s|%s|%c|%d\n", I->pdbfileid, I->pdbid,
           ci->chainid,        goi->go_type,      goi->go_id,       goi->qualifier,
           goi->evidence,      goi->xref_db_name, goi->xref_db_id,  goi->organism_id,
           goi->creation_date, goi->created_by,   goi->ref_db_name, goi->ref_db_id);
     }
   }
   if (output_redirected) fclose(fout);
   printf("#GENEONTOLOGY:%d\n", numGO);
  }
  
  /* For TABLE assemblies, 20 fields */
  if(I->tables[TABLE_ASSEMBLIES]) {
   printf("#ASSEMBLY:%d\n", I->numAssembly);
   if (output_redirected) fout=fopen(temp_assembly_path,"w");
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     numCavity+=assi->numCavity;
     numSymChain+=assi->numSymChain;
     fprintf(fout, "%d|%d|%d|%03d|%d|%d|%d|%d|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f|%f\n",
         I->pdbfileid,           assi->index,            assi->assembly_number,  assi->type,
         assi->numChain,         assi->numSymChain,      assi->numCavity,        assi->numSurfraceAtom,
         assi->total_asa,        assi->polar_asa,        assi->positive_asa,
         assi->negative_asa,     assi->total_bb_asa,     assi->polar_bb_asa,
         assi->total_msa,        assi->polar_msa,        assi->positive_msa,
         assi->negative_msa,     assi->total_bb_msa,     assi->polar_bb_msa);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE cavities, 6 fields */
  if(I->tables[TABLE_CAVITIES]) {
   printf("#CAVITY:%d\n", numCavity);
   if (output_redirected) fout=fopen(temp_cavity_path,"w");
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     for (j=0; j<assi->numCavity; j++) {
       cavi=assi->CavityInfo+j;
       fprintf(fout, "%d|%d|%d|%d|%d|%d\n", I->pdbfileid,
         cavi->index, cavi->numResidue, cavi->numAtom, cavi->volume, cavi->assembly_index);
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE components, 11 fields */
  if(I->tables[TABLE_COMPONENTS]) {
   printf("#COMPONENT:%d\n", I->numComponent);
   if (output_redirected) fout=fopen(temp_component_path,"w");
   for (i=0; i<I->numComponent; i++) {
     comi=I->ComponentInfo+i;
     numFunction+=comi->numFunction;
     fprintf(fout, "%d|%d|%d|%s|%d|%d|%d|%d|%d|%d|%s\n", I->pdbfileid,
       comi->index,       comi->componentnum,  comi->component_name,
       comi->numChain,    comi->numKeyword,    comi->numFunction,
       comi->engineered,  comi->mutation,      comi->organism_id, comi->organism_name);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE functions, 6 fields */
  if(I->tables[TABLE_FUNCTIONS]) {
   printf("#FUNCTION:%d\n", numFunction);
   if (output_redirected) fout=fopen(temp_function_path,"w");
   for (i=0; i<I->numComponent; i++) {
     comi=I->ComponentInfo+i;
     for (j=0; j<comi->numFunction; j++) {
       funi=comi->FunctionInfo+j;
       fprintf(fout, "%d|%d|%d|%d|%d|%d\n", I->pdbfileid,       comi->index,
         funi->index,    funi->ec_primary,  funi->ec_3rd_level, funi->ec_4th_level);
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE keywords, 4 fields */
  if(I->tables[TABLE_KEYWORDS]) {
   printf("#KEYWORD:%d\n", I->numKeyword);
   if (output_redirected) fout=fopen(temp_keyword_path,"w");
   for (i=0; i<I->numKeyword; i++) {
     keyi=I->KeywordInfo+i;
     if(keyi->ComponentInfo==NULL) j=-1;
     else j=keyi->ComponentInfo->index;
     fprintf(fout, "%d|%d|%d|%s\n", I->pdbfileid, j, keyi->index, keyi->keyword);
   }
   if (output_redirected) fclose(fout);
  }
  
  
  /* For TABLE cdhit_chains, 22 fields */
  if(I->tables[TABLE_CDHIT_CHAINS]) {
   printf("#CDHIT_CHAIN:%d\n", I->numChain);
   if (output_redirected) fout=fopen(temp_cdchain_path,"w");
   for (i=0; i<I->numChain; i++) {
     ci=I->ChainInfo+i;
     fprintf(fout, "%d|%s|%c|%d|%04d|%03d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",
       I->pdbfileid,        I->pdbid,           ci->chainid,         ci->assembly_index, ci->type2,
       ci->clusterstatus,   ci->cluster50_id,   ci->represent50_id,  ci->cluster90_id,   ci->represent90_id,
       ci->numGeneOntology, ci->numBiolProcess, ci->numMoleFunction, ci->numCellComponent,
       ci->numMolecule,     ci->numDomain,      ci->numFragment,     ci->numResidue,
       ci->numWaterRes,     ci->numLigandRes,   ci->numDnarnaRes,    ci->numProteinRes);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE symop_chains, 7 fields */
  if(I->tables[TABLE_SYMOP_CHAINS]) {
   printf("#SYMOP_CHAIN:%d\n", numSymChain);
   if (output_redirected) fout=fopen(temp_symchain_path,"w");
   numSymChain=0;
   for (i=0; i<I->numAssembly; i++) {
     assi=I->AssemblyInfo+i;
     for (j=0; j<assi->numSymChain; j++) {
       symi=assi->SymChainInfo+j;
       fprintf(fout, "%d|%d|%s|%d|%c|%c|%d\n", I->pdbfileid, numSymChain, I->pdbid,
           symi->model_number, symi->cdhit_chainid, symi->symop_chainid, symi->assembly_index);
       numSymChain++;
     }
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE molecules, 6 fields */
  if(I->tables[TABLE_MOLECULES]) {
   printf("#MOLECULE:%d\n", I->numMolecule);
   if (output_redirected) fout=fopen(temp_molecule_path,"w");
   for (i=0; i<I->numMolecule; i++) {
     mi=I->MoleculeInfo+i;
     fprintf(fout, "%d|%d|%02d|%c|%d|%d\n",
       I->pdbfileid, mi->index, mi->type, mi->chain, mi->numResidue, mi->assembly_index);
   }
   if (output_redirected) fclose(fout);
  }
   
  /* For TABLE domains, 17 fields */
  if(I->tables[TABLE_DOMAINS]) {
   printf("#DOMAIN:%d\n", I->numDomain);
   if (output_redirected) fout=fopen(temp_domain_path,"w");
   for (i=0; i<I->numDomain; i++) {
     di=I->DomainInfo+i;
     fprintf(fout, "%d|%s|%d|%c|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d\n",    I->pdbfileid,
       I->pdbid,        di->index,     di->chain,        di->residueid_begin, di->residueid_end,
       di->is_fragment, di->domainnum, di->cath_primary, di->cath_topology,   di->cath_superfamily,
       di->cath_s35, di->cath_s60, di->cath_s95, di->cath_s100, di->cath_uniqueid, di->numResidue);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE residues, 19 fields */
  if(I->tables[TABLE_RESIDUES]) {
   printf("#RESIDUE:%d\n", I->numResidue);
   if (output_redirected) fout=fopen(temp_residue_path,"w");
   for (i=0; i<I->numResidue; i++) {
     ri=I->ResidueInfo+i;
     fprintf(fout, "%d|%d|%d|%s|%c|%d|%d|", I->pdbfileid, ri->index,
             ri->type, ri->resn, ri->chain, ri->resid,    ri->numAtom);
     if(ri->containsMetal>=0) fprintf(fout,"%d",ri->containsMetal);
     fprintf(fout, "|%03d|%f|%f|%f|%f|%d|%d|%d|%d|%d|%d\n",  ri->location,       ri->center_displacement,
       ri->asa,          ri->msa,            ri->curvature,  ri->assembly_index, ri->cavity_index,
       ri->domain_index, ri->molecule_index, ri->prev_index, ri->next_index);
   }
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE atoms, 19 fields */
  if(I->tables[TABLE_ATOMS]) {
   printf("#ATOM:%d\n", I->numAtom);
   if (output_redirected) fout=fopen(temp_atom_path,"w");
   for (i=0; i<I->numAtom; i++) {
     ai=I->AtomInfo+i;
     fprintf(fout, "%d|%d|%d|%d|%s|%s|%d|%d|%c|%f|%f|%f|%03d|%f|%f|%f|%f|%d|%d\n",
         I->pdbfileid, ai->residue_index, ai->index,     ai->type,         ai->realname, ai->elem,     ai->protons,
         ai->id,       ai->alt,           ai->occup,     ai->b,            ai->q,        ai->location, ai->center_displacement,
         ai->asa,      ai->msa,           ai->curvature, ai->cavity_index, ai->ResidueInfo->molecule_index);
   }
   if (output_redirected) fclose(fout);
  }
  
  
  /* For TABLE ion_bondvalences, 25 fields */
  if(I->tables[TABLE_ION_BONDVALENCES]) {
   if (output_redirected) fout=fopen(temp_ion_bondvalence_path,"w");
   numBondValence=EntityMoleculeBondValencePrint(fout, I, 0);
   if (output_redirected) fclose(fout);
   I->numIonBondValence=numBondValence;
   printf("#ION_BONDVALENCE:%d\n", numBondValence);
  }
  
  /* For TABLE water_bondvalences, 22 fields */
  if(I->tables[TABLE_WATER_BONDVALENCES]) {
   if (output_redirected) fout=fopen(temp_water_bondvalence_path,"w");
   numBondValence=EntityMoleculeBondValencePrint(fout, I, 1);
   if (output_redirected) fclose(fout);
   printf("#WATER_BONDVALENCE:%d\n", numBondValence);
  }
   /* table ion_bondvalence, water_bondvalence was printed before atomneighbors table is printed in older version,
    * because the value I->numAtmNeighbor was modified within the atomneighbors procedure in older version */
  
  /* For TABLE neighbors, 15 fields */
  if(I->tables[TABLE_NEIGHBORS]) {
   if (output_redirected) fout=fopen(temp_neighbor_path,"w");
   numNeighbor=EntityMoleculeNeighborPrint(fout, I, 0);
   if (output_redirected) fclose(fout);
   printf("#RESIDUE_NEIGHBOR:%d\n", numNeighbor);
  }
  
  /* For TABLE atomneighbors, 15 fields */
  if(I->tables[TABLE_ATOMNEIGHBORS]) {
   if (output_redirected) fout=fopen(temp_atomneighbor_path,"w");
   numNeighbor=EntityMoleculeNeighborPrint(fout, I, 1);
   if (output_redirected) fclose(fout);
   printf("#ATOM_NEIGHBOR:%d\n", numNeighbor);
  }
  
  /* For TABLE ligand_bondangles, 22 fields */
  if(I->tables[TABLE_LIGAND_BONDANGLES]) {
   printf("#LIGAND_BONDANGLE:%d\n", I->numAngle);
   if (output_redirected) fout=fopen(temp_ligbondangle_path,"w");
   EntityMoleculeAnglePrint(fout, I);
   if (output_redirected) fclose(fout);
  }
  
  /* For TABLE ion_bindingsite_path, 62 fields */
  if(I->tables[TABLE_ION_BINDINGSITES]) {
   if (output_redirected) fout=fopen(temp_ion_bindingsite_path,"w");
   numIonBindingSite=EntityMoleculeIonBindingSitePrint(fout, I);
   if (output_redirected) fclose(fout);
   I->numIonBindingSite=numIonBindingSite;
   printf("#ION_BINDINGISTE:%d\n", numIonBindingSite);
  }

  /* For TABLE pdbfile, 21 fields */
  printf("#DISTANCE:%f\n", cutoff);
  if(I->tables[TABLE_PDBFILES]) {
   printf("#PDBFILE(%d):%s\n", I->pdbfileid, I->filename);
   if (output_redirected) fout=fopen(temp_pdbfile_path,"w");
   fprintf(fout, "%d|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%d|%f|%s|%d|%s|%s\n",
       I->pdbfileid,    I->filename,          I->pdbid,            I->numAssembly,
       I->numComponent, I->numChain,          I->numMolecule,      I->numDomain,
       I->numResidue,   I->numAtom,           I->numResNeighbor,   I->numAtmNeighbor,
       I->numAngle,     I->numIonBindingSite, I->space_group_name, I->space_group_number,
       I->resolution,   I->deposition_date,   I->exp_method,       I->header, I->title);
   if (output_redirected) fclose(fout);
  }

  /* For generating sql script to copy data into database */
  if (output_redirected) {
   fout=fopen(sql_copydata_path,"w");
   if(I->tables[TABLE_PDBFILES]) {
    fprintf(fout, "\\copy pdbfiles (pdbfileid, filename, pdbid, numofassemblies, numofcomponents, numofchains, numofmolecules, numofdomains,");
    fprintf(fout, "  numofresidues, numofatoms, numofneighbors, numofatomneighbors, numofligandangles, numofbindingsites,");
    fprintf(fout, "  space_group_name, space_group_number, resolution, deposition_date, exp_method, header, title) FROM %s WITH DELIMITER '|'\n", temp_pdbfile_path);
   }
   if(I->tables[TABLE_CCDINFO]) {
    fprintf(fout, "\\copy ccdinfo (pdbfileid, organism_id, ec_primary, ec_3rd_level, ec_4th_level, ec_complex,");
    fprintf(fout, "  cluster50_id, cluster90_id, go_process, go_function, go_component, cath_primary, cath_topology, cath_superfamily) FROM %s WITH DELIMITER '|'\n", temp_ccdinfo_path);
   }
   if(I->tables[TABLE_GENEONTOLOGIES]) {
    fprintf(fout, "\\copy geneontologies (pdbfileid, pdbid, chainid, go_type, go_id, qualifier, evidence, xref_db_name, xref_db_id,");
    fprintf(fout, "  organism_id, creation_date, created_by, ref_db_name, ref_db_id) FROM %s WITH DELIMITER '|'\n", temp_geneontology_path);
   }
   if(I->tables[TABLE_ASSEMBLIES]) {
    fprintf(fout, "\\copy assemblies (pdbfileid, assemblyid, assemblynum, assemblytype, numofcdhit_chains, numofsymop_chains, numofcavities, numofsurfrace_atoms,");
    fprintf(fout, "  total_asa, polar_asa, positive_charge_asa, negative_charge_asa, total_backbone_asa, polar_backbone_asa,");
    fprintf(fout, "  total_msa, polar_msa, positive_charge_msa, negative_charge_msa, total_backbone_msa, polar_backbone_msa) FROM %s WITH DELIMITER '|'\n", temp_assembly_path);
   }
   if(I->tables[TABLE_CAVITIES])
    fprintf(fout, "\\copy cavities (pdbfileid, cavityid, numofresidues, numofatoms, volume, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_cavity_path);
    /* UP: pdbfile,ccdinfo,geneontology,assembly,cavity; DOWN: component,chain,molecule,domain */
   if(I->tables[TABLE_COMPONENTS]) {
    fprintf(fout, "\\copy components (pdbfileid, componentid, componentnum, component_name, numofchains, numofkeywords, numoffunctions,");
    fprintf(fout, "  engineered, mutation, organism_id, organism_name) FROM %s WITH DELIMITER '|'\n", temp_component_path);
   }
   if(I->tables[TABLE_FUNCTIONS])
    fprintf(fout, "\\copy functions (pdbfileid, componentid, functionid, ec_primary, ec_3rd_level, ec_4th_level) FROM %s WITH DELIMITER '|'\n", temp_function_path);
   if(I->tables[TABLE_KEYWORDS])
    fprintf(fout, "\\copy keywords (pdbfileid, componentid, keywordid, keyword) FROM %s WITH DELIMITER '|'\n", temp_keyword_path);
   if(I->tables[TABLE_CDHIT_CHAINS]) {
    fprintf(fout, "\\copy cdhit_chains (pdbfileid, pdbid, chainid, assemblyid, chaintype,");
    fprintf(fout, "  clusterstatus, cluster50_id, represent50_id, cluster90_id, represent90_id,");
    fprintf(fout, "  num_go_all, num_go_process, num_go_function, num_go_component,");
    fprintf(fout, "  numofmolecules, numofdomains, numoffragments, numofresidues,");
    fprintf(fout, "  numres_water, numres_ligand, numres_dnarna, numres_protein) FROM %s WITH DELIMITER '|'\n", temp_cdchain_path);
   }
   if(I->tables[TABLE_SYMOP_CHAINS])
    fprintf(fout, "\\copy symop_chains (pdbfileid, chainid, pdbid, model_number, cdhit_chainid, symop_chainid, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_symchain_path);
   if(I->tables[TABLE_MOLECULES])
    fprintf(fout, "\\copy molecules (pdbfileid, moleculeid, moleculetype, chainid, numofresidues, assemblyid) FROM %s WITH DELIMITER '|'\n", temp_molecule_path);
   if(I->tables[TABLE_DOMAINS]) {
    fprintf(fout, "\\copy domains (pdbfileid, pdbid, domainid, chainid, residueid_begin, residueid_end, is_fragment, domainnum,");
    fprintf(fout, "  cath_primary, cath_topology, cath_superfamily, cath_s35, cath_s60, cath_s95, cath_s100,");
    fprintf(fout, "  cath_uniqueid, numofresidues) FROM %s WITH DELIMITER '|'\n", temp_domain_path);
   }
    /* UP: component,chain,molecule,domain; DOWN: residue,atom */
   if(I->tables[TABLE_RESIDUES]) {
    fprintf(fout, "\\copy residues (pdbfileid, residueid, residuetype, resname, chainid, resseq, numofatoms, contains_metal,");
    fprintf(fout, "  location, center_displacement, accessible_surface, molecular_surface, curvature,");
    fprintf(fout, "  assemblyid, cavityid, moleculeid, domainid, prev_residueid, next_residueid) FROM %s WITH DELIMITER '|'\n", temp_residue_path);
   }
   if(I->tables[TABLE_ATOMS]) {
    fprintf(fout, "\\copy atoms (pdbfileid, residueid, atomid, atomtype, atomname, atomelem, protons, atomseq, alt,");
    fprintf(fout, "  occup, bfactor, charge, location, center_displacement, accessible_surface, molecular_surface,");
    fprintf(fout, "  curvature, cavityid, moleculeid) FROM %s WITH DELIMITER '|'\n", temp_atom_path);
   }
    /* UP: residue,atom; DOWN: neighbor,atomneighbor,ligbondangle */
   if(I->tables[TABLE_NEIGHBORS]) {
    fprintf(fout, "\\copy neighbors (pdbfileid, neighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  contact_flag, icell, isym, distance, vec_x, vec_y, vec_z, bfactor_correlation) FROM %s WITH DELIMITER '|'\n", temp_neighbor_path);
   }
   if(I->tables[TABLE_ATOMNEIGHBORS]) {
    fprintf(fout, "\\copy atomneighbors (pdbfileid, atomneighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,");
    fprintf(fout, "  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,");
    fprintf(fout, "  contact_flag, icell, isym, distance, vec_x, vec_y, vec_z, bfactor_correlation) FROM %s WITH DELIMITER '|'\n", temp_atomneighbor_path);
   }
   if(I->tables[TABLE_LIGAND_BONDANGLES]) {
    fprintf(fout, "\\copy ligand_bondangles (pdbfileid, bondangleid,");
    fprintf(fout, "  residueid_a, residueid_lig, residueid_b, resname_a, resname_lig, resname_b, resangletype,");
    fprintf(fout, "  atomid_a, atomid_lig, atomid_b, atomname_a, atomname_lig, atomname_b, atomangletype,");
    fprintf(fout, "  atomneighborid_a, atomneighborid_b, dist_a, dist_b, dist_lig, angle) FROM %s WITH DELIMITER '|'\n", temp_ligbondangle_path);
   }
    /* UP: neighbor,atomneighbor,ligbondangle; DOWN: ion_bondvalence, water_bondvalence, ion_bindingsite */
   if(I->tables[TABLE_ION_BONDVALENCES]) {
    fprintf(fout, "\\copy ion_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid,");
    fprintf(fout, "  residueid_lig, residueid_ion, resname_lig, resname_ion, neighbortype,");
    fprintf(fout, "  atomid_lig, atomid_ion, atomname_lig, atomname_ion, atomneighbortype, protons_lig, protons_ion, coord_number_lig,");
    fprintf(fout, "  contact_flag, distance, vec_x, vec_y, vec_z, bfactor_correlation,");
    fprintf(fout, "  bondvalence, calcium_bondvalence) FROM %s WITH DELIMITER '|'\n", temp_ion_bondvalence_path);
   }
   if(I->tables[TABLE_WATER_BONDVALENCES]) {
    fprintf(fout, "\\copy water_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid,");
    fprintf(fout, "  residueid_lig, residueid_water, resname_lig, neighbortype,");
    fprintf(fout, "  atomid_lig, atomid_water, atomname_lig, atomneighbortype, protons_lig, coord_number_lig,");
    fprintf(fout, "  contact_flag, distance, vec_x, vec_y, vec_z, bfactor_correlation,");
    fprintf(fout, "  sodium_bondvalence, calcium_bondvalence) FROM %s WITH DELIMITER '|'\n", temp_water_bondvalence_path);
   }
   if(I->tables[TABLE_ION_BINDINGSITES]) {
    fprintf(fout, "\\copy ion_bindingsites (pdbfileid, bindingsiteid, residueid_ion, resname_ion, atomid_ion,"); 
    fprintf(fout, "  atomname_ion, protons_ion, bfactor_ion, bfactor_env_avg, occupancy_ion, occupancy_env_avg,");       /* 11 */
    fprintf(fout, "  coord_number_3a, coord_number_3a_ons, geometry_type, geometry_bidentate, geometry_pseudo, geometry_distort, rmsd_geom_angle,");
    fprintf(fout, "  num_oxygen, num_nitrogen, num_sulfur, num_phosphorus, num_carbon, num_others,");                    /* 13 */
    fprintf(fout, "  num04_oxygen_mc, num08_oxygen_amide, num10_oxygen_carboxyl, num17_oxygen_hydroxyl,");
    fprintf(fout, "  num18_oxygen_phenol, num26_oxygen_dnarna, num28_oxygen_water, num31_oxygen_others,");
    fprintf(fout, "  num01_nitrogen_mc, num07_nitrogen_arginine, num09_nitrogen_amide, num13_nitrogen_histidine,");
    fprintf(fout, "  num14_nitrogen_lysine, num15_nitrogen_tryptophan, num25_nitrogen_dnarna, num30_nitrogen_others,");  /* 16 */
    fprintf(fout, "  num11_sulfur_cysteine, num16_sulfur_methionine, num33_sulfur_others, num19_selenium, num41_others,");
    fprintf(fout, "  num_bidentate_all, num_bidentate_oo, num_bidentate_on, num_bidentate_nn, distance_avg, distance_min, distance_max,");       /* 12 */
    fprintf(fout, "  valence_3a, vecsum_3a, calcium_valence_3a, calcium_vecsum_3a, coord_number_4a, num_metal_4a,");
    fprintf(fout, "  valence_4a, vecsum_4a, calcium_valence_4a, calcium_vecsum_4a) FROM %s WITH DELIMITER '|'\n", temp_ion_bindingsite_path);      /* 10 */
   }
   fclose(fout);
  }
}

/*---------------------------------------------------------------------------*/
int main(int argc, char** argv) {
  FILE *f, *fcluster, *fcontact, *fbuheader;
  ObjEntityMolecule *I;
  char* envhome=NULL;
  char* buffer=NULL;
  char* buffer_cluster=NULL;
  char* buffer_contact=NULL;
  char* buffer_buheader=NULL;
  float cutoff = 4.0;
  EntityFileName temp_dir, file_path, file_cluster, file_contact, file_buheader;
  EntityFileName data_dir, lib_dir,   file_aadict;
  ResidueDict aminoacid_dictionary[2048];       // Assume maximal 2K non-standard amino acid records
  int i;
//fprintf(stderr, "argc is %i, ", argc);
//for(i=0;i<argc;i++){ fprintf(stderr, "argv[%i] is %s, ", i, argv[i]); }
  envhome=getenv("NEIGHBORHOOD");
  if (envhome == NULL) {
    PFatalError("Please set your environmental variable NEIGHBORHOOD to corresponding path before you can continue...\n");
  } else {
    strcpy(lib_dir, envhome);
    if(lib_dir[strlen(lib_dir)-1] != '/') strcat(lib_dir, "/");
    strcat(lib_dir, "lib/");
  }

/* code to test individual procedures
  AtomInfoPrintElement(element_dictionary);
  AtomInfoPrintBondValence(bondvalence_dictionary);
  ccp4spg_load_by_standard_num(146);
  ccp4spg_load_by_spgname("I 2 3");
  exit(0);
  */

  if (argc < 6) { PFatalError("usage: neighborhood TEMPDIR PDBFILE CLUSTERFILE CONTACTFILE Biological_Unit_HEADER_FILE [data_dir [distance [options]]]\n"); }
  if (argc >= 7) {
   strcpy(data_dir, argv[6]);
   if(data_dir[strlen(data_dir)-1] != '/') strcat(data_dir, "/");
   if (argc >= 8) {
    if(sscanf(argv[7],"%f",&cutoff)!=1) { PFatalError("invalid distance, distance should be numeric.\n"); };
    if (cutoff > 4.1) { PFatalError("invalid distance, distance too large for calculation.\n"); };
    if (cutoff < 0.1) { PFatalError("invalid distance, distance too small for calculation.\n"); };
   }
  } else {
    strcpy(data_dir, "/med/zenobi_data/MYPDB_NEW/");
//  strcpy(data_dir, "/data/MYPDB_ZENOBI/");
  }
  strcpy(file_aadict, lib_dir);
  strcat(file_aadict, "aminoacid_dictionary.data");
  ReadAminoAcidDictionary(aminoacid_dictionary, file_aadict);

  strcpy(temp_dir, argv[1]);
  if(temp_dir[strlen(temp_dir)-1] != '/') strcat(temp_dir, "/");

  strcpy(file_path, temp_dir);
  strcat(file_path, argv[2]);
  f=fopen(file_path,"rb");
  if (!f) { PFatalError("invalid PDBFILE name\n"); };
  buffer=str2cachetextfile(f);

  strcpy(file_cluster, temp_dir);
  strcat(file_cluster, argv[3]);
  fcluster=fopen(file_cluster,"rb");
  if (!fcluster) { PFatalError("invalid CLUSTER FILE name\n"); };
  buffer_cluster=str2cachetextfile(fcluster);

  if (!strncmp(argv[4],"NULL",4)) {
    AllocP(buffer_contact,char,255);
    buffer_contact[0]=0;
  } else {
    strcpy(file_contact, temp_dir);
    strcat(file_contact, argv[4]);
    fcontact=fopen(file_contact,"rb");
    if (!fcontact) { PFatalError("invalid CONTACT FILE name\n"); };
    buffer_contact=str2cachetextfile(fcontact);
  }

  if (!strncmp(argv[5],"NULL",4)) {
    AllocP(buffer_buheader,char,255);
    buffer_buheader[0]=0;
  } else {
    strcpy(file_buheader, temp_dir);
    strcat(file_buheader, argv[5]);
    fbuheader=fopen(file_buheader,"rb");
    if (!fbuheader) { PFatalError("invalid Biological Unit HEADER FILE name\n"); };
    buffer_buheader=str2cachetextfile(fbuheader);
  }

  I = (ObjEntityMolecule *)EntityMoleculeNew();    // create molecule object
  strcpy(I->filename, argv[2]);
  str2extractpdbid(I->pdbid, file_path);


  EntityMoleculeReadPDBStr(I, buffer, aminoacid_dictionary);            // create chain, molecule, residue, atom objects
  fprintf(stderr,"%s: PDB string read successfully.\n", I->pdbid);
  EntityMoleculeReadClusterStr(I, buffer_cluster);                      // assign pdbfileid, chain/symchain cluster info
  fprintf(stderr,"%s: Cluster string read successfully.\n", I->pdbid);
  PDBheaderFinishTouch(I);
  EntityMoleculeReadAssemblyStr(I, buffer_buheader, data_dir);          // create assembly, symchain, cavity objects
  fprintf(stderr,"%s: Assembly string read successfully.\n", I->pdbid);
//EntityMoleculeReport(I, cutoff, temp_dir);
  EntityMoleculeNeighbor(I, cutoff, buffer_contact);                    // create neighbor, atomneighbor objects
  fprintf(stderr,"%s: contact string read successfully.\n", I->pdbid);  // add additional neighbors which are inter-molecule contacts
  EntityMoleculeLigandAngle(I, cutoff);                                 // create angle objects
  fprintf(stderr,"%s: Ligand angle calculation successfully.\n", I->pdbid);  // calculate neighbor angles for ligand
  EntityMoleculeReport(I, cutoff, temp_dir);
  fprintf(stderr,"%s: Neighbor calculation successfully.\n", I->pdbid);


  EntityMoleculeFree(I);
  FreeP(buffer);
  FreeP(buffer_cluster);
  FreeP(buffer_contact);
  FreeP(buffer_buheader);
  return 0;
}
