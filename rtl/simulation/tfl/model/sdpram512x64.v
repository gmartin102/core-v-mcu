module MBH_ZSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128

//  module   sdpram512x64 
    (
     input wire          clkA,
     input wire          clkB,
     input wire          cenA,
     input           cenB,
     input wire [7+2-1:0] aA,
     input wire [7+2-1:0] aB,
     input wire [64-1:0]  d,
     input wire [64-1:0]  bw,
     input wire          deepsleep,
     input wire          powergate,
     
     output wire [64-1:0] q
     );
   
   wire              clk_a = clkA;
   wire              clk_b = clkB;
   wire              cen_a = cenB;
   wire              cen_b = cenA;
   
   wire [8:0]        addr_a = aB;
   wire [8:0]        addr_b = aA;
   wire [63:0]       wmsk_a = ~bw;
   wire              wen_a = cenB;
   reg [63:0]        rdata_b;
   wire [63:0]             wdata_a = d;
   
   
              
   assign q = rdata_b;
   
   


/* verilator lint_off UNOPT */
   reg [63:0] 	ram [0:511];
/* verilator lint_on UNOPT */
   reg [8:0] 	laddr_a;
   reg [8:0] 	laddr_b;
/* verilator lint_off UNOPT */
   reg 		lcen_a;
   reg 		lwen_a;
/* verilator lint_on UNOPT */
   reg [63:0]		lwdata_a;
/* verilator lint_off UNOPT */
   reg 		lcen_b;
//   reg 		lwen_b;
/* verilator lint_on UNOPT */
//   reg [17:0]		lwdata_b;
   reg [63:0]         lwmsk_a;
//   reg [17:0]         lwmsk_b;
   

   
   
   always@(posedge clk_a) begin
      laddr_a <= addr_a;
      lwdata_a <= wdata_a;
      lwmsk_a <= wmsk_a;
      lcen_a <= cen_a;
      lwen_a <= wen_a;
   end

   always@(posedge clk_b) begin
      laddr_b <= addr_b;
  //    lwdata_b <= wdata_b;
  //    lwmsk_b <= wmsk_b;
      lcen_b <= cen_b;
  //    lwen_b <= wen_b;
   end

   always@(*) begin
