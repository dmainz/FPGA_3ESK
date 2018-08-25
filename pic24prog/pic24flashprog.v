module pic24flashprog( input   clk, input rstn, 
		       output 	     PGCx, 
		       input 	     PGDx_in,
		       output 	     PGDx_out,
		       output 	     PGDx_dir,
		       output 	     MCLRn,
		       input [23:0]  instr,
		       input 	     cmd,
		       input 	     valid,
		       output 	     ready,
		       output        dvalid,
		       output [15:0] dout
		       );

/*
POR ICSP enter
    ____         __                                                     ____________________________
    MCLR  ______/  \___________________________________________________/
            ___________________________________________________________|____________________________
    VDD  __/                                                           |
            <P6>   v---P18----v__          __ ___              __v-P19-v-P7-v
    PGDx _____________________/  \________/  X...X____________/  \__________|_______________________
                          b31 b30 b29 b28 b27      b3  b2  b1  b0           |
                            _   _   _   _   _   _   _   _   _   _           |_   _   _   _   _   _
    PGCx __________________/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \__________/ \_/ \_/ \_/ \_/ \_/ \_
                           <-x->
                           P1B P1A
SIX Instruction

         0   0   0   0   0   0   0   0   0       _______________________________||_________________
 PGDx __________________________________________/lsb____________________________||______________msb\________
                                                                                ||
         1   2   3   4   5   6   7   8   9<--P4-->1   2   3   4   5   6   7   8 || 20  21  22  23  24<-P4A->
         _   _   _   _   _   _   _   _   _        _   _   _   _   _   _   _   _ ||  _   _   _   _   _       _
 PGCx __/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \______/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \||_/ \_/ \_/ \_/ \_/ \_____/

REGOUT Instruction

        __   0   0   0         cpu  || idle        _data_out_____________||__________________________
 PGDx _/1 \_________________________||____________/lsb___________________||_______________________msb\_______
                                    ||  				 ||
         1   2   3   4<--P4-->1   2 ||  7   8<-P5->0   1   2   3   4   5 || 9  10  11  12  13  14  15 <P4A>
         _   _   _   _        _   _ ||  _   _      _   _   _   _   _   _ || _   _   _   _   _   _   _      _
 PGCx __/ \_/ \_/ \_/ \______/ \_/ \||_/ \_/ \____/ \_/ \_/ \_/ \_/ \_/ \||/ \_/ \_/ \_/ \_/ \_/ \_/ \____/ \_

 P1A = min 40ns
 P1B = min 40ns
 P2  = min 15ns data setup to PGCx
 P3  = min 15ns data hold
 P4  = min 40ns
 P4A = min 40ns delay between data and next command
 P5  = min 20ns delay from idle to data out
 P6  = min 100ns delay from Vdd to MCLRn
 P7  = min 25ms
 P18 = min 40ns
 P19 = min 1ms
 
*/
   localparam ICSP_SIX    = 4'b0000;
   localparam ICSP_REGOUT = 4'b0001;

   localparam LOG2STATES = 4;
   localparam ICSP_SM_RESET_IDLE   = 'd0;
   localparam ICSP_SM_RESET_MCLR   = 'd1;
   localparam ICSP_SM_RESET_WAIT   = 'd2;
   localparam ICSP_SM_RESET_CODE   = 'd3;
   localparam ICSP_SM_RESET_DONE   = 'd4;
   localparam ICSP_SM_IDLE         = 'd5;
   localparam ICSP_SM_WR_CMD       = 'd6;
   localparam ICSP_SM_WR_INSTR     = 'd5;
   localparam ICSP_SM_RD_CMD       = 'd6;
   localparam ICSP_SM_RD_DOUT      = 'd7;
   localparam P4 = 2; // clocks
   localparam P5 = 1; // clocks
   localparam P6 = 6; // clocks
// TODO put this back before programming FPGA
   localparam P7 = 1000;  //200000; // clocks
   localparam P18 = 2; // clocks
// TODO put this back before programming FPGA
   localparam P19 = 1000; //8000; // clocks
   
   localparam ICSP_ENTER_CODE     = 32'h4D434851;
   localparam ENH_ICSP_ENTER_CODE = 32'h4D434850;
   
