/*###########################################################################
##
## Copyright (c) 2015 INVECAS, Inc.
## All Rights Reserved.
## PROPRIETARY AND CONFIDENTIAL INFORMATION OF INVECAS, Inc.
##
## This file may not be reproduced, modified or disclosed,
## without express written permission of INVECAS Inc.
###########################################################################*/
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
//             This can be adjusted by the user for other clock frequencies / guard times (use cycle - 1).
//             Assigned to *_WKUP_CNT_wire before use in case value needs to be forced during simulation.
//
//  TESTCHIP -- reserved for development use only (disables error messages related to MA when asserted, turns off DEEPSLEEP/POWERGATE sequence checking).
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
module r2ph_memory_generic_fast_func
#(
  `ifdef IVCS_MSG_LVL
  parameter MSG_LVL         = `IVCS_MSG_LVL ,
  `else
  parameter MSG_LVL         = 2,
  `endif
  parameter SKIP_POR        = 0,
  parameter TESTCHIP        = 0,
  parameter PG_WKUP_CNT     = 3,
  parameter DS_WKUP_CNT     = 19,
  parameter CLOCK_SEP       = 1,

// These parameters define the size and decode of the SRAM
 parameter ALLOW_MA=0,
 parameter W_DEPTH=256,                        // total array depth (banks x rows x cols)
 parameter AW_SIZE=7,                           // bits required for row address
 parameter AC_SIZE=1,                           // bits required for column address
 parameter D_SIZE=144                           // bit width of the SRAM
)
(
 `ifdef IVCS_PG
 inout VDD,
 inout VBN,
 inout VCS,
 inout VBP,
 inout VSS,
 `endif

 input notifier,
 input clkA,
 input clkB,
 input cenA,
 input cenB,
 input deepsleep,
 input powergate,
 input [AW_SIZE-1:0] awA,
 input [AC_SIZE-1:0] acA,
 input [AW_SIZE-1:0] awB,
 input [AC_SIZE-1:0] acB,
 input [D_SIZE-1:0] d,
 input [D_SIZE-1:0] bw,
 input t_logic,
 input pipeline,                                                         //Testsite only
 input deepsleep_byp,                                                    //Testsite only
 input ma_sawl,
 input ma_wl,
 input ma_wras,
 input ma_wrasd,
 input ma_tpA,
 input ma_tpB,
 input [1:0] rbe,
 input [7:0] rbf1a,
 input [7:0] rbf0a,
 input [1:0] rwe,
 input [5:0] rwf1a,
 input [5:0] rwf0a,

 output [D_SIZE-1:0] q,
 output [D_SIZE-1:0] obsv_dbw,
 output [1:0] qrb,
 output obsv_ctlA,
 output obsv_ctlB

);

////////////////////////////////////////////////////
// Local parameter / wire / reg definition
////////////////////////////////////////////////////

// local parameters
`ifdef IVCS_MEM_TXS
parameter SETUP_TIME= `IVCS_MEM_TXS;                            // defined setup time for addresses, data, commands, etc.
parameter SETUP_TIMEC= `IVCS_MEM_TXS + 0.01;                            // defined setup time for addresses, data, commands, etc.
`else
parameter SETUP_TIME=0.01;
parameter SETUP_TIMEC=0.02;
`endif
 parameter integer UNUSED_AC=3-AC_SIZE;                                          // there are UNUSED_AC number of unused ac address bits in the macro (add 1 to prevent compile issues)

`ifdef IVCS_SIMPLE_MODEL
 parameter integer DECODE=0;
`else
 parameter integer DECODE=AC_SIZE-1;                                             // =0 for decode2, =1 for decode4
`endif

 parameter integer FW_DEPTH=W_DEPTH/(2 ** DECODE);                               // Generate full array depth based on Decode mode (w/o red.)
 parameter integer FD_SIZE=D_SIZE*(2 ** DECODE);                                 // Generate full data width based on Decode mode (w/o red.)
 parameter integer ROWS_PER_BANK=(W_DEPTH) / (2 ** AC_SIZE);                                 // rows per bank
 parameter integer NUM_SEGS = 0;                                                 // number of segments (0 --> 1 segment, 1 --> 2 segment) break at 160 bitlines

// scan chain length calculations
parameter integer min_size = 0;                                                  // Assume for now the SDP growth is uniform across quadrants for small sizes
parameter integer div_dsize = D_SIZE / 4;                                        // D_SIZE
parameter integer repop_dsize = div_dsize * 4;                                   // the remainder of bits after dividing the data slice into quarters
parameter integer full_remainder = D_SIZE - repop_dsize;                         // the remainder is then allocated bit by bit as per the spec.
                                                                         // for dec 4, the remainder bits allocate in pairs but for all other modes
parameter integer q1_remainder = (full_remainder > 0);                           // the bits are allocated to each quadrant 1 by 1
parameter integer q2_remainder = (full_remainder > 1);                           //    FOR decode4 (DECODE=0)
parameter integer q3_remainder = (full_remainder > 2);                           // quadrants are populated in the following order until all bits are used
parameter integer q4_remainder = (full_remainder > 3);                           //        q0,q0,q2,q2,q1,q1,q3
parameter integer q5_remainder = (full_remainder > 4);                           //    FOR decode8/16/32 (DECODE=1/2/3)
parameter integer q6_remainder = (full_remainder > 5);                           // quadrants are populated in the following order until all bits are used
parameter integer q7_remainder = (full_remainder > 6);                           //        q0,q2,q1,q3,q0,q2,q1

// Calculate the number of bits per quadrant and per segment
parameter integer q0_size = (DECODE == 0) ? 2*div_dsize + q3_remainder + q4_remainder
                                          : 2*div_dsize + q2_remainder + q4_remainder + q6_remainder;
parameter integer q1_size = (DECODE == 0) ? 2*div_dsize + q1_remainder + q2_remainder + q5_remainder + q6_remainder
                                          : 2*div_dsize + q1_remainder + q3_remainder + q5_remainder + q7_remainder;
parameter integer SEG0_SIZE = D_SIZE;                                                                                     // segment 0 size
parameter integer FSEG0_SIZE = SEG0_SIZE*(2 ** DECODE);                                                                              // full segment 0 size

