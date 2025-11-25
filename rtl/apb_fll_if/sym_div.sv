module sym_div #(
)(
  input wire  [9:0] divisor,
  input wire  CLK_i,
  input wire  RST_i,
  output wire CLK_o
);
   
   // Even divider logic
   reg [8:0]  cnt_even = 0;
   reg 	      clk_even = 0;
   
   // Odd divider logic (dual edge)
   reg [9:0]  cnt_pos = 0;
   reg [9:0]  cnt_neg = 0;
   reg 	      clk_pos = 0;
   reg 	      clk_neg = 0;
   reg [9:0]  count = 0;
   wire       clkn = ~CLK_i;
   
   always @(posedge CLK_i or posedge RST_i) begin
     if (RST_i) begin
        cnt_even <= 10'h0;
        clk_even <= 1'b0;
     end else begin
        if (cnt_even == (divisor[8:1] - 1)) begin
           clk_even <= ~clk_even;
           cnt_even <= 1'b0;
        end else begin
           cnt_even <= cnt_even + 1;
        end
     end
   end // block: even
   
   
            // Toggle clk_r and clk_f on alternating counts
   always @(posedge CLK_i or posedge RST_i) begin
      if (RST_i) begin
         count <= 10'h0;
         clk_pos <= 1'b0;
      end else begin
         if (count == divisor - 1)
           count <= 0;
         else
           count <= count + 1;
         clk_pos <= (count == 0); // Toggle high on count 0
      end
   end // block: odd_divider
   always @(posedge clkn or posedge RST_i) begin
      if (RST_i) begin
         clk_neg <= 1'b0;
      end else begin
         clk_neg <= (count == ((divisor-1) >> 1)); // Toggle high midway
      end
   end
   
   assign CLK_o = divisor[0] ?clk_pos | clk_neg : clk_even;
   
endmodule
