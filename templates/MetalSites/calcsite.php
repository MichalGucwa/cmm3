<?php if (!$is_resource) { ?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html><head>
  <title>Center for Structural Genomics of Infectious Diseases</title>
  <style type="text/css">
    #resizable { width: 560px; height: 560px; }
  </style>
  <link href="csgid.css" rel="stylesheet" type="text/css" media="all">
  <!-- TODO idk if this works -->
  <link href="/ms_ext/jquery-ui.css" rel="stylesheet" type="text/css"/>

  <!-- NOTE no more jmol -->
  <!-- <?php// echo $javascript->link(array('/ms_ext/JSmol/jsmol/JSmol.min.js'), false); ?> -->
      <script type="text/javascript">
       var jmolApplet0;
       var use = "HTML5";
       var s = document.location.search;
Jmol.debugCode = (s.indexOf("debugcode") >= 0);
jmol_isReady = function(applet) {
        document.title = (applet._id + " - Jmol " + ___JmolVersion)
        Jmol._getElement(applet, "appletdiv").style.border="1px solid blue"
}
    var Info = {
      width: "99.0%",
      height: "98.7%",
      debug: false,
      color: "0xFFFFFF",
      addSelectionOptions: false,
      use: "HTML5",
      j2sPath: "/ms_ext/JSmol/jsmol/j2s",
      readyFunction: jmol_isReady,
      script: "set antialiasDisplay;load <?php if(!$is_pdb_format) { echo "cif::"; } else {echo "pdb::";};  if(strlen($file_contact_upload)>2) { echo $file_contact_upload; }
                                               elseif(strlen($file_model_upload)>2) { echo $file_model_upload; }
                                               else { echo $file_pdbfile_upload; }  ?>",
      disableJ2SLoadMonitor: true,
      disableInitialConsole: true,
      allowJavaScript: true
    }
    </script>

  <!-- TODO idk if this works -->
  <!-- <?php// echo $javascript->link(array('unitrack/jquery/jquery.min.js'), false); ?> -->
  <!-- <?php// echo $javascript->link(array('unitrack/jquery/jquery-ui.min.js'), false); ?> -->

  <script>

    function make_jmol_resizable() {
      var isMSIE = false;
      var fullVersion = 0;
      var verOffset, majorVersion;
      if ((verOffset=navigator.userAgent.indexOf("MSIE"))!=-1) {
        isMSIE = true;
        fullVersion = navigator.userAgent.substring(verOffset+5);
        majorVersion = parseInt(''+fullVersion,10);
      }
      if(! isMSIE || (majorVersion >= 8)) {
        $(document).ready(function() {
          $("#resizable").resizable();
        });
      }
    };
    function altmetal_toggle_bgcolor(input_name, input_value) {
      var stem = input_name + ":" + input_value;
      var form0 = document.forms[0];
      var text0 = document.getElementById(stem);
      if(form0[input_name].value == input_value) {
        text0.style.backgroundColor='#CCCCCC';
        form0[input_name].value = 0;
        form0["tmp_cnt"].value--;
        if(form0["tmp_cnt"].value == '0') {
          form0["submitbtn"].disabled = true;
        }
      } else {
        text0.style.backgroundColor='#FFFF00';
        if(form0[input_name].value == '0') {
          form0["tmp_cnt"].value++;
          form0["submitbtn"].disabled = false;
        }
        form0[input_name].value = input_value;
      }
    };
    function graph_set_color(stem, input_color) {
      var text1 = document.getElementById(stem);
      text1.style.color = input_color;
      if(input_color=="black") {
        text1.style.cursor = "default";
      } else {
        text1.style.cursor = "pointer";
      }
    }
  </script>
<?php } # end of is_resource?>
</head><body>

