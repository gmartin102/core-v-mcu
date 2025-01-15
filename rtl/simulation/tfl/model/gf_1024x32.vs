`timescale 1ns / 1ns
module TPRAM_WRAP (
  //OUTPUT
  TPRAM_MATHB_R_DATA, 
  TPRAM_EFPGA_R_DATA, 
  //INPUT
  EFPGA_TPRAM_R_MODE,
  EFPGA_TPRAM_W_MODE,
  EFPGA_TPRAM_WDSEL,
  EFPGA_TPRAM_WE,
  EFPGA_TPRAM_R_CLK,
  EFPGA_TPRAM_R_ADDR,
  EFPGA_TPRAM_W_CLK,
  EFPGA_TPRAM_W_ADDR,
  EFPGA_TPRAM_W_DATA,
  MATHB_TPRAM_W_DATA,
  EFPGA_TPRAM_POWERDN

);

localparam  DWORD_MODE = 2'b00; //32-bit 
localparam  WORD_MODE  = 2'b01; //16-bit 
localparam  BYTE_MODE  = 2'b10; //8-bit  
localparam  RESV_MODE  = 2'b11; //32-bit

//TPRAM CTRL
input  [1:0]  EFPGA_TPRAM_R_MODE;
input  [1:0]  EFPGA_TPRAM_W_MODE;
input         EFPGA_TPRAM_WDSEL;
input         EFPGA_TPRAM_WE;

//READ PORT
input         EFPGA_TPRAM_R_CLK;
input  [11:0] EFPGA_TPRAM_R_ADDR;

output [31:0] TPRAM_MATHB_R_DATA;
output [31:0] TPRAM_EFPGA_R_DATA;

//WRITE PORT
input         EFPGA_TPRAM_W_CLK;
input  [11:0] EFPGA_TPRAM_W_ADDR;
input  [31:0] EFPGA_TPRAM_W_DATA;
input  [31:0] MATHB_TPRAM_W_DATA;

//POWER CTRL
input         EFPGA_TPRAM_POWERDN;

/*------------------------------*/
/*          DEFINITION          */
/*------------------------------*/

reg  [63:0] tpram_bit_write;
reg  [31:0] efpga_r_data;
reg  [31:0] efpga_w_data;
reg  [11:0] fEFPGA_TPRAM_R_ADDR;

wire [63:0] tpram_w_data; 
wire [63:0] tpram_r_data;
wire        tpram_r_cen;
wire        tpram_w_cen;
wire [ 8:0] tpram_r_addr;
wire [ 8:0] tpram_w_addr;

/*------------------------------*/
/*          SRAM MACRO          */
/*------------------------------*/

assign tpram_r_cen  = 1'b0;
//assign tpram_w_cen  = EFPGA_TPRAM_WE;
assign tpram_w_cen  = ~EFPGA_TPRAM_WE;
assign tpram_r_addr = EFPGA_TPRAM_R_ADDR[11:3];
assign tpram_w_addr = EFPGA_TPRAM_W_ADDR[11:3];

MBH_ZSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128 U_TPRAM_512X64(
  .clkA (EFPGA_TPRAM_R_CLK),
  .clkB (EFPGA_TPRAM_W_CLK),
  .cenA (tpram_r_cen),
  .cenB (tpram_w_cen),
  .deepsleep (1'b0),                 //vincent
  .powergate (EFPGA_TPRAM_POWERDN),
  .aA (tpram_r_addr),
  .aB (tpram_w_addr),
  .d  (tpram_w_data),
  .bw (tpram_bit_write),
  .q  (tpram_r_data)
    );

/*------------------------------*/
/*       WRITE_DATA_MUX         */
/*------------------------------*/

assign tpram_w_data = EFPGA_TPRAM_WDSEL ? {MATHB_TPRAM_W_DATA,MATHB_TPRAM_W_DATA} : {efpga_w_data,efpga_w_data}; //MUX_WDSEL
//assign tpram_w_data[31:0]  = EFPGA_TPRAM_WDSEL ? MATHB_TPRAM_W_DATA : efpga_w_data; //MUX_WDSEL

always@(*) begin: WDATA_MODE_SEL
  if (EFPGA_TPRAM_WE) begin 
    if (EFPGA_TPRAM_W_MODE == BYTE_MODE) begin
      case (EFPGA_TPRAM_W_ADDR[2:0])    
        3'h0 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA; tpram_bit_write = 64'h0000_0000_0000_00ff; end
        3'h1 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[23:0],EFPGA_TPRAM_W_DATA[31:24]};tpram_bit_write = 64'h0000_0000_0000_ff00; end
        3'h2 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[15:0],EFPGA_TPRAM_W_DATA[31:16]};tpram_bit_write = 64'h0000_0000_00ff_0000; end
        3'h3 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[7:0],EFPGA_TPRAM_W_DATA[31:8]};tpram_bit_write = 64'h0000_0000_ff00_0000; end
        3'h4 : begin  efpga_w_data =  EFPGA_TPRAM_W_DATA; tpram_bit_write = 64'h0000_00ff_0000_0000; end
        3'h5 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[23:0],EFPGA_TPRAM_W_DATA[31:24]};tpram_bit_write = 64'h0000_ff00_0000_0000; end
        3'h6 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[15:0],EFPGA_TPRAM_W_DATA[31:16]};tpram_bit_write = 64'h00ff_0000_0000_0000; end
        3'h7 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[7:0],EFPGA_TPRAM_W_DATA[31:8]};tpram_bit_write = 64'hff00_0000_0000_0000; end
        default : efpga_w_data = 64'h0;
      endcase
    end // end of if (EFPGA_TPRAM_W_MODE == BYTE_MODE))
    else if (EFPGA_TPRAM_W_MODE == WORD_MODE) begin 
      case (EFPGA_TPRAM_W_ADDR[2:1])    
        2'h0 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'h0000_0000_0000_ffff; end
        2'h1 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[15:0],EFPGA_TPRAM_W_DATA[31:16]};tpram_bit_write = 64'h0000_0000_ffff_0000; end
        2'h2 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'h0000_ffff_0000_0000; end
        2'h3 : begin  efpga_w_data = {EFPGA_TPRAM_W_DATA[15:0],EFPGA_TPRAM_W_DATA[31:16]};tpram_bit_write = 64'hffff_0000_0000_0000; end
	    default : efpga_w_data = 64'h0; 
      endcase
    end // end of if (EFPGA_TPRAM_W_MODE == WORD_MODE))
    else if (EFPGA_TPRAM_W_MODE == DWORD_MODE || EFPGA_TPRAM_W_MODE == RESV_MODE ) begin
      case (EFPGA_TPRAM_W_ADDR[2])    
        2'h0 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'h0000_0000_ffff_ffff; end
        2'h1 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'hffff_ffff_0000_0000; end
	    default : efpga_w_data = 64'h0; 
      endcase
    end // end of if (EFPGA_TPRAM_W_MODE == DWORD_MODE))
    else begin // DEFAULT is RESV_W_MODE 
      case (EFPGA_TPRAM_W_ADDR[2])    
        2'h0 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'h0000_0000_ffff_ffff; end
        2'h1 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'hffff_ffff_0000_0000; end
	    default : efpga_w_data = 64'h0; 
       endcase
    end 
  end  
  else if (EFPGA_TPRAM_WE && EFPGA_TPRAM_WDSEL) begin  // overide mode -- data from math block is always 32-bits
      case (EFPGA_TPRAM_W_ADDR[2])    
        2'h0 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'h0000_0000_ffff_ffff; end
        2'h1 : begin  efpga_w_data = EFPGA_TPRAM_W_DATA;tpram_bit_write = 64'hffff_ffff_0000_0000; end
	    default : efpga_w_data = 64'h0; 
       endcase
  end  
  else begin
    efpga_w_data = 32'h0;
    //tpram_w_data[63:0] = 64'h0;
    tpram_bit_write = 64'h0;
  end //if (EFPGA_TPRAM_WE)
end


/*------------------------------*/
/*       READ_DATA_MUX          */
/*------------------------------*/
always@(posedge EFPGA_TPRAM_R_CLK)
  fEFPGA_TPRAM_R_ADDR <= #0.2 EFPGA_TPRAM_R_ADDR;
 
always@(*) begin: RDATA_MODE_SEL
  if (EFPGA_TPRAM_R_MODE == BYTE_MODE ) begin
    case ( fEFPGA_TPRAM_R_ADDR[2:0] )
       3'b0_00: efpga_r_data[31:0] = tpram_r_data[31: 0];
       3'b0_01: efpga_r_data[31:0] = tpram_r_data[39: 8];
       3'b0_10: efpga_r_data[31:0] = tpram_r_data[47:16];
       3'b0_11: efpga_r_data[31:0] = tpram_r_data[55:24];
       3'b1_00: efpga_r_data[31:0] = tpram_r_data[63:32];
       3'b1_01: efpga_r_data[31:0] = {tpram_r_data[ 7:0],tpram_r_data[63:40]};
       3'b1_10: efpga_r_data[31:0] = {tpram_r_data[15:0],tpram_r_data[63:48]};
       3'b1_11: efpga_r_data[31:0] = {tpram_r_data[23:0],tpram_r_data[63:56]};
       default : efpga_r_data = tpram_r_data[31: 0];
    endcase
  end
  else if ( EFPGA_TPRAM_R_MODE == WORD_MODE ) begin
    case ( fEFPGA_TPRAM_R_ADDR[2:1] )
      2'b0_0: efpga_r_data[31: 0] = tpram_r_data[31: 0];
      2'b0_1: efpga_r_data[31: 0] = tpram_r_data[47:16];
      2'b1_0: efpga_r_data[31: 0] = tpram_r_data[63:32];
      2'b1_1: efpga_r_data[31: 0] = {tpram_r_data[15:0],tpram_r_data[63:48]};
      default : efpga_r_data = tpram_r_data[31: 0];
    endcase
  end  
  else if  ( EFPGA_TPRAM_R_MODE == DWORD_MODE ) begin
    case ( fEFPGA_TPRAM_R_ADDR[2] )
      1'b0: efpga_r_data[31: 0] = tpram_r_data[31: 0];
      1'b1: efpga_r_data[31: 0] = tpram_r_data[63:32]; 
      default : efpga_r_data = tpram_r_data[31: 0];
    endcase
  end
  else begin // EFPGA_TPRAM_R_MODE is RESV_MODE = 2'b11
    case ( fEFPGA_TPRAM_R_ADDR[2] )
      1'b0: efpga_r_data[31: 0] = tpram_r_data[31: 0];
      1'b1: efpga_r_data[31: 0] = tpram_r_data[63:32]; 
      default : efpga_r_data = tpram_r_data[31: 0];
    endcase
  end
end

assign TPRAM_MATHB_R_DATA = fEFPGA_TPRAM_R_ADDR[2] ? tpram_r_data[63:32] : tpram_r_data[31:0] ;
assign TPRAM_EFPGA_R_DATA = efpga_r_data;

endmodule

