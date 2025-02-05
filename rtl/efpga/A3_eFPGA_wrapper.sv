// Copyright 2021 QuickLogic
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
`include "pulp_soc_defines.svh"
module eFPGA_wrapper (
    input  [31:0] CCFF_HEAD_i,
    input         CFG_CLK_i,
    input         CFG_DONE_i,
    input         CFG_RST_ni,
    input  [ 3:0] CLK_i,
    input  [31:0] PL_ADDR_i,
    input         PL_CLK_i,
    input  [35:0] PL_DATA_i,
    output [35:0] PL_DATA_o,
    input         PL_ENA_i,
    input         PL_INIT_i,
    input         PL_REN_i,
    input  [ 1:0] PL_WEN_i,
    input         RST_ni,
    output [31:0] CCFF_TAIL_o,


    output logic [`N_FPGAIO-1:0] fpgaio_oe,
    output logic [`N_FPGAIO-1:0] fpgaio_out,

    input logic [`N_FPGAIO-1:0] fpgaio_in,

    input logic [19:0] lint_ADDR,

    input logic    lint_WEN,
    lint_REQ,
    input logic [ 3:0]    lint_BE,
    input logic [31:0]    lint_WDATA,
    input logic [31:0]    control_in,
    output logic    apb_fpga_clk_o,
    //				RESET_LT,
    //				RESET_RB,
    //				RESET_RT,

    input logic [31:0]    tcdm_rdata_p3,
    tcdm_rdata_p2,
    input logic [31:0]    tcdm_rdata_p1,
    tcdm_rdata_p0,
    output logic    tcdm_clk_p0,
    tcdm_clk_p1,
    tcdm_clk_p2,
    tcdm_clk_p3,

    input logic tcdm_gnt_p3,
    tcdm_gnt_p2,
    tcdm_gnt_p1,
    tcdm_gnt_p0,
    input logic tcdm_fmo_p3,
    tcdm_fmo_p2,
    tcdm_fmo_p1,
    tcdm_fmo_p0,
    input logic tcdm_valid_p3,
    tcdm_valid_p2,
    input logic tcdm_valid_p1,
    tcdm_valid_p0,

    output logic [31:0] status_out,
    output logic [ 7:0] version,
    output logic [15:0] events_o,

    output logic [31:0]   lint_RDATA,
    output logic    lint_GNT,
    lint_VALID,

    output logic [31:0] tcdm_wdata_p3,
    tcdm_wdata_p2,
    output logic [31:0] tcdm_wdata_p1,
    tcdm_wdata_p0,
    output logic [19:0] tcdm_addr_p3,
    tcdm_addr_p2,
    output logic [19:0] tcdm_addr_p1,
    tcdm_addr_p0,

    output logic       tcdm_req_p3,
    tcdm_req_p2,
    tcdm_req_p1,
    tcdm_req_p0,
    output logic       tcdm_wen_p3,
    tcdm_wen_p2,
    tcdm_wen_p1,
    tcdm_wen_p0,
    output logic [3:0] tcdm_be_p3,
    tcdm_be_p2,
    tcdm_be_p1,
    tcdm_be_p0
