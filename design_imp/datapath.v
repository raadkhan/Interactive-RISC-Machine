module datapath(clk,
				// Register operand fetch stage
				readnum, loada, loadb,
				// Execution stage
				sximm5, opcode, shift, asel, bsel, ALUop, loadc, loads,
				// Register writeback stage
				sximm8, vsel, writenum, write,
				// Program counter component
				pc_out,
				// RAM component
				mdata,
				// Outputs
				datapath_out, status_out, LR);

	input [15:0]  mdata, sximm8, sximm5;
	input [8:0] pc_out;
	input clk, write, loada, loadb, loadc, loads, asel, bsel;
	input [2:0] writenum, readnum, opcode;
	input [1:0] shift, ALUop, vsel;

	output [15:0] datapath_out;
	output [2:0] status_out;

	wire [2:0] status_in;
	wire [15:0] data_in, data_out, Aout, Bout, ShiftBout, ALUout;

	output wire [8:0] LR;
	assign LR = Aout[8:0];
	// Source operand multiplexer to use instruction/value in Ra or 16'b0
	wire [15:0] Ain = (asel ? 16'b0 : Aout);
	// Source operand multiplexer to use instruction/value in Rb shifted
	// or sximm5
	wire [15:0] Bin = (bsel ? sximm5 : ShiftBout);
	// Instantiate register file to store values
	regfile REGFILE(.clk(clk), .writenum(writenum), .write(write),
					.data_in(data_in), .readnum(readnum), .data_out(data_out));
	// Instantiate ALU to execute arithmetic and logical operations
	alu ALU(.Ain(Ain), .Bin(Bin), .ALUop(ALUop),
			.ALUout(ALUout), .status(status_in));
	// Instantiate shifter to quickly multiply or divide by 2
	shifter Shifter(.in(Bout), .opcode(opcode), .shift(shift), .out(ShiftBout));
	// Instantiate three 16 bit pipeline registers with load enable
	Reg regA(.clk(clk), .in(data_out), .load(loada), .out(Aout));
	Reg regB(.clk(clk), .in(data_out), .load(loadb), .out(Bout));
	Reg regC(.clk(clk), .in(ALUout), .load(loadc), .out(datapath_out));
	// Instantiate 3 bit status register with load enable to implement C features
	Reg #(3) regStatus(.clk(clk), .in(status_in), .load(loads), .out(status_out));
	// Writeback multiplexer to use instruction/value in Rc, PC++, sximm8, or mdata
	Mux4b #(16) muxRegFile(.in3(mdata), .in2(sximm8), .in1({7'b0, (pc_out + 9'b1)}),
						   .in0(datapath_out), .s(vsel), .out(data_in));
endmodule

// 4 input n-bit wide mux with binary select
module Mux4b(in3, in2, in1, in0, out, s);
	parameter n = 16;
	input [n-1:0] in0, in1, in2, in3;
	input [1:0] s;
	output reg [n-1:0] out;
	// Binary select one of the 4 inputs to out
	always @(*) begin
		case(s)
			2'b00: out = in0;
			2'b01: out = in1;
			2'b10: out = in2;
			2'b11: out = in3;
			default: out = {n{1'bx}};
		endcase
	end
endmodule