<?php

  function warning_message($msg) {
      return "<tr><td style=\"padding:1px\" colspan=9><table width=\"100%\"><tr><td style=\"padding:1px\" bgcolor=#FFAAAA><b><center> Warning: $msg</center></b></td></tr></table></td></tr>";
  }

  $dict_linkid=[];

  $pdburl="http://www.pdb.org/pdb/explore/explore.do?structureId=";
  $pdbid="unknown";
  if(preg_match('/^pdb(\w\w\w\w)\.ent$/', $pdbfile_name, $matches)) { $pdbid = $matches[1]; } ;

  if (!$is_resource) { ?>
    <div id='topnav'>
      <?=substr($pdbfile_name,4) == "XXXX" ? "User uploaded PDB file" : "PDB code: <a target=\"new\" href=\"$pdburl$pdbid\">".strtoupper($pdbid)."</a>";?>
      (Click on individual metal binding site to switch views)
    </div>
    <table width=100%>
      <tr>
        <td>
          <b><?=$this->Html->link('CheckMyMetal(CMM) Home', ['action' => 'index']);?></b>
        </td>
        <td>
          <b><?=$this->Html->link('Report a Problem', ['action' => 'index','#' => 'bug-report-anchor']);?></b>
        </td>
        <td align="right">
            <b>Save CMM report (<A HREF=\"/ms_ext/examples/file_download.php?filename=$file_output_html\">HTML</A>, <A HREF=\"/ms_ext/examples/file_download.php?filename=$file_output_pdf\">PDF</a>)</b>
        </td>
      </tr>
    </table>
  <?php  } # end of is_resource?>

<?php

$outheader=""; $outtab1=""; $outtab2=""; $outtab3=""; $outtab4="";

if($pdbfile_valid == -1) {
echo "<H3>Number of new request from $pdbfile_name exceed limit for today, please check back tomorrow.</H3>";
} elseif(!$pdbfile_valid) {
echo "<H3>Invalid PDB file ~ [".$pdbfile_name."]</H3>";
} else {
$outtab1  = "<table cellpadding=3>";
$outtab1 .= $this->Html->tableHeaders(array('ID','Res.','Metal','<i>Occupancy</i>','<i>B factor (env.)</i><sup>1</sup>','<i>Ligands</i>','<i>Valence</i><sup>2</sup>','<i>nVECSUM</i><sup>3</sup>','<i>Geometry</i><sup>1,4</sup>','<i>gRMSD</i>(&deg;)<sup>1</sup>','<i>Vacancy</i><sup>1</sup>','Bidentate','Alt. metal'));
$label[0] ="ID";
$label[1] ="Res.";
$label[2] ="Metal";
$label[3] ="Occupancy";
$label[4] ="B_factors";
$label[5] ="Ligands";
$label[6] ="Valence";
$label[7] ="nVECSUM";
$label[8] ="Geometry";
$label[9] ="gRMSD";
$label[10]="Vacancy";
$label[11]="Bidentate";
$label[12]="Alt_metal";
if (!$is_resource) {
echo $outtab1;
} # end of is_resource

echo $this->Form->Create(null, ['url'=>['action'=>'modelsite'], 'type'=>'post']);
$metals_select=["Na"=>"Na","K"=>"K","Mg"=>"Mg","Ca"=>"Ca","Mn"=>"Mn","Fe"=>"Fe","Co"=>"Co","Ni"=>"Ni","Cu"=>"Cu","Zn"=>"Zn","Hg"=>"Hg"];
//TODO what if there is no metal sites?
for($mg_i_site=0;$mg_i_site<count($bg);$mg_i_site++) {
  if(!$is_resource) {
    $outtab1 .= $this->html->tag('tr'); echo $this->html->tag('tr');
    $total_violation=0;
    for($j=0;$j<13;$j++) {
      if($bg[$mg_i_site][$j]=="#FFAAAA")     { $total_violation+=2; $val[$mg_i_site][$j]='<u><b>'.$val[$mg_i_site][$j].'</b></u>'; }
      elseif($bg[$mg_i_site][$j]=="#FFFFAA") { $total_violation+=1; $val[$mg_i_site][$j]='<u><i>'.$val[$mg_i_site][$j].'</i></u>'; }
      if($j==12 and $total_violation<2 and $val[$mg_i_site][$j]!="N/A") { $val[$mg_i_site][$j]=""; }
      echo '<td bgcolor="'.$bg[$mg_i_site][$j].'">';
      if($j==0) { # for switching button
        //TODO i dont need jmol
        // $site_script[$site_id] = "center $resseq_colon_chainid; zoom 1800; select $id_binding_site;
        // cpk 10%; select $id_binding_env2; wireframe 0.10;
        // select has_label; wireframe 0.02;
        // select has_label and not :# and $id_binding_site; label %c%r:%n;
        // select has_label and :# and $id_binding_site; label sym-%r:%n;
        // select $id_binding_center; label %c%r:%e; color label black; center $id_binding_center;
        // slab on; slab 55; cartoon off; restrict $id_binding_site";
        // #echo "<button id=\"msite$site_id\">".$val[0]."</button>";
        // echo "<a href=\"javascript:Jmol.script(jmolApplet0,'".$site_script[$site_id]."')\">".$val[$mg_i_site][0]."</a>";
        echo $val[$mg_i_site][0];
      } elseif($j==12) {
        //   //NOTE we now have select
        //   if($val[$mg_i_site][12]!="") { # for alternate metal
        //     $each_alt_metal_arr=explode(', ',$val[$mg_i_site][12]);
        //     $count_altmetal=count($each_alt_metal_arr);
        //     for($ii=0;$ii<$count_altmetal;$ii++) {
        //       $ena=$each_alt_metal_arr[$ii]; if($ena!= "") {
        //       $chainid_colon_resseq=$val[$mg_i_site][0];
        //       $elemstem="$chainid_colon_resseq:$ena"; //B:31:metal_name
        //       echo '<span id="'.$elemstem.'" style="color:#074a7e; text-decoration: none; cursor: pointer" ';
        //       echo 'onmouseover="document.getElementById(\''.$elemstem.'\').style.color=\'#801010\'" ';
        //       echo 'onmouseout ="document.getElementById(\''.$elemstem.'\').style.color=\'#074a7e\'" ';
        //       echo "onclick=\"altmetal_toggle_bgcolor('$chainid_colon_resseq','$ena'); ";
        //       for($jj=0;$jj<$count_altmetal;$jj++) {
        //         if($jj!=$ii) {
        //           echo 'document.getElementById(\''.$chainid_colon_resseq.':'.$each_alt_metal_arr[$jj].'\').style.backgroundColor=\'#CCCCCC\'; ';
        //         }
        //       }
        //       echo '">'.$ena.'</span>&nbsp;'; //we display the alt. metal name here
        //     } }
        // }
        //NOTE I only want if this is not exotic metal
        if(in_array($val[$mg_i_site][2],array_keys($metals_select) ) ) {
          echo $this->Form->select('selection'.$mg_i_site, $metals_select, ['default' => $val[$mg_i_site][2]]); //metal select
          echo $this->Form->input('info_selection'.$mg_i_site, ['type' => 'hidden', 'value'=>$val[$mg_i_site][0]] );
        } else {
          echo ""; //nothing
          echo $this->Form->input('selection'.$mg_i_site, ['type' => 'hidden', 'value'=>'0']);
          echo $this->Form->input('info_selection'.$mg_i_site, ['type' => 'hidden', 'value'=>'0']);
        }
      } else { echo $val[$mg_i_site][$j]; }
      echo '</td>';
      $outtab1 .= '<td bgcolor="'.$bg[$mg_i_site][$j].'">'.$val[$mg_i_site][$j].'</td>';
    }
    $outtab1 .= $this->html->tag('/tr'); echo $this->html->tag('/tr');
  } elseif($resource_format=="json") {
  if($is_first_site) {
  echo "{\n  \"validations\": [\n    {\n";
  $is_first_site=0;
  } else {
  echo "    },\n\n    {\n";
  }
  echo "      \"chainid\": \"".$residue_chainid[$residueid_ion]."\",\n";
  echo "      \"resseq\": ".$residue_resseq[$residueid_ion].",\n";
  echo "      \"resname\": \"".$val[$mg_i_site][1]."\",\n";
  echo "      \"atomname\": \"".$val[$mg_i_site][2]."\",\n";
  echo "      \"parameters\": [\n";
  for($j=3;$j<12;$j++) {
  if(is_numeric($val[$mg_i_site][$j])) { $valuej=$val[$mg_i_site][$j]; } else { $valuej="\"".$val[$mg_i_site][$j]."\""; };
  if($bg[$mg_i_site][$j]=="#FFAAAA")     { $bgj="o"; }
  elseif($bg[$mg_i_site][$j]=="#FFFFAA") { $bgj="b"; }
  elseif($bg[$mg_i_site][$j]=="#AAFFAA") { $bgj="a"; }
  else { $bgj="u"; }
  echo "        {\n";
  echo "          \"parameter_name\": \"".$label[$j]."\",\n";
  echo "          \"parameter_value\": $valuej,\n";
  echo "          \"parameter_class\": \"$bgj\"\n";
  if($j==11) {
    echo "        }\n";
  } else {
    echo "        },\n";
  }
  }
  echo "      ]\n";
  } elseif($resource_format=="refmac") {
  if($number_binding_sites==$numbindingsites) {
  # echo "{
  # \"cif\": \"\\n data_link_list\\n loop_\\n _chem_link.id\\n _chem_link.comp_id_1\\n _chem_link.mod_id_1\\n _chem_link.group_comp_1\\n _chem_link.comp_id_2\\n _chem_link.mod_id_2\\n _chem_link.group_comp_2\\n _chem_link.name\\n $refmac_chem_link\\n \\n \\n # --- DESCRIPTION OF LINKS ---\\n #\\n $refmac_chem_link_bond#\",

  # \"pdb\": \"$refmac_pdb\",

  # \"cif_alt\": \"data_link_list\\n loop_\\n _chem_link.id\\n _chem_link.comp_id_1\\n _chem_link.mod_id_1\\n _chem_link.group_comp_1\\n _chem_link.comp_id_2\\n _chem_link.mod_id_2\\n _chem_link.group_comp_2\\n _chem_link.name\\n $refmac_chem_link_alt\\n \\n # --- DESCRIPTION OF LINKS ---\\n #\\n $refmac_chem_link_bond_alt#\",

  # \"pdb_alt\": \"$refmac_pdb_alt\"
  #}";
  echo "{
  \"cif\": \"\ndata_link_list\n loop_\n _chem_link.id\n _chem_link.comp_id_1\n _chem_link.mod_id_1\n _chem_link.group_comp_1\n _chem_link.comp_id_2\n _chem_link.mod_id_2\n _chem_link.group_comp_2\n _chem_link.name\n $refmac_chem_link\n \n \n # --- DESCRIPTION OF LINKS ---\n #\n $refmac_chem_link_bond#\",

  \"pdb\": \"\n$refmac_pdb\",
  ";

  if (strlen($refmac_pdb_alt) < -1) { # This block of code is disabled for the moment
  echo "
  \"cif_alt\": \"\ndata_link_list\n loop_\n _chem_link.id\n _chem_link.comp_id_1\n _chem_link.mod_id_1\n _chem_link.group_comp_1\n _chem_link.comp_id_2\n _chem_link.mod_id_2\n _chem_link.group_comp_2\n _chem_link.name\n $refmac_chem_link_alt\n \n # --- DESCRIPTION OF LINKS ---\n #\n $refmac_chem_link_bond_alt#\",

  \"pdb_alt\": \"\n$refmac_pdb_alt\"
  ";
  };

  echo "
  }";
  }
  } elseif($resource_format=="csv") {
  if($is_first_site) {
  echo "PDBID, CHAINID, RESSEQ, RESNAME, ATOMNAME, OCCUPANCY, C1, BFACTOR, C2, LIGANDS, C3, VALENCE, C4, NVECSUM, C5, GEOMETRY, C6, GRMSD, C7, VACANCY, C8, BIDENTATE, C9, NUMPARAM, PER\n";
  $is_first_site=0;
  }
  echo "'".$pdbid."', ";
  echo "'".$residue_chainid[$residueid_ion]."', ";
  echo $residue_resseq[$residueid_ion].", ";
  echo "'".$val[$mg_i_site][1]."', ";
  echo "'".$val[$mg_i_site][2]."', ";
  $total_score=0;
  $num_params=0;
  for($j=3;$j<12;$j++) {
  if(is_numeric($val[$mg_i_site][$j])) { $valuej=$val[$mg_i_site][$j]; } else { $valuej="'".$val[$mg_i_site][$j]."'"; };
  if($bg[$mg_i_site][$j]=="#FFAAAA")     { $bgj="o"; $num_params++; $total_score+=0.0; }
  elseif($bg[$mg_i_site][$j]=="#FFFFAA") { $bgj="b"; $num_params++; $total_score+=0.5; }
  elseif($bg[$mg_i_site][$j]=="#AAFFAA") { $bgj="a"; $num_params++; $total_score+=1.0; }
  else { $bgj="u"; }
  echo "$valuej, '$bgj', ";
  }
  $total_score=$total_score*1.0/$num_params;
  echo "$num_params, $total_score\n";
  } # end is_resource
}//iterations mg_i_site

if(!$is_resource) {
    $legend_text='<tr><td colspan=3 align="right"><table><tr><th><b>Legend:</b></th></tr></table></td><td colspan=4><table><tr><td bgcolor="#CCCCCC">Not applicable</td><td bgcolor="#FFAAAA"><u><b>Outlier</b></u></td><td bgcolor="#FFFFAA"><u><i>Borderline</i></u></td><td bgcolor="#AAFFAA">Acceptable</td></tr></table></td><td colspan=6 align="right">';
    echo $legend_text;
    if(count($bg)>0){ //always
    ?>
    <table border="0" style="width:300px">
      <tr>
        <th colspan='2'>Generate a model with alt. metal:</th>
      </tr>
      <tr>
        <td>
          Select the metal(s) above and
        </td>
        <td>
          <!-- NOTE to Michal this is main setting thing up -->
          <!-- which folder loc -->
          <?=$this->Form->input('n_sites',['hidden'=>true,'value'=>count($bg)]);?>
          <?=$this->Form->input('mg_pdb_path',['hidden'=>true,'value'=>$file_pdbfile_upload]);?>
          <?=$this->Form->input('densfile_2fo',['hidden'=>true,'value'=>$densfile_2fo]);?>
          <?=$this->Form->input('densfile_fo',['hidden'=>true,'value'=>$densfile_fo]);?>
          <?=$this->Form->button('Change',['name'=>'submitbtn']);?>
          <?=$this->Form->end();?>
        </td>

      </tr>
    </table>
    <?php
    // if(count($alt_metal_arr)) {
      //TODO fix this
      // echo '<table border="0"><tr><td bgcolor="#dcdcdc" style="padding:0"><table border=0 cellpadding=0 cellspacing=0><tr><th>Generate a model with alt. metal:</th></tr></table></td><td valign="middle" style="padding:3px">Select the metal(s) above and</td><td valign="middle" style="padding:2px">';
      // echo $form->create('MetalSite', array('action' => 'newmodel'));
      // $alt_metal_list="";
      // foreach ($alt_metal_arr as $alt_metal) {
      //   echo '<input type="hidden" name="'.$alt_metal.'" value="0">';
      //   if($alt_metal_list!="") {$alt_metal_list.=',';};
      //   $alt_metal_list.=$alt_metal;
      // }
      // echo '<input type="hidden" name="tmp_cnt" value=0>';
      // echo '<input type="hidden" name="alt_metal_index" value="'.$alt_metal_list.'">';
      // echo '<input type="hidden" name="input_pdbfile" value="'.$file_input_pdb.'">';
      // echo '<input type="hidden" name="output_pdbfile" value="'.$file_output_pdb.'">';
      // echo '<input type="hidden" name="server_file_output_pdb" value="'.$server_file_output_pdb.'">';
      // echo '<div class="submit"><input name="submitbtn" type="submit" value="Save" disabled></div></form>';
      // echo '</td></tr></table>';
    }
    echo "</td></tr></table>";
    $legend_text.="</td></tr></table>";
    $outtab1.=$legend_text;
    if($number_binding_sites==0) {
      $msg_no_metal = "<H3>No metal present in the model requested, or metal is far away from the modelled macromolecule chain.</H3>";
      echo $msg_no_metal; $outtab1 .= $msg_no_metal;
    }
} # end is_resource

} //end of else 933



