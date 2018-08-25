module color_mem (
		  input        clk,
		  input        rst_n,
		  input        v_disp,
		  input        h_disp,
		  output [2:0] color,
		  input [9:0]  hcounter,
		  input [9:0]  vcounter
		  );

   parameter VRES = 600;
   parameter HRES = 800;
	parameter CHARVRES = VRES/10;
	parameter CHARHRES = HRES/10;
   
   parameter      OFFSET = 2;
   parameter      SPC = 8'h20;
   
   reg [0:7]     charmem [0:759];
   reg [0:7] 	  chars [0:CHARVRES-1][0:CHARHRES-1];
   reg [7:0] 	  data_q;
   reg [6:0] 	  charcntx;
   reg [5:0] 	  charcnty;
   reg [3:0] 	  dotcnt;
   wire [3:0] 	  pixel;
   reg [3:0] 	  linecnt;
   integer 	  i,j;
   
   always @(negedge rst_n) begin
     for(i=0;i<CHARVRES;i=i+1)
	    for(j=0;j<CHARHRES;j=j+1)
	      chars[i][j] = 0;
      
      chars[0][0] =  "H" - SPC;
      chars[0][1] =  "e" - SPC;
      chars[0][2] =  "l" - SPC;
      chars[0][3] =  "l" - SPC;
      chars[0][4] =  "o" - SPC;
      chars[0][5] =  "," - SPC;
      chars[0][6] =  " " - SPC;
      chars[0][7] =  "W" - SPC;
      chars[0][8] =  "i" - SPC;
      chars[0][9] =  "n" - SPC;
      chars[0][10] = "e" - SPC;
      chars[0][11] = "f" - SPC;
      chars[0][12] = "r" - SPC;
      chars[0][13] = "e" - SPC;
      chars[0][14] = "d" - SPC;
      chars[0][15] = "!" - SPC;
//      $display("chars[0][0] = %0x",chars[0][0]);
//`include "charmem.inc"
   end

   initial begin
      $readmemh("characters.mem",charmem,0,759);
 //     $display("charmem[8] = %0x",charmem[8]);
   end
   
   assign pixel = dotcnt - 4'b0001;
   assign color = 
		  (pixel == 0 && data_q[7]) == 1'b1 ? 3'b111 : 
		  (pixel == 1 && data_q[6]) == 1'b1 ? 3'b111 :
		  (pixel == 2 && data_q[5]) == 1'b1 ? 3'b111 :
		  (pixel == 3 && data_q[4]) == 1'b1 ? 3'b111 :
		  (pixel == 4 && data_q[3]) == 1'b1 ? 3'b111 :
		  (pixel == 5 && data_q[2]) == 1'b1 ? 3'b111 :
		  (pixel == 6 && data_q[1]) == 1'b1 ? 3'b111 :
		  (pixel == 7 && data_q[0]) == 1'b1 ? 3'b111 :
		  3'b000;
   
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
	 dotcnt <= 4'b0000;
      end
      else begin
	 if(dotcnt < 9 && vcounter > 0 && hcounter > 0)
	   dotcnt <= dotcnt + 4'b0001;
	 else
	   dotcnt <= 4'b0000;
      end
   end

   always @(negedge v_disp or posedge h_disp or negedge rst_n) begin
      if(~rst_n) begin
	 linecnt <= 4'b1001;
	 charcnty <= 6'b111111;
      end
      else if(~v_disp) begin
	 linecnt <= 4'b1001;
	 charcnty <= 6'b111111;
      end      
		else if(linecnt < 9)
	linecnt <= linecnt + 4'b0001;
      else if(linecnt == 9) begin
	 charcnty <= charcnty + 6'b000001;
	 linecnt <= 4'b0000;
      end
   end
//   always @(vcounter) begin
//      if(vcounter > 1 && vcounter < VRES+1) begin
//	 if(linecnt < 9) begin
//	    linecnt <= linecnt + 4'b0001;
//	 end
//	 else if(linecnt == 9) begin
//	    charcnty <= charcnty + 6'b000001;
//	    linecnt <= 4'b0000;
//	 end
//      end
//      else begin
//	 linecnt <= 4'b0000;
//         charcnty <= 3'b000;
//      end
//   end
   
   always @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
	 data_q <=  3'b000;
	 charcntx <= 7'b0000000;
      end
      else begin
	 if(vcounter > 0 && vcounter < VRES+1 && hcounter > 0 && hcounter < HRES+1 &&
	    linecnt > 0 && linecnt < 9) begin
	    data_q <= charmem[chars[charcnty][charcntx]*8+linecnt-1];
	    if(dotcnt == 9)  charcntx <= charcntx + 7'b0000001;
         end
	 else begin
	    data_q <= 8'h00;
	    charcntx <= 7'b0000000;
         end
      end
   end

endmodule // color_mem
