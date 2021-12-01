\copy pdbfiles (pdbfileid, filename, pdbid, numofassemblies, numofcomponents, numofchains, numofmolecules, numofdomains,  numofresidues, numofatoms, numofneighbors, numofatomneighbors, numofligandangles, numofbindingsites,  space_group_name, space_group_number, resolution, deposition_date, exp_method, header, title) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/PDBFILE.data WITH DELIMITER '|'
\copy ccdinfo (pdbfileid, organism_id, ec_primary, ec_3rd_level, ec_4th_level, ec_complex,  cluster50_id, cluster90_id, go_process, go_function, go_component, cath_primary, cath_topology, cath_superfamily) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/CCDINFO.data WITH DELIMITER '|'
\copy geneontologies (pdbfileid, pdbid, chainid, go_type, go_id, qualifier, evidence, xref_db_name, xref_db_id,  organism_id, creation_date, created_by, ref_db_name, ref_db_id) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/GENEONTOLOGY.data WITH DELIMITER '|'
\copy assemblies (pdbfileid, assemblyid, assemblynum, assemblytype, numofcdhit_chains, numofsymop_chains, numofcavities, numofsurfrace_atoms,  total_asa, polar_asa, positive_charge_asa, negative_charge_asa, total_backbone_asa, polar_backbone_asa,  total_msa, polar_msa, positive_charge_msa, negative_charge_msa, total_backbone_msa, polar_backbone_msa) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/ASSEMBLY.data WITH DELIMITER '|'
\copy cavities (pdbfileid, cavityid, numofresidues, numofatoms, volume, assemblyid) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/CAVITY.data WITH DELIMITER '|'
\copy components (pdbfileid, componentid, componentnum, component_name, numofchains, numofkeywords, numoffunctions,  engineered, mutation, organism_id, organism_name) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/COMPONENT.data WITH DELIMITER '|'
\copy functions (pdbfileid, componentid, functionid, ec_primary, ec_3rd_level, ec_4th_level) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/FUNCTION.data WITH DELIMITER '|'
\copy keywords (pdbfileid, componentid, keywordid, keyword) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/KEYWORD.data WITH DELIMITER '|'
\copy cdhit_chains (pdbfileid, pdbid, chainid, assemblyid, chaintype,  clusterstatus, cluster50_id, represent50_id, cluster90_id, represent90_id,  num_go_all, num_go_process, num_go_function, num_go_component,  numofmolecules, numofdomains, numoffragments, numofresidues,  numres_water, numres_ligand, numres_dnarna, numres_protein) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/CDHIT_CHAIN.data WITH DELIMITER '|'
\copy symop_chains (pdbfileid, chainid, pdbid, model_number, cdhit_chainid, symop_chainid, assemblyid) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/SYMOP_CHAIN.data WITH DELIMITER '|'
\copy molecules (pdbfileid, moleculeid, moleculetype, chainid, numofresidues, assemblyid) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/MOLECULE.data WITH DELIMITER '|'
\copy domains (pdbfileid, pdbid, domainid, chainid, residueid_begin, residueid_end, is_fragment, domainnum,  cath_primary, cath_topology, cath_superfamily, cath_s35, cath_s60, cath_s95, cath_s100,  cath_uniqueid, numofresidues) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/DOMAIN.data WITH DELIMITER '|'
\copy residues (pdbfileid, residueid, residuetype, resname, chainid, resseq, numofatoms, contains_metal,  location, center_displacement, accessible_surface, molecular_surface, curvature,  assemblyid, cavityid, moleculeid, domainid, prev_residueid, next_residueid) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/RESIDUE.data WITH DELIMITER '|'
\copy atoms (pdbfileid, residueid, atomid, atomtype, atomname, atomelem, protons, atomseq, alt,  occup, bfactor, charge, location, center_displacement, accessible_surface, molecular_surface,  curvature, cavityid, moleculeid) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/ATOM.data WITH DELIMITER '|'
\copy neighbors (pdbfileid, neighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,  contact_flag, icell, isym, distance, vec_x, vec_y, vec_z, bfactor_correlation) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/NEIGHBOR.data WITH DELIMITER '|'
\copy atomneighbors (pdbfileid, atomneighborid, residueid_a, residueid_b, resname_a, resname_b, neighbortype,  atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype,  contact_flag, icell, isym, distance, vec_x, vec_y, vec_z, bfactor_correlation) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/ATOMNEIGHBOR.data WITH DELIMITER '|'
\copy ligand_bondangles (pdbfileid, bondangleid,  residueid_a, residueid_lig, residueid_b, resname_a, resname_lig, resname_b, resangletype,  atomid_a, atomid_lig, atomid_b, atomname_a, atomname_lig, atomname_b, atomangletype,  atomneighborid_a, atomneighborid_b, dist_a, dist_b, dist_lig, angle) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/LIGAND_BONDANGLE.data WITH DELIMITER '|'
\copy ion_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid,  residueid_lig, residueid_ion, resname_lig, resname_ion, neighbortype,  atomid_lig, atomid_ion, atomname_lig, atomname_ion, atomneighbortype, protons_lig, protons_ion, coord_number_lig,  contact_flag, distance, vec_x, vec_y, vec_z, bfactor_correlation,  bondvalence, calcium_bondvalence) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/ION_BONDVALENCE.data WITH DELIMITER '|'
\copy water_bondvalences (pdbfileid, bondvalenceid, neighborid, atomneighborid,  residueid_lig, residueid_water, resname_lig, neighbortype,  atomid_lig, atomid_water, atomname_lig, atomneighbortype, protons_lig, coord_number_lig,  contact_flag, distance, vec_x, vec_y, vec_z, bfactor_correlation,  sodium_bondvalence, calcium_bondvalence) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/WATER_BONDVALENCE.data WITH DELIMITER '|'
\copy ion_bindingsites (pdbfileid, bindingsiteid, residueid_ion, resname_ion, atomid_ion,  atomname_ion, protons_ion, bfactor_ion, bfactor_env_avg, occupancy_ion, occupancy_env_avg,  coord_number_3a, coord_number_3a_ons, geometry_type, geometry_bidentate, geometry_pseudo, geometry_distort, rmsd_geom_angle,  num_oxygen, num_nitrogen, num_sulfur, num_phosphorus, num_carbon, num_others,  num04_oxygen_mc, num08_oxygen_amide, num10_oxygen_carboxyl, num17_oxygen_hydroxyl,  num18_oxygen_phenol, num26_oxygen_dnarna, num28_oxygen_water, num31_oxygen_others,  num01_nitrogen_mc, num07_nitrogen_arginine, num09_nitrogen_amide, num13_nitrogen_histidine,  num14_nitrogen_lysine, num15_nitrogen_tryptophan, num25_nitrogen_dnarna, num30_nitrogen_others,  num11_sulfur_cysteine, num16_sulfur_methionine, num33_sulfur_others, num19_selenium, num41_others,  num_bidentate_all, num_bidentate_oo, num_bidentate_on, num_bidentate_nn, distance_avg, distance_min, distance_max,  valence_3a, vecsum_3a, calcium_valence_3a, calcium_vecsum_3a, coord_number_4a, num_metal_4a,  valence_4a, vecsum_4a, calcium_valence_4a, calcium_vecsum_4a) FROM /var/www/html/csgid/app/webroot/neighborhood_temp/1bxv/ION_BINDINGSITE.data WITH DELIMITER '|'
