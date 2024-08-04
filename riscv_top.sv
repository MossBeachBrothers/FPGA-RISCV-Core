module riscv_top (
    input logic clk,
    input logic reset,

);



typdef enum logic [2:0] {
    WAIT,
    FETCH,
    DECODE,
    READ_REGISTER,
    WRITE_REGISTER,
    READ_MEMORY,
    WRITE_MEMORY,
    READ_INSTRUCTION_MEMORY,
} pipeline_stage_t;

pipeline_stage_t current_state, next_state;


//control signals
logic ctrl_memory_read_enable, ctrl_memory_write_enable;
logic ctrl_instruction_mem_read_enable, ctrl_instruction_mem_write_enable;
logic ctrl_data_mem_read_enable, ctrl_data_mem_read_enable;
logic ctrl_reg_read_enable, ctrl_reg_write_enable;
logic ctrl_alu_op_enable;
logic ctrl_pc_update_enable;
logic ctrl_branch_enable;
logic ctrl_jump_enable;
// logic ctrl_harzard_detection_enable;
// logic ctrl_forwarding_enable;
// logic ctrl_interrupt_enable;
logic ctrl_interrupt_ack; //acknowledges interrupt request


logic[31:0] pc,next_pc;
logic[31:0] instruction;
logic [31:0] immediate;




logic branch_decision_enable;
logic jump_enable;

//Completion
logic stat_instruction_fetched;       // Instruction fetched from memory
logic stat_data_read;                 // Data read from memory or register file
logic stat_data_written;              // Data written to memory
logic stat_execution_done;            // ALU operation completed
logic stat_reg_write_done;            // Register write completed
logic stat_branch_decision_done;      // Branch decision made
logic stat_instruction_decoded;       // Instruction decoded




logic is_r_type, is_i_type, is_s_type, is_b_type, is_u_type, is_j_type

logic [3:0] alu_control;



//Reset and Next State Logic

always_ff @(posedge clk or posedge reset) begin 
    if (reset) begin
        //non-blocking
        current_state <= WAIT;
        pc <= 32'b0; //initialize PC to zero
    end else begin
        current_state <= next_state;
     end
end




//State Machine Logic
always_comb @(posedge clk or posedge reset) begin
    if (reset) begin
        next_state <= WAIT; //if reset , wait
    end else begin
        case (current_state):
            WAIT: next_state <= FETCH; //Move to FETCH unconditionally
            FETCH: begin
                //FETCH
                //read instruction memory
                //write register
                //read register 
                //

            end
            DECODE: begin 

            end
            READ_REGISTER: if () next_state = EXECUTE;
            EXECUTE: begin

            end
            READ_MEMORY: begin 

            end
            WRITE_MEMORY: begin 

            end 
            WRITE_REGISTER: begin 

            end 

            default: next_state = current_state;
        endcase
    end
        
 end

//Update PC logic if enabled
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


