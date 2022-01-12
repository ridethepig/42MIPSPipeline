module decoder (
  input [31:0] inst,
  output reg [2:0] op,
  output [4:0] rs,
  output [4:0] rt,
  output [4:0] rd,
  output [15:0] imm,
  output [25:0] target
);
parameter op_addu = 3'd0, op_subu = 3'd1, op_ori = 3'd2, op_lw = 3'd3,
          op_sw = 3'd4, op_beq = 3'd5, op_jal = 3'd6, op_und = 3'd7;

  always @(inst) begin
    case (inst[31:26])
      6'b000000: begin
        if (inst[5:0] == 6'b100001) op = op_addu;
        else if (inst[5:0] == 6'b100010) op = op_subu;
        else op = op_und;        
      end
      6'b001101: op = op_ori;
      6'b100011: op = op_lw;
      6'b101011: op = op_sw;
      6'b000100: op = op_beq;
      6'b000010: op = op_jal;
      default: op = op_und;
    endcase
  end
  // Actually, we don't really care about what the sigs should be explained as
  assign rs = inst[25:21];  
  assign rt = inst[20:16];
  assign rd = inst[15:11];
  assign imm = inst[15:0];
  assign target = inst[25:0];
endmodule