// Example output, with parameters k=4, p=1, b=8, g=0

module conv_2D(X, H, clk, reset, load_h, load_x, start, done, data_in, data_out);

	input clk, reset, start, load_h, load_x;
	input [9:0] X;
	input [2:0] H;
	output done;
	input signed[7:0] data_in;
	output signed [15:0] data_out;	
	logic wr_en_h ,wr_en_x,wr_en_y,clear_acc;
	logic [9:0] addr_x;
	logic [9:0] addr_y;
	logic [5:0] addr_h;
// Instantation of Data and Conntrol Path 
	datapath d(clk, data_in,addr_x,wr_en_x,addr_h,wr_en_h,addr_y,wr_en_y,clear_acc,data_out);
	ctrlpath c(X, H, clk, reset, start, addr_x, wr_en_x, addr_h, wr_en_h, clear_acc, addr_y, wr_en_y,done, load_h, load_x);

endmodule

/*Defining the Memory Module - This module is further instantiated in datapath*/

module memory(clk, data_in, data_out, addr, wr_en);
	parameter WIDTH=16, SIZE=64, LOGSIZE=6;
	input [WIDTH-1:0] data_in;
	output logic [WIDTH-1:0] data_out;
	input [LOGSIZE-1:0] addr;
	input clk, wr_en;
	logic [SIZE-1:0][WIDTH-1:0] mem;
		always_ff @(posedge clk) begin
			data_out <= mem[addr];
			if (wr_en)
			mem[addr] <= data_in;
		end
endmodule


/* Data Path Contains
 Memory for column matrix
	Memory for Vector matrix
	Memory for Destination Matrix
	Multiply and accumulate block*/
module datapath(clk, data_in,addr_x,wr_en_x,addr_h,wr_en_h,addr_y,wr_en_y,clear_acc,data_out);
	input clk;
	input logic clear_acc , wr_en_h , wr_en_x, wr_en_y;
	input signed [7:0] data_in;
	input logic[5:0] addr_h;
	input logic[9:0] addr_x;
	input logic[9:0] addr_y;
	output logic[15:0] data_out;
	logic signed[15:0] f,mul_out,add_r;
	logic signed [7:0] data_out_h , data_out_x;
	/*Memory Instantion*/
	memory #(8, 1024, 10) mem_x(clk, data_in, data_out_x, addr_x, wr_en_x); // memory Instantaion for x column vector and has k memory location each having bit word length of 8 bits.
	memory #(8, 64, 6) mem_h(clk, data_in, data_out_h, addr_h, wr_en_h); // memory Instantation k*k matrix and has k*k memory location each having bit word length of 8 bits.
	memory #(16, 1024, 10) mem_y(clk, f, data_out, addr_y, wr_en_y);  // memory instantation of y column vector and has k memory location each having bit word length of 16 bits.
	// Multiply and Accumulate Block
	always_ff @ (posedge clk) begin

		if(clear_acc == 1) begin
			f <= 0;
			end
		else begin
			f <= add_r;
			end
	end
	always_comb begin
		mul_out = data_out_h * data_out_x;
		add_r = f + mul_out;
	end

endmodule
/*The Control Path has :
Counters for Counting the address of Memory A , Memory X and Memory Y
Incrementers for Incrementing Address of Memory A, Memory X and Memory Y*/


