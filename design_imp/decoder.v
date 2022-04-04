module decoder(ir_out, nsel, opcode, op, writenum, readnum, shift, sximm8, sximm5, ALUop, cond);
    input [15:0] ir_out;
    input [2:0] nsel;
    output [15:0] sximm5, sximm8;
    output wire [2:0] opcode, writenum, readnum, cond;
    output wire [1:0] op, shift, ALUop;
    // To controller
    assign opcode = ir_out[15:13]; // & datapath
    assign op = ir_out[12:11];
    assign cond = ir_out[10:8];
    // To datapath
    assign ALUop = ir_out[12:11];
    assign shift = ir_out[4:3];

    wire [2:0] Rn = ir_out[10:8];
    wire [2:0] Rd = ir_out[7:5];
    wire [2:0] Rm = ir_out[2:0];

    wire [4:0] imm5 = ir_out[4:0];
    wire [7:0] imm8 = ir_out[7:0];

    wire [2:0] read_write;
    // Instantiate sign extension module
    sx #(5,16) sx5to16(imm5, sximm5);
    sx #(8,16) sx8to16(imm8, sximm8);
    // Instantiate mux to read/write Rn, Rd, Rm to register file
    Mux3 #(3) muxReg(.in2(Rn), .in1(Rd), .in0(Rm), .s(nsel), .out(read_write));
    // Drive selected register to writenum and readnum
    assign writenum = read_write;
    assign readnum = read_write;
endmodule

// sign extension module
module sx(in, out);
    parameter n = 5;
    parameter m = 16;
    input [n-1:0] in;
    output wire [m-1:0] out;
    // Copy in to out from lsb and extend msb of in to msb of out
    assign out = {{m-n{in[n-1]}}, in};
endmodule

// 3 input k-bit wide mux with one-hot select
module Mux3(in2, in1, in0, out, s);
    parameter k = 3;
    input [k-1:0] in2, in1, in0;
    input [2:0] s;
    output reg [k-1:0] out;
    // one-hot select one of the three inputs to out
    always @(*)
    case(s)
        3'b001:
            out = in0;
        3'b010:
            out = in1;
        3'b100:
            out = in2;
        default:
            out = {k{1'bx}};
    endcase
endmodule
