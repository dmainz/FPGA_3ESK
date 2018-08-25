`timescale 1ns/1ns

module test_lcd_driver();
   reg clk;
   reg reset_n;
   reg [7:0] data;
   reg write;
   reg data1cmd0;

   wire ready;

   initial begin
      clk = 0;
      reset_n = 0;
      data = 7'h00;
      write = 1'b0;
      data1cmd0 = 1'b0;
   end

   always
     #10 clk = ~clk;

   initial begin
      $dumpfile("lcd.vcd");
      $dumpvars(0, test_lcd_driver);
      repeat (10) @(posedge clk);
      reset_n = 1'b1;
      while(!ready)
	@(posedge clk);
      data = 8'hab;
      data1cmd0 = 1'b0;
      write = 1'b1;
      @(posedge clk);
      write = 1'b0;
      while(!ready)
	@(posedge clk);
      #1000 $finish;
      
   end // initial begin

   lcd_driver lcd0 ( .clk(clk),
	       .reset_n(reset_n),
	       .data(data),
	       .write(write),
	       .data1cmd0(data1cmd0),
	       .ready(ready),
	       .lcd_data(),
	       .lcd_en(),
	       .lcd_regsel(),
	       .lcd_r1w0()
	       );
   
endmodule