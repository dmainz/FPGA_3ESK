module test_fpga;

   reg clk, rstn, PGDx_in;
   reg button;
   wire [7:0] leds;
   wire       PGDx_IO;
   reg [15:0] dout;
   
   fpga_top fpga (
		  .clk50MHz(clk),
		  .reset(~rstn), 
		  .PGCx(PGCx), 
		  .PGDx_IO(PGDx_IO),
		  .MCLRn(MCLRn),
		  .leds(leds),
		  .button(button)    
		  );
   
   initial begin
      $dumpfile("fpga.vcd");
      $dumpvars(0, test_fpga);
      clk = 1'b0;
      rstn = 1'b0;
      PGDx_in = 1'b0;
      button = 1'b0;
      dout = 16'habcd;
   end

   always
     #62 clk=~clk;
   
   initial begin
      {PGDx_in,dout[15:1]} = dout[15:0];
      repeat (10) @(posedge clk);
      rstn = 1'b1;
      repeat (20000) @(posedge clk);
      button = 1'b1;
      repeat (100) @(posedge clk);
      button = 1'b0;
      repeat (100) @(posedge clk);
      button = 1'b1;
      repeat (100) @(posedge clk);
      button = 1'b0;
      $display("%t done.",$time);
      $finish;
   end

   always @(negedge PGCx)
     if(fpga.PGDx_dir) begin
	{PGDx_in,dout[15:1]} <= dout[15:0];
     end
//     else begin
//	PGDx_in <= 1'b0;
//	dout <= 16'habcd;
//     end
   
   
   assign PGDx_IO = fpga.PGDx_dir ? PGDx_in : 1'bz;
       
endmodule // testp24prog
