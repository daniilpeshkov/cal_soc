
module clk_divider #(
    parameter CLK_DIV = 2
) (
    input           clk_i,
    input           arst_i,

    output logic posedge_o,
    output logic negedge_o,
    output logic    clk_o
);

    logic clk_o_next;
    logic [$clog2(CLK_DIV) : 0] clk_div_cnt = 0;
    logic [$clog2(CLK_DIV) : 0] clk_div_cnt_next;

    always_comb begin
        posedge_o = 0;
        negedge_o = 0;
        if (clk_div_cnt == CLK_DIV - 1) begin
            clk_div_cnt_next = 0;
            clk_o_next = ~clk_o;
            if (clk_o_next == 1) posedge_o= 1;
            else negedge_o= 1;
        end else begin 
            clk_div_cnt_next = clk_div_cnt + 1;
            clk_o_next = clk_o;
        end
    end

    always_ff @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            clk_o = 0;
            clk_div_cnt = 0;
        end else begin 
            clk_o <= clk_o_next;
            clk_div_cnt <= clk_div_cnt_next;
        end
    end

endmodule