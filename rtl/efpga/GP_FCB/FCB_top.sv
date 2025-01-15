`timescale 1ns / 10ps
module FCB_top #(
    parameter ROWS     = 10'h1,
    parameter COLUMNS  = 10'h1,
    parameter R_OFFSET = 10'd2,
    parameter C_OFFSET = 10'd4,
    parameter R_STRIDE = 10'd6,
    parameter C_STRIDE = 10'd7
    //parameter  ROWS     = 10'h2,
    //parameter  COLUMNS  = 10'h2,
    //parameter  R_OFFSET = 10'd1,
    //parameter  C_OFFSET = 10'd4,
    //parameter  R_STRIDE = 10'd6,
    //parameter  C_STRIDE = 10'd4
) (
    output wire        PSLVERR_o,
    output wire        PREADY_o,
    output wire [31:0] PRDATA_o,
    input  wire        PCLK_i,
    input  wire        PSEL_i,
    input  wire        PENABLE_i,
    input  wire        PWRITE_i,
    input  wire [31:0] PWDATA_i,
    input  wire        PRESET_ni,
    input  wire [15:0] PADDR_i,

    output wire        PL_ENA_o,
    output wire        PL_REN_o,
    output wire [ 1:0] PL_WEN_o,
    output wire        PL_INIT_o,
    output wire        PL_CLK_o,
    output wire [35:0] PL_DATA_o,
    output wire [31:0] PL_ADDR_o,
    input  wire [35:0] PL_DATA_i,

    output wire        CFG_CLK_o,
    output wire [31:0] CCFF_HEAD_o,
    input  wire [31:0] CCFF_TAIL_i,
    output wire        CFG_DONE_o,
    output wire        CFG_RST_no,
    input  wire        SET_CFG_DONE_i

);

  wire [31:0] pcb_prdata, ccff_prdata;
  wire pcb_pready, ccff_pready;
  wire pcb_psel, ccff_psel;
  wire pcb_pslverr, ccff_pslverr;

  assign PREADY_o = ccff_pready | pcb_pready;
  assign PSLVERR_o = ccff_pslverr | pcb_pslverr;
  assign PRDATA_o = ccff_prdata | pcb_prdata;

  assign ccff_psel = (PSEL_i == 1'b1) && (PADDR_i[15:6] == 10'h000);  // 0x0 - 0x3F
  assign pcb_psel  = (PSEL_i == 1'b1) && 
                   ( (PADDR_i[15:6] == 10'b0000_0000_01) ||
                     (PADDR_i[14] == 1'b1) ); // 0x40=0x7f, 0x4000 - 0x7fff

  FCB_ccff #() U_ccff (
      .prdata_o(ccff_prdata),
      .pwdata_i(PWDATA_i),
      .pwrite_i(PWRITE_i),
      .penable_i(PENABLE_i),
      .paddr_i(PADDR_i[15:0]),
      .psel_i(ccff_psel),
      .preset_ni(PRESET_ni),
      .pready_o(ccff_pready),
      .pslverr_o(ccff_pslverr),
      .pclk_i(PCLK_i),
      .set_cfg_done_i(SET_CFG_DONE_i),
      .CCFF_HEAD_o(CCFF_HEAD_o),
      .CCFF_TAIL_i(CCFF_TAIL_i),
      .CFG_DONE_o(CFG_DONE_o),
      .CFG_RSTN_o(CFG_RST_no),
      .CFG_CLK_o(CFG_CLK_o)
  );


  FCB_pcb #(
      .PL_DATA_WIDTH(36),
      .PL_ADDR_WIDTH(32),
      .RAM_SIZE(16'd1024),
      .ROWS(ROWS),
      .COLUMNS(COLUMNS),
      .R_OFFSET(R_OFFSET),
      .C_OFFSET(C_OFFSET),
      .R_STRIDE(R_STRIDE),
      .C_STRIDE(C_STRIDE)
  ) U_FCB_pcb (
      .prdata_o(pcb_prdata),
      .pwdata_i(PWDATA_i),
      .pwrite_i(PWRITE_i),
      .penable_i(PENABLE_i),
      .paddr_i(PADDR_i[15:0]),
      .psel_i(pcb_psel),
      .preset_ni(PRESET_ni),
      .pready_o(pcb_pready),
      .pslverr_o(pcb_pslverr),
      .pclk_i(PCLK_i),
      .PL_DATA_IN(PL_DATA_i),
      .PL_DATA_OUT(PL_DATA_o),
      .PL_ADDR_OUT(PL_ADDR_o),
      .PL_WEN(PL_WEN_o),
      .PL_REN(PL_REN_o),
      .PL_ENA(PL_ENA_o),
      .PL_INIT(PL_INIT_o),
      .PL_CLK(PL_CLK_o)
  );


endmodule
