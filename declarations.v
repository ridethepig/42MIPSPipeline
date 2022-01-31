// * ------------------------- Pipeline Register Signals ----------------------

`define Instr       31:0
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