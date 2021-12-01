#ifndef _H_ATOMINFO
#define _H_ATOMINFO

#include "util.h"
#include "main.h"

#define ELEM_GROUP_undef      0
#define ELEM_GROUP_IA         1
#define ELEM_GROUP_IIA        2
#define ELEM_GROUP_IIIA       3
#define ELEM_GROUP_IVA        4
#define ELEM_GROUP_VA         5
#define ELEM_GROUP_VIA        6
#define ELEM_GROUP_VIIA       7
#define ELEM_GROUP_VIIIA      8
#define ELEM_GROUP_LANTHANIDE 9
#define ELEM_GROUP_ACTINIDE  10
#define ELEM_GROUP_IB        11
#define ELEM_GROUP_IIB       12
#define ELEM_GROUP_IIIB      13
#define ELEM_GROUP_IVB       14
#define ELEM_GROUP_VB        15
#define ELEM_GROUP_VIB       16
#define ELEM_GROUP_VIIB      17
#define ELEM_GROUP_VIIIB     18
#define ELEM_GROUP_max       19

#define AN_undef -1
#define AN_H     1
#define AN_He    2
#define AN_Li    3
#define AN_Be    4
#define AN_B     5
#define AN_C     6
#define AN_N     7
#define AN_O     8
#define AN_F     9
#define AN_Na   11
#define AN_Mg   12
#define AN_Si   14
#define AN_P    15
#define AN_S    16
#define AN_Cl   17
#define AN_K    19
#define AN_Ca   20
#define AN_Mn   25
#define AN_Fe   26
#define AN_Co   27
#define AN_Ni   28
#define AN_Cu   29
#define AN_Zn   30
#define AN_As   33
#define AN_Se   34
#define AN_Br   35
#define AN_Te   52
#define AN_I    53
#define AN_Hg   80
#define AN_max 112

