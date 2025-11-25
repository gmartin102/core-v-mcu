//-----------------------------------------------------------------------------
// Title :  CLK Gen for PULPissimo
// -----------------------------------------------------------------------------
// File : sim_clk_gen.sv Author : Tim Saxe
// Created : 2021-05-22
// -----------------------------------------------------------------------------
// Description : Passes ref_clk thru
// -----------------------------------------------------------------------------
// Copyright (C) 2021 QUickLogic Copyright and
// related rights are licensed under the Solderpad Hardware License, Version
// 0.51 (the "License"); you may not use this file except in compliance with the
// License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law or
// agreed to in writing, software, hardware and materials distributed under this
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the specific
// language governing permissions and limitations under the License.
// -----------------------------------------------------------------------------

module apb_pll # (
                  parameter APB_ADDR_WIDTH = 12
                  )
   (
    input logic                      ref_clk_i,
    output logic                     soc_clk_o,
    output logic                     periph_clk_o,
    output logic                     cluster_clk_o,
    output logic                     ref_clk_o,
    input logic                      rst_ni,
    input logic                      HCLK,
    input logic                      HRESETn,
    input logic [APB_ADDR_WIDTH-1:0] PADDR,
    input logic [31:0]               PWDATA,
    input logic                      PWRITE,
    input logic                      PSEL,
    input logic                      PENABLE,
    output logic [31:0]              PRDATA,
    output logic                     PREADY,
    output logic                     PSLVERR,
    inout AVDD,AVDD2,AVSS,VDDC,VSSC
    );

   logic                             PD; // PLL powerdown
   logic                             PDDP; // Post Divider PowerDown
   logic [5:0]                       DM; // Reference input divider
   logic [10:0]                      DN; // Feedback Divider
   logic [2:0]                       DP; // Output Divider
   logic [1:0]                       MODE ; //00=int, 01=frac, 10 = SpreadSpec
   logic [10:0]                      SSRATE; // SPread SPectrum Freq
   logic [23:0]                      SSLOPE; // spread spectrum slope
   logic [23:0]                      FRAC; // Fractional portion of DN
   logic                             BYPASS;
   logic                             PLL_RESET;
   
   
   logic [31:0]                      ControlReg;
   logic [31:0]                      SocDiv;
   logic [31:0]                      PeriphDiv;
   logic [31:0]                      ClusterDiv;
   
   
   logic                             slverr;
   logic                             ready;
   
   logic                             CLKO;
   logic                             LOCK;
   logic                             pll_reset_in;

   logic                             s_bypassn;
   logic                             p_bypassn;
   logic                             c_bypassn;
   logic                             soc_clk_s;
   logic                             periph_clk_s;
   logic                             cluster_clk_s;
   
   
    
   localparam reg_CTL=0;

   localparam reg_SOC=20;
   localparam reg_PERIPH=24;   
   localparam reg_CLUSTER=28;
   localparam reg_REFCLK=32;

   wire [5:0] 			     ring_tap;
   

   enum                              logic [3:0] { IDLE, READ, WRITE, WAIT} state;
   
   always_comb begin
      PREADY = ready & PENABLE;
      PSLVERR = slverr & PENABLE;
   end
   
   
   always_ff @(posedge HCLK, negedge HRESETn) begin
      if (!HRESETn) begin
         state           <= IDLE;
         ControlReg <= 32'h0;
         SocDiv <= 32'd0;
         PeriphDiv <= 32'd0;
         ClusterDiv <= 32'd0;
         
         
         ready <= 0;
         slverr <= 0;
      end
      else begin
         case (state)
           IDLE: begin
              ready <= 0;
              if (PSEL & PENABLE)
                if (PWRITE) state <= WRITE;
                else state <= READ;
           end
           WRITE: begin
              case (PADDR[APB_ADDR_WIDTH-1:0])
                reg_CTL: ControlReg <= PENABLE ? PWDATA : ControlReg ;
                reg_SOC: SocDiv <= PENABLE ? PWDATA : SocDiv;
                reg_PERIPH: PeriphDiv <= PENABLE ? PWDATA : PeriphDiv;
                reg_CLUSTER: ClusterDiv <= PENABLE ? PWDATA : ClusterDiv;
                 default: slverr <= 1;
              endcase // case (PADDR[APB_ADDR_WIDTH-1:0])
              ready <= 1;
              if (PENABLE == 0)
                state <= IDLE;
           end // case: WRITE
           READ: begin
              case (PADDR[APB_ADDR_WIDTH-1:0])
                reg_CTL: PRDATA <= {2'b0,ring_tap,8'h00,ControlReg[15:0]};
                reg_SOC:  PRDATA <= {22'b0,SocDiv[9:0]};
                reg_PERIPH:  PRDATA <= {22'b0,PeriphDiv[9:0]};
                reg_CLUSTER: PRDATA <= {22'b0,ClusterDiv[9:0]};
                default: slverr <= 1;
              endcase // case (PADDR[APB_ADDR_WIDTH-1:0])
              ready <= 1;
              if (PENABLE == 0)
                state <= IDLE;
           end // case: READ
         endcase // case (state)
      end // else: !if(!HRESETn)
   end // always_ff @ (posedge HCLK, negedge HRESETn)


   clkgen u_clkgen (
   .override_i(ControlReg[7]),
   .nco_override_i(ControlReg[13:8]),
   .ring_tap_o(ring_tap),
   .clk_ref_i(ref_clk_i),
   .reset_i(~ControlReg[0]),
   .por_i(~HRESETm),
   .ref_out_o(clk_o)
   );

   
   assign pll_reset_in = ~(~ControlReg[0] | ~HRESETn);
   assign s_bypassn = ~(ControlReg[1] | ControlReg[6]);
   assign p_bypassn = ~(ControlReg[1] | ControlReg[5]);
   assign c_bypassn = ~(ControlReg[1] | ControlReg[4]);
   
  sym_div s_div (
                .CLK_i(CLKO),
                .CLK_o(soc_clk_s),
                .RST_i(~rst_ni),
                .divisor(SocDiv[9:0])
                );
 clk_dmux s_mux (
                .clkinA_i(ref_clk_i),
                .clkinB_i(soc_clk_s),
                .sel_i(s_bypassn),
                .rst_ni(rst_ni),
                .clkout_o(soc_clk_o)
                );
   
  clkdv p_div (
	       .CLK_i(CLKO),
               .CLK_o(periph_clk_s),
               .RST_i(~rst_ni),
               .divisor(SocDiv[9:0])
	       );

 clk_dmux p_mux (
                .clkinA_i(ref_clk_i),
                .clkinB_i(periph_clk_s),
                .sel_i(p_bypassn),
                .rst_ni(rst_ni),
                .clkout_o(periph_clk_o)
                );

  clkdv c_div (
	       .CLK_i(CLKO),
               .CLK_o(cluster_clk_s),
               .RST_i(~rst_ni),
               .divisor(SocDiv[9:0])
               );

 clk_dmux c_mux (
                .clkinA_i(ref_clk_i),
                .clkinB_i(cluster_clk_s),
                .sel_i(c_bypassn),
                .rst_ni(rst_ni),
                .clkout_o(cluster_clk_o)
                );


endmodule // apb_pll


module clk_dmux 
  (
   input  logic clkinA_i,
   input  logic clkinB_i,
   input  logic sel_i,
   input  logic rst_ni,
   output logic clkout_o
   );
   
   logic [1:0] selA;
   logic [1:0] selB;
   logic       clkoutA;
   logic       clkoutB;
   logic       enaA, enaB;
   
   
    always@(posedge clkinA_i or negedge rst_ni) begin
       if (rst_ni == 1'b0)
          selA <= 2'b00;
       else
          selA <= {selA[0],~(selB[1] | sel_i)};
    end

    always@(posedge clkinB_i or negedge rst_ni) begin
       if (rst_ni == 1'b0)
          selB <= 2'b00;
       else
          selB <= {selB[0],(~selA[1] & sel_i)};
    end
   pulp_clock_gating u1 (
                         .clk_i(clkinA_i),
                         .en_i(selA[1]),
                         .test_en_i(1'b0),
                         .clk_o(clkoutA)
                         );

   pulp_clock_gating u2 (
                         .clk_i(clkinB_i),
                         .en_i(selB[1]),
                         .test_en_i(1'b0),
                         .clk_o(clkoutB)
                         );
   pulp_clock_mux2 u3 (
                       .clk0_i(clkoutA),
                       .clk1_i(clkoutB),
                       .clk_sel_i(selB[1]),
                       .clk_o(clkout_o)
                       );
   
endmodule // clk_mux

     
          
         
