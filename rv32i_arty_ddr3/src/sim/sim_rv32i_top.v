//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 4.0
//  \   \         Application        : MIG
//  /   /         Filename           : sim_tb_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/07 13:45:16 $
// \   \  /  \    Date Created       : Tue Sept 21 2010
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : DDR3 SDRAM
// Purpose          :
//                   Top-level testbench for testing DDR3.
//                   Instantiates:
//                     1. IP_TOP (top-level representing FPGA, contains core,
//                        clocking, built-in testbench/memory checker and other
//                        support structures)
//                     2. DDR3 Memory
//                     3. Miscellaneous clock generation and reset logic
//                     4. For ECC ON case inserts error on LSB bit
//                        of data from DRAM to FPGA.
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/100fs

module sim_rv32i_top;

localparam DMI_REQOP_NOP = 2'h0;
localparam DMI_REQOP_RD = 2'h1;
localparam DMI_REQOP_WR = 2'h2;

localparam DMI_ADDR_SBADDRESS0 = 7'h39;
localparam DMI_ADDR_SBDATA0 = 7'h3C;

localparam DMI_ADDR_WIDTH = 7;
localparam DMI_DATA_WIDTH = 32;
localparam DMI_OP_WIDTH = 2;
localparam JTAG_DATA_WIDTH = (DMI_ADDR_WIDTH+DMI_DATA_WIDTH+DMI_OP_WIDTH);
localparam TX_WIDTH = (DMI_ADDR_WIDTH+DMI_DATA_WIDTH+DMI_OP_WIDTH);
localparam RX_WIDTH = (DMI_DATA_WIDTH+DMI_OP_WIDTH);

//parameter CLOCK_FREQ_MHZ = 100.0;
parameter CLOCK_FREQ_MHZ = 10.0;
//Because simulation operation time unit is 1ns from first "`timescale 1ns / 1ps" first parameter
//Therefore, 1MHz is equal 1000ns period, K MHz is equal (1000/K) ns
parameter CLOCK_PROIOD = 1000.0*1000.0/CLOCK_FREQ_MHZ; //1ps
reg         clock;
initial begin clock = 1'b0; forever clock = #(CLOCK_PROIOD/2) ~clock; end

parameter BASE_CLOCK_FREQ_MHZ = 100.0;
parameter BASE_CLOCK_PROIOD = 1000.0*1000.0/BASE_CLOCK_FREQ_MHZ; // 1ps
reg base_clock;
initial begin base_clock = 1'b0; forever base_clock = #(BASE_CLOCK_PROIOD/2) ~base_clock; end

//parameter JCLK_FREQ_MHZ = 100.0;
parameter JCLK_FREQ_MHZ = 15.0;
parameter JCLK_PROIOD = 1000.0*1000.0/JCLK_FREQ_MHZ;
reg jclk; //Jtag Clock
initial begin jclk = 1'b0; forever jclk = #(JCLK_PROIOD/2) ~jclk; end

//Xilinx JTAG simulation
wire tdo;
wire tck;
reg tdi;
reg tms;

reg [JTAG_DATA_WIDTH-1:0] jtx_data = 'h0;
reg [JTAG_DATA_WIDTH-1:0] jrx_data = 'h0;

