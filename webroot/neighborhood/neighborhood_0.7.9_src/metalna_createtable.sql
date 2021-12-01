drop table metalnas;
create table metalnas as (
  select pdbid, chainid, resseq, a.pdbfileid as idp, a.bindingsiteid as idb, a.residueid_ion as idr, a.atomid_ion as ida, isp, isr, isb, isw, iso, osp, osr, osb,
         coordnum_inner as cn, quality_valence as pv, quality_complete as ps, quality_experiment as pe, which_mbrp2/100 as bo,(which_mbrp2%100)/10 as ro, quality_valence as angle,
         resseq as bench, resseq as class, resseq as num_p, resseq as num_bnr, '123456789abcdef' as site_type, a.atomid_ion as sid, atomid_cluster, size_cluster, homosize_cluster,
         which_metal, which_geotype, which_ligtype, which_xhcxx, which_ooo, which_wooo2, which_ppp, which_bnr, which_wbnr2, which_mbrp2, which_isoform, which_mobile
  from ion_bindingsite_profiles a
  left join ion_bindingsites b
  on a.pdbfileid=b.pdbfileid and a.bindingsiteid=b.bindingsiteid
  left join pdbfiles c
  on a.pdbfileid=c.pdbfileid
  left join residues d
  on a.pdbfileid=d.pdbfileid and a.residueid_ion=d.residueid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq||'('||trim(both '-' from atomname_a)||')') as isp from ion_bindingsite_ligresidues where ligresiduetype=1 and atomtype=35 group by pdbfileid,bindingsiteid) lig_isp
  on a.pdbfileid=lig_isp.pdbfileid and a.bindingsiteid=lig_isp.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq||'('||trim(both '-' from atomname_a)||')') as isr from ion_bindingsite_ligresidues where ligresiduetype=1 and atomtype>=32 and atomtype<=34 group by pdbfileid,bindingsiteid) lig_isr
  on a.pdbfileid=lig_isr.pdbfileid and a.bindingsiteid=lig_isr.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq||'('||trim(both '-' from atomname_a)||')') as isb from ion_bindingsite_ligresidues where ligresiduetype=1 and atomtype>=27 and atomtype<=31 group by pdbfileid,bindingsiteid) lig_isb
  on a.pdbfileid=lig_isb.pdbfileid and a.bindingsiteid=lig_isb.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(chainid||resseq) as isw from ion_bindingsite_ligresidues where ligresiduetype=1 and atomtype=41 group by pdbfileid,bindingsiteid) lig_isw
  on a.pdbfileid=lig_isw.pdbfileid and a.bindingsiteid=lig_isw.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq||'('||trim(both '-' from atomname_a)||')') as iso from ion_bindingsite_ligresidues where ligresiduetype=1 and atomtype!=41 and (atomtype<27 or atomtype>35) group by pdbfileid,bindingsiteid) lig_iso
  on a.pdbfileid=lig_iso.pdbfileid and a.bindingsiteid=lig_iso.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq) as osp from ion_bindingsite_ligmoieties where ligmoietytype=2 and moietytype=6 group by pdbfileid,bindingsiteid) lig_osp
  on a.pdbfileid=lig_osp.pdbfileid and a.bindingsiteid=lig_osp.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq) as osr from ion_bindingsite_ligmoieties where ligmoietytype=2 and moietytype=7 group by pdbfileid,bindingsiteid) lig_osr
  on a.pdbfileid=lig_osr.pdbfileid and a.bindingsiteid=lig_osr.bindingsiteid
  left join (select pdbfileid,bindingsiteid,conc_comma(trim(both '_' from resname)||':'||chainid||resseq) as osb from ion_bindingsite_ligmoieties where ligmoietytype=2 and moietytype=8 group by pdbfileid,bindingsiteid) lig_osb
  on a.pdbfileid=lig_osb.pdbfileid and a.bindingsiteid=lig_osb.bindingsiteid
  where which_metal=12
);

