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
module MBH_MSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128
   (
     input CLK_A,
     input CLK_B,
     input CEN_A,
     input CEN_B,
     input DEEPSLEEP,
     input POWERGATE,
     input [7+2-1:0] aA,
     input [7+2-1:0] aB,
     input [64-1:0] D,
     input [64-1:0] BW,
     input T_LOGIC,
     input MA_TPA,
     input MA_TPB,
     input MA_SAWL,
     input MA_WL,
     input MA_WRAS,
     input MA_WRASD,
     input RWE,
     input [5:0] RWFA,
     output [64-1:0] Q,
     output [64-1:0] OBSV_DBW,
     output OBSV_CTL_A,
     output OBSV_CTL_B
     );

// VSIA_Soft_IP_Tag % Vendor INVECAS % Product 22FDX % Version v00r50 % Metric 100 % IP_Owner VTMDC % Celltype IP % Cell_Id MBH_MSWL_IN22FDX_R2PV_WFVG_W00512B064M04C128 % Signature 100 % Tag_Spec 3.0 % Date_Time 20180817 % Process_Step Source

   wire [7-1:0]   n_awA, n_awB;
   wire [2-1:0]   n_acA, n_acB;
   assign {n_awA, n_acA} = aA;
   assign {n_awB, n_acB} = aB;
   IN22FDX_R2PV_WFVG_W00512B064M04C128 R2P
     (
      .CLK_A       (CLK_A),
      .CLK_B       (CLK_B),
      .CEN_A       (CEN_A),
      .CEN_B       (CEN_B),
      .DEEPSLEEP   (DEEPSLEEP),
      .POWERGATE   (POWERGATE),
      .AW_A        (n_awA),
      .AC_A        (n_acA),
      .AW_B        (n_awB),
      .AC_B        (n_acB),
      .D           (D),
      .BW          (BW),
      .T_LOGIC     (T_LOGIC),
      .MA_TPA      (MA_TPA),
      .MA_TPB      (MA_TPB),
      .MA_SAWL     (MA_SAWL),
      .MA_WL       (MA_WL),
      .MA_WRAS     (MA_WRAS),
      .MA_WRASD    (MA_WRASD),
      .RWE         (RWE),
      .RWFA        (RWFA),
      .Q           (Q),
      .OBSV_DBW    (OBSV_DBW),
      .OBSV_CTL_A  (OBSV_CTL_A),
      .OBSV_CTL_B  (OBSV_CTL_B)
      );
endmodule
