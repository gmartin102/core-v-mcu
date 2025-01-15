//==========================================================================
//== INVECAS, Inc.
//== Generated: 08/17/2018 03:01:09
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

//////////////////////////////////////////////
// INVECAS, Inc.
// Generated: // Fri Aug 17 15:01:09 2018
// 22FDX PDK N/A
//
// INVECAS // IVCS VLOG_WRAPPER 000.00
//
// Copyright (c) 2015 INVECAS, Inc.
// All Rights Reserved.
// CONFIDENTIAL AND PROPRIETARY SOFTWARE OF INVECAS, INC.
//
// This file may not be reproduced, modified or disclosed, without express written
// permission of INVECAS, Inc.
////////////////////////////////////////////////
//
// Key parameters (exist only in the lower level *_memory_generic model inside of the verilog outer shell):
//  MSG_LVL -- sets amount of messaging that appears in log
//             1: only prints errors
//             2: default, prints errors & warnings
//             3: prints informational messages also
//
//  SKIP_POR -- enables memory operation when fuse inputs (MA margin adjust and RB / RW redundant steering) are 'x'.
//             Causes warning to be printed (fuse download simulation should be run to ensure these signals are initialized correctly).
//             Assigned to SKIP_POR_wire in case value needs to be forced/changed during simulation.
//
//  CLOCK_SEP -- minimum amount of time after a write occurs before a read to the same location can occur, defaults to 1ns (multi-port specific)
//
//  WL_FAIL / BL_FAIL / CELLx_FAIL -- used to inject fails into the memory during simulation.
//             Assigned to *_wire in case values need to be forced/changed during simulation.
//             See parameter declaration section of *_memory_generic model for more details.
//
//  PG_WKUP_CNT / DS_WKUP_CNT -- dictates number of no-op cycles expected after exiting Powergate or Deepsleep modes.
//             Default value is 20 cycles for Deepsleep and 4 cycles for Powergate (based on a 500ps cycle and worst case memory size).
//             This can be adjusted by the user for other clock frequencies / guard times.
//             Assigned to *_WKUP_CNT_wire before use in case value needs to be forced during simulation.
//
//  TESTCHIP -- reserved for development use only (disables error messages related to T_STAB/T_WBT/MA when asserted, turns off DEEPSLEEP/POWERGATE sequence checking).
//
// Key defines:
//  IVCS_RELAX_COLL_CHECK -- enables a write operation to be considered "complete" after a CLOCK_SEP amount of time occurs (even if write clock has stopped).
//
//  IVCS_MEM_T* -- Various parameters used to set default delay values in outer shell
//
//  IVCS_PG -- enables power pins in design (VDD, VSS, VCS, VBN, VBP)
//
//  IVCS_FAST_FUNC -- enables compilation of memory model using "fast functional" model (*_memory_generic_fast_func).
//             This can be defined for faster simulations (removes logic test, fail injection and redundancy modeling).
//
//  IVCS_SIMPLE_MODEL -- Creates a simplified logically arranged array (words x bits).  Allows for easier initialization when using the "fast functional" model with IVCS_FAST_FUNC defined.
//                     Does not support logic test / redundancy modeling / fail injection.
//
//  IVCS_INIT_MEM -- preloads memory to all 0s
//             This can be defined if customer desires.
//             If this is defined a wire IVCS_INIT_MEM_wire will also exist -- any transition on this wire will also init the memory to 0, allowing for a re-initialization by the customer via a force statement.
//
//  IVCS_MSG_LVL -- if defined this overrides the default MSG_LVL setting
//
//  IVCS_PGDS_DELAYCHK -- if defined this overrides the normal checking of DEEPSLEEP/POWERGATE sequence checking (changes from counting clocked no-ops to just a CEN vs. DS/PG delay check)
//             When using this mode is highly recommended that you set the following defines to an accurate/conservative value:
//                 IVCS_MEM_TCYC to your slowest on chip cycle time (governs delay from CEN rise to entering a power mode)
//                 IVCS_MEM_TPGH to the value recommended in the datasheet for your largest low power memory OR at least to 4x your cycle time (governs delay from exiting Powergate to when you can lower CEN)
//                 IVCS_MEM_TDSH to the value recommended in the datasheet for your largest low power memory OR at least to 20x your cycle time (governs delay from exiting Deepsleep to when you can lower CEN)
//
/*********************************************************************************/
`timescale 1ns / 1ps
`define IVCS_RELAX_COLL_CHECK
//Default values for specify statements
`ifndef IVCS_MEM_TXS
 `define IVCS_MEM_TXS  0.01
