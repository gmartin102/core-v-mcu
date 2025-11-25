`timescale 1ns / 1ps

module clkgen # (
	       parameter [15:0] RING_TARGET = 600,
	       parameter [7:0] REF_FREQ = 10
	       )
  (
   input wire        override_i,
   input wire [5:0]  nco_override_i,
   output wire [5:0] ring_tap_o,
   input wire        clk_ref_i,
   input wire        reset_i,
   input wire        por_i,
   output wire       ref_out_o
   );
   
   wire [5:0] 		    nco_ctrl;
   wire 		    ring_feedback;
   wire 		    ring_out;
   reg signed  [9:0] 	    fb_counter;
   wire signed [9:0] 	    div_adjust;
   wire signed [9:0] 	    adjust;
   reg 			    clk_fb;
   wire plus, minus;
   
   wire [5:0] nco;
   localparam signed [9:0] refdiv = (RING_TARGET/REF_FREQ)/2;

   reg        ring_clk;
`ifdef SIM
   initial ring_clk = 0;
   initial forever #(1000.0/1200.0) ring_clk = ~ring_clk;
   assign div_adjust = 'h0;
   assign ring_tap_o = 6'h0;
`else
   always_comb ring_clk = ring_out;
   ring_osc u_ro 
     (
      .tap_i(nco),
      .ck_i(ring_feedback),
      .ck_o(ring_out),
      .por_i(por_i)
      );

   pd # (
         .RING_TARGET(RING_TARGET),
         .REF_FREQ(REF_FREQ) )
   u_pd 
     (
      .div_adjust_o(div_adjust),
      .plus_o(plus),
      .minus_o(minus),
      .fclk_i (ring_out),
      .clk_ref_i(clk_ref_i),
      .reset_i(reset_i)
      );
   loop_filter u_lf 
     (
      .plus_i(plus),
      .minus_i(minus),
      .clk_i(clk_fb),
      .reset_i(reset_i),
      .nco_ctrl_o(nco_ctrl)
      );
   assign ring_tap_o = nco;
`endif

   assign nco = override_i ? nco_override_i : nco_ctrl;
   assign ring_feedback = reset_i | ~ring_out;
   assign ref_out_o = clk_fb;
   assign adjust = clk_fb ? {div_adjust[9],div_adjust[9:1]} : ({div_adjust[9],div_adjust[9:1]} + {9'h0,div_adjust[0]}) ;
   
   always@(posedge ring_clk or posedge reset_i) begin
      if (reset_i == 1'b1) begin
	 clk_fb <= 1'b0;
	 fb_counter <= 6'h0;
      end
      else begin
	 if (fb_counter == (refdiv + adjust)) begin
	    clk_fb <= ~clk_fb;
	    fb_counter <= 8'b0;
	 end
	 else if (fb_counter > (refdiv + adjust)) begin
	    clk_fb <= ~clk_fb;
	    fb_counter <= 8'b1;
	 end
	 else fb_counter <= fb_counter + 10'h1;
	 
      end
   end // always@ (posedge ring_out or posedge reset_i)
endmodule // tb
