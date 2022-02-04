`include "declarations.v"
module dm_4k( addr, din, DMWr, clk, dout, mode );
    input  [11:0] addr;
    input  [31:0] din;
    input         DMWr;
    input         clk;
    input  [1:0]  mode;
    output reg [31:0] dout;

    reg [31:0] dmem[1023:0];
    wire [11:2] _addr;
    wire [1:0] __addr;
    assign _addr = addr[11:2];
    always @(posedge clk) begin
        if (DMWr) begin
            if (mode == `MEM_op_byte)
                case (addr[1:0])
                    2'b00: dmem[_addr][ 7: 0] <= din[7:0];
                    2'b01: dmem[_addr][15: 8] <= din[7:0];
                    2'b10: dmem[_addr][23:16] <= din[7:0];
                    2'b11: dmem[_addr][31:24] <= din[7:0];
                endcase
            else if (mode == `MEM_op_half)
                case (addr[1:0])
                    2'b00: dmem[_addr][15: 0] <= din[15:0];
                    2'b10: dmem[_addr][31:16] <= din[15:0];
                    default: dmem[_addr] <= din; // should raise exception, though not yet have that
                endcase
            else dmem[_addr] <= din;
        `ifdef DEBUG
            $display("M[0x%8X] <- 0x%8X", addr, din);
        `endif
        end
    end
    // assign dout = dmem[addr];
    always @(_addr, addr, din, mode)
        if (mode == `MEM_op_byte)
            case (__addr)
                2'b00: dout = {24'b0, dmem[_addr][ 7: 0]};
                2'b01: dout = {24'b0, dmem[_addr][15: 8]};
                2'b10: dout = {24'b0, dmem[_addr][23:16]};
                2'b11: dout = {24'b0, dmem[_addr][31:24]};
            endcase
        else if (mode == `MEM_op_half)
            case (__addr)
                2'b00: dout = {16'b0, dmem[_addr][15: 0]};
                2'b10: dout = {16'b0, dmem[_addr][31:16]};
                default: dout = dmem[_addr]; // should also raise exception
            endcase
        else dout = dmem[_addr];
endmodule
