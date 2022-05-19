
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
        a <= (valid_i ? a_i : a)
        b <= (valid_i ? b_i : b)
    end

    enum logic[1:0] {IDLE, FIRST_STAGE, SECOND_STAGE} state, next_state;

    logic valid;
    logic carry;

    always_comb begin
        case (state)
            IDLE: if (valid_i) next_state = FIRST_STAGE;
        endcase
    end


    always_ff @(posedge clk_i) begin
        valid <= valid_i;
        valid_o <= valid;
        // {carry, res}

    end

endmodule