static ElementDict element_dictionary[] = {
  {"BOT",     0, 0, ELEM_GROUP_undef,      "BeginOfTable"},
  {"H_",      1, 1, ELEM_GROUP_IA,         "Hydrogen"},
  {"He",      2, 1, ELEM_GROUP_VIIIA,      "Helium"},
  {"Li",      3, 2, ELEM_GROUP_IA,         "Lithium"},
  {"Be",      4, 2, ELEM_GROUP_IIA,        "Beryllium"},
  {"B_",      5, 2, ELEM_GROUP_IIIA,       "Boron"},
  {"C_",      6, 2, ELEM_GROUP_IVA,        "Carbon"},
  {"N_",      7, 2, ELEM_GROUP_VA,         "Nitrogen"},
  {"O_",      8, 2, ELEM_GROUP_VIA,        "Oxygen"},
  {"F_",      9, 2, ELEM_GROUP_VIIA,       "Fluorine"},
  {"Ne",     10, 2, ELEM_GROUP_VIIIA,      "Neon"},
  {"Na",     11, 3, ELEM_GROUP_IA,         "Sodium"},
  {"Mg",     12, 3, ELEM_GROUP_IIA,        "Magnesium"},
  {"Al",     13, 3, ELEM_GROUP_IIIA,       "Aluminum"},
  {"Si",     14, 3, ELEM_GROUP_IVA,        "Silicon"},
  {"P_",     15, 3, ELEM_GROUP_VA,         "Phosphorus"},
  {"S_",     16, 3, ELEM_GROUP_VIA,        "Sulfur"},
  {"Cl",     17, 3, ELEM_GROUP_VIIA,       "Chlorine"},
  {"Ar",     18, 3, ELEM_GROUP_VIIIA,      "Argon"},
  {"K_",     19, 4, ELEM_GROUP_IA,         "Potassium"},
  {"Ca",     20, 4, ELEM_GROUP_IIA,        "Calcium"},
  {"Sc",     21, 4, ELEM_GROUP_IIIB,       "Scandium"},
  {"Ti",     22, 4, ELEM_GROUP_IVB,        "Titanium"},
  {"V_",     23, 4, ELEM_GROUP_VB,         "Vanadium"},
  {"Cr",     24, 4, ELEM_GROUP_VIB,        "Chromium"},
  {"Mn",     25, 4, ELEM_GROUP_VIIB,       "Manganese"},
  {"Fe",     26, 4, ELEM_GROUP_VIIIB,      "Iron"},
  {"Co",     27, 4, ELEM_GROUP_VIIIB,      "Cobalt"},
  {"Ni",     28, 4, ELEM_GROUP_VIIIB,      "Nickel"},
  {"Cu",     29, 4, ELEM_GROUP_IB,         "Copper"},
  {"Zn",     30, 4, ELEM_GROUP_IIB,        "Zinc"},
  {"Ga",     31, 4, ELEM_GROUP_IIIA,       "Gallium"},
  {"Ge",     32, 4, ELEM_GROUP_IVA,        "Germanium"},
  {"As",     33, 4, ELEM_GROUP_VA,         "Arsenic"},
  {"Se",     34, 4, ELEM_GROUP_VIA,        "Selenium"},
  {"Br",     35, 4, ELEM_GROUP_VIIA,       "Bromine"},
  {"Kr",     36, 4, ELEM_GROUP_VIIIA,      "Krypton"},
  {"Rb",     37, 5, ELEM_GROUP_IA,         "Rubidium"},
  {"Sr",     38, 5, ELEM_GROUP_IIA,        "Strontium"},
  {"Y_",     39, 5, ELEM_GROUP_IIIB,       "Yttrium"},
  {"Zr",     40, 5, ELEM_GROUP_IVB,        "Zirconium"},
  {"Nb",     41, 5, ELEM_GROUP_VB,         "Niobium"},
  {"Mo",     42, 5, ELEM_GROUP_VIB,        "Molybdenum"},
  {"Tc",     43, 5, ELEM_GROUP_VIIB,       "Technetium"},
  {"Ru",     44, 5, ELEM_GROUP_VIIIB,      "Ruthenium"},
  {"Rh",     45, 5, ELEM_GROUP_VIIIB,      "Rhodium"},
  {"Pd",     46, 5, ELEM_GROUP_VIIIB,      "Palladium"},
  {"Ag",     47, 5, ELEM_GROUP_IB,         "Silver"},
  {"Cd",     48, 5, ELEM_GROUP_IIB,        "Cadmium"},
  {"In",     49, 5, ELEM_GROUP_IIIA,       "Indium"},
  {"Sn",     50, 5, ELEM_GROUP_IVA,        "Tin"},
  {"Sb",     51, 5, ELEM_GROUP_VA,         "Antimony"},
  {"Te",     52, 5, ELEM_GROUP_VIA,        "Tellurium"},
  {"I_",     53, 5, ELEM_GROUP_VIIA,       "Iodine"},
  {"Xe",     54, 5, ELEM_GROUP_VIIIA,      "Xenon"},
  {"Cs",     55, 6, ELEM_GROUP_IA,         "Cesium"},
  {"Ba",     56, 6, ELEM_GROUP_IIA,        "Barium"},
  {"La",     57, 6, ELEM_GROUP_LANTHANIDE, "Lanthanum"},
  {"Ce",     58, 6, ELEM_GROUP_LANTHANIDE, "Cerium"},
  {"Pr",     59, 6, ELEM_GROUP_LANTHANIDE, "Praseodymium"},
  {"Nd",     60, 6, ELEM_GROUP_LANTHANIDE, "Neodymium"},
  {"Pm",     61, 6, ELEM_GROUP_LANTHANIDE, "Promethium"},
  {"Sm",     62, 6, ELEM_GROUP_LANTHANIDE, "Samarium"},
  {"Eu",     63, 6, ELEM_GROUP_LANTHANIDE, "Europium"},
  {"Gd",     64, 6, ELEM_GROUP_LANTHANIDE, "Gadolinium"},
  {"Tb",     65, 6, ELEM_GROUP_LANTHANIDE, "Terbium"},
  {"Dy",     66, 6, ELEM_GROUP_LANTHANIDE, "Dysprosium"},
  {"Ho",     67, 6, ELEM_GROUP_LANTHANIDE, "Holmium"},
  {"Er",     68, 6, ELEM_GROUP_LANTHANIDE, "Erbium"},
  {"Tm",     69, 6, ELEM_GROUP_LANTHANIDE, "Thulium"},
  {"Yb",     70, 6, ELEM_GROUP_LANTHANIDE, "Ytterbium"},
  {"Lu",     71, 6, ELEM_GROUP_LANTHANIDE, "Lutetium"},
  {"Hf",     72, 6, ELEM_GROUP_IVB,        "Hafnium"},
  {"Ta",     73, 6, ELEM_GROUP_VB,         "Tantalum"},
  {"W_",     74, 6, ELEM_GROUP_VIB,        "Tungsten"},
  {"Re",     75, 6, ELEM_GROUP_VIIB,       "Rhenium"},
  {"Os",     76, 6, ELEM_GROUP_VIIIB,      "Osmium"},
  {"Ir",     77, 6, ELEM_GROUP_VIIIB,      "Iridium"},
  {"Pt",     78, 6, ELEM_GROUP_VIIIB,      "Platinum"},
  {"Au",     79, 6, ELEM_GROUP_IB,         "Gold"},
  {"Hg",     80, 6, ELEM_GROUP_IIB,        "Mercury"},
  {"Tl",     81, 6, ELEM_GROUP_IIIA,       "Thallium"},
  {"Pb",     82, 6, ELEM_GROUP_IVA,        "Lead"},
  {"Bi",     83, 6, ELEM_GROUP_VA,         "Bismuth"},
  {"Po",     84, 6, ELEM_GROUP_VIA,        "Polonium"},
  {"At",     85, 6, ELEM_GROUP_VIIA,       "Astatine"},
  {"Rn",     86, 6, ELEM_GROUP_VIIIA,      "Radon"},
  {"Fr",     87, 7, ELEM_GROUP_IA,         "Francium"},
  {"Ra",     88, 7, ELEM_GROUP_IIA,        "Radium"},
  {"Ac",     89, 7, ELEM_GROUP_ACTINIDE,   "Actinium"},
  {"Th",     90, 7, ELEM_GROUP_ACTINIDE,   "Thorium"},
  {"Pa",     91, 7, ELEM_GROUP_ACTINIDE,   "Protactinium"},
  {"U_",     92, 7, ELEM_GROUP_ACTINIDE,   "Uranium"},
  {"Np",     93, 7, ELEM_GROUP_ACTINIDE,   "Neptunium"},
  {"Pu",     94, 7, ELEM_GROUP_ACTINIDE,   "Plutonium"},
  {"Am",     95, 7, ELEM_GROUP_ACTINIDE,   "Americium"},
  {"Cm",     96, 7, ELEM_GROUP_ACTINIDE,   "Curium"},
  {"Bk",     97, 7, ELEM_GROUP_ACTINIDE,   "Berkelium"},
  {"Cf",     98, 7, ELEM_GROUP_ACTINIDE,   "Californium"},
  {"Es",     99, 7, ELEM_GROUP_ACTINIDE,   "Einsteinium"},
  {"Fm",    100, 7, ELEM_GROUP_ACTINIDE,   "Fermium"},
  {"Md",    101, 7, ELEM_GROUP_ACTINIDE,   "Mendelevium"},
  {"No",    102, 7, ELEM_GROUP_ACTINIDE,   "Nobelium"},
  {"Lr",    103, 7, ELEM_GROUP_ACTINIDE,   "Lawrencium"},
  {"Rf",    104, 7, ELEM_GROUP_IVB,        "Rutherfordium"},
  {"Db",    105, 7, ELEM_GROUP_VB,         "Dubnium"},
  {"Sg",    106, 7, ELEM_GROUP_VIB,        "Seaborgium"},
  {"Bh",    107, 7, ELEM_GROUP_VIIB,       "Bohrium"},
  {"Hs",    108, 7, ELEM_GROUP_VIIIB,      "Hassium"},
  {"Mt",    109, 7, ELEM_GROUP_VIIIB,      "Meitnerium"},
  {"Ds",    110, 7, ELEM_GROUP_VIIIB,      "Darmstadtium"},
  {"Rg",    111, 7, ELEM_GROUP_IB,         "Roentgenium"},
  {"EOT",AN_max, 8, ELEM_GROUP_max,        "EndOfTable"},
};

