module regfile(clk, writenum, write, data_in, readnum, data_out);
    input [2:0] writenum, readnum;
    input write, clk;
    input [15:0] data_in;
    output [15:0] data_out;

    wire [7:0] loadR;
    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
    wire [7:0] writeout, readout;
    // loadR is one hot code corresponding to which register to be written to
    assign loadR = {writeout[7] & write,
                    writeout[6] & write,
                    writeout[5] & write,
                    writeout[4] & write,
                    writeout[3] & write,
                    writeout[2] & write,
                    writeout[1] & write,
                    writeout[0] & write};
    // Instantiate decoders for writing and reading registers
    Dec #(3,8) decwrite(writenum, writeout);
    Dec #(3,8) decread(readnum, readout);
    // Instantiate 8 registers with load enable
    // for storing 16 bit values from data_in
    Reg reg0(clk, data_in, loadR[0], R0);
    Reg reg1(clk, data_in, loadR[1], R1);
    Reg reg2(clk, data_in, loadR[2], R2);
    Reg reg3(clk, data_in, loadR[3], R3);
    Reg reg4(clk, data_in, loadR[4], R4);
    Reg reg5(clk, data_in, loadR[5], R5);
    Reg reg6(clk, data_in, loadR[6], R6);
    Reg reg7(clk, data_in, loadR[7], R7);
    // Instantiate 8 input 16 bit wide mux with one-hot select
    // for reading register values to data_out
    Mux muxy(R0, R1, R2, R3, R4, R5, R6, R7, readout, data_out);
endmodule

// n:m decoder module
module Dec(a, b);
    parameter n = 1;
    parameter m = 2;
    input [n-1:0] a;
    output wire [m-1:0] b;

    assign b = 1 << a;
endmodule

// Register with load enable module
module Reg(clk, in, load, out);
    parameter n = 16;
    input [n-1:0] in;
    input load, clk;
    output [n-1:0] out;
    // If load is enabled then drive
    // in else drive out to D
    wire [n-1:0] D = (load ? in : out);
    // D from mux stored in dff
    vDFF #(n) dff(clk, D, out);
endmodule

// 8 input k-bit wide mux with one-hot select
module Mux(r0, r1, r2, r3, r4, r5, r6, r7, s, out);
    parameter k = 16;
    input [k-1:0] r0, r1, r2, r3, r4, r5, r6, r7;
    input [7:0] s;
    output reg [k-1:0] out;
    // one-hot select one of 8 registers
    always @(*)
    begin
        case(s)
            8'b00000001:
                out = r0;
            8'b00000010:
                out = r1;
            8'b00000100:
                out = r2;
            8'b00001000:
                out = r3;
            8'b00010000:
                out = r4;
            8'b00100000:
                out = r5;
            8'b01000000:
                out = r6;
            8'b10000000:
                out = r7;
            default:
                out = {k{1'bx}};
        endcase
    end
endmodule
