module sdpram1024x32 (
    input logic        clk_a,
    input logic        cen_a,
    input logic        wen_a,
    input logic [ 9:0] addr_a,
    input logic [31:0] wdata_a,

    input  logic        clk_b,
    input  logic        cen_b,
    input  logic [ 9:0] addr_b,
    output logic [31:0] rdata_b
);

  wire [63:0]   tpram_bit_write;
  wire [63:0]   tpram_r_data;
  reg    laddr_0;

  always @(posedge clk_b) begin
    laddr_0 <= cen_b ? laddr_0 : addr_b[0];
  end
  assign rdata_b = laddr_0 ? tpram_r_data[63:32] : tpram_r_data[31:0];
  assign tpram_bit_write = wen_a ? 64'h0 :
   (~addr_a[0] ? 64'h00000000ffffffff : 64'hffffffff00000000);


  sram512x64 U_TPRAM_512X64 (
      .clkA     (clk_a),
      .clkB     (clk_b),
      .cenA     (cen_b),
      .cenB     (wen_a),
      .deepsleep(1'b0),                //vincent
      .powergate(1'b0),
      .aA       (addr_b[9:1]),
      .aB       (addr_a[9:1]),
      .d        ({wdata_a, wdata_a}),
      .bw       (tpram_bit_write),
      .q        (tpram_r_data)
  );
endmodule  // sdpram1024x32

/*

  logic [31:0] ram[1023:0];

  always @(posedge clk_b) begin
    if (cen_b == 0) begin
      rdata_b = ram[addr_b];
    end else rdata_b = rdata_b;
  end  // always@ (*)

  always @(posedge clk_a) begin
    if ((wen_a == 0) && (cen_a == 0)) begin
      ram[addr_a] <= wdata_a;
    end  // if ((lwen_a == 0) && (lcen_a == 0))
  end

endmodule
*/
