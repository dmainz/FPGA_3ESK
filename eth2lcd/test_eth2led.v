`timescale 1ns/1ns

module test_eth2led();
   reg clk;
   reg reset_n;
   reg [3:0] data;
   reg valid;
   reg rot_a;
   reg rot_b;

   wire ready;

   integer i,j;

   initial begin
      clk = 0;
      reset_n = 0;
      data = 4'h0;
      valid = 1'b0;
      rot_a = 1'b0;
      rot_b = 1'b0;
   end

   always
     #10 clk = ~clk;

   initial begin
      $dumpfile("lcd.vcd");
      $dumpvars(0, test_eth2led);
      repeat (10) @(posedge clk);
      repeat (10) @(posedge clk);
      reset_n = 1'b1;
      fork
	 begin
	    for(i=0;i<100;i=i+1) begin
	       sendpacket;
	       repeat (10) @(posedge clk);
	    end
	 end
	 begin
	    sendrot;
	 end
      join
      #1000 $finish;
   end // initial begin

   task sendpacket;
      begin
	 valid = 1'b1;
	 for(j=0;j<64;j=j+1) begin
	    @(posedge clk) data = j;
	 end
	 valid = 1'b0;
      end
   endtask // for
   task sendrot;
      begin
	 repeat (3) @(posedge led0.lcd_rdy);
	 #1000 rot_b = 1;
	 #100  rot_a = 1;
	 #100  rot_b = 0;
	 #50   rot_a = 0;
	 repeat (32) @(posedge led0.lcd_rdy);
	 #10000 rot_b = 1;
	 #100   rot_a = 1;
	 #100   rot_b = 0;
	 #100   rot_a = 0;
	 repeat (32) @(posedge led0.lcd_rdy);
	 #10000 rot_a = 1;
	 #100  rot_b = 1;
	 #100  rot_a = 0;
	 #50   rot_b = 0;
	 repeat (32) @(posedge led0.lcd_rdy);
	 #10000 rot_a = 1;
	 #100  rot_b = 1;
	 #100  rot_a = 0;
	 #50   rot_b = 0;
	 repeat (32) @(posedge led0.lcd_rdy);
      end
   endtask
   
   
   eth2led_top led0 (
		     .LED(),
		     .ROT_A(rot_a),
		     .ROT_B(rot_b),
		     .E_RXD(data),
		     .E_RX_DV(valid),
		     .E_RX_CLK(clk),
		     .SF_D(),
		     .LCD_E(),
		     .LCD_RS(),
		     .LCD_RW(),
		     .RST_N(reset_n)
	       );
   
endmodule