`endif

`ifndef IVCS_MEM_TXH
 `define IVCS_MEM_TXH  0.0
`endif

`ifndef IVCS_MEM_TCYC
 `define IVCS_MEM_TCYC 0.40
`endif

`ifndef IVCS_MEM_TCKH
 `define IVCS_MEM_TCKH 0.0
`endif

`ifndef IVCS_MEM_TCKL
 `define IVCS_MEM_TCKL 0.10
`endif

`ifndef IVCS_MEM_TDSPGH
 `define IVCS_MEM_TDSPGH 0.40
`endif

`ifndef IVCS_MEM_TACC
 `define IVCS_MEM_TACC 0.20
`endif

`ifndef IVCS_MEM_TDSPGS
 `define IVCS_MEM_TDSPGS 0.40
`endif

`ifndef IVCS_MEM_TPGH
 `define IVCS_MEM_TPGH 2.00
`endif

`ifndef IVCS_MEM_TDSH
 `define IVCS_MEM_TDSH 10.00
`endif

`ifndef IVCS_MEM_TPROP
 `define IVCS_MEM_TPROP 0.20
`endif

`celldefine
module IN22FDX_R2PV_WFVG_W00512B064M04C128
(
 `ifdef IVCS_PG
 inout VDD,
 inout VCS,
 inout VBN,
 inout VBP,
 inout VSS,
 `endif

 input CLK_A,
 input CLK_B,
 input CEN_A,
 input CEN_B,
 input DEEPSLEEP,
 input POWERGATE,
 input [6:0] AW_A,
 input [1:0] AC_A,
 input [6:0] AW_B,
 input [1:0] AC_B,
 input [63:0] D,
 input [63:0] BW,
 input T_LOGIC,
 input MA_SAWL,
 input MA_WL,
 input MA_WRAS,
 input MA_WRASD,
 input MA_TPA,
 input MA_TPB,
 input RWE,
 input [5:0] RWFA,
 output [63:0] Q,
 output [63:0] OBSV_DBW,
 output OBSV_CTL_A,
 output OBSV_CTL_B

);

wire [1:0] dummyQRB;

//Notifier handling
reg notifier = 1'b0;

reg notifier_TSH_CLKA_CENA, notifier_TSH_CLKB_CENB, notifier_TSH_CLKA_DS, notifier_TSH_CLKB_DS, notifier_TSH_CLKB_PG,
    notifier_TSH_CLKA_PG, notifier_TSH_CLKA_ASA, notifier_TSH_CLKA_AWA, notifier_TSH_CLKA_ACA, notifier_TSH_CLKB_ASB, notifier_TSH_CLKB_AWB,
    notifier_TSH_CLKB_ACB, notifier_TSH_CLKB_D, notifier_TSH_CLKB_BW, notifier_TSH_CLKA_TBIST, notifier_TSH_CLKA_TLOGIC, notifier_TSH_CLKA_TSCANA, notifier_TSH_CLKA_TSIA, notifier_TSH_CLKB_TBIST, notifier_TSH_CLKB_TLOGIC, notifier_TSH_CLKB_TSCANB, notifier_TSH_CLKB_TSIB,
    notifier_TSH_CLKA_TCENA, notifier_TSH_CLKB_TCENB, notifier_TSH_CLKB_TDS, notifier_TSH_CLKB_TPG,
    notifier_TPW_DSPG1, notifier_TS_DSPG, notifier_TH_DSPG, notifier_TCYC_CLKA, notifier_TCYC_CLKB, notifier_TPW_CLKA1, notifier_TPW_CLKA0, notifier_TPW_CLKB1, notifier_TPW_CLKB0,
    notifier_TSH_CLKA_TDS, notifier_TSH_CLKA_TPG, notifier_TSH_CLKA_TASA, notifier_TSH_CLKA_TAWA, notifier_TSH_CLKB_TASB, notifier_TSH_CLKB_TACB,
    notifier_TSH_CLKB_TD, notifier_TSH_CLKB_TBW, notifier_TSH_CLKB_TWBT, notifier_TSH_CLKB_TSTAB, notifier_TSH_CLKB_TCLKMODEB, notifier_TSH_CLKB_MASAWL,
    notifier_TSH_CLKA_TWBT, notifier_TSH_CLKA_TSTAB, notifier_TSH_CLKA_MASAWL,
    notifier_TSH_CLKA_MAWL, notifier_TSH_CLKA_MAWRAS, notifier_TSH_CLKA_MAWRASD, notifier_TSH_CLKA_MATPA, notifier_TSH_CLKA_MATPB,
    notifier_TSH_CLKB_MAWL, notifier_TSH_CLKB_MAWRAS, notifier_TSH_CLKB_MAWRASD, notifier_TSH_CLKB_MATPB, notifier_TSH_CLKB_MATPA,
    notifier_TSH_CLKA_TACA, notifier_TSH_CLKB_TAWB,
    notifier_TSH_CLKA_RWE, notifier_TSH_CLKA_RWFA,
    notifier_TSH_CLKB_RWE, notifier_TSH_CLKB_RWFA;

