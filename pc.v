module pc (
  input [31:2] NPC,
  input PCWr,
  input clk,
  input rst,
  output reg [31:2] PC
);

always @(posedge clk, negedge rst) begin
  if (!rst) PC <= 30'hC00; // 32'h0000_3000 >> 2
  else if (PCWr) PC <= NPC;
end

endmodule
