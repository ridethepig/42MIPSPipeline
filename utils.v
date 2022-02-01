`include "declarations.v"
module alu (
  input [31:0] dInA,
  input [31:0] dInB,
  input [3:0]  ALUOp,
  output reg [31:0] dOut
);

always @(ALUOp, dInA, dInB) begin
  case (ALUOp)
    `ALU_op_add: dOut = dInA + dInB;
    `ALU_op_sub: dOut = dInA - dInB;
    `ALU_op_or : dOut = dInA | dInB;
    `ALU_op_and: dOut = dInA & dInB;
    `ALU_op_nor: dOut = ~(dInA | dInB);
    `ALU_op_xor: dOut = dInA ^ dInB;
    default: dOut = 32'b0;
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

module Adder(
    input wire [31:0] dInA,
    input wire [31:0] dInB,
    output wire [31:0] dOut
);

assign dOut = dInA + dInB;

endmodule

module JumpAdder (
    input wire [25:0] dInAddr,
    input wire [31:28] dInPC,
    output wire [31:0] dOut
);
assign dOut = {dInPC, dInAddr, 2'b00};
endmodule