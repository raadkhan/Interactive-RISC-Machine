module alu(Ain, Bin, ALUop, ALUout, status);
    parameter n = 16;
    input wire [n-1:0] Ain, Bin;
    input wire [1:0] ALUop;
    output reg [n-1:0] ALUout;
    output reg [2:0] status;

    wire [n-1:0] ABout;
    wire overflow;
    reg negative, zero;

    // Instantiate adder/subtractor for Ain, Bin, check for overflow
    AddSub #(n) as(Ain, Bin, ALUop[0], ABout, overflow);

    always @(*)
    begin
        // Compute arithmetic/logical operations based on ALUop value
        case(ALUop)
            2'b00:
                ALUout = ABout;
            2'b01:
                ALUout = ABout;
            2'b10:
                ALUout = Ain & Bin;
            2'b11:
                ALUout = ~Bin;
        endcase
        // Compute flags
        negative = ALUout[n-1];
        zero = ~(|ALUout);
        // status[0] is zero flag
        // status[1] is neg flag
        // status[2] is ovf flag
        status = {overflow, negative, zero};
    end
endmodule

module AddSub(a, b, sub, s, ovf);
    parameter n = 8;
    input [n-1:0] a, b;
    input sub;
    output [n-1:0] s;
    output ovf;

    wire c1, c2;
    // Overflow if signs don't match
    wire ovf = c1 ^ c2;
    // Add non sign bits
    Adder1 #(n-1) ai(a[n-2:0], b[n-2:0] ^ {n-1{sub}}, sub, c1, s[n-2:0]);
    // Add sign bits
    Adder1 #(1) as(a[n-1], b[n-1] ^ sub, c1, c2, s[n-1]);
endmodule

module Adder1(a, b, cin, cout, s);
    parameter n = 8;
    input [n-1:0] a, b;
    input cin;
    output wire [n-1:0] s;
    output wire cout;

    assign {cout, s} = a + b + cin;
endmodule
