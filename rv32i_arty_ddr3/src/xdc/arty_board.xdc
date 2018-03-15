
## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports board_clock]
create_clock -period 10.000 -name board_clock -waveform {0.000 5.000} -add [get_ports board_clock]
create_clock -period 40.000 -name xtck -waveform {0.000 20.000} [get_pins bse2_inst/TCK]

set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[4] }]; #IO_L24N_T3_35 Sch=led[4]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[5] }]; #IO_25_35 Sch=led[5]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[6] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[7] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]

# Remove TIG constraint by sampling twice
#set_false_path -through [get_nets rvmemspv/axi_mig_ddr3/init_calib_complete]