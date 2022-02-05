`define DEBUG
// * ------------------------- Pipeline Register Signals ----------------------

`define Inst       31:0
`define Iop     31:26
`define Irs     25:21
`define Irt     20:16
`define Ird     15:11
`define Ishamt  10: 6
`define Ifunct   5: 0
`define Iimm    15: 0
`define Iaddr   25: 0

`define CtrlSig     52:32
`define MemRead     32
`define MemWrite    33
`define RegWrite    34
`define RegSrc      36:35
`define RegDst      38:37
`define ALUASrc     39
`define ALUBSrc     40
`define ALUOp       44:41
`define CMPOp       47:45
`define ISJR        48
`define MemMode     50:49
`define MemExt      52:51

`define PC4         84:53
`define BrPC        116:85
`define Rrs         148:117
`define Rrt         180:149
`define ExtImm      212:181
`define ALUResult   244:213
`define Wrd         249:245 // The final register number to write in 
`define Wmem        281:250 // Data fecthed from DM
`define PLLen       282

// * ---------------------------- ALU operator --------------------------------

`define ALU_op_add 4'd1
`define ALU_op_sub 4'd2
`define ALU_op_or  4'd3
`define ALU_op_and 4'd4
`define ALU_op_nor 4'd5
`define ALU_op_xor 4'd6
`define ALU_op_slt 4'd7
`define ALU_op_sltu 4'd8
`define ALU_op_sll 4'd9
`define ALU_op_srl 4'd10
`define ALU_op_sra 4'd11
`define ALU_op_lui 4'd12

`define CMP_op_beq  3'd1
`define CMP_op_bne  3'd2
`define CMP_op_bltz 3'd3
`define CMP_op_bgez 3'd4
`define CMP_op_blez 3'd5
`define CMP_op_bgtz 3'd6

`define MEM_op_byte 2'b10
`define MEM_op_half 2'b01
`define MEM_op_word 2'b00

// * ---------------------- MIPS Instruction opcode ---------------------------

`define OP_R_Type   6'b000000
// Branch
`define OP_beq      6'b000100
`define OP_bne      6'b000101
`define OP_bltz     6'b000001
// `define OP_bgez     6'b000001
`define OP_blez     6'b000110
`define OP_bgtz     6'b000111
// J-Type
`define OP_jal      6'b000011
`define OP_j        6'b000010
// ALU with immediate
`define OP_addi     6'b001000
`define OP_addiu    6'b001001
`define OP_slti     6'b001010
`define OP_sltiu    6'b001011
`define OP_andi     6'b001100
`define OP_ori      6'b001101
`define OP_xori     6'b001110
`define OP_lui      6'b001111
// Load / Store
`define OP_lb       6'b100000
`define OP_lh       6'b100001
`define OP_lbu      6'b100100
`define OP_lhu      6'b100101
`define OP_lw       6'b100011
`define OP_sb       6'b101000
`define OP_sh       6'b101001
`define OP_sw       6'b101011

// Special code's funct
`define FN_add      6'b100000
`define FN_sub      6'b100010
`define FN_addu     6'b100001
`define FN_subu     6'b100011
`define FN_and      6'b100100
`define FN_or       6'b100101
`define FN_xor      6'b100110
`define FN_nor      6'b100111
`define FN_slt      6'b101010
`define FN_sltu     6'b101011
`define FN_sllv     6'b000100
`define FN_srlv     6'b000110
`define FN_srav     6'b000111
`define FN_sll      6'b000000
`define FN_srl      6'b000010
`define FN_sra      6'b000011
`define FN_jr       6'b001000
`define FN_jalr     6'b001001
// Below won't be implemented
`define FN_mfhi     6'b010000
`define FN_mthi     6'b010001
`define FN_mflo     6'b010010
`define FN_mtlo     6'b010011
`define FN_mult     6'b011000
`define FN_multu    6'b011001
`define FN_div      6'b011010
`define FN_divu     6'b011011