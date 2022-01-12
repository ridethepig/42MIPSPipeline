module mips( clk, rst );
input clk;
input rst;

// ------------------------------ params --------------------------------------
// FSM states
parameter s_InstFetch = 4'd0, 
          s_Decode = 4'd1, 
          s_MemCalc = 4'd2, s_MemLoad = 4'd3, s_MemWrite = 4'd4, s_RegWrite = 4'd5, 
          s_RExec = 4'd6, s_RFinish = 4'd7,
          s_OrExec = 4'd8, s_OrFinish = 4'd9,
          s_BrFinish = 4'd10, s_JaFinish = 4'd11;
// Decoder op codes
parameter op_addu = 3'd0, op_subu = 3'd1, op_ori = 3'd2, op_lw = 3'd3,
          op_sw = 3'd4, op_beq = 3'd5, op_jal = 3'd6;
// ----------------------------------------------------------------------------
// ------------------------------ signals -------------------------------------

wire [31:0] PC, NPC; // PC

reg PCWr, DMWr, RFWr, extSZ, addendA_sel;
reg [1:0] ALUctrl, addendB_sel, rf_w_sel; // ctrl signals

wire ZF;
wire [2:0] op;
wire [4:0] rs, rt, rd, rf_w;
wire [15:0] imm;
wire [25:0] target;
wire [31:0] dm_din, dm_dout, rf_din, im_dout;
wire [31:0] addendA, addendB, ALUout, rf_doutA, rf_doutB;

reg [31:0] r_IR, r_rA, r_rB, r_ALUout, r_DR, r_target; // middle registers

reg [3:0] state, next_state;

//-----------------------------------------------------------------------------
// ------------------------- module connections -------------------------------

pc U_PC (.clk(clk), .rst(rst), .NPC(NPC), .PC(PC[31:2]), .PCWr(PCWr));
im_4k U_IM (.addr(PC[9:0]), .dout(im_dout));
dm_4k U_DM (.addr(r_ALUout[11:2]), .din(dm_din), .DMWr(DMWr), .clk(clk), .dout(dm_dout));
rf U_RF(.clk(clk), .A(rs), .B(rt), .W(rf_w), .din(rf_din), .RFWr(RFWr),
        .doutA(rf_doutA), .doutB(rf_doutB));
decoder U_Decoder (.inst(r_IR),.op(op),.rs(rs),.rt(rt),.rd(rd),.imm(imm),.target(target));
alu U_ALU (.A(addendA), .B(addendB), .ALUctrl(ALUctrl), .ZF(ZF), .ALUout(ALUout));
extender U_EXT (.w_in())
mux3to1 #(.n(5)) MUX_rf_w (.selA(rt), .selB(rd), .selC(5'd31), .sel(rf_w_sel), .mux_out(rf_w));
mux2to1 #(.n(32)) MUX_ALU_A (.selA(PC), .selB(r_rA), .sel(addendA_sel), .mux_out(addendA));
mux4to1 #(.n(32)) MUX_ALU_B (.selA(32'd4), .selB(r_rB),
                             .sel(addendB_sel), .mux_out(addendB));

//-----------------------------------------------------------------------------
//---------------------------- FSM --------------------------------------------
  
  always @(posedge clk, negedge rst) begin
    if (!rst) state <= 4'b0;
    else state <= next_state;
  end

  always @(state, op) begin
    case (state)
      s_InstFetch: next_state = s_Decode;
      s_Decode:
        case (op)
          op_addu, op_subu: next_state = s_RExec;
          op_lw, op_sw: next_state = s_MemCalc;
          op_ori: next_state = s_OrExec;
          op_beq: next_state = s_BrFinish;
          op_jal: next_state = s_JaFinish;
          default: next_state = s_InstFetch;
        endcase
      s_RExec: next_state = s_RFinish;
      s_OrExec: next_state = s_OrFinish;
      s_MemCalc: if (op == op_sw) next_state = s_MemWrite;
                else next_state = s_MemLoad;      
      s_MemLoad: next_state = s_RegWrite;
      default: next_state = s_InstFetch;
    endcase
  end

//-----------------------------------------------------------------------------
//------------------------ Intermediate Reg Control ---------------------------

  always @(posedge clk) begin
    if (state == s_InstFetch) r_IR <= im_dout;
  end

  always @(posedge clk) begin
    if (state == s_Decode) begin
      r_rA <= rf_doutA;
      r_rB <= rf_doutB;
    end
  end

  always @(posedge clk) begin
    if (state == s_RExec || state == s_OrExec || state == s_MemCalc)
      r_ALUout <= ALUout;
  end

  always @(posedge clk) begin
    if (state == s_Decode) r_target <= ALUout;
  end

  always @(posedge clk) begin
    if (state == s_MemLoad) r_DR <= dm_dout;
  end

//-----------------------------------------------------------------------------
//----------------------------- Control Signals -------------------------------

  always @(state) begin
    
  end

endmodule