//    inout              VSSC,
//    VDDC_FPGA,
//    NB,
//    PB


);
   supply1             VDDC_FPGA;
   supply0             VSSC;
   
  wire        psel_s;
  wire        penable_s;
  wire        pwrite_s;
  wire        pready_s;
  wire [31:0] pwdata_s;
  wire [31:0] prdata_s;
  wire [ 8:0] paddr_s;

  wire [11:0] oper1_waddr, coef1_waddr, oper1_raddr, coef1_raddr;
  wire [11:0] oper2_waddr, coef2_waddr, oper2_raddr, coef2_raddr;
  wire [31:0] oper1_wdata, coef1_wdata, oper1_rdata, coef1_rdata;
  wire [31:0] oper2_wdata, coef2_wdata, oper2_rdata, coef2_rdata;
  wire oper1_we, coef1_we, oper2_we, coef2_we;
  wire oper1_rclk, oper1_wclk, coef1_rclk, coef1_wclk;
  wire oper2_rclk, oper2_wclk, coef2_rclk, coef2_wclk;
  wire [1:0] oper1_wmode, oper1_rmode, coef1_wmode, coef1_rmode;
  wire [1:0] oper2_wmode, oper2_rmode, coef2_wmode, coef2_rmode;
  wire oper1_wdsel, coef1_wdsel;
  wire oper2_wdsel, coef2_wdsel;
  wire [41:0] gpio_o, gpio_oe, gpio_i;


  wire [31:0] mult1_oper, mult1_coef, mult1_in, mult2_in;
  wire [31:0] mult2_oper, mult2_coef;
  wire [5:0] m2_outsel, m1_outsel;
  wire m2_tc, m1_tc;
  wire [1:0] m1_oper_sel, m1_coef_sel, m2_oper_sel, m2_coef_sel;
  wire m2_clk, m1_clk, m2_clken, m1_clken;
  wire m2_osel, m2_csel, m1_osel, m1_csel;
  wire clk_out, clk_out_oe;
  wire [1:0] m2_math_mode, m1_math_mode;
  wire m2_sat, m2_clr, m2_rnd, m1_sat, m1_clr, m1_rnd;
  wire [31:0] m2_ram_coef, m2_ram_oper, m2_ram_wdata;
  wire [31:0] m1_ram_coef, m1_ram_oper, m1_ram_wdata;

  assign tcdm_clk_p0 = CLK_i[0];
  assign tcdm_clk_p1 = CLK_i[0];
  assign tcdm_clk_p2 = CLK_i[0];
  assign tcdm_clk_p3 = CLK_i[0];

  tfl top (
      .PCLK(CLK_i[0]),
      .rstn(RST_ni),
      .PSEL(psel_s),
      .PWRITE(pwrite_s),
      .PENABLE(penable_s),
      .PADDR(paddr_s[8:2]),
      .PWDATA(pwdata_s),
      .PREADY(pready_s),
      .PRDATA(prdata_s),

      .gpio_o(),
      .gpio_oe(),
      .gpio_i('h0),
      .oper1_rmode(oper1_rmode),
      .oper1_wmode(oper1_wmode),
      .oper1_wdsel(oper1_wdsel),
      .oper1_we(oper1_we),
      .oper1_rclk(oper1_rclk),
      .oper1_wclk(oper1_wclk),
      .oper1_waddr(oper1_waddr),
      .oper1_raddr(oper1_raddr),
      .oper1_wdata(oper1_wdata),
      .oper1_rdata(oper1_rdata),
      .coef1_rdata(coef1_rdata),
      .coef1_rmode(coef1_rmode),
      .coef1_wmode(coef1_wmode),
      .coef1_wdsel(coef1_wdsel),
      .coef1_we(coef1_we),
      .coef1_rclk(coef1_rclk),
      .coef1_wclk(coef1_wclk),
      .coef1_raddr(coef1_raddr),
      .coef1_waddr(coef1_waddr),
      .coef1_wdata(coef1_wdata),
      .oper2_rmode(oper2_rmode),
      .oper2_wmode(oper2_wmode),
      .oper2_wdsel(oper2_wdsel),
      .oper2_we(oper2_we),
      .oper2_rclk(oper2_rclk),
      .oper2_wclk(oper2_wclk),
      .oper2_waddr(oper2_waddr),
      .oper2_raddr(oper2_raddr),
      .oper2_wdata(oper2_wdata),
      .oper2_rdata(oper2_rdata),
      .coef2_rdata(coef2_rdata),
      .coef2_rmode(coef2_rmode),
      .coef2_wmode(coef2_wmode),
      .coef2_wdsel(coef2_wdsel),
      .coef2_we(coef2_we),
      .coef2_rclk(coef2_rclk),
      .coef2_wclk(coef2_wclk),
      .coef2_raddr(coef2_raddr),
      .coef2_waddr(coef2_waddr),
      .coef2_wdata(coef2_wdata),
      .mult1_in(mult1_in),
      .mult2_in(mult2_in),
      .mult1_oper(mult1_oper),
      .mult1_coef(mult1_coef),
      .mult2_oper(mult2_oper),
      .mult2_coef(mult2_coef),
      .m2_outsel(m2_outsel),
      .m1_outsel(m1_outsel),
      .m2_tc(m2_tc),
      .m1_tc(m1_tc),
      .m2_oper_sel(m2_oper_sel),
      .m2_coef_sel(m2_coef_sel),
      .m1_oper_sel(m1_oper_sel),
      .m1_coef_sel(m1_coef_sel),
      .m2_clk(m2_clk),
      .m1_clk(m1_clk),
      .m2_clken(m2_clken),
      .m1_clken(m1_clken),
      .m2_osel(m2_osel),
      .m2_csel(m2_csel),
      .m1_osel(m1_osel),
      .m1_csel(m1_csel),
      .m2_math_mode(m2_math_mode),
      .m1_math_mode(m1_math_mode),
      .m2_sat(m2_sat),
      .m2_clr(m2_clr),
      .m2_rnd(m2_rnd),
      .m1_sat(m1_sat),
      .m1_clr(m1_clr),
      .m1_rnd(m1_rnd),
      .tcdm_rdata_p0(32'h0),  //tcdm_rdata_p0),
      .tcdm_wdata_p0(),  //tcdm_wdata_p0),
      .tcdm_addr_p0(),  //tcdm_addr_p0),
      .tcdm_be_p0(),  //tcdm_be_p0),
      .tcdm_req_p0(),  //tcdm_req_p0),
      .tcdm_gnt_p0(1'b0),  //tcdm_gnt_p0),
      .tcdm_valid_p0(1'b0),  //tcdm_valid_p0),
      .tcdm_wen_p0(),  //tcdm_wen_p0),
      .tcdm_rdata_p1(tcdm_rdata_p1),
      .tcdm_wdata_p1(tcdm_wdata_p1),
      .tcdm_addr_p1(tcdm_addr_p1),
      .tcdm_be_p1(tcdm_be_p1),
      .tcdm_req_p1(tcdm_req_p1),
      .tcdm_gnt_p1(tcdm_gnt_p1),
      .tcdm_valid_p1(tcdm_valid_p1),
      .tcdm_wen_p1(tcdm_wen_p1),
      .tcdm_rdata_p2(tcdm_rdata_p2),
      .tcdm_wdata_p2(tcdm_wdata_p2),
      .tcdm_addr_p2(tcdm_addr_p2),
      .tcdm_be_p2(tcdm_be_p2),
      .tcdm_req_p2(tcdm_req_p2),
      .tcdm_gnt_p2(tcdm_gnt_p2),
      .tcdm_valid_p2(tcdm_valid_p2),
      .tcdm_wen_p2(tcdm_wen_p2),
      .tcdm_rdata_p3(tcdm_rdata_p3),
      .tcdm_wdata_p3(tcdm_wdata_p3),
      .tcdm_addr_p3(tcdm_addr_p3),
      .tcdm_be_p3(tcdm_be_p3),
      .tcdm_req_p3(tcdm_req_p3),
      .tcdm_gnt_p3(tcdm_gnt_p3),
      .tcdm_valid_p3(tcdm_valid_p3),
      .tcdm_wen_p3(tcdm_wen_p3)
  );
  sdpram1024x32 oram1 (
      .clk_a  (oper1_wclk),
      .cen_a  (~oper1_we),
      .wen_a  (~oper1_we),
      .addr_a (oper1_waddr[11:2]),
      .wdata_a(oper1_wdata),

      .clk_b  (oper1_rclk),
      .cen_b  (1'b0),
      .addr_b (oper1_raddr[11:2]),
      .rdata_b(oper1_rdata)
  );
  sdpram1024x32 cram1 (
      .clk_a  (coef1_wclk),
      .cen_a  (~coef1_we),
      .wen_a  (~coef1_we),
      .addr_a (coef1_waddr[11:2]),
      .wdata_a(coef1_wdata),

      .clk_b  (coef1_rclk),
      .cen_b  (1'b0),
      .addr_b (coef1_raddr[11:2]),
      .rdata_b(coef1_rdata)
  );
  sdpram1024x32 oram2 (
      .clk_a  (oper2_wclk),
      .cen_a  (~oper2_we),
      .wen_a  (~oper2_we),
      .addr_a (oper2_waddr[11:2]),
      .wdata_a(oper2_wdata),

      .clk_b  (oper2_rclk),
      .cen_b  (1'b0),
      .addr_b (oper2_raddr[11:2]),
      .rdata_b(oper2_rdata)
  );
  sdpram1024x32 cram2 (
      .clk_a  (coef2_wclk),
      .cen_a  (~coef2_we),
      .wen_a  (~coef2_we),
      .addr_a (coef2_waddr[11:2]),
      .wdata_a(coef2_wdata),

      .clk_b  (coef2_rclk),
      .cen_b  (1'b0),
      .addr_b (coef2_raddr[11:2]),
      .rdata_b(coef2_rdata)
  );



  wire [42:0] fpga_out, fpga_in, fpga_oe;

  assign fpga_in =  fpgaio_in;
  assign fpgaio_oe = fpga_oe[`N_FPGAIO-1:0];
  assign fpgaio_out = fpga_out[`N_FPGAIO-1:0];
  assign CCFF_TAIL_o[31:10] = 22'h0;

  A3_design Arnold3_Design (  // use this to go to A2F/F2A
      //top Arnold3_Design (  // use this to connect rtl directly
      .CCFF_TAIL_o    (CCFF_TAIL_o[9:0]),
      .CCFF_HEAD_i    (CCFF_HEAD_i[9:0]),
      .CFG_CLK_i      (CFG_CLK_i),         // Templated
      .CFG_DONE_i     (CFG_DONE_i),        // Templated
      .CFG_RST_ni     (CFG_RST_ni),        // Templated
      .CLK_i          (CLK_i),
      .PL_ADDR_i      (PL_ADDR_i),
      .PL_CLK_i       (PL_CLK_i),          // Templated
      .PL_DATA_i      (PL_DATA_i),         // Templated
      .PL_ENA_i       (PL_ENA_i),          // Templated
      .PL_INIT_i      (PL_INIT_i),         // Templated
      .PL_REN_i       (PL_REN_i),          // Templated
      .PL_WEN_i       (PL_WEN_i),          // Templated
      .RST_ni         (RST_ni),
      .SCAN_EN_i      (1'b0),
      .SCAN_MODE_i    (1'b0),
      .SCAN_RST_ni    (1'b1),
      .SCAN_CFG_DONE_i(1'b0),
      .SCAN_i         (20'h0),
      .SCAN_o         (),

      // SOC signals
      .PSEL(psel_s),
      .PWRITE(pwrite_s),
      .PENABLE(penable_s),
      .PWDATA(pwdata_s),
      .PRDATA(prdata_s),
      .PREADY(pready_s),
      .PADDR(paddr_s),

      .control_in(control_in),
      .status_out(status_out),
      .version(version),
      .fpgaio_oe(fpga_oe),  // ouput
      .fpgaio_out(fpga_out),  // ouput
      .fpgaio_in(fpga_in),  // input
      .events_o(events_o),  // output
      .lint_RDATA(lint_RDATA),
      .lint_GNT(lint_GNT),
      .lint_VALID(lint_VALID),
      .tcdm_addr_p0(tcdm_addr_p0),
      .tcdm_wdata_p0(tcdm_wdata_p0),
      .tcdm_req_p0(tcdm_req_p0),
      .tcdm_wen_p0(tcdm_wen_p0),
      .tcdm_be_p0(tcdm_be_p0),
      .lint_ADDR(lint_ADDR),
      .lint_BE(lint_BE),
      .lint_WDATA(lint_WDATA),
      .lint_WEN(lint_WEN),
      .lint_REQ(lint_REQ),
      .tcdm_rdata_p0(tcdm_rdata_p0),
      .tcdm_gnt_p0(tcdm_gnt_p0),
      .tcdm_fmo_p0(tcdm_fmo_p0),
      .tcdm_valid_p0(tcdm_valid_p0)
  );

endmodule
