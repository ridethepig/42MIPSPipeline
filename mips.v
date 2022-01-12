module mips( clk, rst );
input clk;
input rst;

// ------------------------------ params --------------------------------------
// FSM states
parameter s_InstFetch = 4'd0, 
          s_Decode = 4'd1, 
          s_MCalc = 4'd2, s_MLoad = 4'd3, s_MStore = 4'd4, s_MLoadFinish = 4'd5, 
          s_RExec = 4'd6, s_RFinish = 4'd7,
          s_OrExec = 4'd8, s_OrFinish = 4'd9,
          s_BrFinish = 4'd10, s_JaFinish = 4'd11;
// Decoder op codes
parameter op_addu = 3'd0, op_subu = 3'd1, op_ori = 3'd2, op_lw = 3'd3,
          op_sw = 3'd4, op_beq = 3'd5, op_jal = 3'd6;
// ----------------------------------------------------------------------------
// ------------------------------ signals -------------------------------------
wire [29:0] PC_0;
wire [31:0] PC, NPC; // PC

reg PCWr, DMWr, RFWr, extSZ, alu_A_sel;
reg [1:0] alu_ctrl, alu_B_sel, rf_W_sel, rf_din_sel, pc_sel; // ctrl signals

wire ZF;
wire [2:0] op;
wire [4:0] rs, rt, rd, rf_w;
wire [15:0] imm;
wire [25:0] i_target;
wire [31:0] dm_din, dm_dout, rf_din, rf_doutA, rf_doutB, im_dout;
wire [31:0] alu_A, alu_B, ALUout;
wire [31:0] ext_out, ext_out_lsh2;
wire [31:0] target;

reg [31:0] r_IR, r_rA, r_rB, r_ALUout, r_DR, r_target; // middle registers

reg [3:0] state, next_state;

//-----------------------------------------------------------------------------
// ------------------------- module connections -------------------------------

pc    U_PC (.clk(clk), .rst(rst), .NPC(NPC[31:2]), .PC(PC_0), .PCWr(PCWr));
assign PC = {PC_0, 2'b00};
im_4k U_IM (.addr(PC_0[9:0]), .dout(im_dout));
dm_4k U_DM (.addr(r_ALUout[11:2]), .din(r_rB), .DMWr(DMWr), .clk(clk), .dout(dm_dout));
rf    U_RF (.clk(clk), .rst(rst), .A(rs), .B(rt), .W(rf_w), .din(rf_din), .RFWr(RFWr),
            .doutA(rf_doutA), .doutB(rf_doutB));
decoder   U_Decoder (.inst(r_IR),.op(op),.rs(rs),.rt(rt),.rd(rd),.imm(imm),.target(i_target));
alu       U_ALU (.A(alu_A), .B(alu_B), .ALUctrl(alu_ctrl), .ZF(ZF), .ALUout(ALUout));
extender  U_EXT (.w_in(imm), .extSZ(extSZ), .dw_out(ext_out));
assign ext_out_lsh2 = {ext_out[29:0], 2'b0};
assign target = {PC[31:28], i_target, 2'b00};
mux3to1 #(.n( 5)) MUX_RF_w (.selA(rt), .selB(rd), .selC(5'd31), 
                            .sel(rf_W_sel), .mux_out(rf_w));
mux3to1 #(.n(32)) MUX_RF_din (.selA(r_DR), .selB(r_ALUout), .selC(PC),
                            .sel(rf_din_sel), .mux_out(rf_din));
mux2to1 #(.n(32)) MUX_ALU_A(.selA(PC), .selB(r_rA), 
                            .sel(alu_A_sel), .mux_out(alu_A));
mux4to1 #(.n(32)) MUX_ALU_B(.selA(32'd4), .selB(r_rB), .selC(ext_out_lsh2), .selD(ext_out),
                            .sel(alu_B_sel), .mux_out(alu_B));
mux3to1 #(.n(32)) MUX_PC (.selA(r_target), .selB(ALUout), .selC(target),
                          .sel(pc_sel), .mux_out(NPC));
