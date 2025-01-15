`timescale 1ns / 1ns
module depth (
 	       input 		 clk, rstn, depth_start
	       output 		 depth_done,
	       input [8:0] 	 width,height,channels,filters,
	       input [19:0] 	 ext_filter_base, ext_pixel_base, 
	       input [19:0] 	 ext_bias_base, ext_result_base,
	       input [15:0] 	 total_pixels,
	       output [5:0] 	 outsel, 

	       output 		 mac_clr, mac_clken,
	       output 		 pixel_wen, filter1_wen,filter2_wen,
	       output 		 bias_wen,

	       output [11:0] 	 bias_raddr, bias_waddr,
	       
	       output [11:0] 	 pixel_raddr, filter_waddr,
	       output [11:0] 	 filter_raddr, pixel_waddr,
	       output [31:0] 	 pixel_wdata, filter_wdata, bias_wdata,
	       input [31:0] 	 pixel_rdata,bias_rdata,
	       input [15:0] 	 mac0_din, mac1_din, mac2_din, mac3_din,
	       output [31:0] 	 tcdm2_wdata,
	       output [19:0] 	 tcdm1_addr, tcdm2_addr, tcdm3_addr,
	       input [31:0] 	 tcdm1_rdata, tcdm2_rdata, tcdm3_rdata,
	       output 		 tcdm1_req, tcdm1_wen,
	       input 		 tcdm1_gnt, tcdm1_valid,
	       output 		 tcdm2_req, tcdm2_wen,
	       input 		 tcdm2_gnt, tcdm2_valid,
	       output 		 tcdm3_req, tcdm3_wen,
	       input 		 tcdm3_gnt, tcdm3_valid,
	       output reg [31:0] mult1_oper, mult2_oper,
	       output [15:0] 	 debug
	       );
   
      parameter RAM_DEPTH = 4096;
   
   
   
   reg [3:0] 			 fsm_depth;  
   reg [11:0] 			 i_filter_raddr, i_pixel_raddr;
   reg [11:0] 			 i_filter_waddr, i_pixel_waddr;
   reg 			     	 i_filter1_wen,i_filter2_wen,i_pixel_wen;
   reg [15:0] 			 bias0,bias1,bias2,bias3;
   reg [5:0] 			 i_outsel;
   reg 			     	 i_mac_clr;
   reg 			     	 write_result, i_depth_done;
   reg [15:0] 			 total_pixels_done;
   reg [8:0] 			 channels_done, filters_done, filters_complete;
   reg [8:0] 			 filters_loaded ;
   reg [8:0] 		     total_filters_done;
   
   reg 			     	 i_mac_clken;
   reg [8:0] 			 channels_loaded;
   reg 			     	 pixel_start, load_more_pixels;
   reg 			     	 load_more_filters;
   
   reg 			     	 filter_start, running;
   reg [31:0] 			 wdata2;
   reg 				 last_start2d;

   
   assign filter_raddr = running ? i_filter_raddr : ~i_filter_waddr;
   assign pixel_raddr = running ? i_pixel_raddr : ~i_pixel_waddr;
   assign mac_clr = i_mac_clr;
   assign mac_clken = i_mac_clken;
   assign outsel = i_outsel;
   assign done2d = i_done2d;
   
   
   reg [2:0] fsm_getfilters, fsm_getbias; 
   reg [3:0] fsm_getpixels;

   parameter gfIDLE = 0;
   parameter gfLOAD = 1;
   parameter gfDONE = 2;
   parameter gfLOADMORE = 3;
   
   parameter gbIDLE = 0;
   parameter gbLOAD = 1;
   parameter gbDONE = 2;
   

   
   reg [19:0] i_tcdm2_raddr,  i_tcdm2_waddr;
   reg [19:0] i_tcdm2_raddr,  i_tcdm2_waddr;
   reg [19:0] i_tcdm3_raddr;
   
   reg [13:0] filter_space_left;
   reg [8:0]  filter_channels, bias_loaded;
   reg 	      i_tcdm2_rreq, i_tcdm2_wen, i_tcdm2_wreq;
   reg 	      i_tcdm3_req, i_tcdm3_wen;
   
   reg [31:0] i_filter_wdata, i_tcdm2_wdata, i_tcdm2_rdata;
   reg [31:0] i_bias_wdata, i_tcdm3_rdata;
   reg [11:0] i_bias_raddr, i_bias_waddr;
   reg 	      i_bias_wen;
   
   reg [12:0] filter_stride, add_stride;
   reg 	      next_buffer, load_ext_acc, copy_acc;
   reg [3:0]  scale0, scale1, scale2, scale3;
   reg [3:0]  scale4, scale5, scale6, scale7;
   reg 	      exp_valid2, err_valid2;
   
   
   
   assign bias_wdata = i_bias_wdata;
   assign bias_raddr = i_bias_raddr;
   assign bias_waddr = i_bias_waddr;
   assign bias_wen = i_bias_wen;
   
   assign tcdm3_req = i_tcdm3_req;
   assign tcdm3_wen = i_tcdm3_wen;
   assign tcdm3_addr = i_tcdm3_raddr;
   
   assign filter_wdata = i_filter_wdata;
   assign tcdm2_req = i_tcdm2_rreq | i_tcdm2_wreq;
   assign tcdm2_wen = i_tcdm2_wen;
   assign tcdm2_addr = i_tcdm2_wen ? i_tcdm2_raddr : i_tcdm2_waddr;
   assign filter_waddr = i_filter_waddr;
   assign filter1_wen = i_filter1_wen;
   assign filter2_wen = i_filter2_wen;
   assign tcdm2_wdata = i_tcdm2_wdata;
   
   always@(posedge clk or negedge rstn) begin
      if (rstn == 0) begin
	 filters_loaded <= 0;
	 filter_stride <= 0;
	 add_stride <= 0;
	 fsm_getfilters <= gfIDLE;
	 fsm_getbias <= gbIDLE;
	 fsm_loadacc <= laIDLE;
	 bias0 <= 0;
	 bias1 <= 0;
	 bias2 <= 0;
	 bias3 <= 0;
	 bias4 <= 0;
	 bias5 <= 0;
	 bias6 <= 0;
	 bias7 <= 0;
	 i_tcdm2_raddr <= ext_filter_base;
	 i_tcdm2_waddr <= ext_result_base;
	 i_tcdm2_wdata <= 0;
	 wdata2 <= 0;
	 i_tcdm3_raddr <= ext_bias_base;
	 i_bias_raddr <= 11'h00; //middle of oper2
	 i_bias_waddr <= 11'h200;
	 bias_loaded <= 0;
	 i_tcdm2_rreq <= 0;
	 i_tcdm2_wreq <= 0;
	 i_tcdm3_req <= 0;
	 i_tcdm3_wen <= 0;
	 i_bias_wen <= 0;
	 i_bias_wdata <= 0;
	 
	 i_filter_waddr <= 0;
	 i_filter_wdata <= 0;
	 i_filter1_wen <= 0;
	 i_filter2_wen <= 0;
	 
	 filter_channels <= 0;
	 i_tcdm2_wen <= 1;
	 filter_start <= 0;
	 filter_space_left <= RAM_DEPTH; 
	 filters_complete <= 0;
	 fsm_writechannels <= wcIDLE;
	 last_start2d <= 0;
	 exp_valid2 <= 0;
	 err_valid2 <= 0;
	 fract0 <= 0;
	 fract1 <= 0;
	 fract2 <= 0;
	 fract3 <= 0;
	 fract4 <= 0;
	 fract5 <= 0;
	 fract6 <= 0;
	 fract7 <= 0;
	 reset_bias_address <= 0;
      end
      else begin
   reg [15:0] pixels_read;
   reg [19:0] i_tcdm1_addr;
   
   reg 	      i_tcdm1_req, i_tcdm1_wen;
   reg [31:0] i_pixel_wdata, i_tcdm1_rdata;
   
   assign pixel_wdata = i_pixel_wdata;
   assign tcdm1_req = i_tcdm1_req;
   assign tcdm1_wen = i_tcdm1_wen;
   assign tcdm1_addr = i_tcdm1_addr;
   assign pixel_waddr = i_pixel_waddr;
   assign pixel_wen = i_pixel_wen;
   
   parameter gpIDLE = 0;
   parameter gpLOAD = 1;   
   parameter gpDONE = 2;
   parameter gpWAIT = 3;
   
   reg [1:0]  buffers_used;
   reg 	      load_buffer;
   
   
   always@(posedge clk or negedge rstn) begin
      if (rstn == 0) begin
	 fsm_getpixels <= gpIDLE;
	 pixels_read <= 0;
	 i_tcdm1_addr <= ext_pixel_base;
	 i_tcdm1_wen <= 0;
	 i_tcdm1_req <= 0;
	 i_pixel_wen <=0;
	 i_pixel_waddr <=0;
	 i_pixel_wdata <=0;
	 pixel_start <= 0;
	 buffers_used <= 0;
	 load_buffer <= 0;
	 
	 
      end
      else begin
	 // new getpixels
	 i_tcdm1_rdata <= tcdm1_rdata;
	 
	 case (fsm_getpixels)
	   gpIDLE: begin
	      pixels_read <= 0;
	      i_pixel_waddr <=0;
	      load_buffer <= 0;
	      pixel_start <= 0;
	      i_tcdm1_addr <= ext_pixel_base;
	      buffers_used <= 2'b00;//  both channel buffers empty
	      if (depth_start == 1) begin
		 fsm_getpixels <= gpLOAD1;
		 i_tcdm1_req <= 1;
		 i_tcdm1_wen <= 1;
	      end
	   end // case: qpIDLE
	   gpLOAD1: begin
	      if ((tcdm1_gnt == 1) && (i_tcdm1_req == 1)) begin
		 i_tcdm1_req <= 0;
		 i_tcdm1_wen <= 0;
	      end
	      if (tcdm1_valid == 1) begin
		 i_pixel_wdata <= i_tcdm1_rdata;
		 i_tcdm1_addr <= i_tcdm1_addr + 4;
		 i_pixel_wen <= 1;
		 channels_loaded <= channels_loaded + 4;
		 if ((channels_loaded + 4) == channels) begin
		    buffers_used[load_buffer] <= 1;
		    load_buffer <= ~load_buffer;
		    channels_loaded <= 0;
		    pixels_read <= pixels_read + 1;
		    pixel_start <= 1;
		    if ((pixels_read + 1) == total_pixels)  begin
		       fsm_getpixels <= gpDONE;
		       pixel_start <= 0;
		    end
		    else begin
		      fsm_getpixels <= gpWAIT;
		    end
		    
		 end // if ((channels_loaded + 4) == channels)
		 else begin
		    i_tcdm1_req <= 1;
		    i_tcdm1_wen <= 1;
		 end // else: !if((channels_loaded + 4) == channels)
	      end // if (tcdm1_valid == 1)
	   end // case: gpLOAD
	   gpDONE: begin
	      if (load_more_filters == 1) begin
		 fsm_getpixels <= gpIDLE;
	      end
	      if (done2d == 1) begin
		 fsm_getpixels <= gpIDLE;
	      end
	   end
	   gpWAIT: begin
	      if (load_buffer == 0) begin // last buffer
		 i_pixel_waddr <= 0;
	      end
	      if (buffers_used[load_buffer] == 0) begin
		 fsm_getpixels <= gpLOAD;
		 i_tcdm1_req <= 1;
		 i_tcdm1_wen <= 1;
	      end
	      if (load_more_pixels == 1) begin
		 buffers_used[load_buffer] <= 0;
	      end
	   end
	 endcase // case (fsm_getpixels)
      end // else: !if(rstn == 0)
   end // always@ (posedge clk or negedge rstn)
	 
	 
	 case (fsm_writechannels)
	   wcIDLE: begin
	      if (load_more_pixels == 1)
		add_stride <= filter_stride + 4;
	      else
		add_stride <= 4;
	      
	      if (write2 == 1) begin
		 fsm_writechannels <= wcSTART;
	      end
	   end
	   
	   wcSTART: begin
 		 case (scale0)
		   4'd6: i_tcdm2_wdata[31:24] <= acc0[13:6];
		   4'd7: i_tcdm2_wdata[31:24] <= acc0[14:7];
		   4'd8: i_tcdm2_wdata[31:24] <= acc0[15:8];
		   4'd9: i_tcdm2_wdata[31:24] <= acc0[16:9];
 		   4'd10: i_tcdm2_wdata[31:24] <= acc0[17:10];
		   default:  i_tcdm2_wdata[31:24] <= acc0[7:0];
 		 endcase // case scale0
		 case (scale1)
		   4'd6: i_tcdm2_wdata[23:16] <= acc1[13:6];
		   4'd7: i_tcdm2_wdata[23:16] <= acc1[14:7];
		   4'd8: i_tcdm2_wdata[23:16] <= acc1[15:8];
		   4'd9: i_tcdm2_wdata[23:16] <= acc1[16:9];
 		   4'd10: i_tcdm2_wdata[23:16] <= acc1[17:10];
		   default:  i_tcdm2_wdata[23:16] <= acc1[7:0];

		 endcase // case scale0
		 case (scale2)
		   4'd6: i_tcdm2_wdata[15:8] <= acc2[13:6];
		   4'd7: i_tcdm2_wdata[15:8] <= acc2[14:7];
		   4'd8: i_tcdm2_wdata[15:8] <= acc2[15:8];
		   4'd9: i_tcdm2_wdata[15:8] <= acc2[16:9];
 		   4'd10: i_tcdm2_wdata[15:8] <= acc2[17:10];
		   default:  i_tcdm2_wdata[15:8] <= acc2[7:0];

		 endcase // case scale0
		 case (scale3)
		   4'd6: i_tcdm2_wdata[7:0] <= acc3[13:6];
		   4'd7: i_tcdm2_wdata[7:0] <= acc3[14:7];
		   4'd8: i_tcdm2_wdata[7:0] <= acc3[15:8];
		   4'd9: i_tcdm2_wdata[7:0] <= acc3[16:9];
 		   4'd10: i_tcdm2_wdata[7:0] <= acc3[17:10];
		   default:  i_tcdm2_wdata[7:0] <= acc3[7:0];

		 endcase // case scale0
		 case (scale4)
		   4'd6: wdata2[31:24] <= acc4[13:6];
		   4'd7: wdata2[31:24] <= acc4[14:7];
		   4'd8: wdata2[31:24] <= acc4[15:8];
		   4'd9: wdata2[31:24] <= acc4[16:9];
 		   4'd10: wdata2[31:24] <= acc4[17:10];
		   default:  wdata2[31:24] <= acc4[7:0];

		 endcase // case scale0
		 case (scale5)
		   4'd6: wdata2[23:16] <= acc5[13:6];
		   4'd7: wdata2[23:16] <= acc5[14:7];
		   4'd8: wdata2[23:16] <= acc5[15:8];
		   4'd9: wdata2[23:16] <= acc5[16:9];
 		   4'd10: wdata2[23:16] <= acc5[17:10];
		   default:  wdata2[23:16] <= acc5[7:0];

		 endcase // case scale0
		 case (scale6)
		   4'd6: wdata2[15:8] <= acc6[13:6];
		   4'd7: wdata2[15:8] <= acc6[14:7];
		   4'd8: wdata2[15:8] <= acc6[15:8];
		   4'd9: wdata2[15:8] <= acc6[16:9];
 		   4'd10: wdata2[15:8] <= acc6[17:10];
		   default:  wdata2[15:8] <= acc6[7:0];

		 endcase // case scale0
		 case (scale7)
		   4'd6: wdata2[7:0] <= acc7[13:6];
		   4'd7: wdata2[7:0] <= acc7[14:7];
		   4'd8: wdata2[7:0] <= acc7[15:8];
		   4'd9: wdata2[7:0] <= acc7[16:9];
 		   4'd10: wdata2[7:0] <= acc7[17:10];
		   default:  wdata2[7:0] <= acc7[7:0];
		 endcase // case scale0
//		 if (i_tcdm2_rreq == 0) begin
	      i_tcdm2_wreq <= 1;
	      fsm_writechannels <= wcWRITE1;
//		 end
//		 else
//		   fsm_writechannels <= wcWAIT1;
	   end // case: wcIDLE
	   wcWAIT1: begin
	      if (i_tcdm2_rreq == 0) begin
		 i_tcdm2_wreq <= 1;
		 fsm_writechannels <= wcWRITE1;
	      end
	   end
	   wcWRITE1: begin
	      if (tcdm2_gnt && i_tcdm2_wreq) begin
		 i_tcdm2_wreq <= 0;
	      end
	      if (tcdm2_valid == 1) begin
		 i_tcdm2_waddr <= i_tcdm2_waddr + 4;
		 i_tcdm2_wdata <= wdata2;
//		 if (i_tcdm2_rreq == 0) begin
		    i_tcdm2_wreq <= 1;
		    fsm_writechannels <= wcWRITE2;
//		 end
//		 else begin
//		    i_tcdm2_wreq <= 0;
//		    fsm_writechannels <= wcWAIT2;
//                 end
	      end
	   end // case: wcWRITE1
	   wcWAIT2: begin
	      if (i_tcdm2_rreq == 0) begin
		 i_tcdm2_wreq <= 1;
		 fsm_writechannels <= wcWRITE2;
	      end
	   end
	   wcWRITE2: begin
	      if (tcdm2_gnt && i_tcdm2_wreq) begin
		 i_tcdm2_wreq <= 0;
	      end
	      if (tcdm2_valid == 1) begin
		 i_tcdm2_waddr <= i_tcdm2_waddr + add_stride;
		 add_stride <= 4; // reset to default add
		 fsm_writechannels <= wcIDLE;
	      end
	   end // case: wcWRITE2
	 endcase // case (fsm_writechannels)
	 
	 
	 if (i_bias_wen) begin
	    i_bias_wen <= 0;
	    i_bias_waddr <= i_bias_waddr + 4;
	 end
	 i_tcdm3_rdata <= tcdm3_rdata;

	 case (fsm_getbias)
	   gbIDLE: begin
	      i_bias_waddr <= 11'h200;
	      i_tcdm3_raddr <= ext_bias_base;
	      if (start2d == 1) begin
		 i_tcdm3_req <= 1;
		 i_tcdm3_wen <= 1;
		 bias_loaded <= 0;
		 fsm_getbias <= gbLOAD;
	      end
	   end
	   gbLOAD: begin
	      if ((tcdm3_gnt == 1) && (i_tcdm3_req == 1)) begin
		 i_tcdm3_req <= 0;
		 i_tcdm3_wen <= 1;
	      end
	      if (tcdm3_valid == 1) begin
		 i_bias_wdata <= i_tcdm3_rdata;	 
		 i_tcdm3_wen <= 1;	     
		 i_tcdm3_raddr <= i_tcdm3_raddr + 4;
		 if (bias_loaded == filters+(filters>>1)) begin
		    fsm_getbias <= gbDONE;
		 end else begin
		    i_tcdm3_req <= 1;

		    i_bias_wen <= 1;
		    bias_loaded <= bias_loaded + 1;
		 end
	      end
	   end // case: gbLOAD
	   gbDONE: begin
	      if (done2d == 1) begin
		 bias_loaded <= 0;
		 fsm_getbias <= gbIDLE;
	      end
	   end
	 endcase // case (fsm_getbias)

	 i_tcdm2_rdata <= tcdm2_rdata; // Align data with Valid
	 if (tcdm2_req) begin
	    err_valid2 <= exp_valid2;
	    exp_valid2 <= 1;
	 end
	 if (tcdm2_valid) begin
	    err_valid2 <= ~exp_valid2;
	    exp_valid2 <= 0;
	 end
	 
	 
	 case (fsm_getfilters)
	   gfIDLE: begin
	      i_filter_waddr <= 0;
	      filter_space_left <= RAM_DEPTH; 
	      filter_stride <= filters;
	      if (start2d == 1) begin
		 i_tcdm2_raddr <= ext_filter_base;
		 i_tcdm2_rreq <= 1;
		 i_tcdm2_wen <= 1;
		 filter_channels <= 0;
		 fsm_getfilters <= gfLOAD;
	      end
	   end
	   gfLOAD: begin
	      if (i_filter1_wen) begin
	      	 i_filter_waddr <= i_filter_waddr + 2; // futzing to deal with 2 coef RAMs
	      end
	      if (i_filter2_wen) begin
		 filter_space_left <= filter_space_left - 8;
		 i_filter_waddr <= i_filter_waddr + 2; // futzing to deal with 2 coef RAMs
	      end
	      if ((tcdm2_gnt == 1) && (i_tcdm2_rreq == 1)) begin
		 i_tcdm2_rreq <= 0;
		 i_tcdm2_wen <= 1;
	      end
	      if (tcdm2_valid == 1) begin // todo validate with rreq
		 i_filter_wdata <= i_tcdm2_rdata;
		 i_tcdm2_raddr <= i_tcdm2_raddr + 4;
		 i_filter1_wen <= ~i_filter_waddr[1];
		 i_filter2_wen <= i_filter_waddr[1];
		 if (i_tcdm2_raddr[2] != ext_filter_base[2]) begin
		    filter_channels <= filter_channels + 1;
		    if ((filter_channels + 1) == channels) begin
		       filter_stride <= filter_stride - 8;
		       filters_loaded <= filters_loaded + 8;
		       filters_complete <= filters_complete + 8;
		       if ( ((filters_complete + 8) < filters) && 
			    (filter_space_left >= (channels << 3))) begin
			  i_tcdm2_rreq <= 1;
			  i_tcdm2_wen <= 1;
			  filter_channels <= 0;
		       end // if ((filters_complete + 8 < filters) &&...
		       else begin
			  i_tcdm2_rreq <= 0;
			  i_tcdm2_wen <= 0;
			  filter_channels <= 0;
			  filter_start <= 1;
			  fsm_getfilters <= gfDONE;		       
		       end
		    end // if ((filter_channels + 1) == channels)
		    else begin
		       i_tcdm2_rreq <= 1;
		       i_tcdm2_wen <= 1;
		    end // else: !if((filter_channels + 1) == channels)
		 end // if (i_tcdm2_addr[2] == 1)
		 else begin
		    i_tcdm2_rreq <= 1;
		    i_tcdm2_wen <= 1;
		 end // else: !if((filter_channels + 1) == channels)
	      end // if (i_tcdm2_raddr[2] == 1)
	   end // case: gfLOAD
	   gfLOADMORE: begin
	      if (i_filter1_wen) begin
	      	 i_filter_waddr <= i_filter_waddr + 2; // futzing to deal with 2 coef RAMs
	      end
	      if (i_filter2_wen) begin
		 filter_space_left <= filter_space_left - 8;
		 i_filter_waddr <= i_filter_waddr + 2; // futzing to deal with 2 coef RAMs
	      end
	      if ((tcdm2_gnt == 1) && (i_tcdm2_rreq == 1)) begin
		 i_tcdm2_rreq <= 0;
		 i_tcdm2_wen <= 1;
	      end
	      if (tcdm2_valid == 1) begin // todo validate with rreq
		 i_filter_wdata <= i_tcdm2_rdata;
		 i_tcdm2_raddr <= i_tcdm2_raddr + 4;
		 i_filter1_wen <= ~i_filter_waddr[1];
		 i_filter2_wen <= i_filter_waddr[1];
		 if (i_tcdm2_raddr[2] == 1) begin
		    filter_channels <= filter_channels + 1;
		    if ((filter_channels + 1) == channels) begin
		       filters_loaded <= filters_loaded + 8;
		       filters_complete <= filters_complete + 8;
		       if ((filters_complete + 8 < filters) && (filter_space_left >= (channels << 3))) begin
			  i_tcdm2_rreq <= 1;
			  i_tcdm2_wen <= 1;
			  filter_channels <= 0;
		       end // if ((filters_complete + 8 < filters) &&...
		       else begin
			  i_tcdm2_rreq <= 0;
			  i_tcdm2_wen <= 0;
			  filter_channels <= 0;
			  filter_start <= 1;
			  fsm_getfilters <= gfDONE;		       
		       end
		    end // if ((filter_channels + 1) == channels)
		    else begin
		       i_tcdm2_rreq <= 1;
		       i_tcdm2_wen <= 1;
		    end // else: !if((filter_channels + 1) == channels)
		 end // if (i_tcdm2_addr[2] == 1)
		 else begin
		    i_tcdm2_rreq <= 1;
		    i_tcdm2_wen <= 1;
		 end // else: !if((filter_channels + 1) == channels)
	      end // if (i_tcdm2_raddr[2] == 1)
	   end // case: gfLOAD

	   gfDONE: begin
	      if (running)
		 filter_start <= 0;
	      if ((load_more_filters) && (i_tcdm2_wreq == 0)) begin

		 filter_space_left <= RAM_DEPTH;  
		 filters_loaded <= 0;
		 filter_channels <= 0;
		 i_tcdm2_rreq <= 1;
		 i_tcdm2_wen <= 1;
		 fsm_getfilters <= gfLOADMORE;
		 if (filters_complete == filters) begin
		    filters_complete <=0;		 
		 end
	      end // if (load_more_filters)
	      if (done2d == 1) begin
		 fsm_getfilters <= gfIDLE;
	      end
	   end // case: gfDONE	   
	 endcase // case (fsm_getfilters)
      end // else: !if(rstn == 0)
   end // always@ (posedge clk or negedge rstn)
   
   
   
   parameter fsm_IDLE  = 0;
   parameter fsm_SOP   = 1;
   parameter fsm_SOP8  = 2;
   parameter fsm_SOP16 = 3;
   parameter fsm_SOP24 = 4;
   parameter fsm_DONE  = 5;
   parameter fsm_WAIT2 = 6;
   parameter fsm_NEXT  = 7;
   parameter fsm_SOP1  = 8;
   
   wire [23:0] k24acc0, k24acc1, k24acc2, k24acc3;
   wire [23:0] k24acc4, k24acc5, k24acc6, k24acc7;
   wire [15:0] k16acc0, k16acc1, k16acc2, k16acc3;
   wire [15:0] k16acc4, k16acc5, k16acc6, k16acc7;
   
   ksa # (.WIDTH(24)) k0 (.a(bias0),.b({16'b0,mac0_din}),.sum(k24acc0),.cout());
   ksa # (.WIDTH(24)) k1 (.a(bias1),.b({16'b0,mac1_din}),.sum(k24acc1),.cout());
   ksa # (.WIDTH(24)) k2 (.a(bias2),.b({16'b0,mac2_din}),.sum(k24acc2),.cout());
   ksa # (.WIDTH(24)) k3 (.a(bias3),.b({16'b0,mac3_din}),.sum(k24acc3),.cout());
   ksa # (.WIDTH(24)) k4 (.a(bias4),.b({16'b0,mac4_din}),.sum(k24acc4),.cout());
   ksa # (.WIDTH(24)) k5 (.a(bias5),.b({16'b0,mac5_din}),.sum(k24acc5),.cout());
   ksa # (.WIDTH(24)) k6 (.a(bias6),.b({16'b0,mac6_din}),.sum(k24acc6),.cout());
   ksa # (.WIDTH(24)) k7 (.a(bias7),.b({16'b0,mac7_din}),.sum(k24acc7),.cout());
   
   ksa # (.WIDTH(16)) k16_0 (.a(acc0[23:8]),.b({8'b0,mac0_din}),.sum(k16acc0),.cout());
   ksa # (.WIDTH(16)) k16_1 (.a(acc1[23:8]),.b({8'b0,mac1_din}),.sum(k16acc1),.cout());
   ksa # (.WIDTH(16)) k16_2 (.a(acc2[23:8]),.b({8'b0,mac2_din}),.sum(k16acc2),.cout());
   ksa # (.WIDTH(16)) k16_3 (.a(acc3[23:8]),.b({8'b0,mac3_din}),.sum(k16acc3),.cout());
   ksa # (.WIDTH(16)) k16_4 (.a(acc4[23:8]),.b({8'b0,mac4_din}),.sum(k16acc4),.cout());
   ksa # (.WIDTH(16)) k16_5 (.a(acc5[23:8]),.b({8'b0,mac5_din}),.sum(k16acc5),.cout());
   ksa # (.WIDTH(16)) k16_6 (.a(acc6[23:8]),.b({8'b0,mac6_din}),.sum(k16acc6),.cout());
   ksa # (.WIDTH(16)) k16_7 (.a(acc7[23:8]),.b({8'b0,mac7_din}),.sum(k16acc7),.cout());

   always@(posedge clk or negedge rstn) begin
      if (rstn == 1'b0) begin // reset stuff
	 fsm_conv2d <= fsm_IDLE; 
	 i_mac_clr <= 1'b1;
	 i_mac_clken <= 1;
	 i_outsel <= 6'b000000;
	 i_pixel_raddr <= 11'd0;
	 i_filter_raddr <= 11'd0;
	 channels_done <= 0;
	 filters_done <=0;
	 	 total_filters_done <=0;
	 i_done2d <= 0;
	 running <= 0;
	 load_more_filters <= 0;
	 load_more_pixels <= 0;
	 total_pixels_done <= 0;
	 load_ext_acc <= 0;
	 copy_acc <= 0;
	 acc0 <= 0;
	 acc1 <= 1;
	 acc2 <= 2;
	 acc3 <= 3;
	 acc4 <= 4;
	 acc5 <= 5;
	 acc6 <= 6;
	 acc7 <= 7;
	 next_buffer <= 0;
	 pixel_select <= 0;
	 write2 <= 0;
      end
      else begin
	 copy_acc <= 0;
	 load_ext_acc <= 0;
	 write2 <= 0;
	 i_outsel <= 0;
	 if (start2d == 0) begin
	    total_pixels_done <= 0;

	 end // else: !if(rstn == 1'b0)
	 if (write2 == 1) begin
	    acc0[23:16] <= acc0[23:16] + {{4{mac0_din[7]}},mac0_din[7:4]};
	    acc1[23:16] <= acc1[23:16] + {{4{mac1_din[7]}},mac1_din[7:4]};
	    acc2[23:16] <= acc2[23:16] + {{4{mac2_din[7]}},mac2_din[7:4]};
	    acc3[23:16] <= acc3[23:16] + {{4{mac3_din[7]}},mac3_din[7:4]};
	    acc4[23:16] <= acc4[23:16] + {{4{mac4_din[7]}},mac4_din[7:4]};
	    acc5[23:16] <= acc5[23:16] + {{4{mac5_din[7]}},mac5_din[7:4]};
	    acc6[23:16] <= acc6[23:16] + {{4{mac6_din[7]}},mac6_din[7:4]};
	    acc7[23:16] <= acc7[23:16] + {{4{mac7_din[7]}},mac7_din[7:4]};
	 end
	 case (fsm_conv2d)
	   fsm_NEXT: begin
	      load_more_pixels <= 0;
	      i_outsel <= 0;
	      pixel_select <= 2'b00;
	      running <= 1;
	      channels_done <= 0;
	      if (running == 1) begin 
		 fsm_conv2d <= fsm_WAIT2;
	      end
	      
	   end
	   fsm_IDLE: begin
              i_done2d <= 0;
	      next_buffer <= 1;
	      i_mac_clr <= 1'b1;
	      i_mac_clken <= 1;
	      i_pixel_raddr <= 11'd0;
	      i_filter_raddr <= 11'd0;
	      i_outsel <= 0;
	      pixel_select <= 2'b00;
	      load_more_filters <= 0;
		 load_more_pixels <= 0;
	      if ((pixel_start == 1) && (filter_start == 1)) begin
//		 total_filters_done <= filters_loaded;

		 running <= 1;
		 channels_done <= 0;
		 fsm_conv2d <= fsm_WAIT2;
	      end
	   end // case: fsm_IDLE
	   fsm_WAIT2: begin
	      i_filter_raddr <= i_filter_raddr + 4;
	      load_ext_acc <= 1;
	      fsm_conv2d <= fsm_SOP;
	   end
	   fsm_SOP1: begin

	      acc0[23:16] <= acc0[23:16] + {{4{mac0_din[7]}},mac0_din[7:4]};
	      acc1[23:16] <= acc1[23:16] + {{4{mac1_din[7]}},mac1_din[7:4]};
	      acc2[23:16] <= acc2[23:16] + {{4{mac2_din[7]}},mac2_din[7:4]};
	      acc3[23:16] <= acc3[23:16] + {{4{mac3_din[7]}},mac3_din[7:4]};
	      acc4[23:16] <= acc4[23:16] + {{4{mac4_din[7]}},mac4_din[7:4]};
	      acc5[23:16] <= acc5[23:16] + {{4{mac5_din[7]}},mac5_din[7:4]};
	      acc6[23:16] <= acc6[23:16] + {{4{mac6_din[7]}},mac6_din[7:4]};
	      acc7[23:16] <= acc7[23:16] + {{4{mac7_din[7]}},mac7_din[7:4]};
	      copy_acc <= 1;
	      i_filter_raddr <= i_filter_raddr + 4;
	      fsm_conv2d <=  fsm_SOP;
	   end // case: fsm_SOP1
	   fsm_SOP: begin
	      i_mac_clr <= 0;
	      if(pixel_select == 2) begin
		 i_pixel_raddr <= i_pixel_raddr + 4;
	      end
	      pixel_select <= pixel_select+1;
//	      i_filter_raddr <= i_filter_raddr + 4;
	      if (pixel_select == 2'd3) begin
		 channels_done <= channels_done + 4;
		 if ( ((channels_done+4) == channels) || (channels_done[3:0] == 4'b1100) ) begin
//		    if ((channels_done+4) == channels) begin
//		       if ((filters_done + 8) == filters_loaded) begin
//			  i_filter_raddr <= 0;
//		       end
//		    end
		    
		    i_mac_clken <= 0;
		    fsm_conv2d <= fsm_SOP8;
		    i_outsel <= 6'h8;  // get the high 8-bits
		 end // if ( ((channels_done+4) == channels) || (channels_done[3:0] == 4'b1100) )
		 else begin
		    i_filter_raddr <= i_filter_raddr + 4;
		 end
	      end // if (pixel_select == 2'd3)
	      else begin
		 i_filter_raddr <= i_filter_raddr + 4;
	      end // else: !if(pixel_select == 2'd3)
	      
	   end // case: fsm_SOP
	   fsm_SOP8: begin
	      i_outsel <= 6'd12;  // Get the 4 overflow bits
	      fsm_conv2d <= fsm_SOP16;
	      if (channels_done == channels) begin
		 filters_done <= filters_done + 8;
		 if ((filters_done + 8) == filters_loaded) begin
		    i_filter_raddr<= 0;
		 end		    
	      end
	   end // case: fsm_SOP8
	   fsm_SOP16: begin
	      acc0 <= k24acc0; //acc0 + mac0_din;
	      acc1 <= k24acc1; //acc1 + mac1_din;
	      acc2 <= k24acc2; //acc2 + mac2_din;
	      acc3 <= k24acc3; //acc3 + mac3_din;
	      acc4 <= k24acc4; //acc4 + mac4_din;
	      acc5 <= k24acc5; //acc5 + mac5_din;
	      acc6 <= k24acc6; //acc6 + mac6_din;
	      acc7 <= k24acc7; //acc7 + mac7_din;
	      i_outsel <= 6'd0;
	      fsm_conv2d <= fsm_SOP24;
	      if (filters_done == filters_loaded) begin
		 total_pixels_done <= total_pixels_done+1;
	      end
	   end // case: fsm_SOP16
	   fsm_SOP24: begin
	      acc0[23:8] <= k16acc0;//acc0 + {mac0_din,8'b0};
	      acc1[23:8] <= k16acc1;//acc1 + {mac1_din,8'b0};
	      acc2[23:8] <= k16acc2;//acc2 + {mac2_din,8'b0};
	      acc3[23:8] <= k16acc3;//acc3 + {mac3_din,8'b0};
	      acc4[23:8] <= k16acc4;//acc4 + {mac4_din,8'b0};
	      acc5[23:8] <= k16acc5;//acc5 + {mac5_din,8'b0};
	      acc6[23:8] <= k16acc6;//acc6 + {mac6_din,8'b0};
	      acc7[23:8] <= k16acc7;//acc7 + {mac7_din,8'b0};
	      // Default Action
	      i_mac_clken <= 1;
	      i_mac_clr <= 1'b1;
	      // Completion of 1 pixel for 8 filters
	      if (channels_done == channels) begin
		 write2 <= 1;  // write 8 filter results via tcdm
		 if (filters_done < filters_loaded) begin
		    i_pixel_raddr <= i_pixel_raddr - (channels); // rewind pixel ram
		    fsm_conv2d <= fsm_NEXT;
		 end
		 else begin // filters done == filters loaded
		    if (total_pixels_done == total_pixels)  begin
		       total_pixels_done <= 0;
			 if  ((total_filters_done + filters_loaded)
			      == filters) begin
			    fsm_conv2d <= fsm_DONE;
			 end
			 else begin
			    total_filters_done <= total_filters_done + filters_loaded;
			    load_more_pixels <= 1;
			    load_more_filters <= 1;
			    filters_done <= 0;
			    fsm_conv2d <= fsm_IDLE;
			    
			 end
                    end
		    
		    else begin
		       if (next_buffer == 0) begin
			  i_pixel_raddr <= 0;
		       end
		       filters_done <= 0;
		       load_more_pixels <= 1;
		       next_buffer <= ~next_buffer;
		       fsm_conv2d <= fsm_NEXT;
		    end // else: !if(total_pixels_done == total_pixels)
		 end // else: !if(filters_done < filters_loaded)
	      end // if (channels_done == channels)
	      else begin
		 fsm_conv2d <= fsm_SOP1;
	      end
	   end // case: fsm_SOP24
	   fsm_DONE: begin
	      i_done2d <= 1;
	      if (start2d == 0)
		fsm_conv2d <= fsm_IDLE;
	   end
	 endcase // case (fsm_conv2d)
      end // else: !if(rstn == 1'b0)
   end // always@ posedge(clk
//   reg [7:0] i_debug;
   
//   assign debug = i_debug;
//   always @ (posedge clk) begin 
   
   
//   assign debug[3:0] = fsm_conv2d;
//   assign debug = mac0_din;
   
//   assign debug = 8'b0;
//   assign debug[3:0] = {start2d,pixel_start,filter_start,done2d};
 
   assign debug[7:1] = acc4[7:1];
   assign debug[0] = filter_start;
   assign debug[10:8] = fsm_writechannels[2:0];
   assign debug[11] = fsm_loadacc;
   assign   debug[12] = i_filter1_wen;
   assign   debug[15:13] = fsm_getpixels[2:0];
   
//   end
   
   

endmodule // conv2d