module ctrlpath(X, H, clk, reset, start, addr_x, wr_en_x, addr_h, wr_en_h, clear_acc, addr_y, wr_en_y,done, load_h, load_x);
		input clk, reset, start, load_h, load_x;
		input [9:0] X;
		input [2:0] H;
		output logic [5:0] addr_h;
		output logic [9:0] addr_x;
		logic [5:0] addr_xjump;
		output logic [9:0] addr_y;
		output logic wr_en_x,wr_en_h,clear_acc,wr_en_y;
		output logic done;
		logic [3:0] state, next_state;
		logic  state1_done, state2_done, state3_jump, state3_donefinal,state3_isone, state5_done, state53_done;

		always @(posedge clk) begin
			if (reset == 1)begin
				state <= 0;  // addr_x<=0; addr_h<=0; addr_y<=0;
				
				
			end
			else
				state <= next_state;
		end

		always @(posedge clk) begin
			if (state==5 && state5_done==1)
				done<=1;
			else
				done<=0;
		end

		always @(posedge clk) begin
			if (state3_donefinal == 0 )
				addr_h <= addr_h+1;
			else if (state3_isone==1 && state!=5)
				addr_h <= addr_h;
			else if (state1_done == 0)
				addr_h <= addr_h-1;
			else if (load_h==1)
				addr_h <= (H*H)-1;///////////////
			else addr_h <= 0;	
			
			
		end

		always @(posedge clk) begin
			if ((((state2_done == 0) && (state==2) ) || state3_donefinal == 0) && state3_jump!=1) 
				addr_x <= addr_x+1;/////////
					
			
				
			else if (state3_jump==1)
				addr_x <= addr_x+X-H+1;///////////////
			
			
							
			else if (reset==1)
				addr_x <= 0;
				
			else 
				addr_x <=  addr_xjump;
		end
		
		always @(posedge clk) begin
		
			if (state3_jump==1 && state53_done!=1 && addr_h<(H+1) && reset==0)///////////????
				addr_xjump <= addr_xjump+1;
			
			else if (state3_jump==1 && state53_done==1 && addr_h<(H+1) && reset==0)///////?????
				addr_xjump <= addr_xjump+H;///////////
			
			else if (reset==1)
				addr_xjump <=0;
		
		end
		


		always @(posedge clk) begin
			if (((state==5)&& (state5_done!=1)) || state==7 || state==6)
				addr_y <= addr_y+1;
			else if (state==0 || state5_done==1)
				addr_y <= 0;
			else
				addr_y <= addr_y;
		end

		always @(posedge clk) begin
			if (state==5 || state==2 || state==9 ) //include state9 as well
				clear_acc <= 1;
			else
				clear_acc <= 0;
		end

		always_comb begin state5_done=1'b0; state1_done=1'b1; state53_done=0; state2_done =1'b0; state3_jump =1'b0;  state3_donefinal=1'b1; state3_isone=0;state5_done=1'b0;
		/*Beginning State*/
			if (state == 0) begin
				if (start==1)
					next_state = 3;
				else if (load_h==1)
					next_state = 1;
				else if (load_x==1)
					next_state =2;
				else begin
					next_state = 0;
				end
			end

		/*Writing in Memory A(Matrix Storage)*/
			else if (state == 1) begin
				if (addr_h<=(H*H)-1) begin/////////
					next_state = 1;
					state1_done = 0;
				end
				else begin
					next_state = 9;
					state1_done = 1;
				end
			end

			/*Writing in Memory x(Vector Storage)*/
			else if (state == 2) begin
				if (addr_x<(X*X)) begin//////////////
					next_state = 2;
					state2_done = 0;
				end
				else begin
					next_state = 9;
					state2_done = 1;
				end;
			end

			else if (state == 9) begin
				if (start==1)
					next_state=3;
				else if (load_h == 1)
					next_state=1;
				else if (load_x == 1)
					next_state=2;
				else
					next_state=9;
			end

			/*Multiply and Accumulate stage -- > This works along with Data path and generates output*/
			else if (state == 3) begin
							
				//if (addr_h<=3) begin
				
					if (addr_h<(H*H)-1) begin
					next_state = 3;
					state3_donefinal=0;
					state2_done=0;
					
						//if (addr_h==4 || addr_h==9 || addr_h==14 || addr_h==19)///////????????????????/
						if ((addr_h+1)%H==0)//////////////
							state3_jump=1;
							
							
							
						else state3_jump=0;
						
						if (((addr_y+1)%(X-H+1))==0) ////////
							state53_done=1;
						else state53_done=0;
					
					
					end				
					else begin
					next_state = 4;
					state3_isone=1;
					end
				
			end

			/*Enable writing in Memory Y and Clearing accumulator For next MAC Operation*/
			else if (state==4) begin
				next_state=5;
				state3_isone=1;
			end

			/*Writing in Memory Y ( Output Vector Storage)*/
			else if (state==5) begin
				state3_isone=1;
				//if (addr_y>=5)		lastvalues=1;
				//else 				lastvalues=0;
				if (addr_y<((X-H+1)*(X-H+1)-1)) begin///////////////
					
					next_state=3;
					state5_done = 0;
				end
				else begin
					next_state=6;
					
					state5_done =1;
				end
			end

			else if(state==6) begin
				next_state=7; 
			end

			/*Outputting Data Storage Stored in Memory Y*/
			else if (state==7) begin
				if (addr_y < ((X-H+1)*(X-H+1)-1))//////////////
					next_state = 7;
				else
					next_state=0;
				end
				else next_state=8;
			end

		assign wr_en_h = (state==1 && reset==0);

		assign wr_en_x = (state==2 && reset==0);

		assign wr_en_y = (state==5 && reset==0);

endmodule

