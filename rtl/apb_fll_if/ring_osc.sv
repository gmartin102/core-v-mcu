
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

module ring_osc (
    input wire [5:0] tap_i,
    input wire 	     ck_i,
    output wire      ck_o,
    input 	     por_i
);
   reg [63:0] 	     delay_tap;
   wire [63:0] 	     ck;
   wire [63:0] 	     ck_s;
   wire [63:0] 	     loop_ck;
   assign ck_s[63] = 0;
   
   assign ck[0] = ck_i;
   assign ck_o = ck_s[0];
   always_comb begin
      delay_tap = 1<<tap_i;
   end  // always_comb
   genvar j;
   for (j = 0; j < 63; j = j + 1) begin : zD2
      rs_wrapper u0 (
		      .por_i(por_i),
		      .enable_i(delay_tap[j]),
		      .loop_i(delay_tap[j+1]),
		      .ck_i(ck[j]),
		      .ck_o(ck_s[j]),
		      .pre_ck_i(ck_s[j+1]),
		      .next_ck_o(ck[j+1])
		      );
   end  // block: zD2
endmodule


