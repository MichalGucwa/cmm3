set encoding iso_8859_1
set terminal pngcairo transparent enhanced size 340, 160 font "Arial Bold,10"
set output "/var/www/html/csgid/app/webroot/neighborhood_temp/2qif/CU--O.png"
set lmargin at screen 0.00
set bmargin at screen 0.08
set rmargin at screen 0.995
set tmargin at screen 1.00
set xrange [1.5:3.3]
set format x "%3.1f"
set xtics 1.6,0.4,3.2
set xtics offset 0,graph 0.065
set yrange [0:12259.2]
unset ytics
set y2range [0:2]
set y2tics 1,1,1
set y2tics offset -49,graph 0.00
set y2tics mirror
set view 80,45
set key top right
set boxwidth 0.06
set style fill solid 1.0
set xlabel "CU--O \n distance (\305)" offset 17,4.4
set y2label "# of CU--O interactions (2qif)" offset -40,4 rotate by 0
plot "-" using ($1+0.05):2 with boxes lc rgb "#801010" axis x1y2 title "2qif", \
     "/var/www/html/csgid/app/webroot/neighborhood_temp/csd_metal_distances/CU--O.csv" using ($1+0.025):2 with linespoints linewidth 2 pointtype 7 pointsize 0.2 lc rgb "#074a7e" title "CSD^{4}" axis x1y1
2.5	1
2.6	1
e