always @(notifier_TSH_CLKA_CENA or  notifier_TSH_CLKB_CENB or notifier_TSH_CLKA_DS or notifier_TSH_CLKB_DS or notifier_TSH_CLKB_PG or
         notifier_TSH_CLKA_PG or  notifier_TSH_CLKA_ASA or  notifier_TSH_CLKA_AWA or  notifier_TSH_CLKA_ACA or  notifier_TSH_CLKB_ASB or  notifier_TSH_CLKB_AWB or
         notifier_TSH_CLKB_ACB or  notifier_TSH_CLKB_D or  notifier_TSH_CLKB_BW or  notifier_TSH_CLKA_TBIST or  notifier_TSH_CLKA_TLOGIC or  notifier_TSH_CLKA_TSCANA or  notifier_TSH_CLKA_TSIA or  notifier_TSH_CLKB_TBIST or  notifier_TSH_CLKB_TLOGIC or  notifier_TSH_CLKB_TSCANB or  notifier_TSH_CLKB_TSIB or
         notifier_TSH_CLKA_TCENA or  notifier_TSH_CLKB_TCENB or notifier_TSH_CLKB_TDS or notifier_TSH_CLKB_TPG or
         notifier_TPW_DSPG1 or  notifier_TS_DSPG or  notifier_TH_DSPG or  notifier_TCYC_CLKA or  notifier_TCYC_CLKB or  notifier_TPW_CLKA1 or  notifier_TPW_CLKA0 or  notifier_TPW_CLKB1 or  notifier_TPW_CLKB0 or
         notifier_TSH_CLKA_TDS or  notifier_TSH_CLKA_TPG or  notifier_TSH_CLKA_TASA or  notifier_TSH_CLKA_TAWA or  notifier_TSH_CLKB_TASB or  notifier_TSH_CLKB_TACB or
         notifier_TSH_CLKB_TD or  notifier_TSH_CLKB_TBW or  notifier_TSH_CLKB_TWBT or  notifier_TSH_CLKB_TSTAB or  notifier_TSH_CLKB_TCLKMODEB or notifier_TSH_CLKB_MASAWL or
         notifier_TSH_CLKA_TWBT or  notifier_TSH_CLKA_TSTAB or  notifier_TSH_CLKA_MASAWL or
         notifier_TSH_CLKA_MAWL or  notifier_TSH_CLKA_MAWRAS or  notifier_TSH_CLKA_MAWRASD or notifier_TSH_CLKA_MATPA or notifier_TSH_CLKA_MATPB or
         notifier_TSH_CLKB_MAWL or  notifier_TSH_CLKB_MAWRAS or  notifier_TSH_CLKB_MAWRASD or notifier_TSH_CLKB_MATPB or notifier_TSH_CLKB_MATPA or
         notifier_TSH_CLKA_TACA or  notifier_TSH_CLKB_TAWB or
         notifier_TSH_CLKA_RWE or notifier_TSH_CLKA_RWFA or
         notifier_TSH_CLKB_RWE or notifier_TSH_CLKB_RWFA)
begin
 notifier = ~notifier;
end

