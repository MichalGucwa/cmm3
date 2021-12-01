\copy pdbfile (pdbfileid,filename,pdbid,numofresidues,numofatoms,numofneighbors,numofatomneighbors) FROM PDBFILE.data WITH DELIMITER ':'

\copy residues (pdbfileid,residueid,residuetype,resname,chainid,resseq,numofatoms,location,center_displacement,accessible_surface,moolecular_surface,curvature,assemblyid,cavityif,moleculeid,prev_residueid,next_residueid) FROM RESIDUE.data WITH DELIMITER ':'

\copy atoms (pdbfileid,residueid,atomid,atomtype,atomname,atomelem,atomseq,alt,occup,bfactor,charge,location,center_displacement,accessible_surface,molecular_surface,curvature,cavityid,moleculeid) FROM ATOM.data WITH DELIMITER ':'

\copy neighbors (pdbfileid,neighborid,residueid_a,residueid_b,resname_a,resname_b,neighbortype,atomid_a,atomid_b,atomname_a,atomname_b,atomneighbortype,contact_flag,distance,bfactor_correlation) FROM NEIGHBOR.data WITH DELIMITER ':'

\copy atomneighbors (pdbfileid,neighborid,residueid_a,residueid_b,resname_a,resname_b,neighbortype,atomid_a,atomid_b,atomname_a,atomname_b,atomneighbortype,contact_flag,distance,bfactor_correlation) FROM ATOMNEIGHBOR.data WITH DELIMITER ':'

