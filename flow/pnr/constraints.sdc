## Define clock constraints. (Freq in Hz, Period in ps)
set CLK_FREQUENCY           20000000.0
set CLK_PERIOD              [expr {1000000000000 / $CLK_FREQUENCY / 1.0}]
set CLK_HIGH_TIME           [expr {$CLK_PERIOD / 2.0}]
set CLK_UNCERTAINTY_SETUP   [expr {$CLK_PERIOD * 0.1}]

## Define boundary constraints.
## Input and output delay
## This is based off a 16kB SRAM constraint
set INPUT_DELAY_MAX_FRACTION    [expr {$CLK_PERIOD * 0.3}]
set OUTPUT_DELAY_MAX_FRACTION   [expr {$CLK_PERIOD * 0.2}]

## Set clock constraints.
create_clock -period $CLK_PERIOD -waveform [list 0 $CLK_HIGH_TIME] -name clk [get_ports clk]
set_clock_uncertainty -setup $CLK_UNCERTAINTY_SETUP [get_clocks clk]

## Set boundary constraints.
## Uncomment for inputs/outputs that go to places of non-standard timing
# set_input_delay $INPUT_DELAY_MAX_FRACTION -max -clock clk [all_inputs]
# set_output_delay $OUTPUT_DELAY_MAX_FRACTION -max -clock clk [all_outputs]

## Set environmental constraints.
set DRIVING_CELL sg13g2_buf_4
set_load 0.01 [all_outputs]

## Create default path groups.
## Separating these paths can help improve optimization.
group_path -name REGOUT -to [all_outputs]
group_path -name REGIN -from [all_inputs]