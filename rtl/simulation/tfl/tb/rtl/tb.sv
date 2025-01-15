`timescale 1ns / 1ns
module tb (
    input wire dump_result,
    input wire PCLK_i,
    input wire PRESET_ni
);

  wire PCLK;
  wire PRESETn;
  wire PSEL, PWRITE, PENABLE;

  wire [14:0] PADDR;
  reg  [31:0] PWDATA;
  wire        PREADY;
  wire [31:0] PRDATA;
  wire [ 2:0] PPROT;
  wire [ 3:0] PSTRB;

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

  wire intr_0;

  logic [31:0] tcdm_rdata_p0, tcdm_rdata_p1, tcdm_rdata_p2, tcdm_rdata_p3;
  logic [31:0] tcdm_wdata_p0, tcdm_wdata_p1, tcdm_wdata_p2, tcdm_wdata_p3;
  logic [19:0] tcdm_addr_p0, tcdm_addr_p1, tcdm_addr_p2, tcdm_addr_p3;
  logic [3:0] tcdm_be_p0, tcdm_be_p1, tcdm_be_p2, tcdm_be_p3;
  logic tcdm_req_p0, tcdm_gnt_p0, tcdm_valid_p0;
  logic tcdm_req_p1, tcdm_gnt_p1, tcdm_valid_p1;
  logic tcdm_req_p2, tcdm_gnt_p2, tcdm_valid_p2;
  logic tcdm_req_p3, tcdm_gnt_p3, tcdm_valid_p3;
  logic tcdm_wen_p0, tcdm_wen_p1, tcdm_wen_p2, tcdm_wen_p3;


  reg stop;



`ifdef WAVE
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb.top.u_conv2d);
    $dumpvars(0, tb.m1);
  end
