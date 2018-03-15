module rvmemspv #( 
    //parameter MEM_SIZE = 'h100000,
    parameter MEM_ADDR_WIDTH = 32,
    parameter MEM_DATA_WIDTH = 32,
    parameter MASK_WIDTH = MEM_DATA_WIDTH/8
    //parameter WRITE_DELAY = 1,
    //parameter READ_DELAY = 1 
)(
    input waen,
    input wden,
    input [MEM_ADDR_WIDTH-1:0] waddr,
    input [MEM_DATA_WIDTH-1:0] wdata,
    input [MASK_WIDTH-1:0] wmask,
    output wardy,
    output wdrdy,
    output wbvld,
    input raen,
    input rden,
    input [MEM_ADDR_WIDTH-1:0] raddr,
    output [MEM_DATA_WIDTH-1:0] rdata,
    output rardy,
    output rdrdy,
    
    input reset,
    input clock
);

axi_bram axi_bram (
    .s_axi_aclk(clock),        // input wire s_axi_aclk
    .s_axi_aresetn(~reset),  // input wire s_axi_aresetn
    .s_axi_awaddr(waddr[12:0]),    // input wire [12 : 0] s_axi_awaddr
    .s_axi_awlen(8'h00),      // input wire [7 : 0] s_axi_awlen
    .s_axi_awsize(3'h2),    // input wire [2 : 0] s_axi_awsize
    .s_axi_awburst(2'h0),  // input wire [1 : 0] s_axi_awburst
    .s_axi_awlock(1'b0),    // input wire s_axi_awlock
    .s_axi_awcache(4'h0),  // input wire [3 : 0] s_axi_awcache
    .s_axi_awprot(3'h0),    // input wire [2 : 0] s_axi_awprot
    .s_axi_awvalid(waen),  // input wire s_axi_awvalid
    .s_axi_awready(wardy),  // output wire s_axi_awready
    .s_axi_wdata(wdata),      // input wire [31 : 0] s_axi_wdata
    .s_axi_wstrb(wmask),      // input wire [3 : 0] s_axi_wstrb
    .s_axi_wlast(wden),      // input wire s_axi_wlast
    .s_axi_wvalid(wden),    // input wire s_axi_wvalid
    .s_axi_wready(wdrdy),    // output wire s_axi_wready
    .s_axi_bresp(),      // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid(wbvld),    // output wire s_axi_bvalid
    .s_axi_bready(1'b1),    // input wire s_axi_bready
    .s_axi_araddr(raddr[12:0]),    // input wire [12 : 0] s_axi_araddr
    .s_axi_arlen(8'h00),      // input wire [7 : 0] s_axi_arlen
    .s_axi_arsize(3'h2),    // input wire [2 : 0] s_axi_arsize
    .s_axi_arburst(2'h0),  // input wire [1 : 0] s_axi_arburst
    .s_axi_arlock(1'b0),    // input wire s_axi_arlock
    .s_axi_arcache(4'h0),  // input wire [3 : 0] s_axi_arcache
    .s_axi_arprot(3'h0),    // input wire [2 : 0] s_axi_arprot
    .s_axi_arvalid(raen),  // input wire s_axi_arvalid
    .s_axi_arready(rardy),  // output wire s_axi_arready
    .s_axi_rdata(rdata),      // output wire [31 : 0] s_axi_rdata
    .s_axi_rresp(),      // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast(),      // output wire s_axi_rlast
    .s_axi_rvalid(rdrdy),    // output wire s_axi_rvalid
    .s_axi_rready(1'b1)    // input wire s_axi_rready
);

endmodule