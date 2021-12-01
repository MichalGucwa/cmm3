//     jmolApplet0 = Jmol.getApplet("jmolApplet0", Info);
//     Jmol.script(jmolApplet0,'
// echo "zoom 1800; wireframe off; cpk off; set measure angstroms; background [xCBCBCB]; ";
// if($number_binding_sites!=0) {
//   echo $jmol_site_definition;
//   echo "select $jmol_list_sites; cpk 10%; hide (waters and not selected); ";
//   echo "select (($jmol_list_envs) and not water); wireframe 0.10; ";
//   echo "define has_label within ($first_cutoff, $jmol_list_centers); ";
//   echo "select has_label; wireframe 0.02; set fontsize 20; ";
//   echo "select has_label and not :#; label %c%r:%n; set labeloffset 10 4; ";
//   echo "select has_label and :#; label sym-%r:%n; set labeloffset 13 0; ";
//   echo "select $jmol_list_centers; label %c%r:%e; color label black; set fontsize 20; set labeloffset 10 4; ";
//   echo "center met1; restrict site1; slab on; slab 55; set antialiasDisplay on; $jmol_measure_allconnected";
//   echo "select elemno=7; color [x085591]; select elemno=8; color [x931212]; ";
// } else {
//   echo "define temp selected; select *; cartoon on; color cartoon monomer; select temp; center *; zoom 100; slab off; ";}');

var NGLVIEWER = NGLVIEWER || (function(){

  var _args = {}; // private

  return {
          init : function(Args) {
              _args = Args;
              // some other initialising
          },
          executeNglViewer : function() {

            var mg_sites_js = _args[0]; //<?=json_encode($mg_sites)?>;
            var pdb_path = _args[1]; //<?=$mg_pdb_path?>
            var file_fo = _args[2]; //<?php echo json_encode($mg_fo_path)?>;
            var file_2fo = _args[3]; //<?php echo json_encode($mg_2fo_path)?>;
            var cur_site = mg_sites_js[0];

            //zaczynamy zabawea
            document.addEventListener("DOMContentLoaded", function () {

              var stage = new NGL.Stage("resizable");
              stage.handleResize();

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


              function loadNGL(stage, current_site){
                stage.removeAllComponents();
                var repre_main = "ball+stick";

                //main protein
                stage.loadFile(pdb_path).then( function (o) {

                  // if (!metal){ // It can be added that if there is no metal site in the pdb file, we can just display the protein cartoon
                  //   o.addRepresentation("cartoon")
                  //   o.autoView()
                  // }
                  // else {} // we can then put the all code below to the else statement

                  var selection = current_site;
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
                  var selection_metal = new NGL.Selection( selection );
                  var atomSet1 = o.structure.getAtomSetWithinSelection( selection_metal, radius_ligands );
                  var atomSet2 = o.structure.getAtomSetWithinGroup( atomSet1 );


                  //main
                  var repre_main = "ball+stick";
                  o.addRepresentation(repre_main, {
                    sele: atomSet2.toSeleString() + " and " + selection,
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
                    sele: atomSet2.toSeleString() + " and not water and not ion and not protein and not " + selection,
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
                    labelSize: 0.7,
                    scale: 0.2,
                    color: "white",
                    type: "",
                    name: "dist",
                    visible: distCheckbox.checked
                  })

                  var center = o.getCenter(selection);
                  stage.animationControls.zoomMove(center, -20, 0);
                  // o.autoView()
                });
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
              };

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
              }, { top: "71px", left: "3px" , color: "black"})
              addElement(all_licoriceCheckbox)

              addElement(createElement("span", {
                innerText: "All: Licorice"
              }, { top: "73px", left: "21px" , color: "white"}))


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
              }, { top: "89px", left: "21px" , color: "white"}))

              let pol_arr = []
              for (i=0; i<mg_sites_js.length;i++){
                pol_arr.push([mg_sites_js[i],mg_sites_js[i]])
              }

              var polymerSelect2 = createSelect(pol_arr, {
                onchange: function (e) {
                  cur_site = e.target.value;
                  loadNGL(stage, e.target.value);
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

              loadNGL(stage, cur_site);

              var createSiteLinks = function(site){
                var parts = (site.split('.')[0]).split(":");
                var reversed = parts[1] + ":" + parts[0]

                var button = document.createElement('a');
                button.href = "javascript:void(0)";
                button.innerHTML = reversed;
                button.id = site;
                button.addEventListener('click', function() {
                  cur_site = site;
                  loadNGL(stage, site);
                }, false);
                document.getElementById(reversed).appendChild(button);
              };
              mg_sites_js.forEach(createSiteLinks);
            });
            var lastPrompt=0; // What is it? To clean up?
        }
  };
}());
