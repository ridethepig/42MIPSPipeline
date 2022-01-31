`include "declarations.v"
module mips(input wire clk, input wire rst);

// * ----------------------------- signals ------------------------------------
// PC
wire [31:0] pc, npc; 
wire PC_Write; 
// IM
wire [31:0] inst; 
// DM
wire [11:2] DM_addr;
wire [31:0] DM_dIn, DM_dOut;
wire DM_Write;
// Reg File
wire [4:0] RF_rA, RF_rB, RF_rW;
wire [31:0] RF_dIn, RF_dOutA, RF_dOutB;
wire RF_Write;
// Pipeline Registers; See declarations.v for every part's usage
reg [273:0] IFID, IDEX, EXMM, MMWB;


// * ------------------------- module connections -----------------------------

pc    U_PC (.clk(clk), .rst(rst), .PCNext(npc), .PC(pc), .PCWrite(PC_Write));
// ==== Storage ====

im_4k U_IM (.addr(pc[11:2]), .dout(inst));
dm_4k U_DM (.addr(DM_addr), .din(DM_dIn), .DMWr(DM_Write), .clk(clk), .dout(DM_dOut));
    // we don't actually use MemRead signal here, just as a decoration in pipeline >_<
rf    U_RF (.clk(clk), .rst(rst), 
            .A(RF_rA), .B(RF_rB), .doutA(RF_dOutA), .doutB(RF_dOutB),
            .W(RF_rW), .din(RF_dIn), .RFWr(RF_Write) );

// ==== Computing Units ====


// * ------------------------ Clock Control -----------------------------------
always @(posedge clk, posedge rst) begin
    if (rst) begin
        IFID <= 274'b0; IDEX <= 274'b0; EXMM <= 274'b0; MMWB <= 274'b0;
    end
    else begin
        IFID[`Inst] <= inst;
    end
end

endmodule