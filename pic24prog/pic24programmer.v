
module pic24programmer #(parameter DATAWIDTH=32, MEMSIZElog2=7) 
   ( input clk, input rstn,
     output 	   PGCx, 
     input 	   PGDx_in,
     output 	   PGDx_out,
     output 	   PGDx_dir,
     output 	   MCLRn,
     output        dvalid,
     output [15:0] dout
     );

   localparam MAX_ADDR = 20;
   
   reg [MEMSIZElog2-1:0] addr;
   reg 			 ce;
   reg 			 we;
   reg [DATAWIDTH-1:0] 	 data_in_reg;
   wire [DATAWIDTH-1:0]  instr;
   reg 			 valid;
   wire 		 ready;
   wire 		 dvalid;
   
   pic24progmem   imem(.clk(clk), .rstn(rstn), .addr(addr), .ce(ce), .we(we), .din(data_in_reg), .dout(instr));
   pic24flashprog prog(.clk(clk), .rstn(rstn), 
		       .PGCx(PGCx), 
		       .PGDx_in(PGDx_in),
		       .PGDx_out(PGDx_out),
		       .PGDx_dir(PGDx_dir),
		       .MCLRn(MCLRn),
		       .instr(instr[23:0]),
		       .cmd(instr[24]),
		       .valid(valid),
		       .ready(ready),
		       .dvalid(dvalid),
		       .dout(dout)    
		       );

   always @(posedge clk or negedge rstn) begin
      if(~rstn) begin
         addr <= { MEMSIZElog2 {1'b0}};
         ce <= 1'b0;
         we <= 1'b0;
      end
      else begin
	 ce <= 1'b1;
	 valid <= 1'b1;
	 if(ready == 1'b1 && addr < MAX_ADDR) begin
	    addr <= addr + 1;
	 end
      end
   end
   
   localparam DEVID = 24'hFF0000;

   initial begin
      imem.mem[0] ={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[1] ={7'h00,1'b0,24'h040200};  // GOTO 0x200
      imem.mem[2] ={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[3] ={7'h00,1'b0,12'h200,DEVID[23:16],4'h0};  // MOV <CW3Addr[23:16]>, W0
      imem.mem[4] ={7'h00,1'b0,24'h880190};  // MOV W0, TBLPAG
      imem.mem[5] ={7'h00,1'b0,4'h2,DEVID[15:0],4'h6};  // MOV <CW3Addr[15:0]>, W6
      imem.mem[6] ={7'h00,1'b0,24'h207846};  // MOV #VISI, W7
      imem.mem[7] ={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[8] ={7'h00,1'b0,24'hBA0BB6};  // TBLRDL [W6++], [W7]
      imem.mem[9] ={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[10]={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[11]={7'h00,1'b1,24'h000000};  // Clock out VISI reg
      imem.mem[12]={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[13]={7'h00,1'b0,24'hBA0BB6};  // TBLRDL [W6++], [W7]
      imem.mem[14]={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[15]={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[16]={7'h00,1'b1,24'h000000};  // Clock out VISI reg
      imem.mem[17]={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[18]={7'h00,1'b0,24'h040200};  // GOTO 0x200
      imem.mem[19]={7'h00,1'b0,24'h000000};  // NOP
   end
   
endmodule // pic24programmer

		       //    QA 75.5 O552
