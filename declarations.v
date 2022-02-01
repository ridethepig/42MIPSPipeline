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

`define MemRead     32
`define MemWrite    33
`define RegWrite    34
`define RegSrc      36:35
`define RegDst      38:37
`define ALUBSrc     40:39
`define ALUOp       44:41

`define PC4         76:45
`define BrPC        108:77
`define Rrs         140:109
`define Rrt         172:141
`define ExtImm      204:173
`define ALUResult   236:205
`define Wrd         241:237 // The final register number to write in 
`define Wmem        273:242 // Data fecthed from DM

// * ---------------------------- ALU operator --------------------------------

`define ALU_op_add 4'd1
`define ALU_op_sub 4'd2
`define ALU_op_or  4'd3
`define ALU_op_and 4'd4
`define ALU_op_nor 4'd5
`define ALU_op_xor 4'd6

// * ---------------------- MIPS Instruction opcode ---------------------------

`define OP_R_Type   6'b000000
`define OP_beq      6'b000100
`define OP_jal      6'b000010
`define OP_lw       6'b100011
`define OP_ori      6'b001101
`define OP_sw       6'b101011

`define FN_add      6'b100000
`define FN_sub      6'b100010