//Assign user controlled parameters to wires so they can be forced as needed
wire TESTCHIP_wire;
wire [31:0] PG_WKUP_CNT_wire, DS_WKUP_CNT_wire;

assign TESTCHIP_wire        = TESTCHIP        ;

assign PG_WKUP_CNT_wire     = PG_WKUP_CNT;
assign DS_WKUP_CNT_wire     = DS_WKUP_CNT;

// internal versions of the inputs after t_bist mux
wire cenAI;
wire cenBI;
wire deepsleepI, deepsleepIg;
wire powergateI, powergateIg;
wire [AW_SIZE-1:0] awAI;
wire [AC_SIZE-1:0] acAI;
wire [AW_SIZE-1:0] awBI;
wire [AC_SIZE-1:0] acBI;
wire [D_SIZE-1:0] dI;
wire [D_SIZE-1:0] bwI;

// Array assumes always 4 b/l (columns) mux'd down based on number of decode bits
reg [FD_SIZE+NUM_SEGS:0] array [FW_DEPTH+4:0];                  // 2 redundant rows in each subarray can be activated and steered to fix any location (all steer together)
                                                                 // each of these 2 redundant rows has 4 columns so the array depth grows by 16*4
wire [FD_SIZE+NUM_SEGS:0] array0;                         // array[0] is handy for debug

reg [FD_SIZE+NUM_SEGS:0] full_dataB, full_bwB;            // full array width data/bw including red.
reg [FD_SIZE+NUM_SEGS:0] full_dataA, full_bwA;            // full array width data/bw including red.
reg [FD_SIZE-1:0] dec_bwBI, dec_dBI;                      // full array width decoded data/bw
reg [FD_SIZE-1:0] dec_bwAI, dec_dAI;                      // full array width decoded data/bw
reg [FD_SIZE+NUM_SEGS:0] bl_mask_shift, bl_mask_noshift;  // full array width bl redundancy masks
wire [7:0] rbfI [1:0];                                    // put red b/l addresses in an array
wire [5:0] rwfI [1:0];                                           // put red w/l addresses in an array
reg RactiveA=0, RactiveB=0;
reg WactiveA=0, WactiveB=0;

//Handle SKIP_POR parm -- make fuse download bits (rb and ma) a don't care if it is set to 1
wire SKIP_POR_wire;
wire [1:0] rbeI;
wire [1:0] rweI;
wire       ma_sawlI;
wire       ma_wlI;
wire       ma_wrasI;
wire       ma_wrasdI;
wire       ma_tpAI;
wire       ma_tpBI;

// internal clocks
wire clkAI;