alter table metalnas alter column site_type type char(15);
update metalnas set class = 0;
update metalnas set num_p = NULL;
update metalnas set num_bnr = NULL;
update metalnas set site_type = NULL;
update metalnas set sid   = 99999;
update metalnas set bench = 0;
update metalnas set bench = 1 where cn>=4 and cn<=6 and pv>=0.50 and ps>=0.60 and pe>=0.50;
update metalnas set bench = 0 where which_bnr = 0 and which_ppp = 0 and which_mbrp2 = 0;
update metalnas set bench = 0 where (idp, idb) in (select pdbfileid, bindingsiteid from ion_bindingsite_ligatoms where atomtype in (27,29,30));

update metalnas set class = 1, sid = 19999, num_p = which_ppp/100, num_bnr = which_bnr/100+(which_bnr%100)/10+which_bnr%10 where which_geotype = '01' and which_ligtype <= 99 and which_ligtype % 10 = 0 and (which_ppp/10 != 0 or which_bnr != 0);
update metalnas set class = 2, sid = 29999, num_p = which_mbrp2%10, num_bnr = (which_mbrp2%100)/10+which_mbrp2/100 where which_geotype = '01' and which_ligtype <= 99 and which_ligtype % 10 = 0 and (which_ppp/10 = 0 and which_bnr = 0) and (which_mbrp2 != 0);
update metalnas set class = 3, sid = 30000 where which_geotype = '01' and (which_ligtype >= 100 or which_ligtype % 10 != 0) and (which_bnr != 0 or which_ppp != 0 or which_mbrp2 != 0);
update metalnas set class = 4, sid = 40000 where which_geotype = '11' and (which_bnr != 0 or which_ppp != 0 or which_mbrp2 != 0);

create temporary view RNA_inner as (select *,which_ppp/100 as opi,which_bnr/100 as obi,(which_bnr%100)/10 as nbi,which_bnr%10 as ori,which_bnr/100+(which_bnr%100)/10+which_bnr%10 as which_bnrsum from ion_bindingsite_profiles where which_geotype = '01' and which_ligtype <= 99 and which_ligtype % 10 = 0 and (which_ppp/10 != 0 or which_bnr != 0));
create temporary view p2 as (select * from
  (select * from RNA_inner where which_ppp/100=2) a left join
  (select pdbfileid as p1,bindingsiteid as b1,max(atomid) as aa from ion_bindingsite_ligatoms where atomtype=35 group by pdbfileid,bindingsiteid) b on a.pdbfileid=b.p1 and a.bindingsiteid=b.b1 left join
  (select pdbfileid as p2,bindingsiteid as b2,min(atomid) as ab from ion_bindingsite_ligatoms where atomtype=35 group by pdbfileid,bindingsiteid) c on a.pdbfileid=c.p2 and a.bindingsiteid=c.b2 left join
  (select pdbfileid as p3,bindingsiteid as b3,atomid_a,atomid_b,angle from ion_bindingsite_ligatomneighbors) d on a.pdbfileid=d.p3 and a.bindingsiteid=d.b3 and ((b.aa=d.atomid_a and c.ab=atomid_b) or (b.aa=d.atomid_b and c.ab=atomid_a))
); 
update metalnas set angle = 0;
update metalnas set angle=p2.angle from p2 where metalnas.idp=p2.pdbfileid and metalnas.idb=p2.bindingsiteid;