if($is_resource) {
  if($resource_format=="json") {
    echo "    }\n  ]";
    $first_pngplot="";
    $count_pngplot=0;
    $filestem_arr=array();
    $handle=fopen($file_plots, "r");
    while(($buffer=fgets($handle,4096)) != false) {
      $filestem=trim($buffer,"\n");
      if(strlen($filestem)==5) {
        $filestem_arr[$count_pngplot]=$filestem;
        $count_pngplot++;
      }
    }
    fclose($handle);
    if($count_pngplot>=1) {
      echo ",\n\n  \"distributions\": [\n    {\n";
      echo $plot_data_json;
      echo "    }\n  ]";
    }
    echo "\n}";
  }
} else { # end is_resource
?>
<table border width="900">
  <tr align="CENTER" valign="TOP">
    <td align="LEFT">
      <table width=570>
      <?php
#       if($number_binding_sites!=0) {
#         echo "<tr><td colspan=9 bgcolor=#FFFFAA><b><center>The model presented accounts for metal-ligand optimal distance</center></b></td><tr>";
#       }
###
#       echo "<tr><th colspan=9 style=\"white-space: normal\"><b><center>A Java-independent version of CMM will be available soon.</tr>";
###
        if(strlen($title)>1) {
          echo "<tr><th colspan=9 style=\"white-space: normal\"><b><center>";
          $outheader = "PDB title: <a target=\"new\" href=\"$pdblink\">".ucfirst(strtolower($title))."</a>";
          if($exp_method==2) { $outheader .= "(NMR)";
          } elseif($resolution>0.1 and $resolution<100) { $outheader .= sprintf('(%3.1f&Aring;)', $resolution);
          }
          echo "$outheader</center></b></th><tr>";
          $outheader = "<h3><a href=\"/metal_sites/\">CheckMyMetal(CMM)</a> report for PDB code: $pdbid</h3><hr>".$outheader."<br><hr>";
          if($exp_method==2) {
#           echo "<tr><td colspan=9 bgcolor=#FFFFAA><b><center>Note: metal binding sites are shown only for the first model in the ensemble. To check metal sites in other models of the ensemble, upload individual model in PDB format.</center></b></td><tr>";
            echo "<tr><td style=\"padding:1px\" colspan=9><table width=\"100%\"><tr><td style=\"padding:1px\" bgcolor=#FFFFAA><b><center>Please note: Only the first model of this NMR structure is displayed.</center></b></td></tr></table></td></tr>";
          }
        }
        if($pdbfile_valid>0) {
         $msg2="";
         if($rare_metal_detected==1) {
          $msg2 .= warning_message("Due to a lack of high-resolution structural data the validity of <I>Valence</I> and <I>nVECSUM</I> parameters has not been established for rarely observed metals");
         }
         $exotic_msg=$exotic_ring_msg;
         if($exotic_msg!="") {
           if($exotic_met_msg!="" and $exotic_lig_msg!="") { $exotic_msg.="; $exotic_met_msg; and $exotic_lig_msg";
           } elseif($exotic_met_msg!="") { $exotic_msg.="; and $exotic_met_msg";
           } elseif($exotic_lig_msg!="") { $exotic_msg.="; and $exotic_lig_msg"; };
         } else {
           if($exotic_met_msg!="" and $exotic_lig_msg!="") { $exotic_msg=$exotic_met_msg."; and ".$exotic_lig_msg;
           } elseif($exotic_met_msg!="") { $exotic_msg=$exotic_met_msg;
           } elseif($exotic_lig_msg!="") { $exotic_msg=$exotic_lig_msg; };
 }
         if($exotic_msg!="") {
          $msg2 .= warning_message("<I>Valence</I> and <I>nVECSUM</I> parameters should be interpreted with great care due to ".$exotic_msg);
         }
         if($exp_method==1 and $space_group_number<0) {
          $msg2 .= warning_message("CRYST1 record is missing for X-ray crystallography structures");
         }
         if(strlen($file_contact_upload)>2) {
          $msg2 .= warning_message("Coordinating ligands by symmetry operation are labeled with prefix 'sym-'");
          if($partial_occupancy_symop) {
           $msg2 .= warning_message("Partial occupancy of the metal is not adjusted upon symmetry operation");
          }
         }
         echo $msg2;
         $outheader .= "<table width=\"900\">$msg2</table>";
        }
      ?>



          <?php
            $mg_pdb_path='../'.$file_pdbfile_upload;
            if($densfile_fo!=-1){
              $mg_fo_path="../".$densfile_fo;
            } else {$mg_fo_path=-1;}
            if($densfile_2fo!=-1){
              $mg_2fo_path="../".$densfile_2fo;
            } else {$mg_2fo_path=-1;}
            echo $this->Html->script("/js/ngl/ngl.js");
          ?>

          <tr><td colspan=9><div id="resizable", style='position:relative'><script>make_jmol_resizable();</script>
            <script>
              var mg_sites_js = <?php echo json_encode($mg_sites)?>;
              var file_fo = <?php echo json_encode($mg_fo_path)?>;
              var file_2fo = <?php echo json_encode($mg_2fo_path)?>;
              document.addEventListener("DOMContentLoaded", function () {

                var stage = new NGL.Stage("resizable");

                function addElement (el) {
                  Object.assign(el.style, {
                    position: "absolute",
                    zIndex: 10
                  })
                  stage.viewer.container.appendChild(el)
                }

                function createElement (name, properties, style) {
                  var el = document.createElement(name)
                  Object.assign(el, properties)
                  Object.assign(el.style, style)
                  return el
                }

                function createSelect (options, properties, style) {
                  var select = createElement("select", properties, style)
                  options.forEach(function (d) {
                    select.add(createElement("option", {
                      value: d[ 0 ], text: d[ 1 ]
                    }))
                  })
                  return select
                }


                var repre_main = "ball+stick";

                //main protein
                stage.loadFile("<?=$mg_pdb_path?>").then( function (o) {


                  o.addRepresentation("cartoon", {
                    sele: "all",
                    name: "protein_cartoon",
                    color: "atomindex",
                    visible: protein_cartoonCheckbox.checked
                  })

                  //protein_licorice
                  o.addRepresentation("licorice", {
                    name: "all_licorice",
                    visible: all_licoriceCheckbox.checked,
                    sele: "all"
                  })

                  //site_metal main start
                  var radius_ligands = 5;
                  var selection_metal = new NGL.Selection( mg_sites_js[0] );
                  var atomSet1 = o.structure.getAtomSetWithinSelection( selection_metal, radius_ligands );
                  var atomSet2 = o.structure.getAtomSetWithinGroup( atomSet1 );


                  //to do podmienic 400:A na pierwsze z listy
                  //main
                  var repre_main = "ball+stick";
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and " + mg_sites_js[0],
                    name: "site"
                  })
                  // //water
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and water",
                    name: "site"
                  })
                  // //ion
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and ion",
                    name: "site"
                  })
                  // //protein
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and protein",
                    name: "site"
                  })
                  // //rest
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and not water and not ion and not protein and not " + mg_sites_js[0],
                    name: "site"
                  })

                  //Distances
                  //to do visible under button
                  //distances
                  var radius_ligands = 2.8;
                  var atomSet_ligands = o.structure.getAtomSetWithinSelection( selection_metal, radius_ligands );
                  var atomSet_ligands_str = atomSet_ligands.toSeleString().substring(1,);
                  var set_ligands_ids = atomSet_ligands_str.split(",");
                  var set_ligands_ids_int = [];
                  var metal_id = o.structure.getAtomSetWithinSelection( selection_metal, 0 ).toSeleString().substring(1,);;
                  var distance_pairs=[];
                  for (var index in set_ligands_ids) {
                    if(metal_id != set_ligands_ids[index]){
                      distance_pairs.push([parseInt(set_ligands_ids[index]),parseInt(metal_id)]);
                    }
                  }

                  o.addRepresentation("distance", {
                    atomPair: distance_pairs,
                    labelColor: "yellow",
                    labelSize: 1,
                    scale: 0.2,
                    color: "white",
                    type: "",
                    name: "dist",
                    visible: distCheckbox.checked
                  })

                  var center = o.getCenter(mg_sites_js[0]);
                  stage.animationControls.zoomMove(center, -20, 0);

                  // o.autoView()
                })




                //2fo-fc
                if(file_2fo!=-1){
                  stage.loadFile(file_2fo).then( function (o) {
                    o.addRepresentation("surface", {
                      sele: "all",
                      color:"skyblue",
                      name: "density",
                      isolevel: 1.5,
                      boxSize: 3,
                      useWorker: false,
                      contour: true,
                      visible: densityCheckbox.checked
                    })
                  })
                }

                //fo-fc
                if(file_fo!=-1){
                  stage.loadFile(file_fo).then( function (o) {
                    o.addRepresentation("surface", {
                      sele: "all",
                      color:"lightgreen",
                      name: "density",
                      isolevel: 3.0,
                      boxSize: 3,
                      useWorker: false,
                      contour: true,
                      visible: densityCheckbox.checked
                    })

                    o.addRepresentation("surface", {
                      sele: "all",
                      name: "density",
                      color: "tomato",
                      isolevel: 3.0,
                      negateIsolevel: true,
                      boxSize: 3,
                      useWorker: false,
                      contour: true,
                      visible: densityCheckbox.checked
                    })
                  })
                }






                //button
                var protein_cartoonCheckbox = createElement("input", {
                  type: "checkbox",
                  checked: false,
                  onchange: function (e) {
                    stage.getRepresentationsByName("protein_cartoon")
                      .setVisibility(e.target.checked)
                  }
                }, { top: "54px", left: "3px" })
                addElement(protein_cartoonCheckbox)

                addElement(createElement("span", {
                  innerText: "Protein: Cartoon"
                }, { top: "56px", left: "21px" , color: "white"}))



                //licorice
                var all_licoriceCheckbox = createElement("input", {
                  type: "checkbox",
                  checked: false,
                  onchange: function (e) {
                    stage.getRepresentationsByName("all_licorice")
                      .setVisibility(e.target.checked)
                  }
                }, { top: "71px", left: "3px", color: "black"})
                addElement(all_licoriceCheckbox)

                addElement(createElement("span", {
                  innerText: "All: Licorice"
                }, { top: "73px", left: "21px", color: "white"}))


                // //dist
                var distCheckbox = createElement("input", {
                  type: "checkbox",
                  checked: true,
                  onchange: function (e) {
                    stage.getRepresentationsByName("dist")
                      .setVisibility(e.target.checked)
                  }
                }, { top: "87px", left: "3px" })
                addElement(distCheckbox)

                addElement(createElement("span", {
                  innerText: "Distances"
                }, { top: "89px", left: "21px", color: "white"}))

                let pol_arr = []
                for (i=0; i<mg_sites_js.length;i++){
                  pol_arr.push([mg_sites_js[i],mg_sites_js[i]])
                }

                var polymerSelect2 = createSelect(pol_arr, {
                  onchange: function (e) {
                    stage.getRepresentationsByName("site").dispose()
                    stage.getRepresentationsByName("dist").dispose()
                    stage.eachComponent(function (o) {

                      var radius_ligands = 5;
                      var selection_metal = new NGL.Selection( e.target.value );
                      var atomSet1 = o.structure.getAtomSetWithinSelection( selection_metal, radius_ligands );
                      var atomSet2 = o.structure.getAtomSetWithinGroup( atomSet1 );

                      //main
                      o.addRepresentation(repre_main, {
                        sele: atomSet2.toSeleString() + " and " + e.target.value,
                        name: "site"
                      })
                      // //water
                      o.addRepresentation(repre_main, {
                        sele: atomSet2.toSeleString() + " and water",
                        name: "site"
                      })
                      // //ion
                      o.addRepresentation(repre_main, {
                        sele: atomSet2.toSeleString() + " and ion",
                        name: "site"
                      })
                      // //protein
                      o.addRepresentation(repre_main, {
                        sele: atomSet2.toSeleString() + " and protein",
                        name: "site"
                      })
                      // //rest
                      o.addRepresentation(repre_main, {
                        sele: atomSet2.toSeleString() + " and not water and not ion and not protein and not " + e.target.value,
                        name: "site"
                      })


                      //Distances
                      //distances
                      var radius_ligands = 2.8;
                      var atomSet_ligands = o.structure.getAtomSetWithinSelection( selection_metal, radius_ligands );
                      var atomSet_ligands_str = atomSet_ligands.toSeleString().substring(1,);
                      var set_ligands_ids = atomSet_ligands_str.split(",");
                      var set_ligands_ids_int = [];
                      var metal_id = o.structure.getAtomSetWithinSelection( selection_metal, 0 ).toSeleString().substring(1,);;
                      var distance_pairs=[];
                      for (var index in set_ligands_ids) {
                        if(metal_id != set_ligands_ids[index]){
                          distance_pairs.push([parseInt(set_ligands_ids[index]),parseInt(metal_id)]);
                        }
                      }

                      o.addRepresentation("distance", {
                        atomPair: distance_pairs,
                        labelColor: "yellow",
                        labelSize: 1,
                        scale: 0.2,
                        color: "white",
                        type: "",
                        name: "dist",
                        visible: distCheckbox.checked
                      })



                      var center = o.getCenter(e.target.value);
                      stage.animationControls.zoomMove(center, -20, 0);
                    })

                  }
                }, { top: "29px", left: "3px", width : '100px', background: 'yellow'})
                addElement(polymerSelect2)
                //end of select


                var fsButton = createElement("input", {
                  type: "button",
                  value: "FullScreen",
                  onclick: function () {
                    stage.toggleFullscreen()
                  }
                }, { top: "3px", left: "3px" , background: "red", color: "black"})
                addElement(fsButton)

                //electron_density
                if(file_2fo!=-1 || file_fo!=-1){
                  var densityCheckbox = createElement("input", {
                    type: "checkbox",
                    checked: true,
                    onchange: function (e) {
                      stage.getRepresentationsByName("density")
                        .setVisibility(e.target.checked)
                    }
                  }, { top: "103px", left: "3px", color: "black"})
                  addElement(densityCheckbox)

                  addElement(createElement("span", {
                    innerText: "Electron density"
                  }, { top: "105px", left: "21px", color: "white"}))
              }

              });


              var lastPrompt=0;
            </script></div></td>
          </tr>

        <tr><th colspan=6>Mouse click action:</th><th colspan=3><p style="color:red">Crystallization conditions:</p></th></tr>
        <tr align="CENTER" valign="BOTTOM"><td align="LEFT" colspan=6>
        <SCRIPT>
          jmolRadioGroup([
          ["set picking off", "None", "selected"],
          ["set picking center", "Center"],
          ["set picking distance", "Distance"],
          ["set picking label", "Label"],
          ]);
        </SCRIPT>
          <table><tr><td>
          Left-Click to rotate<br>
          Shift-Left-Click up &amp; down to zoom<br>
          Shift-Left-Click left &amp; right to rotate on Z<br>
          <a href="javascript:Jmol.script(jmolApplet0,'console')">Access console here</a><br>
          <A HREF="../../metal_sites"><b>Click here for another PDB file</b></A>
          </td></tr></table>
          </td>

      <td align="left" valign="middle">
        <?php

          // $cryst_path = "neighborhood_temp/" . $pdbid . "/pdb" . $pdbid . '.ent';
          // debug($file_input_pdb);exit;
          $myfile = fopen($file_input_pdb, "r") or die("Unable to open file!");
          $buffer = fread($myfile,filesize($file_input_pdb));
          fclose($myfile);

          $c_lines= explode('REMARK', $buffer);
          $flag=0;
          foreach ($c_lines as $key => $value) {
            //first line
            if( strpos($value, "CRYSTALLIZATION CONDITIONS: ")!==false){
              $subvalue = explode("CRYSTALLIZATION CONDITIONS: ", $value);
              echo $subvalue[1] . "<br>";
              $flag=1;
              continue;
            }
            // other lines
            if($flag==1){
              $subvalue = "REMARK" . $value;
              if( strpos($subvalue, "REMARK 280 ")!==false){
                $subvalue = explode("REMARK 280 ", $subvalue);
                echo $subvalue[1];
              }
              else {
                break;
              }

            }
            // if( $key==(count($c_lines)-1)) continue;
            // echo $value . "<br>";
          }
          // echo $set1[1]
        ?>
      </td>

      </tr>

        <tr><td colspan=9><i>JSmol</i>: HTML5 canvas version of the <a href="http://www.jmol.org/" target="new"><i>Jmol</i></a> molecule viewer (<a href="http://chemapps.stolaf.edu/jmol/jsmol/jsmol.htm" target="new"><i>JSmol</i> examples</a>)</td></tr>
        <tr><td colspan=9 bgcolor="#dcdcdc">&nbsp;</td></tr>

    <?php