wire inputXOR, inputsOK;               // flags to indicate known good input states
reg iClkA, oldClkA;
reg iClkB, oldClkB;
`ifdef IVCS_SIMPLE_MODEL
reg [AW_SIZE+AC_SIZE-1:0] full_addrA;  // address after applying redundancy
reg [AW_SIZE+AC_SIZE-1:0] full_addrB;  // address after applying redundancy
`else
reg [AW_SIZE+1:0] full_addrA;  // address after applying redundancy
reg [AW_SIZE+1:0] full_addrB;  // address after applying redundancy
`endif

reg [FD_SIZE+NUM_SEGS:0] undec_dataA;                      // full array width data output prior to decoding including red.
reg [FD_SIZE+NUM_SEGS:0] undec_dataB;                      // full array width data output prior to decoding including red.
reg [D_SIZE-1:0] dataA_l1, dataA_l2, dataA;                // data output bus/latches
reg [D_SIZE-1:0] dataB_l1, dataB_l2, dataB;                // data output bus/latches
reg [1:0] red_dataA_l1, red_dataA_l2, red_dataA;           // data output bus/latches
reg red_wl_mult_hitA;                                      // on a read or write if there's multiple red. w/l hit don't do the write - array set to Xs for that location
reg oob_addressA;                                          // out of bounds address flag
reg [1:0] red_dataB_l1, red_dataB_l2, red_dataB;           // data output bus/latches
reg red_wl_mult_hitB;                                      // on a read or write if there's multiple red. w/l hit don't do the write - array set to Xs for that location
reg oob_addressB;                                          // out of bounds address flag
reg unlockA1=1;                                              // unlock -- needs to be asserted before array is able to be accessed -- requires a single clock rising edge
reg unlockA2=1;                                              // unlock -- needs to be asserted before array is able to be accessed -- requires a single clock rising edge
reg unlockB1=1;                                              // unlock -- needs to be asserted before array is able to be accessed -- requires a single clock rising edge
reg unlockB2=1;                                              // unlock -- needs to be asserted before array is able to be accessed -- requires a single clock rising edge

integer i, j, k, l, m;


////////////////////////////////////////////////////
// BIST mux / scan mux
////////////////////////////////////////////////////

//BIST mux with SETUP_TIME delay added to require setup time > 0
assign #SETUP_TIME cenAI  =  cenA;
assign #SETUP_TIMEC cenBI =  cenB;
assign #SETUP_TIME deepsleepI = deepsleep;
assign #SETUP_TIME powergateI = powergate;
assign #SETUP_TIME awAI = awA;
assign #SETUP_TIME acAI = acA;
assign #SETUP_TIME awBI = awB;
assign #SETUP_TIME acBI = acB;
assign #SETUP_TIME dI   = d;
assign #SETUP_TIME bwI  = bw;

// assign red. w/l and b/l to their internal array equivalent for ease of use
assign SKIP_POR_wire = SKIP_POR;
assign rbeI = (SKIP_POR_wire) ? 0 : rbe;
assign rweI = (SKIP_POR_wire) ? 0 : rwe;
assign ma_sawlI    = (SKIP_POR_wire) ? 0 : ma_sawl;
assign ma_wlI      = (SKIP_POR_wire) ? 0 : ma_wl;
assign ma_wrasI    = (SKIP_POR_wire) ? 0 : ma_wras;
assign ma_wrasdI   = (SKIP_POR_wire) ? 0 : ma_wrasd;
assign ma_tpAI     = (SKIP_POR_wire) ? 0 : ma_tpA;
assign ma_tpBI     = (SKIP_POR_wire) ? 0 : ma_tpB;

assign rbfI[0] = (SKIP_POR_wire) ? 0 : rbf0a;
assign rbfI[1] = (SKIP_POR_wire) ? 0 : rbf1a;
assign rwfI[0] = (SKIP_POR_wire) ? 0 : rwf0a;
assign rwfI[1] = (SKIP_POR_wire) ? 0 : rwf1a;

assign array0 = array[0];                            // just for diagnostics to be able to see array[0] -- keep!!!!

assign clkAI = clkA;
assign clkBI = clkB;

////////////////////////////////////////////////////
// Check inputs, power supplies, timing notifier, etc.
////////////////////////////////////////////////////
parameter PMODE_START_STATE  = 3'b000;
parameter PMODE_ENABLE_STATE = 3'b001;
parameter PMODE_DS_STATE     = 3'b010;
parameter PMODE_PG_STATE     = 3'b011;
parameter PMODE_DSEXIT_STATE = 3'b100;
parameter PMODE_PGEXIT_STATE = 3'b101;
parameter PMODE_ERROR_STATE  = 3'b110;

reg [2:0] n_pModeFSMA, r_pModeFSMA;
reg n_pModeStartA, n_pModeDSexitA, n_pModePGexitA, n_pModeErrorA, n_pModeEnableA;
reg [2:0] n_pModeFSMB, r_pModeFSMB;
reg n_pModeStartB, n_pModeDSexitB, n_pModePGexitB, n_pModeErrorB, n_pModeEnableB;
wire pModeFatalA, pModeFatalB;

reg iOKtrigger = 0;
reg cenTrigger = 0;
reg startTrigger = 0;
reg timingTrigger = 0;
reg voltTrigger = 0;
reg collTrigger=0;
reg cenFatalTrigger = 0;
reg porTrigger = 0;
reg iOKFatalTrigger = 0;
reg MAcenFatalTrigger = 0;
reg MAcenTrigger = 0;
reg rxe_triggerWFatal = 0, rxe_triggerW = 0;
reg rxe_triggerRFatal = 0, rxe_triggerR = 0;
reg rb0_triggerWFatal = 0, rb0_triggerW = 0;
reg rb1_triggerWFatal = 0, rb1_triggerW = 0;
reg rw0_triggerWFatal = 0, rw0_triggerW = 0;
reg rw1_triggerWFatal = 0, rw1_triggerW = 0;
reg rb0_triggerRFatal = 0, rb0_triggerR = 0;
reg rb1_triggerRFatal = 0, rb1_triggerR = 0;
reg rw0_triggerRFatal = 0, rw0_triggerR = 0;
reg rw1_triggerRFatal = 0, rw1_triggerR = 0;
integer cntA = 0;
integer cntB = 0;

wire killArray, pModeGlitchA, pModeGlitchB, killData;

assign killArray = iOKFatalTrigger | timingTrigger | voltTrigger | cenFatalTrigger | ((pModeFatalA | pModeFatalB) & ~TESTCHIP_wire & ~t_logic)
                   | MAcenFatalTrigger | rxe_triggerWFatal | rb0_triggerWFatal | rb1_triggerWFatal | rw0_triggerWFatal | rw1_triggerWFatal;
assign killData = rxe_triggerRFatal | rb0_triggerRFatal | rb1_triggerRFatal | rw0_triggerRFatal | rw1_triggerRFatal;

always @(negedge clkAI or negedge clkBI) begin
 if (unlockA1 || unlockA2 || unlockB1 || unlockB2) begin
  startTrigger     <= 1; //Set it on the first clock and leave it
   if (iOKFatalTrigger)  iOKFatalTrigger  = 0;
   if (timingTrigger)    timingTrigger    = 0;
   if (cenFatalTrigger)  cenFatalTrigger  = 0;
   if (MAcenFatalTrigger) MAcenFatalTrigger = 0;
   if (rxe_triggerWFatal) rxe_triggerWFatal = 0;
   if (rxe_triggerRFatal) rxe_triggerRFatal = 0;
   if (rb0_triggerWFatal) rb0_triggerWFatal = 0;
   if (rb1_triggerWFatal) rb1_triggerWFatal = 0;
   if (rw0_triggerWFatal) rw0_triggerWFatal = 0;
   if (rw1_triggerWFatal) rw1_triggerWFatal = 0;
   if (rb0_triggerRFatal) rb0_triggerRFatal = 0;
   if (rb1_triggerRFatal) rb1_triggerRFatal = 0;
   if (rw0_triggerRFatal) rw0_triggerRFatal = 0;
   if (rw1_triggerRFatal) rw1_triggerRFatal = 0;
 end
end

//Inputs

//MA must be at correct value during read operations
wire readOK;
assign readOK = (TESTCHIP_wire || ((ALLOW_MA || ma_sawlI===0) && (ALLOW_MA || ma_wlI===0) && ma_wrasI===0 && ma_wrasdI===0 && ma_tpBI===0 && (ALLOW_MA || ma_tpAI===0)));

//No x's on inputs (check after SKIP_POR gating such that X's are ignored if SKIP_POR is asserted)
assign inputXOR = ((ma_sawlI^ma_sawlI)===0 && (ma_wlI^ma_wlI)===0 && (ma_tpAI^ma_tpAI)===0 && (ma_tpBI^ma_tpBI)===0 && (ma_wrasI^ma_wrasI)===0 && (ma_wrasdI^ma_wrasdI)===0 &&
                   (rbeI^rbeI)===0 && (rbfI[0]^rbfI[0])===0 && (rbfI[1]^rbfI[1])===0 && (rweI^rweI)===0 && (rwfI[0]^rwfI[0])===0 && (rwfI[1]^rwfI[1])===0 &&
                   (pipeline^pipeline)===0 && (t_logic^t_logic)===0 && (deepsleepI^deepsleepI)===0 && (powergateI^powergateI)===0);
assign inputsOK = (inputXOR === 1'b1);
always @(clkAI or clkBI) begin
 iClkA = (clkAI^clkAI)^(clkAI&~oldClkA);
 iClkB = (clkBI^clkBI)^(clkBI&~oldClkB);
 if ((!inputsOK || (iClkA !== 1'b1 && iClkA !== 1'b0) || (iClkB !== 1'b1 && iClkB !== 1'b0)) && !iOKFatalTrigger && startTrigger) begin
  iOKFatalTrigger = 1;
  if ((MSG_LVL == 1) && !iOKtrigger) begin
   $display ("ERROR: Some memory inputs are unknown at time %t, array contents are now invalid.", $time);  //Only report "x" issue once per clock cycle
   $display ("An error is issued the first time this occurs ONLY.");
   iOKtrigger = 1;
  end
  else if (MSG_LVL > 1) begin
   $display ("ERROR: Some memory inputs are unknown at time %t, array contents are now invalid.", $time);  //Only report "x" issue once per clock cycle
  end
 end
 oldClkA = clkAI;
 oldClkB = clkBI;
end

//Check that MA are stable
always @(ma_sawl or ma_wl or ma_tpA or ma_tpB or ma_wras or ma_wrasd) begin
 if (startTrigger && !MAcenFatalTrigger && ((cenA === 1'b0 || cenB === 1'b0) && !t_logic)) begin
   if (!TESTCHIP_wire) begin
    MAcenFatalTrigger = 1;

    if ((MSG_LVL == 1) && !MAcenTrigger) begin
     $display ("ERROR: Margin Adjust (MA_*) signals are switching when CEN is active at time %t.  This could cause incorrect memory operation, array contents are now invalid.", $time);
     $display ("An error is issued the first time this occurs ONLY.");
     MAcenTrigger = 1;
    end
    else if (MSG_LVL > 1) begin
     $display ("ERROR: Margin Adjust (MA_*) signals are switching when CEN is active at time %t.  This could cause incorrect memory operation, array contents are now invalid.", $time);
    end
   end
   else begin
    if ((MSG_LVL == 2) && !MAcenTrigger) begin
     $display ("WARNING: Margin Adjust (MA_*) signals are switching when CEN is active at time %t.  This could cause incorrect memory operation and should be reviewed.", $time);
     $display ("A warning is issued the first time this occurs ONLY.");
     MAcenTrigger = 1;
    end
    else if (MSG_LVL > 2) begin
     $display ("WARNING: Margin Adjust (MA_*) signals are switching when CEN is active at time %t.  This could cause incorrect memory operation and should be reviewed.", $time);
    end
   end
 end
end

//Check that R* are stable
always @(rbe or rwe) begin
 if (!cenBI) rx_checkW(rxe_triggerWFatal, rxe_triggerW);
 else         rx_checkR(rxe_triggerRFatal, rxe_triggerR);
end
always @(rbf0a) begin
 if (rbe[0]) begin
  if (!cenBI) rx_checkW(rb0_triggerWFatal, rb0_triggerW);
  else         rx_checkR(rb0_triggerRFatal, rb0_triggerR);
 end
end
always @(rbf1a) begin
 if (rbe[1]) begin
  if (!cenBI) rx_checkW(rb1_triggerWFatal, rb1_triggerW);
  else         rx_checkR(rb1_triggerRFatal, rb1_triggerR);
 end
end
always @(rwf0a) begin
 if (rwe[0]) begin
  if (!cenBI) rx_checkW(rw0_triggerWFatal, rw0_triggerW);
  else         rx_checkR(rw0_triggerRFatal, rw0_triggerR);
 end
end
always @(rwf1a) begin
 if (rwe[1]) begin
  if (!cenBI) rx_checkW(rw1_triggerWFatal, rw1_triggerW);
  else         rx_checkR(rw1_triggerRFatal, rw1_triggerR);
 end
end

//Parameters
always @ (SKIP_POR_wire or startTrigger) begin
 if ((SKIP_POR_wire === 1'b1) && startTrigger && !porTrigger && (MSG_LVL > 1)) begin
  $display ("WARNING: Skipping proper memory initialization requirements since SKIP_POR is set at time %t.", $time);
  $display ("Please remember to simulate a true memory init sequence prior to completing a chip design.");
  $display ("A warning is issued the first time this occurs ONLY.");
  porTrigger = 1;
 end

`ifdef IVCS_RELAX_COLL_CHECK
 if (startTrigger && (MSG_LVL > 1) && !collTrigger) begin
  $display ("WARNING: Collision checking is being relaxed.  Cycle based checks have been converted to time based checks. Read/Write operations are now considered complete after a parameterized CLOCK_SEP amount of time (defaults to 1ns).");
  $display ("This may be optimistic depending on operating conditions and could lead to hardware failure--please adjust CLOCK_SEP to match your memory application (worst case access/cycle).");
  $display ("This should only typically be used if clock gating is employed (which makes cycle based checks ineffective/overly pessimistic).");
  collTrigger = 1;
 end