update metalnas set sid = 10110, site_type = 'OR'              where class=1 and num_p=0 and num_bnr=1 and which_bnr=1;
update metalnas set sid = 10120, site_type = 'OB'              where class=1 and num_p=0 and num_bnr=1 and which_bnr=100;
update metalnas set sid = 10130, site_type = 'NB'              where class=1 and num_p=0 and num_bnr=1 and which_bnr=10;
update metalnas set sid = 10210, site_type = '2OR'             where class=1 and num_p=0 and num_bnr=2 and which_bnr=2;
update metalnas set sid = 10240, site_type = 'OR-OB'           where class=1 and num_p=0 and num_bnr=2 and which_bnr=101;
update metalnas set sid = 10250, site_type = '2OB'             where class=1 and num_p=0 and num_bnr=2 and which_bnr=200;
update metalnas set sid = 10270, site_type = 'OB-NB'           where class=1 and num_p=0 and num_bnr=2 and which_bnr=110;
update metalnas set sid = 10290, site_type = '2NB'             where class=1 and num_p=0 and num_bnr=2 and which_bnr=20;
update metalnas set sid = 10360, site_type = '2OB-NB'          where class=1 and num_p=0 and num_bnr=3 and which_bnr=210;
update metalnas set sid = 10380, site_type = 'OB-2NB'          where class=1 and num_p=0 and num_bnr=3 and which_bnr=120;
update metalnas set sid = 10395, site_type = '2OR-NB'          where class=1 and num_p=0 and num_bnr=3 and which_bnr=12;
update metalnas set sid = 10440, site_type = '2OR-2OB'         where class=1 and num_p=0 and num_bnr=4 and which_bnr=202;
update metalnas set sid = 11000, site_type = 'OP'              where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=0;
update metalnas set sid = 11001, site_type = 'OP-PO'           where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=1;
update metalnas set sid = 11002, site_type = 'OP-2PO'          where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=2;
update metalnas set sid = 11003, site_type = 'OP-3PO'          where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=3;
update metalnas set sid = 11004, site_type = 'OP-4PO'          where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=4;
update metalnas set sid = 11005, site_type = 'OP-5PO'          where class=1 and num_p=1 and num_bnr=0 and which_mbrp2%10=5;
update metalnas set sid = 11110, site_type = 'OP-OR'           where class=1 and num_p=1 and num_bnr=1 and which_bnr=1;
update metalnas set sid = 11120, site_type = 'OP-OB'           where class=1 and num_p=1 and num_bnr=1 and which_bnr=100;
update metalnas set sid = 11130, site_type = 'OP-NB'           where class=1 and num_p=1 and num_bnr=1 and which_bnr=10;
update metalnas set sid = 11210, site_type = 'OP-2OR'          where class=1 and num_p=1 and num_bnr=2 and which_bnr=2;
update metalnas set sid = 11250, site_type = 'OP-2OB'          where class=1 and num_p=1 and num_bnr=2 and which_bnr=200;
update metalnas set sid = 11270, site_type = 'OP-OB-NB'        where class=1 and num_p=1 and num_bnr=2 and which_bnr=110;
update metalnas set sid = 11345, site_type = 'OP-OR-2OB'       where class=1 and num_p=1 and num_bnr=3 and which_bnr=201;
update metalnas set sid = 11395, site_type = 'OP-2OR-NB'       where class=1 and num_p=1 and num_bnr=3 and which_bnr=12;

update metalnas set sid = 12006, site_type = 'cis-2OP'         where class=1 and num_p=2 and num_bnr=0 and angle<135;
update metalnas set sid = 12007, site_type = 'trans-2OP'       where class=1 and num_p=2 and num_bnr=0 and angle>=135;

-- create temporary table "cis-2OP-OR"      as (select * from p2rbn1 where angle<135 and which_bnr=1);
-- create temporary table "cis-2OP-OB"      as (select * from p2rbn1 where angle<135 and which_bnr=100);
-- create temporary table "cis-2OP-NB"      as (select * from p2rbn1 where angle<135 and which_bnr=10);
-- create temporary table "cis-2OP-2OR"     as (select * from p2rbn2 where angle<135 and which_bnr=2);
-- create temporary table "cis-2OP-OR-OB"   as (select * from p2rbn2 where angle<135 and which_bnr=101);
-- create temporary table "cis-2OP-2OB"     as (select * from p2rbn2 where angle<135 and which_bnr=200);
-- create temporary table "trans-2OP-2OB"   as (select * from p2rbn2 where angle>=135 and which_bnr=200);

