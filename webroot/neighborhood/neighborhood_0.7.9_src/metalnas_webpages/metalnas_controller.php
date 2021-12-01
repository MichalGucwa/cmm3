<?php

$GLOBALS["server_neighborhood_temp"]="/csgid/app/webroot/neighborhood_temp/metalna";
$GLOBALS["neighborhood_temp"]="/var/www/html".$GLOBALS["server_neighborhood_temp"];
$GLOBALS["pdb_archive"]="/med/data2/pdb_data/pdb_archive_unzipped/data/structures/divided/pdb";

class MetalnasController extends AppController {

    var $name = 'Metalnas';
    var $helpers = array('Html', 'Form', 'Paginator', 'AJAX');
    var $scaffold;

    /**
    * Standard action, list all rows, and paginate them.
    */
#   var $paginate = array(
#       'limit'=>25,
#       'order'=>array('Metalna.sid'=>'asc')
#   );

    function pdbheadline($pdbid) {
      $pdbfiles_arr = $this->Metalna->query("select * from pdbfiles where pdbid='$pdbid'");
      $pdbfiles_rec=$pdbfiles_arr[0][0];
      $pdburl="http://www.pdb.org/pdb/explore/explore.do?structureId=";
      $uc_pdbid=strtoupper($pdbfiles_rec['pdbid']);
      $pdblink=$pdburl.$uc_pdbid;
      $header=$pdbfiles_rec['header'];
      $resolution=$pdbfiles_rec['resolution'];
      $title=$pdbfiles_rec['title'];
      $dep_date=$pdbfiles_rec['deposition_date'];
      return "<b><a target=\"new\" href=\"$pdblink\">$uc_pdbid</a> ($resolution&Aring;) -- $header: <a target=\"new\" href=\"$pdblink\">".ucfirst(strtolower($title))."</a> ($dep_date)</b><br>";
    }

    function fetch_coord_arr($pdbid, $chainid, $resseq, $temp_id) {
      $mgrnasite_arr = $this->Metalna->query("select * from metalnas where pdbid='$pdbid' and chainid='$chainid' and resseq=$resseq");
      $mgrnasite_rec = $mgrnasite_arr[0][0];
      $pdbfileid     = $mgrnasite_rec['idp'];
      $bindingsiteid = $mgrnasite_rec['idb'];
      $residueid     = $mgrnasite_rec['idr'];
#     $coord_arr_query="select chainid,resseq from ion_bindingsite_ligresidues where pdbfileid=$pdbfileid and bindingsiteid=$bindingsiteid and residuetype>=42";
      $coord_arr_query="select chainid,resseq from ion_bindingsite_ligresidues where pdbfileid=$pdbfileid and bindingsiteid=$bindingsiteid";
      if(($temp_id>=10000 and $temp_id<=11000) or ($temp_id>=11009 and $temp_id<=19999)) {
        $coord_arr_query.=" and (ligresiduetype=1 or ligresiduetype=3)";
      } else {
        $coord_arr_query.=" and ligresiduetype<=3";
      }
      return $this->Metalna->query("$coord_arr_query");
    }

    function generate_mgsite_fragment($pdbfile_in, $pdbfile_out, $chainid, $resseq, $coord_residue_arr) {
      $coord_residue_cnt = count($coord_residue_arr);
      $handle_in =fopen($pdbfile_in, "r");
      $handle_out=fopen($pdbfile_out, "w");
      while(($buffer=fgets($handle_in,4096)) != false) {
        if(preg_match('/^(ATOM  |HETATM)(...............)(.)(...\d)/', $buffer, $matches)) {
          $chainid_in = $matches[3];
          $resseq_in  = $matches[4];
#fprintf($handle_out,'%s',"-$chainid_in-$resseq_in-$chainid-$resseq-\n");
          $res_found  = 0;
          if($chainid_in == $chainid and $resseq_in == $resseq) {
            $res_found=1;
          } else {
            for ($i=0;$i<$coord_residue_cnt;$i++) {
              if($chainid_in == $coord_residue_arr[$i][0]['chainid'] and $resseq_in == $coord_residue_arr[$i][0]['resseq']) {
                $res_found=1;
              }
            }
          }
          if($res_found) { fprintf($handle_out,'%s',$buffer); }
        }
      }
      fclose($handle_out);
      fclose($handle_in);
    }

