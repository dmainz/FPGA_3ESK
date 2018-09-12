
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
   
   reg [MEMSIZElog2-1:0] addr,daddr;
   reg 			 ce;
   wire 		 dce;
   reg 			 we,dwe;
   reg [DATAWIDTH-1:0] 	 data_in_reg,ddata_in_reg;
   wire [DATAWIDTH-1:0]  instr,data;
   wire 		 valid;
   wire 		 ready;
   reg                   ready_reg; 			 
   wire 		 dvalid;
   wire [15:0] 		 muxinstr;
   wire [23:0] 		 instr_in;
   reg 			 dmemvalid;
   
   pic24progmem   imem(.clk(clk), .rstn(rstn), .addr(addr), .ce(ce), .we(we), .din(data_in_reg), .dout(instr));
   pic24progmem   dmem(.clk(clk), .rstn(rstn), .addr(daddr), .ce(dce), .we(dwe), .din(ddata_in_reg), .dout(data));
   pic24flashprog pic24prog(.clk(clk), .rstn(rstn), 
		       .PGCx(PGCx), 
		       .PGDx_in(PGDx_in),
		       .PGDx_out(PGDx_out),
		       .PGDx_dir(PGDx_dir),
		       .MCLRn(MCLRn),
		       .instr(instr_in),
		       .cmd(instr[24]),
		       .valid(valid),
		       .ready(ready),
		       .dvalid(dvalid),
		       .dout(dout)    
		       );

   assign instr_in = {instr[23:20],muxinstr,instr[3:0]};
   assign dce = instr[25];
   
   always @(posedge clk or negedge rstn) begin
      if(~rstn) begin
         addr <= { MEMSIZElog2 {1'b0}};
         daddr <= { MEMSIZElog2 {1'b0}};
         ce <= 1'b1;
         we <= 1'b0;
         dwe <= 1'b0;
	 ready_reg <= 1'b0;
      end
      else begin
	 ce <= 1'b0;
	 ready_reg <= ready;
	 if(ready_reg == 1'b1 && addr < MAX_ADDR) begin
	    addr <= addr + 1;
	    ce <= 1'b1;
	 end
      end
   end

   assign valid = (addr < MAX_ADDR && ce&~ready) ? 1'b1 : 1'b0;
   assign muxinstr = instr[27] ? data[31:16] : 
	       instr[26] ? data[15:0] : instr[19:4];

   always @(posedge clk or negedge rstn) begin
      if(~rstn) begin
	 dmemvalid <= 1'b0;
      end
      else if(dce) begin
	 dmemvalid <= 1'b1;
      end
      else if(dmemvalid) begin
	 daddr <= daddr + 1;
	 dmemvalid <= 1'b0;
      end
   end

   localparam DEVID = 24'hFF0000;

// imem[27] = use upper part of data mem
// imem[26] = use lower part of data mem
// imem[25] = read next data mem location. Upper part to by used by next imem instr
// imem[24] = cmd to pic24prog, 0 = write, 1 = read  
// imem[23:0] = instr to pic24prog
   
   initial begin
      imem.mem[0] ={7'h00,1'b0,24'h000000};  // NOP
      imem.mem[1] ={7'h00,1'b0,24'h040200};  // GOTO 0x200
      imem.mem[2] ={7'h01,1'b0,24'h000000};  // NOP
      imem.mem[3] ={7'h04,1'b0,12'h200,8'h00,4'h0};  // MOV <CW3Addr[23:16]>, W0
      imem.mem[4] ={7'h00,1'b0,24'h880190};  // MOV W0, TBLPAG
      imem.mem[5] ={7'h02,1'b0,4'h2,16'h0000,4'h6};  // MOV <CW3Addr[15:0]>, W6
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
      imem.mem[20]={7'h00,1'b0,24'h000000};  // NOP
      dmem.mem[0] ={8'h00,24'hFF0000};
   end
   
endmodule // pic24programmer

		       //    QA 75.5 O552
