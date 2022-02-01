`include "declarations.v"

module MMForwarder(
    input [4:0] EXMM_rt, input [4:0] MMWB_rt,
    input wire EXMM_MemWrite, input wire MMWB_RegWrite,
    output reg forwardM
);

always @(EXMM_rt, MMWB_rt, EXMM_MemWrite, MMWB_RegWrite) begin
    if (EXMM_rt == MMWB_rt && EXMM_MemWrite && MMWB_RegWrite)
        forwardM = 1'b1;
    else
        forwardM = 1'b0;
end

endmodule

module ALUForwarder( 
    input [4:0] IDEX_rs, input [4:0] IDEX_rt,
    input [4:0] EXMM_rd, input [4:0] MMWB_rd,
    input wire EXMM_RegWrite, input wire MMWB_RegWrite,
    output reg [1:0] forwardA, output reg [1:0] forwardB
);

always @(IDEX_rs, EXMM_rd, EXMM_RegWrite, MMWB_rd, MMWB_RegWrite) begin
    if (EXMM_RegWrite && EXMM_rd != 5'b0 && EXMM_rd == IDEX_rs)
        forwardA = 2'b10;
    else if (MMWB_RegWrite && MMWB_rd != 5'b0 && MMWB_rd == IDEX_rs)
        forwardA = 2'b01;
    else 
        forwardA = 2'b00;
end

always @(IDEX_rt, EXMM_rd, EXMM_RegWrite) begin
    if (EXMM_RegWrite && EXMM_rd != 5'b0 && EXMM_rd == IDEX_rt)
        forwardB = 2'b10;
    else if (MMWB_RegWrite && MMWB_rd != 5'b0 && MMWB_rd == IDEX_rs)
        forwardB = 2'b01;
    else 
        forwardB = 2'b00;
end


endmodule

module HarzardDetector (
    input [4:0] IFID_rs, input [4:0] IFID_rt,
    input [4:0] IDEX_rt, input wire IDEX_MemRead,
    output reg IFID_Write, output reg PC_Write,
    output reg Ctrl_src
);
always @(IFID_rs, IFID_rt, IDEX_rt, IDEX_MemRead) begin
    if (IDEX_MemRead && (IFID_rs == IDEX_rt || IFID_rt == IDEX_rt)) begin
        PC_Write = 1'b0; IFID_Write = 1'b0; Ctrl_src = 1'b1;
    end
    else begin
        PC_Write = 1'b1; IFID_Write = 1'b1; Ctrl_src = 1'b0;        
    end
end
endmodule

module Brancher (
    input wire Br_cmp, 
    output reg IDEX_Clear, output reg IFID_Clear, output reg PC_Br
);
always @(Br_cmp) begin
    if (Br_cmp) begin
        IDEX_Clear = 1'b1; IFID_Clear = 1'b1; PC_Br = 1'b1;
    end
    else begin
        IDEX_Clear = 1'b0; IFID_Clear = 1'b0; PC_Br = 1'b0;
    end
end
endmodule


module Controller (
    input [31:0] inst,
    output reg MemRead,
    output reg MemWrite,
    output reg RegWrite,
    output reg [1:0] RegSrc,
    output reg [1:0] RegDst,
    output reg [1:0] ALUBSrc,
    output reg [3:0] ALUOp
);

always @(inst)
    if (inst[`Iop] == `OP_lw) MemRead = 1'b1;
    else MemRead = 1'b0;

always @(inst)
    if (inst[`Iop] == `OP_sw) MemWrite = 1'b1;
    else MemWrite = 1'b0;

always @(inst)
    case (inst[`Iop])
        `OP_beq, `OP_lw: RegWrite = 1'b0;
        default: RegWrite = 1'b1;
    endcase

always @(inst)
    case (inst[`Iop])
        `OP_R_Type, `OP_ori: RegSrc = 2'b00; // ALUResult
        `OP_lw : RegSrc = 2'b01; // Wmem
        `OP_jal: RegSrc = 2'b10; // current PC + 4
        default: RegSrc = 2'b11; // Reserved
    endcase

always @(inst)
    case (inst[`Iop])
        `OP_R_Type: RegDst = 2'b00; // rd
        default: RegDst = 2'b01;    // rt
    endcase // Well, I have to admit it's a mistake to have 2bit for this sig

always @(inst)
    case (inst[`Iop])
        `OP_lw, `OP_ori, `OP_sw: ALUBSrc = 2'b01;
        default: ALUBSrc = 2'b00;
    endcase

always @(inst)
    case (inst[`Iop])
        `OP_R_Type: if (inst[`Ifunct] == `FN_add) ALUOp = `ALU_op_add;
                    else ALUOp = `ALU_op_sub;
        `OP_ori: ALUOp = `ALU_op_or;
        default: ALUOp = `ALU_op_add;
    endcase    

endmodule