`endif
end

//Power supplies (if present in the model)
`ifdef IVCS_PG
always @ (VDD or VCS or VBN or VBP or VSS or startTrigger) begin
 if (((VDD !== 1'b1) || (VBN === 1'bx) || (VBN === 1'bz) || (VBP === 1'bx) || (VBP === 1'bz) ||
      (VSS !== 1'b0) || (VCS !== 1'b1)) && startTrigger && !voltTrigger) begin
   $display ("ERROR: Voltage supplies are not at correct level at time %t, array contents are now invalid.", $time);
   voltTrigger = 1;
 end
 else if (((VDD === 1'b1) && (VCS === 1'b1) && (VBN !== 1'bx) && (VBN !== 1'bz) && (VBP !== 1'bx) && (VBP !== 1'bz) && (VSS === 1'b0)) && startTrigger && voltTrigger) begin
   voltTrigger = 0; //For memories with an unlock requirement we would also set unlock* back to 0
 end
end
`endif

//Timing check notifier
always @(notifier) begin
 if (startTrigger && !timingTrigger) timingTrigger = 1;   //No messaging (rely on specify messaging for timing issues)
end

//Deepsleep/Powergate check
`ifndef IVCS_PGDS_DELAYCHK
 //Normal no-op clock counting check
always @ (*) begin
 n_pModeStartA = 0;
 n_pModeDSexitA = 0;
 n_pModePGexitA = 0;
 n_pModeErrorA = 0;
 n_pModeEnableA = 0;

 // Allow model to be "powered-up" with DEEPSLEEP asserted
 if (!startTrigger && !t_logic && cenAI && deepsleepI && !powergateI) begin
    n_pModeFSMA = PMODE_DS_STATE;
 end
 // Allow model to be "powered-up" with POWERGATE asserted
 else if (!startTrigger && !t_logic && cenAI && !deepsleepI && powergateI) begin
    n_pModeFSMA = PMODE_PG_STATE;
 end
 else if (!startTrigger || t_logic) begin
  n_pModeFSMA = PMODE_START_STATE;
 end
 else begin
  case (r_pModeFSMA)
   PMODE_START_STATE  : begin
                         n_pModeStartA = 1;
                         if (deepsleepI || powergateI)                 n_pModeFSMA = PMODE_ERROR_STATE;
                         else if ((cenAI) && !deepsleepI && !powergateI)  n_pModeFSMA = PMODE_ENABLE_STATE;
                         else                                          n_pModeFSMA = PMODE_START_STATE;
                        end
   PMODE_ENABLE_STATE : begin
                         n_pModeEnableA = 1;
                         if (!(cenAI) && (deepsleepI || powergateI))      n_pModeFSMA = PMODE_ERROR_STATE;
                         else if ((cenAI) && deepsleepI && !powergateI)   n_pModeFSMA = PMODE_DS_STATE;
                         else if ((cenAI) && !deepsleepI && powergateI)   n_pModeFSMA = PMODE_PG_STATE;
                         else if (!(cenAI) && !deepsleepI && !powergateI) n_pModeFSMA = PMODE_START_STATE;
                         else                                          n_pModeFSMA = PMODE_ENABLE_STATE;
                        end
   PMODE_DS_STATE     : begin
                         if (!(cenAI) || powergateI)                      n_pModeFSMA = PMODE_ERROR_STATE;
                         else if ((cenAI) && !deepsleepI && !powergateI)  n_pModeFSMA = PMODE_DSEXIT_STATE;
                         else                                          n_pModeFSMA = PMODE_DS_STATE;
                        end
   PMODE_PG_STATE     : begin
                         if (!(cenAI) || deepsleepI)                      n_pModeFSMA = PMODE_ERROR_STATE;
                         else if ((cenAI) && !deepsleepI && !powergateI)  n_pModeFSMA = PMODE_PGEXIT_STATE;
                         else                                          n_pModeFSMA = PMODE_PG_STATE;
                        end
   PMODE_DSEXIT_STATE : begin
                         n_pModeDSexitA = 1;
                         if ((cenAI) && !deepsleepI && !powergateI) begin
                          if (cntA < (DS_WKUP_CNT_wire - 1))            n_pModeFSMA = PMODE_DSEXIT_STATE;
                          else                                         n_pModeFSMA = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMA = PMODE_ERROR_STATE;
                        end
   PMODE_PGEXIT_STATE : begin
                         n_pModePGexitA = 1;
                         if ((cenAI) && !deepsleepI && !powergateI) begin
                          if (cntA < (PG_WKUP_CNT_wire - 1))            n_pModeFSMA = PMODE_PGEXIT_STATE;
                          else                                         n_pModeFSMA = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMA = PMODE_ERROR_STATE;
                        end
   PMODE_ERROR_STATE  : begin
                         n_pModeErrorA = 1;
                         if ((cenAI) && !deepsleepI && !powergateI) begin
                          if (cntA < (DS_WKUP_CNT_wire - 1))            n_pModeFSMA = PMODE_ERROR_STATE;
                          else                                         n_pModeFSMA = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMA = PMODE_ERROR_STATE;
                        end
   default            : begin
                         if (deepsleepI || powergateI)                 n_pModeFSMA = PMODE_ERROR_STATE;
                         else if ((cenAI) && !deepsleepI && !powergateI)  n_pModeFSMA = PMODE_ENABLE_STATE;
                         else                                          n_pModeFSMA = PMODE_START_STATE;
                        end
  endcase
 end
end

                     //If ds/pg are high for any point in time during start state then fail OR if they are ever BOTH high then fail
assign pModeGlitchA = ((n_pModeStartA) & (deepsleepI | powergateI)) | (deepsleepI & powergateI);

always @(posedge clkAI or pModeGlitchA) begin
 if (pModeGlitchA) begin
  r_pModeFSMA <= PMODE_ERROR_STATE;
 end
 else begin
  r_pModeFSMA <= n_pModeFSMA;
 end
end

always @ (n_pModeErrorA) begin
 if (n_pModeErrorA && !t_logic && !TESTCHIP_wire) $display ("ERROR: Incorrect DEEPSLEEP / POWERGATE usage at time %t, array contents are now invalid.", $time);
end

always @ (posedge clkAI) begin
 if (n_pModeDSexitA || n_pModePGexitA || n_pModeErrorA) begin
  if ((n_pModeErrorA && ((cenAI) && !deepsleepI && !powergateI)) || n_pModeDSexitA || n_pModePGexitA) begin
   cntA <= cntA + 1;
  end
 end
 else begin
  cntA <= 0;
 end
end

always @ (*) begin
 n_pModeStartB = 0;
 n_pModeDSexitB = 0;
 n_pModePGexitB = 0;
 n_pModeErrorB = 0;
 n_pModeEnableB = 0;

 // Allow model to be "powered-up" with DEEPSLEEP asserted
 if (!startTrigger && !t_logic && cenBI && deepsleepI && !powergateI) begin
    n_pModeFSMB = PMODE_DS_STATE;
 end
 // Allow model to be "powered-up" with POWERGATE asserted
 else if (!startTrigger && !t_logic && cenBI && !deepsleepI && powergateI) begin
    n_pModeFSMB = PMODE_PG_STATE;
 end
 else if (!startTrigger || t_logic) begin
  n_pModeFSMB = PMODE_START_STATE;
 end
 else begin
  case (r_pModeFSMB)
   PMODE_START_STATE  : begin
                         n_pModeStartB = 1;
                         if (deepsleepI || powergateI)                 n_pModeFSMB = PMODE_ERROR_STATE;
                         else if ((cenBI) && !deepsleepI && !powergateI)  n_pModeFSMB = PMODE_ENABLE_STATE;
                         else                                          n_pModeFSMB = PMODE_START_STATE;
                        end
   PMODE_ENABLE_STATE : begin
                         n_pModeEnableB = 1;
                         if (!(cenBI) && (deepsleepI || powergateI))      n_pModeFSMB = PMODE_ERROR_STATE;
                         else if ((cenBI) && deepsleepI && !powergateI)   n_pModeFSMB = PMODE_DS_STATE;
                         else if ((cenBI) && !deepsleepI && powergateI)   n_pModeFSMB = PMODE_PG_STATE;
                         else if (!(cenBI) && !deepsleepI && !powergateI) n_pModeFSMB = PMODE_START_STATE;
                         else                                          n_pModeFSMB = PMODE_ENABLE_STATE;
                        end
   PMODE_DS_STATE     : begin
                         if (!(cenBI) || powergateI)                      n_pModeFSMB = PMODE_ERROR_STATE;
                         else if ((cenBI) && !deepsleepI && !powergateI)  n_pModeFSMB = PMODE_DSEXIT_STATE;
                         else                                          n_pModeFSMB = PMODE_DS_STATE;
                        end
   PMODE_PG_STATE     : begin
                         if (!(cenBI) || deepsleepI)                      n_pModeFSMB = PMODE_ERROR_STATE;
                         else if ((cenBI) && !deepsleepI && !powergateI)  n_pModeFSMB = PMODE_PGEXIT_STATE;
                         else                                          n_pModeFSMB = PMODE_PG_STATE;
                        end
   PMODE_DSEXIT_STATE : begin
                         n_pModeDSexitB = 1;
                         if ((cenBI) && !deepsleepI && !powergateI) begin
                          if (cntB < (DS_WKUP_CNT_wire - 1))            n_pModeFSMB = PMODE_DSEXIT_STATE;
                          else                                         n_pModeFSMB = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMB = PMODE_ERROR_STATE;
                        end
   PMODE_PGEXIT_STATE : begin
                         n_pModePGexitB = 1;
                         if ((cenBI) && !deepsleepI && !powergateI) begin
                          if (cntB < (PG_WKUP_CNT_wire - 1))            n_pModeFSMB = PMODE_PGEXIT_STATE;
                          else                                         n_pModeFSMB = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMB = PMODE_ERROR_STATE;
                        end
   PMODE_ERROR_STATE  : begin
                         n_pModeErrorB = 1;
                         if ((cenBI) && !deepsleepI && !powergateI) begin
                          if (cntB < (DS_WKUP_CNT_wire - 1))            n_pModeFSMB = PMODE_ERROR_STATE;
                          else                                         n_pModeFSMB = PMODE_START_STATE;
                         end
                         else                                          n_pModeFSMB = PMODE_ERROR_STATE;
                        end
   default            : begin
                         if (deepsleepI || powergateI)                 n_pModeFSMB = PMODE_ERROR_STATE;
                         else if ((cenBI) && !deepsleepI && !powergateI)  n_pModeFSMB = PMODE_ENABLE_STATE;
                         else                                          n_pModeFSMB = PMODE_START_STATE;
                        end
  endcase
 end
end

                     //If ds/pg are high for any point in time during start state then fail OR if they are ever BOTH high then fail
assign pModeGlitchB = ((n_pModeStartB) & (deepsleepI | powergateI)) | (deepsleepI & powergateI);

always @(posedge clkBI or pModeGlitchB) begin
 if (pModeGlitchB) begin
  r_pModeFSMB <= PMODE_ERROR_STATE;
 end
 else begin
  r_pModeFSMB <= n_pModeFSMB;
 end
end

always @ (n_pModeErrorB) begin
 if (n_pModeErrorB && !t_logic && !TESTCHIP_wire) $display ("ERROR: Incorrect DEEPSLEEP / POWERGATE usage at time %t, array contents are now invalid.", $time);
end

always @ (posedge clkBI) begin
 if (n_pModeDSexitB || n_pModePGexitB || n_pModeErrorB) begin
  if ((n_pModeErrorB && ((cenBI) && !deepsleepI && !powergateI)) || n_pModeDSexitB || n_pModePGexitB) begin
   cntB <= cntB + 1;
  end
 end
 else begin
  cntB <= 0;
 end
end

assign pModeFatalA = n_pModeErrorA;
assign pModeFatalB = n_pModeErrorB;

`else
 //Method using delays (handles case where memory clock is gated)

wire pModeErrorA, pModeErrorB;
  //CEN delay after exiting Powergate mode
`ifdef IVCS_MEM_TPGH
parameter PG_TO_CEN = `IVCS_MEM_TPGH;
`else
parameter PG_TO_CEN = 40;
`endif
  //CEN delay after exiting Deepsleep mode
`ifdef IVCS_MEM_TDSH
parameter DS_TO_CEN = `IVCS_MEM_TDSH;
`else
parameter DS_TO_CEN = 200;
`endif

  //CEN delay to entering Powergate or Deepsleep is 1 clock cycle
`ifdef IVCS_MEM_TCYC
parameter CEN_TO_PMODE= `IVCS_MEM_TCYC;
`else
parameter CEN_TO_PMODE= 10;
`endif

assign pModeGlitch = (deepsleepI & powergateI);

assign #CEN_TO_PMODE cenAD =cenAI;
assign #CEN_TO_PMODE cenBD =cenBI;
assign #PG_TO_CEN powergateD = powergateI;
assign #DS_TO_CEN deepsleepD = deepsleepI;

assign pModeErrorA = (~cenAD & powergateI) | ((powergateD===1'b1) & ~cenAI) | (powergateI & ~cenAI) |
                     (~cenAD & deepsleepI) | ((deepsleepD===1'b1) & ~cenAI) | (deepsleepI & ~cenAI);
assign pModeErrorB = (~cenBD & powergateI) | ((powergateD===1'b1) & ~cenBI) | (powergateI & ~cenBI) |
                     (~cenBD & deepsleepI) | ((deepsleepD===1'b1) & ~cenBI) | (deepsleepI & ~cenBI);

always @ (pModeErrorA or pModeErrorB or pModeGlitch) begin
 if ((pModeErrorA || pModeErrorB || pModeGlitch) && !t_logic && !TESTCHIP_wire) $display ("ERROR: Incorrect DEEPSLEEP / POWERGATE usage at time %t, array contents are now invalid.", $time);
end

assign pModeFatalA = pModeErrorA | pModeGlitch;
assign pModeFatalB = pModeErrorB | pModeGlitch;
`endif


////////////////////////////////////////////////////
// Array read/write modeling
////////////////////////////////////////////////////

`ifdef IVCS_INIT_MEM
 integer z;
 wire IVCS_INIT_MEM_wire;

 initial begin
  #0.1;
  for (z=0;z<FW_DEPTH+32;z=z+1) begin array[z] <= {FD_SIZE+2{1'b0}}; end
  dataA <= {FD_SIZE+2{1'b0}};
  dataB <= {FD_SIZE+2{1'b0}};
 end

 always @ (IVCS_INIT_MEM_wire) begin
  for (z=0;z<FW_DEPTH+32;z=z+1) begin array[z] <= {FD_SIZE+2{1'b0}}; end
  dataA <= {FD_SIZE+2{1'b0}};
  dataB <= {FD_SIZE+2{1'b0}};
 end
`endif

//Logic added to help with collision checking
reg [AW_SIZE+AC_SIZE-1:0] pAA, pAB;
reg collision=0;
wire killDataColl;
reg csepB=0;
reg csepA=0;
wire realActiveW, realActiveR;

always @(posedge clkBI) begin
 csepB = 0;
 #CLOCK_SEP;
 csepB = 1;
end
always @(posedge clkAI) begin
 csepA = 0;
 #CLOCK_SEP;
 csepA = 1;
end
`ifdef IVCS_RELAX_COLL_CHECK
  assign realActiveW = WactiveB & ~csepB;
  assign realActiveR = RactiveA & ~csepA;
`else
  assign realActiveW = WactiveB;
  assign realActiveR = RactiveA;
`endif

always @(posedge clkBI) begin
 if (!t_logic && !powergateI && !cenBI && (unlockB1 || unlockB2)) begin
  pAB = {awBI,acBI};
 end
end

always @(posedge clkAI) begin
 if (!t_logic && !powergateI && !cenAI && (unlockA1 || unlockA2)) begin
  pAA = {awAI,acAI};
 end
end

assign killDataColl = (pAB == pAA) & realActiveR & realActiveW;
always @(killDataColl) begin
 #0.1;
 if (killDataColl && !collision) begin
  if (MSG_LVL > 1) $display("WARNING: Read/Write address collision (Row/Col = %d/%d)!!!  Read data is undefined.", awAI,acAI);
 end
end

////////////////// A PORT ///////////////////////////
// Begin Read/Write Operational Logic
//Array write/read operations are positive edge triggered off of slightly delayed clock to mimic actual array function
assign deepsleepIg = deepsleepI & ~t_logic;
assign powergateIg = powergateI & ~t_logic;
always @(posedge clkAI or posedge killArray or deepsleepIg or powergateIg) begin
 RactiveA=0;
 collision = 0;
 #0;
 if (t_logic) begin
    dataA = {D_SIZE{awAI[1:0]}};
 end
 if (deepsleepI && !killArray && !t_logic) begin
    for (i=0;i<FW_DEPTH/2+4;i=i+1) begin array[i] <= {FD_SIZE+2{1'bx}}; end             // retain previous data on deepsleep but X array unless in logic test
 end
 else if (killArray) begin
    for (i=0;i<FW_DEPTH/2+4;i=i+1) begin array[i] <= {FD_SIZE+2{1'bx}}; end             // otherwise, on junk inputs clear array and data
 end
 else if (!killArray && !t_logic && !cenAI && !powergateI && (unlockA1 || unlockA2)) begin
       oob_addressA = Out_Of_Bounds(awAI);                                                    // check to see if row address is out of bounds

       if (oob_addressA || !readOK) begin
          if ((MSG_LVL > 1) && oob_addressA) $display("WARNING: Read address port A (Row/Col = %d/%d) is out of bounds for this array size!!!", awAI,acAI);
          else if (MSG_LVL > 1)                              $display("WARNING: MA inputs at incorrect values!!!");
          if (oob_addressA && readOK) dataA = {D_SIZE{1'b0}}; else dataA = {D_SIZE{1'bx}};
       end
       else begin
          RactiveA=1;
          if ((pAA == pAB) && realActiveW) begin
            collision = 1;
            if (MSG_LVL > 1) $display("WARNING: Read/Write address collision (Row/Col = %d/%d)!!!  Read data is undefined.", awAI,acAI);
            dataA = {D_SIZE{1'bx}};
          end
          else begin
          `ifdef IVCS_SIMPLE_MODEL
            full_addrA = {awAI,acAI};
          `else
            full_addrA = {awAI,acAI[0]};
          `endif
            full_dataA = array[full_addrA];

            Extract_Decode_Data(full_dataA,acAI,dataA,red_dataA);
          end
       end
 end
end
// End Read/Write Operational Logic

////////////////// B PORT ///////////////////////////
// Begin Read/Write Operational Logic
//Array write/read operations are positive edge triggered off of slightly delayed clock to mimic actual array function
always @(posedge clkBI or posedge killArray or deepsleepIg or powergateIg) begin
 WactiveB=0;
 #0;
 if (deepsleepI && !killArray && !t_logic) begin
    for (i=0;i<FW_DEPTH/2+4;i=i+1) begin array[i] <= {FD_SIZE+2{1'bx}}; end             // retain previous data on deepsleep but X array unless in logic test
 end
 else if (killArray) begin
    for (i=0;i<FW_DEPTH/2+4;i=i+1) begin array[i] <= {FD_SIZE+2{1'bx}}; end             // otherwise, on junk inputs clear array and data
 end
 else if (!t_logic && !cenBI && !powergateI && (unlockB1 || unlockB2)) begin
       oob_addressB = Out_Of_Bounds(awBI);                                                    // check to see if row address is out of bounds

       if (oob_addressB && (MSG_LVL > 1)) $display("WARNING: Write address port B (Row/Col = %d/%d) is out of bounds for this array size!!!",awBI,acBI);
       else if (!oob_addressB) begin
          WactiveB=1;
          Gen_Decode_Data(dI,bwI,acBI,dec_dBI,dec_bwBI);
        `ifdef IVCS_SIMPLE_MODEL
          full_addrB = {awBI,acBI};
        `else
          full_addrB = {awBI,acBI[0]};
        `endif

          full_bwB[FSEG0_SIZE:0]   = {1'b0,dec_bwBI[FSEG0_SIZE-1:0]};
          full_dataB[FSEG0_SIZE:0] = {1'bx,dec_dBI[FSEG0_SIZE-1:0]};
          if (NUM_SEGS) begin
            full_bwB[FD_SIZE-1:NUM_SEGS*FSEG0_SIZE]   = {1'b0,dec_bwBI[FD_SIZE-1:NUM_SEGS*FSEG0_SIZE]};
            full_dataB[FD_SIZE-1:NUM_SEGS*FSEG0_SIZE] = {1'bx,dec_dBI[FD_SIZE-1:NUM_SEGS*FSEG0_SIZE]};
          end

          array[full_addrB] <= (full_bwB & full_dataB) | (~full_bwB & array[full_addrB]);
       end
 end
end
// End Read/Write Operational Logic

////////////////////////////////////////////////////
// Output latch modeling
////////////////////////////////////////////////////
//Read output latch -- while clkI is asserted the data outputs will update during a read
//Assumes last read data is held during DEEPSLEEP/POWERGATE regardless of whether CEN is asserted (which is correct--gating within memory protects output)
`ifndef IVCS_RELAX_COLL_CHECK
always @(clkAI or posedge killArray or posedge killData or killDataColl or dataA) begin
`else
always @(clkAI or posedge killArray or posedge killData or posedge killDataColl or dataA) begin
`endif
 if (killData || killArray || killDataColl) begin
    dataA_l1 <= {D_SIZE{1'bx}};
 end
 else if (t_logic || ((!deepsleepI && !powergateI) && !cenAI && clkAI)) begin
    dataA_l1 <= dataA;
 end
end

//Output pipeline latch that would be used in non-flowthru memories
always @ (posedge clkA) begin
  dataA_l2 <= dataA_l1;
end

// Generate Q/QRB outputs
assign qrb = 0;
assign q = (pipeline) ? dataA_l2 : dataA_l1;
assign obsv_ctlA = ~t_logic | (&(~awAI) & (&acAI) & ~cenAI & ~deepsleepI & ~powergateI);
assign obsv_ctlB = ~t_logic | (&(~awBI) & (&acBI) & ~cenBI);
assign obsv_dbw  = t_logic ? dI & bwI : {D_SIZE{1'b1}} ;

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
// Supporting functions and tasks
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
function Out_Of_Bounds;
input [AW_SIZE-1:0] row;

begin
   Out_Of_Bounds = (row >= ROWS_PER_BANK);
end
endfunction
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
task Extract_Decode_Data;
input [FD_SIZE+NUM_SEGS:0] data_in;
input [AC_SIZE-1:0] column;
output [D_SIZE-1:0] dec_data;
output [1:0] red_data;

reg [FD_SIZE-1:0] temp_data;
integer x;

begin
  red_data = 0;

  temp_data = NUM_SEGS ? {data_in[FD_SIZE-1:NUM_SEGS*FSEG0_SIZE], data_in[FSEG0_SIZE-1:0]} : data_in[FSEG0_SIZE-1:0];

  if (DECODE == 0) dec_data = temp_data;
  else if (DECODE == 1) begin
     for (x=0;x<FD_SIZE;x=x+2) dec_data[x/2] = temp_data[x+column[1]];
  end

end
endtask
//
//
//////////////Generate Data and Mask based on decode option and column selected///////////////////////
task Gen_Decode_Data;
input [D_SIZE-1:0] data_in;
input [D_SIZE-1:0] mask_in;
input [AC_SIZE-1:0] column;
output [FD_SIZE-1:0] fdata_out;
output [FD_SIZE-1:0] mask_out;


integer x;
reg [FD_SIZE-1:0] dec_mask;

begin
    if (DECODE == 0) begin
        mask_out = {FD_SIZE{1'b1}} & mask_in;    // enable all bits for decode 2
        fdata_out = data_in;
    end
    else if (DECODE == 1) begin                  // enable 1/2 of bits for decode 4
        if (column[1] == 1'b0) dec_mask = {D_SIZE{2'b01}};
        else dec_mask = {D_SIZE{2'b10}};
        for (x=0;x<FD_SIZE;x=x+2) begin
           fdata_out[x +:2] = {2{data_in[x/2]}};
           mask_out[x +:2] = dec_mask[x +:2] & {2{mask_in[x/2]}};
        end
    end
end
endtask

//////////////////////////////////////////////////////////////////////////////////////////
task rx_checkW;
output triggerFatal;
output trigger;

begin
 triggerFatal=0; trigger = 0;
 if (startTrigger && !triggerFatal && ((cenB===1'b0) && !t_logic)) begin
   triggerFatal = 1;
   if ((MSG_LVL == 1) && !trigger) begin
    $display ("ERROR: Redundant Streering (RB* or RW*) signals are switching when a write is active at time %t.  This could cause incorrect memory operation, array contents are now invalid.", $time);
    $display ("An error is issued the first time this occurs ONLY.");
    trigger = 1;
   end
   else if (MSG_LVL > 1) begin
    $display ("ERROR: Redundant Streering (RB* or RW*) signals are switching when a write is active at time %t.  This could cause incorrect memory operation, array contents are now invalid.", $time);
   end
  end
 end
endtask

//////////////////////////////////////////////////////////////////////////////////////////
task rx_checkR;
output triggerFatal;
output trigger;

begin
 triggerFatal=0; trigger = 0;
 if (startTrigger && !triggerFatal && ((cenA===1'b0) && !t_logic)) begin
   triggerFatal = 1;
   if ((MSG_LVL == 1) && !trigger) begin
    $display ("ERROR: Redundant Streering (RB* or RW*) signals are switching when a read/search is active at time %t.  This could cause incorrect memory operation, array outputs are now invalid.", $time);
    $display ("An error is issued the first time this occurs ONLY.");
    trigger = 1;
   end
   else if (MSG_LVL > 1) begin
    $display ("ERROR: Redundant Streering (RB* or RW*) signals are switching when a read/search is active at time %t.  This could cause incorrect memory operation, array outputs are now invalid.", $time);
   end
  end
 end
endtask

endmodule
