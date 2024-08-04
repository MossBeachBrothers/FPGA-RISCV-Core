module riscv_top (
    input logic clk,
    input logic reset
);

// State enumeration
typedef enum logic [2:0] {
    WAIT,
    FETCH,
    DECODE,
    EXECUTE,
    READ_MEMORY,
    WRITE_MEMORY,
    WRITEBACK
} pipeline_stage_t;

pipeline_stage_t current_state, next_state;

// Control signals
logic ctrl_instruction_mem_read_enable, ctrl_data_mem_read_enable, ctrl_data_mem_write_enable;
logic ctrl_reg_read_enable, ctrl_reg_write_enable;
logic ctrl_alu_op_enable, ctrl_pc_update_enable, ctrl_branch_enable, ctrl_jump_enable;
logic ctrl_interrupt_enable, ctrl_interrupt_ack;

// Internal signals
logic [31:0] pc, next_pc;
logic [31:0] instruction, immediate;

// Completion signals
logic stat_instruction_fetched, stat_instruction_decoded;
logic stat_reg_write_done, stat_mem_read_done, stat_mem_write_done;
logic stat_execution_done, stat_branch_decision_done;

// Instruction type flags
logic is_r_type, is_i_type, is_s_type, is_b_type, is_u_type, is_j_type;

// ALU control
logic [3:0] alu_control;

// Reset and Next State Logic
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        // non-blocking
        current_state <= WAIT;
        pc <= 32'b0; // initialize PC to zero
    end else begin
        current_state <= next_state;
    end
end

// State Machine Logic
always_comb begin
    // Default assignments: Ensures known values for control signals every cycle
    next_state = current_state;
    ctrl_instruction_mem_read_enable = 1'b0;
    ctrl_data_mem_read_enable = 1'b0;
    ctrl_data_mem_write_enable = 1'b0;
    ctrl_reg_read_enable = 1'b0;
    ctrl_reg_write_enable = 1'b0;
    ctrl_alu_op_enable = 1'b0;
    ctrl_pc_update_enable = 1'b0;
    ctrl_branch_enable = 1'b0;
    ctrl_jump_enable = 1'b0;
    ctrl_interrupt_enable = 1'b0;
    ctrl_interrupt_ack = 1'b0;
    alu_control = 4'b0000;

    case (current_state)
        WAIT: next_state = FETCH; // Move to FETCH unconditionally

        FETCH: begin
            ctrl_instruction_mem_read_enable = 1'b1;
            // On success signal
            if (stat_instruction_fetched) begin
                next_state = DECODE;
            end
        end

        DECODE: begin
            ctrl_reg_read_enable = 1'b1;
            // On success signal, decide where to go next
            if (stat_instruction_decoded) begin
                if (is_r_type || is_i_type || is_s_type || is_b_type || is_j_type) begin
                    next_state = EXECUTE;
                end else if (is_u_type) begin
                    // If U type, writeback
                    next_state = WRITEBACK;
                end
            end
        end

        EXECUTE: begin
            ctrl_alu_op_enable = 1'b1;
            // On success signal
            if (stat_execution_done) begin
                if (is_r_type || is_i_type) begin
                    next_state = WRITEBACK;
                end else if (is_s_type) begin
                    next_state = WRITE_MEMORY;
                end else if (is_i_type && (instruction[6:0] == 7'b0000011)) begin
                    next_state = READ_MEMORY;
                end else if (is_b_type || is_j_type) begin
                    if (stat_branch_decision_done) begin
                        ctrl_pc_update_enable = 1'b1;
                        next_state = FETCH;
                    end
                end
            end
        end

        READ_MEMORY: begin
            ctrl_data_mem_read_enable = 1'b1;
            if (stat_mem_read_done) begin
                next_state = WRITEBACK;
            end
        end

        WRITE_MEMORY: begin
            ctrl_data_mem_write_enable = 1'b1;
            if (stat_mem_write_done) begin
                next_state = FETCH;
            end
        end

        WRITEBACK: begin
            ctrl_reg_write_enable = 1'b1;
            if (stat_reg_write_done) begin
                next_state = FETCH;
            end
        end

        default: next_state = current_state; // Stay in the current state if no other condition is met
    endcase
end

// Update PC logic if enabled
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 32'b0;
    end else if (ctrl_pc_update_enable) begin
        if (ctrl_branch_enable || ctrl_jump_enable) begin
            pc <= pc + immediate;
        end else begin
            pc <= pc + 4;
        end
    end
end

endmodule