update metalnas set sid = 12116, site_type = 'cis-2OP-OR'      where class=1 and num_p=2 and num_bnr=1 and which_isoform/100!=11 and which_bnr=1;
update metalnas set sid = 12117, site_type = 'trans-2OP-OR'    where class=1 and num_p=2 and num_bnr=1 and which_isoform/100 =11 and which_bnr=1;
update metalnas set sid = 12126, site_type = 'cis-2OP-OB'      where class=1 and num_p=2 and num_bnr=1 and which_isoform/100!=11 and which_bnr=100;
update metalnas set sid = 12127, site_type = 'trans-2OP-OB'    where class=1 and num_p=2 and num_bnr=1 and which_isoform/100 =11 and which_bnr=100;
update metalnas set sid = 12136, site_type = 'cis-2OP-NB'      where class=1 and num_p=2 and num_bnr=1 and which_isoform/100!=11 and which_bnr=10;
update metalnas set sid = 12246, site_type = 'cis-2OP-2OR'     where class=1 and num_p=2 and num_bnr=2 and which_isoform/100!=11 and which_bnr=2;
update metalnas set sid = 12256, site_type = 'cis-2OP-OR-OB'   where class=1 and num_p=2 and num_bnr=2 and which_isoform/100!=11 and which_bnr=101;
update metalnas set sid = 12276, site_type = 'cis-2OP-2OB'     where class=1 and num_p=2 and num_bnr=2 and which_isoform/100!=11 and which_bnr=200;
update metalnas set sid = 12277, site_type = 'trans-2OP-2OB'   where class=1 and num_p=2 and num_bnr=2 and which_isoform/100 =11 and which_bnr=200;
update metalnas set sid = 13008, site_type = 'fac-3OP'         where class=1 and num_p=3 and num_bnr=0 and which_isoform/100!=11;
update metalnas set sid = 13009, site_type = 'mer-3OP'         where class=1 and num_p=3 and num_bnr=0 and which_isoform/100 =11;
update metalnas set sid = 13118, site_type = 'fac-3OP-OR'      where class=1 and num_p=3 and num_bnr=1 and which_isoform/100!=11 and which_bnr=1;
update metalnas set sid = 13119, site_type = 'mer-3OP-OR'      where class=1 and num_p=3 and num_bnr=1 and which_isoform/100 =11 and which_bnr=1;
update metalnas set sid = 13128, site_type = 'fac-3OP-OB'      where class=1 and num_p=3 and num_bnr=1 and which_isoform/100!=11 and which_bnr=100;
update metalnas set sid = 13129, site_type = 'mer-3OP-OB'      where class=1 and num_p=3 and num_bnr=1 and which_isoform/100 =11 and which_bnr=100;
update metalnas set sid = 14006, site_type = 'trans,cis-4OP'   where class=1 and num_p=4 and num_bnr in (0,1) and which_isoform!=1111;
update metalnas set sid = 14007, site_type = 'trans,trans-4OP' where class=1 and num_p=4 and num_bnr in (0,1) and which_isoform=1111;
-- update metalnas set sid = 14110, site_type = '4OP-OR'          where class=1 and num_p=4 and num_bnr=1 and which_bnr=1;





