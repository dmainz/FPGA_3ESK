module lcd_driver (
		   input 	clk,
		   input 	reset_n,
		   input [7:0] 	data,
		   input 	write,
		   input 	data1cmd0,
		   output reg [3:0] lcd_data,
		   output reg 	lcd_en,
		   output reg 	lcd_regsel,
		   output reg 	lcd_r1w0,
		   output reg   ready 	
		   );
   
   reg [1:0] 			lcd_state, next_lcd_state, return_lcd_state;
   reg [1:0] 			write_state, next_write_state, return_write_state;
   reg [1:0] 			init_state, next_init_state;
   reg [2:0] 			wait_index;
   reg [17:0] 			wait_list [6:0];
   
   always @(*) begin
      lcd_state <= next_lcd_state;
      init_state <= next_init_state;
      write_state <= next_write_state;
   end
   
   always @(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
	 lcd_data <= 4'h0;
	 lcd_en <= 1'b0;
	 lcd_regsel <= 1'b0;
	 lcd_r1w0 <= 1'b0;
	 
	 lcd_state <= 2'b00;
	 next_lcd_state <= 2'b00;
	 return_lcd_state <= 2'b00;
	 init_state <= 2'b00;
	 next_init_state <= 2'b00;
	 
	 write_state <= 2'b00;
	 next_write_state <= 2'b00;
	 return_write_state <= 2'b00;
	 wait_index <= 2'b00;
	 wait_list[0] = 18'd12/2;
	 wait_list[1] = 18'd50/2;
	 wait_list[2] = 18'd80/2;
	 wait_list[3] = 18'd205000/2;
	 wait_list[4] = 18'd5000/2;
	 wait_list[5] = 18'd2000/2;
	 wait_list[6] = 18'd2000/2;
	 
	 ready <= 1'b0;
	 
      end
      else begin
	 case(lcd_state)
	    2'b00: begin // init
	       case(init_state)
		  2'b00: begin
		     lcd_regsel <= 1'b0;
		     lcd_r1w0 <= 1'b0;
		     lcd_data <= (wait_index < 3) ? 8'h03:8'h02;
		     lcd_regsel <= 1'b0;
		     wait_list[0] = 18'd12/2;
		     next_init_state <= 2'b01; // wait state
		     next_lcd_state <= 2'b11;
		     return_lcd_state <= 2'b00;
		  end   
		  2'b01: begin
		     if(wait_list[wait_index+3] == 18'h00000) begin
			if(wait_index < 3) begin
			   next_init_state <= 2'b00;
			   wait_index = wait_index +1;
			end
			else begin
			   next_lcd_state <= 2'b01;
			end
		     end
		     else begin
			wait_list[wait_index+3] <= wait_list[wait_index+3] - 1;
		     end
		  end
	       endcase // case (init_state)
	    end // 2'b00
	    2'b01: begin // write MSnibble
	       if(write) begin
		  lcd_r1w0 <= 1'b0;
		  lcd_data <= data[7:4];
		  lcd_regsel <= data1cmd0;
		  ready <= 1'b0;
		  wait_list[0] <= 18'd12/2;  // 240ns
		  wait_list[1] <= 18'd50/2;  // 1us
		  next_lcd_state <= 2'b11;
		  return_lcd_state <= 2'b10;
	       end
	       else
		 ready <= 1'b1;
	    end // case: 2'b01
	    2'b10: begin // write LSnibble
	       lcd_r1w0 <= 1'b0;
	       lcd_data <= data[3:0];
	       wait_list[0] <= 18'd12/2;  // 240ns
	       wait_list[2] <= 18'd2000/2; // 40ns
	       next_lcd_state <= 2'b11;
	       return_lcd_state <= 2'b01;
	    end
	    2'b11: begin  // write
	       ready <= 1'b0;
	       case(write_state)
		  2'b00: begin
		     next_write_state <= 2'b01; // wait state
		     return_write_state <= 2'b10;
		  end   
		  2'b01: begin  // hold write trans for 240ns
		     lcd_en <= 1'b1;
		     if(wait_list[0] == 18'h00000) begin
			next_write_state <= return_write_state;
			lcd_en <= 1'b0;
		     end
		     else
		       wait_list[0] <= wait_list[0] - 1;
		  end
		  2'b10: begin  // de-assert lcd_rw and wait 1us
		     lcd_r1w0 <= 1'b1;
		     if(wait_list[1] == 18'h00000) begin
			next_write_state <= 2'b01; // write lower nibble
			return_write_state <= 2'b11;
			next_lcd_state <= return_lcd_state;
		     end
		     else
		       wait_list[1] <= wait_list[1] - 1;
		  end
		  2'b11: begin  // de-assert lcd_rw and wait 40us
		     lcd_r1w0 <= 1'b1;
		     if(wait_list[2] == 18'h00000) begin
			next_write_state <= 2'b00;
			next_lcd_state <= return_lcd_state; // write lower nibble
		     end
		     else
		       wait_list[2] <= wait_list[2] - 1;
		  end
	       endcase // case (write_state)
	    end
	 endcase
      end // else: !if(!reset_n)
   end // always @ (posedge clk or negedge reset_n)
   
endmodule // lcd_driver