echo "<TR><TD colspan=9>";
$outtab4 = "
<a target=\"new\" href=\"http://www.ncbi.nlm.nih.gov/pubmed/24356774\">(1) Zheng H, Chordia MD, Cooper DR, Chruszcz M, M&uuml;ller P, Sheldrick GM, Minor W (2014) <I>Nature Protocols</I>, <I>9(1)</I>, 156-70.</a><br>
<a target=\"new\" href=\"http://www.ncbi.nlm.nih.gov/pubmed/19728716\">(2) Brown ID (2009) <I>Chem. Rev.</I>, <I>109</I>, 6858-6919.</a><br>
<a target=\"new\" href=\"http://www.ncbi.nlm.nih.gov/pubmed/12499536\">(3) M&uuml;ller P, K&ouml;pke S, Sheldrick GM (2003) <I>Acta Crystallogr. D Biol. Crystallogr.</I>, <I>59</I>, 32-37.</a><br>
<a target=\"new\" href=\"http://www.ncbi.nlm.nih.gov/pubmed/19708219\">(4) Kuppuraj G, Dudev M, Lim C (2009) <I>J. Phys. Chem. B</I>, <I>113</I>, 2952-2960.</a><br>
<a target=\"new\" href=\"http://www.ccdc.cam.ac.uk/products/csd/\">(5) <I>CSD: Cambridge Structural Database</I></a><br>
Maintained by: Heping Zheng &lt;<a href=\"mailto:dust@iwonka.med.virginia.edu\">dust@iwonka.med.virginia.edu</a>&gt;";
echo $outtab4;
    ?>
