/* ==========================================================
 *
 * -  Copyright Notice  -------------------------------------
 *
 *     Licensed Materials - Property of QuickLogic Corp.
 *     Copyright (C) Year: 2024 QuickLogic Corporation
 *     All rights reserved
 *     Use, duplication, or disclosure restricted
 *
 * ==========================================================*/

`ifndef CK2Q
`ifdef SIM
`define CK2Q #0.1
`else
`define CK2Q
`endif  // SIM
`endif  // CK2Q

`timescale 1ns / 1ps

module ring_stage(
		    input wire 	por_i,
		    input wire 	enable_i,
		    input wire loop_i,
		    input wire 	ck_i,
		    input wire 	pre_ck_i,
		    output wire ck_o,
		    output wire next_ck_o
);

   wire 	ena_o, fbk;
   reg 		latch_en;
/*
   wire         clk_g;
   SC9T_CKGPRELATNX10_SSC14L u0 
     (.Z(clk_g),
      .CLK(ck_i),
      .E(enable_i),
      .TE(1'b0));
*/   

   always_ff@(negedge ck_i or negedge por_i) begin
      if (por_i == 1'b0)
	latch_en <= 1'b0;
      else
	latch_en <= enable_i;
   end

   assign ena_o = ~((enable_i & ~ck_i)  &  fbk & por_i);
   assign fbk =   ~(enable_i & ena_o);
 
   
   
   assign #0.02 ck_o = loop_i ? ck_i : ((latch_en & ck_i ) | pre_ck_i);
   assign #0.03 next_ck_o = (~latch_en & ck_i);


endmodule
