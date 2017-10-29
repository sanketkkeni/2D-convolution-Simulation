# 2D-convolution-Simulation
2D convolution module to perform convolution operation between a matrix and kernel

1) 2D Convolution for generalised length of X and H.
2) Change the values of X and H from tb_conv_2D.sv file line no. 19
3) X is the lenth of input vector and H is the length of kernel, both are assumed to be square matrices.
4) I have designed a simple testbench, where the value of input starts from 1,2,3,4..... upto (X*X).
5) Value of H is 1,2,3,4,.....(H*H).
6) The size of output is (X-H+1)*(X-H+1) because we consider only those cases where the kernel completely overlaps with the input.
7) The working is very similar to 1-D convolution.