</TD></TR></table>
    </td>
    <td align="LEFT" width="400">
      <script>
/*    jmolRadioGroup([
        ["center 400:A; zoom 1000; slab 55; slab on", "Center on 400:A<br>"],
        ["center 400:B; zoom 1000; slab 55; slab on", "Center on 400:B<br>"],
      ])
*/    </script>

<?php

  if($pdbfile_valid>0) {

    $first_pngplot="";
    $count_pngplot=0;
    $filestem_arr=array();
    $handle=fopen($file_plots, "r");
    while(($buffer=fgets($handle,4096)) != false) {
      $filestem=trim($buffer,"\n");
      if(strlen($filestem)==5) {
        $filestem_arr[$count_pngplot]=$filestem;
        $count_pngplot++;
      }
    }
    fclose($handle);
    $distribution_title=$pdbfile_name=="XXXX.pdb"?"uploaded file":$pdbfile_name;
    if($count_pngplot) {
      if($count_pngplot==1) {
        echo '<table width="350"><TR><TH colspan='.$count_pngplot.'>'.$filestem_arr[0].' distance distribution for '.$distribution_title.'<sup>1</sup></TH>';
      } else {
        echo '<table width="350"><TR><TH colspan='.$count_pngplot.'>Metal-ligand distance distribution for '.$distribution_title.'<sup>1</sup></TH></TR><TR>';
        for($i=0;$i<$count_pngplot;$i++) {
          $filestem=$filestem_arr[$i];
          $filestem_color="black";
          if($i) { $filestem_color="#074a7e"; }
          echo '<TH><span id="'.$filestem.'" style="color:'.$filestem_color.'; text-decoration: none; cursor: default; " ';
          echo 'onmouseover="if(document.getElementById(\''.$filestem.'\').style.color!=\'black\') { graph_set_color(\''.$filestem.'\', \'#801010\'); }" ';
          echo 'onmouseout ="if(document.getElementById(\''.$filestem.'\').style.color!=\'black\') { graph_set_color(\''.$filestem.'\', \'#074a7e\'); }" ';
          echo 'onclick="document.getElementById(\'distance_distribution_image\').src=\''.$dir_server_session.'/'.$filestem.'.png\';';
          for($j=0;$j<$count_pngplot;$j++) {
            if($j!=$i) {
              echo "graph_set_color('$filestem_arr[$j]','#074a7e'); ";
            }
          }
          echo "graph_set_color('$filestem','black')\">".$filestem.'</span></TH>';
        }
      }
      echo '</TR><TR style="border:0px solid #000; margin-bottom:0px;"><TD colspan='.$count_pngplot.'>';
      echo $this->Html->image('../'.$dir_server_session.'/'.$filestem_arr[0].'.png', ['alt' => 'CakePHP']);
      echo '</TD></TR>';
      echo '</table><br>';
      # Images in the CMM_output.html and CMM_output.pdf file to be saved by user
      $outtab2='<h3>Metal-ligand distance distribution';
      if($count_pngplot>1) {$outtab2.="s";};
      $outtab2.=' for '.$distribution_title.' in comparison with CSD</h3><table width="900"><TR>';
      for($i=0;$i<$count_pngplot;$i++) {
        if($i>0 and $i%2==0) {$outtab2.="</tr><tr>"; };
        $outtab2.='<td><img src="'.$dir_server_session.'/'.$filestem_arr[$i].'.png"></td>';
      }
      $outtab2.="</tr></table>";
    }
  }
      //TODO make it work
      // $cnt1=count($usage_arr);
      // $cnt0=count($usage0_arr);
      // $cnt5=5*ceil(($cnt1+$cnt0)/5);
      // if(($cnt1+$cnt0)>0) {
      //   echo '<table width="350"><tr><th colspan=5>Recent browsing history (PDBID : number of ions)</th></tr><tr>';
      //   //TODO make it work
      //   for ($i=0;$i<$cnt1;$i++) {
      //     $sessionid=trim($usage_arr[$i][0]['sessionid']);
      //     $numbs=$usage_arr[$i][0]['numofbindingsites'];
      //     example_button($sessionid,$form,$numbs);
      //     if(($i % 5)==4) { echo "</tr><tr>"; };
      //   }
      //   for ($i=0;$i<$cnt0;$i++) {
      //     $sessionid=trim($usage0_arr[$i][0]['sessionid']);
      //     $numbs=$usage0_arr[$i][0]['numofbindingsites'];
      //     example_button($sessionid,$form,$numbs);
      //     if((($i+$cnt1) % 5)==4) { echo "</tr><tr>"; };
      //   }
      //   for ($i=($cnt1+$cnt0);$i<$cnt5;$i++) {
      //     echo "<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>";
      //   };
      //   echo "</tr></table><br>";
      // };
