set style data linespoints
set grid
#set xrange [0:0.944430562258]
set xrange [-0.05:1]
set terminal postscript enhanced 20 # color


set style line 1 lt 1 lw 3 pt 1 ps 2
set style line 2 lt 2 lw 3 pt 2 ps 2
set style line 3 lt 1 lw 5 pt 2 ps 0
set style line 4 lt 2 lw 5 pt 2 ps 0

set xlabel "message error rate {/Symbol e}"

set output "final-eps/rdg_reliable-grid-error-overhead.eps"

# unset key
set key top left
set ylabel "(average) retransmissions per message"
set bars 3

plot "final-eps/rdg_reliable-grid-error.dat" using 1:3  title "Reliable protocol" ls 1


set output "final-eps/rdg_reliable-grid-error-recipient.eps"

set ylabel "retransmissions per message per recipient"

plot "final-eps/rdg_reliable-grid-error.dat" using 1:4 title "Average" ls 1, "final-eps/rdg_reliable-grid-error.dat" using 1:4:($4+$5):($4-$5) title "Standard Deviation" w errorbars ls 3, "final-eps/rdg_reliable-grid-error.dat" using 1:4:6:7 title "Minimum / Maximum" w errorbars ls 4


set ylabel "message delivery"
set key bottom left
set yrange [0:1.1]

set output "final-eps/rdg_reliable-grid-error-delivery.eps"

plot "final-eps/rdg_reliable-grid-error.dat"  title "Reliable protocol" ls 1, "final-eps/rdg_unreliable-grid-error.dat"  title "Best-effort protocol" ls 2