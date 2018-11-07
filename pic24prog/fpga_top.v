module fpga_top (
		 input clk50MHz, 
		 input reset,
		 output PGCx, 
		 inout PGDx_IO,
		 output MCLRn,
		 output [7:0] leds,
		 input button
		 );

   wire	       PGDx_in;
   wire        PGDx_dir;
   wire        PGDx_out;
	       
`ifndef SIM
   IOBUF pgdx (.T(PGDx_dir),.I(PGDx_out),.O(PGDx_in),.IO(PGDx_IO));
`else
   assign PGDx_in = PGDx_dir ? PGDx_IO : 1'b0;
   assign PGDx_IO = PGDx_dir ? 1'bz : PGDx_out;
`endif
   
   wire [15:0] dout;
   wire        dvalid;
   
pic24programmer p24prog
  ( clk50MHz, 
    ~reset,
    PGCx, 
    PGDx_in,
    PGDx_out,
    PGDx_dir,
    MCLRn,
    dvalid,
    dout
     );

   reg [15:0] data;
   always @(posedge clk50MHz or posedge reset) begin
      if(reset)
	data <= 16'h0000;
      else
	if(dvalid)
	  data <= dout;
   end

   reg [7:0] leds_reg;
   reg [3:0] button_state;
   reg 	     toggle;
   
   assign leds = leds_reg;

   always @(posedge clk50MHz or posedge reset) begin
      if(reset)
	button_state <= 1'b0;
      else
	  button_state <= {button_state[2:0],button};
   end
   
   always @(posedge clk50MHz or posedge reset) begin
      if(reset)
	toggle <= 1'b0;
      else begin
	 if(~button_state[3] & button_state[2])
	   toggle <= ~toggle;
      end
   end

   always @(posedge clk50MHz or posedge reset) begin
      if(reset)
	leds_reg <= 8'h00;
      else begin
	 if(~toggle)
	   leds_reg <= data[15:0];
	 else
	   leds_reg <= data[15:8];
      end
   end

endmodule // fpga_top
