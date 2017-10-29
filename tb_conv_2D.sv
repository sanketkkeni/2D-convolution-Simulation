include "conv_2D.sv";
// Testbench, with parameters k=4, p=1, b=8, g=0

//This Test bench shows values on normal computation and in the next cycle only the vector is updated keeping the matrix same
module tb_conv2D();
logic clk, reset, start, done,qwerty, load_h, load_x;
integer i;
logic [10:0] X;
logic [2:0] H;
logic signed [7:0] data_in;
logic signed [15:0] data_out;
conv_2D dut(X, H, clk, reset, load_h, load_x, start, done, data_in, data_out);

initial clk=0;
   always #5 clk = ~clk;;

// Set input values.
initial begin  

X=5; H=2;

start=0; reset=1; data_in=8'bx; 
@(posedge clk);
#1; reset=0; load_h=1;
@(posedge clk);
#1; load_h=0; data_in = 1;
@(posedge clk);

for( i=2; i<=H*H; i++) begin

#1;data_in = i;
@(posedge clk);

end

@(posedge clk);
#1; load_x=1; 
@(posedge clk);
#1; load_x=0; data_in=1; 
@(posedge clk);

for( i=2; i<=X*X; i++) begin

#1;data_in = i;
@(posedge clk);

end


@(posedge clk);@(posedge clk);
#1; start=1;
@(posedge clk);
#1; start=0;
 end

integer filehandle=$fopen("proj3_outValuestb1");
// wait for done signal and output  
initial begin
@(posedge done);
 #1; qwerty=0;
@(posedge clk);

for( i=0; i<((X-H+1)*(X-H+1)); i++) begin///////////////

#1; $display("y[%d] = %d" ,i, data_out); $fdisplay(filehandle, "%d", data_out);
@(posedge clk);

end


$finish;
 end
 endmodule 
 