<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html><head> 
  <title>Center for Structural Genomics of Infectious Diseases</title>
  <style type="text/css">
    #resizable { width: 700px; height: 500px; }
  </style>
  <link href="csgid.css" rel="stylesheet" type="text/css" media="all"> 
  <link href="http://www.csgid.org/metal_sites/jquery-ui.css" rel="stylesheet" type="text/css"/> 
  <?php 
    if($molecule_viewer == "jmol") {
      # echo $javascript->link(array('http://www.csgid.org/metal_sites/Jmol/Jmol.js'), false);
      echo $javascript->link(array('http://www.csgid.org/metal_sites/Jmol/Jmol.js'), false);
    } else {
      echo $javascript->link(array('http://www.csgid.org/metal_sites/JSmol/jsmol/JSmol.min.js'), false);
      //<script type="text/javascript" src="http://www.csgid.org/metal_sites/JSmol/jsmol/JSmol.min.js"></script>
  ?>
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
      j2sPath: "/metal_sites/JSmol/jsmol/j2s",
      readyFunction: jmol_isReady,
      script: "set antialiasDisplay;load <?echo $server_pdbfile2; ?>",
      disableJ2SLoadMonitor: true,
      disableInitialConsole: true,
      allowJavaScript: true
    }
      </script>
  <?php }
      echo $javascript->link(array('http://www.csgid.org/metal_sites/jquery.js'), false);
      echo $javascript->link(array('http://www.csgid.org/metal_sites/jquery-ui.js'), false); ?>
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
  </script>
</head><body>

<?php if($molecule_viewer == "jmol") { ?>
  <SCRIPT>
    jmolInitialize("/metal_sites/Jmol")
  </SCRIPT>
<?php } ?>

<?php
function format_sts_str($sts) {
  $search  = array('cis', 'trans', 'fac', 'mer', 'OP', 'OR', 'OB', 'NB', 'PO', 'BO', 'RO');
  $replace = array('<i>cis</i>', '<i>trans</i>', '<i>fac</i>', '<i>mer</i>', 
                   'O<sub>P</sub>', 'O<sub>R</sub>', 'O<sub>B</sub>', 'N<sub>B</sub>', 'P<sub>out</sub>', 'B<sub>out</sub>', 'R<sub>out</sub>');
  return str_replace($search, $replace, $sts);
}

function other_site_type_text($stid) {
  if    ($stid==99999) { return "Mg<sup>2+</sup> not bound by RNA"; }
  elseif($stid==19999) { return "other RNA-inner types"; }
  elseif($stid==29999) { return "other RNA-outer types"; }
  elseif($stid==30000) { return "Mg<sup>2+</sup> bound by non-RNA"; }
  elseif($stid==40000) { return "poly-nuclear Mg<sup>2+</sup> site"; }
  else                 { return "undefined text in other_site_type_text"; }
}

function jmol_button_script($viewer, $label, $script) {
  echo "<input type=\"button\" value=\"$label\" onclick=\"";
  if($viewer=="jmol") {
    echo "javascript:jmolScript('$script;')";
  } else {
    echo "javascript:Jmol.script(jmolApplet0,'$script')";
  }
  echo "\">";
}

