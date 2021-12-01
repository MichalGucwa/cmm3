<?php
// src/Controller/ArticlesController.php

namespace App\Controller;

$GLOBALS["server_neighborhood_temp"]="neighborhood_temp";
$GLOBALS["neighborhood_temp"]="neighborhood_temp2";

class MetalSitesController extends AppController
{

  public $name = 'MetalSites';
  //TODO something wrong with line below maybe it is not needed
  // public $helpers = array('Html', 'Form');
  public $scaffold;
  public $is_resource=0;
  public $plot_data_json="";
  public $pdbfile_valid=0;
  public $file_pdbfiles="";
  public $file_residues="";
  public $file_neighbors="";
  public $file_ion_bondvalence="";
  public $file_ion_bindingsite="";
  public $file_contact_upload=0;


  function index () {
    $this->record_ip("visitors");

    $this->viewBuilder()->setLayout('cmm');

    $this->set('jmol',0);
    $this->set('is_resource',0);
    $this->set('output_content_type',"html");

    $passedArgs = $this->request->getParam('pass');

    if(count($passedArgs) >= 1) {
      $temp_id=$passedArgs[0];
      if($temp_id=="jmol") { $this->set('jmol',1); }
      elseif($temp_id=="refmac") { $this->set('is_resource',1); $this->set('output_content_type',"refmac"); }
      elseif($temp_id=="json")   { $this->set('is_resource',1); $this->set('output_content_type',"json"); }
      elseif($temp_id=="xml")    { $this->set('is_resource',1); $this->set('output_content_type',"xml"); }
      elseif($temp_id=="csv")    { $this->set('is_resource',1); $this->set('output_content_type',"csv"); }
    }

    //TODO on the end I will play around with sql
    // $index_stat_arr = $this->MetalSite->query("select (select count(distinct sessionid) from usages where sessionid like '____ %') as stat_pdbids, count(distinct sessionid) as stat_structures, count(distinct a.ip) as stat_users, count(distinct country) as stat_countries from (select sessionid, ip, test_data from usages) a left join identities b on a.ip=b.ip where test_data is false;");
    // $this->set('index_stat',$index_stat_arr);

    // END OF HEPPING Controller

    //Continuation of Michal Controller
  } //end of index

  function modelsite(){
    $this->viewBuilder()->setLayout('cmm');
    //NOTE i am not planning here to be resource
    // if($this->is_resource) {$this->set('is_resource',1);} else {$this->set('is_resource',0);}
    $this->set('is_resource',0);

    if($this->request->is('post')){
      $data = $this->request->getData();
      $this->set('data', $data);
    }

    $this->set('res_dep', 0);
    $res_dep=0;

    $this->set('is_pdb_format', 0);
    $ip=$this->get_client_ip_server();

    //TODO make this work
    // $usage_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename!='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
    // $this->set('usage_arr', $usage_arr);
    // $usage0_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
    // $this->set('usage0_arr', $usage0_arr);

    if(!empty($data['mg_pdb_path'])) {
      //TODO finish sql
      $usage_arr=[1];
      // $pdbfileid_arr = $this->MetalSite->query("select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");
      #debug ("pdbfileid_arr = select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");

        if(substr($ip, 0, 4) !== "10.1" && count($usage_arr)>=100) { //if it was tried to look for record that is no in database too many times
          $this->set('pdbfile_valid',-1);
          $this->set('pdbfile_name',$ip);
        } else {
          $pdbfileid=$this->get_pdbfileid();
          $mg_list_temp=explode('/',$data['mg_pdb_path']);
          $pdbfile=end($mg_list_temp);
          $tmpname=$data['mg_pdb_path'];

          //TODO find better name method
          $session='abcdef';
          $session.="_$pdbfileid";

          $selected=[];
          for($i=0;$i<$data['n_sites'];$i++){
            array_push($selected,$data['selection'.$i]);
          }
          $info_selected=[];
          for($i=0;$i<$data['n_sites'];$i++){
            array_push($info_selected,$data['info_selection'.$i]);
          }
          $modeled_sites['info']=$info_selected;
          $modeled_sites['selected']=$selected;
          $modeled_sites['densfile_2fo']=$data['densfile_2fo'];
          $modeled_sites['densfile_fo']=$data['densfile_fo'];

          list($retval,$errmsg)=$this->calculate_session($session,$tmpname,$pdbfileid,$modeled_sites);
          if(!$retval) {
            if(substr($pdbfile,-3) === "pdb" or substr($pdbfile,-3) === "ent") {
              $this->set_valid_session($session,"XXXX.pdb",0,'yes');
              $filename=$GLOBALS["neighborhood_temp"]."/$session/XXXX.pdb";
              $this->set('is_pdb_format', 1);
            }else {
              $this->set_valid_session($session,"XXXX.cif",0,'yes');
              $filename=$GLOBALS["neighborhood_temp"]."/$session/XXXX.cif";
            }
            //TODO make it work
            // $this->update_database_usage($session,1,0,0,$pdbfileid,$filename);
          } else {
            $this->set('pdbfile_valid',0);
            //TODO riddle this
            debug("fix this");exit;
            $this->set('pdbfile_name',$this->data['MetalSite']['pdbfile']['name'].":".$errmsg);
          }
        }
    }else {
        echo "No input data received!";
    }
    $this->set('plot_data_json',$this->plot_data_json);



    //NOTE end of mod michal and heping controlelr
    //Michal Controller
    $this->michal_controller($res_dep);
  }