//-----------------------------------------------------------------------------
//---------------------------- FSM --------------------------------------------
  
  always @(posedge clk, posedge rst) begin
    if (rst) state <= s_InstFetch;
    else state <= next_state;
  end

  always @(state, op) begin
    case (state)
      s_InstFetch: next_state = s_Decode;
      s_Decode:
        case (op)
          op_addu, op_subu: next_state = s_RExec;
          op_lw, op_sw: next_state = s_MCalc;
          op_ori: next_state = s_OrExec;
          op_beq: next_state = s_BrFinish;
          op_jal: next_state = s_JaFinish;
          default: next_state = s_InstFetch;
        endcase
      s_RExec: next_state = s_RFinish;
      s_OrExec: next_state = s_OrFinish;
      s_MCalc: if (op == op_sw) next_state = s_MStore;
                else next_state = s_MLoad;      
      s_MLoad: next_state = s_MLoadFinish;
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
    if (state == s_RExec || state == s_OrExec || state == s_MCalc)
      r_ALUout <= ALUout;
  end

  always @(posedge clk) begin
    if (state == s_Decode) r_target <= ALUout;
  end

  always @(posedge clk) begin
    if (state == s_MLoad) r_DR <= dm_dout;
  end

//-----------------------------------------------------------------------------
//----------------------------- Control Signals -------------------------------

  always @(state, ZF) begin
    if (state == s_InstFetch || state == s_JaFinish) PCWr = 1'b1;
    else if (state == s_BrFinish && ZF) PCWr = 1'b1;
    else PCWr = 1'b0;
  end // PC write ctrl

  always @(state) begin
    if (state == s_InstFetch) pc_sel = 2'b01; // selB--ALUout
    else if (state == s_BrFinish) pc_sel = 2'b00; // selA--r_target
    else pc_sel = 2'b10; // selC--inst_target
  end

  always @(state, op) begin
    if (state == s_InstFetch) alu_ctrl = 2'b00; // add to gen PC + 4
    else if (state == s_Decode) alu_ctrl = 2'b00; // add to gen PC + 4 + imm
    else if (state == s_BrFinish) alu_ctrl = 2'b01; // sub to compare
    else if (state == s_OrExec) alu_ctrl = 2'b10;  // or, different op
    else if (state == s_MCalc) alu_ctrl = 2'b00; // add to calc mem addr
    else if (op == op_addu) alu_ctrl = 2'b00; 
    else if (op == op_subu) alu_ctrl = 2'b01;
    else alu_ctrl = 2'b11; // we dont care otherwise
  end // ALU control, [TODO] refactor into case

  always @(state) begin
    if (state == s_InstFetch || state == s_Decode) alu_A_sel = 1'b0; 
    else alu_A_sel = 1'b1; // otherwise, select R[rs]
  end // ALU input A mux

  always @(state) begin
    if (state == s_InstFetch) alu_B_sel = 2'b00; // select 4
    else if (state == s_Decode) alu_B_sel = 2'b10; // select sExt[imm] << 2
    else if (state == s_RExec || state == s_BrFinish) alu_B_sel = 2'b01; // select R[rt]    
    else alu_B_sel = 2'b11; // ORI, MCalc, select Ext[imm]
  end // ALU input B mux

  always @(state) begin
    if (state == s_OrExec) extSZ = 1'b0;
    else extSZ = 1'b1;
  end // extender sign or zero

  always @(state) begin
    if (state == s_JaFinish) rf_W_sel = 2'b10; // select r[31] to set ret addr
    else if (state == s_RFinish) rf_W_sel = 2'b01; // select rd
    else rf_W_sel = 2'b00; // select rt, s_OriExec, s_MLoadFin
  end // register file write selector

  always @(state) begin
    if (state == s_JaFinish) rf_din_sel = 2'b10; // select PC + 4 to set ret addr
    else if (state == s_RFinish || state == s_OrFinish) rf_din_sel = 2'b01; // select aluout to write back rs + rt
    else rf_din_sel = 2'b00; // select DR to load dm
  end // register file write data src

  always @(state) begin
    if (state == s_JaFinish 
    || state == s_RFinish || state == s_MLoadFinish || state == s_OrFinish) RFWr = 1'b1;
    else RFWr = 1'b0;
  end // register file write control, only beq doesnt need to write back

  always @(state) begin
    if (state == s_MStore) DMWr = 1'b1;
    else DMWr = 1'b0;
  end // DM write control, only one operation require write permission

endmodule