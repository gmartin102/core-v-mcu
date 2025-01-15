`timescale 1ns / 10ps
module FCB_pcb #(
    parameter PL_DATA_WIDTH = 36,
    parameter PL_ADDR_WIDTH = 32,
    parameter ROWS          = 10'h2,
    parameter COLUMNS       = 10'h2,
    parameter RAM_SIZE      = 16'd1024,
    parameter R_OFFSET      = 10'd1,
    parameter C_OFFSET      = 10'd2,
    parameter R_STRIDE      = 10'd3,
    parameter C_STRIDE      = 10'd2
) (
    input  wire                     pclk_i,
    input  wire                     preset_ni,
    input       [             15:0] paddr_i,
    input  wire [             31:0] pwdata_i,
    output wire [             31:0] prdata_o,
    output wire                     pready_o,
    output wire                     pslverr_o,
    input  wire                     psel_i,
    input  wire                     penable_i,
    input  wire                     pwrite_i,
    input  wire [PL_DATA_WIDTH-1:0] PL_DATA_IN,

    output [PL_DATA_WIDTH-1:0] PL_DATA_OUT,
    output [PL_ADDR_WIDTH-1:0] PL_ADDR_OUT,
    output [              1:0] PL_WEN,
    output                     PL_ENA,
    output                     PL_CLK,
    output                     PL_REN,
    output                     PL_INIT
);

  localparam CK2Q = 0.01;

  localparam PL_CTL = 16'h0040;
  localparam PL_STAT = 16'h0044;
  localparam PL_CFG = 16'h0048;
  localparam PL_SELECT = 16'h004C;
  localparam PL_EXTRA = 16'h0054;
  localparam PL_ROW = 16'h0058;
  localparam PL_COLUMN = 16'h005C;
  localparam PL_TARG = 16'h0060;
  localparam PL_DATA = 16'h0064;
  localparam PL_RAM = 16'b?1??_????_????_??00;


  localparam FSM_PL_IDLE = 4'd0;
  localparam FSM_PL_CALIB1 = 4'd1;
  localparam FSM_PL_CALIB2 = 4'd2;
  localparam FSM_PL_CALIB3 = 4'd3;
  localparam FSM_PL_READ = 4'd4;
  localparam FSM_PL_WRITE = 4'd5;
  localparam FSM_PL_CYC1 = 4'd6;
  localparam FSM_PL_CYC2 = 4'd7;
  localparam FSM_PL_RDONE = 4'd8;
  localparam FSM_PL_WDONE = 4'd9;
  reg [3:0] fsm_pl;

  localparam FSM_IDLE = 2'd0;
  localparam FSM_READ = 2'd1;
  localparam FSM_WRITE = 2'd2;
  localparam FSM_DONE = 2'd3;
  reg [ 1:0] apb_fsm;

  reg [ 3:0] bist_fsm;
  reg [31:0] bist_addr;
  reg [35:0] bist_data;
  reg [ 1:0] bist_wen;
  reg        bist_ren;
  reg        bist_ena;
  reg        bist_clk;
  reg        bist_running;
  reg        bist_init;
  reg        bist_fail;
  reg        bist_pass;
  reg        bist_abort;


  reg [9:0] PL_R_OFFSET, PL_R_STRIDE;
  reg [9:0] PL_C_OFFSET, PL_C_STRIDE;
  reg PL_WR_START;
  reg PL_RD_START;


  reg [31:0] reg_PL_CTL;
  wire PL_CTL_ENABLE = reg_PL_CTL[0];
  wire [1:0] PL_CTL_SKEW = reg_PL_CTL[3:2];
  wire PL_CTL_A_INC = reg_PL_CTL[4];
  wire PL_CTL_S_INC = reg_PL_CTL[5];
  wire PL_CTL_PARITY = reg_PL_CTL[6];
  wire PL_CTL_EVEN = reg_PL_CTL[7];
  wire [5:0] PL_CTL_RWAIT = reg_PL_CTL[13:8];
  wire [1:0] PL_CTL_SPLIT = reg_PL_CTL[15:14];
  wire PL_CTL_FAIL = reg_PL_CTL[28] | bist_fail;
  wire PL_CTL_PASS = reg_PL_CTL[29] | bist_pass;
  wire PL_CTL_MBIST_START = reg_PL_CTL[30];
  wire PL_CTL_MBIST = reg_PL_CTL[31];
  wire [31:0] rd_PL_CTL = {
    PL_CTL_MBIST,
    PL_CTL_MBIST_START,
    PL_CTL_PASS,
    PL_CTL_FAIL,
    12'h0,
    PL_CTL_SPLIT[1:0],
    PL_CTL_RWAIT[5:0],
    PL_CTL_EVEN,
    PL_CTL_PARITY,
    PL_CTL_S_INC,
    PL_CTL_A_INC,
    PL_CTL_SKEW[1:0],
    1'b0,
    PL_CTL_ENABLE
  };

  reg PL_CAL_START;
  reg PL_CAL_DONE;
  reg [5:0] PL_CAL_WAIT;
  wire [31:0] rd_PL_STAT = {17'h0, PL_CAL_WAIT, 6'h0, PL_CAL_DONE, PL_CAL_START};

  reg [31:0] reg_PL_SELECT;
  reg [9:0] PL_SEL_COL;
  reg [9:0] PL_SEL_ROW;
  reg [11:0] PL_SEL_ADDR;
  wire [31:0] rd_PL_SELECT = {PL_SEL_COL, PL_SEL_ROW, PL_SEL_ADDR};
  reg load_PL_SELECT;

  reg [31:0] reg_PL_DATA;
  reg [31:0] prdata;
  reg pslverr;
  reg pready;




  reg [PL_DATA_WIDTH-1:0] pl_wdata;
  reg [PL_ADDR_WIDTH-1:0] pl_addr;
  reg [5:0] cycle_count;
  reg [1:0] skew;
  reg pl_ren;
  reg [1:0] pl_wen;
  reg pl_ena;
  reg pl_clk;



  reg [3:0] reg_PL_EXTRA;
  reg [3:0] rd_PL_EXTRA;

  reg [3:0] parity;


  assign pready_o = pready & penable_i;

  assign pslverr_o = pslverr;
  assign prdata_o = prdata;

  assign PL_DATA_OUT = bist_running ? bist_data : pl_wdata;
  assign PL_ADDR_OUT = bist_running ? bist_addr : pl_addr;
  assign PL_ENA = bist_running ? bist_ena : pl_ena;
  assign PL_CLK = bist_running ? bist_clk : pl_clk;
  assign PL_REN = bist_running ? bist_ren : pl_ren;
  assign PL_WEN = bist_running ? bist_wen : pl_wen;
  assign PL_INIT = (PL_CTL_MBIST | bist_init);

  always @(*) begin  // parity calulation
    if (PL_CTL_PARITY == 1'b1) begin  // parity on
      parity[0] = PL_CTL_EVEN ^ (^pwdata_i[7:0]);
      parity[1] = PL_CTL_EVEN ^ (^pwdata_i[15:8]);
      parity[2] = PL_CTL_EVEN ^ (^pwdata_i[23:16]);
      parity[3] = PL_CTL_EVEN ^ (^pwdata_i[31:24]);
    end else begin
      parity[3:0] = reg_PL_EXTRA;
    end
  end


  always @(posedge pclk_i or negedge preset_ni) begin : CONFIGURATION
    if (preset_ni == 1'b0) begin
      apb_fsm <= FSM_IDLE;
      prdata <= 32'h0;
      pslverr <= 1'b0;
      pready <= 1'b0;
      PL_CAL_START <= 1'b0;
      load_PL_SELECT <= 1'b0;
      reg_PL_CTL <= 32'h0;
      reg_PL_EXTRA <= 4'h0;
      rd_PL_EXTRA <= 4'h0;
      PL_R_OFFSET <= R_OFFSET;
      PL_R_STRIDE <= R_STRIDE;
      PL_C_OFFSET <= C_OFFSET;
      PL_C_STRIDE <= C_STRIDE;
      PL_WR_START <= 1'b0;
      PL_RD_START <= 1'b0;
      reg_PL_DATA <= 32'h0;
      reg_PL_SELECT <= 32'h0;
    end // if (preset_ni == 1'b0)
      else begin
      pready  <= 1'b0;
      pslverr <= 1'b0;
      if (PL_CAL_DONE == 1'b1) PL_CAL_START <= 1'b0;
      if (PL_WR_START == 1'b1) PL_WR_START <= 1'b0;
      if (PL_RD_START == 1'b1) PL_RD_START <= 1'b0;
      load_PL_SELECT <= 1'b0;

      if (bist_fsm == 4'd11) reg_PL_CTL[30] <= 1'b0;
      reg_PL_CTL[29] <= PL_CTL_PASS;
      reg_PL_CTL[28] <= PL_CTL_FAIL;

      case (apb_fsm)
        FSM_DONE: apb_fsm <= FSM_IDLE;
        FSM_IDLE: begin
          prdata <= 32'h0;
          if (psel_i & penable_i & pwrite_i) apb_fsm <= FSM_WRITE;
          else if (psel_i & penable_i) apb_fsm <= FSM_READ;
        end
        FSM_WRITE: begin
          if (penable_i == 1'b1) apb_fsm <= FSM_DONE;
          pready <= 1'b1;
          casez (paddr_i)
            PL_CTL:   reg_PL_CTL <= pwdata_i;
            PL_STAT:  PL_CAL_START <= pwdata_i[0];
            PL_SELECT: begin
              load_PL_SELECT <= 1'b1;
              reg_PL_SELECT  <= pwdata_i;
            end
            PL_EXTRA: reg_PL_EXTRA <= pwdata_i[3:0];
            PL_ROW: begin
              PL_R_OFFSET <= #CK2Q pwdata_i[9:0];
              PL_R_STRIDE <= #CK2Q pwdata_i[25:16];
            end
            PL_COLUMN: begin
              PL_C_OFFSET <= #CK2Q pwdata_i[9:0];
              PL_C_STRIDE <= #CK2Q pwdata_i[25:16];
            end
            PL_TARG: begin
              if (PL_CTL_ENABLE == 1'b1) begin
                if (fsm_pl == FSM_PL_IDLE) PL_WR_START <= 1'b1;
                else begin
                  pready  <= 1'b0;
                  apb_fsm <= FSM_WRITE;
                end
              end
            end
            PL_DATA:  reg_PL_DATA <= pwdata_i;
            PL_RAM: begin
              if (PL_CTL_ENABLE == 1'b1) begin
                if (fsm_pl == FSM_PL_IDLE) begin
                  PL_WR_START <= 1'b1;
                end else begin
                  pready  <= 1'b0;
                  apb_fsm <= FSM_WRITE;
                end
              end
            end  // case: PL_RAM
            default:  pslverr <= 1'b1;
          endcase  // casez (paddr_i)
        end  // case: FSM_WRITE

        FSM_READ: begin
          pready <= 1;
          if (penable_i == 1'b1) apb_fsm <= FSM_DONE;
          casez (paddr_i[15:0])
            PL_CTL: prdata <= rd_PL_CTL;
            PL_STAT: prdata <= rd_PL_STAT;
            PL_CFG: prdata <= {COLUMNS[7:0], ROWS[7:0], RAM_SIZE[13:0], 2'b00};
            PL_SELECT: prdata <= rd_PL_SELECT;
            PL_EXTRA: prdata <= {20'h0, rd_PL_EXTRA, 4'h0, reg_PL_EXTRA};
            PL_ROW: prdata <= {6'h0, PL_R_STRIDE, 6'h0, PL_R_OFFSET};
            PL_COLUMN: prdata <= {6'h0, PL_C_STRIDE, 6'h0, PL_C_OFFSET};
            PL_TARG: begin
              if (PL_CTL_ENABLE == 1'b1) begin
                pready  <= 1'b0;
                apb_fsm <= FSM_READ;
                if (fsm_pl == FSM_PL_IDLE) PL_RD_START <= 1'b1;
                else if (fsm_pl == FSM_PL_RDONE) begin
                  prdata <= PL_DATA_IN[31:0];
                  rd_PL_EXTRA <= PL_DATA_IN[35:32];
                  pready <= 1'b1;
                  apb_fsm <= FSM_DONE;
                end
              end
            end  // case: PL_TARG
            PL_DATA: prdata <= reg_PL_DATA;
            PL_RAM: begin
              if (PL_CTL_ENABLE == 1'b1) begin
                pready  <= 1'b0;
                apb_fsm <= FSM_READ;
                if (fsm_pl == FSM_PL_IDLE) PL_RD_START <= 1'b1;
                else if (fsm_pl == FSM_PL_RDONE) begin
                  prdata <= PL_DATA_IN[31:0];
                  rd_PL_EXTRA <= PL_DATA_IN[35:32];
                  pready <= 1'b1;
                  apb_fsm <= FSM_DONE;
                end
              end
            end  // case: PL_RAM
            default: pslverr <= 1'b1;

          endcase  // casez (paddr_i[15:0])
        end  // case: FSM_READ
      endcase  // case (apb_fsm)
    end  // else: !if(preset_ni == 1'b0)
  end  // block: CONFIGURATION


  always @(posedge pclk_i or negedge preset_ni) begin
    if (preset_ni == 1'b0) begin
      fsm_pl <= FSM_PL_IDLE;
      cycle_count <= 6'h0;
      pl_wdata <= 36'h0;
      PL_CAL_DONE <= 1'b0;
      PL_CAL_WAIT <= 6'h0;
      skew <= 2'b0;
      pl_ena <= 1'b0;
      pl_clk <= 1'b0;
      pl_ren <= 1'b0;
      pl_wen <= 2'b00;
      pl_addr <= 32'h0;
      pl_wdata <= 36'h0;
      PL_SEL_COL <= 10'h0;
      PL_SEL_ROW <= 10'h0;
      PL_SEL_ADDR <= 12'h0;

    end else begin
      cycle_count <= 6'h0;
      skew <= 2'b0;
      pl_clk <= 1'b0;
      case (fsm_pl)
        FSM_PL_IDLE: begin
          pl_ena <= 1'b0;
          pl_ren <= 1'b0;
          pl_wen <= 2'b00;
          if (load_PL_SELECT == 1'b1) {PL_SEL_COL, PL_SEL_ROW, PL_SEL_ADDR} <= reg_PL_SELECT;

          if (PL_CAL_START == 1'b1) begin
            fsm_pl <= FSM_PL_CALIB1;

          end else if (PL_WR_START == 1'b1) begin
            pl_ena <= 1'b1;
            pl_wen <= ~PL_CTL_SPLIT;
            fsm_pl <= FSM_PL_CYC1;
            if (paddr_i[14] == 1'b1) pl_addr <= {PL_SEL_COL, PL_SEL_ROW, paddr_i[13:2]};
            else pl_addr <= {PL_SEL_COL, PL_SEL_ROW, PL_SEL_ADDR};
            pl_wdata <= {parity, pwdata_i};
          end else if (PL_RD_START == 1'b1) begin
            pl_ena <= 1'b1;
            pl_ren <= 1'b1;
            fsm_pl <= FSM_PL_CYC1;
            if (paddr_i[14] == 1'b1) pl_addr <= {PL_SEL_COL, PL_SEL_ROW, paddr_i[13:2]};
            else pl_addr <= {PL_SEL_COL, PL_SEL_ROW, PL_SEL_ADDR};
            pl_wdata <= {parity, pwdata_i};
          end
        end  // case: FSM_PL_IDLE
        FSM_PL_CALIB1: begin
          pl_wdata <= 36'hfaa996655;
          cycle_count <= cycle_count + 1;
          if ((PL_DATA_IN == 36'hfaa996655) || (cycle_count == 6'h3f)) begin
            cycle_count <= 6'h0;
            pl_wdata <= 36'h0556699aa;
            fsm_pl <= FSM_PL_CALIB2;
          end
        end
        FSM_PL_CALIB2: begin
          pl_wdata <= 36'h0556699aa;
          cycle_count <= cycle_count + 1;
          if ((PL_DATA_IN == 36'h0556699aa) || (cycle_count == 6'h3f)) begin
            PL_CAL_WAIT <= cycle_count;
            PL_CAL_DONE <= 1'b1;
            fsm_pl <= FSM_PL_CALIB3;
          end
        end
        FSM_PL_CALIB3: begin
          if (PL_CAL_START == 1'b0) fsm_pl <= FSM_PL_IDLE;
        end

        FSM_PL_CYC1: begin
          if (skew == PL_CTL_SKEW) begin
            pl_clk <= 1'b1;
            fsm_pl <= FSM_PL_CYC2;
          end else skew <= skew + 2'b01;
        end
        FSM_PL_CYC2: begin
          if (pl_ren == 1'b1) begin
            if (cycle_count == PL_CTL_RWAIT) fsm_pl <= FSM_PL_RDONE;
            else cycle_count <= cycle_count + 1;
          end else  //write
            fsm_pl <= FSM_PL_WDONE;
        end
        FSM_PL_RDONE: begin
          if (PL_CTL_A_INC) begin
            if (PL_SEL_ADDR[11:0] == (RAM_SIZE - 1)) begin
              PL_SEL_ADDR <= 12'h0;
              if (PL_CTL_S_INC) begin
                if (PL_SEL_ROW == (PL_R_OFFSET + (PL_R_STRIDE * (ROWS - 1)))) begin
                  PL_SEL_ROW <= PL_R_OFFSET;
                  if (PL_SEL_COL == (PL_C_OFFSET + (PL_C_STRIDE * (COLUMNS - 1))))
                    PL_SEL_COL <= PL_C_OFFSET;
                  else PL_SEL_COL <= PL_SEL_COL + PL_C_STRIDE;
                end else begin
                  PL_SEL_ROW <= PL_SEL_ROW + PL_R_STRIDE;
                end
              end
            end else begin
              PL_SEL_ADDR <= PL_SEL_ADDR[11:0] + 'h1;
            end
          end
          fsm_pl <= FSM_PL_IDLE;
        end  // case: FSM_PL_DONE
        FSM_PL_WDONE: begin
          if (PL_CTL_A_INC) begin
            if (PL_SEL_ADDR[11:0] == (RAM_SIZE - 1)) begin
              PL_SEL_ADDR <= 12'h0;
              if (PL_CTL_S_INC) begin
                if (PL_SEL_ROW == (PL_R_OFFSET + (PL_R_STRIDE * (ROWS - 1)))) begin
                  PL_SEL_ROW <= PL_R_OFFSET;
                  if (PL_SEL_COL == (PL_C_OFFSET + (PL_C_STRIDE * (COLUMNS - 1))))
                    PL_SEL_COL <= PL_C_OFFSET;
                  else PL_SEL_COL <= PL_SEL_COL + PL_C_STRIDE;
                end else begin
                  PL_SEL_ROW <= PL_SEL_ROW + PL_R_STRIDE;
                end
              end
            end else begin
              PL_SEL_ADDR <= PL_SEL_ADDR[11:0] + 'h1;
            end
          end
          fsm_pl <= FSM_PL_IDLE;
        end  // case: FSM_PL_DONE

      endcase  // case (fsm_pl)
    end  // else: !if(preset_i == 1'b0)
  end  // always@ (posedge pclk_i or negedge preset_i)


  always @(posedge pclk_i or negedge preset_ni) begin
    if (preset_ni == 1'b0) begin
      bist_fsm <= #CK2Q 4'd0;
      bist_addr <= #CK2Q 32'h0;
      bist_data <= #CK2Q 36'h0;
      bist_ena <= #CK2Q 1'b0;
      bist_ren <= #CK2Q 1'b0;
      bist_wen <= #CK2Q 2'b00;
      bist_clk <= 1'b0;
      bist_running <= #CK2Q 1'b0;
      bist_init <= #CK2Q 1'b0;
      bist_fail <= #CK2Q 1'b0;
      bist_pass <= #CK2Q 1'b0;
      bist_abort <= #CK2Q 1'b0;
    end // if (preset_ni== 1'b0)
      else begin
      if (bist_running & ~PL_CTL_MBIST_START) bist_abort <= #CK2Q 1'b1;
      else bist_abort <= #CK2Q 1'b0;
      if ((PL_CTL_MBIST_START == 1'b1) & (bist_fsm == 4'd0)) bist_running <= #CK2Q 1'b1;
      else if ((bist_fsm == 4'd9) & (bist_clk == 1'b1)) bist_running <= #CK2Q 1'b0;
      else bist_running <= #CK2Q bist_running;

      case (bist_fsm)
        4'd0: begin
          if (PL_CTL_MBIST_START == 1'b1) begin
            bist_init <= #CK2Q 1'b1;
            bist_fsm  <= #CK2Q 4'd1;
            bist_ena  <= #CK2Q 1'b1;
            bist_wen  <= #CK2Q 2'b11;
          end else begin
            bist_fail <= #CK2Q 0;
            bist_pass <= #CK2Q 0;
            bist_ren  <= #CK2Q 1'b0;
            bist_ena  <= #CK2Q 1'b0;
            bist_addr <= #CK2Q 32'h0;
            bist_data <= #CK2Q 36'h0;
            bist_clk  <= 1'b0;
          end  // else: !if(fcsr_PL_CTL_MBIST_START == 1'b1)
        end
        4'd1: begin  // Initial write all locations to 0
          bist_clk <= ~bist_clk;
          if (bist_clk == 1'b1) begin
            bist_fsm <= #CK2Q 4'd2;
            bist_addr <= #CK2Q{
              10'h1, 10'h0, 12'h0
            };  // fake ram address to initialize bist results in RAMs
          end
        end
        4'd2: begin  // init the bist results registers in each ram with a non-broadcast bist write
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            bist_addr <= #CK2Q 32'h0;
            bist_fsm  <= #CK2Q 4'd3;
          end
        end
        4'd3: begin  // intiial rams to all 0's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_addr[11:0] == (RAM_SIZE - 1)) begin
              bist_addr <= #CK2Q 32'h0;
              bist_ren  <= #CK2Q 1'b1;
              bist_wen  <= #CK2Q 2'b0;
              bist_fsm  <= #CK2Q 4'd4;
            end else bist_addr <= #CK2Q bist_addr + 1;
          end
        end  // case: 3
        4'd4: begin  // read exp 0's then write to 1's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_wen == 2'b11) begin
              if (bist_addr[11:0] == (RAM_SIZE - 1)) begin
                bist_addr <= #CK2Q 32'h0;
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_fsm  <= #CK2Q 4'd5;
              end else begin
                bist_addr <= #CK2Q bist_addr + 1;
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_data <= #CK2Q 36'h0;

              end  // else: !if(bist_addr[11:0] == (RAM_SIZE-1))
            end // if (bist_wen == 2'b11)
                 else begin
              bist_ren  <= #CK2Q 1'b0;
              bist_wen  <= #CK2Q 2'b11;
              bist_data <= #CK2Q 36'hfffffffff;
            end  // else: !if(bist_wen == 2'b11)
          end  // if (bist_clk == 1'b1)
        end  // case: 4
        4'd5: begin  // read exp 1's then write to 0's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_wen == 2'b11) begin
              if (bist_addr[11:0] == (RAM_SIZE - 1)) begin
                bist_wen <= #CK2Q 2'b00;
                bist_ren <= #CK2Q 1'b1;
                bist_fsm <= #CK2Q 4'd6;
              end else begin
                bist_addr <= #CK2Q bist_addr + 1;
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_data <= #CK2Q 36'hfffffffff;

              end  // else: !if(bist_addr[11:0] == (RAM_SIZE-1))
            end // if (bist_wen == 2'b11)
                 else begin
              bist_ren  <= #CK2Q 1'b0;
              bist_wen  <= #CK2Q 2'b11;
              bist_data <= #CK2Q 36'h0;
            end  // else: !if(bist_wen == 2'b11)
          end  // if (bist_clk == 1'b1)
        end  // case: 5

        4'd6: begin  // read exp 0's then write to 1's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_wen == 2'b11) begin
              if (bist_addr[11:0] == (12'h0)) begin
                bist_addr <= #CK2Q(RAM_SIZE - 1);
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_fsm  <= #CK2Q 4'd7;
              end else begin
                bist_addr <= #CK2Q bist_addr - 1;
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_data <= #CK2Q 36'h0;

              end  // else: !if(bist_addr[11:0] == (RAM_SIZE-1))
            end // if (bist_wen == 2'b11)
                 else begin
              bist_ren  <= #CK2Q 1'b0;
              bist_wen  <= #CK2Q 2'b11;
              bist_data <= #CK2Q 36'hfffffffff;
            end  // else: !if(bist_wen == 2'b11)
          end  // if (bist_clk == 1'b1)
        end  // case: 6
        4'd7: begin  // read exp 1's then write to 0's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_wen == 2'b11) begin
              if (bist_addr[11:0] == 12'h0) begin
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_fsm  <= #CK2Q 4'd8;
                bist_data <= #CK2Q 36'h0;
              end else begin
                bist_addr <= #CK2Q bist_addr - 1;
                bist_wen  <= #CK2Q 2'b00;
                bist_ren  <= #CK2Q 1'b1;
                bist_data <= #CK2Q 36'hfffffffff;

              end  // else: !if(bist_addr[11:0] == (RAM_SIZE-1))
            end // if (bist_wen == 2'b11)
                 else begin
              bist_ren  <= #CK2Q 1'b0;
              bist_wen  <= #CK2Q 2'b11;
              bist_data <= #CK2Q 36'h0;
            end  // else: !if(bist_wen == 2'b11)
          end  // if (bist_clk == 1'b1)
        end  // case: 7
        4'd8: begin  // read exp 0's
          bist_clk <= ~bist_clk;
          if (bist_abort == 1'b1) bist_fsm <= #CK2Q 4'd0;
          else if (bist_clk == 1'b1) begin
            if (bist_addr == (RAM_SIZE - 1)) begin
              bist_data <= #CK2Q 36'h0;
              bist_init <= #CK2Q 1'b0;  // turn off pl_init to read results via non-broadcast read
              bist_addr <= #CK2Q 32'h00000000;
              bist_fsm  <= #CK2Q 4'd9;
            end else bist_addr <= #CK2Q bist_addr + 1;
          end
        end  // case: 8
        4'd9: begin
          bist_clk <= ~bist_clk;
          if (bist_clk == 1'b1) begin
            if (PL_DATA_IN == 36'h0) bist_pass <= #CK2Q 1'b1;
            else bist_fail <= #CK2Q 1'b1;
            bist_fsm <= #CK2Q 4'd10;
          end
        end  // case: 9
        4'd10:   bist_fsm <= #CK2Q 4'd11;
        4'd11: begin
          if (PL_CTL_MBIST_START == 1'b0) bist_fsm <= #CK2Q 4'd0;
        end
        default: bist_fsm <= #CK2Q 4'd0;
      endcase  // case (bist_fsm)
    end  // else: !if(fcb_reg_rstn == 1'b0)
  end  // always @ (posedge FCB_CLK or negedge fcb_reg_rstn)
endmodule