`ifdef IVCS_FAST_FUNC
r2ph_memory_generic_fast_func
`else
r2ph_memory_generic
`endif
#(
 .ALLOW_MA(1'b1),
 .W_DEPTH(512),
 .AW_SIZE(7),
 .AC_SIZE(2),
 .D_SIZE(64)
)
mem0
(
 `ifdef IVCS_PG
 .VDD(VDD),
 .VCS(VCS),
 .VBN(VBN),
 .VBP(VBP),
 .VSS(VSS),
 `endif
 .notifier(notifier),
 .clkA(CLK_A),
 .clkB(CLK_B),
 .cenA(CEN_A),
 .cenB(CEN_B),
 .deepsleep(DEEPSLEEP),
 .powergate(POWERGATE),
 .awA(AW_A[6:0]),
 .acA(AC_A[1:0]),
 .awB(AW_B[6:0]),
 .acB(AC_B[1:0]),
 .d(D[63:0]),
 .bw(BW[63:0]),
 .t_logic(T_LOGIC),
 .pipeline(1'b0),
 .deepsleep_byp(1'b0),
 .ma_sawl(MA_SAWL),
 .ma_wl(MA_WL),
 .ma_wras(MA_WRAS),
 .ma_wrasd(MA_WRASD),
 .ma_tpA(MA_TPA),
 .ma_tpB(MA_TPB),
 .rwe({1'b0,RWE}),
 .rwf1a({6{1'b0}}),
 .rwf0a(RWFA[5:0]),

 .rbe(2'b00),
 .rbf1a(8'b0000_0000),
 .rbf0a(8'b0000_0000),

 .q(Q[63:0]),
 .obsv_dbw(OBSV_DBW[63:0]),
 .qrb(dummyQRB),
 .obsv_ctlA(OBSV_CTL_A),
 .obsv_ctlB(OBSV_CTL_B)

);

wire never;
wire MASAWL_MAWL_MATPA     =  MA_SAWL &  MA_WL &  MA_TPA;
wire MASAWL_MAWL_NMATPA    =  MA_SAWL &  MA_WL & ~MA_TPA;
wire MASAWL_NMAWL_MATPA    =  MA_SAWL & ~MA_WL &  MA_TPA;
wire MASAWL_NMAWL_NMATPA   =  MA_SAWL & ~MA_WL & ~MA_TPA;
wire NMASAWL_MAWL_MATPA    = ~MA_SAWL &  MA_WL &  MA_TPA;
wire NMASAWL_MAWL_NMATPA   = ~MA_SAWL &  MA_WL & ~MA_TPA;
wire NMASAWL_NMAWL_MATPA   = ~MA_SAWL & ~MA_WL &  MA_TPA;
wire NMASAWL_NMAWL_NMATPA  = ~MA_SAWL & ~MA_WL & ~MA_TPA;
wire NTLOGIC;
assign NTLOGIC = ~T_LOGIC;

`ifdef IVCS_NO_SPEC_CHK
 //Define to turn off non-timing critical checks for typically asynchronous paths
 assign never = 0;
`else
 assign never = 1;
`endif

