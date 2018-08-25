`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:54:51 09/19/2015 
// Design Name: 
// Module Name:    eth2led_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module eth2led_top(
		   LED,
		   ROT_A,ROT_B,
		   E_RXD, E_RX_DV, E_RX_CLK, 
		   SF_D, LCD_E, LCD_RS, LCD_RW, 
		   RST_N);

   // LED
   output [7:0] LED;
   //    input CLK_50MHZ;

   // RGMII
   input [3:0] 	E_RXD;
   input 	E_RX_DV;
   input 	E_RX_CLK;
   //   input 	E_RX_ER;

   // LCD
   output [11:8] SF_D;
   output 	 LCD_E;
   output 	 LCD_RS;
   output        LCD_RW;

   input         ROT_A;
   input         ROT_B;
   
   input 	 RST_N;
 
// Internals
   reg [7:0] 	led_ff;
   reg 	     two_count;
   reg [9:0] wr_addr;
   reg [9:0] rd_addr;
   reg 	      mem_read;
   reg        mem_write;
   reg 	      rotary_q1;
   reg 	      rotary_q1_delay;
   reg 	      rotary_q2;
   wire [15:0] ascii;
   wire [15:0] lcd_data_x2;
   
   reg [7:0] lcd_data;
   reg 	     write_lcd;
   reg 	     lcd_cmd;
   reg [3:0] lcd_state;
   reg [3:0] next_lcd_state;
   reg [3:0] counter;
   reg 	     rot_event;
   reg 	     leftturn;
   reg [2:0] mem_wait;
   
   assign LED = wr_addr[9:2];
   //	 assign LED = counter[31:24];
	 
   always @(posedge E_RX_CLK or negedge RST_N)
     if(!RST_N) begin
	wr_addr <= 10'h000;
	rd_addr <= 10'h000;
	two_count <= 1'b0;
     end
     else
       two_count <= ~two_count;
		
   always @(posedge E_RX_CLK or negedge RST_N)
     if(!RST_N)
       led_ff <= 8'h00;
     else begin
	mem_write <= 1'b0;
	if(!two_count & E_RX_DV)
	  led_ff[3:0] <= E_RXD;
	else if (two_count & E_RX_DV) begin
	   led_ff[7:4] <= E_RXD;
	   wr_addr <= wr_addr + 10'b1;
	   mem_write <= 1'b1;
	end
     end

   assign ascii[15:8] = (led_ff[7:4] > 4'h9)? led_ff[7:4] + 8'h37 : led_ff[7:4]+8'h30;
   assign ascii[7:0] =  (led_ff[3:0] > 4'h9)? led_ff[3:0] + 8'h37 : led_ff[3:0]+8'h30;
   
   //    always @(posedge E_RX_CLK) begin
   //	     counter = counter + 1;
   //    end

`ifdef SIM
   reg [15:0] mem0 [0:1023];
   integer    i;
   reg [15:0] mem_out;
   
   assign lcd_data_x2 = mem_out;
   
   always @(posedge E_RX_CLK or negedge RST_N) begin
      if(!RST_N) begin
	 for(i=0;i<1024;i=i+1) mem0[i] <= 16'h0000;
	 mem_out = 16'h0000;
      end
      else
	if(mem_write) mem0[wr_addr] <= ascii;
        if(mem_read)  mem_out <= mem0[rd_addr];
   end
   