reg jtck_en = 1'b0;
assign tck = jclk&jtck_en;


   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter COL_WIDTH             = 10;
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1;
                                     // # of unique CS outputs to memory.
   parameter DM_WIDTH              = 2;
                                     // # of DM (data mask)
   parameter DQ_WIDTH              = 16;
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 2;
   parameter DQS_CNT_WIDTH         = 1;
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8;
                                     // # of DQ per DQS
   parameter ECC                   = "OFF";
   parameter RANKS                 = 1;
                                     // # of Ranks.
   parameter ODT_WIDTH             = 1;
                                     // # of ODT outputs to memory.
   parameter ROW_WIDTH             = 14;
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28;
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter CA_MIRROR             = "OFF";
                                     // C/A mirror opt for DDR3 dual rank

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIM_BYPASS_INIT_CAL   = "FAST";
                                     // # = "SIM_INIT_CAL_FULL" -  Complete
                                     //              memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter RST_ACT_LOW           = 1;
                                     // =1 for active low reset,
                                     // =0 for active high.
  
  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//

  localparam real TPROP_DQS          = 0.00;
                                       // Delay for DQS signal during Write Operation
  localparam real TPROP_DQS_RD       = 0.00;
                       // Delay for DQS signal during Read Operation
  localparam real TPROP_PCB_CTRL     = 0.00;
                       // Delay for Address and Ctrl signals
  localparam real TPROP_PCB_DATA     = 0.00;
                       // Delay for data signal during Write operation
  localparam real TPROP_PCB_DATA_RD  = 0.00;
                       // Delay for data signal during Read operation

  localparam MEMORY_WIDTH            = 16;
  localparam NUM_COMP                = DQ_WIDTH/MEMORY_WIDTH;
  localparam ECC_TEST 		   	= "OFF" ;
  localparam ERR_INSERT = (ECC_TEST == "ON") ? "OFF" : ECC ;
  
  localparam RESET_PERIOD = 200000; //in pSec  
    

  //**************************************************************************//
  // Wire Declarations
  //**************************************************************************//
  reg                                sys_rst_n;
  wire                               sys_rst;
  
  wire                               ddr3_reset_n;
  wire [DQ_WIDTH-1:0]                ddr3_dq_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_fpga;
  wire [ROW_WIDTH-1:0]               ddr3_addr_fpga;
  wire [3-1:0]              ddr3_ba_fpga;
  wire                               ddr3_ras_n_fpga;
  wire                               ddr3_cas_n_fpga;
  wire                               ddr3_we_n_fpga;
  wire [1-1:0]               ddr3_cke_fpga;
  wire [1-1:0]                ddr3_ck_p_fpga;
  wire [1-1:0]                ddr3_ck_n_fpga;
    
  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_fpga;
  wire [DM_WIDTH-1:0]                ddr3_dm_fpga;
  wire [ODT_WIDTH-1:0]               ddr3_odt_fpga;
  reg [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram_tmp;
  reg [DM_WIDTH-1:0]                 ddr3_dm_sdram_tmp;
  reg [ODT_WIDTH-1:0]                ddr3_odt_sdram_tmp;
  wire [DQ_WIDTH-1:0]                ddr3_dq_sdram;
  reg [ROW_WIDTH-1:0]                ddr3_addr_sdram [0:1];
  reg [3-1:0]               ddr3_ba_sdram [0:1];
  reg                                ddr3_ras_n_sdram;
  reg                                ddr3_cas_n_sdram;
  reg                                ddr3_we_n_sdram;
  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram;
  wire [ODT_WIDTH-1:0]               ddr3_odt_sdram;
  reg [1-1:0]                ddr3_cke_sdram;
  wire [DM_WIDTH-1:0]                ddr3_dm_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_sdram;
  reg [1-1:0]                 ddr3_ck_p_sdram;
  reg [1-1:0]                 ddr3_ck_n_sdram;
  
  wire init_calib_complete;
  
//**************************************************************************//

  //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
  initial begin
    sys_rst_n = 1'b0;
    #RESET_PERIOD
      sys_rst_n = 1'b1;
   end

   assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  always @( * ) begin
    ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
    ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
    ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_addr_fpga[ROW_WIDTH-1:9],
                                                  ddr3_addr_fpga[7], ddr3_addr_fpga[8],
                                                  ddr3_addr_fpga[5], ddr3_addr_fpga[6],
                                                  ddr3_addr_fpga[3], ddr3_addr_fpga[4],
                                                  ddr3_addr_fpga[2:0]} :
                                                 ddr3_addr_fpga;
    ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_ba_fpga[3-1:2],
                                                  ddr3_ba_fpga[0],
                                                  ddr3_ba_fpga[1]} :
                                                 ddr3_ba_fpga;
    ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
    ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
    ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
    ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
  end
    

  always @( * )
    ddr3_cs_n_sdram_tmp   <=  #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;
  assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;
    

  always @( * )
    ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
  assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;
    

  always @( * )
    ddr3_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;
  assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;
    

