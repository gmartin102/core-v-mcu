module apb (PCLK,PRESETn,PADDR,PPROT,PSEL,PENABLE,PWRITE,PWDATA,PSTRB,
	    PREADY,PSLVERR,PRDATA,stop);
   output [14:0] PADDR;
   output [31:0] PWDATA;
   output [3:0]  PSTRB;
   output [2:0]  PPROT;
   output 	 PSEL, PENABLE, PWRITE;
   input wire    PRESETn;
   
   input 	 PCLK,PREADY, PSLVERR;
 
   input  [31:0] PRDATA;
   input 	 stop;
      
   integer 	 inputfile, count, retval, delay_time, delay;
   integer 	 address_inc, data_inc, loop;
	 
   reg [8:0]	 ctype;  // "c" nonprintable, "C" printable 		 
   reg [80*8:0]  junkline;
   reg [2:0] fsm;
   reg apb_sel, apb_enable, apb_write, apb_reset;
   reg [14:0] apb_address,addr;
   reg 	      rw;
   reg [31:0] apb_wdata;
   reg [3:0] apb_strobe,strobe;
   reg [31:0]  data, mask;
   wire [31:0] apb_rdata;

     
   parameter filename="apb.vec";
   parameter quiet=0;
   parameter START=0;
   parameter IDLE = 1;
   parameter READ = 2;
   parameter WRITE = 3;
   parameter WAIT = 4;
   parameter WAIT_IDLE = 4;
   parameter STOP =5;
   
   always@ (negedge PRESETn) begin
      inputfile = $fopen(filename,"r");
      if (inputfile == 0) begin 
	 $display ("Vector File %s doesn't exist\n",filename);
	 $stop;
      end
      else
	$display ("File %s opened\n",filename);
      
      #0 apb_address  = 0;
      #0 apb_sel = 0;
      #0 apb_enable = 0;
      #0 apb_write = 0;
      #0 apb_wdata = 0;
      #0 apb_strobe = 4'b1111;
      #0 fsm = START;
      #0 delay_time = 0;
      #0 loop = 0; 
   end // initial begin
   
   
   assign PADDR = apb_address;
   assign PWRITE = apb_write;
   assign PPROT = 3;
   assign PENABLE = apb_enable;
   assign PSEL = apb_sel;
   assign PWDATA = apb_wdata;
   //   assign PRESETn = apb_reset;
   assign apb_rdata = PRDATA;
   assign PSTRB = apb_strobe;
   
   initial begin
      #0
	count = 0;
   end
   
   
   always@(posedge PCLK or negedge PRESETn) begin
      if (PRESETn == 1'b0)
        fsm <= IDLE;
      else begin 
         case (fsm)
	   START: begin 
	      if (count <= 50)
	        apb_reset <= 0;
	      else
	        apb_reset <= 1;
	      if (count == 100)
	        fsm <= IDLE;
	      else
	        count = count + 1;
	   end
      	   
	   IDLE: begin
	      apb_write <= 0;
	      apb_enable <= 0;
	      apb_sel <= 0;
	      if (stop == 0) begin
	         if ($time > delay_time) begin
		    if (loop == 0) begin
		       count = $fscanf(inputfile,"%c", ctype);
		       while ((ctype == 8'h63) || (ctype == 8'h43)) begin
		          retval = $fgets(junkline,inputfile);
		          if ((ctype == 8'h43) && !quiet)
			    $display ("%d - %s\n",$time,junkline);
		          count = $fscanf(inputfile,"%c",ctype);
		       end
		       if (count != 1) begin // end of file
		          $fclose(inputfile);
                          fsm <= STOP;
                       end
		       case (ctype)
		         8'h30: begin
			 count = $fscanf(inputfile,"%b %x %x %b\n",rw,addr,data,strobe);
                            if (!quiet)
			      $display("PWRITE = %b Address = %x\n",rw,addr);
			    
			    fsm = rw ? WRITE : READ;
		         end
		         
		         8'h64: begin  // "d delay"
			    count = $fscanf(inputfile,"%d\n",delay);
                            if (!quiet)
			    $display("%d: Delaying %d ns",$time,delay);
			    delay_time = $time + delay;
		         end
		         
		         8'h4C: begin //  Loop "L loopcnt, rw, addr data strobe add_inc data_inc"
			    count = $fscanf(inputfile,"%d %b %x %x %b %x %x\n",loop,rw,addr,data,strobe,address_inc,data_inc);
                            if (!quiet)
			      $display("%d: Looping %d times",$time,loop);
			    
			    fsm <= rw ? WRITE : READ;
			    loop = loop - 1;
		         end
		         
		         8'h77: begin // Wait w address data mask
			    count = $fscanf(inputfile,"%x %x %x\n", addr, data, mask);
                            if (!quiet)
			    $display ("Waiting for addr %x to match %x mask %x\n", addr, data, mask);
			    fsm <= WAIT;
		         end
                         
		         //8'h73: $fclose(inputfile); //$stop;  //  's' stop simulation 
		       endcase // case (ctype)
		    end // if (loop == 0)
		    else begin
		       addr <= addr + address_inc;
		       data <= data + data_inc;
		       loop = loop - 1;
		       fsm <= rw ? WRITE : READ;
		    end
                 end // if ($time > delay_time)
              end // if (stop == 0)
           end // case: IDLE
           
	   
	   WAIT: begin
	      apb_wdata <= 32'h0;
	      apb_address <= addr;
	      apb_sel <= 1;
	      apb_enable <= apb_sel;
	      if (apb_enable == 1) begin
	         if (PREADY == 1) begin
		    apb_enable <= 0;
		    apb_sel <= 0;
		    if (data == (apb_rdata & mask))
		      fsm <= IDLE;
		    else
		      fsm <= WAIT_IDLE;
                 end
              end
           end // case: WAIT
           WAIT_IDLE: begin
	      fsm <= WAIT;
	   end
	   WRITE: begin
	      apb_write <= 1;
	      apb_address <= addr;
	      apb_wdata <= data;
	      apb_sel <= 1;
	      apb_enable <= apb_sel;
	      apb_strobe <= strobe;
	      if (apb_enable == 1) begin
	         if (PREADY == 1) begin
                    //		 $display("%d: Write 0x%x: data= 0x%x",$time,apb_address,apb_wdata);
		    apb_write <= 0;
		    apb_enable <= 0;
		    apb_sel <= 0;
		    fsm <= IDLE;
	         end
                 
	      end
	   end // case: WRITE
	   READ: begin
	      apb_wdata <= 32'h0;
	      apb_address <= addr;
	      apb_sel <= 1;
	      apb_enable <= apb_sel;
	      if (apb_enable == 1) begin
	         if (PREADY == 1) begin
		    if (data != apb_rdata)
		      $display("%d: Read Fail! 0x%x recv=0x%x (%d), expected 0x%x",$time,apb_address,apb_rdata,apb_rdata,data);
		    else if (!quiet)
		      $display("%d: Read Pass! 0x%x recv=0x%x, expected 0x%x",$time,apb_address,apb_rdata,data);
		    apb_enable <= 0;
		    apb_sel <= 0;
		    fsm <= IDLE;
	         end
	      end
	   end // case: READ
	 endcase // case (fsm)
      end // else: !if(PRESETn == 1'b0)
   end // always@ (posedge PCLK or negedge PRESETn)
endmodule // apb
		
		   
	   
	
