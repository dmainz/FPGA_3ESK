/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

`ifdef X16
`define DDRBITS 16
`define FMLBITS 32
`define DDRBYTES 2
`define FMLBYTES 4
`endif
`ifdef X32
`define DDRBITS 32
`define FMLBITS 64
`define DDRBYTES 4
`define FMLBYTES 8
`endif

module hpdmc_ddrio(
	input sys_clk,
	input sys_clk_n,
	input dqs_clk,
	input dqs_clk_n,
	
	input direction,
	input direction_r,
	input [`FMLBYTES-1:0] mo,
	input [`FMLBITS-1:0] do,
	output [`FMLBITS-1:0] di,
	
	output [`DDRBYTES-1:0] sdram_dm,
	inout [`DDRBITS-1:0] sdram_dq,
	inout [`DDRBYTES-1:0] sdram_dqs,
	
	input idelay_rst,
	input idelay_ce,
	input idelay_inc
);

/******/
/* DQ */
/******/

wire [`DDRBITS-1:0] sdram_dq_t;
wire [`DDRBITS-1:0] sdram_dq_out;
wire [`DDRBITS-1:0] sdram_dq_in;

hpdmc_iobuf32 iobuf_dq(
	.T(sdram_dq_t),
	.I(sdram_dq_out),
	.O(sdram_dq_in),
	.IO(sdram_dq)
);

hpdmc_oddr32 oddr_dq_t(
	.Q(sdram_dq_t),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0({`DDRBITS{~direction_r}}),
	.D1({`DDRBITS{~direction_r}}),
	.R(1'b0),
	.S(1'b0)
);

hpdmc_oddr32 oddr_dq(
	.Q(sdram_dq_out),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(do[`FMCBITS-1:`DDRBITS]),
	.D1(do[`DDRBITS-1:0]),
	.R(1'b0),
	.S(1'b0)
);

hpdmc_iddr32 iddr_dq(
	.Q0(di[`DDRBITS-1:0]),
	.Q1(di[`FMCBITS-1:`DDRBITS]),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D(sdram_dq_in),
	.R(1'b0),
	.S(1'b0)
);

/*******/
/* DM */
/*******/

hpdmc_oddr4 oddr_dm(
	.Q(sdram_dm),
	.C0(sys_clk),
	.C1(sys_clk_n),
	.CE(1'b1),
	.D0(mo[`FMCBYTES-1:`DDRBYTES]),
	.D1(mo[`DDRBYTES-1:0]),
	.R(1'b0),
	.S(1'b0)
);

/*******/
/* DQS */
/*******/

wire [`DDRBYTES-1:0] sdram_dqs_t;
wire [`DDRBYTES-1:0] sdram_dqs_out;

hpdmc_obuft4 obuft_dqs(
	.T(sdram_dqs_t),
	.I(sdram_dqs_out),
	.O(sdram_dqs)
);

hpdmc_oddr4 oddr_dqs_t(
	.Q(sdram_dqs_t),
	.C0(dqs_clk),
	.C1(dqs_clk_n),
	.CE(1'b1),
	.D0({`DDRBYTES{~direction_r}}),
	.D1({`DDRBYTES{~direction_r}}),
	.R(1'b0),
	.S(1'b0)
);

hpdmc_oddr4 oddr_dqs(
	.Q(sdram_dqs_out),
	.C0(dqs_clk),
	.C1(dqs_clk_n),
	.CE(1'b1),
	.D0((`DDRBYTES-1)'hf),
	.D1((`DDRBYTES-1)'h0),
	.R(1'b0),
	.S(1'b0)
);

endmodule