`else   
   RAMB16_S18_S18 mem0 (
		        .WEA(mem_write),
		        .ENA(mem_write),
		       .SSRA(~RST_N),
		       .CLKA(E_RX_CLK),
		      .ADDRA(wr_addr),
		        .DIA(ascii),
		       .DIPA(1'b0),
		       .DOPA(),
		        .DOA(),
		        .WEB(1'b0),
		        .ENB(mem_read),
		       .SSRB(~RST_N),
		       .CLKB(E_RX_CLK),
		      .ADDRB(rd_addr),
		        .DIB(8'h00),
		       .DIPB(1'b0),
		       .DOPB(),
		        .DOB(lcd_data_x2)
		      );
`endif // !`ifdef SIM
   
   always @(posedge E_RX_CLK) begin
      case ({ROT_B,ROT_A})
	2'b00: begin
	   rotary_q1 <= 1'b0;
	   rotary_q2 <= rotary_q2;
	end
	2'b01: begin
	   rotary_q1 <= rotary_q1;
	   rotary_q2 <= 1'b0;
	end
	2'b10: begin
	   rotary_q1 <= rotary_q1;
	   rotary_q2 <= 1'b1;
	end
	2'b11: begin
	   rotary_q1 <= 1'b1;
	   rotary_q2 <= rotary_q2;
	end
      endcase
   end
		      
   always @(posedge E_RX_CLK or negedge RST_N) begin
      if(~RST_N) begin
	 rot_event <= 1'b0;
	 rotary_q1 <= 1'b0;
	 rotary_q1_delay <= 1'b0;
	 rotary_q2 <= 1'b0;
	 leftturn <= 1'b0;
      end
      else begin
	 rotary_q1_delay <= rotary_q1;
	 if (rotary_q1 == 1'b1 && rotary_q1_delay == 1'b0) begin
	    rot_event <= 1'b1;
	 //right turn.  increase address.
	    leftturn <= rotary_q2;
	 end
	 else begin
	    rot_event <= 1'b0;
	    leftturn <= leftturn;
	 end
      end // else: !if(~RST_N)
   end

   lcd_driver lcd0 (
		   .clk(E_RX_CLK),
		   .reset_n(RST_N),
		   .data(lcd_data),
		   .write(write_lcd),
		   .data1cmd0(lcd_cmd),
		   .lcd_data(SF_D),
		   .lcd_en(LCD_E),
		   .lcd_regsel(LCD_RS),
		   .lcd_r1w0(LCD_RW),
		   .ready(lcd_rdy) 	
		   );

   always @(next_lcd_state) lcd_state <= next_lcd_state;
   
   always @(posedge E_RX_CLK or negedge RST_N) begin
      if(!RST_N) begin
	 lcd_state <= 3'b000;
	 lcd_data <= 8'h00;
	 lcd_cmd <= 1'b0;
	 write_lcd <= 1'b0;
	 next_lcd_state <= 3'b000;
	 counter <= 4'b0000;
	 mem_read <= 1'b0;
	 mem_wait <= 3'b000;
      end
      else begin
	 write_lcd <= 1'b0;
	 mem_read <= 1'b0;
	 case(lcd_state)
	   3'b000: begin
	      if(lcd_rdy) begin
		 lcd_data <= 8'h28;  //Function set
		 write_lcd <= 1'b1;
		 next_lcd_state <= 3'b001;
	      end
	   end
	   3'b001: begin
	      if(lcd_rdy) begin
		 lcd_data <= 8'h06;  //Entry mode: increment, no shift
		 write_lcd <= 1'b1;
		 next_lcd_state <= 3'b010;
	      end
	   end
	   3'b010: begin
	      if(lcd_rdy) begin
		 lcd_data <= 8'h0C;  //Display on : DDRAM,NoCursor,NoBlink
		 write_lcd <= 1'b1;
		 next_lcd_state <= 3'b011;
	      end
	   end
	   3'b011: begin
	      if(lcd_rdy) begin
		 lcd_data <= 8'h01;  //Clear display
		 write_lcd <= 1'b1;
		 next_lcd_state <= 3'b100;
	      end
	   end
	   3'b100: begin
	      if(rot_event) begin
		 mem_read <= 1'b1;  // need another state
		 if(leftturn) rd_addr = rd_addr - 10'h20;
		 counter <= 4'h0;
		 next_lcd_state <= 3'b111;
	      end
	   end
	   3'b101: begin
	      if(lcd_rdy) begin
		 if(mem_wait == 3'h7) begin
		    write_lcd <= 1'b1;
		    lcd_cmd <= 1'b1;
		    lcd_data <= lcd_data_x2[7:0];
		    next_lcd_state <= 3'b110;
		    rd_addr <= rd_addr + 1;
		    counter <= counter + 1;
		    if(counter == 4'hf)
		      next_lcd_state <= 3'b100;
		 end
		 else begin
		    write_lcd <= 1'b0;
		 end
		 mem_wait <= mem_wait + 3'h1;
	      end
	   end
	   3'b110: begin
	      if(lcd_rdy) begin
		 if(mem_wait == 3'h0) mem_read <= 1'b1;
		 if(mem_wait == 3'h7) begin
		    write_lcd <= 1'b1;
		    lcd_cmd <= 1'b1;
		    lcd_data <= lcd_data_x2[15:8];
		    next_lcd_state <= 3'b101;
		 end
		 else begin
		    write_lcd <= 1'b0;
		 end
		 mem_wait <= mem_wait + 3'h1;
	      end
	   end
	   3'b111: begin
	      if(mem_wait == 3'h7) begin
		 lcd_data <= lcd_data_x2[15:8];
		 if(lcd_rdy) begin
		    write_lcd <= 1'b1;
		    lcd_cmd <= 1'b1;
		    next_lcd_state <= 3'b101;
		 end
	      end
	      mem_wait <= mem_wait + 3'h1;
	   end
	 endcase // case (lcd_state)
      end
   end
endmodule
