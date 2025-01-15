// Copyright 2021 QuickLogic
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// `include "pulp_soc_defines.svh"
module top (
    input logic [3:0] CLK,
    input logic [3:0] RST_ni,
    input logic lint_REQ,
    input logic lint_WEN,

    input logic [19:0] lint_ADDR,  //PADDR,
    input logic [31:0] lint_WDATA,  //PWDATA,
    input logic [3:0] lint_BE,
    output logic lint_VALID,
    output logic lint_GNT,  //PREADY, PSLVERR,
    output logic [31:0] lint_RDATA,  //PRDATA,

    output logic [42:0] fpgaio_out,
    output logic [42:0] fpgaio_oe,
    input  logic [42:0] fpgaio_in,
    output logic [15:0] events_o,
    input  logic [31:0] control_in,
    output logic [31:0] status_out,
    output logic [ 7:0] version,


    output logic [19:0] tcdm_addr_p0,
    input logic [31:0] tcdm_rdata_p0,
    input logic tcdm_valid_p0,
    input logic tcdm_gnt_p0,
    input logic tcdm_fmo_p0,
    output logic [31:0] tcdm_wdata_p0,
    output logic [3:0] tcdm_be_p0,
    output logic tcdm_wen_p0,
    output logic tcdm_req_p0,

    output logic PSEL,
    output logic [8:0] PADDR,
    output logic PWRITE,
    output logic PENABLE,
    output logic [31:0] PWDATA,
    input logic [31:0] PRDATA,
    input logic PREADY


);



  logic [15:0] i_events;
  logic [79:0] ifpga_out, ifpga_oe;
  logic [31:0] tcdm_result_p0, tcdm_result_p1, tcdm_result_p2, tcdm_result_p3;
  logic [2:0] cnt5, cnt4, cnt3, cnt2, cnt1;

  logic saved_REQ;
  logic [3:0] l_ADDR;
  logic launch_p0;
  logic [3:0] p0_fsm;
  logic [7:0] p0_cnt;
  logic [7:0] delay;
  logic [31:0] blinker;
  logic [30:0] blink_cnt;
  logic blink;


  logic [31:0] last_control;

  enum bit [2:0] {
    IDLE,
    ENABLE,
    READ,
    WRITE,
    READ_WAIT,
    READ_DONE,
    TFL_READ,
    TFL_WRITE
  } apb_fsm;


  assign version = 8'h55;  // defpins for versin register in soc_cntrl
  always @(posedge CLK[0]) status_out <= ~control_in;  // Loop around logic for test

  assign fpgaio_out = (ifpga_out ^ {64'h0, blink, 14'h0});
  assign fpgaio_oe  = ifpga_oe;
  assign events_o   = i_events;


  always @(posedge CLK[0] or negedge RST_ni[0]) begin
    if (RST_ni[0] == 0) begin
      lint_GNT <= 0;
      lint_VALID <= 0;
      lint_RDATA <= '0;
      l_ADDR <= '0;
      saved_REQ <= 1'b0;
      ifpga_out <= 'h0;
      ifpga_oe  <= 'h0;
      apb_fsm <= IDLE;
      PSEL <= 0;
      PWRITE <= 0;
      PENABLE <= 0;
      PWDATA <= 'h0;
      PADDR <= 'h0;

    end else begin
      if (blinker[31] == 1'b1) begin
        if (blink_cnt == 30'h0) begin
          blink <= ~blink;
          blink_cnt <= blinker[30:0];
        end else begin
          blink_cnt <= blink_cnt - 1;
        end
      end
      last_control <= control_in;
      saved_REQ <= lint_REQ;
      case (apb_fsm)
        IDLE: begin
          lint_GNT   <= 0;
          lint_VALID <= lint_GNT;
          if (lint_REQ & !saved_REQ & !lint_GNT) begin
            if (lint_ADDR[19:9] == 11'h0) begin  // send to TFL
              PWDATA <= lint_WDATA;
              PADDR  <= lint_ADDR[8:0];
              PWRITE <= ~lint_WEN;
              PSEL   <= 1'b1;
              if (lint_WEN == 0) apb_fsm <= TFL_WRITE;
              else apb_fsm <= TFL_READ;
            end else if (lint_WEN == 0) begin
              lint_GNT <= 1;
              apb_fsm  <= WRITE;
            end else begin
              apb_fsm <= READ;
            end
          end  // if (lint_REQ & !saved_REQ & !lint_GNT)
        end  // case: IDLE

        TFL_WRITE: begin  //write
          PENABLE <= 1'b1;
          if (PREADY == 1'b1) begin
            lint_GNT <= 1;
            apb_fsm <= IDLE;
            PSEL <= 1'b0;
            PENABLE <= 1'b0;
          end
        end
        TFL_READ: begin  //read
          PENABLE <= 1'b1;
          if (PREADY == 1'b1) begin
            lint_RDATA <= PRDATA;
            lint_GNT <= 1;
            apb_fsm <= IDLE;
            PSEL <= 1'b0;
            PENABLE <= 1'b0;
          end
        end
        WRITE: begin
          lint_VALID <= lint_GNT;
          lint_GNT <= 0;
          apb_fsm <= IDLE;
          casex (lint_ADDR)
            20'h250: ifpga_oe <= lint_WDATA;
            20'h250: ifpga_out <= lint_WDATA;
            20'h270: blinker <= lint_WDATA;
          endcase  // case (lint_ADDR)
        end
        READ: begin
          apb_fsm <= READ_WAIT;
          casex (lint_ADDR)
            20'h270: lint_RDATA <= blinker;
            20'h260: lint_RDATA <= fpgaio_out;
            20'h250: lint_RDATA <= ifpga_oe[31:0];
          endcase  // case (lint_ADDR)
        end
        READ_WAIT: begin
          lint_GNT <= 1;
          apb_fsm  <= IDLE;
        end

        default: apb_fsm <= IDLE;
      endcase  // case (apb_fsm)
    end  // else: !if(RST_ni[0] == 0)
  end  // always @ (posedge CLK[0] or negedge RST_ni[0])

endmodule  //
