module rf (
  input [4:0] A,
  input [4:0] B,
  input [4:0] W,
  input [31:0] din,
  input RFWr,
  input clk,
  input rst,
  output [31:0] doutA,
  output [31:0] doutB
);
integer i;
parameter N = 32;
reg [31:0] reg_file[N-1:0];

always @(posedge clk, posedge rst) begin
  if (rst) begin
    for (i = 0; i < N; i = i + 1)
      reg_file[i] <= 32'b0;
  end
  else if (RFWr) reg_file[W] <= din;
end

assign doutA = reg_file[A];
assign doutB = reg_file[B];

endmodule