function jmol_label_script($viewer, $label, $script) {
  if($viewer=="jmol") {
    echo "<span style=\"color:#074a7e; text-decoration: none; cursor: pointer\" onclick='jmolScript(\"$script;\");'>$label</span>";
  } else {
    echo "<a href=\"javascript:Jmol.script(jmolApplet0,'$script')\">$label</a>";
  }
}


  echo "<center><b>Mg<sup>2+</sup> site $chainid$resseq in </b>$pdbfile_headline<br>Viewer options: (";
  if($molecule_viewer=="jmol") {
    echo "<b><i>Jmol</i></b> | <b><i>".$html->link("JSmol", "$alternate_viewer")."</i></b>";
  } else {
    echo "<b><i>".$html->link("Jmol", "$alternate_viewer")."</i></b> | <b><i>JSmol</i></b>";
  }
  echo ") | Close this window to return to the list of Mg<sup>2+</sup> binding sites being investigated</center>";

  if(!file_exists($pdbfile2)) {
    echo "<H3>Invalid PDB file ~ [".$pdbfile2."]</H3>";
  } else {
?>


<table>
<!-- <tr><td colspan=2 bgcolor="#FFCCCC">
<b>Warning: Some structures, such as ribosomes, can take a few minutes to load.  Please be patient.  If you see a message regarding a script that may have stopped responding, please select "Don't ask me again" and "Continue." You should wait until a close up of the site is displayed.</b>
</td></tr> -->
<tr><td>

<div id="resizable">
<script>make_jmol_resizable();</script>
<?php
  $init_script = "zoom 200; wireframe off; cpk off; set measure angstroms; background [xCBCBCB]; ";
  $number_binding_sites=1;
  $resseq_colon_chainid=$resseq.':'.$chainid;
  $atomname_ion_nodash ='MG';
  $cutoff=3.18; $first_cutoff=3.18;
  $id_binding_center="met".$number_binding_sites;
  $id_binding_water="wat".$number_binding_sites;
  $id_binding_env ="close".$number_binding_sites;
  $id_binding_env2="far".$number_binding_sites;
  $id_binding_site ="site".$number_binding_sites;
  if($number_binding_sites!=0) {
    $jmol_site_definition="";
    $jmol_list_sites="";
    $jmol_list_centers="";
    $jmol_list_envs="";
    $jmol_measure_allconnected="";
    $jmol_site_definition.="define $id_binding_center $resseq_colon_chainid.$atomname_ion_nodash; ";
    $jmol_site_definition.="define $id_binding_water within (2.58, $id_binding_center) and water and not $id_binding_center; ";
    $jmol_site_definition.="define $id_binding_env2 (within (group, within (4.0, ($id_binding_center or $id_binding_water))) and not $id_binding_center); ";
    $jmol_site_definition.="define $id_binding_env (within ($cutoff, $id_binding_center) and not elemno=1 and not elemno=6 and not $id_binding_center); ";
    $jmol_site_definition.="define $id_binding_site within (group, within (4.0, ($id_binding_center or $id_binding_water))); ";
    $jmol_site_definition.="connect ($id_binding_center) ($id_binding_env and not _C) partial 1.1; ";
    if ($jmol_list_sites!="")   {$jmol_list_sites.=" or ";};
    if ($jmol_list_centers!="") {$jmol_list_centers.=" or ";};
    if ($jmol_list_envs!="")    {$jmol_list_envs.=" or ";};
    $jmol_list_sites.=$id_binding_site;
    $jmol_list_centers.=$id_binding_center;
    $jmol_list_envs.=$id_binding_env2;
    $jmol_measure_allconnected.="measure allconnected ($id_binding_center)($id_binding_env); ";
    $init_script .= $jmol_site_definition;
    $init_script .= "select $jmol_list_sites; cpk 10%; hide (waters and not selected); ";
    $init_script .= "select (($jmol_list_envs) and not water); wireframe 0.10; ";
    $init_script .= "define has_label within ($first_cutoff, $jmol_list_centers); ";
    $init_script .= "select has_label; wireframe 0.02; set fontsize 10; ";
    $init_script .= "select has_label and not :#; label %c%r:%n; set labeloffset 10 4; ";
    $init_script .= "select has_label and :#; label sym-%r:%n; set labeloffset 13 0; ";
    $init_script .= "select $jmol_list_centers; label %c%r:%e; color label black; set fontsize 15; set labeloffset 10 4; ";
    $init_script .= "center met1; restrict site1; slab off; set antialiasDisplay off; $jmol_measure_allconnected";
    $init_script .= "select elemno=7; color [x085591]; select elemno=8; color [x931212]; ";
    $init_script .= "select not hydrogen; set hbondsRasmol FALSE; calculate HBONDS; hbonds 0.03; color HBONDS ENERGY; color HBONDS [128,209,227]; ";
  } else {
    $init_script .= "define temp selected; select *; cartoon on; color cartoon monomer; select temp; center *; zoom 100; slab off; ";
  }
  if($molecule_viewer == "jmol") { ?>
    <span id="jmolApplet1">
      <script>jmolApplet(["99.0%","98.7%"],"load <?echo $server_pdbfile2;?>; <?echo $init_script;?>");</script>
    </span>
<?php } else { ?>
    <script>
      jmolApplet0 = Jmol.getApplet("jmolApplet0", Info)
      Jmol.script(jmolApplet0,'<?echo $init_script;?>');
      var lastPrompt=0;
    </script>
<?php } ; ?>
</div>

<?php if($molecule_viewer == "jmol") { ?>
  <i>Jmol</i>: an open-source Java viewer for chemical structures in 3D <a href="http://www.jmol.org/" target="new">http://www.jmol.org/</a>
<?php } else { ?>
  <i>JSmol</i>: HTML5 canvas version of the <a href="http://www.jmol.org/" target="new"><i>Jmol</i></a> molecule viewer <a href="http://chemapps.stolaf.edu/jmol/jsmol/jsmol.htm" target="new">http://chemapps.stolaf.edu/jmol/jsmol/jsmol.htm</a>
<?php } ?>
    </td>
    <td><table>
      <tr><th colspan=2 align="center"><b>Binding environment of Mg<sup>2+</sup> <?echo "$chainid$resseq"; ?></b></th></tr>
      <tr><td style="padding:1px" colspan=2>
       <table>
        <?php if($site_record['site_type']!="") { ?>
<!--
         <tr>
          <td style="padding:2px" colspan=2 align="center"><b>STID</b>**</td>
          <td style="padding:2px"><?echo $site_record['sid']; ?></td>
         </tr>
-->
         <tr>
          <td style="padding:2px" colspan=2 align="center"><h4>Site type*</h4></td>
          <td style="padding:2px"><h4><?echo format_sts_str($site_record['site_type']); ?></h4></td>
         </tr>
        <?php } else { ?>
         <tr><td style="padding:2px" colspan=3 align="center"><b><?echo other_site_type_text($site_record['sid']); ?></b></td></tr>
        <?php } ?>
        <?php if($site_record['bench']==1) { $spacing_string = "<tr height=5><td colspan=2></td></tr>"; ?>
          <tr><th rowspan=5 valign="middle">Inner<br>sphere</th>
              <td style="border-top:thin solid;border-right:thin solid;padding:0px"><b>O<sub>P</sub></b></td> <td style="border-top:thin solid;border-right:thin solid;padding:1px"><?echo $site_record['isp']; ?></td></tr>
          <tr><td style="border-right:thin solid;padding:0px"><b>O<sub>R</sub></b></td>                       <td style="border-right:thin solid;padding:1px"><?echo $site_record['isr']; ?></td></tr>
          <tr><td style="border-right:thin solid;padding:0px"><b>O<sub>B</sub>+N<sub>B</sub></b></td>         <td style="border-right:thin solid;padding:1px"><?echo $site_record['isb']; ?></td></tr>
          <tr><td style="border-right:thin solid;padding:0px"><b>Water</b></th>                               <td style="border-right:thin solid;padding:1px"><?echo $site_record['isw']; ?></td></tr>
          <tr><td style="border-right:thin solid;padding:0px"><b>Other</b></th>                               <td style="border-right:thin solid;padding:1px"><?echo $site_record['iso']; ?></td></tr>
          <tr><th rowspan=3 valign="middle">Outer<br>sphere</th>
              <td style="border-top:thin solid;border-right:thin solid;padding:0px"><b>P<sub>out</sub></b></td>
              <td style="border-top:thin solid;border-right:thin solid;padding:1px"><?echo $site_record['osp']; ?></td></tr>
          <tr><td style="border-right:thin solid;padding:0px"><b>R<sub>out</sub></b></td>
              <td style="border-right:thin solid;padding:1px"><?echo $site_record['osr']; ?></td></tr>
          <tr><td style="border-bottom:thin solid;border-right:thin solid;padding:0px"><b>B<sub>out</sub></b></td>
              <td style="border-bottom:thin solid;border-right:thin solid;padding:1px"><?echo $site_record['osb']; ?></td></tr>
        <?php } else { $spacing_string = "<tr height=25><td colspan=2>&nbsp;</td></tr>";
           $pv=sprintf('%6.2f',$site_record['pv']);
           $ps=sprintf('%6.2f',$site_record['ps']);
           $pe=sprintf('%6.2f',$site_record['pe']);
           ?>
          <tr><td style="padding:3px" colspan=2 align="center"><b>Coordination Number</b></td>     <td style="padding:3px"><?echo $site_record['cn']; ?></td></tr>
          <tr><td style="padding:3px" colspan=2 align="center"><b><i>P<sub>v</sub></i></b> <sup>#</sup></td> <td style="padding:3px"><?echo $pv; ?></td></tr>
          <tr><td style="padding:3px" colspan=2 align="center"><b><i>P<sub>s</sub></i></b> <sup>#</sup></td> <td style="padding:3px"><?echo $ps; ?></td></tr>
          <tr><td style="padding:3px" colspan=2 align="center"><b><i>P<sub>e</sub></i></b> <sup>#</sup></td> <td style="padding:3px"><?echo $pe; ?></td></tr>
        <?php } ?>
       </b></td>
      </tr></table></td></tr>
      <?echo $spacing_string; ?>
      <tr><th colspan=2 align="center">Mouse click action:</th></tr>
      <tr align="CENTER" valign="BOTTOM"><td align="LEFT" colspan=2>
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
          Right-Click for Jmol's context menu
<?php if($molecule_viewer != "jmol") { echo "<br><a href=\"javascript:Jmol.script(jmolApplet0,'console')\">Access console here</a>"; } ?>
          </td></tr></table>
          </td></tr>

      <tr><td align="left" valign="middle" colspan=2>
<?php
jmol_button_script($molecule_viewer, " Zoom In ",  "Zoom In"); echo "&#09;";
jmol_button_script($molecule_viewer, " Zoom Out ", "Zoom Out"); echo "&#09;";
jmol_button_script($molecule_viewer, "  Center  ", "center $id_binding_env2; zoom 1000; slab off"); echo "&#09;";
jmol_button_script($molecule_viewer, "  Reset  ",  "center $id_binding_center; zoom 1800; slab off");
?>
        </td></tr>

      <?echo $spacing_string; ?>
      <tr><th colspan=2 align="center">Additional controls:</th></tr>
      <tr><TD align="right">
      Residue/moiety Name:<br>
      Metal Distances:<br>
      Nucleic Acid Cartoon:<br>
      Spin:<br>
      Antialiasing:</TD><TD>

<?php
      jmol_label_script($molecule_viewer, "On",  "define temp selected; select *.C4; label %c%r:%n:Base; color label blue; select *.P; label %c%r:%n:Phosphate; color label orangered; select *.O4\'; label %c%r:%n:Ribose; select has_label and not :#; label %c%r:%n; select has_label and :#; label sym-%r:%n; select $jmol_list_centers; label %c%r:%e; color label black; select temp"); echo "&#09;";
      jmol_label_script($molecule_viewer, "Off", 'select *; label off'); echo "<br>";

      jmol_label_script($molecule_viewer, "On",  "$jmol_measure_allconnected set measure angstroms"); echo "&#09;";
      jmol_label_script($molecule_viewer, "Off", 'measures off'); echo "<br>";

      jmol_label_script($molecule_viewer, "On",  'define temp selected; select *; cartoon on; color cartoon monomer; select temp'); echo "&#09;";
      jmol_label_script($molecule_viewer, "Off", 'define temp selected; select *; cartoon off; select temp'); echo "<br>";

      jmol_label_script($molecule_viewer, "On",  'spin on'); echo "&#09;";
      jmol_label_script($molecule_viewer, "Off", 'spin off'); echo "<br>";

      jmol_label_script($molecule_viewer, "On",  'set antialiasDisplay true'); echo "&#09;";
      jmol_label_script($molecule_viewer, "Off", 'set antialiasDisplay false');
?>
      </td></tr>
    </table>
    </td>
  </tr>
</table>

<?php echo $footer;
      echo '<hr><br>Maintained by: Heping Zheng &lt;<a href="mailto:dust@iwonka.med.virginia.edu">dust@iwonka.med.virginia.edu</a>&gt;';
} ?>

</body></html>