/*
      if ((lwen_b == 0) && (lcen_b == 0)) begin
	 ram[laddr_b][0] = lwmsk_b[0] ? ram[laddr_b][0] : lwdata_b[0];
	 ram[laddr_b][1] = lwmsk_b[1] ? ram[laddr_b][1] : lwdata_b[1];
	 ram[laddr_b][2] = lwmsk_b[2] ? ram[laddr_b][2] : lwdata_b[2];
	 ram[laddr_b][3] = lwmsk_b[3] ? ram[laddr_b][3] : lwdata_b[3];
	 ram[laddr_b][4] = lwmsk_b[4] ? ram[laddr_b][4] : lwdata_b[4];
	 ram[laddr_b][5] = lwmsk_b[5] ? ram[laddr_b][5] : lwdata_b[5];
	 ram[laddr_b][6] = lwmsk_b[6] ? ram[laddr_b][6] : lwdata_b[6];
	 ram[laddr_b][7] = lwmsk_b[7] ? ram[laddr_b][7] : lwdata_b[7];
	 ram[laddr_b][8] = lwmsk_b[8] ? ram[laddr_b][8] : lwdata_b[8];
	 ram[laddr_b][9] = lwmsk_b[9] ? ram[laddr_b][9] : lwdata_b[9];
	 ram[laddr_b][10] = lwmsk_b[10] ? ram[laddr_b][10] : lwdata_b[10];
	 ram[laddr_b][11] = lwmsk_b[11] ? ram[laddr_b][11] : lwdata_b[11];
	 ram[laddr_b][12] = lwmsk_b[12] ? ram[laddr_b][12] : lwdata_b[12];
	 ram[laddr_b][13] = lwmsk_b[13] ? ram[laddr_b][13] : lwdata_b[13];
	 ram[laddr_b][14] = lwmsk_b[14] ? ram[laddr_b][14] : lwdata_b[14];
	 ram[laddr_b][15] = lwmsk_b[15] ? ram[laddr_b][15] : lwdata_b[15];
	 ram[laddr_b][16] = lwmsk_b[16] ? ram[laddr_b][16] : lwdata_b[16];
	 ram[laddr_b][17] = lwmsk_b[17] ? ram[laddr_b][17] : lwdata_b[17];
	 lwen_b = 1;
      end // if ((lwen_b == 0) && (lcen_b == 0))
*/
      if (lcen_b == 0) begin
	 rdata_b = ram[laddr_b];
	 lcen_b = 1;
      end else
	rdata_b = rdata_b;
   end // always@ (*)

   always@(*) begin
      if ((lwen_a == 0) && (lcen_a == 0)) begin
	  ram[laddr_a][0] = lwmsk_a[0] ? ram[laddr_a][0] : lwdata_a[0];
	  ram[laddr_a][1] = lwmsk_a[1] ? ram[laddr_a][1] : lwdata_a[1];
	  ram[laddr_a][2] = lwmsk_a[2] ? ram[laddr_a][2] : lwdata_a[2];
	  ram[laddr_a][3] = lwmsk_a[3] ? ram[laddr_a][3] : lwdata_a[3];
	  ram[laddr_a][4] = lwmsk_a[4] ? ram[laddr_a][4] : lwdata_a[4];
	  ram[laddr_a][5] = lwmsk_a[5] ? ram[laddr_a][5] : lwdata_a[5];
	  ram[laddr_a][6] = lwmsk_a[6] ? ram[laddr_a][6] : lwdata_a[6];
	  ram[laddr_a][7] = lwmsk_a[7] ? ram[laddr_a][7] : lwdata_a[7];
	  ram[laddr_a][8] = lwmsk_a[8] ? ram[laddr_a][8] : lwdata_a[8];
	  ram[laddr_a][9] = lwmsk_a[9] ? ram[laddr_a][9] : lwdata_a[9];
	 ram[laddr_a][10] = lwmsk_a[10] ? ram[laddr_a][10] : lwdata_a[10];
	 ram[laddr_a][11] = lwmsk_a[11] ? ram[laddr_a][11] : lwdata_a[11];
	 ram[laddr_a][12] = lwmsk_a[12] ? ram[laddr_a][12] : lwdata_a[12];
	 ram[laddr_a][13] = lwmsk_a[13] ? ram[laddr_a][13] : lwdata_a[13];
	 ram[laddr_a][14] = lwmsk_a[14] ? ram[laddr_a][14] : lwdata_a[14];
	 ram[laddr_a][15] = lwmsk_a[15] ? ram[laddr_a][15] : lwdata_a[15];
	 ram[laddr_a][16] = lwmsk_a[16] ? ram[laddr_a][16] : lwdata_a[16];
	 ram[laddr_a][17] = lwmsk_a[17] ? ram[laddr_a][17] : lwdata_a[17];
         ram[laddr_a][18] = lwmsk_a[18] ? ram[laddr_a][18] : lwdata_a[18];
         ram[laddr_a][19] = lwmsk_a[19] ? ram[laddr_a][19] : lwdata_a[19];
	 ram[laddr_a][20] = lwmsk_a[20] ? ram[laddr_a][20] : lwdata_a[20];
	 ram[laddr_a][21] = lwmsk_a[21] ? ram[laddr_a][21] : lwdata_a[21];
	 ram[laddr_a][22] = lwmsk_a[22] ? ram[laddr_a][22] : lwdata_a[22];
	 ram[laddr_a][23] = lwmsk_a[23] ? ram[laddr_a][23] : lwdata_a[23];
	 ram[laddr_a][24] = lwmsk_a[24] ? ram[laddr_a][24] : lwdata_a[24];
	 ram[laddr_a][25] = lwmsk_a[25] ? ram[laddr_a][25] : lwdata_a[25];
	 ram[laddr_a][26] = lwmsk_a[26] ? ram[laddr_a][26] : lwdata_a[26];
	 ram[laddr_a][27] = lwmsk_a[27] ? ram[laddr_a][27] : lwdata_a[27];
         ram[laddr_a][28] = lwmsk_a[28] ? ram[laddr_a][28] : lwdata_a[28];
         ram[laddr_a][29] = lwmsk_a[29] ? ram[laddr_a][29] : lwdata_a[29];
	 ram[laddr_a][30] = lwmsk_a[30] ? ram[laddr_a][30] : lwdata_a[30];
	 ram[laddr_a][31] = lwmsk_a[31] ? ram[laddr_a][31] : lwdata_a[31];
	 ram[laddr_a][32] = lwmsk_a[32] ? ram[laddr_a][32] : lwdata_a[32];
	 ram[laddr_a][33] = lwmsk_a[33] ? ram[laddr_a][33] : lwdata_a[33];
	 ram[laddr_a][34] = lwmsk_a[34] ? ram[laddr_a][34] : lwdata_a[34];
	 ram[laddr_a][35] = lwmsk_a[35] ? ram[laddr_a][35] : lwdata_a[35];
	 ram[laddr_a][36] = lwmsk_a[36] ? ram[laddr_a][36] : lwdata_a[36];
	 ram[laddr_a][37] = lwmsk_a[37] ? ram[laddr_a][37] : lwdata_a[37];
         ram[laddr_a][38] = lwmsk_a[38] ? ram[laddr_a][38] : lwdata_a[38];
         ram[laddr_a][39] = lwmsk_a[39] ? ram[laddr_a][39] : lwdata_a[39];
	 ram[laddr_a][40] = lwmsk_a[40] ? ram[laddr_a][40] : lwdata_a[40];
	 ram[laddr_a][41] = lwmsk_a[41] ? ram[laddr_a][41] : lwdata_a[41];
	 ram[laddr_a][42] = lwmsk_a[42] ? ram[laddr_a][42] : lwdata_a[42];
	 ram[laddr_a][43] = lwmsk_a[43] ? ram[laddr_a][43] : lwdata_a[43];
	 ram[laddr_a][44] = lwmsk_a[44] ? ram[laddr_a][44] : lwdata_a[44];
	 ram[laddr_a][45] = lwmsk_a[45] ? ram[laddr_a][45] : lwdata_a[45];
	 ram[laddr_a][46] = lwmsk_a[46] ? ram[laddr_a][46] : lwdata_a[46];
	 ram[laddr_a][47] = lwmsk_a[47] ? ram[laddr_a][47] : lwdata_a[47];
         ram[laddr_a][48] = lwmsk_a[48] ? ram[laddr_a][48] : lwdata_a[48];
         ram[laddr_a][49] = lwmsk_a[49] ? ram[laddr_a][49] : lwdata_a[49];
	 ram[laddr_a][50] = lwmsk_a[50] ? ram[laddr_a][50] : lwdata_a[50];
	 ram[laddr_a][51] = lwmsk_a[51] ? ram[laddr_a][51] : lwdata_a[51];
	 ram[laddr_a][52] = lwmsk_a[52] ? ram[laddr_a][52] : lwdata_a[52];
	 ram[laddr_a][53] = lwmsk_a[53] ? ram[laddr_a][53] : lwdata_a[53];
	 ram[laddr_a][54] = lwmsk_a[54] ? ram[laddr_a][54] : lwdata_a[54];
	 ram[laddr_a][55] = lwmsk_a[55] ? ram[laddr_a][55] : lwdata_a[55];
	 ram[laddr_a][56] = lwmsk_a[56] ? ram[laddr_a][56] : lwdata_a[56];
	 ram[laddr_a][57] = lwmsk_a[57] ? ram[laddr_a][57] : lwdata_a[57];
         ram[laddr_a][58] = lwmsk_a[58] ? ram[laddr_a][58] : lwdata_a[58];
         ram[laddr_a][59] = lwmsk_a[59] ? ram[laddr_a][59] : lwdata_a[59];
	 ram[laddr_a][60] = lwmsk_a[60] ? ram[laddr_a][60] : lwdata_a[60];
	 ram[laddr_a][61] = lwmsk_a[61] ? ram[laddr_a][61] : lwdata_a[61];
	 ram[laddr_a][62] = lwmsk_a[62] ? ram[laddr_a][62] : lwdata_a[62];
	 ram[laddr_a][63] = lwmsk_a[63] ? ram[laddr_a][63] : lwdata_a[63];
         lwen_a = 1;
      end // if ((lwen_a == 0) && (lcen_a == 0))
   end // always *()
   

endmodule
