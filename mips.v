`include "declarations.v"
module mips(input wire clk, input wire rst);

// * ----------------------------- signals ------------------------------------
// PC
wire [31:0] pc, npc; 
wire PC_Write;
// IM
wire [31:0] inst; 
// DM
wire [11:0] DM_addr;
wire [31:0] DM_dIn, DM_dOut;
wire DM_Write;
wire [1:0] DM_mode;
// Reg File
wire [4:0] RF_rA, RF_rB, RF_rW;
wire [31:0] RF_dIn, RF_dOutA, RF_dOutB;
wire RF_Write;
// Pipeline Registers; See declarations.v for every part's usage
reg [`PLLen - 1:0] IFID, IDEX, EXMM, MMWB;
// intermediate wires
wire [31:0] pc_plus_4, pc_mux_br, pc_jmp, pc_mux_j, pc_br;
wire PC_B, PC_J, EXT_SZ;
wire CTRL_MemRead, CTRL_MemWrite, CTRL_RegWrite, CTRL_ALUASrc, CTRL_ALUBSrc, CTRL_ISJR;
wire [1:0] CTRL_RegSrc, CTRL_RegDst, CTRL_MemMode, CTRL_MemExt;
wire [2:0] CTRL_CMPOp;
wire [3:0] CTRL_ALUOp;
wire Ctrl_src;
wire [`CtrlSig] ctrl_mux_0;
wire [31:0] ext_imm;
wire [1:0] ALU_ForwardA, ALU_ForwardB;
wire [31:0] mux_fwda, mux_fwdb, mux_alub, mux_alua;
wire [31:0] alu_result;
wire cmp_cmp;
wire [4:0] mux_regdst;
wire DM_Forward;
wire [31:0] mux_dmfwd;
wire [31:0] mux_mr;
wire [31:0] ext_wmem;
wire IDEX_Clear, IFID_Clear, IFID_Write;

// * ------------------------- module connections -----------------------------

pc    U_PC (.clk(clk), .rst(rst), .PCNext(npc), .PC(pc), .PCWrite(PC_Write));
// ==== Storage ====

im_4k U_IM (.addr(pc[11:2]), .dout(inst));
dm_4k U_DM (.addr(DM_addr[11:0]), .din(DM_dIn), .DMWr(DM_Write), .clk(clk), .dout(DM_dOut), .mode(DM_mode));
    // we don't actually use MemRead signal here, just as a decoration in pipeline >_<
rf    U_RF (.clk(clk), .rst(rst), 
            .A(RF_rA), .B(RF_rB), .doutA(RF_dOutA), .doutB(RF_dOutB),
            .W(RF_rW), .din(RF_dIn), .RFWr(RF_Write) );

// ==== Computing Units ====

adder ADDER_NPC(.dInA(pc), .dInB(32'd4), .dOut(pc_plus_4));
isJType IS_JTYPE(.inst(inst), .PC_J(PC_J));
jmpAdder ADDER_JPC(.dInAddr(inst[`Iaddr]), .dInPC(pc), .dOut(pc_jmp));
mux2to1 #(.n(32)) MUX_PCJ(.A(pc_plus_4), .B(pc_jmp), .sel(PC_J), .dOut(pc_mux_j));
mux2to1 #(.n(32)) MUX_PCB(.A(pc_mux_j), .B(IDEX[`BrPC]), .sel(PC_B), .dOut(pc_mux_br));
assign npc = pc_mux_br;

