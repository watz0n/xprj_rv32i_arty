`timescale 1ns / 1ps

module rv32i_top(
    input board_clock
);

localparam DMI_ADDR_WIDTH = 7;
localparam DMI_DATA_WIDTH = 32;
localparam DMI_OP_WIDTH = 2;
localparam JTAG_DATA_WIDTH = (DMI_ADDR_WIDTH+DMI_DATA_WIDTH+DMI_OP_WIDTH);
localparam TX_WIDTH = (DMI_ADDR_WIDTH+DMI_DATA_WIDTH+DMI_OP_WIDTH);
localparam RX_WIDTH = (DMI_DATA_WIDTH+DMI_OP_WIDTH);

wire        reset; 
wire        clock;
wire        pll_locked;

wire  [1:0]  io_dmi_req_bits_op;
wire  [6:0]  io_dmi_req_bits_addr;
wire  [31:0] io_dmi_req_bits_data;
wire         io_dmi_req_valid;
wire        io_dmi_req_ready;
wire [1:0]  io_dmi_resp_bits_resp;
wire [31:0] io_dmi_resp_bits_data;
wire        io_dmi_resp_valid;
wire         io_dmi_resp_ready;
wire        io_ext_mem_waen;
wire        io_ext_mem_wden;
wire [31:0] io_ext_mem_waddr;
wire [31:0] io_ext_mem_wdata;
wire [3:0]  io_ext_mem_wmask;
wire         io_ext_mem_wardy;
wire         io_ext_mem_wdrdy;
wire         io_ext_mem_wbvld;
wire        io_ext_mem_raen;
wire        io_ext_mem_rden;
wire [31:0] io_ext_mem_raddr;
wire  [31:0] io_ext_mem_rdata;
wire         io_ext_mem_rardy;
wire         io_ext_mem_rdrdy;
wire        io_ext_mem_clock;
wire        io_ext_mem_reset;

wire creq_vld;
wire [TX_WIDTH-1:0] creq_data;
wire creq_rdy;
wire cresp_vld;
wire [RX_WIDTH-1:0] cresp_data;
wire cresp_rdy;

// Core External Memory Interface
wire waen;
wire wden;
wire [31:0] waddr;
wire [31:0] wdata;
wire [3:0] wmask;
wire wardy;
wire wdrdy;
wire wbvld;
wire raen;
wire rden;
wire [31:0] raddr;
wire [31:0] rdata;
wire rardy;
wire rdrdy;

wire bufg_board_clock;
wire debug_clock;

wire jsys_reset;

assign reset = ~pll_locked;

BUFG BUFG_BD (
    .O(bufg_board_clock), // Clock buffer output
    .I(board_clock) // Clock buffer input (connect directly to top-level port)
);

core_pll core_clock (
    // Clock out ports
    .clk_out1(clock),
    .clk_out2(debug_clock),
    // Status and control signals
    //.reset(1'b0), // input reset
    .reset(jsys_reset),
    .locked(pll_locked),       // output locked
    // Clock in ports
    .clk_in1(bufg_board_clock)
);      // input clk_in1

jtag_if jtag_if_dev (

    //Core Interface
    .creq_vld(creq_vld),
    .creq_data(creq_data),
    .creq_rdy(creq_rdy),
    .cresp_vld(cresp_vld),
    .cresp_data(cresp_data),
    .cresp_rdy(cresp_rdy),

    .reset(reset),
    .clock(clock),

    //Output List
    .jsys_reset(jsys_reset),
    //Input List
    .init_ddr3_done(1'b1)
);

assign io_dmi_req_bits_op = creq_data[0+:2];
assign io_dmi_req_bits_data = creq_data[2+:32];
assign io_dmi_req_bits_addr = creq_data[34+:7];
assign io_dmi_req_valid = creq_vld;
assign creq_rdy = io_dmi_req_ready;

assign cresp_vld = io_dmi_resp_valid;
assign cresp_data = {io_dmi_resp_bits_data, io_dmi_resp_bits_resp};
assign io_dmi_resp_ready = cresp_rdy;

rv32i_fpga rv32i (
    .clock(clock),
    .reset(reset),
    .io_dmi_req_bits_op(io_dmi_req_bits_op),
    .io_dmi_req_bits_addr(io_dmi_req_bits_addr),
    .io_dmi_req_bits_data(io_dmi_req_bits_data),
    .io_dmi_req_valid(io_dmi_req_valid),
    .io_dmi_req_ready(io_dmi_req_ready),
    .io_dmi_resp_bits_resp(io_dmi_resp_bits_resp),
    .io_dmi_resp_bits_data(io_dmi_resp_bits_data),
    .io_dmi_resp_valid(io_dmi_resp_valid),
    .io_dmi_resp_ready(io_dmi_resp_ready),
    .io_ext_mem_waen(io_ext_mem_waen),
    .io_ext_mem_wden(io_ext_mem_wden),
    .io_ext_mem_waddr(io_ext_mem_waddr),
    .io_ext_mem_wdata(io_ext_mem_wdata),
    .io_ext_mem_wmask(io_ext_mem_wmask),
    .io_ext_mem_wardy(io_ext_mem_wardy),
    .io_ext_mem_wdrdy(io_ext_mem_wdrdy),
    .io_ext_mem_wbvld(io_ext_mem_wbvld),
    .io_ext_mem_raen(io_ext_mem_raen),
    .io_ext_mem_rden(io_ext_mem_rden),
    .io_ext_mem_raddr(io_ext_mem_raddr),
    .io_ext_mem_rdata(io_ext_mem_rdata),
    .io_ext_mem_rardy(io_ext_mem_rardy),
    .io_ext_mem_rdrdy(io_ext_mem_rdrdy),
    .io_ext_mem_clock(io_ext_mem_clock),
    .io_ext_mem_reset(io_ext_mem_reset)
);

assign waen = io_ext_mem_waen;
assign wden = io_ext_mem_wden;
assign waddr = io_ext_mem_waddr;
assign wdata = io_ext_mem_wdata;
assign wmask = io_ext_mem_wmask;
assign io_ext_mem_wardy = wardy;
assign io_ext_mem_wdrdy = wdrdy;
assign io_ext_mem_wbvld = wbvld;
assign raen = io_ext_mem_raen;
assign rden = io_ext_mem_rden;
assign raddr = io_ext_mem_raddr;
assign io_ext_mem_rdata = rdata;
assign io_ext_mem_rardy = rardy;
assign io_ext_mem_rdrdy = rdrdy;

rvmemspv rvmemspv (
    .waen(waen),
    .wden(wden),
    .waddr(waddr),
    .wdata(wdata),
    .wmask(wmask),
    .wardy(wardy),
    .wdrdy(wdrdy),
    .wbvld(wbvld),
    .raen(raen),
    .rden(rden),
    .raddr(raddr),
    .rdata(rdata),
    .rardy(rardy),
    .rdrdy(rdrdy),
    
    .reset(reset),
    .clock(clock)
);

endmodule
