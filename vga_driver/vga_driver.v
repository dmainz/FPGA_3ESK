module vga_driver(output red, output green, output blue, output hsync, output vsync, input clk, input rst);

   parameter HRES = 800;
   parameter VRES = 600;
   
   wire [2:0] color;

   wire vdisp;
   wire hdisp;
   wire rst_n;

   reg [9:0] hcounter;
   reg [9:0] vcounter;
//   reg 	     halfclk;
	wire       clk40mhz;
   
   assign red = color[2];
   assign green = color[1];
   assign blue = color[0];
   assign rst_n = ~rst;

`ifndef SIM
   `include "clock_divider.vh"
`else
   assign clk40mhz = clk;
`endif
   
//   always @(posedge clk or negedge rst_n) begin
//      if(~rst_n)
//	halfclk <= 1'b0;
//      else
//	halfclk <= ~halfclk;
//   end
   
   always @(negedge hsync or negedge rst_n) begin
      if(~rst_n)
	vcounter <= 10'h000;
      else if(vcounter == VRES-1)
	vcounter <= 10'h000;
      else if(vdisp)
	vcounter <= vcounter + 1'b1;
   end

   always @(posedge clk40mhz or negedge rst_n) begin
      if(~rst_n )
	hcounter <= 10'h000;
      else if(hcounter == HRES-1 || !vdisp || !hdisp)
	hcounter <= 10'h000;
      else if(hdisp)
	hcounter <= hcounter + 1'b1;
   end
	
//   always @(posedge clk40mhz or negedge rst_n) begin
//      if(~rst_n)
//	      color <= 3'b000;
//      else begin
//	 if(vdisp == 1'b0 || hdisp == 1'b0)
//	   color <= 3'b000;
//	 else if(vcounter == VRES-1 || vcounter == 10'h000)
//	   color <= 3'b000;
//         else if( (hdisp && hcounter[4:0]==5'b00000)) // ||(~hdisp && hcounter == 0 ) )
//	   color <= color + 3'b001;
//      end
//   end
   
   vga_sync_timing vga_sync(vsync,hsync,vdisp,hdisp,clk40mhz,rst_n);

   color_mem #(VRES,HRES) cmem(
			       .clk(clk40mhz),
			       .rst_n(rst_n),
			       .v_disp(vdisp),
			       .h_disp(hdisp),
			       .color(color),
			       .hcounter(hcounter),
			       .vcounter(vcounter)
			       );
   
endmodule // vga_driver
