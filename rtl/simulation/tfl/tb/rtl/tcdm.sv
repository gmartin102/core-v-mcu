`timescale 1ns / 1ns
module tcdm (
    // APB BUS connetions
    input  wire        dump_result,
    input  wire        clk,
    rstn,
    // TCDM connections
    input  wire [19:0] tcdm_addr_p0,
    tcdm_addr_p1,
    input  wire [19:0] tcdm_addr_p2,
    tcdm_addr_p3,
    input  wire [31:0] tcdm_wdata_p0,
    tcdm_wdata_p1,
    input  wire [31:0] tcdm_wdata_p2,
    tcdm_wdata_p3,
    input  wire [ 3:0] tcdm_be_p0,
    tcdm_be_p1,
    tcdm_be_p2,
    tcdm_be_p3,
    input  wire        tcdm_req_p0,
    tcdm_req_p1,
    tcdm_req_p2,
    tcdm_req_p3,
    input  wire        tcdm_wen_p0,
    tcdm_wen_p1,
    tcdm_wen_p2,
    tcdm_wen_p3,
    output wire [31:0] tcdm_rdata_p0,
    tcdm_rdata_p1,
    output wire [31:0] tcdm_rdata_p2,
    tcdm_rdata_p3,
    output wire        tcdm_valid_p0,
    tcdm_valid_p1,
    output wire        tcdm_valid_p2,
    tcdm_valid_p3,
    output wire        tcdm_gnt_p0,
    tcdm_gnt_p1,
    output wire        tcdm_gnt_p2,
    tcdm_gnt_p3
);

  parameter pixel = "pixel.dat";
  parameter filter = "filter.dat";
  parameter bias = "bias.dat";
  parameter result = "result.dat";
  parameter expected = "expect.dat";
  parameter quiet = 0;


  reg [31:0] pixel_mem [ 0:8191];  // 32KBytes
  reg [31:0] filter_mem[0:17000];  // 32KBytes
  reg [31:0] bias_mem  [ 0:2048];  // 8KBytes
  reg [31:0] result_mem[ 0:9215];  // 36KBytes
  reg [31:0] expect_mem[ 0:9215];  // 36KBytes
  reg [31:0] tcdm0_rdata, tcdm1_rdata;
  reg [31:0] tcdm2_rdata, tcdm3_rdata;
  reg tcdm0_gnt, tcdm1_gnt, tcdm2_gnt, tcdm3_gnt;

  reg [1:0] tcdm0_valid, tcdm1_valid, tcdm2_valid, tcdm3_valid;

  reg tcdm0_nreq, tcdm1_nreq, tcdm2_nreq, tcdm3_nreq;
  reg tcdm0_nwr, tcdm1_nwr, tcdm2_nwr, tcdm3_nwr;
  reg fail0, fail1, fail2, fail3;
  reg [31:0] expect0, expect1, expect2, expect3;



  assign tcdm_gnt_p0   = tcdm0_gnt;
  assign tcdm_gnt_p1   = tcdm1_gnt;
  assign tcdm_gnt_p2   = tcdm2_gnt;
  assign tcdm_gnt_p3   = tcdm3_gnt;
  assign tcdm_valid_p0 = tcdm0_valid[1];
  assign tcdm_valid_p1 = tcdm1_valid[1];
  assign tcdm_valid_p2 = tcdm2_valid[1];
  assign tcdm_valid_p3 = tcdm3_valid[1];
  assign tcdm_rdata_p0 = tcdm0_rdata;
  assign tcdm_rdata_p1 = tcdm1_rdata;
  assign tcdm_rdata_p2 = tcdm2_rdata;
  assign tcdm_rdata_p3 = tcdm3_rdata;




  always @(negedge rstn) begin
    if (!quiet)
      $display(
          "TCDM: %d opening %s, %s, %s, %s, and %s\n", $time, pixel, filter, bias, result, expected
      );
    $readmemh(pixel, pixel_mem);
    $readmemh(filter, filter_mem);
    $readmemh(bias, bias_mem);
    //$readmemh(result,result_mem);
    $readmemh(expected, expect_mem);
    if (!quiet) $display("TCDM: %d init completes\n", $time);
  end

  integer f, i;
  always @(posedge dump_result) begin
    f = $fopen("output.txt", "w");

    for (i = 0; i < 4096; i = i + 1) begin
      $fwrite(f, "%08x\n", result_mem[i]);
    end

    $fclose(f);
  end

  always @(negedge clk or negedge rstn) begin
    if (rstn == 0) begin
      tcdm0_nreq <= 0;
      tcdm0_nwr  <= 1;
      tcdm1_nreq <= 0;
      tcdm1_nwr  <= 1;
      tcdm2_nreq <= 0;
      tcdm2_nwr  <= 1;
      tcdm3_nreq <= 0;
      tcdm3_nwr  <= 1;
    end else begin
      tcdm0_nreq <= tcdm_req_p0;
      tcdm0_nwr  <= tcdm_wen_p0;
      tcdm1_nreq <= tcdm_req_p1;
      tcdm1_nwr  <= tcdm_wen_p1;
      tcdm2_nreq <= tcdm_req_p2;
      tcdm2_nwr  <= tcdm_wen_p2;
      tcdm3_nreq <= tcdm_req_p3;
      tcdm3_nwr  <= tcdm_wen_p3;
    end  // else: !if(rstn == 0)
  end  // always@ (negedge clk or negedge rstn)


  always @(posedge clk or negedge rstn) begin
    if (rstn == 0) begin
      tcdm0_rdata <= 0;
      tcdm0_gnt <= 1;
      tcdm0_valid <= 0;
      tcdm1_rdata <= 0;
      tcdm1_gnt <= 1;
      tcdm1_valid <= 0;
      tcdm2_rdata <= 0;
      tcdm2_gnt <= 1;
      tcdm2_valid <= 0;
      tcdm3_rdata <= 0;
      tcdm3_gnt <= 1;
      tcdm3_valid <= 0;
      fail0 <= 0;
      fail1 <= 0;
      fail2 <= 0;
      fail3 <= 0;

    end // if (rstn == 0)
      else begin
      fail0 <= 0;
      fail1 <= 0;
      fail2 <= 0;
      fail3 <= 0;

      if (tcdm0_valid[1] == 1) begin
        tcdm0_gnt <= 1;
      end

      //	 if ((tcdm_req_p0 == 1) && (tcdm0_gnt == 1)) begin
      if ((tcdm0_nreq == 1) && (tcdm0_gnt == 1)) begin
        tcdm0_valid <= {tcdm0_valid[0], 1'b1};
        tcdm0_gnt   <= 0;
        //	    if (tcdm_wen_p0 == 1) begin
        if (tcdm0_nwr == 1) begin
          case (tcdm_addr_p0[17:16])
            0: tcdm0_rdata <= pixel_mem[tcdm_addr_p0[15:2]];
            1: tcdm0_rdata <= filter_mem[tcdm_addr_p0[15:2]];
            2: tcdm0_rdata <= bias_mem[tcdm_addr_p0[15:2]];
            3: tcdm0_rdata <= result_mem[tcdm_addr_p0[15:2]];
          endcase  // case (tcdm_addr_p0[16:15])

        end else begin
          case (tcdm_addr_p0[17:16])
            0: pixel_mem[tcdm_addr_p0[15:2]] <= tcdm_wdata_p0;
            1: filter_mem[tcdm_addr_p0[15:2]] <= tcdm_wdata_p0;
            2: bias_mem[tcdm_addr_p0[15:2]] <= tcdm_wdata_p0;
            3: begin
              result_mem[tcdm_addr_p0[15:2]] <= tcdm_wdata_p0;
              if (tcdm_wdata_p0 !== expect_mem[tcdm_addr_p0[15:2]]) begin
                expect0 <= expect_mem[tcdm_addr_p0[15:2]];
                fail0   <= 1;
                if (!quiet)
                  $display(
                      "%d:tcdm_p0[%04x] = %08x - expected %08x\n",
                      $time,
                      tcdm_addr_p0[15:0],
                      tcdm_wdata_p0,
                      expect_mem[tcdm_addr_p0[15:2]]
                  );
              end

            end
          endcase  // case (tcdm_addr_p0[16:15])
          tcdm0_rdata <= tcdm_wdata_p0;
        end
      end // if ((tcdm_req_p0 == 1) && (tcdm0_gnt == 1))
	 else begin
        tcdm0_valid <= {tcdm0_valid[0], 1'b0};
      end  // else: !if((tcdm_req_p0 == 1) && (tcdm0_gnt == 1))

      if (tcdm1_valid[1] == 1) begin
        tcdm1_gnt <= 1;
      end
      //	 if ((tcdm_req_p1 == 1) && (tcdm1_gnt == 1)) begin
      if ((tcdm1_nreq == 1) && (tcdm1_gnt == 1)) begin
        tcdm1_gnt   <= 0;
        tcdm1_valid <= {tcdm1_valid[0], 1'b1};
        //	    if (tcdm_wen_p1 == 1) begin
        if (tcdm1_nwr == 1) begin
          case (tcdm_addr_p1[17:16])
            0: tcdm1_rdata <= pixel_mem[tcdm_addr_p1[15:2]];
            1: tcdm1_rdata <= filter_mem[tcdm_addr_p1[15:2]];
            2: tcdm1_rdata <= bias_mem[tcdm_addr_p1[15:2]];
            3: tcdm1_rdata <= result_mem[tcdm_addr_p1[15:2]];

          endcase  // case (tcdm_addr_p0[17:16])
        end else begin
          case (tcdm_addr_p1[17:16])
            0: pixel_mem[tcdm_addr_p1[15:2]] <= tcdm_wdata_p1;
            1: filter_mem[tcdm_addr_p1[15:2]] <= tcdm_wdata_p1;
            2: bias_mem[tcdm_addr_p1[15:2]] <= tcdm_wdata_p1;
            3: begin
              result_mem[tcdm_addr_p1[15:2]] <= tcdm_wdata_p1;
              if (tcdm_wdata_p1 !== expect_mem[tcdm_addr_p1[15:2]]) begin
                fail1   <= 1;
                expect1 <= expect_mem[tcdm_addr_p1[15:2]];
                if (!quiet)
                  $display(
                      "%d:tcdm_p1[%04x] = %08x - expected %08x\n",
                      $time,
                      tcdm_addr_p1[14:0],
                      tcdm_wdata_p1,
                      expect_mem[tcdm_addr_p1[15:2]]
                  );
              end
            end

          endcase  // case (tcdm_addr_p0[17:16])
          tcdm1_rdata <= tcdm_wdata_p1;
        end
      end // if ((tcdm_req_p1 == 1) && (tcdm1_gnt == 1))
	 else begin
        tcdm1_valid <= {tcdm1_valid[0], 1'b0};
      end  // else: !if((tcdm_req_p1 == 1) && (tcdm1_gnt == 1))

      if (tcdm2_valid[1] == 1) begin
        tcdm2_gnt <= 1;
      end

      //	 if ((tcdm_req_p2 == 1)&&(tcdm2_gnt == 1)) begin
      if ((tcdm2_nreq == 1) && (tcdm2_gnt == 1)) begin
        tcdm2_gnt   <= 0;
        tcdm2_valid <= {tcdm2_valid[0], 1'b1};
        //	    if (tcdm_wen_p2 == 1) begin
        if (tcdm2_nwr == 1) begin
          case (tcdm_addr_p2[17:16])
            0: tcdm2_rdata <= pixel_mem[tcdm_addr_p2[15:2]];
            1: tcdm2_rdata <= filter_mem[tcdm_addr_p2[15:2]];
            2: tcdm2_rdata <= bias_mem[tcdm_addr_p2[15:2]];
            2: tcdm2_rdata <= result_mem[tcdm_addr_p2[15:2]];

          endcase  // case (tcdm_addr_p0[17:16])

        end else begin
          case (tcdm_addr_p2[17:16])
            0: pixel_mem[tcdm_addr_p2[15:2]] <= tcdm_wdata_p2;
            1: filter_mem[tcdm_addr_p2[15:2]] <= tcdm_wdata_p2;
            2: bias_mem[tcdm_addr_p2[15:2]] <= tcdm_wdata_p2;
            3: begin
              result_mem[tcdm_addr_p2[15:2]] <= tcdm_wdata_p2;
              if (tcdm_wdata_p2 !== expect_mem[tcdm_addr_p2[15:2]]) begin
                expect2 <= expect_mem[tcdm_addr_p2[15:2]];
                fail2   <= 1;
                if (!quiet)
                  $display(
                      "%d:tcdm_p2[%04x] = %08x - expected %08x\n",
                      $time,
                      tcdm_addr_p2[14:0],
                      tcdm_wdata_p2,
                      expect_mem[tcdm_addr_p2[15:2]]
                  );
              end
            end

          endcase  // case (tcdm_addr_p0[17:16])
          tcdm2_rdata <= tcdm_wdata_p2;
        end
      end // if ((tcdm_req_p2 == 1)&&(tcdm2_gnt == 1))
	 else begin
        tcdm2_valid <= {tcdm2_valid[0], 1'b0};
      end  // else: !if((tcdm_req_p2 == 1)&&(tcdm2_gnt == 1))


      if (tcdm3_valid[1] == 1) begin
        tcdm3_gnt <= 1;
      end

      //	 if ((tcdm_req_p3 == 1) && (tcdm3_gnt == 1)) begin
      if ((tcdm3_nreq == 1) && (tcdm3_gnt == 1)) begin
        tcdm3_gnt   <= 0;
        tcdm3_valid <= {tcdm3_valid[0], 1'b1};
        //	    if (tcdm_wen_p3 == 1) begin
        if (tcdm3_nwr == 1) begin
          case (tcdm_addr_p3[17:16])
            0: tcdm3_rdata <= pixel_mem[tcdm_addr_p3[15:2]];
            1: tcdm3_rdata <= filter_mem[tcdm_addr_p3[15:2]];
            2: tcdm3_rdata <= bias_mem[tcdm_addr_p3[15:2]];
            3: tcdm3_rdata <= result_mem[tcdm_addr_p3[15:2]];
          endcase  // case (tcdm_addr_p0[17:16])

        end else begin
          case (tcdm_addr_p3[17:16])
            0: pixel_mem[tcdm_addr_p3[15:2]] <= tcdm_wdata_p3;
            1: filter_mem[tcdm_addr_p3[15:2]] <= tcdm_wdata_p3;
            2: bias_mem[tcdm_addr_p3[15:2]] <= tcdm_wdata_p3;
            3: begin
              result_mem[tcdm_addr_p3[15:2]] <= tcdm_wdata_p3;
              if (tcdm_wdata_p3 !== expect_mem[tcdm_addr_p3[15:2]]) begin
                expect3 <= expect_mem[tcdm_addr_p3[15:2]];
                fail3   <= 1;
                if (!quiet)
                  $display(
                      "%d:tcdm_p3[%04x] = %08x - expected %08x\n",
                      $time,
                      tcdm_addr_p3[14:0],
                      tcdm_wdata_p3,
                      expect_mem[tcdm_addr_p3[15:2]]
                  );
              end
            end

          endcase  // case (tcdm_addr_p0[17:16])
          tcdm3_rdata <= tcdm_wdata_p3;
        end
      end // if ((tcdm_req_p3 == 1) && (tcdm3_gnt == 1))
	 else begin
        tcdm3_valid <= {tcdm3_valid[0], 1'b0};
      end  // else: !if((tcdm_req_p3 == 1) && (tcdm3_gnt == 1))


    end  // else: !if(rstn == 0)
  end  // always@ (posedge clk or negedge rstn)
endmodule  // tcdm