  function listsite () {
    $this->viewBuilder()->setLayout('cmm');
    if($this->is_resource) {$this->set('is_resource',1);} else {$this->set('is_resource',0);}

    if($this->request->is('post')){
      $data = $this->request->getData();
      $this->set('data', $data);
    }

    //if checkbox of resolution dependent is on
    if(array_key_exists('resolutiondependent', $data)) {
      $this->set('res_dep', 1);
      $res_dep=1;
    } else {
      $this->set('res_dep', 0);
      $res_dep=0;
    }

    $this->set('is_pdb_format', 0);
    $is_pdb_format=0;
    $example=0;
    if(array_key_exists('example', $data)) { # selected by example button
      $example=$data['example'];
      if ($example) {
        //TODO idk what it is for
        $data['pdbid']=$data['pdbid'];
      }
    } # if example button $this->data['MetalSite']['pdbid']=$_REQUEST['pdbid'];


    //$ip=$_SERVER['REMOTE_ADDR'];
      $ip=$this->get_client_ip_server();
      //TODO finish this sql
      // $usage_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename!='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
      #debug ("usage_arr = '$usage_arr[0]' = select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename!='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
      // $this->set('usage_arr', $usage_arr);
      #debug ("usage0_arr = '$usage0_arr' = select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
      // $usage0_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
      // $this->set('usage0_arr', $usage0_arr);

      if (!empty($data['pdbid'])) {
        $pdbid=trim($data['pdbid']);
        if(strlen($pdbid)==4) { $pdbid=strtolower($pdbid); };
        //TODO finish sql
        $usage_arr=[1];
        if(is_dir($GLOBALS["server_neighborhood_temp"].'/'.$pdbid) and strlen($pdbid)==4) {$pdbfileid_arr=[1];} else {$pdbfileid_arr=[];}
        // $pdbfileid_arr = $this->MetalSite->query("select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");
        #debug ("pdbfileid_arr = select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");

        if($this->is_heping($ip) && strlen($pdbid)!=4 && $example==0) { $example=2; };
        if($this->is_tutorial($pdbid)) { $example=2; };
        if(strlen($pdbid)!=4 and $example!=2) {
          $this->set('pdbfile_valid',0);
          $this->set('pdbfile_name',$pdbid);
        } elseif(!count($pdbfileid_arr)) { //means that there is no in database
          if(substr($ip, 0, 4) !== "10.1" && count($usage_arr)>=500) { //if it was tried to look for record that is no in database too many times
            $this->set('pdbfile_valid',-1);
            $this->set('pdbfile_name',$ip);
          } else {
            list($elename,$element)=$this->fetch_pdbfile($pdbid);
            if($element != "") {
              $pdbfileid=$this->get_pdbfileid();
              list($retval,$errmsg)=$this->calculate_session($pdbid,$element,$pdbfileid);
              if(!$retval) {
                $this->set_valid_session($pdbid,$element,$example);
                $this->fetch_electron($pdbid);
                //TODO make this work
                // $this->update_database_usage($pdbid,2,$example,0,$pdbfileid,$elename);
              } else {
                $this->set('pdbfile_valid',0);
                $this->set('pdbfile_name',$element.":".$errmsg);
              }
            } else {
              $this->set('pdbfile_valid',0);
              $this->set('pdbfile_name',"No such PDBID $pdbid in PDB!");
            }
          }
        } else {
          //TODO z tym bedzie sporo zabawy, narazie daje tymczasowe za linijke nizej
          // $this->set_valid_session($pdbid,$pdbfileid_arr[0][0]['filename'],$example);
          $row = exec('ls '.$GLOBALS["server_neighborhood_temp"].'/'.$pdbid.'/*'.$pdbid.'.*',$output,$error);
          $mg_filename=explode('/',$row);
          $mg_filename=end($mg_filename);
          $this->set_valid_session($pdbid,$mg_filename,$example);
          //check if there is already maps
          if(!file_exists($GLOBALS["neighborhood_temp"].'/'.$pdbid.'/'.$pdbid.'_fofc.dsn6') or !file_exists($GLOBALS["neighborhood_temp"].'/'.$pdbid.'/'.$pdbid.'_2fofc.dsn6')){
            $this->fetch_electron($pdbid);
          } else { //if maps exists
            $this->set('densfile_fo',$GLOBALS["neighborhood_temp"].'/'.$pdbid.'/'.$pdbid.'_fofc.dsn6');
            $this->set('densfile_2fo',$GLOBALS["neighborhood_temp"].'/'.$pdbid.'/'.$pdbid.'_2fofc.dsn6');
          }
          //TODO sql
          // if($example!=2) {$this->update_database_usage($pdbid,2,$example,0,$pdbfileid_arr[0][0]['pdbfileid'],"");};
        }

        $this->set('is_pdb_format', 1);
      } else { //if string search is nothing
        echo "No input data received!";
        return $this->redirect(['controller' => 'MetalSites','action' => 'nopdb',$data['pdbid']]);
      }
      $this->set('plot_data_json',$this->plot_data_json);

      //NOTE end of Heping controller
      $alt_metal_arr=array();

      $pdburl="http://www.pdb.org/pdb/explore/explore.do?structureId=";
      if($this->pdbfile_valid){

        $handle=fopen($this->file_pdbfiles, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_pdbfile=explode('|',$buffer);
          $space_group_number=$one_pdbfile[15];
          $resolution=$one_pdbfile[16];
          $this->set('resolution',$resolution);
          $deposition_date=$one_pdbfile[17];
          $exp_method=$one_pdbfile[18];
          $title=$one_pdbfile[20];
          $this->set('title',$title);
          $pdblink=$pdburl.$one_pdbfile[2];
          $this->set('pdblink',$pdblink);
          $numbindingsites=$one_pdbfile[13];
          // debug($numbindingsites);exit;
        }
        fclose($handle);


        $handle=fopen($this->file_residues, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_residue=explode('|',$buffer);
          $residue_chainid[$one_residue[1]]=$one_residue[4];
          $residue_resseq[$one_residue[1]]=$one_residue[5];
          $residue_metal_atomid[$one_residue[1]]=-1;
          $residue_multi_metal[$one_residue[1]]=0; /* number of metal ions in the residue, if more than one, a metal-cluster warning will be issued */
          $residue_env_comp[$one_residue[1]]=0;
        /* Within 4A radius, each small molecule residue increase this by 1,
                         each additional multinuclear metal by 10,
                         each Tyr/Phe/Trp carbon in ring by 100 */
          $residue_HIS_allowance[$one_residue[1]]=0;
          $residue_N1_allowance[$one_residue[1]]=0;
          $residue_N3_allowance[$one_residue[1]]=0;
          $residue_N7_allowance[$one_residue[1]]=0;
        }
        fclose($handle);


        $handle=fopen($this->file_neighbors, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_neighbor=explode('|',$buffer);
          if($one_neighbor[6] % 100 >= 44) {
            $resid_a    = $one_neighbor[2];               $resid_b    = $one_neighbor[3];
            $restype_a  = floor($one_neighbor[6]  / 100); $restype_b  = $one_neighbor[6]  % 100;
            $atomtype_a = floor($one_neighbor[11] / 100); $atomtype_b = $one_neighbor[11] % 100;
            $distance   = $one_neighbor[15];
            if($restype_a>=35 and $restype_a<=40) {
              if($atomtype_a==12 and $atomtype_b==40) {
                $residue_env_comp[$resid_b] += 100;
              };
            } elseif($restype_a>=44) {
              if($atomtype_a==36 or $atomtype_a==37 or $atomtype_a==40) {
                if($distance>=0.5) { $residue_env_comp[$resid_b] += 10; };
              } elseif($atomtype_a>=29 and $atomtype_a<=33) {
                if($distance<=3.5) { $residue_env_comp[$resid_b] ++; };
              }
              if($atomtype_b==36 or $atomtype_b==37 or $atomtype_b==40) {
                if($distance>=0.5) { $residue_env_comp[$resid_a] += 10; };
              } elseif($atomtype_b>=29 and $atomtype_b<=33) {
                if($distance<=0.5) { $residue_env_comp[$resid_a] ++; };
              }
            }
          }
        }
        fclose($handle);

        $handle=fopen($this->file_ion_bondvalence, "r");
        $refmac_pdb="";
        $refmac_chem_link="";
        $refmac_chem_link_bond="";
        $linkid_exist = 0;
        while(($buffer=fgets($handle,4096)) != false) {
          $one_bv=explode('|',$buffer);
          list($pdb_txt, $cif_txt, $cif_txt_2) = $this->refmac_record_by_bondvalence($one_bv, $one_bv[5], trim($one_bv[12],"-"), $residue_chainid, $residue_resseq);
          $refmac_pdb.=$pdb_txt;
          $refmac_chem_link.=$cif_txt;
          $refmac_chem_link_bond.=$cif_txt_2;
          if($one_bv[12]=='MG--' || $one_bv[12]=='-K--' || $one_bv[12]=='NA--') {
            if($one_bv[6]=='HIS' && ($one_bv[11]=='-ND1' || $one_bv[11]=='-NE2') && $one_bv[23]>0.08) {
              $residue_HIS_allowance[$one_bv[5]]++;
            } elseif($one_bv[6]=='__A' && $one_bv[11]=='-N1-' && $one_bv[23]>0.08) {
              $residue_N1_allowance[$one_bv[5]]++;
            } elseif(($one_bv[6]=='__G' || $one_bv[6]=='__A' || $one_bv[6]=='__C') && $one_bv[11]=='-N3-' && $one_bv[23]>0.08) {
              $residue_N3_allowance[$one_bv[5]]++;
            } elseif(($one_bv[6]=='__G' || $one_bv[6]=='__A' || $one_bv[6]=='_DG' || $one_bv[6]=='_DA') && $one_bv[11]=='-N7-' && $one_bv[23]>0.08) {
              $residue_N7_allowance[$one_bv[5]]++;
            }
          }
          if($residue_metal_atomid[$one_bv[5]]==-1) {
            $residue_metal_atomid[$one_bv[5]]=$one_bv[10];
          } else {
            if($residue_metal_atomid[$one_bv[5]]!=$one_bv[10]) {
              $residue_multi_metal[$one_bv[5]]=1;
            }
          }
        }
        fclose($handle);


        $handle=fopen($this->file_ion_bindingsite, "r");
        $number_binding_sites=0;
        $partial_occupancy_symop=0;
        $jmol_site_definition="";
        $jmol_list_sites="";
        $jmol_list_centers="";
        $jmol_list_envs="";
        $jmol_measure_allconnected="";
        $first_cutoff=0;
        $exotic_lig_msg="";
        $exotic_met_msg="";
        $exotic_ring_msg="";
        $rare_metal_detected=0;
        $site_id=0;
        $is_first_site=1;
        $refmac_pdb_alt="";
        $refmac_chem_link_alt="";
        $refmac_chem_link_bond_alt="";
        $mg_i_site=-1;
        while(($buffer=fgets($handle,4096)) != false) {
          $mg_i_site+=1;
          $valence_is_problematic=0;

          list($pdbfileid,$bindingsiteid,$residueid_ion,$resname_ion,$atomid_ion,$atomname_ion,$protons_ion,$bfactor_ion,$bfactor_env_avg,$occupancy_ion,$occupancy_env_avg,$coord_number_3a,$coord_number_3a_ons,$geometry_type,$geometry_bidentate,$geometry_pseudo,$geometry_distort,$rmsd_geom_angle,$num_oxygen,$num_nitrogen,$num_sulfur,$num_phosphorus,$num_carbon,$num_others,$num04_oxygen_mc,$num08_oxygen_amide,$num10_oxygen_carboxyl,$num17_oxygen_hydroxyl,$num18_oxygen_phenol,$num26_oxygen_dnarna,$num28_oxygen_water,$num31_oxygen_others,$num01_nitrogen_mc,$num07_nitrogen_arginine,$num09_nitrogen_amide,$num13_nitrogen_histidine,$num14_nitrogen_lysine,$num15_nitrogen_tryptophan,$num25_nitrogen_dnarna,$num30_nitrogen_others,$num11_sulfur_cysteine,$num16_sulfur_methionine,$num33_sulfur_others,$num19_selenium,$num41_others,$num_bidentate_all,$num_bidentate_oo,$num_bidentate_on,$num_bidentate_nn,$distance_avg,$distance_min,$distance_max,$valence_3a,$vecsum_3a,$calcium_valence_3a,$calcium_vecsum_3a,$coord_number_4a,$num_metal_4a,$valence_4a,$vecsum_4a,$calcium_valence_4a,$calcium_vecsum_4a)=explode('|',$buffer);
          for($j=0;$j<13;$j++) { $bg[$mg_i_site][$j] = "#CCCCCC"; }
          $atomname_ion_nodash = preg_replace('/-/','',$atomname_ion);
          if($atomname_ion_nodash=='CA') {$atomname_ion_nodash='';};
          $chainid_colon_resseq=$residue_chainid[$residueid_ion].':'.$residue_resseq[$residueid_ion];
          $resseq_colon_chainid=$residue_resseq[$residueid_ion].':'.$residue_chainid[$residueid_ion];
          $mg_sites[]=$residue_resseq[$residueid_ion].':'.$residue_chainid[$residueid_ion].".".$atomname_ion_nodash;

          $number_binding_sites++;
          $id_binding_center="met".$number_binding_sites;
          $id_binding_env ="close".$number_binding_sites;
          $id_binding_env2="far".$number_binding_sites;
          $id_binding_site ="site".$number_binding_sites;
          switch ($protons_ion) {
            case 11: case 12: case 20:
            case 25: case 26: case 27:
            case 28: case 29: case 30:
                     $cutoff=2.8; break;
            case 19: $cutoff=3.3; break;
            default: $cutoff=3.3; if($protons_ion==31 or $protons_ion>=37) { $rare_metal_detected=1; }; break;
          }
          if($first_cutoff==0) {$first_cutoff=$cutoff;}
          $jmol_site_definition.="define $id_binding_center $resseq_colon_chainid.$atomname_ion_nodash; ";
          $jmol_site_definition.="define $id_binding_env2 (within (group, within (5.0, $id_binding_center)) and not $id_binding_center); ";
          $jmol_site_definition.="define $id_binding_env (within ($cutoff, $id_binding_center) and not elemno=1 and not elemno=6 and not $id_binding_center); ";
          $jmol_site_definition.="define $id_binding_site within (group, within (5.0, $id_binding_center)); ";
          $jmol_site_definition.="connect ($id_binding_center) ($id_binding_env and not _C) partial 1.1; ";
          if ($jmol_list_sites!="")   {$jmol_list_sites.=" or ";};
          if ($jmol_list_centers!="") {$jmol_list_centers.=" or ";};
          if ($jmol_list_envs!="")    {$jmol_list_envs.=" or ";};
          $jmol_list_sites.=$id_binding_site;
          $jmol_list_centers.=$id_binding_center;
          $jmol_list_envs.=$id_binding_env2;
          $jmol_measure_allconnected.="measure allconnected ($id_binding_center)($id_binding_env); ";
        # ACN == assumed coordination number; AOS == assumed oxidation state; LRW == Low resolution weight
          switch ($geometry_type) {
            case  0: $ACN=-1; break;
            case  1: $ACN=2;  break;
            case  2: $ACN=3;  break;
            case  3: $ACN=4;  break;
            case  4: $ACN=4;  break;
            case  5: $ACN=5;  break;
            case  6: $ACN=6;  break;
            case  7: $ACN=6;  break;
            case  8: $ACN=6;  break;
            case  9: $ACN=7;  break;
            case 10: $ACN=7;  break;
            case 11: $ACN=8;  break;
            case 12: $ACN=8;  break;
            case 13: $ACN=8;  break;
            case 15: $ACN=-1; break;
            case 16: $ACN=-1; break;
            default: $ACN=-1; break;
          }
          $ACN4 = ($ACN>4) ? $ACN : 4;
          if($res_dep==0) {
            $low_resolution_weight=0;
          } elseif($exp_method==2) {
            $low_resolution_weight=0;
          } elseif($resolution>=3 and $resolution<100) {
            $low_resolution_weight=0.9999;
          } elseif($resolution>2 and $resolution<3) {
            $low_resolution_weight=$resolution-2.0001;
          } else {
            $low_resolution_weight=0;
          }

          $val[$mg_i_site][0]=$chainid_colon_resseq;
          $val[$mg_i_site][1]=trim($resname_ion,"_");
          $val[$mg_i_site][2]=ucwords(strtolower(trim($atomname_ion,"-")));
          $val[$mg_i_site][3]=round($occupancy_ion,2);
          if($val[$mg_i_site][3]<=0.5) { $partial_occupancy_symop = 1; }
          if($val[$mg_i_site][3]<=0.01) {	# Evaluation of B factor is not applicable if metal occupancy is too low
            $val[$mg_i_site][4]="N/A";
          } elseif($exp_method==0) {
            if($bfactor_ion<2 && $bfactor_env_avg<2) {
              $val[$mg_i_site][4]="N/A";
            } else {
              $val[$mg_i_site][4]=round($bfactor_ion,1)." (".round($bfactor_env_avg,1).")";
            }
          } elseif($exp_method==1) {
            $val[$mg_i_site][4]=round($bfactor_ion,1)." (".round($bfactor_env_avg,1).")";
          } else {
            $val[$mg_i_site][4]="N/A";
          }
          if($this->is_resource) {
            $val[$mg_i_site][5]=  $num_carbon     ? 'C'.$num_carbon   : '';
            $val[$mg_i_site][5].= $num_oxygen     ? 'O'.$num_oxygen   : '';
            $val[$mg_i_site][5].= $num_nitrogen   ? 'N'.$num_nitrogen : '';
            $val[$mg_i_site][5].= $num_sulfur     ? 'S'.$num_sulfur   : '';
          } else {
            $val[$mg_i_site][5]=  $num_carbon     ? 'C<sub>'.$num_carbon.'</sub>'     : '';
            $val[$mg_i_site][5].= $num_oxygen     ? 'O<sub>'.$num_oxygen.'</sub>'     : '';
            $val[$mg_i_site][5].= $num_nitrogen   ? 'N<sub>'.$num_nitrogen.'</sub>'   : '';
            $val[$mg_i_site][5].= $num_sulfur     ? 'S<sub>'.$num_sulfur.'</sub>'     : '';
          }
        #     $val[5].= $num_phosphorus ? 'P<sub>'.$num_phosphorus.'</sub>' : '';
        #     if($valence_3a>0) {
        #      if($valence_3a>=0.2) { $val[6]=round($valence_3a,1); } else { $val[6]=round($valence_3a,2); }
        #     } else {
        #       $val[6]="N/A";
        #     }
        #     if($valence_3a>0 and $vecsum_3a>0) {
        #      if($vecsum_3a/$valence_3a>=0.1) { $val[7]=round($vecsum_3a/$valence_3a,2); } else { $val[7]=round($vecsum_3a/$valence_3a,3) };
        #     } else {
        #       $val[7]="N/A";
        #     }
          $val[$mg_i_site][6]=$valence_3a>0 ? round($valence_3a,2) : "N/A";
          if($valence_3a>=0.2) { $val[$mg_i_site][6]=round($valence_3a,1); }
          $val[$mg_i_site][7]=($valence_3a>0 and $vecsum_3a>0) ? round($vecsum_3a/$valence_3a,3) : "N/A";
          if($val[$mg_i_site][7]>=0.1) { $val[$mg_i_site][7]=round($vecsum_3a/$valence_3a,2); }
          $val[$mg_i_site][8]=$geometry_type;
          $val[$mg_i_site][9]=($rmsd_geom_angle>=0 && $rmsd_geom_angle<180) ? round($rmsd_geom_angle,1) : "N/A";
          $val[$mg_i_site][10]=($geometry_pseudo>=0 && $ACN>=0) ? $geometry_pseudo*100/$ACN : "N/A";
          $val[$mg_i_site][11]=$geometry_bidentate>=0 ? $geometry_bidentate : "N/A";
          $val[$mg_i_site][20]=round($calcium_valence_3a,2);
          $heme=0;
          switch ($resname_ion) {
            case "HEM": case "CLI": case "CLA": case "HEC": case "BCL": case "CYC":
            case "BPH": case "CHL": case "HEA": case "BCB": case "BLA": case "DHE":
            case "PEB": case "BPB": case "SFP": case "HDD": case "FEC": case "PHO":
            case "HNI": case "SRM": case "PP9": case "COH":
            case "1CP": case "CLN": case "CP3": case "DDH": case "DEU": case "FDD":
            case "FDE": case "FMI": case "H01": case "H02": case "HCO": case "HE5":
            case "HEG": case "HEV": case "HFM": case "HIF": case "HME": case "MHM":
            case "MMP": case "MNH": case "MNR": case "MP1": case "PC3": case "PCU":
            case "PNI": case "POH": case "POR": case "VEA": case "VER": case "ZEM":
            case "ZNH": $heme=1; break;
            default:
              $heme=0; break;
          }

        # common background color handling for five fields: occupancy, valence, nVECSUM, gRMSD, and vacancy
          $valve[3]=array(0.01, 0.99, 1000, 1000);
          switch ($protons_ion) {
            case 11: case 19:
            case 37: case 55: case 87: $bv_valve_1=0.4; $bv_valve_2=0.7; $bv_valve_3=1.3; $bv_valve_4=1.6; $AOS=1; break;
            case 12: case 20:
            case 38: case 56: case 88:
            case 30: case 48: case 80: $bv_valve_1=1.3; $bv_valve_2=1.7; $bv_valve_3=2.3; $bv_valve_4=2.7; $AOS=2; break;
            case 25: case 43: case 75: $bv_valve_1=1.0; $bv_valve_2=1.7; $bv_valve_3=4.4; $bv_valve_4=5.2; $AOS=2; break;
            case 26: case 27: case 28:
            case 44: case 45: case 46:
            case 76: case 77: case 78: $bv_valve_1=1.2; $bv_valve_2=1.6; $bv_valve_3=3.3; $bv_valve_4=3.6; $AOS=2; break;
            case 29: case 47: case 79: $bv_valve_1=0.4; $bv_valve_2=0.7; $bv_valve_3=2.3; $bv_valve_4=2.6; $AOS=1; break;
            default:                   $bv_valve_1=1.0; $bv_valve_2=1.7; $bv_valve_3=3.3; $bv_valve_4=4.0; $AOS=2; break;
          };
          $LRW=$low_resolution_weight/$ACN4;
          $valve[6]=array($bv_valve_1-$AOS*$LRW, $bv_valve_2-$AOS*$LRW, $bv_valve_3, $bv_valve_4);
          $vecsum_valve_3=sqrt(0.10*0.10+$LRW*$LRW);
          $vecsum_valve_4=sqrt(0.23*0.23+$LRW*$LRW);
          $valve[7]=array(-1, -1, $vecsum_valve_3, $vecsum_valve_4);
          $valve[9]=array(-1, -1, 13.5, 21.5);
          $valve[10]=array(-1, -1, 1+25*$low_resolution_weight, 25+25*$low_resolution_weight);

          for($j=3;$j<=10;$j++) {
            if($j!=4 && $j!=5 && $j!=8) {
              if($j==7 && ($val[$mg_i_site][$j]=="0.000" || $val[$mg_i_site][$j]=="0"))  $bg[$mg_i_site][$j]="#AAFFAA";
              elseif($j==10 && $val[$mg_i_site][$j]=="0") $bg[$mg_i_site][$j]="#AAFFAA";
        elseif($val[$mg_i_site][$j]=="N/A")         $bg[$mg_i_site][$j]="#CCCCCC";
              elseif($j==3 && $exp_method==2) $bg[$mg_i_site][$j]="#CCCCCC";
              elseif($j==3 && $val[$mg_i_site][3]<=0.5 && $this->pdbfile_valid>0 && strlen($this->file_contact_upload)>2) $bg[$mg_i_site][$j]="#CCCCCC";
        elseif($val[$mg_i_site][$j]<$valve[$j][0])  $bg[$mg_i_site][$j]="#FFAAAA";
        elseif($val[$mg_i_site][$j]<$valve[$j][1])  $bg[$mg_i_site][$j]="#FFFFAA";
        elseif($val[$mg_i_site][$j]<=$valve[$j][2]) $bg[$mg_i_site][$j]="#AAFFAA";
        elseif($val[$mg_i_site][$j]<=$valve[$j][3]) $bg[$mg_i_site][$j]="#FFFFAA";
        else                            $bg[$mg_i_site][$j]="#FFAAAA";
            }
          }
          if($bg[$mg_i_site][6]=="#FFAAAA" or $bg[$mg_i_site][7]=="#FFAAAA") {$valence_is_problematic=1;};

        # special background color handling for composition
          $composition="a";
          switch ($protons_ion) {
            case 11:
            case 12:
            case 19:
            case 20:
                     if($protons_ion!=20 && $residue_HIS_allowance[$residueid_ion]+$residue_N1_allowance[$residueid_ion]+$residue_N3_allowance[$residueid_ion]+$residue_N7_allowance[$residueid_ion]>=$num_nitrogen) {
                       $composition="a";
                     } elseif($num_nitrogen or $num_sulfur) {$composition="o"; }
                     break;
            case 25:
                     if($num_sulfur or $num_phosphorus) {$composition="b"; }
                     break;
            case 28:
            case 29:
            case 30:
                     if(!$num_nitrogen and !$num_sulfur and !$num_phosphorus) {$composition="b"; }
                     break;
            default:
                     break;
          };

          if($num_carbon) {$composition="o"; }
          if($num_oxygen+$num_nitrogen+$num_sulfur+$num_phosphorus<=1) {$composition="o"; }
          elseif($num_oxygen+$num_nitrogen+$num_sulfur+$num_phosphorus<=2 and $composition!="o") {$composition="b"; }
          if(!$num_oxygen and !$num_nitrogen and !$num_sulfur and !$num_phosphorus) {$composition="o"; }
          if($composition=="a") {			# acceptable
            $bg[$mg_i_site][5]="#AAFFAA";
          } elseif($composition=="b") {		# borderline
            $bg[$mg_i_site][5]="#FFFFAA";
          } else {
            $bg[$mg_i_site][5]="#FFAAAA";
          }

        # New algorithm
          if($bfactor_ion>$bfactor_env_avg) {
            $bfactor_coeff2= $bfactor_ion>0 ? ($bfactor_env_avg/$bfactor_ion) : ($bfactor_env_avg/0.0000001);
          } else {
            $bfactor_coeff2= $bfactor_env_avg>0 ? ($bfactor_ion/$bfactor_env_avg) : ($bfactor_ion/0.0000001);
          }
          $bfactor_diff="o";
          if($bfactor_coeff2>1.1) {
            $bfactor_diff="o";
          } elseif($bfactor_coeff2>=0.86) {
            $bfactor_diff="a";
          } elseif($bfactor_coeff2>=0.54) {
            $bfactor_diff="b";
          } else {
            $bfactor_diff="o";
          }
        # special background color handling for B factor difference
        #     if($bfactor_ion>$bfactor_env_avg) {
        #       $bfactor_coeff1=($bfactor_ion-$bfactor_env_avg);
        #       $bfactor_coeff2= $bfactor_env_avg>0 ? ($bfactor_ion/$bfactor_env_avg) : ($bfactor_ion/0.0000001);
        #     } else {
        #       $bfactor_coeff1=($bfactor_env_avg-$bfactor_ion);
        #       $bfactor_coeff2= $bfactor_ion>0 ? ($bfactor_env_avg/$bfactor_ion) : ($bfactor_env_avg/0.0000001);
        #     }
        #     $bfactor_diff="o";
        # Old algorithm
        #     if($bfactor_coeff1<=30.0-40.0*log($bfactor_coeff2)) {
        #       $bfactor_diff="a";
        #     } elseif($bfactor_coeff1<=70.0-40.0*log($bfactor_coeff2)) {
        #       $bfactor_diff="b";
        #     } else {
        #       $bfactor_diff="o";
        #     }
        # Old old algorithm
        #     if($bfactor_coeff1<20.0) {
        #       if($bfactor_coeff2<2.0) { $bfactor_diff="a";
        #       } elseif($bfactor_coeff2<5.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } elseif($bfactor_coeff1<40.0) {
        #       if($bfactor_coeff2<3.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } elseif($bfactor_coeff1<60.0) {
        #       if($bfactor_coeff2<2.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } else {
        #       $bfactor_diff="o";
        #     }
          if ($bfactor_ion <= 2 or $bfactor_env_avg <= 2) { $bfactor_diff="o"; }
          if($val[$mg_i_site][4]=="N/A") {			# not applicable
            $bg[$mg_i_site][4]="#CCCCCC";
          } elseif($bfactor_diff=="a") {		# acceptable
            $bg[$mg_i_site][4]="#AAFFAA";
          } elseif($bfactor_diff=="b") {		# borderline
            $bg[$mg_i_site][4]="#FFFFAA";
          } else {
            $bg[$mg_i_site][4]="#FFAAAA";
          }

        # special background color handling for geometry
          $coordnum=$coord_number_3a_ons-$geometry_bidentate;
          $proton_arr = array(11,12,19,20,25,26,27,28,29,30,80);
          $common_metal=0;
          foreach ($proton_arr as $proton) {
            $alternative[$proton]=0;
            $t="o";	#outlier
        # check coordination sphere profile
            if($num_sulfur or $num_nitrogen) {
              if($proton>=25) { $alternative[$proton]+=10; }
            } else {
              if($proton>=25) { $alternative[$proton]+=10; }
              else { $alternative[$proton]+=11; }
            }
        # check geometry
            switch ($proton) {
              case 11: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";}; break;
              case 19: if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==12 or $val[$mg_i_site][8]==9 or $val[$mg_i_site][8]==11) {$t="b";}; break;
              case 12: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==10) {$t="o";}; break;
              case 20: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==9 or $val[$mg_i_site][8]==10 or $val[$mg_i_site][8]==12) {$t="b";}; break;
              case 25: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==10) {$t="b";}; break;
              case 26: if($heme) {
                       if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==10) {$t="b";};
                       } else {
                       if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="b";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";};
                       }; break;
              case 27: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==3) {$t="b";}; break;
              case 28: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3) {$t="b";}; break;
        # Copper, set square planar as acceptable
              case 29: if($val[$mg_i_site][8]==4 or $val[$mg_i_site][8]==3) {$t="a";} elseif($val[$mg_i_site][8]==6 or $val[$mg_i_site][8]==2) {$t="b";}; break;
              case 30: if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="b";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";}; break;
              case 80: if($val[$mg_i_site][8]==1) {$t="a";}; break;
            }
            if($proton==$protons_ion) { $common_metal=1; };
            $geometry[$proton]=$t;
            if($t == "a") {
              $alternative[$proton]+=12;
            } elseif($t == "b") {
              $alternative[$proton]+=10;
            };
        # check bond valence value
            switch ($proton) {
              case 11: $cmin=1.41; $cmax=1.75; break;
              case 19: $cmin=0.58; $cmax=0.72; break;
              case 12: $cmin=3.71; $cmax=4.76; break;
              case 20: $cmin=1.70; $cmax=2.30; break;
              case 25: $cmin=4.77; $cmax=6.01; break;
              case 26: $cmin=5.30; $cmax=6.79; break;
              case 27: $cmin=3.56; $cmax=4.77; break;
              case 28: $cmin=4.68; $cmax=6.24; break;
              case 29: $cmin=3.69; $cmax=6.79; break;
              case 30: $cmin=4.08; $cmax=5.43; break;
              case 80: $cmin=2.54; $cmax=2.92; break;
            }
            $median =($cmax+$cmin)/2.0;
            $range  =$cmax-$cmin;
            $range25=0.25*$range;
            if($val[$mg_i_site][20]>$cmin-$range25 and $val[$mg_i_site][20]<$cmax+$range25) {
              $alternative[$proton]+=10;
              $deviation = ($val[$mg_i_site][20]>$median) ? $val[$mg_i_site][20]-$median : $median-$val[$mg_i_site][20];
              $alternative[$proton]+=(1-$deviation/(0.75*$range));
            }
          }
          asort($alternative);
          $descending_alternative = array_reverse($alternative, TRUE);
          $descending_alternative_keys = array_keys($descending_alternative);
          $val[$mg_i_site][12]="";
          if($descending_alternative_keys[0] != $protons_ion) {
            $first_alt_met=1;
            foreach ($descending_alternative as $akey => $aval) {
             if($aval>=30) {
        if($val[$mg_i_site][12] != "") {$val[$mg_i_site][12].=", ";};
        switch ($akey) {
              case 11: $alt_met="Na"; break;
              case 19: $alt_met="K";  break;
              case 12: $alt_met="Mg"; break;
              case 20: $alt_met="Ca"; break;
              case 25: $alt_met="Mn"; break;
              case 26: $alt_met="Fe"; break;
              case 27: $alt_met="Co"; break;
              case 28: $alt_met="Ni"; break;
              case 29: $alt_met="Cu"; break;
              case 30: $alt_met="Zn"; break;
              case 80: $alt_met="Hg"; break;
        }
              $val[$mg_i_site][12].=$alt_met;
              if($first_alt_met == 1) {
                $bvhandle=fopen($this->file_ion_bondvalence, "r");
                while(($bvbuffer=fgets($bvhandle,4096)) != false) {
                  $one_bv=explode('|',$bvbuffer);
                  list($pdb_txt, $cif_txt, $cif_txt_2) = $this->refmac_record_by_bondvalence($one_bv, $residueid_ion, strtoupper($alt_met), $residue_chainid, $residue_resseq);
                  $refmac_pdb_alt.=$pdb_txt;
                  $refmac_chem_link_alt.=$cif_txt;
                  $refmac_chem_link_bond_alt.=$cif_txt_2;
                }
                fclose($bvhandle);
                $first_alt_met=0;
              }
             }
            }
          }

          if($val[$mg_i_site][12]!="") { array_push($alt_metal_arr, $chainid_colon_resseq); }
          if($exp_method==2) {$val[$mg_i_site][12]="N/A";}

          if($common_metal==0) {
            $t="o";
            if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";};
            $geometry[$protons_ion]=$t;
          }

          if($geometry[$protons_ion]=="a") {		# acceptable
            $bg[$mg_i_site][8]="#AAFFAA";
          } elseif($geometry[$protons_ion]=="b") {		# borderline
            $bg[$mg_i_site][8]="#FFFFAA";
          } else {
            $bg[$mg_i_site][8]="#FFAAAA";
          }

          switch ($val[$mg_i_site][8]) {
            case  0: $val[$mg_i_site][8]="Free"                 ; break;
            case  1: $val[$mg_i_site][8]="Linear"               ; break;
            case  2: $val[$mg_i_site][8]="Trigonal Planar"      ; break;
            case  3: $val[$mg_i_site][8]="Square Planar"        ; break;
            case  4: $val[$mg_i_site][8]="Tetrahedral"          ; break;
            case  5: $val[$mg_i_site][8]="Trigonal Bipyramidal" ; break;
            case  6: $val[$mg_i_site][8]="Octahedral"           ; break;
            case  7: $val[$mg_i_site][8]="Trigonal Biprism"     ; break;
            case  8: $val[$mg_i_site][8]="Trigonal Antiprism"   ; break;
            case  9: $val[$mg_i_site][8]="Capped Trigonal Biprism"; break;
            case 10: $val[$mg_i_site][8]="Pentagonal Bipyramidal" ; break;
            case 11: $val[$mg_i_site][8]="Cubic"                ; break;
            case 12: $val[$mg_i_site][8]="Square Antiprism"     ; break;
            case 13: $val[$mg_i_site][8]="Dodecahedral"         ; break;
            case 14: $val[$mg_i_site][8]="Irregular"            ; break;
            case 15: $val[$mg_i_site][8]="Poorly Coordinated"   ; break;
            case 16: $val[$mg_i_site][8]="Overflow"             ; break;
            default: $val[$mg_i_site][8]="Undefined"            ; break;
          }
          if($val[$mg_i_site][9]  != "N/A") { if($this->is_resource) {$val[$mg_i_site][9].='\u00b0';} else {$val[$mg_i_site][9].='&deg;';} }
          if($val[$mg_i_site][10] != "N/A") { $val[$mg_i_site][10]=(int)$val[$mg_i_site][10].'%'; }

          if($residue_env_comp[$residueid_ion]>=100) {
            if($exotic_ring_msg=="") { $exotic_ring_msg="potential cation-pi interactions observed around"; };
            $exotic_ring_msg.=" $chainid_colon_resseq";
          }
          if($valence_is_problematic) {
            if($residue_env_comp[$residueid_ion]%100>=10 or $residue_multi_metal[$residueid_ion]) {
              if($exotic_met_msg=="") { $exotic_met_msg="the presence of multi-nuclear metal clusters around"; };
              $exotic_met_msg.=" $chainid_colon_resseq";
              /* Turn off the flag after showing once to avoid same residue showing multiple times */
              if($residue_multi_metal[$residueid_ion]) {$residue_multi_metal[$residueid_ion]=0;}
            }
            if($residue_env_comp[$residueid_ion]%10>=1) {
              if($exotic_lig_msg=="") { $exotic_lig_msg="the presence of small molecules in the coordinate sphere of the metal ion"; };
              $exotic_lig_msg.=" $chainid_colon_resseq";
            }
          }
          $site_id++;
        }
        fclose($handle);

        $this->set('bg',$bg);
        $this->set('val',$val);
        $this->set('alt_metal_arr',$alt_metal_arr );
        $this->set('number_binding_sites',$number_binding_sites );
        $this->set('rare_metal_detected',$rare_metal_detected );
        $this->set('exotic_ring_msg',$exotic_ring_msg );
        $this->set('exotic_met_msg',$exotic_met_msg );
        $this->set('exotic_lig_msg',$exotic_lig_msg );
        $this->set('exp_method',$exp_method );
        $this->set('space_group_number',$space_group_number );
        $this->set('mg_sites',$mg_sites);
        $this->set('partial_occupancy_symop',$partial_occupancy_symop);

      } //end else from org listsite 933
  }


  function calcsite(){
    $this->viewBuilder()->setLayout('cmm');
    if($this->is_resource) {$this->set('is_resource',1);} else {$this->set('is_resource',0);}

    if($this->request->is('post')){
      $data = $this->request->getData();
      $this->set('data', $data);
    }

    $this->set('res_dep', 0);
    $res_dep=0;
    $this->set('is_pdb_format', 0);
    $ip=$this->get_client_ip_server();

    //TODO make this work
    // $usage_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename!='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
    // $this->set('usage_arr', $usage_arr);
    // $usage0_arr = $this->MetalSite->query("select distinct sessionid,numofbindingsites from usages a left join pdbfiles b on a.pdbfileid=b.pdbfileid where cast(ip as text) like '$ip/%' and a.filename='' and to_char(creation_date,'YYYY-MM-DD')=to_char(current_date,'YYYY-MM-DD')");
    // $this->set('usage0_arr', $usage0_arr);

    if (!empty($data['pdbfile']->getClientFilename())) {
      //TODO finish sql
      $usage_arr=[1];
      // $pdbfileid_arr = $this->MetalSite->query("select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");
      #debug ("pdbfileid_arr = select distinct a.pdbfileid,a.filename from pdbfiles a left join (select distinct sessionid, pdbfileid from usages) b on a.pdbfileid=b.pdbfileid where sessionid like '$pdbid%'");

        if(substr($ip, 0, 4) !== "10.1" && count($usage_arr)>=100) { //if it was tried to look for record that is no in database too many times
          $this->set('pdbfile_valid',-1);
          $this->set('pdbfile_name',$ip);
        } else {
          $pdbfileid=$this->get_pdbfileid();
          $pdbfile=$data['pdbfile']->getClientFilename();
          $tmpname=$data['pdbfile']->getStream()->getMetadata('uri');

          $session=substr($tmpname,-6);
          $session.="_$pdbfileid";
          list($retval,$errmsg)=$this->calculate_session($session,$tmpname,$pdbfileid);

          if(!$retval) {
            if(substr($pdbfile,-3) === "pdb" or substr($pdbfile,-3) === "ent") {
              $this->set_valid_session($session,"XXXX.pdb",0);
              $filename=$GLOBALS["neighborhood_temp"]."/$session/XXXX.pdb";
              $this->set('is_pdb_format', 1);
            }else {
              $this->set_valid_session($session,"XXXX.cif",0);
              $filename=$GLOBALS["neighborhood_temp"]."/$session/XXXX.cif";
            }
            //TODO make it work
            // $this->update_database_usage($session,1,0,0,$pdbfileid,$filename);
          } else {
            $this->set('pdbfile_valid',0);
            //TODO riddle this
            debug("fix this");exit;
            $this->set('pdbfile_name',$this->data['MetalSite']['pdbfile']['name'].":".$errmsg);
          }
        }
    }else {
        echo "No input data received!";
    }
    $this->set('plot_data_json',$this->plot_data_json);

    //end of Hepings code


    //michal mod
    //2fo-fc
    $densfile_2fo=$data['densityfile_2fo']->getClientFilename();
    if(empty($densfile_2fo)==1 or (substr($densfile_2fo,-5)!=='.dsn6' and substr($densfile_2fo,-4)!=='.map')) {
      //do nothing
      $this->set('densfile_2fo',-1);
    } else {
      //but if this was uploaded:
      if(substr($densfile_2fo,-5)=='.dsn6') {$mg_2fo_fotmat='.dsn6';} else {$mg_2fo_fotmat='.map';}
      $densfile_2fo_tmp = $data['densityfile_2fo']->getStream()->getMetadata('uri');
      copy($densfile_2fo_tmp,$GLOBALS["neighborhood_temp"]."/".$session."/XXXX_2fo".$mg_2fo_fotmat);
      $this->set('densfile_2fo',$GLOBALS["neighborhood_temp"]."/".$session."/XXXX_2fo".$mg_2fo_fotmat);
    }
    //fo-fc
    $densfile_fo=$data['densityfile_fo']->getClientFilename();
    if(empty($densfile_fo)==1 or (substr($densfile_fo,-5)!=='.dsn6' and substr($densfile_fo,-4)!=='.map')){
      //do nothing
      $this->set('densfile_fo',-1);
    } else {
      //but if this was uploaded:
      $this->set('michal_test', $session);
      if(substr($densfile_fo,-5)=='.dsn6') {$mg_fo_fotmat='.dsn6';} else {$mg_fo_fotmat='.map';}
      $densfile_fo_tmp = $data['densityfile_fo']->getStream()->getMetadata('uri');
      copy($densfile_fo_tmp,$GLOBALS["neighborhood_temp"]."/".$session."/XXXX_fo".$mg_fo_fotmat);
      $this->set('densfile_fo',$GLOBALS["neighborhood_temp"]."/".$session."/XXXX_fo".$mg_fo_fotmat);
    }

    //michal mod end




    //Michal Controller
    $this->michal_controller($res_dep);



  }

  function get_pdbfileid() {
  $clusterfile=$GLOBALS["neighborhood_temp"]."/XXXX.cluster";
  touch($clusterfile);
  $pdbfileid=0;
  $fd = fopen($clusterfile, "r") or exit("Unable to open file $clusterfile!");
  while(!feof($fd)) {
    $clusterline=fgets($fd);
    if (preg_match("/^PDBFILE\s+(\d+)$/", $clusterline, $matches)) {
      $pdbfileid=$matches[1];
      $pdbfileid++;
    }
  }
  fclose($fd);
  return $pdbfileid;
  }

  function fetch_pdbfile($pdbid) {
  $neighborhood_session=$GLOBALS["neighborhood_temp"]."/$pdbid";
  if (!is_dir($neighborhood_session)) { mkdir($neighborhood_session, 0777); }
  chmod($neighborhood_session, 0777);

  $element="pdb$pdbid.ent";
  $subDir=substr($element, 4, 2);
  $elename=$neighborhood_session."/$element";
  $source="ftp://ftp.wwpdb.org/pub/pdb/data/structures/divided/pdb/$subDir/$element.gz";
  $last_line = system("wget -q --passive-ftp --waitretry=10 -N -P $neighborhood_session $source &> $neighborhood_session/XXXX.log",$retval);
  $last_line = system("gunzip $elename.gz &> $neighborhood_session/XXXX.log",$retval);
  if (file_exists($elename)) {
    return array($elename,$element);
  } else {
    return array("","");
  }
}


  function model_pdb($path_r, $modeled_sites){
    $n_sites=count($modeled_sites['info']);
    //for pdb/ent
    $ext=substr($path_r, -3);
    if($ext=='pdb' or $ext=='ent'){
      $path_w=explode('/',$path_r)[0].'/'.explode('/',$path_r)[1].'/YYYY.'.$ext;

      $handle_r=fopen($path_r, "r");
      $handle_w=fopen($path_w,'w');
      $i_site=0;
      //skipiing 0
      if($modeled_sites['info'][$i_site]=='0'){
        while($modeled_sites['info'][$i_site]=='0'){
          $i_site+=1;
        }
      }

      while(($buffer=fgets($handle_r,4096)) != false) {

        if(substr($buffer,0,6)=="HETATM"){
          $components=preg_split("/[\s]+/", $buffer);
          $residue_number=explode(':',$modeled_sites['info'][$i_site])[1];
          $chain=explode(':',$modeled_sites['info'][$i_site])[0];
          $metal=strtoupper($modeled_sites['selected'][$i_site]);
          if($components[5]==$residue_number and $components[4]==$chain ) {

            if($metal=="K"){
              $line=sprintf("%-6s%5d %4s%4s%2s%4d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n", $components[0],$components[1],$metal,
                                                                                $metal,$components[4],$components[5],
                                                                                $components[6],$components[7],$components[8],
                                                                              $components[9],$components[10],$metal);
            } else{
              $line=sprintf("%-6s%5d %-4s%4s%2s%4d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n", $components[0],$components[1],$metal,
                                                                                $metal,$components[4],$components[5],
                                                                                $components[6],$components[7],$components[8],
                                                                              $components[9],$components[10],$metal);
            }

            fwrite($handle_w, $line);
            if($i_site<count($modeled_sites['info'])-1) {
              $i_site+=1;
              if($modeled_sites['info'][$i_site]=='0'){
                while($modeled_sites['info'][$i_site]!='0'){
                  $i_site+=1;
                }
                if($i_site==count($modeled_sites['info'])-1){
                  $i_site-=1;
                }
              }
            }

          } else {
            fwrite($handle_w, $buffer);
          }


        } else {
          fwrite($handle_w, $buffer);
        }
      }
      fclose($handle_r);
      fclose($handle_w);
    }
    unlink($path_r);
    rename($path_w, $path_r);
  }

  function calculate_session($session,$tmpname,$pdbfileid,$modeled_sites='') {

    $neighborhood_session=$GLOBALS["neighborhood_temp"]."/$session";
    $clusterfile=$GLOBALS["neighborhood_temp"]."/XXXX.cluster";
    $logfile=$GLOBALS["neighborhood_temp"]."/XXXX.log";
    $errfile=$neighborhood_session."/XXXX.log";
    #quick hack CIF files must contain _atom_site - algorithm will not work anyway without it
    $last_line = system("grep _atom_site $tmpname  | wc -l ",$retval);
    $ext="cif";
    if ($last_line == 0) $ext="pdb";
    if(strlen($session)>=8) {
      mkdir($neighborhood_session, 0777);
      chmod($neighborhood_session, 0777);
      copy($tmpname,$neighborhood_session."/XXXX.$ext");
      //copy($tmpname,$neighborhood_session."/XXXX.pdb");
      $pdbfile="XXXX.$ext";
    } else {
      $pdbfile=$tmpname;
    }

    #debug ("pdbfile  is $pdbfile in calculate_session");
    $fd = fopen($clusterfile, "w") or exit("Unable to open file $clusterfile!");
    fwrite($fd, "PDBFILE   ");
    $this->format_six_digit($pdbfileid,$fd);
    fclose($fd);
    copy($clusterfile,$neighborhood_session."/XXXX.cluster");

    //if from MetalSite then modificate
    if($modeled_sites!=''){
      $this->model_pdb($neighborhood_session."/XXXX.$ext",$modeled_sites);
      //fetching densfiles
      if($modeled_sites['densfile_2fo']!='-1'){
        $densfile_2fo_name=explode('/',$modeled_sites['densfile_2fo']);
        $densfile_2fo_name=end($densfile_2fo_name);
        copy($modeled_sites['densfile_2fo'],$neighborhood_session.'/'.$densfile_2fo_name);
        $this->set('densfile_2fo',$neighborhood_session.'/'.$densfile_2fo_name);
      } else {$this->set('densfile_2fo','-1');}
      if($modeled_sites['densfile_fo']!='-1'){
        $densfile_fo_name=explode('/',$modeled_sites['densfile_fo']);
        $densfile_fo_name=end($densfile_fo_name);
        copy($modeled_sites['densfile_fo'],$neighborhood_session.'/'.$densfile_fo_name);
        $this->set('densfile_fo',$neighborhood_session.'/'.$densfile_fo_name);
      }else {$this->set('densfile_fo','-1');}
    }

    $neighborhood_path="./neighborhood/neighborhood_0.6.0_cif";
    system("echo $neighborhood_path/neighborhood_contact.sh $neighborhood_path/neighborhood_contact.pl $session $pdbfile $errfile > /tmp/XXXX.log");
    $last_line = system("$neighborhood_path/neighborhood_contact.sh $neighborhood_path/neighborhood_contact.pl $session $pdbfile $errfile",$retval);
    $sqlcopy=$neighborhood_session."/copyNeighborhoodData.sql";
    $errmsg='';
    if(file_exists($sqlcopy)) {
      //TODO add this functionality
      // system("psql -Usg_display -h metal2011 metal2011< $sqlcopy >> $logfile",$retval2);
    } else {
      $fd = fopen($errfile, "r") or exit("Unable to open file $errfile!");
      while(!feof($fd)) {
        $errline=fgets($fd);
        if (preg_match("/^neighborhood error:\s*(.+)\s*$/", $errline, $errstring)) {
          $errmsg=$errstring[1];
        }
      }
      fclose($fd);
      if($errmsg=='') {
        $errmsg="Unspecified error encountered";
      }
    }
    return array($retval,$errmsg);
  }

  function format_six_digit($figure, $fd) {
    $numlen = strlen($figure);
    for ($i=$numlen;$i<6;$i++) {fwrite($fd, " ");}
    fwrite($fd, $figure);
    fwrite($fd, "\n");
  }

  function newmodel(){
    //TODO end this
  }

  //NOTE only works for listsite
  function fetch_electron($pdbid){
    $neighborhood_session=$GLOBALS["neighborhood_temp"]."/$pdbid";
    //fofc
    $source="https://edmaps.rcsb.org/maps/".$pdbid."_fofc.dsn6";
    $last_line = system("wget --passive-ftp --waitretry=10 -N -P $neighborhood_session $source 2> $neighborhood_session/fofc.log",$retval);
    if($retval!='0'){
      $this->set('densfile_fo',-1);
    } else {
      $this->set('densfile_fo',$neighborhood_session.'/'.$pdbid.'_fofc.dsn6');
    }

    //2fofc
    $source="https://edmaps.rcsb.org/maps/".$pdbid."_2fofc.dsn6";
    $last_line = system("wget --passive-ftp --waitretry=10 -N -P $neighborhood_session $source 2> $neighborhood_session/2fofc.log",$retval);
    if($retval!='0'){
      $this->set('densfile_2fo',-1);
    } else {
      $this->set('densfile_2fo',$neighborhood_session.'/'.$pdbid.'_2fofc.dsn6');
    }

  }

  function example_button($pdbid,$form,$numbs) {
      $lower_pdbid=strtolower($pdbid);
      $upper_pdbid=strtoupper($pdbid);
      if(strlen($pdbid)>=8) {$upper_pdbid="Upload";};
      echo "<td>".$form->create('MetalSite', array('action' => 'listsite'));
      echo '<input type="hidden" name="pdbid" value="'.$pdbid.'">';
      echo '<input type="hidden" name="example" value="2">';
      echo $form->end(array('name' => 'submitbtn', 'label' => "$upper_pdbid:$numbs"))."</td>";
  }

  function jmol_button_script($label, $script) {
    echo "<input type=\"button\" value=\"$label\" onclick=\"";
    echo "javascript:Jmol.script(jmolApplet0,'$script')";
    echo "\">";
  }

  function jmol_label_script($label, $script) {
    echo "<a href=\"javascript:Jmol.script(jmolApplet0,'$script')\">$label</a>";
  }

  function warning_message($msg) {
      return "<tr><td style=\"padding:1px\" colspan=9><table width=\"100%\"><tr><td style=\"padding:1px\" bgcolor=#FFAAAA><b><center> Warning: $msg</center></b></td></tr></table></td></tr>";
  }

  function get_distance($ion, $lig_elem, $lig_atom, $lig_res) {
  # d stores the dictionary values for elements,
  # ea stores the exceptions for certain atoms,
  # er stores the exceptions for certain residues
    $d['NA']['O']=2.41; $d['NA']['N']=2.54; $d['NA']['S']=2.89; $ea['NA']['N']['N']=-1;$er['NA']['N']['ARG']=-1;$er['NA']['N']['LYS']=-1;
    $d['MG']['O']=2.08; $d['MG']['N']=2.19; $d['MG']['S']=2.61; $ea['MG']['N']['N']=-1;$er['MG']['N']['ARG']=-1;$er['MG']['N']['LYS']=-1;
    $d['K']['O'] =2.73; $d['K']['N'] =2.88; $d['K']['S'] =3.28; $ea['K']['N']['N']=-1; $er['K']['N']['ARG']=-1; $er['K']['N']['LYS']=-1;
    $d['CA']['O']=2.34; $d['CA']['N']=2.48; $d['CA']['S']=2.83; $ea['CA']['N']['N']=-1;$er['CA']['N']['ARG']=-1;$er['CA']['N']['LYS']=-1;
    $d['MN']['O']=2.15; $d['MN']['N']=2.20;
    $d['FE']['O']=2.11; $d['FE']['N']=2.17; $d['FE']['S']=2.34;
    $d['CO']['O']=2.09; $d['CO']['N']=2.07;
    $d['NI']['O']=2.07; $d['NI']['N']=1.99; $d['NI']['S']=2.24;
    $d['CU']['O']=2.10; $d['CU']['N']=2.02; $d['CU']['S']=2.34;
    $d['ZN']['O']=2.15; $d['ZN']['N']=2.10; $d['ZN']['S']=2.35;
    if(isset($ea[$ion][$lig_elem][$lig_atom])) {
      $dist=$ea[$ion][$lig_elem][$lig_atom];
    } else if(isset($er[$ion][$lig_elem][$lig_res])) {
      $dist=$er[$ion][$lig_elem][$lig_res];
    } else if(isset($d[$ion][$lig_elem])) {
      $dist=$d[$ion][$lig_elem];
    } else {
      $dist=-1.0;
    }
    return $dist;
  }



  function refmac_record_by_bondvalence($one_bv, $metal_id, $metal_name, $residue_chainid, $residue_resseq) {
    global $dict_linkid;
    $pdb_txt="";
    $cif_txt="";
    $cif_txt_2="";
    if($one_bv[23] > 0.05) {
      $iid   = $one_bv[5];
      if($iid == $metal_id) {
        $iatms = trim($one_bv[12],"-");
        if($metal_name == $iatms) {
          $ires  = preg_replace('/_/',' ',$one_bv[7]);
          $iatm  = preg_replace('/-/',' ',$one_bv[12]);
        } else {
          $iatms = $metal_name;
          $ires  = str_pad($metal_name, 3, ' ', STR_PAD_LEFT);
          $iatm  = str_pad($metal_name, 4, ' ', STR_PAD_RIGHT);
        }
        $lid   = $one_bv[4];
        $lres  = preg_replace('/_/',' ',$one_bv[6]);
        $latm  = preg_replace('/-/',' ',$one_bv[11]);
        $latms = trim($one_bv[11],"-");
        $lelem = substr($latms,0,1);
        $linkid= $iatms."-".$lres;
        if($lres!='HOH') {$linkid .= $latms;};
        if(isset($dict_linkid[$linkid])) {
          $linkid_exist = 1;
        } else {
          $linkid_exist = 0;
          $dict_linkid[$linkid]=1;
        }
        $distance=$this->get_distance($iatms,$lelem,$latms,$lres);
        if($distance>1 and ($lelem == 'O' or $lelem == 'N' or $lelem == 'S')) {
          $pdb_txt.="LINK        ".$iatm." ".$ires." ".$residue_chainid[$iid].str_pad($residue_resseq[$iid],4,' ',STR_PAD_LEFT);
          $pdb_txt.="                ".$latm." ".$lres." ".$residue_chainid[$lid].str_pad($residue_resseq[$lid],4,' ',STR_PAD_LEFT);
  #       $pdb_txt.="                ".$linkid."\\n";
          $pdb_txt.="                ".$linkid."\n";

          if(!$linkid_exist) {
  #         $cif_txt.=str_pad($linkid,10,' ',STR_PAD_RIGHT)."$ires       .        .        $lres      .        .  bond_".trim($ires)."-$iatms=_$lres-$latms\\n";
  #         $cif_txt_2.=" data_link_$linkid\\n #\\n loop_\\n _chem_link_bond.link_id\\n _chem_link_bond.atom_1_comp_id\\n _chem_link_bond.atom_id_1\\n _chem_link_bond.atom_2_comp_id\\n _chem_link_bond.atom_id_2\\n _chem_link_bond.type\\n _chem_link_bond.value_dist\\n _chem_link_bond.value_dist_esd\\n ";
  #         $cif_txt_2.=str_pad($linkid,10,' ',STR_PAD_RIGHT)."1 $iatm      2 $latm         .           $distance    0.020\\n";
            $cif_txt.=str_pad($linkid,10,' ',STR_PAD_RIGHT)."$ires       .        .        $lres      .        .  bond_".trim($ires)."-$iatms=_$lres-$latms\n ";
            $cif_txt_2.="\ndata_link_$linkid\n #\n loop_\n _chem_link_bond.link_id\n _chem_link_bond.atom_1_comp_id\n _chem_link_bond.atom_id_1\n _chem_link_bond.atom_2_comp_id\n _chem_link_bond.atom_id_2\n _chem_link_bond.type\n _chem_link_bond.value_dist\n _chem_link_bond.value_dist_esd\n ";
            $cif_txt_2.=str_pad($linkid,10,' ',STR_PAD_RIGHT)."1 $iatm      2 $latm         .           $distance    0.020\n";
          }
        }
      }
    }
    return array($pdb_txt, $cif_txt, $cif_txt_2);
  }




  function listsiteRefmac() {
    $this->is_resource=1;
    $this->viewBuilder()->setLayout('empty');
    header('Content-Type: text/csv');
    $this->set('resource_format', "refmac");
    $this->listsite();
  }



  function nopdb(){
    $this->viewBuilder()->setLayout('cmm');
    $this->set('pdbid',$this->request->getParam('pass')[0]);
  }


  function record_ip($tablename) {
    //$ip=$_SERVER['REMOTE_ADDR'];
    $ip = $this->get_client_ip_server();
    if(! $this->is_heping($ip)) {
      //TODO right now I dont want to mess with database so in future make usefull lines below
      // $browser_id=$this->update_identities_browsers($ip);
      // $this->insert_sqlcommand("record_ip.sql","INSERT INTO $tablename (ip,browser_id) VALUES ('$ip',$browser_id)");
    }
  }

  function is_tutorial($sessionid) {
#                       1wx4_validated                1v8y_validated
#                       3lrk_validated                3lkm_validated
  if($sessionid == "MJ8Lgc_424" or $sessionid == "0iyxpx_428" or
     $sessionid == "gLTnBI_571" or $sessionid == "vHPXkB_570" or
     $sessionid == "rQvzrr_426" or $sessionid == "3wCHji_427") {
#                     1qy6_validated                2z08_validated
    return 1;
  } else {
    return 0;
  }
}


  function is_heping($ip) {
    if($ip == "172.26.11.206" or $ip == "128.143.16.85" or $ip == "128.143.61.215" or $ip == "128.143.16.143" or $ip == "128.143.44.221") {
      return 1;
    } else {
      return 0;
    }
  }

    // Function to get the client ip address
   function get_client_ip_server() {
      $ipaddress = '';
      //Heping:
      // if ($_SERVER['HTTP_CLIENT_IP'])
      //       $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
      // else if($_SERVER['HTTP_X_FORWARDED_FOR'])
      //       $ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
      // else if($_SERVER['HTTP_X_FORWARDED'])
      //       $ipaddress = $_SERVER['HTTP_X_FORWARDED'];
      // else if($_SERVER['HTTP_FORWARDED_FOR'])
      //       $ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
      // else if($_SERVER['HTTP_FORWARDED'])
      //       $ipaddress = $_SERVER['HTTP_FORWARDED'];
      // else

      //Michal
      //Above dont works only below is needed
      if($_SERVER['REMOTE_ADDR'])
            $ipaddress = $_SERVER['REMOTE_ADDR'];
      else $ipaddress = 'UNKNOWN';
      return $ipaddress;
    }



    function set_valid_session($session,$pdbfile,$example,$modelsite='') {
      $server_neighborhood_session=$GLOBALS["server_neighborhood_temp"]."/$session";
      $neighborhood_session=$GLOBALS["neighborhood_temp"]."/$session";
      $neighborhood_temp=$GLOBALS["neighborhood_temp"];
      //TODO there is no such thing
      system("cp $neighborhood_temp/index.html $neighborhood_session/index.html");
      $this->set('pdbfile_valid',1);
      $this->pdbfile_valid=1;
      //if from modelsite
      if($modelsite!=''){
        $mg_temp=explode('/',$this->request->getData()['mg_pdb_path']);
        $this->set('pdbfile_name',end($mg_temp));
      }
      elseif(strlen($session)>=8 && $example!=2) {
        $this->set('pdbfile_name',$this->request->getData()['pdbfile']->getClientFilename());
      } else {
        $this->set('pdbfile_name',$pdbfile);
      }
      $plot_file=$neighborhood_session."/PLOT.data";

      if(!file_exists($plot_file) or $this->is_resource) {
        $this->generate_plot_file($session,$plot_file,$neighborhood_session."/ION_BONDVALENCE.data");
      }
      $this->set('dir_server_session',$server_neighborhood_session);
      $this->set('file_plots',$plot_file);
      $this->set('file_pdbfiles',$neighborhood_session."/PDBFILE.data");
      $this->file_pdbfiles=$neighborhood_session."/PDBFILE.data";
      $this->set('file_residues',$neighborhood_session."/RESIDUE.data");
      $this->file_residues=$neighborhood_session."/RESIDUE.data";
      $this->set('file_neighbors',$neighborhood_session."/NEIGHBOR.data");
      $this->file_neighbors=$neighborhood_session."/NEIGHBOR.data";
      $this->set('file_ion_bondvalence',$neighborhood_session."/ION_BONDVALENCE.data");
      $this->file_ion_bondvalence=$neighborhood_session."/ION_BONDVALENCE.data";
      $this->set('file_ion_bindingsite',$neighborhood_session."/ION_BINDINGSITE.data");
      $this->file_ion_bindingsite=$neighborhood_session."/ION_BINDINGSITE.data";
      $this->set('file_output_html',$neighborhood_session."/CMM_output.html");
      $this->set('file_output_pdf',$neighborhood_session."/CMM_output.pdf");
      $this->set('file_input_pdb',$neighborhood_session."/$pdbfile");
      $this->set('file_output_pdb',$neighborhood_session."/${session}_CMM.pdb");
      $this->set('server_file_output_pdb',$server_neighborhood_session."/${session}_CMM.pdb");
      $this->set('file_pdbfile_upload',$server_neighborhood_session."/$pdbfile");
      if (file_exists($neighborhood_session."/contact.pdb")) {
        $this->set('file_contact_upload',$server_neighborhood_session."/contact.pdb");
        $this->file_contact_upload=$server_neighborhood_session."/contact.pdb";
      } else {
        $this->set('file_contact_upload','0');
        $this->file_contact_upload=0;
      }
      if (file_exists($neighborhood_session."/model.pdb")) {
        $this->set('file_model_upload',$server_neighborhood_session."/model.pdb");
      } else {
        $this->set('file_model_upload','0');
      }
    }


    function generate_plot_file($session,$plot_file,$data_file) {
      $distance_arr=array();
      $count_arr=array();
      $handle=fopen($data_file, "r");
      while(($buffer=fgets($handle,4096)) !== false) {
        $one_record=explode('|',$buffer);
        $metal_name=$one_record[12];
        $ligand_protons=$one_record[14];
        $metal_protons=$one_record[15];
        $distance=$one_record[18];
        $bondvalence=$one_record[23];
        $plotstem='';
        if($ligand_protons == 8 && ($metal_protons==11 || $metal_protons==12 || $metal_protons==19 || $metal_protons==20)) {
          if ($metal_protons==19) { $plotstem="K---O"; }
          else { $plotstem=$metal_name."O"; }
        } elseif(($ligand_protons == 7 || $ligand_protons == 8 || $ligand_protons == 16) && $metal_protons>=25 && $metal_protons<=30) {
          switch($ligand_protons) {
            case 7:  $plotstem=$metal_name."N"; break;
            case 8:  $plotstem=$metal_name."O"; break;
            case 16: $plotstem=$metal_name."S"; break;
            default: $plotstem=''; break;
          }
        }
        if($distance<=1.0) { $distance=1.0; }
        if($plotstem!='' && $bondvalence>=0.08 && $distance<3.5) {
          if(!isset($count_arr[$plotstem])) {
            $count_arr[$plotstem]=0;
          }
          $distance_arr[$plotstem][$count_arr[$plotstem]] = $distance;
          $count_arr[$plotstem]++;
        }
      }
      fclose($handle);

      $plot_arr=array('NA--O','MG--O','K---O','CA--O','MN--O','MN--N','MN--S','FE--O','FE--N','FE--S','CO--O','CO--N','CO--S','NI--O','NI--N','NI--S','CU--O','CU--N','CU--S','ZN--O','ZN--N','ZN--S');
      $fd = fopen($plot_file, "w") or exit("Unable to open file $plot_file!");
    $first_plot=1;
      foreach ($plot_arr as $plotstem) {
        //both false
        if(isset($count_arr[$plotstem]) && $count_arr[$plotstem]>=1) {
          $instance_arr=array();
          for ($i=10;$i<=34;$i++) {
            $instance_arr[$i]=0;
          }
          for ($i=0;$i<$count_arr[$plotstem];$i++) {
            $bin=floor($distance_arr[$plotstem][$i]*10);
            $instance_arr[$bin]++;
          }
          $inline_data='';
          $inline_max=0;
    if($first_plot) {$first_plot=0;} else {$this->plot_data_json.="    },\n\n    {\n";};
    $this->plot_data_json.="      \"plot_name\": \"".$plotstem."\",\n";
    $this->plot_data_json.="      \"pdb_data\": [\n";
    $first_pdb=1;
          for ($i=10;$i<=34;$i++) {
            if($instance_arr[$i]) {
              $distance=$i/10.0;
              $count=$instance_arr[$i];
    if($first_pdb) {$first_pdb=0;} else {$this->plot_data_json.=",\n";};
    $this->plot_data_json.="        {\n          \"distance\": $distance,\n          \"count\": $count\n        }";
              $inline_data.="$distance\t$count\n";
              if($count>$inline_max) { $inline_max=$count; }
            }
          }
    $this->plot_data_json.="\n      ],\n      \"csd_data\": [\n";
          $this->generate_plot_png($session,$plotstem,$inline_data,$inline_max);
    $this->plot_data_json.="\n      ]\n";

          fwrite($fd, "$plotstem\n");
        }
      }
      fclose($fd);
    }

    function generate_plot_png($session,$plotstem,$inline_data,$inline_max) {
      $csddata_file = $GLOBALS["neighborhood_temp"]."/csd_metal_distances/$plotstem.csv";
      $neighborhood_session=$GLOBALS["neighborhood_temp"]."/$session";
      $gnuplot_file = $neighborhood_session."/$plotstem.gnuplot";
      $pngplot_file = $neighborhood_session."/$plotstem.png";


      $csd_max=0;
      $fcsd=fopen($csddata_file, "r");
$first_csd=1;
      while(($buffer=fgets($fcsd,4096)) !== false) {
        list($distance,$count_str)=explode("\t",$buffer);
        $count_int=(int)$count_str;
        if($count_int>$csd_max) { $csd_max = $count_int; }
if($first_csd) {$first_csd=0;} else {$this->plot_data_json.=",\n";};
$this->plot_data_json.="        {\n          \"distance\": $distance,\n          \"count\": $count_str        }";
      }
      fclose($fcsd);

      $fgnuplot = fopen($gnuplot_file, "w") or exit("Unable to open file $gnuplot_file!");
      fwrite($fgnuplot, 'set encoding iso_8859_1'."\n");
     #fwrite($fgnuplot, 'set terminal png xcbcbcb x000000 enhanced size 340, 160 font "Arial,10"'."\n");
      fwrite($fgnuplot, 'set terminal pngcairo transparent enhanced size 340, 160 font "Arial Bold,10"'."\n");
      fwrite($fgnuplot, 'set output "'.$pngplot_file.'"'."\n");
      fwrite($fgnuplot, 'set lmargin at screen 0.00'."\n".'set bmargin at screen 0.08'."\n".'set rmargin at screen 0.995'."\n".'set tmargin at screen 1.00'."\n");
      fwrite($fgnuplot, 'set xrange [1.5:3.3]'."\n");
      fwrite($fgnuplot, 'set format x "%3.1f"'."\n");
      fwrite($fgnuplot, 'set xtics 1.6,0.4,3.2'."\n");
      fwrite($fgnuplot, 'set xtics offset 0,graph 0.065'."\n");
      $inline_increment=ceil($inline_max/5.0);
      $yrange=$csd_max*1.2;
      fwrite($fgnuplot, 'set yrange [0:'.$yrange.']'."\nunset ytics\n");
      $y2range=$inline_max+$inline_increment;
      fwrite($fgnuplot, 'set y2range [0:'.$y2range.']'."\n");
      fwrite($fgnuplot, "set y2tics $inline_increment,$inline_increment,$inline_max\n");
      fwrite($fgnuplot, 'set y2tics offset -49,graph 0.00'."\n");
      fwrite($fgnuplot, 'set y2tics mirror'."\n");
      fwrite($fgnuplot, 'set view 80,45'."\n".'set key top right'."\n".'set boxwidth 0.06'."\n".'set style fill solid 1.0'."\n");
      $title="user";
      if(strlen($session)==4) { $title = $session; }
      fwrite($fgnuplot, 'set xlabel "'.$plotstem.' \n distance (\305)" offset 17,4.4'."\n");
      fwrite($fgnuplot, 'set y2label "# of '.$plotstem.' interactions ('.$title.')" offset -40,4 rotate by 0'."\n");
      fwrite($fgnuplot, 'plot "-" using ($1+0.05):2 with boxes lc rgb "#801010" axis x1y2 title "'.$title.'", \\'."\n");
      fwrite($fgnuplot, '     "'.$csddata_file.'" using ($1+0.025):2 with linespoints linewidth 2 pointtype 7 pointsize 0.2 lc rgb "#074a7e" title "CSD^{5}" axis x1y1'."\n");
      fwrite($fgnuplot, $inline_data);
      fwrite($fgnuplot, 'e'."\n");
      fclose($fgnuplot);

      system("/usr/bin/gnuplot < $gnuplot_file > /dev/null",$retval);
      return $retval;
    }


    function michal_controller($res_dep){
      $alt_metal_arr=array();

      $pdburl="http://www.pdb.org/pdb/explore/explore.do?structureId=";
      if($this->pdbfile_valid){

        $handle=fopen($this->file_pdbfiles, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_pdbfile=explode('|',$buffer);
          $space_group_number=$one_pdbfile[15];
          $resolution=$one_pdbfile[16];
          $this->set('resolution',$resolution);
          $deposition_date=$one_pdbfile[17];
          $exp_method=$one_pdbfile[18];
          $title=$one_pdbfile[20];
          $this->set('title',$title);
          $pdblink=$pdburl.$one_pdbfile[2];
          $this->set('pdblink',$pdblink);
          $numbindingsites=$one_pdbfile[13];
          // debug($numbindingsites);exit;
        }
        fclose($handle);


        $handle=fopen($this->file_residues, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_residue=explode('|',$buffer);
          $residue_chainid[$one_residue[1]]=$one_residue[4];
          $residue_resseq[$one_residue[1]]=$one_residue[5];
          $residue_metal_atomid[$one_residue[1]]=-1;
          $residue_multi_metal[$one_residue[1]]=0; /* number of metal ions in the residue, if more than one, a metal-cluster warning will be issued */
          $residue_env_comp[$one_residue[1]]=0;
        /* Within 4A radius, each small molecule residue increase this by 1,
                         each additional multinuclear metal by 10,
                         each Tyr/Phe/Trp carbon in ring by 100 */
          $residue_HIS_allowance[$one_residue[1]]=0;
          $residue_N1_allowance[$one_residue[1]]=0;
          $residue_N3_allowance[$one_residue[1]]=0;
          $residue_N7_allowance[$one_residue[1]]=0;
        }
        fclose($handle);


        $handle=fopen($this->file_neighbors, "r");
        while(($buffer=fgets($handle,4096)) != false) {
          $one_neighbor=explode('|',$buffer);
          if($one_neighbor[6] % 100 >= 44) {
            $resid_a    = $one_neighbor[2];               $resid_b    = $one_neighbor[3];
            $restype_a  = floor($one_neighbor[6]  / 100); $restype_b  = $one_neighbor[6]  % 100;
            $atomtype_a = floor($one_neighbor[11] / 100); $atomtype_b = $one_neighbor[11] % 100;
            $distance   = $one_neighbor[15];
            if($restype_a>=35 and $restype_a<=40) {
              if($atomtype_a==12 and $atomtype_b==40) {
                $residue_env_comp[$resid_b] += 100;
              };
            } elseif($restype_a>=44) {
              if($atomtype_a==36 or $atomtype_a==37 or $atomtype_a==40) {
                if($distance>=0.5) { $residue_env_comp[$resid_b] += 10; };
              } elseif($atomtype_a>=29 and $atomtype_a<=33) {
                if($distance<=3.5) { $residue_env_comp[$resid_b] ++; };
              }
              if($atomtype_b==36 or $atomtype_b==37 or $atomtype_b==40) {
                if($distance>=0.5) { $residue_env_comp[$resid_a] += 10; };
              } elseif($atomtype_b>=29 and $atomtype_b<=33) {
                if($distance<=0.5) { $residue_env_comp[$resid_a] ++; };
              }
            }
          }
        }
        fclose($handle);

        $handle=fopen($this->file_ion_bondvalence, "r");
        $refmac_pdb="";
        $refmac_chem_link="";
        $refmac_chem_link_bond="";
        $linkid_exist = 0;
        while(($buffer=fgets($handle,4096)) != false) {
          $one_bv=explode('|',$buffer);
          list($pdb_txt, $cif_txt, $cif_txt_2) = $this->refmac_record_by_bondvalence($one_bv, $one_bv[5], trim($one_bv[12],"-"), $residue_chainid, $residue_resseq);
          $refmac_pdb.=$pdb_txt;
          $refmac_chem_link.=$cif_txt;
          $refmac_chem_link_bond.=$cif_txt_2;
          if($one_bv[12]=='MG--' || $one_bv[12]=='-K--' || $one_bv[12]=='NA--') {
            if($one_bv[6]=='HIS' && ($one_bv[11]=='-ND1' || $one_bv[11]=='-NE2') && $one_bv[23]>0.08) {
              $residue_HIS_allowance[$one_bv[5]]++;
            } elseif($one_bv[6]=='__A' && $one_bv[11]=='-N1-' && $one_bv[23]>0.08) {
              $residue_N1_allowance[$one_bv[5]]++;
            } elseif(($one_bv[6]=='__G' || $one_bv[6]=='__A' || $one_bv[6]=='__C') && $one_bv[11]=='-N3-' && $one_bv[23]>0.08) {
              $residue_N3_allowance[$one_bv[5]]++;
            } elseif(($one_bv[6]=='__G' || $one_bv[6]=='__A' || $one_bv[6]=='_DG' || $one_bv[6]=='_DA') && $one_bv[11]=='-N7-' && $one_bv[23]>0.08) {
              $residue_N7_allowance[$one_bv[5]]++;
            }
          }
          if($residue_metal_atomid[$one_bv[5]]==-1) {
            $residue_metal_atomid[$one_bv[5]]=$one_bv[10];
          } else {
            if($residue_metal_atomid[$one_bv[5]]!=$one_bv[10]) {
              $residue_multi_metal[$one_bv[5]]=1;
            }
          }
        }
        fclose($handle);


        $handle=fopen($this->file_ion_bindingsite, "r");
        $number_binding_sites=0;
        $partial_occupancy_symop=0;
        $jmol_site_definition="";
        $jmol_list_sites="";
        $jmol_list_centers="";
        $jmol_list_envs="";
        $jmol_measure_allconnected="";
        $first_cutoff=0;
        $exotic_lig_msg="";
        $exotic_met_msg="";
        $exotic_ring_msg="";
        $rare_metal_detected=0;
        $site_id=0;
        $is_first_site=1;
        $refmac_pdb_alt="";
        $refmac_chem_link_alt="";
        $refmac_chem_link_bond_alt="";
        $mg_i_site=-1;
        while(($buffer=fgets($handle,4096)) != false) {
          $mg_i_site+=1;
          $valence_is_problematic=0;

          list($pdbfileid,$bindingsiteid,$residueid_ion,$resname_ion,$atomid_ion,$atomname_ion,$protons_ion,$bfactor_ion,$bfactor_env_avg,$occupancy_ion,$occupancy_env_avg,$coord_number_3a,$coord_number_3a_ons,$geometry_type,$geometry_bidentate,$geometry_pseudo,$geometry_distort,$rmsd_geom_angle,$num_oxygen,$num_nitrogen,$num_sulfur,$num_phosphorus,$num_carbon,$num_others,$num04_oxygen_mc,$num08_oxygen_amide,$num10_oxygen_carboxyl,$num17_oxygen_hydroxyl,$num18_oxygen_phenol,$num26_oxygen_dnarna,$num28_oxygen_water,$num31_oxygen_others,$num01_nitrogen_mc,$num07_nitrogen_arginine,$num09_nitrogen_amide,$num13_nitrogen_histidine,$num14_nitrogen_lysine,$num15_nitrogen_tryptophan,$num25_nitrogen_dnarna,$num30_nitrogen_others,$num11_sulfur_cysteine,$num16_sulfur_methionine,$num33_sulfur_others,$num19_selenium,$num41_others,$num_bidentate_all,$num_bidentate_oo,$num_bidentate_on,$num_bidentate_nn,$distance_avg,$distance_min,$distance_max,$valence_3a,$vecsum_3a,$calcium_valence_3a,$calcium_vecsum_3a,$coord_number_4a,$num_metal_4a,$valence_4a,$vecsum_4a,$calcium_valence_4a,$calcium_vecsum_4a)=explode('|',$buffer);
          for($j=0;$j<13;$j++) { $bg[$mg_i_site][$j] = "#CCCCCC"; }
          $atomname_ion_nodash = preg_replace('/-/','',$atomname_ion);
          if($atomname_ion_nodash=='CA') {$atomname_ion_nodash='';};
          $chainid_colon_resseq=$residue_chainid[$residueid_ion].':'.$residue_resseq[$residueid_ion];
          $resseq_colon_chainid=$residue_resseq[$residueid_ion].':'.$residue_chainid[$residueid_ion];
          $mg_sites[]=$residue_resseq[$residueid_ion].':'.$residue_chainid[$residueid_ion].".".$atomname_ion_nodash;

          $number_binding_sites++;
          $id_binding_center="met".$number_binding_sites;
          $id_binding_env ="close".$number_binding_sites;
          $id_binding_env2="far".$number_binding_sites;
          $id_binding_site ="site".$number_binding_sites;
          switch ($protons_ion) {
            case 11: case 12: case 20:
            case 25: case 26: case 27:
            case 28: case 29: case 30:
                     $cutoff=2.8; break;
            case 19: $cutoff=3.3; break;
            default: $cutoff=3.3; if($protons_ion==31 or $protons_ion>=37) { $rare_metal_detected=1; }; break;
          }
          if($first_cutoff==0) {$first_cutoff=$cutoff;}
          $jmol_site_definition.="define $id_binding_center $resseq_colon_chainid.$atomname_ion_nodash; ";
          $jmol_site_definition.="define $id_binding_env2 (within (group, within (5.0, $id_binding_center)) and not $id_binding_center); ";
          $jmol_site_definition.="define $id_binding_env (within ($cutoff, $id_binding_center) and not elemno=1 and not elemno=6 and not $id_binding_center); ";
          $jmol_site_definition.="define $id_binding_site within (group, within (5.0, $id_binding_center)); ";
          $jmol_site_definition.="connect ($id_binding_center) ($id_binding_env and not _C) partial 1.1; ";
          if ($jmol_list_sites!="")   {$jmol_list_sites.=" or ";};
          if ($jmol_list_centers!="") {$jmol_list_centers.=" or ";};
          if ($jmol_list_envs!="")    {$jmol_list_envs.=" or ";};
          $jmol_list_sites.=$id_binding_site;
          $jmol_list_centers.=$id_binding_center;
          $jmol_list_envs.=$id_binding_env2;
          $jmol_measure_allconnected.="measure allconnected ($id_binding_center)($id_binding_env); ";
        # ACN == assumed coordination number; AOS == assumed oxidation state; LRW == Low resolution weight
          switch ($geometry_type) {
            case  0: $ACN=-1; break;
            case  1: $ACN=2;  break;
            case  2: $ACN=3;  break;
            case  3: $ACN=4;  break;
            case  4: $ACN=4;  break;
            case  5: $ACN=5;  break;
            case  6: $ACN=6;  break;
            case  7: $ACN=6;  break;
            case  8: $ACN=6;  break;
            case  9: $ACN=7;  break;
            case 10: $ACN=7;  break;
            case 11: $ACN=8;  break;
            case 12: $ACN=8;  break;
            case 13: $ACN=8;  break;
            case 15: $ACN=-1; break;
            case 16: $ACN=-1; break;
            default: $ACN=-1; break;
          }
          $ACN4 = ($ACN>4) ? $ACN : 4;
          if($res_dep==0) {
            $low_resolution_weight=0;
          } elseif($exp_method==2) {
            $low_resolution_weight=0;
          } elseif($resolution>=3 and $resolution<100) {
            $low_resolution_weight=0.9999;
          } elseif($resolution>2 and $resolution<3) {
            $low_resolution_weight=$resolution-2.0001;
          } else {
            $low_resolution_weight=0;
          }

          $val[$mg_i_site][0]=$chainid_colon_resseq;
          $val[$mg_i_site][1]=trim($resname_ion,"_");
          $val[$mg_i_site][2]=ucwords(strtolower(trim($atomname_ion,"-")));
          $val[$mg_i_site][3]=round($occupancy_ion,2);
          if($val[$mg_i_site][3]<=0.5) { $partial_occupancy_symop = 1; }
          if($val[$mg_i_site][3]<=0.01) {	# Evaluation of B factor is not applicable if metal occupancy is too low
            $val[$mg_i_site][4]="N/A";
          } elseif($exp_method==0) {
            if($bfactor_ion<2 && $bfactor_env_avg<2) {
              $val[$mg_i_site][4]="N/A";
            } else {
              $val[$mg_i_site][4]=round($bfactor_ion,1)." (".round($bfactor_env_avg,1).")";
            }
          } elseif($exp_method==1) {
            $val[$mg_i_site][4]=round($bfactor_ion,1)." (".round($bfactor_env_avg,1).")";
          } else {
            $val[$mg_i_site][4]="N/A";
          }
          if($this->is_resource) {
            $val[$mg_i_site][5]=  $num_carbon     ? 'C'.$num_carbon   : '';
            $val[$mg_i_site][5].= $num_oxygen     ? 'O'.$num_oxygen   : '';
            $val[$mg_i_site][5].= $num_nitrogen   ? 'N'.$num_nitrogen : '';
            $val[$mg_i_site][5].= $num_sulfur     ? 'S'.$num_sulfur   : '';
          } else {
            $val[$mg_i_site][5]=  $num_carbon     ? 'C<sub>'.$num_carbon.'</sub>'     : '';
            $val[$mg_i_site][5].= $num_oxygen     ? 'O<sub>'.$num_oxygen.'</sub>'     : '';
            $val[$mg_i_site][5].= $num_nitrogen   ? 'N<sub>'.$num_nitrogen.'</sub>'   : '';
            $val[$mg_i_site][5].= $num_sulfur     ? 'S<sub>'.$num_sulfur.'</sub>'     : '';
          }
        #     $val[5].= $num_phosphorus ? 'P<sub>'.$num_phosphorus.'</sub>' : '';
        #     if($valence_3a>0) {
        #      if($valence_3a>=0.2) { $val[6]=round($valence_3a,1); } else { $val[6]=round($valence_3a,2); }
        #     } else {
        #       $val[6]="N/A";
        #     }
        #     if($valence_3a>0 and $vecsum_3a>0) {
        #      if($vecsum_3a/$valence_3a>=0.1) { $val[7]=round($vecsum_3a/$valence_3a,2); } else { $val[7]=round($vecsum_3a/$valence_3a,3) };
        #     } else {
        #       $val[7]="N/A";
        #     }
          $val[$mg_i_site][6]=$valence_3a>0 ? round($valence_3a,2) : "N/A";
          if($valence_3a>=0.2) { $val[$mg_i_site][6]=round($valence_3a,1); }
          $val[$mg_i_site][7]=($valence_3a>0 and $vecsum_3a>0) ? round($vecsum_3a/$valence_3a,3) : "N/A";
          if($val[$mg_i_site][7]>=0.1) { $val[$mg_i_site][7]=round($vecsum_3a/$valence_3a,2); }
          $val[$mg_i_site][8]=$geometry_type;
          $val[$mg_i_site][9]=($rmsd_geom_angle>=0 && $rmsd_geom_angle<180) ? round($rmsd_geom_angle,1) : "N/A";
          $val[$mg_i_site][10]=($geometry_pseudo>=0 && $ACN>=0) ? $geometry_pseudo*100/$ACN : "N/A";
          $val[$mg_i_site][11]=$geometry_bidentate>=0 ? $geometry_bidentate : "N/A";
          $val[$mg_i_site][20]=round($calcium_valence_3a,2);
          $heme=0;
          switch ($resname_ion) {
            case "HEM": case "CLI": case "CLA": case "HEC": case "BCL": case "CYC":
            case "BPH": case "CHL": case "HEA": case "BCB": case "BLA": case "DHE":
            case "PEB": case "BPB": case "SFP": case "HDD": case "FEC": case "PHO":
            case "HNI": case "SRM": case "PP9": case "COH":
            case "1CP": case "CLN": case "CP3": case "DDH": case "DEU": case "FDD":
            case "FDE": case "FMI": case "H01": case "H02": case "HCO": case "HE5":
            case "HEG": case "HEV": case "HFM": case "HIF": case "HME": case "MHM":
            case "MMP": case "MNH": case "MNR": case "MP1": case "PC3": case "PCU":
            case "PNI": case "POH": case "POR": case "VEA": case "VER": case "ZEM":
            case "ZNH": $heme=1; break;
            default:
              $heme=0; break;
          }

        # common background color handling for five fields: occupancy, valence, nVECSUM, gRMSD, and vacancy
          $valve[3]=array(0.01, 0.99, 1000, 1000);
          switch ($protons_ion) {
            case 11: case 19:
            case 37: case 55: case 87: $bv_valve_1=0.4; $bv_valve_2=0.7; $bv_valve_3=1.3; $bv_valve_4=1.6; $AOS=1; break;
            case 12: case 20:
            case 38: case 56: case 88:
            case 30: case 48: case 80: $bv_valve_1=1.3; $bv_valve_2=1.7; $bv_valve_3=2.3; $bv_valve_4=2.7; $AOS=2; break;
            case 25: case 43: case 75: $bv_valve_1=1.0; $bv_valve_2=1.7; $bv_valve_3=4.4; $bv_valve_4=5.2; $AOS=2; break;
            case 26: case 27: case 28:
            case 44: case 45: case 46:
            case 76: case 77: case 78: $bv_valve_1=1.2; $bv_valve_2=1.6; $bv_valve_3=3.3; $bv_valve_4=3.6; $AOS=2; break;
            case 29: case 47: case 79: $bv_valve_1=0.4; $bv_valve_2=0.7; $bv_valve_3=2.3; $bv_valve_4=2.6; $AOS=1; break;
            default:                   $bv_valve_1=1.0; $bv_valve_2=1.7; $bv_valve_3=3.3; $bv_valve_4=4.0; $AOS=2; break;
          };
          $LRW=$low_resolution_weight/$ACN4;
          $valve[6]=array($bv_valve_1-$AOS*$LRW, $bv_valve_2-$AOS*$LRW, $bv_valve_3, $bv_valve_4);
          $vecsum_valve_3=sqrt(0.10*0.10+$LRW*$LRW);
          $vecsum_valve_4=sqrt(0.23*0.23+$LRW*$LRW);
          $valve[7]=array(-1, -1, $vecsum_valve_3, $vecsum_valve_4);
          $valve[9]=array(-1, -1, 13.5, 21.5);
          $valve[10]=array(-1, -1, 1+25*$low_resolution_weight, 25+25*$low_resolution_weight);

          for($j=3;$j<=10;$j++) {
            if($j!=4 && $j!=5 && $j!=8) {
              if($j==7 && ($val[$mg_i_site][$j]=="0.000" || $val[$mg_i_site][$j]=="0"))  $bg[$mg_i_site][$j]="#AAFFAA";
              elseif($j==10 && $val[$mg_i_site][$j]=="0") $bg[$mg_i_site][$j]="#AAFFAA";
        elseif($val[$mg_i_site][$j]=="N/A")         $bg[$mg_i_site][$j]="#CCCCCC";
              elseif($j==3 && $exp_method==2) $bg[$mg_i_site][$j]="#CCCCCC";
              elseif($j==3 && $val[$mg_i_site][3]<=0.5 && $this->pdbfile_valid>0 && strlen($this->file_contact_upload)>2) $bg[$mg_i_site][$j]="#CCCCCC";
        elseif($val[$mg_i_site][$j]<$valve[$j][0])  $bg[$mg_i_site][$j]="#FFAAAA";
        elseif($val[$mg_i_site][$j]<$valve[$j][1])  $bg[$mg_i_site][$j]="#FFFFAA";
        elseif($val[$mg_i_site][$j]<=$valve[$j][2]) $bg[$mg_i_site][$j]="#AAFFAA";
        elseif($val[$mg_i_site][$j]<=$valve[$j][3]) $bg[$mg_i_site][$j]="#FFFFAA";
        else                            $bg[$mg_i_site][$j]="#FFAAAA";
            }
          }
          if($bg[$mg_i_site][6]=="#FFAAAA" or $bg[$mg_i_site][7]=="#FFAAAA") {$valence_is_problematic=1;};

        # special background color handling for composition
          $composition="a";
          switch ($protons_ion) {
            case 11:
            case 12:
            case 19:
            case 20:
                     if($protons_ion!=20 && $residue_HIS_allowance[$residueid_ion]+$residue_N1_allowance[$residueid_ion]+$residue_N3_allowance[$residueid_ion]+$residue_N7_allowance[$residueid_ion]>=$num_nitrogen) {
                       $composition="a";
                     } elseif($num_nitrogen or $num_sulfur) {$composition="o"; }
                     break;
            case 25:
                     if($num_sulfur or $num_phosphorus) {$composition="b"; }
                     break;
            case 28:
            case 29:
            case 30:
                     if(!$num_nitrogen and !$num_sulfur and !$num_phosphorus) {$composition="b"; }
                     break;
            default:
                     break;
          };

          if($num_carbon) {$composition="o"; }
          if($num_oxygen+$num_nitrogen+$num_sulfur+$num_phosphorus<=1) {$composition="o"; }
          elseif($num_oxygen+$num_nitrogen+$num_sulfur+$num_phosphorus<=2 and $composition!="o") {$composition="b"; }
          if(!$num_oxygen and !$num_nitrogen and !$num_sulfur and !$num_phosphorus) {$composition="o"; }
          if($composition=="a") {			# acceptable
            $bg[$mg_i_site][5]="#AAFFAA";
          } elseif($composition=="b") {		# borderline
            $bg[$mg_i_site][5]="#FFFFAA";
          } else {
            $bg[$mg_i_site][5]="#FFAAAA";
          }

        # New algorithm
          if($bfactor_ion>$bfactor_env_avg) {
            $bfactor_coeff2= $bfactor_ion>0 ? ($bfactor_env_avg/$bfactor_ion) : ($bfactor_env_avg/0.0000001);
          } else {
            $bfactor_coeff2= $bfactor_env_avg>0 ? ($bfactor_ion/$bfactor_env_avg) : ($bfactor_ion/0.0000001);
          }
          $bfactor_diff="o";
          if($bfactor_coeff2>1.1) {
            $bfactor_diff="o";
          } elseif($bfactor_coeff2>=0.86) {
            $bfactor_diff="a";
          } elseif($bfactor_coeff2>=0.54) {
            $bfactor_diff="b";
          } else {
            $bfactor_diff="o";
          }
        # special background color handling for B factor difference
        #     if($bfactor_ion>$bfactor_env_avg) {
        #       $bfactor_coeff1=($bfactor_ion-$bfactor_env_avg);
        #       $bfactor_coeff2= $bfactor_env_avg>0 ? ($bfactor_ion/$bfactor_env_avg) : ($bfactor_ion/0.0000001);
        #     } else {
        #       $bfactor_coeff1=($bfactor_env_avg-$bfactor_ion);
        #       $bfactor_coeff2= $bfactor_ion>0 ? ($bfactor_env_avg/$bfactor_ion) : ($bfactor_env_avg/0.0000001);
        #     }
        #     $bfactor_diff="o";
        # Old algorithm
        #     if($bfactor_coeff1<=30.0-40.0*log($bfactor_coeff2)) {
        #       $bfactor_diff="a";
        #     } elseif($bfactor_coeff1<=70.0-40.0*log($bfactor_coeff2)) {
        #       $bfactor_diff="b";
        #     } else {
        #       $bfactor_diff="o";
        #     }
        # Old old algorithm
        #     if($bfactor_coeff1<20.0) {
        #       if($bfactor_coeff2<2.0) { $bfactor_diff="a";
        #       } elseif($bfactor_coeff2<5.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } elseif($bfactor_coeff1<40.0) {
        #       if($bfactor_coeff2<3.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } elseif($bfactor_coeff1<60.0) {
        #       if($bfactor_coeff2<2.0) { $bfactor_diff="b";
        #       } else { $bfactor_diff="o"; }
        #     } else {
        #       $bfactor_diff="o";
        #     }
          if ($bfactor_ion <= 2 or $bfactor_env_avg <= 2) { $bfactor_diff="o"; }
          if($val[$mg_i_site][4]=="N/A") {			# not applicable
            $bg[$mg_i_site][4]="#CCCCCC";
          } elseif($bfactor_diff=="a") {		# acceptable
            $bg[$mg_i_site][4]="#AAFFAA";
          } elseif($bfactor_diff=="b") {		# borderline
            $bg[$mg_i_site][4]="#FFFFAA";
          } else {
            $bg[$mg_i_site][4]="#FFAAAA";
          }

        # special background color handling for geometry
          $coordnum=$coord_number_3a_ons-$geometry_bidentate;
          $proton_arr = array(11,12,19,20,25,26,27,28,29,30,80);
          $common_metal=0;
          foreach ($proton_arr as $proton) {
            $alternative[$proton]=0;
            $t="o";	#outlier
        # check coordination sphere profile
            if($num_sulfur or $num_nitrogen) {
              if($proton>=25) { $alternative[$proton]+=10; }
            } else {
              if($proton>=25) { $alternative[$proton]+=10; }
              else { $alternative[$proton]+=11; }
            }
        # check geometry
            switch ($proton) {
              case 11: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";}; break;
              case 19: if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==12 or $val[$mg_i_site][8]==9 or $val[$mg_i_site][8]==11) {$t="b";}; break;
              case 12: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==10) {$t="o";}; break;
              case 20: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==9 or $val[$mg_i_site][8]==10 or $val[$mg_i_site][8]==12) {$t="b";}; break;
              case 25: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==10) {$t="b";}; break;
              case 26: if($heme) {
                       if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==10) {$t="b";};
                       } else {
                       if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="b";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";};
                       }; break;
              case 27: if($val[$mg_i_site][8]==4) {$t="b";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==5 or $val[$mg_i_site][8]==3) {$t="b";}; break;
              case 28: if($val[$mg_i_site][8]==4) {$t="o";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3) {$t="b";}; break;
        # Copper, set square planar as acceptable
              case 29: if($val[$mg_i_site][8]==4 or $val[$mg_i_site][8]==3) {$t="a";} elseif($val[$mg_i_site][8]==6 or $val[$mg_i_site][8]==2) {$t="b";}; break;
              case 30: if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="b";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";}; break;
              case 80: if($val[$mg_i_site][8]==1) {$t="a";}; break;
            }
            if($proton==$protons_ion) { $common_metal=1; };
            $geometry[$proton]=$t;
            if($t == "a") {
              $alternative[$proton]+=12;
            } elseif($t == "b") {
              $alternative[$proton]+=10;
            };
        # check bond valence value
            switch ($proton) {
              case 11: $cmin=1.41; $cmax=1.75; break;
              case 19: $cmin=0.58; $cmax=0.72; break;
              case 12: $cmin=3.71; $cmax=4.76; break;
              case 20: $cmin=1.70; $cmax=2.30; break;
              case 25: $cmin=4.77; $cmax=6.01; break;
              case 26: $cmin=5.30; $cmax=6.79; break;
              case 27: $cmin=3.56; $cmax=4.77; break;
              case 28: $cmin=4.68; $cmax=6.24; break;
              case 29: $cmin=3.69; $cmax=6.79; break;
              case 30: $cmin=4.08; $cmax=5.43; break;
              case 80: $cmin=2.54; $cmax=2.92; break;
            }
            $median =($cmax+$cmin)/2.0;
            $range  =$cmax-$cmin;
            $range25=0.25*$range;
            if($val[$mg_i_site][20]>$cmin-$range25 and $val[$mg_i_site][20]<$cmax+$range25) {
              $alternative[$proton]+=10;
              $deviation = ($val[$mg_i_site][20]>$median) ? $val[$mg_i_site][20]-$median : $median-$val[$mg_i_site][20];
              $alternative[$proton]+=(1-$deviation/(0.75*$range));
            }
          }
          asort($alternative);
          $descending_alternative = array_reverse($alternative, TRUE);
          $descending_alternative_keys = array_keys($descending_alternative);
          $val[$mg_i_site][12]="";
          if($descending_alternative_keys[0] != $protons_ion) {
            $first_alt_met=1;
            foreach ($descending_alternative as $akey => $aval) {
             if($aval>=30) {
        if($val[$mg_i_site][12] != "") {$val[$mg_i_site][12].=", ";};
        switch ($akey) {
              case 11: $alt_met="Na"; break;
              case 19: $alt_met="K";  break;
              case 12: $alt_met="Mg"; break;
              case 20: $alt_met="Ca"; break;
              case 25: $alt_met="Mn"; break;
              case 26: $alt_met="Fe"; break;
              case 27: $alt_met="Co"; break;
              case 28: $alt_met="Ni"; break;
              case 29: $alt_met="Cu"; break;
              case 30: $alt_met="Zn"; break;
              case 80: $alt_met="Hg"; break;
        }
              $val[$mg_i_site][12].=$alt_met;
              if($first_alt_met == 1) {
                $bvhandle=fopen($this->file_ion_bondvalence, "r");
                while(($bvbuffer=fgets($bvhandle,4096)) != false) {
                  $one_bv=explode('|',$bvbuffer);
                  list($pdb_txt, $cif_txt, $cif_txt_2) = $this->refmac_record_by_bondvalence($one_bv, $residueid_ion, strtoupper($alt_met), $residue_chainid, $residue_resseq);
                  $refmac_pdb_alt.=$pdb_txt;
                  $refmac_chem_link_alt.=$cif_txt;
                  $refmac_chem_link_bond_alt.=$cif_txt_2;
                }
                fclose($bvhandle);
                $first_alt_met=0;
              }
             }
            }
          }

          if($val[$mg_i_site][12]!="") { array_push($alt_metal_arr, $chainid_colon_resseq); }
          if($exp_method==2) {$val[$mg_i_site][12]="N/A";}

          if($common_metal==0) {
            $t="o";
            if($val[$mg_i_site][8]==4) {$t="a";} elseif($val[$mg_i_site][8]==6) {$t="a";} elseif($val[$mg_i_site][8]==3 or $val[$mg_i_site][8]==5) {$t="b";};
            $geometry[$protons_ion]=$t;
          }

          if($geometry[$protons_ion]=="a") {		# acceptable
            $bg[$mg_i_site][8]="#AAFFAA";
          } elseif($geometry[$protons_ion]=="b") {		# borderline
            $bg[$mg_i_site][8]="#FFFFAA";
          } else {
            $bg[$mg_i_site][8]="#FFAAAA";
          }

          switch ($val[$mg_i_site][8]) {
            case  0: $val[$mg_i_site][8]="Free"                 ; break;
            case  1: $val[$mg_i_site][8]="Linear"               ; break;
            case  2: $val[$mg_i_site][8]="Trigonal Planar"      ; break;
            case  3: $val[$mg_i_site][8]="Square Planar"        ; break;
            case  4: $val[$mg_i_site][8]="Tetrahedral"          ; break;
            case  5: $val[$mg_i_site][8]="Trigonal Bipyramidal" ; break;
            case  6: $val[$mg_i_site][8]="Octahedral"           ; break;
            case  7: $val[$mg_i_site][8]="Trigonal Biprism"     ; break;
            case  8: $val[$mg_i_site][8]="Trigonal Antiprism"   ; break;
            case  9: $val[$mg_i_site][8]="Capped Trigonal Biprism"; break;
            case 10: $val[$mg_i_site][8]="Pentagonal Bipyramidal" ; break;
            case 11: $val[$mg_i_site][8]="Cubic"                ; break;
            case 12: $val[$mg_i_site][8]="Square Antiprism"     ; break;
            case 13: $val[$mg_i_site][8]="Dodecahedral"         ; break;
            case 14: $val[$mg_i_site][8]="Irregular"            ; break;
            case 15: $val[$mg_i_site][8]="Poorly Coordinated"   ; break;
            case 16: $val[$mg_i_site][8]="Overflow"             ; break;
            default: $val[$mg_i_site][8]="Undefined"            ; break;
          }
          if($val[$mg_i_site][9]  != "N/A") { if($this->is_resource) {$val[$mg_i_site][9].='\u00b0';} else {$val[$mg_i_site][9].='&deg;';} }
          if($val[$mg_i_site][10] != "N/A") { $val[$mg_i_site][10]=(int)$val[$mg_i_site][10].'%'; }

          if($residue_env_comp[$residueid_ion]>=100) {
            if($exotic_ring_msg=="") { $exotic_ring_msg="potential cation-pi interactions observed around"; };
            $exotic_ring_msg.=" $chainid_colon_resseq";
          }
          if($valence_is_problematic) {
            if($residue_env_comp[$residueid_ion]%100>=10 or $residue_multi_metal[$residueid_ion]) {
              if($exotic_met_msg=="") { $exotic_met_msg="the presence of multi-nuclear metal clusters around"; };
              $exotic_met_msg.=" $chainid_colon_resseq";
              /* Turn off the flag after showing once to avoid same residue showing multiple times */
              if($residue_multi_metal[$residueid_ion]) {$residue_multi_metal[$residueid_ion]=0;}
            }
            if($residue_env_comp[$residueid_ion]%10>=1) {
              if($exotic_lig_msg=="") { $exotic_lig_msg="the presence of small molecules in the coordinate sphere of the metal ion"; };
              $exotic_lig_msg.=" $chainid_colon_resseq";
            }
          }
          $site_id++;
        }
        fclose($handle);

        $this->set('bg',$bg);
        $this->set('val',$val);
        $this->set('alt_metal_arr',$alt_metal_arr );
        $this->set('number_binding_sites',$number_binding_sites );
        $this->set('rare_metal_detected',$rare_metal_detected );
        $this->set('exotic_ring_msg',$exotic_ring_msg );
        $this->set('exotic_met_msg',$exotic_met_msg );
        $this->set('exotic_lig_msg',$exotic_lig_msg );
        $this->set('exp_method',$exp_method );
        $this->set('space_group_number',$space_group_number );
        $this->set('mg_sites',$mg_sites);
        $this->set('partial_occupancy_symop',$partial_occupancy_symop);

      } //end else from org listsite 933
    }

}
