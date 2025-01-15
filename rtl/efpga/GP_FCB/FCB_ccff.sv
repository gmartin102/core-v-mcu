`timescale 1ns / 10ps

module FCB_ccff (
    input  wire        preset_ni,
    input  wire [31:0] pwdata_i,
    input  wire [15:0] paddr_i,
    input  wire        psel_i,
    input  wire        penable_i,
    input  wire        pwrite_i,
    input  wire        pclk_i,
    output wire [31:0] prdata_o,
    output wire        pready_o,
    output wire        pslverr_o,
    output wire [31:0] CCFF_HEAD_o,
    input  wire [31:0] CCFF_TAIL_i,
    output wire        CFG_RSTN_o,
    output wire        CFG_DONE_o,
    output wire        CFG_CLK_o,
    input  wire        set_cfg_done_i
);

  localparam CK2Q = 0.01;

  localparam DEVICE_ID = 16'h00;
  localparam FB_CFG_CMD = 16'h04;
  localparam FB_CFG_KICKOFF = 16'h08;
  localparam FB_CFG_DONE = 16'h0C;
  localparam FB_CFG_DATA = 16'h10;
  localparam FB_CFG_LOOPCNT = 16'h14;
  localparam CHKSUM_WORD = 16'h18;
  localparam CHKSUM_STATUS = 16'h1C;
  localparam FB_SOFT_RESET = 16'h20;
  localparam FB_RB_DATA = 16'h24;


  reg pslverr, pready;
  reg  [31:0] prdata;


  reg  [ 2:0] fCSR_FB_CFG_CMD;
  wire        disable_chksum;
  wire        pre_chksum_en;
  wire        post_chksum_en;
  wire        post_chksum1_en;
  reg         CFG_CLK;
  wire [31:0] fCHKSUM;
  reg [15:0] fchksum_c0, fchksum_c1;
  wire [15:0] chksum_c0_w0, chksum_c0_w1;
  wire [15:0] chksum_c1_w0, chksum_c1_w1;

  reg        fCSR_CHKS_chksum_w0;
  reg        fCSR_CHKS_chksum_w1;
  reg        fCSR_CHKS_chksum_w2;
  reg        fCSR_CHKS_chksum_w3;
  reg        fCSR_CHKS_chksum_w4;

  reg        fCSR_CFG_KICKOFF;
  reg        fCSR_CFG_DONE;
  reg [31:0] fCSR_CFG_LOOPCNT;
  reg [31:0] fCSR_CHKSUM_WORD;
  reg        fCSR_CHKSUM_STATUS;
  reg        reg_SOFT_RESET;

  reg set_CFG_DONE, clr_CFG_DONE;
  reg         set_KICKOFF;

  wire [31:0] CCFF_TAIL;
  reg  [31:0] CCFF_HEAD;
  reg  [31:0] CCFF_TAIL_d;


  reg  [31:0] loop_count;

  localparam FSM_IDLE = 2'd0;
  localparam FSM_READ = 2'd1;
  localparam FSM_WRITE = 2'd2;
  localparam FSM_DONE = 2'd3;
  reg [1:0] fsm_apb;


  assign pslverr_o = pslverr & psel_i;
  assign pready_o = psel_i && penable_i && ((fsm_apb == FSM_READ) || (fsm_apb == FSM_WRITE));
  assign prdata_o = (psel_i & penable_i) ? prdata : 32'h0;

  assign disable_chksum = fCSR_FB_CFG_CMD == 3'h0;
  assign pre_chksum_en = fCSR_FB_CFG_CMD == 3'h1;
  assign post_chksum_en = fCSR_FB_CFG_CMD == 3'h2;
  assign post_chksum1_en = fCSR_FB_CFG_CMD == 3'h4;
  assign CFG_CLK_o = CFG_CLK;
  assign CFG_RSTN_o = ~(~preset_ni | reg_SOFT_RESET);
  assign CFG_DONE_o = fCSR_CFG_DONE;


  //KCY 20240129   assign CCFF_HEAD_o = {CCFF_HEAD[0],CCFF_HEAD[1],CCFF_HEAD[2],CCFF_HEAD[3],
  //KCY 20240129                         CCFF_HEAD[4],CCFF_HEAD[5],CCFF_HEAD[6],CCFF_HEAD[7],
  //KCY 20240129                         CCFF_HEAD[8],CCFF_HEAD[9],CCFF_HEAD[10],CCFF_HEAD[11],
  //KCY 20240129                         CCFF_HEAD[12],CCFF_HEAD[13],CCFF_HEAD[14],CCFF_HEAD[15],
  //KCY 20240129                         CCFF_HEAD[16],CCFF_HEAD[17],CCFF_HEAD[18],CCFF_HEAD[19],
  //KCY 20240129                         CCFF_HEAD[20],CCFF_HEAD[21],CCFF_HEAD[22],CCFF_HEAD[23],
  //KCY 20240129                         CCFF_HEAD[24],CCFF_HEAD[25],CCFF_HEAD[26],CCFF_HEAD[27],
  //KCY 20240129                         CCFF_HEAD[28],CCFF_HEAD[29],CCFF_HEAD[30],CCFF_HEAD[31]};
  //KCY 20240129   assign CCFF_TAIL = {CCFF_TAIL_i[0],CCFF_TAIL_i[1],CCFF_TAIL_i[2],CCFF_TAIL_i[3],
  //KCY 20240129                         CCFF_TAIL_i[4],CCFF_TAIL_i[5],CCFF_TAIL_i[6],CCFF_TAIL_i[7],
  //KCY 20240129                         CCFF_TAIL_i[8],CCFF_TAIL_i[9],CCFF_TAIL_i[10],CCFF_TAIL_i[11],
  //KCY 20240129                         CCFF_TAIL_i[12],CCFF_TAIL_i[13],CCFF_TAIL_i[14],CCFF_TAIL_i[15],
  //KCY 20240129                         CCFF_TAIL_i[16],CCFF_TAIL_i[17],CCFF_TAIL_i[18],CCFF_TAIL_i[19],
  //KCY 20240129                         CCFF_TAIL_i[20],CCFF_TAIL_i[21],CCFF_TAIL_i[22],CCFF_TAIL_i[23],
  //KCY 20240129                         CCFF_TAIL_i[24],CCFF_TAIL_i[25],CCFF_TAIL_i[26],CCFF_TAIL_i[27],
  //KCY 20240129                         CCFF_TAIL_i[28],CCFF_TAIL_i[29],CCFF_TAIL_i[30],CCFF_TAIL_i[31]};

  assign CCFF_HEAD_o = CCFF_HEAD;
  assign CCFF_TAIL = CCFF_TAIL_i;

  assign fCHKSUM = disable_chksum ? 31'h0 : 
                    (post_chksum1_en ? CCFF_TAIL_d :
                     (pre_chksum_en ? CCFF_HEAD : CCFF_TAIL) );

  assign chksum_c0_w0 = fchksum_c0 + fCHKSUM[15:0];
  assign chksum_c0_w1 = fchksum_c0 + fCHKSUM[31:16];
  assign chksum_c1_w0 = fchksum_c0 + fchksum_c1 + fCHKSUM[15:0];
  assign chksum_c1_w1 = fchksum_c0 + fchksum_c1 + fCHKSUM[31:16];

  always @(posedge pclk_i or negedge preset_ni) begin : CONFIGURATION
    if (preset_ni == 1'b0) begin
      loop_count <= 32'h0;
      fCSR_CFG_KICKOFF <= 1'b0;
      fCSR_CFG_DONE <= 1'b0;
      fchksum_c0 <= 16'h0;
      fchksum_c1 <= 16'h0;
      CFG_CLK <= 1'b0;
      fCSR_CHKSUM_STATUS <= 1'b0;
    end else begin
      CFG_CLK <= 1'b0;
      if (clr_CFG_DONE || reg_SOFT_RESET) begin
        fCSR_CFG_DONE <= 1'b0;
      end else if (set_CFG_DONE || set_cfg_done_i) begin
        fCSR_CFG_DONE <= 1'b1;
      end else if (set_KICKOFF) begin
        fCSR_CFG_DONE <= 1'b0;
        fCSR_CFG_KICKOFF <= #CK2Q 1'b1;
        loop_count <= fCSR_CFG_LOOPCNT;
        fchksum_c0 <= 16'h0;
        fchksum_c1 <= 16'h0;
      end else if (fCSR_CHKS_chksum_w0) begin
        CFG_CLK <= 1'b1;
        loop_count <= loop_count - 32'h1;
        fchksum_c0 <= #CK2Q post_chksum_en ? fchksum_c0 : chksum_c0_w0  ; //(post_chksum_en ? fchksum_c0 : chksum_c0_w0);
        fchksum_c1 <= #CK2Q post_chksum_en ? fchksum_c1 : chksum_c1_w0  ; //(post_chksum_en ? fchksum_c1 : chksum_c1_w0);
      end else if (fCSR_CHKS_chksum_w1) begin

        fchksum_c0 <= #CK2Q post_chksum_en ? fchksum_c0 : chksum_c0_w1;
        fchksum_c1 <= #CK2Q post_chksum_en ? fchksum_c1 : chksum_c1_w1;
      end else if (fCSR_CHKS_chksum_w2) begin
        fchksum_c0 <= #CK2Q post_chksum_en ? chksum_c0_w0 : fchksum_c0;
        fchksum_c1 <= #CK2Q post_chksum_en ? chksum_c1_w0 : fchksum_c1;
      end else if (fCSR_CHKS_chksum_w3) begin
        fchksum_c0 <= #CK2Q post_chksum_en ? chksum_c0_w1 : fchksum_c0;
        fchksum_c1 <= #CK2Q post_chksum_en ? chksum_c1_w1 : fchksum_c1;
      end else if (loop_count == 32'h0 && fCSR_CFG_KICKOFF && fCSR_CHKS_chksum_w4) begin
        fCSR_CFG_DONE <= 1'b1;
        fCSR_CHKSUM_STATUS <=  ~( |(fchksum_c0 + fCSR_CHKSUM_WORD[15:0] + fCSR_CHKSUM_WORD[31:16])
                                      || |(fchksum_c1 - fCSR_CHKSUM_WORD[31:16]) );
      end
    end  // else: !if(preset_ni == 1'b0)
  end  // block: CONFIGURATION

  always @(posedge pclk_i or negedge preset_ni) begin : FSM_APB
    if (preset_ni == 1'b0) begin
      fsm_apb <= FSM_IDLE;
      fCSR_FB_CFG_CMD <= 2'b00;
      set_KICKOFF <= 1'b0;
      fCSR_CHKS_chksum_w0 <= #CK2Q 1'b0;
      fCSR_CHKS_chksum_w1 <= #CK2Q 1'b0;
      fCSR_CHKS_chksum_w2 <= #CK2Q 1'b0;
      fCSR_CHKS_chksum_w3 <= #CK2Q 1'b0;
      fCSR_CHKS_chksum_w4 <= #CK2Q 1'b0;
      prdata <= 32'h0;
      fCSR_CFG_LOOPCNT <= 32'h0;
      fCSR_CHKSUM_WORD <= 32'h0;
      set_CFG_DONE <= 1'b0;
      clr_CFG_DONE <= 1'b0;
      reg_SOFT_RESET <= 1'b0;
      CCFF_HEAD <= 32'h0;
      pslverr <= 1'b0;
      CCFF_TAIL_d <= 32'h0;
    end else begin
      pslverr <= 1'b0;
      set_KICKOFF <= 1'b0;
      fCSR_CHKS_chksum_w4 <= #CK2Q fCSR_CHKS_chksum_w3;
      fCSR_CHKS_chksum_w3 <= #CK2Q fCSR_CHKS_chksum_w2;
      fCSR_CHKS_chksum_w2 <= #CK2Q fCSR_CHKS_chksum_w1;
      fCSR_CHKS_chksum_w1 <= #CK2Q fCSR_CHKS_chksum_w0;
      fCSR_CHKS_chksum_w0 <= 1'b0;
      set_CFG_DONE <= 1'b0;
      clr_CFG_DONE <= 1'b0;
      case (fsm_apb)
        FSM_DONE: fsm_apb <= FSM_IDLE;

        FSM_IDLE: begin
          prdata <= 32'h0;
          if (psel_i & pwrite_i) begin
            fsm_apb <= FSM_WRITE;
            case (paddr_i)
              FB_CFG_CMD: fCSR_FB_CFG_CMD <= pwdata_i[2:0];
              FB_CFG_KICKOFF: set_KICKOFF <= pwdata_i[0];
              FB_CFG_DONE: begin
                set_CFG_DONE <= pwdata_i[0];
                clr_CFG_DONE <= !pwdata_i[0];
              end
              FB_CFG_DATA: begin
                CCFF_TAIL_d <= CCFF_TAIL;
                fCSR_CHKS_chksum_w0 <= fCSR_CFG_KICKOFF;
                CCFF_HEAD <= pwdata_i;
              end
              FB_CFG_LOOPCNT: fCSR_CFG_LOOPCNT <= pwdata_i;
              CHKSUM_WORD: fCSR_CHKSUM_WORD <= pwdata_i;
              FB_SOFT_RESET: reg_SOFT_RESET <= pwdata_i[0];
              default: begin
                pslverr <= 1'b1;
              end
            endcase  // case (paddr_i)
          end // if (psel_i & pwrite_i)
              else if (psel_i ) begin
            fsm_apb <= FSM_READ;
            case (paddr_i[15:0])
              DEVICE_ID: prdata <= 32'h22;
              FB_CFG_CMD: prdata <= {29'h0, fCSR_FB_CFG_CMD};
              FB_CFG_KICKOFF: prdata <= {31'h0, fCSR_CFG_KICKOFF};
              FB_CFG_DONE: prdata <= {31'h0, fCSR_CFG_DONE};
              FB_CFG_LOOPCNT: prdata <= fCSR_CFG_LOOPCNT;
              CHKSUM_WORD: prdata <= fCSR_CHKSUM_WORD;
              CHKSUM_STATUS: prdata <= {31'h0, fCSR_CHKSUM_STATUS};
              FB_RB_DATA: prdata <= CCFF_TAIL;
              default: begin
                pslverr <= 1'b1;
              end
            endcase  // case (paddr[15:0])
          end
        end

        FSM_WRITE: begin
          if (penable_i == 1'b1) fsm_apb <= FSM_DONE;

        end  // case: FSM_WRITE


        FSM_READ: begin
          if (penable_i == 1'b1) fsm_apb <= FSM_DONE;
        end  // case: FSM_READ
      endcase  // case (fsm_apb)
    end  // else: !if(preset_ni == 1'b0)
  end  // block: FSM_APB

endmodule
