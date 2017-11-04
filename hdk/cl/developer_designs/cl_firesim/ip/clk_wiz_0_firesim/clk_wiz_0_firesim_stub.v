// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1_sdxop (lin64) Build 1933108 Fri Jul 14 11:54:19 MDT 2017
// Date        : Sat Nov  4 04:22:52 2017
// Host        : ip-172-31-8-190.ec2.internal running 64-bit CentOS Linux release 7.4.1708 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /benchmarks/firesim-build2/platforms/f1/aws-fpga/hdk/cl/developer_designs/cl_firesim/ip/clk_wiz_0_firesim/clk_wiz_0_firesim_stub.v
// Design      : clk_wiz_0_firesim
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flgb2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0_firesim(clk_out1, clk_out2, clk_out3, clk_out4, clk_out5, 
  reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,reset,locked,clk_in1" */;
  output clk_out1;
  output clk_out2;
  output clk_out3;
  output clk_out4;
  output clk_out5;
  input reset;
  output locked;
  input clk_in1;
endmodule
