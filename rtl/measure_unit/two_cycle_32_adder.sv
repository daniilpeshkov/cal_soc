
module two_cycle_32_adder (
    input logic clk_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic valid_i,

    output logic valid_o,
    output logic [31:0] res_o
);
    
    logic [31:0] a, b;

    always_ff @(posedge clk_i) begin
        a <= (valid_i ? a_i : a);
        b <= (valid_i ? b_i : b);
    end

    enum logic[1:0] {IDLE, FIRST_STAGE, SECOND_STAGE} state = IDLE, next_state;

    always_ff @(posedge clk_i) state <= next_state;
  
    logic valid;

    always_ff @(posedge clk_i) begin
        valid <= valid_i;
        valid_o <= valid;
    end


    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (valid_i) next_state = FIRST_STAGE;
            FIRST_STAGE: next_state = SECOND_STAGE;
            SECOND_STAGE: next_state = IDLE;
        endcase
    end

    logic carry;

    always_ff @(posedge clk_i) begin
        case (state) 
            FIRST_STAGE: {carry, res_o[15:0]} <= a[15:0] + b[15:0];
            default: {carry, res_o[15:0]} <= {carry, res_o[15:0]};
        endcase
        case (state)
            SECOND_STAGE: res_o[31:16] <= a[31:16] + b[31:16] + carry;
            default: res_o[31:16] <= res_o[31:16];
        endcase
    end

endmodule