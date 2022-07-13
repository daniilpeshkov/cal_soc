
module pipelined_adder_32 (
    input logic clk_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic valid_i,

    output logic valid_o,
    output logic [31:0] res_o
);
    
    logic [1:0] valid;
    integer i;
    always_ff @(posedge clk_i) begin
        valid[0] <= valid_i;
        for (i = 1; i <= 1; i = i +1 ) valid[i] <= valid[i-1];
        valid_o <= valid[1];
    end

    // assign valid_o = valid[1];
    logic [31:0] a, b;
    logic carry;
    logic [15:0] first_stage_lo, first_stage_hi;

    always_ff @(posedge clk_i) a <= a_i;
    always_ff @(posedge clk_i) b <= b_i;

    always_ff @(posedge clk_i) first_stage_hi <= a[31:16] + b[31:16];
    always_ff @(posedge clk_i) {carry, first_stage_lo} <= a[15:0] + b[15:0];

    logic [15:0] second_stage_lo, second_stage_hi;

    always_ff @(posedge clk_i) second_stage_lo <= first_stage_lo;
    always_ff @(posedge clk_i) second_stage_hi <= first_stage_hi + carry;

    assign res_o = {second_stage_hi, second_stage_lo};




endmodule