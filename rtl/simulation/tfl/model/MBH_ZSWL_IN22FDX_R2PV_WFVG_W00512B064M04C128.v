//==========================================================================
//== INVECAS, Inc.
//== Generated: 08/17/2018 03:01:18
//== INVECAS Memory Release: V02R60_16MAY2018
//== 22fdsoi PDK 22FDX_V1.3_0.0
//==
//== IDTK_ROOT: /home/vyen/work/ETH/TPRAM/IN22FDX_MEMR2PV_COMPILER_FE_RELV02R60/idtk
//== IDDK_ROOT: /home/vyen/work/ETH/TPRAM/IN22FDX_MEMR2PV_COMPILER_FE_RELV02R60/iddk
//== IDDK_TECH: 22fdsoi
//==
//== Copyright (c) 2018 INVECAS, Inc.
//== All Rights Reserved.
//==
//== CONFIDENTIAL AND PROPRIETARY SOFTWARE OF INVECAS, INC.
//== This file may not be reproduced, modified or disclosed,
//== without express written permission of INVECAS Inc.
//==========================================================================

`timescale 1ns / 1ps
module MBH_ZSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128
   (
    input  clkA,
    input  clkB,
    input  cenA,
    input  cenB,
    input  deepsleep,
    input  powergate,
    input  [7+2-1:0] aA,
    input  [7+2-1:0] aB,
    input  [64-1:0] d,
    input  [64-1:0] bw,
    output [64-1:0] q
    );

// VSIA_Soft_IP_Tag % Vendor INVECAS % Product 22FDX % Version v00r50 % Metric 100 % IP_Owner VTMDC % Celltype IP % Cell_Id MBH_ZSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128 % Signature 100 % Tag_Spec 3.0 % Date_Time 20180817 % Process_Step Source

   wire [6-1:0] n_rwfa = {6{1'b0}};
   wire [64-1:0]    n_obsv_dbw;
   wire                    n_obsv_ctlA;
   wire                    n_obsv_ctlB;
   MBH_MSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128 MBH0
     (
      .CLK_A       (clkA),
      .CLK_B       (clkB),
      .CEN_A       (cenA),
      .CEN_B       (cenB),
      .DEEPSLEEP   (deepsleep),
      .POWERGATE   (powergate),
      .aA          (aA),
      .aB          (aB),
      .D           (d),
      .BW          (bw),
      .T_LOGIC     (1'b0),
      .MA_SAWL     (1'b0),
      .MA_WL       (1'b0),
      .MA_WRAS     (1'b0),
      .MA_WRASD    (1'b0),
      .MA_TPA      (1'b0),
      .MA_TPB      (1'b0),
      .RWE         (1'b0),
      .RWFA        (n_rwfa),
      .Q           (q),
      .OBSV_DBW    (n_obsv_dbw),
      .OBSV_CTL_A  (n_obsv_ctlA),
      .OBSV_CTL_B  (n_obsv_ctlB)
      );
endmodule
