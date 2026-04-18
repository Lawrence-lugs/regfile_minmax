###############################################################################
# Created by write_sdc
# Sat Apr 18 14:19:51 2026
###############################################################################
current_design regfile
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 50000.0000 [get_ports {clk}]
set_clock_uncertainty -setup 5000.0000 clk
group_path -name REGIN\
    -from [list [get_ports {clk}]\
           [get_ports {rd_addr[0]}]\
           [get_ports {rd_addr[1]}]\
           [get_ports {rd_addr[2]}]\
           [get_ports {rd_addr[3]}]\
           [get_ports {rd_addr[4]}]\
           [get_ports {rd_addr[5]}]\
           [get_ports {rd_addr[6]}]\
           [get_ports {rd_addr[7]}]\
           [get_ports {rd_addr[8]}]\
           [get_ports {rd_addr[9]}]\
           [get_ports {rst_n}]\
           [get_ports {wr_addr[0]}]\
           [get_ports {wr_addr[1]}]\
           [get_ports {wr_addr[2]}]\
           [get_ports {wr_addr[3]}]\
           [get_ports {wr_addr[4]}]\
           [get_ports {wr_data[0]}]\
           [get_ports {wr_data[10]}]\
           [get_ports {wr_data[11]}]\
           [get_ports {wr_data[12]}]\
           [get_ports {wr_data[13]}]\
           [get_ports {wr_data[14]}]\
           [get_ports {wr_data[15]}]\
           [get_ports {wr_data[16]}]\
           [get_ports {wr_data[17]}]\
           [get_ports {wr_data[18]}]\
           [get_ports {wr_data[19]}]\
           [get_ports {wr_data[1]}]\
           [get_ports {wr_data[20]}]\
           [get_ports {wr_data[21]}]\
           [get_ports {wr_data[22]}]\
           [get_ports {wr_data[23]}]\
           [get_ports {wr_data[24]}]\
           [get_ports {wr_data[25]}]\
           [get_ports {wr_data[26]}]\
           [get_ports {wr_data[27]}]\
           [get_ports {wr_data[28]}]\
           [get_ports {wr_data[29]}]\
           [get_ports {wr_data[2]}]\
           [get_ports {wr_data[30]}]\
           [get_ports {wr_data[31]}]\
           [get_ports {wr_data[3]}]\
           [get_ports {wr_data[4]}]\
           [get_ports {wr_data[5]}]\
           [get_ports {wr_data[6]}]\
           [get_ports {wr_data[7]}]\
           [get_ports {wr_data[8]}]\
           [get_ports {wr_data[9]}]\
           [get_ports {wr_en[0]}]]
group_path -name REGOUT\
    -to [list [get_ports {rd_data[0]}]\
           [get_ports {rd_data[10]}]\
           [get_ports {rd_data[11]}]\
           [get_ports {rd_data[12]}]\
           [get_ports {rd_data[13]}]\
           [get_ports {rd_data[14]}]\
           [get_ports {rd_data[15]}]\
           [get_ports {rd_data[16]}]\
           [get_ports {rd_data[17]}]\
           [get_ports {rd_data[18]}]\
           [get_ports {rd_data[19]}]\
           [get_ports {rd_data[1]}]\
           [get_ports {rd_data[20]}]\
           [get_ports {rd_data[21]}]\
           [get_ports {rd_data[22]}]\
           [get_ports {rd_data[23]}]\
           [get_ports {rd_data[24]}]\
           [get_ports {rd_data[25]}]\
           [get_ports {rd_data[26]}]\
           [get_ports {rd_data[27]}]\
           [get_ports {rd_data[28]}]\
           [get_ports {rd_data[29]}]\
           [get_ports {rd_data[2]}]\
           [get_ports {rd_data[30]}]\
           [get_ports {rd_data[31]}]\
           [get_ports {rd_data[32]}]\
           [get_ports {rd_data[33]}]\
           [get_ports {rd_data[34]}]\
           [get_ports {rd_data[35]}]\
           [get_ports {rd_data[36]}]\
           [get_ports {rd_data[37]}]\
           [get_ports {rd_data[38]}]\
           [get_ports {rd_data[39]}]\
           [get_ports {rd_data[3]}]\
           [get_ports {rd_data[40]}]\
           [get_ports {rd_data[41]}]\
           [get_ports {rd_data[42]}]\
           [get_ports {rd_data[43]}]\
           [get_ports {rd_data[44]}]\
           [get_ports {rd_data[45]}]\
           [get_ports {rd_data[46]}]\
           [get_ports {rd_data[47]}]\
           [get_ports {rd_data[48]}]\
           [get_ports {rd_data[49]}]\
           [get_ports {rd_data[4]}]\
           [get_ports {rd_data[50]}]\
           [get_ports {rd_data[51]}]\
           [get_ports {rd_data[52]}]\
           [get_ports {rd_data[53]}]\
           [get_ports {rd_data[54]}]\
           [get_ports {rd_data[55]}]\
           [get_ports {rd_data[56]}]\
           [get_ports {rd_data[57]}]\
           [get_ports {rd_data[58]}]\
           [get_ports {rd_data[59]}]\
           [get_ports {rd_data[5]}]\
           [get_ports {rd_data[60]}]\
           [get_ports {rd_data[61]}]\
           [get_ports {rd_data[62]}]\
           [get_ports {rd_data[63]}]\
           [get_ports {rd_data[6]}]\
           [get_ports {rd_data[7]}]\
           [get_ports {rd_data[8]}]\
           [get_ports {rd_data[9]}]]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0100 [get_ports {rd_data[63]}]
