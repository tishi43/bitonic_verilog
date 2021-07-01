#333M
#create_clock -period 3.000 -name clk -waveform {0.000 1.500} [get_nets clk]
#250M
#create_clock -period 4.000 -name clk -waveform {0.000 2.000} [get_nets clk]
#150M
create_clock -period 6.667 -name clk -waveform {0.000 3.333} [get_nets clk]
