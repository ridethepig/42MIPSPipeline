`include "declarations.v"
module alu (
  input [31:0] dInA,
  input [31:0] dInB,
  input [3:0]  ALUOp,
  output reg [31:0] dOut
);
// dInA: R[rs], shamt
// dInB: R[rt], extImm

wire [4:0] shamt;
assign shamt = dInA[4:0];

always @(ALUOp, dInA, dInB) begin
  case (ALUOp)
    `ALU_op_add: dOut = dInA + dInB;
    `ALU_op_sub: dOut = dInA - dInB;
    `ALU_op_or : dOut = dInA | dInB;
    `ALU_op_and: dOut = dInA & dInB;
    `ALU_op_nor: dOut = ~(dInA | dInB);
    `ALU_op_xor: dOut = dInA ^ dInB;
    `ALU_op_slt: dOut = $signed(dInA) < $signed(dInB) ? 32'd1 : 32'd0;
    `ALU_op_sltu: dOut = $unsigned(dInA) < $unsigned(dInB) ? 32'd1 : 32'd0;
    `ALU_op_sll: dOut = dInB << shamt;
    `ALU_op_srl: dOut = dInB >> shamt;
    `ALU_op_sra: dOut = $signed(dInB) >>> shamt;
    `ALU_op_lui: dOut = {dInB[15:0], 16'd0};
    default: dOut = 32'b0;
  endcase
end
endmodule

module comparator(
    input [2:0] CMPOp,
    input [31:0] dInA, // R[rs]
    input [31:0] dInB, // R[rt] or 0
    output reg dOut
);

always @(CMPOp, dInA, dInB) begin
    case (CMPOp)
        `CMP_op_beq: if (dInA == dInB) dOut = 1'b1; else dOut = 1'b0;
        `CMP_op_bne: if (dInA != dInB) dOut = 1'b1; else dOut = 1'b0;
        `CMP_op_bltz: if (dInA[31]) dOut = 1'b1; else dOut = 1'b0;
        `CMP_op_blez: if ($signed(dInA) <= $signed(32'b0)) dOut = 1'b1; else dOut = 1'b0;
        `CMP_op_bgtz: if ($signed(dInA) >  $signed(32'b0)) dOut = 1'b1; else dOut = 1'b0;
        `CMP_op_bgez: if (dInA[31] == 1'b0) dOut = 1'b1; else dOut = 1'b0;
        default: dOut = 1'b0;
    endcase
end

endmodule

module extender (
  input [15:0] dIn,
  input SZ, // 0 -> zero exr, 1 -> sign ext
  output [31:0] dOut
);

assign dOut = SZ ? {{16{dIn[15]}}, dIn} : {16'b0, dIn};

endmodule

module mux2to1 (A, B, sel, dOut);
parameter n = 32;
input wire [n-1: 0] A, B;
input wire sel;
output wire [n-1: 0] dOut;

  assign dOut = (sel == 0) ? A : B;
endmodule

module mux3to1 (A, B, C, sel, dOut);
parameter n = 32;
input wire [n-1: 0] A, B, C;
input wire [1:0]sel;
output reg [n-1: 0] dOut;

always @(A, B, C, sel)
  case(sel)
    2'b00: dOut = A;
    2'b01: dOut = B;
    2'b10: dOut = C;
    default: dOut = 0;
  endcase

endmodule

module mux4to1 (A, B, C, D, sel, dOut);
parameter n = 32;
input wire [n-1: 0] A, B, C, D;
input wire [1:0] sel;
output reg [n-1: 0] dOut;

always @(A, B, C, sel)
  case(sel)
    2'b00: dOut = A;
    2'b01: dOut = B;
    2'b10: dOut = C;
    2'b11: dOut = D;
  endcase

endmodule

module adder(
    input wire [31:0] dInA,
    input wire [31:0] dInB,
    output wire [31:0] dOut
);

assign dOut = dInA + dInB;

endmodule

module jmpAdder (
    input wire [25:0] dInAddr,
    input wire [31:0] dInPC,
    output wire [31:0] dOut
);
assign dOut = {dInPC[31:28], dInAddr, 2'b00};
endmodule

module memExtender (
    input [31:0] dIn,
    input [1:0]  EXTOp,
    input [1:0] mode,
    output reg [31:0] dOut
);
always @(EXTOp, dIn, mode)
    if (EXTOp && mode == `MEM_op_byte) dOut = {{24{dIn[7]}}, dIn[7:0] };
    else if (EXTOp && mode == `MEM_op_half) dOut = {{24{dIn[15]}}, dIn[15:0]};
    else dOut = dIn;
endmodule