?>

      <table width="350"><TR><TH>Brief description of CMM parameters</TH></TR></table>
      <table width="350">
<?php
  $outtab3=$this->Html->tableHeaders(array('Column','Description'));
  $outtab3.="
      <TR><TD><i>Occupancy</i></TD>            <TD>Occupancy of ion under consideration </TD></TR>
      <TR><TD><i>B factor (env.)</i><SUP>1</SUP></TD>
                                               <TD>Metal ion B factor, with valence-weighted environmental average B factor in parenthesis </TD></TR>
      <TR><TD><i>Ligands</i></TD>              <TD>Elemental composition of the coordination sphere </TD></TR>
      <TR><TD><i>Valence</i><SUP>2</SUP></TD>  <TD>Summation of bond valence values for an ion binding site. <i>Valence</i> accounts for metal-ligand distances </TD></TR>
      <TR><TD><i>nVECSUM</i><SUP>3</SUP></TD>  <TD>Summation of ligand vectors, weighted by bond valence values and normalized by overall valence. Increase when the coordination sphere is not symmetrical due to incompleteness.</TD></TR>
      <TR><TD><i>Geometry</i><SUP>1,4</SUP></TD>  <TD>Arrangement of ligands around the ion, as defined by the <I>NEIGHBORHOOD</I> algorithm </TD></TR>
      <TR><TD><i>gRMSD</i>(&deg;)<SUP>1</SUP></TD> <TD>R.M.S. Deviation of observed geometry angles (L-M-L angles) compared to ideal geometry, in degrees </TD></TR>
      <TR><TD><i>Vacancy</i><SUP>1</SUP></TD>  <TD>Percentage of unoccupied sites in the coordination sphere for the given geometry </TD></TR>
      <TR><TD>Bidentate</TD>                   <TD>Number of residues that form a bidentate interaction instead of being considered as multiple ligands </TD></TR>
      <TR><TD>Alt. metal</TD>                  <TD>A list of alternative metal(s) is proposed in descending order of confidency, assuming metal environment is accurately determined. This feature is still experimental. It requires user discrimination and cannot be blindly accepted</TD></TR>
      </table>";
  echo $outtab3;
  $outtab3="<table width=\"900\">".$outtab3;
  $handle=fopen($file_output_html, "w");
  $outheader="<html><head><style type=\"text/css\"> table { border-spacing:0; border-collapse:collapse; } th { border-style:solid; border-width:1px; } td { border-style:solid; border-width:1px; border-color:#000000; } </style></head><body>".$outheader;
  fprintf($handle,'%s%s<BR>%s<BR>%s<BR><table width=900><tr><td colspan=2>%s',$outheader,$outtab1,$outtab3,$outtab2,$outtab4);
  fprintf($handle,'<hr><b>Citing CheckMyMetal (CMM):</b><br>
<a target="new" href="http://www.ncbi.nlm.nih.gov/pubmed/24356774"><b>Validation of metal-binding sites in macromolecular structures with the CheckMyMetal web server.</b>
Zheng,H., Chordia,M.D., Cooper,D.R., Chruszcz,M., M&uuml;ller,P., Sheldrick,G.M., Minor,W. (2014) <I>Nature Protocols</I>, <I>9(1)</I>, 156-70.</a>
</td></tr></table></body></html>');
  fclose($handle);
  system("rm $file_output_pdf");
  system("/usr/bin/xvfb-run -a /usr/bin/wkhtmltopdf -q /$dir_server_session/CMM_output.html $file_output_pdf");
?>
    </td>
  </tr>
</table>


</body></html>

<?php } # end is_resource end of listsite?>