    function generate_mgsite_thumbnail($pdbfile, $pngfile, $pngfile2, $zoom_extent) {
      $outersphere_hb_definition = "";
      if($zoom_extent>8) {
        $outersphere_hb_definition = "dist measure03, MGHOH, outer, mode=2
set dash_gap, 0.4, measure03
color aquamarine, measure03
";
      }
      $common_pymol_commands = "set ray_shadow, 0
set bg_rgb, (1,0.92,0.84)
set sphere_scale, 0.18, all
set stick_radius, 0.14, all
show sticks, all
show spheres, all
select Prot, resn gly+ala+val+leu+ile+ser+thr+cys+met+pro+asp+asn+glu+gln+lys+arg+his+phe+tyr+trp
hide sticks, Prot
hide spheres, Prot
hide lines, Prot
select Carbon, elem C
color grey, Carbon
select MG, name mg
select MG_5A, (MG expand 5) & !(resn HOH)
select complete_res, br. MG_5A
select waters_MG, (MG around 3.23)&(resn HOH)
select nonwaters_MG, (MG around 3.23)& !(resn HOH)
select MGHOH, waters_MG or MG
select innerp, (byres (nonwaters_MG and (name OP1 or name OP2))) and (name OP1 or name OP2)
select outer, (MGHOH around 3.7) & !(resn HOH) & !nonwaters_MG & !innerp
set sphere_scale, 0.30, MG
set sphere_scale, 0.25, resn HOH
dist measure01, MG, waters_MG, mode=2
set dash_gap, 0.0, measure01
color green, measure01
dist measure02, MG, nonwaters_MG, mode=2
set dash_gap, 0.0, measure02
color green, measure02
$outersphere_hb_definition
zoom MG, $zoom_extent
hide label
set ray_shadow, 0
set bg_rgb, (1,0.92,0.84)
ray 300, 300
";
      system("/usr/bin/pymol -cqp <<EOF
load $pdbfile
$common_pymol_commands
png $pngfile
EOF");
      system("/usr/bin/pymol -cqp <<EOF
load $pdbfile
rotate y,90
$common_pymol_commands
png $pngfile2
EOF");
    }

    function schematic_draw_ligand($x1, $y1, $angle, $length, $ligand_str) {
      $x2 = $x1 + $length * sin(deg2rad($angle));
      $y2 = $y1 - $length * cos(deg2rad($angle));
      $y2text = $y2+5;
      if($ligand_str == "Pout" or $ligand_str == "Rout" or $ligand_str == "Bout") {
        $link_options = 'stroke-width="3" stroke="rgb(64,255,255)" stroke-linecap="round" stroke-dasharray="2, 6"';
        $buffer = "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" $link_options/>\n";
      } else {
        $link_options = 'stroke-width="3" stroke="rgb(64,255,64)"';
        $x3 = $x1 + $length * 0.55 * sin(deg2rad($angle));
        $y3 = $y1 - $length * 0.55 * cos(deg2rad($angle));
        $x4 = $x1 + $length * 0.73 * sin(deg2rad($angle));
        $y4 = $y1 - $length * 0.73 * cos(deg2rad($angle));
        $xt = $x1 + $length * 0.66 * sin(deg2rad($angle));
        $yt = $y1 - $length * 0.66 * cos(deg2rad($angle)) + 5;
        $buffer = "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x3\" y2=\"$y3\" $link_options/>\n";
        if($ligand_str == "NB") {
          $element_color="#4040FF"; $element_name="N";
        } else {
          $element_color="#FF4040"; $element_name="O";
        }
        $buffer.= "<line x1=\"$x2\" y1=\"$y2\" x2=\"$x4\" y2=\"$y4\" stroke-width=\"4\" stroke=\"$element_color\"/>\n";
        $buffer.= "<text x=\"$xt\" y=\"$yt\" style=\"text-anchor: middle; font-size: 15px; stroke: $element_color;\">$element_name</text>\n";
      }
      $ligand_text_style   = "style=\"text-anchor: middle; font-size: 15px;\"";
      $ligand_stroke_style = "stroke-width=\"1\" stroke=\"rgb(0,0,0)\"";
      if($ligand_str == "Pout" or $ligand_str == "OP") {
        $buffer .= "<circle cx=\"$x2\"  cy=\"$y2\" r=\"18\" fill=\"rgb(255,204,128)\" $ligand_stroke_style/>
        <text x=\"$x2\" y=\"$y2text\" $ligand_text_style><tspan>PO<tspan baseline-shift = \"sub\">4</tspan></tspan></text>\n";
      } elseif($ligand_str == "Rout" or $ligand_str == "OR") {
        $p_x1=$x2;    $p_y1=$y2-12;
        $p_x2=$x2+24; $p_y2=$y2-2;
        $p_x3=$x2+15; $p_y3=$y2+13;
        $p_x4=$x2-15; $p_y4=$y2+13;
        $p_x5=$x2-24; $p_y5=$y2-2;
        $buffer .= "<polygon points=\"$p_x1,$p_y1 $p_x2,$p_y2 $p_x3,$p_y3 $p_x4,$p_y4 $p_x5,$p_y5\" fill=\"rgb(255,255,192)\" $ligand_stroke_style/>
        <text x=\"$x2\" y=\"$y2text\" $ligand_text_style>Ribose</text>\n";
      } else {
        $buffer .= "<ellipse cx=\"$x2\" cy=\"$y2\" rx=\"21\" ry=\"14\" fill=\"rgb(192,192,255)\" $ligand_stroke_style/>
        <text x=\"$x2\" y=\"$y2text\" $ligand_text_style>Base</text>\n";
      }
      return $buffer."\n";
    }

    function generate_class_schematic_drawing($svgfile, $schfile, $sid, $site_type, $class, $num_p, $which_bnr, $bo, $ro, $angle, $optional_num_pout) {
      $handle_out=fopen($svgfile, "w");
      $num_vertices=$num_p;
      $cx=100;
      $cy=100;
      $buffer="<svg><rect width=\"200\" height=\"200\" style=\"fill: #CBCBCB\"/>\n";
      $ligand_arr = array();
      if($class==2) {
        for($i=0;$i<$num_p;$i++) { array_push($ligand_arr, "Pout"); }
        for($i=0;$i<$ro;$i++)    { array_push($ligand_arr, "Rout"); }
        for($i=0;$i<$bo;$i++)    { array_push($ligand_arr, "Bout"); }
        $num_vertices += $bo + $ro;
      } elseif($class==1) {
        $num_b = floor($which_bnr/100);
        $num_n = floor(($which_bnr%100)/10);
        $num_r = $which_bnr%10;
        for($i=0;$i<$num_p;$i++) { array_push($ligand_arr, "OP"); }
        for($i=0;$i<$num_r;$i++) { array_push($ligand_arr, "OR"); }
        for($i=0;$i<$num_b;$i++) { array_push($ligand_arr, "OB"); }
        for($i=0;$i<$num_n;$i++) { array_push($ligand_arr, "NB"); }
        $num_vertices += $num_b + $num_n + $num_r;
      }
      if ($optional_num_pout != 0) {
        $buffer.=$this->schematic_draw_ligand($cx,$cy,0,75,"OP");
        for($i=1; $i<=$optional_num_pout; $i++) {
          $buffer.=$this->schematic_draw_ligand($cx,$cy,$i*360/($optional_num_pout+1),75,"Pout");
        }
      } elseif($num_vertices<=4) {
        if($class==1 and $num_p==2 and preg_match('/^trans/', $site_type)) {
          $buffer.=$this->schematic_draw_ligand($cx,$cy,315,106,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy,135,106,"OP");
          if($num_vertices>=3) { $buffer.=$this->schematic_draw_ligand($cx,$cy, 45,106,$ligand_arr[2]); }
          if($num_vertices>=4) { $buffer.=$this->schematic_draw_ligand($cx,$cy,225,106,$ligand_arr[3]); }
        } elseif($class==1 and $num_p==3 and preg_match('/^fac/', $site_type)) {
          $buffer.=$this->schematic_draw_ligand($cx,$cy, 0,75,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy,45,75,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy,90,75,"OP");
          if($num_vertices>=4) { $buffer.=$this->schematic_draw_ligand($cx,$cy,225,106,$ligand_arr[3]); }
        } elseif($class==1 and $num_p==4 and preg_match('/^trans,cis/', $site_type)) {
          $buffer.=$this->schematic_draw_ligand($cx,$cy,  0,75,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy, 45,75,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy, 90,75,"OP");
          $buffer.=$this->schematic_draw_ligand($cx,$cy,180,75,"OP");
        } else {
          if($num_vertices>=1) { $buffer.=$this->schematic_draw_ligand($cx,$cy,315,106,$ligand_arr[0]); }
          if($num_vertices>=2) { $buffer.=$this->schematic_draw_ligand($cx,$cy, 45,106,$ligand_arr[1]); }
          if($num_vertices>=3) { $buffer.=$this->schematic_draw_ligand($cx,$cy,135,106,$ligand_arr[2]); }
          if($num_vertices>=4) { $buffer.=$this->schematic_draw_ligand($cx,$cy,225,106,$ligand_arr[3]); }
        }
      } else {
        for($i=0; $i<$num_vertices; $i++) {
          $buffer.=$this->schematic_draw_ligand($cx,$cy,$i*360/$num_vertices,75,$ligand_arr[$i]);
        }
      }
      if($class==1 and $optional_num_pout==0) {
        $buffer .= "<circle cx=\"$cx\" cy=\"$cy\" r=\"28\" fill=\"rgb(192,255,192)\" stroke-width=\"1\" stroke=\"rgb(0,0,0)\"/>
                    <text x=\"$cx\" y=\"$cy\" style=\"text-anchor: middle; font-size: 15px;\">Mg</text>\n";
      } else {
        $outer_style="fill=\"rgb(255,192,192)\" stroke-width=\"1\" stroke=\"rgb(0,0,0)\"";
        if($class==2) {
          $buffer .= "<circle cx=\"$cx\" cy=\"$cy\" r=\"42\" $outer_style/>";
          $num_water=6;
        } else {
          $xa = $cx + 42 * sin(deg2rad(30));
          $ya = $cy - 42 * cos(deg2rad(30));
          $xb = $cx + 42 * sin(deg2rad(330));
          $yb = $cy - 42 * cos(deg2rad(330));
          $buffer .= "<path d=\"M $cx $cy L $xa $ya A 42 42 0 1 1 $xb $yb Z\" $outer_style/>";
          $num_water=5;
        }
        $cy33=$cy+33;
        $buffer .= "<circle cx=\"$cx\" cy=\"$cy\" r=\"16\" fill=\"rgb(192,255,192)\" stroke-width=\"1\" stroke=\"rgb(0,0,0)\"/>
        <text x=\"$cx\" y=\"$cy\" style=\"text-anchor: middle; font-size: 15px;\">Mg</text>
        <text x=\"$cx\" y=\"$cy33\" style=\"text-anchor: middle; font-size: 15px;\">$num_water H2O</text>\n";
      }
      $buffer.="</svg>";
      fprintf($handle_out,'%s',$buffer);
      fclose($handle_out);
      system("/usr/bin/convert $svgfile $schfile");
    }

    function site_fields_arr() {
      $fields_arr = array('Metalna.pdbid', 'Metalna.chainid', 'Metalna.resseq', 'Metalna.sid', 'Metalna.site_type',
                          'Metalna.cn',  'Metalna.pv',  'Metalna.ps',  'Metalna.pe',  'Metalna.bench',
                          'Metalna.isp', 'Metalna.isr', 'Metalna.isb', 'Metalna.isw', 'Metalna.iso',
                          'Metalna.osp', 'Metalna.osr', 'Metalna.osb');
      return $fields_arr;
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

    function index() {
#    chmod("/var/www/html/csgid/app/webroot/neighborhood_temp", 0777);
#    var_dump($this->params);
#    echo "<hr>".$this->cacheAction."<hr>".var_dump($this->paginate);

     $temp_id=-1;
     $bench = "bench=1 and ";
     $this->set('bench',1); $hide_validation=1;
     if(count($this->params["pass"]) >= 1) {
       $temp_id=$this->params["pass"][0];
       if($temp_id=="all") { $bench=""; $this->set('bench',0);  $hide_validation=0; $temp_id=-1; }
       if($temp_id=="ful") { $bench=""; $this->set('bench',-1); $hide_validation=1; $temp_id=-1; }
       if(count($this->params["pass"]) >= 2) { $temp_id=$this->params["pass"][1]; }
     }
     if($temp_id>=10000 and $temp_id<=99999) {
      $this->set('summary', 0);
      $this->paginate = array( 'Metalna' => array (
	'limit'      => 25,
	'fields'     => $this->site_fields_arr(),
	'conditions' => $bench.'sid = '.$temp_id,
	'order'      => 'Metalna.pdbid asc'));
      $this->set('temp_id',$temp_id);
      $additional_order = "";
      $optional_num_pout=0;
      if($temp_id>=11001 and $temp_id<=11005) { $additional_order = "which_mbrp2 asc,"; $optional_num_pout=$temp_id%10; }
      $mgrnasite_arr = $this->Metalna->query("select pdbid,chainid,resseq,site_type,sid,class,num_p,which_bnr,bo,ro,angle from metalnas where sid=$temp_id and pv>0.5 and ps>0.6 and pe>0.5 order by which_wooo2 asc, $additional_order pv+ps+pe desc");
      if(!count($mgrnasite_arr)) {
        $mgrnasite_arr = $this->Metalna->query("select pdbid,chainid,resseq,site_type,sid,class,num_p,which_bnr,bo,ro,angle from metalnas where sid=$temp_id order by which_wooo2 asc, pv+ps+pe desc");
      }
      $mgrnasite_rec = $mgrnasite_arr[0][0];
      $pdbid         = $mgrnasite_rec['pdbid'];
      $chainid       = $mgrnasite_rec['chainid'];
      $resseq        = $mgrnasite_rec['resseq'];
      $site_type     = $mgrnasite_rec['site_type'];
// Begin generating schematic drawing for class
      $svgfile       = $GLOBALS["neighborhood_temp"]."/$temp_id.svg";
      $schfile       = $GLOBALS["neighborhood_temp"]."/$temp_id.png";
      $server_schfile= $GLOBALS["server_neighborhood_temp"]."/$temp_id.png";
      if(!file_exists($svgfile) or !file_exists($schfile)) {
        $this->generate_class_schematic_drawing($svgfile, $schfile, $temp_id, $site_type, $mgrnasite_rec['class'], $mgrnasite_rec['num_p'], $mgrnasite_rec['which_bnr'], $mgrnasite_rec['bo'], $mgrnasite_rec['ro'], $mgrnasite_rec['angle'], $optional_num_pout);
        chmod($schfile, 0777);
      }
      $this->set('sch_thumbnail',$server_schfile);
// Begin generating thumbnail for class
      $this->set('rep_pdbid',    $pdbid);
      $this->set('rep_chainid',  $chainid);
      $this->set('rep_resseq',   $resseq);
      $this->set('rep_site_type',$site_type);
      $this->set('rep_summary',  $this->pdbheadline($pdbid));
#     if(preg_match('/^\w(\w\w)\w$/' ,$pdbid, $matches)) {$pdbid_middle = $matches[1]; } ;
#     $pdbfile =$GLOBALS["pdb_archive"]."/$pdbid_middle/pdb$pdbid.ent";
      $pdb_dir =$GLOBALS["neighborhood_temp"]."/$pdbid";
      $pdbfile2="$pdb_dir/pdb$pdbid.ent";
      $mg_site ="$pdb_dir/outer-$chainid-$resseq.ent";
      $pngfile ="$pdb_dir/outer-$chainid-$resseq.png";
      $pngfile2="$pdb_dir/outer-$chainid-$resseq-rotate.png";
      $server_pngfile =$GLOBALS["server_neighborhood_temp"]."/$pdbid/outer-$chainid-$resseq.png";
      $server_pngfile2=$GLOBALS["server_neighborhood_temp"]."/$pdbid/outer-$chainid-$resseq-rotate.png";
      $zoom_extent=10;
      if(($temp_id>=10000 and $temp_id<=11000) or ($temp_id>=11009 and $temp_id<=19999)) {
        $mg_site ="$pdb_dir/inner-$chainid-$resseq.ent";
        $pngfile ="$pdb_dir/inner-$chainid-$resseq.png";
        $pngfile2="$pdb_dir/inner-$chainid-$resseq-rotate.png";
        $server_pngfile =$GLOBALS["server_neighborhood_temp"]."/$pdbid/inner-$chainid-$resseq.png";
        $server_pngfile2=$GLOBALS["server_neighborhood_temp"]."/$pdbid/inner-$chainid-$resseq-rotate.png";
        $zoom_extent=7;
      }
      if(!file_exists($pngfile) or !file_exists($pngfile2)) {
        if(!file_exists($pdb_dir))  { mkdir($pdb_dir); chmod($pdb_dir, 0777); } ;
        $this->fetch_pdbfile($pdbid);
#       if(!file_exists($pdbfile2)) { copy($pdbfile, $pdbfile2); } ;
        $coord_arr=$this->fetch_coord_arr($pdbid, $chainid, $resseq, $temp_id);
        if(!file_exists($mg_site)) {
          $this->generate_mgsite_fragment($pdbfile2, $mg_site, $chainid, $resseq, $coord_arr);
        }
        $this->generate_mgsite_thumbnail($mg_site, $pngfile, $pngfile2, $zoom_extent);
        chmod($pngfile, 0777);
        chmod($pngfile2, 0777);
      }
      $this->set('rep_thumbnail',$server_pngfile);
      $this->set('rep_thumbnail2',$server_pngfile2);
// End generating thumbnail
     } elseif (preg_match('/^\w\w\w\w$/', $temp_id)) {
      $this->set('summary', -1);
      $this->set('pdbfile_headline', $this->pdbheadline($temp_id));
      $this->paginate = array( 'Metalna' => array (
	'limit'      => 20,
	'fields'     => $this->site_fields_arr(),
	'conditions' => $bench.'pdbid = \''.$temp_id.'\'',
	'order'      => 'Metalna.sid asc'));
      $this->set('temp_id',$temp_id);
     } else {
      $hide_validation=1;
      $this->set('summary', 1);
      $this->Metalna->recursive = 0;
#     $this->Metalna->find('all',array(
#	'fields'=>array('Metalna.sid', 'Metalna.site_type', 'COUNT(*) as "Metalna__stype_cnt"'),
#	'group'=> array('Metalna.sid', 'Metalna.site_type'),
#	'conditions'=>array('Metalna.bench'=>'t')));
      $this->paginate = array( 'Metalna' => array (
 	'limit'      => 200,
#	'fields'     => array('Metalna.sid', 'conc_comma(distinct "Metalna"."site_type") as "Metalna__site_type"', 'COUNT(*) as "Metalna__stype_cnt"'),
 	'fields'     => array('Metalna.sid', 'Metalna.site_type', 'COUNT(*) as "Metalna__stype_cnt"'),
 	'group'      => array('Metalna.sid', 'Metalna.site_type'),
 	'conditions' => "$bench Metalna.sid >= 10000 and Metalna.sid <30000",
 	'order'      => 'Metalna.sid asc'));
     }
     $this->set('data', $this->paginate('Metalna'));
     $this->record_ip("visitors");
#    if (!empty($this->data)) {
#      echo "NOT EMPTY";
#    } else {
#      echo "No input data received!";
#    }
     $this->set('footer', $this->get_footer_text($hide_validation,1));
    }

    function view() {
//debug($this->params);
//echo count($this->params['pass']) . "<br/>";
//    var_dump($this->params);
      if(count($this->params["pass"]) == 3 || count($this->params["pass"])==4) {
        $viewer='jsmol';
        if(count($this->params["pass"])==4) { $viewer = $this->params["pass"][3]; } ;
        if($viewer != "jmol") { $viewer = 'jsmol'; } ;
        $this->set('molecule_viewer', $viewer);
        $pdbid=strtolower($this->params["pass"][0]);
        $chainid=$this->params["pass"][1];
        $resseq =$this->params["pass"][2];
        $viewer2="/metalnas/view/$pdbid/$chainid/$resseq/";
        if($viewer == "jsmol") { $viewer2 .= 'jmol/'; } ;
        $this->set('alternate_viewer', $viewer2);
#       if(preg_match('/^\w(\w\w)\w$/' ,$pdbid, $matches)) {$pdbid_middle = $matches[1]; } ;
#       $pdbfile =$GLOBALS["pdb_archive"]."/$pdbid_middle/pdb$pdbid.ent";
        $pdb_dir =$GLOBALS["neighborhood_temp"]."/$pdbid";
        $pdbfile2=$GLOBALS["neighborhood_temp"]."/$pdbid/pdb$pdbid.ent";
        $mg_site =$GLOBALS["neighborhood_temp"]."/$pdbid/outer-$chainid-$resseq.ent";
        $server_pdbfile2=$GLOBALS["server_neighborhood_temp"]."/$pdbid/outer-$chainid-$resseq.ent";
        $outer_coord_arr=$this->fetch_coord_arr($pdbid, $chainid, $resseq, 20000);
        if(!file_exists($pdb_dir))  { mkdir($pdb_dir); } ;
        $this->fetch_pdbfile($pdbid);
#       if(!file_exists($pdbfile2)) { copy($pdbfile, $pdbfile2); } ;
        if(!file_exists($mg_site))  { $this->generate_mgsite_fragment($pdbfile2, $mg_site, $chainid, $resseq, $outer_coord_arr); } ;
        $this->set('pdbid',            $pdbid);
#       $this->set('pdbfile',          $pdbfile);
        $this->set('pdb_dir',          $pdb_dir);
        $this->set('pdbfile2',         $pdbfile2);
        $this->set('mg_site',          $mg_site);
        $this->set('server_pdbfile2',  $server_pdbfile2);
        $this->set('chainid',          $chainid);
        $this->set('resseq',           $resseq);
        $this->set('pdbfile_headline', $this->pdbheadline($pdbid));
        $site_records = $this->Metalna->find('all',array(
          'fields'     => $this->site_fields_arr(),
          'conditions' => array('Metalna.pdbid'=>"$pdbid", 'Metalna.chainid'=>"$chainid", 'Metalna.resseq'=>"$resseq")));
        $this->set('site_record', $site_records[0]['Metalna']);
        if($site_records[0]['Metalna']['site_type']=="") {$site_classified=0;} else {$site_classified=1;};
        $this->set('footer', $this->get_footer_text($site_records[0]['Metalna']['bench'],$site_classified));
      } else {
        echo "Invalid calling data received!";
      }
    }

    function get_footer_text($hide_validation, $site_classified) {
      $html_string='<p>';
      if($hide_validation==0) { $html_string.='
<sup>#</sup> Validation parameters <i>P<sub>v</sub></i>, <i>P<sub>s</sub></i>, <i>P<sub>e</sub></i> are defined in the range of 0 to 1, with 0 indicating poorest reliability and higher value indicating a more reliable site<br>
<b><i>P<sub>v</sub></i></b> measures the agreement of the inner-sphere bond valence summation with the oxidation state of Mg<sup>2+</sup> (+2)<br>
<b><i>P<sub>s</sub></i></b> measures the geometrical symmetry of the ligands distribution around the Mg<sup>2+</sup> required for octahedral geometry<br>
<b><i>P<sub>e</sub></i></b> measures the agreement of the isotropic atomic displacement (B) factor and occupancy of the Mg<sup>2+</sup> compared to those of all atoms in its environment<br><p>'; };
      if($site_classified==1) {$html_string.='* Site type: String abbreviation of ligand composition in Mg<sup>2+</sup> coordination sphere, see details in table below
<table>
<tr><th rowspan=2 valign="middle" align="center">Abbreations<br>used for Mg<sup>2+</sup><br>"Site type"</th>
    <th>Mg<sup>2+</sup> inner-sphere ligands</th>
    <th><a href="http://en.wikipedia.org/wiki/Octahedral_molecular_geometry" target="new">Geometry</a> for inner-sphere O<sub>P</sub></th>
    <th>Mg<sup>2+</sup> outer-sphere moieties</th>
<tr><td valign="Middle" style="padding:6px">
<b>O<sub>P</sub></b> phosphate oxygen (OP1/OP2)<br>
<b>O<sub>R</sub></b> ribose oxygen (O2\'/O4\')<br>
 &nbsp;&nbsp;&nbsp;&nbsp; or oxygen bridging phosphate and ribose (O3\'/O5\')<br>
<b>O<sub>B</sub></b> nucleobase oxygen &nbsp;&nbsp;&nbsp;&nbsp; <b>N<sub>B</sub></b> nucleobase nitrogen
</td><td valign="middle" style="padding:6px">
<b><i>cis-</i></b> two O<sub>P</sub> ligands adopt <i>cis-</i> isoform<br>
<b><i>trans-</i></b> two O<sub>P</sub> ligands adopt <i>trans-</i> isoform<br>
<b><i>fac-</i></b> three O<sub>P</sub> ligands adopt <i>fac-</i> isoform<br>
<b><i>mer-</i></b> three O<sub>P</sub> ligands adopt <i>mer-</i> isoform
</td><td valign="middle" style="padding:12px">
<b>P<sub>out</sub></b> phosphate moiety<br>
<b>R<sub>out</sub></b> ribose moiety<br>
<b>B<sub>out</sub></b> nucleobase moiety
</td></tr></table>
<!-- <br>** STID: A five digits unique identifier for each site type --><br><br>'; };
      return $html_string;
    }

    function getBrowser()
    {
      $u_agent = $_SERVER['HTTP_USER_AGENT'];
      $bname = 'Unknown';
      $platform = 'Unknown';
      $version= "";
   
      //First get the platform?
      if (preg_match('/linux/i', $u_agent)) {
          $platform = 'linux';
      }
      elseif (preg_match('/macintosh|mac os x/i', $u_agent)) {
          $platform = 'mac';
      }
      elseif (preg_match('/windows|win32/i', $u_agent)) {
          $platform = 'windows';
      }
     
      // Next get the name of the useragent yes seperately and for good reason
      if(preg_match('/MSIE/i',$u_agent) && !preg_match('/Opera/i',$u_agent))
      {
          $bname = 'Internet Explorer';
          $ub = "MSIE";
      }
      elseif(preg_match('/Firefox/i',$u_agent))
      {
          $bname = 'Mozilla Firefox';
          $ub = "Firefox";
      }
      elseif(preg_match('/Chrome/i',$u_agent))
      {
          $bname = 'Google Chrome';
          $ub = "Chrome";
      }
      elseif(preg_match('/Safari/i',$u_agent))
      {
          $bname = 'Apple Safari';
          $ub = "Safari";
      }
      elseif(preg_match('/Opera/i',$u_agent))
      {
          $bname = 'Opera';
          $ub = "Opera";
      }
      elseif(preg_match('/Netscape/i',$u_agent))
      {
          $bname = 'Netscape';
          $ub = "Netscape";
      }
     
      // finally get the correct version number
      $known = array('Version', $ub, 'other');
      $pattern = '#(?<browser>' . join('|', $known) .
      ')[/ ]+(?<version>[0-9.|a-zA-Z.]*)#';
      if (!preg_match_all($pattern, $u_agent, $matches)) {
          // we have no matching number just continue
      }
     
      // see how many we have
      $i = count($matches['browser']);
      if ($i != 1) {
          //we will have two since we are not using 'other' argument yet
          //see if version is before or after the name
          if (strripos($u_agent,"Version") < strripos($u_agent,$ub)){
              $version= $matches['version'][0];
          }
          else {
              $version= $matches['version'][1];
          }
      }
      else {
          $version= $matches['version'][0];
      }
     
      // check if we have a number
      if ($version==null || $version=="") {$version="?";}
     
      return array(
          'userAgent' => $u_agent,
          'name'      => $bname,
          'version'   => $version,
          'platform'  => $platform,
          'pattern'   => $pattern
      );
    } 

    function insert_sqlcommand($filename,$sqlcommand) {
      $sqlfile=$GLOBALS["neighborhood_temp"]."/$filename";
      unlink($sqlfile);
      $fd = fopen($sqlfile, "w") or exit("Unable to open file $sqlfile!");
      fwrite($fd, "$sqlcommand;");
      fclose($fd);
      system("psql -htomis -Usg_display neighborhood12-metalna_Dec12 < $sqlfile > /dev/null",$retval);
      return $retval;
    }

    function update_identities_browsers($ip) {
      $neighborhood_session=$GLOBALS["neighborhood_temp"];
      $browser_id=-1;
      $identity_arr = $this->Metalna->query("select ip from identities where cast(ip as text) like '$ip/%'");
      if(!count($identity_arr)) {
        $host = gethostbyaddr($ip);
        if (!empty($_SERVER['REMOTE_HOST'])) { $host=$_SERVER['REMOTE_HOST']; }
        if ($host == "") {$host = "NULL";} else {$host="'".$host."'";}
        $city="NULL";
        $country="NULL";
        $latitude="NULL";
        $longitude="NULL";
        $source="http://api.hostip.info/get_html.php?ip=$ip&position=true";
        $geolocation="GEOLOCATION";
#       $last_line = system("wget -q --passive-ftp --waitretry=10 -N -P $neighborhood_session -O $geolocation \"$source\" &> $neighborhood_session/$geolocation.log",$retval);
        $geofile=$neighborhood_session."/$geolocation";
        $last_line = system("wget -q --passive-ftp --waitretry=10 -N -O $geofile \"$source\" &> $neighborhood_session/$geolocation.log",$retval);
        chmod($geofile, 0777);
        if(file_exists($geofile)) {
          $fd = fopen($geofile, "r") or exit("Unable to open file $geofile!");
          while(!feof($fd)) {
            $geoline=fgets($fd);
            if (preg_match("/^Country:\s*.*\((\w\w)/", $geoline, $matches)) {
              $country="'".$matches[1]."'";
            } elseif (preg_match("/^City:\s*(\S.*\S)\s*$/", $geoline, $matches)) {
              $city="'".$matches[1]."'";
            } elseif (preg_match("/^Latitude:\s*(-?\d+\.\d+)\s*$/", $geoline, $matches)) {
              $latitude=$matches[1];
            } elseif (preg_match("/^Longitude:\s*(-?\d+\.\d+)\s*$/", $geoline, $matches)) {
              $longitude=$matches[1];
            }
          }
          fclose($fd);
        }
        $this->insert_sqlcommand("update_identity.sql","INSERT INTO identities (ip,host,city,country,latitude,longitude) VALUES ('$ip',$host,$city,$country,$latitude,$longitude)");
      }
      $ua=$this->getBrowser();
      $browser_os=$ua['platform'];
      $browser_name=$ua['name'];
      $browser_version=$ua['version'];
      $browser_arr = $this->Metalna->query("select browser_id from browsers where cast(ip as text) like '$ip/%' and browser_os='$browser_os' and browser_name='$browser_name' and browser_version='$browser_version'");
      if(!count($browser_arr)) {
        $browser_id_arr = $this->Metalna->query("select browser_id from browsers where cast(ip as text) like '$ip/%'");
        if(count($browser_id_arr)) {
          $browser_max_arr = $this->Metalna->query("select max(browser_id) as last_browser_id from browsers where cast(ip as text) like '$ip/%'");
          $browser_id=$browser_max_arr[0][0]['last_browser_id']+1;
        } else {
          $browser_id=0;
        }
        $this->insert_sqlcommand("update_browser.sql","INSERT INTO browsers (ip,browser_id,browser_os,browser_name,browser_version) VALUES ('$ip',$browser_id,'$browser_os','$browser_name','$browser_version')");
      } else {
        $browser_id=$browser_arr[0][0]['browser_id'];
      }
      return $browser_id;
    }

    function is_heping($ip) {
      if($ip == "172.26.11.206") {
        return 1;
      } else {
        return 0;
      }
    }

    function record_ip($tablename) {
      $ip=$_SERVER['REMOTE_ADDR'];
      if(! $this->is_heping($ip)) {
        $browser_id=$this->update_identities_browsers($ip);
        $this->insert_sqlcommand("record_ip.sql","INSERT INTO $tablename (ip,browser_id) VALUES ('$ip',$browser_id)");
      }
    }

   }
