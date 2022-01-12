module alu (
  input [31:0] A,
  input [31:0] B,
  input [1:0]  ALUctrl,
  output ZF,
  output reg [31:0] ALUout
);

parameter op_add = 2'b00;
parameter op_sub = 2'b01;
parameter op_ori = 2'b10;

always @(ALUctrl, A, B) begin
  case (ALUctrl)
    op_add: ALUout = A + B;
    op_sub: ALUout = A - B;
    op_ori: ALUout = A | B;
    default: ALUout = 32'b0;
  endcase
end

assign ZF = (ALUout == 32'b0) ? 1 : 0;

endmodule

module extender (
  input [15:0] w_in,
  input extSZ, // 0 -> zero exr, 1 -> sign ext
  output [31:0] dw_out
);

assign dw_out = extSZ ? {{16{w_in[15]}}, w_in} : {16'b0, w_in};

endmodule

module mux2to1 ( selA, selB, sel, mux_out );
parameter n = 32;

input wire [n-1: 0] selA, selB;
input wire sel;
output wire [n-1: 0] mux_out;

  assign mux_out = (sel == 0) ? selA : selB;
endmodule

module mux3to1 ( selA, selB, selC, sel, mux_out);
parameter n = 32;

input wire [n-1: 0] selA, selB, selC;
input wire sel;
output reg [n-1: 0] mux_out;

always @(selA, selB, selC, sel) begin
  case(sel)
    2'b00: mux_out = selA;
    2'b01: mux_out = selB;
    2'b10: mux_out = selC;
    default: mux_out = 0;
  endcase
end

endmodule

module mux4to1 ( selA, selB, selC, selD, sel, mux_out);
parameter n = 32;

input wire [n-1: 0] selA, selB, selC, selD;
input wire sel;
output reg [n-1: 0] mux_out;

always @(selA, selB, selC, sel) begin
  case(sel)
    2'b00: mux_out = selA;
    2'b01: mux_out = selB;
    2'b10: mux_out = selC;
    2'b11: mux_out = selD;
  endcase
end

endmodule