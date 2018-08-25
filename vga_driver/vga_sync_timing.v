module vga_sync_timing ( output vsync, output hsync, output vdisp, output hdisp, input clk, input rst_n);

   parameter TOFFSET = 0;
   parameter TVSTOHS = TOFFSET + 0;

`define res800x600
   
`ifdef res640x480
   parameter TSVS    = 416800;
   parameter TDISPVS = 384000;
   parameter TPWVS   = 1600;
   parameter TFPVS   = 8000;
   parameter TBPVS   = 23200;
   parameter TSHS    = 800;
   parameter TDISPHS = 640;
   parameter TPWHS   = 96;
   parameter TFPHS   = 16;
   parameter TBPHS   = 48;
`elsif res800x600
   parameter TSVS    = 663168;
   parameter TDISPVS = 633600;
   parameter TPWVS   = 4224;
   parameter TFPVS   = 1056;
   parameter TBPVS   = 24288;
   parameter TSHS    = 1056;
   parameter TDISPHS = 800;
   parameter TPWHS   = 128;
   parameter TFPHS   = 40;
   parameter TBPHS   = 88;
`endif
   
   reg [19:0] vcounter;
   reg [10:0] hcounter;
   reg [9:0]  offsetcounter;
   reg hsync_q;
   reg vsync_q;
   reg vdisp_q;
   reg hdisp_q;
   
   assign hsync = ~hsync_q;
   assign vsync = ~vsync_q;
   assign vdisp  = vdisp_q;
   assign hdisp  = hdisp_q;
   
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n)
	     offsetcounter <= 10'h000;
      else if(offsetcounter < TVSTOHS)
	     offsetcounter <= offsetcounter + 1'b1;
   end
   
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n ) begin
	     vcounter <= 20'hFFFFF;
      end
      else
	    if(vcounter == TSVS-2 || offsetcounter < TOFFSET)
	       vcounter <= 20'hFFFFF;
		 else
	       vcounter <= vcounter + 1'b1;
   end

   always @(posedge clk or negedge rst_n) begin
      if(~rst_n ) begin
	     hcounter <= 11'h7FF;
      end
		else if(hcounter == TSHS-2 || offsetcounter < TVSTOHS)
	     hcounter <= 11'h7FF;
      else
	     hcounter <= hcounter + 1'b1;
   end
   
   always @(posedge clk or negedge rst_n) begin
     if(~rst_n ) begin
	     vsync_q <= 1'b1;
	     vdisp_q <= 1'b0;
     end
	  else if(vcounter == TSVS-2 || offsetcounter < TOFFSET) begin
	     vsync_q <= 1'b1;
	     vdisp_q <= 1'b0;		
	  end
	  else
       case (vcounter)
	      19'h00000: begin
	         vsync_q <= 1'b0;
	         vdisp_q <= 1'b0;
	      end
	      TPWVS: begin
	         vsync_q <= 1'b1;
	      end
	      TPWVS + TBPVS: begin
	         vdisp_q <= 1'b1;
	      end
	      TPWVS + TBPVS + TDISPVS: begin
	         vdisp_q <= 1'b0;
	      end
       endcase // case (counter)
   end

   always @(posedge clk or negedge rst_n) begin
      if(~rst_n ) begin
	     hsync_q <= 1'b1;
	     hdisp_q <= 1'b0;
      end
		else if(hcounter == TSHS-2 || offsetcounter < TVSTOHS) begin
	     hsync_q <= 1'b1;
	     hdisp_q <= 1'b0;		
		  end
		else
        case (hcounter)
	       11'h000: begin
	          hsync_q <= 1'b0;
	          hdisp_q  <= 1'b0;
	       end
	       TPWHS: begin // 296
	          hsync_q <= 1'b1;
	       end
	       TPWHS + TBPHS: begin // 296+48 = 344
	          hdisp_q <= 1'b1;
	       end
	       TPWHS + TBPHS + TDISPHS: begin // 344 + 640 = 984
	          hdisp_q <= 1'b0;
	       end
      endcase // case (counter)
   end

endmodule // vga_sync_timing
