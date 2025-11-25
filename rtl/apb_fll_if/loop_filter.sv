
module loop_filter
  (
   input wire 	     clk_i, // System clock (can be clk_ref)
   input wire 	     reset_i, // Reset signal
   output wire [5:0] nco_ctrl_o, // 6-bit NCO control word output
   input wire 	     plus_i, 
   input wire 	     minus_i
		    
);

   reg [5:0] 	     nco_ctrl;
   assign nco_ctrl_o = nco_ctrl;
   
    // Reduced gains for better stability
    always @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
           nco_ctrl <= 6'h20;
        end else begin
	   if (plus_i == 1'b1) begin
	     if (nco_ctrl != 6'h3f) 
	       nco_ctrl <= nco_ctrl + 1;
	   end
	   else if (minus_i == 1'b1)
	     if (nco_ctrl != 6'h0)
	       nco_ctrl <= nco_ctrl - 1;
	end // else: !if(rst)
    end // always @ (posedge clk or posedge rst)
endmodule
