`include "declarations.v"
module mips( clk, rst );
input clk;
input rst;

// ------------------------------ signals -------------------------------------
wire [31:0] pc, npc; 
wire PCWrite; // PC

wire [31:0] inst; // IM

wire [11:1+2] DM_addr;

reg [273:0] IFID, IDEX, EXMM, MMWB; // for super large pipeline register

//-----------------------------------------------------------------------------
// ------------------------- module connections -------------------------------

pc    U_PC (.clk(clk), .rst(rst), .PCNext(npc), .PC(pc), .PCWrite(PCWrite));

im_4k U_IM (.addr(pc[11:2]), .dout(inst));
dm_4k U_DM (.addr(DM_addr), .din(r_rB), .DMWr(DMWr), .clk(clk), .dout(dm_dout));
rf    U_RF (.clk(clk), .rst(rst), .A(rs), .B(rt), .W(rf_w), .din(rf_din), .RFWr(RFWr),
            .doutA(rf_doutA), .doutB(rf_doutB));

always @(posedge clk, negedge rst) begin
    
end

endmodule