assign RF_rA = IFID[`Irs];
assign RF_rB = IFID[`Irt];
Controller U_CTRLR(.inst(IFID[`Inst]),  .MemRead(CTRL_MemRead), .MemWrite(CTRL_MemWrite), 
                    .RegWrite(CTRL_RegWrite), .RegSrc(CTRL_RegSrc), .RegDst(CTRL_RegDst), 
                    .ALUASrc(CTRL_ALUASrc), .ALUBSrc(CTRL_ALUBSrc), .ALUOp(CTRL_ALUOp), .EXT_SZ(EXT_SZ),
                    .CMPOp(CTRL_CMPOp), .ISJR(CTRL_ISJR), .MemMode(CTRL_MemMode), .MemExt(CTRL_MemExt));
mux2to1 #(.n(13)) MUX_CTRL(
    // .A({CTRL_MemRead, CTRL_MemWrite, CTRL_RegWrite, CTRL_RegSrc, CTRL_RegDst, CTRL_ALUBSrc, CTRL_ALUOp}),
    .A({CTRL_MemExt, CTRL_MemMode, CTRL_ISJR, CTRL_CMPOp, CTRL_ALUOp, CTRL_ALUBSrc, CTRL_RegDst, CTRL_RegSrc, CTRL_RegWrite, CTRL_MemWrite, CTRL_MemRead}),
    .B(13'b0), .sel(Ctrl_src | IDEX_Clear), .dOut(ctrl_mux_0));
extender U_EXT(.dIn(IFID[`Iimm]), .SZ(EXT_SZ), .dOut(ext_imm));
adder ADDER_BrPC(.dInA({ext_imm[29:0], 2'b00}), .dInB(IFID[`PC4]), .dOut(pc_br));

mux3to1 #(.n(32)) MUX_FwdA(.A(IDEX[`Rrs]), .B(mux_mr), .C(EXMM[`ALUResult]), .sel(ALU_ForwardA), .dOut(mux_fwda));
mux3to1 #(.n(32)) MUX_FwdB(.A(IDEX[`Rrt]), .B(mux_mr), .C(EXMM[`ALUResult]), .sel(ALU_ForwardB), .dOut(mux_fwdb));
mux2to1 #(.n(32)) MUX_ALUA(.A(mux_fwda), .B({27'b0, IDEX[`Ishamt]}), .sel(IDEX[`ALUASrc]), .dOut(mux_alua));
mux2to1 #(.n(32)) MUX_ALUB(.A(mux_fwdb), .B(IDEX[`ExtImm]), .sel(IDEX[`ALUBSrc]), .dOut(mux_alub));
mux3to1 #(.n(5))  MUX_RegDst(.A(IDEX[`Ird]), .B(IDEX[`Irt]), .C(5'd31), .sel(IDEX[`RegDst]), .dOut(mux_regdst));
alu U_ALU(.dInA(mux_alua), .dInB(mux_alub), .ALUOp(IDEX[`ALUOp]), .dOut(alu_result));
comparator U_CMP(.dInA(mux_alua), .dInB(mux_alub), .CMPOp(IDEX[`CMPOp]), .dOut(cmp_cmp));

assign DM_addr = EXMM[`ALUResult]; // Attention here it's a 32bit
assign DM_Write = EXMM[`MemWrite];
assign DM_mode = EXMM[`MemMode];
mux2to1 #(.n(32)) MUX_DMFwd(.A(EXMM[`Rrt]), .B(mux_mr), .sel(DM_Forward), .dOut(mux_dmfwd));
memExtender U_MEMEXT(.dIn(DM_dOut), .EXTOp(EXMM[`MemExt]), .mode(DM_mode), .dOut(ext_wmem));
assign DM_dIn = mux_dmfwd;


assign RF_rW = MMWB[`Wrd]; 
assign RF_Write = MMWB[`RegWrite];
mux3to1 #(.n(32)) MUX_MR(.A(MMWB[`ALUResult]), .B(MMWB[`Wmem]), .C(MMWB[`PC4]), 
            .sel(MMWB[`RegSrc]), .dOut(mux_mr));
assign RF_dIn = mux_mr;

// Hazard Handler

Brancher U_BRANCHER(.Br_cmp(cmp_cmp), .PC_B(PC_B), .IDEX_Clear(IDEX_Clear), .IFID_Clear(IFID_Clear));
HarzardDetector U_HAZARD (
    .IFID_rs(IFID[`Irs]), .IFID_rt(IFID[`Irt]), 
    .IDEX_rt(IDEX[`Irt]), .IDEX_MemRead(IDEX[`MemRead]), 
    .IFID_Write(IFID_Write), .PC_Write(PC_Write), .Ctrl_src(Ctrl_src)
);
ALUForwarder U_ALUFWDER( 
    .IDEX_rs(IDEX[`Irs]), .IDEX_rt(IDEX[`Irt]),
    .EXMM_rd(EXMM[`Wrd]), .MMWB_rd(MMWB[`Wrd]),
    .EXMM_RegWrite(EXMM[`RegWrite]), .MMWB_RegWrite(MMWB[`RegWrite]),
    .forwardA(ALU_ForwardA), .forwardB(ALU_ForwardB)
);
MMForwarder U_MMFWDER(
    .EXMM_rt(EXMM[`Irt]), .EXMM_MemWrite(EXMM[`MemWrite]),
    .MMWB_rt(MMWB[`Wrd]), .MMWB_RegWrite(MMWB[`RegWrite]),
    .forwardM(DM_Forward)
);

// * ------------------------ Clock Control -----------------------------------

always @(posedge clk, posedge rst) begin
    if (rst) begin
        IFID <= `PLLen'b0;
    end
    else if (IFID_Write && !IFID_Clear) begin
        IFID[`Inst] <= inst; IFID[`PC4] <= pc_plus_4;
    end
    else if (IFID_Clear)
        IFID <= `PLLen'b0;
`ifdef DEBUG
    $display("======================%10d============================", $time);
    $display("IFID.Inst: %8X, op: %6b, rs: %2d, rt: %2d, funct: %6b, imm: %4X, addr: %8X", 
        IFID[`Inst], IFID[`Iop], IFID[`Irs], IFID[`Irt], IFID[`Ifunct], IFID[`Iimm], IFID[`Iaddr]);    
    $display("IFID.PC4 : %8X", IFID[`PC4]);
`endif
end

always @(posedge clk, posedge rst) begin
    if (rst) begin
        IDEX <= `PLLen'b0;
    end
    else begin
        // IDEX[`Inst] <= IFID[`Inst];  IDEX[`PC4] <= IFID[`PC4];
        IDEX <= IFID;
        IDEX[`Rrs] <= RF_dOutA; IDEX[`Rrt] <= RF_dOutB; IDEX[`ExtImm] <= ext_imm;
        IDEX[`BrPC] <= pc_br;   IDEX[`CtrlSig] <= ctrl_mux_0;
    end
`ifdef DEBUG
    $display("IDEX.Inst: %8X\tIDEX.Ctrl: %b", IDEX[`Inst], IDEX[`CtrlSig]);
    $display("\tMemRead: %b, MemWrite: %b, RegWrite: %b, RegSrc: %b, RegDst: %b, ALUASrc: b ALUBSrc: %b, ALUOp: %b, CMPOp: %b, MemMode: %b, MemExt: %b",
        IDEX[`MemRead], IDEX[`MemWrite], IDEX[`RegWrite], IDEX[`RegSrc], 
        IDEX[`RegDst], IDEX[`ALUASrc], IDEX[`ALUBSrc], IDEX[`ALUOp], IDEX[`CMPOp], 
        IDEX[`MemMode], IDEX[`MemExt]);
    $display("IDEX.PC4 : %8X\tIDEX.BrPC: %8X", IDEX[`PC4], IDEX[`BrPC]);
    $display("IDEX.Rrs : %8X\tIDEX.Rrt : %8X", IDEX[`Rrs], IDEX[`Rrt]);
    $display("IDEX.ExtImm: %8X", IDEX[`ExtImm]);
`endif
end

always @(posedge clk, posedge rst) begin
    if (rst) begin
        EXMM <= `PLLen'b0;
    end
    else begin
        // EXMM[`Inst] <= IDEX[`Inst]; EXMM[`CtrlSig] <= IDEX[`CtrlSig];
        // EXMM[`PC4] <= IDEX[`PC4]; EXMM[`Rrs] <= IDEX[`Rrs]; EXMM[`Rrt] <= IDEX[`Rrt]; EXMM[`ExtImm] <= IDEX[`ExtImm]; EXMM[`BrPC] <= IDEX[`BrPC];
        EXMM <= IDEX;
        EXMM[`ALUResult] <= alu_result; EXMM[`Wrd] <= mux_regdst;
    end
`ifdef DEBUG    
    $display("EXMM.Inst: %8X\tEXMM.Ctrl: %b", EXMM[`Inst], EXMM[`CtrlSig]);       
    $display("EXMM.PC4 : %8X\tEXMM.BrPC: %8X", EXMM[`PC4], EXMM[`BrPC]);
    $display("EXMM.Rrs : %8X\tEXMM.Rrt : %8X", EXMM[`Rrs], EXMM[`Rrt]);
    // $display("EXMM.ExtImm: %8X", EXMM[`ExtImm]);
    $display("EXMM.ALURes: %8X\tEXMM.Wrd: %d", EXMM[`ALUResult], EXMM[`Wrd]);    
`endif
end

always @(posedge clk, posedge rst) begin
    if (rst) begin
        MMWB <= `PLLen'b0;
    end
    else begin
        MMWB <= EXMM;
        // MMWB[`Wmem] <= DM_dOut;
        MMWB[`Wmem] <= ext_wmem;
    end
`ifdef DEBUG
    $display("MMWB.Inst: %8X\tMMWB.Ctrl: %b", MMWB[`Inst], MMWB[`CtrlSig]);    
    $display("MMWB.PC4 : %8X\tMMWB.BrPC: %8X", MMWB[`PC4], MMWB[`BrPC]);
    $display("MMWB.Rrs : %8X\tMMWB.Rrt : %8X", MMWB[`Rrs], MMWB[`Rrt]);
    // $display("MMWB.ExtImm: %8X", MMWB[`ExtImm]);
    $display("MMWB.ALURes: %8X\tMMWB.Wrd: %d", MMWB[`ALUResult], MMWB[`Wrd]);
    $display("MMWB.Wmem: %8X", MMWB[`Wmem]);
    $display("--------------------------------------------------------------");
`endif
end

endmodule