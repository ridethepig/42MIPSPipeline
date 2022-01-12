module rf (
  input [4:0] A,
  input [4:0] B,
  input [4:0] W,
  input [31:0] din,
  input RFWr,
  input clk,
  output [31:0] doutA,
  output [31:0] doutB
);

reg [31:0] reg_file[31:0];

always @(posedge clk) begin
  if (RFWr) reg_file[W] <= din;
end

assign doutA = reg_file[A];
assign doutB = reg_file[B];

endmodule