`endif

  initial begin
    //   #0 PCLK = 0;
    #0 stop = 0;
  end
  //initial forever #10 PCLK = ~PCLK;
  assign PCLK = PCLK_i;
  assign PRESETn = PRESET_ni;

  tfl top (
      .PCLK(PCLK),
      .rstn(PRESETn),
      .PSEL(PSEL),
      .PWRITE(PWRITE),
      .PENABLE(PENABLE),
      .PADDR(PADDR[8:2]),
      .PWDATA(PWDATA),
      .PREADY(PREADY),
      .PRDATA(PRDATA),
      .intr_0(intr_0),
      .gpio_o(gpio_o),
      .gpio_oe(gpio_oe),
      .gpio_i(gpio_i),
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
      .tcdm_rdata_p0(tcdm_rdata_p0),
      .tcdm_wdata_p0(tcdm_wdata_p0),
      .tcdm_addr_p0(tcdm_addr_p0),
      .tcdm_be_p0(tcdm_be_p0),
      .tcdm_req_p0(tcdm_req_p0),
      .tcdm_gnt_p0(tcdm_gnt_p0),
      .tcdm_valid_p0(tcdm_valid_p0),
      .tcdm_wen_p0(tcdm_wen_p0),
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


  apb #(
      // .filename("vec/apb1.vec"),
      .quiet(1)
  ) apb (
      .PCLK(PCLK),
      .PRESETn(PRESETn),
      .PADDR(PADDR),
      .PPROT(PPROT),
      .PSEL(PSEL),
      .PENABLE(PENABLE),
      .PWRITE(PWRITE),
      .PWDATA(PWDATA),
      .PSTRB(PSTRB),
      .PREADY(PREADY),
      .PSLVERR(PSLVERR),
      .PRDATA(PRDATA),
      .stop(stop)
  );

  MATH_BLOCK m2 (
      .FMATHB_EFPGA_MAC_OUT(mult2_in),
      .EFPGA2MATHB_CLK(m2_clk),
      .EFPGA_MATHB_CLK_EN(m2_clken),
      .TPRAM_MATHB_OPER_R_DATA(m2_ram_oper),
      .EFPGA_MATHB_OPER_DATA(mult2_oper),
      .EFPGA_MATHB_OPER_defPin(m2_oper_sel),
      .EFPGA_MATHB_OPER_SEL(m2_osel),

      .TPRAM_MATHB_COEF_R_DATA(m2_ram_coef),
      .EFPGA_MATHB_COEF_DATA(mult2_coef),
      .EFPGA_MATHB_COEF_defPin(m2_coef_sel),
      .EFPGA_MATHB_COEF_SEL(m2_csel),

      .EFPGA_MATHB_TC_defPin  (m2_tc),
      .EFPGA_MATHB_MAC_OUT_SEL(m2_outsel),

      .EFPGA_MATHB_MAC_ACC_SAT  (m2_sat),
      .EFPGA_MATHB_MAC_ACC_CLEAR(m2_clr),
      .EFPGA_MATHB_MAC_ACC_RND  (m2_rnd),

      .EFPGA_MATHB_DATAOUT_SEL(m2_math_mode)
  );

  MATH_BLOCK m1 (
      .FMATHB_EFPGA_MAC_OUT(mult1_in),
      .EFPGA2MATHB_CLK(m1_clk),
      .EFPGA_MATHB_CLK_EN(m1_clken),

      .TPRAM_MATHB_OPER_R_DATA(m1_ram_oper),
      .EFPGA_MATHB_OPER_DATA(mult1_oper),
      .EFPGA_MATHB_OPER_defPin(m1_oper_sel),
      .EFPGA_MATHB_OPER_SEL(m1_osel),

      .TPRAM_MATHB_COEF_R_DATA(m1_ram_coef),
      .EFPGA_MATHB_COEF_DATA(mult1_coef),
      .EFPGA_MATHB_COEF_defPin(m1_coef_sel),
      .EFPGA_MATHB_COEF_SEL(m1_csel),

      .EFPGA_MATHB_TC_defPin  (m1_tc),
      .EFPGA_MATHB_MAC_OUT_SEL(m1_outsel),

      .EFPGA_MATHB_MAC_ACC_SAT  (m1_sat),
      .EFPGA_MATHB_MAC_ACC_CLEAR(m1_clr),
      .EFPGA_MATHB_MAC_ACC_RND  (m1_rnd),

      .EFPGA_MATHB_DATAOUT_SEL(m1_math_mode)
  );


  TPRAM_WRAP oram1 (
      // Outputs
      .TPRAM_MATHB_R_DATA (m1_ram_oper),
      .TPRAM_EFPGA_R_DATA (oper1_rdata),
      // Inputs
      .EFPGA_TPRAM_R_MODE (oper1_rmode),
      .EFPGA_TPRAM_W_MODE (oper1_wmode),
      .EFPGA_TPRAM_WDSEL  (oper1_wdsel),
      .EFPGA_TPRAM_WE     (oper1_we),
      .EFPGA_TPRAM_R_CLK  (oper1_rclk),
      .EFPGA_TPRAM_R_ADDR (oper1_raddr),
      .EFPGA_TPRAM_W_CLK  (oper1_wclk),
      .EFPGA_TPRAM_W_ADDR (oper1_waddr),
      .EFPGA_TPRAM_W_DATA (oper1_wdata),
      .MATHB_TPRAM_W_DATA (32'h0),
      .EFPGA_TPRAM_POWERDN(1'b0)
  );

  TPRAM_WRAP cram1 (
      // Outputs
      .TPRAM_MATHB_R_DATA (m1_ram_coef),
      .TPRAM_EFPGA_R_DATA (coef1_rdata),
      // Inputs
      .EFPGA_TPRAM_R_MODE (coef1_rmode),
      .EFPGA_TPRAM_W_MODE (coef1_wmode),
      .EFPGA_TPRAM_WDSEL  (coef1_wdsel),
      .EFPGA_TPRAM_WE     (coef1_we),
      .EFPGA_TPRAM_R_CLK  (coef1_rclk),
      .EFPGA_TPRAM_R_ADDR (coef1_raddr),
      .EFPGA_TPRAM_W_CLK  (coef1_wclk),
      .EFPGA_TPRAM_W_ADDR (coef1_waddr),
      .EFPGA_TPRAM_W_DATA (coef1_wdata),
      .MATHB_TPRAM_W_DATA (32'h0),
      .EFPGA_TPRAM_POWERDN(1'b0)
  );
  TPRAM_WRAP oram2 (
      // Outputs
      .TPRAM_MATHB_R_DATA (m2_ram_oper),
      .TPRAM_EFPGA_R_DATA (oper2_rdata),
      // Inputs
      .EFPGA_TPRAM_R_MODE (oper2_rmode),
      .EFPGA_TPRAM_W_MODE (oper2_wmode),
      .EFPGA_TPRAM_WDSEL  (oper2_wdsel),
      .EFPGA_TPRAM_WE     (oper2_we),
      .EFPGA_TPRAM_R_CLK  (oper2_rclk),
      .EFPGA_TPRAM_R_ADDR (oper2_raddr),
      .EFPGA_TPRAM_W_CLK  (oper2_wclk),
      .EFPGA_TPRAM_W_ADDR (oper2_waddr),
      .EFPGA_TPRAM_W_DATA (oper2_wdata),
      .MATHB_TPRAM_W_DATA (32'h0),
      .EFPGA_TPRAM_POWERDN(1'b0)
  );

  TPRAM_WRAP cram2 (
      // Outputs
      .TPRAM_MATHB_R_DATA (m2_ram_coef),
      .TPRAM_EFPGA_R_DATA (coef2_rdata),
      // Inputs
      .EFPGA_TPRAM_R_MODE (coef2_rmode),
      .EFPGA_TPRAM_W_MODE (coef2_wmode),
      .EFPGA_TPRAM_WDSEL  (coef2_wdsel),
      .EFPGA_TPRAM_WE     (coef2_we),
      .EFPGA_TPRAM_R_CLK  (coef2_rclk),
      .EFPGA_TPRAM_R_ADDR (coef2_raddr),
      .EFPGA_TPRAM_W_CLK  (coef2_wclk),
      .EFPGA_TPRAM_W_ADDR (coef2_waddr),
      .EFPGA_TPRAM_W_DATA (coef2_wdata),
      .MATHB_TPRAM_W_DATA (32'h0),
      .EFPGA_TPRAM_POWERDN(1'b0)
  );


  tcdm #(
      .quiet(1)
      //    .pixel("../sim/pixel_1.dat"), 
      //    .filter("../sim/filter_1.dat"), 
      //    .bias("../sim/bias_16_fract.dat"),
      //    .result("../sim/result.dat"),
      //    .expected("../sim/expect_1.dat")
  ) tcdm (
      .dump_result(dump_result),
      .clk(PCLK),
      .rstn(PRESETn),
      .tcdm_addr_p0(tcdm_addr_p0),
      .tcdm_addr_p1(tcdm_addr_p1),
      .tcdm_addr_p2(tcdm_addr_p2),
      .tcdm_addr_p3(tcdm_addr_p3),
      .tcdm_wdata_p0(tcdm_wdata_p0),
      .tcdm_wdata_p1(tcdm_wdata_p1),
      .tcdm_wdata_p2(tcdm_wdata_p2),
      .tcdm_wdata_p3(tcdm_wdata_p3),
      .tcdm_be_p0(tcdm_be_p0),
      .tcdm_be_p1(tcdm_be_p1),
      .tcdm_be_p2(tcdm_be_p2),
      .tcdm_be_p3(tcdm_be_p3),
      .tcdm_req_p0(tcdm_req_p0),
      .tcdm_req_p1(tcdm_req_p1),
      .tcdm_req_p2(tcdm_req_p2),
      .tcdm_req_p3(tcdm_req_p3),
      .tcdm_wen_p0(tcdm_wen_p0),
      .tcdm_wen_p1(tcdm_wen_p1),
      .tcdm_wen_p2(tcdm_wen_p2),
      .tcdm_wen_p3(tcdm_wen_p3),
      .tcdm_rdata_p0(tcdm_rdata_p0),
      .tcdm_rdata_p1(tcdm_rdata_p1),
      .tcdm_rdata_p2(tcdm_rdata_p2),
      .tcdm_rdata_p3(tcdm_rdata_p3),
      .tcdm_valid_p0(tcdm_valid_p0),
      .tcdm_valid_p1(tcdm_valid_p1),
      .tcdm_valid_p2(tcdm_valid_p2),
      .tcdm_valid_p3(tcdm_valid_p3),
      .tcdm_gnt_p0(tcdm_gnt_p0),
      .tcdm_gnt_p1(tcdm_gnt_p1),
      .tcdm_gnt_p2(tcdm_gnt_p2),
      .tcdm_gnt_p3(tcdm_gnt_p3)
  );

endmodule  // tb





