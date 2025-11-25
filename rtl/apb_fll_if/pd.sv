module pd  # (
	       parameter [15:0] RING_TARGET = 1500,
	       parameter [7:0] REF_FREQ = 20
	       )
   (
   input 	     fclk_i, // 1.5 GHz clock
   input wire 	     clk_ref_i, // 20 MHz reference clock
   input wire 	     reset_i, // Reset signal
   output wire 	     plus_o, 
   output wire 	     minus_o,
   output wire [9:0] div_adjust_o
   );
   reg signed [9:0]  div_adjust;
   reg 		     prev_clk_ref, prev_clk_fb;
   reg [9:0] 	     clk_count;
   reg 		     plus,minus;


   localparam signed divref = (RING_TARGET/REF_FREQ);
   
		       
   assign plus_o = plus;
   assign minus_o = minus;
   assign div_adjust_o = div_adjust;
   
   
   
   always @(posedge fclk_i or posedge reset_i) begin
      if (reset_i == 1'b1) begin
	 $display ("RING_TARGET = %d, REF_FREQ = %d DIVREF = %d", RING_TARGET, REF_FREQ, divref);
	 
	 clk_count <= 10'h0;
	 prev_clk_ref <= 0;
         prev_clk_fb <= 0;
	 plus <= 1'b0;
	 minus <= 1'b0;
	 div_adjust <= 10'h0;
      end
      else begin
         prev_clk_ref <= clk_ref_i;
	 if (~prev_clk_ref & clk_ref_i)  begin // rising edge on ref
	    clk_count <= 10'h0;
	    plus <= 1'b0;
	    minus <= 1'b0;
	    if (clk_count > (divref+4)) begin
	       plus <= plus ? 1'b0 : 1'b1;
	       div_adjust <= 10'h0;
	    end
	    else if (clk_count < (divref-4)) begin
	       minus <= minus ? 1'b0 : 1'b1;
	       div_adjust <= 10'h0;
	    end
	    else begin 
	      div_adjust <= clk_count - divref;
	    end
	 end // if (~prev_clk_ref & clk_ref)
	 else begin
	    clk_count <= clk_count + 8'h1;
            if (clk_count == 10'h3ff)
              plus <= plus ? 1'b0 : 1'b1;
	 end // else: !if(~prev_clk_ref & clk_ref)
      end // else: !if(rst == 1'b1)
   end // always @ (posedge clk_i or posedge rst)
endmodule

