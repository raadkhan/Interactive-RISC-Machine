module controller(
        clk, reset, status, cond, op, opcode,
        nsel, vsel, write, asel, bsel,
        loada, loadb, loadc, loads,
        reset_pc, tsel, execb, rsel, addr_sel, load_addr,
        mem_cmd,
        load_ir,
        w8);
    input clk, reset;
    // Input from datapath
    input [2:0] status;
    // Inputs from instruction decoder
    input [1:0] op;
    input [2:0] opcode, cond;
    // Outputs to PC
    output reg reset_pc, tsel, execb, rsel, addr_sel, load_addr;
    // Output to RAM
    output reg [1:0] mem_cmd;
    // Output to IR
    output reg load_ir;
    // Output to instruction decoder
    output reg [2:0] nsel;
    // Outputs to datapath
    output reg [1:0] vsel;
    output reg write, asel, bsel, loada, loadb, loadc, loads;
    // Output for wait_state
    output reg w8;
    // Datapath controller states
	`define pc_reset		5'b00000
	`define ifetch			5'b00001
	`define ir_load		 	5'b00010
	`define pc_update	 	5'b00011
	`define op_decode		5'b00100
	`define just_mov 		5'b00101
	`define alu_movs_read 	z5'b00110
	`define alu_mem_read	5'b00111
	`define compute			5'b01000
	`define writeback		5'b01001
	`define str_read		5'b01010
	`define str_load 		5'b01011
	`define str_write		5'b01100
	`define da_update		5'b01101
	`define ldr_read		5'b01110
	`define ldr_wait		5'b01111
	`define jump_return		5'b10000
	`define blx_return		5'b10001
	`define wait_state 		5'b11111
    // nsel one-hot select
	`define Rn 3'b100
	`define Rd 3'b010
	`define Rm 3'b001
    // opcode encoding
	`define MOV 3'b110
	`define ALU 3'b101
	`define LDR 3'b011
	`define STR 3'b100
	`define B__	3'b001
	`define C__	3'b010
	`define HLT 3'b111
    // memory action constant
	`define MREAD 2'b10
	`define MWRITE 2'b01

    wire [4:0] present_state, next_state_reset;
    reg [4:0] next_state;
    // Instantiate dff to update state on posedge
    vDFF #(5) state(clk, next_state_reset, present_state);
    // Mux logic to reset state
    assign next_state_reset = (reset ? `pc_reset : next_state);
    // Always combinational logic for next state logic
    always @(*)
    begin
        // Reset every control signal to 0 when returning from a state
        reset_pc = 1'b0;
        tsel = 1'b0;
        execb = 1'b0;
        rsel = 1'b0;
        addr_sel = 1'b0;
        load_addr = 1'b0;
        mem_cmd = 2'b00;
        load_ir = 1'b0;
        nsel = 3'b000;
        vsel = 2'b00;
        write = 1'b0;
        asel = 1'b0;
        bsel = 1'b0;
        loada = 1'b0;
        loadb = 1'b0;
        loadc = 1'b0;
        loads = 1'b0;
        w8 = 1'b0;

        case(present_state)
            // Start here when reset is pressed (next_pc = 8'b0)
            `pc_reset:
            begin
                next_state = `ifetch;
                reset_pc = 1'b1;
                rsel = 1'b1;
            end
            // Fetch instruction from memory at selected address
            `ifetch:
            begin
                next_state = `ir_load;
                addr_sel = 1'b1;
                mem_cmd = `MREAD;
            end
            // Load instruction to IR
            `ir_load:
            begin
                next_state = `pc_update;
                addr_sel = 1'b1;
                mem_cmd = `MREAD;
                load_ir = 1'b1;
            end
            // Set rsel, execb, nsel, loada to update PC to next instruction
            // or to target instruction based on status flags or to LR
            // or set vsel, write, nsel save PC to LR
            // depending on branch instruction
            `pc_update:
            begin
                casex({opcode,op,status,cond})
                    // B__ <label>			// BEQ <label>
                    {`B__,2'b00,6'bxxx_000}, {`B__,2'b00,6'b001_001},
                    // BNE <label>			// BLT <label>
                    {`B__,2'b00,6'bxx0_010}, {`B__,2'b00,6'b100_011},
                    // BLT <label>			// BLE <label>
                    {`B__,2'b00,6'b010_011}, {`B__,2'b00,6'b100_100},
                    // BLE <label>			// BLE <label>
                    {`B__,2'b00,6'b010_100}, {`B__,2'b00,6'b001_100}:
                    begin
                        next_state = `ifetch;
                        execb = 1'b1;
                    end
                    // BEQ, BNE, BLT, BLE
                    {`B__,2'b00,6'bxxx_xxx}:
                    begin
                        next_state = `ifetch;
                        rsel = 1'b1;
                    end
                    // BL <label>
                    {`C__,2'b11,6'bxxx_111}:
                    begin
                        next_state = `jump_return;
                        vsel = 2'b01;
                        write = 1'b1;
                        nsel = `Rn;
                    end
                    // BLX Rd
                    {`C__,2'b10,6'bxxx_111}:
                    begin
                        next_state = `jump_return;
                        vsel = 2'b01;
                        write = 1'b1;
                        nsel = `Rn;
                    end
                    // BX Rd
                    {`C__,2'b00,6'bxxx_000}:
                    begin
                        next_state = `jump_return;
                        nsel = `Rd;
                        loada = 1'b1;
                    end
                    default:
                    begin
                        next_state = `op_decode;
                        rsel = 1'b1;
                    end
                endcase
            end
            // Set execb, nsel, tsel to update PC to target address
            // or LR depending on branch instruction
            `jump_return:
            begin
                casex({opcode,op})
                    // BL <label>
                    {`C__,2'b11}:
                    begin
                        next_state = `ifetch;
                        execb = 1'b1;
                    end
                    // BLX Rd
                    {`C__,2'b10}:
                    begin
                        next_state = `blx_return;
                        nsel = `Rd;
                        loada = 1'b1;
                    end
                    // BX Rd
                    {`C__,2'b00}:
                    begin
                        next_state = `ifetch;
                        tsel = 1'b1;
                    end
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Set tsel to update PC to LR
            `blx_return:
            begin
                next_state = `ifetch;
                tsel = 1'b1;
            end
            // Transition to respective state depending on opcode, op
            // If all instructions/garbage/HALT executed then go to wait_state
            `op_decode:
            begin
                casex({opcode,op})
                    // MOV Rn, #<im8>
                    {`MOV,2'b10}:
                        next_state = `just_mov;
                    // MOV Rd, Rm{,<sh_op>}
                    {`MOV,2'b00}:
                        next_state = `alu_movs_read;
                    // MVN Rd, Rm{,<sh_op>}
                    {`ALU,2'b11}:
                        next_state = `alu_movs_read;
                    // ADD, CMP, AND
                    {`ALU,2'bxx}:
                        next_state = `alu_mem_read;
                    // LDR Rd, [Rn{,#<im5>}]
                    {`LDR,2'b00}:
                        next_state = `alu_mem_read;
                    // STR Rd, [Rn{,#<im5>}]
                    {`STR,2'b00}:
                        next_state = `alu_mem_read;
                    // HALT
                    {`HLT,2'bxx}:
                        next_state = `wait_state;
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Immediately write sximm8 to Rn
            `just_mov:
            begin
                next_state = `ifetch;
                vsel = 2'b10;
                write = 1'b1;
                nsel = `Rn;
            end
            // Load Rm onto Rb
            `alu_movs_read:
            begin
                next_state = `compute;
                nsel = `Rm;
                loadb = 1'b1;
            end
            // Load Rn onto Ra
            // Transition to respective state depending on opcode, op
            `alu_mem_read:
            begin
                nsel = `Rn;
                loada = 1'b1;
                casex({opcode,op})
                    {`ALU,2'bxx}:
                        next_state = `alu_movs_read;
                    {`LDR,2'b00}:
                        next_state = `compute;
                    {`STR,2'b00}:
                        next_state = `compute;
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Load ALUout onto Rc
            // Transition to respective state depending on opcode, op
            `compute:
            begin
                loadc = 1'b1;
                casex({opcode,op})
                    // Set asel to 1 to add with 16'b0
                    {`MOV,2'b00}:
                    begin
                        next_state = `writeback;
                        asel = 1'b1; /*bsel = 1'b0;*/
                    end
                    // Set bsel to 0 to bitwise NOT Bin
                    {`ALU,2'b11}:
                    begin
                        next_state = `writeback; /*bsel = 1'b0;*/
                    end
                    // Set asel and bsel to 0 to perform subtraction on Ain and Bin
                    // and load status_in onto status register to observe zero flag
                    {`ALU,2'b01}:
                    begin
                        next_state = `ifetch; /*asel = 1'b0; bsel = 1'b0;*/
                        loads = 1'b1;
                    end
                    // Set asel and bsel to 0 to perform addition/bitwise AND on Ain and Bin
                    {`ALU,2'bxx}:
                    begin
                        next_state = `writeback; /*asel = 1'b0; bsel = 1'b0;*/
                    end
                    // Set bsel to 1 to perform addition on Ain and sximm5
                    {`LDR,2'b00}:
                    begin
                        next_state = `da_update; /*asel = 1'b0;*/
                        bsel = 1'b1;
                    end
                    {`STR,2'b00}:
                    begin
                        next_state = `da_update; /*asel = 1'b0;*/
                        bsel = 1'b1;
                    end
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Write back to Rd
            // Transition to respective state depending on opcode, op
            `writeback:
            begin
                nsel = `Rd;
                write = 1'b1;
                casex({opcode,op})
                    // Load Rc onto Rd
                    {`MOV,2'b00}:
                    begin
                        next_state = `ifetch; /*vsel = 2'b00;*/
                    end
                    {`ALU,2'bxx}:
                    begin
                        next_state = `ifetch; /*vsel = 2'b00;*/
                    end
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Store lower 9 bits of Ain + sximm5 to DA
            `da_update:
            begin
                load_addr = 1'b1;
                case({opcode,op})
                    {`LDR,2'b00}:
                        next_state = `ldr_read;
                    {`STR,2'b00}:
                        next_state = `str_read;
                    default:
                        next_state = `wait_state;
                endcase
            end
            // Read from memory specified by mem_addr
            `ldr_read:
            begin
                next_state = `ldr_wait;
                /*addr_sel = 1'b0;*/
                mem_cmd = `MREAD;
            end
            // Wait for mdata to update and load onto Rd
            `ldr_wait:
            begin
                next_state = `ifetch;
                /*addr_sel = 1'b0;*/
                mem_cmd = `MREAD;
                nsel = `Rd;
                write = 1'b1;
                vsel = 2'b11;
            end
            // Load Rd onto Rb
            `str_read:
            begin
                next_state = `str_load;
                nsel = `Rd;
                loadb = 1'b1;
            end
            // Load Rb onto Rc
            `str_load:
            begin
                next_state = `str_write;
                loadc = 1'b1;
                asel = 1'b1; /*bsel = 1'b0;*/
            end
            // Write to memory specified by mem_addr
            `str_write:
            begin
                next_state = `ifetch;
                /*addr_sel = 1'b0;*/
                mem_cmd = `MWRITE;
            end
            // Do nothing/wait until reset is pressed
            `wait_state:
            begin
                w8 = 1'b1;
                next_state = `wait_state;
            end
            default:
                next_state = `wait_state;
        endcase
    end
endmodule