#define BV_undef -1
#define BV_H     39
#define BV_Li    50
#define BV_Be     9
#define BV_B      7
#define BV_C     14
#define BV_N     59
#define BV_Na    60
#define BV_Mg    52
#define BV_Al     2
#define BV_Si    84
#define BV_P     65
#define BV_S     78
#define BV_Cl    20
#define BV_K     48
#define BV_Ca    15
#define BV_Mn    53
#define BV_Fe    35
#define BV_Co    22
#define BV_Ni    63
#define BV_Cu    29
#define BV_Zn   107
#define BV_As     5
#define BV_Se    83
#define BV_Br    13
#define BV_Te    92
#define BV_I     45
#define BV_Hg    42
#define BV_max  109

static BondValenceDict bondvalence_dictionary[] = {
  {     0,    89, "Ac", 3, 2.240,-1.00,-1.00,-1.00, 2.130, 2.630,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {     1,    47, "Ag", 1, 1.805, 2.15, 2.26, 2.51, 1.800, 2.090, 2.22, 2.38, 1.85, 2.22, 2.30, 1.50, -1},
  {     2,    13, "Al", 3, 1.651, 2.13, 2.27, 2.48, 1.545, 2.030, 2.20, 2.41, 1.79, 2.24, 2.32, 1.45, -1},
  {     3,    95, "Am", 3, 2.110,-1.00,-1.00,-1.00, 2.000, 2.480,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {     4,    33, "As", 3, 1.789, 2.26, 2.39, 2.61, 1.700, 2.160, 2.32, 2.54, 1.93, 2.34, 2.41, 1.56,  5},
  {     5,    33, "As", 5, 1.767, 2.26, 2.39, 2.61, 1.620, 2.140, 2.32, 2.54, 1.93, 2.34, 2.41, 1.56, -1},
  {     6,    79, "Au", 3, 1.833, 2.03, 2.18, 2.41, 1.810, 2.170, 2.12, 2.34, 1.72, 2.14, 2.22, 1.37, -1},
  {     7,     5, "B_", 3, 1.371, 1.82, 1.95, 2.20, 1.310, 1.740, 1.88, 2.10, 1.47, 1.88, 1.97, 1.14, -1},
  {     8,    56, "Ba", 2, 2.290, 2.77, 2.88, 3.08, 2.190, 2.690, 2.88, 3.13, 2.47, 2.88, 2.96, 2.22, -1},
  {     9,     4, "Be", 2, 1.381, 1.83, 1.97, 2.21, 1.280, 1.760, 1.90, 2.10, 1.50, 1.95, 2.00, 1.11, -1},
  {    10,    83, "Bi", 3, 2.090, 2.55, 2.72, 2.87, 1.990, 2.480, 2.62, 2.84, 2.24, 2.63, 2.72, 1.97, 11},
  {    11,    83, "Bi", 5, 2.060, 2.55, 2.72, 2.87, 1.970, 2.440, 2.62, 2.84, 2.24, 2.63, 2.72, 1.97, -1},
  {    12,    97, "Bk", 3, 2.080,-1.00,-1.00,-1.00, 1.960, 2.460,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    13,    35, "Br", 7, 1.810,-1.00,-1.00,-1.00, 1.720, 2.190,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    14,     6, "C_", 4, 1.390, 1.82, 1.97, 2.21, 1.320, 1.760, 1.90, 2.12, 1.47, 1.89, 1.99, 1.10, -1},
  {    15,    20, "Ca", 2, 1.940, 2.42, 2.56, 2.76, 1.890, 2.340, 2.45, 2.72, 2.09, 2.60, 2.62, 1.83, -1},
  {    16,    48, "Cd", 2, 1.904, 2.29, 2.40, 2.59, 1.811, 2.230, 2.35, 2.57, 1.96, 2.34, 2.43, 1.66, -1},
  {    17,    58, "Ce", 3, 2.151, 2.62, 2.74, 2.92, 2.036, 2.520, 2.69, 2.92, 2.34, 2.70, 2.78, 2.04, 18},
  {    18,    58, "Ce", 4, 2.028, 2.62, 2.74, 2.92, 1.995, 2.410, 2.69, 2.92, 2.34, 2.70, 2.78, 2.04, -1},
  {    19,    98, "Cf", 3, 2.070,-1.00,-1.00,-1.00, 1.950, 2.450,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    20,    17, "Cl", 7, 1.632,-1.00,-1.00,-1.00, 1.550, 2.000,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    21,    96, "Cm", 3, 2.230,-1.00,-1.00,-1.00, 2.120, 2.620,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    22,    27, "Co", 2, 1.692, 2.06, 2.24, 2.46, 1.640, 2.010, 2.18, 2.37, 1.72, 2.21, 2.28, 1.44, 23},
  {    23,    27, "Co", 3, 1.700, 2.06, 2.24, 2.46, 1.620, 2.050, 2.18, 2.37, 1.72, 2.21, 2.28, 1.44, -1},
  {    24,    24, "Cr", 2, 1.730, 2.18, 2.29, 2.52, 1.670, 2.090, 2.26, 2.45, 1.85, 2.27, 2.34, 1.52, 25},
  {    25,    24, "Cr", 3, 1.724, 2.18, 2.29, 2.52, 1.640, 2.080, 2.26, 2.45, 1.85, 2.27, 2.34, 1.52, 26},
  {    26,    24, "Cr", 6, 1.794, 2.18, 2.29, 2.52, 1.740, 2.120, 2.26, 2.45, 1.85, 2.27, 2.34, 1.52, -1},
  {    27,    55, "Cs", 1, 2.420, 2.89, 2.98, 3.16, 2.330, 2.790, 2.95, 3.18, 2.53, 2.93, 3.04, 2.44, -1},
  {    28,    29, "Cu", 1, 1.567,1.834, 1.90, 2.27, 1.600, 1.858,1.967,2.153,1.571,1.844,1.856, 1.21, 29},
  {    29,    29, "Cu", 2, 1.655,2.024,2.124, 2.27, 1.600, 1.999,2.134, 2.36,1.713,2.053, 2.08, 1.21, -1},
  {    30,    66, "Dy", 3, 2.036, 2.47, 2.61, 2.80, 1.922, 2.410, 2.56, 2.77, 2.18, 2.57, 2.64, 1.89, -1},
  {    31,    68, "Er", 3, 2.010, 2.46, 2.59, 2.78, 1.906, 2.390, 2.54, 2.75, 2.16, 2.55, 2.63, 1.86, -1},
  {    32,    63, "Eu", 2, 2.147, 2.53, 2.66, 2.85, 2.040, 2.530, 2.61, 2.83, 2.24, 2.62, 2.70, 1.95, 33},
  {    33,    63, "Eu", 3, 2.076, 2.53, 2.66, 2.85, 1.961, 2.455, 2.61, 2.83, 2.24, 2.62, 2.70, 1.95, -1},
  {    34,    26, "Fe", 2, 1.720, 2.08, 2.204,2.53, 1.680, 2.060, 2.206,2.388,1.75, 2.12, 2.35, 1.53, 35},
  {    35,    26, "Fe", 3, 1.763, 2.147,2.26, 2.53, 1.672, 2.079, 2.225,2.434,1.72, 2.13, 2.35, 1.53, -1},
  {    36,    31, "Ga", 3, 1.730, 2.17, 2.30, 2.54, 1.620, 2.070, 2.24, 2.45, 1.84, 2.26, 2.34, 1.51, -1},
  {    37,    64, "Gd", 3, 2.065, 2.53, 2.65, 2.84, 1.950, 2.445, 2.60, 2.82, 2.22, 2.61, 2.68, 1.93, -1},
  {    38,    32, "Ge", 4, 1.748, 2.22, 2.35, 2.56, 1.660, 2.140, 2.30, 2.50, 1.88, 2.32, 2.43, 1.55, -1},
  {    39,     1, "H_", 1, 0.950, 1.35, 1.48, 1.78, 0.920, 1.280, 1.42, 1.61, 1.03, 1.48, 1.52, 0.74, -1},
  {    40,    72, "Hf", 4, 1.923, 2.39, 2.52, 2.72, 1.850, 2.300, 2.47, 2.68, 2.09, 2.48, 2.56, 1.78, -1},
  {    41,    80, "Hg", 1, 1.900, 2.32, 2.47, 2.61, 1.810, 2.280, 2.40, 2.59, 2.02, 2.42, 2.50, 1.71, 42},
  {    42,    80, "Hg", 2, 1.930, 2.32, 2.47, 2.61, 1.900, 2.250, 2.40, 2.59, 2.02, 2.42, 2.50, 1.71, -1},
  {    43,    67, "Ho", 3, 2.023, 2.48, 2.61, 2.80, 1.908, 2.401, 2.55, 2.77, 2.18, 2.56, 2.64, 1.88, -1},
  {    44,    53, "I_", 5, 2.000,-1.00,-1.00,-1.00, 1.900, 2.380,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, 45},
  {    45,    53, "I_", 7, 1.930,-1.00,-1.00,-1.00, 1.830, 2.310,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    46,    49, "In", 3, 1.902, 2.36, 2.47, 2.69, 1.790, 2.280, 2.41, 2.63, 2.03, 2.43, 2.51, 1.72, -1},
  {    47,    77, "Ir", 5, 1.916, 2.38, 2.51, 2.71, 1.820, 2.300, 2.45, 2.66, 2.06, 2.46, 2.54, 1.76, -1},
  {    48,    19, "K_", 1, 2.100, 2.62, 2.76, 2.93, 2.260, 2.560, 2.95, 3.03, 2.26, 2.76, 2.83, 2.10, -1},
  {    49,    57, "La", 3, 2.172, 2.64, 2.74, 2.94, 2.057, 2.545, 2.72, 2.93, 2.34, 2.73, 2.80, 2.06, -1},
  {    50,     3, "Li", 1, 1.466, 1.94, 2.09, 2.30, 1.360, 1.910, 2.02, 2.22, 1.61, 2.04, 2.11, 1.31, -1},
  {    51,    71, "Lu", 3, 1.971, 2.43, 2.56, 2.75, 1.876, 2.361, 2.50, 2.72, 2.11, 2.51, 2.59, 1.82, -1},
  {    52,    12, "Mg", 2, 1.666, 2.23, 2.32, 2.53, 1.581, 2.110, 2.264,2.47, 1.80, 2.341,2.38, 1.53, -1},
  {    53,    25, "Mn", 2, 1.790, 2.20, 2.32, 2.55, 1.698, 2.130, 2.26, 2.49, 1.87, 2.24, 2.36, 1.55, 54},
  {    54,    25, "Mn", 3, 1.760, 2.20, 2.32, 2.55, 1.660, 2.140, 2.26, 2.49, 1.87, 2.24, 2.36, 1.55, 55},
  {    55,    25, "Mn", 4, 1.753, 2.20, 2.32, 2.55, 1.710, 2.130, 2.26, 2.49, 1.87, 2.24, 2.36, 1.55, 56},
  {    56,    25, "Mn", 7, 1.790, 2.20, 2.32, 2.55, 1.720, 2.170, 2.26, 2.49, 1.87, 2.24, 2.36, 1.55, -1},
  {    57,    42, "Mo", 6, 1.907, 2.35, 2.49, 2.69, 1.810, 2.280, 2.43, 2.64, 2.04, 2.44, 2.52, 1.73, -1},
  {    58,     7, "N_", 3, 1.361,-1.00,-1.00,-1.00, 1.370, 1.750,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, 59},
  {    59,     7, "N_", 5, 1.432,-1.00,-1.00,-1.00, 1.360, 1.800,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    60,    11, "Na", 1, 1.780, 2.27, 2.38, 2.64, 1.710, 2.170, 2.33, 2.54, 1.89, 2.43, 2.53, 1.68, -1},
  {    61,    41, "Nb", 5, 1.911, 2.37, 2.51, 2.70, 1.870, 2.270, 2.45, 2.68, 2.06, 2.46, 2.54, 1.75, -1},
  {    62,    60, "Nd", 3, 2.117, 2.59, 2.71, 2.89, 2.008, 2.492, 2.66, 2.87, 2.30, 2.66, 2.74, 2.00, -1},
  {    63,    28, "Ni", 2, 1.654, 2.04, 2.14, 2.43, 1.599, 2.020, 2.16, 2.34, 1.75, 2.17, 2.24, 1.40, -1},
  {    64,    76, "Os", 4, 1.811,-1.00,-1.00,-1.00, 1.720, 2.190,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    65,    15, "P_", 5, 1.604, 2.11, 2.26, 2.44, 1.521, 1.990, 2.15, 2.40, 1.73, 2.19, 2.25, 1.41, -1},
  {    66,    82, "Pb", 2, 2.112, 2.55, 2.67, 2.84, 2.030, 2.530, 2.64, 2.78, 2.22, 2.64, 2.72, 1.97, 67},
  {    67,    82, "Pb", 4, 2.042, 2.55, 2.67, 2.84, 1.940, 2.430, 2.64, 2.78, 2.22, 2.64, 2.72, 1.97, -1},
  {    68,    46, "Pd", 2, 1.792, 2.10, 2.22, 2.48, 1.740, 2.050, 2.19, 2.38, 1.81, 2.22, 2.30, 1.47, -1},
  {    69,    59, "Pr", 3, 2.135, 2.60, 2.72, 2.90, 2.022, 2.500, 2.67, 2.89, 2.30, 2.68, 2.75, 2.02, -1},
  {    70,    78, "Pt", 2, 1.768, 2.08, 2.19, 2.45, 1.680, 2.050, 2.18, 2.37, 1.77, 2.19, 2.26, 1.40, 70},
  {    71,    78, "Pt", 4, 1.879, 2.08, 2.19, 2.45, 1.759, 2.170, 2.18, 2.37, 1.77, 2.19, 2.26, 1.40, -1},
  {    72,    94, "Pu", 3, 2.110,-1.00,-1.00,-1.00, 2.000, 2.480,-1.00,-1.00,-1.00,-1.00,-1.00,-1.00, -1},
  {    73,    37, "Rb", 1, 2.260, 2.70, 2.81, 3.00, 2.160, 2.650, 2.78, 3.01, 2.37, 2.76, 2.87, 2.26, -1},
  {    74,    75, "Re", 7, 1.970, 2.37, 2.50, 2.70, 1.860, 2.230, 2.45, 2.61, 2.06, 2.46, 2.54, 1.75, -1},
  {    75,    45, "Rh", 3, 1.791, 2.15, 2.33, 2.55, 1.710, 2.170, 2.25, 2.48, 1.88, 2.29, 2.37, 1.55, -1},
  {    76,    44, "Ru", 4, 1.834, 2.16, 2.33, 2.54, 1.740, 2.210, 2.26, 2.48, 1.88, 2.29, 2.36, 1.61, -1},
  {    77,    16, "S_", 4, 1.644, 2.07, 2.21, 2.45, 1.600, 2.020, 2.17, 2.36, 1.74, 2.15, 2.25, 1.38, 78},
  {    78,    16, "S_", 6, 1.624, 2.07, 2.21, 2.45, 1.560, 2.030, 2.17, 2.36, 1.74, 2.15, 2.25, 1.38, -1},
  {    79,    51, "Sb", 3, 1.973, 2.45, 2.57, 2.78, 1.900, 2.350, 2.50, 2.72, 2.12, 2.52, 2.60, 1.77, 80},
  {    80,    51, "Sb", 5, 1.942, 2.45, 2.57, 2.78, 1.800, 2.300, 2.50, 2.72, 2.12, 2.52, 2.60, 1.77, -1},
  {    81,    21, "Sc", 3, 1.849, 2.32, 2.44, 2.64, 1.760, 2.230, 2.38, 2.59, 1.98, 2.40, 2.48, 1.68, -1},
  {    82,    34, "Se", 4, 1.811, 2.25, 2.36, 2.55, 1.730, 2.220, 2.33, 2.54, 1.93, 2.34, 2.42, 1.54, 83},
  {    83,    34, "Se", 6, 1.788, 2.25, 2.36, 2.55, 1.690, 2.160, 2.33, 2.54, 1.93, 2.34, 2.42, 1.54, -1},
  {    84,    14, "Si", 4, 1.624, 2.13, 2.26, 2.49, 1.580, 2.030, 2.20, 2.41, 1.77, 2.23, 2.31, 1.47, -1},
  {    85,    62, "Sm", 3, 2.088, 2.55, 2.67, 2.86, 1.977, 2.466, 2.62, 2.84, 2.24, 2.63, 2.70, 1.96, -1},
  {    86,    50, "Sn", 2, 1.984, 2.45, 2.59, 2.76, 1.925, 2.360, 2.55, 2.76, 2.14, 2.45, 2.62, 1.85, 87},
  {    87,    50, "Sn", 4, 1.905, 2.45, 2.59, 2.76, 1.840, 2.280, 2.55, 2.76, 2.14, 2.45, 2.62, 1.85, -1},
  {    88,    38, "Sr", 2, 2.118, 2.59, 2.72, 2.87, 2.019, 2.510, 2.68, 2.88, 2.23, 2.67, 2.76, 2.01, -1},
  {    89,    73, "Ta", 5, 1.920, 2.39, 2.51, 2.70, 1.880, 2.300, 2.45, 2.66, 2.01, 2.47, 2.55, 1.76, -1},
  {    90,    65, "Tb", 3, 2.049, 2.51, 2.63, 2.82, 1.936, 2.427, 2.58, 2.80, 2.20, 2.59, 2.66, 1.91, -1},
  {    91,    52, "Te", 4, 1.977, 2.45, 2.53, 2.76, 1.870, 2.370, 2.53, 2.76, 2.12, 2.52, 2.60, 1.83, 92},
  {    92,    52, "Te", 6, 1.917, 2.45, 2.53, 2.76, 1.820, 2.300, 2.53, 2.76, 2.12, 2.52, 2.60, 1.83, -1},
  {    93,    90, "Th", 4, 2.167, 2.64, 2.76, 2.94, 2.070, 2.550, 2.71, 2.93, 2.34, 2.73, 2.80, 2.07, -1},
  {    94,    22, "Ti", 3, 1.791, 2.24, 2.38, 2.60, 1.723, 2.170, 2.32, 2.54, 1.93, 2.36, 2.42, 1.61, 95},
  {    95,    22, "Ti", 4, 1.815, 2.24, 2.38, 2.60, 1.760, 2.190, 2.32, 2.54, 1.93, 2.36, 2.42, 1.61, -1},
  {    96,    81, "Tl", 1, 2.172, 2.63, 2.70, 2.93, 2.150, 2.560, 2.70, 2.91, 2.29, 2.71, 2.79, 2.05, 97},
  {    97,    81, "Tl", 3, 2.003, 2.63, 2.70, 2.93, 1.880, 2.320, 2.70, 2.91, 2.29, 2.71, 2.79, 2.05, -1},
  {    98,    69, "Tm", 3, 2.000, 2.45, 2.58, 2.77, 1.842, 2.380, 2.53, 2.74, 2.14, 2.53, 2.62, 1.85, -1},
  {    99,    92, "U_", 4, 2.112, 2.56, 2.70, 2.86, 2.034, 2.480, 2.63, 2.84, 2.24, 2.64, 2.72, 1.97,100},
  {   100,    92, "U_", 6, 2.075, 2.56, 2.70, 2.86, 1.966, 2.460, 2.63, 2.84, 2.24, 2.64, 2.72, 1.97, -1},
  {   101,    23, "V_", 3, 1.743, 2.23, 2.33, 2.57, 1.702, 2.190, 2.30, 2.51, 1.86, 2.31, 2.39, 1.58,102},
  {   102,    23, "V_", 4, 1.784, 2.23, 2.33, 2.57, 1.700, 2.160, 2.30, 2.51, 1.86, 2.31, 2.39, 1.58,103},
  {   103,    23, "V_", 5, 1.803, 2.23, 2.33, 2.57, 1.710, 2.160, 2.30, 2.51, 1.86, 2.31, 2.39, 1.58, -1},
  {   104,    74, "W_", 6, 1.921, 2.39, 2.51, 2.71, 1.830, 2.270, 2.45, 2.66, 2.06, 2.46, 2.54, 1.76, -1},
  {   105,    39, "Y_", 3, 2.014, 2.48, 2.61, 2.80, 1.904, 2.400, 2.55, 2.77, 2.17, 2.57, 2.64, 1.86, -1},
  {   106,    70, "Yb", 3, 1.985, 2.43, 2.56, 2.76, 1.875, 2.371, 2.51, 2.72, 2.12, 2.53, 2.59, 1.82, -1},
  {   107,    30, "Zn", 2, 1.690, 2.091,2.207,2.45, 1.610, 2.010, 2.143,2.342,1.755,2.188,2.24, 1.42, -1},
  {   108,    40, "Zr", 4, 1.937, 2.41, 2.53, 2.67, 1.854, 2.330, 2.48, 2.69, 2.11, 2.52, 2.57, 1.79, -1},
  {BV_max,AN_max,"EOT", 0,  AN_O, AN_S,AN_Se,AN_Te,  AN_F, AN_Cl,AN_Br, AN_I, AN_N, AN_P,AN_As, AN_H, -1},
};

static InnerSphereDict innersphere_dictionary = {
  {ATOM_UNDEF           , AN_max, AN_Na, AN_Mg, AN_K, AN_Ca, AN_Mn, AN_Fe, AN_Co, AN_Ni, AN_Cu, AN_Zn},
  {ATOM_MC_N            ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_MC_CA           ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_MC_C            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_MC_O            ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_CB           ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_SC_C            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_SC_N_ARG        ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_SC_O_AMIDE      ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_N_AMIDE      ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_SC_O_CARBOXYL   ,      2,     2,     3,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_S_CYS        ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_C_RING       ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_SC_N_HIS        ,      2,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_N_LYS        ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_SC_N_TRP        ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_SC_S_MET        ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_O_HYDROXYL   ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_O_PHENOL     ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_SE           ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_SC_O_HETERO     ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_N_HETERO     ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_S_HETERO     ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_SC_X_HETERO     ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_NA_C_BASE       ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_NA_C_RIBOSE     ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_NA_C_BRIDGE     ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_NA_N_BASE_RIBOSE,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_NA_N_BASE_ENDO  ,      1,     4,     4,    4,     4,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_NH_BASE_ENDO ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_N_BASE_AMIDE ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_O_BASE       ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_O2_RIBOSE    ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_O4_RIBOSE    ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_OP_BRIDGE    ,      1,     2,     3,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_OP_TERMINAL  ,      2,     2,     3,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_NA_P            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_GC_C            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_GC_O            ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_GC_N            ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_GC_X            ,      1,     1,     1,    1,     1,     1,     1,     1,     1,     1,     1},
  {ATOM_WT_O            ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_HYDROGEN        ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_LG_C            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_LG_N            ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_LG_O            ,      1,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_LG_P            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_LG_S            ,      1,     1,     1,    1,     1,     2,     2,     2,     2,     2,     2},
  {ATOM_LG_H            ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_ALKALI          ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_ALKALINE        ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_HALOGEN         ,      2,     2,     2,    2,     2,     2,     2,     2,     2,     2,     2},
  {ATOM_LIGHT           ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_HEAVY           ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_OTHER           ,      0,     0,     0,    0,     0,     0,     0,     0,     0,     0,     0},
  {ATOM_MAX             ,      2,     4,     6,    3,     5,     4,     4,     4,     4,     3,     3},
// The last record stores the minimal CN that will be seeked within generously allowed region of distances +1.0A
// 1: search in favorable distance range;          2: search in generously allowed range;
// 3: include only if bidentate is not introduced; 4: included only if no hydrogen bond is detected
};


/* stack Object */
typedef struct RecNeighborStack {
  ResidueName             resn1;
  char                    chain1;
  int                     resid1;
  AtomName                atomname1;
  ResidueName             resn2;
  char                    chain2;
  int                     resid2;
  AtomName                atomname2;
  int                     regid1,regid2;
  int                     register_int; // This is also considered as a record ID for the stack
  float                   register_float;
  struct RecNeighborStack *prev;
} RecNeighborStack;
typedef struct ObjNeighborStack {
  int                     size;
  struct RecNeighborStack *top;
} ObjNeighborStack;
ObjNeighborStack* stackNew();
void stackPush(ObjNeighborStack *s, ObjResidueInfo *resi1, ObjAtomInfo *atmi1, ObjResidueInfo *resi2, ObjAtomInfo *atmi2, int regid1, int regid2, int regint, float regfloat);
int  stackContains(ObjNeighborStack *s, ObjResidueInfo *resi1, ObjAtomInfo *atmi1, ObjResidueInfo *resi2, ObjAtomInfo *atmi2, int icell, int isym);
int  stackDelete(ObjNeighborStack *s, int record_id);
void stackRecPrint(RecNeighborStack *rec, char *msg);
void stackFree(ObjNeighborStack *s);



int AtomInfoIsElement(char a, char b);
int AtomInfoMatchResidue(char *resn, char a, char b, int elem_flag);
void AtomInfoAssignParameters(ObjAtomInfo *I);
double AtomInfoBondValence(int protons, int bv_index, double distance);
int AtomInfoHasHydrogenBond(ObjAtomInfo *ai, ObjEntityMolecule *I, int consider_water);
double AtomInfoAssignOxidationState(ObjAtomInfo *ai_ion, int numAtomFCS, ObjIonLigAtomInfo *tmpIonLigAtom, double valence_3a);
int AtomInfoExploreCluster(ObjAtomInfo *atinfo, ObjNeighborInfo *nbinfo, int *arr_atomid_cluster);
void AtomInfoPrint(ObjAtomInfo *I);
void AtomInfoPrintPDB(char* pdb_buffer_str, ObjAtomInfo *I, char chain, Vector3f v);
void AtomInfoPrintElement(ElementDict *elem_dict);
void AtomInfoPrintBondValence(BondValenceDict *bv_dict);
int AtomInfoLocateIndex4surfrace(ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index);
int AtomInfoResCmp(ObjResidueInfo *resi, ObjResidueInfo *ri, char rescmp_type);
int AtomInfoLocateIndex4contact(int* list_atomindex, ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index);
ObjAtomInfo *AtomInfoLocateIndex4molprobity(ObjResidueInfo *resi, ObjAtomInfo *atmi, ObjEntityMolecule *I, int prev_atom_index);



#endif