set_load -pin_load 0.0100 [get_ports {rd_data[62]}]
set_load -pin_load 0.0100 [get_ports {rd_data[61]}]
set_load -pin_load 0.0100 [get_ports {rd_data[60]}]
set_load -pin_load 0.0100 [get_ports {rd_data[59]}]
set_load -pin_load 0.0100 [get_ports {rd_data[58]}]
set_load -pin_load 0.0100 [get_ports {rd_data[57]}]
set_load -pin_load 0.0100 [get_ports {rd_data[56]}]
set_load -pin_load 0.0100 [get_ports {rd_data[55]}]
set_load -pin_load 0.0100 [get_ports {rd_data[54]}]
set_load -pin_load 0.0100 [get_ports {rd_data[53]}]
set_load -pin_load 0.0100 [get_ports {rd_data[52]}]
set_load -pin_load 0.0100 [get_ports {rd_data[51]}]
set_load -pin_load 0.0100 [get_ports {rd_data[50]}]
set_load -pin_load 0.0100 [get_ports {rd_data[49]}]
set_load -pin_load 0.0100 [get_ports {rd_data[48]}]
set_load -pin_load 0.0100 [get_ports {rd_data[47]}]
set_load -pin_load 0.0100 [get_ports {rd_data[46]}]
set_load -pin_load 0.0100 [get_ports {rd_data[45]}]
set_load -pin_load 0.0100 [get_ports {rd_data[44]}]
set_load -pin_load 0.0100 [get_ports {rd_data[43]}]
set_load -pin_load 0.0100 [get_ports {rd_data[42]}]
set_load -pin_load 0.0100 [get_ports {rd_data[41]}]
set_load -pin_load 0.0100 [get_ports {rd_data[40]}]
set_load -pin_load 0.0100 [get_ports {rd_data[39]}]
set_load -pin_load 0.0100 [get_ports {rd_data[38]}]
set_load -pin_load 0.0100 [get_ports {rd_data[37]}]
set_load -pin_load 0.0100 [get_ports {rd_data[36]}]
set_load -pin_load 0.0100 [get_ports {rd_data[35]}]
set_load -pin_load 0.0100 [get_ports {rd_data[34]}]
set_load -pin_load 0.0100 [get_ports {rd_data[33]}]
set_load -pin_load 0.0100 [get_ports {rd_data[32]}]
set_load -pin_load 0.0100 [get_ports {rd_data[31]}]
set_load -pin_load 0.0100 [get_ports {rd_data[30]}]
set_load -pin_load 0.0100 [get_ports {rd_data[29]}]
set_load -pin_load 0.0100 [get_ports {rd_data[28]}]
set_load -pin_load 0.0100 [get_ports {rd_data[27]}]
set_load -pin_load 0.0100 [get_ports {rd_data[26]}]
set_load -pin_load 0.0100 [get_ports {rd_data[25]}]
set_load -pin_load 0.0100 [get_ports {rd_data[24]}]
set_load -pin_load 0.0100 [get_ports {rd_data[23]}]
set_load -pin_load 0.0100 [get_ports {rd_data[22]}]
set_load -pin_load 0.0100 [get_ports {rd_data[21]}]
set_load -pin_load 0.0100 [get_ports {rd_data[20]}]
set_load -pin_load 0.0100 [get_ports {rd_data[19]}]
set_load -pin_load 0.0100 [get_ports {rd_data[18]}]
set_load -pin_load 0.0100 [get_ports {rd_data[17]}]
set_load -pin_load 0.0100 [get_ports {rd_data[16]}]
set_load -pin_load 0.0100 [get_ports {rd_data[15]}]
set_load -pin_load 0.0100 [get_ports {rd_data[14]}]
set_load -pin_load 0.0100 [get_ports {rd_data[13]}]
set_load -pin_load 0.0100 [get_ports {rd_data[12]}]
set_load -pin_load 0.0100 [get_ports {rd_data[11]}]
set_load -pin_load 0.0100 [get_ports {rd_data[10]}]
set_load -pin_load 0.0100 [get_ports {rd_data[9]}]
set_load -pin_load 0.0100 [get_ports {rd_data[8]}]
set_load -pin_load 0.0100 [get_ports {rd_data[7]}]
set_load -pin_load 0.0100 [get_ports {rd_data[6]}]
set_load -pin_load 0.0100 [get_ports {rd_data[5]}]
set_load -pin_load 0.0100 [get_ports {rd_data[4]}]
set_load -pin_load 0.0100 [get_ports {rd_data[3]}]
set_load -pin_load 0.0100 [get_ports {rd_data[2]}]
set_load -pin_load 0.0100 [get_ports {rd_data[1]}]
set_load -pin_load 0.0100 [get_ports {rd_data[0]}]
###############################################################################
# Design Rules
###############################################################################
