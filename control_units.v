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
    else if (MMWB_RegWrite && MMWB_rd != 5'b0 && MMWB_rd == IDEX_rt)
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
    input wire IDEX_Jr,
    output reg IDEX_Clear, output reg IFID_Clear,
    output reg [1:0] PC_BR
);
always @(Br_cmp, IDEX_Jr) begin
    if (Br_cmp || IDEX_Jr) begin
        IDEX_Clear = 1'b1; IFID_Clear = 1'b1;
    end
    else begin
        IDEX_Clear = 1'b0; IFID_Clear = 1'b0;
    end
end

always @(Br_cmp, IDEX_Jr) begin
    if (Br_cmp) begin
       PC_BR = 2'b10;
`ifdef DEBUG
        $display("Branch success");
`endif 
    end
    else if (IDEX_Jr) begin
        PC_BR = 2'b01;
`ifdef DEBUG
        $display("Jump Register");
`endif        
    end
    else PC_BR = 2'b00;
end
endmodule


module Controller (
    input [31:0] inst,
    output reg MemRead,
    output reg MemWrite,
    output reg RegWrite,
    output reg EXT_SZ,
    output reg [1:0] RegSrc,
    output reg [1:0] RegDst,
    output reg ALUASrc,
    output reg ALUBSrc,
    output reg [3:0] ALUOp,
    output reg [2:0] CMPOp,
    output reg ISJR,
    output reg [1:0] MemMode,
    output reg [1:0] MemExt
);

// MemRead
always @(inst)
    case (inst[`Iop])
        `OP_lw, `OP_lh, `OP_lhu, `OP_lb, `OP_lbu: MemRead = 1'b1;
        default: MemRead = 1'b0;
    endcase

// MemWrite
always @(inst)
    case (inst[`Iop])
        `OP_sw, `OP_sh, `OP_sb: MemWrite = 1'b1;
        default: MemWrite = 1'b0;
    endcase

// RegWrite
always @(inst)
    case (inst[`Iop])
        `OP_R_Type, `OP_jal, // jalr belongs to R_Type
        `OP_addi, `OP_addiu, `OP_andi, `OP_slti, `OP_sltiu, `OP_ori, `OP_xori, `OP_lui,
        `OP_lw, `OP_lh, `OP_lhu, `OP_lb, `OP_lbu: RegWrite = 1'b1;
        default: RegWrite = 1'b0;
    endcase

// RegSrc
always @(inst)
    case (inst[`Iop])        
        `OP_lw, `OP_lb, `OP_lbu, `OP_lh, `OP_lhu : RegSrc = 2'b01; // Wmem
        `OP_jal: RegSrc = 2'b10; // current PC + 4
        `OP_R_Type: if (inst[`Ifunct] == `FN_jalr) RegSrc = 2'b10; else RegSrc = 2'b00;
        default: RegSrc = 2'b00; // default ALUResult
    endcase

// RegDst
always @(inst)
    case (inst[`Iop])
        `OP_R_Type: RegDst = 2'b00; // rd
        `OP_jal: RegDst = 2'b10;    // jal, $ra
        default: RegDst = 2'b01;    // rt
    endcase

// ALUASrc
always @(inst)
    if (inst[`Iop] == 6'b0)
        case (inst[`Ifunct])
            `FN_sll, `FN_srl, `FN_sra: ALUASrc = 1'b1;
            default: ALUASrc = 1'b0;
        endcase
    else ALUASrc = 1'b0;

// ALUBSrc
always @(inst)
    case (inst[`Iop])
        `OP_lw, `OP_lh, `OP_lhu, `OP_lb, `OP_lbu, `OP_sw, `OP_sh, `OP_sb,
        `OP_addi, `OP_addiu, `OP_slti, `OP_sltiu, `OP_andi, `OP_ori, `OP_xori, `OP_lui: 
            ALUBSrc = 1'b1;
        default: ALUBSrc = 1'b0;
    endcase

// ALUOp
always @(inst)
    case (inst[`Iop])
        `OP_R_Type: 
            case (inst[`Ifunct]) 
                `FN_add, `FN_addu:  ALUOp = `ALU_op_add;
                `FN_sub, `FN_subu:  ALUOp = `ALU_op_sub;
                `FN_and:    ALUOp = `ALU_op_and;
                `FN_or:     ALUOp = `ALU_op_or;
                `FN_xor:    ALUOp = `ALU_op_xor;
                `FN_nor:    ALUOp = `ALU_op_nor;
                `FN_slt:    ALUOp = `ALU_op_slt;
                `FN_sltu:   ALUOp = `ALU_op_sltu;
                `FN_sll, `FN_sllv:  ALUOp = `ALU_op_sll;
                `FN_srl, `FN_srlv:  ALUOp = `ALU_op_srl;
                `FN_sra, `FN_srav:  ALUOp = `ALU_op_sra;
            endcase
        `OP_addi, `OP_addiu: ALUOp = `ALU_op_add;
        `OP_slti:   ALUOp = `ALU_op_slt;
        `OP_sltiu:  ALUOp = `ALU_op_sltu;
        `OP_andi:   ALUOp = `ALU_op_and;
        `OP_ori:    ALUOp = `ALU_op_or;
        `OP_xori:   ALUOp = `ALU_op_xor;
        `OP_lui:    ALUOp = `ALU_op_lui;
        default:    ALUOp = `ALU_op_add;
    endcase

// CMPOp
always @(inst)
    case (inst[`Iop])
        `OP_beq: CMPOp = `CMP_op_beq;
        `OP_bne: CMPOp = `CMP_op_bne;
        `OP_bltz: if (inst[`Irt] == 5'b0) CMPOp = `CMP_op_bltz;
                    else CMPOp = `CMP_op_bgez;
        `OP_blez: CMPOp = `CMP_op_blez;
        `OP_bgtz: CMPOp = `CMP_op_bgtz;
        default: CMPOp = 3'b0;
    endcase

// ISJR
always @(inst)
    if (inst[`Iop] == `OP_R_Type &&
        (inst[`Ifunct] == `FN_jalr || inst[`Ifunct] == `FN_jr))
        ISJR = 1'b1;
    else ISJR = 1'b0;

// MemMode
always @(inst)
    case (inst[`Iop])
        `OP_sw, `OP_lw: MemMode = `MEM_op_word;
        `OP_sh, `OP_lh, `OP_lhu: MemMode = `MEM_op_half;
        `OP_sb, `OP_lb, `OP_lbu: MemMode = `MEM_op_byte;
        default: MemMode = 2'b00;
    endcase

// MemExt
always @(inst)
    case (inst[`Iop])
        `OP_lh, `OP_lb: MemExt = 2'b11;
        default: MemExt = 2'b00;
    endcase

// EXT_SZ
always @(inst)
    case (inst[`Iop])
        `OP_ori, `OP_andi, `OP_xori: EXT_SZ = 1'b0;
        default: EXT_SZ = 1'b1;
    endcase

endmodule

module isJType(
    input [31:0] inst,
    output reg PC_J
);

always @(inst)
    case (inst[`Iop])
        `OP_jal, `OP_j: PC_J = 1'b1;
        default: PC_J = 1'b0;
    endcase
endmodule