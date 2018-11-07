create_clock -period 20 [get_ports clk50MHz]
create_clock -period 125 [get_nets clk]

set_property IOSTANDARD LVCMOS33 [get_ports PGCx]
set_property LOC D12 [get_ports PGCx]
set_property SLEW FAST [get_ports PGCx]

set_property IOSTANDARD LVCMOS33 [get_ports PGDx_IO]
set_property LOC C12 [get_ports PGDx_IO]
set_property SLEW FAST [get_ports PGDx_IO]

set_property IOSTANDARD LVCMOS33 [get_ports MCLRn]
set_property LOC E13 [get_ports MCLRn]
set_property SLEW FAST [get_ports MCLRn]

set_property IOSTANDARD LVCMOS33 [get_ports clk50MHz]
set_property LOC C9 [get_ports clk50MHz]

set_property IOSTANDARD LVCMOS33 [get_ports reset]
## BTN_NORTH
set_property LOC V4 [get_ports reset]

set_property IOSTANDARD LVCMOS33 [get_ports button]
## BTN_EAST
set_property LOC H13 [get_ports button]

set_property IOSTANDARD LVTTL [get_ports leds*]
set_property LOC F9  [get_ports {leds[7]}]
set_property LOC E9  [get_ports {leds[6]}]
set_property LOC D11 [get_ports {leds[5]}]
set_property LOC C11 [get_ports {leds[4]}]
set_property LOC F11 [get_ports {leds[3]}]
set_property LOC E11 [get_ports {leds[2]}]
set_property LOC E12 [get_ports {leds[1]}]
set_property LOC F12 [get_ports {leds[0]}]
