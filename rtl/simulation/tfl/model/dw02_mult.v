module DW02_mult (A, B, TC, PRODUCT);
  parameter A_width = 8, B_width = 8;
  input wire [A_width-1:0] A; 
  input wire[B_width-1:0] B; 
  input wire TC; 

  output wire [A_width+B_width-1:0] PRODUCT;
  wire signed [A_width+B_width-1:0] product_sig; 
  wire [A_width+B_width-1:0] product_usig;

  assign product_sig = $signed(A) * $signed(B); 
  assign product_usig = A * B;
  assign PRODUCT = (TC == 1'b1) ? $unsigned(product_sig) : product_usig;
endmodule