specify
 specparam
 tdelay_CLK_X_01   = `IVCS_MEM_TACC,
 tdelay_CLK_X_10   = `IVCS_MEM_TACC,
 tdelay_PROP_X_01  = `IVCS_MEM_TPROP,
 tdelay_PROP_X_10  = `IVCS_MEM_TPROP,
 tpw_CLK_0         = `IVCS_MEM_TCKL,
 tpw_CLK_1         = `IVCS_MEM_TCKH,
 tpw_DSPG_1        = `IVCS_MEM_TDSPGH,
 tcyc_CLK          = `IVCS_MEM_TCYC,
 tsetup_X_CLK      = `IVCS_MEM_TXS,
 thold_X_CLK       = `IVCS_MEM_TXH,
 tsetup_DSPG       = `IVCS_MEM_TDSPGS,
 thold_PG          = `IVCS_MEM_TPGH,
 thold_DS          = `IVCS_MEM_TDSH;

 $period(posedge CLK_A &&& MASAWL_MAWL_MATPA   , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& MASAWL_MAWL_NMATPA  , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& MASAWL_NMAWL_MATPA  , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& MASAWL_NMAWL_NMATPA , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& NMASAWL_MAWL_MATPA  , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& NMASAWL_MAWL_NMATPA , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& NMASAWL_NMAWL_MATPA , tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_A &&& NMASAWL_NMAWL_NMATPA, tcyc_CLK, notifier_TCYC_CLKA);
 $period(posedge CLK_B &&& MASAWL_MAWL_MATPA   , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& MASAWL_MAWL_NMATPA  , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& MASAWL_NMAWL_MATPA  , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& MASAWL_NMAWL_NMATPA , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& NMASAWL_MAWL_MATPA  , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& NMASAWL_MAWL_NMATPA , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& NMASAWL_NMAWL_MATPA , tcyc_CLK, notifier_TCYC_CLKB);
 $period(posedge CLK_B &&& NMASAWL_NMAWL_NMATPA, tcyc_CLK, notifier_TCYC_CLKB);

 $width(posedge CLK_A, tpw_CLK_1, 0, notifier_TPW_CLKA1);
 $width(negedge CLK_A, tpw_CLK_0, 0, notifier_TPW_CLKA0);
 $width(posedge CLK_B, tpw_CLK_1, 0, notifier_TPW_CLKB1);
 $width(negedge CLK_B, tpw_CLK_0, 0, notifier_TPW_CLKB0);
 $width(posedge DEEPSLEEP &&& NTLOGIC, tpw_DSPG_1, 0, notifier_TPW_DSPG1);
 $width(posedge POWERGATE &&& NTLOGIC, tpw_DSPG_1, 0, notifier_TPW_DSPG1);

 $setup (posedge CEN_A, posedge DEEPSLEEP  &&& NTLOGIC, tsetup_DSPG,  notifier_TS_DSPG);
 $setup (posedge CEN_A, posedge POWERGATE  &&& NTLOGIC, tsetup_DSPG,  notifier_TS_DSPG);
 $hold (negedge DEEPSLEEP &&& NTLOGIC,negedge CEN_A, thold_DS,  notifier_TS_DSPG);
 $hold (negedge POWERGATE &&& NTLOGIC,negedge CEN_A, thold_PG,  notifier_TS_DSPG);
 $setup (posedge CEN_B, posedge DEEPSLEEP  &&& NTLOGIC, tsetup_DSPG,  notifier_TS_DSPG);
 $setup (posedge CEN_B, posedge POWERGATE  &&& NTLOGIC, tsetup_DSPG,  notifier_TS_DSPG);
 $hold (negedge DEEPSLEEP &&& NTLOGIC,negedge CEN_B, thold_DS,  notifier_TS_DSPG);
 $hold (negedge POWERGATE &&& NTLOGIC,negedge CEN_B, thold_PG,  notifier_TS_DSPG);

 $setuphold (posedge CLK_A, posedge CEN_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_CENA);
 $setuphold (posedge CLK_A, negedge CEN_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_CENA);
 $setuphold (posedge CLK_B, posedge CEN_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_CENB);
 $setuphold (posedge CLK_B, negedge CEN_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_CENB);
 $setuphold (posedge CLK_A, posedge AW_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_AWA);
 $setuphold (posedge CLK_A, negedge AW_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_AWA);
 $setuphold (posedge CLK_A, posedge AC_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_ACA);
 $setuphold (posedge CLK_A, negedge AC_A, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_ACA);
 $setuphold (posedge CLK_B, posedge AW_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_AWB);
 $setuphold (posedge CLK_B, negedge AW_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_AWB);
 $setuphold (posedge CLK_B, posedge AC_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_ACB);
 $setuphold (posedge CLK_B, negedge AC_B, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_ACB);
 $setuphold (posedge CLK_B, posedge D, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_D);
 $setuphold (posedge CLK_B, negedge D, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_D);
 $setuphold (posedge CLK_B, posedge BW, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_BW);
 $setuphold (posedge CLK_B, negedge BW, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_BW);
 $setuphold (posedge CLK_A &&& never, posedge T_LOGIC, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_TLOGIC);
 $setuphold (posedge CLK_A &&& never, negedge T_LOGIC, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_TLOGIC);
 $setuphold (posedge CLK_B &&& never, posedge T_LOGIC, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_TLOGIC);
 $setuphold (posedge CLK_B &&& never, negedge T_LOGIC, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_TLOGIC);
 $setuphold (posedge CLK_A &&& never, posedge MA_SAWL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MASAWL);
 $setuphold (posedge CLK_A &&& never, negedge MA_SAWL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MASAWL);
 $setuphold (posedge CLK_A &&& never, posedge MA_WL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWL);
 $setuphold (posedge CLK_A &&& never, negedge MA_WL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWL);
 $setuphold (posedge CLK_A &&& never, posedge MA_WRAS, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWRAS);
 $setuphold (posedge CLK_A &&& never, negedge MA_WRAS, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWRAS);
 $setuphold (posedge CLK_A &&& never, posedge MA_WRASD, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWRASD);
 $setuphold (posedge CLK_A &&& never, negedge MA_WRASD, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MAWRASD);
 $setuphold (posedge CLK_A &&& never, posedge MA_TPA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MATPA);
 $setuphold (posedge CLK_A &&& never, negedge MA_TPA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MATPA);
 $setuphold (posedge CLK_A &&& never, posedge MA_TPB, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MATPB);
 $setuphold (posedge CLK_A &&& never, negedge MA_TPB, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_MATPB);
 $setuphold (posedge CLK_B &&& never, posedge MA_SAWL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MASAWL);
 $setuphold (posedge CLK_B &&& never, negedge MA_SAWL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MASAWL);
 $setuphold (posedge CLK_B &&& never, posedge MA_WL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWL);
 $setuphold (posedge CLK_B &&& never, negedge MA_WL, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWL);
 $setuphold (posedge CLK_B &&& never, posedge MA_WRAS, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWRAS);
 $setuphold (posedge CLK_B &&& never, negedge MA_WRAS, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWRAS);
 $setuphold (posedge CLK_B &&& never, posedge MA_WRASD, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWRASD);
 $setuphold (posedge CLK_B &&& never, negedge MA_WRASD, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MAWRASD);
 $setuphold (posedge CLK_B &&& never, posedge MA_TPB, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MATPB);
 $setuphold (posedge CLK_B &&& never, negedge MA_TPB, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MATPB);
 $setuphold (posedge CLK_B &&& never, posedge MA_TPA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MATPA);
 $setuphold (posedge CLK_B &&& never, negedge MA_TPA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_MATPA);
 $setuphold (posedge CLK_A &&& never, posedge RWE, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_RWE);
 $setuphold (posedge CLK_A &&& never, negedge RWE, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_RWE);
 $setuphold (posedge CLK_A &&& never, posedge RWFA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_RWFA);
 $setuphold (posedge CLK_A &&& never, negedge RWFA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKA_RWFA);
 $setuphold (posedge CLK_B &&& never, posedge RWE, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_RWE);
 $setuphold (posedge CLK_B &&& never, negedge RWE, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_RWE);
 $setuphold (posedge CLK_B &&& never, posedge RWFA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_RWFA);
 $setuphold (posedge CLK_B &&& never, negedge RWFA, tsetup_X_CLK, thold_X_CLK, notifier_TSH_CLKB_RWFA);

(posedge CLK_A *> (Q          : CEN_A))            = (tdelay_CLK_X_01, tdelay_CLK_X_10);
(posedge AW_A[6:0] => (OBSV_CTL_A : AW_A[6:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge AC_A[1:0] => (OBSV_CTL_A : AC_A[1:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge CEN_A            => (OBSV_CTL_A : CEN_A))            = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge DEEPSLEEP        => (OBSV_CTL_A : DEEPSLEEP))        = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge POWERGATE        => (OBSV_CTL_A : POWERGATE))        = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge AW_A[6:0] => (OBSV_CTL_A : AW_A[6:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge AC_A[1:0] => (OBSV_CTL_A : AC_A[1:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge CEN_A            => (OBSV_CTL_A : CEN_A))            = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge DEEPSLEEP        => (OBSV_CTL_A : DEEPSLEEP))        = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge POWERGATE        => (OBSV_CTL_A : POWERGATE))        = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge AW_B[6:0] => (OBSV_CTL_B : AW_B[6:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge AC_B[1:0] => (OBSV_CTL_B : AC_B[1:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge CEN_B            => (OBSV_CTL_B : CEN_B))            = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge AW_B[6:0] => (OBSV_CTL_B : AW_B[6:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge AC_B[1:0] => (OBSV_CTL_B : AC_B[1:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge CEN_B            => (OBSV_CTL_B : CEN_B))            = (tdelay_PROP_X_01, tdelay_PROP_X_10);

(posedge D[63:0]  => (OBSV_DBW[63:0] : D[63:0]))  = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(posedge BW[63:0] => (OBSV_DBW[63:0] : BW[63:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge D[63:0]  => (OBSV_DBW[63:0] : D[63:0]))  = (tdelay_PROP_X_01, tdelay_PROP_X_10);
(negedge BW[63:0] => (OBSV_DBW[63:0] : BW[63:0])) = (tdelay_PROP_X_01, tdelay_PROP_X_10);

endspecify

endmodule
`endcelldefine

