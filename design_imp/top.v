// INSTRUCTIONS:
//
// DE1-SOC INTERFACE SPECIFICATION for top.v code in this file:
//
// clk input to datpath has rising edge when KEY0 is *pressed*
//
// HEX5 contains the status register output on the top (Z), middle (N),
// and bottom (V) segment.
//
// HEX3, HEX2, HEX1, HEX0 are wired to out which should show the contents
// of register C.
//
// The rising edge of clk occurs at the moment KEY0 is *pressed*.
// The input reset is 1 as long as KEY1 is held.
module top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
    input CLOCK_50;
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    // memory action constant
`define MREAD 2'b10
    `define MWRITE 2'b01
    // DE1-SoC output
    wire Z, N, V;
    wire [15:0] out;
    // To i/o devices
    wire [15:0] write_data = out;
    // Internal wiring between CPU and RAM
    wire [15:0] read_data, dout;
    wire [8:0] mem_addr;
    wire [1:0] mem_cmd;
    wire msel = (1'b0 == mem_addr[8]);
    // Instantiate CPU
    cpu CPU( .clk (CLOCK_50), // recall that KEY0 is 1 when NOT pushed
             .reset (~KEY[1]),
             .read_data(read_data),
             .mem_addr(mem_addr),
             .mem_cmd(mem_cmd),
             .out   (out),
             .Z     (Z),
             .N     (N),
             .V     (V),
             .w     (LEDR[8]) );
    // Interface between CPU and RAM
    wire e = (msel) & (mem_cmd == `MREAD);
    wire write = (mem_cmd == `MWRITE) & (msel);
    // assign read_data = e ? dout : {16{1'bz}}; // tri-state driver
    tsd tsdMEM(.in(dout), .c(e), .out(read_data));
    // Instantiate RAM with fig2.txt or fig4.txt
    // or demo.txt or virtual.txt
    RAM #(16, 8, "demo.txt") MEM( .clk(CLOCK_50),
                                  .read_address(mem_addr[7:0]),
                                  .write_address(mem_addr[7:0]),
                                  .write(write),
                                  .din(write_data),
                                  .dout(dout) );
    // Interface between CPU and i/o devices
    wire swe = (mem_cmd == `MREAD) & (mem_addr == 9'b101000000);
    // assign read_data = swe ? {8'b0, SW[7:0]} : {16{1'bz}}; // tri-state driver
    tsd tsdSW(.in({8'b0, SW[7:0]}), .c(swe), .out(read_data));
    // set load_led to write to LED
    wire load_led = (mem_addr == 9'b100000000) & (mem_cmd == `MWRITE);
    // Instantiate 8 bit LED register to display write_data on LED
    Reg #(8) regLED(.clk(CLOCK_50), .in(write_data[7:0]), .load(load_led), .out(LEDR[7:0]));
    // display status flags
    assign HEX5[0] = ~Z;
    assign HEX5[6] = ~N;
    assign HEX5[3] = ~V;
    // fill in sseg to display 4-bits in hexidecimal 0,1,2...9,A,B,C,D,E,F
    sseg H0(out[3:0],   HEX0);
    sseg H1(out[7:4],   HEX1);
    sseg H2(out[11:8],  HEX2);
    sseg H3(out[15:12], HEX3);
    assign HEX4 = 7'b1111111;
    assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
    assign LEDR[9] = 1'b0;
endmodule

module tsd(in, c, out);
    parameter n = 16;
    input [n-1:0] in;
    input c;
    output wire [n-1:0] out;
    // tri-state driver
    assign out = c ? in : {n{1'bz}};
endmodule

module vDFF(clk,D,Q);
    parameter n=1;
    input clk;
    input [n-1:0] D;
    output [n-1:0] Q;
    reg [n-1:0] Q;
    always @(posedge clk)
        Q <= D;
endmodule

// The sseg module below can be used to display the value of datpath_out on
// the hex LEDS the input is a 4-bit value representing numbers between 0 and
// 15 the output is a 7-bit value that will print a hexadecimal digit.
module sseg(in,segs);
    input [3:0] in;
    output reg [6:0] segs;

    // One bit per segment. On the DE1-SoC a HEX segment is illuminated when
    // the input bit is 0. Bits 6543210 correspond to:
    //
    //    0000
    //   5    1
    //   5    1
    //    6666
    //   4    2
    //   4    2
    //    3333
    //
    // Decimal value | Hexadecimal symbol to render on (one) HEX display
    //             0 | 0
    //             1 | 1
    //             2 | 2
    //             3 | 3
    //             4 | 4
    //             5 | 5
    //             6 | 6
    //             7 | 7
    //             8 | 8
    //             9 | 9
    //            10 | A
    //            11 | b
    //            12 | C
    //            13 | d
    //            14 | E
    //            15 | F
    // Define 8 bit value for each hexadecimal symbol
`define zero 	7'b1000000
    `define one 	7'b1111001
    `define two 	7'b0100100
    `define three 7'b0110000
    `define four  7'b0011001
    `define five 	7'b0010010
    `define six 	7'b0000010
    `define seven 7'b1111000
    `define eight 7'b0000000
    `define nine 	7'b0011000
    `define A 	7'b0001000
    `define B 	7'b0000011
    `define C 	7'b1000110
    `define D 	7'b0100001
    `define E 	7'b0000110
    `define F 	7'b0001110
    // Evaluate 4 bit binary input to hexadecimal on HEX
    always @(in)
    begin
        case(in)
            4'b0000:
                segs = `zero;
            4'b0001:
                segs = `one;
            4'b0010:
                segs = `two;
            4'b0011:
                segs = `three;
            4'b0100:
                segs = `four;
            4'b0101:
                segs = `five;
            4'b0110:
                segs = `six;
            4'b0111:
                segs = `seven;
            4'b1000:
                segs = `eight;
            4'b1001:
                segs = `nine;
            4'b1010:
                segs = `A;
            4'b1011:
                segs = `B;
            4'b1100:
                segs = `C;
            4'b1101:
                segs = `D;
            4'b1110:
                segs = `E;
            4'b1111:
                segs = `F;
            default:
                segs = `zero;
        endcase
    end
endmodule
