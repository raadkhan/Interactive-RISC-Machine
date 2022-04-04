module shifter(in, opcode, shift, out);
    input [15:0] in;
    input [2:0] opcode;
    input [1:0] shift;
    output reg [15:0] out;
    // Perform 1 bit left shift, right shift,
    // right shift and sign bit copied to vacated bit,
    // or no shift depending on opcode and shift
    always @(*)
    begin
        casex({opcode, shift})
            5'b011xx:
                out = in;
            5'b100xx:
                out = in;
            5'bxxx00:
                out = in;
            5'bxxx01:
                out = in << 1;
            5'bxxx10:
                out = in >> 1;
            5'bxxx11:
                out = { in[15], in[15:1] };
            default:
                out = 16'bx;
        endcase
    end
endmodule
