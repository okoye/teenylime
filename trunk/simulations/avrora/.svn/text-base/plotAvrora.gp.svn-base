# # set style histogram clustered gap 2
# # #set style data linespoints
# # #set grid
# # #set xrange [0:0.944430562258]
# # set xrange [-0.05:0.7]
# set yrange [0:100]
# # set terminal postscript enhanced 20 # color

# # #set style line 1 lt 1 lw 3 pt 1 ps 2
# # #set style line 2 lt 2 lw 3 pt 2 ps 2
# # #set style line 3 lt 1 lw 5 pt 2 ps 0
# # #set style line 4 lt 2 lw 5 pt 2 ps 0

# # set output "cputimeToken.eps"

# # # unset key
# # set key top right
# # #set pointsize 2

# set terminal postscript enhanced 20 color
# set key invert reverse Left outside
# set key autotitle columnheader
# set style data histogram
# set style histogram rowstacked
# set style fill solid border -1
# set boxwidth 0.6

# # set terminal png transparent font "arial" 8

# # set boxwidth 0.6 relative 
# # set style data histogram 
# # set style histogram rowstacked 
# # set style fill pattern 

# set xlabel "message error rate {/Symbol e}"
# set ylabel "percentage CPU time breakdown"

# set output "cputimeToken.eps"

# plot 'cputimeToken.dat' using 5:xticlabels(1) title "TinyOS",  '' using 4 title "reliable comm", '' using 3 title "TeenyLIME", '' using 2 title "application"

# # plot 'cputimeToken.dat' using 1:2 title "application", 'cputimeToken.dat' using 1:3 title "TeenyLIME", 'cputimeToken.dat' using 1:5 title "TinyOS", 'cputimeToken.dat' using 1:4 title "reliable comm" 
# # -->
# # set style data linespoints
# # set xrange [1:11]
#  set yrange [0:100]
# # set terminal postscript enhanced 20 # color

# # set xlabel "temperature/humidity nodes"

# # set output "cputimeHVAC.eps"

# # set key top right
# # set ylabel "percentage CPU time breakdown"
# # set pointsize 2

# # plot 'cputimeHVAC.dat' using 1:2 title "application", 'cputimeHVAC.dat' using 1:3 title "TeenyLIME", 'cputimeHVAC.dat' using 1:4 title "TinyOS" 

# set terminal postscript enhanced 20 color
# set key invert reverse Left outside
# set key autotitle columnheader
# set style data histogram
# set style histogram rowstacked
# set style fill solid border -1
# set boxwidth 0.6

# set xlabel "temperature/humidity nodes"
# set ylabel "percentage CPU time breakdown"

# set output "cputimeHVAC.eps"

# # plot 'cputimeHVAC.dat' using 4:xticlabels(1) title "TinyOS",  '' using 3 title "TeenyLIME", '' using 2 title "application"

# set style data linespoints
# #set grid
# #set xrange [0:0.944430562258]
# set xrange [-0.05:0.7]
# set yrange [0:6]
# set terminal postscript enhanced 20 # color

# #set style line 1 lt 1 lw 3 pt 1 ps 2
# #set style line 2 lt 2 lw 3 pt 2 ps 2
# #set style line 3 lt 1 lw 5 pt 2 ps 0
# #set style line 4 lt 2 lw 5 pt 2 ps 0

# set xlabel "message error rate {/Symbol e}"

# set output "messages.eps"

# # unset key
# set key bottom right
# set ylabel "average message transmissions"
# set pointsize 2

# plot 'messages.dat' using 1:2 title "avg message retransmissions" 

set style data linespoints
#set grid
#set xrange [0:0.944430562258]
set xrange [-0.05:0.7]
set yrange [0:70]
set y2range [0:100]
set ytics nomirror
set y2tics 0,20,100
# set y2tics nomirror
set terminal postscript enhanced 20 # color

#set style line 1 lt 1 lw 3 pt 1 ps 2
#set style line 2 lt 2 lw 3 pt 2 ps 2
#set style line 3 lt 1 lw 5 pt 2 ps 0
#set style line 4 lt 2 lw 5 pt 2 ps 0

set xlabel "message error rate {/Symbol e}"

set output "lifetimeToken.eps"

# unset key
set key top right
set ylabel "system lifetime (days)"
set y2label "percentage lifetime reduction"
set pointsize 2

#set bars 3

plot "lifetimeToken.dat" using 1:2 t "TeenyLIME", "lifetimeToken.dat" using 1:3 t "plain TinyOS", "lifetimeToken.dat" using 1:4 t "% lifetime reduction"

set style data linespoints
#set grid
#set xrange [0:0.944430562258]
set xrange [1:11]
set yrange [0:110]
set y2range [0:100]
set ytics nomirror
set y2tics 0,20,100
#set y2tics nomirror
set terminal postscript enhanced 20 # color

#set style line 1 lt 1 lw 3 pt 1 ps 2
#set style line 2 lt 2 lw 3 pt 2 ps 2
#set style line 3 lt 1 lw 5 pt 2 ps 0
#set style line 4 lt 2 lw 5 pt 2 ps 0

set xlabel "temperature/humidity nodes"

set output "lifetimeHVAC.eps"

# unset key
set key top right
set ylabel "system lifetime (days)"
set y2label "percentage lifetime reduction"
set pointsize 2

#set bars 3

plot "lifetimeHVAC.dat" using 1:2 t "TeenyLIME", "lifetimeHVAC.dat" using 1:3 t "plain TinyOS", "lifetimeHVAC.dat" using 1:4 t "% lifetime reduction"

