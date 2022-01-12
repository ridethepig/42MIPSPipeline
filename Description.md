
## 自定义模块说明

#### reg_file.v

```verilog
module rf (
  input [4:0] A,      // 读取A号寄存器
  input [4:0] B,      // 读取B号寄存器
  input [4:0] W,      // 写入W号寄存器
  input [31:0] din,   // 写入数据
  input RFWr,         // 写入控制 1-允许，2-拒绝
  input clk,          //
  output [31:0] doutA,// A号寄存器内容
  output [31:0] doutB // B号寄存器内容
);
```

####  pc.v

输入输出信号的定义与实验说明一致。
```verilog
module pc (
  input [31:2] NPC,
  input PCWr,
  input clk,
  input rst,
  output reg [31:2] PC
);

```