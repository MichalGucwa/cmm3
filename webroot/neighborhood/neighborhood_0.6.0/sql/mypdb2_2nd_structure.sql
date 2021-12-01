--drop table derived_pdb_helix2;
--drop table derived_pdb_strand2;
drop table derived_pdb_helix_met2;
drop table derived_pdb_strand_met2;
drop table derived_pdb_summary_met2;

create table derived_pdb_helix2 as
(select a.pdb_id, pdbfileid, init_chain_id as chain1, init_seq_num as resseq1, end_chain_id as chain2, end_seq_num as resseq2
 from derived_pdb_helix a left join pdbfile b on a.pdb_id=upper(b.pdbid));

create table derived_pdb_strand2 as
(select a.pdb_id, pdbfileid, init_chain_id as chain1, init_seq_num as resseq1, end_chain_id as chain2, end_seq_num as resseq2
 from derived_pdb_strand a left join pdbfile b on a.pdb_id=upper(b.pdbid));

create table derived_pdb_helix_met as
(select * from (select a.pdbfileid, residueid, chainid, resseq, resseq1, resseq2
                from residues09_met a left join derived_pdb_helix2 b on a.pdbfileid=b.pdbfileid and chainid=chain1) b
 where resseq >= resseq1 and resseq <= resseq2);

create table derived_pdb_strand_met as
(select * from (select a.pdbfileid, residueid, chainid, resseq, resseq1, resseq2
                from residues09_met a left join derived_pdb_strand2 b on a.pdbfileid=b.pdbfileid and chainid=chain1) b
 where resseq >= resseq1 and resseq <= resseq2);

create table derived_pdb_summary_met as
(select pdbid, count_met, coalesce(count_helix_met, 0) as count_helix_met, coalesce(count_strand_met, 0) as count_strand_met, exp_method, exp_detail, f.pdb_id as flag_2nd from
  (select pdbfileid, count(*) as count_met from residues09_met group by pdbfileid) a
  left join (select pdbfileid, pdbid from pdbfile) b
  on a.pdbfileid=b.pdbfileid
  left join (select pdbfileid, count(*) as count_helix_met from derived_pdb_helix_met group by pdbfileid) c
  on a.pdbfileid=c.pdbfileid
  left join (select pdbfileid, count(*) as count_strand_met from derived_pdb_strand_met group by pdbfileid) d
  on a.pdbfileid=d.pdbfileid
  left join pdbstructures e
  on upper(b.pdbid)=e.pdb_id
  left join derived_pdb_2nd_structure f
  on upper(b.pdbid)=f.pdb_id
);

select count(*) from derived_pdb_summary_met where flag_2nd is not NULL and count_helix_met=0 and count_strand_met=0 and exp_method='XRAY' and (exp_detail='SAD' or exp_detail='MAD');
select count(*) from derived_pdb_summary_met where flag_2nd is not NULL and exp_method='XRAY' and (exp_detail='SAD' or exp_detail='MAD');
select count(*) from derived_pdb_summary_met where flag_2nd is not NULL and count_helix_met=0 and count_strand_met=0;
select count(*) from derived_pdb_summary_met where flag_2nd is not NULL;

create table derived_pdb_helix_met2 as
(select * from (select a.pdbfileid, residueid, chainid, resseq, resseq1, resseq2
                from residues09_met a left join derived_pdb_helix2 b on a.pdbfileid=b.pdbfileid and chainid=chain1) b
 where resseq >= resseq1-2 and resseq <= resseq2+2);

create table derived_pdb_strand_met2 as
(select * from (select a.pdbfileid, residueid, chainid, resseq, resseq1, resseq2
                from residues09_met a left join derived_pdb_strand2 b on a.pdbfileid=b.pdbfileid and chainid=chain1) b
 where resseq >= resseq1-2 and resseq <= resseq2+2);

create table derived_pdb_summary_met2 as
(select pdbid, count_met, coalesce(count_helix_met, 0) as count_helix_met, coalesce(count_strand_met, 0) as count_strand_met, exp_method, exp_detail, f.pdb_id as flag_2nd from
  (select pdbfileid, count(*) as count_met from residues09_met group by pdbfileid) a
  left join (select pdbfileid, pdbid from pdbfile) b
  on a.pdbfileid=b.pdbfileid
  left join (select pdbfileid, count(*) as count_helix_met from derived_pdb_helix_met2 group by pdbfileid) c
  on a.pdbfileid=c.pdbfileid
  left join (select pdbfileid, count(*) as count_strand_met from derived_pdb_strand_met2 group by pdbfileid) d
  on a.pdbfileid=d.pdbfileid
  left join pdbstructures e
  on upper(b.pdbid)=e.pdb_id
  left join derived_pdb_2nd_structure f
  on upper(b.pdbid)=f.pdb_id
);

select count(*) from derived_pdb_summary_met2 where flag_2nd is not NULL and count_helix_met=0 and count_strand_met=0 and exp_method='XRAY' and (exp_detail='SAD' or exp_detail='MAD');
select count(*) from derived_pdb_summary_met2 where flag_2nd is not NULL and exp_method='XRAY' and (exp_detail='SAD' or exp_detail='MAD');
select count(*) from derived_pdb_summary_met2 where flag_2nd is not NULL and count_helix_met=0 and count_strand_met=0;
select count(*) from derived_pdb_summary_met2 where flag_2nd is not NULL;


