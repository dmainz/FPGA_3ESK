module testp24prog;

   reg clk, rstn, PGDx_in;
   wire [15:0] dout;
   wire        dvalid;
   
   pic24flashprog prog(.clk(clk), .rstn(rstn), 
		       .PGCx(PGCx), 
		       .PGDx_in(PGDx_in),
		       .PGDx_out(PGDx_out),
		       .PGDx_dir(PGDx_dir),
		       .MCLRn(MCLRn),
		       .dvalid(dvalid),
		       .dout(dout)    
		       );
   
   initial begin
      $dumpfile("pic24prog.vcd");
      $dumpvars(0, testp24prog);
      clk = 1'b0;
      rstn = 1'b0;
      PGDx_in = 1'b0;
   end

   always
     #62 clk=~clk;
   
   initial begin
      repeat (10) @(posedge clk);
      rstn = 1'b1;
      repeat (20000) @(posedge clk);
      $display("%t done.",$time);
      $finish;
   end
endmodule // testp24prog
