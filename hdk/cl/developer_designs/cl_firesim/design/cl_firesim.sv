// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

module cl_firesim 

(
   `include "cl_ports.vh" // Fixed port definition

);

`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_firesim_defines.vh" // CL Defines for cl_firesim

logic rst_main_n_sync;
logic rst_firesim_n_sync;
logic rst_extra1_n_sync;

//--------------------------------------------0
// Start with Tie-Off of Unused Interfaces
//---------------------------------------------
// the developer should use the next set of `include
// to properly tie-off any unused interface
// The list is put in the top of the module
// to avoid cases where developer may forget to
// remove it from the end of the file

`include "unused_flr_template.inc"
//`include "unused_ddr_a_b_d_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"

//-------------------------------------------------
// Wires
//-------------------------------------------------
//-------------------------------------------------
// ID Values (cl_hello_world_defines.vh)
//-------------------------------------------------
  assign cl_sh_id0[31:0] = `CL_SH_ID0;
  assign cl_sh_id1[31:0] = `CL_SH_ID1;



//-------------------------------------------------
// Reset Synchronization Outer
//-------------------------------------------------
logic pre_sync_rst_n;

always_ff @(negedge rst_main_n or posedge clk_main_a0)
   if (!rst_main_n)
   begin
      pre_sync_rst_n  <= 0;
      rst_main_n_sync <= 0;
   end
   else
   begin
      pre_sync_rst_n  <= 1;
      rst_main_n_sync <= pre_sync_rst_n;
   end

logic pre_sync_rst_n_extra1;
always_ff @(negedge rst_main_n or posedge clk_extra_a1)
   if (!rst_main_n)
   begin
      pre_sync_rst_n_extra1  <= 0;
      rst_extra1_n_sync <= 0;
   end
   else
   begin
      pre_sync_rst_n_extra1  <= 1;
      rst_extra1_n_sync <= pre_sync_rst_n_extra1;
   end



//---------------------------
// new clocking
//-------------------
//
//
//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out1____85.004______0.000______50.0______177.835____296.544
// clk_out2____89.962______0.000______50.0______176.536____296.544
// clk_out3____74.968______0.000______50.0______180.754____296.544
//
//----------------------------------------------------------------------------
// Input Clock   Freq (MHz)    Input Jitter (UI)
//----------------------------------------------------------------------------
// __primary_________125.000____________0.010

logic clock_gend_85;
logic clock_gend_90;
logic clock_gend_75;

logic firesim_internal_clock;
assign firesim_internal_clock = clock_gend_85;
 
clk_wiz_0_firesim firesim_clocking
(
    // Clock out ports
    .clk_out1(clock_gend_85),     // output clk_out1
    .clk_out2(clock_gend_90),     // output clk_out2
    .clk_out3(clock_gend_75),     // output clk_out3
    // Status and control signals
    .reset(!rst_extra1_n_sync), // input reset
    .locked(),       // output locked
   // Clock in ports
    .clk_in1(clk_extra_a1)      // input clk_in1, expects 125 mhz
);

//-------------------------------------------------
// Reset Synchronization Inner
//-------------------------------------------------
logic pre_sync_rst_n_firesim;
always_ff @(negedge rst_main_n or posedge firesim_internal_clock)
   if (!rst_main_n)
   begin
      pre_sync_rst_n_firesim  <= 0;
      rst_firesim_n_sync <= 0;
   end
   else
   begin
      pre_sync_rst_n_firesim  <= 1;
      rst_firesim_n_sync <= pre_sync_rst_n_firesim;
   end

//-------------------------------------------------
// PCIe OCL AXI-L (SH to CL) Timing Flops
//-------------------------------------------------

  // Write address                                                                                                              
  logic        sh_ocl_awvalid_q;
  logic [31:0] sh_ocl_awaddr_q;
  logic        ocl_sh_awready_q;
                                                                                                                              
  // Write data                                                                                                                
  logic        sh_ocl_wvalid_q;
  logic [31:0] sh_ocl_wdata_q;
  logic [ 3:0] sh_ocl_wstrb_q;
  logic        ocl_sh_wready_q;
                                                                                                                              
  // Write response                                                                                                            
  logic        ocl_sh_bvalid_q;
  logic [ 1:0] ocl_sh_bresp_q;
  logic        sh_ocl_bready_q;
                                                                                                                              
  // Read address                                                                                                              
  logic        sh_ocl_arvalid_q;
  logic [31:0] sh_ocl_araddr_q;
  logic        ocl_sh_arready_q;
                                                                                                                              
  // Read data/response                                                                                                        
  logic        ocl_sh_rvalid_q;
  logic [31:0] ocl_sh_rdata_q;
  logic [ 1:0] ocl_sh_rresp_q;
  logic        sh_ocl_rready_q;

// clock converter for OCL connection
axi_clock_converter_oclnew ocl_clock_convert (
  .s_axi_aclk(clk_main_a0),        // input wire s_axi_aclk
  .s_axi_aresetn(rst_main_n_sync),  // input wire s_axi_aresetn

  .s_axi_awaddr(sh_ocl_awaddr),    // input wire [31 : 0] s_axi_awaddr
  .s_axi_awprot(3'h0),             // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(sh_ocl_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(ocl_sh_awready),  // output wire s_axi_awready
  .s_axi_wdata(sh_ocl_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(sh_ocl_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(sh_ocl_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(ocl_sh_wready),    // output wire s_axi_wready
  .s_axi_bresp(ocl_sh_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(ocl_sh_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(sh_ocl_bready),    // input wire s_axi_bready
  .s_axi_araddr(sh_ocl_araddr),    // input wire [31 : 0] s_axi_araddr
  .s_axi_arprot(3'h0),             // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(sh_ocl_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(ocl_sh_arready),  // output wire s_axi_arready
  .s_axi_rdata(ocl_sh_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(ocl_sh_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(ocl_sh_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(sh_ocl_rready),    // input wire s_axi_rready

  .m_axi_aclk(firesim_internal_clock),        // input wire m_axi_aclk
  .m_axi_aresetn(rst_firesim_n_sync),  // input wire m_axi_aresetn
  .m_axi_awaddr(sh_ocl_awaddr_q),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot(),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(sh_ocl_awvalid_q),  // output wire m_axi_awvalid
  .m_axi_awready(ocl_sh_awready_q),  // input wire m_axi_awready
  .m_axi_wdata(sh_ocl_wdata_q),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(sh_ocl_wstrb_q),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid(sh_ocl_wvalid_q),    // output wire m_axi_wvalid
  .m_axi_wready(ocl_sh_wready_q),    // input wire m_axi_wready
  .m_axi_bresp(ocl_sh_bresp_q),      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(ocl_sh_bvalid_q),    // input wire m_axi_bvalid
  .m_axi_bready(sh_ocl_bready_q),    // output wire m_axi_bready
  .m_axi_araddr(sh_ocl_araddr_q),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot(),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(sh_ocl_arvalid_q),  // output wire m_axi_arvalid
  .m_axi_arready(ocl_sh_arready_q),  // input wire m_axi_arready
  .m_axi_rdata(ocl_sh_rdata_q),      // input wire [31 : 0] m_axi_rdata
  .m_axi_rresp(ocl_sh_rresp_q),      // input wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(ocl_sh_rvalid_q),    // input wire m_axi_rvalid
  .m_axi_rready(sh_ocl_rready_q)    // output wire m_axi_rready
);


//----------------------------------------- 
// DDR controller instantiation   
//-----------------------------------------


wire [15 : 0] mc_ddr_s_1_axi_awid;
wire [63 : 0] mc_ddr_s_1_axi_awaddr;
wire [7 : 0] mc_ddr_s_1_axi_awlen;
//wire [2 : 0] mc_ddr_s_1_axi_awsize;
//wire [1 : 0] mc_ddr_s_1_axi_awburst;
//wire [0 : 0] mc_ddr_s_1_axi_awlock;
//wire [3 : 0] mc_ddr_s_1_axi_awcache;
//wire [2 : 0] mc_ddr_s_1_axi_awprot;
//wire [3 : 0] mc_ddr_s_1_axi_awregion;
//wire [3 : 0] mc_ddr_s_1_axi_awqos;
wire mc_ddr_s_1_axi_awvalid;
wire mc_ddr_s_1_axi_awready;

//wire [15 : 0] mc_ddr_s_1_axi_wid;
wire [63 : 0] mc_ddr_s_1_axi_wdata;
wire [7 : 0] mc_ddr_s_1_axi_wstrb;
wire mc_ddr_s_1_axi_wlast;
wire mc_ddr_s_1_axi_wvalid;
wire mc_ddr_s_1_axi_wready;

wire [15 : 0] mc_ddr_s_1_axi_bid;
wire [1 : 0] mc_ddr_s_1_axi_bresp;
wire mc_ddr_s_1_axi_bvalid;
wire mc_ddr_s_1_axi_bready;

wire [15 : 0] mc_ddr_s_1_axi_arid;
wire [63 : 0] mc_ddr_s_1_axi_araddr;
wire [7 : 0] mc_ddr_s_1_axi_arlen;
//wire [2 : 0] mc_ddr_s_1_axi_arsize;
//wire [1 : 0] mc_ddr_s_1_axi_arburst;
//wire [0 : 0] mc_ddr_s_1_axi_arlock;
//wire [3 : 0] mc_ddr_s_1_axi_arcache;
//wire [2 : 0] mc_ddr_s_1_axi_arprot;
//wire [3 : 0] mc_ddr_s_1_axi_arregion;
//wire [3 : 0] mc_ddr_s_1_axi_arqos;
wire mc_ddr_s_1_axi_arvalid;
wire mc_ddr_s_1_axi_arready;

wire [15 : 0] mc_ddr_s_1_axi_rid;
wire [63 : 0] mc_ddr_s_1_axi_rdata;
wire [1 : 0] mc_ddr_s_1_axi_rresp;
wire mc_ddr_s_1_axi_rlast;
wire mc_ddr_s_1_axi_rvalid;
wire mc_ddr_s_1_axi_rready;

wire [15 : 0] mc_ddr_s_2_axi_awid;
wire [63 : 0] mc_ddr_s_2_axi_awaddr;
wire [7 : 0] mc_ddr_s_2_axi_awlen;
//wire [2 : 0] mc_ddr_s_2_axi_awsize;
//wire [1 : 0] mc_ddr_s_2_axi_awburst;
//wire [0 : 0] mc_ddr_s_2_axi_awlock;
//wire [3 : 0] mc_ddr_s_2_axi_awcache;
//wire [2 : 0] mc_ddr_s_2_axi_awprot;
//wire [3 : 0] mc_ddr_s_2_axi_awregion;
//wire [3 : 0] mc_ddr_s_2_axi_awqos;
wire mc_ddr_s_2_axi_awvalid;
wire mc_ddr_s_2_axi_awready;

//wire [15 : 0] mc_ddr_s_2_axi_wid;
wire [63 : 0] mc_ddr_s_2_axi_wdata;
wire [7 : 0] mc_ddr_s_2_axi_wstrb;
wire mc_ddr_s_2_axi_wlast;
wire mc_ddr_s_2_axi_wvalid;
wire mc_ddr_s_2_axi_wready;

wire [15 : 0] mc_ddr_s_2_axi_bid;
wire [1 : 0] mc_ddr_s_2_axi_bresp;
wire mc_ddr_s_2_axi_bvalid;
wire mc_ddr_s_2_axi_bready;

wire [15 : 0] mc_ddr_s_2_axi_arid;
wire [63 : 0] mc_ddr_s_2_axi_araddr;
wire [7 : 0] mc_ddr_s_2_axi_arlen;
//wire [2 : 0] mc_ddr_s_2_axi_arsize;
//wire [1 : 0] mc_ddr_s_2_axi_arburst;
//wire [0 : 0] mc_ddr_s_2_axi_arlock;
//wire [3 : 0] mc_ddr_s_2_axi_arcache;
//wire [2 : 0] mc_ddr_s_2_axi_arprot;
//wire [3 : 0] mc_ddr_s_2_axi_arregion;
//wire [3 : 0] mc_ddr_s_2_axi_arqos;
wire mc_ddr_s_2_axi_arvalid;
wire mc_ddr_s_2_axi_arready;

wire [15 : 0] mc_ddr_s_2_axi_rid;
wire [63 : 0] mc_ddr_s_2_axi_rdata;
wire [1 : 0] mc_ddr_s_2_axi_rresp;
wire mc_ddr_s_2_axi_rlast;
wire mc_ddr_s_2_axi_rvalid;
wire mc_ddr_s_2_axi_rready;

wire [15 : 0] mc_ddr_s_3_axi_awid;
wire [63 : 0] mc_ddr_s_3_axi_awaddr;
wire [7 : 0] mc_ddr_s_3_axi_awlen;
//wire [2 : 0] mc_ddr_s_3_axi_awsize;
//wire [1 : 0] mc_ddr_s_3_axi_awburst;
//wire [0 : 0] mc_ddr_s_3_axi_awlock;
//wire [3 : 0] mc_ddr_s_3_axi_awcache;
//wire [2 : 0] mc_ddr_s_3_axi_awprot;
//wire [3 : 0] mc_ddr_s_3_axi_awregion;
//wire [3 : 0] mc_ddr_s_3_axi_awqos;
wire mc_ddr_s_3_axi_awvalid;
wire mc_ddr_s_3_axi_awready;

//wire [15 : 0] mc_ddr_s_3_axi_wid;
wire [63 : 0] mc_ddr_s_3_axi_wdata;
wire [7 : 0] mc_ddr_s_3_axi_wstrb;
wire mc_ddr_s_3_axi_wlast;
wire mc_ddr_s_3_axi_wvalid;
wire mc_ddr_s_3_axi_wready;

wire [15 : 0] mc_ddr_s_3_axi_bid;
wire [1 : 0] mc_ddr_s_3_axi_bresp;
wire mc_ddr_s_3_axi_bvalid;
wire mc_ddr_s_3_axi_bready;

wire [15 : 0] mc_ddr_s_3_axi_arid;
wire [63 : 0] mc_ddr_s_3_axi_araddr;
wire [7 : 0] mc_ddr_s_3_axi_arlen;
//wire [2 : 0] mc_ddr_s_3_axi_arsize;
//wire [1 : 0] mc_ddr_s_3_axi_arburst;
//wire [0 : 0] mc_ddr_s_3_axi_arlock;
//wire [3 : 0] mc_ddr_s_3_axi_arcache;
//wire [2 : 0] mc_ddr_s_3_axi_arprot;
//wire [3 : 0] mc_ddr_s_3_axi_arregion;
//wire [3 : 0] mc_ddr_s_3_axi_arqos;
wire mc_ddr_s_3_axi_arvalid;
wire mc_ddr_s_3_axi_arready;

wire [15 : 0] mc_ddr_s_3_axi_rid;
wire [63 : 0] mc_ddr_s_3_axi_rdata;
wire [1 : 0] mc_ddr_s_3_axi_rresp;
wire mc_ddr_s_3_axi_rlast;
wire mc_ddr_s_3_axi_rvalid;
wire mc_ddr_s_3_axi_rready;

// Defining local parameters that will instantiate the
// 3 DRAM controllers inside the CL
  
   localparam DDR_A_PRESENT = 1;
   localparam DDR_B_PRESENT = 1;
   localparam DDR_D_PRESENT = 1;


// Define the addition pipeline stag
// needed to close timing for the various
// place where ATG (Automatic Test Generator)
// is defined
   
   localparam NUM_CFG_STGS_CL_DDR_ATG = 8;
   localparam NUM_CFG_STGS_SH_DDR_ATG = 4;
   localparam NUM_CFG_STGS_PCIE_ATG = 4;


// To reduce RTL simulation time, only 8KiB of
// each external DRAM is scrubbed in simulations

`ifdef SIM
   localparam DDR_SCRB_MAX_ADDR = 64'h1FFF;
`else   
   localparam DDR_SCRB_MAX_ADDR = 64'h3FFFFFFFF; //16GB 
`endif
   localparam DDR_SCRB_BURST_LEN_MINUS1 = 15;

`ifdef NO_CL_TST_SCRUBBER
   localparam NO_SCRB_INST = 1;
`else
   localparam NO_SCRB_INST = 0;
`endif   


logic [2:0] lcl_sh_cl_ddr_is_ready;

logic [7:0] sh_ddr_stat_addr_q[2:0];
logic[2:0] sh_ddr_stat_wr_q;
logic[2:0] sh_ddr_stat_rd_q; 
logic[31:0] sh_ddr_stat_wdata_q[2:0];
logic[2:0] ddr_sh_stat_ack_q;
logic[31:0] ddr_sh_stat_rdata_q[2:0];
logic[7:0] ddr_sh_stat_int_q[2:0];


lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT0 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
                                               .out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK0 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
                                               .out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
                                               );


lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT1 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
                                               .out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK1 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
                                               .out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
                                               );

lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT2 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
                                               .out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
                                               );


lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK2 (.clk(clk_main_a0), .rst_n(rst_main_n_sync),
                                               .in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
                                               .out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
                                               ); 

//convert to 2D 
logic[15:0] cl_sh_ddr_awid_2d[2:0];
logic[63:0] cl_sh_ddr_awaddr_2d[2:0];
logic[7:0] cl_sh_ddr_awlen_2d[2:0];
logic[2:0] cl_sh_ddr_awsize_2d[2:0];
logic cl_sh_ddr_awvalid_2d [2:0];
logic[2:0] sh_cl_ddr_awready_2d;

logic[15:0] cl_sh_ddr_wid_2d[2:0];
logic[511:0] cl_sh_ddr_wdata_2d[2:0];
logic[63:0] cl_sh_ddr_wstrb_2d[2:0];
logic[2:0] cl_sh_ddr_wlast_2d;
logic[2:0] cl_sh_ddr_wvalid_2d;
logic[2:0] sh_cl_ddr_wready_2d;

logic[15:0] sh_cl_ddr_bid_2d[2:0];
logic[1:0] sh_cl_ddr_bresp_2d[2:0];
logic[2:0] sh_cl_ddr_bvalid_2d;
logic[2:0] cl_sh_ddr_bready_2d;

logic[15:0] cl_sh_ddr_arid_2d[2:0];
logic[63:0] cl_sh_ddr_araddr_2d[2:0];
logic[7:0] cl_sh_ddr_arlen_2d[2:0];
logic[2:0] cl_sh_ddr_arsize_2d[2:0];
logic[2:0] cl_sh_ddr_arvalid_2d;
logic[2:0] sh_cl_ddr_arready_2d;

logic[15:0] sh_cl_ddr_rid_2d[2:0];
logic[511:0] sh_cl_ddr_rdata_2d[2:0];
logic[1:0] sh_cl_ddr_rresp_2d[2:0];
logic[2:0] sh_cl_ddr_rlast_2d;
logic[2:0] sh_cl_ddr_rvalid_2d;
logic[2:0] cl_sh_ddr_rready_2d;

assign cl_sh_ddr_awid_2d = '{mc_ddr_s_3_axi_awid, mc_ddr_s_2_axi_awid, mc_ddr_s_1_axi_awid};
assign cl_sh_ddr_awaddr_2d = '{mc_ddr_s_3_axi_awaddr, mc_ddr_s_2_axi_awaddr, mc_ddr_s_1_axi_awaddr};
assign cl_sh_ddr_awlen_2d = '{mc_ddr_s_3_axi_awlen, mc_ddr_s_2_axi_awlen, mc_ddr_s_1_axi_awlen};
assign cl_sh_ddr_awsize_2d = '{3'b110, 3'b110, 3'b110};
assign cl_sh_ddr_awvalid_2d = '{mc_ddr_s_3_axi_awvalid, mc_ddr_s_2_axi_awvalid, mc_ddr_s_1_axi_awvalid};
assign {mc_ddr_s_3_axi_awready, mc_ddr_s_2_axi_awready, mc_ddr_s_1_axi_awready} = sh_cl_ddr_awready_2d;

assign cl_sh_ddr_wid_2d = '{16'b0, 16'b0, 16'b0};
assign cl_sh_ddr_wdata_2d = '{mc_ddr_s_3_axi_wdata, mc_ddr_s_2_axi_wdata, mc_ddr_s_1_axi_wdata};
assign cl_sh_ddr_wstrb_2d = '{mc_ddr_s_3_axi_wstrb, mc_ddr_s_2_axi_wstrb, mc_ddr_s_1_axi_wstrb};
assign cl_sh_ddr_wlast_2d = {mc_ddr_s_3_axi_wlast, mc_ddr_s_2_axi_wlast, mc_ddr_s_1_axi_wlast};
assign cl_sh_ddr_wvalid_2d = {mc_ddr_s_3_axi_wvalid, mc_ddr_s_2_axi_wvalid, mc_ddr_s_1_axi_wvalid};
assign {mc_ddr_s_3_axi_wready, mc_ddr_s_2_axi_wready, mc_ddr_s_1_axi_wready} = sh_cl_ddr_wready_2d;

assign {mc_ddr_s_3_axi_bid, mc_ddr_s_2_axi_bid, mc_ddr_s_1_axi_bid} = {sh_cl_ddr_bid_2d[2], sh_cl_ddr_bid_2d[1], sh_cl_ddr_bid_2d[0]};
assign {mc_ddr_s_3_axi_bresp, mc_ddr_s_2_axi_bresp, mc_ddr_s_1_axi_bresp} = {sh_cl_ddr_bresp_2d[2], sh_cl_ddr_bresp_2d[1], sh_cl_ddr_bresp_2d[0]};
assign {mc_ddr_s_3_axi_bvalid, mc_ddr_s_2_axi_bvalid, mc_ddr_s_1_axi_bvalid} = sh_cl_ddr_bvalid_2d;
assign cl_sh_ddr_bready_2d = {mc_ddr_s_3_axi_bready, mc_ddr_s_2_axi_bready, mc_ddr_s_1_axi_bready};

assign cl_sh_ddr_arid_2d = '{mc_ddr_s_3_axi_arid, mc_ddr_s_2_axi_arid, mc_ddr_s_1_axi_arid};
assign cl_sh_ddr_araddr_2d = '{mc_ddr_s_3_axi_araddr, mc_ddr_s_2_axi_araddr, mc_ddr_s_1_axi_araddr};
assign cl_sh_ddr_arlen_2d = '{mc_ddr_s_3_axi_arlen, mc_ddr_s_2_axi_arlen, mc_ddr_s_1_axi_arlen};
assign cl_sh_ddr_arsize_2d = '{3'b110, 3'b110, 3'b110};
assign cl_sh_ddr_arvalid_2d = {mc_ddr_s_3_axi_arvalid, mc_ddr_s_2_axi_arvalid, mc_ddr_s_1_axi_arvalid};
assign {mc_ddr_s_3_axi_arready, mc_ddr_s_2_axi_arready, mc_ddr_s_1_axi_arready} = sh_cl_ddr_arready_2d;

assign {mc_ddr_s_3_axi_rid, mc_ddr_s_2_axi_rid, mc_ddr_s_1_axi_rid} = {sh_cl_ddr_rid_2d[2], sh_cl_ddr_rid_2d[1], sh_cl_ddr_rid_2d[0]};
assign {mc_ddr_s_3_axi_rresp, mc_ddr_s_2_axi_rresp, mc_ddr_s_1_axi_rresp} = {sh_cl_ddr_rresp_2d[2], sh_cl_ddr_rresp_2d[1], sh_cl_ddr_rresp_2d[0]};
assign {mc_ddr_s_3_axi_rdata, mc_ddr_s_2_axi_rdata, mc_ddr_s_1_axi_rdata} = {sh_cl_ddr_rdata_2d[2], sh_cl_ddr_rdata_2d[1], sh_cl_ddr_rdata_2d[0]};
assign {mc_ddr_s_3_axi_rlast, mc_ddr_s_2_axi_rlast, mc_ddr_s_1_axi_rlast} = sh_cl_ddr_rlast_2d;
assign {mc_ddr_s_3_axi_rvalid, mc_ddr_s_2_axi_rvalid, mc_ddr_s_1_axi_rvalid} = sh_cl_ddr_rvalid_2d;
assign cl_sh_ddr_rready_2d = {mc_ddr_s_3_axi_rready, mc_ddr_s_2_axi_rready, mc_ddr_s_1_axi_rready};

(* dont_touch = "true" *) logic sh_ddr_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) SH_DDR_SLC_RST_N (.clk(clk_main_a0), .rst_n(1'b1), .in_bus(rst_main_n_sync), .out_bus(sh_ddr_sync_rst_n));
sh_ddr #(
         .DDR_A_PRESENT(DDR_A_PRESENT),
         .DDR_A_IO(1),
         .DDR_B_PRESENT(DDR_B_PRESENT),
         .DDR_D_PRESENT(DDR_D_PRESENT)
   ) SH_DDR
   (
   .clk(clk_main_a0),
   .rst_n(sh_ddr_sync_rst_n),

   .stat_clk(clk_main_a0),
   .stat_rst_n(sh_ddr_sync_rst_n),


   .CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
   .CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
   .M_A_ACT_N(M_A_ACT_N),
   .M_A_MA(M_A_MA),
   .M_A_BA(M_A_BA),
   .M_A_BG(M_A_BG),
   .M_A_CKE(M_A_CKE),
   .M_A_ODT(M_A_ODT),
   .M_A_CS_N(M_A_CS_N),
   .M_A_CLK_DN(M_A_CLK_DN),
   .M_A_CLK_DP(M_A_CLK_DP),
   .M_A_PAR(M_A_PAR),
   .M_A_DQ(M_A_DQ),
   .M_A_ECC(M_A_ECC),
   .M_A_DQS_DP(M_A_DQS_DP),
   .M_A_DQS_DN(M_A_DQS_DN),
   .cl_RST_DIMM_A_N(cl_RST_DIMM_A_N),
   
   
   .CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
   .CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
   .M_B_ACT_N(M_B_ACT_N),
   .M_B_MA(M_B_MA),
   .M_B_BA(M_B_BA),
   .M_B_BG(M_B_BG),
   .M_B_CKE(M_B_CKE),
   .M_B_ODT(M_B_ODT),
   .M_B_CS_N(M_B_CS_N),
   .M_B_CLK_DN(M_B_CLK_DN),
   .M_B_CLK_DP(M_B_CLK_DP),
   .M_B_PAR(M_B_PAR),
   .M_B_DQ(M_B_DQ),
   .M_B_ECC(M_B_ECC),
   .M_B_DQS_DP(M_B_DQS_DP),
   .M_B_DQS_DN(M_B_DQS_DN),
   .cl_RST_DIMM_B_N(cl_RST_DIMM_B_N),

   .CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
   .CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
   .M_D_ACT_N(M_D_ACT_N),
   .M_D_MA(M_D_MA),
   .M_D_BA(M_D_BA),
   .M_D_BG(M_D_BG),
   .M_D_CKE(M_D_CKE),
   .M_D_ODT(M_D_ODT),
   .M_D_CS_N(M_D_CS_N),
   .M_D_CLK_DN(M_D_CLK_DN),
   .M_D_CLK_DP(M_D_CLK_DP),
   .M_D_PAR(M_D_PAR),
   .M_D_DQ(M_D_DQ),
   .M_D_ECC(M_D_ECC),
   .M_D_DQS_DP(M_D_DQS_DP),
   .M_D_DQS_DN(M_D_DQS_DN),
   .cl_RST_DIMM_D_N(cl_RST_DIMM_D_N),

   //------------------------------------------------------
   // DDR-4 Interface from CL (AXI-4)
   //------------------------------------------------------
   .cl_sh_ddr_awid(cl_sh_ddr_awid_2d),
   .cl_sh_ddr_awaddr(cl_sh_ddr_awaddr_2d),
   .cl_sh_ddr_awlen(cl_sh_ddr_awlen_2d),
   .cl_sh_ddr_awsize(cl_sh_ddr_awsize_2d),
   .cl_sh_ddr_awvalid(cl_sh_ddr_awvalid_2d),
   .sh_cl_ddr_awready(sh_cl_ddr_awready_2d),

   .cl_sh_ddr_wid(cl_sh_ddr_wid_2d),
   .cl_sh_ddr_wdata(cl_sh_ddr_wdata_2d),
   .cl_sh_ddr_wstrb(cl_sh_ddr_wstrb_2d),
   .cl_sh_ddr_wlast(cl_sh_ddr_wlast_2d),
   .cl_sh_ddr_wvalid(cl_sh_ddr_wvalid_2d),
   .sh_cl_ddr_wready(sh_cl_ddr_wready_2d),

   .sh_cl_ddr_bid(sh_cl_ddr_bid_2d),
   .sh_cl_ddr_bresp(sh_cl_ddr_bresp_2d),
   .sh_cl_ddr_bvalid(sh_cl_ddr_bvalid_2d),
   .cl_sh_ddr_bready(cl_sh_ddr_bready_2d),

   .cl_sh_ddr_arid(cl_sh_ddr_arid_2d),
   .cl_sh_ddr_araddr(cl_sh_ddr_araddr_2d),
   .cl_sh_ddr_arlen(cl_sh_ddr_arlen_2d),
   .cl_sh_ddr_arsize(cl_sh_ddr_arsize_2d),
   .cl_sh_ddr_arvalid(cl_sh_ddr_arvalid_2d),
   .sh_cl_ddr_arready(sh_cl_ddr_arready_2d),

   .sh_cl_ddr_rid(sh_cl_ddr_rid_2d),
   .sh_cl_ddr_rdata(sh_cl_ddr_rdata_2d),
   .sh_cl_ddr_rresp(sh_cl_ddr_rresp_2d),
   .sh_cl_ddr_rlast(sh_cl_ddr_rlast_2d),
   .sh_cl_ddr_rvalid(sh_cl_ddr_rvalid_2d),
   .cl_sh_ddr_rready(cl_sh_ddr_rready_2d),

   .sh_cl_ddr_is_ready(lcl_sh_cl_ddr_is_ready),

   .sh_ddr_stat_addr0  (sh_ddr_stat_addr_q[0]) ,
   .sh_ddr_stat_wr0    (sh_ddr_stat_wr_q[0]     ) , 
   .sh_ddr_stat_rd0    (sh_ddr_stat_rd_q[0]     ) , 
   .sh_ddr_stat_wdata0 (sh_ddr_stat_wdata_q[0]  ) , 
   .ddr_sh_stat_ack0   (ddr_sh_stat_ack_q[0]    ) ,
   .ddr_sh_stat_rdata0 (ddr_sh_stat_rdata_q[0]  ),
   .ddr_sh_stat_int0   (ddr_sh_stat_int_q[0]    ),

   .sh_ddr_stat_addr1  (sh_ddr_stat_addr_q[1]) ,
   .sh_ddr_stat_wr1    (sh_ddr_stat_wr_q[1]     ) , 
   .sh_ddr_stat_rd1    (sh_ddr_stat_rd_q[1]     ) , 
   .sh_ddr_stat_wdata1 (sh_ddr_stat_wdata_q[1]  ) , 
   .ddr_sh_stat_ack1   (ddr_sh_stat_ack_q[1]    ) ,
   .ddr_sh_stat_rdata1 (ddr_sh_stat_rdata_q[1]  ),
   .ddr_sh_stat_int1   (ddr_sh_stat_int_q[1]    ),

   .sh_ddr_stat_addr2  (sh_ddr_stat_addr_q[2]) ,
   .sh_ddr_stat_wr2    (sh_ddr_stat_wr_q[2]     ) , 
   .sh_ddr_stat_rd2    (sh_ddr_stat_rd_q[2]     ) , 
   .sh_ddr_stat_wdata2 (sh_ddr_stat_wdata_q[2]  ) , 
   .ddr_sh_stat_ack2   (ddr_sh_stat_ack_q[2]    ) ,
   .ddr_sh_stat_rdata2 (ddr_sh_stat_rdata_q[2]  ),
   .ddr_sh_stat_int2   (ddr_sh_stat_int_q[2]    ) 
   );



//--------------------------------------------------
//==================================================
//--------------------------------------------------


wire [15 : 0] fsimtop_s_0_axi_awid;
wire [63 : 0] fsimtop_s_0_axi_awaddr;
wire [7 : 0] fsimtop_s_0_axi_awlen;
wire [2 : 0] fsimtop_s_0_axi_awsize;
wire [1 : 0] fsimtop_s_0_axi_awburst;
wire [0 : 0] fsimtop_s_0_axi_awlock;
wire [3 : 0] fsimtop_s_0_axi_awcache;
wire [2 : 0] fsimtop_s_0_axi_awprot;
wire [3 : 0] fsimtop_s_0_axi_awregion;
wire [3 : 0] fsimtop_s_0_axi_awqos;
wire fsimtop_s_0_axi_awvalid;
wire fsimtop_s_0_axi_awready;

wire [63 : 0] fsimtop_s_0_axi_wdata;
wire [7 : 0] fsimtop_s_0_axi_wstrb;
wire fsimtop_s_0_axi_wlast;
wire fsimtop_s_0_axi_wvalid;
wire fsimtop_s_0_axi_wready;

wire [15 : 0] fsimtop_s_0_axi_bid;
wire [1 : 0] fsimtop_s_0_axi_bresp;
wire fsimtop_s_0_axi_bvalid;
wire fsimtop_s_0_axi_bready;

wire [15 : 0] fsimtop_s_0_axi_arid;
wire [63 : 0] fsimtop_s_0_axi_araddr;
wire [7 : 0] fsimtop_s_0_axi_arlen;
wire [2 : 0] fsimtop_s_0_axi_arsize;
wire [1 : 0] fsimtop_s_0_axi_arburst;
wire [0 : 0] fsimtop_s_0_axi_arlock;
wire [3 : 0] fsimtop_s_0_axi_arcache;
wire [2 : 0] fsimtop_s_0_axi_arprot;
wire [3 : 0] fsimtop_s_0_axi_arregion;
wire [3 : 0] fsimtop_s_0_axi_arqos;
wire fsimtop_s_0_axi_arvalid;
wire fsimtop_s_0_axi_arready;

wire [15 : 0] fsimtop_s_0_axi_rid;
wire [63 : 0] fsimtop_s_0_axi_rdata;
wire [1 : 0] fsimtop_s_0_axi_rresp;
wire fsimtop_s_0_axi_rlast;
wire fsimtop_s_0_axi_rvalid;
wire fsimtop_s_0_axi_rready;

wire [15 : 0] fsimtop_s_1_axi_awid;
wire [63 : 0] fsimtop_s_1_axi_awaddr;
wire [7 : 0] fsimtop_s_1_axi_awlen;
wire [2 : 0] fsimtop_s_1_axi_awsize;
wire [1 : 0] fsimtop_s_1_axi_awburst;
wire [0 : 0] fsimtop_s_1_axi_awlock;
wire [3 : 0] fsimtop_s_1_axi_awcache;
wire [2 : 0] fsimtop_s_1_axi_awprot;
wire [3 : 0] fsimtop_s_1_axi_awregion;
wire [3 : 0] fsimtop_s_1_axi_awqos;
wire fsimtop_s_1_axi_awvalid;
wire fsimtop_s_1_axi_awready;

wire [63 : 0] fsimtop_s_1_axi_wdata;
wire [7 : 0] fsimtop_s_1_axi_wstrb;
wire fsimtop_s_1_axi_wlast;
wire fsimtop_s_1_axi_wvalid;
wire fsimtop_s_1_axi_wready;

wire [15 : 0] fsimtop_s_1_axi_bid;
wire [1 : 0] fsimtop_s_1_axi_bresp;
wire fsimtop_s_1_axi_bvalid;
wire fsimtop_s_1_axi_bready;

wire [15 : 0] fsimtop_s_1_axi_arid;
wire [63 : 0] fsimtop_s_1_axi_araddr;
wire [7 : 0] fsimtop_s_1_axi_arlen;
wire [2 : 0] fsimtop_s_1_axi_arsize;
wire [1 : 0] fsimtop_s_1_axi_arburst;
wire [0 : 0] fsimtop_s_1_axi_arlock;
wire [3 : 0] fsimtop_s_1_axi_arcache;
wire [2 : 0] fsimtop_s_1_axi_arprot;
wire [3 : 0] fsimtop_s_1_axi_arregion;
wire [3 : 0] fsimtop_s_1_axi_arqos;
wire fsimtop_s_1_axi_arvalid;
wire fsimtop_s_1_axi_arready;

wire [15 : 0] fsimtop_s_1_axi_rid;
wire [63 : 0] fsimtop_s_1_axi_rdata;
wire [1 : 0] fsimtop_s_1_axi_rresp;
wire fsimtop_s_1_axi_rlast;
wire fsimtop_s_1_axi_rvalid;
wire fsimtop_s_1_axi_rready;

wire [15 : 0] fsimtop_s_2_axi_awid;
wire [63 : 0] fsimtop_s_2_axi_awaddr;
wire [7 : 0] fsimtop_s_2_axi_awlen;
wire [2 : 0] fsimtop_s_2_axi_awsize;
wire [1 : 0] fsimtop_s_2_axi_awburst;
wire [0 : 0] fsimtop_s_2_axi_awlock;
wire [3 : 0] fsimtop_s_2_axi_awcache;
wire [2 : 0] fsimtop_s_2_axi_awprot;
wire [3 : 0] fsimtop_s_2_axi_awregion;
wire [3 : 0] fsimtop_s_2_axi_awqos;
wire fsimtop_s_2_axi_awvalid;
wire fsimtop_s_2_axi_awready;

wire [63 : 0] fsimtop_s_2_axi_wdata;
wire [7 : 0] fsimtop_s_2_axi_wstrb;
wire fsimtop_s_2_axi_wlast;
wire fsimtop_s_2_axi_wvalid;
wire fsimtop_s_2_axi_wready;

wire [15 : 0] fsimtop_s_2_axi_bid;
wire [1 : 0] fsimtop_s_2_axi_bresp;
wire fsimtop_s_2_axi_bvalid;
wire fsimtop_s_2_axi_bready;

wire [15 : 0] fsimtop_s_2_axi_arid;
wire [63 : 0] fsimtop_s_2_axi_araddr;
wire [7 : 0] fsimtop_s_2_axi_arlen;
wire [2 : 0] fsimtop_s_2_axi_arsize;
wire [1 : 0] fsimtop_s_2_axi_arburst;
wire [0 : 0] fsimtop_s_2_axi_arlock;
wire [3 : 0] fsimtop_s_2_axi_arcache;
wire [2 : 0] fsimtop_s_2_axi_arprot;
wire [3 : 0] fsimtop_s_2_axi_arregion;
wire [3 : 0] fsimtop_s_2_axi_arqos;
wire fsimtop_s_2_axi_arvalid;
wire fsimtop_s_2_axi_arready;

wire [15 : 0] fsimtop_s_2_axi_rid;
wire [63 : 0] fsimtop_s_2_axi_rdata;
wire [1 : 0] fsimtop_s_2_axi_rresp;
wire fsimtop_s_2_axi_rlast;
wire fsimtop_s_2_axi_rvalid;
wire fsimtop_s_2_axi_rready;

wire [15 : 0] fsimtop_s_3_axi_awid;
wire [63 : 0] fsimtop_s_3_axi_awaddr;
wire [7 : 0] fsimtop_s_3_axi_awlen;
wire [2 : 0] fsimtop_s_3_axi_awsize;
wire [1 : 0] fsimtop_s_3_axi_awburst;
wire [0 : 0] fsimtop_s_3_axi_awlock;
wire [3 : 0] fsimtop_s_3_axi_awcache;
wire [2 : 0] fsimtop_s_3_axi_awprot;
wire [3 : 0] fsimtop_s_3_axi_awregion;
wire [3 : 0] fsimtop_s_3_axi_awqos;
wire fsimtop_s_3_axi_awvalid;
wire fsimtop_s_3_axi_awready;

wire [63 : 0] fsimtop_s_3_axi_wdata;
wire [7 : 0] fsimtop_s_3_axi_wstrb;
wire fsimtop_s_3_axi_wlast;
wire fsimtop_s_3_axi_wvalid;
wire fsimtop_s_3_axi_wready;

wire [15 : 0] fsimtop_s_3_axi_bid;
wire [1 : 0] fsimtop_s_3_axi_bresp;
wire fsimtop_s_3_axi_bvalid;
wire fsimtop_s_3_axi_bready;

wire [15 : 0] fsimtop_s_3_axi_arid;
wire [63 : 0] fsimtop_s_3_axi_araddr;
wire [7 : 0] fsimtop_s_3_axi_arlen;
wire [2 : 0] fsimtop_s_3_axi_arsize;
wire [1 : 0] fsimtop_s_3_axi_arburst;
wire [0 : 0] fsimtop_s_3_axi_arlock;
wire [3 : 0] fsimtop_s_3_axi_arcache;
wire [2 : 0] fsimtop_s_3_axi_arprot;
wire [3 : 0] fsimtop_s_3_axi_arregion;
wire [3 : 0] fsimtop_s_3_axi_arqos;
wire fsimtop_s_3_axi_arvalid;
wire fsimtop_s_3_axi_arready;

wire [15 : 0] fsimtop_s_3_axi_rid;
wire [63 : 0] fsimtop_s_3_axi_rdata;
wire [1 : 0] fsimtop_s_3_axi_rresp;
wire fsimtop_s_3_axi_rlast;
wire fsimtop_s_3_axi_rvalid;
wire fsimtop_s_3_axi_rready;


  F1Shim firesim_top (
   .clock(firesim_internal_clock),
   .reset(!rst_firesim_n_sync),
   .io_master_aw_ready(ocl_sh_awready_q),
   .io_master_aw_valid(sh_ocl_awvalid_q),
   .io_master_aw_bits_addr(sh_ocl_awaddr_q[24:0]),
   .io_master_aw_bits_len(8'h0),
   .io_master_aw_bits_size(3'h2),
   .io_master_aw_bits_burst(2'h1),
   .io_master_aw_bits_lock(1'h0),
   .io_master_aw_bits_cache(4'h0),
   .io_master_aw_bits_prot(3'h0), //unused? (could connect?)
   .io_master_aw_bits_qos(4'h0),
   .io_master_aw_bits_region(4'h0),
   .io_master_aw_bits_id(12'h0),
   .io_master_aw_bits_user(1'h0),
   .io_master_w_ready(ocl_sh_wready_q),
   .io_master_w_valid(sh_ocl_wvalid_q),
   .io_master_w_bits_data(sh_ocl_wdata_q),
   .io_master_w_bits_last(1'h1),
   .io_master_w_bits_id(12'h0),
   .io_master_w_bits_strb(sh_ocl_wstrb_q), //OR 8'hff
   .io_master_w_bits_user(1'h0),
   .io_master_b_ready(sh_ocl_bready_q),
   .io_master_b_valid(ocl_sh_bvalid_q),
   .io_master_b_bits_resp(ocl_sh_bresp_q),
   .io_master_b_bits_id(),      // UNUSED at top level
   .io_master_b_bits_user(),    // UNUSED at top level
   .io_master_ar_ready(ocl_sh_arready_q),
   .io_master_ar_valid(sh_ocl_arvalid_q),
   .io_master_ar_bits_addr(sh_ocl_araddr_q[24:0]),
   .io_master_ar_bits_len(8'h0),
   .io_master_ar_bits_size(3'h2),
   .io_master_ar_bits_burst(2'h1),
   .io_master_ar_bits_lock(1'h0),
   .io_master_ar_bits_cache(4'h0),
   .io_master_ar_bits_prot(3'h0),
   .io_master_ar_bits_qos(4'h0),
   .io_master_ar_bits_region(4'h0),
   .io_master_ar_bits_id(12'h0),
   .io_master_ar_bits_user(1'h0),
   .io_master_r_ready(sh_ocl_rready_q),
   .io_master_r_valid(ocl_sh_rvalid_q),
   .io_master_r_bits_resp(ocl_sh_rresp_q),
   .io_master_r_bits_data(ocl_sh_rdata_q),
   .io_master_r_bits_last(), //UNUSED at top level
   .io_master_r_bits_id(),      // UNUSED at top level
   .io_master_r_bits_user(),    // UNUSED at top level

   .io_slave_0_aw_ready(fsimtop_s_0_axi_awready),
   .io_slave_0_aw_valid(fsimtop_s_0_axi_awvalid),
   .io_slave_0_aw_bits_addr(fsimtop_s_0_axi_awaddr),
   .io_slave_0_aw_bits_len(fsimtop_s_0_axi_awlen),
   .io_slave_0_aw_bits_size(fsimtop_s_0_axi_awsize),
   .io_slave_0_aw_bits_burst(fsimtop_s_0_axi_awburst), // not available on DDR IF
   .io_slave_0_aw_bits_lock(fsimtop_s_0_axi_awlock), // not available on DDR IF
   .io_slave_0_aw_bits_cache(fsimtop_s_0_axi_awcache), // not available on DDR IF
   .io_slave_0_aw_bits_prot(fsimtop_s_0_axi_awprot), // not available on DDR IF
   .io_slave_0_aw_bits_qos(fsimtop_s_0_axi_awqos), // not available on DDR IF
   .io_slave_0_aw_bits_region(fsimtop_0_s_axi_awregion), // not available on DDR IF
   .io_slave_0_aw_bits_id(fsimtop_s_0_axi_awid),
   .io_slave_0_aw_bits_user(), // not available on DDR IF

   .io_slave_0_w_ready(fsimtop_s_0_axi_wready),
   .io_slave_0_w_valid(fsimtop_s_0_axi_wvalid),
   .io_slave_0_w_bits_data(fsimtop_s_0_axi_wdata),
   .io_slave_0_w_bits_last(fsimtop_s_0_axi_wlast),
   .io_slave_0_w_bits_id(),
   .io_slave_0_w_bits_strb(fsimtop_s_0_axi_wstrb),
   .io_slave_0_w_bits_user(), // not available on DDR IF

   .io_slave_0_b_ready(fsimtop_s_0_axi_bready),
   .io_slave_0_b_valid(fsimtop_s_0_axi_bvalid),
   .io_slave_0_b_bits_resp(fsimtop_s_0_axi_bresp),
   .io_slave_0_b_bits_id(fsimtop_s_0_axi_bid),
   .io_slave_0_b_bits_user(1'b0), // TODO check this

   .io_slave_0_ar_ready(fsimtop_s_0_axi_arready),
   .io_slave_0_ar_valid(fsimtop_s_0_axi_arvalid),
   .io_slave_0_ar_bits_addr(fsimtop_s_0_axi_araddr),
   .io_slave_0_ar_bits_len(fsimtop_s_0_axi_arlen),
   .io_slave_0_ar_bits_size(fsimtop_s_0_axi_arsize),
   .io_slave_0_ar_bits_burst(fsimtop_s_0_axi_arburst), // not available on DDR IF
   .io_slave_0_ar_bits_lock(fsimtop_s_0_axi_arlock), // not available on DDR IF
   .io_slave_0_ar_bits_cache(fsimtop_s_0_axi_arcache), // not available on DDR IF
   .io_slave_0_ar_bits_prot(fsimtop_s_0_axi_arprot), // not available on DDR IF
   .io_slave_0_ar_bits_qos(fsimtop_s_0_axi_arqos), // not available on DDR IF
   .io_slave_0_ar_bits_region(fsimtop_s_0_axi_arregion), // not available on DDR IF
   .io_slave_0_ar_bits_id(fsimtop_s_0_axi_arid), // not available on DDR IF
   .io_slave_0_ar_bits_user(), // not available on DDR IF

   .io_slave_0_r_ready(fsimtop_s_0_axi_rready),
   .io_slave_0_r_valid(fsimtop_s_0_axi_rvalid),
   .io_slave_0_r_bits_resp(fsimtop_s_0_axi_rresp),
   .io_slave_0_r_bits_data(fsimtop_s_0_axi_rdata),
   .io_slave_0_r_bits_last(fsimtop_s_0_axi_rlast),
   .io_slave_0_r_bits_id(fsimtop_s_0_axi_rid),
   .io_slave_0_r_bits_user(1'b0), // TODO check this


   .io_slave_1_aw_ready(fsimtop_s_1_axi_awready),
   .io_slave_1_aw_valid(fsimtop_s_1_axi_awvalid),
   .io_slave_1_aw_bits_addr(fsimtop_s_1_axi_awaddr),
   .io_slave_1_aw_bits_len(fsimtop_s_1_axi_awlen),
   .io_slave_1_aw_bits_size(fsimtop_s_1_axi_awsize),
   .io_slave_1_aw_bits_burst(fsimtop_s_1_axi_awburst), // not available on DDR IF
   .io_slave_1_aw_bits_lock(fsimtop_s_1_axi_awlock), // not available on DDR IF
   .io_slave_1_aw_bits_cache(fsimtop_s_1_axi_awcache), // not available on DDR IF
   .io_slave_1_aw_bits_prot(fsimtop_s_1_axi_awprot), // not available on DDR IF
   .io_slave_1_aw_bits_qos(fsimtop_s_1_axi_awqos), // not available on DDR IF
   .io_slave_1_aw_bits_region(fsimtop_1_s_axi_awregion), // not available on DDR IF
   .io_slave_1_aw_bits_id(fsimtop_s_1_axi_awid),
   .io_slave_1_aw_bits_user(), // not available on DDR IF

   .io_slave_1_w_ready(fsimtop_s_1_axi_wready),
   .io_slave_1_w_valid(fsimtop_s_1_axi_wvalid),
   .io_slave_1_w_bits_data(fsimtop_s_1_axi_wdata),
   .io_slave_1_w_bits_last(fsimtop_s_1_axi_wlast),
   .io_slave_1_w_bits_id(),
   .io_slave_1_w_bits_strb(fsimtop_s_1_axi_wstrb),
   .io_slave_1_w_bits_user(), // not available on DDR IF

   .io_slave_1_b_ready(fsimtop_s_1_axi_bready),
   .io_slave_1_b_valid(fsimtop_s_1_axi_bvalid),
   .io_slave_1_b_bits_resp(fsimtop_s_1_axi_bresp),
   .io_slave_1_b_bits_id(fsimtop_s_1_axi_bid),
   .io_slave_1_b_bits_user(1'b0), // TODO check this

   .io_slave_1_ar_ready(fsimtop_s_1_axi_arready),
   .io_slave_1_ar_valid(fsimtop_s_1_axi_arvalid),
   .io_slave_1_ar_bits_addr(fsimtop_s_1_axi_araddr),
   .io_slave_1_ar_bits_len(fsimtop_s_1_axi_arlen),
   .io_slave_1_ar_bits_size(fsimtop_s_1_axi_arsize),
   .io_slave_1_ar_bits_burst(fsimtop_s_1_axi_arburst), // not available on DDR IF
   .io_slave_1_ar_bits_lock(fsimtop_s_1_axi_arlock), // not available on DDR IF
   .io_slave_1_ar_bits_cache(fsimtop_s_1_axi_arcache), // not available on DDR IF
   .io_slave_1_ar_bits_prot(fsimtop_s_1_axi_arprot), // not available on DDR IF
   .io_slave_1_ar_bits_qos(fsimtop_s_1_axi_arqos), // not available on DDR IF
   .io_slave_1_ar_bits_region(fsimtop_s_1_axi_arregion), // not available on DDR IF
   .io_slave_1_ar_bits_id(fsimtop_s_1_axi_arid), // not available on DDR IF
   .io_slave_1_ar_bits_user(), // not available on DDR IF

   .io_slave_1_r_ready(fsimtop_s_1_axi_rready),
   .io_slave_1_r_valid(fsimtop_s_1_axi_rvalid),
   .io_slave_1_r_bits_resp(fsimtop_s_1_axi_rresp),
   .io_slave_1_r_bits_data(fsimtop_s_1_axi_rdata),
   .io_slave_1_r_bits_last(fsimtop_s_1_axi_rlast),
   .io_slave_1_r_bits_id(fsimtop_s_1_axi_rid),
   .io_slave_1_r_bits_user(1'b0), // TODO check this


   .io_slave_2_aw_ready(fsimtop_s_2_axi_awready),
   .io_slave_2_aw_valid(fsimtop_s_2_axi_awvalid),
   .io_slave_2_aw_bits_addr(fsimtop_s_2_axi_awaddr),
   .io_slave_2_aw_bits_len(fsimtop_s_2_axi_awlen),
   .io_slave_2_aw_bits_size(fsimtop_s_2_axi_awsize),
   .io_slave_2_aw_bits_burst(fsimtop_s_2_axi_awburst), // not available on DDR IF
   .io_slave_2_aw_bits_lock(fsimtop_s_2_axi_awlock), // not available on DDR IF
   .io_slave_2_aw_bits_cache(fsimtop_s_2_axi_awcache), // not available on DDR IF
   .io_slave_2_aw_bits_prot(fsimtop_s_2_axi_awprot), // not available on DDR IF
   .io_slave_2_aw_bits_qos(fsimtop_s_2_axi_awqos), // not available on DDR IF
   .io_slave_2_aw_bits_region(fsimtop_2_s_axi_awregion), // not available on DDR IF
   .io_slave_2_aw_bits_id(fsimtop_s_2_axi_awid),
   .io_slave_2_aw_bits_user(), // not available on DDR IF

   .io_slave_2_w_ready(fsimtop_s_2_axi_wready),
   .io_slave_2_w_valid(fsimtop_s_2_axi_wvalid),
   .io_slave_2_w_bits_data(fsimtop_s_2_axi_wdata),
   .io_slave_2_w_bits_last(fsimtop_s_2_axi_wlast),
   .io_slave_2_w_bits_id(),
   .io_slave_2_w_bits_strb(fsimtop_s_2_axi_wstrb),
   .io_slave_2_w_bits_user(), // not available on DDR IF

   .io_slave_2_b_ready(fsimtop_s_2_axi_bready),
   .io_slave_2_b_valid(fsimtop_s_2_axi_bvalid),
   .io_slave_2_b_bits_resp(fsimtop_s_2_axi_bresp),
   .io_slave_2_b_bits_id(fsimtop_s_2_axi_bid),
   .io_slave_2_b_bits_user(1'b0), // TODO check this

   .io_slave_2_ar_ready(fsimtop_s_2_axi_arready),
   .io_slave_2_ar_valid(fsimtop_s_2_axi_arvalid),
   .io_slave_2_ar_bits_addr(fsimtop_s_2_axi_araddr),
   .io_slave_2_ar_bits_len(fsimtop_s_2_axi_arlen),
   .io_slave_2_ar_bits_size(fsimtop_s_2_axi_arsize),
   .io_slave_2_ar_bits_burst(fsimtop_s_2_axi_arburst), // not available on DDR IF
   .io_slave_2_ar_bits_lock(fsimtop_s_2_axi_arlock), // not available on DDR IF
   .io_slave_2_ar_bits_cache(fsimtop_s_2_axi_arcache), // not available on DDR IF
   .io_slave_2_ar_bits_prot(fsimtop_s_2_axi_arprot), // not available on DDR IF
   .io_slave_2_ar_bits_qos(fsimtop_s_2_axi_arqos), // not available on DDR IF
   .io_slave_2_ar_bits_region(fsimtop_s_2_axi_arregion), // not available on DDR IF
   .io_slave_2_ar_bits_id(fsimtop_s_2_axi_arid), // not available on DDR IF
   .io_slave_2_ar_bits_user(), // not available on DDR IF

   .io_slave_2_r_ready(fsimtop_s_2_axi_rready),
   .io_slave_2_r_valid(fsimtop_s_2_axi_rvalid),
   .io_slave_2_r_bits_resp(fsimtop_s_2_axi_rresp),
   .io_slave_2_r_bits_data(fsimtop_s_2_axi_rdata),
   .io_slave_2_r_bits_last(fsimtop_s_2_axi_rlast),
   .io_slave_2_r_bits_id(fsimtop_s_2_axi_rid),
   .io_slave_2_r_bits_user(1'b0), // TODO check this


   .io_slave_3_aw_ready(fsimtop_s_3_axi_awready),
   .io_slave_3_aw_valid(fsimtop_s_3_axi_awvalid),
   .io_slave_3_aw_bits_addr(fsimtop_s_3_axi_awaddr),
   .io_slave_3_aw_bits_len(fsimtop_s_3_axi_awlen),
   .io_slave_3_aw_bits_size(fsimtop_s_3_axi_awsize),
   .io_slave_3_aw_bits_burst(fsimtop_s_3_axi_awburst), // not available on DDR IF
   .io_slave_3_aw_bits_lock(fsimtop_s_3_axi_awlock), // not available on DDR IF
   .io_slave_3_aw_bits_cache(fsimtop_s_3_axi_awcache), // not available on DDR IF
   .io_slave_3_aw_bits_prot(fsimtop_s_3_axi_awprot), // not available on DDR IF
   .io_slave_3_aw_bits_qos(fsimtop_s_3_axi_awqos), // not available on DDR IF
   .io_slave_3_aw_bits_region(fsimtop_3_s_axi_awregion), // not available on DDR IF
   .io_slave_3_aw_bits_id(fsimtop_s_3_axi_awid),
   .io_slave_3_aw_bits_user(), // not available on DDR IF

   .io_slave_3_w_ready(fsimtop_s_3_axi_wready),
   .io_slave_3_w_valid(fsimtop_s_3_axi_wvalid),
   .io_slave_3_w_bits_data(fsimtop_s_3_axi_wdata),
   .io_slave_3_w_bits_last(fsimtop_s_3_axi_wlast),
   .io_slave_3_w_bits_id(),
   .io_slave_3_w_bits_strb(fsimtop_s_3_axi_wstrb),
   .io_slave_3_w_bits_user(), // not available on DDR IF

   .io_slave_3_b_ready(fsimtop_s_3_axi_bready),
   .io_slave_3_b_valid(fsimtop_s_3_axi_bvalid),
   .io_slave_3_b_bits_resp(fsimtop_s_3_axi_bresp),
   .io_slave_3_b_bits_id(fsimtop_s_3_axi_bid),
   .io_slave_3_b_bits_user(1'b0), // TODO check this

   .io_slave_3_ar_ready(fsimtop_s_3_axi_arready),
   .io_slave_3_ar_valid(fsimtop_s_3_axi_arvalid),
   .io_slave_3_ar_bits_addr(fsimtop_s_3_axi_araddr),
   .io_slave_3_ar_bits_len(fsimtop_s_3_axi_arlen),
   .io_slave_3_ar_bits_size(fsimtop_s_3_axi_arsize),
   .io_slave_3_ar_bits_burst(fsimtop_s_3_axi_arburst), // not available on DDR IF
   .io_slave_3_ar_bits_lock(fsimtop_s_3_axi_arlock), // not available on DDR IF
   .io_slave_3_ar_bits_cache(fsimtop_s_3_axi_arcache), // not available on DDR IF
   .io_slave_3_ar_bits_prot(fsimtop_s_3_axi_arprot), // not available on DDR IF
   .io_slave_3_ar_bits_qos(fsimtop_s_3_axi_arqos), // not available on DDR IF
   .io_slave_3_ar_bits_region(fsimtop_s_3_axi_arregion), // not available on DDR IF
   .io_slave_3_ar_bits_id(fsimtop_s_3_axi_arid), // not available on DDR IF
   .io_slave_3_ar_bits_user(), // not available on DDR IF

   .io_slave_3_r_ready(fsimtop_s_3_axi_rready),
   .io_slave_3_r_valid(fsimtop_s_3_axi_rvalid),
   .io_slave_3_r_bits_resp(fsimtop_s_3_axi_rresp),
   .io_slave_3_r_bits_data(fsimtop_s_3_axi_rdata),
   .io_slave_3_r_bits_last(fsimtop_s_3_axi_rlast),
   .io_slave_3_r_bits_id(fsimtop_s_3_axi_rid),
   .io_slave_3_r_bits_user(1'b0) // TODO check this

);

  wire [31:0] io_slave_0_aw_bits_addr;
  assign cl_sh_ddr_awaddr = { 30'b0, io_slave_0_aw_bits_addr[30:0], 3'b0 }; // TODO: check this

  wire [63:0] io_slave_0_w_bits_data;
  assign cl_sh_ddr_wdata = { 448'b0, io_slave_0_w_bits_data };

  wire [7:0] io_slave_0_w_bits_strb;
  assign cl_sh_ddr_wstrb = { 56'b0, io_slave_0_w_bits_strb };

  wire [31:0] io_slave_0_ar_bits_addr;
  assign cl_sh_ddr_araddr = { 30'b0, io_slave_0_ar_bits_addr[30:0], 3'b0 };

  assign cl_sh_ddr_awsize = 3'b110;
  assign cl_sh_ddr_arsize = 3'b110;
  assign cl_sh_ddr_wid = 16'b0;

axi_clock_converter_dramslim clock_convert_dramslim (
  .s_axi_aclk(firesim_internal_clock),          // input wire s_axi_aclk
  .s_axi_aresetn(rst_firesim_n_sync),    // input wire s_axi_aresetn

  .s_axi_awid(fsimtop_s_0_axi_awid),          // input wire [15 : 0] s_axi_awid
  .s_axi_awaddr(fsimtop_s_0_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen(fsimtop_s_0_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(fsimtop_s_0_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fsimtop_s_0_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fsimtop_s_0_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(fsimtop_s_0_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fsimtop_s_0_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(fsimtop_s_0_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(fsimtop_s_0_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(fsimtop_s_0_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(fsimtop_s_0_axi_awready),    // output wire s_axi_awready

  .s_axi_wdata(fsimtop_s_0_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(fsimtop_s_0_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(fsimtop_s_0_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(fsimtop_s_0_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(fsimtop_s_0_axi_wready),      // output wire s_axi_wready

  .s_axi_bid(fsimtop_s_0_axi_bid),            // output wire [15 : 0] s_axi_bid
  .s_axi_bresp(fsimtop_s_0_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fsimtop_s_0_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(fsimtop_s_0_axi_bready),      // input wire s_axi_bready

  .s_axi_arid(fsimtop_s_0_axi_arid),          // input wire [15 : 0] s_axi_arid
  .s_axi_araddr(fsimtop_s_0_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen(fsimtop_s_0_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(fsimtop_s_0_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fsimtop_s_0_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fsimtop_s_0_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(fsimtop_s_0_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fsimtop_s_0_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(fsimtop_s_0_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(fsimtop_s_0_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(fsimtop_s_0_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(fsimtop_s_0_axi_arready),    // output wire s_axi_arready

  .s_axi_rid(fsimtop_s_0_axi_rid),            // output wire [15 : 0] s_axi_rid
  .s_axi_rdata(fsimtop_s_0_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(fsimtop_s_0_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fsimtop_s_0_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(fsimtop_s_0_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(fsimtop_s_0_axi_rready),      // input wire s_axi_rready

  .m_axi_aclk(clk_main_a0),          // input wire m_axi_aclk
  .m_axi_aresetn(rst_main_n_sync),    // input wire m_axi_aresetn

  .m_axi_awid(cl_sh_ddr_awid),          // output wire [15 : 0] m_axi_awid
  .m_axi_awaddr(io_slave_0_aw_bits_addr),      // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(cl_sh_ddr_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(),      // output wire [2 : 0] m_axi_awsize  // unused. manually assign cl_sh_ddr_awsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_awburst(),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(cl_sh_ddr_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(sh_cl_ddr_awready),    // input wire m_axi_awready

  .m_axi_wdata(io_slave_0_w_bits_data),        // output wire [511 : 0] m_axi_wdata
  .m_axi_wstrb(io_slave_0_w_bits_strb),        // output wire [63 : 0] m_axi_wstrb
  .m_axi_wlast(cl_sh_ddr_wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(cl_sh_ddr_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(sh_cl_ddr_wready),      // input wire m_axi_wready

  .m_axi_bid(sh_cl_ddr_bid),            // input wire [15 : 0] m_axi_bid
  .m_axi_bresp(sh_cl_ddr_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(sh_cl_ddr_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(cl_sh_ddr_bready),      // output wire m_axi_bready

  .m_axi_arid(cl_sh_ddr_arid),          // output wire [15 : 0] m_axi_arid
  .m_axi_araddr(io_slave_0_ar_bits_addr),      // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(cl_sh_ddr_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(),      // output wire [2 : 0] m_axi_arsize // unused. manually assign cl_sh_ddr_arsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_arburst(),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(cl_sh_ddr_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(sh_cl_ddr_arready),    // input wire m_axi_arready

  .m_axi_rid(sh_cl_ddr_rid),            // input wire [15 : 0] m_axi_rid
  .m_axi_rdata(sh_cl_ddr_rdata[63:0]),        // input wire [511 : 0] m_axi_rdata
  .m_axi_rresp(sh_cl_ddr_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(sh_cl_ddr_rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(sh_cl_ddr_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(cl_sh_ddr_rready)      // output wire m_axi_rready
);


  wire [31:0] io_slave_1_aw_bits_addr;
  assign mc_ddr_s_1_axi_awaddr = { 30'b0, io_slave_1_aw_bits_addr[30:0], 3'b0 }; // TODO: check this

  wire [63:0] io_slave_1_w_bits_data;
  assign mc_ddr_s_1_axi_wdata = { 448'b0, io_slave_1_w_bits_data };

  wire [7:0] io_slave_1_w_bits_strb;
  assign mc_ddr_s_1_axi_wstrb = { 56'b0, io_slave_1_w_bits_strb };

  wire [31:0] io_slave_1_ar_bits_addr;
  assign mc_ddr_s_1_axi_araddr = { 30'b0, io_slave_1_ar_bits_addr[30:0], 3'b0 };


axi_clock_converter_dramslim clock_convert_dramslim_1 (
  .s_axi_aclk(firesim_internal_clock),          // input wire s_axi_aclk
  .s_axi_aresetn(rst_firesim_n_sync),    // input wire s_axi_aresetn

  .s_axi_awid(fsimtop_s_1_axi_awid),          // input wire [15 : 0] s_axi_awid
  .s_axi_awaddr(fsimtop_s_1_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen(fsimtop_s_1_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(fsimtop_s_1_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fsimtop_s_1_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fsimtop_s_1_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(fsimtop_s_1_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fsimtop_s_1_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(fsimtop_s_1_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(fsimtop_s_1_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(fsimtop_s_1_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(fsimtop_s_1_axi_awready),    // output wire s_axi_awready

  .s_axi_wdata(fsimtop_s_1_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(fsimtop_s_1_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(fsimtop_s_1_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(fsimtop_s_1_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(fsimtop_s_1_axi_wready),      // output wire s_axi_wready

  .s_axi_bid(fsimtop_s_1_axi_bid),            // output wire [15 : 0] s_axi_bid
  .s_axi_bresp(fsimtop_s_1_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fsimtop_s_1_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(fsimtop_s_1_axi_bready),      // input wire s_axi_bready

  .s_axi_arid(fsimtop_s_1_axi_arid),          // input wire [15 : 0] s_axi_arid
  .s_axi_araddr(fsimtop_s_1_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen(fsimtop_s_1_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(fsimtop_s_1_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fsimtop_s_1_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fsimtop_s_1_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(fsimtop_s_1_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fsimtop_s_1_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(fsimtop_s_1_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(fsimtop_s_1_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(fsimtop_s_1_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(fsimtop_s_1_axi_arready),    // output wire s_axi_arready

  .s_axi_rid(fsimtop_s_1_axi_rid),            // output wire [15 : 0] s_axi_rid
  .s_axi_rdata(fsimtop_s_1_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(fsimtop_s_1_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fsimtop_s_1_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(fsimtop_s_1_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(fsimtop_s_1_axi_rready),      // input wire s_axi_rready

  .m_axi_aclk(clk_main_a0),          // input wire m_axi_aclk
  .m_axi_aresetn(rst_main_n_sync),    // input wire m_axi_aresetn

  .m_axi_awid(mc_ddr_s_1_axi_awid),          // output wire [15 : 0] m_axi_awid
  .m_axi_awaddr(io_slave_1_aw_bits_addr),      // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(mc_ddr_s_1_axi_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(),      // output wire [2 : 0] m_axi_awsize  // unused. manually assign cl_sh_ddr_awsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_awburst(),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(mc_ddr_s_1_axi_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(mc_ddr_s_1_axi_awready),    // input wire m_axi_awready

  .m_axi_wdata(io_slave_1_w_bits_data),        // output wire [511 : 0] m_axi_wdata
  .m_axi_wstrb(io_slave_1_w_bits_strb),        // output wire [63 : 0] m_axi_wstrb
  .m_axi_wlast(mc_ddr_s_1_axi_wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(mc_ddr_s_1_axi_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(mc_ddr_s_1_axi_wready),      // input wire m_axi_wready

  .m_axi_bid(mc_ddr_s_1_axi_bid),            // input wire [15 : 0] m_axi_bid
  .m_axi_bresp(mc_ddr_s_1_axi_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(mc_ddr_s_1_axi_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(mc_ddr_s_1_axi_bready),      // output wire m_axi_bready

  .m_axi_arid(mc_ddr_s_1_axi_arid),          // output wire [15 : 0] m_axi_arid
  .m_axi_araddr(io_slave_1_ar_bits_addr),      // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(mc_ddr_s_1_axi_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(),      // output wire [2 : 0] m_axi_arsize // unused. manually assign cl_sh_ddr_arsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_arburst(),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(mc_ddr_s_1_axi_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(mc_ddr_s_1_axi_arready),    // input wire m_axi_arready

  .m_axi_rid(mc_ddr_s_1_axi_rid),            // input wire [15 : 0] m_axi_rid
  .m_axi_rdata(mc_ddr_s_1_axi_rdata[63:0]),        // input wire [511 : 0] m_axi_rdata
  .m_axi_rresp(mc_ddr_s_1_axi_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(mc_ddr_s_1_axi_rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(mc_ddr_s_1_axi_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(mc_ddr_s_1_axi_rready)      // output wire m_axi_rready
);



  wire [31:0] io_slave_2_aw_bits_addr;
  assign mc_ddr_s_2_axi_awaddr = { 30'b0, io_slave_2_aw_bits_addr[30:0], 3'b0 }; // TODO: check this

  wire [63:0] io_slave_2_w_bits_data;
  assign mc_ddr_s_2_axi_wdata = { 448'b0, io_slave_2_w_bits_data };

  wire [7:0] io_slave_2_w_bits_strb;
  assign mc_ddr_s_2_axi_wstrb = { 56'b0, io_slave_2_w_bits_strb };

  wire [31:0] io_slave_2_ar_bits_addr;
  assign mc_ddr_s_2_axi_araddr = { 30'b0, io_slave_2_ar_bits_addr[30:0], 3'b0 };

axi_clock_converter_dramslim clock_convert_dramslim_2 (
  .s_axi_aclk(firesim_internal_clock),          // input wire s_axi_aclk
  .s_axi_aresetn(rst_firesim_n_sync),    // input wire s_axi_aresetn

  .s_axi_awid(fsimtop_s_2_axi_awid),          // input wire [15 : 0] s_axi_awid
  .s_axi_awaddr(fsimtop_s_2_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen(fsimtop_s_2_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(fsimtop_s_2_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fsimtop_s_2_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fsimtop_s_2_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(fsimtop_s_2_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fsimtop_s_2_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(fsimtop_s_2_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(fsimtop_s_2_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(fsimtop_s_2_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(fsimtop_s_2_axi_awready),    // output wire s_axi_awready

  .s_axi_wdata(fsimtop_s_2_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(fsimtop_s_2_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(fsimtop_s_2_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(fsimtop_s_2_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(fsimtop_s_2_axi_wready),      // output wire s_axi_wready

  .s_axi_bid(fsimtop_s_2_axi_bid),            // output wire [15 : 0] s_axi_bid
  .s_axi_bresp(fsimtop_s_2_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fsimtop_s_2_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(fsimtop_s_2_axi_bready),      // input wire s_axi_bready

  .s_axi_arid(fsimtop_s_2_axi_arid),          // input wire [15 : 0] s_axi_arid
  .s_axi_araddr(fsimtop_s_2_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen(fsimtop_s_2_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(fsimtop_s_2_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fsimtop_s_2_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fsimtop_s_2_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(fsimtop_s_2_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fsimtop_s_2_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(fsimtop_s_2_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(fsimtop_s_2_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(fsimtop_s_2_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(fsimtop_s_2_axi_arready),    // output wire s_axi_arready

  .s_axi_rid(fsimtop_s_2_axi_rid),            // output wire [15 : 0] s_axi_rid
  .s_axi_rdata(fsimtop_s_2_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(fsimtop_s_2_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fsimtop_s_2_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(fsimtop_s_2_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(fsimtop_s_2_axi_rready),      // input wire s_axi_rready

  .m_axi_aclk(clk_main_a0),          // input wire m_axi_aclk
  .m_axi_aresetn(rst_main_n_sync),    // input wire m_axi_aresetn

  .m_axi_awid(mc_ddr_s_2_axi_awid),          // output wire [15 : 0] m_axi_awid
  .m_axi_awaddr(io_slave_2_aw_bits_addr),      // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(mc_ddr_s_2_axi_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(),      // output wire [2 : 0] m_axi_awsize  // unused. manually assign cl_sh_ddr_awsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_awburst(),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(mc_ddr_s_2_axi_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(mc_ddr_s_2_axi_awready),    // input wire m_axi_awready

  .m_axi_wdata(io_slave_2_w_bits_data),        // output wire [511 : 0] m_axi_wdata
  .m_axi_wstrb(io_slave_2_w_bits_strb),        // output wire [63 : 0] m_axi_wstrb
  .m_axi_wlast(mc_ddr_s_2_axi_wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(mc_ddr_s_2_axi_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(mc_ddr_s_2_axi_wready),      // input wire m_axi_wready

  .m_axi_bid(mc_ddr_s_2_axi_bid),            // input wire [15 : 0] m_axi_bid
  .m_axi_bresp(mc_ddr_s_2_axi_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(mc_ddr_s_2_axi_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(mc_ddr_s_2_axi_bready),      // output wire m_axi_bready

  .m_axi_arid(mc_ddr_s_2_axi_arid),          // output wire [15 : 0] m_axi_arid
  .m_axi_araddr(io_slave_2_ar_bits_addr),      // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(mc_ddr_s_2_axi_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(),      // output wire [2 : 0] m_axi_arsize // unused. manually assign cl_sh_ddr_arsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_arburst(),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(mc_ddr_s_2_axi_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(mc_ddr_s_2_axi_arready),    // input wire m_axi_arready

  .m_axi_rid(mc_ddr_s_2_axi_rid),            // input wire [15 : 0] m_axi_rid
  .m_axi_rdata(mc_ddr_s_2_axi_rdata[63:0]),        // input wire [511 : 0] m_axi_rdata
  .m_axi_rresp(mc_ddr_s_2_axi_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(mc_ddr_s_2_axi_rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(mc_ddr_s_2_axi_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(mc_ddr_s_2_axi_rready)      // output wire m_axi_rready
);


  wire [31:0] io_slave_3_aw_bits_addr;
  assign mc_ddr_s_3_axi_awaddr = { 30'b0, io_slave_3_aw_bits_addr[30:0], 3'b0 }; // TODO: check this

  wire [63:0] io_slave_3_w_bits_data;
  assign mc_ddr_s_3_axi_wdata = { 448'b0, io_slave_3_w_bits_data };

  wire [7:0] io_slave_3_w_bits_strb;
  assign mc_ddr_s_3_axi_wstrb = { 56'b0, io_slave_3_w_bits_strb };

  wire [31:0] io_slave_3_ar_bits_addr;
  assign mc_ddr_s_3_axi_araddr = { 30'b0, io_slave_3_ar_bits_addr[30:0], 3'b0 };

axi_clock_converter_dramslim clock_convert_dramslim_3 (
  .s_axi_aclk(firesim_internal_clock),          // input wire s_axi_aclk
  .s_axi_aresetn(rst_firesim_n_sync),    // input wire s_axi_aresetn

  .s_axi_awid(fsimtop_s_3_axi_awid),          // input wire [15 : 0] s_axi_awid
  .s_axi_awaddr(fsimtop_s_3_axi_awaddr),      // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen(fsimtop_s_3_axi_awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(fsimtop_s_3_axi_awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fsimtop_s_3_axi_awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fsimtop_s_3_axi_awlock),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(fsimtop_s_3_axi_awcache),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fsimtop_s_3_axi_awprot),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(fsimtop_s_3_axi_awregion),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(fsimtop_s_3_axi_awqos),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(fsimtop_s_3_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(fsimtop_s_3_axi_awready),    // output wire s_axi_awready

  .s_axi_wdata(fsimtop_s_3_axi_wdata),        // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb(fsimtop_s_3_axi_wstrb),        // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast(fsimtop_s_3_axi_wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(fsimtop_s_3_axi_wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(fsimtop_s_3_axi_wready),      // output wire s_axi_wready

  .s_axi_bid(fsimtop_s_3_axi_bid),            // output wire [15 : 0] s_axi_bid
  .s_axi_bresp(fsimtop_s_3_axi_bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fsimtop_s_3_axi_bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(fsimtop_s_3_axi_bready),      // input wire s_axi_bready

  .s_axi_arid(fsimtop_s_3_axi_arid),          // input wire [15 : 0] s_axi_arid
  .s_axi_araddr(fsimtop_s_3_axi_araddr),      // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen(fsimtop_s_3_axi_arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(fsimtop_s_3_axi_arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fsimtop_s_3_axi_arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fsimtop_s_3_axi_arlock),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(fsimtop_s_3_axi_arcache),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fsimtop_s_3_axi_arprot),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(fsimtop_s_3_axi_arregion),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(fsimtop_s_3_axi_arqos),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(fsimtop_s_3_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(fsimtop_s_3_axi_arready),    // output wire s_axi_arready

  .s_axi_rid(fsimtop_s_3_axi_rid),            // output wire [15 : 0] s_axi_rid
  .s_axi_rdata(fsimtop_s_3_axi_rdata),        // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp(fsimtop_s_3_axi_rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fsimtop_s_3_axi_rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(fsimtop_s_3_axi_rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(fsimtop_s_3_axi_rready),      // input wire s_axi_rready

  .m_axi_aclk(clk_main_a0),          // input wire m_axi_aclk
  .m_axi_aresetn(rst_main_n_sync),    // input wire m_axi_aresetn

  .m_axi_awid(mc_ddr_s_3_axi_awid),          // output wire [15 : 0] m_axi_awid
  .m_axi_awaddr(io_slave_3_aw_bits_addr),      // output wire [63 : 0] m_axi_awaddr
  .m_axi_awlen(mc_ddr_s_3_axi_awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(),      // output wire [2 : 0] m_axi_awsize  // unused. manually assign cl_sh_ddr_awsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_awburst(),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(mc_ddr_s_3_axi_awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(mc_ddr_s_3_axi_awready),    // input wire m_axi_awready

  .m_axi_wdata(io_slave_3_w_bits_data),        // output wire [511 : 0] m_axi_wdata
  .m_axi_wstrb(io_slave_3_w_bits_strb),        // output wire [63 : 0] m_axi_wstrb
  .m_axi_wlast(mc_ddr_s_3_axi_wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(mc_ddr_s_3_axi_wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(mc_ddr_s_3_axi_wready),      // input wire m_axi_wready

  .m_axi_bid(mc_ddr_s_3_axi_bid),            // input wire [15 : 0] m_axi_bid
  .m_axi_bresp(mc_ddr_s_3_axi_bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(mc_ddr_s_3_axi_bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(mc_ddr_s_3_axi_bready),      // output wire m_axi_bready

  .m_axi_arid(mc_ddr_s_3_axi_arid),          // output wire [15 : 0] m_axi_arid
  .m_axi_araddr(io_slave_3_ar_bits_addr),      // output wire [63 : 0] m_axi_araddr
  .m_axi_arlen(mc_ddr_s_3_axi_arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(),      // output wire [2 : 0] m_axi_arsize // unused. manually assign cl_sh_ddr_arsize above. see https://github.com/firesim/aws-fpga-firesim/blob/master/ERRATA.md#unsupported-features-planned-for-future-releases
  .m_axi_arburst(),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(mc_ddr_s_3_axi_arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(mc_ddr_s_3_axi_arready),    // input wire m_axi_arready

  .m_axi_rid(mc_ddr_s_3_axi_rid),            // input wire [15 : 0] m_axi_rid
  .m_axi_rdata(mc_ddr_s_3_axi_rdata[63:0]),        // input wire [511 : 0] m_axi_rdata
  .m_axi_rresp(mc_ddr_s_3_axi_rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(mc_ddr_s_3_axi_rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(mc_ddr_s_3_axi_rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(mc_ddr_s_3_axi_rready)      // output wire m_axi_rready
);



//-------------------------------------------
// Tie-Off Global Signals
//-------------------------------------------
`ifndef CL_VERSION
   `define CL_VERSION 32'hee_ee_ee_00
`endif  


  assign cl_sh_status0[31:0] =  32'h0000_0FF0;
  assign cl_sh_status1[31:0] = `CL_VERSION;

//-----------------------------------------------
// Debug bridge, used if need Virtual JTAG
//-----------------------------------------------
`ifndef DISABLE_VJTAG_DEBUG

// Flop for timing global clock counter
logic[63:0] sh_cl_glcount0_q;

always_ff @(posedge clk_main_a0)
   if (!rst_main_n_sync)
      sh_cl_glcount0_q <= 0;
   else
      sh_cl_glcount0_q <= sh_cl_glcount0;


logic zeroila;
assign zeroila = 64'b0;

// Integrated Logic Analyzers (ILA)
   ila_0 CL_ILA_0 (
                   .clk    (clk_main_a0),
                   .probe0 (zeroila),
                   .probe1 (zeroila),
                   .probe2 (zeroila),
                   .probe3 (zeroila),
                   .probe4 (zeroila),
                   .probe5 (zeroila)
                   );

   ila_0 CL_ILA_1 (
                   .clk    (clk_main_a0),
                   .probe0 (zeroila),
                   .probe1 (zeroila),
                   .probe2 (zeroila),
                   .probe3 (zeroila),
                   .probe4 (zeroila),
                   .probe5 (zeroila)
                   );

// Debug Bridge 
 cl_debug_bridge CL_DEBUG_BRIDGE (
      .clk(clk_main_a0),
      .S_BSCAN_drck(drck),
      .S_BSCAN_shift(shift),
      .S_BSCAN_tdi(tdi),
      .S_BSCAN_update(update),
      .S_BSCAN_sel(sel),
      .S_BSCAN_tdo(tdo),
      .S_BSCAN_tms(tms),
      .S_BSCAN_tck(tck),
      .S_BSCAN_runtest(runtest),
      .S_BSCAN_reset(reset),
      .S_BSCAN_capture(capture),
      .S_BSCAN_bscanid_en(bscanid_en)
   );

//-----------------------------------------------
// VIO Example - Needs Virtual JTAG
//-----------------------------------------------
   // Counter running at 125MHz
   
   logic      vo_cnt_enable;
   logic      vo_cnt_load;
   logic      vo_cnt_clear;
   logic      vo_cnt_oneshot;
   logic [7:0]  vo_tick_value;
   logic [15:0] vo_cnt_load_value;
   logic [15:0] vo_cnt_watermark;

   logic      vo_cnt_enable_q = 0;
   logic      vo_cnt_load_q = 0;
   logic      vo_cnt_clear_q = 0;
   logic      vo_cnt_oneshot_q = 0;
   logic [7:0]  vo_tick_value_q = 0;
   logic [15:0] vo_cnt_load_value_q = 0;
   logic [15:0] vo_cnt_watermark_q = 0;

   logic        vi_tick;
   logic        vi_cnt_ge_watermark;
   logic [7:0]  vi_tick_cnt = 0;
   logic [15:0] vi_cnt = 0;
   
   // Tick counter and main counter
   always @(posedge clk_main_a0) begin

      vo_cnt_enable_q     <= vo_cnt_enable    ;
      vo_cnt_load_q       <= vo_cnt_load      ;
      vo_cnt_clear_q      <= vo_cnt_clear     ;
      vo_cnt_oneshot_q    <= vo_cnt_oneshot   ;
      vo_tick_value_q     <= vo_tick_value    ;
      vo_cnt_load_value_q <= vo_cnt_load_value;
      vo_cnt_watermark_q  <= vo_cnt_watermark ;

      vi_tick_cnt = vo_cnt_clear_q ? 0 :
                    ~vo_cnt_enable_q ? vi_tick_cnt :
                    (vi_tick_cnt >= vo_tick_value_q) ? 0 :
                    vi_tick_cnt + 1;

      vi_cnt = vo_cnt_clear_q ? 0 :
               vo_cnt_load_q ? vo_cnt_load_value_q :
               ~vo_cnt_enable_q ? vi_cnt :
               (vi_tick_cnt >= vo_tick_value_q) && (~vo_cnt_oneshot_q || (vi_cnt <= 16'hFFFF)) ? vi_cnt + 1 :
               vi_cnt;

      vi_tick = (vi_tick_cnt >= vo_tick_value_q);

      vi_cnt_ge_watermark = (vi_cnt >= vo_cnt_watermark_q);
      
   end // always @ (posedge clk_main_a0)
   

   vio_0 CL_VIO_0 (
                   .clk    (clk_main_a0),
                   .probe_in0  (vi_tick),
                   .probe_in1  (vi_cnt_ge_watermark),
                   .probe_in2  (vi_tick_cnt),
                   .probe_in3  (vi_cnt),
                   .probe_out0 (vo_cnt_enable),
                   .probe_out1 (vo_cnt_load),
                   .probe_out2 (vo_cnt_clear),
                   .probe_out3 (vo_cnt_oneshot),
                   .probe_out4 (vo_tick_value),
                   .probe_out5 (vo_cnt_load_value),
                   .probe_out6 (vo_cnt_watermark)
                   );
   
   ila_vio_counter CL_VIO_ILA (
                   .clk     (clk_main_a0),
                   .probe0  (vi_tick),
                   .probe1  (vi_cnt_ge_watermark),
                   .probe2  (vi_tick_cnt),
                   .probe3  (vi_cnt),
                   .probe4  (vo_cnt_enable_q),
                   .probe5  (vo_cnt_load_q),
                   .probe6  (vo_cnt_clear_q),
                   .probe7  (vo_cnt_oneshot_q),
                   .probe8  (vo_tick_value_q),
                   .probe9  (vo_cnt_load_value_q),
                   .probe10 (vo_cnt_watermark_q)
                   );
   
`endif //  `ifndef DISABLE_VJTAG_DEBUG

endmodule
