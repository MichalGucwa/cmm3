#! /usr/bin/env python

# Script to run Emma (Euclidian Model Matching) program from the
# command line using the input files used by COMPARE
#
# Usage:
#
# python emma_nantmrf.py "33.95, 33.95, 74.82, 90, 90, 90" "P 43 21 2" model trial
#

from cctbx import euclidean_model_matching as emma
from cctbx import sgtbx
from cctbx import uctbx
from cctbx import crystal
import sys


def read_model(file_name):
  error_coordinate_line = "Corrupt coordinate line in model file: %s"
  lines = open(file_name).readlines()
  positions = []
  for line in lines:
    flds = line.split()
    flds = flds[1:4]
    if (len(flds) != 3):
      raise RuntimeError(error_coordinate_line % line.rstrip())
    try:
      site = [float(x) for x in flds]
    except ValueError:
      raise RuntimeError(error_coordinate_line % line.rstrip())
    positions.append(emma.position(
      label="Site%02d" % (len(positions)+1),
      site=site))
  return positions

def read_trial(file_name):
  error_coordinate_line = "Corrupt coordinate line in trial file: %s"
  lines = open(file_name).readlines()
  positions = []
  for line in lines:
    flds = line.split()
    if (len(flds) == 1):
      return positions
    flds = flds[1:4]
    if (len(flds) != 3):
      raise RuntimeError(error_coordinate_line % line.rstrip())
    try:
      site = [float(x) for x in flds]
    except ValueError:
      raise RuntimeError(error_coordinate_line % line.rstrip())
    positions.append(emma.position(
      label="Site%02d" % (len(positions)+1),
      site=site))
  return positions

def run(tolerance=3,
        models_are_diffraction_index_equivalent=00000,
        break_if_match_with_no_singles=0001):
  assert len(sys.argv) == 5, \
    "usage: python emma_nantmrf.py unit_cell space_group file_1 file_2"
  unit_cell = uctbx.unit_cell(sys.argv[1])
  space_group_info = sgtbx.space_group_info(symbol=sys.argv[2])
  positions_1 = read_model(file_name=sys.argv[3])
  positions_2 = read_trial(file_name=sys.argv[4])
  crystal_symmetry = crystal.symmetry(
    unit_cell=unit_cell,
    space_group_info=space_group_info)
  special_position_settings = crystal.special_position_settings(
    crystal_symmetry=crystal_symmetry)
  model_1 = emma.model(
    special_position_settings=special_position_settings,
    positions=positions_1)
  model_2 = emma.model(
    special_position_settings=special_position_settings,
    positions=positions_2)
  model_1.show("Reference model")
  model_2.show("Second model")
  model_matches = emma.model_matches(
    model1=model_1,
    model2=model_2,
    tolerance=tolerance,
    models_are_diffraction_index_equivalent
    =models_are_diffraction_index_equivalent,
    break_if_match_with_no_singles=break_if_match_with_no_singles)
  if (model_matches.n_matches() == 0):
    print "No matches."
    print
  else:
    for match in model_matches.refined_matches:
      print "." * 79
      print
      match.show()
      
if (__name__ == "__main__"):
  run()
