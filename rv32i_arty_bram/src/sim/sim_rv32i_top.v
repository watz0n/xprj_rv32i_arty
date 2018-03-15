`timescale 1ns / 1ps

module sim_rv32i_top();

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
parameter CLOCK_FREQ_MHZ = 100.0;
//Because simulation operation time unit is 1ns from first "`timescale 1ns / 1ps" first parameter
//Therefore, 1MHz is equal 1000ns period, K MHz is equal (1000/K) ns
parameter CLOCK_PROIOD = 1000.0/CLOCK_FREQ_MHZ;
reg         clock;
initial begin clock = 1'b0; forever clock = #(CLOCK_PROIOD/2) ~clock; end

//parameter JCLK_FREQ_MHZ = 100.0;
parameter JCLK_FREQ_MHZ = 100.0;
parameter JCLK_PROIOD = 1000.0/JCLK_FREQ_MHZ;
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


initial begin: sim_main
    
    jtck_en = 1'b0;
    repeat(4) @(posedge jclk);
    wait(rv32i_top.pll_locked == 1'b1);
    jtck_en = 1'b0;
    repeat(4) @(posedge jclk);
    
    goto_rti();
    shift_ir(6'h09); //IDCODE
    shift_dr('h0, 32); //Read IDCODE //7A35T  0x362D093
    
    //shift_ir(6'h02); //USER1
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
    
    sim_jtag_op(7'h44, 32'h00000001, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h00000000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(7'h48, 32'h00000001, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h00000000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(7'h44, 32'h00000001, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h00000000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(7'h48, 32'h00000001, DMI_REQOP_WR);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    sim_jtag_op(DMI_ADDR_SBDATA0, 32'h00000000, DMI_REQOP_RD);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    sim_jtag_op(7'h0, 32'h00000000, DMI_REQOP_NOP);
    
    shift_ir(6'h22); //USER3
    shift_dr('h1, 32); //jsys_reset
    $display("JTAG Reset System");
    shift_dr('h0, 32); //jsys_reset
    
    wait(rv32i_top.pll_locked == 1'b1);
 
    repeat(10) @(posedge jclk);
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

rv32i_top rv32i_top(
    .board_clock(clock)
);

endmodule
