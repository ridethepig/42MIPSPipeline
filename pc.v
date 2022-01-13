module pc (
  input [31:0] NPC,
  input PCWr,
  input clk,
  input rst,
  output reg [31:0] PC
);

always @(posedge clk, posedge rst) begin
  if (rst) PC <= 32'h3000;
  else if (PCWr) PC <= NPC;
end

endmodule