// Controlling the bi-directional BUS

  genvar dqwd;
  generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq
       (
        .A             (ddr3_dq_fpga[dqwd]),
        .B             (ddr3_dq_sdram[dqwd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
       );
    end
          WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq_0
       (
        .A             (ddr3_dq_fpga[0]),
        .B             (ddr3_dq_sdram[0]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
       );
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_p
       (
        .A             (ddr3_dqs_p_fpga[dqswd]),
        .B             (ddr3_dqs_p_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
       );

      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_n
       (
        .A             (ddr3_dqs_n_fpga[dqswd]),
        .B             (ddr3_dqs_n_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
       );
    end
  endgenerate
  
  //===========================================================================
  //                         FPGA Core
  //===========================================================================

rv32i_top rv32i_dut (
//DDR3 =========================
.ddr3_dq              (ddr3_dq_fpga),
.ddr3_dqs_n           (ddr3_dqs_n_fpga),
.ddr3_dqs_p           (ddr3_dqs_p_fpga),
.ddr3_addr            (ddr3_addr_fpga),
.ddr3_ba              (ddr3_ba_fpga),
.ddr3_ras_n           (ddr3_ras_n_fpga),
.ddr3_cas_n           (ddr3_cas_n_fpga),
.ddr3_we_n            (ddr3_we_n_fpga),
.ddr3_reset_n         (ddr3_reset_n),
.ddr3_ck_p            (ddr3_ck_p_fpga),
.ddr3_ck_n            (ddr3_ck_n_fpga),
.ddr3_cke             (ddr3_cke_fpga),
.ddr3_cs_n            (ddr3_cs_n_fpga),
.ddr3_dm              (ddr3_dm_fpga),
.ddr3_odt             (ddr3_odt_fpga),

.led(),
.board_clock(base_clock)
);
                    

  //**************************************************************************//
  // Memory Models instantiations
  //**************************************************************************//

  genvar r,i;
  generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      if(DQ_WIDTH/16) begin: mem
        for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
          ddr3_model u_comp_ddr3
            (
             .rst_n   (ddr3_reset_n),
             .ck      (ddr3_ck_p_sdram),
             .ck_n    (ddr3_ck_n_sdram),
             .cke     (ddr3_cke_sdram[r]),
             .cs_n    (ddr3_cs_n_sdram[r]),
             .ras_n   (ddr3_ras_n_sdram),
             .cas_n   (ddr3_cas_n_sdram),
             .we_n    (ddr3_we_n_sdram),
             .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
             .ba      (ddr3_ba_sdram[r]),
             .addr    (ddr3_addr_sdram[r]),
             .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
             .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
             .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
             .tdqs_n  (),
             .odt     (ddr3_odt_sdram[r])
             );
        end
      end
      if (DQ_WIDTH%16) begin: gen_mem_extrabits
        ddr3_model u_comp_ddr3
          (
           .rst_n   (ddr3_reset_n),
           .ck      (ddr3_ck_p_sdram),
           .ck_n    (ddr3_ck_n_sdram),
           .cke     (ddr3_cke_sdram[r]),
           .cs_n    (ddr3_cs_n_sdram[r]),
           .ras_n   (ddr3_ras_n_sdram),
           .cas_n   (ddr3_cas_n_sdram),
           .we_n    (ddr3_we_n_sdram),
           .dm_tdqs ({ddr3_dm_sdram[DM_WIDTH-1],ddr3_dm_sdram[DM_WIDTH-1]}),
           .ba      (ddr3_ba_sdram[r]),
           .addr    (ddr3_addr_sdram[r]),
           .dq      ({ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)],
                      ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
           .dqs     ({ddr3_dqs_p_sdram[DQS_WIDTH-1],
                      ddr3_dqs_p_sdram[DQS_WIDTH-1]}),
           .dqs_n   ({ddr3_dqs_n_sdram[DQS_WIDTH-1],
                      ddr3_dqs_n_sdram[DQS_WIDTH-1]}),
           .tdqs_n  (),
           .odt     (ddr3_odt_sdram[r])
           );
      end
    end
  endgenerate

//***************************************************************************
// Simulation Main Task
//***************************************************************************

assign init_calib_complete = rv32i_dut.rvmemspv.init_calib_complete;

initial
begin : sim_main
    
    jtck_en = 1'b0;
    
    wait (rv32i_dut.init_ddr3_done);
    $display("Calibration Done");
    
    repeat(4) @(posedge jclk);
        
    goto_rti();
    shift_ir(6'h09); //IDCODE
    shift_dr('h0, 32); //Read IDCODE //7A35T  0x362D093
    
    shift_ir(6'h23); //USER4

    sim_jtag_op(DMI_ADDR_SBADDRESS0, 32'h80001000, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(DMI_ADDR_SBADDRESS0, 32'h80001000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h12345678, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h00000000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
//    shift_ir(6'h22); //USER3
//    shift_dr('h1, 32); //set jsys_reset
//    $display("JTAG Reset System");
//    shift_dr('h0, 32); //read jsys_reset
    
//    wait (rv32i_dut.pll_locked);
    
//    shift_dr('h0, 32); //read jsys_reset
    
//    wait (rv32i_dut.init_ddr3_done);
//    $display("Calibration Done");
    
//    shift_dr('h0, 32); //read jsys_reset
    
    repeat(10) @(posedge clock);
    $finish;
    
end

task sim_jtag_op;
    input [6:0] addr;
    input [31:0] data;
    input [1:0] op;
    integer i;
    begin
        $display("SHIFT-DR: %X", {addr, data, op});
        shift_dr({addr, data, op}, JTAG_DATA_WIDTH);
    end
endtask

task goto_rti;
    begin
        repeat(1) @(negedge jclk);
        
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        #0.1 tms = 1; //goto TLR
        repeat(5) @(negedge jclk);  
        //jtck_en = 0;
        //repeat(2) @(negedge jclk);
        
        //at TLR
        #0.1 tms = 0; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        #0.1 jtck_en = 0;
    end
endtask

task shift_ir;
    input [5:0] addr;
    integer i;
    begin
        //at RTI
        #0.1 tms = 1; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk); 
        #0.1 tms = 1; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk); 
        
        //at  SELECT-IR-SCAN
        tms = 0; 
        jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        //at CAPTURE-IR 
        #0.1 tms = 0; 
        #0.1 tdi = 0;
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        //at  SHIFT-IR
        for(i=0; i<5; i=i+1) begin
            #0.1 tms = 0; 
            #0.1 tdi = addr[i];
            #0.1 jtck_en = 1;
            repeat(1) @(negedge jclk);
        end
        #0.1 tms = 1; //Last SHIFT-IR bit
        #0.1 tdi = addr[i];
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        //at EXIT1-IR
        #0.1 tms = 1; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        //at UPDATE-IR 
        #0.1 tms = 0; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        //at RTI
        #0.1 jtck_en = 0;
        
        $display("JTAG IR ",  "0x%X, ", addr);
    end
endtask

task shift_dr;
    input [JTAG_DATA_WIDTH-1:0] data;
    input integer dlen;
    integer i;
    begin
        //at RTI
        #0.1 tms = 1; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk); 
        
        //at  SELECT-DR-SCAN
        #0.1 tms = 0; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);

        //at CAPTURE-DR 
        #0.1 tms = 0; 
        #0.1 tdi = 0;
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        //at  SHIFT-DR
        jtx_data = data;
        jrx_data = 'h0;
        for(i=0; i<(dlen-1); i=i+1) begin
            #0.1 tms = 0; 
            #0.1 tdi = data[i];
            jrx_data[i] = tdo;
            #0.1 jtck_en = 1;
            repeat(1) @(negedge jclk);
        end
        #0.1 tms = 1; //Last SHIFT-DR bit
        #0.1 tdi = data[i];
        #0.1 jrx_data[i] = tdo;
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        
        //at EXIT1-DR
        #0.1 tms = 1; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        //at UPDATE-DR 
        #0.1 tms = 0; 
        #0.1 jtck_en = 1;
        repeat(1) @(negedge jclk);
        //at RTI
        #0.1 jtck_en = 0;
        
        if(dlen == JTAG_DATA_WIDTH) begin
            $display("JTAG DR ",  "TX:", 
                                "A[%X]", jtx_data[(DMI_DATA_WIDTH+DMI_OP_WIDTH)+:DMI_ADDR_WIDTH],
                                "_D[%X]", jtx_data[DMI_OP_WIDTH+:DMI_DATA_WIDTH],
                                "_O[%X]", jtx_data[0+:DMI_OP_WIDTH],
                                ", RX:",
                                "A[%X]", jrx_data[(DMI_DATA_WIDTH+DMI_OP_WIDTH)+:DMI_ADDR_WIDTH],
                                "_D[%X]", jrx_data[DMI_OP_WIDTH+:DMI_DATA_WIDTH],
                                "_O[%X]", jrx_data[0+:DMI_OP_WIDTH]);
        end
        else begin
            $display("JTAG DR ",  "TX: 0x%X, ", jtx_data, "RX: 0x%X", jrx_data);
        end
    end
endtask

initial begin: init_value
    tdi = 1'b0;
    tms = 1'b0;
end

JTAG_SIME2 #(
    .PART_NAME("7A35T")
) jtag_sim_arty_inst (
    .TDO(tdo), // 1-bit JTAG data output
    .TCK(tck), // 1-bit Clock input
    .TDI(tdi), // 1-bit JTAG data input
    .TMS(tms) // 1-bit JTAG command input
);
  
endmodule
