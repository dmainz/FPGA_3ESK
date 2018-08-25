
module pic24progmem #(parameter DATAWIDTH=32, MEMSIZElog2=7) (
							      input 		      clk,
							      input 		      rstn,
							      input [MEMSIZElog2-1:0] addr,
							      input 		      ce,
							      input 		      we,
							      input [DATAWIDTH-1:0]   din,
							      output [DATAWIDTH-1:0]  dout
							      );
   localparam ADDRSIZE = (16'b1 << MEMSIZElog2);
   
   reg [DATAWIDTH-1:0] 	mem [ADDRSIZE-1:0];
   reg [DATAWIDTH-1:0] 	dout_reg;

   assign dout = dout_reg;
   
   always @(posedge clk or negedge rstn) begin
      if(~rstn) begin
	 dout_reg <= { DATAWIDTH {1'b0}};
      end
      if(ce == 1'b1) begin
	 if(we == 1'b1)
	   mem[addr] <= din;
	 else
	   dout_reg <= mem[addr];
      end
   end

endmodule // pic24progmem