// wait times are being counted on the half clock.  need to change to full clock.
// add extra cycles for regout command and post wr/rd instr.
   
   reg 			      MCLRn_reg;
   reg 			      PGCx_reg;
   reg 			      PGDx_in_reg;
   reg 			      PGDx_out_reg;
   reg [15:0] 		      regout;
   reg 			      PGDx_dir_reg;  // 0 = out, 1 = in
   reg [31:0] 		      icsp_enter;
   reg [3:0] 		      command;
   reg [23:0] 		      instruction;
   reg [27:0] 		      counter;
   reg 			      out_of_reset;
   reg 			      dvalid_reg;
   reg 			      ready_reg;
   reg 			      cntr_rst;
   reg 			      toggle; 			      
   
   reg [LOG2STATES-1:0] SM_ICSP;
   reg [LOG2STATES-1:0] SM_ICSP_next;
   
   assign MCLRn    = MCLRn_reg;
   assign PGCx     = PGCx_reg;
   assign PGDx_dir = PGDx_dir_reg;
   assign PGDx_out = PGDx_dir ? 1'b0 : PGDx_out_reg;
   assign dvalid = dvalid_reg;
   assign dout = regout;
   assign ready = ready_reg;
   
   always @(posedge clk or negedge rstn) begin
      if(~rstn) begin
	 SM_ICSP <= ICSP_SM_RESET_IDLE;
      end
      else begin
	 SM_ICSP = SM_ICSP_next;
      end
   end
   
   always @(posedge clk or negedge rstn) begin
      if(~rstn | cntr_rst) begin
	 counter <= 28'h0000000;
      end
      else begin
	 counter <= counter + 1'b1;
      end
   end
   
   always @(negedge rstn) begin
      SM_ICSP_next <= ICSP_SM_RESET_IDLE;
      command <= ICSP_SIX;
      instruction <= 24'h000000;
      MCLRn_reg <= 1'b0;
      PGDx_out_reg <= 1'b0;
      PGDx_dir_reg <= 1'b0;
      icsp_enter <= ICSP_ENTER_CODE;
      ready_reg <= 1'b0;
      out_of_reset <= 1'b1;
      dvalid_reg <= 1'b0;
      regout <= 16'h0000;
      cntr_rst <= 1'b0;
      toggle <= 1'b0;
   end

   always @(posedge clk or negedge rstn) begin
      if(~rstn | ~toggle)
	PGCx_reg <= 1'b0;
      else
	PGCx_reg <= ~PGCx_reg;
   end
   
   always @(SM_ICSP or counter or valid) begin
      case (SM_ICSP)
	ICSP_SM_RESET_IDLE: begin
	   if(counter == P6-1) begin
	      MCLRn_reg <= 1'b1;
	      cntr_rst <= 1'b1;
	      SM_ICSP_next <= ICSP_SM_RESET_MCLR;
	   end
	end
	ICSP_SM_RESET_MCLR: begin
	   cntr_rst <= 1'b0;
	   if(counter == 'h2-1) begin
	      MCLRn_reg <= 1'b0;
	      cntr_rst <= 1'b1;
	      SM_ICSP_next <= ICSP_SM_RESET_WAIT;
	   end
	end
	ICSP_SM_RESET_WAIT: begin
	   cntr_rst <= 1'b0;
	   if(counter == P18-1) begin
	      cntr_rst <= 1'b1;
	      SM_ICSP_next <= ICSP_SM_RESET_CODE;
	   end
	end
	ICSP_SM_RESET_CODE: begin
	   cntr_rst <= 1'b0;
	   PGDx_out_reg <= icsp_enter[31];
	   if(PGCx_reg == 1'b1) begin
	      icsp_enter <= {icsp_enter[30:0],1'b0};
	   end
	   if(counter < 64) toggle <= 1'b1;
	   if(counter == 'd65) begin
	      toggle <= 1'b0;
	      PGDx_out_reg <= 1'b0;
	      cntr_rst <= 1'b1;
	      SM_ICSP_next <= ICSP_SM_RESET_DONE;
	   end
	end
	ICSP_SM_RESET_DONE: begin
	   cntr_rst = 1'b0;
	   if(counter == P19) begin
	      MCLRn_reg = 1'b1;
	      cntr_rst = 1'b1;
	   end
	   else if(counter > P7) begin
	      toggle <= 1'b1;
	      if(counter == P7+2 +18) begin // 9 data low clocks
	      cntr_rst = 1'b1;
		 SM_ICSP_next = ICSP_SM_IDLE;
	      end
	   end
	end
	ICSP_SM_IDLE: begin
	   dvalid_reg = 1'b0;
	   PGDx_dir_reg = 1'b1;
	   ready_reg = 1'b1;
	   if(valid == 1'b1) begin
	      instruction = instr;
	      if(cmd == 1'b0) begin
		 command = ICSP_SIX;
		 if(out_of_reset)
		   SM_ICSP_next = ICSP_SM_WR_INSTR;
		 else
		   SM_ICSP_next = ICSP_SM_WR_CMD;
	      end
	      else if(cmd == 1'b1) begin
		 command = ICSP_REGOUT;
		 SM_ICSP_next = ICSP_SM_RD_CMD;
	      end
	   end
	   else
	     SM_ICSP_next = ICSP_SM_IDLE;
	   out_of_reset = 1'b0;
	   cntr_rst = 1'b1;
	end
	ICSP_SM_WR_CMD: begin
	   cntr_rst = 1'b0;
	   ready_reg = 1'b0;
	   toggle <= 1'b1;
	   if(PGCx_reg == 1'b1) begin
	      command = {command[2:0],1'b0};
	   end
	   PGDx_out_reg = command[3];
	   if(counter == 'd7) begin
	      toggle <= 1'b0;
	      PGDx_out_reg = 1'b0;
	      cntr_rst = 1'b1;
	      SM_ICSP_next = ICSP_SM_WR_INSTR;
	   end
	end
	ICSP_SM_WR_INSTR: begin
	   cntr_rst = 1'b0;
	   PGDx_dir_reg = 1'b1;
	   if(counter < 'd47) toggle <= 1'b1;
	   if(PGCx_reg == 1'b1) begin
	      instruction <= {instruction[22:0],1'b0};
	   end
	   if(counter < 'd47) PGDx_out_reg <= instruction[23];
	   if(counter == 'd47) begin
	      toggle <= 1'b0;
	      PGDx_out_reg = 1'b0;
	      cntr_rst = 1'b1;
	      SM_ICSP_next = ICSP_SM_IDLE;
	   end
	end
	ICSP_SM_RD_CMD: begin
	   cntr_rst = 1'b0;
	   ready_reg = 1'b0;
	   if(counter < 'd7) toggle <= 1'b1;
	   if(PGCx_reg == 1'b1) begin
	      command <= {command[2:0],1'b0};
	   end
	   if(counter < 'd7) PGDx_out_reg <= command[3];
	   if(counter == 'd7) begin
	      toggle <= 1'b0;
	      PGDx_out_reg = 1'b0;
	   end
	   if(counter > 'd7) begin
	      if(counter>'d9) toggle <= 1'b1;
	      if(counter=='d41) begin
		 toggle <= 1'b0;
		 PGDx_out_reg = 1'b0;
		 cntr_rst = 1'b1;
		 SM_ICSP_next = ICSP_SM_IDLE;
	      end
	   end
	end
	ICSP_SM_RD_DOUT: begin
	   cntr_rst = 1'b0;
	   PGDx_dir_reg = 1'b0;
	   if(counter < 31) toggle <= 1'b1;
	   if(PGCx_reg == 1'b1) begin
	      regout = {regout[14:0],PGDx_in};
	   end
	   if(counter == 'd31) begin
	      dvalid_reg = 1'b1;
	      toggle <= 1'b0;
	      cntr_rst = 1'b1;
	      SM_ICSP_next = ICSP_SM_IDLE;
	   end
        end
      endcase // case (SM_ICSP)
   end
   
endmodule // pic24flashprog
