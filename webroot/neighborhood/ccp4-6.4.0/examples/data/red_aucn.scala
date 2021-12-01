data_DMSO[red_aucn]
_entry.id                 DMSO
_diffrn.id                red_aucn
_audit.creation_date      2002-11-06T14:54:00+00:00
_software.classification 'data reduction'
_software.contact_author 'P.R. Evans'
_software.contact_author_email pre@mrc-lmb.cam.ac.uk
_software.description 'scale together multiple observations of reflections'
_software.name Scala
_software.version 'CCP4_3.1.4  22/04/2002'

_cell.length_a         88.910
_cell.length_b         88.910
_cell.length_c        229.220
_cell.angle_alpha      90.000
_cell.angle_beta       90.000
_cell.angle_gamma      90.000

_Symmetry.Int_Tables_number       91
_Symmetry.space_group_name_H-M  'P4122     '

_reflns.data_reduction_method
; data reduction merge and scaling used SCALA (CCP4)
;

_reflns.merge_reject_criterion
;  sd multiplier for max deviation from weighted mean I :
     sdref =    6.000
   special value for reflections measured twice :
     sdrej2 =    6.000
 The test for outliers is as follows:
(1) if there are 2 observations (left), then
 (a) for each observation Ihl, test deviation
      Delta(hl) = |Chi|
 |Ihl - ghl Iother| / sqrt[sigIhl**2 + (ghl*sdIother)**2]
   against sdrej2, where Iother = the other observation
 (b) if either Delta(hl) > sdrej2, then
     1. in scaling, reject reflection. Or:
     2. in merging, keep both.
(2) if there 3 or more observations left, then
 (a) for each observation Ihl,
  1. calculate weighted mean of all other observations 
     <I>n-1 & its sd(<I>n-1)
  2. deviation   Delta(hl) =
  |Ihl - ghl <I>n-1>| / sqrt[sigIhl**2 + (ghl*sd(<I>n-1))**2]
  3. find largest deviation max|Delta(hl)|
  4. count number of observations for which 
        |Delta(hl)|.ge.0  (ngt), & 
    for which |Delta(hl)| .lt. 0 (nlt)
 (b)  if max|Delta(hl)| > sdrej, 
       then reject one observation, but which one?
  1. if ngt == 1 .or. nlt == 1, then one 
     observation is a long way from the others and this one is rejected
  2. else reject the one with the worst deviation max|Delta(hl)|
(3)   iterate from beginning
;

_reflns.overall_d_res_low                  35.36
_reflns.overall_d_res_high                  3.00
_reflns.overall_number_observations          9478

_diffrn_reflns.d_res_low                35.36
_diffrn_reflns.d_res_high                3.00
_diffrn_reflns.number_measured_all         424
_diffrn_reflns.number_unique_all           204
_diffrn_reflns.number_centric_all            7
_diffrn_reflns.number_anomalous_all        2346
_diffrn_reflns.Rmerge_I_anomalous_all    0.048
_diffrn_reflns.anom_diff_percent_meas   36.77
_diffrn_reflns.Rmerge_I_all             0.042
_diffrn_reflns.meanI_over_sigI_all       10.6008
_diffrn_reflns.meanI_over_sd_all         13.5573
_diffrn_reflns.mean_fract_bias             0.0481
_diffrn_reflns.num_fract_bias_in_mean         361

_diffrn_reflns.percent_possible_all     36.80
_diffrn_reflns.multiplicity              1.39
_diffrn_reflns.PCV                       0.06
_diffrn_reflns.PCV_mean                  0.07
_diffrn_reflns.Rmeas                     0.06
_diffrn_reflns.Rmeas_mean                0.07
_diffrn_reflns.min_intensity         -248.21
_diffrn_reflns.max_intensity        42797.20
_diffrn_reflns.num_fully_measured                    284
_diffrn_reflns.Intensity_rms_fully_recorded      7309.47
_diffrn_reflns.mean_scatter_over_sd_full            0.16
_diffrn_reflns.sigma_scatter_over_sd_full           3.05
_diffrn_reflns.num_partials_measured                     140
_diffrn_reflns.Intensity_rms_partially_recorded      5651.04
_diffrn_reflns.mean_scatter_over_sd_part               -0.32
_diffrn_reflns.sigma_scatter_over_sd_part               0.98



loop_
_reflns_shell.d_res_low
_reflns_shell.d_res_high
_reflns_shell.number_measured_all
_reflns_shell.number_unique_all
_reflns_shell.number_centric_all
_reflns_shell.Rmerge_I_all
_reflns_shell.Rmerge_I_all_cumulative
_reflns_shell.meanI_over_sigI_all
_reflns_shell.meanI_over_sd_all
_reflns_shell.percent_possible_all
_reflns_shell.cum_percent_possible_all
_reflns_shell.multiplicity
_reflns_shell.PCV
_reflns_shell.PCV_mean
_reflns_shell.Rmeas
_reflns_shell.Rmeas_mean
_reflns_shell.num_fract_bias_in_mean
_reflns_shell.mean_fract_bias
_reflns_shell.number_anomalous_all
_reflns_shell.Rmerge_I_anomalous_all
_reflns_shell.anom_diff_percent_meas
   35.36    9.49       146      66       3  0.05  0.05   9.88  20.53  29.27  29.27   1.80  0.07  0.08  0.07  0.06      33   0.04       62   0.04  39.24
    9.49    6.71        56      28       0  0.03  0.04  21.78  19.31  35.84  33.52   1.45  0.05  0.04  0.04  0.05      25   0.00      141   0.04  39.50
    6.71    5.48        10       5       1  0.02  0.04  33.44  16.69  37.48  35.32   1.34  0.05  0.03  0.03  0.05      21   0.05      166   0.04  34.44
    5.48    4.74        14       7       0  0.04  0.04  17.69  17.30  37.90  36.22   1.34  0.05  0.05  0.05  0.05      23   0.07      202   0.03  34.65
    4.74    4.24        18       9       1  0.04  0.04  10.13  17.59  37.29  36.53   1.35  0.06  0.06  0.06  0.06      30   0.05      224   0.04  34.41
    4.24    3.87        34      17       0  0.03  0.04  27.50  15.74  37.03  36.65   1.38  0.06  0.04  0.04  0.06      38   0.06      267   0.04  37.29
    3.87    3.59        32      16       2  0.03  0.04  24.54  13.65  37.82  36.89   1.38  0.07  0.04  0.04  0.07      52   0.04      300   0.05  37.88
    3.59    3.35        37      18       0  0.04  0.04  14.15  11.74  36.25  36.77   1.37  0.09  0.06  0.05  0.08      44   0.07      300   0.06  36.54
    3.35    3.16        34      17       0  0.06  0.04  13.76   9.04  37.04  36.81   1.38  0.11  0.08  0.08  0.11      46   0.06      329   0.08  37.26
    3.16    3.00        43      21       0  0.06  0.04   7.69   7.47  36.74  36.80   1.39  0.14  0.08  0.08  0.13      49   0.08      355   0.10  37.85
