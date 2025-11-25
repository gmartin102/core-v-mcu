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

module rs_wrapper 
  (
   input wire  por_i,
   input wire  enable_i,
   input wire  loop_i,
   input wire  ck_i,
   input wire  pre_ck_i,
   output wire ck_o,
   output wire next_ck_o
   );
   wire        ck, next_ck;
   
   ring_stage u0 
     (
      .por_i(por_i),
      .enable_i(enable_i),
      .loop_i(loop_i),
      .ck_i(ck_i),
      .ck_o(ck),
      .pre_ck_i(pre_ck_i),
      .next_ck_o(next_ck)
      );
   
   assign #0.02 ck_o = ck;
   assign #0.03 next_ck_o = next_ck;
endmodule