update metalnas set sid = 20101, site_type = 'RO'          where (class=2 and num_p=0 and num_bnr=1 and          ro=1);
update metalnas set sid = 20110, site_type = 'BO'          where (class=2 and num_p=0 and num_bnr=1 and bo=1);
update metalnas set sid = 20202, site_type = '2RO'         where (class=2 and num_p=0 and num_bnr=2 and          ro=2);
update metalnas set sid = 20211, site_type = 'RO-BO'       where (class=2 and num_p=0 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 20220, site_type = '2BO'         where (class=2 and num_p=0 and num_bnr=2 and bo=2);
update metalnas set sid = 20312, site_type = '2RO-BO'      where (class=2 and num_p=0 and num_bnr=3 and bo=1 and ro=2);
update metalnas set sid = 20321, site_type = 'RO-2BO'      where (class=2 and num_p=0 and num_bnr=3 and bo=2 and ro=1);
update metalnas set sid = 20330, site_type = '3BO'         where (class=2 and num_p=0 and num_bnr=3 and bo=3);
update metalnas set sid = 20422, site_type = '2RO-2BO'     where (class=2 and num_p=0 and num_bnr=4 and bo=2 and ro=2);
update metalnas set sid = 20431, site_type = 'RO-3BO'      where (class=2 and num_p=0 and num_bnr=4 and bo=3 and ro=1);
update metalnas set sid = 20440, site_type = '4BO'         where (class=2 and num_p=0 and num_bnr=4 and bo=4);
update metalnas set sid = 20532, site_type = '2RO-3BO'     where (class=2 and num_p=0 and num_bnr=5 and bo=3 and ro=2);
update metalnas set sid = 20541, site_type = 'RO-4BO'      where (class=2 and num_p=0 and num_bnr=5 and bo=4 and ro=1);
update metalnas set sid = 20550, site_type = '5BO'         where (class=2 and num_p=0 and num_bnr=5 and bo=5);
update metalnas set sid = 20624, site_type = '4RO-2BO'     where (class=2 and num_p=0 and num_bnr=6 and bo=2 and ro=4);
update metalnas set sid = 20642, site_type = '4BO-2RO'     where (class=2 and num_p=0 and num_bnr=6 and bo=4 and ro=2);
update metalnas set sid = 20651, site_type = 'RO-5BO'      where (class=2 and num_p=0 and num_bnr=6 and bo=5 and ro=1);
update metalnas set sid = 20660, site_type = '6BO'         where (class=2 and num_p=0 and num_bnr=6 and bo=6);
update metalnas set sid = 20743, site_type = '3RO-4BO'     where (class=2 and num_p=0 and num_bnr=7 and bo=4 and ro=3);
update metalnas set sid = 20752, site_type = '2RO-5BO'     where (class=2 and num_p=0 and num_bnr=7 and bo=5 and ro=2);
update metalnas set sid = 20761, site_type = 'RO-6BO'      where (class=2 and num_p=0 and num_bnr=7 and bo=6 and ro=1);
update metalnas set sid = 20770, site_type = '7BO'         where (class=2 and num_p=0 and num_bnr=7 and bo=7);
update metalnas set sid = 20844, site_type = '4RO-4BO'     where (class=2 and num_p=0 and num_bnr=8 and bo=4 and ro=4);
update metalnas set sid = 20871, site_type = 'RO-7BO'      where (class=2 and num_p=0 and num_bnr=8 and bo=7 and ro=1);
update metalnas set sid = 21000, site_type = 'PO'          where (class=2 and num_p=1 and num_bnr=0);
update metalnas set sid = 21101, site_type = 'PO-RO'       where (class=2 and num_p=1 and num_bnr=1 and          ro=1);
update metalnas set sid = 21110, site_type = 'PO-BO'       where (class=2 and num_p=1 and num_bnr=1 and bo=1);
update metalnas set sid = 21202, site_type = 'PO-2RO'      where (class=2 and num_p=1 and num_bnr=2 and          ro=2);
update metalnas set sid = 21211, site_type = 'PO-RO-BO'    where (class=2 and num_p=1 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 21220, site_type = 'PO-2BO'      where (class=2 and num_p=1 and num_bnr=2 and bo=2);
update metalnas set sid = 21312, site_type = 'PO-2RO-BO'   where (class=2 and num_p=1 and num_bnr=3 and bo=1 and ro=2);
update metalnas set sid = 21321, site_type = 'PO-RO-2BO'   where (class=2 and num_p=1 and num_bnr=3 and bo=2 and ro=1);
update metalnas set sid = 21330, site_type = 'PO-3BO'      where (class=2 and num_p=1 and num_bnr=3 and bo=3);
update metalnas set sid = 21413, site_type = 'PO-3RO-BO'   where (class=2 and num_p=1 and num_bnr=4 and bo=1 and ro=3);
update metalnas set sid = 21422, site_type = 'PO-2RO-2BO'  where (class=2 and num_p=1 and num_bnr=4 and bo=2 and ro=2);
update metalnas set sid = 21431, site_type = 'PO-RO-3BO'   where (class=2 and num_p=1 and num_bnr=4 and bo=3 and ro=1);
update metalnas set sid = 21440, site_type = 'PO-4BO'      where (class=2 and num_p=1 and num_bnr=4 and bo=4);
update metalnas set sid = 21514, site_type = 'PO-4RO-BO'   where (class=2 and num_p=1 and num_bnr=5 and bo=1 and ro=4);
update metalnas set sid = 21523, site_type = 'PO-3RO-2BO'  where (class=2 and num_p=1 and num_bnr=5 and bo=2 and ro=3);
update metalnas set sid = 21532, site_type = 'PO-2RO-3BO'  where (class=2 and num_p=1 and num_bnr=5 and bo=3 and ro=2);
update metalnas set sid = 21541, site_type = 'PO-RO-4BO'   where (class=2 and num_p=1 and num_bnr=5 and bo=4 and ro=1);
update metalnas set sid = 21550, site_type = 'PO-5BO'      where (class=2 and num_p=1 and num_bnr=5 and bo=5);
update metalnas set sid = 21660, site_type = 'PO-6BO'      where (class=2 and num_p=1 and num_bnr=6 and bo=6 and ro=0);
update metalnas set sid = 22000, site_type = '2PO'         where (class=2 and num_p=2 and num_bnr=0);          
update metalnas set sid = 22101, site_type = '2PO-RO'      where (class=2 and num_p=2 and num_bnr=1 and          ro=1);
update metalnas set sid = 22110, site_type = '2PO-BO'      where (class=2 and num_p=2 and num_bnr=1 and bo=1);
update metalnas set sid = 22202, site_type = '2PO-2RO'     where (class=2 and num_p=2 and num_bnr=2 and          ro=2);
update metalnas set sid = 22211, site_type = '2PO-RO-BO'   where (class=2 and num_p=2 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 22220, site_type = '2PO-2BO'     where (class=2 and num_p=2 and num_bnr=2 and bo=2);
update metalnas set sid = 22312, site_type = '2PO-2RO-BO'  where (class=2 and num_p=2 and num_bnr=3 and bo=1 and ro=2);
update metalnas set sid = 22321, site_type = '2PO-RO-2BO'  where (class=2 and num_p=2 and num_bnr=3 and bo=2 and ro=1);
update metalnas set sid = 22330, site_type = '2PO-3BO'     where (class=2 and num_p=2 and num_bnr=3 and bo=3);
update metalnas set sid = 22422, site_type = '2PO-2RO-2BO' where (class=2 and num_p=2 and num_bnr=4 and bo=2 and ro=2);
update metalnas set sid = 22431, site_type = '2PO-RO-3BO'  where (class=2 and num_p=2 and num_bnr=4 and bo=3 and ro=1);
update metalnas set sid = 22440, site_type = '2PO-4BO'     where (class=2 and num_p=2 and num_bnr=4 and bo=4);
update metalnas set sid = 22523, site_type = '2PO-3RO-2BO' where (class=2 and num_p=2 and num_bnr=5 and bo=2 and ro=3);
update metalnas set sid = 22532, site_type = '2PO-2RO-3BO' where (class=2 and num_p=2 and num_bnr=5 and bo=3 and ro=2);
update metalnas set sid = 22541, site_type = '2PO-RO-4BO'  where (class=2 and num_p=2 and num_bnr=5 and bo=4 and ro=1);
update metalnas set sid = 22550, site_type = '2PO-5BO'     where (class=2 and num_p=2 and num_bnr=5 and bo=5);
update metalnas set sid = 22651, site_type = '2PO-RO-5BO'  where (class=2 and num_p=2 and num_bnr=6 and bo=5 and ro=1);
update metalnas set sid = 22660, site_type = '2PO-6BO'     where (class=2 and num_p=2 and num_bnr=6 and bo=6);
update metalnas set sid = 23000, site_type = '3PO'         where (class=2 and num_p=3 and num_bnr=0);          
update metalnas set sid = 23101, site_type = '3PO-RO'      where (class=2 and num_p=3 and num_bnr=1 and          ro=1);
update metalnas set sid = 23110, site_type = '3PO-BO'      where (class=2 and num_p=3 and num_bnr=1 and bo=1);
update metalnas set sid = 23202, site_type = '3PO-2RO'     where (class=2 and num_p=3 and num_bnr=2 and          ro=2);
update metalnas set sid = 23211, site_type = '3PO-RO-BO'   where (class=2 and num_p=3 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 23220, site_type = '3PO-2BO'     where (class=2 and num_p=3 and num_bnr=2 and bo=2);
update metalnas set sid = 23303, site_type = '3PO-3RO'     where (class=2 and num_p=3 and num_bnr=3 and          ro=3);
update metalnas set sid = 23312, site_type = '3PO-2RO-BO'  where (class=2 and num_p=3 and num_bnr=3 and bo=1 and ro=2);
update metalnas set sid = 23321, site_type = '3PO-RO-2BO'  where (class=2 and num_p=3 and num_bnr=3 and bo=2 and ro=1);
update metalnas set sid = 23330, site_type = '3PO-3BO'     where (class=2 and num_p=3 and num_bnr=3 and bo=3);
update metalnas set sid = 23422, site_type = '3PO-2RO-2BO' where (class=2 and num_p=3 and num_bnr=4 and bo=2 and ro=2);
update metalnas set sid = 23431, site_type = '3PO-RO-3BO'  where (class=2 and num_p=3 and num_bnr=4 and bo=3 and ro=1);
update metalnas set sid = 23440, site_type = '3PO-4BO'     where (class=2 and num_p=3 and num_bnr=4 and bo=4);
update metalnas set sid = 23532, site_type = '3PO-2RO-3BO' where (class=2 and num_p=3 and num_bnr=5 and bo=3 and ro=2);
update metalnas set sid = 23541, site_type = '3PO-RO-4BO'  where (class=2 and num_p=3 and num_bnr=5 and bo=4 and ro=1);
update metalnas set sid = 23550, site_type = '3PO-5BO'     where (class=2 and num_p=3 and num_bnr=5 and bo=5);
update metalnas set sid = 23651, site_type = '3PO-RO-5BO'  where (class=2 and num_p=3 and num_bnr=6 and bo=5 and ro=1);
update metalnas set sid = 24000, site_type = '4PO'         where (class=2 and num_p=4 and num_bnr=0);          
update metalnas set sid = 24101, site_type = '4PO-RO'      where (class=2 and num_p=4 and num_bnr=1 and          ro=1);
update metalnas set sid = 24110, site_type = '4PO-BO'      where (class=2 and num_p=4 and num_bnr=1 and bo=1);
update metalnas set sid = 24202, site_type = '4PO-2RO'     where (class=2 and num_p=4 and num_bnr=2 and          ro=2);
update metalnas set sid = 24211, site_type = '4PO-RO-BO'   where (class=2 and num_p=4 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 24220, site_type = '4PO-2BO'     where (class=2 and num_p=4 and num_bnr=2 and bo=2);
update metalnas set sid = 24321, site_type = '4PO-RO-2BO'  where (class=2 and num_p=4 and num_bnr=3 and bo=2 and ro=1);
update metalnas set sid = 24330, site_type = '4PO-3BO'     where (class=2 and num_p=4 and num_bnr=3 and bo=3);
update metalnas set sid = 24431, site_type = '4PO-RO-3BO'  where (class=2 and num_p=4 and num_bnr=4 and bo=3 and ro=1);
update metalnas set sid = 24523, site_type = '4PO-3RO-2BO' where (class=2 and num_p=4 and num_bnr=5 and bo=2 and ro=3);
update metalnas set sid = 24541, site_type = '4PO-RO-4BO'  where (class=2 and num_p=4 and num_bnr=5 and bo=4 and ro=1);
update metalnas set sid = 25000, site_type = '5PO'         where (class=2 and num_p=5 and num_bnr=0);          
update metalnas set sid = 25101, site_type = '5PO-RO'      where (class=2 and num_p=5 and num_bnr=1 and          ro=1);
update metalnas set sid = 25110, site_type = '5PO-BO'      where (class=2 and num_p=5 and num_bnr=1 and bo=1);
update metalnas set sid = 25211, site_type = '5PO-RO-BO'   where (class=2 and num_p=5 and num_bnr=2 and bo=1 and ro=1);
update metalnas set sid = 25220, site_type = '5PO-2BO'     where (class=2 and num_p=5 and num_bnr=2 and bo=2);
update metalnas set sid = 25303, site_type = '5PO-3RO'     where (class=2 and num_p=5 and num_bnr=3 and          ro=3);

