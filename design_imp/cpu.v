module cpu(clk, reset, read_data, mem_addr, mem_cmd, out, N, V, Z, w);
    input clk, reset;
    // RAM i/o interface
    input [15:0] read_data;
    output wire [8:0] mem_addr;
    output wire [1:0] mem_cmd;
    // DE1-SoC output interface
    output wire [15:0] out;
    output wire N, V, Z, w;
    // Internal wiring between controller and IR
    wire load_ir;
    // Wiring for PC and DA
    wire [8:0] pc_next, PC, DA, lr;
    // Internal wiring between controller and PC
    wire reset_pc, tsel, rsel, execb, addr_sel, load_addr;
    // Internal wiring between controller and instruction decoder
    wire [1:0] op;
    wire [2:0] opcode, nsel;
    // Internal wiring between controller and datapath
    wire write, asel, bsel, loada, loadb, loadc, loads;
    wire [1:0] vsel;
    // Internal wiring between instruction decoder and datapath
    wire [1:0] shift, ALUop;
    wire [2:0] writenum, readnum, cond;
    wire [15:0] ir_out, sximm8, sximm5;
    // Wiring for status flags
    wire [2:0] status_out;
    assign {V,N,Z} = status_out;
    // Instantiate controller
    controller CTRL(.clk(clk), .reset(reset), .status(status_out), .cond(cond), .op(op), .opcode(opcode),
                    .nsel(nsel), .vsel(vsel), .write(write), .asel(asel), .bsel(bsel),
                    .loada(loada), .loadb(loadb), .loadc(loadc), .loads(loads),
                    .reset_pc(reset_pc), .tsel(tsel), .rsel(rsel), .execb(execb), .addr_sel(addr_sel), .load_addr(load_addr),
                    .mem_cmd(mem_cmd),
                    .load_ir(load_ir),
                    .w8(w));
    // Instantiate 16 bit IR with load enable
    Reg regIR(.clk(clk), .in(read_data), .load(load_ir), .out(ir_out));
    // Instantiate instruction decoder
    decoder ID(ir_out, nsel, opcode, op, writenum, readnum, shift, sximm8, sximm5, ALUop, cond);
    // Instantiate datapath
    datapath DP(.clk(clk),
                // Register operand fetch stage
                .readnum(readnum), .loada(loada), .loadb(loadb),
                // Execution stage
                .sximm5(sximm5), .opcode(opcode), .shift(shift), .asel(asel), .bsel(bsel), .ALUop(ALUop), .loadc(loadc), .loads(loads),
                // Register writeback stage
                .sximm8(sximm8), .vsel(vsel), .writenum(writenum), .write(write),
                // Program counter component
                .pc_out(PC),
                // RAM component
                .mdata(read_data),
                // Outputs
                .datapath_out(out), .status_out(status_out), .LR(lr));

    wire [8:0] pctgt, pcrel, pc1, pc;
    // Add sximm8 to PC++
    assign pcrel = sximm8[8:0] + pc1;
    // P++
    assign pc1 = PC + 9'b1;
    // Determine if PC should be incremented or updated to target branch
    wire load_pc = execb | rsel | tsel;
    // Instantiate function call support mux
    Mux2 #(9) muxFuncSupp(.in0(pcrel), .in1(lr), .out(pctgt), .s(tsel));
    // Instantiate set PC mux
    Mux2 #(9) muxSetPC(.in0(pctgt), .in1(pc1), .out(pc), .s(rsel));
    // Instantiate reset PC mux
    Mux2 #(9) muxResetPC(.in0(pc), .in1(9'b0), .out(pc_next), .s(reset_pc));
    // Instantiate 9 bit PC with load enable
    Reg #(9) regPC(.clk(clk), .in(pc_next), .load(load_pc), .out(PC));
    // Instantiate next address mux
    Mux2 #(9) muxAddr(.in0(DA), .in1(PC), .out(mem_addr), .s(addr_sel));
    // Instantiate 9 bit DA with load enable
    Reg #(9) regDA(.clk(clk), .in(out[8:0]), .load(load_addr), .out(DA));
endmodule

// 2 input n-bit wide mux with binary select
module Mux2(in0, in1, out, s);
    parameter n = 8;
    input [n-1:0] in0, in1;
    input s;
    output [n-1:0] out;
    // Mux logic: if s is 1 drive in1 to out else drive in0
    wire [n-1:0] out = (s ? in1 : in0);
endmodule
