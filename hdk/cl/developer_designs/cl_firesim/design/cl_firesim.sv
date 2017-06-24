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


//--------------------------------------------0
// Start with Tie-Off of Unused Interfaces
//---------------------------------------------
// the developer should use the next set of `include
// to properly tie-off any unused interface
// The list is put in the top of the module
// to avoid cases where developer may forget to
// remove it from the end of the file

`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
// `include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_hmc_template.inc"
`include "unused_aurora_template.inc"

//-------------------------------------------------
// Wires
//-------------------------------------------------
  logic        arvalid_q;
  logic [31:0] araddr_q;
  logic [31:0] hello_world_q_byte_swapped;
  logic [15:0] vled_q;
  logic [15:0] pre_cl_sh_status_vled;
  logic [15:0] sh_cl_status_vdip_q;
  logic [15:0] sh_cl_status_vdip_q2;
  logic [31:0] hello_world_q;

//-------------------------------------------------
// ID Values (cl_hello_world_defines.vh)
//-------------------------------------------------
  assign cl_sh_id0[31:0] = `CL_SH_ID0;
  assign cl_sh_id1[31:0] = `CL_SH_ID1;

//-------------------------------------------------
// Reset Synchronization
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


  // pipeline registers to break timing path
  // see https://www.xilinx.com/support/documentation/ip_documentation/axi_interconnect/v2_1/pg059-axi-interconnect.pdf
  // page 5
  axi_register_slice_light AXIL_OCL_REG_SLC (
   .aclk          (clk_main_a0),
   .aresetn       (rst_main_n_sync),
   .s_axi_awaddr  (sh_ocl_awaddr),
   .s_axi_awprot   (2'h0),
   .s_axi_awvalid (sh_ocl_awvalid),
   .s_axi_awready (ocl_sh_awready),
   .s_axi_wdata   (sh_ocl_wdata),
   .s_axi_wstrb   (sh_ocl_wstrb),
   .s_axi_wvalid  (sh_ocl_wvalid),
   .s_axi_wready  (ocl_sh_wready),
   .s_axi_bresp   (ocl_sh_bresp),
   .s_axi_bvalid  (ocl_sh_bvalid),
   .s_axi_bready  (sh_ocl_bready),
   .s_axi_araddr  (sh_ocl_araddr),
   .s_axi_arvalid (sh_ocl_arvalid),
   .s_axi_arready (ocl_sh_arready),
   .s_axi_rdata   (ocl_sh_rdata),
   .s_axi_rresp   (ocl_sh_rresp),
   .s_axi_rvalid  (ocl_sh_rvalid),
   .s_axi_rready  (sh_ocl_rready),
   .m_axi_awaddr  (sh_ocl_awaddr_q),
   .m_axi_awprot  (),
   .m_axi_awvalid (sh_ocl_awvalid_q),
   .m_axi_awready (ocl_sh_awready_q),
   .m_axi_wdata   (sh_ocl_wdata_q),
   .m_axi_wstrb   (sh_ocl_wstrb_q),
   .m_axi_wvalid  (sh_ocl_wvalid_q),
   .m_axi_wready  (ocl_sh_wready_q),
   .m_axi_bresp   (ocl_sh_bresp_q),
   .m_axi_bvalid  (ocl_sh_bvalid_q),
   .m_axi_bready  (sh_ocl_bready_q),
   .m_axi_araddr  (sh_ocl_araddr_q),
   .m_axi_arvalid (sh_ocl_arvalid_q),
   .m_axi_arready (ocl_sh_arready_q),
   .m_axi_rdata   (ocl_sh_rdata_q),
   .m_axi_rresp   (ocl_sh_rresp_q),
   .m_axi_rvalid  (ocl_sh_rvalid_q),
   .m_axi_rready  (sh_ocl_rready_q)
  );

    /* instantiate firesim top level here */

   // TODO: switch to AXI width converter IP on DDR IF, or change rocket-chip config
  wire [31:0] io_slave_aw_bits_addr;
  assign cl_sh_dr_awaddr = { 29'b0, io_slave_aw_bits_addr, 3'b0 }; // TODO: check this

  wire [63:0] io_slave_w_bits_data;
  assign cl_sh_ddr_wdata = { 448'b0, io_slave_w_bits_data };

  wire [7:0] io_slave_w_bits_strb;
  assign cl_sh_ddr_wstrb = { 56'b0, io_slave_w_bits_strb };

  wire [31:0] io_slave_ar_bits_addr;
  assign cl_sh_ddr_araddr = { 29'b0, io_slave_ar_bits_addr, 3'b0 };

  F1Shim firesim_top (
   .clock(clk_main_a0),
   .reset(~rst_main_n_sync),
   .io_master_aw_ready(ocl_sh_awready_q),
   .io_master_aw_valid(sh_ocl_awvalid_q),
   .io_master_aw_bits_addr(sh_ocl_awaddr_q),
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
   .io_master_ar_bits_addr(sh_ocl_araddr_q),
   .io_master_ar_bits_len(8'h0),
   .io_master_ar_bits_size(3'h3),
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

   .io_slave_aw_ready(sh_cl_ddr_awready),
   .io_slave_aw_valid(cl_sh_ddr_awvalid),
   .io_slave_aw_bits_addr(io_slave_aw_bits_addr),
   .io_slave_aw_bits_len(cl_sh_ddr_awlen),
   .io_slave_aw_bits_size(cl_sh_ddr_awsize),
   .io_slave_aw_bits_burst(), // not available on DDR IF
   .io_slave_aw_bits_lock(), // not available on DDR IF
   .io_slave_aw_bits_cache(), // not available on DDR IF
   .io_slave_aw_bits_prot(), // not available on DDR IF
   .io_slave_aw_bits_qos(), // not available on DDR IF
   .io_slave_aw_bits_region(), // not available on DDR IF
   .io_slave_aw_bits_id(cl_sh_ddr_awid),
   .io_slave_aw_bits_user(), // not available on DDR IF

   .io_slave_w_ready(sh_cl_ddr_wready),
   .io_slave_w_valid(cl_sh_ddr_wvalid),
   .io_slave_w_bits_data(io_slave_w_bits_data),
   .io_slave_w_bits_last(cl_sh_ddr_wlast),
   .io_slave_w_bits_id(cl_sh_ddr_wid),
   .io_slave_w_bits_strb(io_slave_w_bits_strb),
   .io_slave_w_bits_user(), // not available on DDR IF

   .io_slave_b_ready(cl_sh_ddr_bready),
   .io_slave_b_valid(sh_cl_ddr_bvalid),
   .io_slave_b_bits_resp(sh_cl_ddr_bresp),
   .io_slave_b_bits_id(sh_cl_ddr_bid),
   .io_slave_b_bits_user(1'b0), // TODO check this

   .io_slave_ar_ready(sh_cl_ddr_arready),
   .io_slave_ar_valid(cl_sh_ddr_arvalid),
   .io_slave_ar_bits_addr(io_slave_ar_bits_addr),
   .io_slave_ar_bits_len(cl_sh_ddr_arlen),
   .io_slave_ar_bits_size(cl_sh_ddr_arsize),
   .io_slave_ar_bits_burst(), // not available on DDR IF
   .io_slave_ar_bits_lock(), // not available on DDR IF
   .io_slave_ar_bits_cache(), // not available on DDR IF
   .io_slave_ar_bits_prot(), // not available on DDR IF
   .io_slave_ar_bits_qos(), // not available on DDR IF
   .io_slave_ar_bits_region(), // not available on DDR IF
   .io_slave_ar_bits_id(cl_sh_ddr_arid), // not available on DDR IF
   .io_slave_ar_bits_user(), // not available on DDR IF

   .io_slave_r_ready(cl_sh_ddr_rready),
   .io_slave_r_valid(sh_cl_ddr_rvalid),
   .io_slave_r_bits_resp(sh_cl_ddr_rresp),
   .io_slave_r_bits_data(sh_cl_ddr_rdata[63:0]),
   .io_slave_r_bits_last(sh_cl_ddr_rlast),
   .io_slave_r_bits_id(sh_cl_ddr_rid),
   .io_slave_r_bits_user(1'b0) // TODO check this
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


// Integrated Logic Analyzers (ILA)
   ila_0 CL_ILA_0 (
                   .clk    (clk_main_a0),
                   .probe0 (sh_ocl_awvalid_q),
                   .probe1 (sh_ocl_awaddr_q ),
                   .probe2 (ocl_sh_awready_q),
                   .probe3 (sh_ocl_arvalid_q),
                   .probe4 (sh_ocl_araddr_q ),
                   .probe5 (ocl_sh_arready_q)
                   );

   ila_0 CL_ILA_1 (
                   .clk    (clk_main_a0),
                   .probe0 (ocl_sh_bvalid_q),
                   .probe1 (sh_cl_glcount0_q),
                   .probe2 (sh_ocl_bready_q),
                   .probe3 (ocl_sh_rvalid_q),
                   .probe4 ({32'b0,ocl_sh_rdata_q[31:0]}),
                   .probe5 (sh_ocl_rready_q)
                   );

// Debug Bridge 
 cl_debug_bridge CL_DEBUG_BRIDGE (
      .clk(clk_main_a0),
      .S_BSCAN_VEC_drck(drck),
      .S_BSCAN_VEC_shift(shift),
      .S_BSCAN_VEC_tdi(tdi),
      .S_BSCAN_VEC_update(update),
      .S_BSCAN_VEC_sel(sel),
      .S_BSCAN_VEC_tdo(tdo),
      .S_BSCAN_VEC_tms(tms),
      .S_BSCAN_VEC_tck(tck),
      .S_BSCAN_VEC_runtest(runtest),
      .S_BSCAN_VEC_reset(reset),
      .S_BSCAN_VEC_capture(capture),
      .S_BSCAN_VEC_bscanid(bscanid)
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





