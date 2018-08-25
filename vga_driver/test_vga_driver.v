`timescale 1ns/100ps

module test_vga_driver();
   reg clk;
   reg reset;
   wire vsync;
   wire hsync;
   wire red;
   wire green;
   wire blue;

   initial begin
      clk = 0;
      reset = 1;
   end

   always
     #12.5 clk = ~clk;

   initial begin
      $dumpfile("vga.vcd");
      $dumpvars(0, test_vga_driver);
      repeat (10) @(posedge clk);
      reset = 1'b0;
      repeat (1350000) @(posedge clk);
      #10 $finish;
   end // initial begin

   vga_driver vga0 ( 
		     .clk(clk),
		     .rst(reset),
		     .vsync(vsync),
		     .hsync(hsync),
		     .red(red),
		     .green(green),
		     .blue(blue)
		     );
endmodule
